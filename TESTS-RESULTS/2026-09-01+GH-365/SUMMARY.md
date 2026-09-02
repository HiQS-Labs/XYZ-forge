# GH-377 — test-suite recalibration: execution evidence (supersedes #365)

> **Post-rebase note (GH-377 review):** the width-campaign receipts in `campaign/` are HISTORICAL,
> pinned to pre-rebase commit `46625dabbf10df3b1b688f69b10e9cc9524fa2b2` (315 registered suites at
> that head; the rebased tree has 318). They describe their pinned commit exactly — mutation reds,
> identity brackets, and the ceiling decomposition remain valid for that tree — and are labeled as
> such in `provenance.jsonl`. The qualifying run below is the post-rebase, blocker-1-fixed run.

Branch `feat/gh365-test-recalibration` → PR into `development`. Issue:
https://github.com/HiQS-Labs/XYZ-forge/issues/365 (final plan comment 5498257579).
Campaign head `46625dabbf10df3b1b688f69b10e9cc9524fa2b2` (implementation-complete; the
receipts-commit itself is docs-only above it). Host: 10-core Apple Silicon, quiet, nice-0 launch
context.

## Step gates and receipts

| Step | Expect gate | Evidence |
| --- | --- | --- |
| 1 shared envelope | clean-start qualifying run ends clean AND writes its record | `qualifying-run.log` below (record written; a refused record now fails the run) + `test/gh365-runner-envelope.sh` 22/0 |
| 2 telemetry | reconstructable from retained data | `test/gh365-validate-telemetry.sh` 14/0; every campaign JSONL here is a reconstructable run |
| 3 contention-skip | cannot report equivalence / silently remain pooled | `test/gh365-driver-lane-registry.sh` 5/0; gh346 in DRIVER_LOCK_LANE; skip_total ≤ 1 in every clean leg (the 1 is ci-workflow's expected informational SKIP) |
| 4 PDDA single-scan | lower time, unchanged findings, duplication decision | governance 1:12→4.9s, full run 1:37.5→31.7s, findings cmp-identical; `test/gh365-pdda-gov-scan.sh` 22/0; pdda run/repo-contract/local-checks characterized — intentional dual role, NOT deduplicated |
| 5 ShellCheck width | identical verdicts, mutation red both shapes | `test/gh365-shellcheck-parallel.sh` 10/0 |
| 6 width campaigns | identical commits, explicit denominators, per-width mutation red, explained speedup | table below |
| 7 long tail | equivalent verdicts, no timeout dilution | timing in commit messages (3c45f0c6/c9bea655/a1213581): premise partially wrong — real cost is subprocess chains + two production-owned polls (gate-poll 1s floor × ~30, reviewer poll 2s × 6), documented not weakened; 33 contamination tripwires added; alias-resolution caching measured (98ms hit / 279ms miss) and declined |
| 8 tier routing | classified or fail-closed, reds, real-push latency | `test/gh365-tier-fail-closed.sh` 5/0 (2,628-file sweep: 1,139 tier-1 / 326 tier-2 / 1,163 tier-3, no third state); tier1-real-push.log (34s), tier2-real-push.log (44s, 18-suite releases lane) |
| 9 matrix + policy | evidence classes unambiguous; macOS promotion preserved | matrix in PROJECT/2-WORKING/GH-365-TEST-SUITE-RECALIBRATION.md; smoke lane NOT added (reasoning there) |

## Width campaign (step 6) — HISTORICAL, at pinned pre-rebase head 46625dab (315 registered suites)

Per width: one clean run + one mutation run (a registered suite PREPENDED a forced red — an
appended red is dead code after the suite's own exit, observed and documented) in a fresh
disposable full clone; identity captured before/after each leg; telemetry retained.

| Width | Clean wall | Mutant wall | Forced-red caught | Named | Same executed set | Others' RCs identical | Identity |
| --- | ---: | ---: | --- | --- | --- | --- | --- |
| sequential | 1850s (rc 0) | 1782s (rc 1) | yes | yes | yes | yes | intact |
| 2 | 917s (rc 0) | — (rc 1) | yes | yes | yes | yes | intact |
| 4 | 524s (rc 0) | 509s (rc 1) | yes | yes | yes | yes | intact |
| 8 | 427s (rc 0) | 518s (rc 1) | yes | yes | yes | yes | intact |

Scheduling-ceiling model `floor ≈ max(Σpool/width, Σdriver-lock-lane + Σretry) + Σfixed`, computed
from the receipts:

| width | pool work | serial lane (driver-lock + retries) | fixed | model floor | actual | overhead | speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| seq | 1842.8s | 0.0s | 0.4s | 1843.1s | 1850s | 6.9s | 1.00× |
| 2 | 1799.0s | 66.2s | 0.4s | 899.9s | 917s | 17.1s | 2.02× |
| 4 | 1842.1s | 67.3s | 0.4s | 460.9s | 524s | 63.1s | 3.53× |
| 8 | 2563.1s | 106.5s | 0.4s | 320.8s | 427s | 106.2s | 4.33× |

**Reading** (this is the decomposition the exploratory profile's "~132.7s above sequential/4"
asked for): at 2- and 4-wide the pool aggregate stays flat — the gap to the ideal is genuine but
modest orchestration/tail overhead (1.9% and 12%). At 8-wide the pool aggregate itself grows +39%
(suites run slower under 8-way oversubscription; contention retries rise 1→4) — that part of the
gap is load-induced slowdown, NOT recoverable scheduling overhead. Contention retries were
recovered and classified on every leg (the GH-15 contract), and skip-lines stayed at the single
expected informational SKIP — no contention-induced coverage skips in any leg.

Known receipt caveat: the mutated suite's OWN rc is misrecorded as 0 in the SEQUENTIAL leg's
telemetry (a `$?`-after-substitution bug in the sequential recorder, fixed by 76174765 — the
runner verdict, exit code, and named-failure output were correct in every leg; parallel legs
recorded rc=1 correctly).

## Real-push latency (step 8: real pushes, not fixtures)

- Tier 1 (docs-only push): 34s wall — "documentation gate GREEN in 32s" — `tier1-real-push.log`.
- Tier 2 (releases-lane push, 18 suites at 2-wide): 44s wall — `tier2-real-push.log`.

## Qualifying run (step 1 gate, final commit 76174765)

**PASS at the resolved code head `f1b59bd0`** (after re-review 5504874543's fixes AND a second
development merge, ebe99e50) — all steps green including the clone-identity invariant, tree clean
at exit, gate record written with its output-sha256, `python:test_python_layer.py` and
`gamma-poison-staleness-probe` in the record's verdict list. **Denominator at this head: 328
registered + 3 non-suite** (development kept moving while this branch cycled reviews: 318 → 328
via the #356/#364/#385 lanes; every receipt pins the count at ITS head). Two intermediate runs
are part of the record: the 36d142ed run (green, pre-re-review) and the first ebe99e50-merged run
(refused — the new registry guards caught development's gh370/371/372 as unclassified, which is
the guards working, resolved by audited exemptions in f1b59bd0). The pre-rebase run at 5891d018 (rc=0, 1774s) is retained as
history in provenance; it predates both the rebase and the lane fix.

Two runs before THAT were REFUSED by the new bracket itself — it caught a stray repo-root `-a`
file (a BSD-tee option-permutation bug in the new per-suite capture) and a shellcheck
directive-typo comment, both in this branch's own changes. The detector's first real uses found
two defects in the changes that shipped it.

## Campaign coverage named explicitly (GH-377 gap 3)

- **Python lane:** `python3 -m pytest test/test_python_layer.py` executed inside every clean and
  mutant campaign leg (validate.sh tier 3) and in every qualifying run post-blocker-1.
- **npm lane:** `npm ci` + `test/acorn-extract.sh` run as the qualifying run's npm step
  (`qualifying-run.log`, step `npm ci + acorn-extract`).
- **Clean-tree:** the shared envelope's tracked-tree facet bracketed every campaign leg and every
  qualifying run; per-leg `identity-*.before/after` pairs committed alongside.
- **Lock-leak:** the envelope's driver-lock facet plus validate.sh's contended-retry
  classification (GH-528 family) — the campaign's retry counts are in the receipts (0/1/1/4 by
  width, all recovered, all named).
- **Worktree-leak:** the envelope's registered-worktrees facet on every leg; zero drift observed
  (no `worktrees` facet appears in any receipt's drift record).

## Provenance (GH-430)

See `provenance.jsonl` — every receipt paired with who/what/where/when/commit. Sub-agent-built
work (PDDA scanner; long-tail suites) was re-run and verified in the integration clone before
merge; sub-agent timing methodology is documented in their commit messages (interleaved
same-conditions A/B, 2 runs each).
