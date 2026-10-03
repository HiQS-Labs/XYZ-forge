"""Native Claude account preflight shared by consult and relay (GH-610)."""
import json
import os
import shutil
import re
import sys
import math
from datetime import datetime, timezone

from proc_group import run_bounded

PROVIDER_OVERRIDES = ("ANTHROPIC_API_KEY", "ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_BASE_URL",
                      "CLAUDE_CODE_USE_BEDROCK", "CLAUDE_CODE_USE_VERTEX", "CLAUDE_CODE_USE_FOUNDRY")
HIQS_CONFIG_ENV = {"model": "CLAUDE_MODEL", "effort": "CLAUDE_REASONING_EFFORT",
                   "authMode": "CLAUDE_AUTH_MODE", "maxTurns": "CLAUDE_MAX_TURNS",
                   "maxBudgetUsd": "CLAUDE_MAX_BUDGET"}


def read_json_bounded(path, limit=1024 * 1024):
    """Local nonsecret admission inputs; never echo malformed bytes."""
    with open(path, "rb") as stream:
        raw = stream.read(limit + 1)
    if len(raw) > limit:
        raise ValueError("HiQS JSON exceeds admission limit")
    return json.loads(raw)


def validate_advisory_config(config):
    """One fixed preimage for the existing consult argv, not a generic flag language."""
    fixed = {"schema": "xyz.claude-advisory.v1", "authMode": "subscription",
             "tools": ["Read", "Grep", "Glob"], "allowedTools": ["Read", "Grep", "Glob"],
             "restricted": True, "strictMcpConfig": True, "outputFormat": "json"}
    if (not isinstance(config, dict) or set(config) != set(fixed) | set(HIQS_CONFIG_ENV)
            or any(config.get(k) != v for k, v in fixed.items())
            or config.get("restricted") is not True or config.get("strictMcpConfig") is not True
            or not isinstance(config.get("model"), str)
            or not re.fullmatch(r"claude-[a-z0-9._-]+", config["model"])
            or config.get("effort") not in ("low", "medium", "high", "xhigh", "max")
            or not isinstance(config.get("maxTurns"), str)
            or not re.fullmatch(r"[1-9][0-9]*", config["maxTurns"])
            or not isinstance(config.get("maxBudgetUsd"), str)
            or not re.fullmatch(r"(?:0|[1-9][0-9]*)\.[0-9]{2}", config["maxBudgetUsd"])
            or not math.isfinite(float(config["maxBudgetUsd"])) or float(config["maxBudgetUsd"]) <= 0):
        raise ValueError("unsupported HiQS Claude advisory configuration")
    return {env: config[key] for key, env in HIQS_CONFIG_ENV.items()}


def check_admission_expiry(recipe):
    expiry = recipe["effectiveExpiresAt"]
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z", expiry):
        raise ValueError("HiQS admission has no UTC expiry")
    if datetime.now(timezone.utc) >= datetime.fromisoformat(expiry.replace("Z", "+00:00")):
        raise ValueError("HiQS admission expired; resolve explicitly again")


def validate_admission(receipt, env, cwd):
    """Recheck retained admission locally before EACH advisory call; no resolver retry."""
    request, response = receipt["request"], receipt["response"]
    config = request["executionConfig"]
    expected = validate_advisory_config(config)
    route = response["result"]["route"]
    recipe = route["recipe"]
    target = recipe["target"]
    ref = request["input"]["recipeRef"]
    if (response.get("protocolVersion") != "2" or response.get("status") != "resolved"
            or response.get("enforcedRecipeRef") != ref or recipe["refs"] != [ref]
            or response["input"].get("recipeRef") != ref
            or response["input"].get("policy") != request["input"]["policy"]
            or response["input"].get("asOf") != request["input"]["asOf"]
            or response["input"].get("requiredCapabilities", []) != request["input"].get("requiredCapabilities", [])
            or response["lock"]["request"].get("recipeRef") != ref
            or response["descriptor"].get("trust") != "untrusted"
            or response["descriptor"]["executionConfig"] != config
            or response["descriptor"]["target"] != target
            or response["lock"]["decision"].get("recipe") != recipe
            or any(response["lock"]["decision"].get(k) != route.get(k) for k in
                   ("harness", "gateway", "model", "bindingId", "requestModelIdentifier", "adapterConfig"))
            or route["harness"] != response["input"]["harness"]
            or route["model"] != response["input"]["query"]
            or response["descriptor"]["binding"]["id"] != route["bindingId"]
            or response["result"].get("status") != "resolved"
            or response["result"]["trace"]["snapshotDigest"] != request["snapshotPolicy"]["digest"]
            or target.get("mode") != "hosted" or target.get("transport") != "claude-code-subscription"
            or target.get("endpoint") != "https://claude.ai" or target.get("routing")
            or target.get("adapterConfig") != {} or route.get("adapterConfig") != {}
            or target.get("gateway") != route.get("gateway")
            or target.get("requestIdentifier") != config["model"]
            or route.get("requestModelIdentifier") != config["model"]
            or any(env.get(k) != v for k, v in expected.items())
            or env.get("CLAUDE_FLAGS")
            or any(env.get(k) for k in env if k.startswith("ANTHROPIC_") or k in PROVIDER_OVERRIDES
                   or k.startswith("CLAUDE_CODE_") or k.startswith("CLAUDE_CONFIG_"))):
        raise ValueError("HiQS admission differs from the supported native configuration")
    check_admission_expiry(recipe)
    for key, original in (("snapshotPath", request["snapshot"]), ("policyPath", request["input"]["policy"]),
                          ("executionConfigPath", config)):
        if read_json_bounded(receipt[key]) != original:
            raise ValueError("HiQS retained inputs changed; resolve explicitly again")
    binary = resolve_binary(env)
    if not binary or os.path.realpath(binary) != receipt["binary"]:
        raise ValueError("HiQS admitted Claude binary is unavailable or changed")
    version = run_bounded([binary, "--version"], env=env, cwd=cwd, timeout=5)
    build = recipe["harnessBuild"]
    match = re.match(r"^(\d+)\.(\d+)\.(\d+)(?:\s|$)", version.stdout.strip())
    if (version.timed_out or version.rc != 0 or not match or build.get("commit")
            or ".".join(match.groups()) != build["packageVersion"]
            or tuple(map(int, match.groups())) < (2, 1, 248)):
        raise ValueError("HiQS admitted Claude build cannot be verified")
    # Restricted loads managed settings. This pilot cannot materialize their overrides.
    if sys.platform != "darwin":
        raise ValueError("HiQS advisory admission currently supports macOS only")
    if any(os.path.exists(os.path.join("/Library/Application Support/ClaudeCode", name))
           for name in ("managed-settings.json", "managed-settings.d", "managed-mcp.json")):
        raise ValueError("HiQS advisory admission does not support managed Claude settings")
    managed = run_bounded(["/usr/bin/defaults", "read", "com.anthropic.claudecode"], timeout=5)
    absent = re.search(r"Domain[^\n]*(?:does not exist|not found)", managed.stderr, re.IGNORECASE)
    if managed.timed_out or managed.rc != 1 or not absent:
        raise ValueError("HiQS advisory admission cannot exclude managed Claude preferences")
    return expected


