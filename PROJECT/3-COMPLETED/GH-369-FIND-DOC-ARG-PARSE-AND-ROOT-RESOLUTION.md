---
gh_issue: 369
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/369
title: "GH-369 — find-doc.sh spun forever on a valueless --root, and named a flag the caller never passed for a bad $TENDAYS_ROOT; both landed because the file had no test"
status: "Shipped: both defects fixed, new test/gh369-find-doc-root-resolution.sh (14/0) registered in validate.sh. Observed failing against BOTH prior revisions — 12/2 vs the pre-fix parser, 4/10 vs the pre-#364 harness-relative resolver."
created: 2026-07-30
updated: 2026-07-30
owner: noel
doc_type: fix
complexity: 2
risk: 2
effort: 1
ratings_provisional: false
related:
  - "#364 — the PR under review when this was found; its GH-344 fix is correct and shipped, these are defects in the parser it added"
  - "#344 — resolve PROJECT/** from the swept repo; verified by hand in a PR comment, never by CI, until now"
  - "#329 — the sibling half of #364 (harness root resolution in SKILL.md)"
  - "#351 — same family: an assertion that cannot distinguish the bug from the fix"
  - "#315 / #319 — the absent-signal class this hang belongs to"
non_goals:
  - Reverting or weakening PR #364. Its resolution fix is correct and independently verified across 370 issue numbers.
  - "Making find-doc.sh `set -e`. The `-e` exemption is deliberate and documented for the analysis-tool profile (find/grep misses are expected and handled explicitly); the fix is to check `$#` before shifting, not to change the strictness profile."
  - "Fixing the two-positional-args case (`5 12` silently takes the last). Real but harmless; noted in the issue, not filed."
goal: >
  Stop find-doc.sh hanging a sweep on a malformed invocation, make a bad root name its actual
  source, and — the durable half — put the file under test at all, so that neither these defects
  nor GH-344's resolution order can regress silently again.
---

# GH-369 · a helper that hangs instead of exiting, in a skill built to run unattended

## Status
| What was just completed | What's next |
|---|---|
| Both defects fixed. New `test/gh369-find-doc-root-resolution.sh` **14/0**, registered in `validate.sh`. Proved by running the *same* test against both prior revisions: **12/2** vs pre-fix, **4/10** vs pre-#364. | Nothing required. Optional: `find-harness.sh` still has no `pi` probe (GH-347 Phase 3), unrelated but adjacent. |

## What was actually wrong

### (1) `--root` with no value looped forever

```bash
--root) ROOT_ARG="${2:-}"; shift 2 ;;
```

With one argument left, `shift 2` **shifts nothing and returns non-zero**. `$#` never decreases,
`$1` is still `--root`, and the `while` re-enters the same branch indefinitely.

`set -e` would have aborted cleanly, but this script is deliberately `-e`-exempt with a documented
header — correct for the find/grep misses it was written around, and it means a failed `shift` is
silent.

**Why this is not a usage nit.** `/10days` describes itself as *"an operator-authorized exception…
it exists specifically to run unattended."* A helper that hangs rather than exiting 2 stalls a sweep
with no error, no output and no timeout. That is the **absent-signal** failure class — the same one
as #315, #319 and #351 — not a wrong answer. Wrong answers get noticed.

Confirmed with an `alarm(5)` wrapper: **rc=142 / SIGALRM**, empty output.

### (2) A bad `$TENDAYS_ROOT` reported `--root`

```
$ TENDAYS_ROOT=/no/such/dir bash skills/10days/find-doc.sh 5
find-doc.sh: --root not a directory:
```

Two faults in one line: it names a flag the caller never passed, and it interpolates `$ROOT_ARG`,
empty on that path, so it prints **no path at all**. Now the resolver records which of its four
sources supplied the value and the message names that one.

**My first fix repeated the same class of bug** and is worth recording rather than quietly
correcting: I printed `$ROOT`, which the failed command substitution had already overwritten with
the empty result *before* `||` ran. Preserved as `$ROOT_RAW`, with the reason in a comment.

## Verification — and one assertion that proved nothing

The test was run against **three** revisions, not one:

| Revision | Result | What it demonstrates |
|---|---|---|
| current (fixed) | **14 / 0** | — |
| `1612878` — post-#364, pre-fix | **12 / 2** | exactly cases 1 and 2, and the hang is *reported as a failure* instead of hanging the suite |
| `4dc27b4` — pre-#364 | **4 / 10** | case 6 catches the GH-344 bug: *"answered GH-163 from the HARNESS tree"* |

**Case 6 was wrong first, and that is the most useful thing in this doc.** As originally written it
probed issue `777` — a number absent from *both* the harness and the fixture repos. So the
harness-relative bug and correct behaviour both returned `null`, and the case **passed against the
very code it was written to catch**. It now derives a real `GH-<N>` from the harness's own
`PROJECT/` tree, so a drifted resolver answers with the harness's document and the case fails.

That makes a fifth member of this repo's recurring family — an assertion that cannot distinguish the
bug from the fix — after #348, #342's, #351's, and #362's (B). It was caught only by running the new
test against the old code, which is the practice that keeps finding these.

## The durable half

`skills/10days/find-doc.sh` had **no test file** and was not in `validate.sh`'s `TESTS=()`. That is
why both defects shipped, and why GH-344's resolution order — verified by hand in a PR comment
across 370 issue numbers — had no standing protection at all. The new test covers arg parsing,
all four resolution sources, their documented precedence, and the harness-relative regression
itself.

Every hang-capable case runs under a hard `alarm` cap. Without it, a regression of defect (1) would
**hang `validate.sh`** rather than fail it — reintroducing, in the gate, the exact absent-signal
problem the fix is about.

`perl -e 'alarm …'` rather than `timeout(1)`, which is GNU coreutils and not present by default on
macOS — the same bash-3.2-era constraint that caught `mapfile` in GH-362.
