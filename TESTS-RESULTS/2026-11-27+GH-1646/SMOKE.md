# GH-1646 smoke (manual check, GH-1088 / GH-831)

Base: development `52813e56f`. "unfixed" = `utils/py/swarm_preflight.py` at that base; "fixed" =
the working tree of this branch. All runs: `bash utils/swarm-preflight.sh --project-doc <doc>
--target-root <task clone> --dry-run`, GitHub origin, issue bodies fetched live on 2026-11-27.

## Main path — #792 (plain-bullet issue Acceptance), verbatim checkbox copy without the workaround

`<doc>` = scratch copy of `PROJECT/3-COMPLETED/GH-792-GEN4-SANDBOX-DISJOINT-FIRST.md` with the
`## Acceptance — deviations from the issue` section removed (the three criteria unchanged).

| Parser | acceptance line | exit |
|---|---|---|
| unfixed | `diverged — 3 doc criterion(a) absent from the issue with no declared deviation` | 4 |
| fixed | `match — 3/3 criteria copied verbatim from issue #792` | 4 |

Exit is 4 (STALE) in both because #792 is closed and its fix has landed; the issue's original
exit 5 came from `diverged` on an open candidate. The acceptance verdict is the behaviour under test.

## Adjacent path — rerun on existing captures

Checkbox-style issue Acceptance, active docs (unchanged before/after):

| Doc | unfixed | fixed |
|---|---|---|
| `PROJECT/2-WORKING/GH-1243-CONSULT-ANSWER-PAYLOAD.md` | match (2 deviations accounted for) | same |
| `PROJECT/2-WORKING/GH-1254-OUTER-LOOP-BORROW-DECL.md` | match 4/4 | same |
| `PROJECT/2-WORKING/GH-1344-FINISHING-WORK-READERS-SWEEP-CLOSE.md` | match 6/6 | same |

Explicit replay of the archived #792 capture (old workaround still declared), fixed parser:
`diverged — deviations are declared but the two lists do not differ` (declared=3). Known effect,
stated in the plan and PR: the archive is a historical record and is not edited; stale-deviation
enforcement is intentionally unchanged.

## Adjacent path — nested plain sub-bullet, plain sibling and fenced example (final QA r1)

`smoke-nested/`: issue body served by a hermetic `gh` stub on PATH (`issue-body.md`: a checkbox
criterion with a nested plain detail, a plain sibling criterion, and a fenced `- literal example
output`), capture `capture.md` copying the two criteria as checkboxes. Same CLI command.

| Parser | acceptance line | exit |
|---|---|---|
| unfixed | `diverged — 1 doc criterion(a) absent from the issue with no declared deviation` | 5 |
| fixed | `match — 2/2 criteria copied verbatim from issue #99001` | 5 |

Exit 5 in the fixed run is the synthetic contract's artifact path (`readiness: artifact path not
found at target.ref`), not acceptance; see `preflight-fixed.txt`.

## Suites

- `red-gh400-unfixed.txt`: final `test/gh400-acceptance-fidelity.sh` against the base parser —
  34 pass, 7 fail (the 7 are GH-1646 cases; the other 8 C20 cases are regression guards that pass
  on both).
- `green-gh400.txt`: 41 pass, 0 fail. `green-gh557.txt`: 16 pass, 0 fail.

Verdict: PASS.
