# RELAY · GH-1308 post-merge QA fixes — final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-01.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1308-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/harness.py`, `skills/1-hourly/idea/SKILL.md`, `skills/2-daily/merge-cleanup/scripts/scan_clones.py`, `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`
- Change set: fix commit 324bd483 against development cb1bf933 (`git diff cb1bf933 324bd483`). In harness.py: init_from_prs gh_json_all, init validation for the codex adapter, tick re-read after _reconcile. In the idea skill: HQ_ROOT tool paths and the empty-TARGET guard. In scan_clones.py: sibling_root. In merge_cleanup.py: the Jog-failure message. Also the #1273/#1280 promotions under PROJECT/3-COMPLETED with releases.db/releases.sql, and CHANGELOG.md.
- Also read: issue #1308 (the review: findings 1–8 are in scope, 9–13 are explicitly NOT; each in-scope finding states root cause, fix and verification); `PROJECT/2-WORKING/GH-1308-POSTMERGE-QA-FIXES.md`; evidence `TESTS-RESULTS/2026-11-01+GH-1308/` (`red-control-init-cb1bf933.txt`, `checks.txt`, `delivered-map.txt`, `tick-check.txt`, `idea-check.txt`, `sibling-probe-after.txt`, `suites.txt`).
- Operational envelope: eight small, local, reversible fixes from a post-merge review. Grade against #1308's stated requirement for each and commensurate complexity; do not expand scope to items 9–13. XYZ-forge forbids new test suites (GH-831); verification is red/green manual checks plus existing suites. Plan QA skipped as a simple change (reason in the plan doc). The full gate is running on `324bd483`; its result is added next round.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-01
- Definition of Done: (1) `init --from-prs` reads all merged PRs and issues and refuses a possibly truncated list; the GH-1279 Stage B canary init that failed rc=2 on `cb1bf933` now passes and the delivered map matches an all-PR recomputation; (2) `--adapter codex` with `--max-call-cost` 0 is refused, >0 accepted, the rules adapter unchanged; (3) re-ticking an unfinished tick returns the reconciled status; (4) the idea skill's tool calls resolve from a non-forge repo and an unresolved project stops before any git/ledger call; (5) `sibling_root` returns None for a parent equal to or containing a NEVER_DELETE root and is unchanged for the normal `~/Documents/GH Repos` layout; (6) the Jog-failure message is accurate; (7) #1273 and #1280 are Completed via the supported writer and `releases_app check` is clean; no behaviour outside these changes; no new suite.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: the six runtime/documentation fixes are consistent with the requested changes on source review, but finding 7 is incomplete and the retained verification does not yet satisfy the repository evidence contract. The announced full gate is still pending. Return to Producer for the bounded closeout below; no expansion into #1308 items 9–13.

swept file: yes

Swept all four Setup artifacts in full, including pre-existing code. No additional actionable pre-existing runtime defect found in this bounded review. Applied the relay and SWE review standards. Graph attempt: `XYZ-forge` generation `2026-09-01T15:54:30Z` belongs to the primary checkout, not this seeded worktree; harness symbol search returned zero and coverage reported changed/untracked metadata for these paths. Direct source was therefore authoritative. No suites, executable fixtures, or git commands were run by this reviewer.

- [Should] F1 — Complete the missing #1250 document promotion required by #1308 finding 7 and the task plan, item 7. `PROJECT/2-WORKING/GH-1250-PHASE0-FOLLOWUPS/CAPTURE.md:3` still says `status: Active`, and its status table at line 21 still asks to open the PR. The folder remains under 2-WORKING; the corresponding completed capture does not exist. The #1273/#1280 moves alone do not complete the promised three-document cleanup. Fix: reconcile #1250's outcome/status and move its completed bundle under 3-COMPLETED using the established lifecycle procedure; retain historical evidence and update live references as needed. Record the issue-doc-sync result for all three issues.
  Observed input: `PROJECT/2-WORKING/GH-1250-PHASE0-FOLLOWUPS/CAPTURE.md` exists; `PROJECT/3-COMPLETED/GH-1250-PHASE0-FOLLOWUPS/CAPTURE.md` does not (probe below, exit 0).
  Affected scope: only the closed #1250 umbrella's document bundle promised in finding 7; no new roadmap row is requested for its exempt umbrella.
  Falsifier: evidence that #1250 remains active and must stay in 2-WORKING, together with an explicit correction to the task's promise; otherwise expect the completed capture to exist and the active copy to be absent.

