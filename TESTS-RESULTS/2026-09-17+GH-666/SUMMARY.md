# GH-666 — Narrow Agy probe repair

The model-validation subprocess now resolves its executable in caller CWD, then
runs in an owned stdlib temporary CWD. Allocation/cleanup/launch/nonzero/timeout
failures retain refusal, and successful parsing still accepts IDs/display/full
lines. No shared RTL, frozen Bash or process-lifecycle changes. This is protection
against relative writes, not an OS sandbox or absolute/detached-child protection.
The existing auth-probe relative-binary/cleanup limitations are not repaired here.

## Actual evidence

- Controlled original-runtime diagnosis: validation True, marker in temporary Git
  caller, BEFORE empty porcelain, AFTER `?? probe-write.txt`. No operator checkout
  or real Agy/model was used. diagnosis.py is the retained reproduction source.
- Baseline registered-test source d6fdf2bd: 11 tests, 11 failure events (including
  subtests), exit1. This is original-runtime red evidence, not green qualification.
- Final b6c973e4: 13 actual-validator cases pass, exit0, including executable forms,
  ignored marker, sentinel/Git identity/HEAD/tree, directory cleanup and error paths.
- Same final source, remove only model-subprocess cwd in memory: exit1, 11 failure
  events in 13 tests. Ignored marker is detected despite unchanged Git porcelain.
  ablate-cwd.py is the retained ablation source; no tracked source was mutated.
- Static-only f25de3fe run: exit1, seven code/config stages pass; existing GH-658
  supporting-document coverage fails. Not a final b6 static or full-suite receipt.
- Preimplementation path-integrity: exit1 on the same base fixture-reference
  errors already observed in GH-661. These unrelated repairs are not bundled.

Each log is nonempty, source-pinned and SHA256-addressed in provenance.jsonl.
Mutation-heavy tests run only in the separate disposable full validation clone.

## Publication hold

Full validation and gated topic push/PR are not complete. Known required base
checks are red; no bypass, hosted promotion, PR readiness, merge or deployment
is claimed. Plan QA is Approved; final implementation QA remains pending.
Issue GH-661 and its clone/branch remain untouched. No stacked dependency,
branch deletion or cleanup is authorized. Resolve base gates before normal
publication, or explicitly authorize disclosed WIP draft publication under GH-487.
