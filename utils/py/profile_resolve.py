#!/usr/bin/env python3
"""profile_resolve.py (GH-346 Phase 3a) — one name resolves to harness, gateway, and model.

The problem this closes. Naming a reviewer for a relay review turn meant hand-assembling this,
which was typed by hand four times during GH-346's own QA:

    COMMANDCODE_AGENT=commandcode ALLOW_PATHS="" \\
    COMMANDCODE_MODEL="zai-org/glm-5.3" COMMANDCODE_REASONING_EFFORT="max" \\
    relay-automation/relay-drive.sh --relay-file "$RELAY" --relay-task "$TASK" \\
      --agent-cmd relay-automation/commandcode-turn.sh --review-once

Getting there took three separate lookups that do not read each other: the harness (re-resolved
every shell), the gateway (documented nowhere but each shim's source), and the model (one of two
tables depending on which gateway you already picked). After this module:

    eval "$(resolve-profile.sh 'glm 5.3 max' --env)"

RESOLUTION ORDER — explicit beats preferred beats shipped:

  1. Full manual path: the lane's own `*_AGENT` / `*_MODEL` env vars, already set. Always wins,
     never second-guessed. This is the operator's stated override and is NOT deprecated.
  2. A named profile from `profiles` in ~/.xyz/device_config.json, matched through the EXISTING
     resolve-model-alias.sh normalizer so "GLM5.3 max", "glm 5.3 max" and "GLM 5.3 Max" are one
     entry. No new fuzzy matcher.
  3. (Phase 3b, not built) harnesses.db `models` table, for fields a profile omitted.
  4. The shim's own literal default. The floor, unchanged, always.

EVERY TIER IS SKIPPABLE, INCLUDING ON A PARSE ERROR. A missing config, malformed JSON, an unknown
key, an unmatched name — each is caught, reported on stderr, and falls through. A turn that could
not run because a *preference* was unreadable would be strictly worse than no preferences at all.
Nothing here can block a turn, and no fallback is silent: that is GH-346 Phase 0's "log the
swallow" lesson, where two silent handlers hid a bug for the entire life of three shims.

DERIVE, NEVER CURATE. GH-346 Phase 2 found the lane set enumerated in TEN hand-maintained
allowlists, three of which were invisible to careful reading and surfaced only when a test failed.
This module adds no eleventh copy: `lanes()` reads marathon_drive.py's `route_agent` source for the
lane ids and their `*_AGENT` variables, and reads each shim's own telemetry call for its gateway
variable (deepseek's is DEEPSEEK_PROVIDER, not DEEPSEEK_GATEWAY -- exactly the kind of detail a
curated table gets wrong).
"""

import json
import os
import shutil
import re
import subprocess
import sys
from typing import Any, Dict, List, Optional, Tuple

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from device_config import load_local_device_config, get_device_config_path  # noqa: E402
from model_alias import resolver_path  # noqa: E402

# The resolver is a local bash script over a small in-memory table. Anything near this bound means
# it is wedged, not slow, and a turn is worth more than a name lookup.
MATCH_TIMEOUT_S = 10

# A harness that is its own router carries this instead of a third-party gateway name. Command Code
# is the case that forced it: `cmd` resolves models from its own catalog and holds no OpenRouter
# key, base URL, or routing config. Writing `gateway: openrouter` for that lane would emit a value
# the shim ignores and telemetry would then record a router that was never used -- the exact defect
# GH-346 Phase 0 exists to remove, one argument over.
SELF_ROUTED = "self"


def _warn(msg: str) -> None:
    """Every fallback announces itself. No tier may fail quietly."""
    print(f"resolve-profile: {msg}", file=sys.stderr)


# --------------------------------------------------------------------------------------------
# Lane discovery -- derived from source, never curated here.
# --------------------------------------------------------------------------------------------

def _route_agent_source(xyz_root: str) -> str:
    try:
        with open(os.path.join(xyz_root, "utils", "py", "marathon_drive.py"), encoding="utf-8") as f:
            src = f.read()
    except Exception as exc:
        _warn(f"cannot read marathon_drive.py ({exc!r}) — lane set unavailable")
        return ""
    i = src.find("def route_agent(")
    if i < 0:
        _warn("route_agent() not found in marathon_drive.py — lane set unavailable")
        return ""
    # Stop at the first line that dedents past the branches: the `else: die(...)` closes the chain.
    j = src.find("not recognized", i)
    return src[i: j if j > 0 else len(src)]


