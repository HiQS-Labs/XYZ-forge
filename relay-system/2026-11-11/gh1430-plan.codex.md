# GH1430 independent plan review
STATUS: Approved
NEXT: orchestrator

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

### Round 1 · Reviewer · codex

**Verdict:** Approved

swept file: yes

**What this proposes**

The plan changes the existing Rebalance reader to open with mode=rw and immediately enable query_only, retaining its timeout, queries and warning/fallback behavior. It also updates the diagnostic and docstring, with a CHANGELOG entry and manual verification rather than new tests. It explicitly accepts sidecar creation and possible close-time checkpointing while prohibiting logical data changes.

**How the existing system works, per this document**

The existing board_sync reader opens Rebalance with mode=ro; on the stated Apple build it cannot read a WAL DB after the last connection removed its sidecars. Failures warn and yield an empty source list, leaving pinned repos in place. The document says the environment resolver cannot represent the repos_source object, so its smoke uses ordinary env policy values plus a temporary device-config object.

**What it's not**

The frontmatter non_goals and Preflight bet check exclude other Forge readers, the rebalanceOS helper, journal-mode changes, DB copying and persisted device configuration. The Plan excludes new modules, writers, env variables, subcommands and tests, and explicitly rejects immutable. This does not promise byte-for-byte immutability in the crash-left-WAL case: Risks narrows that acceptance to a cleanly closed fixture.

This initial paraphrase was formed from the plan document alone, before reading supplementary source or live issue requirements.

**Source-backed technical validation**

Ship at plan level. I read the complete plan, the supplied reader/resolver contexts, device_config's path and nested-block resolution, config and policy-preview dispatch, build_policy_preview and its board/GitHub read calls, the inventory scanner, GH-1421's superseded open-mode decision and prior relay decisions. Read-only GitHub connector queries independently retrieved XYZ-forge #1430 and program #87 successfully. The plan matches their selected mode=rw plus query_only fix and their exclusions; no competing reader or writer is introduced. Reversibility is Easy for the code change: revert restores warning/fallback. The new physical side effects are explicitly disclosed and limited to SQLite's sidecar/checkpoint machinery.

1. The source grounds the important Observed claims. board_sync.py:159 is the one Rebalance connection site; :145-181 handles missing files and read failures, while :225-237 retains pinned repos and labels fallback. The separate connect at :542 reads the Forge ledger and is outside this change. device_config.py resolve_device_block coerces lists/bools/ints but leaves a None-default environment value as a string; board_sync.py:204-206 requires a dict. The annotation scanner at check_inventory_ratchet.py:79 skips annotated lines; it does not independently prove a single connect site.
2. The proposed pragma belongs first inside the inner try at board_sync.py:160, preserving finally-close even if it fails. This is application-level read-only SQL on a read-write connection, appropriate for the selected local advisory reader. SQLite's [URI documentation](https://www.sqlite.org/uri.html) distinguishes rw from rwc: rw does not create a missing main DB. Its [query_only documentation](https://www.sqlite.org/pragma.html#pragma_query_only) says data-changing SQL is refused while checkpoints remain possible. That supports the plan's distinction between logical content and physical bytes.
3. Close-time checkpointing copies already committed WAL content into the main DB; it is not a new application data mutation. The [SQLite connection option](https://www.sqlite.org/c3ref/c_dbconfig_defensive.html#sqlitedbconfignockptonclose) can suppress it, but Python 3.9's [documented sqlite3 API](https://docs.python.org/3.9/library/sqlite3.html) exposes no setconfig/db_config entry point. I found no simple supported Python-3.9 connection setting that removes this side effect; wal_autocheckpoint would address a different checkpoint trigger. Adding native bindings, retained connections or cross-repo persistence machinery would exceed this task's value. The disclosed tradeoff is acceptable in the specified envelope. “Rebalance's own next connection” should be understood as normal eventual checkpoint processing, not a guarantee that every next connection checkpoints immediately.
4. The reworded hint remains a qualified possibility, not a diagnosis. The unchanged CANTOPEN/no-sidecar condition at :174-177 can include inability to create sidecars in an unwritable directory; retaining “may” makes the proposed wording sound. There is no reason to remove the branch to implement this fix.
5. The nonempty fixture and old-reader/new-reader comparison exercise the actual SELECT failure and fallback, rather than merely testing successful connect. Write refusal and unchanged clean-fixture bytes address distinct promises. The missing-file guard proves user-visible fallback; rw's independent no-create behavior is additionally established by the URI contract. Manual outcomes and committed provenance are still owed.
6. config calls the same resolver at :1535 onward and prints the resulting repos without network calls or settings writes. A scratch XYZ_DEVICE_CONFIG_PATH carrying only github_board_selection_policy.repos_source is a fair nonpersistent substitute for the impossible all-env object; scalar/list policy values remain env supplied. policy-preview at :1218 additionally requires ledger evidence, then reads GitHub with board caching disabled and writes its explicit output. config therefore proves resolved membership, while a successful policy-preview is still needed to mark program #87's literal preview step complete; a recorded ledger blocker is a deferral, not completion of that step.

Nonblocking evidence cautions: GH-1421's Observed section recorded that all three live agent repos also had GitHub activity in its seven-day window. Recheck the live input before claiming an agent-only on/off result; if none exists, report that live acceptance as outstanding rather than substituting fixture success or modifying live data. Also, timeout=2 is a busy-handler wait, not a hard two-second total runtime bound, and WAL readers can encounter contention during recovery/checkpoint operations. Neither qualification requires changing this bounded reader design.

Inspection receipt: command `rg -n 'sqlite3.connect|def fetch_board_items|def collect_github_state|def _write_json|def main' utils/py/board_sync.py` exited 0; decisive output identified connect sites at 159 (Rebalance) and 542 (Forge ledger), plus the preview read helpers. Source reads completed with exit 0. No runtime fixture, SQLite connection, suite, pytest, validate.sh or git command was executed. Apple-build behavior, write refusal, byte/mtime preservation and live smoke remain **[Unverified — needs clone run]** for implementation QA. Approval is for the plan, not for delivered runtime behavior. Only this relay file was edited.
