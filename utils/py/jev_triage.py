#!/usr/bin/env python3
"""jev_triage.py — GH-712: TypeSafe Jev as an ATE triage classifier, offline replays first.

Jev answers typed questions (Choice / Score) over a `state` and returns calibrated probabilities;
it does not generate text, so the Gemma prompt's `likely_cause` field is `None` on this path.
Three structured fields are asked in one request per row:

    status    Choice  pass | fail
    severity  Choice  none | low | medium | high | critical
    category  Choice  crash | auth_failure | bad_diff | timeout | no_edit | config_error |
                      env_failure | env_missing | ok

CLI (offline replays; no LM Studio, no live ATE run):

  jev_triage.py benchmark --rows FILE --out DIR [--key-file F | env TYPESAFE_API_KEY] [--mock-responses F]
      FILE = calibrate_tier1.py --emit-benchmark rows {label, exit_code, signal, stderr, duration_ms}.
      Reports Jev pass/fail confusion vs label (FN = label fail -> jev pass, FP = label pass -> jev fail,
      the calibrate_tier1.score definitions) and agreement with tier1_classify.
  jev_triage.py errorlog --log FILE --out DIR [...]
      FILE = an ATE error_log.jsonl. Reports per-field agreement with each row's stored Gemma
      `classification` (status / severity / category).

Both write <out>/rows.jsonl (one row per input: verdicts, confidence, request/response sha256, never
stderr text or the key) and <out>/summary.json. Empty input exits 2. `--mock-responses F` replays a
JSON list of canned response bodies in order instead of calling the API (the test path).
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import time
import urllib.error
import urllib.request
from collections import Counter
from typing import Any, Dict, List, Optional

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
from adaptive_ate import tier1_classify  # noqa: E402

ENDPOINT = "https://api.typesafe.ai/v1/systemone"
MODEL = "jev-1.13.0"
TAIL = 1500  # same stdout/stderr tail the Gemma CLASSIFY_PROMPT sends
CATEGORIES = {
    "crash": "the harness crashed: a Python traceback, a fatal signal, or an internal error",
    "auth_failure": "an authentication or authorization error: missing/invalid API key, 401/403, login required",
    "bad_diff": "the harness produced a malformed or unusable diff/edit",
    "timeout": "the run timed out",
    "no_edit": "exit code 0 but no edit was applied when one was expected",
    "config_error": "a configuration, flag, or argument error: usage message, unknown option, bad config value",
    "env_failure": "the environment failed: missing binary, dependency import error, unreachable service",
    "env_missing": "a required environment variable or file is missing",
    "ok": "the run succeeded",
}
EDIT_RULE_EXPECTS = ("This run EXPECTS an edit: edit_applied=false with exit_code 0 means no change was produced, "
                     "which is a fail (status fail, category no_edit, severity high) even though nothing crashed.")
EDIT_RULE_DIAGNOSTIC = ("This run is a DIAGNOSTIC probe that is not expected to change the tree: edit_applied=false "
                        "with exit_code 0 is a pass (status pass, category ok, severity none).")
Row = Dict[str, Any]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def canonical(obj: Any) -> bytes:
    return json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def build_questions(expects_edits: bool = True) -> Dict[str, Any]:
    rule = EDIT_RULE_EXPECTS if expects_edits else EDIT_RULE_DIAGNOSTIC
    evidence = ("Only call it a fail on concrete evidence: a non-zero exit_code, a traceback, an explicit "
                "error/auth-failure message, or a malformed/no-op edit. A cosmetic warning with exit_code 0 "
                "and a successful edit is not a failure. " + rule)
    return {
        "status": {"type": "choice", "instructions": "Did this test run pass or fail? " + evidence,
                   "criteria": {"pass": "the run succeeded", "fail": "the run failed"}},
        "severity": {"type": "choice",
                     "instructions": "How severe is the outcome of this run? A non-zero exit_code is REQUIRED for critical. " + rule,
                     "criteria": {"none": "no failure", "low": "cosmetic problem only", "medium": "degraded but usable",
                                  "high": "expected result not produced (for example no edit applied)",
                                  "critical": "crash or hard failure with a non-zero exit code"}},
        "category": {"type": "choice", "instructions": "Which category best describes the outcome of this run? " + evidence,
                     "criteria": dict(CATEGORIES)},
    }


def build_state(command: str, exit_code: int, edit_applied: Optional[bool], stdout: str, stderr: str,
                expects_edits: bool = True, signal: int = 0, duration_ms: Optional[float] = None) -> Dict[str, Any]:
    state = {"command": command, "exit_code": int(exit_code), "signal": int(signal or 0),
             "edit_applied": edit_applied, "expects_edits": bool(expects_edits),
             "stdout_tail": (stdout or "")[-TAIL:], "stderr_tail": (stderr or "")[-TAIL:]}
    if duration_ms is not None:
        state["duration_ms"] = float(duration_ms)
    return state


def _post(body: Dict[str, Any], key: str, endpoint: str, attempts: int = 3, sleep=time.sleep) -> bytes:
    req = urllib.request.Request(endpoint, data=canonical(body), method="POST",
                                 headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
    for attempt in range(1, attempts + 1):
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                return resp.read()
        except urllib.error.HTTPError as err:
            retry_after = err.headers.get("retry-after") if err.headers else None
            if err.code in (429, 500, 502, 503, 504) and attempt < attempts:
                sleep(float(retry_after) if retry_after else 2.0)
                continue
            raise
    raise RuntimeError("unreachable")


class Client:
    """Live Jev client, or an ordered canned-response replay when `mock_responses` is given."""

    def __init__(self, key: str = "", endpoint: str = ENDPOINT, model: str = MODEL, mock_responses: Optional[List[Any]] = None):
        self.key, self.endpoint, self.model = key, endpoint, model
        self.mock = list(mock_responses) if mock_responses is not None else None
        self.input_tokens = 0
        self.models_seen: Counter = Counter()

    def classify(self, state: Dict[str, Any], expects_edits: bool = True) -> Dict[str, Any]:
        body = {"state": state, "model": self.model, "questions": build_questions(expects_edits)}
        raw_req = canonical(body)
        if self.mock is not None:
            if not self.mock:
                raise RuntimeError("mock responses exhausted")
            raw_resp = canonical(self.mock.pop(0))
        else:
            if not self.key:
                raise SystemExit("no API key: set TYPESAFE_API_KEY or pass --key-file")
            raw_resp = _post(body, self.key, self.endpoint)
        parsed = json.loads(raw_resp)
        answers = parsed["answers"]
        sev = answers["severity"]
        self.input_tokens += int((parsed.get("usage") or {}).get("input_tokens", 0))
        self.models_seen[parsed.get("model")] += 1
        return {
            "status": answers["status"]["choice"],
            "severity": sev["choice"],
            "category": answers["category"]["choice"],
            "likely_cause": None,
            "classifier": "jev",
            "model": parsed.get("model"),
            "confidence": {"status": answers["status"].get("confidence"), "severity": sev.get("confidence"),
                           "category": answers["category"].get("confidence")},
            "probabilities": {"status": answers["status"].get("probabilities"), "category": answers["category"].get("probabilities"),
                              "severity": sev.get("probabilities")},
            "request_sha256": sha256(raw_req), "response_sha256": sha256(raw_resp),
        }


def read_jsonl(path: str) -> List[Row]:
    with open(path, encoding="utf-8") as fh:
        return [json.loads(line) for line in fh if line.strip()]


def replay_benchmark(rows: List[Row], client: Client) -> Dict[str, Any]:
    if not rows:
        raise ValueError("empty benchmark")
    out_rows, fn, fp = [], 0, 0
    confusion = {"pass": Counter(), "fail": Counter()}
    tier1_agreement = Counter()
    p_fail = {"pass": [], "fail": []}  # P(fail) per label, for the recorded FN=0 threshold
    for i, r in enumerate(rows):
        exit_code, signal, stderr, dur = int(r.get("exit_code", 0)), int(r.get("signal", 0)), str(r.get("stderr", "")), float(r.get("duration_ms", 0.0))
        t1, _ = tier1_classify(exit_code, signal, stderr, dur)
        state = build_state(r.get("command", "<benchmark row>"), exit_code, None, "", stderr, expects_edits=False, signal=signal, duration_ms=dur)
        verdict = client.classify(state, expects_edits=False)
        label = r["label"]
        confusion[label][verdict["status"]] += 1
        p_fail[label].append(float((verdict["probabilities"]["status"] or {}).get("fail", 1.0 if verdict["status"] == "fail" else 0.0)))
        if label == "fail" and verdict["status"] == "pass":
            fn += 1
        if label == "pass" and verdict["status"] == "fail":
            fp += 1
        tier1_agreement["anomaly" if t1 == "anomaly" else ("agree" if t1 == verdict["status"] else "disagree")] += 1
        out_rows.append({"index": i, "label": label, "tier1": t1, **{k: verdict[k] for k in
                         ("status", "severity", "category", "model", "confidence", "request_sha256", "response_sha256")}})
    n_fail = sum(1 for r in rows if r["label"] == "fail")
    # Highest decision threshold on P(fail) at which every known-fail row is still called fail (GH-712 QA r1),
    # and the FP count that threshold would produce on the known-pass rows. One recorded number, no tuning.
    fn_zero_threshold = min(p_fail["fail"]) if p_fail["fail"] else None
    fp_at_threshold = sum(1 for p in p_fail["pass"] if fn_zero_threshold is not None and p >= fn_zero_threshold)
    summary = {"rows": len(rows), "false_negatives": fn, "false_positives": fp,
               "false_negative_pct": round(100.0 * fn / max(1, n_fail), 2),
               "confusion": {k: dict(v) for k, v in confusion.items()},
               "tier1_agreement": dict(tier1_agreement), "fn_floor_met": fn == 0,
               "fn_zero_threshold": fn_zero_threshold, "false_positives_at_fn_zero_threshold": fp_at_threshold}
    return {"summary": summary, "rows": out_rows}


def replay_errorlog(rows: List[Row], client: Client) -> Dict[str, Any]:
    if not rows:
        raise ValueError("empty error log")
    out_rows = []
    agree = {"status": 0, "severity": 0, "category": 0}
    pairs = {"status": Counter(), "severity": Counter(), "category": Counter()}
    for i, r in enumerate(rows):
        gemma = r.get("classification") or {}
        expects = bool((r.get("variation") or {}).get("expects_edits", True))
        state = build_state(r.get("command", ""), int(r.get("exit_code", 0)), r.get("edited"), r.get("stdout", ""), r.get("stderr", ""), expects_edits=expects)
        verdict = client.classify(state, expects_edits=expects)
        for field in agree:
            g, j = gemma.get(field), verdict[field]
            pairs[field][f"{g}->{j}"] += 1
            if g == j:
                agree[field] += 1
        out_rows.append({"index": i, "run_id": r.get("run_id"), "gemma": {k: gemma.get(k) for k in agree},
                         **{k: verdict[k] for k in ("status", "severity", "category", "model", "confidence", "request_sha256", "response_sha256")}})
    summary = {"rows": len(rows), "agreement": {k: {"n": v, "pct": round(100.0 * v / len(rows), 2)} for k, v in agree.items()},
               "pairs": {k: dict(v) for k, v in pairs.items()}}
    return {"summary": summary, "rows": out_rows}


def write_out(out_dir: str, result: Dict[str, Any], client: Client, kind: str) -> None:
    os.makedirs(out_dir, exist_ok=True)
    result["summary"].update({"kind": kind, "model_requested": client.model, "models_seen": dict(client.models_seen),
                              "input_tokens": client.input_tokens, "mock": client.mock is not None})
    with open(os.path.join(out_dir, "rows.jsonl"), "w", encoding="utf-8") as fh:
        for row in result["rows"]:
            fh.write(json.dumps(row, sort_keys=True) + "\n")
    with open(os.path.join(out_dir, "summary.json"), "w", encoding="utf-8") as fh:
        json.dump(result["summary"], fh, indent=2, sort_keys=True)
        fh.write("\n")


def make_client(a: argparse.Namespace) -> Client:
    mock = None
    if a.mock_responses:
        with open(a.mock_responses, encoding="utf-8") as fh:
            mock = json.load(fh)
    key = os.environ.get("TYPESAFE_API_KEY", "")
    if a.key_file:
        with open(a.key_file, encoding="utf-8") as fh:
            key = fh.read().strip()
    return Client(key=key, endpoint=os.environ.get("TYPESAFE_API_URL", ENDPOINT), model=a.model, mock_responses=mock)


def main(argv: Optional[List[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="GH-712 Jev triage replays")
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name, flag in (("benchmark", "--rows"), ("errorlog", "--log")):
        p = sub.add_parser(name)
        p.add_argument(flag, dest="input", required=True)
        p.add_argument("--out", required=True)
        p.add_argument("--model", default=MODEL)
        p.add_argument("--key-file")
        p.add_argument("--mock-responses", help="JSON list of canned response bodies, replayed in order (tests)")
    a = ap.parse_args(argv)
    rows = read_jsonl(a.input)
    if not rows:
        print(f"jev_triage: {a.input} has no rows", file=sys.stderr)
        return 2
    client = make_client(a)
    result = replay_benchmark(rows, client) if a.cmd == "benchmark" else replay_errorlog(rows, client)
    write_out(a.out, result, client, a.cmd)
    print(json.dumps(result["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
