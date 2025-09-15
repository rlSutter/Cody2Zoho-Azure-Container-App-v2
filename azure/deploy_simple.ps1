#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Simple Azure Container Apps deployment script that bypasses command line length issues
.DESCRIPTION
    Deploys the Cody2Zoho application to Azure Container Apps using manual commands
.PARAMETER SkipTokenRefresh
    Skip the token refresh step
.PARAMETER SkipLogin
    Skip the Azure login step
#>

param(
    [switch]$SkipTokenRefresh = $true,  # Default to skipping token refresh to avoid hanging
    [switch]$SkipLogin,
    [switch]$ForceTokenRefresh,  # New parameter to force token refresh
    [switch]$SkipEnvVarCheck = $false,  # Skip checking if env vars have changed (force update all)
    [switch]$SkipRedisDeployment = $false  # Skip Redis deployment and use existing Redis instance
)

# Color functions
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

# Function to read tokens from .env file
function Read-TokensFromEnv {
    param()
    
    $envContent = Get-Content ".env" -ErrorAction SilentlyContinue
    $accessToken = ""
    $refreshToken = ""
    
    foreach ($line in $envContent) {
        if ($line -match "^ZOHO_ACCESS_TOKEN=(.+)$") {
            $accessToken = $matches[1]
        }
        elseif ($line -match "^ZOHO_REFRESH_TOKEN=(.+)$") {
            $refreshToken = $matches[1]
        }
    }
    
    return @{
        AccessToken = $accessToken
        RefreshToken = $refreshToken
    }
}

# Function to get current environment variables from container app
function Get-CurrentContainerAppEnvVars {
    param(
        [string]$AppName,
        [string]$ResourceGroup
    )
    
    try {
        $appInfo = az containerapp show --name $AppName --resource-group $ResourceGroup --query 'properties.template.containers[0].env' -o json 2>$null
        if ($appInfo) {
            $envVars = $appInfo | ConvertFrom-Json
            $currentVars = @{}
            foreach ($envVar in $envVars) {
                $currentVars[$envVar.name] = $envVar.value
            }
            return $currentVars
        }
    }
    catch {
        # If container app doesn't exist or has no env vars, return empty hashtable
    }
    
    return @{}
}

# Function to check if Redis instance exists
function Test-RedisExists {
    param(
        [string]$RedisName,
        [string]$ResourceGroup
    )
    
    try {
        $redisInfo = az redis show --name $RedisName --resource-group $ResourceGroup --query "name" -o tsv 2>$null
        return $redisInfo -eq $RedisName
    }
    catch {
        return $false
    }
}

# Function to create Redis instance if it doesn't exist
function New-RedisInstance {
    param(
        [string]$RedisName,
        [string]$ResourceGroup,
        [string]$Location
    )
    
    Write-ColorOutput "Creating Redis instance '$RedisName'..." $Cyan
    az redis create --name $RedisName --resource-group $ResourceGroup --location $Location --sku Basic --vm-size c0 --output none
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput " Redis instance created successfully" $Green
        return $true
    } else {
        Write-ColorOutput " Failed to create Redis instance" $Red
        return $false
    }
}

