# RELAY · GH-1426 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-11.
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
6. **Commit only the relay file** (`relay(gh1426-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the implementation diff `git diff 0f21b761a..HEAD -- utils/py/jog_run.py`, the approved plan `PROJECT/2-WORKING/GH-1426-JOG-DRYRUN-TARGET-READINESS.md` (Plan + Acceptance → check map), and the evidence `TESTS-RESULTS/2026-11-11+GH-1426/` (README.md, provenance.jsonl, captured outputs). The plan review is `relay-system/2026-11-11/gh1426-plan-qa.md` (Approved r3, reviewed `56cdca9f1`).
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-11
- Operational envelope: a local developer CLI (`releases_app.py jog run`), one operator. Grade against issue #1426's acceptance and the approved plan, with commensurate complexity. The repo forbids new tests, suites, registry entries or gate machinery (AGENTS.md "No new tests", GH-831). A new test file in the diff is a finding; asking for one is out of scope. Sibling issues #1427/#1428 are out of scope.
- Measuring: read-only probes only (`export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"`). Do not run `validate.sh`/`test/*.sh` here. The suites already ran in a disposable clone (logs in the evidence dir), and the full gate runs on push from a disposable clone.

Questions:
1. Is each of the five issue acceptance criteria satisfied by the code at `utils/py/jog_run.py` (cite lines), and does the cited evidence file substantiate it?
2. Do the actual codepaths match the approved plan's Steps 1–5 (`_validate_execution_target`, `_resolve_preflight_py`, `_preflight_summary`, `_dry_run_preflight`, the reworded pre-preflight line, the refusal summary, the halt line, the legacy relay summary)? One addition beyond the plan: `_preflight_summary` replaces a `CONTRACT ERROR … see message above` headline with preflight's stderr cause. Is that in scope and correct?
3. Behaviour preservation: is `run_marathon_phase` otherwise unchanged (resolution order, the "resolved outside this root" notice, record/state writes, exit-4 handling)? Is the no-`--target-root` dry-run output unchanged (R3)? Does the dry-run path stay free of Jog ledger, queue, state, lock and lease writes (R1 snapshot)?
4. Robustness: can `_preflight_summary` raise or return empty for any preflight output? Does `_dry_run_preflight` handle a missing preflight script, a 1-INBOX doc with a mismatched identity, and the `--out` path, as planned? Does the `from swarm_preflight import doc_frontmatter_issue` import have side effects?
5. Did a duplicate subsystem or writer, or a new test, slip in? Is the persisted rating (`rated 55/45/50/70`, rationale in the plan doc) consistent with the evidence?
6. Is the evidence truthful (pre/post pairs, fixture description, sanitized paths, provenance SHAs)?

Write graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) with file:line. Behaviour-change requests carry `Observed input:` / `Affected scope:` / `Falsifier:`. VERDICT PASS → set `STATUS: Approved`.
- Definition of Done: every acceptance criterion is met with substantiating evidence; the code matches the approved plan; no duplicate subsystem or new tests; the dry-run effect contract holds.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes

VERDICT: FAIL
Basis: The five issue criteria have supporting code and captured evidence, but the new summary helper has a measured exception path contrary to the requested robustness/fallback contract. One small correction is needed; no new suite is requested. I swept the whole `utils/py/jog_run.py`; no additional pre-existing defect was established.

- [Should] **S1 — malformed verdict output crashes the summary rather than falling back** (`utils/py/jog_run.py:571`). The prefix check accepts `verdict pending`, then indexes element 1 of a colon split that has only one element. Both dry-run reporting (`:2228`) and live refusal reporting (`:649`) use this helper. Parse only a colon-delimited verdict field (or use a guarded partition), and let malformed lines use the existing fallback. This is a synthetic boundary input, not a claim that the current preflight normally emits it (`swarm_preflight.py:1707` emits the valid format).
  Observed input: `subprocess.CompletedProcess([], 2, "verdict pending", "")`.
  Affected scope: text-mode preflight output containing a line starting `verdict ` without a colon.
  Falsifier: that completed process must return a nonempty fallback without raising; valid `verdict : ready (exit 0)` must still yield `ready (exit 0)`, and rc 1 with stderr `late failure` must retain `preflight exited 1`.
  Probe command (no module imports or dispatch; AST-extracted actual helper): `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'` with body below; exit status **0**, decisive output **`IndexError: list index out of range`**. The probe caught the exception for reporting; it did not treat it as success.

  ```python
  import ast, re, subprocess
  from pathlib import Path
  p = Path('utils/py/jog_run.py')
  n = next(x for x in ast.parse(p.read_text()).body
           if isinstance(x, ast.FunctionDef) and x.name == '_preflight_summary')
  ns = {'re': re}
  exec(compile(ast.Module(body=[n], type_ignores=[]), str(p), 'exec'), ns)
  try:
      print(ns['_preflight_summary'](subprocess.CompletedProcess([], 2, 'verdict pending', '')))
  except Exception as e:
      print(type(e).__name__ + ': ' + str(e))
  ```

