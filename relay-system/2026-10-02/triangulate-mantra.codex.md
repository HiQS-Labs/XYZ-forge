# RELAY · Triangulate per-turn mantra QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-02.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(triangulate-per-turn-mantra-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/1-hourly/triangulate/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-10-02
- Definition of Done: A surgical instruction asks for the existing short Triangulate mantra at the start of each assistant turn while the skill is active, once per turn in visible commentary before actions. All routing, evidence floors and the conditional full debug mantra remain intact. This is prompt guidance, not a guaranteed runtime hook.
- Operational envelope: Markdown-only skill edit; no new hooks, tests, invocation policies or deployment edits. Commensurate review: do not demand new machinery for three instruction lines.
- Questions:
  1. Does the new instruction specify visible output, active-skill scope, and once per assistant turn rather than every tool call?
  2. Does it conflict with routing away in Step 0a or the conditional full debug-mantra recital in Step 4?
  3. Is the request met with the smallest change, without claiming runtime-enforced behavior?
- Validation: git diff --check passed. Skill Creator quick_validate rejects the unchanged baseline and candidate equally because of pre-existing argument-hint metadata; that metadata remains unchanged. The repository Small gate is running separately in a disposable full clone. Do not run tests in the review worktree.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PASS
Basis: The requested per-turn instruction is explicit and surgical; routing, evidence floors, and the conditional full debug mantra remain intact. Approval covers prompt guidance, not runtime enforcement or the separate harness gate.
swept file: yes

- [Pass] Visible, active-skill, once-per-turn scope is explicit at `.relay-artifacts/SKILL.md:22`: "At the start of every assistant turn while Triangulate is active" and "once in the first visible commentary message, before tools or task updates (not before each tool call)". Line 23 supplies the short mantra. Fix: none.
- [Pass] No routing or recital conflict: `.relay-artifacts/SKILL.md:30` still says "Route to the single skill and stop"; the active-skill qualifier ends the recurring obligation when Triangulate routes away. The distinct full mantra remains conditional at line 135: "Recite the full mantra only if this is also an active debug session." Fix: none.
- [Pass] Minimal textual change against the installed skill: command `diff -u /Users/noelsaw/.codex/skills/triangulate/SKILL.md .relay-artifacts/SKILL.md` exited 1 (differences found); its sole hunk was `@@ -19,6 +19,9 @@`, adding only the instruction, mantra, and blank line at candidate lines 22–24. This is a comparison to the installed copy, not a Git-baseline claim. No hook, deployment rule, or runtime guarantee is introduced. Fix: none.
- [Pass] Whole-file sweep completed for `.relay-artifacts/SKILL.md:1–195`, including frontmatter, early exits, classification, floor table, all three lenses, card, neighbors, and provenance. No additional pre-existing defect identified. The floor remains explicit at lines 111–112: "Buy more evidence freely; never buy less"; Step 5 preserves it at lines 145–146. Fix: none.
- [Unverified — needs clone run] The separate Small gate and reported quick_validate baseline rejection were not rerun or independently attested here. No prohibited suite, fixture, Git command, or artifact edit was performed; the harness owns post-turn validation.

Relay closed (Approved), no further turn needed. Producer (`codex-author`) remains the NEXT role for the recorded handoff; the token is completed with `done`.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
