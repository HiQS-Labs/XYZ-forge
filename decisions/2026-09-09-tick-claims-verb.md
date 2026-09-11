---
status: Decided
date: 2026-09-09
reversibility: Cheap
revisit: "any second consumer of `tick claims`, or a change to fold() that adds a claim-like state other than `claimed`"
related: ["2026-06-18-epoch-fencing.md"]
decider: "@noelsaw1"
---

# `tick claims` — a read-only kernel verb for external auditors (GH-534 A.4)

**Decision:** Add `tick claims [--json]` to `bin/tick`. It prints every task whose folded status is
`claimed`, with agent, paths and epoch, and is built on the two exports `project()` already uses —
`readAllEvents(root)` and `fold(events)` — **minus the write**. It never touches `.tick/STATE.md` or
`.tick/rejected.jsonl`.

**Why a verb, not a file read.** `/merge-cleanup` needs to know whether a checkout is in use before
it tears the checkout down. The only prior answer was to parse `.tick/STATE.md`, which is wrong on
two counts: it is a **derived snapshot** (`project()` folds the log *then* writes it, so a stale or
absent file proves nothing about current claims), and the old parser matched `- (none)` while the
renderer emits `_(none)_`, so every empty section would have read as active. `tick next` is
per-agent and `tick info` is per-task; nothing enumerated all claims read-only. The fold is the
kernel's own truth, so the kernel exposes it.

**Two refusals the fold alone would not give:**
- `.tick/` absent → exit 3 `tick-dir-missing`. The auditor treats "no coordination root" as
  "nothing can be claimed here" on its own side; the verb does not guess.
- `.tick/` present but `.tick/events` missing or unreadable → exit 3 `events-dir-missing` /
  `events-unreadable`. `readAllEvents()` returns `[]` for a missing directory (`src/events.js`),
  and to an auditor `[]` reads as *no claims* — the opposite of the truth when the log cannot be
  read. Pinned by `TestA4TickClaims.test_xii_events_dir_missing_is_refused_not_empty`.

**Root pinning.** The caller passes `TICK_REPO_ROOT` explicitly (the audited checkout's git
common-dir parent, so a linked worktree is judged by its parent's log) and runs from a CWD outside
the checkout. The verb is read-only, so it is not in `MUTATING_GUARD_VERBS`; the pinning is the
caller's contract, tested in `test_vi_linked_worktree_uses_the_parent_coordination_root`.

**Rejected alternatives:**
- *Repair the STATE.md parser.* Still a snapshot; still writes nothing but still reads stale state.
- *Call `tick project` from the auditor.* Writes into the tree under audit — an audit that mutates
  its subject is not an audit, and it would dirty a clean checkout the moment it looked at it.
- *Import `src/project.js` from Python via a node one-liner.* Same fold, but an undocumented
  surface with no usage line, no exit-code contract and no test; a verb is the honest shape.

**Reversibility:** Cheap. Additive verb, no schema change, one consumer. Removing it breaks
`/merge-cleanup`'s session check (which then preserves everything, fail-closed) and nothing else.
