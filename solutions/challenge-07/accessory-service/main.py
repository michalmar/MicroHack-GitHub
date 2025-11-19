"""
Accessory Service FastAPI Application

This module provides the REST API for the Accessory Service using FastAPI.
It implements endpoints for managing pet accessories with proper validation,
error handling, and documentation.
"""

import logging
from contextlib import asynccontextmanager
from typing import List, Optional
from fastapi import FastAPI, HTTPException, Depends, Query, status
from fastapi.middleware.cors import CORSMiddleware

from models import Accessory, AccessoryCreate, AccessoryUpdate, AccessorySearchFilters
from database import get_cosmos_service, AccessoryCosmosService
from config import get_settings

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan manager for startup and shutdown events
    Uses lazy initialization to avoid blocking startup if CosmosDB is not available
    """
    logger.info("🚀 Accessory Service starting up...")
    logger.info(
        "Using lazy initialization - CosmosDB will be connected on first request")

    yield

    logger.info("🛑 Accessory Service shutting down...")


# Initialize FastAPI app
settings = get_settings()
app = FastAPI(
    title=settings.app_name,
    description="RESTful API for managing pet accessories with Azure CosmosDB backend",
    version=settings.app_version,
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Dependency injection for database service
def get_db_service() -> AccessoryCosmosService:
    """Dependency to get database service instance"""
    return get_cosmos_service()


# Exception handlers
@app.exception_handler(ValueError)
async def value_error_handler(request, exc):
    """Handle ValueError exceptions"""
    logger.error(f"ValueError: {exc}")
    return HTTPException(status_code=400, detail=str(exc))


@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    """Handle general exceptions"""
    logger.error(f"Unexpected error: {exc}")
    return HTTPException(status_code=500, detail="Internal server error")


###############################################################################
# HEALTH CHECK ENDPOINT
###############################################################################

@app.get("/health", tags=["Health"])
async def health_check(db_service: AccessoryCosmosService = Depends(get_db_service)):
    """
    Health check endpoint with auto-database setup

    If the database or container doesn't exist, they will be created automatically
    with sample accessory data for immediate testing.
    """
    try:
        result = await db_service.health_check()
        return result
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(
            status_code=503, detail=f"Service unavailable: {str(e)}")


@app.get("/", tags=["Root"])
async def root():
    """Root endpoint with API information"""
    return {
        "service": settings.app_name,
        "version": settings.app_version,
        "description": "RESTful API for managing pet accessories",
        "endpoints": {
            "health": "/health",
            "accessories": "/api/accessories",
            "docs": "/docs",
            "redoc": "/redoc"
        }
    }


###############################################################################
# ACCESSORY MANAGEMENT ENDPOINTS
###############################################################################

@app.get("/api/accessories", response_model=List[Accessory], tags=["Accessories"])
async def get_accessories(
    search: Optional[str] = Query(
        None, description="Search in name or description"),
    type: Optional[str] = Query(
        None, description="Filter by accessory type (toy|food|collar|bedding|grooming|other)"),
    lowStockOnly: Optional[bool] = Query(
        None, description="Show only items with stock < 10"),
    limit: int = Query(100, ge=1, le=1000,
                       description="Maximum number of results"),
    offset: int = Query(0, ge=0, description="Number of results to skip"),
    db_service: AccessoryCosmosService = Depends(get_db_service)
):
    """
    Get accessories with optional filtering and pagination

    - **search**: Search text in name or description
    - **type**: Filter by accessory type (toy, food, collar, bedding, grooming, other)
    - **lowStockOnly**: Show only items with stock < 10
    - **limit**: Maximum number of results (1-1000, default: 100)
    - **offset**: Number of results to skip for pagination (default: 0)
    """
    try:
        # Create search filters
        filters = AccessorySearchFilters(
            search=search,
            type=type,
            lowStockOnly=lowStockOnly,
            limit=limit,
            offset=offset
        )

        # Search accessories
        accessories = await db_service.search_accessories(filters)
        return accessories

    except Exception as e:
        logger.error(f"Failed to get accessories: {e}")
        raise HTTPException(
            status_code=500, detail=f"Failed to retrieve accessories: {str(e)}")


@app.post("/api/accessories", response_model=Accessory, status_code=status.HTTP_201_CREATED, tags=["Accessories"])
async def create_accessory(
    accessory: AccessoryCreate,
    db_service: AccessoryCosmosService = Depends(get_db_service)
):
    """
    Create a new accessory

    - **name**: Name of the accessory (1-200 characters)
    - **type**: Type of accessory (toy, food, collar, bedding, grooming, other)
    - **price**: Price (must be >= 0)
    - **stock**: Stock quantity (must be >= 0)
    - **size**: Size category (S, M, L, XL)
    - **imageUrl**: Optional URL to accessory image
    - **description**: Optional description (max 2000 characters)
    """
    try:
        created_accessory = await db_service.create_accessory(accessory)
        logger.info(f"Created accessory: {created_accessory.id}")
        return created_accessory

    except ValueError as e:
        logger.error(f"Validation error creating accessory: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to create accessory: {e}")
        raise HTTPException(
            status_code=500, detail=f"Failed to create accessory: {str(e)}")


@app.get("/api/accessories/{accessory_id}", response_model=Accessory, tags=["Accessories"])
async def get_accessory(
    accessory_id: str,
    db_service: AccessoryCosmosService = Depends(get_db_service)
):
    """
    Get a specific accessory by ID

    - **accessory_id**: The unique identifier of the accessory
    """
    try:
        accessory = await db_service.get_accessory(accessory_id)
        if not accessory:
            raise HTTPException(
                status_code=404, detail=f"Accessory not found: {accessory_id}")
        return accessory

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get accessory {accessory_id}: {e}")
        raise HTTPException(
            status_code=500, detail=f"Failed to retrieve accessory: {str(e)}")


@app.patch("/api/accessories/{accessory_id}", response_model=Accessory, tags=["Accessories"])
async def update_accessory(
    accessory_id: str,
    accessory_update: AccessoryUpdate,
    db_service: AccessoryCosmosService = Depends(get_db_service)
):
    """
    Update an existing accessory (partial update)

    All fields are optional. Only provided fields will be updated.

    - **name**: Name of the accessory (1-200 characters)
    - **type**: Type of accessory (toy, food, collar, bedding, grooming, other)
    - **price**: Price (must be >= 0)
    - **stock**: Stock quantity (must be >= 0)
    - **size**: Size category (S, M, L, XL)
    - **imageUrl**: URL to accessory image
    - **description**: Description (max 2000 characters)
    """
    try:
        updated_accessory = await db_service.update_accessory(accessory_id, accessory_update)
        if not updated_accessory:
            raise HTTPException(
                status_code=404, detail=f"Accessory not found: {accessory_id}")

        logger.info(f"Updated accessory: {accessory_id}")
        return updated_accessory

    except HTTPException:
        raise
    except ValueError as e:
        logger.error(f"Validation error updating accessory: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to update accessory {accessory_id}: {e}")
        raise HTTPException(
            status_code=500, detail=f"Failed to update accessory: {str(e)}")


@app.delete("/api/accessories/{accessory_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Accessories"])
async def delete_accessory(
    accessory_id: str,
    db_service: AccessoryCosmosService = Depends(get_db_service)
):
    """
    Delete an accessory

    - **accessory_id**: The unique identifier of the accessory to delete
    """
    try:
        deleted = await db_service.delete_accessory(accessory_id)
        if not deleted:
            raise HTTPException(
                status_code=404, detail=f"Accessory not found: {accessory_id}")

        logger.info(f"Deleted accessory: {accessory_id}")
        return None

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete accessory {accessory_id}: {e}")
        raise HTTPException(
            status_code=500, detail=f"Failed to delete accessory: {str(e)}")


###############################################################################
# APPLICATION RUNNER
###############################################################################

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8030, reload=settings.debug)
