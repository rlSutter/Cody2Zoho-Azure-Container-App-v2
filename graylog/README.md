# Graylog Integration Documentation

## Overview

This directory contains Graylog integration scripts and configuration for centralized logging in the Cody2Zoho application. Graylog provides a powerful web interface for searching, analyzing, and monitoring application logs.

## Scripts

### Graylog Management Scripts

#### `start_graylog.ps1`
**Purpose**: PowerShell script to start Graylog stack
**Features**:
- Docker Compose management
- Service orchestration
- Health checks
- Error handling
- Status reporting

**Usage**:
```powershell
# Start Graylog
.\graylog\start_graylog.ps1

# Start with custom configuration
.\graylog\start_graylog.ps1 -Environment production
```

#### `stop_graylog.ps1`
**Purpose**: PowerShell script to stop Graylog stack
**Features**:
- Graceful service shutdown
- Data persistence
- Resource cleanup
- Status reporting

**Usage**:
```powershell
# Stop Graylog
.\graylog\stop_graylog.ps1

# Force stop
.\graylog\stop_graylog.ps1 -Force
```

#### `setup_remote_access.ps1`
**Purpose**: Configure remote access to Graylog
**Features**:
- Network configuration
- Port forwarding
- Security setup
- Access control

**Usage**:
```powershell
# Setup remote access
.\graylog\setup_remote_access.ps1

# Setup with custom ports
.\graylog\setup_remote_access.ps1 -WebPort 9000 -GelfPort 12201
```

## Configuration

### Docker Compose Configuration

#### `docker-compose.yml`
**Purpose**: Graylog stack configuration
**Features**:
- Graylog server setup
- MongoDB database
- Elasticsearch search engine
- Network configuration
- Volume persistence

**Configuration**:
```yaml
version: '3.8'
services:
  mongodb:
    image: mongo:4.2
    container_name: graylog-mongodb
    volumes:
      - mongodb_data:/data/db
    restart: unless-stopped

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch-oss:7.10.2
    container_name: graylog-elasticsearch
    environment:
      - http.host=0.0.0.0
      - transport.host=localhost
      - network.host=0.0.0.0
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    restart: unless-stopped

  graylog:
    image: graylog/graylog:4.3
    container_name: graylog-server
    environment:
      - GRAYLOG_PASSWORD_SECRET=somepasswordpepper
      - GRAYLOG_ROOT_PASSWORD_SHA2=8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918
      - GRAYLOG_HTTP_EXTERNAL_URI=http://127.0.0.1:9000/
    volumes:
      - graylog_data:/usr/share/graylog/data
    ports:
      - "9000:9000"
      - "12201:12201/udp"
      - "12201:12201/tcp"
    depends_on:
      - mongodb
      - elasticsearch
    restart: unless-stopped

volumes:
  mongodb_data:
  elasticsearch_data:
  graylog_data:
```

## Graylog Features

### Core Features
- **Centralized Logging**: All application logs in one place
- **Real-time Search**: Search logs with powerful query language
- **Dashboards**: Create custom dashboards for monitoring
- **Alerts**: Set up alerts for specific log patterns
- **GELF Support**: Structured logging with metadata

### Log Management
- **Log Collection**: Collect logs from multiple sources
- **Log Processing**: Parse and enrich log data
- **Log Storage**: Efficient storage with Elasticsearch
- **Log Search**: Fast search across all logs
- **Log Analysis**: Analyze patterns and trends

### Monitoring and Alerting
- **Real-time Monitoring**: Monitor application health
- **Custom Alerts**: Set up alerts for specific conditions
- **Dashboard Creation**: Create custom visualizations
- **Performance Metrics**: Track application performance
- **Error Tracking**: Monitor and analyze errors

## Integration with Cody2Zoho

### Application Configuration

The Cody2Zoho application can be configured to send logs to Graylog:

```python
# In src/graylog_handler.py
import logging
from graylog_handler import GraylogHandler

# Configure Graylog handler
graylog_handler = GraylogHandler(
    host='localhost',
    port=12201,
    facility='cody2zoho'
)

# Add to logger
logger = logging.getLogger('cody2zoho')
logger.addHandler(graylog_handler)
```

### Environment Variables

```bash
# Graylog Configuration
GRAYLOG_ENABLED=true
GRAYLOG_HOST=localhost
GRAYLOG_PORT=12201
GRAYLOG_FACILITY=cody2zoho

# Optional Configuration
GRAYLOG_LEVEL=INFO
GRAYLOG_FORMAT=json
```

## Quick Start

### 1. Start Graylog Stack
```bash
# Start Graylog
.\graylog\start_graylog.ps1

# Check status
docker-compose -f graylog/docker-compose.yml ps
```

### 2. Access Graylog Web Interface
- **URL**: http://localhost:9000
- **Username**: admin
- **Password**: admin

### 3. Configure Log Input
1. Go to System → Inputs
2. Add GELF UDP input
3. Configure port 12201
4. Start the input

