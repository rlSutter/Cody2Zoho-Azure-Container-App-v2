#!/usr/bin/env python3
"""
Local development script for Cody2Zoho application.

This script allows you to run the Cody2Zoho application locally without Docker,
making it easier for development and testing. It handles environment setup,
dependency checking, and provides helpful error messages.

Usage:
    python run_local.py

Prerequisites:
    - Python 3.11+
    - .env file with proper configuration
    - Redis server running (optional - will use in-memory fallback)
"""

import os
import sys
import subprocess
import signal
import time
from pathlib import Path

def check_python_version():
    """Check if Python version is compatible."""
    if sys.version_info < (3, 11):
        print("Error: Python 3.11 or higher is required")
        print(f"   Current version: {sys.version}")
        sys.exit(1)
    print(f"Python version: {sys.version.split()[0]}")

def check_dependencies():
    """Check if required dependencies are installed."""
    required_packages = [
        ('flask', 'flask'),
        ('requests', 'requests'),
        ('redis', 'redis'),
        ('python-dotenv', 'dotenv')
    ]
    
    missing_packages = []
    for package_name, import_name in required_packages:
        try:
            __import__(import_name)
        except ImportError:
            missing_packages.append(package_name)
    
    if missing_packages:
        print("Missing required packages:")
        for package in missing_packages:
            print(f"   - {package}")
        print("\nTo install missing packages:")
        print("   pip install -r requirements.txt")
        sys.exit(1)
    
    print("All required packages are installed")

def check_env_file():
    """Check if .env file exists and has required values."""
    # Look for .env file in the project root (parent directory)
    env_path = Path(__file__).parent.parent / ".env"
    if not env_path.exists():
        print(".env file not found")
        print(f"   Expected location: {env_path}")
        print("\nTo create .env file:")
        print("   1. Copy env.template to .env: cp env.template .env")
        print("   2. Edit .env and fill in your configuration values")
        print("   3. Run this script again")
        sys.exit(1)
    
    print(".env file found")
    
    # Load the .env file
    try:
        from dotenv import load_dotenv
        load_dotenv(env_path)
        print(".env file loaded successfully")
    except Exception as e:
        print(f"Error loading .env file: {e}")
        sys.exit(1)
    
    # Check for required environment variables
    required_vars = [
        'CODY_API_KEY',
        'ZOHO_ACCESS_TOKEN',
        'ZOHO_REFRESH_TOKEN'
    ]
    
    missing_vars = []
    for var in required_vars:
        if not os.getenv(var):
            missing_vars.append(var)
    
    if missing_vars:
        print("Missing required environment variables:")
        for var in missing_vars:
            print(f"   - {var}")
        print("\nPlease check your .env file and ensure all required values are set")
        sys.exit(1)
    
    print("Required environment variables are set")

def check_redis_connection():
    """Check if Redis is available (optional)."""
    try:
        import redis
        r = redis.from_url(os.getenv('REDIS_URL', 'redis://localhost:6379/0'))
        r.ping()
        print("Redis connection successful")
        return True
    except Exception as e:
        print(" Redis connection failed (will use in-memory fallback)")
        print(f"   Error: {e}")
        return False

def setup_environment():
    """Set up environment for local development."""
    # Add src directory to Python path (project root)
    src_path = Path(__file__).parent.parent / "src"
    if str(src_path) not in sys.path:
        sys.path.insert(0, str(src_path))
    
    # Set development environment variables
    os.environ.setdefault('FLASK_ENV', 'development')
    os.environ.setdefault('FLASK_DEBUG', '1')

def run_application():
    """Run the Cody2Zoho application."""
    print("\n Starting Cody2Zoho application locally...")
    print("=" * 50)
    
    try:
        # Change to project root directory
        project_root = Path(__file__).parent.parent
        os.chdir(project_root)
        
        # Set up signal handler for graceful shutdown
        def signal_handler(signum, frame):
            print(f"\n Received signal {signum}, shutting down gracefully...")
            sys.exit(0)
        
        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)
        
        # Run the application as a module
        import subprocess
        result = subprocess.run([sys.executable, "-m", "src.main"], 
                              cwd=project_root, 
                              env=os.environ.copy())
        
        if result.returncode != 0:
            print(f"\n Application exited with code {result.returncode}")
            sys.exit(result.returncode)
        
    except KeyboardInterrupt:
        print("\n Application stopped by user")
    except Exception as e:
        print(f"\n Error running application: {e}")
        sys.exit(1)

def main():
    """Main function for local development script."""
    print("Cody2Zoho Local Development Setup")
    print("=" * 40)
    
    # Check prerequisites
    check_python_version()
    check_dependencies()
    check_env_file()
    check_redis_connection()
    
    # Set up environment
    setup_environment()
    
    # Run the application
    run_application()

if __name__ == "__main__":
    main()
