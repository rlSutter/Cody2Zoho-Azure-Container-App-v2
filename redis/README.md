# Redis Management Documentation

## Overview

This directory contains comprehensive Redis management scripts and configuration for the Cody2Zoho application. Redis is used for state management, conversation tracking, and token caching. The scripts support both local development Redis instances and Azure Redis Cache deployments.

## Recent Updates

### **Azure Redis Cache Management**
The Redis folder has been enhanced with comprehensive Azure Redis Cache management capabilities:

#### **New Azure Redis Scripts:**
- `manage_azure_redis.ps1` - Complete Azure Redis Cache management
- `review_azure_redis_logs.ps1` - Log review and analysis
- `monitor_azure_redis_health.ps1` - Health monitoring and diagnostics
- `backup_restore_azure_redis.ps1` - Backup and restore operations

#### **Enhanced Capabilities:**
- **Independent Management**: Manage Azure Redis Cache without affecting the main application
- **Comprehensive Logging**: Review and analyze Redis logs and metrics
- **Health Monitoring**: Real-time health checks and performance monitoring
- **Backup Operations**: Full backup and restore capabilities
- **Automated Reporting**: Generate detailed health and performance reports

## Scripts

### Local Development Scripts

#### **Local Redis Management Scripts**

#### `start_redis.ps1`
**Purpose**: PowerShell script to start Redis container
**Features**:
- Docker container management
- Port configuration
- Volume mounting
- Error handling
- Status reporting

**Usage**:
```powershell
# Start Redis
.\redis\start_redis.ps1

# Start with custom port
.\redis\start_redis.ps1 -Port 6380
```

#### `stop_redis.ps1`
**Purpose**: PowerShell script to stop Redis container
**Features**:
- Graceful container shutdown
- Data persistence
- Status reporting
- Error handling

**Usage**:
```powershell
# Stop Redis
.\redis\stop_redis.ps1

# Force stop
.\redis\stop_redis.ps1 -Force
```

#### `start_redis.bat`
**Purpose**: Windows batch script to start Redis container
**Features**:
- Cross-platform compatibility
- Docker integration
- Error handling
- Status reporting

**Usage**:
```cmd
# Start Redis
redis\start_redis.bat

# Start with custom configuration
redis\start_redis.bat 6380
```

#### `stop_redis.bat`
**Purpose**: Windows batch script to stop Redis container
**Features**:
- Simple stop command
- Error handling
- Status reporting

**Usage**:
```cmd
# Stop Redis
redis\stop_redis.bat
```

## Configuration

### Docker Compose Configuration

#### `docker-compose.dev.yml`
**Purpose**: Development Redis configuration
**Features**:
- Redis container setup
- Volume persistence
- Port mapping
- Network configuration

**Configuration**:
```yaml
version: '3.8'
services:
  redis:
    image: redis:7-alpine
    container_name: cody2zoho-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
    restart: unless-stopped

volumes:
  redis_data:
```

### Environment Variables

#### Required Variables
```bash
# Redis Connection
REDIS_URL=redis://localhost:6379/0
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0

# Optional Authentication
REDIS_PASSWORD=your_password
REDIS_USERNAME=your_username
```

#### Optional Variables
```bash
# Redis Configuration
REDIS_MAX_CONNECTIONS=10
REDIS_CONNECT_TIMEOUT=5
REDIS_READ_TIMEOUT=5
REDIS_WRITE_TIMEOUT=5
```

## Azure Redis Cache Management

### **Azure Redis Management Scripts**

#### `manage_azure_redis.ps1`
**Purpose**: Comprehensive Azure Redis Cache management
**Features**:
- Start/stop/restart Redis instances
- View Redis information and status
- List and manage Redis keys
- Flush Redis data (with safety confirmations)
- Monitor Redis operations in real-time
- Backup operations (metadata and data export)

**Usage**:
```powershell
# Check Redis status
.\redis\manage_azure_redis.ps1 -Action status

# Start Redis instance
.\redis\manage_azure_redis.ps1 -Action start

# Stop Redis instance
.\redis\manage_azure_redis.ps1 -Action stop

# View Redis information
.\redis\manage_azure_redis.ps1 -Action info

# List Redis keys
.\redis\manage_azure_redis.ps1 -Action keys

# Monitor Redis operations
.\redis\manage_azure_redis.ps1 -Action monitor

# Create backup
.\redis\manage_azure_redis.ps1 -Action backup -BackupPath "./backups"
```

#### `review_azure_redis_logs.ps1`
**Purpose**: Comprehensive log review and analysis for Azure Redis Cache
**Features**:
- Retrieve and analyze Redis logs
- View performance metrics
- Check alert status
- Run diagnostics
- Export logs and metrics
- Real-time log monitoring

