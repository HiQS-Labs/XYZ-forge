---
gh_issue: 109
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/109
title: "Gemini 3.1 Deep Think audit: watchdog leak, tmp collision, DRY turn scripts, Python helpers"
status: parked
created: 2026-07-03
updated: 2026-07-03
owner: noel
doc_type: bug-fix-and-hardening
complexity: 3
risk: 3
effort: 3
phases: 3
ratings_provisional: false
non_goals:
  - Not rewriting orchestration logic in Python — BSD/macOS Bash 3.2 portability is a hard
    constraint; Python 3 inline snippets are a dep but not the execution layer
  - Not replacing the custom security scanner with Gitleaks/TruffleHog — see declined item below
  - Not changing the drift-guard pattern on byte-identical lane mirrors (relay-turn-lib.sh seam
    already IS the DRY abstraction; a full "Template Method" extraction in bash risks that guard)
related:
  - relay-automation/consult.sh
  - relay-automation/relay-xyz-guard.sh
  - relay-automation/aider-turn.sh
  - relay-automation/codex-turn.sh
  - relay-automation/claude-turn.sh
  - relay-automation/relay-turn-lib.sh
  - relay-automation/security-scan.sh
  - PROJECT/1-INBOX/GH-64-SECURITY-SCANNING-GUARDRAIL.md
roadmap_exempt: false
---

# GH-109 · Gemini 3.1 Deep Think audit — watchdog leak, tmp collision, DRY turn scripts, Python helpers

**Why:** Gemini 3.1 Deep Think reviewed the codebase and identified five findings. Two are
concrete safety/resource bugs (watchdog process leak, tmp permission collision); two are scope-
appropriate incremental improvements (relay-xyz-guard.sh inline Python extraction, turn-script DRY
audit); and one (retire custom scanner for Gitleaks/TruffleHog) is explicitly declined because it
conflicts with the no-external-dep design constraint. All decisions documented below.

## Status

| What was just completed | What's next |
|---|---|
| GH-109 captured 2026-07-03; all 5 findings evaluated; 4 actioned across 3 phases, 1 declined with rationale. | Phase 1: watchdog process leak + tmp collision fix (~1–2 hrs). |

## Table of contents

