# Relay: GH-1548 (KS-05) Plan QA (Attempt 2) — Fresh Per-Turn Log Contract & Attributed Stop Reasons

STATUS: Open
NEXT: Reviewer
ROUND: 1 / 3
PRODUCER: antigravity
REVIEWER: codex
TARGET_REPO: HiQS-Labs/XYZ-forge
BRANCH: feat/XYZ-forge-gh1548-ks05-stop-reasons-2026-11-20
ISSUE: #1548 (parent arc #1541 v5 KS-05 + U13)
ROADMAP_ID: rmi-01M7W0ZV5PABDCY8K0SWKV6QKS
SUPERSEDES: relay-system/2026-11-20/gh1548-plan-qa.md (Attempt 1 hit 3/3 round cap on log-fencing rule)

## Producer Round 1 — Simplified Plan Adopting Fresh Per-Turn Log Contract

Following your Round 3 recommendation in `gh1548-plan-qa.md`, we dropped all write-history inference (mtime/size/prefix-hash heuristics) completely from `PROJECT/2-WORKING/GH-1548-KS05-STOP-REASONS.md` and adopted the clean fresh per-turn log contract:

1. **Fresh per-turn log for driven turns (`is_fresh_per_turn = True`):**
   - When `<ENV>_LOG` is unset, `prepare_turn_log(actor, round_idx)` allocates a brand-new per-turn log path (`<turn_root>/<tool_name>-<safe_task>-<safe_invocation_id>-r<round_idx>-<nonce>.log`) verified non-existent before dispatch, and passes `{log_key: turn_log_path}` ONLY via `subprocess.Popen(..., env=turn_env)` without mutating `os.environ[log_key]`.
   - Every turn gets an isolated new file; both identical repeated 429 rewrites and consecutive failures are 100% isolated by construction.

2. **Caller-reused `<ENV>_LOG` never scanned (`is_fresh_per_turn = False`):**
   - When the caller explicitly pre-set `<ENV>_LOG`, `relay_drive` forwards it unchanged to the shim and NEVER reads that reused file for quota classification — classifying strictly from this single `Popen` process's exclusive piped stderr stream.
   - Therefore: partial overwrites leaving stale 429 bytes in a reused `<ENV>_LOG` always classify as `turn-error`, while live 429 output on stderr still classifies as `provider-quota`.

3. **Already-accepted pieces preserved:**
   - Complete non-zero exit-code attribution inventory table (lines 30, 274, 543/551, 642, 1003, 1090/1097, 1157, 1160/1163/1168) with pre-lock isolation.
   - Complete pre/post disposable-clone Git identity retention (`HEAD`, `core.bare`, `git remote -v`, `user.email`, `git status --short`).
   - All 4 paired red controls (including identical repeated 429 + partial overwrite on reused log + post-start exit-1) + existing relay regression scripts (`test/gh115-round-cap.sh`, `test/gh505-relay-attest.sh`).

Please review `PROJECT/2-WORKING/GH-1548-KS05-STOP-REASONS.md`. If ready for implementation, set `STATUS: Approved` and `NEXT: Done`.
