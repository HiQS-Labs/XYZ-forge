---
title: "Let the profile carry the route — one pre-calculated resolution path for model aliases"
status: active
doc_type: feedback
source: https://github.com/HiQS-Labs/XYZ-forge/issues/399
gh_issue: 399
created: 2026-09-02
updated: 2026-09-02
revision: 2
owner: Noel Saw
branch: docs/gh399-plan
goal: >
  Make adding a model route a config edit instead of a code change. A profile should carry
  everything the shim needs to reach a provider, so a new endpoint, key variable, or provider
  name requires no Python.
non_goals:
  - The six non-DeepSeek shims. Explicitly deferred — see "Scope" below.
  - Migrating the seven per-shim default-model literals.
  - Bringing harnesses.db onto the routing path.
  - The colloquial-alias table (model_alias.py / resolve-model-alias.sh).
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/399
  - https://github.com/HiQS-Labs/XYZ-forge/pull/400
  - https://github.com/HiQS-Labs/XYZ-forge/issues/398
context_tags: [relay-harness, profiles, routing, config, credentials]
effort: 2
complexity: 3
risk: 2
phases: 2
reviewed:
  - relay-system/2026-09-02/gh399-plan-qa-codex.md (codex, revision 1, 2 blockers + 4 must + 2 should)
---

# GH-399 — Let the profile carry the route

## Status

| What was just completed | What's next |
|---|---|
| Revision 2: Codex's plan review folded in — route-resolution contract, precedence matrix, end-to-end acceptance, explicit DeepSeek-only scope, trust boundary. | Phase 1 — resolver emits the route. |

## Table of contents

