# RELAY · GH-908 reconcile gate correction QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-01.
-->

NEXT: Producer
STATUS: Escalated
ROUND: 1 / 1

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
6. **Commit only the relay file** (`relay(gh908-reconcile-delta-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **reconcile-brief.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-01

### Artifact — reconcile-brief.md
```
Review commit e1507c46 (utils/py/wave_reconcile.py) as the final GH-908 correction. Independent read-only review: do not run test/*.sh or validate.sh, edit code, or invoke a ledger writer. Original feature and first delta were approved in relay-system/2026-10-01/gh908-final-qa.md and gh908-gate-delta-qa.md. The clean ci-local at prior code tip found 6 reconcile suites failing because older fixture releases_app.py stubs omit projections_enabled; one stub calls sys.exit(0) on import. This commit replaces direct import with `python3 <selected Releases CLI> --root <repo> settings get projections`; it suppresses refresh only when stdout is exactly off and exit is 0. Seven affected suites now pass with XYZ_HARNESS unset in a disposable clone; new full gate pending. Review full run_subprocesses and related CLI settings get. Check off/on/default semantics, CLI failure behavior, vendored path, and whether this creates a data safety issue. Give concrete counterexample with file:line if any. No tests in this turn.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

swept file: yes

**VERDICT: FAIL**
**Basis:** Reviewed the whole embedded artifact, complete `run_subprocesses`, its main caller and immediate snapshot/fingerprint/planner helpers, and related settings CLI dispatch/getter, root/DB gateway and tool resolver. Acceptance criteria are off/on/default compatibility, CLI failure compatibility, selected tool/root correctness and ledger safety. One concrete path-resolution defect prevents approval. No additional pre-existing defect identified in this bounded function/caller sweep; this is not an exhaustive audit of unrelated functions in the large modules.

- [Should] Pin the settings query CWD to the target root. `utils/py/wave_reconcile.py:1813-1816` omits `cwd=repo_root`, although the tool resolver returns a repo-relative path when the target owns the CLI (`utils/py/harness_paths.py:103-110,126-127`). Existing downstream calls supply the CWD at `utils/py/wave_reconcile.py:1860`; main accepts an explicit root without changing directory (`utils/py/wave_reconcile.py:2145`). A foreign/subdirectory CWD therefore fails to launch the selected CLI; line 1817 enables adopted views on that failure, so a target `off` setting would be ignored. This can overwrite adopted views; the query does not itself mutate ledger rows. Concrete fix: add `cwd=repo_root` to this subprocess call, retaining the failure predicate.
  Observed input: target root `/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.uaSNS8`; argv `["python3", "utils/py/releases_app.py", "--root", <target root>, "settings", "get", "projections"]`; invocation CWD `<target root>/.relay-scratch/tmp`. Read-only command `subprocess.run(argv, cwd=<scratch CWD>, capture_output=True, text=True, check=False)` returned exit **2**, empty stdout, decisive stderr `can't open file '<target root>/.relay-scratch/tmp/utils/py/releases_app.py': [Errno 2] No such file or directory`. The same command with `cwd=<target root>` returned exit **1**, empty stdout/stderr, consistent with the seeded DB having no projections row. Wrapper probe exited 0. No fixture or reconciler was executed.
  Affected scope: selected CLI paths that are repo-relative when invocation CWD differs from the target root. The off-setting impact follows from the observed launch failure and line 1817; an end-to-end off-ledger export was not executed.
  Falsifier: identical selected argv from a foreign CWD with target `projections=off` must return exit 0/stdout `off\n` and exclude both adopted view steps. The existing invocation cannot find its script; after the CWD fix it should read the target CLI. A vendored absolute CLI should continue reading the consumer root passed through `--root`.
- [Pass] Predicate compatibility itself is intact: `utils/py/wave_reconcile.py:1817-1829` skips adopted views only for successful stripped stdout `off`; `utils/py/releases_app.py:3879-3889` prints the setting or exits 1 when absent. Narrow command `python3 - <<'PY'` parsed the seeded function AST, compiled only the `views_enabled` RHS via `ast.Expression`, and evaluated it with `(returncode, stdout)` values; exit 0, decisive output: `(0, 'off\n') -> False`, `(0, 'on\n') -> True`, `(0, '') -> True`, `(0, 'notice\noff\n') -> True`, `(1, 'off\n') -> True`, `(2, '') -> True`, `(0, ' off \n') -> False`. Contrasting inputs measure only the predicate, not full reconciliation. No predicate change requested.
- [Pass] The getter adds no ledger writer: `utils/py/releases_app.py:3881-3889` resolves root, connects, selects and closes in `finally`; `utils/py/releases_app.py:432-449` checks DB existence, enables foreign keys and selects the row. `utils/py/wave_reconcile.py:1800-1803,1851-1864` still runs roadmap sync and ledger check before exporter steps and rejects their nonzero exits. Source inspection found no new path that discards ledger rows. No change requested to these contracts.
- [Unverified — needs clone run] The seven reported suite passes, final full gate, legacy stub execution and end-to-end projection-off exporter behavior were not run here. The harness must run the required gate in a disposable full clone after correction; this review does not attest merge readiness.

Evidence limits: no Git command, ledger writer, exporter, reconciler, test suite or executable fixture was run. Graph lookup used nearest available `XYZ-forge`, generation `2026-09-01T15:54:30Z`, in a different checkout; coverage marked wave/release source `metadata_changed` and the resolver `not_tracked`. Material citations use current seeded local source. Scratch environment: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"`. Read-only SQLite probe command `sqlite3.connect(db.as_uri()+"?mode=ro", uri=True).execute("SELECT key,value FROM settings WHERE key = 'projections'").fetchall()` returned `[]` for the seeded DB, exit 0. Commit identity comes from the brief and was not independently checked under the no-Git constraint.

Handing off to Producer (claude-a) — apply the CWD correction and arrange renewed independent QA plus the qualifying clone gate. Round cap reached; STATUS is Escalated.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
