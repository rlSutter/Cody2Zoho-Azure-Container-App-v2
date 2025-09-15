#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Stop Graylog stack

.DESCRIPTION
    This script stops the complete Graylog stack including:
    - MongoDB (database)
    - Elasticsearch (search engine)
    - Graylog (log aggregation server)

.PARAMETER ComposeFile
    Path to the docker-compose file (default: docker-compose.yml)

.EXAMPLE
    .\stop_graylog.ps1
    .\stop_graylog.ps1 -ComposeFile "docker-compose.with-graylog.yml"
#>

param(
    [string]$ComposeFile = "docker-compose.yml"
)

Write-Host "Stopping Graylog Stack..." -ForegroundColor Yellow

# Check if compose file exists
if (-not (Test-Path $ComposeFile)) {
    Write-Host "Compose file not found: $ComposeFile" -ForegroundColor Red
    exit 1
}

# Stop the stack
Write-Host "Stopping Graylog stack..." -ForegroundColor Yellow
docker-compose -f $ComposeFile down

Write-Host "Graylog stack stopped!" -ForegroundColor Green
Write-Host ""
Write-Host "Data is preserved in Docker volumes" -ForegroundColor Cyan
Write-Host "  To remove volumes: docker-compose -f $ComposeFile down -v" -ForegroundColor Yellow
