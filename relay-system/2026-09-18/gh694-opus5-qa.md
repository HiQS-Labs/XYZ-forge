# RELAY · GH-694 Opus 5 QA — express telemetry schema and Tick fold resilience
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
6. **Commit only the relay file** (`relay(gh694-opus5-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/express.py`, `src/project.js`, `test/gh267-express-skill.sh`, `PROJECT/2-WORKING/GH-694-EXPRESS-TICK-TELEMETRY-SCHEMA.md`, `CHANGELOG.md`
- Reviewer: claude-opus   ·   Producer: claude-a
- Started: 2026-09-18
- Definition of Done: the implementation is sound if:
  1. `utils/py/express.py` `write_tick()` emits the canonical Tick 0.2.0 event envelope (`schema_version="0.2.0"`, `ts=now_iso()`, `type=ev_type`, `task=task_id`, `agent="express"`) while preserving backward-compatible payload fields;
  2. `src/project.js` `foldWithMeta()` defensively skips non-task.* and malformed events without string task IDs, with the institutional rationale comment intact;
  3. `test/gh267-express-skill.sh` pins `tick project` clean exit 0 across refusals, happy path landings, and resumes;
  4. `PROJECT/2-WORKING/GH-694-EXPRESS-TICK-TELEMETRY-SCHEMA.md` and `CHANGELOG.md` accurately describe the change;
  5. The solution adheres to commensurate complexity and least-mechanism principles (no unnecessary enterprise machinery, no global governance churn);
  6. Grade each finding with `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`; cite `file:line` for all passes/findings; set VERDICT (PASS/FAIL/PARKED) and Basis; PASS only when no `[Blocker]` remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Turn 1: Reviewer (claude-opus)
swept file: yes — `src/project.js` read end-to-end (1-386); `utils/py/express.py` swept at `write_tick()` (97-133), `refuse()` (91-94) and the three call sites (779, 834, 1096); the remaining ~1000 lines of the express driver sit outside this change's blast radius and were not read line-by-line. Probes ran under `.relay-scratch/tmp` with `HOME` redirected so the central mirror never touched `~/.config`.
VERDICT: FAIL

- [Pass] (DoD 1) `write_tick()` emits the canonical envelope — `utils/py/express.py:104-112` (`schema_version="0.2.0"`, `ts=now_iso()`, `type=ev_type`, `task=task_id`, `agent="express"`), legacy `at/actor/verb` kept, payload merged at :114. Probe (`write_tick(root,"express-fired",issue=999,sha="abc123")`) wrote `{"schema_version": "0.2.0", "ts": "2026-09-18T18:50:45.524Z", "type": "express.fired", "task": "GH-999", "agent": "express", "at": …, "actor": "express", "verb": "express-fired", "issue": 999, "sha": "abc123"}`; the no-issue refusal wrote `"type": "express.refused", "task": "lane"`. Envelope keys do not collide with any field passed at the three call sites.
- [Pass] (DoD 2, guard) `src/project.js:58-59` skips no-task and non-`task.*` events. Probe: events dir holding a legacy pre-fix record (`{"at":…,"actor":"express","verb":"express-fired","issue":998}` — what already-fired clones have on disk), both new-envelope express events above, and one `task.created T-1` → current `project()` gives `tasks: ["T-1"] rejections: 0`, STATE.md `## Open | - T-1 (priority: 0)`, exit 0. Every other raw-event consumer routes through `fold` (`src/claim.js:34`, `src/take.js:25`, `src/next.js:22`, `src/scope.js:28,54,168`, `bin/tick:441`); `nextEpoch` (`src/project.js:271-280`) compares by equality; `src/analyze.js:284,420` self-guards. Covered.
- [Should] (DoD 2, comment) The "institutional rationale comment intact" clause is not met. Commit 60dd24ee deleted the 5-line GH-68 comment (old `src/project.js:52-57`) and replaced it with `src/project.js:55-57`, dropping two load-bearing pieces: the pointer `See decisions/2026-07-01-cross-agent-dep-conflict.md` (the file exists) and the note that drift is "consumed directly from .tick/events/ by the shims' drift-brief reader, never via the fold". The gh694-final-qa r1 `[Pass]` "comment is intact" was inaccurate. Fix (no behaviour change): keep the new generalized paragraph and append the two dropped sentences to it.
- [Should] (DoD 3, strength) The three `tick project` assertions pin only exit 0, which the express.py half alone now guarantees — a revert of the `src/project.js:58-59` guard stays green.
  Observed input: PRE-fix `src/project.js` (`git show 60dd24ee~1:src/project.js`) run over the current-envelope express events from the probe above → `tasks: ["T-1","GH-999","lane"]`, STATE.md `## Open | - GH-999 (priority: 0) | - lane (priority: 0) | - T-1 …`, exit 0. Both phantom tasks are back and `test/gh267-express-skill.sh:228,360,594` would still print `ok`.
  Affected scope: only the three GH-694 assertions; no product code.
  Falsifier: restore `if (ev.type === 'dependency.drift') continue;` in place of :58-59 and run the suite — if any GH-694 assertion goes red, this finding is wrong.
  Fix: after each `tick project` add `grep -qE '^- (GH-999|lane) ' "$FX/.tick/STATE.md" && bad "express telemetry seeded a phantom task (GH-694)" || ok "no phantom task from express telemetry (GH-694)"`; and stop discarding diagnostics — `2>"$ERR"` instead of `2>&1 >/dev/null`, echo `$ERR` in the `bad` branch.
- [Should] (pre-existing, GH-268 sweep) `write_tick()` publishes non-atomically: `open(path, "w")` then `f.write` (`utils/py/express.py:118-119`), so a same-clone reader can observe an empty `.jsonl` — the same "express telemetry breaks tick's fold" class this issue fixes, narrower window.
  Observed input: zero-byte `.tick/events/2026-09-18T18-21-00.000Z-express-fired-gh-997.jsonl` (the on-disk state between the `open` and the `write`) → `project()` throws `SyntaxError: Unexpected end of JSON input` from `readAllEvents` (`src/events.js:207-210`), exit 1.
  Affected scope: only a `tick` reader racing an in-flight express write in the same clone; every complete file is unaffected.
  Falsifier: same zero-byte file present and `tick project` exits 0 → finding wrong.
  Fix (least mechanism, mirrors Tick's own GH-14 discipline at `src/events.js:184-186`): write to `path + ".tmp"` then `os.replace(tmp, path)` — `readAllEvents`' `.endsWith('.jsonl')` filter never sees the `.tmp`. Same two lines for the central mirror if wanted; it is not read by `tick`.
- [Nit] `src/project.js:59` still throws on a non-string `type`: `{"type":5,"task":"GH-1","agent":"x",…}` → `TypeError: ev.type.startsWith is not a function`. No writer emits this; align with the idiom the repo already uses at `src/analyze.js:284,420`: `typeof ev.type !== 'string' || !ev.type.startsWith('task.')`.
- [Nit] `utils/py/express.py:99,105,110` take three separate clock reads, so the filename and the record disagree — probe: filename `…T18-50-45.523Z-express-fired-gh-999.jsonl`, record `"ts": "…T18:50:45.524Z"`. Tick derives filename and `ts` from one read (`src/events.js:147-149`); compute `now = now_iso()` once and derive the filename from it (`at` can share it).
- [Pass] (DoD 3, placement) Each new assertion sits directly after the assertion proving the express event file exists (`test/gh267-express-skill.sh:226-228`, `:358-360`, `:592-594`), so the exit-0 pin is not vacuous.
- [Pass] (DoD 4) `CHANGELOG.md:1-3` describes both halves and the regression accurately. Capture doc `PROJECT/2-WORKING/GH-694-EXPRESS-TICK-TELEMETRY-SCHEMA.md:44-48` matches the code (`type`, `task` derivation, guard text, test placement).
- [Nit] (DoD 4) Capture doc `:31` "What's next | Final QA round 2 with agy, push & PR" contradicts `:55` "[x] Final QA approved & attested by agy" — update to "push & PR". `:18` non-goal "Modifying the central telemetry format at ~/.config/xyz/events/" is no longer true: the mirror at `utils/py/express.py:125-131` writes the identical new envelope (probe: both files byte-equal in the redirected `HOME`). Reword to "restructuring the central mirror (it receives the same additive envelope)".
- [Pass] (DoD 5) Commensurate: +12/-1 in express.py, +5/-6 in project.js, +3 in the test, no new module, no governance edits (`git diff --stat 60dd24ee~1..HEAD`).
- [Unverified — needs clone run] `npm test` 23/23 and `test/gh267-express-skill.sh` 98/98 as stated in `CHANGELOG.md:3` and the capture doc `:52-53`; the harness gate after this turn is the measurement.
- Pre-existing defects in the swept scope: one found (the non-atomic publish, graded above); none other in `src/project.js`.

Basis: No `[Blocker]` — the fix is correct and the crash is gone. FAIL routes three `[Should]`s to a Producer disposition: the DoD 2 comment clause is literally unmet, the regression does not pin the consumer half it claims to guard, and the same-clone torn-write is the same failure class as GH-694 with a two-line fix. Approve expected in r2 on Implemented or reasoned Declined.

Handing off to Producer — go to the claude-a window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
