# Relay attestation under an ignored parent

Observed while delivering Forge #1255 / Rebalance #368: on Apple Git 2.39.5, git add of a force-tracked relay file under the ignored relay-system parent returned 1, while the subsequent file-scoped commit still succeeded. relay_drive.py commit_relay_file correctly refused attestation publication after the failed add, leaving an on-disk trailer without a machine record. Source: utils/py/relay_drive.py:666-682 and committed #1255 final review receipts.

The task was unblocked by a supported external-artifact review in Forge, where the transcript is normally tracked; no gate or ignore rule was changed. Outside the capture fix: investigate whether preflight should detect this tracked-under-ignored-parent case before dispatch. Do not infer machine approval from a committed trailer alone.
