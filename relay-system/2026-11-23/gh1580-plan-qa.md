# RELAY · GH-1580 plan QA (swarm_preflight misreports)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
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
     A `[Blocker]` must cite an observed failure.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1580-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/1-INBOX/GH-1580-PREFLIGHT-MISREPORTS-GAPS.md (the PLAN; nothing is implemented yet)
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-23
- Definition of Done: the plan's `## Acceptance` list is satisfiable by the planned change, and the plan is grounded, surgical and falsifiable.

## Review brief (read this before the log)

**Step 0 — paraphrase first (GH-1414).** BEFORE reading any source file or the requirements below, read ONLY the plan doc and write, as the first thing in your block: **What this proposes** (2-5 sentences), **How the existing system works, per this document** (2-5 sentences), and a short **What it's not** where a consequential expectation could be mistaken. Label inference vs. stated. Then continue with the technical review and label that part source-backed.

**Requirements.** GitHub issue HiQS-Labs/XYZ-forge#1580 (its text is quoted in the plan's "Observed problem"). Three correctness defects in `utils/py/swarm_preflight.py`: (1) probe patterns must honour `^`/`$` per line (or reject anchors loudly); (2) every command in a gate must be existence-checked, not just the first; (3) a missing acceptance section must be reported as a gap, not a silent pass. Findings 4-6 of #1580 are follow-ups and out of scope. Preflight is a gate surface, so a finding on it is never deferred.

**Operational envelope.** Local developer CLI/harness code, one Python file plus one doc sentence. Grade against these requirements, commensurate complexity, and this repo's rules: no new tests/suites/gates (GH-831 / AGENTS.md "No new tests"; verification is existing suites + a manual red/green check under TESTS-RESULTS with provenance.jsonl), Python is authoritative and the Bash twin `utils/swarm-preflight.sh` is FROZEN (GH-308), do not touch `githooks/`. Challenge over-building; do not ask for a shell parser or new subsystems.

**Source to read (read-only, measure with narrow probes under `.relay-scratch/`; do not run test suites):**
- `utils/py/swarm_preflight.py`: `eval_probes` (~250-292), `check_acceptance_fidelity` (~928), `evaluate_candidate` gate block (~1785-1814) and acceptance block (~1703-1762), `report_candidate` (~1941-1958), `normalize` readiness (~396-416), `collect_inline_checklist` (~783).
- `utils/py/marathon_drive.py` ~2042-2082 (its own pre-advance gate check, not changed) and ~2636-2700 (`acceptance_probes_unmet` also calls `eval_probes`).
- `test/gh557-unknown-blocks-manifest.sh` (case 2 pins non-manifest `no-issue-section` => ready exit 0), `test/gh308-swarm-gate-path.sh`, `test/gh343-gate-program-target-root.sh`, `test/swarm-preflight.sh`.
- Red evidence: `TESTS-RESULTS/2026-11-23+GH-1580/controls.sh` and `outputs/red.txt` (replay against origin/development 81eefac61).

**Questions (answer each, cite file:line):**
1. Are the plan's claims about the current code accurate (anchors, first-token gate check, `unknown [no-issue-section]` verdict staying ready)? Any claim not grounded in the actual paths?
2. Anchors: is `re.search(pattern, text, re.M)` in `eval_probes` the right and sufficient fix? Any in-repo contract or consumer (marathon `acceptance_probes_unmet`, jog) whose behaviour would silently change for the worse? Give a concrete pattern if so.
3. Gate: does the planned per-command existence check avoid false NOT-READY on real gate shapes in this repo (`&&` chains, `cd`, env prefix, `env VAR=1 prog`, pipes, `${VAR:?}` program words, `bash -c '...'`, quoted newlines)? What realistic gate shape would it get wrong, and is the plan's skip list adequate or over-built?
4. Acceptance gap: is "gap line + `readiness.acceptance_gaps` JSON key, exit code unchanged" a faithful reading of #1580 point 3 ("report a gap instead of passing silently, or accept synonyms") given GH-557's pinned advisory behaviour? Is rejecting synonym-heading acceptance and non-blocking the right call? Does adding a JSON key risk any golden/consumer (test/gh291-contract-goldens.sh, jog, marathon-plan)?
5. For each of the three defects: what prevents an unchanged, unfixed candidate from being reported as delivered, and where is the observed rejection? (Plan-time: name the intended rejection and the control in `controls.sh`; is each control able to fail on the pre-change code? Check red.txt.)
6. Is the plan surgical and DRY (extends the existing evaluator and report path, no new subsystem, no new test file or registry entry)? Anything missing, over-engineered, or mis-scoped? Anything that should be in scope because preflight is a gate surface?

Every `[Blocker]`/`[Should]` that asks for a behaviour change needs `Observed input:`, `Affected scope:`, `Falsifier:`. Include `swept file: yes|no`, a VERDICT (PASS/FAIL/PARKED) with Basis, and set STATUS Approved only if the plan is ready to build.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
