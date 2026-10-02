# GH-922 verification

Synthetic local snapshots only; no app-store writes or private chat content. Base #902 missing activity for project-pin fails (exit 1); fixed source 65e60c9c passes 11 manual assertions and all 28 existing Codex manual controls. This is recorded manual evidence, not a new test suite/runner or registry entry.

Replay: `python3 TESTS-RESULTS/2026-10-02+GH-922/manual-command.txt` from repository root (writes only temp/). The synthetic matrix includes excluded project rows in pinned and chats sections, custom, durable host, ChatGPT, heartbeat, old updatedAt and old actual turn activity; asserts exactly two eligible title proposals and only one new pin. It also verifies missing/invalid/future eligible activity refusal, stale/empty/malformed/ambiguous inventory refusal, idempotent native readback and CLI error exit 3.

The command body and decisive red/green outputs are retained with SHA-addressed provenance. A disposable full clone hosts all checks. Final qualifying Small gate and independent final QA are pending.
