# Exact-candidate qualification invocation

Continuation on the same GH-1317 branch/draft PR 1318. This is the committed
invocation provenance before execution; it is not a passing-result claim.
The candidate is the commit containing this invocation. Production source remains
blob 721858cd469a8bda4c70fcbe56275d018c8c5f44, independently reviewed in the pilot.

Run one missing existing local full gate: RELAY_SELF_SUFFICIENCY_SKIP=1
./validate.sh --parallel 4 in an exclusively owned fresh standalone full clone.
The skip is the established GH-836 CI/pre-push default for the live-provider suite,
not a blanket suite exclusion. No new tests or cases. Existing generated exact-SHA
.xyz/receipts/<candidate>.json and complete retained transcript are the outcome;
results will be disclosed on the existing PR without changing the tested commit.
Only a valid full-scope pass receipt can qualify this exact candidate locally.
This is not hosted main-promotion evidence. No other host gate was found at preflight.

Cross-model transfer was denied by automatic approval review before dispatch;
no source was sent. Explicit payload/destination authorization is pending. The
previous independent Codex review is valid for the unchanged production source,
but must not be called a new cross-model review or substitute for the full gate.

The task checkout and earlier gate/verify clones remain preserved. New disposable
qualification clone has its own Git directory and no shared worktree metadata.
No merge/deploy, formal GitHub APPROVE or draft-state change is authorized here.
