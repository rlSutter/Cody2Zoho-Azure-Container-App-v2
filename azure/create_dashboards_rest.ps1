#!/usr/bin/env pwsh

# Create Application Insights Dashboards using REST API
# This script bypasses the portal extension issue by using direct REST API calls

$ResourceGroup = "{AZURE RESOURCE GROUP}"
$Location = "eastus"
$SubscriptionId = az account show --query "id" -o tsv

Write-Host "=== Creating Application Insights Dashboards via REST API ===" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "Location: $Location" -ForegroundColor White
Write-Host "Subscription: $SubscriptionId" -ForegroundColor White
Write-Host ""

# Get access token for REST API
Write-Host "1. Getting Azure access token..." -ForegroundColor Yellow
try {
    $token = az account get-access-token --resource "https://management.azure.com" --query "accessToken" -o tsv
    if (-not $token) {
        throw "Failed to get access token"
    }
    Write-Host "   Access token obtained successfully" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: Failed to get access token" -ForegroundColor Red
    Write-Host "   Please ensure you are logged in: az login" -ForegroundColor White
    exit 1
}

# Create dashboard templates
Write-Host "2. Creating dashboard templates..." -ForegroundColor Yellow

# Business Metrics Dashboard
$businessDashboard = @{
    "properties" = @{
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
            }
        }
    }
    "location" = $Location
    "tags" = @{
        "Application" = "Cody2Zoho"
        "Environment" = "Production"
        "DashboardType" = "BusinessMetrics"
    }
}

# Performance Dashboard
$performanceDashboard = @{
    "properties" = @{
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
                                    "Query" = "customEvents | where timestamp >= ago(24h) | where customDimensions.eventName == 'api_call' | summarize AvgResponseTime = avg(customDimensions.response_time_ms) by bin(timestamp, 1h) | order by timestamp desc"
                                    "PartTitle" = "API Response Time (Last 24h)"
                                    "PartSubTitle" = "Average API response time in milliseconds"
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
                                    "Query" = "exceptions | where timestamp >= ago(24h) | summarize ErrorCount = count() by bin(timestamp, 1h) | order by timestamp desc"
                                    "PartTitle" = "Error Rate (Last 24h)"
                                    "PartSubTitle" = "Number of exceptions per hour"
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
            }
        }
    }
    "location" = $Location
    "tags" = @{
        "Application" = "Cody2Zoho"
        "Environment" = "Production"
        "DashboardType" = "Performance"
    }
}

# Operations Dashboard
$operationsDashboard = @{
    "properties" = @{
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
                                    "Query" = "customEvents | where timestamp >= ago(24h) | where customDimensions.eventName == 'polling_cycle_completed' | summarize PollingCycles = count() by bin(timestamp, 1h) | order by timestamp desc"
                                    "PartTitle" = "Polling Cycles (Last 24h)"
                                    "PartSubTitle" = "Number of polling cycles completed per hour"
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
                                    "Query" = "customEvents | where timestamp >= ago(24h) | where customDimensions.eventName == 'rate_limit_hit' | summarize RateLimitHits = count() by bin(timestamp, 1h) | order by timestamp desc"
                                    "PartTitle" = "Rate Limit Hits (Last 24h)"
                                    "PartSubTitle" = "Number of API rate limit hits per hour"
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
            }
        }
    }
    "location" = $Location
    "tags" = @{
        "Application" = "Cody2Zoho"
        "Environment" = "Production"
        "DashboardType" = "Operations"
    }
}

Write-Host "   Dashboard templates created" -ForegroundColor Green

# Function to create dashboard via REST API
function Create-Dashboard {
    param(
        [string]$DashboardName,
        [object]$DashboardData
    )
    
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Portal/dashboards/$DashboardName`?api-version=2020-09-01-preview"
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $body = $DashboardData | ConvertTo-Json -Depth 10
    
    Write-Host "   Creating $DashboardName..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers -Body $body
        Write-Host "   $DashboardName created successfully!" -ForegroundColor Green
        return $response
    } catch {
        Write-Host "   ERROR creating $DashboardName`: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            $errorResponse = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorResponse)
            $errorBody = $reader.ReadToEnd()
            Write-Host "   Error details: $errorBody" -ForegroundColor Red
        }
        return $null
    }
}

# Create dashboards
Write-Host "3. Creating dashboards via REST API..." -ForegroundColor Yellow

$dashboards = @(
    @{ Name = "cody2zoho-business-metrics"; Data = $businessDashboard },
    @{ Name = "cody2zoho-performance"; Data = $performanceDashboard },
    @{ Name = "cody2zoho-operations"; Data = $operationsDashboard }
)

$successCount = 0
foreach ($dashboard in $dashboards) {
    $result = Create-Dashboard -DashboardName $dashboard.Name -DashboardData $dashboard.Data
    if ($result) {
        $successCount++
    }
}

Write-Host ""
Write-Host "=== Dashboard Creation Complete ===" -ForegroundColor Green
Write-Host "Successfully created $successCount out of $($dashboards.Count) dashboards" -ForegroundColor White
Write-Host ""
Write-Host "Dashboard URLs:" -ForegroundColor Cyan
Write-Host "Business Metrics: {AZURE APPLICATION INSIGHTS URL}/cody2zoho-business-metrics" -ForegroundColor White
Write-Host "Performance: {AZURE APPLICATION INSIGHTS URL}/cody2zoho-performance" -ForegroundColor White
Write-Host "Operations: {AZURE APPLICATION INSIGHTS URL}/cody2zoho-operations" -ForegroundColor White
Write-Host ""
Write-Host "If dashboards were not created successfully, you can:" -ForegroundColor Yellow
Write-Host "   1. Check the error messages above" -ForegroundColor White
Write-Host "   2. Verify your Azure permissions" -ForegroundColor White
Write-Host "   3. Try creating dashboards manually in the Azure Portal" -ForegroundColor White
Write-Host "   4. Use the Application Insights Logs (Analytics) section for queries" -ForegroundColor White
