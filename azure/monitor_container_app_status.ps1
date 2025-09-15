#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Retrieve logs and metrics from the running Cody2Zoho Azure container

.DESCRIPTION
    This script provides comprehensive monitoring of the Cody2Zoho application
    running in Azure Container Instances. It can retrieve:
    - Container logs
    - Application metrics
    - Health status
    - Container information
    - Performance statistics

.PARAMETER Action
    The action to perform:
    - logs: Get container logs
    - metrics: Get application metrics
    - health: Check health endpoint
    - status: Get container status
    - all: Get all information
    - monitor: Continuous monitoring mode

.PARAMETER Lines
    Number of log lines to retrieve (default: 50)

.PARAMETER Follow
    Follow logs in real-time (continuous output)

.PARAMETER ResourceGroup
    Azure resource group name (default: {AZURE RESOURCE GROUP})

.PARAMETER ContainerName
    Container name (default: zohocodychat-aci)

.EXAMPLE
    .\get_container_status.ps1 -Action logs
    Get the latest container logs

.EXAMPLE
    .\get_container_status.ps1 -Action metrics
    Get current application metrics

.EXAMPLE
    .\get_container_status.ps1 -Action all
    Get comprehensive status information

.EXAMPLE
    .\get_container_status.ps1 -Action monitor
    Start continuous monitoring mode

.NOTES
    Requires Azure CLI to be installed and authenticated
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("logs", "metrics", "health", "status", "all", "monitor")]
    [string]$Action = "all",
    
    [Parameter(Mandatory=$false)]
    [int]$Lines = 50,
    
    [Parameter(Mandatory=$false)]
    [switch]$Follow,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "{AZURE RESOURCE GROUP}",
    
    [Parameter(Mandatory=$false)]
    [string]$ContainerName = "zohocodychat-aci"
)

# Colors for output
$Colors = @{
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "Cyan"
    Header = "Magenta"
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    if ($Colors.ContainsKey($Color)) {
        Write-Host $Message -ForegroundColor $Colors[$Color]
    } else {
        Write-Host $Message
    }
}

function Write-Header {
    param([string]$Title)
    Write-ColorOutput "`n" + "=" * 60 $Colors.Header
    Write-ColorOutput " $Title" $Colors.Header
    Write-ColorOutput "=" * 60 $Colors.Header
}

function Get-ContainerStatus {
    Write-Header "Container Status"
    
    try {
        $status = az container show --resource-group $ResourceGroup --name $ContainerName --output json | ConvertFrom-Json
        
        Write-ColorOutput "Container Name: $($status.name)" $Colors.Info
        Write-ColorOutput "Resource Group: $($status.id.Split('/')[4])" $Colors.Info
        Write-ColorOutput "Location: $($status.location)" $Colors.Info
        Write-ColorOutput "Provisioning State: $($status.provisioningState)" $Colors.Info
        Write-ColorOutput "OS Type: $($status.osType)" $Colors.Info
        
        # Container instance status
        if ($status.containers) {
            $container = $status.containers[0]
            Write-ColorOutput "Container Status: $($container.instanceView.currentState.state)" $Colors.Info
            Write-ColorOutput "Restart Count: $($container.instanceView.currentState.restartCount)" $Colors.Info
            Write-ColorOutput "Started At: $($container.instanceView.currentState.startTime)" $Colors.Info
        }
        
        # IP Address
        if ($status.ipAddress) {
            Write-ColorOutput "Public IP: $($status.ipAddress.ip)" $Colors.Info
            Write-ColorOutput "FQDN: $($status.ipAddress.fqdn)" $Colors.Info
            foreach ($port in $status.ipAddress.ports) {
                Write-ColorOutput "Port $($port.port): $($port.protocol)" $Colors.Info
            }
        }
        
        return $true
    }
    catch {
        Write-ColorOutput "Error getting container status: $($_.Exception.Message)" $Colors.Error
        return $false
    }
}

