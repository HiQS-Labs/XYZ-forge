#!/usr/bin/env python3
"""GH-1279 Stage A manual controls for the Codex decision adapter (no suite, GH-831).

Run from the root of a disposable full clone of the task branch:
    PYTHONDONTWRITEBYTECODE=1 python3 TESTS-RESULTS/2026-10-30+GH-1279/gh1279-controls.py
A stub CODEX_BIN stands in for the CLI so every adapter classification is exercised without a
model call. Prints one PASS/FAIL line per control and writes controls.json beside this file.
"""
from __future__ import annotations

import hashlib
import importlib.util
import json
import os
import shutil
import sqlite3
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
HARNESS = ROOT / "utils" / "py" / "harness.py"
RUNS = ROOT / "temp" / "factory-primitive"
PROBE = HERE / "containment-probe"
TAG = "gh1279-ctl"

STUB = r'''#!/usr/bin/env python3
import json, os, select, sys, time
mode = os.environ["STUB_MODE"]
with open(os.environ["STUB_LOG"], "a") as fh:
    fh.write(json.dumps({"mode": mode, "argv_len": len(sys.argv), "prompt_head": sys.argv[-1][:40],
                         "prompt_has_snapshot": "Snapshot (JSON):" in sys.argv[-1],
                         "effort": [a for a in sys.argv if a.startswith("model_reasoning_effort=")]}) + "\n")
out = sys.argv[sys.argv.index("-o") + 1]
prompt = sys.argv[-1]
snap = json.loads(prompt.split("Snapshot (JSON):\n", 1)[1])
first = snap["inbox"][0]["id"] if snap["inbox"] else "none"
def say(text, events=None):
    for e in (events or [{"type": "thread.started"}, {"type": "turn.started"},
                         {"type": "item.completed", "item": {"type": "agent_message", "text": text}},
                         {"type": "turn.completed"}]):
        print(json.dumps(e))
    open(out, "w").write(text)
good = {"tool": "plan-draft", "args": {"inbox_id": first}, "reason": "stub", "confidence": 1}
if mode == "ok": say(json.dumps(good))
elif mode == "malformed": say("{not json")
elif mode == "nonobject": say("[1]")
elif mode == "tool_list": say(json.dumps({"tool": [], "args": {}, "reason": "r", "confidence": 1}))
elif mode == "id_list": say(json.dumps({"tool": "plan-draft", "args": {"inbox_id": []}, "reason": "r", "confidence": 1}))
elif mode == "ids_dict": say(json.dumps({"tool": "summarize", "args": {"inbox_ids": [{}]}, "reason": "r", "confidence": 1}))
elif mode == "disallowed": say(json.dumps({"tool": "erase", "args": {}, "reason": "r", "confidence": 1}))
elif mode == "injection": say(json.dumps({"tool": "plan-draft", "args": {"inbox_id": "nonexistent"}, "reason": "r", "confidence": 1}))
elif mode == "toolevent": say(json.dumps(good), [{"type": "item.started", "item": {"type": "command_execution"}}])
elif mode == "timeout": time.sleep(60)
elif mode == "ratelimit": print("429 Too Many Requests: usage limit reached", file=sys.stderr); sys.exit(1)
elif mode == "exit1": print("boom", file=sys.stderr); sys.exit(1)
elif mode == "empty": say("", [{"type": "turn.completed"}])
elif mode == "stdin":
    ready = select.select([sys.stdin], [], [], 0.5)[0]
    data = sys.stdin.read() if ready else ""
    say(json.dumps(good) if data.strip() else "")
elif mode.startswith("replay:"):
    lines = open(mode.split(":", 1)[1]).read().splitlines()
    msgs = [json.loads(l)["item"]["text"] for l in lines if '"agent_message"' in l]
    for l in lines: print(l)
    open(out, "w").write(msgs[-1])
'''

results: list[dict] = []


def record(name: str, ok: bool, detail: str) -> None:
    results.append({"control": name, "pass": bool(ok), "detail": detail})
    print(("PASS " if ok else "FAIL ") + name + " :: " + detail, flush=True)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(args: list[str], env: dict | None = None) -> subprocess.CompletedProcess:
    e = dict(os.environ, PYTHONDONTWRITEBYTECODE="1", **(env or {}))
    return subprocess.run([sys.executable, str(HARNESS), "factory-primitive", *args], cwd=ROOT, env=e,
                          capture_output=True, text=True, timeout=300)