def _gateway_var_for(xyz_root: str, lane: str, prefix: str) -> Optional[str]:
    """Read the shim's OWN telemetry call for the env var it treats as the gateway.

    Not `f"{prefix}_GATEWAY"` by assumption: deepseek-turn.py uses DEEPSEEK_PROVIDER, and a
    hand-written table is precisely how that gets recorded wrong. Returns None when the shim
    writes no telemetry at all (smallcode-turn.sh is bash-only and has no logger).
    """
    path = os.path.join(xyz_root, "utils", "py", f"{lane}-turn.py")
    try:
        with open(path, encoding="utf-8") as f:
            src = f.read()
    except Exception:
        return None
    # Direct form, which five of the seven use: gateway=os.environ.get("X_GATEWAY", ...)
    m = re.search(r"gateway\s*=\s*os\.environ\.get\(\s*[\"']([A-Z0-9_]+)[\"']", src)
    if m:
        return m.group(1)

    # One level of local-variable indirection: gateway=deepseek_provider, with
    # deepseek_provider = os.environ.get("DEEPSEEK_PROVIDER", ...) higher up. This branch is why
    # the function reads source instead of assuming f"{prefix}_GATEWAY" -- deepseek's variable is
    # DEEPSEEK_PROVIDER, and the first cut of this derivation missed it and reported the lane as
    # having no gateway variable at all. A curated table would have been wrong in the same place,
    # just without anything to catch it.
    m = re.search(r"gateway\s*=\s*([a-z_][a-z0-9_]*)\s*,", src)
    if m:
        local = m.group(1)
        m2 = re.search(
            rf"^\s*{re.escape(local)}\s*=\s*os\.environ\.get\(\s*[\"']([A-Z0-9_]+)[\"']",
            src, re.M,
        )
        if m2:
            return m2.group(1)

    # A shim that hardcodes its gateway, or writes no telemetry at all, has no variable to emit.
    return None



def _cli_for(xyz_root: str, lane: str, prefix: str) -> str:
    """The binary a lane's shim actually invokes.

    Derived from the shim's own `<PREFIX>_BIN` default rather than a curated map here, for the same
    reason lanes() derives from route_agent(): a lane whose binary is renamed must not need a second
    edit in this file. Falls back to the lane name, which is correct for codex and agy.
    """
    src_path = os.path.join(xyz_root, "utils", "py", f"{lane}-turn.py")
    try:
        with open(src_path, "r", encoding="utf-8") as fh:
            src = fh.read()
    except OSError:
        return lane
    m = re.search(r'%s_BIN["\']\s*,\s*["\']([A-Za-z0-9_.-]+)["\']' % re.escape(prefix), src)
    if m:
        return m.group(1)
    m = re.search(r'shutil\.which\(\s*["\']([A-Za-z0-9_.-]+)["\']\s*\)', src)
    return m.group(1) if m else lane

def lanes(xyz_root: str) -> Dict[str, Dict[str, Any]]:
    """Every lane route_agent() routes, with the env contract each one answers to.

    Derived, so a lane added to route_agent without being taught here shows up automatically
    rather than silently missing from --list.
    """
    src = _route_agent_source(xyz_root)
    out: Dict[str, Dict[str, Any]] = {}
    for lane, agent_var in re.findall(
        # GH-368: AGY_AGENT accumulates same-lane actors with a join rather than a bare
        # assignment.  The derivation intentionally keys on the env slot, not that assignment's
        # right-hand side, so routing can evolve without growing a curated lane allowlist here.
        r"agent_id\.startswith\(\s*[\"']([a-z0-9_]+)[\"']\s*\)\s*:\s*os\.environ\[\s*[\"']([A-Z0-9_]+)[\"']\s*\]",
        src,
    ):
        prefix = agent_var[: -len("_AGENT")] if agent_var.endswith("_AGENT") else agent_var
        shim = os.path.join("relay-automation", f"{lane}-turn.sh")
        out[lane] = {
            "lane": lane,
            "prefix": prefix,
            "agent_var": agent_var,
            "model_var": f"{prefix}_MODEL",
            "effort_var": f"{prefix}_REASONING_EFFORT",
            "flags_var": f"{prefix}_FLAGS",
            "gateway_var": _gateway_var_for(xyz_root, lane, prefix),
            "shim": shim,
            "shim_exists": os.path.isfile(os.path.join(xyz_root, shim)),
        }
    if not out:
        _warn("no lanes derived from route_agent() — falling through to the shim defaults")
    return out


# --------------------------------------------------------------------------------------------
# Profiles -- read from the config file the operator already owns.
# --------------------------------------------------------------------------------------------

