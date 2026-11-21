# RELAY · GH-1169 final QA: express vendored-host mode
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-19.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1169-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/express.py` and the rest of the committed implementation on this branch versus
  development at 7eeae804 (git diff 7eeae804..HEAD): `skills/2-daily/express/SKILL.md`, the evidence in
  `TESTS-RESULTS/2026-10-19+GH-1169/README.md` (logs, fixture and runner scripts, provenance), and the plan and Evidence
  table in `PROJECT/2-WORKING/GH-1169-EXPRESS-VENDORED-HOST.md`. Approved plan QA: `relay-system/2026-10-19/gh1169-plan-qa.md`.
- Operational envelope: a local developer CLI lane driven by one operator. Grade against the approved plan's changes
  1–6 and acceptance with commensurate complexity; no new suites or gate machinery (GH-831). The full gate runs once on
  the final approved commit, after this review.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-19
- Definition of Done: each acceptance item is met by the committed code and substantiated by the evidence; canonical
  (non-vendored) express is byte-identical in behaviour and recovery text; the host docs gate can fail and a red gate
  publishes nothing; code hotfixes without a registry refuse cleanly; no new suite.

### Questions for the Reviewer
1. Is every vendored-only branch gated on `VENDORED` (set once in `main()` from express's own file) so canonical Forge
   runs are unchanged? Any canonical path whose output or behaviour changed (beyond the missing-`validate.sh` refusal,
   which the plan applies to any repo)?
2. Docs lane: `HOST_DOCS_SUITE` spelling, `suite_file`/`suite_argv`, `PDDA_MODE=full` env on the run, receipt command,
   resume matching. Is the `--docs-only` binding airtight (no bypass by spelling or flag combination)?
3. Gate wiring: host hook via `git rev-parse --git-path hooks/pre-push`; "none" path only when vendored and no
   `githooks/install.sh`. Sound?
4. Tool resolution: `harness_tool` anchored on express's own file; `releases_app` and `reconcile_gated` only. Correct,
   and does it leave wave_reconcile's own repo-first contract untouched?
5. Evidence: do the logs support S1–S8 and both smokes? Are the fixture's shortcuts (local bare at a github.com-shaped
   path, gh stub, temp HOME) acceptable for what each scenario claims?
6. Diff hygiene and anything over- or under-engineered. Cite `file:line`.

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
Basis: The vendored runtime branches and recorded landing/red-gate scenarios support the core implementation, but the host recovery instruction loses repository identity and the canonical comparison stops before the changed paths. Fix the recovery instruction and complete the promised parity evidence before approval.
swept file: yes

Reviewed all 1,423 lines of `utils/py/express.py`, the entire express skill, approved plan and plan-QA transcript, and the evidence README, fixture, runner, provenance and logs; rechecked `harness_paths.py` and the reconciler's existing repo-first tool contract. No additional material pre-existing defect was found beyond the recovery/documentation interaction below. Evidence tier: Verify using current source fallback. No graph tools are callable in this session, so project/generation and coverage could not be queried; no graph completeness claim is made. No git commands, suites, pytest or executable fixtures were run. Only this relay file was edited.

- **[Should] F1 — Preserve the host repository in the vendored recovery command.** `skills/2-daily/express/SKILL.md:149-152` explicitly supplies a host `resume` command without `--repo`, although the normal host invocation requires it at `:65-66`. With `EXPRESS_REPO` unset, `express.args_repo()` returns `HiQS-Labs/XYZ-forge` (`utils/py/express.py:871-872`), so identity qualification rejects the documented host recovery before accepting its receipt (`:1233`, `:1263`). Add `--repo "$REPO"` (define it as the landing's host slug) to the vendored variant; keep canonical recovery unchanged. S8 currently passes an extra `--repo $SLUG` absent from the documented command (`run-all.sh.txt:26`), masking this gap. Re-record the recovery using the actual documented variant. Also accurately describe the S8 helper: `host-fixture.sh.txt:51-59` omits the canonical recipe's before/after identity snapshots, so it establishes gate rc/receipt/resume handling, not execution of the entire recovery recipe.
  Observed input: documented `resume --issue 9001 --docs-only --sha <sha> --base main`, host `HiQS-Labs/XYZ-layout-engine`, no `EXPRESS_REPO`. Import-only probes below print the default Forge slug and produce `resume-identity`, exit 3, against mocked host metadata; no subprocess or git executes.
  Affected scope: the newly documented vendored recovery variant and the evidence describing its execution; no change to repository-identity enforcement is requested.
  Falsifier: in a disposable host clone with `EXPRESS_REPO` unset, the exact amended recipe accepts a committed successful host receipt and resumes; a failed gate receipt still refuses before close/ship. The canonical recipe remains unchanged.

  Probe commands (both prefixed `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"`; each shell command exited **0**):
  ```python
  # python3 - <<'PY' ... PY  (parser-only; resolve_base is replaced before any git call)
  import sys, os
  from unittest.mock import patch
  sys.path.insert(0, 'utils/py'); import express
  class Capture(Exception): pass
  def resolve(root, repo, base):
      print('resume parser repo:', repo); raise Capture
  os.environ.pop('EXPRESS_REPO', None)
  argv=['express.py','--root','.','resume','--issue','9001','--docs-only','--sha','a'*40,'--base','main']
  with patch.object(sys,'argv',argv), patch.object(express,'resolve_base',side_effect=resolve), patch.object(express._harness_paths(),'is_vendored',return_value=True):
      try: express.main()
      except Capture: pass
  # decisive output: resume parser repo: HiQS-Labs/XYZ-forge
  ```
  ```python
  # python3 - <<'PY' ... PY  (identity-only; subprocess.run is replaced)
  import sys, os, subprocess
  from types import SimpleNamespace
  from unittest.mock import patch
  sys.path.insert(0,'utils/py'); import express
  os.environ.pop('EXPRESS_REPO',None)
  args=SimpleNamespace(root='.',repo=express.args_repo(),issue=9001,dry_run=True)
  result=subprocess.CompletedProcess([],0,'{"nameWithOwner":"HiQS-Labs/XYZ-layout-engine"}','')
  with patch.object(express.subprocess,'run',return_value=result):
      try: express.qualify_root_repository(args)
      except SystemExit as exc: print('documented host recovery identity refusal exit:',exc.code)
  # decisive output: express-refused: rule=resume-identity — requested repository differs from the landing root repository
  # documented host recovery identity refusal exit: 3
  ```

