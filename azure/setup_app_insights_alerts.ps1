#!/usr/bin/env pwsh

# Setup Application Insights Alerts for Cody2Zoho
# This script creates comprehensive alerts for monitoring the application

$ResourceGroup = "{AZURE RESOURCE GROUP}"
$AppName = "cody2zoho"
$AppInsightsName = "cody2zoho-insights"
$SubscriptionId = az account show --query "id" -o tsv

Write-Host "=== Setting up Application Insights Alerts ===" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "Application: $AppName" -ForegroundColor White
Write-Host "Application Insights: $AppInsightsName" -ForegroundColor White
Write-Host ""

# 1. High Error Rate Alert
Write-Host "1. Creating High Error Rate Alert..." -ForegroundColor Yellow
$errorAlertRule = @{
    Name = "cody2zoho-high-error-rate"
    DisplayName = "Cody2Zoho - High Error Rate"
    Description = "Alert when error rate exceeds 5% in 5 minutes"
    Severity = "2"  # Warning
    Enabled = $true
    Condition = @{
        AllOf = @(
            @{
                MetricName = "exceptions/count"
                MetricNamespace = "Microsoft.Insights/Components"
                Operator = "GreaterThan"
                Threshold = "5"
                TimeAggregation = "Count"
                WindowSize = "PT5M"
            }
        )
    }
    Actions = @(
        @{
            ActionGroupId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/actionGroups/cody2zoho-alerts"
        }
    )
}

az monitor metrics alert create `
    --name $errorAlertRule.Name `
    --resource-group $ResourceGroup `
    --scopes "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/Components/$AppInsightsName" `
    --condition "count 'exceptions/count' > 5" `
    --window-size "PT5M" `
    --evaluation-frequency "PT1M" `
    --description $errorAlertRule.Description `
    --severity $errorAlertRule.Severity `
    --output none

Write-Host "   ✅ High Error Rate Alert created" -ForegroundColor Green

# 2. No Cases Created Alert
Write-Host "2. Creating No Cases Created Alert..." -ForegroundColor Yellow
az monitor metrics alert create `
    --name "cody2zoho-no-cases-created" `
    --resource-group $ResourceGroup `
    --scopes "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/Components/$AppInsightsName" `
    --condition "count 'customEvents/count' where customDimensions.eventName == 'case_created' == 0" `
    --window-size "PT30M" `
    --evaluation-frequency "PT5M" `
    --description "Alert when no cases are created for 30 minutes" `
    --severity "1" `
    --output none

Write-Host "   ✅ No Cases Created Alert created" -ForegroundColor Green

# 3. High API Response Time Alert
Write-Host "3. Creating High API Response Time Alert..." -ForegroundColor Yellow
az monitor metrics alert create `
    --name "cody2zoho-high-api-response-time" `
    --resource-group $ResourceGroup `
    --scopes "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/Components/$AppInsightsName" `
    --condition "avg 'dependencies/duration' > 10000" `
    --window-size "PT5M" `
    --evaluation-frequency "PT1M" `
    --description "Alert when API response time exceeds 10 seconds" `
    --severity "2" `
    --output none

Write-Host "   ✅ High API Response Time Alert created" -ForegroundColor Green

# 4. Application Unavailable Alert
Write-Host "4. Creating Application Unavailable Alert..." -ForegroundColor Yellow
az monitor metrics alert create `
    --name "cody2zoho-application-unavailable" `
    --resource-group $ResourceGroup `
    --scopes "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/Components/$AppInsightsName" `
    --condition "count 'requests/count' == 0" `
    --window-size "PT5M" `
    --evaluation-frequency "PT1M" `
    --description "Alert when no requests are received for 5 minutes" `
    --severity "0" `
    --output none

Write-Host "   ✅ Application Unavailable Alert created" -ForegroundColor Green

# 5. High Memory Usage Alert
Write-Host "5. Creating High Memory Usage Alert..." -ForegroundColor Yellow
az monitor metrics alert create `
    --name "cody2zoho-high-memory-usage" `
    --resource-group $ResourceGroup `
    --scopes "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/Components/$AppInsightsName" `
    --condition "avg 'performanceCounters/processPrivateBytes' > 500000000" `
    --window-size "PT5M" `
    --evaluation-frequency "PT1M" `
    --description "Alert when memory usage exceeds 500MB" `
    --severity "2" `
    --output none

Write-Host "   ✅ High Memory Usage Alert created" -ForegroundColor Green

# 6. Rate Limit Alert
Write-Host "6. Creating Rate Limit Alert..." -ForegroundColor Yellow
az monitor metrics alert create `
    --name "cody2zoho-rate-limit-hit" `
    --resource-group $ResourceGroup `
    --scopes "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/Components/$AppInsightsName" `
    --condition "count 'customEvents/count' where customDimensions.eventName == 'rate_limit_hit' > 0" `
    --window-size "PT5M" `
    --evaluation-frequency "PT1M" `
    --description "Alert when API rate limit is hit" `
    --severity "2" `
    --output none

Write-Host "   ✅ Rate Limit Alert created" -ForegroundColor Green

# List all alerts
Write-Host ""
Write-Host "=== Created Alerts ===" -ForegroundColor Cyan
az monitor metrics alert list --resource-group $ResourceGroup --output table

Write-Host ""
Write-Host "=== Alert Setup Complete ===" -ForegroundColor Green
Write-Host "View alerts in Azure Portal:" -ForegroundColor White
Write-Host "   https://portal.azure.com/#@/resource/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/Components/$AppInsightsName/alerts" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "   1. Configure action groups for email/SMS notifications" -ForegroundColor White
Write-Host "   2. Set up webhook actions for integration with other systems" -ForegroundColor White
Write-Host "   3. Test alerts by triggering conditions" -ForegroundColor White
