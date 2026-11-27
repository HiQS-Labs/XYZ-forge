---
title: relay-drive attest-publish-failed when relay file is under a gitignored path
status: "Prepared 2026-11-27 (1-INBOX, not enqueued, not started)"
created: 2026-11-11
updated: 2026-11-27
owner: Noel Saw (Conveyor preparation 2026-11-27 for the Flywheel Run A queue; ledger #1658)
gh_issue: 1423
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1423
doc_type: bugfix
complexity: 2
risk: 2
effort: 1
phases: 1
ratings_provisional: true
reported_from: rebalanceOS
harness_commit: 966290ddd
non_goals:
  - changing which repos gitignore relay-system/
  - hiding genuine relay-file commit failures
  - the untracked/ignored relay file path (already skipped with a log line and success)
  - the historical Bash fallback body of `relay-automation/relay-drive.sh` (it execs the Python driver)
  - a new test suite or gate machinery (GH-831); edits to `test/gh505-relay-attest.sh`
related:
  - HiQS-Labs/rebalanceOS#375
goal: >
  An approval whose attestation commit lands is attested (exit 0) even when the relay file sits
  under a gitignored-but-tracked path; genuine commit failures still refuse.
---

# GH-1423 — relay-drive attest-publish-failed when relay file is under a gitignored path

> **1-INBOX capture**, not the active-work doc. On promotion to `PROJECT/2-WORKING/`, carry
> `gh_issue` forward (`PROJECT/PDDA.md` → GitHub issue intake).

## Status

| What was just completed | What's next |
|---|---|
| Conveyor preparation 2026-11-27 at `6142128d9c43`: Phase 0 diagnosis completed below (reproduced in this repo, write set named, fix shape chosen), Preflight Contract, probe proof (unfixed / simulated fix / fake fix), consumer validation and PRS rating. No implementation, no queue admission. | Preparation review, publication of the Run A preparation PR, merge to `development`, then a fresh preflight at the integration ref (Conveyor step 6). Next owner: the Run A launch step (#1658). |

## Acceptance

- [ ] A recorded manual repro, in a scratch repo whose `.gitignore` covers `relay-system/` with a tracked relay file under it, shows today's exit 4 / `attest-publish-failed` (the red control) with the captured `git add` stderr.
- [ ] After the fix, the same repro attests (exit 0) and the attestation commit and record are both present; a repo without the ignore rule still attests unchanged.
- [ ] A genuine commit failure (e.g. a read-only index) still returns `attest-publish-failed`, so the fix does not hide real publish failures.

## Symptom
relay-drive exits 4 (`attest-publish-failed`) when relay-system/ is gitignored in the target repo, though the attestation commit (a278102) lands.

## Environment
- **Observed from:** `rebalanceOS` (centralized harness)
- **Harness commit:** `966290ddd`
- **Worker/CLI:** codex (reviewer)
- **Runtime:** Python (default) — `utils/py/relay_drive.py`
- **Sandbox:** unknown (delegated run)

## Reproduction
1. In a rebalanceOS task clone (`.gitignore:143` = `relay-system/`), run `relay-drive.sh --review-once` on a tracked relay file under `relay-system/`.
2. Reproduced in this repo 2026-11-27 (git 2.50.1) without the delegated transcript: in a scratch repo with `relay-system/` gitignored and `relay-system/t.md` force-added and committed, after an edit `git ls-files --error-unmatch` = 0 (tracked), `git add -- <file>` = 1 with stderr `The following paths are ignored by one of your .gitignore files: relay-system` / `hint: Use -f if you really want to add them.`, and `git commit -q -m m -- <file>` = 0 (lands).

**Expected:** attested, exit 0 (or the existing untracked/ignored skip branch, now `relay_drive.py:833-836`).
**Observed:** exit 4 `attest-publish-failed`; commit `a278102` present anyway.
**Frequency:** once so far

## Impact
Plan-QA approvals refused in repos that ignore `relay-system/`; workaround: put the relay file under a non-ignored path (final QA under `TESTS-RESULTS/` exited 0).

## Diagnosis (confirmed 2026-11-27)
`commit_relay_file` (`utils/py/relay_drive.py:827-845` at `6142128d9c43`; `:670-686` at `966290ddd`) runs `git add -- <file>` then `git commit -- <file>` unconditionally and returns False if either is nonzero (`:841-843`). Why `git add` fails for a tracked file is now established: git refuses an explicit `add` of a path inside an ignored directory even when the file is tracked, while `git commit -- <path>` stages and commits the tracked path itself. So a failed add with a landed commit returns False, and `judge_terminal` refuses with `("refused", "attest-publish-failed")` (`:1006-1007`).

## Phase 0 — Diagnose & scope
> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist
- [x] Reproduce it in the intake repo (not just in the reporting repo) — scratch-repo repro above; probe in the contract below.
- [x] Locate the responsible script/path — name the concrete write-set: `utils/py/relay_drive.py` (`commit_relay_file`) only.
- [x] Decide fix vs. guard-and-document; reuse an existing code path before adding one (`/ponytail`) — fix: judge success by the commit result (drop the redundant `git add`, or ignore its exit when the commit lands).
- [ ] Set/correct the triage ratings; clear `ratings_provisional` once real — rated below from the issue's proposal; `ratings_provisional` stays until the operator confirms.

### QA checklist — Phase 0
- [x] The repro is confirmed from the report, not assumed
- [x] An existing suite, or a recorded manual check, covers the failure path before the fix lands (no new test suites: `AGENTS.md` *No new tests*, GH-831) — the contract's probe plus the gate `test/gh505-relay-attest.sh`.
- [x] The fix composes with the existing harness rather than adding a parallel path

## Recon note (Conveyor, parent-only)

The operator's brief asked for capture, contract, preflight and one independent review. The parent read the whole seam, so no separate research child was dispatched. Budget: this preparation session; attempts consumed: 0.

- **Baseline:** `origin/development` at `6142128d9c433d6b12972c6cd9a6f864f0ed9da2` (2026-11-27).
- **Call path:** `relay-automation/relay-drive.sh:18` execs `utils/py/relay_drive.py`; `commit_relay_file` is called for attestation (`:1006`), forged-terminal revert (`:885`), consult-at-cap (`:1217`) and consult-adjudication refusal (`:1685`).
- **State writer / consumer:** the file-scoped `git commit` is the writer; `judge_terminal` and its caller map False to exit 4.
- **Probe constraint:** the probe extracts `commit_relay_file` by AST and runs it with only `subprocess`, `os`, `relay_file`, `transcript_repo` and `eprint` in scope; the fix keeps it callable with those names.
- **Dependencies / overlap:** no open PR touches `relay_drive.py`. Active capture `PROJECT/1-INBOX/GH-1171-BRANCH-ARTIFACT-PREFLIGHT.md` also names `relay_drive.py` (branch-ref artifact preflight, a different function); it has no open PR. PR #1424 (merged 2026-11-12) only filed this capture.
- **Discriminating check:** the probe builds the fixture above in a temp dir (its own hooks path, no network), requires the attest commit to land and the function to return True, then drops the ignore rule and requires a plain commit to still attest, then installs a failing pre-commit hook and requires False (the genuine-failure control; the issue's "read-only index" is one example, a rejecting hook is another). Matrix (`TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/`): base 1; simulated fix 0; fake fix (`return True` before committing) 1.
- **Write set:** `relay_drive.py` plus one new delivery receipt (`artifacts_new`, with a `path_absent` probe) that records the manual repro the Acceptance asks for.
- **Foreseeable approvals/runtime:** none; probe and gate need no network or `gh`.
- **Unknowns:** none blocking.
- **Next owner:** the Run A launch step (#1658), then Jog.

## Attempt and retry history (read 2026-11-27, nothing reset)

- No `roadmap_items` row and no `jog_queue` row before this preparation; this capture (from PR #1424) is the only doc. No branch or PR for a fix. Attempts consumed: 0.

## Rating rationale

`rated 40/35/50/75` (sum 200): the issue's own PRS proposal, written through `roadmap pickup` on 2026-11-27; `ratings_provisional` stays true until the operator confirms.

- Priority 40: any repo that gitignores `relay-system/` gets plan-QA approvals refused.
- Severity 35: false refusal with a working workaround; no data loss, and the commit lands.
- Appeal 50: neutral.
- Effort 75: one function plus a recorded manual repro.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash test/gh505-relay-attest.sh",
  "round_cap": 9,
  "prepared_commit": "6142128d9c433d6b12972c6cd9a6f864f0ed9da2",
  "artifacts": [
    "utils/py/relay_drive.py",
    "TESTS-RESULTS/2026-11-27+GH-1423/delivery.md"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-11-27+GH-1423/delivery.md"
  ],
  "fix_probes": [
    {
      "type": "command",
      "cmd": "env PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'\nimport ast, os, shutil, subprocess, tempfile, textwrap\nsrc = open(\"utils/py/relay_drive.py\", encoding=\"utf-8\").read()\nfn = [n for n in ast.walk(ast.parse(src)) if isinstance(n, ast.FunctionDef) and n.name == \"commit_relay_file\"]\nassert len(fn) == 1, \"commit_relay_file not found exactly once\"\nd = tempfile.mkdtemp(prefix=\"gh1423-probe-\")\ntry:\n    g = lambda *a: subprocess.run([\"git\", \"-C\", d, *a], capture_output=True, text=True)\n    g(\"init\", \"-q\")\n    for k, v in ((\"user.name\", \"probe\"), (\"user.email\", \"probe\"), (\"commit.gpgsign\", \"false\"),\n                 (\"core.hooksPath\", os.path.join(d, \".git\", \"hooks\"))):\n        g(\"config\", k, v)\n    with open(os.path.join(d, \".gitignore\"), \"w\") as fh: fh.write(\"relay-system/\\n\")\n    os.makedirs(os.path.join(d, \"relay-system\")); rf = os.path.join(d, \"relay-system\", \"t.md\")\n    with open(rf, \"w\") as fh: fh.write(\"a\\n\")\n    g(\"add\", \".gitignore\"); g(\"add\", \"-f\", \"relay-system/t.md\")\n    assert g(\"commit\", \"-qm\", \"init\").returncode == 0, \"fixture commit failed\"\n    with open(rf, \"a\") as fh: fh.write(\"b\\n\")\n    ns = {\"subprocess\": subprocess, \"os\": os, \"relay_file\": rf, \"transcript_repo\": lambda: d,\n          \"eprint\": lambda *a, **k: None}\n    exec(textwrap.dedent(ast.get_source_segment(src, fn[0])), ns)\n    ok = ns[\"commit_relay_file\"](\"m1\")\n    landed = g(\"rev-list\", \"--count\", \"HEAD\").stdout.strip() == \"2\"\n    assert landed, \"fixture: the attest commit did not land\"\n    assert ok is True, \"tracked relay file under a gitignored dir: commit landed but reported failure\"\n    os.remove(os.path.join(d, \".gitignore\")); g(\"commit\", \"-qam\", \"drop ignore rule\")\n    with open(rf, \"a\") as fh: fh.write(\"n\\n\")\n    assert ns[\"commit_relay_file\"](\"m-plain\") is True, \"repo without the ignore rule must still attest\"\n    assert not g(\"status\", \"--porcelain\", \"--\", \"relay-system\").stdout, \"plain-repo commit did not land\"\n    hook = os.path.join(d, \".git\", \"hooks\", \"pre-commit\")\n    with open(hook, \"w\") as fh: fh.write(\"#!/bin/sh\\nexit 1\\n\")\n    os.chmod(hook, 0o755)\n    with open(rf, \"a\") as fh: fh.write(\"c\\n\")\n    assert ns[\"commit_relay_file\"](\"m2\") is False, \"a real commit failure must still report False\"\nfinally:\n    shutil.rmtree(d, ignore_errors=True)\nPY",
      "expect_nonzero": true
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-11-27+GH-1423/delivery.md"
    }
  ],
  "remediation": {
    "source": "issue#1423",
    "criteria": "commit_relay_file returns True when the file-scoped commit of a tracked relay file under a gitignored directory lands, still True in a repo without the ignore rule, and False when the commit genuinely fails. Change relay_drive.py only (commit_relay_file), keeping it callable with subprocess, os, relay_file, transcript_repo and eprint in scope. Record the manual repro (red exit 4 with the git add stderr, green after the fix, genuine-failure control) in TESTS-RESULTS/2026-11-27+GH-1423/delivery.md. No new suite, no suite edits."
  }
}
```

The probe is an inline manual check, not a suite: it writes only to its own temp directory, exits 0 only when the fixed behavior and both controls hold, and `expect_nonzero: true` makes any crash read as unfixed. It is inline so it evaluates at `prepared_commit` itself. A readable copy and its red/green outputs are in `TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/`.

## Merge evidence

- PR #1424 merged 2026-11-12 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
