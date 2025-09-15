from __future__ import annotations
import logging
from typing import Any, Dict, List, Optional
import requests

logger = logging.getLogger(__name__)

class CodyClient:
    """
    Cody API client for fetching conversations and messages.
    
    This client handles communication with the Cody API to retrieve:
    - List of conversations for a specific bot
    - Messages within each conversation
    - Pagination support for large datasets
    
    The client uses Bearer token authentication and supports configurable timeouts.
    """
    
    def __init__(self, base_url: str, api_key: str, timeout: int = 30):
        """
        Initialize Cody API client.
        
        Args:
            base_url: Base URL for Cody API (e.g., "https://getcody.ai/api/v1")
            api_version: API version to use
            api_key: API key for authentication
            timeout: Request timeout in seconds
        """
        logger.info(f"Initializing Cody client with base URL: {base_url}")
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key
        self.timeout = timeout
        logger.debug(f"Cody client initialized with timeout: {timeout}s")

    def _headers(self) -> Dict[str, str]:
        """
        Generate HTTP headers for Cody API requests.
        
        Returns:
            Dictionary containing Authorization and Accept headers
        """
        return {
            "Authorization": f"Bearer {self.api_key}",
            "Accept": "application/json",
        }

    def list_conversations(self, bot_id: str, page: Optional[int] = None, limit: Optional[int] = None) -> List[Dict[str, Any]]:
        """
        Fetch list of conversations for a specific bot.
        
        This method retrieves conversations from the Cody API with optional
        pagination support for handling large numbers of conversations.
        
        Args:
            bot_id: The ID of the bot to fetch conversations for
            page: Page number for pagination (optional)
            limit: Number of conversations per page (optional)
            
        Returns:
            List of conversation dictionaries
            
        Raises:
            requests.exceptions.HTTPError: If API request fails
        """
        logger.info(f"Fetching conversations for bot ID: {bot_id}")
        
        # Build query parameters for the API request
        params: Dict[str, Any] = {"bot_id": bot_id}
        if page is not None:
            params["page"] = page
        if limit is not None:
            params["limit"] = limit
            
        logger.debug(f"API request parameters: {params}")
        
        # Make API request to conversations endpoint
        url = f"{self.base_url}/conversations"
        logger.debug(f"Making API request to: {url}")
        
        resp = requests.get(url, headers=self._headers(), params=params, timeout=self.timeout)
        resp.raise_for_status()
        
        # Parse response data
        data = resp.json()
        logger.debug(f"Received response with {len(data) if isinstance(data, list) else 'dict'} items")
        
        # Handle different response formats (some APIs wrap in {data: []}, others return list directly)
        if isinstance(data, dict) and "data" in data:
            conversations = data["data"]
            logger.info(f"Retrieved {len(conversations)} conversations from wrapped response")
            return conversations
        if isinstance(data, list):
            logger.info(f"Retrieved {len(data)} conversations from direct response")
            return data
        
        logger.warning("Unexpected response format, returning empty list")
        return []

    def list_messages(self, conversation_id: str) -> List[Dict[str, Any]]:
        """
        Fetch messages for a specific conversation.
        
        This method retrieves all messages within a conversation,
        including both user and assistant messages with their content and metadata.
        
        Args:
            conversation_id: The ID of the conversation to fetch messages for
            
        Returns:
            List of message dictionaries
            
        Raises:
            requests.exceptions.HTTPError: If API request fails
        """
        logger.info(f"Fetching messages for conversation ID: {conversation_id}")
        
        # Build query parameters for the API request
        params = {"conversation_id": conversation_id}
        
        # Make API request to messages endpoint
        url = f"{self.base_url}/messages"
        logger.debug(f"Making API request to: {url} with params: {params}")
        
        resp = requests.get(url, headers=self._headers(), params=params, timeout=self.timeout)
        resp.raise_for_status()
        
        # Parse response data
        data = resp.json()
        logger.debug(f"Received response with {len(data) if isinstance(data, list) else 'dict'} items")
        
        # Handle different response formats
        if isinstance(data, dict) and "data" in data:
            messages = data["data"]
            logger.info(f"Retrieved {len(messages)} messages from wrapped response")
            return messages
        if isinstance(data, list):
            logger.info(f"Retrieved {len(messages)} messages from direct response")
            return data
        
        logger.warning("Unexpected response format, returning empty list")
        return []

    def get_conversations(self, bot_id: Optional[str] = None, page: Optional[int] = None, limit: Optional[int] = None) -> List[Dict[str, Any]]:
        """
        Get conversations from Cody API with default bot ID.
        
        This is a convenience wrapper around list_conversations that provides
        a default bot ID if none is specified.
        
        Args:
            bot_id: The ID of the bot to fetch conversations for (defaults to "618823")
            page: Page number for pagination (optional)
            limit: Number of conversations per page (optional)
            
        Returns:
            List of conversation dictionaries
        """
        default_bot_id = bot_id or "618823"
        logger.debug(f"Getting conversations with bot ID: {default_bot_id}")
        return self.list_conversations(default_bot_id, page, limit)

    def get_conversation_messages(self, conversation_id: str) -> List[Dict[str, Any]]:
        """
        Get messages for a specific conversation.
        
        This is a convenience wrapper around list_messages that provides
        a cleaner interface for the main application.
        
        Args:
            conversation_id: The ID of the conversation to fetch messages for
            
        Returns:
            List of message dictionaries
        """
        logger.debug(f"Getting messages for conversation: {conversation_id}")
        return self.list_messages(conversation_id)
