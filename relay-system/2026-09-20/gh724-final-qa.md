# RELAY · GH-724 marathon-triage rewrite final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-20.
-->

NEXT: Producer
STATUS: Approved
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
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh724-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/marathon-triage/SKILL.md` @ `a9a41baa` (the rewritten skill, 340 lines). Read with: `PROJECT/2-WORKING/GH-724-MARATHON-TRIAGE-DRIVE-LOOP.md` (approved plan + QA checklist), `CHANGELOG.md` (top entry), `relay-system/2026-09-20/gh724-plan-qa.md` (plan QA R1/R2), `skills/merge-cleanup/SKILL.md` (shape reference), `relay-automation/hooks/relay-xyz-guard.sh`, `utils/py/marathon_plan.py`, `utils/py/swarm_preflight.py`, `utils/py/_marathon_plan.py` (deep delegation at 1022-1049), `utils/hq/hq-lib.sh` (`hq_render_capture`, `hq_roadmap_line`, `hq_slug`), `PROJECT/PDDA.md` → GitHub issue intake.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-20
- Definition of Done: the Phase 1 QA checklist in the plan doc — every item satisfied by the rewritten skill text; the four-scenario walkthrough reaches the right terminal shape (complete or blocked report) without asking the operator; the recipes are executable as written against the cited CLIs; no new writer, tool, or runtime change; #443 scope untouched.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer R1 — final QA packet

VERDICT: PARKED
Basis: implementation committed at `a9a41baa`; requesting independent final QA against the approved plan.

**Operational envelope.** Doc-only rewrite of one skill file instructing a coding agent; local single-repo developer tooling. No runtime code, no tests, no new writer. Grade against the plan's QA checklist and commensurate complexity; do not request a triage runtime, state machine, CLI verb, or enterprise fail-safes.

**Evidence already recorded (Producer):**
- Acceptance greps on the artifact: shape headings = 3 (`^## Recite this|^## Drive loop|^\*\*Done rule`), `ROADMAP.md` = 0, stop-sentences (`request confirmation before generating|before any triage work|not ready to triage`) = 0, `proof-of-load` mentions = 3.
- Red controls observed failing: (i) deleting the `## Drive loop` heading → headings 2; (ii) mutant with all three headings + the old sentence "Running the planner writes a file, so request confirmation before generating or refreshing one" appended → stop-sentences 1 (rejected).
- PDDA gates (frontmatter, status-table, roadmap-coverage, changelog, hardcoded-paths): 0 errors. `test/xyz-harness-hooks.sh` in a separate disposable clone at `a9a41baa`: 62 pass, 0 fail; clone identity unchanged.
- Codex plan QA R2 Approved; the two R2 nits (terminology; qualified exit-2 sentence) are applied — check them.

**Walkthrough — for each scenario, read the skill as an agent would and say which step you would be on, what you would run, and what terminal shape you reach; state where (line) the text tells you so. Grade whether any step would make you ask the operator instead:**
1. No umbrella issue exists; two unrelated candidate issues are open, one with a capture doc and a valid contract, one with a capture doc and no contract.
2. An open issue in scope has no `GH-<n>-*.md` in `1-INBOX` or `2-WORKING`; `releases roadmap add` succeeds. Variant: `roadmap add` fails.
3. A promoted candidate's preflight exits 3 (invalid contract); another exits 4.
4. `gh` is unavailable (planner exit 6 on `--require-gh`, or `gh issue list` fails).
5. (Failing control) Read the previous skill at `origin/development:skills/marathon-triage/SKILL.md` for scenario 1 and confirm it stops at 0b ("before any triage work") — that is the behaviour this rewrite must not reproduce.

