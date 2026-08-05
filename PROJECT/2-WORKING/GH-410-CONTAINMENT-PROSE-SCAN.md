---
gh_issue: 410
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/410
title: "GH-410 — the worktree containment check greps the reviewer's prose for the repo path, fails on wording, and discards a completed review"
status: "Active (2-WORKING) — verified independently 2026-08-05, all four reported claims hold and two are broader than reported. Fix in progress on gh-410-containment-observable."
created: 2026-08-05
updated: 2026-08-05
owner: noel
doc_type: fix
complexity: 3
risk: 3
effort: 3
phases: 3
ratings_provisional: true
related:
  - "#419 — this is a member of the class: a check that reports a containment verdict it cannot substantiate. Its negative-control forms are what this fix's evidence uses."
  - "#308 — Python is authoritative; all five Bash turn shims are FROZEN, so the fix lands in utils/py/** only."
  - "#178 B1 — added the prose scan. This narrows it rather than deleting the intent."
  - "#183 / #187 — the two prior false-positive patches (TICK_REPO_ROOT=, file-scheme URIs, and markdown link targets). Evidence the deny-list approach does not converge."
  - "#162 — added the retry preamble that seeds the trigger string."
non_goals:
  - "Weakening real containment. rtl.worktree_end()'s off-lane filesystem diff stays exactly as it is and remains the verdict; this fix removes an unsound SECOND check layered on top of it."
  - "Adding the prose scan to the other four shims. They are not under-contained — see the Correction section; propagating an unsound check to reach uniformity would be the wrong direction."
  - "Editing the frozen Bash twins (GH-308). agy-turn.sh keeps its historical behaviour and does not execute by default."
  - "Building an openat/ptrace read-tracer. Not portable under macOS SIP without entitlements, and out of proportion to the property being protected."
  - "Removing the signal entirely. A transcript naming the real root is still worth surfacing to an operator — as an advisory, never as a verdict."
goal: >
  Stop issuing a containment verdict the harness cannot substantiate. Writes outside the worktree
  are observable and already enforced identically by all five shims; reads are not observable, and
  substring-matching an agent's prose answers a different question — did the model MENTION a path —
  which diverges from access in both directions. Keep the observable check as the verdict, demote
  the unobservable one to an advisory, and stop discarding completed reviews on its say-so.
---

# GH-410 · a verdict the harness cannot substantiate

## Status
| What was just completed | What's next |
|---|---|
| Independent verification of all four reported claims against `faf50e0`. Two are broader than reported; one of the reporter's three recommendations is answered by evidence rather than implemented. Branch cut. | Phases 1–3, then `/relay-xyz` QA and a PR into `development`. |

## Verification (done before any code)

Re-derived from the tree, not taken on the report's word. The second reproduction cites
`marathon_drive.py:188–191` from a vendored `b937775a`; on `faf50e0` the same code is at
**403–407** — line drift between the consumer's pin and the intake repo, not a discrepancy.

