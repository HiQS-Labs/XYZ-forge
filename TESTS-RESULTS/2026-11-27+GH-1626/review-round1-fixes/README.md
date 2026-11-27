# GH-1626: dispositions for preparation review round 1 (Codex)

Thread: `relay-system/2026-11-27/gh1626-gh792-prep-qa.md`.

- **F1 (empty queue does not discriminate): fixed.** The probe now drives `land_prs` with one fixture PR. Its refresh is stubbed to a draft, and both calls must return 0 with exactly one refresh before folder state counts. `matrix.txt` (each variant applied to `merge_cleanup.py` in this checkout, then reverted; the `.patch` files show each variant):

  | Variant | Probe exit |
  |---|---|
  | base (unfixed) | 1 |
  | skip-call fix (`if not dry_run:`) | 0 |
  | report-only fix (`prune_retained_scratch(..., dry_run=)`) | 0 |
  | partial guard `if not dry_run or ordered_prs:` (reviewer's fake) | 1 |
  | delete the call (fake) | 2 |
  | comment-only edit | 1 |

- **F4 (builder could rewrite its own proof): fixed.** The artifacts are now the product file plus `delivery.md`, listed in `artifacts_new` with a `path_absent` probe. The probe and proof directories are outside the lane. The inferred `test/gh549-work-events.sh` is documented, and editing it is a non-goal.
- **F5 (history wording / ref): fixed.** The capture records the preparation `parked` event and zero execution attempts. Status now says the packet is held pending approval, publication, merge, and a fresh preflight at the fetched integration ref.
- **Frontmatter note (no pre-existing retained scratch deleted): fixed** in `goal` and `non_goals`.
- F2 and F3 concern #792 only.
