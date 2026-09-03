---
title: "Let the profile carry the route — one pre-calculated resolution path for model aliases"
status: proposed
created: 2026-09-02
updated: 2026-09-02
owner: Noel Saw
gh_issue: 399
branch: TBD
goal: >
  Make adding a model route a config edit instead of a code change. A profile in
  device_config.json should carry everything the shim needs to reach a provider, so no
  new endpoint, key variable, or provider name requires editing Python.
non_goals:
  - Migrating the seven per-shim default-model literals.
  - Bringing harnesses.db onto the routing path.
  - The colloquial-alias table (model_alias.py / resolve-model-alias.sh).
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/399
  - https://github.com/HiQS-Labs/XYZ-forge/pull/400
  - https://github.com/HiQS-Labs/XYZ-forge/issues/398
context_tags: [relay-harness, profiles, routing, config]
effort: 2
complexity: 2
risk: 2
phases: 2
---

# GH-399 — Let the profile carry the route

## Status

| What was just completed | What's next |
|---|---|
| Issue #399 filed; PR #400 made the silent fallback loud and added a third hardcoded route. | Phase 1 — pass `base_url` / `key_env` through the resolver. |

## Table of contents

- [Phase 1 — the resolver passes the route through](#phase-1--the-resolver-passes-the-route-through)
- [Phase 2 — the DeepSeek shim consumes it](#phase-2--the-deepseek-shim-consumes-it)

## The problem, in one paragraph

The `profiles` block in `~/.xyz/device_config.json` looks like the place you declare a route. It is
not. It can only *name* a harness, gateway and model that a shim already hardcodes. The endpoint and
the key variable live in Python, so "run Qwen through the Alibaba Token Plan" was not a config edit —
it was a new branch in `utils/py/deepseek-turn.py`, shipped as PR #400.

## Evidence

Three places describe a route. Only one is consulted when a request is made.

| Place | Carries | Consulted at request time? |
|---|---|---|
| `~/.xyz/device_config.json` `profiles` | harness, gateway, model, effort | as names only |
| `utils/py/*-turn.py` | base URL, key variable, default model | **yes — the real router** |
| `harnesses.db` (`models`, `harnesses`) | lab, gateway, context window, pricing | no |

Supporting detail:

- Base URLs are literals in `utils/py/deepseek-turn.py` (`PROVIDER_ROUTES`, added by #400; before it,
  an `if`/`else` whose `else` silently swallowed every unknown provider).
- Default models are seven separate literals: `aider-turn.py:62` and `:64`, `claude-turn.py:97`,
  `commandcode-turn.py:58`, `deepseek-turn.py:143`, `agy-turn.py:251`, `pi-turn.py:71`.
- The *name* of each shim's gateway variable is declared nowhere. `utils/py/profile_resolve.py`
  recovers it by regex over the shim's own source, because `DEEPSEEK_PROVIDER` breaks the
  `<PREFIX>_GATEWAY` convention the other six follow.

So the resolver reverse-engineers the shims, the shims hardcode the endpoints, and the table that
looks like a registry is not in the path.

## The design

Two optional profile fields, one passthrough, one fallback. No new file, no new table, no migration.

```json
"qwen 3.8 max": {
  "harness":  "deepseek",
  "gateway":  "alibaba",
  "model":    "qwen3.8-max",
  "base_url": "https://<the provider's OpenAI-compatible endpoint>",
  "key_env":  "ALIBABA_TOKEN_PLAN_API_KEY"
}
```

The resolver forwards them as `<PREFIX>_BASE_URL` and `<PREFIX>_API_KEY_ENV`, exactly as it already
forwards model and gateway. The shim prefers those when set and falls back to its built-in table when
they are not. Adding a provider becomes a JSON edit.

### Why not the alternatives

- **A routes table in `harnesses.db`.** Right shape, wrong cost. The DB is not on the routing path, so
  adopting it means a loader, a sync step and a migration before the first route works. The profile is
  already loaded, already parsed, and already the thing operators edit.
- **A provider-plugin interface in the shims.** One interface and seven implementations to express a
  URL and a variable name.
- **Deleting the built-in tables outright.** They are the floor that keeps the common cases working
  with no config at all. Keep them; just stop requiring them.

## Phase 1 — the resolver passes the route through

`utils/py/profile_resolve.py` reads `base_url` and `key_env` from the profile body and emits
`<PREFIX>_BASE_URL` and `<PREFIX>_API_KEY_ENV`. Both optional; absent means absent, not empty-string.

Validation stays as thin as the existing gateway check: `key_env` must look like an environment
variable name, and `base_url` must be an absolute `https://` URL. Anything else is a profile problem
reported by `--list`, in the same shape as today's `problems` list.

An explicit `<PREFIX>_BASE_URL` already in the environment wins and is never second-guessed — the same
rule the resolver already applies to `*_AGENT` and `*_MODEL`.

### QA gate — Phase 1

- `resolve-profile.sh <name> --env` emits both variables for a profile that sets them, and **neither**
  for one that does not. The absence case is the assertion that can actually fail; a test that only
  checks the present case would pass against a resolver that emits empty strings unconditionally.
- `--list` flags a profile with a malformed `base_url` or `key_env`, and the message names which field.
- A profile with no new fields resolves byte-identically to today. Capture the current output for the
  three existing profiles first and diff against it — this is the regression that matters.
- `test/gh346-profile-resolve.sh` grows the above and stays green (currently 51 assertions).
- Every new assertion mutation-tested: transpose the behaviour, confirm it goes red, record the
  failure line in the commit message.

## Phase 2 — the DeepSeek shim consumes it

`utils/py/deepseek-turn.py` prefers `DEEPSEEK_BASE_URL` / `DEEPSEEK_API_KEY_ENV` over
`PROVIDER_ROUTES`, and a provider that is unknown to the table but supplies both is **accepted**. A
provider unknown to both still refuses, with the message naming both remedies.

`load_provider_key()` (added by #400) already reads `<KEYVAR>_FILE`, so a config-only provider gets the
key-file fallback for free.

### QA gate — Phase 2

- **The acceptance test for this whole plan:** a provider named in a fixture config and in **no**
  `.py` file routes end to end. Assert against the generated cordis overlay — the artifact that
  decides where the request goes — not the variable that names it.
- The fixture provider must not also exist in `PROVIDER_ROUTES`. If it does, the test passes on the
  table and proves nothing.
- `openrouter` and `deepseek` still route to their existing endpoints with no config present.
- A provider unknown to both table and config exits 2, above `claim_task_or_exit`, leaving the relay
  token untouched — the assertion PR #400 already added must stay green.
- `test/gh148-deepseek-turn.sh` grows the above and stays green (currently 24 assertions).
- Full `validate.sh` green from a normal clone, never a linked worktree — the gate refuses one, and
  the refusal is correct.

## Risk and rollback

Risk 2 — additive and reversible. Both phases are opt-in fields: a config that sets neither behaves
exactly as today, which is what the Phase 1 byte-identical diff pins. Rollback is `git revert`; there
is no migration and no stored state to unwind.

The one real hazard is precedence drift. There are two rules and they must not merge: **which install**
is env-first, **which value inside a profile** is env-first as well, but a *profile* value must never
silently override something the operator exported. State this in the module docstring, and pin it with
an assertion, or it will be re-derived wrongly later.

## Open questions

- Should `base_url` be allowed at the top level of `device_config.json` as a default for a gateway
  named by several profiles? Probably not — it would create a fourth place a route can live, which is
  the thing this plan exists to stop. Recorded so it is not re-proposed.
