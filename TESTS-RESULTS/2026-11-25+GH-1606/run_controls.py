#!/usr/bin/env python3
"""GH-1606 manual red/green controls. NOT a test suite and not registered anywhere (AGENTS.md
"No new tests", GH-831): a one-off driver whose output is the retained evidence (provenance.jsonl).

It reuses the existing phase B `LedgerFixture` (bare origin, seeded ledger, primary clone, `gh` stub)
and the PR setup of `TestPhase5EndToEnd.test_two_prs_second_conflicts_after_first_lands_and_b1_resolves_it`
(a real B1 repair, a real push to the fixture's bare origin, a landing). It adds two DECLARED controlled
seams to the fixture's seed commit, which the fixture lacks (GH-1576 broke it; measured red at base):

  * githooks/install.sh  - exits 0, standing in for real hook wiring (witnessed by GH-1576's own evidence)
  * validate.sh          - a shim answering `--print-mode` only: exits 3 with an `ENVIRONMENT FAULT:` line
                           when $GH1606_TOOLCHAIN=fault, else exits 0. It stands in for the toolchain only;
                           the REAL validate.sh behaviour is witnessed separately (AC-1, real clone).

Each fixture scenario runs in its own process against ONE clone's tree (the fixture imports its own
repo's scripts), so BASE and CANDIDATE are never mixed:

    run_controls.py --base-repo <clone at base> --candidate-repo <task clone> --out <dir>
"""
import argparse
import contextlib
import io
import json
import os
import subprocess
import sys
import unittest.mock as mock
from datetime import datetime, timezone
from pathlib import Path

SENTINEL = "@@GH1606-RESULT@@"
SHIM = r'''#!/usr/bin/env bash
# GH-1606 controlled seam: stands in for validate.sh's toolchain probe ONLY (`--print-mode`).
[ "$1" = "--print-mode" ] || exit 0
if [ "${GH1606_TOOLCHAIN:-ok}" = "usage" ]; then   # a validate.sh that does not know --print-mode (PR #1614 review)
  echo "usage: validate.sh [--tier N] [options]" >&2
  exit 2
fi
if [ "${GH1606_TOOLCHAIN:-ok}" = "fault" ]; then
  echo "ENVIRONMENT FAULT: python3 (/usr/bin/python3) version 3.9.6; missing modules: yaml,pytest,requests,mypy; requires Python >=3.10 (fixture shim of validate.sh:1043)"
  exit 3
fi
exit 0
'''
INSTALLER = "#!/usr/bin/env bash\n# GH-1606 controlled seam: stands in for real pre-push hook wiring.\nexit 0\n"
SCENARIOS = ["S1_fault_refusing_push", "S3_healthy", "S4_fault_then_resume", "S5_consumer_no_validate",
             "S6_dry_run", "S7_ceiling_resume", "S8_unknown_flag_validate"]


# ---------------------------------------------------------------------------------------------------
# one scenario, in-process, against one clone's tree
# ---------------------------------------------------------------------------------------------------
def run_one(repo, scenario):
    sys.path.insert(0, str(Path(repo) / "test"))
    import gh534_phase_b_tests as T  # imports <repo>/skills/.../scripts first on sys.path

    mc = T.merge_cleanup
    ar = mc.attempt_record

    class Drv(T.LedgerFixture):
        def runTest(self):  # pragma: no cover - never run as a test
            pass

        def seams(self, shim=True):
            (self.seed / "githooks").mkdir(exist_ok=True)
            (self.seed / "githooks" / "install.sh").write_text(INSTALLER)
            names = ["githooks/install.sh"]
            if shim:
                (self.seed / "validate.sh").write_text(SHIM)
                names.append("validate.sh")
            T._git(self.seed, "add", "-A")
            for n in names:
                T._git(self.seed, "update-index", "--chmod=+x", n)
            T._git(self.seed, "commit", "-q", "-m", "GH-1606 controlled seams")
            T._git(self.seed, "push", "-q", "origin", "development")
            for c in (self.primary, self.probe):
                T._git(c, "pull", "-q", "--ff-only")

        def build(self, shim=True):
            self.seams(shim)
            self.branch("feat/a", 1, lambda r: T.park(r, 200, "from PR 1"))
            self.branch("feat/b", 2, lambda r: T.park(r, 201, "from PR 2", rated="60/40/50/70"))

    d = Drv("runTest")
    d.setUp()
    try:
        return SCENARIO_FUNCS[scenario](T, mc, ar, d)
    finally:
        d.doCleanups()