- **[Should] F2 — Complete the canonical happy-path comparison.** `smoke-forge-canonical.log.txt:1-5` compares only identical `too-many-commits` refusals (11 commits). That return occurs at `express.py:551-555`, before gate handling, suite admission and check output modified by this implementation. It does not substantiate the promised adjacent canonical smoke through those branches. In a disposable full clone with a qualifying small docs change and installed hook, compare old/new successful `check --docs-only --dry-run` output and exit status; retain the previously claimed canonical recovery-text comparison as reproducible command/output evidence too. Update the README/Evidence table to distinguish this successful comparison from the current early-refusal sample. No new suite or gate is needed.

- **[Pass] Lane binding and host gate are coherent in source and recorded evidence.** `express.py:1396-1404` fixes docs suite selection in `main`; `:655-670` admits the host registry exception only for `docs_only and VENDORED`; `:904-908` supplies the full-mode environment and refuses nonzero gate rc before commit/push. `host-checks.log.txt:17-24` records observe rc 0 versus full rc 1 and the non-preview express `suite-red` refusal with unchanged bare main, zero receipts and zero issue-close calls. `:29-32` records both non-docs refusals without traceback. These are reviewed producer-run results, not fresh executions this turn.

- **[Pass] Tool and hook scope match the approved intent.** `express.py:150-157` anchors vendored tool lookup to this driver's file; `:257` and `:1033` use it for the two intended subprocess tools. The direct anchored lookup is a small implementation variation from the plan's `resolve_tool(..., prefer_repo=False)` and preserves its intended ordering. The reconciler retains its own repo-first contract (`wave_reconcile.py:1834-1841`). Hook-or-none applies only when vendored and the installer is missing (`express.py:414-430`). S2/S4/S7 record successful landing, unused root reconciler decoy and vendored releases-tool selection (`host-checks.log.txt:10-16,26-28,35-37`).

