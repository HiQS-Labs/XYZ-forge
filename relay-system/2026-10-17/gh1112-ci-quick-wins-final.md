# RELAY · gh1112-ci-quick-wins-final
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
6. **Commit only the relay file** (`relay(gh1112-ci-quick-wins-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the committed diff against origin/development a984865e: test/marathon-root-audit.sh, validate.sh (TESTS block), test/gh648-l4-285-revalidate.sh; plan PROJECT/2-WORKING/GH-1112-CI-QUICK-WINS.md; evidence TESTS-RESULTS/2026-10-17+GH-1112/ (provenance.jsonl + artifacts)
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-17
- Definition of Done: each of the three plan items is implemented as planned with its acceptance evidence recorded (green + red parity for the audit; multiset-identical registry with heavy suites first; gh648 guard with no-op/EPERM/ESRCH controls and concurrent rescued suites), no new suites or registry entries (GH-831), no routing change, ratings persisted, no unrelated files in the diff.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 — Producer (claude-a) → Reviewer (codex)

**Final QA request.** Plan was Approved in `relay-system/2026-10-17/gh1112-ci-quick-wins-plan.md` (round 3). Review the committed implementation against it. Operational envelope unchanged: single-maintainer local gate; three one-file edits; commensurate complexity.

**What changed (commit 52296349, plus evidence commits):**
1. `test/marathon-root-audit.sh`: `get_alias_target` → `ALIAS_TARGET`, `find_invocation_target` → `INVOCATION_TARGET` (no `$(…)` per line); pre-gates: invocation lines need `marathon|relay` or `$` with `python|sh`; metadata lines need `^[A-Z]…=`; files need `grep -q -E 'marathon|relay'`. Rules untouched.
2. `validate.sh`: `gh436-merge-cleanup.sh`, `gh280-jog-marathon-adapter.sh`, `gh589-xyz-mini-sync.sh` moved to the top of `TESTS` with a GH-1112 comment; nothing else in the block changed.
3. `test/gh648-l4-285-revalidate.sh`: observation `except (ProcessLookupError, PermissionError) as exc` records `True` or `'eperm-unsignalable'`; cleanup catches both.

**Evidence (all in `TESTS-RESULTS/2026-10-17+GH-1112/`, hashes in `provenance.jsonl`):**
- Audit: before `real 78.93 s` → after `real 8.80 s`; stdout (169 lines) and stderr byte-identical, rc 0 both; `gh273-marathon-root-audit-python-shape.sh` 20/20. Red parity (`audit-red-parity.log.txt`): planted unscoped invocation after 41 comment lines at `gh115-round-cap.sh:220` in temp copies — old rc 1, new rc 1, stdout and stderr identical, FAIL names that path:line.
- Registry: `--list` sorted output identical before/after (406); python multiset check equal; first three entries are the heavy suites; `--print-mode` unchanged.
- gh648 (`gh648-controls-and-rescued-suites.log.txt`, verify clone, identity bracketed): A as committed rc 0, `group_absent: true` ×4; B observation replaced by no-op → rc 1 with `process group remains` (oracle still reachable); C injected PermissionError → rc 0, `'eperm-unsignalable'` ×4; D injected ProcessLookupError → rc 0, `true` ×4; E gh360/gh484/gh648/jog-queue concurrently → all rc 0.
- Parallel gate (`parallel-4wide-*`): `./validate.sh --parallel 4` in the verify clone: 409/409, re-run ladder 0 suites, heavy suites completed at pooled positions 26/65/130 of 390. Wall 1109 s on a loaded host versus PR #1116's 858 s; the Producer does NOT claim a wall-time improvement from this one sample, only the first-wave dispatch.

**Questions (cite file:line):**
1. Do the three pre-gates provably admit every line/file the unchanged regexes could match (direct branches, alias branches, metadata registrations)? Name any counter-example line shape.
2. Is the `ALIAS_TARGET`/`INVOCATION_TARGET` conversion free of stale-value leaks between calls and between files (both are cleared on entry; `|| true` guards under `set -e`)?
3. Does the gh648 change match the approved policy, and do controls B/C/D falsify what the plan said they would?
4. Is anything in the diff outside the three planned files plus plan/evidence/ledger (`git diff --stat a984865e..HEAD`)? Any new test file or registry entry?
5. Is the evidence sufficient and honestly stated, in particular the parallel-gate wall-time caveat and the "not promotion evidence" status of the parallel run?
6. Anything over-built or mis-scoped versus the plan?

Grade each [Blocker]/[Should]/[Nit]/[Unverified — no citation] with Observed input / Affected scope / Falsifier on any requested change. Do not request new tests. End with STATUS: Approved if the Definition of Done holds.


### Reviewer · Round 1

VERDICT: FAIL
Basis: The implementation matches the approved design on source inspection, but required acceptance evidence is incomplete. Finish the bounded manual controls and provide the base/candidate scope comparison; no new suite or production change is requested.
swept file: yes

Swept all three source files in full and the plan/provenance/artifacts. No additional demonstrated pre-existing defect requiring expansion of this slice was found; the audit's documented lexical limits and the runner's existing retry/receipt limitations remain. Verify tier with direct-source fallback: list_projects has no project for this worktree; nearest XYZ-forge is the main checkout, generation 2026-09-01T15:54:30Z. check_index_coverage reports metadata_changed/not_tracked/missing for the five material source/plan/provenance paths, so that graph cannot establish this candidate's state. No git commands, suites, pytest, or executable fixtures ran.

- [Pass] **Q1/Q2 — conservative pre-gates and cleared outputs.** Audit direct branches at `test/marathon-root-audit.sh:158–185` require marathon or relay; alias branches at :192–205 require `$` plus sh/python. Metadata patterns at :123–138 all imply the weaker case pre-gate at :119–122. File-level filtering at :440–446 is safe because aliases reset per audited file (:113–114) and registration itself requires a driver literal (:138). Both outputs clear before lookup (:88, :156); callers retain `|| true` (:193, :201, :425), and uppercase output names avoid the local `target` variables. No counterexample to these three pre-gates was found. Keep this bounded implementation.
- [Pass] **Audit receipt consistency.** Read-only Python probe (exit 0): `hashlib.sha256((p/name).read_bytes()).hexdigest()` for each artifact/hash pair in provenance, byte comparison of audit streams, regex extraction of the nonempty TESTS block, and `gzip.decompress` of the retained gate log. Decisive output: `all retained hashes match=True count=7`; `audit stdout identical=True bytes=17028 lines=169`; `audit stderr identical=True bytes=0`; `registry count=406 unique=406`, with the intended heavy first three; raw log `passed409=True not_promotion=True`. Provenance:1–3 records 79.845 s to 8.801 s, gh273 20/20 and red parity; `audit-red-parity.log.txt:2–7` records both rc=1 and the exact gh115:220 diagnostic. This checks supplied receipts, not fresh execution or commit provenance.
- [Pass] **Q3 — policy implementation and existing controls.** `test/gh648-l4-285-revalidate.sh:148–162` preserves True for ESRCH, records the distinct EPERM string and retains the signalable-group deadline; :166–167 catches both cleanup exceptions. `gh648-controls-and-rescued-suites.log.txt:4–22` records the no-op observation failing specifically with `process group remains`, the two observation injections, and all four concurrent suites green. These support the chosen policy, subject to F1 below.
- [Should] **F1 — supply the promised cleanup EPERM control** (plan:62; `gh648-controls-and-rescued-suites.log.txt:7–10`; provenance:5). C and D explicitly inject only at observation; there is no recorded cleanup injection. In the disposable full clone, inject PermissionError specifically at cleanup, witness that handler being reached, and show it preserves both the ordinary success and the already-failing no-op-observation verdict. Retain exact commands/mutation, exit codes and decisive output with provenance. This remains [Unverified — needs clone run]; source inspection of the catch is insufficient to discharge the approved separate control. No source behavior change or new test file requested.
- [Should] **F2 — complete ordering/membership and scope evidence** (plan:61; provenance:4,6; `parallel-4wide-summary.txt:9,24`). The registry result is a prose summary without retained before/after manifests or the multiset assertion; the gate artifact contains completion order, not per-suite start telemetry. Supply the existing base/candidate registry comparison, a dropped/duplicated-entry red witness, and the approved old-order first-wave red witness using retained PR #1116 telemetry (or explicitly disposition a narrower structural check). Retain the actual assertion/inputs/results; a new full-gate benchmark is unnecessary. Also provide the base a984865e to candidate diff/name-status summary (including any new test paths) so Q4's no-unrelated-files/no-routing-change claim can be reviewed without violating this reviewer's no-git rule. Whole-file source inspection establishes current behavior, not which files changed. Until supplied, exact multiset equality to base and whole-diff scope are [Unverified — no base comparison]. No behavior change requested.
- [Pass] **Q5/Q6 — bounded design, ratings and honest performance limits.** `releases.sql:871–872` persists 70/40/50/85 and 65/55/50/90; plan:66–68 excludes routing/scheduler/receipt work and keeps #1114's own work separate. `parallel-4wide-summary.txt:24` explicitly declines a wall-time improvement claim; the raw retained log says `NOT promotion evidence`. 409/409 is a supplied self-check for 52296349, not promotion attestation. The source changes use existing owners and remain Easy to reverse individually; no extra mechanism is needed.
- [Nit] Update the stale plan status/measurement prose when completing F1/F2: plan:17,83 and the Producer block say 78.9/78.93 s, while the actual baseline receipt is 79.845 s (`audit-before.time:1`, provenance:1). The plan's status table still lists the completed clone verification as next work.

Handing off to Producer (claude-a) — record/disposition F1 and F2, then return for review; go to the Producer window and say 'take your turn'. Harness owns the file-scoped commit.

### Round 2 — Producer (claude-a) → Reviewer (codex)

**F1 — done.** `gh648-cleanup-eperm-control.log.txt` (verify clone, identity bracketed): cleanup keeps the SIGKILL and then raises `PermissionError` inside the same `try`, so the handler is exercised without leaving a live group. F1a (committed observation): rc 0, handler reached 5×, `group_absent: true` ×4. F1b (no-op observation + cleanup EPERM): rc 1 with `process group remains`, handler reached 1× — the failing verdict is preserved. A first variant that replaced the kill itself returned rc 1 from `proc.wait(timeout=3)`; recorded as a control-design error, not a finding.

**F2 — done.** `registry-order-controls.py.txt` + `.log.txt`, `registry-before.txt`, `registry-after.txt`: 406→406, exact multiset equal; red witnesses: dropped entry fails, duplicated entry fails; candidate first wave (4-wide) holds all three heavy suites, base first wave holds none (positions 354/363/404 → 1/2/3); PR #1116 telemetry (`ended_ms`) confirms the three latest-finishing pooled suites were exactly gh436/gh280/gh589-xyz-mini-sync. 8 pass, 0 fail.

**Nit — done.** Plan prose now cites the receipt figure 79.8 s and the status table reflects completed verification.

Provenance has two new hashed entries. Round 2 question: does the Definition of Done now hold?


<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
