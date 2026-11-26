# RELAY · Preparation QA: #977 and #1315 Conveyor packets (Day 2 candidates)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
-->

NEXT: Producer
STATUS: Approved
ROUND: 4 / 4

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

### Producer · Round 1

Each finding re-read against the code and re-measured in a disposable full clone before acting. Round-2 probe hardening is committed at `a7b620924` (evidence: `TESTS-RESULTS/2026-11-25+GH-977/review-round1-fixes/`, `.../GH-1315/review-round1-fixes/`, and the refreshed `probe-proof/` dirs).

- [Should] F1 #977 probe accepts a failed/skipped text update: **Implemented.** `readiness_probe.py` now requires the text-only update to exit 0, reads back the requested `raw_text`, and keeps all five fields; the refuse allowance and its docstring text are removed. Falsifiers: an update that refuses (exit 3, row unchanged) and one that exits 0 without persisting both read unfixed (probe exit 1); the preserve-shape simulated fix reads landed (exit 0); a comment-only edit reads unfixed. Three-state proof re-run: Preflight/Jog lint exits 0/0 unfixed, 4/0 simulated fix, 0/0 comment-only, for both issues. Note: the issue's alternative "refuse" shape therefore cannot read landed; the capture already declares preserve as the chosen shape (deviation list).
- [Should] F2 #1315 probe does not establish refusal parity or recorded-skill apply: **Implemented.** The probe parses the CLI JSON, selects the error entry whose path is the legacy folder, requires exactly one, requires it to name the adoption remedy, and requires apply's entry to equal preview's. The positive control now also applies the recorded skill and checks the managed link and the single retained archive ZIP. Falsifier: an unrelated preview refusal ("Permission denied (unrelated, no remedy)") reads unfixed (exit 1); the simulated fix reads landed (exit 0); comment-only reads unfixed. I did not require the literal `intake.py update` string, because the issue only gives that path for a payload that already matches; the probe requires the adoption remedy, and the capture's criteria name `intake.py update`.
- [Should, Form 2] F3 #977 fixture inherits connector config: **Reproduced, then Implemented.** Reviewer's `Clone probe:` run in the disposable verify clone (offline connector via the registry seam, all writes under that clone's `temp/`): the pre-hardening probe (commit `b1539feb1`) produced `connector_events= 2 [977, 977]`, exit 1. After hardening (child env: `XYZ_WORK_CONNECTORS=0`, fixture `HOME`, fixture `XYZ_DEVICE_CONFIG_PATH`) the same script gives `connector_events= 0`, and the probe still fails on the unfixed defect as intended. On this machine `github_board` is `enabled: false` in the real device config (read-only check), so none of the earlier runs reached a board. The docstring claim is now true.
- [Nit] F4 #1315 provenance pointer: **Implemented.** `provenance.jsonl` row now points at `../2026-11-25+GH-977/ledger-readback-977-1315.json` (exists).
- Q5 caution: **Implemented.** The #1315 capture now says "held" is not a queue pause (Jog selects `pending` rows, `jog_run.py:2843-2848`), Day 2 must reuse the existing row, the 2026-11-11 accepted-start is history, and the trial's three Jog calls (two admission refusals, one loop) are recorded.
- Q6 diff receipt: **Provided.** `TESTS-RESULTS/2026-11-25+GH-977/diff-evidence/` holds `git diff --stat origin/development` (69 files, all under the two capture docs, `TESTS-RESULTS/2026-11-25+GH-977|1315/`, this relay file, and `releases.db`/`releases.sql`) and `git diff origin/development -- releases.sql`, which is exactly seven lines: generation 2966->2967 (two lines), one new `roadmap_items` row, one `roadmap-pickup` op receipt and one `parked` work event, all for #977. No historical row is touched and there is no #977 `jog_queue` insert.

No product fix was implemented. Handing off to Reviewer for round 2.

### Reviewer · Round 2

swept file: no

Read both complete captures and readiness scripts, the summaries/provenance, remediation receipts and simulated patches, the retained diff, and the relevant runtime decision paths. The whole large runtime modules and unrelated ledger history were not swept; this is a bounded preparation review, not implementation QA. No additional pre-existing defect was identified in the fully read capture/probe files beyond the remaining F2 weakness below. No Git command, executable fixture, suite, Preflight run or phase gate was executed this turn; no phase gate is configured here. CLI results below are inspected Producer receipts, not an independent replay.

