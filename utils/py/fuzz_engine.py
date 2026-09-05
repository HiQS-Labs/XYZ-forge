#!/usr/bin/env python3
"""fuzz_engine.py — GH-299 Gen 4 Phase 3: feedback-guided mutational fuzz engine + parity oracle.

True generative fuzzing, not enumerated variation: a seeded PRNG drives four mutator families
over a base argv, every mutant's subprocess feedback vector
    <exit_code, signal, sha256(stderr_normalized)[:16], duration_bucket>
decides whether it is *novel*, and novel mutants join a bounded corpus that seeds the next
round. The engine is 100% replayable from `--seed`.

Mutator families (all deterministic under the seed):
  slice      drop / duplicate / swap / truncate tokens
  boundary   0, -1, 2**31, 2**63, "", whitespace, very long, negative-looking flags
  unicode    zero-width, RTL override, combining marks, emoji, NUL-adjacent, NFD forms
  structure  unbalanced quotes/braces, JSON/YAML fragments, traversal, spaces-in-path, `--`

Corpus (`.fuzz_corpus/`, gitignored): one JSON per entry; hard cap (default 500); eviction by
    score = 0.7 × novelty + 0.3 × recency
where novelty is 1 / (number of corpus entries sharing the feedback signature) and recency
decays linearly with age in the corpus; on a signature collision the *smaller* mutant wins.

Differential Cross-Twin Parity Oracle (`--parity-env KEY=VALUE`, e.g. `XYZ_PYTHON=0`): every
mutant runs twice — authoritative env and the twin env — and any divergence in
(exit_code, stderr_digest) is an anomaly tagged `parity`.

Telemetry: one `TelemetryEvent(phase="fuzz")` per mutant into --telemetry-out; counterexamples
(Tier-1 fail/anomaly) carry `extra.stderr_sample` so Phase 4 can cluster and reproduce them.

CLI:
  fuzz_engine.py --mode suite
  fuzz_engine.py --mode fuzz --target "python3 tool.py {mutant}" --seed 7 --iterations 200 \\
      --cwd DIR --corpus DIR/.fuzz_corpus --telemetry-out OUT.jsonl [--parity-env XYZ_PYTHON=0]
  fuzz_engine.py --mode plan --target ... --seed 7 --iterations 20 --json    # mutants only, no execution
  fuzz_engine.py --mode replay --corpus DIR --id <entry-id> --target ...
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import random
import shlex
import subprocess
import sys
import time
import unicodedata
from typing import Any, Dict, List, Optional, Sequence, Tuple

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

from adaptive_ate import classify_stderr, load_thresholds, tier1_classify  # noqa: E402
from telemetry_schema import (  # noqa: E402
    TelemetryEvent,
    append_jsonl,
    duration_bucket,
    event_from_completed,
    new_run_id,
    stderr_digest,
)

CORPUS_CAP = 500
NOVELTY_WEIGHT, RECENCY_WEIGHT = 0.7, 0.3
FAMILIES = ("slice", "boundary", "unicode", "structure")

BOUNDARY_SCALARS = ["0", "-1", "1", str(2**31 - 1), str(2**31), str(2**63), str(-(2**63)), "", " ", "\t",
                    "9" * 64, "1e309", "NaN", "0x7fffffff", "--", "-", "--=", "=", "%s%s%n", "$(true)", "`true`"]
UNICODE_SNIPPETS = ["​", "‮", "́", "﻿", "🐍", "ａｂｃ", "é", "é", " ", "𝔘𝔫𝔦", "𐌰", " "]
STRUCTURE_SNIPPETS = ['{"a":', "[1,2", "key: [", "'", '"', "'\"", "../../etc/passwd", "path with spaces/x",
                      "-", "--", "--flag=", "--flag=\"\"", "a=b=c", "{}", "[]", "null", "true", "@file", "~", "*", "?"]


# ---- mutators ------------------------------------------------------------------------------------
def mutate(base: Sequence[str], rng: random.Random, family: Optional[str] = None) -> Tuple[List[str], str]:
    """Return (mutant_argv, family). Never returns the base unchanged."""
    fam = family or rng.choice(FAMILIES)
    toks = list(base)
    for _ in range(8):  # try a few times to get an actual change
        cand = list(toks)
        if fam == "slice":
            op = rng.choice(["drop", "dup", "swap", "trunc", "shuffle"])
            if op == "drop" and cand:
                del cand[rng.randrange(len(cand))]
            elif op == "dup" and cand:
                i = rng.randrange(len(cand)); cand.insert(i, cand[i])
            elif op == "swap" and len(cand) >= 2:
                i, j = rng.sample(range(len(cand)), 2); cand[i], cand[j] = cand[j], cand[i]
            elif op == "trunc" and cand:
                i = rng.randrange(len(cand)); t = cand[i]; cand[i] = t[: max(0, rng.randrange(len(t) + 1))]
            elif op == "shuffle" and len(cand) >= 2:
                rng.shuffle(cand)
        elif fam == "boundary":
            if cand and rng.random() < 0.6:
                cand[rng.randrange(len(cand))] = rng.choice(BOUNDARY_SCALARS)
            else:
                cand.insert(rng.randrange(len(cand) + 1), rng.choice(BOUNDARY_SCALARS))
        elif fam == "unicode":
            snip = rng.choice(UNICODE_SNIPPETS)
            if cand and rng.random() < 0.7:
                i = rng.randrange(len(cand)); t = cand[i]
                pos = rng.randrange(len(t) + 1)
                cand[i] = t[:pos] + snip + t[pos:]
                if rng.random() < 0.3:
                    cand[i] = unicodedata.normalize(rng.choice(["NFD", "NFKC"]), cand[i])
            else:
                cand.insert(rng.randrange(len(cand) + 1), snip)
        else:  # structure
            snip = rng.choice(STRUCTURE_SNIPPETS)
            if cand and rng.random() < 0.5:
                i = rng.randrange(len(cand)); cand[i] = cand[i] + snip if rng.random() < 0.5 else snip
            else:
                cand.insert(rng.randrange(len(cand) + 1), snip)
        if cand != toks:
            return cand, fam
    return toks + [rng.choice(BOUNDARY_SCALARS)], fam


def plan_mutants(base: Sequence[str], seed: int, iterations: int, corpus_seeds: Sequence[Sequence[str]] = ()) -> List[Dict[str, Any]]:
    """The deterministic mutant sequence for (seed, iterations): replayable by construction."""
    rng = random.Random(seed)
    pool: List[Sequence[str]] = [list(base)] + [list(s) for s in corpus_seeds]
    out: List[Dict[str, Any]] = []
    for i in range(iterations):
        parent = pool[0] if (i < 4 or rng.random() < 0.5 or len(pool) == 1) else rng.choice(pool)
        mutant, fam = mutate(parent, rng)
        out.append({"index": i, "family": fam, "argv": mutant, "parent_size": len(" ".join(parent))})
    return out


# ---- corpus --------------------------------------------------------------------------------------
class Corpus:
    def __init__(self, path: str, cap: int = CORPUS_CAP) -> None:
        self.path = path
        self.cap = cap
        os.makedirs(path, exist_ok=True)
        self.entries: Dict[str, Dict[str, Any]] = {}
        for fn in sorted(os.listdir(path)):
            if fn.endswith(".json"):
                try:
                    with open(os.path.join(path, fn), "r", encoding="utf-8") as fh:
                        e = json.load(fh)
                    self.entries[e["id"]] = e
                except (OSError, ValueError, KeyError):
                    continue
        self.tick = max((e.get("added_tick", 0) for e in self.entries.values()), default=0)

    @staticmethod
    def signature(vector: Sequence[Any]) -> str:
        return hashlib.sha256(json.dumps(list(vector), sort_keys=True).encode()).hexdigest()[:16]

    @staticmethod
    def size_of(argv: Sequence[str]) -> int:
        return sum(len(a.encode("utf-8", "replace")) for a in argv) + len(argv)

    def _sig_counts(self) -> Dict[str, int]:
        counts: Dict[str, int] = {}
        for e in self.entries.values():
            counts[e["signature"]] = counts.get(e["signature"], 0) + 1
        return counts

    def novelty_of(self, signature: str) -> float:
        return 1.0 / (1 + self._sig_counts().get(signature, 0))

    def scores(self) -> Dict[str, float]:
        counts = self._sig_counts()
        span = max(1, self.tick - min((e["added_tick"] for e in self.entries.values()), default=self.tick))
        out: Dict[str, float] = {}
        for eid, e in self.entries.items():
            novelty = 1.0 / counts[e["signature"]]
            recency = 1.0 - (self.tick - e["added_tick"]) / span if span else 1.0
            out[eid] = NOVELTY_WEIGHT * novelty + RECENCY_WEIGHT * recency
        return out

    def consider(self, argv: Sequence[str], vector: Sequence[Any], verdict: str, family: str, env: Optional[Dict[str, str]] = None) -> Tuple[str, Optional[str]]:
        """Add a mutant if it earns a place. Returns (action, entry_id): added|replaced|dropped|evicted+added."""
        sig = self.signature(vector)
        size = self.size_of(argv)
        same = [e for e in self.entries.values() if e["signature"] == sig]
        if same:
            smallest = min(same, key=lambda e: e["size"])
            if size < smallest["size"]:
                # The slot represents the signature: keep its id so earlier counterexample
                # references (telemetry rows, Phase 4 clusters) still resolve after a replace.
                self._remove(smallest["id"])
                return "replaced", self._add(argv, vector, sig, size, verdict, family, env, eid=smallest["id"])
            return "dropped", None
        action = "added"
        if len(self.entries) >= self.cap:
            victim = min(self.scores().items(), key=lambda kv: kv[1])[0]
            self._remove(victim)
            action = "evicted+added"
        return action, self._add(argv, vector, sig, size, verdict, family, env)

    def _add(self, argv, vector, sig, size, verdict, family, env, eid: Optional[str] = None) -> str:
        self.tick += 1
        eid = eid or hashlib.sha256((sig + json.dumps(list(argv))).encode("utf-8", "replace")).hexdigest()[:12]
        entry = {"id": eid, "argv": list(argv), "env": dict(env or {}), "vector": list(vector), "signature": sig,
                 "size": size, "verdict": verdict, "family": family, "added_tick": self.tick, "added_at": time.time()}
        self.entries[eid] = entry
        tmp = os.path.join(self.path, f".{eid}.tmp")
        with open(tmp, "w", encoding="utf-8") as fh:
            json.dump(entry, fh, sort_keys=True)
        os.replace(tmp, os.path.join(self.path, f"{eid}.json"))
        return eid

    def _remove(self, eid: str) -> None:
        self.entries.pop(eid, None)
        try:
            os.remove(os.path.join(self.path, f"{eid}.json"))
        except OSError:
            pass

    def seeds(self, limit: int = 64) -> List[List[str]]:
        ranked = sorted(self.scores().items(), key=lambda kv: -kv[1])[:limit]
        return [self.entries[eid]["argv"] for eid, _ in ranked]

    def __len__(self) -> int:
        return len(self.entries)


# ---- execution -----------------------------------------------------------------------------------
def build_argv(target: str, mutant: Sequence[str]) -> List[str]:
    if "{mutant}" not in target:
        raise ValueError("target needs a {mutant} placeholder")
    head, _, tail = target.partition("{mutant}")
    return shlex.split(head) + list(mutant) + shlex.split(tail)


def execute(argv: List[str], cwd: str, timeout: float, env: Optional[Dict[str, str]] = None) -> Dict[str, Any]:
    """Run one mutant in its own process group; on timeout the WHOLE group is SIGKILLed.

    A target like a test runner forks grandchildren; killing only the parent (what
    subprocess.run does) leaves them running the suite in the sandbox for minutes — observed
    on the first real campaign run, where orphaned validate.sh runs outlived their mutant.
    """
    full_env = dict(os.environ)
    full_env.update(env or {})
    t0 = time.monotonic()
    proc = None
    try:
        proc = subprocess.Popen(argv, cwd=cwd, env=full_env, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                stdin=subprocess.DEVNULL, start_new_session=True)
        _, err_b = proc.communicate(timeout=timeout)
        rc = proc.returncode
        err = err_b.decode("utf-8", "replace")
    except subprocess.TimeoutExpired:
        _kill_group(proc)
        try:
            _, err_b = proc.communicate(timeout=5)
        except subprocess.TimeoutExpired:
            err_b = b""
        rc = 124
        err = err_b.decode("utf-8", "replace") + f"\n[timeout after {timeout}s; process group killed]"
    except (FileNotFoundError, OSError, ValueError) as exc:  # ValueError: embedded NUL in argv
        rc, err = 127, f"spawn failed: {exc}"
    ms = (time.monotonic() - t0) * 1000.0
    signal_no = -rc if rc < 0 else 0
    if rc < 0:
        rc = 128 + signal_no
    return {"rc": rc, "signal": signal_no, "stderr": err, "duration_ms": ms,
            "vector": [rc, signal_no, stderr_digest(err), duration_bucket(ms)]}


def _kill_group(proc: Optional["subprocess.Popen"]) -> None:
    if proc is None:
        return
    import signal as _signal
    try:
        os.killpg(proc.pid, _signal.SIGKILL)
    except (ProcessLookupError, PermissionError, OSError):
        try:
            proc.kill()
        except OSError:
            pass


def fuzz(
    target: str,
    cwd: str,
    seed: int,
    iterations: int,
    corpus_dir: str,
    telemetry_out: Optional[str] = None,
    timeout_budget: float = 30.0,
    parity_env: Optional[Dict[str, str]] = None,
    base_env: Optional[Dict[str, str]] = None,
    corpus_cap: int = CORPUS_CAP,
    thresholds: Optional[Dict[str, Any]] = None,
    stop_after_counterexamples: Optional[int] = None,
    base: Optional[Sequence[str]] = None,
) -> Dict[str, Any]:
    run_id = new_run_id()
    thresholds = thresholds or load_thresholds()
    corpus = Corpus(corpus_dir, cap=corpus_cap)
    build_argv(target, ["{mutant}"])  # validates the placeholder early
    base_mutant: List[str] = list(base or [])  # the mutable part; the target's fixed argv is head/tail
    plan = plan_mutants(base_mutant, seed, iterations, corpus.seeds())
    counts = {"pass": 0, "fail": 0, "anomaly": 0}
    corpus_actions: Dict[str, int] = {}
    parity_divergences = 0
    counterexamples: List[Dict[str, Any]] = []
    novel = 0
    for m in plan:
        argv = build_argv(target, m["argv"])
        res = execute(argv, cwd, timeout_budget, base_env)
        verdict, reason = tier1_classify(res["rc"], res["signal"], res["stderr"], res["duration_ms"], thresholds)
        parity: Optional[Dict[str, Any]] = None
        if parity_env:
            twin = execute(argv, cwd, timeout_budget, {**(base_env or {}), **parity_env})
            diverged = (twin["rc"], twin["vector"][2]) != (res["rc"], res["vector"][2])
            parity = {"twin_rc": twin["rc"], "twin_stderr_digest": twin["vector"][2], "diverged": diverged}
            if diverged:
                parity_divergences += 1
                verdict, reason = "anomaly", f"parity: authoritative rc={res['rc']} vs twin rc={twin['rc']}"
        counts[verdict] += 1
        sig = Corpus.signature(res["vector"])
        was_novel = corpus.novelty_of(sig) == 1.0
        novel += int(was_novel)
        action, eid = corpus.consider(m["argv"], res["vector"], verdict, m["family"], base_env)
        corpus_actions[action] = corpus_actions.get(action, 0) + 1
        ev = event_from_completed("fuzz", argv, res["rc"] if not res["signal"] else -res["signal"], res["stderr"], res["duration_ms"],
                                  run_id=run_id, env=base_env, mutant=m["argv"], family=m["family"], seed=seed, index=m["index"],
                                  corpus_id=eid, corpus_action=action, novel=was_novel, tier_1_reason=reason,
                                  handled_rejection=(verdict == "fail" and classify_stderr(res["stderr"]) in ("usage", "missing_file")),
                                  stderr_sample=res["stderr"][-2000:], parity=parity, target=target, cwd=cwd)
        ev.tier_1_verdict = verdict
        if telemetry_out:
            append_jsonl(telemetry_out, ev)
        # A handled rejection (usage error, missing file) is the target doing its job; a
        # counterexample is an anomaly or a fail whose stderr looks like an unhandled failure.
        interesting = verdict == "anomaly" or (verdict == "fail" and classify_stderr(res["stderr"]) in ("crash", "assertion", "generic_error"))
        if interesting:
            counterexamples.append({"index": m["index"], "argv": argv, "mutant": m["argv"], "verdict": verdict, "reason": reason,
                                    "stderr_digest": res["vector"][2], "corpus_id": eid})
            if stop_after_counterexamples and len(counterexamples) >= stop_after_counterexamples:
                break
    return {
        "run_id": run_id, "seed": seed, "iterations": len(plan), "executed": sum(counts.values()), "counts": counts,
        "novel_vectors": novel, "corpus_size": len(corpus), "corpus_cap": corpus_cap, "corpus_actions": corpus_actions,
        "parity_divergences": parity_divergences, "counterexamples": counterexamples, "telemetry_out": telemetry_out,
    }


# ---- self-test -----------------------------------------------------------------------------------
def run_suite(as_json: bool = False) -> int:
    import tempfile
    checks: List[Tuple[str, bool, str]] = []

    def ok(name: str, cond: bool, detail: str = "") -> None:
        checks.append((name, bool(cond), detail))

    p1 = plan_mutants(["--jobs", "4", "--mode", "fast"], 42, 50)
    p2 = plan_mutants(["--jobs", "4", "--mode", "fast"], 42, 50)
    p3 = plan_mutants(["--jobs", "4", "--mode", "fast"], 43, 50)
    ok("seed replay: identical plan for identical seed", p1 == p2)
    ok("seed replay: different seed, different plan", p1 != p3)
    ok("every mutant differs from its parent", all(m["argv"] != ["--jobs", "4", "--mode", "fast"] for m in p1))
    ok("all four mutator families fire in 50 iterations", set(m["family"] for m in p1) == set(FAMILIES), str(sorted(set(m["family"] for m in p1))))

    with tempfile.TemporaryDirectory(prefix="gen4-fuzz.") as td:
        c = Corpus(os.path.join(td, "corpus"), cap=5)
        for i in range(5):
            c.consider([f"m{i}"], [i, 0, f"sig{i}", "fast_<1s"], "pass", "slice")
        ok("corpus fills to cap", len(c) == 5)
        action, _ = c.consider(["new"], [99, 0, "sig99", "fast_<1s"], "fail", "boundary")
        ok("novel entry beyond cap evicts the lowest-scored one", action == "evicted+added" and len(c) == 5, action)
        action, _ = c.consider(["m4-bigger-mutant"], [4, 0, "sig4", "fast_<1s"], "pass", "slice")
        ok("signature collision with a bigger mutant is dropped", action == "dropped", action)
        action, _ = c.consider(["m"], [4, 0, "sig4", "fast_<1s"], "pass", "slice")
        ok("signature collision with a smaller mutant replaces", action == "replaced" and len(c) == 5, action)
        c2 = Corpus(os.path.join(td, "corpus"), cap=5)
        ok("corpus persists to disk and reloads", len(c2) == 5 and set(c2.entries) == set(c.entries))
        # duplicate-signature flood: novelty pressure must keep distinct signatures over duplicates
        c3 = Corpus(os.path.join(td, "c3"), cap=4)
        for i in range(4):
            c3.consider([f"d{i}"], [0, 0, "same", "fast_<1s"] if i else [1, 0, "unique", "fast_<1s"], "pass", "slice")
        c3.consider(["x"], [2, 0, "fresh", "fast_<1s"], "pass", "slice")
        sigs = [e["signature"] for e in c3.entries.values()]
        ok("eviction removes a duplicate-signature entry, not the unique one", sigs.count(Corpus.signature([1, 0, "unique", "fast_<1s"])) == 1)

        # end-to-end against a fixture that crashes on a boundary token
        tool = os.path.join(td, "tool.py")
        with open(tool, "w") as fh:
            fh.write("import sys\na=sys.argv[1:]\n"
                     "if '-1' in a: sys.stderr.write('ValueError: negative jobs\\n'); sys.exit(1)\n"
                     "if any('\\u202e' in x for x in a): sys.stderr.write('Traceback: rtl\\n'); sys.exit(1)\n"
                     "sys.exit(0)\n")
        rep = fuzz(f"{sys.executable} {tool} {{mutant}}", td, 7, 120, os.path.join(td, "fc"), os.path.join(td, "t.jsonl"), timeout_budget=10)
        ok("fuzz executes the whole plan", rep["executed"] == 120, str(rep["executed"]))
        ok("fuzz finds the planted counterexamples", rep["counts"]["fail"] >= 1, str(rep["counts"]))
        ok("corpus grows with novel vectors", rep["corpus_size"] >= 2, str(rep["corpus_size"]))
        n_lines = sum(1 for _ in open(os.path.join(td, "t.jsonl")))
        ok("one telemetry row per mutant", n_lines == 120, str(n_lines))
        rep2 = fuzz(f"{sys.executable} {tool} {{mutant}}", td, 7, 30, os.path.join(td, "fc2"), None, timeout_budget=10)
        rep3 = fuzz(f"{sys.executable} {tool} {{mutant}}", td, 7, 30, os.path.join(td, "fc3"), None, timeout_budget=10)
        ok("same seed replays the same counterexample set", [c["mutant"] for c in rep2["counterexamples"]] == [c["mutant"] for c in rep3["counterexamples"]])
        # parity: twin env flips behaviour on one token
        twin = os.path.join(td, "twin.py")
        with open(twin, "w") as fh:
            fh.write("import os,sys\na=sys.argv[1:]\n"
                     "if os.environ.get('TWIN')=='1' and '0' in a: sys.stderr.write('twin: zero unsupported\\n'); sys.exit(2)\n"
                     "sys.exit(0)\n")
        rep4 = fuzz(f"{sys.executable} {twin} {{mutant}}", td, 11, 80, os.path.join(td, "fc4"), None, timeout_budget=10, parity_env={"TWIN": "1"})
        ok("parity oracle detects a diverging twin", rep4["parity_divergences"] >= 1, str(rep4["parity_divergences"]))
        rep5 = fuzz(f"{sys.executable} {twin} {{mutant}}", td, 11, 40, os.path.join(td, "fc5"), None, timeout_budget=10, parity_env={"TWIN": "0"})
        ok("parity oracle is silent when twins agree", rep5["parity_divergences"] == 0, str(rep5["parity_divergences"]))

    failed = [c for c in checks if not c[1]]
    if as_json:
        print(json.dumps({"checks": [{"name": n, "ok": o, "detail": d} for n, o, d in checks], "passed": not failed}, indent=2))
    else:
        for n, o, d in checks:
            print(f"  {'PASS' if o else 'FAIL'}: {n}" + (f" ({d})" if d else ""))
        print(f"SUITE_RESULT={'PASS' if not failed else 'FAIL'} ({len(checks) - len(failed)}/{len(checks)})")
    return 0 if not failed else 1


# ---- CLI -------------------------------------------------------------------------------------------
def main() -> int:
    p = argparse.ArgumentParser(description="GH-299 Gen 4 feedback-guided mutational fuzz engine")
    p.add_argument("--mode", choices=["suite", "fuzz", "plan", "replay"], default="suite")
    p.add_argument("--target", help='command with a {mutant} placeholder, e.g. "python3 utils/py/releases_app.py {mutant}"')
    p.add_argument("--base", default="", help="initial mutable argv (shell-split) that mutants derive from")
    p.add_argument("--seed", type=int, default=0)
    p.add_argument("--iterations", type=int, default=100)
    p.add_argument("--cwd", default=os.getcwd())
    p.add_argument("--corpus", default=".fuzz_corpus")
    p.add_argument("--corpus-cap", type=int, default=CORPUS_CAP)
    p.add_argument("--timeout-budget", type=float, default=30.0, help="seconds per mutant")
    p.add_argument("--telemetry-out")
    p.add_argument("--parity-env", action="append", default=[], help="KEY=VALUE for the twin run (repeatable)")
    p.add_argument("--env", action="append", default=[], help="KEY=VALUE for every run (repeatable)")
    p.add_argument("--stop-after", type=int, help="stop after N counterexamples")
    p.add_argument("--id", help="corpus entry id for --mode replay")
    p.add_argument("--json", action="store_true")
    a = p.parse_args()

    if a.mode == "suite":
        return run_suite(a.json)
    if not a.target:
        print("--target required", file=sys.stderr)
        return 2
    base_env = dict(kv.split("=", 1) for kv in a.env if "=" in kv) or None
    parity_env = dict(kv.split("=", 1) for kv in a.parity_env if "=" in kv) or None
    if a.mode == "plan":
        plan = plan_mutants(shlex.split(a.base), a.seed, a.iterations)
        if a.json:
            print(json.dumps(plan, ensure_ascii=False))
        else:
            for m in plan:
                print(f"{m['index']:4d} {m['family']:9s} {' '.join(shlex.quote(x) for x in build_argv(a.target, m['argv']))}")
        return 0
    if a.mode == "replay":
        c = Corpus(a.corpus, cap=a.corpus_cap)
        e = c.entries.get(a.id or "")
        if not e:
            print(f"no corpus entry {a.id!r} in {a.corpus}", file=sys.stderr)
            return 2
        res = execute(build_argv(a.target, e["argv"]), a.cwd, a.timeout_budget, {**(base_env or {}), **e.get("env", {})})
        same = res["vector"][:3] == e["vector"][:3]
        print(json.dumps({"id": e["id"], "argv": e["argv"], "recorded": e["vector"], "observed": res["vector"], "reproduced": same}, indent=2, ensure_ascii=False))
        return 0 if same else 1
    rep = fuzz(a.target, a.cwd, a.seed, a.iterations, a.corpus, a.telemetry_out, a.timeout_budget, parity_env, base_env, a.corpus_cap,
               stop_after_counterexamples=a.stop_after, base=shlex.split(a.base))
    if a.json:
        print(json.dumps(rep, indent=2, ensure_ascii=False))
    else:
        print(f"fuzz seed={rep['seed']} executed={rep['executed']} {rep['counts']} novel={rep['novel_vectors']} corpus={rep['corpus_size']}/{rep['corpus_cap']} parity_divergences={rep['parity_divergences']} counterexamples={len(rep['counterexamples'])}")
    return 0 if not rep["counterexamples"] else 1


if __name__ == "__main__":
    sys.exit(main())
