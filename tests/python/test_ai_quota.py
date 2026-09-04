import importlib.util
import io
import json
import os
import tempfile
import unittest
from contextlib import redirect_stdout
from email.utils import formatdate
from urllib.error import HTTPError


spec = importlib.util.spec_from_file_location("ai_quota", "scripts/qe-ai-quota.py")
quota = importlib.util.module_from_spec(spec)
spec.loader.exec_module(quota)


class AiQuotaTests(unittest.TestCase):
    def test_opencode_windows(self):
        result = quota.parse_opencode({"usage": {
            "rolling": {"percent": 3.4, "resetsAt": "2026-09-04T05:00:00Z"},
            "weekly": {"percent": 40, "resetsAt": "2026-09-11T00:00:00Z"},
            "monthly": {"percent": 30, "resetsAt": "2026-10-01T00:00:00Z"},
        }})
        self.assertEqual(result["fiveHour"]["remainingPercent"], 96.6)
        self.assertEqual(result["weekly"]["remainingPercent"], 60)
        self.assertEqual(result["monthly"]["remainingPercent"], 70)

    def test_openai_duration_selection(self):
        result = quota.parse_openai({"rate_limit": {
            "primary_window": {"used_percent": 10, "limit_window_seconds": 18000, "reset_at": 1788537600},
            "secondary_window": {"used_percent": 55, "limit_window_seconds": 604800, "reset_at": 1789000000},
        }})
        self.assertEqual(result["fiveHour"]["remainingPercent"], 90)
        self.assertEqual(result["weekly"]["remainingPercent"], 45)

    def test_ambiguous_window_is_rejected(self):
        result = quota.parse_openai({"rate_limit": {
            "primary_window": {"used_percent": 10, "limit_window_seconds": 604800, "reset_at": 1788537600},
            "secondary_window": {"used_percent": 20, "limit_window_seconds": 604800, "reset_at": 1789000000},
        }})
        self.assertEqual(result["weekly"]["error"]["code"], "INVALID_RESPONSE")

    def test_openai_invalid_and_partial_windows(self):
        result = quota.parse_openai({"rate_limit": {
            "primary_window": {"used_percent": 10, "limit_window_seconds": 18000, "reset_at": 1788537600},
            "secondary_window": {"used_percent": -1, "limit_window_seconds": 604800, "reset_at": 1789000000},
        }})
        self.assertEqual(result["fiveHour"]["remainingPercent"], 90)
        self.assertEqual(result["weekly"]["error"]["code"], "INVALID_RESPONSE")
        result = quota.parse_openai({"rate_limit": {
            "primary_window": {"used_percent": 10, "limit_window_seconds": 100, "reset_at": 1788537600},
            "secondary_window": {"used_percent": 20, "limit_window_seconds": 604800, "reset_at": 1789000000},
        }})
        self.assertEqual(result["fiveHour"]["error"]["code"], "INVALID_RESPONSE")

    def test_out_of_range_and_partial_windows_are_isolated(self):
        result = quota.parse_opencode({"usage": {
            "rolling": {"percent": -1, "resetsAt": "2026-09-04T05:00:00Z"},
            "weekly": {"percent": 40, "resetsAt": "2026-09-11T00:00:00Z"},
        }})
        self.assertEqual(result["fiveHour"]["error"]["code"], "INVALID_RESPONSE")
        self.assertEqual(result["weekly"]["remainingPercent"], 60)

    def test_auth_file_is_bounded_and_credentials_are_validated(self):
        with tempfile.TemporaryDirectory() as directory:
            path = os.path.join(directory, "auth.json")
            with open(path, "w", encoding="utf-8") as stream:
                stream.write('{"openai": {"type": "oauth", "access": "token", "expires": 9999999999999}}')
            os.chmod(path, 0o600)
            document, failure = quota.load_auth(path)
            self.assertIsNone(failure)
            self.assertEqual(quota.provider_auth(document, "openai")[0][0], "token")
            self.assertEqual(quota.provider_auth({"opencode-go": {"type": "api", "key": "token"}}, "opencode")[0][0], "token")
            self.assertEqual(quota.provider_auth({"openai": {"type": "oauth", "access": "\n", "expires": 9999999999999}}, "openai")[1]["code"], "AUTH_INVALID")
            with open(path, "w", encoding="utf-8") as stream:
                stream.write("x" * (quota.MAX_AUTH_BYTES + 1))
            self.assertEqual(quota.load_auth(path)[1]["code"], "AUTH_INVALID")
            link = os.path.join(directory, "auth-link.json")
            os.symlink(path, link)
            self.assertEqual(quota.load_auth(link)[1]["code"], "AUTH_INVALID")

    def test_request_contract_and_retry_after(self):
        class Response:
            def __enter__(self): return self
            def __exit__(self, *args): return False
            def read(self, limit): return b'{"ok": true}'

        class Opener:
            def open(self, request, timeout):
                self.request = request
                self.timeout = timeout
                return Response()

        opener = Opener()
        original = quota.OPENER
        quota.OPENER = opener
        try:
            document, failure = quota.request_json(quota.OPENAI_URL, "secret", "account")
        finally:
            quota.OPENER = original
        self.assertIsNone(failure)
        self.assertEqual(document["ok"], True)
        self.assertEqual(opener.request.full_url, quota.OPENAI_URL)
        self.assertEqual(opener.request.get_method(), "GET")
        self.assertIsNone(opener.request.data)
        self.assertEqual(opener.request.get_header("Authorization"), "Bearer secret")
        self.assertEqual(next(value for key, value in opener.request.headers.items() if key.lower() == "chatgpt-account-id"), "account")
        self.assertEqual(quota.retry_after_seconds({"Retry-After": "17"}), 17)
        self.assertGreaterEqual(quota.retry_after_seconds({"Retry-After": formatdate(quota.time.time() + 30, usegmt=True)}), 1)
        error = HTTPError("https://example.test", 429, "", {"Retry-After": "42"}, io.BytesIO())
        class ErrorOpener:
            def open(self, request, timeout):
                raise error
        quota.OPENER = ErrorOpener()
        try:
            _, failure = quota.request_json("https://example.test", "secret")
        finally:
            quota.OPENER = original
        self.assertEqual(failure["code"], "RATE_LIMITED")
        self.assertEqual(failure["retryAfterSeconds"], 42)

    def test_request_failure_boundaries(self):
        class Response:
            def __init__(self, body): self.body = body
            def __enter__(self): return self
            def __exit__(self, *args): return False
            def read(self, limit): return self.body

        class Opener:
            def __init__(self, outcome): self.outcome = outcome
            def open(self, request, timeout):
                if isinstance(self.outcome, Exception): raise self.outcome
                return Response(self.outcome)

        original = quota.OPENER
        try:
            for exception, code in ((HTTPError("https://example.test", 401, "", {}, io.BytesIO()), "UNAUTHORIZED"),
                                    (HTTPError("https://example.test", 403, "", {}, io.BytesIO()), "NOT_ENTITLED"),
                                    (HTTPError("https://example.test", 302, "", {}, io.BytesIO()), "NETWORK_ERROR"),
                                    (quota.urllib.error.URLError("timeout"), "TIMEOUT")):
                quota.OPENER = Opener(exception)
                self.assertEqual(quota.request_json("https://example.test", "secret")[1]["code"], code)
            quota.OPENER = Opener(b"x" * (quota.MAX_RESPONSE_BYTES + 1))
            self.assertEqual(quota.request_json("https://example.test", "secret")[1]["code"], "INVALID_RESPONSE")
        finally:
            quota.OPENER = original

    def test_extreme_timestamp_is_rejected(self):
        self.assertIsNone(quota.iso_time(True))
        self.assertIsNone(quota.iso_time(float("inf")))

    def test_normalized_output_does_not_contain_credentials(self):
        original_path = quota.auth_path
        original_load = quota.load_auth
        original_request = quota.request_json
        output = io.StringIO()
        quota.auth_path = lambda: "/fixture/auth.json"
        quota.load_auth = lambda path: ({
            "openai": {"type": "oauth", "access": "secret-openai-token", "expires": 9999999999999},
            "opencode-go": {"type": "api", "key": "secret-opencode-key"},
        }, None)
        quota.request_json = lambda url, token, account=None: (({"usage": {
            "rolling": {"percent": 10, "resetsAt": "2026-09-04T05:00:00Z"},
            "weekly": {"percent": 20, "resetsAt": "2026-09-11T00:00:00Z"},
        }}, None) if url == quota.OPENCODE_URL else (None, quota.error("NETWORK_ERROR")))
        try:
            with redirect_stdout(output):
                quota.run()
        finally:
            quota.auth_path = original_path
            quota.load_auth = original_load
            quota.request_json = original_request
        self.assertNotIn("secret-openai-token", output.getvalue())
        self.assertNotIn("secret-opencode-key", output.getvalue())
        self.assertEqual(json.loads(output.getvalue())["providers"]["opencode"]["weekly"]["remainingPercent"], 80)


if __name__ == "__main__":
    unittest.main()
