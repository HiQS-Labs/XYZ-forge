---
gh_issue: 896
source: https://github.com/HiQS-Labs/XYZ-forge/issues/896
title: "feat(skills): unified task-sync — central core + per-IDE adapters (ZCode, Antigravity)"
status: Active (2-WORKING — plan drafted 2026-09-30, pending plan QA)
created: 2026-09-30
updated: 2026-09-30
owner: noelsaw1
doc_type: plan
effort: 2
complexity: 2
risk: 2
phases: 2
rating: "pri/sev/appeal/effort 65/35/70/50 · calc 220"
roadmap_row: rmi-01M3SBWHWGSWAFVKTW7ZAE1MMX
fix_probes:
  - test -f skills/3-weekly/task-sync/scripts/task_sync.py
goal: >
  One central core with thin per-IDE adapters grooms both the ZCode app task list and the
  Google Antigravity task list under a single documented stamp semantic (last-activity
  date), one safety contract, one CLI with a doctor, one 15-minute heartbeat, and one
  Skills Army HQ-deployable canonical home at skills/3-weekly/task-sync/. Ports the
  relay-proven logic of PR #893 (utils/zcode/task-stamp) and PR #894 (utils/skills/
  agy-task-sync); both originals are superseded after soak, not modified here.
---

# GH-896: Unified task-sync — central core + per-IDE adapters

## Status

| What was just completed | What's next |
|---|---|
| **INTAKE 2026-09-30** — issue #896 filed; capture parked in the RELEASES ledger (`rmi-01M3SBWHWGSWAFVKTW7ZAE1MMX`) and rated `65/35/70/50` (calc 220); disposable task clone on `feat/gh-896-unified-task-sync` off `origin/development` (`c24a2bc3`) with per-clone hooks installed; prior-art recon clean (only #893/#894 on this seam). | Plan QA via GLM 5.3 Max relay → adjudicate to Approved → roadmap `--accepted-start` admission → Phase 1 build. |

## Observed problem

