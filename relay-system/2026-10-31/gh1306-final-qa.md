---
Goal: Final QA — GH-1306 intake.py update records a missing source receipt for an identical payload
Date: 2026-10-31
NEXT: codex
STATUS: Approved
---

# Context

Issue https://github.com/HiQS-Labs/XYZ-forge/issues/1306. Plan approved in `relay-system/2026-10-31/gh1306-plan-qa.md` (Codex, Approved). Canonical plan: `PROJECT/2-WORKING/GH-1306-HQ-UNCHANGED-SOURCE-RECEIPT.md`. Evidence: `TESTS-RESULTS/2026-10-31+GH-1306/` (`smoke.md`, `smoke.py`, `red-control-prefix.log`, `smoke-candidate.log`, `skills-army-hq-suite.log`, `provenance.jsonl`) — all embedded below.

Operational envelope: a one-branch change in a local single-operator CLI; no new tests or registry entries (GH-831; `smoke.py` is a manual-check script under TESTS-RESULTS, not registered), no new machinery. Grade against the issue goal/non-goals and the approved plan. Reviewer turns cannot run git; the diff is embedded.

Acceptance map:
- Goal: an unadopted identical skill can be adopted via `update --source` → smoke main path (`other`, catalog receipt): source+commit recorded, bytes unchanged, no backup, no WARN, no Pulse commit.
- Plan-QA note (other predicate inputs): adopt-existing self-source re-points → smoke adjacent (a); preview RECORD message and untouched state → smoke preview checks.
- Idempotence → smoke adjacent (b); normal copy unaffected → smoke adjacent (c); no regression → existing suite 33 passed.
- Red control: pre-fix bundle 4 FAIL on the exact early return.

Questions: Is each acceptance item satisfied by the code and evidence? Does the code match the approved plan (no extra writer, no duplicate path)? Any defect in the changed hunk or the surrounding `add`/`update` branch? Is the rating `rated 40/35/50/85` consistent with the evidence?

# Code diff (origin/development..HEAD, intake.py only)

```diff
diff --git a/skills/3-weekly/skills-army-hq/scripts/intake.py b/skills/3-weekly/skills-army-hq/scripts/intake.py
index dc6dae62..60c30238 100644
--- a/skills/3-weekly/skills-army-hq/scripts/intake.py
+++ b/skills/3-weekly/skills-army-hq/scripts/intake.py
@@ -794,10 +794,18 @@ def main(argv=None):
                 require(not within(source, root) and not within(root, source) and source != root, "Source/collection overlap")
                 require(name not in found or args.command == "update", f"Skill already exists: {name}; use update")
                 before = found.get(name, {}).get("digest")
-                if before == record["digest"]:
+                held = state["skills"].get(name, {})
+                receipt_only = before == record["digest"]
+                if receipt_only and held.get("source") == record["source"] and held.get("digest") == before:
                     print(f"Unchanged: {name}"); return 0
                 details = {"name": name, "source": str(source), "before": before, "after": record["digest"], "commit": record["commit"]}
-                if apply:
+                if receipt_only:
+                    # GH-1306: identical bytes but no (or another) recorded source; record provenance, copy nothing.
+                    details["receipt_only"] = True
+                    if not apply:
+                        print(f"skills-army-hq: will RECORD source {source} @ {record['commit'][:12]} for {name} "
+                              "(payload already identical; nothing copied)", file=sys.stderr)
+                elif apply:
                     if before:
                         details["backup"] = archive(root, root / name)
                     actions.append(stage_payload(root, source, before, record["digest"], name, ignored))
@@ -844,7 +852,7 @@ def main(argv=None):
             print(json.dumps({"operation": args.command, "apply": apply, **details}, indent=2))
             if apply:
                 transact(root, state, config, actions, args.command, details)
-                if args.command in ("add", "update", "remove"):
+                if args.command in ("add", "update", "remove") and not details.get("receipt_only"):
                     origin = f" from {Path(details['source']).name}@{details['commit'][:12]}" if details.get("commit") else ""
                     if owned_paths and regular_bytes(root / "README.md") != regular_bytes(root / "skills-army-hq" / "README.md"):
                         owned_paths = ()
```

# Evidence

## smoke.md

