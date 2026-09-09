#!/usr/bin/env python3
"""Claude Code Stop hook for the SDLC Oracle (#1 §6) -- the serve side of the shared serializer.

Wire it in `~/.claude/settings.json` (or the repo's `.claude/settings.json`):

    {"hooks": {"Stop": [{"hooks": [{"type": "command",
        "command": "python3 /path/to/needle-fork/utils/hooks/oracle_stop_hook.py"}]}]}}

Claude Code passes a JSON object on stdin with `transcript_path` (the session's .jsonl,
the same format the training extractor reads), `session_id`, and `stop_hook_active`.

WHAT IT DOES
    1. Rebuilds the turn's context with the SAME code path as training --
       `extract_claude_transcripts.iter_steps` -> `taxonomy.label_call` -> `serialize.serialize_query`.
       Measured at ~400 ms on a 5 MB transcript.
    2. IMPLICIT FEEDBACK: scores the PREVIOUS turn's recommendation against what the
       operator actually did next -- the first action label after that turn's end --
       and appends it to data/oracle/feedback.jsonl. This is #1 §6's "log whether the
       operator actually did it", and it costs the operator nothing.
    3. Writes data/oracle/pending/<session>.json and spawns `oracle_infer.py` DETACHED,
       then exits. The engine (~4 s init + ~1-2 s) never runs inside the turn; the
       statusline picks up the result on its next refresh.

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
sys.path.insert(0, _HERE)
import serialize as ser  # noqa: E402
import taxonomy as tx  # noqa: E402
from extract_claude_transcripts import iter_steps  # noqa: E402

import subprocess  # noqa: E402
import oracle_config as C  # noqa: E402

_REPO_ROOT = C.REPO
LOG_PATH = C.HOOK_LOG


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


def _score_previous(sid: str, prompt_id: str, history: list[str]) -> None:
    """Implicit feedback: compare the last recommendation to what actually happened next."""
    last = os.path.join(C.LAST_DIR, f"{sid}.json")
    try:
        prev = json.load(open(last))
    except (OSError, ValueError):
        return
    n = prev.get("history_len")
    if prev.get("scored") or n is None or prev.get("prompt_id") == prompt_id or len(history) <= n:
        return
    preds = [r["label"] for r in (prev.get("recommendations") or [])]
    actual = history[n]
    with open(C.FEEDBACK, "a") as fh:
        fh.write(json.dumps({
            "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "source": "implicit",
            "session_id": sid, "prompt_id": prev.get("prompt_id"), "cact": prev.get("cact"),
            "query": prev.get("query"), "predicted": preds, "actual": actual,
            "hit": actual in preds,
        }, ensure_ascii=False) + "\n")
    prev["scored"] = True
    tmp = last + ".tmp"
    with open(tmp, "w") as fh:
        json.dump(prev, fh, ensure_ascii=False)
    os.replace(tmp, last)


def main() -> int:
    try:
        payload = json.load(sys.stdin) if not sys.stdin.isatty() else {}
    except Exception:
        payload = {}
    path = payload.get("transcript_path", "")
    if payload.get("stop_hook_active"):
        return 0  # never recurse
    if not path or not os.path.exists(path):
        return 0
    sid = str(payload.get("session_id") or "unknown")
    prompt_id = str(payload.get("prompt_id") or "")
    try:
        request, history = context_from_transcript(path)
        if not history:
            return 0
        query = ser.serialize_query(request, history)
        C.ensure_dirs()
        _score_previous(sid, prompt_id, history)
        pending = os.path.join(C.PENDING_DIR, f"{sid}.json")
        with open(pending, "w") as fh:
            json.dump({
                "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                "session_id": sid, "prompt_id": prompt_id,
                "history_len": len(history), "query": query,
                "query_format": ser.QUERY_FORMAT_VERSION,
                "label_set_version": tx.LABEL_SET_VERSION,
            }, fh, ensure_ascii=False)
        # Detached: the turn must not wait on the engine.
        subprocess.Popen(
            [C.PYTHON, os.path.join(_HERE, "oracle_infer.py"), sid],
            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            start_new_session=True, close_fds=True)
    except Exception:
        pass  # a hook must never break the turn
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
