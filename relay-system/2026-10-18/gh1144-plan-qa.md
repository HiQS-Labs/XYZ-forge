# RELAY · GH-1144 plan QA: express targets the repo's integration branch
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
-->

NEXT: Producer
STATUS: Approved
ROUND: 3 / 3

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
6. **Commit only the relay file** (`relay(gh1144-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1144-EXPRESS-DEFAULT-BRANCH.md` (the plan; nothing is built yet).
  Requirements: issue https://github.com/HiQS-Labs/XYZ-forge/issues/1144. Source to ground against:
  `utils/py/express.py`, `utils/py/wave_reconcile.py`, `skills/2-daily/express/SKILL.md`,
  `test/gh267-express-skill.sh`, `test/wave-reconcile.sh`, `validate.sh`, `SOP.md` (express-to-development
  carve-out), `AGENTS.md` (No new tests rail; Costly surfaces).
- Operational envelope: a local developer CLI lane driven by one operator. Grade against the issue and the plan's
  acceptance with commensurate complexity; do not ask for new suites, gate machinery or multi-tenant hardening.
  The plan deliberately departs from the issue in one place (no `gh repo view` fallback; adds an
  `origin/development` fallback) — judge whether that is sound.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- Definition of Done: the plan finds every load-bearing `development` assumption on express's path (including
  wave_reconcile's direct-commit path), keeps XYZ Forge's behaviour unchanged, keeps every express invariant,
  and its checks would catch a missed literal or a split-brain run.

### Questions for the Reviewer
1. Is the site inventory complete? Any `development` assumption on express's run/land/resume/closeout path
   (express.py, wave_reconcile.py `--commit --gate`, anything they shell out to) that the plan misses?
2. Is the resolution order (`--base` → `origin/HEAD` → `development` if `origin/development` exists → refuse
   `base-unresolved`) sound? Is dropping the issue's `gh repo view` fallback acceptable, and is the
   `origin/development` fallback a guess the issue warned against, or a safe compatibility default?
3. Is a module-level `BASE` set once in `main()` acceptable here, or does any caller (tests, recovery recipe,
   imports from other utils) depend on behaviour that would diverge?
4. Is scoping wave_reconcile's `--base` to the direct-commit path (leaving PR/catch-up/hosted modes on
   `development`) correct, or does express's `--gate` run touch those modes?
5. Do the manual checks and red control actually detect a missed literal (e.g. bounds on `main` but push to
   `development`)? Is the verification compliant with GH-831 (no new suite, no registry entry)?
6. Reversibility/risk: is the plan's read right for a change on express's direct-push authority?
7. Flag anything over- or under-engineered. Cite `file:line`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The branch inventory is substantially grounded, but the plan has two demonstrable acceptance contradictions, misses executable recovery instructions, and cannot detect split-brain landing with its proposed dry-runs. Resolve the findings before implementation.
swept file: yes

Reviewed the entire seeded plan, including acceptance, risks and non-goals; the findings below include existing source/skill assumptions rather than only proposed changes. No other defects found in the swept plan beyond those listed. Evidence tier: Verify intent, source fallback used: graph project `XYZ-forge` is ready but rooted in a different checkout; its express graph ends at line 792 whereas this seeded file ends at 1316. Project listing fully paginated (84 entries); this worktree has no matching project. Coverage queried for express, reconciler, skill and plan, but that foreign index is not evidence of seeded-source freshness. No suites, executable fixtures or git commands run.

- [Blocker] **The specified unresolved-base refusal writes telemetry, contradicting “writes nothing.”** Plan Changes 1 (`PROJECT/1-INBOX/GH-1144-EXPRESS-DEFAULT-BRANCH.md:93`) calls `refuse(root, "base-unresolved", …)` without suppressing telemetry. `utils/py/express.py:119` defaults `dry_run=False`; lines 120–121 call `write_tick`, whose lines 140–181 write both local and central telemetry. Fix the new refusal to suppress telemetry unconditionally, including a real non-preview invocation, and assert no local or central artifacts in its clone-run check.
  Observed input: the exact three-argument refusal specified in Changes 1, evaluated with a recording `write_tick` stub, produces exit 3 and one telemetry call.
  Affected scope: unresolved base before any express phase, with or without `--dry-run`.
  Falsifier: a no-base fixture executed without `--dry-run` exits 3 with `base-unresolved`, leaving local/central telemetry, docs and ledger unchanged.