```
# GH-1306 smoke and verification (manual check; no new suite — GH-831)

| Check | Revision | Result | Log |
|---|---|---|---|
| Red control: `smoke.py` on the pre-fix bundle | 19fe0e6b | 4 FAIL: `update --source` prints `Unchanged` for a `catalog` receipt (no source) and an `adopt-existing` receipt (source = the collection's own folder); nothing recorded | `red-control-prefix.log` |
| Smoke main path + adjacent paths | 6426356f | 19/19 PASS | `smoke-candidate.log` |
| Existing suite `bash test/skills-army-hq.sh` | 6426356f | 33 passed, 4 subtests passed | `skills-army-hq-suite.log` |

**Fixture:** a disposable Pulse-shaped collection in its own temp git repo, adopted with
`init --adopt-existing`; a second skill registered with `catalog`, which leaves no `source` key (the
shape of the 8 skills seen on 2026-10-30). HOME is sandboxed; no real collection is touched.

**Main path (`other`, catalog receipt):** preview prints `will RECORD source …` and leaves the receipt
untouched; `--apply` records source and commit, payload bytes are unchanged, no backup archive, no
blocked-pulse WARN, no Pulse commit.

**Adjacent paths:** (a) an `adopt-existing` receipt re-points to the owning repo; (b) rerunning the same
command prints `Unchanged` (idempotent); (c) a real content change still copies the payload.
```

## red-control-prefix.log

```
PASS setup: adopt-existing
PASS setup: adopt-existing source points inside the collection
PASS setup: catalog
PASS setup: other has no recorded source
PASS preview exits 0
FAIL preview does not say Unchanged — Unchanged: other

PASS preview leaves receipt without source
  apply stdout: Unchanged: other
  apply stderr: 
PASS apply exits 0
FAIL apply records source — {'description': 'Smoke fixture two.', 'digest': 'bfce09d9b9a95b063acca4df20f173e3a52ae69fecbc91397da254e97e585789', 'name': 'other', 'prerequisites': [], 'updated': '2026-10-31T20:41:48+00:00'}
FAIL apply records commit — {'description': 'Smoke fixture two.', 'digest': 'bfce09d9b9a95b063acca4df20f173e3a52ae69fecbc91397da254e97e585789', 'name': 'other', 'prerequisites': [], 'updated': '2026-10-31T20:41:48+00:00'}
PASS payload bytes unchanged
PASS no backup archive written
PASS no blocked-pulse WARN
PASS no Pulse commit for receipt-only update
FAIL adopt-existing receipt re-points to the owning repo — Unchanged: sample

PASS rerun prints Unchanged
PASS changed payload copies
4 FAIL
```

## smoke-candidate.log

```
PASS setup: adopt-existing
PASS setup: adopt-existing source points inside the collection
PASS setup: catalog
PASS setup: other has no recorded source
PASS preview exits 0
PASS preview does not say Unchanged
PASS preview says will RECORD
PASS preview leaves receipt without source
  apply stdout: {   "operation": "update",   "apply": true,   "name": "other",   "source": "$TMPDIR/gh1306-smoke-1kijv1mq/source repo/skills/other",   "before": "bfce09d9b9a95b063acca4df20f173e3a52ae69fecbc91397da254e97e585789",   "after": "bfce09d9b9a95b063acca4df20
  apply stderr: 
PASS apply exits 0
PASS apply records source
PASS apply records commit
PASS payload bytes unchanged
PASS no backup archive written
PASS no blocked-pulse WARN
PASS no Pulse commit for receipt-only update
PASS adopt-existing receipt re-points to the owning repo
PASS rerun prints Unchanged
PASS changed payload copies
ALL PASS
```

## provenance.jsonl

```
{"timestamp": "2026-10-31T20:45:00Z", "issue": 1306, "gate": "manual-check", "commit": "19fe0e6b988d2dcea0857ac85686247783049588", "case": "red-control-prefix-smoke", "command": "python3 -B TESTS-RESULTS/2026-10-31+GH-1306/smoke.py <pre-fix skills-army-hq copy>", "rc": 1, "result": "pass-red-control", "log": "red-control-prefix.log", "environment": "copy of pre-fix bundle; disposable temp collection; 4 FAIL: Unchanged on catalog (no source) and adopt-existing (self source) receipts, nothing recorded"}
{"timestamp": "2026-10-31T20:50:00Z", "issue": 1306, "gate": "manual-check", "commit": "6426356f70568ea7d113977652fd6d541b4c3287", "case": "candidate-smoke-main-and-adjacent", "command": "python3 -B TESTS-RESULTS/2026-10-31+GH-1306/smoke.py skills/3-weekly/skills-army-hq", "rc": 0, "result": "pass", "log": "smoke-candidate.log", "environment": "task clone bundle; disposable temp collection (own git repo, HOME sandboxed); 19/19 PASS"}
{"timestamp": "2026-10-31T20:52:00Z", "issue": 1306, "gate": "existing-suite", "commit": "6426356f70568ea7d113977652fd6d541b4c3287", "case": "test/skills-army-hq.sh", "command": "bash test/skills-army-hq.sh", "rc": 0, "result": "pass", "log": "skills-army-hq-suite.log", "environment": "task clone, unsandboxed (GH-177 guard), venv pytest; 33 passed, 4 subtests passed; suite uses temp fixtures with sandboxed HOME"}
```

