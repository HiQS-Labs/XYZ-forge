# GH-1499 smoke — skill_drift_check.py on tier and flat collections (manual check, GH-831)

Commands (from the repository root; pre = origin/development's script via git show, post = this branch):
  python3 -B <script> --canonical . --collection <LTVera-Pandas>/.xyz/skills     # tier layout, vendored
  python3 -B <script> --canonical . --collection ~/git-pulse-sync/Deployed\ Skills  # flat layout

```
== pre: tier layout (vendored .xyz/skills)
0 ok, 0 drifted, 0 unrecognized
rc=0
== pre: flat layout (Deployed Skills)
43 ok, 2 drifted, 26 unrecognized
== post: tier layout (vendored .xyz/skills)
62 ok, 16 drifted, 0 unrecognized
rc=1
== post: flat layout (Deployed Skills)
43 ok, 2 drifted, 26 unrecognized
```

Pre-fix compared 0 skills on the tier layout and exited 0 (a pass that checked nothing). Post-fix compares 78 there; the 16 drifted are real (that vendor predates this development tip), so exit 1 is correct. The flat layout result is identical before and after.

Existing suite: bash test/gh660-skill-drift.sh -> gh660-skill-drift: 7 pass, 0 fail

## Round 2 (after Codex final QA Blocker: nested name overrode a flat skill)

Fix: depth one always wins, and a depth-two SKILL.md counts only under a folder that is not itself a skill.

| Run | Observed |
|---|---|
| Fixture: flat `coll/alpha/SKILL.md` drifted + nested `coll/zeta/alpha/SKILL.md` matching canonical | `0 ok, 1 drifted, 1 unrecognized` (drift reported) |
| Same fixture, previous candidate `ca351b11a` (red control) | `1 ok, 0 drifted, 1 unrecognized` (drift hidden) |
| Fixture: tier `tier/1-hourly/alpha/SKILL.md` | `1 ok, 0 drifted, 0 unrecognized` |
| Real tier tree (vendored .xyz/skills) | `62 ok, 16 drifted, 0 unrecognized` |
| Real flat tree (Deployed Skills) | `43 ok, 2 drifted, 26 unrecognized` (identical to pre-fix) |
| bash test/gh660-skill-drift.sh | `gh660-skill-drift: 7 pass, 0 fail` |
