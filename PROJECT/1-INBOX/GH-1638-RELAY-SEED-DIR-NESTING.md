---
gh_issue: 1638
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1638
title: "relay turn worktree seeding mirrors an existing allowlisted directory in place instead of nesting it"
status: "Prepared 2026-11-27 (1-INBOX, not enqueued, not started)"
created: 2026-11-27
updated: 2026-11-27
owner: Conveyor preparation (Flywheel Run A queue; ledger #1658)
doc_type: bugfix
ratings_provisional: true
non_goals:
  - "The issue's second item, the directory allowlist entry dropped from the commit pathspec (`relay-automation/relay-turn-lib.sh:1629-1634`): not in this packet; #1638 stays open for it"
  - File allowlist entries, archive-absolute entries and the SEED-DELETE branch (`:778-790`), which are unchanged
  - The node_modules copy (`:766-772`) and the copy-back in `rtl_worktree_end` (`:951-965`)
  - A new test suite or gate machinery (GH-831); edits to any existing suite
goal: >
  When a turn's allowlist names a directory that already exists in the worktree checkout,
  rtl_worktree_begin mirrors the host directory in place: no `<dir>/<basename>` nested copy, and the
  worktree carries the host's current content of the files under it.
---

# GH-1638 · Relay worktree seeding nests an existing allowlisted directory

## Status

| What was just completed | What's next |
|---|---|
| Recon, capture, Preflight Contract, probe proof (unfixed / simulated fix / fake fix), consumer validation and PRS rating prepared 2026-11-27 at `6142128d9c43`. No implementation, no queue admission. | Preparation review, publication of the Run A preparation PR, merge to `development`, then a fresh preflight at the integration ref (Conveyor step 6). Next owner: the Run A launch step (#1658). |

## Acceptance

- [ ] Seeding an allowlisted directory that already exists in the worktree leaves no nested `<dir>/<basename(dir)>` copy: the issue's red control (`find "$dir" -mindepth 1 -maxdepth 2 -name "$(basename "$dir")"`) is empty.
- [ ] The seeded directory carries the host tree's current content (an uncommitted edit under it is visible in the worktree), and nested files are kept.
- [ ] A manual red/green check is recorded under `TESTS-RESULTS/` (GH-831: no new suite), and the vendored `relay-pkg.tar.gz` is regenerated with `skills/1-hourly/relay-automation/make-pkg.sh`.

## Acceptance — deviations from the issue

The issue has no `## Acceptance` heading, so Preflight reports acceptance fidelity as advisory. The criteria above are declared here.

- [added] Seeding an allowlisted directory that already exists in the worktree leaves no nested `<dir>/<basename(dir)>` copy: the issue's red control (`find "$dir" -mindepth 1 -maxdepth 2 -name "$(basename "$dir")"`) is empty. — reason: the issue's own "Red control" and first "Expected" sentence.
- [added] The seeded directory carries the host tree's current content (an uncommitted edit under it is visible in the worktree), and nested files are kept. — reason: the issue's observed stale nested `provenance.jsonl`/`readiness_probe.py`; the nest also leaves the top-level files at their HEAD version (reproduced), and the probe pins that so "skip directories" cannot read as fixed.
- [added] A manual red/green check is recorded under `TESTS-RESULTS/` (GH-831: no new suite), and the vendored `relay-pkg.tar.gz` is regenerated with `skills/1-hourly/relay-automation/make-pkg.sh`. — reason: repository no-new-suite rule; `relay-turn-lib.sh` is packaged in `relay-pkg.tar.gz` (`make-pkg.sh:18`), which `test/relay-pkg-freshness.sh` checks.

## Recon note (parent-only)

The operator's brief asked for capture, contract, preflight and one independent review. The parent read the whole seam, so no separate research child was dispatched. Budget: this preparation session; attempts consumed: 0.

- **Baseline:** `origin/development` at `6142128d9c433d6b12972c6cd9a6f864f0ed9da2` (2026-11-27).
- **Observed (reproduced):** in a scratch repo with `seeded/f.txt` and `seeded/sub/g.txt` committed and `seeded/f.txt` then edited, `RTL_ALLOW=("seeded")` and `rtl_worktree_begin` produce `<wt>/seeded/seeded/`, and `<wt>/seeded/f.txt` keeps the HEAD content (`v1`) instead of the host's edit (`v2`).
- **Call path:** every turn shim (Python by default, e.g. `relay-automation/codex-turn.sh` → `utils/py/codex-turn.py`) reaches `rtl.py` `worktree_begin` (`utils/py/rtl.py:1156-1161`), which runs the Bash `rtl_worktree_begin` (`relay-automation/relay-turn-lib.sh:722`). Its seeding loop (`:774-791`) does `mkdir -p "$wt/$(dirname "$a")"; cp -R "$RTL_ROOT/$a" "$wt/$a"` (`:783-784`). After `git worktree add` the directory already exists, so BSD/GNU `cp -R src dst` copies **into** it. There is no separate Python seeding (the issue's "Python twin" check: `rtl.py` delegates).
- **State writer / consumer:** the seed is the writer; `rtl_worktree_end` copies changed allowlisted paths back and commits them, which is how the nest reached a real lane's commits (issue, GH-1315 lane).
- **Smallest plan:** for an existing directory entry, remove the destination before copying (or copy the directory's contents with `cp -R "$src/." "$dst"` after clearing it). One loop, one file, plus regenerating `relay-pkg.tar.gz`.
- **Dependencies / overlap:** no open PR touches `relay-turn-lib.sh` or `relay-pkg.tar.gz`. Any other change under `relay-automation/` that regenerates the package before Run A would make this packet stale under #1664, which is the gate working as intended.
- **Discriminating check:** the probe (contract below) sources the library and runs the real `rtl_worktree_begin` against a scratch repo (inherited `GIT_*` dropped, global/system git config off, `TMPDIR` inside its own temp dir, worktree removed and temp dir deleted afterwards). It exits 0 only when there is no nested copy, the host edit is seeded and the nested file survives. Matrix (`TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/matrix.txt`): base 1; simulated fix (`sim-gh1638.patch`, `rm -rf` before `cp -R`) 0; fake fix (`fake-gh1638.patch`, skip directory entries) 1.
- **Write set:** `relay-turn-lib.sh`, the regenerated `relay-pkg.tar.gz`, plus one new delivery receipt (`artifacts_new`, with a `path_absent` probe).
- **Foreseeable approvals/runtime:** none; probe and gate need no network.
- **Unknowns:** none blocking.
- **Next owner:** the Run A launch step (#1658), then Jog.

## Attempt and retry history (read 2026-11-27, nothing reset)

- No `roadmap_items` row, no `jog_queue` row, no capture, no issue comments, no branch or PR for #1638 before this preparation. Attempts consumed: 0.

## Rating rationale

`rated 55/50/50/80` (sum 235), written through `roadmap pickup` on 2026-11-27; `ratings_provisional` stays true until the operator confirms.

- Severity 50: a builder turn commits a stale duplicate tree that conflicts with the real files; a reviewer flagged it as a blocker and it was removed by hand.
- Priority 55: observed on a real Flywheel lane (GH-1315, Day 2).
- Appeal 50: neutral.
- Effort 80: one loop plus the package regeneration.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash test/worktree-isolation.sh",
  "round_cap": 9,
  "prepared_commit": "6142128d9c433d6b12972c6cd9a6f864f0ed9da2",
  "artifacts": [
    "relay-automation/relay-turn-lib.sh",
    "skills/1-hourly/relay-automation/relay-pkg.tar.gz",
    "TESTS-RESULTS/2026-11-27+GH-1638/delivery.md"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-11-27+GH-1638/delivery.md"
  ],
  "fix_probes": [
    {
      "type": "command",
      "cmd": "env bash -s <<'SH'\nset -u\nL=\"$PWD/relay-automation/relay-turn-lib.sh\"\nfor v in $(env | sed -n 's/^\\(GIT_[A-Za-z_]*\\)=.*/\\1/p'); do unset \"$v\"; done\nexport GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null\nT=\"$(mktemp -d \"${TMPDIR:-/tmp}/gh1638-probe.XXXXXX\")\" || exit 2\nR=\"$T/repo\"; mkdir -p \"$R/seeded/sub\" && cd \"$R\" || exit 2\ngit init -q && git config user.name probe && git config user.email probe && git config commit.gpgsign false\necho v1 > seeded/f.txt; echo s1 > seeded/sub/g.txt; git add -A && git commit -qm init || exit 2\necho v2 > seeded/f.txt\nexport TMPDIR=\"$T\"\nrc=1\n(\n  source \"$L\" >/dev/null 2>&1 || exit 3\n  RTL_ROOT=\"$R\"; RTL_ALLOW=(\"seeded\")\n  wt=\"$(rtl_worktree_begin)\" || exit 4\n  [ -d \"$wt\" ] || exit 4\n  st=0\n  [ -z \"$(find \"$wt/seeded\" -mindepth 1 -maxdepth 2 -name seeded)\" ] || { echo \"nested copy: $(find \"$wt/seeded\" -mindepth 1 -maxdepth 2 -name seeded)\" >&2; st=1; }\n  [ \"$(cat \"$wt/seeded/f.txt\")\" = v2 ] || { echo \"seed did not carry the current content\" >&2; st=1; }\n  [ \"$(cat \"$wt/seeded/sub/g.txt\")\" = s1 ] || { echo \"seed lost a nested file\" >&2; st=1; }\n  git -C \"$R\" worktree remove --force \"$wt\" >/dev/null 2>&1\n  exit $st\n); rc=$?\ncd / && rm -rf \"$T\"\nexit $rc\nSH",
      "expect_nonzero": true
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-11-27+GH-1638/delivery.md"
    }
  ],
  "remediation": {
    "source": "issue#1638",
    "criteria": "rtl_worktree_begin mirrors an allowlisted directory that already exists in the worktree in place: no <dir>/<basename> nested copy, host's current file content seeded, nested files kept. Change only the seeding loop in relay-automation/relay-turn-lib.sh, regenerate skills/1-hourly/relay-automation/relay-pkg.tar.gz with make-pkg.sh, and record the probe's before/after output in TESTS-RESULTS/2026-11-27+GH-1638/delivery.md. Leave the commit-pathspec filter (:1629-1634) for a separate change. Do not edit any Preflight-inferred lane path (for example test/_setup.sh); they are shared with other Run A packets. No new suite, no suite edits."
  }
}
```

The probe is an inline manual check, not a suite: it writes only inside its own temp directory, exits 0 only when the fixed behavior holds, and `expect_nonzero: true` makes any crash read as unfixed. It is inline so it evaluates at `prepared_commit` itself. A readable copy (`probe-gh1638.sh`) and its red/green outputs are in `TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/`.
