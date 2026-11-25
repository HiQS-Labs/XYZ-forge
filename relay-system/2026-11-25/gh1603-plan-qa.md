# RELAY · GH-1603 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry `Observed input:`, `Affected scope:` (the input predicate the change would govern),
     and `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected
     result). `Observed input:` accepts two strict, non-speculative forms:
     (1) **Form 1 (observed failure or artifact contradiction):** a failing probe/gate output, or a concrete
     `fileA:line` vs `fileB:line` contradiction (e.g. IAM SA mismatch, inverted test, sibling guard omission);
     (2) **Form 2 (unrunnable runtime hazard trace):** permitted ONLY when reproduction requires an external
     service, multi-process concurrency, or a browser/container runtime forbidden in the relay worktree —
     must supply a hop-by-hop `file:line` trace plus an exact `Clone probe:` command/script for the Producer's
     disposable full clone. Default severity for an unexecuted Form 2 hazard is `[Should]`.
     A `[Blocker]` must cite an observed failure (Form 1); an unexecuted Form 2 hazard stays `[Should]`
     until a probe reproduces it, and remains pending probe verification until the Producer runs
     `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, read the probe before running it — refuse any probe that reaches
     the network, credentials, or paths outside the disposable clone and record the refusal as
     `[Unverified — clone probe failed/unavailable]` — then execute safe probes in a disposable full clone and
     record one of three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output;
     (b) Falsified → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored, refused, or
     environment unavailable → keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking
     `STATUS: Approved` until re-run cleanly or escalated/parked). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh-1603-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: producer
- Started: 2026-11-25
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Plan review brief

Read only `PROJECT/2-WORKING/GH-1603-TRANSCRIPT-PARKING.md` first. Record the input boundary and write 2–5 sentences under **What this proposes** and **How the existing system works, per this document**, followed by **What it’s not** for any consequential exclusions. Then read the referenced source for technical validation and label the assessment source-backed.

The operational envelope is the local developer merge-cleanup CLI and its caller-owned parking workflow. Judge the actual plan under the Forge threat model and commensurate complexity. The reviewer may write only this thread.

1. Does one Phase 0 snapshot make all blockers and advisory stash/behind counts visible in the final lines and consistent with the primary row?
2. Will the same read-only transcript precheck govern parking for any candidate, fail closed on unknown visibility and cover transient commits, rename sides, staged and untracked artifacts?
3. Does the plan retain the existing readiness and parking ownership, avoid adding a subsystem and state residual disclosure limitations? Is deep cleanup traced?
4. Which observed base behavior rejects unchanged delivery, and does each acceptance check actually verify the intended behavior? No new tests or registry entries under GH-831.
5. Are the rating and rollback proportional? Can a changed candidate or a same-tip linked ref evade or contradict the proposed guard?

## Log

### Reviewer · Round 1

swept file: yes

Input boundary — I read the complete seeded plan, `PROJECT/2-WORKING/GH-1603-TRANSCRIPT-PARKING.md:1-44`, before reading implementation sources. The plan review brief supplies the artifact and criteria for this turn.

**What this proposes**

Capture primary readiness once for the Phase 0 display, audit row and dry-run footer, with stashes and behind-only counts advisory. Add a read-only check of transcript evidence before the caller publishes documentation history to a parking branch. A refusal leaves recovery local and subject to operator decision.

**How the existing system works, per this document**

Phase 0 checks whether the primary checkout can receive a landing, while the audit counts separately classified local refs for preservation. A linked branch can make two ref entries describe one commit. The orchestrator reports and gates landings; the merge-cleanup skill owns documentation parking and deep cleanup hands PR-worthy material to a fresh reviewed PR.

**What it’s not**

The change excludes a general-purpose secret scanner, automatic publication or ref repair, and relay-source prevention. A passing check carries the limitations at plan lines 35–38, including indirect or missing identities and files outside covered roots.

**Source-backed assessment**

I checked the related code and caller instructions in the relay worktree. The canonical clone's graph generation was `2026-11-25T18:12:31Z`, on a different revision from the named plan base, so the citations below use the worktree files. The findings below account for the defects found in the plan sweep and the relevant pre-existing source behavior.

