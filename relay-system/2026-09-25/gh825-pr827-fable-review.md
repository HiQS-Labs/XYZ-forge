# RELAY · PR 827 Fable high review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-25.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 2

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
6. **Commit only the relay file** (`relay(pr-827-fable-high-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh825-pr827-f0e68399.patch** — the read-only path that
  `relay-drive.sh --artifact-file temp/gh825-pr827-f0e68399.patch` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: claude   ·   Producer: codex
- Started: 2026-09-25
- Definition of Done: Independently review PR #827 at head `f0e683992560ed03cd51c9cf70b82ae7ccba72b2` against `development` base `31a42867521577e58220cd194d442212c609b7ca`. Identify concrete correctness, naming, safety, or verification gaps; approve only if the whole branch meets its stated requirements.

## Review packet

Operational envelope: a portable Markdown `handsfree` skill and two operator-requested skill follow-ups in one PR. Use Claude Code Fable 5 at high effort. Review the complete seeded patch and the full current versions of changed files. The PR is draft because its follow-up commit changed a skill installer and an existing test while the operator restricted local verification to the PDDA Markdown/text gate. Do not treat the earlier full gate at `9b3a780d` as proof for this head. Do not run `validate.sh`, `test/*.sh`, pytest, or executable fixtures in this relay worktree; use only read-only source inspection and narrow non-mutating probes as the relay policy permits.

Read `PROJECT/2-WORKING/GH-825-HANDSFREE-SKILL.md`, `skills/1-hourly/handsfree/SKILL.md`, `skills/1-hourly/start-task/SKILL.md`, `skills/2-daily/where-are-we-at/SKILL.md`, its `install.sh`, `test/gh798-status-skill.sh`, `utils/ci-route.sh`, `githooks/pre-push`, and the `ARCHITECTURE.md` and `CHANGELOG.md` entries. Use the seeded patch for exact changed lines. The original Codex QA receipts are `relay-system/2026-09-25/gh825-plan-r2.codex.md` and `gh825-final.codex.md`; both predate the follow-up commit.

Questions:
1. Does `handsfree` meet the 10-minute, at-most-three-hour native same-conversation wake requirement, including stop/cancel uncertainty and the ignored note? Cite concrete lines for any gap.
2. Does `start-task` correctly use the existing docs route for Markdown/text-only diffs while retaining the tiered/full route for scripts, tests, DB files, and renames? Is any instruction internally contradictory or easy to misapply?
3. Is `where-are-we-at` fully renamed for actual skill discovery and installation? Check the installer target, catalog entry, trigger text, and updated existing test assertions. Find any live old-name reference that would break use.
4. Does the PR's test and review evidence support its current draft status, and what exact check remains before merge readiness? Do not request a new framework or speculative tests.
5. Is the 13-file PR diff surgical and coherent? Identify any concrete unintentional change or latent defect in the touched files.

Give one `VERDICT: PASS`, `FAIL`, or `PARKED`, a concise Basis, `swept file: yes/no`, and graded findings with file:line citations. For every behavior-change `[Blocker]` or `[Should]`, include `Observed input:`, `Affected scope:`, and `Falsifier:`. Write only this relay thread; do not edit implementation files or the PR.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
