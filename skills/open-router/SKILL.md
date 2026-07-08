---
name: open-router
description: >-
  Resolve a colloquial OpenRouter model name (e.g. "GLM 5.2", "Nemotron Ultra 3")
  to its canonical `provider/slug[:variant]` id BEFORE setting `AIDER_MODEL` for
  `aider-turn.sh`, `consult.sh --models aider`, or `DEEP_RESEARCH_OPENROUTER_MODEL`
  for `deep-research.mjs --provider openrouter`. Checks the local alias table
  (`relay-automation/openrouter-model-aliases.yml` via `resolve-model-alias.sh`,
  GH-120) first — zero network calls — and only falls back to the live
  `openrouter.ai/api/v1/models` catalog on a miss, then writes the new alias back
  so the next lookup is instant. Use whenever the operator names a model
  informally for an OpenRouter-routed lane and asks to configure it, or when you
  are about to run `aider --list-models` / curl the OpenRouter API to find a slug
  — check the alias table first instead. NOT for choosing between models or
  picking a model for a task; only for resolving a name you already have to its
  canonical id.
---

# open-router — fast OpenRouter model-name resolve

Turns a colloquial model name into the canonical slug an OpenRouter-routed lane
needs (`AIDER_MODEL=openrouter/<slug>`), without probing.

## Step 1 — check the local alias table first (always)

```bash
relay-automation/resolve-model-alias.sh "<name>"
```

- Exit 0: canonical slug printed on stdout (e.g. `z-ai/glm-5.2`). Use it directly:
  `AIDER_MODEL="openrouter/$(relay-automation/resolve-model-alias.sh "<name>")"`.
- Exit 1: no match — go to Step 2. Do **not** reach for `aider --list-models` or a
  live `curl` first; that's the slow path this skill exists to skip.

Matching is fuzzy (case/punctuation/hyphen/whitespace-insensitive, token-order
insensitive, substring fallback) — try the name as given before assuming a miss.

## Step 2 — only on a miss: query the live catalog

```bash
curl -s https://openrouter.ai/api/v1/models | grep -i '"id":"<partial-name>'
```

Find the exact `provider/slug[:variant]` id. Confirm it's the model the operator
meant (check context length / pricing / provider if there's ambiguity).

## Step 3 — write the alias back (always, once resolved via Step 2)

Append one line to `relay-automation/openrouter-model-aliases.yml`:

```
<colloquial name>: <canonical-slug>
```

Then add a matching assertion in `test/model-alias.sh` and run it to confirm:

```bash
bash test/model-alias.sh
```

This is the whole point of the skill: every miss should shrink the miss set for
next time, not repeat the probe.

## Known adjacent issue — edit-format quirk (GH-118)

Many OpenRouter-proxied models aren't in Aider's `model-settings.yml` and default
to the `whole` edit format, which some models don't reliably produce (confirmed:
GLM-5.2, Nemotron Ultra 3). If a driven turn reports "no tracked changes" despite
a seemingly valid model response, set `AIDER_FLAGS=--edit-format diff` — see
`relay-automation/README.md`'s "Known OpenRouter edit-format quirks" section.

## What this skill does NOT do

- Does not pick which model to use for a task — that's the operator's call.
- Does not touch `AIDER_FLAGS`, edit-format, or any other Aider config beyond the
  model id itself.
- Does not run the turn — it only resolves the id you'll pass into
  `AIDER_MODEL` / `DEEP_RESEARCH_OPENROUTER_MODEL`.
