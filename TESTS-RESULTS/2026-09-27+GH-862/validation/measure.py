"""GH-862 validation: D1 runtime, D2 failure tally, D5 prose ratio, computed from inputs only.
No branch on any suite name. Inputs: validate.sh TESTS, gh306 EXEMPT, utils/ci-route.sh Small list, committed
qualification receipts (TESTS-RESULTS/*+GH-591/wave-*/validation.jsonl), d2-hosted-failed-runs.jsonl, suite source.
Usage: python3 measure.py <out.json>"""
import glob, json, os, re, statistics, subprocess, sys
root = subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()
here = os.path.dirname(os.path.abspath(__file__))
def arr(path, name):
    body = re.search(rf"^{name}=\((.*?)^\)", open(os.path.join(root, path)).read(), re.S | re.M)[1]
    return [w for w in re.findall(r"[\w./+-]+\.(?:sh|py)", re.sub(r"#.*", "", body))]
tests, exempt = arr("validate.sh", "TESTS"), arr("test/gh306-registry-bidirectional.sh", "EXEMPT")
small = set(re.search(r'^SUBSYSTEM_TESTS_small="([^"]*)"', open(f"{root}/utils/ci-route.sh").read(), re.M)[1].split())
# ---- D1: medians over the newest full-registry receipts whose suite set equals the current registry size ----
receipts = []
for f in sorted(glob.glob(f"{root}/TESTS-RESULTS/*+GH-591/wave-*/validation.jsonl")):
    rows = [json.loads(l) for l in open(f) if l.strip()]
    suites = {r["name"]: r for r in rows if r.get("event") == "suite" and r.get("lane") == "sequential"}
    receipts.append(dict(path=os.path.relpath(f, root), suites=suites, sha=f.split("wave-")[1][:40]))
full = [r for r in receipts if len(r["suites"]) >= 0.95 * len(tests)]
cur = [r for r in full if set(tests) <= set(r["suites"])][-8:]
dur = {t: statistics.median(r["suites"][t]["duration_ms"] / 1000 for r in cur) for t in tests if all(t in r["suites"] for r in cur)}
gate = statistics.median(sum(s["duration_ms"] for s in r["suites"].values()) / 1000 for r in cur)
rank = {t: i + 1 for i, t in enumerate(sorted(dur, key=dur.get, reverse=True))}
# ---- D2: k of N executions since 2026-09-12 (green = receipts + zero-fail summaries; red = failed lists) ----
exec_n, fail_k, red_shas, green_shas = {}, {}, {}, {}
for r in receipts:
    if r["path"].split("/")[1][:10] >= "2026-09-12":
        for t in r["suites"]:
            exec_n[t] = exec_n.get(t, 0) + 1; green_shas.setdefault(t, set()).add(r["sha"])
for l in open(f"{here}/d2-hosted-failed-runs.jsonl"):
    run = json.loads(l); s = run["summary"]
    if not s: continue
    tested = run.get("tested")  # the qualified snapshot, not headSha; None = attribution unknown
    for t in s["passed"]:
        exec_n[t] = exec_n.get(t, 0) + 1
        if tested: green_shas.setdefault(t, set()).add(tested)
    for t in s["failed"]:
        exec_n[t] = exec_n.get(t, 0) + 1; fail_k[t] = fail_k.get(t, 0) + 1
        if tested: red_shas.setdefault(t, set()).add(tested)
unattributed = sum(1 for l in open(f"{here}/d2-hosted-failed-runs.jsonl") if json.loads(l)["summary"] is None)
# ---- D5: per assertion line (a `pass`/`ok` call), does it grep a repo doc, run repo code, or neither? ----
DOC = re.compile(r"\.md\b|SKILL|/docs/|README|ROUTER|AGENTS|ARCHITECTURE|CHANGELOG")
def d5(suite):
    path = next((p for p in (f"{root}/test/{suite}", f"{root}/test/{suite}".replace("test/test/", "test/")) if os.path.isfile(p)), None)
    if not path: return None
    src = open(path).read()
    vars_ = dict(re.findall(r'^\s*([A-Z_][A-Z0-9_]*)="?([^"\n]*)"?', src, re.M))
    def resolve(tok, depth=0):
        v = vars_.get(tok, "")
        for m in re.findall(r"\$\{?([A-Z_][A-Z0-9_]*)\}?", v):
            if depth < 5: v += " " + resolve(m, depth + 1)
        return v
    doc = code = total = 0
    for line in src.splitlines():
        if not re.search(r"(&&|\|\||then|^\s*)\s*(pass|ok)\s+[\"']", line): continue
        total += 1
        refs = " ".join([line] + [resolve(m) for m in re.findall(r"\$\{?([A-Z_][A-Z0-9_]*)\}?", line)])
        fixture = re.search(r"\$\{?(WORK|TMP|TMPDIR|SANDBOX|FIX|T)\b", line)
        if "grep" in line and DOC.search(refs) and not fixture: doc += 1
        elif re.search(r"\brc\b|\$\?|bash |python3 |run_|\$\(|\bout\b|-eq|-ne", line): code += 1
    return dict(assertions=total, doc_greps=doc, code=code, ratio=round(doc / total, 2) if total else None)
suites = sorted(set(tests) | set(exempt))
out = dict(registry_sha=subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(),
           registered=len(tests), exempt=len(exempt), d1_receipts=[r["path"] for r in cur], median_gate_s=round(gate, 1),
           d2_failed_runs=sum(1 for _ in open(f"{here}/d2-hosted-failed-runs.jsonl")), d2_unattributed=unattributed,
           suites={t: dict(registered=t in tests, tier="Small" if t in small else "Large", median_s=round(dur[t], 1) if t in dur else None,
                           rank=rank.get(t), share=round(100 * dur[t] / gate, 2) if t in dur else None,
                           fails=fail_k.get(t, 0), runs=exec_n.get(t, 0),
                           same_sha_divergence=sorted(s[:8] for s in red_shas.get(t, set()) & green_shas.get(t, set())),
                           d5=d5(t)) for t in suites})
json.dump(out, open(sys.argv[1], "w"), indent=1, sort_keys=True)
print(f"registry {out['registered']} (+{out['exempt']} exempt) at {out['registry_sha'][:8]}; D1 from {len(cur)} receipts, median gate {out['median_gate_s']} s; D2 {out['d2_failed_runs']} failed runs ({unattributed} unattributed)")
