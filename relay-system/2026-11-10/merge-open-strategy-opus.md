# RELAY · XYZ non-draft landing strategy with explicit holds
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-09.
-->

NEXT: Producer
STATUS: Approved
ROUND: 3 / 3

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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(xyz-non-draft-landing-strategy-with-explicit-holds): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/packet.md** — the read-only path that
  `relay-drive.sh --artifact-file temp/batch-qa/packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: claude-opus   ·   Producer: codex-parent
- Started: 2026-11-09
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 (claude-opus)

swept file: yes — read strategy text `packet.md:1-19` in full; parsed all six PR entries of `packet.md:21-1120` via `python3 -I` (files, heads, mergeable, checks, reviews, comment authors) and read the 1326/1402 owner comments and the 1403/1404 bodies; then probed the candidate tree (no git, no tests).

Probes (cwd = worktree, read-only):
- `ls PROJECT/1-INBOX | grep 1206` → empty; `ls PROJECT/2-WORKING | grep 1206` → `GH-1206-PACKAGING-DRIFT.md`.
- `grep -n '^STATUS\|^NEXT' marathon-system/gh-1206-packaging-drift/RELAY.md` → `2:STATUS: Open`, `3:NEXT: agy (Reviewer)`, `113:NEXT: agy (Reviewer)`. The only Log block is `105:### Round 1 · Builder · codex`.
- `grep -n 1206 releases.sql` → `921: roadmap_items ... doc_path 'PROJECT/1-INBOX/GH-1206-PACKAGING-DRIFT.md'`, `1015: jog_queue ... '1206' ... 'parked' ... attempt_count 2 ... 'cold-start: dispatched Marathon execution has no valid result receipt — inspect manually before any refire'`.
- `TESTS-RESULTS/2026-11-10+GH-1386/1206-qualification-result.json` → `"rc": 0, "head": "a6024d0c…", "seconds": 569.22`.
- `grep -c xyz-3-agents-swarm package.json package-lock.json` → `0`/`0`; `package.json:2 "name": "xyz-forge"`.

**Q1 — holds and grouping**
- [Pass] 1326 is superseded: `AGENTS.md:75-78` already says "locally via `python3 utils/py/wave_reconcile.py --pr <N>`… `--force-local-reconcile`… The hosted `wave-reconcile.yml` is dispatch-only and runs before promotion". The PR is `"mergeable": "CONFLICTING"` and owner comment 6729487654 excludes it. A hold with no closure is correct.
- [Pass] 1403/1404 holds: both modify `releases.db`, `releases.sql` and `CHANGELOG.md`, and both are CONFLICTING (metadata). The 1404 body says "QA ran serially after #1403", which matches the claim that the parser infers the dependency from that phrase. With both PRs capped at 2/2 ("Repair accounting remains 2/2"), holding beats silently dropping the edge.
- [Unverified — needs `refs/qa/pr1327-held` read] 1327 source-QA FAIL. I did not read the ref (no git this turn). The hold is the safe default whatever the ref says, so this does not block.
- [Pass] 1402 and 1405 are implementation-disjoint. Their file lists share only the GH-1206 doc (1402: `PROJECT/1-INBOX/GH-1206-…` MODIFIED; 1405: `PROJECT/2-WORKING/GH-1206-…` RENAMED). Neither touches `releases.db`/`releases.sql`, so neither collides with the held 1403/1404. Order 1402→1405 is sound because 1402 carries the qualification receipt for 1405's head (`1206-qualification-result.json "head": "a6024d0c…"`).

**Q2 — combined GH-1206 doc and packet after 1402+1405.** The strategy defers this ("needs semantic review", `packet.md:10`) and does not perform the review. The candidate tree shows three problems, none of them stale *success*:
- [Should] Landing 1405 puts a live-looking open relay on development. `marathon-system/gh-1206-packaging-drift/RELAY.md:2-3` reads `STATUS: Open` / `NEXT: agy (Reviewer)`, but `interventions.md:5` records that its execution tree "received SIGTERM" after the builder, and that the reviewer had "started before pause". The only thing stopping a refire is the free-text `failure_reason` on the parked `jog_queue` row (`releases.sql:1015`). That is the "duplicate active packet" Q2 asks about.
  Observed input: `RELAY.md:2-3` in candidate `ae002792`.
  Affected scope: the 1206 marathon packet only.
  Falsifier: if `marathon_drive.py`/`jog_run.py` provably never resume a `marathon-system/*/RELAY.md` whose jog row is `parked` (cite the guard `file:line`), this is a Nit.
  Fix (existing machinery, no new mechanism): record in the batch issue that this RELAY is an interrupted, non-resumable trial record. Close it (`STATUS: Closed — interrupted, superseded by PR #1405 landing`) in the post-landing docs reconcile, not by changing the 1405 pin.
