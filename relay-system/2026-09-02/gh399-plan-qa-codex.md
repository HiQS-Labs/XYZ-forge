# QA relay — the GH-399 plan doc
STATUS: Open
NEXT: codex (Reviewer)

## Your role

You are the **reviewer**. This is a **review-only** turn: `ALLOW_PATHS` is empty, so the only file
you may write is this relay file. Do not edit the plan or any source. Report findings here.

## What to review

`PROJECT/1-INBOX/GH-399-PROFILE-CARRIES-THE-ROUTE.md` — a two-phase plan, not yet built.

Context you should read rather than take on trust:

- Issue #399 and PR #400 (`git log --oneline -3`, `git show b7a4a1bb`).
- `utils/py/profile_resolve.py` — what the resolver emits today, and how it recovers each shim's
  gateway variable.
- `utils/py/deepseek-turn.py` — `PROVIDER_ROUTES` and `load_provider_key`, added by #400.
- `PROJECT/PDDA.md` — the contract a plan doc in this repo must satisfy.
- `AGENTS.md` §6 — the repo's proof rules.

## Definition of Done

This is a **plan review**, so the question is not "is the code right" but "will building this plan
produce the right thing, and can a cold agent build it from this doc alone?" Answer each with
evidence from the repo, not from the plan's own claims.

1. **Are the plan's factual claims true?** It cites file:line for seven default-model literals, a
   regex-scraped gateway variable, and three places a route is described. Check each. A plan built on
   a wrong premise is worse than no plan.
2. **Would the QA gates actually catch a broken build?** For each gate, name what a lazy or wrong
   implementation could do that still passes it. The Phase 1 "emits neither variable when absent"
   gate and the Phase 2 "fixture provider in no .py file" gate are the two the author believes are
   load-bearing — say whether they are, and whether any other gate is unfalsifiable as written.
3. **Is the design right, or is it the wrong simplification?** The plan rejects a `harnesses.db`
   routes table, a plugin interface, and deleting the built-in tables. Argue against the chosen
   design if you can — specifically, whether pushing endpoints and key-variable names into operator
   config trades a code-review boundary for a config file nobody reviews.
4. **What does the plan not say that a builder will have to guess?** Precedence between an exported
   variable and a profile field, what happens when `base_url` is set but `key_env` is not, whether
   the six other shims are expected to follow, and anything else underspecified.
5. **Does it satisfy `PROJECT/PDDA.md`?** Frontmatter keys, status table, TOC, per-phase QA gates,
   repo-relative paths only. Name any contract item missing.
6. **Is it too big or too small?** It claims effort 2 / complexity 2 / risk 2 / phases 2. Say if the
   ratings are wrong and why.

Rate each finding `[Blocker]`, `[Must]`, `[Should]`, or `[Note]`. A finding with no evidence from the
repo is a `[Note]`, however strongly you believe it.

Set `STATUS: Approved` only if the plan is buildable as written. Otherwise `STATUS: Changes requested`.

## Round log
