# RELAY · GH-836 final QA — trim the measured gate hotspots, plus D2
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-26.
-->

NEXT: Reviewer
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
6. **Commit only the relay file** (`relay(gh836-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh836-final.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/0cc9b6f4-22bd-4606-b4ec-21e1b8f38591/scratchpad/gh836-final.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-26
- Definition of Done: **Approved** when all of these hold:
  - (a) steps 1–4 of the approved plan are implemented as written, and each trimmed leg still proves what it
    proved;
  - (b) D2 (step 7, operator-directed after plan approval) is implemented as option C and nothing more;
  - (c) every red control named in the plan is witnessed with a falsifiable result, and the evidence is honest,
    including the two corrections the build made to its own plan;
  - (d) no new suite, registry entry or gate machinery. The only change outside `test/`, docs and evidence is
    the pre-push hook's environment default;
  - (e) the plan, CHANGELOG and ledger row claim only what the evidence shows.

## Review packet

**What this is.** The implementation of #836 (`https://github.com/HiQS-Labs/XYZ-forge/issues/836`) on branch
`fix/gh836-gate-hotspots`. The plan `PROJECT/2-WORKING/GH-836-GATE-HOTSPOTS.md` was Approved in round 2 of
`relay-system/2026-09-26/gh836-plan-review.md`, attested at `bae7c451`. The artifact
`.relay-artifacts/gh836-final.diff` is `git diff 4bd8851a 402b78c9`, leaving out the binary `releases.db`, the
rebuilt `relay-pkg.tar.gz`, the raw `.out` logs, the plan-review thread and the D2 consult transcripts. All of
those are readable in the worktree.

**Operational envelope.** A single-repo local developer harness, under the operator's "no new tests" rule
(AGENTS.md). Verification uses existing suites plus manual checks recorded under `TESTS-RESULTS/`. Grade
against the plan and commensurate complexity. The full gate runs once after this review, in a disposable
clone through the push hook, and its log is the witness for D2's default skip.

**Since the plan was approved:**

1. **D2 folded in by the operator: option C.**
   - `githooks/pre-push` defaults `RELAY_SELF_SUFFICIENCY_SKIP=1` on the full-gate `validate.sh` call.
   - `relay-automation/README.md` names the live-run obligation.
   - `test/relay-self-sufficiency.sh`'s header and skip message are updated.
   - `relay-pkg.tar.gz` is rebuilt.

   The consult transcripts are `relay-system/2026-09-26/gh836-d2-*`.
2. **The 21e "both racers exit 0" check was wrong, and is replaced.** The first after-run showed one racer
   exiting 4, the writer-lock refusal (`EXIT_LOCK_REFUSED`, `utils/py/releases_app.py:91`), once the racers
   leave the shared rows. At base the per-row sleep kept them in lockstep and both exited 0. The leg now fails
   on any exit code other than 0 or 4.
3. **W2 measured the cursor advance at about 12 s, not ~100 s.** The saving comes from turning dispatch off.

**Read:**
- the artifact;
- the plan (Recon, Plan, Results);
- `test/gh549-work-events.sh` 160-175 and 1043-1100 (21e) and 1140-1205 (21f);
- `test/gh534_phase_c_tests.py` 560-600 and 920-935;
- `githooks/pre-push` 288-305;
- `TESTS-RESULTS/2026-09-26+GH-836/`: `witnesses.log`, `witness-script.sh.txt`, `after-gh549-top-gaps.txt`,
  `baseline-gh549-top-gaps.txt`, `after-summary.log`, `provenance.jsonl`.

Read-only probes only.

**Questions** (cite `file:line`):

1. **21e.**
   - Is the rendezvous code in the mutated copy sound: the per-process counter via
     `globals().setdefault`, the marker files and the bounded wait?
   - Does the crash check's `case` pattern accept exactly 0 and 4? `witnesses.log` shows the unit check.
   - Do W1's six staggered runs substantiate reliability?
   - Is "0 or 4" the honest requirement, given `EXIT_LOCK_REFUSED`?
2. **21f.**
   - Is `backfill_nodispatch` (`XYZ_WORK_CONNECTORS=0` plus the cursor advance) equivalent, for what 21f and
     its red controls assert?
   - Given W2, is the cursor advance still worth keeping, or is it now unneeded machinery?
3. **`gh436`.** Is removing `run_tests` honest, now that W3a and W3b are witnessed? Is the new docstring
   accurate?
4. **D2.**
   - Does `RELAY_SELF_SUFFICIENCY_SKIP="${RELAY_SELF_SUFFICIENCY_SKIP:-1}"` on the hook's full-gate call alone
     implement option C?
   - Is the README obligation clear and truthful?
   - Is any other hook path affected? Tier 2 never runs this suite.
5. **Scope and accuracy.** Does anything claim more than the evidence? Is the CHANGELOG entry accurate? Is
   anything over-built?

Write findings in the Log per the turn rules. Set `STATUS: Approved` only if the Definition of Done is met.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
