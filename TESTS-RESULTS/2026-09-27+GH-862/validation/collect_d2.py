"""GH-862 validation, D2 inputs: every failed hosted wave-reconcile run since 2026-09-12 -> its validate.sh
summary (passed/failed suite lists). Saves one JSON line per run to d2-hosted-failed-runs.jsonl.
Runs whose log has no validate summary are recorded with summary=null (unattributed).
`sha` is the workflow's headSha (a PR run's is the PR head); `tested` is the snapshot the run actually
qualified, read from its "integrated snapshot <sha>" log line, or null when the log names none. Same-SHA
flake evidence uses `tested` only (PR #880 review, P2)."""
import json, re, subprocess, sys
out = sys.argv[1]
runs = json.loads(subprocess.check_output(["gh", "run", "list", "--workflow", "wave-reconcile.yml", "--limit", "200",
    "--json", "databaseId,conclusion,createdAt,headSha,event"], text=True))
runs = [r for r in runs if r["createdAt"] >= "2026-09-12" and r["conclusion"] == "failure"]
with open(out, "w") as f:
    for r in sorted(runs, key=lambda r: r["createdAt"]):
        log = subprocess.run(["gh", "run", "view", str(r["databaseId"]), "--log-failed"], capture_output=True, text=True).stdout
        lines = [re.sub(r"^[^\t]*\t[^\t]*\t\S+ ", "", l) for l in log.splitlines()]
        summ = None
        snap = re.search(r"integrated snapshot ([0-9a-f]{40})", log)
        for i, l in enumerate(lines):
            m = re.match(r"^passed: (\d+) / (\d+)$", l)
            if m:
                passed, failed, j = [], [], i + 1
                while j < len(lines) and lines[j].startswith("  + "): passed.append(lines[j][4:].strip()); j += 1
                if j < len(lines) and lines[j] == "failed:":
                    j += 1
                    while j < len(lines) and lines[j].startswith("  - "): failed.append(lines[j][4:].strip()); j += 1
                summ = dict(passed=passed, failed=failed, total=int(m[2]))
        f.write(json.dumps(dict(run=r["databaseId"], created=r["createdAt"], sha=r["headSha"], tested=snap[1] if snap else None, event=r["event"],
                                summary=summ)) + "\n")
        print(r["databaseId"], r["createdAt"][:16], "no summary" if summ is None else f"{len(summ['failed'])} failed of {summ['total']}: {summ['failed']}", flush=True)
