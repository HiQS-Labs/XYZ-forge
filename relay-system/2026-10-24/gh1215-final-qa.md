# RELAY · GH-1215 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-24.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

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
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-1215-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **code.diff** (embedded below — the full code diff of branch `feat/XYZ-forge-gh1215-kimi-relay-worker-2026-10-24` vs `origin/development` for `relay-automation/ utils/ skills/ test/`, at HEAD `287d4bf6`). The files are also on disk in this worktree.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-24

### Artifact — code.diff
````
diff --git a/relay-automation/kimi-turn.sh b/relay-automation/kimi-turn.sh
new file mode 100755
index 00000000..2f3a65b7
--- /dev/null
+++ b/relay-automation/kimi-turn.sh
@@ -0,0 +1,14 @@
+#!/usr/bin/env bash
+# GH-148: Python is the only implementation for this entry point.
+set -euo pipefail
+
+if ! command -v python3 >/dev/null 2>&1 \
+   || ! python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,8) else 1)' 2>/dev/null; then
+  echo "kimi-turn: python3 >= 3.8 is required" >&2
+  exit 5
+fi
+
+xyz_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
+export XYZ_ROOT="$xyz_root"
+export PYTHONPATH="$xyz_root/utils/py${PYTHONPATH:+:$PYTHONPATH}"
+exec python3 "$xyz_root/utils/py/kimi-turn.py" "$@"
diff --git a/relay-automation/marathon-agent.sh b/relay-automation/marathon-agent.sh
index 183663ff..e51d5601 100755
--- a/relay-automation/marathon-agent.sh
+++ b/relay-automation/marathon-agent.sh
@@ -18,6 +18,7 @@ set -euo pipefail
 #   SMALLCODE_AGENT   — agent id that routes to smallcode-turn.sh (SmallCode)
 #   COMMANDCODE_AGENT — agent id that routes to commandcode-turn.sh (Command Code / cmd)
 #   DEEPSEEK_AGENT    — agent id that routes to deepseek-turn.sh (DeepSeek via dsh)
+#   KIMI_AGENT        — agent id that routes to kimi-turn.sh (Kimi Code CLI; GH-1215)
 # Peer threading (set by marathon-drive.sh — prevents "release to literal role-string" failure):
 #   MARATHON_BUILDER  — builder agent id; when RELAY_AGENT matches this, RELAY_PEER = MARATHON_REVIEWER
 #   MARATHON_REVIEWER — reviewer agent id; when RELAY_AGENT is the reviewer, RELAY_PEER = MARATHON_BUILDER
@@ -45,6 +46,7 @@ smallcode_agent="${SMALLCODE_AGENT:-}"
 # route_agent() alone would have shipped a lane that still could not dispatch.
 commandcode_agent="${COMMANDCODE_AGENT:-}"
 deepseek_agent="${DEEPSEEK_AGENT:-}"
+kimi_agent="${KIMI_AGENT:-}"
 
 # GH-368: a builder and reviewer may share the agy lane (for example `agy,agy-qa`).
 # Route by exact membership rather than treating AGY_AGENT as one overwrite-prone actor slot.
@@ -102,7 +104,11 @@ case "$me" in
     [[ -n "$deepseek_agent" ]] || die "RELAY_AGENT='$me' matched an empty DEEPSEEK_AGENT — set DEEPSEEK_AGENT"
     exec "$HERE/deepseek-turn.sh"
     ;;
+  "$kimi_agent")
+    [[ -n "$kimi_agent" ]] || die "RELAY_AGENT='$me' matched an empty KIMI_AGENT — set KIMI_AGENT"
+    exec "$HERE/kimi-turn.sh"
+    ;;
   *)
-    die "unknown agent '$me'; set CLAUDE_AGENT/CODEX_AGENT/AGY_AGENT/AIDER_AGENT/PI_AGENT/SMALLCODE_AGENT/COMMANDCODE_AGENT/DEEPSEEK_AGENT to map it to a shim"
+    die "unknown agent '$me'; set CLAUDE_AGENT/CODEX_AGENT/AGY_AGENT/AIDER_AGENT/PI_AGENT/SMALLCODE_AGENT/COMMANDCODE_AGENT/DEEPSEEK_AGENT/KIMI_AGENT to map it to a shim"
     ;;
 esac
