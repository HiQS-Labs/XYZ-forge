---
gh_issue: 1476
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1476
title: "GH-1476: Raw task preparation"
status: "In progress (plan approved; implementation verification pending)"
created: 2026-11-16
updated: 2026-11-17
doc_type: feedback
owner: Codex
goal: Accept raw daily-goal tasks and research selected work consistently before execution admission.
effort: 2
complexity: 2
risk: 2
phases: 1
---

# Raw task preparation — OL-09 implementation slice

Canonical discussion: [Issue #1476](https://github.com/HiQS-Labs/XYZ-forge/issues/1476).
Umbrella: [Issue #1400](https://github.com/HiQS-Labs/XYZ-forge/issues/1400), 40% after OL-14 landed; OL-09, OL-10 and OL-12 remain toward 55%.

## Status

| What was just completed | What's next |
|---|---|
| Plan QA round 4 and final QA round 2 approved; manual scenarios, docs checks and Small gate passed. | Publish reviewed PR; real OL-09 witness and OL-10 remain separate. |

## Requested outcome and boundaries

RAW means an existing open GitHub issue, including a daily-goals issue, without requiring a roadmap row, capture or contract. Conveyor owns explicit issue/daily-goals intake. A daily-goals issue is an operator-named open GitHub issue whose body lists goals. Preserve its text and holds; report explicit #N links to open issues as candidates, not automatic selection. Prepare linked candidates only when individually named by the operator or inside the existing authorized batch scope, counting against its item/time limit (existing default five). A goals issue linking twelve tasks does not authorize twelve preparations. Without selected linked issues or batch scope, report candidates and await selection. Unlinked or ambiguous goals remain recorded holds for decomposition; this slice does not invent issue-creation authority. 10days retains its age-window entrypoint. Accept RAW daily-goal requests at intake. For selected unprepared work, bounded medium research is the default; deepen when evidence justifies risk or actual effort. Reuse applicable research. Unknowns remain visible holds, and risk deferral requires an explicit batch-scoped request. Preparation grants no dispatch authority. Preserve original acceptance, operator scores/overrides, ownership and cumulative budgets.

This slice implements OL-09 instructions through existing Conveyor and 10days. OL-10 actual stale/held admission refusal remains separately open in this issue; do not claim runtime enforcement from prose. No runtime code, new queue/state/schema, test suite, new daemon, installed skill edit, #1328 amendment, or live backlog execution. No dependency on landing PR #1491 for these instruction changes. This PR will use Refs #1476, not close the whole issue.

## Recon and smallest viable bet

Base: `f346d8908a42cd6e7e92f80657f9e7a21208e0ae`. The source Conveyor flow already accepts missing rows/contracts and grounds preparation, but Step 2 has no medium-depth default or bounded research selection contract. 10days Step 2 immediately excludes completed-folder captures; Step 3 defaults to binary INCLUDE/EXCLUDE, scores appeal from clarity and forcibly clears overrides; Step 8 mixes holds into exclusions. Its Step 5 --deep refreshes preflight, not research depth. Jog already owns a detailed preparation/admission handoff. No runtime discovery is needed for this instruction-only change.

Smallest bet: own one research-depth policy in Conveyor and link 10days to it, correcting conflicting selection/reporting text. Existing open #1476 already owns the ask; prior-art query medium research preparation found no matching open/merged PR or existing-fix candidate, with no API errors. This is bounded search, not exhaustive prior-art proof. Graph primary generation 2026-11-16T19:03:06Z reports no recorded gaps/metadata match for the four relevant skill paths; exact source at the stated base was read for material claims.

Alternative rejected: merely adding another umbrella paragraph leaves contradictory consumer instructions intact. A new research runner or automatic readiness gate is unnecessary for OL-09 and would expand into OL-10. Reversibility Easy: revert source instructions through normal review; retain intake and evidence, never erase held tasks.

## Ordered implementation and verification

1. Review this plan before changing skill instructions. Keep primary-owned rating checkpoint; use the existing independent relay protocol, valid verdict/Basis and actual attestation. Preserve round budgets.
2. Add Conveyor's canonical RAW preparation policy before its flow: accept raw requests without manufacturing contracts, distinguish already-prepared freshness reuse from medium research, default one read-only research child for selected unprepared work, and deepen on concrete state/authority/recovery uncertainty or credible high actual effort. Before launching research, record its numeric deadline and remaining authorized budget in the parent selection/recon note (before a capture or preflight packet exists); carry it into the capture doc / Conveyor preparation packet, never into the swarm-preflight packet schema; set proportionate per-run bounds, not mandatory global 20/60/90-minute defaults. Exhausted time or attempt budget forbids launching research. No automatic cap renewal. If a supported child route is unavailable, record the hold and next owner rather than silently substitute. Medium output covers baseline, owner/state/dependency boundaries, discriminating checks, bounded artifacts, acceptance, foreseeable approvals/runtime needs, unknowns and next owner. Human/product decisions stay held. Distinguish read-only research from independent preparation review and publication.
3. Update all conflicting 10days locations: completed-folder guardrail and Step 2, Step 3 sanity filter/ratings/verdict schema, Step 4 research and contract sniff, Step 5 terminology and duplicate pickup directions at current lines 338–343 and 393, Step 6 preflight disposition, and Step 8 reporting. Consume the policy within its existing batch owner. A completed folder alone cannot exclude an open request. HELD is a reporting disposition, not a new persisted queue state. EXCLUDE requires affirmative delivered/duplicate/not-work/superseded evidence; unknown reproduction/access is held. Preserve live issue authority. Use start-task rating policy (neutral appeal50 absent operator value, cheapness inverted, no forced clearing/rescoring). Step 3 validity researchers report provisional findings/ratings only, with no ledger writes. Selected means the parent has explicitly committed a bounded candidate set after validity triage; it does not mean ready or admitted. In Step 4, before contract authoring, reuse fresh preparation or dispatch one read-only medium research child per selected unprepared issue under the canonical Conveyor policy. Step 3 stays cheap validity triage; do not apply the medium checklist to the entire window. Reuse only a prior record already containing the full medium checklist for this issue. Freshness uses the existing 2-WORKING/has_contract route and Step 5/6 preflight, not a new staleness rule. Children must not invoke Conveyor Steps 3–6, write captures/ledger, publish, or execute. The parent preparation owner alone advances capture/contract/review after research. Keep Conveyor Steps 2→3→4 and its pickup command unchanged: research, capture, then pickup with the real capture path. Clarify only that shortlisting is not committed selection and preparation selection is not execution admission; #1328 before-dispatch here refers to execution dispatch, not a mandate to move Conveyor pickup before research. In 10days, record committed candidate selection in the parent selection/recon note before research. Collapse both pickup directions (current 338–343 and 393) into one parent-owned pickup after capture synthesis in Step 4, supplying the real existing --doc-path, before Step 5 and any execution dispatch. Never omit --doc-path for a no-capture item: the writer otherwise invents a nonexistent path. Research-held items remain in the note, without creating a dangling ledger row. Step 3 HELD/EXCLUDE candidates receive no selection/rating write. Make 10days frontmatter ratings/overrides (current lines 225 and 316–320) read-back displays of the canonical ledger, not a competing editable ranking. Explicit justified re-rates pass retained --ovr. Preserve malformed operator overrides and hold for an operator decision rather than clearing them. Keep acceptance copying, probe execution, overlap, auto-fire readiness prerequisites and wave ownership unchanged. Correct their disposition text: contract sniff failures are HELD and reported in the Held section, not Exclusion Ledger; HELD removes the item from this run’s Step 5 intersection and fire list, so it is not dispatched; preflight exit 4 alone is not proof of delivery and is HELD pending evidence distinguishing already-fixed behavior from invalid/wrong-polarity probes. Affirmatively verified delivery may be excluded. Remove automatic low-risk exclusion unless risk-deferral mode was explicitly requested. Explain that marathon-plan --deep refreshes preflight and does not select research depth. Report held and excluded separately.
4. Validate main consumer path and adjacent reuse path by a manual instruction walk with predeclared expected dispositions: ordinary RAW no-contract input gets medium research; valid prepared input gets freshness reuse; unresolved access/product decision gets a visible hold; high-risk state boundary gets deeper bounded investigation; explicit risk-deferral gets scoped deferral only. Use minimal paper scenarios, no fake product work, model calls or builder dispatch; old conflicting text is the red control. This proves instruction consistency, not behavioral compliance by a model or actual admission interception. Do not tick OL-09 in #1400 on this PR. Its checkbox stays unchecked until a real bounded run witnesses the preparation behavior; state this in the PR, CHANGELOG and evidence.
5. Run classified docs checks, retained provenance and independent final relay QA. Final diff limited to Conveyor/10days instructions, this plan, CHANGELOG, required governance checkpoint and evidence. Publish reviewed source PR to development, no automatic merge/deployment. Record actual checks/reviews and open OL-10/real-follow-up work. No new test suites or speculative runner.

## Round 1 dispositions and falsifying scenario matrix

Round 1 FAIL is preserved in `relay-system/2026-11-16/gh1476-plan-qa/`. B1 and S1–S6 accepted; remaining plan review budget is 2 of 3 rounds. No production source changed before approval.

Each row must name the old instruction that gives the wrong result (or missing rule), the revised owner/line, and expected output. Run the main Conveyor path and the 10days consumer where applicable; a paper pass is documentation consistency only.

| Scenario | Old source / control type | Required result and revised owner |
| --- | --- | --- |
| Selected RAW issue without contract | Conveyor Step 2 / 10days Step 4: missing medium-default rule | Parent invokes bounded medium research before authoring contract. RAW intake itself already works and is only a regression check. |
| Goals issue with 12 linked tasks and an ambiguous goal | Missing daily-goals selection rule | Conveyor reports candidates; only explicitly selected/authorized batch items prepare, at most existing default five; ambiguity stays held under goals issue. |
| Fresh prepared item | 10days:221 existing freshness route; regression control, not claimed pre-fix failure | Step 4 reuses applicable full preparation after existing freshness/preflight; unnecessary medium child fails revised rule. |
| Open issue with completed-folder capture | 10days:73–75,220, red control | Reconcile live issue; folder alone cannot exclude. |
| Legitimate low-risk task without requested deferral | 10days:244, red control | Remains eligible; no automatic discard. |
| Unknown reproduction/access or bad contract | 10days:288,389–391,546, red control | Report HELD in Held section (not Exclusion Ledger), reason/owner retained, absent from Step 5 fire intersection. |
| Wrong-polarity preflight exit 4 versus confirmed delivered item | 10days:430, red control | Investigate reason; wrong/unknown probe holds; affirmative delivery excludes. |
| High-risk boundary or credible high effort | Missing deeper-research trigger | Existing parent preparation owner requests bounded deeper research/decision/spike or holds. |
| Explicit batch risk-deferral | 10days:244 implicit exclusion, red control | Apply only in requested batch, retain tasks and authority checks. |
| Operator score or malformed override | 10days:232,250,253, red control | Preserve valid values; appeal50 absent operator value; malformed override holds, never auto-clears. |
| Justified re-rate and frontmatter display | 10days:225,253,316–320 vs start-task rating policy, red control | Parent writer passes retained --ovr; doc values are DB read-back only. |
| Shortlist research versus committed 10days selection | 10days:253–254,338–343,393, red control | No shortlist/child writes. Selection note before research; one Step 4 pickup after capture exists with real --doc-path, before Step 5. Research-held no-capture items get no dangling row. |
| Conveyor with absent capture | Conveyor:25–36 existing order; regression control | Research→capture→pickup real path, no advance write to nonexistent capture. |
| Research before packet / exhausted budget | Missing pre-research budget record | Parent note exists before launch; exhausted budget prevents launch; capture inherits note without packet-schema changes. |
| Raw goal with no existing issue | Conveyor:19 existing clarification boundary; regression control | Clarify target or explicitly requested /idea; never fabricate an issue or execution authority. |
| Instruction PR and paper walk completed | PR assertion, not red control | OL-09 stays unchecked; no OL-10, rubric change, global defaults or deployment claim. |

Record old/control outcomes honestly: missing rules demonstrate policy gaps; existing behavior is a regression control and must not be called a reproduced defect. During implementation add exact revised source-line evidence for each row. This is a manual prose walk, not a new test suite.

Round 2 FAIL retained at helper commit `84bae47dd09712f50a247e09491ecde2c61484e6`. S-A through S-D and N-A through N-E accepted above. Final round 3 of 3 remains; no attempt budget reset.

## Acceptance mapping

- RAW missing-contract/no-row requests remain accepted for preparation, never fabricated as ready.
- Medium research defaults for selected unprepared work; applicable prepared evidence is reused.
- Concrete high risk/actual effort triggers deeper bounded investigation, a decision/spike, or a visible hold, never silent exclusion.
- Explicit risk-deferral is scoped to its batch and grants no approval bypass.
- Ratings preserve operator values; appeal is neutral otherwise. Primary selection writes remain canonical.
- Daily-goal intake retained; 10days stays batch owner and is not re-enqueued into Jog.
- OL-10 runtime admission, #1328 fourth-gate proposal and numeric global defaults are not claimed implemented.
- Source instruction changes are independently reviewed and checked; deployment and unattended qualification remain unproven.

## Rating rationale

2026-11-16: retain proposal 75/60/50/60, no operator override. Priority reflects the requested near-term preparation bottleneck; severity reflects observed workflow loss and selection uncertainty, not data corruption. Appeal50 neutral; cheapness60 assumes a bounded instruction change with existing owners. Recurrence window 2026-11-03–16 versus 2026-10-20–11-02: this task has concrete recent Sunday-trial preparation/review stalls and #1476 recon, but no deduplicated incident census for either window; trend unknown. Do not infer increasing frequency from repeated reports of the same run. Read-back from the canonical writer will be retained before review.

## Lessons Learned (For Future Agents)

Pending implementation evidence; NO_ENTRY at planning time.

## Round 3 disposition — historical approval hold

Round 3 FAIL retained in gh1476-plan-qa-r3.md. R3-A and N-F accepted and corrected: note selection before research, pickup only after capture exists, explicitly refuse launch at exhausted budget. All three plan review rounds are consumed. No approval attestation, no production instruction changes, and no OL-09 completion credit. A further independent review requires an explicit budget extension; no fourth call is authorized or launched.

## Merge evidence

- PR #1491 merged 2026-11-17 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Round 4 approval and implementation dispositions

The operator authorized up to two additional rounds on 2026-11-17; this supersedes
the historical no-fourth-call restriction above without resetting attempts. Round 4
PASS / Approved, driver exit 0, reviewed plan `bdb583abb` at thread head `43c3c44a`;
review and attestation retained in `relay-system/2026-11-16/gh1476-plan-qa/gh1476-plan-qa-r4.md`.
Round 5 was not needed. Accepted Nits: refresh displayed ratings after pickup; give
an existing unrated row its first rating without force and preserve override;
record the extension; update umbrella progress to 40%. Source instructions were
unchanged by integration with `9331cec67`; the one plan merge conflict preserved
both the historical review hold and upstream merge evidence.

Implementation uses the existing writer for accepted-start and promotion of row
`rmi-01M7KXFFGFMZ2KHFDXR4XK1CM8`, preserving 75/60/50/60 and null override.
No OL-09 completion credit, runtime enforcement or deployment is claimed.

## Final QA round 1 dispositions

PASS / Approved with four Nits. Accept N1/N2: canonical completed-folder capture reuse and research-grounded auto-draft wording clarified. Accept N4: retained ledger-check log hashed. N3 is pre-existing primary-writer governance, outside this instruction slice; unchanged and not claimed solved. Small follow-up awaits round-2 review; required classified gate pending.

Final QA round 2 approved (`3bbb710ab`); Small gate passed on that head with identity unchanged. Evidence: `TESTS-RESULTS/2026-11-17+GH-1476/`. Lessons: NO_ENTRY; paper instruction checks do not establish autonomous behavior.
