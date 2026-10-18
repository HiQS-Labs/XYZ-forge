# RELAY · GH1080 express docs admission final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-15.
-->

NEXT: —
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
6. **Commit only the relay file** (`relay(gh1080-express-docs-admission-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **utils/py/express.py**, its canonical express skill and SOP/ARCHITECTURE changes; read committed source directly.
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-15
- Definition of Done: bounded explicit docs admission with the real existing PDDA gate, accurate receipts/recovery, practical exclusions and unchanged hotfix requirements.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Bounded implementation review

User explicitly requests relaxing express for small documentation text and image updates, removing the critical-hotfix and runtime behavior-suite requirement for that lane. The pending README diagram must remain untouched. Review the diff from origin/development and read utils/py/express.py in full, skills/2-daily/express/SKILL.md, the small SOP/ARCHITECTURE changes, PROJECT/2-WORKING/GH-1080-EXPRESS-DOCS.md and its recon map, and TESTS-RESULTS/2026-10-15+GH-1080/ evidence. Do not edit those artifacts.

Operational envelope: local developer CLI, explicitly operator-authorized direct development landing only, existing driver and registered docs suite reused. No new tests, runners, schemas, dependencies, generalized policy scanners or enterprise security machinery. Semantic inspection of doc content remains an agent obligation; the path predicate does not prove arbitrary prose harmless. Scope is admission, truthful docs, exact verification and recovery, not unrelated historical express redesign.

1. Does --docs-only actually admit README+image without critical-hotfix/runtime coverage claims and select the existing registered real PDDA docs gate? Are code hotfix requirements retained?
2. Are practical mixed code/config, known policy roots, executable/symlink and code-to-text rename inputs excluded, with file bounds and meaningful text accounting preserved? Inspect the permission-fingerprint change and new-versus-tracked images.
3. Trace next consumer: do the exact docs suite/command and result produce a committed receipt that existing resume and gated reconciliation can match and finish? Is the scaffold truthful about what ran, including no runtime coverage claim?
4. Is this the smallest coherent extension? Identify concrete failing inputs if requesting more behavior, distinguishing existing defects from change-specific ones. Don't invent new checks or suites.

Evidence: existing express suite 113 pass at d741ae2a (before a one-line mode-fingerprint refinement); Codex prerequisite 43 pass, clone identity unchanged; final candidate manual controls 11 pass at 1984ef66, probe source retained in manual-docs.log. Normal full gate is still pending and will run against the reviewed final candidate before publication; don't claim it already passed.

Only this relay file is writable. No git commands, validate.sh, test/*.sh, pytest, fixture execution or external mutations. Read-only narrow source probes are allowed under the normal reviewer scratch rules. Append one graded reviewer block with swept file: yes/no, VERDICT: PASS|FAIL|PARKED and Basis; cite concrete file:line evidence. If Approved set STATUS: Approved and NEXT: —, then use the env-pinned absolute tick to done RELAY-GH1080-FINAL-20261015 --agent codex. Do not merely release on approval. Otherwise set NEXT: Producer and release to codex-producer. The harness commits the scoped relay result; never self-commit. Cumulative cap: 3 rounds.

### Reviewer · Round 1

swept file: yes
VERDICT: FAIL
Basis: The bounded docs extension reuses the existing landing and receipt machinery coherently, but docs eligibility skips the lane's exempt paperwork. Correct that narrow admission gap before approval. Read the entire 1,312-line express driver and canonical express skill, task/recon documents, relevant SOP/ARCHITECTURE text and retained evidence; no unrelated pre-existing defect identified in this bounded sweep. Graph tools were unavailable. No git command was executed, so an independent origin/development diff comparison remains unverified; source review covers the seeded current files.

- [Should] Apply docs-only eligibility to CHANGELOG and the issue capture document too, preserving their existing file/insertion exemptions. `utils/py/express.py:503` removes `is_doc_path` entries before `:506` validates eligibility; `:422` exempts CHANGELOG and the resolved capture doc. Thus the new executable/symlink checks never inspect these payloads, contrary to `skills/2-daily/express/SKILL.md:70`. This is an existing paperwork exemption interacting incorrectly with the new docs admission, not a request to redesign hotfix bounds.
  Observed input: Narrow in-memory source probe: `cmd_check` with `--docs-only`, changed paths `['CHANGELOG.md']`, and intercepted baseline `ls-tree` mode `100755`; ordinary branch/open-issue/wired-gate responses supplied without executing git, gh, a suite or fixtures. The checker admitted it although its own `is_documentation_update` rejected that identical input. Command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY' > .relay-scratch/admission-probe.log` (import seeded express.py; intercept git/gh/gate_check/change_paths using unittest.mock; invoke cmd_check and then the direct classifier). Probe exit: **0**. Decisive output: `express-check [dry-run]: PASS`, `files : 0 core, 0 insertions`, `documentation classifier calls: 0`, `direct classifier result: False`, `admitted paths: ['CHANGELOG.md']`. Initial attempt against the linked-worktree root correctly refused `not a git repo: .`; the successful probe used the pinned full-clone root for the directory check, with all command calls intercepted. No mode or source file was changed.
  Affected scope: Docs-only changes to CHANGELOG or the current issue capture path, including pre-existing executable/symlink modes or new executable/symlink shapes; actual driver ledger/projection outputs retain their existing handling. Inspect eligibility independently of size-exemption membership.
  Falsifier: In a disposable full clone, an ordinary text edit to non-executable regular CHANGELOG/capture files must still qualify with unchanged size exemptions, while executable/symlink variants must refuse `docs-only` before any docs write or landing. The exact executable CHANGELOG input above returning a refusal would falsify this finding. Use existing/manual verification, no new suite.

- [Pass] Suite selection and wording: `utils/py/express.py:1302` fixes docs mode to `test/pdda-repo-contract.sh` and refuses substitution; `:1306` retains the suite requirement for hotfix check/land/run/resume. `test/pdda-repo-contract.sh:11` executes the actual PDDA dispatcher; `validate.sh:557` registers it. `express.py:603` and `:605` distinguish doc hygiene from runtime coverage. New and tracked image paths share the insertion exemption at `:438`, while core file bounds remain at `:534`; source/destination rename enumeration uses `--no-renames` at `:364` and `:370`, and fingerprints include permissions at `:395`.
- [Pass] Consumer trace: landing uses the selected suite and real return code (`utils/py/express.py:801`, `:809`, `:813`); closeout writes its commit-bound receipt (`:893`), persists that specific receipt (`:912`), then invokes gated reconciliation (`:919`, `:940`). Exact command/success matching is in `:233`; resume requires committed evidence at `:1187`, and docs-mode default resolution applies to resume too (`:1284`, `:1302`). `wave_reconcile.py:723` consumes commit attribution. No receipt schema or parallel runner was added in this path.
- [Unverified — needs clone run] Retained evidence reports 113 existing express checks and 43 prerequisite checks at d741ae2a, plus 11 final manual checks at 1984ef66 (`TESTS-RESULTS/2026-10-15+GH-1080/provenance.jsonl:1`, `:2`, `:3`). The identity snapshots agree and log tails report those counts. These are retained producer runs, not checks rerun here. Full publication gate and end-to-end execution of the corrected candidate remain outstanding; the harness must run them in a disposable full clone. README and its pending diagram were not edited.

Handing off to Producer (codex-producer) — correct or disposition the admission finding, retain clone evidence, and return for Round 2. No self-commit; harness owns the relay-file commit.

### Producer · Round 2

Verified the finding against source and implemented it. Docs eligibility now checks all changed paths except the actual expected ledger/projection outputs (`utils/py/express.py`, df896f4f); CHANGELOG and the issue capture keep size exemptions but no eligibility exemption. No new suite or gate layer. Corrected Setup metadata placeholders to name the already-requested files; prior reviewer findings are unchanged.

Verification: `python3 temp/gh1080/manual-docs.py` in the disposable full clone -> 16 pass at df896f4f, retained in `TESTS-RESULTS/2026-10-15+GH-1080/manual-docs-r2.log` with probe source and provenance. Executable CHANGELOG and symlink capture refuse both ordinarily and with standalone-land expected-driver entries; regular paperwork still qualifies without adding to the three README text insertions. Other code/policy/rename/mode/receipt/default controls remain green. Full publication gate remains pending and will run before PR readiness.

Re-review the narrow paperwork correction and its falsifier, plus any consequence for existing generated ledger/projection handling. Original scope and 3-round cumulative cap remain. On approval, done the original token RELAY-GH1080-FINAL-20261015 --agent codex using the pinned tick; do not release instead. Only the relay file writable; no self-commit or fixtures. Handing off to Reviewer.

### Reviewer · Round 2

swept file: yes
VERDICT: PASS
Basis: Ship the bounded docs admission change through the pending harness gate. Round 1's paperwork eligibility finding is resolved without broadening generated-output exemptions. Re-read the full express driver and canonical skill, task/recon documents, relevant SOP/ARCHITECTURE changes, and retained Round 2 evidence. No blocking pre-existing defect identified in this bounded sweep; one optional stale-doc nit is below. This approves the source review, not an unrun publication gate or an end-to-end landing.

- [Pass] Paperwork correction: `utils/py/express.py:507` intersects expected outputs with `driver_projection_paths`, then `:508-513` checks every remaining changed path. CHANGELOG and the capture document therefore reach the same old/current-mode eligibility predicate (`:89-105`), even when standalone land includes them in `expect_driver_paths` (`:1015-1018`). Their size exemptions remain at `:422-424` and `:436`. The producer's retained falsifier evidence explicitly shows executable CHANGELOG and symlink capture refusals with and without expected-driver entries, then regular-paperwork acceptance with 2 core files / 3 insertions (`TESTS-RESULTS/2026-10-15+GH-1080/manual-docs-r2.log:9-13`). No further correction requested.
- [Pass] Generated ledger/projection handling stays narrow: `utils/py/express.py:412-415` enumerates the ledger pair and adopted projections; `:494-501` refuses unsolicited edits, and `:507` uses that existing enumeration rather than the broader paperwork allowlist. Ordinary docs still use the fixed registered verifier (`:1306-1309`, `validate.sh:557`, `test/pdda-repo-contract.sh:11`); hotfix commands still require a named suite (`express.py:1310-1311`). README/image file bounds, image insertion handling and permission-sensitive identity remain at `:538-545`, `:438-439`, and `:394`.
- [Pass] Receipt/recovery consumer remains coherent: the real suite status flows from `utils/py/express.py:813-817` to the receipt at `:897`; exact suite command/success matching remains at `:232-242`, receipt persistence precedes gated reconciliation at `:916-923`, and resume requires that committed receipt at `:1191-1193`. Docs scaffold language explicitly says "no runtime coverage claim" and "not runtime behavior" (`:607-610`). Canonical skill `:59-74` keeps semantic content/link/rendering checks an agent obligation.
- [Nit] Optional pre-existing prose cleanup: `skills/2-daily/express/SKILL.md:160` still names retired `ROADMAP-DASHBOARD.md` among refreshed outputs. Remove that filename at the next routine text cleanup; the actual output list is `utils/py/express.py:73-81`, and `ROUTER.md`'s RELEASES DB section records the dashboard retirement. This does not affect admission or block approval.
- [Unverified — needs clone run] Retained provenance reports 16 manual controls at df896f4f (`TESTS-RESULTS/2026-10-15+GH-1080/provenance.jsonl:4`; decisive log summary at `manual-docs-r2.log:18`), alongside earlier 113/43 regression/prerequisite results. These are inspected producer receipts, not independently rerun checks. No suite, fixture, pytest or git command ran here. Full final-candidate publication gate remains for the harness in a disposable full clone. An origin/development diff comparison was not independently performed under the no-git constraint. Graph project inventory was fully paginated (84 projects); neither this worktree nor the pinned task clone is indexed, so no matching generation/coverage evidence was available and exact seeded source was read instead.

Relay closed (Approved), no further reviewer turn needed. Producer/harness owns the pending clone gate and publication; no self-commit. Completing the original env-pinned token with `done`.


### Attestation · relay-drive — 2026-10-15T18:12:09Z
task: RELAY-GH1080-FINAL-20261015
reviewer: codex
status: Approved
reviewed-head: b8ce0544efb13e40de8a41d89157282bd0a56823
added-range: 14648+3780
added-sha256: 9b01419434821204014a5b82e6672fa4615e48db286240474aad5c3088ba9511
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
