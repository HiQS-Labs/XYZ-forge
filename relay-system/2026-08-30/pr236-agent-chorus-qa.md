# RELAY · Post-merge QA of PR #236 agent-chorus — close semantics, doorbell liveness, onboarding (qwen3.8-max via CommandCode)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-30.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(pr236-agent-chorus-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Reviewer: commandcode   ·   Producer: claude-a
- Started: 2026-08-30
- Artifact under review: `skills/agent-chorus/scripts/agent_chorus.py` — plus, as supporting
  context, `skills/agent-chorus/SKILL.md`, `skills/agent-chorus/README.md`,
  `skills/agent-chorus/TELEMETRY.md`, `skills/agent-chorus/agents/openai.yaml`,
  `skills/agent-chorus/test-standalone.sh` and `test/agent-chorus.sh`.
  Read-only for you: do NOT edit them; append findings here only.
- Definition of Done: **PR #236 is already MERGED to `development`** (9 files, +454/-65,
  "fix(agent-chorus): close semantics, doorbell liveness, onboarding — pilot findings (#231)").
  This is therefore a **post-merge review of live code**, not a gate. That changes what is useful:
  a defect you find here is already shipped, so prioritise correctness and safety over style, and
  say plainly whether each finding warrants a follow-up issue or is fine to leave.

  Review the merged state as it stands. Grade against these questions:

  1. **Close semantics.** The PR claims to fix them. Read the close/teardown path end to end in
     `agent_chorus.py`. Is every resource opened on the happy path also released on the error and
     signal paths — file handles, subprocesses, sockets, temp files, locks? Name any path where a
     failure mid-flight leaks or leaves state behind, with `file:line`.
  2. **Doorbell liveness.** Same file. Can the liveness mechanism deadlock, spin, or miss a wakeup —
     a signal delivered between check and wait, a timeout that never fires, a waiter that is never
     notified? A concrete interleaving that breaks it is a `[Blocker]`; a theoretical worry with no
     interleaving is a `[Nit]`.
  3. **Concurrency and process handling.** Look for unbounded waits, missing timeouts, orphaned
     child processes, and reads of shared state without a guard. `agent_chorus.py` orchestrates
     multiple agents, so a hang here strands the operator with no signal.
  4. **Error paths and failure reporting.** Does a failing agent surface distinguishably from a
     succeeding one, or can a silent failure read as success? Exit codes, empty output, and
     partial results are the cases that matter.
  5. **Do the tests actually test the fixes?** `test/agent-chorus.sh` and
     `test-standalone.sh` are in the PR. Would either fail if the close-semantics or doorbell fix
     were reverted? If not, say which assertion is missing — that is the most valuable finding
     available here, because it is what lets this regress silently.
  6. **Doc-vs-code drift.** `SKILL.md`, `README.md`, `TELEMETRY.md` and `openai.yaml` all changed in
     the same PR. Quote anything they promise that the code does not do, or that the code does and
     they do not mention.

  **Review the whole file, not just the PR's diff** (GH-268): pre-existing defects in
  `agent_chorus.py` are in scope, and if you find none say so explicitly. Cite `file:line` or a
  quoted span for every `[Pass]`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### commandcode (Reviewer) — round 1 — 2026-08-30

