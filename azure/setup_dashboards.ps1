#!/usr/bin/env pwsh

# Setup Application Insights Dashboards for Cody2Zoho
# This script creates comprehensive dashboards for monitoring the application

$ResourceGroup = "{AZURE RESOURCE GROUP}"
$AppInsightsName = "cody2zoho-insights"
$SubscriptionId = az account show --query "id" -o tsv

Write-Host "=== Setting up Application Insights Dashboards ===" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "Application Insights: $AppInsightsName" -ForegroundColor White
Write-Host ""

# Create dashboards directory
$dashboardsDir = ".\azure\dashboards"
if (-not (Test-Path $dashboardsDir)) {
    New-Item -ItemType Directory -Path $dashboardsDir -Force | Out-Null
}

Write-Host "1. Creating dashboard templates..." -ForegroundColor Yellow

# 1. Business Metrics Dashboard
$businessDashboard = @{
    "lenses" = @{
        "0" = @{
            "order" = 0
            "parts" = @{
                "0" = @{
                    "position" = @{
                        "x" = 0
                        "y" = 0
                        "colSpan" = 6
                        "rowSpan" = 4
                    }
                    "metadata" = @{
                        "inputs" = @(
                            @{
                                "name" = "timespan"
                                "isOptional" = $true
                            },
                            @{
                                "name" = "queryId"
                                "isOptional" = $true
                            }
                        )
                        "type" = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
                        "settings" = @{
                            "content" = @{
                                "Query" = "customEvents | where timestamp >= ago(24h) | where customDimensions.eventName == 'case_created' | summarize CasesCreated = count() by bin(timestamp, 1h) | order by timestamp desc"
                                "PartTitle" = "Cases Created (Last 24h)"
                                "PartSubTitle" = "Number of cases created per hour"
                            }
                        }
                    }
                }
                "1" = @{
                    "position" = @{
                        "x" = 6
                        "y" = 0
                        "colSpan" = 6
                        "rowSpan" = 4
                    }
                    "metadata" = @{
                        "type" = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
                        "settings" = @{
                            "content" = @{
                                "Query" = "customEvents | where timestamp >= ago(24h) | where customDimensions.eventName == 'conversation_processed' | summarize ConversationsProcessed = count() by bin(timestamp, 1h) | order by timestamp desc"
                                "PartTitle" = "Conversations Processed (Last 24h)"
                                "PartSubTitle" = "Number of conversations processed per hour"
                            }
                        }
                    }
                }
                "2" = @{
                    "position" = @{
                        "x" = 0
                        "y" = 4
                        "colSpan" = 6
                        "rowSpan" = 4
                    }
                    "metadata" = @{
                        "type" = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
                        "settings" = @{
                            "content" = @{
                                "Query" = "customEvents | where timestamp >= ago(24h) | where customDimensions.eventName == 'conversation_processed' | summarize AvgProcessingTime = avg(customDimensions.processing_time_seconds) by bin(timestamp, 1h) | order by timestamp desc"
                                "PartTitle" = "Average Processing Time (Last 24h)"
                                "PartSubTitle" = "Average time to process conversations"
                            }
                        }
                    }
                }
                "3" = @{
                    "position" = @{
                        "x" = 6
                        "y" = 4
                        "colSpan" = 6
                        "rowSpan" = 4
                    }
                    "metadata" = @{
                        "type" = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
                        "settings" = @{
                            "content" = @{
                                "Query" = "customEvents | where timestamp >= ago(24h) | where customDimensions.eventName == 'case_created' | summarize AvgMessageCount = avg(customDimensions.message_count), AvgCharacterCount = avg(customDimensions.character_count) by bin(timestamp, 1h) | order by timestamp desc"
                                "PartTitle" = "Conversation Statistics (Last 24h)"
                                "PartSubTitle" = "Average message count and character count"
                            }
                        }
                    }
                }
            }
        }
    }
    "metadata" = @{
        "model" = @{
            "timeRange" = @{
                "value" = @{
                    "relative" = @{
                        "duration" = 86400000
                    }
                }
                "type" = "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
            }
            "filterLocale" = @{
                "value" = "en-us"
            }
            "filters" = @{
                "value" = @{
                    "MsPortalFx_TimeRange" = @{
                        "model" = @{
                            "format" = "utc"
                            "value" = @{
                                "relative" = @{
                                    "duration" = 86400000
                                }
                            }
                        }
                        "displayCache" = @{
                            "name" = "UTC Time"
                            "value" = "Past 24 hours"
                        }
                        "filteredPartIds" = @{
                            "0" = "0"
                            "1" = "1"
                            "2" = "2"
                            "3" = "3"
                        }
                    }
                }
            }
        }
    }
    "name" = "Cody2Zoho Business Metrics"
    "type" = "Microsoft.OperationsManagement/solutions"
}

