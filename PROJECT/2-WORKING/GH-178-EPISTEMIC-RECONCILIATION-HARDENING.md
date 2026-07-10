---
gh_issue: 178
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/178
title: "Epistemic/reconciliation-layer hardening: agy worktree grounding, stale HEAD-visibility warning, advisor pluggability, degraded-panel stamp, verdict provenance"
status: Active (2-WORKING) — B1, B2, A2, A1, and a scoped A4 slice shipped (2026-07-08); B1's #183/#187 caveats fixed via PR #193 (2026-07-10)
created: 2026-07-08
updated: 2026-07-10
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
| **B1's #183/#187 false-positive caveats fixed 2026-07-10** via [PR #193](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/193) — dogfooded through a real marathon relay (Aider/GLM-5.2 builder, agy reviewer); see "Lessons learned" below for two operational gaps found while driving it. **PR #181 merged to `main`** (`3da16b2`, 2026-07-08) — branch `fix/gh-178-reconciliation-hardening` is now on `main`; CI green. **B2 shipped** (`3784fe8`) and **A2 shipped** (`d85da37`) — see prior rows below; both carry regression tests, `./validate.sh` green except the confirmed-pre-existing `worktree-isolation.sh` failure. **B1 shipped 2026-07-08**: Implemented detect-and-warn (verifiably scoped) boundary logic. agy's output transcript is post-hoc scanned for the real repo root path; any citation constitutes an isolation breach, failing the turn loudly instead of silently reporting a contaminated answer. Evaluated strict macOS sandbox-exec containment but it causes severe CLI hangs during repository resolution, making detection the only robust path. **A1 shipped 2026-07-08**: `consult.sh`'s `case "$m" in codex\|agy\|gemini\|aider)` dispatch is now a data table (`ADV_NAMES`/`ADV_RUNFNS` parallel arrays); adding a 5th advisor is a data addition, not a new case arm. "Add vendor N+1" recipe written into `relay-automation/README.md`. **A4 (scoped slice) shipped 2026-07-08**: reused A2's exact stdout+prepended-transcript+sidecar mechanism to mechanically stamp `NO FIRSTHAND VERIFICATION CITED — treat conclusions as conditional` on any answered advisor whose transcript carries zero explicit file:line/quoted-content citations anywhere — deliberately NOT the full firsthand-vs-asserted provenance taxonomy A4 originally asked for (see the A4 row and Non-goals below; that larger design stays future-scoped). | All five #178 items now have a shipped fix; A4's fuller taxonomy is intentionally NOT this pass's scope (see Non-goals) — a future issue can pick it up if still wanted. |

