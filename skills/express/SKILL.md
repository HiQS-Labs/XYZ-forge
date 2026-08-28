---
name: express
description: >
  Hotfix fast lane (GH-267) for an explicit `/express`, "express this hotfix",
  or "express GH-N" request. Carries a critical, risk-bounded fix, registered
  regression suite, releases-ledger updates, born-complete PDDA doc, CHANGELOG,
  landing, and reconciliation in one operator-authorized motion. Requires a
  fresh full task clone branched from origin/development with the canonical
  pre-push gate installed, authenticated gh, and the root releases ledger. The
  driver opens and immediately merges a PR to development so issue closure and
  `wave_reconcile --pr` remain available; "direct" means no human pause, not no
  PR. Refuses shared/stale clones, unsafe Git/Bash/kernel surfaces, oversized or
  multi-subsystem diffs, generated-artifact hand edits, missing/red suites, and
  closed or unresolved issues. Do not use for Costly or one-way-door changes.
---

# /express — hotfix fast lane through the whole paper trail

One verb, one motion: the fix, its regression suite, the ledger writes, the
born-complete capture doc, the CHANGELOG entry, the landing, and the
reconciliation — all before the operator's coffee cools. The guardrails are the
skill; the speed is a side effect.

**Design provenance:** proposed on #259 (comment 5434441831, v2), filed as
#267, built consistently with the jog plan (`PROJECT/1-INBOX/GH-259-JOG-SERIAL-QUEUE.md`):
re-use the releases verbs, `wave_reconcile`, the pre-push gate, and `.tick`
events rather than building parallel machinery. Where jog pauses at each
landing boundary by default (orchestrator outer review), express inlines those
same predicates — base branch, diff size, gate receipts — as pre-flight
refusals, because a pause would defeat the reason /express exists. That is the
foundational difference, and it is the only one.

## Procedure

Run the driver; it enforces the order. Do not hand-perform steps the driver owns.

```bash
# 0. From the task clone that already carries the fix (SOP §4 clone, hooks installed):
python3 utils/py/express.py check --issue <N> --suite test/gh<N>-<slug>.sh   # steps 0–4
python3 utils/py/express.py docs  --issue <N> --suite test/gh<N>-<slug>.sh --summary "<one line>"  # step 5
python3 utils/py/express.py ledger --issue <N>                               # step 6
python3 utils/py/express.py land  --issue <N> --suite test/gh<N>-<slug>.sh   # steps 7–11
# or the whole motion at once:
python3 utils/py/express.py run --issue <N> --suite test/gh<N>-<slug>.sh --summary "<one line>"
```

What each phase asserts (all refusals write `.tick/events/*-express-refused-*.jsonl`):

0. **Tree of execution** — task branch, HEAD == origin/development, no scratch
   paths, and `bash githooks/install.sh --check` proves the canonical pre-push
   stub (`gate-unwired`; hooks do not travel, GH-549). Express never commits
   over peer work (GH-527). Hand-edits to ledger files or generated views are
   refused; only the driver's verbs may write them.
1. **Bounds** — ≤ 4 core files / ≤ 150 insertions, single subsystem. Only the
   lane's OWN paperwork (`CHANGELOG.md`, `PROJECT/**`) is exempt — operator
   .md edits (README, governance, skills) COUNT (a gateless merge never
   rewrites policy unbounded). Defaults are operator-tunable via
   `--max-files` / `--max-insertions`; the refusals are never optional.
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
   adopted release/leaderboard projections and `ROADMAP-DASHBOARD.md` refresh
   in the same phase and are the only accepted driver outputs.
7. **Gate** — the fix's suite runs green, the tree is RE-SNAPSHOTTED afterwards
   by path and content (`tree-drift`: new paths and changed qualified bytes both
   refuse). Gate identity is re-proven after the suite, staging uses explicit
   pathspecs, and the push never sets `XYZ_SKIP_PREPUSH`.
8. **Land** — one commit of exactly the qualified paths; push; ghost PR into
   `development`; immediate merge. The closeout then switches to clean,
   current `development` (ship/reconcile state never rides the task branch).
9. **Ship with evidence** — `manifest ship --gid <rel> --evidence "<sha>; <suite>
   green; PR #<m> merged"` — post-merge, so the sha and receipts exist when the
   evidence is written. The GH-205 trap (dialed_in while closed) is structurally
   impossible in this order.
10. **Close the issue** — the ghost PR body says `Closes #<N>`, so GitHub
    auto-closes it; the driver verifies and closes explicitly if it did not.
11. **Persist, reconcile cleanly, persist — fail closed.** From `development`,
    ship outputs are committed and pushed first. Only then does
    `wave_reconcile.py --pr <m>` run from the clean tree (offline-manifest
    fallback for foreign-tracker citations); its outputs form a second commit
    and push. Every post-merge fault exits non-zero with an
    `express-reconcile-failed` receipt; success prints only after both boundaries.

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
- No true push-to-`development` mode — Phase 2, pending `wave_reconcile
  --commit` (tracked on #267).
