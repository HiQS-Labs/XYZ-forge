---
title: GH-346 Phase 3 — one preferred-model name resolves to harness, gateway, and model
status: Proposed (1-INBOX — gated on the Phase 2 ROI checkpoint)
created: 2026-09-01
updated: 2026-09-01 (QA round 2)
owner: noel
gh_issue: 346
source: https://github.com/HiQS-Labs/XYZ-forge/issues/346
# roadmap_exempt: GH-346 is already parked as a single roadmap row
# (rmi-01M1CREBCRN64CRS5Z4T18JGJA) pointing at the capture doc,
# GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md. This is the phase-3 design document under that
# same row, not a second intake -- parking it separately would double-count one issue in the
# ledger and split its ratings across two rows. Same convention the MARATHON-PLAN docs use.
roadmap_exempt: true
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

...and, clarifying scope after the first QA round:

> "In lieu of the preference file, I was willing to add aliases to the canonical current config
> file." — so `device_config.json` was the operator's own proposal, not a QA correction.
>
> "For now, don't add any new feature to profile-pin a reviewer in the build → review path. I am
> fine leaving the defaults as agy ↔ codex."
>
> **"My main use case is around the relay-xyz reviewer alias."**

### That last line is the spec's centre of gravity

The target is **naming the reviewer for a `/relay-xyz` review turn** — the Path A flow. Today that
means hand-assembling this, which is exactly what was typed by hand four times during this issue's
own QA:

```bash
COMMANDCODE_AGENT=commandcode ALLOW_PATHS="" \
COMMANDCODE_MODEL="zai-org/glm-5.3" COMMANDCODE_REASONING_EFFORT="max" \
COMMANDCODE_FLAGS="--no-session --skip-onboarding --no-auto-update --yolo --effort max" \
relay-automation/relay-drive.sh --relay-file "$RELAY" --relay-task "$TASK" \
  --agent-cmd relay-automation/commandcode-turn.sh --review-once
```

After Phase 3, that is:

```bash
eval "$(resolve.sh 'glm 5.3 max' --env)"     # harness + gateway + model + flags, one call
relay-automation/relay-drive.sh --relay-file "$RELAY" --relay-task "$TASK" \
  --agent-cmd "$RELAY_AGENT_CMD" --review-once
```

**Explicitly OUT of scope, per the operator:** profile-pinning a reviewer in the marathon
build → review path. The marathon reviewer gate keeps its post-GH-346 defaults (codex/agy) and is
not touched. A profile names *which worker runs a relay review turn*, never *who is allowed to
review a marathon phase*.

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

**Revised.** The first draft proposed a new `~/.xyz/model-prefs.yml`. That was a mistake on two
counts: the operator had already offered to put aliases in the canonical config file, and QA
independently reached the same conclusion. The reason is stronger than "one file is tidier" —
`~/.xyz/device_config.json` **already is** a single-profile version of exactly this feature —

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
    "glm 5.3 max":  { "harness": "commandcode", "gateway": "self",
                      "model": "zai-org/glm-5.3", "effort": "max" },
    "qwen 3.8 max": { "harness": "dsh",         "gateway": "openrouter",
                      "model": "qwen/qwen3.8-max" }
  },
  "default_profile": "glm 5.3 max"
}
```

**`gateway` is mandatory, and `"self"` is a real value.** *Added after QA round 2.* The first
revision wrote `"gateway": "commandcode"` — better than `openrouter`, but it left the shape able to
express `{ "harness": "commandcode", "gateway": "openrouter" }`, which is not a configuration, it is
a lie waiting to be logged. The resolver would emit `COMMANDCODE_GATEWAY=openrouter`, `cmd` would
ignore it and route through its own catalog as always, and the telemetry row would record a gateway
that nothing used.

That is the *third* appearance of one defect in this issue: a gateway value asserting a fact about
the run that no dispatch path establishes. It was worth catching here, because rebuilding it inside
the config surface this spec adds — in the issue that exists to remove it — is how it would have
outlived every fix above.

So: a harness that is its own router takes `"gateway": "self"`, and profile validation rejects any
other value for such a lane. Repeating the harness name in the gateway slot is not allowed either;
it reads like a three-element path with two elements filled in, when the truth is that the path has
only two elements.

**On Command Code's gateway — a correction, and how it nearly shipped.** The first draft wrote
`gateway: openrouter` here. That is wrong, and it matters for the data model: **Command Code is
both a harness AND a router.** OpenRouter is only ever a gateway. So the operator's
"CommandCode → GLM 5.3 max" was not two-element shorthand for a three-element path — it *was* the
whole path, because harness and gateway are the same thing on that lane.

The evidence is unambiguous once looked at properly: `commandcode-turn.py` contains **no**
OpenRouter API key, base URL, or routing config of any kind — `cmd` resolves the model from its own
catalog. Contrast `deepseek-turn.py:35-48`, which builds an explicit overlay with
`baseURL: https://openrouter.ai/api/v1` and `OPENROUTER_API_KEY` because it genuinely does route
through one.

