# RELAY · GH-1346 QA: chain close-the-loop and todo-list with non-blocking PARKED/blocker skip ladder
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-05.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1346-close-loop-todo-chain-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifacts under review (in-tree repo paths; read both files in full and do NOT edit them):
  1. `skills/2-daily/close-the-loop/SKILL.md`
  2. `skills/2-daily/todo-list/SKILL.md`
- Reviewer: claude (`claude-fable-5-1`, `--effort low`)   ·   Producer: agy
- Started: 2026-11-05
- Definition of Done:
  1. `skills/2-daily/close-the-loop/SKILL.md` preserves its default report-only contract for bare `/close-the-loop`, and adds `## Execute mode` (`--execute`) that chains `confirmed pending` items directly into `skills/2-daily/todo-list/SKILL.md`.
  2. `skills/2-daily/todo-list/SKILL.md` supports chained discovery (`--close-the-loop`) and implements a DRY non-blocking serial execution ladder: unblocked items complete (`[x]`), low-risk deferrable/incidental items are parked in `<repo-root>/PARKED/YYYY-MM-DD-<scope>.md` (`[p]`) per `PARKED/README.md`, and concrete external blockers are marked `[!]` (keeping true blockers visible rather than hidden in `PARKED/`), immediately advancing to the next independent `[ ]` item until all unblocked items are completed.
  3. At the end of the sequence, `todo-list` reminds the operator of all blocked (`[!]`) and `PARKED/` deferred (`[p]`) items.
  4. All relative links and repo paths in both `SKILL.md` files resolve cleanly.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 (claude)

swept file: yes — both SKILL.md files read in full (close-the-loop 81 lines, todo-list 195 lines), plus `git diff HEAD~1 HEAD` to separate new from pre-existing text; pre-existing sections 0, 2, 4 of todo-list and `## Review`/`## Report` of close-the-loop were read, not just the diff. Pre-existing defects found: one semantic collision (Nit 2 below); nothing else.

**DoD 1 — report-only default preserved + `## Execute mode`:** `[Pass]` `skills/2-daily/close-the-loop/SKILL.md:65-66` "Stop after the report by default. A bare `/close-the-loop` invocation does not authorize executing candidates"; `:68` `## Execute mode (--execute / chain into todo-list)`; `:73-80` runs Review+Report first, filters to `confirmed pending`, then "Immediately load and execute [`todo-list`](../todo-list/SKILL.md) ... as the input to its Section 1".

**DoD 2 — chained discovery + non-blocking ladder:** `[Pass]` `skills/2-daily/todo-list/SKILL.md:63-67` chained discovery for `/todo-list --close-the-loop` / `/close-the-loop --execute`; `:129-133` `[x]` -> "advance immediately to the next available `[ ]` item"; `:139-144` `[p]` -> `<repo-root>/PARKED/YYYY-MM-DD-<scope>.md` per `PARKED/README.md` (matches `PARKED/README.md:11` "dated `PARKED/YYYY-MM-DD-<scope>.md` file") then "**immediately advance to the next `[ ]` item**"; `:145-151` `[!]` "keep it in the active checklist ... not hidden in `PARKED/`" — consistent with `PARKED/README.md:6` "A blocker to the current task stays in its active issue/plan and cannot be hidden here"; dependent items get `[!]` (`blocked by #k`), else advance. The wake prompt `:106-110` mirrors the same ladder, so the watchdog path and the synchronous path agree.

**DoD 3 — end-of-sequence reminder:** `[Pass]` `skills/2-daily/todo-list/SKILL.md:158-164` "report the final checklist ending with a dedicated **Blocked (`[!]`) & Deferred (`[p]` in `PARKED/`) Reminder** listing every skipped item, its `PARKED/` file path or issue link, and the exact decision or action needed from the user"; wake prompt `:111` "report the final checklist status with the blocked/deferred reminder".

**DoD 4 — links/paths resolve:** `[Pass]` probe (exit 0) resolved every `](...)` relative link and every backticked `skills/...`/`PARKED/...` path from each file's directory:
```
OK close-the-loop -> ../todo-list/SKILL.md
OK todo-list -> ../../../PARKED/README.md, ../../1-hourly/sanity-check/SKILL.md,
   ../../1-hourly/unstuck/SKILL.md, ../close-the-loop/SKILL.md, ../workhorse/SKILL.md
OK path skills/1-hourly/{handsfree,sanity-check,unstuck}/SKILL.md, skills/2-daily/{close-the-loop,workhorse}/SKILL.md, PARKED/README.md
MISS path PARKED/YYYY-MM-DD-<scope>.md   (template placeholder, expected)
```
Section anchors also exist: `sanity-check/SKILL.md:68` `## Decision ladder` and `:179` "After two investigation attempts" (matches "capped at 2 investigation attempts"); `workhorse/SKILL.md:66` Rung 0 with Triage Protocol steps 3 (`:75` Queue Segmentation incl. `PARKED/` first) and 4 (`:91` Serial Execution Loop) = the cited "Rung 0.3"/"Rung 0.4"; `:361` Fast-Track; `unstuck/SKILL.md:8` two-turn tripwire; `.gitignore:13` `/temp/` backs "`temp/` is gitignored here". The one `https://github.com/.../handsfree/SKILL.md` URL is pre-existing and paired with the in-repo path.

- `[Nit]` `skills/2-daily/close-the-loop/SKILL.md:17` "Return candidates; do not execute them or create records." is now only true by default; `:65` already says "by default". Fix: append "by default (see `## Execute mode`)" to line 17. Cosmetic; not blocking.
- `[Nit]` (pre-existing, surfaced by the new cross-reference) `skills/2-daily/todo-list/SKILL.md:71-72` defines `[-]` as *in flight*, while `workhorse/SKILL.md:82` uses `[-]` for *optional/deferred* — and `todo-list:122-124` now tells the agent to "Reuse the per-item execution and continuation rules from workhorse Rung 0.4". An agent reading both could misread a todo-list `[-]` item as deferred. Fix: one sentence after `todo-list:124` noting "`[-]` here means in flight; workhorse's run checklist uses `[-]` for deferred — do not carry that marker across." No behaviour change requested, so no Observed/Affected/Falsifier lines.

**VERDICT: PASS**
**Basis:** All four DoD items are satisfied with cited spans; every relative link and repo path resolves (probe above); the `[p]`/`[!]` split matches `PARKED/README.md`'s "blocker stays visible" rule; wake-prompt and synchronous ladders are consistent. The two nits are wording-only and do not affect the contract. Harness gate (`validate.sh`) runs after this turn — not run here per reviewer scope.

Relay closed (Approved), no further turn needed. Producer: optional nits only; nothing required.

### Producer · Round 1 (agy)

- **Nit 1 (`skills/2-daily/close-the-loop/SKILL.md:17`):** Implemented — updated line 17 to `"Return candidates; do not execute them or create records by default (see `## Execute mode` below)."` so it matches line 65.
- **Nit 2 (`skills/2-daily/todo-list/SKILL.md:124`):** Implemented — added explicit disambiguation note that `[-]` in `todo-list` means *in flight* (while `[p]` means parked/deferred, avoiding confusion with `workhorse`'s `[-]` marker).
- Note on Round 1 containment exit: an IDE buffer formatter appended a trailing newline to `PROJECT/2-WORKING/GH-1346-CLOSE-LOOP-TODO-CHAIN.md` in the parent tree mid-turn; all clone edits now run via script without opening IDE buffers.

Handing off to Reviewer (`claude`) — please verify the two implemented nits and close the relay (`STATUS: Approved`).

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
