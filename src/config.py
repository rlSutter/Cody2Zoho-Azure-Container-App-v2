from __future__ import annotations

import os
import sys
from pathlib import Path
from typing import Optional
from dotenv import load_dotenv

from pydantic_settings import BaseSettings
from pydantic import Field


def load_env_file():
    """
    Load environment variables from .env file if it exists.
    
    This function attempts to load environment variables from a .env file.
    If the .env file doesn't exist, it provides helpful guidance to the user
    about creating one from the template.
    
    The function supports both .env and env.template files for flexibility
    in different deployment scenarios.
    
    Note: When running in Docker, environment variables set by Docker Compose
    take precedence over .env file values.
    """
    print("Loading environment configuration...")
    
    # Check if we're running in Docker (environment variables already set)
    if os.getenv('REDIS_URL') and os.getenv('REDIS_URL') != 'redis://localhost:6379/0':
        print("Running in Docker environment, skipping .env file load")
        print(f"Using Docker environment variables (e.g., REDIS_URL={os.getenv('REDIS_URL')})")
        return
    
    env_path = Path(".env")
    if env_path.exists():
        print("Found .env file, loading...")
        load_dotenv(env_path)
        print("Loaded configuration from .env file")
    else:
        # Try to load from env.template if .env doesn't exist
        template_path = Path("env.template")
        if template_path.exists():
            print("Warning: .env file not found. Loading from env.template as fallback.")
            print("For production, please copy env.template to .env and fill in your values.")
            print("Example: cp env.template .env")
            print("Loading from env.template...")
            load_dotenv(template_path)
            print("Loaded configuration from env.template")
        else:
            print("Warning: No .env file found. Please create one with your configuration values.")

def validate_env_value(name: str, value: str | None, required: bool = False) -> str | None:
    """
    Validate that environment variable is not a placeholder value.
    
    This function checks if an environment variable contains a placeholder value
    (like "your_api_key_here") and handles it appropriately based on whether
    the field is required or optional.
    
    Args:
        name: The name of the environment variable (for error messages)
        value: The value to validate
        required: Whether this environment variable is required
        
    Returns:
        The validated value, or None if it was a placeholder and optional
        
    Raises:
        RuntimeError: If a required field contains a placeholder value
    """
    # Check for placeholder values (common pattern: "your_*_here")
    if value and value.startswith("your_") and value.endswith("_here"):
        if required:
            raise RuntimeError(f"Required environment variable {name} contains placeholder value '{value}'. Please set a real value in your .env file.")
        else:
            # For optional fields, just return None instead of the placeholder
            print(f"Warning: Optional environment variable {name} contains placeholder value. Setting to None.")
            return None
    return value

def get_env(name: str, default: str | None = None, required: bool = False) -> str | None:
    """
    Get an environment variable with validation and helpful error messages.
    
    This function retrieves environment variables with the following features:
    - Support for default values
    - Required field validation
    - Placeholder value detection and handling
    - Helpful error messages for common issues
    
    Args:
        name: The name of the environment variable
        default: Default value if the variable is not set
        required: Whether this environment variable is required
        
    Returns:
        The environment variable value, or default if not set
        
    Raises:
        RuntimeError: If a required environment variable is missing or contains placeholder
    """
    # Get the environment variable value
    val = os.getenv(name, default)
    
    # Check if required field is missing
    if required and (val is None or val == ""):
        error_msg = f"Missing required environment variable: {name}. Please check your .env file."
        
        # Provide specific guidance for common issues
        if name == "CODY_API_KEY":
            error_msg += "\n\nTo fix this:\n1. Copy env.template to .env: cp env.template .env\n2. Edit .env and set your CODY_API_KEY\n3. Restart the container"
        
        raise RuntimeError(error_msg)
    
    # Validate that the value is not a placeholder
    val = validate_env_value(name, val, required)
    return val

class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    # Cody Configuration
    CODY_API_URL: str = Field(default="https://getcody.ai/api/v1", description="Cody API base URL")
    CODY_API_KEY: str = Field(description="Cody API key")
    CODY_BOT_ID: str = Field(description="Cody bot ID")
    
    # Zoho Configuration
    ZOHO_API_BASE_URL: str = Field(default="https://www.zohoapis.com", description="Zoho API base URL")
    ZOHO_API_VERSION: str = Field(default="v8", description="Zoho API version")
    ZOHO_ACCESS_TOKEN: Optional[str] = Field(default=None, description="Zoho access token")
    ZOHO_REFRESH_TOKEN: Optional[str] = Field(default=None, description="Zoho refresh token")
    ZOHO_CLIENT_ID: str = Field(description="Zoho client ID")
    ZOHO_CLIENT_SECRET: str = Field(description="Zoho client secret")
    ZOHO_ACCOUNTS_BASE_URL: str = Field(default="https://accounts.zoho.com", description="Zoho accounts base URL")
    
    # Zoho Contact Configuration
    ZOHO_CONTACT_ID: str = Field(description="Zoho contact ID for case creation")
    ZOHO_CONTACT_NAME: str = Field(default="Cody Chat", description="Zoho contact name")
    
    # Zoho Case Configuration
    ZOHO_CASE_ORIGIN: str = Field(default="Web", description="Zoho case origin")
    ZOHO_CASE_STATUS: str = Field(default="Closed", description="Zoho case status")
    ZOHO_ATTACH_TRANSCRIPT_AS_NOTE: bool = Field(default=False, description="Attach transcript as note")
    ZOHO_ENABLE_DUPLICATE_CHECK: bool = Field(default=True, description="Enable duplicate case checking")
    
    # Infrastructure Configuration
    REDIS_URL: str = Field(default="redis://localhost:6379/0", description="Redis connection URL")
    POLL_INTERVAL_SECONDS: int = Field(default=30, description="Polling interval in seconds")
    PORT: int = Field(default=8080, description="Application port")
    
    # Azure Deployment Settings
    RESOURCE_GROUP: str = Field(default="ASEV-OpenAI", description="Azure resource group")
    LOCATION: str = Field(default="eastus", description="Azure location")
    ACR_NAME: str = Field(default="asecontainerregistry", description="Azure Container Registry name")
    APP_NAME: str = Field(default="Cody2Zoho", description="Application name")
    
    # Azure Application Insights Configuration
    APPLICATIONINSIGHTS_CONNECTION_STRING: Optional[str] = Field(default=None, description="Application Insights connection string")
    APPLICATIONINSIGHTS_ROLE_NAME: str = Field(default="Cody2Zoho", description="Application Insights role name")
    ENABLE_APPLICATION_INSIGHTS: bool = Field(default=False, description="Enable Application Insights")
    
    # Graylog Configuration
    ENABLE_GRAYLOG: bool = Field(default=False, description="Enable Graylog integration")
    GRAYLOG_HOST: str = Field(default="localhost", description="Graylog host")
    GRAYLOG_PORT: int = Field(default=12201, description="Graylog port")
    GRAYLOG_PROTOCOL: str = Field(default="udp", description="Graylog protocol")
    GRAYLOG_APPLICATION_NAME: str = Field(default="cody2zoho", description="Graylog application name")
    GRAYLOG_ENVIRONMENT: str = Field(default="production", description="Graylog environment")
    GRAYLOG_LOG_LEVEL: str = Field(default="INFO", description="Graylog log level")
    GRAYLOG_EXTERNAL_URI: str = Field(default="http://127.0.0.1:9000/", description="Graylog external URI")
    
    class Config:
        env_file = ".env"
        case_sensitive = True
