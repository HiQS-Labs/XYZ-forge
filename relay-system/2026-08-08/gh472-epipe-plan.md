# Relay — GH-472 plan review before execution

STATUS: Open
NEXT: Reviewer
Producer: claude-a
Reviewer: codex

**Review the PLAN, do not implement it. Review only — your allowlist is this relay file.** Append your
block at the bottom and hand back. Nothing has been changed yet.

## The bug class

`printf '%s' "$var" | grep -Fq NEEDLE` under `set -o pipefail`. `grep -q` exits on match, so if `$var`
exceeds the pipe buffer the writer takes SIGPIPE and `pipefail` promotes that to the pipeline status —
failing an assertion whose subject is correct. GH-460 was one instance; it blocked every open PR and was
misdiagnosed twice. Verified just now at 1MiB: the piped form exits **141**, the same string under the
buffer exits 0.

## Scope, corrected twice — please attack this

The issue body says **366 files**. That was my measurement error (`grep -lc` prints a line per file
*searched*, not per match). Real: **52 files carry the shape, 285 occurrences.**

I then narrowed to 15 "at-risk" files (those also invoking a repo-wide tool, so the payload grows with
the repo). Then narrowed again, and this is the part I most want checked:

**Only 5 of those files actually set `pipefail`.** Without `pipefail`, the pipeline's status is
`grep`'s, so the writer's SIGPIPE is invisible and the bug cannot bite. Verified per file:

| file | shell options | sites |
|---|---|---|
| `test/gh308-frozen-twin-guard.sh` | `set -euo pipefail` (:9) | 6 |
| `test/gh438-acceptance-recheck.sh` | `_setup.sh` then `set -eu` (:67) | 5 |
| `test/gh284-p3-release-milestone.sh` | `_setup.sh` (pipefail) | 14 |
| `test/pdda-roadmap-coverage.sh` | `_setup.sh` (pipefail) | 8 |
| `utils/pdda-local-checks.sh` | `set -uo pipefail` (:38) | 4 |

Excluded, `set -u` only, no pipefail anywhere including sourced libs: `test/hq-park.sh`, `test/hq.sh`,
`test/hq-promote.sh`, `test/hq-park-synthesis.sh`, `test/hq-hardening.sh`, `utils/hq/hq.sh`,
`utils/hq/hq-lib.sh`, `utils/pdda/pdda.sh`. `validate.sh` runs each test as `bash test/<f>`, a fresh
shell, so options are not inherited from the runner.

So the proposed work is **5 files / 37 sites**, not 13 files and not 366.

## Existing in-repo precedent

`test/gh308-frozen-twin-guard.sh:114-118` already hit this class and recorded the resolution:

> *Deliberately NOT `| head -1`: head closing the pipe early makes git's write fail, and under
> `set -euo pipefail` that surfaced as `printf: write error: Interrupted system call` on every call.
> Take the first line in-shell instead.*

## The candidate fixes, measured at 1MiB under pipefail

| form | exit |
|---|---|
| `printf '%s' "$big" \| grep -Fq X` | **141** |
| `grep -Fq X <<<"$big"` (herestring) | 0 |
| write to a file, `grep -Fq X file` | 0 |
| `case "$big" in *X*)` (pure shell) | 0 |

**My proposal: herestring.** One-line mechanical change per site, preserves every grep flag and regex
semantic already in use (`-F`, `-i`, `-E`, `-x`), no temp-file bookkeeping, no logic restructuring. The
file form is what GH-460 used but it needs a path variable per site. Pure shell is fastest but changes
semantics wherever the needle is a pattern rather than a literal.

## Proposed regression guard

Extend `test/gh460-pipe-buffer-sigpipe.sh` with a conditional invariant rather than a repo-wide lint:

> **For any file that sets `pipefail`, no non-comment line may pipe a variable into `grep -q`.**

That is deliberately conditional so it (a) auto-covers a file that *gains* `pipefail` later — the silent
path into this bug — and (b) does not fire on the ~37 harmless occurrences in non-pipefail files, which
would be permanent false-positive noise. Comment lines must be stripped: an earlier version of a
similar guard matched the comment documenting the rule.

I do NOT propose a repo-wide lint or touching the other 47 files.

## Questions

**Q1.** Is the `pipefail` exclusion sound? Is there a route by which a non-pipefail file becomes
vulnerable that I have missed — sourced into a pipefail shell, `bash -o pipefail` invocation, a
function called from a pipefail context, `set -o pipefail` inside a function, anything?

**Q2.** Herestring, file, or pure shell? Note bash writes `<<<` to a temp file rather than a pipe, which
is why it has no reader to lose — confirm or refute, and say whether that is portable enough here.

**Q3.** Is the conditional guard ("a file that sets pipefail must not carry the shape") the right
invariant, or is it too clever? Would you prefer an unconditional guard over the 5 files by name?

**Q4.** 37 mechanical edits across 5 files, two of which (`utils/pdda-local-checks.sh`,
`test/gh308-frozen-twin-guard.sh`) matter a lot. How would you keep it verifiable — per-file commits,
before/after assertion counts, something else? What is the failure mode of a mechanical rewrite here?

**Q5.** Anything wrong, missing, or over-built in this plan. If you think the whole thing should be
deferred or scoped differently, say so — the operator has asked for it now, but a bad plan is worse.

Grade `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`. Be blunt.

---

## Turn log

### Round 1 · Producer · claude-a

Plan above. Nothing implemented yet. Handing to codex for Q1-Q5.
