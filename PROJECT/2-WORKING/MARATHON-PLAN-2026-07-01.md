---
title: Marathon Plan 2026-07-01 — daily queue review
status: Active (2-WORKING)
created: 2026-07-01
updated: 2026-07-01
owner: noel
branch: main
doc_type: project
source: ../../ROADMAP.md (open ledger entries)
roadmap_exempt: true
goal: >
  Daily queue review for 2026-07-01: parked GH-64/GH-66 + flagged GH-63 collision,
  ranked surviving open work, and produced a wave plan. Builds on MARATHON-PLAN-2026-06-30.md
  which showed 0 active waves (all items held).
---

<!-- Hand-built queue review — see also the machine-scored version: utils/marathon-plan.sh -->

# Marathon Plan 2026-07-01 — daily queue review

> Hand-built from [ROADMAP.md](../../ROADMAP.md) · 2026-07-01  
> The roadmap says **what/why**; this says **what is still real and in what order**.  
> Execution detail lives in each `PROJECT/**` doc — this is a scheduling overlay.

## What changed since 2026-06-30

- **GH-67** (tick-release missing in relay-turn-lib.sh) and **GH-68** (cross-agent dep conflict) captured and parked in ROADMAP on 2026-07-01.
- **3 self-healing inbox docs** committed from untracked state (all from a 2026-06-30 external harness review):
  - **GH-64** — security-scanning guardrail (parked ✅)
  - **GH-66** — session/transcript-log audit (parked ✅)
  - **GH-63-SIGNAL-TRIAGE-STAGE** — ⚠️ issue-number collision with existing GH-63-UPGRADE-CODE-STRUCTURE; blocked until the GitHub issue number is confirmed and the file is renamed.
- **Rebalance-OS cross-repo dogfood** remains unblocked (GH-51 [1-kernel] closed 2026-06-30).
- Previous plan (2026-06-30) showed **0 active lanes** — all items held; today opens 4.

## Status

| What was just completed | What's next |
|---|---|
| Parked GH-64 + GH-66; flagged GH-63-signal-triage collision; reviewed all open items. | **Wave 1 (kernel, serialize):** GH-67 tick-release fix. **Wave 2 (parallel):** GH-64 + GH-66 + GH-63-upgrade Phase 1. **Operator-driven:** rebalance-OS cross-repo dogfood + G2 dup-token. |

## The one safety rule

Two lanes are safe to run concurrently **iff their write-sets are disjoint**. The kernel
(`relay-automation/relay-turn-lib.sh`, `bin/tick`, `relay-automation/relay-drive.sh`) is the
serialization bottleneck: **at most one kernel lane per wave**, even in separate worktrees.

## Collision map

| Zone | Parallel-safe? | Active items today |
|---|---|---|
| kernel | ❌ serialize — one at a time | GH-67 (tick-release), G2 dup-token |
| shim | ✅ one lane per file | — |
| independent | ✅ one lane per file | GH-64, GH-66, GH-63-upgrade Ph1 |
| cross-repo | ✅ separate target root | Rebalance-OS dogfood |

## Wave 1 — Kernel (serialize; run before Wave 2)

| Lane | Item | Why now | Model | Allow paths |
|---|---|---|---|---|
| GH-67 | tick-release missing in `relay-turn-lib.sh` | Bug: both worker shims leave tick tokens `open` after every turn; manual `tick log task.done` force-close is the only recovery today. Root fix: one `post-commit` branch in the shared kernel (`relay-turn-lib.sh`) that inspects relay `STATUS:` → `tick done` or `tick release --to <RELAY_PEER>`. Clean containment-only change. | Opus (kernel correctness) | `relay-automation/relay-turn-lib.sh` |

**Gating:** complete and merge Wave 1 before starting Wave 2 shim-adjacent lanes.  
**GH-68** (also kernel) is HIGH PRIORITY but needs a `decisions/` record before touching `.tick/events/` schema + both shims — hold until the contract is written.

## Wave 2 — Independent (parallel-safe after Wave 1)

