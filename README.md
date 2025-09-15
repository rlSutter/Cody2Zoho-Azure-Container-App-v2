# 🚀 Cody2Zoho - Cody Conversations to Zoho CRM Cases

## 🎯 **Overview**

Cody2Zoho is a robust, production-ready application that automatically monitors Cody conversations and creates Zoho CRM Cases with conversation transcripts, metrics tracking, and optional note attachments. Built with modern Python practices, the application features automatic OAuth token refresh, comprehensive error handling, Redis-backed state management, and seamless integration with both Cody and Zoho CRM APIs.

The application is designed for high availability and scalability, supporting both local development and cloud deployment scenarios with comprehensive monitoring, logging, and management tools.

## ✨ **Key Features**

- 🔄 **Automatic Conversation Monitoring** - Continuously polls Cody for new conversations with configurable intervals
- 📋 **Case Creation** - Creates Zoho CRM Cases with full conversation transcripts and metadata
- 📊 **Metrics Tracking** - Calculates and stores conversation metrics in custom case fields
- 🔐 **OAuth Integration** - Secure authentication with automatic token refresh and rate limiting
- 🗂️ **Optional Notes** - Attach conversation transcripts as notes on cases
- 🏗️ **Docker Support** - Containerized deployment with Docker Compose and multi-stage builds
- ☁️ **Azure Integration** - Complete Azure Container Apps deployment with flexible Redis management
- 📈 **Application Insights** - Comprehensive telemetry and monitoring with Azure Application Insights
- 🧪 **Comprehensive Testing** - Multiple OAuth testing tools and utilities
- 📝 **Detailed Logging** - Comprehensive logging for monitoring and debugging
- 🔄 **State Management** - Redis-backed conversation tracking with in-memory fallback
- 🏥 **Health Monitoring** - Built-in health checks and metrics endpoints
- 🚀 **Graceful Shutdown** - Proper signal handling and resource cleanup

## 🏗️ **Architecture Overview**

### **System Architecture**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Cody API      │    │   Cody2Zoho     │    │   Zoho CRM      │
│                 │    │   Application   │    │                 │
│ • Conversations │◄──►│ • Polling Loop  │◄──►│ • Cases API     │
│ • Messages      │    │ • OAuth Client  │    │ • OAuth         │
│ • Transcripts   │    │ • State Store   │    │ • Token Mgmt    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   Redis Store   │
                       │                 │
                       │ • Conversation  │
                       │   Tracking      │
                       │ • Token Cache   │
                       │ • Metrics       │
                       └─────────────────┘
```

### **Component Architecture**

#### **1. Core Application (`src/main.py`)**
- **Polling Engine**: Configurable interval-based conversation monitoring
- **Flask Server**: HTTP endpoints for health checks, metrics, and logs
- **Signal Handling**: Graceful shutdown with SIGTERM/SIGINT support
- **Threading**: Concurrent polling and HTTP server operations
- **Startup Management**: Robust initialization with timeout protection

#### **2. Cody Integration (`src/cody_client.py`)**
- **API Client**: RESTful communication with Cody API
- **Conversation Fetching**: Retrieves conversations with pagination support
- **Message Processing**: Extracts and formats conversation messages
- **Error Handling**: Retry logic with exponential backoff
- **Rate Limiting**: Respects API rate limits

#### **3. Zoho Integration (`src/zoho_client.py`)**
- **OAuth 2.0 Client**: Complete OAuth flow implementation
- **Token Management**: Automatic refresh with caching and rate limiting
- **Case Creation**: Creates Zoho CRM cases with custom fields
- **Transcript Formatting**: Formats conversations for CRM storage
- **Error Recovery**: Handles API errors and token expiration

#### **4. State Management (`src/store.py`)**
- **Redis Integration**: Primary state storage with connection pooling
- **In-Memory Fallback**: Graceful degradation when Redis unavailable
- **Conversation Tracking**: Prevents duplicate case creation
- **Token Caching**: Secure token storage with expiration
- **Metrics Storage**: Performance and usage metrics

#### **5. Configuration (`src/config.py`)**
- **Environment Loading**: Flexible configuration from multiple sources
- **Validation**: Ensures required settings are present
- **Defaults**: Sensible defaults for development and production
- **Security**: Handles sensitive configuration securely

#### **6. Transcript Processing (`src/transcript.py`)**
- **Message Formatting**: Converts raw messages to readable format
- **Metadata Extraction**: Extracts conversation metadata
- **Length Management**: Handles long conversations appropriately
- **Custom Fields**: Maps conversation data to CRM fields

### **Data Flow**

```
1. Polling Loop
   ├── Fetch conversations from Cody API
   ├── Check Redis for processed conversations
   ├── Filter new/unprocessed conversations
   └── Queue for processing

2. Conversation Processing
   ├── Fetch detailed messages for conversation
   ├── Format transcript with metadata
   ├── Check Zoho token validity/refresh if needed
   └── Create Zoho CRM case

3. State Management
   ├── Mark conversation as processed in Redis
   ├── Update metrics and counters
   ├── Cache tokens for future use
   └── Log processing results

4. Monitoring
   ├── Update health check status
   ├── Record metrics for monitoring
   ├── Log activities for debugging
   └── Respond to HTTP endpoints
