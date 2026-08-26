#!/usr/bin/env python3
"""device_config.py (GH-174) — 3-Tier DRY Per-Device Configuration Resolver.

Resolves active harness, gateway, model, and reasoning effort across:
1. Local per-device file: ~/.xyz/device_config.json
2. Environment variables: XYZ_HARNESS, XYZ_MODEL, XYZ_REASONING_EFFORT, XYZ_GATEWAY
3. Global repository defaults
"""

import json
import os
import platform
from typing import Any, Dict, Optional


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


def resolve_device_setting(key: str, env_var: Optional[str] = None) -> Any:
    """Resolve single configuration key across 3-tier hierarchy."""
    # 1. Environment override
    if env_var and env_var in os.environ:
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
        "harness": resolve_device_setting("default_harness", "XYZ_HARNESS"),
        "gateway": resolve_device_setting("default_gateway", "XYZ_GATEWAY"),
        "model": resolve_device_setting("default_model", "XYZ_MODEL"),
        "reasoning_effort": resolve_device_setting("default_reasoning_effort", "XYZ_REASONING_EFFORT"),
        "logging_enabled": logging_enabled,
    }


if __name__ == "__main__":
    cfg = get_effective_runtime_config()
    print(json.dumps(cfg, indent=2))
