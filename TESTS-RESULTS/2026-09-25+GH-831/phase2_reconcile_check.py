#!/usr/bin/env python3
"""GH-831 Phase 2 step 4 — manual check of the reconcile's tier-2 qualification (D5).

A recorded check, not a registered suite (AGENTS.md: no new tests). It replays REAL Small-run
telemetry, produced by `validate.sh --sequential --subsystem small` in a disposable clone, through
utils/py/wave_reconcile.py and checks each rule the plan names:

  1. the complete run qualifies, and its receipt matches;
  2. removing tier2:pdda is rejected;
  3. deleting or failing the envelope-assert stage is rejected;
  4. removing the Python event, or the skipped-Python shape, is rejected;
  5. a duplicated shell event is rejected;
  6. a missing Small suite is rejected;
  7. a receipt still matches after a later, unrelated change to SUBSYSTEM_TESTS_small, and a
     receipt whose recorded list differs from the tested commit's does not;
  8. the selection: a docs landing picks Small, a core landing and a classifier failure pick full.

Each mutation keeps the other fields consistent, so the rule under test is what rejects it.

usage: phase2_reconcile_check.py <harness-root> <small-run-clone> <telemetry.jsonl>
"""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root, run_clone, telemetry = (Path(a).resolve() for a in sys.argv[1:4])
sys.path.insert(0, str(root / "utils/py"))
import wave_reconcile as wave  # noqa: E402

raw = telemetry.read_bytes()
rows = [json.loads(line) for line in raw.splitlines() if line.strip()]
start = next(r for r in rows if r["event"] == "run.start")
tested = start["commit"]
expected = wave.small_suites_at(str(run_clone), tested)
results = []


def check(label, ok):
    results.append(ok)
    print(("PASS" if ok else "FAIL") + ": " + label)


def rejected(mutated):
    try:
        wave.qualification_summary("\n".join(json.dumps(r) for r in mutated), tested, expected)
    except ValueError:
        return True
    return False


def mutate(fn):
    copy = [dict(r) for r in rows]
    fn(copy)
    return copy


def summary(copy):
    return next(r for r in copy if r["event"] == "run.summary")


print(f"tested commit {tested}; Small list at that commit: {len(expected)} suites; "
      f"telemetry {telemetry.name} ({len(rows)} rows)")

# 1 — the complete run qualifies.
s = wave.qualification_summary(raw.decode(), tested, expected)
check(f"complete Small run qualifies (passed={s['passed']} total={s['total']} run_set={s['run_set']})",
      s["total"] == len(expected) + 3)
try:
    wave.qualification_summary(raw.decode(), tested)
    check("the same telemetry does NOT pass the tier-3 rule", False)
except ValueError:
    check("the same telemetry does NOT pass the tier-3 rule", True)

# 2 — tier2:pdda removed (totals left as they were).
check("removing tier2:pdda is rejected",
      rejected(mutate(lambda c: c.remove(next(r for r in c if r.get("name") == "tier2:pdda")))))

# 3 — the identity check deleted, or failed.
check("deleting the envelope-assert stage is rejected",
      rejected(mutate(lambda c: c.remove(next(r for r in c if r.get("name") == "envelope-assert")))))
check("a failed envelope-assert stage is rejected",
      rejected(mutate(lambda c: next(r for r in c if r.get("name") == "envelope-assert").update(rc=1))))

# 4 — the Python layer removed, or the skipped shape (event kept at rc 0, excluded from total).
check("removing the Python event is rejected",
      rejected(mutate(lambda c: c.remove(next(r for r in c if r.get("name") == "python:test_python_layer.py")))))
def skipped_python(c):
    summary(c).update(total=len(expected) + 2, passed=len(expected) + 2)
check("the skipped-Python shape (total = suites + 2) is rejected", rejected(mutate(skipped_python)))

# 5 — a shell suite event duplicated.
def duplicate(c):
    first = next(r for r in c if r.get("lane") == "sequential")
    c.insert(c.index(first) + 1, dict(first))
check("a duplicated shell event is rejected", rejected(mutate(duplicate)))

# 6 — one Small suite missing, with every count adjusted to agree.
def missing(c):
    c.remove(next(r for r in c if r.get("lane") == "sequential"))
    summary(c).update(total=len(expected) + 2, passed=len(expected) + 2, run_set=str(len(expected) - 1))
check("a missing Small suite is rejected (counts adjusted to agree)", rejected(mutate(missing)))

