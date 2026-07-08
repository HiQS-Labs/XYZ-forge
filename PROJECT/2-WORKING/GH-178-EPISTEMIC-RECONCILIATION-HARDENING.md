---
gh_issue: 178
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/178
title: "Epistemic/reconciliation-layer hardening: agy worktree grounding, stale HEAD-visibility warning, advisor pluggability, degraded-panel stamp, verdict provenance"
status: Active (2-WORKING) — B2 + A2 merged to main (PR #181), B1 root-caused, A1 inventoried (2026-07-08)
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
| **PR #181 merged to `main`** (`3da16b2`, 2026-07-08) — branch `fix/gh-178-reconciliation-hardening` is now on `main`; CI green. **B2 shipped** (`3784fe8`) and **A2 shipped** (`d85da37`) — see prior rows below; both carry regression tests, `./validate.sh` green except the confirmed-pre-existing `worktree-isolation.sh` failure. **B1 root-caused 2026-07-08** (doc-only, no code changed yet): a decisive live repro (gitignored marker file, so it never entered the throwaway worktree) proved agy does not confine grounding to its assigned CWD — it self-searches the filesystem and lands on the real repo root regardless. Reframes B1 from "sometimes zero visibility" to "grounding isn't scoped to the isolation boundary at all," with two candidate Phase 3 directions now written up (detect-and-warn vs. actual process-level containment). **A1 inventoried 2026-07-08** (doc-only): the safety core (`relay-turn-lib.sh`) is already vendor-agnostic across all 4 turn shims; the real gap is `consult.sh`'s `--models` being a fixed `case` instead of data, plus no written "add vendor N+1" recipe — narrower than the original "hardwired" framing. | A4 still needs its scope decision before implementation. B1/A1 Phase 3 fixes are now well-scoped and ready to pick up. |

## Parent & provenance
- **Parent:** [#173](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/173) — Jedi Wright beta feedback, full trip report at [GH-173-JEDI-WRIGHT-FEEDBACK.md](GH-173-JEDI-WRIGHT-FEEDBACK.md)
- **Sibling:** [#175](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/175) — the Phase 1 low-fruit slice (B4/D2/A3), building now via [Marathon Plan E](MARATHON-PLAN-2026-07-07-E-BUILD.md)
- **This issue:** [#178](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/178) — the five items below

## Scope — 5 items on the epistemic / reconciliation layer
All evidence below carried forward verbatim from #173's Validation table (see that doc for the full first-pass + dogfood-mining narrative on each).

| # | Claim | Status | Evidence |
|---|---|---|---|
| B1 | **agy worktree grounding** *(highest priority — undermines the panel's grounding claim)* — agy saw zero repo files in a `consult.sh` worktree and answered from pure priors. | **Root cause found 2026-07-08 — reframed, more severe than the original hypothesis** | `agy-turn.sh:146/61` already warn on "finds nothing"/empty-`-p`. `consult.sh:125-136`'s worktree seeding (stash/HEAD → `worktree add --detach` → untracked overlay) looks complete, arguing against incomplete-checkout — but the seeding was never the problem. Live repro (2026-07-08): asked agy (via `consult.sh --models agy`, real CWD=`$WT`) to quote a nonce token from a marker file. (1) With the marker present as an untracked file (so it's overlaid into `$WT` too), agy answered correctly but its transcript cited the absolute path of the operator's real repo checkout — not `$WT` — and narrated "searching the system for the file... to locate the active repository root." (2) Decisive variant: added the marker to `.gitignore` so `consult.sh`'s overlay (`git ls-files --others --exclude-standard`) never copies it into `$WT` — the file then does **not exist in the worktree at all**. agy *still* found and correctly quoted it, again citing the real repo root path. Conclusion: agy does not trust/use its assigned CWD as ground truth for grounding — it performs its own filesystem search and lands on whatever it finds, which in this repo is the live working tree, not the throwaway isolation worktree. This means (a) the panel's "advisory only, isolated" contract is provably broken for agy specifically — matches the consult skill's already-documented caveat ("agy... can still reach the host outside the worktree") but now with a concrete repro instead of a theoretical caveat, and (b) the original "zero visibility" symptom is plausibly the *same* underlying defect manifesting the other way — if agy's internal search fails to resolve a root (timing, an already-cleaned-up worktree, a search-depth limit) it falls back to priors instead of failing closed. One search strategy, two opposite-looking symptoms. |
| B2 | **Stale HEAD-visibility warning** — relay warns the reviewer "will find nothing," then the run completes anyway. | **Fixed 2026-07-08** | Root cause: `relay-drive.sh:226-240`'s warning didn't account for `relay-turn-lib.sh`'s `rtl_worktree_begin()` unconditionally seeding the relay file's current content (always first in `RTL_ALLOW`) regardless of HEAD-tracked status. Fix: the warning now compares the relay file's repo toplevel against the turn-taker's effective root (`${RELAY_TARGET_ROOT:-$ROOT_DIR}`) — same repo → accurate informational NOTE (seeding covers it); different repo (archive-routed) → the original strong WARNING stays, since seeding provably can't reach it there. Mechanically proven by `test/relay-file-seeding-visibility.sh`, both directions. |
| A1 | **Advisor pluggability** — harness hardwires codex + agy. | Inventoried 2026-07-08 — narrower gap than the framing suggests | Two independent surfaces, inventoried separately: **(1) consult.sh** already runs 4 advisors (`codex`, `agy`, `gemini` legacy alias, `aider`) behind one shared worktree-isolation + collect-results pipeline (`consult.sh:125-267`); `test/consult.sh` now covers `aider` end-to-end including graceful-degrade and auth-failure cases (added for A2). The actual gap: `--models` is a fixed `case "$m" in codex\|agy\|gemini\|aider\|*) warn` (`consult.sh:250-265`) — adding a 5th advisor still means writing a new `run_<vendor>()` function and a new case arm, not config. **(2) The relay turn-shims** (`codex-turn.sh` 182 lines, `agy-turn.sh` 259, `aider-turn.sh` 230, `claude-turn.sh` 257 — 928 total) all source the same 898-line `relay-turn-lib.sh` for every safety-relevant call (`rtl_init`, `rtl_worktree_begin/end`, `rtl_enforce`, `rtl_run_bounded`, 9-13 shared calls per shim) — the containment boundary is genuinely vendor-agnostic already, by design (`relay-turn-lib.sh:21`: "reimplementation is where a fourth bypass sneaks in"). A vendor-normalized diff of `codex-turn.sh` vs. `agy-turn.sh` still shows 225/441 lines differing, but nearly all of it is legitimately vendor-specific (CLI invocation syntax, auth pre-flight probe, flags, transcript-format quirks) — not copy-paste that a registry would eliminate. **Net:** the safety core is already a shared registry in effect; what's missing is (a) `consult.sh`'s advisor list being data instead of a `case` statement, and (b) a documented "how to add vendor N+1" recipe, since the 4th shim (`aider-turn.sh`) and 4th consult lane were each still a from-scratch ~200-line port of an existing shim's shape, done ad hoc rather than against a written template. Neither is a rewrite — both are additive, bounded changes. |
| A2 | **Single-advisor degraded-mode stamp** — no mechanical `SINGLE-MODEL — NOT RECONCILED` marker. | **Fixed 2026-07-08** | Root cause: `consult.sh` only ever reported the degrade as a transient stdout line — nothing survived with the transcript. Fix: when more than one advisor was requested and exactly one answered, `consult.sh` stamps `SINGLE-MODEL — NOT RECONCILED` into stdout, prepends it into the surviving transcript file, and writes a format-agnostic sidecar (`DEGRADED-SINGLE-MODEL.txt`) — so the caveat travels with the data for a reader days later, not just a live operator watching stdout. Scoped to genuine degrades only: a deliberate single-model request (`--models codex` alone) is not flagged. |
| A4 | **Verdict-layer provenance** *(likely the largest item — may need its own further split)* — distinguish firsthand-read facts from operator-asserted ones; flag asserted-only conclusions as conditional. | Plausible/design; sharpened by a live example tonight | References an external failure-mode catalog (not owned here). Live example: an advisor made a confident, dated, self-hedged claim tonight that was still wrong — the hedge alone didn't prevent the error, only independent verification caught it. Makes the case for *structural* provenance over model-supplied hedging. |

## Remediation checklist

### Phase 2 — Exploration (where evidence is still incomplete)
- [x] **B1** — 2026-07-08: root cause found via a decisive repro (see Scope table) — agy does not confine grounding to its assigned CWD (`$WT`); it self-searches the filesystem and lands on the real repo root, proven by a gitignored-marker variant where the file didn't exist in `$WT` at all and agy still found it via the real tree. Not a CWD-resolution bug on `consult.sh`'s side — `$WT` is correctly set; agy simply doesn't use it as ground truth.
- [x] **A1** — 2026-07-08: inventoried (see Scope table). `relay-turn-lib.sh` is already the shared, vendor-agnostic safety core (4 shims all route through it); the real gap is narrower than "hardwired" implied — `consult.sh`'s `--models` dispatch is a fixed `case` (data-as-code) and there's no written "add vendor N+1" recipe, not a missing containment abstraction.

### Phase 3 — Fixes (B2/A2 have enough root-cause evidence to start directly; B1/A1 gate on their Phase 2 above)
- [ ] **B1** — reframed by the Phase 2 finding: this is not "make agy see `$WT`'s files" (it already can, via its own search) but "make agy's grounding trustworthy or provably scoped." Two directions worth weighing before picking one: (a) detect-and-warn — pre-flight or post-hoc check that any file path agy's transcript cites resolves under `$WT`, not `$ROOT`, and flag/fail the run if it doesn't (cheap, doesn't fix agy, does stop a silent isolation-boundary breach from passing as clean); (b) actually contain it — run agy in a process/mount-level sandbox (chroot/container/bind-mount) so there is nothing outside `$WT` for it to find, closing the gap for real instead of detecting it. (a) is a days-scale mitigation; (b) is the structural fix the consult skill's "provable no-mutation boundary" claim actually needs to be true for agy. Either way, do not let a future "zero visibility" recur silently — if the search-and-fail-closed theory holds, the same detection layer in (a) also surfaces that failure mode explicitly instead of a silent prior-only answer.
- [x] **B2** — 2026-07-08: reconciled `warn_if_relay_file_untracked` with `rtl_worktree_begin`'s seeding — same-repo case downgraded to an accurate NOTE, cross-repo (archive-routed) case keeps the strong WARNING since seeding doesn't cover it there
- [x] **A2** — 2026-07-08: `consult.sh` mechanically stamps `SINGLE-MODEL — NOT RECONCILED` (stdout + surviving transcript + sidecar file) when a >1-requested panel degrades to exactly one survivor; intentional single-model requests stay unstamped
- [ ] **A1** — narrow, informed by the Phase-2 inventory: (1) turn `consult.sh`'s `case "$m"` dispatch into a small data table (name → run-function/bin-var), so adding an advisor doesn't require a new case arm; (2) write down the "add vendor N+1" recipe (what a new shim must source from `relay-turn-lib.sh`, what's legitimately vendor-specific) so the next port isn't another from-scratch read of an existing shim
- [ ] **A4** — first resolve the scope question (bundle here vs. spin out its own issue, given its size); then distinguish firsthand vs. asserted facts in verdict output and flag asserted-only conclusions as conditional

### Phase 4 — Verify
- [x] **B2** carries two passing regression tests: `test/relay-file-seeding-visibility.sh` (new — mechanical proof of the seeding mechanism itself) and `test/relay-untracked-file-warn.sh` (extended — warning-message behavior, both same-repo and cross-repo cases)
- [x] **A2** carries 8 new assertions in `test/consult.sh`: stdout stamp, in-transcript stamp, sidecar marker, stamped-content-not-corrupted, plus non-regression checks that a full panel and an intentional single-model request both stay unstamped
- [ ] Remaining items (B1, A1, A4) each need their own regression test as they land
- [x] `utils/pdda/pdda.sh run` clean (checked 2026-07-08, ahead of each commit)
- [x] `./validate.sh` green for touched surfaces (2026-07-08, both B2 and A2 passes) — the only failure, `worktree-isolation.sh`, is confirmed pre-existing on clean `main`, unrelated to this work
- [x] Link fix commit(s) back to #178 and #173 — B2 is `3784fe8`; A2 is `d85da37`; both merged to `main` via PR #181 (`3da16b2`), 2026-07-08. #173's status-update comment also links back here.

## Non-goals
- B3 (reviewer citation) — stays in #173, needs more investigation before it's clearly in scope here.
- D1 (onboarding framing) — stays in #173 as a positive/keep item, no fix needed.
- B4/D2/A3 — already split to #175.
- Vendoring/authoring the external failure-mode catalog A4 references.