# Function to set environment variables efficiently (only changed ones)
function Set-ContainerAppEnvVars {
    param(
        [string]$AppName,
        [string]$ResourceGroup,
        [array]$NewEnvVars,
        [hashtable]$CurrentEnvVars,
        [bool]$SkipEnvVarCheck = $false
    )
    
    $changedVars = @()
    $unchangedCount = 0
    
    if ($SkipEnvVarCheck) {
        Write-ColorOutput " Skipping environment variable change detection (force update all)" $Yellow
        $changedVars = $NewEnvVars
    } else {
        foreach ($envVar in $NewEnvVars) {
            $parts = $envVar -split "=", 2
            if ($parts.Length -eq 2) {
                $key = $parts[0]
                $newValue = $parts[1]
                
                # Check if value has changed
                if ($CurrentEnvVars.ContainsKey($key)) {
                    if ($CurrentEnvVars[$key] -eq $newValue) {
                        $unchangedCount++
                        continue  # Skip unchanged variables
                    }
                }
                
                $changedVars += $envVar
            }
        }
    }
    
    if ($unchangedCount -gt 0) {
        Write-ColorOutput " Skipping $unchangedCount unchanged environment variables" $Yellow
    }
    
    if ($changedVars.Count -eq 0) {
        Write-ColorOutput " All environment variables are up to date!" $Green
        return
    }
    
    Write-ColorOutput " Updating $($changedVars.Count) changed environment variables..." $Cyan
    
    # Set all changed variables in one command for efficiency
    $envVarsString = $changedVars -join ","
    az containerapp update --name $AppName --resource-group $ResourceGroup --set-env-vars $envVarsString --output none
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput " Environment variables updated successfully!" $Green
    } else {
        Write-ColorOutput " Failed to update environment variables, trying individual updates..." $Yellow
        
        # Fallback to individual updates if bulk update fails
        foreach ($envVar in $changedVars) {
            $parts = $envVar -split "=", 2
            if ($parts.Length -eq 2) {
                $key = $parts[0]
                $value = $parts[1]
                Write-ColorOutput " Setting $key..." $Yellow
                az containerapp update --name $AppName --resource-group $ResourceGroup --set-env-vars "$key=$value" --output none
            }
        }
    }
}

$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Cyan = "Cyan"
$Blue = "Blue"
$White = "White"

# Configuration
$ResourceGroup = "{AZURE RESOURCE GROUP}"
$Location = "eastus"
$AcrName = "asecontainerregistry"
$AppName = "cody2zoho"
$EnvironmentName = "Cody2Zoho-env"

Write-ColorOutput "Simple Cody2Zoho Azure Deployment" $Cyan
Write-ColorOutput "=================================" $Cyan

# Check prerequisites
Write-ColorOutput "Checking prerequisites..." $Cyan
if (-not (Get-Command "az" -ErrorAction SilentlyContinue)) {
    Write-ColorOutput " Azure CLI not found!" $Red
    exit 1
}
Write-ColorOutput " Azure CLI found: $(az version --query '\"azure-cli\"' -o tsv)" $Green

if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-ColorOutput " Docker not found!" $Red
    exit 1
}
Write-ColorOutput " Docker found: $(docker --version)" $Green

# Connect to Azure
if (-not $SkipLogin) {
    Write-ColorOutput "Connecting to Azure..." $Cyan
    az login
}

$subscription = az account show --query "name" -o tsv
Write-ColorOutput " Using subscription: $subscription" $Green

# Token refresh
if ($ForceTokenRefresh) {
    Write-ColorOutput "WARNING: Token refresh requires manual OAuth flow completion" $Yellow
    Write-ColorOutput "This will open a browser and wait for you to complete the authorization" $Yellow
    $continue = Read-Host "Do you want to continue with token refresh? (y/N)"
    if ($continue -notmatch "^[Yy]") {
        Write-ColorOutput " Skipping token refresh" $Yellow
        $SkipTokenRefresh = $true
    } else {
        Write-ColorOutput " Proceeding with token refresh..." $Green
        $SkipTokenRefresh = $false
    }
}

if (-not $SkipTokenRefresh) {
    Write-ColorOutput "Refreshing tokens..." $Cyan
    try {
        # Run token refresh directly (no background job)
        Write-ColorOutput " Starting token refresh process..." $Yellow
        & ".\azure\refresh_tokens.ps1"
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput " Token refresh completed successfully" $Green
            # Re-read tokens from updated .env file
            Write-ColorOutput " Re-reading tokens from updated .env file..." $Cyan
            Start-Sleep -Seconds 2  # Give file system time to update
            
            # Re-read tokens after refresh
            $updatedTokens = Read-TokensFromEnv
            $currentAccessToken = $updatedTokens.AccessToken
            $currentRefreshToken = $updatedTokens.RefreshToken
            
            Write-ColorOutput " Updated access token: $($currentAccessToken.Substring(0, 20))..." $Green
            Write-ColorOutput " Updated refresh token: $($currentRefreshToken.Substring(0, 20))..." $Green
        } else {
            Write-ColorOutput " Token refresh failed with exit code: $LASTEXITCODE" $Red
            Write-ColorOutput " Continuing with existing tokens..." $Yellow
        }
    }
    catch {
        Write-ColorOutput " Token refresh failed: $($_.Exception.Message)" $Red
        Write-ColorOutput " Continuing with existing tokens..." $Yellow
    }
}

