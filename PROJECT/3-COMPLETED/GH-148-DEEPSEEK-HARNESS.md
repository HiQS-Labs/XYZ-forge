---
title: "GH-148: DeepSeek Harness (dsh) Integration & Evaluation"
gh_issue: 148
source: "https://github.com/HiQS-Labs/XYZ-forge/issues/148"
status: active
created: 2026-08-21
updated: 2026-08-21
owner: Antigravity
goal: "Integrate DeepSeek Harness (dsh) and deepseek-turn shim for OpenRouter DeepSeek V4 Pro, test against 3 real repo issues, and qualify model grade."
doc_type: feature
---

# GH-148 — DeepSeek Harness (`dsh`) Integration & Evaluation

## Status

| What was just completed | What's next |
|---|---|
| Built DeepSeek Harness, implemented `utils/py/deepseek-turn.py` and `relay-automation/deepseek-turn.sh`, passed 11/11 assertions in `test/gh148-deepseek-turn.sh`, and resolved 3 candidate bugs (GH-142, GH-68, GH-65) in an isolated clone. | Merge qualifying PR into `development` and close out tracking issue #148. |

## Quad Concepts
- **Harness Portability:** Seamless multi-provider Cordis patch overlays connecting `@deepseek-ai/dsh` to OpenRouter.
- **Strict Isolation:** Evaluated within a separate full clone folder outside the repo tree per GH-564 rail.
- **Empirical 3-Bug Verification:** Tested on genuine repo issues (GH-142 subprocess exit propagation, GH-68 table schema misalignment, and GH-65 3-tier portable hashing).
- **Authoritative Python Twin:** Zero-drift execution parity via `utils/py/deepseek-turn.py` with process group containment and `rtl.enforce`.

## Bet and boundary

Integrating DeepSeek Harness (`dsh`) expands the cost-effective frontier Chinese lab builder roster beside Command Code and Codex CLI. This is an **Easy** reversibility change: new turn shims are isolated to `utils/py/deepseek-turn.py`, `relay-automation/deepseek-turn.sh`, and `test/gh148-deepseek-turn.sh`.

## Deliverables
1. **Turn Shim:** `utils/py/deepseek-turn.py` & `relay-automation/deepseek-turn.sh`.
2. **OpenRouter Route:** Modular Cordis patch configuring `@deepseek-ai/dsh-llm-deepseek` with `https://openrouter.ai/api/v1` and `deepseek/deepseek-v4-pro`.
3. **Test Suite:** `test/gh148-deepseek-turn.sh` with 11/11 passing unit and integration assertions.
4. **Resolved Bugs:**
   - **GH-142:** `utils/ate/scripts/compile_issue.py` missing import and error exit code propagation.
   - **GH-68:** `HARNESS-MODELS-REGISTRY.md` Table 1 schema alignment.
   - **GH-65:** `test/gh32-releases-artifacts.sh` and `test/gh69-roadmap-shadow.sh` portable 3-tier hashing (`sha256sum` → `shasum -a 256` → `md5`).
5. **Registry Entry:** Awarded Grade **A** for Autonomous Headless Builder in `HARNESS-MODELS-REGISTRY.md`.
