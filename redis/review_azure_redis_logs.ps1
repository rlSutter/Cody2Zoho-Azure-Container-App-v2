#!/usr/bin/env pwsh

# Azure Redis Cache Log Review and Management Script
# This script provides comprehensive log review and management for Azure Redis Cache

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("logs", "metrics", "alerts", "diagnostics", "export", "monitor")]
    [string]$Action = "logs",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "ASEV-OpenAI",
    
    [Parameter(Mandatory=$false)]
    [string]$RedisName = "cody2zoho-redis",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "./redis_logs",
    
    [Parameter(Mandatory=$false)]
    [int]$Hours = 24,
    
    [Parameter(Mandatory=$false)]
    [switch]$Follow
)

Write-Host "=== Azure Redis Cache Log Review ===" -ForegroundColor Cyan
Write-Host "Action: $Action" -ForegroundColor White
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "Redis Name: $RedisName" -ForegroundColor White
Write-Host "Time Range: Last $Hours hours" -ForegroundColor White
Write-Host ""

# Function to check Azure CLI and login status
function Test-AzureLogin {
    Write-Host "Checking Azure CLI status..." -ForegroundColor Yellow
    try {
        $account = az account show --output json 2>$null | ConvertFrom-Json
        if ($account) {
            Write-Host "Logged in as: $($account.user.name)" -ForegroundColor Green
            Write-Host "   Subscription: $($account.name)" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "Not logged into Azure CLI" -ForegroundColor Red
        Write-Host "Please run: az login" -ForegroundColor Yellow
        return $false
    }
}

# Function to check if Redis instance exists
function Test-RedisExists {
    param([string]$Name, [string]$ResourceGroup)
    
    try {
        $redis = az redis show --name $Name --resource-group $ResourceGroup --output json 2>$null | ConvertFrom-Json
        return $redis -ne $null
    } catch {
        return $false
    }
}

# Function to get Redis logs
function Get-RedisLogs {
    param([string]$Name, [string]$ResourceGroup, [int]$Hours, [string]$OutputPath)
    
    Write-Host "Retrieving Redis logs..." -ForegroundColor Yellow
    
    try {
        # Handle null output path for monitoring mode
        $logFile = $null
        if ($OutputPath -and $OutputPath -ne "") {
            # Create output directory if it doesn't exist
            if (-not (Test-Path $OutputPath)) {
                New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
            }
            
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $logFile = Join-Path $OutputPath "redis_logs_$timestamp.txt"
        }
        
        # Get Redis resource ID
        $redis = az redis show --name $Name --resource-group $ResourceGroup --output json | ConvertFrom-Json
        $resourceId = $redis.id
        
        Write-Host "Resource ID: $resourceId" -ForegroundColor Gray
        
        # Query logs using Azure Monitor
        $startTime = (Get-Date).AddHours(-$Hours).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $endTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        
        Write-Host "Querying logs from $startTime to $endTime..." -ForegroundColor Yellow
        
        # Azure Monitor query for Redis logs
        $query = @"
AzureDiagnostics
| where ResourceId == '$resourceId'
| where TimeGenerated >= datetime('$startTime') and TimeGenerated <= datetime('$endTime')
| order by TimeGenerated desc
| project TimeGenerated, Category, OperationName, ResultType, ResultDescription, DurationMs, CallerIpAddress, ClientIP, UserAgent
"@
        
         Write-Host "Executing log query..." -ForegroundColor Yellow
         
         # Try to get logs using Azure Monitor metrics instead of Log Analytics
         # Azure Redis Cache doesn't have a direct workspaceId, so we'll use activity logs
         $logs = az monitor activity-log list --resource-id $resourceId --start-time $startTime --output json 2>$null | ConvertFrom-Json
        
        if ($logs -and $logs.Count -gt 0) {
            Write-Host "Found $($logs.Count) log entries" -ForegroundColor Green
            
            # Write logs to file if output path is specified
            $logContent = @()
            $logContent += "=== Azure Redis Cache Activity Logs ==="
            $logContent += "Redis Name: $Name"
            $logContent += "Resource Group: $ResourceGroup"
            $logContent += "Time Range: $startTime to $endTime"
            $logContent += "Total Entries: $($logs.Count)"
            $logContent += ""
            
            foreach ($logEntry in $logs) {
                $logContent += "Time: $($logEntry.eventTimestamp)"
                $logContent += "Operation: $($logEntry.operationName.value)"
                $logContent += "Status: $($logEntry.status.value)"
                $logContent += "Caller: $($logEntry.caller)"
                $logContent += "Description: $($logEntry.description)"
                $logContent += "---"
            }
            
            if ($logFile) {
                $logContent | Out-File -FilePath $logFile -Encoding UTF8
                Write-Host "Logs saved to: $logFile" -ForegroundColor Green
            }
            
            # Display recent logs
            Write-Host ""
            Write-Host "=== Recent Log Entries ===" -ForegroundColor Cyan
            $recentLogs = $logs | Select-Object -First 10
            foreach ($logEntry in $recentLogs) {
                Write-Host "$($logEntry.eventTimestamp) - $($logEntry.operationName.value) - $($logEntry.status.value)" -ForegroundColor White
            }
            
        } else {
            Write-Host " No logs found for the specified time range" -ForegroundColor Yellow
            Write-Host "This could mean:" -ForegroundColor Yellow
            Write-Host "  - No activity in the time range" -ForegroundColor Yellow
            Write-Host "  - Logging is not enabled (Basic tier doesn't support diagnostic logging)" -ForegroundColor Yellow
            Write-Host "  - Redis instance needs to be Standard tier or higher for logging" -ForegroundColor Yellow
            Write-Host "  - Different log category" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "To enable logging:" -ForegroundColor Cyan
            Write-Host "  1. Upgrade Redis to Standard tier: az redis update --name $Name --resource-group $ResourceGroup --sku Standard" -ForegroundColor White
            Write-Host "  2. Create diagnostic settings with Log Analytics workspace" -ForegroundColor White
            Write-Host "  3. Use 'metrics' action for immediate performance data" -ForegroundColor White
        }
        
    } catch {
        Write-Host "Failed to retrieve logs: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Trying alternative method..." -ForegroundColor Yellow
        
         # Alternative: Try to get metrics instead of logs
         try {
             Write-Host "Trying to get Redis metrics as alternative..." -ForegroundColor Yellow
             $metrics = az monitor metrics list --resource $resourceId --metric "connectedclients" --start-time $startTime --end-time $endTime --output json 2>$null | ConvertFrom-Json
             
             if ($metrics -and $metrics.value) {
                 Write-Host "Found metrics data (alternative method)" -ForegroundColor Green
                 Write-Host "Note: Azure Redis Cache logs are limited. Use metrics for performance monitoring." -ForegroundColor Yellow
             }
         } catch {
             Write-Host "Alternative method also failed: $($_.Exception.Message)" -ForegroundColor Red
         }
    }
}

# Function to get Redis metrics
function Get-RedisMetrics {
    param([string]$Name, [string]$ResourceGroup, [int]$Hours)
    
    Write-Host "Retrieving Redis metrics..." -ForegroundColor Yellow
    
    try {
        $startTime = (Get-Date).AddHours(-$Hours).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $endTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        
        # Get Redis resource ID
        $redis = az redis show --name $Name --resource-group $ResourceGroup --output json | ConvertFrom-Json
        $resourceId = $redis.id
        
        Write-Host "=== Redis Performance Metrics ===" -ForegroundColor Cyan
        
        # Get metrics using Azure CLI
        $metrics = @(
            "connectedclients",
            "totalcommandsprocessed",
            "cachehits",
            "cachemisses",
            "getcommands",
            "setcommands",
            "evictedkeys",
            "totalkeys",
            "usedmemory",
            "usedmemorypercentage"
        )
        
        foreach ($metric in $metrics) {
            try {
                Write-Host "Getting $metric metric..." -ForegroundColor Yellow
                $metricData = az monitor metrics list --resource $resourceId --metric $metric --start-time $startTime --end-time $endTime --output json | ConvertFrom-Json
                
                if ($metricData.value -and $metricData.value[0].timeseries) {
                    $latestValue = $metricData.value[0].timeseries[0].data[-1]
                    if ($latestValue.average) {
                        Write-Host "  $metric`: $($latestValue.average)" -ForegroundColor White
                    }
                }
            } catch {
                Write-Host "  $metric`: Not available" -ForegroundColor Gray
            }
        }
        
    } catch {
        Write-Host "Failed to retrieve metrics: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to check Redis alerts
function Get-RedisAlerts {
    param([string]$Name, [string]$ResourceGroup)
    
    Write-Host "Checking Redis alerts..." -ForegroundColor Yellow
    
    try {
        $redis = az redis show --name $Name --resource-group $ResourceGroup --output json | ConvertFrom-Json
        $resourceId = $redis.id
        
        # Get alerts for this Redis instance
        $alerts = az monitor activity-log list --resource-id $resourceId --start-time (Get-Date).AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ssZ") --output json | ConvertFrom-Json
        
        if ($alerts -and $alerts.Count -gt 0) {
            Write-Host "=== Recent Alerts ===" -ForegroundColor Cyan
            foreach ($alert in $alerts | Select-Object -First 10) {
                Write-Host "$($alert.eventTimestamp) - $($alert.operationName.value) - $($alert.status.value)" -ForegroundColor White
            }
        } else {
            Write-Host "No recent alerts found" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "Failed to retrieve alerts: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to run diagnostics
function Run-RedisDiagnostics {
    param([string]$Name, [string]$ResourceGroup)
    
    Write-Host "Running Redis diagnostics..." -ForegroundColor Yellow
    
    try {
        $redis = az redis show --name $Name --resource-group $ResourceGroup --output json | ConvertFrom-Json
        
        Write-Host "=== Redis Diagnostics ===" -ForegroundColor Cyan
        Write-Host "Name: $($redis.name)" -ForegroundColor White
        Write-Host "SKU: $($redis.sku.name) - $($redis.sku.family) - $($redis.sku.capacity)" -ForegroundColor White
        Write-Host "Version: $($redis.redisVersion)" -ForegroundColor White
        Write-Host "Provisioning State: $($redis.provisioningState)" -ForegroundColor White
        Write-Host "SSL Port: $($redis.port)" -ForegroundColor White
        Write-Host "Non-SSL Port: $($redis.sslPort)" -ForegroundColor White
        
        # Check connectivity
        Write-Host ""
        Write-Host "=== Connectivity Test ===" -ForegroundColor Cyan
        try {
            $connectionInfo = @{
                HostName = $redis.hostName
                Port = $redis.port
                PrimaryKey = $redis.accessKeys.primaryKey
            }
            
            # Test with redis-cli if available
            $redisCli = Get-Command redis-cli -ErrorAction SilentlyContinue
            if ($redisCli) {
                $pingResult = redis-cli -h $connectionInfo.HostName -p $connectionInfo.Port -a $connectionInfo.PrimaryKey --tls ping 2>$null
                if ($pingResult -eq "PONG") {
                    Write-Host "Redis connectivity test passed" -ForegroundColor Green
                } else {
                    Write-Host "Redis connectivity test failed" -ForegroundColor Red
                }
            } else {
                Write-Host " redis-cli not available for connectivity test" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Connectivity test failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        # Check configuration
        Write-Host ""
        Write-Host "=== Configuration Check ===" -ForegroundColor Cyan
        Write-Host "Max Memory Policy: $($redis.maxMemoryPolicy)" -ForegroundColor White
        Write-Host "Enable Non-SSL Port: $($redis.enableNonSslPort)" -ForegroundColor White
        Write-Host "Minimum TLS Version: $($redis.minimumTlsVersion)" -ForegroundColor White
        
    } catch {
        Write-Host "Failed to run diagnostics: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to export logs
function Export-RedisLogs {
    param([string]$Name, [string]$ResourceGroup, [string]$OutputPath, [int]$Hours)
    
    Write-Host "Exporting Redis logs..." -ForegroundColor Yellow
    
    try {
        # Create output directory
        if (-not (Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }
        
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $exportDir = Join-Path $OutputPath "redis_export_$timestamp"
        New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
        
        # Export logs
        Get-RedisLogs -Name $Name -ResourceGroup $ResourceGroup -Hours $Hours -OutputPath $exportDir
        
        # Export metrics
        $metricsFile = Join-Path $exportDir "metrics.txt"
        Get-RedisMetrics -Name $Name -ResourceGroup $ResourceGroup -Hours $Hours | Out-File -FilePath $metricsFile -Encoding UTF8
        
        # Export diagnostics
        $diagnosticsFile = Join-Path $exportDir "diagnostics.txt"
        Run-RedisDiagnostics -Name $Name -ResourceGroup $ResourceGroup | Out-File -FilePath $diagnosticsFile -Encoding UTF8
        
        Write-Host "Export completed: $exportDir" -ForegroundColor Green
        
    } catch {
        Write-Host "Failed to export logs: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to monitor logs in real-time
function Monitor-RedisLogs {
    param([string]$Name, [string]$ResourceGroup, [bool]$Follow)
    
    Write-Host "Starting real-time log monitoring (Press Ctrl+C to stop)..." -ForegroundColor Yellow
    
    if ($Follow) {
        Write-Host "Monitoring logs in real-time..." -ForegroundColor Cyan
        # This would require a more complex implementation with Azure Monitor streaming
        Write-Host " Real-time monitoring requires Azure Monitor streaming setup" -ForegroundColor Yellow
        Write-Host "For now, showing recent logs every 30 seconds..." -ForegroundColor Yellow
        
        while ($true) {
            Write-Host "`n=== $(Get-Date) ===" -ForegroundColor Cyan
            Get-RedisLogs -Name $Name -ResourceGroup $ResourceGroup -Hours $Hours -OutputPath $null
            Start-Sleep -Seconds 30
        }
    } else {
        Get-RedisLogs -Name $Name -ResourceGroup $ResourceGroup -Hours $Hours -OutputPath $null
    }
}

# Main execution
if (-not (Test-AzureLogin)) {
    exit 1
}

if (-not (Test-RedisExists -Name $RedisName -ResourceGroup $ResourceGroup)) {
    Write-Host "Redis instance '$RedisName' not found in resource group '$ResourceGroup'" -ForegroundColor Red
    exit 1
}

switch ($Action) {
    "logs" {
        Get-RedisLogs -Name $RedisName -ResourceGroup $ResourceGroup -Hours $Hours -OutputPath $OutputPath
    }
    "metrics" {
        Get-RedisMetrics -Name $RedisName -ResourceGroup $ResourceGroup -Hours $Hours
    }
    "alerts" {
        Get-RedisAlerts -Name $RedisName -ResourceGroup $ResourceGroup
    }
    "diagnostics" {
        Run-RedisDiagnostics -Name $RedisName -ResourceGroup $ResourceGroup
    }
    "export" {
        Export-RedisLogs -Name $RedisName -ResourceGroup $ResourceGroup -OutputPath $OutputPath -Hours $Hours
    }
    "monitor" {
        Monitor-RedisLogs -Name $RedisName -ResourceGroup $ResourceGroup -Follow $Follow
    }
    default {
        Write-Host "Unknown action: $Action" -ForegroundColor Red
        Write-Host "Available actions: logs, metrics, alerts, diagnostics, export, monitor" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""
Write-Host "Operation completed successfully!" -ForegroundColor Green
