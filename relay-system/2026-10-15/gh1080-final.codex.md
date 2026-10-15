# RELAY · GH1080 express docs admission final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-15.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 3

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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
