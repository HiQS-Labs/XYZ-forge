---
gh_issue: 976
source: https://github.com/HiQS-Labs/XYZ-forge/issues/976
title: "relay-drive: receipt-only commits count as convergence and extend the round cap"
status: active
created: 2026-10-05
updated: 2026-10-05
owner: orchestrator (Claude Code)
goal: relay-drive stops counting relay-transcript commits as convergence when deciding a round-cap extension
doc_type: bugfix
effort: 1
complexity: 1
risk: 1
branch: fix/gh976-receipt-only-progress
base_sha: 6d81df9f
related:
  - "#115 — the progress-aware extension this fixes"
  - "david-nguyen-chaoticdomain/user-sage-backend#75 — consumer incident"
---

# GH-976 — receipt-only commits are not convergence

## Status

| What was just completed | What's next |
|---|---|
| fix landed on branch (e7559676); controls A–G green on candidate, A/B/F/G red on base; gh115 7/7; final Codex QA attested Approved (round 3, reviewed d9099687); qualifying ci-local.sh run recorded | PR to development open; merge + reconcile via /merge-cleanup; link PR from #976 and user-sage-backend#75 |

## Observed problem

`utils/py/relay_drive.py:1094-1108` decides `made_progress` from two signals: HEAD moved
(`get_head_commit()` before vs after the turn) or the `[x]` count in the relay file rose. Every
relay turn commits its own transcript: `relay-automation/relay-turn-lib.sh:1498` commits
`relay(<task>): <agent> turn`, and the driver's attestation path `relay_drive.py:643` commits
`relay-drive: attest ...` (approval publication only). So on a turn whose only tracked change is the
transcript committed in the same repository `get_head_commit()` samples, HEAD moves inside the
before/after window and the GH-115 extension is granted round after round until the hard ceiling
(`hard_cap = 2 * cap`, line 738). A turn that commits nothing (`relay-turn-lib.sh:1480-1495`) or
whose transcript lives in the archive repo (`:1502-1523`) does not trigger it; the defect is the
same-repo tracked-receipt case, which is the marathon layout. Consumer evidence: user-sage-backend#75, relay extended to cap 10 with no repair
commits, halted exit 4 `cap-progressing-extended`.

## Requirement

HEAD movement counts as progress only when at least one changed path between `head_before` and
`head_after` lies outside receipt paths. Receipt paths: `relay-system/`, `marathon-system/`,
`.tick/`, `.relay-scratch/`, `TESTS-RESULTS/` (directory prefixes, trailing slash kept), plus the
relay file's own path **relative to the same repository the diff is taken in**, resolved through the
existing `target_repo()` (`relay_drive.py:616-623`, the same root `get_head_commit()` uses). When the
transcript is outside that repo the exact-file exclusion is omitted; an archive basename never
excludes an unrelated target file. Evidence-only edits under `TESTS-RESULTS/` and brief-only edits
under `marathon-system/` are deliberately not progress. The `[x]` resolved-items arm is unchanged.

## Non-goals

- The dispatch-time observer / wake-up contract from user-sage-backend#75 (separate issue, Costly).
- Parsing free-prose "adjudication requested" text. The protocol already has the terminal handoff
  marker, `STATUS: Escalated` (`relay_drive.py:399`, `escalated_status`, handled at :756 and :1044);
  an agent that wants adjudication sets it. Not a driver change.
- The frozen Bash twin `relay-automation/relay-drive.sh` (GH-308): untouched.
- No new test suite, no new `validate.sh` registry entry (GH-831).

## Smallest viable bet

One helper in `relay_drive.py`, `commits_touch_non_receipt(head_before, head_after)`, that runs
`git diff --name-only <before>..<after>` in the same repo `get_head_commit()` resolves and returns
True when any path survives the receipt filter. Replace the `head_after != head_before` arm with it.
On git failure (empty before/after SHA, diff error) return False: no extension on unverifiable
evidence, matching the stalled default; the independent resolved-items arm still applies. Rejected alternative: filtering on commit *message* prefix
(`relay(`/`relay-drive:`) — a builder commit of real files can carry any message, and a receipt
commit could be renamed; paths are the ground truth.

## Implementation (ordered, verification inline)

1. `utils/py/relay_drive.py`: add `commits_touch_non_receipt(before, after)` beside
   `get_head_commit()`, reusing `target_repo()`; replace the `head_after != head_before` arm at
   line ~1097. Verify: `bash test/gh115-round-cap.sh` stays green. Note what it pins: Tests 2/3
   signal progress through `[x]` lines (`test/gh115-round-cap.sh:23-24`), so the suite does **not**
   pin the HEAD arm either way; the controls below do.
2. Manual controls, run in a disposable full clone against base `6d81df9f` (must fail) and the
   candidate commit (must pass), one standalone script under `$TMPDIR` that builds a fixture repo,
   seeds a tick token, dispatches a stub agent that **commits inside the dispatched turn** and keeps
   handing the token off, never approves, `--round-cap 2`, `STUB_PROGRESS=no`. Assertions: captured
   output non-empty, exit 4, reason, original turn count, and presence/absence of
   `bounded extension granted` and `Extension · System`.
   - A. receipt-only directory: only `relay-system/receipt.md` changes per turn → expect exit 4
     `cap-stalled`, no extension (base extends → control fails on base).
   - B. receipt-only exact file: the relay file at an arbitrary tracked location (`notes/thread.md`)
     is the only change → same expectation as A.
   - C. real-file positive: only `src/repair.py` changes per turn → expect `bounded extension
     granted` and `Extension · System` on the candidate (GH-115 HEAD arm preserved).
   - D. mixed: `relay-system/receipt.md` plus `src/repair.py` → same as C.
   - E. no-SHA: `RELAY_TARGET_ROOT` pointing at a non-git dir → helper returns False, exit 4
     `cap-stalled` (resolved-items arm untouched).
   Record commands, revisions, output and `provenance.jsonl` under
   `TESTS-RESULTS/2026-10-05+GH-976/`. No new suite, no `validate.sh` entry.
3. `test/gh115-round-cap.sh` unchanged (its pinned behaviour does not change).
4. CHANGELOG entry; link PR from #976 and user-sage-backend#75. Issue #976's
   `adjudication-requested` acceptance item is withdrawn in favour of the existing
   `STATUS: Escalated` handoff (`relay_drive.py:399`, `:756`, `:1044`), which either role may set.

## Rollback

Single-hunk revert of the oracle; no state, schema or contract change.

## Rating

`rated 80/75/50/85` — rationale in the 2026-10-05 intake commit (d051cdb8).

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh --auto",
  "fix_probes":    [ { "type": "grep_absent", "path": "utils/py/relay_drive.py", "pattern": "commits_touch_non_receipt" } ],
  "artifacts":     [ "utils/py/relay_drive.py", "CHANGELOG.md" ],
  "artifacts_new": [],
  "remediation":   { "source": "self#implementation", "criteria": "receipt-only commits do not extend the cap; real-file commits still do; gh115 suite green" },
  "lanes":         { "agy_safe": [], "orchestrator_only": [ "utils/py/relay_drive.py" ] }
}
```
