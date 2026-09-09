"""The ONE `query` serializer shared by training and the end-of-turn hook (#1 §3, §6).

#1 §6: "A mismatch between hook-time and training-time serialization is the single
most likely cause of a good model looking useless in production -- build them from one
shared function, not two implementations." This module is that function. The corpus
builder (`build_oracle_jsonl.py`) and the Stop hook (`utils/hooks/oracle_stop_hook.py`)
both call `serialize_query`; neither has a format of its own. `tests/test_serialize.py`
asserts the two paths produce byte-identical queries for the same steps.

FORMAT `q1` -- designed so `reasoning` can cite a span inside it (#1 §3)

    [oracle-q1]
    REQUEST: <most recent user request, truncated>
    RECENT ACTIONS (oldest->newest): read_file, search_code, git_inspect
    LAST: git_inspect

Every line is a citable anchor: `REQUEST:`, `RECENT ACTIONS`, `LAST:`. The templated
reasoning cites `LAST:`; a future richer reasoning can cite `REQUEST:` spans. Labels are
v1 names from `taxonomy.LABELS_V1`, never raw tool names, so the model sees the same
vocabulary it must emit. The `[oracle-q1]` marker is a version stamp: if the hook and
the trainer ever disagree on format, the mismatch is detectable in the data rather than
discovered as a silently bad model.

TOKEN BUDGET -- measured, not assumed (2026-09-07, real Needle tokenizer)

    44 full label schemas   1,383 tokens   <-- exceeds finetune's default --max-len 1024 alone
    name+description only   1,080 tokens
    names only                435 tokens
    sample q1 query            83 tokens

`finetune._encode` truncates `ids[:max_len]` from the END, i.e. the TARGET is cut first
and the row trains toward nothing, silently. So the schemas are kept in full (the shape
the base model was trained on) and training runs at `--max-len 2048`, the architecture's
`max_seq_len`. `build_oracle_jsonl.py --check-max-len` refuses any row that would
truncate. Do not shrink schemas to fit 1024; raise the cap instead.
"""
from __future__ import annotations
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import taxonomy as tx  # noqa: E402

QUERY_FORMAT_VERSION = "q1"
QUERY_MARKER = f"[oracle-{QUERY_FORMAT_VERSION}]"
DEFAULT_CONTEXT_STEPS = 12
DEFAULT_USER_CHARS = 600
TRAIN_MAX_LEN = 2048  # architecture max_seq_len; finetune's default 1024 truncates rows

SYSTEM_PROMPT = ("You are the SDLC Oracle. Given the operator's request and the recent "
                 "actions, choose the single best next action label.")

_REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SCHEMAS_PATH = os.path.join(_REPO_ROOT, "oracle", "labels-v1.json")


def load_schemas(path: str = SCHEMAS_PATH) -> list[dict]:
    """The §1 cross-repo contract, as the `tools` list every row carries."""
    with open(path) as fh:
        doc = json.load(fh)
    schemas = doc["schemas"]
    if doc.get("label_set_version") != tx.LABEL_SET_VERSION:
        raise RuntimeError(f"labels-v1.json is {doc.get('label_set_version')} but "
                           f"taxonomy.py is {tx.LABEL_SET_VERSION}; regenerate the schema")
    return schemas


def _clean(text: str) -> str:
    # One line, no format-breaking newlines; whitespace runs collapsed.
    return " ".join((text or "").split())


def serialize_query(recent_user_request: str, prior_actions: list[str],
                    context_steps: int = DEFAULT_CONTEXT_STEPS,
                    user_chars: int = DEFAULT_USER_CHARS) -> str:
    """Render the model input. Deterministic; identical for training and the hook."""
    if not prior_actions:
        raise ValueError("a query needs at least one prior action (LAST: must exist)")
    for a in prior_actions:
        if a not in tx.LABELS_V1 and a != "unmapped":
            raise ValueError(f"prior action {a!r} is not a v1 label")
    window = prior_actions[-context_steps:]
    request = _clean(recent_user_request)[:user_chars]
    return (f"{QUERY_MARKER}\n"
            f"REQUEST: {request}\n"
            f"RECENT ACTIONS (oldest->newest): {', '.join(window)}\n"
            f"LAST: {window[-1]}")


def templated_reasoning(prior_actions: list[str], label: str) -> str:
    """#1 §6: templated one-line why, no generated prose. Cites the `LAST:` span."""
    return f"LAST: {prior_actions[-1]} -> {label}"


def to_finetune_row(pair: dict, schemas: list[dict],
                    context_steps: int = DEFAULT_CONTEXT_STEPS,
                    user_chars: int = DEFAULT_USER_CHARS) -> dict:
    """Convert one extractor pair into the row `needle/model/finetune.py` consumes.

    `answers` is `[{"name": label}]` -- labels take no arguments (§1 output contract).
    `no_action` becomes `"answers": []`, the off-topic/abstain slice (#1 §3).
    """
    label = pair["label"]
    if label not in tx.LABELS_V1:
        raise ValueError(f"pair label {label!r} is not a v1 label")
    query = serialize_query(pair.get("recent_user_request", ""), pair["prior_actions"],
                            context_steps, user_chars)
    answers = [] if label == "no_action" else [{"name": label}]
    return {
        "query": query,
        "tools": schemas,
        "answers": answers,
        "reasoning": templated_reasoning(pair["prior_actions"], label),
        "system": SYSTEM_PROMPT,
    }
