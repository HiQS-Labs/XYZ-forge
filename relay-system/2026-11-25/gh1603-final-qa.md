# RELAY · GH-1603 final QA
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
6. **Manual relay: commit only the relay file** (`relay(gh-1603-final-qa): <role> r<N>`); no push.
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

## Final review brief

Review GH-1603 against its approved plan at `PROJECT/2-WORKING/GH-1603-TRANSCRIPT-PARKING.md`, plan relay at `relay-system/2026-11-25/gh1603-plan-qa.md`, the two scripts and two skill sections named in the plan, and the manual acceptance receipt at `TESTS-RESULTS/2026-11-25+GH-1603/manual-check.md`. The candidate includes the current integration as of this review. Operational envelope is the local developer CLI and the caller-owned parking instructions. Grade within that scope and the repo's commensurate complexity standard, with reviewer writes limited to this thread.

1. Does the shared Phase 0 snapshot carry all blockers and matching advisory counts into the audit and the last 20 lines on the documented paths? Does it retain current execute gate semantics?
2. Does the parking check cover the declared local history and index/worktree cases, refuse unknown visibility, and bind the checked OID and origin to the caller's actual publication? Evaluate the read-only and quiescent-caller assumptions. Is the local recovery option and deep-triage handoff sound?
3. Which observed red control prevents unchanged delivery for each behavior change? Does the real Git matrix substantiate the six acceptance cases without adding a suite?
4. Confirm the rating/persisted intake and scope, and call out a concrete regression if present. The existing suite and required full gate run outside this worktree, and require separate passing results before publication.

## Log

### Reviewer · Round 1

swept file: yes

Reviewed the seeded scan and merge-cleanup scripts, the Phase 0 and parking instructions, the deep-triage handoff, the approved plan and plan relay, and the manual receipt. I followed the existing audit, readiness, and teardown paths as well as the changed code. The nearest graph generation (`2026-11-25T18:19:12Z`) indexes the canonical checkout. The seeded worktree is the source for this review.

- [Blocker] F1 — The shared status helper bypasses the existing fail-closed test injection. Keep optional locking disabled while passing `status` as the first argument at the existing `run_git` seam, or update the existing injector for the new command shape.
  - Observed input: `test/gh534_phase_a_tests.py:502–509,522–526` injects failure on the prefix `["status"]` and requires `PRESERVE_UNVERIFIED_QUERY`. `skills/2-daily/merge-cleanup/scripts/scan_clones.py:1045–1051,1265–1272` now passes `["--no-optional-locks", "status", …]`. A `python3 -B -` probe imported `scan_clones`, patched `run_git` with the existing prefix predicate (`args[:1] == ["status"]`), and called `checkout_status(Path.cwd())`. It exited 1 with `existing injector matched=False` and `files=[]; error=''`. The registered suite imports this test at `test/gh436-merge-cleanup.py:1382`.
  - Affected scope: The existing status failure control in `gh436-merge-cleanup.sh`. A real status failure still takes the production error path.
  - Falsifier: The existing test's injected status failure must reach the preservation assertion, and its clean baseline must remain `SAFE_REMOVE_CLONE`. Run the existing suite in the disposable full clone.

- [Blocker] F2 — The standalone check clears an unidentifiable origin. Return a refusal when canonical origin identity cannot be established and retain the caller's independent check of the actual push destination.
  - Observed input: `PROJECT/2-WORKING/GH-1603-TRANSCRIPT-PARKING.md:51` requires rejecting unknown target identity. `skills/2-daily/merge-cleanup/scripts/scan_clones.py:1327–1331,1358–1371,1663–1673` converts an unrecognized origin into an empty string and returns success if there are no foreign slugs. A `python3 -B -` probe called `scan_clones.main()` with `--check-transcript-parking "$PWD" --parking-tip aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa`. It patched only `run_git` to return that SHA from tip resolution, `/absolute/unidentified-origin.git` for `remote get-url origin`, and successful empty history/index/worktree output. The probe exited 1 because the command printed `No transcript parking refusal for inspected commit aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.` and returned 0.
  - Affected scope: The standalone verdict for a candidate with a resolvable tip and a nonempty origin answer whose repository identity cannot be parsed. The runbook's separate destination check reduces the risk of acting on this verdict.
  - Falsifier: With the same pinned tip and no transcript changes, unknown origin must return 1. A recognized matching destination must still clear ordinary docs, and matching-origin and independently public transcript controls must still clear. Record the unknown-target case explicitly in the manual receipt.

