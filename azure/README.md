# Azure Deployment and Monitoring Documentation

## Overview

This directory contains all Azure deployment scripts, monitoring tools, and Application Insights integration for the Cody2Zoho application.

## Recent Updates

### **Script Reorganization and Naming**
The Azure scripts have been reorganized for better clarity and precision:

#### **Renamed Scripts for Better Precision:**
- `check_app_insights.ps1` → `verify_app_insights_status.ps1`
- `check_app_insights_events.ps1` → `query_app_insights_events.ps1`
- `app_insights_workaround.ps1` → `troubleshoot_app_insights.ps1`
- `fix_portal_extension.ps1` → `fix_azure_cli_portal_extension.ps1`
- `get_container_status.ps1` → `monitor_container_app_status.ps1`

#### **Test Scripts Moved to Tests Folder:**
- `test_app_insights_local.ps1` → `tests/test_app_insights_local.ps1`
- `test_app_insights_real.ps1` → `tests/test_app_insights_real.ps1`

This reorganization provides:
- **Clearer naming**: Script names now clearly indicate their purpose
- **Better organization**: Test scripts are now properly located in the tests folder
- **Improved maintainability**: Easier to find and use the right script for each task

## Scripts

### Deployment Scripts

#### `deploy_simple.ps1`
**Purpose**: Main deployment script for Azure Container Apps
**Features**:
- Builds and pushes Docker image to Azure Container Registry
- Creates/updates Azure Container App
- Configures environment variables
- Tests health endpoint
- Handles token refresh if needed
- **Note**: Disables Application Insights by default (`ENABLE_APPLICATION_INSIGHTS=false`)

**Usage**:
```powershell
.\azure\deploy_simple.ps1
.\azure\deploy_simple.ps1 -ForceTokenRefresh
```

#### `deploy_azure_monitoring.ps1`
**Purpose**: Deploys Application Insights monitoring features
**Features**:
- Deploys enhanced Application Insights
- Sets up dashboards and alerts
- Configures Log Analytics queries
- Enables comprehensive monitoring
- **Automatically enables Application Insights** after deployment

**Usage**:
```powershell
.\azure\deploy_azure_monitoring.ps1
```

### Application Insights Scripts

#### `verify_app_insights_status.ps1` *(renamed from check_app_insights.ps1)*
**Purpose**: Verifies Application Insights configuration and status
**Features**:
- Checks connection string
- Validates role name
- Tests connectivity
- Reports configuration status

#### `query_app_insights_events.ps1` *(renamed from check_app_insights_events.ps1)*
**Purpose**: Queries Application Insights for telemetry data
**Features**:
- Searches for custom events
- Checks for traces and exceptions
- Queries business metrics
- Reports data availability

#### `enable_app_insights.ps1`
**Purpose**: Enables Application Insights for existing deployment
**Features**:
- Updates environment variables
- Configures telemetry
- Enables monitoring
- Restarts application

#### `troubleshoot_app_insights.ps1` *(renamed from app_insights_workaround.ps1)*
**Purpose**: Comprehensive Application Insights troubleshooting and diagnostic script
**Features**:
- Diagnoses common Application Insights issues
- Automatically fixes configuration problems
- Tests connectivity and telemetry
- Provides manual workaround steps
- Comprehensive status reporting
- **Automatically enables Application Insights if disabled**

### Monitoring and Setup Scripts

#### `setup_dashboards.ps1`
**Purpose**: Creates Azure dashboards
**Features**:
- Application performance dashboard
- Business metrics dashboard
- Error tracking dashboard
- Custom visualizations

#### `setup_app_insights_alerts.ps1`
**Purpose**: Configures Application Insights alerts
**Features**:
- Error rate alerts
- Performance alerts
- Business metric alerts
- Custom alert rules

#### `setup_log_analytics_queries.ps1`
**Purpose**: Sets up Log Analytics queries
**Features**:
- Custom event queries
- Performance queries
- Error analysis queries
- Business intelligence queries

#### `monitor_container_app_status.ps1` *(renamed from get_container_status.ps1)*
**Purpose**: Monitors container app status and health
**Features**:
- Container health checks
- Performance metrics
- Log retrieval
- Status reporting

### Token Management

#### `refresh_tokens.ps1`
**Purpose**: Refreshes Zoho OAuth tokens
**Features**:
- Interactive OAuth flow
- Token validation
- Environment updates
- Backup creation

**Usage**:
```powershell
.\azure\refresh_tokens.ps1
.\azure\refresh_tokens.ps1 -Interactive:$false
```

### Troubleshooting Scripts

#### `fix_azure_cli_portal_extension.ps1` *(renamed from fix_portal_extension.ps1)*
**Purpose**: Fixes Azure CLI portal extension installation issues
**Features**:
- Checks Azure CLI installation
- Verifies login status
- Removes problematic extensions
- Clears extension cache
- Reinstalls portal extension
- Tests extension functionality

## Documentation

### `FINDING_APPLICATION_INSIGHTS_DATA.md`
Comprehensive guide for finding and viewing Application Insights telemetry data including:
- Direct portal access links
- Navigation steps for different data views
- Kusto query examples for custom events, metrics, and traces
- Troubleshooting guide for data visibility issues
- Best practices for data monitoring




## Subdirectories

### `dashboards/`
Contains Azure dashboard JSON templates and configurations.

