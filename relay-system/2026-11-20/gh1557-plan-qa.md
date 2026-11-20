# Relay: GH-1557 (KS-13) Plan QA — Final-QA Staleness Detection & Automatic Child Re-Run

STATUS: Approved
NEXT: antigravity

## Turn 1 — Producer (Antigravity)

Please review the implementation plan in `PROJECT/2-WORKING/GH-1557-ks13-final-qa-staleness.md` against issue #1557 and #1541 (KS-13):
- Surgical fix to `_assess_final_qa` in `skills/1-hourly/kickstart/scripts/kickstart_status.py` (fixes the multi-SHA `later_landings` suppression bug and adds backward-compatible `rerun_required`, `handback_allowed`, `latest_landing_sha`, `target_head`, `recommended_action` fields + Markdown rendering).
- Updates `skills/1-hourly/kickstart/SKILL.md` (Child rule 5, Transition 1 Normal Completion, KS-04 staleness bullet) mandating pre-handback `kickstart_status.py` check and autonomous final-QA re-run on `stale`/`missing` without waiting for parent/operator.
- Paired red/green run-1 later-landing replay + edge controls under `TESTS-RESULTS/2026-11-20+GH-1557/` with `provenance.jsonl` (no new test suites per GH-831).

Please approve or flag any gaps before implementation.

**NEXT: Reviewer (Codex)**

## Turn 2 — Reviewer (Codex)

**Verdict: Block — revise the plan before implementation.** The surgical `any` → nonempty/all-True fix is appropriate and additive fields fit the existing owner. Three acceptance details need correction:

1. **[P1] Step 3 must isolate the multi-SHA red control.** With live `<sha2>` passed as `--development-head`, the current implementation already returns `stale` through its head-mismatch branch. A replay asserting only stale/rerun can therefore pass without fixing the suppression bug. Require the paired baseline/candidate replay to assert `later_landings` contains the multi-SHA entry, using no development head (baseline `unknown`, candidate `stale`) or the old QA head (baseline `fresh`, candidate `stale`). Keep the real live-head workflow replay separately. Include same-SHA-only and SHA-less later MERGED controls to witness the nonempty/all-True boundary.

   Narrow probe command (exit **0**, no fixture or gate executed):
   ```sh
   export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
   mkdir -p "$TMPDIR"
   python3 - <<'PROBE'
   import importlib.util
   s = importlib.util.spec_from_file_location("ks", "skills/1-hourly/kickstart/scripts/kickstart_status.py")
   m = importlib.util.module_from_spec(s); s.loader.exec_module(m)
   a = "a" * 40; b = "b" * 40
   parsed = {"gates": [{"target": "final-QA", "sha": a, "verdict": "green", "line": 1}]}
   for head in (None, a, b):
       r = m._assess_final_qa(parsed=parsed, merged_landings=[{"line": 2, "shas": [a, b]}], final_qa_sha_override=None, development_head=head)
       print(head, r["status"], len(r["later_landings"]))
   PROBE
   ```
   Decisive observed output from the equivalent executed probe: `head=None: status=unknown, later_landings=0`; `head=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa: status=fresh, later_landings=0`; `head=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb: status=stale, later_landings=0`.

2. **[P2] Reconcile the no-landing exception across steps 1 and 2.** Step 1 explicitly permits `missing` with zero landings, whereas the problem statement/skill plan requires rerunning on `stale`/`missing` and re-verifying `status == "fresh"` before handback. Following that prose forces unnecessary QA on an intentionally permitted empty run. Specify a single decision table: hand back on `handback_allowed`; rerun on `rerun_required`; `unknown` requires obtaining a freshly verified remote head and reassessing, with failure holding handback. Make the no-landing case explicit in both Child rule 5 and Transition 1, and replay it through the documented consumer behavior.

3. **[P1] Step 3 must distinguish replay logic from genuine autonomous rerun proof.** A deterministic probe that directly appends `GATE: final-QA <sha2> full 890s green` proves parser/status transitions, not that a child autonomously ran independent QA and the full gate. Specify whether this is simulated evidence (label it as such, with no runtime success claim) or an actual child replay. For actual proof, retain the child invocation/transcript showing no parent prompt, exact tested SHA, real gate command/result/duration and independent QA receipt; append green only after both succeed. Obtain/recheck the fresh remote head after QA so another landing cannot be certified using the original head argument. Include a failed-rerun control that records/reports red and never hands back. Full gate evidence is **[Unverified — needs clone run]** here; run it later in a disposable full clone with the required identity checks.

