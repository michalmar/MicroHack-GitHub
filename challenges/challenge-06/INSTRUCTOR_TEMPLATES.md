# Instructor Templates for Challenge 06

## Overview
This document provides ready-to-use template files that instructors should use to replace the current complete implementation. These templates provide the right balance of structure and learning opportunity.

---

## Template 1: models.py (Student Version)

```python
"""
Accessory Model Definition

This module defines the Accessory data model using Pydantic for validation
and type checking, following Azure CosmosDB best practices.

TODO: Implement all model classes following the schema specification in Task 3 of the challenge.
"""

import uuid
from typing import Optional, Literal
from pydantic import BaseModel, Field
from datetime import datetime


class AccessoryBase(BaseModel):
    """
    Base Accessory model with common fields
    
    TODO: Add the following fields with proper validation:
    - name: str (min 1 char, max 200 chars)
    - type: Literal type for accessory types (toy, food, collar, bedding, grooming, other)
    - price: float (must be >= 0)
    - stock: int (must be >= 0)
    - size: Literal type for sizes (S, M, L, XL)
    - imageUrl: Optional[str]
    - description: Optional[str] (max 2000 chars)
    
    Use Field(...) for required fields and Field(None) for optional fields.
    Include description parameter in Field() for documentation.
    """
    pass


class AccessoryCreate(AccessoryBase):
    """
    Model for creating a new accessory
    
    TODO: This class should inherit all fields from AccessoryBase.
    No additional fields needed - the base fields are sufficient for creation.
    """
    pass


class AccessoryUpdate(BaseModel):
    """
    Model for updating an existing accessory
    
    TODO: Make all fields from AccessoryBase optional for partial updates.
    Each field should use Optional[type] and Field(None).
    This allows updating only specific fields without providing all data.
    """
    pass


class Accessory(AccessoryBase):
    """
    Complete Accessory model with ID and metadata
    
    TODO: Add the following system-generated fields:
    - id: str with default_factory that generates a UUID string
    - createdAt: datetime with default_factory using datetime.utcnow
    - updatedAt: datetime with default_factory using datetime.utcnow
    
    Also add a Config class with:
    - from_attributes = True
    - json_encoders for datetime (convert to ISO format)
    """
    pass


class AccessorySearchFilters(BaseModel):
    """
    Model for search and filter parameters
    
    TODO: Add the following query parameters:
    - search: Optional[str] for searching in name/description
    - type: Optional[Literal[...]] for filtering by accessory type
    - lowStockOnly: Optional[bool] for showing items with stock < 10
    - limit: int with default 100, min 1, max 1000
    - offset: int with default 0, min 0
    
    Use Field() to set defaults and constraints.
    """
    pass


# HINTS for using GitHub Copilot:
# 1. Start by writing a comment describing each field, then let Copilot suggest
# 2. Use: "# name should be a required string between 1 and 200 characters"
# 3. Reference the challenge document Task 3 for exact specifications
# 4. Look at pet-service/models.py for similar patterns
# 5. Test your models by importing them in main.py
```

---

## Template 2: database.py (Student Version)

