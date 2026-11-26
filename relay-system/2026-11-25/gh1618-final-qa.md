# RELAY · GH-1618 final QA: correct the 'ungated' claim in the GH-1606 documents
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
6. **Manual relay: commit only the relay file** (`relay(gh1618-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1618-UNGATED-CLAIM-CORRECTION.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1618-UNGATED-CLAIM-CORRECTION.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-25
- Definition of Done: the two merged GH-1606 documents no longer assert that the phase B/C suite is ungated or that no gated suite enters the B1 reserve path; each keeps what was measured (standalone red at `b479f74e0`: 39 tests, 14 failures, 1 error, cause GH-1576) and only the wrong inference is superseded (struck through, with a dated 2026-11-25 correction note pointing to Issue #1615 / PR #1617 / Issue #1618); every factual statement in the notes is supported by the retained evidence and not broader than it; `provenance.jsonl` of GH-1606 is byte-identical; nothing but documentation text changed.

### Operational envelope and non-goals
- Documentation-only correction in the XYZ-forge repo. Grade against the plan's stated requirements and commensurate complexity; the repo's own threat model governs. Challenge bloat; do not manufacture scope. The plan (`PROJECT/2-WORKING/GH-1618-UNGATED-CLAIM-CORRECTION.md`) was approved by plan QA round 2 (`relay-system/2026-11-25/gh1618-plan-qa.md`).
- XYZ-forge forbids new tests (`AGENTS.md` *No new tests*, GH-831): a new `test/` suite, `validate.sh` entry or gate machinery in the diff is a finding. `TESTS-RESULTS/2026-11-25+GH-1618/probe_gate_reserve.py` is a manual evidence driver with `provenance.jsonl`, not a suite. Operator constraints: no code/test/gate change; `provenance.jsonl` row `FINDING-phaseB-pre-existing` unchanged; no absolute home paths in anything written. Smoke: documentation-only change with no instruction or consumer path altered, so the acceptance rows AC-1..AC-4 are the check (smoke skipped for that reason).

### What to read
- The diff against the base: `git` is not available to you, so read the two edited files in full (`PROJECT/3-COMPLETED/GH-1606-MERGE-CLEANUP-PUSH-ENVFAULT.md`, `TESTS-RESULTS/2026-11-25+GH-1606/SUMMARY.md`), the untouched `TESTS-RESULTS/2026-11-25+GH-1606/provenance.jsonl`, the plan, and `TESTS-RESULTS/2026-11-25+GH-1618/` (SUMMARY.md, provenance.jsonl, probe script). The original wording of the changed lines is in the plan's Observed table (doc lines 30, 47, 131-134, 180, 214, 240; SUMMARY line 38). Ground the claims in `test/gh436-merge-cleanup.py` (lines 36-45, 1382-1384), `validate.sh:96`, `test/gh534_phase_b_tests.py`, `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (about 2160-2215).

### Questions (answer each; cite `file:line`)
1. **Issue satisfied.** For each required change (strike the wrong inference, keep the measurement, dated note pointing to #1615/#1617, SUMMARY note supersedes the receipt's "ungated", receipt untouched), where in the files is it, and is anything missing? What prevents an unchanged, uncorrected candidate from being reported as delivered, and where is the observed rejection (the plan's AC-1 red control; `provenance.jsonl` rows AC-1..AC-4)?
2. **No overclaim.** Is every statement in the two correction notes true and no broader than the evidence (gate runs phase B/C through gh436 with the stub; one healthy-path test reached `attempt_record.reserve`; no direct test reference to the toolchain-fault helper and gated fault-ordering coverage not established; the gate at the GH-1606 base not re-run, with BASE-DIFF as the bridging evidence)? Is BASE-DIFF's inference sound (only the 8-line fixture stub differs)?
3. **No history rewrite.** Are the original sentences preserved (struck through) and the true standalone facts kept? Is any remaining unqualified false claim left in either file (grep for the same claim in other wording)? Does the "Nothing in this issue's conclusions depends on the wrong inference" sentence hold?
4. **Scope and governance.** Only documentation, evidence, plan, ledger pickup files and relay threads changed; no new test/suite/gate; the doc stays in `PROJECT/3-COMPLETED/` with valid front matter and status table; no `/Users/` path introduced (the one pre-existing mention in the GH-1606 SUMMARY is unchanged text).
5. **Rating and plan fidelity.** Does the implementation match the approved plan, and is the persisted rating `15/10/40/90` consistent with the evidence (operator-supplied appeal 40)?

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) with a concrete fix and `file:line`, the required `swept file: yes|no` line, then `VERDICT:` and `Basis:`. Use bold labels, never markdown heading lines, inside your block (a heading line truncates what the driver counts). Behaviour-change findings need `Observed input:` / `Affected scope:` / `Falsifier:`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
