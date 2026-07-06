---
gh_issue: 147
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/147
title: LM Studio local-LLM lane for consult, relay, and swarm
status: Proposed (1-INBOX — not yet active)
created: 2026-07-05
updated: 2026-07-05
owner: noel
doc_type: feature
complexity: 4
risk: 3
effort: 4
phases: 5
ratings_provisional: true
non_goals:
  - Not replacing the existing Codex, Claude, agy, or Aider/OpenRouter lanes
  - Not making LM Studio the default path for any existing workflow
  - Not assuming every LM Studio model supports the same response shape, tool use, or token accounting
related:
  - relay-automation/consult.sh
  - relay-automation/aider-turn.sh
  - relay-automation/marathon-drive.sh
  - relay-automation/relay-drive.sh
  - utils/py/consult.py
  - utils/py/swarm_preflight.py
---

# GH-147 · LM Studio local-LLM lane for consult, relay, and swarm

## Summary
Add first-class support for using a local LM Studio OpenAI-compatible endpoint as an XYZ model lane, starting from a server like `http://127.0.0.1:1234` with a loaded model such as `agents-a1`.

## Why
Today the repo has fixed named lanes for Codex, Claude, agy, and Aider/OpenRouter. Consult can run multiple advisors, but there is no local OpenAI-compatible lane for LM Studio. Relay and swarm orchestration likewise route only known agents/shims.

## Desired outcome
- Consult can query an LM Studio-backed model directly.
- Relay can run a local-LLM builder/reviewer lane under the same containment rules.
- Swarm preflight and marathon planning can assign work to that lane explicitly.
- The integration is additive and default-off.

## Acceptance criteria
- New documented config for LM Studio base URL, model id, and auth behavior.
- A runnable consult path against an OpenAI-compatible local endpoint.
- A relay turn shim or equivalent generic OpenAI-compatible lane for build/review turns.
- Swarm/marathon routing updated to recognize the lane.
- Tests cover missing endpoint/model config, successful consult invocation, and routing/containment expectations.
- Docs explain the reasoning-token caveat some local models expose (e.g. `reasoning_content` before visible `content`).

## Notes
Observed locally on 2026-07-05: LM Studio at `http://127.0.0.1:1234` responded to `/v1/models` with `agents-a1`, and `/v1/chat/completions` succeeded when given enough token budget to emit visible content after reasoning tokens.

Reversibility: **Easy** for the Phase 0 spike itself; likely **Costly** if the implementation grows into a new native relay/swarm lane rather than reusing the existing Aider seam. The spike is just characterization and a path choice. The shipped feature, if it touches consult, turn shims, swarm routing, and tests, is broader than a trivial revert.

Blast radius: zero for existing workflows by default if this remains opt-in. The shared surfaces that would move once implementation starts are `consult`, the existing Aider-backed build/review path, relay turn routing, and swarm/marathon lane assignment. Existing Codex/Claude/agy/Aider defaults must stay byte-identical unless an LM Studio endpoint or lane is explicitly selected.

Implementation note: Aider is a credible first bridge here, not just a separate idea. Aider already supports
LM Studio directly and, more generally, OpenAI-compatible endpoints, so the existing Aider lane may be
able to provide an earlier LM Studio-backed build/review path before XYZ grows a bespoke direct
consult/relay client. That does not remove the value of a native XYZ lane, but it does mean the
shortest durable path may be:

- first: verify whether the existing Aider integration can target LM Studio cleanly for build/review
- then: decide whether consult and relay should also gain a direct non-Aider OpenAI-compatible lane

Important caveat: if we use Aider as the bridge, LM Studio may still need a dummy API key value even
when the server itself does not require auth, because the client can fail on an empty bearer token.

## Phase 0 — Technical spike baseline

Purpose: establish the smallest truthful baseline before choosing architecture. This spike is not
“ship LM Studio support”; it is “prove which integration seam is real, cheap, and safe in this repo.”

### Questions this spike must answer
- Can the current Aider lane already reach LM Studio cleanly enough to count as a usable baseline for
  build/review turns?
