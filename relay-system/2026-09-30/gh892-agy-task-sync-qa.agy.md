# RELAY · GH-892 agy-task-sync QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-30.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 5 / 5

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

### Producer · Round 2

- **[Blocker] `update_annotation_file` regex fails on existing escaped quotes**: Implemented. Updated regex pattern to `r'title:\s*"(?:\\.|[^"\\])*"'` (`utils/skills/agy-task-sync/scripts/agy_task_sync.py:157`), which properly handles escaped quotes and backslashes within the quoted string without premature truncation. Tested against `title:"A \"quote\"" pinned:true` and verified full replacement.
- **[Should] Uncaught SQLite exceptions in `sync_conversations` crash daemon**: Implemented. Wrapped all SQLite database operations in `try ... except sqlite3.Error` and `except Exception` blocks (`utils/skills/agy-task-sync/scripts/agy_task_sync.py:198-275`), returning a structured error dictionary. Additionally wrapped `sync_conversations` invocation in `run_cycle` (`utils/skills/agy-task-sync/scripts/agy_task_sync.py:317-338`) to ensure transient database lock errors log a warning rather than killing the long-running daemon loop.
- Swept and verified with unit assertions.  [Unverified — no citation]

Handing off to Reviewer for Round 3 review.

### Reviewer · Round 3

swept file: yes

- **[Blocker]** `sync_conversations` leaks SQLite file descriptors on transient database errors, crashing the 15-minute daemon loop over time.
  Observed input: `sqlite3.OperationalError` (e.g., database is locked) raised during `c.execute(...)`.
  Affected scope: `utils/skills/agy-task-sync/scripts/agy_task_sync.py:198-278` inside `sync_conversations`.
  Falsifier: If `c.execute` throws an exception, execution jumps directly to the `except sqlite3.Error` block at line 273, skipping `conn.close()` at line 271. Over multiple 15-minute cycles, this exhausts file descriptors. Fix by wrapping the connection usage in a `try...finally:` block (e.g. `finally: if 'conn' in locals(): conn.close()`) or `with contextlib.closing(...)`.
- **[Blocker]** `update_annotation_file` blindly replaces or searches for the literal string `pinned:true`, which corrupts the title if it contains that string.
  Observed input: `content = 'title:"A pinned:true task"'` and `pin = True` (or `pin = False`).
  Affected scope: `utils/skills/agy-task-sync/scripts/agy_task_sync.py:165-168` inside `update_annotation_file`.
  Falsifier: If the user's title includes `pinned:true`, `"pinned:true" in content` is True, so `pin = True` fails to append the flag to the `.pbtxt`. Conversely, `pin = False` calls `content.replace("pinned:true", "")`, corrupting the title to `title:"A  task"`. Fix by ignoring content inside quotes when checking or removing the flag, for example by temporarily stripping quoted strings (e.g., `if "pinned:true" not in re.sub(r'("(?:\\.|[^"\\])*")', '', content):`) and similarly using a regex for unquoted removal.

**VERDICT:** FAIL
**Basis:** File descriptor leaks will crash the background daemon, and brittle string replacement will corrupt titles in `.pbtxt` annotations.

### Producer · Round 3

- **[Blocker] `sync_conversations` leaks SQLite file descriptors on transient database errors**: Implemented. Wrapped connection lifecycle with `try ... finally: if conn: conn.close()` in `sync_conversations` (`utils/skills/agy-task-sync/scripts/agy_task_sync.py:198-281`) and in `args.list_pinned` (`utils/skills/agy-task-sync/scripts/agy_task_sync.py:314-328`). Even when errors or early returns occur, connections are deterministically closed, preventing file descriptor exhaustion across daemon iterations.
- **[Blocker] `update_annotation_file` blindly replaces or searches for literal string `pinned:true`**: Implemented. Strips quoted string literals `r'"(?:\\.|[^"\\])*"'` before checking for unquoted `\bpinned:\s*true\b` (`utils/skills/agy-task-sync/scripts/agy_task_sync.py:165-167`), and uses a quotation-aware substitution callback `_remove_unquoted_pin` to remove `\bpinned:\s*true\b` only outside quoted spans (`utils/skills/agy-task-sync/scripts/agy_task_sync.py:169-175`). Validated with test fixture `title:"A pinned:true task"` preserving title contents exactly.
- Swept and verified with test executions.  [Unverified — no citation]

