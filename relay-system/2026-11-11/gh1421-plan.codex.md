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
