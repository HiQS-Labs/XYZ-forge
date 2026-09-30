# RELAY · GH-892 agy-task-sync QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-30.
-->

NEXT: Producer
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-892-agy-task-sync-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **utils/skills/agy-task-sync/SKILL.md** and **utils/skills/agy-task-sync/scripts/agy_task_sync.py**
- Reviewer: agy (Gemini Pro 3.1)   ·   Producer: claude-a
- Started: 2026-09-30
- Operational Envelope: Local developer agent CLI and Antigravity IDE automation.
- Definition of Done:
  1. Correctly formats and updates titles with today's US date (MM-DD) across SQLite DB and .pbtxt annotations.
  2. Accurately extracts the latest meaningful action or tool summary from session transcripts (transcript.jsonl) into the preview field.
  3. Accurately manages the Pinned group in app_storage.json (pinned_conversations_order) and annotations/*.pbtxt.
  4. Supports headless 15-minute recurring cadence via daemon loop, Antigravity schedule, or launchd.
  5. Adheres to commensurate complexity: safe dry-run by default, SQLite timeouts, clean error handling, no superfluous dependencies or test bloat (GH-831).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes

- **[Blocker]** `format_title_with_date` crashes on `None` titles. SQLite can return `None` (NULL) for titles of new tasks, which throws a `TypeError` in `re.sub`.
  Observed input: `current_title = None` (valid state in SQLite)
  Affected scope: `utils/skills/agy-task-sync/scripts/agy_task_sync.py:136` inside `format_title_with_date`.
  Falsifier: Passing `None` to `re.sub(r"^\d{2}[-/]\d{2}\s*", "", current_title)` throws `TypeError: expected string or bytes-like object`. Fix by coalescing to `""` if `current_title` is `None`.
- **[Should]** Date prefix regex aggressively strips non-prefix dates like `10-15-2023`, yielding an ugly suffix.
  Observed input: `current_title = "10-15-2023 Task"`
  Affected scope: `utils/skills/agy-task-sync/scripts/agy_task_sync.py:136` regex `r"^\d{2}[-/]\d{2}\s*"`.
  Falsifier: Replaced with `"-2023 Task"`, causing an ugly new title `09-30 -2023 Task`. Add `(?=\s|$)` to the regex to ensure the date is an isolated word or prefix.
- **[Should]** Unescaped quotes in `new_title` break protobuf text format in `.pbtxt`.
  Observed input: `new_title = 'A title with "quotes"'`
  Affected scope: `utils/skills/agy-task-sync/scripts/agy_task_sync.py:156` inside `update_annotation_file`.
  Falsifier: A script attempting to parse `title:"A title with "quotes""` using `google.protobuf.text_format` throws a ParseError. Fix by escaping double quotes (e.g. `new_title.replace('"', '\\"')`) before injection.
- **[Should]** `--all` implementation contradicts the documentation in `SKILL.md`. The code limits to 20 instead of a 48-hour time filter.
  Observed input: `args.all = True`
  Affected scope: `utils/skills/agy-task-sync/scripts/agy_task_sync.py:218` SQL query in `sync_conversations`.
  Falsifier: Code executes `SELECT ... ORDER BY last_modified_time DESC LIMIT 20` instead of a 48-hour time filter. Either update `SKILL.md` to say "20 most recent" or change the SQL query to `WHERE last_modified_time >= ...`.
- **[Pass]** Extracts last action from transcript correctly. Verified: `utils/skills/agy-task-sync/scripts/agy_task_sync.py:93-108` correctly traverses `tool_calls` array in `PLANNER_RESPONSE` and parses `toolSummary` or `toolAction`.
- **[Pass]** Safely manages app storage. Verified: `utils/skills/agy-task-sync/scripts/agy_task_sync.py:45-48` correctly handles stringified JSON arrays which is how Electron saves `pinned_conversations_order`.

**VERDICT:** FAIL
**Basis:** Crash on `None` titles blocks end-to-end sync for new tasks, and unescaped quotes corrupt protobuf files.

### Producer · Round 1

- **[Blocker] `format_title_with_date` crashes on `None` titles**: Implemented. Added null-coalescing guard `raw = "" if current_title is None else str(current_title).strip()`.
- **[Should] Date prefix regex strips non-prefix dates**: Implemented. Added positive lookahead `(?=\s|$)` to `r"^\d{2}[-/]\d{2}(?=\s|$)\s*"` ensuring only isolated date prefixes are stripped.
- **[Should] Unescaped quotes in `new_title` break protobuf text format**: Implemented. Added `.replace("\\", "\\\\").replace('"', '\\"')` escaping before formatting `.pbtxt`.
- **[Should] `--all` implementation vs documentation**: Implemented. Updated SQL query to filter `WHERE last_modified_time >= ?` with a 48-hour UTC cutoff timestamp.
- Verified all 4 cases with automated assertions.  [Unverified — no citation]

Handing off to Reviewer for Round 2 review.

### Reviewer · Round 2

swept file: yes

- **[Blocker]** `update_annotation_file` regex `r'title:\s*"[^"]*"'` fails to match existing titles containing escaped quotes, corrupting the `.pbtxt` file.
  Observed input: Existing `.pbtxt` content `title:"A \"quote\"" pinned:true`
  Affected scope: `utils/skills/agy-task-sync/scripts/agy_task_sync.py:157-158` inside `update_annotation_file`.
  Falsifier: `re.sub(r'title:\s*"[^"]*"', 'title:"New Title"', 'title:"A \\"quote\\"" pinned:true')` yields `title:"New Title"quote\"" pinned:true` instead of replacing the entire title string. Fix by using a regex that handles escaped quotes, such as `r'title:\s*"(?:\\.|[^"\\])*"'`.
- **[Should]** Uncaught SQLite exceptions in `sync_conversations` will crash the background daemon loop.
  Observed input: Transient database locks or connection errors (e.g., `sqlite3.OperationalError`).
  Affected scope: `utils/skills/agy-task-sync/scripts/agy_task_sync.py:197-269` inside `sync_conversations`, called unconditionally in `while True:` daemon loop at line 333.
  Falsifier: A locked database throws an exception during `c.execute(...)`, escaping `sync_conversations` and killing the entire `agy_task_sync.py` process. Catch `sqlite3.Error` or `Exception` in `run_cycle()` to log it and permit the daemon to retry next interval.
- **[Pass]** `format_title_with_date` correctly guards against `None`. Verified: `utils/skills/agy-task-sync/scripts/agy_task_sync.py:135` converts `None` to `""`.
- **[Pass]** Date prefix regex correctly isolates the date using positive lookahead. Verified: `utils/skills/agy-task-sync/scripts/agy_task_sync.py:137` uses `(?=\s|$)`.
- **[Pass]** Unescaped quotes are now correctly escaped for protobuf injection. Verified: `utils/skills/agy-task-sync/scripts/agy_task_sync.py:156` correctly replaces backslashes and double quotes.
- **[Pass]** `--all` implementation correctly limits by 48 hours. Verified: `utils/skills/agy-task-sync/scripts/agy_task_sync.py:218-223` uses `last_modified_time >= ?` with a 48-hour UTC cutoff.

**VERDICT:** FAIL
**Basis:** Corrupting `.pbtxt` annotations when titles contain existing escaped quotes blocks safe execution.

Handing off to Producer — go to the claude-a window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
