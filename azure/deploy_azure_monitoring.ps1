#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy version supporting Enhanced Monitoring using Application Insights for Cody2Zoho
.DESCRIPTION
    This script deploys all enhanced monitoring features including:
    - Enhanced Application Insights telemetry
    - Alerts and notifications
    - Log Analytics queries
    - Dashboards
.PARAMETER SkipRedisDeployment
    Skip Redis deployment and use existing Redis instance
#>

param(
    [switch]$SkipRedisDeployment = $false  # Skip Redis deployment and use existing Redis instance
)

$ResourceGroup = "{AZURE RESOURCE GROUP}"
$AppName = "cody2zoho"
$AppInsightsName = "cody2zoho-insights"

Write-Host "=== Phase 2: Enhanced Monitoring Deployment ===" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "Application: $AppName" -ForegroundColor White
Write-Host "Application Insights: $AppInsightsName" -ForegroundColor White
if ($SkipRedisDeployment) {
    Write-Host "Redis Deployment: SKIPPED (using existing instance)" -ForegroundColor Yellow
} else {
    Write-Host "Redis Deployment: ENABLED (will create if needed)" -ForegroundColor Green
}
Write-Host ""

# Step 1: Deploy enhanced application with new telemetry
Write-Host "Step 1: Deploying enhanced application..." -ForegroundColor Yellow
Write-Host "Building and deploying application with enhanced telemetry..." -ForegroundColor White

# Deploy the application with enhanced telemetry
if ($SkipRedisDeployment) {
    .\azure\deploy_simple.ps1 -ForceTokenRefresh -SkipRedisDeployment
} else {
    .\azure\deploy_simple.ps1 -ForceTokenRefresh
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "Application deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Application deployed successfully" -ForegroundColor Green

# Step 1.5: Enable Application Insights
Write-Host ""
Write-Host "Step 1.5: Enabling Application Insights..." -ForegroundColor Yellow
Write-Host "Enabling Application Insights for enhanced telemetry..." -ForegroundColor White

.\azure\enable_app_insights.ps1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Application Insights enablement failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Application Insights enabled successfully" -ForegroundColor Green

# Step 2: Set up alerts
Write-Host ""
Write-Host "Step 2: Setting up Application Insights alerts..." -ForegroundColor Yellow
.\azure\setup_app_insights_alerts.ps1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Alert setup had issues, but continuing..." -ForegroundColor Yellow
}

# Step 3: Set up Log Analytics queries
Write-Host ""
Write-Host "Step 3: Setting up Log Analytics queries..." -ForegroundColor Yellow
.\azure\setup_log_analytics_queries.ps1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Query setup had issues, but continuing..." -ForegroundColor Yellow
}

# Step 4: Set up dashboards
Write-Host ""
Write-Host "Step 4: Setting up dashboards..." -ForegroundColor Yellow
.\azure\setup_dashboards.ps1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Dashboard setup had issues, but continuing..." -ForegroundColor Yellow
}

# Step 5: Deploy dashboards
Write-Host ""
Write-Host "Step 5: Deploying dashboards..." -ForegroundColor Yellow
if (Test-Path ".\azure\dashboards\deploy_dashboards.ps1") {
    try {
        .\azure\dashboards\deploy_dashboards.ps1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Dashboard deployment had issues, but continuing..." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Dashboard deployment failed, but continuing..." -ForegroundColor Yellow
    }
} else {
    Write-Host "Dashboard deployment script not found, skipping..." -ForegroundColor Yellow
}

# Step 6: Verify deployment
Write-Host ""
Write-Host "Step 6: Verifying deployment..." -ForegroundColor Yellow

# Check application status
Write-Host "Checking application status..." -ForegroundColor White
$appStatus = az containerapp show --name $AppName --resource-group $ResourceGroup --query "properties.runningReplicas" -o tsv
if ($appStatus -gt 0) {
    Write-Host "Application is running ($appStatus replicas)" -ForegroundColor Green
} else {
    Write-Host "Application is not running" -ForegroundColor Red
}

# Check Application Insights
Write-Host "Checking Application Insights..." -ForegroundColor White
$aiStatus = az resource show --name $AppInsightsName --resource-group $ResourceGroup --resource-type "Microsoft.Insights/components" --query "properties.ProvisioningState" -o tsv
if ($aiStatus -eq "Succeeded") {
    Write-Host "Application Insights is active" -ForegroundColor Green
} else {
    Write-Host "Application Insights status: $aiStatus" -ForegroundColor Red
}

