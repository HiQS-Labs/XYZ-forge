# GH-744 focused-suite evidence (task clone, HEAD f323fe7c, run un-sandboxed 2026-09-21)

```
agent-chorus-bridge.sh                       PASS ==========================================
agent-chorus.sh                              FAIL rc=1
ci-route.sh                                  PASS   ci-route: 76 pass, 0 fail
find-harness.sh                              PASS   find-harness: 23 pass, 0 fail
gh132-review-xyz-skill.sh                    PASS   gh132-review-xyz-skill: 19 pass, 0 fail
gh165-governance-canonical-paths-guard.sh    PASS === gh165-governance-canonical-paths-guard.sh Results: 4 pas
gh233-agent-chorus-concurrency.sh            PASS   gh233-agent-chorus-concurrency: 16 pass, 0 fail
gh267-express-skill.sh                       PASS gh267-express-skill: pass=108 fail=0
gh278-turn-timeout-parity.sh                 PASS   gh278-turn-timeout-parity (total): 11 pass, 0 fail
gh284-p4-release-lanes.sh                    PASS   gh284-p4-release-lanes: 39 pass, 0 fail
gh292-worktree-vendored-discovery.sh         PASS   gh292 worktree vendored discovery: 7 pass, 0 fail
gh346-gateway-allowlists.sh                  PASS   gh346-gateway-allowlists: 56 pass, 0 fail
gh369-find-doc-root-resolution.sh            PASS gh369-find-doc-root-resolution: 14 pass / 0 fail
gh393-deepseek-readiness.sh                  PASS   gh393-deepseek-readiness: 9 pass, 0 fail
gh396-find-harness-roots.sh                  PASS   gh396-find-harness-roots: 41 pass, 0 fail
gh400-source-url.sh                          PASS   gh400-source-url: 13 pass, 0 fail
gh448-driver-lock-resolver.sh                PASS gh448-driver-lock-resolver: 18 pass, 0 fail
gh549-work-events.sh                         FAIL rc=1
gh578-ci-optimize-skill.sh                   PASS   gh578-ci-optimize-skill: 36 pass, 0 fail
gh589-skill-viewer.sh                        PASS gh589-skill-viewer: 8 passed, 0 failed
gh589-xyz-mini-sync.sh                       PASS gh589-xyz-mini-sync: 18 passed, 0 failed
gh609-sdlc-agent-gaps.sh                     PASS   gh609-sdlc-agent-gaps: 33 pass, 0 fail
gh615-start-task-reinforce.sh                PASS   gh615-start-task-reinforce: 8 pass, 0 fail
gh616-start-task-commensurate-envelope.sh    PASS   gh616-start-task-commensurate-envelope: 7 pass, 0 fail
gh617-relay-xyz-commensurate-review.sh       PASS   gh617-relay-xyz-commensurate-review: 9 pass, 0 fail
gh620-skills-army-mini-sync.sh               PASS gh620-skills-army-mini-sync: 28 passed, 0 failed
gh645-merge-cleanup-xyz-tools.sh             PASS OK
gh649-pdda-migration.sh                      PASS GH-649 migration checks passed
gh660-skill-drift.sh                         PASS gh660-skill-drift: 7 pass, 0 fail
gh678-installer-live-links.sh                PASS   PASS: matrix covered all 22 discovered installers
gh681-reviewer-probe-rules.sh                PASS gh681-reviewer-probe-rules: all cases passed
gh77-standup-triage.sh                       PASS   gh77-standup-triage: 150 pass, 0 fail
hq-locator.sh                                PASS == hq-locator: 8 passed, 0 failed ==
path-integrity.sh                            FAIL rc=1
relay-pkg-freshness.sh                       PASS   relay-pkg-freshness: 3 pass, 0 fail
relay-xyz-skill-guard.sh                     PASS   relay-xyz-skill-guard: 12 pass, 0 fail
releases-skill.sh                            PASS   releases-skill: 40 pass, 0 fail
skill-extract.sh                             PASS   skill-extract: 4 pass, 0 fail
skills-army-hq.sh                            FAIL rc=2
xyz-harness-hooks.sh                         PASS   xyz-harness-hooks: 62 pass, 0 fail
xyz-vendor.sh                                PASS   xyz-vendor: 94 pass, 0 fail

re-run after the Path-join repoints (faa62025):
path-integrity.sh              PASS   path-integrity: 2 pass, 0 fail
agent-chorus.sh                PASS   agent-chorus: 215 pass, 0 fail
skills-army-hq.sh              PASS   33 passed (pytest test_deploy_skills.py)
gh436-merge-cleanup.sh         PASS
gh549-work-events.sh           FAIL   identical 105/20 on the untouched primary clone (XYZ_WORK_CONNECTORS_REGISTRY env) — pre-existing, verified again in the disposable-clone gate
```

Acceptance one-liners: depth-2 SKILL.md count = 60; depth-1 count = 0; `find-harness.sh --check` resolves the clone via git-root; both publish manifests resolve every source; drift check vs Deployed Skills recognises 22 forge-owned skills before and after (12 ok + 10 drifted-by-text-repoint after).
