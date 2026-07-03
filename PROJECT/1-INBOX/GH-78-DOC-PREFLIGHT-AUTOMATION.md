---
gh_issue: 78
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/78
title: Optional hourly doc-preflight — contract-enforcing auto-edits for 2-WORKING + ROADMAP-queued docs, logged to telemetry
status: Proposed (1-INBOX — not yet active)
created: 2026-07-02
updated: 2026-07-02
owner: noel
doc_type: feature
effort: 3
complexity: 3
risk: 2
phases: 3
ratings_provisional: true
non_goals:
  - Not a blocking gate — the preflight always exits 0 and can never fail a build (LLM-layer calibration, same as pdda.sh doc-ready).
  - Not auto-committing or pushing its edits — edits land in the working tree only; a human reviews git diff + the telemetry log.
  - Not replacing the deterministic pdda.sh checks or the doc-ready review — it composes them.
  - Not rewriting nuanced plan content — only mechanical, contract-level edits; anything requiring judgment becomes a warn.
related:
  - PROJECT/PDDA.md
  - utils/pdda/pdda.sh
  - utils/pdda/pdda-catchup.sh
  - utils/telemetry/append-xyz-completion.sh
roadmap_exempt: false
---

# GH-78 · Optional hourly doc-preflight (contract-enforcing auto-edits + telemetry log)

**Why:** PDDA's deterministic checks only *flag* and the LLM `doc-ready` review only *advises* — neither
*fixes* a contract violation. The common, mechanical drift (a missing frontmatter key, a status-table
header that isn't exactly `What was just completed | What's next`, a missing `ROADMAP.md` pointer) still
needs a human to open the doc and edit it. This adds a best-effort, off-by-default hourly job that makes
the *safe* edits itself, logs every change to the telemetry folder, and warns (without editing) whenever
a fix is unsafe or under-specified.

## Status

| What was just completed | What's next |
|---|---|
| Issue [#78](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/78) opened, doc captured, parked in ROADMAP; v1 `utils/telemetry/preflight-docs.sh` + `test/preflight-docs.sh` built and wired into `validate.sh`. | Confirm scope + the never-auto-commit posture, promote to `2-WORKING`, then decide the scheduler (launchd vs Claude Code scheduled task) and enable it with `PDDA_LLM_BIN` set. |

## Table of contents

- [Status](#status)
- [Phase 1 — deterministic scaffolding + telemetry log](#phase-1--deterministic-scaffolding--telemetry-log)
- [Phase 2 — gated LLM edit step + safety valve](#phase-2--gated-llm-edit-step--safety-valve)
- [Phase 3 — scheduling](#phase-3--scheduling)

## Design summary

Targets = every doc in `PROJECT/2-WORKING/` **plus** every `PROJECT/1-INBOX/GH-*.md` capture parked in
`ROADMAP.md`'s queue. For each target the script:

1. **Reviews** — runs the deterministic `pdda.sh` single-file checks (scoped via `PDDA_ONLY_FILE`) to
   learn *exactly* what contract violations exist. No guessing.
2. **Edits (safely)** — if `PDDA_LLM_BIN` is set, asks the model for a corrected copy of the doc via a
   tightly-scoped rubric (mechanical contract fixes only). The candidate is written back **only if** the
   deterministic findings do not get *worse* (the safety valve).
3. **Logs** — appends an `edit` telemetry record (doc, findings resolved, model) to
   `utils/telemetry/preflight-log/YYYY-MM-DD.jsonl`.
4. **Warns** — a candidate that would worsen the contract, or a violation the model declined to fix, is
   logged as a `warn` record with `safe:false` and **no edit is made**.

### Safety posture (inherits PDDA's philosophy)

- Best-effort, **always exits 0** — never blocks a build (LLM oracle must be non-deterministic-safe).
- **Off by default** — a no-op edit-wise unless `PDDA_LLM_BIN` is set; with it unset the deterministic
  pass still runs and logs `warn`s for docs needing a manual fix.
- **Never auto-commits/pushes** — working-tree edits only; fully reversible (Easy). Bet: an unattended
  job that also commits is a One-way-door-shaped risk we deliberately decline for v1.
- Deterministic safety valve + single-file-scoped LLM invocations bound the blast radius.

## Phase 1 — deterministic scaffolding + telemetry log

- [ ] Target resolution: `PROJECT/2-WORKING/*.md` (minus `blank.md`) + the `GH-*.md` inbox docs whose
      repo-relative path appears in `ROADMAP.md`.
- [ ] Telemetry logger: append-only JSONL at `utils/telemetry/preflight-log/YYYY-MM-DD.jsonl`
      (`{timestamp, doc, action, safe, summary, findings_before, findings_after, model}`); gitignored.
- [ ] Deterministic pass: run `pdda.sh` scoped to each file, count findings before any edit.

### QA gate — Phase 1

- [ ] With `PDDA_LLM_BIN` unset the script exits 0, edits nothing, and writes one telemetry line per
      target (`skip`/`clean`/`warn`), proven by `test/preflight-docs.sh`.

## Phase 2 — gated LLM edit step + safety valve

- [ ] When `PDDA_LLM_BIN` is set, per-file: send content + rubric, receive a JSON envelope
      (`action: edit|warn|clean`, `content`, `reason`).
- [ ] Apply an `edit` only if the deterministic findings after ≤ before **and** no new `error`; else
      revert (`git checkout -- <file>`) and log a `warn` (`safe:false`).
- [ ] Log an `edit`/`warn`/`clean` telemetry record accordingly.

### QA gate — Phase 2

- [ ] A stub `PDDA_LLM_BIN` that returns a valid contract-fixing edit → the edit is applied + logged.
- [ ] A stub that returns a contract-worsening edit → reverted, `warn` logged, file unchanged.
- [ ] A stub that returns `action:warn` (insufficient guidance) → no edit, `warn` logged.

## Phase 3 — scheduling

Answer to "does it have to be a Claude Desktop scheduled job?" — **no.** The script is the deliverable;
the scheduler is pluggable:

- **launchd** (macOS) hourly agent → `PDDA_LLM_BIN=claude utils/telemetry/preflight-docs.sh`
  (recommended; matches PDDA.md's "Suggested hourly schedule" cadence). Sample plist in the script header.
- **Claude Code scheduled task** — the harness-native cron; runs the preflight prompt/skill hourly with
  no separate `claude -p` wiring.
- **Claude Desktop scheduled job** — works, but is not required and is the least reproducible.

### QA gate — Phase 3

- [ ] The sample launchd plist runs the script hourly against a real clone and produces a dated telemetry
      log with at least one record (operator litmus — a scheduler smoke test, not a `validate.sh` gate).
