---
title: Marathon Plan — 2026-07-23 · GH-279/GH-280 aider-qwen follow-up
status: "GH-280 root cause resolved 2026-07-23 (second session) — edit-format mismatch confirmed, AIDER_FLAGS=--edit-format diff is the fix. GH-279 still queued/unfired (OPEN)."
created: 2026-07-23
updated: 2026-07-22
owner: noel
branch: development
doc_type: project
source: PROJECT/1-INBOX/GH-279-AIDER-QWEN-MARATHON-TRIAL-FINDINGS.md + GH-280-AIDER-QWEN-VS-SONNET-INVESTIGATION.md
generated_by: hand-authored (operator-directed follow-up to the GH-268 aider-qwen marathon trial, PR #282)
lanes: [279, 280]
execution: GH-280 investigation concluded (root cause resolved, findings posted to the issue); GH-279 remains queued, not yet fired
roadmap_exempt: true
goal: >
  Follow-up work from trialing aider-qwen as a marathon builder on GH-268: GH-279 is a punch list of
  harness defects found along the way (independently fixable, no urgency); GH-280 is the focused
  experiment that determines whether Aider+Qwen is a usable builder at all, gated at $5 OpenRouter
  spend. GH-280 is now concluded — see Resolution below. GH-279 is documented and queued, still not
  fired.
---

# Marathon Plan — 2026-07-23 · GH-279/GH-280 aider-qwen follow-up

## Status

| What was just completed | What's next |
|---|---|
| GH-268 Phase 1 installer marathon shipped (PR #282, merged `f38d23a`) via an aider+qwen3.8-max builder trial (2/9 files, partially reliable) then codex+agy (7/9, 0 failures). GH-280 was fired across two sessions and is now **concluded**: root cause found (Aider's `whole` edit-format silently discards Qwen's diff-style output) and fix confirmed (`AIDER_FLAGS=--edit-format diff`). Along the way, two independent real bugs were found and fixed directly (no separate issue needed — merged same session): a log-persistence gap in `aider-turn.sh`/`aider-turn.py`/`agy-turn.py` (PR #288, #290), and a dead/retired OpenRouter default model id (PR #291). A genuinely new gap was also surfaced and filed separately: **GH-294** (`swarm-preflight.sh`'s suggested marathon invocations never default to `RELAY_WORKTREE_ISOLATION=1`). | **GH-280: no further action planned** — recommendation is codex+agy stays the default builder pairing, with Aider+Qwen usable as a fallback if `AIDER_FLAGS=--edit-format diff` and a generous timeout are set explicitly. **GH-279 still queued (OPEN, unfired)** — independently actionable, no dependency on GH-280's result. Note: GH-279 item 1 ("Aider↔Qwen edit-format mismatch → empty artifacts") is effectively answered by GH-280's findings now, but GH-279 itself hasn't been edited/closed to reflect that. **GH-294 queued (OPEN, unfired)** — new, not part of the original two-lane scope. |

## The one safety rule

Two lanes are safe to run concurrently **iff their write-sets are disjoint**. Current caps: kernel≤1/wave.

## Collision map

| Zone | Parallel-safe? | Active items here |
|---|---|---|
| kernel | ❌ serialize — one at a time | #279 (touches `aider-turn.py`/`aider-turn.sh`), #280 Phase 2 fix-if-confirmed (same files) |
| independent | ✅ | #280 Phase 1 (diagnostic script + scratch test repo, no core file edits) |

**Note:** GH-279's timeout-drift fix and GH-280's Phase-2 edit-format fix (if the diagnostic confirms
one) both land in `relay-automation/aider-turn.sh` / `utils/py/aider-turn.py` — do not run both as
simultaneous build lanes. GH-280 Phase 1 (the diagnostic) has no such collision; it's scratch-only.

## Per-item scoring

| Item | cx | risk | eff | zone | deps | score | wave |
|---|---|---|---|---|---|---|---|
| [#280] Aider+Qwen vs Aider+Sonnet reliability investigation ($5 OpenRouter budget) | 3 | 2 | 3 | independent (Phase 1) → kernel (Phase 2 fix) | — | 15 | now |
| [#279] aider-qwen marathon trial — consolidated harness findings | 2 | 1 | 2 | kernel | soft: avoid concurrent edit with #280 Phase 2 | 8 | queued |

## Recommended waves (as originally planned — see Resolution below for what actually happened)

**Now (operator step 3):** #280 — cut a fresh branch off `development`, start with the
`--edit-format` diagnostic (near-zero cost) before touching the $5 matrix budget.

- #280 → suggested_branch: `marathon/gh-280-aider-qwen-vs-sonnet-2026-07-23`

**Queued (fire later, not this pass):** #279 — independently actionable, no dependency on #280's
outcome. Serialize against #280 Phase 2 if both are ever in flight (see collision map).

## Resolution (2026-07-22 — GH-280 concluded)

GH-280 ran across two sessions, on branches `marathon/gh-280-aider-qwen-vs-sonnet-2026-07-23` (first
session, 80 synthetic trials) and `marathon/gh-268-qwen-w1v2/w1v3/w1v4-difffmt-2026-07-23` (second
session, real production GH-268 attempts). Full findings are in
`PROJECT/1-INBOX/GH-280-AIDER-QWEN-VS-SONNET-INVESTIGATION.md` and posted to the GH-280 issue thread.
Summary:

- **Root cause:** Aider auto-selects `whole` edit format for unlisted/custom model ids; Qwen ignores
  this and emits standard unified diffs anyway, which Aider silently discards as "no tracked changes."
  This is the real explanation for the historical ~86% aider-qwen failure rate on the GH-268 marathon
  trial — not general Qwen unreliability.
- **Fix confirmed:** forcing `AIDER_FLAGS="--edit-format diff"` took a real production task from 0/3
  real edits to a 90%-complete, correct implementation landing in round 1.
- **Recommendation:** codex+agy remains the default builder pairing (0 failures across the whole GH-268
  marathon). Aider+Qwen is usable as a fallback/alternate builder if `AIDER_FLAGS=--edit-format diff`
  and a generous turn timeout (900s was borderline at real-repo scale) are set explicitly rather than
  left to Aider's defaults.
- **Real bugs found and fixed along the way (not GH-280's subject, but surfaced by chasing it):**
  - Log-persistence gap in `aider-turn.sh`/`utils/py/aider-turn.py`/`utils/py/agy-turn.py` — fixed
    directly, no separate issue (PR #288, #290).
  - Dead/retired OpenRouter default model id (`openrouter/anthropic/claude-3.5-sonnet`) — fixed
    directly, no separate issue (PR #291).
  - `swarm-preflight.sh`'s suggested marathon invocations never default to
    `RELAY_WORKTREE_ISOLATION=1` — filed as its own issue, **GH-294** (OPEN, unfired), since it's a
    distinct harness-default gap, not part of GH-280's scope.
- **Not fired further:** the remaining Wave-1 candidate issues from the earlier `/10days` sweep
  (GH-272, GH-284, GH-153, GH-147) and the planned Wave 2 were deliberately not fired — the debugging
  goal (is Aider+Qwen viable, and why does it fail) was answered, and the operator directed concluding
  rather than continuing the exercise.
- **GH-279 unaffected by this session** — still OPEN, unfired, independently actionable. Its item 1
  ("Aider↔Qwen edit-format mismatch → empty artifacts") is now effectively explained/answered by
  GH-280's findings, but the GH-279 issue/doc itself has not been edited to note that.

## Contract seams — pin a contract before launching both concurrently (GH-5)

`relay-automation/aider-turn.sh` and `utils/py/aider-turn.py` are the shared seam between #279 and
#280 Phase 2. If both are ever fired in the same wave, scope `ALLOW_PATHS`/preflight write-sets so
only one lane edits either file at a time.

## Held / flagged — excluded from this pass

- GH-279 is fully specified and PDDA-captured but deliberately not fired this pass — operator directed
  step 3 (GH-280) as the immediate next action; GH-279 has no urgency and no dependency on GH-280.