- [Should] F3 — Pre-existing malformed merged-PR evidence can abort the audit before the footer. Validate returned row shape and route malformed evidence through the existing incomplete-proof path.
  - Observed input: A `python3 -B -` probe called `scan_clones.merged_pr_index(Path.cwd(), "development")` with mocked successful `run_git` origin `https://github.com/example-fixture/landing` and successful `subprocess.run` responses `{"url":"https://github.com/example-fixture/landing"}` and `[null]`. It exited 1 with `AttributeError: 'NoneType' object has no attribute 'get'` at `skills/2-daily/merge-cleanup/scripts/scan_clones.py:491`. This bypasses conservative classification at lines 663–668 when called from `inspect_checkout` at lines 1071–1081. The scan precedes the preview footer in `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2706–2715,2769–2776`.
  - Affected scope: Ref provenance queries for non-ancestor tips when a successful GitHub CLI response has a non-object row in its merged-PR list.
  - Falsifier: The same `[null]` response should preserve the affected refs, display `incomplete proof`, and reach the normal preview footer. A successful empty list should still produce complete negative proof.

- [Pass] With ordinary valid evidence, the audit uses the Phase 0 dirt/stash/divergence snapshot and displays independent ref proof. Normal, scan-only, PR-only, discovery failure, and selection failure reach the footer with their existing exits. Stash and behind counts stay advisory. Execution keeps the current override, stale-rebase check, remote refresh and live readiness recheck. `skills/2-daily/merge-cleanup/scripts/scan_clones.py:1420–1538,1553–1609`; `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2413–2425,2706–2725,2770–2776,2797–2810,2822–2833,2915–2960,3064–3065`.
- [Pass] The history/index/worktree scan and local recovery route follow the scoped design for identified origins. History includes intermediate commits and both raw blob sides, and index inspection is per checkout. Standalone exits before scan/fetch and uses no optional index locks. The caller verifies the fetch/push repository, uses the refreshed baseline, and publishes the inspected OID under a creation-only lease with quiescent inputs. Local recovery retains verified backup and operator-controlled refs. Deep triage keeps refused material in its verified backup before the fresh-PR handoff. `skills/2-daily/merge-cleanup/scripts/scan_clones.py:1298–1371,1659–1682`; `skills/2-daily/merge-cleanup/SKILL.md:181–215`; `skills/3-weekly/merge-cleanup-deep/SKILL.md:189–205`.
- [Pass] The retained receipt records the reporting red controls (omitted tail detail and false zero after failed tag proof) and the parking red control (the original route created the fixture branch with the transcript). It records the five preview routes, readiness controls, private/public/same-origin cases, staged/untracked/intermediate/rename variants, the read-only comparison and the pinned push. It does not separately demonstrate unknown target identity, as F2 shows. `TESTS-RESULTS/2026-11-25+GH-1603/manual-check.md:3–29`. `wc -c` and `shasum -a 256` on that receipt both exited 0, returning 4242 bytes and `33df4fb3c767c636a978b16a84960c70860a8f9afefa2cec702ece6f4bce3fac`, matching `TESTS-RESULTS/2026-11-25+GH-1603/provenance.jsonl:1`.
- [Pass] The active plan pointer stores 85/85/50/75 and the rated and accepted-start events persisted. The scope remains the local CLI and caller runbooks, with source prevention tracked separately. `releases.sql:1054,6068–6071`; `PROJECT/2-WORKING/GH-1603-TRANSCRIPT-PARKING.md:32–46,54–57`.
- [Unverified — needs clone run] The two existing focused suites and the full gate need passing results on the corrected candidate in a disposable full clone before publication. The manual matrix is evidence for its recorded cases. `PROJECT/2-WORKING/GH-1603-TRANSCRIPT-PARKING.md:46,50–52`.