### 4. Configure Cody2Zoho
```bash
# Set environment variables
export GRAYLOG_ENABLED=true
export GRAYLOG_HOST=localhost
export GRAYLOG_PORT=12201

# Start application
python scripts/run_local.py
```

## Management Commands

### Service Management
```bash
# Start Graylog
.\graylog\start_graylog.ps1

# Stop Graylog
.\graylog\stop_graylog.ps1

# Restart Graylog
.\graylog\stop_graylog.ps1
.\graylog\start_graylog.ps1

# Check status
docker-compose -f graylog/docker-compose.yml ps
```

### Data Management
```bash
# View logs
docker-compose -f graylog/docker-compose.yml logs graylog

# View MongoDB logs
docker-compose -f graylog/docker-compose.yml logs mongodb

# View Elasticsearch logs
docker-compose -f graylog/docker-compose.yml logs elasticsearch

# Backup data
docker run --rm -v graylog_graylog_data:/data -v $(pwd):/backup alpine tar czf /backup/graylog-backup.tar.gz -C /data .
```

### Configuration Management
```bash
# Setup remote access
.\graylog\setup_remote_access.ps1

# Check network configuration
docker network ls
docker network inspect graylog_default
```

## Monitoring

### Health Checks
```bash
# Check Graylog status
curl http://localhost:9000/api/system/lbstatus

# Check Elasticsearch status
curl http://localhost:9200/_cluster/health

# Check MongoDB status
docker exec graylog-mongodb mongo --eval "db.adminCommand('ping')"
```

### Performance Monitoring
```bash
# Monitor Graylog performance
curl http://localhost:9000/api/system/stats

# Check Elasticsearch performance
curl http://localhost:9200/_nodes/stats

# Monitor resource usage
docker stats graylog-server graylog-elasticsearch graylog-mongodb
```

## Troubleshooting

### Common Issues

1. **Graylog Not Accessible**
   - Check if containers are running
   - Verify port configuration
   - Check network connectivity
   - Validate service dependencies

2. **Elasticsearch Issues**
   - Check memory configuration
   - Verify disk space
   - Check cluster health
   - Validate configuration

3. **MongoDB Issues**
   - Check database connectivity
   - Verify data persistence
   - Check authentication
   - Validate configuration

4. **Log Ingestion Issues**
   - Check input configuration
   - Verify network connectivity
   - Check log format
   - Validate permissions

### Debug Commands
```bash
# Check container status
docker-compose -f graylog/docker-compose.yml ps

# View service logs
docker-compose -f graylog/docker-compose.yml logs graylog
docker-compose -f graylog/docker-compose.yml logs elasticsearch
docker-compose -f graylog/docker-compose.yml logs mongodb

# Check network connectivity
docker network inspect graylog_default

# Test Graylog API
curl http://localhost:9000/api/system/lbstatus

# Check Elasticsearch health
curl http://localhost:9200/_cluster/health
```

## Best Practices

### Configuration
1. **Use appropriate memory limits**: Configure memory for Elasticsearch
2. **Enable data persistence**: Use volumes for data storage
3. **Configure security**: Set up authentication and authorization
4. **Monitor performance**: Track resource usage and performance

### Log Management
1. **Use structured logging**: Send logs in structured format
2. **Include metadata**: Add relevant context to logs
3. **Set appropriate log levels**: Use appropriate log levels
4. **Monitor log volume**: Track log ingestion rates

### Security
1. **Change default passwords**: Update default credentials
2. **Restrict network access**: Limit access to necessary ports
3. **Use SSL/TLS**: Enable encryption for sensitive data
4. **Regular updates**: Keep Graylog version updated

## Integration with Azure

### Azure Container Apps Integration

Graylog can be integrated with Azure Container Apps deployment:

1. **Local Development**: Use local Graylog for development
2. **Azure Deployment**: Configure remote Graylog access
3. **Hybrid Setup**: Use local Graylog with Azure application

### Configuration for Azure
```bash
# Setup remote access
.\graylog\setup_remote_access.ps1

# Configure application for remote Graylog
export GRAYLOG_HOST=your-graylog-host
export GRAYLOG_PORT=12201
```

## Production Considerations

### High Availability
For production deployments, consider:

1. **Graylog Cluster**: Use Graylog clustering for high availability
2. **Elasticsearch Cluster**: Set up Elasticsearch clustering
3. **MongoDB Replica Set**: Configure MongoDB replication
4. **Load Balancing**: Use load balancers for high availability

### Security
For production environments:

1. **Network Security**: Restrict access to Graylog services
2. **Authentication**: Enable proper authentication
3. **Encryption**: Use SSL/TLS for data in transit
4. **Access Control**: Implement proper access controls

### Performance
For optimal performance:

1. **Resource Allocation**: Allocate appropriate resources
2. **Index Management**: Configure proper index management
3. **Log Retention**: Set up log retention policies
4. **Monitoring**: Monitor Graylog performance metrics

## Documentation

### `azure-container-apps-integration.md`
Comprehensive guide for integrating Graylog with Azure Container Apps including:
- Azure deployment configuration
- Network setup
- Security configuration
- Performance optimization
- Troubleshooting guide
