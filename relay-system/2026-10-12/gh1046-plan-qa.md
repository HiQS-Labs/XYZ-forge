# RELAY · GH-1046 plan QA: skills-army-hq copy-not-link visibility
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
6. **Commit only the relay file** (`relay(gh1046-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1046-COPY-NOT-LINK.md` (the plan; sections Ask, Acceptance, Recon, Plan, Rating rationale). Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1046
- Source paths the plan changes (read them in full): `skills/3-weekly/skills-army-hq/SKILL.md`, `skills/3-weekly/skills-army-hq/scripts/intake.py` (`source_record`, `render_catalog`, `main` list/add/update branches), `skills/3-weekly/skills-army-hq/scripts/sync.py` (`main`). Also `skills/3-weekly/skills-army-hq/README.md:61-75`, `test/test_deploy_skills.py`, `test/skills-army-hq.sh`, `utils/ci-route.sh` (skills-army-hq subsystem), `AGENTS.md` *No new tests* (GH-831).
- Operational envelope: a local single-operator CLI (two ~800/~260-line Python scripts) plus a skill doc. This is a clarity change: one short SKILL.md block and a few human-readable stderr lines from receipt data that already exists. Grade against the stated requirements and commensurate complexity; do not ask for new state, JSON schema changes, flags, tests, or enterprise machinery. Read-only probes only (no validate.sh / test/*.sh / pytest in the relay worktree).
- Questions:
  1. Are the Recon claims grounded? Do receipts really carry `source`/`commit`/`dirty` (`intake.py` `source_record`), and does every stdout consumer (tests, other scripts, docs) parse JSON such that stderr-only additions are safe? Cite any consumer that reads stderr or expects empty stderr for `list`, `add`/`update` preview or `sync.py --status`.
  2. Is any requirement from the Ask missing (copy not link; source path + revision; which app roots link; consequences: any clean checkout of the merged revision, deletable after intake, update needs a newer source)?
  3. Does the plan extend the existing writer/helpers (reuse `render_catalog`'s link check via a shared `linked_targets`) rather than building a parallel path? Is putting `copy_line` in `intake.py` and importing it from `sync.py` (which already does `import intake as shared`) right?
  4. Are there receipts without `source`/`commit` (e.g. `catalog`-adopted or `init --adopt-existing` skills) and does the plan's fallback text handle them truthfully?
  5. Is the verification sound under GH-831 (existing `skills-army-hq.sh` suite + recorded manual check + red control on the existing suite)? Is the red control (temporarily print to stdout in `list`/`--status`) actually caught by an existing test — i.e. does any existing test parse `list` or `--status` stdout?
  6. Rating `55/40/50/85`: grounded?
- Flag anything wrong, missing, or over/under-engineered, citing file:line.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-12
- Definition of Done: the plan, if executed, satisfies the issue's Goal 1-4 with the smallest change, keeps stdout JSON byte-identical, adds no tests/state/deps, and its acceptance checks can fail. Approve (STATUS: Approved) when that holds.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
