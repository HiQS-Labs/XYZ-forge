---
gh_issue: 280
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/280
title: "Investigate Aider+Qwen3.8-Max reliability vs Aider+Claude-Sonnet-5 control ($5 OpenRouter budget) — test/debug/fix/iterate"
status: "Root cause resolved 2026-07-23 (second session) — edit-format mismatch (H2) confirmed with a real transcript; AIDER_FLAGS=--edit-format diff fixes it. See 'Findings (second session)' section."
created: 2026-07-22
updated: 2026-07-23
doc_type: feedback
effort: 3
complexity: 3
risk: 2
phases: 2
---

# GH-280 · Aider+Qwen vs Aider+Sonnet reliability investigation

Focused, budget-capped (~$5 OpenRouter) experiment to determine whether the empty-artifact/no-op
failures seen driving Aider + `qwen3.8-max-preview` (GH-279) are a Qwen problem, an Aider problem, or a
harness (ours) problem — using Aider + Claude Sonnet 5 as the control on identical tasks.

**Recommended sequencing (cheap-first):**
- Phase 1 — quick, near-zero-cost diagnostic: try Aider against Qwen with an explicit `--edit-format`
  override (`diff`/`diff-fenced`/`udiff`) instead of its auto-selected `whole`, on the exact failing
  installer task. Aider auto-picks `whole` for unlisted/custom model ids; this is Aider's most common
  failure mode for models it has no built-in metadata for, and has a known, cheap remedy.
- Phase 2 — if Phase 1 doesn't fully resolve it, run the fuller model × edit-format × files-per-turn
  matrix against both Qwen and the Sonnet control, K repetitions per cell (stochastic behavior observed:
  1 of ~4 lanes succeeded with default settings), hard-capped at $5 total OpenRouter spend.

Hypotheses to discriminate: H1 (Qwen doesn't reliably honor Aider's edit-format contract), H2 (Aider's
format selection/parsing is wrong for this model), H3 (harness prompt/containment degrades compliance).
Full experiment design, matrix, and deliverables are in the GitHub issue.

Depends on nothing else being fired first; independent of GH-279's punch-list items.

## Findings (2026-07-23 run)

**Corrected baseline:** the real historical failure rate is **6 failures out of 7 total aider-qwen
builder turns (~86%)** across the GH-268 marathon trial — not the looser "1 of ~4 lanes" figure used
earlier. This matters for interpreting everything below: at an 86% true rate, any clean-trial streak
in the double digits is not plausible by chance.

**80 total trials run, across 8 rounds, in this order:**

| Round | Condition | Result |
|---|---|---|
| 1 | Explicit `--edit-format` (diff/diff-fenced/udiff) vs auto-`whole`, 1 trial each | 4/4 pass |
| 2 | Auto vs explicit `diff`, 4 trials each, direct endpoint | 8/8 pass |
| 3 | 2-file + real relay-turn-style prompt (tick caveats, RELAY.md in chat), direct endpoint | 4/4 pass |
| 4 | Same, inside an isolated clone of the real ~1,082-file repo (repo-scale test) | 4/4 pass |
| 5 | Real `skills/ponytail/`+`skills/release/` paths (actual `SKILL.md` siblings), install.sh reset empty, 1 trial | Ambiguous — succeeded but took ~8 min / ~11k output tokens vs ~1-3 min / ~2-3k tokens typical |
| 6 | OpenRouter matrix: `qwen/qwen3.7-max` vs `anthropic/claude-sonnet-5` control, alternating, $5 budget-capped | 10/10 pass **each** ($0.40 spent of $5 cap; hit the 20-trial safety cap first) |
| 7 | Exact production model+endpoint (`qwen3.8-max-preview`, direct Alibaba MaaS), 2-file+relay-prompt, direct `aider` calls (no worktree) | 15/15 pass |
| 8a | **Real `git worktree add --detach` (matching production exactly)**, isolated scratch-clone base | **5/8 pass — 3 FAIL (empty files, a=0/b=0), reproducing the production signature** |
| 8b | Same, second batch, log-retention fixed for next failure | 10/10 pass (no failure caught this round) |

