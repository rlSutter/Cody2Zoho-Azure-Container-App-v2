#!/usr/bin/env pwsh

# Manual Dashboard Setup Guide
# This script provides instructions and alternative approaches for creating Application Insights dashboards

$ResourceGroup = "{AZURE RESOURCE GROUP}"
$AppInsightsName = "cody2zoho-insights"
$SubscriptionId = az account show --query "id" -o tsv

Write-Host "=== Manual Dashboard Setup Guide ===" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "Application Insights: $AppInsightsName" -ForegroundColor White
Write-Host "Subscription: $SubscriptionId" -ForegroundColor White
Write-Host ""

Write-Host "Since the Azure CLI portal extension is having installation issues, here are alternative approaches:" -ForegroundColor Yellow
Write-Host ""

Write-Host "=== Option 1: Manual Dashboard Creation in Azure Portal ===" -ForegroundColor Green
Write-Host "1. Go to Azure Portal: https://portal.azure.com" -ForegroundColor White
Write-Host "2. Navigate to your Application Insights resource: $AppInsightsName" -ForegroundColor White
Write-Host "3. Click on 'Dashboards' in the left menu" -ForegroundColor White
Write-Host "4. Click 'New Dashboard'" -ForegroundColor White
Write-Host "5. Add the following tiles:" -ForegroundColor White
Write-Host ""

Write-Host "=== Business Metrics Dashboard ===" -ForegroundColor Cyan
Write-Host "Add these tiles to your dashboard:" -ForegroundColor White
Write-Host ""

Write-Host "Tile 1: Cases Created" -ForegroundColor Yellow
Write-Host "   Type: Logs (Analytics)" -ForegroundColor White
Write-Host "   Query:" -ForegroundColor White
Write-Host "   customEvents | where timestamp >= ago(24h) | where customDimensions.eventName == 'case_created' | summarize CasesCreated = count() by bin(timestamp, 1h) | order by timestamp desc" -ForegroundColor Gray
Write-Host "   Visualization: Time Chart" -ForegroundColor White
Write-Host ""

Write-Host "Tile 2: Conversations Processed" -ForegroundColor Yellow
Write-Host "   Type: Logs (Analytics)" -ForegroundColor White
Write-Host "   Query:" -ForegroundColor White
Write-Host "   customEvents | where timestamp >= ago(24h) | where customDimensions.eventName == 'conversation_processed' | summarize ConversationsProcessed = count() by bin(timestamp, 1h) | order by timestamp desc" -ForegroundColor Gray
Write-Host "   Visualization: Time Chart" -ForegroundColor White
Write-Host ""

Write-Host "=== Performance Dashboard ===" -ForegroundColor Cyan
Write-Host "Add these tiles to your dashboard:" -ForegroundColor White
Write-Host ""

Write-Host "Tile 1: API Response Time" -ForegroundColor Yellow
Write-Host "   Type: Logs (Analytics)" -ForegroundColor White
Write-Host "   Query:" -ForegroundColor White
Write-Host "   customEvents | where timestamp >= ago(24h) | where customDimensions.eventName == 'api_call' | summarize AvgResponseTime = avg(customDimensions.response_time_ms) by bin(timestamp, 1h) | order by timestamp desc" -ForegroundColor Gray
Write-Host "   Visualization: Time Chart" -ForegroundColor White
Write-Host ""

Write-Host "Tile 2: Error Rate" -ForegroundColor Yellow
Write-Host "   Type: Logs (Analytics)" -ForegroundColor White
Write-Host "   Query:" -ForegroundColor White
Write-Host "   exceptions | where timestamp >= ago(24h) | summarize ErrorCount = count() by bin(timestamp, 1h) | order by timestamp desc" -ForegroundColor Gray
Write-Host "   Visualization: Time Chart" -ForegroundColor White
Write-Host ""

Write-Host "=== Operations Dashboard ===" -ForegroundColor Cyan
Write-Host "Add these tiles to your dashboard:" -ForegroundColor White
Write-Host ""

