---
title: "GH-681: relay Reviewer may measure read-only; generalizations carry a falsifier"
status: Complete
created: 2026-09-17
updated: 2026-09-18
owner: operator (via fresh-clone PR lane; /express refused — shared-runtime)
gh_issue: 681
source: https://github.com/HiQS-Labs/XYZ-forge/issues/681
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
branch: fix/gh681-reviewer-probe-rules
goal: >
  A headless relay Reviewer may run narrow, non-mutating probes against the seeded artifact
  (scratch-only output, test suites stay out of the worktree) and receives exactly one
  role-consistent verification instruction; a finding that asks for a behaviour change must carry
  Observed input / Affected scope / Falsifier before the Producer implements it.
---

# GH-681 — relay Reviewer may measure read-only; generalizations carry a falsifier

## Status

| What was just completed | What's next |
|---|---|
| Two consult rounds (Codex + agy; Codex Astra high + Fable high), plan v2 recorded on #681. S1–S6 implemented on `fix/gh681-reviewer-probe-rules`; `test/gh681-reviewer-probe-rules.sh` registered in `validate.sh`. `/express` refused as designed (`shared-runtime`: `relay-turn-lib.sh`), so this rides the fresh-clone PR lane. | Disposable-clone runs of the suite, its four red controls, `gh397`, `gh505`, `gh308`, then `validate.sh`; receipts to `TESTS-RESULTS/2026-09-17+GH-681/`; PR `Closes #681`; after merge, re-vendor `relay-xyz` via skills-army-hq; post-merge smoke relay recorded on #681. Follow-up: #682 (harness-set env for reviewer probe turns). |

## Diagnosis

`relay-system/2026-09-17/gh673-final-qa.md` ran three Reviewer/Producer rounds and escalated without approval while carrying a design it had itself requested. Round 1's Reviewer, forbidden to execute anything (`relay-turn-lib.sh` reviewer note: "do NOT edit, create, or run any artifact or source file"), generalized one late-error observation (`connectors.py:92-93`) into "or a later invalid identity"; the Producer implemented it; the same seat `[Pass]`ed it in Round 2. One historical `NULL`-URL ledger row (GH-135, 1 of 202) then blanks every issue. The defect was a row count nobody was allowed to run. Two harness properties allowed it: the Reviewer could not measure, and a Reviewer-authored generalization carried no falsifier and was self-certified (the GH-268 sweep and GH-173 citation rules guard observations, not requests).

## Change

