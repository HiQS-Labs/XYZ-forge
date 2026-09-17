# GH-653 / GH-665 verification

Status: fixture full gate green; independent final QA and combined #669 full run pending.
Draft fixture PR: https://github.com/HiQS-Labs/XYZ-forge/pull/671.
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

Independent final QA and fixture hosted checks, plus separate combined candidate
+ #669 local verification. Combined clone ae56f400151631b3a3fb0a2fce97dd4ca0c7fb1e
has both parents (published #669 aa634155 and fixture 82f786f9). Existing resolver
preserved all three issue records/receipts, generation 749; displaced DB moved
intact under temp before testing. Focused 62 fixture checks, 14 validator tests,
65 Agy assertions and eight --fast stages pass; full run pending. These results
are not qualification of published #669. #669 remains draft until fixture prerequisite
lands. Current hosted smoke passes; advisory platform jobs are skipped, not passed.
