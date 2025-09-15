#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Start Graylog stack with MongoDB and Elasticsearch

.DESCRIPTION
    This script starts the complete Graylog stack including:
    - MongoDB (database)
    - Elasticsearch (search engine)
    - Graylog (log aggregation server)

.PARAMETER ComposeFile
    Path to the docker-compose file (default: docker-compose.yml)

.EXAMPLE
    .\start_graylog.ps1
    .\start_graylog.ps1 -ComposeFile "docker-compose.with-graylog.yml"
#>

param(
    [string]$ComposeFile = "docker-compose.yml"
)

Write-Host "Starting Graylog Stack..." -ForegroundColor Green

# Check if Docker is running
try {
    docker version | Out-Null
} catch {
    Write-Host "Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    exit 1
}

# Check if compose file exists
if (-not (Test-Path $ComposeFile)) {
    Write-Host "Compose file not found: $ComposeFile" -ForegroundColor Red
    exit 1
}

# Stop any existing containers
Write-Host "Stopping existing containers..." -ForegroundColor Yellow
docker-compose -f $ComposeFile down

# Start the stack
Write-Host "Starting Graylog stack..." -ForegroundColor Yellow
docker-compose -f $ComposeFile up -d

# Wait for services to start
Write-Host "Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check service status
Write-Host "Checking service status..." -ForegroundColor Yellow
docker-compose -f $ComposeFile ps

Write-Host "Graylog stack started!" -ForegroundColor Green
Write-Host ""
Write-Host "Access Graylog Web UI at: http://localhost:9000" -ForegroundColor Cyan
Write-Host "Default credentials: admin / admin" -ForegroundColor Cyan
Write-Host ""
Write-Host "GELF Inputs:" -ForegroundColor Cyan
Write-Host "   UDP: localhost:12201" -ForegroundColor White
Write-Host "   TCP: localhost:12201" -ForegroundColor White
Write-Host "   HTTP: localhost:12202" -ForegroundColor White
Write-Host ""
Write-Host "To view logs: docker-compose -f $ComposeFile logs -f" -ForegroundColor Yellow
Write-Host "To stop: docker-compose -f $ComposeFile down" -ForegroundColor Yellow
