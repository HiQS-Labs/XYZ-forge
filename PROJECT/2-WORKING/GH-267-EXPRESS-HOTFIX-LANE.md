---
title: "GH-267: /express — hotfix fast lane through the whole paper trail"
status: Active
created: 2026-08-27
updated: 2026-08-27
owner: orchestrator (ZCode)
gh_issue: 267
source: https://github.com/HiQS-Labs/XYZ-forge/issues/267
doc_type: feature
complexity: 3
risk: 3
effort: 3
ratings_provisional: true
related:
  - "GH-259 (parent skills-design thread; jog plan PR #261 is the consistency template)"
  - "GH-232 (promotion gate: docs refuse promotion while the linked issue is OPEN)"
  - "GH-205 (manifest item left dialed_in while its issue was closed)"
  - "GH-527 (peer work destroyed by tree-wide git spells)"
  - "GH-561 (four Meter commits straight onto development — the ad-hoc express lane)"
goal: >
  Mechanize SOP §4's express-to-development carve-out as the only sanctioned
  no-human-gate landing path: fix + regression suite, releases-DB writes,
  born-complete PDDA docs, CHANGELOG entry, landing, and reconciliation in one
  operator-authorized motion, with every PR-satisfiable predicate asserted as
  an up-front refusal instead.
---

# GH-267 — /express: Hotfix Fast Lane Through the Whole Paper Trail

## Status

| What was just completed | What's next |
|---|---|
| Driver (`utils/py/express.py`), skill (`skills/express/`), regression suite (`test/gh267-express-skill.sh`, 15/15), registrations (validate.sh TESTS, Skills Index, roadmap row, CHANGELOG) | PR into `development`; QA relay review pending; Phase 2: true direct-push mode pending `wave_reconcile --commit` |

## Why

A critical, risk-bounded fix should not wait behind ceremony, and the paperwork
should not wait behind the fix. Before `/express`, the SOP §4 carve-out existed
only as policy — and its ad-hoc use produced GH-561 (four commits straight onto
`development`, no PR, no evidence). `/express` is the carve-out with teeth: the
only sanctioned agent path to a gateless landing, because every predicate a PR
would have satisfied is asserted up front as a refusal, and the operator's
`/express` invocation IS the merge authorization.

## Design (consistent with the jog plan, GH-259 PR #261)

- **Re-use, not new surface**: releases CLI verbs (`roadmap add`,
  `manifest dial-in`/`ship --evidence`), `wave_reconcile.py`, the
  `githooks/pre-push` boundary, `.tick` events. No new DB table (express is
  stateless; jog needed `jog_queue` because a queue is state — express does not).
- **Where jog pauses, express pre-flights**: jog's landing boundary pauses for
  orchestrator outer review (base branch, diff size, gate receipts) by default.
  Express inlines those same three predicates as `check`-time refusals, because
  a pause would defeat the reason the lane exists. This is the one foundational
  divergence, and it is deliberate.
- **Landing shape (documented deviation from the letter of "direct commit")**:
  the commit rides the task branch and merges via a PR the driver itself opens
  and merges immediately. This keeps `wave_reconcile --pr` working and
  auto-closes the linked issue — a raw push to `development` would strand both.
  "Direct" means no human gate, not no PR object. Phase 2 tracks a true
  direct-push mode pending `wave_reconcile --commit`.
- **Issue closure is load-bearing** (GH-232): no PR means no auto-close —
  except the ghost PR provides one via its `Closes #N` body; the driver verifies
  and closes explicitly if GitHub did not.

## Mechanics (steps 0–11)

See `skills/express/SKILL.md` for the operator-facing procedure and
`utils/py/express.py` for the enforced order: tree-of-execution → qualify
(≤4 core files / ≤150 insertions / single subsystem) → hard refusals (frozen
twins, new Bash, kernel surfaces) → issue OPEN → suite registered → docs born
complete + CHANGELOG → ledger (park + dial-in) → suite green → commit/push
through the pre-push gate → ghost PR + merge → ship with evidence → close
issue → reconcile (with auto-built offline manifest fallback for
foreign-tracker PR-body citations).

## Acceptance Criteria

- [x] `test/gh267-express-skill.sh` green (15/15): refusal predicates, happy
      path, born-complete scaffolding, CHANGELOG insertion, tick telemetry.
- [x] Suite registered in `validate.sh` TESTS; skill indexed in ARCHITECTURE.md.
- [x] Roadmap row parked via `releases roadmap add` (rated 3/3/3, provisional).
- [ ] QA relay review (pattern: `relay-system/<date>/gh267-express-qa.md`).
- [ ] First live `/express` run on a real hotfix.

## Non-goals

- No `--force` override — a refused run routes to the normal fresh-clone PR lane.
- No Costly/one-way-door work, ever.
- No scoring/ranking (that is marathon's and jog's concern; express is single-shot).

## Merge evidence

- (recorded at landing)

## Lessons Learned (For Future Agents)

- **A fast lane is a refusal surface, not a speed feature.** Everything the PR
  loop would have checked must become an up-front refusal, or the lane is just
  a direct push with extra steps — GH-561 is what the unmechanized version of
  this carve-out looks like.
- **Order the writes so the traps are structurally impossible**: docs born
  complete (GH-232's gate can't dead-end), dial-in and ship in the same motion
  as the commit (GH-205 can't recur), issue closed before reconcile (promotion
  can't stall), evidence written only after the sha exists.
- **Consistency with a sibling plan beats local elegance**: following the jog
  plan's conventions (re-use inventory, capture-doc + `roadmap add`
  registration, registered test suite, non-goals section) made the review
  surface smaller and the skill legible to agents that already know jog.
- **Tests for guardrails need contamination-proof fixtures**: an untracked
  `.tick/` file surviving between cases made six consecutive cases fail with
  the wrong rule; every case now resets with `reset --hard` + `clean -fdq`
  inside the sandbox, and the telemetry assertion runs before any reset can
  wipe the events it asserts on.
