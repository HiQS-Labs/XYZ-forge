# Marathon Phase daybreak-wave-1-2026-08-20
STATUS: Open
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-DAYBREAK-WAVE-1-2026-08-20-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Daybreak · Wave 1 — the three offline lenses

Release **0.7.2 "Daybreak"** · marathon `mar-01M0EC2ZXJCCJ88KASQPDBTBJ9` · tracking
[#77](https://github.com/HiQS-Labs/XYZ-forge/issues/77).

Build lenses **2, 3, 7** in `skills/standup/collect.sh`. These three are deliberately first: they are
pure-local reads with no network and no `gh`, so they are the cheapest possible proof that the
harness holds before the two `gh` lenses arrive in wave 3.

## Work units

| Issue | Lens | Bounded read |
|---|---|---|
| [#79](https://github.com/HiQS-Labs/XYZ-forge/issues/79) | 2 · working tree | `git status --porcelain`, excluding **untracked** paths under `PARKED/` |
| [#80](https://github.com/HiQS-Labs/XYZ-forge/issues/80) | 3 · branch | `git rev-list --left-right --count @{upstream}...HEAD`, trunk fallback on exit 128 |
| [#81](https://github.com/HiQS-Labs/XYZ-forge/issues/81) | 7 · ROADMAP ledger | `python3 utils/py/releases_app.py roadmap sync --dry-run` |

## The transform — identical for all three

1. Implement the bounded read in `skills/standup/collect.sh`, honouring `--fixture <dir>`.
2. Emit candidates carrying all six required fields — `key`, `what`, `evidence_type`,
   `evidence_payload`, `staleness`, `close` (plus `close_kind`, and `check` when parkable).
   **A lens that cannot supply all six does not emit the candidate** — it sets
   `status: degraded` with its `D` id. Silence is the one unacceptable outcome.
3. Add `skills/standup/fixtures/lens-<n>/`.
4. Add two assertions to `test/gh77-standup-triage.sh`: the candidate classifies to its expected
   tier, and the lens degrades loudly with its `D` id when the read is unavailable.

## Output contract `collect.sh` must satisfy

```json
{"repo": {"branch": "<name>"},
 "lenses": {"2": {"status": "ok|degraded", "degraded_id": "D<n>|null", "candidates": [ … ]}}}
```

`triage.py --lenses <file> --dry-run` is the consumer. Read it — it is the authority on field names
and on what each lens's `live_state` payload must contain, because suppression hashes that payload.

## Pass condition — machine-checkable, per unit

```
skills/standup/collect.sh --fixture skills/standup/fixtures/lens-<n>   # valid JSON
python3 skills/standup/triage.py --lenses <that output> --dry-run      # no D5, exit 0
bash test/gh77-standup-triage.sh                                       # green
```

## Three things that are already settled — do not relitigate them

- **Lens 2 excludes only *untracked* paths under `PARKED/`.** A blanket exclusion was tried and
  rejected in review: it hid an operator's uncommitted edit to a tracked park file forever. The
  self-feed only needs the untracked half, because a modified tracked file closes with
  `git add` + commit and cannot loop.
- **Lens 3 never claims "unpushed" without an upstream.** Divergence from the trunk does not
  establish push state. With no upstream, carry `upstream-state: no-upstream`, take **unknown**
  staleness, and make the close an `inspect:` action — never a bare `git push` at an unresolved
  remote.
- **`close` is never executed.** Only a park record's read-only `check` probe runs during collection.

## Definition of done for this phase

All three lenses implemented, three fixture directories, six new assertions, and
`bash validate.sh --subsystem releases` green. `triage.py` is **not** modified by this phase — if a
lens seems to need a change there, that is a finding to report, not an edit to make.

## What this phase is actually testing

Three lanes editing **one shared `collect.sh` and one shared suite**. That collision surface is why
this is a marathon rather than a task. A lane clobbering another's edit, a stale worktree, an
unexpected driver-lock interaction — those are the deliverable, per `AGENTS.md` → Repo-specific
rails, rule 4. **Report what broke; do not smooth it.** A clean run that teaches nothing is the
weaker result.


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): skills/standup/collect.sh,skills/standup/fixtures,test/gh77-standup-triage.sh
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge/bin/tick
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge/bin/tick claim MARATHON-DAYBREAK-WAVE-1-2026-08-20-TURN --agent agy --paths "marathon-system/daybreak-wave-1-2026-08-20/RELAY.md,skills/standup/collect.sh,skills/standup/fixtures,test/gh77-standup-triage.sh"
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge/bin/tick ping MARATHON-DAYBREAK-WAVE-1-2026-08-20-TURN --agent agy
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge/bin/tick release MARATHON-DAYBREAK-WAVE-1-2026-08-20-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/daybreak-wave-1-2026-08-20/RELAY.md and skills/standup/collect.sh,skills/standup/fixtures,test/gh77-standup-triage.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/standup/collect.sh,skills/standup/fixtures,test/gh77-standup-triage.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge/bin/tick release MARATHON-DAYBREAK-WAVE-1-2026-08-20-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge/bin/tick done MARATHON-DAYBREAK-WAVE-1-2026-08-20-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/XYZ-forge/bin/tick
   Edit ONLY marathon-system/daybreak-wave-1-2026-08-20/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to agy —
   agy, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.

### Round 1 · Builder · agy
Implemented Lenses 2, 3, and 7 in `skills/standup/collect.sh`.
- **Lens 2:** Reads `git status --porcelain` and ignores untracked paths under `PARKED/`. Corresponds to Tier 1 corruption when targeting `releases.db`.
- **Lens 3:** Emits branch divergence utilizing `git rev-list --left-right --count @{upstream}...HEAD`, safely fallbacking to `main` with `upstream-state: no-upstream` and `inspect` command for unpushed changes when no upstream is tracked.
- **Lens 7:** Syncs with `ROADMAP.md` via `python3 utils/py/releases_app.py roadmap sync --dry-run` and classifies items to Tier 5.
- Added mock file responses to `skills/standup/fixtures/lens-2`, `skills/standup/fixtures/lens-3`, and `skills/standup/fixtures/lens-7` directories.
- Updated `test/gh77-standup-triage.sh` to include 6 new assertions validating each of the lenses' expected tier and their ability to degrade loudly (D4, D5) when readings are unavailable.
