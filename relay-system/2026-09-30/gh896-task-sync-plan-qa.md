# RELAY · Plan QA GH-896 - unified task-sync
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-30.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
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
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh896-task-sync-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-896-UNIFIED-TASK-SYNC.md** — the canonical plan for
  GH-896 (unified task-sync), also committed in-tree at
  `PROJECT/2-WORKING/GH-896-UNIFIED-TASK-SYNC.md` (this clone's HEAD).
- Ground truth for every claim about the two source implementations (READ-ONLY, outside the
  worktree — read by absolute path, never edit):
  - ZCode: `/Users/noelsaw/Documents/GH Repos/XYZ-forge/utils/zcode/task-stamp/scripts/sweep_tasks.py` + `SKILL.md`
  - Antigravity: `/Users/noelsaw/Documents/GH Repos/XYZ-forge/utils/skills/agy-task-sync/scripts/agy_task_sync.py` + `SKILL.md`
  - Safety-contract reference: `/Users/noelsaw/Documents/GH Repos/XYZ-forge/utils/zcode/task-stamp/SKILL.md`
- Reviewer: commandcode   ·   Producer: claude-a
- Started: 2026-09-30
- Definition of Done: _The plan is executable as written by a fresh session: every claim about the
  two source implementations is verifiable at a cited file:line; the safety contract closes the named
  destructive edge; acceptance checks detect the actual failures; machinery stays commensurate with a
  local developer CLI (GH-831: no new test/ suites)._

Goal: QA the GH-896 plan BEFORE implementation (plan QA, not code review).

Operational envelope: local developer CLI on one macOS device grooming two local app task stores;
no daemons, no multi-tenant threat model; machinery must stay commensurate (PDDA/ponytail) —
grade against the plan's stated requirements, not unrequested enterprise fail-safes.

Questions (answer each; cite file:line for every claim about existing code):
1. Grounding: does the plan's "Observed problem" match the two source implementations (stamp
   semantics divergence, the `load_pinned_ids()` empty-read destructive cleanup edge, blind
   whole-file `app_storage.json` rewrite, scheduler sprawl)? Falsify anything mis-cited.
2. Requirements: is anything MISSING for a safe unification (R1-R8)? e.g. concurrency between the
   heartbeat and a live app session; report schema adequacy for the cron consumer; per-IDE
   isolation semantics.
3. Architecture: does core.py + adapters + CLI extend the existing proven code without a duplicate
   or parallel subsystem? Is anything over- or under-engineered for the envelope?
4. Blast radius & rollback: are the risk table, rollback paths, and "untouched" surface claims
   complete and honest? Any hidden dependency on PRs #893/#894 landing?
5. Acceptance checks A1-A5: does each detect the actual failure? Red controls adequate? Is the
   verification scope right given GH-831 forbids new test suites?
6. Ratings/governance: is `65/35/70/50` defensible against the rating policy (severity honest,
   appeal labeled as operator interpretation)? Any intake step skipped that SOP Step 1b requires?

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Be concrete and cite
file:line.

Write your verdict below and set STATUS to Approved if the plan passes.

<!-- REPLACE-MARKER -->

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer — Round 1 (commandcode)

swept file: yes — whole artifact (181 lines) plus all four ground-truth files (sweep_tasks.py, agy_task_sync.py, both SKILL.mds), SOP.md Steps 1/1b, and the RELEASES-DB-FAQS.md rating vocabulary; contained probes run with `PYTHONDONTWRITEBYTECODE=1`, output under `.relay-scratch/`, commands + rc + decisive output quoted inline. Pre-existing defects in files the plan touches: one found (last Nit, in the superseded original the plan ports from); none in the artifact's own text beyond the graded findings below.

**Q1 — Grounding**