- [Blocker] **“Existing suites unchanged” is incompatible with the planned push replacement.** Plan lines 105–106 and 138–139 require unmodified suites, but `test/gh267-express-skill.sh:753` explicitly requires the source substring `"push", "origin", "HEAD:development"` inside `cmd_land`. Changes 2 removes it. An in-memory source probe reports `existing source assertion before= True after planned BASE replacement= False`. Fix the plan to allow the smallest truthful edit of this existing assertion; preserve its direct, fast-forward landing contract. GH-831 explicitly permits keeping an existing suite truthful when its pinned behavior changes; no new suite or registry entry is needed.
  Observed input: the literal required by gh267 line 753, against `cmd_land` after replacing `"HEAD:development"` with `"HEAD:" + BASE`.
  Affected scope: existing express source-audit assertion after branch parameterization.
  Falsifier: the adjusted existing assertion passes the actual implementation and fails an isolated mutation that restores a hardcoded wrong destination; retain the runtime landing checks.

- [Should] **Dry-run does not exercise the dangerous half of the path or supply the promised red control.** Plan line 130 says its main-fixture dry-run exercises push, closeout and reconcile previews; `utils/py/express.py:839–842` only prints a summary and returns before the actual push at 853, checkout/pull at 859–860, closeout at 869, and reconciler call at 943. Resume likewise returns at 1175 before its checkout at 1179 and reconciliation at 1216. Old code refusing at admission proves resolution changed, not that every later destination agrees. The grep audit helps literal inventory but does not prove command wiring. Add a recorded manual non-preview main-only run and resume in the disposable full clone, using the existing fixture approach, and inspect remote refs, final branch/cleanliness, committed receipt, and successful `--gate` reconciliation. Witness the same check fail with one actual push/closeout destination transposed to `development`; save its evidence in the already proposed TESTS-RESULTS directory. This is a manual check, not new gate machinery.
  Observed input: plan lines 108–115/130 choose `--dry-run` for the main run and adjacent resume; AST inspection shows `cmd_land returns= [842]`, actual push at 853, and resume's preview return at 1175.
  Affected scope: branch consistency across actual land, ship persistence, reconciliation and resume.
  Falsifier: restore a single wrong branch destination while keeping the preview correct; the proposed observable-state check must fail and the corrected implementation must pass.

- [Should] **Recovery remains hardcoded despite the all-path requirement.** Changes 5 (plan lines 102–103) permits only one new paragraph and “no other wording change,” leaving executable `git checkout development` at `skills/2-daily/express/SKILL.md:129`, `git push origin development` at 132, and a resume command without the explicit selection at 133. For a main-only host the documented recovery cannot complete. Its imported `express.write_receipt` at 130 also bypasses `main()` resolution, retaining the proposed module default and falsely describing a development push (`express.py:313`). Update executable recovery commands to use one explicit base, pass it into resume and receipt generation through the smallest supported mechanism, and make the normal procedure's branch wording consistent. Keep Forge's default receipts unchanged.
  Observed input: the existing recovery block's checkout/push commands above, applied to the plan's main-only fixture; plan line 81 explicitly preserves the imported helper's development default.
  Affected scope: recovery after a main/custom-base landing without a valid committed receipt, including explicit `--base` overrides.
  Falsifier: in a disposable main-only clone, the documented recovery procedure completes with a receipt naming main and resume reconciles that same base; Forge's default recovery still names development.