### `log_analytics_queries/`
Contains Kusto query templates for Log Analytics.

## Environment Variables

### Required for Deployment
```bash
# Azure Container Registry
ACR_NAME={AZURE CONTAINER REGISTRY}
ACR_LOGIN_SERVER={AZURE CONTAINER REGISTRY LOGIN}

# Azure Container Apps
RESOURCE_GROUP={AZURE RESOURCE GROUP}
LOCATION={AZURE LOCATION}
CONTAINER_APP_NAME=cody2zoho

# Application Insights
ENABLE_APPLICATION_INSIGHTS=true
APPLICATIONINSIGHTS_CONNECTION_STRING={AZURE APPLICATION INSIGHT CONNECTION STRING}
APPLICATIONINSIGHTS_ROLE_NAME=Cody2Zoho
APPLICATIONINSIGHTS_ENABLE_LIVE_METRICS=true
```

### Optional for Monitoring
```bash
# Graylog Integration
GRAYLOG_ENABLED=true
GRAYLOG_HOST=localhost
GRAYLOG_PORT=12201

# Redis Integration
REDIS_ENABLED=true
REDIS_HOST=localhost
REDIS_PORT=6379
```

## Quick Reference

### Deployment Commands
```powershell
# Deploy application (Application Insights disabled by default)
.\azure\deploy_simple.ps1

# Deploy with monitoring (enables Application Insights)
.\azure\deploy_azure_monitoring.ps1

# Refresh tokens
.\azure\refresh_tokens.ps1

# Monitor container app status
.\azure\monitor_container_app_status.ps1
```

### Monitoring Commands
```powershell
# Verify Application Insights status
.\azure\verify_app_insights_status.ps1

# Comprehensive Application Insights troubleshooting
.\azure\troubleshoot_app_insights.ps1

# Query telemetry data
.\azure\query_app_insights_events.ps1

# Test Application Insights locally (moved to tests folder)
.\tests\test_app_insights_local.ps1

# Test with real connection (moved to tests folder)
.\tests\test_app_insights_real.ps1
```

### Setup Commands
```powershell
# Setup dashboards
.\azure\setup_dashboards.ps1

# Setup alerts
.\azure\setup_app_insights_alerts.ps1

# Setup queries
.\azure\setup_log_analytics_queries.ps1
```

### Container App Management
```powershell
# Restart container app (correct method)
az containerapp update --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --image "asecontainerregistry.azurecr.io/cody2zoho:latest"

# Check container status
az containerapp show --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --query "properties.runningStatus"

# View logs
az containerapp logs show --name cody2zoho --resource-group {AZURE RESOURCE GROUP} --follow

# Fix Azure CLI portal extension issues
.\azure\fix_azure_cli_portal_extension.ps1
```

## Troubleshooting

### Common Issues

1. **Deployment Failures**
   - Check Azure CLI authentication
   - Verify resource group exists
   - Ensure Docker is running
   - Check network connectivity

2. **Application Insights Issues**
   - Verify connection string format
   - Check Python dependencies
   - Test network connectivity
   - Validate instrumentation key

3. **Live Metrics Connection Issues**
   - Enable Live Metrics environment variable
   - Check Container App networking constraints
   - Use Logs (Analytics) as alternative
   - Verify Application Insights configuration

4. **Container App Restart Issues**
   - **Important**: `az containerapp restart` command does not exist
   - Use `az containerapp update` instead
   - Check revision status after restart
   - Verify application health

5. **Token Refresh Issues**
   - Check OAuth app configuration
   - Verify redirect URI
   - Ensure proper scopes
   - Test interactive flow

### Debug Steps

1. **Check Application Status**
   ```powershell
   .\azure\monitor_container_app_status.ps1
   ```

2. **Test Application Insights**
   ```powershell
   .\tests\test_app_insights_local.ps1
   .\tests\test_app_insights_real.ps1
   ```

3. **Check Telemetry Data**
   ```powershell
   .\azure\query_app_insights_events.ps1
   ```

4. **Comprehensive Troubleshooting**
   ```powershell
   .\azure\troubleshoot_app_insights.ps1
   ```



5. **Find Application Insights Data**
   - See `FINDING_APPLICATION_INSIGHTS_DATA.md` for detailed portal navigation
   - Use direct portal links for quick access
   - Run Kusto queries for specific data types

## Best Practices

1. **Always use the latest deployment script**
2. **Test Application Insights locally before deployment**
3. **Monitor telemetry data regularly**
4. **Keep tokens refreshed**
5. **Use proper resource naming conventions**
6. **Monitor costs and resource usage**
7. **Use `az containerapp update` for restarts (not `az containerapp restart`)**
8. **Check Live Metrics alternatives if direct connection fails**
9. **Use Logs (Analytics) for historical data analysis**
10. **Set up alerts for immediate notification of issues**

## Important Notes

- **Container App Restart**: The `az containerapp restart` command does not exist. Use `az containerapp update` instead.
- **Live Metrics**: May not work in Container Apps due to networking constraints. Use Logs (Analytics) as alternative.
- **Application Insights Data**: Takes 2-5 minutes to appear in portal. Use Live Metrics for real-time data.
- **Environment Variables**: `deploy_simple.ps1` disables Application Insights by default. Use `deploy_azure_monitoring.ps1` for full monitoring.
- **Emojis**: Removed from PowerShell script outputs as per user preference.