- [The problem](#the-problem)
- [Scope](#scope)
- [The route-resolution contract](#the-route-resolution-contract)
- [Precedence and partial fields](#precedence-and-partial-fields)
- [Trust boundary](#trust-boundary)
- [Phase 1 — the resolver emits the route](#phase-1--the-resolver-emits-the-route)
- [Phase 2 — the DeepSeek shim consumes it](#phase-2--the-deepseek-shim-consumes-it)
- [Risk and rollback](#risk-and-rollback)

## The problem

The `profiles` block in the device config looks like the place you declare a route. It is not. It can
only *name* a harness, gateway and model that a shim already hardcodes. The endpoint and the key
variable live in Python, so "run Qwen through the Alibaba Token Plan" was not a config edit — it was a
new branch in `utils/py/deepseek-turn.py`, shipped as PR #400.

### Evidence

Three places describe a route. Only one is consulted when a request is made.

| Place | Carries | Consulted at request time? |
|---|---|---|
| device config `profiles` block | harness, gateway, model, effort | as names only |
| `utils/py/*-turn.py` | base URL, key variable, default model | **yes — the real router** |
| `harnesses.db` (`models`, `harnesses`) | lab, gateway, context window, pricing | no |

- Base URLs are literals in `utils/py/deepseek-turn.py` (`PROVIDER_ROUTES`, added by #400; before it,
  an `if`/`else` whose `else` silently swallowed every unknown provider).
- Default models are seven separate literals: `utils/py/aider-turn.py:62` and `:64`,
  `utils/py/claude-turn.py:97`, `utils/py/commandcode-turn.py:58`, `utils/py/deepseek-turn.py:206`,
  `utils/py/agy-turn.py:251`, `utils/py/pi-turn.py:71`.
- The *name* of each shim's gateway variable is declared nowhere. `utils/py/profile_resolve.py:95-133`
  recovers it by regex over the shim's own source, because `DEEPSEEK_PROVIDER` breaks the
  `<PREFIX>_GATEWAY` convention the other six follow.

**Path exception (PDDA rule 7).** This plan names one file outside the repo: the device config at
`~/.xyz/device_config.json`, read by `profile_resolve.py`'s `load_profiles()`. It is operator-local by
design and has no repo-relative equivalent. Every other path in this doc is repo-relative.

## Scope

**Phase 2 teaches the DeepSeek shim only.** The other six shims are explicitly deferred, and that is a
decision, not an omission: DeepSeek is the only shim that constructs an endpoint from a provider name,
so it is the only one where a config-supplied route has anything to consume today. Aider is the likely
second (`AIDER_OPENAI_API_BASE`), and it gets its own issue when this lands — not a phase here.

The resolver in Phase 1 emits `<PREFIX>_BASE_URL` / `<PREFIX>_API_KEY_ENV` generically, because the
emission code is prefix-driven and special-casing DeepSeek there would be more code, not less. But
**emitting a variable no shim reads is not a route**, so Phase 1's gate asserts only what the resolver
emits, and the end-to-end claim belongs to Phase 2 and to DeepSeek alone.

## The route-resolution contract

Codex's first blocker: `deepseek-turn.py` calls `provider_route()` in three places — the pre-claim
guard, key loading, and overlay generation — and each would need to agree. An overlay-only change
still exits 2 at the guard.

So Phase 2 introduces **one function**, and every one of those three call sites goes through it:

```python
def resolve_route(provider, env):
    """-> (base_url, key_env, key_file) or None if the provider cannot be routed.

    Config first, table second. Never merges the two: a config route is used whole or not at all,
    so a half-supplied profile cannot inherit an endpoint from one provider and a key from another.
    """
```

Call sites, all three replaced in the same commit:

| site | today | after |
|---|---|---|
| pre-claim guard | `provider_route(...)` | `resolve_route(...) or die(...)` |
| key loading | `provider_route(provider)[2]` | the tuple `resolve_route` already returned |
| overlay generation | `provider_route(provider)` | the tuple passed in as an argument |

`generate_patch_overlay()` stops calling the table at all and takes the resolved tuple as a parameter.
That is what makes "unknown provider + both fields = accepted" reachable rather than blocked by a
guard the plan forgot about.

## Precedence and partial fields

Codex's second blocker. The full matrix, which becomes a QA gate rather than prose:

| provider in table? | `base_url` | `key_env` | outcome |
|---|---|---|---|
| yes | absent | absent | table route (today's behaviour, unchanged) |
| yes | set | absent | config URL + **table's** key variable |
| yes | absent | set | table URL + **config's** key variable |
| yes | set | set | config route, whole |
| no | set | set | config route, whole |
| no | set | absent | **profile error** — no key variable to pair with a new endpoint |
| no | absent | set | **profile error** — no endpoint to send it to |
| no | absent | absent | **refuse the turn**, exit 2 (today's behaviour, unchanged) |

The two error rows are the point: for a provider the code has never seen, a partial route is a
mistake, not a default to be filled in.

**Environment beats profile, for both variables.** An exported `<PREFIX>_BASE_URL` or
`<PREFIX>_API_KEY_ENV` wins and is never second-guessed — the same rule the resolver already applies
to `*_AGENT` and `*_MODEL` (`utils/py/profile_resolve.py:311-322`). Note that the tier-1 decision
there currently keys on `*_AGENT` + `*_MODEL` only; adding route fields must not change which tier
answers, only what that tier emits.

## Trust boundary

Codex's `[Should]`, and the finding I would have got wrong. My instinct was "the device config is the
operator's own file, same trust as their shell rc." The repo has already rejected that argument in
writing — `test/gh346-profile-resolve.sh:246-250`:

> The config is operator-owned, but "the operator wrote it" is not a security argument: a profile can
> be pasted from a README, synced between machines, or vendored in.

Those existing cases pin *injection* — a hostile value must become an inert string. This plan opens a
different door: **redirection.** A syntactically clean profile can point an existing credential at an
attacker's endpoint, and nothing about it looks wrong.

Decision, and it is a trade, not a fix:

1. `key_env` must match `^[A-Z][A-Z0-9_]*$`. `base_url` must be `https://`, with no userinfo component
   (`https://user:pass@host` is rejected outright).
2. **The resolver announces the pairing on stderr whenever a profile supplies a route** — the
   credential *name* and the endpoint *host*, never a value:
   `resolve-profile: route 'qwen 3.8 max' sends $ALIBABA_TOKEN_PLAN_API_KEY to <host>`
   This is one line and no machinery, and it makes a silent redirect impossible.
3. Residual risk, stated rather than papered over: an operator who does not read stderr can still be
   redirected by a pasted profile. An allowlist of host/credential pairings would close it and would
   also re-create the hardcoded table this plan exists to remove. Not worth it at this blast radius —
   revisit if profiles ever start being shared between people rather than between an operator's own
   machines.

## Phase 1 — the resolver emits the route

`utils/py/profile_resolve.py` reads `base_url` and `key_env` from the profile body and emits
`<PREFIX>_BASE_URL` and `<PREFIX>_API_KEY_ENV`. Both optional; absent means **not emitted**, never
emitted-empty. Validation and the stderr announcement are as specified in
[Trust boundary](#trust-boundary); malformed values are reported through the existing `problems` list
so `--list` flags them.

### QA gate — Phase 1

- A profile that sets both emits both. A profile that sets neither emits **neither** — this is the
  assertion that can actually fail; one that only checks the present case passes against a resolver
  that emits empty strings unconditionally.
- Each partial-field row of [the matrix](#precedence-and-partial-fields) that is a *profile error* is
  reported by `--list` with the field named.
- An exported `<PREFIX>_BASE_URL` / `<PREFIX>_API_KEY_ENV` survives untouched.
- Adding route fields does not change which tier answers — assert the `--explain` tier for a profile
  before and after.
- The stderr announcement names the credential variable and the host, and **contains no credential
  value** — drive it with a fixture whose value is set, and assert the value's absence.
- A `base_url` carrying a userinfo component is rejected.
- Byte-identical regression: capture `--env` output for every existing profile before the change and
  diff after. This is the assertion that protects the six shims Phase 2 does not touch.
- `test/gh346-profile-resolve.sh` grows the above and stays green (currently 51 assertions).
- Every new assertion mutation-tested; record each mutant and the line it fired in the commit message.

## Phase 2 — the DeepSeek shim consumes it

Implement [the route-resolution contract](#the-route-resolution-contract) and
[the matrix](#precedence-and-partial-fields) in `utils/py/deepseek-turn.py`. `load_provider_key()`
(added by #400) already honours `<KEYVAR>_FILE`, so a config-only provider inherits the key-file
fallback with no new code.

### QA gate — Phase 2

- **The acceptance test for this whole plan, and it must drive the real path.** A fixture provider
  named in a fixture config and in **no** production Python routes end to end: write the config, run
  `resolve-profile.sh --env`, `eval` it, invoke `relay-automation/deepseek-turn.sh` with the existing
  stub CLI, and read the **cordis overlay the stub was handed**. Calling `generate_patch_overlay()`
  directly — as `test/gh148-deepseek-turn.sh:107-121` does today — is not sufficient: a lazy change to
  that helper passes while the pre-claim guard still rejects the fixture provider. The stub must copy
  the `--patch` file before exiting, since the shim deletes it in its `finally` block.
- Assert the overlay's exact base URL and `apiKeyEnv`, not merely that it differs from the table's.
- The "fixture provider appears in no Python" control is a **bounded scan of `utils/py/*.py`**, not a
  whole-tree grep. If the fixture name also exists in `PROVIDER_ROUTES`, the test passes on the table
  and proves nothing.
- Every row of the matrix asserted, including both *profile error* rows.
- `openrouter` and `deepseek` still route to their existing endpoints with no config present.
- A provider unknown to both table and config still exits 2 above `claim_task_or_exit`, leaving the
  relay token untouched — PR #400's assertion must stay green.
- `test/gh148-deepseek-turn.sh` grows the above and stays green (currently **30** assertions after
  #400 round 2; the GH-399 additions begin at `:205`).
- Full `validate.sh` green **from a normal clone, never a linked worktree** — the gate refuses one, and
  the refusal is correct.

## Risk and rollback

Risk 2, complexity 3 (raised from 2 on Codex's finding: this crosses resolver serialisation, evaluated
shell precedence, pre-claim validation, credential fallback, overlay generation, and fixtures).

Both phases are additive and opt-in: a config that sets neither field behaves exactly as today, which
is what the Phase 1 byte-identical diff pins. Rollback is `git revert`; no migration, no stored state.

The live hazard is precedence drift. Two rules must not merge: **which install** is env-first
(`find-harness.sh`), and **which value inside a profile** is also env-first — but a *profile* value
must never silently override something the operator exported. State it in the module docstring and pin
it with an assertion, or it will be re-derived wrongly later.

## Open questions

- Should `base_url` be allowed at the top level of the device config as a default for a gateway named
  by several profiles? Probably not — a fourth place a route can live is the thing this plan exists to
  stop. Recorded so it is not re-proposed.
