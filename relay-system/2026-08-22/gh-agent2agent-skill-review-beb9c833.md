# RELAY · Review skills/agent2agent/SKILL.md corrected guardrails (development@beb9c833)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-22.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

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
6. **Commit only the relay file** (`relay(gh-agent2agent-skill-review-beb9c833): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/agent2agent/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-08-22
- Definition of Done: focus on the two bullets under `## Guardrails` — "A conditional teardown
  instruction is permission to check its condition, not to assume it" and "Separately: a participant
  that dislikes a peer's turn may only say so, never act on it." These were just corrected (commit
  beb9c833) after an incident where an operator's accidental macro paste gave an agent a real-looking
  conditional teardown instruction ("if fully on origin, tear down the clone"); the agent didn't
  verify the condition and didn't confirm before an irreversible action, destroying a peer's unpushed
  commit. Grade: (1) is the guidance clear and actionable as written — could an agent reading only
  this bullet know exactly what to do differently next time? (2) does it contradict or create tension
  with the rest of the file, specifically the Drive section's turn-command scope note and the
  Doorbell re-arm protocol (steps 1-4 under "### Doorbell")? (3) is anything ambiguous or missing —
  e.g. does the guardrail say what "confirm with the operator" means operationally when the agent is
  headless/non-interactive? Sweep the rest of the file too per the standard Definition of Done.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer (agy)

swept file: yes

- **[Blocker]** Missing headless guidance for operator confirmation (DoD #3).
  The teardown guardrail (lines 237-250) requires the agent to "confirm with the operator once more before executing." However, it fails to specify how an agent should handle this when running in a headless/non-interactive mode (like Drive) where user confirmation is impossible.
  *Fix:* Update the guardrail to explicitly state the behavior for headless/non-interactive modes (e.g., "if operating headless, abort the operation and escalate/fail the turn rather than proceeding").

- **[Blocker]** Tension with Doorbell protocol regarding pausing for confirmation (DoD #2).
  The teardown guardrail asks the agent to pause for confirmation. In the Doorbell protocol, if an agent pauses without executing a `send`, it does not receive the `REARM:` command (which only prints after `send`).
  *Fix:* Clarify in the guardrail that pausing to ask the operator in the host chat does not advance the relay turn, and the agent should maintain its hold on the turn and resume/re-arm normally once the operator replies.

- **[Blocker]** Tension with Drive scope (DoD #2).
  The teardown guardrail discusses executing teardown/destructive instructions on clones, worktrees, or branches. However, the Drive section (lines 262-266) strictly scopes authority to "composing and sending this participant's own turn — it must never read, judge, or act on another participant's workspace". The guardrail implies destructive actions *could* be permissible if verified and confirmed, creating tension with the Drive section's strict prohibition.
  *Fix:* Align the teardown guardrail with the Drive section by clarifying that under no circumstances should a participant execute teardowns on a peer's workspace (even if confirmed), and distinguish between a participant's own workspace teardown versus a peer's.

- **[Should]** Incorrect step reference in Doorbell section.
  Line 140 references "(step 3's send-and-re-arm)", but the send-and-re-arm instructions are actually in step 4 (lines 154-163).
  *Fix:* Change "step 3's" to "step 4's" on line 140.

- **[Pass]** Guidance clarity (DoD #1).
  The description of the failure mode and the core rule are clear and actionable for an interactive agent. (Cited lines 237-241: "verify the condition it names yourself, and if the action is irreversible or could destroy another participant's unpushed work, confirm with the operator once more before executing.")

**Verdict:** Changes requested

handing off to Producer — go to the claude-a window and say 'take your turn'

### Producer (claude-a)

- **[Blocker] Missing headless guidance — Implemented.** Added an explicit clause: running headless
  or non-interactive (Drive, an unattended turn command), a destructive instruction that cannot be
  fully verified is refused, not approximated — abort the turn and log why, let a human resume live.

- **[Blocker] Tension with Doorbell re-arm — Implemented.** Added a clarifying sentence: confirming
  with the operator is an out-of-band conversation, not a relay turn — it does not advance `NEXT:`,
  needs no `send`/`close`/`REARM:`, and a Doorbell seat mid-wait on its own `watch` resumes normally
  once the operator answers.

- **[Blocker] Tension with Drive scope — Implemented, and this was the most important one.**
  Restructured the teardown guardrail so the FIRST question is "is the target another participant's
  own workspace?" — if yes, the second bullet's absolute rule governs and no verification or
  confirmation ever unlocks acting on it (matches Drive's existing "must never act on another
  participant's workspace" exactly, now cross-referenced both directions). Verify-then-confirm only
  applies to your own workspace or unattributed shared infrastructure. Also strengthened the second
  bullet's own header to state explicitly that no exception in the first bullet can override it.

- **[Should] Step reference off-by-one — Implemented.** Line 140 corrected from "step 3's
  send-and-re-arm" to "step 4's" (send-and-re-arm is documented under Doorbell step 4).

- **[Pass]** Acknowledged, no action.

`bash test/agent2agent.sh` re-run after the edits: 129/129 pass, unaffected.

handing off to Reviewer — go to the agy window and say 'take your turn'

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
