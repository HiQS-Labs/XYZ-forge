"""GH-831 recon: map every registered suite to Small / Medium / Core / Off, and project a month of
merges onto the proposed tiers. Read-only: it reads test files, utils/ci-route.sh, git history and a
committed hosted telemetry file, and runs utils/ci-route.sh (a pure classifier) per merge.

Usage (from the repo root): python3 TESTS-RESULTS/2026-09-25+GH-831/suite_map.py <registry.txt> <telemetry.jsonl> <issues.json> <outdir>
  registry.txt    output of `./validate.sh --list`
  telemetry.jsonl a hosted wave qualification validation.jsonl (per-suite durations)
  issues.json     `gh issue list --state all --limit 1000 --json number,title,labels`
"""
import collections, json, os, re, subprocess, sys

registry_txt, telemetry, issues_json, outdir = sys.argv[1:5]
reg = [l.strip() for l in open(registry_txt) if l.strip().startswith("test/")]
dur = {}
for line in open(telemetry):
    r = json.loads(line)
    if r.get("event") == "suite":
        dur[r["name"]] = r["duration_ms"] / 1000
titles = {i["number"]: i["title"] for i in json.load(open(issues_json))}

route = open("utils/ci-route.sh").read()
subs = {m.group(1): m.group(2).split() for m in re.finditer(r'^SUBSYSTEM_TESTS_(\w+)="([^"]*)"', route, re.M)}
pdda, rel = set(subs["pdda"]), set(subs["releases"])
medium_owner = {t: s for s, ts in subs.items() if s not in ("pdda", "releases") for t in ts}
# Canaries: #816's blast-radius list plus #802's repo-wide static guards.
canary = {"security-scan.sh", "mktemp-trap-guard.sh", "gh308-frozen-twin-guard.sh", "gh139-pipe-grep-guard.sh",
          "gh306-registry-bidirectional.sh", "gh777-inventory-ratchet.sh", "gh1-adoption-guard.sh",
          "gh1-fixture-guard.sh", "gh184-no-tracked-scratch.sh", "sentinel-network-guard.sh"}
canary |= {n[len("test/"):] for n in reg if n.startswith(("test/gh448", "test/relay-target-root"))}


def bucket(p):
    if p.startswith(("utils/pdda/", "utils/pdda-")):
        return "pdda"
    if re.match(r"utils/py/(releases_|wave_reconcile|merge_cleanup|work_connectors|roadmap|leaderboard)"
                r"|utils/(releases-|release-lanes|leaderboard|timeline/|roadmap)|skills/[^/]+/(merge-cleanup|releases)/", p):
        return "prs"
    if (p.startswith(("src/", "bin/", "relay-automation/", "githooks/", ".github/"))
            or p in ("validate.sh", "ci-local.sh", "utils/ci-route.sh")
            or re.match(r"skills/[^/]+/(relay-xyz|relay-automation|relay)/", p)):
        return "core"
    if p.startswith(("utils/hq/", "utils/telemetry/", "utils/ate/", "utils/fuzzing/", "utils/swe-diagram/", "mini/", "skills/")):
        return "medium"
    if p.startswith("utils/"):
        return "core"  # unmapped utils/: ci-route already fails these closed to the full gate
    return "other"


files = subprocess.check_output(["git", "ls-files", "relay-automation", "utils", "bin", "src", "githooks",
                                 "skills", "mini", "validate.sh", "ci-local.sh"], text=True).split()
by_base = collections.defaultdict(set)
for f in files:
    b = os.path.basename(f)
    if re.search(r"\.(py|sh|js|mjs)$", b) or f.startswith("bin/"):
        by_base[b].add(bucket(f))
GENERIC = {"install.sh", "run.sh", "lib.sh", "common.sh", "setup.sh", "__init__.py", "main.py", "index.js",
           "utils.py", "test.sh", "check.sh", "sync.py", "cli.py", "app.py", "verify-fixture.sh"}


def signals(code):
    out = collections.Counter()
    for tok in set(re.findall(r"[A-Za-z0-9_.-]+\.(?:py|sh|js|mjs)\b", code)):
        if tok not in GENERIC:
            for b in by_base.get(tok, ()):
                out[b] += 1
    for mod in set(re.findall(r"(?:^|\s)(?:from|import)\s+([A-Za-z_][A-Za-z0-9_]*)", code, re.M)):
        for b in by_base.get(mod + ".py", ()):
            out[b] += 1
    if re.search(r"\bbin/tick\b|_setup\.sh|\btick_[ab]\b|lib/vendored-fixture\.sh", code):
        out["core"] += 1
    if re.search(r"releases_app|roadmap_items|releases\.sql|work_events|releases\.db", code):
        out["prs"] += 1
    if re.search(r"utils/pdda|pdda\.sh", code):
        out["pdda"] += 1
    return out


