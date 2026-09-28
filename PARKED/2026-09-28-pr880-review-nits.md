# PR #880 review nits parked (2026-09-28)

Source: the Grok review on PR #880 (landing of #854), adjudicated in the PR thread. Outside the landing's scope:
none is a regression the window introduced, and each needs its own measurement first.

- **N3 — merge recovery re-queries once.** After a non-zero `gh pr merge`, `merge_cleanup.py` re-queries the PR once;
  the zero-exit path polls up to 6 times. Lag stops the run safely and costs a `--resume`. Next check: whether a
  merge-cleanup log ever shows that stop.
- **N4 — hosted lookup window.** `wait_for_hosted_reconcile` lists `--limit 20` runs unfiltered by branch (deliberate
  since GH-674; SHA matching decides). On a busy repo the target run could age out of 20. Next check: the largest
  number of `wave-reconcile` runs created inside one hosted wait in the last 30 days.
- **N5 — GH-139 ratchet counts only the literal `| grep -q`.** `-Fq`, `-iq`, `--quiet` and `|grep` without a space
  pass unguarded (the #853 sweep converted three `| grep -Fq` helpers that were never in the baseline). Proposed
  pattern in the review; widening needs a baseline regen whose repo-wide effect is unmeasured. Next check: run the
  widened pattern over `test/` and count the new sites. Relevant to #853's Sweep.
