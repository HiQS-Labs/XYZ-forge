# Exact main qualified; Pages publishing needs a decision

Main `4895148683120b8b6f808d4dcd66267a3754fd2c` is qualified by CI run38326961087, macOS job115067757430. The full sequential registry passed409/409, with0 failed and0 retry-ladder suites. Blocking smoke passed. The hosted job emitted:

```
MACOS-BOUNDARY: green 4895148683120b8b6f808d4dcd66267a3754fd2c
```

The retained1,551,978-byte raw log has SHA256 `99b3b267eea944e265cb9548498e95092d9c46444492fa29a043997748775438`. Main's parents are last-good B `a076b1b117a68252dc3d9d1c4901b0c31fcb4db3` and tested F `af50c205e3f04f3fc6a02ac6c402f2013123b127`; its tree matches F exactly. Remote main still matched M at verification. Firsthand review and native independent QA round2/3 approved F. This receipt carrier is a separate commit; qualification does not transfer to it or later main metadata commits.

Pages run38326961150 built the main artifact but could not deploy: `github-pages` allows only `development`, while the workflow targets both branches. The existing homepage returned HTTP200 at01:19UTC. An operator decision is needed to allow main or affirm development-only publishing. No protection change, deploy, rerun or bypass was performed.

The operator deferred #954/#1024; #930 is held, #1033 separate, #1034 untouched. #1024's FAIL/Escalated4/4, #1031 and W8-W11 remain unchanged. Automatic approval review separately denied canonical #1012 issue/plan writes; none were retried. All clones, refs and fixtures are preserved. No new CI cases, cap resets, live provider/pilot, installed-skill/schedule change or cleanup. The declared live-agent exclusion means qualification does not prove live-provider or installed-state restoration.
