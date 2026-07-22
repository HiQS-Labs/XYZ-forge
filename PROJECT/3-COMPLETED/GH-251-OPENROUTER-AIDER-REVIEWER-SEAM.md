---
gh_issue: 251
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/251
title: "OpenRouter/aider reviewer seam: aider produces reviews but doesn't persist the relay-file append (builder-only in practice)"
status: "SHIPPED — closed 2026-07-21, merged via PR #256 (commit cf7a123). See GitHub issue comment
  for evidence. NOTE: one DoD item (live OpenRouter model verification) still needs a human operator
  step that cannot run headless — that item is NOT claimed done, only the code-level fix."
created: 2026-07-19
updated: 2026-07-19
owner: noel
doc_type: bug
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
goal: >
  Make the OpenRouter/aider seam usable as a headless REVIEWER: a review turn must either land its
  graded findings in the relay file, or the harness must salvage the review from the aider transcript —
  never silently discard a completed review as a stall. If neither is viable, document the seam as
  builder-only and route review turns to codex/agy.
roadmap_exempt: false
---

# GH-251 · OpenRouter/aider reviewer seam doesn't persist its review

## Status
| What was just completed | What's next |
|---|---|
| **Fixed on branch `cf7a123`** (Plan L lane): both fix directions 1+2 landed in `relay-automation/aider-turn.sh` — **review mode** (explicit reviewer posture on `ALLOW_PATHS=""` turns) + **transcript-salvage backstop** (a review-only turn that lands no relay-file delta but whose transcript carries a `Verdict:` anchor is appended, attributed, so the review lands instead of stalling). Composes with GH-245: empty/non-review turns leave no anchor → not salvaged → still a genuine stall. `test/aider-turn.sh` +2 cases (phantom-review salvaged; non-review not salvaged), 61/61 pass. | Open a PR into `development`. **Honest gap:** DoD bullet 1's "verified with a REAL OpenRouter model, not a stub" is NOT done — it needs a live OpenRouter call that can't run headless in the Bash sandbox; that live verification remains an operator step before closing #251. On merge, move to `3-COMPLETED`. |
| **2026-07-21:** merged via PR [#256](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/256) (commit `cf7a123`); issue #251 closed on GitHub on the strength of the code-level fix. **DoD bullet 1's live-OpenRouter-model verification is STILL an outstanding operator step** — it is not claimed done by this closure. | Promoted to `3-COMPLETED`. The live-verification caveat carries forward; no further doc action otherwise. |

## Problem

Driving a **review** turn through the OpenRouter seam —
`relay-drive.sh --review-once --agent-cmd relay-automation/aider-turn.sh` with `ALLOW_PATHS=""` (relay
file is the only writable path) and `AIDER_MODEL=openrouter/z-ai/glm-5.2` — the model produces a
complete, correct, `file:line`-cited review **in the aider transcript**, but the review **does not
persist** into the relay file:

1. aider is an *editor*, not a reviewer. Its repomap auto-adds off-allowlist repo files
   ("I added these files to the chat: `relay-automation/new-relay.sh`, `validate.sh`…") and it wanders
   into "what changes would you like?" instead of appending findings.
2. Its markdown append to the relay file is lost through worktree containment, so the ROOT relay file
   is unchanged after the turn.
3. `relay-drive --review-once` then **correctly** scores the unchanged file a stall (`exit 3`).

Reproduced on **both** GLM review turns (rounds 1 and 3), including with
`AIDER_FLAGS="--map-tokens 0 --no-auto-lint"`. Each time the review had to be recovered by hand from
the transcript and transcribed into the thread.

**Not a classifier bug.** The `exit 3` is correct — this is a live confirmation of the GH-245
evidence-based `--review-once` classifier (the old token-state logic would have false-scored these
`exit 5`). The defect is upstream, in the reviewer seam: it doesn't land its output.

## Fix direction (decide in Phase 0)

1. **Review-mode for `aider-turn.sh`** — when `ALLOW_PATHS=""`, invoke aider in a non-editing/ask-style
   mode with the relay file pinned as the only chat file and repomap fully disabled, so the model
   appends findings instead of proposing (and losing) code edits.
2. **Transcript-capture fallback** — if a review turn produces no relay-file delta but the transcript
   contains a graded review block (`Verdict:` + findings), append the transcript's review to the relay
   file (attributed) instead of discarding it. Turns a lost review into a landed one; also benefits
   codex/agy on the same failure mode.
3. **Document builder-only** — if neither is reliable, state in `aider-turn.sh` + relay-xyz SKILL.md
   that the OpenRouter/aider seam is builder-only and route review turns to codex/agy, so operators
   don't reach for a seam that can't report.

Options 1 and 2 are complementary (harden the happy path + a salvage backstop); option 3 is the honest
fallback if the seam can't be made to append.

## Definition of done
- [ ] A review turn driven through `aider-turn.sh` with `ALLOW_PATHS=""` either lands its graded review
      in the relay file, OR the harness salvages the review from the transcript and appends it
      (attributed) — verified with a real OpenRouter model, not a stub.
- [ ] A review turn that genuinely did nothing still scores `exit 3` (no false rescue of an empty turn).
- [ ] If the builder-only path is chosen instead, `aider-turn.sh` + relay-xyz SKILL.md say so and review
      turns are routed away from the seam.
- [ ] `bash validate.sh` no worse than baseline.

## Phase 0 — diagnose & scope
> Discovery phase: findings written back into this doc before its QA gate can pass (PROJECT/PDDA.md).

- [ ] Reproduce in-repo with a cheap OpenRouter model (not a stub) — confirm the append is lost, not just flaky.
- [ ] Locate where the review append is dropped: aider's edit format vs. `rtl_worktree_end` copyback vs. containment revert.
- [ ] Decide fix direction (1 / 2 / 3 above); if (2), define the transcript review-block grammar to detect.
- [ ] Confirm the fix composes with the GH-245 classifier (don't re-introduce a token-state rescue).
- [ ] Set/correct triage ratings; clear `ratings_provisional`.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/aider-turn.sh", "pattern": "review.mode" }
  ],
  "artifacts": [ "relay-automation/aider-turn.sh" ],
  "remediation": {
    "source": "issue#251",
    "criteria": "A review turn (ALLOW_PATHS=\"\") through aider-turn.sh lands its graded review in the relay file (or the harness salvages it from the transcript, attributed); an empty turn still scores exit 3; bash validate.sh no worse than baseline. Draft contract — artifacts not yet operator-verified."
  },
  "lanes": { "agy_safe": [ "relay-automation/aider-turn.sh" ], "orchestrator_only": [] }
}
```
