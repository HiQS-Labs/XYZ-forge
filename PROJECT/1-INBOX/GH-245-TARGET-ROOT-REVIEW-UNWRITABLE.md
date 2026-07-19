---
title: --target-root review turn cannot report, and relay-drive misclassifies the outcome in both directions
status: Proposed (1-INBOX — not yet active)
created: 2026-07-18
owner: noelsaw1
gh_issue: 245
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/245
doc_type: bugfix
complexity: 2
risk: 4
effort: 2
phases: 1
ratings_provisional: true
reported_from: rebalance-OS
harness_commit: fb9ed4e
non_goals:
  - Redesigning how --target-root resolves paths generally; the fix is a startup
    validation plus an evidence-based classifier, not a path-resolution rework.
  - Changing the ALLOW_PATHS="" review-turn convention, which is correct as documented.
related:
  - "#236 — a 2-second exit labelled turn-timeout-or-hang (same misclassification family)"
goal: >
  Fixed means two things are observably true. First, a review turn driven with
  --target-root either appends its findings to the relay file, or the driver refuses
  at startup with a clear error — never spends a full turn and discards the result.
  Second, --review-once classifies on evidence of a turn (relay-file diff, NEXT/STATUS
  change) rather than token movement alone, so neither an empty turn nor a complete
  review can be scored as its opposite.
---

# GH-245 — `--target-root` review turn cannot report; outcome misclassified both ways

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Symptom

A cross-repo review turn (`relay-drive.sh --target-root <other-repo> --review-once`) is
structurally unable to produce a review: the relay file it must append to lives outside the
writable root. The driver then scores the empty result as a successful review — and, in a
second run, scored a complete review as a stall.

## Environment

- **Observed from:** `rebalance-OS` (centralized harness for the failing run; vendored `.xyz/`
  for the successful workaround run)
- **Harness commit:** `fb9ed4e`
- **Worker/CLI:** codex
- **Sandbox:** off at the time of failure

## Reproduction

Every time — a deterministic path-containment condition, not a race.

1. Have a relay thread in the harness repo with an embedded `▶ TAKE YOUR TURN` block.
2. Drive a review-only turn whose target root is a *different* repo:

```bash
CODEX_AGENT=codex ALLOW_PATHS="" RELAY_PEER=claude-a \
relay-automation/relay-drive.sh \
  --relay-file relay-system/<date>/<slug>.md \
  --relay-task RELAY-<task> \
  --agent-cmd relay-automation/codex-turn.sh \
  --target-root /path/to/other/repo \
  --review-once
```

**Expected:** the reviewer appends graded findings to the relay file and hands back; or, if the
layout makes that impossible, the driver fails fast at startup rather than after a full-cost turn.

**Observed:** patch rejected, zero findings, exit 0 from the shim / 5 from the driver, ~88k tokens
spent.

**Frequency:** every time.

### Defect 1 — the reviewer has nowhere to write

`--target-root` bases the isolated worktree on the **target** repo, but `--relay-file` resolves
against the **harness** repo. With `ALLOW_PATHS=""` — the setting SKILL.md documents for a review
turn — the relay file is the only writable path, and it isn't in the worktree.

```text
ERROR codex_core::tools::router: error=patch rejected: writing outside of the project;
  rejected by user approval settings
codex: The required relay file is outside the writable workspace; the mandated
  file-only append was rejected by the filesystem policy. I'll hand the token
  back cleanly to avoid blocking the relay.
```

The reviewer had completed the full review before hitting this; only a one-sentence summary
survived in the transcript. The `relay-xyz` SKILL.md section *"Drive a full relay/build that lands
in a DIFFERENT repo (`--target-root`)"* presents this as the normal case, so the documented happy
path cannot report findings.

### Defect 2 — outcome classification is unreliable in both directions

Two runs, same relay, ~40 minutes apart, both misreported.

**Run A — empty turn scored as a successful review:**

```text
codex-turn: codex turn produced no tracked changes (token-only move?)
relay-drive: review-once — reviewer completed a turn (STATUS: Open, token open:claude-a);
  non-approval handback, not a stall
```

Exit 5 ("changes requested"), but the `## Log` was empty and `NEXT:` unflipped — and the shim had
already printed that there were no tracked changes.

**Run B — a complete review scored as a stall.** After working around defect 1 (vendoring the
harness into the target repo so relay file, harness and source share one writable root, then
dropping `--target-root`):

```text
relay-drive: review-once — reviewer took no action (STATUS unchanged: Open,
  token still open:codex) — genuine stall
```

That turn produced a full six-finding graded review (1 Blocker, 5 Shoulds, 1 Pass,
`Verdict: Changes requested`) and flipped `NEXT:` to Producer. Codex simply left the token claimed
rather than releasing it.

The classifier reads **token state only**. In run A the token moved and the file didn't; in run B
the file moved and the token didn't. Both times it reported the opposite of what happened, while
the distinguishing evidence was present and unused.

## Impact

Not blocking. Workaround is `xyz-vendor.sh <target-repo>` so harness, relay file and source share
one writable root, then drop `--target-root` — which also gives the lane its own driver lock.

But the failure is silent and expensive (~88k tokens for a discarded review), and defect 2 is the
amplifier: an unattended multi-round loop advances on a review that never happened, while a real
review can be discarded as a stall. Defect 1 costs a turn; defect 2 is what makes it hard to notice.

## Phase 0 — Diagnose & scope

> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist
- [ ] Reproduce both defects in the intake repo (not just from `rebalance-OS`)
- [ ] Locate where `--relay-file` is resolved vs. where the worktree root is set under
      `--target-root`; name the concrete write-set in `relay-automation/`
- [ ] Decide fix vs. guard-and-document for defect 1 — a startup validation that refuses the
      combination may be better than making the relay file reachable, since the vendoring
      workaround is already the documented path to per-repo relays
- [ ] For defect 2, enumerate what evidence the driver already has at classification time
      (relay-file diff, `NEXT:`/`STATUS:` delta, the shim's own no-tracked-changes signal)
- [ ] Check whether `#236` shares a root cause and should be fixed in the same pass
- [ ] Set/correct the triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [ ] The repro is confirmed from the report, not assumed
- [ ] Regression tests cover both failure paths before the fix lands: an empty turn must not
      score 5, and a relay-file-only turn (token left claimed) must not score 3
- [ ] The fix composes with the existing harness rather than adding a parallel classification path
