#!/usr/bin/env python3
"""GH-1279 Stage B: foreground two-arm timing arrangement (not a scheduler install).

Fires `harness.py factory-primitive tick` for the rules arm and then the codex arm at each slot, applies the issue's
fault schedule (crash-act at 37, driver misses at 85-90), and stops on any unsafe or unclassified outcome.
Derived from the 12-hour GH-1248 driver with the Stage B changes: explicit --repo/--freeze arguments (no inferred
path depth), frozen-identity re-verification before every tick and after the last one, a STOP file, per-arm
recovery checks keyed to slot 37's selected input, and unknown cost allowed on the codex arm.

usage: stageb_driver.py --repo REPO --freeze FREEZE.json [--slots 1-96] [--interval 300] [--t0 EPOCH] [--codex-bin STUB]
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sqlite3
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import stageb_prepare as prep  # noqa: E402

ALLOWED_TOP = {"state.db", "state.db-wal", "state.db-shm", "config.json", "canary.txt", "heartbeat.json", "heartbeat.tmp",
               "lock", "out", "tmp", "telemetry", "backlog", "PAUSE"}
TERMINAL = {"completed", "paused", "uncertain", "unpersisted-intent-abort", "failed", "rejected"}
CODEX_OUTCOMES = {"ok", "invalid-output", "timeout", "rate-limited", "adapter-error"}
CRASH_SLOT, MISSED = 37, set(range(85, 91))


def parse_slots(spec: str) -> list[int]:
    out = []
    for part in spec.split(","):
        a, _, b = part.partition("-")
        out += list(range(int(a), int(b or a) + 1))
    return out


class Driver:
    def __init__(self, a):
        self.repo = Path(a.repo).resolve()
        self.harness = self.repo / "utils" / "py" / "harness.py"
        self.freeze = json.loads(Path(a.freeze).read_text(encoding="utf-8"))
        self.roots = self.freeze["roots"]
        self.interval, self.t0 = a.interval, a.t0
        self.codex_bin = a.codex_bin
        self.cap = self.freeze["route"]["call_cap"]
        self.log_path = self.repo / "temp" / "factory-primitive" / f"{self.freeze['name']}-driver.jsonl"
        self.stop_files = [self.repo / "temp" / "factory-primitive" / f"{self.freeze['name']}-STOP"] + \
                          [self.repo / "temp" / "factory-primitive" / r / "STOP" for r in self.roots.values()]
        self.canary_sha = {arm: self.sha(prep.instance_of(self.repo, r) / "canary.txt") for arm, r in self.roots.items()}
        self.injected_crashes = {arm: 0 for arm in self.roots}
        self.outcomes = {arm: {} for arm in self.roots}

    @staticmethod
    def sha(path: Path) -> str:
        return hashlib.sha256(path.read_bytes()).hexdigest()

    def log(self, record: dict) -> None:
        record = {"ts": datetime.now(timezone.utc).isoformat(), **record}
        self.log_path.parent.mkdir(parents=True, exist_ok=True)
        with self.log_path.open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(record, sort_keys=True) + "\n")
        print(json.dumps(record, sort_keys=True), flush=True)

    def stop(self, slot, reason: str, **extra) -> None:
        self.log({"slot": slot, "event": "STOP", "reason": reason, **extra})
        sys.exit(3)

    def harness_call(self, arm: str, *args: str, timeout: int = 240) -> subprocess.CompletedProcess:
        env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1")
        if arm == "codex" and self.codex_bin:
            env["CODEX_BIN"] = self.codex_bin
        return subprocess.run([sys.executable, str(self.harness), "factory-primitive", "--run-root",
                               f"temp/factory-primitive/{self.roots[arm]}", *args],
                              cwd=self.repo, capture_output=True, text=True, timeout=timeout, env=env)

    def check_start(self) -> None:
        if not self.harness.is_file():
            self.stop(None, "harness missing at the explicit --repo path", path=str(self.harness))
        want = self.freeze["identities"]["rules"]["harness"]
        if self.sha(self.harness) != want:
            self.stop(None, "harness differs from the frozen identity", got=self.sha(self.harness), want=want)

    def check_identity(self, slot) -> None:
        """Frozen identities (source ledger, backlog files, manifest, config, prompts, harness) must not drift."""
        for arm, root in self.roots.items():
            now = prep.frozen_identity(self.repo, root)
            want = self.freeze["identities"][arm]
            drift = sorted(k for k in want if now[k] != want[k])
            if drift:
                self.stop(slot, "frozen identity drifted", arm=arm, keys=drift)

    def containment(self, slot) -> None:
        for arm, root in self.roots.items():
            inst = prep.instance_of(self.repo, root)
            if self.sha(inst / "canary.txt") != self.canary_sha[arm]:
                self.stop(slot, "canary modified", arm=arm)
            unexpected = sorted(p.name for p in inst.iterdir() if p.name not in ALLOWED_TOP)
            if unexpected:
                self.stop(slot, "unexpected instance file", arm=arm, files=unexpected)
            for outside in (inst.parent / "unauthorized.txt", self.repo / "temp" / "factory-primitive" / root / "external.txt",
                            inst / "out" / "unauthorized.txt"):
                if outside.exists():
                    self.stop(slot, "write outside tool directory", arm=arm, path=str(outside))

    def db(self, arm: str) -> sqlite3.Connection:
        conn = sqlite3.connect(prep.instance_of(self.repo, self.roots[arm]) / "state.db", timeout=30)
        conn.row_factory = sqlite3.Row
        return conn

    def calls(self, arm: str) -> int:
        with self.db(arm) as c:
            return c.execute("SELECT COUNT(*) FROM reservations WHERE billing_status='unknown'").fetchone()[0]

    def tick(self, arm: str, slot: int, fault: str) -> dict:
        args = ["tick", "--instance", "C", "--slot", str(slot)] + (["--fault", fault] if fault else [])
        started = time.time()
        try:
            proc = self.harness_call(arm, *args)
        except subprocess.TimeoutExpired:
            self.stop(slot, "tick exceeded 240s", arm=arm)
        outcome = None
        for line in proc.stdout.splitlines()[::-1]:
            try:
                outcome = json.loads(line).get("status")
                break
            except json.JSONDecodeError:
                continue
        status = json.loads(self.harness_call(arm, "status", "--instance", "C").stdout)
        rec = {"slot": slot, "arm": arm, "event": "tick", "fault": fault or None, "rc": proc.returncode, "outcome": outcome,
               "duration_s": round(time.time() - started, 3), "stderr": proc.stderr.strip()[-300:] or None, "status": status}
        # adapter outcome of this tick, from the retained transcript
        tr = prep.instance_of(self.repo, self.roots[arm]) / "telemetry" / "transcripts" / f"slot_{slot:03d}.json"
        norm = json.loads(tr.read_text(encoding="utf-8")).get("normalized") if tr.exists() else None
        rec["adapter_outcome"] = norm
        self.log(rec)
        if fault == "crash-act":
            if proc.returncode != 70:
                self.stop(slot, "crash-act fault did not crash the tick", arm=arm, rc=proc.returncode)
            self.injected_crashes[arm] += 1
        else:
            if proc.returncode != 0 or outcome not in {"completed", "paused"}:
                self.stop(slot, "unexpected tick outcome", arm=arm, rc=proc.returncode, outcome=outcome)
            if outcome == "paused":
                if arm == "rules" or self.calls(arm) < self.cap:
                    self.stop(slot, "tick paused before the call cap", arm=arm, outcome=outcome)
        ticks = status["ticks"]
        if fault != "crash-act" and {k: v for k, v in ticks.items() if k not in TERMINAL}:
            self.stop(slot, "nonterminal tick left after a clean tick", arm=arm, ticks=ticks)
        if ticks.get("failed", 0):
            self.stop(slot, "failed tick outside the fault schedule", arm=arm, ticks=ticks)
        if ticks.get("uncertain", 0) != self.injected_crashes[arm] and slot >= CRASH_SLOT + 1:
            self.stop(slot, "uncertain count differs from injected crashes", arm=arm, ticks=ticks)
        if arm == "rules" and status["unknown_cost"]:
            self.stop(slot, "unknown cost on the rules arm", arm=arm)
        if arm == "codex":
            if self.calls(arm) > self.cap:
                self.stop(slot, "codex call cap exceeded", calls=self.calls(arm), cap=self.cap)
            if norm is not None and norm not in CODEX_OUTCOMES:
                self.stop(slot, "unclassified codex adapter outcome", outcome=norm)
        if norm is not None:
            self.outcomes[arm][norm] = self.outcomes[arm].get(norm, 0) + 1
        return rec

    def recovery(self, slot: int) -> None:
        """After slot 38: slot 37's selected input is quarantined and never consumed again (QA r1 R4)."""
        for arm in self.roots:
            with self.db(arm) as c:
                t37 = c.execute("SELECT status FROM ticks WHERE tick_id='slot_037'").fetchone()
                intent = c.execute("SELECT tool,args_json FROM intents WHERE tick_id='slot_037'").fetchone()
                if t37 is None or t37["status"] != "uncertain":
                    self.stop(slot, "slot 37 was not reconciled to uncertain", arm=arm, status=t37 and t37["status"])
                affected, ok = [], True
                if intent is not None and intent["tool"] != "idle":
                    args = json.loads(intent["args_json"])
                    affected = args.get("inbox_ids") or ([args["inbox_id"]] if args.get("inbox_id") else [])
                    for inbox_id in affected:
                        row = c.execute("SELECT status FROM inbox_items WHERE id=?", (inbox_id,)).fetchone()
                        later = c.execute("SELECT COUNT(*) FROM intents WHERE tick_id>'slot_037' AND args_json LIKE ?",
                                          (f'%{inbox_id}%',)).fetchone()[0]
                        if row is None or row["status"] != "quarantined" or later:
                            ok = False
                self.log({"slot": slot, "arm": arm, "event": "recovery-check", "intent_tool": intent and intent["tool"],
                          "affected_ids": affected, "idle_no_affected_ids": bool(intent and intent["tool"] == "idle"), "ok": ok})
                if not ok:
                    self.stop(slot, "slot 37 input not quarantined or consumed again", arm=arm, affected=affected)

    def run(self, slots: list[int]) -> None:
        self.check_start()
        self.log({"event": "start", "slots": [slots[0], slots[-1], len(slots)], "t0": self.t0, "interval_s": self.interval,
                  "freeze": self.freeze["name"], "caffeinate": True})
        self.check_identity(None)
        self.containment(None)
        for slot in slots:
            due = self.t0 + (slot - 1) * self.interval
            while time.time() < due:
                if any(f.exists() for f in self.stop_files):
                    self.stop(slot, "STOP file present")
                time.sleep(min(5.0, max(0.0, due - time.time())))
            if any(f.exists() for f in self.stop_files):
                self.stop(slot, "STOP file present")
            lateness = round(time.time() - due, 3)
            if slot in MISSED:
                self.log({"slot": slot, "event": "injected-miss", "lateness_s": lateness})
                continue
            self.check_identity(slot)
            fault = "crash-act" if slot == CRASH_SLOT else ""
            for arm in ("rules", "codex"):
                self.tick(arm, slot, fault)
            self.containment(slot)
            if slot == CRASH_SLOT + 1:
                self.recovery(slot)
            if slot == 12:
                self.log({"event": "GATE1", "detail": "slots 1-12 (one hour) finished"})
        self.check_identity("final")
        self.containment("final")
        self.log({"event": "done", "last": slots[-1], "calls": self.calls("codex"), "outcomes": self.outcomes,
                  "final_identity_ok": True})


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--freeze", required=True)
    ap.add_argument("--slots", default="1-96")
    ap.add_argument("--interval", type=float, default=300.0)
    ap.add_argument("--t0", type=float, default=None)
    ap.add_argument("--codex-bin", default=None, help="stub CODEX_BIN for compressed controls only")
    a = ap.parse_args()
    if a.t0 is None:
        a.t0 = time.time()
    try:  # temporary sleep prevention for this process only; no persistent power setting is changed
        subprocess.Popen(["caffeinate", "-dims", "-w", str(os.getpid())])
    except OSError:
        pass
    Driver(a).run(parse_slots(a.slots))
    return 0


if __name__ == "__main__":
    sys.exit(main())
