---
Goal: Final QA for GH-1299 (fold ceremony-audit into sanity-check)
Date: 2026-10-31
---

NEXT: none
STATUS: Approved

# Context

Review the committed change for https://github.com/HiQS-Labs/XYZ-forge/issues/1299: `git diff origin/development...HEAD`. Operator decision: fold the ceremony-audit skill (merged in PR #1289 for #1286) into sanity-check as Plan mode and add a mode-before-skill rule to skills/README.md. Evidence: TESTS-RESULTS/2026-10-31+GH-1299/ (fold-acceptance.md, raw/, inputs/, provenance.jsonl, gates.md).

Operational envelope: Markdown only, no scripts, no new tests (GH-831). Grade against the issue's scope and commensurate complexity. Do not ask for more acceptance rounds, scoring or tooling. Review only: edit nothing except this relay file. No network calls.

Known results to judge, not hide: the #1186 counter-example failed in both fold runs (both cut the optional red control); #1279 scored 4 of 6 with the tested wording, matching the standalone skill.

Questions:

1. Does skills/1-hourly/sanity-check/SKILL.md now carry the full ceremony-audit procedure (all Step 1–4 rules and qualifiers) without changing the existing ladder? Are the Plan mode triggers in the description? Cite file:line.
2. Is skills/1-hourly/ceremony-audit/ fully removed, with no live reference left (index row, links)? Is the ARCHITECTURE.md 1-hourly count (17, including `idea`) correct?
3. Is the skills/README.md rule clear and bounded, and does it sit with the existing add-a-skill contract?
4. Do the receipts and provenance support exactly what CHANGELOG.md claims, including the failed control? Is that an acceptable ship state, or does it block?
5. Is the 50/25/50/85 rating reasonable? Is skipping plan QA (operator-decided fold) acceptable?

Each `[Blocker]` or `[Should]` must carry `Observed input:`, `Affected scope:` and `Falsifier:` lines. Cite file:line.

Write your verdict below. Set STATUS to Approved if the change can ship as committed (minor notes allowed).

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->


## Codex final QA — 2026-10-31

**Ship. Approved for the Markdown fold as committed, with one nonblocking evidence note.** No Blocker or Should findings. Reversibility: Easy; this consolidates instructions without adding execution machinery.

1. **Procedure and existing ladder:** Plan triggers are present at `skills/1-hourly/sanity-check/SKILL.md:9–13`. Steps 1–4 and all their qualifiers are at lines 255–320: evidence before treating anything as proven, multiple open questions, required gates, known-bad controls, negligible-cost exclusions, proxy availability/approval, operator scheduling authority and an empty cut list. A read-only Python inspection of the local base objects at `origin/development=25bfa30fc52bfdef85f9f28b5a6c88b4f1d61109` found the original sanity-check body unchanged (current lines 18–240). Comparing the old ceremony procedure with current Plan mode, normalizing heading depth only, found no Step 1–4 difference. The removed trailing Composition, illustrative counter-example and success-summary sections are not omitted procedure rules; the empty-cut rule remains explicit at line 320.

2. **Removal and index:** The old folder is absent. The 1-hourly index has 17 rows including `idea` (`ARCHITECTURE.md:49–71`), matching 17 current hourly SKILL.md files. `rg -n --glob "*.md" "ceremony-audit" skills ARCHITECTURE.md` returned exit 1, no matches. A broader read-only reference scan found only the current GH-1299 capture/ledger naming the fold, plus excluded historical changelog, evidence and relay records; no live skill invocation/link remains in the scanned tree.

3. **Admission rule:** `skills/README.md:23–28` places the rule directly after the existing add-a-skill contract. It requires an existing-owner check for the trigger/unit, names the rejected owners in the plan, and illustrates this fold. It does not introduce a runner, scoring system or additional acceptance workflow.

4. **Evidence and failed controls:** `CHANGELOG.md:5` claims consolidation with tested wording and a failed compressed attempt, not full behavioral acceptance. The receipts support that bounded claim. The f2 #1279 output cuts spacing, crash/miss faults and slot accounting and keeps planted-flaw review, while retaining the adapter/driver and stopping short of a real marathon lane (`raw/f2-1279.md:13–40`); the recorded 4/6 is reasonable under the six-part rule. Both #1186 outputs cut the optional red control (`raw/f1-1186.md:13–14`, `raw/f2-1186.md:10–11`). Those are failures under the unchanged empty-cut-list criterion, not passes. All four provenance rows mark failure, including the partial worked examples (`provenance.jsonl:1–4`); `fold-acceptance.md:11–28` discloses the results. The input snapshots are nonempty and byte-identical to GH-1286. These results permit the operator-directed consolidation to ship with limits; they do not establish parity, improved efficacy or reliable preservation of controls. Plan mode still explicitly protects required gates and proof controls (`SKILL.md:276–289`), and the base ladder retains its authority safeguards (lines 36–42).

5. **Rating and plan QA:** The persisted 50/25/50/85 (`releases.sql:950`) is reasonable: moderate housekeeping priority, low consequence, neutral appeal and cheap Markdown work. The operator supplied the design (`PROJECT/2-WORKING/GH-1299-FOLD-CEREMONY-AUDIT.md:21–22`); skipping a separate plan-QA cycle for this bounded fold is proportionate. Final independent review is this receipt. No extra rounds, scores or tooling are required.

**[Nit] Causal attribution is stronger than the observations.** `TESTS-RESULTS/2026-10-31+GH-1299/fold-acceptance.md:25–27` calls the discrepancy “run-to-run variance … not a wording regression,” then correctly says it cannot be attributed with one sample per cell. The procedure wording matches, but its surrounding skill/context changed. Read the result as *cause unresolved; parity unproven*. Optional correction: use that phrasing. This does not alter the fail labels or block the requested consolidation.

### Verification scope

No git command, network call, suite, executable fixture or source/artifact edit was performed. Graph tools were unavailable; inspection used Markdown/source reads and bounded non-mutating probes. The base-object probe was invoked as `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'` (inline standard-library pack/tree reader); exit 0, decisive output: `original sanity-check body retained: True`, `hourly files: 17 idea: True`, `deleted folder absent: True`, `same nonempty input 1186 True`, `same nonempty input 1279 True`, `PROBE_OK`. Its procedure diff contained only deletion of the trailing sections identified above. An initial loose-object-only probe could not read the packed base; the successful probe handled packed objects.

Existing gate results are producer receipts, not fresh reviewer executions: `TESTS-RESULTS/2026-10-31+GH-1299/gates.md:1–8` records docs route, PDDA exit 0 and skill-viewer 8/8 at `031a39bd`. Final-state harness gating remains separate; no full-suite or promotion qualification is claimed here.

### Attestation · relay-drive — 2026-10-31T16:55:33Z
task: RELAY-gh1299-final-qa-095313
reviewer: codex
status: Approved
reviewed-head: 9245bac29b62597fea89d9e7a57aa789b746ebdf
added-range: 2128+5145
added-sha256: 42f80287624f26cd8780b5319af727d63fea0b087e75c8f0e78f092c329de52c