- [Should] F1 — Bind the parking decision to the publish input. Make the caller check the exact candidate checkout and commit OID against the verified integration baseline for the actual push destination, then publish that OID under the existing creation-only lease. Recheck any changed candidate before publishing it. Treat equality of commit OIDs only as a reason to reuse a history walk; distinct checkouts can still have different index and worktree evidence.
  - Observed input: Plan lines 35–36 say to check the exact candidate again immediately before publication, yet `skills/2-daily/merge-cleanup/SKILL.md:179-192` describes inspecting a range, publishing a named branch to `origin`, then verifying its OID. The plan leaves the contract between the check and the push unstated. A creation-only destination lease checks whether the destination name exists. It supplies no evidence that the push source is the OID inspected, or that the destination used for publication is the one used to exclude already-published history. The candidate state also explicitly includes checkout-specific files (plan line 35), while `skills/2-daily/merge-cleanup/scripts/scan_clones.py:601-616,639-649` enumerates by ref even when OIDs match.
  - Affected scope: Caller-owned remote parking of a candidate whose ref, destination or local evidence differs from the input to an earlier check.
  - Falsifier: In a disposable clone, pass at clean tip A, then advance the named temp ref to B containing a fixture-private transcript before the publication step. The caller must refuse B or publish only A, as read back from the throwaway upstream. In a same-tip linked checkout, stage the private transcript only in the second index and expect refusal there despite the clean sibling result. Use the existing fetch and publication workflow; this needs no new lock or publisher.

- [Should] F2 — Define what the ref count means when squash provenance is incomplete. Preserve conservative checkout dispositions and label the count as unknown or explicitly incomplete when the evidence cannot classify it conclusively. Keep it independent of the integration ahead/behind count.
  - Observed input: Plan line 34 requires unknown on incomplete proof. In `skills/2-daily/merge-cleanup/scripts/scan_clones.py:662-692`, merged-PR lookup and diff failures add entries to `unlanded` and still yield `ok=True`. The empty/failed top-level path at lines 1082–1087 and 1447–1449 can also print zero. Using `prov["ok"]` as the sole display guard fixes only the latter. The held-on-lookup-failure behavior is already pinned in `test/gh534_phase_a_tests.py:252`.
  - Affected scope: Audit rows and footer counts when ref enumeration/fetch fails or a non-ancestor ref requires a merged-PR or content comparison that cannot complete.
  - Falsifier: A fixture with two refs at the same non-ancestor tip and a failed merged-PR lookup still preserves both refs, displays incomplete proof, and reports one integration-ahead commit. Repeat with a successful negative lookup and require a conclusive count of two refs. Separately fail fetch and require unknown without zero.

- [Should] F3 — Make the acceptance checks reject partial delivery across exit paths and give the counts an explicit meaning. Record labeled dirt, stash, ahead, behind, and separate ref-provenance values. Reuse the one snapshot for the primary audit readiness fields and footer, with a consistent baseline for its ahead/behind comparison. Keep the existing live execute recheck.
  - Observed input: Plan line 34 promises normal, scan-only, PR-only, discovery-error and selection-error coverage. Line 42 specifies a single dry run and “all four quantities” despite defining five distinct counts across that bullet and line 34. `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2781-2794,2816-2817,2899-2900,3048-3049` has independent returns. The one outlined check can pass with four of five counts, one footer path, and no operation marker. Phase 0 precedes audit discovery at lines 2696 and 2755, and audit ref classification fetches at `skills/2-daily/merge-cleanup/scripts/scan_clones.py:595-599`. A report can mix cached and refreshed evidence unless the plan defines the snapshot boundary.
  - Affected scope: The three named dry-run modes once Phase 0 has run, their discovery and selection errors, and advisory-only snapshots.
  - Falsifier: On the same diverged fixture set up an operation marker, or add it in a fixture variant. Require the last 20 lines of each mode to carry the blockers and named counts, including the two-ref versus one-ahead distinction. Inject discovery and selection failures and assert their existing nonzero exits and the same footer. With a clean behind-only/stash-only fixture require READY and visible advisory counts. Exercise cached origin plus a newer bare-upstream tip to show that the audit's primary readiness fields and footer still agree with the Phase 0 snapshot.

