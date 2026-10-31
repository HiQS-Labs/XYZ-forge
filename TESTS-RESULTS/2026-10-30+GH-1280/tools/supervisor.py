#!/usr/bin/env python3
"""GH-1280 campaign supervisor: an independent foreground stop for one gen4_campaign run.

Not a suite, gate or adapter. It launches gen4 in its own process group, reads telemetry as it
grows, and stops the run on wall time, a no-new-signal streak, a canary change or invalid
telemetry. On stop it kills the gen4 group and then every surviving campaign process (each
mutant runs in its own session, so a group kill alone misses it).

usage: supervisor.py --contract contract.json [--replay-telemetry FILE]
"""
import argparse, hashlib, json, os, re, signal, subprocess, sys, time

EXPECTED = [  # (class, rc, stderr regex) — verified against utils/py/harness.py
    ("usage", 2, r"usage: harness\.py factory-primitive"),
    ("run-root-guard", 2, r"factory-primitive: run root must stay under "),
    ("instance-guard", 2, r"factory-primitive: instance must be a simple name"),
    ("slot-guard", 2, r"factory-primitive: slot must be in 1\.\.288"),
    ("state-guard", 2, r"factory-primitive: instance already initialized"),
    ("cap-guard", 2, r"factory-primitive: (invalid daily cap|--limit must be|--unregistered must be)"),
    ("sandbox-denied", 2, r"factory-primitive: .*Operation not permitted"),
    ("input-error", 2, r"factory-primitive: (\[Errno \d+\]|scenario |Expecting |Extra data|Invalid |Unterminated )"),
]


def classify(rc, stderr):
    if rc == 0:
        return "pass"
    if "Traceback (most recent call last)" in stderr:
        return "CANDIDATE:traceback"
    for name, want_rc, rx in EXPECTED:
        if rc == want_rc and re.search(rx, stderr):
            return name
    return "CANDIDATE:rc%d" % rc


def signature(target, rc, cls, stderr):
    last = (stderr.strip().splitlines() or [""])[-1]
    last = re.sub(r"'[^']*'|\"[^\"]*\"|/\S+", "P", last)
    last = re.sub(r"\d+", "N", last)[:160]
    return "%s|%d|%s|%s" % (target, rc, cls, last)


def canaries(spec):
    out = {}
    for name, cmd in spec.items():
        try:
            r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=10)
            out[name] = hashlib.sha256((str(r.returncode) + r.stdout).encode()).hexdigest()[:16]
        except subprocess.TimeoutExpired:
            out[name] = "timeout"  # never equals a baseline digest, so it stops the run
    return out