- **[Pass] Evidence integrity is internally consistent.** Import-only SHA256/length verification of all ten entries in `TESTS-RESULTS/2026-10-19+GH-1169/provenance.jsonl` against their nonempty local artifacts exited **0** and printed `provenance: all 10 nonempty artifacts match recorded bytes and SHA256`. The covering-suite logs report gh267 113/0, gh358 8/0, gh425 OK and gh429 15/0. The local bare origin, gh stub and temporary HOME are appropriate for local landing/gate/receipt measurements; they do not establish real GitHub closure behavior. The real-host check smoke is separately recorded in `smoke-host-xyz-layout-engine.log.txt:1-8`.

[Unverified — needs clone run] No runtime checks were executed by this reviewer. The final committed-state harness gate remains outstanding by design; F1 recovery replay and F2 canonical parity must run in disposable full clones. A full gate alone will not replace those specific missing observations.

Handing off to Producer (claude-a) — address F1 and F2, update the evidence, then open Round 2; go to the Producer window and say 'take your turn'.

### Producer · Round 1 (claude-a)

- F1 [Should] — **Implemented.** `skills/2-daily/express/SKILL.md` vendored recovery now sets `REPO=<owner>/<name>` and resumes with `--repo "$REPO"` (`f66e3a3c`). The fixture helper `host-fixture.sh.txt` `vendored_recipe` now follows the documented recipe exactly: canonical steps 1–7 including the before/after identity snapshots and VOID check, the four vendored substitutions, and the documented `resume` as step 7 (no extra argument added by the runner). Re-recorded at `dc33ddfd`: broken landing recipe rc 1 → resume rc 4 (no valid receipt); clean recipe rc 0 → resume rc 0, issue closed, reconciled.
- F2 [Should] — **Implemented, and it found a real canonical change.** New `canonical-compare.sh.txt`: fresh GitHub clone of XYZ Forge at `7eeae804`, gate installed, one-line README change, open #1169, `check --docs-only --dry-run` with the `origin/development` driver vs this branch's driver. The first run differed: the branch printed an extra `gate    : canonical pre-push stub` line in canonical output. Fixed in `dc33ddfd` (the gate line prints only when vendored); rerun → both rc 0 PASS, byte-identical. The same script records the canonical recovery-text comparison (byte-identical). `smoke-forge-canonical.log.txt` (early-refusal sample) removed; README distinguishes the successful comparison.
- All suites (gh267 113/0, gh358 8/0, gh425 OK, gh429 15/0) and host scenarios S1–S8 re-run at `dc33ddfd`; provenance regenerated (11 records).

Handing off to Reviewer (codex) for round 2.

### Reviewer · Round 2

VERDICT: PASS
Basis: F1 and F2 are resolved: the documented host recovery retains repository identity and has red/green replay evidence; canonical parity now reaches a successful check and records unchanged recovery text. The implementation and retained evidence satisfy the approved plan within the local single-operator envelope. The final committed-state harness gate remains outstanding by design.
swept file: yes

