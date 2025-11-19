"""
Accessory Service Database Layer

This module provides the database service layer for accessories using Azure CosmosDB.
It follows Azure best practices for CosmosDB integration with proper error handling,
logging, and performance optimization.

Authentication Strategy:
- Local Development (localhost): Uses key-based authentication with emulator
- Azure Deployment: Uses Entra ID (Managed Identity) authentication
"""

import os
import logging
from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
from azure.cosmos import CosmosClient, PartitionKey
from azure.cosmos import exceptions as cosmos_exceptions
from azure.identity import DefaultAzureCredential
from models import Accessory, AccessoryCreate, AccessoryUpdate, AccessorySearchFilters

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class AccessoryCosmosService:
    """
    Service class for managing accessories in Azure CosmosDB

    This class provides CRUD operations and search capabilities for accessories,
    following Azure CosmosDB best practices for partition key usage and query optimization.
    """

    def __init__(self, cosmos_endpoint: str, cosmos_key: str, database_name: str = "accessoryservice", container_name: str = "accessories"):
        """
        Initialize the CosmosDB service

        Args:
            cosmos_endpoint: Azure CosmosDB endpoint URL
            cosmos_key: Azure CosmosDB access key
            database_name: CosmosDB database name
            container_name: CosmosDB container name
        """
        self.cosmos_endpoint = cosmos_endpoint
        self.cosmos_key = cosmos_key
        self.database_name = database_name
        self.container_name = container_name

        # Initialize client, database, and container as None (lazy initialization)
        self.client = None
        self.database = None
        self.container = None

        logger.info("AccessoryCosmosService initialized with lazy loading")

    def _build_cosmos_client_options(self) -> Dict[str, Any]:
        """
        Build CosmosClient configuration for consistent usage across services.

        Authentication strategy:
        - Local (localhost): Key-based authentication with optional SSL verification disabled
        - Azure: Entra ID (Managed Identity) authentication via DefaultAzureCredential
        """
        # Detect if running locally
        is_local = "localhost" in self.cosmos_endpoint.lower(
        ) or "127.0.0.1" in self.cosmos_endpoint

        options: Dict[str, Any] = {
            "url": self.cosmos_endpoint,
            "connection_timeout": 30,
            "request_timeout": 30,
        }

        if is_local:
            # Local development: Use key-based authentication
            logger.info("Using key-based authentication (local development)")
            options["credential"] = self.cosmos_key

            # Check if SSL verification should be disabled (for emulator)
            disable_ssl_verify = os.getenv(
                "COSMOS_EMULATOR_DISABLE_SSL_VERIFY", "0").lower() in ("1", "true", "yes")

            if disable_ssl_verify:
                options["connection_verify"] = False
                logger.warning(
                    "COSMOS_EMULATOR_DISABLE_SSL_VERIFY is enabled – SSL certificate verification DISABLED (dev/emulator only)")
        else:
            # Azure deployment: Use Entra ID (Managed Identity) authentication
            logger.info(
                "Using Entra ID authentication (Azure deployment with Managed Identity)")
            credential = DefaultAzureCredential()
            options["credential"] = credential

        return options

    def _ensure_initialized(self):
        """Ensure the CosmosDB client, database, and container are initialized"""
        if self.client is None:
            logger.info("Initializing CosmosDB client...")
            cosmos_client_options = self._build_cosmos_client_options()
            endpoint = cosmos_client_options["url"]
            if endpoint.startswith("http://"):
                logger.warning(
                    "cosmos_endpoint uses http:// – prefer https:// for production parity.")
            self.client = CosmosClient(**cosmos_client_options)

        if self.database is None:
            logger.info(f"Getting database: {self.database_name}")
            self.database = self.client.get_database_client(self.database_name)

        if self.container is None:
            logger.info(f"Getting container: {self.container_name}")
            self.container = self.database.get_container_client(
                self.container_name)

    async def health_check(self) -> dict:
        """
        Perform health check and auto-create database/container if needed

        Returns:
            Dictionary with health status and any setup messages
        """
        try:
            # Ensure client is initialized
            self._ensure_initialized()

            # Try to perform a simple query to verify connection
            try:
                items = list(self.container.query_items(
                    query="SELECT TOP 1 c.id FROM c",
                    enable_cross_partition_query=True,
                    max_item_count=1
                ))

                if items:
                    return {"status": "healthy", "database": self.database_name}

                logger.info(
                    "Database is reachable but empty. Seeding with sample data...")
                await self._database_seed()
                return {
                    "status": "healthy",
                    "database": self.database_name,
                    "message": "Database was empty and has been seeded with sample data"
                }

            except (cosmos_exceptions.CosmosResourceNotFoundError, cosmos_exceptions.CosmosHttpResponseError) as e:
                # Database or container doesn't exist - check if it's a "not found" type error
                error_message = str(e).lower()
                if "does not exist" in error_message or "notfound" in error_message or (hasattr(e, 'status_code') and e.status_code in [404, 500]):
                    logger.info(
                        "Database or container not found. Creating and seeding with sample data...")
                    result = await self._create_database_and_seed()
                    if result["status"] == "healthy":
                        return {
                            "status": "healthy",
                            "database": self.database_name,
                            "message": "Database and container created successfully with sample data"
                        }
                    else:
                        return result
                else:
                    # Re-raise if it's a different type of error
                    raise

        except Exception as e:
            logger.error(f"Health check failed: {e}")
            return {"status": "unhealthy", "error": str(e)}

    async def _create_database_and_seed(self) -> dict:
        """Create database, container, and seed with sample accessory data"""
        try:
            # Create database if it doesn't exist
            logger.info(f"Creating database: {self.database_name}")
            database = self.client.create_database_if_not_exists(
                id=self.database_name)

            # Create container if it doesn't exist
            logger.info(f"Creating container: {self.container_name}")
            container = database.create_container_if_not_exists(
                id=self.container_name,
                partition_key=PartitionKey(path="/id"),
                offer_throughput=400  # Minimum RU/s for manual throughput
            )

            # Update our references
            self.database = self.client.get_database_client(self.database_name)
            self.container = self.database.get_container_client(
                self.container_name)

            await self._database_seed()
            logger.info("Database setup and seeding completed successfully")
            return {
                "status": "healthy",
                "message": "Database and container created successfully with sample data"
            }

        except Exception as e:
            logger.error(f"Failed to create database and seed: {e}")
            return {"status": "unhealthy", "error": str(e)}

    async def _database_seed(self):
        """Seed the database with sample accessory data"""
        try:
            sample_accessories = [
                {
                    "name": "Squeaky Toy",
                    "type": "toy",
                    "price": 12.99,
                    "stock": 25,
                    "size": "M",
                    "imageUrl": "https://example.com/squeaky-toy.jpg",
                    "description": "Fun squeaky toy that keeps pets entertained"
                },
                {
                    "name": "Premium Dog Food",
                    "type": "food",
                    "price": 45.99,
                    "stock": 8,
                    "size": "L",
                    "imageUrl": "https://example.com/dog-food.jpg",
                    "description": "High-quality nutrition for active dogs (low stock)"
                }
            ]

            for accessory_data in sample_accessories:
                accessory = AccessoryCreate(**accessory_data)
                await self.create_accessory(accessory)

            logger.info(f"Seeded {len(sample_accessories)} sample accessories")

        except Exception as e:
            logger.error(f"Failed to seed database: {e}")
            raise

    async def create_accessory(self, accessory: AccessoryCreate) -> Accessory:
        """
        Create a new accessory

        Args:
            accessory: AccessoryCreate model with accessory data

        Returns:
            Created Accessory model with generated ID and timestamps
        """
        self._ensure_initialized()

        try:
            # Create full accessory object with metadata
            import uuid
            now = datetime.utcnow()
            accessory_dict = accessory.model_dump()
            accessory_dict["id"] = str(uuid.uuid4())  # Generate UUID
            accessory_dict["createdAt"] = now.isoformat()
            accessory_dict["updatedAt"] = now.isoformat()

            # Insert into CosmosDB
            created_item = self.container.create_item(body=accessory_dict)
            logger.info(f"Created accessory with ID: {created_item['id']}")

            return Accessory(**created_item)

        except cosmos_exceptions.CosmosResourceExistsError as e:
            logger.error(f"Accessory already exists: {e}")
            raise ValueError("Accessory with this ID already exists")
        except Exception as e:
            logger.error(f"Failed to create accessory: {e}")
            raise

    async def get_accessory(self, accessory_id: str) -> Optional[Accessory]:
        """
        Get an accessory by ID

        Args:
            accessory_id: The accessory ID

        Returns:
            Accessory model if found, None otherwise
        """
        self._ensure_initialized()

        try:
            item = self.container.read_item(
                item=accessory_id, partition_key=accessory_id)
            return Accessory(**item)

        except cosmos_exceptions.CosmosResourceNotFoundError:
            logger.info(f"Accessory not found: {accessory_id}")
            return None
        except Exception as e:
            logger.error(f"Failed to get accessory {accessory_id}: {e}")
            raise

    async def update_accessory(self, accessory_id: str, accessory_update: AccessoryUpdate) -> Optional[Accessory]:
        """
        Update an existing accessory

        Args:
            accessory_id: The accessory ID
            accessory_update: AccessoryUpdate model with fields to update

        Returns:
            Updated Accessory model if found, None otherwise
        """
        self._ensure_initialized()

        try:
            # Get existing accessory
            existing = await self.get_accessory(accessory_id)
            if not existing:
                return None

            # Update only provided fields
            update_data = accessory_update.model_dump(exclude_unset=True)
            # Use mode='json' to serialize datetime objects to ISO format strings
            existing_dict = existing.model_dump(mode='json')
            existing_dict.update(update_data)
            existing_dict["updatedAt"] = datetime.utcnow().isoformat()

            # Replace item in CosmosDB
            updated_item = self.container.replace_item(
                item=accessory_id, body=existing_dict)
            logger.info(f"Updated accessory with ID: {accessory_id}")

            return Accessory(**updated_item)

        except cosmos_exceptions.CosmosResourceNotFoundError:
            logger.info(f"Accessory not found for update: {accessory_id}")
            return None
        except Exception as e:
            logger.error(f"Failed to update accessory {accessory_id}: {e}")
            raise

    async def delete_accessory(self, accessory_id: str) -> bool:
        """
        Delete an accessory

        Args:
            accessory_id: The accessory ID

        Returns:
            True if deleted, False if not found
        """
        self._ensure_initialized()

        try:
            self.container.delete_item(
                item=accessory_id, partition_key=accessory_id)
            logger.info(f"Deleted accessory with ID: {accessory_id}")
            return True

        except cosmos_exceptions.CosmosResourceNotFoundError:
            logger.info(f"Accessory not found for deletion: {accessory_id}")
            return False
        except Exception as e:
            logger.error(f"Failed to delete accessory {accessory_id}: {e}")
            raise

    async def search_accessories(self, filters: AccessorySearchFilters) -> List[Accessory]:
        """
        Search accessories with filters and pagination

        Args:
            filters: AccessorySearchFilters model with search criteria

        Returns:
            List of matching Accessory models
        """
        self._ensure_initialized()

        try:
            # Build dynamic SQL query without WHERE 1=1 tautology
            query_parts = ["SELECT * FROM c"]
            where_clauses = []
            parameters = []

            # Add search filter (text search in name and description)
            # Note: CONTAINS is case-sensitive in CosmosDB emulator
            # For production, consider using LOWER() or case-insensitive collation
            if filters.search:
                where_clauses.append(
                    "(CONTAINS(c.name, @search) OR CONTAINS(c.description, @search))")
                parameters.append({"name": "@search", "value": filters.search})

            # Add type filter
            if filters.type:
                where_clauses.append("c.type = @type")
                parameters.append({"name": "@type", "value": filters.type})

            # Add low stock filter
            if filters.lowStockOnly:
                where_clauses.append("c.stock < 10")

            # Combine WHERE clauses
            if where_clauses:
                query_parts.append("WHERE " + " AND ".join(where_clauses))

            # Add ordering
            query_parts.append("ORDER BY c.createdAt DESC")

            # Add pagination
            query_parts.append(
                f"OFFSET {filters.offset} LIMIT {filters.limit}")

            # Build final query
            query = " ".join(query_parts)
            logger.info(
                f"Executing query: {query} with parameters: {parameters}")

            # Execute query
            items = list(self.container.query_items(
                query=query,
                parameters=parameters,
                enable_cross_partition_query=True
            ))

            accessories = [Accessory(**item) for item in items]
            logger.info(
                f"Found {len(accessories)} accessories matching filters")

            return accessories

        except Exception as e:
            logger.error(f"Failed to search accessories: {e}")
            raise


# Factory function to create service instance
def get_cosmos_service() -> AccessoryCosmosService:
    """Get configured AccessoryCosmosService instance"""
    from config import get_settings
    settings = get_settings()
    return AccessoryCosmosService(
        cosmos_endpoint=settings.cosmos_endpoint,
        cosmos_key=settings.cosmos_key,
        database_name=settings.cosmos_database_name,
        container_name=settings.cosmos_container_name
    )
