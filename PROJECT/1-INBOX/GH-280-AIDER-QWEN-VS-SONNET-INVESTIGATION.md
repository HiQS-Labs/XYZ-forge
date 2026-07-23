---
gh_issue: 280
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/280
title: "Investigate Aider+Qwen3.8-Max reliability vs Aider+Claude-Sonnet-5 control ($5 OpenRouter budget) — test/debug/fix/iterate"
status: "Phase 1 run 2026-07-23 — root cause narrowed, not fully isolated. Phase 2 ($5 matrix) done, no further spend needed for now."
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
