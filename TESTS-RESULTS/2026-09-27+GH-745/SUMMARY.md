# GH-745: rollback events poisoned `.tick/events`, and suites wrote them into the real clone

Base \`staging/stabilize-2026-10\` at \`6653ab16\`. Fix \`b375e787\`, rebased unchanged as the PR head.

**Two defects, one writer** (\`utils/py/wave_reconcile.py\` \`RollbackJournal.rollback()\`):

1. **One file could hold two records.** The event file was named by timestamp and opened in append mode (\`open(evt, "a")\`). GH-707 had already cut the name to the millisecond, but two rollbacks in the same instant still shared one file. \`tick\` parses each event file as one object, so one such file made \`tick claims\` fail \`events-unreadable\` for the whole clone. merge-cleanup then preserved the clone forever.
   - **Fix:** the name adds the pid and 8 random hex characters, and the file is created with \`open(evt, "x")\`: one record per file, never appended. \`except Exception: pass\` is kept, so the event can never make a rollback worse.
2. **Suites wrote into the real clone.** \`RollbackJournal()\` defaults its root to the cwd. \`gh424\`, \`gh425\` and \`gh421\` built it with no root, so running them from a clone that has \`.tick/events\` wrote real rollback events there.
   - **Fix:** each passes its own fixture root (\`self.root\`, or \`legacy\` in gh421). No production caller relies on the default: \`grep 'RollbackJournal()'\` finds none left.

No new test, no new assertion, no assertion changed. \`test/wave-reconcile.sh\` already pins the event's shape (one file, one record, the \`schema_version\`, \`type\` and \`agent\` fields, no \`task\`) and still passes.

| Witness | Base \`6653ab16\` | Head \`b375e787\` |
|---|---|---|
| \`leak-witness.sh.txt\`: run gh424, gh425 and gh421 from the clone root | **3** rollback events written into the real clone | **0**, ×5 runs; all three suites OK each run |
| \`collision-witness.py.txt\`: two rollbacks at one frozen instant, then \`tick claims\` | 1 file, 2 records; \`tick claims\` **rc 3** \`events-unreadable\` | 2 files, 1 record each; \`tick claims\` **rc 0** |
| \`test/wave-reconcile.sh\` | — | 23 passed, 0 failed ×5 |

**Route:** changed_tests=gh421-auto-wave-reconcile.sh,gh424-roadmap-status-marker.sh,gh425-gate-provenance-pr.sh,wave-reconcile.sh; tier=3; tier2_subsystems=pdda; tier2_tests=. A test file changed, so tier 3; under #854 D2 that obligation is paid at the window's landing.

**Recovery for an already-poisoned clone** (from #745): split any multi-record \`*-wave-reconcile-rollback.jsonl\` into one-record files. That state is local and git-ignored.