- [Declined item — rationale](#declined-item--rationale)
- [Phase 1 — Safety bugs](#phase-1--safety-bugs-~1-2-hrs)
- [Phase 2 — Targeted Python extraction](#phase-2--targeted-python-extraction-~half-day)
- [Phase 3 — DRY turn-script audit](#phase-3--dry-turn-script-audit-~half-day-to-1-day)

---

## Declined item — rationale

### Item 4: Retire custom security scanner for Gitleaks / TruffleHog / ShellCheck

**Gemini's suggestion:** Replace `security-scan.sh` (custom regex SAST + manual TSV baseline) with
Gitleaks or TruffleHog for secrets, and ShellCheck for unsafe `eval` usage.

**Decision: declined.** The custom scanner (GH-64) was deliberately designed around two constraints
that external tools violate: (a) **no network access** — tools like Gitleaks fetch rule databases
at runtime; (b) **no external tool dependency** — `security-scan.sh` runs anywhere with `grep`,
making it CI-safe without package management. ShellCheck already runs in CI (GH-61 Tier 1) and
catches AST-level issues; the custom scanner is a distinct layer for credential/eval pattern
detection with a content-keyed baseline that survives line churn. The manual baseline maintenance
cost is real but accepted. If Gemini's objection is the maintenance burden specifically, the right
response is a `make update-baseline` convenience target — not swapping tools.

---

## Phase 1 — Safety bugs (~1–2 hrs)

Two concrete bugs: a resource leak and a silent permission failure. Both are small, independent
fixes that can land together.

### Checklist

#### 1a — Fix orphaned process leak in `consult.sh` watchdog

**Observation (Gemini item 2):** `consult.sh` implements a custom watchdog because macOS lacks GNU
`timeout`:

```bash
( sleep "$secs"; kill -9 "$apid" 2>/dev/null ) >/dev/null 2>&1 &
kpid=$!
wait "$apid" || rc=$?
kill "$kpid" 2>/dev/null || true
```

Two distinct leaks: (a) `kill "$kpid"` kills the subshell but not its `sleep` grandchild — `sleep`
is reparented to PID 1 and runs to completion silently; (b) `kill -9 "$apid"` only kills the
parent agent process — any children the agent spawned are leaked. Fast/repeated consults accumulate
orphaned sleeps.

- [ ] Fix grandchild leak: use `kill -- -"$kpid"` (negative PID = process group) OR restructure
      the watchdog so `sleep` is in a dedicated process group. Verify BSD `kill` semantics on
      macOS before committing (GNU `kill -PGID` and BSD `kill -PGID` differ slightly).
- [ ] Fix agent-children leak: if `$apid` was launched in its own process group (check the
      launch site in `consult.sh` — `setsid` or equivalent), use `kill -9 -- -"$apid"`. If not in
      its own group, start it in one: `( set -m; exec agent_cmd ) &` or `setsid agent_cmd &`.
- [ ] Add a comment at the watchdog site explaining the process-group kill semantics so the pattern
      is not reverted as "aggressive."
- [ ] Verify macOS Bash 3.2 compat for the chosen approach (no `coproc`, no `mapfile`).

#### 1b — Fix multi-user `/tmp` permission collision in `relay-xyz-guard.sh`

**Observation (Gemini item 3):** `STATE_DIR="${TMPDIR:-/tmp}/relay-xyz-guard"` is created by the
first user to run the script. On a shared machine or CI runner, a second user hits `mkdir -p`
silently and `$MARKER` is never written — the guard then always fails closed, permanently blocking
that user.

- [ ] Append `$UID` to the state directory path:
      `STATE_DIR="${TMPDIR:-/tmp}/relay-xyz-guard-${UID}"`. One line change; `$UID` is set by the
      shell itself (POSIX), not a subprocess.
- [ ] Confirm the existing test in `test/` (if any) covers the state directory path and update it.

### QA gate — Phase 1

- [ ] `./validate.sh` green.
- [ ] Manual smoke test: run two rapid `consult.sh` calls that exit early, then confirm no orphaned
      `sleep` processes remain (`ps aux | grep sleep`).
- [ ] `relay-xyz-guard.sh` state directory path includes `$UID` (grep the file).
- [ ] `shellcheck relay-automation/consult.sh` reports no new warnings.

---

## Phase 2 — Targeted Python extraction (~half day)

**Gemini item 5 (scoped down):** Gemini recommended rewriting orchestration in Python. That is
out of scope (BSD portability constraint). The narrow valid sub-point: `relay-xyz-guard.sh` drops
into an inline Python heredoc to parse JSON and emit tab-delimited output — this is the brittle
cross-language serialization Gemini correctly flagged. Extracting it to a discrete util avoids the
quoting/splitting hazard without touching the shell orchestration layer.

### Checklist

- [ ] Identify all `python3 <<'PY'` and `python3 -c` inline strings in `relay-automation/`
      (known sites: `relay-xyz-guard.sh` JSON parser, `claude-turn.sh` token extraction).
- [ ] For each inline block above ~10 lines: extract to `utils/parse-relay-field.py` (or a
      per-purpose named script in `utils/`). The script should accept args or stdin, emit a single
      clean value, and exit non-zero on parse failure.
- [ ] Update callers to invoke the extracted script; remove the heredoc.
- [ ] Verify the extracted helper handles malformed JSON gracefully (exit 1 + stderr message, not
      a Python traceback that could be misread as a shell error).
- [ ] For short `python3 -c` one-liners (token extraction): leave in place if they are
      self-contained and have no quoting hazard; document the decision with a comment.

### QA gate — Phase 2

- [ ] `./validate.sh` green.
- [ ] No inline `python3 <<'PY'` heredocs remain in `relay-automation/` for JSON parsing
      (one-liner `-c` strings are exempt).
- [ ] Extracted helpers handle a malformed-JSON fixture gracefully (manual test or new assertion).
- [ ] `shellcheck` on affected scripts produces no new warnings related to the extraction.

---

## Phase 3 — DRY turn-script audit (~half day to 1 day)

**Gemini item 1 (scoped down):** `aider-turn.sh`, `codex-turn.sh`, and `claude-turn.sh` share
~80% lifecycle logic. The "Template Method in bash" macro suggestion is out of scope — the
byte-identical lane_attempt mirror in both drivers is already drift-guarded by a test, and
`relay-turn-lib.sh` IS the intended DRY seam. The narrow valid concern: if a bug lands in worktree
teardown, it must be patched in ≥3 files. This phase audits the actual delta and decides whether
a targeted extraction is warranted.

### Checklist

- [ ] Diff `aider-turn.sh`, `codex-turn.sh`, and `claude-turn.sh` side by side. Identify:
      (a) identical blocks (worktree setup/teardown, `rtl_init`, exit-code handling, `rtl_enforce`
      call), (b) model-specific blocks (prompt construction, env vars, binary path), (c) blocks
      that are *nearly* identical (risk of silent drift).
- [ ] For category (a) — exact identical blocks: if any block is >~10 lines and not already
      delegated to `relay-turn-lib.sh`, extract it to `relay-turn-lib.sh` as a function and update
      callers. This is the pattern the harness already uses; extend it, don't add a new seam.
- [ ] For category (c) — near-identical blocks: add a drift-guard test assertion (like the
      existing `lane_attempt` byte-comparison test) rather than extracting if the divergence is
      intentional (different models have genuinely different behavior).
- [ ] Do NOT create a new `execute-turn.sh` dispatcher unless the audit reveals the shared code
      cannot be captured by `relay-turn-lib.sh` functions. Document the decision either way.
- [ ] If any extraction is made, update `validate.sh` or the existing turn-script test to cover
      the extracted function.

### QA gate — Phase 3

- [ ] `./validate.sh` green.
- [ ] Any newly extracted `relay-turn-lib.sh` function has at least one test assertion in the
      existing turn-script or lib test.
- [ ] The byte-identical `lane_attempt` drift-guard test still passes (no regression).
- [ ] A written note in this doc (under Phase 3 results) states: (a) what was extracted, or (b)
      why no extraction was warranted.
