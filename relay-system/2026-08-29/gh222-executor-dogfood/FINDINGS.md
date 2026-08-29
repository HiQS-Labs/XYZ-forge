# GH-222 Jog→Marathon executor dogfood — record (2026-08-29)

Dogfood lane: `feat/gh222-tracking-issue-repoint` (this branch, milestone 1 = the
`--tracking-issue` implementation). The executor ran in THIS clone off local `development`
(b471df15) so the builder took real turns against a tree without the fix. Builder agy,
reviewer codex, REAL turns throughout. Queue gid `jog-01M15SX2C7QYQ5RYWTF0NSQ1SD`.

## Outcome — terminal: lane parked at the attempt cap (exit 8), no PR emitted

| Exec | Mode | Outcome | Reason | What actually happened |
|---|---|---|---|---|
| gh222-exec1 | run | completed (stale) | preflight: already-landed | Mis-declared probe: `grep_present` named for the PRE-FIX property; my marker was absent on development so preflight read already-landed. Zero turns. Fixed by probe → `grep_absent`. |
| gh222-exec2 | run | escalated (exit 5) | pre-advance-failed | 3 agy build turns + 3 codex review turns, RELAY **Approved**, then the full `validate.sh` gate failed serially on `roadmap-dashboard.sh` drift. Two root causes, both fixed on the executor lane (commit f82ce8cd, see findings 1–2). |
| gh222-exec3 | retry-build | escalated (exit 7) | timeout-no-artifact | agy CLI hung (attribution: cpu=0.06s/s, no worktree progress — host had 0 MB free swap all session), then wrote off-allowlist probe files `patch3.py`–`patch5.py` at the worktree root; containment reverted them (orphan-backups `20260829T044629Z-73938`) and failed the turn. GH-279 defect-3 class, Phase-4 finding 4 reconfirmed. |
| gh222-exec4 | retry-build | parked (exit 8) | lane parked at the attempt cap | Pre-dispatch lane-attempt gate refused (2 attempts spent), no token seeded. Per AGENTS.md this needs an explicit operator `--force` — not taken; the marathon lane branch is preserved locally (unpushed) for that decision. |

Closeout never ran → no PR from the executor. The queue row is `parked | 2 attempts` with
the cap reason; final state in `queue-row-final.txt`.

## Material findings

1. **GH-292 F3's dashboard regen shipped as dead code.** `jog_regenerate_dashboard()` was
   defined and never called — the fix existed as a comment ("the dashboard was regenerated
   after promotion"). The supervisor commit therefore carried the stale dashboard and the
   lane's gate failed `roadmap-dashboard.sh` drift: the exact Phase-4 finding-3 recurrence F3
   was written to prevent. **Fixed** on the executor lane (call wired before
   `jog_commit_supervisor_state`); the adapter suite's M1 control now actually exercises it.
2. **`test/gh280-jog-marathon-adapter.sh` section M planted a fixture row in the LIVE
   releases.db (GH-195 class).** The M-fixture `roadmap add` had no `--root`;
   `resolve_root()` landed on the real clone running the gate — receipt
   `roadmap-add rmi-01M15V9ZZ9WSBTPC9T6SFX30B9` at 2026-08-29T04:09:08Z, caught live 14 s
   later by the dashboard suite's fresh-render check. Double damage: because the FIXTURE never
   held the row, the promotion's repoint silently `no-such-row`'d and the M1/F3 assertion
   passed **vacuously** — an unfalsifiable green (GUIDING-PRINCIPLES #13). **Fixed**
   (`--root "$FR"`); M1 is falsifiable again; a fixed-run escape check in a disposable clone
   shows 0 phantom rows (the unfixed run planted one there too). This also explains part of
   the "known churn" quartet agents routinely `git restore` away.
3. **Probe-type semantics are name-inverted from intuition.** `grep_present` = "the pattern
   is present PRE-fix"; verdict `landed` fires when the pattern is ABSENT. An honest marker
   of the landed fix needs `grep_absent`. Cost here: one wasted execution (exec1) with zero
   turns and a clean, receipted early-exit — the fail-closed path worked as designed.
4. **agy builder turn hung with zero CPU/progress under a 0-swap host**, then wrote probe
   files off-allowlist; containment reverted + preserved them and failed the turn (exit 7).
   Environmental trigger suspected (memory starvation), not a harness defect; the timeout
   attribution telemetry named it precisely on the first look.
5. **`retry-gate`'s head-SHA integrity check bit as designed**: my hygiene commit moved the
   lane head past the escalated execution, so the gate-only retry refused and named
   `retry-build` — which (per GH-491's fresh-token rule) took the full-rebuild path, not the
   gate-only path. Worth knowing operationally: post-escalation hygiene commits on the lane
   convert any gate-only retry into a full rebuild.
6. Supervisor-state commits correctly skip on a lane branch (GH-292 F1 lane tradeoff,
   announced in the log); the jog queue ledger survived in untracked `.tick/` throughout.

## Builder's implementation (exec2, codex-Approved, unlanded)

The executor's builder produced its own independent GH-222 implementation on the marathon
lane (3 build + 3 review rounds): removes the `tracking-ref-immutable` refusal, re-points via
`issue_ref_for_token` inside the UPDATE, argparse help un-suppressed, +3-line FAQ entry,
test updates in `test/gh32-releases-app.sh`. Diff vs mine: it accepts TMP- re-points and does
not expand bare issue numbers; this lane's milestone-1 implementation is stricter
(placeholder refusal, `<N|URL>` canonicalization, gh-never-consulted proof). The
orchestrator chooses; the marathon branch `marathon/gh-222-releases-tracking-repoint-2026-08-28`
(local, f82ce8cd) holds the executor's version.

## Receipts

- `state.json` — full execution ledger (4 executions, relative result paths)
- `exec2/`, `exec3/`, `exec4/` — `marathon-invocation.json` + `marathon-result.json` per
  attempt (exec2 also carries `packet.md`)
- `gh222-jog-run.log`, `gh222-jog-run2.log` — the two `jog run` supervisor logs
- `gh222-retry-build2.log`, `gh222-retry-build3.log` — the retry-build logs
- `RELAY.md`, `ESCALATION.md`, `marathon-gh-222-releases-tracking-repoint-040924.md` — the
  lane's terminal relay, escalation record, and gate transcript
- `queue-row-final.txt`, `queue-state-vs-committed.patch`,
  `turn3-telemetry-and-setup-churn.patch` — queue terminal state and working-tree drift
  snapshots taken off the parked lane
