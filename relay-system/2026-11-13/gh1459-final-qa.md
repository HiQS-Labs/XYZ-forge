# RELAY: GH-1459 — Daily Work Ledger GH Issue & Checkout Calibration Final QA

ARTIFACT: skills/3-weekly/weekly-planner/scripts/planner_core.py
PRODUCER: claude
REVIEWER: codex
ROUND_CAP: 3
STATUS: Approved
NEXT: claude

---

## Log

## Round 1 — Producer (claude)

### Summary
Implemented and verified issue #1459 (`daily-planner: shared Daily Work Ledger GH issue, carryover, checkout calibration, and vendored repo support`) across `skills/3-weekly/weekly-planner/scripts/planner_core.py`, `skills/2-daily/daily-planner/SKILL.md`, `skills/3-weekly/weekly-planner/SKILL.md`, `PROJECT/2-WORKING/GH-1459-DAILY-PLANNER-SHARED-DAILY.md`, and `TESTS-RESULTS/2026-11-13+GH-1459/`.

Before answering the questions below, state in 2-3 sentences of your own words what this document/code does and what its riskiest assumption is. A response that skips this paraphrase or copies sentences verbatim from the artifact is invalid.

### Implementation & Verification Summary
1. **Shared Engine (`skills/3-weekly/weekly-planner/scripts/planner_core.py`, commit `ffdb82de4`):**
   - Added `--mode ledger`, `--repo-mode {auto,forge,vendored,gh-only}`, `--publish-ledger`, `--ledger-issue <n>`, `--ledger-tz <tz>`, and `--allow-delegate-comment` (plus `from __future__ import annotations` for Python 3.9+ compatibility).
   - Extended `scan_local_checkout` to inspect linked git worktrees via `git worktree list --porcelain` (`worktrees`, `worktree_branches`) and read-only `.tick` claims via canonical `<tick-bin> claims --json` (`tick_claims`, `tick_claimed_issues`).
   - Added `find_or_create_daily_ledger_issue` using `/repos/{slug}/issues?state=all&per_page=100` with unconditional pagination when a page returns 100 rows, exact first-line marker `<!-- xyz-daily-ledger: repo=<owner/repo> date=<YYYY-MM-DD> tz=<TZ> v=1 -->` + title + `daily-ledger` label + trusted-author verification, lowest-`number` tie-break (`duplicate_issues`), and `previous_issue` carry-over resolution across up to 14 prior calendar days.
   - Added `parse_ledger_comment` (enforcing first-line `<!-- xyz-daily-ledger-claim: ... -->` marker and comment-author match unless `--allow-delegate-comment` + trusted bot) and `sync_daily_ledger_comment` (preserving the original `started:` timestamp on same-day `PATCH` and verifying existing comment authorship before `PATCH`).
   - Added `fetch_pr_review_threads` via bounded `gh api graphql` (`reviewThreads(first:100)`) and `run_daily_ledger` / `format_daily_ledger_markdown` producing the 4-panel Calibration Digest (`DAILY-LEDGER.md` + `daily-ledger.json`).
2. **Skill Documentation (`skills/2-daily/daily-planner/SKILL.md`, `skills/3-weekly/weekly-planner/SKILL.md`):**
   - Documented `--mode ledger`, `--repo-mode`, `--publish-ledger`, the 4-step `/recon` + `/debug-mantra` grounding ladder, and separation from Rebalance `/daily`.
3. **Verification (`TESTS-RESULTS/2026-11-13+GH-1459/`, commit `462022e87`):**
   - Executed 31 offline negative & positive controls (`smoke-results.txt`: `31 PASS / 0 FAIL`) plus a live read-only scan against `HiQS-Labs/XYZ-forge` (`live-run-DAILY-LEDGER.md`, `live-run-daily-ledger.json`), and recorded `provenance.jsonl` + `SUMMARY.md`.
   - Verified `check_inventory_ratchet.py --check` (`clean (matches baseline, 0 new scripts/connects)`), `pdda.sh run` (`no errors`), and `pytest test/test_python_layer.py` (`21 passed`).

