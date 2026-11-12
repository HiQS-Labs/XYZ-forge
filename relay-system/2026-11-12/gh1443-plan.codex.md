# GH1443 independent plan QA
STATUS: Approved
NEXT: orchestrator

Read PROJECT/1-INBOX/GH-1443-JOG-READINESS.md and TESTS-RESULTS/2026-11-12+GH-1443/SPIKES.md first. Before source inspection, write 2–5 sentences covering What this proposes / How existing behavior works per document / What it is not. Then validate against utils/py/jog_run.py and existing test/gh280-jog-marathon-adapter.sh and test/jog-queue.sh. Do not run suites in this valued clone or change production/plan files. Write only this review thread.

Operational envelope: existing local CLI, Easy reversible task branch, no schema/dependency/daemon/runner. Do not demand speculative enterprise machinery. All real queue writes, provider calls, live recovery, and actual dispatch must be unchanged. Bare queue preview/simulation compatible. Static explicit target-aware readiness is stricter. No claim of complete environment/capacity assurance.

1. Are controlled baseline failures real and worth repairing? Are boundaries/shared owners correct?
2. Is numeric preflight aggregation (all nonzero, including4, maps to nonzero readiness) useful and honest while preserving all per-item summaries?
3. Can static checkpoint clone/origin/clean-publication/development validation be shared with finish without begin/recovery/journal/fetch? Do not certify remote freshness. Keep run behavior unchanged.
4. Reuse promotion probe selection/lint only for inbox docs; no duplicate probe execution. Any drift or missing cases?
5. Ratings65/55/50/65, unknown incidence trend, explicit remaining prerequisites. Are scope/rollback/proof sufficient?

Require concrete observed input, affected scope and falsifier for blockers. Verdict Approved or ChangesRequested; citations. Plan QA round1/3. No source edits, gates, model/provider calls, or network needed.

▶ TAKE YOUR TURN (codex)

## Codex review — document model before source inspection

This proposes static, explicit-target Jog readiness that rejects known admission failures and aggregates per-item preflight outcomes. Per the plan and spikes, current target-aware dry-run prints preflight summaries but returns zero, bypasses executor/checkpoint validation, and omits promotion probe lint. It is not a setup engine, live capacity/authentication check, remote-freshness certificate, or change to dispatch/recovery; bare preview remains compatible. The bet is that existing read-only owners can be shared without importing their write paths; reversal is Easy because there is no persistent migration.

## Codex verdict — Approved (plan QA round 1/3)

Ship the bounded plan. No blocking findings. Approval covers implementation direction, not runtime completion or environment qualification.

- **Baseline and value:** `jog_run.py:2205–2230` produces text only, and `:2291–2326` prints it then returns normally. Role validation explicitly excludes dry-run (`:2271`); checkpoint option checks occur after that return (`:2333`). Thus the controlled nonempty baseline really establishes false-zero orchestration, even though target/preflight seams were stubbed. This is worth repairing without asserting a known incidence trend or data-loss consequence. The stored baseline does not prove invalid-clone behavior, unsupported-role behavior, or live preflight success; those remain final controls.
- **Numeric readiness:** return the subprocess numeric outcome separately from its existing summary, retaining every selected item's output and treating every nonzero, including already-landed 4, as not ready for new work. Missing preflight and inbox identity refusal currently return strings before subprocess launch (`:2211–2223`); these also need explicit nonzero outcomes. Do not parse the display text or stop after the first per-item failure. Falsifier: a mixed nonempty queue containing one refusal still exits zero or hides a later item's summary.
- **Shared owners and boundaries:** `validate_marathon_executor` (`:202–235`) uses route recognition and binary probes, restoring driver result state; `marathon_drive.py:882–945` supports the claimed static scope. Apply it to target-aware real-Marathon readiness while retaining bare preview/simulation compatibility. `JogCheckpoint.__init__` (`:2115`) owns clone/origin identity, and `finish` (`:2180–2185`) owns clean publication/development checks; factoring only those static checks is adequate. Keep option/distinct-target checks too. Do not call begin/finish, inspect recovery as readiness, fetch, write journal, or certify freshness. Reusing a factored helper from finish must preserve its current ordering and live error semantics.
- **Promotion parity:** `promote_contract_to_working` (`:1718–1734`) accepts any valid frontmatter probes, then falls back to JSON contract probes only if none survive lint. Reuse that selection rule for inbox docs, including no-valid-probe refusal; linting every JSON command unconditionally would reject inputs the live promotion accepts. `contract_probes_from_doc` (`:1624`) deliberately checks shape without evaluating probes. Keep preflight as the single evaluator; do not run shell probes during lint or broaden this promotion-only check to working docs.
- **Scope, rollback and proof:** provisional ratings 65/55/50/65 and unknown incidence trend are stated honestly; there is no evidence here warranting numerical recalibration. Easy rollback is credible for this local change without schema/dependency/runner additions. Existing `gh280-jog-marathon-adapter.sh` G1–G3, G8 and I1–I7 cover live admission/refusal and preview/simulation contracts; `jog-queue.sh:173–183` covers hermetic bare preview. Final proof still owes invalid and valid nonempty target-aware entry points, mixed outcomes including 4, early not-evaluated cases, inbox selection/fallback, static publication refusals, and unchanged DB/state/provider/dispatch behavior. Use the existing suites and recorded manual controls in a disposable full clone, then independent final QA and classified qualification.

