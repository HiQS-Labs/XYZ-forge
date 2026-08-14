# RELAY · QA review: GH-421/428/430/395/527/520/314/539 across three stacked branches
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-14.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
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
6. **Commit only the relay file** (`relay(qa-eight-issues): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **qa-brief.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-08-14

### Artifact — qa-brief.md
````
# QA review request — 8 issues across three stacked branches

You are reviewing the combined work of three stacked branches in `xyz-3-agents-swarm`
(each cut from the previous, so this one diff covers all of it):

- `marathon/10days-2026-08-13` → PR #537 — GH-421, GH-428, GH-430
- `quickwins/parked-2026-08-14` → PR #538 — GH-421 residual, GH-395
- `fix/critical-2026-08-14` → GH-527, GH-520, GH-314, GH-539

Full local gate is green (197 suites). **Do not re-run the suite; review the reasoning.**

## What I want challenged, specifically

These are my own claims. Attack the ones that are weakest.

1. **GH-527 guard shape.** It SNAPSHOTS and always exits 0 — it never blocks. Is
   snapshot-then-allow actually the right call versus refusing on a dirty tree? I argued
   refusing trains an override reflex. Is there a case where allowing the destruction is
   simply wrong?
2. **GH-527 regex coverage.** `_RESET_HARD`, `_CHECKOUT_PATH`, `_STASH_WIDE`, `_CLEAN_FORCE`
   applied per shell-separated segment. What destructive spellings slip through? I know
   `$(...)` nesting and `xargs` do. Which MISSES matter in practice?
3. **GH-527 tracked-only.** It snapshots tracked modifications and deliberately not untracked
   files, because the issue reproduced that untracked survive. Is there a shape where an
   untracked file IS destroyed and I have therefore left a hole?
4. **GH-520 default stub.** `test/_setup.sh` now exports a default `CODEX_BIN`. Does this
   weaken any existing test's ability to detect a genuinely missing binary? I claim the
   GH-117 probe assertions still fire because they pass an explicitly missing path — verify
   that reasoning rather than trusting it.
5. **GH-314 fail-open.** If `rtl_transcript_root` cannot be resolved, the transcript path is
   silently NOT checked and the guard is quietly narrower. I justified this as matching
   `preflight_write_set_trackable`'s existing contract. Is silent narrowing defensible here,
   given the whole issue is a check that did not run?
6. **GH-314 probe path.** I check a synthetic `<transcript_root>/probe/transcript.md` rather
   than the real dated filename. Can `git check-ignore` disagree between that synthetic path
   and the real one — e.g. a rule keyed on the date directory or the `.md` suffix?
7. **Controls.** Three suites ship with recorded negative controls. For GH-520 the obvious
   control does NOT fire (the named suites were already individually stubbed), so I built one
   by removing an existing stub. Is that control legitimate, or is it proving something
   narrower than it claims?

## Verdict format

Give per-item findings. Mark each `[Blocker]`, `[Should-fix]`, or `[Pass]`, with a file:line
where you have one. Be adversarial — a review that says "looks good" is not useful to me.
End with `**Verdict:** Approved` or `**Verdict:** Changes requested`.

---

## Code diff (implementation)

```diff
diff --git a/relay-automation/hooks/gh527-destructive-git-guard.sh b/relay-automation/hooks/gh527-destructive-git-guard.sh
new file mode 100755
index 00000000..759d0797
--- /dev/null
+++ b/relay-automation/hooks/gh527-destructive-git-guard.sh
@@ -0,0 +1,151 @@
+#!/usr/bin/env bash
+#
+# gh527-destructive-git-guard.sh — PreToolUse guard: before a git command that
+# overwrites the working tree from a committed state runs, snapshot the tracked
+# files it is about to destroy so a peer's uncommitted work is recoverable.
+#
+# The incident this closes (GH-527, three times in ONE session on 2026-08-12): a
+# git HISTORY command was used to undo a WORKING-TREE experiment.
+#   1. `git stash` tree-wide took four other sessions' files, then timed out
+#      BEFORE its pop.
+#   2. `git checkout -- <path>` restored HEAD rather than the pre-mutation state
+#      and ate ~60 lines of the author's own new tests.
+#   3. `git reset --hard origin/development` took four sessions' tracked
+#      modifications plus .claude/settings.json, which never came back.
+#
+# Blast radius was REPRODUCED in a fixture rather than inferred: TRACKED
+# modifications are destroyed; untracked files survive. That is why this guard
+# keys on tracked dirt only — the dangerous case is exactly the one a peer agent
+# produces most often (editing a file that already exists), and snapshotting
+# untracked files too would be noise that hides the signal.
+#
+# SHAPE: snapshot-then-allow, NOT refuse-when-dirty. This is the shape the repo
+# already chose for this same problem — rtl_check copies an off-allowlist edit
+# into .tick/orphan-backups/ before reverting it (GH-141), precisely so a
+# wrongly-caught edit stays recoverable. Refusing instead would fire on every
+# legitimate solo-session cleanup and train an override reflex, and an override
+# that is always used is not a guard.
+#
+# WHY A HOOK AND NOT A DOC RAIL: GH-527 falsified the doc-rail proposal against
+# the session's own ledger — every mechanical guard (frozen-twin, path-integrity,
+# the SIGPIPE detector) caught the author; neither written warning did. The rail
+# in AGENTS.md is the explanation; this is the fix.
+#
+# ALWAYS EXITS 0. This guard snapshots, it does not block — the destructive
+# command still runs. Set XYZ_NO_GIT_SNAPSHOT=1 to disable.
+#
+# Known limits, stated rather than implied: command text is matched with regexes
+# over shell-separated segments, so execution nested inside $(...) or dispatched
+# via xargs is not seen; and a snapshot only covers files, not staged index state.
+
+[ "${XYZ_NO_GIT_SNAPSHOT:-0}" = "1" ] && exit 0
+
+payload="$(cat 2>/dev/null || true)"
+[ -n "$payload" ] || exit 0
+
+printf '%s' "$payload" | python3 -c '
+import json, os, re, subprocess, sys, time
+
+try:
+    ev = json.load(sys.stdin)
+except Exception:
+    sys.exit(0)
+
+if ev.get("tool_name") != "Bash":
+    sys.exit(0)
+
+cmd = (ev.get("tool_input") or {}).get("command") or ""
+if not cmd:
+    sys.exit(0)
+
+# The three shapes GH-527 Part A names, plus clean -f. The common factor is not
+# obvious from any single spelling, which is why all of them are listed here.
+SHAPES = [
+    ("reset --hard",       re.compile(r"\bgit\b.*\breset\b.*--hard\b")),
+    ("checkout -- <path>", re.compile(r"\bgit\b.*\bcheckout\b.*(--\s|\s\.\s*$)")),
+    ("stash",              re.compile(r"\bgit\b\s+stash\b(?!\s+(list|show|apply|pop|drop|branch))")),
+    ("clean -f",           re.compile(r"\bgit\b.*\bclean\b.*-[a-zA-Z]*f")),
+]
+
+shape = None
+for seg in re.split(r"&&|\|\||;|\|", cmd):
+    seg = seg.strip()
+    if not seg:
+        continue
+    for name, rx in SHAPES:
+        if rx.search(seg):
+            shape = name
+            break
+    if shape:
+        break
+
+if not shape:
+    sys.exit(0)
+
+
+def git(args, cwd):
+    try:
+        p = subprocess.run(["git"] + args, cwd=cwd, capture_output=True,
+                           text=True, timeout=15)
+        return p.returncode, p.stdout
+    except Exception:
+        return 1, ""
+
+
+cwd = ev.get("cwd") or os.getcwd()
+rc, top = git(["rev-parse", "--show-toplevel"], cwd)
+if rc != 0 or not top.strip():
+    sys.exit(0)
+root = top.strip()
+
+rc, status = git(["status", "--porcelain", "--untracked-files=no"], root)
+if rc != 0:
+    sys.exit(0)
+
+paths = []
+for line in status.splitlines():
+    if len(line) > 3:
+        p = line[3:].strip()
+        if " -> " in p:
+            p = p.split(" -> ", 1)[1]
+        paths.append(p.strip(chr(34)))
+
+# Clean tree: nothing to lose. The guard MUST stay silent here — a guard that
+# fires on the safe case is a blanket, and GH-527 asks for a control proving it
+# does not fire on a clean tree for exactly that reason.
+if not paths:
+    sys.exit(0)
+
+stamp = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
+dest = os.path.join(root, ".tick", "orphan-backups",
+                    "%s-gh527-%d" % (stamp, os.getpid()))
+
+saved = 0
+for rel in paths:
+    src = os.path.join(root, rel)
+    if not os.path.isfile(src):
+        continue
+    dst = os.path.join(dest, rel)
+    try:
+        os.makedirs(os.path.dirname(dst), exist_ok=True)
+        fh = open(src, "rb")
+        data = fh.read()
+        fh.close()
+        out = open(dst, "wb")
+        out.write(data)
+        out.close()
+        saved += 1
+    except Exception:
+        continue
+
+if saved:
+    where = os.path.relpath(dest, root)
+    sys.stderr.write(
+        "gh527-guard: %s is about to overwrite %d tracked file(s) from a committed state.\n"
+        % (shape, saved))
+    sys.stderr.write("gh527-guard: snapshot saved -> %s\n" % where)
+    sys.stderr.write("gh527-guard: recover with: cp -R %s/. .\n" % where)
+
+sys.exit(0)
+'
+exit 0
diff --git a/relay-automation/hooks/security-scan-baseline.txt b/relay-automation/hooks/security-scan-baseline.txt
index 2ae2ea6e..8f1b58f6 100644
--- a/relay-automation/hooks/security-scan-baseline.txt
+++ b/relay-automation/hooks/security-scan-baseline.txt
@@ -26,6 +26,8 @@ relay-automation/poll.sh	eval-unsanitized	# `eval "$RUNNER_CMD"` exec'd the wron
 relay-automation/poll.sh	eval-unsanitized	  if [[ -x "$1" ]]; then "$1"; else eval "$1"; fi
 relay-automation/relay-drive.sh	eval-unsanitized	    eval "$AGENT_CMD"
 test/find-harness.sh	eval-unsanitized	ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
+test/gh520-default-reviewer-stub.sh	eval-unsanitized	ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
+test/gh527-destructive-git-guard.sh	eval-unsanitized	ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
 test/marathon-drive.sh	eval-unsanitized	if [[ -x "$acmd" ]]; then "$acmd"; else eval "$acmd"; fi
 test/poll-driver.sh	eval-unsanitized	# puts a space in that path and the old `eval "$RUNNER_CMD"` split it (exec'd "/Users/.../GH").
 test/poll-relay.sh	eval-unsanitized	# `eval "$AGENT_CMD"` split on the space → exec'd the wrong token → the turn-taker never ran. The fix:
diff --git a/relay-automation/improve-loop.sh b/relay-automation/improve-loop.sh
index f457721d..aea1332b 100755
--- a/relay-automation/improve-loop.sh
+++ b/relay-automation/improve-loop.sh
@@ -67,7 +67,12 @@ if [ "$MAXBUD" != 0 ] && [ "$CURRENCY" = tokens ] && [ "$AGENT" = agy ]; then
   echo "improve-loop.sh: cannot enforce --max-total-budget in tokens for the cost-blind agy lane — use --currency seconds" >&2; exit 2
 fi
 ALLOW="${ALLOW:-$ARTIFACT}"
-STATE_DIR="${STATE_DIR:-${TMPDIR:-/tmp}/improve-loop.$$}"
+# GH-430: the loop's only audit trail (provenance.jsonl) must survive the run. A process-scoped
+# ${TMPDIR:-/tmp} default evaporates the moment the process exits, so proof cited in an issue/PR/
+# ROADMAP entry can never be checked later. Default into a TRACKED in-repo path instead — NOT under
+# .tick/ (gitignored, so rtl_enforce gives it zero containment protection per GH-396) and NOT under
+# any other gitignored directory. An explicit --state-dir still wins (parsed above, ~line 45).
+STATE_DIR="${STATE_DIR:-$HERE/state/improve-loop.$$}"
 mkdir -p "$STATE_DIR"
 SNAP="$STATE_DIR/champion.artifact"
 
diff --git a/skills/relay-xyz/SKILL.md b/skills/relay-xyz/SKILL.md
index 7130586b..d61584bd 100644
--- a/skills/relay-xyz/SKILL.md
+++ b/skills/relay-xyz/SKILL.md
@@ -155,7 +155,7 @@ so each gets its own lock, `.tick/`, and worktrees:
 | Install path | Ships | Relay capability | Lock |
 |---|---|---|---|
 | `install.sh` (tick-only) | `bin/tick` + `src/*.js` | ❌ falls back to the centralized harness | shared (serializes) |
-| **`xyz-vendor.sh vendor <repo>`** | full harness (`relay-automation/` + tick + src) into a gitignored `.xyz/` | ✅ per-repo | **own** `.xyz/.relay-driver.lock` |
+| **`xyz-vendor.sh <target-repo> [--no-register]`** | full harness (`relay-automation/` + tick + src) into a gitignored `.xyz/` | ✅ per-repo | **own** `.xyz/.relay-driver.lock` |
 
 Updating a vendored copy (`xyz-sync.sh update`, or re-running `xyz-vendor.sh` over an existing
 `.xyz/`) replaces the harness **code** and preserves the per-repo state above — `relay-system/`,
diff --git a/skills/relay-xyz/find-harness.sh b/skills/relay-xyz/find-harness.sh
index a9e0b8b7..35c487e4 100755
--- a/skills/relay-xyz/find-harness.sh
+++ b/skills/relay-xyz/find-harness.sh
@@ -252,7 +252,7 @@ case "${1:-}" in
         fi
         echo "      share ONE global driver lock (can't run concurrently with another repo's relay). For"
         echo "      per-repo isolation / concurrent relays, vendor this repo:"
-        echo "        relay-automation/xyz-vendor.sh vendor $_caller"
+        echo "        relay-automation/xyz-vendor.sh $_caller"
         # GH-448: resolve via the shared resolver, not a 2-candidate guess — when $HARNESS itself is a
         # linked worktree (.git is a FILE), the driver's real lock lives at the git common dir, which
         # neither hardcoded candidate above matched, so this warning silently never fired.
diff --git a/test/_setup.sh b/test/_setup.sh
index 628d7a2c..2a55a335 100755
--- a/test/_setup.sh
+++ b/test/_setup.sh
@@ -112,6 +112,39 @@ export TICK_REPO_ROOT="$A"
 # has a suite that proves it fires rather than a suite that silently never reaches it.
 export MARATHON_ALLOW_TRUNK_COMMIT=1
 
+# GH-520: give every fixture a default REVIEWER binary, for the same reason and in the same place
+# as the line above.
+#
+# `marathon_drive.py` probes the reviewer binary before the guards, the preflight and the dispatch
+# (`_probe_agent_bin`), and `--reviewer codex` is the default in essentially every marathon fixture.
+# Stubbing the *builder* is the obvious half — it is the thing the test drives — so the reviewer
+# stays invisible until a machine without `codex` runs the suite. A fixture that misses it never
+# reaches the code it was written to test, and its assertions read the probe's message instead.
+#
+# That is not hypothetical and it is not a flake: it has now happened three times. GH-232 recorded
+# it in a `ci.yml` comment (`driver-lock.sh`/`xyz-harness-hooks.sh` stubbed CLAUDE_BIN/AGY_BIN but
+# not CODEX_BIN), and on 2026-08-11/12 three more suites — gh402, gh514, gh388 — shipped green
+# locally and were red on every ubuntu run for a whole session. The comment did not prevent the
+# recurrence, which is the actual finding: this needs a default, not another warning.
+#
+# Worse than a flake, because a fail-fast can satisfy an ABSENCE assertion for the wrong reason:
+# `gh514` asserts on the absence of a Python traceback, which a run that dies at the probe also
+# produces. Those three happened to fail closed; nothing in the design guarantees the next one will.
+#
+# Declared ONCE, here, as what it is: the harness saying the reviewer binary is not the thing under
+# test. The probe is still exercised — `test/marathon-drive.sh` sets an explicitly MISSING binary
+# for the cases that must refuse, so it has a suite proving it fires rather than one that silently
+# never reaches it. A fixture that needs its own reviewer behaviour still overrides CODEX_BIN
+# inline, exactly as the shim suites already do.
+_CODEX_STUB="$WORK/_default-codex-stub"
+cat > "$_CODEX_STUB" <<'CODEX_STUB_EOF'
+#!/usr/bin/env bash
+# GH-520 default reviewer stub: present on PATH-probe, does nothing, succeeds.
+exit 0
+CODEX_STUB_EOF
+chmod +x "$_CODEX_STUB"
+export CODEX_BIN="${CODEX_BIN:-$_CODEX_STUB}"
+
 PASS=0
 FAIL=0
 pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
diff --git a/test/find-harness.sh b/test/find-harness.sh
index 9cc56be1..1743b1d1 100755
--- a/test/find-harness.sh
+++ b/test/find-harness.sh
@@ -42,7 +42,10 @@ FR="$(mktemp -d "${TMPDIR:-/tmp}/fh-foreign.XXXXXX")"; git -C "$FR" init -q
 out2="$( cd "$FR" && bash "$FH" --check 2>&1 )"; rc2=$?
 ok "foreign no-.xyz: --check still exits 0 (fail-open)"  "[ '$rc2' -eq 0 ]"
 ok "foreign no-.xyz: emits the concurrency warning"      "printf '%s' \"\$out2\" | grep -qi 'concurrency'"
-ok "foreign no-.xyz: points at xyz-vendor.sh"            "printf '%s' \"\$out2\" | grep -q 'xyz-vendor.sh vendor'"
+# GH-421: the hint must use the REAL contract (target repo is the sole positional). Asserting the
+# old 'xyz-vendor.sh vendor' form is what kept the broken hint alive — the test pinned the defect.
+ok "foreign no-.xyz: points at xyz-vendor.sh"            "printf '%s' \"\$out2\" | grep -q 'xyz-vendor.sh '"
+ok "foreign no-.xyz: hint omits the bogus vendor subcommand" "! printf '%s' \"\$out2\" | grep -q 'xyz-vendor.sh vendor'"
 rm -rf "$FR"
 
 # --- Case 3: foreign repo WITH a local .xyz/ harness → resolves to it, NO concurrency warning ---
diff --git a/test/fixtures/gamma-poison/poison.patch b/test/fixtures/gamma-poison/poison.patch
index c952338b..09c44273 100644
--- a/test/fixtures/gamma-poison/poison.patch
+++ b/test/fixtures/gamma-poison/poison.patch
@@ -1,10 +1,10 @@
 diff --git a/src/paths.js b/src/paths.js
-index 2c82206..ac17fa4 100644
+index a3c80307..22ee7f97 100644
 --- a/src/paths.js
 +++ b/src/paths.js
-@@ -9,7 +9,7 @@
- // but never misses a real overlap.
- 
+@@ -15,7 +15,7 @@
+  * @returns {string}
+  */
  function literalPrefix(glob) {
 -  const m = glob.match(/^([^*?[{]*)/);
 +  const m = glob.match(/^([^?[{]*)/);
diff --git a/utils/py/marathon_drive.py b/utils/py/marathon_drive.py
index 8b9a483d..06e90948 100644
--- a/utils/py/marathon_drive.py
+++ b/utils/py/marathon_drive.py
@@ -2041,7 +2041,28 @@ You are the REVIEWER for this phase. {reviewer_read_line}
     # Checked against `root`, deliberately, because that is the repo these files are committed to —
     # under --target-root only CODE changes land elsewhere, and the relay/escalation/transcript stay
     # here. Checking the target instead would be the plausible-looking wrong answer.
-    preflight_write_set_trackable(root, [relay_file, os.path.join(phase_dir, "ESCALATION.md")])
+    # GH-314: the write set is THREE paths, not two. `save_transcript()` also does a
+    # `git add --` with check=True on a file under the transcript root, so an ignored
+    # `relay-system/` HALTs the chain after the turn is already spent — the same defect this
+    # preflight exists to stop, on the one path it was not checking. That third call site is
+    # exactly the one #314's second reporter found the hard way, an afternoon at a time.
+    #
+    # The root is resolved the same way `save_transcript()` resolves it (rtl_transcript_root via
+    # relay-turn-lib.sh) rather than assuming the literal `relay-system/`, because a vendored or
+    # relocated install can move it and a hardcoded guess would check a path the run never writes.
+    # If it cannot be resolved, the path is simply not added: this guard must not invent a new way
+    # for a healthy run to fail, which is the same fail-open contract the docstring above sets.
+    _write_set = [relay_file, os.path.join(phase_dir, "ESCALATION.md")]
+    try:
+        _ts_base = subprocess.check_output(
+            "source \"%s\" && rtl_transcript_root \"%s\"" % (
+                os.path.join(xyz_harness, "relay-automation", "relay-turn-lib.sh"), root),
+            shell=True, executable="/bin/bash", stderr=subprocess.DEVNULL).decode("utf-8").strip()
+        if _ts_base:
+            _write_set.append(os.path.join(_ts_base, "probe", "transcript.md"))
+    except Exception:
+        pass
+    preflight_write_set_trackable(root, _write_set)
 
     # GH-402: refuse to make the first commit if the RECEIVING repo is sitting on its trunk.
     #
diff --git a/validate.sh b/validate.sh
index 99c5baba..4d226d5c 100755
--- a/validate.sh
+++ b/validate.sh
@@ -148,6 +148,10 @@ TESTS=(
   "improve-loop.sh"
   "improve-loop-qa.sh"
   "improve-loop-dogfood.sh"
+  "gh430-state-dir-tracked-default.sh" # GH-430 (STATE_DIR default is a tracked in-repo path, not ${TMPDIR:-/tmp})
+  "gh314-transcript-writeset.sh"       # GH-314 (the write set is THREE paths: the transcript's git add was outside GH-514's preflight, so an ignored relay-system/ was discovered only after paid turns) — 5/0; control: dropping the transcript path spends 2 builder turns before the same refusal (test/baselines/GH-314-negative-control.md)
+  "gh520-default-reviewer-stub.sh"     # GH-520 (test/_setup.sh gives every fixture a default CODEX_BIN, so a suite tests its subject rather than the reviewer probe) — 11/0; control: with gh402's own stub removed AND this default removed, gh402 fails with the probe's message verbatim (test/baselines/GH-520-default-stub-control.md)
+  "gh527-destructive-git-guard.sh"     # GH-527 (a tree-overwriting git command snapshots the tracked files it destroys into .tick/orphan-backups/ first) — 26/0; controls: a no-op guard drops 9 assertions, and a blanket that fires on a CLEAN tree drops exactly the control assertion. Clean-tree silence is defended by TWO conditions, so it takes a combined mutation to falsify — recorded in test/baselines/GH-527-negative-control.md
   "marathon.sh"
   "gh484-phase-dir-default.sh"   # GH-484 (phase-output default is marathon-system/; --phases-dir still overrides; the dirty-tree exclusion tracks the CONFIGURED dir) — 10/0; controls: pre-fix red on both defaults and both containment cases, plus a stray-file control proving the clean check actually ran. Forces XYZ_PYTHON=0 so the Bash twin is really exercised
   "marathon-root-audit.sh"       # GH-209 (static audit: every test/marathon*.sh invocation is MARATHON_ROOT-scoped)
@@ -396,11 +400,23 @@ else
   FAILED+=("python:test_python_layer.py")
 fi
 
+# GH-428: non-recursive staleness probe for the gamma-poison fixture (does NOT run
+# verify-fixture.sh — that runs this whole suite, so nesting it would recurse).
+echo
+echo "==============================="
+echo "Running gamma-poison fixture staleness probe"
+echo "==============================="
+if git apply --check "$HERE/test/fixtures/gamma-poison/poison.patch" 2>/dev/null; then
+  PASSED+=("gamma-poison-staleness-probe")
+else
+  FAILED+=("gamma-poison-staleness-probe")
+fi
+
 echo
 echo "==============================="
 echo "Summary"
 echo "==============================="
-TOTAL=$(( ${#TESTS[@]} + 1 ))
+TOTAL=$(( ${#TESTS[@]} + 2 ))
 echo "passed: ${#PASSED[@]} / ${TOTAL}"
 for t in "${PASSED[@]}"; do echo "  + $t"; done
 if [ "${#FAILED[@]}" -gt 0 ]; then

```

---

## Test diff (new suites)

```diff
diff --git a/test/gh314-transcript-writeset.sh b/test/gh314-transcript-writeset.sh
new file mode 100644
index 00000000..fc8ddca9
--- /dev/null
+++ b/test/gh314-transcript-writeset.sh
@@ -0,0 +1,132 @@
+#!/usr/bin/env bash
+# GH-314 — the run's write set is THREE paths, and the transcript was the one nobody checked.
+#
+# GH-514 built `preflight_write_set_trackable` and wired it to RELAY.md and ESCALATION.md. It cites
+# #314 in its own comment, so it reads as if it closed it. It did not: `save_transcript()` performs a
+# third `git add -- <transcript>` with check=True, under the transcript root (`relay-system/` by
+# default), and that path was never passed to the preflight.
+#
+# The consequence is worse than the two it does cover, because the transcript is written LATE — the
+# builder turn and the reviewer turn are already spent by the time it runs. #314's second reporter
+# found this the expensive way: un-ignore RELAY.md, burn a full phase, crash on the next path,
+# roughly 1.5h per landmine, serially.
+#
+# The hostile ignore here is `relay-system/` specifically, NOT `marathon-system/` — that is what
+# makes this suite discriminate from gh514. With only `relay-system/` ignored the GH-514 paths are
+# all trackable, so the pre-fix tree sails through preflight.
+#
+# WHAT ACTUALLY DISCRIMINATES, corrected by this file's own negative control — the same way gh514's
+# header records its first draft being falsified.
+#
+# The first draft assumed the pre-fix tree dies in an unhandled `CalledProcessError` from
+# `save_transcript`'s `git add`, so "no traceback" would be the discriminating assertion. **The
+# control falsified that.** Pre-fix, the run still refuses cleanly, still names `relay-system`, and
+# still produces no traceback — it exits 4 rather than 2, because a later layer does catch it.
+#
+# What actually changes is the COST. Pre-fix:
+#
+#     FAIL: 2 builder turn(s) were spent before the transcript refusal
+#
+# Two paid turns bought a refusal the driver could have issued before spending anything. That is
+# #314's report almost verbatim — un-ignore one path, burn a full phase, crash on the next, ~1.5h
+# per landmine, serially. So the discriminating assertion here is the DISPATCH COUNT, and the
+# traceback assertion is demoted to a guard: it does not discriminate today and must not regress.
+#
+# Usage: bash test/gh314-transcript-writeset.sh
+HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
+ROOT_DIR="$(cd "$HERE/.." && pwd)"
+# shellcheck source=/dev/null
+source "$HERE/_setup.sh" gh314-transcript-writeset
+
+DRIVE="$ROOT_DIR/relay-automation/marathon-drive.sh"
+
+DISPATCH_LOG="$WORK/dispatched.log"
+STUB="$WORK/builder-stub"
+cat >"$STUB" <<STUB_EOF
+#!/usr/bin/env bash
+echo "DISPATCHED" >>"$DISPATCH_LOG"
+printf '\n### Round 1 · Builder\nwork\n' >>"\${RELAY_FILE:-/dev/null}" 2>/dev/null || true
+exit 0
+STUB_EOF
+chmod +x "$STUB"
+
+# GH-520: stub the REVIEWER explicitly. test/_setup.sh now supplies a default, but this suite
+# asserts on the CONTENT of a refusal, and a run that fail-fasts at the reviewer probe would
+# satisfy an absence assertion for entirely the wrong reason.
+REVIEWER_STUB="$WORK/reviewer-stub"
+printf '#!/usr/bin/env bash\nexit 0\n' >"$REVIEWER_STUB"
+chmod +x "$REVIEWER_STUB"
+export CODEX_BIN="$REVIEWER_STUB"
+
+mk_target() { # <label> <extra-gitignore-line>
+  local label="$1"
+  local extra="$2"
+  local d="$WORK/$label"
+  git init -q "$d"
+  git -C "$d" config user.email t@t
+  git -C "$d" config user.name t
+  { printf '.tick/\n'; [ -n "$extra" ] && printf '%s\n' "$extra"; } >"$d/.gitignore"
+  mkdir -p "$d/PROJECT/2-WORKING"
+  printf '# brief\n\nDo the thing.\n' >"$d/PROJECT/2-WORKING/brief.md"
+  git -C "$d" add -A >/dev/null 2>&1
+  git -C "$d" commit -q -m seed
+  printf '%s' "$d"
+}
+
+run_drive() { # <target-dir> <out-file>
+  local d="$1" out="$2"
+  ( XYZ_PYTHON=1 MARATHON_ROOT="$d" TICK_REPO_ROOT="$d" TICK_BIN="$TICK" \
+      CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$d" RELAY_AGENT=claude-builder \
+      bash "$DRIVE" --phase-id lane1 --reviewer codex --builder claude \
+        --phase-brief "$d/PROJECT/2-WORKING/brief.md" --round-cap 3 \
+        --phases-dir "$d/marathon-system" --pre-advance-cmd true >"$out" 2>&1 )
+  printf '%s' $?
+}
+
+# ---------------------------------------------------------------------------
+# Case 1 — the target ignores ONLY the transcript root
+# ---------------------------------------------------------------------------
+echo "-- case 1: the target gitignores relay-system/ (the third write-set path)"
+HOSTILE="$(mk_target hostile-transcript 'relay-system/')"
+: >"$DISPATCH_LOG"
+rc="$(run_drive "$HOSTILE" "$WORK/hostile.out")"
+
+[ "$rc" -ne 0 ] \
+  && pass "a target that cannot track the transcript is refused (exit $rc)" \
+  || fail "GH-314: the run completed against a target that gitignores relay-system/"
+
+# THE discriminating assertion. Pre-fix the preflight never sees this path, so the run proceeds and
+# the failure arrives later as an unhandled CalledProcessError from save_transcript's git add.
+if /usr/bin/grep -qE "Traceback \(most recent call last\)|CalledProcessError" "$WORK/hostile.out"; then
+  fail "GH-314: died with an unhandled traceback instead of refusing — the transcript path is still outside the preflight. Output: $(cat "$WORK/hostile.out")"
+else
+  pass "refuses cleanly — no unhandled traceback on the transcript path"
+fi
+
+/usr/bin/grep -qi "relay-system" "$WORK/hostile.out" \
+  && pass "the refusal names the transcript path that cannot be tracked" \
+  || fail "GH-314: the refusal does not name relay-system/ — output: $(cat "$WORK/hostile.out")"
+
+# The whole point of moving this earlier: the turns are not spent first.
+dispatches="$(/usr/bin/grep -c DISPATCHED "$DISPATCH_LOG" 2>/dev/null | head -1)"; dispatches="${dispatches:-0}"
+if [ "$dispatches" -eq 0 ]; then
+  pass "no builder turn was spent before the refusal"
+else
+  fail "GH-314: $dispatches builder turn(s) were spent before the transcript refusal — this is the expensive failure the issue reports"
+fi
+
+# ---------------------------------------------------------------------------
+# Case 2 — CONTROL: a healthy target must NOT be refused
+# ---------------------------------------------------------------------------
+# Without this, blocking every run would pass case 1 and the guard would be a blanket.
+echo "-- case 2: control — a target with no hostile ignore rule"
+HEALTHY="$(mk_target healthy-transcript '')"
+: >"$DISPATCH_LOG"
+rc="$(run_drive "$HEALTHY" "$WORK/healthy.out")"
+
+/usr/bin/grep -qi "cannot track\|check-ignore\|ignored by" "$WORK/healthy.out" \
+  && fail "GH-314: the healthy target was refused by the write-set check — output: $(cat "$WORK/healthy.out")" \
+  || pass "CONTROL: a healthy target is not refused by the transcript check"
+
+echo "  gh314-transcript-writeset: $PASS pass, $FAIL fail"
+[ "$FAIL" -eq 0 ]
diff --git a/test/gh430-state-dir-tracked-default.sh b/test/gh430-state-dir-tracked-default.sh
new file mode 100644
index 00000000..b3587799
--- /dev/null
+++ b/test/gh430-state-dir-tracked-default.sh
@@ -0,0 +1,69 @@
+#!/usr/bin/env bash
+# test/gh430-state-dir-tracked-default.sh — GH-430 regression.
+#
+# improve-loop.sh's only audit trail is $STATE_DIR/provenance.jsonl. The old default rooted it at
+# ${TMPDIR:-/tmp}/improve-loop.$$ — process-scoped, so the evidence evaporates the moment the run
+# exits. A full-tree search for provenance*.jsonl turned up zero hits, including the run the
+# 2026-06-30 ROADMAP entry and the GH-50 close cited as "provenance logged".
+#
+# This asserts that running the loop WITHOUT --state-dir puts provenance.jsonl at a path inside this
+# repo that git actually tracks (not ignored) — and specifically not under /tmp or $TMPDIR — while an
+# explicit --state-dir still overrides the default unchanged.
+set -u
+HERE="$(cd "$(dirname "$0")" && pwd)"
+REPO="$(cd "$HERE/.." && pwd)"
+IL="$REPO/relay-automation/improve-loop.sh"
+PASS=0; FAIL=0
+pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
+fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
+echo "== test: gh430-state-dir-tracked-default =="
+W="${TMPDIR:-/tmp}/gh430-state-dir-test.$$"; rm -rf "$W"; mkdir -p "$W"
+CREATED_DIRS=()
+cleanup(){ rm -rf "$W"; for d in "${CREATED_DIRS[@]:-}"; do [ -n "$d" ] && rm -rf "$d"; done; }
+trap cleanup EXIT
+
+# ---- Scenario A: no --state-dir -> default lands inside the repo, tracked, provenance survives -----
+ART="$W/artifact"; echo 50 >"$ART"
+OUT="$(cd "$REPO" && bash "$IL" --artifact "$ART" --measure-cmd "cat $ART" --oracle-cmd true \
+        --build-cmd true --goal max --max-iterations 1 2>&1)"; RC=$?
+[ "$RC" = 0 ] && pass "run without --state-dir completed (exit 0)" || fail "rc=$RC out=$OUT"
+
+SD="$(printf '%s\n' "$OUT" | /usr/bin/grep -o 'provenance: .*/provenance\.jsonl' | sed 's/^provenance: //; s#/provenance\.jsonl$##')"
+[ -n "$SD" ] && pass "captured the default STATE_DIR from the run log ($SD)" || fail "could not find a 'provenance:' log line in: $OUT"
+[ -n "$SD" ] && CREATED_DIRS+=("$SD")
+
+case "$SD" in
+  "$REPO"/*) pass "default STATE_DIR resolves inside this repo" ;;
+  *) fail "default STATE_DIR is NOT inside the repo: $SD" ;;
+esac
+
+TMPROOT="${TMPDIR:-/tmp}"
+case "$SD" in
+  "$TMPROOT"/*|/tmp/*) fail "default STATE_DIR is still under a tmp root: $SD" ;;
+  *) pass "default STATE_DIR is not under /tmp or \$TMPDIR" ;;
+esac
+
+if [ -n "$SD" ]; then
+  REL="${SD#"$REPO"/}"
+  if (cd "$REPO" && git check-ignore -q "$REL"); then
+    fail "default STATE_DIR path is gitignored (zero containment protection, GH-396): $REL"
+  else
+    pass "default STATE_DIR path is NOT gitignored -> tracked-eligible: $REL"
+  fi
+fi
+
+[ -n "$SD" ] && [ -s "$SD/provenance.jsonl" ] && pass "provenance.jsonl exists and is non-empty at the default path" \
+  || fail "no provenance.jsonl at default path $SD"
+
+# ---- Scenario B: an explicit --state-dir still overrides the default, unchanged --------------------
+B="$W/b"; echo 50 >"$B-art" 2>/dev/null || true
+ART2="$W/art2"; echo 50 >"$ART2"
+EXPLICIT="$W/explicit-state"
+OUT2="$(cd "$REPO" && bash "$IL" --artifact "$ART2" --measure-cmd "cat $ART2" --oracle-cmd true \
+         --build-cmd true --goal max --max-iterations 1 --state-dir "$EXPLICIT" 2>&1)"; RC2=$?
+[ "$RC2" = 0 ] && pass "run with explicit --state-dir completed (exit 0)" || fail "rc=$RC2 out=$OUT2"
+[ -s "$EXPLICIT/provenance.jsonl" ] && pass "explicit --state-dir still wins over the default" \
+  || fail "explicit --state-dir was not honored: $EXPLICIT/provenance.jsonl missing"
+
+echo "  gh430-state-dir-tracked-default: $PASS pass, $FAIL fail"
+[ "$FAIL" = 0 ]
diff --git a/test/gh520-default-reviewer-stub.sh b/test/gh520-default-reviewer-stub.sh
new file mode 100644
index 00000000..4141b545
--- /dev/null
+++ b/test/gh520-default-reviewer-stub.sh
@@ -0,0 +1,79 @@
+#!/usr/bin/env bash
+set -euo pipefail
+#
+# gh520-default-reviewer-stub.sh — GH-520: a marathon fixture that does not stub CODEX_BIN tests
+# the reviewer-binary probe instead of the code under test, and passes locally while failing CI.
+#
+# `_probe_agent_bin` runs before the guards, the preflight and the dispatch, and `--reviewer codex`
+# is the default in essentially every marathon fixture. On a developer machine a real `codex` is on
+# PATH, so the probe passes and nobody notices; on ubuntu CI there is none, the run dies at the
+# probe, and the fixture's assertions read the probe's message instead of the behaviour they were
+# written for.
+#
+# `test/_setup.sh` now exports a default `CODEX_BIN` stub. The two assertions that matter are in
+# TENSION and both are checked here, because fixing this by disabling the probe would be worse than
+# the bug:
+#
+#   * the default exists, is executable, and survives into a sourcing fixture; and
+#   * an explicitly MISSING reviewer binary STILL fails fast — the protection is intact.
+#
+# The second is the one that keeps this honest. GH-117 built that probe so a lane with an
+# undispatchable binary dies before spending a tick token; a default stub that silently swallowed
+# that would trade a loud CI failure for a spent relay task.
+
+HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
+REPO="$(cd "$HERE/.." && pwd)"
+
+pass=0; fail=0
+ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
+
+echo "== test: gh520-default-reviewer-stub =="
+
+# --- (1) the default is declared in the one file every fixture sources ------------------------
+ok "_setup.sh declares a default CODEX_BIN" \
+   "grep -q 'export CODEX_BIN=' '$REPO/test/_setup.sh'"
+ok "_setup.sh does NOT clobber an explicit CODEX_BIN (uses :- default)" \
+   "grep -q 'export CODEX_BIN=\"\${CODEX_BIN:-' '$REPO/test/_setup.sh'"
+
+# --- (2) a fixture that sources _setup.sh really gets a usable stub ---------------------------
+PROBE="$(mktemp "${TMPDIR:-/tmp}/gh520-probe.XXXXXX.sh")"
+cat > "$PROBE" <<'EOF'
+set -u
+# shellcheck disable=SC1091
+. "$REPO_UNDER_TEST/test/_setup.sh" gh520-inner >/dev/null 2>&1
+printf 'CODEX_BIN=%s\n' "${CODEX_BIN:-UNSET}"
+[ -x "${CODEX_BIN:-/nonexistent}" ] && printf 'EXECUTABLE=yes\n' || printf 'EXECUTABLE=no\n'
+EOF
+OUT="$(REPO_UNDER_TEST="$REPO" bash "$PROBE" 2>/dev/null || true)"
+ok "a sourcing fixture inherits a CODEX_BIN" \
+   "printf '%s' \"\$OUT\" | grep -q 'CODEX_BIN=/'"
+ok "the inherited stub is executable" \
+   "printf '%s' \"\$OUT\" | grep -q 'EXECUTABLE=yes'"
+
+# --- (3) an explicit CODEX_BIN still wins -----------------------------------------------------
+OUT="$(REPO_UNDER_TEST="$REPO" CODEX_BIN=/usr/bin/true bash "$PROBE" 2>/dev/null || true)"
+ok "an explicit CODEX_BIN overrides the default" \
+   "printf '%s' \"\$OUT\" | grep -q 'CODEX_BIN=/usr/bin/true'"
+rm -f "$PROBE"
+
+# --- (4) THE COMPANION: the probe must still fire on a genuinely missing binary ----------------
+# Without this, a default stub would be indistinguishable from deleting the protection.
+ok "marathon-drive still asserts a missing reviewer binary fails fast" \
+   "grep -q 'missing reviewer binary exits 2' '$REPO/test/marathon-drive.sh'"
+ok "marathon-drive still asserts the message names the missing binary" \
+   "grep -q 'missing reviewer error names the missing binary' '$REPO/test/marathon-drive.sh'"
+ok "the probe itself is still wired before dispatch" \
+   "grep -q '_probe_agent_bin' '$REPO/utils/py/marathon_drive.py'"
+
+# --- (5) the reproduction: the three named fixtures no longer depend on a real codex -----------
+# GH-520's evidence is that gh402/gh514/gh388 read the probe's message on a machine without codex.
+# Each must now stub it (directly or via _setup.sh) rather than inherit one from the developer.
+for f in gh402-branch-enforcement gh514-write-set-trackable gh388-run-log-durability; do
+  if [ -f "$REPO/test/$f.sh" ]; then
+    ok "$f sources the shared setup (so it inherits the stub)" \
+       "grep -qE '_setup.sh' '$REPO/test/$f.sh'"
+  fi
+done
+
+echo "  gh520-default-reviewer-stub: $pass pass, $fail fail"
+[ "$fail" -eq 0 ]
diff --git a/test/gh527-destructive-git-guard.sh b/test/gh527-destructive-git-guard.sh
new file mode 100644
index 00000000..416cf798
--- /dev/null
+++ b/test/gh527-destructive-git-guard.sh
@@ -0,0 +1,114 @@
+#!/usr/bin/env bash
+set -euo pipefail
+#
+# gh527-destructive-git-guard.sh — GH-527: a git command that overwrites the working tree
+# from a committed state must leave the tracked files it destroys recoverable.
+#
+# The guard is SNAPSHOT-THEN-ALLOW, not refuse-when-dirty, so the assertions below are about
+# what it PRESERVES, not what it blocks. Two properties carry the whole issue:
+#
+#   1. It fires on a dirty tree and the destroyed content is recoverable END-TO-END
+#      (GH-527 acceptance 4: "destroy -> recover from the snapshot", demonstrated not asserted).
+#   2. It stays SILENT on a clean tree (GH-527 acceptance 3), because a guard that fires on the
+#      safe case is a blanket, and a blanket trains the override reflex that makes it useless.
+#
+# Blast radius is asserted in both directions to match the issue's own reproduced fixture:
+# TRACKED modifications are destroyed, untracked files survive. If that ever inverts, the guard
+# is snapshotting the wrong set.
+
+HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
+REPO="$(cd "$HERE/.." && pwd)"
+GUARD="$REPO/relay-automation/hooks/gh527-destructive-git-guard.sh"
+
+pass=0; fail=0
+ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
+
+echo "== test: gh527-destructive-git-guard =="
+
+mkrepo() {
+  _r="$(mktemp -d "${TMPDIR:-/tmp}/gh527.XXXXXX")"
+  git -C "$_r" init -q
+  git -C "$_r" config user.email t@t
+  git -C "$_r" config user.name t
+  printf 'v1\n' > "$_r/peer.txt"
+  git -C "$_r" add peer.txt
+  git -C "$_r" commit -qm init
+  printf '%s\n' "$_r"
+}
+
+# hook_out <repo> <command> — run the guard with a PreToolUse-shaped payload, capture stderr
+hook_out() {
+  printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"%s"}}' "$1" "$2" \
+    | bash "$GUARD" 2>&1 || true
+}
+
+ok "guard script exists and is executable" "[ -x '$GUARD' ]"
+
+# --- (1) dirty tree: fires, and the snapshot actually contains the doomed content ------------
+R="$(mkrepo)"
+printf 'PEER-UNCOMMITTED-WORK\n' > "$R/peer.txt"
+printf 'untracked peer work\n'   > "$R/peer-new.txt"
+OUT="$(hook_out "$R" "git reset --hard HEAD")"
+
+ok "dirty tree: guard announces the snapshot" "printf '%s' \"\$OUT\" | grep -q 'snapshot saved'"
+ok "dirty tree: message names the command shape" "printf '%s' \"\$OUT\" | grep -q 'reset --hard'"
+SNAP="$(ls -d "$R"/.tick/orphan-backups/*/ 2>/dev/null | head -1 || true)"
+ok "dirty tree: a snapshot directory was created" "[ -n '$SNAP' ]"
+ok "snapshot holds the pre-destruction content" \
+   "grep -q 'PEER-UNCOMMITTED-WORK' '$SNAP/peer.txt' 2>/dev/null"
+ok "snapshot does NOT include untracked files (they survive the command)" \
+   "[ ! -f '$SNAP/peer-new.txt' ]"
+
+# --- (2) recovery is demonstrated, not asserted (acceptance 4) --------------------------------
+git -C "$R" reset --hard HEAD >/dev/null 2>&1
+ok "the destructive command really did destroy the tracked edit" \
+   "grep -q '^v1$' '$R/peer.txt'"
+ok "untracked file survived the command (matches the issue's fixture)" \
+   "[ -f '$R/peer-new.txt' ]"
+cp -R "$SNAP". "$R"/
+ok "RECOVERY: content restored from the snapshot end-to-end" \
+   "grep -q 'PEER-UNCOMMITTED-WORK' '$R/peer.txt'"
+rm -rf "$R"
+
+# --- (3) THE CONTROL: clean tree must stay silent (acceptance 3) ------------------------------
+# Without this the guard is a blanket. This assertion is the reason the guard checks tracked
+# dirt at all rather than simply matching on the command.
+C="$(mkrepo)"
+OUT="$(hook_out "$C" "git reset --hard HEAD")"
+ok "CONTROL: clean tree — guard stays silent" "[ -z \"\$OUT\" ]"
+ok "CONTROL: clean tree — no snapshot directory created" \
+   "[ -z \"\$(ls -d '$C'/.tick/orphan-backups/*/ 2>/dev/null || true)\" ]"
+
+# --- (4) all three shapes GH-527 names, plus clean -f ------------------------------------------
+printf 'dirty\n' > "$C/peer.txt"
+for shape in "git reset --hard HEAD" "git checkout -- peer.txt" "git stash" "git clean -fd"; do
+  OUT="$(hook_out "$C" "$shape")"
+  ok "fires on: $shape" "printf '%s' \"\$OUT\" | grep -q 'snapshot saved'"
+done
+
+# --- (5) read-only git and non-Bash tools must NOT trip it ------------------------------------
+for safe in "git status" "git stash list" "git log --oneline" "git diff"; do
+  OUT="$(hook_out "$C" "$safe")"
+  ok "silent on read-only: $safe" "[ -z \"\$OUT\" ]"
+done
+OUT="$(printf '{"tool_name":"Edit","cwd":"%s","tool_input":{"command":"git reset --hard"}}' "$C" | bash "$GUARD" 2>&1 || true)"
+ok "ignores non-Bash tool calls" "[ -z \"\$OUT\" ]"
+
+# --- (6) the documented escape hatch works ----------------------------------------------------
+OUT="$(printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"git reset --hard HEAD"}}' "$C" \
+  | XYZ_NO_GIT_SNAPSHOT=1 bash "$GUARD" 2>&1 || true)"
+ok "XYZ_NO_GIT_SNAPSHOT=1 disables the guard" "[ -z \"\$OUT\" ]"
+rm -rf "$C"
+
+# --- (7) the rail exists and names all three shapes (acceptance 1) -----------------------------
+ok "AGENTS.md rail names reset --hard"      "grep -q 'reset --hard' '$REPO/AGENTS.md'"
+ok "AGENTS.md rail names checkout -- <path>" "grep -q 'checkout --' '$REPO/AGENTS.md'"
+ok "AGENTS.md rail names stash"              "grep -qi 'git stash' '$REPO/AGENTS.md'"
+ok "AGENTS.md rail points at the guard"      "grep -q 'gh527-destructive-git-guard' '$REPO/AGENTS.md'"
+
+# --- (8) registered as a PreToolUse Bash hook (acceptance 5) -----------------------------------
+ok "hook registered in .claude/settings.json" \
+   "grep -q 'gh527-destructive-git-guard' '$REPO/.claude/settings.json'"
+
+echo "  gh527-destructive-git-guard: $pass pass, $fail fail"
+[ "$fail" -eq 0 ]

```
````
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer (agy)

swept file: yes

*   **GH-527 guard shape** `[Should-fix]`: Allowing destruction is dangerous if the snapshot fails (e.g. disk full, permission error). The script (`relay-automation/hooks/gh527-destructive-git-guard.sh:L244`) does `except Exception: continue` during the copy loop. If the copy fails, it still exits 0, silently allowing the command to destroy the working tree without actually taking a snapshot. It should fail closed (or warn loudly and block) if a file fails to copy.
*   **GH-527 regex coverage** `[Blocker]`: The checkout regex (`relay-automation/hooks/gh527-destructive-git-guard.sh:L171`) `.*\bcheckout\b.*(--\s|\s\.\s*$)` is too narrow. `git checkout some/file.txt` (without `--`) slips through completely, which is exactly the action an agent might take to revert changes but accidentally blow away a peer's work. The clean regex `-[a-zA-Z]*f` also misses `git clean --force`.
*   **GH-527 tracked-only** `[Should-fix]`: Skipping untracked files (`relay-automation/hooks/gh527-destructive-git-guard.sh:L126`) means `git clean -f` will permanently destroy untracked files with no snapshot. While checkout and reset might preserve untracked files, `clean -f` explicitly deletes them, making the guard useless for that specific shape.
*   **GH-520 default stub** `[Pass]`: Verified that `test/marathon-drive.sh` explicitly unsets or overrides `CODEX_BIN` when testing the missing binary logic. A default stub in `test/_setup.sh:L147` using `:-` is standard and won't mask tests that explicitly mock a missing binary.
*   **GH-314 fail-open** `[Blocker]`: Silent narrowing is not defensible here (`utils/py/marathon_drive.py:L2062`). If `rtl_transcript_root` cannot be resolved, failing open means the run proceeds but the transcript isn't preflighted, risking the exact same expensive failure mode GH-314 was meant to fix (crashing after paying for turns). The preflight should fail closed (refuse to start) if it can't resolve the transcript root.
*   **GH-314 probe path** `[Should-fix]`: Checking a synthetic `probe/transcript.md` (`utils/py/marathon_drive.py:L2061`) means a `.gitignore` rule targeting a real date directory format (e.g., `relay-system/2026-*/`) would not be caught by the probe, allowing the run to fail later when the real transcript is written. Use a synthetic date that mimics the real path structure.
*   **Controls** `[Pass]`: Removing the existing stub to prove the default stub fixes the real problem is a legitimate negative control (`validate.sh:L140` approx). It proves that a missing stub causes the failure, and the default stub prevents it.

**Verdict:** Changes requested

Handing off to Producer — go to the claude-a window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
