# RELAY · GH-955 final QA — centralized downstream publisher (implementation)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-03.
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
6. **Commit only the relay file** (`relay(gh955-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- **Artifact under review:** `utils/py/xyz_mini_sync.py` (primary), plus every other file in the branch diff.
- **Diff to read:** `git diff 5c67ae05e9fa HEAD -- . ':!relay-system' ':!TESTS-RESULTS'` (branch `feat/gh-955-central-publisher`) and the evidence directory.
- **Approved plan:** `PROJECT/2-WORKING/GH-955-CENTRAL-DOWNSTREAM-PUBLISHER.md` (approved in plan-QA round 3, `relay-system/2026-10-03/gh955-plan-qa.md`). It includes the operator's answers Q1–Q5.
- **Evidence:** `TESTS-RESULTS/2026-10-03+GH-955/` (`provenance.jsonl`, `preview-all.log`, `agentchorus-setup-commit-dryrun.log`, `recon/`).
- **Reviewer:** codex · **Producer:** claude-a · **Started:** 2026-10-03
- **Operational envelope:** a local developer CLI that the operator runs occasionally to refresh three small child repos. Grade against the approved plan and commensurate complexity. XYZ-forge forbids new test suites (GH-831): new checks are assertions in the existing gh589 / gh620 suites, which is allowed. Do not run suites in the relay worktree; flag anything that needs a clone run as `[Unverified — needs clone run]`.

### Acceptance map (plan step → change → check)

| Step | What changed | Check |
|---|---|---|
| 1 | Multi-target CLI: `main` → `publish_one` / `check_one` loop, dedup, `--dest` guard, worst exit | gh589 multi-target assertions; red control A (a short-circuiting loop) fails gh589 |
| 2 | `RETIRED_TARGETS` removed; gh620 opt-in dropped; expected set is 9 payloads | gh620 28/0; red control B (re-retired) fails gh620 |
| 3 | `agent-chorus` profile with 13 payload rows | gh589: the published child has exactly the 13 manifest paths and no legacy TSV, and `--check` passes |
| 4 | Setup commit recipe (operator, post-merge) | `agentchorus-setup-commit-dryrun.log` on a disposable clone of the real child |
| 5 | `--check` read-only path | gh589: detached child passes; byte drift and exec-bit drift → 1; `--check --apply` → 2 and untouched; mixed multi-target → 1 |
| 6 | Child CI uses `--check`; smoke path fixed; READMEs; script and TSV deleted | path-integrity; no `sync-to-standalone` references remain outside history |
| 7 | `UPSTREAM.md` deleted; `push-downstream` replaces both skills; ROUTER / skills README / ARCHITECTURE / PAGES / ci-route; #934 patch; GH-882 doc; CHANGELOG | `git diff origin/feat/sharpen-skills-army-hq -- skills/3-weekly/skills-army-hq/SKILL.md` is empty; skills-army-hq 33 passed |
| 8 | Read-only previews against the real children | `preview-all.log`: copy 36 / delete 0; copy 9 / delete 0; agent-chorus refused (expected) |

### Questions for the Reviewer
1. Does each step's code match the approved plan? Cite `file:line` for any departure.
2. Did the `main` → `publish_one` extraction change single-target behaviour? Compare against `5c67ae05e9fa:utils/py/xyz_mini_sync.py`, especially the exit codes, the log prefixes and `destination_ready` usage.
3. Is `check_one` truly read-only and branch- and origin-agnostic? Does it compare exactly the managed paths, and treat a missing child file and a missing `source_sha` as drift?
4. Is the child CI (`skills/2-daily/agent-chorus/standalone/ci.yml`) correct? Does it read `source_sha`, check out that forge SHA, and run `--check` against the workspace? Does the smoke step's working directory exist in the child (`skills/agent-chorus/`)?
5. Did any #882 reversal surface or old-skill reference survive where it should not? Did the fold drop any operator guidance from the two old skills (preconditions, exit-code meanings, never-force-push)?
6. Did any new suite, `validate.sh` registry entry or gate machinery slip in (forbidden by GH-831)? Is any change over-built for this envelope?

Cite `file:line` for every finding. Behaviour-change requests carry `Observed input:`, `Affected scope:` and `Falsifier:` lines.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
