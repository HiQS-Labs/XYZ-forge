---
title: Marathon Plan 2026-07-01 — daily queue review
status: Complete (3-COMPLETED) — superseded snapshot; status word corrected 2026-07-18 (GH-224 drift sweep)
created: 2026-07-01
updated: 2026-07-18
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
  - **GH-63-SIGNAL-TRIAGE-STAGE** — ✅ collision RESOLVED 2026-07-01: the upgrade doc got its own issue **#71** and was renamed to `GH-71-UPGRADE-CODE-STRUCTURE.md`; #63 stays the signal-triage issue.
- **Rebalance-OS cross-repo dogfood** remains unblocked (GH-51 [1-kernel] closed 2026-06-30).
- Previous plan (2026-06-30) showed **0 active lanes** — all items held; today opens 4.

## Status

| What was just completed | What's next |
|---|---|
| **2026-07-01 — big day, all pushed to `origin/main`.** Marathon: **GH-67** tick-handoff (`102cc74`), **GH-68** dep-drift (`94558c5`), **GH-66** transcript audit (`ff2ea44`), **GH-64** security scanner (`a0cc84e`). Then a `/relay-xyz` concurrency review spun off **GH-72/73/74**: **GH-73** closed (`d427a90`), **GH-72** registry lock closed after a 5-defect codex relay (`56433d6`), **GH-70** Phase 1–2 shipped (`e8d9999`). **GH-71** issue opened (code-structure upgrade). `validate.sh` **76/76**. | See **Resume on another device** below — the ranked remaining queue + exact setup to continue elsewhere. |

## Resume on another device (cross-device handoff)

Everything below is pushed to `origin/main` (`git pull` to get it). To continue this queue on a
different machine:

