# RELAY · GH-268 installers branch QA (governance adjudication)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-22.
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
6. **Commit only the relay file** (`relay(gh-268-installers-branch-qa-governance-adjudication): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **.relay-artifacts/gh268-branch-review-artifact.md** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/7c523f9d-cb85-4799-8499-ebdeb6e9fb95/scratchpad/gh268-branch-review-artifact.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-22
- Definition of Done: **Adjudicate the branch `marathon/gh-268-installers-2026-07-22` (14 commits vs
  `development`, full diff + commit log embedded in the artifact) against this repo's own governance
  docs — not general code-quality taste.** Before grading, read all three in full:
  - `GUIDING-PRINCIPLES.md` (repo root)
  - `AGENTS.md` (repo root) — this repo's canonical agent behavior/decision-quality/proof rules
  - `PROJECT/PDDA.md` — the PDDA (Plan-Driven Development Agent) lifecycle framework this repo runs on

  What happened on this branch (context, not a claim to take on faith — verify against the diff): a
  GH-268 Phase 1 remediation item ("every skill ships an install.sh") was built via an operator-directed
  marathon trial — first an aider+qwen3.8-max builder (partially successful, 2/9 files, logged in two
  now-closed GH issues #279/#280 for its reliability problems), then completed via codex-builder +
  agy-reviewer for the remaining 7 (0 failures). A separate unrelated stash (`RELEASES.md` +
  `GH-272.md`) was folded in as its own commit, and install.sh modes were normalized to 755 in another.

  Grade against these dimensions, citing `file:line` (diff) or doc:line (governance doc) for every
  finding per the citation rule above:
  1. **PDDA compliance** — is this branch's work traceable to a real GH issue/capture doc (GH-268 in
     `PROJECT/2-WORKING/`)? Is the Issue-first SOP honored? Does the PDDA ledger/checklist update
     (the Phase 1 checkbox commit) meet PDDA's own documentation standards?
  2. **Guiding Principles adherence** — commit hygiene (one purpose per commit — is that honored across
     the 14?), blast-radius discipline (was risky work properly isolated — throwaway branch, no push,
     worktree-isolated builder turns), and any principle a commit or the overall approach violates.
  3. **AGENTS.md decision-quality/proof rules** — are claims in commit messages and the doc-update
     commit backed by actual evidence (e.g. does "functionally verified" claim match what's
     demonstrable from the diff), not asserted without proof.
  4. **Installer correctness itself** — spot-check that the 9 `skills/*/install.sh` files are
     structurally sound (shebang, idempotency, symlink safety) independent of process — a governance
     pass that ignores whether the actual deliverable works would be incomplete.

  A `[Pass]` on any dimension needs a citation exactly like a `[Blocker]` does — "looks fine" is not
  a grade. If a dimension doesn't apply or can't be assessed from the artifact alone, say so explicitly
  rather than silently omitting it.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
