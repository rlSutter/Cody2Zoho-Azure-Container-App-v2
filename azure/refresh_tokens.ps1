#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Refresh Zoho OAuth tokens and update configuration files
    
.DESCRIPTION
    This script refreshes Zoho OAuth tokens and updates both env.template
    and .env files with the new tokens.
    
.PARAMETER Interactive
    Run in interactive mode (default: true)
    
.PARAMETER Backup
    Create backup files before updating (default: true)
    
.PARAMETER SkipBackup
    Skip creating backup files
    
.EXAMPLE
    .\refresh_tokens.ps1
    
.EXAMPLE
    .\refresh_tokens.ps1 -Interactive:$false
    
.EXAMPLE
    .\refresh_tokens.ps1 -SkipBackup
#>

param(
    [switch]$Interactive,
    [switch]$SkipBackup
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors for output
$Green = "Green"
$Yellow = "Yellow"
$Red = "Red"
$Cyan = "Cyan"
$White = "White"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-Prerequisites {
    Write-ColorOutput "Checking prerequisites..." $Cyan
    
    # Check if Python is installed
    try {
        $pythonVersion = python --version
        Write-ColorOutput " Python found: $pythonVersion" $Green
    }
    catch {
        Write-ColorOutput " Python not found. Please install Python 3.8+." $Red
        exit 1
    }
    
    # Check if .env file exists
    if (Test-Path ".env") {
        Write-ColorOutput " .env file found" $Green
    }
    else {
        Write-ColorOutput " .env file not found. Using env.template..." $Yellow
        if (Test-Path "env.template") {
            Copy-Item "env.template" ".env"
            Write-ColorOutput " Created .env from template" $Green
        }
        else {
            Write-ColorOutput " Neither .env nor env.template found." $Red
            exit 1
        }
    }
    
    # Check if env.template exists
    if (Test-Path "env.template") {
        Write-ColorOutput " env.template file found" $Green
    }
    else {
        Write-ColorOutput " env.template file not found" $Red
        exit 1
    }
}

function Backup-ConfigFiles {
    if ($SkipBackup) {
        Write-ColorOutput " Skipping backup creation" $Yellow
        return
    }
    
    Write-ColorOutput "Creating backup files..." $Cyan
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    # Backup .env file
    if (Test-Path ".env") {
        $backupEnvPath = ".env.backup.$timestamp"
        Copy-Item ".env" $backupEnvPath
        Write-ColorOutput " Created backup: $backupEnvPath" $Green
    }
    
    # Backup env.template file
    if (Test-Path "env.template") {
        $backupTemplatePath = "env.template.backup.$timestamp"
        Copy-Item "env.template" $backupTemplatePath
        Write-ColorOutput " Created backup: $backupTemplatePath" $Green
    }
}

function Invoke-TokenRefresh {
    Write-ColorOutput "Starting Zoho OAuth token refresh..." $Cyan
    
    try {
        # Run the token generation script
        Write-ColorOutput " Running token generation script..." $Cyan
        
        if ($Interactive.IsPresent) {
            # Interactive mode
            $result = python "tests/generate_new_tokens.py"
        }
        else {
            # Non-interactive mode - generate auth URL only
            Write-ColorOutput " Non-interactive mode: Generating authorization URL..." $Cyan
            $result = python -c "
import sys
sys.path.insert(0, 'tests')
from generate_new_tokens import main
result = main(interactive=False, auto_update=False)
if isinstance(result, dict):
    print('AUTH_URL:' + result['auth_url'])
    print('REDIRECT_URI:' + result['redirect_uri'])
else:
    sys.exit(1)
"
            
            if ($LASTEXITCODE -eq 0) {
                $authUrl = ($result | Select-String "AUTH_URL:").ToString().Replace("AUTH_URL:", "").Trim()
                $redirectUri = ($result | Select-String "REDIRECT_URI:").ToString().Replace("REDIRECT_URI:", "").Trim()
                
                Write-ColorOutput " Authorization URL generated:" $Green
                Write-ColorOutput " $authUrl" $Cyan
                Write-ColorOutput " Redirect URI: $redirectUri" $Cyan
                Write-ColorOutput " Please complete the OAuth flow and provide the final URL" $Yellow
                
                $finalUrl = Read-Host "Enter the final URL from your browser"
                
                # Process the final URL
                $processResult = python -c "
import sys
sys.path.insert(0, 'tests')
from generate_new_tokens import process_external_auth_url
result = process_external_auth_url('$authUrl', '$finalUrl')
sys.exit(0 if result else 1)
"
                
                if ($LASTEXITCODE -eq 0) {
                    Write-ColorOutput " Token refresh completed successfully" $Green
                    return $true
                }
                else {
                    Write-ColorOutput " Token refresh failed" $Red
                    return $false
                }
            }
            else {
                Write-ColorOutput " Failed to generate authorization URL" $Red
                return $false
            }
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput " Token refresh completed successfully" $Green
            return $true
        }
        else {
            Write-ColorOutput " Token refresh failed" $Red
            return $false
        }
    }
    catch {
        Write-ColorOutput " Error during token refresh: $($_.Exception.Message)" $Red
        return $false
    }
}

function Test-TokenRefresh {
    Write-ColorOutput "Testing token refresh..." $Cyan
    
    # Check if tokens were updated
    if (Test-Path ".env") {
        $envContent = Get-Content ".env"
        $accessToken = ($envContent | Select-String "ZOHO_ACCESS_TOKEN=").ToString().Split("=")[1]
        $refreshToken = ($envContent | Select-String "ZOHO_REFRESH_TOKEN=").ToString().Split("=")[1]
        
        if ($accessToken -and $accessToken -ne "{ZOHO ACCESS TOKEN}") {
            Write-ColorOutput " Access token updated: $($accessToken.Substring(0, 20))..." $Green
        }
        else {
            Write-ColorOutput " Access token not updated" $Yellow
        }
        
        if ($refreshToken -and $refreshToken -ne "{ZOHO REFRESH TOKEN}") {
            Write-ColorOutput " Refresh token updated: $($refreshToken.Substring(0, 20))..." $Green
        }
        else {
            Write-ColorOutput " Refresh token not updated" $Yellow
        }
    }
    
    # Check if env.template was updated
    if (Test-Path "env.template") {
        $templateContent = Get-Content "env.template"
        $templateAccessToken = ($templateContent | Select-String "ZOHO_ACCESS_TOKEN=").ToString().Split("=")[1]
        $templateRefreshToken = ($templateContent | Select-String "ZOHO_REFRESH_TOKEN=").ToString().Split("=")[1]
        
        if ($templateAccessToken -and $templateAccessToken -ne "{ZOHO ACCESS TOKEN}") {
            Write-ColorOutput " env.template access token updated" $Green
        }
        else {
            Write-ColorOutput " env.template access token not updated" $Yellow
        }
        
        if ($templateRefreshToken -and $templateRefreshToken -ne "{ZOHO REFRESH TOKEN}") {
            Write-ColorOutput " env.template refresh token updated" $Green
        }
        else {
            Write-ColorOutput " env.template refresh token not updated" $Yellow
        }
    }
}

function Show-Usage {
    Write-ColorOutput "`nUsage Examples:" $Cyan
    Write-ColorOutput "  Interactive mode (default):" $Yellow
    Write-ColorOutput "    .\refresh_tokens.ps1" $White
    Write-ColorOutput "  Non-interactive mode:" $Yellow
    Write-ColorOutput "    .\refresh_tokens.ps1 -Interactive:`$false" $White
    Write-ColorOutput "  Skip backup creation:" $Yellow
    Write-ColorOutput "    .\refresh_tokens.ps1 -SkipBackup" $White
    Write-ColorOutput "  Manual token generation:" $Yellow
    Write-ColorOutput "    python tests/generate_new_tokens.py" $White
}

# Main execution
try {
    Write-ColorOutput "Zoho OAuth Token Refresh" $Cyan
    Write-ColorOutput "===========================" $Cyan
    
    # Check prerequisites
    Test-Prerequisites
    
    # Create backups
    Backup-ConfigFiles
    
    # Refresh tokens
    $success = Invoke-TokenRefresh
    
    if ($success) {
        Write-ColorOutput "`nToken refresh completed successfully!" $Green
        
        # Test the refresh
        Test-TokenRefresh
        
        Write-ColorOutput "`nNext steps:" $Cyan
        Write-ColorOutput "  1. Verify the tokens in .env and env.template files" $White
        Write-ColorOutput "  2. Deploy the application with updated tokens" $White
        Write-ColorOutput "  3. Test the application functionality" $White
        
        Show-Usage
    }
    else {
        Write-ColorOutput "`nToken refresh failed!" $Red
        Write-ColorOutput "Please check the error messages above and try again." $Yellow
        
        Show-Usage
        exit 1
    }
}
catch {
    Write-ColorOutput "`nToken refresh failed: $($_.Exception.Message)" $Red
    Write-ColorOutput "Check the error details above and try again." $Yellow
    exit 1
}