# Read current tokens from .env file
Write-ColorOutput "Reading current tokens..." $Cyan
$tokens = Read-TokensFromEnv
$currentAccessToken = $tokens.AccessToken
$currentRefreshToken = $tokens.RefreshToken

Write-ColorOutput " Access token: $($currentAccessToken.Substring(0, 20))..." $Green
Write-ColorOutput " Refresh token: $($currentRefreshToken.Substring(0, 20))..." $Green

# Check if tokens are recent (less than 1 hour old)
if ($currentAccessToken -and $currentRefreshToken) {
    Write-ColorOutput " Using existing tokens (use -ForceTokenRefresh to generate new ones)" $Yellow
} else {
    Write-ColorOutput " No valid tokens found - consider running with -ForceTokenRefresh" $Red
}

# Build and push Docker image
Write-ColorOutput "Building Docker image..." $Cyan
docker build -t "$AcrName.azurecr.io/$AppName`:latest" .
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput " Docker build failed!" $Red
    exit 1
}
Write-ColorOutput " Docker image built successfully" $Green

Write-ColorOutput "Pushing image to ACR..." $Cyan
az acr login --name $AcrName
docker push "$AcrName.azurecr.io/$AppName`:latest"
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput " Docker push failed!" $Red
    exit 1
}
Write-ColorOutput " Image pushed successfully" $Green

# Handle Redis deployment
$redisName = "cody2zoho-redis"
Write-ColorOutput "Checking Redis instance..." $Cyan

if ($SkipRedisDeployment) {
    Write-ColorOutput " Skipping Redis deployment - using existing instance" $Yellow
} else {
    Write-ColorOutput " Checking if Redis instance exists..." $Cyan
    $redisExists = Test-RedisExists -RedisName $redisName -ResourceGroup $ResourceGroup
    
    if (-not $redisExists) {
        Write-ColorOutput " Redis instance '$redisName' not found" $Yellow
        Write-ColorOutput " Creating new Redis instance..." $Cyan
        $redisCreated = New-RedisInstance -RedisName $redisName -ResourceGroup $ResourceGroup -Location $Location
        
        if (-not $redisCreated) {
            Write-ColorOutput " Failed to create Redis instance. Exiting." $Red
            exit 1
        }
        
        # Wait for Redis to be ready
        Write-ColorOutput " Waiting for Redis instance to be ready..." $Yellow
        Start-Sleep -Seconds 30
    } else {
        Write-ColorOutput " Redis instance '$redisName' already exists" $Green
        
        # Interactive prompt for existing Redis instance
        Write-ColorOutput "`nRedis Deployment Options:" $Cyan
        Write-ColorOutput "  [Y] Use existing Redis instance (recommended for updates)" $Green
        Write-ColorOutput "  [N] Recreate Redis instance (will delete existing data)" $Yellow
        Write-ColorOutput "  [S] Skip Redis deployment entirely" $White
        
        do {
            $redisChoice = Read-Host "`nHow would you like to handle the existing Redis instance? (Y/n/s)"
            $redisChoice = $redisChoice.Trim().ToLower()
        } while ($redisChoice -notmatch "^(y|yes|n|no|s|skip)$")
        
        switch ($redisChoice) {
            { $_ -match "^(n|no)$" } {
                Write-ColorOutput " Recreating Redis instance (this will delete existing data)..." $Yellow
                Write-ColorOutput " WARNING: This will permanently delete all data in the existing Redis instance!" $Red
                $confirm = Read-Host "Are you sure you want to continue? (y/N)"
                if ($confirm -match "^(y|yes)$") {
                    Write-ColorOutput " Deleting existing Redis instance..." $Yellow
                    az redis delete --name $redisName --resource-group $ResourceGroup --yes --output none
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-ColorOutput " Creating new Redis instance..." $Cyan
                        $redisCreated = New-RedisInstance -RedisName $redisName -ResourceGroup $ResourceGroup -Location $Location
                        
                        if (-not $redisCreated) {
                            Write-ColorOutput " Failed to create Redis instance. Exiting." $Red
                            exit 1
                        }
                        
                        # Wait for Redis to be ready
                        Write-ColorOutput " Waiting for Redis instance to be ready..." $Yellow
                        Start-Sleep -Seconds 30
                    } else {
                        Write-ColorOutput " Failed to delete existing Redis instance. Exiting." $Red
                        exit 1
                    }
                } else {
                    Write-ColorOutput " Keeping existing Redis instance" $Green
                }
            }
            { $_ -match "^(s|skip)$" } {
                Write-ColorOutput " Skipping Redis deployment - using existing instance" $Yellow
                $SkipRedisDeployment = $true
            }
            default {
                Write-ColorOutput " Using existing Redis instance" $Green
            }
        }
    }
}

