# RELAY · GH-1046 final QA: skills-army-hq copy-not-link visibility
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-12.
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
6. **Commit only the relay file** (`relay(gh1046-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the implementation diff `git diff d86f647b245e866f23245211b8d36e4cc49ecc67..HEAD -- skills/3-weekly/skills-army-hq` (SKILL.md, scripts/intake.py, scripts/sync.py), against the approved plan `PROJECT/2-WORKING/GH-1046-COPY-NOT-LINK.md` (plan QA: `relay-system/2026-10-12/gh1046-plan-qa.md`, approved r2) and the evidence in `TESTS-RESULTS/2026-10-12+GH-1046/` (`manual-check.log`, `provenance.jsonl`). Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1046
- Operational envelope: local single-operator CLI plus a skill doc; a clarity change. Grade against the issue's Goal 1-4 and the approved plan with commensurate complexity; do not ask for new state, JSON keys, flags, tests or machinery (GH-831: a new test file or validate.sh entry in the diff is itself a finding). Read-only probes only; no validate.sh / test/*.sh / pytest in the relay worktree.
- Questions:
  1. Is each issue goal met? (1) copy not link, (2) source path + revision per copy, (3) which app roots link, (4) consequences (any clean checkout of the merged revision; deletable after intake; update needs a newer source). Cite SKILL.md lines and the emitted lines in `manual-check.log`.
  2. Do the code paths match the plan (steps 2-5)? `is_linked` reused by `render_catalog` with catalog output unchanged; `copy_line` fallbacks `manual/unadopted` / `unknown`; `(disabled)` marking; `print_copies` shared by `intake.py list` and `sync.py --status`; `will COPY` only on add/update preview (and not on the unchanged-update early return). Did a duplicate helper or parallel writer slip in?
  3. Is stdout JSON unchanged on all four paths? Does the evidence (byte `cmp` on nonempty output, existing suite green, three red controls) substantiate that, and the stderr claims?
  4. Any correctness bug: e.g. `copy_line` on a receipt whose `commit` is present but `None`, a target path that no longer resolves (`location()` raising inside `is_linked` for `list`/`--status` where base did not raise), `--retire-trinity --status`, or SKILL.md wording that overclaims (e.g. that every collection entry is a real folder)?
  5. Does the persisted rating `rated 55/40/50/85` still match the evidence?
- Flag anything wrong, missing or over/under-engineered, citing file:line.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-12
- Definition of Done: the issue's Goal 1-4 are met by the approved plan's smallest change; stdout JSON is byte-identical; no new tests/state/deps; the cited evidence supports each claim. Approve (STATUS: Approved) when that holds.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
