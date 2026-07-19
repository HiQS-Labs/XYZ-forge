# RELAY · README repo-map QA (commit 0f699e1)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-19.
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
     (Approved | Changes requested | Blocked). Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(readme-qa): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: `README.md` (specifically the `## Repo map` section refreshed in commit
  `0f699e1`). You may read the whole tree freely (`skills/`, `utils/`, `relay-automation/hooks/`,
  `CHANGELOG.md`) to verify claims — but only append findings to THIS file; do not edit README.md.
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-19
- Definition of Done — every one of these must hold, cite `file:line` or a quoted span for each:
  1. **Targets exist.** Every path/link added to the repo map resolves on disk:
     `skills/marathon-triage/SKILL.md`, `skills/marathon-cleanup/SKILL.md`, `skills/10days/SKILL.md`,
     `skills/file-xyz-bug/`, `utils/marathon-plan.sh`, `utils/swe-diagram/`,
     `utils/git-bundle-snapshot.sh`, `relay-automation/hooks/gh177-sandbox-test-guard.sh`.
  2. **Descriptions match real behavior.** Each new entry's one-line description is accurate against
     the actual SKILL.md `description:` / script behavior — no overclaim, no wrong verb. Check in
     particular: `marathon-plan.sh` ranks the whole ROADMAP into collision-safe waves and `--deep`
     delegates to `swarm-preflight.sh --dry-run`; `10days` is the auto-fire exception; the
     `gh177-sandbox-test-guard.sh` hook blocks running the test suite under a *sandboxed* Bash call;
     `git-bundle-snapshot.sh` does rotated `git bundle --all` backups.
  3. **GH issue references are correct.** GH-240 = marathon skills, GH-201 = swe-diagram,
     GH-233 = wipe-prevention layer.
  4. **No stale/contradicted claims** were introduced, and nothing user-facing that landed since
     2026-07-17 is conspicuously still missing from the map (flag as `[Should]`/`[Nit]`, not a
     blocker, if so).
  5. Markdown is well-formed (list nesting, link syntax, no broken relative anchors).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
