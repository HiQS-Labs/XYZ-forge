---
gh_issue: 153
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/153
title: "Cost observability: Codex per-turn token capture (parseCodexStats)"
status: "Contract authored 2026-07-23 (/10days sweep) — gate issue #151 CLOSED, unblocked; not yet fired"
created: 2026-07-23
updated: 2026-07-23
owner: noel
doc_type: feature
complexity: 2
risk: 1
effort: 2
ratings_provisional: true
related:
  - "#151 — Phase 4 discovery spike (CLOSED); its finding unblocks this issue — see PROJECT/1-INBOX/COST-OBSERVABILITY-PLAN.md Phase 7"
goal: >
  Add parseCodexStats to src/cost.js (mirroring the existing parseGeminiStats), and wire
  codex-turn.sh's `codex exec` invocation to emit machine-readable JSON so its turn.completed usage
  block can be parsed into a cost.tokens capture — mirroring the existing Gemini token-capture pattern.
---

# GH-153 · Codex per-turn token capture (`parseCodexStats`)

Was gated on issue #151 (Phase 4 discovery spike), now CLOSED. Its recorded finding in
`PROJECT/1-INBOX/COST-OBSERVABILITY-PLAN.md` (Phase 7 section, ~lines 187-350) explicitly says the
gate check passes: "Codex capture feasible? YES. `codex exec --json` emits a clean
`turn.completed.usage` block... `parseCodexStats` in `src/cost.js` can mirror `parseGeminiStats`
almost exactly — same shape, different field names."

Confirmed unimplemented: `src/cost.js` only defines/exports `parseGeminiStats` (lines 23, 56) —
`parseCodexStats` does not exist. `relay-automation/codex-turn.sh`'s `CODEX_FLAGS` (line ~136, default
`-s workspace-write -c approval_policy=never`) does not currently include `--json`; its `codex exec`
output goes to a plain transcript file at `CODEX_LOG` (line ~182), not a JSON stream.

## Touch surface

- `src/cost.js`: add `function parseCodexStats(input)` mirroring `parseGeminiStats` (~line 23); add it
  to `module.exports` (~line 56).
- `relay-automation/codex-turn.sh`: add `--json` (or the equivalent flag) to `CODEX_FLAGS`/the `codex
  exec` invocation (~lines 136, 182); parse the `turn.completed` usage line and emit a
  `cost.tokens --tool codex` call — best-effort, non-fatal on failure/zero, loud on stderr if it can't
  parse (mirrors the existing Gemini capture's fail-open contract).
- `test/cost.sh`: add a Codex fixture/test case.
- Reference: `PROJECT/1-INBOX/COST-OBSERVABILITY-PLAN.md` Phase 7 section (~lines 425-447) already has
  the full spec + QA checklist written — this contract should not re-derive it, just implement it.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash test/cost.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "src/cost.js", "pattern": "parseCodexStats" }
  ],
  "artifacts": [ "src/cost.js", "relay-automation/codex-turn.sh", "test/cost.sh" ],
  "remediation": {
    "source": "issue#153",
    "criteria": "parseCodexStats exists in src/cost.js and is exported, mirroring parseGeminiStats's shape. codex-turn.sh emits --json (or equivalent) and best-effort parses turn.completed usage into a cost.tokens --tool codex call, non-fatal on failure. test/cost.sh covers the new Codex fixture. Full spec in PROJECT/1-INBOX/COST-OBSERVABILITY-PLAN.md Phase 7."
  },
  "lanes": { "agy_safe": [ "src/cost.js", "test/cost.sh" ], "orchestrator_only": [ "relay-automation/codex-turn.sh" ] }
}
```

Note: `codex-turn.sh` is kernel-zone (a turn-taker shim, same tier as `aider-turn.sh`/`agy-turn.sh`) —
flagged `orchestrator_only`. `src/cost.js` and its test are plain application code, `agy_safe`.
