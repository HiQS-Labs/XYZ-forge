---
Goal: Medium review — PR #643 final merged state (GH-642 tranche)
Date: 2026-09-15
NEXT: agy
STATUS: Approved
---

# Context

MEDIUM-scope review (single pass; the implementation already passed 3 Codex QA rounds — this is
the pre-merge check of the FINAL merged state, not a re-QA). PR #643: `feat/gh642-consumer-fruit`
→ `development`. This tree is the merged head `68613ec4` = implementation `e15de062` (QA'd) +
two merges of current `development` (upstream GH-645 ledger writes conflicted in
releases.sql/releases.db; resolved by taking upstream's dump and replaying the GH-642 roadmap row
through the CLI: `roadmap add/rate 60/35/50/48/repoint/update` — current row gid
`rmi-01M2NTBAT8DMBQ48Q888DNW4C2`, `releases check` clean).

Plan of record: `PROJECT/2-WORKING/GH-642-CONSUMER-FRUIT.md`. Prior QA threads:
`relay-system/2026-09-15/qa-gh642.md` (rounds 1-3, final state approved except test-falsifiability,
which was fixed and mutation-checked).

Medium-depth checklist — verify in THIS tree, cite file:line, do not re-litigate settled design:

1. The six items survive the merges intact: vendor info/exclude destination + direction-2 intact
   (relay-automation/xyz-vendor.sh); warn_opus_budget present and called in main
   (utils/py/claude-turn.py); resolve_force_relay_task spec + call site before receipt/render
   (utils/py/marathon_drive.py); worktree deps copy (relay-automation/relay-turn-lib.sh);
   xyz_init_clone contract (utils/py/xyz_init_clone.py); warn_zero_criteria before dry-run exit
   (utils/py/swarm_preflight.py).
2. Frozen twins still byte-clean of GH-642 behavior: relay-automation/claude-turn.sh,
   relay-automation/marathon-drive.sh, utils/swarm-preflight.sh.
3. Ledger: releases.sql has exactly ONE GH-642 roadmap row (rmi-01M2NTBAT8DMBQ48Q888DNW4C2), no
   leftover conflict markers anywhere in releases.sql/releases.db/LEADERBOARD.md, no duplicate
   gh_number 642 rows, rating 60/35/50/48, doc_path PROJECT/2-WORKING/GH-642-CONSUMER-FRUIT.md.
4. Merge hygiene: no conflict markers in any tracked file; the plan/status doc reflects reality;
   validate.sh TESTS registry contains gh642-consumer-fruit.sh exactly once; gh365 exemption
   present once.
5. Test suite: test/gh642-consumer-fruit.sh still falsifiable (spot-check three assertions of your
   choice against the implementations they guard).

Findings: BLOCKER/SHOULD/NIT with file:line, then exactly one line `VERDICT: APPROVED` or
`VERDICT: CHANGES REQUESTED` + minimal fix list. Edit ONLY this relay file. Do NOT run git.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex — MEDIUM REVIEWER role; ALLOW_PATHS is empty: this relay file is your only
writable path; verify and report, never edit code)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

---

## Medium review · codex · final merged state

The six GH-642 items survived the development merges intact. Vendor reconciliation still checks
direction 2 before mutation and writes direction-1 rules to the resolved repo-local exclude, with a
non-Git `.gitignore` fallback (`relay-automation/xyz-vendor.sh:253-319`). The Opus warning helper is
present and called from `main()` after effective model/budget resolution
(`utils/py/claude-turn.py:36-47,110-114`). Forced-token resolution retains its fail-closed scan and
runs before `_RESULT["token"]` and downstream render/receipt consumers
(`utils/py/marathon_drive.py:487-531,1388-1395`). Worktree dependency transfer remains a real copy,
not a symlink (`relay-automation/relay-turn-lib.sh:758-772`). The initializer still enforces the
documented full-clone, naming/retry, unconditional Tier-2 vendor, conditional-hook, and next-step
contract (`utils/py/xyz_init_clone.py:46-61,72-125`). The zero-criteria warning remains text-only and
its runtime call precedes the dry-run exit (`utils/py/swarm_preflight.py:1142-1152,1701-1711`).

Frozen-twin hygiene is intact in the current files: all three fallbacks retain their GH-308 frozen
banners and dispatch to the authoritative Python implementations
(`relay-automation/claude-turn.sh:1-18`, `relay-automation/marathon-drive.sh:1-18`,
`utils/swarm-preflight.sh:1-17`), with no GH-642 helper/message additions in their Bash bodies.

Ledger and merge hygiene are clean. `releases.sql` contains one GH-642 `roadmap_items` row with gid
`rmi-01M2NTBAT8DMBQ48Q888DNW4C2`, ratings `60/35/50/48`, and the expected working-doc path
(`releases.sql:611`); a read-only SQLite query returned the same single row. Targeted marker scans
found no unresolved merge markers in the ledger/view or reviewed code/project/test scopes (the one
match is an intentional conflict-fixture string in `test/gh53-releases-merge-resolve.sh:149`). The
plan accurately records the built/QA'd, PR-pending state and six-item result
(`PROJECT/2-WORKING/GH-642-CONSUMER-FRUIT.md:5,17-23,28-32`). The focused suite is registered exactly
once (`validate.sh:502`), and its GH-365 audited exemption appears exactly once
(`test/gh365-driver-lane-registry.sh:134`).

Three falsifiability spot-checks remain tied to the implementations they guard: the vendor
destination assertions (`test/gh642-consumer-fruit.sh:29-40`) fail if the resolved-exclude write at
`relay-automation/xyz-vendor.sh:297-319` regresses; the forced-token matrix
(`test/gh642-consumer-fruit.sh:109-150`) exercises the status/scan branches at
`utils/py/marathon_drive.py:487-531`; and the indented-call ordering assertion
(`test/gh642-consumer-fruit.sh:240-245`) specifically selects the runtime call before the dry-run
branch at `utils/py/swarm_preflight.py:1701-1705`. Per the worktree safety rail, no `test/*.sh` or
full gate was run in this review checkout; this was a current-source and read-only-ledger review.

Findings: none (no BLOCKER, SHOULD, or NIT).

VERDICT: APPROVED