- [Should] **Existence of `origin/development` does not establish the default/integration branch.** The fetched issue #1144 says “If neither resolves, refuse … Never guess.” Plan lines 90–92 instead choose development merely because its ref exists. A clone can have no origin/HEAD while retaining both main and development; ref existence provides no evidence which one the operator authorized. Fixture convenience is insufficient justification for choosing a direct-push target. Prefer the issue's `gh ... defaultBranchRef` fallback and fail closed when unavailable, or drop that network fallback but require `--base` when origin/HEAD is absent. Make the existing fixture declare its intended base (explicit flag or origin/HEAD) rather than deriving production policy from its missing symbolic ref.
  Observed input: resolver input explicitly admitted by plan line 92: `explicit=None`, missing origin/HEAD, existing origin/development; the algorithm returns development without any default-branch evidence. Issue read: `gh issue view 1144 -R HiQS-Labs/XYZ-forge --json title,body`, exit 0, proposal states “Never guess.”
  Affected scope: implicit base selection when origin/HEAD is unavailable; explicit `--base development` remains supported.
  Falsifier: a clone with main as its declared GitHub default, development also present, and no local origin/HEAD must resolve main via authoritative fallback or refuse; it must not silently select development.

- [Pass] **A per-process module base and narrowly scoped direct-commit reconciliation are reasonable mechanisms.** `express.py:1246–1312` dispatches one command per process; the imported recovery helper is the concrete exception addressed above. Express invokes only `--commit … --gate` (`express.py:943`), not `--qualify` or `--catch-up`; reconciler qualification and recovered-owner paths are conditional on those separate flags (`wave_reconcile.py:2266`, `:2295`). Keep default arguments for other metadata callers (`:676`, `:1436`); apply the new base only to the direct-commit path and preserve development semantics for PR/hosted modes. No additional framework is needed.

- [Nit] Plan line 85's “Costly-adjacent” is not a shared reversibility grade. Easy source rollback is defensible, but explicitly state that reverting code cannot undo a misdirected remote landing. Name the stop signal (any disagreement in branch destinations) and last safe checkpoint (before first push); preserve the current fast-forward-only authority.

Probe ledger (non-mutating; no executable fixture): ran `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 - <<'PY' ... PY`, exit 0. Python parsed express with `ast.parse`, inspected Return line numbers, compiled only the existing `refuse` function with a recording `write_tick` and throwing `sys.exit` stub, and compared gh267's literal against the cmd_land source before/after an in-memory `.replace('"HEAD:development"', '"HEAD:" + BASE')`. Decisive output: `cmd_land returns= [842]`; `cmd_resume returns= [1225, 1175]`; `cmd_land actual push line: 853`; `planned refuse call: exit= 3 telemetry_calls= 1`; `existing source assertion before= True after planned BASE replacement= False`. These are source-level controls, not executed landing evidence. [Unverified — needs clone run]: all runtime suites, real branch resolution, landing, receipt/reconciliation and recovery behavior remain for the disposable clone gate.

Root cause: branch authority is encoded in multiple independent literals and executable recovery instructions; Fix site: resolve once in express and pass the same base into direct-commit reconciliation and recovery; Why not upstream/downstream: PR/hosted reconciliation has separate development contracts and does not run on express's plain --commit --gate path.

Handing off to Producer (claude-a) — revise the plan and disposition every finding, then return for Round 2.

### Producer · Round 1 (claude-a)

