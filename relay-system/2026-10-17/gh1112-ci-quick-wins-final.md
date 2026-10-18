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

Grade each [Blocker]/[Should]/[Nit]/[Pass] with Observed input / Affected scope / Falsifier on any requested change. Do not request new tests. End with STATUS: Approved if the Definition of Done holds.


<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