def fresh(name: str, limit: int = 3, *, adapter: str = "codex", timeout: str = "3", cap: str = "0.9",
          call: str = "0.01") -> tuple[str, Path]:
    rr = f"temp/factory-primitive/{TAG}-{name}"
    shutil.rmtree(ROOT / rr, ignore_errors=True)
    extra = ["--adapter", adapter] + (["--codex-model", "stub-model", "--adapter-timeout", timeout]
                                      if adapter == "codex" else [])
    p = run(["--run-root", rr, "init", "--from-prs", "--limit", str(limit), "--daily-cap", cap,
             "--max-call-cost", call, *extra])
    assert p.returncode == 0, p.stderr
    return rr, ROOT / rr / "instances" / "C"


def tick(rr: str, slot: int, mode: str, log: Path, fault: str = "") -> subprocess.CompletedProcess:
    env = {"CODEX_BIN": str(STUBFILE), "STUB_MODE": mode, "STUB_LOG": str(log)}
    return run(["--run-root", rr, "tick", "--slot", str(slot), *(["--fault", fault] if fault else [])], env)


def inspect(inst: Path, slot: int = 1) -> dict:
    conn = sqlite3.connect(inst / "state.db")
    conn.row_factory = sqlite3.Row
    tid = f"slot_{slot:03d}"
    dec = conn.execute("SELECT status,rejected_reason,validated_json FROM decisions WHERE tick_id=?", (tid,)).fetchone()
    res = conn.execute("SELECT status,billing_status,actual_cost FROM reservations WHERE tick_id=?", (tid,)).fetchone()
    ev = [json.loads(r["json"]) for r in conn.execute("SELECT json FROM events WHERE tick_id=? AND stage='evaluate'", (tid,))]
    tick_row = conn.execute("SELECT status FROM ticks WHERE tick_id=?", (tid,)).fetchone()
    tr = inst / "telemetry" / "transcripts" / f"{tid}.json"
    transcript = json.loads(tr.read_text()) if tr.exists() else {}
    conn.close()
    return {"decision": dict(dec) if dec else None, "reservation": dict(res) if res else None,
            "evaluate": ev[0] if ev else None, "tick": tick_row["status"] if tick_row else None,
            "normalized": transcript.get("normalized"), "raw": transcript.get("raw"),
            "canary": (inst / "canary.txt").read_text() if (inst / "canary.txt").exists() else None}


def calls(log: Path) -> int:
    return len(log.read_text().splitlines()) if log.exists() else 0


def case(name: str, mode: str, want_norm: str, want_status: str, want_tool: str | None = None,
         want_reason: str | None = None, want_billing: str = "unknown", timeout: str = "3") -> None:
    rr, inst = fresh(name, timeout=timeout)
    log = ROOT / "temp" / f"{TAG}-{name}.stub.log"
    log.unlink(missing_ok=True)
    p = tick(rr, 1, mode, log)
    i = inspect(inst)
    d = i["decision"] or {}
    tool = json.loads(d["validated_json"])["tool"] if d.get("validated_json") else None
    ok = (p.returncode == 0 and i["tick"] in {"completed", "uncertain"} and i["normalized"] == want_norm
          and d.get("status") == want_status and (want_tool is None or tool == want_tool)
          and (want_reason is None or d.get("rejected_reason") == want_reason)
          and calls(log) == 1 and i["reservation"]["billing_status"] == want_billing
          and i["evaluate"]["agent_called"] is True and i["canary"] == "do-not-modify\n")
    record(name, ok, f"rc={p.returncode} tick={i['tick']} norm={i['normalized']} decision={d.get('status')}"
                     f"/{d.get('rejected_reason')} tool={tool} stub_calls={calls(log)} "
                     f"billing={i['reservation']['billing_status'] if i['reservation'] else None}")