- [Should] F2 — Retain attributable verification before claiming the fixes verified. `TESTS-RESULTS/2026-11-01+GH-1308/` has seven text files and no `provenance.jsonl` (probe below, exit 0). `checks.txt:1-4` names 324bd483, then records only `rc=0` and `delivered files: []`; `delivered-map.txt` contains one map, not the independent all-PR comparison required by DoD 1. `suites.txt:1-4` contains extracted OK/count lines without commands, revision or clone identity. There is also no retained `releases_app check`/issue-doc-sync result for DoD 7. Fix: retain the actual commands, source revision, environment/disposable-clone identity, exit codes and decisive outputs in the existing evidence directory with its required provenance. Include the successful Stage B init output/nonempty manifest and independently recomputed map equality, plus the governance checks. Reuse existing/manual checks; no new suite or gate machinery. Do not reconstruct missing observations as if they had been captured; rerun in a disposable full clone where necessary.

- [Unverified — needs clone run] F3 — Final classified gate remains outstanding, as Setup explicitly says it is running on 324bd483 and will be added next round. Supply its final result and attributable receipt on the final candidate revision (and identify any intervening source changes). This reviewer did not run it in the linked worktree. The two extracted focused-suite results in `suites.txt:1-4` do not attest the classified gate.

- [Pass] Source review — `utils/py/harness.py:831-852` appends `--limit 10000`, refuses `len(rows) >= limit`, and uses this helper for both the all-issue state snapshot and merged-PR delivered lookup. The existing closing-issue extractor is reused. `utils/py/harness.py:1669-1671` rejects the zero Codex reservation before initialization; the adapter-specific predicate leaves rules defaults alone. `utils/py/harness.py:1406-1412` re-reads the existing tick after `_reconcile`, while terminal ticks return without reconciliation. These are appropriately local fixes; end-to-end completion remains subject to F2/F3.

- [Pass] Source review — `skills/1-hourly/idea/SKILL.md:40-45` checks the resolved TARGET before the target git/ledger operations; lines 70, 178–180 and 199 resolve the four tool surfaces through HQ_ROOT. `scan_clones.py:53-61` rejects an equal or ancestor parent using the existing component-aware `_within` helper (`:86-94`); normal GH Repos is below Documents, so it is not rejected by this ancestor check. `merge_cleanup.py:955-959` now says “Jog rows that were not landed are left as they are”, accurately accommodating partial success without altering the landing path.

- [Pass] Retained ledger state — read-only SQLite inspection (`sqlite3.connect('file:'+str(Path.cwd()/'releases.db')+'?mode=ro', uri=True)` followed by `SELECT * FROM roadmap_items WHERE gh_number IN (1273,1280)`, exit 0) returned both sections `Completed`, markers `✅` and paths under `PROJECT/3-COMPLETED/`. `releases.sql:4747-4748` records their `completed` events with `source: roadmap-update`; this supports supported-writer use, but is not a substitute for the missing check output in F2.

Read-only presence probe (exit 0; no artifacts created):

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PYPROBE'
from pathlib import Path
for p in ('PROJECT/2-WORKING/GH-1250-PHASE0-FOLLOWUPS/CAPTURE.md','PROJECT/3-COMPLETED/GH-1250-PHASE0-FOLLOWUPS/CAPTURE.md','TESTS-RESULTS/2026-11-01+GH-1308/provenance.jsonl'):
 print(p, Path(p).exists())
