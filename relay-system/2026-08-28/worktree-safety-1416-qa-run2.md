---
Goal: QA WORKTREE-SAFETY.md sections 14-16 (macOS recovery, audit trails, containment) — run 2
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

Read: `WORKTREE-SAFETY.md` — **823 lines, committed at `a7525a44`.** Run 1 of this QA read a stale
505-line copy because the content was uncommitted; if the file you can see does not contain a `## 14.`
heading, say so immediately and do not review further.

Run 1 did surface one real finding against that older copy, already fixed upstream: it had two
sections both numbered 13. Confirm the committed version does not.

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

## Reviewer findings — codex (changes requested)

**Verdict: not approved.** The new recovery/containment material belongs in this canonical guide and
the TOC is correct; `## 13.` appears once (`WORKTREE-SAFETY.md:510`) and §§14–16 are present.
However, the executable-looking examples have two safety-critical defects and several recovery
qualifications are needed.

1. **§16.3 `safe-rm` is unsafe as written.** `${@:#--i-mean-it}` is valid zsh array-pattern
filtering and does remove the sentinel, but the case at `WORKTREE-SAFETY.md:743-754` only detects
combined short-option words containing both `r` and `f`. It silently permits real BSD/macOS recursive
deletes such as `safe-rm -r target`, `safe-rm -R target`, and `safe-rm -r -f target`; the last has
each flag in a separate word. Thus it violates its own claim at `:740` and must not ship as a safety
wrapper. Gate any recursive option (including `-r`, `-R`, clusters, and `--recursive` if portability
is desired) while parsing options up to `--`; `rm -r` alone should absolutely require the
acknowledgement. macOS `/bin/rm` does not accept GNU `--recursive --force`, so that particular form
does not delete on this platform, but the wrapper still does not recognize it.

2. **§16.1 does not run on this repository's supported Python floor.** `Path.is_relative_to` was
added in Python 3.9, whereas the project declares Python 3.8+ (`README.md:192`), so the example at
`WORKTREE-SAFETY.md:709-714` raises `AttributeError` on a supported interpreter. Use a 3.8-compatible
`try: p.relative_to(root)` predicate or raise the documented floor. The core reasoning at `:718-721`
is otherwise correct: `resolve(strict=False)` resolves existing components/symlinks and still returns
a path for a missing leaf, and component-aware containment fixes the `Documents-backup` false accept.
Two more fixes are required: resolve `NEVER_DELETE` members before comparing them to resolved `p`
(`:706-712` currently compares canonical and possibly noncanonical Paths), and reject `p == root` for
each safe root. As written, deleting `~/agent-workspaces` or the entire `~/Documents/GH Repos` is
allowed because a root is relative to itself.

3. **The `eslogger` selector is only a partial audit, despite appearing complete.** The paths used
for the two handled cases are right: unlink target is `.event.unlink.target.path` and rename source
is `.event.rename.source.path` (`WORKTREE-SAFETY.md:668-671`). But `create` is subscribed and then
silently dropped because the selector has no `.event.create...` arm. Decide explicitly: remove
`create` when the purpose is deletion-only, or add a correct create/destination extractor and describe
the result as a broader filesystem audit. A rename *into* a watched root is also missed because only
its source is examined. Further, Apple explicitly says eslogger JSON is not a stable API; add a
version/schema caveat and recommend checking `eslogger --list-events` rather than presenting this
filter as durable telemetry. The stated root + Full Disk Access prerequisite at `:663-665` is correct.

4. **APFS/Time Machine command spellings are sound, but their availability is overstated.**
`tmutil listlocalsnapshots /`, `tmutil localsnapshot`, `sudo mount_apfs -s <snapshot> / /tmp/snap`,
`sudo umount`, both `log show` invocations, and `chflags uchg`/`nouchg` are correctly formed
(`WORKTREE-SAFETY.md:550-561`, `:608-613`, `:680-682`, `:725-728`). `mount_apfs_snapshot` is not the
macOS tool. But `tmutil localsnapshot` creates snapshots only for APFS volumes included in the Time
Machine backup; a machine without suitable Time Machine configuration may have none. Qualify the
absolute claim that macOS keeps automatic snapshots without a backup disk (`:545-548`) and make a
harness preflight tolerate/report unavailable snapshot support rather than treating it as a universal
precondition (`:684-687`).

5. **Git recovery needs a linked-worktree qualification.** The three Git commands at
`WORKTREE-SAFETY.md:581-588` are correctly formed. Reflogs and unreachable objects are nevertheless
retention-dependent, so “the reflog outlives branch deletion” should say *may* and direct readers to
act before expiry/pruning. More importantly, an “other worktree” is not an independent object store:
it helps only if its shared parent/common Git directory survived. A remote helps only for objects it
still retains (normally pushed/reachable work). Qualify the broad claim at `:576-577` accordingly.

6. **Recovery coverage misses this harness's two relevant non-Git stores.** Add a first-pass check
of `.tick/orphan-backups/` in a surviving checkout; the harness deliberately copies pre-revert content
there (`relay-automation/relay-turn-lib.sh:984-992`). Also say that ignored vendored `.xyz/` state has
no Git/ref-log/fsck recovery: `.xyz/` is ignored (`.gitignore:66-67`) and the vendor itself documents
that a destroyed relay thread there is gone (`relay-automation/xyz-vendor.sh:388-392`). These are
concrete failures squarely inside the guide's agent-workflow scope.

7. **Consistency/scope.** §§14–16 are appropriately scoped recovery and containment material for an
agent-driven Git safety guide; no section should be cut merely for being macOS-specific. Golden rules
9–10 accurately summarize the intended additions once findings 1, 2, and 4 are fixed. Separately,
the header points to `LICENSE` and `LICENSE-COMMERCIAL.md` (`WORKTREE-SAFETY.md:3`) while the footer
asserts Apache 2.0 (`:822`); that is a pre-existing but user-visible license contradiction worth
resolving, not preserving.

Verification: full document read plus command/API documentation review only; no project gate or tests
were run, per the reviewer-turn restriction.