QA (agy) flagged this and was **right**; the first revision of this spec overrode the finding and
should not have. The stated justification was live telemetry showing
`commandcode | zai-org/glm-5.3 | openrouter` — but that `openrouter` came from
`gateway=os.environ.get("COMMANDCODE_GATEWAY", "openrouter")`, a hardcoded literal in the shim, not
an observation of anything. **A hardcoded default was cited as evidence** — which is the precise
defect Phase 0 of this issue exists to eliminate, reproduced while arguing against a correct
review. The literal is now fixed to `commandcode`, and the lesson is recorded here rather than
quietly patched: telemetry is only evidence once you have checked that something actually writes it.

Note the `models` table is not wrong to list `openrouter` for `zai-org/GLM-5.3` — that model *is*
reachable through OpenRouter. It says where a model can be reached, not which router a given
harness used. Tier 3 must therefore treat `models.gateway` as a hint for lanes that need a
gateway, never as an override for a harness that is its own router.

JSON, not YAML, and parsed by `device_config.py`, which already loads this file. That removes the
second QA finding entirely: `resolve-model-alias.sh` is a **flat** `alias: canonical` line parser
(`:70-81`) and could never have read a nested structure. It is used here for **name matching only**
— never for reading the profile file.

**How Python reuses the matcher — settled, shipped, and tested.** Round 2's sharpest process
finding was that "reuses `resolve-model-alias.sh` for normalization only" named no mechanism, and
that three implementers would build three different ones: reimplement `normalize`/`squash` in
Python, refactor the bash into a sourceable library, or have Python write a temp flat file and set
`MODEL_ALIASES_FILE`. All three grow a **second matcher**, which is the thing this repo has the
most scar tissue about.

The seam turned out to cost one character. `resolve-model-alias.sh` already took its table from
`$MODEL_ALIASES_FILE`; only its readability guard (`-f`) refused a pipe. That is now `-r`, so:

```bash
printf 'glm 5.3 max: zai-org/glm-5.3\n' \
  | MODEL_ALIASES_FILE=/dev/stdin resolve-model-alias.sh "GLM5.3 Max"
# -> zai-org/glm-5.3
```

The resolver builds that table from the `profiles` keys and pipes it in. All four matching tiers —
normalized, squashed, sorted-token, substring — stay the **single** implementation of colloquial
name matching in the repo, and no parity test is needed because there is no second thing to keep in
parity with.