## skills-army-hq-suite.log (tail)

```
test/test_deploy_skills.py::DeploySkillsTest::test_a7_missing_manager_entry_blocks_usability PASSED [ 72%]
test/test_deploy_skills.py::DeploySkillsTest::test_a7_swe_description_fits_zcode_discovery_limit PASSED [ 75%]
test/test_deploy_skills.py::DeploySkillsTest::test_gh660_collection_only_skill_is_unrecognized_never_refused PASSED [ 78%]
test/test_deploy_skills.py::DeploySkillsTest::test_gh660_drifted_deploy_refused_citing_canonical_then_allowed_loudly PASSED [ 81%]
test/test_deploy_skills.py::DeploySkillsTest::test_gh660_explicit_bad_canonical_is_an_error PASSED [ 84%]
test/test_deploy_skills.py::DeploySkillsTest::test_gh660_no_canonical_is_a_warning_not_a_pass PASSED [ 87%]
test/test_deploy_skills.py::DeploySkillsTest::test_gh660_targets_json_canonical_key PASSED [ 90%]
test/test_deploy_skills.py::DeploySkillsTest::test_pulse_adoption_refuses_unprotected_or_foreign_state PASSED [ 93%]
test/test_deploy_skills.py::DeploySkillsTest::test_pulse_adoption_two_devices_and_pull_readthrough PASSED [ 96%]
test/test_deploy_skills.py::DeploySkillsTest::test_pulse_default_root PASSED [100%]

==================== 33 passed, 4 subtests passed in 21.28s ====================
```

## smoke.py

