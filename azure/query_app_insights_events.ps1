#!/usr/bin/env pwsh

# Check Application Insights Logged Events for Cody2Zoho
# This script queries and displays telemetry data from Application Insights

$ResourceGroup = "{AZURE RESOURCE GROUP}"
$AppInsightsName = "cody2zoho-insights"
$SubscriptionId = az account show --query "id" -o tsv

Write-Host "=== Application Insights Events Check ===" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "Application Insights: $AppInsightsName" -ForegroundColor White
Write-Host ""

# Check if Application Insights is accessible
Write-Host "1. Checking Application Insights status..." -ForegroundColor Yellow
$aiStatus = az resource show --name $AppInsightsName --resource-group $ResourceGroup --resource-type "Microsoft.Insights/components" --query "properties.provisioningState" -o tsv

if ($aiStatus -eq "Succeeded") {
    Write-Host "   Application Insights is active" -ForegroundColor Green
} else {
    Write-Host "   Application Insights status: $aiStatus" -ForegroundColor Red
    exit 1
}

# Get Application Insights connection string
Write-Host "2. Getting Application Insights connection string..." -ForegroundColor Yellow
$connectionString = az resource show --name $AppInsightsName --resource-group $ResourceGroup --resource-type "Microsoft.Insights/components" --query "properties.ConnectionString" -o tsv

if ($connectionString) {
    Write-Host "   Connection string retrieved" -ForegroundColor Green
} else {
    Write-Host "   Failed to get connection string" -ForegroundColor Red
    exit 1
}

# Check recent events using Log Analytics
Write-Host "3. Querying recent telemetry events..." -ForegroundColor Yellow

# Get workspace ID
$workspaceId = az monitor log-analytics workspace list --resource-group $ResourceGroup --query "[0].customerId" -o tsv

if (-not $workspaceId) {
    Write-Host "   No Log Analytics workspace found, creating one..." -ForegroundColor Yellow
    az monitor log-analytics workspace create --resource-group $ResourceGroup --workspace-name "cody2zoho-workspace" --location "eastus" --output none
    $workspaceId = az monitor log-analytics workspace list --resource-group $ResourceGroup --query "[0].customerId" -o tsv
}

Write-Host "   Workspace ID: $workspaceId" -ForegroundColor White

# Query recent custom events
Write-Host "4. Recent Custom Events (last 24 hours):" -ForegroundColor Yellow
$customEventsQuery = @"
customEvents
| where timestamp >= ago(24h)
| where cloud_RoleName == "Cody2Zoho"
| summarize EventCount = count() by customDimensions.eventName, bin(timestamp, 1h)
| order by timestamp desc
"@

$customEventsQuery | Out-File -FilePath "temp_query.kql" -Encoding UTF8
$customEvents = az monitor log-analytics query --workspace $workspaceId --analytics-query "temp_query.kql" --output table 2>$null

if ($customEvents) {
    Write-Host "   Recent custom events:" -ForegroundColor Green
    $customEvents | Write-Host
} else {
    Write-Host "   No custom events found in the last 24 hours" -ForegroundColor Yellow
}

# Query recent traces
Write-Host "5. Recent Traces (last 24 hours):" -ForegroundColor Yellow
$tracesQuery = @"
traces
| where timestamp >= ago(24h)
| where cloud_RoleName == "Cody2Zoho"
| summarize TraceCount = count() by severityLevel, bin(timestamp, 1h)
| order by timestamp desc
"@

$tracesQuery | Out-File -FilePath "temp_traces_query.kql" -Encoding UTF8
$traces = az monitor log-analytics query --workspace $workspaceId --analytics-query "temp_traces_query.kql" --output table 2>$null

if ($traces) {
    Write-Host "   Recent traces:" -ForegroundColor Green
    $traces | Write-Host
} else {
    Write-Host "   No traces found in the last 24 hours" -ForegroundColor Yellow
}

