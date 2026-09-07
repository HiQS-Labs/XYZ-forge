# GH-484 fixture ledger

Platform: macOS; isolated full verification clones; fixture writes only inside
temporary local repositories, alternate homes and app roots. No live deployment
was exercised by these tests. Commands use `python3 -B -m unittest discover -s test
-p test_deploy_skills.py`; targeted controls add `-k <test name>`.

| Revision / experiment | Observed result | Conclusion |
|---|---|---|
| `6b6e643e`, full focused suite | 18 tests in 17.753s; exit 1, two failures | Strict preview and legacy-preview observers detected source `.git` directory mtime changes. |
| `6b6e643e`, single preview with independent before/after observer | Only `source repo/.git` directory mtime changed | Git's optional status/index bookkeeping, not a collection write. |
| `adc6cbfd`, optional Git writes disabled | 18 tests in 18.465s; exit 0, OK | Both preview regressions now pass; all 18 behavioral tests pass. |
| `adc6cbfd` plus deliberate mutation skipping the owned-link text guard | `test_a4_foreign_real_link_and_lost_ownership_preserved`: 1 test in 1.559s, exit 1 | Retargeted `sample -> foreign-dangling` disappeared; independent tree comparison fails. Guard is not decorative. |
| `adc6cbfd` plus resurrected old SKILL.md | `test_a10_old_discoverable_skill_is_absent`: 1 test in 0.389s, exit 1 | `AssertionError: True is not false`; competing discovery entry is detected. |

Both deliberate mutations were reversed with exact file patches in the disposable
red-control clone, not a Git working-tree reset. They were never applied to the
task branch. Expected stderr `ZIP verification failed` and `injected copy failure`
come from failure-injection cases whose live payload/link preservation checks pass.

The 18 tests cover detached manager use, missing sibling refusal, archive bytes/modes/
links round-trip and same-day collisions, CRC/copy failures, self-update, strict
preview, malformed names/frontmatter and unsafe links, overlapping/aliased roots,
denied scans, link idempotence/recreation/dedup/disabled-target withdrawal, explicit
adoption/source migration, partial success, corrupt/missing state, shared locking,
real process exits at payload rename/action/state/history boundaries, checksum
refusal, and explicit legacy link/real-folder retirement. These are fixture claims,
not five-app usability evidence. Full-repo gate and final relay remain separate.