Graph: Verify tier; all 87 project entries checked, this worktree is not indexed. Nearest project is `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation `2026-11-25T18:19:12Z`. Symbol lookup returned the four relevant decision functions without pagination remaining. Coverage reports missing new preparation content and partial gh257/gh549 shell ranges; local source was used, including the reported shell ranges. Another checkout's index is not evidence of this artifact's freshness.

- **[Should] F2 remains OPEN — the selected error still need not explain ownership or give an adoption remedy.** **Observed input:** Form 1, decision-only reproduction: JSON `{"errors":[{"path":"/fixture/app skills/xyz","error":"adoption service unavailable"}]}` with exit 2 in both modes passes all three refusal assertions in `TESTS-RESULTS/2026-11-25+GH-1315/readiness_probe.py:72`, `:73`, `:77`. The string supplies neither the missing ownership reason nor a remedy, contradicting the capture's acceptance at `PROJECT/1-INBOX/GH-1315-LEGACY-PREVIEW-PARITY.md:23` and remediation at `:88`. Parity and the positive control are improved, but parity of an unrelated failure does not establish the required refusal. The new retained falsifier (`review-round1-fixes/probe-1315-f2-unrelated.txt:7`) uses `Permission denied (unrelated, no remedy)` and therefore misses the original `adopt` substring counterexample. **Affected scope:** identical unrelated exit-2 errors for the selected unadopted folder that contain `adopt`, with recorded-skill migration otherwise working. **Fix:** strengthen this existing manual probe to require the ownership explanation and an actionable adoption instruction for the selected skill; for this matching-payload fixture the capture already specifies `intake.py update xyz --source ...`. An equivalent actionable formulation is fine; no new suite is requested. **Falsifier:** the exact JSON above must fail the refusal checks, while the retained simulated fix's `Not adopted: ... no recorded source; adopt it first (receipt-only: intake.py update ...)` must pass. Retain a full CLI replay in the disposable clone and refresh the three-state proof after the probe change.

  Exact decision-only command executed (exit **0**; decisive output: `FALSE POSITIVE: identical unrelated error "adoption service unavailable" passes all refusal assertions (72, 73, 77)`). It extracts only the JSON selector and assertions; it does not execute the fixture or its subprocess calls:

  ```bash
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  python3 -B - <<'CHECK'
  import ast,json
  from pathlib import Path
  p=Path('TESTS-RESULTS/2026-11-25+GH-1315/readiness_probe.py')
  t=ast.parse(p.read_text())
  f=next(n for n in ast.walk(t) if isinstance(n,ast.FunctionDef) and n.name=='refusal')
  ns={'json':json}
  exec(compile(ast.Module(body=[f],type_ignores=[]),str(p),'exec'),ns)
  ns.update(rc=2,out=json.dumps({'errors':[{'path':'/fixture/app skills/xyz','error':'adoption service unavailable'}]}),err='')
  ns['preview_errors']=ns['refusal'](ns['out'])
  for line in (72,73,77):
      n=next(n for n in ast.walk(t) if isinstance(n,ast.Assert) and n.lineno==line)
      exec(compile(ast.Module(body=[n],type_ignores=[]),str(p),'exec'),ns)
  print('FALSE POSITIVE: identical unrelated error "adoption service unavailable" passes all refusal assertions (72, 73, 77)')
  print('Decision-only check; no readiness script, subprocess, fixture, or Git command executed')
  CHECK
  ```

- **[Pass] F1 CLOSED / Q1 #977.** `TESTS-RESULTS/2026-11-25+GH-977/readiness_probe.py:73`–`:83` now requires success, persisted replacement text, all five retained ratings, and successful explicit rescore. The two retained falsifiers end `rc=1`, respectively naming `text-only update must succeed` and `text-only update must persist the requested text`; the simulated-fix receipt ends `rc=0` (`review-round1-fixes/probe-977-f1-refuse.txt:7`, `probe-977-f1-noop.txt:7`, `probe-977-simfix.txt:2`). This closes the refusal/no-op false positive. Q1 #1315 remains F2; its positive apply control is now present at `readiness_probe.py:104`–`:107` and the CLI receipt `review-round1-fixes/probe-1315-simfix.txt:1`–`:2` records success.

- **[Pass] F3 CLOSED on retained clone evidence.** The #977 child environment explicitly overrides connectors, HOME and device config (`readiness_probe.py:30`–`:35`). `review-round1-fixes/f3-temp-old_probe_977.py.txt:1` records `connector_events= 2 [977, 977]`; `f3-2026-11-25+GH-977-readiness_probe.py.txt:1` records `connector_events= 0 []`, and its lines 3–5 show the expected unfixed-rating assertion, so this was not an early unrelated failure. The retained clone script was read; its generated offline connector also passed an in-memory syntax compile. I did not inspect operator configuration or infer that all historical runs were side-effect free.

- **[Pass] F4 CLOSED.** `TESTS-RESULTS/2026-11-25+GH-1315/provenance.jsonl:9` now names `../2026-11-25+GH-977/ledger-readback-977-1315.json`. Read-only JSON/path checks exited 0 and reported `977 all provenance output paths exist` and `1315 all provenance output paths exist`.

- **[Pass] Q2 / polarity and retained state proof.** `utils/py/swarm_preflight.py:283`–`:297` still maps command nonzero to unfixed for `expect_nonzero: true`; propagated crashes do not become landed. Both complete scripts leave exceptions uncaught. Both `SUMMARY.md:10`–`:14` tables agree with the parsed retained JSON/RC files: `e331a4d98` → exit 0/unfixed, `448cea7a8` → exit 4/landed, `6cbef1e44` → exit 0/unfixed. This establishes recorded polarity, not immunity to a script accepting the wrong condition (F2).

- **[Pass] Q3 / existing gates and bounded artifacts.** The contracts still name existing suites (`GH-977` capture `:83`, `GH-1315` capture `:73`); #977 includes the suite requiring change at `:87`. `test/gh257-roadmap-ledger-fixes.sh:147`–`:152` still pins clearing. Its retained code-only red control ends `FAIL: expected all rating columns to be NULL, found non-null values` / `exit=1`; the adjusted simulated-fix gh257 and gh549 receipts end `ALL PASSED` and `125 passed, 0 failed` / `exit=0`. The #1315 real suite receipt ends `34 passed, 4 subtests passed` / `exit=0`, while its capture `:48` expressly warns about the missing-pytest skip. No new suite or product implementation is requested by this review. Other possible source-text pins remain bounded by round 1's search, not an exhaustive fresh search claim.

- **[Pass] Q4 / acceptance and ratings remain consistent with the reviewed decisions.** The capture declarations remain at `GH-977:31`–`:44` and `GH-1315:23`–`:38`: preserve-on-omit and retaining the current ownership rule are explicit. Round 1's cited live issue/comment comparison is retained; live GitHub was not queried again this turn. #977 still declares provisional `65/55/50/85` at `:68` with the recurrence bounds at `:71`; #1315 retains `60/45/50/85` at `:63`. F2 concerns measuring the accepted remedy, not changing that acceptance.

- **[Pass] Q5/Q6 / supplied diff receipt closes the requested evidence gap, with its stated cutoff.** `TESTS-RESULTS/2026-11-25+GH-977/diff-evidence/README.md:1` pins capture to `a7b620924` before adding that evidence directory. The SQL diff adds only the #977 roadmap row, pickup receipt and parked event (`releases.sql.diff:26`, `:34`, `:42`), plus generation changes; it contains no #1315 history mutation or queue insert. The retained stat lists preparation docs/evidence, this relay and the ledger pair, with no runtime source edit. Local source still contains the original defects (`utils/py/releases_app.py:4230`–`:4233`; `skills/3-weekly/skills-army-hq/scripts/sync.py:281`–`:285`). The #1315 capture now records the three trial calls and explicit pending-row/accepted-start caution at `:56`–`:59`. Its historical accepted-start is not new launch authorization. These are inspected receipts with a declared cutoff, not a current Git diff or proof of absence of all external writes. The preparation is otherwise proportionate; the remaining correction is local to the existing probe.

VERDICT: FAIL
Basis: F1, F3 and F4 are closed, and the missing diff receipt is supplied. F2 remains open on a reproduced decision-check false positive. Round 2/2 is exhausted, so STATUS is Escalated rather than Approved; no later gate is assumed.

Handing off to Producer (claude-a) for escalation to the operator: F2 needs the bounded probe correction and clone evidence above before a newly authorized review cycle. Do not implement either product fix or silently extend the round cap.

### Producer · Round 2

Operator authorization (2026-11-25, Flywheel project only; newest comment on #1315): review loops are capped at 4 rounds in total and narrow findings are repaired and re-reviewed without stopping, so this relay reopens at ROUND 3 / 4 rather than staying Escalated. Nothing else about scope changed: preparation only.

- [Should] F2 #1315 probe does not require the ownership reason and remedy: **Implemented.** `readiness_probe.py` now requires, for the unadopted folder, exactly one error entry in preview and one in apply, equal to each other, that (a) states the ownership reason (`not adopted` / `unadopted` / `no recorded source` / `not recorded` / `no recorded skill`) and (b) gives the remedy for that skill (`intake.py update xyz ... --source`). Falsifiers, run in the disposable verify clone against `f2115e986` (`TESTS-RESULTS/2026-11-25+GH-1315/review-round2-fixes/`): the reviewer's own input (`adoption service unavailable`, exit 2 in both modes) now fails the probe (exit 1); an error with only the reason, and one with only the command, also fail (exit 1); the simulated real fix passes (exit 0); a comment-only edit stays unfixed (exit 1); unfixed today is exit 1. The contract's remediation text and the capture's probe description state the required elements, so a builder knows what the probe accepts.
- Three-state proof and both consumers re-run on the new commit, for both docs: unfixed `f2115e986` Preflight 0 / Jog lint 0 (probe unfixed); simulated fix `ce717e069` Preflight 4 STALE / Jog lint 0 (probe landed); comment-only `9ba644fe2` Preflight 0 / Jog lint 0 (probe unfixed). #977's preparation was not changed beyond re-running its consumers.
- Q5/Q6 evidence from round 1 stands; the diff receipt cutoff is unchanged because the only files changed since are the #1315 probe/doc/evidence and this relay file.

No product fix was implemented. Handing off to Reviewer for round 3.

### Reviewer · Round 3

swept file: no

F2 is closed; one evidence-attribution correction remains before approval. Read both complete captures and readiness scripts, summaries/provenance, refreshed proof JSON/RC/lint receipts, simulated patches, remediation receipts, retained diff and the relevant runtime source. No additional defect was found in the fully read capture/probe files. The large runtime modules and whole ledger were not swept; this is preparation QA. No Git, fixture, suite, Preflight or phase gate was executed; no phase gate is configured. Runtime results below are inspected Producer receipts, not independent CLI replays.

Graph: Verify intent; all 87 project entries checked, this worktree remains unindexed. Nearest project `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation `2026-11-25T18:19:12Z`; symbol search completed without pagination remaining. Coverage reports missing preparation files and partial gh257/gh549 shell ranges. Read local source and the reported ranges. Graph trace access was denied; local source supplied the bounded call-path evidence. Another checkout's metadata does not establish this worktree's freshness.

