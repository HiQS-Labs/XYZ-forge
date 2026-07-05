# Marathon Phase gh137
STATUS: Open
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH137-TURN builder=codex reviewer=agy round-cap=4 -->

## Phase Brief

---
gh_issue: 137
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/137
title: "swarm-preflight: covering-test inference can inject test/.. (repo root) + generated files into ALLOW_PATHS"
status: captured 2026-07-05, rated — independent (swarm-preflight) lane, marathon-ready
created: 2026-07-05
updated: 2026-07-05
owner: noel
doc_type: bugfix
goal: >
  swarm-preflight's covering-test/helper inference (the embedded JS in utils/swarm-preflight.sh)
  can emit a path that normalizes to the repo root (test/..) or a generated file (__pycache__/*.pyc)
  into the suggested artifacts / ALLOW_PATHS. An operator who fires marathon-drive with that
  suggestion verbatim widens the containment allowlist to the whole repo — the boundary is gone.
  Fix: sanitize inferred paths so nothing containing `..`, resolving outside the repo test/ tree, or
  matching a generated/gitignored pattern can reach the allowlist. Narrowing only — never widens.
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: false
non_goals:
  - NOT changing the declared `artifacts[]` passthrough — an operator-declared write-set stays authoritative; only the INFERRED additions are sanitized
  - NOT removing covering-test inference — genuine sibling covering tests still resolve; this only drops pathological/escaping/generated entries
  - NOT touching relay-turn-lib.sh or the containment core — this is purely the preflight suggestion generator
related:
  - utils/swarm-preflight.sh
  - test/swarm-preflight.sh
---

## Status

| What was just completed | What's next |
|---|---|
| Found 2026-07-05 while dogfooding the GH-112 parity marathon: swarm-preflight's packet suggested an `--artifact` list containing `test/..` (→ repo root), a `__pycache__/*.pyc`, and unrelated `test/` files. Filed #137. Fired the GH-112 lane with an explicit bounded `--artifact` instead. | Sanitize the inference in `utils/swarm-preflight.sh` so escaping/generated paths can't reach the emitted ALLOW_PATHS; add regression coverage in `test/swarm-preflight.sh`. |

## Problem (grounded in the current code)

`utils/swarm-preflight.sh` embeds a JS covering-test/helper inference (~lines 286–366). The helper
walk does:

```
for (const helper of helperRefs(read(rel))) {
  if (!helper.startsWith("test/")) continue;
  if (!existsSync(path.join(root, helper)) || seenHelpers.has(helper)) continue;
  add(inferredHelpers, helper);   // <-- test/.. passes existsSync (root exists) and is added
}
```

`helperRefs` can extract a reference whose path is `test/..` (a test that references its parent dir).
`existsSync(root + "/test/..")` is true (it's the repo root), so `test/..` is added to the inferred
artifacts and flows into the emitted `artifacts` / ALLOW_PATHS. Same class of problem admits
`__pycache__/*.pyc` (generated, gitignored) entries.

`ALLOW_PATHS` is the containment allowlist (GUIDING-PRINCIPLES §3). A suggested invocation that widens
it to the repo root is a footgun for exactly the unattended-run case swarm-preflight exists to make
safe.

## Acceptance criteria — the build is DONE when these hold

- [ ] Inferred covering-test/helper paths are sanitized: any path containing a `..` segment, or that normalizes to a location outside the repo `test/` subtree (including the repo root), is dropped before it can reach `included` / the emitted `artifacts`.
- [ ] Generated/gitignored paths (`__pycache__/`, `*.pyc`) are excluded from inference.
- [ ] The emitted `artifacts` / ALLOW_PATHS can never contain a path that normalizes to ROOT or escapes the repo; operator-declared `artifacts[]` still pass through unchanged.
- [ ] `test/swarm-preflight.sh` gains regression coverage: a fixture whose covering-test/helper inference previously yielded `test/..` now excludes it; a `__pycache__/*.pyc` reference is excluded; a genuine sibling covering test is still included; declared artifacts still pass through.
- [ ] A `GH-137` marker comment sits at the sanitization site.
- [ ] Gate green: `bash test/swarm-preflight.sh`; and `validate.sh` green in default mode (no regression to the existing preflight suite).

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/swarm-preflight.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/swarm-preflight.sh", "pattern": "GH-137" }
  ],
  "artifacts": [
    "utils/swarm-preflight.sh",
    "test/swarm-preflight.sh"
  ],
  "remediation": "In utils/swarm-preflight.sh's embedded covering-test/helper inference (~lines 286-366), sanitize every INFERRED path before it is added to inferredTests/inferredHelpers/included: reject any path whose normalized form contains a `..` segment or resolves outside the repo `test/` subtree (so `test/..` → repo root is never added), and reject generated/gitignored patterns (`__pycache__/`, trailing `.pyc`). Keep the operator-declared artifacts[] passthrough exactly as-is (only inferred additions are filtered). Add a `GH-137` marker comment at the sanitization site. Then extend test/swarm-preflight.sh with a regression fixture: a covering test/helper that references `..` (previously surfaced `test/..`) is now excluded from the emitted artifacts; a `__pycache__/x.pyc` reference is excluded; a genuine sibling covering test is still included; and a declared artifact still passes through. Do NOT weaken or remove genuine covering-test inference. Do NOT touch relay-turn-lib.sh.",
  "lanes": {
    "preflight_safe": ["utils/swarm-preflight.sh", "test/swarm-preflight.sh"],
    "orchestrator_only": [],
    "note": "Single independent lane. Write-set is swarm-preflight.sh + its test — disjoint from relay-turn-lib.sh and from any turn/orchestrator entry script."
  }
}
```

## How to fire

```
utils/swarm-preflight.sh --project-doc PROJECT/2-WORKING/GH-137-SWARM-PREFLIGHT-INFERENCE-CONTAINMENT.md
relay-automation/marathon-drive.sh \
  --phase-brief PROJECT/2-WORKING/GH-137-SWARM-PREFLIGHT-INFERENCE-CONTAINMENT.md \
  --reviewer agy --builder codex --phase-id gh137 \
  --artifact 'utils/swarm-preflight.sh,test/swarm-preflight.sh' \
  --pre-advance-cmd 'bash test/swarm-preflight.sh' --require-clean --round-cap 4
```

---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/swarm-preflight.sh,test/swarm-preflight.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH137-TURN --agent codex --paths "phases/gh137/RELAY.md,utils/swarm-preflight.sh,test/swarm-preflight.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH137-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH137-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gh137/RELAY.md and utils/swarm-preflight.sh,test/swarm-preflight.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/swarm-preflight.sh,test/swarm-preflight.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH137-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH137-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh137/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · codex

Implemented GH-137 in `utils/swarm-preflight.sh` and `test/swarm-preflight.sh`.

- Added a `GH-137` sanitization step inside the embedded `expand-artifacts.mjs` helper so only inferred paths that stay inside the repo `test/` subtree are admitted; any inferred path with a `..` segment, a repo-root/out-of-tree normalization, `__pycache__/`, or a trailing `.pyc` is dropped before it can widen the emitted allowlist. Declared `artifacts[]` are unchanged.
- Added `T35b GH-137`, a regression fixture that creates a real covering test/helper alongside `$(dirname "$0")/..` and `$(dirname "$0")/__pycache__/generated.pyc` references, then asserts the effective artifacts keep only `relay-automation/consult.sh`, `test/consult.sh`, and `test/_setup.sh`.
- Verified with `bash test/swarm-preflight.sh` -> `87 passed, 0 failed`.
