# src/main.py
from __future__ import annotations

import logging
import signal
import threading
import time
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from collections import deque
import os # Added for os.getenv

from flask import Flask, jsonify, request

from .config import Settings
from .cody_client import CodyClient
from .store import Store
from .transcript import format_transcript
from .zoho_client import ZohoClient
from .app_insights_handler import create_app_insights_handler

# -----------------------------------------------------------------------------
# Custom Log Handler for Recent Logs
# -----------------------------------------------------------------------------
class RecentLogHandler(logging.Handler):
    """Handler that keeps recent log entries in memory for API access."""
    
    def __init__(self, max_entries: int = 100):
        super().__init__()
        self.max_entries = max_entries
        self.logs = deque(maxlen=max_entries)
    
    def emit(self, record):
        try:
            log_entry = {
                "timestamp": record.created,
                "level": record.levelname,
                "logger": record.name,
                "message": self.format(record)
            }
            self.logs.append(log_entry)
        except Exception:
            # Don't let logging errors break the application
            pass
    
    def get_recent_logs(self, limit: Optional[int] = None) -> List[Dict[str, Any]]:
        """Get recent log entries, optionally limited by count."""
        logs = list(self.logs)
        if limit is not None:
            logs = logs[-limit:]
        return logs

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
# Create the recent log handler
recent_log_handler = RecentLogHandler(max_entries=200)

# Set up basic logging first
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(), recent_log_handler],
)
logger = logging.getLogger("src.main")

# Graylog integration will be set up after settings are loaded

# -----------------------------------------------------------------------------
# Flask app
# -----------------------------------------------------------------------------
app = Flask(__name__)

# -----------------------------------------------------------------------------
# Globals (initialized in main())
# -----------------------------------------------------------------------------
settings: Optional[Settings] = None
store: Optional[Store] = None
cody: Optional[CodyClient] = None
zoho: Optional[ZohoClient] = None
app_insights: Optional[Any] = None  # Application Insights handler
stop_event = threading.Event()
flask_server = None  # Will hold the Flask server instance

# Conversation processing metrics
conversation_metrics = {
    "total_processed": 0,
    "total_skipped": 0,
    "total_errors": 0,
    "last_processing_time": None,
    "processing_start_time": None,
    "cases_created": 0,
    "last_case_created": None,
}

# -----------------------------------------------------------------------------
# HTTP endpoints
# -----------------------------------------------------------------------------
@app.get("/health")
def health():
    return {"status": "ok"}, 200


@app.get("/metrics")
def metrics():
    """Get current business metrics and application status."""
    global conversation_metrics, app_insights
    
    # Get basic metrics
    metrics_data = {
        "status": "ok",
        "uptime_seconds": time.time() - app.start_time if hasattr(app, 'start_time') else None,
        "conversation_metrics": conversation_metrics.copy()
    }
    
    # Add Application Insights business metrics if available
    if app_insights:
        try:
            ai_metrics = app_insights.get_business_metrics()
            metrics_data["application_insights_metrics"] = ai_metrics
        except Exception as e:
            logger.warning("Failed to get Application Insights metrics: %s", e)
            metrics_data["application_insights_metrics"] = {"error": str(e)}
    
    return metrics_data, 200
def metrics():
    try:
        token_metrics = zoho.get_token_metrics() if zoho else {}
        
        # Calculate processing rate
        processing_rate = 0
        if conversation_metrics["processing_start_time"]:
            uptime = time.time() - conversation_metrics["processing_start_time"]
            if uptime > 0:
                processing_rate = conversation_metrics["total_processed"] / (uptime / 3600)  # per hour
        
        data = {
            "application": {
                "status": "running",
                "uptime_seconds": (time.time() - getattr(app, "start_time", time.time())),
                "polling_active": not stop_event.is_set(),
            },
            "conversations": {
                "total_processed": conversation_metrics["total_processed"],
                "total_skipped": conversation_metrics["total_skipped"],
                "total_errors": conversation_metrics["total_errors"],
                "cases_created": conversation_metrics["cases_created"],
                "processing_rate_per_hour": round(processing_rate, 2),
                "last_processing_time": conversation_metrics["last_processing_time"],
                "last_case_created": conversation_metrics["last_case_created"],
                "processing_start_time": conversation_metrics["processing_start_time"],
            },
            "tokens": token_metrics,
            "timestamp": time.time(),
        }
        return jsonify(data), 200
    except Exception as e:
        logger.exception("Error building /metrics response: %s", e)
        return {"error": str(e)}, 500