Write-Host "Tile 1: Polling Cycles" -ForegroundColor Yellow
Write-Host "   Type: Logs (Analytics)" -ForegroundColor White
Write-Host "   Query:" -ForegroundColor White
Write-Host "   customEvents | where timestamp >= ago(24h) | where customDimensions.eventName == 'polling_cycle_completed' | summarize PollingCycles = count() by bin(timestamp, 1h) | order by timestamp desc" -ForegroundColor Gray
Write-Host "   Visualization: Time Chart" -ForegroundColor White
Write-Host ""

Write-Host "Tile 2: Rate Limit Hits" -ForegroundColor Yellow
Write-Host "   Type: Logs (Analytics)" -ForegroundColor White
Write-Host "   Query:" -ForegroundColor White
Write-Host "   customEvents | where timestamp >= ago(24h) | where customDimensions.eventName == 'rate_limit_hit' | summarize RateLimitHits = count() by bin(timestamp, 1h) | order by timestamp desc" -ForegroundColor Gray
Write-Host "   Visualization: Time Chart" -ForegroundColor White
Write-Host ""

Write-Host "=== Option 2: Use Application Insights Logs (Analytics) ===" -ForegroundColor Green
Write-Host "Instead of dashboards, you can use the Logs (Analytics) section directly:" -ForegroundColor White
Write-Host ""
Write-Host "1. Go to Azure Portal: https://portal.azure.com" -ForegroundColor White
Write-Host "2. Navigate to your Application Insights resource: $AppInsightsName" -ForegroundColor White
Write-Host "3. Click on 'Logs (Analytics)' in the left menu" -ForegroundColor White
Write-Host "4. Use the queries above to analyze your data" -ForegroundColor White
Write-Host "5. Save frequently used queries as favorites" -ForegroundColor White
Write-Host ""

Write-Host "=== Option 3: Fix Portal Extension (Advanced) ===" -ForegroundColor Green
Write-Host "If you want to try fixing the portal extension:" -ForegroundColor White
Write-Host ""
Write-Host "1. Update Azure CLI to latest version:" -ForegroundColor White
Write-Host "   winget install Microsoft.AzureCLI" -ForegroundColor Gray
Write-Host "   or download from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Clear Azure CLI cache:" -ForegroundColor White
Write-Host "   Remove folder: $env:USERPROFILE\.azure\cliextensions" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Try installing portal extension again:" -ForegroundColor White
Write-Host "   az extension add --name portal --allow-preview true --yes" -ForegroundColor Gray
Write-Host ""

Write-Host "=== Quick Access Links ===" -ForegroundColor Cyan
Write-Host "Application Insights: https://portal.azure.com/#@/resource/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/components/$AppInsightsName" -ForegroundColor White
Write-Host "Logs (Analytics): https://portal.azure.com/#@/resource/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/components/$AppInsightsName/logs" -ForegroundColor White
Write-Host "Live Metrics: https://portal.azure.com/#@/resource/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/components/$AppInsightsName/liveMetrics" -ForegroundColor White
Write-Host ""

Write-Host "=== Recommended Approach ===" -ForegroundColor Yellow
Write-Host "For immediate results, use Option 2 (Logs Analytics) as it provides the same" -ForegroundColor White
Write-Host "functionality as dashboards and doesn't require any extensions." -ForegroundColor White
Write-Host ""
Write-Host "You can create custom queries and save them as favorites for quick access." -ForegroundColor White
Write-Host ""

Write-Host "=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Go to Application Insights Logs (Analytics)" -ForegroundColor White
Write-Host "2. Test the queries above to verify data is being collected" -ForegroundColor White
Write-Host "3. Create custom queries based on your specific needs" -ForegroundColor White
Write-Host "4. Set up alerts on important metrics" -ForegroundColor White
Write-Host "5. Share query results with your team" -ForegroundColor White
