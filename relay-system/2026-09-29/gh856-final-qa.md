# RELAY · GH-856 locator final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-29.
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
6. **Commit only the relay file** (`relay(gh-856-locator-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-856-RELAY-LOCATOR.md`, `skills/1-hourly/relay-xyz/find-harness.sh`, `skills/1-hourly/relay-xyz/SKILL.md`, `skills/1-hourly/relay-xyz/install.sh`, and `test/find-harness.sh`. Compare the committed branch against origin/development; issue #856 is https://github.com/HiQS-Labs/XYZ-forge/issues/856.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-29
- Definition of Done: the copied skill resolves the canonical XYZ-forge clone from the seven bounded roots or a per-Mac config while preserving override, vendored, git-root, and self precedence; search rejects task clones and wrong origins, reports ambiguity and attempted locations; shared lock helpers load from the selected harness; `--check` warns on cached upstream lag, branch, held lock, and vendored drift without fetching, and prints an executable config-save hint. Bash 3.2 and existing suites remain green. No new suite or registry entry. The RELEASES row for #856 has the rated `86/82/50/55` and accepted start, with appeal neutral as the user supplied no appeal score.

### Review questions and evidence

1. Read the entire touched locator and test files, not only the added lines. Is any concrete #856 acceptance case unfulfilled or contradicted by the current code? Cite an observed input and line for any finding.
2. Does the implementation match the approved plan without duplicating the shared resolver or changing #394/#395/#396 behavior? Is the `--check` config command executable for paths containing spaces?
3. Do the copied-skill fixtures actually exercise the desired outputs, including seven roots, ambiguity, origin validation, lock, lag, and vendored drift? Identify a vacuous or missing assertion only with a concrete falsifier.
4. Is the plan/ledger/changelog state truthful, and has any new test file or registry entry entered the diff? Check `git diff origin/development...HEAD`.

Focused evidence from a disposable full clone: `test/find-harness.sh` 47/47, `test/gh396-find-harness-roots.sh` 41/41, `test/gh292-worktree-vendored-discovery.sh` 7/7, `test/gh448-driver-lock-resolver.sh` 18/18. `pdda.sh frontmatter` and `roadmap-coverage` found 0 errors; `releases_app.py check` found 0 failures and 9 pre-existing warnings. The one full qualifying gate is reserved for the final approved commit. Do not run mutation-heavy suites in this valued task clone.

Operational envelope: a local Bash locator for one repository family across four Macs. Grade against #856 and the approved plan. Do not request a general registry, network discovery service, or unrelated root-resolution refactor. Review only; write findings to this relay file.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
