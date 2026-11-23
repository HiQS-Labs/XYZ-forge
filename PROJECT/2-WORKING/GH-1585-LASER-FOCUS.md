---
title: "GH-1585 — laser-focus skill (lock target, mandatory ledger gate, 100% goal breakdown, client/PO triage; retires /finish-line)"
status: "Active (2-WORKING)"
created: 2026-11-23
updated: 2026-11-23
owner: noelsaw1
goal: "Land skills/2-daily/laser-focus/SKILL.md plus its index row and the /finish-line retirement as a ready PR into development."
gh_issue: 1585
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1585
doc_type: feedback
branch: feat/XYZ-forge-gh1585-laser-focus-2026-11-23
effort: 2
complexity: 2
risk: 1
phases: 1
non_goals: "merge/landing; Skills Army HQ deploy; XYZ-mini publish; re-vendoring downstream .xyz/; post-merge live-issue dogfood; new test files; CHANGELOG edits"
related: [releases, daily-planner, weekly-planner, sanity-check, unstuck, standup]
---

# GH-1585 — laser-focus

## Status

| What was just completed | What's next |
|---|---|
| Skill, index row and `/finish-line` repoints written. Focused suites green, with red controls witnessed. Read-only dogfood retained (redacted) under `TESTS-RESULTS/2026-11-23+GH-1585/`. | Final Codex relay QA on the diff; then the ready PR. |

## Problem

A client or PO posts mid-sprint input, and an agent over-reacts to it: it invents priority changes, declares items unblocked without checking live gates, removes options the client picked, and widens the active release. In the motivating private client repo, the team's working target is not in `releases.db` at all, while seven stale rows are still marked `active`. The full specification is the body of issue #1585.

## Plan: the 100% build checklist

The goal list, weights and per-goal checks were QA'd by consult (#1585, first comment). Weights total 100.

| ID | Wt | Goal (observable done) | check: → expected · fails if |
|---|---|---|---|
| G-01 | 3 | Issue filed in `HiQS-Labs/XYZ-forge` with the v4 body and a dispositions comment | `gh issue view N --json body,comments` → body contains "Step 1b" and the gate text; ≥1 comment headed "Consult dispositions" · fails if either is missing |
| G-02 | 3 | Fresh full clone `XYZ-forge-gh<N>-laser-focus-2026-11-23`, sibling of the primary, on `feat/<folder>`; `origin` is GitHub; HEAD descends from `origin/development`@base; hooks pass `--check` | `git remote get-url origin`; `git merge-base --is-ancestor <base> HEAD`; `bash githooks/install.sh --check` → all exit 0 · fails on a non-zero exit |
| G-03 | 5 | PDDA intake: `PROJECT/1-INBOX/GH-<N>-LASER-FOCUS.md` written by the repo's writer; roadmap row picked up with a 4-axis rating and read back; lifecycle promoted per PDDA before execution | `releases_app.py roadmap list` → row for #N with `rated a/b/c/d`; the doc exists in the lifecycle folder PDDA requires · fails if the row is unrated or missing |
| G-04 | 3 | `SKILL.md` frontmatter: `name: laser-focus`; the description has triggers and a "Not for" clause | parse the frontmatter → `name == laser-focus`, description contains "Not for" · fails otherwise |
| G-05 | 7 | Step 0 (repo identity, foreign-remote skip) and Step 1 (source ladder per repo policy, five source states, Q1/Q2/scope source, stop) | dogfood G-15: the first output has the source table and the questions, with no triage table · fails if a triage row appears before the answers |
| G-06 | 10 | Step 1b mandatory gate: target represented with an eligible status; each flagged row has a disposition; nothing invented; `next` is evidence only; route offers; plain-GitHub confirmed write; decline ends the run; correct-the-frame exit | dogfood G-15 on the client repo → gap "target absent" reported, run stops before triage · fails if triage proceeds or any write happens |
| G-07 | 8 | Step 1c: ask once; 10–20 goals; weights total 100; rubric R1–R8 with expected/fail conditions; consult with out-of-repo `--out`; per-criterion disposition; frozen done-list; dated revision on approved swaps | read the section; the dogfood dry run produces a checklist summing to 100 · fails if the sum ≠ 100 or the rubric is absent |
| G-08 | 7 | Step 2: three PR surfaces; verbatim vs. inference; authorized-decider rule; separate live-gate state; selection preservation with supersession; evidence grade sets confidence only | the G-15 paper classification cites per-statement IDs and quotes · fails if any row lacks a quote |
| G-09 | 10 | Step 3: decision states; defect-report exception; the 12-row ordered code table, first match wins, no fall-through; four worked examples; row schema (`claimed_severity`, `last_verified`, `check:`, `revisit_when:`) | G-15 paper run of the four examples → A4 / D1-or-C3 / C1 / C4 · fails on any mismatch |
| G-10 | 9 | Step 4: identity (timezone, slug, marker, REST paging, min number); merge-based read-modify-write; carried-row labels; visibility guard failing closed; comment-mode marker; multi-day carry-forward; size rule | read the section; a dry-run body printed in G-15 shows the header and the marker as its first line · fails if the marker isn't line 1 |
| G-11 | 4 | Step 5 handoffs; guardrails (no ledger self-write, no files, no client threads); "What it's not" | `grep -c "never writes .releases.db"` ≥1 · fails if 0 |
| G-12 | 2 | `ARCHITECTURE.md` Skills Index row under 2-daily | `grep -n "skills/2-daily/laser-focus/SKILL.md" ARCHITECTURE.md` → 1 line · fails if 0 |
| G-13 | 6 | `/finish-line` retired: `releases` :3 and :241-243, `unstuck` :216, `standup` :9, `ROUTER.md` :218, `PDDA.md` :861; `test/releases-skill.sh` :40 assertion kept truthful; history untouched | the v4 AC `git grep` → only the "re-anchor the finish line" phrases · fails if any live route remains |
| G-14 | 8 | Verification in a disposable `-gate` clone: `test/releases-skill.sh` and `test/path-integrity.sh` pass. **Red control:** with the old assertion against the new text, `releases-skill.sh` fails (or the new assertion against old text fails). The pre-push gate passes on the final SHA | logs captured, non-empty, exit codes recorded · fails on any non-zero exit or empty log |
| G-15 | 7 | Client-repo read-only dogfood (redacted for this public repo): Steps 0–1b output; Step 1c dry run; paper classification of the four worked examples plus the two PO-feedback PRs; printed body. Retained under `TESTS-RESULTS/2026-11-23+GH-<N>/` with `provenance.jsonl`; `releases.db` sha256 the same before and after | the sha256 pair matches; receipt files non-empty · fails on a mismatch or an empty receipt |
| G-16 | 8 | Final Codex relay QA on the diff reaches Approved (or findings dispositioned); ready PR against `development`, linked; closeout comment on #N; task-clone retirement through merge-cleanup `--retire-published-pr`, or the preservation reason reported | `gh pr view --json baseRefName,headRefOid,isDraft` → `development`, `isDraft=false`; relay `STATUS: Approved` · fails otherwise |

## Acceptance

The acceptance criteria are those in issue #1585 §4. Items tagged `[post-merge]` need an operator go and are out of this PR.

## Process notes

- Plan QA ran as three operator-requested consult rounds, not a relay: round 1 agy + Codex; round 2 Codex only; round 3 Codex only, because Kimi was out of quota and agy idle-timed out.
- Final QA is a Codex relay on the diff.
