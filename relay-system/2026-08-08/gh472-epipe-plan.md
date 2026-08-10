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
misdiagnosed twice. Verified just now at 1MiB: the piped form exits **141**, the same string under the  [Unverified — no citation]
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

### Round 1 · Reviewer · codex

**Grade: [Should] — proceed after tightening the scope claim and the replacement contract.** The
current five-file / 37-site count is internally consistent with the current tree (6 + 5 + 14 + 8 +
4). This is a bounded, reversible mechanical change, but the plan presently overstates two
guarantees.

**Q1 — [Should].** “No `pipefail`, so the bug cannot bite” is sound only for the normal invocation
of these standalone scripts in a fresh Bash. It is not a general property of a file: a caller can
source it after enabling `pipefail`, invoke it as `bash -o pipefail file`, or deliberately export
`SHELLOPTS` into a child Bash. A function runs with its caller's options, too. There is no evidence
here that the excluded files are normally reached that way, and `validate.sh`'s `bash test/<file>`
form does give the stated fresh-shell boundary. Amend the claim to that supported-execution
boundary, rather than claiming the 47 files are categorically harmless. In particular, a physical
file guard cannot discover an externally sourced library/function context.

**Q2 — [Should].** Use a here-string only after accepting its input contract. Bash appends one
newline to `<<<"$value"`; `printf '%s' "$value"` does not. Thus the proposal does *not* preserve
every grep semantic: empty input, input ending in a newline, and patterns able to match the added
empty line can differ. The assertion sites shown appear likely safe, but that must be audited per
site; `-x` is a useful reason not to wave this away. Also refute the explanation that Bash always
writes a here-string to a temp file: that is an implementation/size detail, not its language
contract. It is nevertheless Bash-portable for these `#!/usr/bin/env bash` files and removes the
concurrent `printf | grep -q` producer/consumer shape. If exact bytes must be retained without a
site audit, retain the file form; pure shell globbing changes matching semantics more broadly.

**Q3 — [Should].** Prefer an explicit, comment-aware static check over the five named files as the
required regression guard. It states exactly what this issue fixes and avoids pretending that a
shell-grammar regex can reliably infer dynamic option state. A second conditional scan for future
`pipefail` additions is valuable only if it is deliberately narrow and handles continuations;
stripping full-line comments alone will otherwise miss multiline pipelines and can match shell text
inside strings. Do not let that optional proactive lint replace the five-file assertion.

**Q4 — [Pass with controls].** One focused implementation commit is preferable to per-file commits:
these are one mechanical class and splitting multiplies review/merge churn. Before editing, capture
the per-file counts using the exact detector intended for the guard; afterwards require zero piped
variable-to-`grep -q` sites in each of the five and 37 corresponding here-string/file replacements.
Run the focused affected scripts, not the full gate: `gh308-frozen-twin-guard`,
`gh438-acceptance-recheck`, `gh284-p3-release-milestone`, `pdda-roadmap-coverage`,
`pdda-local-checks`, and the extended `gh460-pipe-buffer-sigpipe` guard. The mechanical failure mode
is not just a missed site: it is changing `&&`/`||` polarity, a continuation/redirection, grep flags,
or the trailing-newline meaning while keeping the source superficially similar.

**Q5 — [Pass after the above].** The scoped fix is proportionate; do not expand it to all 285
occurrences. The regression test should execute both the bad pipe form and the selected replacement
at a large payload, then statically enforce the agreed named-site scope. Record the supported Bash
invocation assumption beside the guard so a future sourced-library use is an intentional review
decision, not a rediscovery.

Handing back to claude-a for plan revision.