```

## 📁 **Directory Structure**

```
Cody2Zoho/
├── 📁 src/                          # Main application source code
│   ├── 🐍 main.py                   # Application entry point and orchestration
│   ├── 🐍 cody_client.py            # Cody API integration client
│   ├── 🐍 zoho_client.py            # Zoho CRM API integration with OAuth
│   ├── 🐍 config.py                 # Configuration management and validation
│   ├── 🐍 store.py                  # Redis and in-memory state management
│   ├── 🐍 transcript.py             # Conversation transcript formatting
│   ├── 🐍 app_insights_handler.py   # Azure Application Insights telemetry
│   └── 🐍 token_cli.py              # Command-line token management tool
│
├── 📁 tests/                        # Testing and debugging scripts
│   ├── 🧪 test_zoho_oauth_enhanced.py    # Comprehensive OAuth testing
│   ├── 🧪 test_auto_refresh.py           # Automatic token refresh testing
│   ├── 🧪 test_token_management.py       # Token management testing
│   ├── 🧪 generate_tokens.py             # Token generation utility
│   ├── 🧪 generate_new_tokens.py         # Enhanced token generation
│   ├── 🧪 test_store_init.py             # Redis store initialization testing
│   ├── 🧪 test_redis.py                  # Redis connection testing
│   ├── 🧪 debug_main.py                  # Main function execution testing
│   ├── 🧪 test_main_simple.py            # Simple main function testing
│   ├── 🧪 test_logging.py                # Logging handler testing
│   ├── 🧪 debug_zoho_api.py              # Zoho API debugging
│   ├── 🧪 test_zoho_refresh.py           # Zoho refresh token testing
│   ├── 🧪 test_full_app.py               # Full application testing
│   ├── 🧪 test_duplicate_checking.py     # Duplicate checking testing
│   ├── 🧪 test_app_insights_integration.py # Application Insights testing
│   ├── 🧪 test_graylog_integration.py    # Graylog integration testing
│   ├── 🧪 test_cody_client.py            # Cody client testing
│   ├── 🧪 test_zoho_client.py            # Zoho client testing
│   ├── 🧪 test_zoho_client_simple.py     # Simple Zoho client testing
│   ├── 🧪 test_zoho_client_retry.py      # Zoho client retry testing
│   ├── 🧪 test_zoho_case_search.py       # Zoho case search testing
│   ├── 🧪 test_zoho_oauth.py             # Basic Zoho OAuth testing
│   ├── 🧪 oauth_callback_server.py       # OAuth callback server
│   ├── 🧪 test_full_integration.py       # Full integration testing
│   ├── 🧪 test_app_startup.py            # Application startup testing
│   ├── 🧪 test_components.py             # Component testing
│   ├── 🧪 test_settings.py               # Settings testing
│   ├── 🧪 test_import.py                 # Import testing
│   ├── 🧪 test_smoke.py                  # Smoke testing
│   ├── 🧪 test_minimal_main.py           # Minimal main testing
│   ├── 🧪 test_standalone.py             # Standalone testing
│   ├── 🧪 test_token_fix.py              # Token fix testing
│   ├── 🧪 check_docker.py                # Docker environment testing
│   ├── 🧪 test_flask_startup.py          # Flask startup testing
│   ├── 🧪 test_token.py                  # Token debugging
│   ├── 📄 TESTS_DOCUMENTATION.md         # Tests documentation
│   ├── 📄 TOKEN_MANAGEMENT_IMPROVEMENTS.md # Token management guide
│   ├── 📄 CODY_CLIENT_TEST_SUMMARY.md    # Cody client test summary
│   ├── 📄 ZOHO_CLIENT_TEST_SUMMARY.md    # Zoho client test summary
│   ├── 📄 CONTAINER_DEBUG_SCRIPTS.md     # Debug scripts documentation
│   ├── 📄 IMPORT_PATH_FIXES.md           # Import path fixes
│   ├── 📄 IMPORT_PATH_UPDATES.md         # Import path documentation
│   ├── 📄 TEST_FILES_MOVED_SUMMARY.md    # Test organization summary
│   └── 📄 README.md                      # Tests folder documentation
│
├── 📁 docs/                         # Project documentation
│   ├── 📄 README.md                 # Documentation index
│   ├── 📄 DEBUG_SUMMARY.md          # Azure deployment debug summary
│   ├── 📄 LOCAL_DEBUG_SUMMARY.md    # Local development debug summary
│   ├── 📄 FINAL_TEST_RESULTS.md     # Final test results
│   ├── 📄 TEST_RESULTS.md           # Comprehensive test results
│   ├── 📄 AZURE_DEPLOYMENT_TEST_RESULTS.md  # Azure deployment results
│   ├── 📄 ZOHO_DUPLICATE_CHECKING.md      # Duplicate checking guide
│   ├── 📄 APPLICATION_INSIGHTS_INTEGRATION.md # Application Insights guide
│   └── 📄 BUSINESS_RULES_ANALYSIS.md      # Business rules analysis
│
├── 📁 scripts/                      # Utility scripts
│   ├── 🚀 run_local.py              # Local development runner
│   ├── 🚀 run_local.sh              # Unix/Linux/macOS local runner
│   ├── 🚀 run_local.bat             # Windows local runner
│   ├── 🔧 activate_cody2zoho.ps1    # PowerShell environment activation
│   ├── 🔧 activate_cody2zoho.bat    # Batch environment activation
│   ├── 📄 SCRIPTS_DOCUMENTATION.md  # Scripts documentation
│   ├── 📄 RUN_SCRIPTS_FIXES.md      # Script fixes documentation
│   └── 📄 README.md                 # Scripts folder documentation
│
├── 📁 redis/                        # Redis management and configuration
│   ├── 🔧 start_redis.ps1           # PowerShell Redis start script
│   ├── 🔧 stop_redis.ps1            # PowerShell Redis stop script
│   ├── 🔧 start_redis.bat           # Batch Redis start script
│   ├── 🔧 stop_redis.bat            # Batch Redis stop script
│   ├── 🐳 docker-compose.dev.yml    # Redis Docker Compose configuration
│   ├── 📄 REDIS_SETUP.md            # Redis setup documentation
│   └── 📄 README.md                 # Redis folder documentation
│
├── 📁 graylog/                      # Graylog centralized logging
│   ├── 🐳 docker-compose.yml        # Graylog Docker Compose configuration
│   ├── 🔧 start_graylog.ps1         # PowerShell Graylog start script
│   ├── 🔧 stop_graylog.ps1          # PowerShell Graylog stop script
│   ├── 🔧 setup_remote_access.ps1   # Remote access setup script
│   ├── 📄 README.md                 # Graylog folder documentation
│   ├── 📄 INTEGRATION_SUMMARY.md    # Graylog integration summary
│   └── 📄 azure-container-apps-integration.md # Azure integration guide
│
├── 📁 azure/                        # Azure deployment and monitoring
│   ├── 🚀 deploy_simple.ps1         # Main Azure Container Apps deployment (with optional Redis management)
│   ├── 🚀 deploy_azure_monitoring.ps1    # Azure monitoring deployment (with optional Redis management)
│   ├── 📊 check_app_insights.ps1         # Application Insights status checker
│   ├── 🔧 app_insights_workaround.ps1    # Comprehensive AI troubleshooting
│   ├── 📊 check_app_insights_events.ps1  # Application Insights events checker
│   ├── 🧪 test_app_insights_local.ps1    # Local Application Insights testing
│   ├── 🧪 test_app_insights_real.ps1     # Real Application Insights testing
│   ├── 📊 setup_dashboards.ps1           # Dashboard setup script
│   ├── 📊 setup_app_insights_alerts.ps1  # Alerts setup script
│   ├── 📊 setup_log_analytics_queries.ps1 # Log Analytics queries setup
│   ├── 🔄 refresh_tokens.ps1             # Token refresh script
│   ├── 🔧 enable_app_insights.ps1        # Application Insights enablement
│   ├── 📊 get_container_status.ps1       # Container monitoring and metrics
│   ├── 📄 DEBUGGING.md                   # Comprehensive debugging guide
│   ├── 📄 FINDING_APPLICATION_INSIGHTS_DATA.md # AI data location guide
│   └── 📄 README.md                      # Azure folder documentation
│
├── 📁 backup/                       # Backup files for recovery
│   ├── 📄 BACKUP_INFO.md            # Backup information
│   ├── 📁 src/                      # Backup of source files
│   └── 📁 tests/                    # Backup of test files
│
├── 🐳 docker-compose.yml            # Main application Docker configuration
├── 🐳 docker-compose.with-graylog.yml # Docker Compose with Graylog integration
├── 🐳 Dockerfile                    # Multi-stage application container
├── 🐳 containerapp.yaml             # Azure Container App configuration
├── 📄 requirements.txt              # Python dependencies
├── 📄 env.template                  # Environment configuration template
├── 📄 env-vars.yaml                 # Azure Container App environment variables
├── 📄 azure-deployment-info.json    # Azure deployment information
├── 📄 .env                          # Environment configuration (create from template)
├── 📄 .gitignore                    # Git ignore patterns
├── 📄 LICENSE                       # MIT License
├── 📄 FILES.md                      # Complete file inventory
├── 📄 BUSINESS_RULES_ANALYSIS.md    # Business rules analysis
└── 📄 README.md                     # This comprehensive documentation
```

### **Key File Descriptions**

#### **Core Application Files**
- **`src/main.py`**: Application orchestrator with polling loop, Flask server, and signal handling
- **`src/cody_client.py`**: Cody API client with conversation and message retrieval
- **`src/zoho_client.py`**: Zoho CRM client with OAuth 2.0 and case management
- **`src/store.py`**: Redis and in-memory state management with fallback
- **`src/config.py`**: Configuration management with environment variable loading
- **`src/transcript.py`**: Conversation transcript formatting and metadata extraction
- **`src/app_insights_handler.py`**: Azure Application Insights telemetry and monitoring

#### **Testing and Debugging**
- **`tests/test_zoho_oauth_enhanced.py`**: Comprehensive OAuth testing with interactive flow
- **`tests/generate_new_tokens.py`**: Enhanced token generation with proper path handling

- **`tests/debug_main.py`**: Main function execution testing with timeout protection

#### **Infrastructure**
- **`docker-compose.yml`**: Production Docker Compose configuration
- **`docker-compose.with-graylog.yml`**: Docker Compose with Graylog integration
- **`Dockerfile`**: Multi-stage container build with optimization
- **`containerapp.yaml`**: Azure Container App configuration
- **`env-vars.yaml`**: Azure Container App environment variables
- **`azure-deployment-info.json`**: Azure deployment information
- **`redis/docker-compose.dev.yml`**: Local Redis development setup
- **`azure/deploy_simple.ps1`**: Azure Container Apps deployment script
- **`azure/deploy_azure_monitoring.ps1`**: Azure monitoring deployment
- **`azure/setup_dashboards.ps1`**: Application Insights dashboard setup
- **`azure/setup_app_insights_alerts.ps1`**: Application Insights alerts configuration

#### **Documentation**
- **`docs/README.md`**: Comprehensive documentation index
- **`docs/DEBUG_SUMMARY.md`**: Azure deployment troubleshooting guide
- **`docs/LOCAL_DEBUG_SUMMARY.md`**: Local development troubleshooting guide
- **`docs/ZOHO_DUPLICATE_CHECKING.md`**: Duplicate checking implementation guide
- **`docs/APPLICATION_INSIGHTS_INTEGRATION.md`**: Application Insights integration guide
- **`BUSINESS_RULES_ANALYSIS.md`**: Comprehensive business rules analysis
- **`FILES.md`**: Complete file inventory and descriptions

#### **Utility Scripts**
- **`scripts/run_local.py`**: Cross-platform local development runner
- **`scripts/activate_cody2zoho.ps1`**: PowerShell environment activation
- **`scripts/activate_cody2zoho.bat`**: Batch environment activation
- **`scripts/README.md`**: Scripts folder documentation

#### **Infrastructure Management**
- **`redis/start_redis.ps1`**: PowerShell Redis container management
- **`graylog/start_graylog.ps1`**: PowerShell Graylog container management
- **`azure/get_container_status.ps1`**: Azure container monitoring and metrics
- **`azure/check_app_insights.ps1`**: Application Insights status verification
- **`azure/app_insights_workaround.ps1`**: Comprehensive Application Insights troubleshooting
- **`azure/check_app_insights_events.ps1`**: Application Insights telemetry verification
- **`azure/test_app_insights_local.ps1`**: Local Application Insights testing
- **`azure/test_app_insights_real.ps1`**: Real Application Insights testing

## 🚀 **Execution Options**

Cody2Zoho supports three distinct execution environments, each optimized for different use cases and monitoring requirements.

### **1. Local Development Execution**

**Use Case**: Development, debugging, and testing with direct access to logs and immediate feedback.

**Prerequisites**:
- Python 3.11+
- Redis (optional, for state management)
- Zoho Developer Account with OAuth app configured
- Cody API access with valid credentials

**Setup**:
```bash
# Clone the repository
git clone <repository-url>
cd Cody2Zoho

