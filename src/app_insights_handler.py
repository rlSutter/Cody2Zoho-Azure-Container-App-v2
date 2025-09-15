# src/app_insights_handler.py
"""
Azure Application Insights integration for Cody2Zoho.

This module provides Application Insights telemetry and logging integration
for monitoring the Cody2Zoho application in Azure.

Phase 2 Features:
- Enhanced business metrics tracking
- Performance monitoring
- Custom telemetry for case creation
- Comprehensive error tracking
- API performance monitoring
"""

import logging
import os
import time
from typing import Optional, Dict, Any, List
from contextlib import contextmanager
from datetime import datetime, timezone
import requests
import json

try:
    from opencensus.ext.azure.log_exporter import AzureLogHandler
    from opencensus.ext.azure.trace_exporter import AzureExporter
    from opencensus.trace.tracer import Tracer
    
    # Verify that the imports actually work
    if AzureLogHandler and AzureExporter and Tracer:
        APPLICATION_INSIGHTS_AVAILABLE = True
    else:
        APPLICATION_INSIGHTS_AVAILABLE = False
except ImportError as e:
    APPLICATION_INSIGHTS_AVAILABLE = False
    AzureLogHandler = None
    AzureExporter = None
    Tracer = None


class ApplicationInsightsHandler:
    """Enhanced handler for Azure Application Insights integration."""
    
    def __init__(self, connection_string: str, role_name: str = "Cody2Zoho"):
        """
        Initialize Application Insights handler.
        
        Args:
            connection_string: Application Insights connection string
            role_name: Role name for the application
        """
        if not APPLICATION_INSIGHTS_AVAILABLE:
            raise ImportError("Application Insights dependencies not available. Install opencensus-ext-azure.")
        
        self.connection_string = connection_string
        self.role_name = role_name
        self.logger = None
        self.tracer = None
        self._initialized = False
        
        # Business metrics tracking
        self.business_metrics = {
            "total_cases_created": 0,
            "total_conversations_processed": 0,
            "total_conversations_skipped": 0,
            "total_errors": 0,
            "total_api_calls": 0,
            "total_token_refreshes": 0,
            "total_cody_polls": 0,
            "last_case_created": None,
            "last_error": None,
            "processing_start_time": None
        }
        
    def initialize(self) -> None:
        """Initialize Application Insights components."""
        import logging
        logger = logging.getLogger(__name__)
        
        if self._initialized:
            logger.info("Application Insights already initialized")
            return
            
        logger.info("Starting Application Insights initialization...")
        
        try:
            logger.info("Setting up AzureExporter with connection string...")
            # Set up the tracer for custom telemetry
            # Use a more robust initialization approach
            try:
                self.tracer = Tracer(
                    exporter=AzureExporter(connection_string=self.connection_string)
                )
                logger.info("AzureExporter and Tracer created successfully")
            except Exception as e:
                logger.warning("Failed to create AzureExporter/Tracer: %s", e)
                logger.info("Continuing without tracer (logging will still work)")
                self.tracer = None
            
            logger.info("Setting up logging handler...")
            # Set up logging handler
            self.logger = logging.getLogger("app_insights")
            self.logger.setLevel(logging.INFO)
            
            logger.info("Creating AzureLogHandler...")
            # Add Azure Log Handler
            try:
                azure_handler = AzureLogHandler(connection_string=self.connection_string)
                azure_handler.setLevel(logging.INFO)
                
                # Configure the handler properly
                formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
                azure_handler.setFormatter(formatter)
                
                self.logger.addHandler(azure_handler)
                logger.info("AzureLogHandler added successfully")
                
                # Test the handler by sending a test message
                logger.info("Testing AzureLogHandler with test message...")
                test_logger = logging.getLogger("test_app_insights")
                test_logger.addHandler(azure_handler)
                test_logger.setLevel(logging.INFO)
                test_logger.info("Application Insights test message - initialization successful")
                logger.info("AzureLogHandler test completed")
                
            except Exception as e:
                logger.warning("Failed to create AzureLogHandler: %s", e)
                logger.info("Continuing without Azure log handler")
            
            logger.info("Initializing business metrics...")
            # Initialize business metrics
            self.business_metrics["processing_start_time"] = time.time()
            
            self._initialized = True
            logger.info("Application Insights initialized successfully for role: %s", self.role_name)
            
        except Exception as e:
            logger.error("Failed to initialize Application Insights: %s", e)
            logger.error("Exception type: %s", type(e).__name__)
            import traceback
            logger.error("Traceback: %s", traceback.format_exc())
            raise
    
    def _send_telemetry_direct(self, event_type: str, data: Dict[str, Any]) -> bool:
        """
        Send telemetry data directly to Application Insights using REST API.
        
        Args:
            event_type: Type of telemetry (event, metric, etc.)
            data: Telemetry data to send
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Extract instrumentation key from connection string
            if 'InstrumentationKey=' not in self.connection_string:
                return False
                
            instrumentation_key = self.connection_string.split('InstrumentationKey=')[1].split(';')[0]
            
            # Prepare the telemetry data based on type
            if event_type == "Event":
                telemetry_data = {
                    "name": f"Microsoft.ApplicationInsights.{instrumentation_key}.Event",
                    "time": datetime.now(timezone.utc).isoformat(),
                    "iKey": instrumentation_key,
                    "tags": {
                        "ai.cloud.role": self.role_name,
                        "ai.internal.sdkVersion": "python:opencensus-ext-azure"
                    },
                    "data": {
                        "baseType": "EventData",
                        "baseData": {
                            "ver": 2,
                            "name": data.get("name", "unknown"),
                            "properties": data.get("properties", {})
                        }
                    }
                }
            elif event_type == "Metric":
                telemetry_data = {
                    "name": f"Microsoft.ApplicationInsights.{instrumentation_key}.Metric",
                    "time": datetime.now(timezone.utc).isoformat(),
                    "iKey": instrumentation_key,
                    "tags": {
                        "ai.cloud.role": self.role_name,
                        "ai.internal.sdkVersion": "python:opencensus-ext-azure"
                    },
                    "data": {
                        "baseType": "MetricData",
                        "baseData": {
                            "ver": 2,
                            "metrics": [
                                {
                                    "name": data.get("name", "unknown"),
                                    "kind": "Measurement",
                                    "value": data.get("value", 0.0)
                                }
                            ],
                            "properties": data.get("properties", {})
                        }
                    }
                }
            else:
                return False
            
            # Send to Application Insights endpoint
            endpoint = f"https://eastus-8.in.applicationinsights.azure.com/v2/track"
            headers = {
                "Content-Type": "application/json",
                "User-Agent": "Cody2Zoho/1.0"
            }
            
            response = requests.post(endpoint, json=telemetry_data, headers=headers, timeout=10)
            
            if response.status_code == 200:
                return True
            else:
                print(f"Failed to send telemetry: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            print(f"Error sending telemetry directly: {e}")
            return False
    
    def test_connectivity(self) -> Dict[str, bool]:
        """
        Test network connectivity to Application Insights endpoints.
        
        Returns:
            Dict with connectivity test results
        """
        results = {
            "ingestion_endpoint": False,
            "live_endpoint": False,
            "direct_api": False
        }
        
        try:
            # Test ingestion endpoint
            if 'IngestionEndpoint=' in self.connection_string:
                ingestion_endpoint = self.connection_string.split('IngestionEndpoint=')[1].split(';')[0]
                try:
                    response = requests.get(ingestion_endpoint, timeout=5)
                    results["ingestion_endpoint"] = response.status_code < 500
                except Exception as e:
                    print(f"Ingestion endpoint test failed: {e}")
            
            # Test live endpoint
            if 'LiveEndpoint=' in self.connection_string:
                live_endpoint = self.connection_string.split('LiveEndpoint=')[1].split(';')[0]
                try:
                    response = requests.get(live_endpoint, timeout=5)
                    results["live_endpoint"] = response.status_code < 500
                except Exception as e:
                    print(f"Live endpoint test failed: {e}")
            
            # Test direct API endpoint
            try:
                response = requests.get("https://eastus-8.in.applicationinsights.azure.com/v2/track", timeout=5)
                results["direct_api"] = response.status_code < 500
            except Exception as e:
                print(f"Direct API test failed: {e}")
                
        except Exception as e:
            print(f"Connectivity test failed: {e}")
            
        return results
    
    def force_flush_telemetry(self) -> None:
        """
        Force flush any buffered telemetry data to Azure.
        """
        try:
            if self.logger:
                # Force flush all handlers
                for handler in self.logger.handlers:
                    if hasattr(handler, 'flush'):
                        handler.flush()
                print("Telemetry data flushed successfully")
        except Exception as e:
            print(f"Failed to flush telemetry: {e}")
    
    def log_event(self, event_name: str, properties: Optional[Dict[str, Any]] = None) -> None:
        """
        Log a custom event to Application Insights.
        
        Args:
            event_name: Name of the event
            properties: Additional properties for the event
        """
        if not self._initialized:
            return
            
        try:
            # Add common properties
            if properties is None:
                properties = {}
            
            properties.update({
                'role_name': self.role_name,
                'timestamp': datetime.now(timezone.utc).isoformat(),
                'event_type': 'custom_event'
            })
            
            # Try using AzureLogHandler first
            if self.logger:
                try:
                    self.logger.info(f"Event: {event_name}", extra={
                        'custom_dimensions': properties
                    })
                    # Force flush to ensure data is sent immediately
                    self.force_flush_telemetry()
                except Exception as e:
                    print(f"AzureLogHandler failed for event {event_name}: {e}")
            
            # Also try direct REST API as fallback
            try:
                event_data = {
                    "ver": 2,
                    "name": event_name,
                    "properties": properties
                }
                self._send_telemetry_direct("Event", event_data)
            except Exception as e:
                print(f"Direct telemetry failed for event {event_name}: {e}")
                
        except Exception as e:
            print(f"Failed to log event {event_name}: {e}")
    
    def log_metric(self, metric_name: str, value: float, properties: Optional[Dict[str, Any]] = None) -> None:
        """
        Log a custom metric to Application Insights.
        
        Args:
            metric_name: Name of the metric
            value: Metric value
            properties: Additional properties for the metric
        """
        if not self._initialized:
            return
            
        try:
            # Add common properties
            if properties is None:
                properties = {}
            
            properties.update({
                'role_name': self.role_name,
                'timestamp': datetime.now(timezone.utc).isoformat(),
                'metric_type': 'custom_metric'
            })
            
            metric_properties = {
                'metric_name': metric_name,
                'metric_value': value
            }
            metric_properties.update(properties)
            
            # Try using AzureLogHandler first
            if self.logger:
                try:
                    self.logger.info(f"Metric: {metric_name} = {value}", extra={
                        'custom_dimensions': metric_properties
                    })
                    # Force flush to ensure data is sent immediately
                    self.force_flush_telemetry()
                except Exception as e:
                    print(f"AzureLogHandler failed for metric {metric_name}: {e}")
            
            # Also try direct REST API as fallback
            try:
                metric_data = {
                    "ver": 2,
                    "name": metric_name,
                    "value": value,
                    "properties": properties
                }
                self._send_telemetry_direct("Metric", metric_data)
            except Exception as e:
                print(f"Direct telemetry failed for metric {metric_name}: {e}")
            
        except Exception as e:
            print(f"Failed to log metric {metric_name}: {e}")
    
    def log_exception(self, exception: Exception, properties: Optional[Dict[str, Any]] = None) -> None:
        """
        Log an exception to Application Insights.
        
        Args:
            exception: The exception to log
            properties: Additional properties for the exception
        """
        if not self._initialized or not self.logger:
            return
            
        try:
            # Add common properties
            if properties is None:
                properties = {}
            
            properties.update({
                'role_name': self.role_name,
                'timestamp': datetime.now(timezone.utc).isoformat(),
                'exception_type': type(exception).__name__,
                'exception_message': str(exception)
            })
            
            self.logger.exception(f"Exception: {str(exception)}", extra={
                'custom_dimensions': properties
            })
            
            # Update business metrics
            self.business_metrics["total_errors"] += 1
            self.business_metrics["last_error"] = {
                "timestamp": time.time(),
                "type": type(exception).__name__,
                "message": str(exception)
            }
                
        except Exception as e:
            print(f"❌ Failed to log exception: {e}")
    
    @contextmanager
    def track_operation(self, operation_name: str, properties: Optional[Dict[str, Any]] = None):
        """
        Track an operation with custom telemetry.
        
        Args:
            operation_name: Name of the operation
            properties: Additional properties for the operation
            
        Yields:
            Span: The telemetry span for the operation
        """
        if not self._initialized or not self.tracer:
            yield None
            return
            
        try:
            with self.tracer.span(operation_name) as span:
                # Note: span.add_attribute is not available without Span import
                # Properties are still tracked via the span context
                yield span
                
        except Exception as e:
            print(f"Failed to track operation {operation_name}: {e}")
            yield None
    
    def track_conversation_processing(self, conversation_id: str, processing_time: float, 
                                    success: bool, case_created: bool = False, 
                                    message_count: int = 0, character_count: int = 0) -> None:
        """
        Track conversation processing metrics with enhanced business data.
        
        Args:
            conversation_id: ID of the conversation
            processing_time: Time taken to process (seconds)
            success: Whether processing was successful
            case_created: Whether a case was created
            message_count: Number of messages in conversation
            character_count: Total character count
        """
        properties = {
            'conversation_id': conversation_id,
            'processing_time_seconds': processing_time,
            'success': success,
            'case_created': case_created,
            'message_count': message_count,
            'character_count': character_count,
            'role_name': self.role_name
        }
        
        # Log the event
        self.log_event('conversation_processed', properties)
        
        # Log metrics
        self.log_metric('conversation_processing_time', processing_time, {
            'conversation_id': conversation_id,
            'success': success
        })
        
        self.log_metric('conversation_message_count', message_count, {
            'conversation_id': conversation_id
        })
        
        self.log_metric('conversation_character_count', character_count, {
            'conversation_id': conversation_id
        })
        
        # Update business metrics
        self.business_metrics["total_conversations_processed"] += 1
        
        if case_created:
            self.track_case_creation(conversation_id, processing_time, message_count, character_count)
    
    def track_case_creation(self, conversation_id: str, processing_time: float = None,
                           message_count: int = 0, character_count: int = 0) -> None:
        """
        Track case creation with comprehensive business metrics.
        
        Args:
            conversation_id: ID of the conversation
            processing_time: Time taken to process (seconds)
            message_count: Number of messages in conversation
            character_count: Total character count
        """
        properties = {
            'conversation_id': conversation_id,
            'message_count': message_count,
            'character_count': character_count,
            'role_name': self.role_name
        }
        
        if processing_time:
            properties['processing_time_seconds'] = processing_time
        
        # Log the event
        self.log_event('case_created', properties)
        
        # Log business metrics
        self.log_metric('cases_created_total', 1, {
            'conversation_id': conversation_id
        })
        
        self.log_metric('conversation_message_count_at_creation', message_count, {
            'conversation_id': conversation_id
        })
        
        self.log_metric('conversation_character_count_at_creation', character_count, {
            'conversation_id': conversation_id
        })
        
        # Update business metrics
        self.business_metrics["total_cases_created"] += 1
        self.business_metrics["last_case_created"] = {
            "timestamp": time.time(),
            "conversation_id": conversation_id,
            "message_count": message_count,
            "character_count": character_count
        }
    
    def track_api_call(self, api_name: str, endpoint: str, duration: float, 
                      success: bool, status_code: Optional[int] = None,
                      response_size: Optional[int] = None) -> None:
        """
        Track API call metrics with enhanced performance data.
        
        Args:
            api_name: Name of the API (e.g., 'cody', 'zoho')
            endpoint: API endpoint
            duration: Call duration (seconds)
            success: Whether the call was successful
            status_code: HTTP status code
            response_size: Size of response in bytes
        """
        properties = {
            'api_name': api_name,
            'endpoint': endpoint,
            'duration_seconds': duration,
            'success': success,
            'role_name': self.role_name
        }
        
        if status_code:
            properties['status_code'] = status_code
        if response_size:
            properties['response_size_bytes'] = response_size
        
        # Log the event
        self.log_event('api_call', properties)
        
        # Log metrics
        self.log_metric('api_call_duration', duration, {
            'api_name': api_name,
            'endpoint': endpoint,
            'success': success
        })
        
        if response_size:
            self.log_metric('api_response_size', response_size, {
                'api_name': api_name,
                'endpoint': endpoint
            })
        
        # Update business metrics
        self.business_metrics["total_api_calls"] += 1
    
    def track_token_refresh(self, success: bool, duration: float = None, 
                           attempts: int = 1, error_message: str = None) -> None:
        """
        Track token refresh operations with detailed metrics.
        
        Args:
            success: Whether the refresh was successful
            duration: Time taken for refresh (seconds)
            attempts: Number of attempts made
            error_message: Error message if failed
        """
        properties = {
            'success': success,
            'attempts': attempts,
            'role_name': self.role_name
        }
        
        if duration:
            properties['duration_seconds'] = duration
        if error_message:
            properties['error_message'] = error_message
        
        # Log the event
        self.log_event('token_refresh', properties)
        
        # Log metrics
        if duration:
            self.log_metric('token_refresh_duration', duration, {
                'success': success
            })
        
        self.log_metric('token_refresh_attempts', attempts, {
            'success': success
        })
        
        # Update business metrics
        self.business_metrics["total_token_refreshes"] += 1
    
    def track_rate_limit(self, api_name: str, retry_after: Optional[int] = None) -> None:
        """
        Track rate limit events.
        
        Args:
            api_name: Name of the API that hit rate limit
            retry_after: Retry after time in seconds
        """
        properties = {
            'api_name': api_name,
            'role_name': self.role_name
        }
        
        if retry_after:
            properties['retry_after_seconds'] = retry_after
        
        # Log the event
        self.log_event('rate_limit_hit', properties)
        
        # Log metrics
        self.log_metric('rate_limit_events', 1, {
            'api_name': api_name
        })
    
    def track_polling_cycle(self, conversations_found: int, processed: int, 
                           skipped: int, errors: int, cycle_duration: float) -> None:
        """
        Track polling cycle metrics.
        
        Args:
            conversations_found: Number of conversations found
            processed: Number of conversations processed
            skipped: Number of conversations skipped
            errors: Number of errors in cycle
            cycle_duration: Duration of the cycle (seconds)
        """
        properties = {
            'conversations_found': conversations_found,
            'processed': processed,
            'skipped': skipped,
            'errors': errors,
            'cycle_duration_seconds': cycle_duration,
            'role_name': self.role_name
        }
        
        # Log the event
        self.log_event('polling_cycle_completed', properties)
        
        # Log metrics
        self.log_metric('polling_cycle_duration', cycle_duration)
        self.log_metric('conversations_found_per_cycle', conversations_found)
        self.log_metric('conversations_processed_per_cycle', processed)
        self.log_metric('conversations_skipped_per_cycle', skipped)
        self.log_metric('errors_per_cycle', errors)
        
        # Update business metrics
        self.business_metrics["total_conversations_skipped"] += skipped
        self.business_metrics["total_errors"] += errors
    
    def track_cody_poll(self, conversations_found: int, poll_duration: float) -> None:
        """
        Track each time the application polls Cody for conversations.
        
        Args:
            conversations_found: Number of conversations found in this poll
            poll_duration: Duration of the poll operation (seconds)
        """
        properties = {
            'conversations_found': conversations_found,
            'poll_duration_seconds': poll_duration,
            'role_name': self.role_name
        }
        
        # Log the event
        self.log_event('cody_poll_completed', properties)
        
        # Log metrics
        self.log_metric('cody_poll_count', 1, {
            'conversations_found': conversations_found
        })
        self.log_metric('cody_poll_duration', poll_duration, {
            'conversations_found': conversations_found
        })
        self.log_metric('conversations_found_per_poll', conversations_found)
        
        # Update business metrics
        self.business_metrics["total_cody_polls"] += 1
    
    def track_conversation_processing_ratio(self) -> None:
        """
        Track the ratio of conversations processed to cases created.
        This metric helps understand the efficiency of case creation.
        """
        if not self._initialized:
            return
            
        try:
            total_processed = self.business_metrics["total_conversations_processed"]
            total_created = self.business_metrics["total_cases_created"]
            
            if total_processed > 0:
                # Calculate success rate as percentage
                success_rate = (total_created / total_processed) * 100
                
                # Log the ratio metric
                self.log_metric('conversation_to_case_ratio', success_rate, {
                    'total_conversations_processed': total_processed,
                    'total_cases_created': total_created,
                    'role_name': self.role_name
                })
                
                # Log the raw counts as well
                self.log_metric('conversations_processed_total', total_processed, {
                    'metric_type': 'cumulative_count',
                    'role_name': self.role_name
                })
                
                self.log_metric('cases_created_total', total_created, {
                    'metric_type': 'cumulative_count', 
                    'role_name': self.role_name
                })
                
                # Log an event with the ratio information
                self.log_event('conversation_processing_ratio_updated', {
                    'conversations_processed': total_processed,
                    'cases_created': total_created,
                    'success_rate_percent': round(success_rate, 2),
                    'role_name': self.role_name
                })
                
        except Exception as e:
            print(f"Failed to track conversation processing ratio: {e}")
    
    def get_business_metrics(self) -> Dict[str, Any]:
        """
        Get current business metrics for dashboard/reporting.
        
        Returns:
            Dictionary containing current business metrics
        """
        uptime = None
        if self.business_metrics["processing_start_time"]:
            uptime = time.time() - self.business_metrics["processing_start_time"]
        
        # Calculate conversation to case ratio
        conversation_to_case_ratio = None
        if self.business_metrics["total_conversations_processed"] > 0:
            conversation_to_case_ratio = (self.business_metrics["total_cases_created"] / self.business_metrics["total_conversations_processed"]) * 100
        
        return {
            **self.business_metrics,
            "uptime_seconds": uptime,
            "cases_per_hour": self._calculate_rate_per_hour(self.business_metrics["total_cases_created"], uptime),
            "conversations_per_hour": self._calculate_rate_per_hour(self.business_metrics["total_conversations_processed"], uptime),
            "api_calls_per_hour": self._calculate_rate_per_hour(self.business_metrics["total_api_calls"], uptime),
            "cody_polls_per_hour": self._calculate_rate_per_hour(self.business_metrics["total_cody_polls"], uptime),
            "error_rate_percent": self._calculate_error_rate(),
            "conversation_to_case_ratio_percent": conversation_to_case_ratio
        }
    
    def _calculate_rate_per_hour(self, total: int, uptime_seconds: Optional[float]) -> Optional[float]:
        """Calculate rate per hour for a given total and uptime."""
        if not uptime_seconds or uptime_seconds <= 0:
            return None
        return (total / uptime_seconds) * 3600
    
    def _calculate_error_rate(self) -> Optional[float]:
        """Calculate error rate as percentage."""
        total_operations = (self.business_metrics["total_conversations_processed"] + 
                           self.business_metrics["total_conversations_skipped"])
        if total_operations == 0:
            return None
        return (self.business_metrics["total_errors"] / total_operations) * 100
    
    def log_business_metrics_summary(self) -> None:
        """Log a summary of current business metrics."""
        metrics = self.get_business_metrics()
        self.log_event('business_metrics_summary', metrics)
        
        # Also track the conversation processing ratio
        self.track_conversation_processing_ratio()


def create_app_insights_handler(connection_string: str, role_name: str = "Cody2Zoho") -> Optional[ApplicationInsightsHandler]:
    """
    Create an Application Insights handler if dependencies are available.
    
    Args:
        connection_string: Application Insights connection string
        role_name: Role name for the application
        
    Returns:
        ApplicationInsightsHandler instance or None if not available
    """
    import logging
    logger = logging.getLogger(__name__)
    
    logger.info("Creating Application Insights handler...")
    
    if not connection_string:
        logger.error("Application Insights connection string is empty or None")
        return None
    
    logger.info("Application Insights connection string provided: %s", connection_string[:50] + "..." if len(connection_string) > 50 else connection_string)
    
    if not APPLICATION_INSIGHTS_AVAILABLE:
        logger.error("Application Insights dependencies not available. Install opencensus-ext-azure.")
        logger.error("Required packages: opencensus-ext-azure, opencensus-ext-flask")
        return None
    
    logger.info("Application Insights dependencies are available")
    
    try:
        logger.info("Creating ApplicationInsightsHandler instance...")
        handler = ApplicationInsightsHandler(connection_string, role_name)
        logger.info("ApplicationInsightsHandler instance created successfully")
        
        logger.info("Initializing Application Insights handler...")
        try:
            handler.initialize()
            logger.info("Application Insights handler initialized successfully")
        except Exception as e:
            logger.warning("Failed to initialize Application Insights handler: %s", e)
            logger.info("Continuing with partially initialized handler")
            # Don't return None, continue with the handler even if initialization failed
        
        return handler
    except ImportError as e:
        logger.error("Import error during Application Insights setup: %s", e)
        return None
    except Exception as e:
        logger.error("Failed to create Application Insights handler: %s", e)
        logger.error("Exception type: %s", type(e).__name__)
        import traceback
        logger.error("Traceback: %s", traceback.format_exc())
        return None
