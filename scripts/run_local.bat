@echo off
REM Local development script for Cody2Zoho application (Windows)
REM This batch file allows you to run the Cody2Zoho application locally on Windows

echo Cody2Zoho Local Development Setup
echo ==================================

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python is not installed or not in PATH
    echo Please install Python 3.11 or higher and try again
    pause
    exit /b 1
)

REM Check if .env file exists in project root
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
set "ENV_FILE=%PROJECT_ROOT%\.env"

if not exist "%ENV_FILE%" (
    echo Error: .env file not found
    echo Expected location: %ENV_FILE%
    echo.
    echo To create .env file:
    echo 1. Copy env.template to .env: copy env.template .env
    echo 2. Edit .env and fill in your configuration values
    echo 3. Run this script again
    echo.
    pause
    exit /b 1
)

REM Check if requirements are installed
echo Checking dependencies...
python -c "import flask, requests, redis, dotenv" >nul 2>&1
if errorlevel 1 (
    echo Installing required packages...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo Error: Failed to install required packages
        pause
        exit /b 1
    )
)

echo Starting Cody2Zoho application locally...
echo.
echo Application will be available at:
echo - Health check: http://localhost:8080/health
echo - Metrics: http://localhost:8080/metrics
echo.
echo Press Ctrl+C to stop the application
echo.

REM Change to project root directory and run the application
cd /d "%PROJECT_ROOT%"
python scripts\run_local.py

echo.
echo Application stopped.
pause
