# RELAY · GH-908 projection ledger-read QA
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
6. **Commit only the relay file** (`relay(gh908-ledger-read-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **reconcile-ledger-brief.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-01

### Artifact — reconcile-ledger-brief.md
```
Independently review commit 55b9d05d in utils/py/wave_reconcile.py, following two failed full-gate attempts and the earlier review findings in relay-system/2026-10-01/gh908-reconcile-delta-qa.md and gh908-reconcile-cwd-qa.md. This commit replaces an extra settings subprocess with the existing ledger_rows(repo_root, sql, params) helper and defaults to views enabled if its read raises ReconcileError. Do not modify files or run test/*.sh/validate.sh or ledger writers. Read the complete run_subprocesses and ledger_rows functions and immediate callers. Check projection-off behavior on a queryable DB, behavior for absent/legacy/corrupt DB and missing settings table, no new subprocess/mock call, no duplicate source of truth or hidden data-loss path. Ten related existing suites pass in a disposable clone, including GH-424 and GH-421; full gate at final code tip is pending. Give concrete counterexample and file:line citations for any finding. Assess whether prior reviewer objections are resolved; do not approve solely from the suite result.
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
**Basis:** Reviewed the entire embedded brief, the seeded reconciler source with emphasis on complete `ledger_rows` and `run_subprocesses`, all local ledger-reader callers, main orchestration/rollback, snapshot/fingerprint helpers, resolver, and canonical projections getter/setter. Acceptance criteria inferred from the brief: explicit off suppresses adopted exporters; absent/legacy/schema-error reads preserve default adoption; no added CLI import/subprocess or competing setting store; existing check/rollback authority remains intact. No additional pre-existing defect identified in the reviewed source. Approval covers this correction, not pending full-gate qualification.

- [Pass] Explicit off is read from the target ledger and suppresses both adopted exporter steps (`utils/py/wave_reconcile.py:1813-1829`). This matches the canonical exact-value policy at `utils/py/releases_app.py:1344-1357`; the supported setter permits only `on` or `off` (`:3843-3844`). Keep this predicate. Narrow probe command: `python3 - <<'PY'`, parse the seeded AST, compile only `ReconcileError/log_err/die/ledger_rows` and the existing try/assignment nodes at `:1812-1818`; obtain input mappings through the real helper using `ledger_rows(str(root), "SELECT ? AS value", (val,))`, then evaluate the exact selection nodes with those mappings. Exit **0**; decisive output: `SQL value='off' -> views_enabled=False`; `'on'`, `''`, `' off '`, and `None` each produce `True`. This measures SQLite row shape and the selection predicate, not an exporter run. The whitespace result matches the canonical getter; no normalization change is requested.
- [Pass] The existing helper opens `releases.db` with `mode=ro`, parameterizes the setting key, closes the connection, and creates no DB (`utils/py/wave_reconcile.py:1206-1227,1813-1815`). Same probe command called the real helper with `SELECT value FROM settings WHERE key = ?`, parameters `("projections",)`: exit **0**, decisive output `seeded projections rows: []`, `seeded selection: True`. Against nonexistent scratch root `.relay-scratch/tmp/absent-ledger-root`, output `absent ledger: []`; asserted the root remained nonexistent. Nonzero DB size was asserted before querying and SHA256 compared afterward: `seeded DB SHA256 unchanged; no missing DB created`. Keep the shared reader; no ledger writer added.
- [Pass] Compatibility fallback is localized to the optional setting: missing DB or legacy zero-byte placeholder yields no rows (`utils/py/wave_reconcile.py:1209-1216`); SQLite errors become `ReconcileError` (`:1226-1227`) and this caller defaults to adoption (`:1816-1818`). Same probe routed the selection's reader through a read-only query against an intentionally nonexistent table in the seeded DB: `ledger_rows(str(root), "SELECT value FROM __gh908_missing_settings_probe")`. Wrapper exit **0**; decisive stderr `Cannot read reconciliation ledger: no such table: __gh908_missing_settings_probe`; output `observed schema-error fallback: [] True`. This witnesses the SQLite-schema-error/catch path; actual corrupt/zero-byte/missing-settings ledgers were not manufactured or executed here. Those cases are source-checked, not runtime-attested.
- [Pass] Prior subprocess/CWD objections are resolved by removing that settings process entirely: the selected target root is used directly at `utils/py/wave_reconcile.py:1813-1815`, normalized by main at `:2146`; no Releases CLI import appears in this function. AST command `[ast.unparse(n.func) for n in ast.walk(fn) if isinstance(n, ast.Call)]`, filtered for `subprocess.`, exited **0** with `run_subprocesses subprocess call sites: ['subprocess.run']` — the existing downstream loop at `:1861`. Tool selection for downstream commands remains at `:1789-1794`, with target CWD at `:1861`. Keep this implementation; the earlier settings-stub import and extra mock-call failure mechanisms no longer apply to this read.
- [Pass] No hidden new ledger-data-loss path identified: sync and check are first in the ordered step list (`utils/py/wave_reconcile.py:1800-1803`), their nonzero status stops before exporters (`:1852-1865`), ledger/view snapshots precede this read (`:1771,1707-1727`), and main rolls back failures (`:2423-2430`). The optional setting catch does not suppress those check failures. Other ledger-reader callers retain their existing fail behavior (`:1241,1409,1479,1485`). The setting remains solely in the target DB; no parallel settings source is introduced. Retain these contracts.
- [Unverified — needs clone run] The ten reported suite passes, original full-gate failures and pending final full gate were not independently run. End-to-end off exporter suppression, corrupt/legacy ledger reconciliation, actual missing-settings schema reconciliation, vendored tool execution and rollback under executable stubs require the harness's disposable full clone. This review does not attest merge readiness.

Evidence limits: no Git command, CLI writer, reconciler, exporter, suite, pytest or executable fixture was run. Probe environment: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"`. Only isolated read helper/selection AST nodes were executed; source and seeded DB were unchanged. Graph tools are unavailable in this session, so current seeded source supplies citations; no graph generation/coverage claim is made. Commit identity `55b9d05d` is supplied by the brief and was not independently checked under the no-Git constraint. The relay file is the only tracked edit; the harness owns its commit.

Relay closed (Approved), no further turn needed. Producer (claude-a) should arrange the pending disposable-clone qualification. Marking the token done under the explicit approval instruction.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