swept file: yes — read all 2,382 lines of `skills/agent-chorus/scripts/agent_chorus.py` plus
`SKILL.md`, `README.md`, `TELEMETRY.md`, `agents/openai.yaml`, `test-standalone.sh`,
`test/agent-chorus.sh`, and `.gitignore:81-89` as supporting context. Findings below answer the
six Setup questions; pre-existing (pre-#236) defects are in scope per GH-268 and are marked.

**Q1 — Close semantics**

- [Should] **Supersede closes the old discussion before the new one exists.**
  `agent_chorus.py:826-850` closes + pointer-izes the old discussion; the new `conversation.md`
  is only written at `:855-863`. Any failure in between (disk full, `os.open` OSError) leaves the
  old discussion `Closed` with `SUPERSEDED-BY:` pointing at a ghost ID — the reserved dir
  (`:812-821`) keeps the ID from reuse (`:589-593`) but nothing is readable there. Fix: write the
  new conversation/metadata first (the ID is already reserved by the dir), then close the old one;
  or roll the old close back on failure. **Warrants a follow-up issue.**
- [Pass] Everything opened on the close path is released: `DiscussionLock` unlocks + closes in
  `__exit__` (`:963-967`); `atomic_write` unlinks its temp in `finally` (`:736-751`); flock is
  kernel-released on process death (`:929-933`); close spawns no subprocesses/sockets. Only
  hard-kill residue is an mkstemp temp — standard for the idiom.

**Q2 — Doorbell liveness**

- [Pass] No deadlock, spin, or missed wakeup: polling re-reads state every interval
  (`:1096-1113`), so a change can only be late by one interval, never lost; the timeout is
  monotonic with the sleep clamped to the remainder (`:1107-1113`), so it always fires; SIGTERM
  raises `SystemExit` and the `finally` clears the marker and restores the handler (`:1319-1336`);
  the per-poll heartbeat (`:1098-1099`) is guarded by the revert-sensitive test at
  `test/agent-chorus.sh:633-640`. No concrete breaking interleaving found.
- [Nit] `_sidecar_pid_dead` (`:1174-1191`) trusts `os.kill(pid, 0)` on the local table — pid reuse
  makes a dead doorbell read as armed. Advisory-only output, so worst case is a stale advisory
  line; no action needed beyond noting it.
- [Nit] `touch_watch_sidecar`'s "must never break a watch" contract (`:1156-1162`) leaks: the
  `watch_sidecar()` call sits **outside** the `try`, and `watch_sidecar` mkdirs `runtime/`
  (`:1149-1153`) — a mkdir failure kills the watch. Fix: compute the marker path inside the try.

**Q3 — Concurrency and process handling**

- [Pass] `drive` is double-bounded (deadline `:1426`, `:1431-1434`; max-turns `:1430`), the turn
  command is bounded by the remaining deadline (`:1458-1461`), orphans are killed via
  `killpg` SIGTERM→SIGKILL (`:1368-1381`, `:1400-1405`), and a second driver is refused by
  `DriveLock` (`:982-990`) — tested at `test/agent-chorus.sh:375-382`.
- [Nit] `drive` passes no heartbeat (`:1435-1437`), so a driven seat is reported to peers as
  `none armed — manual seat; it needs a nudge to notice its turn` (`:1260-1262`) — wrong for a
  seat that polls autonomously. Fix: arm a sidecar from drive, or soften the wording.

**Q4 — Error paths and failure reporting**

- [Should] **(pre-existing, #193 telemetry, not #236's diff)** `index_connect` crashes uncaught
  when the store dir does not exist: probed `sqlite3.connect` under a missing parent →
  `OperationalError: unable to open database file`. Reachable today: telemetry is default-ON in
  the pilot window (`:202`, today is inside it) + a legacy relay-system discussion + a machine
  that never ran `start`/`configure-store` (normalize_store returns the path uncreated,
  `:154-155`). Then `send` writes the turn (`:1674`) and crashes in `index_upsert` (`:1704`)
  with a traceback, exit 1 — **a committed turn that reads as failure**; a retry then fails
  "out of turn". Same exposure in `command_outcome`'s direct connect (`:2076-2086` — `try/finally`
  with no `except`). Fix: catch connect failure like the sidecar's `except OSError`, or mkdir the
  store parent in `index_connect`. **Warrants a follow-up issue.**
- [Pass] Failing agent surfaces distinguishably: non-zero command → exit 2 +
  `turn command failed with exit N` (`:1469-1470`); exit-0-without-advance is detected
  (`:1471-1478`); watch timeout exits 3 with `STILL-WAITING` (`:1343-1354`). Tested at
  `test/agent-chorus.sh:351-368` and `:408-416`.

**Q5 — Do the tests test the fixes?**

- [Should] **The watch-invalidation half of the close fix is untested.** The
  `terminal=closed` write on close (`:1676-1683`) and `terminal=superseded` on supersede
  (`:841-848`) have zero assertions in either suite (grep for `terminal=` in both test files:
  nothing; the only hit is the STALE-LOCK negative control at `test/agent-chorus.sh:484`).
  Reverting either block leaves both suites green — this is the silent-regression opening.
  Missing assertions: arm a sidecar (fresh mtime), `close`, assert its content becomes
  `terminal=closed`; same for `--supersedes`. Fix: add both to `test-standalone.sh`'s GH-231
  section. **Warrants a follow-up issue** (or fold into this relay's Producer round).
- [Pass] Everything else is revert-sensitive: placeholder refusal (`test-standalone.sh:495-499`),
  both CLOSE-WARNINGs (`:520-521`), heading strip (`:491-493`), invitation trigger (`:468-469`),
  marker removal on exit (`:527-529`), dead-pid reporting (`:531-533`), per-poll heartbeat
  (`test/agent-chorus.sh:633-640`).

**Q6 — Doc-vs-code drift**

- [Should] `SKILL.md:488-492` documents the **rejected** stale-lock design: "a lock left by a
  crashed sender is now detected and reclaimed automatically, with a `STALE-LOCK:` line on
  stderr". The code deliberately does no reclaim (flock design, `:913-957`) and `STALE-LOCK`
  appears in **no** code path (grep-verified; the suite asserts it must stay absent,
  `test/agent-chorus.sh:483-486`). An agent following the skill waits for a line that never
  prints. The same bullet's "Silence about a seat means it never armed a doorbell" is also
  pre-GH-231 text — the code now prints an explicit `none armed — manual seat` line
  (`:1260-1262`). Fix: rewrite the bullet to the flock semantics the error message itself states
  (`:953-957`). **Warrants a follow-up issue** (doc fix).
- [Should] **(pre-existing, #193)** Telemetry for **legacy relay-system discussions writes inside
  the coordinated repository**: `telemetry_sidecar` is unconditionally `path.parent/"runtime"`
  (`:232-235`), so during the default-ON window any send/close/join on a legacy discussion
  creates `relay-system/<date>/runtime/telemetry.jsonl` (+ `close_report.json`, `:1698-1703`) in
  the git tree. `.gitignore:83-85` covers only `.*.lock` and `*.watch.agent*`, not `runtime/` —
  one `git add -A` from a commit. Contradicts `TELEMETRY.md:49-50` ("sidecar and index live only
  under the store … nothing is copied into any repository"), and `telemetry purge` rglobs only
  the store (`:2015-2028`) so it can never revoke these. Fix: skip the sidecar for non-store
  paths (or root it in the store) + gitignore stopgap. **Warrants a follow-up issue.**
- [Nit] `SKILL.md:297-298` lists drive's env vars but omits `AGENT2AGENT_HOME`, which the code
  sets (`:1454`). `TELEMETRY.md:19-20`'s "Close report — on every substantive close" should say
  "when telemetry is on" (both writes are gated on `telemetry_enabled()`, `:1685`, `:1694-1703`).
- [Nit] `SKILL.md:160` says `status` "creates no lock or sidecar" — true for files, but
  `doorbell_state` → `watch_sidecar` → `private_mkdir` (`:1204-1229`, `:1149-1153`) mkdirs
  `runtime/` for any discussion lacking one (inside the repo for legacy discussions). The suites
  fingerprint files only (`test-standalone.sh:76` uses `find -type f`), so the empty dir is
  invisible to them. Fix with the N1 change (lazy mkdir on write only).

**Verdict: Changes requested** — no `[Blocker]`: I found no concrete interleaving that breaks the
shipped close or doorbell logic, and the PR's headline fixes are real and mostly well-tested.
Five `[Should]`s: S1 (supersede ordering), S3 (sqlite crash path), S4 (missing test for the
watch-invalidation fix), S5 (SKILL.md stale-lock drift), S2 (telemetry-in-repo for legacy
discussions) — S2/S3 are pre-existing #193-era defects flagged under the GH-268 whole-file sweep.
Four of the five warrant follow-up issues; S4 can be handled in this relay's next Producer round.

handing off to Producer (claude-a) — go to the claude-a window and say "take your turn".

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