```python
"""
Azure CosmosDB Service for Accessory Management

This module provides the database service layer for accessories using Azure CosmosDB.
It follows the implementation pattern used by activity-service and pet-service.

TODO: Implement all database operations following the patterns from other services.
"""

import logging
import os
from datetime import datetime
from typing import Any, Dict, List, Optional

from azure.cosmos import CosmosClient, PartitionKey
from azure.cosmos import exceptions as cosmos_exceptions

from models import Accessory, AccessoryCreate, AccessoryUpdate, AccessorySearchFilters

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class AccessoryCosmosService:
    """Service class for managing accessories in Azure CosmosDB."""

    def __init__(
        self,
        cosmos_endpoint: str,
        cosmos_key: str,
        database_name: str = "accessoryservice",
        container_name: str = "accessories",
    ):
        """
        Initialize the CosmosDB service for accessories.
        
        Uses lazy initialization - connection is established on first use.
        """
        self.cosmos_endpoint = cosmos_endpoint
        self.cosmos_key = cosmos_key
        self.database_name = database_name
        self.container_name = container_name

        # These will be initialized lazily
        self.client: Optional[CosmosClient] = None
        self.database = None
        self.container = None

        logger.info("AccessoryCosmosService initialized with lazy loading")

    def _build_cosmos_client_options(self) -> Dict[str, Any]:
        """
        Build CosmosClient configuration for consistent usage across services.
        
        TODO: Create a dictionary with connection options:
        - url: self.cosmos_endpoint
        - credential: self.cosmos_key
        - connection_timeout: 30
        - request_timeout: 30
        
        HINT: Check if COSMOS_EMULATOR_DISABLE_SSL_VERIFY environment variable is set.
        If it is, add connection_verify: False for local emulator support.
        Look at activity-service/database.py for the pattern.
        """
        pass

    def _ensure_initialized(self):
        """
        Ensure the CosmosDB client, database, and container are initialized.
        
        TODO: Implement lazy initialization:
        1. If self.client is None, create CosmosClient using _build_cosmos_client_options()
        2. If self.database is None, get database client using self.client.get_database_client()
        3. If self.container is None, get container client using self.database.get_container_client()
        
        Add appropriate logging at each step.
        
        HINT: Use GitHub Copilot with prompt:
        "Implement lazy initialization for Cosmos DB client, database, and container"
        """
        pass

    async def health_check(self) -> Dict[str, Any]:
        """
        Perform health check and auto-create database/container if needed.
        
        TODO: Implement health check logic:
        1. Call _ensure_initialized()
        2. Try to query the container (SELECT TOP 1 c.id FROM c)
        3. If successful, return {"status": "healthy", "database": self.database_name}
        4. If database/container not found (404 error), call _create_database_and_seed()
        5. Handle other exceptions and return {"status": "unhealthy", "error": str(e)}
        
        HINT: Look at activity-service/database.py health_check method for the pattern.
        Use try/except with cosmos_exceptions.CosmosResourceNotFoundError
        """
        pass

    async def _create_database_and_seed(self) -> Dict[str, Any]:
        """
        Create database, container, and seed with sample accessory data.
        
        TODO: Implement database creation and seeding:
        1. Create database if not exists using self.client.create_database_if_not_exists()
        2. Create container with:
           - id: self.container_name
           - partition_key: PartitionKey(path="/id")
           - offer_throughput: 400
        3. Update self.database and self.container references
        4. Create 2 sample accessories:
           - x1: Chew Toy (toy), $8.99, stock: 12, size: M
           - x2: Salmon Treats (food), $5.49, stock: 3, size: S (low stock!)
        5. Insert them using self.container.create_item()
        6. Return success message
        
        HINT: Sample data helps with immediate testing. Include createdAt and updatedAt.
        """
        pass

    def create_accessory(self, accessory_data: AccessoryCreate) -> Accessory:
        """
        Create a new accessory in CosmosDB.
        
        TODO: Implement create operation:
        1. Call _ensure_initialized()
        2. Create an Accessory object from accessory_data (includes auto-generated id and timestamps)
        3. Convert to dict using accessory.model_dump(mode="json")
        4. Insert using self.container.create_item(body=accessory_dict)
        5. Return Accessory object created from response
        
        Handle exceptions:
        - CosmosResourceExistsError: raise ValueError("Accessory already exists")
        - Other errors: log and re-raise
        
        HINT: Use Copilot prompt: "Implement Cosmos DB create operation with error handling"
        """
        pass

    def get_accessory(self, accessory_id: str) -> Optional[Accessory]:
        """
        Get an accessory by ID.
        
        TODO: Implement get operation:
        1. Call _ensure_initialized()
        2. Use self.container.read_item(item=accessory_id, partition_key=accessory_id)
        3. Return Accessory object if found
        4. Return None if CosmosResourceNotFoundError
        5. Log and re-raise other exceptions
        
        HINT: The partition key is the id field in our schema.
        """
        pass

    def update_accessory(
        self, accessory_id: str, update_data: AccessoryUpdate
    ) -> Optional[Accessory]:
        """
        Update an accessory by ID.
        
        TODO: Implement update operation:
        1. Get existing accessory using get_accessory()
        2. If not found, return None
        3. Get update dict using update_data.model_dump(exclude_unset=True)
        4. If empty update, return existing accessory unchanged
        5. Update the existing accessory dict with new values
        6. Update the updatedAt timestamp to datetime.utcnow().isoformat()
        7. Replace item using self.container.replace_item()
        8. Return updated Accessory object
        
        HINT: exclude_unset=True ensures only provided fields are updated (partial update).
        """
        pass

    def delete_accessory(self, accessory_id: str) -> bool:
        """
        Delete an accessory by ID.
        
        TODO: Implement delete operation:
        1. Call _ensure_initialized()
        2. Use self.container.delete_item(item=accessory_id, partition_key=accessory_id)
        3. Log the deletion and return True
        4. Return False if CosmosResourceNotFoundError (not found)
        5. Log and re-raise other exceptions
        
        HINT: Simple operation - just delete and return success/failure.
        """
        pass

    def search_accessories(self, filters: AccessorySearchFilters) -> List[Accessory]:
        """
        Search accessories with filtering support.
        
        TODO: Implement search with dynamic SQL query:
        1. Call _ensure_initialized()
        2. Start building query: ["SELECT * FROM c"]
        3. Build WHERE conditions based on filters:
           - If filters.search: add CONTAINS(c.name, @search) OR CONTAINS(c.description, @search)
           - If filters.type: add c.type = @type
           - If filters.lowStockOnly: add c.stock < 10
        4. Join conditions with AND
        5. Add ORDER BY c.createdAt DESC
        6. Add OFFSET {filters.offset} LIMIT {filters.limit}
        7. Build parameters list: [{"name": "@search", "value": filters.search}, ...]
        8. Execute query with enable_cross_partition_query=True
        9. Parse results into Accessory objects
        10. Return list of accessories
        
        HINT: This is the most complex method. Break it into steps:
        - Build query string dynamically
        - Build parameters list dynamically
        - Execute query
        - Parse results
        
        Use Copilot prompt: "Create dynamic Cosmos DB SQL query with optional filters"
        """
        pass

    def get_all_accessories(self, limit: int = 100, offset: int = 0) -> List[Accessory]:
        """
        Get all accessories with pagination support.
        
        TODO: Use search_accessories with empty filters for pagination.
        Create AccessorySearchFilters with only limit and offset set.
        """
        pass


def get_cosmos_service() -> AccessoryCosmosService:
    """
    Factory function to create and return a CosmosDB service instance.
    
    This is already implemented - it loads settings and creates the service.
    """
    from config import get_settings

    settings = get_settings()
    return AccessoryCosmosService(
        cosmos_endpoint=settings.cosmos_endpoint,
        cosmos_key=settings.cosmos_key,
        database_name=settings.cosmos_database_name,
        container_name=settings.cosmos_container_name,
    )


# IMPLEMENTATION TIPS:
# 1. Implement methods one at a time, starting with _ensure_initialized
# 2. Test each method as you go using main.py endpoints
# 3. Reference activity-service/database.py for similar patterns
# 4. Use try/except blocks for proper error handling
# 5. Add logging for all operations (INFO for success, ERROR for failures)
# 6. The search_accessories method is most complex - save it for last
```

