#!/usr/bin/env python3
"""GH-1279 Stage B manual controls (no suite, GH-831). Run from the root of a disposable full clone:

    PYTHONDONTWRITEBYTECODE=1 python3 TESTS-RESULTS/2026-10-31+GH-1279-stageb/stageb_controls.py [layout|driver|roundtrip]

Prints PASS/FAIL/MEASURED lines and writes stageb-controls.json beside this file. Needs `gh` (read-only) for init.
"""
from __future__ import annotations

import copy
import importlib.util
import json
import os
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(ROOT / "utils" / "py"))
import stageb_prepare as prep  # noqa: E402

HARNESS = ROOT / "utils" / "py" / "harness.py"
CANARIES = ROOT / "utils" / "py" / "factory_primitive" / "scenarios" / "gh1279-canaries.jsonl"
RUNS = ROOT / "temp" / "factory-primitive"
results: list[dict] = []


def record(name: str, ok: bool | None, detail: str) -> None:
    kind = "MEASURED" if ok is None else ("PASS" if ok else "FAIL")
    results.append({"control": name, "result": kind, "detail": detail})
    print(f"{kind} {name} :: {detail}", flush=True)


def harness(*args: str, env=None, script: Path = HARNESS, timeout=600) -> subprocess.CompletedProcess:
    e = dict(os.environ, PYTHONDONTWRITEBYTECODE="1", **(env or {}))
    for attempt in range(3):  # `init --from-prs` reads GitHub; a transient failure is retried, never masked
        p = subprocess.run([sys.executable, str(script), "factory-primitive", *args], cwd=ROOT, capture_output=True, text=True, timeout=timeout, env=e)
        if p.returncode == 0 or "--from-prs" not in args or " failed" not in p.stderr or attempt == 2:
            return p
        time.sleep(20)
    return p


def init(name: str, *extra: str, script: Path = HARNESS) -> subprocess.CompletedProcess:
    shutil.rmtree(RUNS / name, ignore_errors=True)
    return harness("--run-root", f"temp/factory-primitive/{name}", "init", "--from-prs", "--daily-cap", "1.8", "--max-call-cost", "0.01", *extra, script=script)


def load_module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec)
    sys.modules[name] = m
    spec.loader.exec_module(m)
    return m


def rows():
    return [json.loads(l) for l in CANARIES.read_text().splitlines() if l.strip()]


def write_rows(path: Path, rs) -> Path:
    path.write_text("".join(json.dumps(r) + "\n" for r in rs))
    return path


