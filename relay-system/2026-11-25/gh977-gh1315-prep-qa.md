# RELAY · Preparation QA: #977 and #1315 Conveyor packets (Day 2 candidates)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 2

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
     change MUST carry `Observed input:`, `Affected scope:` (the input predicate the change would govern),
     and `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected
     result). `Observed input:` accepts two strict, non-speculative forms:
     (1) **Form 1 (observed failure or artifact contradiction):** a failing probe/gate output, or a concrete
     `fileA:line` vs `fileB:line` contradiction (e.g. IAM SA mismatch, inverted test, sibling guard omission);
     (2) **Form 2 (unrunnable runtime hazard trace):** permitted ONLY when reproduction requires an external
     service, multi-process concurrency, or a browser/container runtime forbidden in the relay worktree —
     must supply a hop-by-hop `file:line` trace plus an exact `Clone probe:` command/script for the Producer's
     disposable full clone. Default severity for an unexecuted Form 2 hazard is `[Should]`.
     A `[Blocker]` must cite an observed failure (Form 1); an unexecuted Form 2 hazard stays `[Should]`
     until a probe reproduces it, and remains pending probe verification until the Producer runs
     `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, read the probe before running it — refuse any probe that reaches
     the network, credentials, or paths outside the disposable clone and record the refusal as
     `[Unverified — clone probe failed/unavailable]` — then execute safe probes in a disposable full clone and
     record one of three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output;
     (b) Falsified → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored, refused, or
     environment unavailable → keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking
     `STATUS: Approved` until re-run cleanly or escalated/parked). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh977-gh1315-prep-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-25
- Reviewer sandbox is read-only on the artifact: set no edits. Read-only probes only (see `swept file` rule); do NOT run `validate.sh`, `test/*.sh` or pytest.

