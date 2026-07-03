---
title: Marathon Plan 2026-07-04 — low-risk blend (Fable GH-110 + Gemini GH-109 Phase 1)
status: Active (2-WORKING)
created: 2026-07-04
updated: 2026-07-04
owner: noel
branch: main
doc_type: project
source: PROJECT/1-INBOX/GH-110-SHELLCHECK-VENDOR-FIXES.md, PROJECT/1-INBOX/GH-109-GEMINI-FEEDBACK.md
generated_by: hand (pre-flighted from audit findings)
roadmap_exempt: true
goal: >
  Three collision-free Phase-1 lanes drawn from the Fable 5 (GH-110) and Gemini (GH-109)
  audit findings. All low-risk, all disjoint write-sets — wave-packable in parallel.
  Assertion fix from Fable item 1 already landed in 84ff078; three items remain open.
---

<!-- Pre-flighted from GH-109 + GH-110 Phase 1 findings. Write-sets verified disjoint below.
     Edit the source docs (1-INBOX/GH-109*, 1-INBOX/GH-110*), not this plan. -->

# Marathon Plan 2026-07-04 — low-risk Fable + Gemini blend

> Scoped to Phase 1 items from the two external audit issues. Execution detail lives in
> [GH-110-SHELLCHECK-VENDOR-FIXES.md](../1-INBOX/GH-110-SHELLCHECK-VENDOR-FIXES.md) and
> [GH-109-GEMINI-FEEDBACK.md](../1-INBOX/GH-109-GEMINI-FEEDBACK.md).
> **Note:** Fable's item 1 (broken assertion at `test/xyz-vendor.sh:140`) already landed in
> `84ff078` — excluded from this plan.

## Status

| What was just completed | What's next |
|---|---|
| Plan pre-flighted 2026-07-04 from audit findings; write-sets verified disjoint; all 3 lanes in Wave 1. | **Wave 1 (all parallel):** Lane A ‖ Lane B ‖ Lane C. Fire each via `swarm-preflight → marathon-drive` scoped by `ALLOW_PATHS`. |

## The one safety rule

Two lanes are safe to run concurrently **iff their write-sets are disjoint.** No kernel files
(`relay-turn-lib.sh`, `bin/tick`, `relay-drive.sh`) are touched in this plan.

## Write-set collision map

| Lane | Files written | Zone | Parallel-safe? |
|---|---|---|---|
| A — vendor payload cleanup | `relay-automation/xyz-vendor.sh`, `skills/swe/SKILL.md` | independent | ✅ |
| B — tmp UID isolation | `relay-automation/hooks/relay-xyz-guard.sh` | independent | ✅ |
| C — watchdog leak fix | `relay-automation/consult.sh` | shim | ✅ |

All write-sets are disjoint. No kernel zone entries. **All three run in Wave 1.**

## Per-lane scoring

| Lane | cx | risk | eff | zone | score | wave |
|---|---|---|---|---|---|---|
| A — vendor payload cleanup | 1 | 1 | 1 | independent | 5 | 1 |
| B — tmp UID isolation | 1 | 1 | 1 | independent | 5 | 1 |
| C — watchdog orphaned-sleep | 2 | 2 | 2 | shim | 11 | 1 |

## Recommended wave

**Wave 1:** Lane A ‖ Lane B ‖ Lane C

- Lane A → `marathon/gh-110-vendor-payload-cleanup-2026-07-04`
- Lane B → `marathon/gh-109-tmp-uid-isolation-2026-07-04`
- Lane C → `marathon/gh-109-watchdog-orphaned-sleep-2026-07-04`

---

## Lane detail

### Lane A — Vendor payload cleanup (Fable GH-110 P1)

