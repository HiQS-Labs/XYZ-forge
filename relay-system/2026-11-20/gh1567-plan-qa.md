# RELAY · GH-1567 plan QA: tick harness-config hint
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-20.
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
6. **Manual relay: commit only the relay file** (`relay(gh1567-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1567-TICK-HARNESS-HINT.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1567-TICK-HARNESS-HINT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-20
- Definition of Done: the plan in the artifact is Approved when it (a) fixes GH-1567's two "smallest first" items
  (scanner refusal message; `find-harness.sh --check` per-device config line) without touching the GH-1362 / GH-744 trust
  rule, (b) extends the existing subsystems only (no new writer, test, suite, registry entry; AGENTS.md "No new tests"),
  and (c) has acceptance checks that would reject the unfixed code.
- Operational envelope: local developer CLI/skill output text, Easy reversibility. Grade against the stated requirements,
  commensurate complexity and the repo's own threat model; do not ask for speculative machinery, new tests, or option 3
  (auto-write of config), which is an explicit non-goal. Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1567
- Source paths to read (at HEAD in your worktree): `skills/2-daily/merge-cleanup/scripts/scan_clones.py` (`_tick_binary`,
  `inspect_tick_claims`), `skills/1-hourly/relay-xyz/find-harness.sh` (the `check)` branch, `LIVE_HARNESS`, `_read_config`,
  `_canonical_clone`), `skills/1-hourly/relay-xyz/SKILL.md`, `test/find-harness.sh` (line ~205 consumes the
  `save this harness on this Mac:` line), `test/gh534_phase_a_tests.py`, `test/gh436-merge-cleanup.py`.

## Reviewer instructions (paraphrase-first, GH-1414)
BEFORE reading the source paths or the Definition of Done above, read only the artifact and write, as the first lines of
your review block: **What this proposes** (2-5 sentences), **How the existing system works, per this document** (2-5
sentences), and **What it's not** (short; ground each exclusion in the plan's sections, label inference). Then do the
source-backed technical validation, labelled as such. Then answer:
1. Are the claims about `scan_clones.py:323` and `find-harness.sh :424-431` true at HEAD? Is the vendored-branch fix site
   right (is `LIVE_HARNESS` set in the case that matters, e.g. vendored resolution with no XYZ_HARNESS)?
2. Does the plan keep the GH-1362 trust rule intact and avoid a second subsystem/writer?
3. For the unfixed code, what prevents it being reported as delivered, and where is the observed rejection (red control)?
   Do the stated acceptance checks observe the artifact that proves the outcome?
4. Does any existing test, doc or consumer pin the old strings or the exact `--check` output (e.g. parsing the
   `save this harness` line, or `--check` output expectations in a copied-skill / vendored fixture)?
5. Anything missing, over- or under-engineered? Cite file:line.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

**What this proposes:** Add a setup remedy to the scanner's refusal and show per-device harness configuration status during vendored `--check`. Update the skill sentence and verify both outputs using existing coverage and smoke receipts.

**How the existing system works, per this document:** The scanner intentionally excludes the audited tree's vendored tick and searches explicit configuration and PATH. The harness locator can resolve a vendored installation successfully while suppressing its live-harness save hint.

**What it's not:** The frontmatter excludes trusting vendored tick, automatic config writes, and new tests or suites. The preflight section limits the change to advisory output; inference: discovery precedence should remain unchanged.

**Source-backed technical validation**

swept file: yes

- [Pass] The two fix sites match HEAD: `scan_clones.py:323` returns `"tick binary not found"` with `verified: False`; `find-harness.sh:424-431` gates the save hint on `VENDORED=0`. Vendored resolution without overrides still computes `LIVE_HARNESS` from script ancestry, config, then bounded search (`find-harness.sh:303-317`). It can remain empty, as the plan's manual-command fallback anticipates. `_canonical_clone` additionally requires basename `XYZ-forge` and canonical origin (`find-harness.sh:32-40`); keep that condition on suggested save targets.
- [Pass] The plan explicitly excludes "Relaxing GH-1362 / GH-744" and "Auto-writing ~/.config/xyz/harness" (artifact frontmatter). Its three implementation steps change refusal text, advisory checklist text and a skill sentence, preserving the existing resolver and writer boundary. No additional pre-existing defect found in the artifact sweep beyond the acceptance gap below.
- [Should] Make the acceptance recipe isolate **all** scanner discovery channels and distinguish locating tick from verifying claims. The stated red setup (only unset `XYZ_HARNESS` / `MERGE_CLEANUP_TICK_BIN` and isolate config) does not yield a missing tick when running this checkout's scanner: its own-ancestor lookup wins before config (`scan_clones.py:264-267`), and PATH remains a fallback (`:285`). Also `_tick_binary()` returns a path, not `verified: True`; that result belongs to `inspect_tick_claims` and can arise from locks or absence of `.tick` without using tick (`:303-319`). Concrete fix: specify a copied scanner outside harness ancestry, controlled PATH, an audited `.tick` root without locks, and isolated HOME/config; clear `XYZ_REPO_ROOT` for locator probes too. Record the failing baseline assertions and after assertions against actual emitted detail/checklist, run the printed command in the isolated config, assert its saved bytes, then require scanner resolution to equal that saved harness's tick. If claiming `verified: True`, measure `inspect_tick_claims` with actual valid claims JSON; do not infer it from resolution. Include invalid config/no canonical live harness and valid config checklist branches in retained manual checks; existing suites remain unchanged.
  Observed input: HEAD scanner at its real `__file__`, `XYZ_HARNESS` and `MERGE_CLEANUP_TICK_BIN` unset, `XDG_CONFIG_HOME=$TMPDIR/absent-config` (nonexistent). Probe returned the worktree's `bin/tick`, not `None`.
  Affected scope: the plan's red/after acceptance recipe only; no requested production discovery or trust change.
  Falsifier: the copied-scanner fixture with no own-ancestor tick and no PATH tick must return `None` before config, emit the old bare refusal before the fix, and reject the new message/checklist assertions on baseline. After saving config, exact path equality must establish that config supplied resolution.
  Probe command (non-mutating AST extraction, no module entrypoint, fixture executable, or git):
  ```python
  # Run with: export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY'
  import ast, os, pathlib, typing, shutil
  p=pathlib.Path('skills/2-daily/merge-cleanup/scripts/scan_clones.py').resolve()
  t=ast.parse(p.read_text()); f=next(n for n in t.body if isinstance(n,ast.FunctionDef) and n.name=='_tick_binary')
  ns={'Optional':typing.Optional,'os':os,'Path':pathlib.Path,'__file__':str(p),'TICK_BIN_ENV':'MERGE_CLEANUP_TICK_BIN','shutil':shutil}
  exec(compile(ast.Module(body=[f],type_ignores=[]),str(p),'exec'),ns)
  os.environ.pop('XYZ_HARNESS',None);os.environ.pop('MERGE_CLEANUP_TICK_BIN',None);os.environ['XDG_CONFIG_HOME']=str(pathlib.Path(os.environ['TMPDIR'])/'absent-config')
  print('isolated config exists:',pathlib.Path(os.environ['XDG_CONFIG_HOME']).exists())
  print('_tick_binary:',ns['_tick_binary']())
  # PY
  ```
  Exit status: 0. Decisive output: `isolated config exists: False`; `_tick_binary: /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/rtl-wt.mQIOtC/bin/tick`.
- [Pass] Existing consumer `test/find-harness.sh:205-216` extracts the exact prefix `  save this harness on this Mac: `, executes the suffix, checks saved bytes, then checks config resolution. Preserve that prefix and its shell quoting. Existing vendored checks assert selected substrings and exit 0 (`test/find-harness.sh:65-72,264-269`), rather than a full-output snapshot. The named source/test string search found no old refusal-string pin; skill documentation already gives the XDG-aware manual command (`skills/1-hourly/relay-xyz/SKILL.md:130-135`).
- [Unverified — needs clone run] No acceptance baseline or post-fix checklist run has been witnessed here; no phase gate was configured in these reviewer instructions. The existing suite list is planned verification, not delivery evidence. Retain actual red/green results with `provenance.jsonl` under the planned receipts directory when implementation is tested in a disposable full clone.

**VERDICT: FAIL**

**Basis:** Scope and implementation direction are sound and proportionate. Tighten the acceptance recipe so the documented red control actually reaches the changed branch and the config remedy is proven to supply scanner resolution; the current environment recipe is insufficient at HEAD. This is a plan correction, not a request for another subsystem or new tests.

Handing off to Producer (claude-a) — revise the acceptance recipe and disposition the finding.

### Producer · Round 1

Disposition of Reviewer R1 `[Should]` (acceptance recipe): **Implemented.** Reproduced the reviewer's observation: the
in-tree scanner finds the worktree's own `bin/tick` before the config lookup, so the stated red setup would not reach the
changed branch, and `_tick_binary()` returns a path rather than `verified: True`. The Acceptance section of the plan now
specifies a copied scanner outside harness ancestry, controlled PATH, isolated HOME/XDG config, an audited temp repo with
`.tick/` and no locks, `XYZ_REPO_ROOT` cleared, assertions on emitted detail/checklist for baseline and fixed copies,
saved-bytes and `_tick_binary()` path-equality checks, `verified: True` only from a measured `inspect_tick_claims` run, and the
invalid-config / no-canonical-harness / valid-config branches as retained manual checks. No production scope changed; no tests added.
Other `[Pass]` findings acknowledged (keep the `save this harness on this Mac: ` prefix and quoting; canonical-clone condition on save targets).

Handing off to Reviewer (codex) for round 2.

### Reviewer · Round 2

**What this proposes:** Add the per-Mac setup remedy to the scanner refusal and show config readiness on vendored harness checks. Keep the implementation to the existing scanner, locator and skill documentation.

**How the existing system works, per this document:** The scanner excludes discovery through the audited checkout and uses trusted installation/configuration channels. The locator can successfully select vendored tick while its existing save hint is restricted to non-vendored resolution.

**What it's not:** The frontmatter excludes changing GH-1362 / GH-744 trust, automatic config writes, and new tests or suites. Inference from Plan steps 1–3: resolution precedence remains unchanged.

**Source-backed technical validation**

swept file: yes

- [Pass] Reviewed the entire revised artifact; no additional pre-existing defect found. The R1 acceptance finding is addressed by Acceptance's “outside any harness ancestry”, “controlled PATH with no tick”, isolated HOME/config and cleared overrides. The recipe measures saved bytes and exact resolved tick path; it no longer infers claim verification from discovery. This matches the distinct discovery and claims contracts in `scan_clones.py:254-285,321-350`.
- [Pass] Fix sites still match HEAD: `scan_clones.py:323` emits the bare refusal with `verified: False`; `find-harness.sh:424-431` restricts the save hint to `VENDORED=0`. Vendored live discovery tries script ancestry, config and bounded search even without XYZ_HARNESS (`find-harness.sh:303-317`). Plan step 2 correctly conditions a save target on `_canonical_clone`, while allowing the no-live-harness manual pointer; that helper requires basename and canonical origin (`find-harness.sh:32-40`).
- [Pass] Scope preserves the trust boundary and existing writer: frontmatter excludes “Relaxing GH-1362 / GH-744” and “Auto-writing ~/.config/xyz/harness”; Plan uses only refusal/checklist output and a skill sentence. Acceptance explicitly preserves the executable save-line prefix and quoting consumed by `test/find-harness.sh:205-216`. Vendored coverage checks substrings rather than full output (`test/find-harness.sh:69-72,264-269`); the named scanner suites contain no old-refusal literal pin. Existing manual instructions already use XDG-aware config (`skills/1-hourly/relay-xyz/SKILL.md:130-135`). No second subsystem or new suite is proposed.
- [Pass] The baseline refusal cannot meet the planned new-message assertion. Narrow AST probe below, exit 0: `resolution: None`; `baseline: {'has_claims': False, 'verified': False, 'details': 'tick binary not found'}`; `new-message assertion: False`. This measures the actual baseline function bodies with synthetic outside-harness `__file__` and a stubbed coordination-root lookup; it does not establish an end-to-end clone result.
  ```python
  # export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY'
  import ast, os, pathlib, shutil, typing
  p=pathlib.Path('skills/2-daily/merge-cleanup/scripts/scan_clones.py'); t=ast.parse(p.read_text())
  f=[n for n in t.body if isinstance(n,ast.FunctionDef) and n.name in ('_tick_binary','inspect_tick_claims')]
  root=pathlib.Path(os.environ['TMPDIR'])/'gh1567-r2'
  # Scratch audit/.tick directory was created beforehand, with no locks.
  ns={'Optional':typing.Optional,'Dict':typing.Dict,'Any':typing.Any,'os':os,'Path':pathlib.Path,'__file__':'/__gh1567_copied__/scan_clones.py','TICK_BIN_ENV':'MERGE_CLEANUP_TICK_BIN','shutil':shutil,'coordination_root':lambda p:p}
  exec(compile(ast.Module(body=f,type_ignores=[]),str(p),'exec'),ns)
  for k in ('XYZ_HARNESS','XYZ_REPO_ROOT','MERGE_CLEANUP_TICK_BIN'): os.environ.pop(k,None)
  os.environ.update(HOME=str(root/'home'),XDG_CONFIG_HOME=str(root/'config'),PATH=str(root/'empty-path'))
  print('resolution:',ns['_tick_binary']());r=ns['inspect_tick_claims'](root/'audit');print('baseline:',r)
  print('new-message assertion:',all(x in r['details'] for x in ('~/.config/xyz/harness','XYZ_HARNESS')))
  # PY
  ```
  An initial probe placed synthetic `__file__` under scratch inside this checkout: own-ancestor discovery found its tick, then the incomplete probe namespace raised NameError (exit 1). The corrected probe above excludes that ancestry; no tick executable was run by either probe.
- [Unverified — needs clone run] Actual baseline/fixed vendored checklist runs, saved-command execution, real claim verification and existing suites remain implementation acceptance work in a disposable full clone. The plan names their receipts directory; retain `provenance.jsonl` there. No phase gate is configured here and no later gate is assumed. Graph lookup was unavailable under the session's never-approval policy; validation used direct reads of the named sources.

**VERDICT: PASS**

**Basis:** Approve the plan, not delivery. Its bounded output changes satisfy the stated scope, and the revised acceptance procedure would reject unfixed output while proving the config remedy through saved bytes and exact resolution. No remaining blocking plan finding.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
