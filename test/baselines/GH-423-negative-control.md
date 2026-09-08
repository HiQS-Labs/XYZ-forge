# GH-423 negative control

Observed before the renderer edit on 2026-09-08. The DB was opened read-only;
no source data or git state was changed. The actual DB row and database hash
below identify the input; absolute scratch paths are normalized for portability.

```text
GH-423 pre-change observation (2026-09-08)
releases.db sha256=584cf663b4eef4485f51f36caa18f3830c756051510a629a5b0f568fe554200a
DB row=(423, 'releases roadmap render: emit the DB as ledger markdown — the missing verb #418 actually depends on')
$ python3 utils/py/releases_app.py --root <checkout> roadmap render
exit=2
usage: releases roadmap [-h] {sync,list,add,rate,repoint,update,move} ...
releases roadmap: error: argument roadmap_cmd: invalid choice: 'render' (choose from 'sync', 'list', 'add', 'rate', 'repoint', 'update', 'move')
$ QUEUE_PLAN_ROADMAP=<scratch>/not-yet-rendered.md python3 utils/py/marathon_plan.py --dry-run --format json
exit=3
ROADMAP not found: <scratch>/not-yet-rendered.md
stdout=''
DB-only GH-423 not surfaced by the explicit missing-file input.
```

The original brief predates the planner's native DB reader. Its claim that the
current default planner omits DB-only rows is no longer valid. This observation
covers the explicit file-input seam (`QUEUE_PLAN_ROADMAP`), which requires an
existing file, and the absent `roadmap render` command. It does not claim that
the default DB reader fails.

`test/gh423-roadmap-render.sh` includes a repeatable negative control: delete
GH-423 from a nonempty fixture and require the DB-row/parser comparison to fail.
The positive contract covers both parsers and the planner's actual explicit-file
reader up to its scheduling boundary. Custom sections remain verbatim and retain
the planner's existing section-filter behavior.

## Focused verification and witnessed guard mutation

Final focused command (all fixtures under the exempt scratch directory):

```text
$ GH423_TEST_TMP="$PWD/.relay-scratch" bash test/gh423-roadmap-render.sh
Ran 8 tests in 0.214s
OK
NEGATIVE CONTROL: DB-only GH-423 omission trips the round-trip assertion
```

A scratch copy of `releases_app.py` was changed from
`if tracked.returncode != 1:` to `if False:` and the same focused suite was run
against that copy. The production file was not modified by this experiment:

```text
Guard mutation: replaced tracked.returncode refusal condition with False in scratch copy.
exit=1
FAIL: test_output_refusals_and_untracked_roadmap
AssertionError: SystemExit not raised
```

Tracking responses are mocked; no git command ran during either test invocation.
This witnesses that removing the refusal fails the assertion. It does not replace
a real git-index integration check by the outer harness. The existing
`parse_roadmap_ledger` reader emits an unclosed-file ResourceWarning; the focused
suite still exits zero. That pre-existing reader is unchanged.

The read-only production-data probe on the database hash above produced:

```text
DB rows: 140 ledger parser: 140 planner parser: 140
Sections: [('Completed', 94), ('Deferred · vision', 1), ('In progress', 4), ('Queue / parked intake', 41)]
DB-only GH-423 preserved: True
Stored titles differing from replayed raw bullet titles: 76
```

The last count is a source-contract discrepancy, not a renderer normalization:
`roadmap add` stores an issue title separately from the full `GH-N · title` in
`raw_text`, and existing rows can have further editorial differences. Literal
comparison with the stored `title` column therefore conflicts with the brief's
verbatim-replay requirement for these rows. The renderer preserves `raw_text`;
the focused fixtures compare exact GH/title pairs where those representations
agree and separately pin synthesis of a missing GH prefix. No source rows were
rewritten. The full project gate remains the harness's responsibility.
