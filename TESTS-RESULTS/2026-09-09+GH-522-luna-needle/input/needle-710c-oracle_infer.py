#!/usr/bin/env python3
"""Detached inference worker for the Oracle hook.

The Stop hook must return in well under a second or the turn is felt to hang.
The native engine costs ~4 s to initialise plus ~1-2 s per completion. So the
hook writes `pending/<session>.json` and spawns THIS, detached, and exits; this
runs the engine and writes `last/<session>.json`, which the statusline reads on
its next refresh. Nothing in the turn waits on the model.

Usage: oracle_infer.py <session_id>
"""
from __future__ import annotations
import json, os, sys, time, warnings

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import oracle_config as C

def main() -> int:
    if len(sys.argv) < 2:
        return 0
    sid = sys.argv[1]
    pending = os.path.join(C.PENDING_DIR, f"{sid}.json")
    try:
        req = json.load(open(pending))
    except (OSError, ValueError):
        return 0
    cfg = C.load()
    os.environ.setdefault("HF_HUB_DISABLE_XET", "1"); os.environ.setdefault("NEEDLE_TELEMETRY", "0")
    warnings.filterwarnings("ignore")
    t0 = time.perf_counter()
    rec = {"session_id": sid, "prompt_id": req.get("prompt_id"), "ts": req.get("ts"),
           "history_len": req.get("history_len"), "query": req.get("query"),
           "cact": os.path.basename(cfg["cact"]), "recommendations": [], "reasoning": None,
           "engine": {}, "ms": None}
    try:
        import needle
        agent = needle.Needle(tools=C.tools_json(cfg["labels"]), system=C.SYSTEM, weights=cfg["cact"])
        try:
            out = agent.complete(req["query"], max_new_tokens=int(cfg.get("max_new_tokens", 64)))
        finally:
            try: agent.close()
            except Exception: pass
        desc = C.label_descriptions(cfg["labels"])
        calls = out.get("function_calls") or []
        # v0 is top-1: the engine returns one call or an abstention ([]). The
        # templated why is the label's own description -- never generated prose.
        rec["recommendations"] = [{"label": c["name"], "why": desc.get(c["name"], "")}
                                  for c in calls if c.get("name") in desc][:3]
        rec["reasoning"] = out.get("reasoning")
        rec["engine"] = {k: out.get(k) for k in ("type", "prefill_tps", "decode_tps", "validation")}
    except Exception as exc:
        rec["error"] = f"{type(exc).__name__}: {exc}"[:300]
    rec["ms"] = round((time.perf_counter() - t0) * 1000)
    C.ensure_dirs()
    tmp = os.path.join(C.LAST_DIR, f"{sid}.json.tmp")
    with open(tmp, "w") as fh:
        json.dump(rec, fh, ensure_ascii=False)
    os.replace(tmp, os.path.join(C.LAST_DIR, f"{sid}.json"))
    try: os.remove(pending)
    except OSError: pass
    # PR #4's log, now with the recommendations field filled in.
    with open(C.HOOK_LOG, "a") as fh:
        fh.write(json.dumps({"ts": rec["ts"], "session_id": sid, "prompt_id": rec["prompt_id"],
                             "query": rec["query"], "recommendations": rec["recommendations"],
                             "ms": rec["ms"], "cact": rec["cact"]}, ensure_ascii=False) + "\n")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