- **[Should] F5 — refreshed proof files retain stale provenance SHAs.** **Observed input:** Form 1 artifact contradiction: `TESTS-RESULTS/2026-11-25+GH-977/provenance.jsonl:1,3,5` and `TESTS-RESULTS/2026-11-25+GH-1315/provenance.jsonl:1,3,5` attribute the three Preflight outputs to `e331a4d98`, `448cea7a8`, `6cbef1e44`. The named files now contain `f2115e986`, `ce717e069`, `9ba644fe2`, respectively, at `probe-proof/{1-unfixed-at-prepared-commit,2-simulated-fix,3-comment-only-edit}/preflight-977.json:57` and the corresponding `preflight-1315.json:55`. Both `SUMMARY.md:4` explicitly promise that each provenance row names the exact SHA it ran on. The refreshed outputs and summaries agree; their provenance does not. **Affected scope:** attribution of the six refreshed Preflight runs and paired Jog lint receipts (rows 2/4/6 likewise retain earlier SHAs). This does not invalidate the observed probe behavior, but it prevents truthful run-to-revision attribution in the preparation evidence. **Fix:** reconcile these existing provenance entries with the retained runs, including recording metadata/notes and paired Jog receipts. If preserving historical entries, point them at actual retained historical outputs and add entries for the new outputs; do not leave old and new runs sharing overwritten paths without explanation. No new suite, runtime change or replay is needed when the retained run records establish the correct attribution. **Falsifier:** each current Preflight provenance `source_sha` equals its nonempty output's `freshness.evaluated_ref_commit`, and the paired Jog entries identify the same state/revision as their retained state receipts; the check below then exits 0 with `mismatches= 0`.

  Exact read-only command executed, exit **1**. Decisive output: `[(977, 1, 'e331a4d98', 'f2115e986'), (977, 3, '448cea7a8', 'ce717e069'), (977, 5, '6cbef1e44', '9ba644fe2'), (1315, 1, 'e331a4d98', 'f2115e986'), (1315, 3, '448cea7a8', 'ce717e069'), (1315, 5, '6cbef1e44', '9ba644fe2')]` and `mismatches= 6`.

  ```bash
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  python3 -B - <<'CHECK'
  import json
  from pathlib import Path
  mismatches=[]
  for issue in (977,1315):
      root=Path(f'TESTS-RESULTS/2026-11-25+GH-{issue}')
      for line,text in enumerate((root/'provenance.jsonl').read_text().splitlines(),1):
          row=json.loads(text)
          if row['output'].endswith(f'preflight-{issue}.json'):
              p=root/row['output']; assert p.stat().st_size>0
              actual=json.loads(p.read_text())['freshness']['evaluated_ref_commit']
              if row['source_sha']!=actual:
                  mismatches.append((issue,line,row['source_sha'][:9],actual[:9]))
  print(mismatches)
  print('mismatches=',len(mismatches))
  raise SystemExit(bool(mismatches))
  CHECK
  ```

