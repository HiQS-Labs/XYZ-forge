---
title: Marathon Plan 2026-07-04 — low-risk blend (Fable GH-110 + Gemini GH-109 Phase 1 + Aider/OpenRouter GH-119/GH-120)
status: Active (2-WORKING)
created: 2026-07-04
updated: 2026-07-03
owner: noel
branch: main
doc_type: project
source: PROJECT/1-INBOX/GH-110-SHELLCHECK-VENDOR-FIXES.md, PROJECT/1-INBOX/GH-109-GEMINI-FEEDBACK.md, GH-119, GH-120
generated_by: hand (pre-flighted from audit findings; extended 2026-07-03 with GH-119/GH-120 from live Aider/OpenRouter testing)
roadmap_exempt: true
goal: >
  Five collision-free Phase-1 lanes: three from the Fable 5 (GH-110) and Gemini (GH-109)
  audit findings, plus two from live Aider/OpenRouter model testing (GH-119, GH-120).
  All low-risk, all disjoint write-sets — wave-packable in parallel.
  Assertion fix from Fable item 1 already landed in 84ff078; five items remain open.
---

<!-- Pre-flighted from GH-109 + GH-110 Phase 1 findings, extended 2026-07-03 with GH-119/GH-120.
     Write-sets verified disjoint below. Edit the source docs (1-INBOX/GH-109*, 1-INBOX/GH-110*,
     the GH-119/GH-120 issues), not this plan. -->

# Marathon Plan 2026-07-04 — low-risk Fable + Gemini + Aider/OpenRouter blend

