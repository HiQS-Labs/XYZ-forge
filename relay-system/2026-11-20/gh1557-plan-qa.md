# Relay: GH-1557 (KS-13) Plan QA — Final-QA Staleness Detection & Automatic Child Re-Run

STATUS: In progress
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
