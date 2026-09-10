#!/usr/bin/env python3
"""device_config.py (GH-174) — 3-Tier DRY Per-Device Configuration Resolver.

Resolves active harness, gateway, model, and reasoning effort across:
1. Local per-device file: ~/.xyz/device_config.json
2. Environment variables: XYZ_DEFAULT_HARNESS (or deprecated XYZ_HARNESS), XYZ_MODEL, XYZ_REASONING_EFFORT, XYZ_GATEWAY
   Note: XYZ_HARNESS is the harness root path variable; use XYZ_DEFAULT_HARNESS for the harness name.
3. Global repository defaults
"""

import json
import os
import platform
import sys
from typing import Any, Dict, Optional, Tuple


GLOBAL_DEFAULTS = {
    "device_id": f"{platform.node() or 'local-device'}",
    "user_name": os.environ.get("USER", "default_user"),
    "default_harness": "dsh",
    "default_gateway": "openrouter",
    "default_model": "deepseek/deepseek-v4-pro",
    "default_reasoning_effort": "high",
    "logging_enabled": False,
}


def get_device_config_path() -> str:
    """Return canonical path to local user device configuration file."""
    return os.environ.get("XYZ_DEVICE_CONFIG_PATH") or os.path.expanduser("~/.xyz/device_config.json")


def load_local_device_config() -> Dict[str, Any]:
    """Read ~/.xyz/device_config.json if present; return empty dict if missing."""
    p = get_device_config_path()
    if os.path.exists(p):
        try:
            with open(p, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return {}
    return {}


def load_device_config_diagnostic() -> Tuple[Dict[str, Any], Optional[str]]:
    """Like load_local_device_config, but says WHY it returned nothing (GH-549).

    load_local_device_config() collapses "file absent" and "file present but unparseable"
    into the same empty dict, so every caller that needs to tell a silent no-op from a
    misconfiguration has had to re-open the file itself — profile_resolve.py does exactly
    that today. This returns (config, error): error is None when the file is absent (a
    legitimate silent no-op) and a message when it exists but could not be read.
    """
    p = get_device_config_path()
    if not os.path.exists(p):
        return {}, None
    try:
        with open(p, "r", encoding="utf-8") as f:
            raw = f.read()
    except Exception as exc:
        return {}, "%s is unreadable (%s)" % (p, exc)
    if not raw.strip():
        # An empty file is "no config", not a broken one. /dev/null is the standard idiom
        # for "no device config" in this repo's suites, and it must stay a silent no-op.
        return {}, None
    try:
        loaded = json.loads(raw)
    except Exception as exc:
        return {}, "%s is unreadable (%s)" % (p, exc)
    if not isinstance(loaded, dict):
        return {}, "%s does not contain a JSON object" % p
    return loaded, None


def resolve_device_block(block: str, defaults: Dict[str, Any],
                         env_prefix: str) -> Tuple[Dict[str, Any], Optional[str]]:
    """3-tier resolution for a NESTED config object (GH-549).

    resolve_device_setting handles top-level keys, and its env tier can only ever produce a
    string, so a nested object like `board_sync` or `work_connectors` has had to carry its own
    merge. This is that merge, factored out once: per-key `<env_prefix>_<KEY>` env override with
    list and int coercion driven by the shape of the default, then the file's block, then the
    defaults.

    Returns (config, error) with the same contract as load_device_config_diagnostic: error is
    None for an absent config, and a message when the file or the block is malformed — the
    caller decides whether that is a warning or a refusal.
    """
    cfg = dict(defaults)
    loaded, error = load_device_config_diagnostic()
    local = loaded.get(block, {})
    if not isinstance(local, dict):
        return cfg, "%s setting is not an object — ignoring it" % block
    for key in defaults:
        env = "%s_%s" % (env_prefix, key.upper())
        if env in os.environ:
            raw = os.environ[env]
            if isinstance(defaults[key], list):
                raw = [p.strip() for p in raw.split(",") if p.strip()]
            elif isinstance(defaults[key], bool):
                raw = raw not in ("0", "false", "False", "")
            elif isinstance(defaults[key], int):
                try:
                    raw = int(raw)
                except ValueError:
                    error = error or "%s=%r is not an integer — ignoring it" % (env, raw)
                    continue
            cfg[key] = raw
        elif key in local:
            cfg[key] = local[key]
    # A JSON-file value skips the env tier's comma-splitting, so a bare string where a list
    # belongs would iterate characters downstream. Coerce, driven by the default's shape.
    for key, default in defaults.items():
        if isinstance(default, list) and isinstance(cfg.get(key), str):
            cfg[key] = [cfg[key]]
    return cfg, error


def resolve_device_setting(key: str, env_var: Optional[str] = None) -> Any:
    """Resolve single configuration key across 3-tier hierarchy."""
    # 1. Environment override
    if key == "default_harness":
        if "XYZ_DEFAULT_HARNESS" in os.environ:
            return os.environ["XYZ_DEFAULT_HARNESS"]
        if "XYZ_HARNESS" in os.environ:
            val = os.environ["XYZ_HARNESS"]
            if not os.path.isdir(val):
                print("device_config.py: warning: XYZ_HARNESS is deprecated for harness name; use XYZ_DEFAULT_HARNESS instead (XYZ_HARNESS is the harness root path)", file=sys.stderr)
                return val
    elif env_var and env_var in os.environ:
        return os.environ[env_var]

    # 2. Local device JSON
    local_cfg = load_local_device_config()
    if key in local_cfg:
        return local_cfg[key]

    # 3. Global default
    return GLOBAL_DEFAULTS.get(key)


def get_effective_runtime_config() -> Dict[str, Any]:
    """Return dictionary of all active resolved runtime settings."""
    raw_logging = resolve_device_setting("logging_enabled", "XYZ_HARNESS_LOGGING")
    logging_enabled = (
        raw_logging in (True, 1, "1", "true", "True", "yes", "on")
        if raw_logging is not None
        else False
    )
    return {
        "device_id": resolve_device_setting("device_id", "XYZ_DEVICE_ID"),
        "user_name": resolve_device_setting("user_name", "XYZ_USER_NAME"),
        "harness": resolve_device_setting("default_harness", "XYZ_DEFAULT_HARNESS"),
        "gateway": resolve_device_setting("default_gateway", "XYZ_GATEWAY"),
        "model": resolve_device_setting("default_model", "XYZ_MODEL"),
        "reasoning_effort": resolve_device_setting("default_reasoning_effort", "XYZ_REASONING_EFFORT"),
        "logging_enabled": logging_enabled,
    }


if __name__ == "__main__":
    cfg = get_effective_runtime_config()
    print(json.dumps(cfg, indent=2))
