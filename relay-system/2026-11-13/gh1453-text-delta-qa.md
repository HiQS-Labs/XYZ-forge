# RELAY · GH-1453 text delta QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-13.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 1

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
6. **Commit only the relay file** (`relay(gh1453-text-delta-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the text changes made **after** final QA approval, `git diff 2ed9abb57 07490ab50 -- skills/2-daily/jog/SKILL.md PROJECT/2-WORKING/GH-1453-JOG-LOCAL-RECONCILE.md CHANGELOG.md` (if you cannot run git, read the current files: the skill section "Checkpoint publication (`--checkpoint-root`)", the plan doc's Recon bullet "Where the stop came from", Plan steps 8 and 10, and the GH-1453 CHANGELOG entry). No file under `utils/` changed.
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-13
- Why this round exists: the code and evidence were approved in `relay-system/2026-11-13/gh1453-final-qa.md` (round 3, attested at `2ed9abb57`). The operator then directed four text changes. The operator has allowed **one** review round on them; the Producer adjudicates your findings afterwards. Write everything you have in this one turn.
- The operator's four directions: (1) fix the source sentences that produced the stop (two hand-written lines on a downstream issue), not only the skill; (2) make the skill a **closed list**: "these are the only stops, by exact error string; anything else, continue", replacing a sentence that banned asking for a "quiet window", because a ban on one phrase does not stop the next invented rule; (3) define "competing writer" once, in the Jog skill, and tell run-directive authors to cite it instead of restating it; (4) correct the Observed record: the wording came from the operator's own issue checklist and directive, and the hold was 47 minutes, not a day.
- Operational envelope: skill and plan prose read by coding agents and by people writing run directives. Grade whether an agent reading the skill would act correctly. No new tests or machinery (GH-831).
- Definition of Done: the skill text is true of `utils/py/jog_run.py` `JogCheckpoint`, the closed list cannot be read as permitting an invented stop, and the definition of "competing writer" matches what the code enforces.

### Step A: paraphrase first (GH-1414). Do this BEFORE reading source.
Read ONLY the skill section "Checkpoint publication (`--checkpoint-root`)". Then write, at the top of your block: **What this section tells an agent to do**, **What counts as a stop, per this section**, **What it's not**, and **Input boundary**.

### Step B: source-backed validation
Read `utils/py/jog_run.py` `JogCheckpoint` (and `JogSupervisorLock` and its use in `jog_run_main`), then answer with `file:line`:

1. Closed list: is every Jog-authored checkpoint stop in the code on the list, and is every listed message in the code? Is there any other way a `--checkpoint-root` run stops for a remote-related reason that the "anything else: continue" sentence would wrongly tell an agent to ignore (for example a stop printed without the `jog: checkpoint held:` prefix, a `SystemExit` from `_require_jog_primary`, or a traceback)? Name each with its line.
2. "Competing writer": the section says the supervisor lock refuses a second `jog run` in the same primary clone and the replay check stops on an operator queue verb on the wake's rows. Is each half true? Cite the lock and the check. Does the definition leave out a real competing-writer case, such as a second primary-pinned clone on another machine writing the same queue rows and pushing them?
3. Does "anything that is not on it is not a stop ... continue" overreach: could it be read as telling an agent to continue past a failed task, a failed gate, or a non-checkpoint Jog refusal? If so, give the smallest wording change that scopes it to checkpoint publication.
4. Is the instruction to directive authors ("cite this section; do not restate or paraphrase") placed where a directive author would find it, and is it consistent with the rest of the skill?
5. Plan step 10's two replacement sentences for the downstream issue: are they accurate against the skill and code, and do they avoid restating a stop condition in their own words?
6. Is the corrected account in the plan doc ("Where the stop came from") internally consistent with the rest of the doc and the CHANGELOG entry?

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