- [Should] The working doc's status contradicts the landed tree. `PROJECT/2-WORKING/GH-1206-PACKAGING-DRIFT.md:21-23` says "Execute implementation and verify probes", all eight acceptance boxes `:45-52` are `[ ]`, and fix_probes `:83-88` assert `path_absent` for `TESTS-RESULTS/2026-11-10+GH-1206/manual.md`/`provenance.jsonl`, both of which exist after 1405. The truthful outcome is spread over three PR artifacts: source QA PASS at `7276186d` (`gh1206-independent-final.codex.md:1`), "kernel unit tests … pending" (`manual.md:16`), and full gate rc 0 at `a6024d0c` (1402's receipt). The doc never states it.
  Observed input: the lines above.
  Affected scope: the GH-1206 doc only.
  Falsifier: none needed, because this is a docs truth fix.
  Fix: the batch record states the 1206 outcome with those three citations. A post-landing docs PR updates the Status row and ticks only the boxes the evidence proves. Keep the issue open per GH-202 (`:61`).
- [Should] The roadmap pointer dangles after the rename. `releases.sql:921` `doc_path 'PROJECT/1-INBOX/GH-1206-PACKAGING-DRIFT.md'` no longer exists in the candidate.
  Observed input: `releases.sql:921` plus the empty `ls PROJECT/1-INBOX | grep 1206`.
  Affected scope: the 1206 roadmap row.
  Falsifier: local `wave_reconcile.py --pr 1405` repoints `doc_path` on its own (cite it).
  Fix: add a post-merge 1405 step that repoints with the existing roadmap verb *without* `--raw-text`, because the row is rated 50/30/65/90 and LESSONS-LEARNED warns that `--raw-text` clears the rating.

**Q3 — checkpoints**
- [Pass] The sweep handling is truthful. `.merge-cleanup.json` has `"full_suite": "promotion"` and `"sweep_command": "gh workflow run wave-reconcile.yml --ref development"`. The strategy does not dispatch it and records DEFERRED (`packet.md:12`). It adds no redundant broad rerun, because the existing full-gate receipts (1206 rc 0 at `a6024d0c`; 1402 "runtime full qualification GREEN557s on bd7ce73d4", owner comment) are reused.
- [Nit] "Live required checks" is undefined. On every PR, `promotion boundary (macOS)` and `portability canary` are `SKIPPED` and CodeRabbit is `NEUTRAL` on 1402/1405. Name the required check (vendored smoke gate = SUCCESS) and state that SKIPPED/NEUTRAL do not stop the driver, so a stop-on-unreadable gate does not fire spuriously.

**Q4 — ownership, pins, caps, recovery**
- [Pass] Ownership and pins: "NEVER execute before owner releases shared primary… Re-fetch exact integration/heads on release" (`packet.md:11`). Merge (never squash) matches `.merge-cleanup.json "preserve_commit_history": true`. Stop conditions and partial-landing records (`packet.md:13`) cover resume.
- [Nit] The 1402 pin `95699ba8` is a development merge commit (`Merge branch 'development' … into t3/flywheel-two-item-trial`), while its source QA and full gate bind to `f6a40d3b`/`bd7ce73d4`, and CodeRabbit to `6ba01d87`. State that the QA→pin delta is a merge-only delta, so the re-fetch check compares the right SHAs.
- [Nit] Evidence binding across PRs: 1402 lands the qualification receipt for 1405@`a6024d0c`. If 1405's head changes on re-fetch, that landed receipt no longer covers 1405. The strategy should name this, so a moved 1405 pin requires fresh qualification and does not reuse 1402's file.

No pre-existing defects found in the strategy beyond the above.

VERDICT: FAIL
Basis: Q1, Q3 and Q4 are justified and cited. Q2, which the packet raises explicitly, is deferred rather than answered, and the candidate tree shows an open interrupted marathon relay, a working doc whose status and probes contradict the landed tree, and a dangling roadmap `doc_path`. All three fixes are disposition and post-landing docs/roadmap steps through existing verbs. None needs a code repair to 1402/1405, a pin change, or a cap or gate bypass. Once the strategy adds them (and ideally the Nits), I expect a conditional PASS. This is a strategy review only, not merge authorization.

