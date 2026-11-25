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
| OL-09 preparation published; Day 1 OL-10 baseline replays reproduced held dispatch. | Resolve R1 plan-QA blockers, then obtain independent approval before runtime edits. |

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

## Merge evidence

- PR #1514 merged 2026-11-19 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #1521 merged 2026-11-19 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- commit b76b62b1e02c landed 2026-11-17 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Day 1 OL-10 admission plan — 2026-11-25 (proposed; not approved)

Outcome: on the real Jog → Preflight → Marathon path, a currently reviewed and
ready preparation may reach the worker; current human/dependency holds, changed
acceptance, or source changed since the applicable review must park before worker
or native attempt. Preserve queue identity, execution history and existing cap.
This is setup/repair for #1609, not a live queue or Day 2 authorization.

### Recon and bet

At `b479f74e0278bf3bfaabca78200b1338f44faa8d`, Jog leases the pending row via
`jog_acquire_lease`, promotes a capture if needed, then `run_marathon_phase`
appends an execution, invokes target-root Preflight and parks on nonzero before
loading its pinned Marathon invocation. Preflight `fetch_issue_details` fetches
body/state only and `evaluate_candidate` checks acceptance fidelity and contract
probes; it does not consume the Conveyor preparation decision. Conveyor records
holds in the selection/capture and specifies a reviewed preparation PR, reviewed
commit and evaluated integration SHA in its issue marker, but that prose marker
is not a documented machine-readable attestation. Kickstart's
`issue_hold_reason` owns the existing `status:held`, `HELD:`, `Blocked by`, and
active `after` semantics; it is a queue-building consumer and does not sit on
Jog's dispatch path. `accepted-start` is lifecycle state, not a reviewed-source
witness. Existing native attempt writer in `rtl.py` owns the cap; no re-add or
reset is a refresh.

The smallest defensible bet is to extend the existing Conveyor preparation record
and Preflight's consumer, rather than infer approval from the label or parse
arbitrary natural language as approval. The preparation publisher needs an
unambiguous, reviewable identity tying the exact issue, reviewed capture and
relevant contract artifacts to the evaluated revision; the consumer must verify
that identity and current inputs before emitting the invocation. **The exact
representation and verification of an existing reviewed preparation remain a
plan-QA question:** the existing marker describes values but does not specify
machine grammar or reviewer authenticity. Do not implement a guessed format or
claim the existing label/comment proves approval. A concrete reviewed plan must
resolve this while preserving direct operator-authorized Jog/start-task work and
avoiding an invented parallel readiness database or blanket mandatory Conveyor
workflow.

Blast radius: shared Preflight and Jog consumers, including vendored installs and
existing offline behavior; a false hold stops eligible work, a false ready may
fire held work. Treat as Costly until scoped; rollback is revert the reviewed
change and keep affected rows parked, never erase history or re-add rows. Live
GitHub/transport failures must have a specified honest disposition rather than
silently granting current review. No new scheduler, suite, runner, gate, attempt
reset or production dispatch.

### Falsifiable acceptance and ordered work

1. Finish source/record trace and resolve the receipt/authority and compatibility
   contract through independent plan QA. Specify which exact source paths are
   reviewed, current issue and dependency state, operator hold release authority,
   stale/unknown behavior, and how a reviewed record is refreshed without changing
   the row or its budget. No runtime changes before approval.
2. Extend the existing preparation publisher and Preflight/Jog boundary only as
   approved, reuse existing hold semantics and park/history writers; do not
   duplicate a queue or persist a second independent decision store.
3. Replay existing retained fixture controls on real entry path with worker edge
   sentinel: ready = one call; human and dependency holds, stale acceptance and
   *actually bound reviewed source* changed after review = zero. Include matching
   fresh source positive control, hold release authority and unavailable/malformed
   record controls. Prove the changed gate rejects a pre-fix counterexample.
4. Refresh the same parked row using the supported recovery owner; compare exact
   global ID, all old execution records and byte-preserved prior native attempts;
   the subsequent worker fire consumes only the next existing allowance. Include
   exhausted native cap refusal and no worker call. No cap increase or force.
5. Record nonempty command outputs, fixture identity, exits and hashes with
   provenance; perform main/adjacent smoke, independent final QA, classify and
   qualify its exact approved head in a disposable full clone. Publish a ready PR
   only if all required evidence passes; otherwise retain the explicit hold.

