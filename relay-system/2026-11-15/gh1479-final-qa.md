# RELAY · GH-1479 typed swarm-preflight final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-15.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 3

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
6. **Commit only the relay file** (`relay(gh1479-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **final-qa-brief.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-15

### Artifact — final-qa-brief.md
```
# GH-1479 final QA brief — typed swarm-preflight stages and scoped mypy

Goal: final review of the implemented change on branch `feat/XYZ-forge-gh1479-static-analysis-swarm-2026-11-14`
before a DRAFT pull request. Your worktree is this branch at HEAD. Review the code, not this brief.

Operational envelope: a local developer CLI (`utils/py/swarm_preflight.py`) in a single repo. This is a
behavior-preserving refactor plus a one-module static-analysis baseline. Machinery must stay commensurate.
Non-goals (do not request): atomic-write repair, whole-repo typing, new test files/functions/suites/registry
entries (repo rule GH-831), changes to `marathon_drive.py`, `merge_cleanup.py`, `releases_app.py`.

Read:
- Plan and receipt: `PROJECT/2-WORKING/GH-1479-STATIC-ANALYSIS-SWARM.md` (whole file).
- Implementation diff: `git diff a7104e323 b2c5c32a7` (the single implementation commit) — and the whole of
  `utils/py/swarm_preflight.py` at HEAD, especially `parse_args` through `main`.
- Pre-change source for comparison: `git show a7104e323:utils/py/swarm_preflight.py` (`main()` at ~1206-1939).
- `mypy.ini`, `requirements-dev.txt`, `test/test_python_layer.py:44-52`, `.github/workflows/ci.yml`,
  `.github/workflows/wave-reconcile.yml`, `README.md`, `ROUTER.md`, `CHANGELOG.md` (top entry).
- Evidence: `TESTS-RESULTS/2026-11-14+GH-1479/` — `provenance.jsonl`, `stage-signatures.md`,
  `ab-compare/` (run.sh, exit-codes.txt, diff-old-vs-new.txt, old/, new/), `post-*.log`.

Questions:
1. Behavior preservation: comparing old `main()` with the extracted stages, is any early `SystemExit`, readiness
   precedence, side effect ordering (git fetch / worktree add/remove/prune, file writes), stdout/stderr text, or
   exit code changed? Cite the old and new `file:line` for anything that differs. Pay particular attention to
   paths the A/B comparison did NOT exercise (see `ab-compare/exit-codes.txt`: exits 0,2,3,4,5 were covered) —
   e.g. multi-issue `--gh-issue` mode success, stale index lock, frozen artifacts, lanes, fetch failure, exit 6+.
2. Is the A/B evidence sound and non-vacuous for what it claims? Is replacing the plan's step-5
   baseline-with-substitutions comparison by a same-path old-vs-new byte comparison acceptable?
3. Bounded decomposition: do the three frozen records and stage signatures give a bounded producer/consumer
   flow, or is the monolith merely relocated (`evaluate_candidate` is 250 lines, `write_packet` 197)? Only
   request a further split if you can name a concrete defect or review hazard it removes.
4. Typing: are annotations honest (no `Any` hiding a knowable type where it matters, no behavior-changing
   coercions introduced to satisfy mypy)? Is `mypy.ini` scoped correctly and is `follow_imports = skip` sound here?
5. Gate wiring: `test_swarm_preflight_module_load` now shells out to mypy. Does a missing mypy fail with actionable
   output? Are the three CI install steps and docs consistent with `requirements-dev.txt`? Any hosted-CI risk
   (e.g. `--break-system-packages -r requirements-dev.txt`, Python version vs `python_version = 3.10`)?
6. Scope: anything in the diff outside the plan, or anything the plan required that is missing?
7. Pre-existing defects in `swarm_preflight.py` you notice while sweeping the file: list them, marked as
   pre-existing, without requesting they be fixed in this PR unless the refactor made them worse.

Output graded findings with `file:line` citations. A behaviour-change request needs `Observed input:`,
`Affected scope:` and `Falsifier:` lines. Do not run `validate.sh`, `test/*.sh` or pytest in the relay worktree.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PASS
Basis: Ship for the requested draft PR. No introduced correctness defect found in the whole-module sweep or implementation comparison. Approval is code-review evidence, not a full-gate or promotion receipt.
swept file: yes

- [Pass] Behavior preservation: compared the complete old source at `a7104e323` with the implementation at `b2c5c32a7`, reading objects directly without invoking git; the current module matches the implementation blob. Old `utils/py/swarm_preflight.py:1239-1328` maps to new `:1363-1464`; only pure primary-doc/slug computation moves ahead of contract loading. Bundle source order and primary-issue selection remain intact (old `:1279-1290,1534`; new `:1403-1414,1707`). Fetch, lock inspection, ref resolution, worktree add, probes, frozen scan, removal/prune retain their order (old `:1330-1432`; new `:1467-1569`). Candidate precedence remains blocked → ambiguous → stale (old `:1434-1437`; new `:1606-1610`), followed by the same readiness ladder. Report exits still precede packet writes (old `:1695-1750`; new `:1911-1956,2176-2181`). The packet's literal `Verdict: ready` replaces a variable that could only be ready on that path (old `:1894`; new `:2123`). No behavior-changing coercion found. Keep this extraction.
- [Pass] A/B evidence is non-vacuous and the same-path substitution-free comparison is acceptable for its measured scope. `TESTS-RESULTS/2026-11-14+GH-1479/ab-compare/exit-codes.txt` covers exits 0/2/3/4/5; `run.sh:7-16` includes actual packet emission. Read-only Python probe compared every relative file in `ab-compare/old` and `new`, asserted exactly 37 equal files, seven nonempty packet files, parsed both ready JSON objects, and recomputed every `log_sha256` in `provenance.jsonl`: exit 0, decisive output `37 identical files; 7 nonempty packet files; both ready JSON objects; all 11 log hashes match`. Command form: `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'` using `Path.rglob`, byte equality, `json.loads`, and `hashlib.sha256`; no executor or fixture ran. This establishes retained-output integrity, not independent replay of their originating runs.
- [Pass] Bounded decomposition and typing meet the plan: three frozen, named records at `utils/py/swarm_preflight.py:1259-1325`, explicit stage inputs, and an 11-line main at `:2170-2181`. The evaluation stage owns the existing ordered readiness decision, while writing owns packet presentation; no concrete hazard justifies another split. `Any` remains at JSON/dict payload seams; `fetch_issue_body:742-744` honestly forwards a dynamically decoded body. `mypy.ini:1-11` scopes one module and deliberately skips imported implementation checking. The retained `post-mypy-pass.log:1` and `post-mypy-red-control.log:1-2` witness acceptance and a return-value rejection. Keep the bounded scope; this does not prove imported helpers are typed.
- [Pass] Gate wiring is consistent: `test/test_python_layer.py:47-51` uses the gate interpreter, explicit config, repository cwd, captured diagnostics and a nonzero assertion. Missing mypy therefore exposes the interpreter's `No module named mypy` diagnostic; installation is documented at `README.md:285-290` and `ROUTER.md:35`. `requirements-dev.txt:1-4` retains the three existing dependencies and pins mypy. All three install sites use it (`ci.yml:184,402`; `wave-reconcile.yml:52`); `--break-system-packages` was already present. No new test function/file/registry entry is introduced.
- [Pass] Scope: implementation paths are the planned module, existing Python-layer check, config/manifest, CI and setup docs, plus the GH-1479 accepted-start ledger update. The `releases.sql` change is generation 2651→2652 and that row's `in_flight` receipt, not another executor lane. No changes to `marathon_drive.py`, `merge_cleanup.py`, or `releases_app.py` in the implementation comparison. Plan/CHANGELOG and evidence receipts describe the result and deferred atomic-write exception (`PROJECT/2-WORKING/GH-1479-STATIC-ANALYSIS-SWARM.md`, Implementation receipt and Recon).
- [Nit] Pre-existing limitations observed during the sweep, unchanged by extraction: packet files publish sequentially with direct truncating writes (old `:1775-1788,1931-1932`; new `:1999-2015,2158-2159`), so a later write failure leaves a partial packet. Stale-lock detection assumes `.git` is a directory (old `:1374`; new `:1512`), omitting linked-worktree locks. Worktree-removal failure still falls back to `shutil.rmtree` (old `:1429-1430`; new `:1566-1567`). Record these as pre-existing; no repair requested in this behavior-preserving PR.
- [Unverified — needs clone run] No full gate, pytest, shell suite, executable fixture, or hosted workflow ran in this reviewer worktree. Retained A/B does not exercise successful multi-issue bundles, stale locks, frozen/lane refusal, fetch failure, or exits 6/7; their preservation above is source-review evidence only. Hosted installation/runtime compatibility is not established by configuration inspection. The harness must run the final gate in a disposable full clone and retain its exact-commit receipt before merge readiness is claimed; no additional suite or gate requested.

Relay closed (Approved), no further turn needed. Harness owns the file-scoped commit and subsequent gate.


### Attestation · relay-drive — 2026-11-15T20:06:08Z
task: RELAY-gh1479-final-qa
reviewer: codex
status: Approved
reviewed-head: 058900491612ca9bd2447a93172b75d158834331
added-range: 9316+5305
added-sha256: c843f8a0edd26502ee79f02c3d3c3a468e0a3fd68f11c33dfce1d1e68a833b17
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