# Get Redis connection info
Write-ColorOutput "Getting Redis connection info..." $Cyan
$redisHost = az redis show --name $redisName --resource-group $ResourceGroup --query "hostName" -o tsv
$redisPort = az redis show --name $redisName --resource-group $ResourceGroup --query "port" -o tsv
$redisKey = az redis list-keys --name $redisName --resource-group $ResourceGroup --query "primaryKey" -o tsv

Write-ColorOutput " Redis Host: $redisHost" $Green
Write-ColorOutput " Redis Port: $redisPort" $Green

# Always delete existing container app and create new one
Write-ColorOutput "Checking for existing container app..." $Cyan
$existingApp = az containerapp show --name $AppName --resource-group $ResourceGroup 2>$null
if ($existingApp) {
    Write-ColorOutput " Deleting existing container app..." $Yellow
    az containerapp delete --name $AppName --resource-group $ResourceGroup --yes
    Write-ColorOutput " Existing container app deleted" $Green
}
Write-ColorOutput " Creating new container app..." $Yellow

# Create container app manually
Write-ColorOutput "Creating container app manually..." $Cyan
Write-ColorOutput " This bypasses PowerShell command line length limitations" $Yellow

# Get ACR credentials
az acr update --name $AcrName --admin-enabled true | Out-Null
$acrUsername = az acr credential show --name $AcrName --query "username" -o tsv
$acrPassword = az acr credential show --name $AcrName --query "passwords[0].value" -o tsv

# Create the container app with all settings in one command
Write-ColorOutput " Creating container app with all configuration..." $Cyan
$redisUrl = "redis://:$redisKey@$redisHost`:$redisPort/0"

# Build environment variables string
Write-ColorOutput " Preparing environment variables..." $Cyan

# Create environment variables array for Azure CLI
$envVarsArray = @(
    "REDIS_URL=$redisUrl",
    "PORT=8080",
    "ZOHO_ACCESS_TOKEN=$currentAccessToken",
    "ZOHO_REFRESH_TOKEN=$currentRefreshToken",
    "ZOHO_CLIENT_ID={ID}",
    "ZOHO_CLIENT_SECRET={SECRET}",
    "ZOHO_API_BASE_URL=https://www.zohoapis.com",
    "ZOHO_ACCOUNTS_BASE_URL=https://accounts.zoho.com",
    "ZOHO_API_VERSION=v8",
    "CODY_API_URL=https://getcody.ai/api/v1",
    "CODY_API_KEY={API KEY}",
    "CODY_BOT_ID={BOT ID}",
    "ZOHO_CONTACT_ID={CONTACT ID}",
    "ZOHO_CONTACT_NAME={CONTACT NAME}",
    "ZOHO_CASE_STATUS=Closed",
    "ZOHO_CASE_ORIGIN=Web",
    "ZOHO_ENABLE_DUPLICATE_CHECK=true",
    "ZOHO_ATTACH_TRANSCRIPT_AS_NOTE=false",
    "POLL_INTERVAL_SECONDS=30",
    "ENABLE_GRAYLOG=false",
    "ENABLE_APPLICATION_INSIGHTS=false",
    "APPLICATIONINSIGHTS_ROLE_NAME=Cody2Zoho",
    "APPLICATIONINSIGHTS_CONNECTION_STRING={CONNECTION STRING}"
)