def admission_preflight(binary, env, cwd):
    receipt = None
    if env.get("XYZ_HIQS_ADMISSION"):
        try:
            receipt = read_json_bounded(env["XYZ_HIQS_ADMISSION"], 3 * 1024 * 1024)
            validate_admission(receipt, env, cwd)
        except (OSError, ValueError, KeyError, TypeError, AttributeError):
            raise ValueError("HiQS advisory admission refused; reselect the profile explicitly") from None
    preflight(binary, env, cwd, cli_flags=["--restricted", "--strict-mcp-config"])
    if receipt:
        check_admission_expiry(receipt["response"]["result"]["route"]["recipe"])


def resolve_binary(env):
    explicit = env.get("CLAUDE_BIN")
    if explicit:
        return shutil.which(explicit, path=env.get("PATH")) or ""
    return (shutil.which("claude", path=env.get("PATH")) or
            next((p for p in (os.path.expanduser("~/.local/bin/claude"),
                             os.path.expanduser("~/.claude/local/claude"))
                  if os.path.isfile(p) and os.access(p, os.X_OK)), ""))


def effort_flags(env):
    """Share native effort selection; omission leaves the CLI default intact."""
    effort = env.get("CLAUDE_REASONING_EFFORT", "")
    if effort and effort not in ("low", "medium", "high", "xhigh", "max"):
        raise ValueError("CLAUDE_REASONING_EFFORT must be low, medium, high, xhigh, or max")
    return ["--effort", effort] if effort else []


def preflight(binary, env, cwd, *, cli_flags=()):
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
    overrides = PROVIDER_OVERRIDES
    if any(env.get(k) for k in overrides):
        raise ValueError("subscription mode refuses API/provider environment overrides; unset them and retry")
    try:
        result = run_bounded([binary, *cli_flags, "auth", "status"], cwd=cwd, env=env, timeout=20)
        if result.timed_out or result.rc != 0:
            raise ValueError()
        account = json.loads(result.stdout)
        valid = (isinstance(account, dict) and account.get("loggedIn") is True
                 and account.get("authMethod") == "claude.ai"
                 and account.get("apiProvider") == "firstParty"
                 and account.get("subscriptionType") in ("pro", "max", "team", "enterprise"))
        if env.get("XYZ_HIQS_ADMISSION") and account.get("subscriptionType") not in ("pro", "max"):
            valid = False
        if not valid:
            raise ValueError()
    except (OSError, ValueError, TypeError):
        raise ValueError("subscription auth status not verified; run Claude Code auth login/status in this directory") from None


def read_result(path, expected_model=None):
    """Reject CLI error results even if the process exited zero."""
    try:
        with open(path, encoding="utf-8") as stream:
            data = json.load(stream)
        if (not isinstance(data, dict) or data.get("type") != "result"
                or data.get("is_error") is not False
                or data.get("subtype") != "success"
                or not isinstance(data.get("result"), str) or not data["result"].strip()):
            raise ValueError()
        if expected_model and (not isinstance(data.get("modelUsage"), dict)
                               or set(data["modelUsage"]) != {expected_model}):
            raise ValueError()
        return data["result"]
    except (OSError, ValueError, TypeError):
        raise ValueError("Claude returned an error or empty/invalid result; inspect the local transcript (no API fallback)") from None
