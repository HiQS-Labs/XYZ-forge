# GH-922 verification

Synthetic local snapshots only; no app-store writes or private chat content. Base #902 missing activity for project-pin fails (exit 1); fixed source 65e60c9c passes 11 manual assertions and all 28 existing Codex manual controls. This is recorded manual evidence, not a new test suite/runner or registry entry.

Replay: `python3 TESTS-RESULTS/2026-10-02+GH-922/manual-command.txt` from repository root (writes only temp/). The synthetic matrix includes excluded project rows in pinned and chats sections, custom, durable host, ChatGPT, heartbeat, old updatedAt and old actual turn activity; asserts exactly two eligible title proposals and only one new pin. It also verifies missing/invalid/future eligible activity refusal, stale/empty/malformed/ambiguous inventory refusal, idempotent native readback and CLI error exit 3.

The command body and decisive red/green outputs are retained with SHA-addressed provenance. A disposable full clone hosts all checks. Independent final QA Approved (driver exit 0). Small qualifying gate at 62593e14 failed: 71/75 checks passed. Three failures were caused by inherited XYZ_HARNESS override; clean-environment comparisons are recorded separately. The deploy-skills October 2 archive assertion also fails on unmodified #902 (8c2e6cf3), tracked by #914/#915. This is not merge-ready evidence.

After merging development at f16707c0: Small gate exit 0, Python 21/21, manual matrix 11/11 and existing controls 28/28. Inherited archive failure fixed by development. Clean environment removes the harness override failures. Clone identity intact. Previous failed run retained as diagnostic history.