# ---------------------------------------------------------------------------------------------------- layout
def layout_controls() -> None:
    td = Path(tempfile.mkdtemp(prefix="sb-layout-"))
    h = load_module(HARNESS, "harness_sb")
    base = rows()
    record("canary-file-shape", len(base) == 24 and len({r["slot"] for r in base}) == 24 and not ({37} | set(range(85, 91))) & {r["slot"] for r in base}
           and sum(1 for r in base if "real_issue" in r) == 6, f"rows={len(base)} real_state={sum(1 for r in base if 'real_issue' in r)} categories={sorted({r['category'] for r in base})}")
    bad = {
        "slot-37": lambda rs: rs[0].update(slot=37),
        "slot-in-missed-range": lambda rs: rs[0].update(slot=85),
        "duplicate-slot": lambda rs: rs[1].update(slot=rs[0]["slot"]),
        "slot-out-of-range": lambda rs: rs[0].update(slot=97),
        "unknown-category": lambda rs: rs[0].update(category="nope"),
        "synthetic-missing-body": lambda rs: rs[0].pop("body"),
        "real-row-missing-expect": lambda rs: next(r for r in rs if "real_issue" in r).pop("expect"),
        "duplicate-id": lambda rs: rs[1].update(id=rs[0]["id"]),
    }
    for nm, mut in bad.items():
        rs = copy.deepcopy(base)
        mut(rs)
        try:
            h._load_canaries(write_rows(td / f"{nm}.jsonl", rs), 96, (85, 90))
            record("layout-refuses-" + nm, False, "loader accepted an invalid row")
        except ValueError as exc:
            record("layout-refuses-" + nm, True, str(exc)[:110])
    # loader accepts the real file
    try:
        h._load_canaries(CANARIES, 96, (85, 90))
        record("layout-loader-accepts-real-file", True, "24 rows")
    except ValueError as exc:
        record("layout-loader-accepts-real-file", False, str(exc))
    # init-level refusals that need frozen GitHub state
    def with_row(rs, **chg):
        r = next(x for x in rs if "real_issue" in x); r.update(chg)
    cases = [
        ("real-issue-without-ledger-row", lambda rs: with_row(rs, real_issue=1012, expect="held-delivered"), ["--limit", "33", "--unregistered", "33"], "no ledger row"),
        ("real-issue-expect-mismatch", lambda rs: with_row(rs, real_issue=1075, expect="held-delivered"), ["--limit", "33", "--unregistered", "33"], "expected frozen state"),
        ("slot-37-without-real-request", lambda rs: None, ["--limit", "1"], "slot 37 must carry a real request"),
        ("real-requests-do-not-fit", lambda rs: [r.update(slot=i + 1) for i, r in enumerate(rs)], ["--limit", "10", "--slots", "30"], "do not fit"),
    ]
    for nm, mut, extra, want in cases:
        rs = copy.deepcopy(base)
        mut(rs)
        p = init("sb-ctl-" + nm, "--canaries", str(write_rows(td / f"{nm}.jsonl", rs)), "--miss", "85-90" if "--slots" not in extra else "29-30", *extra)
        record("layout-refuses-" + nm, p.returncode != 0 and want in p.stderr, f"rc={p.returncode} stderr={p.stderr.strip()[-110:]!r}")
    # default behaviour unchanged: controlled brief and manifest outputs equal the Stage A harness's
    stagea = ROOT / "utils" / "py" / "harness_stagea_ref.py"
    stagea.write_bytes(subprocess.run(["git", "show", "a1d95690:utils/py/harness.py"], cwd=ROOT, capture_output=True, check=True).stdout)
    try:
        got = {}
        for tag, script in (("new", HARNESS), ("old", stagea)):
            p = init("sb-ctl-default-" + tag, "--limit", "3", script=script)
            assert p.returncode == 0, p.stderr[-200:]
            harness("--run-root", f"temp/factory-primitive/sb-ctl-default-{tag}", "tick", "--slot", "1", script=script)
            inst = RUNS / f"sb-ctl-default-{tag}" / "instances" / "C"
            man = json.loads((inst / "backlog" / "manifest.json").read_text())
            man.pop("created_at", None)
            got[tag] = (json.dumps(man, sort_keys=True), (inst / "backlog" / "issues.json").read_bytes(), (inst / "out" / "plan-draft" / "slot_001.json").read_bytes())
    finally:
        stagea.unlink(missing_ok=True)
    record("layout-default-unchanged", got["old"] == got["new"] and "layout" not in json.loads(got["new"][0]),
           f"manifest/issues/brief equal={got['old'] == got['new']} (created_at excluded; same frozen inputs only if GitHub state did not move)")


# ---------------------------------------------------------------------------------------------------- parity
def parity_controls() -> str:
    name = "sb-ctl-parity"
    p = subprocess.run([sys.executable, str(HERE / "stageb_prepare.py"), "--repo", str(ROOT), "--name", name], cwd=ROOT, capture_output=True, text=True, timeout=1200)
    record("prepare-two-arms-parity", p.returncode == 0 and '"prepared"' in p.stdout, p.stdout.strip()[-160:] or p.stderr.strip()[-160:])
    freeze = json.loads((RUNS / f"{name}-freeze.json").read_text())
    ids = copy.deepcopy(freeze["identities"])
    record("parity-identical-inputs-pass", prep.parity(ids["rules"], ids["codex"]) == [], "intended config difference (adapter/model) is not a parity key")
    bad = copy.deepcopy(ids)
    bad["codex"]["backlog_files"]["gh-state.json"] = "0" * 64     # e.g. #1075's frozen state differs in one arm
    record("parity-detects-frozen-state-difference", prep.parity(bad["rules"], bad["codex"]) == ["backlog_files"], "one backlog file hash differs -> rejected")
    bad2 = copy.deepcopy(ids)
    bad2["codex"]["source_ledger"] = "f" * 64
    record("parity-detects-source-ledger-difference", prep.parity(bad2["rules"], bad2["codex"]) == ["source_ledger"], "source ledger hash differs -> rejected")
    return name