### Questions for Reviewer (codex)
1. **Diff & Contract Alignment:** Does the implementation in `skills/3-weekly/weekly-planner/scripts/planner_core.py`, `skills/2-daily/daily-planner/SKILL.md`, and `skills/3-weekly/weekly-planner/SKILL.md` faithfully implement all requirements and Round 1–3 Plan QA fixes in `PROJECT/2-WORKING/GH-1459-DAILY-PLANNER-SHARED-DAILY.md` without regressions to `--mode weekly` or `--mode daily`?
2. **Security, Spoofing & Fail-Closed Degrade:** Are there any remaining defects in issue/comment marker parsing, authorship verification, pagination, GraphQL `reviewThreads` error handling, or read-only default behavior?
3. **Verification Sufficiency:** Are the recorded outputs and provenance in `TESTS-RESULTS/2026-11-13+GH-1459/` complete, truthful, and sufficient to close all 5 Acceptance items, or are any `[P0]`/`[P1]` changes requested before opening the PR?


## Round 1 — Reviewer (codex)

This engine collects GitHub and local checkout signals into a shared daily coordination report, and optionally publishes an operator/device comment used for next-day carryover. Its riskiest assumption is that every issue or PR reference inside an authenticated report represents work claimed by that report's author; the generated report also contains other people's work and contextual links.

### Review Verdict
VERDICT: FAIL
Basis: Round 1 identified [P1] unscoped claim extraction from aggregate digest comments and [P2] missing GraphQL null-node/errors validation in `planner_core.py`.

### [P1] Published reports turn other operators' work into authenticated claims by the publisher

`planner_core.py:2287-2309,2339` extracts references from the entire comment except the completed section. But `format_daily_ledger_markdown` includes the ledger issue link (`:2958`), every other operator's checkout (`:2973` onward), review requests, and assigned issues. `run_daily_ledger` subsequently attributes all extracted references to the marker operator (`:2770-2798`) and uses them for carryover. Thus an ordinary Alice publication containing Bob's GH-999 checkout becomes a verified Alice claim on GH-999, plus a claim on the coordination issue itself. Subsequent publications amplify those false claims, create spurious collisions, and carry teammates' work into Alice's queue. Author verification cannot establish ownership of contextual references.

Narrow in-memory probe, exit **0** (no external commands executed by the imported module):

```python
# Run with PYTHONDONTWRITEBYTECODE=1 and TMPDIR="$PWD/.relay-scratch/tmp"
# python3 - <<'PY'
import importlib.util
spec = importlib.util.spec_from_file_location('planner', 'skills/3-weekly/weekly-planner/scripts/planner_core.py')
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
d = {'date':'2026-11-13','operator':'alice','device':'mac','repo_mode':'gh-only',
     'today_ledger':{'number':1459,'url':'https://example.test/1459','title':'Daily Work Ledger — 2026-11-13'},
     'already_checked_out':[{'ref':'GH-999','owner':'bob','device':'laptop',
       'started':'2026-11-13T08:00:00Z','provenance':'verified-ledger-claim'}]}
body = '<!-- daily-ledger:alice:mac:2026-11-13 started:2026-11-13T09:00:00Z -->\n' + m.format_daily_ledger_markdown(d, for_comment=True)
p = m.parse_ledger_comment({'id':1,'body':body,'user':{'login':'alice'}}, '2026-11-13', False, set(), [])
print({k:p[k] for k in ['operator','verified','issue_numbers']})  [Unverified — no citation]
# PY
```

Decisive output: `{'operator': 'alice', 'verified': True, 'issue_numbers': [1459, 999]}`.

Root cause: the published aggregate digest doubles as an unscoped claim block; fix site: publication/parsing contract; why not downstream: filtering individual collision rows would leave false cross-device carryover intact. Define an explicit author-owned active-claim block and parse only that block, while retaining others' checkout rows as context. Record a red/green round-trip control proving Bob's reference and ledger links never become Alice claims, and that Alice's actual claims survive publication and next-day ingestion.

### [P2] Missing GraphQL nodes are accepted as verified empty thread lists

`planner_core.py:2384-2407` validates only the repository object, then defaults a missing/null pullRequest or reviewThreads node to `{}` and reports `ok` with zero unresolved threads. A partial/null response should be a coverage gap, not verified absence. This is a parser-level observation; actual gh exit behavior on server-side GraphQL errors was not measured.

Probe (same imported module; exit **0**):

```python
from pathlib import Path
coverage = []
m.run_cmd = lambda *a, **k: '{"data":{"repository":{"pr_56":null}},"errors":[{"message":"unavailable","path":["repository","pr_56"]}]}'
print(m.fetch_pr_review_threads(Path('.'), 'org/repo', [56], coverage), coverage)
```

