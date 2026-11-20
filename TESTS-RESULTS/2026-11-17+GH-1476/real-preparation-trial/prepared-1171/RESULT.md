# Case PREPARED — #1171 freshness reuse

Disposition: **reused — preparation evidence fresh at live development; HELD for execution owner** (prior accepted start exhausted its 2-attempt lane budget and an unreviewed candidate is preserved). No research child launched (budget 0 by design). No capture/ledger/label write.

## Freshness checks run (commands and nonempty outputs)

| Check | Command | Observed |
| --- | --- | --- |
| Capture unchanged branch vs live | `git -C <verify> show HEAD:PROJECT/1-INBOX/GH-1171-BRANCH-ARTIFACT-PREFLIGHT.md` vs `gh api …contents/…?ref=6000f3de…` then `diff` | `capture-identical` |
| Probed source unchanged | `shasum -a 256` on `utils/py/relay_drive.py` from branch `2e22cce0` and live `6000f3de` | both `a85a894e80947668dd396eb183513700f98bc688b93c18e3eac9b8f099728655` (`hashes.txt`) |
| Probe still discriminates (bug present) | `cd <src> && python3 -I ../manual_probe.py` (probe inspected first: AST-loads 4 functions, git-inits a tempdir fixture only) | rc=1 at both SHAs, `RuntimeError: artifact path not found in worktree: fix/gh1171-probe` (`probe-branch-src.out`, `probe-dev-src.out`). Contract has `expect_nonzero: true` → unfixed. Matches 2026-11-11 control at `68367d66` |
| Parser + Jog linter | `PYTHONPATH=utils/py python3 -c 'extract_contract(...); contract_probes_from_doc(...)'` in evidence clone, bytecode off | keys `artifacts,fix_probes,gate,remediation,round_cap,target`; labels `['command:python3 TESTS-RESULTS/2026-11-11+GH-1171/manual_probe.py']`; reason `None`; `PARSER+LINTER OK` (`parser.out`); evidence clone porcelain still 0 |
| Overlap | `gh pr diff 1467` / `1505` grep for the 4 probed functions | 0 hits each (both touch `relay_drive.py` elsewhere) — textual overlap risk only |
| Live functions | `grep def` in live `relay_drive.py` | lines 425, 443, 454, 464 |
| Live ledger | `gh api -H raw …/releases.sql?ref=6000f3de…` | row `rmi-01M74KXX9V1CFAC9TEXTAP1Y58` 🚧 in-progress, 65/50/50/90, ovr null; `jog_queue` `jog-01M74KY87SPPBKHNJ361G2Q0AH` status `failed`, `attempt_count 2`, `relay-failed-before-gate (exit 5)` |
| Prior run record | #1386 comments | Agy review failed `RESOURCE_EXHAUSTED` HTTP429; unreviewed candidate `ae942d0f7e31423cbee7d4a30693f3a2f4b441bd` preserved; LANE_MAX_ATTEMPTS=2 consumed |

## Medium-checklist coverage of the prior record

Covered: baseline SHA (`68367d66`, provenance), owner seam (Python relay preflight functions), bounded artifacts, acceptance, discriminating unfixed control, rating. Gaps: no fixed-control witness (only possible after implementation); capture's "Scope and budget" is trial #1386-specific and expired (hard end 2026-11-11T06:51:58Z); unknowns/next owner not stated for after the failed run; issue body still cites `relay-drive.sh` Bash lines, capture correctly targets Python and freezes the twin.

## Not run (needs parent)

`bash utils/swarm-preflight.sh --project-doc … --dry-run` creates/removes a detached worktree and executes command probes; Conveyor requires a separate disposable full clone. Not run on the evidence clone. Request parent provisioning to complete Step 5 for this item.

## Why held, not re-prepared

Re-preparing would not reset cumulative attempt budget. The decision whether to review/salvage candidate `ae942d0f`, re-admit with a new authorized attempt budget, or rebuild belongs to the operator/Jog owner. Preparation evidence itself is fresh.