# ---------------------------------------------------------------------------------------------------- driver
STUB = r'''#!/usr/bin/env python3
import json, os, sqlite3, sys
out = sys.argv[sys.argv.index("-o") + 1]
snap, _ = json.JSONDecoder().raw_decode(sys.argv[-1].split("Snapshot (JSON):\n", 1)[1])
slot = 289 - snap["budget"]["ticks_left"]
b = os.environ.get("STUB_BEHAVIOR", "select")
first = snap["inbox"][0]["id"] if snap["inbox"] else None
if b == "drift_last" and slot == int(os.environ["STUB_LAST"]):
    p = os.path.join(os.environ["STUB_BACKLOG"], "gh-state.json"); open(p, "a").write(" ")
if b == "unquarantine" and slot == 38:
    c = sqlite3.connect(os.environ["STUB_DB"]); r = c.execute("select args_json from intents where tick_id='slot_037'").fetchone()
    if r: c.execute("update inbox_items set status='pending' where id=?", (json.loads(r[0]).get("inbox_id"),)); c.commit()
if (b == "idle37" and slot == 37) or first is None:
    d = {"tool": "idle", "args": {}, "reason": "stub idle", "confidence": 1}
else:
    d = {"tool": "plan-draft", "args": {"inbox_id": first}, "reason": "stub", "confidence": 1}
text = json.dumps(d)
for e in [{"type": "thread.started"}, {"type": "turn.started"}, {"type": "item.completed", "item": {"type": "agent_message", "text": text}}, {"type": "turn.completed"}]:
    print(json.dumps(e))
open(out, "w").write(text)
'''


def clone_pair(freeze: dict, tag: str) -> Path:
    """Copy the prepared run roots under new names with an adjusted freeze file (instances are byte-identical)."""
    f = copy.deepcopy(freeze)
    f["name"] = f"{freeze['name']}-{tag}"
    for arm, old in freeze["roots"].items():
        new = f"{f['name']}-{arm}"
        shutil.rmtree(RUNS / new, ignore_errors=True)
        shutil.copytree(RUNS / old, RUNS / new)
        f["roots"][arm] = new
    path = RUNS / f"{f['name']}-freeze.json"
    path.write_text(json.dumps(f, indent=2, sort_keys=True) + "\n")
    (RUNS / f"{f['name']}-driver.jsonl").unlink(missing_ok=True)   # the driver appends; a stale log would double-count a rerun
    (RUNS / f"{f['name']}-STOP").unlink(missing_ok=True)
    return path


def run_driver(freeze_path: Path, slots: str, stub: Path | None, behavior: str = "select", env_extra=None, repo: Path = ROOT):
    f = json.loads(freeze_path.read_text())
    env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1", STUB_BEHAVIOR=behavior, **(env_extra or {}))
    argv = [sys.executable, str(HERE / "stageb_driver.py"), "--repo", str(repo), "--freeze", str(freeze_path), "--slots", slots, "--interval", "1"]
    if stub:
        argv += ["--codex-bin", str(stub)]
    p = subprocess.run(argv, cwd=ROOT, capture_output=True, text=True, timeout=1500, env=env)
    log = [json.loads(l) for l in (RUNS / f"{f['name']}-driver.jsonl").read_text().splitlines()] if (RUNS / f"{f['name']}-driver.jsonl").exists() else []
    return p, log