- **S1** `relay-automation/relay-turn-lib.sh` `rtl_turn_prompt`: the shared "verify ONLY with the specific test for the file(s) you changed" clause becomes a role-conditional `verify_note` (Producer keeps it verbatim); the Reviewer note allows narrow, non-mutating probes with output under `.relay-scratch/` or `$TMPDIR` (`export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"` — `-B` does not reach child interpreters and `_rtl_sig` hashes `.relay-artifacts/` with `find`), requires the evidence be quoted in the finding (scratch is discarded), keeps `validate.sh`/`test/*.sh`/pytest/fixtures out of the worktree (`AGENTS.md`), grades suite-only claims `[Unverified — needs clone run]`, and keeps the `gh397`/`gh505`-asserted sentences verbatim. Containment (`rtl_enforce`, `rtl_worktree_end`, allowlist scoping, GH-173 rewrite) untouched.
- **S2** `relay-automation/new-relay.sh`: Reviewer bullet — a behaviour-change request is a generalization unless the concrete failing input can be pasted; `[Blocker]`/`[Should]` requesting a change carry `Observed input:` / `Affected scope:` / `Falsifier:`; a `[Blocker]` cites an observed failure; protocol rule, not mechanical. Producer bullet — `Declined — unproven generalization`.
- **S2b** `utils/py/marathon_drive.py` reviewer brief: step `4c` with the same rule (the marathon brief already allowed `$TMPDIR` probes since GH-441, so S1's diagnosis was relay-drive-specific).
- **S2c** `skills/relay/SKILL.md`: the generic template's Reviewer bullet carries the rule (a supported scaffolding path per `relay-xyz`).
- **S3** `skills/relay-xyz/SKILL.md`: Reviewers standard items 5–6 (probe allowance/limits; generalization rule), naming the harness strings as canonical. This is the skill deployed on devices.
- **S4** `relay-automation/README.md`: `relay-turn-lib.sh` row notes the probe allowance, the `.relay-scratch/` exception to `AGENTS.md`'s `temp/` rule, that read-only execution is behavioural (relay Codex is `workspace-write`), and the residue gap → #682.
- **S5** `test/gh681-reviewer-probe-rules.sh` (registered): cases 1–6 pin wording (stated plainly: prose can only be pinned by text); case 7 is behavioural — a reviewer worktree writing under `.relay-scratch/` is not off-lane, one leaving `.pytest_cache/` is (the backstop the allowance relies on; deleting the `.relay-scratch` exemption passes 1–6 and fails 7).

## Acceptance Criteria

- [x] `bash test/gh681-reviewer-probe-rules.sh` green in a disposable full clone; red controls (revert S1 → cases 1–2 red; drop the closing sentence → case 1 red; revert S2 → case 4 red; delete the `.relay-scratch` exemption → case 7 red) witnessed with receipts.
- [x] `test/gh397-reviewer-turn-role.sh`, `test/gh505-relay-attest.sh` unchanged and green; `bash test/gh308-frozen-twin-guard.sh --check` clean (the lib is not a twin; no new `.sh` under `relay-automation/`; `marathon_drive.py` is the authoritative Python).
- [ ] `validate.sh` green in the disposable clone — 389/393; the four red suites (`gh425`, `gh-gen4`, `gh142`, `gh268`) fail identically on unmodified `development` there; disclosed in the PR body and `validate-full.log`.
- [x] `/express` refusal receipt kept (`shared-runtime`) — the lane decision is the driver's, not an opinion.
- [x] PR merged; `relay-xyz` re-vendored to `~/git-pulse-sync/Deployed Skills` from the landed source.
- [ ] Post-merge smoke: one driven relay whose Reviewer turn writes a probe into `.relay-scratch/` and is attested (shim exit 0), recorded on #681.

## Merge evidence

- PR [#683](https://github.com/HiQS-Labs/XYZ-forge/pull/683) squash-merged to `development` as `55d8ab47` on 2026-09-18T01:05Z; `Closes #681` fired (issue closed 01:05:20Z). Hosted CI on the bypassed push: blocking job green (macOS promotion job runs only on `main`; canary advisory).
- Receipts: `TESTS-RESULTS/2026-09-17+GH-681/` — `provenance.jsonl` (9 rows, log sha256s), focused suite 26/0, four red controls, `gh397` 11/0, `gh505` 63/0, GH-308 guard clean, `express-refusal.log`, `validate-full.log` (389/393; the red suites fail identically on unmodified `development` in that environment — baselined in the same disposable clone).
- Consults: `relay-system/2026-09-17/gh681-relay-dod-vote-155755/` (Codex + agy, A/B vote), `gh681-plan-qa-163853/` (Codex Astra high), `gh681-plan-qa-fable-164327/` (Fable high).
- `relay-xyz` re-vendored from `55d8ab47` into the Pulse collection (`rebalance-git-pulse` commit `e001ee00`); deployed copy byte-identical; `sync.py --apply` zero actions, read-through confirmed on all three enabled targets.
- Reconciled locally: the hosted `wave-reconcile.yml` lane had 0 successes since 2026-09-11 and was disabled 2026-09-18 pending [#684](https://github.com/HiQS-Labs/XYZ-forge/issues/684).

## Lessons Learned (For Future Agents)

- **A rule that forbids the reviewer from measuring forbids the one check that catches a bad generalization.** The gh673 defect was a count; three static rounds could not see it; one out-of-relay measurement did.
- **A reviewer-requested design change is a claim, not a finding.** GH-268 and GH-173 guard what the reviewer *observed*; nothing guarded what it *asked for*, and the same seat then certified its own request. Hence the three lines — and the trigger is "can you paste the failing input", not "is this a design change", because the latter is permeable (the gh673 request was phrased as a defect).
- **Check the whole rendered prompt, not the string you are editing.** The first draft of S1 dropped "hand the token off with done and set STATUS: Approved" — the sentence driver attestation keys on — and contradicted the shared "verify ONLY with the specific test" clause four lines below. Both consult rounds caught things the author's diff view could not.
- **`python3 -B` is not enough in a worktree.** It does not reach child interpreters, and the seeded artifact directory is hashed with `find(1)`, so ignored bytecode still flips its signature. Export the env; scope probes to non-mutating commands; keep suites in a disposable clone.
- **The marathon lane already had half of this (GH-441).** Recon that finds "exactly one edit point" for a string may still be missing a second *policy* in another driver. Both drivers now agree on scratch homes and carry the rule.
- **`/express` said no, mechanically, and that was correct**: `relay-turn-lib.sh` is the containment surface (`SHARED_RUNTIME`), AGENTS classes edits to it as at least Costly, and Costly work gets a reviewed PR. The refusal output is the receipt.
