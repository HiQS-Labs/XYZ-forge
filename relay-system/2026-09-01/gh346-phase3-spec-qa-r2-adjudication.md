---
title: Adjudication of agy's round-2 QA on the GH-346 Phase 3 spec
date: 2026-09-01
source: relay-system/2026-09-01/gh346-phase3-spec-qa-r2.md
verdict: 5 findings upheld, 1 upheld-but-narrowed, 1 conclusion rejected
---

# Verdict: FAIL is correct. 3a is not yet implementable.

Every finding was checked against the code before adjudication — the standing rule on this issue
after a hardcoded literal was once cited as telemetry evidence.

---

## UPHELD — #4: `--env` omits the gateway variable

Spec 3a bullet 2 lists `RELAY_AGENT_CMD`, `*_AGENT`, `*_MODEL`, `*_REASONING_EFFORT`, `*_FLAGS`,
`$HARNESS`, `$TICK`. It does **not** list `*_GATEWAY`.

That was harmless until this round. `commandcode-turn.py:141` now reads
`os.environ.get("COMMANDCODE_GATEWAY", "commandcode")` — so a resolver that emits everything *except*
the gateway leaves the shim on its literal. The literal is correct today, which is exactly why the
omission would survive review and then rot the first time a lane's default changes.

**Fix:** add `*_GATEWAY` to the `--env` contract in 3a.

---

## UPHELD — #2: nothing validates the `profiles` block

Confirmed: the spec has no integrity check on `device_config.json`. A profile naming a retired
harness, or a `model` absent from the `models` table, falls through to tier 3 → tier 4 and quietly
runs something else. That is precisely the drift the "derive, never curate" lesson exists to stop,
reintroduced in the one file the spec added.

agy's proposed check is right and cheap: assert every profile's `harness` appears in `route_agent`'s
lane set and its `model` appears in `models`. It must be a **test**, not a runtime raise — a
validation error that blocks a turn would violate the never-block rule.

**Fix:** new checkbox in 3a. `test/gh346-profile-integrity.sh`, deriving the lane set from
`route_agent` the way `test/gh346-gateway-allowlists.sh` already does.

---

## UPHELD — #5: `{harness, gateway, model}` permits invalid permutations

Confirmed and it is the sharper form of #3. Nothing in the shape stops
`{harness: commandcode, gateway: openrouter}`. The resolver would emit
`COMMANDCODE_GATEWAY=openrouter`; `cmd` would ignore it and route through its own catalog anyway;
the telemetry row would record a gateway that was never used.

That is the identical failure this issue has already produced once — a gateway value asserting a
fact about the run that no dispatch path establishes. Rebuilding it in the new config surface, in
the same issue that fixed it, is the finding that most deserved to be caught.

**Fix:** `gateway: self` for a harness that is its own router, and profile validation rejects any
other gateway for a self-routing lane.

---

## UPHELD, CONCLUSION REJECTED — #3: "tier 3 cannot be built, drop it"

**The fact is confirmed.** Neither table carries a self-routing indicator:

- `models`: `model_id, lab, canonical_name, gateway, context_window, prompt_price_per_m,
  completion_price_per_m, cache_read_price_per_m, supported_reasoning_levels, is_deprecated`
- `harnesses`: `harness_id, name, execution_engine, supports_programmatic,
  supports_reasoning_effort, headless_command_template, standing_policy_role, operating_constraint`

`execution_engine` does not encode it either — `commandcode` is `node_langbase` and `dsh` is
`node_cordis`; both say how the harness executes, neither says what it routes through.

So a tier 3 that reads `models.gateway` for a `commandcode` lane returns `openrouter` for
`zai-org/GLM-5.3` and is wrong, exactly as claimed.

**The conclusion does not follow, because #5's fix removes the case.** Self-routing is a property of
the *harness*, not of the model, and tier 3 is only ever consulted for a gateway the profile did not
name. Once `gateway` is mandatory in a profile — `self` for self-routers — tier 3 is never asked to
supply a gateway for those lanes at all. What remains for tier 3 is looking up the canonical model
id, which `models` answers correctly today.

Dropping the tier outright would also refuse the operator's explicit instruction that `harnesses.db`
feed dispatch where reversible. It is reversible in this shape.

**Fix:** keep tier 3, and state in the spec that it is consulted only when the profile omits a
field — never to override a `gateway: self` lane.

---

## UPHELD — #6: a second claim is overstated, and it is not the one the spec names

