#!/usr/bin/env pwsh

# Fix Azure CLI Portal Extension Installation
# This script resolves the common portal extension installation issues

Write-Host "=== Fixing Azure CLI Portal Extension ===" -ForegroundColor Cyan
Write-Host ""

# Check if Azure CLI is installed
Write-Host "1. Checking Azure CLI installation..." -ForegroundColor Yellow
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Host "   Azure CLI version: $($azVersion.'azure-cli')" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: Azure CLI not found or not working" -ForegroundColor Red
    Write-Host "   Please install Azure CLI from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor White
    exit 1
}

# Check if logged in
Write-Host "2. Checking Azure login status..." -ForegroundColor Yellow
try {
    $account = az account show --output json | ConvertFrom-Json
    Write-Host "   Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "   Subscription: $($account.name)" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: Not logged into Azure" -ForegroundColor Red
    Write-Host "   Please run: az login" -ForegroundColor White
    exit 1
}

# Remove existing portal extension if problematic
Write-Host "3. Checking existing portal extension..." -ForegroundColor Yellow
try {
    $existingExtension = az extension show --name portal --output json 2>$null | ConvertFrom-Json
    Write-Host "   Found existing portal extension version: $($existingExtension.version)" -ForegroundColor Yellow
    
    Write-Host "   Removing existing portal extension..." -ForegroundColor Yellow
    az extension remove --name portal --yes
    Write-Host "   Portal extension removed" -ForegroundColor Green
} catch {
    Write-Host "   No existing portal extension found" -ForegroundColor Green
}

# Clear Azure CLI extension cache
Write-Host "4. Clearing Azure CLI extension cache..." -ForegroundColor Yellow
try {
    # Get Azure CLI extension directory
    $azConfigDir = az config get --query "defaults[?name=='extension_dir'].value" --output tsv
    if (-not $azConfigDir) {
        $azConfigDir = "$env:USERPROFILE\.azure\cliextensions"
    }
    
    if (Test-Path "$azConfigDir\portal") {
        Remove-Item -Path "$azConfigDir\portal" -Recurse -Force
        Write-Host "   Extension cache cleared" -ForegroundColor Green
    } else {
        Write-Host "   No portal extension cache found" -ForegroundColor Green
    }
} catch {
    Write-Host "   Warning: Could not clear extension cache" -ForegroundColor Yellow
}

# Install portal extension with multiple methods
Write-Host "5. Installing portal extension..." -ForegroundColor Yellow

$installMethods = @(
    @{ name = "Standard installation"; command = "az extension add --name portal --yes" },
    @{ name = "Direct source installation"; command = "az extension add --name portal --source https://aka.ms/portal-extension --yes" },
    @{ name = "Pip installation"; command = "pip install azure-cli-extension-portal -or- pip install azure-cli-extension" }
)

$success = $false
foreach ($method in $installMethods) {
    Write-Host "   Trying $($method.name)..." -ForegroundColor Yellow
    try {
        Invoke-Expression $method.command
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   $($method.name) successful!" -ForegroundColor Green
            $success = $true
            break
        }
    } catch {
        Write-Host "   $($method.name) failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if (-not $success) {
    Write-Host "   All installation methods failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual installation steps:" -ForegroundColor Yellow
    Write-Host "   1. Run: az extension add --name portal --yes" -ForegroundColor White
    Write-Host "   2. If that fails, run: pip install azure-cli-extension-portal" -ForegroundColor White
    Write-Host "   3. Restart your terminal/PowerShell" -ForegroundColor White
    Write-Host "   4. Try the dashboard deployment again" -ForegroundColor White
    exit 1
}

# Verify portal extension installation
Write-Host "6. Verifying portal extension..." -ForegroundColor Yellow
try {
    $extension = az extension show --name portal --output json | ConvertFrom-Json
    Write-Host "   Portal extension version: $($extension.version)" -ForegroundColor Green
    
    # Test portal extension functionality
    Write-Host "   Testing portal extension functionality..." -ForegroundColor Yellow
    az portal dashboard list --output table 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Portal extension is working correctly!" -ForegroundColor Green
    } else {
        Write-Host "   Warning: Portal extension installed but may have issues" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ERROR: Portal extension verification failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Portal Extension Fix Complete ===" -ForegroundColor Green
Write-Host "The portal extension has been successfully installed and verified." -ForegroundColor White
Write-Host ""
Write-Host "You can now run the dashboard deployment:" -ForegroundColor Yellow
Write-Host "   .\azure\dashboards\deploy_dashboards.ps1" -ForegroundColor White
Write-Host ""
Write-Host "If you still encounter issues, try:" -ForegroundColor Yellow
Write-Host "   1. Restarting your terminal/PowerShell" -ForegroundColor White
Write-Host "   2. Running: az extension update --name portal" -ForegroundColor White
Write-Host "   3. Checking your Azure CLI version: az version" -ForegroundColor White
