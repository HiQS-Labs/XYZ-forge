# Connector payload write can precede the shared deadline

While diagnosing #764, Codex plan QA found that `utils/py/work_connectors/__init__.py::_launch`
writes each serialized event batch to child stdin synchronously. `_collect` starts the shared
deadline only after all children launch. A child that pauses before reading a payload larger than
pipe capacity can delay the launch path before that deadline applies.

Evidence: a local Python subprocess probe wrote a 1 MiB stdin payload to a child that slept two
seconds before reading; the write itself took two seconds. This is outside #764's observed
`communicate()` closed-handle failure and is not a claimed fix in that task.

Next triage: decide whether the configured connector window should include payload delivery,
then write a focused timeout test before changing dispatch. Keep the existing concurrency and
cursor contracts. No issue or RELEASES row has been created for this observation yet.

Final QA also noticed a diagnostic mismatch in the same area: `dispatch(window_s=2)` can run under
a two-second window while the timeout text reports the default `CONNECTOR_WINDOW_S` of five seconds.
This does not change the deadline or cursor outcome. Triage it with the window contract above.