# Copy environment template
cp env.template .env

# Edit .env with your credentials
# See Configuration section below

# Run enhanced OAuth test to get tokens
python tests/test_zoho_oauth_enhanced.py
```

**Execution**:
```bash
# Windows
scripts\run_local.bat

# Unix/Linux/macOS
./scripts/run_local.sh

# Or directly with Python
python scripts/run_local.py
```

**Monitoring**: Direct console output and log files
**Health Check**: `http://localhost:8080/health`
**Stop**: Press `Ctrl+C` in terminal

### **2. Docker Desktop Testing Environment**

**Use Case**: Testing environment with centralized logging and monitoring using Graylog. This environment mirrors production architecture for testing purposes.

**Prerequisites**:
- Docker Desktop
- Docker Compose
- Zoho Developer Account with OAuth app configured
- Cody API access with valid credentials

**Setup**:
```bash
# Clone the repository
git clone <repository-url>
cd Cody2Zoho

# Copy environment template
cp env.template .env

# Edit .env with your credentials
# Configure Graylog integration for testing environment
ENABLE_GRAYLOG=true
GRAYLOG_HOST=localhost
GRAYLOG_PORT=12201
```

**Execution**:
```bash
# Start complete stack (Application + Redis + Graylog)
docker-compose -f docker-compose.with-graylog.yml up -d

# Check all services are running
docker-compose -f docker-compose.with-graylog.yml ps

# View application logs
docker-compose -f docker-compose.with-graylog.yml logs app

# View Graylog logs
docker-compose -f docker-compose.with-graylog.yml logs graylog
```

**Monitoring**: Graylog web interface at `http://localhost:9000`
**Health Check**: `http://localhost:8080/health`
**Stop**: `docker-compose -f docker-compose.with-graylog.yml down`

### **3. Azure Container App Production Environment**

**Use Case**: Production deployment with enterprise-grade monitoring using Azure Application Insights and separate Redis container.

**Prerequisites**:
- Azure subscription
- Azure CLI installed and authenticated
- Azure Container Registry
- Zoho Developer Account with OAuth app configured
- Cody API access with valid credentials

**Setup**:
```bash
# Clone the repository
git clone <repository-url>
cd Cody2Zoho

# Copy environment template
cp env.template .env

# Edit .env with your credentials
# Azure-specific configuration will be set during deployment
```

**Execution**:
```bash
# Deploy to Azure Container App with Application Insights and Redis
.\azure\deploy_azure_monitoring.ps1

# Check deployment status
.\azure\get_container_status.ps1

# Monitor Application Insights
.\azure\check_app_insights.ps1
```

**Monitoring**: Azure Application Insights portal
**Health Check**: `https://your-app-url/health`
**Stop**: Use Azure Portal or `az containerapp update` commands

## 📊 **Graylog Integration (Docker Desktop Only)**

Graylog integration provides centralized log management exclusively for the Docker Desktop execution environment. Graylog offers a powerful web interface for searching, analyzing, and monitoring application logs with structured data support. This integration is not available for Azure Container App deployments.

### **Graylog Features**
- 🔍 **Centralized Logging** - All application logs in one place
- 📊 **Real-time Search** - Search logs with powerful query language
- 📈 **Dashboards** - Create custom dashboards for monitoring
- 🚨 **Alerts** - Set up alerts for specific log patterns
- 🔄 **GELF Support** - Structured logging with metadata

### **Graylog Stack Management**

#### **Complete Stack (Application + Graylog)**
```bash
# Start the complete stack including Cody2Zoho, Redis, and Graylog
docker-compose -f docker-compose.with-graylog.yml up -d

# Check all services are running
docker-compose -f docker-compose.with-graylog.yml ps

# View application logs
docker-compose -f docker-compose.with-graylog.yml logs app

# View Graylog logs
docker-compose -f docker-compose.with-graylog.yml logs graylog
```

#### **Graylog Only (for existing application)**
```bash
# Start just the Graylog stack
cd graylog
docker-compose up -d

# Check Graylog services
docker-compose ps

# Access Graylog web interface
# Open http://localhost:9000 in your browser
# Username: admin
# Password: admin
```

### **Stopping the Complete Stack**

#### **Option A: Stop Full Stack**
```bash
# Stop all services (Cody2Zoho, Redis, Graylog, MongoDB, Elasticsearch)
docker-compose -f docker-compose.with-graylog.yml down

# Verify all containers are stopped
docker-compose -f docker-compose.with-graylog.yml ps
```

#### **Option B: Stop Graylog Only**
```bash
# Stop just the Graylog stack
cd graylog
docker-compose down

# Verify Graylog containers are stopped
docker-compose ps
```

### **Graylog Access and Configuration**

#### **Web Interface Access**
- **URL**: `http://localhost:9000`
- **Username**: `admin`
- **Password**: `admin`
- **Default Port**: 9000

#### **GELF Input Configuration**
After logging into Graylog, configure a GELF input:

1. **Navigate to**: System → Inputs
2. **Select**: GELF UDP
3. **Configure**:
   - **Title**: `Cody2Zoho Logs`
   - **Port**: `12201`
   - **Bind Address**: `0.0.0.0`
4. **Launch Input**

#### **Searching Logs**
- **Query**: `application:cody2zoho`
- **Time Range**: Select appropriate time range
- **Fields**: Use structured fields for filtering

### **Graylog Management Scripts**

#### **PowerShell Scripts (Windows)**
```powershell
# Start Graylog stack
.\graylog\start_graylog.ps1

# Stop Graylog stack
.\graylog\stop_graylog.ps1

# Configure remote access
.\graylog\setup_remote_access.ps1
```

#### **Manual Commands**
```bash
# Start Graylog stack
cd graylog
docker-compose up -d

# Stop Graylog stack
cd graylog
docker-compose down

# View Graylog logs
cd graylog
docker-compose logs -f graylog

# Restart Graylog only
cd graylog
docker-compose restart graylog
```

### **Graylog Data Persistence**
- **MongoDB Data**: Stored in `mongodb_data` volume
- **Elasticsearch Data**: Stored in `elasticsearch_data` volume
- **Graylog Data**: Stored in `graylog_data` volume
- **Data Location**: Docker volumes persist across container restarts

### **Troubleshooting Graylog**

#### **Common Issues**
1. **Graylog not accessible**: Check if containers are running
2. **Elasticsearch connection issues**: Verify Elasticsearch is healthy
3. **MongoDB connection issues**: Check MongoDB container status
4. **Port conflicts**: Ensure ports 9000, 12201, 12202 are available

