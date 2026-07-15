# Marathon Phase gh205-turn-timeout
STATUS: Approved
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH205-TURN-TIMEOUT-TURN builder=codex reviewer=agy round-cap=7 -->

## Phase Brief

# Lane brief — GH-205: realistic turn-timeout + per-lane override + no false HALT on a done turn

Execution surface of record: `PROJECT/1-INBOX/GH-205-TURN-TIMEOUT-FALSE-HALT.md`
(issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/205)

## Task

A builder turn that already produced + committed its artifact with a green gate can still be
killed at `relay-automation/codex-turn.sh:131`'s `RELAY_TURN_TIMEOUT_S` default (300s), classified
exit 7, and HALT the whole marathon — the reviewer round never runs.

1. Raise the shim default (`codex-turn.sh`, and the same default in `agy-turn.sh`) to 900s;
   keep the `RELAY_TURN_TIMEOUT_S` env override.
2. Add per-lane `turn_timeout_s:` to the MARATHON.yaml schema: parse in `bin/marathon-yaml`,
   plumb through `relay-automation/marathon.sh` into the lane's drive env as
   `RELAY_TURN_TIMEOUT_S`.
3. In the drive/halt classification: on exit 7, if the lane's declared artifact(s) exist and the
   pre-advance gate passes, proceed to the reviewer round instead of HALT. A true hang (no
   artifact, or red gate) still HALTs.
4. Document `RELAY_TURN_TIMEOUT_S` and `turn_timeout_s:` in `relay-automation/README.md` and
   `relay-automation/MARATHON.example.yaml`.

## Definition of done

- `test/marathon-yaml.sh`: `turn_timeout_s:` parses and defaults correctly.
- `test/marathon.sh`: per-lane value reaches the shim env.
- `test/codex-turn.sh` / `test/marathon.sh`: exit-7 with artifact present + gate green advances to
  review; exit-7 with no artifact still halts.
- `bash validate.sh` green.

---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): relay-automation/codex-turn.sh,relay-automation/agy-turn.sh,relay-automation/marathon.sh,relay-automation/marathon-drive.sh,bin/marathon-yaml,relay-automation/README.md,relay-automation/MARATHON.example.yaml,test/marathon.sh,test/codex-turn.sh,test/marathon-yaml.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH205-TURN-TIMEOUT-TURN --agent codex --paths "phases/gh205-turn-timeout/RELAY.md,relay-automation/codex-turn.sh,relay-automation/agy-turn.sh,relay-automation/marathon.sh,relay-automation/marathon-drive.sh,bin/marathon-yaml,relay-automation/README.md,relay-automation/MARATHON.example.yaml,test/marathon.sh,test/codex-turn.sh,test/marathon-yaml.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH205-TURN-TIMEOUT-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH205-TURN-TIMEOUT-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gh205-turn-timeout/RELAY.md and relay-automation/codex-turn.sh,relay-automation/agy-turn.sh,relay-automation/marathon.sh,relay-automation/marathon-drive.sh,bin/marathon-yaml,relay-automation/README.md,relay-automation/MARATHON.example.yaml,test/marathon.sh,test/codex-turn.sh,test/marathon-yaml.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/codex-turn.sh,relay-automation/agy-turn.sh,relay-automation/marathon.sh,relay-automation/marathon-drive.sh,bin/marathon-yaml,relay-automation/README.md,relay-automation/MARATHON.example.yaml,test/marathon.sh,test/codex-turn.sh,test/marathon-yaml.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH205-TURN-TIMEOUT-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH205-TURN-TIMEOUT-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh205-turn-timeout/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · codex

Files touched: `relay-automation/codex-turn.sh`, `relay-automation/agy-turn.sh`, `relay-automation/marathon.sh`, `relay-automation/marathon-drive.sh`, `bin/marathon-yaml`, `relay-automation/README.md`, `relay-automation/MARATHON.example.yaml`, `test/marathon.sh`, `test/codex-turn.sh`, `test/marathon-yaml.sh`.

Key decisions:
- Raised the Codex and agy shim defaults from `300` to `900` seconds while preserving the `RELAY_TURN_TIMEOUT_S` override.
- Kept `turn_timeout_s` inside the allowed surface by teaching `bin/marathon-yaml` to parse/emit it directly and plumbing that field through `marathon.sh` as per-lane `RELAY_TURN_TIMEOUT_S`.
- Added timeout recovery in `marathon-drive.sh`: an exit `7` now only resumes into review when the declared artifact exists, the pre-advance gate is green, and the relay/task state shows the builder actually advanced the baton past itself; otherwise it still halts as a real hang.
- Extended the targeted regression tests to cover the new YAML column, per-lane env export, the “commit + handoff but shim exits 7” fixture, and the marathon-drive resume-vs-halt split for artifact-present vs no-artifact timeouts.

### Round 1 · Reviewer · agy

I have run the marathon tests, and `test/marathon.sh` fails with:
`FAIL: GH-205 recovery run exit=7`

**Investigation:**
In [marathon-drive.sh](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/relay-automation/marathon-drive.sh#L614-L616):
```bash
run_relay_drive || relay_exit=$?
if [[ "$relay_exit" -eq 7 ]]; then
  recover_timeout_exit || relay_exit=$?
fi
```
The expression `recover_timeout_exit || relay_exit=$?` has a logic bug. If `recover_timeout_exit` succeeds (returns 0), the `||` branch is not executed, meaning `relay_exit` is not updated and retains its previous value of `7`. This causes the phase to fail as a timeout/hang instead of proceeding to success.

**Requested Fix:**
Please update [marathon-drive.sh](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/relay-automation/marathon-drive.sh#L614-L616) to update `relay_exit` correctly regardless of the return value of `recover_timeout_exit`, for example:
```bash
if [[ "$relay_exit" -eq 7 ]]; then
  recover_timeout_exit
  relay_exit=$?
fi
```

**Verdict:** Changes requested

### Round 2 · Builder · codex

Files touched: `relay-automation/marathon-drive.sh`.

Key decisions:
- Fixed the exit-propagation bug in the outer timeout-recovery branch without tripping `set -e`: the wrapper now captures `recover_timeout_exit` under `if`, so a successful recovery clears the stale `7` and a real hang still reaches the existing `case 7` escalation path.
- Kept the change scoped to the reviewer-reported control-flow seam so the existing GH-205 resume-vs-halt behavior remains intact aside from the false `exit 7` on successful recovery.
- Verification: `bash test/marathon.sh` (passes, including GH-205 resume-to-review and no-artifact halt coverage).

### Round 2 · Reviewer · agy

I have reviewed the changes in `relay-automation/marathon-drive.sh`.
- The exit-propagation bug in the outer timeout-recovery branch has been fixed correctly.
- All test suites (`test/marathon.sh`, `test/marathon-yaml.sh`, and `test/codex-turn.sh`) pass successfully.
- No other issues were found, and the behavior aligns with the definition of done.

**Verdict:** Approved