- [Should] F4 — Exercise the transcript decision through the caller procedure, and define the standalone check's read-only boundary. Dispatch the existing CLI's precheck before the ordinary scan, use read-only local evidence, and leave the caller's existing origin refresh in place. Record the actual root names and reuse a single checker for Phase 0 and standalone.
  - Observed input: Plan line 43 compares refs and status around the precheck and requires Phase 0 advice, but never checks that the caller skips publication. `skills/2-daily/merge-cleanup/SKILL.md:187-203` still publishes and proceeds after verification. The standalone CLI currently unconditionally scans after parsing options (`skills/2-daily/merge-cleanup/scripts/scan_clones.py:1494-1516`), which goes through `inspect_checkout:1077-1079` to fetch at lines 595–599. A fetch can write FETCH_HEAD while the observed refs and status remain identical.
  - Affected scope: The standalone candidate flag and the caller's remote parking path, including candidates outside the primary checkout.
  - Falsifier: In the existing manual matrix use a fixture-private ref, an unavailable/identity-mismatched lookup and an unreadable or unidentified transcript. For each, require refusal and demonstrate no remote temp branch was created by reading the bare upstream. Run the public-positive and same-repo ordinary-docs controls. Include concrete separate staged, untracked, removed-intermediate and rename-across-root cases. Trace the standalone path for absence of fetch or ref/index writes, comparing FETCH_HEAD, refs and index as well as status. Retain the red/green results under the established receipt convention.

- [Pass] The readiness/parking ownership and rollback fit the task. Plan lines 34–38 preserve the existing execute gate and put local preservation and any publish decision with the caller. `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2702-2710,2902-2919` already owns the strict gate and live refresh. `skills/3-weekly/merge-cleanup-deep/SKILL.md:131-139,189-205` forbids pushes from reviewed clones and hands selected work to a fresh PR. `utils/py/consult.py:701-709` and `relay-automation/relay-turn-lib.sh:125-128` establish the normal consult/relay root and archive layout. The 85/85/50/75 rationale and patch-revert rollback are proportionate for this bounded implementation. The publication decision itself carries disclosure risk, which the local fallback avoids.
- [Unverified — needs clone run] The baseline claimed at plan line 42 has a source-backed rejection: `scan_clones.py:1389-1399,1443-1449` reports local commits and a ref count independently, with no behind count, and `merge_cleanup.py:2862-2866,3048-3049` refers back to Phase 0 and ends without repeating the details. The base parking path at `SKILL.md:179-192` has document-history classification followed by a remote publish and lacks a transcript visibility decision. I did not execute a live red/green fixture or gate in this relay. Use the existing `test/gh436-merge-cleanup.sh` and `test/codex-turn.sh` plus the required full gate in a disposable full clone, as called for by plan lines 38 and 44. No new suites or registry entries.

VERDICT: FAIL

Basis: The plan needs explicit binding between check and publication, a complete provenance display contract, and acceptance checks that discriminate the promised early-return and caller paths from partial delivery. Producer should revise the plan and disposition F1–F4 before the next review.

### Round 2 · Producer

- F1 implemented in the plan. The caller binds the precheck to the verified origin and pinned commit, pushes that OID, and rechecks changed inputs.  [Unverified — no citation]
- F2 implemented in the plan. The independent ref count labels conservative classifications incomplete and top-level failures unknown.
- F3 implemented in the plan. The snapshot boundary and cases for all preview exits, operation markers, cached divergence and stashes are explicit.
- F4 implemented in the plan. The caller smoke exercises skipped and pinned publication against a bare upstream, including visibility and staged/renamed history variants. The standalone precheck runs before audit and has no fetch or optional index updates.
- Verification: Original-revision dry run reproduced missing footer details, 2 refs for 1 commit, and 0 displayed when ref proof failed. No production code changed. The updated base changes unrelated files and the ledger.

Re-review these four dispositions and report whether the revised plan is ready for implementation.

### Reviewer · Round 2

swept file: yes

Input boundary — I read the complete revised plan, `PROJECT/2-WORKING/GH-1603-TRANSCRIPT-PARKING.md:1-52`, before checking implementation sources. The plan review brief supplies the artifact and acceptance criteria.

**What this proposes**

Capture readiness once against the cached integration ref and reuse it in the primary audit row and preview footer. Keep the separate count of refs to preserve and show incomplete proof. Have the caller run the same read-only transcript check on the candidate checkout before parking, then publish only the inspected commit to the verified destination.  [Unverified — no citation]

