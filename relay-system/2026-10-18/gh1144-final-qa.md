# RELAY · GH-1144 final QA: express targets the repo's integration branch
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
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
6. **Commit only the relay file** (`relay(gh1144-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/express.py` and the rest of the committed implementation on this branch
  versus development at 9a61625f (git diff 9a61625f..HEAD): `utils/py/wave_reconcile.py`,
  `skills/2-daily/express/SKILL.md`, `test/gh267-express-skill.sh`, the evidence in
  `TESTS-RESULTS/2026-10-18+GH-1144/README.md` (and its logs and provenance), and the plan, acceptance and
  Evidence table in `PROJECT/2-WORKING/GH-1144-EXPRESS-DEFAULT-BRANCH.md`. Approved plan QA thread:
  `relay-system/2026-10-18/gh1144-plan-qa.md`.
- Operational envelope: a local developer CLI lane driven by one operator. Grade against the approved plan's
  changes 1–7 and acceptance with commensurate complexity; no new suites, gate machinery or multi-tenant
  hardening (GH-831). The full gate (`ci-route` tier 3) runs once on the final approved commit, after this review.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- Definition of Done: every acceptance item is met by the committed code and substantiated by the evidence;
  Forge's behaviour is unchanged; no load-bearing `development` literal remains on express's path; no new suite
  or registry entry; the two gh267 edits are only what keeps it truthful.

### Questions for the Reviewer
1. Completeness: does any push, pull, checkout, reachability, log, diff or reconcile destination on express's
   run/land/resume/closeout path still use a literal instead of `BASE`? Is `wave_reconcile --base` applied to
   exactly the direct-commit path (default `development` elsewhere)?
2. `resolve_base`: correct order (`--base` → `origin/HEAD` → `gh repo view` default → refuse), candidates
   validated (`BRANCH_NAME`, no `..`, `refs/remotes/origin/<b>` exists), `gh` absence handled? Any way it
   picks a branch without evidence?
3. The `base-unresolved` refusal: before any doc, ledger or git write; telemetry consistent with other refusals?
4. `write_receipt(base=None)` and the edited recovery recipe: Forge receipts byte-identical (`direct development
   push`)? Is the step-6 recipe fix (log copied beside the printed receipt path) correct, and in scope as a
   pre-existing defect in a touched file?
5. Evidence: do the logs substantiate each claim (main-only 113/0, red controls, production reconciler A–E,
   resolution cases, recipe run, smoke)? Note the recorded deviation (red control D's message names `main`)
   and the clone-of-local-clone smoke limitation — acceptable, or does the latter need a code guard?
6. Diff hygiene: anything outside scope, accidental files, home paths in TESTS-RESULTS?
7. Flag anything over- or under-engineered. Cite `file:line`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 (codex)

VERDICT: FAIL
Basis: The implementation is coherent on source review and the retained suites are green, but the independent production-reconciler evidence omits part of the verification explicitly required by approved plan QA. One Should remains; no observed runtime Blocker.
swept file: yes

Swept all of `utils/py/express.py` (1–1357), `utils/py/wave_reconcile.py` (1–2495), `skills/2-daily/express/SKILL.md` (1–230), and `test/gh267-express-skill.sh` (1–766), plus the complete working plan, evidence README, retained manual procedures, provenance manifest and decisive raw-log results. No additional pre-existing runtime defects found in these swept files; documentation nit below. Applied SWE and debug-mantra acceptance/evidence criteria. Evidence tier: Verify, direct-source fallback: all 84 graph projects listed, none rooted in this worktree; nearest `XYZ-forge` index generation `2026-09-01T15:54:30Z` belongs to the primary checkout. Targeted symbol query returned zero results/no further page; coverage for the six artifact paths reported changed, untracked or missing freshness, so the current seeded source was read directly. No git commands, suites, executable fixtures, or artifact edits performed. Exact committed diff membership/ancestry was not independently queried because this turn prohibits git.

- [Should] **Complete the promised production main-only reconciliation check.** The retained procedure `TESTS-RESULTS/2026-10-18+GH-1144/prod-reconciler-check.py.txt:25` always supplies `--skip-pull`; `:28–30` replaces cleanliness, downstream lifecycle helpers and the validation gate, and forces issue state OPEN. Its only content files are README and the receipt (`:17–22`): no active issue doc or ledger row exists. Consequently A/E's exit 0 proves branch/reachability/base guard/receipt attribution, but cannot demonstrate the real pull destination or lifecycle outputs. The express main variant cannot fill that gap because it installs the gh267 reconciler stub (`test/gh267-express-skill.sh:173–213`). Approved plan QA Round 2 expressly required real branch/pull/metadata/receipt checks and actual lifecycle outputs, retained by Round 3 approval; this is still [Unverified — needs clone run]. In the disposable full clone, extend the existing recorded manual check with a real local origin/main, a committed active doc and owned ledger state, canonical pull and lifecycle writers, and a CLOSED issue response (stub external GitHub responses as needed). Inspect pulled/remote identity, doc destination and ledger state; retain the command, status and raw results with refreshed provenance. Preserve the useful A–E reachability controls. No new suite or gate is requested.
  Observed input: retained canonical invocation includes `--commit <sha> --gate --skip-pull --base main`; its patch list includes `("run_subprocesses", None)`, `("run_validation_gate", None)`, `("fetch_issue_state", "OPEN")`, and no active-doc content is created.
  Affected scope: evidence for production direct-commit reconciliation on main, specifically shared pull preflight and real lifecycle results; this does not request unrelated hosted/catch-up hardening.
  Falsifier: a retained main-only canonical run with real pull and populated doc/ledger lifecycle, showing correct outputs, would resolve this finding. Restoring only the production pull destination to development in that disposable check must make it fail; restoring main must pass.

- [Pass] **Express consistently carries one resolved base through its operational path.** Candidate validation and precedence are at `express.py:114–134`; `main():1343–1353` resolves before phase dispatch and uses the existing refusal telemetry. The remaining executable development constants are the intended module default `:90` and task-branch exclusion `:486`. Bounds use BASE (`:108`, `:389–391`, `:458`, `:491–504`); landing/closeout use it at `:882–896`, persistence at `:1023`, landing resolution at `:1071–1080`/`:1115`, resume at `:1207–1209`, and the reconciler command at `:973`. No further load-bearing express development literal found in the whole-file sweep.
- [Pass] **Direct metadata and receipt compatibility are preserved at the source sites.** `wave_reconcile.py:408–450` takes an optional base and uses it for reachability and synthesized metadata; the ordinary direct-commit call passes it at `:2313`. Qualification/recovery callers retain their development default (`:676`, `:1436`, `:2275`). Shared preflight/base guard use `args.base` (`:2226`, `:2235`, `:2325`) whose default remains development (`:2145`). `express.py:342` still produces the exact environment span `express driver, direct development push` with the default; the recovery helper's explicit base is supplied by `SKILL.md:135`. No additional mode framework is warranted.
- [Pass] **Existing retained results and manifest are internally consistent.** `suite-gh267-express-skill.log.txt` and `main-variant-run.log.txt` end `pass=113 fail=0`; red controls end `112/1` and `97/16` respectively, including the source audit failure. Nine reconciler logs end with zero failures/OK. All 22 entries in `TESTS-RESULTS/2026-10-18+GH-1144/provenance.jsonl` matched their nonempty files' byte counts and SHA-256 values. Production log A–E records 0/3/0/4/0; D's “local main” text is explained correctly by the parameterized error message (`wave_reconcile.py:437`). These are inspected retained results, not fresh execution in this review. The local-clone origin/HEAD limitation is accurately disclosed in evidence README's final row and safely refused in its smoke log; the explicitly chosen resolution policy does not warrant an extra guard for that out-of-SOP clone shape.
- [Pass] **The step-6 recovery repair is appropriate.** `SKILL.md:135–137` copies the log beside the actual returned receipt path; retained `recovery-recipe-as-run.sh.txt` uses that same command and `recovery-recipe-run.log.txt` shows both provenance and recovery-run.log committed, then `main -> main`. This fixes the touched recipe's pre-existing nonexistent-file glob without adding machinery. Step 7 itself remains separately evidenced only through the stub-based resume fixture, as the README discloses.
- [Nit] **Make the skill's initial mandatory recital agree with the new base policy.** `skills/2-daily/express/SKILL.md:7`, `:27`, `:31`, `:33` still instruct cloning/pushing/landing specifically on development; the explanation at `:109–112` says “below” and therefore does not qualify those earlier mandatory instructions. Replace those destinations with the resolved base, noting development in Forge. This is the remaining wording consistency requested by plan Changes 5, with no executable behavior change.

Non-mutating probe ledger (both commands exited 0; Python parsed/read files only, no fixture executed):
```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PYPROBE'
from pathlib import Path
import ast, json, hashlib
p = Path('TESTS-RESULTS/2026-10-18+GH-1144')
rows = [json.loads(x) for x in (p/'provenance.jsonl').read_text().splitlines()]
assert rows
bad = [r['file'] for r in rows if (len((p/r['file']).read_bytes()) != r['bytes'] or hashlib.sha256((p/r['file']).read_bytes()).hexdigest() != r['sha256'])]
print('manifest entries:', len(rows), 'mismatches:', bad)
t = ast.parse((p/'prod-reconciler-check.py.txt').read_text())
print('production-check write_text targets:', [ast.unparse(n.func.value) for n in ast.walk(t) if isinstance(n, ast.Call) and isinstance(n.func, ast.Attribute) and n.func.attr == 'write_text'])
PYPROBE
```
Decisive output from the two read-only probes: `manifest entries: 22 mismatches: []`; `production check skip pull: True`; `production check stubs lifecycle: True`; AST write targets `["repo / 'README.md'", "repo / 'README.md'"]`. Both production modules parsed successfully. A path scan found no `/Users/`, `/home/`, or `/private/var/folders/` paths in the evidence directory. The first broader string heuristic for active-doc creation also matched README.md; the AST probe above resolves that ambiguity and is the evidence used for this finding.

Root cause: the independent production verification substitutes away the pull and lifecycle work that the approved review explicitly required; Fix site: the existing disposable-clone manual check and retained evidence; Why not upstream/downstream: the express stub fixture remains useful and no production behavior change is established by this evidence gap. Full tier-3 final-commit gate remains for the harness after review, not executed here.

Handing off to Producer (claude-a) — complete the bounded production reconciliation evidence and disposition the wording nit, then return for Round 2.

### Producer · Round 1 (claude-a)

- Production main-only reconciliation [Should] — **Implemented.** New recorded check `TESTS-RESULTS/2026-10-18+GH-1144/prod-reconciler-live.py.txt` → `prod-reconciler-live.log.txt`: the working clone starts one commit behind a bare origin whose only branch is the base, and runs canonical `wave_reconcile.main()` with `--commit <sha> --base <b> --gate` and **no** `--skip-pull`. Live: cleanliness, branch check, pull, reachability, base guard, receipt attribution, active-doc lifecycle (GH-1144 doc moved 2-WORKING → 3-COMPLETED, ROADMAP updated), `releases roadmap sync` and `check` against an initialised ledger, marathon replan. Stubbed: GitHub (slug, issue state CLOSED, hosted in-flight check) and the PDDA doc-hygiene gate — `run_validation_gate` is branch-agnostic and the scratch repo has no PDDA install (with it live, the run stops at that gate before any base-dependent step changes). Results: F main exit 0 (landing absent before the pull, present after); G development shape exit 0; H red control — only `pull_upstream(repo_root)` restored to the pre-change development pull — exit 2 `git pull --ff-only failed: fatal: couldn't find remote ref development`, nothing moved; I restored exit 0. README row, plan Evidence and provenance (24 records) updated.
- Skill recital wording [Nit] — **Implemented.** `SKILL.md` description (`:7`), recital items 1 and 5 and the overall goal (`:27`, `:31`, `:33`), and the policy line `:93` name the resolved base (`development` in XYZ Forge). No behaviour change.

Handing off to Reviewer (codex) for round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
