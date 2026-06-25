---
title: Cross-repo driven-relay friction — token collision, path resolution, .tick, sandbox
status: Active — verification + docs + code fixes (#2/#1b/#5) shipped, agy-approved; #3/#4 doc-only resolved
created: 2026-06-24
updated: 2026-06-24
owner: noelsaw1
branch: main
gh_issue: 18
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/18
parent: GH-16 (same-device cross-repo swarm readiness)
goal: >
  Remove the cross-repo driven-relay friction a maintainer hit driving a Codex review whose
  thread/artifact lived in a different repo (rebalance-OS) than the harness clone, via --target-root.
  Review quality + safety boundary held; the friction is entirely in the cross-repo plumbing and its
  docs. Verify each finding reproduces, fix the doc-only ones now, PAUSE before any code change.
scope: >
  Cross-repo driven relay (relay-drive.sh + codex-turn.sh + --target-root) on the same device.
  Folds into the GH-16 cross-repo frontier as a concrete child.
related:
  - relay-automation/relay-drive.sh
  - relay-automation/codex-turn.sh
  - relay-automation/relay-turn-lib.sh
  - relay-automation/README.md
non_goals:
  - Cloud / cross-machine relay (out of GH-16 scope)
  - Re-defaulting the token id in the scripts before review (deferred to the code phase)
---

## Status

| What was just completed | What's next |
|---|---|
| **All phases done.** Phase 0 verification (#1/#2/#5 real bugs; #3/#4 doc-only). Phase 1 docs (headless bring-up now folded into `relay-automation/README.md`). **Phase 2 code shipped + agy-approved**: #2 relay-file resolution, #1b token-collision hints, #5 Escalated-not-stall oracle — 3 new tests, **`validate.sh` 41→44/44**; agy review **Approved** (3×[Pass], confirmed #5 doesn't mask a true stall). | Close [#18](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/18); fold any residual into GH-16. Move this doc to `3-COMPLETED` once #18 is closed. |

## Problem

Field feedback ([#18](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/18))
from driving a cross-repo Codex review: thread + artifact in `rebalance-OS`, harness clone in
`xyz-3-agents-swarm`, driven via `--target-root`. The review itself worked well and Codex produced
strong findings, but the cross-repo path took ~5 false starts. The friction is almost entirely in
that cross-repo flow — which is also the *common* real case (the reviewer should read **your** repo,
not the harness).

## Phase 0 — Verification gate (DONE 2026-06-24)

Each finding was reproduced locally (throwaway tick root, no codex/agy needed) before any fix.

| # | Sev | Finding | Verdict | Evidence |
|---|-----|---------|---------|----------|
| 1 | High | `RELAY-TURN` singleton token carries terminal state across relays | ✅ **CONFIRMED (code)** | A `done` RELAY-TURN → new relay's `claim` fails `lost: RELAY-TURN is done — not claimable`; a fresh per-relay id (`RELAY-<slug>`) claims cleanly. Default at [relay-drive.sh:46](../../relay-automation/relay-drive.sh#L46); the consolidated README bring-up example now seeds the safe pattern instead. |
| 2 | High | `--relay-file` resolved vs CWD, not `--target-root` | ✅ **CONFIRMED (code)** | From harness with `--target-root <foreign>` + repo-relative `--relay-file`, driver dies `relay file does not exist` though the file exists under the target. Check at [relay-drive.sh:60](../../relay-automation/relay-drive.sh#L60); `TARGET_ROOT` known by [line 53](../../relay-automation/relay-drive.sh#L53). |
| 3 | Med | Cross-repo `.tick` footgun (foreign untracked noise) | ⚠️ **LARGELY STALE → doc-only** | Driven runs anchor `.tick` to the harness — [codex-turn.sh:57](../../relay-automation/codex-turn.sh#L57) `export TICK_REPO_ROOT="$ROOT"`; [relay-turn-lib.sh:53-57](../../relay-automation/relay-turn-lib.sh#L53-L57) "only the ARTIFACT side moves." Residual was the manual seed step in the headless bring-up docs. Fix = doc. |
| 4 | Med | Codex can't self-write under default sandbox cross-repo | ⚠️ **Documented limitation → doc-only** | [codex-turn.sh:64](../../relay-automation/codex-turn.sh#L64) defaults `-s workspace-write`; remediation already documented at [lines 17-20](../../relay-automation/codex-turn.sh#L17-L20). Fix = surface the recipe in the consolidated README bring-up. |
| 5 | Med | By-design `Escalated` round-cap handback reports as a stall | ✅ **CONFIRMED (code)** | A `STATUS: Escalated` relay with the token left `open:codex` (correct at `ROUND 1/1`) trips the no-progress `exit 3`. `terminal_status` matches only `Approved\|Closed` ([relay-drive.sh:78](../../relay-automation/relay-drive.sh#L78)); no-progress guard at [line 139](../../relay-automation/relay-drive.sh#L139). |

## Phase 1 — Documentation updates (DONE 2026-06-24, docs only)

Closes the doc-only findings (#3, #4) and the doc halves of #1 and both Low/Nit items.

- [x] **README bring-up example → per-relay id** (closes #1-doc + Low nit). Stop teaching the
      collision trap; seed `RELAY-<slug>` derived from the relay file.
- [x] **Add a "review a file in another repo" recipe** (closes #3-doc, #4-doc, both Lows). One worked
      cross-repo example: `--target-root` + `TICK_REPO_ROOT=<harness>` (NOT `$PWD`) + absolute
      `--agent-cmd` + `CODEX_FLAGS` bypass — the single least-documented, most-common path.

## Phase 2 — Code fixes (DONE 2026-06-24, commit `7709abc`, agy-approved)

Order shipped: #2 → #1b → #5. Each landed with a failing-first test seeded from the Phase 0 repros.

- [x] **#2 — resolve `--relay-file` relative to `--target-root`.** `relay-drive.sh` validates
      `--target-root` first, then resolves a repo-relative `--relay-file` under it when not found in CWD
      (absolute/CWD-relative unchanged; missing files still error). `ALLOW_PATHS` was **already**
      target-relative (the shim resolves it against `RELAY_TARGET_ROOT` in `relay-turn-lib.sh`), so no
      change needed there. Test: `test/relay-target-root-relayfile.sh` (4).
- [x] **#1b — token-collision hints (default unchanged).** `bin/tick`'s `claim` not-claimable branch
      hints a fresh per-relay id; `relay-drive.sh`'s no-actor branch names the real `--relay-task` and,
      on a spent `done` token, hints the fix. Default token left as `RELAY-TURN` (the seed is external;
      changing it would break the seed/drive contract and many tests — README/skill already use a
      per-relay id). Test: `test/relay-token-collision.sh` (5).
- [x] **#5 — escalation success oracle.** `STATUS: Escalated` is now terminal-by-design at both the
      loop top and the post-turn guard → exit 4 with a clean handback message, NOT the stall's exit 3.
      Discriminator = the explicit `Escalated` status (a true stall leaves STATUS unchanged); the
      no-progress guard is intact, so a genuine stall still exits 3. Test:
      `test/relay-escalation-not-stall.sh` (5, incl. a true-stall regression + a pre-escalated case).

**Verification:** `validate.sh` **41 → 44/44** (behavioral). **Review:** agy headless relay
([relay-system/2026-06-24/gh18-agy-review.md](../../relay-system/2026-06-24/gh18-agy-review.md)) —
**Approved**, 3×[Pass], basis textual-only; explicitly confirmed #5 does not mask a true stall.

## Blast radius (summary)

✅ **Small ×4 + one Medium-risk behavioral tweak (#5).** No `tick` event-schema, projection-kernel, or
public-contract change. All changes are a few lines of shell or markdown, trivially reversible. The one
to treat carefully is #5 — it changes the driver's success oracle, where a sloppy widening masks real
stalls. Full lens: see the conversation that produced this doc.

## What worked well (from the field report — keep)

- Safety boundary held: path-allowlist, file-scoped commit, no push, worktree isolation of `target@HEAD`.
- The locator (`find-harness.sh --env/--check`) resolved cleanly from a foreign repo.
- `--relay-task` exists and was the escape hatch for the token collision.
- Codex's review quality behind the shim was excellent (4 actionable graded findings).
