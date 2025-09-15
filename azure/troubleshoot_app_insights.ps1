#!/usr/bin/env pwsh

# Application Insights Workaround Script for Cody2Zoho
# This script addresses common Application Insights issues and provides solutions

$ResourceGroup = "{AZURE RESOURCE GROUP}"
$AppName = "cody2zoho"

Write-Host "=== Application Insights Workaround Script ===" -ForegroundColor Cyan
Write-Host "This script addresses common Application Insights issues" -ForegroundColor White
Write-Host ""

# Function to check if Application Insights is working
function Test-AppInsightsStatus {
    Write-Host "1. Checking Application Insights Status..." -ForegroundColor Yellow
    
    # Check if Application Insights resource exists
    $appInsights = az resource show --name "cody2zoho-insights" --resource-group $ResourceGroup --resource-type "Microsoft.Insights/components" --output json 2>$null
    
    if (-not $appInsights) {
        Write-Host "   ERROR: Application Insights resource not found!" -ForegroundColor Red
        Write-Host "   Solution: Run .\azure\deploy_azure_monitoring.ps1 to create Application Insights" -ForegroundColor Yellow
        return $false
    }
    
    $appInsightsObj = $appInsights | ConvertFrom-Json
    Write-Host "   Application Insights resource found: $($appInsightsObj.name)" -ForegroundColor Green
    
    # Check connection string
    $connectionString = $appInsightsObj.properties.ConnectionString
    if (-not $connectionString) {
        Write-Host "   ERROR: Connection string not available!" -ForegroundColor Red
        return $false
    }
    
    Write-Host "   Connection string available" -ForegroundColor Green
    return $true
}

# Function to check container app configuration
function Test-ContainerAppConfig {
    Write-Host "2. Checking Container App Configuration..." -ForegroundColor Yellow
    
    $containerApp = az containerapp show --name $AppName --resource-group $ResourceGroup --output json | ConvertFrom-Json
    $envVarsString = $containerApp.properties.template.containers[0].env[0].value
    
    # Parse environment variables
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
    
    $issues = @()
    
    # Check ENABLE_APPLICATION_INSIGHTS
    if (-not $envVars.ContainsKey("ENABLE_APPLICATION_INSIGHTS") -or $envVars["ENABLE_APPLICATION_INSIGHTS"] -ne "true") {
        $issues += "ENABLE_APPLICATION_INSIGHTS not set to true"
    }
    
    # Check APPLICATIONINSIGHTS_CONNECTION_STRING
    if (-not $envVars.ContainsKey("APPLICATIONINSIGHTS_CONNECTION_STRING") -or -not $envVars["APPLICATIONINSIGHTS_CONNECTION_STRING"]) {
        $issues += "APPLICATIONINSIGHTS_CONNECTION_STRING not set"
    }
    
    # Check APPLICATIONINSIGHTS_ROLE_NAME
    if (-not $envVars.ContainsKey("APPLICATIONINSIGHTS_ROLE_NAME") -or -not $envVars["APPLICATIONINSIGHTS_ROLE_NAME"]) {
        $issues += "APPLICATIONINSIGHTS_ROLE_NAME not set"
    }
    
    if ($issues.Count -eq 0) {
        Write-Host "   Container app configuration looks good" -ForegroundColor Green
        return $true
    } else {
        Write-Host "   Configuration issues found:" -ForegroundColor Red
        foreach ($issue in $issues) {
            Write-Host "     - $issue" -ForegroundColor Red
        }
        return $false
    }
}