- **[Pass] F2 CLOSED / Q1 #1315.** `TESTS-RESULTS/2026-11-25+GH-1315/readiness_probe.py:37-44` now requires both the ownership reason and skill-specific adoption command; `:84-94` applies that requirement to both modes and checks parity. `:97-100` checks refusal side effects, and `:115-123` covers recorded-skill preview and apply. The exact previous counterexample now fails at the intended assertion (`review-round2-fixes/probe-1315-f2-reviewer-adoption-service-unavailable.txt:7-8`, assertion plus `rc=1`), as do reason-only and remedy-only messages in the sibling receipts. `review-round2-fixes/probe-1315-simfix.txt:1-2` records the complete CLI success and `rc=0`; unfixed and comment-only receipts fail at the preview assertion. These close the requested CLI falsifier and positive-control gap. Independent decision-only extraction below exited **0**, output `unrelated, reason-only, remedy-only, complete: [False, False, False, True]`; no fixture or subprocess was invoked.

  ```bash
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  python3 -B - <<'CHECK'
  import ast,re
  from pathlib import Path
  p=Path('TESTS-RESULTS/2026-11-25+GH-1315/readiness_probe.py')
  f=next(n for n in ast.parse(p.read_text()).body if isinstance(n,ast.FunctionDef) and n.name=='explains_refusal')
  ns={'re':re}; exec(compile(ast.Module(body=[f],type_ignores=[]),str(p),'exec'),ns)
  messages=['adoption service unavailable','Not adopted: xyz has no recorded source; adopt it first','Cannot proceed; run intake.py update xyz --source /x','Not adopted: xyz has no recorded source; adopt it first (receipt-only: intake.py update xyz --source /x)']
  results=[ns['explains_refusal'](s) for s in messages]
  assert results==[False,False,False,True],results
  print('unrelated, reason-only, remedy-only, complete:',results)
  CHECK
  ```

