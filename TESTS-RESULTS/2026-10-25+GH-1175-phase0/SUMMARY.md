# GH-1175 Phase 0 spike: one issue through the full cycle, by hand

- Design of record: #1175 (Critical path comment 6407035729). Related: #1188, #1224, #522, #1177, #1213 (GH-1208).
- Host: operator's Mac, primary `XYZ-forge` on `development`. Start `a3450a2c` (2026-10-26 02:51Z); end `08c2a2fb` (2026-10-27 04:41Z).
- Issue: **#416** (doc trues-ups, narrowed to items 1 and 3), builder agy, reviewer codex.
- Outcome: PR #1225 merged (`81352026`), #416 closed. Jog row **parked `awaiting-landing`**, because `jog land` is blocked on GH-1208 / #1213.
- No new suites (GH-831). Every ledger write went through `releases jog …` / `releases roadmap …`.

## Hypothesis verdict

"Landing stalls first, then intake becomes the bottleneck": **partly confirmed.**

- **Admission stalled first.** At the start, 0 of 280 open issues could run. The hand-picked issue needed scope narrowing and a contract rewrite. Its first `jog run` then parked before dispatch on Jog's 1-INBOX promotion check (D1).
- **Landing is the only hard block.** Everything else had a manual workaround; landing would need code. `jog land` cannot pass after an ordinary merge since GH-1127 (fix: #1213). Operator approval took about 23.5 h, and the closeout PR didn't close the issue (D6).
- **Intake is the bottleneck for the next item.** 0 admissible issues of 281. 73% have no ledger row, and 7 of the 11 issues that have contracts are STALE.

## Stage table

| Stage | Wall clock | Agent time | Operator touches | Commands | Cost |
|---|---|---|---|---|---|
| 0 kickoff | 02:51–02:53Z | ~2 min | 0 | ~10 | — |
| 1 survey + top-3 | 02:53–02:55Z | ~4 min | — | ~18 | — |
| 1 intake of #416 | 02:56:28–02:58:21Z | ~2 min | 1 (pick + scope) | ~10 | — |
| 2 attempt 1 (promotion park) | 03:05:56Z | 0 s | 1 (approve run) | 4 | none |
| 2 SOP 1b promotion | 03:15:38–03:21:55Z | ~6 min (2 gated pushes) | 1 (choose path) | ~12 | — |
| 3 attempt 2 + crash test | 03:22:13–03:24:45Z | ~3 min | 0 (pre-approved) | ~12 | 1 partial agy turn |
| 3 recovery `retry-build` | 03:26:18–03:54:25Z | 28m07s (turns 2m54s, gates 23m43s) | 0 | ~6 | agy + codex subscription turns; `result@1` has no cost field |
| 5 evidence packet | 03:54:25–03:56:05Z | ~2 min | 0 | ~12 | — |
| 5 wait for approval | ~23.5 h | — | 1 | — | — |
| 5 merge + reconcile | 03:25:52–03:37:22Z (10-27) | ~11.5 min | 0 | 7 | — |
| 5 `jog land` refusal → trace, decision, commit | ~10 min | ~10 min | 1 (skip dispatch) | ~10 | — |
| 6 next selection | 04:38:56–04:41Z | ~3 min | 0 | ~15 | — |

Totals: about 6 operator touches, roughly 140 commands, about 75 minutes of agent-attended work and 28 minutes of unattended drive. The dominant wall-clock cost was approval latency (about 23.5 h).

## Park reasons seen

1. `unreviewed-probe-contract (no valid probes in unattended mode)`: attempt 1, before dispatch.
2. `cold-start: dispatched Marathon execution has no valid result receipt — inspect manually before any refire`: after the deliberate SIGKILL.
3. `awaiting-landing (PR #1225: …)`: attempt 3, as designed.
4. (refusal, row unchanged) `jog land`: "hosted wave-reconcile is not green for the landed PR head".

## Crash test (step 3)

SIGKILL of the jog → marathon_drive → relay-drive → agy-turn → agy tree, 18 s into the builder turn. On restart: stale lock reclaimed, orphan lease reconciled, **parked, no refire, no duplicate branch or PR**. `rtl_driver_heartbeat_status` read `finished` for a dead driver until 120 s had passed, then `stale` (D2). The heartbeat was never refreshed while the driver lived (18 s). Leftovers that needed manual handling (D3): the isolation worktree, the `claimed` tick token, the clone driver lock, and an unpushed local branch.

Step 4 (sleep/wake) was optional and not run.

## What the reconciler (#1175 Phase 1) must do: the decisions made by hand

1. **Admit on live evidence.** Check the row, capture doc, contract, real rating and plan in the issue, **plus** a live `swarm-preflight --dry-run`. STALE, AMBIGUOUS and BLOCKED are named holds, and so is delivered-but-open. Ledger fields alone admitted 5 issues that all failed.
2. **Promote before firing.** A run without a terminal attached parks every 1-INBOX doc. Either promote through SOP 1b first, or fix D1. Never depend on a tty prompt.
3. **Pre-run checks.** Primary pinned, clean and published. A **fresh disposable clone per attempt**. Gate toolchain on PATH.
4. **After a crash, trust the receipt, not the heartbeat.** Cold start parks correctly. The recovery verb is `retry-build` into a fresh clone, after clearing leftovers. Never read heartbeat `finished` as done.
5. **Landing desk.** Build the packet: PR, scope diff, attestation bound to `reviewed_candidate`, PR head = candidate + receipt-only tail, CI on that head, risk flags, and `closingIssuesReferences` containing the issue. Get one approval. Merge through merge-cleanup. `jog land` needs #1213. If the Jog hook refuses, commit the reconcile writes so the shared primary stays landable.
6. **One verb per pass, with a named reason.** The final pass here was `hold(land: GH-1208)`, `idle(run: queue empty)`, `idle(add: 0 admissible)`.
7. **Shared-primary discipline.** Uncommitted reconcile or ledger writes block other sessions' landings; this blocked #1217. Commit at each checkpoint.

## Defects / gaps (drafts, not filed; operator decides)

| Draft | Title (short) | Route |
|---|---|---|
| D1 | jog promotion lints YAML frontmatter probes, not the JSON contract probes | new issue |
| D2 | heartbeat status reads `finished` for a SIGKILLed driver | fold into #1188 L2 (comment) or new issue |
| D3 | no recovery guidance for crash leftovers before `retry-build` | new issue (doc-first) |
| D4 | stale contracts / delivered-but-open issues defeat field-based admission | comment on #522 / #1022 |
| D5 | SOP 1b names retired `utils/roadmap-dashboard.sh` | trivial fix, no issue needed |
| D6 | marathon closeout PR body omits `Closes #<issue>` | new issue |
| D7 | a merge-cleanup Jog-hook refusal leaves reconcile writes uncommitted | new issue |
| D8 | the full gate runs twice per lane on the identical tree | new issue |
| — | reconcile regenerated an untracked `MARATHON-PLAN-*.md` | evidence comment on existing #446 |
| — | `jog land` hosted-run requirement vs GH-1127 | already #1213 (GH-1208) |

## #1188 and #1224 implications

- **#1188:** rule 2 is violated by `rtl_driver_heartbeat_status` during the first `stale_after` seconds after a crash (D2). Rule 3 held in practice: Jog keyed on the receipt. L2 must map a dead pid with the heartbeat file still present to uncertain → park.
- **#1224:** a 6-line, 3-file product change needed **5 bookkeeping commits on `development`**: `dc812539` intake, `709ffbf6` + `1f5b0508` promotion, `bb15a787` Jog checkpoint, `5265cfad` post-merge reconcile. Two of them left the shared primary dirty and blocked a concurrent session's merge until committed. That supports moving operational state off git.

## Files

`step1-*` survey and preflight before/after · `step2-*` jog add/run/retry/promotion · `snap-*` state snapshots (snap.sh) · `step3-*` kill targets, leftovers, restart, resume, retry-build drive log · `step5-*` landing packet, merge-cleanup dry-run/execute, `jog land` refusal, stray MARATHON-PLAN · `step6/` survey and preflight per candidate · `D1`–`D8` draft issues.
