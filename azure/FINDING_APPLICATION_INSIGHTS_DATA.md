# Finding Application Insights Telemetry Data

## Overview

This document explains how to locate and view Application Insights telemetry data for the Cody2Zoho application. Application Insights data is stored separately from container logs and requires specific navigation in the Azure Portal.

## Key Concepts

### Container Logs vs Application Insights Data

- **Container Logs**: Application startup, errors, and system messages
- **Application Insights**: Custom telemetry, events, metrics, and performance data

### Data Storage Location

Application Insights data is stored in the **Application Insights resource** (`cody2zoho-insights`), not in the Container App resource.

## Accessing Application Insights Data

### 1. Direct Portal Access

**Application Insights Resource URL:**
```
{URL}
```

**Application Insights Main Dashboard**
```
{URL}
```

### 2. Navigation Steps

1. **Open Azure Portal**
2. **Search for "Application Insights"** in the search bar
3. **Click on "cody2zoho-insights"**
4. **Use the left menu to navigate to different data views**

## Data Sections in Application Insights

### 1. LOGS (Analytics) - Primary Location for Custom Telemetry

**Purpose**: View custom events, metrics, traces, and logs
**Access**: Click "Logs (Analytics)" in the left menu
**Data Latency**: 2-5 minutes

#### Key Kusto Queries

**Find Custom Events:**
```kusto
customEvents
| where timestamp > ago(24h)
| where customDimensions.source == 'detailed_debug_endpoint'
| project timestamp, name, customDimensions
| order by timestamp desc
```

**Find Custom Metrics:**
```kusto
customMetrics
| where timestamp > ago(24h)
| where name == 'detailed_test_metric'
| project timestamp, name, value, customDimensions
| order by timestamp desc
```

**Find Application Insights Traces:**
```kusto
traces
| where timestamp > ago(24h)
| where message contains 'app_insights'
| project timestamp, message, severityLevel
| order by timestamp desc
```

**Find All Custom Events:**
```kusto
customEvents
| where timestamp > ago(24h)
| project timestamp, name, customDimensions
| order by timestamp desc
```

**Find All Custom Metrics:**
```kusto
customMetrics
| where timestamp > ago(24h)
| project timestamp, name, value, customDimensions
| order by timestamp desc
```

### 2. LIVE METRICS - Real-time Data

**Purpose**: View real-time telemetry data
**Access**: Click "Live Metrics" in the left menu
**Data Latency**: Real-time (no delay)

**What to Look For:**
- Incoming requests
- Custom events being sent
- Performance metrics
- Error rates

### 3. OVERVIEW DASHBOARD - Summary Data

**Purpose**: View overall application health and performance
**Access**: Main dashboard (default view)

**Key Metrics:**
- Server response time
- Request rate
- Failed requests
- Availability

### 4. METRICS - Performance Data

**Purpose**: View performance metrics and custom metrics
**Access**: Click "Metrics" in the left menu

**What to Look For:**
- Custom metrics charts
- Performance indicators
- Error rates over time

## Expected Data Types

### Custom Events

**Event Names to Look For:**
- `detailed_test_event`
- `test_event`
- `conversation_processed`
- `case_created`
- `polling_cycle_completed`
- `rate_limit_hit`

**Example Event Data:**
```json
{
  "timestamp": "2025-08-27T15:14:53.349603+00:00",
  "name": "detailed_test_event",
  "customDimensions": {
    "test_type": "basic_event",
    "source": "detailed_debug_endpoint"
  }
}
```

### Custom Metrics

**Metric Names to Look For:**
- `detailed_test_metric`
- `test_metric`
- `cases_created_count`
- `conversations_processed`
- `api_calls_count`

**Example Metric Data:**
```json
{
  "timestamp": "2025-08-27T15:14:53.349603+00:00",
  "name": "detailed_test_metric",
  "value": 123.45,
  "customDimensions": {
    "test_type": "basic_metric",
    "source": "detailed_debug_endpoint"
  }
}
```

### Traces

**Trace Messages to Look For:**
- Application Insights initialization messages
- Telemetry sending confirmations
- Error messages related to telemetry

