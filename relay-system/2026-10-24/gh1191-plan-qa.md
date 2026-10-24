# RELAY · GH-1191 plan QA: task-sync Claude Desktop native planner
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-24.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1191-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the PLAN in `PROJECT/1-INBOX/GH-1191-TASK-SYNC-CLAUDE-DESKTOP.md` (no code yet). Requirements: steps 1–3 of https://github.com/HiQS-Labs/XYZ-forge/issues/1191 (the issue text's Findings and Plan sections are restated in the doc's Recon/Scope).
- Source paths the plan extends (read them): `skills/3-weekly/task-sync/scripts/task_sync.py` (whole file), `skills/3-weekly/task-sync/scripts/adapters/claude.py` (esp. `_iso_to_local` :37 and `ClaudeCloudAdapter` :276–354), `skills/3-weekly/task-sync/scripts/core.py`, `skills/3-weekly/task-sync/SKILL.md` (sections "Codex desktop (GH-901)" and "Claude Code (GH-1105)"), and prior art `PROJECT/3-COMPLETED/GH-1105-CLAUDE-CODE-TASK-SYNC.md` + `TESTS-RESULTS/2026-10-17+GH-1105/probes.py`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-24
- Operational envelope: a local, single-operator CLI planner (~60 lines) that proposes title renames; it never writes. The app's native `set_session_title` tool is the only writer, driven by an agent following SKILL.md. Grade against these requirements and commensurate complexity, not multi-tenant/enterprise threat models. XYZ-forge forbids new `test/` suites or gate machinery (AGENTS.md "No new tests", GH-831); verification is manual probes + a live smoke under `TESTS-RESULTS/`.
- Native tool facts the plan relies on (from the operator's Claude Desktop app, 2026-10-24): `list_sessions(include_archived?, limit?)` returns other sessions only (the caller is excluded) with `sessionId`, `title`, `isArchived`, `isRunning`, `lastActivityAt` (ISO). `get_session(id|"self")` returns the same fields. `set_session_title(session_id, title)`: app-generated titles are replaced without asking; a user-set title needs operator approval, which an unattended session cannot give, so it declines.
- Definition of Done (for this plan review):
  1. Every #1191 step 1–3 requirement maps to a plan step with a falsifiable acceptance check.
  2. The plan extends the existing subsystem (task-sync CLI + `adapters/claude.py` + the GH-901/GH-1105 plan-only pattern) with no second writer, module or framework.
  3. Risks, rollback and the untraced facts (`lastActivityAt` / `titleSource` after a rename) are named, with a check that would catch them.
  4. The rating `rated 60/25/50/75` and its rationale are grounded.

Questions:
1. Is using the row's own `lastActivityAt` as activity (no separate `activity_at` map, unlike claude-cloud) sound, given the recon evidence that Desktop's record sets it equal to `lastTurnEdgeAt`? What would break if a rename bumps it?
2. Is accepting an empty `sessions` list (zero candidates), unlike claude-cloud's refusal, justified given `list_sessions` excludes the caller and the planner never writes? Or does it open a real failure (a failed list call written as `[]`) the procedure doesn't already guard?
3. Does adding `claude-desktop` to `ADAPTERS`/`PLAN_ONLY` plus a new `--desktop-snapshot` flag keep the existing modes (`zcode,agy` default, `codex`, `claude`, `claude-cloud`) byte-for-byte unchanged? Cite `task_sync.py` lines.
4. Is the native procedure in plan step 3 complete and ordered correctly (recheck before write, decline = skip, re-read, undo receipt)? Is anything missing that the Codex/cloud procedures in SKILL.md have and this one needs?
5. Are the probes in plan step 4 plus the red control enough to catch the real failures, without over-testing? Name any probe that is missing or unnecessary.
6. Anything over-engineered, under-specified or out of scope? Cite file:line.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