Re-read the whole current express driver, express skill, plan/Evidence table and verification README; inspected the fixture, runner, canonical comparison, provenance, scenario/smoke logs and covering-suite results. Rechecked the resolver contract and prior plan-QA dispositions. No additional material pre-existing defect was found. Evidence tier: Verify, current direct-source fallback. Graph project inventory was fully paginated (84 entries); this worktree is not indexed. Nearest canonical project XYZ-forge is ready but coverage generation is 2026-09-01T15:54:30Z and reviewed paths have changed or unavailable metadata, so that graph does not establish current branch coverage. No git command, suite, pytest or executable fixture was run. Only this relay file was edited.

- **[Pass] F1 resolved.** `skills/2-daily/express/SKILL.md:149-153` now defines the host slug and includes `--repo "$REPO"` in the vendored resume command. `TESTS-RESULTS/2026-10-19+GH-1169/host-fixture.sh.txt:51-68` replays the documented substitutions with clean-baseline checks, before/after identity snapshots, VOID comparison and the actual resume command. `host-checks.log.txt:38-46` records gate rc 1 → resume rc 4 (no valid committed receipt), and gate rc 0 → resume rc 0 with receipt attribution and issue closure. This closes the original command/evidence mismatch.

- **[Pass] F2 resolved.** `TESTS-RESULTS/2026-10-19+GH-1169/canonical-compare.log.txt:1-21` identifies base 7eeae804, the installed hook and candidate driver dc33ddfd; both successful checks return 0 with byte-identical output, followed by identical canonical docs/runtime recovery text. The retained comparison script shows the old/new commands and comparison. `utils/py/express.py:686-687` limits the added gate line to VENDORED, addressing the real canonical output difference discovered by this comparison. These are producer-run disposable-clone observations, not fresh runtime executions by this reviewer.

- **[Pass] Remaining acceptance stays supported.** `express.py:655-670` binds the registry exception to docs-only plus VENDORED and guards absent registries; `:904-908` applies full-mode PDDA and refuses a red suite before publication; `:1396-1404` fixes lane selection. `TESTS-RESULTS/2026-10-19+GH-1169/host-checks.log.txt:9-37` records landing/receipt/base identity, the red express boundary with unchanged remote and no receipt/closure, unused reconciler decoy, both non-docs refusals and releases-tool selection. `smoke-host-xyz-layout-engine.log.txt:1-8` separately records the real-host check smoke at the explicitly disclosed earlier revision 944c43c9. Host-hook and anchored tool scope remain as reviewed in Round 1 (`express.py:150-157,414-430,1033`). The local bare origin, gh stub and temporary HOME support these local integration claims; they do not prove real GitHub closure behavior.

- **[Pass] Evidence integrity and existing-suite results.** Narrow read-only command `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY' … PY` parsed every provenance row, required exactly 11 rows, read each named artifact, asserted nonempty bytes, recorded length and SHA256 equality, and printed each suite log's final three lines. Exit **0**; decisive output: `provenance: all 11 nonempty artifacts match recorded bytes and SHA256`, `gh267-express-skill: pass=113 fail=0`, `gh358: 8 passed, 0 failed`, gh425 `Ran 23 tests … OK`, and `gh429-wave-reconcile-vendored-observe: 15 passed, 0 failed`. Citations: `TESTS-RESULTS/2026-10-19+GH-1169/provenance.jsonl:1-11` and the corresponding named suite logs. No new suite or gate machinery is introduced by the reviewed implementation/evidence.

[Unverified — needs clone run] The final committed-state harness gate has not run in this reviewer turn and must run after this approval, as Setup specifies. This approval closes artifact QA; it does not attest that later gate or authorize promotion.

Relay closed (Approved), no further turn needed. Producer (claude-a) receives the completed review; the harness owns the relay-file commit and final gate.


### Attestation · relay-drive — 2026-10-19T15:57:15Z
task: RELAY-gh1169-final-qa
reviewer: codex
status: Approved
reviewed-head: bbcbaf00a3126f5c4cc4f511e60ed047a119abbc
added-range: 16531+4558
added-sha256: 33b0e0767b1246a34a0a7138a8a4bd413916a2143dcbb3190a2a483a67042adc
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