@app.get("/logs")
def logs():
    """Retrieve recent log entries."""
    try:
        # Get limit from query parameter, default to 50
        limit = request.args.get("limit", 50, type=int)
        if limit is None or limit <= 0:
            limit = 50
        if limit > 200:  # Cap at 200 entries
            limit = 200
        
        # Get level filter from query parameter
        level_filter = request.args.get("level", "").upper()
        
        # Get recent logs
        recent_logs = recent_log_handler.get_recent_logs(limit=limit)
        
        # Apply level filter if specified
        if level_filter:
            valid_levels = ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
            if level_filter in valid_levels:
                recent_logs = [
                    log for log in recent_logs 
                    if log["level"] == level_filter
                ]
        
        data = {
            "logs": recent_logs,
            "count": len(recent_logs),
            "level_filter": level_filter if level_filter else None,
            "timestamp": time.time(),
        }
        return jsonify(data), 200
    except Exception as e:
        logger.exception("Error building /logs response: %s", e)
        return {"error": str(e)}, 500


@app.get("/debug/app-insights")
def debug_app_insights():
    """Debug endpoint to check Application Insights status."""
    global app_insights, settings
    
    debug_info = {
        "app_insights_configured": app_insights is not None,
        "app_insights_initialized": app_insights._initialized if app_insights else False,
        "settings": {
            "ENABLE_APPLICATION_INSIGHTS": settings.ENABLE_APPLICATION_INSIGHTS if settings else None,
            "APPLICATIONINSIGHTS_CONNECTION_STRING": "SET" if (settings and settings.APPLICATIONINSIGHTS_CONNECTION_STRING) else "NOT SET",
            "APPLICATIONINSIGHTS_ROLE_NAME": settings.APPLICATIONINSIGHTS_ROLE_NAME if settings else None
        },
        "environment_variables": {
            "ENABLE_APPLICATION_INSIGHTS": os.getenv("ENABLE_APPLICATION_INSIGHTS"),
            "APPLICATIONINSIGHTS_CONNECTION_STRING": "SET" if os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING") else "NOT SET",
            "APPLICATIONINSIGHTS_ROLE_NAME": os.getenv("APPLICATIONINSIGHTS_ROLE_NAME")
        }
    }
    
    # Add connectivity test if Application Insights is available
    if app_insights:
        try:
            connectivity_results = app_insights.test_connectivity()
            debug_info["connectivity"] = connectivity_results
        except Exception as e:
            debug_info["connectivity"] = {"error": str(e)}
    
    return debug_info

@app.get("/debug/test-telemetry")
def test_telemetry():
    """Test endpoint to send test telemetry to Application Insights."""
    global app_insights
    
    if not app_insights:
        return {"error": "Application Insights not configured"}
    
    try:
        # Send test event
        app_insights.log_event("test_event", {
            "test": "value",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "source": "debug_endpoint"
        })
        
        # Send test metric
        app_insights.log_metric("test_metric", 42.0, {
            "test": "value",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "source": "debug_endpoint"
        })
        
        return {
            "status": "success",
            "message": "Test telemetry sent",
            "timestamp": datetime.now(timezone.utc).isoformat()
        }
        
    except Exception as e:
        return {
            "status": "error",
            "error": str(e),
            "timestamp": datetime.now(timezone.utc).isoformat()
        }

