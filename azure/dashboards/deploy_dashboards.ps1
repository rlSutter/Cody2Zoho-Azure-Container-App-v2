# Deploy Application Insights Dashboards
# Run this script to deploy the dashboard templates

Write-Host "Deploying Application Insights Dashboards..." -ForegroundColor Cyan

# Ensure portal extension is installed
Write-Host "Checking Azure CLI portal extension..." -ForegroundColor Yellow
try {
    az extension show --name portal 2>
    if (0 -ne 0) {
        Write-Host "Installing Azure CLI portal extension..." -ForegroundColor Yellow
        az extension add --name portal --yes
        if (0 -ne 0) {
            Write-Host "Failed to install portal extension. Trying alternative method..." -ForegroundColor Red
            az extension add --name portal --source https://aka.ms/portal-extension --yes
        }
    } else {
        Write-Host "Portal extension is already installed" -ForegroundColor Green
    }
} catch {
    Write-Host "Error checking portal extension: " -ForegroundColor Red
    Write-Host "Attempting to install portal extension..." -ForegroundColor Yellow
    az extension add --name portal --yes
}

# Verify portal extension is working
Write-Host "Verifying portal extension..." -ForegroundColor Yellow
az portal dashboard list --resource-group "{RESOURCE GROUP NAME}" --output table 2>
if (0 -ne 0) {
    Write-Host "Portal extension verification failed. Please install manually:" -ForegroundColor Red
    Write-Host "   az extension add --name portal --yes" -ForegroundColor White
    Write-Host "   az extension update --name portal" -ForegroundColor White
    exit 1
}

# Deploy Business Metrics Dashboard
Write-Host "Deploying Business Metrics Dashboard..." -ForegroundColor Yellow
az portal dashboard create --resource-group "{RESOURCE GROUP NAME}" --location "{LOCATION}" --name "cody2zoho-business-metrics" --input-path ".\azure\dashboards\business_metrics_dashboard.json" --output none

# Deploy Performance Dashboard  
Write-Host "Deploying Performance Dashboard..." -ForegroundColor Yellow
az portal dashboard create --resource-group "{RESOURCE GROUP NAME}" --location "{LOCATION}" --name "cody2zoho-performance" --input-path ".\azure\dashboards\performance_dashboard.json" --output none

# Deploy Operations Dashboard
Write-Host "Deploying Operations Dashboard..." -ForegroundColor Yellow
az portal dashboard create --resource-group "{RESOURCE GROUP NAME}" --location "{LOCATION}" --name "cody2zoho-operations" --input-path ".\azure\dashboards\operations_dashboard.json" --output none

Write-Host "Dashboard deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Dashboard URLs:" -ForegroundColor Cyan
Write-Host "Business Metrics: https://portal.azure.com/#@/resource/subscriptions/{SUBCRIPTION ID}/resourceGroups/{RESOURCE GROUP NAME}/providers/Microsoft.Portal/dashboards/cody2zoho-business-metrics" -ForegroundColor White
Write-Host "Performance: https://portal.azure.com/#@/resource/subscriptions/{SUBCRIPTION ID}/resourceGroups/{RESOURCE GROUP NAME}/providers/Microsoft.Portal/dashboards/cody2zoho-performance" -ForegroundColor White
Write-Host "Operations: https://portal.azure.com/#@/resource/subscriptions/{SUBCRIPTION ID}/resourceGroups/{RESOURCE GROUP NAME}/providers/Microsoft.Portal/dashboards/cody2zoho-operations" -ForegroundColor White