- [Pass] Observed #2 (destructive edge) — verified and WITNESSED. `load_pinned_ids()` returns `[]` on missing file (agy_task_sync.py:40-41) and on any read/parse exception (:49-51); the empty-pinned early return (:245-248) runs `cleanup_stale_pinned_annotations([], apply)`, which strips `pinned:true` from every annotation not in the empty set (:202-213 → :175-181). Contained probe on synthetic stores (`.relay-scratch/tmp/agy_edge_probe.py`, rc=0): malformed `app_storage.json` + `apply=True` → `[WARN] Failed to read app_storage.json: Expecting property name enclosed in double quotes...`, then both annotations became `'title:"09-28 old title"\n'` (pins stripped); control case with a valid file pinning conv-a → conv-a kept `pinned:true`, conv-b stripped. The edge is real, not merely plausible.
- [Pass] Observed #3 (blind rewrite) — `save_pinned_ids()` re-dumps the whole file with `indent=2`, plain `open(path,"w")`, no gate/backup/atomic rename (agy_task_sync.py:54-67).
- [Pass] Observed #1 (stamp divergence) — Agy reapplies rolling today (`get_today_us_date` :33-35; `format_title_with_date` strips any `MM-DD`/`MM/DD` prefix and re-prefixes today :138-145; applied per row :267 — probe case 2 stamped a 09-28 task `"09-30 task a"`); ZCode stamps the row's own `updated_at` (sweep_tasks.py:195, `local_stamp` :58-60). R2's choice of ZCode semantics is correct.
- [Nit] "(404 + 311 lines)" — `wc -l` (rc=0): agy_task_sync.py 404 ✓, sweep_tasks.py **338**, not 311. Fix the count.
- [Nit] "five ways to double-run" — it's four: Agy SKILL.md documents exactly three options (`/schedule` :81-90, daemon :92-97, launchd :99-128) + task-stamp's one CronCreate automation (task-stamp SKILL.md:70-80). Fix the count or name the fifth.
- [Should] "share ... pin policy" (Observed #1) mis-cites the divergence, and the unified Agy pin semantics are unspecified. The two pin models differ in kind: ZCode DERIVES pins from an activity window and writes them (sweep_tasks.py:209-215); Agy READS the app's `pinned_conversations_order` as ground truth and mirrors it (agy_task_sync.py:245-247, :269; `auto_pin` is opt-in at :299-300). R1's "core owning windows/pin policy" leaves `adapters/antigravity.py`'s pin write path undefined — derive-by-window means more `app_storage.json` writes (the dangerous surface), mirror-only means core pin policy is ZCode-only.
  - Observed input: sweep_tasks.py:209-215 (window-derived `UPDATE tasks SET pinned=1`) vs agy_task_sync.py:269 (`is_pinned = cid in pinned_ids`, app_storage-derived).
  - Affected scope: the Antigravity adapter's pin write path; the Phase 2a "pin policy" probe oracle; R1's windows/pin-policy clause.
  - Falsifier: if A2's "reproduce the QA'd scripts' verified behavior" is meant to fix Agy pins as mirror-app-owned, the ambiguity resolves from the plan text alone — but R1 then needs a ZCode-only qualifier on pin policy; expected result: one sentence in R1/R2 removes the derive-vs-mirror ambiguity either way.

**Q2 — Requirements**

- [Pass] Concurrency (heartbeat vs live app): ZCode short WAL transactions + `busy_timeout=5000` (sweep_tasks.py:99-100) with app-revert self-heal next sweep (task-stamp SKILL.md:87-89); Agy app-running write gate (R3/A4). Covered.
- [Pass] Per-IDE isolation: R4 + A4 (refusal observed in one merged report). Covered.
- [Nit] Cron-consumer report contract: R4 says "merged JSON report" but step 1c lists a `--json` flag — state the default output shape, and that per-IDE `needs_summary` stays machine-addressable: the repointed automation prompt consumes it ("for any needs_summary entries craft and apply summaries", task-stamp SKILL.md:74-77).
- [Nit] Doctor receipt-absence state: R5 checks "heartbeat receipt staleness" but Phase 1c verifies "doctor green on live stores" before the installer has repointed any heartbeat, so no receipt can exist yet. Define receipt-absent as a distinct non-red state, else Phase 1c's verification is unpassable as written.

**Q3 — Architecture**

- [Pass] No parallel system; the ports are real. Every named port exists at cited behavior: `STAMP_RE` sweep_tasks.py:43, `clean_base` :63-74, `local_stamp` :58-60, `sync_meta` :105-116, per-row set-title :260-292, composite keys :204-206/:287-290; Agy transcript preview :70-135 and pbtxt editing :148-199. Doctor + heartbeat receipt are commensurate with an unattended 15-minute heartbeat, not enterprise fail-safes; no new gates (GH-831 respected).
- [Pass] "the already-running ZCode automation (automation-c77e69d3)" — verified: live index query (sqlite `mode=ro`, rc=0) returns `automation-c77e69d3-afac-49f0-9f0c-17e1ed006f16`.

**Q4 — Blast radius & rollback**

- [Blocker] The plan's port sources do not exist in its stated base tree — not executable as written by a fresh session in the task clone it prescribes. The plan pins "Base: `origin/development` @ `c24a2bc3`" and a task clone "off `origin/development`", then cites `utils/zcode/task-stamp/` and `utils/skills/agy-task-sync/` as the code to port and as "Untouched" surface. Probe: `git ls-tree origin/development --name-only utils/zcode/task-stamp utils/skills/agy-task-sync` → **empty** (rc=0); `gh api repos/HiQS-Labs/XYZ-forge/branches/development --jq .commit.sha` → `c24a2bc381...` (the remote tip IS the stated base — not a stale-ref artifact). The sources live only unmerged: task-stamp is tracked on the primary clone's current branch `feat/gh-889-weekly-daily-planner-skills` (HEAD 3b4d359e); agy-task-sync on PR #894's head `feat/gh-892-agy-task-sync` (commits 419d5701f..48ab5f623) plus untracked working-tree files in the primary clone. A fresh session in the task clone hits file-not-found at Phase 1a, and "Untouched" plus rollback's "originals untouched and still deployable" read as if the originals were in the base tree — they are not.
  - Observed input: the empty `ls-tree` above; `git log --oneline -1 -- utils/skills/agy-task-sync` on the primary clone's HEAD → no commits.
  - Affected scope: Phase 1a/1b/2a port steps, "Existing subsystems extended", "Smallest affected surface → Untouched", "Dependencies & sequencing", the risk-table rollback cell.
  - Falsifier: in a fresh clone of the GitHub remote at `development`, re-run the `ls-tree` — if the two dirs are listed, this finding dissolves. Expected result per the probes above: still empty. The fix is text-only: add a "Port sources" note naming the primary-clone absolute paths (as this relay's Setup does) and/or the PR #893/#894 head branches, and reword "Untouched" to state the originals are absent from the base and remain on their holding branches.
- [Pass] Risk-table row 4 verified: no Antigravity/task-sync plist in `~/Library/LaunchAgents/` (ls, rc=0) and no `agy_task_sync` process (pgrep rc=1). "daemon/launchd never deployed" is true; no other schedulers exist to double-run during transition.
- [Pass] Base claim verified: `origin/development` = `c24a2bc381...` = live GitHub tip (rev-parse + gh api).
- [Pass] No landing dependency, correctly stated: PRs #893/#894 verified OPEN with heads `feat/zcode-task-stamp` / `feat/gh-892-agy-task-sync` and titles matching the plan's attribution. The real dependency is code *access*, which the Blocker above makes explicit.

**Q5 — Acceptance checks**

- [Pass] A2's pinned behaviors exist in source: bare-date non-restack (`clean_base` returns `""` for a bare `MM-DD`, sweep_tasks.py:70-71 → :197 keeps the original title); idempotent second run and last-activity stamping verified under Q1.
- [Nit] A2's lead-in "reproduce the QA'd scripts' verified behavior" contradicts R2 for Agy — the QA'd Agy behavior is rolling-today, which R2 deliberately replaces. Keep the enumerated sub-checks (they are right); qualify the lead-in ("storage behavior, with R2's unified stamp semantics").
- [Should] A3 lacks a witnessed red control. A3 proves the fix (abort + byte-identical pbtxt), but nothing in the plan runs the same fault against the ORIGINAL script to witness the failure the check guards — and the plan itself says the edge is "Untriggered on current data", so the receipt would carry a check nobody has seen fail.
  - Observed input: the Q1 probe (rc=0) — the original strips pins under malformed `app_storage.json` + `--apply` and discriminates correctly on a valid read. The red control exists and costs one extra invocation on the same copies.
  - Affected scope: A3's probe battery and the TESTS-RESULTS manual-check record (per GH-831 / AGENTS §6).
  - Falsifier: run the same fault against the original `agy_task_sync.py` on a copy — if it does NOT strip pins, Observed #2 collapses and A3's premise is wrong. Witnessed here: it strips.
- [Should] The mandated probe battery has no stated store-targeting mechanism. R8/A2/bounded verification require "functional probes on `.backup` DB copies", but R4's CLI (`--ide, --apply, --set-title, --doctor`, step 1c `--json`) has no `--db`/`--store` override, and the plan never says probes instantiate adapters with injected paths. The ZCode original ships `--db` for exactly this (sweep_tasks.py:297; task-stamp SKILL.md:55 "--db PATH (test against a copy)").
  - Observed input: R4's flag list vs bounded verification's "functional probes on `.backup` DB copies for both adapters".
  - Affected scope: how every mandated probe (A2/A3/doctor fault injection) targets copies rather than live stores.
  - Falsifier: if the intent is programmatic instantiation (R1: "adapters own only store I/O"), one clarifying sentence dissolves it; expected result: no probe can accidentally hit a live store.
- [Pass] A1/A4/A5 shape: doctor faults map 1:1 to R5 checks; A4 observes per-IDE isolation in one merged report; A5's governance set (releases check, pdda.sh run, validate.sh once, HQ preview) matches the rails. Verification scope is right for GH-831: probes + manual checks + one `validate.sh`, no new suites.

**Q6 — Ratings/governance**

- [Pass] Intake complete per SOP Step 1/1b: issue #896 OPEN with matching title (gh probe); doc at `PROJECT/2-WORKING/GH-896-UNIFIED-TASK-SYNC.md` with full frontmatter incl. `updated:` and the exact two-column Status table; ledger row `rmi-01M3SBWHWGSWAFVKTW7ZAE1MMX` present (worktree `releases.db`, `mode=ro` probe) with correct `doc_path`/`issue_url` and raw_text in the required `- **GH-896 · ...**` bullet grammar (SOP.md:79-80); rating columns stored 65/35/70/50, `rating_ovr` NULL, `status_label` NULL (correct — `--accepted-start` is deliberately post-QA per GH-646); committed in-tree copy is byte-identical to the seeded artifact (diff, rc=0). Prior-art claim corroborated (gh search "task-sync": only #892/#894 and #896 on this seam; other hits unrelated).
- [Pass] 65/35/70/50 defensible against the GH-108 vocabulary (RELEASES-DB-FAQS.md:125-139): sev 35 is honest — the destructive edge is real (witnessed above) but untriggered on live data, and the primary pain is duplication; effort 50 on the cheapness axis fits a two-phase port with probes (not a quick win, not a multi-week rewrite); pri/appeal are judgment axes by definition ("urgency", "stakeholder / developer desirability"). Arithmetic 65+35+70+50 = 220 ✓.
- [Nit] Appeal labeling: no citable policy requires an "operator interpretation" tag — FAQs defines appeal as desirability, inherently interpretive. If the operator's convention wants the label, add it to the ledger raw_text; otherwise leave as is.
- [Nit] Stale model naming: the plan says "Plan QA via GLM 5.3 Max relay" (Status table) and "final GLM 5.3 Max relay QA" (step 3), but this relay's reviewer seat is commandcode. Genericize to the relay id (`gh896-task-sync-plan-qa`) or mark the model as the operator's choice.
- [Nit] Do not inherit the original's stale self-path: agy SKILL.md:38 says the script lives at `skills/2-daily/agy-task-sync/scripts/agy_task_sync.py`, but the files are at `utils/skills/agy-task-sync/` — a pre-existing defect in the superseded original; the Phase 2b SKILL.md port must not copy it (worth one line in the post-soak retirement note).

**VERDICT: FAIL**

**Basis:** One executability Blocker — the plan's cited port sources are absent from its stated base (`origin/development` @ c24a2bc3), so a fresh session in the prescribed task clone cannot execute Phase 1a as written, and the "Untouched"/rollback claims mislead about where the originals live. Three Shoulds leave a fresh implementer guessing on safety-adjacent surfaces (Agy pin derive-vs-mirror, probe store-targeting, A3 red control). All findings are plan-text fixes — the core + adapters + CLI + doctor architecture, the safety contract (verified against the witnessed failure), and the GH-831-scoped verification are sound; no redesign requested. Fix the Blocker + Shoulds (Nits at Producer's discretion) and this should approve next round.


### Producer · claude-a — r1 dispositions, plan amended in-tree

- [Blocker] port sources absent from base — **Implemented**: "Smallest affected surface"
  now states the sources are absent from `origin/development` @ c24a2bc3 (ls-tree-verified)
  and live on holding branches (#893 head `feat/zcode-task-stamp`, #894 head
  `feat/gh-892-agy-task-sync` + primary-checkout copies); "Dependencies & sequencing"
  gained a "Port sources (executability)" block naming the read-only absolute paths; the
  rollback cell no longer implies the originals are in the base.
- [Should] Agy pin derive-vs-mirror — **Implemented** (falsifier's "one sentence" arm,
  both halves): R1 declares pin policy adapter-declared — ZCode derive-by-window writes;
  Antigravity **mirror-app-owned** (`pinned_conversations_order` ground truth, mirrored to
  annotations only, `--auto-pin` opt-in), keeping derived pin writes off the
  `app_storage.json` surface; Phase 2a probe oracle updated to match.
- [Should] probe store-targeting — **Implemented**: R4 adds `--zcode-db PATH` /
  `--agy-root PATH` (constructor-injected), so every probe targets copies and cannot hit
  a live store; ordered-implementation step 1c lists them.
- [Should] A3 red control — **Implemented**: bounded verification now mandates running
  the same malformed-read fault against the ORIGINAL `agy_task_sync.py` on a copy and
  citing the witnessed strip (r1's Q1 probe) in the TESTS-RESULTS record.
- [Nit] line count — **Implemented**: 404 + 338.
- [Nit] scheduler count — **Implemented**: four.
- [Nit] report contract — **Implemented**: R4 states JSON is the default and only stdout
  contract; `needs_summary` stays machine-addressable per IDE; `--json` dropped from 1c.
- [Nit] receipt-absent — **Implemented**: R5 defines `heartbeat: pending — no receipt
  yet` as a distinct non-red state.
- [Nit] A2 lead-in — **Implemented**: qualified with "storage behavior ... under R2's
  unified stamp semantics".
- [Nit] stale model naming — **Implemented**: Status/step-3 references genericized to the
  relay id (`gh896-task-sync-plan-qa`), model noted as operator choice.
- [Nit] appeal labeling — **Declined (kept as-is)**: the plan's rating rationale already
  carries the labeled interpretation; no ledger raw_text change needed.
- [Nit] stale self-path — **Implemented**: Phase 2b now forbids inheriting the original's
  stale `skills/2-daily/...` self-path; SKILL.md self-references point at the new home.

All dispositions applied in-tree at `PROJECT/2-WORKING/GH-896-UNIFIED-TASK-SYNC.md`
(this commit). No scope or architecture change requested or made.

handing off to Reviewer (commandcode) — take your turn: re-review the amended plan
against the r1 findings and set the verdict (line starts exactly `VERDICT: `).

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->

