# RELAY · GH-1580 final QA round 4 (F8 only)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 1

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
6. **Manual relay: commit only the relay file** (`relay(gh1580-final-qa-r4): <role> r<N>`); no push.
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
- Definition of Done: F8 is closed, and the plan's `## Acceptance` list in `PROJECT/2-WORKING/GH-1580-PREFLIGHT-MISREPORTS-GAPS.md` is satisfied by the committed change with substantiating evidence under `TESTS-RESULTS/2026-11-23+GH-1580/`. Nothing is deferred (preflight is a gate surface).

## Authority and history (read first)

This is **round 4**, the one extra round the operator authorized, limited to F8: GitHub comment https://github.com/HiQS-Labs/XYZ-forge/issues/1580#issuecomment-7114054883 ("Operator decision 2026-11-23": one extra repair + final-QA round, limited to F8, refresh the clone-identity evidence; if round 4 fails, #1580 parks). The prior thread is `relay-system/2026-11-23/gh1580-final-qa.md` (rounds 1-3, STATUS Escalated at its cap): F1-F4 and F5-F7 were repaired and you closed them in rounds 2 and 3; F8 was the only open finding. Read that thread's Round 3 Reviewer block and the Producer Round 3 handback for the finding and recipe.

## Review brief

**Step 0 - paraphrase first.** Before reading source, write **What this changes** and **How the existing system works** (2-5 sentences each) from the plan doc alone; then review source-backed.

**What changed since your round 3.** Commit 940d58499: `_gate_tokens`' fold pass now treats a command position as "after an operator, or after control-prefix words only" (`if`, `elif`, `while`, `until`, `!`, `time`, `then`, `do`, `{`), so `[[ a && b ]]` / `(( … ))` there is one skipped word; the commands after `]]` are still checked. New controls D2w (your exact failing shape, fixture form), D2x (a missing command inside the same if-block is still found), D2y (`if ! [[ a && b ]]`). Evidence regenerated: red at 5f51d28c8 (`outputs/prerepair-r3.txt`, 33/3: D2w D2x D2y red) and green at the new head (`outputs/green.txt`, 36/0); suites and the 129-contract replay re-run at the repaired head in a fresh disposable full clone with a complete identity bracket (HEAD, origin, core.bare, local user.name/user.email, clean tree; before and after, unchanged) in `outputs/existing-suites.txt`.

**Operational envelope.** Local developer CLI/harness code. Grade against the requirements, commensurate complexity and this repo's rules: no new tests/suites/gates (GH-831), Python authoritative and the Bash twin FROZEN (GH-308), `githooks/` untouched. Challenge over-building; prefer conservative skips over more shell machinery.

**Read:** the seeded diff `.relay-artifacts/gh1580-final.diff`, then `utils/py/swarm_preflight.py` (`_gate_tokens` fold pass, `_gate_program_gap`, `gate_command_gap`, `eval_probes`, `acceptance_gaps`, evaluate_candidate wiring), the plan doc, `TESTS-RESULTS/2026-11-23+GH-1580/{manual-check.md,controls.sh,provenance.jsonl,outputs/*}`. Measure with narrow read-only probes under `.relay-scratch/`; do not run suites.

**Questions (cite file:line):**
1. Is F8 closed for your exact input and its positive/negative controls (`true && if [[ -f validate.sh && -f ROUTER.md ]]; then bash -n validate.sh; fi` no gap; `... then gh1580_absent_command; fi` reports the missing command)? Do F1-F7 controls stay green?
2. Any new false NOT-READY or false no-gap introduced by the changed fold pass (e.g. `[[` as an argument, nested `if`, `elif`, `while`/`until`, `{ [[ … ]]; }`)? Give the exact input and observed output; do not assert general shell correctness.
3. Does the evidence substantiate the claims (provenance hashes non-empty and matching, MATCH/MISMATCH counts, source hash vs green.txt, the complete identity bracket, the 129-contract replay)? Anything claimed but unverified? The full `validate.sh` gate is intentionally not run at this stage (it runs once at push via the pre-push hook, GH-1518); say so rather than treating it as a defect.
4. Acceptance 1-5 of the plan: satisfied? Any finding must carry `Observed input:`, `Affected scope:`, `Falsifier:` if it asks for a behaviour change.

Include `swept file: yes|no`, a VERDICT (PASS/FAIL/PARKED) with Basis, and set STATUS Approved only if ready to ship.
## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
