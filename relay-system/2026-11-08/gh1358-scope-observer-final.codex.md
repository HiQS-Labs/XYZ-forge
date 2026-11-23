# GH1358 scope, probe and observer correction QA

Independent native Codex reviewer: /root/scope_probe_final. Read-only review of actual runner/source files, 2026-11-08.

Verdict: Approved for bounded continuation.

PR1372 correction624f52c8 removes GH1295 scope; remaining diff is AGENTS guidance plus GH1160 contract, transcripts and receipts. Prepared base d335e5429 differs from origin/development only by GH1216 capture. Corrected probe passes Jog lint and independently produces the expected nonempty behavioral failure under deployed Python3.13 PATH. System Python returned false success; preserve failure and keep pinned deployment environment. Observer corrections address both races without new authority or machinery. No runtime changes warrant another409-suite gate. GH1216 attempt1 consumed; continuation remains within cap2.

Earlier independent /root/local_observer_config_qa required rereading the journal after absent-owner probe, handling disappearing PID files, and best-effort supplemental heartbeat reads. These small fixes were applied and inspected by final reviewer. Local process/scheduler coverage only; host-loss/offhost delivery unproven.
