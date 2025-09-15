#!/usr/bin/env pwsh

# Setup Log Analytics Queries for Cody2Zoho
# This script creates useful KQL queries for monitoring the application

$ResourceGroup = "{AZURE RESOURCE GROUP}"
$AppInsightsName = "cody2zoho-insights"
$WorkspaceName = "cody2zoho-workspace"

Write-Host "=== Setting up Log Analytics Queries ===" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "Application Insights: $AppInsightsName" -ForegroundColor White
Write-Host ""

# Create Log Analytics workspace if it doesn't exist
Write-Host "1. Creating Log Analytics workspace..." -ForegroundColor Yellow
$workspaceExists = az monitor log-analytics workspace show --resource-group $ResourceGroup --workspace-name $WorkspaceName --query "name" -o tsv 2>$null

if (-not $workspaceExists) {
    az monitor log-analytics workspace create --resource-group $ResourceGroup --workspace-name $WorkspaceName --location "eastus" --output none
    Write-Host "   Log Analytics workspace created" -ForegroundColor Green
} else {
    Write-Host "   Log Analytics workspace already exists" -ForegroundColor Green
}

# Get workspace ID
$workspaceId = az monitor log-analytics workspace show --resource-group $ResourceGroup --workspace-name $WorkspaceName --query "customerId" -o tsv

Write-Host ""
Write-Host "2. Creating saved queries..." -ForegroundColor Yellow

# Create queries directory
$queriesDir = ".\azure\log_analytics_queries"
if (-not (Test-Path $queriesDir)) {
    New-Item -ItemType Directory -Path $queriesDir -Force | Out-Null
}

# 1. Cases Created Today
$casesCreatedQuery = @"
// Cases Created Today
customEvents
| where timestamp >= startofday(now())
| where customDimensions.eventName == "case_created"
| summarize 
    CasesCreated = count(),
    Conversations = dcount(customDimensions.conversation_id),
    AvgMessageCount = avg(customDimensions.message_count),
    AvgCharacterCount = avg(customDimensions.character_count)
    by bin(timestamp, 1h)
| order by timestamp desc
"@

$casesCreatedQuery | Out-File -FilePath "$queriesDir\cases_created_today.kql" -Encoding UTF8
Write-Host "   Cases Created Today query saved" -ForegroundColor Green

# 2. Error Analysis
$errorAnalysisQuery = @"
// Error Analysis
exceptions
| where timestamp >= ago(24h)
| summarize 
    ErrorCount = count(),
    ErrorTypes = dcount(type),
    AffectedConversations = dcount(customDimensions.conversation_id)
    by type, bin(timestamp, 1h)
| order by ErrorCount desc
"@

$errorAnalysisQuery | Out-File -FilePath "$queriesDir\error_analysis.kql" -Encoding UTF8
Write-Host "   Error Analysis query saved" -ForegroundColor Green

# 3. API Performance
$apiPerformanceQuery = @"
// API Performance
dependencies
| where timestamp >= ago(24h)
| where type == "Http"
| summarize 
    RequestCount = count(),
    AvgDuration = avg(duration),
    MaxDuration = max(duration),
    SuccessRate = 100.0 * countif(success == true) / count()
    by target, bin(timestamp, 1h)
| order by AvgDuration desc
"@

$apiPerformanceQuery | Out-File -FilePath "$queriesDir\api_performance.kql" -Encoding UTF8
Write-Host "   API Performance query saved" -ForegroundColor Green

# 4. Business Metrics Dashboard
$businessMetricsQuery = @"
// Business Metrics Dashboard
customEvents
| where timestamp >= ago(7d)
| where customDimensions.eventName in ("case_created", "conversation_processed", "polling_cycle_completed")
| summarize 
    CasesCreated = countif(customDimensions.eventName == "case_created"),
    ConversationsProcessed = countif(customDimensions.eventName == "conversation_processed"),
    PollingCycles = countif(customDimensions.eventName == "polling_cycle_completed"),
    AvgProcessingTime = avgif(customDimensions.processing_time_seconds, customDimensions.eventName == "conversation_processed"),
    AvgMessageCount = avgif(customDimensions.message_count, customDimensions.eventName == "case_created")
    by bin(timestamp, 1d)
| order by timestamp desc
"@

