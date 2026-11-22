#!/usr/bin/env python3
"""Read-only quota adapter for OpenCode's and Claude Code's locally owned credentials."""

import json
import math
import os
import sqlite3
import stat
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime

MAX_AUTH_BYTES = 1024 * 1024
MAX_RESPONSE_BYTES = 256 * 1024
REQUEST_TIMEOUT = 8
DATABASE_TIMEOUT = 1
OPENAI_URL = "https://chatgpt.com/backend-api/wham/usage"
OPENCODE_URL = "https://opencode.ai/zen/go/v1/usage"
CLAUDE_URL = "https://api.anthropic.com/api/oauth/usage"
CLAUDE_HEADERS = {"anthropic-beta": "oauth-2025-04-20"}
INVALID_CREDENTIAL = object()


def error(code, retryable=True, retry_after=None):
    return {"code": code, "retryable": retryable, "retryAfterSeconds": retry_after}


def empty_window():
    return {"status": "error", "usedPercent": None, "remainingPercent": None,
            "resetsAt": None, "error": None}


def failed_provider(code, retryable=True, retry_after=None):
    failure = error(code, retryable, retry_after)
    result = {"status": "error", "lastUpdated": None, "fiveHour": empty_window(),
              "weekly": empty_window(), "error": failure}
    result["fiveHour"]["error"] = failure
    result["weekly"]["error"] = failure
    return result


def clamp_percent(value):
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return None
    if value != value or value in (float("inf"), float("-inf")):
        return None
    if not 0 <= value <= 100:
        return None
    return float(value)


def iso_time(value):
    if isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value):
        try:
            return datetime.fromtimestamp(value, timezone.utc).isoformat().replace("+00:00", "Z")
        except (OverflowError, OSError, ValueError):
            return None
    if not isinstance(value, str):
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
        return parsed.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")
    except ValueError:
        return None


def make_window(source, duration=None, weekly=False):
    if not isinstance(source, dict):
        return None
    if source.get("status") not in (None, "ok", "rate-limited"):
        return None
    used = clamp_percent(source.get("percent", source.get("used_percent")))
    reset = iso_time(source.get("resetsAt", source.get("reset_at")))
    if used is None or reset is None:
        return None
    if duration is not None and (not isinstance(duration, (int, float)) or isinstance(duration, bool) or not math.isfinite(duration) or duration <= 0):
        return None
    result = {"status": "ok", "usedPercent": used,
              "remainingPercent": max(0, min(100, 100 - used)),
              "resetsAt": reset, "error": None}
    if source.get("status") == "rate-limited":
        result["status"] = "ok"
    return result


def parse_opencode(document):
    usage = document.get("usage") if isinstance(document, dict) else None
    if not isinstance(usage, dict):
        return failed_provider("INVALID_RESPONSE", False)
    result = {"status": "ok", "lastUpdated": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
              "fiveHour": empty_window(), "weekly": empty_window(), "monthly": empty_window(), "error": None}
    for target, source_name in (("fiveHour", "rolling"), ("weekly", "weekly"), ("monthly", "monthly")):
        window = make_window(usage.get(source_name))
        if window is None:
            window = empty_window()
            window["error"] = error("INVALID_RESPONSE", False)
            result["status"] = "error"
            result["error"] = window["error"]
        result[target] = window
    return result


def select_openai_window(window, expected):
    if not isinstance(window, dict):
        return None
    duration = window.get("limit_window_seconds")
    if not isinstance(duration, (int, float)):
        return None
    return make_window(window, duration) if abs(duration - expected) <= expected * 0.05 else None


def parse_openai(document):
    rate_limit = document.get("rate_limit") if isinstance(document, dict) else None
    if not isinstance(rate_limit, dict):
        return failed_provider("INVALID_RESPONSE", False)
    candidates = []
    for key in ("primary_window", "secondary_window"):
        if isinstance(rate_limit.get(key), dict):
            candidates.append(rate_limit[key])
    five = [item for item in candidates if select_openai_window(item, 5 * 60 * 60)]
    week = [item for item in candidates if select_openai_window(item, 7 * 24 * 60 * 60)]
    result = {"status": "ok", "lastUpdated": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
              "fiveHour": empty_window(), "weekly": empty_window(), "error": None}
    for name, matches in (("fiveHour", five), ("weekly", week)):
        if len(matches) != 1:
            result[name]["error"] = error("INVALID_RESPONSE", False)
            result["status"] = "error"
            result["error"] = result[name]["error"]
        else:
            result[name] = select_openai_window(matches[0], 5 * 60 * 60 if name == "fiveHour" else 7 * 24 * 60 * 60)
    return result


