---
title: GH-346 Phase 3 — one preferred-model name resolves to harness, gateway, and model
status: Proposed (1-INBOX — gated on the Phase 2 ROI checkpoint)
created: 2026-09-01
updated: 2026-09-01
owner: noel
gh_issue: 346
source: https://github.com/HiQS-Labs/XYZ-forge/issues/346
doc_type: feature
complexity: 6
risk: 5
effort: 5
phases: 3
ratings_provisional: true
non_goals:
  - Replacing any shim's execution or containment logic. Phase 3 changes only what a shim is TOLD
    to run, never how it runs it.
  - Making harnesses.db a required dependency of dispatch. See "Reversibility" — it has no merge
    resolver, so a hard dependency is a one-way door during a conflicted merge.
  - A live model-catalog fetch on the turn path. Refresh stays an explicit operator step.
related:
  - GH-346 Phases 0-2 (the repair this builds on)
  - GH-174 (harnesses.db + the telemetry seam Phase 3 finally makes readable)
goal: >
  One name — "glm 5.3 max" — resolves to a complete harness -> gateway -> model path, from a
  preferences file the operator owns, with a full manual path always able to override it, and with
  every failure falling back to today's behavior rather than blocking a turn.
---

# GH-346 Phase 3 — the lookup the issue actually asked for

> **Gated.** Do not start before the Phase 2 ROI checkpoint returns a go. Phases 0–2 were repair:
> they made the existing telemetry honest and made two shipped gateways dispatchable. They
> delivered **no user-facing capability**. Everything below is the capability.

## The ask, in the operator's words

> "I want a preferences file that specifies a single model name that maps to my preferred harness,
> router, and model unless I provide the full harness → gateway → model path as a manual override.
> So if I say I want to do a `relay-xyz with Qwen 3.8 max` it knows to use DeepSeek harness →
> OpenRouter → Qwen 3.8 max. Or if I say `relay-xyz with GLM 5.3 max` it knows to use CommandCode →
> GLM 5.3 max."

Today that costs three separate lookups, none cached, none reading each other:

| Layer | Where it lives now | How you find it |
|---|---|---|
| harness | `find-harness.sh` | re-resolved every shell; `$HARNESS` does not survive |
| gateway | each shim's own `*_AGENT` / `*_MODEL` env contract | **read the source** |
| model | `openrouter-model-aliases.yml` (11 static aliases, OpenRouter lane only) **or** `cmd --list-models` (62, live, Command Code only) | depends which gateway you already picked |

`harnesses.db` looks like it should answer this and cannot: nothing in the dispatch path reads it.
It feeds documentation only.

## What Phase 3 delivers

### 1. A preferences file the operator owns

`~/.xyz/model-prefs.yml`, beside the existing `~/.xyz/device_config.json` (same seam, same
3-tier discipline — env, then file, then shipped defaults).

```yaml
# One name -> the whole path. The name is what you type; everything else is inferred.
profiles:
  "glm 5.3 max":
    harness: commandcode          # -> relay-automation/commandcode-turn.sh, COMMANDCODE_AGENT
    gateway: openrouter
    model:   zai-org/glm-5.3
    effort:  max                  # -> COMMANDCODE_REASONING_EFFORT + `--effort max`

  "qwen 3.8 max":
    harness: dsh                  # -> deepseek-turn.sh, DEEPSEEK_AGENT
    gateway: openrouter           # -> DEEPSEEK_PROVIDER=openrouter, OPENROUTER_API_KEY
    model:   qwen/qwen3.8-max

default: "glm 5.3 max"            # what an unqualified request resolves to
```

The two entries above are the operator's own examples and ship as the seed file.

### 2. One resolver, one command

```bash
resolve.sh "glm 5.3 max" --env      # prints the complete export block for that path
resolve.sh --list                   # every profile, and what each resolves to
resolve.sh --explain "qwen 3.8 max" # which tier answered, and why
```

`--env` emits the harness root **and** the chosen gateway's specific env contract **and** the
resolved model id — replacing today's "locate script, eval, cd, then go read source to find the
right env var name" with one call. This is proposal B from the issue body, with the preferences
file as its input.

### 3. Resolution order — explicit beats preferred beats known beats shipped

1. **Full manual path** — `--harness/--gateway/--model`, or the existing `*_AGENT` + `*_MODEL` env
   vars. Always wins, never second-guessed. This is the operator's stated override.
2. **A named profile** from the preferences file, matched through the *existing*
   `resolve-model-alias.sh` normalizer, so `"GLM5.3 max"`, `"glm 5.3 max"` and `"GLM 5.3 Max"` are
   one entry — no new fuzzy matcher.
3. **`harnesses.db`** — the registry already knows which harness a model has actually run on
   (`invocation_logs` proves it empirically; `models` carries the gateway). This is what "make the
   DB feed dispatch" means, and it is the only tier that is new plumbing.
4. **The shim's current literal default** — unchanged. The floor, always.

**Every tier is skippable.** A missing preferences file, an unmatched name, an absent or corrupt
`harnesses.db` — each falls through to the next tier, and tier 4 is exactly today's behavior. No
tier can block a turn. This is the Phase 1 pattern (`model_alias.py`), which QA endorsed, applied
one layer up.

