#!/usr/bin/env pwsh

Write-Host "Stopping Redis container for Cody2Zoho development..." -ForegroundColor Green
Write-Host ""

# Stop Redis container
Write-Host "Stopping Redis container..." -ForegroundColor Yellow
docker-compose -f docker-compose.dev.yml down

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Redis container stopped successfully!" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "WARNING: There was an issue stopping the Redis container." -ForegroundColor Yellow
    Write-Host "You may need to stop it manually in Docker Desktop." -ForegroundColor Yellow
    Write-Host ""
}

Read-Host "Press Enter to continue"