- B1 [Blocker] — **Modified.** The skill contract is that every refusal and fired run writes `.tick/express/*` (`skills/2-daily/express/SKILL.md`, "What each phase asserts"), and `refuse()` (`express.py:117-122`) does so for every other rule. Suppressing it for one rule would make `base-unresolved` the only invisible refusal. The defect was the plan's wording: Changes 1 and Acceptance now say the refusal happens before any doc, ledger or git write and records refusal telemetry like every other refusal; the clone-run check asserts exactly that.
- B2 [Blocker] — **Implemented.** Changes 6(a): the `test/gh267-express-skill.sh:753` source audit asserts a direct push to `"HEAD:" + BASE`; red control in Changes 7 mutates `cmd_land` back to a hardcoded `HEAD:development` and requires the assertion to fail. Runtime landing checks kept.
- S3 [Should] — **Implemented.** Verification is now a non-preview main-only `run` and `resume` in a disposable full clone (scratch copy of gh267 with the fixture branch renamed to `main`), inspecting remote refs, final branch/cleanliness, committed receipt and `--base main --gate` reconcile, with a red control that hardcodes only the push destination.
- S4 [Should] — **Implemented.** Changes 5: the SKILL.md recovery recipe uses one `BASE` variable for checkout, push, `write_receipt(..., base=...)` and `resume --base`; procedure wording names the resolved base. `write_receipt` gains an optional `base` argument (Changes 1). Recipe exercised once on the main-only fixture.
- S5 [Should] — **Implemented.** The `origin/development` existence fallback is removed. Order is `--base` → `origin/HEAD` → `gh repo view --json defaultBranchRef` → refuse; each candidate must verify as `origin/<base>`. gh267's fixture declares `origin/HEAD` with `git remote set-head origin development` (its `gh` stub returns no default branch). Acceptance adds the both-branches case resolving `main`.
- Pass — module `BASE` and direct-commit-only `--base` in wave_reconcile retained as reviewed.
- Nit — **Implemented.** Reversibility now states that reverting code cannot undo a misdirected landing, names the stop signal and the last safe checkpoint (before first push).

Handing off to Reviewer (codex) for round 2.

### Reviewer · Round 2

VERDICT: FAIL
Basis: The revised design resolves the previous findings. One material verification gap remains: the main-only fixture substitutes a reconciler that cannot exercise the changed production reconciliation path.
swept file: yes

Read the entire revised plan (lines 1–190), not just the changed paragraphs; no additional plan defects found beyond the finding below. Evidence tier: Verify with direct-source fallback. `list_projects(limit=100)` returned all 84 projects, no matching worktree. The nearest graph is `XYZ-forge`, rooted in the primary checkout, generation `2026-09-01T15:54:30Z`; targeted express search returned two symbols with no further page and obsolete line ranges. Coverage checked for plan, express, reconciler, skill and both named suites: changed/untracked/missing metadata, so seeded source was read directly rather than treating the foreign index as fresh evidence. No git commands, suites or executable fixtures run.

- [Should] **Name a main-only check of the actual reconciler, independent of gh267's stub.** Plan `PROJECT/1-INBOX/GH-1144-EXPRESS-DEFAULT-BRANCH.md:124–131` specifies a renamed scratch copy of gh267, then counts a passing `wave_reconcile --commit … --base main --gate` among its observations. But `test/gh267-express-skill.sh:173–213` writes its own `$FX/utils/py/wave_reconcile.py`: it checks the current branch and a receipt, never parses `--base`, and never imports the production module. Renaming its development strings to main leaves that substitution intact. Existing wave-reconcile suite fixtures still use development (`test/wave-reconcile.sh:43`, `:140–167`). Thus these named runs can pass with the production metadata reachability check still hardcoded (`utils/py/wave_reconcile.py:433`). Explicitly add a recorded manual invocation of the changed canonical reconciler against a main-only disposable fixture (real branch check, pull, commit metadata and `--gate` receipt matching; stub only external services as needed), checking its reported base and actual lifecycle outputs. Witness this check fail when one production direct-commit branch literal is restored to development, then pass after restoration. Keep this a manual check under the already named evidence directory; no new suite or gate machinery.
  Observed input: the plan's scratch copy of gh267 after its fixture branch rename still installs the inline reconciler stub; source-only probe reports `stub reads --base: False`, `stub imports wave_reconcile: False`, and `sha = sys.argv[sys.argv.index("--commit") + 1]`.
  Affected scope: evidence for main-only production `wave_reconcile.py --commit … --base main --gate`, including an accidentally missed reachability/base literal or missing express-to-reconciler option wiring.
  Falsifier: keep production `fetch_commit_metadata` reaching local development while the renamed stub accepts main. The proposed production-module manual check must fail; fixing the production destination must make it pass. A retained real-module run already specified separately from the stub would also resolve this finding.