@app.get("/debug/test-telemetry-detailed")
def test_telemetry_detailed():
    """Detailed test endpoint to debug Application Insights telemetry."""
    global app_insights
    
    if not app_insights:
        return {"error": "Application Insights not configured"}
    
    results = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "tests": {}
    }
    
    try:
        # Test 1: Basic event logging
        try:
            app_insights.log_event("detailed_test_event", {
                "test_type": "basic_event",
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "source": "detailed_debug_endpoint"
            })
            results["tests"]["basic_event"] = "success"
        except Exception as e:
            results["tests"]["basic_event"] = f"failed: {str(e)}"
        
        # Test 2: Basic metric logging
        try:
            app_insights.log_metric("detailed_test_metric", 123.45, {
                "test_type": "basic_metric",
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "source": "detailed_debug_endpoint"
            })
            results["tests"]["basic_metric"] = "success"
        except Exception as e:
            results["tests"]["basic_metric"] = f"failed: {str(e)}"
        
        # Test 3: Direct REST API call
        try:
            success = app_insights._send_telemetry_direct("Event", {
                "ver": 2,
                "name": "direct_api_test",
                "properties": {
                    "test_type": "direct_api",
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "source": "detailed_debug_endpoint"
                }
            })
            results["tests"]["direct_api"] = "success" if success else "failed"
        except Exception as e:
            results["tests"]["direct_api"] = f"failed: {str(e)}"
        
        # Test 4: Force flush
        try:
            app_insights.force_flush_telemetry()
            results["tests"]["force_flush"] = "success"
        except Exception as e:
            results["tests"]["force_flush"] = f"failed: {str(e)}"
        
        results["status"] = "completed"
        
    except Exception as e:
        results["status"] = "error"
        results["error"] = str(e)
    
    return results


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
def _conversation_subject(conv: Dict[str, Any]) -> str:
    """
    Build a concise case subject, using the conversation timestamp if present.
    """
    # Try common timestamp keys; fall back to now (UTC)
    ts = conv.get("created_at") or conv.get("createdAt") or conv.get("timestamp")
    try:
        # Handle ISO 8601 with possible 'Z'
        dt = datetime.fromisoformat(str(ts).replace("Z", "+00:00")).astimezone()
    except Exception:
        dt = datetime.now(timezone.utc).astimezone()
    return dt.strftime("Cody Chat - %Y-%m-%d %H:%M")