# Function to check for telemetry data
function Test-TelemetryData {
    Write-Host "3. Checking for Telemetry Data..." -ForegroundColor Yellow
    
    try {
        $logs = az containerapp logs show --name $AppName --resource-group $ResourceGroup --follow false --tail 20 2>$null
        
        if ($logs) {
            $telemetryLogs = $logs | Where-Object { $_ -match "app_insights|telemetry|Application Insights" }
            
            if ($telemetryLogs) {
                Write-Host "   Found telemetry activity in logs:" -ForegroundColor Green
                $telemetryLogs | Select-Object -First 5 | ForEach-Object { 
                    Write-Host "     $($_.Substring(0, [Math]::Min(80, $_.Length)))..." -ForegroundColor Gray 
                }
                return $true
            } else {
                Write-Host "   No telemetry activity found in recent logs" -ForegroundColor Yellow
                return $false
            }
        } else {
            Write-Host "   No logs available" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "   Could not retrieve logs: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to enable Application Insights
function Enable-ApplicationInsights {
    Write-Host "4. Enabling Application Insights..." -ForegroundColor Yellow
    
    Write-Host "   Running enable_app_insights.ps1..." -ForegroundColor White
    & "$PSScriptRoot\enable_app_insights.ps1"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Application Insights enabled successfully" -ForegroundColor Green
        return $true
    } else {
        Write-Host "   Failed to enable Application Insights" -ForegroundColor Red
        return $false
    }
}

# Function to test Application Insights connectivity
function Test-AppInsightsConnectivity {
    Write-Host "5. Testing Application Insights Connectivity..." -ForegroundColor Yellow
    
    # Get the application URL
    $appUrl = az containerapp show --name $AppName --resource-group $ResourceGroup --query "properties.configuration.ingress.fqdn" -o tsv
    
    if (-not $appUrl) {
        Write-Host "   Could not get application URL" -ForegroundColor Red
        return $false
    }
    
    Write-Host "   Testing debug endpoints..." -ForegroundColor White
    
    # Test /debug/app-insights endpoint
    try {
        $debugResponse = Invoke-WebRequest -Uri "https://$appUrl/debug/app-insights" -TimeoutSec 10 -UseBasicParsing
        $debugData = $debugResponse.Content | ConvertFrom-Json
        
        Write-Host "   /debug/app-insights response:" -ForegroundColor White
        Write-Host "     Configured: $($debugData.app_insights_configured)" -ForegroundColor $(if ($debugData.app_insights_configured) { "Green" } else { "Red" })
        Write-Host "     Initialized: $($debugData.app_insights_initialized)" -ForegroundColor $(if ($debugData.app_insights_initialized) { "Green" } else { "Red" })
        
        if ($debugData.connectivity) {
            Write-Host "     Connectivity:" -ForegroundColor White
            Write-Host "       Direct API: $($debugData.connectivity.direct_api)" -ForegroundColor $(if ($debugData.connectivity.direct_api) { "Green" } else { "Red" })
            Write-Host "       Ingestion Endpoint: $($debugData.connectivity.ingestion_endpoint)" -ForegroundColor $(if ($debugData.connectivity.ingestion_endpoint) { "Green" } else { "Red" })
            Write-Host "       Live Endpoint: $($debugData.connectivity.live_endpoint)" -ForegroundColor $(if ($debugData.connectivity.live_endpoint) { "Green" } else { "Red" })
        }
        
        return $debugData.app_insights_configured -and $debugData.app_insights_initialized
        
    } catch {
        Write-Host "   Could not test debug endpoint: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to send test telemetry
function Send-TestTelemetry {
    Write-Host "6. Sending Test Telemetry..." -ForegroundColor Yellow
    
    $appUrl = az containerapp show --name $AppName --resource-group $ResourceGroup --query "properties.configuration.ingress.fqdn" -o tsv
    
    if (-not $appUrl) {
        Write-Host "   Could not get application URL" -ForegroundColor Red
        return $false
    }
    
    try {
        $testResponse = Invoke-WebRequest -Uri "https://$appUrl/debug/test-telemetry-detailed" -TimeoutSec 10 -UseBasicParsing
        $testData = $testResponse.Content | ConvertFrom-Json
        
        Write-Host "   Test telemetry results:" -ForegroundColor White
        foreach ($test in $testData.tests.PSObject.Properties) {
            $status = if ($test.Value -eq "success") { "Green" } else { "Red" }
            Write-Host "     $($test.Name): $($test.Value)" -ForegroundColor $status
        }
        
        return $testData.status -eq "completed"
        
    } catch {
        Write-Host "   Could not send test telemetry: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to provide manual workarounds
function Show-ManualWorkarounds {
    Write-Host "7. Manual Workarounds..." -ForegroundColor Yellow
    
    Write-Host "   If Application Insights is still not working, try these manual steps:" -ForegroundColor White
    Write-Host ""
    Write-Host "   a) Check Application Insights in Azure Portal:" -ForegroundColor Cyan
    Write-Host "      {APPLICATION INSIGHTS URL}" -ForegroundColor White
    Write-Host ""
    Write-Host "   b) Check Live Metrics:" -ForegroundColor Cyan
    Write-Host "      Look for 'Not available: couldn't connect to your application'" -ForegroundColor White
    Write-Host ""
    Write-Host "   c) Check Logs (Analytics):" -ForegroundColor Cyan
    Write-Host "      Run these Kusto queries:" -ForegroundColor White
    Write-Host "      customEvents | where timestamp > ago(1h)" -ForegroundColor Gray
    Write-Host "      customMetrics | where timestamp > ago(1h)" -ForegroundColor Gray
    Write-Host "      traces | where message contains 'app_insights'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   d) Restart the container app:" -ForegroundColor Cyan
    Write-Host "      az containerapp update --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --image {IMAGE}" -ForegroundColor White
    Write-Host ""
    Write-Host "   e) Check container logs:" -ForegroundColor Cyan
    Write-Host "      az containerapp logs show --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --follow" -ForegroundColor White
}

# Main execution
Write-Host "Starting Application Insights diagnostics..." -ForegroundColor Cyan
Write-Host ""

$appInsightsStatus = Test-AppInsightsStatus
$containerConfig = Test-ContainerAppConfig
$telemetryData = Test-TelemetryData

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan

if (-not $appInsightsStatus) {
    Write-Host "CRITICAL: Application Insights resource not found!" -ForegroundColor Red
    Write-Host "Run: .\azure\deploy_azure_monitoring.ps1" -ForegroundColor Yellow
    exit 1
}

if (-not $containerConfig) {
    Write-Host "ISSUE: Container app configuration needs fixing" -ForegroundColor Yellow
    $enableResult = Enable-ApplicationInsights
    if ($enableResult) {
        Write-Host "Application Insights has been enabled. Please wait 2-3 minutes for changes to take effect." -ForegroundColor Green
        Write-Host "Then run this script again to verify." -ForegroundColor Yellow
    }
} else {
    Write-Host "Container app configuration is correct" -ForegroundColor Green
}

if ($telemetryData) {
    Write-Host "Telemetry data is being sent" -ForegroundColor Green
} else {
    Write-Host "No telemetry data found - this may be normal if no conversations have been processed recently" -ForegroundColor Yellow
}

# Test connectivity and telemetry
Write-Host ""
$connectivity = Test-AppInsightsConnectivity
$telemetry = Send-TestTelemetry

if ($connectivity -and $telemetry) {
    Write-Host "Application Insights is working correctly!" -ForegroundColor Green
} else {
    Write-Host "Application Insights may have connectivity issues" -ForegroundColor Yellow
    Show-ManualWorkarounds
}

Write-Host ""
Write-Host "=== Workaround Complete ===" -ForegroundColor Cyan
Write-Host "For more detailed information, see: .\azure\FINDING_APPLICATION_INSIGHTS_DATA.md" -ForegroundColor White