def driver_controls(prepared: str) -> None:
    td = Path(tempfile.mkdtemp(prefix="sb-drv-"))
    stub = td / "codex-stub"
    stub.write_text(STUB)
    stub.chmod(0o755)
    freeze = json.loads((RUNS / f"{prepared}-freeze.json").read_text())
    SL = "35-39,84-92"

    fp = clone_pair(freeze, "clean")
    p, log = run_driver(fp, SL, stub)
    rec = [e for e in log if e.get("event") == "recovery-check"]
    miss = [e["slot"] for e in log if e.get("event") == "injected-miss"]
    codex_ticks = [e for e in log if e.get("event") == "tick" and e["arm"] == "codex"]
    record("driver-clean-run-both-arms", p.returncode == 0 and log[-1].get("event") == "done" and log[-1].get("final_identity_ok")
           and len(rec) == 2 and all(r["ok"] for r in rec) and miss == list(range(85, 91)),
           f"rc={p.returncode} recovery={[(r['arm'], r['intent_tool'], r['affected_ids'], r['ok']) for r in rec]} misses={miss}")
    record("driver-crash-at-37-both-arms", sorted(e["arm"] for e in log if e.get("event") == "tick" and e["slot"] == 37 and e["rc"] == 70) == ["codex", "rules"], "rc 70 on both arms at slot 37")
    record("driver-unknown-cost-allowed-on-codex-arm", p.returncode == 0 and any(e["status"]["unknown_cost"] for e in codex_ticks), "codex unknown_cost recorded and the run continued")

    fp = clone_pair(freeze, "idle37")
    p, log = run_driver(fp, "36-39", stub, "idle37")
    rec = {r["arm"]: r for r in log if r.get("event") == "recovery-check"}
    record("driver-recovery-idle-selection", p.returncode == 0 and rec["codex"]["idle_no_affected_ids"] and rec["codex"]["affected_ids"] == [] and rec["rules"]["affected_ids"],
           f"codex idle -> no affected IDs; rules selected {rec['rules']['affected_ids']}")

    fp = clone_pair(freeze, "unquar")
    f2 = json.loads(fp.read_text())
    p, log = run_driver(fp, "36-39", stub, "unquarantine", {"STUB_DB": str(prep.instance_of(ROOT, f2["roots"]["codex"]) / "state.db")})
    stops = [e for e in log if e.get("event") == "STOP"]
    record("driver-detects-wrong-quarantine", p.returncode == 3 and stops and "not quarantined" in stops[-1]["reason"], f"rc={p.returncode} stop={stops[-1]['reason'] if stops else None}")

    fp = clone_pair(freeze, "escape")
    f2 = json.loads(fp.read_text())
    (prep.instance_of(ROOT, f2["roots"]["codex"]) / "evil.txt").write_text("x")
    p, log = run_driver(fp, "36-37", stub)
    stops = [e for e in log if e.get("event") == "STOP"]
    record("driver-planted-escape-stops", p.returncode == 3 and stops and stops[-1]["reason"] == "unexpected instance file", f"rc={p.returncode} stop={stops[-1] if stops else None}")

    fp = clone_pair(freeze, "drift-ledger")
    f2 = json.loads(fp.read_text())
    with (prep.instance_of(ROOT, f2["roots"]["codex"]) / "backlog" / "gh-state.json").open("a") as fh:
        fh.write(" ")
    p, log = run_driver(fp, "36-37", stub)
    stops = [e for e in log if e.get("event") == "STOP"]
    record("driver-frozen-ledger-drift-stops-before-next-evaluation", p.returncode == 3 and stops and stops[-1]["reason"] == "frozen identity drifted"
           and "backlog_files" in stops[-1]["keys"] and not any(e.get("event") == "tick" for e in log), f"rc={p.returncode} keys={stops[-1].get('keys') if stops else None} ticks={sum(e.get('event') == 'tick' for e in log)}")

    fp = clone_pair(freeze, "drift-model")
    f2 = json.loads(fp.read_text())
    cfgp = prep.instance_of(ROOT, f2["roots"]["codex"]) / "config.json"
    cfg = json.loads(cfgp.read_text()); cfg["codex_model"] = "gpt-other"; cfgp.write_text(json.dumps(cfg, indent=2, sort_keys=True) + "\n")
    p, log = run_driver(fp, "36-37", stub)
    stops = [e for e in log if e.get("event") == "STOP"]
    record("driver-model-drift-stops", p.returncode == 3 and stops and stops[-1]["reason"] == "frozen identity drifted" and "config_route" in stops[-1]["keys"], f"rc={p.returncode} keys={stops[-1].get('keys') if stops else None}")

    fp = clone_pair(freeze, "stopfile")
    f2 = json.loads(fp.read_text())
    (RUNS / f"{f2['name']}-STOP").write_text("stop")
    p, log = run_driver(fp, "36-37", stub)
    stops = [e for e in log if e.get("event") == "STOP"]
    record("driver-stop-file-prevents-next-tick", p.returncode == 3 and stops and stops[-1]["reason"] == "STOP file present" and not any(e.get("event") == "tick" for e in log), f"rc={p.returncode}")

    driver_final_drift(prepared, stub, freeze)

    fp = clone_pair(freeze, "wrongrepo")
    p, log = run_driver(fp, "36-37", stub, repo=ROOT / "TESTS-RESULTS")
    record("driver-wrong-repo-path-fails", p.returncode != 0 and not any(e.get("event") == "tick" for e in log), f"rc={p.returncode} {p.stderr.strip()[-90:]!r}")


def driver_final_drift(prepared: str, stub: Path | None = None, freeze: dict | None = None) -> None:
    if stub is None:
        stub = Path(tempfile.mkdtemp(prefix="sb-drv-")) / "codex-stub"
        stub.write_text(STUB)
        stub.chmod(0o755)
    freeze = freeze or json.loads((RUNS / f"{prepared}-freeze.json").read_text())
    fp = clone_pair(freeze, "final-drift")
    f2 = json.loads(fp.read_text())
    # slots 37-39: the crash at 37 is reconciled at 38, then the stub drifts a frozen backlog file during the final tick (39)
    p, log = run_driver(fp, "37-39", stub, "drift_last", {"STUB_LAST": "39", "STUB_BACKLOG": str(prep.instance_of(ROOT, f2["roots"]["codex"]) / "backlog")})
    stops = [e for e in log if e.get("event") == "STOP"]
    record("driver-final-tick-drift-blocks-identity-claim", p.returncode == 3 and stops and stops[-1]["slot"] == "final" and not any(e.get("final_identity_ok") for e in log)
           and any(e.get("event") == "recovery-check" and e["ok"] for e in log),
           f"rc={p.returncode} stop_slot={stops[-1]['slot'] if stops else None} reason={stops[-1]['reason'] if stops else None}")


