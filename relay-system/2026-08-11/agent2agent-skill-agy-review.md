# RELAY · Agent2Agent Skill Agy Review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-11.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(agent2agent-skill-agy-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/agent2agent/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-08-11
- Definition of Done:
  1. A pasted invitation in the exact form `Join XYZ agent2agent #123456 as agent number two to discuss: "subject line here"` tells any supported agent how to join and respond immediately.
  2. The skill clearly supports agents one through N while preserving one serialized `NEXT:` writer and preventing simultaneous writes.
  3. Read-only join/status/read operations are clearly separated from state-changing create/write/close operations, with no direct relay-file editing.
  4. Commands discover the repository root safely, quote user-controlled values, and match the shipped helper interface.
  5. Instructions are concise, model-neutral, and unambiguous enough that Claude, Agy, Codex, or another agent will not stall or invoke the wrong workflow.
  6. Every finding cites `.relay-artifacts/SKILL.md` by line and proposes a concrete correction; the Reviewer does not edit the artifact.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Turn 1 — Reviewer (agy)

swept file: yes

- `[Blocker]` `.relay-artifacts/SKILL.md:22`, `41`, `61`, `74`: The pseudo-variable `<this-skill>` in the bash snippets will cause a syntax error (`bash: syntax error near unexpected token 'newline'`) because `<` acts as a file redirection operator.
  **Fix:** Replace `<this-skill>` with the literal path `skills/agent2agent` in all four script invocation blocks.
- `[Pass]` `.relay-artifacts/SKILL.md:30`: The pasted invitation format exactly matches the DoD requirement.
- `[Pass]` `.relay-artifacts/SKILL.md:38`: Read-only joins are explicitly separated from state-changing operations ("Resolve and validate the existing discussion read-only first:").
- `[Pass]` `.relay-artifacts/SKILL.md:83`: The file editing constraint is clearly enforced ("Never edit the discussion directly").

**Verdict:** Changes requested.

handing off to claude-a — go to the claude-a window and say 'take your turn'

### Turn 2 — Producer (claude-a)

- `[Blocker]` **Modified:** Removed all four shell-significant `<this-skill>` placeholders. Each
  command now invokes the executable helper through a quoted
  `$(git rev-parse --show-toplevel)/skills/agent2agent/scripts/agent2agent.py` path. This preserves
  Agy's concrete fix while also making the examples independent of the caller's current path spelling
  and safe when the clone path contains spaces.
- Added an explicit instruction that commands run from the intended XYZ clone and resolve the helper
  from that clone's Git root.
- Validation: `bash test/agent2agent.sh` and the skill validator must pass before final disposition.

handing off to agy — the blocker is addressed; review the complete revised skill and issue the final verdict

### Turn 3 — Reviewer (agy)

swept file: yes

- `[Pass]` `.relay-artifacts/SKILL.md:24`, `43`, `63`, `76`: The `<this-skill>` placeholders were successfully replaced with safely quoted `"$(git rev-parse --show-toplevel)/skills/agent2agent/scripts/agent2agent.py"` command paths.
- `[Pass]` `.relay-artifacts/SKILL.md:15-16`: The explicit instruction that commands run from the intended XYZ clone was added successfully.
- I found no other pre-existing defects in the file.

**Verdict:** Approved

relay closed (Approved), no further turn needed

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
