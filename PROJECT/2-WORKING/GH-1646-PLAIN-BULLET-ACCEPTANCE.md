---
gh_issue: 1646
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1646
title: "swarm_preflight: plain-bullet issue Acceptance parses as empty, so a verbatim capture reads NOT-READY (exit 5)"
status: Active
created: 2026-11-27
updated: 2026-11-27
owner: noelsaw1
doc_type: bug
complexity: 1
risk: 1
effort: 1
phases: 1
non_goals:
  - Changing the capture-doc side (doc acceptance still requires checkbox bullets)
  - Changing collect_inline_checklist / packet inlining
  - Reading other headings (GH-1580 alt headings stay advisory)
goal: >
  An issue whose Acceptance section uses plain "- " / "* " bullets yields those bullets as its
  criteria, so a verbatim checkbox copy in the capture doc reads `match` instead of `diverged`.
---

# GH-1646 · Plain-bullet issue Acceptance

## Status

| What was just completed | What's next |
|---|---|
| Recon on development `52813e56f`; plan written. | Plan QA (Codex relay), then implement + gh400 case. |

Batch: item 2 of #1657.

## Observed (development `52813e56f`)

- `utils/py/swarm_preflight.py:576` `ACC_BULLET_RE` matches only `- [ ]` / `- [x]` bullets.
- `extract_acceptance_criteria` (`:589`) is called for both sides in `check_acceptance_fidelity`
  (`:985` issue body, `:986` capture doc). A plain-bullet issue section returns `[]` (present but
  empty), so every doc criterion counts as an undeclared addition → `diverged`, exit 5.
- Real case: #792 (`PROJECT/3-COMPLETED/GH-792-GEN4-SANDBOX-DISJOINT-FIRST.md`) needed three
  `[added]` deviations for a verbatim copy.
- No other production caller of `extract_acceptance_criteria`. `collect_inline_checklist`
  (`:793`) uses `ACC_BULLET_RE` for the doc only and is untouched.

## Plan (smallest change in the existing parser)

1. Add `ACC_PLAIN_BULLET_RE = ^([ \t]*)[-*][ \t]+(\S.*)$` next to `ACC_BULLET_RE` (non-blank
   payload required, so `- ` alone is never a criterion).
2. `extract_acceptance_criteria(text, plain_bullets=False)`: inside the existing loop, after the
   checkbox match fails and only when `plain_bullets` is true, try the plain regex. A plain bullet
   is a new criterion unless it is indented deeper than the current criterion; then it is a
   continuation (folded into the parent, exactly as the doc side folds the same nested line).
   Checkbox lines still match `ACC_BULLET_RE` first, including `-  [ ]` with extra spacing (an empty
   one is dropped by the existing blank filter), so the plain branch never sees a task marker.
3. `check_acceptance_fidelity` passes `plain_bullets=True` for the issue body only.

Mixed sections (plan QA r1): `- [ ] First` / `  - detail` / `- Second` yields `First - detail` and
`Second`, so a full checkbox copy matches and a copy that omits `Second` diverges with
`dropped=['Second']`.

Preserved by construction: checkbox-only issues without plain siblings (same output); deviations
heading skip; HR and heading termination (checked before bullets); `None` (no section) vs `[]`
(section with no bullets); doc side unchanged (`plain_bullets` defaults to False), so a doc cannot
dodge the gate with plain bullets and the packet/fidelity views of the doc stay in agreement.

Archived #792 capture (plan QA r1): `PROJECT/3-COMPLETED/GH-792-...md` declares three `[added]`
deviations as the old workaround. After this fix a re-run of preflight on it would read `diverged`
(stale deviations). Not edited here: #792 is closed (COMPLETED), the doc is an archived record of
the packet that was actually delivered, and preflight does not re-run completed captures. Recorded
as a known effect in the PR.

Why issue-side only: the doc's criteria are what the packet inlines (`collect_inline_checklist`,
checkbox-only). Accepting plain bullets on the doc side would let fidelity read `match` while the
packet inlines nothing.

Why the indent rule: without it a checkbox issue with plain nested sub-bullets would split each
sub-bullet into its own criterion and diverge from a verbatim copy, which folds them.

## Preflight bet check

- Outcome: real issues written in common GitHub style admit without hand-written deviations.
- Smallest bet: one regex + one flag in the existing extractor. Not built: doc-side changes, new
  headings, normalization of both sides.
- Alternative rejected: keep declaring `[added]` deviations — they falsely claim the doc differs.
- Rollback: revert the commit; behaviour returns to checkbox-only.

## Acceptance

- [ ] `test/gh400-acceptance-fidelity.sh` gains one case: an issue with plain `- ` bullets under
      `## Acceptance` and a doc copying them verbatim as `- [ ]` reads `match`. Red on the unfixed
      parser (`diverged`), green after.
- [ ] The same case's negative control: a doc that drops one of those plain-bullet criteria reads
      `diverged` with that criterion in `dropped` (not merely as an addition).
- [ ] Mixed control: an issue with `- [ ] First`, nested `  - detail`, plain sibling `- Second`
      matches a full checkbox copy and diverges with `dropped=['Second']` when `Second` is omitted.
- [ ] Whitespace control: `-  [ ]` (empty, padded task) plus `- First` yields only `First`.
- [ ] All existing cases in `test/gh400-acceptance-fidelity.sh` and
      `test/gh557-unknown-blocks-manifest.sh` still pass.
- [ ] Smoke: `swarm-preflight.sh` dry run against the #792 issue body shape (main path) and a
      checkbox issue with nested plain sub-bullets (adjacent path); receipt under
      `TESTS-RESULTS/2026-11-27+GH-1646/`.

## Rating (2026-11-27)

rated 65/55/50/85. Severity: a correct packet is refused (exit 5) unless the operator writes false
deviations; workaround exists, no data loss. Priority: on the #1657 batch before Run A/Run B.
Appeal neutral. Effort: one-function change with an existing suite. Recurrence: one observed
incident (#792, 2026-11-27); trend unknown.
