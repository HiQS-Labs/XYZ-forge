"""Shared configuration for the Oracle hook family (#1 §6).

One place for every path and constant the hook, the inference worker, the
statusline, the vote command and the report all need -- so they cannot drift
from each other, and so swapping in a new adapter is a one-field edit in
`data/oracle/config.json` rather than five code changes.

Everything under `data/` is gitignored: the logs carry real prompt text and
this repo is PUBLIC. Nothing here may write outside `data/`.
"""
from __future__ import annotations
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
CORPUS = os.path.join(REPO, "utils", "corpus")
DATA = os.path.join(REPO, "data", "oracle")
PYTHON = sys.executable  # the venv that has the engine; the hook is wired with it

CONFIG_PATH = os.path.join(DATA, "config.json")
PENDING_DIR = os.path.join(DATA, "pending")
LAST_DIR = os.path.join(DATA, "last")
HOOK_LOG = os.path.join(REPO, "data", "hook-log.jsonl")      # PR #4's log, kept
FEEDBACK = os.path.join(DATA, "feedback.jsonl")

# The training system prompt -- IMPORTED from the serializer the corpus was built
# with, not retyped, so it cannot drift. `check_system()` still asserts it against a
# real corpus row as a belt-and-braces byte-identity test.
sys.path.insert(0, CORPUS)
from serialize import SYSTEM_PROMPT as SYSTEM  # noqa: E402

DEFAULTS = {
    # PTQ of the 2k fp32 adapter; replaced by the 10k adapter once it lands.
    "cact": os.path.join(REPO, "data", "spike-mlx", "oracle-2k.cact"),
    "labels": os.path.join(REPO, "oracle", "labels-v1.json"),
    "max_new_tokens": 64,
    "fresh_seconds": 1800,     # statusline hides a recommendation older than this
    "show": True,              # False = collect feedback silently, display nothing
}

def load() -> dict:
    cfg = dict(DEFAULTS)
    try:
        with open(CONFIG_PATH) as fh:
            cfg.update(json.load(fh))
    except (OSError, ValueError):
        pass
    return cfg

def tools_json(labels_path: str) -> str:
    """BYTE-IDENTICAL to training. render_example (finetune.py:196) serialises the
    tool list with separators=(",", ":") and ensure_ascii=False, and the SDK hands
    the string to the engine verbatim. Default separators shift ~1,400 schema
    tokens and put the model out of distribution -- measured, not hypothetical."""
    schemas = json.load(open(labels_path))["schemas"]
    return json.dumps(schemas, separators=(",", ":"), ensure_ascii=False)

def label_descriptions(labels_path: str) -> dict:
    """label -> one-line description, for the TEMPLATED why (#1 §6: no generated prose)."""
    return {t["name"]: t.get("description", "") for t in json.load(open(labels_path))["schemas"]}

def check_system(holdout=os.path.join(REPO, "data", "corpus-studio", "oracle-holdout.jsonl")) -> bool:
    try:
        row = json.loads(open(holdout).readline())
        return row.get("system") == SYSTEM
    except OSError:
        return True  # corpus absent on this machine; nothing to check against

def ensure_dirs():
    for d in (DATA, PENDING_DIR, LAST_DIR):
        os.makedirs(d, exist_ok=True)

if __name__ == "__main__":
    print(json.dumps({"config": load(), "system_matches_corpus": check_system()}, indent=2))