VERDICT: FAIL

Basis: The existing fail-closed status control misses the new command, and the standalone transcript check accepts an unknown origin. The audit also aborts on malformed merged-PR evidence. Producer should disposition F1–F3 and return the corrected candidate with updated evidence.

### Round 2 · Producer

- F1 implemented. Git receives `status` as its first argument again, with `GIT_OPTIONAL_LOCKS=0` preserving the read-only state. The existing injected-error and clean baseline unittest controls both passed.
- F2 implemented. The standalone parking verdict refuses an unidentified origin before scanning. Phase 0 can still report transcript findings on local-origin development checkouts. The exact-tip fixture that previously cleared now exits 1, and identified same-origin, foreign-public and ordinary-doc controls still clear.
- F3 implemented. Malformed merged-PR list entries or merge-commit records are reported as incomplete provenance. The fixture `[null]` previously raised an AttributeError and now yields the expected 2-ref incomplete-proof footer and unchanged success status. The conclusive empty-list response still reports 2.
- Verification: reran the complete manual matrix on the corrected runtime candidate and updated the hashed receipt. The existing merge-cleanup suite is running in the disposable clone. The exact-commit full gate remains pending after reviewer approval.

Re-review the F1–F3 fixes and their replayed evidence. Keep the final gate distinct from this independent review.

### Reviewer · Round 2

swept file: yes

The Round 1 file sweep carries forward. For this turn I rechecked the corrected status, parking and ref-proof paths in the seeded files, the preview and execute consumers, the runbooks, the approved plan and the updated receipt. Graph generation `2026-11-25T18:19:12Z` traces the canonical checkout. The seeded source supplies the citations and probe inputs.

