# RELAY · GH-981 optional dashboard final QA for visual review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-06.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 3

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
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-981-optional-dashboard-final-qa-for-visual-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Review envelope

Review the entire optional `addons/paperclip-dashboard/` implementation, its attribution/license, approved plan/recon, evidence and diff from `85556455`. Artifact implementation is `0ae105bc`; this receipt and later gate/status receipts do not change its runtime bytes. Review both correctness and fidelity to the user: isolated folder, optional read-only add-on, visual evaluation before any merge. Read existing shared modules at their source seam. No React runtime migration, task writer, default startup, schema or connector change is authorized.

All screenshot records are synthetic. Browser keyboard focus failure was observed and repaired; Option-Tab + Return now preserves focused row. Manual HTTP boundary and source immutability passed (retained negative control). Existing focused pytest is explicitly RED: 34 passed / 5 failed at an unchanged Darwin Python `os.waitid` incompatibility; do not call it green. Tier 3 full qualification follows this QA checkpoint in a separate disposable full clone. A PASS may approve the implementation for visual/draft review only; it must not attest merge readiness or a pending gate.

Source reference is `/Users/noelsaw/Documents/GitHub/paperclip-fork` revision `90182b4f8b40d6ee217937ba61199b4abc31dee7`. Codebase-memory graph tools were unavailable; source-grounded searches/recon were used. Read paths are safe; never run pytest, validate.sh, test/*.sh or executable fixture harnesses in the reviewer worktree. Narrow non-mutating code inspection is permitted with scratch containment. Grade observed input, affected scope and falsifier for any behavior change requested. Avoid speculative production machinery for this local visual spike. Do not modify implementation or source inputs; append findings only to this review thread.

## Setup
- Artifact under review: **SUMMARY.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-10-06

### Artifact — SUMMARY.md
```
# GH-981 spike verification

The synthetic dashboard is usable for operator visual review. Optional demo/live boundaries and existing fixture/manual checks passed. Independent final QA and the required full gate follow this checkpoint; no merge readiness is claimed.

- Browser: desktop, 430 CSS-pixel compact container, dark and collapsed screenshots; filters, keyboard row selection, Escape, selectable handoff, empty/stale/partial/failure/hostile scenarios inspected through native Safari. Compact preview is not device emulation. Retained screenshots use synthetic records in a separate window, avoiding other open task tabs.
- Observed red keyboard control: selection originally moved focus to the document after a full render. The renderer now restores focus to the matching generated control; Option-Tab/Return was rechecked and retained row focus. Expiry recomputation keeps the handoff textarea present.
- HTTP manual boundary: demo snapshot GET forbidden, asset allowlist nonempty, traversal/foreign Host rejected, loopback-only bind and shared CSP/no-store headers passed. Explicit live fixture snapshot was nonempty; source files stayed byte-identical. Forced aggregator exception returned 503. The source-immutability assertion failed after deliberately changing a disposable fixture, then passed when the original bytes were restored.
- Existing `python3 -m src.flightdeck.manual_harness --check`: passed, including its negative controls and source immutability assertions.
- Existing `python3 -m pytest -q test/flightdeck`: **34 passed, 5 failed**. All failures reach unchanged `utils/py/releases_cycle.py` and its `os.waitid` call; this Darwin Python3.9.6 has no `os.waitid`. It is a pre-existing implementation/environment incompatibility, not a green focused suite. The add-on renderer and its bounded fixture path are verified separately. No gate or tests were weakened.
- PDDA frontmatter/status-table/roadmap-coverage: zero errors/warnings at checkpoint. The route classifier selects **tier 3** for the unmapped optional launcher; no mapping was added.
- Existing core Flightdeck source/UI files and dependency/startup files remain unchanged. Upstream MIT notice is byte-identical.

The one-off boundary probe lived under ignored `temp/`; it is not a new suite or gate. Its output is retained, including the deliberate failure trace. Public evidence contains no live prompt/task records. Machine-specific checkout prefixes in command logs are replaced with `$GATE_CLONE`.

Merge decision remains keep/revise/abandon after viewing. Outstanding: final peer QA, qualifying gate and PR publication/status.
```
- Definition of Done: optional renderer matches approved scope; observed focus nit resolved; attribution intact; evidence remains honest; PASS approves visual/draft review only, with qualifying gate still pending.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: PASS
Basis: Implementation 0ae105bcf62a6e29e4efb41b24003d983fa3a739 meets the bounded optional presentation spike for operator visual/draft review. Acceptance is graded against the review envelope and approved plan despite the unused Definition of Done placeholder. No blocking implementation defect or additional blocking pre-existing seam defect was found; the disclosed Darwin helper incompatibility remains. One nonblocking keyboard nit follows. This approval does not establish merge readiness, adoption, or a passing pending gate.
swept file: yes

Swept all eight add-on files, complete SUMMARY, plan/recon, relay receipts, retained evidence and the 33-path change set from 85556455a3e734708235ef23869818a0dc743ba5 to seeded head 89f5fe696549bff3f0de0dbd21b5590f4f17e103. Read complete shared server/aggregate/contract/connectors and both browser selectors; inspected local Paperclip component references/license. No implementation edits, Git commands, suites, executable fixture harnesses or server launches were performed. Scratch queries stayed under .relay-scratch/tmp.

- [Pass] **Scope and immutable implementation.** The isolated launcher reuses the existing read seam (addons/paperclip-dashboard/preview.py:16–29, :38–42, :64–68). Read-only stored-object comparison, without invoking Git: command `PYTHONDONTWRITEBYTECODE=1 python3 .relay-scratch/tmp/read_objects.py`, exit 0; decisive output: `changed paths 33`, `core/dependency/startup changes []`, `PASS all add-on bytes equal implementation revision`. Changes comprise add-on, GH-981 docs/evidence/relay, two parked observations and releases.db/sql intake. A subsequent baseline/working-byte Python query exited 0: `PASS 18 shared/helper/package files match baseline and reviewed working bytes`; decoded object SHA1s were recomputed. No React runtime, task writer, startup, connector or schema change appears.
- [Pass] **Read boundary and honest display.** Demo does not attach/configure an aggregator; snapshot GET is forbidden until --live (addons/paperclip-dashboard/preview.py:38–42, :66–68). Finite assets, literal loopback bind and shared security/JSON helpers are retained (preview.py:21–29, :34–46, :51, :64; src/flightdeck/server.py:27–35, :44–51). Renderer uses textContent, shared issue cards/freshness, conservative PR labels and unmeasured progress (addons/paperclip-dashboard/app.js:20, :37–40, :62–64, :74, :91–98). Read timeout, failure pause, polling and independent expiry rendering are at :100–116. Pure-module query command `node --input-type=module`, importing demoSnapshot, issueCards, snapshotFresh and sourceStatus, exited 0: default `repos:3, work:5, active:4, source:ok`; stale `fresh:false, work:5, active:0, source:stale`; empty `repos:0, work:0`; partial `source:partial`. This query called no live reader.
- [Pass] **Attribution and inspectable visuals.** Pinned borrowing and MIT terms are explicit (addons/paperclip-dashboard/ATTRIBUTION.md:3–17; LICENSE.paperclip:1–21). Python read-only license comparison against local paperclip-fork/LICENSE exited 0: `PASS upstream MIT notice byte-identical`. Inspected all retained screenshots under TESTS-RESULTS/2026-10-06+GH-981/: desktop.png, dark.png, collapsed.png, compact.png, stale.png, failure.png and hostile.png show the corresponding layouts, synthetic labels, handoff text, expired/failed states and literal hostile title. compact.png is a 430 CSS-pixel container, not device emulation. filter.ax.txt records the no-match view with the search field still focused. Inspected dashboard screenshots contain synthetic records.
- [Pass] **Nonempty evidence and honest RED status.** Python read-only query of provenance.jsonl and artifact bytes exited 0: `PASS 14 nonempty evidence artifacts match recorded byte counts and SHA256`. manual-boundary.txt retains demo denial, finite assets, Host rejection, live fixture immutability and bounded 503. Its negative control states `EXPECTED RED source immutability assertion rejected a deliberately modified disposable fixture: source bytes changed`, then records the restored passing assertion. flightdeck-manual.txt reports existing checks passed. These are retained producer receipts, not suite runs repeated here. flightdeck-pytest.txt:942–947 reports five failed tests and `5 failed, 34 passed in 2.66s`; traces name missing os.waitid. The helper and consumers remain baseline-identical. SUMMARY preserves the RED result and excludes merge readiness.
- [Nit] **Disambiguate Lanes focus targets.** Lane cards and corresponding list rows both receive item.key (addons/paperclip-dashboard/app.js:66, :71), while restoration chooses the first matching control (:84). Concrete synthetic key `demo:forge:lanes:demo:codex` occurs in both controls. Pure data/key query command `node --input-type=module`, exit 0, returned `matches:[{kind:lane-card,key:demo:forge:lanes:demo:codex},{kind:work-row,key:demo:forge:lanes:demo:codex}], firstMatch:lane-card`. Source therefore resolves a focused Lanes list row to its overview card on render; the retained Work-row repair cannot cover this case. Give card/row focus keys distinct prefixes while keeping selection identity shared, then manually check Return and timer rendering on a Lanes row. This small navigation defect does not block visual review. Browser reproduction was not repeated here.
- [Unverified — needs clone run] **Qualification remains outstanding.** classifier.txt reports `tier=3` with `tier_reason=unmapped path: addons/paperclip-dashboard/preview.py`; approved plan step 9 requires the full qualifying gate in a separate disposable full clone. No such gate is attested here. Optional HTTP query command `curl --max-time 3 -sS -o "$PWD/.relay-scratch/tmp/preview.html" -w "%{http_code}\\n" http://127.0.0.1:8769/` exited 7: `Failed to connect ... Couldn't connect to server`, status `000`. No preview was running. Browser/HTTP acceptance rests on inspected retained receipts and source, not a fresh reviewer server session. Retain the nit and these limits in the draft; record the exact final SHA gate outcome before claiming merge readiness. No merge or promotion is approved.

Relay closed (Approved), no further review turn needed. Handing the completed token to codex-author for the planned disposable-clone qualification and operator visual/draft review; keep/revise/abandon and merge remain the operator decision.


### Attestation · relay-drive — 2026-10-06T16:35:27Z
task: RELAY-gh981-final
reviewer: codex
status: Approved
reviewed-head: 89f5fe696549bff3f0de0dbd21b5590f4f17e103
added-range: 9737+6451
added-sha256: f371a51c6313f607953e9772c148dad33c8b8ca1218e043e33775e42f9c1ef03
### Producer · Round 2

Implemented the sole Round 1 nit in `1bffd9e0`: `card:${lane.key}` versus `row:${item.key}` focus targets, while selection identity stays shared. Only two expressions in app.js changed. Reread that whole file and verify these distinct targets; the Round 1 full artifact sweep and source boundary remain applicable. No source reader, core UI, dependencies or launch behavior changed.

Manual native Safari Option-Tab/Return now retained focus on the Lanes list row (lanes-focus.txt). The subsequent timed browser observation was interrupted when the operator switched windows, so browser-checks.json/SUMMARY explicitly leave that timer check unverified. Do not invent a PASS. The interval calls the same render function reviewed here.

The separate baseline full clone reproduced exactly the same five work-status failures / 15 passes at original base `85556455`; output and updated nonempty provenance are committed. The required full qualifying gate remains pending until this final artifact QA closes.

The optional reviewer curl failed inside its sandbox. A root-session curl against the same server returned HTTP 200 while the preview remained active. Therefore the earlier phrase “No preview was running” does not establish a server failure; fresh reviewer HTTP remains unverified. No network exposure or source changes were added.

Handing off to codex — review the corrected artifact and evidence delta, append Round 2 verdict. No merge is requested.

### Reviewer · Round 2 · codex

VERDICT: PASS
Basis: The corrected optional renderer meets the Definition of Done for operator visual/draft review. The Round 1 focus-key nit is resolved at its origin. No new blocking implementation defect or additional blocking pre-existing seam defect was found; the disclosed Darwin helper incompatibility remains. This approval does not attest merge readiness, adoption, a passing qualifying gate or the interrupted browser timer check.
swept file: yes

Reread all eight add-on files, the complete embedded and retained SUMMARY, approved plan/recon and relay receipts, shared server/aggregate/contract/connectors and both browser selectors. Inspected all seven retained screenshots and updated evidence. Read-only stored-object inspection covered the full 35-path change set from 85556455a3e734708235ef23869818a0dc743ba5 to seeded head 6b0d583a7f260b04008ef6062124e07affe3c059, including the focus correction recorded as 1bffd9e0. No Git commands, implementation edits, suites, executable fixtures or server launches were performed. Probes remained in .relay-scratch/tmp.

- [Pass] **Focus collision repaired without changing selection identity.** Card and row focus keys now have separate prefixes (addons/paperclip-dashboard/app.js:66, :71); select still uses item.key (:42), and restoration compares the full focus key (:84). Pure source-expression/data probe command `node --input-type=module`, exit 0, returned `PASS 3 synthetic lanes restore row key to work-row, not overview card`; concrete input `demo:forge:lanes:demo:codex` produced `card:demo:forge:lanes:demo:codex` and `row:demo:forge:lanes:demo:codex`. Removing both prefixes in memory made the same restoration assertion fail: `EXPECTED RED unprefixed control: lane-card !== work-row`. No browser timer execution is inferred from this probe. Retained Safari output says `The focused UI element is 57 toggle button ... Value: on` (TESTS-RESULTS/2026-10-06+GH-981/lanes-focus.txt:4).
- [Pass] **Bounded scope and attribution preserved.** Command `PYTHONDONTWRITEBYTECODE=1 python3 "$TMPDIR/object_probe.py"`, exit 0, decoded stored objects and recomputed their SHA1s: `changed paths 35`, `PASS core/dependency/startup changes []`, `PASS 8 working add-on files match seeded objects; implementation delta exactly two focus expressions`, and `PASS upstream MIT notice byte-identical`. A corrected read-only baseline/working-byte query (`PYTHONDONTWRITEBYTECODE=1 python3 -`, exit 0) returned `PASS 19 current shared/helper/package files byte-identical to baseline objects`. Optional demo/live attachment and finite assets remain at addons/paperclip-dashboard/preview.py:21–29, :38–42, :64–68; pinned attribution and notice remain at ATTRIBUTION.md:3–17 and LICENSE.paperclip:1–21. No new reader, task writer, startup, dependency, schema or connector change appears.
- [Pass] **Whole renderer and retained visual evidence remain suitable for the spike.** Text insertion uses textContent (app.js:20); shared freshness/status selection is retained (:37–40, :62, :82), PRs require current-head verification (:74, :91), and progress is unmeasured (:67, :92). Inspected desktop.png, compact.png, dark.png, collapsed.png, stale.png, failure.png and hostile.png under TESTS-RESULTS/2026-10-06+GH-981/. They display synthetic records and corresponding layout/appearance/error states; hostile.png displays the literal img/onerror text. compact.png remains a compact container, as explicitly described in SUMMARY.md:5. This is inspection of retained screenshots, not a new live browser session.
- [Pass] **Updated evidence is nonempty and the RED suite remains honest.** The stored-object/evidence query above exited 0: `PASS 18 nonempty evidence artifacts match latest provenance byte counts and SHA256`; `PASS candidate and baseline receipts list identical five failed tests (both RED)`. Candidate output ends `5 failed, 34 passed in 2.66s` (flightdeck-pytest.txt:947); baseline work-status output ends `5 failed, 15 passed in 1.65s` (base-flightdeck-pytest.txt:946). These are inspected producer receipts, not repeated suite runs. The unchanged helper calls os.waitid at utils/py/releases_cycle.py:85, :104. SUMMARY.md:9 preserves the incompatibility and does not call either run green. manual-boundary.txt retains `EXPECTED RED source immutability assertion rejected a deliberately modified disposable fixture: source bytes changed` followed by the restored passing assertion.
- [Unverified — browser timer and fresh reviewer HTTP] **Keep the stated limits.** Both click and the 30-second interval call render (app.js:42, :115), but source inspection does not establish native browser focus after a timer fires. lanes-focus.txt:5 and browser-checks.json:16 explicitly disclose the interrupted timer observation. No fresh reviewer browser/HTTP session was performed. Correction to Round 1: curl exit 7/status 000 established only that the sandboxed request failed; the phrase “No preview was running” was unsupported and must not be treated as a server defect. Retain these limits; they do not block the authorized visual review.
- [Unverified — needs clone run] **Qualification and merge readiness remain outstanding.** classifier.txt reports `tier=3` and `tier_reason=unmapped path: addons/paperclip-dashboard/preview.py`; approved plan step 9 requires the full qualifying gate in a separate disposable full clone. SUMMARY.md:15 still lists the gate and publication/status as outstanding. Record its actual result against the final committed revision before any merge-readiness claim; this PASS approves visual/draft review only. Keep/revise/abandon and merge remain the operator decision.

Relay closed (Approved), no further review turn needed. Handing completion to codex-author for the planned disposable-clone qualification and operator visual/draft review. The approval-specific token handoff is `done`; the harness owns the file-scoped commit.


### Attestation · relay-drive — 2026-10-06T16:43:27Z
task: RELAY-gh981-final-r2
reviewer: codex
status: Approved
reviewed-head: 6b0d583a7f260b04008ef6062124e07affe3c059
added-range: 18078+5965
added-sha256: 823d432cf12df8daa4da1835cdfb3667e5be7e60ca2d2ae24217482ffa9961a6
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
