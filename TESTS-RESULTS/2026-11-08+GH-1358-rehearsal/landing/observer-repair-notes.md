# Existing observer correction

Preserve the existing read-only launchd observer and state/log surfaces. Add explicit
elapsed sample-gap reporting and alarm above180s or on backward clock movement;
a fresh healthy current sample no longer implies continuous coverage. The existing
work-status is retained alongside an OBSERVATION_GAP alert. Same-host operating envelope
is explicitly awake-only. Historical sleeps/gaps and full qualification requirements
remain unchanged. Config cutoff is this authorized19:06:18Z window, not an extension.

Recognize the now-deployed finite landing stage using the existing launchd job PID plus
its pinned1373head/base/merge-cleanup command. Bound landing from18:23Z (before actual
launch) by1800s; after exec intoJog, retain the original process/lease/checkpoint logic.
No new heartbeat file, queue, supervisor, retry, processkill or work-state mutation.

Manual controls execute the exact new gap block for15/179/181/982/-1s intervals;
old-code red executes the original observer decision AST with a healthy resumed sample
and a982s preceding gap. Full configuration compiles. Actual scheduled main-path
observation is required before calling the deployment verified. Initial gap includes
explicitly declared paused time between the old12:12Z stop and this continuation;
it is reported, not silently removed. Alerts are local logs, never an offhost claim.