```python
"""GH-1306 manual smoke (no suite, GH-831): intake.py update on an unadopted identical skill.

Usage: python3 -B smoke.py <skills-army-hq bundle dir>
Builds a disposable Pulse-shaped collection (adopt-existing gives `sample` a self-referencing source;
`catalog` gives `other` no source, the 2026-10-30 shape), then drives the bundle's intake.py. Prints one PASS/FAIL line per check; exits 1 on any FAIL.
"""
import json, os, shutil, subprocess, sys, tempfile
from pathlib import Path

BUNDLE = Path(sys.argv[1]).resolve()
fails = 0


def check(label, ok, extra=""):
    global fails
    fails += not ok
    print(f"{'PASS' if ok else 'FAIL'} {label}{(' — ' + extra) if extra and not ok else ''}")


with tempfile.TemporaryDirectory(prefix="gh1306-smoke-") as tmp:
    work = Path(tmp).resolve()
    repo, home = work / "source repo", work / "home"
    home.mkdir()
    env = {**os.environ, "HOME": str(home), "PYTHONDONTWRITEBYTECODE": "1"}
    env.pop("XYZ_FORGE_ROOT", None)
    env.pop("XYZ_SKILLS_ROOT", None)

    def git(*args, cwd=repo):
        subprocess.run(["git", "-C", str(cwd), "-c", "user.name=Smoke", "-c", "user.email=smoke@example.invalid", *args],
                       check=True, capture_output=True)

    repo.mkdir()
    git("init", "-q")
    src = repo / "skills" / "sample"
    src.mkdir(parents=True)
    (src / "SKILL.md").write_text("---\nname: sample\ndescription: Smoke fixture.\n---\n\nRead only.\n")
    (src / "run.py").write_text("print('smoke')\n")
    pulse = repo / "Deployed Skills"
    pulse.mkdir()
    shutil.copytree(BUNDLE, pulse / "skills-army-hq", ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))
    shutil.copyfile(BUNDLE / "README.md", pulse / "README.md")
    shutil.copytree(src, pulse / "sample")
    for name in ("intake.py", "sync.py"):
        (pulse / name).symlink_to(f"skills-army-hq/scripts/{name}")
    (pulse / ".gitignore").write_text(".deploy-skills*\ntargets.json\ncatalog.md\nchangelog.md\nbackups/\n.staging/\n*.zip\n*.lock\n__pycache__/\n*.pyc\n")
    git("add", ".")
    git("commit", "-qm", "fixture")

    def cli(*args):
        run = subprocess.run([sys.executable, "-B", str(pulse / "intake.py"), "--root", str(pulse), *args],
                             env=env, cwd=home, capture_output=True, text=True, timeout=60)
        return run

    def receipt(name):
        return json.loads((pulse / ".deploy-skills.json").read_text())["skills"].get(name, {})

    def head():
        return subprocess.run(["git", "-C", str(repo), "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()

    run = cli("--apply", "init", "--adopt-existing")
    check("setup: adopt-existing", run.returncode == 0, run.stderr)
    check("setup: adopt-existing source points inside the collection",
          receipt("sample").get("source") == str(pulse / "sample"), str(receipt("sample")))
    # The 2026-10-30 shape: a payload registered by `catalog` has no source key at all.
    other = repo / "skills" / "other"
    shutil.copytree(src, other)
    (other / "SKILL.md").write_text("---\nname: other\ndescription: Smoke fixture two.\n---\n\nRead only.\n")
    shutil.copytree(other, pulse / "other")
    git("add", ".")
    git("commit", "-qm", "other")
    run = cli("--apply", "catalog")
    check("setup: catalog", run.returncode == 0, run.stderr)
    check("setup: other has no recorded source", "source" not in receipt("other"), str(receipt("other")))
    payload = (pulse / "other" / "run.py").read_bytes()
    commit_before = head()

    # Main path: preview, then apply.
    run = cli("update", "other", "--source", str(other))
    check("preview exits 0", run.returncode == 0, run.stderr)
    check("preview does not say Unchanged", "Unchanged" not in run.stdout, run.stdout)
    check("preview says will RECORD", "will RECORD source" in run.stderr, run.stderr)
    check("preview leaves receipt without source", not receipt("other").get("source"), str(receipt("other")))
    run = cli("--apply", "update", "other", "--source", str(other))
    print("  apply stdout:", run.stdout.strip().replace("\n", " ")[:300])
    print("  apply stderr:", run.stderr.strip().replace("\n", " ")[:300])
    rec = receipt("other")
    check("apply exits 0", run.returncode == 0, run.stderr)
    check("apply records source", rec.get("source") == str(other.resolve()), str(rec))
    check("apply records commit", bool(rec.get("commit")), str(rec))
    check("payload bytes unchanged", (pulse / "other" / "run.py").read_bytes() == payload)
    check("no backup archive written", not list((pulse / "backups").glob("*")) if (pulse / "backups").exists() else True)
    check("no blocked-pulse WARN", "WARN not committed" not in run.stderr, run.stderr)
    check("no Pulse commit for receipt-only update", head() == commit_before)

    # Adjacent shape: an adopt-existing receipt whose source is the collection's own folder.
    run = cli("--apply", "update", "sample", "--source", str(src))
    check("adopt-existing receipt re-points to the owning repo", run.returncode == 0 and
          receipt("sample").get("source") == str(src.resolve()), run.stdout + run.stderr)

    # Adjacent path 1: rerun the same command (idempotent).
    run = cli("--apply", "update", "sample", "--source", str(src))
    check("rerun prints Unchanged", run.returncode == 0 and "Unchanged: sample" in run.stdout, run.stdout + run.stderr)

    # Adjacent path 2: a real content change still copies.
    (src / "run.py").write_text("print('smoke v2')\n")
    run = cli("--apply", "update", "sample", "--source", str(src))
    check("changed payload copies", run.returncode == 0 and (pulse / "sample" / "run.py").read_text() == "print('smoke v2')\n",
          run.stdout + run.stderr)

print(f"{'ALL PASS' if not fails else f'{fails} FAIL'}")
sys.exit(1 if fails else 0)
```

## CHANGELOG entry

## 2026-10-31 — GH-1306 skills-army-hq adopts a skill whose payload already matches its source

- `intake.py update NAME --source PATH` no longer stops at `Unchanged` when the deployed bytes equal the source but the receipt has no source (a `catalog` entry), names another source (an `adopt-existing` self-reference) or carries a stale digest. It records the source receipt as a state-only transaction: preview prints `will RECORD source …`, nothing is copied or backed up, and no Pulse commit is attempted. `Unchanged` remains when the same source and digest are already recorded.


# Log

## Turn 1 — codex (Reviewer) — 2026-10-31

**Approved.** No blocking findings in the changed branch or its transaction/commit integration. This approves the implementation review; the final harness gate remains outstanding. Reversibility: **Easy**. The change extends the existing receipt writer with no payload migration, new writer, dependency, or registry entry.