diff --git a/skills/1-hourly/relay-xyz/SKILL.md b/skills/1-hourly/relay-xyz/SKILL.md
index 407ba175..70002a34 100644
--- a/skills/1-hourly/relay-xyz/SKILL.md
+++ b/skills/1-hourly/relay-xyz/SKILL.md
@@ -37,7 +37,7 @@ bash "$L" --check
 ```
 
 That locator resolves the harness from wherever your CWD is and reports which workers
-(tick/codex/agy/cmd/dsh) are on PATH. See
+(tick/codex/agy/cmd/dsh/kimi) are on PATH. See
 [Preconditions](#preconditions--locate-the-harness-bundled-locator-never-hardcode-a-path) below for the
 full env-exporting form (`eval "$(... --env)"` + `cd`) that every recipe in this doc assumes has already
 run.
@@ -185,9 +185,9 @@ for L in "${XYZ_HARNESS:+$XYZ_HARNESS/skills/1-hourly/relay-xyz/find-harness.sh}
 done
 [ -x "$L" ] || { echo "relay-xyz: locator not found — set XYZ_HARNESS to your XYZ-forge clone"; exit 1; }
 
-eval "$("$L" --env)"   # exports HARNESS, TICK, TICK_REPO_ROOT, RELAY_HAS_{TICK,CODEX,AGY,COMMANDCODE,DEEPSEEK}
+eval "$("$L" --env)"   # exports HARNESS, TICK, TICK_REPO_ROOT, RELAY_HAS_{TICK,CODEX,AGY,COMMANDCODE,DEEPSEEK,KIMI}
 cd "$HARNESS"
-"$L" --check           # prints: harness path + which Path-A workers (tick/codex/agy/cmd/dsh) are on PATH
+"$L" --check           # prints: harness path + which Path-A workers (tick/codex/agy/cmd/dsh/kimi) are on PATH
 ```
 
 After this, `$HARNESS` is the harness repo root, `$TICK` is the absolute `bin/tick`, and
@@ -366,6 +366,7 @@ exists, or when you want a one-off that is not worth naming.
 | agy | `"$RELAY_HAS_AGY" = 1` | `agy` | `AGY_AGENT=agy ALLOW_PATHS="$ARTIFACT" AGY_LOG="${TMPDIR:-/tmp}/agy-turn-$$.log"` | `relay-automation/agy-turn.sh` | `${TMPDIR:-/tmp}/agy-turn-$$.log` |
 | Commandcode | `"$RELAY_HAS_COMMANDCODE" = 1` | `commandcode` | `COMMANDCODE_AGENT=commandcode ALLOW_PATHS="$ARTIFACT" COMMANDCODE_LOG="${TMPDIR:-/tmp}/commandcode-turn-$$.log"` | `relay-automation/commandcode-turn.sh` | `${TMPDIR:-/tmp}/commandcode-turn-$$.log` |
 | DeepSeek | `"$RELAY_HAS_DEEPSEEK" = 1` | `deepseek` | `DEEPSEEK_AGENT=deepseek ALLOW_PATHS="$ARTIFACT" DEEPSEEK_LOG="${TMPDIR:-/tmp}/deepseek-turn-$$.log"` | `relay-automation/deepseek-turn.sh` | `${TMPDIR:-/tmp}/deepseek-turn-$$.log` |
+| Kimi | `"$RELAY_HAS_KIMI" = 1` | `kimi` | `KIMI_AGENT=kimi ALLOW_PATHS="$ARTIFACT" KIMI_LOG="${TMPDIR:-/tmp}/kimi-turn-$$.log"` | `relay-automation/kimi-turn.sh` | `${TMPDIR:-/tmp}/kimi-turn-$$.log` |
 
 **Model selection per worker** (GH-346) — the one lookup that used to mean reading each shim's
 source. `RELAY_HAS_*` is set by `find-harness.sh --env`; every worker below also honors
@@ -377,6 +378,7 @@ source. `RELAY_HAS_*` is set by `find-harness.sh --env`; every worker below also
 | agy | `AGY_MODEL` | agy CLI's own | validated against `agy models` — an unlisted id fails fast rather than falling back |
 | Commandcode | `COMMANDCODE_MODEL` | `meta/muse-spark-1.2-contributor` | `cmd --list-models` for the live catalog (GLM, Qwen, DeepSeek all reachable here) |
 | DeepSeek | `DEEPSEEK_MODEL` | `deepseek/deepseek-v4-pro` | accepts a colloquial alias (`"deepseek v4 pro"`); also `DEEPSEEK_PROVIDER` (`openrouter`\|`deepseek`\|`alibaba`) selecting the endpoint and its key variable. An unrecognised value REFUSES the turn (it used to fall through to DeepSeek silently). `alibaba` is the Alibaba Token Plan, which serves Qwen under bare ids (`qwen3.8-max`, not `qwen/...`) and reads its key from `ALIBABA_TOKEN_PLAN_API_KEY` or, failing that, the file named by `ALIBABA_TOKEN_PLAN_API_KEY_FILE`. |
