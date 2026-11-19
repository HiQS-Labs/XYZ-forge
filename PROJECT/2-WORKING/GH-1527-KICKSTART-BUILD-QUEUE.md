---
gh_issue: 1527
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1527
title: "kickstart: deterministic queue builder so a long run is one command (build_queue.py)"
status: In Progress
created: 2026-11-19
updated: 2026-11-19
owner: operator
goal: "`build_queue.py` prints a kickstart run record's Authority, Queue and Needs-operator sections from pr_minder.py --json plus gh, deterministically, so the next long run starts from one command."
doc_type: feedback
complexity: 2
risk: 1
effort: 2
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Plan approved (Codex, round 2); final QA approved (Codex, round 2) after S1 fix: live run is read-only via `pr_minder.py --no-conflict-files`. Manual check passes. | PR ready; awaiting merge. |

## Problem

On 2026-11-19 the queue for the observer-led long run (kickstart session a6590cb2) was assembled by
hand from open PRs and issues, and the operator's standing merge/close authority was granted in
chat. Neither step repeats: the next run rebuilds the list and asks again.

## Requirements (from the issue)

1. `skills/1-hourly/kickstart/scripts/build_queue.py --repo-root . [--out PATH]` emits the run
   record's Queue and Needs-operator sections from live state. Same inputs, same output.
2. Inputs: `pr_minder.py --json` and `gh issue list --json`. No second PR classifier.
3. Ordering is a closed list, written in the script and in kickstart SKILL.md (below).
4. Held PRs, others' PRs, decision-needed and other-session-owned items go to Needs-operator.
5. The authority block is a fixed template granted once and stored in the run record.
6. kickstart SKILL.md gains one parent step: build the queue, record the grant, dispatch.
7. Check: run against 2026-11-19 state, diff with the hand-built queue, record as a manual check
   under `TESTS-RESULTS/`. No new test suite (GH-831).

## Recon (base `ad22311e8`)

- `skills/2-daily/pr-minder/scripts/pr_minder.py --json` prints a list of rows per open PR with
  `pr`, `title`, `draft`, `held` (hold label reason or null), `inherited_hold`, `conflicting`
  (`mergeStateStatus == DIRTY` or `mergeable == CONFLICTING`, `pr_minder.py:220-221`), `behind`
  (`BEHIND` or measured drift, `:225`), `failing` (failed checks, `:222`). Its `unknown` key means
  **author history unavailable** (`:217`), not GitHub mergeability; the raw `mergeable` value lives in
  `pr_data`, which `--json` omits. It carries **no author, body or head branch**. Plan-only by default.
- `own vs others` and GitHub's raw mergeability therefore need one
  `gh pr list --json number,author,title,body,mergeable` call. It adds identity, issue links and the
  raw `mergeable` string only; conflict, behind, failing, draft and held still come from pr_minder.
  pr_minder's `unknown` (author history) does not affect landing order and is not used.
- Issue labels are sparse: 2026-11-19's hand-queue issues are mostly unlabeled (`#1519`, `#1517`,
  `#1500`, `#1499`, `#1508`, refactors `#1480`–`#1483`). Classification must lean on titles.
- Open issues total >300, so the builder needs a window: issues created in the last
  `--since-days` (default 14) days.
- PR-to-issue links: PR bodies cite many unrelated issues (`#1495` body cites `#1400`), so only
  closing keywords (`Closes|Fixes|Resolves #N`) and a `GH-N` in the PR title count.
- `skills/1-hourly/kickstart/` holds only `SKILL.md`; no scripts directory yet.
- Run record shape: `temp/kickstart-2026-11-19-a6590cb2.md` (primary checkout, local only).

## Plan

### Ordering rules (closed list; first match wins)

The operator overrides `--other-session N,...` and `--needs-operator N,...` apply to PR and issue
numbers alike and are checked first.

PRs (state from pr_minder; author and raw `mergeable` from the one gh call):

