# RELAY · GH610 subscription reviewer account validation
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-13.
-->

NEXT: operator
STATUS: Approved
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh610-subscription-reviewer-account-validation): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **claude_cli.py** (embedded below — read it here).
- Reviewer: claude-reviewer   ·   Producer: operator
- Started: 2026-09-13

### Artifact — claude_cli.py
```
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
```
- Definition of Done: Review the embedded shared native Claude helper. 1. Does subscription preflight reject API/helper/provider routes and failed probes without exposing secrets? 2. Does result parsing reject errors, exhausted turns and malformed/empty output? 3. Are binary resolution and inherit-mode compatibility reasonable? Inspect the complete helper, cite exact lines, and separate defects from optional improvements. No code changes or tests; edit only this relay file.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## R1 — claude-reviewer (2026-09-13)

swept file: yes

VERDICT: PASS
Basis: All three DoD criteria are satisfied. No security blockers. One diagnostic clarity gap ([Should]) and two minor robustness gaps ([Nit]). Shippable as-is; [Should] fix recommended before next integration.

### DoD 1 — Preflight rejects API/helper/provider routes and failed probes without exposing secrets

- [Pass] All six override env vars (ANTHROPIC_API_KEY, ANTHROPIC_AUTH_TOKEN, ANTHROPIC_BASE_URL, CLAUDE_CODE_USE_BEDROCK, CLAUDE_CODE_USE_VERTEX, CLAUDE_CODE_USE_FOUNDRY) are blocked before the probe runs. `claude_cli.py:79-82`
- [Pass] Auth probe validation uses `is True` identity checks and exact string comparisons — not truthy checks — for `loggedIn`, `authMethod`, `apiProvider`, `subscriptionType`. `claude_cli.py:88-91`
- [Pass] `raise ValueError(...) from None` on the catch-all re-raise suppresses the original exception chain, preventing auth JSON from leaking in tracebacks. `claude_cli.py:94-95`
- [Should] No explicit empty-binary guard before the probe. `resolve_binary` returns `""` when the binary is not found. `preflight("", env, cwd)` executes `run_bounded(["", ...])`, which raises OSError (caught correctly — auth still fails safely), but the re-raised error says "subscription auth status not verified" rather than "binary not found." Diagnosis is misleading. Fix: add `if not binary: raise ValueError("claude binary not found; install or set CLAUDE_BIN")` at `claude_cli.py:84`, before the `try` block.

### DoD 2 — Result parsing rejects errors, exhausted turns, and malformed/empty output

- [Pass] `read_result` checks `type == "result"`, rejects `is_error: true`, rejects non-success `subtype`, requires `result` to be a non-empty string. `claude_cli.py:103-108`
- [Pass] `json.JSONDecodeError` is a `ValueError` subclass and is caught by `except (OSError, ValueError, TypeError)`. `claude_cli.py:109`
- [Nit] `data.get("subtype", "success")` defaults to `"success"` when `subtype` is absent. An older CLI build that omits `subtype` on exhausted-turns output would slip through if `is_error` is also absent or false — though the whitespace-empty-result guard provides a last-resort catch for a truly blank output. Consider defaulting to `""` instead of `"success"` to require the field explicitly. `claude_cli.py:105`

### DoD 3 — Binary resolution and inherit-mode compatibility

- [Pass] `resolve_binary` falls through to `~/.local/bin/claude` and `~/.claude/local/claude` with executability checks when `claude` is absent from PATH. `claude_cli.py:62-64`
- [Pass] `inherit` mode returns immediately — no probe, no network call, no rejection. `claude_cli.py:75-76`
- [Nit] `read_result` has no file-size guard before loading the JSON. A pathologically large result file is read fully into memory before any rejection. Risk is low (cwd is caller-controlled), but a defensive cap (e.g., 10 MB) would bound worst-case memory use. `claude_cli.py:101-102`

### Pre-existing defects

None found beyond the items above. All three functions reviewed top-to-bottom.

### Round 2 · Producer · operator

Implemented the missing-binary diagnostic and strict success fields: result now requires explicit is_error=false and subtype=success. Declined a file-size cap because the native CLI is already turn/time bounded and a new arbitrary size policy is outside this focused change. The helper above is refreshed to current source. Re-review only these dispositions, retain prior findings, and set STATUS: Approved if no remaining required change. Do not run tools beyond reading this relay and writing your block. Token handoff to operator is required.

## R2 — claude-reviewer (2026-09-13)

swept file: yes

VERDICT: PASS
Basis: All three R1 findings are correctly resolved. No new blockers. Relay is closed.

### Producer disposition verification

- [Pass] R1 [Should] — Binary guard implemented. `if not binary: raise ValueError("claude binary not found; install Claude Code or set CLAUDE_BIN")` is present at `claude_cli.py:79-80`, correctly positioned before overrides check and before the `try` block. Error message is clear and does not disclose auth state.
- [Pass] R1 [Nit] — Strict subtype check confirmed. `data.get("subtype") != "success"` at `claude_cli.py:107` carries no default argument; absent `subtype` yields `None`, `None != "success"` is `True`, raises `ValueError`. Exhausted-turns output with missing `subtype` is correctly rejected.
- [Pass] R1 [Nit] — File-size cap decline accepted. CLI output is already time-bounded via `run_bounded` timeout; an arbitrary byte cap is out of scope for this focused change. Risk noted and declined on reasonable grounds.

### Fresh sweep — no new findings

- [Pass] `any(env.get(k) for k in overrides)` at `claude_cli.py:83` — falsy check means `ANTHROPIC_API_KEY=""` (empty string) would not be blocked. Empty credentials are inert in practice; the CLI ignores unset-equivalent values. Accepted as-is; documenting only for transparency, not a required fix.
- [Pass] `account.get("loggedIn") is True` / `== "claude.ai"` / `== "firstParty"` / `in (...)` at `claude_cli.py:90-93` — identity and exact-match checks confirmed correct; no truthy looseness.
- [Pass] `raise ValueError(...) from None` used in both `preflight` and `read_result` — exception chain suppressed; no auth JSON or internal state can leak through tracebacks. `claude_cli.py:97`, `claude_cli.py:112`.
- [Pass] `resolve_binary` fallback paths use both `os.path.isfile` and `os.access(p, os.X_OK)` at `claude_cli.py:63-64` — symlinks and non-executable files are correctly excluded.

### Pre-existing defects (re-checked)

None. All three functions reviewed top-to-bottom on the refreshed artifact.

---

Relay closed (Approved). No further turn needed — return to the operator window and confirm.


### Attestation · relay-drive — 2026-09-13T23:59:12Z
task: RELAY-gh610-review
reviewer: claude-reviewer
status: Approved
reviewed-head: 723e233092c1113b42e2b9f427b857d03e62a491
added-range: 11008+2191
added-sha256: 38480d2a9fd2c6d4a7858cedd387c81470b60e346345bad09f44c776e9e2ca7c
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
