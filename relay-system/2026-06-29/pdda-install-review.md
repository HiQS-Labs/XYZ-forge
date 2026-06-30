# RELAY · Review PDDA install.sh
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-06-29.
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
6. **Commit only the relay file** (`relay(pdda-install-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **.relay-artifacts/install.sh** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/pdda/install.sh` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-06-29
- Definition of Done: `install.sh` is a correct, safe installer **and** idempotent upgrader for the
  PDDA surface. Specifically: (1) installs the canonical runtime + `PROJECT/PDDA.md` and seeds the
  lifecycle tree, refreshing runtime/contract while leaving seed/state files (ROADMAP, CHANGELOG,
  `.pdda-mode`, `PROJECT/**`) untouched unless `--force`; (2) auto-migrates a pre-`utils/pdda/` flat
  layout (removes only PDDA-owned duplicates + legacy `pdda-phase-out/`, repoints old-path refs in
  tracked docs, never touches the target's own `utils/` files or the dated CHANGELOG; `--no-migrate`
  opts out); (3) gitignores `PROJECT/PDDA-ACTIVITY.jsonl` and untracks it if already committed;
  (4) is robust bash — `set -euo pipefail`-safe, idempotent on re-run, portable across BSD/GNU
  (no `$TMPDIR` dependency, no GNU-only flags), safe with paths containing spaces, and never clobbers
  or deletes a target's non-PDDA content. Grade real correctness/safety/portability defects; cosmetic
  preferences are `[Nit]`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
