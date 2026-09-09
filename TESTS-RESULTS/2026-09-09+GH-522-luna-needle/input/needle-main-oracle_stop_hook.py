#!/usr/bin/env python3
"""Claude Code Stop hook for the SDLC Oracle (#1 §6) -- the serve side of the shared serializer.

Wire it in `~/.claude/settings.json` (or the repo's `.claude/settings.json`):

    {"hooks": {"Stop": [{"hooks": [{"type": "command",
        "command": "python3 /path/to/needle-fork/utils/hooks/oracle_stop_hook.py"}]}]}}

Claude Code passes a JSON object on stdin with `transcript_path` (the session's .jsonl,
the same format the training extractor reads), `session_id`, and `stop_hook_active`.

WHAT IT DOES TODAY
    Rebuilds the turn's context with the SAME code path as training --
    `extract_claude_transcripts.iter_steps` -> `taxonomy.label_call` -> `serialize.serialize_query`
    -- and appends the query to `data/hook-log.jsonl` with a timestamp and session id.
    It does NOT call a model yet: no adapter has been trained. Wiring the model in is a
    one-function change here once §4 produces an adapter; the serialization, the part
    §6 says is most likely to go wrong, is finished and tested now.

WHAT IT MUST NEVER DO
    Block the turn (always exit 0), print prose into the transcript, or write anywhere
    but data/ (gitignored -- the log carries real prompt text and this repo is PUBLIC).

Latency budget (#1 §6): measured and recorded below on each run as `ms`.
"""
from __future__ import annotations
import json
import os
import sys
import time

_HERE = os.path.dirname(os.path.abspath(__file__))
_CORPUS = os.path.join(_HERE, "..", "corpus")
sys.path.insert(0, _CORPUS)
import serialize as ser  # noqa: E402
import taxonomy as tx  # noqa: E402
from extract_claude_transcripts import iter_steps  # noqa: E402

_REPO_ROOT = os.path.abspath(os.path.join(_HERE, "..", ".."))
LOG_PATH = os.path.join(_REPO_ROOT, "data", "hook-log.jsonl")


def context_from_transcript(path: str) -> tuple[str, list[str]]:
    """(recent_user_request, prior_action_labels) from a live transcript.

    Identical labelling to training: every tool_use goes through `taxonomy.label_call`.
    """
    recent_user, history = "", []
    for step in iter_steps(path):
        if step[0] == "user":
            recent_user = step[1]
            continue
        _, tool, tool_input = step
        label, _ = tx.label_call(tool, tool_input)
        history.append(label)
    return recent_user, history


def main() -> int:
    t0 = time.perf_counter()
    try:
        payload = json.load(sys.stdin) if not sys.stdin.isatty() else {}
    except Exception:
        payload = {}
    path = payload.get("transcript_path", "")
    if payload.get("stop_hook_active"):
        return 0  # never recurse
    if not path or not os.path.exists(path):
        return 0
    try:
        request, history = context_from_transcript(path)
        if not history:
            return 0
        query = ser.serialize_query(request, history)
        os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
        with open(LOG_PATH, "a") as fh:
            fh.write(json.dumps({
                "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                "session_id": payload.get("session_id"),
                "query_format": ser.QUERY_FORMAT_VERSION,
                "label_set_version": tx.LABEL_SET_VERSION,
                "query": query,
                "recommendations": None,  # filled once an adapter exists (#1 §4/§6)
                "ms": round((time.perf_counter() - t0) * 1000, 1),
            }, ensure_ascii=False) + "\n")
    except Exception:
        pass  # a hook must never break the turn
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