+| Kimi | `KIMI_MODEL` | `kimi-code/k3.1-pro` | Kimi Code CLI on the operator's Kimi plan, not OpenRouter (GH-1215); other ids are the `[models]` in `~/.kimi-code/config.toml` (`k3.1-pro-highspeed`, `k3`, `kimi-for-coding`). Runs `kimi -p` headless, which edits without asking; do not put `--yolo`/`--auto` in `KIMI_FLAGS` (the CLI refuses them with `-p`). No reasoning-effort flag. `KIMI_BIN` defaults to `kimi` on PATH, then `~/.kimi-code/bin/kimi`. |
 | Aider | `AIDER_MODEL` | `openrouter/anthropic/claude-sonnet-5`, or `openai/agents-a1` when `AIDER_OPENAI_API_BASE` is set | force `AIDER_FLAGS=--edit-format diff` on GLM |
 | Claude | `CLAUDE_MODEL` | `claude-sonnet-4-6` | Explicit operator choice, never a session default; see [subscription setup](https://github.com/HiQS-Labs/XYZ-forge/blob/development/relay-automation/README.md#claude-subscription-mode) |
 | Pi | `PI_MODEL` | **none — required** | refuses to guess (GH-295) |
diff --git a/skills/1-hourly/relay-xyz/find-harness.sh b/skills/1-hourly/relay-xyz/find-harness.sh
index c470462d..cdeacba7 100755
--- a/skills/1-hourly/relay-xyz/find-harness.sh
+++ b/skills/1-hourly/relay-xyz/find-harness.sh
@@ -372,6 +372,16 @@ if [ -f "$HARNESS/utils/py/deepseek-turn.py" ] && command -v python3 >/dev/null
   fi
 fi
 
+# GH-1215: Kimi Code's installer puts `kimi` in ~/.kimi-code/bin and edits only ~/.zshrc, so ask the
+# shim's own rule (KIMI_BIN, PATH, installer path) rather than PATH alone — the GH-393 parity lesson.
+KIMI_PATH=""
+if [ -f "$HARNESS/utils/py/kimi-turn.py" ] && command -v python3 >/dev/null 2>&1; then
+  _kimi_out="$(python3 "$HARNESS/utils/py/kimi-turn.py" --print-bin 2>/dev/null || true)"
+  if [ -n "$_kimi_out" ] && [ -x "$_kimi_out" ]; then
+    KIMI_PATH="$_kimi_out"
+  fi
+fi
+
 HAS_DEEPSEEK=0
 if [ -n "$DEEPSEEK_PATH" ] && { [ -n "${OPENROUTER_API_KEY:-}" ] || [ -n "${DEEPSEEK_API_KEY:-}" ]; }; then
   HAS_DEEPSEEK=1
@@ -391,11 +401,13 @@ case "$ACTION" in
     [ -n "$AGY_PATH" ]   && printf 'export AGY_BIN=%q\n'    "$AGY_PATH"
     [ -n "$COMMANDCODE_PATH" ] && printf 'export COMMANDCODE_BIN=%q\n' "$COMMANDCODE_PATH"
     [ -n "$DEEPSEEK_PATH" ]    && printf 'export DEEPSEEK_BIN=%q\n'    "$DEEPSEEK_PATH"
+    [ -n "$KIMI_PATH" ]        && printf 'export KIMI_BIN=%q\n'        "$KIMI_PATH"
     printf 'export RELAY_HAS_TICK=%s\n'  "$(_flag "$TICK")"
     printf 'export RELAY_HAS_CODEX=%s\n' "$(_flag "$CODEX_PATH")"
     printf 'export RELAY_HAS_AGY=%s\n'   "$(_flag "$AGY_PATH")"
     printf 'export RELAY_HAS_COMMANDCODE=%s\n' "$(_flag "$COMMANDCODE_PATH")"
     printf 'export RELAY_HAS_DEEPSEEK=%s\n'    "$HAS_DEEPSEEK"
+    printf 'export RELAY_HAS_KIMI=%s\n'        "$(_flag "$KIMI_PATH")"
     printf 'export XYZ_VENDORED=%s\n'    "$VENDORED"
     [ -n "$CALLER_ROOT" ]     && printf 'export XYZ_CALLER_ROOT=%q\n'     "$CALLER_ROOT"
     [ -n "$VENDORED_STATUS" ] && printf 'export XYZ_VENDORED_STATUS=%q\n' "$VENDORED_STATUS"
@@ -455,6 +467,7 @@ case "$ACTION" in
     mark "$AGY_PATH"   "agy CLI   (Path A worker)"
     mark "$COMMANDCODE_PATH" "cmd CLI   (Path A worker, Command Code)"
     mark "$DEEPSEEK_PATH"    "dsh CLI   (Path A worker, DeepSeek)"
+    mark "$KIMI_PATH"        "kimi CLI  (Path A worker, Kimi Code)"
     if [ -z "$CODEX_PATH" ] && [ -z "$AGY_PATH" ]; then
       echo "  !   no cross-model headless worker on PATH — only Path B (all-Claude poll) is available"
     fi
diff --git a/test/gh346-gateway-allowlists.sh b/test/gh346-gateway-allowlists.sh
index 652b8b9e..bb2299d6 100755
--- a/test/gh346-gateway-allowlists.sh
+++ b/test/gh346-gateway-allowlists.sh
@@ -86,7 +86,7 @@ lane_env_var() {
   case "$1" in
     claude) echo CLAUDE_AGENT ;; codex) echo CODEX_AGENT ;; agy) echo AGY_AGENT ;;
     aider) echo AIDER_AGENT ;; pi) echo PI_AGENT ;; smallcode) echo SMALLCODE_AGENT ;;