**Usage**:
```powershell
# View recent logs
.\redis\review_azure_redis_logs.ps1 -Action logs -Hours 24

# Check performance metrics
.\redis\review_azure_redis_logs.ps1 -Action metrics -Hours 24

# View alerts
.\redis\review_azure_redis_logs.ps1 -Action alerts

# Run diagnostics
.\redis\review_azure_redis_logs.ps1 -Action diagnostics

# Export all data
.\redis\review_azure_redis_logs.ps1 -Action export -OutputPath "./exports"

# Monitor logs in real-time
.\redis\review_azure_redis_logs.ps1 -Action monitor -Follow
```

#### `monitor_azure_redis_health.ps1`
**Purpose**: Health monitoring and diagnostics for Azure Redis Cache
**Features**:
- Comprehensive health scoring
- Connectivity testing
- Performance metrics analysis
- Alert monitoring
- Health report generation
- Continuous monitoring

**Usage**:
```powershell
# Check overall health
.\redis\monitor_azure_redis_health.ps1 -Action health

# Check performance metrics
.\redis\monitor_azure_redis_health.ps1 -Action performance

# Test connectivity
.\redis\monitor_azure_redis_health.ps1 -Action connectivity

# Check alerts
.\redis\monitor_azure_redis_health.ps1 -Action alerts

# Generate health report
.\redis\monitor_azure_redis_health.ps1 -Action report -OutputPath "./reports"

# Continuous monitoring
.\redis\monitor_azure_redis_health.ps1 -Action continuous -IntervalSeconds 60 -DurationMinutes 60
```

#### `backup_restore_azure_redis.ps1`
**Purpose**: Backup and restore operations for Azure Redis Cache
**Features**:
- Create comprehensive backups (data + metadata)
- Restore from backups
- List available backups
- Delete old backups
- Azure Storage integration
- Backup status monitoring

**Usage**:
```powershell
# Create backup
.\redis\backup_restore_azure_redis.ps1 -Action backup -BackupName "daily_backup"

# Restore from backup
.\redis\backup_restore_azure_redis.ps1 -Action restore -BackupName "daily_backup"

# List available backups
.\redis\backup_restore_azure_redis.ps1 -Action list

# Delete backup
.\redis\backup_restore_azure_redis.ps1 -Action delete -BackupName "old_backup"

# Check backup status
.\redis\backup_restore_azure_redis.ps1 -Action status

# Backup with Azure Storage
.\redis\backup_restore_azure_redis.ps1 -Action backup -StorageAccount "mystorage" -StorageContainer "redis-backups"
```

## Redis Usage in Cody2Zoho

### State Management

Redis is used for the following state management tasks:

1. **Conversation Tracking**: Prevents duplicate case creation
2. **Token Caching**: Stores OAuth tokens with expiration
3. **Metrics Storage**: Performance and usage metrics
4. **Session Management**: Application session data

### Data Structures

#### Conversation Tracking
```redis
# Key: conversation:{conversation_id}
# Value: JSON with processing status and metadata
SET conversation:WPe9rGq9ZaLy '{"processed": true, "case_id": "12345", "timestamp": "2025-08-27T01:00:00Z"}'
```

#### Token Caching
```redis
# Key: token:zoho_access
# Value: Access token with expiration
SET token:zoho_access "1000.abc123..." EX 3600

# Key: token:zoho_refresh
# Value: Refresh token
SET token:zoho_refresh "1000.def456..."
```

#### Metrics Storage
```redis
# Key: metrics:cases_created
# Value: Counter
INCR metrics:cases_created

# Key: metrics:api_calls
# Value: Counter
INCR metrics:api_calls
```

## Quick Start

### Local Development

#### 1. Start Local Redis
```bash
# PowerShell
.\redis\start_redis.ps1

# Batch
redis\start_redis.bat

# Docker Compose
docker-compose -f redis/docker-compose.dev.yml up -d
```

### Azure Redis Cache

#### 1. Check Azure Redis Status
```powershell
# Check Redis status
.\redis\manage_azure_redis.ps1 -Action status

# View Redis information
.\redis\manage_azure_redis.ps1 -Action info
```

#### 2. Monitor Redis Health
```powershell
# Check overall health
.\redis\monitor_azure_redis_health.ps1 -Action health

# Generate health report
.\redis\monitor_azure_redis_health.ps1 -Action report
```

#### 3. Review Redis Logs
```powershell
# View recent logs
.\redis\review_azure_redis_logs.ps1 -Action logs -Hours 24

# Check performance metrics
.\redis\review_azure_redis_logs.ps1 -Action metrics
```

### 2. Verify Redis Connection
```bash
# Test connection
redis-cli ping

# Check status
docker ps | grep redis
```

### 3. Start Application
```bash
# Local development
python scripts/run_local.py

# Docker
docker-compose up -d
```

## Management Commands

### Container Management
```bash
# Start Redis
.\redis\start_redis.ps1

# Stop Redis
.\redis\stop_redis.ps1

# Restart Redis
.\redis\stop_redis.ps1
.\redis\start_redis.ps1

# Check status
docker ps | grep redis
```

