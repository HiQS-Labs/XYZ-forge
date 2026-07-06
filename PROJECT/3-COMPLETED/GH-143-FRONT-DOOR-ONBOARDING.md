---
gh_issue: 143
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/143
complexity: 1
risk: 1
effort: 1
ratings_provisional: false
title: Front-door remediation + relay-xyz adherence — unified plan (refreshed 2026-06-23)
slug: front-door-remediation
status: Complete — CLOSED 2026-07-06. FD-01…FD-13 all ✅; validate.sh 104/104 green (the audit-time relay-pkg-freshness failure was resolved by rebuilding relay-pkg.tar.gz in the same marathon).
created: 2026-06-22
updated: 2026-07-06
owner: Noel (operator) · Claude (producer)
related:
  - FRONTDOOR.md                                       # the live deterministic dashboard this plan drives to green
  - relay-automation/poll.sh                           # Phase 0 — its line-7 comment points at the moved PHASE-4-PLAN.md (breaks path-integrity.sh)
  - PROJECT/4-MISC/PHASE-4-PLAN.md                      # the real home of the file poll.sh still references at the old path
  - PROJECT/2-WORKING/GH-11-CROSS-REPO-TARGETING.md    # Asks 2–5 overlap Phase 3
  - PROJECT/1-INBOX/FEEDBACK/FEEDBACK-OPUS-MAX.md       # parallel Opus-Max session: PDDA hardening (@2610e45) + relay-xyz adherence (folded into Phase 4)
  - skills/relay-xyz/SKILL.md                          # Phase 4 hoists find-harness --check to the first body line
  - ROUTER.md
non_goals:
  - Not restructuring docs/ navigation — the structure is sound; this is drift, not architecture.
  - Not (re)building any relay-xyz infra — `find-harness.sh`, `--target-root`, `CONSULT_ROOT`, `install.sh` already EXIST (confirmed by both sessions); only docs + adherence remain.
  - No kernel/logic changes — the ONLY non-doc edit is Phase 0's one-line comment fix in `poll.sh` to restore the green suite; everything else is a doc edit.
goal: >
  Drive FRONTDOOR.md to all-green AND close the relay-xyz agent-adherence gap a parallel Opus-Max
  session surfaced. The 2026-06-23 re-audit found the green baseline is currently BROKEN (validate.sh
  37/38: `relay-automation/poll.sh` references `PHASE-4-PLAN.md` at its pre-reorg path), so Phase 0
  restores it first. Then fix the onboarding drift (stale test counts — now 38, not 36; two dead README
  links; the CLAUDE.md phantom-path block), surface the shipped cross-repo features, and make the
  relay-xyz harness un-missable (hoist `find-harness.sh --check` to the top of SKILL.md). A cold clone
  (human or agent) clones → `ROUTER.md` → `./validate.sh` green at 38/38, reaches working, AND uses the
  harness as designed.
---

## Status

| What was just completed | What's next |
|---|---|
| **All phases complete + CLOSED (2026-07-06).** Re-verified every FD-01…FD-13 observable against the ACTUAL current suite (now **104 / 104**, not the stale 36/38 this doc previously tracked). Most items had already landed via other work (GH-83's README rewrite fixed FD-02/03/04/06/09; `67068da` fixed FD-11/FD-12; Phase 0 fixed FD-13); this pass fixed the two genuinely still-open items — **FD-08** (`skills/relay-xyz/install.sh` discoverability, added to `README.md`'s Repo map) and **FD-10** (agent "run un-sandboxed" callout, added to `README.md`). `FRONTDOOR.md` refreshed: Last audited → 2026-07-06, baseline → 104/104, FD-13 row added, all rows ✅. | **Nothing outstanding.** A `relay-pkg-freshness.sh` failure surfaced at audit time (the packaged tarball had drifted from the S9-fixed `agy-turn.sh`) — **resolved in the same marathon** by rebuilding `relay-pkg.tar.gz`; suite is 104/104 green. |

> **Header note:** this table uses the canonical `What was just completed | What's next`. The parallel
> Opus-Max session's PDDA hardening (`2610e45`) **deleted the "Most recently completed phase" alias**, so
> that earlier wording would now `error` on promotion to `2-WORKING`. Keep this header on promotion.