def _origin_head(T, d, branch):
    out = T._git(d.probe, "ls-remote", str(d.origin), "refs/heads/" + branch).stdout.split()
    return out[0] if out else ""


def _record(mc, ar, d, n):
    path = ar.record_path(d.primary.resolve(), mc.origin_url(d.primary) or "", n)
    if not path.exists():
        return "absent", None
    atts = json.loads(path.read_text()).get("attempts", [])
    return len(atts), (atts[-1].get("commit") if atts else None)


def _drive(T, mc, ar, d, *, toolchain, push, extra=(), execute=True):
    """One merge_cleanup.main() run with BOTH output streams captured and a counting push wrapper."""
    out, calls = io.StringIO(), []
    real_push = mc.push_resolved_head

    def counting_real(pr, clone, sha, primary):
        ok, why = real_push(pr, clone, sha, primary)
        # Captured IMMEDIATELY after the real push: the fixture deletes the source branch on merge.
        calls.append({"sha": sha, "ok": ok, "why": why, "origin_head_after_push": _origin_head(T, d, pr["headRefName"])})
        return ok, why

    def refusing(pr, clone, sha, primary):
        calls.append({"sha": sha, "refused": True})
        return False, "push refused: utput above."

    stub = counting_real if push == "real" else refusing
    before = _origin_head(T, d, "feat/b")
    with mock.patch.dict(os.environ, {"GH1606_TOOLCHAIN": toolchain}), \
            mock.patch.object(mc, "push_resolved_head", side_effect=stub), \
            contextlib.redirect_stdout(out):
        rc = d.run_main(execute=execute, extra=list(extra))
    stdout, stderr = out.getvalue(), d.err
    n_att, commit = _record(mc, ar, d, 2)
    both = stdout + "\n" + stderr
    return {
        "rc": rc, "attempts": n_att, "recorded_commit": commit, "push_calls": calls,
        "routing_to_b1": "routing to B1" in both,
        "b1_lines": sum(1 for ln in both.splitlines() if "B1:" in ln),
        "fault_named": "ENVIRONMENT FAULT" in both,
        "deferred_named": "DEFERRED — the pre-push gate cannot run here" in stderr,
        "preflight_toolchain_warning": any("PRE-FLIGHT:" in ln and "toolchain" in ln for ln in stderr.splitlines()),
        "previously_parked": "previously parked" in both or "PARKED (resume)" in both,
        "origin_before": before, "origin_after": _origin_head(T, d, "feat/b"),
        "pr2_state": d.load()["prs"]["2"]["state"],
        "stdout_tail": stdout[-500:], "stderr_tail": stderr[-700:],
    }


def s1(T, mc, ar, d):
    d.build()
    return {"run": _drive(T, mc, ar, d, toolchain="fault", push="refuse")}


def s3(T, mc, ar, d):
    d.build()
    return {"run": _drive(T, mc, ar, d, toolchain="ok", push="real")}


def s4(T, mc, ar, d):
    d.build()
    first = _drive(T, mc, ar, d, toolchain="fault", push="real")
    second = _drive(T, mc, ar, d, toolchain="ok", push="real", extra=["--resume"])
    return {"run1": first, "run2": second}