## Troubleshooting

### If No Data Appears

1. **Check Application Insights Status:**
   ```bash
   curl "{URL}"
   ```

2. **Send Test Telemetry:**
   ```bash
   curl "{URL}"
   ```

3. **Wait for Data Latency:**
   - Application Insights data takes 2-5 minutes to appear
   - Live Metrics shows real-time data immediately

4. **Check Time Range:**
   - Ensure the time range in Logs (Analytics) covers the expected data period
   - Use "Last 1 hour" or "Last 4 hours" for recent data

5. **Verify Configuration:**
   - Check that Application Insights is enabled
   - Verify connection string is correct
   - Ensure the application is sending telemetry

### Common Issues

**Issue**: No data in Logs (Analytics)
**Solution**: 
- Wait 2-5 minutes for data to appear
- Check Live Metrics for real-time data
- Verify telemetry is being sent

**Issue**: Data appears in Live Metrics but not Logs
**Solution**: 
- This is normal - Live Metrics shows real-time data
- Logs (Analytics) has a 2-5 minute delay

**Issue**: Can't find Application Insights resource
**Solution**: 
- Search for "Application Insights" in Azure Portal
- Look for "cody2zoho-insights" in your resources
- Check the resource group "{AZURE RESOURCE GROUP}"

## Best Practices

### Query Optimization

1. **Use Specific Time Ranges:**
   ```kusto
   | where timestamp > ago(1h)  // Last hour
   | where timestamp > ago(24h) // Last 24 hours
   ```

2. **Filter by Specific Sources:**
   ```kusto
   | where customDimensions.source == 'detailed_debug_endpoint'
   ```

3. **Order Results by Time:**
   ```kusto
   | order by timestamp desc
   ```

### Data Monitoring

1. **Set Up Alerts:**
   - Create alerts for high error rates
   - Monitor custom metrics thresholds
   - Set up availability alerts

2. **Create Dashboards:**
   - Build custom dashboards for key metrics
   - Include custom events and metrics
   - Monitor application health

3. **Export Queries:**
   - Save frequently used queries
   - Share queries with team members
   - Create query templates

## Quick Reference

### Direct Links

- **Application Insights Overview**: [Portal Link]({URL})
- **Logs (Analytics)**: [Portal Link]({URL}/logs)
- **Live Metrics**: [Portal Link](https://portal{URL}/liveMetrics)
- **Metrics**: [Portal Link](https{URL}/metrics)

### Test Commands

```bash
# Check Application Insights status
curl "{URL}/debug/app-insights"

# Send test telemetry
curl "{URL}/debug/test-telemetry-detailed"
```

### Key Data Tables

- **customEvents**: Custom events sent by the application
- **customMetrics**: Custom metrics and measurements
- **traces**: Application traces and log messages
- **requests**: HTTP requests to the application
- **exceptions**: Application exceptions and errors
- **dependencies**: External service calls and dependencies

## Success Indicators

You know Application Insights is working correctly when you see:

1. **Custom Events** appearing in the `customEvents` table
2. **Custom Metrics** appearing in the `customMetrics` table
3. **Traces** containing Application Insights related messages
4. **Live Metrics** showing real-time data flow
5. **Overview Dashboard** displaying application health metrics

## Data Retention

- **Application Insights data is retained for 90 days** by default
- **Custom events and metrics** are stored in Log Analytics
- **Performance data** is available for trend analysis
- **Historical data** can be queried using Kusto queries

## Additional Resources

- [Application Insights Documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
- [Kusto Query Language Reference](https://docs.microsoft.com/en-us/azure/data-explorer/kusto/query/)
- [Application Insights Troubleshooting](https://docs.microsoft.com/en-us/azure/azure-monitor/app/troubleshoot-faq)
- [Custom Events and Metrics](https://docs.microsoft.com/en-us/azure/azure-monitor/app/api-custom-events-metrics)

---

**Note**: This document is specific to the Cody2Zoho application. The Application Insights resource name, connection strings, and custom event names are specific to this deployment.
