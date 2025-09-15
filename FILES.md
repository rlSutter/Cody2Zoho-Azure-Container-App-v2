# Cody2Zoho Project - Complete File Inventory

## Overview

This document provides a complete inventory of all files in the Cody2Zoho project, organized by directory with brief descriptions of each file's purpose.

## Recent Enhancements

### Redis Deployment Management (Latest)
- **Interactive Redis Deployment**: Added user-friendly prompts for Redis instance management during deployment
- **Flexible Deployment Options**: Support for automatic Redis creation, existing instance usage, or complete Redis recreation
- **Deployment Script Parameters**: Enhanced `deploy_simple.ps1` and `deploy_azure_monitoring.ps1` with `-SkipRedisDeployment` parameter
- **Safety Features**: Confirmation prompts for destructive operations and clear warnings about data loss

### Enhanced Metrics and Monitoring
- **Cody Polling Metrics**: Added comprehensive tracking of Cody API polling operations with duration and conversation counts
- **Conversation-to-Case Ratio**: New metrics to track processing efficiency and duplicate detection effectiveness
- **Application Insights Integration**: Enhanced telemetry with business metrics and operational insights
- **Bug Fixes**: Corrected double-counting issues in conversation processing metrics

### Improved Documentation
- **Redis Deployment Guide**: Comprehensive documentation for Redis deployment options and scenarios
- **Interactive Prompts Documentation**: Detailed explanation of deployment prompts and user choices
- **Parameter Reference**: Complete reference for all deployment script parameters and use cases

## Root Directory

### Core Application Files
- **`README.md`** (62KB) - Main project documentation with comprehensive overview, features, setup instructions, usage guide, and Redis deployment options
- **`requirements.txt`** (212B) - Python dependencies list for the application
- **`Dockerfile`** (467B) - Docker container definition for building the application image
- **`env.template`** (1.8KB) - Template file for environment variables configuration
- **`LICENSE`** (1.0KB) - Project license information
- **`.gitignore`** (56B) - Git ignore rules for version control

### Configuration Files
- **`env-vars.yaml`** (1.3KB) - Environment variables for Azure Container App deployment

### Docker Configuration
- **`docker-compose.yml`** (306B) - Basic Docker Compose configuration for local development
- **`docker-compose.with-graylog.yml`** (3.5KB) - Docker Compose configuration with Graylog integration

## `/src` Directory - Core Application Code

### Main Application
- **`main.py`** (35KB) - Main application entry point with Flask server, polling logic, API endpoints, and enhanced conversation processing metrics
- **`config.py`** (8.1KB) - Application configuration management using Pydantic settings
- **`store.py`** (9.7KB) - Data storage and caching functionality using Redis with conversation tracking and token management

### Client Integrations
- **`cody_client.py`** (6.7KB) - Cody API client for fetching conversations and messages
- **`zoho_client.py`** (25KB) - Zoho CRM API client for creating cases, managing contacts, and duplicate checking with enhanced return values
- **`token_cli.py`** (2.1KB) - Command-line interface for token management

### Monitoring and Logging
- **`app_insights_handler.py`** (32KB) - Azure Application Insights integration for telemetry, monitoring, Cody polling metrics, and conversation-to-case ratio tracking
- **`graylog_handler.py`** (8.9KB) - Graylog integration for centralized logging

### Utilities
- **`transcript.py`** (2.3KB) - Conversation transcript processing and formatting utilities

## `/azure` Directory - Azure Deployment and Monitoring

### Core Deployment Scripts
- **`deploy_simple.ps1`** (16KB) - Main deployment script for Azure Container Apps with Docker build, push, and interactive Redis management
- **`deploy_azure_monitoring.ps1`** (9.5KB) - Enhanced deployment script with Application Insights, monitoring setup, and Redis deployment options
- **`refresh_tokens.ps1`** (9.5KB) - Zoho OAuth token refresh and management script

### Application Insights Scripts
- **`check_app_insights.ps1`** (4.6KB) - Application Insights configuration verification script
- **`check_app_insights_events.ps1`** (7.5KB) - Script to query and display Application Insights telemetry data
- **`enable_app_insights.ps1`** (2.9KB) - Script to enable Application Insights for existing deployments
- **`test_app_insights_local.ps1`** (4.4KB) - Local testing script for Application Insights setup
- **`test_app_insights_real.ps1`** (3.7KB) - Real Application Insights connection testing script

### Monitoring and Setup Scripts
- **`get_container_status.ps1`** (13KB) - Container app status monitoring and health check script
- **`setup_dashboards.ps1`** (21KB) - Azure dashboard creation and configuration script
- **`setup_app_insights_alerts.ps1`** (6.2KB) - Application Insights alert configuration script
- **`setup_log_analytics_queries.ps1`** (8.3KB) - Log Analytics query setup and configuration script

### Documentation
- **`README.md`** (9.6KB) - Azure-specific documentation and script usage guide
- **`DEBUGGING.md`** (17KB) - Comprehensive debugging guide for Azure Container Apps and Application Insights
- **`FINDING_APPLICATION_INSIGHTS_DATA.md`** (9.5KB) - Guide for locating and viewing Application Insights telemetry data
- **`BUSINESS_RULES_ANALYSIS.md`** (16.0KB) - Identifies and analyzes all business rules implemented or observed in the Cody2Zoho application

### `/azure/dashboards` Subdirectory
- **`deploy_dashboards.ps1`** (1.9KB) - Dashboard deployment automation script
- **`operations_dashboard.json`** (11KB) - Azure dashboard JSON template for operations monitoring
- **`performance_dashboard.json`** (11KB) - Azure dashboard JSON template for performance monitoring
- **`business_metrics_dashboard.json`** (12KB) - Azure dashboard JSON template for business metrics