function Get-ContainerLogs {
    Write-Header "Container Logs"
    
    try {
        if ($Follow) {
            Write-ColorOutput "Following logs in real-time (Press Ctrl+C to stop)..." $Colors.Info
            Write-ColorOutput "Note: Use 'az container logs --resource-group $ResourceGroup --name $ContainerName --follow' directly for real-time logs" $Colors.Warning
                } else {
            Write-ColorOutput "Retrieving last $Lines log lines..." $Colors.Info
            
            # Handle Azure CLI Unicode encoding issues gracefully
            Write-ColorOutput "Note: Azure CLI has known Unicode encoding issues with certain characters." $Colors.Info
            Write-ColorOutput "For the best log viewing experience, use the Azure CLI command directly:" $Colors.Info
            Write-ColorOutput "az container logs --resource-group $ResourceGroup --name $ContainerName" $Colors.Info
            Write-ColorOutput ""
            Write-ColorOutput "Recent log summary:" $Colors.Header
            
            # Check if container is running first
            try {
                $containerStatus = az container show --resource-group $ResourceGroup --name $ContainerName --query "containers[0].instanceView.currentState.state" --output tsv 2>$null
                if ($containerStatus -eq "Running") {
                    Write-ColorOutput "Container Status: Running" $Colors.Success
                    Write-ColorOutput "Logs are available but may have encoding issues when retrieved through this script." $Colors.Info
                    Write-ColorOutput ""
                    Write-ColorOutput "Recommended commands for log access:" $Colors.Header
                    Write-ColorOutput "• View all logs: az container logs --resource-group $ResourceGroup --name $ContainerName" $Colors.Info
                    Write-ColorOutput "• View last $Lines lines: az container logs --resource-group $ResourceGroup --name $ContainerName | Select-Object -Last $Lines" $Colors.Info
                    Write-ColorOutput "• Follow logs: az container logs --resource-group $ResourceGroup --name $ContainerName --follow" $Colors.Info
                } else {
                    Write-ColorOutput "Container Status: $containerStatus" $Colors.Warning
                    Write-ColorOutput "Container is not running, so no logs are available." $Colors.Warning
                }
            } catch {
                Write-ColorOutput "Unable to check container status." $Colors.Warning
                Write-ColorOutput "Please use the Azure CLI command directly for log access." $Colors.Info
            }
        }
        return $true
    }
    catch {
        Write-ColorOutput "Error getting container logs: $($_.Exception.Message)" $Colors.Error
        return $false
    }
}

function Get-ApplicationMetrics {
    Write-Header "Application Metrics"
    
    try {
        # Get container info to find the FQDN
        $containerInfo = az container show --resource-group $ResourceGroup --name $ContainerName --output json | ConvertFrom-Json
        $fqdn = $containerInfo.ipAddress.fqdn
        
        if (-not $fqdn) {
            Write-ColorOutput "Could not determine container FQDN" $Colors.Error
            return $false
        }
        
        $metricsUrl = "http://${fqdn}:8080/metrics"
        Write-ColorOutput "Fetching metrics from: $metricsUrl" $Colors.Info
        
        $response = Invoke-WebRequest -Uri $metricsUrl -UseBasicParsing -TimeoutSec 10
        $metrics = $response.Content | ConvertFrom-Json
        
        # Display metrics in a formatted way
        Write-ColorOutput "Application Status:" $Colors.Header
        Write-ColorOutput "  Status: $($metrics.application.status)" $Colors.Info
        Write-ColorOutput "  Polling Active: $($metrics.application.polling_active)" $Colors.Info
        Write-ColorOutput "  Uptime: $([math]::Round($metrics.application.uptime_seconds / 60, 2)) minutes" $Colors.Info
        
        Write-ColorOutput "`nConversation Processing:" $Colors.Header
        Write-ColorOutput "  Total Processed: $($metrics.conversations.total_processed)" $Colors.Info
        Write-ColorOutput "  Cases Created: $($metrics.conversations.cases_created)" $Colors.Info
        Write-ColorOutput "  Total Skipped: $($metrics.conversations.total_skipped)" $Colors.Info
        Write-ColorOutput "  Total Errors: $($metrics.conversations.total_errors)" $Colors.Info
        Write-ColorOutput "  Processing Rate: $($metrics.conversations.processing_rate_per_hour) conversations/hour" $Colors.Info
        
        if ($metrics.conversations.last_case_created) {
            $lastCaseTime = [DateTimeOffset]::FromUnixTimeSeconds($metrics.conversations.last_case_created).DateTime
            Write-ColorOutput "  Last Case Created: $lastCaseTime" $Colors.Info
        }
        
        Write-ColorOutput "`nToken Management:" $Colors.Header
        Write-ColorOutput "  Refresh Attempts: $($metrics.tokens.refresh_attempts)" $Colors.Info
        Write-ColorOutput "  Refresh Successes: $($metrics.tokens.refresh_successes)" $Colors.Info
        Write-ColorOutput "  Refresh Failures: $($metrics.tokens.refresh_failures)" $Colors.Info
        Write-ColorOutput "  Success Rate: $($metrics.tokens.success_rate)%" $Colors.Info
        Write-ColorOutput "  Rate Limit Hits: $($metrics.tokens.rate_limit_hits)" $Colors.Info
        
        if ($metrics.tokens.token_cache.has_cached_token) {
            $expiresAt = [DateTimeOffset]::FromUnixTimeSeconds($metrics.tokens.token_cache.expires_at).DateTime
            Write-ColorOutput "  Token Expires: $expiresAt" $Colors.Info
        }
        
        Write-ColorOutput "`nTimestamp: $([DateTimeOffset]::FromUnixTimeSeconds($metrics.timestamp).DateTime)" $Colors.Info
        
        return $true
    }
    catch {
        Write-ColorOutput "Error getting application metrics: $($_.Exception.Message)" $Colors.Error
        return $false
    }
}