- If not, is the blocker transport, model behavior, Aider config, containment, or relay orchestration?
- For direct XYZ integration, is `consult` the lowest-risk first slice, or does relay/build routing
  have a cheaper seam?
- Which model behaviors are baseline assumptions versus optional enhancements:
  visible `content`, `reasoning_content`, token usage, tool use, and streaming?

### Checklist
- [x] Reproduce the baseline transport manually against the local LM Studio server:
      `GET /v1/models` and one non-streaming `POST /v1/chat/completions`.
- [x] Record the minimum config needed for Aider to talk to LM Studio in this environment:
      base URL, dummy API key requirement, model name format, and any edit-format caveat.
- [x] Run one narrow Aider proof against LM Studio outside the relay harness first, so transport and
      model behavior are separated from relay containment questions.
- [x] Determine the safest Aider edit format for the target local model in this environment:
      baseline the default, then test `AIDER_FLAGS=--edit-format diff` if the model emits unusable
      whole-file or malformed edits. Record which format, if any, is automation-safe for `agents-a1`.
- [x] Characterize one direct non-Aider call path for `consult`:
      request shape, response fields, and how empty visible `content` behaves when reasoning tokens are present.
- [x] Compare the two candidate first seams:
      `Aider -> LM Studio` versus `direct consult -> LM Studio`, and write down which is the recommended
      Phase 1 starting point and why.
- [x] Write the spike findings back into this doc with exact commands, observed outputs, and concrete
      follow-on recommendations.

### Deliverables
- [x] A short “baseline findings” subsection added to this doc.
- [x] A recommended first implementation seam:
      `Aider bridge first`, `direct consult first`, or `stop — local-model contract too unstable`.
- [x] A clear list of unknowns that remain after the spike, so later phases do not pretend the spike
      resolved more than it did.

### Baseline findings (2026-07-05)

#### 1. Manual LM Studio transport is real, but `agents-a1` can spend the whole completion budget on reasoning

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
- At `max_tokens: 128`, the response ended with `finish_reason: "length"`, `message.content: ""`, and only `reasoning_content`; usage reported `completion_tokens_details.reasoning_tokens: 127`.
- At `max_tokens: 512`, the same prompt returned visible content (`LM Studio baseline OK`) with `finish_reason: "stop"`, but still consumed heavy reasoning budget first (`reasoning_tokens: 157`, `completion_tokens: 164`).

Implication:

- A direct XYZ consult path must treat `reasoning_content` and empty visible `content` as a first-class failure mode, not an edge case.
- Transport compatibility alone is not enough; low token budgets can produce a formally successful response with no user-visible answer.

#### 2. Minimum Aider config for LM Studio in this environment

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

- Aider 0.86.3.dev53+g5dc9490bb recognized the model as `openai/agents-a1`.
- Omitting `--openai-api-key` failed client-side with `litellm.AuthenticationError ... api_key client option must be set`, even though raw LM Studio `curl` calls worked without auth.
- A dummy non-empty key is therefore required at the client layer for Aider in this environment.
- The default format reported by Aider for this model was `whole edit format`.

#### 3. Narrow Aider proof outside the relay harness succeeded

Consult-style proof:

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

- Aider returned the expected visible answer and printed token counts.

Edit proof:

```bash
tmpdir=$(mktemp -d)
cd "$tmpdir"
git init -q
printf 'alpha\n' > note.txt
git add note.txt
git -c user.name=Spike -c user.email=spike@example.com commit -qm init

aider \
  --model openai/agents-a1 \
  --openai-api-base http://127.0.0.1:1234/v1 \
  --openai-api-key dummy \
  --yes-always --no-auto-commits --no-gitignore \
  --no-check-update --no-analytics --no-show-model-warnings \
  --no-stream --map-tokens 0 \
  note.txt \
  --message 'Change note.txt so it contains exactly beta on one line.'
```

Observed:

- Default `whole` mode succeeded on the narrow edit: Aider emitted a diff-style answer, applied it, and `note.txt` became `beta`.
- Re-running the same proof with `--edit-format diff` also succeeded.