-    commandcode) echo COMMANDCODE_AGENT ;; deepseek) echo DEEPSEEK_AGENT ;;
+    commandcode) echo COMMANDCODE_AGENT ;; deepseek) echo DEEPSEEK_AGENT ;; kimi) echo KIMI_AGENT ;;
   esac
 }
 
@@ -179,7 +179,7 @@ fi
 
 # the two lanes GH-346 added must now get past BOTH route_agent (#2) and _probe_agent_bin (#4).
 # Skipped, not failed, where the lane's tooling is genuinely absent on this host.
-for lane in commandcode deepseek; do
+for lane in commandcode deepseek kimi; do
   rc="$(drive_rc "$lane")"
   if drive_locked_out; then
     echo "  SKIP: driver lock held — '$lane' routing not evaluated"
@@ -274,7 +274,7 @@ fi
 # #9 is not cosmetic: without it, a COMMANDCODE_AGENT left in the parent shell survives into a run
 # that never asked for that lane.
 # ------------------------------------------------------------------------------------------------
-for lane in commandcode deepseek; do
+for lane in commandcode deepseek kimi; do
   upper="$(printf '%s' "$lane" | tr '[:lower:]' '[:upper:]')"
   if grep -q "\"${upper}_AGENT\"" "$ROOT/utils/py/gate_env.py"; then
     pass "#8 gate_env.py classifies ${upper}_AGENT"
@@ -291,7 +291,7 @@ done
 scrub="$(sed -n '/GATE_SCRUBBED_ENV = (/,/^    )/p' "$ROOT/utils/py/marathon_drive.py")"
 for lane in $LANES; do
   upper="$(printf '%s' "$lane" | tr '[:lower:]' '[:upper:]')"
-  case "$lane" in claude|codex|agy|aider|pi|smallcode|commandcode|deepseek) ;; *) continue ;; esac
+  case "$lane" in claude|codex|agy|aider|pi|smallcode|commandcode|deepseek|kimi) ;; *) continue ;; esac
   if grep -q "\"${upper}_AGENT\"" <<<"$scrub"; then
     pass "#10 GATE_SCRUBBED_ENV includes ${upper}_AGENT"
   else
