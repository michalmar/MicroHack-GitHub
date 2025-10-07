"""
Configuration module for Accessory Service

Handles environment variables and Azure CosmosDB configuration
following Azure best practices for credential management.
"""

import os
from typing import Optional
from functools import lru_cache
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


class Settings:
    """Application settings and configuration"""
    
    def __init__(self):
        # CosmosDB Configuration
        self.cosmos_endpoint: str = os.getenv("COSMOS_ENDPOINT", "")
        self.cosmos_key: str = os.getenv("COSMOS_KEY", "")
        self.cosmos_database_name: str = os.getenv("COSMOS_DATABASE_NAME", "accessoryservice")
        self.cosmos_container_name: str = os.getenv("COSMOS_CONTAINER_NAME", "accessories")
        
        # Application Configuration
        self.app_name: str = "Accessory Service API"
        self.app_version: str = "1.0.0"
        self.debug: bool = os.getenv("DEBUG", "false").lower() == "true"
        
        # Validate required settings
        if not self.cosmos_endpoint:
            raise ValueError("COSMOS_ENDPOINT environment variable is required")
        if not self.cosmos_key:
            raise ValueError("COSMOS_KEY environment variable is required")


@lru_cache()
def get_settings() -> Settings:
    """Get cached application settings"""
    return Settings()