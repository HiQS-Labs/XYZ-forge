# Marathon Phase p4-drift-filter
STATUS: Open
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-P4-DRIFT-FILTER-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

---
title: "p4 brief — drift-brief path-existence filter (#374)"
status: "Brief (input to the 2026-09-01 xyz-harness-quickwins marathon — not a tracked plan)"
created: 2026-09-01
updated: 2026-09-01
owner: Noel Saw
goal: >
  Stop prepending stale cross-repo drift-registry entries into builder prompts.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/374
---

# p4 — drift filter

## Status

| What was just completed | What's next |
|---|---|
| Phase brief authored. | Marathon phase execution. |

Read the capture doc first:
`PROJECT/2-WORKING/GH-374-DRIFT-REGISTRY-CROSS-REPO-NOISE.md`.

`rtl_drift_brief` (in `relay-automation/relay-turn-lib.sh`, mirrored in
`utils/py/rtl.py`) prepends unread dependency-drift heads-ups into the builder's prompt.
Observed 2026-09-01 in an LTVera-Pandas run: repeated
`dependency.drift — agy changed src/project.js (0 lines)` for a file that does not exist
in the driven repo — leftovers from another repo's registry.

Fix: at read time, keep only entries whose path exists in the driven repo
(`git cat-file -e HEAD:<path>` or a filesystem check against the turn root — pick one,
document it in a comment). Namespacing the registry per repo is the deeper fix; the
path-existence filter is the small one this phase ships — if the registry format makes
namespacing trivial, do that instead and say so in the relay block.

Test: `test/gh374-drift-path-filter.sh` — seed a fixture registry with one entry whose
path exists and one whose path does not; assert the brief includes only the former
(`test/relay-dep-drift.sh` is the existing drift test to extend or sit beside).

## Constraints

- Leave a `GH-374` marker in relay-turn-lib.sh at the change site (the preflight probe
  keys on it). Bash/Python lanes stay behaviorally identical.
- Gate: `bash validate.sh`. In-turn, run only the new test plus files you edit.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): relay-automation/relay-turn-lib.sh,utils/py/rtl.py,test/gh374-drift-path-filter.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick
   - /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick claim MARATHON-P4-DRIFT-FILTER-TURN --agent codex --paths "marathon-system/2026-09-01-xyz-harness-quickwins--p4-drift-filter/RELAY.md,relay-automation/relay-turn-lib.sh,utils/py/rtl.py,test/gh374-drift-path-filter.sh"
   - /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick ping MARATHON-P4-DRIFT-FILTER-TURN --agent codex
   - /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick release MARATHON-P4-DRIFT-FILTER-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/2026-09-01-xyz-harness-quickwins--p4-drift-filter/RELAY.md and relay-automation/relay-turn-lib.sh,utils/py/rtl.py,test/gh374-drift-path-filter.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/relay-turn-lib.sh,utils/py/rtl.py,test/gh374-drift-path-filter.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick release MARATHON-P4-DRIFT-FILTER-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick done MARATHON-P4-DRIFT-FILTER-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick
   Edit ONLY marathon-system/2026-09-01-xyz-harness-quickwins--p4-drift-filter/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.

### Round 1 · Builder · codex

Implemented the GH-374 read-time filter in `rtl_drift_brief`: it advances the existing watermark for
all scanned events but displays only surfaces present in the driven repository's committed `HEAD`.
The Python bridge now supplies its driven-root explicitly, preserving the same behavior in both lanes.
Added `test/gh374-drift-path-filter.sh`, which seeds present and stale registry entries and verifies
both Bash and Python only surface the present path.