#### **Debugging Steps**
```bash
# Check all container statuses
docker-compose -f docker-compose.with-graylog.yml ps

# View Graylog logs
docker-compose -f docker-compose.with-graylog.yml logs graylog

# View Elasticsearch logs
docker-compose -f docker-compose.with-graylog.yml logs elasticsearch

# View MongoDB logs
docker-compose -f docker-compose.with-graylog.yml logs mongodb

# Test Graylog connectivity
curl http://localhost:9000
```

## 🚀 **Execution Management Reference**

This section provides comprehensive management commands for each of the three execution environments.

### **Quick Reference Commands**

#### **Local Development Execution**
```bash
# Start
python scripts/run_local.py

# Stop
# Press Ctrl+C in terminal

# Status
curl http://localhost:8080/health

# Logs
# Direct console output
```

#### **Docker Desktop with Graylog**
```bash
# Start Complete Stack
docker-compose -f docker-compose.with-graylog.yml up -d

# Start Graylog Only
cd graylog && docker-compose up -d

# Stop Complete Stack
docker-compose -f docker-compose.with-graylog.yml down

# Stop Graylog Only
cd graylog && docker-compose down

# Status
docker-compose -f docker-compose.with-graylog.yml ps

# Logs
docker-compose -f docker-compose.with-graylog.yml logs app
docker-compose -f docker-compose.with-graylog.yml logs graylog
```

#### **Azure Container App Production Environment**
```bash
# Deploy
.\azure\deploy_azure_monitoring.ps1

# Status
.\azure\get_container_status.ps1

# Application Insights
.\azure\check_app_insights.ps1
.\azure\check_app_insights_events.ps1

# Stop
# Use Azure Portal or Azure CLI
az containerapp update --name cody2zoho --resource-group ASEV-OpenAI --image asecontainerregistry.azurecr.io/cody2zoho:latest

# Note: Graylog is not available for Azure Container App deployments
```

### **Environment-Specific Management**

#### **Local Development Environment**
- **Use Case**: Development, debugging, testing
- **Monitoring**: Console output and log files
- **Scaling**: Single instance
- **Persistence**: Local file system
- **Networking**: Localhost only

#### **Docker Desktop Testing Environment**
- **Use Case**: Testing environment with centralized logging
- **Monitoring**: Graylog web interface at `http://localhost:9000` (local only)
- **Scaling**: Docker Compose services
- **Persistence**: Docker volumes
- **Networking**: Local Docker network
- **Note**: Graylog is only available for local Docker Desktop deployment

#### **Azure Container App Production Environment**
- **Use Case**: Production deployment with enterprise monitoring
- **Monitoring**: Azure Application Insights portal
- **Scaling**: Azure Container App scaling rules
- **Persistence**: Azure Storage and Redis
- **Networking**: Azure networking with ingress
- **Note**: Graylog is not available for Azure Container App deployments

## 📊 **Azure Application Insights Integration**

Azure Application Insights provides comprehensive telemetry and monitoring capabilities for the Azure Container App execution environment, offering real-time visibility into application performance, business metrics, and operational health.

### **🎯 Application Insights Features**

#### **Core Telemetry**
- **Custom Events**: Business operations, API calls, and user actions
- **Custom Metrics**: Performance data, business metrics, and system health
- **Traces**: Application flow and debugging information
- **Exceptions**: Error tracking and monitoring
- **Dependencies**: External service calls and performance monitoring

#### **Business Metrics Tracking**
- **Case Creation**: Number of cases created per polling cycle
- **API Performance**: Response times for Cody and Zoho API calls
- **Token Management**: OAuth token refresh frequency and success rates
- **Rate Limiting**: API rate limit hits and backoff periods
- **Polling Cycles**: Polling cycle completion and processing times

#### **Performance Monitoring**
- **Request/Response Timing**: API call performance metrics
- **Memory Usage**: Application memory consumption
- **Error Rates**: Exception and error frequency
- **Throughput**: Processing capacity and efficiency

### **🔧 Application Insights Configuration**

#### **Environment Variables**
```bash
# Enable Application Insights
ENABLE_APPLICATION_INSIGHTS=true

# Application Insights Connection String
APPLICATIONINSIGHTS_CONNECTION_STRING=InstrumentationKey=your-key;IngestionEndpoint=https://eastus-8.in.applicationinsights.azure.com/;LiveEndpoint=https://eastus.livediagnostics.monitor.azure.com/

# Application Role Name
APPLICATIONINSIGHTS_ROLE_NAME=Cody2Zoho
```

#### **Python Dependencies**
```python
# Required packages in requirements.txt
opencensus-ext-azure==1.1.8
opencensus-ext-flask>=0.8.0
opencensus-ext-logging==0.1.0
```

### **📈 Telemetry Implementation**

#### **Application Insights Handler (`src/app_insights_handler.py`)**
```python
class ApplicationInsightsHandler:
    def __init__(self, connection_string: str, role_name: str = "Cody2Zoho"):
        # Initialize Azure Application Insights integration
        self.connection_string = connection_string
        self.role_name = role_name
        self.logger = None
        self.business_metrics = {
            "cases_created": 0,
            "api_calls": 0,
            "token_refreshes": 0,
            "rate_limit_hits": 0,
            "polling_cycles": 0
        }
    
    def log_event(self, event_name: str, properties: Dict[str, Any] = None):
        # Log custom events to Application Insights
        
    def log_metric(self, metric_name: str, value: float, properties: Dict[str, Any] = None):
        # Log custom metrics to Application Insights
        
    def track_case_creation(self, case_id: str, contact_name: str):
        # Track case creation business metric
        
    def track_api_call(self, api_name: str, duration: float, success: bool):
        # Track API call performance
        
    def track_token_refresh(self, success: bool, duration: float):
        # Track OAuth token refresh operations
        
    def track_rate_limit(self, api_name: str, retry_after: int):
        # Track API rate limiting events
        
    def track_polling_cycle(self, conversations_processed: int, duration: float):
        # Track polling cycle completion
```

#### **Business Metrics Tracking**
```python
# Case creation tracking
app_insights.track_case_creation(case_id="12345", contact_name="John Doe")

# API call performance
app_insights.track_api_call(api_name="cody_conversations", duration=1.23, success=True)

# Token refresh monitoring
app_insights.track_token_refresh(success=True, duration=0.5)

# Rate limit tracking
app_insights.track_rate_limit(api_name="zoho_crm", retry_after=60)

# Polling cycle completion
app_insights.track_polling_cycle(conversations_processed=5, duration=30.5)
```

### **🔍 Debug and Testing Endpoints**

#### **Application Insights Status**
```bash
# Check Application Insights configuration
curl https://your-app-url/debug/app-insights

# Response includes:
{
    "app_insights_configured": true,
    "app_insights_initialized": true,
    "connectivity": {
        "direct_api": true,
        "ingestion_endpoint": true,
        "live_endpoint": true
    },
    "settings": {
        "APPLICATIONINSIGHTS_CONNECTION_STRING": "SET",
        "APPLICATIONINSIGHTS_ROLE_NAME": "Cody2Zoho",
        "ENABLE_APPLICATION_INSIGHTS": true
    }
}
```

#### **Telemetry Testing**
```bash
# Test basic telemetry
curl https://your-app-url/debug/test-telemetry

# Test detailed telemetry
curl https://your-app-url/debug/test-telemetry-detailed

# Response includes:
{
    "status": "completed",
    "tests": {
        "basic_event": "success",
        "basic_metric": "success",
        "direct_api": "success",
        "force_flush": "success"
    }
}
```

### **📊 Azure Portal Monitoring**

#### **Application Insights Dashboard**
1. **Overview Tab**: Server response time, failed requests, request rate
2. **Live Metrics**: Real-time telemetry data (no latency)
3. **Logs (Analytics)**: Custom queries for telemetry data
4. **Metrics**: Custom metrics and performance data

#### **Key Kusto Queries**
```kusto
// Custom events
customEvents
| where timestamp > ago(1h)
| order by timestamp desc

// Application traces
traces
| where timestamp > ago(1h)
| where message contains 'app_insights'
| order by timestamp desc

// Custom metrics
customMetrics
| where timestamp > ago(1h)
| where name == 'test_metric'
| order by timestamp desc

// Business metrics
customEvents
| where name == 'case_created'
| summarize count() by bin(timestamp, 1h)
```

### **🚀 Deployment with Application Insights**