$businessDashboard | ConvertTo-Json -Depth 10 | Out-File -FilePath "$dashboardsDir\business_metrics_dashboard.json" -Encoding UTF8
Write-Host "   Business Metrics Dashboard template created" -ForegroundColor Green

# 2. Performance Dashboard
$performanceDashboard = @{
    "lenses" = @{
        "0" = @{
            "order" = 0
            "parts" = @{
                "0" = @{
                    "position" = @{
                        "x" = 0
                        "y" = 0
                        "colSpan" = 6
                        "rowSpan" = 4
                    }
                    "metadata" = @{
                        "type" = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
                        "settings" = @{
                            "content" = @{
                                "Query" = "requests | where timestamp >= ago(24h) | summarize RequestCount = count(), SuccessRate = 100.0 * countif(success == true) / count() by bin(timestamp, 1h) | order by timestamp desc"
                                "PartTitle" = "Request Success Rate (Last 24h)"
                                "PartSubTitle" = "Percentage of successful requests"
                            }
                        }
                    }
                }
                "1" = @{
                    "position" = @{
                        "x" = 6
                        "y" = 0
                        "colSpan" = 6
                        "rowSpan" = 4
                    }
                    "metadata" = @{
                        "type" = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
                        "settings" = @{
                            "content" = @{
                                "Query" = "dependencies | where timestamp >= ago(24h) | where type == 'Http' | summarize AvgDuration = avg(duration), MaxDuration = max(duration) by target, bin(timestamp, 1h) | order by AvgDuration desc"
                                "PartTitle" = "API Response Times (Last 24h)"
                                "PartSubTitle" = "Average and maximum response times"
                            }
                        }
                    }
                }
                "2" = @{
                    "position" = @{
                        "x" = 0
                        "y" = 4
                        "colSpan" = 6
                        "rowSpan" = 4
                    }
                    "metadata" = @{
                        "type" = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
                        "settings" = @{
                            "content" = @{
                                "Query" = "exceptions | where timestamp >= ago(24h) | summarize ErrorCount = count() by type, bin(timestamp, 1h) | order by ErrorCount desc"
                                "PartTitle" = "Error Analysis (Last 24h)"
                                "PartSubTitle" = "Errors by type and frequency"
                            }
                        }
                    }
                }
                "3" = @{
                    "position" = @{
                        "x" = 6
                        "y" = 4
                        "colSpan" = 6
                        "rowSpan" = 4
                    }
                    "metadata" = @{
                        "type" = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
                        "settings" = @{
                            "content" = @{
                                "Query" = "performanceCounters | where timestamp >= ago(24h) | where name == '\\Process(_Total)\\Private Bytes' | summarize MemoryUsage = avg(value) by bin(timestamp, 1h) | order by timestamp desc"
                                "PartTitle" = "Memory Usage (Last 24h)"
                                "PartSubTitle" = "Application memory consumption"
                            }
                        }
                    }
                }
            }
        }
    }
    "metadata" = @{
        "model" = @{
            "timeRange" = @{
                "value" = @{
                    "relative" = @{
                        "duration" = 86400000
                    }
                }
                "type" = "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
            }
            "filterLocale" = @{
                "value" = "en-us"
            }
            "filters" = @{
                "value" = @{
                    "MsPortalFx_TimeRange" = @{
                        "model" = @{
                            "format" = "utc"
                            "value" = @{
                                "relative" = @{
                                    "duration" = 86400000
                                }
                            }
                        }
                        "displayCache" = @{
                            "name" = "UTC Time"
                            "value" = "Past 24 hours"
                        }
                        "filteredPartIds" = @{
                            "0" = "0"
                            "1" = "1"
                            "2" = "2"
                            "3" = "3"
                        }
                    }
                }
            }
        }
    }
    "name" = "Cody2Zoho Performance Monitoring"
    "type" = "Microsoft.OperationsManagement/solutions"
}

