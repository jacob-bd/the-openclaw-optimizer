#!/usr/bin/env python3
"""
OpenClaw Optimizer — Version Checker
=========================================
Checks if the skill is current with the latest OpenClaw release.
Caches results for 6 hours to reduce GitHub API calls.

Usage:
  python3 version-check.py            # standard check (uses cache)
  python3 version-check.py --force    # bypass cache, always hits API
  python3 version-check.py --status   # human-readable status report

Output (stdout, machine-readable):
  CURRENT                → skill matches latest OpenClaw
  STALE:<new_version>    → OpenClaw has a newer release
  UNCHECKED              → API unreachable, no valid cache
"""

import sys
import json
import time
import ssl
import urllib.request
import urllib.error
from pathlib import Path

SKILL_DIR    = Path(__file__).parent.parent
METADATA_DIR = SKILL_DIR / "metadata"
SKILL_MD     = SKILL_DIR / "SKILL.md"
LAST_CHECKED = METADATA_DIR / "last-checked.txt"
LATEST_VER   = METADATA_DIR / "latest-version.txt"

CACHE_TTL    = 21600  # 6 hours in seconds
GITHUB_API   = "https://api.github.com/repos/openclaw/openclaw/releases/latest"


def get_skill_version() -> str | None:
    """Read version from SKILL.md frontmatter."""
    try:
        for line in SKILL_MD.read_text().splitlines():
            if line.startswith("version:"):
                return line.split(":", 1)[1].strip()
    except IOError:
        pass
    return None


def get_ssl_context() -> ssl.SSLContext:
    """Create SSL context with proper certificate handling."""
    # Try system default first
    try:
        ctx = ssl.create_default_context()
        if ctx.get_ca_certs():
            return ctx
    except Exception:
        pass
    # Fall back to certifi if installed
    try:
        import certifi
        return ssl.create_default_context(cafile=certifi.where())
    except ImportError:
        pass
    # Last resort — warn explicitly, don't silently disable
    print("WARNING: No SSL certificates found. Using unverified HTTPS.", file=sys.stderr)
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx


def get_cached_latest() -> str | None:
    """Read cached latest version from disk."""
    try:
        return LATEST_VER.read_text().strip() or None
    except IOError:
        return None


def get_cache_age() -> float:
    """Seconds since last API check. Returns inf if never checked."""
    try:
        return time.time() - float(LAST_CHECKED.read_text().strip())
    except (IOError, ValueError):
        return float("inf")


def fetch_latest_version() -> str | None:
    """Fetch latest release version from GitHub API with rate-limit awareness."""
    skill_ver = get_skill_version() or "unknown"
    headers = {"User-Agent": f"openclaw-optimizer/{skill_ver}"}
    req = urllib.request.Request(GITHUB_API, headers=headers)
    try:
        ctx = get_ssl_context()
        with urllib.request.urlopen(req, timeout=10, context=ctx) as resp:
            data = json.loads(resp.read())
            tag = data.get("tag_name", "").lstrip("v")
            return tag if tag else None
    except urllib.error.HTTPError as e:
        if e.code in (403, 429):
            print(f"WARNING: GitHub API rate limited (HTTP {e.code}).", file=sys.stderr)
        return None
    except (urllib.error.URLError, json.JSONDecodeError, TimeoutError):
        return None


def save_cache(version: str) -> None:
    """Persist latest version and timestamp to disk."""
    METADATA_DIR.mkdir(parents=True, exist_ok=True)
    LATEST_VER.write_text(version)
    LAST_CHECKED.write_text(str(time.time()))


def main() -> None:
    force  = "--force"  in sys.argv
    status = "--status" in sys.argv

    skill_version = get_skill_version()
    if not skill_version:
        print("ERROR: could not read skill version from SKILL.md", file=sys.stderr)
        sys.exit(1)

    cache_age = get_cache_age()
    needs_refresh = force or cache_age >= CACHE_TTL

    if needs_refresh:
        latest = fetch_latest_version()
        if latest is None:
            cached = get_cached_latest()
            if status:
                print(f"WARNING: GitHub API unreachable. Skill: v{skill_version} | Cache: {cached or 'none'}")
            else:
                print("UNCHECKED")
            return
        save_cache(latest)
    else:
        latest = get_cached_latest()
        if latest is None:
            print("UNCHECKED")
            return

    is_current = latest == skill_version

    if status:
        age_str = f"{int(cache_age)}s ago" if not needs_refresh else "just checked"
        if is_current:
            print(f"CURRENT — Skill v{skill_version} matches OpenClaw v{latest} ({age_str})")
        else:
            print(f"STALE — Skill v{skill_version}, OpenClaw latest: v{latest} ({age_str})")
    else:
        if is_current:
            print("CURRENT")
        else:
            print(f"STALE:{latest}")


if __name__ == "__main__":
    main()
