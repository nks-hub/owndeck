"""Prepare the ignored build configuration from CI secrets."""

import json
import os
from pathlib import Path
import re
from urllib.parse import unquote, urlsplit


def configuration(environment, version):
    values = {key: environment.get(key, "").strip() for key in (
        "SENTRY_DSN", "RYBBIT_HOST", "RYBBIT_SITE_ID",
    )}
    for key in ("SENTRY_DSN", "RYBBIT_HOST"):
        try:
            uri = urlsplit(values[key])
            valid = uri.scheme == "https" and uri.hostname and not uri.query and not uri.fragment
            valid = valid and (uri.port is None or 0 < uri.port < 65536)
            parts = [unquote(part) for part in uri.path.split("/")]
            valid = valid and not any(part in (".", "..") or "\\" in part or "/" in part or any(ord(char) < 32 or ord(char) == 127 for char in part) for part in parts)
        except ValueError:
            valid = False
        if not valid:
            raise ValueError(f"{key} requires a valid HTTPS address")
    dsn = urlsplit(values["SENTRY_DSN"])
    if not re.fullmatch(r"[a-zA-Z0-9]+", dsn.username or "") or dsn.password is not None or not re.fullmatch(r"\d+", dsn.path.split("/")[-1]):
        raise ValueError("SENTRY_DSN requires a public key and project id")
    if urlsplit(values["RYBBIT_HOST"]).username is not None:
        raise ValueError("RYBBIT_HOST must not contain credentials")
    if not re.fullmatch(r"[a-zA-Z0-9_-]{1,64}", values["RYBBIT_SITE_ID"]):
        raise ValueError("RYBBIT_SITE_ID is required for official builds")
    stage = environment.get("TELEMETRY_ENVIRONMENT", "production")
    if stage not in ("development", "staging", "production", "test"):
        raise ValueError("Invalid TELEMETRY_ENVIRONMENT")
    if not re.fullmatch(r"\d+\.\d+\.\d+(?:-[a-zA-Z0-9.-]+)?\+\d+", version):
        raise ValueError("Invalid release version")
    return values | {"TELEMETRY_ENVIRONMENT": stage, "TELEMETRY_RELEASE": f"com.nkshub.nextclouddeck@{version}"}


if __name__ == "__main__":
    root = Path(__file__).resolve().parent.parent
    try:
        values = configuration(os.environ, (root / "VERSION").read_text(encoding="utf-8").strip())
    except ValueError as error:
        raise SystemExit(str(error)) from None
    target = root / "apps/mobile/telemetry.json"
    target.write_text(json.dumps(values), encoding="utf-8")
    target.chmod(0o600)
    print("Both telemetry services are configured for this build.")
