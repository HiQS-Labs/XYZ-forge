"""Native Claude account preflight shared by consult and relay (GH-610)."""
import json
import os
import shutil

from proc_group import run_bounded


def resolve_binary(env):
    explicit = env.get("CLAUDE_BIN")
    if explicit:
        return shutil.which(explicit, path=env.get("PATH")) or ""
    return (shutil.which("claude", path=env.get("PATH")) or
            next((p for p in (os.path.expanduser("~/.local/bin/claude"),
                             os.path.expanduser("~/.claude/local/claude"))
                  if os.path.isfile(p) and os.access(p, os.X_OK)), ""))


def preflight(binary, env, cwd):
    """Validate the request's actual account route; never expose auth JSON/secrets.

    inherit preserves existing CLI configuration. subscription requires normal
    Claude.ai login, not API keys, provider overrides, or custom OAuth plumbing.
    The CLI resolves settings (including apiKeyHelper) in the request directory.
    """
    mode = env.get("CLAUDE_AUTH_MODE", "inherit")
    if mode == "inherit":
        return
    if mode != "subscription":
        raise ValueError("CLAUDE_AUTH_MODE must be inherit or subscription")
    if not binary:
        raise ValueError("claude binary not found; install Claude Code or set CLAUDE_BIN")
    overrides = ("ANTHROPIC_API_KEY", "ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_BASE_URL",
                 "CLAUDE_CODE_USE_BEDROCK", "CLAUDE_CODE_USE_VERTEX", "CLAUDE_CODE_USE_FOUNDRY")
    if any(env.get(k) for k in overrides):
        raise ValueError("subscription mode refuses API/provider environment overrides; unset them and retry")
    try:
        result = run_bounded([binary, "auth", "status"], cwd=cwd, env=env, timeout=20)
        if result.timed_out or result.rc != 0:
            raise ValueError()
        account = json.loads(result.stdout)
        valid = (isinstance(account, dict) and account.get("loggedIn") is True
                 and account.get("authMethod") == "claude.ai"
                 and account.get("apiProvider") == "firstParty"
                 and account.get("subscriptionType") in ("pro", "max", "team", "enterprise"))
        if not valid:
            raise ValueError()
    except (OSError, ValueError, TypeError):
        raise ValueError("subscription auth status not verified; run Claude Code auth login/status in this directory") from None


def read_result(path):
    """Reject CLI error results even if the process exited zero."""
    try:
        with open(path, encoding="utf-8") as stream:
            data = json.load(stream)
        if (not isinstance(data, dict) or data.get("type") != "result"
                or data.get("is_error") is not False
                or data.get("subtype") != "success"
                or not isinstance(data.get("result"), str) or not data["result"].strip()):
            raise ValueError()
        return data["result"]
    except (OSError, ValueError, TypeError):
        raise ValueError("Claude returned an error or empty/invalid result; inspect the local transcript (no API fallback)") from None
