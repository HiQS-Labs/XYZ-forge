# Marathon Phase gh-625
STATUS: Approved
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-625-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-625-agent-chorus-bridge-bind-without-getfqdn

- Generated: 2026-09-15T06:56:06Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/marathon-clones/10days-2026-09-14-HiQS-Labs--XYZ-forge-20260914-233620/PROJECT/2-WORKING/GH-625-AGENT-CHORUS-BRIDGE-BIND-WITHOUT-GETFQDN.md 
- Target root: /Users/noelsaw/marathon-clones/10days-2026-09-14-HiQS-Labs--XYZ-forge-20260914-233620 (marathon/10days-2026-09-15 @ 852372781)
- Suggested branch: `marathon/gh-625-agent-chorus-bridge-bind-without-getfqdn-2026-09-15` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash test/agent-chorus-bridge.sh`

- Artifacts: skills/agent-chorus/scripts/agent_chorus_bridge.py,test/agent-chorus-bridge.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 1388 LOC across 2 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.


This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/marathon-clones/10days-2026-09-14-HiQS-Labs--XYZ-forge-20260914-233620/PROJECT/2-WORKING/GH-625-AGENT-CHORUS-BRIDGE-BIND-WITHOUT-GETFQDN.md` (its `## Acceptance` section, 4 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*Verified against [issue #625](https://github.com/HiQS-Labs/XYZ-forge/issues/625) — 4/4 criteria copied verbatim from issue #625.*
- [ ] `skills/agent-chorus/scripts/agent_chorus_bridge.py` binds its HTTP server without calling `socket.getfqdn()`: `ThreadingHTTPServer` overrides `server_bind` to call `socketserver.TCPServer.server_bind(self)` and sets `server_name` / `server_port` from the bound socket (or an equivalent that never performs a reverse DNS lookup at bind time). No behaviour change for callers: `server_address`, the auth-posture banner, and every `--tunnel` path are unchanged.
- [ ] `test/agent-chorus-bridge.sh` gains one check that starts the bridge with `socket.getfqdn` patched to block (or raise) and asserts startup still reaches the banner / tunnel refusal within the existing 4 s probe window. Red control: the pre-fix server does not reach it under the same patch.
- [ ] `bash test/agent-chorus-bridge.sh` is green locally (all checks pass, none skipped that ran before).
- [ ] Post-merge verification (not part of the lane): the first hosted `wave-reconcile.yml` run on `development` after this lands no longer lists `agent-chorus-bridge.sh` in `failed:`.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `skills/agent-chorus/scripts/agent_chorus_bridge.py,test/agent-chorus-bridge.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash test/agent-chorus-bridge.sh`, and NOT `test/agent-chorus-bridge.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-625-agent-chorus-bridge-bind-without-getfqdn RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact skills/agent-chorus/scripts/agent_chorus_bridge.py,test/agent-chorus-bridge.sh \
  --pre-advance-cmd 'bash test/agent-chorus-bridge.sh' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
- `marathon-invocation.json` — the same invocation as structured data (`swarm-preflight/marathon-invocation@1`, GH-280); supervisors consume this, never the shell text


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): skills/agent-chorus/scripts/agent_chorus_bridge.py,test/agent-chorus-bridge.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/10days-2026-09-14-HiQS-Labs--XYZ-forge-20260914-233620/bin/tick
   - /Users/noelsaw/marathon-clones/10days-2026-09-14-HiQS-Labs--XYZ-forge-20260914-233620/bin/tick claim MARATHON-GH-625-TURN --agent codex --paths "marathon-system/gh-625/RELAY.md,skills/agent-chorus/scripts/agent_chorus_bridge.py,test/agent-chorus-bridge.sh"
   - /Users/noelsaw/marathon-clones/10days-2026-09-14-HiQS-Labs--XYZ-forge-20260914-233620/bin/tick ping MARATHON-GH-625-TURN --agent codex
   - /Users/noelsaw/marathon-clones/10days-2026-09-14-HiQS-Labs--XYZ-forge-20260914-233620/bin/tick release MARATHON-GH-625-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh-625/RELAY.md and skills/agent-chorus/scripts/agent_chorus_bridge.py,test/agent-chorus-bridge.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/agent-chorus/scripts/agent_chorus_bridge.py,test/agent-chorus-bridge.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/marathon-clones/10days-2026-09-14-HiQS-Labs--XYZ-forge-20260914-233620/bin/tick release MARATHON-GH-625-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/10days-2026-09-14-HiQS-Labs--XYZ-forge-20260914-233620/bin/tick done MARATHON-GH-625-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/10days-2026-09-14-HiQS-Labs--XYZ-forge-20260914-233620/bin/tick
   Edit ONLY marathon-system/gh-625/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

- Files touched: `skills/agent-chorus/scripts/agent_chorus_bridge.py`, `test/agent-chorus-bridge.sh`, and this relay file.
- Overrode `ThreadingHTTPServer.server_bind` to bind through `socketserver.TCPServer.server_bind`, then populate `server_name` and `server_port` directly from the bound socket. This preserves `server_address` while bypassing `HTTPServer.server_bind` and its `socket.getfqdn` reverse-DNS lookup.
- Added a bounded GH-625 regression probe that replaces `socket.getfqdn` with a hard failure and requires bridge startup to reach the existing unauthenticated-tunnel refusal with exit 2 within the four-second window. Removing the override makes this control fail before the refusal.
- Verification: per the phase scope lock, I did not run tests or gates in this isolated worktree; the harness owns `bash test/agent-chorus-bridge.sh` after handoff.

### Round 1 · Reviewer · agy

swept file: yes

The changes fully satisfy the acceptance criteria:
1. `ThreadingHTTPServer` successfully overrides `server_bind` to bypass `socket.getfqdn`, using `self.socket.getsockname()[:2]` instead, which guarantees no reverse DNS lookup occurs.
2. The added test check properly guards this by monkeypatching `socket.getfqdn` to block/raise, asserting that the initialization reaches the tunnel refusal point before it exits 2.
3. A full file sweep found no preexisting issues or logic faults in the surrounding bridge server logic.

**Verdict:** Approved

### Attestation · relay-drive — 2026-09-15T07:02:05Z
task: MARATHON-GH-625-TURN
reviewer: agy
status: Approved
reviewed-head: d461ca4b85624a10ef32ccbfcbe0f41575fba427
added-range: 10154+595
added-sha256: a4c9ab3d164605e6e9b3aed8b72c3f54fdd1f1a2c2ccfc80c435a859020ead9a