def s5(T, mc, ar, d):
    d.build(shim=False)  # consumer shape: no validate.sh in the clone
    return {"run": _drive(T, mc, ar, d, toolchain="fault", push="real")}


def s6(T, mc, ar, d):
    d.build()
    fault = _drive(T, mc, ar, d, toolchain="fault", push="real", execute=False, extra=["--prs", "1,2"])
    healthy = _drive(T, mc, ar, d, toolchain="ok", push="real", execute=False, extra=["--prs", "1,2"])
    return {"dry_fault": fault, "dry_healthy": healthy}


def s7(T, mc, ar, d):
    d.build()
    origin = mc.origin_url(d.primary) or ""
    rec = ar.record_path(d.primary.resolve(), origin, 2)
    head = _origin_head(T, d, "feat/b")
    fresh = ar.new_record(2, origin, base_sha=head)
    for i in range(2):  # created through the writer, never hand-written JSON
        idx, why = ar.reserve(rec, by="script", head_sha=head, rung="B1", create=fresh if i == 0 else None)
        ar.finish(rec, idx, "handoff", reason="GH-1606 control setup")
    return {"run": _drive(T, mc, ar, d, toolchain="fault", push="real", extra=["--resume"])}


def s8(T, mc, ar, d):
    d.build()  # the clone's validate.sh exits 2 with a usage line and no fault line
    return {"run": _drive(T, mc, ar, d, toolchain="usage", push="real")}


SCENARIO_FUNCS = {"S8_unknown_flag_validate": s8, "S1_fault_refusing_push": s1, "S3_healthy": s3, "S4_fault_then_resume": s4,
                  "S5_consumer_no_validate": s5, "S6_dry_run": s6, "S7_ceiling_resume": s7}


# ---------------------------------------------------------------------------------------------------
# orchestrator: base vs candidate, plus AC-1 on the real clone, then the verdicts
# ---------------------------------------------------------------------------------------------------
def _spawn(repo, scenario):
    p = subprocess.run([sys.executable, str(Path(__file__).resolve()), "--one", scenario, "--repo", str(repo)],
                       capture_output=True, text=True)
    for line in reversed(p.stdout.splitlines()):
        if line.startswith(SENTINEL):
            return json.loads(line[len(SENTINEL):])
    return {"driver_error": True, "rc": p.returncode, "stdout_tail": p.stdout[-600:], "stderr_tail": p.stderr[-900:]}


def _helper_probe(repo, path_env):
    """AC-1: call the real helper on the real clone, under an explicit PATH."""
    code = ("import sys;sys.path.insert(0,%r);import merge_cleanup as m;"
            "print(repr(m.gate_toolchain_fault_reason(__import__('pathlib').Path(%r))))"
            % (str(Path(repo) / "skills/2-daily/merge-cleanup/scripts"), str(repo)))
    env = dict(os.environ, PATH=path_env)
    p = subprocess.run([sys.executable, "-c", code], capture_output=True, text=True, env=env)
    return p.returncode, (p.stdout.strip() or p.stderr.strip())[-700:]