handing off to Producer (codex-parent) — go to the codex-parent window and say 'take your turn'.


### Producer · Round 1 — adjudication

- Open interrupted relay Should: Modified to historical-record note, not forced closure. `jog_run.py:717-722` explicitly says resume reprojects receipts and never dispatches Marathon; next-work selectors at2226/2300 select pending, not parked. Thus the requested falsifier is established: the original parked trial cannot auto-refire just because its preserved RELAY says Open. Preserve its authentic interrupted header/log; batch record and live canonical task doc will explicitly label it historical/non-active, superseded by separately qualified PR1405. No new gate or destructive history rewrite.
- Status/checkbox Should: Accepted as post-landing documentation truth. After supported reconciliation, locate the canonical GH1206 doc, update its status and only the acceptance boxes substantiated by source/manual/full-gate receipts, and distinguish the original interrupted engine from rescued independent artifact qualification. Link 1405 source QA, manual baseline/final, and 1402 exact-a6024d0c qualification receipt. `manual.md` pending statement remains original timestamped history; append final harness result context instead of editing historical observations. Completed fix_probes intentionally yield STALE/already-landed; do NOT weaken or rewrite them. Record missing evidence as pending, never tick by inference.
- GH202 interpretation: Declined keep-open instruction. GH1206 doc:61 says promotion requires the issue to be closed, not that it must remain open. Follow actual native issue state after the Closes#1206 PR; no manual close/reopen/force-promote.
- Dangling pointer Should: Existing owner covers it, with explicit verification. `wave_reconcile.update_roadmap_entry` at1716-1718 calls canonical `roadmap repoint --gid --doc-path` if paths differ; main calls it with actual dest_path at2610-2619. After1405, verify exactly one owned row points to the real canonical doc and rating50/30/65/90 survives. If needed, use the existing repoint verb without raw-text to repair; no SQL and no new writer. Failed reconciliation stops before advancing.
- Check Nit: Accepted. Exact-head vendored smoke SUCCESS is observed; macOS promotion/Ubuntu are expected SKIPPED and CodeRabbit NEUTRAL, not unperformed checks claimed green. Driver still reads actual required checks and refuses pending/failing/unreadable outcomes.
- Source-binding Nit: Accepted. Before landing verify PR1402 runtime diff versus qualified bd7ce73d4 is empty for its five runtime files. Source QA/qualified source versus final merge-only pin are distinct; preserve both SHAs. Any semantic delta reopens affected qualification; no reuse by filename alone.
- Moved1405 Nit: Accepted. The qualification in1402 covers exactly a6024d0c; moved1405 pin invalidates it, requiring refreshed evidence. No moved-head merges.

R2 reviews this bounded strategy disposition, not source code fixes or live1243. Shared-primary release remains a hard precondition; no merge performed.

### Reviewer · Round 2 (claude-opus)

swept file: yes — re-read the strategy `packet.md:1-19` in full, including the new ROUND2 preamble at `packet.md:1`, and every Producer R1 disposition. I checked each cited `file:line` in the candidate tree. Probes were read-only (`sed`/`grep`): no git, no tests.

