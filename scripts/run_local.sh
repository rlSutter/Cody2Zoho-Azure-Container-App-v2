#!/bin/bash
# Local development script for Cody2Zoho application (Unix/Linux/macOS)
# This script allows you to run the Cody2Zoho application locally

echo "Cody2Zoho Local Development Setup"
echo "=================================="

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed or not in PATH"
    echo "Please install Python 3.11 or higher and try again"
    exit 1
fi

# Check Python version
python_version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
required_version="3.11"

if [ "$(printf '%s\n' "$required_version" "$python_version" | sort -V | head -n1)" != "$required_version" ]; then
    echo "Error: Python 3.11 or higher is required"
    echo "Current version: $python_version"
    exit 1
fi

echo "Python version: $python_version"

# Check if .env file exists in project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found"
    echo "Expected location: $ENV_FILE"
    echo ""
    echo "To create .env file:"
    echo "1. Copy env.template to .env: cp env.template .env"
    echo "2. Edit .env and fill in your configuration values"
    echo "3. Run this script again"
    echo ""
    exit 1
fi

echo ".env file found"

# Check if requirements are installed
echo "Checking dependencies..."
if ! python3 -c "import flask, requests, redis, dotenv" &> /dev/null; then
    echo "Installing required packages..."
    python3 -m pip install -r requirements.txt
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install required packages"
        exit 1
    fi
fi

echo "All dependencies are installed"

echo ""
echo "Starting Cody2Zoho application locally..."
echo ""
echo "Application will be available at:"
echo "- Health check: http://localhost:8080/health"
echo "- Metrics: http://localhost:8080/metrics"
echo ""
echo "Press Ctrl+C to stop the application"
echo ""

# Change to project root directory and run the application
cd "$PROJECT_ROOT"
python3 scripts/run_local.py

echo ""
echo "Application stopped."
