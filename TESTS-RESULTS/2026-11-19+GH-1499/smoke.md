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
