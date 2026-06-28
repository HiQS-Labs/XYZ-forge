# RELAY · QA: queue-plan.sh + PDDA complexity/risk/effort ratings system
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-06-28.
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
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(qa-queue-plan-sh-pdda-complexity-risk-effort-ratings-system): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review (read all; you may read any path in the repo):
  - `utils/queue-plan.sh` — the deterministic pre-pre-flight queue planner (PRIMARY).
  - `PROJECT/PDDA.md` → section **"Project ratings — complexity / risk / effort"** — the ratings contract.
  - `utils/pdda-check-ratings.sh` — the warn-level ratings check.
  - `test/queue-plan.sh` — the 28-assertion regression suite (judge coverage adequacy).
  - The ratings backfill — provisional `complexity`/`risk`/`effort` + `ratings_exempt` across `PROJECT/**` docs (e.g. `PROJECT/2-WORKING/GH-37-AGY-CONSULT-AUTH-HANG.md`, `GH-33-LOOP-SKILL-INTEGRATION.md`, `ADVERSARIAL-HARDENING.md`).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-06-28
- Definition of Done — grade the work against these; this is a QA of correctness AND of the ratings ("difficulty of implementation") system design:
  1. **Planner correctness.** Ledger parse; the validation signals (already-closed via `gh`, already-landed via `fix_probes` not artifact-existence, undocumented-partial ≥2-signal threshold, drift, unrated); the score `2·eff + 1·cx + 2·risk + 3·deps + zone_pen`; wave packing (write-set disjoint, ≤1 kernel lane/wave, deps push later); `--check` determinism; `gh` graceful degradation. Flag any logic bug, false-positive/negative, or non-determinism.
  2. **Ratings system soundness.** Is `complexity`/`risk`/`effort` on a `low|medium|high` scale a sound "difficulty of implementation" rubric? Are the three axes clearly distinct (not double-counting)? Is the default `quick-wins` weighting (and the `derisk-first` risk-sign flip) defensible, or gameable / mis-ordering? Is risk-as-reversibility the right meaning? Is the ≥2-signal partial threshold well-chosen?
  3. **Discipline.** Deterministic + flag-for-human only (never auto-resolves); reuses swarm-preflight contract/probe semantics rather than a second control plane; advisory check never blocks.
  4. **The provisional backfill values** — are the assigned ratings + exemptions reasonable, or obviously wrong anywhere?
- Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) each with a concrete fix, then a Verdict (Approved | Changes requested | Blocked). Review only — do not edit any file; append findings to this relay file.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
