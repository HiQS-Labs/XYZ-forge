---
Goal: GH-518 — first real relay turn driven by Muse Spark 1.3 through muse-turn.sh
Date: 2026-09-08
NEXT: Reviewer
STATUS: Open
---

# Context

You are the Reviewer on a single review turn. Adjudicate the model-tier containment logic in
`utils/py/muse-turn.py` — specifically `resolve_model()` and how `main()` calls it.

Background you need:

- `muse-spark-1.3-contributor` is a discounted tier whose published terms state that submitted
  content, including inter-session messages, may be used for product improvement.
  `muse-spark-1.3` carries no such clause and costs ~12x more.
- The operator's rule: the discounted tier is for OPEN-SOURCE repositories only.
- A relay turn ships repository content to whichever tier is dispatched. Sent content cannot be
  recalled.

Read `utils/py/muse-turn.py` in full.

Questions:

1. Can any input or environment combination cause the discounted `-contributor` tier to be
   dispatched while the content being sent belongs to a repository that is not public? Cite
   file:line.
2. `resolve_model()` is variadic and requires every root to be PUBLIC. Is requiring unanimity
   actually sufficient, or is there a root that participates in the turn's content but is never
   passed to it? Name it.
3. Is the failure direction correct throughout? Every uncertain path must land on the CLAUSE-FREE
   model. Point at any branch that could reach `CONTRIBUTOR_MODEL` without a positive PUBLIC
   determination.

Be concrete and cite file:line. Do not edit any file — this is a review turn only. Write your
verdict below, then hand the turn back.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (muse)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
