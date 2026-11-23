# GH1358 integrated rehearsal — final partial assessment

Candidate runtime5182a77c; runtime unchanged after source evidence tail5ae03986f. Agent-assisted preparation, not unattended qualification. Local launchd runs existing Jog/Marathon with separate runner/publication full clones and independent read-only observer. No new supervisor, queue, suite or gate. Per-PR merge approval retained.

| Transition | Actual evidence | Remaining gap / decision |
|---|---|---|
| Normal no-row discovery → pickup | Existing planner read-only scan840 live issues; manual reviewed pickup1160/1216 | Not deployed admission. Only unregistered ready1356 is terminal PARTIAL; do not refire. Existing522 requires independently reviewed plan/authority; planner readiness is insufficient. |
| Delivered/stale refusal | Existing preflight rejects closed1288; actual scheduled1216 malformed contract refusal | Closed refusal was manual, not a scheduled integration witness. Preserve distinction. |
| Awaiting landing → independent advance | GH1295 PR1371 held, next scheduledwake selected1160 and built/reviewed before stale-ledger gate failure; later1160 PR1372 held while1216builds and publishes PR1373 | Useful independent selection proven; initialpair not two successful PR-ready wakes. |
| Lane interruption → cold recovery | Retained scheduled GH1296 mistaken-selection interruption/cold recovery, local fixture transport | Actual recovery but workload selection was invalid; no held-workload claim. |
| Supervisor loss → scheduled resume | Local fixture automatic cold recovery; real681ab30 checkpoint recovered by a scheduled RunAtLoad wake after assisted restart | Restart activation assisted. Independent observer alerted and cleared, local only. |
| Changed candidate → approval refusal | Existing validator remains exact-SHA;1372 scope-correction changes candidate after its lane review, independently reviewed correction | No deployed approval/merge witness. No merge authority issued; global Marathon auto-merge remains refused. |
| Approved merge → reconcile → land → next | Existing primitive and earlier1356 assisted evidence reusable | No approved landing in this rehearsal. Parent/user per-PR approval boundary remains; no auto-merge enabled. |

Budgets: worker wall/idle900s, lane max2, relaybase5/hard10 only qualifying progress; gate1800s; max3 repairrounds/blocker; cutoff12:30Z; no new spend/access or PhaseB. Queue1295=2,1160=2,1216=2 after dispatch. Last has Marathonexec1 because attempt1 failed before builder, not a counter reset. GH1344/1296excluded.

Failures preserved: GH1295 first900s timeout, stale runnerledger1160, inherited preparation-doc scope1372, malformed1216probe, accidental queuedwake duringdisable/unload, systemPython stdin false-success and observerTCC denial. Earlier fullgateoverlap remains disclosed; later source409 unchanged/reused, docs-only evidence pushes, separatefullclone workloadgates.

Local observer config:15s sampling,120s silence /180s bound,1800s publication and10800s active ceiling, absolute12:30Z. Saw one SCHEDULE_SILENCE at135.1s and recovery; power-management records correlate the469.4s gap with465s sleep and later982.3s gap with979s sleep; these prevent a global detection-bound or complete slot-accounting claim; natural sleep/dark-wake continuation occurred; HEADchange is only committed activity, not acceptedprogress. Offhost detection and process restart remain unproven. Natural same-process continuation after host sleep is witnessed, without fault injection or power-setting changes. Observer performs no queue/recovery writes.

## Real work and final verification

- GH1295 → PR1371 head1c235e38a9b671d54cdec4bdee6b4651a5aeea1e, Codex/Agy, full409/409, primary838aded2. First900s timeout preserved.
- GH1160 → PR1372 head624f52c8c489c41b70445a54e860416e54538e64, AGENTS guidance only; independentAgy review, docs gate, additive scope correction normaldocs166s and independentCodexQA/parentouterpass. First stale-ledger failure preserved. Primaryda2bc3.
- GH1216 → PR1373 headc50b7616fbe5fabc56705e7894dc9a6cf5b13d6d,8lineexportchange and32lines inexisting suite; Codexplan/Agyreview a821fc55, focused56/56, full409/409 at7d07fb0f69b7ddfc15dd3e6d979fededbad5af1f; normaldocs130s plus receiptpublication. Outerbase development, no prior-lane scope. Queueattempt2/2, firstactualMarathonexec1.

The GH1216 fullgate had one parallelfailure, gh123-lock-progress-bound.sh, which passed the existing serialretry; no rerun/newgate added. Pre-push reports3403s elapsed versus gate-guard859s. The guard uses time.monotonic (utils/py/marathon_drive.py:2469); hostsleep is recorded. Configured1800s cap was unchanged, but realelapsed wall-time compliance was not achieved. This is retained under existingdeadline owner1254, with observation limits under1188. No deadline extension, offhost installation or extra workload.

Independent finalCodexQA approves meaningful agent-assisted PARTIAL, not1358qualification. New capability versus baseline is actual scheduled publication and independent progression, recoverable publication and local observation; threePRs alone are not the claim. Realwork exposed setup/scope/probe, host-sleep and clock limitations. Decisionvalue: do not widen to24h/overnight qualification; retain the working opt-in integration and repair missing discovery/approval composition and deadline/observation behavior under existingowners. Per-PR approval is the next externalboundary for landing; remaining integration gaps stay open.

Final primary checkpoint661d08cad249b7815aac21269fb581a18eaaea09 published without manual Git rescue; primary clean. Both ownedjobs disabled/unloaded after completion before12:30Z; all deployments/branches/evidence retained. Finalqueue1295/1160/1216parkedawaitinglanding at2attempts each.
