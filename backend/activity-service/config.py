"""
Activity Service Configuration

This module handles configuration management using Pydantic Settings
for environment variable loading with validation and type conversion.
"""

import os
from typing import Optional
from pydantic_settings import BaseSettings
from pydantic import Field


class Settings(BaseSettings):
    """
    Application settings loaded from environment variables
    
    These settings configure the Activity Service application including
    Azure CosmosDB connection details and application behavior.
    """
    
    # CosmosDB Configuration
    cosmos_endpoint: str = Field(
        ...,
        description="Azure CosmosDB endpoint URL"
    )
    
    cosmos_key: str = Field(
        ..., 
        description="Azure CosmosDB access key"
    )
    
    cosmos_database_name: str = Field(
        default="activityservice",
        description="CosmosDB database name"
    )
    
    cosmos_container_name: str = Field(
        default="activities",
        description="CosmosDB container name"
    )
    
    # Application Configuration
    app_name: str = Field(
        default="Activity Service",
        description="Application name"
    )
    
    app_version: str = Field(
        default="1.0.0",
        description="Application version"
    )
    
    # Development Configuration
    debug: bool = Field(
        default=False,
        description="Enable debug mode"
    )
    
    log_level: str = Field(
        default="INFO",
        description="Logging level (DEBUG, INFO, WARNING, ERROR)"
    )
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False


# Global settings instance
_settings = None


def get_settings() -> Settings:
    """Get application settings singleton"""
    global _settings
    if _settings is None:
        _settings = Settings()
    return _settings