- **[Pass] F1/F3/F4 remain CLOSED / Q1 #977.** `TESTS-RESULTS/2026-11-25+GH-977/readiness_probe.py:73-83` still requires successful persisted text, preserved five-field rating and explicit rescore. Its `review-round1-fixes/probe-977-f1-refuse.txt:7-8` and `probe-977-f1-noop.txt:7-8` fail at the intended assertions; `probe-977-simfix.txt:2` records `rc=0`. Connector isolation remains explicit at `readiness_probe.py:33-34`; retained F3 receipts show `connector_events= 2 [977, 977]` before and `connector_events= 0 []` after (`f3-temp-old_probe_977.py.txt:1`, `f3-2026-11-25+GH-977-readiness_probe.py.txt:1`), with the expected unfixed rating failure. The corrected sibling ledger pointer remains at `TESTS-RESULTS/2026-11-25+GH-1315/provenance.jsonl:9`; a read-only parse confirmed all provenance output paths exist. F5 concerns attribution, not missing paths.

- **[Pass] Q2 / polarity and recorded states.** `utils/py/swarm_preflight.py:283-297` maps command success to landed only with `expect_nonzero: true`; uncaught probe failures remain unfixed. Both contracts use that shape (`GH-977` capture `:93-95`, `GH-1315` capture `:81-83`). Read-only parsing of all six refreshed reports and RC files found `f2115e986` → 0/unfixed, `ce717e069` → 4/landed, `9ba644fe2` → 0/unfixed; all six Jog lint RCs are 0 and their text ends `JOG LINT OK`. Both `SUMMARY.md:10-14` tables match those outputs. F5 must align the provenance rows with this evidence.

- **[Pass] Q3 / existing gates and bounded artifacts.** Capture gates remain the existing suites (`GH-977:83`, `GH-1315:73`), and #977 includes gh257 as an artifact (`:87`). Its current `test/gh257-roadmap-ledger-fixes.sh:147-152` pins clearing; the retained code-only red control fails exactly there (`TESTS-RESULTS/2026-11-25+GH-977/existing-suites/gh257-codefix-only-RED-CONTROL.txt:36-37`). Adjusted simulated-fix receipts record gh257 success (`gh257-roadmap-ledger-fixes-simulated-fix.txt:43-44`) and gh549 `125 passed, 0 failed` (`gh549-work-events-simulated-fix.txt:162-163`). #1315's pytest prerequisite warning remains in its capture `:48`, matching the wrapper at `test/skills-army-hq.sh:10-15`; its real retained result is `34 passed, 4 subtests passed` (`TESTS-RESULTS/2026-11-25+GH-1315/existing-suites/skills-army-hq-simulated-fix-python314-pytest.txt:46-47`). This is bounded existing coverage; no exhaustive fresh search for every source-text pin is claimed.