- [Pass] F1 closed. The existing injection predicate sees `status` first and optional locks stay disabled. A `python3 -B -` probe patched `scan_clones.run_git` at `checkout_status(Path.cwd())`, asserted `args[0] == "status"` and `env["GIT_OPTIONAL_LOCKS"] == "0"`, and returned the existing fixture's rejection. It printed `F1 argv prefix=status, GIT_OPTIONAL_LOCKS=0, output=([], 'status refused')`. Those assertions passed in the combined probe (overall exit 1 on the final F3 assertion below). The injected error feeds preservation at `skills/2-daily/merge-cleanup/scripts/scan_clones.py:1050–1056,1270–1278`; the fixture is `test/gh534_phase_a_tests.py:502–509,522–526`. The receipt records the Producer's passing injected and clean controls at `TESTS-RESULTS/2026-11-25+GH-1603/manual-check.md:31`.
- [Pass] F2 closed. The same `python3 -B -` probe invoked `scan_clones.main()` with `--check-transcript-parking "$PWD" --parking-tip` and a 40-character fixture OID. Mocked `run_git` returned the candidate OID and `/absolute/unidentified-origin.git`, which produced CLI return 1 after only candidate resolution and the origin query. Substituting `https://github.com/example-fixture/landing` plus empty successful scan outputs produced CLI return 0. Both assertions passed before the combined probe's F3 failure. Standalone dispatch requires a recognized origin and the caller checks the actual push destination, pins the inspected OID and keeps the checkout quiescent. `skills/2-daily/merge-cleanup/scripts/scan_clones.py:1334–1351,1668–1682`; `skills/2-daily/merge-cleanup/SKILL.md:189–204`; `skills/3-weekly/merge-cleanup-deep/SKILL.md:189–202`.
- [Should] F3 remains open for a malformed OID inside an otherwise recognized merged-PR entry. Treat this as incomplete proof by using the existing unusable-output path when the selected row lacks a usable merge OID.
  - Observed input: `python3 -B -` imported `scan_clones`, patched `run_git` to return a successful fetch, two local refs at the same 40-character `a` OID, an attached HEAD, ancestry exit 1 and matching origin `https://github.com/example-fixture/landing`. Mocked `subprocess.run` returned a matching `gh repo view` URL and the merged list `[{"number":1,"state":"MERGED","baseRefName":"development","headRefOid":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","mergeCommit":{"oid":null}}]`. The probe called `classify_local_refs(Path.cwd())` and `format_ref_count` on the resulting proof and held refs. It exited 1. Decisive output was `missing OID: audit='2', reason='not reachable from origin/development; no merged PR has this head'`. The same probe printed `prior control: audit='2 (incomplete proof)'` for `[null]` and `empty control: audit='2'` for `[]`. The known head is dropped at `skills/2-daily/merge-cleanup/scripts/scan_clones.py:493–503`, turning unavailable comparison evidence into a conclusive miss at lines 669–680 and an unqualified count at lines 1081–1084 and 1554–1559. The approved plan requires incomplete proof when a necessary comparison fails at `PROJECT/2-WORKING/GH-1603-TRANSCRIPT-PARKING.md:42`.
  - Affected scope: A successful merged-PR lookup for the selected base includes a row for an otherwise unproven local head whose merge OID is null. Both refs are still preserved.
  - Falsifier: Replay the exact three lists. The null-OID list and `[null]` should preserve both refs, return successful conservative classification and display `2 (incomplete proof)`. The conclusive empty list should still display `2`.
- [Pass] The corrected receipt covers the reporting red controls and the original fixture publication, the six candidate cases, and separate caller pinning and read-only controls. The same probe hashed the retained bytes and checked their length before the F3 assertion. It printed `receipt bytes=4645 sha256=68029cc65bded11d137d2489201e6544da4b065bf0755e5c3d7c4549ddd3dd8f candidate=564673af1f00f33405208fa6bfda68f79da9f515`, matching `TESTS-RESULTS/2026-11-25+GH-1603/provenance.jsonl:1`. The receipt's `[null]` result agrees with the independent replay. `TESTS-RESULTS/2026-11-25+GH-1603/manual-check.md:18–31`.
- [Pass] The same cached readiness snapshot feeds the primary row and the preview footer. Stash and behind counts stay advisory. Execute still refreshes and checks readiness before a merge. The 85/85/50/75 intake, rated event and accepted start are persisted. `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2706–2715,2775–2776,2915–2960`; `skills/2-daily/merge-cleanup/scripts/scan_clones.py:1538–1546,1562–1574,1589–1616`; `releases.sql:1054,6068–6071`. No additional material pre-existing issue surfaced in the reviewed paths.
- [Unverified — needs clone run] The existing merge-cleanup and Codex harness suites plus the exact-candidate full gate require separate disposable-clone results before publication. `PROJECT/2-WORKING/GH-1603-TRANSCRIPT-PARKING.md:46,52`.

VERDICT: FAIL

Basis: F1 and F2 close. F3 handles a null list entry and still calls a missing merge OID complete when that OID is needed to assess a known head. Producer should disposition the remaining F3 input and return its two-ref replay with the empty-list control.

### Round 3 · Producer

- F1 and F2 previously verified and closed. No changes to their paths this round.
- F3 finalized. The same-tip Git fixture with a matching merged PR and null merge OID had printed `refs to preserve (separate audit): 2`. It now prints `2 (incomplete proof)` and retains the full footer. The `[null]` list produces the same incomplete proof. The conclusive `[]` list still prints `2`. Invalid actual head/merge OIDs and missing repository identity go through the existing incomplete-proof path.
- Verification: the three distinct CLI probes ran against the disposable real Git checkout and the hashed receipt was refreshed. Full qualification remains separate.