$performanceDashboard | ConvertTo-Json -Depth 10 | Out-File -FilePath "$dashboardsDir\performance_dashboard.json" -Encoding UTF8
Write-Host "   Performance Dashboard template created" -ForegroundColor Green

# 3. Operations Dashboard
$operationsDashboard = @{
    "lenses" = @{
        "0" = @{
            "order" = 0
            "parts" = @{
                "0" = @{
                    "position" = @{
                        "x" = 0
                        "y" = 0
                        "colSpan" = 6
                        "rowSpan" = 4
                    }
                    "metadata" = @{
                        "type" = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
                        "settings" = @{
                            "content" = @{
                                "Query" = "customEvents | where timestamp >= ago(24h) | where customDimensions.eventName == 'polling_cycle_completed' | summarize Cycles = count(), AvgDuration = avg(customDimensions.cycle_duration_seconds) by bin(timestamp, 1h) | order by timestamp desc"
                                "PartTitle" = "Polling Cycles (Last 24h)"
                                "PartSubTitle" = "Number of polling cycles and average duration"
                            }
                        }
                    }
                }
                "1" = @{
                    "position" = @{
                        "x" = 6
                        "y" = 0
                        "colSpan" = 6
                        "rowSpan" = 4
                    }
                    "metadata" = @{
                        "type" = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
                        "settings" = @{
                            "content" = @{
                                "Query" = "customEvents | where timestamp >= ago(24h) | where customDimensions.eventName == 'rate_limit_hit' | summarize RateLimitHits = count() by customDimensions.api_name, bin(timestamp, 1h) | order by RateLimitHits desc"
                                "PartTitle" = "Rate Limit Hits (Last 24h)"
                                "PartSubTitle" = "API rate limit violations"
                            }
                        }
                    }
                }
                "2" = @{
                    "position" = @{
                        "x" = 0
                        "y" = 4
                        "colSpan" = 6
                        "rowSpan" = 4
                    }
                    "metadata" = @{
                        "type" = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
                        "settings" = @{
                            "content" = @{
                                "Query" = "customEvents | where timestamp >= ago(24h) | where customDimensions.eventName == 'token_refresh' | summarize RefreshCount = count(), SuccessRate = 100.0 * countif(customDimensions.success == 'true') / count() by bin(timestamp, 1h) | order by timestamp desc"
                                "PartTitle" = "Token Refresh (Last 24h)"
                                "PartSubTitle" = "Token refresh attempts and success rate"
                            }
                        }
                    }
                }
                "3" = @{
                    "position" = @{
                        "x" = 6
                        "y" = 4
                        "colSpan" = 6
                        "rowSpan" = 4
                    }
                    "metadata" = @{
                        "type" = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
                        "settings" = @{
                            "content" = @{
                                "Query" = "customEvents | where timestamp >= ago(24h) | where customDimensions.eventName == 'api_call' | summarize ApiCalls = count(), AvgDuration = avg(customDimensions.duration_seconds) by customDimensions.api_name, bin(timestamp, 1h) | order by ApiCalls desc"
                                "PartTitle" = "API Calls (Last 24h)"
                                "PartSubTitle" = "Number of API calls and average duration"
                            }
                        }
                    }
                }
            }
        }
    }
    "metadata" = @{
        "model" = @{
            "timeRange" = @{
                "value" = @{
                    "relative" = @{
                        "duration" = 86400000
                    }
                }
                "type" = "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
            }
            "filterLocale" = @{
                "value" = "en-us"
            }
            "filters" = @{
                "value" = @{
                    "MsPortalFx_TimeRange" = @{
                        "model" = @{
                            "format" = "utc"
                            "value" = @{
                                "relative" = @{
                                    "duration" = 86400000
                                }
                            }
                        }
                        "displayCache" = @{
                            "name" = "UTC Time"
                            "value" = "Past 24 hours"
                        }
                        "filteredPartIds" = @{
                            "0" = "0"
                            "1" = "1"
                            "2" = "2"
                            "3" = "3"
                        }
                    }
                }
            }
        }
    }
    "name" = "Cody2Zoho Operations Monitoring"
    "type" = "Microsoft.OperationsManagement/solutions"
}