function Test-HealthEndpoint {
    Write-Header "Health Check"
    
    try {
        # Get container info to find the FQDN
        $containerInfo = az container show --resource-group $ResourceGroup --name $ContainerName --output json | ConvertFrom-Json
        $fqdn = $containerInfo.ipAddress.fqdn
        
        if (-not $fqdn) {
            Write-ColorOutput "Could not determine container FQDN" $Colors.Error
            return $false
        }
        
        $healthUrl = "http://${fqdn}:8080/health"
        Write-ColorOutput "Testing health endpoint: $healthUrl" $Colors.Info
        
        $response = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 10
        
        if ($response.StatusCode -eq 200) {
            Write-ColorOutput "Health check passed - Status: $($response.StatusCode)" $Colors.Success
            $health = $response.Content | ConvertFrom-Json
            Write-ColorOutput "Status: $($health.status)" $Colors.Info
            Write-ColorOutput "Timestamp: $($health.timestamp)" $Colors.Info
        } else {
            Write-ColorOutput "Health check failed - Status: $($response.StatusCode)" $Colors.Error
        }
        
        return $true
    }
    catch {
        Write-ColorOutput "Error testing health endpoint: $($_.Exception.Message)" $Colors.Error
        return $false
    }
}

function Start-MonitoringMode {
    Write-Header "Continuous Monitoring Mode"
    Write-ColorOutput "Starting continuous monitoring (Press Ctrl+C to stop)..." $Colors.Info
    Write-ColorOutput "Monitoring interval: 30 seconds" $Colors.Info
    
    try {
        while ($true) {
            Clear-Host
            Write-Header "Cody2Zoho Container Monitor - $(Get-Date)"
            
            # Get all status information
            Get-ContainerStatus | Out-Null
            Get-ApplicationMetrics | Out-Null
            Test-HealthEndpoint | Out-Null
            
            Write-ColorOutput "`nNext update in 30 seconds..." $Colors.Info
            Start-Sleep -Seconds 30
        }
    }
    catch {
        Write-ColorOutput "`nMonitoring stopped." $Colors.Warning
    }
}

# Main execution
Write-Header "Cody2Zoho Container Status Tool"

# Check if Azure CLI is available
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-ColorOutput "Azure CLI Version: $($azVersion.'azure-cli')" $Colors.Info
} catch {
    Write-ColorOutput "Azure CLI not found. Please install Azure CLI first." $Colors.Error
    exit 1
}

# Check if logged in to Azure
try {
    $account = az account show --output json | ConvertFrom-Json
    Write-ColorOutput "Azure Account: $($account.user.name)" $Colors.Info
    Write-ColorOutput "Subscription: $($account.name)" $Colors.Info
} catch {
    Write-ColorOutput "Not logged in to Azure. Please run 'az login' first." $Colors.Error
    exit 1
}

# Execute requested action
switch ($Action.ToLower()) {
    "logs" {
        Get-ContainerLogs
    }
    "metrics" {
        Get-ApplicationMetrics
    }
    "health" {
        Test-HealthEndpoint
    }
    "status" {
        Get-ContainerStatus
    }
    "monitor" {
        Start-MonitoringMode
    }
    "all" {
        Get-ContainerStatus
        Get-ApplicationMetrics
        Test-HealthEndpoint
        Get-ContainerLogs
    }
}

Write-ColorOutput "`nStatus check completed." $Colors.Success
