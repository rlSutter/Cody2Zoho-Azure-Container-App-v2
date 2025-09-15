# Azure Container App Debugging Guide

## Overview

This comprehensive debugging guide consolidates all commands and procedures for interacting with, checking, and troubleshooting the Cody2Zoho Azure Container App, Application Insights, and related services.

## Quick Start Commands

### **Application Health Check**
```powershell
# Check if application is running
curl "{URL}/health"

# Check Application Insights status
curl "{URL}/debug/app-insights"

# Send test telemetry
curl "{URL}/debug/test-telemetry-detailed"

# Use Azure scripts for comprehensive checking
.\azure\verify_app_insights_status.ps1
.\azure\troubleshoot_app_insights.ps1
```

### **Container App Status**
```powershell
# Check running status
az containerapp show --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --query "properties.runningStatus" --output table

# Check latest revision
az containerapp show --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --query "properties.latestRevisionName" --output table

# List all revisions
az containerapp revision list --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --output table
```

## Container App Management

### **Container App Commands**

#### **Available Commands**
```powershell
# List all available commands
az containerapp --help

# Available commands:
az containerapp browse          # Open in browser
az containerapp create          # Create new app
az containerapp delete          # Delete app
az containerapp exec            # SSH into container
az containerapp list            # List apps
az containerapp show            # Show details
az containerapp update          # Update app (creates new revision)
az containerapp up              # Create or update with associated resources
```

#### **Commands That Don't Exist**
```powershell
# These commands are NOT available:
az containerapp restart         # ❌ Does not exist
az containerapp stop            # ❌ Does not exist
az containerapp start           # ❌ Does not exist
```

### **Restarting Container Apps**

#### **Method 1: Update with Same Image (Recommended)**
```powershell
# Restart by updating with the same image
az containerapp update \
  --name cody2zoho \
  --resource-group {AZURE RESOURCE GROUP} \
  --image "{IMAGE URL}" \
  --output none
```

#### **Method 2: Update Environment Variables**
```powershell
# Update environment variables (triggers restart)
az containerapp update \
  --name cody2zoho \
  --resource-group {AZURE RESOURCE GROUP} \
  --set-env-vars "APPLICATIONINSIGHTS_ENABLE_LIVE_METRICS=true" \
  --output none
```

#### **Method 3: Scale to Zero and Back**
```powershell
# Scale to zero replicas
az containerapp update \
  --name cody2zoho \
  --resource-group {AZURE RESOURCE GROUP} \
  --min-replicas 0 \
  --max-replicas 0 \
  --output none

# Wait a moment
Start-Sleep -Seconds 10

# Scale back up
az containerapp update \
  --name cody2zoho \
  --resource-group {AZURE RESOURCE GROUP} \
  --min-replicas 1 \
  --max-replicas 10 \
  --output none
```

### **Container App Information**

#### **Show Container App Details**
```powershell
# Show full details
az containerapp show --name cody2zoho --resource-group {AZURE RESOURCE GROUP}

# Show specific properties
az containerapp show --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --query "properties.runningStatus" --output table
az containerapp show --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --query "properties.latestRevisionName" --output table
az containerapp show --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --query "properties.template.containers[0].env" --output table
```

#### **Environment Variables**
```powershell
# Check all environment variables
az containerapp show \
  --name cody2zoho \
  --resource-group {AZURE RESOURCE GROUP} \
  --query "properties.template.containers[0].env" \
  --output table

# Check specific environment variables
az containerapp show \
  --name cody2zoho \
  --resource-group {AZURE RESOURCE GROUP} \
  --query "properties.template.containers[0].env[?contains(name, 'APPLICATIONINSIGHTS')]" \
  --output table
```

### **Container App Logs**

#### **View Logs**
```powershell
# View recent logs
az containerapp logs show --name cody2zoho --resource-group {AZURE RESOURCE GROUP}

# Follow logs in real-time
az containerapp logs show --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --follow

# View logs with specific options
az containerapp logs show --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --tail 100
```