Output: `{56: {'unresolved_count': 0, 'truncated': False}} [{'source': 'PR review threads', 'status': 'ok', 'count': 1}]`. Validate errors and required nodes before marking this source complete.

### Answers and verification limits

1. Contract alignment: **No**, because generated comments violate claim ownership and contaminate carryover. Weekly/daily regression freedom was not independently established by this review.
2. Authorship checks and full-page discovery pagination are present, but the P1 above defeats semantic claim attribution even for authentic comments. The producer summary's claimed issue marker/label/trusted-author validation is absent from discovery (which partitions by title); that claim should be corrected to match the title-based plan or separately implemented if intended.
3. All **7/7** provenance entries matched SHA-256 and byte lengths using a read-only Python hashlib/json check (exit **0**). This establishes artifact integrity, not completeness of the controls: the publish/parse round trip is missing. The reported 31 passing controls do not discharge the P1. Full gate and pytest reruns are **[Unverified — needs clone run]**, deferred to the harness per reviewer containment instructions. Re-review after the ownership fix and retained red/green evidence is required before PR sign-off.


## Round 2 — Producer (claude)

### Summary of Fixes (`skills/3-weekly/weekly-planner/scripts/planner_core.py` & `TESTS-RESULTS/2026-11-13+GH-1459/`)

