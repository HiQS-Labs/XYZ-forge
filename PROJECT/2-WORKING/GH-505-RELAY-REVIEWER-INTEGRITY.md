---
title: "GH-505 / GH-509: Approved means a reviewer approved — driver-attested terminal status"
status: In progress
created: 2026-09-08
updated: 2026-09-08
owner: agent-b
goal: relay-drive is the only process that can make STATUS Approved count — it knows the roles from its own invocation, attests only an approval it watched a reviewer-role turn write, records the revision the reviewer actually read and a digest of what the reviewer added, and every consumer (jog, marathon recovery, jog's merge) validates that record instead of trusting the word in the file
gh_issue: 505
source: https://github.com/HiQS-Labs/XYZ-forge/issues/505
branch: fix/gh505-relay-reviewer-integrity
base_sha: a6441b9b
doc_type: defect
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/509
  - https://github.com/HiQS-Labs/XYZ-forge/issues/510
  - https://github.com/HiQS-Labs/XYZ-forge/issues/482
context_tags: [relay, review-integrity, governance, merge-gate]
non_goals:
  - Cryptographic signing, key management, or authenticating tick events (#509 option 3 — key isolation is not achievable on one host where agy runs unsandboxed)
  - Running the reviewer in a container or read-only checkout (#509 option 4)
  - Quorum review (#509 option 5)
  - Defending against arbitrary same-user host code outside the dispatch/containment contract (agy-turn.sh runs unsandboxed; anything it can write, a hostile agy turn can write)
  - Scoring review quality or prescribing a verdict vocabulary — the attestation proves the designated reviewer added review text, nothing more
  - Bridging relay-reviewer identity to GitHub-reviewer identity; branch protection; a second PR reviewer (operator-excluded)
  - Binding the merge in express.py, merge_cleanup.py and marathon-closeout.sh — none of them owns a relay task name to resolve an attestation by; recorded as a limitation, not silently skipped
  - Changing the relay turn protocol, token model, or round-cap semantics
effort: 40
complexity: 4
risk: 4
phases: 4
reversibility: Costly
---

# GH-505 / GH-509 — driver-attested approval

## Status

| What was just completed | What's next |
|---|---|
| Design v2 QA round 1 (Codex): Block with B1 (digest boundary), B2 (attested head ≠ merge candidate), B3 (mirror validation), F1–F3. All six accepted; plan revised below — every disposition in [Round 1 dispositions](#round-1-dispositions) | Round 2 review of this revision |

## Issue map

| Issue | Scope in this PR | Acceptance |
|---|---|---|
| [#505](https://github.com/HiQS-Labs/XYZ-forge/issues/505) | Phases 0, 2, and the consumer wiring in 3 | builder-written `STATUS: Approved` is refused, reverted and committed as reverted; the shared prompt no longer tells a builder to approve; jog no longer overrides the driver |
| [#509](https://github.com/HiQS-Labs/XYZ-forge/issues/509) | Phase 1 (the anchor + the record) and Phase 3 (consumers validate the record) | a terminal status counts only when this driver run watched a reviewer-role turn add review text; the record names the reviewed revision and the digest of the review body; marathon recovery and jog's merge validate the record against the file and the candidate |
| [#510](https://github.com/HiQS-Labs/XYZ-forge/issues/510) | folded into Phase 3 — the merge-candidate check rewrites the exact lines (round-1 Q7: fold accepted) | a refused merge parks; a missing PR parks |

Ratings: #505 `85/85/50/55`, #509 `75/85/50/25` (kept provisional at 25 per round 1 — identity, commit ordering, recovery and integration tests dominate, not line count), #510 `70/70/50/90`. Persisted in the ledger; rationale in each issue's inbox doc / issue body.

**Reversibility: Costly.** This changes the approval contract every driven relay in this repo and every vendored `.xyz/` copy runs under. A revert is one PR, but a week of relays approved under the new contract cannot be re-run under the old one. Debugging protocol during implementation: `/debug-mantra`.

## Trust boundary, stated once

The driver (`utils/py/relay_drive.py`) is the only process in a relay that the party under review does not run. Everything the driver *knows from its own invocation and observation* is trusted; everything it *reads back from a file a turn can write* is evidence to validate, never authority. The one durable record this plan adds lives under `.git/`, which a worktree-isolated Codex turn cannot reach and containment never copies back; an unsandboxed agy turn can write there, and that is the stated non-goal. **The driver's own exit code never depends on that record — only on memory.** Consumers that read it validate it against the relay file and the candidate revision (Phase 3) rather than trusting its existence.

## The design

1. **Roles from the invocation.** `relay_drive.py` learns `--reviewer` (required) and `--builder` (optional) from its arguments, refuses equality at startup, and never derives a role from the relay file or the token. Each dispatched turn is reviewer-role iff `actor == args.reviewer`; every other actor is builder-role (unknown actors cannot approve — safe direction).
2. **Containment reads the driver.** `RELAY_ROLE` is exported per turn and is the first tier of `rtl_is_reviewer_turn`.
3. **The driver judges the turn it watched.** Pre-turn it snapshots the relay file's *review body* (everything below the header block), `STATUS:`, and the target repo's HEAD — `reviewed_head`, the revision the isolated worktree was cut from. Post-turn, on a successful shim return with the token done: a terminal `STATUS:` after a builder-role turn is reverted, committed as reverted, and escalated `forged-terminal`; after a reviewer-role turn it is accepted only if the body is an append-only extension of the pre-turn body with non-whitespace new text (`review-body-rewritten` / `empty-approval` otherwise).
4. **One attestation record, one writer, one validated reader.** On acceptance the driver appends an `### Attestation · relay-drive` block to the relay file, commits it file-scoped (checked), and atomically publishes `<git-common-dir>/relay-attest/<task>.json` (`relay-drive/attest@1`). `utils/py/relay_attest.py` is the single writer + resolver + validating reader; marathon and jog import it.
5. **Reviewed revision vs merge candidate.** The record carries `reviewed_head` (pre-dispatch HEAD). The permitted transition to a merge candidate is: every commit from `reviewed_head` to the candidate touches only transcript paths (the relay file, `relay-system/`, `.relay-scratch/`). Consumers enforce that with `git diff --quiet <reviewed_head> <candidate> -- . ':(exclude)relay-system' ':(exclude)<relay_file>'` and then merge with `--match-head-commit <candidate>` so the checked SHA and the merged SHA are the same object. Any code drift — a concurrent parent commit during the turn, a post-approve command that touched source, a push after the check — refuses.

## Implementation

### Phase 0 — delete the jog override (#505)

`utils/py/jog_run.py:1375-1389` → `return proc.returncode`.

Check **J**: `run_single_phase_drive` with a stub `relay-drive.sh` that exits 4 and a relay file reading `STATUS: Approved` returns 4. Red at base (returns 0).

### Phase 1 — driver-attested terminal status (#509)

`utils/py/relay_drive.py` (canonical; `relay-drive.sh:18` is an `exec` shim, gh308 guard untouched).

**Args and precedence (F1).** `--reviewer AGENT` required for any run that may accept a terminal status; `--builder AGENT` optional. Startup refusals (exit 2, before any tick mutation, matching `marathon_drive.py:1940-1942`): `--reviewer` missing; `--builder == --reviewer`. `--review-once` keeps its meaning (one turn, no cap) and does **not** redefine the reviewer: the dispatched actor must equal `--reviewer`, else exit 2 `review-once-actor-mismatch` before dispatch. `--dry-run` is exempt from the reviewer requirement (it dispatches nothing).

**Per-turn snapshot** (beside `rfsig` at `:611-614`): `pre_status = s`; `pre_body = review_body(relay_file)`; `reviewed_head = head_before` (already captured). `review_body()` = file bytes after the header block, where the header block is the leading `---`…`---` frontmatter when present, else the leading run of `KEY:` lines; the driver's own `### Attestation · relay-drive` trailer, when present, is excluded from the body so a re-read after attestation compares equal. Role: `role = "reviewer" if actor == args.reviewer else "builder"`; `os.environ["RELAY_ROLE"] = role`.

**Post-turn judgement**, one function `judge_terminal(ns)` called at the current post-turn read (`:820-823`) **and** on the nonzero-shim exit path (`:711-712`, F3) — the latter only ever reverts, never attests, and still exits with the shim's code:
- `not terminal_status(ns)` → return.
- builder-role → rewrite the first `STATUS:` line to `pre_status`; append `### System · relay-drive — <ts>\nterminal STATUS written by builder-role turn (<actor>) — reverted`; file-scoped commit `relay-drive: revert forged terminal (<task>, <actor>)` with the return code checked (a failed commit is its own escalation `revert-commit-failed`); stderr line with the reason; `exit_escalate("forged-terminal")`.
- reviewer-role: `post_body = review_body(relay_file)`. `not post_body.startswith(pre_body)` → `review-body-rewritten`. `post_body[len(pre_body):].strip() == ""` → `empty-approval`. Otherwise `added = post_body[len(pre_body):]`, `digest = sha256(added)`.
- Publication gate (B3): attest only when the shim returned 0, containment passed (implied by 0), the body check passed, **and** `token_state()` reads `done` for `args.relay_task`. A live token → `close-mismatch` exactly as the loop top does today; the check moves *before* publication so review-once (`:830-834`) gets it too.
- Attest: append the block below; file-scoped commit `relay-drive: attest <task> approved by <actor> (reviewed <reviewed_head[:12]>)`, checked; `relay_attest.write(...)` (temp file + `os.replace`); `attested = record` in memory.

```
### Attestation · relay-drive — <utc ts>
task: <relay_task>
reviewer: <actor>
status: <ns>
reviewed-head: <reviewed_head>
review-body-sha256: <digest>
```

**Terminal exits.** Loop top (`:571-579`), review-once (`:830-834`), post-loop (`:868-871`): success requires `attested`; a terminal word without it → `unattested-terminal` (exit 4), stderr + scratch. A file that is already terminal at startup is therefore refused (covers "forged before startup").

**Record** (`relay-drive/attest@1`, written by `relay_attest.write`, read by `relay_attest.load` which validates or returns `None` with a reason):
`schema, task, relay_file (repo-relative), target_repo (abs path), reviewer, status, reviewed_head, review_body_sha256, attested_at, driver_pid`. `load(task, relay_file, target_repo)` refuses: missing/malformed/truncated JSON; `task`/`relay_file`/`target_repo` mismatch; non-terminal `status`; `sha256(review_body(relay_file) tail)` ≠ recorded — the reader recomputes the digest of the body *after* the block boundary named by the attestation trailer's position, so a rewritten review or a record for a different file fails. Retry task identities (`-<n>`) are distinct records by construction. Stale records are never deleted — they fail the candidate check in Phase 3 rather than being trusted.

Checks (`test/gh505-relay-attest.sh`; fixture harness clone as in `test/gh376-relay-drive-lock-parity.sh`; stub `--agent-cmd` scripts append to the relay file, move the token, and record that they ran):
- **A** builder-role turn writes `STATUS: Approved` + `tick done` → exit 4, `.relay-scratch/escalation-reason` = `forged-terminal`, `STATUS:` restored on disk **and in HEAD** (revert commit present), no attestation block, no record. **Red control:** base-SHA driver invoked *without* the new flags (base rejects unknown args at `:55-56`) exits 0.
- **A2** same as A but the stub exits 6 (containment failure) → driver exits 6, `STATUS:` reverted and committed, no record.
- **B** reviewer-role turn appends findings + `STATUS: Approved` + done → exit 0; attestation block present; `reviewed-head` = fixture HEAD *before* dispatch (assert it is the parent of the shim's commit, not the shim's commit); `review-body-sha256` = independently computed sha256 of exactly the appended bytes; record loads and validates. Positive control, not a red control.
- **B2** reviewer turn also edits `NEXT:`/`ROUND:` and shortens the header → still attested, digest still equals the appended body bytes only.
- **C** file already `STATUS: Approved`, token done, no turn → exit 4 `unattested-terminal`. Red control: base (no flags) exits 0 after 0 turns.
- **D1** reviewer turn changes only `STATUS:` (four-byte growth) → `empty-approval`. **D2** appends whitespace only → `empty-approval`. **D3** rewrites an earlier body paragraph and appends → `review-body-rewritten`.
- **E** `--review-once --reviewer codex` with the token handed to `agy` → exit 2 before dispatch; the stub records it did not run.
- **E2** `--reviewer` omitted → exit 2 before any tick mutation.
- **K** reviewer turn leaves the token claimed → `close-mismatch`, no record.

### Phase 2 — containment reads the driver; the prompt stops inviting builders to approve (#505; B1 of the prior thread)

`relay-automation/relay-turn-lib.sh` (only copy — `utils/py/rtl.py:667-696` sources it and preserves the env).

1. `rtl_is_reviewer_turn` (`:63`): first tier `case "${RELAY_ROLE:-}" in reviewer) return 0;; builder) return 1;; esac`. Directive and `NEXT:` tiers remain for hand-run turns. **Stated limit:** a hand-run turn with no driver still trusts editable directive/`NEXT:` bytes, and a stale `RELAY_ROLE=builder` inherited by a hand-run reviewer narrows nothing but a stale `reviewer` would widen — so the shims **unset `RELAY_ROLE` unless `RELAY_DRIVER_LOCKED=1`** (the driver's own marker), making the tier reachable only under a driver.
2. Shared prompt (`:1011`): remove `(or done + set STATUS: Approved when approving)`; add ` When approving, hand the token off with done and set STATUS: Approved.` to the reviewer `role_note` (`:994-998`).

Checks:
- **F** through the `rtl.py` bridge, `RELAY_ROLE=reviewer` + a directive naming the agent as *builder* → reviewer allowlist (relay file only); `RELAY_ROLE=builder` + directive naming it *reviewer* → builder allowlist. Red control: base follows the directive both ways.
- **F2** `RELAY_ROLE=reviewer` with `RELAY_DRIVER_LOCKED` unset → tier ignored (directive decides).
- **G** rendered prompts are non-empty; builder prompt lacks `STATUS: Approved`; reviewer prompt contains it.

### Phase 3 — consumers validate the record (#509, #505, #510; B2 of the prior thread)

**`utils/py/relay_attest.py`** (new, ~60 lines): `write`, `load`, `candidate_ok(record, candidate_sha, repo)` implementing the transition rule in design point 5, `path_for(task, repo)` via `git rev-parse --git-common-dir`.

**`utils/py/marathon_drive.py`**
1. `cmd2` (`:3144-3149`): `"--reviewer", args.reviewer, "--builder", args.builder`.
2. After a relay-drive exit 0, `complete_phase_success()` loads the record for the phase's task and copies `reviewed_head` and `review_body_sha256` into `marathon-drive/result@1` (`:250-256`) as `reviewed_head`, `review_body_sha256`. `head_sha` keeps its meaning (receipt-time HEAD) — it is no longer described as reviewed.
3. `satisfied_lane_terminal()` (`:2677-2698`), exit-3 probe (`:3218-3222`), exit-7 probe (`:3294-3298`): `terminal_status(s) and not actor` additionally requires `relay_attest.load(task, relay_file, root)` **and** `candidate_ok(record, HEAD)`. Refusals are logged with the reader's reason, never absorbed.

**`utils/py/jog_run.py`**
4. `run_single_phase_drive(root, gh_num, builder, reviewer, simulate)`: refuse a missing reviewer and `reviewer == builder` with the messages `validate_marathon_executor` already uses (`:189-196`); dispatch via `relay-automation/marathon-agent.sh` with `MARATHON_BUILDER/REVIEWER` and both `<AGENT>_AGENT` vars; pass `--reviewer`/`--builder`. Caller `:1665` threads `args.reviewer`.
5. `handle_landing_boundary` (`:1410-1471`): one `_merge_reviewed_pr(root, pr_num, record)` used by both branches: read the PR head SHA (`gh pr view --json headRefOid`), `candidate_ok(record, head)` else park `candidate-drifted-from-reviewed-head`, then `gh pr merge <n> --merge --auto=false --match-head-commit <head>` with output captured; non-zero → park with stderr (#510). No PR found → park (#510). The existing state/base checks (`:1393-1407`) stay. Record resolved by `RELAY-gh{N}-jog-drive`.
6. Marathon-executor landing (`:426-435`): `candidate_ok` against `receipt["reviewed_head"]` (park when absent — a receipt without it came from an unattested run), then `--match-head-commit <PR head>`.

Checks:
- **H1** marathon startup with a relay file already terminal + token done + no record → `satisfied_lane_terminal()` refuses, phase renders and dispatches (stub records it ran). **H2** exit-3 recovery: artifact present, gate passes, stub relay exits 3 after writing terminal + done, no record → **process** exit 3 `no-progress`; with a valid record and clean candidate → 0. **H3** exit-7 recovery, record present but candidate has a code commit after `reviewed_head` → process exit 7. Red control for H1/H2: base exits 0.
- **I1** jog interactive branch (stdin `y`), stub `gh` serving `pr list`/`pr view`, record present, candidate == reviewed → `pr merge` argv carries `--match-head-commit <head>` and the stub confirms it was reached. **I2** stub `pr merge` exits 1 → `(False, "parked", ...)`. **I3** `pr list` empty → parked. **I4** candidate has a non-transcript commit after `reviewed_head` → parked before merge, stub confirms merge not reached. **I5** auto-merge branch, same four. Red control for I2/I3: base returns `(True, "completed", None)`.
- **J** Phase 0.

Evidence: each red control is recorded in `test/baselines/GH-505-negative-control.md` with the exact base invocation and observed output; the disposable-clone gate run's `provenance.jsonl` is committed in this PR.

### Migration (F1)

`skills/relay-xyz/SKILL.md:324-328, 345-349, 366-370` and `relay-automation/README.md:229-230` recipes gain `--reviewer "$AGENT"` (they are single-reviewer runs, so the reviewer is the worker they name). `relay-drive.sh:32` header comment updated.

## Round 1 dispositions

| # | Verdict | Disposition |
|---|---|---|
| B1 | Accept | Body-not-size: `review_body()` strips the header block and the driver's trailer; append-only check; non-whitespace requirement; digest of exactly the added bytes. D1–D3, B2 added. |
| B2 | Accept | `reviewed_head` = pre-dispatch HEAD; explicit transition rule (transcript-only commits); `candidate_ok` at every consumer; `--match-head-commit` binds check to merge; receipt gains `reviewed_head`, `head_sha` no longer described as reviewed. H3, I4 added. |
| B3 | Accept | One record schema, one writer/reader module, validated load (task/file/repo/status/digest), atomic publish, publication only after shim 0 + body check + done token; stale records fail `candidate_ok` rather than being deleted. K added. |
| F1 | Accept | `--reviewer` required, `--builder` optional, equality refusal, review-once actor mismatch refusal, refuse before any tick mutation; recipes and README migrated; jog keeps its same-agent rejection. E/E2 added. |
| F2 | Accept | Base controls invoked without the new flags; H split into startup/exit-3/exit-7 with the process exit asserted; I gets stdin, PR view, and reached-merge assertions; B/E labelled positive controls; baseline doc + committed provenance named. |
| F3 | Accept | Revert is committed (checked); nonzero-shim path judged for revert only; stderr reason on every refusal. |
| Q1 limit | Accept | `RELAY_ROLE` reachable only under `RELAY_DRIVER_LOCKED=1`; hand-run limit stated. F2 check added. |
| Reversibility | Accept | Costly, stated; debug-mantra named. |
| #509 effort | Accept | Stays 25, provisional. |

## Dependencies and ordering

0 → 1 → 2 → 3, one PR. Phase 3 without Phase 1 breaks marathon (no record is ever written).

## Risks and rollback

- Every driven relay in this repo and in vendored `.xyz/` copies now needs `--reviewer`; missing it refuses at startup with a one-line reason. Callers migrated in this PR: marathon, jog (both executors), relay-xyz recipes, README.
- Two driver commits per approval/forgery on tracked relay files (shim's + driver's). Gitignored relay files get the record only.
- Rollback: revert the PR; `.git/relay-attest/` is inert.
- Tripwire, first week: any `forged-terminal`, `unattested-terminal`, `candidate-drifted-from-reviewed-head` on stderr or in scratch is a real forgery, real drift, or a caller I missed.

## Verification

- `test/gh505-relay-attest.sh` A–K, H1–H3, I1–I5, J, in a disposable full clone.
- Full gate (`validate.sh`) in that clone; `provenance.jsonl` committed.
- Codex final QA on the committed implementation.
