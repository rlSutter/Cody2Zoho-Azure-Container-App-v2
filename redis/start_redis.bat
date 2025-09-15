@echo off
echo Starting Redis container for Cody2Zoho development...
echo.

REM Check if Docker Desktop is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker Desktop is not running or not accessible.
    echo Please start Docker Desktop and try again.
    pause
    exit /b 1
)

REM Start Redis container
echo Starting Redis container...
docker-compose -f docker-compose.dev.yml up -d redis

if %errorlevel% equ 0 (
    echo.
    echo Redis container started successfully!
    echo Redis is now available at localhost:6379
    echo.
    echo To stop Redis, run: stop_redis.bat
    echo To view logs, run: docker logs cody2zoho-redis-dev
    echo.
) else (
    echo.
    echo ERROR: Failed to start Redis container.
    echo Check Docker Desktop and try again.
    pause
    exit /b 1
)

pause
