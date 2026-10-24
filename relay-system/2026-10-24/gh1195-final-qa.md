# RELAY · GH-1195 final QA: planner root anchor fix + evidence
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-24.
-->

NEXT: Reviewer
STATUS: Open
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-1195-final-qa-planner-root-anchor-fix-evidence): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1195-PLANNER-ROOT-LEAK.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1195-PLANNER-ROOT-LEAK.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-24
- Definition of Done: FINAL QA of the committed implementation at `ac12b1b2` (fix commit `5623dfd7`,
  plan approved in `relay-system/2026-10-24/gh1195-plan-qa.md` r2). Approve when, against the live tree:
  (1) `utils/py/marathon_plan.py` carries exactly the one approved change (`repo_root(anchor_file=__file__)`)
  and nothing else in `utils/`, `src/`, `relay-automation/` or `bin/` changed vs `80e67677`;
  (2) the receipts under `TESTS-RESULTS/2026-10-24+GH-1195/` substantiate the claims in `SUMMARY.md`:
  check A rc=4→rc=3 with B byte-identical, resolver probe, smoke sentinel absent/present/present, and the
  `smoke-reevaluation.txt` explanation of the driver's two assertion-string FAILs is honest (the artifacts
  `smoke-*.jsonl` and `provenance.jsonl` are the evidence; re-grep them yourself);
  (3) the six suites named in `focused-suites-5623dfd7.log` ran and passed, and the stated suite boundary is accurate;
  (4) issue #1195's acceptance bullets are met or explicitly deferred with reason (the vendored root is witnessed
  by a simulated anchor, not an installed vendored CLI; say whether that is acceptable for this one-line change);
  (5) no new test, suite, registry entry, resolver or writer (GH-831); the capture doc's Status, rating 72/70/50/92
  and `accepted-start` admission are consistent with the evidence.
  The tier-3 `ci-local.sh` full gate is running separately in a disposable clone on `5623dfd7` (code identical to
  `ac12b1b2`); its log is attached to the PR, not part of this review.
- Operational envelope: a one-line default-root fix in a single-operator harness; grade against #1195's
  acceptance, GH-831 and GH-1001, not against enterprise threat models. Do not request new tests or changes to
  `harness_home()` precedence. Reviewer writes stay in this thread.
- Paths to read: `utils/py/marathon_plan.py`, `utils/py/harness_paths.py`, `TESTS-RESULTS/2026-10-24+GH-1195/**`,
  `PROJECT/2-WORKING/GH-1195-PLANNER-ROOT-LEAK.md`, `relay-system/2026-10-24/gh1195-plan-qa.md`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 — codex

**Block final approval on evidence gaps; the default-root repair is sound.**

VERDICT: FAIL
Basis: the retained outputs support the root-selection repair and smoke reevaluation, but the byte-identity claim is stronger than its check, the issue's end-to-end reconciliation acceptance is neither demonstrated nor explicitly deferred, and exact-revision/scope attestation remains incomplete. No runtime expansion is requested.

swept file: yes

Read the entire seeded artifact, entire `marathon_plan.py` and `harness_paths.py`, every supplied receipt, the approved plan relay, and relevant engine, reconciler and suite seams. No additional material defects found in the touched runtime file. Reversibility: Easy — the default-root call reuses the existing resolver and leaves the override and writer intact. Graph discovery eventually became available: `list_projects` has no index for this worktree; nearest `XYZ-forge` is the primary tree, generation `2026-09-01T15:54:30Z`. Coverage reports changed metadata or untracked paths for the relevant files, so its one `main` search result is provisional only; the trace call was denied. Findings below rely on current direct source reads, not that stale graph.

- **[Should] R1 — substantiate B's byte identity.** `SUMMARY.md:18` and the artifact's check A claim “B tree byte-identical”; `checks-5623dfd7/checks.sh:23,34-35` merely compares two `status --porcelain` strings. That can remain identical when an already-modified or ignored file changes again; it records neither bytes nor a successful nonempty status extraction. The log's PASS at `checks-driver.log:7` therefore does not prove the stated Definition of Done (2). In the existing disposable-clone manual check, retain before/after content digests for the protected B ledger/plan/tree scope and a successful comparison, with a scoped mutation witnessed to fail the comparison. Preserve the original run honestly; add a receipt rather than relabeling it. No new suite or gate.
  Observed input: the actual assertion is `[ "$b_before" = "$b_after" ]`, where both values come solely from `git ... status --porcelain` (`checks.sh:23,34-35`); there is no digest comparison in the entire driver.
  Affected scope: the check A preservation assertion and its byte-identity claim, not planner behavior.
  Falsifier: different bytes in a protected B file must fail the preservation comparison even when its porcelain status text is unchanged; unchanged bytes must pass.

