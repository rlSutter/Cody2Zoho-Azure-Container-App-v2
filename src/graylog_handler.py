"""
Graylog GELF Handler for structured logging to Graylog.
"""

import logging
import socket
import json
import time
import gzip
from typing import Optional, Dict, Any

class GraylogHandler(logging.Handler):
    """
    A logging handler that sends log records to Graylog via GELF protocol.
    
    This handler formats log records as GELF messages and sends them to a Graylog
    server using UDP, TCP, or HTTP transport. It supports structured logging with
    custom fields and automatic metadata extraction.
    """
    
    def __init__(self, 
                 host: str = "localhost", 
                 port: int = 12201, 
                 protocol: str = "udp",
                 application_name: str = "cody2zoho",
                 environment: str = "production",
                 max_message_size: int = 8192):
        """
        Initialize the Graylog handler.
        
        Args:
            host: Graylog server hostname or IP
            port: Graylog server port (12201 for GELF)
            protocol: Transport protocol ('udp', 'tcp', or 'http')
            application_name: Name of the application for log identification
            environment: Environment name (dev, staging, production, etc.)
            max_message_size: Maximum size of GELF messages in bytes
        """
        super().__init__()
        self.host = host
        self.port = port
        self.protocol = protocol.lower()
        self.application_name = application_name
        self.environment = environment
        self.max_message_size = max_message_size
        
        # Initialize transport
        self._setup_transport()
        
        # Default fields that will be added to every log message
        self.default_fields = {
            "_application": application_name,
            "_environment": environment,
            "_host": socket.gethostname(),
        }
    
    def _setup_transport(self):
        """Set up the transport mechanism based on protocol."""
        try:
            if self.protocol == "udp":
                self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                self.socket.settimeout(5.0)
            elif self.protocol == "tcp":
                self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                self.socket.settimeout(5.0)
                self.socket.connect((self.host, self.port))
            elif self.protocol == "http":
                import requests
                self.session = requests.Session()
                self.session.timeout = 5.0
                self.gelf_url = f"http://{self.host}:{self.port}/gelf"
            else:
                raise ValueError(f"Unsupported protocol: {self.protocol}")
        except Exception as e:
            # Fallback to null handler if transport setup fails
            self.socket = None
            self.session = None
            print(f"Warning: Failed to setup Graylog transport: {e}")
    
    def emit(self, record: logging.LogRecord):
        """
        Emit a log record to Graylog.
        
        Args:
            record: The log record to emit
        """
        try:
            # Create GELF message
            gelf_message = self._format_record(record)
            
            # Send message based on protocol
            if self.protocol == "udp":
                self._send_udp(gelf_message)
            elif self.protocol == "tcp":
                self._send_tcp(gelf_message)
            elif self.protocol == "http":
                self._send_http(gelf_message)
                
        except Exception as e:
            # Don't let logging errors break the application
            print(f"Graylog handler error: {e}")
    
    def _format_record(self, record: logging.LogRecord) -> Dict[str, Any]:
        """
        Format a log record as a GELF message.
        
        Args:
            record: The log record to format
            
        Returns:
            Dictionary containing the GELF message
        """
        # Convert log level to syslog level
        level_map = {
            logging.DEBUG: 7,
            logging.INFO: 6,
            logging.WARNING: 4,
            logging.ERROR: 3,
            logging.CRITICAL: 2
        }
        
        # Base GELF message
        gelf_message = {
            "version": "1.1",
            "host": socket.gethostname(),
            "short_message": self.format(record),
            "full_message": self.format(record),
            "timestamp": record.created,
            "level": level_map.get(record.levelno, 1),
            "facility": self.application_name,
        }
        
        # Add default fields
        gelf_message.update(self.default_fields)
        
        # Add custom fields from record
        if hasattr(record, 'gelf_fields'):
            for key, value in record.gelf_fields.items():
                if isinstance(key, str) and key.startswith('_'):
                    gelf_message[key] = value
        
        # Add exception information if present
        if record.exc_info:
            gelf_message["_exception"] = self.formatException(record.exc_info)
        
        # Add extra fields from record
        for key, value in record.__dict__.items():
            if key not in ['name', 'msg', 'args', 'levelname', 'levelno', 
                          'pathname', 'filename', 'module', 'lineno', 
                          'funcName', 'created', 'msecs', 'relativeCreated',
                          'thread', 'threadName', 'processName', 'process',
                          'getMessage', 'exc_info', 'exc_text', 'stack_info']:
                if isinstance(value, (str, int, float, bool)):
                    gelf_message[f"_{key}"] = value
        
        return gelf_message
    
    def _send_udp(self, message: Dict[str, Any]):
        """Send GELF message via UDP."""
        if self.socket:
            try:
                # Compress message if it's too large
                message_bytes = json.dumps(message).encode('utf-8')
                if len(message_bytes) > self.max_message_size:
                    message_bytes = gzip.compress(message_bytes)
                self.socket.sendto(message_bytes, (self.host, self.port))
            except Exception as e:
                print(f"UDP send error: {e}")
    
    def _send_tcp(self, message: Dict[str, Any]):
        """Send GELF message via TCP."""
        if self.socket:
            try:
                message_bytes = (json.dumps(message) + '\0').encode('utf-8')
                self.socket.send(message_bytes)
            except Exception as e:
                print(f"TCP send error: {e}")
    
    def _send_http(self, message: Dict[str, Any]):
        """Send GELF message via HTTP."""
        if hasattr(self, 'session'):
            try:
                response = self.session.post(
                    self.gelf_url,
                    json=message,
                    headers={'Content-Type': 'application/json'}
                )
                response.raise_for_status()
            except Exception as e:
                print(f"HTTP send error: {e}")
    
    def close(self):
        """Close the handler and cleanup resources."""
        try:
            if hasattr(self, 'socket') and self.socket:
                self.socket.close()
            if hasattr(self, 'session'):
                self.session.close()
        except Exception as e:
            print(f"Error closing Graylog handler: {e}")
        finally:
            super().close()


def setup_graylog_logging(host: str = "localhost", 
                         port: int = 12201, 
                         protocol: str = "udp",
                         application_name: str = "cody2zoho",
                         environment: str = "production",
                         log_level: int = logging.INFO) -> Optional[GraylogHandler]:
    """
    Set up Graylog logging for the application.
    
    Args:
        host: Graylog server hostname or IP
        port: Graylog server port
        protocol: Transport protocol ('udp', 'tcp', or 'http')
        application_name: Name of the application
        environment: Environment name
        log_level: Logging level for the handler
        
    Returns:
        GraylogHandler instance if setup successful, None otherwise
    """
    try:
        handler = GraylogHandler(
            host=host,
            port=port,
            protocol=protocol,
            application_name=application_name,
            environment=environment
        )
        handler.setLevel(log_level)
        
        # Add formatter
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        handler.setFormatter(formatter)
        
        return handler
    except Exception as e:
        print(f"Failed to setup Graylog logging: {e}")
        return None
