#!/usr/bin/env python3
"""
Antigravity Task Synchronizer (agy_task_sync.py)

Automates task management in Google Antigravity:
1. Auto-renames task titles with today's US date (MM-DD).
2. Updates task previews/descriptions with the last action extracted from transcripts.
3. Manages the Pinned group in app_storage.json and annotations/*.pbtxt.
4. Supports one-shot execution, dry-run, and a 15-minute daemon loop.
"""

import argparse
import datetime
import glob
import json
import os
import re
import sqlite3
import sys
import time
from pathlib import Path

# Canonical paths for Antigravity on macOS
APP_DATA_DIR = Path(os.path.expanduser("~/.gemini/antigravity"))
ELECTRON_STORAGE_PATH = Path(
    os.path.expanduser("~/Library/Application Support/Antigravity/app_storage.json")
)
DB_PATH = APP_DATA_DIR / "conversation_summaries.db"
ANNOTATIONS_DIR = APP_DATA_DIR / "annotations"
BRAIN_DIR = APP_DATA_DIR / "brain"


def get_today_us_date() -> str:
    """Returns today's date formatted as MM-DD."""
    return datetime.datetime.now().strftime("%m-%d")


def load_pinned_ids() -> list[str]:
    """Reads pinned conversation IDs from app_storage.json."""
    if not ELECTRON_STORAGE_PATH.exists():
        return []
    try:
        with open(ELECTRON_STORAGE_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
        pinned = data.get("pinned_conversations_order", [])
        if isinstance(pinned, str):
            pinned = json.loads(pinned)
        return pinned if isinstance(pinned, list) else []
    except Exception as e:
        print(f"[WARN] Failed to read app_storage.json: {e}", file=sys.stderr)
        return []


def save_pinned_ids(pinned_ids: list[str]) -> bool:
    """Saves updated pinned conversation IDs to app_storage.json."""
    if not ELECTRON_STORAGE_PATH.exists():
        return False
    try:
        with open(ELECTRON_STORAGE_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
        data["pinned_conversations_order"] = json.dumps(pinned_ids)
        with open(ELECTRON_STORAGE_PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
        return True
    except Exception as e:
        print(f"[WARN] Failed to write app_storage.json: {e}", file=sys.stderr)
        return False


def get_last_action_from_transcript(conversation_id: str) -> str:
    """Extracts the last meaningful action or output from the transcript."""
    tpath = BRAIN_DIR / conversation_id / ".system_generated" / "logs" / "transcript.jsonl"
    if not tpath.exists():
        return "No transcript recorded"

    try:
        with open(tpath, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except Exception as e:
        return f"Error reading transcript: {e}"

    if not lines:
        return "Empty transcript"

    last_action = None
    # Inspect reverse lines for the latest action
    for line in reversed(lines):
        try:
            entry = json.loads(line)
        except Exception:
            continue

        tool_calls = entry.get("tool_calls")
        if tool_calls and isinstance(tool_calls, list) and len(tool_calls) > 0:
            tc = tool_calls[0]
            args = tc.get("args", {})
            summary = tc.get("toolSummary")
            if not summary and isinstance(args, dict):
                summary = args.get("toolSummary")
            if not summary:
                summary = tc.get("toolAction")
            if not summary and isinstance(args, dict):
                summary = args.get("toolAction")
            if not summary:
                summary = tc.get("name", "Tool call")
            summary = str(summary).strip('"\'')
            last_action = f"[Tool] {summary}"
            break

        step_type = entry.get("type")
        content = entry.get("content", "")
        if step_type == "PLANNER_RESPONSE" and content:
            # First non-empty line of response
            for cl in content.splitlines():
                cl_clean = cl.strip().lstrip(">").lstrip("#").strip()
                if cl_clean:
                    last_action = f"[Response] {cl_clean[:80]}"
                    break
            if last_action:
                break
        elif step_type == "USER_INPUT" and content:
            for cl in content.splitlines():
                cl_clean = cl.strip()
                if cl_clean:
                    last_action = f"[User] {cl_clean[:80]}"
                    break
            if last_action:
                break

    return last_action or "Awaiting instructions"


def format_title_with_date(current_title: str, today_prefix: str) -> str:
    """Ensures title has today's MM-DD prefix, replacing any older MM-DD prefix."""
    # Strip existing date pattern MM-DD or MM/DD
    clean_title = re.sub(r"^\d{2}[-/]\d{2}\s*", "", current_title).strip()
    if not clean_title:
        clean_title = "Untitled Task"
    return f"{today_prefix} {clean_title}"


def update_annotation_file(conversation_id: str, new_title: str | None = None, pin: bool | None = None, apply: bool = False) -> bool:
    """Updates the .pbtxt annotation file for a conversation."""
    pbtxt_path = ANNOTATIONS_DIR / f"{conversation_id}.pbtxt"
    content = ""
    if pbtxt_path.exists():
        try:
            with open(pbtxt_path, "r", encoding="utf-8") as f:
                content = f.read().strip()
        except Exception as e:
            print(f"[WARN] Failed to read {pbtxt_path}: {e}", file=sys.stderr)

    # Update or insert title
    if new_title is not None:
        if re.search(r'title:\s*"[^"]*"', content):
            content = re.sub(r'title:\s*"[^"]*"', f'title:"{new_title}"', content)
        else:
            content = f'title:"{new_title}" {content}'.strip()

    # Update or insert pinned:true
    if pin is True:
        if "pinned:true" not in content:
            content = f"{content} pinned:true".strip()
    elif pin is False:
        content = content.replace("pinned:true", "").strip()

    if apply:
        ANNOTATIONS_DIR.mkdir(parents=True, exist_ok=True)
        try:
            with open(pbtxt_path, "w", encoding="utf-8") as f:
                f.write(content + "\n")
            return True
        except Exception as e:
            print(f"[WARN] Failed to write {pbtxt_path}: {e}", file=sys.stderr)
            return False
    return True


def sync_conversations(
    target_ids: list[str] | None = None,
    only_pinned: bool = True,
    auto_pin: bool = False,
    update_date: bool = True,
    update_desc: bool = True,
    apply: bool = False,
) -> dict:
    """Performs the synchronization across DB, annotations, and app storage."""
    today = get_today_us_date()
    pinned_ids = load_pinned_ids()

    if not DB_PATH.exists():
        print(f"[ERROR] Database not found at {DB_PATH}", file=sys.stderr)
        return {"error": "DB not found"}

    conn = sqlite3.connect(str(DB_PATH), timeout=10.0)
    c = conn.cursor()

    # Select candidates
    if target_ids:
        placeholders = ",".join("?" for _ in target_ids)
        c.execute(
            f"SELECT conversation_id, title, preview, status, last_modified_time FROM conversation_summaries WHERE conversation_id IN ({placeholders})",
            target_ids,
        )
    elif only_pinned:
        if not pinned_ids:
            print("[INFO] No pinned conversations found in app_storage.json.")
            conn.close()
            return {"synced": 0}
        placeholders = ",".join("?" for _ in pinned_ids)
        c.execute(
            f"SELECT conversation_id, title, preview, status, last_modified_time FROM conversation_summaries WHERE conversation_id IN ({placeholders})",
            pinned_ids,
        )
    else:
        # Default: all active conversations modified within the last 48 hours
        c.execute(
            "SELECT conversation_id, title, preview, status, last_modified_time FROM conversation_summaries ORDER BY last_modified_time DESC LIMIT 20"
        )

    rows = c.fetchall()
    results = []

    for row in rows:
        cid, current_title, current_preview, status, last_mod = row
        new_title = format_title_with_date(current_title, today) if update_date else current_title
        last_action = get_last_action_from_transcript(cid) if update_desc else current_preview
        is_pinned = cid in pinned_ids

        changes = {
            "conversation_id": cid,
            "old_title": current_title,
            "new_title": new_title,
            "title_changed": current_title != new_title,
            "old_preview": current_preview,
            "new_preview": last_action,
            "preview_changed": current_preview != last_action,
            "is_pinned": is_pinned,
            "status": status,
        }
        results.append(changes)

        if apply:
            # 1. Update SQLite DB
            if changes["title_changed"] or changes["preview_changed"]:
                c.execute(
                    "UPDATE conversation_summaries SET title=?, preview=? WHERE conversation_id=?",
                    (new_title, last_action, cid),
                )
            # 2. Update .pbtxt annotation
            update_annotation_file(
                cid,
                new_title=new_title if changes["title_changed"] else None,
                pin=True if (is_pinned or auto_pin) else None,
                apply=True,
            )
            # 3. Add to pinned_conversations_order if auto_pin requested
            if auto_pin and cid not in pinned_ids:
                pinned_ids.append(cid)

    if apply:
        conn.commit()
        if auto_pin:
            save_pinned_ids(pinned_ids)
    conn.close()

    return {"results": results, "pinned_count": len(pinned_ids), "applied": apply}


def main():
    parser = argparse.ArgumentParser(
        description="Sync Antigravity task titles with MM-DD dates, update descriptions with last actions, and manage pinned groups."
    )
    parser.add_argument("--apply", action="store_true", help="Apply updates to DB, annotations, and app storage (default is dry-run)")
    parser.add_argument("--all", action="store_true", help="Process all recent conversations, not just pinned ones")
    parser.add_argument("--auto-pin", action="store_true", help="Ensure target conversations are pinned in app_storage and annotations")
    parser.add_argument("--id", action="append", help="Target specific conversation ID(s)")
    parser.add_argument("--no-date", action="store_true", help="Skip renaming titles with MM-DD date")
    parser.add_argument("--no-desc", action="store_true", help="Skip updating previews with last actions")
    parser.add_argument("--list-pinned", action="store_true", help="Inspect and display currently pinned tasks")
    parser.add_argument("--daemon", action="store_true", help="Run continuously in the background every 15 minutes")
    parser.add_argument("--interval", type=int, default=900, help="Interval in seconds for daemon mode (default: 900 = 15m)")

    args = parser.parse_args()

    if args.list_pinned:
        pinned = load_pinned_ids()
        print(f"\n[Pinned Tasks in Antigravity] Total: {len(pinned)}")
        if not pinned:
            print("  (None found)")
            return 0
        conn = sqlite3.connect(str(DB_PATH))
        c = conn.cursor()
        for idx, cid in enumerate(pinned, 1):
            c.execute("SELECT title, preview, status, last_modified_time FROM conversation_summaries WHERE conversation_id=?", (cid,))
            row = c.fetchone()
            title = row[0] if row else "(Unknown)"
            status = row[2] if row else "(Unknown)"
            last_action = get_last_action_from_transcript(cid)
            print(f"  {idx}. [{cid[:8]}] {title}")
            print(f"     Status: {status} | Last action: {last_action}")
        conn.close()
        return 0

    def run_cycle():
        mode_str = "APPLYING" if args.apply else "DRY-RUN"
        print(f"[{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Running Antigravity Task Sync ({mode_str})...")
        res = sync_conversations(
            target_ids=args.id,
            only_pinned=not args.all,
            auto_pin=args.auto_pin,
            update_date=not args.no_date,
            update_desc=not args.no_desc,
            apply=args.apply,
        )
        for item in res.get("results", []):
            cid = item["conversation_id"][:8]
            t_flag = "-> " + item["new_title"] if item["title_changed"] else "(unchanged)"
            p_flag = item["new_preview"]
            print(f"  * [{cid}] Title: {item['old_title']} {t_flag}")
            print(f"             Last Action: {p_flag}")
        if not args.apply:
            print("[INFO] Dry-run complete. Pass --apply to commit changes.")

    if args.daemon:
        print(f"[DAEMON] Starting agy_task_sync daemon every {args.interval}s (15 min). Press Ctrl+C to stop.")
        try:
            while True:
                run_cycle()
                time.sleep(args.interval)
        except KeyboardInterrupt:
            print("\n[DAEMON] Stopped.")
            return 0
    else:
        run_cycle()
        return 0


if __name__ == "__main__":
    sys.exit(main())
