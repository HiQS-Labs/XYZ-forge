# RELAY · GH1448 bounded research plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-12.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1448-bounded-research-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1448-EXPLORE-ADVISORY-CONTRACT-QUALITY.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1448-EXPLORE-ADVISORY-CONTRACT-QUALITY.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: producer
- Started: 2026-11-12
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Review packet

First read only PROJECT/2-WORKING/GH-1448-EXPLORE-ADVISORY-CONTRACT-QUALITY.md.
Before reading supplementary inputs/source, write 2–5 sentences each under **What this
proposes** and **How the existing system works, per this document**, plus **What it’s not**.
Record that input boundary. Distinguish current authorized plan from historical intake.
Then perform a separately labeled source-backed assessment using cases.json under
TESTS-RESULTS/2026-11-12+GH-1448, GH1447 SUMMARY/replay-results, utils/py/jog_run.py
lint_probe/extract_probes_from_doc/contract_probes_from_doc/promote_contract_to_working,
and utils/py/swarm_preflight.py extract_contract/eval_probes. No author conversation history.

Operational envelope: local repository research, at most eight cases/30 minutes evaluation,
no new runner/tests/gate/ledger and no runtime edits in this initial plan. User permits a
small implementation only after evidence and reviewed amendment; no merge/deploy/cleanup.
Commensurate complexity applies. Reviewer writes only this relay file; no suites or fixtures.

1. Does the plan distinguish admission, exit-status interpretation and semantic relevance?
2. Are fixed-output positives and legitimate specialized negatives predeclared, and does
   the analysis report false positives/negatives instead of tuning until green?
3. What prevents unchanged runtime from being reported as delivered? Is a no-code finding
   a valid research outcome without claiming improved runtime or agent effectiveness?
4. Are the preserved refusals, existing writers, rating/unknown recurrence and scope grounded?
5. Is the eight-case hypothesis comparison sufficient for a bounded go/no-go recommendation,
   with limits and a reviewed amendment before any production change?

## Log

### Reviewer · Round 1

**Input boundary:** Read the entire canonical PROJECT/2-WORKING/GH-1448-EXPLORE-ADVISORY-CONTRACT-QUALITY.md before supplementary evidence or implementation. The Setup seed path was absent: `cat .relay-artifacts/GH-1448-EXPLORE-ADVISORY-CONTRACT-QUALITY.md` exited 1, `No such file or directory`; used the canonical path explicitly named in Review packet instead.

**What this proposes**

The current authorized plan is an eight-case, non-executing comparison of existing Jog admission with a simple advisory hypothesis, capped at 30 minutes. It permits a no-code recommendation; implementation requires evidence and an independently reviewed amendment. Current authorization supersedes the historical intake's later-authorization wording, while leaving merge and cleanup outside scope.

**How the existing system works, per this document**

Jog filters command forms and paths, while preflight evaluates command exit status. Neither establishes semantic correspondence between a probe and the requested outcome. Existing HQ/PRS writers retain admission and contract ownership; the study consumes GH1447 receipts without replaying them.

**What it’s not**

This is not runtime delivery, semantic proof, automatic admission, a new linter runner, or a population accuracy measurement. No-code research may complete this study without improving runtime or establishing agent effectiveness.

**Source-backed assessment — Ship the bounded study**

swept file: yes

- [Pass] Admission, evaluation and relevance are separate. `utils/py/jog_run.py:1568` strips/rejects trivial commands and resolves selected token-1 paths; `:1624` validates JSON probe shape without executing it. `utils/py/swarm_preflight.py:243` runs command probes and interprets status with `expect_nonzero`; its `landed` label is a preflight state, not semantic acceptance. The plan explicitly says “Lexical command-form recognition cannot establish the task's outcome.” Preserve that distinction in the report.
- [Pass] Controls are predeclared in `TESTS-RESULTS/2026-11-12+GH-1448/cases.json`: constant-printf/wrapped-constant desire warnings; input-dependent-printf/specialized-pipeline desire silence despite starting with printf; option-refusal expects rejection. GH1243's command matches `PROJECT/2-WORKING/GH-1243-CONSULT-ANSWER-PAYLOAD.md:48`; GH1254's matches `PROJECT/2-WORKING/GH-1254-OUTER-LOOP-BORROW-DECL.md:134`. These deliberately adverse controls support a bounded go/no-go comparison, not population accuracy or permission to tune until green.
- [Pass] No-code is explicitly valid: step 3 says “publish a no-code recommendation and evidence”; step 4 requires source unchanged on that path and forbids runtime-delivery claims. The amendment review condition prevents study approval from authorizing a particular implementation. Eight cases/30 minutes are proportionate to rejecting or retaining this narrow lexical hypothesis, not establishing general effectiveness.
- [Pass] Existing refusals have retained observations in GH1447 `replay-results.json`: empty → “empty probe command”, trivial → “trivial probe pattern rejected: 'echo ok'”, missing → “probe target path does not resolve: missing.py”, originals → unresolved -c. These are prior recorded observations, not a new execution this turn. GH1448 explicitly consumes rather than replays them.
- [Pass] Existing writers remain owners: `utils/py/jog_run.py:1677` guards promotion with `_require_jog_primary`; its subsequent promotion path writes the doc and invokes `releases_app.py roadmap repoint`/pickup. This study calls only lint_probe and H and inspects extraction/promotion statically, avoiding those write paths. “No new tests, registry, runner, ledger, hook or telemetry machinery” bounds maintenance cost and blast radius.
- [Nit] Setup still names an absent seed path and leaves Definition of Done as a placeholder. The canonical artifact was available and Review packet's five explicit questions plus its envelope supplied review criteria, so this did not obstruct this turn. On future scaffolds, point Setup at the actually seeded artifact and populate Definition of Done.
- [Unverified — source evidence only] The numeric PRS readback and historical recurrence search were not independently queried this turn. The plan gives rating rationales and explicitly says trend is unknown; no execution/admission or recurrence claim is certified by this approval. Evaluation order, retained hashes, measured classifications and final gate remain future work.

No additional pre-existing material defect found in the whole plan. Historical “no runtime changes” wording is explicitly superseded by the current authorized section; runtime remains outside this initial study until amendment review. No suites, executable fixtures, inherited command probes, Git operations or runtime evaluations ran during this review. Read commands exited 0 except the missing Setup seed lookup recorded above; no harness gate result is claimed.

**VERDICT: PASS**

**Basis:** Approve the initial bounded research plan against Review packet questions 1–5, with no runtime change approved. Its chosen sample can expose the stated heuristic's limits while preserving refusals, current writers and an honest no-code outcome. Later implementation needs the specified reviewed amendment and final evidence.

Relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-11-12T22:41:55Z
task: GH1448-PLAN
reviewer: codex
status: Approved
reviewed-head: 27adc227b8606cf1a49547508ab18ad22dd1ec84
added-range: 7641+5442
added-sha256: f0ea5643fd74078a0c1e0b43ac2940bfe3234066eee8692b31cc8a36e1a3320b
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