Implication:

- For `agents-a1`, the shortest truthful statement is: default `whole` is not disproven by this spike, and `--edit-format diff` is also viable.
- Unlike the confirmed OpenRouter models in GH-118, this spike did not reproduce an edit-format failure on `agents-a1`.

#### 4. Repo seam readout: the Aider lane is partly there already; consult/swarm still need real adaptation

Code findings:

- `relay-automation/consult.sh:199-213` already exposes an Aider advisor path, but it is hard-wired to `OPENROUTER_API_KEY` and does not pass an LM Studio base URL.
- `utils/py/consult.py:186-196` mirrors that path: it accepts `m == "aider"` but assumes OpenRouter auth semantics and default model naming.
- `utils/py/aider-turn.py:14-115` already provides a dedicated Aider relay shim with allowlist, token ownership, worktree isolation, and `AIDER_FLAGS` passthrough.
- `relay-automation/marathon-drive.sh:249-255` already recognizes `aider*` agent ids in `route_agent`.
- `utils/py/swarm_preflight.py:178-207` still plans only `codex_lane` and `agy_lane`; there is no explicit local-LLM lane assignment today.

Observed consult-path behavior:

```bash
OPENROUTER_API_KEY=dummy \
AIDER_MODEL=openai/agents-a1 \
AIDER_OPENAI_API_BASE=http://127.0.0.1:1234/v1 \
python3 utils/py/consult.py \
  --prompt 'Reply with exactly: CONSULT LM STUDIO OK' \
  --models aider
```

- This produced an Aider transcript containing `litellm.AuthenticationError ... api_key client option must be set`, because Aider still wanted `OPENAI_API_KEY`.
- `consult.py` still reported `consult: 1 answered, 0 failed`, because it only looked at the process exit code; Aider exited 0 while printing the auth error transcript.

Re-run with both `OPENROUTER_API_KEY=dummy` and `OPENAI_API_KEY=dummy` succeeded against LM Studio.

Implication:

- The current repo does not yet have a truthful LM Studio consult path by config alone; it needs at least a small auth/base-URL generalization.
- There is also a sharp false-green risk in consult accounting: an Aider auth/config failure can currently be counted as a successful answer.

#### 5. Recommended Phase 1 seam

Recommendation: `Aider bridge first`.

Why:

- It already has the narrowest real code path for build/review turns: `aider-turn.py` exists, `marathon-drive.sh` already recognizes `aider*`, and consult already has an Aider advisor branch.
- The remaining work is mostly configuration generalization and routing truthfulness: support an OpenAI-compatible base URL + model, accept the right dummy-key/auth contract, and make consult fail closed when Aider prints a transcripted auth error.
- A direct non-Aider consult lane is still worthwhile later, but it would only solve consult. It does not automatically unlock relay/build/swarm, and the repo already has an Aider seam where relay containment lives.

#### 6. Unknowns still open after the spike

- The relay harness itself was not driven end-to-end against LM Studio; this spike proved Aider transport and edits outside the harness, not full relay containment behavior on a live lane.
- `agents-a1`'s heavy reasoning-token usage means timeout and token-budget defaults may need tuning in both consult and relay turns.
- The current consult/Aider path has an auth-variable mismatch (`OPENROUTER_API_KEY` gate vs the actual `OPENAI_API_KEY` the client wanted here) and a false-green accounting bug when Aider exits 0 with an auth error transcript.
- This spike only proved a narrow single-file edit. It did not establish whether `whole` remains reliable on larger diffs, multi-file edits, or long-running relay prompts.
- Streaming, tool use, and token-usage consistency for LM Studio models remain uncharacterized.

### QA checklist
- [x] The spike proves at least one real end-to-end success path against the local LM Studio server,
      not just theoretical compatibility.
- [x] The findings separate transport success from automation-readiness; a model that answers once is
      not automatically safe for relay/swarm.
- [x] Any recommendation names the failure mode explicitly:
      reasoning-budget exhaustion, missing usage stats, unsupported edit format, auth quirks, or containment mismatch.