def load_profiles() -> Dict[str, Dict[str, Any]]:
    """The `profiles` block of ~/.xyz/device_config.json. Never raises, never blocks a turn."""
    try:
        cfg = load_local_device_config()
    except Exception as exc:
        _warn(f"device config unreadable ({exc!r}) — no profiles, falling through")
        return {}

    # device_config.load_local_device_config() returns {} for BOTH "file absent" and "file present
    # but unparseable". Those need different messages: an operator with a trailing comma in their
    # config, told only "no profiles defined", goes looking in the wrong place entirely. Falling
    # back silently is the Phase 0 defect; falling back with a misleading reason is the same
    # defect wearing a message.
    path = get_device_config_path()
    if not cfg and os.path.exists(path):
        try:
            with open(path, encoding="utf-8") as f:
                json.load(f)
        except Exception as exc:
            _warn(f"{path} is present but could not be parsed ({exc}) — falling through to the "
                  f"shim defaults. Fix the file; nothing here will block a turn over it.")
            return {}

    if not isinstance(cfg, dict):
        _warn("device config is not a JSON object — no profiles, falling through")
        return {}
    profiles = cfg.get("profiles")
    if profiles is None:
        return {}
    if not isinstance(profiles, dict):
        _warn("'profiles' in the device config is not an object — ignoring it, falling through")
        return {}
    good: Dict[str, Dict[str, Any]] = {}
    for name, body in profiles.items():
        if isinstance(body, dict):
            good[str(name)] = body
        else:
            _warn(f"profile {name!r} is not an object — skipping it")
    return good


def match_profile(name: str, profiles: Dict[str, Dict[str, Any]], xyz_root: str) -> Optional[str]:
    """Match a colloquial name to a profile key, reusing resolve-model-alias.sh's matcher.

    The script's four tiers -- normalized, squashed, sorted-token, substring -- stay the single
    implementation of colloquial-name matching in this repo. GH-346 shipped the one-character
    change (its readability guard went -f to -r) that lets a caller pipe in its own table, so
    nothing here reimplements normalize/squash and there is no second matcher to keep in parity.
    """
    if not name or not profiles:
        return None
    if name in profiles:            # exact key: no subprocess needed
        return name

    script = resolver_path(xyz_root)
    if not os.path.isfile(script):
        _warn(f"alias matcher not found at {script} — exact profile names only")
        return None

    # `key: key` so the canonical output IS the profile key. A ':' in a profile name would split
    # wrong in the flat table, so those are matched exactly above and excluded from the pipe.
    table = "".join(f"{k}: {k}\n" for k in profiles if ":" not in k)
    if not table:
        return None
    try:
        env = dict(os.environ, MODEL_ALIASES_FILE="/dev/stdin")
        r = subprocess.run(
            ["bash", script, name],
            input=table, capture_output=True, text=True,
            check=False, timeout=MATCH_TIMEOUT_S, env=env,
        )
    except Exception as exc:
        _warn(f"profile matcher failed ({exc!r}) — falling through")
        return None

    if r.returncode == 0 and r.stdout.strip() in profiles:
        return r.stdout.strip()
    return None


# --------------------------------------------------------------------------------------------
# Resolution
# --------------------------------------------------------------------------------------------

def validate_profile(key: str, body: Dict[str, Any], lane_map: Dict[str, Dict[str, Any]]) -> List[str]:
    """Problems that make a profile unusable. Reported, never raised -- see the module docstring."""
    problems: List[str] = []
    harness = body.get("harness")
    if not harness:
        problems.append("no 'harness'")
    elif lane_map and harness not in lane_map:
        known = ", ".join(sorted(lane_map)) or "(none derived)"
        problems.append(f"harness {harness!r} is not a lane route_agent() routes (known: {known})")
    elif not lane_map[harness]["shim_exists"]:
        problems.append(f"harness {harness!r} routes but its shim {lane_map[harness]['shim']} is missing")

    gw = body.get("gateway")
    if not gw:
        problems.append(f"no 'gateway' (use {SELF_ROUTED!r} when the harness is its own router)")
    elif harness and lane_map and harness in lane_map:
        if gw == harness:
            problems.append(
                f"gateway {gw!r} repeats the harness name — use {SELF_ROUTED!r}, which says the "
                f"path has two elements rather than three with one filled in twice"
            )
        elif gw != SELF_ROUTED and lane_map[harness]["gateway_var"] is None:
            problems.append(
                f"harness {harness!r} has no gateway variable to receive {gw!r} — it routes "
                f"internally, so this value would be emitted and then ignored"
            )
    if not body.get("model"):
        problems.append("no 'model'")
    return problems