1. **Duplicated semantics, divergent behavior.** Two same-goal scripts (404 + 311 lines)
   share stamp-prefix logic, idempotent retitle, pin policy, dry-run/apply split, and
   report shape, but disagree on stamp semantics (Agy: rolling *today* reapplied to every
   synced task; ZCode: the task's own last-activity date) and safety posture.
2. **One destructive edge in agy-task-sync.** `load_pinned_ids()` returns `[]` on any
   `app_storage.json` read failure, and the empty-pinned early return
   (`agy_task_sync.py:246-248`) still runs `cleanup_stale_pinned_annotations([], apply)` —
   under `--apply` that strips `pinned:true` from **every** annotation file. Untriggered on
   current data, catastrophic if `app_storage.json` is ever locked/absent during a run.
3. **App-owned Electron state written blind.** `save_pinned_ids()` rewrites the whole
   `app_storage.json` (reformatted, `indent=2`) with no app-running gate, no backup, no
   atomic rename — last-writer-wins against a running Antigravity.
4. **Scheduler sprawl.** Agy ships three scheduling options (in-session `/schedule`,
   built-in daemon, launchd) beside task-stamp's ZCode cron — five ways to double-run the
   same writes.

## Requirements (per issue #896)

- R1 One core owning stamp logic, report schema, windows/pin policy, and the safety
  contract; adapters own only store I/O.
- R2 Stamp = **last-activity date** everywhere (ZCode `updated_at` ms-epoch local;
  Agy `last_modified_time` UTC-text → local date). Agy's rolling-today is replaced.
- R3 Safety contract, core-enforced: schema-validate before write with clear abort;
  dry-run by default (`--apply` to commit); write-only-on-change; composite/unique keys;
  **a failed or empty authoritative read never triggers a destructive write**;
  Antigravity writes gated on the app not running; `app_storage.json` backed up and
  replaced atomically.
- R4 CLI: `task_sync.py --ide zcode,agy [--apply] [--set-title ID DESC] [--doctor]`
  with a merged JSON report; per-IDE isolation (one IDE's store failure never blocks
  or corrupts the other).
- R5 `--doctor`: per-IDE store reachability, schema check, app-running detection,
  heartbeat receipt staleness; exits nonzero on any red.
- R6 Canonical home `skills/3-weekly/task-sync/` (SKILL.md + scripts/), Skills Army
  HQ-deployable; SKILL.md carries the install SOP (HQ intake → sync targets →
  heartbeat → doctor) and ARCHITECTURE.md Skills Index gains the 3-weekly row.
- R7 One heartbeat: the existing ZCode 15-minute automation is repointed (app-side
  step, done by the installer SOP) to `task_sync.py --apply --ide zcode,agy`; the
  daemon/launchd/`/schedule` options are dropped.
- R8 Verification without new suites (GH-831): functional probes on DB copies, doctor
  fault injection, `./validate.sh` exactly once on the final commit, TESTS-RESULTS
  receipt with provenance.

## Smallest affected surface

- New: `skills/3-weekly/task-sync/` (SKILL.md, `scripts/task_sync.py`, `scripts/core.py`,
  `scripts/adapters/{__init__,zcode,antigravity}.py`).
- Modified: `ARCHITECTURE.md` (one Skills Index row), the RELEASES ledger rows for this
  issue, `TESTS-RESULTS/` receipt.
- Untouched: `utils/zcode/task-stamp/`, `utils/skills/agy-task-sync/` (superseded after
  soak in a follow-up), both IDE apps, all existing gates/test suites.

## Existing subsystems extended (no parallel systems)

- Stamp/clean-base/idempotency logic is ported **verbatim in behavior** from the QA'd
  `sweep_tasks.py` (`STAMP_RE`, `clean_base`, `local_stamp`, `sync_meta`-equivalent,
  per-row set-title stamping) — not reinvented.
- Agy's transcript-preview extraction (`get_last_action_from_transcript`) and pbtxt
  text-format editing move into `adapters/antigravity.py` behind the contract, with the
  two safety fixes applied.
- Skills-tree tier conventions + Skills Index registration follow GH-889/#890's pattern;
  deployment follows `skills-army-hq`'s SOP (intake.py/sync.py), not a new mechanism.
- The heartbeat is the already-running ZCode automation (`automation-c77e69d3`), repointed.

## Explicit non-goals

- No Codex/Claude adapters (no implementation exists to port).
- No new `test/` suites, registry entries, or gate machinery (GH-831).
- No daemon, launchd plist, or in-session scheduler in the unified skill.
- No retirement of the `utils/` implementations in this PR (post-soak follow-up).
- No cross-IDE task migration or shared task store — adapters groom their own app only.

## Dependencies & sequencing

- None on #893/#894 landing: both adapters port logic into new files; those PRs are held
  and superseded (operator decision). Their review findings are reused as evidence.
- Base: `origin/development` @ `c24a2bc3`. Plan QA (GLM 5.3 Max) gates execution start
  (`roadmap update --gid rmi-01M3SBWHWGSWAFVKTW7ZAE1MMX --accepted-start` after approval).

## Risks & rollback

| Risk | Mitigation | Rollback |
|---|---|---|
| Antigravity store format drift | Adapter schema/pattern checks abort with clear message; doctor surfaces red | Revert PR; originals untouched and still deployable |
| App clobbers externally-written state | Known, documented (ZCode proved it); sweep re-applies next tick; app-running gate blocks Agy writes while app is open | Stop heartbeat; state self-heals on next app write |
| `app_storage.json` corruption on write | Backup per write + temp-file atomic rename; write only after successful read | Restore `.bak-<ts>` written immediately before |
| Heartbeat double-run with old scripts during transition | Installer SOP repoints the single automation; old scripts have no other scheduler (daemon/launchd never deployed) | Revert cron prompt |

## Bounded verification (and explicit non-scope)

- **In scope:** python functional probes on `.backup` DB copies for both adapters (stamp
  from last-activity incl. UTC→local correctness, idempotent second run, no-write-on-
  no-change, `needs_summary` on ZCode, pin policy, per-row set-title); doctor fault
  injection (missing store, dropped column, unreadable `app_storage.json` with non-empty
  annotations must NOT strip pins, app running + `--apply` must refuse Agy writes);
  `./validate.sh` once on the final commit; TESTS-RESULTS receipt with `provenance.jsonl`.
- **Non-scope:** no synthetic fuzzers, no new registries, no CI wiring, no multi-device
  matrix; Skills Army HQ deployment is previewed (`intake.py add` preview + `sync.py`
  preview); actual device apply is the operator running the installer skill.

## Ordered implementation (verification inline)

1. **Phase 1 — core + ZCode adapter + CLI + doctor.**
   a. `scripts/core.py`: port `STAMP_RE`/`clean_base`/`local_stamp` + report schema +
      `AdapterError` + window/pin policy defaults. *Verify:* import smoke + stamp probes
      on a ZCode DB copy match the QA'd sweep_tasks.py outputs exactly.
   b. `scripts/adapters/zcode.py`: port the sweep/set-title storage layer onto the
      contract (schema check, WAL, busy timeout, composite keys, `needs_summary`,
      per-row stamps). *Verify:* probe battery on DB copies — dry-run/apply/idempotency/
      no-change-no-write; diff against `sweep_tasks.py` outputs on the same copy.
   c. `scripts/task_sync.py`: CLI (`--ide`, `--apply`, `--set-title`, `--doctor`,
      `--json`), per-IDE isolation, merged report, heartbeat receipt write.
      *Verify:* doctor green on live stores read-only; fault injection red cases exit
      nonzero with clear messages.
2. **Phase 2 — Antigravity adapter + docs + deployment SOP.**
   a. `scripts/adapters/antigravity.py`: port summaries-DB + pbtxt + transcript-preview
      logic; last-activity stamps (UTC→local); app-running write gate; atomic backed-up
      `app_storage.json` write; cleanup only after verified authoritative read.
      *Verify:* probe battery on copies of all three stores (synthetic + real copies
      with app closed); destructive-cleanup fault injection proves the GH-896 fix.
   b. `SKILL.md`: operations, doctor, install SOP (HQ intake → targets → heartbeat →
      doctor), caveats (app-overwrites-active-titles, UI refresh, Agy write gating).
      *Verify:* every documented command runs as documented on this machine.
   c. `ARCHITECTURE.md` Skills Index row (3-weekly); ledger `roadmap update` raw-text
      refresh; TESTS-RESULTS receipt. *Verify:* `releases check` clean;
      `utils/pdda/pdda.sh run` zero errors; HQ `intake.py add --preview` accepts the
      folder.
3. **Final:** `./validate.sh` exactly once on the final commit SHA; final GLM 5.3 Max
   relay QA on diff + evidence; PR against `development`.

## Acceptance checks (falsifiable)

- A1 `task_sync.py --doctor` exits 0 on this machine with all stores present; exits
  nonzero with a named red on each injected fault (missing store / dropped column /
  unreadable app_storage / app running).
- A2 On identical DB copies, unified adapters reproduce the QA'd scripts' verified
  behavior: second run reports zero writes; stamps derive from each row's own
  last-activity time (UTC conversion covered for Agy); a raw `09-29`-only title is
  not restacked.
- A3 The GH-896 destructive edge is closed: unreadable `app_storage.json` + `--apply`
  aborts the Antigravity adapter with annotations untouched (probe asserts byte-identical
  pbtxt files before/after).
- A4 App-running gate: `pgrep` matching Antigravity + `--apply` → adapter refuses Agy
  writes, ZCode side unaffected (per-IDE isolation observed in one merged report).
- A5 `releases check` + `pdda.sh run` clean; `validate.sh` green on the final SHA;
  HQ preview intake accepts `skills/3-weekly/task-sync/` as a vendorable skill.
