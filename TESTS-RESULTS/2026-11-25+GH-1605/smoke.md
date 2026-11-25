# GH-1605 smoke, red-control & suite verification (manual check, GH-831)

- **Tested commit:** `b62cf100270562a45cf09447ac27e0e9c9d7f59f` (PR #1608 review fixes on top of `origin/development` merge `2cc3df15f` / `d3b238ed5`)
- **Base commit (red control):** `e22fd2374` (pre-fix `sync.py`), merged against `origin/development` `d3b238ed5`
- **Execution environment:** Separate disposable full clone (`XYZ-forge-gh1605-pr1608-fixes-2026-11-25`, `HEAD=b62cf100270562a45cf09447ac27e0e9c9d7f59f`, `core.bare=false`, `origin=https://github.com/HiQS-Labs/XYZ-forge.git`, pre-run `git status --porcelain=""`).
- **Policy:** No new `test/` file or `validate.sh` entry added (GH-831).

## Required existing suites & repo hygiene gates

| Check | Exact command | Exit | Retained log / decisive summary |
|---|---|---|---|
| Skills Army HQ pytest wrapper | `uv run --with pytest bash test/skills-army-hq.sh` | `0` | `TESTS-RESULTS/2026-11-25+GH-1605/skills-army-hq.log` — `==================== 34 passed, 4 subtests passed in 8.28s =====================` |
| Skills Army mini sync | `bash test/gh620-skills-army-mini-sync.sh` | `0` | `gh620-skills-army-mini-sync: 28 passed, 0 failed` |
| Drift comparator | `bash test/gh660-skill-drift.sh` | `0` | `gh660-skill-drift: 7 pass, 0 fail` |
| PDDA doc hygiene gate | `bash utils/pdda/pdda.sh run` | `0` | `TESTS-RESULTS/2026-11-25+GH-1605/pdda-run.log` — `PDDA run complete: no errors, 36 warning(s) to review — pdda-check-issue-doc-sync pdda-check-governance pdda-check-marathon-qa` |
| Releases ledger integrity | `python3 -B utils/py/releases_app.py check` | `0` | `TESTS-RESULTS/2026-11-25+GH-1605/releases-check.log` — `check: clean (0 failures, 11 warning(s))` |

## Reproducible manual smoke & red-control script

Run from the root of any checkout of this branch (exit code `0`; creates all temporary repos and collections under `tempfile.TemporaryDirectory()` and leaves the repo clean):

```bash
python3 -B -c 'import pathlib, re; exec(re.search(r"(?ms)^```python\n(.*?)\n```$", pathlib.Path("TESTS-RESULTS/2026-11-25+GH-1605/smoke.md").read_text()).group(1))'
```

Exact executed script (`exit: 0`):

```python
import json, os, pathlib, shutil, subprocess, sys, tempfile

repo = pathlib.Path.cwd().resolve()
bundle = repo / "skills/3-weekly/skills-army-hq"
checker_src = repo / "utils/py/skill_drift_check.py"

def git(cwd, *args, check=True):
    r = subprocess.run(["git", *args], cwd=cwd, text=True, capture_output=True)
    if check:
        assert r.returncode == 0, f"git {args} failed: {r.stderr}"
    return r

pre_sync_code = git(repo, "show", "e22fd2374:skills/3-weekly/skills-army-hq/scripts/sync.py").stdout

with tempfile.TemporaryDirectory(prefix="gh1605-smoke-") as td:
    tmp = pathlib.Path(td).resolve()
    def sanitize(s):
        return s.replace(str(tmp), "<TMP>").replace(str(repo), "<REPO>")

    home = tmp / "home"
    home.mkdir()
    env = {**os.environ, "HOME": str(home), "PYTHONDONTWRITEBYTECODE": "1"}
    env.pop("XYZ_FORGE_ROOT", None)
    env.pop("XYZ_SKILLS_ROOT", None)

    # Bare upstream remote on development
    origin_bare = tmp / "origin-forge.git"
    git(tmp, "init", "--bare", "-q", "-b", "development", str(origin_bare))

    # Fresh canonical checkout: commit v1 and push
    fresh_forge = tmp / "fresh-forge"
    git(tmp, "clone", "-q", str(origin_bare), str(fresh_forge))
    git(fresh_forge, "checkout", "-q", "-b", "development")
    shutil.copytree(
        bundle,
        fresh_forge / "skills/3-weekly/skills-army-hq",
        ignore=shutil.ignore_patterns("__pycache__", "*.pyc"),
    )
    (fresh_forge / "utils/py").mkdir(parents=True, exist_ok=True)
    shutil.copy(checker_src, fresh_forge / "utils/py/skill_drift_check.py")
    sample_dir = fresh_forge / "skills/1-hourly/sample"
    sample_dir.mkdir(parents=True)
    (sample_dir / "SKILL.md").write_text("---\nname: sample\ndescription: v1 skill.\n---\n\nVersion 1.\n")
    git(fresh_forge, "add", ".")
    git(fresh_forge, "-c", "user.name=Smoke", "-c", "user.email=smoke@example.invalid", "commit", "-qm", "v1")
    git(fresh_forge, "push", "-q", "-u", "origin", "development")

    # Stale canonical checkout cloned at v1
    stale_forge = tmp / "stale-forge"
    git(tmp, "clone", "-q", "-b", "development", str(origin_bare), str(stale_forge))

    # Advance upstream to v2, v3; fetch in stale_forge so it is 0 ahead / 2 behind
    for ver in ("v2", "v3"):
        (sample_dir / "SKILL.md").write_text(f"---\nname: sample\ndescription: {ver} skill.\n---\n\nVersion {ver}.\n")
        git(fresh_forge, "add", ".")
        git(fresh_forge, "-c", "user.name=Smoke", "-c", "user.email=smoke@example.invalid", "commit", "-qm", ver)
    git(fresh_forge, "push", "-q", "origin", "development")
    git(stale_forge, "fetch", "-q", "origin", "development")

    # Deployed Skills collection populated from fresh_forge (v3)
    coll = tmp / "Deployed Skills"
    target = tmp / "app-skills"
    intake_script = bundle / "scripts/intake.py"
    sync_script = bundle / "scripts/sync.py"

    def run_cli(script, *args, want_rc=0):
        r = subprocess.run(
            [sys.executable, "-B", str(script), "--root", str(coll), *map(str, args)],
            cwd=home, env=env, text=True, capture_output=True,
        )
        assert r.returncode == want_rc, f"rc={r.returncode} want={want_rc}\nSTDOUT:{r.stdout}\nSTDERR:{r.stderr}"
        return r

    run_cli(intake_script, "--apply", "init")
    run_cli(intake_script, "--apply", "add", str(fresh_forge / "skills/1-hourly/sample"))
    run_cli(intake_script, "--apply", "targets", "--id", "app", "--path", str(target), "--consumer", "SmokeApp")

    # Pre-fix sync.py from base commit e22fd2374 for Case 0 red control
    pre_dir = tmp / "pre-scripts"
    pre_dir.mkdir()
    shutil.copy(intake_script, pre_dir / "intake.py")
    (pre_dir / "sync.py").write_text(pre_sync_code)

    # Current sync.py mutated copies for causal red controls (Case 6b & Case 7b)
    cur_sync_code = sync_script.read_text()
    no_dev_dir = tmp / "nodev-scripts"
    no_dev_dir.mkdir()
    shutil.copy(intake_script, no_dev_dir / "intake.py")
    assert '"origin/development", ' in cur_sync_code
    (no_dev_dir / "sync.py").write_text(cur_sync_code.replace('"origin/development", ', "", 1))

    enclosing_dir = tmp / "enclosing-scripts"
    enclosing_dir.mkdir()
    shutil.copy(intake_script, enclosing_dir / "intake.py")
    assert "canonical_top = top if top == canonical else None" in cur_sync_code
    (enclosing_dir / "sync.py").write_text(
        cur_sync_code.replace("canonical_top = top if top == canonical else None", "canonical_top = top", 1)
    )

    def emit(title, r, extra=None):
        drift = json.loads(r.stdout).get("drift") if r.stdout.strip().startswith("{") else None
        print(f"### {title}")
        print(f"- exit: `{r.returncode}`")
        if r.stderr.strip():
            print("- stderr:\n```text\n" + sanitize(r.stderr.strip()) + "\n```")
        if drift is not None:
            print("- `result[\"drift\"]`:\n```json\n" + sanitize(json.dumps(drift, indent=2)) + "\n```")
        if extra:
            print(f"- note: {extra}")
        print()

    # Case 0: Red control (pre-fix e22fd2374 emits WARN DRIFTED + downgrade command)
    r0 = run_cli(pre_dir / "sync.py", "--status", "--canonical", str(stale_forge), want_rc=0)
    assert "WARN DRIFTED sample:" in r0.stderr and "--apply update sample --source" in r0.stderr
    emit("Case 0 — Red control (`e22fd2374` pre-fix `sync.py --status` vs `0 ahead / 2 behind`)", r0)

    # Case 1: Post-fix --status on stale canonical (0 ahead / 2 behind, tracked branch)
    r1 = run_cli(sync_script, "--status", "--canonical", str(stale_forge), want_rc=0)
    d1 = json.loads(r1.stdout)["drift"]
    assert "WARN STALE_CANONICAL_FORGE:" in r1.stderr and "pull --ff-only" in r1.stderr
    assert "WARN DRIFTED" not in r1.stderr and "--apply update" not in r1.stderr
    assert d1 == {"canonical": str(stale_forge), "origin": "--canonical", "branch": "development",
                  "ahead": 0, "behind": 2, "stale_canonical": True, "skipped": "STALE_CANONICAL_FORGE"}
    emit("Case 1 — Main path (post-fix `sync.py --status` vs `0 ahead / 2 behind`, tracked branch)", r1)

    # Case 2: Post-fix --apply refused on stale canonical before creating links
    r2 = run_cli(sync_script, "--apply", "--canonical", str(stale_forge), want_rc=2)
    assert "WARN STALE_CANONICAL_FORGE:" in r2.stderr and "REFUSED: canonical XYZ-forge checkout" in r2.stderr
    assert not (target / "sample").exists()
    emit("Case 2 — Main path (`sync.py --apply` refused on stale canonical, enabled target)", r2,
         "Verified target symlink was NOT created before refusal.")

    # Case 3 & 4: --apply --allow-drift override proceeds, logs once, second --apply is no-op (changelog unchanged)
    changelog = coll / "CHANGELOG.md"
    r3 = run_cli(sync_script, "--apply", "--allow-drift", "--canonical", str(stale_forge), want_rc=0)
    assert (target / "sample").is_symlink()
    assert any("STALE_CANONICAL_FORGE" in w for w in json.loads(r3.stdout)["warnings"])
    assert any("--allow-drift: deploying without drift verification" in w for w in json.loads(r3.stdout)["warnings"])
    cl_after_first = changelog.read_text()
    r4 = run_cli(sync_script, "--apply", "--allow-drift", "--canonical", str(stale_forge), want_rc=0)
    assert changelog.read_text() == cl_after_first
    assert any("STALE_CANONICAL_FORGE" in w for w in json.loads(r4.stdout)["warnings"])
    emit("Case 3 — Override (`sync.py --apply --allow-drift` on stale canonical, first run)", r3,
         "Verified symlink created and override warning captured in JSON warnings.")
    emit("Case 4 — No-op changelog invariant (second `sync.py --apply --allow-drift`, no link changes)", r4,
         "Verified `CHANGELOG.md` byte-for-byte unchanged on no-op repeat.")

    # Case 5: Diverged tracked canonical (1 ahead / 2 behind) warns pull --ff-only will refuse
    div_forge = tmp / "diverged-forge"
    git(tmp, "clone", "-q", str(stale_forge), str(div_forge))
    git(div_forge, "remote", "set-url", "origin", str(origin_bare))
    git(div_forge, "fetch", "-q", "origin", "development")
    (div_forge / "LOCAL_NOTE.txt").write_text("local commit\n")
    git(div_forge, "add", "LOCAL_NOTE.txt")
    git(div_forge, "-c", "user.name=Smoke", "-c", "user.email=smoke@example.invalid", "commit", "-qm", "local ahead")
    r5 = run_cli(sync_script, "--status", "--canonical", str(div_forge), want_rc=0)
    d5 = json.loads(r5.stdout)["drift"]
    assert "WARN STALE_CANONICAL_FORGE:" in r5.stderr and "1 ahead, 2 behind" in r5.stderr
    assert "reconcile or fast-forward it" in r5.stderr and "pull --ff-only will refuse while 1 commit(s) ahead" in r5.stderr
    assert "WARN DRIFTED" not in r5.stderr and d5["ahead"] == 1 and d5["behind"] == 2 and d5["stale_canonical"] is True
    emit("Case 5 — Diverged tracked canonical (`1 ahead / 2 behind`, warns `pull --ff-only` will refuse)", r5)

    # Case 6a: Detached HEAD behind origin/development ONLY (origin/HEAD and FETCH_HEAD cleared)
    det_forge = tmp / "detached-forge"
    git(tmp, "clone", "-q", str(stale_forge), str(det_forge))
    git(det_forge, "remote", "set-url", "origin", str(origin_bare))
    git(det_forge, "fetch", "-q", "origin", "development")
    git(det_forge, "checkout", "-q", "--detach", "HEAD")
    git(det_forge, "symbolic-ref", "-d", "refs/remotes/origin/HEAD", check=False)
    fetch_head = det_forge / ".git/FETCH_HEAD"
    if fetch_head.exists():
        fetch_head.unlink()
    assert git(det_forge, "rev-parse", "--verify", "origin/HEAD", check=False).returncode != 0
    assert git(det_forge, "rev-parse", "--verify", "FETCH_HEAD", check=False).returncode != 0
    assert git(det_forge, "rev-parse", "--verify", "origin/main", check=False).returncode != 0
    assert git(det_forge, "rev-parse", "--verify", "origin/master", check=False).returncode != 0
    assert git(det_forge, "rev-parse", "--verify", "origin/development", check=False).returncode == 0
    r6a = run_cli(sync_script, "--status", "--canonical", str(det_forge), want_rc=0)
    d6a = json.loads(r6a.stdout)["drift"]
    assert "WARN STALE_CANONICAL_FORGE:" in r6a.stderr and "branch HEAD, 0 ahead, 2 behind" in r6a.stderr
    assert "HEAD is detached" in r6a.stderr and "pull --ff-only" not in r6a.stderr
    assert "WARN DRIFTED" not in r6a.stderr and d6a["branch"] == "HEAD" and d6a["behind"] == 2 and d6a["stale_canonical"] is True
    emit("Case 6a — Detached HEAD behind `origin/development` ONLY (`origin/HEAD` + `FETCH_HEAD` cleared)", r6a,
         "Verified `origin/HEAD` and `FETCH_HEAD` absent, `origin/development` present, and bare `pull --ff-only` omitted.")

    # Case 6b: Fallback-disabled red control on the exact same detached fixture
    r6b = run_cli(no_dev_dir / "sync.py", "--status", "--canonical", str(det_forge), want_rc=0)
    d6b = json.loads(r6b.stdout)["drift"]
    assert "STALE_CANONICAL_FORGE" not in r6b.stderr and "WARN DRIFTED sample:" in r6b.stderr
    assert d6b["branch"] == "HEAD" and d6b["ahead"] is None and d6b["behind"] is None and d6b["stale_canonical"] is False
    emit("Case 6b — Fallback-disabled red control (detached fixture with `origin/development` removed from `ahead_behind`)", r6b,
         "Proves Case 6a causally depends on the `origin/development` fallback.")

    # Case 6c: Untracked branch (no @{upstream}, origin/HEAD + FETCH_HEAD cleared, origin/development present)
    git(det_forge, "checkout", "-q", "-b", "wip")
    assert git(det_forge, "rev-parse", "--abbrev-ref", "@{upstream}", check=False).returncode != 0
    r6c = run_cli(sync_script, "--status", "--canonical", str(det_forge), want_rc=0)
    d6c = json.loads(r6c.stdout)["drift"]
    assert "WARN STALE_CANONICAL_FORGE:" in r6c.stderr and "branch wip, 0 ahead, 2 behind" in r6c.stderr
    assert "branch wip has no configured upstream" in r6c.stderr and "pull --ff-only" not in r6c.stderr
    assert "WARN DRIFTED" not in r6c.stderr and d6c["branch"] == "wip" and d6c["behind"] == 2 and d6c["stale_canonical"] is True
    emit("Case 6c — Untracked branch `wip` behind `origin/development` (no `@{upstream}`, no bare `pull --ff-only`)", r6c)

    # Case 7a & 7b: Non-git canonical export nested inside stale Git checkout (PR #1608 Blocker #1)
    nested_export = stale_forge / "nested-nongit-export"
    shutil.copytree(fresh_forge, nested_export, ignore=shutil.ignore_patterns(".git"))
    (target / "sample").unlink()
    r7b = run_cli(enclosing_dir / "sync.py", "--apply", "--canonical", str(nested_export), want_rc=2)
    assert "WARN STALE_CANONICAL_FORGE:" in r7b.stderr and "REFUSED: canonical XYZ-forge checkout" in r7b.stderr
    assert not (target / "sample").exists()
    emit("Case 7b — Nested non-Git export red control (without worktree-root equality guard)", r7b,
         "Proves enclosing `collection_repo()` without `top == canonical` falsely blocked the fresh nested export and created no symlink.")

    r7a = run_cli(sync_script, "--status", "--canonical", str(nested_export), want_rc=0)
    d7a = json.loads(r7a.stdout)["drift"]
    assert "STALE_CANONICAL_FORGE" not in r7a.stderr and "WARN DRIFTED" not in r7a.stderr
    assert d7a["branch"] is None and d7a["ahead"] is None and d7a["behind"] is None
    assert d7a["stale_canonical"] is False and d7a["drifted"] == [] and "sample" in d7a["ok"]
    r7a_apply = run_cli(sync_script, "--apply", "--canonical", str(nested_export), want_rc=0)
    assert "STALE_CANONICAL_FORGE" not in r7a_apply.stderr and (target / "sample").is_symlink()
    emit("Case 7a — Nested non-Git canonical export inside stale Git checkout (preserves comparator + apply)", r7a,
         "Verified `--status` reports parity (`stale_canonical: false`, `branch: null`) and `--apply` exits 0 creating the target symlink.")
    shutil.rmtree(nested_export)

    # Case 8: Recovery — git pull --ff-only clears STALE_CANONICAL_FORGE, 0 drifted
    git(stale_forge, "pull", "-q", "--ff-only")
    r8 = run_cli(sync_script, "--status", "--canonical", str(stale_forge), want_rc=0)
    d8 = json.loads(r8.stdout)["drift"]
    assert "STALE_CANONICAL_FORGE" not in r8.stderr and "WARN DRIFTED" not in r8.stderr
    assert d8["stale_canonical"] is False and d8["behind"] == 0 and d8["drifted"] == []
    emit("Case 8 — Recovery (`git -C <stale> pull --ff-only` -> `stale_canonical: false`, 0 drifted)", r8)

    # Case 9: Fresh canonical with genuine drift still reports WARN DRIFTED + re-vendor command
    (fresh_forge / "skills/1-hourly/sample/SKILL.md").write_text("---\nname: sample\ndescription: v4 skill.\n---\n\nVersion 4.\n")
    git(fresh_forge, "add", ".")
    git(fresh_forge, "-c", "user.name=Smoke", "-c", "user.email=smoke@example.invalid", "commit", "-qm", "v4")
    git(fresh_forge, "push", "-q", "origin", "development")
    r9 = run_cli(sync_script, "--status", "--canonical", str(fresh_forge), want_rc=0)
    d9 = json.loads(r9.stdout)["drift"]
    assert "STALE_CANONICAL_FORGE" not in r9.stderr
    assert "WARN DRIFTED sample:" in r9.stderr and "--apply update sample --source" in r9.stderr
    assert d9["stale_canonical"] is False and len(d9["drifted"]) == 1
    emit("Case 9 — Fresh canonical with real drift (normal `WARN DRIFTED` preserved)", r9)

    # Case 10: Standalone non-git canonical directory (ahead=None, behind=None, stale_canonical=False)
    nongit = tmp / "nongit-forge"
    shutil.copytree(fresh_forge, nongit, ignore=shutil.ignore_patterns(".git"))
    r10 = run_cli(sync_script, "--status", "--canonical", str(nongit), want_rc=0)
    d10 = json.loads(r10.stdout)["drift"]
    assert "STALE_CANONICAL_FORGE" not in r10.stderr and "WARN DRIFTED sample:" in r10.stderr
    assert d10["branch"] is None and d10["ahead"] is None and d10["behind"] is None and d10["stale_canonical"] is False
    emit("Case 10 — Standalone non-git `--canonical` directory (`ahead=null, behind=null, stale_canonical=false`)", r10)

    # Case 11: --allow-drift --help text covers stale canonical checkout
    r11 = subprocess.run([sys.executable, "-B", str(sync_script), "--help"], cwd=home, env=env, text=True, capture_output=True)
    assert r11.returncode == 0 and "stale canonical checkout" in r11.stdout
    help_line = next(line.strip() for line in r11.stdout.splitlines() if "--allow-drift" in line)
    print("### Case 11 — `--allow-drift` CLI `--help` covers skipped stale-canonical verification")
    print(f"- exit: `{r11.returncode}`")
    print(f"- matched line:\n```text\n{help_line}\n```\n")

print("ALL 14 SMOKE + RED-CONTROL ASSERTIONS PASSED")
```

## Verbatim anonymized outputs (14 cases, all assertions passed)

### Case 0 — Red control (`e22fd2374` pre-fix `sync.py --status` vs `0 ahead / 2 behind`)
- exit: `0`
- stderr:
```text
skills-army-hq sync: WARN DRIFTED sample: vendored <TMP>/Deployed Skills/sample/SKILL.md != canonical <TMP>/stale-forge/skills/1-hourly/sample/SKILL.md — re-vendor: python3 '<TMP>/Deployed Skills/intake.py' --root '<TMP>/Deployed Skills' --apply update sample --source <TMP>/stale-forge/skills/1-hourly/sample
skills-army-hq sync: WARN duplicate-clone check skipped: no git-pulse config at <TMP>/home/.config/git-pulse/config.sh
Each skill is a physical COPY in the collection; app roots symlink to that copy, never to the source. The source may be deleted after intake; refresh with: update NAME --source <newer checkout>. Sync withdraws links left in targets removed from config.
sample: copy at <TMP>/Deployed Skills/sample (recorded source <TMP>/fresh-forge/skills/1-hourly/sample @ 708b491e585b); linked from: none
skills-army-hq: copy at <TMP>/Deployed Skills/skills-army-hq (recorded source <REPO>/skills/3-weekly/skills-army-hq @ unknown); linked from: none
```
- `result["drift"]`:
```json
{
  "canonical": "<TMP>/stale-forge",
  "ok": [
    "skills-army-hq"
  ],
  "drifted": [
    {
      "skill": "sample",
      "vendored_path": "<TMP>/Deployed Skills/sample/SKILL.md",
      "canonical_path": "<TMP>/stale-forge/skills/1-hourly/sample/SKILL.md"
    }
  ],
  "unrecognized": [],
  "origin": "--canonical"
}
```

### Case 1 — Main path (post-fix `sync.py --status` vs `0 ahead / 2 behind`, tracked branch)
- exit: `0`
- stderr:
```text
skills-army-hq sync: WARN STALE_CANONICAL_FORGE: canonical XYZ-forge checkout <TMP>/stale-forge (from --canonical, branch development, 0 ahead, 2 behind origin) is 2 commit(s) behind its upstream (as of the last fetch) — skipping drift comparison and re-vendor commands to avoid downgrades; fast-forward it (git -C <TMP>/stale-forge pull --ff-only) or point --canonical / XYZ_FORGE_ROOT / targets.json "canonical" at a current checkout
skills-army-hq sync: WARN duplicate-clone check skipped: no git-pulse config at <TMP>/home/.config/git-pulse/config.sh
Each skill is a physical COPY in the collection; app roots symlink to that copy, never to the source. The source may be deleted after intake; refresh with: update NAME --source <newer checkout>. Sync withdraws links left in targets removed from config.
sample: copy at <TMP>/Deployed Skills/sample (recorded source <TMP>/fresh-forge/skills/1-hourly/sample @ 708b491e585b); linked from: none
skills-army-hq: copy at <TMP>/Deployed Skills/skills-army-hq (recorded source <REPO>/skills/3-weekly/skills-army-hq @ unknown); linked from: none
```
- `result["drift"]`:
```json
{
  "canonical": "<TMP>/stale-forge",
  "origin": "--canonical",
  "branch": "development",
  "ahead": 0,
  "behind": 2,
  "stale_canonical": true,
  "skipped": "STALE_CANONICAL_FORGE"
}
```

### Case 2 — Main path (`sync.py --apply` refused on stale canonical, enabled target)
- exit: `2`
- stderr:
```text
skills-army-hq sync: WARN STALE_CANONICAL_FORGE: canonical XYZ-forge checkout <TMP>/stale-forge (from --canonical, branch development, 0 ahead, 2 behind origin) is 2 commit(s) behind its upstream (as of the last fetch) — skipping drift comparison and re-vendor commands to avoid downgrades; fast-forward it (git -C <TMP>/stale-forge pull --ff-only) or point --canonical / XYZ_FORGE_ROOT / targets.json "canonical" at a current checkout
skills-army-hq sync: REFUSED: canonical XYZ-forge checkout <TMP>/stale-forge is 2 commit(s) behind its upstream; drift cannot be verified — update <TMP>/stale-forge, pass a current --canonical, or deploy with --allow-drift (loudly)
```
- note: Verified target symlink was NOT created before refusal.

### Case 3 — Override (`sync.py --apply --allow-drift` on stale canonical, first run)
- exit: `0`
- stderr:
```text
skills-army-hq sync: WARN STALE_CANONICAL_FORGE: canonical XYZ-forge checkout <TMP>/stale-forge (from --canonical, branch development, 0 ahead, 2 behind origin) is 2 commit(s) behind its upstream (as of the last fetch) — skipping drift comparison and re-vendor commands to avoid downgrades; fast-forward it (git -C <TMP>/stale-forge pull --ff-only) or point --canonical / XYZ_FORGE_ROOT / targets.json "canonical" at a current checkout
skills-army-hq sync: WARN --allow-drift: deploying without drift verification because canonical <TMP>/stale-forge is 2 commit(s) behind its upstream
skills-army-hq sync: WARN duplicate-clone check skipped: no git-pulse config at <TMP>/home/.config/git-pulse/config.sh
```
- `result["drift"]`:
```json
{
  "canonical": "<TMP>/stale-forge",
  "origin": "--canonical",
  "branch": "development",
  "ahead": 0,
  "behind": 2,
  "stale_canonical": true,
  "skipped": "STALE_CANONICAL_FORGE"
}
```
- note: Verified symlink created and override warning captured in JSON warnings.

### Case 4 — No-op changelog invariant (second `sync.py --apply --allow-drift`, no link changes)
- exit: `0`
- stderr:
```text
skills-army-hq sync: WARN STALE_CANONICAL_FORGE: canonical XYZ-forge checkout <TMP>/stale-forge (from --canonical, branch development, 0 ahead, 2 behind origin) is 2 commit(s) behind its upstream (as of the last fetch) — skipping drift comparison and re-vendor commands to avoid downgrades; fast-forward it (git -C <TMP>/stale-forge pull --ff-only) or point --canonical / XYZ_FORGE_ROOT / targets.json "canonical" at a current checkout
skills-army-hq sync: WARN --allow-drift: deploying without drift verification because canonical <TMP>/stale-forge is 2 commit(s) behind its upstream
skills-army-hq sync: WARN duplicate-clone check skipped: no git-pulse config at <TMP>/home/.config/git-pulse/config.sh
```
- `result["drift"]`:
```json
{
  "canonical": "<TMP>/stale-forge",
  "origin": "--canonical",
  "branch": "development",
  "ahead": 0,
  "behind": 2,
  "stale_canonical": true,
  "skipped": "STALE_CANONICAL_FORGE"
}
```
- note: Verified `CHANGELOG.md` byte-for-byte unchanged on no-op repeat.

### Case 5 — Diverged tracked canonical (`1 ahead / 2 behind`, warns `pull --ff-only` will refuse)
- exit: `0`
- stderr:
```text
skills-army-hq sync: WARN STALE_CANONICAL_FORGE: canonical XYZ-forge checkout <TMP>/diverged-forge (from --canonical, branch development, 1 ahead, 2 behind origin) is 2 commit(s) behind its upstream (as of the last fetch) — skipping drift comparison and re-vendor commands to avoid downgrades; reconcile or fast-forward it (git -C <TMP>/diverged-forge pull --ff-only will refuse while 1 commit(s) ahead) or point --canonical / XYZ_FORGE_ROOT / targets.json "canonical" at a current checkout
skills-army-hq sync: WARN duplicate-clone check skipped: no git-pulse config at <TMP>/home/.config/git-pulse/config.sh
Each skill is a physical COPY in the collection; app roots symlink to that copy, never to the source. The source may be deleted after intake; refresh with: update NAME --source <newer checkout>. Sync withdraws links left in targets removed from config.
sample: copy at <TMP>/Deployed Skills/sample (recorded source <TMP>/fresh-forge/skills/1-hourly/sample @ 708b491e585b); linked from: app
skills-army-hq: copy at <TMP>/Deployed Skills/skills-army-hq (recorded source <REPO>/skills/3-weekly/skills-army-hq @ unknown); linked from: app
```
- `result["drift"]`:
```json
{
  "canonical": "<TMP>/diverged-forge",
  "origin": "--canonical",
  "branch": "development",
  "ahead": 1,
  "behind": 2,
  "stale_canonical": true,
  "skipped": "STALE_CANONICAL_FORGE"
}
```

### Case 6a — Detached HEAD behind `origin/development` ONLY (`origin/HEAD` + `FETCH_HEAD` cleared)
- exit: `0`
- stderr:
```text
skills-army-hq sync: WARN STALE_CANONICAL_FORGE: canonical XYZ-forge checkout <TMP>/detached-forge (from --canonical, branch HEAD, 0 ahead, 2 behind origin) is 2 commit(s) behind its upstream (as of the last fetch) — skipping drift comparison and re-vendor commands to avoid downgrades; check out an up-to-date tracked branch in <TMP>/detached-forge (HEAD is detached) or point --canonical / XYZ_FORGE_ROOT / targets.json "canonical" at a current checkout
skills-army-hq sync: WARN duplicate-clone check skipped: no git-pulse config at <TMP>/home/.config/git-pulse/config.sh
Each skill is a physical COPY in the collection; app roots symlink to that copy, never to the source. The source may be deleted after intake; refresh with: update NAME --source <newer checkout>. Sync withdraws links left in targets removed from config.
sample: copy at <TMP>/Deployed Skills/sample (recorded source <TMP>/fresh-forge/skills/1-hourly/sample @ 708b491e585b); linked from: app
skills-army-hq: copy at <TMP>/Deployed Skills/skills-army-hq (recorded source <REPO>/skills/3-weekly/skills-army-hq @ unknown); linked from: app
```
- `result["drift"]`:
```json
{
  "canonical": "<TMP>/detached-forge",
  "origin": "--canonical",
  "branch": "HEAD",
  "ahead": 0,
  "behind": 2,
  "stale_canonical": true,
  "skipped": "STALE_CANONICAL_FORGE"
}
```
- note: Verified `origin/HEAD` and `FETCH_HEAD` absent, `origin/development` present, and bare `pull --ff-only` omitted.

### Case 6b — Fallback-disabled red control (detached fixture with `origin/development` removed from `ahead_behind`)
- exit: `0`
- stderr:
```text
skills-army-hq sync: WARN DRIFTED sample: vendored <TMP>/Deployed Skills/sample/SKILL.md != canonical <TMP>/detached-forge/skills/1-hourly/sample/SKILL.md — re-vendor: python3 '<TMP>/Deployed Skills/intake.py' --root '<TMP>/Deployed Skills' --apply update sample --source <TMP>/detached-forge/skills/1-hourly/sample
skills-army-hq sync: WARN duplicate-clone check skipped: no git-pulse config at <TMP>/home/.config/git-pulse/config.sh
Each skill is a physical COPY in the collection; app roots symlink to that copy, never to the source. The source may be deleted after intake; refresh with: update NAME --source <newer checkout>. Sync withdraws links left in targets removed from config.
sample: copy at <TMP>/Deployed Skills/sample (recorded source <TMP>/fresh-forge/skills/1-hourly/sample @ 708b491e585b); linked from: app
skills-army-hq: copy at <TMP>/Deployed Skills/skills-army-hq (recorded source <REPO>/skills/3-weekly/skills-army-hq @ unknown); linked from: app
```
- `result["drift"]`:
```json
{
  "canonical": "<TMP>/detached-forge",
  "ok": [
    "skills-army-hq"
  ],
  "drifted": [
    {
      "skill": "sample",
      "vendored_path": "<TMP>/Deployed Skills/sample/SKILL.md",
      "canonical_path": "<TMP>/detached-forge/skills/1-hourly/sample/SKILL.md"
    }
  ],
  "unrecognized": [],
  "origin": "--canonical",
  "branch": "HEAD",
  "ahead": null,
  "behind": null,
  "stale_canonical": false
}
```
- note: Proves Case 6a causally depends on the `origin/development` fallback.

### Case 6c — Untracked branch `wip` behind `origin/development` (no `@{upstream}`, no bare `pull --ff-only`)
- exit: `0`
- stderr:
```text
skills-army-hq sync: WARN STALE_CANONICAL_FORGE: canonical XYZ-forge checkout <TMP>/detached-forge (from --canonical, branch wip, 0 ahead, 2 behind origin) is 2 commit(s) behind its upstream (as of the last fetch) — skipping drift comparison and re-vendor commands to avoid downgrades; switch <TMP>/detached-forge to an up-to-date tracked checkout (branch wip has no configured upstream) or point --canonical / XYZ_FORGE_ROOT / targets.json "canonical" at a current checkout
skills-army-hq sync: WARN duplicate-clone check skipped: no git-pulse config at <TMP>/home/.config/git-pulse/config.sh
Each skill is a physical COPY in the collection; app roots symlink to that copy, never to the source. The source may be deleted after intake; refresh with: update NAME --source <newer checkout>. Sync withdraws links left in targets removed from config.
sample: copy at <TMP>/Deployed Skills/sample (recorded source <TMP>/fresh-forge/skills/1-hourly/sample @ 708b491e585b); linked from: app
skills-army-hq: copy at <TMP>/Deployed Skills/skills-army-hq (recorded source <REPO>/skills/3-weekly/skills-army-hq @ unknown); linked from: app
```
- `result["drift"]`:
```json
{
  "canonical": "<TMP>/detached-forge",
  "origin": "--canonical",
  "branch": "wip",
  "ahead": 0,
  "behind": 2,
  "stale_canonical": true,
  "skipped": "STALE_CANONICAL_FORGE"
}
```

### Case 7b — Nested non-Git export red control (without worktree-root equality guard)
- exit: `2`
- stderr:
```text
skills-army-hq sync: WARN STALE_CANONICAL_FORGE: canonical XYZ-forge checkout <TMP>/stale-forge/nested-nongit-export (from --canonical, branch development, 0 ahead, 2 behind origin) is 2 commit(s) behind its upstream (as of the last fetch) — skipping drift comparison and re-vendor commands to avoid downgrades; fast-forward it (git -C <TMP>/stale-forge pull --ff-only) or point --canonical / XYZ_FORGE_ROOT / targets.json "canonical" at a current checkout
skills-army-hq sync: REFUSED: canonical XYZ-forge checkout <TMP>/stale-forge/nested-nongit-export is 2 commit(s) behind its upstream; drift cannot be verified — update <TMP>/stale-forge/nested-nongit-export, pass a current --canonical, or deploy with --allow-drift (loudly)
```
- note: Proves enclosing `collection_repo()` without `top == canonical` falsely blocked the fresh nested export and created no symlink.

### Case 7a — Nested non-Git canonical export inside stale Git checkout (preserves comparator + apply)
- exit: `0`
- stderr:
```text
skills-army-hq sync: WARN duplicate-clone check skipped: no git-pulse config at <TMP>/home/.config/git-pulse/config.sh
Each skill is a physical COPY in the collection; app roots symlink to that copy, never to the source. The source may be deleted after intake; refresh with: update NAME --source <newer checkout>. Sync withdraws links left in targets removed from config.
sample: copy at <TMP>/Deployed Skills/sample (recorded source <TMP>/fresh-forge/skills/1-hourly/sample @ 708b491e585b); linked from: none
skills-army-hq: copy at <TMP>/Deployed Skills/skills-army-hq (recorded source <REPO>/skills/3-weekly/skills-army-hq @ unknown); linked from: app
```
- `result["drift"]`:
```json
{
  "canonical": "<TMP>/stale-forge/nested-nongit-export",
  "ok": [
    "sample",
    "skills-army-hq"
  ],
  "drifted": [],
  "unrecognized": [],
  "origin": "--canonical",
  "branch": null,
  "ahead": null,
  "behind": null,
  "stale_canonical": false
}
```
- note: Verified `--status` reports parity (`stale_canonical: false`, `branch: null`) and `--apply` exits 0 creating the target symlink.

### Case 8 — Recovery (`git -C <stale> pull --ff-only` -> `stale_canonical: false`, 0 drifted)
- exit: `0`
- stderr:
```text
skills-army-hq sync: WARN duplicate-clone check skipped: no git-pulse config at <TMP>/home/.config/git-pulse/config.sh
Each skill is a physical COPY in the collection; app roots symlink to that copy, never to the source. The source may be deleted after intake; refresh with: update NAME --source <newer checkout>. Sync withdraws links left in targets removed from config.
sample: copy at <TMP>/Deployed Skills/sample (recorded source <TMP>/fresh-forge/skills/1-hourly/sample @ 708b491e585b); linked from: app
skills-army-hq: copy at <TMP>/Deployed Skills/skills-army-hq (recorded source <REPO>/skills/3-weekly/skills-army-hq @ unknown); linked from: app
```
- `result["drift"]`:
```json
{
  "canonical": "<TMP>/stale-forge",
  "ok": [
    "sample",
    "skills-army-hq"
  ],
  "drifted": [],
  "unrecognized": [],
  "origin": "--canonical",
  "branch": "development",
  "ahead": 0,
  "behind": 0,
  "stale_canonical": false
}
```

### Case 9 — Fresh canonical with real drift (normal `WARN DRIFTED` preserved)
- exit: `0`
- stderr:
```text
skills-army-hq sync: WARN DRIFTED sample: vendored <TMP>/Deployed Skills/sample/SKILL.md != canonical <TMP>/fresh-forge/skills/1-hourly/sample/SKILL.md — re-vendor: python3 '<TMP>/Deployed Skills/intake.py' --root '<TMP>/Deployed Skills' --apply update sample --source <TMP>/fresh-forge/skills/1-hourly/sample
skills-army-hq sync: WARN duplicate-clone check skipped: no git-pulse config at <TMP>/home/.config/git-pulse/config.sh
Each skill is a physical COPY in the collection; app roots symlink to that copy, never to the source. The source may be deleted after intake; refresh with: update NAME --source <newer checkout>. Sync withdraws links left in targets removed from config.
sample: copy at <TMP>/Deployed Skills/sample (recorded source <TMP>/fresh-forge/skills/1-hourly/sample @ 708b491e585b); linked from: app
skills-army-hq: copy at <TMP>/Deployed Skills/skills-army-hq (recorded source <REPO>/skills/3-weekly/skills-army-hq @ unknown); linked from: app
```
- `result["drift"]`:
```json
{
  "canonical": "<TMP>/fresh-forge",
  "ok": [
    "skills-army-hq"
  ],
  "drifted": [
    {
      "skill": "sample",
      "vendored_path": "<TMP>/Deployed Skills/sample/SKILL.md",
      "canonical_path": "<TMP>/fresh-forge/skills/1-hourly/sample/SKILL.md"
    }
  ],
  "unrecognized": [],
  "origin": "--canonical",
  "branch": "development",
  "ahead": 0,
  "behind": 0,
  "stale_canonical": false
}
```

### Case 10 — Standalone non-git `--canonical` directory (`ahead=null, behind=null, stale_canonical=false`)
- exit: `0`
- stderr:
```text
skills-army-hq sync: WARN DRIFTED sample: vendored <TMP>/Deployed Skills/sample/SKILL.md != canonical <TMP>/nongit-forge/skills/1-hourly/sample/SKILL.md — re-vendor: python3 '<TMP>/Deployed Skills/intake.py' --root '<TMP>/Deployed Skills' --apply update sample --source <TMP>/nongit-forge/skills/1-hourly/sample
skills-army-hq sync: WARN duplicate-clone check skipped: no git-pulse config at <TMP>/home/.config/git-pulse/config.sh
Each skill is a physical COPY in the collection; app roots symlink to that copy, never to the source. The source may be deleted after intake; refresh with: update NAME --source <newer checkout>. Sync withdraws links left in targets removed from config.
sample: copy at <TMP>/Deployed Skills/sample (recorded source <TMP>/fresh-forge/skills/1-hourly/sample @ 708b491e585b); linked from: app
skills-army-hq: copy at <TMP>/Deployed Skills/skills-army-hq (recorded source <REPO>/skills/3-weekly/skills-army-hq @ unknown); linked from: app
```
- `result["drift"]`:
```json
{
  "canonical": "<TMP>/nongit-forge",
  "ok": [
    "skills-army-hq"
  ],
  "drifted": [
    {
      "skill": "sample",
      "vendored_path": "<TMP>/Deployed Skills/sample/SKILL.md",
      "canonical_path": "<TMP>/nongit-forge/skills/1-hourly/sample/SKILL.md"
    }
  ],
  "unrecognized": [],
  "origin": "--canonical",
  "branch": null,
  "ahead": null,
  "behind": null,
  "stale_canonical": false
}
```

### Case 11 — `--allow-drift` CLI `--help` covers skipped stale-canonical verification
- exit: `0`
- matched line:
```text
[--archive-legacy] [--canonical FORGE_ROOT] [--allow-drift]
```

ALL 14 SMOKE + RED-CONTROL ASSERTIONS PASSED
