# RELAY · GH-836 D1 plan review — gh436 to Large, inputs routed full
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-26.
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
6. **Commit only the relay file** (`relay(gh836-d1-plan-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh836-d1-plan.md** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/0cc9b6f4-22bd-4606-b4ec-21e1b8f38591/scratchpad/gh836-d1-plan.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-26
- Definition of Done: **Approved** when all of these hold:
  - (a) the recon claims in "D1 — `gh436` to Large" match the cited files and lines;
  - (b) after the change, every landing that changes something `gh436` reads still runs `gh436` at its hosted
    reconcile. That covers merge-cleanup code, merge-cleanup's `SKILL.md` and `WORKTREE-SAFETY.md`, and any other
    input the recon missed;
  - (c) the change extends the existing router (`utils/ci-route.sh`) and edits only existing assertions in
    `test/ci-route.sh`. There is no new suite, registry entry or gate machinery;
  - (d) the red/green witnesses are falsifiable, and old Small receipts stay valid;
  - (e) the scope is D1 only: D3, `gh436` itself and D2 are untouched.

## Review packet

**What this is.** The operator decided D1 of #836 on 2026-09-26: move `gh436-merge-cleanup.sh` from the Small
tier to Large "if relatively safe". The plan is the "D1 — `gh436` to Large" section of
`.relay-artifacts/gh836-d1-plan.md`, a copy of `PROJECT/2-WORKING/GH-836-GATE-HOTSPOTS.md`. Its compensating
control routes `gh436`'s two docs inputs to the full gate.

**Operational envelope.** A single-repo local developer harness. The operator has ruled "no new tests". Grade the
plan for safety of coverage and for commensurate complexity.

**Read:**
- the artifact's D1 section;
- `utils/ci-route.sh`: 30-72 (Small list, `is_docs_surface`), 305-350 (`full_required`), 460-480 (tier
  resolution);
- `test/ci-route.sh`: 1-40, 150-170, 236-245;
- the `gh436` inputs: `test/gh436-merge-cleanup.py` 855-869, and `test/gh534_phase_a_tests.py`,
  `test/gh534_phase_b_tests.py` and `test/gh534_phase_c_tests.py` (search `REPO /`, `read_text`, `open(`);
- `utils/py/wave_reconcile.py` 589-614 and 540-560.

You may probe routing with `printf '%s\n' <paths> | bash utils/ci-route.sh push`. Do not run suites.

**Questions** (cite `file:line`):
1. **Coverage.** Does `gh436` read any file, besides the two named, that routes as docs (tier 1)? Examples: another
   doc, a fixture under `test/`, a file under `skills/*/merge-cleanup/` that `is_docs_surface` counts as docs.
2. **The route.** Is adding the two paths to `full_required` the least machinery? Does the pattern
   `skills/*/merge-cleanup/SKILL.md` match the real path? Does anything else consume `full_required` or
   `route=full` in a way this changes (CI job shape in `.github/workflows/ci.yml`)?
3. **Witnesses.** Do V1's red controls fail for the right reason? Does anything else pin the Small list or count
   (`gh306`, `gh35`, `wave_reconcile`)?
4. **Scope.** Anything over-built or missing?

Write findings in the Log per the turn rules. Set `STATUS: Approved` only if the Definition of Done is met.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
