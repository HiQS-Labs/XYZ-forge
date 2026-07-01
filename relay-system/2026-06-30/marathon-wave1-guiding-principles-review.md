# RELAY · MARATHON-WAVE1 guiding principles review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded 2026-07-01.
-->

NEXT: agy
STATUS: Open
ROUND: 1 / 2

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
6. **Commit only the relay file** (`relay(marathon-wave1-guiding-principles-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: rebalance-OS marathon wave 1 (lanes D/E/F/G + dogfood fix), branch `marathon/2026-06-30`
- Review lens: GUIDING-PRINCIPLES.md (xyz-3-agents-swarm root) — all 12 principles, appendix heuristics
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-01
- Definition of Done: agy confirms (or flags) each completed lane for: containment preserved (#3),
  least-code (#7), honest/operator-decides (#8), done=verified (#10), independent verification (#12).
  Any [Blocker] must be addressed before merge. [Should]/[Nit] are tracked but non-blocking.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Wave 1 Work Summary (review context — embedded for agent access)

### Dogfood fix — xyz-3-agents-swarm (already merged to main)

**validate-relay-block not vendored (exit 8 bug)**
- `xyz-vendor.sh` only copied `bin/tick`; `bin/validate-relay-block` was absent in vendored `.xyz/`.
- Every `tick release --relay-file` in a vendored repo exited 8 (structural validation failed).
- Fix: added `cp -p "$HARNESS_ROOT/bin/validate-relay-block" "$STAGE_DIR/bin/validate-relay-block"` to `xyz-vendor.sh`.
- Test: `test/xyz-vendor.sh` — added `[ -x "$REPO/.xyz/bin/validate-relay-block" ]` assertion.
- Acceptance: `bash test/xyz-vendor.sh` passes.
- Watch item filed as GH-67: headless codex turns write the relay file but don't call `tick release`, relay-drive exits 3.

### Lane D — `utils/pdda/pdda.sh` changelog regex

**Bug:** `check_changelog()` regex `^##[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}` only matched bare
`## YYYY-MM-DD`. The repo uses `## [x.y.z] - YYYY-MM-DD` (Keepachangelog format). Every PDDA run
false-warned "no dated entry" even with a valid, current CHANGELOG.

**Fix (line 365):** Extended regex to optionally match `[x.y.z] - ` prefix:
```
^##[[:space:]]+(\[[^]]*\][[:space:]]*-[[:space:]]*)?[0-9]{4}-[0-9]{2}-[0-9]{2}
```
Warning text updated to name both accepted formats.

**Verification:** `utils/pdda/pdda.sh changelog` → `SUMMARY errors=0 warns=0 info=0`

**Relay:** `relay-system/2026-06-30/marathon-d-pdda-changelog-semver-regex.md`
STATUS: Approved (codex reviewer r1 → claude-a producer r2 → agy reviewer r2 Approved)

### Lane E — `src/rebalance/mcp/tools/calendar.py` days validation

**Bug:** `snap_calendar_edges` MCP tool accepted any integer for `days`, passing it to `snap_edges()`
without bounds checking. Values outside [1,7] raised unhandled `ValueError`; structured error dict
was never returned.

**Fix:** Guard added at top of the tool handler:
```python
if not (1 <= days <= 7):
    return {"error": f"days must be between 1 and 7, got {days}", "status": "error"}
```

**Test discovery challenge:** `snap_calendar_edges` is nested inside `register(mcp, database_path)` —
not a module-level attribute. Tests required a mock FastMCP decorator to capture registered functions
by name. `CalendarConfig` is a local import inside the factory; patched at source module.

**Verification:** `pytest tests/test_calendar_snap.py` → 20/20

**Relay:** `relay-system/2026-06-30/marathon-e-snap-calendar-edges-days-validation.md`
STATUS: Approved (operator self-review; independent test suite as verification gate)

### Lane F — `src/rebalance/cli/semantic.py` kill-check

**Kill-check result:** fix already applied in prior commit `3b40e58`. `_normalize_semantic_sources_option()`
at `semantic.py:28-30` already calls `_all_semantic_sources()` when `"all"` is in values.
Acceptance test `test_cli_all_expansion_equals_runtime_stage` already exists and passes (3/3).

No code changes. Lane closed as verified-already-done.

**Relay:** `relay-system/2026-06-30/marathon-f-semantic-source-all-drift.md`
STATUS: Approved

### Lane G — `scripts/setup_gmail_oauth.py` + `setup_calendar_oauth.py` path fix

**Bug:** `secret_store_root()` = `USER_CONFIG_DIR/secrets/` but `resolve_oauth_token_path("gmail")`
= `USER_CONFIG_DIR/google-gmail-oauth` (no `secrets/` subdir). Setup wrote to `secrets/google-...-oauth`,
runtime read from `google-...-oauth`. Token always missed at runtime.

**Fix (both scripts symmetric):**
- Removed `secret_store` import
- Added `from rebalance.paths import resolve_oauth_token_path`
- Replaced `secret_store.write_secret_file(...)` with direct `token_path.write_text(...); token_path.chmod(0o600)`
- Updated `log_flow_succeeded` and print to use `str(token_path)`

**Verification:** `pytest tests/test_gmail_keyring.py tests/test_onboarding_e2e.py tests/test_google_oauth_client.py` → 26/26

**Relay:** `relay-system/2026-06-30/marathon-g-oauth-setup-scripts-resolve-token-path.md`
STATUS: Approved

### Tick-token management

`tick analyze` after all lanes: 0 concurrent-claim conflicts, 0 parked-claim suspects. All 4 lanes Done.
GH-67 filed for codex tick-release watch item (stall pattern documented, proposed fix Options A/B).

## Log

### Producer — claude-a — 2026-07-01

Scaffolded this relay to request an independent agy quality review of the wave 1 marathon output
against GUIDING-PRINCIPLES. The four lane summaries above are the primary review surface; the actual
code diffs are on branch `marathon/2026-06-30` of rebalance-OS. The dogfood fix is already merged to
xyz main.

Asking agy to grade each lane and the dogfood fix against the principles most likely to flag issues:
#3 containment, #7 least-code, #8 honest/operator-decides, #10 done=verified, #12 independent verification.

VERDICT: PASS (producer setup turn)
Basis: Context established; agy Reviewer turn is next.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