| Claim | Verdict | Evidence at `faf50e0` |
|---|---|---|
| The verdict is a prose substring test | **TRUE** | `utils/py/agy-turn.py:223` — `if root in line` |
| The deny-list has accreted | **TRUE** | four exempt shapes: `[trace] ` lines, `TICK_REPO_ROOT=`, file-scheme URIs, and markdown link targets — three separate prior patches (#183, #187) |
| The harness renders absolute paths into the retry relay | **TRUE** | `marathon_drive.py:403-407` (`{mantra_file}`, `{phase_dir_}/ESCALATION.md`), gated on `prior >= 1`; plus `Use this exact tick binary … {tick_cli}` at `:1199` and `:1217` |
| Only the agy shim carries the scan | **TRUE, and broader** | `isolation breach` appears **2× in agy-turn (.py/.sh) and 0× in codex, claude, aider, and pi** — not just codex |
| The retry path raises its own hazard | **TRUE** | the preamble is rendered *only* when `prior >= 1`, so failing once hands the next attempt more copies of the trigger |

## Correction to the report — item 3's premise does not hold

> *"Either codex is under-contained or agy is over-contained — picking a builder silently picks a
> safety model."*

**Neither.** `rtl.worktree_end()` — the real filesystem off-lane diff — is called by **all five
shims**, and every one exits 6 on it:

```
agy-turn.py:206   codex-turn.py:107   claude-turn.py:135   aider-turn.py:187   pi-turn.py:137
```

So containment **is** uniform, and it is enforced by the check that observes the filesystem. What
agy alone carries is an *additional, unsound* prose scan on top. The shims do not disagree about
containment; they disagree about an unsound heuristic.

This inverts item 3's remedy. Uniformity is reached by **removing the unsound layer**, not by
propagating it to four more shims. Choosing a builder does not currently pick a safety model — it
picks whether you are exposed to a false positive.

## Why the prose scan cannot be repaired

The property worth enforcing is *did this turn read or write outside its worktree*.

- **Writes are observable** and already observed — `rtl.worktree_end()` diffs the worktree's own git
  state. That is the verdict, and it stays.
- **Reads are not observable** here. Catching them needs `openat`-level tracing, which is not
  portable under macOS SIP without entitlements, and is out of proportion to the risk.

A transcript substring scan cannot distinguish "the agent accessed the real tree" from "the agent
typed a path." It fails in both directions: a reviewer that quietly touched the real root without
naming it **passes**, and one that names it in a finding **fails**. The reporter's quantified case
is decisive — `vb4` had **10** repo-root mentions and was Approved; `vb5` had **9** and failed three
consecutive times. Same builder, same isolation settings, same run.

Three exemption patches have already been spent on it and a fourth shape (the retry preamble) is
now in hand. That is a deny-list that does not converge.

**So the answer to "replace the deny-list, don't extend it" is not to build a better scanner — it is
that the observable half is already observed, and the unobservable half should stop being asserted.**

## The asymmetric cost

A builder failing containment discards work that can be regenerated. A reviewer failing it discards
a **verdict** — and in the observed case the review had already completed and written
`STATUS: Approved` to the relay file. The harness threw away a review it was holding, escalated the
phase, and halted phases 5–10.

A heuristic that destroys completed work must fail toward keeping it.

### Footnote, earned the hard way

The first draft of this document failed `pdda-check-hardcoded-paths` — twice — because it wrote the
literal `file` scheme prefix while *naming an exemption pattern*. A doc about a substring scan that
cannot tell a mention from an access was itself flagged by a substring scan that cannot tell a
mention from an access. The checker was not wrong to look; it simply has the same blind spot, one
layer up. Recorded because it is the cheapest available demonstration of the thesis.

## Acceptance

*Copied verbatim from [issue #410](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/410)
(`## Suggested acceptance criteria`), fetched 2026-08-05. Deviations, if any, are recorded below this block.*

- [ ] A reviewer that merely mentions the repo path in its findings does not fail containment.
- [ ] The containment verdict reflects actual access outside the worktree.
- [ ] A completed review is not discarded by a heuristic containment failure.
- [ ] A regression test pins a review whose text contains the repo root but which made no out-of-worktree access, and asserts it passes.

## Acceptance — deviations from the issue

None. Every criterion is carried verbatim.

Criterion 2 is satisfied by *narrowing what claims to be a verdict*: after this change the containment
verdict is `rtl.worktree_end()`'s filesystem diff alone, which reflects actual out-of-worktree writes.
The prose signal stops being a verdict rather than becoming a better one — reads are not observable
here, and the honest response to an unobservable property is to stop asserting it, not to keep
asserting it badly. That is a reading of the criterion, not a departure from it.

## Phases

| Phase | Deliverable | Artifacts | cx/risk/eff |
|---|---|---|---|
| 1 | Demote the prose scan. `rtl.py` gains a shared advisory helper; `agy-turn.py` records the finding on the transcript and stderr and **does not** fail the turn or discard the review. `worktree_end` remains the verdict. | `utils/py/rtl.py`, `utils/py/agy-turn.py` | 2/3/2 |
| 2 | Stop seeding where it is free. The retry preamble names `DEBUG-MANTRA.md` / `ESCALATION.md` by filename with the directory given once, instead of repeating absolute paths per line. The tick line keeps its absolute path — "run it from any directory" requires it — and that is now harmless because the scan no longer fails turns. | `utils/py/marathon_drive.py` | 1/1/1 |
| 3 | The regression test, with a negative control. | `test/gh410-containment-advisory.sh`, `validate.sh` | 2/1/2 |

## Litmus tests

- **The pass-direction case is the point.** A test that only asserts "mentioning the root no longer
  fails" would also pass if containment were deleted outright. The suite must equally assert that a
  genuine off-lane **write** still fails the turn with exit 6 — otherwise it cannot tell this fix
  from a regression, which is the #419 shape this repo has eight instances of.
- **The advisory must still be visible.** Demoting it to silence would trade a false positive for a
  blind spot. The note must reach both the transcript and stderr.
