---
gh_issue: 147
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/147
title: LM Studio local-LLM lane for consult, relay, and swarm
status: Active (2-WORKING) — Phase 0 spike + Phase 1 (consult/Aider truthfulness) complete; Phase 2 relay seam next
created: 2026-07-05
updated: 2026-07-06
owner: noel
doc_type: feature
complexity: 4
risk: 3
effort: 4
phases: 5
ratings_provisional: false
non_goals:
  - Not replacing the existing Codex, Claude, agy, or Aider/OpenRouter lanes
  - Not making LM Studio the default path for any existing workflow
  - Not assuming every LM Studio model supports the same response shape, tool use, or token accounting
related:
  - relay-automation/consult.sh
  - utils/py/consult.py
  - utils/py/aider-turn.py
  - relay-automation/aider-turn.sh
  - relay-automation/marathon-drive.sh
  - relay-automation/relay-drive.sh
  - utils/py/swarm_preflight.py
goal: >
  Add an opt-in LM Studio-backed local-LLM lane by reusing the existing Aider/OpenAI-compatible seam
  first, then wiring that lane through consult, relay, and swarm planning without changing any
  existing default path unless LM Studio is explicitly selected.
roadmap_exempt: false
---

# GH-147 · LM Studio local-LLM lane for consult, relay, and swarm

LM Studio support is plausible here because the repo already has one reusable seam: Aider can speak to
OpenAI-compatible endpoints, and this repo already routes Aider through consult and relay. The spike
proved that seam is real enough to plan against.

Reversibility: **Costly** once implementation starts. The shared surfaces are `consult`, the Aider
turn shim, relay routing, and swarm-preflight lane assignment. The rollback path is to keep the work
strictly opt-in and preserve byte-identical behavior for Codex, Claude, agy, and current Aider /
OpenRouter defaults unless LM Studio is explicitly selected.

## Status

| What was just completed | What's next |
|---|---|
| **Phase 1 — consult + Aider truthfulness** ✅ completed 2026-07-06. The Aider consult path (both `relay-automation/consult.sh` and `utils/py/consult.py`) now (a) accepts an OpenAI-compatible base URL via `AIDER_OPENAI_API_BASE` + `AIDER_OPENAI_API_KEY` (dummy default) without requiring `OPENROUTER_API_KEY`, and (b) **fails closed**: an exit-0 Aider run whose transcript shows an auth/config error or has no visible content is now counted `[FAIL]`, not a false `[ok]`. 5 new tests in `test/consult.sh` (auth false-green, empty answer, LM Studio seam) — 23/23 green on both shell and Python ports. Phase 0 spike (Aider-bridge-first seam) remains the basis. | **Phase 2 — reuse the Aider relay seam**: thread the same LM Studio base-URL/model/dummy-key contract through the existing Aider turn shim (`utils/py/aider-turn.py`), proving review-only and single-file edit turns under containment before any planner routing. |

## Table of contents

