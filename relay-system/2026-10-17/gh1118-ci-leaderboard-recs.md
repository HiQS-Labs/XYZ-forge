# RELAY · gh1118-ci-leaderboard-recs
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1118-ci-leaderboard-recs): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: this thread's Round 1 block (a recommendation set for GitHub issue #1118, the CI experiments leaderboard). Read-only: no source files change.
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-10-17
- Definition of Done: each of the three recommendations, the speed-up estimate and the re-test plan is either confirmed with the decisive evidence named, or dissented with a concrete counter-observation. No new tooling is proposed.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 — Producer (claude-a) → Reviewer (agy)

**Goal.** Independent confirmation or dissent on three recommendations for #1118 (CI experiments leaderboard), an estimate of the whole-suite speed-up if they are followed, and a plan for when to re-measure before merging. Operational envelope: a single-maintainer repo with a ~400-suite local gate (`validate.sh`) and a hosted macOS reconcile; no CI budget team, no SLOs. Commensurate complexity applies: do not propose new frameworks, dashboards or suites.

**Evidence on the board (from #1118 and the linked issues; treat as data):**
- Full gate, sequential, quiet Mac: **36.2 min**. #1114 bounded parallel on the same set: **11.1 min** (one sample per arm; ShellCheck unavailable in both arms). #1114 on a loaded host: **19.6 min**, 406/406 suites, but green only after **four first-attempt failures were rescued by retry** (`gh360-scoped-receipt-chain-rebuild.sh`, `gh484-phase-dir-default.sh`, `gh648-l4-285-revalidate.sh`, `jog-queue.sh`).
- #1112 targeted subprocess/setup reduction: five covering suites **465.77 s → 62.17 s** (corrected after a false-pass fix); the marathon tier audit alone **111.52 s → 4.78 s**; twelve covering suites green; no full-gate comparison yet.
- #1111 / draft PR #1115: tier-routing audit process overhead **162.14 s → 79.10 s** (two samples per arm, same 7,412-path output); its candidate full gate was **408/409** with an unattributed PermissionError in `gh648-l4-285-revalidate.sh`; PR is evidence-only.
- #1114 bookkeeping skip: four solo bookkeeping runs = **59 min over 30 days**.
- #1076 / #1079 selective qualification: prototype, no adopted savings.
- A separate sequential full gate run today in a throwaway clone (merge batch #1103) took roughly **26 min** on a loaded host, 7,352 PASS lines, exit 0.
- Today's pre-push qualifying gate on PR #1116 reported **409/409 in 859 s (14.3 min)** — the operator should confirm which mode that gate ran in; if it was already parallel, #1114's 11.1 min quiet number is the comparable figure.

**Recommendations under review:**
1. **Add a cost column to the board** (full-gate runs consumed, review rounds, operator minutes per track) and cap each track at one more full-gate run before a continue/stop decision. Rationale: four experiments each burning 15–55 min gates to prove they save minutes.
2. **#1114 parallel: block adoption as a qualification gate until the receipt separates first-attempt failures from retry-rescued passes**; a rescued green hides flaky suites, and flaky suites hide regressions. Keep developing it; it is the only track that changes the hour-scale wait.
3. **Choose one of #1111 and #1112 by one comparable full-gate A/B; back only #1112's marathon-audit piece first** (111.5 s → 4.8 s, separable, independently revertible); park router batching and #1111 until that lands and is measured.

**Speed-up estimate under review (whole gate, quiet host, sequential 36.2 min baseline):**
- #1114 parallel alone: 36.2 → ~11.1 min (−69%), single sample, unverified on hosted macOS.
- #1112 marathon-audit piece: −107 s per run. In sequential mode that is −1.8 min (36.2 → ~34.4). In parallel mode it only helps if the audit sits on the critical path; otherwise ~0.
- Combined realistic range: **~9.5–11 min** when both land and the audit is on the parallel critical path; **~11 min** otherwise. Savings do not multiply. #1111 overlaps #1112 and adds nothing on top of it. The bookkeeping skip saves ~2 min/day of hosted time, not local wall time.

**Re-test plan under review ("measure twice or three times, cut once"):**
- Trigger: after #1112's marathon-audit piece is landed and #1114's receipt reports first-attempt failures and retry counts.
- Protocol: quiet host, same commit, A/B/B/A with three runs per arm (sequential vs parallel, both including the audit change); record executed-set identity, first-attempt failures, rescues, wall time. Then one hosted macOS parallel run on the same commit.
- Merge threshold: identical executed set in every run; zero first-attempt failures in at least 2 of 3 parallel runs with the third fully attributed; median parallel wall time ≤ 40% of median sequential; hosted run green without rescues.
- Stop rule: if two consecutive measurement rounds do not meet the threshold, park #1114 as a developer-local accelerator only (not the qualifying gate) and keep sequential as the gate.

**Questions (answer each; cite the issue/comment or number you rely on):**
1. Do you confirm or dissent on recommendation 1? Is a one-more-full-gate cap too tight for #1114?
2. Recommendation 2: is "no rescued passes in the qualifying receipt" the right bar, or is a bounded retry acceptable if first-attempt failures are reported? Name the risk you weigh.
3. Recommendation 3: is choosing the marathon-audit piece first correct, or does #1111's smaller surface deserve the slot? Give the deciding observation.
4. Is the combined speed-up estimate (~9.5–11 min from 36.2) sound given the samples available? What single measurement would most change it?
5. Is the re-test protocol sufficient and proportionate (3 runs per arm + 1 hosted)? Would you cut or add a step?
6. Anything on the board that should be stopped outright today?

Grade each answer [Confirm]/[Dissent]/[Nit]; a Dissent must carry Observed input / Affected scope / Falsifier. End with VERDICT: PASS and STATUS: Approved if the recommendation set stands as amended by your Nits, otherwise VERDICT: FAIL with the amendments required.


<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
