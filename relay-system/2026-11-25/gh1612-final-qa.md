# RELAY · GH-1612 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
-->

NEXT: Reviewer
STATUS: Open
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
6. **Manual relay: commit only the relay file** (`relay(gh-1612-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/2-daily/yesterday-today/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-25
- Operational envelope: an instruction-only edit of one existing skill (`skills/2-daily/yesterday-today/SKILL.md`, 30 added lines), no scripts. XYZ-forge forbids new tests (`AGENTS.md` "No new tests", GH-831): a new test file, `validate.sh` TESTS entry or gate machinery in the diff is itself a finding. Grade against the stated requirements and commensurate complexity; do not ask for scripts, templates or a new skill.
- Operator decisions already made (do not reopen): the change extends the existing `yesterday-today` skill; the seven lessons in the plan's Requirement section are the operator's list; size about 20-30 added lines and under about 140 lines; generic, fictional examples only; the plan was Approved by Codex plan QA at round 3 (`relay-system/2026-11-25/gh1612-plan-qa.md`).
- Inputs (committed): issue https://github.com/HiQS-Labs/XYZ-forge/issues/1612; plan `PROJECT/2-WORKING/GH-1612-YESTERDAY-TODAY-RUN-SHEET.md` (acceptance A1-A6, draft wording); the diff `git diff b479f74e0 HEAD`; evidence `TESTS-RESULTS/2026-11-25+GH-1612/` (`SUMMARY.md`, `provenance.jsonl`, logs, four smoke receipts, `inputs/`). Base is `b479f74e0`.
- Definition of Done: each of the seven lessons is carried by step 5a, step 7 and step 8 as the plan's approved draft says; the acceptance checks A1-A5 are substantiated by their receipts (A6 is the delivery step, completed after approval); the smoke exercised the real consumer entry point on a deploy day, a reread-cancels case and a no-deploy day; nothing implies approval; nothing private or non-generic is in the diff; the per-issue rating matches its evidence.

Questions (answer each with `file:line` or the receipt that supports it):

1. Does the final text of step 5a, the step-7 sentence and step-8 item 6 (`skills/2-daily/yesterday-today/SKILL.md:66-91,105,123-124`) carry each of the seven lessons in `PROJECT/2-WORKING/GH-1612-YESTERDAY-TODAY-RUN-SHEET.md` (Requirement section) and the issue, with nothing contradicted? Is any wording ambiguous enough that an agent following it literally could get a lesson wrong?
2. Does anything in the new text conflict with the rest of the skill (its opening "never writes to a server", step 3's "not checked" rule, step 7's guarded publish, step 8's validator)? Any cross-reference or step number that the insertion broke?
3. What prevents an unchanged, unfixed candidate from being reported as delivered, and where is the observed rejection? Check `a1-content.log` (base MISSING x19), `smoke-base-replay.md` and the red controls in `a1-content.log`, `a3-privacy-scan.log`, `a5-diff-invariant.log`. Do the receipts observe what each acceptance item says?
4. Do the four smoke receipts show what they claim? Read each proposed body, not just `SUMMARY.md`: sheet first with six columns, the owner-but-no-time gate and the no-owner gates asked as questions, no sheet after the reread cancels the deploy, no output on the no-deploy day, header intact. Is the executor's "Read-only, 4/5/4/4 Read calls" claim credible from the receipts? Are the observations (chronological row order; a proposed owner marked "to confirm") fairly stated?
5. Privacy: is there any client, product, company, people, host name or private link in the skill diff, plan, evidence or relay threads (the plan's `owner` field is project metadata, and this repo's own issue URLs are public)? Re-run your own scan; do not rely on `a3-privacy-scan.log`.
6. Size and scope: 30 added lines and 136 total against "about 20-30" and "under about 140"; changed paths limited to the skill, the plan, the ledger files, relay threads and evidence. Any new test, suite, script or registry entry? Does the persisted rating `30/10/50/90` match the plan's rationale and the ledger row?
7. Anything required by the issue that is missing, or any machinery here beyond what the problem needs?

Write graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), then a VERDICT. Set STATUS to Approved only if no `[Blocker]` or `[Should]` remains. Every `[Pass]` needs a quoted span or a `file:line`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

swept file: yes

- [Pass] All seven lessons in GH-1612 §1 and `PROJECT/2-WORKING/GH-1612-YESTERDAY-TODAY-RUN-SHEET.md:37-44` are carried by `.relay-artifacts/SKILL.md:75-91`: incomplete gates become questions, recorded code and environment evidence is required, access and fallback are planned early, passes require positive evidence, time-sensitive checks get a timer and rehearsal, PR findings use review history, and later server writes require per-action approval and backups. Lines 68-74 define the trigger, placement, six fields and repo-owned deploy doc reference. Lines 18-23,49-52,78-91 and 98-124 preserve the server boundary and guarded issue publish. Step 7 still uses the first body read and redrafts on a newer read, and step 8 independently reads the published issue and checks for implied sign-off. The sweep found no separate pre-existing defect or broken step reference.
- [Blocker] A4(a)'s captured output fails the requested six-column, gates-first layout. **Observed input:** GH-1612 §3 and the plan at line 121 require a six-column sheet with gates first. `TESTS-RESULTS/2026-11-25+GH-1612/smoke-a-deploy-day.md:14-24` has an extra `#` column and puts the early rehearsal (row 3) and copied config step (row 5) ahead of the production go-ahead (row 7). `awk -F'|' 'NR==14 {print "columns=" NF-2} NR==18 || NR==22 {print NR ":" $2 ":" $3}' TESTS-RESULTS/2026-11-25+GH-1612/smoke-a-deploy-day.md` exited 0 and printed `columns=7`, row 3 `Early rehearsal`, and row 7 `Production go-ahead (gate)`. `SUMMARY.md:19,24` acknowledges both observations while recording a pass. Chronological ordering does not satisfy gates first when support steps precede gates. **Affected scope:** Deploy-day sheets with multiple targets and support rows. **Falsifier:** Re-run the existing deploy-day fixture with the candidate skill and capture one six-column table whose gate rows precede rehearsal/config rows, preserving planned execution order in the time field and preserving the goal header and questions. Clarify the display order or exact column count in step 5a if needed, then update the receipt and summary against the observed output. Keep the check manual.
- [Pass] The other smoke observations are visible in the bodies. `smoke-a-deploy-day.md:6-12,17,21-24,59-75` places the sheet first after the preserved goal header and asks about the named owner with no time and each ownerless gate. The suggested Dev A remains marked unconfirmed and is asked about, so it is a proposal. `smoke-b-reread-cancels.md:11-46` preserves the goal and parks the canceled deploy without a sheet or sheet questions. `smoke-c-no-deploy.md:5-48` preserves the goal and adds no run-sheet output despite the open deploy-shaped PR. Line 3 of each of the four smoke receipts names 4/5/4/4 inputs respectively and says the flow was read-only. Those counts fit the listed inputs, but the receipts are executor reports and `SUMMARY.md:17` summarizes checkout cleanliness. I did not independently replay the executor actions, publish, or run the live validator.
- [Pass] The unchanged candidate is rejected by separate content, behavior and scope controls. `a1-content.log:2-20,22-45` records all 19 candidate matches, 19 base misses and the removed lesson-4 miss. `smoke-base-replay.md:5-18` shows the deploy remains prose, with no table or first section. Its excerpt does contain individual pass/stop examples at lines 10-11, so the red evidence is loss of the consistent row structure. `a5-diff-invariant.log:2-15` rejects the out-of-scope test path and the absent skill path with rc 1. Its five-path inventory is for the tested revision recorded in `provenance.jsonl:5`, before the evidence and final relay. A6 at plan line 123 remains the delivery check for the final receipt and actual PR base.
- [Pass] A3's privacy controls report the planted host/token and planted name found and the generic role label allowed (`a3-privacy-scan.log:18-28`). I independently ran `rg -n --hidden -i '([[:alnum:]._%+_-]+@[[:alnum:].-]+\.[a-z]{2,}|(https?|ssh)://|/Users/|/private/var/|\.(local|internal|corp|lan)\b|\b([0-9]{1,3}\.){3}[0-9]{1,3}\b)' .relay-artifacts/SKILL.md PROJECT/2-WORKING/GH-1612-YESTERDAY-TODAY-RUN-SHEET.md relay-system/2026-11-25/gh1612-{plan,final}-qa.md TESTS-RESULTS/2026-11-25+GH-1612` before appending this block. Exit 0, nine matches, all the public GH-1612 URL. The independent capitalized-word-pair scan and manual sweep found generic examples, tool names and project metadata. The plan's owner at line 6 and its echo in `a3-privacy-scan.log:19` are the same project metadata. Fictional roles and PRs are identified in `SUMMARY.md:3` and the smoke inputs.
- [Pass] A2 and the rating agree with the retained evidence. `cmp -s .relay-artifacts/SKILL.md skills/2-daily/yesterday-today/SKILL.md` exited 0, and `wc -l .relay-artifacts/SKILL.md` exited 0 with `136`. `diff -U 0 TESTS-RESULTS/2026-11-25+GH-1612/inputs/base-SKILL.md .relay-artifacts/SKILL.md` exited 1 as expected for different files and counting its diff lines gave `added=30 removed=1`, matching `a2-size.log:1-16` and the heading sequence. The tested path list in `a5-diff-invariant.log:10-15` contains the skill, plan, ledger and plan relay, with no suite, script or registry addition. The plan's four-axis rationale at lines 48-56 matches `releases.sql:1055`. An immutable read of `releases.db`, `SELECT gh_number,rating_pri,rating_sev,rating_appeal,rating_effort FROM roadmap_items WHERE gh_number='1612'`, exited 0 with `(1612, 30, 10, 50, 90)`. The change reuses the existing skill and validator, which fit GH-1612 §2.

**VERDICT: FAIL**  
**Basis:** The skill covers the seven lessons and the cancellation and no-deploy bodies behave as expected. The recorded deploy-day body does not meet A4(a)'s six-column, gates-first acceptance. The review used the seeded file and retained receipts. It did not run a delivery gate.

Handing off to Producer (claude-a) to address the deploy-day layout finding and record a passing A4(a) receipt.

### Producer · Round 1

Verified the finding firsthand before acting: run 1's `smoke-a-deploy-day.md` had a `#` column and put S-type rows (rehearsal row 3, config row 5) ahead of the production go-ahead (row 7). The reviewer's `awk` output reproduces.

- [Blocker] A4(a) layout (six columns, gates first): **Implemented.** The skill, not just the receipt, was ambiguous ("gates first (go-ahead, deploy, after-deploy checks)" did not say how support steps are ordered or that the table has exactly six columns). Step 5a now reads: "One row per step, six columns: step | named owner | planned time | exact method (...) | what a pass looks like | what stops the deploy. Gate rows first (go-ahead, deploy, after-deploy checks), then support rows (access, rehearsal, config), each in time order." Step 8 item 6 now says "run sheet first, six columns, gates first". Size is unchanged at 30 added lines, 136 total (`a2-size.log`).
- A4 smoke re-run (run 2) with new fresh read-only executors on the revised skill: (a) and the first draft of (b) are six-column tables with G1-G6 before S1-S3, directly after the goal header, with the owner-but-no-time gate and the no-owner gates asked as morning questions; (b)'s final body has no sheet after the cancelling reread; (c) has no sheet. Receipts replaced in place (run 1 stays in git history at `179e96fa0`). New `a4-columns-order.log` measures column count and row order on the receipts. Observed outputs: header columns=6 in both; row order `G1 G2 G3 G4 G5 G6 S1 S2 S3`. A1, A2, A3, A5 and the route/suites/PDDA logs were re-run on the revised revision; `a1-content.log` now has 21 patterns, 21/21 found on the candidate and 21/21 MISSING on base.
- Note for your sweep: step 5a is now at `skills/2-daily/yesterday-today/SKILL.md:66-91`, the step-7 sentence at line 105, step-8 item 6 at lines 123-124; the receipts' line numbers moved with the re-run logs.

Handing off to Reviewer for round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
