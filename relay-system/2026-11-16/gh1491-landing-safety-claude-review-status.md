# GH-1400 / PR #1491 landing-safety follow-up: independent Claude review result

Scope: `git diff 00db9d662..c03bdfb8f` only, which is fix `16e79acbf` (`--no-overwrite-ignore` on supervised alignment, plus the supervised `expected_global_id` lease guard) and evidence `c03bdfb8f` (`landing-safety/check.py`, `baseline-red.json`, stricter `followup.py` `published()`). The whole PR was not re-reviewed. The prior runtime approval stands in `gh1400-integrated-ef23-claude-review-status.md`.
Relay reviewed head: `c3309e4124f4`. It differs from `c03bdfb8f` only under `relay-system/`. `git diff --stat c03bdfb8f 9d13a0b9b` lists only the thread file.
Thread: `relay-system/2026-11-16/gh1491-landing-safety-claude-review.md`. Turn commit `ca45db414`. Attestation commit `9d13a0b9b`.

VERDICT: PASS
Basis: All four supervised alignment git paths refuse on an ignored-file collision, and the reviewer's scratch probe on git 2.50.1 shows each exiting 1 with the file preserved, against a no-flag control that overwrites. The stale or held lease check runs inside the same `BEGIN IMMEDIATE` transaction and exits before any UPDATE or receipt is written. Non-supervised callers pass `None` and behave as before. The evidence claims match what `check.py` and `baseline-red.json` compute. Two Nits do not block.
Reviewer-approved: yes. STATUS: Approved, set by the `--reviewer claude` turn and attested by the driver.

## Route and attestation

- Route: the shipped relay-xyz harness on the same provider: `relay-drive.sh --reviewer claude --review-once --round-cap 1 --agent-cmd relay-automation/claude-turn.sh`, with `CLAUDE_AGENT=claude` and `ALLOW_PATHS=""`, so only the relay file could be written.
- Auth: `CLAUDE_AUTH_MODE=subscription`. No API key or provider override was used, and there was no API fallback.
- Environment isolation: `env -i`, passing only HOME, USER, LOGNAME, SHELL, PATH, TMPDIR, LANG and TERM. The turn ran in the harness's temporary worktree (`isolated: true`).
- Model: `CLAUDE_MODEL=opus` resolved to `claude-opus-5-5`, with `CLAUDE_REASONING_EFFORT=high`. Ceilings were 60 turns, $10 and 1800 s. Actual use was 20 turns and 209 s, with a $1.21 API-price estimate under the subscription. The transcript shows `subtype: success`, `is_error: false`.
- Token: seeded before the driver ran, with `tick log task.created`, `claim --agent claude-a`, then `release --to claude`.
- Driver: exit 0, review-once approved. Log at `/private/tmp/claude-501/gh1491/drive.log`, transcript at `/private/tmp/claude-501/gh1491/claude-turn.log`. The first launch exited 2 at preflight (`artifact path not found in worktree: baseline-red.json`) before any dispatch, because the Setup line used a bare backticked basename. The token stayed with `claude`, no review round was used, and the line was corrected in `f1490d9eb` and `c3309e412`.
- Attestation: `.git/relay-attest/RELAY-gh1491-landing-safety-claude-review.json` (schema `relay-drive/attest@1`, reviewer `claude`, status Approved, reviewed head `c3309e412`, added-sha256 `c3c382cb…7653`, `gate_run: undeclared`).
- Validator: `relay_attest.load(task, expected_reviewer='claude', relay_file, target_repo)` returned the record with refusal `None`. `relay_attest.candidate_ok(record, sha, root)` returned `(True, None)` for `c3309e412` and `9d13a0b9b`. For `c03bdfb8f` it returned `(False, 'reviewed head … is not an ancestor')`, which is expected because the evidence commits sit on top of it.
- Budget: one review round used out of this follow-up's maximum of 3. The earlier integration and conflict budgets (2/2 conflict used) were not touched or reset.

## Findings for parent disposition

- [Pass] Q1 to Q6: alignment refusal on every supervised switch/merge path; lease check inside the same transaction and no receipt on refusal; clean stop after a stale refusal (outer `_cleanup()` releases the lock, and the next wake recovers through `checkpoint.begin`); retry (≈1111) and checkpoint-recovery (≈2435) callers unchanged; `check.py` counts `SystemExit` as a refusal; no scope creep.
- [Nit] The landing-safety fixture covers only the "local development exists, not ahead" path (`jog_run.py:2571`). The ff-merge and `switch -c` paths are shown only by the reviewer's scratch probe. Optional: add a fixture variant with local development behind the remote.
- [Nit] Pre-existing, outside this delta: the non-supervised checkpoint path `jog_run.py:2849` runs `switch development` without `--no-overwrite-ignore`, and its dirty guard does not see ignored files. DoD (c) requires non-supervised behaviour to stay unchanged, so this is a follow-up candidate only. No failure was observed.
- [Unverified, needs clone run] Whether every `published(r)` check still passes at `c03bdfb8f` under the stricter predicate. The rerun of the 23 controls already in progress covers this.

## Process incident (self-reported by the reviewer, checked by the parent)

The reviewer's first probe hit a sandbox block on `git init` and ran in the shared clone instead. It renamed local `development` to `keep`, created and checked out a new `development`, then reversed all of it within the turn. Parent check after the run: `refs/heads/development` = `be0a37520` (its value at clone time, per the reflog), no `keep` branch, `branch.development.{remote,merge}` unchanged, current branch `feat/XYZ-forge-gh1400-supervision-composition-2026-11-15`, one worktree, clean status. Only reflog entries remain. No commit, push or file change came from it.

## Scope limits

- `swept file: no`. The reviewer read `check.py` and `baseline-red.json` in full. In `jog_run.py` and `releases_app.py` it read only the touched functions, every `jog_acquire_lease` caller, `refuse`/`perform_write`/`_git`, and the cleanup path.
- Static review plus non-mutating git probes in scratch space. No suites or tests ran. The green result at `/private/tmp/gh1491-landing-safety-green/result.json` was graded against what `check.py` computes, not opened by the reviewer.

## Parent action

Wait for the 23-control rerun in progress to finish green at `c03bdfb8f`, then decide on the two Nits and land. This record authorizes no push, merge or full gate.
