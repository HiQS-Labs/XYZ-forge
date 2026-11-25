# GH-1605 smoke, red-control & suite verification (manual check, GH-831)

- **Tested commit:** `4bbf2b0564968599c7cf0f1035994f4ea6b39f64` (code commit `41baf1524b6857c3654f1be33043afc5283f21d2`)
- **Base commit (red control):** `e22fd2374` (`origin/development`)
- **Execution environment:** Separate disposable full clone (`-verify` sibling, canonical `origin` verified; pre/post `HEAD=4bbf2b0564968599c7cf0f1035994f4ea6b39f64`, `core.bare=false`, `origin=https://github.com/HiQS-Labs/XYZ-forge.git`, local `user.email=""` matched identically).
- **Policy:** No new `test/` file or `validate.sh` entry added (GH-831).

## Required existing suites & repo hygiene gates

| Check | Exact command | Exit | Retained log / decisive summary |
|---|---|---|---|
| Skills Army HQ pytest wrapper | `uv run --with pytest bash test/skills-army-hq.sh` | `0` | `TESTS-RESULTS/2026-11-25+GH-1605/skills-army-hq.log` — `==================== 34 passed, 4 subtests passed in 11.06s ====================` |
| Skills Army mini sync | `bash test/gh620-skills-army-mini-sync.sh` | `0` | `gh620-skills-army-mini-sync: 28 passed, 0 failed` |
| Drift comparator | `bash test/gh660-skill-drift.sh` | `0` | `gh660-skill-drift: 7 pass, 0 fail` |
| PDDA doc hygiene gate | `bash utils/pdda/pdda.sh run` | `0` | `TESTS-RESULTS/2026-11-25+GH-1605/pdda-run.log` — `PDDA run complete: no errors, 36 warning(s) to review — pdda-check-issue-doc-sync pdda-check-governance pdda-check-marathon-qa` |
| Releases ledger integrity | `python3 -B utils/py/releases_app.py check` | `0` | `TESTS-RESULTS/2026-11-25+GH-1605/releases-check.log` — `check: clean (0 failures, 11 warning(s))` |

## Reproducible manual smoke & red-control procedure

Create a temp workspace (`<TMP>`), initialize a bare remote `<TMP>/origin-forge.git` on `development`, push `v1` of `skills/1-hourly/sample/SKILL.md` + `utils/py/skill_drift_check.py`, clone `<TMP>/stale-forge` at `v1`, push `v2` and `v3` from `<TMP>/fresh-forge`, run `git -C <TMP>/stale-forge fetch origin development` (`0 ahead / 2 behind`), initialize `<TMP>/Deployed Skills` with `intake.py --apply init`, `intake.py --apply add <TMP>/fresh-forge/skills/1-hourly/sample`, and `intake.py --apply targets --id app --path <TMP>/app-skills --consumer SmokeApp`. Compare `git show e22fd2374:skills/3-weekly/skills-army-hq/scripts/sync.py` (red control) against `skills/3-weekly/skills-army-hq/scripts/sync.py` across cases 0–9 below.

## Verbatim probe outputs (`<TMP>` and `<REPO>` anonymized)