> Scoped to Phase 1 items from the two external audit issues, plus two Aider/OpenRouter harness
> fixes surfaced by live testing on 2026-07-03. Execution detail lives in
> [GH-110-SHELLCHECK-VENDOR-FIXES.md](../1-INBOX/GH-110-SHELLCHECK-VENDOR-FIXES.md),
> [GH-109-GEMINI-FEEDBACK.md](../1-INBOX/GH-109-GEMINI-FEEDBACK.md),
> [#119](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/119), and
> [#120](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/120).
> **Note:** Fable's item 1 (broken assertion at `test/xyz-vendor.sh:140`) already landed in
> `84ff078` — excluded from this plan.

## Status

| What was just completed | What's next |
|---|---|
| Plan pre-flighted 2026-07-04 from audit findings; extended 2026-07-03 with two lanes from live GH-118 follow-on testing (GH-119, GH-120); write-sets verified disjoint across all 5 lanes; all in Wave 1. | **Wave 1 (all parallel):** Lane A ‖ Lane B ‖ Lane C ‖ Lane D ‖ Lane E. Fire each via `swarm-preflight → marathon-drive` scoped by `ALLOW_PATHS`. |

## The one safety rule

Two lanes are safe to run concurrently **iff their write-sets are disjoint.** No kernel files
(`relay-turn-lib.sh`, `bin/tick`, `relay-drive.sh`) are touched in this plan.

## Write-set collision map

| Lane | Files written | Zone | Parallel-safe? |
|---|---|---|---|
| A — vendor payload cleanup | `relay-automation/xyz-vendor.sh`, `skills/swe/SKILL.md` | independent | ✅ |
| B — tmp UID isolation | `relay-automation/hooks/relay-xyz-guard.sh` | independent | ✅ |
| C — watchdog leak fix | `relay-automation/consult.sh` | shim | ✅ |
| D — reviewer read-only pre-seed (GH-119) | `relay-automation/aider-turn.sh` | shim | ✅ |
| E — model-alias lookup table (GH-120) | `relay-automation/openrouter-model-aliases.yml` (new) | independent | ✅ |

All write-sets are disjoint. No kernel zone entries. **All five run in Wave 1.**

## Per-lane scoring

| Lane | cx | risk | eff | zone | score | wave |
|---|---|---|---|---|---|---|
| A — vendor payload cleanup | 1 | 1 | 1 | independent | 5 | 1 |
| B — tmp UID isolation | 1 | 1 | 1 | independent | 5 | 1 |
| C — watchdog orphaned-sleep | 2 | 2 | 2 | shim | 11 | 1 |
| D — reviewer read-only pre-seed (GH-119) | 2 | 2 | 2 | shim | 11 | 1 |
| E — model-alias lookup table (GH-120) | 1 | 1 | 2 | independent | 6 | 1 |

## Recommended wave

**Wave 1:** Lane A ‖ Lane B ‖ Lane C ‖ Lane D ‖ Lane E

- Lane A → `marathon/gh-110-vendor-payload-cleanup-2026-07-04`
- Lane B → `marathon/gh-109-tmp-uid-isolation-2026-07-04`
- Lane C → `marathon/gh-109-watchdog-orphaned-sleep-2026-07-04`
- Lane D → `marathon/gh-119-reviewer-readonly-preseed-2026-07-04`
- Lane E → `marathon/gh-120-model-alias-lookup-2026-07-04`

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

### Lane D — Reviewer read-only pre-seed in aider-turn.sh (GH-119)

**Source:** [#119](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/119) — sibling of #54/#107, surfaced live 2026-07-03 testing GH-118's fix.
**Effort:** ~45 min · **Risk:** 2

**ALLOW_PATHS:** `relay-automation/aider-turn.sh`

**Prompt for agent:**

> Fix a scope-creep gap in `relay-automation/aider-turn.sh` found via live testing (GH-119):
> when a review-only turn (`ALLOW_PATHS=""`) is driven with `--edit-format diff`, a model can
> emit a valid SEARCH/REPLACE edit for a file it was never given via `--file`/`--read` — Aider's
> `--yes-always` auto-confirms the implicit "add this file to the chat?" prompt and applies the
> edit. The harness's off-lane guard in `relay-turn-lib.sh` correctly catches this and discards
> the whole turn (including any otherwise-valid, in-lane edit) — but the turn is wasted.
>
> **Fix:** for review-only turns (when `ALLOW_PATHS` is empty), derive the set of files changed
> in the reviewed diff/artifact and pass each as an additional `--read` flag (alongside the
> existing `--read .relay-artifacts/<artifact>`) in the `aider_args` construction (around
> `relay-automation/aider-turn.sh:135-142`). `--read` files are structurally read-only to Aider
> even under `--yes-always`, so the Reviewer gets full file context to reason about without a
> path it can write to.
>
> **Do not** change the build/fix-turn path (where `ALLOW_PATHS` is non-empty and the artifact
> IS meant to be edited) — this fix is scoped to `ALLOW_PATHS=""` review-only turns only.
>
> Gate: `./validate.sh` green. `shellcheck relay-automation/aider-turn.sh` passes. Add/extend
> `test/aider-turn.sh` with a case asserting a review-only turn cannot apply an edit to a
> non-allowlisted, `--read`-seeded file (turn should still succeed — it should simply have no
> path to write there, not fail containment).

---

### Lane E — OpenRouter model-alias lookup table (GH-120)

**Source:** [#120](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/120) — captured 2026-07-03 from repeated live model-name lookups during GH-118 testing.
**Effort:** ~30 min · **Risk:** 1

**ALLOW_PATHS:** `relay-automation/openrouter-model-aliases.yml`

**Prompt for agent:**

> Build a small fuzzy-match lookup table for OpenRouter model names (GH-120), so future sessions
> don't need a live API query to resolve a colloquial model name to its canonical slug.
>
> 1. Create `relay-automation/openrouter-model-aliases.yml` seeded with the models already tested:
>    ```yaml
>    glm-5.2: z-ai/glm-5.2
>    nemotron ultra 3: nvidia/nemotron-3-ultra-550b-a55b
>    nemotron ultra 3 free: nvidia/nemotron-3-ultra-550b-a55b:free
>    ```
> 2. Add a small lookup helper (a `resolve-model-alias.sh` or inline function in
>    `relay-automation/`) that normalizes input (lowercase, strip punctuation/hyphens) and does a
>    token/substring fuzzy match against the table's keys, returning the canonical slug.
> 3. Document in `relay-automation/README.md` (or the `relay-xyz` skill) how to add a new alias
>    when testing a new model.
>
> **Out of scope for this lane:** the optional `--verify` re-query mode against OpenRouter's
> live model list — that's a follow-up, not required for this lane's acceptance.
>
> Gate: `./validate.sh` green. A new `test/model-alias.sh` (or equivalent) asserts the three
> seeded aliases resolve correctly, including a fuzzy variant (e.g. "Nemotron 3 Ultra" or
> "nemotron-ultra3") for at least one entry.

---

## How to fire a lane

```bash
# Per lane:
utils/swarm-preflight.sh --gh-issue 109   # or 110 for Lane A, 119 for Lane D, 120 for Lane E
# → generates packet.md with freshness + fix-still-required confirmation

relay-automation/marathon-drive.sh \
  --builder codex \
  --reviewer agy \
  --allow-paths "<ALLOW_PATHS from lane detail above>" \
  --branch "<suggested_branch above>"
```

- Run all five lanes concurrently in separate terminals or worktrees — write-sets are verified disjoint.
- Never let any lane touch `relay-turn-lib.sh`, `bin/tick`, or `relay-drive.sh` — those are kernel zone; block with ALLOW_PATHS.
- After all lanes complete: `./validate.sh` must be green end-to-end before merging.

---

*Source docs: [GH-109](../1-INBOX/GH-109-GEMINI-FEEDBACK.md) · [GH-110](../1-INBOX/GH-110-SHELLCHECK-VENDOR-FIXES.md) · [#118](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/118) · [#119](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/119) · [#120](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/120) · re-derive from source docs if scope changes.*