def resolve(name: Optional[str], xyz_root: str) -> Dict[str, Any]:
    """Resolve a profile name to a complete dispatch path. Always returns; never raises."""
    lane_map = lanes(xyz_root)
    result: Dict[str, Any] = {
        "query": name, "tier": None, "why": "", "profile": None,
        "harness": None, "gateway": None, "model": None, "effort": None, "flags": None,
        "problems": [], "lanes": lane_map,
    }

    # ---- Tier 1: an explicit manual path already in the environment. Always wins. ----
    for lane, spec in lane_map.items():
        if os.environ.get(spec["agent_var"]) and os.environ.get(spec["model_var"]):
            result.update(
                tier=1, harness=lane, model=os.environ[spec["model_var"]],
                gateway=(os.environ.get(spec["gateway_var"]) if spec["gateway_var"] else None),
                effort=os.environ.get(spec["effort_var"]),
                flags=os.environ.get(spec["flags_var"]),
                why=(f"{spec['agent_var']} and {spec['model_var']} are both set — an explicit "
                     f"manual path always wins and is never second-guessed"),
            )
            return result

    # ---- Tier 2: a named profile. ----
    profiles = load_profiles()
    if name:
        key = match_profile(name, profiles, xyz_root)
        if key:
            body = profiles[key]
            problems = validate_profile(key, body, lane_map)
            result.update(
                tier=2, profile=key, harness=body.get("harness"), gateway=body.get("gateway"),
                model=body.get("model"), effort=body.get("effort"), flags=body.get("flags"),
                problems=problems,
                why=(f"matched profile {key!r} in {get_device_config_path()}"
                     + (" (with problems — see below)" if problems else "")),
            )
            return result
        if profiles:
            _warn(f"no profile matched {name!r} (have: {', '.join(sorted(profiles))}) — falling through")
        else:
            _warn(f"no profiles defined in {get_device_config_path()} — falling through")

    # ---- Tier 4: the floor. Today's behavior, unchanged. ----
    # Tier 3 (harnesses.db `models`) is Phase 3b and deliberately absent; its slot is kept in the
    # numbering so --explain never implies a tier ran that did not.
    result.update(
        tier=4,
        why=("no profile applied — each shim keeps its own literal default, exactly as before "
             "this feature existed"),
    )
    return result


# --------------------------------------------------------------------------------------------
# Output modes
# --------------------------------------------------------------------------------------------

def _sh_quote(v: str) -> str:
    return "'" + str(v).replace("'", "'\\''") + "'"


def emit_env(res: Dict[str, Any], xyz_root: str) -> Tuple[str, int]:
    """The export block a relay review turn needs, and nothing it does not."""
    if res["tier"] == 4:
        return ("# resolve-profile: nothing to export — the shims' own defaults apply.\n", 0)

    lane_map, harness = res["lanes"], res["harness"]
    if not harness or harness not in lane_map:
        _warn(f"cannot emit env for harness {harness!r} — not a routable lane")
        return ("", 1)
    if res["problems"]:
        for p in res["problems"]:
            _warn(f"profile {res['profile']!r}: {p}")
        _warn("refusing to emit a broken export block — fix the profile or pass the path manually")
        return ("", 1)

    spec = lane_map[harness]
    lines = [
        f"# resolve-profile: {res['query']!r} -> tier {res['tier']}"
        + (f" (profile {res['profile']!r})" if res["profile"] else ""),
        f"export {spec['agent_var']}={_sh_quote(harness)}",
        f"export {spec['model_var']}={_sh_quote(res['model'])}",
    ]

    # The gateway. Omitted for a self-routed harness on purpose: exporting the harness's own name
    # into a variable meant for a third-party router is how a value that means "no router" gets
    # logged as if it were one.
    gw = res["gateway"]
    if spec["gateway_var"] and gw and gw != SELF_ROUTED:
        lines.append(f"export {spec['gateway_var']}={_sh_quote(gw)}")
    elif gw == SELF_ROUTED and spec["gateway_var"]:
        lines.append(f"# {spec['gateway_var']}: not set — {harness} is its own router")

    if res["effort"]:
        lines.append(f"export {spec['effort_var']}={_sh_quote(res['effort'])}")
    if res["flags"]:
        lines.append(f"export {spec['flags_var']}={_sh_quote(res['flags'])}")

    # RELAY_AGENT is the actor name the turn shims compare against <HARNESS>_AGENT before they
    # will act. Every shim hard-requires it ("RELAY_AGENT required", exit) — so without this line
    # the one-liner this whole feature exists to provide could not run for ANY profile, and the
    # operator got a bare "RELAY_AGENT required" with nothing pointing back here. It must match
    # the relay file's `NEXT:` and the <HARNESS>_AGENT value emitted above.
    lines.append(f"export RELAY_AGENT={_sh_quote(harness)}")
    lines.append(f"export RELAY_AGENT_CMD={_sh_quote(spec['shim'])}")
    lines.append(f"export HARNESS={_sh_quote(xyz_root)}")

    # Resolving to a harness whose CLI is not installed is the other way this fails late and
    # confusingly: the resolver exits 0, hands back a complete-looking environment, and the failure
    # surfaces minutes later inside a relay driver as a stall. Say it here, at the moment the name
    # is resolved, where the operator can still choose a different profile. A comment rather than a
    # refusal — the caller may be preparing an environment for another machine.
    cli = _cli_for(xyz_root, spec["lane"], spec["prefix"])
    if not shutil.which(cli):
        lines.insert(1, f"# resolve-profile: WARNING — {harness} harness selected, but its CLI "
                        f"{cli!r} is NOT on PATH; this turn will not run on this machine")
    tick = os.path.join(xyz_root, "bin", "tick")
    if os.path.isfile(tick):
        lines.append(f"export TICK={_sh_quote(tick)}")
    return ("\n".join(lines) + "\n", 0)