- [Pass] **Previous B1/B2/S3/S4/S5 and reversibility nit are dispositioned adequately at plan level.** Refusal telemetry is now explicitly permitted before doc/ledger/git writes (plan `:95–99`, `:132–135`, `:165–166`), matching the existing `refuse` default (`express.py:117–122`); changing the contradictory acceptance wording is sound. The existing source assertion and fixture declaration are expressly updated (plan `:114–119`), actual landing/ref inspection and a wrong-push red control replace preview-only evidence (`:124–131`), recovery passes one base through checkout/push/helper/resume (`:100–113`, `:136–137`), and resolution now uses authoritative defaults or refuses (`:71–84`, `:92–95`). Reversibility names the remote limitation and pre-push checkpoint (`:85–88`). These are approved plan requirements, not executed implementation results.

- [Pass] **The intended mechanism remains appropriately small.** One process dispatches one express command (`express.py:1246–1312`); the recovery helper gets the explicit argument needed outside that dispatch (plan `:81–83`, `:100–101`). Express supplies only `--commit … --gate` (`express.py:943`), so keeping PR/catch-up/qualification behavior on development is appropriate (plan `:75–78`, `:145–147`; reconciler branches at `:2266`, `:2295`). Implement step 4 under that stated direct-commit scope: its branch/pull preflight calls are shared with PR modes (`wave_reconcile.py:2220`, `:2229`), not exclusive call sites.

Probe ledger: source-only command, exit 0 (no fixture execution):
```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PYPROBE'
from pathlib import Path
s = Path('test/gh267-express-skill.sh').read_text()
stub = s.split('cat > "$FX/utils/py/wave_reconcile.py" <<\'WR\'\n', 1)[1].split('\nWR\n', 1)[0]
print('stub reads --base:', '--base' in stub)
print('stub imports wave_reconcile:', 'import wave_reconcile' in stub)
print('stub identifies landing:', next(l for l in stub.splitlines() if 'sys.argv.index' in l))
PYPROBE
```
Decisive output: `stub reads --base: False`; `stub imports wave_reconcile: False`; `stub identifies landing: sha = sys.argv[sys.argv.index("--commit") + 1]`.

[Unverified — needs clone run]: resolution, real landing/resume/recovery and production reconciliation remain implementation-time evidence. Root cause: the selected express fixture replaces the second changed production module; Fix site: plan verification step 7; Why not upstream/downstream: keep the useful express stub fixture, but independently measure the production reconciler rather than inferring its behavior from that stub.

Handing off to Producer (claude-a) — specify the actual-reconciler manual check and red control, then return for Round 3.

### Producer · Round 2 (claude-a)

- Production-reconciler gap [Should] — **Implemented.** Changes 7 adds a separate recorded run of the canonical `utils/py/wave_reconcile.py --commit <sha> --base main --gate` on a main-only scratch repo in the disposable clone (receipt committed, harness tools resolved as the existing wave-reconcile suites do), with a red control: `fetch_commit_metadata` left on local `development` must exit 4 `not reachable from local development`; fixed → passes. Plus a no-`--base` run on a development-shaped repo to show unchanged behaviour.
- Implementation note on step 4 — **Implemented.** Changes 4 now says the branch/pull preflight at `:2220`/`:2229` is shared with PR modes and is unchanged for them because `--base` defaults to `development` and only express passes it.

Handing off to Reviewer (codex) for round 3 (final round within the cap).

### Reviewer · Round 3

VERDICT: PASS
Basis: Approve the plan for implementation. The independent production-reconciler check resolves the remaining Round 2 finding; the full plan retains authoritative resolution, one per-run base, branch-consistent recovery and observable landing controls. No open Blocker or Should findings remain.
swept file: yes