## Parent & provenance
- **Parent:** [#173](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/173) — Jedi Wright beta feedback, full trip report at [GH-173-JEDI-WRIGHT-FEEDBACK.md](GH-173-JEDI-WRIGHT-FEEDBACK.md)
- **Sibling:** [#175](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/175) — the Phase 1 low-fruit slice (B4/D2/A3), building now via [Marathon Plan E](MARATHON-PLAN-2026-07-07-E-BUILD.md)
- **This issue:** [#178](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/178) — the five items below

## Scope — 5 items on the epistemic / reconciliation layer
All evidence below carried forward verbatim from #173's Validation table (see that doc for the full first-pass + dogfood-mining narrative on each).

| # | Claim | Status | Evidence |
|---|---|---|---|
| B1 | **agy worktree grounding** *(highest priority — undermines the panel's grounding claim)* — agy saw zero repo files in a `consult.sh` worktree and answered from pure priors. | **Fixed 2026-07-08** | `agy-turn.sh:146/61` already warn on "finds nothing"/empty-`-p`. `consult.sh:125-136`'s worktree seeding (stash/HEAD → `worktree add --detach` → untracked overlay) looks complete, arguing against incomplete-checkout — but the seeding was never the problem. Live repro (2026-07-08): asked agy (via `consult.sh --models agy`, real CWD=`$WT`) to quote a nonce token from a marker file. (1) With the marker present as an untracked file (so it's overlaid into `$WT` too), agy answered correctly but its transcript cited the absolute path of the operator's real repo checkout — not `$WT` — and narrated "searching the system for the file... to locate the active repository root." (2) Decisive variant: added the marker to `.gitignore` so `consult.sh`'s overlay (`git ls-files --others --exclude-standard`) never copies it into `$WT` — the file then does **not exist in the worktree at all**. agy *still* found and correctly quoted it, again citing the real repo root path. Conclusion: agy does not trust/use its assigned CWD as ground truth for grounding — it performs its own filesystem search and lands on whatever it finds, which in this repo is the live working tree, not the throwaway isolation worktree. **Fix:** Implemented transcript scanning for the real `$ROOT` path in `consult.sh` and `agy-turn.sh`. This ensures agy is *verifiably scoped*: if it escapes the `$WT` and finds the main repo, it fails the turn (exit 5) with a loud `[FAIL]` in the transcript instead of passing off contaminated context as isolated ground truth. Explored macOS `sandbox-exec` but restricting agy's git lookup traversal caused it to hang indefinitely. |
| B2 | **Stale HEAD-visibility warning** — relay warns the reviewer "will find nothing," then the run completes anyway. | **Fixed 2026-07-08** | Root cause: `relay-drive.sh:226-240`'s warning didn't account for `relay-turn-lib.sh`'s `rtl_worktree_begin()` unconditionally seeding the relay file's current content (always first in `RTL_ALLOW`) regardless of HEAD-tracked status. Fix: the warning now compares the relay file's repo toplevel against the turn-taker's effective root (`${RELAY_TARGET_ROOT:-$ROOT_DIR}`) — same repo → accurate informational NOTE (seeding covers it); different repo (archive-routed) → the original strong WARNING stays, since seeding provably can't reach it there. Mechanically proven by `test/relay-file-seeding-visibility.sh`, both directions. |
| A1 | **Advisor pluggability** — harness hardwires codex + agy. | **Fixed 2026-07-08** | Two independent surfaces, inventoried separately: **(1) consult.sh** already runs 4 advisors (`codex`, `agy`, `gemini` legacy alias, `aider`) behind one shared worktree-isolation + collect-results pipeline (`consult.sh:125-267`); `test/consult.sh` now covers `aider` end-to-end including graceful-degrade and auth-failure cases (added for A2). The actual gap was: `--models` was a fixed `case "$m" in codex\|agy\|gemini\|aider\|*) warn` (`consult.sh:250-265`) — adding a 5th advisor meant writing a new `run_<vendor>()` function AND a new case arm, not config. **(2) The relay turn-shims** (`codex-turn.sh` 182 lines, `agy-turn.sh` 259, `aider-turn.sh` 230, `claude-turn.sh` 257 — 928 total) all source the same `relay-turn-lib.sh` for every safety-relevant call (`rtl_init`, `rtl_worktree_begin/end`, `rtl_enforce`, `rtl_run_bounded`) — the containment boundary is genuinely vendor-agnostic already, by design (`relay-turn-lib.sh:21`: "reimplementation is where a fourth bypass sneaks in"); left as-is, no changes needed there. **Fix (scoped to (1) only, as the inventory recommended):** `consult.sh`'s advisor dispatch is now a data table — `ADV_NAMES=(codex agy gemini aider)` / `ADV_RUNFNS=(run_codex run_agy run_gemini run_aider)` parallel arrays (`consult.sh:266-271`), looked up in the fan-out loop instead of a `case`. Adding a 5th advisor is now a data addition (one array entry + its own `run_<vendor>()`), not a new case arm. The "add vendor N+1" recipe is written into `relay-automation/README.md` → "Adding a new consult advisor (GH-178 A1)": what a new `run_<vendor>()` must own itself (CLI syntax, auth pre-flight, transcript quirks) vs. what's shared for free (`_guarded`'s timeout watchdog in `consult.sh`; `relay-turn-lib.sh`'s containment contract for a relay turn-shim). |
| A2 | **Single-advisor degraded-mode stamp** — no mechanical `SINGLE-MODEL — NOT RECONCILED` marker. | **Fixed 2026-07-08** | Root cause: `consult.sh` only ever reported the degrade as a transient stdout line — nothing survived with the transcript. Fix: when more than one advisor was requested and exactly one answered, `consult.sh` stamps `SINGLE-MODEL — NOT RECONCILED` into stdout, prepends it into the surviving transcript file, and writes a format-agnostic sidecar (`DEGRADED-SINGLE-MODEL.txt`) — so the caveat travels with the data for a reader days later, not just a live operator watching stdout. Scoped to genuine degrades only: a deliberate single-model request (`--models codex` alone) is not flagged. |
| A4 | **Verdict-layer provenance** *(likely the largest item — may need its own further split)* — distinguish firsthand-read facts from operator-asserted ones; flag asserted-only conclusions as conditional. | **Scoped slice shipped 2026-07-08 — NOT the full taxonomy** | References an external failure-mode catalog (not owned here; still not vendored). Live example (2026-07-07): an advisor made a confident, dated, self-hedged claim that was still wrong — the hedge alone didn't prevent the error, only independent verification caught it. Made the case for *structural* provenance over model-supplied hedging. **Shipped slice:** reused A2's exact mechanism (stdout + prepended-into-transcript + format-agnostic sidecar) rather than inventing a new one. When an answered advisor's transcript contains ZERO explicit `file:line` or quoted-content citations anywhere, `consult.sh` stamps `NO FIRSTHAND VERIFICATION CITED — treat conclusions as conditional` into stdout, prepends it into that advisor's transcript, and writes a per-advisor sidecar (`<label>.<model>.NO-CITATION.txt`). Scoped to not fire when the advisor cited anything (a quote or a `file:line`, anywhere in its answer). **This is deliberately NOT** the firsthand-vs-asserted distinction A4 originally asked for: it does not distinguish a fact the advisor read itself from one the operator asserted in the prompt, and it does not check whether a PRESENT citation is accurate — it is a presence/absence check only, same spirit as B3's uncited-`[Pass]` mechanism. The fuller taxonomy (and the external failure-mode catalog it would reference) stays future-scoped; see Non-goals. **Code-review follow-up, same day:** a review of PR #184 flagged that "zero citations ANYWHERE in the whole transcript" let one incidental early citation excuse every later uncited claim. Tightened to reuse B3's new per-claim, proximity-based `rtl_has_uncited_claim()` predicate (`relay-turn-lib.sh`) — now flags EITHER a transcript with zero citations anywhere (the original spec) OR one with some citation but at least one `[Pass]`/verified/confirmed/etc-style claim with none nearby. Test suite grew to 5 assertions (+2), and the non-regression fixture (test 13) was corrected to cite each claim individually rather than once anywhere in the transcript. |

## Remediation checklist

### Phase 2 — Exploration (where evidence is still incomplete)
- [x] **B1** — 2026-07-08: root cause found via a decisive repro (see Scope table) — agy does not confine grounding to its assigned CWD (`$WT`); it self-searches the filesystem and lands on the real repo root, proven by a gitignored-marker variant where the file didn't exist in `$WT` at all and agy still found it via the real tree. Not a CWD-resolution bug on `consult.sh`'s side — `$WT` is correctly set; agy simply doesn't use it as ground truth.
- [x] **A1** — 2026-07-08: inventoried (see Scope table). `relay-turn-lib.sh` is already the shared, vendor-agnostic safety core (4 shims all route through it); the real gap is narrower than "hardwired" implied — `consult.sh`'s `--models` dispatch is a fixed `case` (data-as-code) and there's no written "add vendor N+1" recipe, not a missing containment abstraction.

### Phase 3 — Fixes (B2/A2 have enough root-cause evidence to start directly; B1/A1 gate on their Phase 2 above)
- [x] **B1** — 2026-07-08: implemented "verifiably scoped" boundary check. Transcript scanning now catches absolute references to the real repo root, failing the turn if an escape is detected. Strict macOS sandboxing proved unviable due to CLI hangs.
- [x] **B2** — 2026-07-08: reconciled `warn_if_relay_file_untracked` with `rtl_worktree_begin`'s seeding — same-repo case downgraded to an accurate NOTE, cross-repo (archive-routed) case keeps the strong WARNING since seeding doesn't cover it there
- [x] **A2** — 2026-07-08: `consult.sh` mechanically stamps `SINGLE-MODEL — NOT RECONCILED` (stdout + surviving transcript + sidecar file) when a >1-requested panel degrades to exactly one survivor; intentional single-model requests stay unstamped
- [x] **A1** — 2026-07-08: `consult.sh`'s `case "$m"` dispatch is now a small data table (`ADV_NAMES`/`ADV_RUNFNS` parallel arrays); adding an advisor is a data addition, not a new case arm. "Add vendor N+1" recipe written into `relay-automation/README.md`.
- [x] **A4** — 2026-07-08 (scoped slice, per the operator's explicit scope-down instruction): shipped the narrower "no citation anywhere" mechanical stamp (see Scope table) using A2's exact mechanism, instead of the full firsthand-vs-asserted taxonomy. The fuller distinction stays future-scoped — see Non-goals.

### Phase 4 — Verify
- [x] **B2** carries two passing regression tests: `test/relay-file-seeding-visibility.sh` (new — mechanical proof of the seeding mechanism itself) and `test/relay-untracked-file-warn.sh` (extended — warning-message behavior, both same-repo and cross-repo cases)
- [x] **A2** carries 8 new assertions in `test/consult.sh`: stdout stamp, in-transcript stamp, sidecar marker, stamped-content-not-corrupted, plus non-regression checks that a full panel and an intentional single-model request both stay unstamped
- [x] **B1** carries a new regression test (`test/test-agy-isolation.sh`) that mocks agy outputting the real `$ROOT` path, asserting that both `consult.sh` and `agy-turn.sh` catch it, write the failure message, and exit 5. **Caveat found in PR #182 review:** the check false-positives on a legitimate turn whenever agy's response narrates the mandatory tick command (which itself embeds `$ROOT` via `TICK_REPO_ROOT`) — the shipped test's "safe" mock never exercises that realistic shape. Confirmed by live repro; tracked as [#183](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/183), shipped as-is per operator call. B1's status should read "detects one leak symptom, not structural containment" rather than "verifiably scoped."
- [x] **A1** carries 3 new assertions in `test/consult.sh`: an unknown model name in `--models` is warned + skipped (not a fatal error), and a valid model elsewhere in the same list still runs (proves the array-lookup dispatch, not the removed `case`, still degrades gracefully on an unrecognized name)
- [x] **A4** carries 5 new assertions in `test/consult.sh` (+2 from the code-review follow-up): an uncited answer is stamped on stdout + transcript + a per-advisor sidecar with the real answer preserved beneath the stamp, a cited answer (quote or `file:line`) is confirmed NOT stamped (non-regression, every claim cited near itself), and a LATER uncited claim is flagged despite an EARLIER unrelated citation elsewhere in the same transcript (proves the per-claim tightening, not just whole-transcript presence)
- [x] `utils/pdda/pdda.sh run` clean (checked 2026-07-08, ahead of each commit)
- [x] `./validate.sh` green for touched surfaces (2026-07-08) — targeted runs: `test/consult.sh` (41/41), `test/relay-uncited-findings.sh` (8/8, new), plus regression sweeps of `test/agy-turn.sh`, `test/codex-turn.sh`, `test/claude-turn.sh`, `test/aider-turn.sh`, `test/shim-worktree.sh`, `test/relay-turn-trace.sh`, `test/new-relay.sh`, `test/relay-target-root.sh`, `test/relay-case-insensitive.sh`, `test/test-agy-isolation.sh` (all green). The full `validate.sh` was not re-run at first (109 tests; targeted subset is the documented default for a bounded patch) — `test/relay-file-seeding-visibility.sh`'s pre-existing `git worktree add` sandbox failure (confirmed present before this change too) is the only known non-green test in the touched-file set, unrelated to this work. **Update (same day, code-review follow-up):** ran the full `./validate.sh` (item 4 of that follow-up) — `test/consult.sh` grew to 43/43 (A4's +2 assertions), `test/relay-uncited-findings.sh` grew to 16/16. Caught and fixed a real gap the targeted-subset approach missed: `skills/relay-automation/relay-pkg.tar.gz` had drifted stale since the original PR (never rebuilt after touching `new-relay.sh`/`relay-turn-lib.sh`/`README.md`), failing `relay-pkg-freshness.sh` — rebuilt via `make-pkg.sh`, now green. Remaining 2 reds (`acorn-extract.sh` missing the `acorn` npm module, `python:test_python_layer.py` missing `pytest`) are pre-existing environment gaps, confirmed present on the PR's original head commit via `git stash` — unrelated to this work.
- [x] Link fix commit(s) back to #178 and #173 — B2 is `3784fe8`; A2 is `d85da37`; both merged to `main` via PR #181 (`3da16b2`), 2026-07-08. **B3/A1/A4** land together as `17c1dc4` via [PR #184](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/184), linked back to both #173 and #178.

## Lessons learned — GH-183/GH-187 dogfood fix (2026-07-10)

GH-183 and GH-187 (both false-positive shapes on B1's transcript scan — see Scope table above)
were fixed via a real dogfood run: Aider driving OpenRouter's GLM-5.2 as builder, agy as
independent reviewer, `marathon-drive.sh --builder aider --reviewer agy` (worktree-isolated, no
push). Approved on round 2; shipped as [PR #193](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/193).
Two operational gaps surfaced while driving that run, neither in the fix itself:

1. **A killed foreground driver call can leave an orphaned background process undetected.**
   Driving `marathon-drive.sh` from an agent session risks the calling tool's own foreground
   timeout killing the *supervising* shell — but if that shell was launched by hand-rolling
   backgrounding (`nohup ... & disown`) instead of the calling tool's native background-execution
   primitive, the backgrounded job can survive the kill and keep running **undetected**, racing a
   subsequent re-fire against the same repo/worktree state. Observed symptom here: a stray
   `git worktree` left behind and a `tick` claim stuck in `claimed` status (the shim never got to
   hand it off). Recovery: `git worktree remove --force <path>` + `tick reap <agent> --by <caller>
   --task <task>` — `reap` is the sanctioned path (logs an auditable `task.released` event with
   `note: "reaped by <caller>: agent presumed crashed"`), not a hand-written `tick release`.
   Prevention: never hand-roll backgrounding for anything that drives this harness — always use the
   calling tool/shell's own background-execution mechanism so a timeout can't silently orphan a
   live driver.
2. **Any edit to `relay-automation/*.sh` needs `skills/relay-automation/make-pkg.sh` re-run before
   `validate.sh` is truly green.** `relay-pkg-freshness.sh` catches a stale vendored
   `relay-pkg.tar.gz`, but this is now a **second, independent recurrence on this same doc** — the
   original B1/A4 pass hit the identical gap on 2026-07-08 (see the Phase 4 verify note above:
   "Caught and fixed a real gap the targeted-subset approach missed... rebuilt via `make-pkg.sh`").
   Two hits on one doc in two days suggests this is a standing trap, not a one-off — worth a rule
   at the skill layer (added to `skills/relay-xyz/SKILL.md`'s pre-run checklist), not just a test
   assertion discovered after the fact.

Both gaps are about *driving* the harness, not about GH-178's substance (B1/B2/A1/A2/A4) — recorded
here because this is the doc that owns the isolation-detector work where they surfaced, and because
the pattern (killed-driver races, stale package) is exactly the kind of operational bug this issue's
epistemic-hardening spirit cares about: don't let a silent gap between "looks done" and "verified
done" stand.

## Non-goals
- B3 (reviewer citation) — **shipped 2026-07-08 in #173** (this issue's non-goal only meant "not owned here"; see [GH-173-JEDI-WRIGHT-FEEDBACK.md](GH-173-JEDI-WRIGHT-FEEDBACK.md) for the fix).
- D1 (onboarding framing) — stays in #173 as a positive/keep item, no fix needed.
- B4/D2/A3 — already split to #175.
- Vendoring/authoring the external failure-mode catalog A4 references — still not vendored; the shipped A4 slice needed none of it (presence/absence of a citation only).
- **A4's full firsthand-vs-asserted provenance taxonomy** — explicitly NOT this pass's scope per the operator's scope-down instruction. What's shipped is a narrower "did the advisor cite ANYTHING" mechanical check; it does not distinguish a firsthand-read fact from an operator-asserted one, and does not verify a present citation's accuracy. A future issue can pick up the fuller distinction (and, if ever wanted, the external failure-mode catalog) as its own bounded slice.