1. in `--other-session` → Needs-operator (owned by another session; remind only).
2. in `--needs-operator` → Needs-operator (decision).
3. held or inherited hold → Needs-operator (held).
4. author ≠ `--owner` → Needs-operator (someone else's PR).
5. draft → bucket D, drafts: finish or close.
6. pr_minder `conflicting`, or non-empty `failing` → bucket B, repair: merge development in, gate, merge.
7. pr_minder `behind`, or raw `mergeable == UNKNOWN` → bucket C, one merge-cleanup batch (refresh,
   then land; reconcile once).
8. otherwise (raw `mergeable == MERGEABLE`, not behind/conflicting/failing) → bucket A, clean:
   wait for review, merge.

Worked cases: an own unheld non-draft PR with complete author history, `mergeable == UNKNOWN`, no
failing checks and no drift → C (rule 7). A CLEAN, `MERGEABLE` PR whose author history is
unavailable (pr_minder `unknown: true`) → A (rule 8); author history does not gate landing.

Issues (open, created on or after `--as-of` minus `--since-days`):

1. in `--other-session` → Needs-operator (owned by another session; remind only).
2. in `--needs-operator`, or title matches `\bdecid(e|ing)\b|\bdecision\b` → Needs-operator (decision).
3. closed by an open own PR (closing keyword or title `GH-N`) → folded into that PR's line.
4. label `merge-batch`, or title matches `^Merge batch|merge inventory|^\S+ sweep <YYYY-MM-DD>` → bucket G
   (narrowed during the build: a bare `\bsweep\b` misfiled #1517, whose title mentions "auto-sweep"),
   stale batch/inventory: verify, then close.
5. title starts `refactor` → bucket H, gated on the first `after #N` in title, else body.
6. label `documentation`, or title names a `*.md` file → bucket F, docs.
7. label `bug`, or title names a code/config file (`*.py`, `*.sh`, `*.txt`, `*.json`, `*.yml`) →
   bucket E, small bug.
8. title starts `Arc:`, `Plan:`, `Architectural Plan`, `Research:`, `Spike:`, `Umbrella:`, `Radar`,
   `Daily goals` → not queued (listed by number on one line).
9. anything else → Needs-operator (unclassified: operator picks scope). The run never executes an
   issue nobody classified.

Queue order: A → B → C → D → E → F → G → H → final QA. Within a bucket, ascending number.

### Output

Markdown: `## Authority granted` (fixed template, the 2026-11-19 grant text), `## Queue (execution
order)`, `## Needs the operator`, `## Not queued`. A header line names the as-of date and the
inputs. No timestamps beyond `--as-of` (default today, UTC), so fixed inputs give byte-identical
output.

### Determinism and replay

`--prs-json FILE`, `--pr-meta-json FILE`, `--issues-json FILE` read saved inputs instead of calling
pr_minder and gh. Default: live calls. The full replay input set is those three files plus
`--as-of`, `--owner`, `--other-session`, `--needs-operator` and `--since-days`; the issue window is
computed from `--as-of`, never the wall clock. Every list in every section (queue lines, folded
issue numbers, Needs-operator, Not queued) renders in ascending number. With the same replay inputs,
two runs are byte-identical.

### Steps

1. Add `skills/1-hourly/kickstart/scripts/build_queue.py` (stdlib only; runs pr_minder via
   subprocess, gh via subprocess). Verify: live run prints all four sections.
2. kickstart SKILL.md: one parent step under section 1 (build the queue with build_queue.py,
   record the authority grant in the run record, then dispatch) plus the closed ordering list.
3. CHANGELOG entry; ARCHITECTURE.md index line if scripts are indexed there.
4. Manual check `TESTS-RESULTS/2026-11-19+GH-1527/` with `provenance.jsonl` (AGENTS.md), tied
   to the implemented candidate commit and the exact commands run:
   - saved live inputs and the output they produced;
   - diff against the 2026-11-19 hand queue. **Completion rule:** every difference must be
     explained as either live-state drift since the hand queue was written (cited from the saved
     input) or a stated rule above. An unexplained difference, or an item routed against a stated
     rule, rejects delivery until fixed;
   - determinism: two runs on the same replay inputs, `cmp` exit 0;
   - routing checks on edited copies of the saved inputs: a held PR, a non-owner PR, and an own
     clean PR listed in `--other-session` and then in `--needs-operator` each land in
     Needs-operator, never the queue; the same own clean PR without overrides lands in A;
   - red control: run the routing assertion against a deliberately wrong output (the held PR
     moved into the queue by hand) and record that the assertion fails.

## Non-goals

- No new PR classifier, labels, DB rows, daemon or schedule. No test suite (GH-831).
- Does not dispatch the child or write the run record; the parent pastes or `--out`s it.
- Does not judge whether an issue is worth doing; unclassified items go to the operator.

## Preflight bet check

- Outcome sought: the next long run starts from one command and re-reads its grant.
- Smallest bet: one ~200-line stdlib script plus one SKILL.md step.
- Alternative rejected: extending pr_minder with issue logic — it is a per-PR remediation pass,
  and issues are outside its contract.
- Rollback: delete the script and the SKILL.md step; nothing else reads them.

## Risks

- Title heuristics misfile an issue. Mitigation: unclassified goes to the operator, and the diff
  check records every misfile against the hand queue.
- pr_minder JSON shape changes. Mitigation: the script reads only the named keys and fails loudly
  on a missing key.

## Rating (2026-11-19)

`rated 70/30/50/65`: operator requirement for the next run (pri 70); no defect or data risk
(sev 30); appeal neutral 50; one script plus doc step (effort 65, cheap). Recurrence: n/a (new
capability).

## Lessons Learned

A plan-only `--json` callee can still write to the checkout; trace its JSON path and prove read-only with a logging `git` shim. Entry added to `LESSONS-LEARNED.md`.
