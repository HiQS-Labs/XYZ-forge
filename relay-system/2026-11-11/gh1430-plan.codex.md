# GH1430 independent plan review
STATUS: Open
NEXT: codex

Artifact under review: `PROJECT/2-WORKING/GH-1430-BOARD-SYNC-WAL-READ.md`

Review the committed plan first WITHOUT supplementary source/context. Append 2–5 sentences each under **What this proposes**, **How the existing system works, per this document**, and **What it's not** (ground exclusions in the plan's sections; label inference and missing boundaries rather than inventing non-goals). Record that this initial paraphrase used only the plan doc. Then read the requirements and source below for a separately labeled **Source-backed technical validation**. No author conversation history is provided.

Requirements: https://github.com/HiQS-Labs/XYZ-forge/issues/1430 and the program plan https://github.com/noelsaw1/noels-cross-project-tasks/issues/87 (steps 6 and 7; §2 "Known facts"). Recorded operator decisions: the fix is `mode=rw` + `PRAGMA query_only=ON`; `immutable=1` stays rejected (rejected twice in #1421 plan QA, see `relay-system/2026-11-11/gh1421-plan.codex.md`); other Forge `mode=ro` readers and rebalanceOS's helper are out of scope; no new tests (AGENTS.md, GH-831).

Source to read: `utils/py/board_sync.py` lines 120-240 (reader `_rebalance_active_repos`, resolver `_resolve_policy_and_label`), its `config` and `policy-preview` branches (~1500-1545) and `build_policy_preview` (~1218); `utils/py/device_config.py` `resolve_device_block` and `get_device_config_path`; the GH-1421 plan `PROJECT/2-WORKING/GH-1421-BOARD-SYNC-REPOS-SOURCE.md` (its Plan step 5 and Non-goals, which this plan supersedes on open mode); `utils/pdda/check_inventory_ratchet.py` (SQLITE-GATEWAY-OK annotation).

Operational envelope: a local single-operator CLI reading a local SQLite DB to enrich an advisory board repo list. Grade against the stated requirements and commensurate complexity. Do not impose enterprise or multi-tenant threat models, new suites, registries or gate machinery.

Questions:
1. Are the Observed claims grounded (single connect site at `board_sync.py:159`, warn-and-fall-back, env tier unable to express `repos_source`)?
2. Is `mode=rw` + `PRAGMA query_only=ON` (first statement, inside the existing try) a correct read-only open for this reader? Does `mode=rw` refuse to create a missing file? Is the disclosed checkpoint-on-close risk (Risks section) correctly characterized as a byte change with no content change, and acceptable for this envelope, or is there a simple contained mitigation available under Python 3.9's `sqlite3`?
3. Is the reworded "unable to open" hint accurate after the change (read-only directory case), or should the branch go?
4. Do the acceptance checks detect the actual failure with a non-empty red control, and is the live smoke design (env for owner/number/repos plus a scratch `XYZ_DEVICE_CONFIG_PATH` file carrying only `repos_source`, read via `board_sync.py config`) read-only and a fair substitute for "policy supplied only through env", given the env tier cannot carry an object?
5. Is anything missing, over-built, or a parallel subsystem or writer?

Read whole affected contexts. Do not run test/*.sh, validate.sh or pytest in this worktree; read-only probes under $TMPDIR only (`export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"`). Findings that ask for a behaviour change carry `Observed input:`, `Affected scope:` and `Falsifier:` lines with file:line citations. Append `### Round 1 · Reviewer · codex`, a literal `swept file: yes/no`, and **Verdict:** Approved or Changes requested. Set STATUS: Approved only if approved, and NEXT: orchestrator. Do not edit any other file or run git. This turn is plan QA only.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