- **[Pass] Q4 / acceptance and ratings.** Complete capture review found the issue-derived criteria and declared choices retained at `PROJECT/1-INBOX/GH-977-ROADMAP-UPDATE-KEEPS-RATING.md:31-44` and `PROJECT/1-INBOX/GH-1315-LEGACY-PREVIEW-PARITY.md:23-38`. Round 1's live issue/triage comparison remains the external evidence; no fresh GitHub query was made this turn. Rating rationales remain at #977 `:68-73` and #1315 `:63`, with neutral appeal, cheapness direction and recurrence limits. #1315's revised probe description/remediation (`:47`, `:88`) now matches what the probe measures.

- **[Pass] Q5/Q6 / preserved history and preparation scope, within the retained diff cutoff.** `releases.sql:990,1093,5835,5837,5839` preserves #1315's rating, pending/0 queue row and prior accepted-start history. Its capture `:56-59` records the trial and warns that pending remains selectable (`utils/py/jog_run.py:2843-2848`), so Day 2 must reuse/revalidate that row. The bounded SQL diff adds only #977's pickup row/receipt/parked event and generation changes (`TESTS-RESULTS/2026-11-25+GH-977/diff-evidence/releases.sql.diff:26,34,42`). The retained stat lists only preparation/evidence/relay/ledger files; its cutoff is explicitly `a7b620924` (`diff-evidence/README.md:1`). Current runtime still has the original defects (`utils/py/releases_app.py:4230-4233`, `skills/3-weekly/skills-army-hq/scripts/sync.py:281-285`); simulated patches are evidence only. No current Git diff or absence of all external writes is claimed. No extra subsystem or suite is warranted.

Handing off to Producer (claude-a): correct F5's provenance attribution and return for round 4. Keep F1-F4 closed, preserve the runtime evidence, and do not implement either product fix in this preparation turn.

VERDICT: FAIL
Basis: The behavioral probe findings are closed. Six refreshed Preflight outputs still contradict their recorded source SHAs; the paired Jog attribution also needs reconciliation. The remaining correction is bounded to existing evidence metadata, with no new runtime replay required.

### Producer · Round 3

- [Should] F5 refreshed proof files retain stale provenance SHAs: **Implemented.** Cause confirmed: the round-2 refresh script updated the provenance rows in memory but wrote the file back only for #1315's falsifier row. Fixed by setting every  row's  (and its paired Jog-lint row's) from the  in the retained  for that state, with a note saying so. The reviewer's own check, re-run unchanged against the files, now reports ; rows 1-6 of both files read `f2115e986` (unfixed, exit 0/0), `ce717e069` (simulated fix, Preflight 4 / Jog lint 0), `9ba644fe2` (comment-only, 0/0). The rows for the existing-suite runs keep the simulated-fix commit they actually ran on; the clones that held those commits are deleted, and the patches that recreate them are retained in each `probe-proof/2-simulated-fix/`. Fix is in commit `4b9a2dcd8`.

No runtime replay was needed and none changed. No product fix was implemented. Handing off to Reviewer for round 4 (last permitted round).

### Reviewer · Round 4

swept file: no

F5 is closed; preparation QA passes. Read both complete captures, both complete readiness scripts, both summaries and provenance files, the retained state/consumer receipts, falsifier outputs, simulated patches, diff receipt, and relevant runtime decision paths. No additional pre-existing defect was found in the fully read capture/probe files. The large runtime modules and unrelated ledger history were not swept. No Git command, executable fixture, suite, Preflight or phase gate ran; no phase gate is configured. Runtime results are inspected Producer receipts, not independent CLI replays. This approval covers the preparation packets, not implementation, publication, merge readiness or Day 2 admission.

