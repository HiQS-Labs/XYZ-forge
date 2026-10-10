# Required-gate contract adaptation — merge batch #1012

SANITY-CHECK: Fix now. The normal full push gate is a required boundary for #982.
It refused the unmodified integrated candidate 209fd0bd after 930 seconds:
409/410 checks pass; only gh609-sdlc-agent-gaps fails. No publication or bypass.
Before/after Git identity is identical, and the serial rerun retains the failure.

Root cause: #1009 intentionally replaced universal six-stage SWE migration wording
with workload-scoped migration safeguards; its existing covering static checker
and mutation inputs still required retired text. Fix site: the existing gh609
SWE checker and its two existing SWE mutations. Why not upstream/downstream:
restoring unconditional dual-write/bidirectional requirements would reverse the
independently reviewed governance change; bypassing/removing the gate would hide it.

Differential: the unchanged candidate's focused suite exits 1; replacing only SWE
with the parent-of-#1009 version makes it exit 0. This falsifies dashboard-only and
concurrency-only attribution. The original bytes and Git identity are restored.

The adapted existing suite exits 0 (33 pass), retaining compatibility, bounded
backfill, ordering, convergence, read cutover, rollback, safe fallback and retirement
accounting. Its existing two SWE mutations now remove ordering and rollback-window
accounting and are rejected. A separate manual removal of convergence evidence
makes the same suite exit 1 (31 pass/2 fail); restored bytes remain exact. No new
suite, gate, runner, registry entry or product behavior is added.

Blast radius: existing gh609 static contract and fixture inputs only. Reversibility
Easy: one-file adaptation. The bet is that assertions pin the intentionally changed
policy without dropping its safety guarantees; independent review must validate
that bet. The new full gate remains pending.

Independent [Codex repair QA](../../relay-system/2026-10-09/gh982-gate-repair.codex.md) is Approved with mechanical attestation; driver exits 0. This approves the one-file adaptation and retained safety properties, not full qualification.