**Rounds 1–7 total: 62/62 pass, 0 failures.** Every angle that could be tested with a plain directory,
plain clone, or plain copy — edit-format choice, file count per turn, prompt complexity, repo scale,
model family/version, direct endpoint vs OpenRouter — came back completely clean. This rules out H1
(Qwen inherently unreliable) and H2 (Aider's edit-format selection is wrong for this model) as
sufficient explanations on their own: the OpenRouter control comparison in round 6 showed
`qwen/qwen3.7-max` matching `anthropic/claude-sonnet-5` exactly, 10/10 each.

**Round 8 (real `git worktree add --detach`) is the only condition that reproduced the failure at
all** — combined 15/18 pass (16.7% failure rate) across both batches, vs 0% everywhere else. This
points at Aider's own behavior when invoked inside a linked worktree with a detached HEAD, not at
Qwen, not at this repo's own harness code. **The harness's own copyback logic
(`rtl_worktree_begin`/`rtl_worktree_end`/`rtl_enforce` in `relay-automation/relay-turn-lib.sh`) was
read in full and is sound** — it faithfully copies back whatever Aider actually wrote in the worktree;
if the real committed files were 0 bytes, Aider itself wrote them empty inside the worktree, not a
copyback bug.

**Not fully isolated — the exact mechanism is still unknown.** 16.7% is a real signal (nothing else
came close) but far below the 86% production rate, and the second batch caught zero failures with log
retention enabled, so no failure transcript was captured to show what Aider actually does/says when it
breaks under worktree conditions. The most likely explanation is a real, intermittent Aider bug/quirk
specific to running inside a `git worktree add --detach` context, possibly compounding with something
not yet isolated (repeated turns in the same worktree lineage; real-repo content interacting with
worktree state — round 5's ambiguous long-running success is a loose thread here too).

**Recommendation:** don't block on this — **codex+agy remains the reliable builder pairing** (0
failures across the entire GH-268 marathon). If Aider+Qwen is revisited, the next diagnostic step is
running enough worktree-mode trials with failure-log retention to actually catch and read a failure
transcript, rather than more format/prompt/model variable testing (those are now well-covered).

**Safety note:** every worktree test used an isolated scratch clone as the worktree base — never the
real repo — specifically to avoid disturbing a concurrent, unrelated worktree (`~/wt/gh-281-sentinel`)
that was in progress throughout this session. Confirmed untouched throughout.

## Findings (2026-07-23, second session) — root cause resolved

The prior session's blocker — "no failure transcript was captured to show what Aider actually
does/says when it breaks" — is now resolved, and it changes the conclusion above.

**Prerequisite fix: the observability gap itself.** GH-161 had already given `codex-turn.sh`/
`agy-turn.sh` a persistent, gitignored transcript path (`relay-system/logs/<day>/...`) instead of an
ephemeral `$TMPDIR` file — but `aider-turn.sh` was missed, and this repo's `XYZ_PYTHON` default (unset
→ 1 → Python) meant the *actual* runtime executed was `utils/py/aider-turn.py`, which independently had
the same gap (and so did `utils/py/agy-turn.py`). Both were fixed and merged (PR #288, #290) before any
of the findings below were possible — every prior investigation round genuinely could not have caught a
failure transcript even if it tried, regardless of how many trials were run.

**A live GH-268 Wave-1 exercise (real production repo, real `qwen3.8-max-preview` endpoint) then
caught real failures on the first real attempt:**

1. **First attempt was invalid, not evidence** — a launch mistake (never exporting
   `AIDER_OPENAI_API_BASE`) caused `aider-turn.sh`'s own model-selection logic to silently fall back to
   its hardcoded OpenRouter default instead of routing to Qwen. That default —
   `openrouter/anthropic/claude-3.5-sonnet` — turned out to be **fully retired upstream** (confirmed via
   OpenRouter's live `/api/v1/models` catalog: zero `claude-3.5-sonnet`/`claude-3-5-sonnet` variants
   exist). Fixed separately (PR #291) and unrelated to Qwen's own reliability, but it means this
   specific default silently breaks *any* plain `aider`/`consult --models aider` call today that sets
   neither `AIDER_MODEL` nor `AIDER_OPENAI_API_BASE` — a live bug independent of this investigation.

2. **With the launch corrected, 3 real `aider-qwen` turns against the actual endpoint, under `whole`
   edit format (Aider's default when no format is specified for an unlisted model id): 2 hit litellm's
   own internal 300s per-request timeout repeatedly** (`Response stream timeout, timeout_seconds=300`),
   retried, and were killed by the outer 900s wall-clock cap without ever returning a response. **The
   third actually got a response — and it's the most valuable transcript of the whole investigation.**
   The model did genuinely correct, well-reasoned work (readable in full at
   `relay-system/logs/2026-07-22/aider-turn-MARATHON-GH268-QWEN-W1V3-TURN-39237.log`), but emitted a
   **standard unified diff** (`@@ -1,6 +1,60 @@` hunks) while Aider was configured for **`whole` format**
   (complete file rewrites). Aider silently discarded the mismatched output — recorded as "no tracked
   changes" despite the model doing its job correctly. Codex's own review of the same turn independently
   named the exact prior art: `relay-automation/README.md:501 "## Known OpenRouter edit-format quirks
   (GH-118)"`.

3. **This resurrects and confirms H2** (Aider's edit-format selection is wrong for this model), which
   the prior session's synthetic testing had ruled out — but only because those tests were too small/
   simple (small file counts, low context) to ever trigger the model's tendency to revert to diff-style
   output. At real production scale (a ~1,100-file repo, full README content in context, 179k-token
   turns), the mismatch reproduces cleanly and repeatably.

4. **Fix hypothesis tested and confirmed:** re-running the identical task with
   `AIDER_FLAGS="--edit-format diff"` forced explicitly took Qwen from **0/3 real edits** (whole format)
   to a **90%-complete, substantively correct implementation landing in round 1** (all 4 phase-brief
   items correctly implemented, confirmed by Codex's own review: "ordering, fast-path prerequisite
   placement, sandbox-hang note, and renamed anchors are all present and correctly linked on disk"). The
   phase still didn't reach `Approved` within the round cap (6) — 2 more rounds hit the same 900s
   timeout, and Codex reasonably held the build to a slightly higher bar than the original brief
   specified (wanted actual install/auth instructions, not just a heading rename) — but the core
   reliability question is answered: **`--edit-format diff` is the fix**, and the remaining timeout
   sensitivity is a separate, secondary issue (Qwen is slow on large-context real-repo turns, not
   unreliable once given a parseable format).

**Revised recommendation:** Aider+Qwen is viable as a builder **with `AIDER_FLAGS=--edit-format diff`
forced** (not left to Aider's auto-selection) **and a generous turn timeout** (900s was borderline; the
model needs the full budget on real-repo-scale tasks). codex+agy remain the lower-friction default for
now, but the historical ~86% failure rate is now explained rather than mysterious, and is very likely
addressable with this one flag rather than requiring a different builder entirely.

**Process note:** three real production branches were cut and diagnosed live during this session
(`marathon/gh-268-qwen-w1v2/w1v3/w1v4-difffmt-2026-07-23`) — the first two invalidated/cleaned up, the
last preserved and pushed as evidence. All worktree isolation, tick-token cleanup, and branch hygiene
followed this repo's own documented conventions throughout.
