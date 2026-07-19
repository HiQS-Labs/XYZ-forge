---
gh_issue: 61
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/61
title: CI GitHub Actions — Tier 1 lint/doc-hygiene gate + Tier 2 validate.sh regression gate
status: Closed — Proposed (1-INBOX — not yet active)
created: 2026-06-30
doc_type: feature
complexity: 2
risk: 2
effort: 3
ratings_provisional: false
related:
  - validate.sh
  - utils/pdda/pdda.sh
  - decisions/2026-06-30-pdda-runtime-consolidation.md
  - test/pdda-roadmap-coverage.sh
---

# GH-61 · CI GitHub Actions — Tier 1 + Tier 2

**Why:** This repo has **no CI** today; correctness is gated only by running `./validate.sh` locally.
The ~80% of issues it actually hits are bash logic bugs and doc/path drift (see CHANGELOG: relay
containment, epoch-fencing, the PDDA path drift fixed in #57). The real regression gate already exists
(`validate.sh`, 69 tests); the work is wiring it — plus a cheap always-green lint pass — into Actions
without creating a flaky required check.

Build as **two tiers in a single workflow effort.** Tier 1 ships first (zero-risk); Tier 2 is the real
gate but carries a runner decision (below).

## Tier 1 — lint + doc-hygiene (cheap, always-green, no auth)

A single `ubuntu-latest` job, runs in well under a minute, no secrets:

- **`shellcheck`** on all tracked `*.sh` (the #1 mechanical-bug catcher for a bash-heavy repo). Start
  permissive (`-S error` or an agreed exclude list) so it lands green, then tighten.
- **`bash -n`** syntax check on every `*.sh` (catches un-sourced/edited-script breakage).
- **`node --check`** on JS sources; **`python3 -m json.tool`** (or `jq`) on `.claude/settings*.json`.
- **`utils/pdda/pdda.sh run`** in `full` mode — deterministic doc/roadmap/path-drift gate. Env-light,
  no network. (This check would have flagged the entire #57 migration's drift.)

Acceptance: workflow green on `main` and on a PR; intentionally-broken fixtures (bad shell syntax,
malformed JSON, a working doc missing its ROADMAP pointer) each turn the job red.

## Tier 2 — `./validate.sh` regression gate (the real 80%)

Runs the full 69-test suite on PR. **Smaller lift than first scoped** (corrected by the GH-61 agy
review, 2026-06-30 — both items below were over-stated in the first draft):

1. **Portability** (if ubuntu): the only genuine BSD-ism in the test path is **`sed -i ''`** in
   [`relay-automation/relay-drive.sh`](../../relay-automation/relay-drive.sh) (GNU `sed` needs
   `sed -i` — no empty-suffix arg). *Not* hazards: `find-harness.sh` already uses a bash-3.2-safe
   `while [ -h ]` symlink loop (no `readlink -f`); `extract-relay-telemetry.sh`'s `date -v` already
   has a `|| date -d` GNU fallback **and** is exercised by no test. So: one small fix (or guard).
2. **Live-agent / network tests:** nearly all the turn/consult tests (`agy-turn`, `codex-turn`,
   `claude-turn`, `consult`, plus the pure-logic `improve-loop-qa`/`loop-cost`) run against **local
   stubs** (`AGY_BIN`/`CODEX_BIN`/`GEMINI_BIN` = a fake binary) and need **no** network/API. The only
   test that calls a real agent is **`relay-self-sufficiency.sh`**, which already self-skips via
   `RELAY_SELF_SUFFICIENCY_SKIP=1`. So CI just sets that env var and audits for any straggler. Any
   `gh`-dependent test needs `GITHUB_TOKEN` wiring or a skip.

**Do NOT make Tier 2 a *required* status check until it is reliably green** — a flaky required gate
erodes trust faster than no gate. Land it as advisory first, promote to required once stable.

### Open decision (resolve at build time) — Tier 2 runner

| Option | Pros | Cons |
|---|---|---|
| `macos-latest` | matches dev env → fastest route to green; no portability work | **~10× Actions minutes** (heavy on a private org repo) |
| `ubuntu-latest` + skip-gating | cheap to run forever (1× minutes) | upfront portability + skip-gating pass (the items above) |

*Recommendation:* if the repo is private, **ubuntu + invest in the skip-gating** (the portability
fixes are small and worth having anyway); if minutes are a non-issue, `macos-latest` is the shortest
path. Surface this to the operator before implementing Tier 2.

## Build notes
- Issue-first capture (#61); promote `1-INBOX → 2-WORKING` when execution starts, carrying `gh_issue`.
- Sequenceable via the Marathon Queue: Tier 1 is an independent quick-win lane; Tier 2 depends on the
  portability/skip-gating sub-task and the runner decision.
- Ratings: low blast radius (CI is additive, not in the runtime path; a red check is Easy to revert),
  modest effort (Tier 1 trivial, Tier 2 needs the skip-gating pass).

## Swarm Preflight Contract

Consumed by `utils/swarm-preflight.sh` to turn this doc into a marathon-ready packet. **Scope: Tier 1
only** (same-repo build; `target.ref: main`; `.github/workflows/` is genuinely unbuilt). Tier 2's
runner choice (`macos-latest` vs `ubuntu-latest` + skip-gating) is an **operator decision** and is
deliberately excluded from this auto-fireable lane. Codex lane — a normal code-writing task, fully
additive (CI is not in the runtime path), so nothing is orchestrator-only.

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash test/ci-workflow.sh",
  "fix_probes":  [ { "type": "path_absent", "path": ".github/workflows/ci.yml" } ],
  "artifacts":   [ ".github/workflows/ci.yml", "test/ci-workflow.sh", "validate.sh" ],
  "remediation": { "source": "GH-61#tier-1--lint--doc-hygiene", "criteria": "One additive Tier-1 GitHub Actions workflow (.github/workflows/ci.yml, single ubuntu-latest job, no secrets) that runs shellcheck + bash -n over tracked *.sh, node --check on JS sources, JSON-validate on .claude/settings*.json, and utils/pdda/pdda.sh run in full mode; plus a dependency-free deterministic test/ci-workflow.sh asserting the workflow exists, is well-formed, and references those exact checks — wired into validate.sh. Tier 2 (validate.sh regression gate) is explicitly OUT OF SCOPE for this lane." },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
