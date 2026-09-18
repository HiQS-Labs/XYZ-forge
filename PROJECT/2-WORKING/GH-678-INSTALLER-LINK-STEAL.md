---
title: "GH-678: skills/*/install.sh steals app symlinks from the managed Skills Army collection"
status: Active
created: 2026-09-17
updated: 2026-09-17
owner: operator
gh_issue: 678
source: https://github.com/HiQS-Labs/XYZ-forge/issues/678
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
goal: >
  Stop every skill installer from replacing a live symlink it does not own, and stop the gate
  from writing real ~/.gemini directories through test/agent-chorus.sh's partial sandbox.
---

# GH-678 — installers steal symlinks; the gate writes real HOME

## Status

| What was just completed | What's next |
|---|---|
| Root cause reproduced and confirmed against three same-day incidents; 22 installers guarded; test sandboxed with a containment assertion; matrix regression added and registered; PR open | Land; recover this device's three stolen Gemini links; retire stale task clones that still carry the leaky test |

## Root cause (debug-mantra, all four steps)

1. **Reproduced** in a sandbox in one second: three managed symlinks stolen with an "installed" message and no record of the old target; a real directory backed up. Same result from the single-target template.
2. **Fail path.** `test/agent-chorus.sh:683,696,719` run the real installer with `CLAUDE_SKILLS_DIR` and `CODEX_SKILLS_DIR` sandboxed and nothing else. `skills/agent-chorus/install.sh:75-77` also writes three `$HOME/.gemini/**` defaults. The Gemini targets were added in `3c820f06` (2026-08-20), leaving the pre-existing two-variable test override unchanged. `9be6f70f` (2026-08-23, #193) subsequently renamed the affected skill.
3. **Falsified.** No `HOME` redirect anywhere in `validate.sh` or the test; the test's exact env writes three Gemini links under whatever HOME is; the clone that owned the 11:24 steal had a gate artifact at 11:27.
4. **Breadcrumbs.** Three steals on 2026-09-17 (10:21 gh666, 11:24 gh669, 14:26 pr235), each minutes before that clone's gate artifact, and each time Claude Code and Codex links stayed on the collection because those two are the sandboxed ones.

Latent underneath: all 22 installers `rm -f` any symlink not already theirs. Real directories are backed up (5) or refused (17); symlinks, the case the collection creates on purpose, are deleted.

## Change

- `test/agent-chorus.sh`: `HOME="$SANDBOX_HOME"` on all three installer calls (the pattern `gh77-standup-triage.sh:751` already uses); corrected the comment at line 680 that claimed the test never wrote real user directories; one assertion that the HOME-relative targets landed in the sandbox. Dropping the override makes that assertion fail with "escaped the sandbox" — witnessed.
- 22 `skills/*/install.sh`: before the main-link `rm -f`, refuse when the link is live (`-e`), naming its current target; dangling links are still cleaned. Seven textual variants, one insertion each; legacy-alias loops and `standup --check` untouched. `relay-xyz/install.sh` gains `rc` aggregation and `exit "$rc"` like its four siblings, so a refused target is visible.
- `test/gh678-installer-live-links.sh`, registered in `validate.sh`: all 22 in a sandbox HOME with every target variable set; live foreign link must be refused and untouched; dangling link must be replaced; matrix count must be 22. Against the original installers with `TEST_SOFT_FAIL=1`: 22 of 22 replaced the foreign link, 22 of 22 still replaced the dangling one.
- `README.md`: one paragraph telling Skills Army HQ machines to skip the installers.
- `PROJECT/2-WORKING/recon-install-sh-link-steal.md`: the Recon Map (10 seams, 3 unknowns).

## Acceptance Criteria

- [x] `test/agent-chorus.sh` passes and real `~/.gemini/**/skills/agent-chorus` mtimes are unchanged across a run (verified on the affected device).
- [x] Negative control: with the HOME override removed from the first call, the suite fails with "installer's HOME-relative targets escaped the sandbox" and a throwaway HOME receives three Gemini links.
- [x] `test/gh678-installer-live-links.sh`: 45 passed against the fix; 22 of 22 refuse-checks fail against the originals.
- [x] `agent-chorus.sh` 213 passed, `gh77-standup-triage.sh`, `releases-skill.sh`, `gh132-review-xyz-skill.sh`, `gh589-xyz-mini-sync.sh` all exit 0.

## Skipped, on purpose

- A shared installer library. Seven variants exist because 22 files drifted; a library is a new contract for 22 consumers, three of which must stay self-contained for the mini repos. Add when a third policy change touches all 22.
- The false-success path in the five `install_one` installers: a failed `rm -f` or `ln -s` inside the function falls through to "installed" because `f || rc=1` suppresses errexit. Separate, small, and not about the steal.
- Stale per-skill docs about which directories an installer writes (`relay-xyz/SKILL.md:210`, `10days/SKILL.md:99`, `mini/README.md:37-41`).
- Making `~/.gemini/antigravity/skills` and `~/.gemini/antigravity-cli/skills` HQ targets. `targets.md:20-21` calls the first historical; the second is undocumented. Policy question, see #676.

## Related

- #676 names foreign links as the drift that matters under the one-collection-per-device SOP (GH-672).
- Stale task clones on disk still carry the leaky test until rebased or retired; each gate run there can still steal until then.

## Pulse issue 2 follow-up (2026-09-17)

Source issue: https://github.com/Hypercart-Dev-Tools/rebalance-git-pulse/issues/2.
The existing PR #680 is reused. Easy to reverse: revert the follow-up commit;
projection updates retain an intake backup, and link migrations retain prior link text.

Rating: `rated 85/80/50/85` (RELEASES read-back). Repeated recoverable app-link corruption
can remove skills when a clone is retired; a small installer/test correction is cheap.
Appeal stays neutral. Reports #678 and Pulse #2 describe the same defect, not two independent
classes. Three September 17 occurrences are documented. The September 4–17 versus
August 21–September 3 trend is unknown: no comprehensive incident history exists.

The review found two concrete gaps: inherited Gemini target variables bypass sandbox HOME,
and a live legacy alias is repointed before the current-name refusal. The existing installer
wrapper now clears those three variables in a subshell, with sentinel destinations and
assertions for all three default Gemini paths. Legacy links now preserve live foreign owners
and propagate refusal, while the existing dangling-link migration stays covered. The matrix
uses the discovered nonempty installer set instead of requiring exactly 22, and drops an
observation that confused pre-existing real installations with writes during a test.

Scope stays device-independent: HQ derives skills and enabled targets from local configuration.
No additional IDE targets, global HOME policy, task-clone name heuristic, or doctor subsystem
is introduced. `sync.py --status` is the documented health check. Its configured-target scope
and app-discovery limits still apply.
