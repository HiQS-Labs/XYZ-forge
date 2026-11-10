# Additional requested QA — PR1404
Pinned candidate head: 2ac48f4021bfa47b33b92edcefd64efcd251a34a. Review scaffold is the only later commit.
Operational envelope: skill-only existing-issue preparation in local XYZ; no new runtime, scheduler, queue, gate, contract schema or readiness consumer. Review whole skills/1-hourly/conveyor/SKILL.md and its ARCHITECTURE row, canonical PROJECT/2-WORKING/GH-1401-CONVEYOR.md and recon-conveyor.md, TESTS-RESULTS/2026-11-09+GH-1401 evidence/provenance, plus existing contracts and actual consumers as needed: utils/py/swarm_preflight.py, utils/py/jog_run.py, releases_app.py pickup writer/help, HQ capture and idea skill exclusion. Prior Codex approvals are evidence, not replacement for your review.
Questions:
1. Is each named invocation mode bounded and implementable by these instructions with existing CLI contracts and canonical writers?
2. Can capture/contract/probe polarity, parser/linter and pinned-ref real preflight checks produce truthful readiness? Trace downstream exact-issue selection; readiness label is publication signal only. Is readiness held until packet is merged/available on integration? Are holds preserved and stale results handled?
3. Are publication, ratings/overrides, accepted-start exclusion, issue marker rerun and no-execution boundaries correct? Any concrete regression or instruction that cannot be followed?
4. Do recorded manual red/main/adjacent checks substantiate claims, and is production surgical/DRY/commensurate? No new tests/gates under GH831. No enterprise scope expansion.
5. Does this compose with PR1403 downstream handoff (prepared signal -> explicit owner selection/revalidation -> execution; no automatic admission), without changing shared runtime?
Use complete source file sweep and file:line citations. Read-only source queries only: NO tests/pytest/fixtures/validate in worktree. Any change-request needs Observed input, Affected scope, Falsifier; blockers need observed failure. Write graded findings + swept file yes/no + PASS/FAIL/PARKED + basis in relay only. Do not edit artifact or self-commit; harness owns commit. No push. Approved only if deserved. User requested Claude Code CLI Opus medium effort, parent Codex adjudicates.
## Original issue
## Problem: The Upstream Intake Bottleneck

In issue #522's census across 298 open issues, only **6** were admissible for immediate pickup: **202 had no ledger row** and **67 had no Preflight Contract**. 

Currently, transforming a raw, ambiguous GitHub issue into an executable task packet requires:
1. Deep codebase investigation (/recon) to locate entry points and blast radius.
2. Formulating a falsifiable reproduction or acceptance probe.
3. Drafting a PDDA-compliant capture doc in `PROJECT/1-INBOX/GH-<n>-*.md`.
4. Formatting a strict JSON `Preflight Contract` (`target`, `gate`, `fix_probes`, `artifacts`).
5. Registering the issue in `releases.db` with a PRS rating.

When this is done ad-hoc during a factory run (inside `jog` or `start-task`), the execution engine stalls before touching any code.

---

## The Concept: `/conveyor`

`conveyor` is an upstream intake and preparation skill that feeds the factory flywheel. It acts as an **Issue Refinery**, converting raw backlog items into verified, ready-for-pickup contracts without executing code changes.

```text
[Raw Issue] ──► /conveyor (Triage ──► Recon ──► Plan ──► Preflight Contract) ──► [status:ready-for-pickup]
                                                                                          │
                                                                                          ▼
                                                                           [Flywheel / Jog Factory]
```

---

## Operating Flow of `/conveyor`

1. **Intake & Duplication Check:**
   - Evaluates the raw issue description against `releases.db`, recent commits, and open PRs.
   - Detects whether the issue is already fixed, obsolete, or a duplicate.
2. **Grounded Codebase Reconnaissance:**
   - Traces the subsystem using existing read-only tools and `/recon` (callers, contracts, state carriers).
   - Establishes primitive ground truth: identifies the exact files, lines, and potential reproduction path.
3. **Capture Doc & Contract Synthesis:**
   - Drafts `PROJECT/1-INBOX/GH-<num>-<title-slug>.md`.
   - Embeds a schema-valid JSON `Preflight Contract` with concrete `fix_probes` (runnable commands or tests) and designated `gate`.
   - Generates an honest PRS 4-axis rating (priority, severity, appeal, effort).
4. **Roadmap Registration & Handshake:**
   - Registers the item via `python3 utils/py/releases_app.py roadmap pickup --issue-num <N> --doc-path <P>`.
   - Adds label `status:ready-for-pickup` on GitHub and posts a summary comment with the synthesized Preflight Contract.

---

## Why This Unlocks Factory Throughput

- **Zero Test/Gate Contention:** `/conveyor` operates purely in read-only / research mode. It never cuts task branches, modifies code, or contends for the 1800s full gate slot.
- **Cost & Speed Optimized:** Because it requires analysis and synthesis rather than code execution, it can run efficiently on fast, economical models (e.g. Gemini 3.8 Flash or Claude 3.5 Haiku).
- **Decoupled Execution:** The builder engine (`jog` / `flywheel`) never has to pause to figure out what an issue means; it picks up fully preflighted tasks from the conveyor belt.

---

## Invocation Modes

1. **Interactive / Ad-hoc:** `/conveyor 1340` or `/conveyor --prs-min 200`
2. **Scheduled Batch:** Periodic scheduled job that pulls the top N untriaged issues, refines them, and pushes capture docs in a clean docs-only PR.
3. **Event-driven:** Triggered when an operator applies an `intake` or `refine` label to an issue.

## Initial PRS Proposal
- **pri 80**: Directly unblocks the factory from issue starvation.
- **sev 65**: Prevents factory builders from stalling on ambiguous requirements.
- **appeal 85**: High operator value for automated backlog grooming.
- **effort 45**: Reuses existing `/recon`, `start-task` Phase 0 logic, and `releases_app.py`.