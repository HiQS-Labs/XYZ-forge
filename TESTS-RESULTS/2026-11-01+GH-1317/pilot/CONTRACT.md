# Frozen repair contract

Operator approved cases 1–8 and bounded execution on 2026-11-01. Start 22:07:47Z;
absolute stop 22:37:47Z, final evaluation starts by 22:27:47Z. At most two actor
attempts, commands <=60s, no API/provider spending. Codex actor/reviewer use existing
ChatGPT subscription login; recording fake CODEX_BIN handles candidate calls.

Independent specification owner: supervising session; actor: separate Codex relay
worker, writes harness.py only; final evaluator: separate reviewer of frozen manual
checks and raw state evidence. Existing relay, run_bounded, CLI and receipt paths;
no new reusable runner, scheduler, ledger, suite or gate registration.

Cases 1–7: real factory-primitive generate-manifest/init/tick in owned disposable
full clone, observe subprocess count, agent_called event, decision, receipt and
reservation state. Empty inbox with a recent successful probe has no call/released
reservation/zero actual cost and idle. Due (>3600 or never probed) makes exactly
one call and completes probe. Inbox makes note. Changed v2/v3 bytes after init
refuse with decision status prompt-mismatch before call, called=false and released
zero-cost reservation. Unchanged v2/v3 make a call and complete note/idle respectively.
V3 init runs --from-prs with a synthetic external gh executable and frozen local
ledger copy; no network. Fixture ids/titles are synthetic. No internal mocks.

Case 8: evaluator removes the prompt identity enforcement in a separate disposable
copy of the repaired candidate; exactly the unchanged manual oracle must reject
its mutated-prompt cases while positive controls still pass. Restore no valued tree.

The approved strictly >3600 boundary stays unchanged. Cases use a recent probe
and absent probe history; equality is inspected against the shared source predicate,
not a new timing case. A reservation row is expected; release/no net charge required.

Freeze this contract and manual-check.py.txt hashes before actor edits. Candidate
state effects and nonempty JSON matter, not just exits/digests. No weakening after
base results. A script/fixture defect is unavailable evaluation and must be recorded,
not a product pass. Same-user containment is supervised, not immutable. Stop on
identity drift, disputed contract, invalid evidence, uncertain cleanup or exhaustion.