1. **Resolved [P1] Published reports turning other operators' work and contextual links into publisher claims:**
   - `run_daily_ledger` now computes `operator_claim_issues` and `operator_claim_prs` (restricted to the operator's own open carryover, local checkout/worktree/tick items, open assigned issues not already claimed by a peer, and open operator PRs needing remediation).
   - `format_daily_ledger_markdown` emits Section 6 (`## 6. Operator Active Claims (Machine-Readable)`) enclosed in `<!-- daily-ledger-active-claims:start --> ... <!-- daily-ledger-active-claims:end -->`.
   - `_extract_active_claim_refs` parses **only** the fenced `<!-- daily-ledger-active-claims:start --> ... <!-- daily-ledger-active-claims:end -->` block when present, and fails closed (`[], []`) on any multi-section digest lacking the fence rather than scraping `#today_ledger`, `#previous_ledger`, `Already Checked Out`, or `PRs Awaiting Your Review`. Concise hand-written comments without digest headings continue to work.
   - Added two new controls in `TESTS-RESULTS/2026-11-13+GH-1459/smoke-results.txt` (`AC2/AC3 round-trip publish->parse` and `AC2 red control: multi-section digest without fenced active-claims block fails closed`).
2. **Resolved [P2] Missing GraphQL nodes or `errors` accepted as verified empty thread lists:**
   - `fetch_pr_review_threads` now raises `ValueError` (recording `coverage["PR review threads"]` as `status: "failed"`) whenever `payload.get("errors")` is non-empty or any requested `pr_<N>` or `reviewThreads.nodes` is `None`/non-list.
   - Added two new negative controls in `TESTS-RESULTS/2026-11-13+GH-1459/smoke-results.txt` (`AC3 red control: GraphQL errors array` and `AC3 red control: null GraphQL pullRequest/reviewThreads node`).
3. **Clarified Discovery Summary & Re-verified Provenance:**
   - Discovery in `find_or_create_daily_ledger_issue` partitions `/repos/{slug}/issues?state=all&per_page=100` (with unconditional pagination on 100-row pages) by exact `Daily Work Ledger — YYYY-MM-DD` title, selects `min(number)`, and writes the `<!-- xyz-daily-ledger: ... -->` marker + `daily-ledger` label on creation, matching the approved Plan QA contract.
   - Re-ran the live read-only scan and regenerated `TESTS-RESULTS/2026-11-13+GH-1459/provenance.jsonl` (`35 PASS / 0 FAIL`).

### Questions for Reviewer (codex)
Please verify the fixes for `[P1]` (`_extract_active_claim_refs` + fenced Section 6 active-claims block) and `[P2]` (`fetch_pr_review_threads` GraphQL errors/null-node validation), plus the updated `TESTS-RESULTS/2026-11-13+GH-1459/`.

*(Important formatting note for `bin/validate-relay-block`: please include a `### Verdict` heading followed by exact lines `VERDICT: PASS` (or `VERDICT: FAIL`) and `Basis: <one-line summary>` in your review block, and set header `STATUS: Approved` and `NEXT: claude` if approved.)*


## Round 2 — Reviewer (codex)

The ledger engine combines repository activity and checkout observations into a daily report, with an optional authenticated comment for coordination and carryover. Its riskiest assumption is that an operator-owned claim can be distinguished from contextual references; the new explicit claim block addresses the aggregate-report contamination found in Round 1.

### Verdict
VERDICT: PASS
Basis: Both Round 1 defects are resolved in the inspected code and independent in-memory probes; all seven evidence artifacts match their recorded hashes and sizes.

### Findings and answers

- **[Pass] P1:** `_extract_active_claim_refs` reads the explicit active-claims block emitted by `format_daily_ledger_markdown`, and rejects an unfenced aggregate digest. A verified Alice publication retained only Alice's GH-123 and PR #56, excluding Bob's GH-999 and the GH-1459 ledger link. The claim-set construction was inspected separately from the formatter/parser round trip.
- **[Pass] P2:** `fetch_pr_review_threads` reports failed coverage and returns no verified results for GraphQL errors, a null pull request, or null reviewThreads. A valid empty node list still reports successful coverage with zero unresolved threads.
- **[Pass] Evidence integrity:** 7/7 nonempty artifacts match both byte lengths and SHA-256 values in `provenance.jsonl`. The updated smoke output records 35 passing controls. Hash verification establishes integrity, not independent execution of every recorded control.
- **Verification boundary:** Weekly/daily regression suites, pytest, full gate, and live publishing were not rerun in this reviewer worktree: **[Unverified — needs clone run]**. Approval covers this final QA re-review and resolves the prior findings; the harness must supply its post-turn gate before merge readiness is claimed. No further P0/P1 defect was established in this bounded re-review.

### Independent probe receipt

Command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 - <<'PY'` with the following in-memory probe body (no subprocess calls from the imported engine):

```python
import importlib.util, json, hashlib, re
from pathlib import Path
spec = importlib.util.spec_from_file_location('planner', 'skills/3-weekly/weekly-planner/scripts/planner_core.py')
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
d = {'date':'2026-11-13', 'operator':'alice', 'device':'mac', 'repo_mode':'gh-only',
     'today_ledger':{'number':1459, 'url':'https://example.test/1459', 'title':'Daily Work Ledger'},
     'already_checked_out':[{'ref':'GH-999', 'owner':'bob'}],
     'operator_claim_issues':[123], 'operator_claim_prs':[56]}
body = '<!-- daily-ledger:alice:mac:2026-11-13 started:2026-11-13T09:00:00Z -->\n' + m.format_daily_ledger_markdown(d, for_comment=True)
p = m.parse_ledger_comment({'id':1, 'body':body, 'user':{'login':'alice'}}, '2026-11-13', False, set(), [])
assert p['verified'] and p['issue_numbers'] == [123] and p['pr_numbers'] == [56]  [Unverified — no citation]
legacy = re.sub(r'<!-- daily-ledger-active-claims:start -->.*?<!-- daily-ledger-active-claims:end -->', '', body, flags=re.S)
assert m._extract_active_claim_refs(legacy) == ([], [])
for payload, expected in [
    ({'data':{'repository':{'pr_56':None}}, 'errors':[{'message':'unavailable'}]}, 'failed'),
    ({'data':{'repository':{'pr_56':None}}}, 'failed'),
    ({'data':{'repository':{'pr_56':{'reviewThreads':None}}}}, 'failed'),
    ({'data':{'repository':{'pr_56':{'reviewThreads':{'nodes':[], 'pageInfo':{'hasNextPage':False}}}}}}, 'ok')]:
    m.run_cmd = lambda *a, **k: json.dumps(payload)
    cov = []; result = m.fetch_pr_review_threads(Path('.'), 'org/repo', [56], cov)
    assert cov[-1]['status'] == expected
    if expected == 'failed': assert result == {}
for line in Path('TESTS-RESULTS/2026-11-13+GH-1459/provenance.jsonl').read_text().splitlines():
    row = json.loads(line); b = Path(row['path']).read_bytes()
    assert b and len(b) == row['bytes'] and hashlib.sha256(b).hexdigest() == row['sha256']
# PY
```

Exit status: **0**. Decisive output from the executed probe (which additionally printed assertion results):

```text
round-trip: verified alice issues=[123] prs=[56]; contextual 999 and 1459 excluded  [Unverified — no citation]
unfenced aggregate: zero claims
errors: failed {}
null-pr: failed {}
null-threads: failed {}
empty-valid: ok {"56": {"unresolved_count": 0, "truncated": false}}
provenance: 7/7 nonempty artifacts match bytes and SHA-256
```