**Disposition checks**
- [Pass] Open interrupted relay: the falsifier I set in R1 holds. `utils/py/jog_run.py:717-722` (`jog_resume`) says "Resume never fires Marathon on its own — a new fire is always the explicit retry-build decision." Both next-work selectors filter on pending rows only: `jog_run.py:2226` `"... FROM jog_queue WHERE status = 'pending' ..."` and `jog_run.py:2300` `WHERE status = 'pending'`. The 1206 row is `'parked'` (`releases.sql:1015`), so an Open header cannot trigger a refire on its own. Labelling the RELAY historical in the batch record and the canonical doc, and leaving its authentic header alone, is the right call. My forced-closure fix was more than the evidence supports. I accept the downgrade.
- [Pass] GH-202: the Producer is right. `PROJECT/2-WORKING/GH-1206-PACKAGING-DRIFT.md:61` reads "doc stays active by design (GH-202: promotion requires the issue to be closed)". It describes how the issue lifecycle works and does not instruct anyone to keep the issue open. Following the native issue state after `Closes #1206` is correct, and I withdraw my "keep open" wording.
- [Pass] Status/checkbox truth: the disposition ticks only boxes that receipts prove, appends to `manual.md` without rewriting it, and leaves fix_probes STALE rather than weakened. That fully answers my Should.
- [Pass] Dangling pointer: the existing owner repoints the row. `utils/py/wave_reconcile.py:1716-1718` contains `if doc_path and row["doc_path"] != doc_path: ledger_write(... ["roadmap", "repoint", "--gid", ..., "--doc-path", doc_path] ...)`, and `:2610-2619` passes `doc_path=os.path.relpath(dest_path, repo_root)`. On rating survival I checked one more thing. The same function then runs `roadmap update --raw-text new_raw_text` (`:1719-1721`), which is the call LESSONS-LEARNED.md:115-117 says nulls the rating. Here `new_raw_text` keeps the old text after "—" (`:1710-1714`), and the stored `raw_text` (`releases.sql:921`) ends in `(rated 50/30/65/90)`, so the token carries over and the rating survives. The Producer's read-back step is the right guard.
- [Nit] One wording fix to the dangling-pointer fallback: if the read-back shows the rating NULL, the repair is `roadmap rate --issue-num 1206 --rated 50/30/65/90` (LESSONS-LEARNED.md:117). `repoint` does not restore ratings. This is non-blocking, because the guard catches the failure either way.
- [Pass] Check Nit: required = exact-head vendored smoke SUCCESS; SKIPPED/NEUTRAL are named as expected; the driver still refuses pending, failing or unreadable checks. Accepted.
- [Pass] Source-binding Nit: the empty runtime diff of 1402 against the qualified `bd7ce73d4` for its five runtime files is required before landing, and both SHAs are preserved. Accepted.
- [Pass] Moved-1405 Nit: the qualification covers exactly `a6024d0c`, and a moved head invalidates it with no merge on a moved head (`packet.md:1` "invalidation on moved1405head"). Accepted.

The strategy itself has no new defects beyond the Nit above. The holds for 1326/1327/1403/1404 and the 1402→1405 order stand as graded in R1.

VERDICT: PASS
Basis: every R1 Should is resolved with a citation. One is downgraded on its falsifier (`jog_run.py:717-722`, `:2226`, `:2300`), one is accepted as a post-landing docs truth step, and one is covered by the existing `wave_reconcile` repoint (`:1716-1718`), whose rating token I confirmed survives (`releases.sql:921`). All three R1 Nits are accepted. The approval is conditional, as the strategy states: shared-primary release by its owner, re-fetch of the exact pins, and live exact-head checks before each merge. This approves the landing strategy only. It does not authorize a merge and does not replace per-PR source QA.

relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-11-10T06:34:23Z
task: RELAY-merge-open-strategy
reviewer: claude-opus
status: Approved
reviewed-head: 4f1b8df84a67acb31bf99d1bceab13a961134cbe
added-range: 16777+4082
added-sha256: 770cb198bec9f25141ff586c213607a33be2e94d62b2f54e17872fe2653c67f2
### Producer final disposition

Round2 rating-fallback Nit accepted: if canonical read-back unexpectedly loses a rating, use existing `roadmap rate --issue-num 1206 --rated 50/30/65/90` (retaining any actual operator override), not repoint, to restore it. Verify before advancement. No source/candidate change; strategy remains conditional on ownership release and exact pins. No merge performed.

