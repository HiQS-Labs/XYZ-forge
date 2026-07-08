---
gh_issue: 178
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/178
title: "Epistemic/reconciliation-layer hardening: agy worktree grounding, stale HEAD-visibility warning, advisor pluggability, degraded-panel stamp, verdict provenance"
status: queued
created: 2026-07-08
updated: 2026-07-08
owner: noel
doc_type: bug-fix-and-hardening
complexity: 4
risk: 3
effort: 5
phases: 3
ratings_provisional: true
goal: >
  Root-cause and fix five epistemic/reconciliation-layer gaps split from #173's beta feedback: agy's
  intermittent zero-file-visibility in worktree consults (B1), a HEAD-visibility warning that
  false-positives against the harness's own seeding step (B2), advisor pluggability beyond three
  near-duplicate per-vendor turn shims (A1), a mechanical single-advisor degraded-mode stamp so the
  caveat is structural rather than operator-noticed (A2), and verdict-layer provenance distinguishing
  firsthand-read facts from operator-asserted ones (A4).
related:
  - relay-automation/consult.sh
  - relay-automation/agy-turn.sh
  - relay-automation/codex-turn.sh
  - relay-automation/aider-turn.sh
  - relay-automation/relay-drive.sh
  - relay-automation/relay-turn-lib.sh
non_goals:
  - Not B3 (reviewer citation) — stays parked in #173; tonight's runs partially contradicted it, needs more investigation before it's clearly in scope here
  - Not D1 (onboarding framing) — positive finding in #173, needs no fix
  - Not B4/D2/A3 — already split to #175, building now via Marathon Plan E
  - Not vendoring or authoring the external failure-mode catalog (advisor echo, false consensus, reconciler laundering, prompt drift, model-version drift) referenced by A4 — external, referenced not owned
---

# GH-178 — Epistemic/reconciliation-layer hardening (split from #173)

## Status