### `/azure/log_analytics_queries` Subdirectory
- **`token_refresh_monitoring.kql`** (410B) - Kusto query for monitoring token refresh operations
- **`conversation_processing_details.kql`** (526B) - Kusto query for conversation processing analysis
- **`application_health_overview.kql`** (318B) - Kusto query for application health monitoring
- **`rate_limit_monitoring.kql`** (305B) - Kusto query for API rate limit monitoring
- **`business_metrics_dashboard.kql`** (749B) - Kusto query for business metrics dashboard
- **`api_performance.kql`** (329B) - Kusto query for API performance monitoring
- **`error_analysis.kql`** (269B) - Kusto query for error analysis and troubleshooting
- **`cases_created_today.kql`** (418B) - Kusto query for daily case creation tracking

## `/scripts` Directory - Local Development Scripts

### Execution Scripts
- **`run_local.py`** (5.7KB) - Python script for running the application locally
- **`run_local.bat`** (1.7KB) - Windows batch script for running the application locally
- **`run_local.sh`** (2.2KB) - Linux/Unix shell script for running the application locally

### Environment Scripts
- **`activate_cody2zoho.ps1`** (790B) - PowerShell script for activating the Cody2Zoho environment
- **`activate_cody2zoho.bat`** (596B) - Windows batch script for activating the Cody2Zoho environment

### Documentation
- **`README.md`** (7.1KB) - Scripts documentation and usage guide
- **`SCRIPTS_DOCUMENTATION.md`** (11KB) - Comprehensive scripts documentation

## `/graylog` Directory - Graylog Integration

### Core Files
- **`docker-compose.yml`** (2.7KB) - Docker Compose configuration for Graylog setup
- **`start_graylog.ps1`** (2.2KB) - PowerShell script to start Graylog services
- **`stop_graylog.ps1`** (1.1KB) - PowerShell script to stop Graylog services
- **`setup_remote_access.ps1`** (3.2KB) - PowerShell script for setting up remote access to Graylog

### Documentation
- **`README.md`** (10KB) - Graylog integration documentation and setup guide
- **`azure-container-apps-integration.md`** (15KB) - Graylog integration with Azure Container Apps documentation

## `/redis` Directory - Redis Integration

### Core Files
- **`docker-compose.dev.yml`** (426B) - Docker Compose configuration for Redis development environment
- **`start_redis.ps1`** (3.8KB) - PowerShell script to start Redis services
- **`stop_redis.ps1`** (699B) - PowerShell script to stop Redis services
- **`start_redis.bat`** (853B) - Windows batch script to start Redis services
- **`stop_redis.bat`** (458B) - Windows batch script to stop Redis services

### Documentation
- **`README.md`** (8.6KB) - Redis integration documentation and setup guide

## File Count Summary

### By Directory
- **Root**: 15 files
- **`/src`**: 11 files
- **`/azure`**: 19 files (including subdirectories)
- **`/scripts`**: 7 files
- **`/graylog`**: 6 files
- **`/redis`**: 6 files

### By Type
- **Python Files**: 47 files
- **PowerShell Scripts**: 15 files
- **Documentation Files**: 12 files
- **Configuration Files**: 8 files
- **JSON Files**: 7 files
- **Batch Files**: 4 files
- **Shell Scripts**: 2 files
- **YAML Files**: 2 files
- **KQL Files**: 8 files
- **Other**: 3 files

### Total Files: 108 files

## Key Features by File Category

### Deployment Scripts
- **Interactive Redis Management**: User-friendly prompts for Redis deployment decisions
- **Parameter Flexibility**: Multiple deployment options with command-line parameters
- **Safety Features**: Confirmation prompts and data loss warnings
- **Automation Support**: Non-interactive options for CI/CD pipelines

### Application Code
- **Enhanced Metrics**: Cody polling and conversation processing efficiency tracking
- **Improved Error Handling**: Better duplicate detection and case creation logic
- **Redis Integration**: Conversation tracking and token caching with fallback support
- **Application Insights**: Comprehensive telemetry and business metrics

### Documentation
- **Comprehensive Guides**: Detailed deployment and usage instructions
- **Interactive Examples**: Real-world scenarios and parameter combinations
- **Troubleshooting**: Debug guides and common issue resolution
- **API References**: Complete parameter and configuration documentation

## Notes

- Files marked as "historical" contain information that may be outdated but are kept for reference
- Backup files contain older versions of source code and should not be used for active development
- Some test files may be redundant and could be consolidated
- Documentation files may contain overlapping information that could be streamlined
- The `.venv/` directory is excluded from version control and contains the Python virtual environment

## Recent Updates (Latest Session)

### Enhanced Deployment Experience
- **Interactive Redis Prompts**: Deployment scripts now provide user-friendly prompts for Redis management decisions
- **Flexible Parameters**: Added `-SkipRedisDeployment` parameter for automated deployments
- **Safety Improvements**: Added confirmation prompts for destructive operations

### Improved Metrics and Monitoring
- **Cody Polling Tracking**: New metrics for monitoring Cody API polling performance
- **Processing Efficiency**: Conversation-to-case ratio metrics for business insights
- **Bug Fixes**: Corrected double-counting issues in conversation processing

### Documentation Enhancements
- **Comprehensive Redis Guide**: Detailed documentation for Redis deployment options
- **Parameter Reference**: Complete reference for all deployment script parameters
- **Usage Scenarios**: Real-world examples and best practices for different deployment scenarios
