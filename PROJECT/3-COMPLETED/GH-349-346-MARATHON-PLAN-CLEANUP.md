---
gh_issue: 349
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/349
title: "GH-349 + GH-346 — marathon-plan cleanup: an unknown flag no longer exits 0, and `branch:` is derived instead of hardcoded"
status: "Shipped: unknown flag exits 2 on both lanes; `branch:` derives the repo trunk in BOTH engines with byte parity; three stale UPGRADE.md references to the deleted JS renderer corrected. marathon-plan 72/0, observed 65/7 pre-fix."
created: 2026-07-29
updated: 2026-07-29
owner: noel
doc_type: fix
complexity: 2
risk: 2
effort: 2
ratings_provisional: false
related:
  - "#346 — `branch: main` hardcoded in every generated plan (folded into this PR; both are marathon-plan front-door defects)"
  - "#340 / PR #341 — the native Python engine; it changed #346's fix surface from one file to two"
  - "#348 — the parity gate this PR is stacked on; it is what makes the two-engine `branch:` change verifiable"
  - "#322 — the same defect class as #349: the Python lane silently accepting what Bash rejects"
non_goals:
  - Dropping the `branch:` field. The issue offered it as an alternative; deriving keeps parity with every hand-written PDDA doc, which all carry a real branch name.
  - Deriving the CURRENT branch. It is the repo's trunk — deriving HEAD would make `--check` report drift merely because someone cut a feature branch.
  - Reconciling the two lanes' usage TEXT. The Python usage block omits `--zones-config` because the Bash wrapper translates that flag before Python runs; that divergence is intended and documented in marathon_plan.py's module docstring.
  - Retiring marathon-plan's GH-308 exception. Separate decision.
goal: >
  Close the two marathon-plan front-door defects found while reviewing PR #341. Make an unknown flag a
  usage error (exit 2) on the lane that actually runs, matching the Bash twin; derive the rendered
  plan's `branch:` front-matter from the repo's trunk in BOTH engines with byte-identical output; and
  correct the three UPGRADE.md references to the JS renderer that GH-340 deleted.
---

# GH-349 + GH-346 · marathon-plan cleanup

## Status
| What was just completed | What's next |
|---|---|
| Unknown flag → exit 2 on both lanes (`print_usage()` split from the exit). `branch:` derived from the trunk in `utils/marathon-plan.sh` **and** `utils/py/_marathon_plan.py`, byte-identical, with a `QUEUE_PLAN_BRANCH` override/test seam. Three `UPGRADE.md` spots corrected. New Scenarios U + V: `marathon-plan` **72/0**, observed **65/7 pre-fix**. | Review + merge. Stacked on #348 — merge that first. |

## GH-349 · an unknown flag exited 0 on the lane that runs

`utils/py/marathon_plan.py`'s `usage()` ended in an unconditional `sys.exit(0)`, which made the
`die(f"unknown argument: {arg}")` on the following line **unreachable**:

```
utils/marathon-plan.sh --bogus    →  rc=0   (Python, the default lane)
XYZ_PYTHON=0 ... --bogus          →  rc=2   (Bash)
```

Practical bite: a pipeline running the drift gate with one mistyped flag —

```bash
utils/marathon-plan.sh --check --requre-gh || alert "plan drifted"
```

— printed usage, compared nothing, and returned **success**. Same class as #322.

**Fix:** split printing from exiting. `print_usage()` prints and returns; `--help` calls it then
`sys.exit(0)`; the unknown-argument branch calls it then `die(...)` → exit 2. That is exactly the Bash
shape (`utils/marathon-plan.sh:102` prints only; `:139` is `usage; die "unknown argument: $1"`), so
usage goes to stdout and the error to stderr on both lanes.

## GH-346 · `branch:` was the string literal "main"

`o.push("branch: main")` — hardcoded, in every generated plan. Reported against `rebalance-OS`, whose
trunk is `development`, so the plan asserted a branch that exists but is not the trunk and is not where
any lane would land. The reporter's point stands: of 41 docs in that repo's `PROJECT/2-WORKING`, only
the two *generated* plans said `main`, so a reader has good reason to trust the field.

**#346's fix note was already stale when it was filed.** It said:

> The Python lane contains no `branch:` string of its own … so both lanes reach this same renderer.
> Fixing it once at `:945` covers both.

True while `marathon_plan.py` shelled out to the copied JS. GH-340 (PR #341, merged `1d06862`) replaced
that with a native Python engine that has **its own renderer** — `utils/py/_marathon_plan.py:1151` had
its own `o.append("branch: main")`. The fix needed both files, and #348's now-working parity gate is
what makes "both" verifiable rather than hopeful.

**Trunk, not current branch.** Deriving HEAD would make `--check` report drift merely because someone
cut a feature branch. The field clearly meant the trunk — the issue's own title says *"wrong for any
repo whose trunk is not `main`"*. Resolution order, identical in both engines:

1. `QUEUE_PLAN_BRANCH` — explicit override, and the hermetic test seam (the suite's fixture roots are
   plain directories, not git repos)
2. `git symbolic-ref --short refs/remotes/origin/HEAD`, with the `origin/` prefix stripped — the same
   source `release-lanes.sh` uses for its trunk
3. `git rev-parse --abbrev-ref HEAD` — a repo with no `origin/HEAD` still has an answer worth printing
4. `unknown`

**Why `unknown` and not `main` as the floor.** PDDA does not require this key (`pdda.sh:39` lists
`title status created updated owner goal`), and no consumer of it was found. A wrong value is worse
than an absent one; `main` was wrong for every repo whose trunk is not `main`, which is what the issue
is about. Verified: this repo renders `branch: main` (its `origin/HEAD` *is* `main`), and a non-git root
renders `branch: unknown` on both lanes.

## Verification

`test/marathon-plan.sh` **72 passed / 0 failed**, observed **65 passed / 7 failed** against pre-fix
sources (`git checkout HEAD -- utils/...`, re-run, restore). The three pre-fix passes are honest and
worth naming, because each one is a thing that was *already* correct: usage already went to stdout,
`--help` already exited 0, and the Bash lane already exited 2 — that last one being the entire premise
of #349.

New Scenario **U** (GH-349): unknown flag exits 2 on the **default** lane; the error names the flag, on
stderr; usage still on stdout; `--help` still 0; and the Bash lane agrees on the code — because a
caller's `|| alert` firing on one lane only is the actual failure mode.

New Scenario **V** (GH-346): neither engine still contains the hardcoded literal; a non-git root renders
`branch: unknown`; `QUEUE_PLAN_BRANCH` overrides on both lanes; and **the whole rendered doc is
byte-identical between the two engines** — a derived value computed differently in two places is
exactly the drift class #348 exists to catch, and this is the change most likely to introduce it.

Beyond the suite, checked by hand on the live 160-item ROADMAP: both lanes render the same 233-line doc
byte-for-byte with the derived branch, and the `QUEUE_PLAN_BRANCH` seam and the no-git fallback agree
across lanes.

## Also corrected

Three `UPGRADE.md` spots still described a file GH-340 deleted — `:164`, `:246` (interpreter matrix),
and `:251` ("the 10 non-marathon-plan twins"). Low severity, since Node remains a **baseline**
requirement via `bin/tick` and the document's operative conclusion ("there is no flip-without-Node
subset") was never wrong. But two of them pointed at a path that no longer exists, and the
marathon-plan carve-out in the prose had inverted: its Python lane is now the one entry point that
does *not* need Node for its own work.
