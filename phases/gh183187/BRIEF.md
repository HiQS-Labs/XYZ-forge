# GH-183 + GH-187: fix agy isolation-breach detector false positives

## Problem

`relay-automation/agy-turn.sh` (around line 237) and `relay-automation/consult.sh` (around line
208) both do a post-hoc containment check: after an isolated-worktree agy turn, grep the raw agy
transcript for a literal substring match of the real repo root path (`$ROOT`). If found, the turn
is failed as an "isolation breach" (agy escaped its worktree and grounded against the real repo).

This produces **false positives** — confirmed twice in real use, not synthetically:

- **GH-183**: the harness's own prompt template (`rtl_turn_prompt` in `relay-turn-lib.sh`) mandates
  agy run a tick command containing `TICK_REPO_ROOT="$ROOT"`. When agy's response narrates having
  run that exact command (ordinary LLM behavior — summarizing what it did), the substring scan
  matches and fails a fully legitimate, in-bounds turn.
- **GH-187**: a second, distinct trigger shape — agy's end-of-turn summary cited a file it edited
  using a markdown link, `[file](file:///.../xyz-3-agents-swarm/...)`. The `file://` URI contains
  `$ROOT` as a citation, not an escape. This fired live during a real marathon lane (GH-186) and
  aborted the whole run (`marathon-drive.sh` exit 2), requiring manual recovery of a turn that
  actually succeeded.

`agy-turn.sh` already excludes `[trace]` lines before scanning (`grep -v '^\[trace\] '`).
`consult.sh`'s equivalent check has **no filtering at all** — it's the more fragile of the two.

## Fix direction (broader than a third one-off allowlist entry)

GH-187 explicitly argues that allowlisting individual line shapes is whack-a-mole — this is the
second distinct trigger found in two days of real use, and a third will surface eventually. Two
acceptable approaches, in order of preference:

1. **Prefer the existing filesystem-based check over the transcript-text scan.** Containment is
   already verified from what agy actually wrote to disk — `rtl_worktree_end` sets
   `RTL_WT_OFFLANE=1` if agy made any off-lane creation/rename/edit in the isolated worktree, and
   that check already fails the turn (exit 6) independently of the transcript scan. The transcript
   substring scan is redundant with, and less reliable than, that filesystem check. If it can be
   removed (or demoted to a non-fatal warning) without weakening real containment, that is the
   cleanest fix.
2. **If the transcript scan is kept as defense-in-depth**, broaden what gets stripped before the
   `$ROOT` check runs, instead of allowlisting one more literal line format:
   - `[trace]` lines (already done)
   - the deterministic tick-command line shape printed by `rtl_turn_prompt`
     (`TICK_REPO_ROOT="..."` invocations)
   - markdown link targets (`](...)`) and `file://` URIs referencing `$ROOT`
   Apply the same broadened filtering to **both** `agy-turn.sh` and `consult.sh` — right now only
   `agy-turn.sh` has any filtering, so `consult.sh` needs to gain parity, not just a bigger
   allowlist.

Use your judgment on which of the two to implement — pick whichever is the smaller, more
defensible diff, but don't leave `consult.sh` with zero filtering if you keep the transcript scan
approach there.

## Explicitly out of scope

- Do not touch `RTL_WT_OFFLANE` / the worktree copy-back containment check itself — that stays as
  the authoritative filesystem-based guard regardless of which option you pick for the transcript
  scan.
- Do not weaken real breach detection — a transcript that cites `$ROOT` outside of a tick-command
  narration or a markdown citation of an on-lane file should still fail the turn.

## Definition of done

- [ ] `agy-turn.sh`'s isolation-breach check no longer false-positives on the GH-183 tick-command
      narration case.
- [ ] The same check (or its removal) no longer false-positives on the GH-187 markdown-citation
      case.
- [ ] `consult.sh`'s equivalent check is no more fragile than `agy-turn.sh`'s (same filtering, or
      also relies on a filesystem-based check).
- [ ] `test/agy-turn.sh` gains regression coverage for both false-positive shapes (tick-command
      narration, markdown `file://` citation) using realistic mock transcripts, alongside the
      existing genuine-breach case (which must still fail).
- [ ] A genuine isolation breach (agy transcript citing `$ROOT` in a context that is NOT a
      tick-command narration or file citation) still fails the turn — do not just delete the check
      without proving the filesystem-based guard alone still catches a real breach.
- [ ] `bash validate.sh` green.

## References

- GH-183: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/183
- GH-187: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/187
- GH-178 (parent doc): PROJECT/2-WORKING/GH-178-EPISTEMIC-RECONCILIATION-HARDENING.md
