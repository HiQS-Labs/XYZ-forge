# GH1428 independent plan review
STATUS: Open
NEXT: codex (Reviewer)

Artifact under review: `PROJECT/2-WORKING/GH-1428-REVIEWER-UNVERIFIED-APPROVAL.md` (committed plan; base `0f21b761a`).

**Paraphrase first (GH-1414).** Read ONLY the plan document first, without the issue or source. Append 2–5 sentences each under `#### What this proposes`, `#### How the existing system works, per this document`, and a short `#### What it's not` (ground exclusions in the plan's own sections; label inference; distinguish excluded vs deferred vs unresolved). No author history is provided.

**Then source-backed validation** under `#### Source-backed technical validation`. Requirements: https://github.com/HiQS-Labs/XYZ-forge/issues/1428 (acceptance: reviewer steps require running the phase gate or naming why not, attestation records it; Approved after builder-declared unverified assertions refused or downgraded without reviewer-run evidence; documented opt-in Codex builder localhost network OR preflight warning; existing suites pass, evidence under TESTS-RESULTS, GH-831 no new tests). Source paths: `utils/py/marathon_drive.py` (1519-1539, 3080-3160, 3463-3520), `utils/py/relay_drive.py` (698-790, 1095-1115), `utils/py/relay_attest.py` (262-385), `relay-automation/relay-turn-lib.sh` (1040-1070), `test/gh681-reviewer-probe-rules.sh`, `test/gh505-relay-attest.sh`, `utils/py/swarm_preflight.py:1420-1430`, `utils/py/codex-turn.py:14-18`, `utils/py/rtl.py:876-884`, `utils/py/jog_run.py:519-528`, `relay-automation/README.md:430-445`, `AGENTS.md` (No new tests; worktree rules). Ground-truth incident: the GH-955 RELAY.md excerpts quoted in the plan's Observed table.

Operational envelope: local CLI harness for one operator; grade commensurate complexity; no enterprise threat models; no new suites/runners/guards (GH-831). Parallel work: #1427 edits marathon_drive.py/claude-turn.py; the plan keeps its marathon_drive.py diff minimal.

Questions:
1. Is the root-cause correction right — the reviewer followed the GH-681 role note and preflight brief rather than ignoring an obligation? Any instruction layer missed?
2. Is the "reviewer-runnable gate" predicate (explicit `--pre-advance-cmd`, not validate.sh/ci-local.sh/run-tests.sh/test/*.sh) a sound and minimal boundary consistent with AGENTS.md worktree rules and GH-681, or should the exception be shaped differently?
3. Is `judge_terminal()` refusal gated on `MARATHON_REVIEWER_GATE_CMD` + latest Builder block matching `\bunverified\b` + reviewer `gate run:` != yes correct and non-regressing for generic relays and full-suite marathon gates? Is refusal (escalate) vs downgrade the right choice, given alternatives rejected in the plan?
4. Is the optional `gate_run` trailer/record field compatible with legacy attestation records and `_load()`?
5. Is documenting the existing `CODEX_FLAGS` with `-c sandbox_workspace_write.network_access=true` sufficient for acceptance 3, and is one PR (vs split) justified?
6. Are verification (existing suites + manual red control from the GH-955 pair + dry-run render + Codex network smoke), rating rationale, and rollback sufficient? Anything missing or over-built?

Rules: plan QA only. Read whole affected contexts. Do NOT run validate.sh, test/*.sh, pytest or executable fixtures in this clone; read-only probes with output under `$TMPDIR` only. Every behaviour-change [Blocker]/[Should] carries `Observed input:`, `Affected scope:`, `Falsifier:` and file:line citations. Append `### Round 1 · Reviewer · codex` with your sections, a literal `swept file: yes` or `swept file: no` line, and `**Verdict:** Approved` or `**Verdict:** Changes requested`. Set `STATUS: Approved` only if approved; set `NEXT: orchestrator`. Edit ONLY this file; do not run git.

