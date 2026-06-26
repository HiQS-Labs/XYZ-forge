---
title: agy turn edits ROOT directly under RELAY_WORKTREE_ISOLATION=1 — worktree copy-back silently overwrites output
status: Fixed 2026-06-26 — deterministic repro + library fix landed; validate.sh 47/47
created: 2026-06-25
updated: 2026-06-25
owner: noelsaw1
branch: main
gh_issue: 22
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/22
track: standalone bug fix (relay-turn-lib.sh / agy-turn.sh)
related:
  - relay-automation/agy-turn.sh
  - relay-automation/relay-turn-lib.sh
  - relay-automation/relay-drive.sh
  - PROJECT/2-WORKING/RELAY-CONTAINMENT-HARDENING.md
non_goals:
  - Changing the worktree isolation model for codex-turn.sh (different failure mode — exit 6 containment, not silent data loss)
  - Disabling worktree isolation by default (the safety benefit is real; fix the path, not the feature)
---

## Progress

| Most recently completed | What's next |
|---|---|
| **2026-06-26 — FIXED.** The earlier same-repo repro was a false negative: its stub wrote *inside the worktree*, so it never modelled the real failure. Real agy (and the existing `agy-turn.sh` test stub) writes the relay file via its **absolute ROOT path**, which `rtl_worktree_end` then overwrote with the stale, unmodified worktree seed. Reproduced deterministically (`agy-turn.sh` test, worktree-iso ON + absolute-ROOT write → output lost), fixed in `relay-turn-lib.sh`, and the same suite + `validate.sh` (47/47) now pass. See **Resolution** below. | Optional: one live agy relay re-run under `RELAY_WORKTREE_ISOLATION=1` as belt-and-suspenders, then close #22. |
| **2026-06-25 (later) — root-cause hypothesis DISPROVEN for same-repo; trigger re-scoped to cross-repo.** A deterministic repro (below) shows the documented mechanism does NOT hold in same-repo mode. **Reproduce the cross-repo case before any fix.** | (superseded by the row above — the same-repo case DOES reproduce; the prior repro's stub wrote the worktree, not ROOT) |
| Bug first seen 2026-06-25 during GH-21 quality gate relay. Original hypothesis: agy edits ROOT via absolute path in prompt; `rtl_worktree_end` copies stale worktree copy back over ROOT edits. Workaround `RELAY_WORKTREE_ISOLATION=0` (confirmed effective). | (superseded by the row above) |

## Verification log (2026-06-25, debug-mantra)

- **Code reading contradicts the original hypothesis.** `rtl_turn_prompt` ([relay-turn-lib.sh:219](../../relay-automation/relay-turn-lib.sh#L219)) already emits a **ROOT-relative** relay path (`f_rel="${f#"$root/"}"`), and `rtl_init` ([relay-turn-lib.sh:81](../../relay-automation/relay-turn-lib.sh#L81)) already **normalizes `RTL_ALLOW` to ROOT-relative**. So "rewrite the absolute path to relative in `agy-turn.sh`" (Option A) is *already effectively done* for the same-repo case.
- **Deterministic same-repo repro → bug does NOT reproduce.** A throwaway git repo + the real lib functions + a stub editor writing the relay file inside the worktree: with `RELAY_FILE` passed **absolute** AND passed **ROOT-relative**, `rtl_worktree_end` copy-back **PROPAGATED** the edit to ROOT both times (no loss). (Repro harness retained in session scratch; rerun via `bash` not `zsh` — `zsh` mangles `read -a` and PATH.)
- **Re-scoped hypothesis (UNCONFIRMED — needs a cross-repo repro):** the loss triggers in **cross-repo mode** (`RELAY_TARGET_ROOT` set ⇒ `RTL_ROOT`=foreign target, but the relay file lives in the **harness**, not under `RTL_ROOT`). Then `${f#"$root/"}` does **not** strip (prefix mismatch) ⇒ the prompt path stays **absolute** ⇒ agy writes the harness file directly (outside the worktree) AND copy-back is keyed on the wrong root. The GH-21 origin run's exact invocation (was `--target-root` involved?) is needed to confirm.
- **Impact on the WPCC TS-lite dogfood:** that run **is** cross-repo (`--target-root WP-Code-Check`, relay thread in the harness), so it is squarely in the suspected-trigger zone — this fix is correctly on its critical path.

## Resolution (2026-06-26)

**Confirmed root cause.** `rtl_worktree_end` copied the **entire allowlist** from the worktree back
to ROOT *unconditionally*. `rtl_worktree_begin` seeds the worktree from ROOT's working tree, so an
allowlisted file the turn never touched in the worktree is byte-identical to its seed. When the agent
instead writes ROOT directly — which real agy does: it resolves the relay file to its **absolute ROOT
path** even with `CWD`=worktree — the worktree copy stays at the seed, and the copy-back overwrites
agy's ROOT edit with that stale seed. `rtl_enforce` then sees no change → exit 0, no commit, blank
relay file. This reproduces in **same-repo** mode (no `--target-root` needed); the earlier same-repo
repro missed it only because its stub wrote *inside the worktree* rather than via the absolute path.

**Fix (`relay-turn-lib.sh`).** Copy back **only the paths the turn actually modified in the worktree**:
- `_rtl_sig <path>` — a content signature (`git hash-object` for files, a sorted recursive hash for
  dirs, `ABSENT` for missing).
- `rtl_worktree_begin` records each seeded allowlist path's signature to a sidecar file `${wt}.seedsig`
  (a sidecar, not a global, because the caller runs `wt="$(rtl_worktree_begin)"` in a subshell whose
  globals are lost; and not inside the worktree, where it would read as an off-lane untracked file).
- `rtl_worktree_end` re-reads the sidecar and **skips** any path whose worktree signature is unchanged,
  leaving ROOT's copy intact so a ROOT-direct edit survives for `rtl_enforce` to commit. Genuine
  worktree edits/creates/deletes still propagate (signature differs). Off-lane ROOT writes remain
  contained by `rtl_enforce` (revert + exit 6) as before.

**Why not Option A (prompt-relative path).** The prompt already emits a ROOT-relative path
(`f_rel`); agy ignores it and uses the absolute ROOT path regardless, so a prompt-layer rewrite can't
hold. The teardown fix is model-agnostic — it protects ROOT-direct writes from any turn-taker.

**Verification.** `test/agy-turn.sh` case (10) drives the stub with `RELAY_WORKTREE_ISOLATION=1` and
the absolute-ROOT write: RED before the fix (output lost), GREEN after (block preserved + committed).
Full `validate.sh` → **47/47**.

## Problem

When `relay-drive.sh` drives an agy turn with `RELAY_WORKTREE_ISOLATION=1` (the default for driven runs), the headless agy process edits the relay file via the **absolute path** embedded in the turn prompt. This path points to ROOT, not the throwaway worktree. At teardown, `rtl_worktree_end` copies allowlisted files from the worktree back to ROOT — but since the worktree copy was never written, the stale empty worktree version overwrites agy's ROOT edits. Output is silently discarded. Exit code is 0 (or the round-cap's exit 4) — no error surfaces.

### Symptom

```
agy-turn: worktree isolation ON (/tmp/rtl-wt.aPHBam)
agy-turn: committed agy turn (file-scoped, no push)
relay-drive: round cap (1) exceeded (STATUS: Open, token actor: none)
```

The task registers as `done` in `.tick/` but the relay file on disk has no output block.

### Root cause

`rtl_worktree_end` in `relay-turn-lib.sh` copies allowlisted files **from worktree → ROOT**. When the agent edits via the absolute path in the prompt, it writes ROOT directly. The worktree copy is untouched. Copy-back direction is wrong for this case.

### Workaround

```bash
RELAY_WORKTREE_ISOLATION=0 AGY_AGENT=agy ... relay-drive.sh ...
```

## Fix options

### Option A — prompt-layer fix (preferred)

In `agy-turn.sh`, before the `agy -p "$prompt"` call, rewrite any absolute relay file path in the prompt to its CWD-relative equivalent inside the worktree. Since the worktree is set as CWD (`cwd_wrap`), a relative path ensures the agent writes the worktree copy, not ROOT. `rtl_worktree_end` then copies the correct file back.

**What done looks like:** an `agy-turn.sh` change that rewrites the `RELAY_FILE` path in the prompt when `RELAY_WORKTREE_ISOLATION=1` is active. `rtl_worktree_end` copy-back then works as designed.

### Option B — worktree-teardown sync

In `rtl_worktree_end`, before copying worktree → ROOT, first sync allowlisted files FROM ROOT into the worktree. Any ROOT-direct edits are captured; the copy-back is then idempotent.

**Downside:** makes `rtl_worktree_end` bidirectional and more complex; harder to reason about containment.

### Option C — doc-only (interim)

Document `RELAY_WORKTREE_ISOLATION=0` as required for agy-turn.sh driven runs until the path issue is fixed. Already captured in `relay-xyz/SKILL.md` and `agy-turn.sh` header.

## Relationship to other issues

- **GH-17** — macOS case-sensitivity triggers exit 6 from the same containment path; different failure mode (tracked edit reverted vs. untracked write lost)
- **GH-13 / GH-14** — containment hardening siblings; this is a containment *interaction* bug, not a new containment gap
- **RELAY-CONTAINMENT-HARDENING.md** — closest active doc; this bug may warrant a phase addition there or a standalone fix PR

## Origin

Surfaced during the GH-21 relay quality gate doc review (2026-06-25). The first agy relay drive (task `RELAY-gh21-plan-qa-agy`) completed with `VERDICT: PASS` in the agy log but the relay file was blank on disk. A second drive with `RELAY_WORKTREE_ISOLATION=0` succeeded cleanly.
