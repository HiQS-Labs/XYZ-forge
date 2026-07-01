---
title: Vendored `.xyz/` harness copy + locator preference, staleness = warn-loudly-continue (GH-49)
date: 2026-06-30
status: Decided
gh_issue: 49
related:
  - skills/relay-xyz/find-harness.sh                   # the locator gaining a .xyz/ preference branch
  - relay-automation/relay-turn-lib.sh                 # the containment kernel a vendored copy forks
  - skills/relay-automation/make-pkg.sh                # the 16-file manifest the snapshot reuses
  - PROJECT/3-COMPLETED/GH-62-XYZ-INSTALL-REGISTRY.md  # the registry the copy registers into
  - decisions/2026-06-30-target-root-same-repo-normalization.md  # nearby locator/containment change
---

# Vendored `.xyz/` copy + locator preference (GH-49)

**Decision:** Add an **opt-in** `vendor` command that snapshots the curated harness set (the 16-file
`make-pkg.sh` manifest + `bin/tick` + `src/*.js`) into a **git-ignored `.xyz/`** in a foreign repo,
pinned + version-stamped, and teach `find-harness.sh` to **prefer `.xyz/` over a live harness clone**
when present in the repo you are standing in. When the snapshot is **provably behind a reachable**
harness, the locator **warns loudly but does not block** (operator decision 2026-06-30). When no
harness is reachable — the WIP/offline case this exists for — it runs from `.xyz/` silently.

**The problem it solves:** Driving a foreign repo (`--target-root`) couples to a *live* harness clone.
The operator holds off relays when that clone is mid-WIP (uncommitted/half-edited scripts) or
unavailable (other machine / not checked out), because a relay would run against whatever half-state
the harness is in. A pinned local snapshot decouples the foreign-repo relay from the harness clone's
live state.

**The risk this accepts (named, not hidden):** a vendored copy **forks the containment kernel**
(`relay-turn-lib.sh`), whose safety rests on a single source of truth. A foreign repo could run an
**old, buggy kernel** (e.g. a copy taken before the 2026-06-29 #14 mid-turn-commit fix) after the
harness has fixed it. This is a *staleness/governance* risk, not a blast-radius one — the copy is
git-ignored, opt-in, deletable, and writes nothing outside the foreign repo + `$HOME` registry.

**The staleness bet (the load-bearing decision): warn loudly, continue — do NOT refuse.**
- The entire purpose of `.xyz/` is to run *when the live harness is WIP or absent*. In exactly that
  case there is **nothing to compare against**, so a refuse-on-stale gate would either (a) do nothing
  (no reachable harness → no comparison → nothing to refuse) or (b) block the operator precisely when
  they deliberately vendored to avoid the live clone. A hard refuse buys little and blocks the use case.
- So: compare only when a harness **is** reachable; if `.xyz/VERSION`'s source commit is behind it,
  emit a loud multi-line banner (vendored SHA, live SHA, `xyz-sync --update` remedy) and **proceed**.
  The operator decides (GUIDING #8); the copy is explicitly labeled a fallback.
- Mitigations that carry the containment weight instead of a block: (1) the version stamp makes drift
  *visible* at every resolution and in `--check`; (2) `xyz-sync --update` makes refresh one command;
  (3) the session-end reminder + registry make copies discoverable and deletable so they don't rot
  silently; (4) `.xyz/` is git-ignored and opt-in, so the default (no-`.xyz/`) path — the one every
  existing relay uses — is **byte-for-byte unchanged** and keeps the single-source-of-truth kernel.

**Mechanism (the invariants):**
- **Default path untouched.** The `.xyz/` branch in `find-harness.sh` is taken *only* when
  `<cwd-repo>/.xyz/relay-automation/relay-drive.sh` exists. No `.xyz/` ⇒ the resolver runs exactly as
  today (regression-proven). This is the same "additive branch, prove the default is byte-identical"
  discipline as the GH-51 same-repo `--target-root` collapse.
- **Explicit override still wins.** Order is env (`XYZ_HARNESS`/`XYZ_REPO_ROOT`) → `.xyz/` → current
  git-repo harness → script-relative. An operator who sets `XYZ_HARNESS` to a live clone overrides a
  present `.xyz/` (escape hatch to force the live kernel).
- **Manifest is single-source.** The snapshot's file list is *derived from* `make-pkg.sh`, not a second
  hand-maintained list — so the vendored set can't drift from the packaged set.
- **Registry-tracked, never committed.** Each vendored copy registers a machine-local row (GH-62
  registry, `$HOME`, git-ignored) marked vendored, so `xyz-sync` can update/delete it. A registry
  failure never fails the vendor (fail-open, matching GH-62).

**Rejected alternatives:**
- **Refuse when stale (hard containment stop).** Strongest on paper, but blocks the exact WIP/offline
  case `.xyz/` exists for, and can't even fire when no harness is reachable. Rejected in favor of
  warn-loudly-continue + visible drift + one-command refresh. (Operator chose this 2026-06-30.)
- **Refuse-with-one-flag-override.** Considered; the override reduces to warn-continue in practice while
  adding a flag and a failure mode. The operator picked plain warn-continue.
- **No vendoring — always require a live clone.** The status quo; it's exactly what makes the operator
  hold off relays on WIP repos. Rejected — that's the problem.
- **Symlink into a live clone instead of a snapshot.** Doesn't decouple from the clone's live state
  (the whole point) and breaks when the clone moves / is on another machine.

**Backward compatibility:** No `.xyz/` in the repo ⇒ the new locator branch is skipped entirely
(byte-identical resolution). `vendor` is a new opt-in command; nothing auto-vendors. `.xyz/` is
git-ignored so it can never leak into the (eventually public) repo.

**Reversibility:** **Easy.** Delete `.xyz/` (or `xyz-sync --delete`); remove the additive locator
branch to restore prior resolution. No schema/projection change; the registry row is machine-local.

**Revisit trigger:** if a stale vendored kernel ever causes a real containment miss in the field
(an old `relay-turn-lib.sh` failing to contain a turn that the current kernel would have), revisit the
posture — escalate warn→refuse-with-override, or add a max-staleness hard cap. Not seen yet; the bet is
that visible drift + one-command refresh + delete-reminder keeps copies fresh without a block.
