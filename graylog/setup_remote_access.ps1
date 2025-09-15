#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Configure Graylog for remote access

.DESCRIPTION
    This script helps configure Graylog for remote access by:
    1. Detecting the server's IP address
    2. Updating the GRAYLOG_EXTERNAL_URI environment variable
    3. Restarting the Graylog stack

.PARAMETER ExternalUri
    Custom external URI (optional). If not provided, will use detected IP.

.PARAMETER ComposeFile
    Path to the docker-compose file (default: docker-compose.yml)

.EXAMPLE
    .\setup_remote_access.ps1
    .\setup_remote_access.ps1 -ExternalUri "http://graylog.example.com:9000/"
    .\setup_remote_access.ps1 -ComposeFile "docker-compose.with-graylog.yml"
#>

param(
    [string]$ExternalUri = "",
    [string]$ComposeFile = "docker-compose.yml"
)

Write-Host "Configuring Graylog for Remote Access..." -ForegroundColor Green

# Check if compose file exists
if (-not (Test-Path $ComposeFile)) {
    Write-Host "Compose file not found: $ComposeFile" -ForegroundColor Red
    exit 1
}

# Determine external URI
if ($ExternalUri -eq "") {
    Write-Host "Detecting server IP address..." -ForegroundColor Yellow
    
    try {
        # Get primary IP address (not localhost)
        $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
            $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" 
        } | Select-Object -First 1).IPAddress
        
        if ($ipAddress) {
            $ExternalUri = "http://$ipAddress`:9000/"
            Write-Host "Detected IP: $ipAddress" -ForegroundColor Green
        } else {
            Write-Host " Could not detect IP address, using localhost" -ForegroundColor Yellow
            $ExternalUri = "http://127.0.0.1:9000/"
        }
    } catch {
        Write-Host " Error detecting IP address, using localhost" -ForegroundColor Yellow
        $ExternalUri = "http://127.0.0.1:9000/"
    }
}

Write-Host "📝 Setting GRAYLOG_EXTERNAL_URI to: $ExternalUri" -ForegroundColor Cyan

# Set environment variable
$env:GRAYLOG_EXTERNAL_URI = $ExternalUri

# Stop existing containers
Write-Host "Stopping existing containers..." -ForegroundColor Yellow
docker-compose -f $ComposeFile down

# Start with new configuration
Write-Host "Starting Graylog with remote access..." -ForegroundColor Yellow
docker-compose -f $ComposeFile up -d

# Wait for services to start
Write-Host "Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check service status
Write-Host "Checking service status..." -ForegroundColor Yellow
docker-compose -f $ComposeFile ps

Write-Host "Graylog configured for remote access!" -ForegroundColor Green
Write-Host ""
Write-Host "Access Graylog at: $ExternalUri" -ForegroundColor Cyan
Write-Host "Default credentials: admin / admin" -ForegroundColor Cyan
Write-Host ""
Write-Host "To make this permanent, add to your .env file:" -ForegroundColor Yellow
Write-Host "   GRAYLOG_EXTERNAL_URI=$ExternalUri" -ForegroundColor White
Write-Host ""
Write-Host "To view logs: docker-compose -f $ComposeFile logs -f" -ForegroundColor Yellow