Current red evidence is under `TESTS-RESULTS/2026-11-25+GH-1476-day1/`.
Ready, human-held and dependency-held each reached the sentinel once, stale
acceptance did not. The changed-source case lacks a reviewed-source binding and
is not a complete stale-review proof. Corrected refresh retained one synthetic
prior native line byte-for-byte and added a second on dispatch (receipt 2/2);
the first failed refresh and invalid inherited-override runs are not passes.

### R1 design revision — proposed contract for review

The owner of the existing preparation capture opts a lane into managed admission
with a versioned `preparation_admission` block **in that capture**, not a queue
or readiness database. It identifies the qualified issue, integration ref,
reviewed preparation commit, a committed independent-review transcript/receipt,
and the bounded source paths (capture, contract inputs and `artifacts` including
missing-path expectations). The existing preparation publisher writes this
block before review; the independent reviewer covers those bytes. Its finalized
Conveyor marker comment carries the exact reviewed commit and review receipt
identity after publication. A comment's own SHA or readiness label is not proof.
The consumer verifies the marker is authored by the configured repository owner,
that the cited preparation PR is merged into the selected integration history,
that its independent reviewer receipt actually binds the reviewed revision and
reports approval, and that the current capture/block matches that reviewed tree.
Do not accept an asserted reviewer string or self-authored prose as attestation.
Use the existing `relay_attest` validator where its bound evidence is usable;
if its absolute-path binding makes a committed receipt nonportable, extend that
owner with a portable, identity-checked export/read path rather than weakening
it or inventing a second review authority. Exact issue, reviewed commit, receipt,
PR and capture must agree; unavailable, missing, ambiguous, malformed, wrong
owner or unverifiable managed evidence parks with a specific reason. The marker
is a lookup/locator, not execution authority by itself.

Preflight compares Git object identity for each bounded path at reviewed source
and at its evaluated immutable ref, including expected absence; unrelated source
changes are permitted. Capture and contract bytes are included. Resolve the
actual lane branch before a native attempt and compare the same bounded paths in
its starting tree against that evaluated ref; if the branch is absent use the
current starting tree, if present verify that branch's tree. A mismatch or dirty
relevant path parks; no branch switch, token or attempt reservation on mismatch.
The invocation must carry the evaluated full SHA and relevant bound paths, not
merely a mutable ref name; revalidate immediately before dispatch and before
Marathon reserves the attempt. This is a candidate design to verify against the
existing structured invocation contract, not permission to weaken an existing
pin or create a standalone gate.

Managed selection is durable in the capture itself. Unknown GitHub lookup cannot
turn a managed capture into legacy: it parks. A direct/legacy capture without the
opt-in retains existing offline/fidelity behavior, while known explicit native
holds in live issue or capture still park. For managed lanes fetch issue body,
labels and owner decisions and relevant dependency status; unavailable information
parks. Reuse Kickstart's existing supported hold grammar and owner-authored latest
operator decision rules, with independent body/label holds continuing to block;
only the authorized owner may release a decision hold, and a dependency must be
verified resolved before a dependency hold is cleared. Never interpret a random
comment or bare readiness label as release. Preflight returns NOT-READY/BLOCKED,
not exit 4, so Jog's existing refusal writer records the execution and parks it.

R1 review dispositions: accept all three Blockers and the Should. The exact
artifact seed must be supplied and compared in the next review; the previously
read committed copy is substantive but not a seeded-input attestation. Preserve
the first red controls, then upgrade the disposable replay: append one line per
sentinel call; prove two calls fail the exactly-one assertion; snapshot full old
execution records and native bytes before retry, assert records identical and
native history retains the exact prefix plus one new line, with a byte-mutation
red control. Replace author-machine path in the reusable control with an explicit
fixture clone argument. Test an actual `Blocked by #902` and resolved/unresolved
state separately from HELD; add missing/wrong-author/offline managed cases,
legacy direct/offline behavior, fresh vs stale reviewed source, unrelated diff,
existing lane branch, and exhausted cap with identical history and zero calls.
Use `jog retry` as same-row recovery. The existing 2/2 fixture is evidence of
preserved prior native count, not proof of all these stronger assertions. R1 Nit:
OL-09 publication is historical and Day 1 plan QA is now the active hold.

### R2 contract corrections — supersede conflicting R1 text