**Source:** [GH-110 Phase 1](../1-INBOX/GH-110-SHELLCHECK-VENDOR-FIXES.md#phase-1--quick-fixes-~1-hr)
**Effort:** ~30 min · **Risk:** 1

**ALLOW_PATHS:** `relay-automation/xyz-vendor.sh skills/swe/SKILL.md`

**Prompt for agent:**

> Two small cleanups in the vendor pipeline, from the Fable 5 audit (GH-110 Phase 1):
>
> 1. **Exclude `.DS_Store` from `materialize_vendor`** in `relay-automation/xyz-vendor.sh`.
>    The function uses `cp -Rp "$HARNESS_ROOT/$d/." "$STAGE_DIR/$d/"` for each dir in
>    `VENDOR_DIRS`. Add a follow-up `find "$STAGE_DIR" -name '.DS_Store' -delete` after the
>    copy loop (or before `mv "$STAGE_DIR" "$VENDOR_DIR"`). This is the safest portable
>    approach on macOS/BSD — no rsync dependency, works with the existing `cp -Rp` pattern.
>
> 2. **Delete `skills/swe/SKILL.md`** — currently 0 bytes. Either remove the file (if the
>    `skills/swe/` skill is unimplemented) or replace it with a one-line stub directive so
>    consumers know what the skill does. Check whether `skills/swe/` has any other files first;
>    if it is genuinely empty, remove the whole directory.
>
> Gate: `./validate.sh` must stay green. Confirm a fresh `materialize_vendor` call into a
> temp dir contains no `.DS_Store` files after the fix.

---

### Lane B — `/tmp` UID isolation in relay-xyz-guard.sh (Gemini GH-109 P1b)

**Source:** [GH-109 Phase 1 / 1b](../1-INBOX/GH-109-GEMINI-FEEDBACK.md#1b--fix-multi-user-tmp-permission-collision-in-relay-xyz-guardsh)
**Effort:** ~15 min · **Risk:** 1

**ALLOW_PATHS:** `relay-automation/hooks/relay-xyz-guard.sh`

**Prompt for agent:**

> One-line fix in `relay-automation/hooks/relay-xyz-guard.sh` (Gemini GH-109 Phase 1b):
>
> Line 62 currently reads:
> ```bash
> STATE_DIR="${TMPDIR:-/tmp}/relay-xyz-guard"
> ```
> On a shared machine, User A creates this directory; User B's `mkdir -p` silently fails,
> `$MARKER` is never created, and the guard always blocks User B. Fix: append `$UID`:
> ```bash
> STATE_DIR="${TMPDIR:-/tmp}/relay-xyz-guard-${UID}"
> ```
> `$UID` is set by bash itself (no subprocess). This is the complete fix — one character
> change plus a dash separator.
>
> Gate: `./validate.sh` green. `grep -n STATE_DIR relay-automation/hooks/relay-xyz-guard.sh`
> must show `$UID` in the path. `shellcheck relay-automation/hooks/relay-xyz-guard.sh` must
> pass cleanly.

---

### Lane C — Watchdog orphaned-sleep leak in consult.sh (Gemini GH-109 P1a)

**Source:** [GH-109 Phase 1 / 1a](../1-INBOX/GH-109-GEMINI-FEEDBACK.md#1a--fix-orphaned-process-leak-in-consultsh-watchdog)
**Effort:** ~45 min · **Risk:** 2

**ALLOW_PATHS:** `relay-automation/consult.sh`

**Prompt for agent:**

> Fix the orphaned-sleep leak in `relay-automation/consult.sh`'s `_guarded_with_timeout`
> function (Gemini GH-109 Phase 1a). Relevant lines (around 123–132):
>
> ```bash
> local apid kpid rc=0
> ( cd "$WT" && "$@" < /dev/null ) > "$out" 2>&1 &
> apid=$!
> ( sleep "$secs"; kill -9 "$apid" 2>/dev/null ) >/dev/null 2>&1 &
> kpid=$!
> wait "$apid" || rc=$?
> kill "$kpid" 2>/dev/null || true; wait "$kpid" 2>/dev/null || true
> ```
>
> **Problem:** `kill "$kpid"` kills the subshell but its `sleep` grandchild is reparented to
> PID 1 and runs to completion silently. On rapid/repeated consults this accumulates orphaned
> sleeps.
>
> **Fix (macOS/BSD-compatible):** Kill children of `$kpid` before killing the subshell itself.
> `pkill -P` is available on macOS and kills direct children of a PID:
>
> ```bash
> wait "$apid" || rc=$?
> pkill -P "$kpid" 2>/dev/null || true   # kill sleep grandchild first
> kill "$kpid" 2>/dev/null || true
> wait "$kpid" 2>/dev/null || true
> ```
>
> **Before committing:** verify `pkill -P` behavior on macOS (it is available in macOS via
> `/usr/bin/pkill` — confirm with `which pkill`). If `pkill` is absent, fall back to:
> `kill $(ps -o pid= -g "$(ps -o pgid= $kpid 2>/dev/null | tr -d ' ')" 2>/dev/null) 2>/dev/null || true`
> — but `pkill -P` is the clean path.
>
> Add a brief comment at the fix site explaining the grandchild-kill pattern so it is not
> reverted as "unnecessary."
>
> **Scope:** fix the `sleep` orphan only. The separate agent-children leak (kill -9 on `$apid`
> doesn't reach agent's subprocesses) requires process-group changes to the agent launch site —
> that is follow-up work, not this lane.
>
> Gate: `./validate.sh` green. `shellcheck relay-automation/consult.sh` passes. Manual smoke:
> `ps aux | grep sleep` after two back-to-back consults that exit early shows no orphaned
> sleeps from this function (or document the verification method used).

---

## How to fire a lane

```bash
# Per lane:
utils/swarm-preflight.sh --gh-issue 109   # or 110 for Lane A
# → generates packet.md with freshness + fix-still-required confirmation

relay-automation/marathon-drive.sh \
  --builder codex \
  --reviewer agy \
  --allow-paths "<ALLOW_PATHS from lane detail above>" \
  --branch "<suggested_branch above>"
```

- Run all three lanes concurrently in separate terminals or worktrees — write-sets are verified disjoint.
- Never let any lane touch `relay-turn-lib.sh`, `bin/tick`, or `relay-drive.sh` — those are kernel zone; block with ALLOW_PATHS.
- After all lanes complete: `./validate.sh` must be green end-to-end before merging.

---

*Source docs: [GH-109](../1-INBOX/GH-109-GEMINI-FEEDBACK.md) · [GH-110](../1-INBOX/GH-110-SHELLCHECK-VENDOR-FIXES.md) · re-derive from source docs if scope changes.*
