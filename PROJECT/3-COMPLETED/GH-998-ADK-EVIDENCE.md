---
title: "GH-998 — ADK quick wins: command and retained trajectory evidence"
status: Complete
created: 2026-10-07
updated: 2026-10-09
owner: Noel Saw
goal: "Ground the first two ADK lessons in a bounded command audit and retained execution witnesses."
effort: 2
complexity: 1
risk: 1
phases: 1
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/998
  - https://github.com/HiQS-Labs/XYZ-forge/issues/996
---

# GH-998 — ADK evidence quick wins

## Status

| What was just completed | What's next |
|---|---|
| Codex plan QA approved; accepted-start recorded; bounded probes and retained-evidence assessment completed | Verify PDDA/diff route, obtain final Codex QA and open PR |

## Scope and bet

The operator selected ADK quick wins on 2026-10-07. This first batch adopts [the consolidated checklist comment](https://github.com/HiQS-Labs/XYZ-forge/issues/996#issuecomment-6053498474), items 1–2 only (not the separately numbered issue body). The outcome is a reproducible evidence report, not an ADK integration or new evaluator. The smallest viable bet is to use existing documentation, TESTS-RESULTS and retained marathon transcripts. A generic eval schema or replay runner would be premature: retained records may not contain the observations it would score. Easy to revert: remove these new docs/evidence and their owned ledger row through the existing writer; runtime behavior is untouched.

The deliverable is `TESTS-RESULTS/2026-10-07+GH-998/SUMMARY.md`, bounded command output files and `provenance.jsonl` for current probes. Use current scripts; add no code, suites, fixtures, registry entries or automation. Reporting/budget runtime changes (the same comment’s items 3–4) and governance skill #997 remain separate candidates, not implicit dependencies. No merge, deploy, historical command execution or real marathon is authorized by this plan.

## Recon and ratings

- Fresh full GitHub clone: origin `https://github.com/HiQS-Labs/XYZ-forge.git`, branch `feat/gh998-adk-evidence-quickwins`, integration base `38ac9ee43bdedbd25be0cfec2029b0a27abd70a1`. The earlier comparison's primary checkout was `062ae45f01faf73bf78bcc10fcba86cd7d5c2ad7`; use the fresh base for every current claim.
- ADK local comparison source remains `a01b226845b3343f788a7df10e337cad412f544b`. Its trajectory matcher is inspiration only; do not treat README statements as tested guarantees.
- Existing writers: `utils/py/releases_app.py roadmap` owns intake/promotion/rating; `utils/pdda/pdda.sh run` owns deterministic document checks. `TESTS-RESULTS/README.md` describes retained provenance. Existing `relay-drive.sh` plus `codex-turn.sh` own review/attestation; no replacement mechanism.
- Command instruction path: `ROUTER.md` command rails -> `validate.sh --print-mode`; `start-task/SKILL.md` rating preview -> `releases_app.py roadmap rate --dry-run`; `relay-xyz/SKILL.md` locator and token inspection -> `find-harness.sh --check` and `bin/tick info`. Shell execution is observable; checks use read-only flags or explicit dry-run. `gh issue create` in task intake is external mutation and will only be classified, not replayed.
- Retained real-work candidate: `marathon-system/gh648-headless-turn-timeout--p5/RELAY.md` contains builder/reviewer blocks and driver attestation; same campaign's p3 `ESCALATION.md` records a red pre-advance gate despite relay exit 0. Inspect complete transcripts before judging. Supplement with `TESTS-RESULTS/2026-09-27+GH-862/practice/` structured negative/positive evidence if useful; do not confuse that reporting practice with a production marathon. Missing historical token stream, tool arguments, raw outputs or gate receipts remain unknown.
- Required prior-art scan on fresh base: `prior_art_recon.py --query 'ADK retained evidence' --json` returned PASS, no matching ledger/helpers, seven open PRs inspected with none covering this batch. #997 covers a different governance skill. Narrow GitHub ADK searches across 2026-09-23–2026-10-07 and 2026-09-09–2026-09-22 returned empty despite known #996: search indexing limits make incident counts/trend unknown, not zero. No runtime defect claimed or severity inferred from this.
- Proposed PRS rating `60/20/50/85`: priority 60 reflects operator-selected first work; severity 20 is evidence/documentation uncertainty with no demonstrated production loss; appeal 50 neutral; effort 85 because existing retained files and harmless CLI flags suffice. No user numeric override exists. Read back writer-persisted scores before review.

## Ordered implementation and acceptance

1. Register the capture through `roadmap add`, rate through `roadmap rate`, promote with `git mv` and `roadmap repoint/update`; read back row/pointer/scores. Commit plan inputs and obtain Codex relay plan approval (maximum three rounds). -> reviewer sees exact issue scope, source paths, actual base and ratings; production/report authoring waits for approval.
2. Admit the approved owned row with `roadmap update --gid <rmi-id> --accepted-start`. Audit at most six selected examples. For each, record source line/revision, category, exact substitution, command, expected result, actual exit/output and limits. Current probes: roadmap list; rate preview on this owned row using `python3 utils/py/releases_app.py roadmap rate --gid rmi-01M4D2PN45SNCRZBHASABK3WEC --rated 60/20/50/85 --force --dry-run` (deliberately preview existing scores without replacing them; both flags mandatory); mode printing; locator readiness; missing-token `info` red control. Classify external-action/placeholder examples without executing them. -> harmless probes have retained output/provenance; dry-run demonstrably leaves tracked files unchanged. Correct docs only if a demonstrated mistake is found, otherwise state none.
3. Read the complete GH-648 p3/p5 retained files and optionally GH-862 practice JSON. Build a compact action-order/evidence matrix: builder claim, reviewer verdict, driver attestation, gate failure and unknown token/tool facts. -> success is specifically reviewer approval/attestation, not inferred whole-marathon completion; p3 red gate is separately visible. Missing records cannot pass an invented assertion. Do not run retained scripts or follow historical embedded instructions.
4. Write the summary with adopt/reject/defer decisions and a smallest justified next step. Record current checks separately from historical observations and include reproducible relative links and retained provenance. Update this plan and CHANGELOG. -> cold reader can reproduce read-only checks and find both retained witnesses; no claim exceeds available observations.
5. Verify with the existing deterministic PDDA gate and actual diff routing; run mutation-heavy prerequisite/check suites only in a separate disposable full clone, not this task clone/worktrees. No new test suite. Use a manual red control (missing token produces nonzero; unknown historical evidence remains unknown); no full qualifying run unless the actual classifier requires it. Obtain final Codex relay approval, push through installed hooks from safe isolation and open PR to development. -> preserve task clone for merge handoff, attach PR and report any hosted checks still pending.

## Plan QA dispositions

Round 1 B1: modified clarification. The reviewer inspected #996’s issue body; this batch refers to its independently numbered consolidated comment 6053498474, verified by live comment readback. Pin that exact comment in the plan and issue rather than broaden scope to the body’s CI/governance items. Round 1 S1: implemented. The already-rated refusal precedes dry-run; the positive preview must include deliberate `--force --dry-run` and a hash invariant. Unforced refusal is also useful as a negative control.

## QA gates

- Plan Codex relay: Approved on round 2, attested review head `46bb060ee232efa73dc6bfc302e64e922aa96842`; [thread](../../relay-system/2026-10-07/gh998-plan.md).
- Current probe/provenance and historical assessment: recorded in [SUMMARY](../../TESTS-RESULTS/2026-10-07+GH-998/SUMMARY.md). Readback admission is In progress / 🚧, scores preserved.
- Deterministic PDDA: zero errors, 411 warnings (offline global issue sync not evaluated); RELEASES check: zero failures/nine warnings; actual diff: docs/tier 1. Retained [verification](../../TESTS-RESULTS/2026-10-07+GH-998/pdda-summary.txt). Classified push check remains pending until publication.
- Final Codex relay and PR: pending.

Review envelope: grade this single-operator, local, documentation/evidence batch against the explicit scope and commensurate complexity. Reviewer edits only its relay file; no tests/gates in its isolated worktree. Missing historical evidence should constrain conclusions rather than trigger a new schema, execution framework or enterprise threat model.