**One-time setup on the new device**
1. Clone (or pull) `xyz-3-agents-swarm`, then make the relay skill discoverable + disable the sandbox:
   - `bash skills/relay-xyz/install.sh` — symlinks `relay-xyz` into `~/.claude/skills/` (Claude Code doesn't scan top-level `skills/`).
   - Run Claude Code with the Bash sandbox **off** — every workflow here (codex/agy, `gh`, `git push`) needs it. See memory `git-push-needs-sandbox-disabled`.
2. Workers: `codex` (ChatGPT-sub auth) and `agy` (Antigravity) must be installed + authed for headless relay/marathon lanes. `claude` is **not** a headless builder yet (#58).
3. Orient: read `ROUTER.md` → `AGENTS.md` → `ROADMAP.md`; run `utils/pdda/pdda.sh run` (docs) and `RELAY_SELF_SUFFICIENCY_SKIP=1 ./validate.sh` (code) to confirm green.

**Ranked remaining queue (pick up here)**
| Rank | Item | Size | Notes / next action |
|---|---|---|---|
| 1 | **GH-74** — `test/xyz-vendor.sh` not hermetic under a git worktree | S | Root-caused 2026-07-01: locator resolves to the real clone via the `~/.claude/skills` symlink. Pin the locator anchor to the fixture for the `no-.xyz` assertion. → [#74](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/74) |
| 2 | **GH-71** — code-structure upgrade Phase 1+2 | M | Phase 1 root-dir cleanup + Phase 2 JSDoc/`checkJs` (wires GH-61). Both low-risk, no supervisor rewrite. Phases 3–4 (Node ports) deferred behind a concrete trigger. → [#71](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/71) |
| 3 | **GH-69** — marathon branch suggestion + confirm prompt | S–M | `marathon-plan.sh` emits `suggested_branch`; `swarm-preflight` emits `branch_ready`; orchestrator asks before `marathon-drive`. → [#69](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/69) |
| 4 | **GH-64 active-gate wiring** | M | Scanner + test shipped; making it a *blocking* repo-wide gate needs a suppression/baseline (legit `eval "$1"` in `poll.sh`); pair with GH-61 CI. |
| 5 | **#72 nit** — `XYZ_GITPULSE_DIR=""` = auto-discover, not disabled | S | Doc/UX: add a distinct disable sentinel, or treat empty as disabled + unset-only for autodiscovery. Noted on #72; not yet its own issue. |
| 6 | **GH-70 Phase 3** — `install.sh --with-harness` | M | Deferred: wrap `xyz-vendor.sh`. Only if a real user finds `xyz-vendor.sh` too indirect. |
| — | **#58** — headless `claude` builder | L | The external-independence keystone, but blocked: no `claude` CLI on this device (IDE-only). Needs the standalone CLI + a nested-`claude -p` dogfood. |

**Operator-driven (any device, unchanged):** rebalance-OS cross-repo dogfood (`swarm-preflight --target-root <clone> → marathon-drive`), and G2 dup-token determinism (Part B Phase 2).

**How to fire a lane through the harness** (proven this session): invoke the `relay-xyz` skill, then
either a `/relay` review (`relay-drive.sh --review-once`, `ALLOW_PATHS=""`) or a build lane
(direct `codex-turn.sh`/`agy-turn.sh` for true concurrency — the `/xyz` model — since two supervised
`relay-drive`s serialize on the per-clone lock). Always `dangerouslyDisableSandbox`.

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

## Wave 1a — Kernel (serialize first; must complete before Wave 1b or Wave 2)

| Lane | Item | Why now | Model | Allow paths |
|---|---|---|---|---|
| GH-67 | tick-release missing in `relay-turn-lib.sh` | Bug: both worker shims leave tick tokens `open` after every turn; manual `tick log task.done` force-close is the only recovery today. Root fix: one `post-commit` branch in the shared kernel (`relay-turn-lib.sh`) that inspects relay `STATUS:` → `tick done` or `tick release --to <RELAY_PEER>`. Clean containment-only change. | Opus (kernel correctness) | `relay-automation/relay-turn-lib.sh` |

**Gating:** complete and merge Wave 1a before starting Wave 1b or Wave 2. GH-67 and GH-68 are both kernel — they must serialize.

### Wave 1b — Kernel (after Wave 1a merges; operator-confirmed 2026-07-01)

| Lane | Item | Why now | Model | Allow paths |
|---|---|---|---|---|
| GH-68 | Cross-agent dependency conflict detection | 🔴 HIGH PRIORITY — operator confirmed for today's marathon. Write the `decisions/` record as the first step of this lane (before any code). Warn-only Phase 1: post-commit hook diffs shared surfaces + emits `dependency.drift` event to `.tick/events/`; both shims read unacknowledged drift events and inject a summary into the next turn brief. | Opus (kernel + schema) | `relay-automation/relay-turn-lib.sh`, `relay-automation/codex-turn.sh`, `relay-automation/agy-turn.sh`, `src/project.js`, `.tick/events/` |

**GH-68 pre-condition:** write `decisions/2026-07-01-cross-agent-dep-conflict.md` (schema contract + warn-only invariant) before touching any code.

## Wave 2 — Independent (parallel-safe after Wave 1)

| Lane | Item | Why now | Model | Allow paths |
|---|---|---|---|---|
| A | GH-64 security-scanning guardrail | Additive; wraps existing hooks; no kernel or relay mutation. Pairs naturally with GH-61 CI. Ratings: cx=2 risk=2 eff=2. | Sonnet High | `relay-automation/hooks/`, `bin/validate-relay-block`, `validate.sh` |
| B | GH-66 session/transcript-log audit | Read-only, additive; periodic audit script over `relay-system/**` + `AUDIT/`; no relay mutation. Ratings: cx=2 risk=2 eff=2. | Sonnet High | `utils/`, `AUDIT/` |
| C | Code Structure upgrade Phase 1 (root-dir cleanup) | Root cleanup only — remove stale stubs, tighten directory layout. Independent of all kernel/shim work. ✅ Unblocked 2026-07-01 (now **issue #71**, doc renamed) — not executed this run; ready for a future wave. Ratings: cx=2 risk=2 eff=2. | Sonnet High | top-level `*.md`, scripts listed in GH-71-UPGRADE-CODE-STRUCTURE.md |

## Outside the wave plan (operator-driven, any order)

| Item | Why it's outside waves | Next action |
|---|---|---|
| **Rebalance-OS cross-repo dogfood** | Separate target root; doesn't collide with the wave lanes above. Highest-momentum test now that GH-51 is closed. | `swarm-preflight --target-root <clone> → marathon-drive`; do not run simultaneously with Wave 1. |
| **G2 dup-token determinism** (Part B Phase 2) | Kernel-territory; `test/chaos-dup-token.sh`. Schedule as a second Wave 1 after GH-67 settles. | Opus + `decisions/` record; `ADVERSARIAL-HARDENING.md` is the execution surface. |

## Held / flagged — excluded from active waves

| Item | Reason |
|---|---|
| **GH-69 marathon branch prompt** | 🆕 Captured today — needs contract before execution. Low-cost; independent lane candidate for a future wave. |
| **Code Structure upgrade** (GH-71-UPGRADE-CODE-STRUCTURE.md) | ✅ Issue-number resolved 2026-07-01 (now #71, doc renamed, ROADMAP relabelled). Not executed this run — ready to sequence as a Wave 2 lane in a future marathon. |
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
utils/swarm-preflight.sh --project-doc PROJECT/1-INBOX/GH-71-UPGRADE-CODE-STRUCTURE.md

# Rebalance-OS cross-repo (operator-driven)
utils/swarm-preflight.sh --target-root <path-to-rebalance-OS-clone> ...
```

- **Wave 1 first** — merge GH-67 before starting any lane that could touch shim exit paths.
- **Never** run two kernel lanes simultaneously, even in separate worktrees.
- For GH-68: write the `decisions/` record first, then promote to a future Wave 1.

---

*Source of truth: [ROADMAP.md](../../ROADMAP.md). Hand-crafted review; for a machine-scored version re-run `utils/marathon-plan.sh` after the ledger stabilizes.*