### Case 0 — Red control (`e22fd2374` pre-fix `sync.py --status` vs `0 ahead / 2 behind`)
- exit: `0`
- stderr:
```text
skills-army-hq sync: WARN DRIFTED sample: vendored <TMP>/Deployed Skills/sample/SKILL.md != canonical <TMP>/stale-forge/skills/1-hourly/sample/SKILL.md — re-vendor: python3 '<TMP>/Deployed Skills/intake.py' --root '<TMP>/Deployed Skills' --apply update sample --source <TMP>/stale-forge/skills/1-hourly/sample
skills-army-hq sync: WARN duplicate-clone check skipped: no git-pulse config at <TMP>/home/.config/git-pulse/config.sh
Each skill is a physical COPY in the collection; app roots symlink to that copy, never to the source. The source may be deleted after intake; refresh with: update NAME --source <newer checkout>. Sync withdraws links left in targets removed from config.
sample: copy at <TMP>/Deployed Skills/sample (recorded source <TMP>/fresh-forge/skills/1-hourly/sample @ 21a42d532b48); linked from: none
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

### Case 1 — Main path (post-fix `sync.py --status` vs `0 ahead / 2 behind`)
- exit: `0`
- stderr:
```text
skills-army-hq sync: WARN STALE_CANONICAL_FORGE: canonical XYZ-forge checkout <TMP>/stale-forge (from --canonical, branch development, 0 ahead, 2 behind origin) is 2 commit(s) behind its upstream (as of the last fetch) — skipping drift comparison and re-vendor commands to avoid downgrades; fast-forward it (git -C <TMP>/stale-forge pull --ff-only) or point --canonical / XYZ_FORGE_ROOT / targets.json "canonical" at a current checkout
skills-army-hq sync: WARN duplicate-clone check skipped: no git-pulse config at <TMP>/home/.config/git-pulse/config.sh
Each skill is a physical COPY in the collection; app roots symlink to that copy, never to the source. The source may be deleted after intake; refresh with: update NAME --source <newer checkout>. Sync withdraws links left in targets removed from config.
sample: copy at <TMP>/Deployed Skills/sample (recorded source <TMP>/fresh-forge/skills/1-hourly/sample @ 21a42d532b48); linked from: none
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
- note: target dir empty (0 links created)

### Case 3 — Main path (`sync.py --apply --allow-drift` on pending links)
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
- note: symlink created; changelog.md length=3988 bytes contains STALE_CANONICAL_FORGE and --allow-drift

### Case 4 — Adjacent path (repeated no-op `sync.py --apply --allow-drift`)
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
- note: changelog.md byte-identical (3988 == 3988 bytes)

### Case 5 — Adjacent path (diverged canonical `1 ahead / 2 behind`)
- exit: `0`
- stderr:
```text
skills-army-hq sync: WARN STALE_CANONICAL_FORGE: canonical XYZ-forge checkout <TMP>/diverged-forge (from --canonical, branch development, 1 ahead, 2 behind origin) is 2 commit(s) behind its upstream (as of the last fetch) — skipping drift comparison and re-vendor commands to avoid downgrades; reconcile or fast-forward it (git -C <TMP>/diverged-forge pull --ff-only will refuse while 1 commit(s) ahead) or point --canonical / XYZ_FORGE_ROOT / targets.json "canonical" at a current checkout
skills-army-hq sync: WARN duplicate-clone check skipped: no git-pulse config at <TMP>/home/.config/git-pulse/config.sh
Each skill is a physical COPY in the collection; app roots symlink to that copy, never to the source. The source may be deleted after intake; refresh with: update NAME --source <newer checkout>. Sync withdraws links left in targets removed from config.
sample: copy at <TMP>/Deployed Skills/sample (recorded source <TMP>/fresh-forge/skills/1-hourly/sample @ 21a42d532b48); linked from: app
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

### Case 6 — Adjacent path (detached HEAD without `origin/HEAD` -> `origin/development` fallback)
- exit: `0`
- stderr:
```text
skills-army-hq sync: WARN STALE_CANONICAL_FORGE: canonical XYZ-forge checkout <TMP>/detached-forge (from --canonical, branch HEAD, 0 ahead, 2 behind origin) is 2 commit(s) behind its upstream (as of the last fetch) — skipping drift comparison and re-vendor commands to avoid downgrades; fast-forward it (git -C <TMP>/detached-forge pull --ff-only) or point --canonical / XYZ_FORGE_ROOT / targets.json "canonical" at a current checkout
skills-army-hq sync: WARN duplicate-clone check skipped: no git-pulse config at <TMP>/home/.config/git-pulse/config.sh
Each skill is a physical COPY in the collection; app roots symlink to that copy, never to the source. The source may be deleted after intake; refresh with: update NAME --source <newer checkout>. Sync withdraws links left in targets removed from config.
sample: copy at <TMP>/Deployed Skills/sample (recorded source <TMP>/fresh-forge/skills/1-hourly/sample @ 21a42d532b48); linked from: app
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

