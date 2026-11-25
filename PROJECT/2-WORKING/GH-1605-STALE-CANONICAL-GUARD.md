---
gh_issue: 1605
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1605
title: "skills-army-hq: sync.py warns STALE_CANONICAL_FORGE when canonical checkout is behind upstream instead of printing downgrade DRIFTED commands"
status: Active — implemented & verified; awaiting Final Codex QA
created: 2026-11-25
updated: 2026-11-25
owner: Antigravity implementation sub-agent (start-task lane)
goal: Prevent sync.py from emitting false-positive WARN DRIFTED lines and downgrade-risk intake.py --apply update commands when the resolved canonical XYZ-forge checkout is behind its last-fetched upstream.
doc_type: bugfix
effort: 1
complexity: 1
risk: 1
phases: 1
branch: fix/XYZ-forge-gh1605-stale-canonical-guard-2026-11-25
related:
  - GH-1157 / PR #1161 (Hard Rule 4 prose warning for stale canonical downgrades)
  - GH-960 / PR #1097 (STALE_PULSE_COLLECTION and DUPLICATE_PULSE_CLONE in sync.py)
  - GH-660 / PR #664 (drift guard in sync.py and utils/py/skill_drift_check.py)
  - GH-1499 / PR #1533 (vendored tier layout scan in skill_drift_check.py)
context_tags: [skills-army-hq, drift-guard, sync, stale-canonical]
---

# GH-1605 — Skills Army HQ: `STALE_CANONICAL_FORGE` guard in `sync.py`

## Status

| What was just completed | What's next |
|---|---|
| Plan QA Approved in round 2 (`relay-system/2026-11-25/gh1605-plan-qa.md`, attested `d52e23414267`); admitted (`--accepted-start`), implemented (`41baf1524`), and full AC #7 evidence retained from disposable `-verify` clone (`TESTS-RESULTS/2026-11-25+GH-1605/{pdda-run.log,releases-check.log,skills-army-hq.log,smoke.md,provenance.jsonl}`: `pdda.sh run` 0 errors, `releases_app.py check` 0 failures, `uv run --with pytest bash test/skills-army-hq.sh` 34/34 passed, `gh620` 28/28, `gh660` 7/7, 10/10 verbatim smoke + red-control). | Complete Final Codex QA Round 2 (`relay-system/2026-11-25/gh1605-final-qa.md`), qualify and push from disposable `-gate` clone, open PR against `development`, and retire published checkouts. |

## Quad Concepts

- Stale local `XYZ-forge` canonical checkout causes `sync.py` to emit false `WARN DRIFTED` lines with copy-pasteable downgrade commands → check `ahead_behind()` on the resolved canonical repo first, warn `STALE_CANONICAL_FORGE`, and skip `drift_report()` + re-vendor commands when `behind > 0`.
- Unverified `--apply` against a stale canonical checkout either tricks operators into downgrading or silently skips the GH-660 drift gate → refuse `--apply` (with enabled targets) citing safe update/override remedies unless `--allow-drift` is explicitly passed loudly.

## Triangulate Card