Please close the bounded review if F3 is resolved and no material regression remains.

### Reviewer · Round 3

swept file: yes

The Round 1 file sweep carries forward. This turn rechecked the revised provenance path in the seeded worktree and the existing Phase 0, parking, and teardown consumers. Canonical graph generation `2026-11-25T18:19:12Z` supplied the call path; the seeded source and replay supply the current evidence. No additional material pre-existing defect surfaced in the bounded review.

- [Pass] F3 closed. Matched rows with unusable OIDs and malformed list entries now route to incomplete proof. The two local refs stay preserved. The empty-list control stays conclusive, and valid squash evidence still reaches the ancestry and content comparisons. `skills/2-daily/merge-cleanup/scripts/scan_clones.py:476–514,673–709,1081–1092,1559–1564`.
  - Probe command `python3 -B - >"$TMPDIR/gh1603-review.log"` with inline Python importing `scan_clones`, patching `run_git` for two same-tip refs and `subprocess.run` for the repository view and merged list, and calling `classify_local_refs(Path.cwd())` and `format_ref_count`. Exit 0. Decisive output was `null merge OID: ok=True, held=2, audit=2 (incomplete proof)`, `null row: ok=True, held=2, audit=2 (incomplete proof)`, `empty list: ok=True, held=2, audit=2`, `bad head OID: ok=True, held=2, audit=2 (incomplete proof)`, `missing repo identity: ok=True, held=2, audit=2 (incomplete proof)`, and `valid squash evidence: ok=True, held=0, audit=0`.
- [Pass] F1 and F2 remain closed. The status command retains the injectable argument prefix and disables optional locks. Standalone parking rejects an unknown origin before scanning. The caller verifies the push destination and publishes the inspected OID under a creation-only lease with quiescent inputs. Refused material stays local through the backup and deep-triage handoff. `skills/2-daily/merge-cleanup/scripts/scan_clones.py:1275–1290,1339–1352,1673–1687`; `skills/2-daily/merge-cleanup/SKILL.md:181–215`; `skills/3-weekly/merge-cleanup-deep/SKILL.md:189–202`.
- [Pass] The retained matrix records the original missing footer details, false zero after failed proof, and publication of the fictional transcript to a disposable origin. Its six outcomes cover the cached readiness snapshot and preview exits, distinct preservation counts, refused and allowed parking, the caller's pinned publication, and the clean-primary control. The new real Git CLI controls agree with the independent replay. The same probe matched the nonempty receipt to its provenance, printing `receipt bytes=4927 sha256=5487a790baebaf89bddf5ac4202da0c5943bb42c626804f0e162ee1e2905e20a candidate=bb6398fbe79dfcf49628a26320c963bef78b6b7c`. `TESTS-RESULTS/2026-11-25+GH-1603/manual-check.md:5–31`; `TESTS-RESULTS/2026-11-25+GH-1603/provenance.jsonl:1`.
- [Pass] The audit still presents the Phase 0 counts, and the execute path refreshes and rechecks readiness. The 85/85/50/75 rating and accepted start remain in the intake ledger. `skills/2-daily/merge-cleanup/scripts/scan_clones.py:1567–1621`; `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2915–2960`; `releases.sql:1054,6069,6071`.
- [Unverified — needs clone run] The existing merge-cleanup and Codex harness suites and the full gate still require separate passing evidence in a disposable full clone before publication. `PROJECT/2-WORKING/GH-1603-TRANSCRIPT-PARKING.md:46,52`.

VERDICT: PASS

Basis: F1–F3 are closed. The independent replay confirms conservative preservation with incomplete evidence and conclusive outcomes with valid evidence. Approval covers the bounded final review. Publication qualification remains pending.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
