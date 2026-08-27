---
name: express
description: >
  Hotfix fast lane (GH-267): push a critical, risk-bounded fix end-to-end in one
  motion — fix + regression suite, releases-DB dial-in, PDDA capture doc born
  complete, CHANGELOG entry, landing on development with no human review loop,
  then full doc reconciliation. Mechanizes SOP.md §4's express-to-development
  carve-out ("direct commit + push into development happens only when the user
  explicitly asks") as the ONLY sanctioned agent path to a gateless landing:
  every predicate a PR would have satisfied is asserted up front instead, and
  the operator's /express invocation IS the merge authorization. Trigger on
  "/express", "express this hotfix", "express GH-<n>", or any explicit operator
  request matching SOP §4 ("express commit this critical fix now"). Requires:
  a fresh task clone branched off origin/development with githooks installed
  (SOP §4 — express NEVER runs from a shared/primary clone), gh (authenticated),
  the releases ledger at repo root, and the fix's regression suite already
  registered in validate.sh. Landing shape (documented deviation, see #267):
  the commit rides the task branch and merges via a PR that the driver itself
  opens and merges immediately — this keeps wave_reconcile --pr working and
  auto-closes the linked issue, which a raw push to development would not;
  "direct" means "no human gate", not "no PR object". Refuses (exit 3, .tick
  event `express-refused`): dirty/shared clones, frozen-twin or new-Bash edits,
  coordination-kernel surfaces (.tick/, src/project.js, containment), diffs over
  the size bounds (default 4 files / 150 insertions), multi-subsystem changes,
  missing/unregistered/un-green suites, and closed or unresolvable issues.
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
   paths, and the **pre-push hook provably installed** (`gate-unwired`
   refusal — hooks do not travel with a clone, GH-549). Express never commits
   over peer work (GH-527). Hand-edits to `releases.db`/`releases.sql` are
   refused (`ledger-hand-edit` — verbs only).
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
   against the active release (`releases next`) with an express reason.
7. **Gate** — the fix's suite runs green, the tree is RE-SNAPSHOTTED afterwards
   (`tree-drift` refusal: anything the suite generated never rides the commit —
   staging is by explicit pathspec, never `-A`), and the push rides the normal
   `githooks/pre-push` boundary (express never sets `XYZ_SKIP_PREPUSH`).
8. **Land** — one commit of exactly the qualified paths; push; ghost PR into
   `development`; immediate merge. The closeout then switches to clean,
   current `development` (ship/reconcile state never rides the task branch).
9. **Ship with evidence** — `manifest ship --gid <rel> --evidence "<sha>; <suite>
   green; PR #<m> merged"` — post-merge, so the sha and receipts exist when the
   evidence is written. The GH-205 trap (dialed_in while closed) is structurally
   impossible in this order.
10. **Close the issue** — the ghost PR body says `Closes #<N>`, so GitHub
    auto-closes it; the driver verifies and closes explicitly if it did not.
11. **Reconcile, then persist — fail closed.** From `development`:
    `wave_reconcile.py --pr <m>` (offline-manifest fallback for foreign-tracker
    citations), then the closeout COMMITS AND PUSHES everything it wrote (DB,
    dump, doc promotion, ROADMAP, views) — unpushed ledger state is unshipped
    state. Any closeout fault exits non-zero with an `express-reconcile-failed`
    tick event; a success line is printed only after persistence.

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
