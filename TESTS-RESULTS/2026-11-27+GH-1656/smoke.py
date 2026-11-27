#!/usr/bin/env python3
"""GH-1656 smoke (GH-1088): drive the real merge_cleanup.py CLI as a subprocess against a bare-origin
fixture with the phase-B gh stub. Main path: a GitHub-CONFLICTING, locally clean PR, dry run then
--execute under --strategy merge. Adjacent path: the dry run re-run on the landed state.
Usage: python3 gh1656_smoke.py <forge clone>"""
import json, os, subprocess, sys
from pathlib import Path

REPO = Path(sys.argv[1]).resolve()
sys.path.insert(0, str(REPO / "test"))
sys.path.insert(0, str(REPO / "skills" / "2-daily" / "merge-cleanup" / "scripts"))
import gh534_phase_b_tests as b  # noqa: E402
import merge_cleanup  # noqa: E402

fx = b.LedgerFixture("run")
fx.setUp()
try:
    fx.st["infer_merged"] = True
    fx.save()
    # The synthetic repo has no githooks/: give it a minimal installer so the CLI's real GH-1576 wiring
    # check and the real `git push` hook path run (the hook records each run, then passes).
    hooklog = fx.tmp / "pre-push-runs.log"
    gh = fx.seed / "githooks"
    gh.mkdir()
    (gh / "install.sh").write_text(
        '#!/usr/bin/env bash\nset -e\nh="$(git rev-parse --git-path hooks)/pre-push"\n'
        'if [ "${1:-}" = "--check" ]; then [ -x "$h" ] && exit 0; echo "pre-push not installed" >&2; exit 1; fi\n'
        f'printf \'#!/bin/sh\\necho "pre-push ran XYZ_SKIP_PREPUSH=${{XYZ_SKIP_PREPUSH:-unset}}" >> "{hooklog}"\\nexit 0\\n\' > "$h"\n'
        'chmod +x "$h"\n')
    b.commit_all(fx.seed, "smoke: minimal githooks installer")
    b._git(fx.seed, "push", "-q", "origin", "development")
    b._git(fx.primary, "pull", "-q", "--ff-only", "origin", "development")
    base = fx.origin_dev()
    pin = fx.branch("feat/smoke", 1, lambda r: (r / "smoke.md").write_text("smoke\n"))
    fx.st["force_mergeable"] = {"1": "CONFLICTING"}
    fx.save()
    script = REPO / "skills" / "2-daily" / "merge-cleanup" / "scripts" / "merge_cleanup.py"
    env = dict(os.environ, **{b.GH_BIN_ENV: str(fx.gh), "GH_STATE": str(fx.state), "RELEASES_GH_BIN": str(fx.gh)})
    # The synthetic fixture has no githooks/: wire a pass-through pre-push hook the way the real installer would.
    env["XYZ_SKIP_PREPUSH"] = "1"  # the rung must strip it: the hook log should show unset
    common = [sys.executable, str(script), "--primary", str(fx.primary), "--root", str(fx.tmp / "no-roots"),
              "--strategy", "merge"]

    def run(label, extra):
        r = subprocess.run(common + extra, capture_output=True, text=True, env=env, timeout=600)
        print(f"\n===== {label}: rc={r.returncode} :: {' '.join(['merge_cleanup.py'] + common[3:] + extra)}")
        keep = [l for l in (r.stdout + r.stderr).splitlines()
                if "PR #1" in l or "Would merge" in l or "local-merge" in l or "ERROR" in l or "WARNING" in l]
        print("\n".join(keep[-25:]))
        return r

    d1 = run("main path, dry run", ["--prs", "1"])
    fx.pin([1])
    ex = run("main path, --execute", ["--prs", "1", "--execute"])
    st = fx.load()
    mc = st["prs"]["1"].get("mergeCommit")
    print(f"\nPR #1 state={st['prs']['1']['state']} mergeCommit={mc}")
    print("pr merge calls for #1:", [c for c in st["calls"] if c[:3] == ["pr", "merge", "1"]])
    if mc:
        print("parents:", b._git(fx.probe, "rev-parse", f"{mc}^1", f"{mc}^2").stdout.split(), "expected:", [base, pin])
    print("origin/development:", fx.origin_dev())
    print("pre-push hook runs:", hooklog.read_text().splitlines() if hooklog.exists() else [])
    d2 = run("adjacent path, dry run re-run on the landed state", [])
    after = fx.origin_dev()
    print("origin unchanged by the re-run:", after == fx.origin_dev())
    ok = (d1.returncode == 0 and "local-merge rung" in d1.stdout and "Would merge PR #1" not in d1.stdout
          and ex.returncode == 0 and st["prs"]["1"]["state"] == "MERGED"
          and not [c for c in st["calls"] if c[:3] == ["pr", "merge", "1"]]
          and d2.returncode == 0 and "Would merge PR #1" not in d2.stdout)
    print("\nSMOKE VERDICT:", "PASS" if ok else "FAIL")
    sys.exit(0 if ok else 1)
finally:
    fx.doCleanups()