def _calculate_conversation_metrics(messages: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Compute simple metrics used for optional custom fields on the Case.
    Robust to either Cody message shape:
      - {"content": "...", "machine": True/False}
      - {"content": "...", "role": "user"|"assistant"|...}
    """
    total = len(messages)
    user_cnt = 0
    bot_cnt = 0
    chars = 0

    for m in messages:
        content = (m.get("content") or "").strip()
        chars += len(content)

        # Prefer 'machine' flag if present; otherwise infer from 'role'
        if "machine" in m:
            bot_cnt += 1 if m.get("machine") else 0
            user_cnt += 0 if m.get("machine") else 1
        else:
            role = (m.get("role") or "").lower()
            if role in ("assistant", "bot"):
                bot_cnt += 1
            else:
                user_cnt += 1

    avg_len = (chars // total) if total else 0
    return {
        "Message_Count": total,
        "User_Messages": user_cnt,
        "Assistant_Messages": bot_cnt,
        "Total_Characters": chars,
        "Average_Message_Length": avg_len,
    }


# -----------------------------------------------------------------------------
# Poller
# -----------------------------------------------------------------------------
def poll_loop():
    """
    Continuously poll Cody for new conversations and create Zoho Cases.
    Uses Redis to deduplicate by conversation id.
    """
    assert settings and store and cody and zoho
    interval = settings.POLL_INTERVAL_SECONDS
    bot_id = settings.CODY_BOT_ID

    logger.info("Starting Cody poller (bot_id=%s, interval=%ss)", bot_id, interval)
    
    # Initialize processing start time
    conversation_metrics["processing_start_time"] = time.time()

    while not stop_event.is_set():
        try:
            logger.info("Fetching conversations from Cody…")
            poll_start_time = time.time()
            conversations = cody.list_conversations(bot_id=bot_id)  # returns a list
            poll_duration = time.time() - poll_start_time
            logger.info("Retrieved %d conversations from Cody", len(conversations))
            
            # Track Cody polling with Application Insights
            if app_insights:
                app_insights.track_cody_poll(
                    conversations_found=len(conversations),
                    poll_duration=poll_duration
                )

            processed_count = 0
            skipped_count = 0

            for conv in conversations:
                # Check for stop event between each conversation
                if stop_event.is_set():
                    logger.info("Stop event received during conversation processing, exiting")
                    return
                    
                conv_id = str(conv.get("id") or "")
                if not conv_id:
                    continue

                # Note: Duplicate checking is now handled by Zoho search instead of Redis
                # This allows the application to work reliably across container restarts

                title = conv.get("name") or conv.get("title") or "Conversation"
                logger.info("Processing conversation %s (%s)", conv_id, title)

                # Track conversation processing with Application Insights
                processing_start_time = time.time()
                case_created = False

                # Fetch messages and format transcript
                messages = cody.list_messages(conversation_id=conv_id)
                logger.info("Retrieved %d messages for conversation %s", len(messages), conv_id)

                transcript = format_transcript(messages)
                if not transcript.strip():
                    logger.info("Conversation %s has no content; marking processed and skipping", conv_id)
                    store.mark_processed(conv_id)
                    skipped_count += 1
                    continue

                metrics = _calculate_conversation_metrics(messages)
                subject = _conversation_subject(conv)

                # Create Zoho Case with optional duplicate checking
                case_result = None
                case_id = None
                case_was_created = False
                
                if getattr(settings, "ZOHO_ENABLE_DUPLICATE_CHECK", True):
                    # Use duplicate checking (recommended for Azure deployments)
                    case_result = zoho.create_case_with_duplicate_check(
                        subject=subject,
                        description=transcript,
                        cody_conversation_id=conv_id,  # Use Cody ID for duplicate checking
                        contact_name=settings.ZOHO_CONTACT_NAME,
                        case_origin=settings.ZOHO_CASE_ORIGIN,
                        case_status=settings.ZOHO_CASE_STATUS,
                        attach_transcript_as_note=getattr(settings, "ZOHO_ATTACH_TRANSCRIPT_AS_NOTE", False),
                        metrics=metrics,
                    )
                    case_id = case_result.get("case_id")
                    case_was_created = case_result.get("was_created", False)
                else:
                    # Use original method without duplicate checking
                    case_id = zoho.create_case(
                        subject=subject,
                        description=transcript,
                        contact_name=settings.ZOHO_CONTACT_NAME,
                        case_origin=settings.ZOHO_CASE_ORIGIN,
                        case_status=settings.ZOHO_CASE_STATUS,
                        attach_transcript_as_note=getattr(settings, "ZOHO_ATTACH_TRANSCRIPT_AS_NOTE", False),
                        metrics=metrics,
                        cody_conversation_id=conv_id,  # Still store the ID for reference
                    )
                    case_was_created = case_id is not None  # Assume created if case_id returned
                
                # Track conversation processing with enhanced Application Insights telemetry
                processing_time = time.time() - processing_start_time
                
                # Always count as processed
                processed_count += 1
                conversation_metrics["total_processed"] += 1
                
                if case_id:
                    if case_was_created:
                        logger.info("New case %s created for conversation %s", case_id, conv_id)
                        conversation_metrics["cases_created"] += 1
                        conversation_metrics["last_case_created"] = time.time()
                    else:
                        logger.info("Existing case %s found for conversation %s", case_id, conv_id)
                        skipped_count += 1
                else:
                    logger.info("Failed to create case for conversation %s", conv_id)
                    conversation_metrics["total_errors"] += 1
                
                if app_insights:
                    # Calculate message and character counts for enhanced telemetry
                    message_count = len(messages)
                    character_count = sum(len(msg.get("content", "")) for msg in messages)
                    
                    app_insights.track_conversation_processing(
                        conversation_id=conv_id,
                        processing_time=processing_time,
                        success=case_id is not None,
                        case_created=case_was_created,
                        message_count=message_count,
                        character_count=character_count
                    )

            # Update cycle metrics
            conversation_metrics["total_skipped"] += skipped_count
            conversation_metrics["last_processing_time"] = time.time()

            # Track polling cycle with Application Insights
            cycle_duration = time.time() - processing_start_time
            if app_insights:
                app_insights.track_polling_cycle(
                    conversations_found=len(conversations),
                    processed=processed_count,
                    skipped=skipped_count,
                    errors=0,  # Will be updated in error handling
                    cycle_duration=cycle_duration
                )

            logger.info(
                "Polling cycle complete: %d processed, %d skipped",
                processed_count,
                skipped_count,
            )

        except RuntimeError as e:
            if "rate limit" in str(e).lower() or "rate limit" in str(e).lower():
                logger.warning("Zoho API rate limit hit - skipping this cycle: %s", e)
                conversation_metrics["total_errors"] += 1
                # Track rate limit with enhanced Application Insights telemetry
                if app_insights:
                    app_insights.track_rate_limit("zoho")
                    app_insights.log_exception(e, {
                        "error_type": "rate_limit_error",
                        "context": "poll_loop",
                        "api": "zoho"
                    })
                # Sleep longer on rate limit to allow recovery
                if stop_event.wait(interval * 2):
                    logger.info("Stop event received, exiting poll loop")
                    break
                continue
            else:
                logger.exception("Runtime error in poll loop: %s", e)
                conversation_metrics["total_errors"] += 1
                # Track runtime error with Application Insights
                if app_insights:
                    app_insights.log_exception(e, {
                        "error_type": "runtime_error",
                        "context": "poll_loop"
                    })
        except Exception as e:
            logger.exception("Error in poll loop: %s", e)
            conversation_metrics["total_errors"] += 1
            # Track general error with Application Insights
            if app_insights:
                app_insights.log_exception(e, {
                    "error_type": "general_error",
                    "context": "poll_loop"
                })

        # Sleep between cycles (even after errors) - check stop event during sleep
        if stop_event.wait(interval):
            logger.info("Stop event received, exiting poll loop")
            break


# -----------------------------------------------------------------------------
# Metrics logging
# -----------------------------------------------------------------------------
def metrics_logging_loop():
    """
    Periodically log business metrics to Application Insights.
    Runs in a separate thread to avoid blocking the main poller.
    """
    global app_insights
    
    if not app_insights:
        return
        
    interval = 300  # Log metrics every 5 minutes
    logger.info("Starting metrics logging loop (interval=%ds)", interval)
    
    while not stop_event.is_set():
        try:
            # Log business metrics summary
            app_insights.log_business_metrics_summary()
            logger.debug("Business metrics logged to Application Insights")
            
        except Exception as e:
            logger.warning("Failed to log business metrics: %s", e)
        
        # Wait for next interval or stop event
        if stop_event.wait(interval):
            logger.info("Stop event received, exiting metrics logging loop")
            break
    
    logger.info("Metrics logging loop stopped")


# -----------------------------------------------------------------------------
# Signal handler
# -----------------------------------------------------------------------------
def _handle_signal(signum, frame):
    """Handle shutdown signals gracefully."""
    logger.info("Received signal %s; shutting down gracefully...", signum)
    stop_event.set()


# -----------------------------------------------------------------------------
# Entry point
# -----------------------------------------------------------------------------
def main():
    global settings, store, cody, zoho, app_insights

    logger.info("Starting Cody → Zoho (Cases) service…")
    app.start_time = time.time()
    logger.info("Starting at %s", app.start_time)
    
    # Set up signal handlers early
    signal.signal(signal.SIGTERM, _handle_signal)
    signal.signal(signal.SIGINT, _handle_signal)
    logger.info("Signal handlers configured")

    # Add a watchdog timer for startup
    startup_timeout = 60  # 60 seconds timeout for startup
    startup_start = time.time()

    try:
        # Load settings
        logger.info("Loading settings...")
        start_time = time.time()
        try:
            settings = Settings()
            logger.info(
                "Settings loaded in %.2f seconds (Cody URL=%s, Zoho URL=%s)",
                time.time() - start_time,
                settings.CODY_API_URL,
                settings.ZOHO_API_BASE_URL,
            )
            
            # Set up Graylog logging if enabled
            if settings.ENABLE_GRAYLOG:
                logger.info("Setting up Graylog logging...")
                try:
                    from .graylog_handler import setup_graylog_logging
                    
                    # Convert log level string to logging constant
                    log_level_map = {
                        "DEBUG": logging.DEBUG,
                        "INFO": logging.INFO,
                        "WARNING": logging.WARNING,
                        "ERROR": logging.ERROR,
                        "CRITICAL": logging.CRITICAL
                    }
                    log_level = log_level_map.get(settings.GRAYLOG_LOG_LEVEL, logging.INFO)
                    
                    graylog_handler = setup_graylog_logging(
                        host=settings.GRAYLOG_HOST,
                        port=settings.GRAYLOG_PORT,
                        protocol=settings.GRAYLOG_PROTOCOL,
                        application_name=settings.GRAYLOG_APPLICATION_NAME,
                        environment=settings.GRAYLOG_ENVIRONMENT,
                        log_level=log_level
                    )
                    
                    if graylog_handler:
                        # Add Graylog handler to root logger
                        logging.getLogger().addHandler(graylog_handler)
                        logger.info(
                            "Graylog logging enabled (host=%s, port=%s, protocol=%s)",
                            settings.GRAYLOG_HOST, settings.GRAYLOG_PORT, settings.GRAYLOG_PROTOCOL
                        )
                    else:
                        logger.warning("Failed to setup Graylog handler, continuing without Graylog")
                        
                except Exception as e:
                    logger.warning("Failed to setup Graylog logging: %s", e)
                    logger.info("Continuing without Graylog logging")
            else:
                logger.info("Graylog logging disabled")
                
            # Set up Application Insights if enabled
            logger.info("Checking Application Insights configuration...")
            logger.info("ENABLE_APPLICATION_INSIGHTS: %s", settings.ENABLE_APPLICATION_INSIGHTS)
            logger.info("APPLICATIONINSIGHTS_CONNECTION_STRING: %s", "SET" if settings.APPLICATIONINSIGHTS_CONNECTION_STRING else "NOT SET")
            logger.info("APPLICATIONINSIGHTS_ROLE_NAME: %s", settings.APPLICATIONINSIGHTS_ROLE_NAME)
            
            if settings.ENABLE_APPLICATION_INSIGHTS and settings.APPLICATIONINSIGHTS_CONNECTION_STRING:
                logger.info("Setting up Application Insights...")
                try:
                    app_insights = create_app_insights_handler(
                        connection_string=settings.APPLICATIONINSIGHTS_CONNECTION_STRING,
                        role_name=settings.APPLICATIONINSIGHTS_ROLE_NAME
                    )
                    
                    if app_insights:
                        logger.info("Application Insights enabled")
                    else:
                        logger.warning("Failed to setup Application Insights handler, continuing without Application Insights")
                        
                except Exception as e:
                    logger.warning("Failed to setup Application Insights: %s", e)
                    logger.info("Continuing without Application Insights")
            else:
                logger.info("Application Insights disabled - ENABLE_APPLICATION_INSIGHTS: %s, CONNECTION_STRING: %s", 
                           settings.ENABLE_APPLICATION_INSIGHTS, "SET" if settings.APPLICATIONINSIGHTS_CONNECTION_STRING else "NOT SET")
                    
        except Exception as e:
            logger.error("Failed to load settings: %s", e)
            logger.error("Please check your .env file or env.template file")
            raise
        
        # Check startup timeout
        if time.time() - startup_start > startup_timeout:
            logger.error("Startup timeout exceeded (%.1f seconds)", startup_timeout)
            raise RuntimeError("Startup timeout exceeded")

        # Store (Redis)
        logger.info("Initializing Redis store...")
        start_time = time.time()
        try:
            store = Store(settings.REDIS_URL)
            if store.use_redis:
                logger.info("Redis store initialized successfully in %.2f seconds", time.time() - start_time)
            else:
                logger.info("Redis store initialized with in-memory fallback in %.2f seconds", time.time() - start_time)
        except Exception as e:
            logger.error("Failed to initialize store: %s", e)
            logger.error("This is unexpected - Store should handle Redis failures gracefully")
            raise
        
        # Check startup timeout
        if time.time() - startup_start > startup_timeout:
            logger.error("Startup timeout exceeded (%.1f seconds)", startup_timeout)
            raise RuntimeError("Startup timeout exceeded")

        # Cody client
        logger.info("Initializing Cody client...")
        start_time = time.time()
        try:
            cody = CodyClient(settings.CODY_API_URL, settings.CODY_API_KEY)
            logger.info("Cody client initialized in %.2f seconds", time.time() - start_time)
        except Exception as e:
            logger.error("Failed to initialize Cody client: %s", e)
            raise
        
        # Check startup timeout
        if time.time() - startup_start > startup_timeout:
            logger.error("Startup timeout exceeded (%.1f seconds)", startup_timeout)
            raise RuntimeError("Startup timeout exceeded")

        # Prefer env access token; else use Redis-cached token (seeded by token_cli)
        logger.info("Getting cached access token...")
        start_time = time.time()
        cached_token = settings.ZOHO_ACCESS_TOKEN or store.get_access_token()
        logger.info("Access token retrieved in %.2f seconds", time.time() - start_time)
        
        # Check startup timeout
        if time.time() - startup_start > startup_timeout:
            logger.error("Startup timeout exceeded (%.1f seconds)", startup_timeout)
            raise RuntimeError("Startup timeout exceeded")

        # Zoho client (new robust refresh logic should adopt api_domain after refresh)
        logger.info("Initializing Zoho client...")
        start_time = time.time()
        try:
            zoho = ZohoClient(
                api_base_url=settings.ZOHO_API_BASE_URL,
                api_version=settings.ZOHO_API_VERSION,
                access_token=cached_token,
                client_id=settings.ZOHO_CLIENT_ID,
                client_secret=settings.ZOHO_CLIENT_SECRET,
                refresh_token=settings.ZOHO_REFRESH_TOKEN,
                accounts_base_url=settings.ZOHO_ACCOUNTS_BASE_URL,
                timeout=30,
            )
            logger.info("Zoho client initialized in %.2f seconds", time.time() - start_time)
        except Exception as e:
            logger.error("Failed to initialize Zoho client: %s", e)
            raise
        
        # Check startup timeout
        if time.time() - startup_start > startup_timeout:
            logger.error("Startup timeout exceeded (%.1f seconds)", startup_timeout)
            raise RuntimeError("Startup timeout exceeded")

        # Start poller thread
        logger.info("Creating polling thread...")
        poller_thread = threading.Thread(target=poll_loop, name="cody-poller", daemon=True)
        logger.info("Starting polling thread...")
        poller_thread.start()
        logger.info("Cody poller started successfully")
        
        # Start metrics logging thread if Application Insights is enabled
        if app_insights:
            logger.info("Starting metrics logging thread...")
            metrics_thread = threading.Thread(target=metrics_logging_loop, name="metrics-logger", daemon=True)
            metrics_thread.start()
            logger.info("Metrics logging thread started successfully")
        
        # Check startup timeout
        if time.time() - startup_start > startup_timeout:
            logger.error("Startup timeout exceeded (%.1f seconds)", startup_timeout)
            raise RuntimeError("Startup timeout exceeded")

        # Run Flask with proper shutdown handling
        logger.info("HTTP server listening on 0.0.0.0:%s", settings.PORT)
        logger.info("Application startup completed in %.2f seconds", time.time() - startup_start)
        try:
            from werkzeug.serving import make_server
            
            # Create a custom server that can be shut down
            server = make_server('0.0.0.0', settings.PORT, app)
            flask_server = server
            
            # Run the server in a separate thread
            server_thread = threading.Thread(target=server.serve_forever, daemon=True)
            server_thread.start()
            logger.info("Flask server started in background thread")
            
            # Wait for stop event in main thread
            while not stop_event.is_set():
                time.sleep(0.1)
            
            logger.info("Shutdown signal received, stopping server...")
            server.shutdown()
            server_thread.join(timeout=5)
            logger.info("Server stopped successfully")
            
        except Exception as e:
            logger.error("Flask app failed to start: %s", e)
            raise
            
    except KeyboardInterrupt:
        logger.info("KeyboardInterrupt received, shutting down...")
        stop_event.set()
    except Exception as e:
        logger.error("Application startup failed: %s", e)
        import traceback
        traceback.print_exc()
        stop_event.set()
    finally:
        # Cleanup
        logger.info("Performing cleanup...")
        if store:
            try:
                store.close()
                logger.info("Store connection closed")
            except Exception as e:
                logger.warning("Error closing store: %s", e)
        logger.info("Cleanup complete")


if __name__ == "__main__":
    main()
