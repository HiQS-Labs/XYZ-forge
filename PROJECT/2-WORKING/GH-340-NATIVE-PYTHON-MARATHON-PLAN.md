---
title: "GH-340 — native Python marathon-plan engine (retire the copied Node renderer on the Python path)"
status: "Active (2-WORKING) — Phases 0–2 done: native engine shipped, `_marathon_plan_node.js` deleted, Node no longer required; byte-identical parity proven against the Bash/node engine. Awaiting review/merge."
created: 2026-07-29
updated: 2026-07-29
owner: noel
branch: claude/gh340-native-python-marathon-y83fbd
gh_issue: 340
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/340
doc_type: bugfix
related:
  - PROJECT/3-COMPLETED/GH-154-MARATHON-PLAN-PORT-PARITY.md
  - PROJECT/2-WORKING/GH-308-BASH-TWIN-RETIREMENT.md
  - PROJECT/2-WORKING/GH-110-SHELLCHECK-VENDOR-FIXES.md
  - utils/py/marathon_plan.py
  - utils/py/_marathon_plan_node.js
  - utils/marathon-plan.sh
  - test/marathon-plan.sh
non_goals:
  - Retiring, rewriting, or altering the XYZ_PYTHON=0 Bash fallback (utils/marathon-plan.sh stays authoritative + dual-maintained per GH-308).
  - Flipping GH-308's marathon-plan authority exception to "Python-authoritative".
  - Introducing a third renderer, an external dependency, or new CLI surface.
  - Changing scheduling, scoring, zone, or safety semantics — output must stay byte-identical to the Bash engine on fixed fixtures.
effort: 3
complexity: 4
risk: 3
phases: 3
goal: >
  Replace utils/py/_marathon_plan_node.js with a native Python-stdlib planner/rendering engine
  used by utils/py/marathon_plan.py, folding the docOf and PR-review-overlay compatibility shims
  into the native logic, so a production Python marathon-plan run needs neither Node nor the copied
  JS file — while preserving the CLI contract, exit codes, deterministic byte-identical output,
  hermetic test seams, and containment/safety semantics.
---

# GH-340 — native Python marathon-plan engine

## Status

| What was just completed | What's next |
|---|---|
| Phases 0–2 complete. Implemented `utils/py/_marathon_plan.py` (native stdlib engine), rewired `marathon_plan.py` to call it with **no Node** and folded shims `S` (native `doc_of`) + `N` (native review-lanes) in, deleted `_marathon_plan_node.js`. Proved byte-identical parity against the Bash/node engine (`XYZ_PYTHON=0` vs `XYZ_PYTHON=1`) on the live 160-item ROADMAP across text/JSON/derisk-first/require-gh + the full rendered doc, and on a synthetic corpus exercising both folded shims. `test/marathon-plan.sh` 60/0; `test_python_layer.py` 19/0; frozen-twin guard 27/0; PDDA deterministic checks clean; Python path runs with no `node` on `PATH`. | Land: commit + push to `claude/gh340-native-python-marathon-y83fbd`, open PR to `development`. GH-308's marathon-plan exception left documented (authority not flipped). |

## Table of contents

