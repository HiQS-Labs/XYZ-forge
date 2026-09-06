# Recon Map — model aliasing & canonicalization
Commit: 96c21555 · Mode: grep+read (no graph) · Lanes: serial in-context (subsystem contained; edges held from live debugging session 2026-09-05/06, re-verified at HEAD)

## Subject and change class
The model-name resolution stack: colloquial/bare id → canonical slug → per-lane model env. Spec deliverable (GitHub issue) feeding future fixes; no code change in this step.

## The seams — where a change here escapes this file
| Seam | Location | Crosses | Breaks if |
|---|---|---|---|
| Alias table data | relay-automation/openrouter-model-aliases.yml (7 rows at HEAD) | relay lane model selection; #450 will make it GENERATED from Model-catalog | hand-edit vs generated drift; row order (file-order-wins per tier) |
| Matcher | relay-automation/resolve-model-alias.sh:36-45,63-124 — 4 tiers, normalize/squash/sorted_tokens, tier-4 substring both-directions | every consumer | tier semantics change breaks profile-name matching reuse (same matcher) |
| Canonicalization wrapper | utils/py/model_alias.py — resolve_model_slug: never-raise, input-as-floor, 10s timeout | deepseek lane + review_xyz.py | contract change breaks turn shims on miss |
| Canonicalization call sites | utils/py/deepseek-turn.py:11,226-228 (DEEPSEEK_MODEL); utils/py/review_xyz.py; pinned by test/gh346-resolver-fallback.sh:75-78 | DEEPSEEK lane turns only (codex/agy/commandcode/pi/aider do NOT canonicalize at runtime — aider-turn.sh:62 is a comment) | — |
| Profile resolver | relay-automation/resolve-profile.sh + utils/py/profile_resolve.py — reuses matcher for profile-NAME matching only (MODEL_ALIASES_FILE=/dev/stdin seam, -r guard); passes profile model value through UNCANONICALIZED | device_config.json profiles → lane env | if profile values ever got canonicalized, bare per-provider ids hijack (today they don't — verified --env emits qwen3.8-max) |
| Test seam | MODEL_ALIASES_FILE env (resolve-model-alias.sh:31, -r readability guard); test/model-alias.sh STDIN_TABLE | test/model-alias.sh:64,79 carry stale slug qwen/qwen3.8-max (absent from live OpenRouter catalog; live = -0902) | doc-rot with green tests |
| Docs | AGENTS.md:405-408 (GH-120 rail); relay-automation/README.md:582-588; skills/relay-xyz/SKILL.md:265 (stale slug in example profile) | agent behavior | stale example teaches the hijack shape |

## Call paths in
- relay turn: DEEPSEEK_MODEL env → deepseek-turn.py:226-228 → resolve_model_slug → resolve-model-alias.sh → yml rows → canonical slug → dsh request model
- profile: resolve-profile.sh --env → profile_resolve.py (matcher for NAME match) → DEEPSEEK_MODEL=<profile model verbatim>
- review lane: review_xyz.py → resolve_model_slug
- aid lane: aider-turn.sh — docs pointer only (GH-120), no runtime call

## State
Single data file (yml, hand-maintained today; #450 makes it generated). No cache (#346 owns). No persisted resolution state.

## Contracts
- Resolver exit codes: 0 match+slug / 1 silent miss / 2 usage-or-unreadable-table (test/model-alias.sh pins all three)
- model_alias.py: never raises, never empty; caller literal is the floor (docstring + test/gh346-resolver-fallback.sh:21-41)
- MODEL_ALIASES_FILE accepts pipes (-r guard) — profile-name matching reuses THIS matcher, no second implementation
- Adding a row: append + assertion in test/model-alias.sh (yml header) — #450 replaces with generated render + drift check

## Defects verified live (evidence)
- D1 gateway-blind canonicalization: deepseek-turn.py rewrites DEEPSEEK_MODEL via a table whose rows are OpenRouter slugs only; a bare id exact for the target provider is rewritten if any alias normalizes equal. Repro chain 2026-09-05: profile (deepseek/alibaba/qwen3.8-max) → shim canonicalized bare id via alias "qwen 3.8 max: qwen/qwen3.8-max-0902" → dsh HTTP_404 "Model not exist." (r4/r5 transcripts; dsh session request/header shows the rewritten id). Negative control observed: alias removed (96c21555) → bare id rc=1 passthrough. Structural, not instance-specific: any future colliding row re-arms it.
- D2 tier-4 substring over-match: bare "qwen"→qwen/qwen3-coder, "glm"→z-ai/glm-5.2, "grok"→x-ai/grok-4.6 (probes at HEAD). Both-direction containment on squashed forms; any prefix of an alias key silently rewrites.
- D3 stale slugs: skills/relay-xyz/SKILL.md:265 + test/model-alias.sh:64,79 use qwen/qwen3.8-max; live OpenRouter catalog has qwen/qwen3.8-max-0902 only (queried live 2026-09-05). Green tests encoding a dead id.

## Unknowns
| Unknown | Why it matters | What would settle it |
|---|---|---|
| Whether commandcode/aider lanes need canonicalization parity | scope of D1 fix | operator decision (ponytail: default no — they don't consume the table today) |

## Current-state radius, one line
DeepSeek-lane turns (dsh worker: deepseek/openrouter/alibaba providers), review_xyz, profile resolution UX, #450's generated-YAML plan, Model-catalog's matcher contract.
