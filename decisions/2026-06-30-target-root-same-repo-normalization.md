---
title: Same-repo --target-root is a no-op — collapse RTL_ROOT to the caller's root (GH-51 [1-kernel])
date: 2026-06-30
status: Decided
gh_issue: 51
related:
  - relay-automation/relay-turn-lib.sh   # rtl_init RTL_ROOT routing
  - test/relay-target-root.sh            # regression (case 3)
  - decisions/2026-06-29-self-improvement-loop.md  # unrelated; nearby
supersedes: the swarm-preflight packet-gen workaround (don't EMIT --target-root for same-repo) — that
  stopped the planner producing the bad invocation; this fixes the kernel so a same-repo --target-root
  is correct even when passed by hand.
---

# Same-repo `--target-root` is a no-op (GH-51 [1-kernel])

**Decision:** In `relay-turn-lib.sh`'s `rtl_init`, when `RELAY_TARGET_ROOT` (the `--target-root` anchor,
GH-11) resolves to the **same git repo** as the caller's own root, **collapse `RTL_ROOT` to the caller's
root** (`$1`) — making a same-repo `--target-root` byte-for-byte identical to a no-`--target-root` turn.
The collapse is gated on `git -C "$RTL_ROOT" rev-parse --show-toplevel == git -C "$1" rev-parse
--show-toplevel` (non-empty), so a **genuine foreign** target (a different toplevel) is untouched and the
cross-repo path is unchanged.

**The bug it fixes:** `RTL_ROOT="${RELAY_TARGET_ROOT:-$1}"` left `RTL_ROOT` **relative** when the operator
(or `marathon-drive`) passed `--target-root .` for a same-repo lane. The allowlist is normalized to
repo-root-relative by stripping the `RTL_ROOT` prefix (`${a#"$RTL_ROOT"/}`), but `marathon-drive` passes
the relay file as an **absolute** path — and `${"/abs/.../phases/<id>/RELAY.md"#"./"}` strips nothing, so
the allowlisted relay file stayed absolute while `git status` in the worktree emits it relative. The relay
file then **failed its own off-lane match** and `rtl_worktree_end` reverted the entire turn (exit 6,
"off-lane edit"). This is the failure that forced the 2026-06-29 GH-37 marathon to be re-run with
`--target-root` **dropped** before it could converge (six runs; see [#51](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/51)).

**The bet:** The intended semantics of `--target-root <this repo>` is "act on this repo" — i.e., a no-op
relative to the default. Routing it through the cross-repo path (relative `RTL_ROOT`, prefix-strip that
can't match) was an accident of the GH-11 `RTL_ROOT="${RELAY_TARGET_ROOT:-$1}"` line never resolving the
value. Detecting "same repo as caller" by canonical git toplevel and collapsing to the caller's root is
sufficient and minimal: it restores the *exact* code path the no-`--target-root` case already exercises
(and which `relay-target-root.sh` "default path" already proves), so there is no new behavior to trust —
only the elimination of a wrong one.

**Mechanism (the invariant):**
- **Same-repo detection is canonical.** Both sides use `git rev-parse --show-toplevel`, so a relative
  `RTL_ROOT` (`.`), a `/var`→`/private/var` symlink, or a trailing slash all resolve to the same physical
  toplevel — the comparison is robust where a bare string compare was not.
- **Collapse, don't merely absolutize.** Setting `RTL_ROOT="$1"` (the caller's own root, which is how the
  relay file is already rooted in the no-target-root path) guarantees the prefix-strip matches, rather
  than absolutizing `RTL_ROOT` to a path that might still differ from how `$f` was computed.
- **Foreign roots untouched.** A different toplevel ⇒ no collapse ⇒ the existing cross-repo path runs
  exactly as before (`relay-target-root.sh` cases 1–2 unchanged).
- **Worktree / commit / enforce all follow.** Every later `git -C "$RTL_ROOT"` and `cp "$RTL_ROOT/$a"`
  now uses the absolute caller root for a same-repo lane, so the worktree base, copy-back, and file-scoped
  commit are consistent — no relative-CWD dependence.

**Backward compatibility:** No `--target-root` ⇒ `RELAY_TARGET_ROOT` unset ⇒ the new block is skipped
entirely (byte-identical). Foreign `--target-root` ⇒ toplevels differ ⇒ skipped. Only the previously
**broken** same-repo case changes — from exit-6 revert to a correct no-op turn.

**Rejected alternatives:**
- **Absolutize `RTL_ROOT` via `pwd -P` only** — fixes the relative case but can still mismatch `$f` if the
  relay-file root was computed without symlink resolution; collapsing to `$1` (the proven root) avoids the
  guesswork.
- **Fix it only in the planner** (don't emit `--target-root` for same-repo — already shipped, GH-51
  [1-packet-gen]) — necessary but not sufficient: a hand-typed or third-party `--target-root .` would
  still hit the kernel trap. Defense belongs in the kernel.
- **Re-relativize each allowlist entry against the worktree at check time** — larger, touches the hot
  off-lane loop, and unnecessary once `RTL_ROOT` is correct.

**Expected signal:** `test/relay-target-root.sh` case 3 — a same-repo `--target-root .` turn with an
absolute relay file COMMITS (relay-file + artifact edits land), and reverts the turn off-lane only when
the fix is disabled (verified: the assertion fails without the collapse).

**Reversibility:** **Easy.** One guarded block in `rtl_init`; remove it to restore the prior (buggy)
behavior. No schema/projection change.

**Revisit trigger:** a same-repo turn where the caller's root and the relay-file root are *legitimately*
different physical paths (e.g., a bind-mount alias) such that the toplevel compare misses — then the
collapse wouldn't fire and the old strip would resurface; that would need a per-entry canonicalization in
the off-lane loop. Not seen in practice (single-clone, single-toplevel).

## Caveats carried forward
- GH-51's remaining items are independent of this fix: [2] the brief template must forbid in-turn
  execution of fs-touching tests; [3] swarm-preflight should auto-include a changed artifact's tests in
  the allowlist; [5] marathon should reconcile/fresh-id a leaked tick token before re-seed. This decision
  closes [1-kernel] only.
