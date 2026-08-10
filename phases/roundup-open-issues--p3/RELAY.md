# Marathon Phase p3
STATUS: Open
NEXT: codex

<!-- marathon-drive: task=MARATHON-P3-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# p3 — GH-26: RELEASES.md fixture error + Codename absorbed by preceding block

Release 1.4.270 "Roundup" · issue [#26] · depends on p2

Two defects in one file and one check. Fixing them together is what finally gets
`pdda.sh releases` to `errors=0`.

## Defect 1 — the `<!--test-->` fixture errors on every run

`RELEASES.md:9-17` holds a leftover fixture whose `Release:` value is empty:

```
ERROR [pdda-check-releases] RELEASES.md:11 a 'Release:' block near line 11 has no version
```

The check is **correct** — this is a true positive, and the empty-`Release:` guard must stay. The
question is only the fixture.

Preferred fix: **delete the fixture block.** It is titled `Codename: "Test"` / `Description: FTest`
and contains two typos (`Shakdedown`, `reviwed`); it is scratch content, not a spec.

If instead a fenced-fixture concept is wanted, have `pdda-check-releases` skip regions between
`<!--test-->` markers — but then add a test proving a *malformed real* block outside such a region
still errors. Do not weaken the guard itself.

## Defect 2 — `Codename:` is absorbed by the preceding block

The parser starts a new block at each `Release:` line, so any field appearing **before** a block's
own `Release:` is attributed to the **previous** block. `RELEASES.md` has:

```text
Codename: "Silverlining"
Release: TBD
```

so `"Silverlining"` attaches to the fixture block above it. Observed live: inserting a new block
above it made that block render as `1.5.0 ("Silverlining")`. It was worked around in #23 by placing
the new block last — the trap is still there, and it is **silent**.

Fix both halves:

- normalise `RELEASES.md` so every block leads with `Release:`
- **and** have the check `warn` when a recognised field appears before the first `Release:` of a
  block, so the trap reports itself instead of relying on authoring discipline

The second half is the durable one. Without it the file drifts back the first time someone adds a
block by copy-paste.

## Constraint

`pdda.sh` / `pdda-lib.sh` are synced in from a canonical PDDA repo (`utils/pdda/PDDA-INSTALL.md`,
`PDDA-SOURCE.md`). Changing them here creates a **diverged target** on the next
`pdda-sync.sh push`. Note in the turn that this change needs pushing upstream, or it will be
overwritten. Do not silently fork the vendored copy.

## Done when

- `bash utils/pdda/pdda.sh releases` reports **errors=0, warns=0**
- `bash utils/pdda/pdda.sh releases-current` still renders both `1.5.0 ("Ledger")` and
  `1.4.270 ("Roundup")` with correct codenames and Iterations bands
- a test (or a documented manual check with output) shows the new warn fires on a field-before-
  `Release:` block, and does **not** fire on a well-formed one
- `pdda.sh run` shows no new findings
- the upstream-sync consequence is stated in the turn

## Out of scope

Any other PDDA check. The 3 pre-existing governance dead-reference warnings in `ROUTER.md` /
`AGENTS.md` are **not** part of this issue — leave them.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): RELEASES.md,utils/pdda/pdda.sh,utils/pdda/pdda-lib.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-P3-TURN --agent codex --paths "phases/roundup-open-issues--p3/RELAY.md,RELEASES.md,utils/pdda/pdda.sh,utils/pdda/pdda-lib.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-P3-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-P3-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/roundup-open-issues--p3/RELAY.md and RELEASES.md,utils/pdda/pdda.sh,utils/pdda/pdda-lib.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: RELEASES.md,utils/pdda/pdda.sh,utils/pdda/pdda-lib.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-P3-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-P3-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/roundup-open-issues--p3/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.