This change is landed with this revision rather than deferred to 3a, because a spec that names a
mechanism it has not proven is how the last three rounds of findings started. It is inert until 3a
calls it, and six cases in `test/model-alias.sh` pin it: the piped-table matches, a miss still
exiting 1 with no stdout (so tier 2 falls through rather than blocking), an unreadable path still
exiting 2 (the guard did not become a no-op that treats a missing table as an empty one), and the
shipped table still being the default when the variable is unset.

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
3. **`harnesses.db` — the `models` table ONLY, never `invocation_logs`, and only for fields the
   profile left out.** *Narrowed after QA round 1, scoped again after round 2.*
   The first draft proposed routing partly on "this model has actually run on this harness before".
   agy rejected that and the live data proves the point: `commandcode` carries a two-row
   `stealth/ox-alpha` experiment that would have been promoted to a routing default. **History is
   not policy.** Tier 3 reads only the *declared* registry (`models.gateway`), which is curated on
   purpose. agy recommended dropping tier 3 outright; it is kept, narrowed, because the operator
   asked for the DB to feed dispatch and the unsoundness was entirely in the `invocation_logs` half.

   **Round 2 found the remaining hole, and it closes without dropping the tier.** agy checked the
   schema and reported that a tier 3 reading `models.gateway` returns `openrouter` for
   `zai-org/GLM-5.3` even on a Command Code lane, because *nothing in the database says a harness is
   its own router*. Verified — neither table carries it:

   | table | columns |
   |---|---|
   | `models` | `model_id, lab, canonical_name, gateway, context_window, prompt_price_per_m, completion_price_per_m, cache_read_price_per_m, supported_reasoning_levels, is_deprecated` |
   | `harnesses` | `harness_id, name, execution_engine, supports_programmatic, supports_reasoning_effort, headless_command_template, standing_policy_role, operating_constraint` |

   `execution_engine` does not encode it either: `commandcode` is `node_langbase` and `dsh` is
   `node_cordis`. Both say how a harness executes; neither says what it routes through.

   agy concluded tier 3 is unbuildable and must be dropped. **The fact is right; the conclusion does
   not follow, because self-routing is a property of the harness and the fix above already records
   it.** Tier 3 is consulted only for a field the profile did not supply, and `gateway` is now
   mandatory — so tier 3 is never asked to supply a gateway at all. What is left for it is resolving
   a model id, which `models` answers correctly.

   The alternative — a new `is_self_routing` column — was rejected. It would mean a schema migration
   on a database with no merge resolver, to store a fact the config file already states, in the
   issue that exists to stop the same fact being kept in more than one place.
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

### Phase 3a — the reviewer alias, end to end (the operator's main use case)

Ships the whole stated need on its own. Nothing below 3a is required for it to be useful.

- [ ] `profiles` block in `device_config.json`, seeded with the operator's two entries; the existing
      `default_*` keys become the unnamed fallback profile (no migration, no break)
- [ ] `resolve.sh <name> --env` emits everything a relay review turn needs: `RELAY_AGENT_CMD`, the
      gateway's `*_AGENT` / `*_MODEL` / `*_GATEWAY` / `*_REASONING_EFFORT` / `*_FLAGS`, and
      `$HARNESS` / `$TICK`. **`*_GATEWAY` is not optional** — QA round 2 caught it missing from this
      list. It became load-bearing this round: `commandcode-turn.py:141` now reads
      `COMMANDCODE_GATEWAY`, so a resolver that emits everything else leaves the shim on its
      literal. The literal is correct *today*, which is exactly why the omission would pass review
      and then rot the first time a lane's routing changes. For a `"gateway": "self"` profile,
      `--env` emits the harness id — the shim's own name is the honest value when harness and
      router are the same thing.
- [ ] `--list` and `--explain` (which tier answered, and why)
- [ ] Name matching reuses `resolve-model-alias.sh` via `MODEL_ALIASES_FILE=/dev/stdin` (shipped
      and pinned by `test/model-alias.sh`); the profile file is parsed by `device_config.py`,
      which already loads it
