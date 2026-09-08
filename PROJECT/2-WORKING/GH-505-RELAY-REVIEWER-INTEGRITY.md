---
title: "GH-505 / GH-509: Approved means a reviewer approved — driver-attested terminal status"
status: In progress
created: 2026-09-08
updated: 2026-09-08
owner: agent-b
goal: relay-drive is the only process that can make STATUS Approved count — it knows the roles from its own invocation, pins the revision the reviewer reads, attests only an approval it watched a reviewer-role turn write, records exactly which bytes the reviewer added, and every consumer (jog, marathon success and recovery, jog's merge) validates that record against the file, the expected reviewer, the done token and the merge candidate instead of trusting the word in the file
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
  - Merge binding for non-isolated turns (`RELAY_WORKTREE_ISOLATION=0`) — the reviewed input is not a pinned revision there; such records carry `isolated: false` and every merge consumer refuses them
  - Bridging relay-reviewer identity to GitHub-reviewer identity; branch protection; a second PR reviewer (operator-excluded)
  - Binding the merge in express.py, merge_cleanup.py and marathon-closeout.sh — none of them owns a relay task name to resolve an attestation by; recorded as a limitation, not silently skipped
  - Changing the relay turn protocol, token model, or round-cap semantics
effort: 4
complexity: 4
risk: 4
phases: 4
reversibility: Costly
---

# GH-505 / GH-509 — driver-attested approval

## Status

| What was just completed | What's next |
|---|---|
| **Implemented** on `fix/gh505-relay-reviewer-integrity` (operator chose option (b) after the 3-round plan-QA cap: implement on the adjudicated revision, final Codex QA as the check). Driver, containment, marathon, jog, shared record module, 50-case fixture with base-driver red controls, and 30 shipped suites re-pointed at the attestation. Deviations from the reviewed plan are listed in [Implementation dispositions](#implementation-dispositions) and in `test/baselines/GH-505-negative-control.md` | Full gate in the disposable clone → provenance under `TESTS-RESULTS/2026-09-08+GH-505/` → final Codex QA on the committed implementation → PR |

## Issue map

| Issue | Scope in this PR | Acceptance |
|---|---|---|
| [#505](https://github.com/HiQS-Labs/XYZ-forge/issues/505) | Phases 0, 2, consumer wiring in 3 | builder-written `STATUS: Approved` is refused, reverted and committed as reverted; the shared prompt no longer tells a builder to approve; jog no longer overrides the driver |
| [#509](https://github.com/HiQS-Labs/XYZ-forge/issues/509) | Phase 1 (anchor + record) and Phase 3 (consumers validate the record) | a terminal status counts only when this driver run watched a reviewer-role turn add review text to a pinned revision; the record names that revision and the exact added bytes; every consumer validates the record against the file, the expected reviewer, the done token and the candidate |
| [#510](https://github.com/HiQS-Labs/XYZ-forge/issues/510) | folded into Phase 3 (fold accepted, rounds 1–2 Q7) | a refused merge parks; a missing PR parks |

Ratings: #505 `85/85/50/55`, #509 `75/85/50/25` (provisional — rationale now in `GH-509-RELAY-TERMINAL-AUTHORIZATION.md`), #510 `70/70/50/90`. Persisted in the ledger.

**Reversibility: Costly.** This changes the approval contract every driven relay in this repo and every vendored `.xyz/` copy runs under; a revert is one PR, but relays approved under the new contract cannot be re-run under the old one. Implementation debugging protocol: `/debug-mantra`.

## Trust boundary, stated once

The driver (`utils/py/relay_drive.py`) is the only process in a relay that the party under review does not run. What the driver *knows from its own invocation and observation* is trusted; what it *reads back from a file a turn can write* is evidence to validate, never authority. The one durable record this plan adds lives under `<git-common-dir>/relay-attest/`, which a worktree-isolated Codex turn cannot reach and containment never copies back; an unsandboxed agy turn can write there — the stated non-goal. **The driver's own exit code never depends on that record — only on memory.** Consumers validate the record against the current file, the expected reviewer, the token and the candidate; existence proves nothing.

## The design

1. **Roles from the invocation.** `--reviewer AGENT` required, `--builder AGENT` optional; equality refused at startup; roles never derived from the file or the token. A dispatched turn is reviewer-role iff `actor == args.reviewer`; every other actor is builder-role.
2. **Containment reads the driver.** `RELAY_ROLE` is exported per dispatch and is the first tier of `rtl_is_reviewer_turn` — honoured only when `RELAY_DRIVER_LOCKED=1` is also set, decided inside the shared helper so the `rtl.py` bridge and every shim agree.
3. **The reviewed revision is pinned, not observed.** The driver captures `reviewed_head = HEAD` of the target repo before dispatch and exports `RELAY_REVIEWED_HEAD`; `rtl_worktree_begin` cuts the isolated worktree at that SHA (`git worktree add --detach <wt> "$RELAY_REVIEWED_HEAD"`) instead of live `HEAD`. A concurrent parent commit during the turn therefore cannot change what the reviewer read. Non-isolated turns cannot be pinned and are marked `isolated: false` in the record (no merge binding, by non-goal). A seeded `--artifact-file` is digested by the driver, exported as `RELAY_ARTIFACT_SHA256`, and **verified by `rtl_worktree_begin` after the copy** (`relay-turn-lib.sh:771-774`) — a mismatch fails the turn. Records with an artifact are transcript-only: `candidate_ok` refuses them, because nothing maps an external artifact onto the pinned target tree. Plan-QA relays still get an attestation; they never merge.
4. **The driver judges the turn it watched** on the *canonical* relay bytes — the file with its first `STATUS:`, `NEXT:` and `ROUND:` lines reduced to their bare keys, so permitted header edits never disturb the body comparison, whatever the file's leading format (title-first as marathon and jog emit, frontmatter, or bare `KEY:` lines). After a builder-role turn a terminal `STATUS:` is reverted, committed as reverted, and escalated `forged-terminal`; after a reviewer-role turn it is accepted only if the canonical post-bytes are an append-only extension of the canonical pre-bytes with non-whitespace new text.
5. **One record, one module, one validated reader.** `utils/py/relay_attest.py` writes `relay-drive/attest@1` atomically, resolves its path, and loads it **only against trusted expectations** (task, expected reviewer, relay file, target repo) — comparing reviewer, status, the byte range and digest of the added text, and the driver's trailer exactly. Consumers additionally require the token to read `done` (not merely actorless) and the candidate to satisfy the transition rule.
6. **Reviewed revision → merge candidate.** Permitted transition: `reviewed_head` is an ancestor of the candidate **and** the endpoint tree diff between them is empty outside the transcript paths (`relay-system/` and the relay file's repo-relative path when it lives in the target repo). Consumers enforce both with `git merge-base --is-ancestor` + `git diff --quiet`, refuse on any git error, then merge with `--match-head-commit <candidate>` so the checked and merged SHAs are the same object. This is the "ancestor + preserved final content" contract, chosen explicitly over "every intervening commit is metadata-only".

## Implementation

### Phase 0 — delete the jog override (#505)

`utils/py/jog_run.py:1375-1389` → `return proc.returncode`.

Check **J**: `run_single_phase_drive` with a stub `relay-drive.sh` exiting 4 and a relay file reading `STATUS: Approved` returns 4. Red at base (returns 0).

### Phase 1 — pin, judge, attest (#509)

`utils/py/relay_drive.py` (canonical; `relay-drive.sh:18` is an `exec` shim).

**Args and precedence.** `--reviewer` required for any run that may accept a terminal status (`--dry-run` exempt); `--builder` optional. Refusals, exit 2, before any tick mutation: `--reviewer` missing; `--builder == --reviewer`; `--review-once` with a dispatched actor ≠ `--reviewer` (`review-once-actor-mismatch`). A custom `--agent-cmd` must route `RELAY_AGENT` to the corresponding contained shim (as `marathon-agent.sh` does); the token actor names *who*, the shim supplies *containment*, and the driver attests only turns whose shim returned 0.

**Per-turn snapshot** (beside `rfsig`, `:611-615`): `pre_status = s`; `pre_canon = canonical(relay_file)`; `reviewed_head = head_before` (already captured at `:615`); `isolated = get_env("RELAY_WORKTREE_ISOLATION","1") == "1"` — the shims' exact predicate (`codex-turn.py:83-91`, `agy-turn.py:404-412`); any supplied value other than `0` or `1` is refused before dispatch (exit 2); `artifact_sha256` when `--artifact-file`. Exports: `RELAY_ROLE`, `RELAY_REVIEWED_HEAD`, `RELAY_DRIVER_LOCKED=1` (already set by the driver's lock path).

`canonical(path)` = file bytes with the first line matching each of `^STATUS:`, `^NEXT:`, `^ROUND:` replaced by the bare key (`STATUS:\n`). Nothing else is normalised. This accepts marathon's render (`marathon_drive.py:2797-2801`), jog's (`jog_run.py:1322-1325`), frontmatter threads, and bare-header threads alike.

**Post-turn judgement**, `judge_terminal(ns, shim_rc)` → returns a verdict; the caller chooses the exit. Called at the current post-turn read (`:820-823`) and on the nonzero-shim path (`:711-712`).
- `not terminal_status(ns)` → `("none",)`.
- builder-role → rewrite the first `STATUS:` line to `pre_status`; append `### System · relay-drive — <ts>\nterminal STATUS written by builder-role turn (<actor>) — reverted`; file-scoped commit, return code checked; stderr line. Verdict `("forged", commit_ok)`. Caller: on the shim-success path `exit_escalate("forged-terminal")` (exit 4); on the shim-failure path write scratch reason `forged-terminal` (or `revert-commit-failed` when the commit failed) and **exit with the shim's code** — 6 stays 6, 7 stays 7.
- reviewer-role: `post_canon = canonical(relay_file)`. `not post_canon.startswith(pre_canon)` → `review-body-rewritten`; `post_canon[len(pre_canon):].strip() == b""` → `empty-approval`. Else `added = post_canon[len(pre_canon):]`, `added_start = len(pre_canon)`, `added_len = len(added)`, `digest = sha256(added)`.
- Publication gate: shim returned 0 **and** body check passed **and** `token_state()` reads status `done` for `args.relay_task` (a claimed/open token → `close-mismatch`; a missing/unreadable token → `token-state`, never treated as done). This check moves *before* publication so review-once (`:830-834`) gets it.
- Attest: append the trailer below; file-scoped commit, checked; `relay_attest.write(record)` (temp + `os.replace`). A failed commit or write → `attest-publish-failed` (exit 4), stderr + scratch, no record left behind (the temp is removed). Set `attested = record` in memory only after both succeed.

```
### Attestation · relay-drive — <utc ts>
task: <relay_task>
reviewer: <actor>
status: <ns>
reviewed-head: <reviewed_head>
added-range: <added_start>+<added_len>
added-sha256: <digest>
```

**Terminal exits.** Loop top (`:571-579`), review-once (`:830-834`), post-loop (`:868-871`): success requires `attested`; otherwise `unattested-terminal` (exit 4, stderr + scratch). A file already terminal at startup is refused.

**Record** `relay-drive/attest@1`: `schema, task, transcript_repo (abs), relay_file (abs), relay_file_rel (repo-relative when inside target_repo, else null), target_repo (abs), reviewer, status, isolated, reviewed_head, artifact_sha256|null, added_start, added_len, added_sha256, trailer_sha256, attested_at, driver_pid`.

`relay_attest.load(task, *, expected_reviewer, relay_file, target_repo)` returns the record or `(None, reason)`; refuses when: file missing/malformed/truncated; `task`/`relay_file`/`target_repo` differ; `reviewer != expected_reviewer`; `status` not terminal; current file's first `STATUS:` ≠ record `status`; `canonical(relay_file)[added_start:added_start+added_len]` digest ≠ `added_sha256`; the bytes immediately after that range are not exactly the trailer whose sha256 is `trailer_sha256` (located by offset, never by heading — a quoted `### Attestation` in the body is inert). Retry identities (`-<n>`) are distinct records; stale records are never deleted, they fail `candidate_ok`.

Checks (`test/gh505-relay-attest.sh`; fixture harness clone as `test/gh376-relay-drive-lock-parity.sh`; the `--agent-cmd` is the **real `codex-turn.py`** with a stub `codex` binary on `PATH` that edits the relay file and moves the token, so the full shipped lifecycle runs — `rtl_init` → `rtl_before` → `rtl_worktree_begin` (cut at the pinned SHA) → stub edits in the worktree → `rtl_worktree_end` (copyback, `RTL_WT_USED`) → `rtl_enforce` (file-scoped commit); each fixture asserts the stub edited the *isolated* file and the bytes reached the parent through copyback before judging the driver):
- **A** builder-role turn writes `STATUS: Approved` + `tick done` → exit 4, reason `forged-terminal`, `STATUS:` restored on disk and in HEAD, no trailer, no record. Red control: base driver invoked without the new flags exits 0.
- **A2** same, stub exits 6 → driver exits **6**, reason `forged-terminal`, revert committed, no record. **A3** same with a pre-existing `.git/index.lock` created after the shim's commit succeeded → the corrective commit is reached and refused (`Unable to create index.lock`), exit 6, reason `revert-commit-failed`.
- **B** reviewer-role turn appends findings + `STATUS: Approved` + done, relay rendered by the **marathon** renderer → exit 0; trailer present; `reviewed-head` = HEAD before dispatch = the worktree's cut revision (asserted from the shim's log) = parent of the shim's commit; `added-sha256` = independently computed sha256 of exactly the appended bytes; `load(...)` with the right reviewer returns the record. **B2** same with the **jog** renderer and a multi-round body. **B3** reviewer also edits `NEXT:`/`ROUND:` and the body contains a quoted `### Attestation · relay-drive` heading → attested, digest unchanged. Positive controls.
- **B4** a parent commit lands on the target repo during the turn → attested with `reviewed_head` = the pre-dispatch SHA (not the new HEAD); the worktree was cut at the pinned SHA.
- **C** file already `STATUS: Approved`, token done, no turn → exit 4 `unattested-terminal`. Red control: base exits 0 after 0 turns.
- **D1** reviewer changes only `STATUS:` → `empty-approval`. **D2** whitespace-only append → `empty-approval`. **D3** rewrites an earlier body paragraph + appends → `review-body-rewritten`.
- **E** `--review-once --reviewer codex`, token handed to `agy` → exit 2, stub did not run. **E2** `--reviewer` omitted → exit 2 before any tick mutation. **E3** `--builder x --reviewer x` → exit 2.
- **K** reviewer turn leaves the token claimed → `close-mismatch`, no record. **K2** attestation write forced to fail → exit 4 `attest-publish-failed`, no partial record.
- **N1** gitignored relay file: trailer still appended on disk (the reader requires it), the commit is skipped deliberately with a logged reason, the record loads. **N2** archive relay (`XYZ_ARCHIVE_ROOT`): checked commit lands in `transcript_repo`; the target repo is untouched; `candidate_ok` excludes only `relay-system`. **N3** tracked relay outside `relay-system/` named `review[1].md` with a neighbouring non-transcript change → `candidate_ok` refuses; with only the relay changed → passes.
- **S1** `RELAY_WORKTREE_ISOLATION` unset and `1` → pinned worktree created, record `isolated:true`; `0` → in-root turn, `isolated:false`, `candidate_ok` refuses; empty and `false` → exit 2 before dispatch. **S2** `--artifact-file` source modified between the driver's digest and the seed copy → turn fails at seed verification; unmodified → attested, `candidate_ok` refuses (artifact records are transcript-only).
- **L** reader: record loads for reviewer A, refuses for expected reviewer B; refuses after `STATUS:` is edited `Approved`→`Closed`; refuses after the added text is edited; refuses a truncated JSON.

### Phase 2 — containment reads the driver; the prompt stops inviting builders to approve (#505)

`relay-automation/relay-turn-lib.sh` (only copy — `utils/py/rtl.py:667-696` sources it, env preserved).

1. `rtl_is_reviewer_turn` (`:63`), first tier, inside the shared helper: `if [[ "${RELAY_DRIVER_LOCKED:-}" == 1 ]]; then case "${RELAY_ROLE:-}" in reviewer) return 0;; builder) return 1;; esac; fi`. **Stated limit:** `RELAY_DRIVER_LOCKED` is an inherited compatibility marker, not proof of a live driver; a hand-run turn that inherits both variables from a driver shell is classified by them, and a stale `RELAY_ROLE=builder` on a hand-run *reviewer* widens its allowlist to the artifact. Hand-run turns without both variables still trust the editable directive / `NEXT:` prose, as today.
2. `rtl_worktree_begin` (`:733`): cut at `"${RELAY_REVIEWED_HEAD:-HEAD}"`; log the SHA used.
3. Shared prompt (`:1011`): remove `(or done + set STATUS: Approved when approving)`; add ` When approving, hand the token off with done and set STATUS: Approved.` to the reviewer `role_note` (`:994-998`). Correct the permission description in the comment: reviewer = relay-file only; builder = artifact allowlist.

Checks:
- **F** through the `rtl.py` bridge with `RELAY_DRIVER_LOCKED=1`: `RELAY_ROLE=reviewer` + directive naming the agent *builder* → relay-only allowlist; `RELAY_ROLE=builder` + directive naming it *reviewer* → artifact allowlist. Red control: base follows the directive both ways. **F2** same env without `RELAY_DRIVER_LOCKED` → directive decides, through the same shared path.
- **F3** `rtl_worktree_begin` with `RELAY_REVIEWED_HEAD=<older sha>` cuts the worktree at that SHA while `HEAD` is newer. Red control: base cuts at HEAD.
- **G** rendered prompts non-empty; builder prompt lacks `STATUS: Approved`; reviewer prompt contains it.

### Phase 3 — consumers validate the record (#509, #505, #510)

**`utils/py/relay_attest.py`** (new): `path_for(task, target_repo)` via `git rev-parse --git-common-dir`; `write(record)`; `load(...)` as above; `candidate_ok(record, candidate_sha, target_repo)` → `(bool, reason)`: refuses when `not record.isolated`; `git merge-base --is-ancestor reviewed_head candidate` fails; `git -C <target_repo> diff --quiet reviewed_head candidate -- ':(top,exclude)relay-system' [':(top,literal,exclude)<relay_file_rel>']` is non-empty (literal, top-anchored — a name like `review[1].md` is matched exactly); any git error. A gitignored relay needs no exclusion; an archive relay (`XYZ_ARCHIVE_ROOT`) lives in `transcript_repo`, so only `relay-system` is excluded in the target repo.

**`utils/py/marathon_drive.py`**
1. `cmd2` (`:3144-3149`): `"--reviewer", args.reviewer, "--builder", args.builder`.
2. **Normal success**: in `complete_phase_success()`, after `save_transcript()` and the post-approve command (`:2575`, `:2595-2602`), capture **one** candidate `C = rev-parse HEAD`, `load(task, expected_reviewer=args.reviewer, ...)`, `candidate_ok(record, C)`; refusal → escalate `candidate-drifted-from-reviewed-head` (exit 4). The `marathon.phase.approved` emit, attempt reset and green emit (`:2573-2579`) move **after** this check so no success is published for a drifted candidate. `C` is stored in `_RESULT["reviewed_candidate"]` and the exit writer (`:148-165`) emits it verbatim beside its own observational `head_sha`; the receipt also gains `reviewed_head`, `added_sha256`, `attest_path`. Jog's marathon branch requires PR head == `reviewed_candidate` before `candidate_ok`.
3. `satisfied_lane_terminal()` (`:2677-2698`), exit-3 probe (`:3218-3222`), exit-7 probe (`:3294-3298`): require `token_state(task).status == "done"` explicitly, a validated `load`, and `candidate_ok(record, HEAD)`. Refusals logged with the reader's reason.

**`utils/py/jog_run.py`**
4. `run_single_phase_drive(root, gh_num, builder, reviewer, simulate)`: refuse missing reviewer and `reviewer == builder` with `validate_marathon_executor`'s messages (`:189-196`); dispatch via `marathon-agent.sh` with `MARATHON_BUILDER/REVIEWER` and both `<AGENT>_AGENT` vars; pass `--reviewer`/`--builder`. Caller `:1665` threads `args.reviewer`.
5. `_merge_reviewed_pr(root, pr_num, record)` used by **all three** landing branches (legacy auto, legacy interactive, marathon-executor `:426-435`): candidate `C = gh pr view --json headRefOid`; `candidate_ok(record, C)` else park `candidate-drifted-from-reviewed-head`; `gh pr merge <n> --merge --auto=false --match-head-commit C`, output captured, non-zero → park with stderr (#510). No PR → park (#510). Existing state/base checks (`:1393-1407`) and `jog_verify_pr_before_merge` stay. Legacy branches load the record by `RELAY-gh{N}-jog-drive` with `expected_reviewer=args.reviewer`; the marathon branch loads by the receipt's `attest_path`/task with the receipt's reviewer, and parks when the receipt has no `reviewed_head`.

Checks:
- **H1** marathon startup with a terminal relay + done token + no record → `satisfied_lane_terminal()` refuses **loudly** and the run exits non-zero without dispatch (a done token cannot reopen, `:2605-2610`); the stub records it did not run. **H2** exit-3 recovery: artifact present, gate passes, stub relay writes terminal + done and exits 3, no record → **process** exit 3 `no-progress`; with a valid record and clean candidate → 0. **H3** exit-7 recovery with a record whose `reviewed_head` is not an ancestor of HEAD → process exit 7. **H4** normal success with a source commit after approval (post-approve command touches a file) → exit 4 `candidate-drifted`, no approved receipt. Red control for H1/H2/H4: base exits 0; for H3: guard-transposition mutation (`candidate_ok` copied and forced to return True) passes.
- **I1** legacy interactive (stdin replaced by an object whose `isatty()` is True and `readline()` yields `y`), stub `gh` serving `pr list`/`pr view`, valid record, candidate == reviewed → `pr merge` argv carries `--match-head-commit <C>`, stub confirms it ran. **I2** stub `pr merge` exits 1 → parked. **I3** `pr list` empty → parked. **I4** candidate has a non-transcript commit after `reviewed_head` → parked, merge not reached. **I5** auto branch: I1–I4 again; I2 there is a preservation control (base already parks). **M1/M2** marathon-executor branch: receipt with `reviewed_head` and a clean candidate merges with `--match-head-commit`; receipt without it parks; candidate drifted parks. Red controls: I2/I3 legacy-interactive and M2 (base returns `completed` / merges without binding); I4 by mutation.
- **J** Phase 0.

Evidence: red controls and mutations recorded in `test/baselines/GH-505-negative-control.md` with exact invocations and observed output; the disposable-clone gate's `provenance.jsonl` committed in this PR.

### Migration

Recipes gain the reviewer explicitly, per their own variables: `skills/relay-xyz/SKILL.md:324-328` `--reviewer "$CODEX_AGENT"`, `:345-349` `--reviewer "$AGY_AGENT"`, `:366-370` `--reviewer "$COMMANDCODE_AGENT"`; `relay-automation/README.md:227-234` names a reviewer and builder explicitly and states that a custom `--agent-cmd` must route the actor to a contained shim. `relay-drive.sh:32` header comment updated.

## Round 2 dispositions

| # | Verdict | Disposition |
|---|---|---|
| B1 | Accept | Canonical bytes (first `STATUS:`/`NEXT:`/`ROUND:` reduced to keys) replace the header-stripping parser — accepts title-first, frontmatter and bare forms; record and trailer carry `added_start`/`added_len`; reader validates the range, digest and trailer by offset. B, B2, B3 rewritten. |
| B2 checkout | Accept | `RELAY_REVIEWED_HEAD` exported; `rtl_worktree_begin` cuts at it; non-isolated turns → `isolated:false`, merge refused by non-goal; artifact input recorded by digest. B4, F3 added. |
| B2 landing | Accept | One `_merge_reviewed_pr` for all three branches; compares record R with PR candidate C; passes exactly C. M1/M2 added. |
| B2 success | Accept | `candidate_ok` before the approved receipt, after post-approve; receipt carries `reviewed_head`/`attest_path`. H4 added. |
| Q9 | Accept | Ancestor + preserved endpoint content, stated as the contract; exact transcript paths named; `.relay-scratch` dropped; git errors refuse; archive relay handled by `transcript_repo`. |
| B3 | Accept | Reader takes expected reviewer; compares reviewer, status (record = file = trailer), range/digest/trailer; consumers require token `done` explicitly; publish failures are their own refusal with no partial record. L, K2 added. |
| F1 | Accept | Gate inside the shared helper; permission description corrected (stale *builder* widens); per-recipe variables; custom `--agent-cmd` contract stated. |
| F2 | Accept | H1 asserts loud refusal + no dispatch; I1 makes `isatty()` true; I5-I2 labelled preservation; integration cases run the real `relay-turn-lib.sh`; mutations named for controls not red at base. |
| F3 | Accept | Judge returns a verdict; shim-failure path preserves 6/7; `revert-commit-failed` reported without masking the original code. |
| Ratings | Accept | #509 rationale added to its pointer doc; effort 25 kept provisional. |

## Round 3 dispositions

| # | Verdict | Disposition |
|---|---|---|
| B1 isolation | Accept | Predicate is the shims' exact `== "1"`; other supplied values refused pre-dispatch. S1 added. |
| B1 artifact | Accept | Driver exports the digest; `rtl_worktree_begin` verifies the copied bytes; artifact records are merge-ineligible by `candidate_ok`. S2 added. |
| F1 | Accept | One candidate `C` captured after post-approve, validated, carried into the receipt as `reviewed_candidate`; success emits moved after the check; jog's marathon branch requires PR head == `C`. H4 inspects the emits. |
| F2 | Accept | `:(top,exclude)` / `:(top,literal,exclude)` from the target root. N3 added. |
| F3 | Accept | Fixtures run the real `codex-turn.py` with a stub binary; A3 uses `index.lock`; N1/N2 state the ignored and archive branches. |

## Implementation dispositions

Where the code departs from the adjudicated plan, and why. Each is a judgement final QA should
re-examine with the code in hand.

| Plan said | Code does | Why |
|---|---|---|
| `--reviewer` missing → exit 2 before dispatch | loud stderr warning; the run can never accept a terminal status (E2 pins that an approval without a named reviewer is reverted as `forged-terminal`) | 30+ shipped suites and every vendored `.xyz/` copy drive non-terminal relays without the flag; refusing strands them for no safety gain. Round-1 QA said "preferably", not "must". |
| canonical = header keys normalised | also applies the harness's own uncited-claim downgrade (GH-173 B3) | the shim rewrites pre-existing lines in place after a reviewer turn; without this port every real reviewer turn read as `review-body-rewritten` (`gh280` chain) |
| transcript paths = `relay-system/` + the relay file | + marathon's two named phase records beside it (`ESCALATION.md`, `PHASE-INTERRUPTED.md`), never the directory | marathon writes exactly those beside `RELAY.md`; a retry after a gate flake was refused as code drift (`marathon-drive.sh` GH-274 case). Final-QA round 1 rejected the directory allowance (a user-selected relay may sit beside source) — N3 pins neighbouring drift as refused |
| nonzero-shim path "judges for revert only" | any turn whose shim returned non-zero is reverted whatever its role and never attested (`failed-turn-terminal`) | final-QA round 1 B1: a reviewer that approved, marked done, then failed could publish a record marathon's recovery would accept. A3 pins it |
| consumers require the token `done` | jog's landing (all three branches) reads the token in the repo's own tick root and parks unless it is `done` | final-QA round 1 F1; I0 pins the missing-token refusal |
| canonical = keys + downgrade | the pre-turn snapshot's downgrade is judged with the POST-turn lines as look-ahead, records split on LF only with a CR kept in the record and a final LF always added — the awk's actual behaviour | final-QA round 1 F2; B6 (appended citation un-stamps an old claim) and B7 (CRLF) pin it |
| reader refuses malformed records | `load()` never raises — any malformed record is `(None, reason)`; `attested_at` and the range/path types are validated | final-QA round 1 F3; L extended |
| candidate bound once, after post-approve | bound **twice** — before the approved event/green emit, and again after the post-approve command | the GH-273 post-approve contract requires the approved event to exist when the hook runs; the first check keeps a drifted candidate from ever being published, the second catches drift the hook caused |
| `--review-once` redefines nothing | actor≠`--reviewer` refusal applies only when `--reviewer` is given | a review-once run with no reviewer named must still be able to stall/hand back (exit 3/5) for the cost-summary suites |
| jog relay executor requires a reviewer | required for real dispatch; `--simulate` dispatches nothing and lands as a simulated completion | `jog-queue.sh` simulate contract |
| `test/gh505-relay-attest.sh` cases A–L, H, I, J | A, A2, B, B4, B5, C, D1, D3, E2, E3, S1, K1, K2, L, F, F2, G, I1–I5, J in the new suite; H1/H2/H4 via the shipped marathon suites (every stub relay-drive now has to attest for marathon to succeed — 19 failures in `marathon-drive.sh` alone on the first gate run); M1/M2 via `gh280` N-series; H3/I4-by-mutation folded into B4 (real peer commit) and I4/I5 (real drift) | a real drift is a stronger control than a transposed guard |

## Dependencies and ordering

0 → 1 → 2 → 3, one PR. Phase 3 without Phase 1 breaks marathon (no record is ever written); Phase 1 without Phase 2's worktree cut attests an unpinned revision — land together.

## Risks and rollback

- Every driven relay here and in vendored `.xyz/` copies should name `--reviewer`; without it the driver warns once at startup and can never accept a terminal status (see Implementation dispositions). Migrated in this PR: marathon, jog (both executors), relay-xyz recipes, README.
- Two commits per approval/forgery on tracked relay files. Gitignored relay files get the record only.
- Rollback: revert the PR; `relay-attest/` under `.git` is inert.
- Tripwire, first week: `forged-terminal`, `unattested-terminal`, `candidate-drifted-from-reviewed-head`, `attest-publish-failed` on stderr or in scratch.

## Verification

- `test/gh505-relay-attest.sh` (A–L, F–G, H1–H4, I1–I5, M1–M2, J) in a disposable full clone.
- Full gate (`validate.sh`) in that clone; `provenance.jsonl` committed.
- Codex final QA on the committed implementation.
