---
title: "Consume Model-catalog v1 (Phase 1): vendored catalog + generated alias YAML + drift check + version telemetry"
status: active
doc_type: feedback
source: https://github.com/HiQS-Labs/XYZ-forge/issues/450
gh_issue: 450
created: 2026-09-05
updated: 2026-09-05
revision: 1
owner: noelsaw1
branch: feat/gh450-model-catalog
goal: >
  Make HiQS-Labs/Model-catalog the pin of record for OpenRouter model aliases in this repo:
  vendor its v1.0.0 data byte-identically with a verifiable pin record, GENERATE the legacy alias
  YAML from it, make hand edits to either side CI-red, keep the Bash resolver untouched, and
  record the catalog version in invocation telemetry.
non_goals:
  - Any change to relay-automation/resolve-model-alias.sh (byte-untouched; Model-catalog PROJECT.md
    Phase 1 step 2 — no Bash-parses-JSON, no GH-551 adjacency).
  - Editing Model-catalog's data or bumping its version (data-only upstream; two-PR flow).
  - A runtime fetch of the catalog (no network at resolution; the vendored copy is the read).
  - Renaming or changing the AEGIS-Sleuth side (Phase 2, AEGIS-Sleuth-Slackbot#173).
related:
  - https://github.com/HiQS-Labs/Model-catalog/issues/1 (umbrella)
  - https://github.com/HiQS-Labs/XYZ-forge/issues/346 (resolver surface, GH-346 Phase 3a)
  - https://github.com/HiQS-Labs/XYZ-forge/issues/448 (adjacent dsh default-model defect)
context_tags: [model-alias, model-catalog, telemetry, relay-harness, generated-files]
effort: 2
complexity: 2
risk: 2
phases: 1
---

# GH-450 — Consume Model-catalog v1 (Phase 1)

## Status

| What was just completed | What's next |
|---|---|
| Vendored `v1.0.0` + pin record, generated YAML, `test/gh450-model-catalog-pin.sh` (26/0) with four red controls, tier-4 seam guard + terminal-refusal control in `test/model-alias.sh` (26/0), catalog version in `resolve-profile` + `harnesses.db` rows, hand-append flow retired in README/AGENTS. | Full `validate.sh` on the final candidate in the disposable clone; PR to `development` with `Closes #450`; Phase 2 (Sleuth#173). |

## What shipped (Model-catalog PROJECT.md Phase 1, steps 1–5)

1. **Vendored copy + pin record.** `relay-automation/model-catalog/catalog.json` is byte-identical to
   Model-catalog tag `v1.0.0` (`75e19139`, sha256 `9ff019fd…`). `catalog.pin.json` records repo, tag,
   tag commit, version, both sha256s (catalog + renderer), and the source URLs.
   `python3 utils/py/model_catalog.py check` verifies it; the suite runs it.
2. **Generated YAML.** `relay-automation/openrouter-model-aliases.yml` is rendered by the catalog
   repo's own `scripts/render_openrouter.py`, vendored at `324b0b34` (the tagged renderer predates
   `--catalog`), in the renderer's deterministic order (squash-length desc, then lex). Header line 1
   names `Model-catalog v1.0.0`. The 7 openrouter rows are unchanged as data; only order and
   provenance moved. `resolve-model-alias.sh` is byte-untouched.
3. **Drift check.** `model_catalog.py check` re-renders the vendored copy and demands byte
   equality with the committed YAML, and reports pin AND drift problems in one run. A flipped
   row in the vendored copy fails both edges; a hand-appended YAML line fails drift by name.
4. **Tests.** `test/model-alias.sh` keeps every hand-written assertion driving the real resolver
   and gains (a) the tier-4 post-correction guard: the raw resolver's capture of an old exact id
   after a repin is pinned *as documented behaviour*, and the guard that makes it impossible
   lives at the one seam every shim uses, `utils/py/model_alias.py:resolve_model_slug` (an exact
   `provider/slug` form never reaches the fuzzy table); (b) the named terminal-refusal control:
   a miss is exit 1 / no output at the resolver and an unchanged pass-through at the seam, never
   a default. `test/gh450-model-catalog-pin.sh` pins the pin/drift/telemetry edges with negative
   controls on scratch copies (`--root`). Both registered in `validate.sh`.
5. **Hand-append flow retired.** `relay-automation/README.md` → "Adding a new model alias" and the
   AGENTS.md GH-120 rail now describe the two-PR flow (`pin` / `render` / `check`).
6. **Telemetry.** `profile_resolve.py` reads the vendored `version` and exports
   `XYZ_MODEL_CATALOG_VERSION` on every tier (also in `--json`/`--explain`);
   `HarnessTurnLogger` stamps `invocation_logs.model_catalog_version` (env > vendored copy;
   additive nullable column with an in-place migration for pre-existing DBs; tracked
   `harnesses.db`/`harnesses.sql` migrated via the `dump` verb).

## Decisions taken that the plan left open

- **The renderer is vendored too** (`relay-automation/model-catalog/render_openrouter.py`, pinned by
  commit + sha256 in the pin record). The plan's drift recipe assumes a sibling Model-catalog
  checkout; CI has none, and a drift check that only runs on one laptop is not a drift check.
  Python under `relay-automation/` is not a new Bash executable (GH-551 scopes `.sh`).
- **The tier-4 guard is at the Python seam, not in the resolver or the data.** The resolver is
  byte-untouched by decision; the catalog's CI rule cannot see an id that has already left the
  data. `resolve_model_slug` is the one place every shim resolves through, and an exact id there
  is returned unchanged. `test/model-alias.sh` says out loud that the raw resolver still captures.
- **`model_catalog_version` is a real column**, not a value smuggled into `cli_flags`. Invocation
  rows "carry" the version only if the schema does.

## Acceptance (from #450)

- [ ] Green `validate.sh` on the PR (disposable full clone, un-sandboxed) — see PR body.
- [x] Flipping a row in the vendored copy turns CI red via the drift check — `provenance.jsonl`
      `mutation-a-*` (both edges named); hand-written resolver assertions still drive the real binary.
- [x] Refusal-contract negative control still fails when mutated — `mutation-c-default-on-miss`.
- [x] Tier-4 guard red when mutated — `mutation-b-remove-tier4-seam-guard`.
- [x] Hand-append flow red — `mutation-d-hand-append-yaml`.

Evidence: `TESTS-RESULTS/2026-09-05+GH-450/provenance.jsonl`.

## Risk and rollback

Reversibility **Easy**: revert the PR. The YAML returns to its hand-maintained form (same 7 rows),
the resolver never changed, and the `model_catalog_version` column is nullable — rows written
while it existed survive a revert harmlessly.
