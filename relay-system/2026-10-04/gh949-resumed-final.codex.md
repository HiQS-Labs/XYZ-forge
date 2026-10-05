# RELAY · GH949 resumed final cancellation QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-04.
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

### Reviewer · Round 1 (codex)

swept file: yes

**VERDICT: PASS**

**Basis:** B1 is repaired at both oracle CLI boundaries with the existing shared helper. The retained real-process red/base/repaired controls are nonempty and distinguish the regression from the inherited direct-TERM gap. Original F1–F9/K1 evidence and caller contracts remain consistent with the current source. No current blocker found. This approves the implementation/evidence for the subsequent final full-clone gate; it does not establish gate success, PR readiness, merge or promotion.

Sweep: the embedded packet, complete canonical GH949 plan/recon, complete Fable review, original/resumed evidence summaries, and all six runtime files in full: `proc_group.py` (251 lines), `domain_oracles.py` (651), `metamorphic_oracle.py` (405), `run_variations.py` (602), `find-harness.sh` (510), `runner-envelope.sh` (125). Material consumers inspected directly: `fuzz_engine.py:245`, `claude_cli.py:46`, `wave_reconcile.py:654`, `checkin.py:66`, `compile_issue.py:52`, `runaway-guard.sh:56`, and both gate-envelope call sites. Verify-tier graph project/generation confirmed as `Users-noelsaw-Documents-GH-Repos-XYZ-forge` / `2026-10-05T04:59:22Z`; targeted proc_group Function search exhausted 3 results. Coverage reports metadata_match on primary source, missing canonical plan. The primary graph is development, not this PR. My trace_path call was denied by runtime approval policy; exact seeded source and supplied recon were used instead. No exhaustive graph claim.

