# Cody2Zoho Custom Activation Script
# This script activates the virtual environment and changes to the correct directory

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Change to the Cody2Zoho directory
$Cody2ZohoDir = "{cody directory}"
Set-Location $Cody2ZohoDir

# Activate the virtual environment
& "$ScriptDir\.venv\Scripts\Activate.ps1"

# Display success message
Write-Host "Virtual environment activated and changed to Cody2Zoho directory" -ForegroundColor Green
Write-Host "Current directory: $(Get-Location)" -ForegroundColor Cyan
Write-Host "Python environment: $env:VIRTUAL_ENV" -ForegroundColor Yellow