skills = {os.path.basename(d.rstrip("/")) for d in subprocess.check_output(["bash", "-c", "ls -d skills/*/*/"], text=True).split()}
CORE_SKILLS = {"relay-xyz", "relay", "merge-cleanup", "express", "start-marathon", "marathon-triage", "jog", "releases", "hq"}
noncore_skills = sorted(skills - CORE_SKILLS, key=len, reverse=True)

rows = []
for entry in reg:
    name = entry[len("test/"):]
    code = "\n".join(l for l in open(entry, errors="replace").read().splitlines() if not l.lstrip().startswith("#"))
    b = signals(code)
    m = re.match(r"gh(\d+)", os.path.basename(name))
    title = titles.get(int(m.group(1)), "") if m else ""
    subject = next((s for s in noncore_skills if len(s) > 3 and (re.search(rf"\b{re.escape(s)}\b", name)
                                                             or re.search(rf"\b{re.escape(s)}\b", title, re.I))), "")
    if name in canary: cls = "SMALL:canary"
    elif name in pdda: cls = "SMALL:pdda"
    elif name in rel or re.search(r"merge-cleanup|reconcil|gh645", name): cls = "SMALL:prs"
    elif name in medium_owner: cls = "MEDIUM:" + medium_owner[name]
    elif b["core"] and subject: cls = "REVIEW:core-code,skill-subject"
    elif b["core"]: cls = "CORE"
    elif b["prs"]: cls = "REVIEW:prs-code"
    elif b["pdda"]: cls = "REVIEW:pdda-code"
    elif subject or b["medium"]: cls = "OFF:skill/non-core"
    else: cls = "REVIEW:no-code-ref"
    rows.append((name, cls, round(dur.get(name, 0), 1), subject, title[:90],
                 " ".join(f"{k}={v}" for k, v in sorted(b.items()))))

os.makedirs(outdir, exist_ok=True)
with open(os.path.join(outdir, "suite-map.tsv"), "w") as f:
    f.write("suite\tclass\thosted_s\tskill_subject\tissue_title\tsignals\n")
    for r in rows:
        f.write("\t".join(map(str, r)) + "\n")

# Merge projection: every squash merge on development since 2026-08-26, classified as if its test/ and
# evidence edits were absent (the no-new-tests world). Ledger, generated views and harness data count as Small.
merges = [l.split(" ", 1) for l in subprocess.check_output(
    ["git", "log", "origin/development", "--since=2026-08-26", "--format=%H %s"], text=True).splitlines()
    if not l.endswith("chore: reconcile merged development work") and re.search(r"\(#\d+\)$", l)]
SMALLISH = re.compile(r"^test/|^TESTS-RESULTS/|\.(md|txt)$|^PROJECT/|^docs/|^relay-system/|^decisions/"
                      r"|^releases\.(db|sql)$|^harnesses\.(db|sql)$|^LEADERBOARD\.(md|html)$|^RELEASES-PREVIEW\.html$|^\.pdda-|^\.gitignore$")
MEDIUM_SUBS = {"hq", "telemetry", "ate", "swe-diagram", "agent-chorus", "standup", "skills-army-hq"}
proj = []
for sha, subj in merges:
    paths = [p for p in subprocess.check_output(["git", "diff", "--no-renames", "--name-only", f"{sha}^", sha], text=True).split()
             if not SMALLISH.search(p)]
    if not paths:
        tier = "small"
    elif all(p.startswith("skills/") and not re.match(r"skills/[^/]+/(relay-xyz|relay)/", p) for p in paths):
        tier = "small(skill code)"
    else:
        out = subprocess.run(["bash", "utils/ci-route.sh", "push"], input="\n".join(paths) + "\n", capture_output=True, text=True).stdout
        t = re.search(r"^tier=(\d)", out, re.M)
        s = set((re.search(r"^tier2_subsystems=(.*)$", out, re.M) or [None, ""])[1].split())
        tier = {"1": "small", "2": "medium" if s & MEDIUM_SUBS else "small(pdda/releases code)"}.get(t.group(1) if t else "3", "large")
    proj.append((sha[:8], tier, subj[:100]))
with open(os.path.join(outdir, "merge-projection.tsv"), "w") as f:
    f.write("merge\tprojected_tier\tsubject\n")
    for r in proj:
        f.write("\t".join(r) + "\n")

agg = collections.defaultdict(lambda: [0, 0.0])
for r in rows:
    agg[r[1]][0] += 1
    agg[r[1]][1] += r[2]
print("suite map (hosted sequential minutes, a0345e9c):")
for k, (n, s) in sorted(agg.items()):
    print(f"  {k:32s} {n:4d} suites {s / 60:6.1f} min")
print(f"  total {len(rows)}")
print(f"merge projection ({len(proj)} merges since 2026-08-26):")
for k, n in collections.Counter(t for _, t, _ in proj).most_common():
    print(f"  {k:28s} {n:4d}")
