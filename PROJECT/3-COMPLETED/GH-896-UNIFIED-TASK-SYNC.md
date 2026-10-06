---
gh_issue: 896
source: https://github.com/HiQS-Labs/XYZ-forge/issues/896
title: "feat(skills): unified task-sync — central core + per-IDE adapters (ZCode, Antigravity)"
status: Complete
created: 2026-09-30
updated: 2026-10-02
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
| **PLAN-QA r1 2026-09-30** — relay `gh896-task-sync-plan-qa` reviewed the plan; FAIL on one executability Blocker (port sources absent from the base tree) + three Shoulds (Agy pin derive-vs-mirror unspecified, A3 red control, probe store-targeting) and eight Nits (seven amended, one declined) — all addressed as plan amendments (R1 pin models, R4 store-path overrides + JSON contract, R5 receipt-absent state, Dependencies/rollback rewrites, A3 red control, counts corrected). Round-1 probe evidence: the destructive cleanup edge witnessed live on synthetic stores. | **PLAN-QA r2 2026-09-30 — VERDICT: PASS.** Round 2 re-probed every r1 disposition (ls-tree/PR-head/primary-checkout facts, pin models, store overrides, red control) and approved the amended plan; three residual text Nits folded in. Note: the driver's attestation was refused on a containment technicality (the reviewer's file-write normalized blank lines above its own block, tripping review-body-rewritten); the committed round-2 block itself carries `swept file: yes`, graded dispositions, and `VERDICT: PASS`, and the reviewer closed the relay (`tick done`) — recorded here as the attestation of record; the final QA relay provides the driver-attested approval for the PR. Task admitted (`--accepted-start`). **BUILT 2026-09-30 on branch `feat/gh-896-unified-task-sync`** — Phase 1+2 landed (`b9a68a35`): core + zcode adapter + antigravity adapter + CLI + doctor + SKILL.md installer SOP + Skills Index row; probes zcode parity 9/9 and agy battery 19/19 (incl. A3 red control witnessed against the original) recorded in TESTS-RESULTS/2026-09-30+GH-896/provenance.jsonl; doctor observed live: agy red while Antigravity runs (fail-closed, A4). |
| **AGY QA 2026-09-30 (operator-requested second lens, relay `gh896-task-sync-agy-qa`)** — r2 found a real Blocker (live Antigravity timestamps are ISO with microseconds+offset; the ported parser silently skipped all stamps) + a Should (JSON-array electron store crashed instead of clean AdapterError); both fixed (0796930a) with falsifier probes (battery now 23/23); r3 re-probed and passed **VERDICT: PASS** (attestation refused on a file-rewrite technicality — stale System marker removed by the reviewer's write; recorded in the thread). | **FINAL-QA r1 2026-09-30 (relay `gh896-task-sync-final-qa`)** — FAIL, all evidence-bookkeeping: [Blocker] the committed battery was the stale 19-check version contradicting the receipt (23-check fixed version lived in session scratch) → committed with portable paths, 23/23 from tree; [Should] doctor never judged receipt staleness → red at >2h (probed 29-day-old receipt); [Should] A1-zcode + governance arms unevidenced → parity 12/12 with doctor faults, releases/pdda recorded, HQ preview honestly blocked on pre-existing collection reconciliation; 6 Nits fixed (docstring convention, non-str guard, SKILL path, pinned_source, debris, portable path). Plan de-pathed (PDDA clean). |
| **GATE 2026-09-30** — `validate.sh` in the disposable gate clone failed exactly one suite: GH-777 inventory ratchet (tree-wide shrink-only scan flags any NEW direct-`sqlite3.connect` file). Disposition: the two adapter connects target EXTERNAL app stores (~/.zcode, ~/.gemini), not repo ledgers; the canonical gateway (`releases_app.connect`) is releases-ledger-specific (autocommit + `isolation_level=None` would break the ported QA'd transaction semantics), and `--update-baseline` refuses growth by design — so each connect line carries the checker's own inline `SQLITE-BYPASS-OK:` marker with the reason (check_inventory_ratchet.py's marker skip (scan loop) honors marked lines). Ratchet now clean; both batteries re-run green (r3 note: sqlite3.Row would in fact not break tuple-index reads — autocommit and ledger ownership are the decisive reasons; the GH-777 suite has never tested the marker path — pre-existing gap, fail-safe direction, recorded per GH-831). Code changed post-approval → final-QA round 3 (fresh attestation — **Approved, attested, reviewed 6f82a1f3**, two precision Nits folded into this row) → **GATE PASSED 2026-09-30**: full `validate.sh` green (exit 0) on final SHA `87e8b564` in the disposable gate clone (first run's single GH-777 failure resolved by the disclosed disposition; receipt finalized). | **PR-ready**: PR against `development`; retained task clone held for merge handoff (`/merge-cleanup`). |
| **PR 900 merge-readiness review** — prior relay QA verified; merged current development and rebuilt ledger with canonical resolver. Fixed missing-pin authority, pre-write validation, type preservation, receipt atomicity/partial success, fail-closed process detection, inherited escaping/path/cron/no-op defects. Existing batteries pass 24/24 and 12/12; manual red/green controls recorded. | Independent Codex QA r2 Approved, driver-attested at `429a3e47`; final macOS Small gate 75/75 (Python 21/21). Ready for merge review; PR remains open. |

## Observed problem

1. **Duplicated semantics, divergent behavior.** Two same-goal scripts (404 + 338 lines)
   share stamp-prefix logic, idempotent retitle, dry-run/apply split, and report shape,
   but disagree on stamp semantics (Agy: rolling *today* reapplied to every synced task;
   ZCode: the task's own last-activity date), pin model (ZCode derives pins from an
   activity window and writes them; Agy mirrors the app's own
   `pinned_conversations_order` as ground truth), and safety posture.
2. **One destructive edge in agy-task-sync.** `load_pinned_ids()` returns `[]` on any
   `app_storage.json` read failure, and the empty-pinned early return
   (`agy_task_sync.py:246-248`) still runs `cleanup_stale_pinned_annotations([], apply)` —
   under `--apply` that strips `pinned:true` from **every** annotation file. Untriggered on
   current data, catastrophic if `app_storage.json` is ever locked/absent during a run.
   Witnessed by the plan-QA relay probe on synthetic stores (malformed read + apply →
   both annotations stripped; valid-read control discriminated correctly).
3. **App-owned Electron state written blind.** `save_pinned_ids()` rewrites the whole
   `app_storage.json` (reformatted, `indent=2`) with no app-running gate, no backup, no
   atomic rename — last-writer-wins against a running Antigravity.
4. **Scheduler sprawl.** Agy ships three scheduling options (in-session `/schedule`,
   built-in daemon, launchd) beside task-stamp's one ZCode cron automation — four ways
   to double-run the same writes.

## Requirements (per issue #896)

- R1 One core owning stamp logic, report schema, windowing, and the safety contract;
  adapters own only store I/O. **Pin policy is adapter-declared**: ZCode derives pins
  from the activity window and writes them; the Antigravity adapter is
  **mirror-app-owned** — `pinned_conversations_order` is ground truth, mirrored to
  annotations only, with `--auto-pin` as an explicit opt-in (no derived pin writes, so
  the dangerous `app_storage.json` surface stays out of the sweep path). `--auto-pin` opts into derived pin writes
  including `app_storage.json` — the original's semantics, made safe by R3's gate,
  backup, and atomic rename.
- R2 Stamp = **last-activity date** everywhere (ZCode `updated_at` ms-epoch local;
  Agy `last_modified_time` UTC-text → local date). Agy's rolling-today is replaced.
- R3 Safety contract, core-enforced: schema-validate before write with clear abort;
  dry-run by default (`--apply` to commit); write-only-on-change; composite/unique keys;
  **a failed or empty authoritative read never triggers a destructive write**;
  Antigravity writes gated on the app not running; `app_storage.json` backed up and
  replaced atomically.
- R4 CLI: `task_sync.py --ide zcode,agy [--apply] [--set-title ID DESC] [--doctor]`
  with a merged JSON report (JSON is the default and only stdout contract — the
  heartbeat and installer consume it; per-IDE sections keep `needs_summary`
  machine-addressable); per-IDE isolation (one IDE's store failure never blocks or
  corrupts the other). Store-path overrides for probes: `--zcode-db PATH` and
  `--agy-root PATH` (constructor-injected into the adapters), so no probe can touch a
  live store.
- R5 `--doctor`: per-IDE store reachability, schema check, app-running detection,
  heartbeat receipt staleness; exits nonzero on any red. **Receipt-absent is a distinct
  non-red state** (`heartbeat: pending — no receipt yet`) so doctor is green before the
  installer ever repoints a heartbeat.
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
- Absent from base, not modified by this PR: the port sources do not exist on
  `origin/development` @ `c24a2bc3` (verified by `git ls-tree` during plan QA). They live
  on their holding branches — task-stamp at PR #893 head `feat/zcode-task-stamp` (also
  tracked on the primary checkout's `feat/gh-889-weekly-daily-planner-skills`),
  agy-task-sync at PR #894 head `feat/gh-892-agy-task-sync` (plus untracked working-tree
  copies in the primary checkout). Both are superseded after soak in a follow-up; this PR
  neither merges nor edits them.

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

- **Port sources (executability):** a fresh session in the task clone will not find the
  two source implementations in the base tree. Fetch them read-only from their holding
  branches —
  - ZCode: PR #893 head `feat/zcode-task-stamp` (also tracked on the primary checkout's
    `feat/gh-889-weekly-daily-planner-skills`), path `utils/zcode/task-stamp/`
  - Antigravity: PR #894 head `feat/gh-892-agy-task-sync`, path `utils/skills/agy-task-sync/`
  Copies of both traveled with the plan-QA relay thread's Setup block; the port is
  behavior-verbatim, so the branch copies are reference evidence, not build inputs.
