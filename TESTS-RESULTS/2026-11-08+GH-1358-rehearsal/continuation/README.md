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
