# RELAY · GH-955 final QA — centralized downstream publisher (implementation)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-03.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

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

### Reviewer · Round 1

VERDICT: FAIL
Basis: Two documentation fixes remain; clone-only verification is not attested by this turn.
swept file: no

Scope: Read the whole primary publisher (481 lines), both focused suites, the approved plan, push-downstream skill, both AgentChorus READMEs and child CI; inspected routing and evidence. The primary-file sweep included pre-existing code. Full branch-file sweep and base comparison remain unverified: no seeded diff was available and git is explicitly prohibited. Graph tools were unavailable; source reads were used. No suites, executable fixtures, git commands or source edits were run.

- **[Should] F1 — Published installation instructions name nonexistent child paths.** skills/2-daily/agent-chorus/standalone/README.md:36 says to run `bash skills/2-daily/agent-chorus/install.sh`; its links at lines 45–53 repeat that layout. The shared README promises applicability to both repos at lines 9–13 but uses forge-only commands at lines 30, 42, 78 and 105. The destination is actually skills/agent-chorus/install.sh (utils/py/xyz_mini_sync.py:118). Fix the standalone paths and distinguish forge/child commands in the shared README. This pre-existing defect is in the touched files and in scope.
  Observed input: The literal quick-start command above against the 13-path child payload.
  Affected scope: Child installation, copy, configure-store and smoke instructions, plus local package links in the two READMEs.
  Falsifier: A child manifest containing skills/2-daily/agent-chorus/install.sh would make the install finding unnecessary; the manifest contains the flat path instead.
  Probe command: Python 3 AST parse of utils/py/xyz_mini_sync.py; ast.literal_eval of AGENT_CHORUS_MANIFEST; collect destination paths and compare the documented and actual install paths. Exit 0; decisive output: `payload_paths=13; documented_install_in_child=False; actual_install_in_child=True`. No artifact executable was invoked. The later unrelated shell glob lookup failed, without affecting this completed probe.

- **[Should] F2 — Provide the promised runnable setup recipe.** PROJECT/2-WORKING/GH-955-CENTRAL-DOWNSTREAM-PUBLISHER.md:121 promises a documented JSON-decoding one-liner. skills/3-weekly/push-downstream/SKILL.md:74 points to that step as the recipe, but it is prose only; TESTS-RESULTS/2026-10-03+GH-955/agentchorus-setup-commit-dryrun.log:4 also summarizes it. Add concrete commands to the existing skill or plan with explicit forge/child locations, JSON-to-sorted-destination-lines conversion, both legacy deletions, setup commit/push, and the documented intermediate CI failure. No runtime adoption mechanism is needed.
  Observed input: The skill recipe pointer resolves to step 4, which says “The commit is generated by a documented one-liner and pushed” without providing it.
  Affected scope: The one-time AgentChorus migration before ordinary publication.
  Falsifier: An existing linked runnable recipe that emits the 13 destination rows and removes both legacy paths satisfies this request; supply its location if present.

- **[Pass] Static publisher review:** utils/py/xyz_mini_sync.py:460–477 deduplicates in profile order, rejects multi-target --dest and check/write combinations, processes all returned target results and selects max exit. Lines 287–323 compare managed bytes/modes and detect missing files/source_sha without destination_ready or child branch/origin calls. Lines 105–120 contain 13 AgentChorus payload rows. No additional defect was established in the rest of the primary-file sweep.
- **[Pass] Static CI and operator safeguards:** skills/2-daily/agent-chorus/standalone/ci.yml:19–27 reads source_sha, fetches/checks out it, invokes --check and uses the actual child smoke directory. skills/3-weekly/push-downstream/SKILL.md:24–60 retains clean/main preconditions, preview, confirmation, exit meanings and read-back; lines 78–81 prohibit force pushes/history rewrites. utils/ci-route.sh:33 and :50 retain gh620 routing.
- **[Unverified — needs clone run]** Focused suites and red controls are producer receipts in TESTS-RESULTS/2026-10-03+GH-955/provenance.jsonl, not rerun here. Final-state full gate, child workflow execution, exact #934/base comparison, whole-diff absence of new gate machinery and removed-skill guidance comparison remain unverified. Supply a seeded diff/base artifact for the next review within the no-git boundary.

Handing off to Producer (claude-a): address F1/F2, provide the comparison artifact, and open the next review round.

### Producer · Round 1 (claude-a)

- **F1 Implemented.** The shared `skills/2-daily/agent-chorus/README.md` commands now run from the skill folder (`bash install.sh`, `cp -R "$PWD" …`, `python3 scripts/agent_chorus.py configure-store`, `bash test-standalone.sh`), which works in both repos. It names both folder locations. The child-only `standalone/README.md` uses `cd skills/agent-chorus && bash install.sh` and folder links, which avoids forge-only file paths and keeps the forge path-integrity check honest. Verified: path-integrity 3/0, agent-chorus 215/0, and `test-standalone.sh` run from the skill folder 115/0, the same working directory the child CI uses.
- **F2 Implemented.** `skills/3-weekly/push-downstream/SKILL.md` now carries the literal recipe:
  - the JSON-to-sorted-paths `MANIFEST.txt` write;
  - `git rm` of both legacy paths;
  - the commit and push;
  - the first `--push`;
  - the expected intermediate CI failure, and green-at-first-publication as the done condition.

  It is the same sequence that `TESTS-RESULTS/2026-10-03+GH-955/agentchorus-setup-commit-dryrun.log` ran green.
- **Comparison artifact:** the whole branch diff, plus the two deleted skills' base text for the guidance comparison, is seeded read-only at `.relay-artifacts/gh955-branch.diff`.

Requesting Round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
