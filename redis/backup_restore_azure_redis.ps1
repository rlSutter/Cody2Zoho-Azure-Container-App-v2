#!/usr/bin/env pwsh

# Azure Redis Cache Backup and Restore Script for Cody2Zoho
# This script provides comprehensive backup and restore functionality for Azure Redis Cache

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("backup", "restore", "list", "delete", "status")]
    [string]$Action = "backup",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "ASEV-OpenAI",
    
    [Parameter(Mandatory=$false)]
    [string]$RedisName = "cody2zoho-redis",
    
    [Parameter(Mandatory=$false)]
    [string]$BackupPath = "./redis_backups",
    
    [Parameter(Mandatory=$false)]
    [string]$BackupName = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

Write-Host "=== Azure Redis Cache Backup and Restore ===" -ForegroundColor Cyan
Write-Host "Action: $Action" -ForegroundColor White
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "Redis Name: $RedisName" -ForegroundColor White
Write-Host "Backup Path: $BackupPath" -ForegroundColor White
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

# Function to create Redis backup
function New-RedisBackup {
    param([string]$Name, [string]$ResourceGroup, [string]$BackupPath)
    
    Write-Host "Creating Redis backup..." -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupName = "redis_backup_$timestamp"
    $backupDir = Join-Path $BackupPath $backupName
    
    try {
        # Create backup directory
        if (-not (Test-Path $BackupPath)) {
            New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
        }
        
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        
        # Get Redis information
        $redis = az redis show --name $Name --resource-group $ResourceGroup --output json | ConvertFrom-Json
        $accessKeys = az redis list-keys --name $Name --resource-group $ResourceGroup --output json | ConvertFrom-Json
        
        # Create metadata backup
        $metadata = @{
            Timestamp = $timestamp
            RedisName = $Name
            ResourceGroup = $ResourceGroup
            HostName = $redis.hostName
            Port = 6380
            SSL = $true
            RedisVersion = $redis.redisVersion
            SKU = $redis.sku
            Location = $redis.location
            BackupType = "metadata_and_connection"
            CreatedBy = "backup_restore_azure_redis.ps1"
        }
        
        $metadataFile = Join-Path $backupDir "metadata.json"
        $metadata | ConvertTo-Json -Depth 5 | Out-File -FilePath $metadataFile -Encoding UTF8
        
        # Create connection info file
        $connectionInfo = @{
            HostName = $redis.hostName
            Port = 6380
            PrimaryKey = $accessKeys.primaryKey
            SecondaryKey = $accessKeys.secondaryKey
            ConnectionString = "$($redis.hostName):6380,password=$($accessKeys.primaryKey),ssl=True"
            SSL = $true
        }
        
        $connectionFile = Join-Path $backupDir "connection.json"
        $connectionInfo | ConvertTo-Json -Depth 5 | Out-File -FilePath $connectionFile -Encoding UTF8
        
        # Try to export Redis data if redis-cli is available
        $redisCli = Get-Command redis-cli -ErrorAction SilentlyContinue
        if ($redisCli) {
            Write-Host "Exporting Redis data using redis-cli..." -ForegroundColor Yellow
            $exportFile = Join-Path $backupDir "redis_data.txt"
            
            # Export all keys and their values
            $keys = redis-cli -h $redis.hostName -p 6380 -a $accessKeys.primaryKey --tls keys "*"
            if ($keys) {
                $exportContent = @()
                foreach ($key in $keys) {
                    $value = redis-cli -h $redis.hostName -p 6380 -a $accessKeys.primaryKey --tls get $key
                    $ttl = redis-cli -h $redis.hostName -p 6380 -a $accessKeys.primaryKey --tls ttl $key
                    $exportContent += "KEY: $key"
                    $exportContent += "VALUE: $value"
                    $exportContent += "TTL: $ttl"
                    $exportContent += "---"
                }
                $exportContent | Out-File -FilePath $exportFile -Encoding UTF8
                Write-Host "Data exported to: $exportFile" -ForegroundColor Green
            } else {
                Write-Host "No keys found in Redis instance" -ForegroundColor Yellow
            }
        } else {
            Write-Host "redis-cli not available. Creating metadata backup only." -ForegroundColor Yellow
        }
        
        # Create backup summary
        $summary = @{
            BackupName = $backupName
            Created = (Get-Date).ToString()
            RedisInstance = $Name
            ResourceGroup = $ResourceGroup
            Files = @(
                "metadata.json",
                "connection.json"
            ) + @(if ($redisCli) { "redis_data.txt" })
            Status = "Completed"
        }
        
        $summaryFile = Join-Path $backupDir "backup_summary.json"
        $summary | ConvertTo-Json -Depth 5 | Out-File -FilePath $summaryFile -Encoding UTF8
        
        Write-Host "Metadata saved to: $metadataFile" -ForegroundColor Green
        Write-Host "Connection info saved to: $connectionFile" -ForegroundColor Green
        Write-Host "Backup completed successfully!" -ForegroundColor Green
        Write-Host "Backup location: $backupDir" -ForegroundColor Green
        
        return $backupName
        
    } catch {
        Write-Host "Failed to create backup: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Function to restore Redis from backup
function Restore-RedisFromBackup {
    param([string]$Name, [string]$ResourceGroup, [string]$BackupPath, [string]$BackupName, [bool]$Force)
    
    if (-not $Force) {
        Write-Host "WARNING: This will overwrite ALL data in the Redis instance!" -ForegroundColor Red
        $confirm = Read-Host "Are you absolutely sure? Type 'RESTORE ALL DATA' to confirm"
        if ($confirm -ne "RESTORE ALL DATA") {
            Write-Host "Operation cancelled" -ForegroundColor Yellow
            return
        }
    }
    
    Write-Host "Restoring Redis from backup: $BackupName" -ForegroundColor Yellow
    
    try {
        $backupDir = Join-Path $BackupPath $BackupName
        if (-not (Test-Path $backupDir)) {
            Write-Host "No backup files found for: $BackupName" -ForegroundColor Red
            return
        }
        
        # Read connection info
        $connectionFile = Join-Path $backupDir "connection.json"
        if (-not (Test-Path $connectionFile)) {
            Write-Host "Connection file not found in backup" -ForegroundColor Red
            return
        }
        
        $connectionInfo = Get-Content $connectionFile | ConvertFrom-Json
        
        # Check if redis-cli is available
        $redisCli = Get-Command redis-cli -ErrorAction SilentlyContinue
        if (-not $redisCli) {
            Write-Host "redis-cli not available. Cannot restore data." -ForegroundColor Red
            return
        }
        
        # Flush existing data
        Write-Host "Flushing existing Redis data..." -ForegroundColor Yellow
        redis-cli -h $connectionInfo.HostName -p $connectionInfo.Port -a $connectionInfo.PrimaryKey --tls flushall
        
        # Restore data if available
        $dataFile = Join-Path $backupDir "redis_data.txt"
        if (Test-Path $dataFile) {
            Write-Host "Restoring Redis data..." -ForegroundColor Yellow
            $dataContent = Get-Content $dataFile
            $keyCount = 0
            
            for ($i = 0; $i -lt $dataContent.Length; $i += 4) {
                if ($i + 3 -lt $dataContent.Length) {
                    $key = $dataContent[$i] -replace "KEY: ", ""
                    $value = $dataContent[$i + 1] -replace "VALUE: ", ""
                    $ttl = $dataContent[$i + 2] -replace "TTL: ", ""
                    
                    if ($key -and $value) {
                        redis-cli -h $connectionInfo.HostName -p $connectionInfo.Port -a $connectionInfo.PrimaryKey --tls set $key $value
                        if ($ttl -and $ttl -ne "-1" -and $ttl -ne "-2") {
                            redis-cli -h $connectionInfo.HostName -p $connectionInfo.Port -a $connectionInfo.PrimaryKey --tls expire $key $ttl
                        }
                        $keyCount++
                    }
                }
            }
            
            Write-Host "Data restored successfully" -ForegroundColor Green
            Write-Host "Restored $keyCount keys" -ForegroundColor Green
        } else {
            Write-Host "No data file found. Only metadata was restored." -ForegroundColor Yellow
        }
        
        Write-Host "Restoration complete. Total keys: $keyCount" -ForegroundColor Green
        
    } catch {
        Write-Host "Failed to restore backup: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to list available backups
function Get-RedisBackups {
    param([string]$BackupPath)
    
    try {
        if (-not (Test-Path $BackupPath)) {
            Write-Host "Backup directory not found: $BackupPath" -ForegroundColor Red
            return
        }
        
        Write-Host "Available backups:" -ForegroundColor Cyan
        $backups = Get-ChildItem -Path $BackupPath -Directory | Sort-Object LastWriteTime -Descending
        
        if ($backups.Count -eq 0) {
            Write-Host "No backups found" -ForegroundColor Yellow
            return
        }
        
        foreach ($backup in $backups) {
            $summaryFile = Join-Path $backup.FullName "backup_summary.json"
            if (Test-Path $summaryFile) {
                try {
                    $summary = Get-Content $summaryFile | ConvertFrom-Json
                    Write-Host "  $($backup.Name)" -ForegroundColor White
                    Write-Host "    Created: $($summary.Created)" -ForegroundColor Gray
                    Write-Host "    Redis: $($summary.RedisInstance)" -ForegroundColor Gray
                    Write-Host "    Status: $($summary.Status)" -ForegroundColor Gray
                } catch {
                    Write-Host "  $($backup.Name) (corrupted summary)" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  $($backup.Name) (no summary)" -ForegroundColor Yellow
            }
        }
        
    } catch {
        Write-Host "Failed to list backups: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to delete backup
function Remove-RedisBackup {
    param([string]$BackupPath, [string]$BackupName, [bool]$Force)
    
    try {
        $backupDir = Join-Path $BackupPath $BackupName
        if (-not (Test-Path $backupDir)) {
            Write-Host "No backup files found for: $BackupName" -ForegroundColor Red
            return
        }
        
        if (-not $Force) {
            $confirm = Read-Host "Are you sure you want to delete backup '$BackupName'? (y/N)"
            if ($confirm -notmatch "^(y|yes)$") {
                Write-Host "Operation cancelled" -ForegroundColor Yellow
                return
            }
        }
        
        Remove-Item -Path $backupDir -Recurse -Force
        Write-Host "Deleted: $($backupDir)" -ForegroundColor Green
        
    } catch {
        Write-Host "Failed to delete backup: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to check backup status
function Get-BackupStatus {
    param([string]$BackupPath, [string]$BackupName)
    
    try {
        $backupDir = Join-Path $BackupPath $BackupName
        if (-not (Test-Path $backupDir)) {
            Write-Host "Backup not found: $BackupName" -ForegroundColor Red
            return
        }
        
        $summaryFile = Join-Path $backupDir "backup_summary.json"
        if (Test-Path $summaryFile) {
            $summary = Get-Content $summaryFile | ConvertFrom-Json
            Write-Host "=== Backup Status ===" -ForegroundColor Cyan
            Write-Host "Name: $($summary.BackupName)" -ForegroundColor White
            Write-Host "Created: $($summary.Created)" -ForegroundColor White
            Write-Host "Redis Instance: $($summary.RedisInstance)" -ForegroundColor White
            Write-Host "Resource Group: $($summary.ResourceGroup)" -ForegroundColor White
            Write-Host "Status: $($summary.Status)" -ForegroundColor White
            Write-Host "Files:" -ForegroundColor White
            foreach ($file in $summary.Files) {
                $filePath = Join-Path $backupDir $file
                $exists = Test-Path $filePath
                $status = if ($exists) { "EXISTS" } else { "MISSING" }
                $color = if ($exists) { "Green" } else { "Red" }
                Write-Host "  $file - $status" -ForegroundColor $color
            }
        } else {
            Write-Host "Backup summary not found" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "Failed to check backup status: $($_.Exception.Message)" -ForegroundColor Red
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
    "backup" {
        $backupName = New-RedisBackup -Name $RedisName -ResourceGroup $ResourceGroup -BackupPath $BackupPath
        if ($backupName) {
            Write-Host "Backup created successfully: $backupName" -ForegroundColor Green
        }
    }
    "restore" {
        if (-not $BackupName) {
            Write-Host "Backup name is required for restore operation" -ForegroundColor Red
            exit 1
        }
        Restore-RedisFromBackup -Name $RedisName -ResourceGroup $ResourceGroup -BackupPath $BackupPath -BackupName $BackupName -Force $Force
    }
    "list" {
        Get-RedisBackups -BackupPath $BackupPath
    }
    "delete" {
        if (-not $BackupName) {
            Write-Host "Backup name is required for delete operation" -ForegroundColor Red
            exit 1
        }
        Remove-RedisBackup -BackupPath $BackupPath -BackupName $BackupName -Force $Force
    }
    "status" {
        if (-not $BackupName) {
            Write-Host "Backup name is required for status check" -ForegroundColor Red
            exit 1
        }
        Get-BackupStatus -BackupPath $BackupPath -BackupName $BackupName
    }
    default {
        Write-Host "Unknown action: $Action" -ForegroundColor Red
        Write-Host "Available actions: backup, restore, list, delete, status" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""
Write-Host "Operation completed successfully!" -ForegroundColor Green
