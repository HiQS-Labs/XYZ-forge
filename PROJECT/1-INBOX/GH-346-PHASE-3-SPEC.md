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
phases: 4
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

### 1. A preferences file the operator owns — inside `device_config.json`, not beside it

**Revised after QA.** The first draft proposed a new `~/.xyz/model-prefs.yml`. agy pushed back and
was right, for a reason stronger than "one file is tidier": `~/.xyz/device_config.json` **already
is** a single-profile version of exactly this feature —

```json
{ "default_harness": "dsh", "default_gateway": "openrouter",
  "default_model": "deepseek/deepseek-v4-pro", "default_reasoning_effort": "high" }
```

— so a second file would have made the eleventh curated list this issue exists to stop. Profiles
become a `profiles` block in that same file, and the existing `default_*` keys stay valid as the
unnamed fallback profile. No migration, no break.

```json
{
  "default_harness": "dsh",
  "default_gateway": "openrouter",
  "default_model":   "deepseek/deepseek-v4-pro",

  "profiles": {
    "glm 5.3 max":  { "harness": "commandcode", "gateway": "openrouter",
                      "model": "zai-org/glm-5.3", "effort": "max" },
    "qwen 3.8 max": { "harness": "dsh",         "gateway": "openrouter",
                      "model": "qwen/qwen3.8-max" }
  },
  "default_profile": "glm 5.3 max"
}
```

**On the `gateway: openrouter` for Command Code.** QA flagged this as contradicting the operator's
"CommandCode → GLM 5.3 max". It does not — that phrasing was two-element shorthand. Command Code
reaches GLM through OpenRouter, confirmed two ways: the declared registry
(`models.gateway = openrouter` for `zai-org/GLM-5.3`) and live telemetry from this issue's own QA
relay (`invocation_logs`: `commandcode | zai-org/glm-5.3 | openrouter`, 2 rows). The three-element
path is the real one; the operator simply did not need to say it.

JSON, not YAML, and parsed by `device_config.py`, which already loads this file. That removes the
second QA finding entirely: `resolve-model-alias.sh` is a **flat** `alias: canonical` line parser
(`:63-74`) and could never have read a nested structure. It is used here for **name normalization
only** — never for reading the profile file.

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
3. **`harnesses.db` — the `models` table ONLY, never `invocation_logs`.** *Narrowed after QA.*
   The first draft proposed routing partly on "this model has actually run on this harness before".
   agy rejected that and the live data proves the point: `commandcode` carries a two-row
   `stealth/ox-alpha` experiment that would have been promoted to a routing default. **History is
   not policy.** Tier 3 reads only the *declared* registry (`models.gateway`), which is curated on
   purpose. agy recommended dropping tier 3 outright; it is kept, narrowed, because the operator
   asked for the DB to feed dispatch and the unsoundness was entirely in the `invocation_logs` half.
4. **The shim's current literal default** — unchanged. The floor, always.

**Every tier is skippable, INCLUDING on a parse error.** *Hardened after QA.* The first draft said
"a missing preferences file falls through" and never said what a **malformed** one does — and a
config parse error that propagates would halt the resolver and block the turn, which is strictly
worse than today. Explicitly: a missing file, malformed JSON, an unknown key, an unmatched name, an
absent/locked/corrupt `harnesses.db` — **each is caught, reported on stderr, and falls through**.
Tier 4 is exactly today's behavior. No tier can block a turn, and no fallback is silent — that is
the Phase 0 "log the swallow" lesson, where two silent handlers hid a whole-lifetime bug. This is the Phase 1 pattern (`model_alias.py`), which QA endorsed, applied
one layer up.

### 4. The cache — its own phase (3d), not folded into the resolver

*Re-scoped after QA:* agy called the cache orthogonal to the resolver and was right — they share no
code and bundling them would have made 3a un-shippable until both were done. Proposal A: hash the resolution inputs
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

### Phase 3a — the profiles block and the resolver (no dispatch change, no cache)

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
      for **all 8 gateways, with the model var BOTH set and unset**. *QA caught the gap:* the first
      draft asserted only the unset case, leaving the tier-1 override path unproven. This is the
      proof that closes the declared-not-dispatched caveat the ROI checkpoint is forbidden to tick
      until then
- [ ] **Proof:** the resolver cache measurably removes re-resolutions — the checkpoint's own metric

### Phase 3d — the resolution cache (independent of 3a-3c)

- [ ] Hash the resolution inputs; skip the vendored-vs-live diff on a match
- [ ] Invalidate on `.xyz/` version marker or config mtime change
- [ ] **Proof:** the checkpoint metric — re-resolutions per session drops measurably

## Design questions — answered by QA (agy, 2026-09-01)

1. **Separate prefs file vs `device_config.json`?** → **`device_config.json`.** Accepted and
   applied above. Its `default_harness`/`default_gateway`/`default_model` keys are already a
   one-profile version of this feature, so a second file would have been the eleventh curated list.
2. **Route on `invocation_logs`?** → **No.** Accepted. Tier 3 now reads only the declared `models`
   table. Live data proved the objection: a two-row `stealth/ox-alpha` experiment would have become
   a routing default.
3. **Does `effort` belong in a profile?** → **Only namespaced per gateway**, since not every
   gateway has one (`COMMANDCODE_REASONING_EFFORT`, `AGY_REASONING_EFFORT`; codex has none).
   Accepted: `effort` is optional per profile and emitted only for gateways that accept it.
4. **Deprecate the 8 `*_MODEL` env vars?** → **No.** Keep them permanently as tier 1 overrides.
   Deprecating would break existing scripts while providing nothing better. The spec already
   intended this; it is now explicit — 3c is a *fallback* change, not a migration.

## Findings recorded but NOT adopted

**"Drop tier 3 entirely."** Not taken. The unsoundness agy identified was real but confined to the
`invocation_logs` half; narrowing tier 3 to the declared `models` table removes it. Dropping the
tier outright would also refuse the operator's explicit instruction that `harnesses.db` should feed
dispatch where reversible — and it is reversible in this shape.

**"The YAML example routes GLM 5.3 to OpenRouter instead of Command Code."** Wrong on the facts.
Command Code reaches GLM *through* OpenRouter; verified in both the declared registry and live
telemetry. The operator's two-element phrasing was shorthand, not a different path.

**"Degrading to tier 4 makes the system silently do the wrong thing."** The concern is fair but the
remedy is loud fallback, not abandoning the tier: every fallback reports which tier answered, on
stderr and via `--explain`. Reversibility (can the code change be undone?) and surprise (does the
fallback announce itself?) are separate properties; this spec now provides both.

## Still open for the operator

- Should a profile be able to pin a **reviewer** as well as a builder? Today reviewer eligibility is
  a separate gate (codex/agy only, post-GH-346). Out of scope as written.