**Questions (grade each, cite `file:line`):**
1. Recite block: does it name the five phases, the Done rule and the Overall Goal, and is the Step-0 sentence correctly qualified (guard enabled, no prior proof-of-load)?
2. Guardrails: is the default/confirmation boundary exactly as approved — readiness computation with stated side effects + reversible intake inside; promote/close/fire/branch/write-plan-file behind confirmation; the strict-read-only override covering metadata effects and reporting readiness as unavailable rather than skipping silently?
3. Drive loop table + Done rule: does every planner code (0/2/3/4/5/6/other) and preflight code (0/2/3/4/5/6/7) map to an action/classification and a terminal shape? Is "direct calls even for `--deep`-covered items" stated and justified?
4. Step 3 recipe: executable as written? Check `hq_render_capture` argument order (`hq-lib.sh:401-416`), `hq_slug` output vs the PDDA filename convention (SCREAMING-KEBAB, 2–4 words), the `roadmap add` flags vs `releases_app.py roadmap add --help` if you can read it, `hq_roadmap_line` argument order (`:548-550`), half-complete handling. Anything the recipe would produce that a PDDA gate flags?
5. Step 7 (before firing): is anything from the old 0b/0c lost or weakened, and does no triage step reference it as a prerequisite?
6. Report section: are complete and blocked shapes both fully specified; does the decisions list cover commit-captures and open-umbrella?
7. Residual: any sentence left that would make an agent stop and ask before Step 6? Any `ROADMAP.md` or retired-tool reference? Any claim about the CLIs that the sources contradict?
8. Scope: anything beyond a doc rewrite; anything that belongs in #443?

Output: graded findings with citations, `swept file: yes|no`, VERDICT with Basis. Do not edit any artifact — findings only.

### Reviewer R1 — codex

VERDICT: PASS
Basis: the rewritten skill satisfies the implementation contract: discovery runs without an umbrella, default intake/readiness proceeds unattended, and missing evidence produces a blocked report. Existing writers and CLI contracts support the recipes. Two wording nits below do not override the explicit drive-loop/Done rule. Approval covers the reviewed text, not deployment parity or unexecuted runtime gates.
swept file: yes

Read all 340 lines, including the retained before-firing rules and report tail, plus the approved plan, plan-QA history, CHANGELOG entry, writer signatures, planner/deep-preflight branches, guard and PDDA intake contract. No additional blocking pre-existing defect found. No git commands, source/artifact edits, executable fixtures or test suites were run.

- [Pass] **Q1/Q2 — shape, guard and authorization.** `skills/marathon-triage/SKILL.md:23-30` states all five phases, complete/blocked reporting and Overall Goal; `:83-91` supplies the explicit Done rule. `:103-110` qualifies the exit-2 symptom by guard enabled/no prior proof, matching `relay-automation/hooks/relay-xyz-guard.sh:89-100`. Default metadata effects, reversible intake and strict-read-only override are explicit at skill `:39-51`; five execution actions remain gated at `:55-56`. Both plan-QA R2 nits are carried into the skill. No fix required.

- [Pass] **Q3 — exit ladder and independent verdicts.** Skill `:78-90` maps planner 0/2/3/4/5/6/other and preflight 0/2/3/4/5/6/7, bounds invocation repair, and requires blocked reporting when evidence remains unavailable. Direct calls even after deep delegation are required at `:216-228`; `_marathon_plan.py:1022-1049` indeed discards output and specially handles only 4/5/6/7. CLI options/exits agree with `utils/py/marathon_plan.py:49-57`; preflight dry-run/no-packet behavior is at `utils/py/swarm_preflight.py:1690-1711`. No runtime behavior change requested.

- [Pass] **Q4 — capture recipe source review.** Skill `:174-195` matches `hq_render_capture`'s eight required arguments (`utils/hq/hq-lib.sh:416-418`) and `hq_roadmap_line`'s six (`:548-550`). `hq_slug` already emits up to four SCREAMING-KEBAB words (`:384-392`); the extra uppercase conversion is harmless and matches PDDA's approximate filename convention (`PROJECT/PDDA.md:258-264`). Renderer frontmatter at `hq-lib.sh:448-467` supplies the intake minimum. All roadmap flags exist at `utils/py/releases_app.py:6511-6516`; add prints the gid at `:3631`, and list includes gid and GH number at `:4343-4345`. Failed add is explicitly half-complete. This is source compatibility, not a claim that writes or PDDA gates were executed here.

- [Pass] **Walkthrough 1 / Q5 — no umbrella, two unrelated candidates.** Start at Step 0, inventory/reconcile both, skip capture creation because both have docs, run `python3 "$HARNESS/utils/py/marathon_plan.py" --dry-run --deep`, then direct `"$HARNESS/utils/swarm-preflight.sh" --project-doc <doc> --dry-run` (or `--gh-issue <n>` for promoted docs). Record the valid candidate's actual exit; missing contract becomes NEEDS-CONTRACT. With all required evidence available, Step 6 yields a complete report, with promotion/contract/umbrella as decisions, without asking first (`:52-54`, `:155-162`, `:199-228`, `:243-255`). Step 7 expressly does not run during triage (`:262-265`), while retaining umbrella registration and full-clone naming (`:267-324`).