---

## Template 3: main.py (Student Version)

```python
"""
Accessory Service FastAPI Application

This module implements a REST API for accessory management using FastAPI and Azure CosmosDB.
Follows Azure best practices for authentication, error handling, and API design.

TODO: Implement all API endpoints following the patterns from pet-service and activity-service.
"""

import logging
from typing import List, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Depends, Query, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from config import get_settings
from models import Accessory, AccessoryCreate, AccessoryUpdate, AccessorySearchFilters
from database import get_cosmos_service, AccessoryCosmosService

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager"""
    logger.info("Starting Accessory Service API")
    logger.info("CosmosDB connection will be established when first needed")
    
    yield
    
    # Shutdown
    logger.info("Shutting down Accessory Service API")


# Initialize FastAPI app
settings = get_settings()
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="Accessory management API with Azure CosmosDB backend",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Dependency to get CosmosDB service
def get_db() -> AccessoryCosmosService:
    """Dependency to get CosmosDB service instance"""
    return get_cosmos_service()


# Exception handlers
@app.exception_handler(ValueError)
async def value_error_handler(request, exc: ValueError):
    """
    Handle validation errors
    
    TODO: Return a JSONResponse with:
    - status_code: status.HTTP_400_BAD_REQUEST
    - content: {"detail": str(exc)}
    """
    pass


@app.exception_handler(Exception)
async def general_exception_handler(request, exc: Exception):
    """
    Handle general exceptions
    
    TODO: 
    1. Log the error using logger.error()
    2. Return JSONResponse with:
       - status_code: status.HTTP_500_INTERNAL_SERVER_ERROR
       - content: {"detail": "An internal error occurred"}
    """
    pass


# API Routes - TODO: Implement all endpoints

# TODO: Implement GET / endpoint
# Return: service name, version, status: "healthy"
# Tags: ["Health"]


# TODO: Implement GET /health endpoint
# Call: db.health_check()
# Return: health check result
# Handle: HTTPException with 503 if unhealthy
# Tags: ["Health"]


# TODO: Implement GET /api/accessories endpoint
# Query params: search, type, lowStockOnly, limit, offset (use Query())
# Validate: type must be one of valid_types
# Call: db.search_accessories() with filters
# Return: List[Accessory]
# Tags: ["Accessories"]
# HINT: Validate type against valid_types = ["toy", "food", "collar", "bedding", "grooming", "other"]


# TODO: Implement POST /api/accessories endpoint
# Input: AccessoryCreate
# Response: Accessory with status 201
# Call: db.create_accessory()
# Handle: ValueError -> 400, other errors -> 500
# Tags: ["Accessories"]


# TODO: Implement GET /api/accessories/{accessory_id} endpoint
# Input: accessory_id: str
# Response: Accessory
# Call: db.get_accessory()
# Handle: Return 404 if not found
# Tags: ["Accessories"]


# TODO: Implement PATCH /api/accessories/{accessory_id} endpoint
# Input: accessory_id: str, AccessoryUpdate
# Response: Accessory
# Call: db.update_accessory()
# Handle: Return 404 if not found
# Tags: ["Accessories"]


# TODO: Implement DELETE /api/accessories/{accessory_id} endpoint
# Input: accessory_id: str
# Response: 204 No Content
# Call: db.delete_accessory()
# Handle: Return 404 if not found, else return None (204)
# Tags: ["Accessories"]


if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8030,  # Different port from Pet (8010) and Activity (8020) Services
        reload=settings.debug,
        log_level="info"
    )


# IMPLEMENTATION GUIDE:
# 
# 1. Start with root and health endpoints (simple)
# 2. Implement POST /api/accessories (test creating accessories)
# 3. Implement GET /api/accessories (test listing)
# 4. Implement GET /api/accessories/{id} (test getting one)
# 5. Implement PATCH and DELETE (complete CRUD)
# 6. Test each endpoint using accessory-service.http as you go
#
# COPILOT TIPS:
# - Write a comment describing the endpoint, then let Copilot generate
# - Example: "# Create an endpoint that lists all accessories with filtering"
# - Use @app.get(), @app.post(), @app.patch(), @app.delete() decorators
# - Use Depends(get_db) to inject database service
# - Use Query() for query parameters with defaults
# - Use response_model and status_code in decorators
#
# TESTING:
# - Use accessory-service.http file to test each endpoint
# - Check logs for errors
# - Verify data in Cosmos DB emulator UI
```

