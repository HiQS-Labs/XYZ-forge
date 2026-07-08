---
gh_issue: 178
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/178
title: "Epistemic/reconciliation-layer hardening: agy worktree grounding, stale HEAD-visibility warning, advisor pluggability, degraded-panel stamp, verdict provenance"
status: Active (2-WORKING) — B2 shipped 2026-07-08
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
| Branch `fix/gh-178-reconciliation-hardening` cut from `main`. **B2 shipped**: `warn_if_relay_file_untracked` (`relay-drive.sh`) now only claims "will find nothing" when the relay file lives in a genuinely different repo than the turn-taker's effective root (archive-routed shape) — the common same-repo case gets an accurate informational NOTE instead, since `rtl_worktree_begin`'s seeding step already covers it. Added `test/relay-file-seeding-visibility.sh` (new — mechanically proves both halves: same-repo seeding works, cross-repo seeding doesn't) and extended `test/relay-untracked-file-warn.sh` (same-repo NOTE tone + cross-repo WARNING still fires). `./validate.sh` green except `worktree-isolation.sh`, confirmed pre-existing/unrelated (fails identically on clean `main`). Also fixed an unrelated stale-package drift (`relay-pkg-freshness.sh`) surfaced along the way. | A2 next (mechanical stamp, similarly well-evidenced). Then B1/A1's Phase 2 exploration. A4 still needs its scope decision before implementation. |

## Parent & provenance
- **Parent:** [#173](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/173) — Jedi Wright beta feedback, full trip report at [GH-173-JEDI-WRIGHT-FEEDBACK.md](GH-173-JEDI-WRIGHT-FEEDBACK.md)
- **Sibling:** [#175](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/175) — the Phase 1 low-fruit slice (B4/D2/A3), building now via [Marathon Plan E](MARATHON-PLAN-2026-07-07-E-BUILD.md)
- **This issue:** [#178](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/178) — the five items below

## Scope — 5 items on the epistemic / reconciliation layer
All evidence below carried forward verbatim from #173's Validation table (see that doc for the full first-pass + dogfood-mining narrative on each).

| # | Claim | Status | Evidence |
|---|---|---|---|
| B1 | **agy worktree grounding** *(highest priority — undermines the panel's grounding claim)* — agy saw zero repo files in a `consult.sh` worktree and answered from pure priors. | Plausible; hypothesis narrowed; **non-repro 2026-07-07 night** | `agy-turn.sh:146/61` already warn on "finds nothing"/empty-`-p`. `consult.sh:125-136`'s worktree seeding (stash/HEAD → `worktree add --detach` → untracked overlay) looks complete, arguing against incomplete-checkout. Re-run tonight was clean (agy fine) — looks intermittent; Phase 2 needs N repeated runs, not one. |
| B2 | **Stale HEAD-visibility warning** — relay warns the reviewer "will find nothing," then the run completes anyway. | **Fixed 2026-07-08** | Root cause: `relay-drive.sh:226-240`'s warning didn't account for `relay-turn-lib.sh`'s `rtl_worktree_begin()` unconditionally seeding the relay file's current content (always first in `RTL_ALLOW`) regardless of HEAD-tracked status. Fix: the warning now compares the relay file's repo toplevel against the turn-taker's effective root (`${RELAY_TARGET_ROOT:-$ROOT_DIR}`) — same repo → accurate informational NOTE (seeding covers it); different repo (archive-routed) → the original strong WARNING stays, since seeding provably can't reach it there. Mechanically proven by `test/relay-file-seeding-visibility.sh`, both directions. |
| A1 | **Advisor pluggability** — harness hardwires codex + agy. | Partially already present; sharpened 2026-07-07 evening | `consult.sh:28-29` exposes `--models codex,agy`. A third shim (`aider-turn.sh`, OpenRouter/GLM-5.2) proven live end-to-end tonight via the relay path (not yet via `consult.sh --models aider`, which remains untested). Gap is a generalized registry, not zero configurability. |
| A2 | **Single-advisor degraded-mode stamp** — no mechanical `SINGLE-MODEL — NOT RECONCILED` marker. | **Confirmed gap; live instance tonight** | No such stamp anywhere in the tree; `consult.sh:18` is "reconciled once" with no incomplete-panel marker. Live: tonight's first consult attempt returned `1 answered, 1 failed` (codex timeout) with nothing structurally marked degraded — caught only by the operator reading stdout. |
| A4 | **Verdict-layer provenance** *(likely the largest item — may need its own further split)* — distinguish firsthand-read facts from operator-asserted ones; flag asserted-only conclusions as conditional. | Plausible/design; sharpened by a live example tonight | References an external failure-mode catalog (not owned here). Live example: an advisor made a confident, dated, self-hedged claim tonight that was still wrong — the hedge alone didn't prevent the error, only independent verification caught it. Makes the case for *structural* provenance over model-supplied hedging. |

## Remediation checklist

### Phase 2 — Exploration (where evidence is still incomplete)
- [ ] **B1** — reproduce agy's zero-file visibility across N repeated `consult.sh` worktree runs (today's single re-run was clean); if reproduced, isolate CWD resolution vs. path-trust vs. something else on agy's side
- [ ] **A1** — inventory exactly what `--models` already generalizes vs. what stays codex/agy/aider-specific (turn scripts, reconciliation, config surface), to scope the registry design in Phase 3

### Phase 3 — Fixes (B2/A2 have enough root-cause evidence to start directly; B1/A1 gate on their Phase 2 above)
- [ ] **B1** — ensure agy sees the worktree's files, or fail-closed if it can't (don't let it silently answer from priors while claiming grounding)
- [x] **B2** — 2026-07-08: reconciled `warn_if_relay_file_untracked` with `rtl_worktree_begin`'s seeding — same-repo case downgraded to an accurate NOTE, cross-repo (archive-routed) case keeps the strong WARNING since seeding doesn't cover it there
- [ ] **A2** — mechanically stamp verdicts `SINGLE-MODEL — NOT RECONCILED` when the panel is incomplete, so the caveat is structural, not dependent on the operator reading stdout
- [ ] **A1** — extend `--models`/the turn-shim pattern into a generalized advisor registry, informed by the Phase-2 inventory above
- [ ] **A4** — first resolve the scope question (bundle here vs. spin out its own issue, given its size); then distinguish firsthand vs. asserted facts in verdict output and flag asserted-only conclusions as conditional

### Phase 4 — Verify
- [x] **B2** carries two passing regression tests: `test/relay-file-seeding-visibility.sh` (new — mechanical proof of the seeding mechanism itself) and `test/relay-untracked-file-warn.sh` (extended — warning-message behavior, both same-repo and cross-repo cases)
- [ ] Remaining items (B1, A1, A2, A4) each need their own regression test as they land
- [x] `utils/pdda/pdda.sh run` clean (checked 2026-07-08, ahead of commit)
- [x] `./validate.sh` green for touched surfaces (2026-07-08) — the only failure, `worktree-isolation.sh`, is confirmed pre-existing on clean `main`, unrelated to this work
- [ ] Link fix commit(s) back to #178 and #173 — pending this branch's first commit

## Non-goals
- B3 (reviewer citation) — stays in #173, needs more investigation before it's clearly in scope here.
- D1 (onboarding framing) — stays in #173 as a positive/keep item, no fix needed.
- B4/D2/A3 — already split to #175.
- Vendoring/authoring the external failure-mode catalog A4 references.