- No landing dependency on #893/#894: both adapters port logic into new files; those PRs
  are held and superseded (operator decision). Their review findings are reused as evidence.
- Base: `origin/development` @ `c24a2bc3`. Plan QA (relay `gh896-task-sync-plan-qa`,
  model per operator choice) gates execution start
  (`roadmap update --gid rmi-01M3SBWHWGSWAFVKTW7ZAE1MMX --accepted-start` after approval).

## Risks & rollback

| Risk | Mitigation | Rollback |
|---|---|---|
| Antigravity store format drift | Adapter schema/pattern checks abort with clear message; doctor surfaces red | Revert PR; originals remain intact on their holding branches (#893/#894 heads) and primary-checkout copies, still deployable |
| App clobbers externally-written state | Known, documented (ZCode proved it); sweep re-applies next tick; app-running gate blocks Agy writes while app is open | Stop heartbeat; state self-heals on next app write |
| `app_storage.json` corruption on write | Backup per write + temp-file atomic rename; write only after successful read | Restore `.bak-<ts>` written immediately before |
| Heartbeat double-run with old scripts during transition | Installer SOP repoints the single automation; old scripts have no other scheduler (daemon/launchd never deployed) | Revert cron prompt |

## Bounded verification (and explicit non-scope)

- **In scope:** python functional probes on `.backup` DB copies for both adapters —
  targeted via the R4 store-path overrides (`--zcode-db`, `--agy-root`), never live
  stores (stamp from last-activity incl. UTC→local correctness, idempotent second run,
  no-write-on-no-change, `needs_summary` on ZCode, pin policy per R1's adapter-declared
  models, per-row set-title); doctor fault injection (missing store, dropped column,
  unreadable `app_storage.json` with non-empty annotations must NOT strip pins, app
  running + `--apply` must refuse Agy writes); **A3 red control**: the same malformed-
  read fault run against the ORIGINAL `agy_task_sync.py` on a copy, witnessing the pin
  strip the fix guards (already witnessed by the plan-QA relay probe; cited in the
  TESTS-RESULTS record); `./validate.sh` once on the final commit; TESTS-RESULTS
  receipt with `provenance.jsonl`.
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
      `--zcode-db`, `--agy-root`), per-IDE isolation, merged JSON report, heartbeat
      receipt write.
      *Verify:* doctor green on live stores read-only; fault injection red cases exit
      nonzero with clear messages.