#### **Azure Container Apps Deployment**
```bash
# Deploy with Basic Application Insights enabled
.\azure\deploy_simple.ps1

# Deploy with Advanced Application Insights monitoring features
.\azure\deploy_azure_monitoring.ps1
```

#### **Local Development**
```bash
# Set environment variables
export ENABLE_APPLICATION_INSIGHTS=false
export APPLICATIONINSIGHTS_CONNECTION_STRING="your-connection-string"
export APPLICATIONINSIGHTS_ROLE_NAME="Cody2Zoho"

# Start application
python scripts/run_local.py
```

### **📈 Monitoring Scripts**

#### **Application Insights Verification**
```bash
# Check Application Insights status
.\azure\check_app_insights.ps1

# Check for telemetry events
.\azure\check_app_insights_events.ps1

# Portal verification guide

```

#### **Testing Scripts**
```bash
# Test Application Insights locally
.\azure\test_app_insights_local.ps1

# Test with real connection string
.\azure\test_app_insights_real.ps1
```

### **🔧 Troubleshooting Application Insights**

#### **Common Issues**
1. **No data in Azure Portal**: Check data latency (5-15 minutes)
2. **Connection string issues**: Verify instrumentation key format
3. **Import errors**: Ensure opencensus packages are installed
4. **Telemetry not sending**: Check network connectivity

#### **Debug Steps**
```bash
# 1. Check Application Insights status
curl https://your-app-url/debug/app-insights

# 2. Test telemetry sending
curl https://your-app-url/debug/test-telemetry-detailed

# 3. Check container logs
az containerapp logs show --name cody2zoho --resource-group your-resource-group

# 4. Verify Azure Portal
# Open Application Insights in Azure Portal and check Live Metrics
```

#### **Data Latency**
- **Live Metrics**: Real-time (no latency)
- **Logs (Analytics)**: 5-15 minutes
- **Overview Charts**: 5-15 minutes
- **Custom Metrics**: 5-15 minutes

### **📋 Application Insights Benefits**

1. **Real-time Monitoring**: Live metrics and immediate visibility
2. **Business Intelligence**: Track case creation and API performance
3. **Performance Optimization**: Identify bottlenecks and slow operations
4. **Error Tracking**: Monitor exceptions and failures
5. **Capacity Planning**: Understand usage patterns and trends
6. **Operational Health**: Proactive monitoring and alerting

## ☁️ **Azure Deployment Options**

### **Architecture with Azure Container Apps**
```
┌────────────────────────────────────────────────────────┐
│                Azure Container Apps                    │
│  ┌─────────────────┐  ┌─────────────────┐              │
│  │  Cody2Zoho App  │  │   Graylog App   │              │
│  │  (Container)    │  │  (Container)    │              │
│  └─────────────────┘  └─────────────────┘              │
│           │                      │                     │
│           └──────────────────────┼─────────────────────┘
│                                  │                     |
│  ┌─────────────────┐  ┌─────────────────┐              │
│  │   Redis Cache   │  │  Azure Storage  │              │
│  │   (Managed)     │  │  (Graylog Data) │              │
│  └─────────────────┘  └─────────────────┘              │
└────────────────────────────────────────────────────────┘
```

### **Benefits of Azure Container Apps**
- ✅ **Multi-Container Support**: Run multiple containers in one app
- ✅ **Managed Redis**: Use Azure Cache for Redis
- ✅ **Persistent Storage**: Azure Storage integration
- ✅ **Auto-scaling**: Automatic scaling based on demand
- ✅ **Built-in Monitoring**: Application Insights integration
- ✅ **Dapr Support**: Distributed application runtime

### **Azure Container Apps (Production)**
```bash
# 1. Deploy with Container Apps, Application Insights, and Redis
.\azure\deploy_azure_monitoring.ps1

# Benefits:
# - Production-ready container service
# - Auto-scaling capabilities
# - Application Insights integration
# - Separate Redis container for state management
# - Enterprise-grade monitoring

# 2. Verify deployment
.\azure\get_container_status.ps1

# 3. Check Application Insights
.\azure\check_app_insights.ps1
```

### **Redis Deployment Options**

The deployment scripts now support flexible Redis deployment strategies:

#### **Option 1: Interactive Redis Management (Default)**
```bash
# Deploy with interactive Redis management
.\azure\deploy_simple.ps1
.\azure\deploy_azure_monitoring.ps1

# Behavior:
# - Checks if Redis instance exists
# - Creates new Redis instance if not found
# - For existing Redis instances, prompts user with options:
#   • [Y] Use existing Redis instance (recommended for updates)
#   • [N] Recreate Redis instance (will delete existing data)
#   • [S] Skip Redis deployment entirely
# - Waits for Redis to be ready before proceeding
```

#### **Option 2: Skip Redis Deployment (Use Existing)**
```bash
# Skip Redis deployment and use existing instance
.\azure\deploy_simple.ps1 -SkipRedisDeployment
.\azure\deploy_azure_monitoring.ps1 -SkipRedisDeployment

# Benefits:
# - Faster deployment (no Redis creation wait time)
# - Preserves existing Redis data and configuration
# - Useful for updates when Redis is already working
# - Reduces deployment time by ~30-60 seconds
```

#### **When to Use Each Option**

| Scenario | Recommended Option | Reason |
|----------|-------------------|---------|
| **First-time deployment** | Default (interactive) | Ensures Redis exists and is properly configured |
| **Application updates** | Default (interactive) or `-SkipRedisDeployment` | Interactive prompts guide you, or skip for speed |
| **Redis configuration changes** | Default (interactive) | Interactive prompts allow you to recreate if needed |
| **Disaster recovery** | Default (interactive) | Interactive prompts help you choose the right option |
| **Development/testing** | `-SkipRedisDeployment` | Faster iteration cycles without prompts |
| **Production maintenance** | `-SkipRedisDeployment` | Minimizes downtime and preserves data |
| **Automated deployments** | `-SkipRedisDeployment` | Avoids interactive prompts in CI/CD pipelines |

#### **Interactive Redis Prompts**

When an existing Redis instance is found, the deployment script will present you with three options:

```
Redis Deployment Options:
  [Y] Use existing Redis instance (recommended for updates)
  [N] Recreate Redis instance (will delete existing data)
  [S] Skip Redis deployment entirely

How would you like to handle the existing Redis instance? (Y/n/s)
```

**Option Y (Default)**: Use existing Redis instance
- ✅ **Recommended for most updates**
- ✅ **Preserves all existing data**
- ✅ **Fastest deployment option**
- ✅ **No data loss risk**

**Option N**: Recreate Redis instance
- ⚠️ **WARNING: This will permanently delete all data**
- ⚠️ **Requires confirmation prompt**
- ✅ **Clean slate for troubleshooting**
- ✅ **Useful for configuration changes**

**Option S**: Skip Redis deployment
- ✅ **Fastest option (no Redis operations)**
- ✅ **Useful for automated deployments**
- ⚠️ **Assumes Redis is already configured**

#### **Redis Instance Details**
- **Instance Name**: `cody2zoho-redis`
- **Resource Group**: `ASEV-OpenAI`
- **SKU**: Basic (c0)
- **Location**: eastus
- **Purpose**: State management, token caching, conversation tracking

### **Deployment Script Parameters**

Both deployment scripts support the following parameters:

#### **`deploy_simple.ps1` Parameters**
```bash
# Basic deployment
.\azure\deploy_simple.ps1

# Skip Redis deployment (use existing instance)
.\azure\deploy_simple.ps1 -SkipRedisDeployment

# Force token refresh (opens browser for OAuth)
.\azure\deploy_simple.ps1 -ForceTokenRefresh

# Skip Azure login (if already authenticated)
.\azure\deploy_simple.ps1 -SkipLogin

# Force update all environment variables
.\azure\deploy_simple.ps1 -SkipEnvVarCheck

# Combine multiple parameters
.\azure\deploy_simple.ps1 -SkipRedisDeployment -SkipLogin
```

#### **`deploy_azure_monitoring.ps1` Parameters**
```bash
# Full monitoring deployment
.\azure\deploy_azure_monitoring.ps1

# Skip Redis deployment (use existing instance)
.\azure\deploy_azure_monitoring.ps1 -SkipRedisDeployment
```

#### **Parameter Reference**

