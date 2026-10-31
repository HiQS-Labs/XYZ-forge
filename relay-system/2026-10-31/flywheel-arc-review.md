# RELAY · Factory flywheel arc (#1298): Codex review of the combined summary
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-31.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(flywheel-arc-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **arc-review-artifact.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-31

### Artifact — arc-review-artifact.md
```
## Why this issue

Three separate sessions have now probed the factory flywheel (#1175) from different angles, and their results have only been summarised inside their own issues. This issue puts them side by side, says what they agree on, says what each one cannot show, and proposes whether and how they converge. It authorizes no implementation. Every number below is taken from a committed artifact or an issue comment cited in the table; the author ran only the #1279 window and **read, but did not re-run**, the other two (the Phase 0 session transcript is 2,478 messages and was not read in full).

## The three runs

| | Phase 0 spike (#1175) | Planning soak (#1279) | ATE/fuzz campaign (#1280) |
|---|---|---|---|
| **Question** | Can one real issue go backlog → Jog → Preflight → Marathon → PR → landed, and where does the loop stall first? | Can an agent sit in the decision seat of the outer-loop primitive (#1248) safely, and does letting it author plan content help? | Does the primitive's CLI surface survive hostile input without crashes or host damage? |
| **What ran** | One issue (#416, narrowed) by hand through the full cycle, with a deliberate `kill -9` mid-build, 2026-10-25/27 | 96 five-minute slots per arm, deterministic rules arm vs Codex (`gpt-6.1-terra`, medium) arm, 24 canaries + 8 seeded flawed plans, read-only, 2026-10-31 | 10,000 sandboxed `factory-primitive` invocations (`--help`, `generate-manifest`, `status`, `init`), 2026-10-30 |
| **Key result** | PR #1225 merged, #416 closed. Landing is the only hard block (`jog land` after a normal merge; fixed since by #1213). 0 of 281 open issues were admissible; 73% had no ledger row; 7 of the 11 with contracts were STALE. About 23.5 h of operator approval latency vs 28 min of unattended drive. | 90 Codex calls all valid and classified `ok` (7.6 s mean); 3 validator rejections of invented paths; crash recovery and frozen-identity checks held; 0 of 16 false approvals on seeded flaws. Authoring lifted `missing-scope` holds (20 → 0) but ready lanes after dry runs were 4 (rules) vs 3 (Codex) of the first ten. | 0 candidates; 1 new low-severity defect (`status` on an uninitialised root created state; fixed by #1290). Supervisor novelty measure ineffective (#1287); `tick` fails under the sandbox profile (#1288). Verdict: go for a stateful campaign after two changes. |
| **Evidence** | `TESTS-RESULTS/2026-10-25+GH-1175-phase0/SUMMARY.md`, D1-D8 drafts; #1175 comments | `TESTS-RESULTS/2026-10-31+GH-1279-stageb/SUMMARY.md`; PR #1282; follow-ups #1294, #1295, #1296 | `TESTS-RESULTS/2026-10-30+GH-1280/SUMMARY.md`; PR #1283; #1287, #1288 |

## What they agree on

1. **The constraint is the supply of admissible work, not the model.** Phase 0: ledger-field checks admitted 5 issues and all 5 failed a live preflight dry run (3 STALE, 1 AMBIGUOUS, 1 already had a PR); the survey found 202 with no ledger row and 64 with no Preflight Contract. #1279: the dry-run helper passed every lane through the structure validator and `marathon.sh --dry-run`, yet preflight rejected #722 (a moved artifact path) and #1204, #216, #446 (no Preflight Contract). **Caveat on comparability:** 0 of 281 is a rate over the whole open backlog; "4 and 3 ready of the first ten" is a count over lanes the planner had already selected. They share failure classes, not a denominator.
2. **Live evidence beats field checks.** Both found that something structurally valid can still be unrunnable, and that only a live preflight dry run tells the two apart.
3. **Delivered-but-open issues leak through.** Phase 0 recorded it as D4. The #1279 window found it independently in the proposal builder (#1294: #384 and #484 were scheduled although merged PRs closed them). Two independent observations of one class.
4. **Crash handling by receipts holds.** Phase 0: SIGKILL of the whole run tree, cold start parked, no refire. #1279: an injected `crash-act` at slot 37 became `uncertain`, the selected request was quarantined and never re-fired, on both arms. #1280: no process survived and no host change.
5. **Operator attention is the scarce resource.** Phase 0 measured it (6 touches, ~140 commands, ~23.5 h approval wait). #1279 produced 90 briefs unattended, and the independent reviewers then rejected 25 of 44 (rules pack) and 18 of 42 (codex pack) items, which is review load, not saved effort.

## What each run cannot show

- **Phase 0:** one issue; it says nothing about agent decisions at scale or about throughput beyond that item. Step 4 (sleep/wake) was not run.
- **#1279:** read-only. It never executed a build, a merge or a landing, so it is silent on the stage Phase 0 found to be the hard block. Authored-content accuracy was not established, and the two reviewers' verdicts on real items are unpaired (different packs, different strictness). One unplanned ~71-minute host suspension broke cadence for slots 76-84.
- **#1280:** it fuzzed the primitive's command-line surface, not Jog, landing or the agent. Its "no new signal" stop could not fire (#1287), so it proves bounds held, not saturation.

## Do they converge?

**Yes, on one path; partly on a second; not on a third.**

**Convergent: the reconciler.** #1175 Phase 1 is a one-shot decision step that reads Jog state and receipts and picks exactly one verb with a named reason. The outer-loop primitive (#1248) is that shape (decide → validate → act → receipt, one decision per tick, a deterministic validator as the safety boundary). The spike wrote down what the reconciler must do; the primitive and the two experiments supply some of it:

| Spike requirement | Supplied by | Gap |
|---|---|---|
| Admit on live evidence (row, contract, rating, plan, live preflight) | #1279's dry-run helper is a prototype (validator + `marathon.sh --dry-run` + preflight) | not in the primitive; delivered/closed checks missing at proposal (#1294) |
| Promote before firing; fresh clone per attempt; pinned clean primary | #1279 window: fresh clone, pinned head, frozen-identity checks per tick | promotion (SOP 1b) not modelled |
| After a crash trust the receipt, not the heartbeat | primitive: `uncertain` + quarantine, no refire (verified in #1279, fuzzed in #1280) | #1188 liveness unaddressed |
| Landing desk: packet, attestation, CI, one approval, merge, confirm closure | none | the spike's rank-1 missing system; `jog land` now accepts local reconcile evidence (#1213), but there is no approval/evidence surface |
| One verb per pass with a named reason | primitive: one decision + reason per tick | the primitive's verbs are `note`, `summarize`, `probe`, `idle`, `plan-draft`; the reconciler's are admit, run, land, park, escalate, idle |
| Shared-primary discipline (commit ledger writes) | the primitive isolates state in run roots and asserts ledgers unchanged | opposite requirement: a real reconciler must write the ledger |

**Partly convergent: the agent.** In #1279 the Codex arm chose the same request as the rules arm in all 25 slots before its first validator rejection (slot 26, an untracked authored path, which turned that slot into an idle and shifted its queue; checked slot by slot from the per-arm tables), so on *selection* the model added nothing measurable here; its measurable effect was authoring text, which lifted holds but did not raise admissible lanes. The evidence supports an agent as an optional *proposer* behind the validator, not as the thing that closes the gap Phase 0 found.

**Not convergent (yet): landing.** Phase 0 ranked it first; neither later run touches it.

## Proposed order of next steps (each with a falsifiable exit; none started)

1. **Make admission a deterministic gate on live evidence.** Reuse the #1279 dry-run logic plus delivered/closed checks. Exit: run it over the open backlog and report admissible count with a reason per rejection, directly comparable to Phase 0's 0 of 281. No model.
2. **Fix the inputs the gate exposes:** #1294 (delivered scheduled), #1296 (stale paths, missing contracts), decide #1295 (injected text carried into briefs). Exit: the same gate run shows those classes gone.
3. **Landing desk MVP** (Phase 0 rank 1), building on #1213. Exit: a parked `awaiting-landing` item reaches landed-and-closed with one bound approval and a post-land confirmation.
4. **Reconciler in shadow mode** on the #1248 primitive, with the six real verbs over real Jog state, rules arm first. Exit: its logged verb and reason per pass compared with the operator's actual decisions over N days; seeded flaws and canaries kept; no ledger writes in shadow.
5. **Point the model at the bottleneck, not at brief text.** Hypothesis, untested: Codex proposes fixes for stale artifact paths and missing Preflight Contracts, a human reviews, and the metric is the fraction of repaired contracts that then pass preflight.
6. **Stateful ATE campaign** (#1280's follow-on) once #1287 and #1288 are fixed and a stateful target (the shadow reconciler) exists.

**Do not** scale the planning arm before steps 1-3: it raises the number of candidate plans faster than approval and landing capacity (this is an inference from Phase 0's approval latency and #1279's review rejection rates, not a measurement).

**Shared metrics** for every later run so results can be compared: admissible-issue count and rejection reasons; ready-lane fraction after live preflight; time to landed; operator touches; per-verb outcome with named reason; false-approval rate on seeded flaws; agent calls, validity and cost (`unknown` stays `unknown`).

## Related
#1175, #1248, #1279, #1280, #522, #1022, #1188, #1224, #1213, #1250, #1287, #1288, #1294, #1295, #1296.

*Draft; being reviewed by Codex through `relay-xyz` before it is finalised.*

---

# APPENDIX A: evidence that lives only in issue comments (the repo has the rest)

# Evidence pack: issue comments not in the repo (verbatim excerpts, fetched 2026-10-31)

## #1175 comment 2026-10-26T02:58Z: Phase 0 step 1 survey
## Phase 0 — step 1: candidate #416 selected and admissible (intake ≈ 2 min agent time after the pick, no ledger writes)

**Survey of 280 open issues at `a3450a2c` (02:53Z).** None could run as they stood:

| Missing piece (first one found) | Issues |
|---|---|
| ledger row (so no doc and no rating either) | 202 |
| Preflight Contract in the capture doc | 64 |
| remediation plan in the issue (regex check, rough) | 7 |
| capture doc | 2 |
| nothing found missing | 5 |

All 5 of the "nothing missing" issues failed when tested. Preflight `--dry-run`: #423, #141 and #275 return **STALE (exit 4)**, meaning their fix checks no longer match the tree. #1098 returns **AMBIGUOUS (exit 7)** because the issue has no `## Acceptance` section. #418 already has open PR #1211. #345 is open but its fix is already in the tree (`test/agent-chorus.sh:617-624`).

**Top 3 offered:** #416 (contract out of date, half its items already done), #446 (no contract, no Acceptance section), #767 (no contract, no remedy steps, large). The operator picked **#416**, narrowed to items 1 and 3.

**Intake steps for #416** (02:56:28Z → 02:58:21Z):
1. Operator pick and scope decision (1 operator touch).
2. Re-checked each of the four items against the tree (about 6 read-only commands). Items 2 and 4 were already done; item 1's §7 wording was already true, but the deps are still under `dependencies`.
3. Posted the narrowed remediation plan as an issue comment, selected for admission: https://github.com/HiQS-Labs/XYZ-forge/issues/416#issuecomment-6407209414
4. Rewrote the capture doc: new fix checks, `skills/relay-xyz` → `skills/1-hourly/relay-xyz`, added `package-lock.json`, `## Acceptance` plus 2 declared `[dropped]` deviations.
5. `swarm-preflight --project-doc … --dry-run` → **ready (exit 0)**, acceptance `match — 4 issue criteria reconciled: 2 deviation(s) declared`.
6. Ledger read-back: row `rmi-01M1M3CB6E0MKZNSCR4BM0EESS`, rating 50/30/60/95 (a real rating, not a placeholder). `jog add 416 --dry-run` → would enqueue.

Commit `dc812539` (local; it will be pushed before the run).

**Findings so far**
- **Stale contracts are what actually blocks the "complete" issues.** Every issue that looked complete failed preflight, and none of that shows up in the ledger. Admission needs a live preflight `--dry-run` in addition to the field checks.
- **Open issues whose fix already landed** (#345, and half of #416). Intake needs a delivered-but-open detector.
- **Preflight widens the artifact list on its own.** The suggested drive adds 7 `test/*.sh` files that read `relay-xyz` SKILL.md to the 3 contract artifacts. The pre-advance gate becomes `validate.sh --auto development`, not the contract's `bash validate.sh`.
- The Jog primary pin is unset for this origin. It's a one-time step needed before any mutating `jog` verb.

Evidence: `TESTS-RESULTS/2026-10-25+GH-1175-phase0/step1-*` (survey script, JSON, preflight logs before and after).


## #1175 comment 2026-10-25: Critical path (ranking only)
## Critical path: the three components that keep the flywheel turning

Recorded 2026-10-25 as a comment so the body stays the design of record. Ranking only. This comment authorizes no implementation.

**Not in the top three: the heartbeat / wake.** Waking is cheap plumbing: launchd plus the dead-man's switch in #1188. A wake does nothing if no issue is ready.

### 1. Intake and admission: the supply

Turns a GitHub issue into work Jog is allowed to run: registered ledger row → capture doc with a Preflight Contract → remediation plan written in the issue → reviewed PRS → admission decision (#522, #1022, #1168).

- This is the most starved part today: 182 of 265 open issues had no row or capture doc (2026-10-21), and #1177 found 60 rated rows holding placeholder scores (13 on the old 1–5 scale, 47 exactly `50/50/50/50`).
- The "doc manager" role is the middle of this pipeline. **Caution:** changing a doc's scope or acceptance criteria changes what the factory is authorized to do. Such edits go through review, like ratings in PR #1176, never a silent rewrite.

### 2. Verification and landing: the closer (the missing piece)

The loop halts after every issue today: Jog parks each approved item at `awaiting-landing (PR #n)` because `--auto-merge` is refused in real runs (`JOG_AUTO_MERGE_CHECKPOINT`). Landing then needs:

- a reviewer attestation bound to the exact `reviewed_candidate`
- CI passing on that candidate
- operator approval (D3)
- `releases jog land`
- confirmation that the issue actually closed

Throughput equals the rate of trustworthy landings, not the rate of runs. Operator time is the scarce resource here, so the closer's job is to make each approval a quick decision on a compact evidence summary.

### 3. The reconciler: the decision step

The one-shot `factory reconcile` (Phase 1). After any outcome it reads Jog state and the run's receipts and chooses exactly one action: admit the next issue, run, land, park with a reason, escalate, or idle. It is idempotent and records what it did. Jog already provides the queue, leases and park-on-restart, so this is a thin layer. The heartbeat is a small piece of it: the trigger that starts each pass and the alarm when passes stop (#1188).

### Also on the critical path

- **Operator attention is the real limit.** Every gate in #1 and #2 ends at the operator. Batch approvals and keep evidence compact, or the factory queues up behind review.
- **Dogfood return channel.** Parked items and failures should become well-formed new issues: harness defects routed to XYZ Forge, application defects kept in their own repo. That turns the queue into a flywheel.

### Suggested order

Run the Phase 0 spike with one admitted issue and see where it stalls. Expect landing first: a single issue can get through intake by hand, but it hits the landing boundary immediately. After that, intake becomes the bottleneck. Build the reconciler alongside both, since it is mostly glue over Jog.

### The three most important missing systems (status 2026-10-25)

Jog (queue, leases, park-on-restart), Preflight, Marathon (execution, receipts, driver heartbeat) and `jog land` exist. What is missing is the system **around** each of the three components above. Ranked by how soon each one stops the flywheel:

| Rank | Missing system | What exists | What is missing | In flight |
|---|---|---|---|---|
| 1 | **Landing desk.** Turns `awaiting-landing` into a landed, closed issue | `releases jog land` (manual), reviewer attestation bound to `reviewed_candidate`, `result@1` receipt | An approval request per parked item with a compact evidence summary (diff scope, attestation, CI on the exact candidate, risk flags); an approval bound to that candidate; the land call; post-land confirmation that the issue closed and the row reconciled; a policy for pre-authorized PR classes (D3) | PR #1213 (`jog land` evidence beside hosted reconcile). No approval/evidence surface yet |
| 2 | **Admission pipeline.** Keeps a supply of runnable issues | `roadmap add`/`rate`, HQ capture renderer, Preflight Contract check, prs-backfill (PR #1176, merged) for rating registered rows | Continuous GitHub → ledger intake; capture-doc + Preflight Contract authoring for unregistered issues; a reviewed path for scope/acceptance edits; placeholder-rating detection (#1177); the #522 admission decision itself. Today 182 of 265 open issues cannot even be rated | #1022 / PR #1024 (draft), #1168, #522, #1177 |
| 3 | **Factory reconciler + foreman liveness.** Decides the next action after every outcome and proves passes are still happening | Jog state machine, cold-start park, driver heartbeat | The one-shot `factory reconcile` (one action per pass, idempotent, receipted); restart after the landing boundary; on-`failed` policy (D2); last-run record + hosted dead-man's switch; Jog lease reading the driver heartbeat | #1175 Phase 1, #1188 |

Why this order: with a single hand-admitted issue the Phase 0 spike stalls at **landing** first (every approved run parks there), so the landing desk is the first hard block. Once one issue can land, **supply** runs out next, because nothing admits the next issue without manual work. The **reconciler** is the cheapest of the three (glue over Jog), but it is what makes the other two continuous instead of operator-driven.

Explicitly **not** missing: a new queue, a new execution engine, a new heartbeat file, or a hosted platform (see the Anvil decision gate above).


## #1280 comment 2026-10-31T13:44Z: campaign result
## Campaign result (2026-10-30)

**Verdict: one new low-severity defect, nothing else.** Codex final QA passed (round 2). Evidence lands with PR #1283 (`TESTS-RESULTS/2026-10-30+GH-1280/SUMMARY.md`, `provenance.jsonl`).

- **Smoke:** passed in 428 s. All 6 controls passed, each with a witnessed red; Track B passed 17/17, plus B2 and B3.
- **Long run:** 10,000 sandboxed `factory-primitive` invocations in 4,496 s, stopped by the mutation budget. 0 candidates (no traceback, no unexpected exit code). Canaries were unchanged, no process survived, and there were no host violations.
- **Coverage:** `--help`, `generate-manifest --output`, `status` and `init`, including the run-root, cap, state and input guards. 89% of cases were argparse usage refusals. `tick`, `packet`, `tool` and state sequences were excluded by design.

| ID | Disposition | Follow-up |
|---|---|---|
| D1 | New defect: `status` on an uninitialized root creates `state.db`; `init` then refuses and `tick` fails | #1284 |
| D2 | Expected: `--output` writes where it is told | — |
| D3 | gen4 oracle gap: 234 run-root refusals unclassified | — |
| D4 | Replay setup fault (mine), explained | — |
| D5 | `tick` fails under the sandbox profile even on a clean root | #1288 |
| D6 | No-new-signal stop never fired (usage signatures echo mutated tokens) | #1287 |

**Qualified acceptance:** the run stayed within every bound, but "stopped at no new signal" is unproven because of D6.

**Stop/go for a stateful campaign:** go once #1287 and #1288 are resolved.

**Deviation:** a replay reset deleted the long-run corpus. The full telemetry was kept and the admission history was rebuilt from it.

This issue closes when #1283 merges.
```
- Definition of Done: a verdict on whether the draft's facts are accurate and its comparisons and next steps are sound, with concrete corrections, so the draft can be sharpened before it replaces the body of issue #1298.

**What you are reviewing.** A combined summary of three runs on the XYZ-forge factory flywheel (#1175): the Phase 0 spike (one real issue through Jog -> Preflight -> Marathon -> PR), the 8-hour planning soak (#1279, an agent in the decision seat of the outer-loop primitive #1248), and the ATE/fuzz campaign (#1280). It claims what they agree on, what each cannot show, whether they converge, and an ordered set of next steps. The draft is embedded below, followed by Appendix A (verbatim excerpts of issue comments that are not in the repo).

**Operational envelope.** Local single-operator project; this is a documentation and planning review, nothing executes. You have read access to the repository checkout you run in (it is current `development`), so check claims against these committed artifacts: `TESTS-RESULTS/2026-10-25+GH-1175-phase0/SUMMARY.md` (+ `D1`-`D8` drafts), `TESTS-RESULTS/2026-10-30+GH-1280/SUMMARY.md`, `TESTS-RESULTS/2026-10-31+GH-1279-stageb/SUMMARY.md` and its `window/` evidence (`window/window-summary.json`, `window/dryrun-*/dryrun.json`, `window/qa/qa-score.json`, per-arm `tables.json`), `utils/py/harness.py` (the primitive's tool set is `TOOLS`), `PROJECT/2-WORKING/GH-1248-OUTER-LOOP-PRIMITIVE.md`. Do not ask for new tests, suites or machinery; grade the argument, not the code. Do not edit any file except this relay file.

**Questions** (cite file:line or the artifact path for every correction; for any claim you say is wrong give the concrete evidence):
1. **Accuracy.** Check every number and attribution in the draft against the artifacts: the Phase 0 figures (0 of 281, 73%, 7 of 11 STALE, the five "nothing missing" issues, 202/64 survey counts, ~23.5 h approval, 28 min unattended, 6 touches / ~140 commands), the #1280 figures (10,000 invocations, 0 candidates, D1/#1290, #1287, #1288), and the #1279 figures (90 calls, 3 rejections, 20 -> 0 `missing-scope`, 4 vs 3 ready, 25 of 44 and 18 of 42 rejections, 0 of 16 false approvals, the slot-26 divergence). List each error or unsupported statement.
2. **Shared findings.** Are the five "they agree on" items really supported by *both* runs they cite, or are some of them the author pattern-matching across different measurements? In particular item 1 (supply of admissible work is the constraint) and item 3 (delivered-but-open found independently). Say what is and is not comparable.
3. **Convergence table.** Is the mapping from the spike's seven reconciler requirements to what #1248/#1279/#1280 supply correct (check the primitive's real verbs and behaviours in `utils/py/harness.py`)? Is anything claimed as supplied that is not, or missing that is supplied? Is "the reconciler" and "the outer-loop primitive" really the same component, or does the draft conflate two things?
4. **Overclaims.** Mark every sentence that goes beyond the evidence (for example "the model added nothing measurable on selection", "do not scale the planning arm before steps 1-3", "point the model at the bottleneck"). For each, say whether it is a measurement, an inference, or speculation, and whether the draft labels it correctly.
5. **Next steps.** Are the six steps in the right order, each with a falsifiable exit, and commensurate (nothing overbuilt, no duplicate of existing work such as #522, #1022, #1188, #1224, #1213)? What is missing (for example liveness #1188, state-off-git #1224, the D1-D8 defects from the spike, whatever the repo already plans in `PROJECT/`)? Which step would you drop or merge?
6. **Sharpen.** Give the concrete rewrites you would make (replace sentence X with Y) and a recommended single next experiment, so the Producer can apply them. Keep the issue short enough to read.

Write the verdict (PASS / FAIL / PARKED) with a Basis; PASS only if the draft needs no change to its facts. Findings must be graded and carry the evidence lines described in the protocol above.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
