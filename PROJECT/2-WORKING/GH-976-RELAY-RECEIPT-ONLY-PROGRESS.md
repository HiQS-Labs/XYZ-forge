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
| intake captured, parked, rated 80/75/50/85; recon done; plan drafted | Codex plan QA relay, then implement step 1, witness red control on existing suite |

## Observed problem

`utils/py/relay_drive.py:1094-1108` decides `made_progress` from two signals: HEAD moved
(`get_head_commit()` before vs after the turn) or the `[x]` count in the relay file rose. Every
relay turn commits its own transcript: `relay-automation/relay-turn-lib.sh:1498` commits
`relay(<task>): <agent> turn`, and the driver's attestation path `relay_drive.py:643` commits
`relay-drive: attest ...`. So HEAD moves on a handoff that changed nothing but the relay file, and
the GH-115 extension is granted round after round until the hard ceiling (`hard_cap = 2 * cap`,
line 738). Consumer evidence: user-sage-backend#75, relay extended to cap 10 with no repair
commits, halted exit 4 `cap-progressing-extended`.

## Requirement

HEAD movement counts as progress only when at least one changed path between `head_before` and
`head_after` lies outside receipt paths. Receipt paths: `relay-system/`, `marathon-system/`,
`.tick/`, `.relay-scratch/`, `TESTS-RESULTS/`, and the relay file itself (it may live elsewhere,
e.g. `relay.md` at the target root in the existing suite). The `[x]` resolved-items signal is unchanged.

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
On git failure (no before SHA, diff error) return False: no extension on unverifiable evidence,
matching the stalled default. Rejected alternative: filtering on commit *message* prefix
(`relay(`/`relay-drive:`) — a builder commit of real files can carry any message, and a receipt
commit could be renamed; paths are the ground truth.

## Implementation (ordered, verification inline)

1. `utils/py/relay_drive.py`: add the helper next to `get_head_commit()`; use it at line ~1097.
   Verify: `bash test/gh115-round-cap.sh` stays green (its progressing stub appends `[x]` to the
   relay file, so it exercises the untouched arm; Test 1 stalled still `cap-stalled`).
2. Red control, witnessed on the existing suite without adding a registry entry: run Test 2's stub
   variant where the only change per round is a commit to `relay.md` (receipt path) with
   `STUB_PROGRESS=no`. Before the fix the attest commit already moves HEAD and the old code never
   extended on it in the suite — so the red control is a manual check recorded under
   `TESTS-RESULTS/2026-10-05+GH-976/`: a scripted round that commits only `relay-system/x.md`
   between turns must extend on the pre-fix code and must not on the post-fix code, with
   `provenance.jsonl`.
3. `test/gh115-round-cap.sh` is edited only if its pinned behaviour changes (it does not); leave it.
4. CHANGELOG entry; link PR from #976 and user-sage-backend#75.

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
