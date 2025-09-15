from __future__ import annotations
import logging
import threading
import time
import urllib.parse
from typing import Any, Dict, Optional
import requests

logger = logging.getLogger(__name__)

class ZohoClient:
    """
    Zoho CRM API client with robust OAuth handling.

    Key fixes:
      - Adopt Zoho 'api_domain' right after token refresh/exchange.
      - Recompute CRM URL after refresh (retry uses the new domain).
      - Force refresh on expiry and on HTTP 401 (bypass min-interval gate).
      - Expiry skew to refresh a bit early and avoid edge races.
      - Explicit 429 handling; safer expires_in parsing.
    """

    def __init__(
        self,
        api_base_url: str,
        api_version: str,
        access_token: Optional[str] = None,
        client_id: Optional[str] = None,
        client_secret: Optional[str] = None,
        refresh_token: Optional[str] = None,
        accounts_base_url: str = "https://accounts.zoho.com",
        timeout: int = 30,
    ):
        logger.debug("Initializing ZohoClient with api_base_url=%s, api_version=%s", api_base_url, api_version)
        
        self.api_base_url = api_base_url.rstrip("/")
        self.api_version = api_version
        self.access_token = access_token
        self.client_id = client_id
        self.client_secret = client_secret
        self._refresh_token = refresh_token
        self.accounts_base_url = accounts_base_url.rstrip("/")
        self.timeout = timeout

        logger.debug("Setting up token management...")
        # Refresh just before expiry to avoid races
        self._expiry_skew_seconds = 120
        # Prevent concurrent refresh stampedes
        self._refresh_lock = threading.Lock()

        self._token_cache: Dict[str, Any] = {
            "access_token": access_token,
            "expires_at": None,     # epoch seconds
            "last_refresh": None,   # epoch seconds
        }
        self._rate_limit_config = {
            "min_refresh_interval": 600,   # 10 minutes (increased from 5)
            "max_refresh_interval": 3600,  # 1 hour (increased from 30 minutes)
            "backoff_multiplier": 3,       # increased from 2
            "max_retries": 1,              # reduced from 2 to prevent rapid retries
        }
        self._metrics = {
            "refresh_attempts": 0,
            "refresh_successes": 0,
            "refresh_failures": 0,
            "rate_limit_hits": 0,
            "last_refresh_error": None,
            "last_refresh_time": None,
        }
        
        logger.debug("ZohoClient initialization completed")

    # ---------- HTTP + URL helpers ----------

    def _headers(self) -> Dict[str, str]:
        if not self.access_token:
            raise RuntimeError("Zoho access token is missing")
        return {
            "Authorization": f"Zoho-oauthtoken {self.access_token}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        }

    def _crm_url(self, endpoint: str) -> str:
        # Always compute from the *current* base URL
        return f"{self.api_base_url}/crm/{self.api_version}{endpoint}"

    # ---------- Token management ----------

    def _can_refresh_token(self) -> bool:
        last = self._token_cache["last_refresh"]
        if not last:
            return True
        return (time.time() - last) >= self._rate_limit_config["min_refresh_interval"]

    def _is_token_expired(self) -> bool:
        exp = self._token_cache["expires_at"]
        if not exp:
            return True
        return time.time() >= (exp - self._expiry_skew_seconds)

    def _update_token_cache(self, token_data: Dict[str, Any]) -> None:
        # 1) access token
        access = token_data.get("access_token")
        # 2) expiry
        raw_expires = token_data.get("expires_in", token_data.get("expires_in_sec", 3600))
        try:
            expires_in = int(raw_expires)
        except Exception:
            expires_in = 3600
        if expires_in <= 0:
            expires_in = 3600

        self._token_cache["access_token"] = access
        self._token_cache["expires_at"] = time.time() + expires_in
        self._token_cache["last_refresh"] = time.time()
        if access:
            self.access_token = access

        # 3) refresh token (only overwrite if a new one is provided)
        if token_data.get("refresh_token"):
            self._refresh_token = token_data["refresh_token"]

        # 4) adopt api_domain if present
        api_domain = token_data.get("api_domain")
        if api_domain:
            self.api_base_url = api_domain.rstrip("/")
            logger.info(f"Adopted Zoho api_domain: {self.api_base_url}")

    def _handle_rate_limit_error(self, attempt: int) -> None:
        self._metrics["rate_limit_hits"] += 1
        self._metrics["last_refresh_error"] = "rate_limit"
        if attempt >= self._rate_limit_config["max_retries"]:
            logger.error("Max retry attempts reached for token refresh after rate limit")
            return
        base = self._rate_limit_config["min_refresh_interval"]
        delay = min(base * (self._rate_limit_config["backoff_multiplier"] ** (attempt - 1)),
                    self._rate_limit_config["max_refresh_interval"])
        logger.warning(f"Rate limit on token refresh (attempt {attempt}); sleeping {delay}s")
        time.sleep(delay)

    def _safe_refresh_token(self, max_attempts: int | None = None, *, force: bool = False) -> bool:
        """
        Refresh the access token. If force=True, bypass min-interval gate
        (used when expired or after HTTP 401).
        """
        if max_attempts is None:
            max_attempts = self._rate_limit_config["max_retries"]

        if not self._refresh_token:
            logger.error("No refresh token available")
            return False

        # Honor min-interval unless we MUST refresh (expired/401)
        if not force and not self._can_refresh_token():
            logger.warning("Token refresh rate limited - too soon since last attempt")
            return False

        with self._refresh_lock:
            if not force and not self._can_refresh_token():
                return False

            for attempt in range(1, max_attempts + 1):
                try:
                    self._metrics["refresh_attempts"] += 1
                    logger.info(f"Attempting token refresh (attempt {attempt}/{max_attempts})")
                    token_data = self.refresh_access_token(self._refresh_token)
                    self._update_token_cache(token_data)

                    if self.access_token:
                        self._metrics["refresh_successes"] += 1
                        self._metrics["last_refresh_time"] = time.time()
                        self._metrics["last_refresh_error"] = None
                        logger.info("Token refresh successful")
                        return True

                    raise RuntimeError(f"Refresh returned no access_token: {token_data}")

                except requests.exceptions.HTTPError as e:
                    self._metrics["refresh_failures"] += 1
                    status = getattr(e.response, "status_code", None)

                    if status == 429:
                        self._handle_rate_limit_error(attempt)
                        continue

                    if status == 400:
                        try:
                            err = e.response.json()
                            code = str(err.get("error", "")).lower()
                            if code in {"rate_limit_exceeded", "too_many_requests"}:
                                self._handle_rate_limit_error(attempt)
                                continue
                            desc = str(err.get("error_description", "")).lower()
                            if "too many requests" in desc:
                                self._handle_rate_limit_error(attempt)
                                continue
                        except Exception:
                            pass

                    logger.error(f"Token refresh failed on attempt {attempt}: {e}")
                    self._metrics["last_refresh_error"] = str(e)
                    if attempt < max_attempts:
                        time.sleep(min(30, self._rate_limit_config["min_refresh_interval"]))

                except Exception as e:
                    self._metrics["refresh_failures"] += 1
                    logger.error(f"Unexpected error during token refresh (attempt {attempt}): {e}")
                    self._metrics["last_refresh_error"] = str(e)
                    if attempt < max_attempts:
                        time.sleep(min(30, self._rate_limit_config["min_refresh_interval"]))

            logger.error(f"All {max_attempts} token refresh attempts failed")
            return False

    def get_token_metrics(self) -> Dict[str, Any]:
        return {
            'refresh_attempts': self._metrics['refresh_attempts'],
            'refresh_successes': self._metrics['refresh_successes'],
            'refresh_failures': self._metrics['refresh_failures'],
            'rate_limit_hits': self._metrics['rate_limit_hits'],
            'success_rate': (self._metrics['refresh_successes'] / max(self._metrics['refresh_attempts'], 1)) * 100,
            'last_refresh_error': self._metrics['last_refresh_error'],
            'last_refresh_time': self._metrics['last_refresh_time'],
            'token_cache': {
                'has_cached_token': bool(self._token_cache['access_token']),
                'expires_at': self._token_cache['expires_at'],
                'last_refresh': self._token_cache['last_refresh']
            }
        }

    # ---------- Unified CRM request (recomputes URL after refresh) ----------

    def _request_crm(self, method: str, endpoint: str, **kwargs) -> requests.Response:
        """
        Make a CRM request for `endpoint` (e.g., '/Contacts/search').

        Flow:
          - Proactive forced refresh if near/at expiry (bypass min-interval).
          - Build URL from *current* api_base_url.
          - Send request.
          - If 401: force refresh, REBUILD URL (api_domain may have changed), retry once.
        """
        # 1) proactive refresh (only if we haven't hit rate limits recently)
        if self._is_token_expired() and self._can_refresh_token():
            logger.info("Token is near/at expiry - attempting proactive refresh")
            if self._safe_refresh_token(force=True):
                logger.info("Proactive token refresh successful")
            else:
                logger.warning("Proactive token refresh failed; proceeding with current token")

        # 2) first attempt
        url = self._crm_url(endpoint)
        logger.info(" - Calling url: %s", url)
        try:
            resp = requests.request(method, url, headers=self._headers(), timeout=self.timeout, **kwargs)
            resp.raise_for_status()
            return resp
        except requests.exceptions.HTTPError as e:
            # 3) handle 401: refresh + RECOMPUTE URL from possibly new api_domain
            if e.response is not None and e.response.status_code == 401:
                logger.info("Received 401 Unauthorized - attempting automatic token refresh")
                if self._safe_refresh_token(force=True):
                    logger.info("Token refresh successful - retrying request")
                    new_url = self._crm_url(endpoint)  # <-- recompute with (potentially) new api_domain
                    resp = requests.request(method, new_url, headers=self._headers(), timeout=self.timeout, **kwargs)
                    resp.raise_for_status()
                    return resp
                else:
                    logger.error("Token refresh failed - likely rate limited")
                    raise RuntimeError("Zoho API rate limit exceeded. Please wait before retrying.")
            raise

    # ---------- OAuth 2.0 ----------

    def generate_auth_url(
        self,
        redirect_uri: str,
        scope: str = "ZohoCRM.modules.contacts.ALL,ZohoCRM.modules.notes.CREATE,ZohoCRM.modules.notes.READ,ZohoCRM.modules.cases.CREATE",
        prompt: str = "consent",
    ) -> str:
        if not self.client_id:
            raise RuntimeError("Client ID is required to generate auth URL")
        params = {
            "response_type": "code",
            "client_id": self.client_id,
            "scope": scope,
            "redirect_uri": redirect_uri,
            "access_type": "offline",
            "prompt": prompt,
        }
        return f"{self.accounts_base_url}/oauth/v2/auth?{urllib.parse.urlencode(params)}"

    def exchange_code_for_tokens(self, authorization_code: str, redirect_uri: str) -> Dict[str, Any]:
        if not self.client_id or not self.client_secret:
            raise RuntimeError("Client ID and Client Secret are required to exchange code for tokens")
        token_url = f"{self.accounts_base_url}/oauth/v2/token"
        data = {
            "grant_type": "authorization_code",
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "redirect_uri": redirect_uri,
            "code": authorization_code,
        }
        resp = requests.post(token_url, data=data, timeout=self.timeout)
        resp.raise_for_status()
        token_data = resp.json()
        self._update_token_cache(token_data)
        return token_data

    def refresh_access_token(self, refresh_token: str) -> Dict[str, Any]:
        if not self.client_id or not self.client_secret:
            raise RuntimeError("Client ID and Client Secret are required to refresh tokens")
        token_url = f"{self.accounts_base_url}/oauth/v2/token"
        data = {
            "grant_type": "refresh_token",
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "refresh_token": refresh_token,
        }
        resp = requests.post(token_url, data=data, timeout=self.timeout)
        resp.raise_for_status()
        return resp.json()  # Do not log tokens

    def update_refresh_token(self, refresh_token: str) -> None:
        self._refresh_token = refresh_token

    # ---------- Contacts ----------

    def search_contact_by_name(self, name: str) -> Optional[Dict[str, Any]]:
        criteria = f"(Last_Name:equals:{name})"
        resp = self._request_crm("GET", "/Contacts/search", params={"criteria": criteria})
        if resp.status_code == 204:
            return None
        data = resp.json()
        if isinstance(data, dict):
            records = data.get("data") or []
            if records:
                return records[0]
        return None

    def create_contact(self, last_name: str) -> str:
        payload = {"data": [{"Last_Name": last_name}]}
        resp = self._request_crm("POST", "/Contacts", json=payload)
        data = resp.json()
        if isinstance(data, dict) and "data" in data and data["data"]:
            details = data["data"][0].get("details", {})
            rec_id = details.get("id")
            if rec_id:
                return rec_id
        raise RuntimeError(f"Failed to create contact: {data}")

    def ensure_contact(self, contact_id: Optional[str], contact_name: Optional[str]) -> str:
        if contact_id:
            return contact_id
        if contact_name:
            found = self.search_contact_by_name(contact_name)
            if found and found.get("id"):
                return found["id"]
            return self.create_contact(contact_name)
        raise RuntimeError("Neither ZOHO_CONTACT_ID nor ZOHO_CONTACT_NAME provided.")

    # ---------- Cases (+ optional notes) ----------

    def search_case_by_cody_id(self, cody_conversation_id: str) -> Optional[Dict[str, Any]]:
        """
        Search for existing case by Cody conversation ID using the correct API format.
        
        API Format: GET {api-domain}/crm/v8/Cases/search?criteria=Cody_Conversation_ID%3Aequals%3A{YOUR_ID}
        
        Args:
            cody_conversation_id: The Cody conversation ID to search for
            
        Returns:
            Case data if found, None otherwise
        """
        try:
            # URL encode the criteria parameter
            import urllib.parse
            criteria = f"Cody_Conversation_ID:equals:{cody_conversation_id}"
            encoded_criteria = urllib.parse.quote(criteria)
            
            # Build the search URL with encoded criteria
            search_url = f"{self._crm_url('/Cases/search')}?criteria={encoded_criteria}"
            
            logger.debug(f"Searching for case with criteria: {criteria}")
            logger.debug(f"Search URL: {search_url}")
            
            resp = self._request_crm("GET", f"/Cases/search?criteria={encoded_criteria}")
            
            if resp.status_code == 204:
                logger.debug(f"No existing case found for Cody conversation ID: {cody_conversation_id}")
                return None
            
            data = resp.json()
            if isinstance(data, dict):
                records = data.get("data") or []
                if records:
                    existing_case = records[0]
                    case_id = existing_case.get("id")
                    logger.info(f"Found existing case {case_id} for Cody conversation {cody_conversation_id}")
                    return existing_case
            
            logger.debug(f"No existing case found for Cody conversation ID: {cody_conversation_id}")
            return None
            
        except Exception as e:
            logger.warning(f"Error searching for case by Cody ID {cody_conversation_id}: {e}")
            return None

    def create_case_with_duplicate_check(
        self,
        subject: str,
        description: str,
        cody_conversation_id: str,  # Required for duplicate checking
        contact_name: str = "Cody Chat",
        case_origin: str = "Web",
        case_status: str = "Closed",
        attach_transcript_as_note: bool = False,
        metrics: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Create a case only if it doesn't already exist for this Cody conversation.
        
        Returns:
            Dict with 'case_id' and 'was_created' keys:
            - case_id: Case ID if found/created, None if error
            - was_created: True if new case was created, False if existing case found
        """
        # Check for existing case using the correct API format
        existing_case = self.search_case_by_cody_id(cody_conversation_id)
        if existing_case:
            case_id = existing_case.get("id")
            logger.info(f"Case already exists for Cody conversation {cody_conversation_id}: {case_id}")
            return {"case_id": case_id, "was_created": False}
        
        # Create new case
        logger.info(f"Creating new case for Cody conversation {cody_conversation_id}")
        new_case_id = self.create_case(
            subject=subject,
            description=description,
            contact_name=contact_name,
            case_origin=case_origin,
            case_status=case_status,
            attach_transcript_as_note=attach_transcript_as_note,
            metrics=metrics,
            cody_conversation_id=cody_conversation_id
        )
        return {"case_id": new_case_id, "was_created": True}

    def create_case(
        self,
        subject: str,
        description: str,
        contact_name: str = "Cody Chat",
        case_origin: str = "Web",
        case_status: str = "Closed",
        attach_transcript_as_note: bool = False,
        metrics: Optional[Dict[str, Any]] = None,
        cody_conversation_id: Optional[str] = None,  # NEW PARAMETER
    ) -> str:
        contact_id = self.ensure_contact(None, contact_name)
        record: Dict[str, Any] = {
            "Subject": (subject or "Cody Chat")[:255],
            "Description": description or "",
            "Contact_Name": {"id": contact_id},  # link by ID (correct)
            "Case_Origin": case_origin,
            "Status": case_status,
        }
        
        # Add Cody conversation ID to existing field
        if cody_conversation_id:
            record["Cody_Conversation_ID"] = cody_conversation_id
        if metrics:
            for k, v in metrics.items():
                record[f"CF_{k}"] = str(v)
        # Log a lightweight view of the payload for debugging (avoid logging very long description)
        try:
            logger.debug(
                "Creating case payload: %s",
                {
                    k: (v if k != "Description" else f"<{len(description or '')} chars>")
                    for k, v in record.items()
                },
            )
        except Exception:
            pass

        try:
            resp = self._request_crm("POST", "/Cases", json={"data": [record]})
            data = resp.json()
            if isinstance(data, dict) and "data" in data and data["data"]:
                details = data["data"][0].get("details", {})
                case_id = details.get("id")
                if case_id:
                    if attach_transcript_as_note and description:
                        try:
                            self.create_note_on_case(case_id, f"Conversation Transcript - {subject[:200]}", description)
                        except Exception as e:
                            logger.warning(f"Failed to attach transcript note to case {case_id}: {e}")
                    return case_id
            raise RuntimeError(f"Failed to create case: {data}")
        except requests.exceptions.HTTPError as e:
            # Try to extract Zoho error response for diagnostics
            status_code = getattr(e.response, "status_code", "?")
            error_body: Any = None
            error_message = str(e)
            try:
                error_body = e.response.json()
            except Exception:
                try:
                    error_body = e.response.text
                except Exception:
                    error_body = None

            # Special handling: DUPLICATE_DATA means the case already exists
            try:
                if isinstance(error_body, dict):
                    data_list = error_body.get("data")
                    if isinstance(data_list, list) and data_list:
                        first_item = data_list[0] or {}
                        if str(first_item.get("code")) == "DUPLICATE_DATA":
                            details = first_item.get("details", {})
                            duplicate = details.get("duplicate_record", {})
                            existing_case_id = duplicate.get("id")
                            if existing_case_id:
                                logger.info(
                                    "Duplicate case detected for Cody_Conversation_ID; using existing case %s",
                                    existing_case_id,
                                )
                                # Attach transcript if requested
                                if attach_transcript_as_note and description:
                                    try:
                                        self.create_note_on_case(
                                            existing_case_id,
                                            f"Conversation Transcript - {subject[:200]}",
                                            description,
                                        )
                                    except Exception as note_err:
                                        logger.warning(
                                            "Failed to attach transcript note to existing case %s: %s",
                                            existing_case_id,
                                            note_err,
                                        )
                                return existing_case_id
            except Exception:
                # If any parsing error occurs, fall through to generic error path
                pass

            logger.error(
                "Zoho Cases create returned HTTP %s. Message=%s, ErrorBody=%s",
                status_code,
                error_message,
                error_body,
            )
            # Surface a concise error upward with essential details
            raise RuntimeError(
                f"Zoho Cases create failed ({status_code}). Message={error_message}. Details={error_body}"
            ) from e

    def create_note_on_case(self, case_id: str, title: str, content: str) -> str:
        payload = {"data": [{
            "Note_Title": (title or "Case Note")[:255],
            "Note_Content": content or "",
        }]}
        resp = self._request_crm("POST", f"/Cases/{case_id}/Notes", json=payload)
        data = resp.json()
        if isinstance(data, dict) and "data" in data and data["data"]:
            details = data["data"][0].get("details", {})
            note_id = details.get("id")
            if note_id:
                return note_id
        raise RuntimeError(f"Failed to create note on case: {data}")