#### **Container App Exec (SSH)**
```powershell
# Open interactive shell in container
az containerapp exec --name cody2zoho --resource-group {AZURE RESOURCE GROUP}

# Execute specific command
az containerapp exec --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --command "ls -la"
```

## Application Insights Debugging

### **Application Insights Status**

#### **Check Application Insights Resource**
```powershell
# Show Application Insights details
az resource show \
  --name "cody2zoho-insights" \
  --resource-group "{AZURE RESOURCE GROUP}" \
  --resource-type "Microsoft.Insights/components" \
  --query "properties" \
  --output json

# Check provisioning state
az resource show \
  --name "cody2zoho-insights" \
  --resource-group "{AZURE RESOURCE GROUP}" \
  --resource-type "Microsoft.Insights/components" \
  --query "properties.provisioningState" \
  --output table
```

#### **Application Insights Configuration**
```powershell
# Check connection string
az resource show \
  --name "cody2zoho-insights" \
  --resource-group "{AZURE RESOURCE GROUP}" \
  --resource-type "Microsoft.Insights/components" \
  --query "properties.ConnectionString" \
  --output table

# Check instrumentation key
az resource show \
  --name "cody2zoho-insights" \
  --resource-group "{AZURE RESOURCE GROUP}" \
  --resource-type "Microsoft.Insights/components" \
  --query "properties.InstrumentationKey" \
  --output table
```

### **Application Insights Scripts**

#### **Run Debug Scripts**
```powershell
# Check Application Insights configuration
.\azure\verify_app_insights_status.ps1

# Check telemetry events
.\azure\query_app_insights_events.ps1

# Test locally (moved to tests folder)
.\tests\test_app_insights_local.ps1

# Test with real connection (moved to tests folder)
.\tests\test_app_insights_real.ps1

# Enable Application Insights
.\azure\enable_app_insights.ps1
```

### **Live Metrics Troubleshooting**

#### **Enable Live Metrics**
```powershell
# Add Live Metrics environment variable
az containerapp update \
  --name cody2zoho \
  --resource-group {AZURE RESOURCE GROUP} \
  --set-env-vars "APPLICATIONINSIGHTS_ENABLE_LIVE_METRICS=true" \
  --output none

# Restart container app
az containerapp update \
  --name cody2zoho \
  --resource-group {AZURE RESOURCE GROUP} \
  --image "{IMAGE URL}" \
  --output none
```

#### **Test Live Metrics Connectivity**
```powershell
# Test connectivity to Live Metrics endpoint
curl -v "{URL}"

# Check Application Insights Live Metrics settings
az resource show \
  --name "cody2zoho-insights" \
  --resource-group "{AZURE RESOURCE GROUP}" \
  --resource-type "Microsoft.Insights/components" \
  --query "properties.EnableLiveMetrics" \
  --output table
```

## Application Debug Endpoints

### **Health and Status Endpoints**
```powershell
# Health check
curl "https{URL}/health"

# Application Insights debug
curl "{URL}/debug/app-insights"

# Test telemetry
curl "{URL}/debug/test-telemetry"

# Detailed telemetry test
curl "{URL}/debug/test-telemetry-detailed"

# Metrics endpoint
curl "{URL}/metrics"
```

### **Using PowerShell for HTTP Requests**
```powershell
# Health check with PowerShell
Invoke-WebRequest -Uri "{URL}/health" -UseBasicParsing

# Application Insights status with PowerShell
Invoke-WebRequest -Uri "https{URL}/debug/app-insights" -UseBasicParsing

# Test telemetry with PowerShell
Invoke-WebRequest -Uri "{URL}/debug/test-telemetry-detailed" -UseBasicParsing
```

## Azure Container Registry

