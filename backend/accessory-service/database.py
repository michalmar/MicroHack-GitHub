"""
Azure CosmosDB Service for Accessory Management

This module provides a service layer for interacting with Azure CosmosDB
following Azure best practices for authentication, error handling, and performance.
"""

import logging
from typing import List, Optional, Dict, Any
from datetime import datetime

from azure.cosmos import CosmosClient, exceptions as cosmos_exceptions, PartitionKey

from config import get_settings
from models import Accessory, AccessoryCreate, AccessoryUpdate, AccessorySearchFilters

# Configure logging
logger = logging.getLogger(__name__)


class AccessoryCosmosDBService:
    """
    Service class for Azure CosmosDB operations for accessories
    
    Implements Azure best practices:
    - Uses key-based authentication for CosmosDB
    - Implements proper error handling and retry logic
    - Uses connection pooling and proper resource management
    """
    
    def __init__(self):
        self.settings = get_settings()
        self.client: Optional[CosmosClient] = None
        self.database = None
        self.container = None
        self._initialized = False

    def _ensure_initialized(self):
        """Ensure CosmosDB client is initialized (lazy initialization)"""
        if self._initialized:
            return
            
        try:
            logger.info("Initializing CosmosDB connection with key-based authentication")
            
            # Create CosmosDB client with key authentication
            self.client = CosmosClient(
                self.settings.cosmos_endpoint,
                credential=self.settings.cosmos_key,
                # Enable connection pooling and set timeouts
                connection_timeout=30,
                request_timeout=30
            )
            
            # Get database and container references
            self.database = self.client.get_database_client(self.settings.cosmos_database_name)
            self.container = self.database.get_container_client(self.settings.cosmos_container_name)
            
            self._initialized = True
            logger.info(f"Successfully connected to CosmosDB: {self.settings.cosmos_database_name}/{self.settings.cosmos_container_name}")
            
        except Exception as e:
            logger.error(f"Failed to initialize CosmosDB client: {e}")
            raise

    async def health_check(self) -> Dict[str, Any]:
        """
        Health check for the CosmosDB connection
        
        If database or container doesn't exist, creates them and seeds with sample data
        """
        try:
            # Ensure client is initialized
            self._ensure_initialized()
            
            # Try to perform a simple query to verify connection
            try:
                list(self.container.query_items(
                    query="SELECT TOP 1 c.id FROM c",
                    enable_cross_partition_query=True,
                    max_item_count=1
                ))
                return {"status": "healthy", "database": self.settings.cosmos_database_name}
                
            except (cosmos_exceptions.CosmosResourceNotFoundError, cosmos_exceptions.CosmosHttpResponseError) as e:
                # Database or container doesn't exist - check if it's a "not found" type error
                error_message = str(e).lower()
                if "does not exist" in error_message or "notfound" in error_message or (hasattr(e, 'status_code') and e.status_code in [404, 500]):
                    logger.info("Database or container not found. Creating and seeding with sample data...")
                    await self._create_database_and_seed()
                    return {
                        "status": "healthy", 
                        "database": self.settings.cosmos_database_name,
                        "message": "Database and container created successfully with sample data"
                    }
                else:
                    # Re-raise if it's a different type of error
                    raise
                
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            return {"status": "unhealthy", "error": str(e)}

    async def _create_database_and_seed(self):
        """Create database, container and seed with sample data"""
        try:
            # Create database if it doesn't exist
            logger.info(f"Creating database: {self.settings.cosmos_database_name}")
            database = self.client.create_database_if_not_exists(
                id=self.settings.cosmos_database_name
            )
            
            # Create container if it doesn't exist
            logger.info(f"Creating container: {self.settings.cosmos_container_name}")
            container = database.create_container_if_not_exists(
                id=self.settings.cosmos_container_name,
                partition_key=PartitionKey(path="/id"),
                offer_throughput=400  # Minimum RU/s for manual throughput
            )
            
            # Update our references
            self.database = self.client.get_database_client(self.settings.cosmos_database_name)
            self.container = self.database.get_container_client(self.settings.cosmos_container_name)
            
            # Seed with sample data
            logger.info("Seeding container with sample accessory data")
            sample_accessories = [
                {
                    "id": "x1",
                    "name": "Chew Toy",
                    "type": "toy",
                    "price": 8.99,
                    "stock": 12,
                    "size": "M",
                    "imageUrl": "",
                    "description": "Durable rope",
                    "createdAt": datetime.utcnow().isoformat(),
                    "updatedAt": datetime.utcnow().isoformat()
                },
                {
                    "id": "x2",
                    "name": "Salmon Treats",
                    "type": "food",
                    "price": 5.49,
                    "stock": 3,
                    "size": "S",
                    "imageUrl": "",
                    "description": "Soft chews",
                    "createdAt": datetime.utcnow().isoformat(),
                    "updatedAt": datetime.utcnow().isoformat()
                }
            ]
            
            # Insert sample accessories
            for accessory_data in sample_accessories:
                try:
                    self.container.create_item(body=accessory_data)
                    logger.info(f"Seeded accessory: {accessory_data['name']} ({accessory_data['id']})")
                except cosmos_exceptions.CosmosResourceExistsError:
                    # Accessory already exists, skip
                    logger.info(f"Accessory {accessory_data['name']} ({accessory_data['id']}) already exists, skipping")
                    pass
            
            logger.info("Database setup and seeding completed successfully")
            
        except Exception as e:
            logger.error(f"Failed to create database and seed data: {e}")
            raise

    def create_accessory(self, accessory_data: AccessoryCreate) -> Accessory:
        """
        Create a new accessory in CosmosDB
        
        Args:
            accessory_data: Accessory creation data
            
        Returns:
            Created Accessory object
            
        Raises:
            CosmosDBError: If creation fails
        """
        try:
            # Ensure client is initialized
            self._ensure_initialized()
            # Create Accessory object with generated ID and timestamps
            accessory = Accessory(**accessory_data.model_dump())
            accessory_dict = accessory.model_dump(mode='json')
            
            # Insert into CosmosDB
            response = self.container.create_item(body=accessory_dict)
            logger.info(f"Created accessory with ID: {accessory.id}")
            
            return Accessory(**response)
            
        except cosmos_exceptions.CosmosResourceExistsError:
            logger.error(f"Accessory with ID {accessory.id} already exists")
            raise ValueError(f"Accessory with ID {accessory.id} already exists")
        except cosmos_exceptions.CosmosHttpResponseError as e:
            logger.error(f"CosmosDB HTTP error creating accessory: {e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error creating accessory: {e}")
            raise

    def get_accessory(self, accessory_id: str) -> Optional[Accessory]:
        """
        Get an accessory by ID
        
        Args:
            accessory_id: Accessory identifier
            
        Returns:
            Accessory object if found, None otherwise
        """
        try:
            # Ensure client is initialized
            self._ensure_initialized()
            response = self.container.read_item(item=accessory_id, partition_key=accessory_id)
            return Accessory(**response)
            
        except cosmos_exceptions.CosmosResourceNotFoundError:
            logger.info(f"Accessory not found: {accessory_id}")
            return None
        except cosmos_exceptions.CosmosHttpResponseError as e:
            logger.error(f"CosmosDB HTTP error getting accessory {accessory_id}: {e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error getting accessory {accessory_id}: {e}")
            raise

    def update_accessory(self, accessory_id: str, update_data: AccessoryUpdate) -> Optional[Accessory]:
        """
        Update an accessory by ID
        
        Args:
            accessory_id: Accessory identifier
            update_data: Accessory update data
            
        Returns:
            Updated Accessory object if successful, None if not found
        """
        try:
            # Ensure client is initialized
            self._ensure_initialized()
            # Get existing accessory
            existing_accessory = self.get_accessory(accessory_id)
            if not existing_accessory:
                return None
            
            # Apply updates
            update_dict = update_data.model_dump(exclude_unset=True)
            if not update_dict:
                return existing_accessory  # No changes
            
            # Update the existing accessory data (with JSON serialization)
            accessory_dict = existing_accessory.model_dump(mode='json')
            accessory_dict.update(update_dict)
            accessory_dict['updatedAt'] = datetime.utcnow().isoformat()
            
            # Update in CosmosDB
            response = self.container.replace_item(item=accessory_id, body=accessory_dict)
            logger.info(f"Updated accessory: {accessory_id}")
            
            return Accessory(**response)
            
        except cosmos_exceptions.CosmosResourceNotFoundError:
            logger.info(f"Accessory not found for update: {accessory_id}")
            return None
        except cosmos_exceptions.CosmosHttpResponseError as e:
            logger.error(f"CosmosDB HTTP error updating accessory {accessory_id}: {e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error updating accessory {accessory_id}: {e}")
            raise

    def delete_accessory(self, accessory_id: str) -> bool:
        """
        Delete an accessory by ID
        
        Args:
            accessory_id: Accessory identifier
            
        Returns:
            True if deleted, False if not found
        """
        try:
            # Ensure client is initialized
            self._ensure_initialized()
            self.container.delete_item(item=accessory_id, partition_key=accessory_id)
            logger.info(f"Deleted accessory: {accessory_id}")
            return True
            
        except cosmos_exceptions.CosmosResourceNotFoundError:
            logger.info(f"Accessory not found for deletion: {accessory_id}")
            return False
        except cosmos_exceptions.CosmosHttpResponseError as e:
            logger.error(f"CosmosDB HTTP error deleting accessory {accessory_id}: {e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error deleting accessory {accessory_id}: {e}")
            raise

    def search_accessories(self, filters: AccessorySearchFilters) -> List[Accessory]:
        """
        Search accessories with filtering support
        
        Args:
            filters: Search and filter parameters
            
        Returns:
            List of Accessory objects matching the criteria
        """
        try:
            # Ensure client is initialized
            self._ensure_initialized()
            # Build SQL query based on filters
            query_parts = ["SELECT * FROM c"]
            parameters = []
            conditions = []

            # Add search condition (name or description) - emulator-compatible version
            if filters.search:
                conditions.append("(CONTAINS(c.name, @search) OR CONTAINS(c.description, @search))")
                parameters.append({"name": "@search", "value": filters.search})

            # Add type filter
            if filters.type:
                conditions.append("c.type = @type")
                parameters.append({"name": "@type", "value": filters.type})

            # Add low stock filter
            if filters.lowStockOnly:
                conditions.append("c.stock < 10")

            # Add WHERE clause if there are conditions
            if conditions:
                query_parts.append("WHERE " + " AND ".join(conditions))

            # Add ordering and pagination
            query_parts.append("ORDER BY c.createdAt DESC")
            query_parts.append(f"OFFSET {filters.offset} LIMIT {filters.limit}")

            query = " ".join(query_parts)
            logger.debug(f"Executing query: {query} with parameters: {parameters}")

            # Execute query
            items = list(self.container.query_items(
                query=query,
                parameters=parameters,
                enable_cross_partition_query=True,
                max_item_count=filters.limit
            ))

            # Convert to Accessory objects
            accessories = []
            for item in items:
                try:
                    accessories.append(Accessory(**item))
                except Exception as e:
                    logger.warning(f"Failed to parse accessory item: {e}")
                    continue

            logger.info(f"Found {len(accessories)} accessories matching criteria")
            return accessories

        except cosmos_exceptions.CosmosHttpResponseError as e:
            logger.error(f"CosmosDB HTTP error searching accessories: {e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error searching accessories: {e}")
            raise

    def get_all_accessories(self, limit: int = 100, offset: int = 0) -> List[Accessory]:
        """
        Get all accessories with pagination
        
        Args:
            limit: Maximum number of accessories to return
            offset: Number of accessories to skip
            
        Returns:
            List of Accessory objects
        """
        filters = AccessorySearchFilters(limit=limit, offset=offset)
        return self.search_accessories(filters)


# Singleton instance
_cosmos_service: Optional[AccessoryCosmosDBService] = None


def get_cosmos_service() -> AccessoryCosmosDBService:
    """Get singleton CosmosDB service instance"""
    global _cosmos_service
    if _cosmos_service is None:
        _cosmos_service = AccessoryCosmosDBService()
    return _cosmos_service