2. **Phase 2 — Antigravity adapter + docs + deployment SOP.**
   a. `scripts/adapters/antigravity.py`: port summaries-DB + pbtxt + transcript-preview
      logic; last-activity stamps (UTC→local); **mirror-app-owned pins**
      (`pinned_conversations_order` ground truth, mirrored to annotations only;
      `--auto-pin` opt-in); app-running write gate; atomic backed-up `app_storage.json`
      write; cleanup only after verified authoritative read.
      *Verify:* probe battery on copies of all three stores (synthetic + real copies
      with app closed); destructive-cleanup fault injection proves the GH-896 fix.
   b. `SKILL.md`: operations, doctor, install SOP (HQ intake → targets → heartbeat →
      doctor), caveats (app-overwrites-active-titles, UI refresh, Agy write gating);
      self-path references point at `skills/3-weekly/task-sync/` (the superseded
      original's `skills/2-daily/...` self-path is stale — do not inherit).
      *Verify:* every documented command runs as documented on this machine.
   c. `ARCHITECTURE.md` Skills Index row (3-weekly); ledger `roadmap update` raw-text
      refresh; TESTS-RESULTS receipt. *Verify:* `releases check` clean;
      `utils/pdda/pdda.sh run` zero errors; HQ `intake.py add --preview` accepts the
      folder.
3. **Final:** `./validate.sh` exactly once on the final commit SHA; final relay QA
   (GLM 5.3 Max per operator choice) on diff + evidence, plus an agy-seat relay QA on the
   Antigravity adapter + unified core (operator request); PR against `development`.

## Acceptance checks (falsifiable)

- A1 `task_sync.py --doctor` exits 0 on this machine with all stores present; exits
  nonzero with a named red on each injected fault (missing store / dropped column /
  unreadable app_storage / app running).
- A2 On identical DB copies, unified adapters reproduce the QA'd scripts' storage
  behavior (idempotency, no-write-on-no-change, bare-date handling) under R2's unified
  stamp semantics: second run reports zero writes; stamps derive from each row's own
  last-activity time (UTC conversion covered for Agy); a raw `09-29`-only title is
  not restacked.
- A3 The GH-896 destructive edge is closed: unreadable `app_storage.json` + `--apply`
  aborts the Antigravity adapter with annotations untouched (probe asserts byte-identical
  pbtxt files before/after).
- A4 App-running gate: `pgrep` matching Antigravity + `--apply` → adapter refuses Agy
  writes, ZCode side unaffected (per-IDE isolation observed in one merged report).
- A5 `releases check` + `pdda.sh run` clean; `validate.sh` green on the final SHA;
  HQ preview intake accepts `skills/3-weekly/task-sync/` as a vendorable skill.