### Producer — final cumulative strategy round 3
Owner released primary/source/gate/push ownership; primary clean development6b17493f. User specifically authorized PR1327 one extra repair episode and PR1406 minor fixes/ready/merge. Prior scope holds remain for1403/4 (2/2 used), draft1391/1024;1326 doublechecked and closed. No live1243 engine takeover.
Final direct order:1327 ->1402 ->1405 ->1406. Independent source approvals retained in this candidate for1327R3 and1402/1406R2 separately. Candidate038b71452 merges all four CLEANLY in this order using ordinary merge history; no staging publication, retarget or source repair required. Pins are qa/1327=2d04ff9b3,qa/1402=3b5b74c6,qa/1405=a6024d0c,qa/1406=7f60ac0a. Fresh normal publication gates for corrected1327/1402/1406 required before merge;1402 currently running; source heads may receive gate evidence-only tails, whose diff MUST be verified docs/evidence-only and whose exact final SHA must get normal documentation push+hosted smoke. Any source/head semantic delta or changed integration invalidates affected candidate review.1405 unchanged exact-source fullreceipt retained. No bypass.
Before each remote merge freeze finalhead, verify base development and bounded source scope vs inherited/evidence bulk, exact-head hosted vendored smoke SUCCESS (macOS/Ubuntu expectedSKIPPED, CodeRabbitNEUTRAL is not a green suite).1406 onlyreadyafterfreshgate. After1402 lands/reconciles, verify all five runtimefiles identical1406 versusdevelopment immediately before1406 merge.
Use existing merge_cleanup driver allowlist+pinnedheads --resume --landing-plan direct; create scriptmanagedbatchissue beforefirstmerge. Permerge FFprimary, localwave_reconcile, canonical ledger/check/docs, normalpush, clean/equalremote beforeadvancing. No cap reset. Premerge ledger disjoint merge/replay allowed onlywithin existing episodes; no speculativebranch/SQL edits. If a material blocker remains stopthatlane, doindependenteligiblelandings.
Retain all R2 accepted postlanding1206 steps: historical interruptedRELAY authentic header unchanged; canonicalstatus/acceptance truthful fromsource/manual/full receipts, appendmanualqualification withoutrewritingpast; nativeissue state controlsarchive; verifycanonicalpath and50/30/65/90 rating, existingrepoint/rate withactualovr onlyifneeded.1406 canonicaldoc keepsliveCodex+agyacceptance unchecked, original failedtrial/attempts preserved; no approvedJogbundle fabricated and existingpostmergeguard leaves parkedfailedrows unchanged.
Fullregistry sweep DEFERRED to explicitpromotion per policy; no implicitpromotion. Recorddeferredvia existingrecord-sweep ifrequired, batchcarryovers verbatimunchecked and echochat. Safecheckoutcleanuponlyafterunique-state proof; preserveunpublishedQArefs/dirtyhelpers.
This is final strategy review3/3, not a new source review. Review the material scope change and combinedcandidate interactions, reuse R2 disposition forunchangeditems. Readonlysourcequeries only; no tests/fixtures/gitmutations. ReturnPASS/FAILwithconcreteblockinginput.

### Reviewer · Round 3 (claude-opus)

swept file: yes. I read the whole relay file, including the Producer R3 block (`:167-174`) and the R3 artifact `packet.md:1` (one line, 323 bytes). I read the headers and verdicts of both source-QA relays this scope change rests on, `relay-system/2026-11-10/pr1327-source-opus.md` and `pr1406-outer-opus.md`. I probed the composed candidate tree, which is the worktree on top of `038b71452`. All probes were read-only (`python3 -I`, `shasum`, `grep`, `sed`). I ran no git, tests, fixtures or validate.

Probes:
- Five-file binding in the composed tree. I ran `python3 -I` with sha256 over the paths in `TESTS-RESULTS/2026-11-10+GH-1243/review-followup/dependency-binding.json` (`"dependency_source": "e5d29ca9"`). Exit 0. `jog_run.py`, `marathon_drive.py`, `relay_drive.py`, `releases_app.py` and `swarm_preflight.py` all print `MATCH`.
- R2 citations after composition. `sed -n 717,722p utils/py/jog_run.py` still reads "Resume never fires Marathon on its own". `grep -n "status = 'pending'"` returns `2226` and `2300`. `marathon-system/gh-1206-packaging-drift/RELAY.md:2-3` still reads `STATUS: Open` / `NEXT: agy (Reviewer)`, so the authentic interrupted header is preserved.
- Source approvals. `pr1327-source-opus.md:8` reads `STATUS: Approved`, with R3 `VERDICT: PASS` (`:156`) and attestation `reviewed-head: d13becae5a57…` (`:166`). `pr1406-outer-opus.md:8` reads `STATUS: Approved`, with R2 `VERDICT: PASS` (`:215`) and `reviewed-head: 2ac2e5f6…` (`:223`).
- 1406 binding. `grep` finds no recorded sha256 for `utils/py/consult.py` (the composed tree has `734bb2a4…`) in `TESTS-RESULTS/` or `relay-system/`.