---

## Template 4: config.py (Keep Complete)

This file can be kept as-is since it's straightforward and follows the pattern from other services. Students can reference it or copy the pattern.

---

## Template 5: requirements.txt (Keep Complete)

```txt
# FastAPI and web server dependencies
fastapi==0.104.1
uvicorn[standard]==0.24.0

# Data validation and serialization
pydantic==2.5.0
python-dotenv==1.0.0

# Azure CosmosDB integration
azure-cosmos==4.5.1
azure-identity==1.15.0

# Additional utilities
python-multipart==0.0.6
requests==2.31.0

# Development and testing (optional)
pytest==7.4.3
pytest-asyncio==0.21.1
httpx==0.25.2
```

Keep this complete - dependency management is not the focus.

---

## Template 6: .env.example (Keep Complete)

```env
# Azure CosmosDB Configuration
COSMOS_ENDPOINT=http://localhost:8081/
COSMOS_KEY=C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==
COSMOS_DATABASE_NAME=accessoryservice
COSMOS_CONTAINER_NAME=accessories

# Cosmos DB Emulator SSL Bypass (for local development only)
COSMOS_EMULATOR_DISABLE_SSL_VERIFY=1

# Application Configuration
DEBUG=false
```

Keep this complete - shows proper configuration structure.

