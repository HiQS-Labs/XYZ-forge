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

# Final dispositions for every suite the rules above could not settle. Each is a judgment recorded in the
# plan (R2); a suite that runs harness, PDDA or PRS code is never off (Codex plan review r1, F1). Off is
# limited to suites that execute nothing but read skill text, or run only their own skill's install.sh.
OVERRIDES = {
    **{n: "SMALL" for n in ["gh75-dashboard.sh", "gh107-timeline-json-seam.sh", "gh349-releases-roadmap-vendored.sh",
       "gh351-manifest-unship.sh", "gh360-scoped-receipt-chain-rebuild.sh", "gh424-roadmap-status-marker.sh",
       "gh491-roadmap-section-validation.sh", "gh492-roadmap-state-sweep.sh", "gh527-issue-url-repair.sh",
       "gh605-work-state.sh", "gh605-board-policy.sh", "gh784-marathon-qa-gate.sh"]},
    "gh142-ate-exit-contract.sh": "MEDIUM:ate", "synthetic/gh102-telemetry-schema.sh": "MEDIUM:ate",
    "agent-chorus-bridge.sh": "MEDIUM:agent_chorus", "gh233-agent-chorus-concurrency.sh": "MEDIUM:agent_chorus",
    "gh589-xyz-mini-sync.sh": "MEDIUM:skills_army_hq", "gh589-consult-no-tick.sh": "MEDIUM:skills_army_hq",
    "gh589-skill-viewer.sh": "MEDIUM:skills_army_hq",
    **{n: "OFF" for n in ["gh578-ci-optimize-skill.sh", "gh615-start-task-reinforce.sh",
       "gh616-start-task-commensurate-envelope.sh", "gh617-relay-xyz-commensurate-review.sh",
       "gh779-radar-ci-health.sh", "gh781-wam-radar-seed.sh", "gh778-review-code-skill.sh", "gh798-status-skill.sh"]},
}
def final(name, cls):
    if name in OVERRIDES:
        return OVERRIDES[name]
    if cls.startswith(("SMALL", "MEDIUM")) or cls == "CORE":
        return cls.split(":")[0] if cls.startswith("SMALL") else cls
    return "CORE"  # every remaining unclear suite runs harness code (reviewed in the plan's R2 list)
rows = [r + (final(r[0], r[1]),) for r in rows]

os.makedirs(outdir, exist_ok=True)
with open(os.path.join(outdir, "suite-map.tsv"), "w") as f:
    f.write("suite\tclass\thosted_s\tskill_subject\tissue_title\tsignals\tdisposition\n")
    for r in rows:
        f.write("\t".join(map(str, r)) + "\n")

# Merge projection: every squash merge on development since 2026-08-26, routed by the plan's D4 and priced by
# D5 (tier 1 -> the hosted Small run; tier 2 or 3 -> the hosted full run). Two variants:
#   as-merged     the real paths, test edits included (ci-route's own test-edit rules, incl. GH-487, apply)
#   no-test-edits test/ paths removed, the no-new-tests counterfactual. It also removes repairs to existing
#                 suites, so it overstates the Small share; as-merged understates it.
merges = [l.split(" ", 1) for l in subprocess.check_output(
    ["git", "log", "origin/development", "--since=2026-08-26", "--format=%H %s"], text=True).splitlines()
    if not l.endswith("chore: reconcile merged development work") and re.search(r"\(#\d+\)$", l)]
D4_DATA = re.compile(r"^(releases|harnesses)\.(db|sql)$|^LEADERBOARD\.html$|^RELEASES-PREVIEW\.html$")
CORE_SKILL = re.compile(r"^skills/[^/]+/(relay-xyz|relay|relay-automation|merge-cleanup|express|jog)/")
def route(paths):
    out = subprocess.run(["bash", "utils/ci-route.sh", "push"], input="\n".join(paths) + "\n",
                         capture_output=True, text=True).stdout
    t = re.search(r"^tier=(\d)", out, re.M)
    subs = (re.search(r"^tier2_subsystems=(.*)$", out, re.M) or [None, ""])[1].split()
    return (t.group(1) if t else "3"), subs
def d4_tier(paths):
    rest = []
    for p in paths:
        if D4_DATA.search(p):
            continue                      # D4: ledger, data and generated views join the docs surfaces
        if p.startswith("skills/") and not CORE_SKILL.search(p) and not route([p])[1]:
            continue                      # D4: unclaimed, non-core skill files join the docs surfaces
        rest.append(p)
    return route(rest)[0] if rest else "1"
proj = []
for sha, subj in merges:
    paths = subprocess.check_output(["git", "diff", "--no-renames", "--name-only", f"{sha}^", sha], text=True).splitlines()
    as_merged = d4_tier(paths)
    no_tests = d4_tier([p for p in paths if not p.startswith("test/")])
    proj.append((sha[:8], as_merged, no_tests, subj[:100]))
with open(os.path.join(outdir, "merge-projection.tsv"), "w") as f:
    f.write("merge\ttier_as_merged\ttier_no_test_edits\tsubject\n")
    for r in proj:
        f.write("\t".join(r) + "\n")

agg = collections.defaultdict(lambda: [0, 0.0])
for r in rows:
    agg[r[-1]][0] += 1
    agg[r[-1]][1] += r[2]
print("final dispositions (hosted sequential minutes, a0345e9c):")
for k, (n, sec) in sorted(agg.items()):
    print(f"  {k:24s} {n:4d} suites {sec / 60:6.1f} min")
print(f"  total {len(rows)}")
for i, label in ((1, "as-merged"), (2, "no-test-edits")):
    c = collections.Counter(r[i] for r in proj)
    print(f"merge projection {label} ({len(proj)} merges): tier1 {c['1']} ({100*c['1']//len(proj)}%), tier2 {c['2']}, tier3 {c['3']}")