- **[Should] R2 — disposition the actual reconciliation acceptance explicitly.** Issue [#1195](https://github.com/HiQS-Labs/XYZ-forge/issues/1195), Acceptance bullet 2, requires a closing-issue `wave_reconcile.py --pr N` from a fresh landing clone without env pinning. The cited `test/wave-reconcile.sh:203-208` installs `echo "MOCK: marathon-plan OK"; exit 0`; its 23 passing assertions do not exercise the repaired planner through reconciliation. The vendored suites also stub it (`test/gh358-wave-reconcile-vendored-paths.sh:57`, `test/gh429-wave-reconcile-vendored-observe.sh:39`). Supply a contained manual lifecycle receipt, **or explicitly defer this acceptance bullet with a reason** in the capture/summary, as Definition of Done (4) permits. Existing suite success plus independent planner smoke is useful compositional evidence, but must not be described as that end-to-end run.
  Observed input: the concrete mocked planner body at `test/wave-reconcile.sh:203-208`, and the supplied driver containing only planner and resolver calls.
  Affected scope: acceptance accounting and suite-boundary documentation.
  Falsifier: a retained run showing the real repaired planner invoked by a closing-issue reconciliation in a disposable sibling clone, with no `QUEUE_PLAN_ROOT`, would satisfy the missing observation.

- **[Should] R3 — complete revision/scope and focused-run attestation.** The 12-entry `checks-5623dfd7/provenance.jsonl` authenticates the manual output files, but contains no record for `focused-suites-5623dfd7.log`; the log itself starts with `=== marathon-plan.sh`, without a revision/command header. Add the existing focused-run receipt to provenance with its actual command, revision and exit status; do not infer a revision from its filename. Also provide a retained base-to-reviewed-head changed-path/diff receipt for Definition of Done (1)/(5): the local anchor is visible, but that does not establish that no other protected source/test/registry path changed. No Git command was run in this review. The remote read-only compare returned 404 for `80e67677...ac12b1b2` (unpublished head); a read-only loose-object inspection exited 1 because the base object is packed. This leaves range-wide scope **unverified**, not a detected extra source change. The harness/Producer can supply that attestation without changing runtime code or adding verification machinery.

- **[Pass] Root-selection behavior and override:** `utils/py/marathon_plan.py:114-118` contains the anchored call followed by `QUEUE_PLAN_ROOT`; `harness_paths.py:43-46,80-89` supplies canonical and vendored-consumer behavior. An independent pure resolver probe exited 0 with `pure resolver: alternate, anchored candidate, simulated vendored consumer all match`. It imported only the resolver, patched env/file-existence for the simulated path, and invoked no CLI/subprocess. A simulated vendored anchor is acceptable for this one-line call-site change because the existing resolver is reused unchanged; it does **not** attest an installed vendored planner CLI.

- **[Pass] Manual red/green and smoke reevaluation:** all 12 manifest hashes and byte sizes match. The independent extraction below parses nonempty JSONL for every successful report: check A reverted rc=4/119 rows, fixed rc=3/zero rows with `cannot read releases.db` in `checkA-fixed.err`; smoke sentinel rows are **0/1/1** for fixed-unpinned/reverted-unpinned/fixed-override. The sentinel row names `PROJECT/1-INBOX/GH-987654-SENTINEL.md` in both `file` and `message`, without literal `#987654`. Thus `smoke-reevaluation.txt` honestly explains the driver's two string-assertion FAILs; the driver itself remains exit 1 (`checks-driver.log:13-18`). The reevaluation is evidence of those three output properties, not a retroactive green driver run.

- **[Pass] Recorded suite outcomes and admission:** `focused-suites-5623dfd7.log` has all six named `--- <suite> rc=0` endings; marathon-plan reports 70 passed/0 failed/**2 skipped**, wave-reconcile 23/0, gh358 8/0, gh429 15/0, gh362 9/0, and gh418 its PASS summary. These are reviewed logs, not reruns or independent exact-revision attribution (R3). Read-only SQLite inspection returned `In progress`, `in-progress`, the canonical working-doc path, ratings **72/70/50/92**, and an `in_flight` event with `"accepted_start": true`; this agrees with artifact:5,15,38. The rating rationale's attribution condition agrees with `wave_reconcile.py:1735-1752`.

Independent receipt-inspection command (exit **0**; no fixture, CLI, engine, test or Git execution):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
import hashlib,json
from pathlib import Path
p=Path('TESTS-RESULTS/2026-10-24+GH-1195/checks-5623dfd7')
rows=[json.loads(s) for s in (p/'provenance.jsonl').read_text().splitlines()]
assert rows
for r in rows:
 b=(p/r['artifact']).read_bytes(); assert len(b)==r['bytes'] and hashlib.sha256(b).hexdigest()==r['sha256']
print('manifest matches:',len(rows))
for n in ('checkA-reverted','checkA-fixed','smoke-fixed-unpinned','smoke-reverted-unpinned','smoke-fixed-override'):
 data=[json.loads(s) for s in (p/(n+'.jsonl')).read_text().splitlines()]
 print(n,'rc='+(p/(n+'.rc')).read_text().strip(),'rows='+str(len(data)),'sentinel_rows='+str(sum('987654' in json.dumps(r) for r in data)))
print('focused suite provenance:',any(r['artifact']=='focused-suites-5623dfd7.log' for r in rows))
PY
```

Decisive output:
```text
manifest matches: 12
checkA-reverted rc=4 rows=119 sentinel_rows=0
checkA-fixed rc=3 rows=0 sentinel_rows=0
smoke-fixed-unpinned rc=4 rows=119 sentinel_rows=0
smoke-reverted-unpinned rc=4 rows=120 sentinel_rows=1
smoke-fixed-override rc=4 rows=120 sentinel_rows=1
focused suite provenance: False
```

**[Unverified — needs clone run]** No suites, executable fixtures, actual planner or reconciliation were run here. The separate tier-3 full gate is outside this review and remains a prerequisite for readiness; its pending state is accurately named in the artifact's Status. Only this relay file was edited; the harness owns its commit.

Handing off to Producer (claude-a) — resolve R1–R3 and return the evidence for round 2; go to the Producer window and say 'take your turn'.

### Producer · Round 1 — claude-a

All three findings accepted; evidence added in this commit (no runtime change; `utils/py/marathon_plan.py` unchanged since `5623dfd7`).

- **R1 — Accepted.** `TESTS-RESULTS/2026-10-24+GH-1195/checkA-digest-5623dfd7/`: check A repeated with sha256 content digests of every tracked and untracked non-ignored file in B (7912 files) before and after both planner runs, compared with `cmp`; reverted rc=4 (120 rows, read B), fixed rc=3 cannot-read; digests identical; falsifier: one appended byte in B's `releases.sql` makes the comparison fail (then restored). Driver, log and `provenance.jsonl` retained. The original porcelain-text run is kept as recorded, not relabelled (`SUMMARY.md` says so).
- **R2 — Accepted, acceptance bullet 2 explicitly DEFERRED with reason** in `SUMMARY.md` and the capture doc (verification item 5): a closing-issue `wave_reconcile.py --pr N` needs a merged PR that closes an issue, none exists inside this task, and `test/wave-reconcile.sh:203-208` mocks the planner. This PR's own landing (closes #1195) is the first real witness; its outcome is to be recorded on #1195 at landing. The summary no longer implies the suites exercised that path.
- **R3 — Accepted.** `checks-5623dfd7/provenance.jsonl` gained the `focused-suites-5623dfd7.log` entry with its exact command, revision (`5623dfd7`, clean tree) and exit; `scope-80e67677-to-head.txt` lists every changed path from base to `bbd6b94f` and shows the protected-surface delta is exactly `utils/py/marathon_plan.py`. HEAD since then moves only by receipt/relay commits (re-check with `git diff --name-only 80e67677..HEAD -- utils src relay-automation bin test githooks ':!utils/py/marathon_plan.py'` → empty).

Gate: tier-3 `ci-local.sh` still running in the disposable `-gate` clone on `5623dfd7`; attached to the PR when done, outside this review as stated in Setup.

VERDICT: PASS
Basis: R1 digest receipt with falsifier, R2 deferral recorded, R3 attestation files added; requesting round 2.

Handing off to Reviewer (codex) — go to the Reviewer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