### 4. The cache

Proposal A, subsumed here rather than built separately: hash the resolution inputs
(`$XYZ_HARNESS`, cwd, `.xyz/` presence + version marker, prefs-file mtime) and skip the
vendored-vs-live diff when the hash matches. Fixes the "`find-harness.sh` re-runs a dozen times a
session and re-prints the same vendored-diff warning" friction the issue opened with.

## Reversibility — the reason tier 3 is a lookup and not a dependency

`harnesses.db` is a tracked binary (`.gitattributes:37`, `-diff linguist-generated=true`) with a
`harnesses.sql` dump beside it — the same trio shape as `releases.db`, **but with one difference
that decides this design: `releases.db` has `utils/releases-merge-resolve.sh` and `harnesses.db`
has no merge resolver at all.**

So:

- **As a fallback tier (this spec): reversible.** Purely additive. Reverting is deleting one lookup
  call; behavior returns bit-for-bit to today. A conflicted, missing, or corrupt DB degrades to the
  shim's literal default — the same thing that happens now.
- **As a hard dependency (rejected): a one-way door.** A conflicted binary DB mid-merge would stop
  every turn on the machine, with no one-command resolver to get out. The blast radius is "no agent
  can run" and the exit is manual SQLite surgery.

Tier 3 therefore reads the DB and never requires it. If Phase 3 later wants a hard dependency, the
prerequisite is a `harnesses-merge-resolve.sh` first — that is a separate, cheap piece of work and
it should not be smuggled in here.

## What Phases 0–2 taught that this design obeys

- **Derive, never curate.** The gateway set lived in TEN hand-maintained allowlists; three were
  invisible to careful reading and only found by a test failing. Phase 3 must not add an eleventh:
  the resolver reads the lane set from `route_agent`'s own source, the way
  `test/gh346-gateway-allowlists.sh` now does.
- **Enhancement over a floor, never a swap.** `resolve-model-alias.sh` exits 1 with no output on a
  miss and has no canonical-slug passthrough — a bare call blanks every canonical id. Same
  discipline here: every tier falls through, none replaces.
- **Verify, do not claim.** Phase 0's checkbox 0.5 was ticked without being run, which is how three
  shims with dead telemetry looked fixed. Each phase below names the command that proves it.
- **Log the swallow.** Two silent `except`/`check=False` paths hid a whole-lifetime bug. Any new
  fallback here reports which tier answered (`--explain`), never falls back in silence.

## Phases

### Phase 3a — the preferences file and the resolver (no dispatch change)

- [ ] `~/.xyz/model-prefs.yml` schema + a seeded file carrying the operator's two named profiles
- [ ] `resolve.sh` with `--env`, `--list`, `--explain`; name matching delegated to
      `resolve-model-alias.sh`, not reimplemented
- [ ] Tiers 1, 2 and 4 only — tier 3 (`harnesses.db`) deliberately deferred to 3b
- [ ] `--explain` names the answering tier for every resolution, including fallbacks
- [ ] **Proof:** `resolve.sh "qwen 3.8 max" --env` emits a DeepSeek → OpenRouter → qwen/qwen3.8-max
      block, and `resolve.sh "glm 5.3 max" --env` a Command Code → GLM 5.3 block, with no shim edited

### Phase 3b — harnesses.db as tier 3, strictly as a fallback

- [ ] Read harness + gateway for a model from `models` / `invocation_logs`
- [ ] Fail-soft on missing, locked, corrupt, or merge-conflicted DB — degrade to tier 4, say so
- [ ] **Proof:** a test that deletes the DB, and another that corrupts it, and asserts turns still
      resolve and run via tier 4
- [ ] **Not in scope:** making the DB required. That needs `harnesses-merge-resolve.sh` first.

### Phase 3c — the shims consume the resolver

- [ ] Each shim's dispatch default comes from the resolver instead of its own literal
- [ ] The literal remains as tier 4 inside the resolver — deleted from nowhere
- [ ] The 8 `*_MODEL` env var names keep working (deprecation path, not a break)
- [ ] **Proof:** `test/gh346-telemetry-row-written.sh` extended — telemetry model == dispatched model
      for **all 8 gateways with the var unset**, which closes the declared-not-dispatched caveat QA
      raised and that the ROI checkpoint is forbidden to tick until then
- [ ] **Proof:** the resolver cache measurably removes re-resolutions — the checkpoint's own metric

## Open questions for QA

1. Is `~/.xyz/model-prefs.yml` the right home, or should profiles live inside the existing
   `device_config.json` rather than adding a second file to the same directory?
2. Tier 3 reads `invocation_logs` (what has actually run) as well as `models` (what is declared).
   Is "this model ran on this harness before" sound evidence for routing, or does it risk pinning a
   one-off experiment as a default?
3. Does `effort` belong in the profile? It is per-gateway (`--effort max` for Command Code,
   `AGY_REASONING_EFFORT` for agy) and not every gateway has it.
4. Is 3c's deprecation of 8 env var names doable without a breaking change, or does that need its
   own phase?