- **[Pass] B1 — catchable cancellation reaches group cleanup.** `domain_oracles.py:646` and `metamorphic_oracle.py:400` now wrap actual `__main__` execution in `cancellation_signals()` and return `128 + signum`; `proc_group.py:57` ignores repeated INT/TERM before raising, `:66` restores prior handlers, and `:139` cleans/reaps/closes pipes before re-raising. No handlers are registered by `run_bounded` itself (`:108`). Narrow in-memory probe command: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 .relay-scratch/probe.py`, exit **0**. It uses `runpy` on the actual entry guards, mocked Popen/kill_existing, and invokes the installed handler during mocked communicate. Decisive output for **each** CLI: `normal rc=0`, parsed JSON `passed=true`; `argument-error rc=2`, no Popen; `TERM rc=143 cleanup=true`; `INT rc=130 cleanup=true`; `handlers_restored=true`. Mock cleanup asserts both signals ignored, wait performed and both pipes closed. Sequential and concurrent library calls pass while any `signal.signal` call is made an assertion failure. This is control-flow measurement, not a fresh process-survival run.
- **[Pass] Retained B1 falsification is meaningful.** `TESTS-RESULTS/2026-10-04+GH-949/replay.py:54` requires nonempty readiness and PID/PGID >1; `:61` measures the child's process state; `:68` combines absence with the exact conventional status; `:70` independently cleans survivors. `base/results.json` and `pr-before/results.json` retain four cases each: direct TERM survives on both; outer-cap disappears only at base, survives pre-repair. `repaired/results.json:260` reports `all_properties_pass: true` over eight cases, with 143/130/124 as appropriate and all child-survival flags false; TERM-resistant direct commands also disappear. These are supplied separate-full-clone receipts I inspected, not reruns here. SIGKILL and deliberate session escape remain excluded.
- **[Pass] Source/evidence continuity.** Read-only command `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 .relay-scratch/audit.py`, exit **0**. Decisive output: `17 nonempty resumed artifacts; all SHA256 match`; `base 4`, `pr-before 4`, `repaired 8 nonempty startup cases; expected survivor matrix and independent cleanup hold`; `oracle changes exactly import + guard relative to pinned PR-before; proc_group/telemetry unchanged`; `3 focused logs hash-match, rc=0; before/after clone identity and tracked diff identical`. The audit removes only the two new guards/imports in memory and matches `source-identities.json`'s pinned pre-repair hashes. It also matches unchanged proc_group/ATE/checkin/compile source against original `manual-contracts/provenance.jsonl:1`. Raw focused counts are 17/0, 8/0 and 43/0 (`gh478-runaway-guard.sh.log:66`). Historical 870s gate is not reused for this implementation.
- **[Pass] F1/F7 and existing process callers.** `proc_group.py:71` retains BoundedResult fields; Popen spawn errors propagate (`:122`), timeout returns incomplete `rc=None` (`:131`), missing timeout refuses before Popen (`:173`), and kill-pgid remains timeout-optional (`:168`). `fuzz_engine.py:245`, `claude_cli.py:46`, `wave_reconcile.py:654` still consume the same fields; `runaway-guard.sh:91` supplies timeout and preserves publication/ACK seams. Original `manual-process/after/summary.json` records 143/130, prior bytes preserved, one interrupted row and child absence; `manual-process/COMPATIBILITY.md` records normal success, genuine exit124, timed-out result, repeated-signal ACK cleanup and original SystemExit77 propagation. No result-shape expansion is requested.
- **[Pass] F8 and first-versus-later idempotence.** `domain_oracles.py:127` marks incomplete timeout/launch observations; zero-state/containment reject them (`:221`, `:324`). `metamorphic_oracle.py:185` uses the shared runner for every repetition, and `:207` requires completion. Domain `:383` compares the first rc/stdout with the existing result fields. Original `manual-process/after/summary.json` shows no late writes after timeout, including later repeats; `manual-idempotence/before/results.json` falsely passes first-only differences, while `after/results.json` rejects them and retains stable success. `manual-contracts/results.json` records threaded timeout failure and unchanged handlers. Concurrent cancellation remains bounded by worker timeouts, as expressly accepted in resumed SUMMARY lines43–45.
- **[Pass] F2/F3 state visibility.** `domain_oracles.py:95` hashes directory symlink entries without traversing targets; `:244` resolves common/config.worktree paths, records read errors and presence, and `:326` rejects unreadable metadata. Original `manual-state/base/results.json` contains false passes for add/remove/retarget and linked config; `after/results.json` detects all, retains no-op success and unchanged link targets. The audit reports `original state acceptance matrix: base 4/14, repaired 14/14; result hashes match`. Additional absent-config/host refusals and linked HEAD changes are recorded in `manual-contracts/results.json`.
- **[Pass] F4/F5/F9 and ATE consumers.** Empty-grid refusal precedes control/baseline writes (`run_variations.py:436`); no-row budget refusal is `:581`; active cancellation/spawn errors become a single fail row and stop (`:484`, `:497`, `:567`, `:570`). UTC run IDs/timestamps use gmtime (`:422`, `:552`). Existing schema1.0 and normal filing result flow remain (`:548`, `:588`). Original state receipts show empty-grid rc2/no rows, missing executable rc127/one row, and UTC within sampled bounds. Full spawn/interrupted records are accepted by checkin/compile in `manual-contracts/results.json`; current readers use the retained top-level status and classification fields (`checkin.py:69`, `compile_issue.py:52`). Zero-minute initialization remains an explicit accepted limit, not a no-write promise.
- **[Pass] F6/K1 selector precedence.** Optional HOME/XDG/config/AGY guards remain at `find-harness.sh:122`, `:129`, `:356`; override-first resolution is unchanged at `:179`. Envelope entry unsets only inherited locator selectors (`runner-envelope.sh:62`), while explicit DB selection wins (`:65`). Both runners enter this envelope before dispatch (`validate.sh:1238`, `ci-local.sh:399`). Original environment receipts retain inherited 48/2 and40/1 red controls, then wrapped 50/0 and41/0 with explicit fixture selections and DB behavior preserved (`manual-environment/afterfix/report.md`). The external driver's stale-SHA failure is disclosed there, not relabeled as a passing wrapper.
- **[Pass] Governance/ledger and proportionality.** Resumed plan disposition and `CHANGELOG.md:3` explicitly keep PR953 draft/current final gate pending and distinguish earlier checkpoints. `ledger-resolution.json` reports only two writer replays. Read-only SQL-table import into memory in the audit reports `ledger 949 ratings=90/85/50/55 in-progress; latest in_flight accepted_start=true` and `ledger 912 ratings=82/80/50/85 in-progress; latest in_flight accepted_start=true` (dump rows `releases.sql:805`, `:806`, events `:3038`, `:3039`). No new executor, library signal registration, schema, dependency, suite or gate is introduced by these two imports/entry guards.
- **[Nit] Pre-existing limitations retained, no additional pre-existing blocker identified.** S1 remains at `metamorphic_oracle.py:102` and is correctly dispositioned, without claiming repair, in `PARKED/2026-10-04-metamorphic-worktree-config.md`. Fable's inherited N1/N2/N3/N5 remain source-visible: zero-mutation uses leader-only subprocess timeout (`metamorphic_oracle.py:128`), tree digest omits empty directories (`domain_oracles.py:104`), cleanup wait can replace the original exception if it expires (`proc_group.py:142`, `:241`), and absent HOME/XDG can yield an empty config-save hint (`find-harness.sh:413`). They do not justify expanding this accepted repair. No behavior-change request in this turn.
- **[Unverified — needs clone run] Final full qualifying gate on the approved implementation, final Codex-shim preflight raw receipt, and resulting hosted exact-SHA checks.** These are outstanding follow-on work, not evidence claimed by this approval. No suites, pytest, validate, executable fixtures, live services/providers or Git commands were run here. Two preliminary read-only extraction attempts exited1 because my probe assumed dump DDL and list-valued row counts; corrected audit/extraction exited0. Only this relay file was edited; probe code lived solely in `.relay-scratch/`.

Relay closed (Approved), no further review turn needed. Producer (codex-author) should run the planned final qualifying gate once in the separate full clone, retain exact-source receipts and identity, then assess PR readiness; approval does not authorize merge or promotion. Token closed with `done`; harness owns the file-scoped commit.


### Attestation · relay-drive — 2026-10-05T05:23:30Z
task: RELAY-GH949-RESUME-20261004
reviewer: codex
status: Approved
reviewed-head: 157bf05afaff4884fd4053938823065c0a74f6dd
added-range: 9621+10418
added-sha256: 17ac3440935509ba29285f00c6d23a4893344d6a1a606d51712e9890b361789f
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
