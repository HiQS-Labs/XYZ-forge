# RELAY · GH-908 reconcile CWD correction QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-01.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh908-reconcile-cwd-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **reconcile-cwd-brief.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-01

### Artifact — reconcile-cwd-brief.md
```
Review the one-line correction in commit 0401f505 to utils/py/wave_reconcile.py, after the independent finding in relay-system/2026-10-01/gh908-reconcile-delta-qa.md. Previous reviewer found the settings CLI path relative to target but subprocess CWD unspecified. The correction sets cwd=repo_root. Do not modify code, run test/*.sh or validate.sh, or write a ledger. Inspect selected CLI path resolution, run_subprocesses context, and setting predicate. Check whether cwd=repo_root fixes bare and vendored paths without changing the target --root semantics, and whether any concrete counterexample remains. A manual red/green read-only CLI probe on a releases-only fixture with projections=off showed foreign CWD rc2/no stdout vs target CWD rc0/off. A new full ci-local is pending. Grade with citations. Do not approve from test results alone.
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

**VERDICT: PASS**
**Basis:** Reviewed the whole embedded brief, complete `run_subprocesses`, immediate snapshot/fingerprint helpers and main caller/root context, complete tool resolver, and related settings CLI parser/dispatch/getter/root/connection path. Acceptance criteria inferred from the brief: repair foreign-CWD launch for relative tools, preserve absolute vendored-tool support and target `--root`, retain off/on/default/error semantics, and introduce no ledger writer. The correction satisfies this bounded review. No additional pre-existing defect identified in this function/caller sweep; this is not an exhaustive audit of unrelated functions in the 2,433-line reconciler. Approval covers the correction; final gate and merge readiness remain outstanding.

- [Pass] The correction closes the observed launch failure: `utils/py/wave_reconcile.py:1813-1816` now supplies `cwd=repo_root`, matching the resolver contract at `utils/py/harness_paths.py:103-116,126-127` and downstream invocation at `utils/py/wave_reconcile.py:1860`. Read-only probe command: `subprocess.run(["python3", "utils/py/releases_app.py", "--root", str(root), "settings", "get", "projections"], cwd=cwd, capture_output=True, text=True, check=False)`, with `root=/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.D4hFCs`. Red control `cwd=root/".relay-scratch/tmp"`: exit **2**, stdout `''`, decisive stderr `can't open file '<root>/.relay-scratch/tmp/utils/py/releases_app.py': [Errno 2] No such file or directory`. Corrected `cwd=root`: exit **1**, stdout/stderr `''`, the getter's expected missing-setting result (`utils/py/releases_app.py:3884-3889`). Probe wrapper exit **0**. Keep the CWD correction.
- [Pass] Target-root semantics remain explicit: main normalizes the target to an absolute root (`utils/py/wave_reconcile.py:2145`), query argv retains it (`:1814`), and getter resolves that explicit root before opening its DB (`utils/py/releases_app.py:304-306,351-355,3881-3882`). Absolute-tool probe used the preceding command with argv[1] replaced by `str(root/"utils/py/releases_app.py")` and foreign scratch CWD: exit **1**, stdout/stderr `''`, matching relative-target execution. This measures absolute launch and explicit-root reading; vendored tool selection is source-checked at `utils/py/harness_paths.py:30-56,89-127`, not an executed vendored fixture. Retain the resolver and `--root` as written.
- [Pass] Only successful stripped stdout `off` disables adopted exports (`utils/py/wave_reconcile.py:1817-1829`); sync/check and planner remain separate (`:1800-1803,1831-1864`). Predicate probe command: parse the seeded function with `ast.parse`, compile only the `views_enabled` RHS using `compile(ast.Expression(predicate.value), str(source), "eval")`, then `eval(expr, {"projection_setting": SimpleNamespace(returncode=rc, stdout=out)})`. Wrapper exit **0**; decisive output `(0, 'off\n') -> False`; `(0, 'on\n')`, `(0, '')`, `(1, '')`, `(2, '')`, `(1, 'off\n')`, `(0, 'notice\noff\n') -> True`. Contrasting inputs exercise the exact seeded predicate without running reconciliation. No predicate change requested.
- [Pass] Settings-get remains a read path (`utils/py/releases_app.py:3879-3889,432-449,6870-6872`). Read-only SQLite probe command `sqlite3.connect(db.as_uri()+"?mode=ro", uri=True).execute("SELECT key,value FROM settings WHERE key = 'projections'").fetchall()` returned `[]`, wrapper exit **0**. The probe asserted nonzero DB size and identical `hashlib.sha256(db.read_bytes()).hexdigest()` before/after CLI calls; decisive output `seeded DB hash unchanged`. The CWD correction introduces no ledger writer. No ledger change requested.
- [Unverified — needs clone run] Actual off-setting exporter suppression, full vendored reconciliation, legacy executable stubs and the pending full `ci-local` qualification were not run here. The seeded DB has no projections row, so the producer's off-fixture rc2/rc0 report is not independently attested by this turn. Run the required existing gate in a disposable full clone after handoff; this review does not attest gate success.

Evidence limits: no Git command, ledger writer, exporter, reconciler, suite or executable fixture was run. Probe environment: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"`. No probe output was copied into source artifacts. Graph discovery used nearest available `XYZ-forge`, generation `2026-09-01T15:54:30Z`, in another checkout; both project-list pages were read. Coverage marked wave/release source `metadata_changed` and resolver `not_tracked`, so material citations use current seeded local source. Commit identity `0401f505` comes from the brief and was not independently checked under the no-Git constraint.

Relay closed (Approved), no further turn needed. Producer (claude-a) should arrange the pending disposable-clone gate; the harness owns the file-scoped commit. Marking the token done under the explicit approval instruction.


### Attestation · relay-drive — 2026-10-01T20:53:33Z
task: RELAY-gh908-reconcile-cwd-qa
reviewer: codex
status: Approved
reviewed-head: f6127f3f6c649c6b3f50fe7a43e2e70cc30cee9f
added-range: 6126+5038
added-sha256: 26a7526246b49583df58db507f29949d622e342c96f8b38970d91480a53f0733
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
