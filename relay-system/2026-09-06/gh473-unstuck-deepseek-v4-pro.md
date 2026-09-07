# RELAY · GH-473 unstuck skill DeepSeek V4 Pro QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded from relay-automation/new-relay.sh on 2026-09-06.
-->

NEXT: Human
STATUS: Escalated
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff.**
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Any `[Pass]` or "verified" finding must carry a quoted span or `file:line` citation.
     Do not edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the bottom, directly above the marker. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If max `ROUND` ends without `Approved`, set
   `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh473-unstuck-deepseek-v4-pro): <role> r<N>`); no push.
7. End the turn with an explicit handoff, or `relay closed (Approved), no further turn needed`.

## Setup
- Artifact under review: **.relay-artifacts/SKILL.md** — seeded read-only by
  `relay-drive.sh --artifact-file skills/unstuck/SKILL.md`.
- Related contract to inspect: `skills/workhorse/SKILL.md` (handoff only) and
  `PROJECT/2-WORKING/GH-473-UNSTUCK-SKILL.md` (originating failure and decisions).
- Reviewer: DeepSeek V4 Pro (`deepseek/deepseek-v4-pro`) · Producer: claude-a
- Started: 2026-09-06
- Definition of Done:
  1. The skill interrupts an agent that is polishing machinery while the user's current goal is not
     moving, including the demonstrated review-cap/cache-fingerprint failure.
  2. It distinguishes a real goal blocker from correctness/safety work, an external dependency,
     polish, and a self-created cog without dismissing legitimate blockers.
  3. It selects one smallest goal-moving action, acts once, verifies observable movement, and exits;
     the recovery process cannot become a recursive workflow of its own.
  4. Cap exhaustion is not itself proof of blockage or completion; recent qualifying movement and
     the latest authoritative user goal govern the decision.
  5. It preserves authorization and parent-workflow governance, and does not silently delete work,
     bypass required review, launch external actions, or invent facts.
  6. The description routes precisely: `/unstuck` is a mid-execution recovery interrupt, while
     `/workhorse`, `/debug-mantra`, `/recon`, and `/finish-line` keep their existing jobs.
  7. The instructions are lean enough to help a stuck model move; remove ceremony, duplication, or
     ambiguous rules that could create another cog.

## Questions

Answer each directly, with `file:line` citations for defects and concrete replacement language.

1. Run the screenshot scenario mentally. Would these instructions make the agent launch the already
   accepted marathon, or could it still rationalize a fifth review/cog? Identify the exact escape hatch.
2. Is the `qualifying movement` test operational and hard to game? Does it correctly handle a narrow
   real fix completed during the latest round without mistaking polishing for goal movement?
3. Are the categories and Rung 3 falsification test sufficient to protect real correctness/safety
   blockers? Flag any wording that encourages reckless action or unauthorized mutation.
4. Is the boundary with workhorse and neighboring skills crisp? Should this remain a separate
   interrupt, or does any part belong back inside workhorse?
5. Find anything overengineered inside the anti-overengineering skill: repeated concepts, excessive
   output requirements, recursive consult/review behavior, or a rung that can be removed.
6. Review `agents/openai.yaml` for consistency with the skill and assess whether the trigger text is
   likely to fire on the intended requests without swallowing ordinary debugging or planning.

If the skill is sound, say so plainly and set `STATUS: Approved`. This is a review-only turn: do not
edit any file other than this relay file.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise stop.
3. One turn = one block appended at the bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). Commit just the relay file; no push.

## Log

### Coordinator — transport escalation

- The configured DeepSeek relay profile resolved to `deepseek/deepseek-v4-pro` over OpenRouter.
- Attempt 1 read the review inputs but OpenRouter returned `HTTP_404` before a valid review block or
  `VERDICT:` survived. The harness rejected the partial turn and released its claim.
- The one allowed retry returned the same `HTTP_404` immediately.
- The installed Command Code transport advertised the exact same model and was tried once without
  substituting a different model; it refused the request for insufficient account credits.
- No reviewer verdict exists, no artifact edit was accepted, and no sharpening is attributed to
  DeepSeek. The existing skill remains at commit `ed390b3`.

VERDICT: Blocked — DeepSeek V4 Pro is unavailable through both installed transports.

Handing off to the human — restore one of the two V4 Pro routes before requesting another review.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