**Material scope change**
- [Pass] **1327 is now eligible.** In R1 I held 1327 as [Unverified] pending its source-QA ref. It now has an independent R3 PASS bound to `d13becae` (`pr1327-source-opus.md:156,166`). The R2 block there records `"prior_repairs": 2, "authorized_additional_episodes": 1`, which matches the operator's one-extra-episode authorization. It is not a cap reset.
- [Pass] **1406 is added under explicit authorization, with source PASS** (`pr1406-outer-opus.md:215`). Its R1 Q4a Should was "after #1402 lands… confirm those five files have an empty diff against `development`". The strategy keeps that step (`:170` "verify all five runtimefiles identical1406 versusdevelopment immediately before1406 merge"). The composed candidate already satisfies it: 5/5 `MATCH` against the `e5d29ca9` binding. So 1327 and 1405 do not perturb the 1402/1406 shared runtime.
- [Pass] **Holds.** 1403/1404 stay held at 2/2. 1391/1024 are drafts. 1326 is closed, consistent with my R1 supersession finding (`AGENTS.md:75-78`). There is no 1243 engine takeover. The 1406 R2 basis says the Jog guard "leaves the failed 1243 row as it is" (`pr1406-outer-opus.md:216`).
- [Pass] **Order 1327→1402→1405→1406.** 1402 comes before 1406 because 1406 inherits 1402's five runtime files. 1402 comes before 1405 because it carries 1405's `a6024d0c` receipt (R1). 1327 touches the planner/start-marathon seam (`pr1327-source-opus.md:118`), which is disjoint from the five-file set: they all match after composition. The Producer reports that candidate `038b71452` composes all four cleanly. The four `Merge remote-tracking branch 'qa/…'` commits in the session's recent-commit list are consistent with that. I did not re-derive it with git.
- [Pass] **Gates and procedure.** The strategy requires a fresh normal publication gate for each corrected head, which keeps the qualified head equal to the merged head. It requires evidence-only tails to be verified docs/evidence-only and the exact final SHA to be smoked. It treats a semantic delta as invalidating review. It reuses the existing `merge_cleanup` driver with `--resume --landing-plan direct` and creates the batch issue before the first merge. Each merge is followed by FF primary, local `wave_reconcile`, ledger/docs reconcile and a clean, equal remote before the next merge. The sweep is DEFERRED to promotion. It adds no new mechanism and no bypass, and the R2 dispositions are carried forward unchanged (`:172`).

**Residual**
- [Nit] **Name the reviewed-head→pin delta explicitly.** For all three corrected PRs the pins already differ from the source-QA heads:
  - 1327: reviewed `d13becae`, pinned `2d04ff9b3`, which is the relay-drive attestation commit.
  - 1402: bound `e5d29ca9`, pinned `3b5b74c6`.
  - 1406: reviewed `2ac2e5f6`, pinned `7f60ac0a`.

  `:169` covers "evidence-only tails", but it talks about tails added in the future. Before each merge, the driver should also diff reviewed-head→final-head (not just pin→final) and confirm it is docs/evidence/relay-only.

  For 1402 the five-file `MATCH` already proves the runtime half. 1406 has no recorded `consult.py` hash, so the `git diff 2ac2e5f6 <final> -- utils/py/consult.py skills/` check is the only binding. This needs no behaviour change, and the existing "Any source/head semantic delta… invalidates" clause already authorizes the stop.

No other defects found in the strategy or in the combined-candidate interactions I probed.

VERDICT: PASS
Basis: Each R3 scope change is backed by an independent source-QA approval bound to a cited head (`pr1327-source-opus.md:156,166`; `pr1406-outer-opus.md:215,223`) and by explicit operator authorization. The composed candidate keeps the 1402/1406 five-file binding (5/5 sha256 `MATCH`) and every R2 citation (`jog_run.py:717-722,2226,2300`; 1206 RELAY header). The order, holds, gates and post-landing 1206 steps reuse existing machinery with no cap reset or bypass. This approves the landing strategy only. Each merge still requires: the exact-head fresh gate, hosted vendored smoke SUCCESS, the reviewed-head→final-head scope diff (Nit above), and a clean per-merge reconcile. This review is not a merge.

relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-11-10T07:22:25Z
task: RELAY-merge-open-strategy-r3
reviewer: claude-opus
status: Approved
reviewed-head: 2d1252a183ee8d34343b1d1517d32f21f453deee
added-range: 24607+5906
added-sha256: a926a5df4d616305b699668a94fb5c6bd6e79511229401e3cf8d1a7f3edd327b
### Producer final disposition
Accepted R3 Nit. Immediately before landing, compare each source-reviewed head to its exact final head and require only documentation/evidence/relay changes:1327 d13becae5;1402 e5d29ca9 (five runtimefiles also bound in dependency-binding.json);1406 2ac2e5f6 (explicit empty consult.py andskills source diff). Qualification is fresh normal full on source-containing publication head plus normal documentation gate on evidence tail and exact final hosted smoke. Do not claim the full gate reran against an evidence-only tail. Any source difference stops affected merge.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
