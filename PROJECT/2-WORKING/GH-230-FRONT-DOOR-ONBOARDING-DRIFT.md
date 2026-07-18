---
gh_issue: 230
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/230
title: "Front-door onboarding: undocumented npm install + package.json drift"
status: "Phases 1+2 executed 2026-07-17 — awaiting Phase 2 QA (CI green on next main PR), then close #230"
created: 2026-07-17
updated: 2026-07-17
owner: noel
doc_type: chore
complexity: 1
risk: 1
effort: 2
phases: 2
non_goals:
  - Not a full front-door rewrite — README.md/ROUTER.md's structure and the beta-onboarding banner
    already work well and are out of scope
  - Not fixing the pre-existing acorn-extract.sh environmental red tracked elsewhere in ROADMAP —
    this is about the missing install step, not existing test flakiness
related:
  - README.md
  - package.json
  - .github/workflows/ci.yml
  - test/acorn-extract.sh
goal: >
  Close the one real Bumpy gap in a cold-newcomer's path (undocumented npm install before
  ./validate.sh) and clean up package.json drift (stale name, garbled description, failing
  npm test stub), then add a CI safety net so this class of regression can't recur invisibly.
roadmap_exempt: false
---

# GH-230 · Front-door onboarding drift remediation

## Status

| What was just completed | What's next |
|---|---|
| Phases 1 and 2 executed 2026-07-17: README Quickstart now documents `npm install`, `package.json` name/description/`scripts.test` cleaned up, and CI `tier1` gained an `npm ci` + `./validate.sh` step. `validate.sh` deliberately NOT run locally (sandboxed local runs are the exact GH-177 wipe vector) — the new CI step is the exercise path. | Phase 2 QA gate: CI only triggers on push/PR to `main`, so the new step first runs when `development` next goes to `main` via PR. Verify green there (+ optional deliberate-regression check), then close [#230](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/230). |

## Table of contents

- [Phase 1 — Quick wins](#phase-1--quick-wins)
- [Phase 2 — CI safety net](#phase-2--ci-safety-net)

## Background

`/front-door` audit (2026-07-17, read-only — no scripts executed) walked the repo as a cold newcomer
against README.md's own Quickstart. Verdict: ⚠️ Bumpy. Full findings:

- **Source of truth:** clean — README.md is the one human-facing front door; ROUTER.md is explicitly
  scoped to agents ("Editing this repo as an agent? Read ROUTER.md ... a human landing here should
  start with the Quickstart above"). No competing onboarding docs found.
- **Leaked secrets:** clean — no `.env`/`.env.example` anywhere, and the only credential-shaped
  strings in the tracked tree are `test/security-scan.sh`'s own dummy fixtures (AWS's documented
  `AKIAIOSFODNN7EXAMPLE`, an obviously-fake `ghp_...` token, bare PEM headers with no key body).
- **The one real gap:** `package.json` declares real dependencies (`acorn`, `acorn-walk`) that
  [src/acorn-extract.js:4-5](../../src/acorn-extract.js#L4-L5) requires, wired into `validate.sh`'s
  suite via `test/acorn-extract.sh` (GH-169). `node_modules/` is gitignored, and no doc (README.md,
  ROUTER.md, AGENTS.md, relay-automation/README.md) mentions `npm install`/`npm ci` anywhere. A
  genuinely fresh clone following the README Quickstart verbatim (`git clone` → `./validate.sh`)
  hits `Cannot find module 'acorn'`. CI's own `tier1` job
  ([.github/workflows/ci.yml](../../.github/workflows/ci.yml)) never runs `./validate.sh` (only
  shellcheck/syntax/PDDA-gate steps), so this class of gap is invisible to CI and would only surface
  on a real newcomer's first run.
- **Drift:** `package.json`'s `"name": "lane-169"` (looks like a stale internal lane label, not a
  real package name), `"description"` (a garbled copy-paste of the README's beta-banner prose, not
  an actual description), and `"scripts": {"test": "echo \"Error: no test specified\" && exit 1"}`
  (a deliberately-failing stub — a newcomer's reflexive `npm test` fails instead of being pointed at
  `./validate.sh`).

Classification (per the `front-door` skill's agent-soluble/human-gated axis): both findings are
**agent-soluble, Bumpy** — the missing-module error names its own fix directly (`Cannot find module
'acorn'` → `npm install`), and the `package.json` fields are plain text edits. Neither is a
human-gated wall.

## Phase 1 — Quick wins

Doc + manifest edits only; no change to any script's actual logic.

- [x] `README.md` Quickstart: add `npm install` as an explicit line immediately before `./validate.sh`.
- [x] `package.json`: fix `"name"` to a real package name (`xyz-3-agents-swarm`), replace
      `"description"` with an actual one-line description, and point `"scripts"."test"` at
      `./validate.sh` instead of the failing stub.

### QA gate — Phase 1

- [x] `README.md` Quickstart reads correctly top-to-bottom as a fresh-newcomer path (`git clone` →
      `npm install` → `./validate.sh`), with a one-line note explaining what `npm install` is for.
- [x] `package.json` is valid JSON (verified `python3 -m json.tool`) and its
      `name`/`description`/`scripts.test` no longer contain stale/garbled/stub content.
      `validate.sh` confirmed executable (755), so `npm test` → `./validate.sh` resolves.
- [x] No change to any script's actual behavior — this phase is doc/manifest text only.

## Phase 2 — CI safety net

- [x] `.github/workflows/ci.yml` `tier1` job: add a step that runs `npm install` (or `npm ci`, if a
      lockfile discipline is wanted) followed by `./validate.sh` — or, if full-suite runtime is a
      concern for CI, at minimum `test/acorn-extract.sh` — so a missing-install-step regression is
      caught automatically instead of relying on a newcomer's first real run.
      *(Done 2026-07-17: `npm ci` chosen — a tracked `package-lock.json` already exists — followed by
      the full `./validate.sh` suite, which the README says runs in ~1 minute. YAML validity
      verified. Note: `ci.yml` triggers only on push/PR to `main`, so the step first fires when
      `development` next PRs into `main`.)*

### QA gate — Phase 2

- [ ] CI's `tier1` job is green on a PR that exercises the new step. *(Pending: needs the next
      `development` → `main` PR — CI does not trigger on `development` pushes.)*
- [ ] As a deliberate regression check: temporarily reverting Phase 1's `npm install` line makes the
      new CI step fail the way it should have caught this gap originally — proves the safety net
      actually works, not just that it runs.

## Definition of done

- [ ] Both phases' QA gates pass. *(Phase 1 done; Phase 2 pending the next `main` PR.)*
- [x] `bash utils/pdda/pdda.sh run` clean (verified 2026-07-17: "all checks passed", errors=0 warns=0).
- [ ] Issue [#230](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/230)
      closed with a reference to the shipping commit(s).

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "npm install && bash validate.sh",
  "fix_probes": [
    { "type": "grep_present", "path": "package.json", "pattern": "lane-169" },
    { "type": "grep_absent", "path": "README.md", "pattern": "npm install" }
  ],
  "artifacts": [ "README.md", "package.json", ".github/workflows/ci.yml" ],
  "remediation": {
    "source": "issue#230",
    "criteria": "README Quickstart includes npm install before ./validate.sh; package.json name/description/scripts.test cleaned up; CI tier1 job exercises npm install + the acorn-extract path so this class of gap can't recur silently."
  },
  "lanes": { "agy_safe": [ "README.md", "package.json" ], "orchestrator_only": [ ".github/workflows/ci.yml" ] }
}
```