The spec correctly flags that the ROI checkpoint item must stay unticked while 3c is deferred. agy
is right that a second claim is affected, and it is upstream of that one.

`harness_turn_logger.py:36` is `self.model_id = model_id or self.cfg["model"]`. `agy-turn.py:626`
and `codex-turn.py:146` both pass `os.environ.get("*_MODEL") or None`, so with the var unset the row
records `device_config`'s `default_model` — `deepseek/deepseek-v4-pro` — while agy and codex each
run their own internal default. Two different models.

Checkbox **0.4** in the capture doc reads: *"telemetry model == dispatch model for each shim with
the `*_MODEL` var unset"* — ticked, and untrue for 2 of the 8. The caveat at
`GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:133-136` records the fact honestly, but 0.4's own text
still asserts the equality without qualification, and 0.5's *"shows the right model"* inherits it.

**This review turn produced its own evidence.** The agy turn that raised the finding wrote:

```
inv-20260901043908-69de1ccf | agy | deepseek/deepseek-v4-pro | google | agy-turn.py | RELAY-gh346-phase3-spec-qa-r2
```

agy did not run `deepseek/deepseek-v4-pro`. That is `device_config`'s declared default, recorded
because `AGY_MODEL` was unset. The review that found the claim overstated demonstrated it in the
same turn.

**Fix:** scope 0.4 to the five shims that pass an explicit `--model`, and point the other two at the
standing caveat. Do not untick it — the work was done; the sentence overreached.

**Count correction found while applying this.** There are **seven** turn shims, not eight: agy,
aider, claude, codex, commandcode, deepseek, pi. The "8 gateways" figure traces to
`test/gh346-telemetry-row-written.sh` printing "8 pass" — 8 assertions, being 7 gateways plus one
that the scratch DB was written. It had spread to the capture doc, the spec, the ROI checkpoint and
a test header. All corrected. This also means the original Phase 0 claim *"records the wrong model
for 5 of 8 gateways"* was wrong in **both** halves — the numerator retracted in round 1, the
denominator never right.

---

## UPHELD — #7: the bash/Python normalizer seam is unspecified

Confirmed. `resolve-model-alias.sh` defines `normalize`, `squash` and `sorted_tokens` at `:28-44`,
but they are internal shell functions; the script's only interface is
`resolve-model-alias.sh <name>` → canonical slug from `ALIASES_FILE`. There is no way for Python to
reach the normalizer without also invoking the file read.

The three divergent implementations agy predicts are all real: reimplement `normalize` in Python,
refactor the bash into a sourceable library, or have Python write a temp flat file and set
`MODEL_ALIASES_FILE`. Two implementers would not build the same 3a.

**Recommendation:** reimplement `normalize`/`squash` in `model_alias.py` (~8 lines, already the
Python-side home for this) and pin bash/Python parity with a test the way
`driver_lock_path` parity is pinned. Shelling out to bash for string normalization on the turn path
buys nothing.

---

## Not upheld

Nothing. Finding #1's row-by-row verification confirmed all seven "Accepted" rows are real changes,
not cosmetic ones.

---

# Required before 3a is implementable

*All six are applied in this revision. See the round-2 table at the end of the spec.*

1. `--env` emits `*_GATEWAY`.
2. `gateway` mandatory in a profile; `self` for self-routing harnesses.
3. ~~`test/gh346-profile-integrity.sh`~~ — **folded into `test/gh346-gateway-allowlists.sh` instead.**
   That suite already derives the lane set from `route_agent`'s AST and guards the ten allowlists;
   the profiles block is simply the eleventh place the lane set appears, so it belongs *in* the
   eleventh-allowlist detector, not in a new file beside it.
4. Tier 3 kept, scoped: consulted only for fields the profile omits, never over `gateway: self`.
5. ~~Normalizer moves into `model_alias.py` with a parity test~~ — **superseded while applying it.**
   Duplicating `normalize`/`squash` in Python would create the second matcher the north star warns
   against, and a parity test only exists to manage that duplication. The existing script already
   read `$MODEL_ALIASES_FILE`; only its `-f` guard refused a pipe. Changed to `-r`, so Python pipes
   the profile table in and the four matching tiers stay the single implementation. One character,
   six new cases in the existing `test/model-alias.sh`, no new module, no parity test.
6. Capture-doc checkbox 0.4 scoped to the five explicit-model shims.
7. *(added while applying)* The 8-vs-7 gateway count corrected everywhere it had spread.