| Lane | Item | Why now | Model | Allow paths |
|---|---|---|---|---|
| A | GH-64 security-scanning guardrail | Additive; wraps existing hooks; no kernel or relay mutation. Pairs naturally with GH-61 CI. Ratings: cx=2 risk=2 eff=2. | Sonnet High | `relay-automation/hooks/`, `bin/validate-relay-block`, `validate.sh` |
| B | GH-66 session/transcript-log audit | Read-only, additive; periodic audit script over `relay-system/**` + `AUDIT/`; no relay mutation. Ratings: cx=2 risk=2 eff=2. | Sonnet High | `utils/`, `AUDIT/` |
| C | GH-63-upgrade Phase 1 (root-dir cleanup) | Root cleanup only — remove stale stubs, tighten the directory layout. Independent of all kernel/shim work. Phase 2 (JSDoc/checkJs) can follow in a Wave 2b. Ratings: cx=2 risk=2 eff=2. | Sonnet High | top-level `*.md`, scripts listed in GH-63-UPGRADE-CODE-STRUCTURE.md |

## Outside the wave plan (operator-driven, any order)

| Item | Why it's outside waves | Next action |
|---|---|---|
| **Rebalance-OS cross-repo dogfood** | Separate target root; doesn't collide with the wave lanes above. Highest-momentum test now that GH-51 is closed. | `swarm-preflight --target-root <clone> → marathon-drive`; do not run simultaneously with Wave 1. |
| **G2 dup-token determinism** (Part B Phase 2) | Kernel-territory; `test/chaos-dup-token.sh`. Schedule as a second Wave 1 after GH-67 settles. | Opus + `decisions/` record; `ADVERSARIAL-HARDENING.md` is the execution surface. |

## Held / flagged — excluded from active waves

| Item | Reason |
|---|---|
| **GH-68 cross-agent dep conflict** | 🔴 HIGH PRIORITY — costly: touches `.tick/events/` verb schema + both shims + `relay-turn-lib.sh`. Needs `decisions/` record first; only then promote to Wave 1. |
| **GH-63-SIGNAL-TRIAGE-STAGE** | ⚠️ Issue-number collision: `gh_issue: 63` conflicts with GH-63-UPGRADE-CODE-STRUCTURE. Confirm GitHub issue # (likely #65); rename file; then re-park and sequence. |
| GH-41 task.done not terminal | Unrated — add PDDA ratings to unblock. Kernel territory once rated. |
| GH-44 scratch-repo git fall-through | Unrated — add ratings to unblock. |
| GH-48 cross-repo zone model | Behind the rebalance-OS dogfood — keep it there. |
| GH-45 commitment contract | Needs `decisions/` record before execution. |
| GH-23 Cursor CLI lane | Needs doc (`GH-23-*.md` not created yet). |
| GH-30 centralized transcript archive | Needs contract (expensive; phase model not decided). |
| Agy reliability testing | Needs S1–S10 matrix doc / contract. |
| Front-door onboarding health | Needs promotion decision (still in `1-INBOX`). |
| PDDA feedback synthesis | Needs promotion decision (agy-approved proposal in `1-INBOX`). |
| Part B adversarial hardening (hub) | Promote one slice at a time — G2 dup-token is the next candidate. |
| Relay-to-issue skill | Needs one live un-sandboxed `gh issue create` to confirm E2E. |

## How to fire a lane

```bash
# Wave 1
utils/swarm-preflight.sh --gh-issue 67
relay-automation/marathon-drive.sh ...

# Wave 2 lanes (parallel-safe after Wave 1 merges)
utils/swarm-preflight.sh --project-doc PROJECT/1-INBOX/GH-64-SECURITY-SCANNING-GUARDRAIL.md
utils/swarm-preflight.sh --project-doc PROJECT/1-INBOX/GH-66-SESSION-LOG-AUDIT.md
utils/swarm-preflight.sh --project-doc PROJECT/1-INBOX/GH-63-UPGRADE-CODE-STRUCTURE.md

# Rebalance-OS cross-repo (operator-driven)
utils/swarm-preflight.sh --target-root <path-to-rebalance-OS-clone> ...
```

- **Wave 1 first** — merge GH-67 before starting any lane that could touch shim exit paths.
- **Never** run two kernel lanes simultaneously, even in separate worktrees.
- For GH-68: write the `decisions/` record first, then promote to a future Wave 1.

---

*Source of truth: [ROADMAP.md](../../ROADMAP.md). Hand-crafted review; for a machine-scored version re-run `utils/marathon-plan.sh` after the ledger stabilizes.*
