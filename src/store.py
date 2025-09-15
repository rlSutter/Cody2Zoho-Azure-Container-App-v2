from __future__ import annotations
import logging
import signal
import threading
import time
from typing import Optional
import redis

logger = logging.getLogger(__name__)

class Store:
    """
    Redis-backed state store for managing application state and caching.
    
    This class provides a simple interface for storing and retrieving
    application state data in Redis, including conversation processing status
    and token caching. Falls back to in-memory storage if Redis is not available.
    """
    
    def __init__(self, redis_url: str):
        """
        Initialize Redis store with connection URL.
        
        Args:
            redis_url: Redis connection URL (e.g., "redis://localhost:6379/0")
        """
        logger.info(f"Initializing Redis store with URL: {redis_url}")
        self.use_redis = True
        self.memory_store = {}  # Fallback in-memory store
        
        try:
            logger.debug("Creating Redis connection...")
            
            # Use a timeout wrapper to prevent hanging
            def create_redis_connection():
                return redis.from_url(
                    redis_url,
                    socket_timeout=5,  # 5 second timeout for socket operations
                    socket_connect_timeout=5,  # 5 second timeout for connection
                    retry_on_timeout=True,
                    health_check_interval=30
                )
            
            # Create connection with timeout
            self.r = create_redis_connection()
            logger.debug("Testing Redis connection with ping...")
            
            # Test the connection with a timeout
            def ping_with_timeout():
                return self.r.ping()
            
            # Use threading with timeout to prevent hanging
            result = None
            exception = None
            
            def ping_worker():
                nonlocal result, exception
                try:
                    result = ping_with_timeout()
                except Exception as e:
                    exception = e
            
            ping_thread = threading.Thread(target=ping_worker, daemon=True)
            ping_thread.start()
            ping_thread.join(timeout=10)  # 10 second timeout for ping
            
            if ping_thread.is_alive():
                logger.warning("Redis ping timed out after 10 seconds")
                raise Exception("Redis ping timeout")
            
            if exception:
                raise exception
                
            logger.debug("Redis store initialized successfully")
        except Exception as e:
            logger.warning(f"Redis connection failed: {e}")
            logger.warning("Falling back to in-memory storage (data will not persist between restarts)")
            self.use_redis = False
            self.r = None

    def get(self, key: str) -> Optional[str]:
        """
        Get a value from Redis store or in-memory fallback.
        
        Args:
            key: The key to retrieve
            
        Returns:
            The value if found, None otherwise
        """
        logger.debug(f"Getting value for key: {key}")
        
        if self.use_redis and self.r:
            try:
                value = self.r.get(key)
                if value is not None:
                    value = value.decode('utf-8')
                    logger.debug(f"Retrieved value for key {key}: {value[:50]}{'...' if len(value) > 50 else ''}")
                else:
                    logger.debug(f"No value found for key: {key}")
                return value
            except Exception as e:
                logger.warning(f"Redis get failed for key {key}: {e}")
                # Fall back to memory store
                self.use_redis = False
        
        # Use in-memory store
        value = self.memory_store.get(key)
        if value is not None:
            logger.debug(f"Retrieved value from memory for key {key}: {value[:50]}{'...' if len(value) > 50 else ''}")
        else:
            logger.debug(f"No value found in memory for key: {key}")
        return value

    def set(self, key: str, value: str) -> None:
        """
        Set a value in Redis store or in-memory fallback.
        
        Args:
            key: The key to set
            value: The value to store
        """
        logger.debug(f"Setting value for key: {key}")
        
        if self.use_redis and self.r:
            try:
                self.r.set(key, value)
                logger.debug(f"Successfully set value in Redis for key: {key}")
                return
            except Exception as e:
                logger.warning(f"Redis set failed for key {key}: {e}")
                # Fall back to memory store
                self.use_redis = False
        
        # Use in-memory store
        self.memory_store[key] = value
        logger.debug(f"Successfully set value in memory for key: {key}")

    def set_access_token(self, access_token: str, ttl_seconds: int = 3600) -> None:
        """
        Cache a Zoho access token with expiration.
        This method stores the access token in Redis with a TTL (Time To Live)
        to ensure the token expires automatically when it's no longer valid.
        This is useful for token management and automatic cleanup.
        Args:
            access_token: The access token to cache
            ttl_seconds: Time to live in seconds (default: 3600 = 1 hour)
        """
        logger.info(f"Caching access token with TTL: {ttl_seconds}s")
        
        if self.use_redis and self.r:
            try:
                self.r.setex("zoho_access_token", ttl_seconds, access_token)
                logger.debug("Access token cached successfully in Redis")
                return
            except Exception as e:
                logger.warning(f"Redis token caching failed: {e}")
                self.use_redis = False
        
        # Fall back to memory store (no TTL in memory)
        self.memory_store["zoho_access_token"] = access_token
        logger.debug("Access token cached in memory (no TTL)")

    def get_access_token(self) -> Optional[str]:
        """
        Get the cached Zoho access token.
        This method retrieves the access token from Redis cache or memory fallback.
        Returns None if the token is not cached or has expired.
        Returns:
            The cached access token if available and not expired, None otherwise
        """
        logger.debug("Retrieving cached access token")
        
        if self.use_redis and self.r:
            try:
                token = self.r.get("zoho_access_token")
                if token is not None:
                    token = token.decode('utf-8')
                    logger.debug("Cached access token found in Redis")
                else:
                    logger.debug("No cached access token found in Redis")
                return token
            except Exception as e:
                logger.warning(f"Redis token retrieval failed: {e}")
                self.use_redis = False
        
        # Fall back to memory store
        token = self.memory_store.get("zoho_access_token")
        if token is not None:
            logger.debug("Cached access token found in memory")
        else:
            logger.debug("No cached access token found in memory")
        return token

    def is_processed(self, conversation_id: str) -> bool:
        """
        Check if a conversation has already been processed.
        
        Args:
            conversation_id: The conversation ID to check
            
        Returns:
            True if the conversation has been processed, False otherwise
        """
        key = f"processed_conversation:{conversation_id}"
        logger.debug(f"Checking if conversation {conversation_id} is processed")
        
        if self.use_redis and self.r:
            try:
                exists = self.r.exists(key)
                logger.debug(f"Conversation {conversation_id} processed status: {exists}")
                return bool(exists)
            except Exception as e:
                logger.warning(f"Redis check failed for conversation {conversation_id}: {e}")
                self.use_redis = False
        
        # Fall back to memory store
        exists = key in self.memory_store
        logger.debug(f"Conversation {conversation_id} processed status (memory): {exists}")
        return exists

    def mark_processed(self, conversation_id: str) -> None:
        """
        Mark a conversation as processed.
        
        Args:
            conversation_id: The conversation ID to mark as processed
        """
        key = f"processed_conversation:{conversation_id}"
        logger.debug(f"Marking conversation {conversation_id} as processed")
        
        if self.use_redis and self.r:
            try:
                # Store with a reasonable TTL (e.g., 30 days) to avoid memory bloat
                self.r.setex(key, 30 * 24 * 3600, "1")
                logger.debug(f"Conversation {conversation_id} marked as processed in Redis")
                return
            except Exception as e:
                logger.warning(f"Redis mark processed failed for conversation {conversation_id}: {e}")
                self.use_redis = False
        
        # Fall back to memory store
        self.memory_store[key] = "1"
        logger.debug(f"Conversation {conversation_id} marked as processed in memory")

    def close(self) -> None:
        """
        Close the Redis connection and perform cleanup.
        """
        logger.info("Closing Redis store connection")
        if self.use_redis and self.r:
            try:
                self.r.close()
                logger.info("Redis connection closed successfully")
            except Exception as e:
                logger.warning(f"Error closing Redis connection: {e}")
        self.use_redis = False
        self.r = None
