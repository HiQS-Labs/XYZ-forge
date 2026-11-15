# RELAY · GH-1486 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
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
6. **Commit only the relay file** (`relay(gh1486-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the completed change on this branch against base `5967bde25`: `git diff 5967bde25..dc31da6af`. Files: `skills/4-occasional/re-vendor-xyz/SKILL.md` (new), `ARCHITECTURE.md`, `README.md`, `skills/4-occasional/vendor-stack/SKILL.md`, `CHANGELOG.md`, the plan `PROJECT/2-WORKING/GH-1486-RE-VENDOR-XYZ-SKILL.md`, evidence under `TESTS-RESULTS/2026-11-14+GH-1486/SUMMARY.md` (start there; driver `TESTS-RESULTS/2026-11-14+GH-1486/fixture-checks.sh.txt`), the approved plan thread `relay-system/2026-11-14/gh1486-plan-qa.md`, and the ledger row for GH-1486 in `releases.sql`.
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-14
- Operational envelope: an instruction-only skill an agent follows on one developer's machine to refresh one repository's `.xyz/` copy by sequencing existing commands (`relay-automation/xyz-sync.sh`, `xyz-vendor.sh`, Skills Army HQ `sync.py`). No script, flag or suite is added (`AGENTS.md` *No new tests*, GH-831); a new `test/` file or `validate.sh` entry would be a finding. The operator chose a separate skill over a `vendor-stack` section (issue #1486, first comment); do not reopen that.
- Definition of Done: each plan acceptance item A1–A7 is satisfied by evidence that would fail on base; the skill's shell block does what its prose and closed stop list say; no duplicate writer or helper slipped in; the evidence substantiates the claims.

### Step A: paraphrase first (GH-1414). Do this BEFORE reading anything else.
Read ONLY `skills/4-occasional/re-vendor-xyz/SKILL.md`. Do not open the plan, evidence or source yet. Then, at the top of your review block, write:
- **What this proposes** (2–5 sentences)
- **How the existing system works, per this document** (2–5 sentences)
- **What it's not** (short; ground exclusions in the skill's text and label any inference)
- **Input boundary:** what you had read when you wrote the paraphrase.

### Step B: source-backed validation
Now read the plan, the evidence, the diff and the source it calls (`relay-automation/xyz-sync.sh`, `relay-automation/xyz-vendor.sh:36-75,230-240,420-516`, `relay-automation/driver-lock-lib.sh`, `utils/py/relay_drive.py:110-125,515-525`, `utils/py/rtl.py:980-1010`, `skills/3-weekly/skills-army-hq/SKILL.md:20-90,190-250`). Label this assessment **source-backed**. Answer with `file:line` evidence:

1. Does the steps 1–8 block implement each of the 11 listed stops, in the stated order, and nothing that stops outside the list? Name any stop whose shell check differs from its prose.
2. Shell correctness under `set -u` in `bash -s` with a quoted heredoc: quoting of paths with spaces, the `awk` registry match (exact `present` row for `$T/.xyz`), the subshell that sources `driver-lock-lib.sh`, the `ps` filter (does it exclude itself and its parent, and can it match its own argv?), the `current()` function's three conditions, and the exit codes (0 current, 3 stop) as seen by the outer `echo "re-vendor-xyz: exit $?"`.
3. Step 2 runs `git fetch origin "$BR"` then `git merge --ff-only origin/$BR`. Is the remote-tracking ref reliably updated by that fetch form, and is the ff-only merge safe on the operator's Forge checkout (clean tree already required)?
4. Step 9: is the read-only status block correct (`--root`, `--status`, `--canonical`), and does the prose keep writes with `/skills-army-hq`?
5. Evidence: does the fixture driver run the skill's own extracted block (not a reimplementation), and do A3–A6 assertions observe the right things (named stop, no backup, no `update` call, `VERSION` unchanged; three-part current test; "already current" with no writer call; `ok`+guard-missing not accepted)? Does each base red control really fail on `5967bde25`? Is anything claimed that the logs do not show?
6. Pointers and docs: are `ARCHITECTURE.md`, `README.md`, `vendor-stack` and `CHANGELOG.md` accurate and consistent with the skill? Are the recovery instructions safe?
7. What prevents an unchanged base from being reported as delivered, and where is that rejection observed?
8. Over- or under-engineering against the envelope. Do not ask for new suites.

Write graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), then a VERDICT. Set STATUS to Approved only if no `[Blocker]` or `[Should]` remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