| Parameter | Description | Default | Use Case |
|-----------|-------------|---------|----------|
| `-SkipRedisDeployment` | Skip Redis creation/management | `false` | Use existing Redis instance |
| `-ForceTokenRefresh` | Force OAuth token refresh | `false` | Generate new Zoho tokens |
| `-SkipLogin` | Skip Azure login step | `false` | Already authenticated |
| `-SkipEnvVarCheck` | Force update all environment variables | `false` | Override environment variable optimization |
| `-SkipTokenRefresh` | Skip token refresh entirely | `true` | Use existing tokens without refresh |

#### **Common Deployment Scenarios**

```bash
# First-time deployment (interactive prompts will guide you)
.\azure\deploy_azure_monitoring.ps1

# Quick application update (bypass all prompts)
.\azure\deploy_simple.ps1 -SkipRedisDeployment -SkipLogin

# Interactive deployment with token refresh
.\azure\deploy_simple.ps1 -ForceTokenRefresh

# Automated deployment (no prompts)
.\azure\deploy_simple.ps1 -SkipRedisDeployment -SkipLogin -SkipEnvVarCheck

# Force complete environment refresh
.\azure\deploy_simple.ps1 -SkipEnvVarCheck
```

### **Azure Container Instances (Legacy)**
```bash
# Simple container deployment (legacy option)
.\azure\deploy_simple.ps1

# Benefits:
# - Simple deployment
# - Cost-effective
# - Quick setup
# - Good for testing
```

### **Azure-Specific Configuration**

#### **Environment Variables for Azure**
```bash
# Application Insights configuration for Azure deployment
ENABLE_APPLICATION_INSIGHTS=true
APPLICATIONINSIGHTS_CONNECTION_STRING=your-connection-string
APPLICATIONINSIGHTS_ROLE_NAME=Cody2Zoho

# Azure-specific settings
AZURE_REGION=eastus
AZURE_RESOURCE_GROUP=your-resource-group
AZURE_CONTAINER_APP_NAME=cody2zoho

# Note: Graylog is not available for Azure deployments
```

#### **Azure Container Apps Configuration**
```yaml
# containerapp.yaml
apiVersion: 2021-03-01
location: eastus
name: cody2zoho
properties:
  template:
    containers:
    - name: cody2zoho-app
      image: your-registry.azurecr.io/cody2zoho:latest
      env:
      - name: ENABLE_APPLICATION_INSIGHTS
        value: "true"
      - name: APPLICATIONINSIGHTS_CONNECTION_STRING
        value: "your-connection-string"
      - name: APPLICATIONINSIGHTS_ROLE_NAME
        value: "Cody2Zoho"
      - name: REDIS_HOST
        value: "your-redis-host"
      - name: REDIS_PORT
        value: "6379"
```

### **Monitoring and Logging in Azure**

#### **Azure Application Insights Integration**
```bash
# Enable Application Insights
az monitor app-insights component create --app cody2zoho-insights --location eastus --resource-group your-resource-group

# View telemetry in Azure Portal
# Navigate to: Azure Portal > Application Insights > Your App
```

#### **Application Insights Monitoring**
```bash
# Check Application Insights status
.\azure\check_app_insights.ps1

# View telemetry data
.\azure\check_app_insights_events.ps1

# View container logs
az containerapp logs show --name cody2zoho --resource-group your-resource-group
```

### **Service Ports Reference**

| Service | Port | Purpose | Access |
|---------|------|---------|--------|
| Cody2Zoho App | 8080 | Application & Health Checks | `http://localhost:8080` |
| Redis | 6379 | State Management | Internal only |
| Graylog Web UI | 9000 | Log Management Interface | `http://localhost:9000` |
| GELF UDP | 12201 | Log Input (UDP) | Internal only |
| GELF TCP | 12201 | Log Input (TCP) | Internal only |
| GELF HTTP | 12202 | Log Input (HTTP) | Internal only |
| MongoDB | 27017 | Graylog Database | Internal only |
| Elasticsearch | 9200 | Graylog Search Engine | Internal only |

### **Data Persistence**

#### **Docker Volumes**
```bash
# List volumes
docker volume ls

# Volume names
- cody2zoho_redis-data      # Redis data
- cody2zoho_mongodb_data    # MongoDB data
- cody2zoho_elasticsearch_data  # Elasticsearch data
- cody2zoho_graylog_data    # Graylog data
```

#### **Backup and Restore**
```bash
# Backup Redis data
docker run --rm -v cody2zoho_redis-data:/data -v $(pwd):/backup alpine tar czf /backup/redis-backup.tar.gz -C /data .

# Backup Graylog data
docker run --rm -v cody2zoho_graylog_data:/data -v $(pwd):/backup alpine tar czf /backup/graylog-backup.tar.gz -C /data .
```

### **Troubleshooting Commands**

#### **Container Issues**
```bash
# Check container status
docker ps -a

# View container logs
docker logs <container-name>

# Restart specific service
docker-compose restart <service-name>

# Rebuild and restart
docker-compose up -d --build
```

#### **Network Issues**
```bash
# Check network connectivity
docker network ls
docker network inspect cody2zoho_app-network
docker network inspect cody2zoho_graylog-network

# Test inter-container communication
docker exec cody2zoho-app ping redis
docker exec cody2zoho-app ping graylog
```

#### **Resource Issues**
```bash
# Check resource usage
docker stats

# Check disk space
docker system df

# Clean up unused resources
docker system prune
```

### **Environment-Specific Commands**

#### **Windows PowerShell**
```powershell
# Start full stack
docker-compose -f docker-compose.with-graylog.yml up -d

# Stop full stack
docker-compose -f docker-compose.with-graylog.yml down

# View logs
docker-compose -f docker-compose.with-graylog.yml logs -f app
```

#### **Linux/macOS**
```bash
# Start full stack
docker-compose -f docker-compose.with-graylog.yml up -d

# Stop full stack
docker-compose -f docker-compose.with-graylog.yml down

# View logs
docker-compose -f docker-compose.with-graylog.yml logs -f app
```

### **Monitoring and Health Checks**

#### **Application Health**
```bash
# Health check
curl http://localhost:8080/health

# Metrics
curl http://localhost:8080/metrics

# Logs
curl http://localhost:8080/logs
```

#### **Graylog Health**
```bash
# Web interface
curl http://localhost:9000

# API health
curl http://localhost:9000/api/system/lbstatus
```

#### **Azure Health**
```bash
# Container status
azure/get_container_status.ps1 -Action status

# Application metrics
azure/get_container_status.ps1 -Action metrics

# Continuous monitoring
azure/get_container_status.ps1 -Action monitor
```

#### **Option B: Docker Deployment (Recommended for Production)**
```bash
# Build and start the application
docker-compose up --build

# Check logs
docker-compose logs app

# Health check
curl http://localhost:8080/health

# Metrics and monitoring
curl http://localhost:8080/metrics
```

#### **Option B.1: Local Redis for Development**
```bash
# Start local Redis container
cd redis
.\start_redis.ps1

# Use Redis with application (set REDIS_URL=redis://localhost:6379/0 in .env)
# Stop Redis when done
.\stop_redis.ps1
```

#### **Option C: Azure Deployment (Cloud Production)**
```bash
# Deploy to Azure Container Instances
azure/deploy_to_azure.ps1

# Check deployment status
azure/check_azure_deployment.ps1

# Monitor container status and metrics
azure/get_container_status.ps1

# Quick restart for testing
```

## ⚙️ **Configuration**

### **Environment Variables**

Create a `.env` file from `env.template` with the following variables:

#### **Cody Configuration**
```bash
CODY_API_URL=https://getcody.ai/api/v1
CODY_API_KEY=your_cody_api_key
CODY_BOT_ID=your_bot_id
```

#### **Zoho Configuration**
```bash
ZOHO_CLIENT_ID=your_zoho_client_id
ZOHO_CLIENT_SECRET=your_zoho_client_secret
ZOHO_REFRESH_TOKEN=your_refresh_token
ZOHO_ACCESS_TOKEN=your_access_token
```

#### **Application Configuration**
```bash
POLLING_INTERVAL=30
REDIS_URL=redis://localhost:6379/0
LOG_LEVEL=INFO
```

#### **Optional Configuration**
```bash
# Enable conversation notes
ENABLE_NOTES=true

# Custom case fields
CASE_SUBJECT_PREFIX="Cody Conversation: "
CASE_DESCRIPTION_TEMPLATE="Conversation from {conversation_id}"
```

### **Configuration Sources**