### Review evidence and limits

Read-only source/document inspection only; no suites, executable fixtures, providers, network, or git commands ran. A narrow integrity probe read the evidence files, checked SHA-256 against every `provenance.jsonl` artifact entry, asserted a nonempty failed-preflight output with rc=0, and checked the recorded unchanged-DB/no-state flags. Command: `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'` with `hashlib.sha256((p/name).read_bytes()).hexdigest()==want` for each artifact, followed by `b['failed_preflight']['rc']==0 and 'exit 3' in b['failed_preflight']['output']` and `b['db_unchanged'] and b['no_jog_state']`. Exit 0; decisive output: `3 artifact hashes match; nonempty failed-preflight baseline reports rc=0; DB unchanged and no Jog state recorded`. This verifies evidence integrity and its stated contents, not an independent execution replay. Runtime and final no-mutation claims are **[Unverified — needs clone run]**.

### System · relay-drive — 2026-11-12T17:33:25Z
terminal STATUS Approved written by FAILED reviewer turn (codex; shim returned non-zero) — reverted

## Round2 request
Prior review was substantive Approved but shim exit6: orchestrator edited plan/CONSULT concurrently, detected as off-allowlist, backed up and restored. No approval claimed. All inputs now committed; no concurrent writes during turn. Recheck revised plan/advisory exact legacy-first semantics and explicit status aggregation; confirm Approved if sound. Do not run suites/edit other files. Original round1 remains retained.

## Codex round 2 — document model before source inspection

The revised plan proposes explicit-target static admission checks and numeric readiness aggregation while preserving the live run path. Its documents describe current dry-run as returning success after displaying failed preflight and bypassing promotion/publication admission checks. This is not provider qualification, environment setup, remote freshness certification, or permission to change dispatch/recovery. The central bet remains that the existing read-only checks can be factored without moving live checks earlier or changing legacy-first probe selection.

## Codex verdict — Approved (plan QA round 2/3)

No blocking findings in the revised plan or advisory. Approval is for implementation direction; it is not a runtime qualification.

- **Exact legacy-first semantics confirmed:** `utils/py/jog_run.py:1718–1734` lints legacy frontmatter probes, accepts any surviving valid probe, and consults JSON contract probes only when none survive. The revised plan and `TESTS-RESULTS/2026-11-12+GH-1443/CONSULT.md` now state precisely that rule. Share the selector with promotion rather than independently validating every JSON command. Final controls should include a valid legacy probe plus malformed JSON (legacy wins), invalid legacy plus valid contract (fallback), and neither valid (refusal). These are cases for the existing coverage/manual evidence, not a new suite.
- **Explicit exit aggregation confirmed:** `_dry_run_preflight` at `jog_run.py:2205–2230` currently returns text, including early missing-helper and identity refusals; `jog_run_main:2291–2326` prints it and returns normally. Returning numeric status alongside summary and explicitly exiting 2 after processing all selected items closes the actual CLI gap. Exit 4 must remain visibly identified as already-landed while still making new-work readiness nonzero. Falsifier: one nonzero outcome in a mixed selected queue yields CLI zero, or suppresses a later summary.
- **Live boundary preserved:** `JogCheckpoint.finish:2180–2185` checks publication cleanliness and development after recording the primary commit. The plan explicitly retains that live position; static preview may reuse a factored check without calling begin/finish, recovery, fetch or journal writes. Constructor identity checks and existing option/distinct-target constraints remain required. Static acceptance cannot certify remote freshness or recovery eligibility.
- **Scope remains proportionate:** executor validation at `jog_run.py:202–235` reuses route recognition and binary checks with restored driver result state. Existing adapter G1–G3/G8 and preview/simulation cases, plus `test/jog-queue.sh:173–183`, remain the compatibility owners. The controlled CLI baseline records 3/16 expected outcomes satisfied, with failure/preflight-4 and admission cases incorrectly zero; its controlled preflight seam does not establish real preflight success. No evidence requires changing provisional 65/55/50/65 ratings or claiming an incidence trend. Easy reversal and the stated environment/capacity prerequisites remain adequate.

### Round 2 evidence and remaining proof

Read-only inspection of the revised plan, spikes, advisory, seeded CLI baseline, source owners and existing suite text; no executable fixtures, suites, provider calls, network or git commands. Source-reading commands exited 0. The displayed baseline reports `passed: 3`, `total: 16`, `all_preserved: true`; these are inspected recorded results, not a new replay. Final mixed-item aggregation, exact probe fallback controls, no-Jog-write behavior, unchanged actual dispatch/recovery, and successful real CLI preparation remain **[Unverified — needs clone run]**. Run the planned existing coverage/manual controls in a disposable full clone and obtain independent final QA before claiming completion.

### Attestation · relay-drive — 2026-11-12T17:35:55Z
task: GH1443-PLAN-QA-R2
reviewer: codex
status: Approved
reviewed-head: 16a23a602b32602b7da93e4a9a2cf2b02db29442
added-range: 7544+3897
added-sha256: b7b699356b6fcafefe7b9fcccc7d200d7c03acb50f79e7673adec2cdf47e2b04
gate-run: undeclared