def emit_list(xyz_root: str) -> int:
    lane_map = lanes(xyz_root)
    profiles = load_profiles()
    if not profiles:
        print(f"No profiles defined in {get_device_config_path()}.")
        print()
        print("Add a 'profiles' block, for example:")
        print('  "profiles": {')
        print('    "glm 5.3 max":  { "harness": "commandcode", "gateway": "self",')
        print('                      "model": "zai-org/glm-5.3", "effort": "max" },')
        print('    "qwen 3.8 max": { "harness": "deepseek", "gateway": "openrouter",')
        print('                      "model": "qwen/qwen3.8-max" }')
        print("  }")
        print()
        print(f"Routable harnesses: {', '.join(sorted(lane_map)) or '(none derived)'}")
        return 0
    for key in sorted(profiles):
        body = profiles[key]
        gw = body.get("gateway")
        route = f"{body.get('harness')} -> {body.get('model')}" if gw == SELF_ROUTED \
            else f"{body.get('harness')} -> {gw} -> {body.get('model')}"
        extra = f"  [effort {body['effort']}]" if body.get("effort") else ""
        problems = validate_profile(key, body, lane_map)
        print(f"  {key:<18} {route}{extra}")
        for p in problems:
            print(f"  {'':<18} PROBLEM: {p}")
    return 0


def emit_explain(res: Dict[str, Any]) -> int:
    print(f"query:   {res['query']!r}")
    print(f"tier:    {res['tier']}  ({res['why']})")
    if res["profile"]:
        print(f"profile: {res['profile']!r}")
    print(f"harness: {res['harness']}")
    gw = res["gateway"]
    print(f"gateway: {gw}" + ("   (the harness is its own router)" if gw == SELF_ROUTED else ""))
    print(f"model:   {res['model']}")
    if res["effort"]:
        print(f"effort:  {res['effort']}")
    for p in res["problems"]:
        print(f"PROBLEM: {p}")
    return 1 if res["problems"] else 0


def main(argv: List[str]) -> int:
    xyz_root = os.environ.get("XYZ_ROOT") or os.path.dirname(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

    args = [a for a in argv if a not in ("--env", "--list", "--explain", "--json")]
    mode = ("--list" if "--list" in argv else
            "--explain" if "--explain" in argv else
            "--json" if "--json" in argv else "--env")

    if "-h" in argv or "--help" in argv:
        print("usage: resolve-profile.sh [<name>] [--env|--list|--explain|--json]")
        print()
        print("  --env      print the export block for <name>   (default)")
        print("  --list     every profile and what it resolves to")
        print("  --explain  which tier answered, and why")
        print("  --json     the full resolution as JSON")
        return 0

    if mode == "--list":
        return emit_list(xyz_root)

    name = args[0] if args else None
    res = resolve(name, xyz_root)

    if mode == "--explain":
        return emit_explain(res)
    if mode == "--json":
        out = {k: v for k, v in res.items() if k != "lanes"}
        print(json.dumps(out, indent=2, default=str))
        return 1 if res["problems"] else 0

    text, rc = emit_env(res, xyz_root)
    sys.stdout.write(text)
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
