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
sys.path.insert(0, str(ROOT / "utils" / "py"))

STUB = r'''#!/usr/bin/env python3
import json, os, select, sys, time
mode = os.environ["STUB_MODE"]
with open(os.environ["STUB_LOG"], "a") as fh:
    fh.write(json.dumps({"mode": mode, "argv_len": len(sys.argv), "prompt_head": sys.argv[-1][:40],
                         "prompt_has_snapshot": "Snapshot (JSON):" in sys.argv[-1],
                         "prompt_len": len(sys.argv[-1].encode()),
                         "effort": [a for a in sys.argv if a.startswith("model_reasoning_effort=")]}) + "\n")
out = sys.argv[sys.argv.index("-o") + 1]
prompt = sys.argv[-1]
snap, _ = json.JSONDecoder().raw_decode(prompt.split("Snapshot (JSON):\n", 1)[1])
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
elif mode.startswith("a_"):
    pick = int(os.environ.get("STUB_PICK", "0"))
    target = snap["inbox"][pick]["id"] if len(snap["inbox"]) > pick else "none"
    shared = os.environ.get("STUB_PATH", "utils/py/proc_group.py")
    A = {
        "a_ok": {"scope": ["Authored scope line one."], "acceptance": ["Authored acceptance line."], "open_questions": ["Authored question?"]},
        "a_scope_only": {"scope": ["Authored scope lifts the hold."]},
        "a_scope_blank": {"scope": ["   "]},
        "a_bad_key": {"scope": ["x"], "evil": ["y"]},
        "a_oversize": {"scope": ["z" * 601]},
        "a_too_many": {"scope": ["s"] * 6},
        "a_nonstr": {"scope": [1]},
        "a_not_list": {"scope": "text"},
        "a_empty": {},
        "a_invented_path": {"write_set": ["utils/py/does_not_exist_gh1279.py"]},
        "a_new_file": {"write_set": ["utils/py/factory_primitive/prompts/evaluator.v9-never-exists.md"]},
        "a_ws": {"write_set": [shared], "scope": ["Authored scope with a path."]},
    }[mode]
    say(json.dumps({"tool": "plan-draft", "args": {"inbox_id": target, "authored": A}, "reason": "stub", "confidence": 1}))
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


def a2_case(name, mode, want_status, want_reason=None, *, authoring=True, limit=3, unreg=0, slot=1, pick=0, pre=None,
            env_extra=None, early="ok"):
    """init (codex, authoring on/off) -> optional pre-hook on the instance -> tick `slot` -> inspect."""
    rr = f"temp/factory-primitive/{TAG}-{name}"
    shutil.rmtree(ROOT / rr, ignore_errors=True)
    extra = ["--adapter", "codex", "--codex-model", "stub-model", "--adapter-timeout", "5"] + (["--codex-authoring"] if authoring else [])
    p = run(["--run-root", rr, "init", "--from-prs", "--limit", str(limit), "--unregistered", str(unreg), "--daily-cap", "0.9",
             "--max-call-cost", "0.01", *extra])
    assert p.returncode == 0, p.stderr
    inst = ROOT / rr / "instances" / "C"
    if pre:
        pre(inst)
    log = ROOT / "temp" / f"{TAG}-{name}.stub.log"
    log.unlink(missing_ok=True)
    env = {"CODEX_BIN": str(STUBFILE), "STUB_MODE": mode, "STUB_LOG": str(log), "STUB_PICK": str(pick), **(env_extra or {})}
    for s in range(1, slot + 1):  # earlier slots tick with a plain, valid response so their requests are consumed
        e = dict(env, STUB_MODE=early) if s < slot else env
        pr = run(["--run-root", rr, "tick", "--slot", str(s)], e)
    i = inspect(inst, slot)
    d = i["decision"] or {}
    brief_path = inst / "out" / "plan-draft" / f"slot_{slot:03d}.json"
    brief = json.loads(brief_path.read_text()) if brief_path.exists() else None
    return rr, inst, i, d, brief, pr


def a2_controls():
    # authoring ON: valid authored content is accepted, merged, labelled, sourced entries kept
    rr, inst, i, d, brief, pr = a2_case("a2-valid", "a_ok", "raw-valid")
    srcs = [e["source"] for e in (brief or {}).get("scope", [])] if brief else []
    record("a2-valid-authored-merged", d.get("status") == "raw-valid" and brief and brief.get("authored") is True
           and any(s == "codex-authored" for s in srcs) and any(s != "codex-authored" for s in srcs + ["x"])
           and all(e.get("heading") for e in brief["scope"]),
           f"decision={d.get('status')} authored={brief and brief.get('authored')} scope_sources={sorted(set(srcs))}")
    # rejections: each returns its reason, safe idle, no brief, one stub call
    for nm, mode, reason in [("blank-scope", "a_scope_blank", "authored-shape"), ("unknown-key", "a_bad_key", "authored-shape"),
                             ("oversize-string", "a_oversize", "authored-shape"), ("too-many-items", "a_too_many", "authored-shape"),
                             ("non-string-item", "a_nonstr", "authored-shape"), ("scope-not-list", "a_not_list", "authored-shape"),
                             ("empty-authored", "a_empty", "authored-shape"),
                             ("invented-path", "a_invented_path", "authored-path-not-tracked"),
                             ("legit-new-file-policy-false-reject", "a_new_file", "authored-path-not-tracked")]:
        rr, inst, i, d, brief, pr = a2_case("a2-" + nm, mode, "rejected")
        tool = json.loads(d["validated_json"])["tool"] if d.get("validated_json") else None
        record("a2-reject-" + nm, d.get("status") == "rejected" and d.get("rejected_reason") == reason and tool == "idle" and brief is None
               and i["tick"] in {"completed", "uncertain"},
               f"decision={d.get('status')}/{d.get('rejected_reason')} tool={tool} brief={'yes' if brief else 'none'}")
    # authoring OFF: the identical authored response is rejected exactly as in Stage A
    rr, inst, i, d, brief, pr = a2_case("a2-off", "a_ok", "rejected", authoring=False)
    cfg = json.loads((inst / "config.json").read_text())
    record("a2-off-mode-rejects-authored", d.get("status") == "rejected" and d.get("rejected_reason") == "plan-draft-id-not-eligible"
           and brief is None and "codex_authoring" not in cfg,
           f"decision={d.get('status')}/{d.get('rejected_reason')} brief={'yes' if brief else 'none'} codex_authoring_in_cfg={'codex_authoring' in cfg}")
    # old validator is the red control: a validator that ignores `tracked` admits invented paths
    # (checked in the loaded-module section below)
    # missing-scope lift: an unregistered issue with a cited path and no headed sections is held without authoring
    def plain_body(inst):
        iss = json.loads((inst / "backlog" / "issues.json").read_text())
        num = [k for k, v in json.loads((inst / "backlog" / "manifest.json").read_text())["requests"].items() if v["source"] == "unregistered"]
        man = json.loads((inst / "backlog" / "manifest.json").read_text())
        n = str(man["requests"][num[0]]["issue"])
        iss[n]["body"] = "Plain paragraph with no headings. It concerns utils/py/proc_group.py only."
        (inst / "backlog" / "issues.json").write_text(json.dumps(iss))
    rr, inst, i, d, held, pr = a2_case("a2-hold", "ok", "raw-valid", authoring=True, limit=1, unreg=1, slot=2, pre=plain_body)
    rr, inst, i, d, lift, pr = a2_case("a2-lift", "a_scope_only", "raw-valid", authoring=True, limit=1, unreg=1, slot=2, pre=plain_body)
    record("a2-authored-scope-lifts-missing-scope", held and held["draft_status"] == "missing-scope" and lift and lift["draft_status"] in {"draft", "ready"}
           and any(e["source"] == "codex-authored" for e in lift["scope"]) and lift.get("authored") is True and "authored" not in held,
           f"without={held and held['draft_status']} with={lift and lift['draft_status']} sourced_scope_kept={bool(lift and [e for e in lift['scope'] if e['source'] != 'codex-authored'])}")
    # write_set: draft briefs take authored paths; ready briefs drop them and record it; branch is data-driven
    seen_states = {}
    for pick_slot in range(1, 6):
        rr, inst, i, d, brief, pr = a2_case(f"a2-ws-{pick_slot}", "a_ws", "raw-valid", authoring=True, limit=6, unreg=2, slot=pick_slot)
        if not brief:
            continue
        state = brief["planner_state"]
        paths = [w["path"] for w in brief["write_set"]]
        added = "utils/py/proc_group.py" in paths and any(w["source"] == "codex-authored" and w["path"] == "utils/py/proc_group.py" for w in brief["write_set"])
        if state == "ready":
            ok = ("utils/py/proc_group.py" not in paths or not added) and brief.get("authored_ignored") == ["write_set"]
        else:
            ok = added or "utils/py/proc_group.py" in paths  # already sourced counts as present, not added
        seen_states.setdefault("ready" if state == "ready" else "draft", []).append(ok)
    record("a2-write-set-draft-branch", bool(seen_states.get("draft")) and all(seen_states["draft"]),
           f"draft briefs checked={len(seen_states.get('draft', []))}")
    record("a2-write-set-ready-branch", (not seen_states.get("ready")) or all(seen_states["ready"]),
           f"ready briefs checked={len(seen_states.get('ready', []))}" + ("" if seen_states.get("ready") else " (not exercised: no planner-ready request in this backlog)"))
    # R1 collision: two draft lanes whose briefs share an authored path never share a wave
    rr = f"temp/factory-primitive/{TAG}-a2-collide"; shutil.rmtree(ROOT / rr, ignore_errors=True)
    p = run(["--run-root", rr, "init", "--from-prs", "--limit", "4", "--unregistered", "2", "--daily-cap", "0.9", "--max-call-cost", "0.01",
             "--adapter", "codex", "--codex-model", "stub-model", "--adapter-timeout", "5", "--codex-authoring"]); assert p.returncode == 0, p.stderr
    inst = ROOT / rr / "instances" / "C"; log = ROOT / "temp" / f"{TAG}-a2-collide.stub.log"; log.unlink(missing_ok=True)
    for sl in (1, 2):
        run(["--run-root", rr, "tick", "--slot", str(sl)], {"CODEX_BIN": str(STUBFILE), "STUB_MODE": "a_ws", "STUB_LOG": str(log), "STUB_PATH": "utils/py/proc_group.py"})
    b = [json.loads((inst / "out" / "plan-draft" / f"slot_00{sl}.json").read_text()) for sl in (1, 2)]
    prop = json.loads((inst / "out" / "plan-draft" / "wave-proposal.json").read_text())
    where = {}
    for wi, wave in enumerate(prop["provisional"]["waves"], 1):
        for lane in wave:
            where[lane["issue"]] = (wi, lane["write_set"])
    lanes = [where.get(x["issue"]) for x in b]
    both = all(lanes) and all("utils/py/proc_group.py" in l[1] for l in lanes)
    record("a2-collision-draft-lanes-separated", both and lanes[0][0] != lanes[1][0],
           f"issues={[x['issue'] for x in b]} waves={[l and l[0] for l in lanes]} both_claim_shared_path={both}")
    # R1 ready branch, forced in-process: a planner-ready record keeps its contract write set and records authored_ignored
    spec2 = importlib.util.spec_from_file_location("harness_ready", HARNESS); hm = importlib.util.module_from_spec(spec2); sys.modules["harness_ready"] = hm; spec2.loader.exec_module(hm)
    rr = f"temp/factory-primitive/{TAG}-a2-ready"; shutil.rmtree(ROOT / rr, ignore_errors=True)
    p = run(["--run-root", rr, "init", "--from-prs", "--limit", "2", "--daily-cap", "0.9", "--max-call-cost", "0.01",
             "--adapter", "codex", "--codex-model", "stub-model", "--codex-authoring"]); assert p.returncode == 0, p.stderr
    inst = ROOT / rr / "instances" / "C"; man = json.loads((inst / "backlog" / "manifest.json").read_text())
    rid, req = next(iter(man["requests"].items()))
    real_planner = hm._planner
    class Proxy:
        def __init__(self, eng): self._e = eng
        def __getattr__(self, n): return getattr(self._e, n)
        def compute(self):
            comp = self._e.compute()
            for r in comp["deduped"]:
                if r["gh"] == req["issue"]:
                    r["state"] = "ready"; r["contract"] = {"artifacts": ["utils/py/harness.py"], "fix_probes": []}
            return comp
    hm._planner = lambda backlog, mode: Proxy(real_planner(backlog, mode))
    out = inst / "out" / "plan-draft"; out.mkdir(parents=True, exist_ok=True)
    hm.plan_draft("slot_001", out, {"inbox_id": rid, "authored": {"write_set": ["utils/py/proc_group.py"], "scope": ["Authored scope."]}}, [], "")
    rb = json.loads((out / "slot_001.json").read_text()); rp = json.loads((out / "wave-proposal.json").read_text())
    lane_paths = [l["write_set"] for w in rp["actual"]["waves"] + rp["provisional"]["waves"] for l in w if l["issue"] == req["issue"]]
    record("a2-ready-brief-ignores-authored-paths", rb["planner_state"] == "ready" and [w["path"] for w in rb["write_set"]] == ["utils/py/harness.py"]
           and rb.get("authored_ignored") == ["write_set"] and rb.get("authored") is True and all("utils/py/proc_group.py" not in lp for lp in lane_paths),
           f"state={rb['planner_state']} write_set={[w['path'] for w in rb['write_set']]} ignored={rb.get('authored_ignored')} lane_paths={lane_paths}")
    # full prompt transport with 12 pending requests: one positional argument, size recorded
    rr, inst, i, d, brief, pr = a2_case("a2-prompt12", "ok", "raw-valid", authoring=True, limit=12, slot=12, early="malformed")
    seen = json.loads((ROOT / "temp" / f"{TAG}-a2-prompt12.stub.log").read_text().splitlines()[-1])
    _c = sqlite3.connect(inst / "state.db"); pending12 = len(json.loads(_c.execute("SELECT json FROM snapshots WHERE tick_id='slot_012'").fetchone()[0])["inbox"]); _c.close()
    record("a2-prompt-12-requests-single-argv", pending12 == 12 and seen["prompt_has_snapshot"] and 50_000 < seen["prompt_len"] < 700_000,
           f"pending_requests={pending12} prompt_bytes={seen['prompt_len']} (ARG_MAX={os.sysconf('SC_ARG_MAX')})")
    # off-mode brief is byte-identical to Stage A's: old harness (Stage A commit) vs new, rules arm, same frozen inputs
    old = ROOT / "utils" / "py" / "harness_stagea.py"
    old.write_bytes(subprocess.run(["git", "show", "4eb4dce8e3bee399eac3ee1dadd20f05cc715c62:utils/py/harness.py"], cwd=ROOT, capture_output=True, check=True).stdout)
    try:
        briefs = {}
        for tag, script in (("new", HARNESS), ("old", old)):
            rr = f"temp/factory-primitive/{TAG}-a2-bytes-{tag}"
            shutil.rmtree(ROOT / rr, ignore_errors=True)
            e = dict(os.environ, PYTHONDONTWRITEBYTECODE="1")
            subprocess.run([sys.executable, str(script), "factory-primitive", "--run-root", rr, "init", "--from-prs", "--limit", "2"], cwd=ROOT, env=e, capture_output=True, text=True, check=True)
            subprocess.run([sys.executable, str(script), "factory-primitive", "--run-root", rr, "tick", "--slot", "1"], cwd=ROOT, env=e, capture_output=True, text=True, check=True)
            briefs[tag] = (ROOT / rr / "instances" / "C" / "out" / "plan-draft" / "slot_001.json").read_bytes()
    finally:
        old.unlink(missing_ok=True)
    record("a2-off-mode-brief-byte-identical", briefs["old"] == briefs["new"], f"bytes old={len(briefs['old'])} new={len(briefs['new'])} equal={briefs['old'] == briefs['new']}")
    # red control: the Stage A validator (no `tracked`) rejects every authored decision; a validator that skips the
    # path test would admit the invented path. Exercise the new one directly.
    import importlib.util as _u
    spec = _u.spec_from_file_location("harness_new_a2", HARNESS); m = _u.module_from_spec(spec); sys.modules["harness_new_a2"] = m; spec.loader.exec_module(m)
    snap = {"inbox": [{"id": "x", "kind": "plan-request"}], "recent": [], "probe_targets": []}
    def v(authored, tracked):
        return m._validate({"tool": "plan-draft", "args": {"inbox_id": "x", "authored": authored}, "reason": "r", "confidence": 1}, snap, tracked)
    tracked = {"utils/py/proc_group.py"}
    got = [v({"scope": ["ok"]}, tracked), v({"write_set": ["utils/py/proc_group.py"]}, tracked), v({"write_set": ["nope.py"]}, tracked),
           v({"scope": ["ok"]}, None), v({"scope": [" "]}, tracked)]
    record("a2-validator-direct", got == [None, None, "authored-path-not-tracked", "plan-draft-id-not-eligible", "authored-shape"], f"got={got}")


def main() -> int:
    global STUBFILE
    keep = [ROOT / "releases.db", ROOT / "releases.sql"]
    before = {str(p): sha(p) for p in keep}
    td = Path(tempfile.mkdtemp(prefix="gh1279-stub-"))
    STUBFILE = td / "codex-stub"
    STUBFILE.write_text(STUB)
    STUBFILE.chmod(0o755)

    if len(sys.argv) > 1 and sys.argv[1] == "a2":
        a2_controls()
        bad = [r for r in results if not r["pass"]]
        print(f"\n{len(results) - len(bad)}/{len(results)} a2 controls passed")
        return 1 if bad else 0
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

    a2_controls()

    after = {str(p): sha(p) for p in keep}
    record("ledger-files-unchanged", before == after, "releases.db/releases.sql hashes identical before and after")
    (HERE / "controls.json").write_text(json.dumps(results, indent=2) + "\n")
    shutil.rmtree(td, ignore_errors=True)
    bad = [r for r in results if not r["pass"]]
    print(f"\n{len(results) - len(bad)}/{len(results)} controls passed")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