- [Pass] **Acceptance 1–2 / effect contract:** `jog_run.py:2290–2325` opens SQLite with `mode=ro` and returns before the supervisor lock/lease path; `:2204–2228` delegates per-item readiness with pinned cwd/root, explicit prospective `--out`, and child bytecode disabled. `r1-post-dryrun.txt` names `.venv/bin/pytest` and the GH-1427 contract error; the supplied R1 snapshots compare byte-equal. `r3-pre-samestate-notarget.txt` and `r3-post-dryrun-notarget.txt` also compare byte-equal. My Python byte comparisons exited 0 and printed `R1 snapshots equal: True` and `R3 outputs equal: True`. Target fetch/worktree/probe effects remain the explicitly accepted preflight effects, not a promise of filesystem immutability.
- [Pass] **Acceptance 3–4 / plan Steps 3–5:** `jog_run.py:634`, `:649–651`, `:2473–2475`, and `:2497–2500` implement the starting-preflight label, refusal cause, actual halt reason, and legacy summary. `r2-pre-live.txt` contains the old landing-boundary line; `r2-post-live.txt` contains `preflight refused: NOT-READY (exit 5) — next: gate program not found` and the matching halt reason. README truthfully identifies this post run as attempt 2/retry-build.
- [Pass] **Acceptance 5, evidence and rating:** the supplied gh280 log ends `227 pass, 0 fail`; jog-queue ends `34 passed, 0 failed`. `provenance.jsonl` names code SHA `8ad2ff6326485707f553b648f4debc2dc9dfabf3`, base `0f21b761a`, commands and disposable-clone identity. `releases.sql:990` persists 55/45/50/70, matching the plan's PRS rationale. These are captured producer results, not fresh suite execution in this turn.
- [Pass] **Helper composition and planned exceptional cases:** `jog_run.py:530–561` separates the primary pin from target checks and retains target → vendored `.xyz` → harness lookup; `:612–614` retains the outside-root notice; `:635–647` retains state writes and exit-4 handling. `:2210–2223` handles missing scripts and mismatched 1-INBOX identity without promotion. `swarm_preflight.py:1012–1019` only reads frontmatter; its module startup (`:1–29`, main guard `:1901`) adjusts import paths but does not run preflight. `swarm_preflight.py:1715–1735` shows why explicit `--out` avoids archive resolution and dry-run exits before packet creation. The contract-error stderr substitution at `jog_run.py:583–586` is in scope: `swarm_preflight.py:1258` otherwise says `see message above`, and R1/R4 retain the actual cause. Reuse stays within the existing owner; no new readiness engine is present in this file.
- [Unverified — needs clone run] No suites or executable fixtures were run here, as instructed. The full post-review gate remains the harness's responsibility. No git command was run, so exact base-to-HEAD diff equality, changed-file inventory (including the absence of new test files), committed evidence membership and provenance SHA binding were not independently established; source/evidence inspection supports the narrower findings above. No other artifact was edited.

Handing off to Producer (claude-a) — disposition S1, make the bounded parser correction, and record a manual red/green check using the existing evidence workflow; then take the next relay turn.

### Producer · Round 1 → 2 (claude)

- **[Should] S1 malformed verdict crashes the summary: Implemented** in `b59b801b1`. `_preflight_summary` now matches only `verdict ` lines that contain `:` and uses `partition`, so a malformed line falls through to the existing fallback (`utils/py/jog_run.py:571-572`). Red/green: `TESTS-RESULTS/2026-11-11+GH-1426/r4b-malformed-verdict.txt`. Before: `RAISED IndexError`. After: `'verdict pending'`. Valid `ready (exit 0)` and `preflight exited 1: late failure` are unchanged. R4 was re-run with this case added. The focused suites were re-run at `b59b801b1` in the disposable clone: gh280 227/0, jog-queue 34/0, identity stable. Provenance was appended.
- Changed files vs base (for your unverified git inventory): `PROJECT/1-INBOX/GH-1426-…` → `PROJECT/2-WORKING/GH-1426-…` (promotion), `TESTS-RESULTS/2026-11-11+GH-1426/*` (evidence), `relay-system/2026-11-11/gh1426-{plan,final}-qa.md`, `releases.db`/`releases.sql` (pickup, rating, repoint, accepted-start), and `utils/py/jog_run.py`. No `test/` file and no `validate.sh` change.

Handing off to Reviewer (codex), final QA round 2.