The application loads configuration from multiple sources in order of priority:

1. **Environment Variables** (highest priority)
2. **`.env` file** in project root
3. **`env.template`** as fallback
4. **Default values** for non-critical settings

## 🔧 **Development**

### **Local Development Setup**

#### **1. Python Environment**
```bash
# Create virtual environment
python -m venv .venv

# Activate environment
# Windows
.venv\Scripts\activate
# Unix/Linux/macOS
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

#### **2. Redis Setup (Optional)**
```bash
# Start Redis container
cd redis
.\start_redis.ps1

# Verify Redis connection
python tests/test_redis.py
```

#### **3. OAuth Testing**
```bash
# Test OAuth flow
python tests/test_zoho_oauth_enhanced.py

# Test token refresh
python tests/test_auto_refresh.py

# Test token management
python tests/test_token_management.py
```

### **Testing and Debugging**

#### **Container Testing**
```bash
# Test container components


# Test main function
python tests/debug_main.py

# Test logging
python tests/test_logging.py
```

#### **API Testing**
```bash
# Test Zoho API
python tests/debug_zoho_api.py

# Test token refresh
python tests/test_zoho_refresh.py
```

#### **Store Testing**
```bash
# Test Redis store initialization
python tests/test_store_init.py

# Test Redis connection
python tests/test_redis.py
```

### **Building and Deployment**

#### **Docker Build**
```bash
# Build application image
docker-compose build

# Build with no cache
docker-compose build --no-cache
```

#### **Local Testing**
```bash
# Run with Docker Compose
docker-compose up -d

# Check logs
docker-compose logs -f app

# Stop services
docker-compose down
```

## 📊 **Monitoring and Health Checks**

### **Health Endpoints**

The application provides several HTTP endpoints for monitoring:

#### **Health Check**
```bash
curl http://localhost:8080/health
```
**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-08-17T03:30:00Z",
  "uptime_seconds": 1800,
  "version": "1.0.0"
}
```

#### **Metrics Endpoint**
```bash
curl http://localhost:8080/metrics
```
**Response:**
```json
{
  "application": {
    "status": "running",
    "polling_active": true,
    "uptime_seconds": 1800
  },
  "conversations": {
    "total_processed": 15,
    "cases_created": 15,
    "total_skipped": 0,
    "total_errors": 0,
    "processing_rate_per_hour": 30.0
  },
  "tokens": {
    "refresh_attempts": 1,
    "refresh_successes": 1,
    "refresh_failures": 0,
    "success_rate": 100.0,
    "rate_limit_hits": 0
  },
  "timestamp": 1755399600
}
```

#### **Logs Endpoint**
```bash
curl http://localhost:8080/logs
```
**Response:**
```json
{
  "logs": [
    "2025-08-17 03:30:00 - INFO - Polling cycle complete: 0 processed, 15 skipped",
    "2025-08-17 03:29:30 - INFO - Fetching conversations from Cody..."
  ]
}
```

### **📈 Metrics Collected**

The application collects comprehensive metrics that are sent to Azure Application Insights for monitoring and analysis. These metrics provide visibility into application performance, business operations, and system health.

#### **Business Metrics**

**Conversation Processing:**
- `conversation_processed` - Event logged when a conversation is processed
- `conversation_processing_time` - Time taken to process each conversation (seconds)
- `conversation_message_count` - Number of messages in each conversation
- `conversation_character_count` - Total character count in each conversation

**Case Creation:**
- `case_created` - Event logged when a new Zoho case is created
- `cases_created_total` - Counter for total cases created
- `conversation_message_count_at_creation` - Message count when case was created
- `conversation_character_count_at_creation` - Character count when case was created

**Polling Operations:**
- `cody_poll_completed` - Event logged every time Cody is polled for conversations
- `cody_poll_count` - Counter for each poll operation (always 1)
- `cody_poll_duration` - Duration of each Cody API poll (seconds)
- `conversations_found_per_poll` - Number of conversations found in each poll
- `polling_cycle_completed` - Event logged when a complete polling cycle finishes
- `polling_cycle_duration` - Duration of complete polling cycles (seconds)
- `conversations_found_per_cycle` - Total conversations found per cycle
- `conversations_processed_per_cycle` - Conversations processed per cycle
- `conversations_skipped_per_cycle` - Conversations skipped per cycle
- `errors_per_cycle` - Errors encountered per cycle

#### **API Performance Metrics**

**API Calls:**
- `api_call` - Event logged for each API call
- `api_call_duration` - Duration of API calls (seconds)
- `api_response_size` - Size of API responses (bytes)

**Token Management:**
- `token_refresh` - Event logged for token refresh operations
- `token_refresh_duration` - Duration of token refresh operations (seconds)
- `token_refresh_attempts` - Number of token refresh attempts

**Rate Limiting:**
- `rate_limit_hit` - Event logged when API rate limits are hit
- `rate_limit_events` - Counter for rate limit events

#### **System Metrics**

**Business Metrics Summary:**
- `business_metrics_summary` - Periodic summary of all business metrics
- `total_cases_created` - Total cases created since startup
- `total_conversations_processed` - Total conversations processed since startup
- `total_conversations_skipped` - Total conversations skipped since startup
- `total_errors` - Total errors encountered since startup
- `total_api_calls` - Total API calls made since startup
- `total_token_refreshes` - Total token refresh operations since startup
- `total_cody_polls` - Total Cody polling operations since startup

**Rate Calculations:**
- `cases_per_hour` - Rate of case creation per hour
- `conversations_per_hour` - Rate of conversation processing per hour
- `api_calls_per_hour` - Rate of API calls per hour
- `cody_polls_per_hour` - Rate of Cody polling per hour
- `error_rate_percent` - Error rate as percentage of total operations

**Conversation Processing Efficiency:**
- `conversation_to_case_ratio` - Percentage of conversations that resulted in new cases (0-100%)
- `conversations_processed_total` - Total conversations processed since startup (cumulative)
- `cases_created_total` - Total new cases created since startup (cumulative)
- `conversation_processing_ratio_updated` - Event logged when processing ratio is updated
- `conversation_to_case_ratio_percent` - Ratio included in business metrics summary

#### **Monitoring Frequency**

- **Real-time Events**: All business events are logged immediately when they occur
- **Polling Metrics**: Cody polling metrics are logged every 30 seconds (configurable via `POLL_INTERVAL_SECONDS`)
- **Business Summary**: Comprehensive business metrics are logged every 5 minutes
- **API Performance**: All API calls are tracked with timing and response data

#### **Application Insights Queries**

You can query these metrics in Azure Application Insights using KQL (Kusto Query Language):

```kql
// Cody polling frequency
customEvents
| where name == "cody_poll_completed"
| summarize count() by bin(timestamp, 1h)
| render timechart

// Conversation processing performance
customMetrics
| where name == "conversation_processing_time"
| summarize avg(value), max(value), min(value) by bin(timestamp, 1h)
| render timechart

// Case creation rate
customEvents
| where name == "case_created"
| summarize count() by bin(timestamp, 1h)
| render timechart

// API performance
customMetrics
| where name == "api_call_duration"
| where customDimensions.api_name == "cody"
| summarize avg(value) by bin(timestamp, 1h)
| render timechart

// Conversation-to-case processing efficiency
customMetrics
| where name == "conversation_to_case_ratio"
| summarize avg(value) by bin(timestamp, 1h)
| render timechart

// Track total conversations vs cases created over time
customEvents
| where name == "conversation_processing_ratio_updated"
| project timestamp, 
         conversations_processed = toint(customDimensions.conversations_processed), 
         cases_created = toint(customDimensions.cases_created),
         success_rate = todouble(customDimensions.success_rate_percent)
| render timechart

// Monitor conversation processing efficiency trends
customEvents
| where name == "conversation_processing_ratio_updated"
| extend hour = bin(timestamp, 1h)
| summarize 
    avg_conversations = avg(toint(customDimensions.conversations_processed)),
    avg_cases = avg(toint(customDimensions.cases_created)),
    avg_success_rate = avg(todouble(customDimensions.success_rate_percent))
    by hour
| render timechart

// Get current processing efficiency summary
customEvents
| where name == "conversation_processing_ratio_updated"
| top 1 by timestamp desc
| project 
    timestamp,
    total_conversations = toint(customDimensions.conversations_processed),
    total_cases_created = toint(customDimensions.cases_created),
    current_success_rate = todouble(customDimensions.success_rate_percent)

// Monitor duplicate case detection (conversations processed but no new cases)
customEvents
| where name == "conversation_processing_ratio_updated"
| extend 
    conversations = toint(customDimensions.conversations_processed),
    cases = toint(customDimensions.cases_created),
    duplicates = conversations - cases
| summarize 
    total_conversations = sum(conversations),
    total_cases = sum(cases),
    total_duplicates = sum(duplicates),
    duplicate_rate = (sum(duplicates) * 100.0) / sum(conversations)
    by bin(timestamp, 1h)
| render timechart
```