```text
SUBJECT: warn STALE_CANONICAL_FORGE when canonical XYZ-forge checkout is behind upstream instead of printing downgrade DRIFTED commands
CELL:    irreversible (cross-device sync.py JSON/CLI contract) x crossing (sync.py, skill_drift_check.py, SKILL.md, recovery.md, test_deploy_skills.py) -> floor: full recon + falsify
GROUND:  sync.py:31-65 (canonical_root, drift_report invokes canonical/CHECKER), sync.py:107-116 (ahead_behind),
         sync.py:166-215 (repo_health / STALE_PULSE_COLLECTION), sync.py:218-237 (drift_gate),
         utils/py/skill_drift_check.py:1-97 (pure filesystem SHA-256 comparator, zero git/subprocess, 1 code caller: sync.py),
         SKILL.md:33-41 & 221-251, references/recovery.md:84-114, test/test_deploy_skills.py:578-634, test/gh660-skill-drift.sh
FALSIFY: Belief "putting the check in utils/py/skill_drift_check.py fixes sync.py" — DEAD.
         sync.py:57 executes canonical/utils/py/skill_drift_check.py; when canonical is 871-1077 commits behind,
         that checkout holds an OLD skill_drift_check.py without any new check. Only sync.py (distributed via
         Git Pulse Sync in Deployed Skills/skills-army-hq/scripts/sync.py) runs current code against a stale canonical.
         Belief "apply 24h FETCH_HEAD staleness to canonical XYZ-forge like STALE_PULSE_COLLECTION" — DEAD.
         Git Pulse Sync fetches hourly via LaunchAgent, so 24h proves a stalled daemon; XYZ-forge has no hourly
         auto-fetch daemon, so gating on 24h FETCH_HEAD would falsely suppress drift checks on up-to-date clones.
SMALLEST:Extend sync.py's existing ahead_behind() + drift_gate() to detect behind > 0 on the resolved canonical repo,
         warn STALE_CANONICAL_FORGE, skip drift_report() (zero DRIFTED / intake.py --apply update commands),
         return structured stale metadata in result["drift"], refuse --apply unless --allow-drift, and document in
         SKILL.md + references/recovery.md.
         — skipped: duplicating git probing in utils/py/skill_drift_check.py (pure comparator; never prints intake.py commands;
           add only if direct CLI callers begin printing re-vendor commands);
         — skipped: fetch_age_hours() staleness gate on canonical XYZ-forge (no hourly fetch daemon; add only if
           unfetched behind==0 false positives recur in practice).
UNKNOWNS:Whether any downstream script outside XYZ-forge indexes result["drift"]["drifted"] without checking
         stale_canonical/skipped — mitigated by keeping non-stale schema strictly additive and documenting stale_canonical.
```

## Observed problem & ground-truth evidence