# Test metrics endpoint
Write-Host "Testing metrics endpoint..." -ForegroundColor White
try {
    $metricsResponse = Invoke-WebRequest -Uri "{URL}/metrics" -UseBasicParsing -TimeoutSec 10
    if ($metricsResponse.StatusCode -eq 200) {
        Write-Host "Metrics endpoint is responding" -ForegroundColor Green
        $metrics = $metricsResponse.Content | ConvertFrom-Json
        if ($metrics.application_insights_metrics) {
            Write-Host "Application Insights metrics are available" -ForegroundColor Green
        } else {
            Write-Host "Application Insights metrics not yet available (may take a few minutes)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Metrics endpoint returned status: $($metricsResponse.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "Failed to test metrics endpoint: $($_.Exception.Message)" -ForegroundColor Red
}

# Test Application Insights debug endpoint
Write-Host "Testing Application Insights debug endpoint..." -ForegroundColor White
try {
    $debugResponse = Invoke-WebRequest -Uri "{URL}/debug/app-insights" -UseBasicParsing -TimeoutSec 10
    if ($debugResponse.StatusCode -eq 200) {
        Write-Host "Debug endpoint is responding" -ForegroundColor Green
        $debugInfo = $debugResponse.Content | ConvertFrom-Json
        if ($debugInfo.app_insights_configured) {
            Write-Host "Application Insights is properly configured" -ForegroundColor Green
        } else {
            Write-Host "Application Insights is not configured - check container logs" -ForegroundColor Red
        }
    } else {
        Write-Host "Debug endpoint returned status: $($debugResponse.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "Failed to test debug endpoint: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Phase 2 Deployment Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Monitoring Resources:" -ForegroundColor Cyan
Write-Host "   Application Insights: {URL}/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/components/$AppInsightsName" -ForegroundColor White
Write-Host "   Application URL: {URL}" -ForegroundColor White
Write-Host "   Health Check: {URL}/health" -ForegroundColor White
Write-Host "   Metrics Endpoint: {URL}/metrics" -ForegroundColor White
Write-Host ""
Write-Host "Available Queries:" -ForegroundColor Cyan
Write-Host "   Location: .\azure\log_analytics_queries\" -ForegroundColor White
Write-Host "   - cases_created_today.kql" -ForegroundColor White
Write-Host "   - error_analysis.kql" -ForegroundColor White
Write-Host "   - api_performance.kql" -ForegroundColor White
Write-Host "   - business_metrics_dashboard.kql" -ForegroundColor White
Write-Host "   - rate_limit_monitoring.kql" -ForegroundColor White
Write-Host "   - application_health_overview.kql" -ForegroundColor White
Write-Host "   - conversation_processing_details.kql" -ForegroundColor White
Write-Host "   - token_refresh_monitoring.kql" -ForegroundColor White
Write-Host ""
Write-Host "Available Dashboards:" -ForegroundColor Cyan
Write-Host "   Location: .\azure\dashboards\" -ForegroundColor White
Write-Host "   - business_metrics_dashboard.json" -ForegroundColor White
Write-Host "   - performance_dashboard.json" -ForegroundColor White
Write-Host "   - operations_dashboard.json" -ForegroundColor White
Write-Host ""
Write-Host " Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Wait 5-10 minutes for telemetry data to appear in Application Insights" -ForegroundColor White
Write-Host "   2. Import Log Analytics queries into your workspace" -ForegroundColor White
Write-Host "   3. Deploy dashboards using: .\azure\dashboards\deploy_dashboards.ps1" -ForegroundColor White
Write-Host "   4. Configure alert action groups for email/SMS notifications" -ForegroundColor White
Write-Host "   5. Test the monitoring by generating some application activity" -ForegroundColor White
Write-Host "   6. Check Application Insights dashboard for telemetry data" -ForegroundColor White
Write-Host ""
Write-Host "Enhanced Features Deployed:" -ForegroundColor Cyan
Write-Host "   Application Insights enabled and configured" -ForegroundColor Green
Write-Host "   Enhanced business metrics tracking" -ForegroundColor Green
Write-Host "   Performance monitoring" -ForegroundColor Green
Write-Host "   Custom telemetry for case creation" -ForegroundColor Green
Write-Host "   Comprehensive error tracking" -ForegroundColor Green
Write-Host "   API performance monitoring" -ForegroundColor Green
Write-Host "   Rate limit monitoring" -ForegroundColor Green
Write-Host "   Token refresh monitoring" -ForegroundColor Green
Write-Host "   Polling cycle monitoring" -ForegroundColor Green
Write-Host "   Periodic metrics logging" -ForegroundColor Green
Write-Host "   Business metrics API endpoint" -ForegroundColor Green
