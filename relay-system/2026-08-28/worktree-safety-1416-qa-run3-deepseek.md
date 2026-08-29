---
Goal: QA WORKTREE-SAFETY.md 14-16 — adversarial re-check of the fixed examples (deepseek v4 pro)
Date: 2026-08-28
NEXT: Reviewer
STATUS: Open
---

# Your task

**Write your review into THIS file first, then stop.** A previous attempt on this thread read
everything, announced "now I'll write my comprehensive review," and ran out of turn before writing
anything. Draft your answer as you go rather than saving it for the end.

Read `WORKTREE-SAFETY.md` §16.1 and §16.3 only (roughly lines 690-770). Do not review the whole file.

Two code examples in it were just rewritten to fix defects. Your job is to attack the *fixed* versions.

## §16.3 — the `safe-rm` zsh wrapper

It claims to gate every recursive delete behind `--i-mean-it`. Find an invocation that deletes
recursively but is **not** gated, or state plainly that you could not. Consider at minimum:

- `-fR`, `-Rf`, and other letter orders and clusters
- a file literally named `-r` or `-rf`, before and after `--`
- whether `exec /bin/rm "${@:#--i-mean-it}"` can drop or mangle an argument that legitimately
  equals the sentinel string (e.g. `rm --i-mean-it` where a *file* has that name)
- whether `set -euo pipefail` under zsh behaves as the author assumes

## §16.1 — the `assert_deletable` / `_within` Python check

It claims to refuse anything outside `SAFE_ROOTS`, refuse the roots themselves, and work on Python 3.8.
Find an input that gets authorized but should be refused, or state plainly that you could not. Consider:

- a `SAFE_ROOTS` entry that is itself a symlink
- a path containing `..` components
- TOCTOU: the gap between `resolve()` and the actual delete
- `Path("/")` and `NEVER_DELETE` handling
- whether `_within` is genuinely 3.8-compatible

## Output format

For each of the two, write:

```
### §16.3 safe-rm — BROKEN | HOLDS
<one paragraph. If BROKEN, give the exact invocation and why it slips through.>

### §16.1 assert_deletable — BROKEN | HOLDS
<one paragraph. If BROKEN, give the exact input and why it is authorized.>
```

Cite `WORKTREE-SAFETY.md:<line>` for anything you claim. Then set `STATUS:` to `Approved` if both
hold, or leave it `Open` if either is broken.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (deepseek)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Review (deepseek)

### §16.3 safe-rm — HOLDS

I could not find an invocation that deletes recursively but is ungated. The `-*[rR]*)` glob in the case
statement (line 830) correctly catches every short-option cluster containing `r` or `R` (`-rf`, `-fr`,
`-Rf`, `-fR`, `-Rv`, bare `-r` and `-R`, every letter order). The `(( end_of_opts )) && continue` guard
at line 825 stops scanning after `--`, so a file literally named `-rf` after the separator never trips
the gate — correct, because `rm -- -rf` deletes one file, not a tree. The `${@:#--i-mean-it}` zsh
expansion (line 839) correctly strips only the sentinel argument while preserving all others; if a file
were literally named `--i-mean-it` it would be silently dropped, causing a false-negative (file
survives, not a gate bypass). The `set -u` in line 820 is semantically wrong for zsh — in zsh, `-u`
enables the `UNSET` option (the default), which is the *opposite* of bash's nounset. However, the
script accesses no variables that could be unset, so this creates no bypass opportunity in practice.
The gate is on `-r`/`-R` alone (line 842–846 documents the previous fix), which is the correct
semantic: any recursive delete needs the acknowledgement, whether or not `-f` is present.

### §16.1 assert_deletable — BROKEN

The primary gap is **TOCTOU** (time-of-check-to-time-of-use): `resolve()` at line 779 creates a
snapshot at the moment of validation, but the actual delete happens after `assert_deletable` returns.
An adversary who can swap a symlink target between the check and the operation can redirect the delete
to a path outside `SAFE_ROOTS`. For example: `~/agent-workspaces/link` resolves to
`~/agent-workspaces/real-project` (passes `_within`). If that symlink is then retargeted to
`~/Documents/secret` before the caller runs `path.unlink()` or `shutil.rmtree(path)`, the delete hits
the protected location. The document does not acknowledge this gap at all, unlike the three previous
defects it openly discusses (lines 787–798). Symlink-resolution is correct on both sides (line 780 vs
line 782), `..` normalization is handled by `resolve()`, `_within` rejects `child == parent` (line
770–771) and works on Python 3.8 via `relative_to()` (available since 3.4), and `NEVER_DELETE`
includes `Path("/")` correctly. The TOCTOU gap is the sole remaining structural weakness in the
assert_deletable guard.

**STATUS: Open**