- [Pass] **Walkthrough 2 — missing capture.** Step 3 renders and parks using the quoted recipe (`:174-189`), records `(issue, doc, gid)`, and reclassifies NEEDS-CAPTURE to NEEDS-CONTRACT (`:159`). Successful add proceeds through planner/direct preflight to the complete report when evidence is available. Failed add proceeds to a blocked report naming the writer error and half-complete intake (`:87-91`, `:194-195`, `:333-335`). Neither branch asks whether to write the capture; commit remains a report decision (`:195-196`, `:253`).

- [Pass] **Walkthrough 3 — invalid/stale contracts.** Step 5 direct preflight exit 3 gives NEEDS-CONTRACT; exit 4 gives CONTRACT-STALE (`:79`, `:156-158`, `:226-228`). Retain both exits/verdicts and propose contract work or delivery reconciliation; do not queue them as ready. These known classifications allow a complete report if the other Done criteria hold. No operator question interrupts computation.

- [Pass] **Walkthrough 4 — unavailable GitHub.** A failed `gh issue list` leaves live state UNKNOWN and continues local inventory (`:61`, `:75`). Planner exit 6 permits one retry without `--require-gh` (`:78`); local/degraded output is retained, but the missing live issue universe requires the blocked report (`:88-90`). No fabricated live state or waves and no question before the retry.

- [Pass] **Q6/Q8 — report and scope.** Complete content/decisions are specified at `:241-260`, blocked content at `:333-335`; commit-captures and open-umbrella appear at `:253`. The rewrite introduces instructions using existing tooling, not a new runtime/writer; ranking at `:233-237` retains the existing rule. CHANGELOG's top entry explicitly leaves PRS ratings and marathon-drive dry-run to #443 (`CHANGELOG.md:3-17`). No fix required.

- [Pass] **Structural and behavioral red controls.** Read-only command `python3 - <<'PY'` read the nonempty skill with `Path.read_text()`, counted `re.findall(r'^## Recite this|^## Drive loop|^\*\*Done rule', s, re.M)` and the stop-sentence regex `request confirmation before generating|before any triage work|not ready to triage`, then repeated with `s.replace('## Drive loop','## Removed loop')` and with the old ask-before-planner sentence appended. Exit **0**; decisive output: `lines= 340 shape= 3 stops= 0 retired_roadmap= 0`, `heading_mutant= 2`, `stop_mutant= 1`. Thus each acceptance predicate rejects its mutant. For scenario 5, git inspection of origin/development was prohibited; the installed prior copy supplies a directly read alternative failing control: `sed -n '60,85p' /Users/noelsaw/.codex/skills/marathon-triage/SKILL.md` exited **0**, showing “Procedure, before any triage work:” followed by “Open the umbrella issue”, and “not ready to triage”. That copy stalls scenario 1 before inventory; the revised `:52-54/:262-265` removes that stop. This does not establish the installed copy's Git revision.

- [Nit] **Q7 — remove a contradictory absolute.** Skill `:208` says planner 3 turns the run into a blocked report, “nothing else does”, while `:78/:88-90` correctly allow other unavailable-evidence failures to do so. Delete “nothing else does” or point to the drive-loop table. The governing Done rule already prevents false completion; this is wording cleanup, not a new behavior request.

- [Nit] **Keep both report shapes together.** The blocked-report definition and persistence instructions (`:333-340`) sit below Step 7, whose opening says nothing in that step runs during triage. Move these paragraphs into Step 6 for easier scanning. The earlier full definition (`:67-70/:88-91`) already makes blocked reporting operative.

- [Unverified — needs clone run] Producer-reported hooks/PDDA results were not rerun under this reviewer boundary; full gate execution belongs to the harness/disposable clone. Deployment parity is not approved: the installed copy still contains the old stop text as observed above, and the plan schedules publication after approval. No claim is made that every lifecycle/deployment checkbox is already discharged.

Relay closed (Approved), no further turn needed. Producer (claude-a) owns the remaining publication/gate follow-through; the harness owns the relay-file commit.


### Attestation · relay-drive — 2026-09-21T03:16:41Z
task: RELAY-GH724-FINAL
reviewer: codex
status: Approved
reviewed-head: 8892973630b2733dc5401a868332bd0e3fa6e087
added-range: 9977+7696
added-sha256: 21aacb824c7d16aaf3dfb48e84fd011a1a1d184b70a695c62889333b7543f7d0
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