### Data Management
```bash
# Connect to Redis CLI
docker exec -it cody2zoho-redis redis-cli

# View all keys
KEYS *

# View conversation data
KEYS conversation:*

# View token data
KEYS token:*

# View metrics
KEYS metrics:*

# Clear all data
FLUSHALL
```

### Backup and Restore
```bash
# Backup Redis data
docker exec cody2zoho-redis redis-cli BGSAVE

# Copy backup file
docker cp cody2zoho-redis:/data/dump.rdb ./redis_backup.rdb

# Restore from backup
docker cp ./redis_backup.rdb cody2zoho-redis:/data/dump.rdb
docker restart cody2zoho-redis
```

## Monitoring

### Health Checks
```bash
# Check Redis status
docker exec cody2zoho-redis redis-cli ping

# Check memory usage
docker exec cody2zoho-redis redis-cli info memory

# Check connected clients
docker exec cody2zoho-redis redis-cli info clients
```

### Performance Monitoring
```bash
# Monitor Redis commands
docker exec cody2zoho-redis redis-cli monitor

# Check slow queries
docker exec cody2zoho-redis redis-cli slowlog get 10

# Check memory usage
docker exec cody2zoho-redis redis-cli info memory
```

## Troubleshooting

### Common Issues

1. **Redis Connection Failed**
   - Check if Redis container is running
   - Verify port configuration
   - Check network connectivity
   - Validate connection string

2. **Data Persistence Issues**
   - Check volume mounting
   - Verify file permissions
   - Check disk space
   - Validate backup/restore process

3. **Performance Issues**
   - Monitor memory usage
   - Check for slow queries
   - Optimize data structures
   - Consider Redis clustering

### Debug Commands
```bash
# Check container status
docker ps -a | grep redis

# View container logs
docker logs cody2zoho-redis

# Check Redis configuration
docker exec cody2zoho-redis redis-cli config get "*"

# Test Redis connectivity
docker exec cody2zoho-redis redis-cli ping

# Check Redis info
docker exec cody2zoho-redis redis-cli info
```

## Best Practices

### Local Development
1. **Use appropriate data structures**: Choose the right Redis data type for your data
2. **Set expiration times**: Use TTL for temporary data
3. **Monitor memory usage**: Keep track of Redis memory consumption
4. **Backup regularly**: Create regular backups of important data

### Azure Redis Cache
1. **Monitor health regularly**: Use health monitoring scripts to track Redis performance
2. **Review logs frequently**: Check logs for errors and performance issues
3. **Set up automated backups**: Use backup scripts for data protection
4. **Monitor costs**: Keep track of Azure Redis Cache usage and costs
5. **Use appropriate SKU**: Choose the right Redis SKU for your workload
6. **Enable diagnostics**: Configure Azure Monitor for comprehensive logging

### Performance
1. **Use pipelining**: Batch multiple commands for better performance
2. **Optimize queries**: Use efficient Redis commands
3. **Monitor slow queries**: Keep track of slow operations
4. **Use appropriate key naming**: Use descriptive and consistent key names
5. **Monitor Azure metrics**: Use Azure Monitor to track performance metrics

### Security
1. **Enable authentication**: Use Redis password protection
2. **Restrict network access**: Limit Redis to localhost or internal networks
3. **Use SSL/TLS**: Enable encryption for sensitive data
4. **Regular updates**: Keep Redis version updated
5. **Use Azure Key Vault**: Store Redis connection strings securely
6. **Enable Azure Security Center**: Monitor for security threats

## Integration with Cody2Zoho

### Application Configuration
The Cody2Zoho application automatically detects and uses Redis when available:

1. **Connection Detection**: Automatically connects to Redis if available
2. **Fallback Mechanism**: Uses in-memory storage if Redis is unavailable
3. **Error Handling**: Gracefully handles Redis connection issues
4. **State Persistence**: Maintains state across application restarts

### State Management
Redis provides the following benefits for Cody2Zoho:

1. **Conversation Deduplication**: Prevents creating duplicate cases
2. **Token Persistence**: Maintains OAuth tokens across restarts
3. **Metrics Collection**: Stores performance and usage metrics
4. **Session Management**: Maintains application state

## Production Considerations

### High Availability
For production deployments, consider:

1. **Redis Cluster**: Use Redis Cluster for high availability
2. **Replication**: Set up Redis replication for data redundancy
3. **Backup Strategy**: Implement automated backup procedures
4. **Monitoring**: Set up comprehensive monitoring and alerting

### Security
For production environments:

1. **Network Security**: Restrict Redis to internal networks
2. **Authentication**: Enable Redis authentication
3. **Encryption**: Use SSL/TLS for data in transit
4. **Access Control**: Implement proper access controls

### Performance
For optimal performance:

1. **Memory Optimization**: Configure appropriate memory limits
2. **Connection Pooling**: Use connection pooling in the application
3. **Caching Strategy**: Implement effective caching strategies
4. **Monitoring**: Monitor Redis performance metrics