def claude_window(source):
    if not isinstance(source, dict):
        return None
    used = clamp_percent(source.get("utilization"))
    if used is None:
        return None
    if source.get("resets_at") is None and used == 0:
        # A window that has not started yet reports no reset time.
        reset = None
    else:
        reset = iso_time(source.get("resets_at"))
        if reset is None:
            return None
    return {"status": "ok", "usedPercent": used, "remainingPercent": max(0, min(100, 100 - used)),
            "resetsAt": reset, "error": None}


def parse_claude(document):
    if not isinstance(document, dict):
        return failed_provider("INVALID_RESPONSE", False)
    result = {"status": "ok", "lastUpdated": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
              "fiveHour": empty_window(), "weekly": empty_window(), "error": None}
    for target, source_name in (("fiveHour", "five_hour"), ("weekly", "seven_day")):
        window = claude_window(document.get(source_name))
        if window is None:
            window = empty_window()
            window["error"] = error("INVALID_RESPONSE", False)
            result["status"] = "error"
            result["error"] = window["error"]
        result[target] = window
    return result


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


OPENER = urllib.request.build_opener(NoRedirect)


def retry_after_seconds(headers):
    value = headers.get("Retry-After", "")
    try:
        retry = int(value)
    except (TypeError, ValueError):
        try:
            retry = int(parsedate_to_datetime(value).timestamp() - time.time())
        except (OverflowError, TypeError, ValueError):
            return None
    return max(1, min(3600, retry))


def request_json(url, token, account_id=None, extra_headers=None):
    headers = dict(extra_headers or {})
    headers.update({"Authorization": f"Bearer {token}", "User-Agent": "qe-ai-quota/1"})
    if account_id:
        headers["ChatGPT-Account-Id"] = account_id
    request = urllib.request.Request(url, headers=headers, method="GET")
    try:
        with OPENER.open(request, timeout=REQUEST_TIMEOUT) as response:
            body = response.read(MAX_RESPONSE_BYTES + 1)
            if len(body) > MAX_RESPONSE_BYTES:
                return None, error("INVALID_RESPONSE", False)
            return json.loads(body.decode("utf-8")), None
    except urllib.error.HTTPError as exc:
        if exc.code in (401, 403):
            return None, error("UNAUTHORIZED" if exc.code == 401 else "NOT_ENTITLED", False)
        if exc.code == 429:
            retry = retry_after_seconds(exc.headers)
            return None, error("RATE_LIMITED", True, retry)
        return None, error("NETWORK_ERROR", True)
    except (urllib.error.URLError, TimeoutError, OSError):
        return None, error("TIMEOUT", True)
    except (UnicodeDecodeError, json.JSONDecodeError):
        return None, error("INVALID_RESPONSE", False)


def auth_path():
    data_home = os.environ.get("XDG_DATA_HOME") or os.path.join(os.path.expanduser("~"), ".local", "share")
    return os.path.join(data_home, "opencode", "auth.json")


def credential_db_path():
    data_home = os.environ.get("XDG_DATA_HOME") or os.path.join(os.path.expanduser("~"), ".local", "share")
    return os.path.join(data_home, "opencode", "opencode.db")


def claude_credentials_path():
    config_dir = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.join(os.path.expanduser("~"), ".claude")
    return os.path.join(config_dir, ".credentials.json")


def load_auth(path):
    fd = None
    try:
        fd = os.open(path, os.O_RDONLY | os.O_CLOEXEC | os.O_NOFOLLOW)
        info = os.fstat(fd)
        if not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid() or info.st_mode & 0o077:
            return None, error("AUTH_INVALID", False)
        if info.st_size > MAX_AUTH_BYTES:
            return None, error("AUTH_INVALID", False)
        with os.fdopen(fd, "rb") as stream:
            fd = None
            raw = stream.read(MAX_AUTH_BYTES + 1)
            if len(raw) > MAX_AUTH_BYTES:
                return None, error("AUTH_INVALID", False)
            document = json.loads(raw.decode("utf-8"))
        return document if isinstance(document, dict) else None, None
    except FileNotFoundError:
        return None, error("AUTH_MISSING", False)
    except (OSError, UnicodeDecodeError, json.JSONDecodeError):
        return None, error("AUTH_INVALID", False)
    finally:
        if fd is not None:
            os.close(fd)