def sweep(patterns):
    found = []
    for pat in patterns:
        r = subprocess.run(["/usr/bin/pgrep", "-f", pat], capture_output=True, text=True)
        found += [int(p) for p in r.stdout.split() if int(p) != os.getpid()]
    for pid in set(found):
        try:
            os.kill(pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    return sorted(set(found))


class Tracker:
    def __init__(self, c):
        self.c, self.seen, self.events, self.streak = c, set(), 0, 0
        self.batch_key, self.batch_new, self.quiet_batches = None, False, 0
        self.counts, self.per_target, self.candidates = {}, {}, []

    def target_of(self, seed):
        names = self.c["target_names"]
        return names[(seed - self.c["seed"] - 1) % len(names)]

    def feed(self, ev):
        x = ev.get("extra", {})
        rc, stderr = ev["exit_code"], x.get("stderr_sample", "")
        if rc == 125 and "gh1280-gate: stopped" in stderr:
            self.gated = getattr(self, "gated", 0) + 1  # refused at the launch boundary; never ran
            return
        tgt = self.target_of(x["seed"])
        cls = classify(rc, stderr)
        sig = signature(tgt, rc, cls, stderr)
        new = sig not in self.seen
        self.seen.add(sig)
        self.events += 1
        self.counts[cls] = self.counts.get(cls, 0) + 1
        pt = self.per_target.setdefault(tgt, {})
        pt[cls] = pt.get(cls, 0) + 1
        if cls.startswith("CANDIDATE"):
            self.candidates.append({"target": tgt, "class": cls, "rc": rc, "mutant": x.get("mutant"),
                                    "seed": x["seed"], "index": x.get("index"), "signature": sig,
                                    "stderr_tail": stderr[-600:], "corpus_id": x.get("corpus_id")})
        # Novelty is the signature's first occurrence only; a repeated candidate is captured
        # above but is not new signal (review F11).
        self.streak = 0 if new else self.streak + 1
        key = (tgt, x["seed"])
        if key != self.batch_key:
            self.batch_key, self.batch_new, self.batch_n = key, False, 0
        self.batch_new |= new
        self.batch_n += 1
        if self.batch_n == self.c["batch"]:  # close the batch at its last case, not the next one
            self.quiet_batches = 0 if self.batch_new else self.quiet_batches + 1

    def stop_reason(self):
        c = self.c
        if c.get("streak_stop") and self.streak >= c["streak_stop"]:
            return "no-new-signal: %d consecutive cases with no new signature" % self.streak
        if c.get("quiet_batch_stop") and self.quiet_batches >= c["quiet_batch_stop"]:
            return "no-new-signal: %d consecutive batches without a new signature" % self.quiet_batches
        if self.events >= c["max_mutations"]:
            return "mutation budget reached (%d)" % self.events
        return None


def read_new(path, pos):
    if not os.path.exists(path):
        return [], pos
    with open(path) as fh:
        fh.seek(pos)
        data = fh.read()
    lines = data.split("\n")
    complete, tail = lines[:-1], lines[-1]
    return [json.loads(l) for l in complete if l.strip()], pos + len(data) - len(tail)


def gate(c, argv):
    """Launch boundary: runs (inside the mutant's sandbox) before every mutant. Telemetry for
    case N-1 is appended before case N launches, so the decision here is exact.

    Replay uses its own contract (separate stop file, no discovery telemetry), so an exhausted
    discovery run never blocks a replay; the canary check still applies (review F12)."""
    stopfile = c["stopfile"]
    if os.path.exists(stopfile):
        print("gh1280-gate: stopped: %s" % open(stopfile).read().strip(), file=sys.stderr)
        return 125
    t = Tracker(c)
    if os.path.exists(c["telemetry"]):
        for l in open(c["telemetry"]):
            if l.strip():
                t.feed(json.loads(l))
    reason = t.stop_reason()
    if reason is None:
        base = json.load(open(c["baseline"]))
        moved = [k for k, v in canaries(c["canaries"]).items() if base.get(k) != v]
        reason = "CANARY VIOLATION: %s" % moved if moved else None
    if reason:
        with open(stopfile, "w") as fh:
            fh.write("%s (decided before event %d)\n" % (reason, t.events + 1))
        print("gh1280-gate: stopped: %s" % reason, file=sys.stderr)
        return 125
    os.execv(sys.executable, [sys.executable] + argv)


def main():
    if len(sys.argv) > 2 and sys.argv[1] == "--gate":
        c = json.load(open(sys.argv[2]))
        return gate(c, sys.argv[sys.argv.index("--") + 1:])
    ap = argparse.ArgumentParser()
    ap.add_argument("--contract", required=True)
    ap.add_argument("--replay-telemetry", help="negative control: feed a frozen telemetry file, run nothing")
    a = ap.parse_args()
    c = json.load(open(a.contract))
    t = Tracker(c)
    report = {"contract_sha256": hashlib.sha256(open(a.contract, "rb").read()).hexdigest()}

    if a.replay_telemetry:
        for i, l in enumerate(open(a.replay_telemetry)):
            t.feed(json.loads(l))
            r = t.stop_reason()
            if r:
                report.update(stop_reason=r, stopped_at_event=i + 1)
                break
        report.update(events=t.events, counts=t.counts)
        print(json.dumps(report, indent=1))
        return 0

    pre = subprocess.run(["/usr/bin/pgrep", "-f", "|".join(c["sweep_patterns"])],
                                       capture_output=True, text=True).stdout.split()
    if pre:
        print("refusing: campaign-pattern processes already running: %s" % pre, file=sys.stderr)
        return 3
    base = canaries(c["canaries"])
    json.dump(base, open(c["baseline"], "w"))
    if os.path.exists(c["stopfile"]):
        os.remove(c["stopfile"])
    t0 = time.monotonic()
    proc = subprocess.Popen(c["gen4_argv"], cwd=c["gen4_cwd"], env=c["gen4_env"], start_new_session=True,
                            stdout=open(c["gen4_log"], "w"), stderr=subprocess.STDOUT)
    report.update(gen4_pid=proc.pid, started=time.strftime("%Y-%m-%dT%H:%M:%S%z"))
    pos, reason, last_canary = 0, None, 0.0
    while reason is None:
        time.sleep(1)
        try:
            evs, pos = read_new(c["telemetry"], pos)
        except (ValueError, KeyError) as exc:
            reason = "invalid telemetry: %s" % exc
            break
        for ev in evs:
            try:
                t.feed(ev)
            except (KeyError, TypeError) as exc:
                reason = "invalid telemetry event: %s" % exc
                break
            reason = reason or t.stop_reason()
        if reason:
            break
        if os.path.exists(c["stopfile"]):
            reason = "gate: " + open(c["stopfile"]).read().strip()
        elif time.monotonic() - t0 >= c["wall_s"]:
            reason = "wall time reached (%ds)" % c["wall_s"]
        elif time.monotonic() - last_canary >= 5:
            last_canary = time.monotonic()
            now = canaries(c["canaries"])
            moved = [k for k in base if base[k] != now[k]]
            if moved:
                reason = "CANARY VIOLATION: %s" % moved
        if reason is None and proc.poll() is not None:
            reason = "gen4 exited rc=%s" % proc.returncode
    try:
        os.killpg(proc.pid, signal.SIGTERM)
        proc.wait(timeout=10)
    except (ProcessLookupError, subprocess.TimeoutExpired):
        try:
            os.killpg(proc.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    try:  # pick up the last lines the run wrote
        for ev in read_new(c["telemetry"], pos)[0]:
            t.feed(ev)
    except Exception:
        pass
    killed = sweep(c["sweep_patterns"])
    time.sleep(1)
    survivors = subprocess.run(["/usr/bin/pgrep", "-f", "|".join(c["sweep_patterns"])],
                               capture_output=True, text=True).stdout.split()
    final = canaries(c["canaries"])
    report.update(stop_reason=reason, elapsed_s=round(time.monotonic() - t0, 1), gen4_rc=proc.returncode,
                  events=t.events, gated_events=getattr(t, "gated", 0), streak_at_stop=t.streak, quiet_batches_at_stop=t.quiet_batches,
                  counts=t.counts, per_target=t.per_target, signatures=sorted(t.seen),
                  candidates=t.candidates, swept_pids=killed, survivors_after_sweep=survivors,
                  canaries_moved=[k for k in base if base[k] != final[k]])
    json.dump(report, open(c["report"], "w"), indent=1)
    print(json.dumps({k: report[k] for k in ("stop_reason", "elapsed_s", "events", "counts",
                                             "swept_pids", "survivors_after_sweep", "canaries_moved")}))
    bad = report["survivors_after_sweep"] or report["canaries_moved"] or (reason or "").startswith(("CANARY", "invalid"))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
