# Marathon Phase daybreak-wave-2-2026-08-20
STATUS: Open
NEXT: agy (Builder)

<!-- marathon-drive: task=MARATHON-DAYBREAK-WAVE-2-2026-08-20-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Daybreak · Wave 2 — session transcript, RELEASES CLI, PARKED (still offline)

Release **0.7.2 "Daybreak"** · marathon `mar-01M0EC2ZXJCCJ88KASQPDBTBJ9` · tracking
[#77](https://github.com/HiQS-Suite/XYZ-forge/issues/77).

Build lenses **1, 6, 8** in `skills/standup/collect.sh`. Wave 1 (lenses 2, 3, 7) is already landed
and green — `test/gh77-standup-triage.sh` runs 92/0 on `development`. These three complete the
offline set before the two `gh` lenses arrive in wave 3; none of them touches the network or `gh`.

## Work units

| Issue | Lens | Bounded read |
|---|---|---|
| [#82](https://github.com/HiQS-Suite/XYZ-forge/issues/82) | 1 · conversation | this session's transcript — an action the agent said it would take, or a finding it raised, neither completed nor parked |
| [#83](https://github.com/HiQS-Suite/XYZ-forge/issues/83) | 6 · RELEASES ledger | `$R check`, `$R next`, then `$R list --status draft` + `--status active` to enumerate, then `$R show --version <v>` per enumerated release |
| [#84](https://github.com/HiQS-Suite/XYZ-forge/issues/84) | 8 · PARKED | read `PARKED/*.md` — a parked record whose mandatory `check` field (a read-only probe, never the `close` command) reports the work is done |

## Contract (unchanged from wave 1)

`collect.sh --fixture <dir>` must emit one JSON document:

```json
{"repo": {"branch": "<name>"},
 "lenses": {"6": {"status": "ok|degraded", "degraded_id": "D<n>|null", "candidates": [ … ]}}}
```

`triage.py --lenses <file> --dry-run` is the consumer. Read it — it is the authority on field names
and on what each lens's `live_state` payload must contain, because suppression hashes that payload.

## Pass condition — machine-checkable, per unit

```
skills/standup/collect.sh --fixture skills/standup/fixtures/lens-<n>   # valid JSON
python3 skills/standup/triage.py --lenses <that output> --dry-run      # no D5, exit 0
bash test/gh77-standup-triage.sh                                       # green
```

## Things that are already settled — do not relitigate them

- **Lens 6 classifies corruption from BOTH emission shapes**, `FAIL: rule=` and `warn: rule=` —
  matching only `warn:` made the founding incident class produce no candidate at all. The
  corruption rule set routes to tier 1; an `active` release past target is the non-corruption row.
- **Lens 8 runs only the park record's read-only `check` probe.** `close` is never executed during
  collection — closing interfaces are rendered for the operator, not run.
- **Lens 1 evidence is `quote:<span>`** — the normalized quoted span, identical to the key's input,
  staleness age 0. No transcript enumeration beyond this session.
- **`triage.py` is NOT modified by this phase** — if a lens seems to need a change there, that is a
  finding to report, not an edit to make.

## Definition of done for this phase

All three lenses implemented, three fixture directories under `skills/standup/fixtures/lens-<n>/`
(plus degradation fixtures matching the wave-1 pattern), each lens degrades loudly with its `D<n>`
id when its read is unavailable, new assertions in `test/gh77-standup-triage.sh`, and
`bash validate.sh --subsystem releases` green.

## Working rules for the BUILDER — wave 1 escalated once; these are its lessons

- **`skills/standup/fixtures/` is a DIRECTORY lane** — spelled with the trailing slash, so the whole
  tree beneath it is yours this turn. Wave 1's first fire spelled it without one, which was
  unmatchable by construction and reverted the fixtures as off-lane (GH-90, fixed in `a350b2d`).
- **Do not leave scratch files in the tree.** Probe files, scratch scripts, and one-off outputs are
  off-lane no matter how harmless, and a single stray path at the repo root fails the whole turn.
  Use `$TMPDIR`.
- **Off-lane edits are reverted by the harness.** A `### Side Finding` block in the relay file is
  the only channel that survives — path / symptom / suspected_cause / probe.

## What this phase is actually testing

Three lanes editing **one shared `collect.sh` and one shared suite**. That collision surface is why
this is a marathon rather than a task. A lane clobbering another's edit, a stale worktree, an
unexpected driver-lock interaction — those are the deliverable, per `AGENTS.md` → Repo-specific
rails, rule 4. **Report what broke; do not smooth it.** A clean run that teaches nothing is the
weaker result.


## Debug mantra (auto-triggered — 4 prior attempt(s) on this phase did not reach Approved)

Before trying again, read `relay-automation/DEBUG-MANTRA.md` (relative to the harness root) and follow its four-step discipline: reproduce reliably, know the fail path, question the hypothesis, treat this round as a breadcrumb for the next one.
Last recorded reason (`marathon-system/daybreak-wave-2-2026-08-20/ESCALATION.md`): `cap-or-close-mismatch`. Read it before re-guessing.

---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): skills/standup/collect.sh,skills/standup/fixtures/,test/gh77-standup-triage.sh
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge/bin/tick
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge/bin/tick claim MARATHON-DAYBREAK-WAVE-2-2026-08-20-TURN --agent agy --paths "marathon-system/daybreak-wave-2-2026-08-20/RELAY.md,skills/standup/collect.sh,skills/standup/fixtures/,test/gh77-standup-triage.sh"
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge/bin/tick ping MARATHON-DAYBREAK-WAVE-2-2026-08-20-TURN --agent agy
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge/bin/tick release MARATHON-DAYBREAK-WAVE-2-2026-08-20-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/daybreak-wave-2-2026-08-20/RELAY.md and skills/standup/collect.sh,skills/standup/fixtures/,test/gh77-standup-triage.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/standup/collect.sh,skills/standup/fixtures/,test/gh77-standup-triage.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge/bin/tick release MARATHON-DAYBREAK-WAVE-2-2026-08-20-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge/bin/tick done MARATHON-DAYBREAK-WAVE-2-2026-08-20-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/XYZ-forge/bin/tick
   Edit ONLY marathon-system/daybreak-wave-2-2026-08-20/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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