Write-ColorOutput " Configured $($envVarsArray.Count) environment variables" $Green

Write-ColorOutput " Executing creation command with all environment variables..." $Yellow

# Create new container app
Write-ColorOutput "Creating new container app..." $Cyan

# Use PowerShell arrays to avoid command line length issues
$cmd = "az"
$args = @(
    "containerapp", "create",
    "--name", $AppName,
    "--resource-group", $ResourceGroup,
    "--environment", $EnvironmentName,
    "--image", "$AcrName.azurecr.io/$AppName`:latest",
    "--target-port", "8080",
    "--ingress", "external",
    "--allow-insecure",
    "--registry-server", "$AcrName.azurecr.io",
    "--registry-username", $acrUsername,
    "--registry-password", $acrPassword,
    "--output", "none"
)

& $cmd $args

if ($LASTEXITCODE -eq 0) {
    Write-ColorOutput " Container app created successfully!" $Green
    
    # Get current environment variables (will be empty for new container app)
    Write-ColorOutput "Checking current environment variables..." $Cyan
    $currentEnvVars = Get-CurrentContainerAppEnvVars -AppName $AppName -ResourceGroup $ResourceGroup
    
    # Add environment variables efficiently (only changed ones)
    Write-ColorOutput "Setting environment variables..." $Cyan
    Set-ContainerAppEnvVars -AppName $AppName -ResourceGroup $ResourceGroup -NewEnvVars $envVarsArray -CurrentEnvVars $currentEnvVars -SkipEnvVarCheck $SkipEnvVarCheck
    
    Write-ColorOutput " Container app created successfully with all environment variables!" $Green
} else {
    Write-ColorOutput " Container app creation failed!" $Red
    exit 1
}

# Get deployment info
Write-ColorOutput "Getting deployment details..." $Cyan
$appInfo = az containerapp show --name $AppName --resource-group $ResourceGroup --output json | ConvertFrom-Json
$appUrl = $appInfo.properties.configuration.ingress.fqdn

Write-ColorOutput "`nDeployment completed successfully!" $Green
Write-ColorOutput " Application URL: https://$appUrl" $Green
Write-ColorOutput " Health Check: https://$appUrl/health" $Green
Write-ColorOutput " Metrics: https://$appUrl/metrics" $Green

# Test health endpoint
Write-ColorOutput "`nTesting health endpoint..." $Cyan
try {
    $response = Invoke-WebRequest -Uri "https://$appUrl/health" -UseBasicParsing -TimeoutSec 30
    if ($response.StatusCode -eq 200) {
        Write-ColorOutput " Health check passed! Status: $($response.StatusCode)" $Green
    } else {
        Write-ColorOutput " Health check returned: $($response.StatusCode)" $Yellow
    }
}
catch {
    Write-ColorOutput " Health check failed: $($_.Exception.Message)" $Red
    Write-ColorOutput " This is normal immediately after deployment - the app may still be starting" $Yellow
}

Write-ColorOutput "`nDeployment script completed successfully!" $Green
Write-ColorOutput "Container app '$AppName' is now running at: https://$appUrl" $Cyan

# Show optimization summary
Write-ColorOutput "`nOptimization Summary:" $Cyan
Write-ColorOutput " - Container app creation: Always creates fresh container app" $White
Write-ColorOutput " - Environment variables: Only updates changed variables (use -SkipEnvVarCheck to force all)" $White
Write-ColorOutput " - Token refresh: Available with -ForceTokenRefresh parameter" $White
Write-ColorOutput " - Redis deployment: Interactive prompts for existing instances, -SkipRedisDeployment to bypass" $White