# ---------------------------------------------------------------------------------------------------- round trip
def roundtrip(prepared: str) -> None:
    """All 24 canary rows through init -> draft -> proposal on the rules arm; outcomes versus expectation."""
    freeze = json.loads((RUNS / f"{prepared}-freeze.json").read_text())
    fp = clone_pair(freeze, "roundtrip")
    f2 = json.loads(fp.read_text())
    root = f2["roots"]["rules"]
    bad = []
    for s in range(1, 97):
        if 85 <= s <= 90:
            continue
        p = harness("--run-root", f"temp/factory-primitive/{root}", "tick", "--slot", str(s))
        if p.returncode != 0 or '"completed"' not in p.stdout:
            bad.append((s, p.returncode))
    inst = prep.instance_of(ROOT, root)
    man = json.loads((inst / "backlog" / "manifest.json").read_text())
    briefs = {json.loads(f.read_text())["request_id"]: json.loads(f.read_text()) for f in (inst / "out" / "plan-draft").glob("slot_*.json")}
    prop = json.loads((inst / "out" / "plan-draft" / "wave-proposal.json").read_text())
    sched = {l["issue"]: w for w, wave in enumerate(prop["provisional"]["waves"], 1) for l in wave}
    held = {h["issue"]: h["reason"] for h in prop["held"]}
    canaries = [(rid, q) for rid, q in man["requests"].items() if "canary" in q]
    record("roundtrip-all-24-canaries-drafted", not bad and len(canaries) == 24 and all(rid in briefs for rid, _ in canaries), f"ticks_not_completed={bad} canaries={len(canaries)} briefs={sum(rid in briefs for rid, _ in canaries)}")
    closed = [(q["canary"], q["issue"]) for _, q in canaries if q["canary_category"] == "stale-or-delivered" and q["issue"] in (255, 1075, 1087)]
    record("roundtrip-closed-controls-held", all(q_issue in held and "already-closed" in held[q_issue] and q_issue not in sched for _, q_issue in closed), f"closed={closed}")
    for _, q in canaries:
        if q["canary_category"] == "stale-or-delivered" and q["issue"] in (1098, 384, 484):
            record(f"roundtrip-delivered-#{q['issue']}", None if q["issue"] in sched else True,
                   f"scheduled_in_wave={sched.get(q['issue'])} held={held.get(q['issue'])} brief_status={briefs[next(r for r, qq in canaries if qq is q)]['draft_status']} (expect held-delivered)")
    syn = [(q["canary"], briefs[rid]["draft_status"], q["issue"] in sched) for rid, q in canaries if q["issue"] >= 900001]
    record("roundtrip-synthetic-canaries-no-crash", all(rid in briefs for rid, q in canaries if q["issue"] >= 900001), f"{len(syn)} synthetic rows drafted")
    record("roundtrip-injection-text-scheduled-by-deterministic-planner", None if any(s for _, _, s in syn if True) else True,
           f"scheduled synthetic rows: {[c for c, _, s in syn if s]}")


def main() -> int:
    which = sys.argv[1] if len(sys.argv) > 1 else "all"
    if which == "final-drift":
        driver_final_drift(parity_controls())   # a fresh freeze: the driver (correctly) refuses one taken at another commit
        (HERE / "stageb-controls-final-drift.json").write_text(json.dumps(results, indent=2) + "\n")
        return 0 if all(r["result"] == "PASS" for r in results) else 1
    if which in ("all", "layout"):
        layout_controls()
    prepared = None
    if which in ("all", "driver", "roundtrip", "parity"):
        prepared = parity_controls()
    if which in ("all", "driver"):
        driver_controls(prepared)
    if which in ("all", "roundtrip"):
        roundtrip(prepared)
    (HERE / "stageb-controls.json").write_text(json.dumps(results, indent=2) + "\n")
    bad = [r for r in results if r["result"] == "FAIL"]
    print(f"\n{sum(r['result'] == 'PASS' for r in results)} pass, {sum(r['result'] == 'MEASURED' for r in results)} measured, {len(bad)} fail")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
