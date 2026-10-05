# RELAY · GH949 resumed final cancellation QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-04.
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
6. **Commit only the relay file** (`relay(gh949-resumed-final-cancellation-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **final-qa-packet.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-10-04

### Artifact — final-qa-packet.md
```
# PR953 resumed final independent QA

Goal: determine whether PR953 can leave draft after its latest Fable B1 blocker
is repaired. Current implementation `3a2e1d5e`; previous PR head `0b892acd`;
integration base `6beac5bf` (PR948 merged). This continues the existing approved
GH949/GH912 plan, not a new feature or architecture.

Operational envelope: local macOS developer CLI. Use commensurate complexity:
reuse existing helpers; no new executor, global library signal registration,
suite, gate, registry, schema, dependency or speculative enterprise machinery.
No live provider calls, services, tunnels, merge or promotion are in scope.

Read the complete canonical plan and Fable review, the retained original evidence,
and this resumed evidence summary. Sweep all six touched runtime files in full:
`utils/py/proc_group.py`, `domain_oracles.py`, `metamorphic_oracle.py`,
`utils/ate/scripts/run_variations.py`, `skills/1-hourly/relay-xyz/find-harness.sh`,
and `test/lib/runner-envelope.sh`. The resumed runtime diff is only the two oracle
imports and `__main__` guards; approved original API shapes should remain intact.

Questions:

1. Does B1 close at both actual CLI entry points: catchable TERM/INT unwinds through
   shared group cleanup, preserves143/130 and leaves library/threaded calls free
   of global handlers? Do normal exit, argument-error and JSON CLI contracts hold?
2. Are the source-pinned red/base/repaired controls meaningful and nonempty?
   Base outer-cap cleans the same-group command; pre-repair PR orphans it; repaired
   controls remove it. Direct TERM orphaning is inherited, now also repaired.
   Eight repaired controls cover both CLIs, TERM/INT, outer-cap and direct TERM
   against a resistant command. No SIGKILL or deliberate session-escape guarantee.
3. Does the whole PR still satisfy F1–F9/K1 without unjustified changes to existing
   caller result shapes, ATE record consumers or selector precedence? Check original
   evidence rather than assuming historical approvals establish it.
4. Is nonblocking S1 correctly dispositioned to PARKED, with no false repair claim?
   Concurrent idempotence cancellation remains bounded by worker timeouts, as Fable
   allowed; do not silently extend this into a new thread-cancellation contract.
5. Do governance and ledger statements distinguish current readiness from earlier
   checkpoints? The disjoint merge replayed only949/912 using the existing writer;
   both owned rows were explicitly readmitted and retain their original ratings.
   Final full gate runs once after your valid approval, in a separate full clone.

Focused suites: domain17/0, metamorphic8/0, process guard43/0. Codex shim preflight
43/0 in a separate verification clone; raw log will ride with final receipts.
Read `TESTS-RESULTS/2026-10-04+GH-949/` source identities, results and provenance.
Older full870s gate is historical; do not reuse it as new implementation evidence.

Graph handoff: Verify tier; nearest primary project
`Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation2026-10-05T04:59:22Z.
Primary graph is development, not this unmerged PR. Search proc_group exhausted
7 results; one-hop run_bounded traces show ATE/fuzz/Claude/reconcile callers.
Coverage reported primary metadata_match for proc_group/domain/metamorphic/ATE
and runaway guard, missing canonical GH949 plan. Direct PR-source reads override
that graph. Ledger helper discovery15 results exhausted; coverage metadata_match;
exact clone source was read before use. No exhaustive graph claim is supplied.
If graph tools are unavailable, use exact source and do not claim MCP access.

Reviewer writes ONLY the relay thread; ALLOW_PATHS is empty. Do not run suites,
pytest, validate, installs, executable fixtures or mutating Git commands inside
the relay worktree. Narrow read-only/in-memory probes may use `.relay-scratch`.
Source claims need file:line; every behavior finding needs Observed input,
Affected scope, Falsifier. Declare swept file yes/no. Append one substantive
review block, preserve all prior bytes except header NEXT/STATUS/ROUND, set
PASS/FAIL with honest limits, and hand off. The harness commits; do not commit
or push yourself. Three-round review budget; no merge authority.
```
- Definition of Done: Fable B1 repaired, original F1–F9/K1 contracts preserved, retained nonempty red/green evidence, no current blocker. Final gate pending independent approval.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