### **ACR Commands**
```powershell
# List repositories
az acr repository list --name asecontainerregistry

# List tags for specific image
az acr repository show-tags --name {AZURE CONTAINER REGISTRY} --repository cody2zoho

# Show image details
az acr repository show --name {AZURE CONTAINER REGISTRY} --image cody2zoho:latest

# Delete old images
az acr repository delete --name {AZURE CONTAINER REGISTRY} --image cody2zoho:old-tag
```

## Deployment Debugging

### **Deployment Scripts**
```powershell
# Deploy application (Application Insights disabled by default)
.\azure\deploy_simple.ps1

# Deploy with monitoring (enables Application Insights)
.\azure\deploy_azure_monitoring.ps1

# Refresh tokens
.\azure\refresh_tokens.ps1

# Get container status
.\azure\monitor_container_app_status.ps1
```

### **Docker Commands**
```powershell
# Build image locally
docker build -t cody2zoho:latest .

# Test image locally
docker run -p 8080:8080 cody2zoho:latest

# Push to ACR
docker tag cody2zoho:latest {AZURE CONTAINER REGISTRY}
docker push {AZURE CONTAINER REGISTRY}

# Login to ACR
az acr login --name asecontainerregistry
```

## Monitoring and Logs

### **Azure Monitor Commands**
```powershell
# List Application Insights resources
az monitor app-insights component list --resource-group {AZURE RESOURCE GROUP}

# Show Application Insights details
az monitor app-insights component show --app cody2zoho-insights --resource-group {AZURE RESOURCE GROUP}

# List metrics
az monitor metrics list --resource "/subscriptions/{SUBSCRIPTION ID}/resourceGroups/{AZURE RESOURCE GROUP}/providers/Microsoft.Insights/components/cody2zoho-insights"
```

### **Log Analytics Queries**
```powershell
# Note: Log Analytics extension may fail to install
# Use Azure Portal for Log Analytics queries instead

# Direct portal access for Log Analytics:
# https://portal.azure.com/#@/resource/subscriptions/{SUBSCRIPTION ID}/resourceGroups/{AZURE RESOURCE GROUP}/providers/Microsoft.Insights/components/cody2zoho-insights/logs
```

## Troubleshooting Scenarios

### **Scenario 1: Application Not Responding**
```powershell
# 1. Check container app status
az containerapp show --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --query "properties.runningStatus"

# 2. Check health endpoint
curl "{URL}/health"

# 3. View logs
az containerapp logs show --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --tail 50

# 4. Check revision status
az containerapp revision list --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --output table
```

### **Scenario 2: Application Insights Not Working**
```powershell
# 1. Check Application Insights status
curl "{URL}/debug/app-insights"

# 2. Test telemetry
curl "{URL}/debug/test-telemetry-detailed"

# 3. Check environment variables
az containerapp show --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --query "properties.template.containers[0].env[?contains(name, 'APPLICATIONINSIGHTS')]" --output table

# 4. Run debug script
.\azure\test_app_insights_real.ps1
```

### **Scenario 3: Live Metrics Not Connecting**
```powershell
# 1. Enable Live Metrics
az containerapp update --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --set-env-vars "APPLICATIONINSIGHTS_ENABLE_LIVE_METRICS=true"

# 2. Restart container app
az containerapp update --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --image "{CONTAINER REGISTRY IMAGE URL}"

# 3. Test connectivity
curl -v "https://eastus.livediagnostics.monitor.azure.com/"

# 4. Use Logs (Analytics) as alternative
# Go to: https://portal.azure.com/#@/resource/subscriptions/{SUBSCRIPTION ID}/resourceGroups/{AZURE RESOURCE GROUP}/providers/Microsoft.Insights/components/cody2zoho-insights/logs
```

### **Scenario 4: Container App Restart Issues**
```powershell
# 1. Check current revision
az containerapp show --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --query "properties.latestRevisionName"

# 2. Restart using update command (correct method)
az containerapp update --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --image "asecontainerregistry.azurecr.io/cody2zoho:latest"

# 3. Verify restart worked
az containerapp show --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --query "properties.latestRevisionName"

# 4. Check application health
curl "{URL}/health"
```