def _mixed_probe(repo):
    """Final-QA R1: the gate can print an advisory php fault line before the blocking python one.
    Feed the helper that two-line rc-3 output (and a php-only rc-0 output) through a patched subprocess.run."""
    code = (
        "import sys,subprocess\nfrom pathlib import Path\nfrom unittest.mock import patch\n"
        "sys.path.insert(0,%r)\nimport merge_cleanup as m\n"
        "def run(rc,out):\n"
        "    r=subprocess.CompletedProcess([],rc,stdout=out,stderr='')\n"
        "    with patch.object(m.subprocess,'run',return_value=r):\n"
        "        return m.gate_toolchain_fault_reason(Path.cwd())\n"
        "php='ENVIRONMENT FAULT: php present but unusable (advisory)\\n'\n"
        "py='ENVIRONMENT FAULT: python3 (/usr/bin/python3) version 3.9.6; missing modules: yaml,pytest,requests,mypy; requires Python >=3.10\\n'\n"
        "mixed=run(3,php+py)\n"
        "print('MIXED_NAMES_PYTHON=',('python3' in mixed and 'missing modules' in mixed))\n"
        "print('MIXED_NAMES_PHP=',('php' in mixed))\n"
        "print('PHP_ONLY_RC0_EMPTY=',run(0,php)=='')\n"
        "print('NOFAULT_RC3_EMPTY=',run(3,'usage: validate.sh [options]\\n')=='')\n"
        % str(Path(repo) / "skills/2-daily/merge-cleanup/scripts"))
    p = subprocess.run([sys.executable, "-c", code], capture_output=True, text=True, cwd=str(repo))
    flags = {ln.split("=")[0]: ln.split("=")[1].strip() == "True" for ln in p.stdout.splitlines() if "=" in ln}
    return p.returncode, flags, (p.stdout.strip() or p.stderr.strip())[-500:]


