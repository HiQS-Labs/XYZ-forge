---
title: "GH-113: headless agy builder writes root scratch files, tripping containment (exit 6)"
status: active
created: 2026-08-22
updated: 2026-08-22
owner: orchestrator (Claude Code)
goal: give headless builder turns a sanctioned scratch lane so debugging temp files can never trip the containment guard
gh_issue: 113
source: https://github.com/HiQS-Labs/XYZ-forge/issues/113
branch: gh-113/headless-scratch-containment
doc_type: bugfix
effort: 2
complexity: 2
risk: 2
related:
  - "#114 — same headless agy-turn seam, different failure (TTY/idle hang); shared artifact relay-automation/agy-turn.sh, sequence after or same wave lane"
  - "#115 — same marathon-drive seam (round-cap escalation)"
---

# GH-113 — headless builder scratch files trip containment

## Status

| What was just completed | What's next |
|---|---|
| capture doc + preflight contract written (ready, exit 0); queued as Bulkhead wave 5 (2026-08-22, release 0.7.3 "Bulkhead", #179) | Operator fires the marathon lane per MARATHON-PLAN-2026-08-23.md; builder executes ## Plan, reviewer verifies ## Acceptance |


Release 0.7.3 "Bulkhead" manifest member. Radar 2026-08-22:
RADAR-class-suite-containment (kill-legitimate-work polarity). Observed in
`marathon/daybreak-wave-2-2026-08-20`: agy created `fix_lens1.py`, `test_lens6.py`, `tmp.json`
in the tree root; `rtl_check()` reverted them into `.tick/orphan-backups/` and failed the turn
with exit 6 (containment-violation).

## Bug

Headless builder prompts rely on prose ("no root scratch files") that the model ignores while
debugging. There is no sanctioned writable scratch lane in the turn's ALLOW_PATHS, so any
temp file is an off-allowlist change and the guard's only move is revert-and-fail.

## Plan

1. `utils/py/agy-turn.py` (authoritative Python lane; the Bash twin is FROZEN per GH-308):
   provision a per-turn scratch dir (`.relay-scratch/<turn>/`,
   already gitignored per GH-91) and export it as TMPDIR/scratch guidance in the builder prompt;
   add it to the turn's allowlist.
2. `utils/py/marathon_drive.py`: same provisioning for marathon-generated turns.
3. Soft-landing in `rtl_check()`: a root-level scratch-shaped file (matching a small extension
   allowlist) is MOVED to the turn scratch dir with a warning instead of failing the turn;
   genuinely off-lane edits to tracked files still exit 6.
4. `test/gh113-headless-scratch.sh`: a synthetic turn that writes `tmp.json` at root completes
   with the file relocated and turn exit 0; an off-lane tracked-file edit still exits 6.
   Register in validate.sh TESTS.

## Acceptance

- [ ] Daybreak-wave-2 repro shape (root `tmp.json` written during a builder turn) no longer fails the turn — the file relocates to the sanctioned scratch lane instead.
- [ ] Containment still refuses an off-lane edit to a tracked file (exit 6 unchanged).
- [ ] `test/gh113-headless-scratch.sh` green and registered in validate.sh.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "path_absent", "path": "test/gh113-headless-scratch.sh" } ],
  "artifacts":     [ "utils/py/agy-turn.py", "utils/py/marathon_drive.py", "test/gh113-headless-scratch.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh113-headless-scratch.sh" ],
  "remediation":   { "source": "self#plan", "criteria": "scratch-shaped root files relocate to the sanctioned per-turn scratch lane without failing the turn; tracked-file violations still exit 6; gh113 suite green" },
  "lanes":         { "agy_safe": [ "test/gh113-headless-scratch.sh" ], "orchestrator_only": [ "relay-automation/", ".tick/" ] }
}
```

## Lessons Learned (For Future Agents)

- Prose rules in a builder prompt ("no root scratch files") are not containment: models ignore
  them under debugging pressure. Give the turn a sanctioned scratch lane and relocate strays
  into it (`rtl_scratch_relocate` → `.tick/scratch/<ts>-$$/`) instead of failing the turn.
- Keep the relocation a room, not an amnesty (GH-91's line): only untracked, root-level,
  scratch-NAMED files qualify; nested paths, dotfiles, and tracked off-lane edits still exit 6.
- Wire the same relocation into BOTH containment paths (`rtl_check` and `rtl_worktree_end`) —
  the non-worktree path is where the daybreak-wave-2 shape actually fired.