**How the existing system works, per this document**

Phase 0 owns landing readiness, and the audit independently fetches and classifies refs for preservation. The caller owns remote documentation parking. Deep cleanup preserves backups and hands selected hunks to a fresh reviewed PR.

**What it’s not**

The plan limits screening to recognized repository evidence in the listed roots. It leaves automatic repair and publication outside the CLI and tracks relay-source prevention separately in GH-1604.

**Source-backed assessment**

The canonical graph generation `2026-11-25T18:12:31Z` identified the readiness and provenance callers. It is indexed on a different checkout, so the citations below use the seeded worktree. The plan sweep found no additional material defect within the brief.

- [Pass] F1 closed. The plan requires a refreshed baseline for the verified push destination, the exact candidate OID from the candidate checkout, publication of that OID under the creation-only lease, and a repeat check for changed inputs. The same-tip fixture varies the index, and the moving-ref fixture reads the result against the intended inspected OID. This binds the input that the current caller publishes. `PROJECT/2-WORKING/GH-1603-TRANSCRIPT-PARKING.md:43,51`; `skills/2-daily/merge-cleanup/SKILL.md:179-192`.
- [Pass] F2 closed. The plan retains conservative preservation, distinguishes top-level unknown from incomplete counted results, and specifies a two-ref control and a failed merged-PR lookup. The new distinction addresses the current paths where failed lookups still return `ok=True` or a missing proof renders zero. `PROJECT/2-WORKING/GH-1603-TRANSCRIPT-PARKING.md:42,50`; `skills/2-daily/merge-cleanup/scripts/scan_clones.py:595-599,662-692,1443-1449`.
- [Pass] F3 closed. One cached-ref snapshot governs the primary readiness fields and footer. The revised matrix names dirty, stash, ahead and behind, tests separate ref-proof counts, covers normal/scan-only/PR-only and discovery/selection errors, and advances the bare upstream to expose an accidental refresh of the readiness inputs. Stashes and behind-only remain advisory, and the execute path keeps its live recheck. `PROJECT/2-WORKING/GH-1603-TRANSCRIPT-PARKING.md:42,50,52`; `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2696-2710,2755-2760,2781-2817,2899-2925,3048-3049`.
- [Pass] F4 closed. Standalone dispatch precedes the audit fetch. The matrix checks refs, index, status and FETCH_HEAD and differentiates a refusal from actual publication by observing the bare upstream. It covers private/lookup failure, positive controls, unreadable or mismatched evidence, staged/untracked content, transient commits and both sides of renames. Caller ownership and the deep-cleanup fresh-PR path remain in place. The 85/85/50/75 rating and patch-revert rollback fit the bounded CLI and runbook change. `PROJECT/2-WORKING/GH-1603-TRANSCRIPT-PARKING.md:38,43-46,51`; `skills/2-daily/merge-cleanup/scripts/scan_clones.py:595-599,1504-1517`; `skills/3-weekly/merge-cleanup-deep/SKILL.md:131-139,189-205`.
- [Unverified — needs clone run] The producer reports the original-revision dry-run symptoms. The base source independently shows the Phase 0 local-commit count, independent audit ref count, and final warning referring back to Phase 0. The parking runbook goes from history inspection to publication. The clone matrix and existing suites/full gate remain implementation qualification, with red/green receipts to retain under the existing convention. `skills/2-daily/merge-cleanup/scripts/scan_clones.py:1389-1399,1443-1449`; `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2862-2866`; `skills/2-daily/merge-cleanup/SKILL.md:179-192`; `PROJECT/2-WORKING/GH-1603-TRANSCRIPT-PARKING.md:46,50-52`.

VERDICT: PASS

Basis: The revised plan closes F1–F4 and is ready for implementation. Approval covers the plan. Runtime qualification remains in the disposable full clone.


### Attestation · relay-drive — 2026-11-25T18:20:22Z
task: RELAY-gh1603-plan-qa
reviewer: codex
status: Approved
reviewed-head: 5e9480587c5d8502cb069717f18573036392ccfb
added-range: 20506+4629
added-sha256: 0356355898de28ba67fc803ad6fe25845cbbe6b1e1fcbd186f295cbb1a0c8561
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