| What was just completed | What's next |
|---|---|
| Split from [#173](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/173) 2026-07-08: five items (B1, B2, A1, A2, A4) that were investigated/root-caused during #173's triage and a same-night dogfood-mining pass, but have no code fix yet. Queued — not yet started. | Phase 2 (B1 repro, A1 inventory) needs to run before Phase 3 fixes; B2/A2 already have enough root-cause evidence to consider starting Phase 3 directly. A4 needs an explicit scope decision (bundle here vs. its own issue) before implementation. |

## Parent & provenance
- **Parent:** [#173](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/173) — Jedi Wright beta feedback, full trip report at [GH-173-JEDI-WRIGHT-FEEDBACK.md](GH-173-JEDI-WRIGHT-FEEDBACK.md)
- **Sibling:** [#175](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/175) — the Phase 1 low-fruit slice (B4/D2/A3), building now via [Marathon Plan E](MARATHON-PLAN-2026-07-07-E-BUILD.md)
- **This issue:** [#178](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/178) — the five items below

## Scope — 5 items on the epistemic / reconciliation layer
All evidence below carried forward verbatim from #173's Validation table (see that doc for the full first-pass + dogfood-mining narrative on each).

| # | Claim | Status | Evidence |
|---|---|---|---|
| B1 | **agy worktree grounding** *(highest priority — undermines the panel's grounding claim)* — agy saw zero repo files in a `consult.sh` worktree and answered from pure priors. | Plausible; hypothesis narrowed; **non-repro 2026-07-07 night** | `agy-turn.sh:146/61` already warn on "finds nothing"/empty-`-p`. `consult.sh:125-136`'s worktree seeding (stash/HEAD → `worktree add --detach` → untracked overlay) looks complete, arguing against incomplete-checkout. Re-run tonight was clean (agy fine) — looks intermittent; Phase 2 needs N repeated runs, not one. |
| B2 | **Stale HEAD-visibility warning** — relay warns the reviewer "will find nothing," then the run completes anyway. | **Root cause found 2026-07-07 night** | Emitting site: `relay-drive.sh:226-240`. Live false-positive tonight: warning fired on an uncommitted relay file, run succeeded anyway because `relay-turn-lib.sh`'s `rtl_worktree_begin()` unconditionally seeds the relay file's current content (it's always in `RTL_ALLOW`) regardless of HEAD-tracked status. The warning's premise is stale relative to that seeding step. |
| A1 | **Advisor pluggability** — harness hardwires codex + agy. | Partially already present; sharpened 2026-07-07 evening | `consult.sh:28-29` exposes `--models codex,agy`. A third shim (`aider-turn.sh`, OpenRouter/GLM-5.2) proven live end-to-end tonight via the relay path (not yet via `consult.sh --models aider`, which remains untested). Gap is a generalized registry, not zero configurability. |
| A2 | **Single-advisor degraded-mode stamp** — no mechanical `SINGLE-MODEL — NOT RECONCILED` marker. | **Confirmed gap; live instance tonight** | No such stamp anywhere in the tree; `consult.sh:18` is "reconciled once" with no incomplete-panel marker. Live: tonight's first consult attempt returned `1 answered, 1 failed` (codex timeout) with nothing structurally marked degraded — caught only by the operator reading stdout. |
| A4 | **Verdict-layer provenance** *(likely the largest item — may need its own further split)* — distinguish firsthand-read facts from operator-asserted ones; flag asserted-only conclusions as conditional. | Plausible/design; sharpened by a live example tonight | References an external failure-mode catalog (not owned here). Live example: an advisor made a confident, dated, self-hedged claim tonight that was still wrong — the hedge alone didn't prevent the error, only independent verification caught it. Makes the case for *structural* provenance over model-supplied hedging. |

## Remediation checklist

### Phase 2 — Exploration (where evidence is still incomplete)
- [ ] **B1** — reproduce agy's zero-file visibility across N repeated `consult.sh` worktree runs (today's single re-run was clean); if reproduced, isolate CWD resolution vs. path-trust vs. something else on agy's side
- [ ] **A1** — inventory exactly what `--models` already generalizes vs. what stays codex/agy/aider-specific (turn scripts, reconciliation, config surface), to scope the registry design in Phase 3

### Phase 3 — Fixes (B2/A2 have enough root-cause evidence to start directly; B1/A1 gate on their Phase 2 above)
- [ ] **B1** — ensure agy sees the worktree's files, or fail-closed if it can't (don't let it silently answer from priors while claiming grounding)
- [ ] **B2** — reconcile `warn_if_relay_file_untracked` (`relay-drive.sh:226-240`) with `rtl_worktree_begin`'s seeding (`relay-turn-lib.sh`) so the warning reflects what the turn-taker will actually see; consider whether a *post*-seeding check (not a pre-turn prediction) is the more durable fix
- [ ] **A2** — mechanically stamp verdicts `SINGLE-MODEL — NOT RECONCILED` when the panel is incomplete, so the caveat is structural, not dependent on the operator reading stdout
- [ ] **A1** — extend `--models`/the turn-shim pattern into a generalized advisor registry, informed by the Phase-2 inventory above
- [ ] **A4** — first resolve the scope question (bundle here vs. spin out its own issue, given its size); then distinguish firsthand vs. asserted facts in verdict output and flag asserted-only conclusions as conditional

### Phase 4 — Verify
- [ ] Each fix carries a passing regression test (an agy worktree-visibility test; a warning/seeding reconciliation assertion; a degraded-panel stamp assertion; a registry config test)
- [ ] `utils/pdda/pdda.sh run` clean
- [ ] `./validate.sh` green for touched surfaces
- [ ] Link fix commit(s) back to #178 and #173

## Non-goals
- B3 (reviewer citation) — stays in #173, needs more investigation before it's clearly in scope here.
- D1 (onboarding framing) — stays in #173 as a positive/keep item, no fix needed.
- B4/D2/A3 — already split to #175.
- Vendoring/authoring the external failure-mode catalog A4 references.