### What is under review (PREPARATION only, not an implementation)
Conveyor preparation packets for GitHub issues #977 and #1315 (HiQS-Labs/XYZ-forge), candidates for Day 2 of the Flywheel proving arc (ledger #1610, ranking #1616). Skill: `skills/1-hourly/conveyor/SKILL.md` (read it, esp. Preparation flow steps 3-5 and "Probe polarity").
Files (all committed at HEAD of this worktree, base `origin/development` 086b657ea):
- `PROJECT/1-INBOX/GH-977-ROADMAP-UPDATE-KEEPS-RATING.md` (new capture + Swarm Preflight Contract)
- `PROJECT/1-INBOX/GH-1315-LEGACY-PREVIEW-PARITY.md` (existing 2026-11-11 capture, refreshed)
- `TESTS-RESULTS/2026-11-25+GH-977/` and `TESTS-RESULTS/2026-11-25+GH-1315/` (`readiness_probe.py`, `SUMMARY.md`, `provenance.jsonl`, `probe-proof/`, `existing-suites/`)
- `releases.sql` diff (one new roadmap row for #977 via `roadmap pickup`; #1315 row untouched)
Source defects to read: `utils/py/releases_app.py:4108-4240` (`cmd_roadmap_update`), `skills/3-weekly/skills-army-hq/scripts/sync.py:242-300` and `intake.py:565-575`.
Issue text (read via the capture docs' quoted acceptance): #977 criteria are its `## Ask` bullets; #1315 criteria are its `## Expected` text. Neither issue body has an `## Acceptance` heading, so Preflight reports acceptance fidelity `unknown/no-issue-section` (advisory).

### Operational envelope and non-goals
Local developer tooling in a docs/ledger-only PR. No implementation, no queue enqueue, no labels, no issue edits, no new test suites (GH-831). Grade commensurate complexity; challenge bloat. Do not ask for new suites.

### Facts already measured (verify, do not take on faith)
- Preflight `--dry-run` + Jog promotion lint (`contract_probes_from_doc`, `promotion_probes`) both exit 0 for both docs on the prepared commit; probe verdict `unfixed`. After a simulated real fix (disposable clone) Preflight exits 4 STALE with probe `landed`; after a comment-only edit exit 0 `unfixed` (see `probe-proof/*/` and the patches there).
- The probes are `command` probes with `expect_nonzero: true`: the script exits 0 only when the fixed behavior is positively observed, so a crash reads as unfixed. Preflight `eval_probes` is `utils/py/swarm_preflight.py:250-305`.
- #1315 already had a row (In progress, accepted-start) and a `pending/0` Jog queue row from the 2026-11-11 trial; both preserved. #977 has no queue row.

### Definition of Done (grade against these; cite file:line)
1. Each capture's acceptance is copied verbatim from the issue and any deviation is declared in the form `extract_declared_deviations` parses (`utils/py/swarm_preflight.py:637-700`).
2. Each contract uses only supported probe shapes, has correct polarity (reads unfixed today, fixed after a real fix, unfixed after a comment-only edit), the gate is made only of existing suites, and artifacts are bounded (no new test suite).
3. The attempt/retry history recorded in each doc is accurate and nothing was reset (check `releases.sql`, `git diff origin/development -- releases.sql`).
4. Ratings: #977 written only through `roadmap pickup`; #1315 preserved. Rationale consistent with start-task's rating policy.
5. Nothing implements either fix, adds a label, enqueues into Jog, or edits the issues.

### Questions (answer each with file:line)
1. Does each probe (`readiness_probe.py`) actually discriminate the defect described in its issue, and could it read "fixed" for a wrong reason (e.g. a preview that merely errors for another cause, a text-only update refused for an unrelated reason)? Name the falsifier.
2. Is the `expect_nonzero: true` + fail-closed design sound given `eval_probes` treats any nonzero exit as landed when `expect_nonzero` is false and zero as landed when true? Any crash path that reads "landed"?
3. Is each gate command made only of existing suites, and will the contract's `artifacts` allow the real fix (e.g. #977 must edit `test/gh257-roadmap-ledger-fixes.sh` Case 8; does anything else pin the clearing behavior)?
4. Are the deviation declarations and acceptance lists faithful to the issue text and the 2026-11-25 triage notes (comments on #977 and #1315)?
5. Is the #1315 history accurate (queue row, work_events, trial #1386) and is anything about the preserved In-progress/accepted-start state a hazard for the Day 2 launch that the doc fails to state?
6. Is anything over-built or out of scope for a preparation-only PR? Does the diff touch anything it should not (`git diff --stat origin/development`)?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

swept file: no

Reviewed both complete captures, both complete readiness scripts, retained summaries/provenance, probe-state JSON and patches, and relevant existing source/suite paths. The ledger review was bounded to the two issues and their receipts; the base-to-head diff/full ledger sweep remains unverified because this driven turn explicitly forbids all Git commands. No suites, fixtures, Git commands, or real readiness scripts were executed. The checks below only parse files or execute extracted decision statements with in-memory inputs. No additional pre-existing defect was identified in the fully swept preparation files beyond the findings below; this is not an exhaustive claim about the large runtime modules.

Graph navigation: Verify intent, project `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation `2026-11-25T18:19:12Z`; this worktree is not indexed. Coverage reported missing new preparation paths and partial gh257/gh549 shell ranges. Read local source, including those ranges, rather than treating another checkout's index as proof.

- **[Should] F1 — #977 can report landed after an unrelated failed text update.** **Observed input:** Form 1: `PROJECT/1-INBOX/GH-977-ROADMAP-UPDATE-KEEPS-RATING.md:34` and `:100` require preserve, not refuse, but `TESTS-RESULTS/2026-11-25+GH-977/readiness_probe.py:61` accepts nonzero if output merely contains `rat`. Controlled input `returncode=1, stderr="operation failed: database is locked"` passes because `operation` contains `rat`; the row is unchanged because the write failed. The probe also never reads back the new raw text. **Affected scope:** no-token updates that fail or silently do nothing while an explicit-token update still works. **Fix:** require exit 0 and read back the requested replacement text as well as all five unchanged fields; remove the obsolete refuse allowance from the probe docstring. **Falsifier:** this exact refusal and a successful no-op must produce nonzero/unfixed; an actual persisted text-only update plus the existing explicit rescore control must produce zero/landed. Re-run the retained three-state proof after changing the probe.

  Decision-only command run here (exit 0, decisive output: `text-only roadmap update preserves saved ratings; explicit rated token still replaces them` followed by `FALSE POSITIVE: failed text-only update accepted; no subprocess or fixture executed`):

  ```python
  # python3 -B - <<'PY'
  import ast
  from pathlib import Path
  from types import SimpleNamespace
  p=Path('TESTS-RESULTS/2026-11-25+GH-977/readiness_probe.py')
  tree=ast.parse(p.read_text()); main=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='main')
  body=[n for n in main.body[0].body if 57<=n.lineno<=69]
  state={'ratings':[(80,70,90,60,320)]}
  def app(repo,*args):
      if 'probe rescored' in args[-1]:
          state['ratings']=[(10,20,30,40,None)]
          return SimpleNamespace(returncode=0,stdout='',stderr='')
      return SimpleNamespace(returncode=1,stdout='',stderr='operation failed: database is locked')
  exec(compile(ast.Module(body=body,type_ignores=[]),str(p),'exec'),dict(app=app,repo=None,URL='https://github.com/org/repo/issues/977',ratings=lambda repo:state['ratings']))
  print('FALSE POSITIVE: failed text-only update accepted; no subprocess or fixture executed')
  # PY
  ```

- **[Should] F2 — #1315 does not establish refusal parity or successful recorded-skill apply.** **Observed input:** Form 1: the capture requires both modes to name the adoption remedy (`PROJECT/1-INBOX/GH-1315-LEGACY-PREVIEW-PARITY.md:25`, `:87`), while `TESTS-RESULTS/2026-11-25+GH-1315/readiness_probe.py:66` checks only exit 2, `:67` accepts any `adopt` substring anywhere in combined output, and `:71` does not inspect apply's reason at all. Its positive control ends after preview (`:92`–`:98`), despite the contract saying recorded migration “still previews and applies” (`:87`). **Affected scope:** unrelated exit-2 refusals, warnings containing `adopt`, and fixes that break recorded-skill apply. **Fix:** check the actual error for the selected legacy directory in both modes, require the ownership refusal and actionable `intake.py update` remedy, and extend the existing manual control to apply the recorded skill and verify the managed link/retained archive. No new suite. **Falsifier:** unrelated refusal messages must remain unfixed; matching ownership refusals with the remedy and a successful recorded-skill preview/apply must read landed. Retain the clone CLI evidence, not just function output.

  Decision-only command run here (exit 0; output: `Preview error "adoption service unavailable" and apply error "permission denied" both pass the refusal assertions`):

  ```python
  # python3 -B - <<'PY'
  import ast
  from pathlib import Path
  p=Path('TESTS-RESULTS/2026-11-25+GH-1315/readiness_probe.py')
  t=ast.parse(p.read_text())
  for line,env in [(66,{'rc':2,'text':'adoption service unavailable'}),(67,{'text':'adoption service unavailable'}),(71,{'rc':2,'out':'','err':'permission denied'})]:
      n=next(n for n in ast.walk(t) if isinstance(n,ast.Assert) and n.lineno==line)
      exec(compile(ast.Module(body=[n],type_ignores=[]),str(p),'exec'),env)
  print('Preview error "adoption service unavailable" and apply error "permission denied" both pass the refusal assertions')
  # PY
  ```

- **[Should] F3 — #977's fixture inherits live connector configuration. Pending clone probe verification.** **Observed input:** Form 2: `TESTS-RESULTS/2026-11-25+GH-977/readiness_probe.py:28` copies the entire environment without disabling connectors or isolating HOME/device config; `:48`–`:53` performs real ledger writes. `utils/py/releases_app.py:1775` dispatches after every write; `:1632` disables dispatch only for `XYZ_WORK_CONNECTORS=0`. `utils/py/device_config.py:31` otherwise selects the inherited override or real `~/.xyz/device_config.json`; `utils/py/work_connectors/__init__.py:88`–`:118` loads enabled connectors, `:128`–`:139` supplies raw issue-number events, and `:458`–`:487` launches them. `utils/py/work_connectors/github_board.py:94`–`:99` chooses the configured repository and calls `set_issue_status(..., write=True)`. Thus the fixture's fake URL does not isolate the legacy board connector's issue 977 projection. This contradicts the probe's “All writes are confined” claim at `:12`. **Affected scope:** running this readiness probe on a machine with an enabled legacy board connector (no policy guard), including Preflight consumption. **Fix:** explicitly force `XYZ_WORK_CONNECTORS=0` in the child environment; also point device config/HOME at the fixture so the probe does not depend on operator settings. **Falsifier:** with a deliberately enabled offline connector, the uncorrected probe should emit a fixture event; after isolation it must emit none while still testing the ledger behavior. No live board call is needed or authorized. **Clone probe:** run the following only in a disposable full clone. It supplies a minimal environment and an offline connector through the existing registry seam; all fixture/config/log writes stay under that clone's `temp/`. Exit 1 with `connector_events` containing issue 977 reproduces the escape; exit 0 with no events is the expected fixed result. An errored/unavailable run keeps F3 open.

  ```bash
  python3 -B - <<'PY'
  import json, os, subprocess, sys, tempfile
  from pathlib import Path
  root = Path.cwd().resolve()
  probe = root / 'TESTS-RESULTS/2026-11-25+GH-977/readiness_probe.py'
  assert probe.is_file()
  scratch = root / 'temp'
  scratch.mkdir(exist_ok=True)
  with tempfile.TemporaryDirectory(prefix='qa977-connectors-', dir=scratch) as raw:
      work = Path(raw).resolve()
      assert work.is_relative_to(root)
      home = work / 'home'; home.mkdir()
      config = work / 'device.json'
      config.write_text(json.dumps({'work_connectors': {'github_board': {
          'enabled': True, 'project_owner': 'offline', 'project_number': 1,
          'repos': ['offline/fixture']}}}))
      log = work / 'events.jsonl'
      fake = work / 'offline_connector.py'
      fake.write_text('import json,os,sys\n'
          'batch=json.load(sys.stdin)\n'
          'with open(os.environ["QA977_LOG"],"a") as f: f.write(json.dumps(batch)+"\\n")\n'
          'print("advanced_to: %s" % max(e["id"] for e in batch["events"]))\n')
      empty_git_config = work / 'gitconfig'; empty_git_config.write_text('')
      env = {'PATH': os.environ['PATH'], 'HOME': str(home), 'TMPDIR': str(work),
          'PYTHONDONTWRITEBYTECODE': '1', 'XYZ_DEVICE_CONFIG_PATH': str(config),
          'XYZ_WORK_CONNECTORS': '1', 'QA977_LOG': str(log),
          'XYZ_WORK_CONNECTORS_REGISTRY': json.dumps({'github_board': str(fake)}),
          'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_GLOBAL': str(empty_git_config),
          'GIT_TERMINAL_PROMPT': '0', 'GH_CONFIG_DIR': str(home / 'gh')}
      run = subprocess.run([sys.executable, '-B', str(probe)], cwd=root,
          env=env, capture_output=True, text=True, timeout=120)
      events = [e for line in (log.read_text().splitlines() if log.exists() else [])
          for e in json.loads(line)['events']]
      print('readiness_rc=', run.returncode, 'connector_events=', events)
      print(run.stdout, run.stderr)
      if not events and run.returncode != 0:
          # The unfixed ledger normally fails this assertion; other failures are inconclusive.
          assert 'text-only update dropped the saved rating' in run.stderr, 'probe errored before measurement'
      raise SystemExit(1 if events else 0)
  PY
  ```

- **[Nit] F4 — repair the #1315 ledger receipt pointer.** `TESTS-RESULTS/2026-11-25+GH-1315/provenance.jsonl:9` names `ledger-readback-977-1315.json` in its own directory, where it does not exist. Its `SUMMARY.md:22` correctly points to the sibling GH-977 directory. Resolve the provenance path as `../2026-11-25+GH-977/ledger-readback-977-1315.json`. Read-only Python check `json.loads(p.read_text().splitlines()[8]); (p.parent / row['output']).is_file()` exited 0 and printed `1315 ledger provenance output exists: False`.

- **[Pass] Q2 / supported shape:** both contracts use the supported command shape with `expect_nonzero: true` (`GH-977` capture `:93`–`:95`; `GH-1315` capture `:80`–`:82`). `utils/py/swarm_preflight.py:283`–`:297` maps a nonzero command to unfixed and an execution exception to blocked. A normally propagated crash does not read landed; F1/F2 identify errors the scripts themselves accept as success. The retained `probe-proof/*/preflight-*.json` report `unfixed`, `landed`, `unfixed` with exit receipts 0, 4, 0 for each issue; both summaries' table at lines 10–14 accurately describes those recorded results. These are inspected Producer receipts, not independently replayed CLI results.

- **[Pass] Q3 / bounded gates and artifacts:** the capture gates (`GH-977:83`, `GH-1315:72`) name existing suites only. GH-977 artifacts include the gh257 suite at `:87`; its existing Case 8 (`test/gh257-roadmap-ledger-fixes.sh:147`–`:152`) pins clearing, and the retained red-control output ends `FAIL: expected all rating columns to be NULL, found non-null values` / `exit=1`. Literal searches in `test/` found this clearing expectation; the other NULL-rating matches in `test/gh69-roadmap-shadow.sh:253`–`:313` concern add/rate rather than update. This is a bounded search, not proof of all possible pins. GH-1315's existing wrapper skips with exit 0 without pytest (`test/skills-army-hq.sh:10`–`:15`); the capture explicitly warns at `:48`, and its real retained suite log ends `34 passed, 4 subtests passed` / `exit=0`. Require that interpreter prerequisite at execution; no later relay gate is assumed.

- **[Pass] Q4 / acceptance and ratings:** read the live issue bodies/comments through the GitHub connector. GH-977 capture `:31`–`:33` copies the three Ask bullets, and its `:42`–`:44` declares additions consistent with [triage comment 7174351131](https://github.com/HiQS-Labs/XYZ-forge/issues/977#issuecomment-7174351131). GH-1315 capture `:23` copies the first Expected paragraph and `:34` explicitly replaces the alternative design, consistent with [triage comment 7174351181](https://github.com/HiQS-Labs/XYZ-forge/issues/1315#issuecomment-7174351181). A read-only import of `extract_contract`, `extract_declared_deviations`, and `contract_probes_from_doc` exited 0: both contracts nonempty, labels nonempty, reason `None`; #977 has 3 added/0 malformed, #1315 has 4 added/1 changed/0 malformed. The parser is `utils/py/swarm_preflight.py:637`–`:705`. No issue edit to invent an Acceptance heading is needed. The rating rationales (`GH-977:68`–`:73`, `GH-1315:62`) retain neutral appeal and cheapness direction from `skills/1-hourly/start-task/SKILL.md:448`–`:474`; #977 explicitly bounds its recurrence evidence to issue/comments.

- **[Pass] Q5 / current history, with launch caution:** `releases.sql:990`, `:1093`, `:3930`, `:3932`, `:3934`, `:5835`, `:5837`, `:5839` contain the described #1315 rating, pending/0 unleased queue row, pickup/update/add receipts and accepted-start event. `TESTS-RESULTS/2026-11-11+GH-1386/SUMMARY.md:7`–`:17` records an initial #1171 promotion refusal, then the resumed loop's reviewer-credit failure; #1315 was never dispatched. The refreshed capture's `:56` compresses that history to the resumed loop; the underlying attempt conclusion is supported. Its prose “held” is not a queue pause: `utils/py/jog_run.py:2843`–`:2848` selects pending rows. Day 2 must revalidate/reuse that existing row and avoid treating the old accepted-start as fresh approval. Preserve its history; do not reset it or add a second row.

- **[Unverified — needs Producer diff receipt] Q6 / no unrelated changes:** the local runtime still contains the original defects (`utils/py/releases_app.py:4230`–`:4233`; `skills/3-weekly/skills-army-hq/scripts/sync.py:281`–`:285`), while simulated implementation patches are evidence only. The current SQL contains #977's pickup receipt (`releases.sql:4386`) and rated row (`:1057`), and no #977 queue INSERT was found. This supports the intended preparation scope, but does not prove the full diff or that historical rows were unchanged. Before the next review retain the Producer's `git diff --stat origin/development` and `git diff origin/development -- releases.sql` output for inspection; do not ask this reviewer to violate the no-Git turn rule. Live issues currently have only the `bug` label; absence of all past external writes cannot be established from the local artifact. Apart from the above corrections, the existing manual checks and receipts are proportionate; no new suite or subsystem is requested.

Handing off to Producer (claude-a): correct F1/F2/F4, execute the offline disposable-clone probe for F3 and disposition it with evidence, refresh affected readiness receipts, and provide the bounded diff evidence. Do not implement either product fix in this preparation turn.

VERDICT: FAIL
Basis: Two measured decision-check false positives, an unverified connector-containment hazard with a complete clone probe, and one broken evidence pointer remain open; full diff verification is also outstanding under the driven-turn no-Git restriction.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
