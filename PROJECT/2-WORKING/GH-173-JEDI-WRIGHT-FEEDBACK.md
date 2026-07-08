---
gh_issue: 173
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/173
title: "Jedi Wright beta feedback: agy worktree grounding, non-re-checked HEAD warning, uncited reviewer, degraded-panel stamping"
status: Working (2-WORKING) — Phase 1 + partial Phase 3 shipped to main via #175/#178; B3 shipped 2026-07-08
created: 2026-07-07
updated: 2026-07-08
owner: noel
doc_type: feedback
complexity: 4
risk: 3
effort: 4
phases: 5
ratings_provisional: true
goal: >
  Triage Jedi Wright's beta trip report (fast-path Consult+Relay trial) into verified bugs and
  architecture gaps, validate each against the live tree, and split into actionable follow-up work:
  the low-fruit docs/attestation slice (#175, building now), the epistemic/reconciliation-layer
  hardening cluster (#178: agy grounding, stale warning, advisor pluggability, degraded-panel stamp,
  verdict provenance), and the two items still needing more investigation before they split further
  (B3 reviewer citation, D1 onboarding framing — the latter needs no fix, just regression-protection).
related:
  - relay-automation/consult.sh
  - relay-automation/agy-turn.sh
  - relay-automation/codex-turn.sh
  - relay-automation/aider-turn.sh
  - relay-automation/relay-drive.sh
  - relay-automation/relay-turn-lib.sh
non_goals:
  - Not implementing the fixes in this doc — this is a triaged 1-INBOX capture; execution starts on promotion to 2-WORKING
  - Not re-auditing Swarm / Marathon / HQ / tick export — the reporter explicitly kept those out of the trial's scope
  - Not vendoring or authoring the external ra-to-xyz-transfer.md epistemic catalog here (external artifact; referenced, not owned by this repo)
---

# GH-173 — Jedi Wright beta feedback (Consult + Relay fast-path trial, 7/6–7/7)

## Status

| What was just completed | What's next |
|---|---|
| **2026-07-08:** both split tracks landed on `main`. **#175** (B4/D2/A3) merged via PR #179 (`39729a0`). **#178** shipped its first slice — B2/A2 — via PR #181 (`3da16b2`); B1 was root-caused and fixed. **B3 shipped 2026-07-08** (this doc): the Phase 2 read found the actual source of the uncited "[Pass]" claim is `new-relay.sh`'s scaffolded Reviewer template (the "▶ TAKE YOUR TURN" block a Reviewer turn reads and follows via `relay-turn-lib.sh`'s `rtl_turn_prompt`) — NOT `consult.sh`'s advisor PREAMBLE (that path already showed unprompted citation in dogfooding) and not `rtl_turn_prompt`'s generic role_note (which never defined the `[Pass]` grading scheme itself). Fix: one added sentence in `new-relay.sh` requiring a citation on `[Pass]`/"verified" findings, plus a mechanical post-hoc downgrade (`rtl_check_uncited_findings` in `relay-turn-lib.sh`, called from `rtl_enforce` on Reviewer turns) that rewrites an uncited claim to `[Unverified — no citation]` in place — catches the ABSENCE of a citation only, not whether a present one is accurate. | **#178**: A1 registry + A4 scope decision (see that doc). **This doc**: D1 needs no fix, regression-protect only — nothing else outstanding here. |

| Phase | Description | Status |
|---|---|---|
| 0 | Triage & scope | ✅ Done |
| 1 | Low-fruit fixes (#175) | ✅ Done — merged to `main` (PR #179) |
| 2 | Deeper exploration / reproduction | Done — B1/A1 done (via #178); B3 read done 2026-07-08 (this doc) |
| 3 | Behavior & architecture fixes | Partial — B1/B2/A2 shipped to `main` (via #178, PR #181); **B3 shipped 2026-07-08** (this doc); A1/A4 fixes pending in #178; D1 not started (no fix needed) |
| 4 | Verify | Partial — B1/B2/A2/B3 carry regression tests; A1/A4 pending |

## Source report
- **Report / tracking issue:** [#173](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/173) (native origin issue)
- **Reported by / date:** noelsaw1 — 2026-07-07
- **Scale:** ~6.7 KB single-issue write-up, 0 comments — a full beta trip report, triaged below (not transcribed whole)
- **Scope of the trial:** validated the **fast path only** — Consult + Relay end-to-end on real work + kernel test suite. Swarm, Marathon, HQ, PDDA, and `tick` export were untested and out of scope.

## Problem summary
A newcomer took the harness from zero to a shipped, reviewed skill on the fast path — Consult produced a
genuine multi-model second opinion, and a one-round Relay built + reviewed a real "router" skill (10/10 on
a hidden exam). The trust story mostly held, but the trial surfaced **four verified behavior bugs** and
**four architecture gaps**, all clustered on the harness's weakest link: the **epistemic / reconciliation
layer** — how it proves an advisor actually read what it claims to have read. The highest-priority item
is an **agy file-visibility quirk in worktrees** (agy answered from pure priors while seeing zero repo
files), because it undermines the grounding claim the whole advisor panel rests on. Two doc/onboarding
notes and a "keep these" list round it out.

## Validation — first pass (light)
Cheap checks only against the live tree; full reproduction is Phase 2. "Plausible" here means the
reporter verified it in a real run and a quick code read is consistent, but I did not re-run it.

| # | Claim from report | First-pass read | Evidence |
|---|---|---|---|
| B1 | **agy file-visibility quirk** — in the 7/7 consult, agy saw zero repo files in a worktree despite running alongside Codex; pre-checked fine in the main repo dir. Highest priority. | **Plausible — partly corroborated; hypothesis narrowed 2026-07-07 evening** | `agy-turn.sh:146` already warns agy "silently 'finds nothing'"; `agy-turn.sh:61` treats empty `agy -p` output as a FALSE success. **Update:** read `consult.sh:125-136` (its worktree build — this consult was reported via `consult.sh`, not a relay turn, so this is the actually-relevant code path, not `relay-turn-lib.sh`'s separate `rtl_worktree_begin`). The seeding looks complete: `git stash create` (or HEAD) → `git worktree add --detach` → an untracked-not-ignored file overlay — so an incomplete-checkout theory is now unlikely. This argues the root cause sits on agy's own side (CWD resolution, or path-trust/recognition of a brand-new `$TMPDIR/consult-wt-*` path it's never seen) rather than in the harness's seeding logic. Narrows Phase-2's hypothesis space; still needs a live repro to confirm. **Non-repro today:** agy ran fine in today's WORKTREE-SAFETY.md consult (via `consult.sh`, the same code path Jedi hit) — it read and correctly cited repo content, no zero-visibility symptom. Useful negative data point: B1 is intermittent, not a hard failure on every worktree consult, which should shape the Phase-2 repro strategy (needs N repeated runs, not one). |
| B2 | **HEAD-visibility warning doesn't re-check** — relay warned the reviewer would find nothing, then the run completed anyway; Producer's commit cured it, but the harness never re-evaluated, forcing manual forensics. | **Root cause found 2026-07-07 night — related but sharper than reported** | Emitting site: `relay-drive.sh:226-240` (`warn_if_relay_file_untracked`) — tests `git cat-file -e HEAD:$rel` and warns "INVISIBLE... will find nothing" if the relay file isn't committed at HEAD. **Live instance today:** this warning fired for real on an uncommitted relay file, yet the driven aider/GLM turn completed normally and produced a genuine review — not the predicted "finds nothing." Root cause: `relay-turn-lib.sh`'s `rtl_worktree_begin()` (the seeding step, which runs *after* this warning, inside the shim) always copies the relay file's **current** content into the worktree — it's unconditionally in `RTL_ALLOW`, regardless of HEAD-tracked status. So the warning's premise (only HEAD content is visible) is stale relative to the seeding mechanism that already solves it; it's a false-positive generator, not (only) a missing re-check. Jedi's framing ("never re-evaluated after commit") describes a related but distinct angle — a multi-round relay where the warning should clear post-commit; today's finding is a pre-turn false-positive on the *initial* check. Both point at the same subsystem needing one coherent fix. |
| B3 | **Reviewer asserts without citing** — agy's review claimed it was "supported by explicit source text" but quoted none; the claim checked out, but only after a manual audit. | **Fixed 2026-07-08** | Phase 2 read (2026-07-08) confirmed the actual source: Jedi's report was about a **Relay** review (`new-relay.sh`-scaffolded thread), not a `consult.sh` advisor panel — consistent with the dogfooding counter-evidence (consult advisors cited unprompted; a relay Reviewer wasn't asked to). Checked both candidates named in the original triage: `relay-turn-lib.sh`'s `rtl_turn_prompt` role_note only says "append your graded findings" (no citation requirement, doesn't even define the `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]` scheme); `consult.sh`'s advisor PREAMBLE already asks advisors to "cite evidence." Neither is the actual template a Reviewer follows — `rtl_turn_prompt` tells the model to "read [the relay file] and follow its embedded '▶ TAKE YOUR TURN' steps," which is the text `new-relay.sh` scaffolds (`new-relay.sh:79-81`): "graded findings ([Blocker]/[Should]/[Nit]/[Pass])... set a Verdict" — with NO citation requirement. That's the actual template. **Fix:** `new-relay.sh:79-81` now requires a quoted span or `file:line` citation for any `[Pass]`/"verified"/"confirmed" finding. Backstopped mechanically (not just prompt compliance) by `relay-turn-lib.sh`'s new `rtl_check_uncited_findings()`, called from `rtl_enforce()` on Reviewer turns only (gated on a new `RTL_WAS_REVIEWER_TURN` flag captured in `rtl_init`, since `NEXT` has already flipped by the time `rtl_enforce` runs): scans the relay file for `[Pass]`/"verified"/"confirmed" with no quote or `file:line` citation within 3 lines, and rewrites it in place to `[Unverified — no citation]` before the turn's commit. Catches the ABSENCE of a citation only — does not verify a present citation is accurate (out of scope, no citation-verification engine). Regression test: `test/relay-uncited-findings.sh` (8 assertions). **Code-review follow-up, same day:** a review of PR #184 flagged that the 3-word trigger list (`[Pass]`/verified/confirmed) let an assertion like "looks good, no issues, ship it" bypass the backstop entirely. Widened to `RTL_CLAIM_WORD_RE` (adds LGTM/looks good/checks out/all good/works as expected/no issues). **Caught while fixing that:** passing `\[Pass\]` through `awk -v` silently corrupts it under macOS's default awk (the -v value's backslash is stripped before the string compiles as a regex, turning the literal tag into a bracket expression matching almost any line) — fixed by keeping the `[Pass]` tag check as an inline `/regex/` literal in the awk source and only passing the backslash-free prose words through `-v`. Test suite grew to 16 assertions (+6, including a dedicated regression guard for the `awk -v` corruption). |
| B4 | **Two environment items** — (a) agy triggered a macOS Documents-folder permission prompt mid-headless-run; (b) agy's `-p` requirement was misdiagnosed by Claude Code as "requires interactive TTY". | **Plausible** | `agy-turn.sh` owns `-p`/empty-output handling; the TTY misdiagnosis is a Claude Code-side/bring-up-doc note, not a harness bug. |
| A1 | **Advisor pluggability** — harness hardwires codex + agy; make the advisor set configurable. | **Partially already present — sharpened 2026-07-07 evening** | `consult.sh:28-29` already exposes `--models codex,agy`. **Update:** a *third* turn-taker shim (`aider-turn.sh`, driving OpenRouter models — GLM-5.2 confirmed live end-to-end today, see below) already exists and works with the same `relay-turn-lib.sh` containment contract as codex/agy. That run went through the relay path (`relay-drive.sh --agent-cmd aider-turn.sh`), not `consult.sh --models aider` — the latter is documented in `relay-automation/README.md` but wasn't exercised today, so it's still unconfirmed, not newly proven. Net: the per-vendor plumbing generalizes further than the table previously credited; the gap is still a *generalized advisor registry* (one config surface instead of three near-duplicate shims), not zero configurability. |
| A2 | **Single-advisor degraded mode** — mechanically stamp verdicts `SINGLE-MODEL — NOT RECONCILED` when the panel is incomplete, so caveats are structure, not model goodwill. | **Confirmed gap — live instance today** | No `SINGLE-MODEL` stamp anywhere in the tree; consult is "reconciled once" (`consult.sh:18`) with no mechanical incomplete-panel marker. **Live instance:** today's first WORKTREE-SAFETY.md consult attempt timed out on codex (killed at the 300s cap) and returned `1 answered, 1 failed`; the operator (me) had to notice the degrade from plain stdout and manually retry codex with a longer timeout. Nothing in the output was structurally marked degraded — exactly the failure mode A2 describes, caught only because the operator happened to read the summary line. |
| A3 | **Preflight attestation is nearly free** — parse Codex exec's session preamble (model/provider/sandbox) instead of generating attestation; closes the "unattested panel" gap. | **Plausible / new** | No preamble/attestation parsing found in `consult.sh`/`codex-turn.sh`; low-effort additive parse. |
| A4 | **Verdict-layer provenance** — verdicts should distinguish facts advisors read firsthand from facts the operator asserted, and flag conclusions resting on asserted facts as conditional. References external `ra-to-xyz-transfer.md` (7 transfers) + a named failure-mode catalog. | **Plausible / design — sharpened by a live example today** | `ra-to-xyz-transfer.md` not in this repo (external). Largest item; touches the reconciliation contract — Costly, likely its own design issue. **Live example:** in today's aider/GLM-5.2 relay review of `WORKTREE-SAFETY.md`, GLM confidently asserted `git worktree repair` "was introduced in Git 2.24.0 (November 2019)" — specific, dated, reads as sourced — and appended its own hedge ("Verify exact version against Git release notes"). The claim was wrong (independently verified against `git/git`'s tagged docs on GitHub: actually 2.29.0); the model's *own* hedge was the only signal it wasn't firsthand-verified, and only independent verification caught the error the hedge flagged but didn't prevent. This is precisely A4's case for structural provenance over model-supplied hedging: the hedge existed here and still wasn't sufficient on its own — a caveat that isn't enforced is easy to skim past. |
| D1 | **Onboarding guide works** — zero-to-shipped on the fast path; reversibility framing (branch-first, what-each-step-touches) made the mid-run scare recoverable. | **Positive — keep** | No action beyond preserving the framing. |
| D2 | **Two supply-chain README notes** — (a) skills install as symlinks, so `git pull` silently updates installed skill content; (b) agy self-updates in the background, interacting oddly with pin-to-audited-commit discipline. | **Plausible — doc-only** | Both are README/onboarding additions, not code fixes. |

## Remediation checklist

**Phase 0 — Triage & scope (this pass, ✅ done):** report distilled, light-validated (tables above),
and the low-fruit slice split out to **[#175](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/175)**
for today's marathon. The design-heavy items stay parked here. `ratings_provisional: true` until the
remaining phases are split/rated.

### Phase 1 — Low-fruit fixes (no reporter dependency)  → split to #175, Marathon E-BUILD
Contained, additive, unambiguous — the obvious items that need **no back-and-forth with the reporter**.
Execute as parallel lanes in
[MARATHON-PLAN-2026-07-07-E-BUILD.md](../2-WORKING/MARATHON-PLAN-2026-07-07-E-BUILD.md); tracked by
**[#175](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/175)**.
- [x] **B4** headless bring-up doc notes — macOS Documents-folder prompt + `agy -p` vs "interactive TTY" misdiagnosis *(docs only)*
- [x] **D2** README supply-chain notes — symlinked skills + `git pull`; `agy` background self-update vs pin-to-audited-commit *(docs only)*
- [x] **A3** Codex preflight attestation — parse the exec preamble (model/provider/sandbox) into the panel record *(additive; closes the unattested-panel gap)*

### Phase 2 — Deeper exploration / reproduction  (spike, needs the reporter's runs or live repro)
**B1, A1 → split to [#178](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/178)** 2026-07-08, along with B2/A2/A4 (see that issue's own Phase 2/3). Tracked there now, not here.
> Discovery phase: its findings must be written **back into this doc** (fill/repromote the Validation
> table + notes) before this phase's gate can pass (`PROJECT/PDDA.md` → Discovery & spike phases).
- [x] **B3** 2026-07-08: read confirmed the actual template is `new-relay.sh`'s scaffolded Reviewer
  block (not `consult.sh`'s PREAMBLE, not `relay-turn-lib.sh`'s generic role_note) — see Validation table.
- [x] Update the Validation table with Confirmed/Rejected + concrete file:line evidence — done for B3 above.

### Phase 3 — Behavior & architecture fixes  (post-exploration; each likely its own GH issue)
**B1, B2, A1, A2, A4 → split to [#178](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/178)**
([GH-178-EPISTEMIC-RECONCILIATION-HARDENING.md](GH-178-EPISTEMIC-RECONCILIATION-HARDENING.md)) 2026-07-08 —
the five root-caused/evidenced items now have their own tracking issue and doc. Remaining here:
- [x] **B3** 2026-07-08: `new-relay.sh`'s Reviewer template now requires a quoted span or `file:line`
  citation for any `[Pass]`/"verified"/"confirmed" finding; `relay-turn-lib.sh`'s `rtl_check_uncited_findings()`
  (called from `rtl_enforce()` on Reviewer turns) mechanically downgrades an uncited one to
  `[Unverified — no citation]` rather than trusting model compliance with the new prompt sentence alone.
- [ ] **D1** Preserve the reversibility/branch-first onboarding framing that made the mid-run scare recoverable (regression-protect, don't dilute)

### Phase 4 — Verify
- [x] **B3** carries `test/relay-uncited-findings.sh` (16 assertions: uncited `[Pass]` downgraded, unrelated
  findings untouched, inline-quote and file:line-cited findings left alone, uncited prose "verified"
  flagged, idempotent on a second pass, `RTL_WAS_REVIEWER_TURN` set correctly for both roles, plus 6
  assertions from the 2026-07-08 code-review follow-up on PR #184 covering the widened trigger
  vocabulary and a regression guard for the `awk -v \[Pass\]` corruption bug — see the B3 row below)
- [ ] Remaining items (D1) still need their own regression-protection pass
- [ ] `utils/pdda/pdda.sh run` (or the narrower relevant check) is clean
- [x] `./validate.sh` green for touched surfaces — full 109-test run done 2026-07-08 as part of the code-review follow-up (item 4: the original PR shipped on a targeted subset only). Rebuilt `skills/relay-automation/relay-pkg.tar.gz` (it had drifted from `new-relay.sh`/`relay-turn-lib.sh` since the original PR never rebuilt it). Remaining 2 reds (`acorn-extract.sh`, `python:test_python_layer.py`) are pre-existing environment gaps (missing `acorn`/`pytest`), confirmed present on the PR's original head commit too — unrelated to this work.
- [x] Link fix commit(s) back to #173 — B3 landed 2026-07-08 as `17c1dc4` via [PR #184](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/184), alongside #178's A1/A4; the code-review follow-up (widened trigger vocabulary + `awk -v` fix) landed as a follow-up commit on the same PR the same day

## What worked well (keep — regression-protect)
- Worktree isolation + lane containment held throughout; byte-diff showed zero out-of-scope changes.
- Codex's trusted-directory refusal (won't run outside a git repo) — the `git init` fix beats the bypass flag.
- **Refuse-rather-than-fabricate** on the missing-CLI consult was the single most trust-building moment — but A2 exists precisely so this doesn't depend on model judgment.
- One-cycle relay convergence on a real artifact with a genuinely checkable review claim = the product working as designed.

## Related session note (2026-07-07 evening)
A same-day, separately-scoped pass on `WORKTREE-SAFETY.md` (git-worktree footgun doc, prompted by an
unrelated repo-recovery incident — GH-177) touched adjacent surfaces. Not a fix for any item below;
recorded here only because it produced evidence relevant to open questions, in two passes:

**First pass** (while placing an unrelated doc pointer):
- **A1** — `aider-turn.sh` (driving `openrouter/z-ai/glm-5.2`) was proven live end-to-end as a
  genuine third turn-taker, via a real relay review turn (not `consult.sh --models aider`, which
  remains untested). See the A1 Validation row above.
- **B1** — reading `consult.sh`'s own worktree-build code (separate from `relay-turn-lib.sh`'s)
  surfaced that its file-seeding looks complete, narrowing Phase-2's hypothesis space toward
  agy-side behavior. See the B1 Validation row above. Not a repro, not a fix.

**Second pass — deliberate dogfood mining (2026-07-07 night):** the two consults and one relay run
during the first pass are themselves fresh field evidence, same category as Jedi's report. Mined the
transcripts (`relay-system/2026-07-07/worktree-safety-review-194255/`,
`.../worktree-safety-review-codex-194809/`, `.../worktree-safety-glm-review.md`) and the scripts they
exercised for anything Phase 2 should chase. Findings written into the Validation table above:
- **B2** — found the exact warning-emission site and a live false-positive instance; the root cause
  is sharper (and slightly different) than Jedi's original framing. See the B2 row.
- **A2** — a live, unstamped single-advisor degrade (codex timeout, `1 answered, 1 failed`) that only
  the operator's manual read caught. See the A2 row.
- **A4** — a live example of a hedged-but-wrong advisor claim (GLM's `git worktree repair` version),
  showing model-supplied hedging alone isn't sufficient. See the A4 row.
- **B1** — a non-repro: agy was fine in today's consult, same code path Jedi hit. Suggests
  intermittency, which should shape the Phase-2 repro strategy (repeat runs, not one). See the B1 row.
- **B3** — partial counter-evidence: both advisors cited `file:line` unprompted today, suggesting
  citation quality may be turn-shape-dependent rather than a hard gap everywhere. See the B3 row.

## Non-goals
- Implementing any fix here (capture only; execution begins on promotion).
- Re-auditing Swarm / Marathon / HQ / PDDA / `tick` export — explicitly out of the trial's scope.
- Owning/vendoring the external `ra-to-xyz-transfer.md` catalog in this repo.
