# RELAY · GH-1453 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-13.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1453-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the committed implementation on this branch against base `6c0c76bb5`: `utils/py/jog_run.py` (`JogCheckpoint` and its two call sites in `jog_run_main`; `git diff 6c0c76bb5 -- utils/py/jog_run.py`), `skills/2-daily/jog/SKILL.md` (the new "Checkpoint publication" section), `CHANGELOG.md` (the GH-1453 entry), and the evidence in `TESTS-RESULTS/2026-11-13+GH-1453/`. This is the **final review** of completed work.
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-13
- Plan of record: `PROJECT/2-WORKING/GH-1453-JOG-LOCAL-RECONCILE.md` (approved in `relay-system/2026-11-13/gh1453-plan-qa.md`, round 3), including its `## Implementation notes`, which disclose one addition beyond the approved plan.
- Operational envelope: a local developer CLI (`releases_app.py jog run --checkpoint-root`), one operator per primary clone, other sessions pushing to the same `development`. Grade against the issue's acceptance and commensurate complexity, not enterprise or multi-tenant threat models. The repo forbids new tests, suites, registry entries or gate machinery (AGENTS.md *No new tests*, GH-831); a new test file in the diff is a finding. Verification is existing suites plus manual checks recorded under `TESTS-RESULTS/`. `fixture-checks.py.txt` there is a recorded manual-check driver, not a suite or registry entry.
- Definition of Done: each acceptance item A1–A12 is met by the code and supported by retained evidence; the code matches the approved plan or discloses where it does not; no duplicate subsystem or second ledger writer was introduced.

### Step A: paraphrase first (GH-1414). Do this BEFORE reading anything else.
Read ONLY the plan doc (`## Plan`, `## Acceptance`, `## Risks`, `## Implementation notes`) and `TESTS-RESULTS/2026-11-13+GH-1453/SUMMARY.md`. Then, at the top of your review block, write:
- **What this delivers** (2–5 sentences)
- **How the existing system works, per these documents** (2–5 sentences)
- **What it's not** (short; ground exclusions in the documents and label any inference)
- **Input boundary:** list what you had read when you wrote the paraphrase.

### Step B: source-backed validation
Now read the diff and source: `git diff 6c0c76bb5 -- utils/py/jog_run.py skills/2-daily/jog/SKILL.md CHANGELOG.md`; `utils/py/jog_run.py` `JogCheckpoint` in full; `utils/py/releases_app.py` (`perform_write` 1662-1790, `jog_acquire_lease` / `jog_set_status` 5072-5135, `_rebuild` 6540-6665); `utils/releases-merge-resolve.sh`; the logs `candidate-A1-A12.log`, `base-red-controls.log`, `a6-skill-text.log`, `gh280-jog-marathon-adapter.log`, `jog-queue.log` and the driver `fixture-checks.py.txt`. Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1453.

Label the assessment **source-backed**. Answer each with `file:line` evidence:

1. For each acceptance item A1–A12: is it satisfied by the code, and does the retained log actually observe it? Quote the decisive log line. Mark any item whose log shows only "nothing crashed".
2. What prevents an unchanged, unfixed tree from being reported as delivered, and where is the observed rejection? Check `base-red-controls.log` against the driver: does each red control fail for the stated reason, or for an incidental one?
3. Does `JogCheckpoint` match the approved plan steps 1–7? List every divergence. Is the disclosed addition (abort of this wake's own interrupted merge at the start of `finish()`) safe, and can it ever abort a merge that is not this wake's?
4. Read `finish()`'s publication loop and `_reconcile` / `_replay` / `_abort_merge` for defects: a path that leaves the primary dirty or mid-merge, a path that publishes without replay, a path that replays twice, an exception type that escapes the restore, or a state where the journal and `HEAD` disagree after a stop.
5. Is the unmoved path (`development` did not move) behaviourally unchanged apart from the extra fetch before the push? Name anything else that changed for existing callers.
6. Did a duplicate subsystem, a second ledger writer, or a hand-edit of `releases.sql` slip in? `_replay` writes the remote's dump bytes to the working file before `check --rebuild`: is that within the repo's "never hand-edit the dump" rule, given it is the remote's canonical dump taken whole?
7. Skill text: does the new section say anything the code does not do, or omit a stop the code can print? Is each listed message found in the code?
8. Is the persisted rating (`rated 75/70/50/40`) still consistent with the evidence?
9. Is anything over-built for this problem? Do not ask for new suites.

Write graded findings, then a VERDICT. Set STATUS to Approved only if no `[Blocker]` or `[Should]` remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
