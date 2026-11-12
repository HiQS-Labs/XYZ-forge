# GH1421 independent plan review
STATUS: Open
NEXT: codex

Artifact under review: `PROJECT/2-WORKING/GH-1421-BOARD-SYNC-REPOS-SOURCE.md`

Review the committed plan first WITHOUT supplementary source/context. Append 2–5 sentences each under What this proposes, How the existing system works per this document, and What it's not (ground exclusions in the plan's sections, label uncertainty). Then read its referenced source and requirements for separately labeled source-backed technical validation. No author history provided.

Requirements: https://github.com/HiQS-Labs/XYZ-forge/issues/1421 (the plan's Idea/Observed/Acceptance sections quote it). Source to read: `utils/py/board_sync.py` (lines 82-232 and the `config` branch near 1505), `utils/py/device_config.py` (`resolve_device_block`), `test/gh777-inventory-ratchet.sh`, the GH-898 precedent `PROJECT/3-COMPLETED/GH-898-BOARD-SYNC-ACTIVE-REPOS.md` and `TESTS-RESULTS/2026-09-30+GH-898/manual_matrix.py`. The upstream schema is quoted in the plan (rebalanceOS migration 0010; that repo is not in this worktree).

Operational envelope: a local single-operator CLI that reads a local SQLite DB read-only to enrich an advisory board repo list. Grade against the stated requirements and commensurate complexity; do not impose enterprise multi-tenant threat models, new suites, registries or gate machinery. XYZ-forge forbids new tests (AGENTS.md, GH-831): verification is the existing suites plus a manual matrix under TESTS-RESULTS.

Questions:
1. Are the Observed claims grounded in the cited paths (single connect site, warn-and-fallback, `repos_source` popped from the policy dict, ratchet counting connect sites)?
2. Is the merge rule (GitHub list unchanged, agent-only repos appended by runs DESC, name) a faithful and sufficient reading of the issue's "agent-only ranked after GitHub-active ones"? Is rejecting "GitHub score plus runs" re-scoring justified?
3. Is the open-mode fix (retry `?mode=ro&immutable=1` only when `?mode=ro` fails with "unable to open database file" and `<db>-shm` is absent) correct for a persistent-WAL DB with no sidecars, and is its risk adequately contained? Is there a simpler correct option that honours "no writes to the Rebalance DB"?
4. Do the acceptance checks detect the actual failures, with red controls, and is the key-off byte-identity check against the base commit sound?
5. Is anything missing, over-built, or a parallel subsystem/writer?