def load_credential_db(path):
    try:
        info = os.stat(path)
        if not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid():
            return None, error("AUTH_INVALID", False)
        uri = "file:" + path.replace("%", "%25").replace("?", "%3F").replace("#", "%23") + "?mode=ro"
        deadline = time.monotonic() + DATABASE_TIMEOUT
        with sqlite3.connect(uri, uri=True, timeout=DATABASE_TIMEOUT) as database:
            database.set_progress_handler(lambda: int(time.monotonic() >= deadline), 1000)
            selected = {}
            for provider in ("openai", "opencode-go"):
                selected[provider] = database.execute(
                    "SELECT length(CAST(value AS BLOB)), "
                    "CASE WHEN length(CAST(value AS BLOB)) <= ? THEN value ELSE NULL END "
                    "FROM credential WHERE integration_id = ? "
                    "ORDER BY CASE WHEN active = 1 THEN 1 ELSE 0 END DESC, time_updated DESC LIMIT 1",
                    (MAX_AUTH_BYTES, provider),
                ).fetchone()
        result = {}
        for provider, row in selected.items():
            if row is None:
                continue
            length, raw = row
            if not isinstance(length, int) or length > MAX_AUTH_BYTES or not isinstance(raw, str):
                result[provider] = INVALID_CREDENTIAL
                continue
            try:
                value = json.loads(raw)
            except (TypeError, UnicodeDecodeError, json.JSONDecodeError):
                result[provider] = INVALID_CREDENTIAL
                continue
            result[provider] = value if isinstance(value, dict) else INVALID_CREDENTIAL
        return result, None
    except FileNotFoundError:
        return None, error("AUTH_MISSING", False)
    except (OSError, sqlite3.Error):
        return None, error("AUTH_INVALID", False)


def load_credentials():
    legacy, legacy_error = load_auth(auth_path())
    database, database_error = load_credential_db(credential_db_path())
    if database is None:
        if database_error and database_error["code"] != "AUTH_MISSING":
            return None, database_error
        return (legacy, None) if legacy is not None else (None, legacy_error or database_error or error("AUTH_MISSING", False))
    result = dict(legacy or {})
    result.update(database)
    return result, None


def provider_auth(document, provider):
    record = document.get(provider) if isinstance(document, dict) else None
    if provider == "opencode" and record is None:
        record = document.get("opencode-go")
    if record is INVALID_CREDENTIAL:
        return None, error("AUTH_INVALID", False)
    if not isinstance(record, dict):
        return None, error("AUTH_MISSING", False)
    if provider == "openai":
        if record.get("type") != "oauth" or not safe_secret(record.get("access")):
            return None, error("AUTH_INVALID", False)
        if not isinstance(record.get("expires"), (int, float)) or isinstance(record.get("expires"), bool) or not math.isfinite(record["expires"]):
            return None, error("AUTH_INVALID", False)
        if record["expires"] <= time.time() * 1000 + 60000:
            return None, error("AUTH_EXPIRED", True)
        account_id = record.get("accountId")
        if account_id is not None and not safe_secret(account_id):
            return None, error("AUTH_INVALID", False)
        return (record["access"], account_id), None
    if record.get("type") not in ("api", "key") or not safe_secret(record.get("key")):
        return None, error("AUTH_INVALID", False)
    return (record["key"], None), None


def claude_auth(document):
    record = document.get("claudeAiOauth") if isinstance(document, dict) else None
    if not isinstance(record, dict):
        return None, error("AUTH_MISSING", False)
    if not safe_secret(record.get("accessToken")):
        return None, error("AUTH_INVALID", False)
    expires = record.get("expiresAt")
    if not isinstance(expires, (int, float)) or isinstance(expires, bool) or not math.isfinite(expires):
        return None, error("AUTH_INVALID", False)
    if expires <= time.time() * 1000 + 60000:
        return None, error("AUTH_EXPIRED", True)
    return (record["accessToken"], None, CLAUDE_HEADERS), None


def safe_secret(value):
    return isinstance(value, str) and 0 < len(value) <= 8192 and all(32 <= ord(char) < 127 for char in value)


def provider_credentials(provider, opencode_auth):
    if provider == "claude":
        document, failure = load_auth(claude_credentials_path())
        return (None, failure) if failure else claude_auth(document)
    auth, auth_error = opencode_auth()
    return (None, auth_error) if auth_error else provider_auth(auth, provider)


def run(provider_filter=None):
    cache = []

    def opencode_auth():
        if not cache:
            cache.append(load_credentials())
        return cache[0]

    providers = {}
    for provider, parser, url in (("openai", parse_openai, OPENAI_URL), ("opencode", parse_opencode, OPENCODE_URL),
                                  ("claude", parse_claude, CLAUDE_URL)):
        if provider_filter and provider != provider_filter:
            continue
        credentials, credential_error = provider_credentials(provider, opencode_auth)
        if credential_error:
            providers[provider] = failed_provider(credential_error["code"], credential_error["retryable"], credential_error["retryAfterSeconds"])
            continue
        document, request_error = request_json(url, *credentials)
        providers[provider] = failed_provider(request_error["code"], request_error["retryable"], request_error["retryAfterSeconds"]) if request_error else parser(document)
    print(json.dumps({"schemaVersion": 1, "observedAt": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"), "providers": providers}, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    selected = None
    if len(sys.argv) == 3 and sys.argv[1] == "--provider" and sys.argv[2] in ("openai", "opencode", "claude"):
        selected = sys.argv[2]
    elif len(sys.argv) != 1:
        sys.exit(2)
    sys.exit(run(selected))