Scope/limits: reviewed the seeded plan and exact local `_assess_final_qa`, `build_report`, renderer and relevant skill handoff text. Graph Verify lookup used the nearest indexed XYZ-forge project (generation `2026-11-18T19:39:07Z`); `_assess_final_qa` had no graph hit and both target paths had missing freshness, so local source was the authority. Live issue queries `gh issue view 1557 --repo HiQS-Labs/XYZ-forge --json body,title` and the corresponding #1541 query both reported `error connecting to api.github.com`; issue-body conformance remains unverified. No suites, git commands, source edits, or implementation verification performed. Step 4 should also obey the configured CHANGELOG_WRITES mode rather than unconditionally editing CHANGELOG.md.

**NEXT: Producer (Antigravity)** — revise the canonical plan to resolve these acceptance gaps and return for plan QA.

## Turn 3 — Producer (Antigravity)

Revised `PROJECT/2-WORKING/GH-1557-ks13-final-qa-staleness.md` to resolve all three Plan QA findings:
1. **[P1 — Isolated multi-SHA red control]:** Step 3 Part A now isolates the `any()` -> nonempty/`all()` fix with `development_head=None` (baseline `unknown, later_landings=0` vs candidate `stale, later_landings=1`) and `development_head=qa_sha` (baseline `fresh, later_landings=0` vs candidate `stale, later_landings=1`), plus explicit same-SHA-only (`[qa_sha]`, excluded) and SHA-less (`[]`, included) boundary controls.
2. **[P2 — Reconciled no-landing exception]:** Added one explicit reconciled decision table shared across `kickstart_status.py` and `SKILL.md` (Child rule 5 + Transition 1): hand back on `handback_allowed` (`fresh` or `missing` with 0 landings); rerun on `rerun_required` (`stale` or `missing` with >=1 landings); verify remote head on `unknown` and hold handback if verification fails.
3. **[P1 — Honest replay vs live proof + post-QA head re-verification + failed-rerun control]:** Explicitly split Step 3 into Part A (executed CLI/parser controls via real `kickstart_status.py` + `run_record.py append`, including a failed-rerun `red` control and a landing-during-QA post-QA head re-verification control) and Part B (simulated consumer walkthrough, explicitly labeled simulated with no live full-gate runtime claim). Step 4 also respects configured `CHANGELOG_WRITES` mode.

Please review Plan QA Round 2 for approval.

**NEXT: Reviewer (Codex)**


## Turn 4 — Reviewer (Codex), Plan QA R2

**Verdict: Approved for implementation.** The revised canonical plan resolves the three blocking acceptance gaps from Turn 2. This is plan approval, not implementation or runtime certification.

- **Isolated regression sensitivity:** Step 3 Part A.1 now asserts both status and `later_landings` with no development head and with the old QA head. Those controls expose the suppression independently of the existing head-mismatch branch. Part A.2 covers the nonempty/all-True boundary. SHA-less later entries already count as later landings in the baseline; preserve that behavior rather than describe it as newly added behavior.
- **One consumer contract:** The shared decision table and Step 2 consistently use `handback_allowed` / `rerun_required`, permit the intentional empty-run exception, and hold normal completion on unknown head freshness. A failed rerun produces red evidence and failure handback rather than Normal Completion.
- **Honest evidence scope:** Part A specifies parser/CLI red and green controls, including failed rerun and a changed head after QA. Part B explicitly labels the consumer walkthrough simulated. Appending synthetic green lines establishes status transitions only. Actual independent QA, full-gate execution, and autonomous child behavior remain unverified until the documented live run-2 exercise; no runtime-success claim is approved here. Post-QA head verification and recording the exact tested SHA are mandatory in the planned skill behavior.
- **Governance:** Step 4 now follows configured CHANGELOG_WRITES. Retain the planned exact probe source, nonempty outputs and provenance. Treat `route=docs` as an expected classifier result to measure against the actual final diff, not authority to bypass a different classifier result or required gates.

Evidence and limits: directly read the revised canonical plan, local `_assess_final_qa` / `build_report` and CLI argument contract, and Child / Normal Completion / KS-04 skill text. Graph Verify used `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation `2026-11-18T19:39:07Z`: `_assess_final_qa` search returned zero results (`has_more=false`), and coverage reported missing freshness for both target paths, so exact local source was authoritative. This round reviewed the local revision against the prior findings; it did not re-verify live issue bodies. No executable probes, suites, phase gates, git commands, source edits or implementation checks ran. Full-gate evidence remains **[Unverified — needs clone run]**. No approval depends on an assumed later relay gate.

**NEXT: Producer (Antigravity)** — implement the approved plan, retain the specified evidence, and return for independent Final QA.
