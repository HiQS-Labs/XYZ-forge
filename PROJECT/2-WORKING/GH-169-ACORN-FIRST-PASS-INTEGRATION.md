---
gh_issue: 169
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/169
title: "Acorn integration (first pass): vendor acorn+acorn-walk as a lightweight JS symbol/call-site extractor for GH-156"
goal: Vendor acorn
roadmap_exempt: true
status: Active (2-WORKING) — completed in lane-169
created: 2026-07-07
updated: 2026-07-07
owner: noel
doc_type: feature
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Not GH-156's full Phase 1 scorer — that still needs GH-156's Phase 0 scoring-contract decisions
  - Not a call-graph/symbol-table assembly layer — parse step only
  - Not PHP-side parsing (stays nikic/php-parser, a separate track)
  - Not wired into any active code path yet — purely additive, default-off
related:
  - PROJECT/1-INBOX/GH-163-WP-SIBLING-AST-REVIEW.md
  - PROJECT/2-WORKING/GH-156-SWARMABILITY-PRELIGHT.md
  - ~/Documents/GH Repos/acorn
goal: >
  Vendor acorn + acorn-walk as a real dependency and build a small, tested utility that parses a
  JS file and extracts function/class declarations and call sites — the JS-side parsing building
  block GH-156 will eventually consume, built and tested independently of GH-156's still-open
  scoring-contract decisions.
roadmap_exempt: false
---

## Key concepts

- GH-163 reviewed `wp-code-check`/`WP-DB-Toolkit` (no reusable JS AST infra found) then
  license-vetted and smoke-tested `acorn` as an external candidate: MIT, zero runtime deps,
  ~6.7K LOC total, 28/28 real repo files parsed clean, 20/20 modern syntax features covered, clean
  error path. Verdict: usable as-is for the JS side.
- This issue is the first *build* pass on that verdict — narrow scope, infra only.
- GH-156's actual scoring contract (inputs, hard gates, output schema) is still an open Phase 0
  decision in that doc — this issue does not depend on it and does not resolve it. It only
  delivers the parsing building block GH-156 Phase 1 will later consume.

# GH-169 · Acorn first-pass integration

## Status

| What was just completed | What's next |
|---|---|
| Built acorn-extract utility, vendored acorn/acorn-walk, and added tests in lane-169. | Merge lane-169 and unblock GH-156 Phase 1 scoring logic. |

## Idea

Vendor `acorn` + `acorn-walk` (already cloned locally at `~/Documents/GH Repos/acorn` for GH-163's
evaluation) as a real project dependency, and build a minimal, tested extractor utility mirroring
the shape already proven in GH-163's test rounds: parse a JS file, walk the AST, return function/
class declarations and call-site identifiers.

## Why

GH-163 already did the expensive part (license clearance + real-world parse testing). Wiring the
dependency in now — while it's still a small, additive, reversible unit — is cheap and de-risks
GH-156's later Phase 1 work: by the time GH-156's scoring contract is settled, the parsing
building block already exists, is tested, and its behavior on this repo's real files is already
characterized (GH-163's Addendum 2).

## Phase 0 — Vendor and build the extractor

### Checklist

- [x] Add `acorn` + `acorn-walk` as a real dependency (package.json entry, not just a filesystem
      reference to the local clone).
- [x] Build a small utility module: given a JS file path, parse it (`ecmaVersion: "latest"`,
      `sourceType: "module"`, falling back to `"script"` on failure — mirroring GH-163's test
      sweep logic) and return `{ declarations: [...], callSites: [...] }`.
- [x] Handle the malformed-input case explicitly: catch the parse error and return/report it with
      line/col rather than letting it propagate as an uncaught exception.
- [x] Write a test that exercises the utility against at least one real file in this repo and
      against a deliberately malformed snippet.

### QA checklist — Phase 0

- [x] The utility is purely additive — no existing code path calls it yet (GH-156 wires it in
      later, once its own scoring contract is settled).
- [x] The test covers both the happy path (real file → declarations + call sites) and the error
      path (malformed input → clean, catchable error).
- [x] No changes to scheduling, containment, or the relay kernel.


## Swarm Preflight Contract

```json
{"target":{"repo":".","ref":"main"},"gate":"bash validate.sh","fix_probes":[{"type":"grep_absent","path":"README.md","pattern":"THIS_WILL_NEVER_MATCH"}],"artifacts":["README.md"],"remediation":{"source":"self","criteria":"Fix per plan"},"lanes":{"orchestrator_only":[]}}
```