### Case 7 — Adjacent path (fast-forward recovery `git pull --ff-only`)
- exit: `0`
- stderr:
```text
skills-army-hq sync: WARN duplicate-clone check skipped: no git-pulse config at <TMP>/home/.config/git-pulse/config.sh
Each skill is a physical COPY in the collection; app roots symlink to that copy, never to the source. The source may be deleted after intake; refresh with: update NAME --source <newer checkout>. Sync withdraws links left in targets removed from config.
sample: copy at <TMP>/Deployed Skills/sample (recorded source <TMP>/fresh-forge/skills/1-hourly/sample @ 21a42d532b48); linked from: app
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

### Case 8a — Adjacent path (fresh canonical + genuine drift, `--status`)
- exit: `0`
- stderr:
```text
skills-army-hq sync: WARN DRIFTED sample: vendored <TMP>/Deployed Skills/sample/SKILL.md != canonical <TMP>/fresh-forge/skills/1-hourly/sample/SKILL.md — re-vendor: python3 '<TMP>/Deployed Skills/intake.py' --root '<TMP>/Deployed Skills' --apply update sample --source <TMP>/fresh-forge/skills/1-hourly/sample
skills-army-hq sync: WARN duplicate-clone check skipped: no git-pulse config at <TMP>/home/.config/git-pulse/config.sh
Each skill is a physical COPY in the collection; app roots symlink to that copy, never to the source. The source may be deleted after intake; refresh with: update NAME --source <newer checkout>. Sync withdraws links left in targets removed from config.
sample: copy at <TMP>/Deployed Skills/sample (recorded source <TMP>/fresh-forge/skills/1-hourly/sample @ 21a42d532b48); linked from: app
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

### Case 8b — Adjacent path (fresh canonical + genuine drift, `--apply` refused)
- exit: `2`
- stderr:
```text
skills-army-hq sync: WARN DRIFTED sample: vendored <TMP>/Deployed Skills/sample/SKILL.md != canonical <TMP>/fresh-forge/skills/1-hourly/sample/SKILL.md — re-vendor: python3 '<TMP>/Deployed Skills/intake.py' --root '<TMP>/Deployed Skills' --apply update sample --source <TMP>/fresh-forge/skills/1-hourly/sample
skills-army-hq sync: REFUSED: deploy would ship drifted vendored SKILL.md for sample; canonical is <TMP>/fresh-forge/skills — re-vendor from it (or --allow-drift, loudly)
```

### Case 9 — Adjacent path (non-git canonical directory)
- exit: `0`
- stderr:
```text
skills-army-hq sync: WARN DRIFTED sample: vendored <TMP>/Deployed Skills/sample/SKILL.md != canonical <TMP>/nogit-forge/skills/1-hourly/sample/SKILL.md — re-vendor: python3 '<TMP>/Deployed Skills/intake.py' --root '<TMP>/Deployed Skills' --apply update sample --source <TMP>/nogit-forge/skills/1-hourly/sample
skills-army-hq sync: WARN duplicate-clone check skipped: no git-pulse config at <TMP>/home/.config/git-pulse/config.sh
Each skill is a physical COPY in the collection; app roots symlink to that copy, never to the source. The source may be deleted after intake; refresh with: update NAME --source <newer checkout>. Sync withdraws links left in targets removed from config.
sample: copy at <TMP>/Deployed Skills/sample (recorded source <TMP>/fresh-forge/skills/1-hourly/sample @ 21a42d532b48); linked from: app
skills-army-hq: copy at <TMP>/Deployed Skills/skills-army-hq (recorded source <REPO>/skills/3-weekly/skills-army-hq @ unknown); linked from: app
```
- `result["drift"]`:
```json
{
  "canonical": "<TMP>/nogit-forge",
  "ok": [
    "skills-army-hq"
  ],
  "drifted": [
    {
      "skill": "sample",
      "vendored_path": "<TMP>/Deployed Skills/sample/SKILL.md",
      "canonical_path": "<TMP>/nogit-forge/skills/1-hourly/sample/SKILL.md"
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

Verdict: **PASS** (10/10 smoke + red-control checks; 34/34 pytest via `test/skills-army-hq.sh`; 28/28 `gh620`; 7/7 `gh660`; `pdda.sh run` exit 0; `releases_app.py check` exit 0).