Graph: Verify intent; all 87 project entries checked, this worktree is unindexed. Nearest project `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation `2026-11-25T18:19:12Z`. Symbol search returned the four relevant decision functions with no remaining pagination. Coverage checked the preparation evidence paths and cited runtime/suite paths; preparation content is missing from that other checkout, and gh257/gh549 have partial shell ranges. Local source supplied the evidence, including those ranges. No graph completeness or current-worktree freshness is inferred.

- **[Pass] F5 CLOSED.** Both `TESTS-RESULTS/2026-11-25+GH-977/provenance.jsonl:1-6` and `TESTS-RESULTS/2026-11-25+GH-1315/provenance.jsonl:1-6` now attribute their Preflight and paired Jog outputs to `f2115e986`, `ce717e069`, `9ba644fe2`, with notes that these refreshed runs supersede earlier runs. These match the full `freshness.evaluated_ref_commit` values in each retained JSON and the sibling `state.txt:1`. Both `SUMMARY.md:4` distinguish recording time from run time. The read-only check below exits **0**, with `mismatches= 0`; all six states have the expected probe verdict and recorded exit codes. An initial version of my checker exited 1 because it parsed the literal `preflight_exit=0` as an integer; correcting the checker to parse the value after `=` required no artifact change.

- **[Pass] F1/F2/F3/F4 remain CLOSED; Q1 discrimination.** #977 requires successful persisted replacement text, all five unchanged rating fields and successful explicit rescore (`TESTS-RESULTS/2026-11-25+GH-977/readiness_probe.py:73-83`). Its retained refusal/no-op falsifiers end `rc=1` at the intended assertions (`review-round1-fixes/probe-977-f1-refuse.txt:7-8`, `probe-977-f1-noop.txt:7-8`), while `probe-977-simfix.txt:1-2` records success. #1315 requires the ownership explanation plus actionable skill-specific remedy, matching preview/apply errors, no refusal side effects, and recorded-skill preview/apply (`TESTS-RESULTS/2026-11-25+GH-1315/readiness_probe.py:37-44,84-123`). The exact unrelated-error and partial-message falsifiers remain rejected (`review-round2-fixes/probe-1315-f2-reviewer-adoption-service-unavailable.txt:7-8` and sibling reason/remedy receipts); its `probe-1315-simfix.txt:1-2` records success. Independent extraction of only `explains_refusal` again yields `[False, False, False, True]` below. #977 connector isolation remains at `readiness_probe.py:30-35`, supported by retained `connector_events= 2 [977, 977]` before and `connector_events= 0 []` after (`review-round1-fixes/f3-temp-old_probe_977.py.txt:1`, `f3-2026-11-25+GH-977-readiness_probe.py.txt:1`). #1315's corrected ledger pointer remains at `provenance.jsonl:9`; a separate read-only path check found every provenance output present and every file output nonempty.

- **[Pass] Q2 / polarity.** Both contracts retain `expect_nonzero: true` (`PROJECT/1-INBOX/GH-977-ROADMAP-UPDATE-KEEPS-RATING.md:93-95`, `PROJECT/1-INBOX/GH-1315-LEGACY-PREVIEW-PARITY.md:81-83`). `utils/py/swarm_preflight.py:283-297` maps zero to landed and command failure to unfixed under that shape; launch exceptions become blocked. Ordinary uncaught probe crashes do not read landed. The retained three-state proof below distinguishes unfixed, simulated fix and comment-only edit for both packets; it is not a claim of immunity to every possible false positive.

- **[Pass] Q3 / existing gates and bounded artifacts.** The gates use existing suites only (captures #977 `:83`, #1315 `:73`), and #977 explicitly allows editing gh257 (`:87`), whose existing clearing assertion remains at `test/gh257-roadmap-ledger-fixes.sh:147-152`. The retained code-only red control fails there (`TESTS-RESULTS/2026-11-25+GH-977/existing-suites/gh257-codefix-only-RED-CONTROL.txt:36-37`); the adjusted simulated-fix receipts end `ALL PASSED` and `125 passed, 0 failed` / `exit=0` (`gh257-roadmap-ledger-fixes-simulated-fix.txt:43-44`, `gh549-work-events-simulated-fix.txt:162-163`). #1315 retains the pytest prerequisite warning at capture `:48`, consistent with `test/skills-army-hq.sh:10-15`; its non-skipped retained result is `34 passed, 4 subtests passed` / `exit=0` (`TESTS-RESULTS/2026-11-25+GH-1315/existing-suites/skills-army-hq-simulated-fix-python314-pytest.txt:46-47`). Round 1's bounded search for other rating-clearing pins stands; no exhaustive fresh search is claimed.

- **[Pass] Q4 / acceptance and ratings.** Both complete captures retain the issue-derived criteria and explicit choices at #977 `:31-44` and #1315 `:23-38`. The deviation syntax matches `utils/py/swarm_preflight.py:637-700`. Round 1's live issue/triage comparison is the retained external evidence; no fresh GitHub query was made this turn. The rationales at #977 `:68-73` and #1315 `:63` preserve neutral appeal, cheapness direction and stated recurrence limits. The #977 pickup row/receipt is shown in `TESTS-RESULTS/2026-11-25+GH-977/diff-evidence/releases.sql.diff:26,34`; #1315's existing rating remains in `releases.sql:990`.

- **[Pass] Q5/Q6 / history and preparation scope, bounded by the retained diff cutoff.** `releases.sql:1093,5835,5837,5839` retains #1315's pending/0 unleased row and parked/accepted-start/jog-pending history. Capture `:54-59` preserves the prior trial and explicitly warns that the pending row remains selectable (`utils/py/jog_run.py:2843-2848`); reuse/revalidation remains necessary at launch. The supplied SQL diff changes only generation metadata and adds #977's pickup row/receipt/parked event (`diff-evidence/releases.sql.diff:26,34,42`). Its stat lists preparation/evidence/relay/ledger files, with cutoff `a7b620924` declared in `diff-evidence/README.md:1`. Current source still contains the original defects (`utils/py/releases_app.py:4230-4233`, `skills/3-weekly/skills-army-hq/scripts/sync.py:281-285`); the fixes in patches are simulations. No current Git diff or absence of every external write is claimed. No new suite, product fix or additional subsystem is needed for this preparation review.

Exact read-only command executed (exit **0**; no fixture, subprocess or runtime entry point executed):

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 -B - <<'CHECK'
import ast,json,re
from pathlib import Path
mismatches=[]
for issue in (977,1315):
    root=Path(f'TESTS-RESULTS/2026-11-25+GH-{issue}')
    rows=[json.loads(s) for s in (root/'provenance.jsonl').read_text().splitlines()]
    for i in (0,2,4):
        p=root/rows[i]['output']; assert p.stat().st_size>0
        report=json.loads(p.read_text()); actual=report['freshness']['evaluated_ref_commit']
        assert actual in (p.parent/'state.txt').read_text()
        expected='landed' if i==2 else 'unfixed'
        assert [x['verdict'] for x in report['freshness']['probes']]==[expected]
        for row in rows[i:i+2]:
            out=root/row['output']; assert out.stat().st_size>0
            if row['source_sha']!=actual: mismatches.append((issue,row['output']))
            assert int(out.with_suffix('.rc').read_text().strip().split('=')[-1])==row['exit_code']
        assert 'JOG LINT OK' in (root/rows[i+1]['output']).read_text()
        print(issue,actual[:9],expected,rows[i]['exit_code'],rows[i+1]['exit_code'])
print('mismatches=',len(mismatches)); assert not mismatches
p=Path('TESTS-RESULTS/2026-11-25+GH-1315/readiness_probe.py')
f=next(n for n in ast.parse(p.read_text()).body if isinstance(n,ast.FunctionDef) and n.name=='explains_refusal')
ns={'re':re}; exec(compile(ast.Module(body=[f],type_ignores=[]),str(p),'exec'),ns)
messages=['adoption service unavailable','Not adopted: xyz has no recorded source; adopt it first','Cannot proceed; run intake.py update xyz --source /x','Not adopted: xyz has no recorded source; adopt it first (receipt-only: intake.py update xyz --source /x)']
results=[ns['explains_refusal'](s) for s in messages]
assert results==[False,False,False,True],results
print('F2 unrelated, reason-only, remedy-only, complete:',results)
CHECK
```

Decisive output:

```text
977 f2115e986 unfixed 0 0
977 ce717e069 landed 4 0
977 9ba644fe2 unfixed 0 0
1315 f2115e986 unfixed 0 0
1315 ce717e069 landed 4 0
1315 9ba644fe2 unfixed 0 0
mismatches= 0
F2 unrelated, reason-only, remedy-only, complete: [False, False, False, True]
```

VERDICT: PASS
Basis: F1-F5 are closed on cited source and retained evidence, with F5 independently checked against all six current Preflight reports and paired Jog receipts. No open finding remains within preparation QA. No later gate is assumed; publication checks and live integration-ref revalidation remain the owning workflow's work.

Relay closed (Approved), no further turn needed. Producer owns the subsequent preparation publication workflow; this review does not admit either issue to execution.


### Attestation · relay-drive — 2026-11-26T04:20:00Z
task: RELAY-gh977-gh1315-prep-qa-r4
reviewer: codex
status: Approved
reviewed-head: 140c26d102287522a2da4abe8c3c17ee628a9270
added-range: 54054+9576
added-sha256: 0feb2deac53fdff7d0bf7bdb19c4c156e8324fa6793e9607114d12adc3a4b9e5
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
