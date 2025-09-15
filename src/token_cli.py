from __future__ import annotations
import argparse
import requests
from dotenv import load_dotenv

from .config import Settings
from .store import Store

def fetch_access_token(accounts_base_url: str, client_id: str, client_secret: str, refresh_token: str, timeout: int = 30) -> dict:
    url = accounts_base_url.rstrip("/") + "/oauth/v2/token"
    params = {
        "grant_type": "refresh_token",
        "client_id": client_id,
        "client_secret": client_secret,
        "refresh_token": refresh_token,
    }
    resp = requests.post(url, params=params, timeout=timeout)
    try:
        data = resp.json()
    except Exception:
        data = {"error": f"Non-JSON response: {resp.text[:200]}"}
    if resp.status_code != 200:
        raise SystemExit(f"Failed to refresh token ({resp.status_code}): {data}")
    return data

def main(argv=None):
    load_dotenv()
    settings = Settings()

    parser = argparse.ArgumentParser(description="Fetch Zoho access token using a refresh token and cache it in Redis.")
    parser.add_argument("--print-only", action="store_true", help="Only print the access token; do not cache in Redis.")
    args = parser.parse_args(argv)

    if not (settings.ZOHO_REFRESH_TOKEN and settings.ZOHO_CLIENT_ID and settings.ZOHO_CLIENT_SECRET):
        raise SystemExit("Missing ZOHO_REFRESH_TOKEN, ZOHO_CLIENT_ID, or ZOHO_CLIENT_SECRET in environment.")

    data = fetch_access_token(
        accounts_base_url=settings.ZOHO_ACCOUNTS_BASE_URL,
        client_id=settings.ZOHO_CLIENT_ID,
        client_secret=settings.ZOHO_CLIENT_SECRET,
        refresh_token=settings.ZOHO_REFRESH_TOKEN,
    )

    access_token = data.get("access_token")
    expires_in = int(data.get("expires_in", 3600))

    if not access_token:
        raise SystemExit(f"Did not receive access_token: {data}")

    print(f"New access token (expires in ~{expires_in}s):\n{access_token}")

    if not args.print_only:
        store = Store(settings.REDIS_URL)
        store.set_access_token(access_token, ttl_seconds=expires_in)
        print("Cached access token in Redis key 'zoho_access_token'")

if __name__ == "__main__":
    main()
