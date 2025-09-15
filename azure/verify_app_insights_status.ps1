#!/usr/bin/env pwsh

# Check Application Insights status for Cody2Zoho Container App
$ResourceGroup = "{AZURE RESOURCE GROUP}"
$AppName = "cody2zoho"

Write-Host "=== Application Insights Status Check ===" -ForegroundColor Cyan
Write-Host "App: $AppName" -ForegroundColor White
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host ""

# 1. Check if Application Insights resource exists
Write-Host "1. Application Insights Resource:" -ForegroundColor Yellow
$appInsights = az resource show --name "cody2zoho-insights" --resource-group $ResourceGroup --resource-type "Microsoft.Insights/components" --output json 2>$null

if ($appInsights) {
    $appInsightsObj = $appInsights | ConvertFrom-Json
    Write-Host "   Resource Name: $($appInsightsObj.name)" -ForegroundColor Green
    Write-Host "   Location: $($appInsightsObj.location)" -ForegroundColor Green
    Write-Host "   Provisioning State: $($appInsightsObj.properties.provisioningState)" -ForegroundColor Green
    
    # Get connection string
    $connectionString = $appInsightsObj.properties.ConnectionString
    if ($connectionString) {
        Write-Host "   Connection String: $($connectionString.Substring(0, 50))..." -ForegroundColor Green
    } else {
        Write-Host "   Connection String: Not available" -ForegroundColor Red
    }
} else {
    Write-Host "   Application Insights resource not found!" -ForegroundColor Red
}

Write-Host ""

# 2. Check container app environment variables
Write-Host "2. Container App Configuration:" -ForegroundColor Yellow

# Get all environment variables as a single string and parse them
$containerApp = az containerapp show --name $AppName --resource-group $ResourceGroup --output json | ConvertFrom-Json
$envVarsString = $containerApp.properties.template.containers[0].env[0].value

# Parse the concatenated environment variables string
$envVars = @{}
if ($envVarsString) {
    $envPairs = $envVarsString -split ','
    foreach ($pair in $envPairs) {
        if ($pair -match '^([^=]+)=(.*)$') {
            $name = $matches[1]
            $value = $matches[2]
            $envVars[$name] = $value
        }
    }
}

$appInsightsEnabled = $false
$connectionStringSet = $false
$roleNameSet = $false

# Check Application Insights related environment variables
if ($envVars.ContainsKey("ENABLE_APPLICATION_INSIGHTS")) {
    $value = $envVars["ENABLE_APPLICATION_INSIGHTS"]
    Write-Host "   ENABLE_APPLICATION_INSIGHTS: $value" -ForegroundColor $(if ($value -eq "true") { "Green" } else { "Red" })
    $appInsightsEnabled = ($value -eq "true")
} else {
    Write-Host "   ENABLE_APPLICATION_INSIGHTS: Not set" -ForegroundColor Red
}

if ($envVars.ContainsKey("APPLICATIONINSIGHTS_CONNECTION_STRING")) {
    $value = $envVars["APPLICATIONINSIGHTS_CONNECTION_STRING"]
    Write-Host "   APPLICATIONINSIGHTS_CONNECTION_STRING: $($value.Substring(0, [Math]::Min(50, $value.Length)))..." -ForegroundColor Green
    $connectionStringSet = [bool]$value
} else {
    Write-Host "   APPLICATIONINSIGHTS_CONNECTION_STRING: Not set" -ForegroundColor Red
}

if ($envVars.ContainsKey("APPLICATIONINSIGHTS_ROLE_NAME")) {
    $value = $envVars["APPLICATIONINSIGHTS_ROLE_NAME"]
    Write-Host "   APPLICATIONINSIGHTS_ROLE_NAME: $value" -ForegroundColor Green
    $roleNameSet = [bool]$value
} else {
    Write-Host "   APPLICATIONINSIGHTS_ROLE_NAME: Not set" -ForegroundColor Red
}

if ($envVars.ContainsKey("APPLICATIONINSIGHTS_ENABLE_LIVE_METRICS")) {
    $value = $envVars["APPLICATIONINSIGHTS_ENABLE_LIVE_METRICS"]
    Write-Host "   APPLICATIONINSIGHTS_ENABLE_LIVE_METRICS: $value" -ForegroundColor $(if ($value -eq "true") { "Green" } else { "Yellow" })
}

Write-Host ""

# 3. Check container logs for Application Insights activity
Write-Host "3. Application Insights Activity in Logs:" -ForegroundColor Yellow
try {
    $logs = az containerapp logs show --name $AppName --resource-group $ResourceGroup --follow false --tail 10 2>$null
    if ($logs) {
        $appInsightsLogs = $logs | Where-Object { $_ -match "Application Insights|app_insights|telemetry" }
        if ($appInsightsLogs) {
            Write-Host "   Found Application Insights related logs:" -ForegroundColor Green
            $appInsightsLogs | ForEach-Object { Write-Host "     $_" -ForegroundColor Gray }
        } else {
            Write-Host "   No Application Insights activity found in recent logs" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   No logs available" -ForegroundColor Red
    }
} catch {
    Write-Host "   Could not retrieve logs: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 4. Summary
Write-Host "4. Summary:" -ForegroundColor Yellow
if ($appInsightsEnabled -and $connectionStringSet -and $roleNameSet) {
    Write-Host "   Application Insights is properly configured and enabled" -ForegroundColor Green
    Write-Host "   Dashboard: {DASHBOARD URL}" -ForegroundColor Cyan
} else {
    Write-Host "   Application Insights is not properly configured:" -ForegroundColor Red
    if (-not $appInsightsEnabled) { Write-Host "     - ENABLE_APPLICATION_INSIGHTS is not set to true" -ForegroundColor Red }
    if (-not $connectionStringSet) { Write-Host "     - APPLICATIONINSIGHTS_CONNECTION_STRING is not set" -ForegroundColor Red }
    if (-not $roleNameSet) { Write-Host "     - APPLICATIONINSIGHTS_ROLE_NAME is not set" -ForegroundColor Red }
    Write-Host "   Run: .\azure\enable_app_insights.ps1 to fix this" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Check Complete ===" -ForegroundColor Cyan
