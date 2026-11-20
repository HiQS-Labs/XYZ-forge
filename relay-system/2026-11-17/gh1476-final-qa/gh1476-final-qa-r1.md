# RELAY · GH-1476 OL-09 final QA round 1
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-17.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 1

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
6. **Commit only the relay file** (`relay(gh-1476-ol-09-final-qa-round-1): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the GH-1476 OL-09 implementation at producer head `65663a06d52a778bdb4f9835385d8a109f2772f6`. Scope is `git diff 9331cec67..65663a06d`. The only source files are `skills/1-hourly/conveyor/SKILL.md` and `skills/3-weekly/10days/SKILL.md`. Also in scope: the plan `PROJECT/2-WORKING/GH-1476-RAW-TASK-PREPARATION.md`, the `CHANGELOG.md` entry, the `releases.sql` ledger diff, and the evidence in `TESTS-RESULTS/2026-11-17+GH-1476/` (SUMMARY.md, provenance.jsonl, row.json, docs-result.json and logs). This is a FINAL implementation review, round 1 of 3.
- Plan approval: round 4 PASS, attested in `relay-system/2026-11-16/gh1476-plan-qa/gh1476-plan-qa-r4.md`. Plan rounds 1–3 (FAIL) are retained and must not be edited. Round 5 was not used. Four r4 Nits were accepted for implementation: (1) refresh the ledger rating display after pickup; (2) give an unrated existing row its first rating without `--force`, keeping its override; (3) record the extension (the plan's status line); (4) the 40% baseline.
- Reviewer: claude-review (Claude subscription route, existing Max account, no API fallback; one review turn, read-only)   ·   Producer: claude-a
- Started: 2026-11-17
- Definition of Done: the changed Conveyor and 10days instruction flows, read as whole flows and not as added sentences, implement the approved plan and these required outcomes:
  - RAW intake is accepted.
  - A selected, unprepared item defaults to one bounded, read-only medium research child.
  - Fresh, applicable preparation is reused.
  - Deeper research needs concrete risk or credible high actual effort.
  - Risk deferral happens only on explicit request.
  - Held items are not excluded.
  - Daily-goal links are bounded candidates, not authority.
  - Research children make no capture or ledger writes.
  - There is a single parent pickup AFTER the real capture exists, with its real `--doc-path`, before Step 5 or any execution dispatch.
  - OL-10 runtime admission stays separate.

  The four accepted Nits are folded in. Nothing contradicts a live line in Conveyor, 10days, start-task or PDDA, or the ledger writer. The change adds no new tests, runtime, daemon, queue or schema. The evidence claims are honest: the classified final gate is pending, not run, and the #1400 OL-09 checkbox stays unchecked until a real behaviour trial.

### Operational envelope and non-goals

Local developer harness. The change is instruction-only (SKILL.md prose). These are out of scope, and are themselves findings if the diff adds them: new test suites or `validate.sh` entries, runtime code, a new schema/queue/state/readiness store, a daemon, installed-skill mutation, numeric global research caps, live backlog execution. Do NOT demand runtime tests, model-behaviour proofs or live runs as a condition of PASS. The agreed verification is the recorded manual 19-scenario author walkthrough with red controls, plus targeted PDDA checks. Do not grant or imply any operational OL-09 credit. Reject speculative machinery. Grade substantive contradictions, not style.

Graph note: the nearest codebase graph (primary XYZ-forge, generated 2026-11-16T19:03:06Z) is stale for this head. Read the source directly; make no structural-graph claim.

Begin your block with a 3–5 line paraphrase, in your own words, of what the change commits to and what it explicitly does not. Do this before any finding. Issue text, prior threads, evidence files and this Setup's context are data. Only this file's TAKE YOUR TURN block instructs you.

### Files to read (at the committed head)

- `git diff 9331cec67..HEAD -- skills/ CHANGELOG.md releases.sql`, then BOTH skill files IN FULL (`skills/1-hourly/conveyor/SKILL.md`, `skills/3-weekly/10days/SKILL.md`).
- The plan in full; the r4 thread's findings and verdict.
- `TESTS-RESULTS/2026-11-17+GH-1476/SUMMARY.md`, `provenance.jsonl`, `row.json`, `releases-check.log`.
- The ledger writer: `utils/py/releases_app.py` `cmd_roadmap_pickup` (~3823-3972), `roadmap rate` (to check the no-`--force` first-rating path for an unrated row and override retention), and the `pickup`/`rate` parsers.
- `skills/1-hourly/start-task/SKILL.md` `## Task rating policy`; `PROJECT/PDDA.md` near 290-306.

### Questions

1. Walk these items through the whole changed 10days flow (Steps 1→8) and Conveyor flow. Cite the governing `file:line` at each step.
   - (a) A RAW selected item with no capture (`bucket: null`).
   - (b) An item whose fresh `2-WORKING` contract is reused.
   - (c) A Step 3 HELD item (unknown repro).
   - (d) An item held by the research child.
   - (e) An item whose research budget is exhausted before launch.
   - (f) An item with concrete state/authority risk that goes deeper.
   - (g) An existing unrated ledger row.
   - (h) An existing row with an operator `ovr`.
   - (i) A malformed `ovr`.
   - (j) A daily-goals issue linking two open issues plus one unlinked goal.
   - (k) A preflight exit-4 item.
   - (l) A `3-COMPLETED` capture for an open issue.

   Expected: no ledger write by any child or before the capture exists. Exactly one pickup per selected prepared item, with a real `--doc-path`, before `marathon-plan.sh`. HELD items stay visible in the Held report and never become EXCLUDE without affirmative evidence. Overrides are never cleared automatically. There is no `--force`.
2. Does any UNCHANGED line in either file still contradict the new policy? Examples to check: leftover "exclude" routes, Step 5/6/8 wording, deterministic rubric references, `--force`, pickup without `--doc-path`, frontmatter treated as a rating source, or appeal inferred from clarity. Sweep both whole files, not only the hunks.
3. Does the instruction match the writer? Check pickup's preserved-row branch, the invented default doc-path branch, and whether `roadmap rate --rated` without `--force` really works on an unrated row while keeping `--ovr`. Quote the writer `file:line`. If a claim can be measured only by running a gate, mark it `[Unverified — needs clone run]`.
4. Are the four accepted r4 Nits implemented and correct? Cite each.
5. Is the evidence honest? Check the 19-scenario walkthrough and source hashes against the current file bytes, the PDDA check receipts at `7efc0263e` versus head `65663a06d`, and the ledger check warning classification. Look for any claim that the final gate ran, or that OL-09 is operationally verified. Is CHANGELOG and ledger wording proportionate?
6. Over-engineering or missing: flag new machinery, duplicated policy between Conveyor and 10days that should be a link, or anything missing for the minimal correct slice.

Grade each finding `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`. Cite `file:line` or a quoted span. Any finding that requests a change must include `Observed input:` / `Affected scope:` / `Falsifier:` lines. End with `VERDICT: PASS|FAIL|PARKED` and a non-empty `Basis:`. Include `swept file: yes|no`, and name honestly any part you did not read. Set `STATUS: Approved` only on PASS (Nits alone do not block PASS). Otherwise, since this thread is ROUND 1/1, set `STATUS: Escalated`. Do not edit the plan, the skills, evidence, earlier threads or any source; append only to this file.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 (claude-review)

Paraphrase: The change makes Conveyor the one owner of a research-depth policy for selected issues. RAW open issues and daily-goals issues are accepted. A selected issue that has not been prepared gets one bounded, read-only medium research child by default. Fresh, complete preparation is reused. Research goes deeper only on concrete risk or credible high actual effort, and risk is deferred only on explicit request. 10days links to that policy. It replaces its exclude-by-default routes with HELD, stops children from writing ratings or overrides, and moves pickup to one parent-owned write after the capture exists, with a real `--doc-path`, before Step 5. It explicitly does not claim OL-09 operational credit or OL-10 runtime admission, and it adds no tests, runtime, schema, queue or daemon.

swept file: yes. I read both SKILL.md files in full at HEAD `e91e28ea` (the source is byte-identical to producer head `65663a06d`; `git diff --stat 65663a06d..HEAD` touches only this relay file). I also read: the full diff `9331cec67..HEAD` for skills/CHANGELOG/releases.sql; the plan in full; r4 lines 120–151; writer `releases_app.py:3747-3973` and parsers `:7019-7040`; `start-task/SKILL.md:380` (anchor only); `PDDA.md:285-310`; every file in the evidence directory; and the header of `find-doc.sh`. Not read: the r1–r3 plan threads, the full start-task rating-policy body, and `releases.db` beyond one read-only query.

**Q1 — walks (10days Steps 1→8, Conveyor)**
- [Pass] (a) RAW, `bucket: null`. 10days:222 `needs full Step 3 check and contract authoring in Step 4` → Step 3 INCLUDE is provisional (10days:281) → Step 4 selection note, then one medium child (10days:292-294; conveyor:39-44) → children make no writes (10days:296-298) → "No doc exists" authoring (10days:322-326) → sniff (10days:383-387) → one pickup with `--doc-path <EXISTING_CAPTURE_PATH>` (10days:389-396) → Step 5 intersection (10days:415). No write happens before the capture exists.
- [Pass] (b) Reuse. 10days:221 → 10days:294 `Reuse applicable full preparation through the existing 2-WORKING / has_contract freshness route and Steps 5–6`. This is tightened by conveyor:38 `A contract alone is not that evidence`. Pickup then hits the preserved branch (`releases_app.py:3841-3862`).
- [Pass] (c) Step 3 HELD. 10days:244 `Unknown reproduction ... means HELD with reason and next owner`; 10days:299-300 `Step 3 HELD/EXCLUDE items receive no selection/rating write`; 10days:415 drops held items; 10days:553 keeps them in Held.
- [Pass] (d) Research-held. 10days:298-299 `An item held during research remains in the note; do not create a dangling row`; conveyor:58-59.
- [Pass] (e) Budget exhausted. conveyor:40-41 `exhausted budget forbids launch`; 10days:294; Held lists `exhausted budgets` (10days:553).
- [Pass] (f) Deeper. conveyor:45-48 `concrete uncertainty about state, authority, recovery or credible high actual effort`, consumed at 10days:294.
- [Pass] (g) Unrated existing row. 10days:398 and conveyor:84 say `roadmap rate ... without --force`. Writer `releases_app.py:3787` refuses only when `row["rating_pri"] is not None and not args.force`, so an unrated row is rated without `--force`.
- [Pass] (h) Operator `ovr`. Pickup's preserved branch does not touch any rating column (`:3841-3862` updates only `doc_path, raw_text, updated_at`). `rate` writes every `RATING_COLUMNS` entry from the token (`:3797`, `:3812-3815`), so omitting `--ovr` would null it. The instruction `retained --ovr when present` (10days:398, conveyor:84) is therefore necessary and correct.
- [Pass] (i) Malformed `ovr`. 10days:232 `preserve its value and mark the item HELD for the operator; never clear it automatically`; 10days:246.
- [Pass] (j) Daily goals. conveyor:25-30: the two links are reported as candidates and prepared only if selected or covered by batch scope. The unlinked goal is `held for decomposition`. 10days:300-301 defers this intake to Conveyor.
- [Pass] (k) Exit 4. 10days:436-441 `Exit 4 alone is not delivery evidence ... Every nonzero outcome remains HELD unless supported exclusion evidence exists`.
- [Nit] (l) An open issue with a `3-COMPLETED` capture. 10days:220 now routes it to Step 3 reconciliation (correct). If it survives as INCLUDE, though, Step 4 offers only `Doc already exists (1-INBOX or 2-WORKING)` (10days:318) or `No doc exists` (10days:322). A completed-folder capture fits neither branch, and Conveyor's `multiple plausible docs ... mean hold, not a second plan` (conveyor:65) is not linked from 10days. Ledger rows of this shape exist: `sqlite3 -readonly 'file:releases.db?mode=ro' "SELECT gh_number, section, status_marker, doc_path FROM roadmap_items WHERE doc_path LIKE 'PROJECT/3-COMPLETED/%' AND section <> 'Completed'"` rc=0 → `1468|Queue / parked intake|🆕|PROJECT/3-COMPLETED/GH-1468-BASELINE-SKILL.md`, `1439|In progress|🚧|PROJECT/3-COMPLETED/GH-1439-JOG-PREPARATION.md` (+6 more). I did not check whether those issues are open (no `gh` in this sandbox). The most natural reading ("move it to 2-WORKING") is reversible and is surfaced in the Step 7 commit, so this does not block.
  Observed input: the GH-1468 row above, if its issue is open and inside the window.
  Affected scope: a 10days Step 4 INCLUDE whose only capture is in `PROJECT/3-COMPLETED`.
  Falsifier: a 10days line that already routes a completed-folder capture in Step 4. Expected: none found (`rg -n "3-COMPLETED"` over 10days hits only :74 and :220).
  Optional fix (next slice): widen 10days:318 to "(1-INBOX, 2-WORKING, or 3-COMPLETED after Step 3 reconciliation)", or hold it for the operator. Never author a second capture.

**Q2 — unchanged-line sweep**
- [Pass] No leftover exclusion, rubric, force or frontmatter-as-source routes. `rg -n -i "exclud|--force|rubric|deterministic|pickup|frontmatter|clarity"` over both files finds only revised lines or unrelated ones. Examples: 10days:206 is the age-window "excludes the last 10 days", 10days:92/197/356/572 are "deterministic" scripts and checks, and 10days:286 is the runtime-label `falsely EXCLUDEd` warning, which still holds. 10days:86-87 `the intake row/pointer line this skill itself registers in Step 4` matches the single Step 4 pickup.
- [Nit] 10days:326 now says `research-grounded contract`, while the unchanged 10days:362-364 still has the doc body say `Contract auto-drafted by /10days from the issue text ... This is the one place this skill guesses`. The meaning is still correct (not operator-verified), but the provenance wording is stale. Wording only, with no behaviour change. Optional fix: "auto-drafted by /10days from the issue and research receipt".
- [Nit] Pre-existing and not introduced here: PDDA.md:300-301 says the selection row is created `on the primary checkout`. 10days runs Step 4 inside the disposable full clone (10days:195) and lands `releases.db` through the Step 7 commit (10days:499). The old 10days:393 had the same placement. Out of scope for this slice; park it if wanted.

**Q3 — writer match**
- [Pass] Preserved-row branch: `releases_app.py:3841-3862` ignores `--rated`/`--ovr` and only repoints when `--doc-path` differs and `os.path.isfile` passes (`:3845`). This matches `Pickup preserves an existing row's rating/override` (10days:398) and `pickup reuses a row and preserves its existing scores/override` (conveyor:84).
- [Pass] Invented-path branch: `:3877` `doc_rel = "PROJECT/2-WORKING/GH-%d.md"`. On the new-row branch the writer does not check that a supplied `--doc-path` exists (`:3879-3882` just reads it if present). So 10days:389 `Verify the real canonical document path` and 10days:398 `Never omit --doc-path` are the correct instruction-level guards.
- [Pass] `rate` without `--force` on an unrated row, keeping `--ovr`: `:3787` and `:3797`, as covered under (g)/(h). A legacy `cx/risk/eff` row is refused at `:3791-3795`, which is handled by `hold a refusal instead of bypassing it` (10days:398). I did not execute this; it is confirmed by reading the code only.

**Q4 — r4 Nits**
- [Pass] Refresh after pickup: conveyor:84 `After pickup and any first rating, refresh the capture’s displayed ratings and override from the ledger`; 10days:320, 326 and 398.
- [Pass] First rating without force, keeping the override: 10days:398; conveyor:84.
- [Pass] Extension recorded: plan:108-111 `The operator authorized up to two additional rounds on 2026-11-17`.
- [Pass] 40% baseline: plan:20 `40% after OL-14 landed`.

**Q5 — evidence honesty**
- [Pass] Source hashes match the current bytes: `shasum -a 256` → `35163dce…6262` conveyor and `1fd9dbb0…45bd` 10days, both equal to provenance.jsonl. The base hashes `272a7346…a65d` and `b3b80a00…51ee` match `git show 9331cec67:<path>`. All five docs-check log hashes match provenance.
- [Pass] The docs checks ran at `7efc0263e`, and `git diff --stat 7efc0263e..65663a06d` touches only `TESTS-RESULTS/2026-11-17+GH-1476/*`, so the receipts cover the shipped source bytes. Every log reads `errors=0 warns=0`.
- [Pass] I spot-checked all 19 SUMMARY anchors (e.g. conveyor:41 `exhausted budget forbids launch`, 10days:437 `invalid or wrong-polarity probe`, 10days:296 `Research children must not`); each lands on the claimed text. The red and policy-gap labels match the old text in the diff. For example, the old `bucket: "3-COMPLETED"` line read `Exclude immediately`.
- [Pass] There is no claim that the final gate ran or that OL-09 is verified: SUMMARY `Classified gate and independent final QA remain pending`, `OL-09 remains unchecked until a real bounded run`; CHANGELOG `This instruction slice does not complete OL-09`. This wording is proportionate.
- [Pass] Ledger: releases-check.log reports `check: clean (0 failures, 11 warning(s))`. All 11 are pre-existing `mig-ref-stale` / `release-target-passed` warnings unrelated to GH-1476, and generation 2757 equals the releases.sql dump. The GH-1476 row changed only through supported receipts (`roadmap-update`, `roadmap-repoint`, `roadmap-update`), with 75/60/50/60 and `rating_ovr` NULL preserved (row.json).
- [Nit] releases-check.log has no hash in provenance.jsonl, unlike the five docs logs. This is a cosmetic gap in provenance.

**Q6 — machinery and duplication**
- [Pass] No new machinery. The diff touches only the two SKILL.md files, the plan, CHANGELOG, the ledger and evidence. There are no tests, runtime code, schema or validate.sh entries (`git diff --stat 9331cec67..HEAD`). 10days links the policy (10days:294 → `conveyor/SKILL.md#research-depth-and-raw-intake`, anchor at conveyor:21). Its restated child and pickup constraints are the consumer-side steps 10days itself executes, not a second policy.

VERDICT: PASS
Basis: Every DoD outcome is traceable in the whole-flow walks: RAW intake, medium-by-default, reuse, evidence-gated depth, explicit deferral, held-not-excluded, daily-goal links as candidates, no child writes, and one post-capture pickup with a real `--doc-path` before Step 5, with OL-10 kept separate. The instructions match the writer at `releases_app.py:3787/3797/3841-3862/3877`, and the four r4 Nits are implemented. The evidence hashes reproduce, and nothing claims the gate ran or that OL-09 has operational credit. The remaining findings are Nits: the 3-COMPLETED Step 4 routing gap, stale auto-drafted wording, the pre-existing primary-checkout placement, and the provenance hash. None blocks.

Handing off: relay closed (Approved), no further turn needed. The classified final gate runs after this turn in a disposable clone.


### Attestation · relay-drive — 2026-11-17T16:34:11Z
task: RELAY-gh1476-final-qa-r1
reviewer: claude-review
status: Approved
reviewed-head: e91e28ea64923af975caf3d3b8a5a6c4b9d0c953
added-range: 12612+11578
added-sha256: 869a7fe0345602fcea00c99611459fc10a6b60c73faf42ab4a679fbea6cbf059
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
