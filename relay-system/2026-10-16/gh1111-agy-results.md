# RELAY · GH-1111 Agy methodology and reporting QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-16.
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
6. **Commit only the relay file** (`relay(gh-1111-agy-methodology-and-reporting-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/ISSUE-REPORT.md** — the read-only path that
  `relay-drive.sh --artifact-file TESTS-RESULTS/2026-10-16+GH-1111/ISSUE-REPORT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: codex-author
- Started: 2026-10-16
- Definition of Done: truthful and reproducible experiment methodology/results reporting; explicit unresolved red gate; no runtime merge approval.

## Review packet — bounded reporting QA

Goal: independently QA GH-1111 methodology and the exact results posted at https://github.com/HiQS-Labs/XYZ-forge/issues/1111#issuecomment-6230834142. This is an evidence-only technical spike. The candidate is held after a red full gate. Approving report accuracy must not be described as approving production code or merge readiness.

Operational envelope: one local audit suite, a small exploratory benchmark on a heavily loaded shared Mac, no gate policy/routing changes and no new registered tests. Be commensurate; do not demand a CI rebuild or an unrelated process-group repair. Reviewer writes only this relay thread. No validate.sh, test/*.sh, pytest, executable fixtures or worker dispatches in the relay worktree. Narrow read-only arithmetic/data checks are allowed with scratch discipline.

Read the whole candidate file from its frozen revision, not just the current working tree: `git show c2d875fab7dd1bc3fb3648a2f7b94d60ed8fceb4:test/gh365-tier-fail-closed.sh`. Base is c9ecd0bf4c08e77765968a7bf797849658386a6e. The current branch tip deliberately restores baseline test bytes; candidate.patch and the immutable candidate commit retain the measured source. Do not misread the hold as missing implementation evidence.

Read all of TESTS-RESULTS/2026-10-16+GH-1111/SUMMARY.md, ISSUE-REPORT.md, issue-report-snapshot.json, measurements.jsonl, provenance.jsonl, ab-summary.json, controls.json, full-validation.jsonl, full-gate-context.json, aborted-publication-context.json and aborted-publication-validation.jsonl, plus measure.py and controls.py. Read the source diff and relevant router output/schema when needed. The complete frozen test-file lists are equal; the report branch adds evidence afterward. Existing graph generation is stale; use exact source/Git reads for material claims.

Answer these concrete questions:

1. Do raw timestamps, revisions, return codes and A/B/B/A order support 162.136 -> 79.101 seconds, 83.034 seconds / 51.213% reduction, N=2 each? Is the comparison explicitly limited by host load, cache/order variability, and bundled changes, with no unsupported hosted or whole-gate speedup?
2. Are all 7,412 path checks and five existing assertions retained, normalization restricted to the random fixture line, parser/membership checks accurately scoped, and expected red/mutation/restoration separated from passing measurements? Does the full candidate source introduce any material correctness regression within this bounded optimization?
3. Does the report preserve the full gate's RED 408/409, initial and retry failure, 406 executed shell suites, exact frozen candidate, explicit live-worker opt-out and clean identity/envelope? Are later isolated base/candidate greens correctly NOT used to establish root cause or erase the failure? Is the separate canceled publication attempt clearly incomplete and excluded from completed-run statistics?
4. Does ISSUE-REPORT.md match the posted snapshot exactly (allow only terminal newline normalization), and do its claims match retained evidence? Are candidate hold, restored branch-tip source, documentation-only publication and no bypass/merge claims honest? Flag unsupported claim strength or missing limitations.
5. Is the recommendation proportionate: retain an experiment with a useful focused signal, hold runtime adoption, avoid changing test selection/qualification based on this small sample? Do not turn report QA into runtime gate approval.

Output a Reviewer block with VERDICT: PASS/FAIL/PARKED, Basis (textual review of retained execution evidence vs your narrow arithmetic queries; no claimed test reruns), literal swept file: yes/no, numbered answers, graded findings with file:line or quoted evidence. Behavior-change requests require Observed input / Affected scope / Falsifier; no speculative machinery. Set STATUS: Approved only if methodology and reporting are accurate; otherwise Changes requested and hand back to codex-author. Commit only the relay thread; no push.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Producer · codex-author
**Did:** executed bounded suite optimization and retained raw A/B/control/full-gate evidence; restored baseline branch-tip test after red full gate; published exact findings to GH-1111.
**Verification:** A/B/B/A all exit 0; deliberate parser red exits 1 and saved bytes restored; three focused suites pass; full gate RED 408/409, later isolated base/candidate both pass with unresolved attribution; canceled publication excluded; evidence-only documentation gate green, no bypass. Independent review pending.
**Re-review this:** report accuracy and bounded methodology, not runtime merge approval; frozen candidate c2d875fa, all raw receipts and exact issue snapshot.
**Commit:** inputs committed before handoff.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