- [ ] **Profile integrity, as an extension of `test/gh346-gateway-allowlists.sh` — not a new
      suite.** QA round 2 found nothing validates the `profiles` block: a profile naming a retired
      harness, or a model absent from the `models` table, falls silently through to tiers 3 and 4
      and runs something else. That is the "derive, never curate" drift this issue exists to stop,
      reintroduced in the one file the spec adds. The check belongs in the suite that **already**
      derives the lane set from `route_agent`'s AST, next to the ten allowlists it already guards —
      the profiles block is simply the eleventh place the lane set appears, so it goes in the
      eleventh-allowlist detector rather than beside it. Assert: every profile's `harness` is a
      lane `route_agent` still routes, every `model` exists in `models`, and every
      `"gateway": "self"` names a harness that really is its own router.
- [ ] **The integrity check is a TEST, never a runtime raise.** A validation error that blocked a
      turn would break the never-block rule this spec is otherwise built on. Bad profile at
      runtime: report on stderr, fall through.
- [ ] Tiers 1, 2 and 4 only — the `harnesses.db` tier is 3b
- [ ] **Proof:** a real `/relay-xyz` review turn driven by
      `eval "$(resolve.sh 'glm 5.3 max' --env)"` alone, with no hand-written env block — and the
      same for `'qwen 3.8 max'` reaching DeepSeek → OpenRouter → `qwen/qwen3.8-max`
- [ ] **Proof:** the relay-xyz SKILL.md worker recipes replaced by the one-line form

### Phase 3b — `harnesses.db` as tier 3, declared registry only

- [ ] Read `models.gateway` for a model the profile did not name. **Never `invocation_logs`.**
- [ ] Fail-soft on missing, locked, corrupt or merge-conflicted DB — degrade to tier 4, and say so
- [ ] **Proof:** a test that deletes the DB and another that corrupts it, both asserting turns still
      resolve and run
- [ ] **Not in scope:** making the DB required. That needs `harnesses-merge-resolve.sh` first.

### Phase 3c — the shims consume the resolver (OPTIONAL; not needed for the main use case)

Deferred deliberately. 3a delivers the reviewer alias without touching a single shim's dispatch
default, so this phase is a separate value judgement, not a dependency.

- [ ] Each shim's dispatch default comes from the resolver; its literal remains as tier 4
- [ ] The 7 `*_MODEL` env var names keep working permanently as tier-1 overrides — **not deprecated**
- [ ] **Proof:** `test/gh346-telemetry-row-written.sh` extended — telemetry model == dispatched model
      for all 7 gateways, with the model var **both set and unset**

