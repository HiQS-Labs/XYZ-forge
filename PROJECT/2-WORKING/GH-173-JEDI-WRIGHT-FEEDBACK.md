---
gh_issue: 173
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/173
title: "Jedi Wright beta feedback: agy worktree grounding, non-re-checked HEAD warning, uncited reviewer, degraded-panel stamping"
status: parked
created: 2026-07-07
updated: 2026-07-07
owner: noel
doc_type: feedback
complexity: 4
risk: 3
effort: 4
phases: 5
ratings_provisional: true
related:
  - relay-automation/consult.sh
  - relay-automation/agy-turn.sh
  - relay-automation/codex-turn.sh
non_goals:
  - Not implementing the fixes in this doc — this is a triaged 1-INBOX capture; execution starts on promotion to 2-WORKING
  - Not re-auditing Swarm / Marathon / HQ / tick export — the reporter explicitly kept those out of the trial's scope
  - Not vendoring or authoring the external ra-to-xyz-transfer.md epistemic catalog here (external artifact; referenced, not owned by this repo)
---

# GH-173 — Jedi Wright beta feedback (Consult + Relay fast-path trial, 7/6–7/7)

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue: 173` forward
> (`PROJECT/PDDA.md` → GitHub issue intake). Several items likely split into their own `GH-*` issues
> at promotion (bugs vs architecture vs docs); `ratings_provisional: true` until that split is rated.

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
| B1 | **agy file-visibility quirk** — in the 7/7 consult, agy saw zero repo files in a worktree despite running alongside Codex; pre-checked fine in the main repo dir. Highest priority. | **Plausible — partly corroborated** | `agy-turn.sh:146` already warns agy "silently 'finds nothing'"; `agy-turn.sh:61` treats empty `agy -p` output as a FALSE success. Worktree-specificity needs Phase-2 repro. |
| B2 | **HEAD-visibility warning doesn't re-check** — relay warned the reviewer would find nothing, then the run completed anyway; Producer's commit cured it, but the harness never re-evaluated, forcing manual forensics. | **Plausible** | Empty-turn guard exists (`agy-turn.sh:61`), but no post-commit re-evaluation of the warning found; exact warning wording not matched verbatim — confirm the emitting site in Phase 2. |
| B3 | **Reviewer asserts without citing** — agy's review claimed it was "supported by explicit source text" but quoted none; the claim checked out, but only after a manual audit. | **Plausible** | No citation/quote-enforcement in `agy-turn.sh`'s review path on a quick read; needs a look at the reviewer turn template in Phase 2. |
| B4 | **Two environment items** — (a) agy triggered a macOS Documents-folder permission prompt mid-headless-run; (b) agy's `-p` requirement was misdiagnosed by Claude Code as "requires interactive TTY". | **Plausible** | `agy-turn.sh` owns `-p`/empty-output handling; the TTY misdiagnosis is a Claude Code-side/bring-up-doc note, not a harness bug. |
| A1 | **Advisor pluggability** — harness hardwires codex + agy; make the advisor set configurable. | **Partially already present** | `consult.sh:28-29` already exposes `--models codex,agy`. The gap is a *generalized advisor registry* beyond the two per-vendor turn scripts, not zero configurability. |
| A2 | **Single-advisor degraded mode** — mechanically stamp verdicts `SINGLE-MODEL — NOT RECONCILED` when the panel is incomplete, so caveats are structure, not model goodwill. | **Confirmed gap** | No `SINGLE-MODEL` stamp anywhere in the tree; consult is "reconciled once" (`consult.sh:18`) with no mechanical incomplete-panel marker. |
| A3 | **Preflight attestation is nearly free** — parse Codex exec's session preamble (model/provider/sandbox) instead of generating attestation; closes the "unattested panel" gap. | **Plausible / new** | No preamble/attestation parsing found in `consult.sh`/`codex-turn.sh`; low-effort additive parse. |
| A4 | **Verdict-layer provenance** — verdicts should distinguish facts advisors read firsthand from facts the operator asserted, and flag conclusions resting on asserted facts as conditional. References external `ra-to-xyz-transfer.md` (7 transfers) + a named failure-mode catalog. | **Plausible / design** | `ra-to-xyz-transfer.md` not in this repo (external). Largest item; touches the reconciliation contract — Costly, likely its own design issue. |
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
- [ ] **B4** headless bring-up doc notes — macOS Documents-folder prompt + `agy -p` vs "interactive TTY" misdiagnosis *(docs only)*
- [ ] **D2** README supply-chain notes — symlinked skills + `git pull`; `agy` background self-update vs pin-to-audited-commit *(docs only)*
- [ ] **A3** Codex preflight attestation — parse the exec preamble (model/provider/sandbox) into the panel record *(additive; closes the unattested-panel gap)*

### Phase 2 — Deeper exploration / reproduction  (spike, needs the reporter's runs or live repro)
> Discovery phase: its findings must be written **back into this doc** (fill/repromote the Validation
> table + notes) before this phase's gate can pass (`PROJECT/PDDA.md` → Discovery & spike phases).
- [ ] **B1** Reproduce agy's zero-file visibility inside a consult/relay worktree; isolate why it differs from the main-repo pre-check (worktree CWD? `git stash create` copy? agy's own file discovery?)
- [ ] **B2** Find the exact site that emits the "reviewer will find nothing" warning; confirm it is not re-evaluated after each turn's commit
- [ ] **B3** Read the agy reviewer turn template; determine whether "verified" findings can be required to carry a quoted span
- [ ] **A1** Inventory what `--models` already generalizes vs what is still codex/agy-specific (turn scripts, reconciliation)
- [ ] Update the Validation table with Confirmed/Rejected + concrete file:line evidence; capture any newly discovered adjacent issues here

### Phase 3 — Behavior & architecture fixes  (post-exploration; each likely its own GH issue)
- [ ] **B1** agy worktree grounding — ensure agy sees the worktree's files (or fail-closed if it can't) so it can't answer from pure priors while claiming grounding *(highest priority — undermines the panel's grounding claim)*
- [ ] **B2** HEAD-visibility warning — re-check after each turn's commit and update/clear the warning, or hard-stop until the operator acknowledges (a predicted failure shouldn't be outraceable by a background run)
- [ ] **B3** Reviewer citation — reviewer turn template requires a quoted span for any "verified" finding, else mark it unverified (assert-with-citation)
- [ ] **A2** Degraded-mode stamp — harness mechanically stamps `SINGLE-MODEL — NOT RECONCILED` when the panel is incomplete (structure, not model judgment)
- [ ] **A1** Advisor pluggability — extend `--models` into a generalized advisor registry so the consult pattern is decoupled from any specific vendor
- [ ] **A4** Verdict-layer provenance *(likely its own design issue)* — distinguish firsthand vs asserted facts and flag asserted-only conclusions as conditional; consider the named failure-mode catalog (advisor echo, false consensus, reconciler laundering, prompt drift, model-version drift)
- [ ] **D1** Preserve the reversibility/branch-first onboarding framing that made the mid-run scare recoverable (regression-protect, don't dilute)

### Phase 4 — Verify
- [ ] Each fix carries a passing regression test (e.g. an agy worktree-visibility test; a warning-re-check assertion; an uncited-"verified"-finding rejection)
- [ ] `utils/pdda/pdda.sh run` (or the narrower relevant check) is clean
- [ ] `./validate.sh` green for touched surfaces
- [ ] Link fix commit(s) back to #173 (or the per-cluster issues if split)

## What worked well (keep — regression-protect)
- Worktree isolation + lane containment held throughout; byte-diff showed zero out-of-scope changes.
- Codex's trusted-directory refusal (won't run outside a git repo) — the `git init` fix beats the bypass flag.
- **Refuse-rather-than-fabricate** on the missing-CLI consult was the single most trust-building moment — but A2 exists precisely so this doesn't depend on model judgment.
- One-cycle relay convergence on a real artifact with a genuinely checkable review claim = the product working as designed.

## Non-goals
- Implementing any fix here (capture only; execution begins on promotion).
- Re-auditing Swarm / Marathon / HQ / PDDA / `tick` export — explicitly out of the trial's scope.
- Owning/vendoring the external `ra-to-xyz-transfer.md` catalog in this repo.


## Swarm Preflight Contract

```json
{"target":{"repo":".","ref":"main"},"gate":"bash validate.sh","fix_probes":[{"type":"grep_absent","path":"README.md","pattern":"THIS_WILL_NEVER_MATCH"}],"artifacts":["README.md"],"remediation":{"source":"self","criteria":"Fix per plan"},"lanes":{"orchestrator_only":[]}}
```
