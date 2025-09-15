from __future__ import annotations
import logging
from typing import Dict, List

logger = logging.getLogger(__name__)

def format_transcript(messages: List[Dict]) -> str:
    """
    Format conversation messages into a readable transcript.
    
    This function takes a list of message dictionaries from the Cody API
    and formats them into a human-readable transcript with proper
    speaker identification and message ordering.
    
    Args:
        messages: List of message dictionaries from Cody API
        
    Returns:
        Formatted transcript string
    """
    logger.info(f"Formatting transcript for {len(messages)} messages")
    
    if not messages:
        logger.warning("No messages provided for transcript formatting")
        return "No messages in conversation."
    
    # Sort messages by creation time to ensure proper order
    sorted_messages = sorted(messages, key=lambda x: x.get("created_at", 0))
    logger.debug(f"Sorted {len(sorted_messages)} messages by creation time")
    
    transcript_lines = []
    
    for i, message in enumerate(sorted_messages):
        content = message.get("content", "")
        role = message.get("role", "")
        created_at = message.get("created_at", 0)
        
        # Determine speaker label based on role
        if role.lower() in ["user", "human"]:
            speaker = "User"
        elif role.lower() in ["assistant", "bot", "ai"]:
            speaker = "Assistant"
        else:
            speaker = " "
        
        # Format timestamp if available
        if created_at:
            try:
                from datetime import datetime
                timestamp = datetime.fromtimestamp(created_at).strftime("%Y-%m-%d %H:%M:%S")
                timestamp_str = f" [{timestamp}]"
            except (ValueError, OSError):
                timestamp_str = ""
        else:
            timestamp_str = ""
        
        # Format the message line
        message_line = f"{speaker}{timestamp_str}: {content}"
        transcript_lines.append(message_line)
        
        logger.debug(f"Formatted message {i+1}: {speaker} ({len(content)} chars)")
    
    # Join all lines with newlines
    transcript = "\n\n".join(transcript_lines)
    logger.info(f"Transcript formatting completed: {len(transcript)} total characters")
    
    return transcript
