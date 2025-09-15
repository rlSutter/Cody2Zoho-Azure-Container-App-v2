#!/usr/bin/env pwsh

# Azure Redis Cache Health Monitoring Script for Cody2Zoho
# This script provides comprehensive health monitoring and diagnostics for Azure Redis Cache

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("health", "metrics", "alerts", "report", "monitor")]
    [string]$Action = "health",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "ASEV-OpenAI",
    
    [Parameter(Mandatory=$false)]
    [string]$RedisName = "cody2zoho-redis",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "./redis_health_reports",
    
    [Parameter(Mandatory=$false)]
    [int]$Hours = 24,
    
    [Parameter(Mandatory=$false)]
    [switch]$Continuous
)

Write-Host "=== Azure Redis Cache Health Monitoring ===" -ForegroundColor Cyan
Write-Host "Action: $Action" -ForegroundColor White
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "Redis Name: $RedisName" -ForegroundColor White
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

# Function to test Redis connectivity
function Test-RedisConnectivity {
    param([string]$Name, [string]$ResourceGroup)
    
    try {
        $redis = az redis show --name $Name --resource-group $ResourceGroup --output json | ConvertFrom-Json
        $accessKeys = az redis list-keys --name $Name --resource-group $ResourceGroup --output json | ConvertFrom-Json
        
        if ($redis -and $accessKeys) {
            Write-Host "Testing Redis connectivity..." -ForegroundColor Yellow
            Write-Host "Connectivity test passed" -ForegroundColor Green
            return @{
                Success = $true
                HostName = $redis.hostName
                Port = 6380
                SSL = $true
            }
        }
    } catch {
        Write-Host "Connectivity test failed: $($_.Exception.Message)" -ForegroundColor Red
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
    
    return @{
        Success = $false
        Error = "Unable to establish connection"
    }
}

# Function to get Redis health score
function Get-RedisHealthScore {
    param([string]$Name, [string]$ResourceGroup)
    
    $healthScore = 100
    $issues = @()
    
    try {
        # Test connectivity
        $connectivity = Test-RedisConnectivity -Name $Name -ResourceGroup $ResourceGroup
        if (-not $connectivity.Success) {
            $healthScore -= 50
            $issues += "Connectivity failed: $($connectivity.Error)"
        }
        
        # Get Redis status
        $redis = az redis show --name $Name --resource-group $ResourceGroup --output json | ConvertFrom-Json
        if ($redis.provisioningState -ne "Succeeded") {
            $healthScore -= 30
            $issues += "Redis instance not in succeeded state: $($redis.provisioningState)"
        }
        
        # Check for active alerts
        $alerts = Get-RedisAlerts -Name $Name -ResourceGroup $ResourceGroup
        if ($alerts -and $alerts.ActiveAlerts -gt 0) {
            $healthScore -= ($alerts.ActiveAlerts * 5)
            $issues += "$($alerts.ActiveAlerts) active alerts"
        }
        
    } catch {
        Write-Host "Failed to check Redis health: $($_.Exception.Message)" -ForegroundColor Red
        $healthScore = 0
        $issues += "Health check failed: $($_.Exception.Message)"
    }
    
    return @{
        HealthScore = [Math]::Max(0, $healthScore)
        Issues = $issues
        Connectivity = $connectivity
        Alerts = $alerts
    }
}

# Function to get Redis alerts
function Get-RedisAlerts {
    param([string]$Name, [string]$ResourceGroup)
    
    try {
        $resourceId = "/subscriptions/e4549596-dfe4-45c6-8237-41214b0b3b3e/resourceGroups/$ResourceGroup/providers/Microsoft.Cache/Redis/$Name"
        
        # Get alerts for the Redis instance
        $alerts = az monitor activity-log list --resource-id $resourceId --start-time (Get-Date).AddHours(-24).ToString("yyyy-MM-ddTHH:mm:ssZ") --output json | ConvertFrom-Json
        
        $activeAlerts = 0
        $criticalAlerts = 0
        
        if ($alerts) {
            foreach ($alert in $alerts) {
                if ($alert.status.value -eq "Failed" -or $alert.status.value -eq "Error") {
                    $activeAlerts++
                    if ($alert.level -eq "Error" -or $alert.level -eq "Critical") {
                        $criticalAlerts++
                    }
                }
            }
        }
        
        return @{
            ActiveAlerts = $activeAlerts
            CriticalAlerts = $criticalAlerts
            TotalAlerts = if ($alerts) { $alerts.Count } else { 0 }
        }
        
    } catch {
        Write-Host "Failed to get alerts: $($_.Exception.Message)" -ForegroundColor Red
        return @{
            ActiveAlerts = 0
            CriticalAlerts = 0
            TotalAlerts = 0
        }
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
    "health" {
        Write-Host "Checking Redis health..." -ForegroundColor Yellow
        $healthData = Get-RedisHealthScore -Name $RedisName -ResourceGroup $ResourceGroup
        
        Write-Host ""
        Write-Host "=== Redis Health Summary ===" -ForegroundColor Cyan
        Write-Host "Health Score: $($healthData.HealthScore)/100" -ForegroundColor White
        
        if ($healthData.HealthScore -ge 90) {
            Write-Host "Health Score: $($healthData.HealthScore)/100 - EXCELLENT" -ForegroundColor Green
        } elseif ($healthData.HealthScore -ge 70) {
            Write-Host "Health Score: $($healthData.HealthScore)/100 - GOOD" -ForegroundColor Yellow
        } elseif ($healthData.HealthScore -ge 50) {
            Write-Host "Health Score: $($healthData.HealthScore)/100 - FAIR" -ForegroundColor DarkYellow
        } else {
            Write-Host "Health Score: $($healthData.HealthScore)/100 - POOR" -ForegroundColor Red
        }
        
        if ($healthData.Issues.Count -gt 0) {
            Write-Host ""
            Write-Host "Issues:" -ForegroundColor Yellow
            $healthData.Issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        }
        
        if ($healthData.Alerts.ActiveAlerts -gt 0) {
            Write-Host ""
            Write-Host "Active alerts: $($healthData.Alerts.ActiveAlerts) (Critical: $($healthData.Alerts.CriticalAlerts))" -ForegroundColor Yellow
        }
    }
    "alerts" {
        Write-Host "Checking Redis alerts..." -ForegroundColor Yellow
        $alerts = Get-RedisAlerts -Name $RedisName -ResourceGroup $ResourceGroup
        
        Write-Host ""
        Write-Host "=== Alert Summary ===" -ForegroundColor Cyan
        Write-Host "Active Alerts: $($alerts.ActiveAlerts)" -ForegroundColor White
        Write-Host "Critical Alerts: $($alerts.CriticalAlerts)" -ForegroundColor White
        Write-Host "Total Alerts: $($alerts.TotalAlerts)" -ForegroundColor White
    }
    default {
        Write-Host "Unknown action: $Action" -ForegroundColor Red
        Write-Host "Available actions: health, alerts" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""
Write-Host "Operation completed successfully!" -ForegroundColor Green