$businessMetricsQuery | Out-File -FilePath "$queriesDir\business_metrics_dashboard.kql" -Encoding UTF8
Write-Host "   Business Metrics Dashboard query saved" -ForegroundColor Green

# 5. Rate Limit Monitoring
$rateLimitQuery = @"
// Rate Limit Monitoring
customEvents
| where timestamp >= ago(24h)
| where customDimensions.eventName == "rate_limit_hit"
| summarize 
    RateLimitHits = count(),
    APIs = dcount(customDimensions.api_name)
    by customDimensions.api_name, bin(timestamp, 1h)
| order by RateLimitHits desc
"@

$rateLimitQuery | Out-File -FilePath "$queriesDir\rate_limit_monitoring.kql" -Encoding UTF8
Write-Host "   Rate Limit Monitoring query saved" -ForegroundColor Green

# 6. Application Health Overview
$healthOverviewQuery = @"
// Application Health Overview
requests
| where timestamp >= ago(24h)
| summarize 
    RequestCount = count(),
    SuccessRate = 100.0 * countif(success == true) / count(),
    AvgResponseTime = avg(duration),
    ErrorCount = countif(success == false)
    by bin(timestamp, 1h)
| order by timestamp desc
"@

$healthOverviewQuery | Out-File -FilePath "$queriesDir\application_health_overview.kql" -Encoding UTF8
Write-Host "   Application Health Overview query saved" -ForegroundColor Green

# 7. Conversation Processing Details
$conversationDetailsQuery = @"
// Conversation Processing Details
customEvents
| where timestamp >= ago(24h)
| where customDimensions.eventName == "conversation_processed"
| project 
    timestamp,
    conversation_id = customDimensions.conversation_id,
    processing_time = customDimensions.processing_time_seconds,
    success = customDimensions.success,
    case_created = customDimensions.case_created,
    message_count = customDimensions.message_count,
    character_count = customDimensions.character_count
| order by timestamp desc
"@

$conversationDetailsQuery | Out-File -FilePath "$queriesDir\conversation_processing_details.kql" -Encoding UTF8
Write-Host "   Conversation Processing Details query saved" -ForegroundColor Green

# 8. Token Refresh Monitoring
$tokenRefreshQuery = @"
// Token Refresh Monitoring
customEvents
| where timestamp >= ago(24h)
| where customDimensions.eventName == "token_refresh"
| summarize 
    RefreshCount = count(),
    SuccessRate = 100.0 * countif(customDimensions.success == "true") / count(),
    AvgDuration = avgif(customDimensions.duration_seconds, customDimensions.duration_seconds > 0)
    by bin(timestamp, 1h)
| order by timestamp desc
"@

$tokenRefreshQuery | Out-File -FilePath "$queriesDir\token_refresh_monitoring.kql" -Encoding UTF8
Write-Host "   Token Refresh Monitoring query saved" -ForegroundColor Green

Write-Host ""
Write-Host "=== Query Setup Complete ===" -ForegroundColor Green
Write-Host "View queries in Azure Portal:" -ForegroundColor White
Write-Host "   {AZURE APPLICATION INSIGHTS PORTAL URL}" -ForegroundColor Cyan
Write-Host ""
Write-Host "Queries saved to: $queriesDir" -ForegroundColor White
Write-Host ""
Write-Host "Available Queries:" -ForegroundColor Yellow
Write-Host "   1. cases_created_today.kql - Cases created in the last 24 hours" -ForegroundColor White
Write-Host "   2. error_analysis.kql - Error analysis and trends" -ForegroundColor White
Write-Host "   3. api_performance.kql - API response times and success rates" -ForegroundColor White
Write-Host "   4. business_metrics_dashboard.kql - Business metrics overview" -ForegroundColor White
Write-Host "   5. rate_limit_monitoring.kql - API rate limit monitoring" -ForegroundColor White
Write-Host "   6. application_health_overview.kql - Application health metrics" -ForegroundColor White
Write-Host "   7. conversation_processing_details.kql - Detailed conversation processing" -ForegroundColor White
Write-Host "   8. token_refresh_monitoring.kql - Token refresh monitoring" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "   1. Import queries into Log Analytics workspace" -ForegroundColor White
Write-Host "   2. Create dashboards using these queries" -ForegroundColor White
Write-Host "   3. Set up scheduled queries for automated reporting" -ForegroundColor White