# 7 — durable replay through the production matcher, in a scratch clone of the run's commit.
with tempfile.TemporaryDirectory(prefix="gh831-replay-") as tmp:
    repo = Path(tmp) / "repo"
    git = lambda *a: subprocess.check_output(["git", *a], cwd=repo, text=True,
                                             stderr=subprocess.DEVNULL).strip()
    subprocess.check_call(["git", "clone", "-q", "--no-local", str(run_clone), str(repo)])
    git("checkout", "-q", "--detach", tested)
    git("config", "user.email", "check@example.invalid")
    git("config", "user.name", "GH-831 check")
    landing = git("rev-parse", f"{tested}^")
    folder = repo / "TESTS-RESULTS" / "2026-09-25+GH-591" / f"wave-{tested}"
    folder.mkdir(parents=True)
    (folder / "validation.jsonl").write_bytes(raw)
    entry = dict(schema_version=wave.QUALIFICATION_SCHEMA, artifact_kind="pr", tested_commit=tested,
                 landing_commit=landing, result="pass", rc=0, gate=wave.SMALL_GATE, tier=2,
                 suites=expected, telemetry=str((folder / "validation.jsonl").relative_to(repo)),
                 telemetry_sha256=hashlib.sha256(raw).hexdigest(), pr=832)
    git("add", "-A")
    git("commit", "-q", "-m", "receipt telemetry")
    meta = {"number": 832, "state": "MERGED", "baseRefName": "development",
            "artifactKind": "pr", "mergeCommit": {"oid": landing}}
    check("the Small receipt matches through qualification_receipt_matches",
          wave.qualification_receipt_matches(str(repo), entry, meta))
    route = repo / "utils" / "ci-route.sh"
    text = route.read_text()
    route.write_text(text.replace(f" {expected[-1]}\"", "\""))
    git("commit", "-q", "-am", "a later, unrelated Small-list change")
    check("HEAD's Small list now differs from the tested commit's",
          wave.small_suites_at(str(repo), "HEAD") != expected)
    check("the old receipt STILL matches (replayed against the tested commit)",
          wave.qualification_receipt_matches(str(repo), entry, meta))
    check("a receipt recording a different list does not match",
          not wave.qualification_receipt_matches(str(repo), dict(entry, suites=expected[:-1]), meta))
    check("a Small receipt without tier 2 does not match",
          not wave.qualification_receipt_matches(str(repo), dict(entry, tier=3), meta))
    check("the full-gate string over Small telemetry does not match",
          not wave.qualification_receipt_matches(str(repo), dict(entry, gate=wave.QUALIFICATION_GATE), meta))

    # 8 — selection. Landings are synthetic commits on top of the run's commit.
    git("checkout", "-q", "--detach", tested)
    env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
    def landing_with(path, text):
        target = repo / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text)
        git("add", "-A")
        git("commit", "-q", "-m", f"touch {path}")
        return {"number": 1, "mergeCommit": {"oid": git("rev-parse", "HEAD")}}
    docs = landing_with("PROJECT/1-INBOX/gh831-check.md", "note\n")
    ledger = landing_with("releases.sql", (repo / "releases.sql").read_text() + "-- check\n")
    gate, listed, why = wave.select_qualification_gate(str(repo), [docs, ledger], env)
    check(f"docs + ledger landings select Small ({why})", gate == wave.SMALL_GATE and listed == expected)
    core = landing_with("relay-automation/relay-drive.sh",
                        (repo / "relay-automation/relay-drive.sh").read_text() + "# check\n")
    gate, listed, why = wave.select_qualification_gate(str(repo), [docs, core], env)
    check(f"a docs landing batched with a core landing selects full ({why})",
          gate == wave.QUALIFICATION_GATE and listed is None)
    shutil.move(str(route), str(route) + ".moved")
    gate, listed, why = wave.select_qualification_gate(str(repo), [docs], env)
    check(f"a classifier that cannot run selects full ({why})", gate == wave.QUALIFICATION_GATE)
    shutil.move(str(route) + ".moved", str(route))
    gate, listed, why = wave.select_qualification_gate(
        str(repo), [{"number": 2, "mergeCommit": {"oid": "f" * 40}}], env)
    check(f"an unreadable landing diff selects full ({why})", gate == wave.QUALIFICATION_GATE)

print(f"{sum(results)} pass, {len(results) - sum(results)} fail")
sys.exit(0 if all(results) else 1)