def _attempts(r):
    return r["attempts"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--one")
    ap.add_argument("--repo")
    ap.add_argument("--base-repo")
    ap.add_argument("--candidate-repo")
    ap.add_argument("--prefix-repo", help="the candidate BEFORE the final-QA R1 fix (red side of AC-1-mixed)")
    ap.add_argument("--out")
    a = ap.parse_args()
    if a.one:
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            res = run_one(a.repo, a.one)
        print(SENTINEL + json.dumps(res))
        return 0

    base, cand = a.base_repo, a.candidate_repo
    rows = []

    def add(ac, title, passed, cmd, snippet, notes="", exit_code=0):
        rows.append({"ac": ac, "title": title, "command": cmd, "exit_code": exit_code, "passed": bool(passed),
                     "output_snippet": snippet[:900], "notes": notes,
                     "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")})

    venv = os.path.expanduser("~/.cache/xyz-forge-test-venv/bin")
    sysp = "/usr/bin:/bin:/usr/sbin:/sbin"

    # AC-1 -------------------------------------------------------------------------------------------
    b_rc, b_out = _helper_probe(base, sysp)
    add("AC-1-base", "BASE has no gate_toolchain_fault_reason (the unfixed candidate cannot probe)",
        b_rc != 0 and "AttributeError" in b_out, "helper call at base", b_out, "red control: helper absent at base")
    s_rc, s_out = _helper_probe(cand, sysp)
    add("AC-1-fault", "real validate.sh, system python3 on PATH: helper returns the ENVIRONMENT FAULT line",
        s_rc == 0 and "ENVIRONMENT FAULT" in s_out and s_out not in ("''", '""'), "helper under PATH=%s" % sysp, s_out)
    v_rc, v_out = _helper_probe(cand, venv + ":" + sysp)
    add("AC-1-healthy", "real validate.sh, test venv first on PATH: helper returns ''",
        v_rc == 0 and v_out in ("''", '""'), "helper under PATH=$HOME/.cache/xyz-forge-test-venv/bin:...", v_out)

    # AC-1-mixed (final QA R1): advisory php line before the blocking python line -------------------------
    if a.prefix_repo:
        pr_rc, pr_flags, pr_out = _mixed_probe(a.prefix_repo)
        add("AC-1-mixed-red", "PRE-FIX helper (first fault line only) loses the blocking python cause behind an advisory php line",
            pr_rc == 0 and pr_flags.get("MIXED_NAMES_PYTHON") is False, "mixed-output probe at the pre-fix commit", pr_out,
            "red control for final-QA R1")
    m_rc, m_flags, m_out = _mixed_probe(cand)
    add("AC-1-mixed-green", "CANDIDATE names the blocking python cause AND the advisory php line; php-only rc 0 still returns ''",
        m_rc == 0 and m_flags.get("MIXED_NAMES_PYTHON") and m_flags.get("MIXED_NAMES_PHP") and m_flags.get("PHP_ONLY_RC0_EMPTY"),
        "mixed-output probe at the candidate", m_out)

    # AC-1-nofault (PR #1614 CodeRabbit finding): a nonzero exit with NO fault line is not a toolchain fault ----
    if a.prefix_repo:
        _rc, pf, po = _mixed_probe(a.prefix_repo)
        add("AC-1-nofault-red", "PRE-FIX helper returns the output tail for a nonzero exit with no fault line, which would defer a PR for no named fault",
            _rc == 0 and pf.get("NOFAULT_RC3_EMPTY") is False, "no-fault-line probe at the pre-fix commit", po,
            "red control for the CodeRabbit finding on PR #1614")
    add("AC-1-nofault-green", "CANDIDATE returns '' for a nonzero exit with no fault line, so the pre-push hook stays authoritative",
        m_rc == 0 and m_flags.get("NOFAULT_RC3_EMPTY"), "no-fault-line probe at the candidate", m_out)

    res = {}
    for sc in SCENARIOS:
        res[sc] = {"base": _spawn(base, sc), "cand": _spawn(cand, sc)}

    def ok_run(r):  # a healthy real-push landing, with the published head proven equal to the repair
        pc = r.get("push_calls") or []
        head = pc[0].get("origin_head_after_push") if pc else ""
        return (r.get("rc") == 4 and r.get("pr2_state") == "MERGED" and r.get("attempts") == 1 and len(pc) == 1
                and bool(head) and head == r.get("recorded_commit"))

    # AC-2 (central) ---------------------------------------------------------------------------------
    b = res["S1_fault_refusing_push"]["base"].get("run", {})
    c = res["S1_fault_refusing_push"]["cand"].get("run", {})
    add("AC-2-base-red", "BASE under a toolchain fault reproduces the incident: B1 reserves a slot, push refused, cause unnamed",
        b.get("rc") == 2 and b.get("routing_to_b1") and b.get("attempts") == 1 and len(b.get("push_calls", [])) == 1
        and not b.get("fault_named"), "S1 at base", json.dumps({k: b.get(k) for k in ("rc", "attempts", "routing_to_b1", "fault_named")}),
        "the observed rejection of an unchanged candidate", exit_code=b.get("rc", -1))
    add("AC-2-cand-green", "CANDIDATE defers before reserve: exit 3, fault named, no slot, no push, head unchanged",
        c.get("rc") == 3 and c.get("fault_named") and c.get("deferred_named") and c.get("routing_to_b1")
        and c.get("b1_lines") == 0 and c.get("attempts") in ("absent", 0) and len(c.get("push_calls", [])) == 0
        and c.get("origin_before") and c.get("origin_before") == c.get("origin_after") and c.get("pr2_state") == "OPEN",
        "S1 at candidate", json.dumps({k: c.get(k) for k in ("rc", "attempts", "fault_named", "deferred_named", "b1_lines", "pr2_state")}),
        exit_code=c.get("rc", -1))

    # AC-3 -------------------------------------------------------------------------------------------
    for sc, label in (("S3_healthy", "healthy toolchain"), ("S5_consumer_no_validate", "consumer shape (no validate.sh)")):
        bb, cc = res[sc]["base"].get("run", {}), res[sc]["cand"].get("run", {})
        add("AC-3-" + sc, f"{label}: BASE == CANDIDATE, lands with the published head equal to the repair",
            ok_run(bb) and ok_run(cc), sc, json.dumps({"base": [bb.get("rc"), bb.get("attempts")], "cand": [cc.get("rc"), cc.get("attempts")]}))
    r4 = res["S4_fault_then_resume"]["cand"]
    r1, r2 = r4.get("run1", {}), r4.get("run2", {})
    add("AC-3-S4", "fault run defers (exit 3, no slot), then --resume with the toolchain fixed lands using exactly one slot",
        r1.get("rc") == 3 and r1.get("attempts") in ("absent", 0) and r2.get("pr2_state") == "MERGED" and r2.get("attempts") == 1
        and len(r2.get("push_calls", [])) == 1 and r2["push_calls"][0].get("origin_head_after_push") == r2.get("recorded_commit")
        and bool(r2.get("recorded_commit")), "S4 at candidate", json.dumps({"run1": [r1.get("rc"), r1.get("attempts")], "run2": [r2.get("rc"), r2.get("attempts")]}))
    for who in ("base", "cand"):
        r = res["S7_ceiling_resume"][who].get("run", {})
        add("AC-3-S7-" + who, f"{who}: --resume at the 2-repair ceiling stays parked under a fault; record unchanged; no push",
            r.get("rc") == 3 and r.get("previously_parked") and r.get("attempts") == 2 and len(r.get("push_calls", [])) == 0,
            "S7 at " + who, json.dumps({k: r.get(k) for k in ("rc", "attempts", "previously_parked")}))

    # AC-3-S8 (PR #1614 review): a validate.sh that rejects --print-mode must not defer the PR -------------
    c8 = res["S8_unknown_flag_validate"]["cand"].get("run", {})
    add("AC-3-S8-cand", "CANDIDATE: a validate.sh that answers --print-mode with a usage error (no fault line) does NOT defer; the PR repairs and lands, published head equals the repair",
        ok_run(c8) and not c8.get("deferred_named"), "S8 at candidate", json.dumps({k: c8.get(k) for k in ("rc", "attempts", "deferred_named")}))
    if a.prefix_repo:
        p8 = _spawn(a.prefix_repo, "S8_unknown_flag_validate").get("run", {})
        add("AC-3-S8-prefix-red", "PRE-FIX commit wrongly defers the same PR (exit 3, no repair) for a reason that names no fault",
            p8.get("rc") == 3 and p8.get("deferred_named") and p8.get("attempts") in ("absent", 0) and not p8.get("fault_named"),
            "S8 at the pre-fix commit", json.dumps({k: p8.get(k) for k in ("rc", "attempts", "deferred_named", "fault_named")}),
            "red control for the CodeRabbit finding on PR #1614", exit_code=p8.get("rc", -1))

    # AC-4 -------------------------------------------------------------------------------------------
    cd = res["S6_dry_run"]["cand"]
    f, h = cd.get("dry_fault", {}), cd.get("dry_healthy", {})
    add("AC-4-cand", "CANDIDATE dry run: PRE-FLIGHT toolchain warning under a fault, none when healthy, no attempt record",
        f.get("preflight_toolchain_warning") and not h.get("preflight_toolchain_warning")
        and f.get("attempts") == "absent" and h.get("attempts") == "absent", "S6 at candidate",
        json.dumps({"fault_warn": f.get("preflight_toolchain_warning"), "healthy_warn": h.get("preflight_toolchain_warning")}))
    bd = res["S6_dry_run"]["base"].get("dry_fault", {})
    add("AC-4-base-red", "BASE dry run emits no toolchain warning even under a fault (the missing foresight)",
        bd.get("preflight_toolchain_warning") is False, "S6 at base", json.dumps({"warn": bd.get("preflight_toolchain_warning")}))

    out = Path(a.out or ".")
    out.mkdir(parents=True, exist_ok=True)
    (out / "provenance.jsonl").write_text("".join(json.dumps(r) + "\n" for r in rows))
    (out / "raw-results.json").write_text(json.dumps(res, indent=1, default=str))
    width = max(len(r["ac"]) for r in rows)
    for r in rows:
        print(("PASS " if r["passed"] else "FAIL ") + r["ac"].ljust(width) + "  " + r["title"])
    return 0 if all(r["passed"] for r in rows) else 1


if __name__ == "__main__":
    sys.exit(main())
