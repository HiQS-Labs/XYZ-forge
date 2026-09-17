# GH-653 / GH-665 verification

Status: fixture full gate green and independent final source QA Approved; combined #669 full run green (393/393).
Fixture PR: https://github.com/HiQS-Labs/XYZ-forge/pull/671 (no merge authorized).
No merge authorized. GH-661 source clone untouched. No published #669 qualification claim.

## Source and results

Fresh full validation clone: XYZ-forge-gh653-gh665-validation. Original-base
011113f64bf60da1c93ab97c37c70c760f2dbb56; repaired-source
5d8c994b705573141a36693ef41165b213e78c37. Code pins (documentation commits do not
change these inputs):

- test/gh642-consumer-fruit.sh SHA256 38be8fac37eb657ec65d174e77d502f1b26b4916bbc249d3d5e046131c8d4f09
- negative-controls.py SHA256 c3f53eb85350410c52682a370b89df24821e83ca20c21e567af0eb79f54c99e6

Nonempty transcripts accompany each result:

| Check | Exit | Observable result |
|---|---:|---|
| Original-base GH-642 | 1 | Six earlier assertions pass, worktree fixture creation fails |
| Repaired GH-642 | 0 | 62 pass, 0 fail; true linked-worktree and RTL-copy cases reached |
| Guard-disabled control | 1 | `fixture guard accepted symlink (rc=0)` |
| Caller-damage control | 1 | `caller changed after empty` |
| bash -n / shellcheck -S error | 0 / 0 | Parse/static checks pass |
| ci-local.sh --fast --base origin/development at 82f786f9 | 0 | Eight static/doc/frozen-twin/npm stages pass; full suite explicitly skipped in this invocation |
| Normal gated topic push at 82f786f9 | 0 | 393/393 full checks, 1082 seconds; no bypass; prepush.log retained |

Controls execute the actual suite with one in-memory edit, using its original path
as Bash $0. They never rewrite tracked source; deliberately damaged callers are
inside _setup's owned outer sandbox. Validation HEAD, origin URL, bare=false and
clean tracked tree remained unchanged. Full gates run only in full disposable
clones, never linked worktrees or valued source checkouts.

## Recent PR review

Bounded Sep03–17 merged-PR sample plus historical fixture examples, not exhaustive
incident counts or a measured trend. PR #643 introduced the unseeded suite. PR #614
concerns related routing/isolation; #652 fixes a separate vendored-tool lookup.
Older #6 introduced the reusable guard, #89 expanded adoption. No other published
PR specifically fixing #653/#665 was found; held #661 already contains the scoped
fixture repair, extracted here without its unrelated changes.

## Remaining qualification

Plan and final source QA are independently Approved in relay-system/2026-09-17/gh653-plan-qa.md
and gh653-final-qa.md (driver-attested; final reviewed b703148f). Final reviewer
read the whole touched suite and witness/source/evidence, ran no new tests, and
found no remaining pre-existing safety defect. Nit: future scaffold Setup should
carry the actual criteria; current Producer R1 supplied them. No code change needed.
The full run is pinned to 82f786f9, not later documentation-only commits.

Separate combined candidate + #669 local verification is complete. Combined clone
ae56f400151631b3a3fb0a2fce97dd4ca0c7fb1e
has both parents (published #669 aa634155 and fixture 82f786f9). Existing resolver
preserved all three issue records/receipts, generation 749; displaced DB moved
intact under temp before testing. Focused 62 fixture checks, 14 validator tests,
65 Agy assertions and eight --fast stages pass; ./validate.sh full run is 393/393,
exit 0, with unchanged HEAD/origin/bare=false/clean tracked tree. Nonempty combined-*
transcripts retained. Coverage used separate --fast and full validate calls; no
ci-local full-run gate record or promotion qualification is claimed. Code pins:
fixture SHA256 38be8fac37eb657ec65d174e77d502f1b26b4916bbc249d3d5e046131c8d4f09;
agy-turn.py 512465da0f09acccf3b4805e860c028dca991cf129021115c38bc15b9dc440ee;
gh666_agy_model_probe.py 30e8d149d81b4f2458270f08ab2373fc0f599772cbb23f19cfe87e6e6ac34fde.
All commands were run in XYZ-forge-gh669-fixture-recheck. These results
are not qualification of published #669. #669 remains draft until fixture prerequisite
lands. Current hosted smoke passes; advisory platform jobs are skipped, not passed.

## Next gates (no merge authorized)

### Latest-base refresh

Development advanced to 92462d50 during verification (GH-672 skills deployment).
Its ledger writes conflicted with this topic; existing resolver preserved #653,
#665 and completed #672, rebuilt generation 749, and displaced DB/own regenerated
views were preserved under temp. Incidental rendered-view changes were excluded;
topic diff contains no skills/shared-guard/setup changes. Refresh commit a17490b1:
fixture remains 62/62 with the same code hash. Normal hook selected releases and
skills-army-hq affected suites: 29/29, exit 0, 392 seconds, no bypass (base-refresh-push.log).
This is affected-subsystem evidence on the latest base, not a new 393-check run
or promotion qualification. Earlier full/combined results retain their exact pins.

### Remaining landing gates

1. Approve and land fixture PR #671 → verify merge/issue closure using existing follow-up.
2. Refresh #669 against current development using existing ledger resolver → preserve
   both ledgers/receipts, rerun its exact-head normal checks and hosted checks, then
   reassess draft readiness. Do not resume held #661 or readers automatically.
