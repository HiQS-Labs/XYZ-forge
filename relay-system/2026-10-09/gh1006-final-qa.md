# RELAY · GH-1006 bounded observation final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-09.
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
6. **Commit only the relay file** (`relay(gh1006-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup

Operational envelope: macOS local developer harness; opt-in finite observation and active-agent repair-to-PR instructions. No autonomous recovery controller, no new suites/registry/gate machinery, no changes to coordination/containment/review semantics. Grade against this envelope and the approved plan, not speculative enterprise threat models.
Artifact: complete changed files `relay-automation/marathon.sh`, `utils/py/marathon_progress.py`, `relay-automation/README.md`, `skills/1-hourly/relay-xyz/SKILL.md`; whole plan `PROJECT/2-WORKING/GH-1006-BOUNDED-RECOVERY.md`; supporting CHANGELOG, ledger row, package and retained TESTS-RESULTS/2026-10-09+GH-1006. Diff base 7435a38cbcccbb7e3cb6fe11db809a7f6562a8c2, implementation checkpoint 9f7043f4.
Definition of Done: implementation and focused proofs meet every first-delivery acceptance item; whole-file sweep, no speculative controller/writer, coherent run attribution/signal/finite lifecycle, unanimous bounded repair guidance and honest held continuation. Rating remains 80/65/80/45 (qualitative preference interpretation, trend unknown).

Questions:
1. Are the validated opt-in settings, N=6/N=18 and missed-slot outcomes consistent with the plan? Does phase transition or terminal/window expiry introduce an extra check or executor?
2. Does the read-only observer attribute driver receipts and current heartbeat honestly, including whole-second timestamps, foreign/malformed data, optional acceptance and re-verification/duplicate milestones?
3. Does the opt-in serial background/wait preserve status and cancellation, with no promise of stopped descendants? Inspect the logger TERM red control and corrected real launcher latency controls.
4. Does the procedure preserve original deadlines/attempts and exclusions, require three affirmative advisory seats plus independent QA/gates, publish to development and hold unmerged continuation behind #752/#1004? Does it fulfill the refined issue's first-delivery boundary without closing held work?
5. Are retained 51 manual controls and existing 35/17/223 checks attributable and nonempty? No new test suite or gate is permitted; retained manual probe text is evidence, not registered test machinery. Any concrete missing acceptance proof must state failing input/scope/falsifier.
6. Review full changed files for material pre-existing defects; report bounded coverage limitations. Graph generation is stale, helper not indexed; use current source. No mutation-heavy test/suite/fixture may run in this review worktree. Retained producer results are not independent reruns.

Full gate sequencing: classifier says route=full,tier=3. Focused evidence is complete. Per start-task, the single final classified macOS full gate runs AFTER code approval, in a separate disposable full clone, through the pre-push hook. Approval of code is not gate evidence or PR readiness; publication remains blocked until that gate passes and clone identity is intact. Do not approve missing focused evidence, and do not require a second full gate before the final approved runtime revision exists.

Reviewer codex; Producer codex-author. Three-round binding cap. Write only this relay thread; no production edits or push.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: No material defect found in the new observation runtime within the declared local envelope. Two concrete pre-existing documentation defects remain in the required whole-file sweep: worker recipes cannot select their reviewer as written, and verification guidance directs mutation-heavy suites at the maintained harness. Correct those guidance surfaces and refresh the packaged README before approval. No new controller, gate, suite, or review semantics are requested.

swept file: yes

Coverage: read complete `relay-automation/marathon.sh` (444 lines), `utils/py/marathon_progress.py` (255), `relay-automation/README.md` (790), `skills/1-hourly/relay-xyz/SKILL.md` (739), and GH-1006 plan (285). Inspected the GH-1006 CHANGELOG entry, read-only roadmap row, package, retained probe sources/logs/provenance and current driver receipt/heartbeat/attestation seams. Graph tools were unavailable; no current generation/coverage check is claimed. Current source fallback was used. No git command, suite, executable fixture, driver invocation, or production mutation was performed.

- [Should] **R1 — Pass a nonempty reviewer in the worker recipes.** `skills/1-hourly/relay-xyz/SKILL.md:402` sets `CODEX_AGENT=codex` on the same command whose `--reviewer "$CODEX_AGENT"` argument is expanded at line 407. An unset variable supplies an empty reviewer. The agy and Commandcode examples repeat this at lines 424/429 and 446/451. The README's five headless drive recipes omit `--reviewer` entirely (`relay-automation/README.md:531`, `:559`, `:586`, `:650`, `:667`). The driver warns that no terminal status can be accepted without it (`utils/py/relay_drive.py:90-96`), assigns reviewer role only on an exact actor match (`:837`), and rejects other-role terminal writes (`:707-715`). Fix: use a literal matching reviewer ID, or assign/export it in a preceding statement; add the explicit flag to the README recipes and regenerate the existing package.
  Observed input: clean shell with `CODEX_AGENT` unset. Probe command `env -u CODEX_AGENT bash -c 'CODEX_AGENT=codex printf "reviewer_arg=<%s>\n" "$CODEX_AGENT"'` exited 0 and printed `reviewer_arg=<>`. README commands have no reviewer argument at all.
  Affected scope: these copy-paste headless review examples and their analogous worker-variable expansions; no runtime policy change.
  Falsifier: substitute a harmless argv printer for the driver in a clean shell; the corrected command must supply exactly `--reviewer codex` (or selected worker ID), regardless of absent/conflicting inherited worker variables. If the current recipes did that already, this finding would be unnecessary. A real relay run belongs in a disposable clone; none was run here.

- [Should] **R2 — Route verification instructions through a disposable full clone.** `skills/1-hourly/relay-xyz/SKILL.md:642-661` directs `bash "$HARNESS/validate.sh"` and worker suites at the located maintained harness. `relay-automation/README.md:474-486` similarly follows clone-or-refresh with direct suites; `:444` also recommends a direct agy suite. This contradicts the binding GH-564 isolation rail and the new repair procedure's correct full-clone requirement (`skills/1-hourly/relay-xyz/SKILL.md:88-90`). Fix: require a separate disposable full clone, use its CWD and script paths, and point to `WORKTREE-SAFETY.md` for the existing identity-bracket procedure. Unsandboxing alone is not clone isolation. No new machinery needed.
  Observed input: Preconditions selects a maintained canonical `$HARNESS` (`skills/1-hourly/relay-xyz/SKILL.md:159-199`); line 648 then literally runs `bash "$HARNESS/validate.sh"`. This targets the valued clone's suite. Not executed here; the GH-564 rail records the observed corruption behind this prohibition.
  Affected scope: verification guidance in these two touched docs, including direct worker-suite examples; normal harness execution remains distinct from test-clone paths.
  Falsifier: follow the revised verification guidance while `$HARNESS` still points at a maintained clone; every suite command and CWD must resolve to a separate full clone with independent `.git`, never a linked worktree or `$HARNESS`. Current instructions do not enforce that.

- [Pass] **Finite lifecycle and receipt attribution match the first-delivery plan.** Bounds/defaults/legacy refusal are at `relay-automation/marathon.sh:130-157`; one observer is created outside the phase loop (`:299-315`), and exact-child waits preserve serial dispatch (`:377-391`). `utils/py/marathon_progress.py:155-193` consumes missed slots without resetting deadlines or exceeding N. Terminal reporting is separate from numbered checks (`:247-251`), including after window expiry. Receipt identity binds execution/phase/lane/product root/token family (`:73-89`); qualification and optional acceptance are at `:92-101`; already-satisfied, initial and duplicate candidates cannot create new milestones (`:233-245`). Current driver receipts supply the validated candidate (`utils/py/marathon_drive.py:2698-2735`). Whole-second heartbeat handling is liveness-only (`utils/py/marathon_progress.py:104-124`). No runtime fix requested.

- [Pass] **Retained signal controls support bounded cancellation without proving descendant stop.** `TESTS-RESULTS/2026-10-09+GH-1006/manual/probe-source.txt` times launcher INT/TERM, group TERM and owner disappearance until the observed reader is gone. `manual/checks.json` records 0.204s/130, 0.199s/143, 0.079s/143, and 0.185s/-9 respectively. `manual/signal-ledger.json` and `manual/minimal-signal-source.txt` isolate logger red exit -13 versus protected-reader green exit 143. The fix is the opt-in logger signal disposition (`relay-automation/marathon.sh:264-266`); direct-child forwarding and interruption status are at `:281-297`. These are inspected producer measurements, not independent signal reruns. No runtime fix requested.

- [Pass] **Repair scope and held continuation are honest.** `skills/1-hourly/relay-xyz/SKILL.md:69-104` preserves one episode, at most one continuation, the absolute deadline, attempts, three affirmative advisory seats, exclusions, isolated repair, independent plan/final QA, exact-revision gate and publication to development. Unmerged continuation stays held behind #752/#1004 plus ownership/revision/state/budget proof. The plan's Conditional continuation section keeps #1006 open beyond this delivery; `CHANGELOG.md:3-15` agrees. The read-only ledger row retains the correct working-doc pointer and ratings 80/65/80/45 with no override. No scope expansion requested.

- [Pass] **Retained evidence is nonempty and attributable; package matches.** Manual provenance pins current helper `f93ebdf697f777f8e1a66fb45f53fa1e7ab0704b0a1e6491424c30f6ee47233a` and launcher `ede11ad8c3b9d1d18fbff493bf7695e557a7950009242e0bae249b7027c1e104`. `focused/provenance.jsonl` and its nonempty logs retain 35/35, 17/17, 223/223, package 3/3 and frozen-guard success. Manual JSON contains 38+13 passing controls. Independent read-only integrity query below exited 0, printing `checks.json 38 passed`, `supplement-checks.json 13 passed`, `5 focused logs nonempty, hashes match, recorded exit 0; helper/launcher hashes match`, `identity bracket byte-equal`, `package 18 files match current source`. This checks retained evidence, not live product behavior. No new suite requested.

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
from pathlib import Path
import hashlib,json,tarfile
p=Path('TESTS-RESULTS/2026-10-09+GH-1006')
r=[json.loads(x) for x in (p/'manual/provenance.jsonl').read_text().splitlines()][0]
for source,key in [('utils/py/marathon_progress.py','source_sha256'),('relay-automation/marathon.sh','launcher_sha256')]:
 assert hashlib.sha256(Path(source).read_bytes()).hexdigest()==r[key]
for name in ['checks.json','supplement-checks.json']:
 rows=json.loads((p/'manual'/name).read_text());assert rows and all(r['passed'] for r in rows);print(name,len(rows),'passed')
for line in (p/'focused/provenance.jsonl').read_text().splitlines():
 row=json.loads(line);raw=(p/'focused'/row['log']).read_bytes();assert raw and row['exit_code']==0 and hashlib.sha256(raw).hexdigest()==row['sha256']
print('5 focused logs nonempty, hashes match, recorded exit 0; helper/launcher hashes match')
assert (p/'manual/identity-before.json').read_bytes()==(p/'manual/identity-after.json').read_bytes()
print('identity bracket byte-equal')
with tarfile.open('skills/1-hourly/relay-automation/relay-pkg.tar.gz') as tar:
 members=[m for m in tar.getmembers() if m.isfile()];assert members
 assert all(tar.extractfile(m).read()==Path(m.name).read_bytes() for m in members)
 print('package',len(members),'files match current source')
PY
```

- [Unverified — needs clone run] The final classified macOS full gate remains owed **after** code approval, per this thread's sequencing. No independent suite or launcher-signal rerun occurred here. No additional pre-approval full gate is requested; publication/readiness remains blocked until the final gate passes with intact clone identity.

Whole-file sweep found the two pre-existing guidance defects above; no additional material pre-existing runtime defect was found in this bounded review. This is not a repository-wide audit or verification of every external CLI/provider claim in the reference docs.

Handing off to Producer (codex-author) — correct R1/R2, refresh the package, log dispositions, and return for round 2. Only this relay file was changed.

### Producer · Round 2 · codex-author

R1 — Implemented. All three skill recipes now pass literal matching reviewer IDs; all five README headless recipes specify the matching reviewer. Harmless argv substitution of the eight actual blocks passes with absent and conflicting inherited actors (16 probes); the old inline expansion fails the corrected expectation. Evidence: TESTS-RESULTS/2026-10-09+GH-1006/recipe-fix/.
R2 — Implemented. Both documents route suite commands to a separately cloned full checkout, check the source is a full clone, guard the temporary directory/clone/cd, scrub inherited maintained-root overrides, and cite the identity bracket. A vendored non-Git install must select the maintained full harness clone as source. Normal execution returns to the maintained harness; the tests do not. Package regenerated and byte freshness passes 3/3.

Integration advanced to ecec5561 (GH-1005 docs/ledger). Merged that base in 54670b52 with the repo-native ledger resolver; original GH-1006 admission, ratings and both tasks' histories retained. No new row values were invented. Retained readback and check report 0 failures. The observer and launcher hashes are unchanged from the 51 controls inspected in round 1. Resulting artifact commit 09e3d2af, current diff base ecec5561.

Re-review the actual committed documentation changes, eight recipes, package and composed integration state; sweep whole touched files under the same envelope. Full classified gate remains owed after this code approval. No new suites/registry/gates or runtime change. Review round 2 of the binding three-round cap.

Handing off to Reviewer codex for final code approval of the composed artifact.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