## Portal Access Links

### **Direct Portal Links**
```powershell
# Application Insights Overview
Write-Host "Application Insights: https://portal.azure.com/#@/resource/subscriptions/{SUBCRIPTION ID}/resourceGroups/{AZURE RESOURCE GROUP}/providers/Microsoft.Insights/components/cody2zoho-insights"

# Logs (Analytics)
Write-Host "Logs (Analytics): https://portal.azure.com/#@/resource/subscriptions/{SUBCRIPTION ID}/resourceGroups/{AZURE RESOURCE GROUP}/providers/Microsoft.Insights/components/cody2zoho-insights/logs"

# Live Metrics
Write-Host "Live Metrics: https://portal.azure.com/#@/resource/subscriptions/{SUBCRIPTION ID}/resourceGroups/{AZURE RESOURCE GROUP}/providers/Microsoft.Insights/components/cody2zoho-insights/liveMetrics"

# Container App
Write-Host "Container App: https://portal.azure.com/#@/resource/subscriptions/{SUBCRIPTION ID}/resourceGroups/{AZURE RESOURCE GROUP}/providers/Microsoft.App/containerApps/cody2zoho"
```

## Kusto Query Examples

### **Custom Events**
```kusto
// Find custom events from last 24 hours
customEvents
| where timestamp > ago(24h)
| where customDimensions.source == 'detailed_debug_endpoint'
| project timestamp, name, customDimensions
| order by timestamp desc

// Find all custom events
customEvents
| where timestamp > ago(24h)
| project timestamp, name, customDimensions
| order by timestamp desc
```

### **Custom Metrics**
```kusto
// Find custom metrics from last 24 hours
customMetrics
| where timestamp > ago(24h)
| where name == 'detailed_test_metric'
| project timestamp, name, value, customDimensions
| order by timestamp desc

// Find all custom metrics
customMetrics
| where timestamp > ago(24h)
| project timestamp, name, value, customDimensions
| order by timestamp desc
```

### **Traces**
```kusto
// Find Application Insights traces
traces
| where timestamp > ago(24h)
| where message contains 'app_insights'
| project timestamp, message, severityLevel
| order by timestamp desc
```

### **Requests and Exceptions**
```kusto
// Find HTTP requests
requests
| where timestamp > ago(24h)
| project timestamp, name, success, duration, resultCode
| order by timestamp desc

// Find exceptions
exceptions
| where timestamp > ago(24h)
| project timestamp, type, message, operationName
| order by timestamp desc
```

## Best Practices

### **Debugging Workflow**
1. **Start with health checks** - Verify application is running
2. **Check container app status** - Ensure proper deployment
3. **Review logs** - Look for errors and warnings
4. **Test Application Insights** - Verify telemetry is working
5. **Check portal data** - Verify data is appearing in Azure Portal
6. **Use debug endpoints** - Test specific functionality
7. **Monitor real-time** - Use Live Metrics or Logs (Analytics)

### **Common Issues and Solutions**
- **Container App Restart**: Use `az containerapp update`, not `az containerapp restart`
- **Live Metrics**: May not work in Container Apps, use Logs (Analytics) instead
- **Application Insights Data**: Takes 2-5 minutes to appear in portal
- **Environment Variables**: Check both raw environment and Pydantic settings
- **Network Connectivity**: Test endpoints directly with curl or PowerShell

### **Verification Checklist**
- [ ] Application health endpoint returns 200 OK
- [ ] Container app status is "Running"
- [ ] Latest revision is active
- [ ] Application Insights is configured
- [ ] Telemetry test endpoints work
- [ ] Data appears in Azure Portal (2-5 minute delay)
- [ ] Logs show no critical errors
- [ ] Environment variables are set correctly

---

**Note**: This debugging guide consolidates information from all Azure documentation files. For detailed explanations of specific issues, refer to the individual troubleshooting guides in the azure directory.