Read whole affected contexts, not just the proposed lines. Do not run test/*.sh, validate.sh or pytest in this worktree; read-only probes under $TMPDIR only. Findings that ask for a behaviour change carry Observed input, Affected scope and Falsifier lines with file:line citations. Append `### Round 1 · Reviewer · codex`, a literal `swept file: yes/no`, and **Verdict:** Approved or Changes requested. Set STATUS: Approved only if approved, and NEXT: orchestrator. Do not edit any other file or run git. This turn is plan QA only.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->


### Round 1 · Reviewer · codex

**Verdict:** Changes requested

swept file: yes

#### What this proposes

The plan adds an opt-in `include_agent_sessions` flag to the existing Rebalance repo source. It preserves the GitHub-ranked contribution and appends agent-only repositories ranked by summed runs, within the existing resolver cap. It also proposes an immutable retry to repair the reported local WAL read failure.

#### How the existing system works per this document

According to Observed, one helper opens Rebalance, scores GitHub activity, and returns a contribution that the resolver merges after pinned repositories. The resolver removes source configuration from policy identity, while the resolved repo list remains part of that identity. The document describes warnings and pinned-repo fallback on read failures, and config exposes the resolved list offline.

#### What it's not

The Non-goals exclude Rebalance writes, GitHub score changes, new board columns, modules, env vars and suites. The Preflight bet rejects importing Rebalance or copying agent rows into GitHub activity. No source/device filtering or rename alias mapping is proposed; upstream schema correctness is quoted rather than independently established here.

#### Source-backed technical validation

The plan was read before supplementary source. Read the reader/resolver and config contexts, `resolve_device_block`, GH-777 suite/scanner, and GH-898 plan/manual matrix. `board_sync.py:133-161` has one annotated connect, error fallback and empty-window warning; `:169-232` pops source config and performs the stated validation, merge and cap. `device_config.py:82-125` supports the nested-object account; `board_sync.py:1505-1517` supports the config account.

The GitHub-first merge is faithful to the quoted requirement and avoids an unnecessary score change. Existing limits and pinned-first behavior remain appropriate. No parallel owner or writer is needed. Reversibility is Easy for the flag/query, but the open-mode assumption affects enabled Rebalance sources even when the new flag is off.

The ratchet account needs a factual qualification: `utils/pdda/check_inventory_ratchet.py:65-83` skips annotated lines, and GH-898's Ratchet exception record explains that exception. It counts unexempt connect occurrences, not all call sites. Keeping one site is reasonable reuse, but the green ratchet alone cannot prove that invariant.

#### Required changes

**F1 [High] — Replace the asserted immutable safety argument with a valid read contract.**

Observed input: plan `PROJECT/2-WORKING/GH-1421-BOARD-SYNC-REPOS-SOURCE.md:114-119,126,146` infers that missing `-shm` makes immutable safe, treats concurrent-write problems as caught exceptions, and implies that `mode=ro` cannot create sidecars. SQLite's primary documentation says immutable skips locking and change detection and can return incorrect results as well as errors if the file changes ([URI parameters](https://www.sqlite.org/uri.html), immutable section). Its [WAL documentation](https://www.sqlite.org/wal.html), section 5 and overview item 4, explicitly permits read-only WAL access by creating sidecars when directory permissions allow. Missing `-shm` at a check is not a lifetime guarantee against a later writer, and does not rule out an existing `-wal` needing recovery.

Affected scope: every configured Rebalance source through `board_sync.py:133-161`, including flag-off reads. A silent incorrect repo list is not caught by the fallback and becomes policy membership through `:205-214`; the GH-898 precedent already records downstream apply/restore identity implications. This is a local correctness issue, not a multi-tenant threat model.

Requested correction: explicitly distinguish no changes to main DB contents from no sidecar writes; choose behavior consistent with the actual requirement. Do not present a live mutable file as a safe immutable snapshot. The smallest safe baseline is ordinary read-only access plus existing fallback when SQLite cannot open it; if repairing that environment is mandatory, specify an actually stable snapshot or quiescence contract, or an explicit operator acceptance of potentially stale/inconsistent advisory results. An extra absence check alone does not establish immutability. Avoid inventing a new service or gate.

Falsifier: demonstrate a contract that prevents changes for the immutable read's lifetime, or obtain/document the explicit bounded advisory-risk tradeoff; then verify both normal WAL and no-sidecar paths in the existing manual matrix in a disposable full clone. Include sidecar existence/content checks if no source-directory writes is required. Current runtime behavior: **[Unverified — needs clone run]**. No executable fixture or live SQLite connection was run here, since even a nominally read-only WAL connection can create sidecars.

**F2 [Medium] — Make the open-mode acceptance distinguish open from first-read failure, and retain additive results on other agent errors.**

Observed input: plan `:114-119` describes retry when connect raises, but `board_sync.py:148-158` wraps connect and execute together; the reported whole-reader warning does not establish which operation failed. Acceptance `:158-171` only exercises the live happy path and missing agent table, although step 4 promises GitHub preservation on every other agent-query error.

Affected scope: retry placement and the inner agent-query exception boundary. A connection that succeeds but fails when SQLite first accesses the schema can bypass a connect-only retry; an overly broad outer catch can erase already-read GitHub rows on a malformed agent schema.

Requested correction: in the manual matrix, record separately whether connection creation or first SELECT fails for the reported WAL case, and make the chosen repair cover the measured operation. Add a malformed agent-table case (for example missing `runs`) that asserts a warning and the unchanged nonempty GitHub list. Use this existing manual matrix, not a new suite. This acceptance request is contingent on the final open strategy selected for F1.

Falsifier: clone-run evidence identifying the failing operation and proving the selected open strategy handles it, plus a non-missing-table agent-query error retaining the GitHub list; a controlled mutation routing that error to the outer empty-list fallback must fail the same assertion. **[Unverified — needs clone run]**.

#### Acceptance and evidence limits

The key-off base comparison is sound for the same ordinary fixture, environment, dependency paths and serialization, with nonempty output assertions. It cannot establish universal byte identity: the plan deliberately changes behavior for the formerly unreadable WAL case even with the flag off. Say so explicitly. Key on/off controls establish feature sensitivity; missing-table recovery is useful, but should not substitute for the error-preservation control above. Preserve commands, exit statuses and provenance in the eventual committed evidence directory as required by repo policy.

No suites, pytest, fixtures, or git commands were executed. Read-only requirements query `gh api repos/HiQS-Labs/XYZ-forge/issues/1421 --jq '.body'` exited 1 with `error connecting to api.github.com`; the issue requirements were therefore assessed from the supplied plan quotation, not independently verified live. SQLite primary docs were fetched successfully; no upstream schema checkout was available. No source/artifact edits were made.

### Round 2 · Builder · orchestrator

Dispositions (plan doc revised; no production code written):

- **F1 [High] — Accepted.** Measured on this Mac (SQLite 3.54.0 Apple build, Python 3.9): a `mode=ro` connection to a WAL DB with no sidecars **connects, then fails on the first SELECT** with "unable to open database file", and creates no sidecar even in a writable directory. Reproduced on the live DB and on a fixture (WAL DB, `wal_checkpoint(TRUNCATE)`, close, delete the empty `-wal`/`-shm`). This build is narrower than the general SQLite WAL docs; the plan now states the measured behaviour. Step 5 now uses a before/after sidecar bracket: immutable runs only when `mode=ro` failed with that error and no `-wal`/`-shm` exists; if either exists after the read, the result is discarded (warn, pinned fallback). The contract: WAL main file changes only at checkpoint; no sidecars before means fully checkpointed with no WAL connection; a WAL connection creates `-shm` on first read, so none after means none opened during. The residual (a whole writer session finishing inside the ms window) is stated as bounded advisory risk with its downstream containment (preview before apply; restore refuses membership drift). "No writes" is made explicit: no DB content change and no sidecar creation, asserted on the fixture. No `mode=rw`.
- **F2 [Medium] — Accepted.** The loop wraps connect and queries (measured: the failure is on the first SELECT). The agent query runs in its own inner `try` after GitHub rows are read. Acceptance gains a malformed-agent-table case (no `runs` column → one warning, unchanged GitHub list) with a disposable-clone mutation red control, a no-sidecar WAL fixture with a base-reader red control, and a gate control (empty `-wal` present → no immutable read).
- **Ratchet qualification — Accepted.** Observed now says the ratchet counts unannotated occurrences (`check_inventory_ratchet.py:65-83`).
- **Key-off identity scope — Accepted.** The acceptance now says identity holds for every DB the base reader could open; the no-sidecar WAL case changes with the key off by design.

Re-review the revised plan. Preserve Round 1. Append `### Round 2 · Reviewer · codex` with plain paragraphs, `swept file: yes/no` and an explicit verdict. Set STATUS: Approved only if approved, NEXT: orchestrator. Same scope and rules as Round 1.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
