# GH-1401 verification

Implementation smoke revision: `31424e4ff421037c413c0ef3fef2ad55ba4afaa8`; main probe base: `39207869450ee7115dcd9b552fb1bcacd15e203b`.

- Main: existing `extract_contract` and `jog_run.contract_probes_from_doc` returned a nonempty path_absent probe and no reason. `swarm-preflight --project-doc temp/conveyor-valid.md --target-root <verify-root> --dry-run --format json` exited 0, candidate ready, missing conveyor file unfixed at pinned base. Live issue OPEN; source URL valid. Acceptance fidelity explicitly unknown/no-issue-section: #1401 has no Acceptance heading; this is not claimed verified.
- Adjacent rerun: same contract at implementation revision detects conveyor already present, candidate stale/landed, exit 4. The skill holds readiness on this result instead of claiming another executable task.
- Red control: empty fix_probes rejected by existing parser with exit 3.
- Paired existing-file control: `grep_present BUG` on contents BUG/FIXED gives unfixed/landed. Intentionally inverted `grep_absent BUG` gives landed/unfixed, exposing polarity error. Assertions in the manual invocation passed; output in conveyor-smoke.log. These are manual checks, no new suite/gate.
- Existing Codex shim prerequisite: `bash test/codex-turn.sh`, 43 pass, 0 fail, in separate disposable full clone. Its HEAD/origin/bare/local-identity bracket was unchanged. The verify origin was subsequently deliberately repointed from the local source to canonical GitHub before real preflight so native issue lookup could resolve; this was setup, not suite drift. No gate ran in a linked worktree.
- Skill quick_validate passed in task-local venv (system python lacks PyYAML); source dependencies were not changed.
- Consumer read-through: existing issue mode reuses canonical doc/row; ranked mode lists unrated discovery separately; scheduled/event modes invoke the same bounded flow without installing infrastructure. Pending preparation PR does not label readiness. Rerun reuses marker comment and preserves scores/ovr; publication requires integration-ref availability and fresh preflight. No live backlog labelling/publication was used as a smoke test.

Commands and expected outcomes are retained in provenance.jsonl and the smoke inputs. Preflight JSON paths are replaced with `<verify-root>` for portability; semantic fields and SHAs are retained. Classified route: docs, tier 1. Final documentation gate and review results are recorded in the canonical plan/PR.
