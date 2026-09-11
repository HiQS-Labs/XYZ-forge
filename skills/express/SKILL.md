---
name: express
description: >
  Hotfix fast lane (GH-267/GH-516) for an explicit `/express`, "express this hotfix",
  or "express GH-N" request. Carries a critical, risk-bounded fix, registered
  regression suite, releases-ledger updates, born-complete PDDA doc, CHANGELOG,
  landing, and reconciliation in one operator-authorized motion. Requires a
  task clone branched from origin/development (carrying <= 2 local commits) with the
  canonical pre-push gate installed, authenticated gh, and the root releases ledger. The
  driver commits and fast-forward pushes directly to development, verifies the
  commit and issue closure, then reconciles with `wave_reconcile --commit`.
  Supports --dry-run across commands, contextual subsystem tolerance (--allow-multi-subsystem
  or <= 30 insertions across <= 2 files), an explicit `resume` subcommand to recover
  interrupted runs, and central telemetry mirroring (~/.config/xyz/events/).
  Refuses shared/stale clones, diverged branches, > 2 commits, unsafe Git/Bash/kernel surfaces,
  oversized diffs, generated-artifact hand edits, missing/red suites, and closed or unresolved
  issues. Do not use for Costly or one-way-door changes.
---

# /express — hotfix fast lane through the whole paper trail

One verb, one motion: the fix, its regression suite, the ledger writes, the
born-complete capture doc, the CHANGELOG entry, the landing, and the
reconciliation — all before the operator's coffee cools. The guardrails are the
skill; the speed is a side effect.

**Design provenance:** proposed on #259 (comment 5434441831, v2), filed as
#267, upgraded in #516 (True Direct-Push Mode, commit-driven reconciliation,
branch flexibility, recovery subcommand, dry-run, and central telemetry):
re-use the releases verbs, `wave_reconcile`, the pre-push gate, and `.tick`
events rather than building parallel machinery. Where jog pauses at each
landing boundary by default (orchestrator outer review), express inlines those
same predicates — base branch, diff size, gate receipts — as pre-flight
refusals, because a pause would defeat the reason /express exists. That is the
foundational difference, and it is the only one.

## Procedure

Run the driver; it enforces the order. Do not hand-perform steps the driver owns.

```bash
# 0. From the task clone carrying the fix (SOP §4 clone, <= 2 commits ahead, hooks installed):
python3 utils/py/express.py check --issue <N> --suite test/gh<N>-<slug>.sh   # steps 0–4
python3 utils/py/express.py docs  --issue <N> --suite test/gh<N>-<slug>.sh --summary "<one line>"  # step 5
python3 utils/py/express.py ledger --issue <N>                               # step 6
python3 utils/py/express.py land  --issue <N> --suite test/gh<N>-<slug>.sh   # steps 7–11
# or the whole motion at once:
python3 utils/py/express.py run --issue <N> --suite test/gh<N>-<slug>.sh --summary "<one line>"

# Inspect what would happen without modifying disk, DB, or git state:
python3 utils/py/express.py run --issue <N> --suite test/gh<N>-<slug>.sh --summary "<one line>" --dry-run

# Recover/resume an interrupted express run (e.g. dropped network or post-push closeout fault):
python3 utils/py/express.py resume --issue <N> [--sha <SHA>]
```

What each phase asserts (all refusals and fired runs write `.tick/events/*` and mirror to `~/.config/xyz/events/`):

0. **Tree of execution** — task branch based on origin/development with $\le 2$
   local commits (GH-516; $> 2$ refuses with `too-many-commits`; diverged branches
   refuse with `task-clone`), no scratch paths, and `bash githooks/install.sh --check`
   proves the canonical pre-push stub (`gate-unwired`; hooks do not travel, GH-549).
   Express never commits over peer work (GH-527). Hand-edits to ledger files or
   generated views are refused; only the driver's verbs may write them.
1. **Bounds** — ≤ 4 core files / ≤ 150 insertions, single subsystem (unless
   `--allow-multi-subsystem` is passed, or micro-diff tolerance applies: $\le 30$
   insertions across $\le 2$ files auto-passes, GH-516). Only the lane's OWN
   paperwork (`CHANGELOG.md`, `PROJECT/**`) is exempt — operator .md edits (README,
   governance, skills) COUNT (a gateless merge never rewrites policy unbounded).
   Defaults are operator-tunable via `--max-files` / `--max-insertions`; the
   refusals are never optional.
2. **Hard refusals** — frozen twins and shared Bash runtime (GH-308), any
   new/edited `.sh` under `utils/` or `relay-automation/` (GH-551),
   coordination-kernel and containment surfaces (AGENTS: at least Costly).
3. **Issue first** — the tracking issue exists and is OPEN. Closed => the work
   may already be landed; run the preflight probes instead of re-doing it.
4. **Suite** — the fix's regression suite exists AND is registered in
   `validate.sh` TESTS. A hotfix without its suite is a claim, not a fix.
5. **Docs born complete** — capture doc scaffolded in `2-WORKING` with Status,
   Acceptance, Merge evidence, and `## Lessons Learned (For Future Agents)`
   present from birth (the 08-26 reconcile gate refuses promotion otherwise),
   plus the CHANGELOG entry appended in the same motion.
6. **Ledger** — `roadmap add` if the issue is unparked, then `manifest dial-in`
   against the active release (`releases next`) with an express reason. The
   adopted release/leaderboard projections refresh
   in the same phase and are the only accepted driver outputs.
7. **Gate** — the fix's suite runs green, the tree is RE-SNAPSHOTTED afterwards
   by path and content (`tree-drift`: new paths and changed qualified bytes both
   refuse). Gate identity is re-proven after the suite, staging uses explicit
   pathspecs, and the push never sets `XYZ_SKIP_PREPUSH`.
8. **Land** — one commit of exactly the qualified paths with `Closes #N`, then
   `git push origin HEAD:development`. A concurrent update refuses as a normal
   non-fast-forward; there is no force push and no PR. The closeout switches to clean,
   current `development` (ship/reconcile state never rides the task branch).
9. **Ship with evidence** — `manifest ship --gid <rel> --evidence "<sha>; <suite>
   green; direct development push"` — post-push, so the sha and receipts exist when the
   evidence is written. The GH-205 trap (dialed_in while closed) is structurally
   impossible in this order.
10. **Close the issue** — the commit message says `Closes #<N>` and lands on the
    default branch; the driver verifies and closes explicitly if GitHub has not.
11. **Persist, reconcile cleanly, persist — fail closed.** The landing is
    three pushes total: (1) the hotfix land push (step 8), then from
    `development`, (2) the ship outputs are committed and pushed, and only
    then (3) `wave_reconcile.py --commit <sha>` runs from the clean tree; its
    outputs form the third commit and push. Every post-push fault exits
    non-zero with an `express-reconcile-failed` receipt; success prints only
    after every boundary.

## After the run

- Confirm the tail: `releases check` clean, `pdda.sh issue-doc-sync` 0 errors,
  capture doc promoted (or, under an OPEN umbrella, correctly left in
  `2-WORKING` with merge evidence — that is success, not failure).
- `standup` reports the weekly express count; a rising counter means the normal
  lane is too slow — fix the lane, don't normalize express.

## Non-goals

- No override flag: a refused run routes to the normal fresh-clone PR lane,
  full stop. An `--force` would make every guardrail negotiable.
- No Costly/one-way-door work, ever (see step 2 refusals).
- No force push and no bypass of the canonical pre-push gate.