def main() -> int:
    global STUBFILE
    keep = [ROOT / "releases.db", ROOT / "releases.sql"]
    before = {str(p): sha(p) for p in keep}
    td = Path(tempfile.mkdtemp(prefix="gh1279-stub-"))
    STUBFILE = td / "codex-stub"
    STUBFILE.write_text(STUB)
    STUBFILE.chmod(0o755)

    case("valid-plan-draft", "ok", "ok", "raw-valid", "plan-draft")
    case("malformed-json", "malformed", "invalid-output", "invalid-output", "idle")
    case("json-non-object", "nonobject", "invalid-output", "invalid-output", "idle")
    case("empty-output", "empty", "invalid-output", "invalid-output", "idle")
    case("qa-r1-tool-is-list", "tool_list", "ok", "rejected", "idle", "tool-or-args-not-allowlisted")
    case("qa-r1-inbox-id-is-list", "id_list", "ok", "rejected", "idle", "plan-draft-id-not-eligible")
    case("qa-r1-inbox-ids-has-dict", "ids_dict", "ok", "rejected", "idle", "summarize-args")
    case("disallowed-tool", "disallowed", "ok", "rejected", "idle", "tool-or-args-not-allowlisted")
    case("injection-nonexistent-id", "injection", "ok", "rejected", "idle", "plan-draft-id-not-eligible")
    case("tool-event-is-adapter-error", "toolevent", "adapter-error", "adapter-error", "idle")
    case("rate-limited", "ratelimit", "rate-limited", "rate-limited", "idle")
    case("nonzero-exit", "exit1", "adapter-error", "adapter-error", "idle")
    case("transport-not-stdin-red-control", "stdin", "invalid-output", "invalid-output", "idle")
    case("replay-hardened-stream", f"replay:{PROBE / 'ev2-hardened.jsonl'}", "ok", "raw-valid", "idle")
    case("replay-baseline-stream-tool-events", f"replay:{PROBE / 'ev2-baseline.jsonl'}", "adapter-error", "adapter-error", "idle")

    # timeout: stub sleeps 60 s, cap 2 s, no retry
    rr, inst = fresh("timeout", timeout="2")
    log = ROOT / "temp" / f"{TAG}-timeout.stub.log"; log.unlink(missing_ok=True)
    import time as _t; t0 = _t.monotonic(); p = tick(rr, 1, "timeout", log); dt = _t.monotonic() - t0
    i = inspect(inst)
    record("timeout-no-retry", p.returncode == 0 and i["normalized"] == "timeout" and calls(log) == 1 and dt < 20
           and i["reservation"]["billing_status"] == "unknown" and i["decision"]["validated_json"].count('"idle"') == 1,
           f"norm={i['normalized']} stub_calls={calls(log)} elapsed={dt:.1f}s billing={i['reservation']['billing_status']}")

    # transport: prompt arrives as the positional argument with the policy and the snapshot
    rr, inst = fresh("transport"); log = ROOT / "temp" / f"{TAG}-transport.stub.log"; log.unlink(missing_ok=True)
    tick(rr, 1, "ok", log)
    seen = json.loads(log.read_text().splitlines()[0])
    record("prompt-transport-positional", seen["prompt_has_snapshot"] and seen["prompt_head"].startswith("# Evaluator v2"),
           f"prompt_head={seen['prompt_head']!r} snapshot_present={seen['prompt_has_snapshot']}")
    record("effort-reaches-cli", seen["effort"] == ["model_reasoning_effort=medium"], f"argv effort={seen['effort']}")

    # fault names still apply on the codex arm and make no real call
    rr, inst = fresh("fault"); log = ROOT / "temp" / f"{TAG}-fault.stub.log"; log.unlink(missing_ok=True)
    tick(rr, 1, "ok", log, fault="malformed-decision"); i = inspect(inst)
    record("fault-name-codex-arm", i["normalized"] == "invalid-output" and calls(log) == 0 and i["evaluate"]["agent_called"] is True,
           f"norm={i['normalized']} stub_calls={calls(log)} agent_called={i['evaluate']['agent_called']} (synthetic)")

    # empty inbox: zero invocations, unbilled release, agent_called False
    rr, inst = fresh("empty-inbox"); log = ROOT / "temp" / f"{TAG}-empty-inbox.stub.log"; log.unlink(missing_ok=True)
    conn = sqlite3.connect(inst / "state.db"); conn.execute("UPDATE inbox_items SET status='consumed'"); conn.commit(); conn.close()
    p = tick(rr, 1, "ok", log); i = inspect(inst)
    record("empty-inbox-no-call", p.returncode == 0 and calls(log) == 0 and i["evaluate"]["agent_called"] is False
           and i["reservation"]["status"] == "released" and i["reservation"]["actual_cost"] == 0.0
           and json.loads(i["decision"]["validated_json"])["tool"] == "idle",
           f"stub_calls={calls(log)} agent_called={i['evaluate']['agent_called']} reservation={i['reservation']}")

    # 90-call boundary: 90 unknown-cost calls then the loop pauses; no 91st call
    rr, inst = fresh("cap90", limit=3, cap="0.9", call="0.01"); log = ROOT / "temp" / f"{TAG}-cap90.stub.log"; log.unlink(missing_ok=True)
    outs = [tick(rr, s, "malformed", log) for s in range(1, 92)]
    conn = sqlite3.connect(inst / "state.db")
    held = conn.execute("SELECT COUNT(*) FROM reservations WHERE billing_status='unknown'").fetchone()[0]
    last = conn.execute("SELECT status FROM ticks WHERE tick_id='slot_091'").fetchone()
    conn.close()
    record("call-cap-90-then-pause", calls(log) == 90 and held == 90 and (inst / "PAUSE").exists()
           and (last is None or last[0] == "paused"),
           f"stub_calls={calls(log)} held_unknown={held} PAUSE={(inst / 'PAUSE').exists()} slot91={last[0] if last else None} rcs_nonzero={sum(o.returncode != 0 for o in outs)}")

    # rules arm unchanged and still the default
    rr, inst = fresh("rules-default", adapter="rules"); log = ROOT / "temp" / f"{TAG}-rules.stub.log"; log.unlink(missing_ok=True)
    p = tick(rr, 1, "ok", log); i = inspect(inst); cfg = json.loads((inst / "config.json").read_text())
    record("rules-arm-unchanged", p.returncode == 0 and i["normalized"] == "ok" and calls(log) == 0
           and cfg["adapter"] == "rules" and i["evaluate"]["agent_called"] is True,
           f"norm={i['normalized']} stub_calls={calls(log)} adapter={cfg['adapter']} prompt_sha={cfg['prompt_sha256'][:12]}")

    # config freezes the route; codex without a model is refused
    rr, inst = fresh("config"); cfg = json.loads((inst / "config.json").read_text())
    refused = run(["--run-root", f"temp/factory-primitive/{TAG}-nomodel", "init", "--from-prs", "--limit", "1", "--adapter", "codex"])
    record("config-freezes-route", cfg.get("adapter") == "codex" and cfg.get("codex_model") == "stub-model"
           and cfg.get("codex_effort") == "medium" and cfg.get("adapter_timeout_s") == 3.0 and len(cfg.get("codex_flags", [])) > 10 and "shell_tool" in cfg["codex_flags"]
           and refused.returncode != 0 and "requires --codex-model" in refused.stderr,
           f"flags={len(cfg.get('codex_flags', []))} refused_rc={refused.returncode}")

    # red control for B2: the pre-change _validate raises on the same shapes, the new one rejects them
    old = Path(tempfile.mkdtemp(prefix="gh1279-old-")) / "harness_old.py"
    old.write_bytes(subprocess.run(["git", "show", "origin/development:utils/py/harness.py"], cwd=ROOT, capture_output=True, check=True).stdout)
    sys.path.insert(0, str(ROOT / "utils" / "py"))
    def load(path: Path, name: str):
        spec = importlib.util.spec_from_file_location(name, path); m = importlib.util.module_from_spec(spec); sys.modules[name] = m; spec.loader.exec_module(m); return m
    old_m, new_m = load(old, "harness_old"), load(HARNESS, "harness_new")
    snap = {"inbox": [{"id": "x", "kind": "plan-request"}], "recent": [], "probe_targets": []}
    shapes = [("plan-draft", {"inbox_id": "x"}), ([], {}), ("plan-draft", {"inbox_id": []}), ("summarize", {"inbox_ids": [{}]})]
    def verdicts(m):
        out = []
        for tool, args in shapes:
            d = {"tool": tool, "args": args, "reason": "r", "confidence": 1}
            try: out.append(m._validate(d, snap))
            except Exception as exc: out.append(type(exc).__name__)
        return out
    o, n = verdicts(old_m), verdicts(new_m)
    record("validate-red-control", o == [None, "TypeError", "TypeError", "TypeError"] and n[0] is None and all(isinstance(x, str) for x in n[1:]),
           f"old={o} new={n}")

    after = {str(p): sha(p) for p in keep}
    record("ledger-files-unchanged", before == after, "releases.db/releases.sql hashes identical before and after")
    (HERE / "controls.json").write_text(json.dumps(results, indent=2) + "\n")
    shutil.rmtree(td, ignore_errors=True)
    bad = [r for r in results if not r["pass"]]
    print(f"\n{len(results) - len(bad)}/{len(results)} controls passed")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