> **Note the coupling:** this is the phase that closes the declared-not-dispatched caveat (agy and
> codex record `device_config`'s declared default because they pass no `--model`). While 3c is
> deferred, that caveat stands, and the ROI checkpoint item "telemetry matches dispatch for all 7
> gateways" **must stay unticked**. Deferring 3c is fine; quietly ticking that box is not.

### Phase 3d — the resolution cache (independent of 3a-3c)

- [ ] Hash the resolution inputs; skip the vendored-vs-live diff on a match
- [ ] Invalidate on `.xyz/` version marker or config mtime change
- [ ] **Proof:** the checkpoint metric — re-resolutions per session drops measurably

## Design questions — answered by QA (agy, 2026-09-01)

1. **Separate prefs file vs `device_config.json`?** → **`device_config.json`** — which is where the
   operator offered to put it in the first place ("in lieu of the preference file, I was willing to
   add aliases to the canonical current config file"). QA reached the same answer independently. Its
   `default_harness`/`default_gateway`/`default_model` keys are already a one-profile version of this
   feature, so a second file would have been the eleventh curated list.
2. **Route on `invocation_logs`?** → **No.** Accepted. Tier 3 now reads only the declared `models`
   table. Live data proved the objection: a two-row `stealth/ox-alpha` experiment would have become
   a routing default.
3. **Does `effort` belong in a profile?** → **Only namespaced per gateway**, since not every
   gateway has one (`COMMANDCODE_REASONING_EFFORT`, `AGY_REASONING_EFFORT`; codex has none).
   Accepted: `effort` is optional per profile and emitted only for gateways that accept it.
4. **Deprecate the 7 `*_MODEL` env vars?** → **No.** Keep them permanently as tier 1 overrides.
   Deprecating would break existing scripts while providing nothing better. The spec already
   intended this; it is now explicit — 3c is a *fallback* change, not a migration.

## Findings recorded but NOT adopted

**"Drop tier 3 entirely."** Raised in both QA rounds, not taken in either — but for a different
reason each time, and round 2's reason is the stronger one.

Round 1 objected to routing on `invocation_logs`, which was correct and is fixed: history is not
policy, and tier 3 reads only the declared `models` table now.

Round 2 objected on schema grounds — no column marks a harness as its own router, so tier 3 would
hand `openrouter` to a Command Code lane. The fact was verified and is recorded under tier 3 above.
The conclusion is declined because **making `gateway` mandatory removes the question**: tier 3 is
only ever consulted for a field the profile omitted, and `gateway` can no longer be omitted. A tier
that is never asked for a gateway cannot answer with the wrong one.

Both rounds' objections were about tier 3 *supplying a gateway*. Neither disputed it supplying a
model id, which is what it is now scoped to. Dropping the tier outright would also refuse the
operator's explicit instruction that `harnesses.db` should feed dispatch where reversible — and it
is reversible in this shape.

~~**"The YAML example routes GLM 5.3 to OpenRouter instead of Command Code."**~~ **RETRACTED — QA
was right and this rejection was wrong.** Command Code is both harness and router; it does not
route through OpenRouter. The "live telemetry" cited as counter-evidence was a hardcoded shim
literal. See the correction under section 1, and the fix in `commandcode-turn.py`.

**"Degrading to tier 4 makes the system silently do the wrong thing."** The concern is fair but the
remedy is loud fallback, not abandoning the tier: every fallback reports which tier answered, on
stderr and via `--explain`. Reversibility (can the code change be undone?) and surprise (does the
fallback announce itself?) are separate properties; this spec now provides both.

## Closed by the operator

- *Should a profile pin a reviewer in the build → review path?* **No** — explicitly declined. The
  marathon defaults stay agy ↔ codex and that gate is untouched. A profile selects the worker for a
  **relay** review turn only.

## QA round 2 — what changed

`relay-system/2026-09-01/gh346-phase3-spec-qa-r2.md` (agy), adjudicated in
`gh346-phase3-spec-qa-r2-adjudication.md`. Verdict FAIL, six findings, **none dismissed**:

| Finding | Outcome |
|---|---|
| `--env` omits `*_GATEWAY` | Upheld — added to 3a; it became load-bearing when `commandcode-turn.py:141` started reading it |
| Nothing validates the `profiles` block | Upheld — folded into `test/gh346-gateway-allowlists.sh`, as a test, never a runtime raise |
| `{harness, gateway, model}` permits `{commandcode, openrouter}` | Upheld — `"gateway": "self"`, validated. The sharpest finding of the round |
| Schema cannot express self-routing, so drop tier 3 | Fact upheld, conclusion declined — mandatory `gateway` removes the case; a new column would store in the DB what the config already says |
| Deferring 3c leaves a second overstated claim | Upheld — capture-doc checkbox **0.4** scoped to the six explicit-model shims |
| The bash/Python normalizer seam is unspecified | Upheld — settled with a one-character change and shipped with this revision, not deferred |

The through-line of both rounds is one defect wearing three costumes: **a gateway value that asserts
something about a run no dispatch path establishes.** It appeared as a hardcoded shim literal
(Phase 0), as that literal being cited as evidence against a correct review (round 1), and as a
config shape able to express a router that isn't there (round 2). Each time it was caught by
checking the code rather than the document.
