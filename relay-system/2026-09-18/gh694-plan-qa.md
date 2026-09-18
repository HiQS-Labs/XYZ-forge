# RELAY · GH-694 plan QA — express telemetry schema and Tick fold resilience
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-18.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

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
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh694-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh694-plan.md** — the read-only path that
  `relay-drive.sh --artifact-file relay-system/2026-09-18/gh694-plan.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-09-18
- Definition of Done: the plan is sound if (1) Root cause and failure path are accurately grounded in utils/py/express.py and src/project.js; (2) The proposed event envelope for write_tick() adheres to the canonical Tick 0.2.0 format (schema_version, ts, type, task, agent) while preserving backward-compatible payload fields; (3) The defensive filter in src/project.js (foldWithMeta) safely skips malformed/non-task events without breaking existing task coordination; (4) The verification plan includes a concrete consumer coexistence test in test/gh267-express-skill.sh testing ./bin/tick info exit code; (5) Scope is minimal and DRY (no ceremonial middleware or governance edits). Grade each; PASS only when no [Blocker] remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

**Reviewer:** agy
swept file: yes
VERDICT: FAIL
Basis: The proposed test asserts `./bin/tick info` exits 0, which fails because it requires a task argument and the fix correctly prevents express events from seeding a task. It should run `tick project` via the correct path.

- `[Pass]` Root cause grounded. The plan correctly identifies `write_tick()` (`utils/py/express.py:97-110`) omitting envelope fields and `foldWithMeta()` (`src/project.js:53-63`) crashing on `undefined` when sorting tasks.
- `[Pass]` Canonical 0.2.0 format. The proposed `write_tick()` payload (in `utils/py/express.py`) correctly aligns with the schema (`schema_version`, `ts`, `type`, `task`, `agent`) while preserving backwards-compatible fields.
- `[Pass]` Defensive filter. The addition of `if (!ev.type || !ev.type.startsWith('task.')) continue;` in `src/project.js:54-63` safely prevents non-task events like `express.fired` from polluting task states.
- `[Should]` Preserve the `dependency.drift` comment.
  Observed input: The plan's snippet for `src/project.js:54-63` replaces the existing code but omits the 5-line `dependency.drift (GH-68)` rationale comment.
  Affected scope: `src/project.js` `foldWithMeta` event loop.
  Falsifier: A replacement that deletes the rationale removes institutional context. Update the comment to mention `dependency.drift` and `express.*` as examples of non-task events skipped by the new filter instead of deleting it.
  Fix: Explicitly state to retain and update the comment at `src/project.js:54-58` above the new filter.
- `[Blocker]` The test assertion `./bin/tick info` exits 0 is broken.
  Observed input: Running `"$HERE/../bin/tick" info` inside the test environment exits 2 (missing task argument). Running `"$HERE/../bin/tick" info GH-999` exits 1 because the defensive filter prevents task seeding. Finally, `tick` is not located at `./bin/tick` from within `$FX`.
  Affected scope: `test/gh267-express-skill.sh` Component C test modifications.
  Falsifier: Using `TICK_REPO_ROOT="$FX" "$HERE/../bin/tick" project` executes the full fold and `renderState()` sort (where the crash originally occurred) and successfully exits 0.
  Fix: Change Component C to assert `TICK_REPO_ROOT="$FX" "$HERE/../bin/tick" project >/dev/null` exits 0 instead.
- `[Pass]` Scope is minimal and DRY. No ceremonial middleware or governance edits proposed across the 3 targeted files (`utils/py/express.py`, `src/project.js`, `test/gh267-express-skill.sh`).

handing off to Producer — go to the claude-a window and say 'take your turn'

## Producer (claude-a, 2026-09-18)
- `[Should]` Preserve dependency.drift comment: **Implemented**. Component B in `gh694-plan.md` now explicitly retains and expands the rationale comment above the `foldWithMeta` filter at `src/project.js:54-58`.
- `[Blocker]` Fix broken test assertion: **Implemented**. Component C in `gh694-plan.md` updated to use `TICK_REPO_ROOT="$FX" "$HERE/../bin/tick" project >/dev/null 2>&1` with `assert_eq "$?" "0"`, verifying the full task fold and `renderState()` sort cleanly exit 0.

handing off to Reviewer — take your turn

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