$operationsDashboard | ConvertTo-Json -Depth 10 | Out-File -FilePath "$dashboardsDir\operations_dashboard.json" -Encoding UTF8
Write-Host "   Operations Dashboard template created" -ForegroundColor Green

Write-Host ""
Write-Host "2. Creating dashboard deployment script..." -ForegroundColor Yellow

# Create deployment script
$deploymentScript = @"
# Deploy Application Insights Dashboards
# Run this script to deploy the dashboard templates

Write-Host "Deploying Application Insights Dashboards..." -ForegroundColor Cyan

# Ensure portal extension is installed
Write-Host "Checking Azure CLI portal extension..." -ForegroundColor Yellow
try {
    az extension show --name portal 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Installing Azure CLI portal extension..." -ForegroundColor Yellow
        az extension add --name portal --yes
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to install portal extension. Trying alternative method..." -ForegroundColor Red
            az extension add --name portal --source https://aka.ms/portal-extension --yes
        }
    } else {
        Write-Host "Portal extension is already installed" -ForegroundColor Green
    }
} catch {
    Write-Host "Error checking portal extension: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Attempting to install portal extension..." -ForegroundColor Yellow
    az extension add --name portal --yes
}

# Verify portal extension is working
Write-Host "Verifying portal extension..." -ForegroundColor Yellow
az portal dashboard list --resource-group "$ResourceGroup" --output table 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Portal extension verification failed. Please install manually:" -ForegroundColor Red
    Write-Host "   az extension add --name portal --yes" -ForegroundColor White
    Write-Host "   az extension update --name portal" -ForegroundColor White
    exit 1
}

# Deploy Business Metrics Dashboard
Write-Host "Deploying Business Metrics Dashboard..." -ForegroundColor Yellow
az portal dashboard create --resource-group "$ResourceGroup" --location "eastus" --name "cody2zoho-business-metrics" --input-path "$dashboardsDir\business_metrics_dashboard.json" --output none

# Deploy Performance Dashboard  
Write-Host "Deploying Performance Dashboard..." -ForegroundColor Yellow
az portal dashboard create --resource-group "$ResourceGroup" --location "eastus" --name "cody2zoho-performance" --input-path "$dashboardsDir\performance_dashboard.json" --output none

# Deploy Operations Dashboard
Write-Host "Deploying Operations Dashboard..." -ForegroundColor Yellow
az portal dashboard create --resource-group "$ResourceGroup" --location "eastus" --name "cody2zoho-operations" --input-path "$dashboardsDir\operations_dashboard.json" --output none

Write-Host "Dashboard deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Dashboard URLs:" -ForegroundColor Cyan
Write-Host "Business Metrics: {AZURE APPLICATION INSIGHTS URL}/cody2zoho-business-metrics" -ForegroundColor White
Write-Host "Performance: {AZURE APPLICATION INSIGHTS URL}/cody2zoho-performance" -ForegroundColor White
Write-Host "Operations: {AZURE APPLICATION INSIGHTS URL}/cody2zoho-operations" -ForegroundColor White
"@

$deploymentScript | Out-File -FilePath "$dashboardsDir\deploy_dashboards.ps1" -Encoding UTF8
Write-Host "   Dashboard deployment script created" -ForegroundColor Green

Write-Host ""
Write-Host "=== Dashboard Setup Complete ===" -ForegroundColor Green
Write-Host "Dashboard templates saved to: $dashboardsDir" -ForegroundColor White
Write-Host ""
Write-Host "Available Dashboards:" -ForegroundColor Yellow
Write-Host "   1. business_metrics_dashboard.json - Business metrics and case creation" -ForegroundColor White
Write-Host "   2. performance_dashboard.json - Performance and error monitoring" -ForegroundColor White
Write-Host "   3. operations_dashboard.json - Operations and API monitoring" -ForegroundColor White
Write-Host ""
Write-Host "To deploy dashboards:" -ForegroundColor Yellow
Write-Host "   .\azure\dashboards\deploy_dashboards.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "   1. Deploy the dashboards using the deployment script" -ForegroundColor White
Write-Host "   2. Customize dashboard queries as needed" -ForegroundColor White
Write-Host "   3. Set up dashboard sharing with team members" -ForegroundColor White
Write-Host "   4. Configure dashboard refresh intervals" -ForegroundColor White