diff --git a/utils/py/gate_env.py b/utils/py/gate_env.py
index c80edc96..239ff0a1 100644
--- a/utils/py/gate_env.py
+++ b/utils/py/gate_env.py
@@ -119,6 +119,7 @@ HARNESS_ENV = {
     # argument for generating this surface rather than curating it (issue #346, proposal B).
     "COMMANDCODE_AGENT": (SCRUB, "See CLAUDE_AGENT."),
     "DEEPSEEK_AGENT": (SCRUB, "See CLAUDE_AGENT."),
+    "KIMI_AGENT": (SCRUB, "See CLAUDE_AGENT."),
     "RELAY_TOOL_MODE": (SCRUB, "Turn tool mode (standard vs programmatic); suites set this per-invocation."),
     "XYZ_TOOL_MODE": (SCRUB, "Harness tool execution mode; suites set this per-invocation."),
     # ── PASS: load-bearing for the gate or for the drivers a suite legitimately spawns ─────────────
diff --git a/utils/py/kimi-turn.py b/utils/py/kimi-turn.py
new file mode 100755
index 00000000..0e76d279
--- /dev/null
+++ b/utils/py/kimi-turn.py
@@ -0,0 +1,238 @@
+#!/usr/bin/env python3
+"""kimi-turn.py (GH-1215) — relay turn adapter for the Kimi Code CLI (`kimi`).
+
+Modeled on muse-turn.py (GH-518): Python is the only implementation, the Bash file is a thin entry
+point, and containment/enforcement stay in RelayTurnLib rather than being re-derived here.
+
+Why a native shim at all: Kimi K3.1 already reached the relay through aider-turn.sh + OpenRouter
+(HiQS-Labs/XYZ-CLIO#12), but Aider's whole-file edit format broke relay-block validation once
+(exit 8) and that route spends OpenRouter credit rather than the operator's Kimi plan.
+
+Three CLI facts shape this file, all measured against Kimi Code CLI 2.3.1 rather than taken from
+documentation:
+
+  - `kimi -p "<prompt>"` is the headless mode and already edits files and runs Bash without asking.
+    `--yolo` and `--auto` are REFUSED alongside `-p` ("Cannot combine --prompt with --yolo"), so no
+    approval flag is passed and KIMI_FLAGS must not carry one.
+  - There is no prompt-file or stdin mode (`-p -` takes `-` as the prompt), so the turn prompt rides
+    in argv, unlike muse's --prompt-file. A relay prompt is a few KB against macOS's 1 MB ARG_MAX; an
+    E2BIG launch failure lands in the generic launch handler below as exit 5.
+  - `--output-format stream-json` writes one JSON object per line. That is what lets the empty-output
+    guard tell model output from the CLI's own version and resume-hint events.
+"""
+import json
+import os
+import shlex
+import shutil
+import subprocess
+import sys
+
+from rtl import (RelayTurnLib, claim_task_or_exit, rtl_default_log, resolve_turn_root,
+                 rtl_run_bounded)
+from turn_diagnostics import TurnDiagnostics, TERMINATION_WALL_CAP
+
+DEFAULT_MODEL = "kimi-code/k3.1-pro"
+# Where the Kimi Code installer puts the binary. Its PATH edit lands in ~/.zshrc, which a
+# non-interactive shell (launchd, a driven turn) never reads, so a bare `kimi` may not resolve.
+INSTALLER_BIN = os.path.join("~", ".kimi-code", "bin", "kimi")
+
+
+def die(msg):
+    print(f"kimi-turn: {msg}", file=sys.stderr)
+    sys.exit(2)
+
+
+def default_kimi_bin():
+    """KIMI_BIN, else `kimi` on PATH, else the installer's location. find-harness.sh asks this."""
+    explicit = os.environ.get("KIMI_BIN", "").strip()
+    if explicit:
+        return explicit
+    return shutil.which("kimi") or os.path.expanduser(INSTALLER_BIN)
+
+
+def has_model_output(log_path):
+    """True when the stream-json log holds at least one assistant message or tool call.
+
+    Meta events (`system.version`, `session.resume_hint`) and any non-JSON chatter do not count:
+    the CLI emits those even when the model produced nothing, which is the GH-178 / GH-518 trap of
+    a log that is non-empty only because the CLI introduced itself.
+    """
+    try:
+        with open(log_path) as log_f:
+            for line in log_f:
+                try:
+                    event = json.loads(line)
+                except ValueError:
+                    continue
+                if not isinstance(event, dict) or event.get("role") != "assistant":
+                    continue
+                content = event.get("content")
+                if (isinstance(content, str) and content.strip()) or event.get("tool_calls"):
+                    return True
+    except OSError:
+        pass
+    return False
+
+
+def main():
+    if "--print-bin" in sys.argv[1:]:
+        print(default_kimi_bin())
+        sys.exit(0)
+    if "-h" in sys.argv[1:] or "--help" in sys.argv[1:]:
+        print("Usage: kimi-turn.py [--print-bin]")
+        print("Required environment variables: RELAY_AGENT, RELAY_FILE, KIMI_AGENT")
+        print("Optional: RELAY_TASK, RELAY_PEER, ALLOW_PATHS, KIMI_BIN, KIMI_MODEL, KIMI_FLAGS,")
+        print("          KIMI_LOG, KIMI_TURN_ROOT, RELAY_TURN_TIMEOUT_S")
+        sys.exit(0)
+
+    xyz_root = os.environ.get(
+        "XYZ_ROOT",
+        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
+    root = resolve_turn_root(os.environ.get("KIMI_TURN_ROOT"), xyz_root)
+
+    me = os.environ.get("RELAY_AGENT", "")
+    f = os.environ.get("RELAY_FILE", "")
+    t = os.environ.get("RELAY_TASK", "RELAY-TURN")
+    kimi_agent = os.environ.get("KIMI_AGENT", "")
+
+    if not me:
+        die("RELAY_AGENT required")
+    if not f:
+        die("RELAY_FILE required")
+    if not kimi_agent:
+        die("KIMI_AGENT required")
+
+    if me != kimi_agent:
+        print(f"kimi-turn: actor {me} is not the Kimi agent ({kimi_agent}) — deferring (window-driven)",
+              file=sys.stderr)
+        sys.exit(0)
+
+    kimi_bin = default_kimi_bin()
+    kimi_model = os.environ.get("KIMI_MODEL", "").strip() or DEFAULT_MODEL
+    kimi_flags = shlex.split(os.environ.get("KIMI_FLAGS", ""))
+
+    allow_paths = os.environ.get("ALLOW_PATHS", "")
+    peer = os.environ.get("RELAY_PEER", "")
+
+    kimi_log = os.environ.get("KIMI_LOG") or rtl_default_log(root, "kimi-turn", t)
+    os.environ["RTL_LOG"] = kimi_log
+
+    rtl = RelayTurnLib(root, xyz_root, f, allow_paths)
+
+    prompt = rtl.turn_prompt(me, t, peer)
+    tick_repo_root = os.environ.get("TICK_REPO_ROOT", root)
+    drift_brief = rtl.drift_brief(me, tick_repo_root)
+    if drift_brief:
+        prompt = drift_brief + "\n" + prompt
+
+    tick_repo_root, _tick_bin = claim_task_or_exit(
+        root, xyz_root, f, allow_paths, t, me, "kimi-turn")
+
+    rtl.before()
+
+    turn_timeout = int(os.environ.get("RELAY_TURN_TIMEOUT_S", 900))
+
+    bounded_rc = 0
+    wt = ""
+    run_cwd = root
+    kimi_env = dict(os.environ)
+    kimi_env["TICK_REPO_ROOT"] = tick_repo_root
+
+    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
+        wt = rtl.worktree_begin()
+        if wt:
+            run_cwd = wt
+            print(f"kimi-turn: worktree isolation ON ({wt})", file=sys.stderr)
+        else:
+            print("kimi-turn: worktree isolation requested but `git worktree add` failed — failing turn",
+                  file=sys.stderr)
+            bounded_rc = 5
+
+    rtl.apply_reviewer_turn_env(kimi_env, run_cwd, me)
+
+    # Kimi's workspace is its cwd, so the isolation worktree (when on) is what bounds its tools.
+    # Containment does not depend on that: the path allowlist, commit guard and worktree isolation
+    # in RelayTurnLib are what bound the turn.
+    cmd = [kimi_bin, "-p", prompt, "-m", kimi_model, "--output-format", "stream-json"] + kimi_flags
+
+    diag = TurnDiagnostics(worktree=run_cwd)
+    if bounded_rc == 0:
+        diag.start()
+        try:
+            with open(kimi_log, "a") as log_f:
+                # rtl_run_bounded, not subprocess.run(timeout=...): it kills the whole process group
+                # on timeout, so Kimi's Bash children cannot outlive the turn (see muse-turn.py).
+                # Returns the child's status, or 7 on timeout.
+                bounded_rc = rtl_run_bounded(
+                    turn_timeout, cmd,
+                    cwd=run_cwd, env=kimi_env,
+                    stdout=log_f, stderr=subprocess.STDOUT,
+                )
+        except FileNotFoundError:
+            print(f"kimi-turn: kimi binary not found at {kimi_bin} "
+                  f"(set KIMI_BIN, or install the Kimi Code CLI)", file=sys.stderr)
+            bounded_rc = 5
+        except Exception as exc:
+            print(f"kimi-turn: kimi launch failed: {exc}", file=sys.stderr)
+            bounded_rc = 5
+        finally:
+            diag.stop()
+
+    # GH-648 L6: record the observed timeout in the run log before containment cleanup can replace
+    # exit 7 with exit 6.
+    if bounded_rc == 7:
+        with open(kimi_log, "a") as log_f:
+            record = diag.emit_termination_record(TERMINATION_WALL_CAP, stream=log_f)
+        print(f"kimi-turn: kimi exceeded {turn_timeout}s wall-clock cap — killed [{record['reason']}]",
+              file=sys.stderr)
+        print(f"kimi-turn: timeout attribution: {record['detail']}", file=sys.stderr)
+
+    if wt:
+        off_lane = rtl.worktree_end(wt)
+        if off_lane:
+            print("kimi-turn: kimi made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)",
+                  file=sys.stderr)
+            bounded_rc = 6
+
+    if bounded_rc not in (0, 7):
+        print(f"kimi-turn: kimi failed (exit {bounded_rc})", file=sys.stderr)
+
+    # GH-178's empty-exit-0 failure mode: a turn with no assistant output is a failed turn.
+    if bounded_rc == 0 and not has_model_output(kimi_log):
+        print("kimi-turn: kimi exited 0 but produced NO model output (only CLI meta events) — "
+              "failing the turn.", file=sys.stderr)
+        bounded_rc = 5
+
+    rc = rtl.enforce(t, me, kimi_log, "kimi")
+
+    try:
+        from harness_turn_logger import HarnessTurnLogger
+        with HarnessTurnLogger(
+            harness_id="kimi",
+            shim="kimi-turn.py",
+            task_scope=t,
+            # The model actually dispatched (GH-346 Phase 0).
+            model_id=kimi_model,
+            # Kimi Code is its own router: it bills the operator's Kimi plan, not OpenRouter.
+            gateway=os.environ.get("KIMI_GATEWAY", "moonshot"),
+            cli_flags=["-p", "-m", kimi_model, "--output-format", "stream-json"] + kimi_flags,
+            repo_root=xyz_root,
+        ) as logger:
+            logger.exit_code = bounded_rc or rc
+    except Exception as _telemetry_exc:
+        print("kimi-turn: telemetry not recorded: %r" % (_telemetry_exc,), file=sys.stderr)
+
+    if rc == 6:
+        sys.exit(6)
+    if bounded_rc == 6:
+        sys.exit(6)
+    if bounded_rc == 7:
+        sys.exit(7)
+    if bounded_rc != 0:
+        sys.exit(5)
+
+    sys.exit(rc)
+
+
+if __name__ == "__main__":
+    main()
diff --git a/utils/py/marathon_drive.py b/utils/py/marathon_drive.py
index 180b0f9d..a218bebe 100644
--- a/utils/py/marathon_drive.py
+++ b/utils/py/marathon_drive.py
@@ -735,6 +735,8 @@ SMALLCODE_DEFAULT_BIN = os.path.join(
     os.path.expanduser("~"), "Documents", "GH Repos", "smallcode", "bin", "smallcode.js"
 )
 DEEPSEEK_DEFAULT_BIN = "/Users/noelsaw/Documents/GH Repos/deepseek-harness/apps/cli/lib/bin.js"
+# GH-1215: mirrors kimi-turn.py's INSTALLER_BIN (the Kimi Code installer's PATH edit is in ~/.zshrc).
+KIMI_DEFAULT_BIN = os.path.join(os.path.expanduser("~"), ".kimi-code", "bin", "kimi")
 
 def _probe_bin_or_file(candidates, role_label, agent_id, override_env):
     """Pass if ANY candidate resolves — on PATH, or as an existing file dispatched by interpreter.
@@ -806,6 +808,12 @@ def _probe_agent_bin(agent_id, role_label):
             [get_env("DEEPSEEK_BIN"), DEEPSEEK_DEFAULT_BIN, "dsh"],
             role_label, agent_id, "DEEPSEEK_BIN",
         )
+    elif agent_id.startswith("kimi"):
+        # GH-1215: mirrors kimi-turn.py's default_kimi_bin(): override, `kimi` on PATH, installer path.
+        _probe_bin_or_file(
+            [get_env("KIMI_BIN"), "kimi", KIMI_DEFAULT_BIN],
+            role_label, agent_id, "KIMI_BIN",
+        )
     else:
         # GH-346: the comment above used to STATE this invariant and nothing enforced it, so an id
         # route_agent accepted but this function had no branch for skipped preflight in silence —
@@ -1979,6 +1987,7 @@ def main():
     # asked for. Omitting the two new lanes here would have left exactly that hole open for them.
     os.environ["COMMANDCODE_AGENT"] = ""
     os.environ["DEEPSEEK_AGENT"] = ""
+    os.environ["KIMI_AGENT"] = ""
 
     def route_agent(agent_id):
         # GH-414 — BASH/PYTHON DIVERGENCE, deliberate and pinned. This router accepts `pi*`
@@ -2026,7 +2035,9 @@ def main():
         # is what made these two gateways accept-then-die.
         elif agent_id.startswith("commandcode"): os.environ["COMMANDCODE_AGENT"] = agent_id
         elif agent_id.startswith("deepseek"): os.environ["DEEPSEEK_AGENT"] = agent_id
-        else: die(f"agent '{agent_id}' not recognized — must start with claude/codex/agy/aider/pi/smallcode/commandcode/deepseek")
+        # GH-1215: builder lane only; the reviewer gate below stays codex/agy.
+        elif agent_id.startswith("kimi"): os.environ["KIMI_AGENT"] = agent_id
+        else: die(f"agent '{agent_id}' not recognized — must start with claude/codex/agy/aider/pi/smallcode/commandcode/deepseek/kimi")
         
     if args.builder == args.reviewer:
         _RESULT["reason"] = "builder-equals-reviewer"
@@ -2297,7 +2308,7 @@ relay-file: {rel_relay}
         "SMALLCODE_AGENT",
         # GH-346 Phase 2: TENTH copy. Kept in lockstep with gate_env.py's registry, which
         # test/gh441-gate-env-contract.sh compares against this literal.
-        "COMMANDCODE_AGENT", "DEEPSEEK_AGENT",
+        "COMMANDCODE_AGENT", "DEEPSEEK_AGENT", "KIMI_AGENT",
         "RELAY_TARGET_ROOT", "RELAY_TASK", "RELAY_WORKTREE_ISOLATION",
         "RELAY_TOOL_MODE", "XYZ_TOOL_MODE",
         "XYZ_HARNESS_CONTEXT", "XYZ_SESSION_ID",
@@ -3412,7 +3423,7 @@ APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delet
         # with no guard root — deepseek-turn.py:93 reads DEEPSEEK_TURN_ROOT, so a --target-root
         # deepseek turn was resolving containment against the harness clone, not the target.
         if args.target_root:
-            for _shim in ("CLAUDE", "CODEX", "AGY", "AIDER", "PI", "SMALLCODE", "COMMANDCODE", "DEEPSEEK"):
+            for _shim in ("CLAUDE", "CODEX", "AGY", "AIDER", "PI", "SMALLCODE", "COMMANDCODE", "DEEPSEEK", "KIMI"):
                 env2[f"{_shim}_TURN_ROOT"] = args.target_root
         return subprocess.run(cmd2, env=env2, cwd=root).returncode
 
diff --git a/utils/py/relay_drive.py b/utils/py/relay_drive.py
index 67666e05..0ef2cd13 100644
--- a/utils/py/relay_drive.py
+++ b/utils/py/relay_drive.py
@@ -153,6 +153,7 @@ def main():
             ("smallcode", "SMALLCODE", "smallcode-turn"),
             ("commandcode", "COMMANDCODE", "commandcode-turn"),
             ("deepseek", "DEEPSEEK", "deepseek-turn"),
+            ("kimi", "KIMI", "kimi-turn"),
         )
         for prefix, env_prefix, tool_name in shims:
             if actor.startswith(prefix):
````
- Definition of Done: every requirement R1-R7 in `PROJECT/2-WORKING/GH-1215-KIMI-RELAY-WORKER.md`
  is met by the code and backed by the evidence, the code matches the Codex-approved plan
  (`relay-system/2026-10-24/gh1215-plan-qa.md`), and nothing outside that scope slipped in.

### Context for the reviewer

**Operational envelope:** a local developer CLI adapter on one Mac. Grade against the stated
requirements and commensurate complexity. Do not ask for new test suites or gate machinery
(AGENTS.md *No new tests*, GH-831); a new `test/` file or `validate.sh` entry in the diff would be a
finding. Editing an existing suite to keep it truthful is allowed.

Read: the plan doc (Scope, Plan, Verification, Results), the embedded diff, the receipt
`TESTS-RESULTS/2026-10-24+GH-1215/live-smoke.md` and `provenance.jsonl`, and the first live Kimi
thread `relay-system/2026-10-24/gh1215-kimi-first-relay.md` (the R7 evidence, attested by the
driver). Compare `utils/py/kimi-turn.py` with `utils/py/muse-turn.py`.

Questions:

1. Is each of R1-R7 satisfied? Map each to a file:line in the diff and an evidence row in the receipt.
2. Do the code paths match the approved plan step by step? Flag any deviation, and any duplicate
   subsystem, parallel writer, or allowlist edit the plan did not name.
3. `has_model_output()` and the exit-code mapping: can a real turn be failed wrongly, or an empty
   turn pass? Is the `--print-bin` flag used by `find-harness.sh` consistent with what the shim
   actually runs?
4. The `marathon_drive.py` `_probe_agent_bin` branch probes `[KIMI_BIN, "kimi", KIMI_DEFAULT_BIN]`.
   Does that order mirror `default_kimi_bin()` exactly, and does the `KIMI_DEFAULT_BIN` literal
   match the shim's installer path?
5. Do the evidence claims hold (red control 62/63 then 63/0; nine suites green; R7 attested exit 0;
   re-fire exit 4)? Is the stated limit (lost stream-json transcript, false PATH comment from
   `resolve-profile.sh`) honestly recorded and acceptable for this scope?
6. Is the rating `55/30/50/70` and its rationale in the plan doc consistent with the evidence?
7. Flag anything over-built, under-built, or missing.

Write a verdict below. Set STATUS to Approved if it passes; otherwise leave it Open and hand back.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
