# Final QA Relay — GH-1557 (KS-13: Final-QA Staleness Detection & Autonomous Child Re-Run)

STATUS: Approved

- **Issue:** #1557 (parent arc #1541, milestone KS-13)
- **Candidate Head:** `ab8b4ee3a8ceb8195d510746fb3a5026c8e06a56`
- **Base Head (`origin/development`):** `6062aa2ea77a01a9d395f0cee971a0bdcf62c3e0`
- **Plan QA Relay:** `relay-system/2026-11-20/gh1557-plan-qa.md` (Turn 4 `Approved`)
- **Route:** `docs`

## Turn 1 — Producer (Antigravity)

Implemented GH-1557 (KS-13) per the Codex Plan QA R2 approved plan (`relay-system/2026-11-20/gh1557-plan-qa.md`, Turn 4 `Approved`) on candidate HEAD `ab8b4ee3a8ceb8195d510746fb3a5026c8e06a56` (based on `origin/development` `6062aa2ea7`):

- `skills/1-hourly/kickstart/scripts/kickstart_status.py`:
  - Fixed the multi-SHA `later_landings` staleness check (`shas and all(_sha_matches(s, qa_sha) is True for s in shas)`).
  - Fixed a real `line_no` vs `line` bug caught by our executable probe: `run_record.py` writes `"line_no"` on parsed `GATE:` entries whereas `_assess_final_qa` previously read `g.get("line", 0)`, causing `qa_line=0` and falsely flagging pre-QA landings as later landings after a re-run. Now reads `line_no` with fallback to `line`.
  - Added explicit machine-readable and Markdown fields (`rerun_required`, `handback_allowed`, `latest_landing_sha`, `target_head`, `recommended_action`).
- `skills/1-hourly/kickstart/SKILL.md`: Updated Child rule 5, Transition 1, and the KS-04 staleness section with a single reconciled decision table (including the 0-landing exception and post-QA head re-verification).
- `CHANGELOG.md`: Recorded the GH-1557 entry.
- `TESTS-RESULTS/2026-11-20+GH-1557/`: Retained executable probe `outputs/ks13-probe.py`, full output `outputs/ks13-controls.txt` (Part A executed red/green CLI controls against baseline `6062aa2ea7` vs candidate + Part B explicitly labeled simulated consumer walkthrough), `outputs/mypy.log`, `outputs/ci-route.log` (`route=docs`), `outputs/pdda-run.log`, `outputs/code-and-docs.patch`, `manual-check.md`, and `provenance.jsonl`.

Please review for Final QA approval.

**NEXT: Reviewer (Codex)**


## Turn 2 — Reviewer (Codex), Final QA

**Verdict: Approved for the scoped KS-13 implementation.** The seeded source implements the approved decision table, fixes multi-SHA suppression, and corrects canonical gate ordering/position to use `line_no` with legacy `line` fallback. No blocking defect found in the reviewed changes. This approval does not certify live autonomous child behavior or a full-gate run.

- **[Pass]** `skills/1-hourly/kickstart/scripts/kickstart_status.py:_assess_final_qa` preserves same-SHA exclusion and SHA-less later-landing detection, blocks stale/red/missing-with-landings handback, and holds unknown head freshness. The `line_no` correction also prevents pre-QA landings from being mistaken for later landings after a rerun.
- **[Pass]** `skills/1-hourly/kickstart/SKILL.md:104-123,227-235,270-283` consistently requires the child decision check, autonomous rerun, green only after both checks succeed, post-QA remote-head re-verification, and failure/hold handback. The intentional no-landing exception remains explicit.
- **[Pass]** Read the retained probe source and outputs, including isolated baseline red controls, parser/CLI rerun sequence, red rerun, concurrent landing and simulated consumer walkthrough. Independently verified all six provenance entries against nonempty artifact bytes, sizes and SHA-256 hashes. Retained mypy reports no issues; classifier reports `route=docs`; PDDA reports no errors and 36 warnings. These are retained producer results, not gates rerun by this reviewer.
- **[Nit]** `_render_markdown` displays the new action, target and handback/rerun fields but omits `latest_landing_sha`. JSON includes it. Displaying it would fully match the plan's “render them” wording; this omission does not affect the handback decision.

### Independent narrow probes

Ran the following non-mutating command (exit **0**); the mutation exists only in memory, with no fixture, gate or git invocation:

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PROBE'
import importlib.util, inspect
s=importlib.util.spec_from_file_location('ks','skills/1-hourly/kickstart/scripts/kickstart_status.py');m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
src=inspect.getsource(m._assess_final_qa); old='shas and all(_sha_matches(s, qa_sha) is True for s in shas)';assert old in src
ns=dict(m.__dict__);exec(src.replace(old,'any(_sha_matches(s, qa_sha) for s in shas)'),ns)
a='a'*40;b='b'*40;p={'gates':[{'target':'final-QA','sha':a,'verdict':'green','line_no':5}]};land=[{'line':6,'sha':b,'shas':[a,b]}]
for label,fn in [('candidate',m._assess_final_qa),('any-mutation',ns['_assess_final_qa'])]:
 r=fn(p,land,None,a); print(label,r['status'],len(r['later_landings']),r['handback_allowed'])
 assert (r['status'],len(r['later_landings']),r['handback_allowed']) == (('stale',1,False) if label=='candidate' else ('fresh',0,True))
PROBE
```

Decisive output:
```text
candidate stale 1 False
any-mutation fresh 0 True
```

A separate import-only assertion probe (exit **0**) checked same-SHA, SHA-less, pre-QA `line_no`, and absent-head cases, yielding respectively `fresh 0 True`, `stale 1 False`, `fresh 0 True`, and `unknown 0 False`; its provenance check reported `provenance: 6 nonempty artifacts match size and sha256`.

### Evidence limits

Graph Verify lookup used nearest indexed `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation `2026-11-18T19:39:07Z`. `_assess_final_qa` had no hit (`has_more=false`); coverage freshness was missing for status script, parser and skill, so direct local source was authoritative. No git commands were run, so this review assesses seeded bytes rather than independently attesting candidate ancestry or final-diff classification. Retained replay metadata names `d3568cd9f8787aef9528f2fa7897446d0274fa68`, not the advertised final candidate `ab8b4ee3a8ceb8195d510746fb3a5026c8e06a56`; the current-source probes above independently check the central decision logic but do not turn that earlier replay into a final-commit gate receipt. Live issue bodies were not queried this turn.

**[Unverified — needs clone run]** Actual full-gate execution and live autonomous child rerun remain run-2 acceptance work, as expressly separated by the approved plan. Part B is simulation, not runtime proof. No suites, executable fixtures, phase gate, source changes, other tracked edits, or self-commit occurred, and approval assumes no later relay gate.

**NEXT: Done** — approved scoped implementation; retain the live run-2 limitations in downstream reporting.
