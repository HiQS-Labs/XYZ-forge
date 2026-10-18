---
gh_issue: 1159
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1159
title: "merge-cleanup: per-repo qualification setting in .merge-cleanup.json — Forge keeps #1131 promotion-only cadence; vendored repos stop getting Forge-only sweep commands"
status: Proposed (1-INBOX — plan QA pending)
created: 2026-10-18
updated: 2026-10-18
owner: noelsaw1
goal: "Batch sweep inputs follow a per-repo `qualification` key read by the existing .merge-cleanup.json resolver; Forge's committed key keeps today's output, and a repo without it never sees a Forge-only command."
doc_type: feedback
effort: 2
complexity: 2
risk: 2
phases: 1
related:
  - "#1127 / #1131 — promotion-only full suite (the cadence being made explicit)"
  - "#1019 — .merge-cleanup.json resolver (extended, not duplicated)"
  - "#1064 — batch record (finalize_sweep_inputs / script_block)"
  - "#1158, #1076 — batching and merge-group checkpoint (non-goals here)"
---

# GH-1159: per-repo qualification setting

## Status

| What was just completed | What's next |
|---|---|
| Intake, recon and plan written at base `9a61625f`; rated 50/45/50/75. | Plan QA. Codex is not installed in this cloud session, so the operator decides how review runs. |

## Intake notes

- Base: `origin/development` @ `9a61625f`. Prior-art scan: no open PR; #1019 matched (the resolver
  this extends, not a fix).
- Isolation: a cloud container whose checkout is a fresh clone, on the session's designated branch
  `claude/peaceful-gates-1b06pd`. The session's harness pins this branch, so the start-task
  formula's sibling clone and `feat/` branch name are not used.

## Recon (at `9a61625f`)

- Resolver: `resolve_merge_policy()` (`skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:163`)
  reads `<primary>/.merge-cleanup.json`, allows only `preserve_commit_history`, and fails closed on
  unknown keys or bad types. Called at `:210`, `:1106`, `:1133`, `:1571`. `--show-merge-policy`
  prints the returned dict.
- Sweep writer: `batch_record.finalize_sweep_inputs()` (`batch_record.py:431`) runs the Forge
  classifier `_gate()` (`:412`). Anything except `--subsystem small` sets `deferred` and the
  command to `gh workflow run wave-reconcile.yml --ref <integration>  # full registry, …(#1131)…`.
  The one caller is `merge_cleanup.py:1093` (end of a landing run).
- Renderer: `batch_record.script_block()` (`:304`) prints `Gate`, then the deferred or run-it line.
- In a foreign repo the classifier cannot find `utils/ci-route.sh`, so it returns the full gate,
  which defers the sweep and prints the Forge workflow command. This is the failure in the issue.
- Existing test touchpoint: `test/gh436-merge-cleanup.py:1013` `test_emitted_sweep_command_parses`
  calls `finalize_sweep_inputs(rec, Path("/tmp"), "ex/ample")` with no policy and checks that the
  command parses under `bash -n`.
- Vendor notes: `relay-automation/xyz-vendor.sh:512-514` (`note …`).

## Plan

**Outcome sought:** a batch issue in any repo prints only the qualification command that repo
declared. Forge's output does not change.
**Smallest bet:** one optional key on the existing resolver, passed to the existing sweep writer.
**Alternatives rejected:** auto-detecting a repo's CI from file presence (the issue rules it out,
and it is how the bug arises); a new config file or env var (it would be a second resolver).
**Rollback:** revert the commit. The key is optional, and old batch records render the same.

Key shape (validated in `resolve_merge_policy`, fail closed):

```json
"qualification": {"full_suite": "promotion|per_batch|none", "sweep_command": "<string, optional>"}
```

- It must be an object. Its keys must be a subset of `{full_suite, sweep_command}`, and
  `full_suite` is required and must be one of the three values. `sweep_command` must be a
  non-empty string, and it is refused with `none`.
- The resolver returns `policy["qualification"]`: the object, or `None` when the key is absent.

Sweep behavior (`finalize_sweep_inputs(rec, primary, origin, qualification=None)`):

| Setting | Classifier | Command | Rendered |
|---|---|---|---|
| `promotion` | runs (today's path) | Small: throwaway-clone `bash <gate>` (today). Otherwise `deferred`, `<sweep_command>  # full registry, hosted, once before promotion (#1131); no local full rerun` | Today's lines |
| `per_batch` | not run | throwaway clone `&& <sweep_command>` | "Run it in a throwaway clone" |
| `none` | not run | none | "This repo declares no full suite (`qualification.full_suite: none`)…" |
| absent, or no `sweep_command` | not run (absent) | none | "No sweep command declared for this repo…" |

Forge commits `{"full_suite": "promotion", "sweep_command": "gh workflow run wave-reconcile.yml --ref development"}`.
This reproduces today's deferred command byte for byte, because Forge's integration branch is
`development`. The command is printed verbatim, with no `{integration}` templating.

**Non-goals:** no change to `ci.yml`, `wave-reconcile.yml` or AGENTS.md. No CI auto-detection. No
writes into vendored repos. No change to verdict recording or `qa_pending`: the operator still
records a verdict. No `MERGE_CLEANUP_USE_HOSTED` change.

**Ordered implementation, with verification inline:**

1. `merge_cleanup.py`: validate and return `qualification` in `resolve_merge_policy`. Pass
   `policy["qualification"]` at `:1093`; this reads the policy once there, under the same
   fail-closed handling as at `:1106`.
2. `batch_record.py`: branch `finalize_sweep_inputs` on the setting, and teach `script_block` the
   "none" and "no command" lines. Keep the `gate`/`deferred`/`command` keys so old records render
   unchanged.
3. `.merge-cleanup.json`: add Forge's key.
4. `skills/2-daily/merge-cleanup/SKILL.md` "Project merge policy": one short paragraph.
   `xyz-vendor.sh`: one `note` line.
5. Verify: `bash test/gh436-merge-cleanup.sh` (existing; `test_emitted_sweep_command_parses` still
   passes with the absent-key path). Then the routed gate for the changed paths.

**Tests (GH-831, no new tests):** no new cases without the operator's per-case approval. Proposed
for approval: (a) a foreign-shaped repo with no key never emits `wave-reconcile.yml`; (b) Forge's
key reproduces today's command byte for byte; (c) an unknown `full_suite` fails closed. Until
then these are recorded as manual checks under `TESTS-RESULTS/2026-10-18+GH-1159/`.
**Red control:** with Forge's key removed, the deferred command disappears from the sweep inputs.

## Rating (2026-10-18)

`rated 50/45/50/75` (pri/sev/appeal/effort).

- **sev 45:** in a vendored repo, a batch of 2+ PRs exits 4 and points at a command that cannot
  run there. The operator can still record a verdict by hand, so no data is lost and work is not
  blocked.
- **pri 50:** requested today by the operator, with no deadline.
- **appeal 50:** neutral; no score was supplied.
- **effort 75:** about 60 lines across 2 scripts, 1 config file and 2 docs.
- **Recurrence (2026-10-04..18 vs 2026-09-20..10-04):** no separate incident reports. The defect
  was found by recon, not by a field report, so the trend is unknown.
