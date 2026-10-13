# PR #954 base-refresh conflict-resolution review

Approved within the bounded conflict-resolution scope. No blocking finding.

Reviewer: GPT-6 (Codex), independent peer turn.
Reviewed source SHA: `2183f2c44ec637bead5953faab81a29ead6ea5c3`.
Original PR head: `738fde98d718014f6cc6f9ad5cb3e5f3762ed449`.
Integration parent: `6e1ce8e6e98430849beafe909a74b734d7ee9e4c`.

The resolved `utils/py/proc_group.py:115` preserves PR input support. Lines 125 and 130 select PIPE when input is provided and forward the exact input through communicate. Lines 128–148 retain development's nested timeout handling and outer BaseException cleanup. Against the integration parent, the entire file diff consists only of these three input-support changes; CLI cancellation and handshake behavior remain development's version.

Manual native Python checks on this source passed: nonempty input delivered exactly; omitted input provides EOF; a 0.2-second timeout retains printed input, reports timed_out with rc None, and removes the process group; an injected KeyboardInterrupt propagates after killing/reaping a real sleeping process. The timeout and cancellation children were short isolated local processes, with grace 0.1 seconds. No test suite, live provider, model or external CLI call was run.

Red control witnessed: removing only communicate's input forwarding in an in-memory copy causes the exact-input assertion to fail. No source mutation was used. Two initial probe harness errors (mock patch ordering and an unregistered in-memory module for dataclasses) were corrected; neither was a runtime-source failure. The successful functional assertions completed before the latter harness error, and the red control then completed separately.

Evidence source: exact source and parent diffs. Parent-supplied graph generation 2026-09-01T15:54:30Z had no run_bounded result and proc_group freshness not_tracked; graph evidence is not used as proof of completeness.

Limits: this approves preservation in the narrow conflict block only. It does not approve the whole PR, #947 pilot readiness, model behavior, or any change to existing holds/caps. Native checks cover direct children; no new exhaustive descendant or repeated-signal qualification is claimed. Receipt is a peer review record, not a full committed test-provenance artifact.