- [Phase 0 — Technical spike and seam choice](#phase-0--technical-spike-and-seam-choice--done-2026-07-05)
- [Phase 1 — Make consult and Aider LM Studio-aware and truthful](#phase-1--make-consult-and-aider-lm-studio-aware-and-truthful)
- [Phase 2 — Reuse the Aider relay seam for LM Studio turns](#phase-2--reuse-the-aider-relay-seam-for-lm-studio-turns)
- [Phase 3 — Teach swarm-preflight and marathon routing about the lane](#phase-3--teach-swarm-preflight-and-marathon-routing-about-the-lane)
- [Phase 4 — Hardening, docs, and live operator proof](#phase-4--hardening-docs-and-live-operator-proof)

## Phase 0 — Technical spike and seam choice ✅ DONE 2026-07-05

Purpose: prove the smallest truthful path before touching shared runtime surfaces. This spike was not
"ship LM Studio support"; it was "identify the cheapest safe seam and record the unknowns honestly."

### Checklist

- [x] Reproduced baseline LM Studio transport against a live local endpoint:
      `GET /v1/models` and non-streaming `POST /v1/chat/completions`.
- [x] Recorded the minimum working Aider config for LM Studio in this environment:
      model id, base URL, dummy API key requirement, and edit-format behavior.
- [x] Ran a narrow Aider consult proof outside the relay harness so transport and model behavior were
      separated from containment questions.
- [x] Ran a narrow Aider edit proof outside the relay harness and checked both default `whole` and
      explicit `--edit-format diff`.
- [x] Characterized one direct consult-style LM Studio path and captured the empty-visible-content
      failure mode when reasoning tokens consume the budget.
- [x] Compared the first two feasible seams:
      `Aider -> LM Studio` versus `direct consult -> LM Studio`.
- [x] Wrote the findings back into this doc before promoting it to `2-WORKING`.

### Findings written back from the spike

#### 0.1 Manual LM Studio transport is real, but low budgets can produce no visible answer

Commands run:

```bash
curl -sS http://127.0.0.1:1234/v1/models

printf '%s\n' \
  '{"model":"agents-a1","messages":[{"role":"user","content":"Reply with exactly: LM Studio baseline OK"}],"stream":false,"max_tokens":128}' \
| curl -sS http://127.0.0.1:1234/v1/chat/completions \
    -H 'Content-Type: application/json' \
    -d @-

printf '%s\n' \
  '{"model":"agents-a1","messages":[{"role":"user","content":"Reply with exactly: LM Studio baseline OK"}],"stream":false,"max_tokens":512}' \
| curl -sS http://127.0.0.1:1234/v1/chat/completions \
    -H 'Content-Type: application/json' \
    -d @-
```

Observed:

- `GET /v1/models` returned `agents-a1` and `text-embedding-nomic-embed-text-v1.5`.
- At `max_tokens: 128`, the response ended with `finish_reason: "length"`, `message.content: ""`,
  and only `reasoning_content`.
- At `max_tokens: 512`, the same prompt returned visible content, but only after spending a large
  reasoning budget first.

What it changes:

- LM Studio transport compatibility is real, but a "200 OK" is not the same thing as a usable answer.
- Any consult integration must treat `reasoning_content` + empty visible `content` as a first-class
  failure or escalation path.

#### 0.2 Aider can already reach LM Studio with a small, specific config contract

Working minimum:

```bash
aider \
  --model openai/agents-a1 \
  --openai-api-base http://127.0.0.1:1234/v1 \
  --openai-api-key dummy \
  --yes-always --no-auto-commits --no-gitignore \
  --no-check-update --no-analytics --no-show-model-warnings \
  --no-stream --map-tokens 0 \
  --message 'Reply with exactly: Aider LM Studio OK'
```

Observed:

- Aider recognized `openai/agents-a1`.
- The local server itself did not require auth for raw `curl`, but Aider still required a non-empty
  `--openai-api-key`.
- The default format reported for this model was `whole edit format`.

What it changes:

- The first implementation seam does not need a new bespoke client just to prove build/review turns.
- Auth handling must model the client contract, not only the server contract.

#### 0.3 Narrow Aider consult and edit proofs succeeded outside the harness

Edit proof setup:

```bash
tmpdir=$(mktemp -d)
cd "$tmpdir"
git init -q
printf 'alpha\n' > note.txt
git add note.txt
git -c user.name=Spike -c user.email=spike@example.com commit -qm init
```

Observed:

- Aider returned the expected visible consult answer.
- On the single-file edit proof, default `whole` succeeded and explicit `--edit-format diff` also
  succeeded.

What it changes:

- For `agents-a1`, this spike did not reproduce the GH-118-style edit-format failure.
- The shortest truthful plan is: keep `AIDER_FLAGS=--edit-format diff` available, but do not invent
  a format bug the spike did not actually prove.

#### 0.4 Repo seam readout: the Aider lane is partly present; consult and planner logic are not

Code findings recorded from the repo:

- `relay-automation/consult.sh` already exposes an Aider advisor path, but it is shaped around current
  OpenRouter assumptions.
- `utils/py/consult.py` mirrors that path and currently trusts process exit status too much.
- `utils/py/aider-turn.py` already provides the Aider relay shim with allowlist, token ownership,
  and worktree isolation.
- `relay-automation/marathon-drive.sh` already recognizes `aider*` agent ids.
- `utils/py/swarm_preflight.py` still plans only `codex_lane` and `agy_lane`.

Observed consult-path behavior:

```bash
OPENROUTER_API_KEY=dummy \
AIDER_MODEL=openai/agents-a1 \
AIDER_OPENAI_API_BASE=http://127.0.0.1:1234/v1 \
python3 utils/py/consult.py \
  --prompt 'Reply with exactly: CONSULT LM STUDIO OK' \
  --models aider
```

Observed:

- This produced an Aider auth error transcript because the client still wanted `OPENAI_API_KEY`.
- `consult.py` still counted the run as answered because it trusted exit code alone.

What it changes:

- The first real bug to fix is not "LM Studio transport"; it is "consult can false-green a failed
  Aider call."
- The plan should start with consult/Aider truthfulness, then reuse the existing relay seam, then add
  planner routing last.

#### 0.5 Seam choice

Recommendation: **Aider bridge first**.

Why:

- It already covers the widest surface with the smallest new runtime shape: consult has an Aider
  branch, relay already has an Aider shim, and marathon routing already recognizes `aider*`.
- A direct non-Aider consult lane would solve only consult and would not prove the relay/swarm path.

#### 0.6 Unknowns still open after the spike

- The relay harness itself was not driven end-to-end against LM Studio in this spike.
- `agents-a1`'s heavy reasoning-token use may require timeout and token-budget tuning.
- The spike only proved a narrow single-file edit, not multi-file or long-running relay prompts.
- Streaming, tool use, and token-usage consistency remain uncharacterized.

### QA checklist — Phase 0

- [x] Findings are written back into this doc with concrete commands and observed behavior.
- [x] The recommended first seam is explicit: **Aider bridge first**.
- [x] The remaining unknowns are explicit, so later phases do not pretend the spike proved more than it did.
- [x] No shared runtime surface was changed during the spike itself.

## Phase 1 — Make consult and Aider LM Studio-aware and truthful

Purpose: fix the known consult truthfulness gap first, while keeping the change strictly opt-in and
limited to the existing Aider/OpenAI-compatible seam.

### Checklist

- [x] Define one explicit LM Studio config contract for the Aider-backed consult path:
      base URL, model id, and the client-side auth rule (including the dummy-key case).
      → `AIDER_OPENAI_API_BASE` (base URL) + `AIDER_OPENAI_API_KEY` (default `dummy`) +
      `AIDER_MODEL` (default `openai/agents-a1` when a base URL is set).
- [x] Generalize the current consult/Aider path so an OpenAI-compatible base URL can be supplied
      without pretending the path is OpenRouter-only. → `run_aider` / aider branch now branch on
      `AIDER_OPENAI_API_BASE`; OpenRouter remains the default when it is unset.
- [x] Make consult fail closed when Aider prints a transcripted auth/config failure or returns no
      visible answer, instead of counting success from process exit alone. → `_aider_answer_ok`
      (shell) / `aider_answer_ok` (py) downgrade an exit-0 aider run to `[FAIL]`.
- [x] Record the visible-content minimum for the characterized local model so consult does not default
      to a token budget that routinely yields empty `content`. → consult does not override Aider's
      token budget; instead it now **detects and fails** the empty-content case at collection time, and
      the `reasoning_content`/empty-content caveat is documented in code comments + spike 0.1 above.
- [x] Add tests for:
      missing config, auth/config transcript failure, successful consult invocation, and the existing
      non-LM-Studio default path staying intact. → `test/consult.sh` cases 8–11 (+ existing 1/7).

### QA checklist — Phase 1

- [x] A real consult invocation against LM Studio returns visible content and is counted as success.
      (Seam + success-counting proven with a stub — case 11; a *live* LM Studio run is the Phase 4
      operator proof, consistent with the repo's network-free test idiom.)
- [x] A missing or bad LM Studio config fails loudly and is counted as failure, not "answered."
      (cases 8/9/10 — no-key, exit-0 auth-error transcript, exit-0 empty answer all → exit 5.)
- [x] Existing default consult paths remain byte-identical unless LM Studio is explicitly selected.
      (OpenRouter path unchanged; cases 1/7 still green.)
- [x] The doc or code comments explain the `reasoning_content` / empty-visible-content caveat.

## Phase 2 — Reuse the Aider relay seam for LM Studio turns

Purpose: prove build/review turns on LM Studio by reusing the existing Aider turn shim instead of
inventing a second containment path.

### Checklist

- [ ] Decide and document the lane surface:
      whether LM Studio is selected by explicit Aider env/config, by a named lane alias, or both.
- [ ] Thread the LM Studio base URL/model/auth contract through the existing Aider turn shim without
      changing current Aider/OpenRouter behavior by default.
- [ ] Verify review-only and single-file edit turns against LM Studio under the current containment
      rules before attempting broader swarm usage.
- [ ] Make startup/config failures happen before the lane is allowed to present a false "successful"
      turn result.
- [ ] Add tests covering config pass-through and failure behavior at the shim boundary.

### QA checklist — Phase 2

- [ ] One LM Studio-backed review-only turn completes under containment with no off-lane edits.
- [ ] One narrow LM Studio-backed build/edit turn completes under containment and commits only the
      allowlisted artifact.
- [ ] Bad LM Studio config fails before the harness reports a successful turn.
- [ ] Existing Aider/OpenRouter turns still behave the same when LM Studio is not selected.

## Phase 3 — Teach swarm-preflight and marathon routing about the lane

Purpose: make the lane plannable without making it the default or pretending it is interchangeable
with Codex or agy for every task.

### Checklist

- [ ] Extend swarm-preflight lane planning so LM Studio can be selected explicitly as an opt-in lane.
- [ ] Keep the planner conservative:
      no automatic LM Studio assignment by default until a live relay proof exists and the caveats are documented.
- [ ] Document what the planner assumes about the lane:
      token budget sensitivity, no guaranteed tool use, and model-specific response-shape variability.
- [ ] Add dry-run or fixture coverage showing the lane appears correctly in planner output and routing.

### QA checklist — Phase 3

- [ ] A preflight packet can name the LM Studio-backed lane explicitly.
- [ ] Planner output remains unchanged for users who do not select LM Studio.
- [ ] Dry-run or test coverage proves the lane is routed and labeled correctly in planner output.

## Phase 4 — Hardening, docs, and live operator proof

Purpose: finish with proof, not with plausible configuration. This phase closes the gap between
"the lane exists" and "the lane is safe enough to keep around."

### Checklist

- [ ] Add operator-facing docs for LM Studio setup:
      base URL, model naming, dummy-key requirement, and the heavy-reasoning-token caveat.
- [ ] Add one opt-in smoke or characterization path for a real LM Studio backend, self-skipping when
      the endpoint is unavailable.
- [ ] Run one end-to-end operator proof covering:
      consult, one relay turn, and one planner/preflight surface using the same LM Studio contract.
- [ ] Record the live proof results back into this doc, including any caveats that remain open after implementation.
- [ ] Decide whether any remaining model-specific instability means the lane should stay explicitly
      experimental in docs and planner language.

### QA checklist — Phase 4

- [ ] Docs are sufficient for a cold operator to configure the lane without reading chat history.
- [ ] The opt-in live smoke path self-skips cleanly when LM Studio is unavailable and passes when it is available.
- [ ] One end-to-end operator proof is recorded back into this doc with concrete commands and outcome.
- [ ] `utils/pdda/pdda.sh run` is green after the doc + roadmap updates for the finished implementation state.