- [Phase 0 — Characterize the existing planner (discovery)](#phase-0--characterize-the-existing-planner-discovery)
- [Phase 1 — Native Python planner](#phase-1--native-python-planner)
- [Phase 2 — Authority & compatibility proof](#phase-2--authority--compatibility-proof)
- [Acceptance criteria](#acceptance-criteria)

## Background

`utils/py/_marathon_plan_node.js` is a copied Node renderer, not a separate JS architecture choice.
GH-112 copied the Bash-embedded `node - <<'NODE'` planner into the Python path to preserve behavior
quickly. That copy drifted (GH-154 — missing the GH-48 zone model) and GH-255 papered over two more
gaps by pre/post-processing *around* the copied program inside `marathon_plan.py`:

- **Shim `S` (`_normalize_roadmap`)** — the copied engine's older `docOf` picks the first
  `2-WORKING/GH-` md link, mis-selecting a distractor doc. The shim rewrites the ROADMAP input so the
  copied engine resolves the same doc Bash would. This is *input mutation*.
- **Shim `N` (`_inject_review_lanes`)** — the copied engine omits the GH-86 "Review lanes" overlay
  section; the shim appends it *after* the engine renders. This is a *post-render patch*.

The canonical, up-to-date engine is the one embedded in `utils/marathon-plan.sh` (Bash), which already
implements `docOf(item, gh)` (correct own-doc precedence) and `parseLanesTable`/native review-lanes
rendering. That embedded engine is the byte-identical port target.

## Phase 0 — Characterize the existing planner (discovery)

Observable contract of `marathon-plan` (the Bash-embedded engine; the Python path must match it):

- **CLI modes** — default (write today's `PROJECT/2-WORKING/MARATHON-PLAN-<today>.md` + print report),
  `--dry-run` (print report, write nothing), `--check` (re-render into a temp file, `cmp` against
  today's committed doc, print a `diff` on drift, write nothing).
- **Flags** — `--policy quick-wins|derisk-first` (default `quick-wins`; `derisk-first` flips the risk
  weight sign and bumps `RISK_W` 2→4), `--deep` (delegate each ready item to
  `utils/swarm-preflight.sh --dry-run`, downgrading on exit 4/5/6/7), `--require-gh` (turn an
  offline/absent `gh` into a hard exit 6), `--format text|json`, `--zones-config <file>` (explicit
  zone-rules override; on the Python path the Bash shim translates it to `QUEUE_PLAN_ZONES_FILE`).
- **Exit codes** — `0` clean · `2` usage · `3` ROADMAP missing/unparseable **or** malformed zones
  config · `4` drift present (already-landed/already-closed) · `5` items held out of sequencing · `6`
  `gh` required but unavailable.
- **Text output** — a header line (`marathon-plan · <today> · policy=… · weights{…} · gh=<mode>`),
  ledger/active/held counts, a `gh=off` note when applicable, a `FLAGS` block sorted `warn` before
  `info` then by type, and a `SUMMARY [marathon-plan] …` line.
- **JSON output** — one JSON object per finding (`timestamp,severity,check,file,message,action`, keys
  in that order) plus a `marathon-plan/summary` record, emitted in **insertion order** (not sorted).
  Must match JS `JSON.stringify`: no inter-token spaces, non-ASCII kept raw (`·`, `‖`, `—`), `/`
  unescaped.
- **Ranking** — `score = 2·eff + 1·cx + sign·RISK_W·risk + 3·deps + 1·zonePenalty` (+100 for a gated
  item). Active items sort by score, then dep-count, then zone rank, then issue number, then slug.
- **Zone configuration** — precedence `--zones-config` > `QUEUE_PLAN_ZONES_FILE` > root-local
  `.marathon-plan-zones.json` > built-in `utils/marathon-plan-zones.default.json`; foreign zone names,
  `pathPrefixes`, `pathRegex`(+`pathRegexCaseInsensitive`), `inferKeywordRegex`, `maxPerWave`,
  `penalty`, `conservativeWhenInferred`, `escalateOrchestratorOnly`; malformed config → exit 3, no
  silent fallback.
- **Wave packing** — collision-safe on exact write-set overlap, per-zone `maxPerWave`, conservative
  serialization of inferred zones, dependency ordering (a dep merely *held* still blocks its
  dependent), and GH-5 contract-seam detection (write-disjoint same-wave lanes sharing a directory
  spine deeper than a top-level dir).
- **Contracts / probes** — a `## Swarm Preflight Contract` ```json``` block per doc; `fix_probes`
  (`path_absent`/`path_present`/`grep_present`/`grep_absent`) drive `already-landed`; `artifacts` +
  base-ref existence drive the `some-artifacts-exist` partial signal.
- **`--deep`** — per ready item, `bash swarm-preflight.sh --project-doc <doc> --dry-run`; exit 4 →
  `already-landed`, 5 → `not-ready`, 6/7 → `blocked`.
- **`--require-gh`** — with `gh` off and `--require-gh`, exit 6.
- **Vendored mode** — when the engine lives under `.xyz/`, command strings render as `.xyz/utils/…`
  and the root resolves to the vendored parent.
- **`--check`** — deterministic; same ledger + ratings + `NOW`/`TODAY` ⇒ byte-identical doc, so
  `--check` is a drift guard.
- **Hermetic seams** — `QUEUE_PLAN_ROOT/ROADMAP/QUEUE_DIR/NOW/TODAY`, `QUEUE_PLAN_GH_STATE_FILE`,
  `QUEUE_PLAN_BRANCHES_FILE`, `QUEUE_PLAN_GH` (off/stub), `QUEUE_PLAN_BASE_FILES_FILE`,
  `QUEUE_PLAN_ZONES_FILE`.

### QA gate — Phase 0

- [x] Observable contract recorded in this doc (above).
- [x] Two Python parity shims (`S` docOf, `N` review-lanes) identified as input-mutation / post-render
      patches to be folded into native logic.
- [x] Baseline `bash test/marathon-plan.sh` captured green (60/60) before any change.

## Phase 1 — Native Python planner

- Implement the full planner/rendering engine in Python stdlib as `utils/py/_marathon_plan.py`
  (parse ledger → resolve items → validation signals → readiness → dep resolution → score →
  wave-pack → contract seams → text/JSON report → render Markdown), a faithful port of the
  Bash-embedded canonical engine.
- Fold shim `S` in by implementing native `doc_of(item, gh)` with own-`GH-<n>`-doc precedence; delete
  `_normalize_roadmap` (no ROADMAP input mutation).
- Fold shim `N` in by implementing native `parse_lanes_table` + a native "Review lanes" render block;
  delete `_inject_review_lanes` (no post-render patch).
- Rewire `utils/py/marathon_plan.py` to call the native engine directly — no `node --version` check,
  no `_marathon_plan_node.js` subprocess, no `QP_*` env plumbing.
- Delete `utils/py/_marathon_plan_node.js` once parity holds.

### QA gate — Phase 1

- [x] `utils/py/marathon_plan.py` imports and runs with **no** Node on `PATH`.
- [x] `_marathon_plan_node.js` is deleted; no runtime reference remains.
- [x] `_normalize_roadmap` / `_inject_review_lanes` shims removed; native `doc_of` + review-lanes in place.

## Phase 2 — Authority & compatibility proof

- `test/marathon-plan.sh` Scenario T proves `XYZ_PYTHON=1` (native Python) is byte-identical to the
  Bash engine for both the `--dry-run` text report and the rendered doc, on an explicit zones config.
- `./validate.sh` passes, including the `XYZ_PYTHON=1` parity assertions in `test/marathon-plan.sh`.
- Leave GH-308's marathon-plan exception documented as-is (Bash stays authoritative + dual-maintained);
  this issue does not flip authority.

### QA gate — Phase 2

- [x] `bash test/marathon-plan.sh` green (Scenario T shell↔Python parity included) — 60/0.
- [x] `test_python_layer.py` green — 19/0 (incl. `test_marathon_plan_module_load`).
- [x] Byte-identical parity proven `XYZ_PYTHON=0` vs `XYZ_PYTHON=1` on the live ROADMAP (text/JSON/derisk-first/require-gh + full rendered doc) and a synthetic docOf+review-lanes corpus.
- [x] Frozen-twin guard still asserts marathon-plan is the Bash-authoritative exception (unchanged) — 27/0.

## Acceptance criteria

- No production Python invocation of marathon-plan requires Node or references `_marathon_plan_node.js`.
- The copied Node engine is deleted; no new duplicate JS/Node renderer is introduced.
- `test/marathon-plan.sh` covers the native Python path and parity-sensitive fixtures (Scenario T).
- `./validate.sh` passes in the applicable modes, including `XYZ_PYTHON=1`.
- Existing planner guarantees remain: deterministic ordering, truthful Held/Flagged reporting,
  contract-based collision safety, and no automatic execution.
- Any remaining difference from legacy Bash is documented with its safety rationale and rollback path
  (rollback: `XYZ_PYTHON=0` runs the unchanged Bash engine).
