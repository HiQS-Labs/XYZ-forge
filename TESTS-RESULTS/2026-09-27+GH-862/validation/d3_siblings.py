"""GH-862 validation, D3/D4 sibling search for NIGHTLY: for each heavy suite (rank 4-10, 0 failures), list the repo
scripts it invokes, then every registered suite that invokes one of the same targets, with that suite's median.
A NIGHTLY sibling must be faster (<= 20% of the heavy suite's median) and share the invoked target.
Computed from source and measured.json; no suite names in the logic."""
import json, os, re, subprocess, sys
root = subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()
m = json.load(open(sys.argv[1])); S = m["suites"]
INV = re.compile(r'(?:bash|python3|exec|sh)\s+"?\$\{?[A-Z_]*\}?/?((?:utils|relay-automation|skills|githooks)/[\w./-]+\.(?:sh|py))|(?:bash|python3)\s+"?((?:utils|relay-automation|skills|githooks)/[\w./-]+\.(?:sh|py))')
def targets(suite):
    p = f"{root}/test/{suite}"
    return set(a or b for a, b in INV.findall(open(p).read())) if os.path.isfile(p) else set()
tmap = {t: targets(t) for t in S if S[t]["registered"]}
heavy = [t for t in S if S[t]["rank"] and 4 <= S[t]["rank"] <= 10 and S[t]["fails"] == 0]
for h in sorted(heavy, key=lambda t: S[t]["rank"]):
    mine = tmap[h]
    sibs = sorted(((t, S[t]["median_s"], sorted(mine & tmap[t])) for t in tmap if t != h and mine & tmap[t] and S[t]["median_s"]),
                  key=lambda x: x[1])
    fast = [s for s in sibs if s[1] <= 0.2 * S[h]["median_s"]]
    print(f"#{S[h]['rank']} {h} {S[h]['median_s']}s targets={sorted(mine) or 'none parsed'}")
    print(f"    siblings sharing a target: {len(sibs)}; fast (<=20%): {[(s[0], s[1], s[2]) for s in fast[:4]] or 'none found'}")