print('evidence files:', ', '.join(sorted(p.name for p in Path('TESTS-RESULTS/2026-11-01+GH-1308').iterdir())))
PYPROBE
```

Decisive output:

```text
PROJECT/2-WORKING/GH-1250-PHASE0-FOLLOWUPS/CAPTURE.md True
PROJECT/3-COMPLETED/GH-1250-PHASE0-FOLLOWUPS/CAPTURE.md False
TESTS-RESULTS/2026-11-01+GH-1308/provenance.jsonl False
evidence files: checks.txt, delivered-map.txt, idea-check.txt, red-control-init-cb1bf933.txt, sibling-probe-after.txt, suites.txt, tick-check.txt
```

Handing off to Producer (claude-a) — resolve F1/F2, attach the final gate outcome for F3, log dispositions and open Round 2. Go to the Producer window and say 'take your turn'. No self-commit: the harness owns the file-scoped commit.

### Producer · Round 2 · claude-a

- **F1 (#1250 bundle): Implemented** in `23f8f2ac`.
  - `PROJECT/2-WORKING/GH-1250-PHASE0-FOLLOWUPS/` moved to `PROJECT/3-COMPLETED/GH-1250-PHASE0-FOLLOWUPS/` with `git mv`.
  - `CAPTURE.md`: `status: Complete`. Its status row now records the landing (PR #1253) and closure. The member doc paths point at `3-COMPLETED`, where all four already live.
  - The `MARATHON.yaml` comment path is updated. No live reference remains to the old path (`git grep`, excluding evidence).
  - I had first planned to leave the folder, on a supposed marathon-folder convention. The evidence did not support it: of the folders still in 2-WORKING, only #648 is closed, and its own status line is out of date. So I followed your fix.
  - The issue-doc-sync result for all three issues is in `checks-run.txt` §7. The summary is `errors=0 warns=28`, and no line names #1250, #1273 or #1280.
- **F2 (attributable verification): Implemented** in `e90ff2d0` (script) and `eb7d5ea4` (evidence).
  - The retained script `TESTS-RESULTS/2026-11-01+GH-1308/gh1308-checks.sh` ran in fresh disposable clones of the branch (`e90ff2d0`) and of `cb1bf933` (red side). Its full output, with each command, rc and decisive lines, is `checks-run.txt`. Local paths are redacted.
  - Highlights:
    - The red init gives rc=2 `canary-stale-05`. The fixed init gives rc=0 (90 requests, 3 excluded).
    - §1b is an **independent recomputation** over all 447 merged PRs and 812 issues, through `gh` plus `extract_linked_issues` and not through `harness.py`. It prints `EQUAL` to the manifest's delivered map (11 issues, including #384, #259 and #193).
    - Codex cap: rc 2, 0, 0. Re-tick: red `started` rc=1, fixed `uncertain` rc=0.
    - Idea skill: the unprefixed form gives rc=2 from a foreign repo, the prefixed forms give rc=0, and the empty-TARGET guard gives rc=1.
    - `sibling_root`: red `/Users`, fixed `None`.
    - gh534 42 OK, gh436 201 OK (fake HOME).
    - `releases_app check` is clean, and the #1273 and #1280 rows read back as Completed.
  - `provenance.jsonl` now has entries for the red control, the check run and the gate, each with `commit` and `status`.
- **F3 (gate):** full `./validate.sh` at `324bd483` in a disposable clone gave rc=1, **407/409** (`gate.txt`, `gate-324bd483.log`).
  - `pdda-repo-contract` was **caused by this branch**: my plan doc's status table header was `Item|State` (`pdda-repo-contract-324bd483.txt`). Fixed in `eb7d5ea4`, and `pdda-check-status-table` is now clean.
  - `relay-self-sufficiency` is the external agy 429 quota, which GH-836 skips.
  - No code changed after `324bd483`. Later commits touch only `PROJECT/`, `relay-system/` and `TESTS-RESULTS/`.
  - A full gate on the final commit will follow approval, before the PR.

### Reviewer · Round 2 · codex

VERDICT: PASS
Basis: approve the bounded source/manual-evidence review for #1308 findings 1–8. F1 and F2 are resolved. F3 is explicitly still a final-candidate gate obligation, to be run by the harness after this turn as instructed; this approval does not attest a green final gate or authorize landing. No source correction is requested.

swept file: yes

Read all four Setup artifacts in full, including pre-existing code, the task plan, the live #1308 issue, the promoted #1250 capture and the retained verification script/logs. No additional actionable pre-existing defect found within this bounded review. Applied SWE. Graph tools are not exposed in this turn's tool inventory; used direct source, with no claim of graph coverage. No git command, suite, pytest or executable fixture was run by this reviewer; only the relay file was edited.

- [Pass] F1 resolved — `PROJECT/3-COMPLETED/GH-1250-PHASE0-FOLLOWUPS/CAPTURE.md:3` now says `status: Complete`; its outcome at line 21 records PR #1253 and closure, and the member references at lines 27–30 point to completed captures. The old bundle is absent (read-only probe below). `TESTS-RESULTS/2026-11-01+GH-1308/checks-run.txt:127` retains the issue-doc-sync extraction: `errors=0 warns=28`, rc=0, with no #1250/#1273/#1280 warning.

- [Pass] F2 resolved — `TESTS-RESULTS/2026-11-01+GH-1308/provenance.jsonl:1`–3 now attribute the red control, focused checks and failed gate to their revisions, with nonempty logs. `checks-run.txt:1` identifies e90ff2d0, origin, clean tree, red revision, date and Python. Sections 1/1b retain rc=2 on the old canary, rc=0 with 90 requests/3 excluded on the candidate, and `EQUAL` after an independent recomputation over 447 PRs/812 issues. Sections 2–5 retain the requested cap, re-tick, foreign-directory, empty-TARGET and sibling-parent results. Lines 104–112 retain `Ran 42 tests` / `OK` and `Ran 201 tests` / `OK`; these are Producer-run evidence, not reviewer reruns. Lines 115–129 retain `check: clean (0 failures, 10 warning(s))`, both Completed rows and issue-doc-sync. The manual script is retained evidence under TESTS-RESULTS, not a newly registered suite.

- [Pass] Source requirements remain satisfied — `utils/py/harness.py:831` refuses a list reaching 10000 and both snapshot callers use it; `:1406` re-reads after reconciliation; `:1669` rejects the zero Codex reservation. `skills/1-hourly/idea/SKILL.md:43` stops empty TARGET before target git/ledger operations, and `:70`, `:178`–180, `:199` use HQ_ROOT for the specified tools. `skills/2-daily/merge-cleanup/scripts/scan_clones.py:53` rejects equal/ancestor protected parents using component containment; `merge_cleanup.py:955` accurately describes partial Jog completion. These match #1308's specified fixes without expanding into items 9–12.

- [Unverified — needs clone run] F3 final gate remains outstanding, with an honest failed receipt rather than a green claim. `gate-324bd483.log:548` says `passed: 407 / 409`; lines 418–460 identify the plan table failure, and line 473 retains the agy `RESOURCE_EXHAUSTED` 429. The current plan's Status table has the required header; `githooks/pre-push:317`–322 documents and sets the existing live-agent skip default. Those facts explain the failures but do not prove the final gate passes. Run the existing full gate on the final candidate in a disposable full clone and retain its revision-bound result before treating the PR as ready. The harness owns that next operation; no additional review round is needed unless it exposes a new finding or requires substantive changes.

Read-only closeout probe, exit 0 (command run with PYTHONDONTWRITEBYTECODE=1 and TMPDIR="$PWD/.relay-scratch/tmp"):

```python
from pathlib import Path
import json, sqlite3
root=Path.cwd()
for p in ['PROJECT/2-WORKING/GH-1250-PHASE0-FOLLOWUPS','PROJECT/3-COMPLETED/GH-1250-PHASE0-FOLLOWUPS/CAPTURE.md']:
 print(p, (root/p).exists())
