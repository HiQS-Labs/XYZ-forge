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
- Final-source registered Agy suite: exit0, all 13 validator cases and 62 existing
  assertions pass; model refusal/forwarding and normal turns are preserved.
  Owned plan frontmatter/status checks also pass with zero errors/warnings.
- Final-source required path check: exit1, same base missing-reference failures.
  Clone HEAD, non-bare identity, GitHub origin and tracked tree show no drift.
- Static-only f25de3fe run: exit1, seven code/config stages pass; existing GH-658
  supporting-document coverage fails. Not a final b6 static or full-suite receipt.
- Preimplementation path-integrity: exit1 on the same base fixture-reference
  errors already observed in GH-661. These unrelated repairs are not bundled.

Each log is nonempty, source-pinned and SHA256-addressed in provenance.jsonl.
Mutation-heavy tests run only in the separate disposable full validation clone.

## Review follow-up

Source e6898846 adds an existing executable with an invalid interpreter, proving
launch refusal after temporary-directory allocation, caller preservation and
directory/log removal. All 14 validator tests pass. Disabling only probe cleanup
in memory makes this single launch-error test fail on directory residue; the
outer controlled sandbox still cleans up. Missing-event and empty-path negative
controls now guard the registered suite's GH-296 claim-path assertion.

The registered suite's older token diagnostics are not clean bookkeeping evidence.
Its unowned-token fixture leaves an intruder holding z/** (test/agy-turn.sh:275–286).
Later seed_token calls request overlapping z/** and ignore claim/release results
(:94); src/claim.js rejects overlap and src/scope.js release rejects an open task.
Thus these are failed seeding diagnostics, not expected teardown. The actual
GH-296 prelaunch claim is independently required nonempty; model tests and
specific behavior assertions are retained, not a blanket token-lifecycle claim.
Repairing that older fixture is excluded from this runtime fix.

Current e6898846 registered suite exits 0: 14 validator tests and 65 shell
assertions pass, including missing-event/empty-path refusals. The failed seeding
diagnostics remain; this result does not prove a fully clean token lifecycle.

## Publication hold

### 2026-09-17 authorized draft publication

Operator explicitly approved skipping the local pre-push check for disclosed WIP
publication. Draft PR #669 was published at a19d3fc7 with XYZ_SKIP_PREPUSH=1;
the entire local gate was skipped, not a single failing stage. No merge authorized.
The following hold describes the earlier reviewed/tested base; development has
since advanced. Current-base integration and hosted evidence are separate and
must not be inferred from the older receipts.

Full validation and gated topic push/PR are not complete. Known required base
checks are red; no bypass, hosted promotion, PR readiness, merge or deployment
is claimed. Plan QA and final scoped implementation QA are Approved. Final review
R2 approved bd1e7d02dadf1402b493d4ce6d8040a0ce0fc343 with driver attestation
1e680b5a2af8213a9477caa2fd84c97c2eafe3a39f241737475dc5c23ac88f22.
This is code/evidence approval, not full-gate or publication approval.
Issue GH-661 and its clone/branch remain untouched. No stacked dependency,
branch deletion or cleanup is authorized. Resolve base gates before normal
publication, or explicitly authorize disclosed WIP draft publication under GH-487.
