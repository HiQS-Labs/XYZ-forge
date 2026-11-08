# Continued GH1358 rehearsal

Parent reviewed PR1370 head5f98fe6 and authorized continued isolated rehearsal,
not merge. One-line scheduled requeue composition now uses existing retry-build
mode after explicit jog retry, while first dispatch remains run. Independent
plan/final Codex QA approved. No new queue, supervisor, tests or gate machinery.

Manual control is a separate disposable full fixture, dispatch stubbed so no model
was called. Old code selects run after explicit retry (red); new code selects
retry-build. The fixture's three queue leases are not actual workload attempts.
Initial fixture setup exposed identity and primary ownership refusals; preserved
logs. A full clone with local fixture primary pin and canonical origin corrected
setup without changing global configuration or canonical primary state.

Timeout diagnosis: provider-local Agy log cli-20261108_003547.log records local regex
checks at 00:49:12 and 00:50:17, and model responses near 00:50:28, before termination
00:50:49. This contradicts a proved lock-stall diagnosis: no such cause is established.
The turn used its 900-second wall cap without a patch. Source queue attempt1 and
Marathon lane fire remain retained. Retry will change builder from agy to codex,
reviewer to agy, not raise limits: worker wall/idle900, relay rounds5, lane max2.
Task blocker repair max3 is distinct from QA rounds and Marathon lane attempts.
Actual model/cost telemetry remains unknown unless the new receipt supplies it.

Second concrete connection: the runner remains on the prior lane after Marathon.
In checkpoint mode only, before a pending row is leased, acquire the existing
runner driver lock, require a named clean branch, switch to prepared development,
then release for Marathon. This allows Marathon's existing branch guard and PR
closeout to own each lane; it preserves prior commits and refuses busy/dirty or
detached runners. Independent plan/final QA approved. Manual real-git/lock/queue
controls pass; checkpoint/engine stubbed, not deployed-autonomy evidence.

Independent workload selected from current live open-issue discovery: GH1160.
Actual startup paragraph contradicts dispatch-only workflow/local reconcile; issue
OPEN, no comments/defer; primary roadmap had no1160 row. Prepared a minimal docs
contract on runner development. This preparation is agent-assisted, not scheduled
no-row admission. GH670 was excluded after comments proved cap exhaustion and an
explicit operator defer. GH355 is a broad nine-table migration, not bounded here.

Budget correction from source: relay base5 can extend to hardmax10 only for
qualifying progress (relay_drive.py), not an absolute5 cap. Worker wall/idle900,
Marathon lane max2 unchanged; GH1295 count1 retained. Preparation earliest recorded
receipt 06:55:50Z implies latest ceiling12:55:50Z; the ceiling is not reset.

First successful useful wake: GH1295 attempt2 (09:54:48–10:10:37Z Marathon)
produced PR1371, then Jog published receipt tail1c235e38a and primary checkpoint
838aded2 without parent Git/chat rescue. Full gate409/409 in529s, preadvance total
544s including focused checks/clone/push; normal transcript-tail docs gate71s.
Agy independent review witnessed six-canary green and pre-fix red. Outcome approved;
prior timeout and count2/max2 retained. Token/cost totals UNKNOWN: the existing
summary's zero-instrumented floor is not measured zero; its1h24 window includes
older retained history, not this attempt's duration.

Next launchd wake selected GH1160, promoted its contract and cut its independent
Marathon branch while GH1295 remained awaiting landing. Outcome pending at this
checkpoint. No manual work between wakes; source evidence recording is independent
of deployment. PR1371 outer sanity passes development base, focused runtime/test
diff and normal gate evidence; parent retains landing approval.

Read-only planner census uses a complete live840-issue snapshot, labeled snapshot
mode rather than deployed discovery. Its only unregistered ready item is GH1356,
whose attempt is explicitly terminal; it is refused, not relaunched. GH1216's actual
CLI routing defect was reproduced and scoped by independent plan QA, but admission
and dispatch have not happened. No discovery or full seven-transition claim.
