# RELAY · review PR #81 (GH-78 doc-preflight)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-02.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(review-pr-81-gh-78-doc-preflight): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **pr81.diff** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-02

### Artifact — pr81.diff
```
diff --git a/.gitignore b/.gitignore
index c5d0419..6407326 100644
--- a/.gitignore
+++ b/.gitignore
@@ -18,3 +18,5 @@ PROJECT/.DS_Store
 # to (relay/marathon/swarm). Kept out of git to avoid per-session merge-conflict churn.
 XYZ.json
 XYZ.json.lock/
+# GH-78: hourly doc-preflight telemetry — per-machine, per-run edit/warn logs; gitignored to avoid churn.
+utils/telemetry/preflight-log/
diff --git a/CHANGELOG.md b/CHANGELOG.md
index 0511a4c..cbe2fa7 100644
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -4,6 +4,17 @@ All notable changes to this repo. Newest first. Dates are PDT.
 
 ## 2026-07-02
 
+### GH-78 captured + v1 shipped — optional hourly doc-preflight (contract-enforcing auto-edits + telemetry)
+Issue-first SOP followed: [#78](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/78) opened, `PROJECT/1-INBOX/GH-78-DOC-PREFLIGHT-AUTOMATION.md` captured, parked in `ROADMAP.md`'s queue. Then built the v1.
+
+- **`utils/telemetry/preflight-docs.sh`** — a best-effort, off-by-default, hourly preflight over every `PROJECT/2-WORKING/` doc + every ROADMAP-queued `PROJECT/1-INBOX/GH-*.md` capture. For each doc it (1) **reviews** against the PDDA contract by reusing the deterministic `pdda.sh` checks (2-WORKING, scoped via `PDDA_ONLY_FILE`) / a lightweight inline frontmatter check (inbox captures — the `pdda.sh` checks intentionally don't scan `1-INBOX`); (2) **makes the safe mechanical contract edit** by delegating to `PDDA_LLM_BIN` (same convention as `pdda.sh doc-ready`/`pdda-catchup.sh`); (3) **logs** each edit/change to a telemetry JSONL at `utils/telemetry/preflight-log/YYYY-MM-DD.jsonl`; (4) **warns (no edit)** whenever the fix is unsafe or under-specified.
+- **Safety valve (deterministic):** a candidate edit is applied only if the deterministic findings **strictly improve** (`after < before`) **and** the diff is small/mechanical (`≤ PREFLIGHT_MAX_EDIT_LINES`, default 30); otherwise it's reverted from a temp backup (preserving any pre-existing WIP) and logged as an unsafe-edit `warn`. Clean docs skip the LLM entirely.
+- **Posture:** always exits 0 (never blocks — an LLM oracle must be non-deterministic-safe, per PDDA.md); off by default (a no-op edit-wise unless `PDDA_LLM_BIN` is set — with it unset the deterministic pass still runs and `warn`s docs needing a manual fix); **never auto-commits/pushes** (working-tree edits only; a human reviews `git diff` + the log). Scheduler is **pluggable** — launchd (recommended; sample plist in the script header) / Claude Code scheduled task / Claude Desktop; it does **not** have to be a Claude Desktop job.
+- **Bug found + fixed while building:** the model-call captured stdout with `|| resp=""`, which **discarded a valid envelope whenever the model CLI exited non-zero** (a rate-limit/deprecation notice on a successful run). Changed to `|| true` so output survives a non-zero exit.
+- **Tests:** `test/preflight-docs.sh` (offline, stub `PDDA_LLM_BIN`) covers no-LLM warn, clean pass, safe edit applied, unsafe edit reverted, model-declined warn, ROADMAP-queued inbox targeting, and JSONL validity (14/14). Wired into `validate.sh`. `utils/telemetry/preflight-log/` gitignored.
+
+**Bet (Easy/reversible):** an unattended job that *edits docs* is bounded to safety by three deterministic guards — off-by-default, strict-improvement-only + small-diff safety valve, and never-commit — so a wrong edit costs one ignorable working-tree change a human reverts, never a bad commit. Revisit trigger: if field logs show the LLM repeatedly rejected on the small-diff cap for legitimate multi-key fixes, raise `PREFLIGHT_MAX_EDIT_LINES` or split per-key. Not promoted to `2-WORKING` yet — awaiting a scope/posture confirm.
+
 ### GH-75 SHIPPED — XYZ.json final-completion telemetry at every harness session end
 All three harnesses (relay, marathon, swarm) now append a durable, newest-first completion record to a gitignored `XYZ.json` at the harness repo root — the live per-session signal GH-24's on-demand batch extractor never provided. Schema extends GH-24's `{health, title, description, updatedAt}` with `{harness, sessionId}`.
 
diff --git a/PROJECT/1-INBOX/GH-78-DOC-PREFLIGHT-AUTOMATION.md b/PROJECT/1-INBOX/GH-78-DOC-PREFLIGHT-AUTOMATION.md
new file mode 100644
index 0000000..0cbde6c
--- /dev/null
+++ b/PROJECT/1-INBOX/GH-78-DOC-PREFLIGHT-AUTOMATION.md
@@ -0,0 +1,115 @@
+---
+gh_issue: 78
+source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/78
+title: Optional hourly doc-preflight — contract-enforcing auto-edits for 2-WORKING + ROADMAP-queued docs, logged to telemetry
+status: Proposed (1-INBOX — not yet active)
+created: 2026-07-02
+updated: 2026-07-02
+owner: noel
+doc_type: feature
+effort: 3
+complexity: 3
+risk: 2
+phases: 3
+ratings_provisional: true
+non_goals:
+  - Not a blocking gate — the preflight always exits 0 and can never fail a build (LLM-layer calibration, same as pdda.sh doc-ready).
+  - Not auto-committing or pushing its edits — edits land in the working tree only; a human reviews git diff + the telemetry log.
+  - Not replacing the deterministic pdda.sh checks or the doc-ready review — it composes them.
+  - Not rewriting nuanced plan content — only mechanical, contract-level edits; anything requiring judgment becomes a warn.
+related:
+  - PROJECT/PDDA.md
+  - utils/pdda/pdda.sh
+  - utils/pdda/pdda-catchup.sh
+  - utils/telemetry/append-xyz-completion.sh
+roadmap_exempt: false
+---
+
+# GH-78 · Optional hourly doc-preflight (contract-enforcing auto-edits + telemetry log)
+
+**Why:** PDDA's deterministic checks only *flag* and the LLM `doc-ready` review only *advises* — neither
+*fixes* a contract violation. The common, mechanical drift (a missing frontmatter key, a status-table
+header that isn't exactly `What was just completed | What's next`, a missing `ROADMAP.md` pointer) still
+needs a human to open the doc and edit it. This adds a best-effort, off-by-default hourly job that makes
+the *safe* edits itself, logs every change to the telemetry folder, and warns (without editing) whenever
+a fix is unsafe or under-specified.
+
+## Status
+
+| What was just completed | What's next |
+|---|---|
+| Issue [#78](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/78) opened, doc captured, parked in ROADMAP; v1 `utils/telemetry/preflight-docs.sh` + `test/preflight-docs.sh` built and wired into `validate.sh`. | Confirm scope + the never-auto-commit posture, promote to `2-WORKING`, then decide the scheduler (launchd vs Claude Code scheduled task) and enable it with `PDDA_LLM_BIN` set. |
+
+## Table of contents
+
+- [Status](#status)
+- [Phase 1 — deterministic scaffolding + telemetry log](#phase-1--deterministic-scaffolding--telemetry-log)
+- [Phase 2 — gated LLM edit step + safety valve](#phase-2--gated-llm-edit-step--safety-valve)
+- [Phase 3 — scheduling](#phase-3--scheduling)
+
+## Design summary
+
+Targets = every doc in `PROJECT/2-WORKING/` **plus** every `PROJECT/1-INBOX/GH-*.md` capture parked in
+`ROADMAP.md`'s queue. For each target the script:
+
+1. **Reviews** — runs the deterministic `pdda.sh` single-file checks (scoped via `PDDA_ONLY_FILE`) to
+   learn *exactly* what contract violations exist. No guessing.
+2. **Edits (safely)** — if `PDDA_LLM_BIN` is set, asks the model for a corrected copy of the doc via a
+   tightly-scoped rubric (mechanical contract fixes only). The candidate is written back **only if** the
+   deterministic findings do not get *worse* (the safety valve).
+3. **Logs** — appends an `edit` telemetry record (doc, findings resolved, model) to
+   `utils/telemetry/preflight-log/YYYY-MM-DD.jsonl`.
+4. **Warns** — a candidate that would worsen the contract, or a violation the model declined to fix, is
+   logged as a `warn` record with `safe:false` and **no edit is made**.
+
+### Safety posture (inherits PDDA's philosophy)
+
+- Best-effort, **always exits 0** — never blocks a build (LLM oracle must be non-deterministic-safe).
+- **Off by default** — a no-op edit-wise unless `PDDA_LLM_BIN` is set; with it unset the deterministic
+  pass still runs and logs `warn`s for docs needing a manual fix.
+- **Never auto-commits/pushes** — working-tree edits only; fully reversible (Easy). Bet: an unattended
+  job that also commits is a One-way-door-shaped risk we deliberately decline for v1.
+- Deterministic safety valve + single-file-scoped LLM invocations bound the blast radius.
+
+## Phase 1 — deterministic scaffolding + telemetry log
+
+- [ ] Target resolution: `PROJECT/2-WORKING/*.md` (minus `blank.md`) + the `GH-*.md` inbox docs whose
+      repo-relative path appears in `ROADMAP.md`.
+- [ ] Telemetry logger: append-only JSONL at `utils/telemetry/preflight-log/YYYY-MM-DD.jsonl`
+      (`{timestamp, doc, action, safe, summary, findings_before, findings_after, model}`); gitignored.
+- [ ] Deterministic pass: run `pdda.sh` scoped to each file, count findings before any edit.
+
+### QA gate — Phase 1
+
+- [ ] With `PDDA_LLM_BIN` unset the script exits 0, edits nothing, and writes one telemetry line per
+      target (`skip`/`clean`/`warn`), proven by `test/preflight-docs.sh`.
+
+## Phase 2 — gated LLM edit step + safety valve
+
+- [ ] When `PDDA_LLM_BIN` is set, per-file: send content + rubric, receive a JSON envelope
+      (`action: edit|warn|clean`, `content`, `reason`).
+- [ ] Apply an `edit` only if the deterministic findings after ≤ before **and** no new `error`; else
+      revert (`git checkout -- <file>`) and log a `warn` (`safe:false`).
+- [ ] Log an `edit`/`warn`/`clean` telemetry record accordingly.
+
+### QA gate — Phase 2
+
+- [ ] A stub `PDDA_LLM_BIN` that returns a valid contract-fixing edit → the edit is applied + logged.
+- [ ] A stub that returns a contract-worsening edit → reverted, `warn` logged, file unchanged.
+- [ ] A stub that returns `action:warn` (insufficient guidance) → no edit, `warn` logged.
+
+## Phase 3 — scheduling
+
+Answer to "does it have to be a Claude Desktop scheduled job?" — **no.** The script is the deliverable;
+the scheduler is pluggable:
+
+- **launchd** (macOS) hourly agent → `PDDA_LLM_BIN=claude utils/telemetry/preflight-docs.sh`
+  (recommended; matches PDDA.md's "Suggested hourly schedule" cadence). Sample plist in the script header.
+- **Claude Code scheduled task** — the harness-native cron; runs the preflight prompt/skill hourly with
+  no separate `claude -p` wiring.
+- **Claude Desktop scheduled job** — works, but is not required and is the least reproducible.
+
+### QA gate — Phase 3
+
+- [ ] The sample launchd plist runs the script hourly against a real clone and produces a dated telemetry
+      log with at least one record (operator litmus — a scheduler smoke test, not a `validate.sh` gate).
diff --git a/ROADMAP-DASHBOARD.md b/ROADMAP-DASHBOARD.md
index 7d79c27..bc1699f 100644
--- a/ROADMAP-DASHBOARD.md
+++ b/ROADMAP-DASHBOARD.md
@@ -6,10 +6,11 @@ Read-only derived view of the root [ROADMAP.md](ROADMAP.md) ledger.
 
 ## Queue / parked intake
 
-Summary: 16 items | Tally: 🟢 0 · 🟡 5 · ⏸️ 1 · ⛔ 0 · ✅ 0 · 🔮 0 · 🔲 0
+Summary: 17 items | Tally: 🟢 0 · 🟡 5 · ⏸️ 1 · ⛔ 0 · ✅ 0 · 🔮 0 · 🔲 0
 
 | Item | Status | Links |
 | --- | --- | --- |
+| GH-78 · Optional hourly doc-preflight (contract-enforcing auto-edits + telemetry log) | — | [GH-78-DOC-PREFLIGHT-AUTOMATION.md](PROJECT/1-INBOX/GH-78-DOC-PREFLIGHT-AUTOMATION.md) · [#78](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/78) |
 | GH-63 · Signal triage stage for inbound signals before GH-*.md capture | — | [GH-63-SIGNAL-TRIAGE-STAGE.md](PROJECT/1-INBOX/GH-63-SIGNAL-TRIAGE-STAGE.md) · [#63](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/63) |
 | GH-61 · CI GitHub Actions (Tier 1 lint/doc-hygiene + Tier 2 validate.sh) | — | [GH-61-CI-GITHUB-ACTIONS.md](PROJECT/1-INBOX/GH-61-CI-GITHUB-ACTIONS.md) · [#61](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/61) |
 | GH-45 · QUEUE 'must-complete' commitment contract + anti-rabbit-hole safeguard | — | [GH-45-QUEUE-COMMITMENT-CONTRACT.md](PROJECT/1-INBOX/GH-45-QUEUE-COMMITMENT-CONTRACT.md) · [#45](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/45) |
diff --git a/ROADMAP.md b/ROADMAP.md
index d17c42a..c4a5d18 100644
--- a/ROADMAP.md
+++ b/ROADMAP.md
@@ -67,6 +67,7 @@ Mechanical / pattern-following work → **Sonnet High**; trust-critical kernel-c
 ## Ledger
 
 ### Queue / parked intake
+- **GH-78 · Optional hourly doc-preflight (contract-enforcing auto-edits + telemetry log)** 🆕 **captured 2026-07-02 · parked** — PDDA's deterministic checks only *flag* and `doc-ready` only *advises*; neither *fixes* a contract violation. Proposed: an optional, off-by-default, best-effort **hourly** `utils/telemetry/preflight-docs.sh` that reviews every `PROJECT/2-WORKING/` doc + every ROADMAP-queued `1-INBOX/GH-*.md`, makes the *safe* mechanical contract edits (via `PDDA_LLM_BIN`, reusing the `pdda.sh`/`pdda-catchup.sh` convention), logs each edit/change to a telemetry JSONL under `utils/telemetry/preflight-log/`, and emits a `warn` (no edit) whenever a fix is unsafe or under-specified. Never blocks (exits 0), never auto-commits, deterministic safety valve rejects a contract-worsening edit. v1 script + `test/preflight-docs.sh` built + wired into `validate.sh`; scheduler is pluggable (launchd / Claude Code scheduled task / Claude Desktop — not required to be the last). → [GH-78-DOC-PREFLIGHT-AUTOMATION.md](PROJECT/1-INBOX/GH-78-DOC-PREFLIGHT-AUTOMATION.md) · [#78](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/78)
 - **GH-63 · Signal triage stage for inbound signals before GH-*.md capture** 🆕 **captured 2026-06-30 · parked** — no triage step today classifies an inbound signal's severity/category before the issue-first SOP fires (it starts at "open a GitHub issue"). Proposed: a deterministic pre-capture step that tags any inbound signal (failing `validate.sh` test, relay escalation, manually filed bug) with a severity/category (bug / drift / enhancement / noise) and produces an inspectable artifact before the `GH-*.md` is created. Reuses existing signal sources (relay `watchdog.sh` `parked_suspects[]`, `validate.sh` failures, manually filed issues). Additive; wired into `ROUTER.md` routing hints. → [GH-63-SIGNAL-TRIAGE-STAGE.md](PROJECT/1-INBOX/GH-63-SIGNAL-TRIAGE-STAGE.md) · [#63](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/63)
 - **GH-61 · CI GitHub Actions (Tier 1 lint/doc-hygiene + Tier 2 validate.sh)** 🆕 **captured 2026-06-30 · parked** — no CI today; add Actions to catch the ~80% (bash logic + doc/path drift). **Tier 1** (cheap, always-green, no auth): `shellcheck` + `bash -n` on all `*.sh`, `node --check`/JSON-validate, `utils/pdda/pdda.sh run` full-mode. **Tier 2** (the real gate): `./validate.sh` 69-test suite — needs a portability + live-agent skip-gating pass, and a runner decision (`macos-latest` fast/~10× minutes vs `ubuntu` cheap/needs the pass) left open; don't make it *required* until reliably green. Marathon-sequenceable: Tier 1 = independent quick-win lane; Tier 2 depends on the skip-gating sub-task. → [GH-61-CI-GITHUB-ACTIONS.md](PROJECT/1-INBOX/GH-61-CI-GITHUB-ACTIONS.md) · [#61](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/61)
 - **GH-45 · QUEUE 'must-complete' commitment contract + anti-rabbit-hole safeguard** 🆕 **captured 2026-06-28 · parked** — make a wave/lane a *commitment contract* so a session can't silently abandon the plan to deep-dive one item (the GH-39 drift): per-lane `max_attempts`/`out_of_scope`/`on_failure=park`, an enforced **attempt cap** (refuse-to-re-fire + surface), a re-anchor checkpoint, and a marathon-plan drift signal. Remediation plan captured ([GH-45-QUEUE-COMMITMENT-CONTRACT.md](PROJECT/1-INBOX/GH-45-QUEUE-COMMITMENT-CONTRACT.md)) — Phase 1+2 (lane contract + attempt-cap) are the core; 3 mostly free; 4 nice-to-have. → [#45](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/45)
diff --git a/test/preflight-docs.sh b/test/preflight-docs.sh
new file mode 100755
index 0000000..9ab93ca
--- /dev/null
+++ b/test/preflight-docs.sh
@@ -0,0 +1,160 @@
+#!/usr/bin/env bash
+# test/preflight-docs.sh — GH-78: offline coverage for utils/telemetry/preflight-docs.sh.
+# Uses a STUB PDDA_LLM_BIN (no real model) to exercise every branch: no-LLM warn, clean pass, a safe
+# contract-enforcing edit that is APPLIED, an unsafe edit that is REJECTED+reverted, a model-declined
+# warn, and inbox-capture (ROADMAP-queued) targeting.
+source "$(dirname "$0")/_setup.sh" preflight-docs
+ROOT="$(cd "$(dirname "$0")/.." && pwd)"
+SCRIPT="$ROOT/utils/telemetry/preflight-docs.sh"
+
+REPO="$WORK/repo"
+mkdir -p "$REPO/PROJECT/2-WORKING" "$REPO/PROJECT/1-INBOX"
+
+# ── fixture docs ─────────────────────────────────────────────────────────────
+# A fully contract-clean working doc.
+cat >"$REPO/PROJECT/2-WORKING/CLEAN.md" <<'EOF'
+---
+title: Clean doc
+status: Active
+created: 2026-06-24
+updated: 2026-06-24
+owner: test
+goal: stay clean
+---
+
+## Status
+
+| What was just completed | What's next |
+|---|---|
+| seeded | verify |
+EOF
+
+# The broken working doc: missing the required `goal` key (exactly 1 deterministic error).
+ORIG="$WORK/broken-orig.md"
+cat >"$ORIG" <<'EOF'
+---
+title: Broken doc
+status: Active
+created: 2026-06-24
+updated: 2026-06-24
+owner: test
+---
+
+## Status
+
+| What was just completed | What's next |
+|---|---|
+| seeded | verify |
+EOF
+
+# The contract-clean corrected version the stub returns for the "fix" case (adds `goal`).
+FIXED="$WORK/broken-fixed.md"
+cat >"$FIXED" <<'EOF'
+---
+title: Broken doc
+status: Active
+created: 2026-06-24
+updated: 2026-06-24
+owner: test
+goal: added by preflight
+---
+
+## Status
+
+| What was just completed | What's next |
+|---|---|
+| seeded | verify |
+EOF
+
+# A broken inbox capture parked in ROADMAP (missing required `doc_type`).
+cat >"$REPO/PROJECT/1-INBOX/GH-9001-TEST.md" <<'EOF'
+---
+gh_issue: 9001
+source: https://example.com/issues/9001
+title: Test intake
+status: Proposed (1-INBOX — not yet active)
+created: 2026-06-24
+---
+
+Short capture.
+EOF
+
+cat >"$REPO/ROADMAP.md" <<'EOF'
+# Roadmap
+
+## Queue / parked intake
+
+- Test intake → [GH-9001-TEST.md](PROJECT/1-INBOX/GH-9001-TEST.md)
+EOF
+
+BROKEN="$REPO/PROJECT/2-WORKING/BROKEN.md"
+seed_broken() { cp "$ORIG" "$BROKEN"; }
+
+# ── stub model CLI ───────────────────────────────────────────────────────────
+STUB="$WORK/stub-llm.sh"
+cat >"$STUB" <<'EOF'
+#!/usr/bin/env bash
+cat >/dev/null   # consume the prompt on stdin
+case "${STUB_MODE:-}" in
+  fix)    printf 'ACTION: edit\nREASON: added missing goal key\n---BEGIN-DOC---\n'; cat "$STUB_FIXED_DOC"; printf '%s\n' '---END-DOC---' ;;
+  unsafe) printf 'ACTION: edit\nREASON: pretend fix\n---BEGIN-DOC---\n';           cat "$STUB_ORIG_DOC";  printf '%s\n' '---END-DOC---' ;;
+  warn)   printf 'ACTION: warn\nREASON: needs human judgment\n' ;;
+  *)      printf 'ACTION: clean\nREASON: n/a\n' ;;
+esac
+EOF
+chmod +x "$STUB"
+
+run_preflight() {  # run_preflight <logdir> [PDDA_LLM_BIN]
+  local logdir="$1" bin="${2:-}"
+  PDDA_REPO_ROOT="$REPO" \
+  PDDA_WORKING_DIR="$REPO/PROJECT/2-WORKING" \
+  PDDA_INBOX_DIR="$REPO/PROJECT/1-INBOX" \
+  PDDA_ROADMAP="$REPO/ROADMAP.md" \
+  PREFLIGHT_LOG_DIR="$logdir" \
+  PDDA_LLM_BIN="$bin" \
+  STUB_MODE="${STUB_MODE:-}" STUB_FIXED_DOC="$FIXED" STUB_ORIG_DOC="$ORIG" \
+  bash "$SCRIPT" >/dev/null 2>&1
+}
+
+logline() { grep "\"doc\": \"[^\"]*$1\"" "$2/$(date +%Y-%m-%d).jsonl" 2>/dev/null; }
+has() { logline "$1" "$3" | grep -q "\"action\": \"$2\""; }
+
+# ── Case 1: no LLM — review+warn only, no edits ──────────────────────────────
+seed_broken
+L1="$WORK/log1"; run_preflight "$L1" ""
+rc=$?
+[ "$rc" -eq 0 ] && pass "exits 0 with no PDDA_LLM_BIN (never blocks)" || fail "non-zero exit ($rc) with no LLM"
+has BROKEN.md warn "$L1"   && pass "no-LLM: broken working doc logged as warn" || fail "no-LLM: broken doc not warned"
+has CLEAN.md clean "$L1"   && pass "no-LLM: clean working doc logged as clean" || fail "no-LLM: clean doc not marked clean"
+has GH-9001-TEST.md warn "$L1" && pass "no-LLM: ROADMAP-queued inbox capture is targeted + warned" || fail "inbox capture not targeted"
+grep -q '"goal"' "$BROKEN" && fail "no-LLM run edited the doc (must not)" || pass "no-LLM: doc left unedited"
+
+# ── Case 2: model declines (ACTION: warn) — no edit ──────────────────────────
+seed_broken
+L2="$WORK/log2"; STUB_MODE=warn run_preflight "$L2" "$STUB"
+has BROKEN.md warn "$L2" && pass "model-declines: logged as warn" || fail "model-declines: not warned"
+grep -q '"goal"' "$BROKEN" && fail "model-declines run edited the doc" || pass "model-declines: doc left unedited"
+
+# ── Case 3: unsafe edit (no improvement) — reverted + warn ───────────────────
+seed_broken
+L3="$WORK/log3"; STUB_MODE=unsafe run_preflight "$L3" "$STUB"
+has BROKEN.md warn "$L3" && pass "unsafe-edit: rejected and logged as warn" || fail "unsafe-edit: not warned"
+logline BROKEN.md "$L3" | grep -q 'unsafe edit reverted' && pass "unsafe-edit: summary records the revert" || fail "unsafe-edit: revert not recorded"
+grep -q '"goal"' "$BROKEN" && fail "unsafe-edit was NOT reverted (doc changed)" || pass "unsafe-edit: doc reverted to original"
+
+# ── Case 4: safe edit — applied + logged ─────────────────────────────────────
+seed_broken
+L4="$WORK/log4"; STUB_MODE=fix run_preflight "$L4" "$STUB"
+has BROKEN.md edit "$L4" && pass "safe-edit: logged as edit" || fail "safe-edit: not logged as edit"
+logline BROKEN.md "$L4" | grep -q '"safe": true' && pass "safe-edit: marked safe" || fail "safe-edit: not marked safe"
+grep -q '^goal: added by preflight' "$BROKEN" && pass "safe-edit: contract fix applied to the doc" || fail "safe-edit: fix not written"
+
+# ── every telemetry line is valid JSON ───────────────────────────────────────
+python3 -c "import json,glob,sys
+for f in glob.glob('$WORK/log*/*.jsonl'):
+    for ln in open(f):
+        json.loads(ln)
+print('ok')" >/dev/null 2>&1 && pass "all telemetry lines are valid JSON" || fail "telemetry produced invalid JSON"
+
+echo "  $TEST_NAME: $PASS pass, $FAIL fail"
+exit 0
diff --git a/utils/telemetry/preflight-docs.sh b/utils/telemetry/preflight-docs.sh
new file mode 100755
index 0000000..67153fd
--- /dev/null
+++ b/utils/telemetry/preflight-docs.sh
@@ -0,0 +1,280 @@
+#!/usr/bin/env bash
+set -u
+#
+# preflight-docs.sh — GH-78: optional, best-effort, hourly doc PREFLIGHT.
+#
+# For every active doc in PROJECT/2-WORKING/ and every PROJECT/1-INBOX/GH-*.md capture that is parked in
+# ROADMAP.md, this:
+#   1. REVIEWS the doc against the PDDA contract — reusing the deterministic pdda.sh checks (for
+#      2-WORKING docs) / a lightweight inline frontmatter check (for inbox captures) to learn EXACTLY
+#      what is wrong. No guessing.
+#   2. Makes SAFE, contract-enforcing EDITS where the fix is unambiguous, delegating the edit judgment to
+#      an LLM (PDDA_LLM_BIN — the same convention pdda.sh doc-ready / pdda-catchup.sh already use).
+#   3. LOGS every edit/change to an append-only telemetry JSONL beside this telemetry folder
+#      (utils/telemetry/preflight-log/YYYY-MM-DD.jsonl).
+#   4. Emits a WARN log entry (and makes NO edit) whenever the fix is not safe or there is not enough
+#      guidance to edit — the safety valve.
+#
+# SAFETY POSTURE (inherits PDDA's philosophy — see PROJECT/PDDA.md):
+#   * best-effort, ALWAYS exits 0 — never blocks a build (an LLM oracle must be non-deterministic-safe).
+#   * OFF BY DEFAULT edit-wise: a no-op unless PDDA_LLM_BIN is set to a model CLI (claude/codex/agy).
+#     With it unset the deterministic pass still runs and WARNs on docs that need a manual fix.
+#   * NEVER auto-commits or pushes — edits land in the working tree only; a human reviews git diff + log.
+#   * deterministic safety valve: a candidate edit is applied only if the deterministic findings do not
+#     get worse AND the diff is small (mechanical), else it is reverted from a backup and WARNed.
+#
+# SCHEDULING ("does it have to be a Claude Desktop scheduled job?" — NO). The script is the deliverable;
+# the scheduler is pluggable. Recommended: a macOS launchd hourly agent (matches PDDA.md's "Suggested
+# hourly schedule"). Sample ~/Library/LaunchAgents/com.xyz.preflight-docs.plist:
+#
+#   <?xml version="1.0" encoding="UTF-8"?>
+#   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
+#   <plist version="1.0"><dict>
+#     <key>Label</key><string>com.xyz.preflight-docs</string>
+#     <key>ProgramArguments</key><array>
+#       <string>/bin/bash</string>
+#       <string>/ABSOLUTE/PATH/TO/xyz-3-agents-swarm/utils/telemetry/preflight-docs.sh</string>
+#     </array>
+#     <key>EnvironmentVariables</key><dict><key>PDDA_LLM_BIN</key><string>claude</string></dict>
+#     <key>StartInterval</key><integer>3600</integer>
+#     <key>RunAtLoad</key><true/>
+#   </dict></plist>
+#
+# Then: launchctl load ~/Library/LaunchAgents/com.xyz.preflight-docs.plist
+# Alternatives: a Claude Code scheduled task (harness-native cron), or a Claude Desktop scheduled job.
+#
+# Usage: [PDDA_LLM_BIN=claude] utils/telemetry/preflight-docs.sh
+# Env knobs:
+#   PDDA_LLM_BIN            model CLI to delegate edits to (unset => review+warn only, no edits)
+#   PDDA_LLM_ARGS          args passed to the model CLI (default "-p")
+#   PDDA_LLM_MODEL         optional --model value
+#   PREFLIGHT_LOG_DIR      telemetry log dir (default <this dir>/preflight-log)
+#   PREFLIGHT_MAX_EDIT_LINES  reject a candidate edit whose changed-line count exceeds this (default 30)
+#   PDDA_REPO_ROOT / PDDA_WORKING_DIR / PDDA_INBOX_DIR  standard PDDA overrides (used for tests)
+#   PDDA_ROADMAP           ROADMAP.md path (default <repo root>/ROADMAP.md)
+
+HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
+# shellcheck source=utils/pdda/pdda-lib.sh
+. "$HERE/../pdda/pdda-lib.sh"
+
+PDDA_SH="$HERE/../pdda/pdda.sh"
+PDDA_ROADMAP="${PDDA_ROADMAP:-$PDDA_REPO_ROOT/ROADMAP.md}"
+PREFLIGHT_LOG_DIR="${PREFLIGHT_LOG_DIR:-$HERE/preflight-log}"
+PREFLIGHT_MAX_EDIT_LINES="${PREFLIGHT_MAX_EDIT_LINES:-30}"
+PDDA_LLM_BIN="${PDDA_LLM_BIN:-}"
+PDDA_LLM_ARGS="${PDDA_LLM_ARGS:--p}"
+
+RUN_ID="preflight-$(date -u +%Y%m%dT%H%M%SZ)-$$"
+MODEL_LABEL="${PDDA_LLM_BIN:-none}"
+[ -n "${PDDA_LLM_MODEL:-}" ] && MODEL_LABEL="$PDDA_LLM_BIN:$PDDA_LLM_MODEL"
+
+EDITS=0 WARNS=0 CLEANS=0
+
+# ── telemetry logger ─────────────────────────────────────────────────────────
+# One JSON object per line, appended to a daily file — same JSONL spirit as XYZ.json / PDDA-ACTIVITY.
+_pf_log() {
+  # _pf_log <doc> <action> <safe> <before> <after> <changed> <summary>
+  local logf; logf="$PREFLIGHT_LOG_DIR/$(date +%Y-%m-%d).jsonl"
+  mkdir -p "$PREFLIGHT_LOG_DIR" 2>/dev/null || true
+  python3 - "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$MODEL_LABEL" "$RUN_ID" >>"$logf" <<'PY'
+import sys, json, datetime
+doc, action, safe, before, after, changed, summary, model, run_id = sys.argv[1:10]
+print(json.dumps({
+    "timestamp": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
+    "run_id": run_id,
+    "doc": doc,
+    "action": action,           # edit | warn | clean | skip
+    "safe": safe == "true",
+    "before_errors": int(before),
+    "after_errors": int(after),
+    "changed_lines": int(changed),
+    "model": model,
+    "summary": summary,
+}))
+PY
+}
+
+# ── deterministic contract error count ───────────────────────────────────────
+# 2-WORKING: authoritative — sum the error totals of the scoped pdda.sh checks (they scan 2-WORKING only,
+# so PDDA_ONLY_FILE cleanly isolates the one doc). INBOX: lightweight inline frontmatter check, because
+# the pdda.sh checks intentionally do not scan 1-INBOX and inbox captures carry a lighter contract.
+_pf_errors() {
+  local file="$1" kind="$2" total=0 out sumline n key
+  if [ "$kind" = working ]; then
+    local check
+    for check in frontmatter status-table hardcoded-paths; do
+      out="$(PDDA_FORMAT=json PDDA_MODE=observe PDDA_ONLY_FILE="$file" "$PDDA_SH" "$check" 2>/dev/null)"
+      sumline="$(printf '%s\n' "$out" | grep '"action":"summary"' | tail -1)"
+      n="$(printf '%s' "$sumline" | sed -n 's/.*errors=\([0-9][0-9]*\).*/\1/p')"
+      total=$((total + ${n:-0}))
+    done
+  else
+    # inbox capture contract (PDDA.md "GitHub issue intake"): required minimum keys.
+    if ! pdda_has_frontmatter "$file"; then
+      total=$((total + 1))
+    else
+      for key in gh_issue source title status created doc_type; do
+        if ! pdda_frontmatter_has_key "$file" "$key" \
+           || [ -z "$(pdda_trim "$(pdda_frontmatter_value "$file" "$key")")" ]; then
+          total=$((total + 1))
+        fi
+      done
+    fi
+    # cheap absolute-path scan (mirrors pdda.sh hardcoded-paths intent) outside fenced blocks.
+    n="$(grep -nE '/Users/|/private/|/home/[^/]+/|file://|[A-Za-z]:\\\\' "$file" 2>/dev/null | grep -cvE '^\s*[0-9]+:\s*[`>]' || true)"
+    total=$((total + ${n:-0}))
+  fi
+  printf '%s' "$total"
+}
+
+# ── LLM edit rubric ──────────────────────────────────────────────────────────
+read -r -d '' RUBRIC <<'RUBRIC_EOF' || true
+You are a documentation CONTRACT ENFORCER for this repo's PDDA system. You are given ONE markdown doc and
+the deterministic contract violations found in it. Make ONLY the minimal, MECHANICAL edits required to
+satisfy the contract:
+  - add a MISSING required frontmatter key with a correct, faithful value
+      (2-WORKING docs need: title, status, created, updated, owner, goal; dates are YYYY-MM-DD)
+      (1-INBOX GH captures need: gh_issue, source, title, status, created, doc_type)
+  - fix a status-table header to be EXACTLY:  What was just completed | What's next
+  - fill a BLANK status-table cell with a faithful, minimal value drawn from the doc
+  - repoint an obvious hardcoded absolute path (/Users/..., /home/..., file://...) to a repo-relative one
+Do NOT rewrite prose, restructure sections, reorder content, change meaning, or fix anything that needs
+judgment or information you do not have. If the safe fix is unclear, DO NOT edit — warn instead.
+
+Respond in EXACTLY this format and NOTHING else:
+ACTION: <edit|warn|clean>
+REASON: <one short line>
+---BEGIN-DOC---
+<the FULL corrected document — include this section ONLY when ACTION is edit>
+---END-DOC---
+
+ACTION meanings: edit = you made safe mechanical fixes (full corrected doc follows);
+clean = already compliant, no change; warn = a fix is needed but is not safe/mechanical for you to make.
+RUBRIC_EOF
+
+# ── per-doc preflight ────────────────────────────────────────────────────────
+preflight_one() {
+  local file="$1" kind="$2" rel before after changed resp action reason newdoc backup findings
+  rel="$(pdda_relpath "$file")"
+  before="$(_pf_errors "$file" "$kind")"
+
+  if [ "${before:-0}" -eq 0 ]; then
+    CLEANS=$((CLEANS + 1))
+    printf 'CLEAN  %s (contract satisfied)\n' "$rel"
+    _pf_log "$rel" clean true "$before" "$before" 0 "contract already satisfied"
+    return
+  fi
+
+  # before>0: the doc has contract violations. Without an LLM we can only flag them.
+  if [ -z "$PDDA_LLM_BIN" ] || ! command -v "$PDDA_LLM_BIN" >/dev/null 2>&1; then
+    WARNS=$((WARNS + 1))
+    printf 'WARN   %s — %s contract error(s); set PDDA_LLM_BIN to auto-fix, else fix by hand\n' "$rel" "$before"
+    _pf_log "$rel" warn false "$before" "$before" 0 "$before contract error(s); no PDDA_LLM_BIN — manual fix needed"
+    return
+  fi
+
+  # gather the deterministic findings so the model knows precisely what to fix.
+  if [ "$kind" = working ]; then
+    findings="$(PDDA_FORMAT=text PDDA_MODE=observe PDDA_ONLY_FILE="$file" "$PDDA_SH" frontmatter 2>/dev/null; \
+                PDDA_FORMAT=text PDDA_MODE=observe PDDA_ONLY_FILE="$file" "$PDDA_SH" status-table 2>/dev/null; \
+                PDDA_FORMAT=text PDDA_MODE=observe PDDA_ONLY_FILE="$file" "$PDDA_SH" hardcoded-paths 2>/dev/null)"
+  else
+    findings="(inbox capture) $before missing/empty required frontmatter key(s) or hardcoded path(s)"
+  fi
+
+  local -a llm_args
+  read -ra llm_args <<<"$PDDA_LLM_ARGS"
+  [ -n "${PDDA_LLM_MODEL:-}" ] && llm_args+=(--model "$PDDA_LLM_MODEL")
+
+  local prompt
+  prompt="$RUBRIC
+
+=== DETERMINISTIC CONTRACT VIOLATIONS ($rel) ===
+$findings
+
+=== DOCUMENT ($rel) ===
+$(cat "$file")
+"
+  # Capture stdout regardless of the CLI's exit code — a model CLI can exit non-zero (a rate-limit
+  # notice, a deprecation warning) yet still print a valid envelope; discarding it would waste the turn.
+  resp="$(printf '%s' "$prompt" | "$PDDA_LLM_BIN" ${llm_args[@]+"${llm_args[@]}"} 2>/dev/null)" || true
+
+  action="$(printf '%s\n' "$resp" | sed -n 's/^ACTION:[[:space:]]*//p' | head -1 | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
+  reason="$(printf '%s\n' "$resp" | sed -n 's/^REASON:[[:space:]]*//p' | head -1)"
+  reason="$(pdda_trim "${reason:-no reason given}")"
+
+  case "$action" in
+    edit)
+      newdoc="$(printf '%s\n' "$resp" | awk '/^---BEGIN-DOC---[[:space:]]*$/{f=1;next} /^---END-DOC---[[:space:]]*$/{f=0} f')"
+      if [ -z "$newdoc" ]; then
+        WARNS=$((WARNS + 1))
+        printf 'WARN   %s — model said edit but returned no document body\n' "$rel"
+        _pf_log "$rel" warn false "$before" "$before" 0 "edit action with empty doc body — no change"
+        return
+      fi
+      backup="$(mktemp)"; cp "$file" "$backup"
+      printf '%s\n' "$newdoc" > "$file"
+      after="$(_pf_errors "$file" "$kind")"
+      changed="$(diff "$backup" "$file" | grep -cE '^[<>]' || true)"
+      # SAFETY VALVE: keep only a strictly-improving, small (mechanical) edit; else revert + warn.
+      if [ "${after:-99}" -lt "${before}" ] && [ "${changed:-9999}" -le "$PREFLIGHT_MAX_EDIT_LINES" ]; then
+        EDITS=$((EDITS + 1))
+        printf 'EDIT   %s — %s→%s error(s), %s line(s): %s\n' "$rel" "$before" "$after" "$changed" "$reason"
+        _pf_log "$rel" edit true "$before" "$after" "$changed" "$reason"
+      else
+        cp "$backup" "$file"   # revert from backup (preserves any pre-existing WIP)
+        WARNS=$((WARNS + 1))
+        printf 'WARN   %s — unsafe edit rejected (%s→%s error(s), %s line(s)); reverted\n' "$rel" "$before" "$after" "$changed"
+        _pf_log "$rel" warn false "$before" "$after" "$changed" "unsafe edit reverted: $reason"
+      fi
+      rm -f "$backup"
+      ;;
+    warn)
+      WARNS=$((WARNS + 1))
+      printf 'WARN   %s — model declined to auto-fix: %s\n' "$rel" "$reason"
+      _pf_log "$rel" warn false "$before" "$before" 0 "model declined: $reason"
+      ;;
+    clean)
+      # model says clean but the deterministic layer disagrees — trust the deterministic layer, warn.
+      WARNS=$((WARNS + 1))
+      printf 'WARN   %s — %s deterministic error(s) but model reported clean\n' "$rel" "$before"
+      _pf_log "$rel" warn false "$before" "$before" 0 "model reported clean but $before deterministic error(s) remain"
+      ;;
+    *)
+      WARNS=$((WARNS + 1))
+      printf 'WARN   %s — unparseable model response; no edit made\n' "$rel"
+      _pf_log "$rel" warn false "$before" "$before" 0 "unparseable model response — no change"
+      ;;
+  esac
+}
+
+# ── target resolution ────────────────────────────────────────────────────────
+# 2-WORKING active docs + every 1-INBOX/GH-*.md capture whose path appears in ROADMAP.md's queue.
+main() {
+  printf 'preflight-docs: run %s (model=%s, log=%s)\n' "$RUN_ID" "$MODEL_LABEL" "$(pdda_relpath "$PREFLIGHT_LOG_DIR")"
+  if [ -z "$PDDA_LLM_BIN" ] || ! command -v "$PDDA_LLM_BIN" >/dev/null 2>&1; then
+    printf 'preflight-docs: PDDA_LLM_BIN unset/absent — REVIEW+WARN only, no edits.\n'
+  fi
+
+  local file
+  while IFS= read -r file; do
+    [ -n "$file" ] || continue
+    preflight_one "$file" working
+  done < <(pdda_list_working_docs)
+
+  if [ -f "$PDDA_ROADMAP" ]; then
+    local rel
+    while IFS= read -r rel; do
+      [ -n "$rel" ] || continue
+      file="$PDDA_REPO_ROOT/$rel"
+      [ -f "$file" ] || continue
+      preflight_one "$file" inbox
+    done < <(grep -oE 'PROJECT/1-INBOX/GH-[A-Za-z0-9._-]+\.md' "$PDDA_ROADMAP" 2>/dev/null | LC_ALL=C sort -u)
+  fi
+
+  printf 'preflight-docs: done — %s edit(s), %s warn(s), %s clean.\n' "$EDITS" "$WARNS" "$CLEANS"
+  # Best-effort: NEVER blocks (an LLM-driven oracle must be non-deterministic-safe, per PDDA.md).
+  exit 0
+}
+
+main "$@"
diff --git a/validate.sh b/validate.sh
index 52eb98f..dd064bc 100755
--- a/validate.sh
+++ b/validate.sh
@@ -76,6 +76,7 @@ TESTS=(
   "swarm-preflight.sh"
   "xyz-completion.sh"
   "xyz-harness-hooks.sh"
+  "preflight-docs.sh"
   "roadmap-dashboard.sh"
   "marathon-plan.sh"
   "transcript-audit.sh"
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
