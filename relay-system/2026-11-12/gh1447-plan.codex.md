# GH1447 plan QA
STATUS: Approved
NEXT: orchestrator

Read only PROJECT/2-WORKING/GH-1447-ACCEPTANCE-RELEVANCE.md first. Before supplementary source, append 2–5 sentences each What this proposes / How the existing system works per this document / What it is not; label inference and missing boundaries. Then inspect skills/1-hourly/start-task/SKILL.md Step6, skills/2-daily/flywheel/SKILL.md handoff, utils/py/jog_run.py lint_probe, utils/py/swarm_preflight.py eval_probes, TESTS-RESULTS/2026-11-11+GH-1386/SUMMARY.md. Questions: plan grounded? all user requests covered? smallest existing owners, falsifiable red/adjacent controls, replay scope/limits, ratings/rollback sound? User wants wording first, bounded real bad-contract replay, then separate gate-lint exploration issue. No runtime fix/new machinery within current implementation. No new tests. Only edit this relay file; no suites/pytest/validate. Append at absolute EOF preserving all existing body/blank lines; only STATUS/NEXT may change. Concrete findings require input/scope/falsifier. Verdict Approved or ChangesRequested.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex document-first understanding

### What this proposes
The plan adds an acceptance-observation question to existing start-task preparation review and complete requested-outcome accounting to Flywheel handoff. It then performs one bounded offline replay of historical bad and repaired probe contracts, retaining provenance and controls before filing a separate exploration issue.

### How the existing system works per this document
The document says Step6 already asks how an unchanged candidate is rejected, while Flywheel preserves objective, evidence and budgets. It identifies lint_probe as a syntax/path filter and eval_probes as an exit-status evaluator; inference: neither filter alone establishes that a check measures the user-requested outcome. Exact parser behavior and historical command contents remain boundaries to inspect in source.

### What it is not
This is not a runtime validator fix, new gate, new test suite, or live workflow replay. Lint admission cannot establish semantic relevance or integrated delivery, and the plan explicitly leaves those claims unproved.

## Codex source-backed plan review

Verdict: **Approved**. No blocking findings. Approval covers the plan, not implementation, replay results, gate qualification or publication readiness.

The two requested wording changes extend the smallest existing owners: start-task Step6 already distinguishes admission from final acceptance, and Flywheel's existing handoff already preserves objective/evidence/budgets. Asking what artifact or behavior each check observes closes the stated review-question gap without adding authority or machinery. Requiring every requested outcome and later amendment to have evidence or an unresolved disposition, while distinguishing subtask completion from integration, covers the requested reporting gap. The order is explicit: wording first, bounded historical replay second, separate exploration issue afterward; no runtime fix is authorized here.

Source inspection confirms `jog_run.py:1568` strips the command, rejects empty/trivial inputs, then uses the second whitespace token as a filesystem target for bash/sh/python3/pytest. `swarm_preflight.py:243` executes command probes and interprets their exit result according to expect_nonzero; its landed/unfixed vocabulary is an admission assessment, not a delivery certificate. The plan correctly limits its replay to lint calls and source comparison rather than executing inherited shell commands. GH1386 SUMMARY explicitly records the inline-python promotion refusal and repaired manual script admission, then reviewer failure, no gate, no PR and zero verified deliveries; it supports a real historical compatibility example, not a semantic validator success claim.

Verification performed: read-only `sed -n '196,237p' skills/1-hourly/start-task/SKILL.md`, `sed -n '92,139p' skills/2-daily/flywheel/SKILL.md`, `sed -n '1568,1644p' utils/py/jog_run.py`, `sed -n '243,308p' utils/py/swarm_preflight.py`, and `cat TESTS-RESULTS/2026-11-11+GH-1386/SUMMARY.md`; commands exited 0. Decisive source output includes `target_path = tokens[1]`, `return False, "empty probe command"`, and `subprocess.run(cmd, shell=True, cwd=root, ...)`. No suites, executable fixtures, inherited probes or Git commands were run.

Implementation proof obligations already within this plan: retain exact historical command inputs and source identities with nonempty extraction assertions, and distinguish a missing target caused by replay setup from rejection of the original inline command. For the repaired supported-file control, identify the root and ensure the referenced historical file exists there; otherwise the comparison would measure missing setup. Report actual empty/trivial/missing/valid-control verdicts, not expected verdicts. The falsifier is an admitted empty/trivial input or a supported-file input rejected under a correctly reconstructed root. This is guidance for the planned replay, not a request for runtime expansion.

The content red control is proportionate to instruction-only edits: previous wording lacks the new obligation; exact placement checks plus main/adjacent consumer read-through establish the text was added coherently. They cannot demonstrate agent compliance, and the plan expressly leaves that unproved. Final QA should reject a handoff that omits a later amendment or claims integration from local completion. Retain commands, exits, decisive output and provenance.jsonl with the implementation evidence as required by repository policy.

Ratings are presented as a proposal with rationale and unknown recurrence clearly distinguished from zero; neutral appeal and a cheap existing seam are credible. Easy reversibility and instruction-commit rollback fit this bounded scope. Any validator implementation or broader semantic claim requires the separate follow-up's own evidence and acceptance. Historical object extraction and applicable normal classified gate remain **Unverified — needs implementation replay / disposable clone run**; neither is claimed complete by this approval.

### Attestation · relay-drive — 2026-11-12T22:08:18Z
task: GH1447-PLAN
reviewer: codex
status: Approved
reviewed-head: 148a3a9036ab0987f998ce19f6d4fdf402e117c7
added-range: 1218+5084
added-sha256: b3b78a443c3b795d58e351ae1cecfe6ccb423ef09ead31ec853b38bfa3fde48f
gate-run: undeclared