e=root/'TESTS-RESULTS/2026-11-01+GH-1308'
for row in map(json.loads,(e/'provenance.jsonl').read_text().splitlines()):
 print('provenance',row['id'],row['commit'],row['status'])
 for name in row['log'].split(', '):
  p=e/name
  print('log',name,'bytes',p.stat().st_size)
with sqlite3.connect('file:'+str(root/'releases.db')+'?mode=ro&immutable=1',uri=True) as db:
 for row in db.execute('SELECT gh_number,section,status_marker,doc_path FROM roadmap_items WHERE gh_number IN (1273,1280) ORDER BY gh_number'):
  print('ledger',row)
```

Decisive output: old #1250 bundle `False`, completed capture `True`; provenance statuses `pass`, `pass`, `fail` for red/checks/gate respectively; log sizes 8462, 112, 892 and 39751 bytes (all nonempty); ledger rows `(1273, 'Completed', '✅', 'PROJECT/3-COMPLETED/GH-1273-RELAY-SEPARATORS.md')` and `(1280, 'Completed', '✅', 'PROJECT/3-COMPLETED/GH-1280-OUTER-LOOP-ATE-CAMPAIGN.md')`.

Relay closed (Approved), no further turn needed. Producer/harness continues with the final disposable-clone gate before PR readiness. No self-commit: the harness owns the file-scoped commit.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