#### **Understanding Conversation Processing Efficiency**

The new conversation processing efficiency metrics provide crucial insights into how effectively the application converts Cody conversations into Zoho CRM cases:

**Key Metrics Explained:**

- **`conversation_to_case_ratio`**: The percentage of conversations that resulted in new cases being created. A high ratio (close to 100%) indicates most conversations are new and creating cases. A lower ratio suggests many conversations are duplicates or existing cases.

- **`conversations_processed_total`**: Total count of all conversations the application has attempted to process since startup.

- **`cases_created_total`**: Total count of new cases actually created in Zoho CRM since startup.

**Interpreting the Data:**

- **High Efficiency (80-100%)**: Most conversations are new, creating new cases
- **Medium Efficiency (50-80%)**: Mix of new conversations and duplicates
- **Low Efficiency (<50%)**: Many duplicate conversations or processing issues

**Use Cases:**

1. **Duplicate Detection**: Monitor if the duplicate checking is working correctly
2. **Business Volume**: Track actual new case creation vs total conversation volume
3. **System Health**: Identify if the application is processing conversations but failing to create cases
4. **Performance Optimization**: Understand conversation patterns to optimize processing

**Example Scenarios:**

- **100 conversations processed, 80 cases created** = 80% efficiency (20 duplicates found)
- **100 conversations processed, 100 cases created** = 100% efficiency (all new conversations)
- **100 conversations processed, 0 cases created** = 0% efficiency (all duplicates or errors)

### **Azure Monitoring**

For Azure deployments, use the monitoring script:

```bash
# Get container status
azure/get_container_status.ps1 -Action status

# Get application metrics
azure/get_container_status.ps1 -Action metrics

# Get container logs (with guidance for direct access)
azure/get_container_status.ps1 -Action logs

# Continuous monitoring
azure/get_container_status.ps1 -Action monitor
```

## 🔒 **Security Considerations**

### **OAuth Security**
- **Token Storage**: Tokens are stored securely in environment variables
- **Token Refresh**: Automatic refresh with rate limiting to prevent abuse
- **Scope Management**: Minimal required scopes for security
- **Error Handling**: Secure error handling without exposing sensitive data

### **API Security**
- **Rate Limiting**: Respects API rate limits with exponential backoff
- **Error Recovery**: Graceful handling of API errors
- **Connection Security**: Uses HTTPS for all API communications
- **Timeout Handling**: Configurable timeouts for API calls

### **Data Security**
- **Redis Security**: Redis connections use authentication when available
- **Log Security**: Sensitive data is not logged
- **Environment Variables**: Sensitive configuration in environment variables
- **Container Security**: Non-root user in containers

### **Production Security**
- **Secrets Management**: Use Azure Key Vault or similar for production secrets
- **Network Security**: Proper network segmentation and firewall rules
- **Monitoring**: Comprehensive logging and monitoring
- **Backup**: Regular backup of Redis data and configuration

## 🚀 **Deployment Options**

### **Local Development**
- **Python Virtual Environment**: Isolated development environment
- **Local Redis**: Optional Redis for state management
- **Hot Reloading**: Development server with auto-reload
- **Debug Logging**: Detailed logging for development

### **Docker Development**
- **Docker Compose**: Multi-service development environment
- **Volume Mounting**: Code changes reflected immediately
- **Environment Isolation**: Consistent development environment
- **Service Discovery**: Automatic service discovery

### **Production Docker**
- **Multi-stage Builds**: Optimized production images
- **Health Checks**: Built-in health monitoring
- **Resource Limits**: Configurable resource constraints
- **Logging**: Structured logging for production

### **Azure Container Instances**
- **Managed Service**: Fully managed container service
- **Auto-scaling**: Automatic scaling based on demand
- **Monitoring**: Integrated monitoring and logging
- **Security**: Managed identity and key vault integration

### **Azure Container Apps**
- **Serverless**: Pay-per-use container service
- **Event-driven**: Scale based on HTTP requests
- **Dapr Integration**: Distributed application runtime
- **Built-in Monitoring**: Application insights integration

## 🔧 **Troubleshooting**

### **Common Issues**

#### **1. "Redis connection failed"**
- **Cause**: Redis server not running or network issues
- **Solution**: Application falls back to in-memory storage
- **Action**: Start Redis or check network connectivity

#### **2. "OAuth token expired"**
- **Cause**: Access token expired and refresh failed
- **Solution**: Generate new tokens using OAuth flow
- **Action**: Run `python tests/test_zoho_oauth_enhanced.py`

#### **3. "Cody API rate limit exceeded"**
- **Cause**: Too many requests to Cody API
- **Solution**: Application implements exponential backoff
- **Action**: Wait for rate limit reset or adjust polling interval

#### **4. "Zoho API 401 Unauthorized"**
- **Cause**: Invalid or expired OAuth tokens
- **Solution**: Automatic token refresh or manual regeneration
- **Action**: Check token validity and refresh if needed

#### **5. "Container startup timeout"**
- **Cause**: Application taking too long to start
- **Solution**: Check dependencies and configuration
- **Action**: Review logs and verify environment setup

### **Debugging Steps**

1. **Check Application Logs**
   ```bash
   # Local development
   tail -f logs/app.log
   
   # Docker
   docker-compose logs -f app
   
   # Azure
   azure/get_container_status.ps1 -Action logs
   ```

2. **Verify Configuration**
   ```bash
   # Check environment variables
   python -c "from src.config import Settings; s = Settings(); print(s)"
   ```

3. **Test Individual Components**
   ```bash
   # Test Redis connection
   python tests/test_redis.py
   
   # Test OAuth flow
   python tests/test_zoho_oauth_enhanced.py
   
   # Test Cody API
   
   ```

4. **Check Health Endpoints**
   ```bash
   # Health check
   curl http://localhost:8080/health
   
   # Metrics
   curl http://localhost:8080/metrics
   ```

## 📚 **API References**

### **Cody API**
- **Base URL**: `https://getcody.ai/api/v1`
- **Authentication**: API Key in header
- **Endpoints**:
  - `GET /conversations` - List conversations
  - `GET /conversations/{id}/messages` - Get conversation messages
- **Rate Limits**: Respect API rate limits with exponential backoff

### **Zoho CRM API**
- **Base URL**: `https://www.zohoapis.com/crm/v8`
- **Authentication**: OAuth 2.0 with automatic token refresh
- **Endpoints**:
  - `POST /Cases` - Create new case
  - `POST /oauth/v2/token` - Refresh access token
- **Scopes**: `ZohoCRM.modules.ALL,ZohoCRM.settings.ALL`

### **OAuth 2.0 Flow**
1. **Authorization Code Grant**: Initial token acquisition
2. **Refresh Token Grant**: Automatic token refresh
3. **Token Storage**: Secure token caching with expiration
4. **Error Handling**: Graceful handling of token expiration

## 🤝 **Contributing**

### **Development Setup**
1. Fork the repository
2. Create a feature branch
3. Set up development environment
4. Make changes with tests
5. Submit pull request

### **Code Standards**
- **Python**: PEP 8 style guide
- **Documentation**: Comprehensive docstrings
- **Testing**: Unit tests for new features
- **Logging**: Appropriate log levels and messages

### **Testing Guidelines**
- **Unit Tests**: Test individual components
- **Integration Tests**: Test component interactions
- **End-to-End Tests**: Test complete workflows
- **Performance Tests**: Test under load

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 **Acknowledgments**

- **Cody Team**: For providing the Cody API and documentation
- **Zoho Team**: For comprehensive CRM API and OAuth documentation
- **Open Source Community**: For the libraries and tools that make this possible

---

**Cody2Zoho** - Bridging the gap between Cody conversations and Zoho CRM with automation, reliability, and ease of use. 🚀
