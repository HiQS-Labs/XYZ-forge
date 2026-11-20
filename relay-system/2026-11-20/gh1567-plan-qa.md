# RELAY · GH-1567 plan QA: tick harness-config hint
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-20.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1567-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1567-TICK-HARNESS-HINT.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1567-TICK-HARNESS-HINT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-20
- Definition of Done: the plan in the artifact is Approved when it (a) fixes GH-1567's two "smallest first" items
  (scanner refusal message; `find-harness.sh --check` per-device config line) without touching the GH-1362 / GH-744 trust
  rule, (b) extends the existing subsystems only (no new writer, test, suite, registry entry; AGENTS.md "No new tests"),
  and (c) has acceptance checks that would reject the unfixed code.
- Operational envelope: local developer CLI/skill output text, Easy reversibility. Grade against the stated requirements,
  commensurate complexity and the repo's own threat model; do not ask for speculative machinery, new tests, or option 3
  (auto-write of config), which is an explicit non-goal. Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1567
- Source paths to read (at HEAD in your worktree): `skills/2-daily/merge-cleanup/scripts/scan_clones.py` (`_tick_binary`,
  `inspect_tick_claims`), `skills/1-hourly/relay-xyz/find-harness.sh` (the `check)` branch, `LIVE_HARNESS`, `_read_config`,
  `_canonical_clone`), `skills/1-hourly/relay-xyz/SKILL.md`, `test/find-harness.sh` (line ~205 consumes the
  `save this harness on this Mac:` line), `test/gh534_phase_a_tests.py`, `test/gh436-merge-cleanup.py`.

## Reviewer instructions (paraphrase-first, GH-1414)
BEFORE reading the source paths or the Definition of Done above, read only the artifact and write, as the first lines of
your review block: **What this proposes** (2-5 sentences), **How the existing system works, per this document** (2-5
sentences), and **What it's not** (short; ground each exclusion in the plan's sections, label inference). Then do the
source-backed technical validation, labelled as such. Then answer:
1. Are the claims about `scan_clones.py:323` and `find-harness.sh :424-431` true at HEAD? Is the vendored-branch fix site
   right (is `LIVE_HARNESS` set in the case that matters, e.g. vendored resolution with no XYZ_HARNESS)?
2. Does the plan keep the GH-1362 trust rule intact and avoid a second subsystem/writer?
3. For the unfixed code, what prevents it being reported as delivered, and where is the observed rejection (red control)?
   Do the stated acceptance checks observe the artifact that proves the outcome?
4. Does any existing test, doc or consumer pin the old strings or the exact `--check` output (e.g. parsing the
   `save this harness` line, or `--check` output expectations in a copied-skill / vendored fixture)?
5. Anything missing, over- or under-engineered? Cite file:line.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