1. **[Pass — source review] Goal and predicate.** The seeded `intake.py` matches the embedded diff. Under equal deployed/source digests, only a held receipt with both the same resolved source and the deployed digest returns `Unchanged`. Catalog receipts without a source, adopt-existing self-sources and stale held digests proceed to assign the fresh `source_record()` result. Prerequisites remain preserved by the existing assignment. `add` cannot encounter an already deployed equal payload because its existing-name guard runs first.
2. **[Pass — source review] No copy or duplicate writer.** The receipt-only arm sets the details flag and bypasses both `archive()` and `stage_payload()`, leaving the initialized actions list empty. The normal changed-payload arm still archives/stages as before. Apply reaches the existing `transact()`/`finish()` path; `validate_receipt()` accepts an empty actions list and recovery uses the same pending receipt/checksum mechanism. Preview assigns only in-memory state and never calls `transact()`. The RECORD message is restricted to preview.
3. **[Pass — source review] Commit suppression and surrounding behavior.** The post-apply guard skips `commit_skill()` only when this arm sets `receipt_only`; ordinary add/update/remove commits retain their previous path. No new link action is introduced. As already qualified in plan QA, `finish()` still performs its existing generated-document refresh, including the root README; the no-tracked-change rationale assumes a consistent collection README. Refreshing commit/dirty metadata when source and digest already match remains outside the approved adoption goal.
4. **[Pass — supplied execution evidence] Acceptance and red control.** I read the actual smoke script, both smoke logs, provenance and existing-suite log, rather than relying only on their embedded summaries. The candidate log records source/commit persistence for the catalog shape, preview RECORD/untouched receipt, unchanged sampled payload bytes, no backup/WARN/Pulse commit, adopt-existing repointing, identical rerun and changed-payload copying. The pre-fix log has four failures at adoption/receipt persistence, with provenance rc 1; candidate provenance has rc 0. The existing suite log collected 33 items and reports `33 passed, 4 subtests passed`, rather than the wrapper's pytest-unavailable skip. These support the planned functional acceptance. The manual payload check samples `run.py`; the stronger no-copy conclusion also rests on the inspected branch bypassing all payload actions.
5. **[Pass — scope/rating]** `rated 40/35/50/85` is consistent with the documented operational consequence and implemented scope: missing provenance/drift visibility with correct payloads, one bounded branch change, existing transaction ownership. The reported eight-device-skill incident count and recurrence history are supplied context, not independently measured here. No larger mechanism or additional suite is justified by this fix.

**[Low — evidence count only]** The summary's `19/19` is a counting error: the actual candidate log contains **18 PASS, 0 FAIL**, ending `ALL PASS`. This does not remove any planned acceptance case or affect approval. Correct future summaries to 18 rather than repeating 19. The narrower reviewer probe below reads seeded files only; it runs no CLI fixture, git command or suite. Exit status **0**.

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 -B - <<'PY'
import ast, json
from pathlib import Path
root = Path("TESTS-RESULTS/2026-10-31+GH-1306")
for name in ("smoke-candidate.log", "red-control-prefix.log"):
    lines = (root/name).read_text().splitlines()
    assert lines, f"empty evidence: {name}"
    print(f"{name}: PASS={sum(s.startswith('PASS ') for s in lines)} FAIL={sum(s.startswith('FAIL ') for s in lines)} terminal={lines[-1]}")
entries = [json.loads(line) for line in (root/"provenance.jsonl").read_text().splitlines() if line]
assert len(entries) == 3
print("provenance rc:", [(entry["case"], entry["rc"]) for entry in entries])
ast.parse(Path("skills/3-weekly/skills-army-hq/scripts/intake.py").read_text())
print("intake.py: AST parses")
PY
```

Decisive output:

```text
smoke-candidate.log: PASS=18 FAIL=0 terminal=ALL PASS
red-control-prefix.log: PASS=13 FAIL=4 terminal=4 FAIL
provenance rc: [('red-control-prefix-smoke', 1), ('candidate-smoke-main-and-adjacent', 0), ('test/skills-army-hq.sh', 0)]
intake.py: AST parses
```

**[Unverified — needs clone run]** I did not rerun the supplied runtime evidence, recovery experiments or full gate in this reviewer worktree. The full gate against the final committed state remains for the harness in a disposable full clone; approval here is not merge or promotion readiness. The preferred graph tool was unavailable under this turn's approval policy, so source review used direct reads. Only this relay file was edited; no source, evidence artifact or executable fixture was created or changed.


### Attestation · relay-drive — 2026-10-31T20:46:14Z
task: RELAY-gh1306-final-qa
reviewer: codex
status: Approved
reviewed-head: 4b1210ccec2e7a2f3d8e1873bfae642f56c6b409
added-range: 16763+5395
added-sha256: d15abdcbe9134ec8c4b05b24477c5c3668cb1def96d6bac471b92e37614703b9
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
