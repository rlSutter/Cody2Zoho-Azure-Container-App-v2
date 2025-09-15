#!/usr/bin/env pwsh

Write-Host "Starting Redis container for Cody2Zoho development..." -ForegroundColor Green
Write-Host ""

# Check if Docker Desktop is running
Write-Host "Checking Docker Desktop status..." -ForegroundColor Yellow
try {
    $null = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Docker Desktop is not responding"
    }
    Write-Host "Docker Desktop is running!" -ForegroundColor Green
    
    # Check if Redis container is already running
    Write-Host "Checking for existing Redis containers..." -ForegroundColor Yellow
    $existingContainer = docker ps --filter "name=cody2zoho-redis-dev" --format "table {{.Names}}\t{{.Status}}" 2>&1
    if ($LASTEXITCODE -eq 0 -and $existingContainer -match "cody2zoho-redis-dev") {
        Write-Host "Redis container is already running!" -ForegroundColor Green
        Write-Host "Redis is available at localhost:6379" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "To stop Redis, run: .\stop_redis.ps1" -ForegroundColor Yellow
        Write-Host "To view logs, run: docker logs cody2zoho-redis-dev" -ForegroundColor Yellow
        Write-Host "To test connection, run: python test_redis.py" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter to continue"
        exit 0
    }
} catch {
    Write-Host "ERROR: Docker Desktop is not running or not accessible." -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "To fix this:" -ForegroundColor Yellow
    Write-Host "1. Start Docker Desktop from the Start menu or system tray" -ForegroundColor Yellow
    Write-Host "2. Wait for Docker Desktop to fully start (whale icon stops animating)" -ForegroundColor Yellow
    Write-Host "3. Run this script again" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "If Docker Desktop is not installed:" -ForegroundColor Yellow
    Write-Host "- Download from: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
    Write-Host "- Install and restart your computer" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Start Redis container
Write-Host "Starting Redis container..." -ForegroundColor Yellow
try {
    $output = docker-compose -f docker-compose.dev.yml up -d redis 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Redis container started successfully!" -ForegroundColor Green
        Write-Host "Redis is now available at localhost:6379" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "To stop Redis, run: .\stop_redis.ps1" -ForegroundColor Yellow
        Write-Host "To view logs, run: docker logs cody2zoho-redis-dev" -ForegroundColor Yellow
        Write-Host "To test connection, run: python test_redis.py" -ForegroundColor Yellow
        Write-Host ""
    } else {
        throw "Docker Compose failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Host ""
    Write-Host "ERROR: Failed to start Redis container." -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Common solutions:" -ForegroundColor Yellow
    Write-Host "1. Make sure Docker Desktop is running" -ForegroundColor Yellow
    Write-Host "2. Check if port 6379 is already in use: netstat -an | findstr 6379" -ForegroundColor Yellow
    Write-Host "3. Try stopping any existing Redis containers" -ForegroundColor Yellow
    Write-Host "4. Check Docker Desktop logs for errors" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Docker Compose output:" -ForegroundColor Gray
    Write-Host $output -ForegroundColor Gray
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Read-Host "Press Enter to continue"
