---
title: Reviewer approves without running the gate after builder flags unverified assertions; Codex builder sandbox blocks localhost
status: Active (2-WORKING)
created: 2026-11-11
updated: 2026-11-11
owner: Noel Saw
gh_issue: 1428
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1428
doc_type: bugfix
complexity: 3
risk: 3
effort: 3
phases: 1
reported_from: LTVera-Pandas
harness_commit: 046b41538
non_goals:
  - Changing gate selection or the pre-advance gate itself
  - Letting reviewers run full-suite gates (validate.sh, ci-local.sh, test/*.sh) in a turn worktree
  - A harness-side "run the gate before the reviewer" stage or a new gate/runner (GH-831)
  - Spend/turn ceilings and error surfacing (#1427), jog dry-run (#1426)
related:
  - "#1426"
  - "#1427"
  - "#1092"
goal: >
  A marathon reviewer that is allowed to run the phase gate must declare whether it ran it, and an
  Approved after the builder records unverified assertions is refused unless the reviewer ran the gate;
  Codex builders get a documented opt-in path to localhost services.
---

# GH-1428 — Reviewer approves unverified work; Codex builder cannot reach localhost

## Status

| What was just completed | What's next |
|---|---|
| Plan QA R3 Approved; implemented; focused suites + manual checks green; final QA R1 selector-containment fix applied | Final QA R2, full gate on the approved head, ready PR |

## Table of contents

- [Observed](#observed)
- [Recon (base 0f21b761a)](#recon-base-0f21b761a)
- [Rating rationale](#rating-rationale-2026-11-11)
- [Plan](#plan)
- [Acceptance map](#acceptance-map)
- [Lessons Learned](#lessons-learned)

## Environment
- **Observed from:** `LTVera-Pandas` (vendored `.xyz/` at `046b41538`)
- **Worker/CLI:** codex-cli 0.167.0-alpha.3.2 (builder), claude 2.1.322 / claude-sonnet-4-6 (reviewer)
- **Sandbox:** driver unsandboxed; Codex builder in `-s workspace-write` (network off by default)

## Symptom

Marathon relay `--builder codex --reviewer claude-reviewer` (Jog item GH-955, attempt 2, throwaway
Postgres on `localhost:55461`, `TEST_POSTGRES_*` exported for the whole run). The Codex builder wrote
in its round-1 block that DB-backed assertions were **unverified** because "sandbox access to
`localhost:55461` was denied … harness must run the specified gate with database access". The Claude
reviewer **Approved** after 13 Bash calls (all `ls`/`grep`/`tick`, zero pytest). The pre-advance gate
then failed on exactly the flagged assertion (`CheckViolation`). Attempt 1 (no DB) showed the same
reviewer pattern.

## Observed

| Claim | Source | Observed |
|---|---|---|
| Builder flagged unverified work | LTVera-Pandas `1d5cfcb0:marathon-system/gh-955-dashboard-snapshot-refresh-filter/RELAY.md`, Round 1 · Builder · codex | "Persisted-row/KPI assertions remain unverified here; harness must run the specified gate with database access." |
| Reviewer graded it unverified and approved anyway | same file, Round 1 · Reviewer · claude-reviewer | "[Unverified — needs clone run for Postgres-backed tests]" … `**Verdict:** Approved`; relay-drive attested it (`1d5cfcb0`) |
| Gate failed on the flagged path | LTVera-Pandas `4c8c3ac4` ESCALATION.md | `reason: pre-advance-failed`, `gate: red` |
| Phase gate was a focused, explicit command | packet in the same RELAY.md | `--pre-advance-cmd '.venv/bin/pytest -q tests/test_dashboard_snapshot_refresh_filter.py'` |

## Recon (base 0f21b761a)

**Root-cause correction.** The reviewer did not ignore its instructions; it followed them. Three
harness layers tell it *not* to run the gate, and none asks for gate evidence:

1. `relay-automation/relay-turn-lib.sh:1067` (GH-681 reviewer role note, prepended to every turn
   prompt by `rtl.turn_prompt`): "Do NOT run validate.sh, test/*.sh, pytest, or executable fixtures
   here — … a claim that can only be measured that way is graded [Unverified — needs clone run], and
   the harness gate runs after your turn." Pinned by `test/gh681-reviewer-probe-rules.sh:49-50`.
2. `utils/py/swarm_preflight.py:1418-1430` (brief "Scope lock — builder", GH-54): "Do NOT run the full
   gate (`<gate>`) yourself", or, when covering tests create git fixtures, "Do NOT run ANY test or
   gate yourself". Builder-scoped, so for the reviewer it is contextual ambiguity rather than a
   binding prohibition; the fixture variant is a real safety signal the exception must preserve.
3. `utils/py/marathon_drive.py:3134-3160` (REVIEWER TAKE YOUR TURN): requires `swept file:`, says
   nothing about the gate. The Bash twin `relay-automation/marathon-drive.sh:1067` already lags
   (no 4b/4c/swept-file); Python is the default runtime (`XYZ_PYTHON-1`).

**Approval seam.** `utils/py/relay_drive.py:698` `judge_terminal()` is the only place a reviewer's
terminal STATUS becomes an attestation; it already refuses `review-body-rewritten`, `empty-approval`,
`token-state` via `("refused", reason)` → `exit_escalate(reason)` (exit 4, reason in
`.relay-scratch/escalation-reason`). Existing coverage: `test/gh505-relay-attest.sh`. The Bash
`relay-drive.sh` body has no attestation, so the change is Python-only.

**Attestation record.** `utils/py/relay_attest.py:267 trailer_text()` binds optional
`config_sha256` (GH-1220) into the trailer only when present; `_load()` validates it optionally.
Same pattern carries an optional `gate_run` field without a schema bump; legacy records are
unaffected.

**Gate knowledge.** `marathon_drive.main()` resolves `pre_advance_cmd` at `:1519-1539`
(explicit `--pre-advance-cmd`, else target `validate.sh`, else `tc run --strict`, else harness
`validate.sh`). The reviewer runs in an isolated worktree at HEAD (`relay_drive.py:319`,
`RELAY_WORKTREE_ISOLATION=1` default) with `PYTHONDONTWRITEBYTECODE=1` and
`TMPDIR=<wt>/.relay-scratch/tmp` already injected for reviewer turns (`rtl.py:876`, GH-682).
Containment reads `git status --porcelain` (ignored files are not off-lane). marathon passes the
relay-drive child env via `env2` (`marathon_drive.py:3489`); `MARATHON_CONFIG_SHA256` is the
precedent for a marathon→relay-drive env signal.

**Gate env.** `utils/py/gate_env.py:147-157` scrubs only registered harness vars, so
`TEST_POSTGRES_*` reaches the pre-advance gate and the turn shims.

**Codex network.** `utils/py/codex-turn.py:17` takes `CODEX_FLAGS` (default
`-s workspace-write -c approval_policy=never`); Jog (`jog_run.py:519`), marathon (`env2`) and
relay-drive pass the environment through unscrubbed. codex-cli 0.167 accepts
`-c sandbox_workspace_write.network_access=true`. The knob exists; it is undocumented for this use
(`relay-automation/README.md:439`, `skills/1-hourly/relay-xyz/SKILL.md:599`).

**Related.** #1092 (open) recommends keeping the reviewer restriction for code artifacts "where the
gate runs after the turn"; this plan keeps the restriction for full-suite gates and opens a single
named exception for an explicit focused phase gate, which is what GH-955 had.

## Rating rationale (2026-11-11)

`rated 65/55/50/60` (pickup, `rmi-01M76W1SYFRHFHPY05081ZFZHS`).
- **sev 55**: wasted Jog attempts and a false "Approved" signal; the pre-advance gate still caught it,
  so no bad code landed. Recoverable.
- **pri 65**: two incidents on one item in one session (2026-11-11, attempts 1 and 2); same class as
  #1092 (reviewer barred from measuring still approves; Oct 2026). Window 2026-10-28..11-11 vs prior
  14 days: 2 distinct incidents vs 0 known for this exact class; earlier coverage is limited to issues.
- **appeal 50**: neutral; the capture's 60 was an agent proposal, not an operator value.
- **effort 60**: template text + one predicate + one refusal + docs; no schema or control-flow change.

## Plan

### Bet check
- **Outcome sought:** a focused, DB-backed assertion that the builder could not run is not
  approved unrun; a Codex builder can run localhost-backed tests when the operator opts in.
- **Smallest viable bet:** a reviewer declaration (`gate run: yes|no`), one refusal in the existing
  `judge_terminal()`, a narrow exception in the reviewer role note, and docs for the existing
  `CODEX_FLAGS` knob. **Not built:** a harness pre-reviewer gate run, a preflight service probe, a
  Bash-twin port, any new suite.
- **Alternatives rejected:** (a) harness runs the gate before accepting Approved and hands red back
  to the builder: a real control-flow change in `marathon_drive.py`, which #1427 is editing in
  parallel, and it contradicts the issue's reviewer-centred acceptance. (b) Refuse every Approved
  after a builder "unverified": it escalates lanes whose gate is a full suite the reviewer is forbidden
  to run, a regression against today. (c) A preflight warning probing for local services: guesses
  which services a gate needs; the issue accepts docs instead.
- **Rollback:** revert the PR. Reversibility **Easy**: no schema, the attestation field is optional,
  and with no `MARATHON_REVIEWER_GATE_CMD` relay-drive behaves exactly as before.

### One PR, not two
Both concerns describe the same failure. The refusal is only workable if there is a documented way to
make the builder verify for itself (the network knob is the remedy the refusal message points at).
The network part is docs-only. Splitting would ship a refusal with no remedy.

### Ordered implementation (verification inline)

1. **`utils/py/marathon_drive.py` — reviewer-runnable gate (positive contract, plan-QA R1).** After
   `pre_advance_cmd` is resolved (`:1539`), set `reviewer_gate_cmd = pre_advance_cmd` only when ALL hold,
   otherwise `""`:
   - `args.pre_advance_cmd` was passed explicitly (defaults are full-suite by construction);
   - **focused, file/node selectors only** (plan-QA R2): `shlex.split` the command; no shell compound
     (`&&`, `||`, `;`, `|`, `$(`, backtick); after the first token (the runner), every positional token is
     either the value of `-m`/`-p`/`-k` or a test **file** (after stripping a `::node` suffix) that exists
     as a regular file under the target root (`args.target_root or root`) — relative, and contained after
     resolving symlinks (final QA R1: no `../`, absolute or symlink-escaping selectors) — and at least one such file is
     named. A directory, a missing path, or any other positional keeps the gate harness-only, so
     `python3 -m pytest` and `pytest tests/x.py tests/` do not qualify;
   - no full-suite runner or passthrough: none of `validate.sh`, `ci-local.sh`, `run-tests.sh`, a
     `test/*.sh` script, or a ` -- ` passthrough (GH-108 caveat);
   - the brief does not carry preflight's GH-54 fixture rule ("create temporary git fixtures"), which
     marks covering tests that mutate Git state.
   One small predicate, no scanner. Unknown or broad shapes stay harness-only, and the selector is a
   scope check, not proof of fixture safety, so the reviewer step also says: if you cannot tell that the
   run is worktree-safe, declare `gate run: no — <why>`. → expect GH-955's
   `.venv/bin/pytest -q tests/…py` yields the command; `bash …/validate.sh`, `tc run --strict`,
   `python3 -m pytest`, `pytest tests/x.py tests/`, `a && b`, and a GH-54-fixture brief yield `""`.
2. **Same file — template.** BUILDER step 2 gains one sentence: a verification the brief asks for that
   could not run (e.g. sandbox denied a local service) goes on its own `unverified: <what> — <why>`
   line. REVIEWER gains step `3a. GATE EVIDENCE (GH-1428)`:
   - with `reviewer_gate_cmd`: before writing Approved, run the gate from your worktree
     (`{reviewer_gate_cmd}`), with cwd = your worktree so the tests and source under test are the
     reviewed revision. Only *tooling* missing from the worktree (e.g. an untracked `.venv/bin/pytest`)
     may be taken from the target root; if a test or source path is missing, do not substitute the
     target root's copy and declare `gate run: no — <why>`. Scratch env exported, caches out of the tree
     (pytest `-p no:cacheprovider`). Every review block carries a literal
     `gate run: yes — exit <rc>` or `gate run: no — <why>` line. If the builder's latest block says
     anything is unverified and you did not run the gate to `exit 0`, do not approve: relay-drive refuses
     it (`unverified-approval`).
   - without: the phase gate is a full suite that runs only in the harness after your turn. Do not run
     it, and declare `gate run: no — harness gate` in your block.
   → expect `--dry-run` renders each variant (step 7 smoke).
3. **Same file — signal.** In `_run_relay_drive`, set `env2["MARATHON_REVIEWER_GATE_CMD"]` when
   `reviewer_gate_cmd` is non-empty and `pop` it otherwise, so an ambient value cannot leak in. (One line beside `MARATHON_CONFIG_SHA256`. Kept minimal for #1427
   overlap.)
4. **`utils/py/relay_attest.py` — parse + record.** Add `declared_gate_run(added)` returning
   `"yes"` only for a last `gate run: yes … exit 0` declaration, `"failed"` for `yes` with a non-zero or
   missing exit, `"no"`, or `"undeclared"` (case-insensitive, last declaration wins) and
   `builder_declared_unverified(pre_text) -> bool`. That second check reads the **latest**
   `### Round N · Builder ·` block for `\bunverified\b`; that matches both the instructed `unverified:`
   line and GH-955's prose. Make `trailer_text()` bind `gate-run: <v>` when `record["gate_run"]` is
   present, as `config_sha256` already does, and have `_load()` validate the optional field against
   the four allowed values.
   → expect legacy records still load (gh505 B/C cases).
5. **`utils/py/relay_drive.py` — refusal.** In `judge_terminal()`, after `empty-approval` and before
   the token check, compute `gate_run`. If `MARATHON_REVIEWER_GATE_CMD` is set, the builder declared
   unverified, and `gate_run != "yes"` (so `failed`, `no` and `undeclared` all refuse), eprint the remedy (reviewer runs the gate, or opt the Codex
   builder into localhost network per README) and return `("refused", "unverified-approval")`. Always
   store `record["gate_run"] = gate_run`. → expect generic relays (no env) unchanged.
6. **`relay-automation/relay-turn-lib.sh:1067` — exception clause.** After "executable fixtures here",
   insert ", except a phase gate command your relay file's REVIEWER steps explicitly tell you to run
   (GH-1428)". The pinned needles in `test/gh681-reviewer-probe-rules.sh` are unchanged.
   → expect gh681 green.
7. **Docs.** `relay-automation/README.md` (next to the `CODEX_FLAGS` paragraph) and the
   `relay-xyz/SKILL.md` autonomy row get the opt-in:
   `CODEX_FLAGS='-s workspace-write -c approval_policy=never -c sandbox_workspace_write.network_access=true'`.
   It is opt-in and per run, and it opens all outbound network for that Codex turn, not just localhost.
   Add the `gate run:` contract and the `unverified-approval` reason. One CHANGELOG entry.

### Verification (bounded; no new suites, GH-831)
- Focused existing suites while iterating, run in a disposable `-verify` full clone:
  `test/gh505-relay-attest.sh`, `test/gh681-reviewer-probe-rules.sh`,
  `test/gh268-relay-cue-and-target-checks.sh`, `test/debug-mantra.sh`.
- Manual checks under `TESTS-RESULTS/2026-11-11+GH-1428/` with `provenance.jsonl`:
  - **Red control (acceptance 2):** feed the real GH-955 builder block and reviewer Approved block
    through relay-drive with a scripted reviewer (gh505 fixture pattern, in scratch, not a new suite).
    With `MARATHON_REVIEWER_GATE_CMD` set → exit 4, reason `unverified-approval`; also refused for
    `gate run: yes — exit 1`, `— exit 124` and `gate run: yes` with no exit. Same pair with
    `gate run: yes — exit 0` → attested, record `gate_run: yes`. Same pair without the env → attested as today,
    `gate_run: undeclared`. Pre-fix code on the same pair is attested (the witnessed red).
  - **Render (acceptance 1):** `marathon-drive --dry-run` with GH-955's explicit focused
    `--pre-advance-cmd` shows the run-the-gate step; the default `validate.sh` gate, an unscoped
    `python3 -m pytest`, `pytest tests/x.py tests/`, a compound `a && b`, and a brief with the GH-54
    fixture rule show the do-not-run step.
  - **Path fallback (plan-QA R1/R2):** the render tells the reviewer cwd = worktree, tooling-only
    fallback, and `gate run: no` on a missing test/source path. Recorded as a render receipt; a live
    reviewer turn is out of scope for this verification.
  - **Codex network (acceptance 3):** with `python3 -m http.server --bind 127.0.0.1` on a free port,
    `codex exec` under the default flags fails to fetch it (red); with
    `-c sandbox_workspace_write.network_access=true` it succeeds.
- Final gate: `utils/ci-route.sh` routes `.py`/`.sh` changes to the full gate. Run full
  `validate.sh` exactly once on the final commit in a disposable full clone, then push through the
  pre-push hook.

### Risks
- **False positive:** a builder writes "nothing unverified". The reviewer must then run the focused
  gate, which costs one focused run and only applies where the reviewer may run it.
- **Reviewer misreports `gate run: yes`:** this is a declaration, like `swept file:`. The harness gate
  still referees afterwards, so it is no worse than today.
- **Containment:** a reviewer gate run that writes non-ignored files fails that turn. The prompt names
  the scratch env and `-p no:cacheprovider`, and containment stays unchanged.
- **#1427 overlap:** both touch `marathon_drive.py`. This diff touches only the reviewer template,
  one predicate after `:1539`, and one `env2` line.

## Acceptance map

| Issue acceptance | Plan step | Evidence |
|---|---|---|
| Reviewer steps require running the gate (or naming why it can't); attestation records it | 1, 2, 4, 5, 6 | dry-run render receipts; record `gate_run` |
| Approved after builder-declared unverified assertions refused without reviewer-run evidence | 4, 5 | GH-955 red-control receipt |
| Documented opt-in localhost network for Codex builders | 7 | README/SKILL diff + codex network smoke |
| Existing suites pass; evidence under TESTS-RESULTS | Verification | focused logs + one full gate |

## Lessons Learned

- Before blaming an agent for skipping verification, read every instruction layer the harness gave
  it. Here the turn prompt and brief both forbade the action the issue expected.