- **AgentChorus #924765 (2026-11-25):** On two Macs (Mac Mini: `development` `0 ahead / 871 behind`; MBP 14": `development` `3 ahead / 1077 behind`), `sync.py --status` emitted 12 and 16 `WARN DRIFTED <name>` lines with copy-pasteable `intake.py --apply update <name> --source <stale-checkout>` commands.
- Byte-for-byte comparison showed **0 / 46** forge-owned skills actually differed from `origin/development` (`c2e528dd1`): 100% of the reported `DRIFTED` warnings were stale-canonical false positives.
- Running the printed `intake.py --apply update` command immediately overwrites `Deployed Skills/<name>/` (no drift gate in `intake.py`), commits locally, and exposes older bytes through every enabled app symlink (`SKILL.md` Hard Rule 4, PR #1161 / GH-1157).
- **Prior recurrence (#1157, 2026-10-18):** Mac Mini `development [ahead 3, behind 657]` produced 12 `WARN DRIFTED` lines where 8/12 were current. PR #1161 added prose Hard Rule 4, which did not stop `sync.py` from printing the downgrade commands.

## PRS Task Rating & Rationale

- **Rating:** `rated 82/78/50/88` (sum `298`, no operator `ovr`).
- **Severity (`78`):** High-consequence silent downgrade hazard — following `sync.py`'s printed copy-paste command overwrites `Deployed Skills/` and propagates stale skill bytes across all app symlinks (and across Macs via Pulse), recoverable via git/ZIP backups. Recurring same-class defect after #1157 prose mitigation.
- **Priority (`82`):** Severity-led urgency; active cross-Mac footgun hit again on 2026-11-25 across two Macs, cheap surgical fix.
- **Appeal (`50`):** Neutral (no explicit user appeal preference provided).
- **Effort / cheapness (`88`):** Quick surgical change (~45–60 lines in `sync.py` reusing `ahead_behind()`, plus concise docs in `SKILL.md` and `references/recovery.md`), covered by existing Tier-2 `skills-army-hq` suite.
- **Recurrence window:**
  - Last 14 days (2026-11-11 to 2026-11-25): 1 distinct multi-device incident (AgentChorus #924765, 2026-11-25, 2 Macs).
  - Preceding 14 days (2026-10-28 to 2026-11-10): 0 new incidents filed.
  - Prior history: 1 distinct incident on 2026-10-18 (#1157, 1 Mac). Total: 2 distinct incidents across 3 Macs; coverage limited to GitHub issues and AgentChorus #924765 evidence.

## Preflight Bet Check (Solution-Fit)

- **Outcome sought:** Operators and agents running `sync.py --status`, preview, or `--apply` on a device whose resolved canonical `XYZ-forge` checkout is behind its upstream receive a clear `STALE_CANONICAL_FORGE` warning with safe git-update remediation and **never** receive false-positive `WARN DRIFTED` lines or downgrade-risk `intake.py --apply update --source <stale-checkout>` commands.
- **Smallest viable bet:**
  - Extend `ahead_behind()` in `skills/3-weekly/skills-army-hq/scripts/sync.py` to include `"origin/development"` in the fallback ref list right after `"origin/HEAD"` (before `"origin/main"`), so detached/untracked Forge clones without `origin/HEAD` still measure against `origin/development`.
  - Check canonical repo upstream status in `drift_gate()` before calling `drift_report()`. When `behind > 0`: warn `STALE_CANONICAL_FORGE`, skip `drift_report()` (suppressing all `DRIFTED` lines and downgrade commands), return structured `stale_canonical: true` metadata in `result["drift"]`, and on `--apply` with enabled targets refuse unless `--allow-drift` is explicitly passed loudly.
  - Document `STALE_CANONICAL_FORGE` concisely in `skills/3-weekly/skills-army-hq/SKILL.md` and `skills/3-weekly/skills-army-hq/references/recovery.md`.
  - **Explicit non-goals:**
    - No network calls (`git fetch`) from `sync.py` (stays strictly offline/read-only on `--status`/preview, matching GH-960).
    - No changes to `utils/py/skill_drift_check.py` (pure filesystem comparator; stale checkouts run their old copy anyway; never prints `intake.py` commands).
    - No `FETCH_HEAD` age gate (`PULSE_STALE_HOURS`) on canonical `XYZ-forge` (unlike Pulse, Forge has no hourly fetch LaunchAgent).
    - No `RECEIPT-STALE` handling (remains scoped to #1157 Rung 4).
    - No changes to `intake.py` or `test/` suites (GH-831: no new test files or `validate.sh` entries).
- **Alternatives rejected:**
  1. *Adding upstream staleness check only in `utils/py/skill_drift_check.py`:* Fails on the exact bug scenario because `sync.py` executes `<stale-canonical>/utils/py/skill_drift_check.py`, which predates the fix.
  2. *Warning `STALE_CANONICAL_FORGE` while still printing `WARN DRIFTED` lines:* Leaves copy-pasteable downgrade commands in stderr where hasty operators/agents still run them, directly violating the goal.
  3. *Allowing `--apply` to succeed silently (exit 0) when canonical is stale:* Weakens the GH-660 drift gate by letting a stale canonical checkout bypass `--allow-drift` acknowledgement.
- **Rollback / containment:** Purely contained within `skills/3-weekly/skills-army-hq/{scripts/sync.py,SKILL.md,references/recovery.md}`. Reverting the commit restores prior behavior with zero schema migrations or persistent state changes.

## Recon (verified against base SHA `e22fd2374`)

- `skills/3-weekly/skills-army-hq/scripts/sync.py:31-65`:
  - `canonical_root(explicit, config, state)` resolves `(canonical, origin)` from `--canonical`, `XYZ_FORGE_ROOT`, `targets.json "canonical"`, `skills-army-hq provenance`.
  - `drift_report(root, canonical)` invokes `[sys.executable, "-B", str(canonical / CHECKER), "--canonical", str(canonical), "--collection", str(root), "--json"]`.
- `skills/3-weekly/skills-army-hq/scripts/sync.py:107-116`:
  - `ahead_behind(repo)` runs `git rev-list --left-right --count HEAD...<ref>` trying `@{upstream}`, `origin/<branch>`, `origin/HEAD`, `origin/main`, `origin/master`, `FETCH_HEAD`. Returns `(int(ahead), int(behind))` or `(None, None)`.
  - Note: `"origin/development"` is currently missing from the fallback list (Forge's standing WIP branch per `AGENTS.md`).
- `skills/3-weekly/skills-army-hq/scripts/sync.py:166-215`:
  - `repo_health(root, warnings)` emits `STALE_PULSE_COLLECTION` and `DUPLICATE_PULSE_CLONE`, and returns `{"path", "dirty", "branch", "ahead", "behind", ..., "stale_pulse_collection": stale}`.
- `skills/3-weekly/skills-army-hq/scripts/sync.py:218-237`:
  - `drift_gate(root, state, config, found, explicit, apply, allow_drift, warnings)` calls `canonical_root`, then immediately `drift_report`, emits `WARN DRIFTED <name> ... — re-vendor: python3 .../intake.py --root ... --apply update ...`, and refuses `--apply` when `drifted and deploying and not allow_drift`.
- `skills/3-weekly/skills-army-hq/scripts/intake.py:436-443`:
  - `shared.git_at(top, *args)` runs `git --no-optional-locks -C <top> ...`.
  - `shared.collection_repo(root)` runs `git rev-parse --show-toplevel` and returns `Path` or `None`.
- `utils/py/skill_drift_check.py:1-97`:
  - Pure filesystem `SKILL.md` SHA-256 comparator; only code caller in the repo is `sync.py:31,57`.
- `test/test_deploy_skills.py:578-634`:
  - Existing GH-660 drift tests use a local `git init` fixture (`self.repo`) with **no remote/upstream** -> `ahead_behind()` returns `(None, None)` -> `behind` is `None` (not stale), so all existing tests stay green without modification.
  - None of the existing assertions do exact-dict equality on `out["drift"]`.
- `utils/ci-route.sh:33,50`:
  - `skills/*/skills-army-hq/*` routes to Tier-2 subsystem `skills-army-hq` (`skills-army-hq.sh`, `gh620-skills-army-mini-sync.sh`, `gh589-xyz-mini-sync.sh`, `gh589-consult-no-tick.sh`, `gh589-skill-viewer.sh`).
- **Prior-art check:** Checked open/recent issues (#1556–#1604, #1157, #960, #660, #1499) and PRs (#1161, #1097, #1533). No existing PR or issue implements `STALE_CANONICAL_FORGE` in `sync.py`.
- **Untraced paths / caveats:** External downstream repos consuming `sync.py --status` JSON outside `XYZ-forge` were not scanned; fresh-canonical JSON retains all existing keys verbatim, and stale-canonical JSON explicitly sets `stale_canonical: true` and `skipped: "STALE_CANONICAL_FORGE"`.

## Surgical Implementation Plan

Subsystem and canonical writer extended: `skills/3-weekly/skills-army-hq/scripts/sync.py` (`ahead_behind()`, `drift_gate()`).

1. **Extend `ahead_behind(repo)` (`skills/3-weekly/skills-army-hq/scripts/sync.py`):**
   - Insert `"origin/development"` immediately after `"origin/HEAD"` and before `"origin/main"` in the fallback ref tuple so detached/untracked Forge checkouts without `origin/HEAD` still compare against `origin/development` while preserving `@{upstream}` and `origin/<branch>` priority for Pulse and other repos.
2. **Add canonical staleness check in `drift_gate()` (`skills/3-weekly/skills-army-hq/scripts/sync.py`):**
   - Retain the existing `canonical is None` early return (`sync.py:221-224`) before repository discovery.
   - After resolving `canonical, origin = canonical_root(...)`, inspect the canonical checkout offline via `canonical_top = shared.collection_repo(canonical)`:
     - If `canonical_top is None`: set `ahead, behind, branch = None, None, None`.
     - Else: set `ahead, behind = ahead_behind(canonical_top)`, run `head = shared.git_at(canonical_top, "symbolic-ref", "-q", "--short", "HEAD")`, and set `branch = head.stdout.strip() if head.returncode == 0 else "HEAD"`.
   - If `behind` (i.e. `behind is not None and behind > 0`):
     - Build safe remediation text:
       - When `ahead` is `0` or `None`: `fast-forward it (git -C {shlex.quote(str(canonical_top))} pull --ff-only) or point --canonical / XYZ_FORGE_ROOT / targets.json "canonical" at a current checkout`.
       - When `ahead > 0` (diverged): `reconcile or fast-forward it (git -C {shlex.quote(str(canonical_top))} pull --ff-only will refuse while {ahead} commit(s) ahead) or point --canonical / XYZ_FORGE_ROOT / targets.json "canonical" at a current checkout`.
     - Call `warn(warnings, f"STALE_CANONICAL_FORGE: canonical XYZ-forge checkout {canonical} (from {origin}, branch {branch or 'unknown'}, {fmt_ahead_behind(ahead, behind)}) is {behind} commit(s) behind its upstream (as of the last fetch) — skipping drift comparison and re-vendor commands to avoid downgrades; {remedy}")`.
     - Do **not** invoke `drift_report(root, canonical)` and emit **zero** `WARN DRIFTED` lines / `intake.py --apply update` commands.
     - Check `deploying = any(t["enabled"] for t in config["targets"])`:
       - If `apply and deploying and not allow_drift`: call `shared.require(False, f"REFUSED: canonical XYZ-forge checkout {canonical} is {behind} commit(s) behind its upstream; drift cannot be verified — update {canonical}, pass a current --canonical, or deploy with --allow-drift (loudly)")`.
       - If `apply and deploying and allow_drift`: call `warn(warnings, f"--allow-drift: deploying without drift verification because canonical {canonical} is {behind} commit(s) behind its upstream")`.
     - Return `{"canonical": str(canonical), "origin": origin, "branch": branch, "ahead": ahead, "behind": behind, "stale_canonical": True, "skipped": "STALE_CANONICAL_FORGE"}`.
   - When not stale (`behind` is `0` or `None`): run `drift_report(root, canonical)` unchanged and include additive metadata `branch`, `ahead`, `behind`, `stale_canonical: False` in the returned `drift` dict alongside existing `canonical`, `ok`, `drifted`, `unrecognized`, `origin`.
3. **Update docs (`skills/3-weekly/skills-army-hq/SKILL.md` and `skills/3-weekly/skills-army-hq/references/recovery.md`):**
   - In `SKILL.md` under `## Drift guard: deploying a drifted skill fails loudly (GH-660)`, add a concise bullet documenting `STALE_CANONICAL_FORGE` behavior on `--status`/preview and `--apply` / `--allow-drift` (noting changelog recording applies when a sync transaction occurs).
   - In `references/recovery.md` under the stale-clone recovery section, add a concise note explaining `STALE_CANONICAL_FORGE` alongside `STALE_PULSE_COLLECTION` and how to resolve it (`git -C <canonical> pull --ff-only` or pointing `--canonical` / `XYZ_FORGE_ROOT` / `targets.json "canonical"` at a current checkout).
4. **Verify & smoke-test (bounded test scope, GH-831 compliant):**
   - **Test non-scope (GH-831):** No new files under `test/`, no `validate.sh` `TESTS` edits, no edits to `test/test_deploy_skills.py` unless pinned behavior breaks (none expected).
   - Run existing focused suites in safe isolation: `bash test/skills-army-hq.sh` and `bash test/gh620-skills-army-mini-sync.sh` (plus `utils/pdda/pdda.sh run` and `python3 utils/py/releases_app.py check`).
   - Run deterministic manual smoke + red-control verification script (stored only in temp during execution; commands, raw outputs, and red control recorded under `TESTS-RESULTS/2026-11-25+GH-1605/smoke.md` + `provenance.jsonl`):
     1. **Red control (`git show e22fd2374:skills/3-weekly/skills-army-hq/scripts/sync.py`):** against a fixture canonical checkout `0 ahead / 2 behind` upstream with an updated deployed skill, pre-fix `sync.py --status` emits `WARN DRIFTED` with downgrade `intake.py --apply update ... --source <stale-checkout>`.
     2. **Main path (post-fix, `0 ahead / 2 behind`):** `--status` exits `0`, emits `WARN STALE_CANONICAL_FORGE`, emits **0** `WARN DRIFTED` and **0** `intake.py --apply update` lines, JSON has `drift.stale_canonical == True`, `drift.behind == 2`, `drift.skipped == "STALE_CANONICAL_FORGE"`, no `drifted` key; `--apply` (enabled target) exits `2` with `REFUSED` (no links created, no downgrade command); `--apply --allow-drift` on pending links exits `0` loudly, deploys links, and records the warning/drift block in `changelog.md`; a repeated no-op `--apply --allow-drift` on the already-reconciled collection exits `0` loudly (stderr + JSON warning) while leaving `changelog.md` bytes unchanged (preserving the `sync.py:427-428` no-op invariant).
     3. **Adjacent real-world paths:**
        - Diverged canonical (`1 ahead / 2 behind`, matching MBP 14" `3 ahead / 1077 behind`): warning explicitly notes `pull --ff-only will refuse while 1 commit(s) ahead` and suppresses `DRIFTED`.
        - Fresh canonical (`0 ahead / 0 behind`) with genuine drift in collection: normal `WARN DRIFTED` + `--apply` refusal still fires (`drift.stale_canonical == False`, `drift.behind == 0`).
        - Fast-forward recovery (`git pull --ff-only` on the stale canonical fixture, then re-run `sync.py --status`): `STALE_CANONICAL_FORGE` clears and normal parity (`ok: ["sample"]`, `drifted: []`, `stale_canonical: False`) resumes.
        - Non-remote canonical (local `git init` without upstream): `behind == None`, `stale_canonical == False`, normal drift check runs.

## Acceptance Criteria

1. When the resolved canonical `XYZ-forge` checkout is behind its last-fetched upstream (`behind > 0`), `sync.py --status` and preview emit `WARN STALE_CANONICAL_FORGE` citing the canonical path, origin, branch, ahead/behind counts, and safe remediation, and emit **zero** `WARN DRIFTED` lines and **zero** `intake.py --apply update` commands.
2. When `canonical` is diverged (`ahead > 0` and `behind > 0`), the remediation notes that `pull --ff-only` will refuse while commits are ahead and points to reconciling or selecting a current canonical checkout.
3. On `--apply` with an enabled target and stale canonical (`behind > 0`), `sync.py` refuses (exit 2, no links deployed, no downgrade command printed) unless `--allow-drift` is explicitly passed (exit 0, loud warning on stderr and in JSON, and recorded in `changelog.md` when a sync transaction occurs — preserving the existing no-op changelog invariant at `sync.py:427-428` when already reconciled).
4. When `canonical` is up-to-date (`behind == 0`) or has no upstream (`behind is None`), existing GH-660 drift detection and refusal work identically and `result["drift"]["stale_canonical"]` is `False`.
5. No network commands are executed by `sync.py`; `utils/py/skill_drift_check.py` is unchanged; no new test files or `validate.sh` entries are added (GH-831).
6. `SKILL.md` and `references/recovery.md` document `STALE_CANONICAL_FORGE` accurately.
7. Existing suites (`test/skills-army-hq.sh`, `test/gh620-skills-army-mini-sync.sh`), `utils/pdda/pdda.sh run`, `releases_app.py check`, red control, and smoke checks all pass on the final approved commit.

## Lessons Learned (For Future Agents)

- When `sync.py` executes `<canonical>/utils/py/skill_drift_check.py`, a stale canonical checkout runs an **old** copy of `skill_drift_check.py`. Any guard that protects against stale canonical checkouts must therefore live in `sync.py` (which ships to every device via Git Pulse Sync), not only in `skill_drift_check.py`.
- `sync.py:427-428` intentionally omits `changelog.md` writes on a no-op `--apply` (pinned by `test_a4_owned_links_idempotence_removed_disabled_and_dedup`). Any override warning/receipt documentation must scope `changelog.md` persistence to runs where a sync transaction actually occurs.
