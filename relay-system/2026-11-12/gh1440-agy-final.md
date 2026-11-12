# RELAY · PR #1440 (GH-1436 / GH-1437) Final Review

<!--
  Independent review receipt for PR #1440:
  fix: isolate malformed contracts and reject invalid gate environments (GH-1436, GH-1437)
-->

NEXT: Done
STATUS: Approved
ROUND: 1 / 1

## Review Metadata
- **PR:** https://github.com/HiQS-Labs/XYZ-forge/pull/1440
- **Reviewed HEAD:** `eb309c66668e85c14cd731705119b877078eb721`
- **Base:** `development` (`43265eed2359f781f942543af74c6d12c990cf00`)
- **Reviewer:** Agy (Gemini 3.8 Flash)
- **Reasoning Effort:** high
- **Review Scope:** Combined #1436 (malformed contract isolation & intake) and #1437 (gate Python environment refusal), including 4 CodeRabbit follow-ups after original Codex QA approval.
- **Evaluation Standard:** Commensurate-complexity criteria, local single-repo CLI scope (no enterprise machinery), relay-xyz protocol.
- **Test Execution Attestation:** Read-only inspection of committed receipts, code diffs, logs, and controls; no test execution or relay-drive attestation claimed.

---

### Reviewer · Round 1

swept file: yes

#### Graded Findings

- [Pass] **(1) Malformed contract isolation & resilient planning:**
  - `utils/py/swarm_preflight.py:54-87`: `contract_shape_error(obj)` performs robust shape validation on outer container (`dict`), `target` object (`repo` and `ref` strings), `fix_probes` (list of probe dicts with string fields `type`, `path`, `pattern`, `command`), `artifacts` / `artifacts_new` (list of non-empty strings), and `lanes` (`agy_safe`, `orchestrator_only`, `index_only` lists of non-empty strings) without imposing execution-only requirements.
  - `utils/py/_marathon_plan.py:484-488`: In `Engine._extract_contract`, `contract_shape_error` is invoked on parsed JSON. Any shape error returns `(None, error)`; JSON decode failure returns `(None, "invalid JSON contract")`.
  - `utils/py/_marathon_plan.py:1139, 1146, 1171-1181`: When `contract_error` is present, `contract` is held as `None`, preventing downstream dereference crashes in `_zone_of` and probe evaluation. Active items receive `r["state"] = "needs-contract"`, log a warning with flag `malformed-contract: <error>`, and `continue`, holding the item safely. Unrelated PR reconciliation proceeds unblocked. Verified by `TESTS-RESULTS/2026-11-12+GH-1436-1437/wave-reconcile.log` and `gh168-wave-reconcile-scope.log`.

- [Pass] **(2) Terminal states preserved & issue-body invalid JSON attributed:**
  - `utils/py/_marathon_plan.py:1172-1181`: Resolves CodeRabbit finding. For records in terminal sections (`Completed` or `Deferred · vision`), `terminal` is set to `True`. The item is flagged with warning `malformed-contract`, but does not demote to `needs-contract`. Instead, its state is preserved as `completed-ref` or `deferred`. Crucially, it does not `continue`, allowing lines 1198-1205 to execute and surface the `closed-drift` warning if the GitHub issue remains OPEN.
  - `utils/py/_marathon_plan.py:183-191, 217-218, 236`: Resolves CodeRabbit finding. In `_unregistered_record`, invalid JSON in an issue body Preflight Contract block catches `ValueError`, explicitly sets `contract_error = "invalid JSON contract"`, sets `state = "needs-contract"`, and exposes `contractError` in the record dictionary. Verified by `TESTS-RESULTS/2026-11-12+GH-1436-1437/review_controls.py` and `review_controls-green.log`.