Read the entire current plan (lines 1–201), including inventory, design, changes, risks, acceptance and evidence; no additional pre-existing defects found in the swept artifact. Evidence tier: Verify with direct-source fallback. Project listing returned all 84 projects with no matching worktree. Nearest graph `XYZ-forge` is rooted in the primary checkout, generation `2026-09-01T15:54:30Z`; targeted search returned two results with no further page, including obsolete express line ranges. Coverage checked for the plan, express, reconciler, skill and both named suites: missing/changed/untracked freshness, so graph results were not treated as evidence of this seeded source. Relevant source and fixture bodies were read directly. Applied swe and debug-mantra plan-review criteria.

- [Pass] **Round 2 reconciliation finding resolved at plan level.** `PROJECT/1-INBOX/GH-1144-EXPRESS-DEFAULT-BRANCH.md:133–142` explicitly distinguishes gh267's stub from the canonical module, requires a separate main-only `--commit <sha> --base main --gate` run with committed attributable evidence, specifies a reachability red control and retains a no-`--base` development control. This targets the actual production failure: `utils/py/wave_reconcile.py:432–437` checks ancestry against local development and exits 4 on failure. The manual run must retain real branch/pull/metadata/receipt checks, as required by the prior finding; it is implementation-time evidence, not a result observed here.
- [Pass] **Branch selection and inventory remain adequate for the bounded change.** Plan `:35–53`, `:92–109` cover bounds, admission, landing, closeout persistence, resume, receipts, recovery messages and direct-commit reconciliation; `:110–114` covers the imported recovery helper. Express currently invokes the plain direct-commit path with `--gate` (`utils/py/express.py:938–945`); qualification/catch-up are separate conditional paths (`utils/py/wave_reconcile.py:2266–2299`). Preserve the stated direct-commit scope when implementing shared preflight/base-guard calls. Resolution now follows explicit choice, origin/HEAD, GitHub default, then refusal (`plan:92–101`); the earlier ref-existence guess is gone.
- [Pass] **Verification and risk remain proportionate.** Plan `:115–148` uses existing suites plus recorded manual runs and mutations, including remote-ref inspection for the wrong-push control and a recovery run; it adds no suite or gate. Plan `:85–88` states the remote rollback limit and pre-push stop checkpoint. Acceptance `:171–181` keeps Forge defaults and requires main-only actual land/resume plus production reconciliation.

Source-only probe (exit 0; no executable fixture or git command):
```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PYPROBE'
from pathlib import Path
import ast
p = Path('PROJECT/1-INBOX/GH-1144-EXPRESS-DEFAULT-BRANCH.md').read_text()
t = ast.parse(Path('utils/py/wave_reconcile.py').read_text())
f = next(n for n in t.body if isinstance(n, ast.FunctionDef) and n.name == 'fetch_commit_metadata')
print('production function:', f.name, f.lineno, f.end_lineno)
print('reachability destination:', next(n.value for n in ast.walk(f) if isinstance(n, ast.Constant) and n.value == 'development' and n.lineno == 433))
print('production failure:', next(n.value for n in ast.walk(f) if isinstance(n, ast.Constant) and isinstance(n.value,str) and 'not reachable from local development' in n.value))
print('plan independent canonical invocation:', 'run the canonical `utils/py/wave_reconcile.py' in p)
print('plan reachability red control:', 'local `development`, the same invocation exits 4' in p)
print('plan default compatibility control:', 'same command without `--base`' in p)
PYPROBE
```
Decisive output: `production function: fetch_commit_metadata 408 452`; `reachability destination: development`; `production failure:  is not reachable from local development`; the three plan checks each printed `True`. This corroborates the planned control's source target, not runtime success.

[Unverified — needs clone run]: implementation, resolution, suites, landing/resume/recovery, real reconciliation, and both runtime red controls. Approval is for the plan only; those checks and committed provenance remain required before implementation sign-off.

Root cause: branch authority is repeated across express and its direct-commit reconciliation/recovery path. Fix site: resolve once in express and propagate that base across these existing owners. Why not upstream/downstream: unrelated PR/catch-up/hosted reconciliation retains its development contract.

Relay closed (Approved), no further turn needed. Producer (claude-a) may proceed to implementation and the specified disposable-clone verification.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
