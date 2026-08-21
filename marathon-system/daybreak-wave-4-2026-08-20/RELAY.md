# Marathon Phase daybreak-wave-4-2026-08-20
STATUS: Open
NEXT: agy (Builder)

<!-- marathon-drive: task=MARATHON-DAYBREAK-WAVE-4-2026-08-20-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Daybreak · Wave 4 — End-to-end Wiring, All-Degraded Fixture & Subsystem Registration

Release **0.7.2 "Daybreak"** · marathon `mar-01M0EC2ZXJCCJ88KASQPDBTBJ9` · tracking
[#77](https://github.com/HiQS-Suite/XYZ-forge/issues/77) ([#87](https://github.com/HiQS-Suite/XYZ-forge/issues/87)).

Complete the final integration of the `/standup` toolchain:
1. End-to-end `skills/standup/collect.sh` execution combining all 8 lenses (1 through 8).
2. Hermetic `skills/standup/fixtures/all-degraded/` fixture triggering all degradation paths simultaneously.
3. Verify `skills/standup/install.sh --check` contract.
4. Register `standup` subsystem or mapping in `utils/ci-route.sh`.
5. Comprehensive test coverage in `test/gh77-standup-triage.sh` proving all 8 lenses run together cleanly and all exit criteria for Release 0.7.2 Daybreak are satisfied.

## Work units

| Issue | Unit | Deliverables |
|---|---|---|
| [#87](https://github.com/HiQS-Suite/XYZ-forge/issues/87) | 4 · Wiring & Integration | `collect.sh` end-to-end with all 8 lenses, `fixtures/all-degraded/`, `install.sh --check`, `ci-route.sh` registration, and full `test/gh77-standup-triage.sh` suite |

## Contract

`collect.sh --fixture <dir>` emits one unified JSON document containing lenses 1–8:

```json
{
  "repo": {"branch": "<name>"},
  "lenses": {
    "1": {"status": "ok|degraded", "degraded_id": "D<n>|null", "candidates": [ ... ]},
    "2": {"status": "ok|degraded", "degraded_id": "D<n>|null", "candidates": [ ... ]},
    "3": {"status": "ok|degraded", "degraded_id": "D<n>|null", "candidates": [ ... ]},
    "4": {"status": "ok|degraded", "degraded_id": "D<n>|null", "candidates": [ ... ]},
    "5": {"status": "ok|degraded", "degraded_id": "D<n>|null", "candidates": [ ... ]},
    "6": {"status": "ok|degraded", "degraded_id": "D<n>|null", "candidates": [ ... ]},
    "7": {"status": "ok|degraded", "degraded_id": "D<n>|null", "candidates": [ ... ]},
    "8": {"status": "ok|degraded", "degraded_id": "D<n>|null", "candidates": [ ... ]}
  }
}
```

## Pass condition — machine-checkable, per unit

```bash
skills/standup/collect.sh --fixture skills/standup/fixtures/all-degraded
python3 skills/standup/triage.py --lenses <that output> --dry-run
bash test/gh77-standup-triage.sh
bash validate.sh --subsystem releases
```

## Definition of done for this phase

1. All 8 lenses run together in `skills/standup/collect.sh`.
2. `skills/standup/fixtures/all-degraded/` cleanly triggers all degradation modes and `triage.py` handles the collapsed output within the 15-line display cap exiting 3.
3. `skills/standup/install.sh --check` exits 0 when installed (or 1 when not) without errors.
4. `ci-route.sh` maps `skills/standup/*` changes to `test/gh77-standup-triage.sh`.
5. `test/gh77-standup-triage.sh` passes 100% clean.
6. `bash validate.sh --subsystem releases` is green.

## Working rules for the BUILDER

- **`skills/standup/fixtures/` is a DIRECTORY lane** — files inside are yours to create/update.
- **Do not leave scratch files in the tree.** Keep temp probes under `$TMPDIR`.
- **`triage.py` is NOT modified** — report any finding in the relay file rather than editing `triage.py`.


## Debug mantra (auto-triggered — 1 prior attempt(s) on this phase did not reach Approved)

Before trying again, read `relay-automation/DEBUG-MANTRA.md` (relative to the harness root) and follow its four-step discipline: reproduce reliably, know the fail path, question the hypothesis, treat this round as a breadcrumb for the next one.
Last recorded reason (`marathon-system/daybreak-wave-4-2026-08-20/ESCALATION.md`): `containment-violation (off-lane edit reverted by a turn-taker)`. Read it before re-guessing.

---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): skills/standup/collect.sh,skills/standup/fixtures/,skills/standup/install.sh,utils/ci-route.sh,test/gh77-standup-triage.sh
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge/bin/tick
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge/bin/tick claim MARATHON-DAYBREAK-WAVE-4-2026-08-20-TURN --agent agy --paths "marathon-system/daybreak-wave-4-2026-08-20/RELAY.md,skills/standup/collect.sh,skills/standup/fixtures/,skills/standup/install.sh,utils/ci-route.sh,test/gh77-standup-triage.sh"
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge/bin/tick ping MARATHON-DAYBREAK-WAVE-4-2026-08-20-TURN --agent agy
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge/bin/tick release MARATHON-DAYBREAK-WAVE-4-2026-08-20-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/daybreak-wave-4-2026-08-20/RELAY.md and skills/standup/collect.sh,skills/standup/fixtures/,skills/standup/install.sh,utils/ci-route.sh,test/gh77-standup-triage.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/standup/collect.sh,skills/standup/fixtures/,skills/standup/install.sh,utils/ci-route.sh,test/gh77-standup-triage.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge/bin/tick release MARATHON-DAYBREAK-WAVE-4-2026-08-20-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge/bin/tick done MARATHON-DAYBREAK-WAVE-4-2026-08-20-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/XYZ-forge/bin/tick
   Edit ONLY marathon-system/daybreak-wave-4-2026-08-20/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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
