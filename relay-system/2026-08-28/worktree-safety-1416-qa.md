---
Goal: QA WORKTREE-SAFETY.md sections 14-16 (macOS recovery, audit trails, containment)
Date: 2026-08-28
NEXT: Reviewer
STATUS: Open
---

# Context

`WORKTREE-SAFETY.md` was a Git-only guide (sections 1-13, "Safety model", "Golden rules", "See also").
Three new sections were just appended, adapting operator-supplied macOS material into the doc's existing
voice:

- **§14 Recovering a checkout that is already gone** — APFS/Time Machine snapshots, Trash and sync
  providers, Git-side recovery (remote / sibling clone / reflog / fsck), shell history, unified logging.
- **§15 Audit trails that make the next incident solvable** — zsh `EXTENDED_HISTORY` + `INC_APPEND_HISTORY`,
  an `fsync`ed agent action log, `eslogger` filesystem events, `tmutil localsnapshot` before destructive runs.
- **§16 Containment: limiting blast radius outside Git** — resolved-path safe-root checks, `chflags uchg`,
  a `safe-rm` wrapper, dry-run discipline, container/VM/separate-user isolation.

The TOC, two new Golden rules (9 and 10), and six new "See also" entries were updated to match.

Read the file in full — sections 1-13 as well as 14-16, because several claims in the new sections
deliberately cross-reference the old ones (§3 trap paths, §7 clone deletion, §12 disposable full clone).

Read: `WORKTREE-SAFETY.md`

# Questions

Answer each one specifically. Cite `file:line` wherever you disagree with a claim or find an error.

1. **Command accuracy — macOS.** Every shell invocation in §14 and §15 must be real and correctly
   spelled for macOS 13+. Specifically verify: `tmutil listlocalsnapshots /`, `tmutil localsnapshot`,
   `sudo mount_apfs -s <snapshot> / /tmp/snap` (the doc explicitly warns that `mount_apfs_snapshot` does
   NOT exist — is that correct?), `log show --last 3h --predicate ...`, `eslogger unlink rename create`,
   and `chflags uchg`/`nouchg`. Flag any flag, subcommand, or argument order that is wrong, deprecated,
   or that requires privileges/TCC grants the doc does not mention.

2. **The `eslogger` jq filter.** §15.3 pipes eslogger JSON through
   `jq -c 'select(.event.unlink.target.path // .event.rename.source.path // "" | test(...))'`.
   Are those the correct JSON paths for Endpoint Security `unlink` and `rename` events as `eslogger`
   emits them? Note the filter names three event types on the command line (`unlink rename create`) but
   only handles two in the selector — is `create` silently dropped, and if so is that a defect or
   acceptable?

3. **The `safe-rm` wrapper (§16.3) — does it actually work?** It is `#!/bin/zsh` and uses
   `"${@:#--i-mean-it}"` to strip the sentinel. Verify: (a) the zsh `${array:#pattern}` substitution does
   what the comment claims on `$@`; (b) the `case` patterns `-*r*f*|-*f*r*` actually catch the real-world
   forms (`rm -rf`, `rm -fr`, `rm -r -f`, `rm --recursive --force`); (c) whether a `rm -r` without `-f`
   should also be gated. Say plainly whether this script is safe to ship as written or needs a fix.

4. **The safe-root check (§16.1).** It claims `Path.is_relative_to` plus `resolve()` beats
   `str.startswith`, citing `/Users/me/Documents-backup` as the false accept. Is the reasoning correct,
   is `is_relative_to` available in the Python versions this repo targets, and does `resolve()` on a
   non-existent path behave as the code assumes? Is `NEVER_DELETE` membership testing by `in` on a set of
   `Path` objects sound given `p` is resolved but the set members are not?

5. **Accuracy of the Git recovery claims (§14.3).** Verify `git ls-remote origin 'refs/heads/*'`,
   `git --git-dir=<path> reflog --date=iso`, and `git --git-dir=<path> fsck --lost-found` are correct for
   the stated purpose. Is the claim that "a destroyed working tree is not destroyed history if any other
   clone, worktree, or remote still has the objects" accurate as stated, or does it need qualifying?

6. **Comprehensiveness.** For a guide whose stated scope is now "prevent destructive checkout and
   repository-state failures in agent-driven Git workflows," what is *missing* from §14-16? Name concrete
   gaps only — do not pad. Consider at minimum: whether recovery guidance should cover the
   `.tick/orphan-backups/` path this harness already writes, and whether §16 should mention this repo's
   own vendored `.xyz/` being gitignored (state lost there has no reflog behind it).

7. **Over-engineering / scope drift.** Is any of §14-16 generic macOS advice that does not earn its place
   in a Git safety guide? The operator explicitly chose ONE canonical doc over fragmenting into a second
   file, so the bar is "does this belong here," not "is it useful in general." Flag anything that should
   be cut or compressed.

8. **Internal consistency.** Do §14-16 contradict anything in §1-13 or the Golden rules? Do the two new
   Golden rules (9, 10) accurately summarize the new sections? Does the TOC match the headings? Note also
   that the file has a license line in the header (`License: See LICENSE and LICENSE-COMMERCIAL.md`) and a
   different one in the footer (`Licensed under: Apache 2.0`) — is that a pre-existing defect worth flagging?

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Be concrete and cite
`file:line` where you disagree with a specific claim.

Write your verdict below and change `STATUS:` to `Approved` if it passes, or leave it `Open` with your
findings if changes are needed.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex review — changes needed

**Verdict: not approved.** The checked-out `WORKTREE-SAFETY.md` ends at line 505 and contains no
§14, §15, or §16, no updated TOC, no Golden Rules 9–10, and no additional See Also entries. The
macOS command, `eslogger` JSON-path, `safe-rm`, and safe-root-check material described in the relay
context is therefore absent and cannot be reviewed or approved from this worktree.

Concrete findings in the file that is present:

1. `WORKTREE-SAFETY.md:426` already defines §13, then `WORKTREE-SAFETY.md:443` defines a second
   §13. This is an internal-structure error independent of the missing §§14–16; renumber/consolidate
   before adding the proposed new sections.
2. `WORKTREE-SAFETY.md:7-8` still scopes the document to Git-worktree scripting, rather than the
   broader agent-driven checkout/repository-state scope asserted in this relay. Update scope only if
   the new containment/recovery material is actually added.
3. The relay context says the header license is `See LICENSE and LICENSE-COMMERCIAL.md` while the
   footer says Apache 2.0. In the checked-out document, both header (`WORKTREE-SAFETY.md:4`) and
   footer (`WORKTREE-SAFETY.md:504`) instead say Apache 2.0, so that reported contradiction is not
   present here.

Please restore/apply the intended §§14–16 content, TOC, Golden Rules 9–10, and See Also changes in
the reviewable worktree, then return this relay for the requested command-level QA.
