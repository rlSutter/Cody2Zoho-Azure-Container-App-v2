#!/usr/bin/env pwsh

# Azure Redis Cache Management Script for Cody2Zoho
# This script provides comprehensive management of Azure Redis Cache independently of the main application

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("status", "start", "stop", "restart", "info", "keys", "flush", "backup", "restore", "monitor")]
    [string]$Action = "status",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "ASEV-OpenAI",
    
    [Parameter(Mandatory=$false)]
    [string]$RedisName = "cody2zoho-redis",
    
    [Parameter(Mandatory=$false)]
    [string]$BackupPath = "./redis_backup",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

Write-Host "=== Azure Redis Cache Management ===" -ForegroundColor Cyan
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

# Function to get Redis status
function Get-RedisStatus {
    param([string]$Name, [string]$ResourceGroup)
    
    try {
        $redis = az redis show --name $Name --resource-group $ResourceGroup --output json | ConvertFrom-Json
        return $redis
    } catch {
        Write-Host "Failed to get Redis status: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Function to get Redis connection details
function Get-RedisConnectionInfo {
    param([string]$Name, [string]$ResourceGroup)
    
    try {
        $redis = Get-RedisStatus -Name $Name -ResourceGroup $ResourceGroup
        if ($redis) {
            $connectionString = $redis.hostName + ":6380,password=" + $redis.accessKeys.primaryKey + ",ssl=True"
            return @{
                HostName = $redis.hostName
                Port = 6380
                PrimaryKey = $redis.accessKeys.primaryKey
                SecondaryKey = $redis.accessKeys.secondaryKey
                ConnectionString = $connectionString
                SSL = $true
            }
        }
    } catch {
        Write-Host "Failed to get connection info: $($_.Exception.Message)" -ForegroundColor Red
    }
    return $null
}

# Function to start Redis
function Start-Redis {
    param([string]$Name, [string]$ResourceGroup)
    
    Write-Host "Starting Redis instance..." -ForegroundColor Yellow
    try {
        az redis start --name $Name --resource-group $ResourceGroup --output none
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Redis instance started successfully" -ForegroundColor Green
            Start-Sleep -Seconds 10
            Get-RedisStatus -Name $Name -ResourceGroup $ResourceGroup
        } else {
            Write-Host "Failed to start Redis instance" -ForegroundColor Red
        }
    } catch {
        Write-Host "Error starting Redis: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to stop Redis
function Stop-Redis {
    param([string]$Name, [string]$ResourceGroup, [bool]$Force)
    
    if (-not $Force) {
        $confirm = Read-Host "Are you sure you want to stop the Redis instance? This will affect the Cody2Zoho application. (y/N)"
        if ($confirm -notmatch "^(y|yes)$") {
            Write-Host "Operation cancelled" -ForegroundColor Yellow
            return
        }
    }
    
    Write-Host "Stopping Redis instance..." -ForegroundColor Yellow
    try {
        az redis stop --name $Name --resource-group $ResourceGroup --output none
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Redis instance stopped successfully" -ForegroundColor Green
        } else {
            Write-Host "Failed to stop Redis instance" -ForegroundColor Red
        }
    } catch {
        Write-Host "Error stopping Redis: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to restart Redis
function Restart-Redis {
    param([string]$Name, [string]$ResourceGroup)
    
    Write-Host "Restarting Redis instance..." -ForegroundColor Yellow
    Stop-Redis -Name $Name -ResourceGroup $ResourceGroup -Force $true
    Start-Sleep -Seconds 5
    Start-Redis -Name $Name -ResourceGroup $ResourceGroup
}

# Function to display Redis information
function Show-RedisInfo {
    param([string]$Name, [string]$ResourceGroup)
    
    $redis = Get-RedisStatus -Name $Name -ResourceGroup $ResourceGroup
    if ($redis) {
        Write-Host "=== Redis Instance Information ===" -ForegroundColor Cyan
        Write-Host "Name: $($redis.name)" -ForegroundColor White
        Write-Host "Resource Group: $($redis.resourceGroup)" -ForegroundColor White
        Write-Host "Location: $($redis.location)" -ForegroundColor White
        Write-Host "SKU: $($redis.sku.name) - $($redis.sku.family) - $($redis.sku.capacity)" -ForegroundColor White
        Write-Host "Version: $($redis.redisVersion)" -ForegroundColor White
        Write-Host "Provisioning State: $($redis.provisioningState)" -ForegroundColor White
        Write-Host "Host Name: $($redis.hostName)" -ForegroundColor White
        Write-Host "Port: 6380 (SSL)" -ForegroundColor White
        Write-Host "SSL Enabled: $($redis.enableNonSslPort)" -ForegroundColor White
        Write-Host "Max Memory Policy: $($redis.maxMemoryPolicy)" -ForegroundColor White
        
        $connectionInfo = Get-RedisConnectionInfo -Name $Name -ResourceGroup $ResourceGroup
        if ($connectionInfo) {
            Write-Host ""
            Write-Host "=== Connection Information ===" -ForegroundColor Cyan
            Write-Host "Connection String: $($connectionInfo.ConnectionString)" -ForegroundColor White
            Write-Host "Primary Key: $($connectionInfo.PrimaryKey.Substring(0, 10))..." -ForegroundColor White
        }
    }
}

# Function to list Redis keys
function Get-RedisKeys {
    param([string]$Name, [string]$ResourceGroup)
    
    Write-Host "Connecting to Redis to list keys..." -ForegroundColor Yellow
    $connectionInfo = Get-RedisConnectionInfo -Name $Name -ResourceGroup $ResourceGroup
    if ($connectionInfo) {
        try {
            # Use redis-cli if available, otherwise show connection info
            $redisCli = Get-Command redis-cli -ErrorAction SilentlyContinue
            if ($redisCli) {
                Write-Host "Using redis-cli to connect..." -ForegroundColor Yellow
                $keys = redis-cli -h $connectionInfo.HostName -p $connectionInfo.Port -a $connectionInfo.PrimaryKey --tls keys "*"
                if ($keys) {
                    Write-Host "=== Redis Keys ===" -ForegroundColor Cyan
                    $keys | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
                } else {
                    Write-Host "No keys found in Redis" -ForegroundColor Yellow
                }
            } else {
                Write-Host "redis-cli not found. Connection details:" -ForegroundColor Yellow
                Write-Host "Host: $($connectionInfo.HostName)" -ForegroundColor White
                Write-Host "Port: $($connectionInfo.Port)" -ForegroundColor White
                Write-Host "Password: $($connectionInfo.PrimaryKey.Substring(0, 10))..." -ForegroundColor White
                Write-Host "SSL: Enabled" -ForegroundColor White
            }
        } catch {
            Write-Host "Failed to connect to Redis: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Function to flush Redis data
function Clear-RedisData {
    param([string]$Name, [string]$ResourceGroup, [bool]$Force)
    
    if (-not $Force) {
        Write-Host "WARNING: This will delete ALL data in the Redis instance!" -ForegroundColor Red
        $confirm = Read-Host "Are you absolutely sure? Type 'DELETE ALL DATA' to confirm"
        if ($confirm -ne "DELETE ALL DATA") {
            Write-Host "Operation cancelled" -ForegroundColor Yellow
            return
        }
    }
    
    Write-Host "Flushing Redis data..." -ForegroundColor Yellow
    $connectionInfo = Get-RedisConnectionInfo -Name $Name -ResourceGroup $ResourceGroup
    if ($connectionInfo) {
        try {
            $redisCli = Get-Command redis-cli -ErrorAction SilentlyContinue
            if ($redisCli) {
                redis-cli -h $connectionInfo.HostName -p $connectionInfo.Port -a $connectionInfo.PrimaryKey --tls flushall
                Write-Host "Redis data flushed successfully" -ForegroundColor Green
            } else {
                Write-Host "redis-cli not found. Cannot flush data." -ForegroundColor Red
            }
        } catch {
            Write-Host "Failed to flush Redis data: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Function to backup Redis data
function Backup-RedisData {
    param([string]$Name, [string]$ResourceGroup, [string]$BackupPath)
    
    Write-Host "Creating Redis backup..." -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = Join-Path $BackupPath "redis_backup_$timestamp.rdb"
    
    try {
        # Create backup directory if it doesn't exist
        if (-not (Test-Path $BackupPath)) {
            New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
        }
        
        # Note: Azure Redis Cache doesn't support direct backup via redis-cli
        # This would need to be done through Azure backup services
        Write-Host "Note: Azure Redis Cache backup requires Azure backup services" -ForegroundColor Yellow
        Write-Host "For production backups, use Azure Redis Cache backup features" -ForegroundColor Yellow
        
        # Create a metadata file with connection info
        $connectionInfo = Get-RedisConnectionInfo -Name $Name -ResourceGroup $ResourceGroup
        $metadata = @{
            Timestamp = $timestamp
            RedisName = $Name
            ResourceGroup = $ResourceGroup
            HostName = $connectionInfo.HostName
            BackupType = "metadata_only"
        } | ConvertTo-Json
        
        $metadataFile = Join-Path $BackupPath "redis_metadata_$timestamp.json"
        $metadata | Out-File -FilePath $metadataFile -Encoding UTF8
        
        Write-Host "Backup metadata saved to: $metadataFile" -ForegroundColor Green
        Write-Host "For full backup, use Azure portal or Azure CLI backup commands" -ForegroundColor Yellow
        
    } catch {
        Write-Host "Failed to create backup: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to monitor Redis
function Monitor-Redis {
    param([string]$Name, [string]$ResourceGroup)
    
    Write-Host "Starting Redis monitoring (Press Ctrl+C to stop)..." -ForegroundColor Yellow
    $connectionInfo = Get-RedisConnectionInfo -Name $Name -ResourceGroup $ResourceGroup
    if ($connectionInfo) {
        try {
            $redisCli = Get-Command redis-cli -ErrorAction SilentlyContinue
            if ($redisCli) {
                Write-Host "Monitoring Redis commands..." -ForegroundColor Cyan
                redis-cli -h $connectionInfo.HostName -p $connectionInfo.Port -a $connectionInfo.PrimaryKey --tls monitor
            } else {
                Write-Host "redis-cli not found. Cannot monitor Redis." -ForegroundColor Red
                Write-Host "Connection details for manual monitoring:" -ForegroundColor Yellow
                Write-Host "Host: $($connectionInfo.HostName)" -ForegroundColor White
                Write-Host "Port: $($connectionInfo.Port)" -ForegroundColor White
                Write-Host "Password: $($connectionInfo.PrimaryKey.Substring(0, 10))..." -ForegroundColor White
            }
        } catch {
            Write-Host "Failed to monitor Redis: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Main execution
if (-not (Test-AzureLogin)) {
    exit 1
}

if (-not (Test-RedisExists -Name $RedisName -ResourceGroup $ResourceGroup)) {
    Write-Host "Redis instance '$RedisName' not found in resource group '$ResourceGroup'" -ForegroundColor Red
    Write-Host "Available Redis instances:" -ForegroundColor Yellow
    try {
        az redis list --resource-group $ResourceGroup --output table
    } catch {
        Write-Host "Failed to list Redis instances" -ForegroundColor Red
    }
    exit 1
}

switch ($Action) {
    "status" {
        Show-RedisInfo -Name $RedisName -ResourceGroup $ResourceGroup
    }
    "start" {
        Start-Redis -Name $RedisName -ResourceGroup $ResourceGroup
    }
    "stop" {
        Stop-Redis -Name $RedisName -ResourceGroup $ResourceGroup -Force $Force
    }
    "restart" {
        Restart-Redis -Name $RedisName -ResourceGroup $ResourceGroup
    }
    "info" {
        Show-RedisInfo -Name $RedisName -ResourceGroup $ResourceGroup
    }
    "keys" {
        Get-RedisKeys -Name $RedisName -ResourceGroup $ResourceGroup
    }
    "flush" {
        Clear-RedisData -Name $RedisName -ResourceGroup $ResourceGroup -Force $Force
    }
    "backup" {
        Backup-RedisData -Name $RedisName -ResourceGroup $ResourceGroup -BackupPath $BackupPath
    }
    "monitor" {
        Monitor-Redis -Name $RedisName -ResourceGroup $ResourceGroup
    }
    default {
        Write-Host "Unknown action: $Action" -ForegroundColor Red
        Write-Host "Available actions: status, start, stop, restart, info, keys, flush, backup, monitor" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""
Write-Host "Operation completed successfully!" -ForegroundColor Green