### Reviewer · Round 2

swept file: yes

VERDICT: PASS
Basis: S1 is resolved by the bounded parser correction. The five acceptance criteria remain supported by code and captured evidence. I swept the whole current utils/py/jog_run.py, including pre-existing receipt, resume/retry, promotion, lock and checkpoint paths; no additional actionable pre-existing defect was established. The full disposable-clone gate remains outstanding.

- [Pass] **S1 closed** — utils/py/jog_run.py:571–572 requires a colon and uses partition; malformed verdict text reaches the nonempty fallback at :583. The actual AST-extracted helper probe exited **0**. Decisive output: `malformed: 'verdict pending'`, `valid: 'ready (exit 0)'`, `late: 'ready (exit 0); preflight exited 1: late failure'`, `empty: 'exit 2'`, `contract: 'CONTRACT ERROR: missing target'`, `empty verdict: 'verdict :'`. This matches TESTS-RESULTS/2026-11-11+GH-1426/r4b-malformed-verdict.txt, whose before case records `RAISED IndexError`.
  Probe command: `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'` with the following extraction; the six completed-process cases above were asserted against those exact expected strings:
  ```python
  import ast, re, subprocess
  from pathlib import Path
  p = Path('utils/py/jog_run.py')
  n = next(n for n in ast.parse(p.read_text()).body
           if isinstance(n, ast.FunctionDef) and n.name == '_preflight_summary')
  ns = {'re': re}
  exec(compile(ast.Module(body=[n], type_ignores=[]), str(p), 'exec'), ns)
  f = ns['_preflight_summary']
  assert f(subprocess.CompletedProcess([], 2, 'verdict pending', '')) == 'verdict pending'
  ```
- [Pass] **Acceptance 1–2 / plan Steps 1–2** — jog_run.py:530–561 retains shared target checks and target → vendored → harness resolution; :2204–2228 delegates with pinned cwd/root, prospective out path, identity-checked inbox substitution and disabled child bytecode. :2290–2325 uses SQLite read-only and returns before supervisor acquisition. r1-post-dryrun.txt records the missing gate and contract error; r1-post-s1fix-dryrun.txt truthfully contains only remaining pending GH-1427. Python byte comparisons guarded by positive file sizes exited **0**, printing `R1 snapshots equal: True` and `R3 outputs equal: True` for the same pairs cited in round 1. Command core: `assert (d/a).stat().st_size > 0 and (d/b).stat().st_size > 0; assert (d/a).read_bytes() == (d/b).read_bytes()` with d the evidence directory and a/b the round-1 snapshot/output pairs.
- [Pass] **Acceptance 3–4 / plan Steps 3–5** — jog_run.py:634, :649–651, :2473–2475 and :2497–2500 retain the preflight-start label, refusal cause, actual park reason and shared legacy summary. r2-post-live.txt records `preflight refused: NOT-READY (exit 5) — next: gate program not found`; README explicitly discloses attempt 2. :612–614 retains the outside-root notice and :635–647 the preflight state/exit-4 handling. Exact base-to-HEAD equality is not independently attested because git is prohibited this turn.
- [Pass] **Acceptance 5 / final correction evidence** — provenance.jsonl names correction SHA `b59b801b1e26515e19f467398eba3be850607bbd` for R4/R4b/R1-recheck and both rerun suites. The captured gh280 log ends `227 pass, 0 fail`; jog-queue ends `34 passed, 0 failed`. These are producer clone-run receipts, not fresh suite execution here. Provenance JSONL parsed successfully in the exit-0 probe. The plan's `rated 55/45/50/70` remains consistent with the bounded change and recoverable setup failure.
- [Pass] **Composition / exceptional cases** — jog_run.py:2210–2223 reports missing script or mismatched inbox identity without promotion; swarm_preflight.py:1012–1019 reads identity, its main guard prevents dispatch on import, and :1715–1735 confirms explicit out avoids archive lookup and dry-run exits before packet creation. jog_run.py:583–586's contract stderr substitution remains appropriate cause reporting. No second readiness engine or writer was found in the reviewed file.
- [Unverified — needs clone run] Full gate execution remains with the harness. No git, suite, pytest or executable fixture was run here. Changed-file inventory, committed evidence membership and provenance-to-commit binding remain unverified independently; the producer inventory states no new tests or gate machinery. Only this relay file was edited.

Relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-11-12T03:35:32Z
task: RELAY-gh1426-final-qa
reviewer: codex
status: Approved
reviewed-head: a6e94c3ee190342b6e9d46c2a16186edc82bee9d
added-range: 15016+4443
added-sha256: 03b611f90cea008ad01c5db271cba6ccd3ec95bad76c2356b19f9886d6b640a6
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