# Query recent exceptions
Write-Host "6. Recent Exceptions (last 24 hours):" -ForegroundColor Yellow
$exceptionsQuery = @"
exceptions
| where timestamp >= ago(24h)
| where cloud_RoleName == "Cody2Zoho"
| summarize ExceptionCount = count() by type, bin(timestamp, 1h)
| order by ExceptionCount desc
"@

$exceptionsQuery | Out-File -FilePath "temp_exceptions_query.kql" -Encoding UTF8
$exceptions = az monitor log-analytics query --workspace $workspaceId --analytics-query "temp_exceptions_query.kql" --output table 2>$null

if ($exceptions) {
    Write-Host "   Recent exceptions:" -ForegroundColor Green
    $exceptions | Write-Host
} else {
    Write-Host "   No exceptions found in the last 24 hours" -ForegroundColor Green
}

# Query recent dependencies (API calls)
Write-Host "7. Recent API Calls (last 24 hours):" -ForegroundColor Yellow
$dependenciesQuery = @"
dependencies
| where timestamp >= ago(24h)
| where cloud_RoleName == "Cody2Zoho"
| summarize ApiCallCount = count(), AvgDuration = avg(duration) by target, bin(timestamp, 1h)
| order by ApiCallCount desc
"@

$dependenciesQuery | Out-File -FilePath "temp_dependencies_query.kql" -Encoding UTF8
$dependencies = az monitor log-analytics query --workspace $workspaceId --analytics-query "temp_dependencies_query.kql" --output table 2>$null

if ($dependencies) {
    Write-Host "   Recent API calls:" -ForegroundColor Green
    $dependencies | Write-Host
} else {
    Write-Host "   No API calls found in the last 24 hours" -ForegroundColor Yellow
}

# Query business metrics
Write-Host "8. Business Metrics Summary (last 24 hours):" -ForegroundColor Yellow
$businessMetricsQuery = @"
customEvents
| where timestamp >= ago(24h)
| where cloud_RoleName == "Cody2Zoho"
| where customDimensions.eventName in ("case_created", "conversation_processed", "polling_cycle_completed")
| summarize 
    CasesCreated = countif(customDimensions.eventName == "case_created"),
    ConversationsProcessed = countif(customDimensions.eventName == "conversation_processed"),
    PollingCycles = countif(customDimensions.eventName == "polling_cycle_completed")
    by bin(timestamp, 1h)
| order by timestamp desc
"@

$businessMetricsQuery | Out-File -FilePath "temp_business_query.kql" -Encoding UTF8
$businessMetrics = az monitor log-analytics query --workspace $workspaceId --analytics-query "temp_business_query.kql" --output table 2>$null

if ($businessMetrics) {
    Write-Host "   Business metrics:" -ForegroundColor Green
    $businessMetrics | Write-Host
} else {
    Write-Host "   No business metrics found in the last 24 hours" -ForegroundColor Yellow
}

# Clean up temporary files
Remove-Item -Path "temp_query.kql" -ErrorAction SilentlyContinue
Remove-Item -Path "temp_traces_query.kql" -ErrorAction SilentlyContinue
Remove-Item -Path "temp_exceptions_query.kql" -ErrorAction SilentlyContinue
Remove-Item -Path "temp_dependencies_query.kql" -ErrorAction SilentlyContinue
Remove-Item -Path "temp_business_query.kql" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=== Application Insights Dashboard ===" -ForegroundColor Cyan
Write-Host "View detailed telemetry in Azure Portal:" -ForegroundColor White
Write-Host "   https://portal.azure.com/#@/resource/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/components/$AppInsightsName" -ForegroundColor Cyan
Write-Host ""
Write-Host "=== Log Analytics Workspace ===" -ForegroundColor Cyan
Write-Host "Run custom queries in Log Analytics:" -ForegroundColor White
Write-Host "   https://portal.azure.com/#@/resource/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.OperationalInsights/workspaces/cody2zoho-workspace/queries" -ForegroundColor Cyan
Write-Host ""
Write-Host "=== Check Complete ===" -ForegroundColor Green
