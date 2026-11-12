# GH1428 final implementation QA
STATUS: Open
NEXT: codex (Reviewer)

Final independent QA of the committed implementation for https://github.com/HiQS-Labs/XYZ-forge/issues/1428 against its Codex-approved plan (`relay-system/2026-11-11/gh1428-plan.codex.md`, R3 Approved, attested `67fa20b09`). Review `git diff 0f21b761a..HEAD` (read it with `git diff`/`git show` read-only, or read the files). Plan: `PROJECT/2-WORKING/GH-1428-REVIEWER-UNVERIFIED-APPROVAL.md`. Evidence: `TESTS-RESULTS/2026-11-11+GH-1428/SUMMARY.md` (+ receipts, provenance.jsonl).

Changed code: `utils/py/marathon_drive.py` (`reviewer_runnable_gate`, render-time `reviewer_gate_cmd`, builder `unverified:` sentence, reviewer step 3a, `env2` signal set/pop), `utils/py/relay_attest.py` (`declared_gate_run`, `builder_declared_unverified`, optional `gate-run:` trailer line, `_load` validation), `utils/py/relay_drive.py` (`judge_terminal` refusal `unverified-approval`, `record["gate_run"]`), `relay-automation/relay-turn-lib.sh:1067` (exception clause), docs (`relay-automation/README.md`, `skills/1-hourly/relay-xyz/SKILL.md`, CHANGELOG), regenerated `relay-pkg.tar.gz`, ledger pickup + accepted-start.

Operational envelope: local single-operator CLI harness; grade against the issue acceptance and the approved plan; commensurate complexity; GH-831 — a new test suite/registry entry/gate machinery would be a finding (TESTS-RESULTS manual-check scripts are receipts, not suites — say if you disagree). Parallel #1427 also edits marathon_drive.py; minimal footprint there is intentional.

Questions:
1. Does each issue acceptance item hold, per the acceptance map, and do the code paths match the approved plan steps 1–7 (no duplicate subsystem/writer)?
2. `reviewer_runnable_gate`: does it implement the R2-approved file/node-selector contract exactly (compound, `--` passthrough, GH-54 marker, directories, missing paths, runner-name denylist)? Any shape that wrongly qualifies or wrongly disqualifies the GH-955 gate?
3. `judge_terminal`: is the refusal placed correctly (after empty-approval, before token), does `post_canon[:added_start]` give the pre-turn text in both the canonical and separator-tolerant paths, and is behaviour unchanged when the env is absent? Note: `record["gate_run"]` is now always present, so every new attestation trailer gains a `gate-run:` line — any consumer this breaks?
4. `declared_gate_run`/`builder_declared_unverified`: regex correctness (last declaration wins, exit 0 only, latest Builder block only, `####` sub-headings inside a builder block).
5. Is the relay-turn-lib.sh clause correct inside its single-quoted bash string, and do the gh681 pinned needles still match?
6. Do the receipts substantiate the claims (red control witnessed on base, render variants, codex network red/green), and is the persisted rating 65/55/50/60 still consistent with the evidence?

Rules: final QA only. Read whole affected contexts. Do NOT run validate.sh, test/*.sh, pytest or executable fixtures in this clone; read-only probes under `$TMPDIR` only. Behaviour-change [Blocker]/[Should] need `Observed input:`, `Affected scope:`, `Falsifier:` and file:line. Append `### Round 1 · Reviewer · codex` with plain paragraphs directly under the heading (no nested `####` headings), a literal `swept file: yes|no` line, and `**Verdict:** Approved` or `**Verdict:** Changes requested`. Set `STATUS: Approved` only if approved; set `NEXT: orchestrator`. Edit ONLY this file; do not run git commands that write.

