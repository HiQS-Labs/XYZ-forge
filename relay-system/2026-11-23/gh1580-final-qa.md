# RELAY · GH-1580 final QA (swarm_preflight misreports)
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
6. **Manual relay: commit only the relay file** (`relay(gh1580-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh1580-final.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/d67c8fc2-b01d-447c-9384-355c25b46faa/scratchpad/gh1580-final.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-23
- Definition of Done: the plan's `## Acceptance` list in `PROJECT/2-WORKING/GH-1580-PREFLIGHT-MISREPORTS-GAPS.md` is satisfied by the committed change, the evidence under `TESTS-RESULTS/2026-11-23+GH-1580/` substantiates it, and no finding is deferred (preflight is a gate surface).

## Review brief (read before the log)

**Step 0 — paraphrase first.** Before reading source, write **What this changes** and **How the existing system works** (2-5 sentences each) from the plan doc alone; then review source-backed.

**What was built (committed, HEAD of this branch).** Issue HiQS-Labs/XYZ-forge#1580, three correctness defects in `utils/py/swarm_preflight.py`: (1) `eval_probes` matches grep probes with `re.M`; (2) `gate_command_gap` (plus `_gate_tokens`, `_gate_program_gap`) replaces the first-token-only gate check, with cwd-aware literal `cd` tracking; (3) `acceptance_gaps` adds a `gap` line and `readiness.acceptance_gaps`, advisory only. Also: one sentence in `relay-automation/CONTRACT.example.md`; the existing `test/gh343-gate-program-target-root.sh` mutation literal follows the extracted helper. Findings 4-6 of #1580 are intentionally out of scope. The plan was Approved by Codex plan QA in round 3 (`relay-system/2026-11-23/gh1580-plan-qa.md`).

**Operational envelope.** Local developer CLI/harness code. Grade against the requirements, commensurate complexity and this repo's rules: no new tests/suites/gates (GH-831; a new test file or registry entry in the diff is a finding), Python is authoritative and the Bash twin is FROZEN (GH-308), `githooks/` untouched. Challenge over-building.

**Read:** the diff `.relay-artifacts/gh1580-final.diff` (seeded read-only), then the real files: `utils/py/swarm_preflight.py` (`eval_probes`, `_gate_tokens`, `_gate_program_gap`, `gate_command_gap`, `acceptance_gaps`, the evaluate_candidate wiring, `normalize`, `report_candidate`), `test/gh343-gate-program-target-root.sh`, `test/gh557-unknown-blocks-manifest.sh`, the plan doc, and evidence `TESTS-RESULTS/2026-11-23+GH-1580/{manual-check.md,controls.sh,provenance.jsonl,outputs/*}`. Measure with narrow read-only probes under `.relay-scratch/`; do not run suites (they were run in a disposable clone: `outputs/existing-suites.txt`).

**Questions (cite file:line):**
1. Is each acceptance criterion in the plan satisfied? For each of the three defects: what prevents an unchanged, unfixed candidate from being reported as delivered, and where is the observed rejection (red.txt MISMATCH vs green.txt MATCH, mutant-unconditional-cd.txt)?
2. Do the actual code paths match the approved plan? Any divergence, duplicate subsystem or second writer? Is the rating (70/65/50/75, plan "Rating rationale") consistent with the evidence?
3. Correctness of `_gate_tokens` / `gate_command_gap` / `_gate_program_gap` on real gate shapes: find a concrete gate string that is falsely refused (NOT-READY) or that reads READY with a missing program/script, other than the documented skips (builtins, expansion words, `bash -c` body, indeterminate cwd). Give the exact input and the observed output.
4. `re.M` change: any consumer (marathon `acceptance_probes_unmet`, jog) or in-repo contract that gets worse? (`corpus-sweep.txt` shows no change over 129 contracts.)
5. `acceptance_gaps`: advisory only, exit codes unchanged (GH-557 case 2)? Anything that could newly block or break JSON consumers?
6. Do the checks substantiate the claims (provenance hashes, source commit, MATCH/MISMATCH logic)? Is anything claimed but unverified?
7. Anything missing that preflight being a gate surface requires, or over-engineered?

Every `[Blocker]`/`[Should]` asking for a behaviour change needs `Observed input:`, `Affected scope:`, `Falsifier:`. Include `swept file: yes|no`, a VERDICT (PASS/FAIL/PARKED) with Basis, and set STATUS Approved only if ready to ship.
## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
