# GH-1400 integrated candidate: independent Claude review result

Reviewed candidate source: `ef23e77b24e51add4be9476191257bcbc7d7c432`, plus evidence commit `7a95a1d0c8c8eb731803199eedd33fb2a9537397` (reports only).
Relay reviewed head: `628b1369aed61945145c6ce0a06f830cdb7793f6`. It differs from `ef23e77b2` only under `TESTS-RESULTS/` and `relay-system/`: `git diff ef23e77b2 HEAD -- . ':!TESTS-RESULTS' ':!relay-system'` is empty.
Thread: `relay-system/2026-11-16/gh1400-integrated-ef23-claude-review.md`. Turn commit `8062e16d7`, attestation commit `44b4f5898`.

VERDICT: PASS
Basis: The independent Claude reviewer found that the Jog runtime blobs are byte-identical to the attested follow-up head `185db9741037`. Task-local continuation sits only on the supervised `failed` path and fails closed. Shared-safety checks run before every dispatch. Saved-approved-result adoption happens once, and missing, corrupt or mismatched receipts hold. The upstream `swarm_preflight.py` refactor preserves every Jog seam. Evidence and limits are honest. There is one optional docs Nit. The full gate is pending.
Reviewer-approved: yes. STATUS: Approved, set by the `--reviewer claude` turn and attested by the driver.

## Route and attestation

- Route: the shipped relay-xyz harness on the same provider. Run as `relay-drive.sh --reviewer claude --review-once --agent-cmd relay-automation/claude-turn.sh` with `CLAUDE_AGENT=claude` and `ALLOW_PATHS=""`, so the review could write only the relay file.
- Auth: `CLAUDE_AUTH_MODE=subscription`. The preflight showed a first-party claude.ai Max account. No API key or provider override was used, and there was no API fallback.
- Environment isolation: the driver ran under `env -i` with only HOME, USER, LOGNAME, SHELL, PATH, TMPDIR, LANG and TERM. The parent session's `CLAUDECODE`/`CLAUDE_CODE_*` variables did not reach the child. The turn ran in the harness's own temporary worktree at the reviewed head (`isolated: true`).
- Model: `CLAUDE_MODEL=opus`, which resolved to `claude-opus-5-5`, with `CLAUDE_REASONING_EFFORT=high`. Ceilings: 60 turns, $10, 2400 s. Actual: 34 turns, 231 s, a $1.98 API-price estimate under subscription. The transcript reports `subtype: success` and `is_error: false`.
- Driver exit: 0, review-once approved after 1 turn. Log tail: `attested Approved by claude — reviewed 628b1369aed6, 8494 bytes of review text`.
- Attestation record: `.git/relay-attest/RELAY-gh1400-integrated-ef23-claude-review.json` (schema `relay-drive/attest@1`, reviewer `claude`, status Approved, added-sha256 `9e6af767…69ca`, `gate_run: undeclared`).
- Validator: `relay_attest.load(..., expected_reviewer='claude')` returned a record with no refusal. `relay_attest.candidate_ok(record, 44b4f5898)` returned `(True, None)`. Exit 0.
- Budget: one review round consumed (round cap 1). Earlier Agy, Claude and status attempts were not modified, reset or restarted, and `.tick/attempts` was not reset.

## Findings for parent disposition

- [Pass] Q1–Q6: classification, shared safety, saved-result adoption, preflight integration, evidence honesty and scope, each with line citations in the thread.
- [Nit] `jog retry` resets a failed row to `pending` (`releases_app.py:4966`). A later supervised wake re-holds that row as `latest execution is not approved; explicit retry decision required` (`jog_run.py:2622-2631`). This matches the documented intent. Optional docs-only fix: one SKILL.md line saying that `retry-build` is the explicit path for a supervised wake.
- Pending, not a finding: the classified full gate on the approved commit.

## Scope limits

- `swept file: no`. The reviewer read the full task diff, the full `swarm_preflight.py` delta against `0d1dc0fe8`, and named ranges of `jog_run.py`/`releases_app.py`. It did not read about 2,400 other lines of `jog_run.py` or the untouched parts of the preflight.
- The review was static only. No suites, tests or model processes ran beyond the single review turn. The 23 controls use a fixture preflight; the 227-test adapter suite is the only real-preflight evidence.
- Known limits stand: a shared environment fault looks the same as a task-local red; each later task consumes one bounded attempt; a mid-wake checkpoint contradiction is detected only at finish; evidence is synthetic only, with no production or unattended claim.
- The CLI warned that the temporary worktree was not trusted, so it "may ignore project permissions". The review wrote only the relay file, the commit was file-scoped, and nothing was pushed.
- Graph context was supporting only (primary project generation `2026-11-16T19:03:06Z`, not the candidate). Candidate claims rest on reading the source.

## Parent action

Run the qualifying full gate on the approved commit in a verified disposable full clone. Then decide on the Nit, publish, and land. This record authorizes no push, merge or full gate.