**Publication sequence and authority.** The pre-review capture block contains
only `version`, qualified `owner/repo#issue`, integration ref, and normalized
bounded paths with present/absent expectations. It never contains its own commit
ID or a future receipt. Publish and review that capture in `2-WORKING` through
normal preparation QA. Conveyor runs non-dispatching contract/probe validation
without requiring the post-review record; that validation cannot emit an
executable invocation or confer admission. Once independent QA approves the
exact reviewed capture commit and its PR is merged, the existing Conveyor issue
marker gets one machine-readable payload: version, qualified issue, capture path,
reviewed full SHA, merged preparation PR number, review transcript path, and
approved review's full input SHA. The marker is authored by the configured
trusted operator login (the same explicit owner input used by Kickstart, or the
authenticated login when no owner was supplied); the trusted publisher attests
that independent QA covered that commit. This local-first trust assumption is
explicit: transcript hashes prove consistency, not reviewer identity; a copied
JSON/trailer or arbitrary self-authored comment is not independent proof.
Admission checks the marker author, exact PR/issue/capture/review identities,
merged PR head and integration ancestry, and reads the committed review transcript
at its published commit for the recorded approval and input SHA. A wrong author,
missing/unavailable lookup, divergent review, unmerged PR or ambiguity parks.
A repository whose landing policy does not preserve the reviewed commit must
prove exact reviewed capture and bound objects in its merged tree; absent that
proof it parks. No broad assertion that a path-bound `.git` attestation can be
copied between clones. Operator login is a login, never the organization slug.

**Classification and promotion.** Before Jog's promotion, consult the selected
integration tree's capture for the qualified issue, including both inbox and
working locations. A managed declaration there is authoritative even if the
execution copy loses its block. Managed inbox is held for publication and
independent review as a working capture; it is not rewritten on the way to
execution. A managed working capture must match the reviewed capture object and
be the exact doc Preflight selects. Removing the execution-copy block, missing
published object, conflicting captures or missing authoritative ref parks.
Withdrawal of managed intent is a separately reviewed/published capture change,
not omission in a local checkout. A genuine direct/legacy capture with no
managed declaration in the available authoritative integration tree retains the
existing direct/offline behavior; known positive holds still park. If no
integration tree is available, do not silently reclassify known managed work;
retain its previous managed identity and park. Tests must expose the case where
that identity cannot be established rather than assume offline lookup is proof.

**Holds.** Reuse the existing recognizer for `status:held`, line `HELD:`,
`Blocked by #N` and active `after #N`, but treat each as independent. A literal
HELD or blocker marker remains held until its authorized owner removes it from
the source as well as the dependency being verified resolved; resolution alone
never overrides explicit text. For issue dependencies require closed; for PRs
require merged, with closed-unmerged, unknown type and unavailable lookup held.
Unknown references park. Owner-decision holds are released only by the latest
configured owner-authored exact first-line `Operator decision: proceed` or
`Operator decision: close` (close routes to separate close handling, never build).
`pending`, free text and wrong-author comments do not release; a subsequent hold
supersedes. Label/body/dependency holds remain independently effective. The broad
existing decision regex cannot be reused unchanged for release.

**Typed handoff and park.** Extend the existing invocation with optional managed
binding `{version, reviewed_sha, evaluated_sha, paths}`; require all fields and
validated relative paths/object IDs together, reject malformed or partial fields,
and leave legacy packets without the field compatible. Reuse Marathon's branch
selection as the single owner: before switching/creating a branch and before
reservation, resolve its intended actual tree, compare bound objects to the
immutable evaluated SHA and check relevant dirty paths. The same check covers an
already-feature-branch target. Emit a valid `marathon-drive/result@1` with
`outcome=parked`, `reason=managed-start-tree-mismatch` and no reservation on
mismatch; Jog's existing `jog_project_marathon_outcome` maps parked to parked.
Include the bound identity in the existing invocation/result flow and verify it
again at the actual use boundary. A stale existing lane branch is preserved;
owner reconciles or reviews it separately, then uses `jog retry` on the same row.
No checkout, force, attempt reset or deletion to manufacture freshness.

R2 dispositions: all four Blockers accepted as corrections above; both Passes
acknowledged. Reviewer should test the chronological publication path, trust
assumption, managed-selector downgrade resistance, exact hold/release cases and
typed no-reservation park against actual source. Review is not approval of an
unimplemented portable receipt or proof of any unrun scenario.
