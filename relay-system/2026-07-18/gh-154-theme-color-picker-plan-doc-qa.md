# RELAY · GH-154 theme color picker — plan doc QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-18.
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
6. **Commit only the relay file** (`relay(gh-154-theme-color-picker-plan-doc-qa): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-154-THEME-COLOR-PICKER.md`
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-18
- **This is a PLAN doc, not code. No code has been written.** You are reviewing whether the plan is
  correct and buildable — not reviewing an implementation.
- The working tree you are in is a git worktree of the `rebalance-OS` repo on branch
  `feat/theme-picker`, based on `origin/development`. **The real source is present — read it.**
  A finding that the plan misstates the codebase is the most valuable thing you can produce here.
- Context: this is Day 2 of the dashboard redesign epic (GH-136). Read
  `PROJECT/2-WORKING/GH-136-DASHBOARD-REDESIGN.md` first — it holds 10 standing invariants the plan
  must not violate. Design source: `PROJECT/1-INBOX/dashboard-redesign-2026-07-18/Settings Theme.dc.html`.

### Definition of Done — grade against these

1. **The inventory is factually true.** The plan's "Current state" section makes specific, checkable
   claims: file:line references (`web_components.py:19` is the only `:root`; `render_shell()` at
   `:640`; `PAGE_CSS` at `pulse_web.py:1698-2388`; `_CSS` at `web.py:244-356`), literal counts
   (~190 total; 42/59, 37/14, 24/12 hex/rgb per file), "zero tracked `.css` files", "no `localStorage`
   anywhere", "no settings table", and the route→renderer table (esp. `/` being a static
   `FileResponse` at `pulse_server.py:268`). **Verify these against the actual tree.** Cite
   `file:line` for anything you confirm or refute. An uncited pass is worthless here.
2. **The token vocabulary is sufficient and the derivation is right.** 7 settable + 3 derived +
   4 theme-invariant status colors. Does that actually cover the ~190 literals, or will the build
   discover it needs more tokens? Check the proposed rename map (`--bg`→`--page` etc.) against real
   call sites. The plan already flags `--fg-dim`/`--shadow` as unresolved — is that the only gap?
3. **D1 (derivation in JS only, Python ships pre-derived defaults, drift gated by a Playwright test)
   is sound.** Attack it. Is the drift test actually implementable? Is the rejected alternative
   fairly rejected?
4. **D2 (client-side pre-paint theming because `/` is a static build artifact) is sound.** This is
   the load-bearing decision. If it is wrong the whole plan is wrong. Is there a flash-of-default
   failure mode the plan hasn't closed? Does the pre-paint script actually survive `build_page()`?
5. **Phase ordering is safe to bisect** and each phase's exit condition is checkable.
6. **No standing invariant from GH-136 is violated** — particularly #1 (one timestamp helper),
   #5 (no import workarounds), #6 (`web/pulse.html` is a build artifact, never hand-edited),
   #8 (verify by rendering).
7. **Risks and anti-goals are honest** — is anything material missing? Specifically consider:
   print stylesheets, SVG/canvas fills (the repo-pie chart), `<meta name="theme-color">`, email or
   report output that reuses these stylesheets, and any CSS the plan's inventory may have missed.

Verdict must be one of: Approved | Changes requested | Blocked.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