> **Re-audit note (2026-07-05, at marathon-preflight setup time):** most of this plan's scope has
> since landed via *other* issues, not this doc's own checklist — **GH-83** (README onboarding
> rewrite, shipped 2026-07-02) de-brittled the stale test-count entirely (README no longer states a
> hardcoded pass count), the two FD-05 dead links now resolve, the FD-06 `skill/` typo is gone, and
> root `CLAUDE.md` (FD-01/Phase 2) is already a clean pointer to `ROUTER.md`/`AGENTS.md` — no phantom
> paths remain. **Phases 0–3 are effectively done, just not through this ticket.** The one item
> re-confirmed still open: **Phase 4 / FD-11** — `skills/relay-xyz/SKILL.md` still doesn't hoist
> `find-harness.sh --check` to the top of the body (first mention is line 53, well past the ~25-line
> target); FD-12 (per-repo persistence guidance) is likewise unconfirmed. Rated down accordingly
> (1/1/1) — this is now a single small doc-hoist edit, not a 4-phase remediation.

## Table of Contents

- [Audit summary (both sessions)](#audit-summary-both-sessions)
- [Phase 0 — Restore the green baseline (blocker)](#phase-0--restore-the-green-baseline-blocker)
- [Phase 1 — Quick-win drift fixes](#phase-1--quick-win-drift-fixes)
- [Phase 2 — Repair the agent front door (CLAUDE.md)](#phase-2--repair-the-agent-front-door-claudemd)
- [Phase 3 — Surface the recent features](#phase-3--surface-the-recent-features)
- [Phase 4 — relay-xyz adherence (parallel Opus-Max session)](#phase-4--relay-xyz-adherence-parallel-opus-max-session)
- [Cross-cutting — refresh FRONTDOOR.md itself](#cross-cutting--refresh-frontdoormd-itself)

## Audit summary (both sessions)

A cold clone of HEAD **mostly** reaches working (clone → `ROUTER.md` → `./validate.sh`), but the
2026-06-23 re-audit found the kernel gate is **no longer green**: `validate.sh` is **37/38** because
`test/path-integrity.sh` catches a stale path reference — `relay-automation/poll.sh:7` names
`relay-automation/PHASE-4-PLAN.md`, which the "Update/organize Docs" reorg (`d44e07c`) moved to
`PROJECT/4-MISC/PHASE-4-PLAN.md`. That is **Phase 0**: the green baseline FRONTDOOR.md advertises
("First success works → `validate.sh` green") must actually be green before any doc-drift fix can claim
"validate still passes." The residual friction beyond that is cheap doc drift — no architecture, no
secrets (scan clean). A **parallel Opus-Max session** on the same repo independently confirmed the
relay-xyz half: the infra is **complete** — `find-harness.sh` (device-agnostic locator:
`--root`/`--env`/`--check`, symlink-safe), `--target-root` (in `relay-drive.sh`), `CONSULT_ROOT` (in
`consult.sh`), and `install.sh` all exist, and SKILL.md *does* reference the locator. So **nothing is
missing; the friction is agent-adherence** — agents skim SKILL.md and skip the "run `find-harness.sh`
first" step. That session also shipped PDDA acting-layer hardening (`2610e45`: the only destructive
stale-move → flag-only; LLM findings clamped `warn`-max; status-header alias removed). Phase 0 restores
the suite; Phases 1–3 fix the front-door drift; **Phase 4 folds in that session's relay-xyz adherence
fixes.** Live status + re-runnable checks: [FRONTDOOR.md](../../../FRONTDOOR.md). Phases ordered
blocker-first, then quick-wins.

## Phase 0 — Restore the green baseline (blocker) ✅ DONE 2026-06-23

*The gate for every "validate still green" claim below. The fix is a one-line comment, but it has a
second-order requirement: `poll.sh` is a **packaged** script, so `test/skill-extract.sh` fails until the
shipped tarball is regenerated to match. Two files, no logic touched.*

- [x] **FD-13** — `relay-automation/poll.sh:7` comment pointed at the moved file. Repointed
  `relay-automation/PHASE-4-PLAN.md` → `PROJECT/4-MISC/PHASE-4-PLAN.md`. *Observable:* `grep -c 'relay-automation/PHASE-4-PLAN.md' relay-automation/poll.sh` returns `0` ✅.
- [x] **Repackaged the skill tarball** — re-ran `skills/relay-automation/make-pkg.sh` so `relay-pkg.tar.gz` carries the fixed `poll.sh` (else `skill-extract.sh` fails "packaged poll.sh differs from source"). *Observable:* `bash test/skill-extract.sh` → `4 pass, 0 fail` ✅.
- [x] **Suite back to green.** *Observable:* `bash test/path-integrity.sh` exits `0` (`2 pass, 0 fail`); `bash validate.sh` prints `passed: 38 / 38` ✅ (run un-sandboxed — `mktemp` under the Bash sandbox aborts several tests for reasons unrelated to the code).

### QA checklist — Phase 0

- [x] `bash validate.sh` is green at **38 / 38** un-sandboxed (the number FRONTDOOR's "First success" promise now depends on).
- [x] `bash test/path-integrity.sh` reports no broken path references and exits `0`.
- [x] The edit touches only the `poll.sh` comment **and** the regenerated `relay-pkg.tar.gz` (a build artifact, not logic) — `git diff` shows no change under `src/`, `bin/`, or `test/`.
- [x] FRONTDOOR.md's "First success works" row + the test-count number are refreshed (36 → **104/104**, the true current count as of 2026-07-06), and a new FD-13 row is added + flipped ⬜ → ✅.

## Phase 1 — Quick-win drift fixes

*Minutes; highest friction-removed-per-effort. Doc edits only. Re-verified 2026-07-06 against the true current count (**104/104**, not 38 — the suite has grown since this plan was last touched).*

- [x] **FD-02** — `README.md` test count. *Verified 2026-07-06:* already fixed via GH-83's README rewrite — no hardcoded `28/28` (or any stale count) remains. `grep -c '28 ?/ ?28' README.md` → `0`. No edit needed.
- [x] **FD-03** — `AGENTS.md` test count `12/12`. *Verified 2026-07-06:* already fixed — `grep -c '12/12' AGENTS.md` → `0`. No edit needed.
- [x] **FD-04** — `ROADMAP.md` status-table `33/33`. *Verified 2026-07-06:* already fixed — `grep -c '33/33' ROADMAP.md` → `0`. Not edited by this pass (`ROADMAP.md` is orchestrator-owned).
- [x] **FD-05** — README dead links. *Verified 2026-07-06:* both links already resolve — a full relative-link sweep of `README.md` (24 links) found zero dead links. No edit needed.
- [x] **FD-06** — `README.md` `skill/relay-automation/` typo. *Verified 2026-07-06:* already fixed — `grep -c 'skill/relay-automation' README.md` → `0`. No edit needed.

### QA checklist — Phase 1

- [x] No stale count remains on the front door: `grep -rE '12/12|28 ?/ ?28|33/33' README.md AGENTS.md ROADMAP.md` prints nothing (verified 2026-07-06).
- [x] **Both** README dead links resolve now — full relative-link sweep prints zero dead links.
- [x] `FRONTDOOR.md` rows FD-02…FD-06 flipped ⬜ → ✅.
- [x] Doc-only: this phase required no edits (all already fixed by prior work); `./validate.sh` unaffected.

## Phase 2 — Repair the agent front door (CLAUDE.md)

*The single worst step for the ~75% who clone with an agent. One decision gates it.*

- [x] **Decide (operator) — resolved:** root `CLAUDE.md` is a clean pointer for THIS repo (`Read ROUTER.md first for canonical entry points and command rails`, then `AGENTS.md`, then the linked `PROJECT/**` doc). No phantom-repo content.
- [x] **FD-01** — *Verified 2026-07-06:* `CLAUDE.md` no longer cats any phantom path or phantom branch; it points at `ROUTER.md` and `AGENTS.md`, both of which exist. No edit needed (already fixed via other work before this pass).

### QA checklist — Phase 2

- [x] Every required-reading path in `CLAUDE.md` exists (`ROUTER.md`, `AGENTS.md` both `test -e` pass).
- [x] No instruction references a branch the repo doesn't have.
- [x] A dry read-through of `CLAUDE.md` lands a fresh agent on `ROUTER.md` with zero failed reads.
- [x] `FRONTDOOR.md` FD-01 flipped ⬜ → ✅; the "Agent front door" dimension flips 🚧 → ✅.

## Phase 3 — Surface the recent features

*Doc-only; overlaps GH-11 Asks 2–5 (same edits satisfy both).*

- [x] **FD-07** — *Verified 2026-07-06:* already documented. `skills/relay-xyz/SKILL.md` (lines ~258–278) and `relay-automation/README.md` (§"Review a file in another repo") both distinguish turn-based relay (`relay-drive.sh --target-root`) from one-shot read (`CONSULT_ROOT` + `consult.sh`), with the "wrong tool for a read" rationale spelled out. No edit needed.
- [x] **FD-08** — **Fixed 2026-07-06.** Added a note to `README.md`'s Repo map bullet for `skills/`: `bash skills/relay-xyz/install.sh` (once per clone/machine) + a link to SKILL.md's setup section. *Observable:* `grep -n 'relay-xyz' README.md | grep install.sh` now hits.
- [x] **FD-09** — *Verified 2026-07-06:* already fixed — `grep -c 'One skill ships here' AGENTS.md` → `0`. No edit needed.
- [x] **FD-10** — **Fixed 2026-07-06.** Added an "Agent users: run un-sandboxed" callout to `README.md`'s "Before you start" section. *Observable:* `grep -ci sandbox README.md` → `3`.

### QA checklist — Phase 3

- [x] `--target-root` *and* `CONSULT_ROOT` are discoverable from prose docs, and the recipe says which is for reads vs relays.
- [x] `install.sh` is reachable from the front door — the `skills/relay-xyz` chicken-and-egg is gone.
- [x] `AGENTS.md`'s skill claim matches reality (no stale "One skill ships here" line).
- [x] `FRONTDOOR.md` FD-07…FD-10 flipped ⬜ → ✅.
- [x] These are doc-only fixes tracked directly on this ticket (no separate GH-11 dependency found).

## Phase 4 — relay-xyz adherence (parallel Opus-Max session)

*That session's core finding: the relay-xyz infra is **complete** — the friction is **agent-adherence**
(agents skim SKILL.md and skip `find-harness.sh`). The breadcrumb instinct is right, but it has to live
in a channel Claude Code auto-loads and be a portable pointer, never a cached path. Doc-only; highest
leverage first.*

- [x] **FD-11** — *Verified 2026-07-06:* `bash skills/relay-xyz/find-harness.sh --check` appears at line 21 of `SKILL.md`, right after the H1, as a hard gate ("ALWAYS run this first"). Confirmed DONE via `67068da`.
- [x] **FD-12** — *Verified 2026-07-06:* `SKILL.md` §"Per-repo persistence (don't cache a path)" (line 129) documents memory / `CLAUDE.md`-by-name as the only auto-loaded, portable persistence channels; no bare pointer file pattern is recommended. Confirmed DONE via `67068da`.

### QA checklist — Phase 4

- [x] A skimming agent meets `find-harness.sh --check` as the **first** actionable SKILL.md step (line 21, within the first ~10 body lines).
- [x] SKILL.md's cross-repo guidance distinguishes **one-shot read → `CONSULT_ROOT` + `consult.sh`** from **turn-based relay → `relay-drive.sh --target-root`**.
- [x] No bare pointer-file is auto-installed into any target repo; the persistence pattern is memory / `CLAUDE.md`-by-name only.
- [x] `FRONTDOOR.md` FD-11/FD-12 flipped ⬜ → ✅; the "relay-xyz adherence" dimension is ✅.

## Cross-cutting — refresh FRONTDOOR.md itself

*The dashboard predated this re-audit and still said "36/36" and "Last audited 2026-06-22." Refreshed 2026-07-06 so the board matches reality.*

- [x] Bumped **Last audited** to 2026-07-06 and the "First success" baseline to the true current count, **104/104** (not 38 — the suite grew since this plan was last touched; the audit-time `relay-pkg-freshness.sh` failure was resolved by rebuilding the tarball in the same marathon).
- [x] Added an **FD-13** row (poll.sh stale path → suite red) plus a `test/path-integrity.sh` assertion to the Deterministic-checks block.
- [x] Re-ran the full Deterministic-checks block after edits; all rows flipped ⬜ → ✅.
- [x] All of FD-01…FD-13 are ✅; flipped the top-line **Verdict** to ✅ — `validate.sh` is 104/104 green (the packaging-staleness failure surfaced at audit was fixed via `make-pkg.sh`).

### QA checklist — Cross-cutting

- [x] No stale test-count claim remains in `FRONTDOOR.md` — the board reads `104/104`.
- [x] The Deterministic-checks block includes a path-integrity / FD-13 assertion, so a future regression of the moved-file class is caught automatically.
- [x] No row in FRONTDOOR.md asserts a status its own command wouldn't reproduce (the board stays *verified-by-rerun*, not asserted) — the "First success works" row is ✅, reflecting the real 104/104 state.

## Swarm Preflight Contract

```json
{"target":{"repo":".","ref":"main"},"gate":"true","fix_probes":[{"type":"grep_absent","path":"skills/relay-xyz/SKILL.md","pattern":"ALWAYS run this first"}],"artifacts":["skills/relay-xyz/SKILL.md"],"lanes":{"orchestrator_only":[]}}
```