---

## Template 7: accessory-service.http (Keep Complete)

This file is the test specification and acceptance criteria. Keep it completely unchanged.

---

## Setup Script for Instructors

Create a simple script to set up the student template:

```bash
#!/bin/bash
# setup-challenge.sh

echo "Setting up Challenge 06 student template..."

STUDENT_DIR="backend/accessory-service-student"
TEMPLATE_DIR="challenges/challenge-06/templates"

# Create student directory
mkdir -p $STUDENT_DIR

# Copy template files
cp $TEMPLATE_DIR/models.py $STUDENT_DIR/
cp $TEMPLATE_DIR/database.py $STUDENT_DIR/
cp $TEMPLATE_DIR/main.py $STUDENT_DIR/

# Copy complete files
cp backend/accessory-service/config.py $STUDENT_DIR/
cp backend/accessory-service/requirements.txt $STUDENT_DIR/
cp backend/accessory-service/.env.example $STUDENT_DIR/
cp backend/accessory-service/accessory-service.http $STUDENT_DIR/

# Create empty .env
cp $STUDENT_DIR/.env.example $STUDENT_DIR/.env

echo "Student template created at: $STUDENT_DIR"
echo ""
echo "Next steps for students:"
echo "1. cd $STUDENT_DIR"
echo "2. pip install -r requirements.txt"
echo "3. Start Cosmos DB emulator"
echo "4. Follow challenge instructions in challenges/challenge-06/README.md"
```

---

## Verification Checklist for Instructors

Before releasing to students:

- [ ] All template files have TODO comments
- [ ] Template files don't have syntax errors
- [ ] Imports work (can load modules)
- [ ] Config.py and requirements.txt are complete
- [ ] .env.example has correct values
- [ ] accessory-service.http is unchanged
- [ ] Challenge README is updated and clear
- [ ] Solution branch exists with complete code
- [ ] Tested: can implement from templates in 2-4 hours
- [ ] All HTTP tests pass with complete solution

---

## Quick Start for Students

Provide this to students:

```bash
# 1. Clone repository
git clone <repo-url>
cd MicroHack-GitHub

# 2. Navigate to challenge directory
cd backend/accessory-service

# 3. Install dependencies
pip install -r requirements.txt

# 4. Set up environment
cp .env.example .env
# Edit .env if needed (default values should work)

# 5. Start Cosmos DB emulator (in another terminal)
docker run --name cosmos-emulator --detach \
  --publish 8081:8081 --publish 1234:1234 \
  mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator:vnext-preview

# 6. Open challenge instructions
# Read: challenges/challenge-06/README.md

# 7. Start coding!
# Implement: models.py → database.py → main.py

# 8. Test as you go
# Use: accessory-service.http to test each endpoint

# 9. Run the service
python main.py

# 10. Verify
# Open http://localhost:8030/docs
```

---

## Summary

These templates provide the optimal balance:
- ✅ Clear structure and guidance
- ✅ Enough work to be challenging
- ✅ Not overwhelming or frustrating
- ✅ Copilot-friendly with comments
- ✅ Follows established patterns
- ✅ Testable with provided HTTP file

Students will gain practical experience with:
- Pydantic data modeling
- Azure Cosmos DB operations
- FastAPI endpoint implementation
- Search and filtering logic
- Error handling
- Testing and integration

**Estimated completion time: 2-4 hours**