- [Pass] **(3) HQ intake rejection of malformed shapes & unterminated JSON fences:**
  - `utils/hq/hq.sh:325-343`: Resolves CodeRabbit findings and preserves intake safety. Validates supplied contracts before any GitHub issue creation or capture file writes.
  - Regex `r"^#{1,6}[ 	]+[^
]*preflight[ 	]+contract[^
]*
(.*?)(?=^#{1,6}[ 	]|\Z)"` bounds the heading to a single line (`[^
]*
`) and matches content strictly up to the next Markdown heading or EOF, preventing multiline swallowing of subsequent headings or prose.
  - If no preflight contract heading exists, or if a heading exists without a JSON block (placeholder), Python exits 0 and HQ park proceeds normally.
  - If an opening JSON fence (````json`) is unterminated, `not block and re.search(r"^```json[ 	]*$", match[1], re.I | re.M)` catches it and exits with `"hq park: malformed-contract: unterminated JSON contract"`.
  - If JSON is malformed or violates `contract_shape_error`, it exits with `"hq park: malformed-contract: " + error`.
  - All checks reject before writes (`created="$(date +%F)"`). Verified by `TESTS-RESULTS/2026-11-12+GH-1436-1437/hq-following-prose-green.log`, `review_hq-green.log`, and `hq-park.log`.

- [Pass] **(4) Optional-null markers remain safe through extraction & merging:**
  - `utils/py/swarm_preflight.py:73-75`: `if key == "artifacts_new" and obj.get(key) is None: continue` ensures `artifacts_new: null` passes shape validation.
  - `utils/py/swarm_preflight.py:219, 238`: `merge_contracts()` uses `base.get("artifacts_new") or []` and `c.get("artifacts_new") or []`, preventing `TypeError: 'NoneType' object is not iterable` when merging contracts with explicit null markers. Verified by `TESTS-RESULTS/2026-11-12+GH-1436-1437/optional-null-green.log`.

- [Pass] **(5) Fail-fast gate refusal for unsuitable Python environment:**
  - `validate.sh:1033-1043`: Replaces advisory yaml warning with an early gate refusal before any suite execution. Probes Python version for `>= (3, 10)` and checks imports for `yaml`, `pytest`, `requests`.
  - If unsuitable, prints:
    `ENVIRONMENT FAULT: python3 (<path>) version <version>; missing modules: <missing>; requires Python >=3.10 with yaml/pytest/requests — rerun with PATH="$HOME/.cache/xyz-forge-test-venv/bin:$PATH" bash validate.sh (retain your arguments); NOT promotion evidence (GH-732)`
    and exits with `exit 3`.
  - Preserves PHP handling (`validate.sh:1026-1031`).
  - Documented in `README.md:285-288`.
  - Covered by `test/gh251-validate-pytest-skip.sh:57-81` and `test/baselines/GH-139-pipe-grep-baseline.txt`. Verified by `TESTS-RESULTS/2026-11-12+GH-1436-1437/environment-green.log`, `python39-red.log`, and `gh251-fixed.log`.

- [Pass] **(6) Scoped ledger repair of GH-1430 merge history:**
  - `releases.sql` (commit `4c85ee2a7ff5814fb35e78537fae83f26a8c4700`): Eliminates the synthetic `rmi-01M78AG095YE20R1K8YYP5X1BJ` row created during an earlier merge conflict.
  - Restores exact original `roadmap_items` row for GH-1430 (`rmi-01M76X72NHMNF7VAT0WMP8JSCA`, `first_seen` 2026-11-12T03:35:55Z, `updated_at` 2026-11-12T16:30:12Z) and three original `work_events` (`wev-01M76X72PAXVP97JE9M34DADSX` parked, `wev-01M76XCDZK898DGAQ8PZMJQKW8` in_flight, `wev-01M789GTMR9RHJBT8CZFGCFCG8` completed) byte-for-byte from development `43265eed2359f781f942543af74c6d12c990cf00`.
  - All non-GH1430 business rows remain strictly identical. Historical operation receipts are preserved, and one new `merge-rebuild` receipt (`43134cabd43a4f6183c4ba603dddaed6`) is recorded by canonical `utils/releases-merge-resolve.sh`.
  - Verified by committed rehearsal and verification artifacts: `TESTS-RESULTS/2026-11-12+GH-1436-1437/gh1430-history-rebuild.log` and `gh1430-history-restoration.json`. Operator one-time authorization documented; CodeRabbit confirmed and resolved thread.

- [Pass] **(7) Bounded scope, zero bloat, no new suites/dependencies:**
  - Scope is strictly confined to single-repo CLI requirements: no new test suites, runners, dependencies, or schema changes.
  - Issue #1436 acceptance criteria specify intake validation (`hq park` OR `pdda.sh`); HQ park rejection before writes satisfies this requirement without expanding scope to every authoring skill.
  - Head `4c85ee2a` passed full normal pre-push gate (408/408 in 646s). Head `eb309c66` adds only review evidence and passed the documentation gate in 90s. Hosted checks are passing.

---

## VERDICT: Approved

**Basis:**
The PR at head `eb309c66668e85c14cd731705119b877078eb721` cleanly fulfills all requirements of issues #1436 and #1437 with surgical, high-quality, commensurate changes. All four CodeRabbit follow-up items (unterminated JSON fence handling, issue-body JSON error attribution, terminal state preservation with open-drift detection, and exact GH-1430 merge history restoration) were properly diagnosed, implemented, verified with discriminating red/green controls, and covered by full gate runs. No blocking issues, regressions, or scope leaks exist.

Note: The reviewing agent does not merge or watch PRs. The PR is ready for operator landing.
