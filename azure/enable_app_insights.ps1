#!/usr/bin/env pwsh

# Enable Application Insights for Cody2Zoho Container App
$ResourceGroup = "{AZURE RESOURCE GROUP}"
$AppName = "cody2zoho"

Write-Host "Enabling Application Insights for $AppName..." -ForegroundColor Cyan

# Get Application Insights connection string using generic resource commands
Write-Host "Getting Application Insights connection string..." -ForegroundColor Yellow
$connectionString = az resource show --name "cody2zoho-insights" --resource-group $ResourceGroup --resource-type "Microsoft.Insights/components" --query "properties.ConnectionString" -o tsv

if (-not $connectionString) {
    Write-Host "Failed to get Application Insights connection string!" -ForegroundColor Red
    Write-Host "Trying alternative method..." -ForegroundColor Yellow
    
    # Alternative method using REST API
    $subscriptionId = az account show --query "id" -o tsv
    $connectionString = az rest --method GET --uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/components/cody2zoho-insights?api-version=2020-02-02" --query "properties.ConnectionString" -o tsv
    
    if (-not $connectionString) {
        Write-Host "Failed to get Application Insights connection string using alternative method!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Application Insights connection string retrieved successfully" -ForegroundColor Green

# Enable Application Insights by updating environment variables
Write-Host "Enabling Application Insights..." -ForegroundColor Yellow

# Set Application Insights environment variables
az containerapp update --name $AppName --resource-group $ResourceGroup --set-env-vars "ENABLE_APPLICATION_INSIGHTS=true" --output none
az containerapp update --name $AppName --resource-group $ResourceGroup --set-env-vars "APPLICATIONINSIGHTS_CONNECTION_STRING=$connectionString" --output none
az containerapp update --name $AppName --resource-group $ResourceGroup --set-env-vars "APPLICATIONINSIGHTS_ROLE_NAME=Cody2Zoho" --output none

Write-Host "Application Insights enabled successfully!" -ForegroundColor Green
Write-Host "Connection String: $($connectionString.Substring(0, 50))..." -ForegroundColor White
Write-Host "Role Name: Cody2Zoho" -ForegroundColor White

# Restart the container app to pick up the new configuration
Write-Host "Restarting container app to apply Application Insights configuration..." -ForegroundColor Yellow
az containerapp update --name $AppName --resource-group $ResourceGroup --image "{URL}" --output none

Write-Host "Container app restarted with Application Insights enabled!" -ForegroundColor Green
Write-Host "Application Insights dashboard: {URL}/cody2zoho-insights" -ForegroundColor Cyan
