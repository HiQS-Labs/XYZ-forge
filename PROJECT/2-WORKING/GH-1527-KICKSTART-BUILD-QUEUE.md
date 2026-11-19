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
| Recon on base `ad22311e8`; plan written. | Codex plan QA, then build. |

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
  `pr`, `title`, `draft`, `held` (hold label reason or null), `inherited_hold`, `unknown`
  (mergeability not yet computed), `conflicting`, `behind`, `failing` (list of failed checks).
  It carries **no author, body or head branch**. It is plan-only by default (no writes).
- `own vs others` therefore needs `gh pr list --json number,author,title,body` (one call). That
  call adds identity and issue links only; PR state still comes from pr_minder.
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

PRs (state from pr_minder; author from gh):

1. held or inherited hold → Needs-operator (held).
2. author ≠ `--owner` → Needs-operator (someone else's PR).
3. draft → bucket D, drafts: finish or close.
4. conflicting, or failing checks → bucket B, repair: merge development in, gate, merge.
5. unknown or behind → bucket C, one merge-cleanup batch (refresh, then land; reconcile once).
6. otherwise → bucket A, clean: wait for review, merge.

Issues (open, created within `--since-days`):

1. in `--other-session` → Needs-operator (owned by another session; remind only).
2. in `--needs-operator`, or title matches `\bdecid(e|ing)\b|\bdecision\b` → Needs-operator (decision).
3. closed by an open own PR (closing keyword or title `GH-N`) → folded into that PR's line.
4. label `merge-batch`, or title matches `^Merge batch|merge inventory|\bsweep\b` → bucket G,
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
pr_minder and gh. Default: live calls. With saved inputs and `--as-of`, two runs are identical.

### Steps

1. Add `skills/1-hourly/kickstart/scripts/build_queue.py` (stdlib only; runs pr_minder via
   subprocess, gh via subprocess). Verify: live run prints all four sections.
2. kickstart SKILL.md: one parent step under section 1 (build the queue with build_queue.py,
   record the authority grant in the run record, then dispatch) plus the closed ordering list.
3. CHANGELOG entry; ARCHITECTURE.md index line if scripts are indexed there.
4. Manual check `TESTS-RESULTS/2026-11-19+GH-1527/`: saved inputs, output, diff against the hand
   queue with each difference explained (state drift since the hand queue vs rule), determinism
   rerun (`cmp` of two outputs), and a red control: an input with a held PR and a non-owner PR
   must route both to Needs-operator, never the queue.

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

(filled at handoff)