Handing off to Reviewer for Round 4 review.

### Reviewer · Round 4

swept file: yes

- **[Blocker]** `update_annotation_file` unconditionally overwrites `.pbtxt` files if `apply=True` even when no modifications are made, causing continuous disk writes and creating empty `.pbtxt` files for conversations that didn't have one.
  Observed input: `update_annotation_file("cid", new_title=None, pin=None, apply=True)` on a non-existent or unchanged `.pbtxt` file.
  Affected scope: `utils/skills/agy-task-sync/scripts/agy_task_sync.py:177-184` inside `update_annotation_file`.
  Falsifier: If `new_title` and `pin` are both `None`, `content` is unchanged from what was read, but `f.write(content + "\n")` is executed regardless, modifying the file's `mtime` or creating a file containing just `\n`. Fix by only writing if `content` is not empty and `content != original_content` (where `original_content = f.read().strip()` or `""` if not found).
- **[Blocker]** `sync_conversations` skips unpinning tasks that were manually removed from `app_storage.json` by the user, leaving stale `pinned:true` flags in `.pbtxt` that fight the user's intent on app reload.
  Observed input: `is_pinned = False` and `auto_pin = False` (task was manually unpinned).
  Affected scope: `utils/skills/agy-task-sync/scripts/agy_task_sync.py:266` inside `sync_conversations`.
  Falsifier: `pin=True if (is_pinned or auto_pin) else None` evaluates to `None`, which skips the unpin logic in `update_annotation_file`, leaving any existing `pinned:true` intact. Fix by changing the argument to `pin=(is_pinned or auto_pin)` (or `True if auto_pin else is_pinned`), which will pass `False` and correctly strip the stale flag from `.pbtxt`.
- **[Should]** `get_last_action_from_transcript` lacks type checking for `entry` and `content`, risking an `AttributeError` crash on unexpected JSON lines.
  Observed input: `entry = {"type": "PLANNER_RESPONSE", "content": {"foo": "bar"}}` or `entry = ["a list"]`.
  Affected scope: `utils/skills/agy-task-sync/scripts/agy_task_sync.py:93` and `114` inside `get_last_action_from_transcript`.
  Falsifier: If `entry` is a list, `entry.get("type")` throws `AttributeError`. If `content` is a dictionary, `content.splitlines()` throws `AttributeError: 'dict' object has no attribute 'splitlines'`. Fix by adding `if not isinstance(entry, dict): continue` and guarding string operations with `isinstance(content, str)`.

**VERDICT:** FAIL
**Basis:** Unconditional file writes spam the disk on every background cycle, and ignoring unpinned tasks violates accurate management of the Pinned group.

### Producer · Round 4

- **[Blocker] `update_annotation_file` unconditionally overwrites `.pbtxt` files**: Implemented. Saved `original_content` prior to edits and added guard `if apply and content and content != original_content:` (`utils/skills/agy-task-sync/scripts/agy_task_sync.py:180`). If the content is empty or unchanged from the original disk contents, no disk writes or mtime mutations occur.
- **[Blocker] `sync_conversations` skips unpinning tasks removed from `app_storage.json`**: Implemented. Changed `pin` parameter to `pin=True if auto_pin else is_pinned` (`utils/skills/agy-task-sync/scripts/agy_task_sync.py:269`). When `is_pinned` is False and `auto_pin` is False, `pin=False` is passed to `update_annotation_file`, which cleans up any stale `pinned:true` annotations.
- **[Should] `get_last_action_from_transcript` lacks type checking**: Implemented. Added `if not isinstance(entry, dict): continue` guard (`utils/skills/agy-task-sync/scripts/agy_task_sync.py:93`), guarded tool call items with `isinstance(tc, dict)` (`line 98`), and coerced `content` to string before `splitlines()` (`line 116`).
- Swept and verified with test assertions.

Handing off to Reviewer for Round 5 review.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
