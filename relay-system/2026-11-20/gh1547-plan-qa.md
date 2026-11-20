# Relay: GH-1547 (KS-04) Plan QA — kickstart_status.py Thin Derived Read-Only Status Report

STATUS: In Progress
NEXT: Producer
ROUND: 2 / 3
PRODUCER: antigravity
REVIEWER: codex
TARGET_REPO: HiQS-Labs/XYZ-forge
BRANCH: feat/XYZ-forge-gh1547-ks04-kickstart-status-2026-11-20
ISSUE: #1547 (parent arc #1541 v5 KS-04 + U3 + U10)
ROADMAP_ID: rmi-01M7W0NS5BZNRPBKBJP51QQ5M1

## Producer Round 1 — Plan QA Submission

Please review the implementation plan in `PROJECT/2-WORKING/GH-1547-KS04-KICKSTART-STATUS.md` for **GH-1547 (KS-04)** against `#1541` v5 KS-04, U3, U10, and GH-831 (no new test suites).

### Key Design Decisions
1. **Thin derived read-only report only:** reads existing records (`run_record.py:parse_record`, `pr_minder.py --json --no-conflict-files --repo-root <target-root>`, pinned `LANDING_CLONE` `.tick/merge-cleanup/<slug>/pr-*.json` + remote PR state, log age + U3 liveness, final-QA head vs latest landed SHA, attributable stop reason). Never writes refs/locks/state, never acts as a readiness engine.
2. **U3 Liveness strictness:** `waiting` / `quiet` / `stale-candidate` / `confirmed-stopped` / `unknown`, where log age alone NEVER yields `confirmed-stopped` and NEVER authorizes `attempt_record.py finish` or redispatch.
3. **U10 Pinned-clone isolation:** reads attempt records strictly from the run record's `LANDING_CLONE:` (explicit `--landing-clone` override only for isolated fixture replay, with mismatch warning if both differ), and pairs every in-progress attempt with remote PR state (`gh pr view` or `--remote-prs-json`, defaulting to `unknown` when unavailable).
4. **Clean forward seams:** final-QA staleness (KS-13) and attributable verbatim stop reason (KS-05) are structured cleanly so KS-05/KS-06/KS-13 plug in without rewriting KS-04.
5. **Paired verification + GH-1527 read-only check:** deterministic offline fixtures + live read-only check with `git` shim and before/after `git show-ref`, `FETCH_HEAD`, `git count-objects`.

### Review Checklist
1. Does the plan satisfy every KS-04, U3, and U10 requirement in `#1541` v5 without overbuilding a readiness engine or adding a new test suite?
2. Are all fail-closed edge cases covered (unapplied amendments even with legacy parse warnings, unattributable escalation-reason files, missing remote PR state, log age vs stopped-ownership separation, read-only invariant)?
3. If clean, append your review block and set `STATUS: Approved` and `NEXT: Done`. Otherwise list numbered findings and set `NEXT: Producer`.


## Reviewer Round 1 — codex

**Verdict: Needs changes.** The thin report, reuse of `parse_record` and read-only pr-minder mode, pinned attempt source, and manual evidence rather than new suites are appropriate. Resolve the following before implementation.

1. **[Major] `confirmed-stopped` requires the complete ownership proof, not one dead PID and an absent lock.** Plan Inputs 4 and verification 2 permit `--owner-state stopped` + dead PID + no lock to produce `confirmed-stopped`, even if an associated builder, gate, push subprocess or detached session remains live (or cannot be inspected). The canonical kickstart recovery protocol (`skills/1-hourly/kickstart/SKILL.md:55-57,229-230`) and #1541 KS-08 require all associated ownership stopped; unknown holds. Define how the report consumes that full proof without becoming a recovery engine; missing checks must remain unknown/stale-candidate. Add manual cases for dead coordinator with live child/session and unknown child ownership; neither may report confirmed-stopped. Also specify precedence so an old log with live ownership follows the planned stale-candidate rule rather than the overlapping waiting rule.

2. **[Major] Final-QA freshness conflates check heads with landed heads and omits the canonical QA event.** Inputs 5 accepts latest `GATE:` as latest landed SHA, although `run_record.py:parse_record` returns gates with independent `target`, `sha`, and `verdict`; a task gate does not establish a landing. It also names `FINAL_QA:`/free-text mentions but does not explicitly consume the canonical `GATE: final-QA <sha> ... green` event. This can miss valid QA, mark an unlanded task head as a later landing, or treat failed QA as fresh. Specify successful canonical final-QA selection, separate actual landing evidence/current integration head from task gate SHAs, and return unknown when ordering/freshness cannot be established (including abbreviated-vs-full SHAs and a stale local origin/development). Manual checks should cover canonical green and red final-QA lines, a later non-landing task gate, and a real later landing.

3. **[Major] Shared escalation-file mtime is recency evidence, not invocation attribution.** Inputs 6 and verification 6 accept any shared file written after run start as this run's reason. A concurrent different relay can write cap-stalled after this run starts, so this report would quote the other invocation's reason as its own. #1541 KS-05 explicitly identifies the shared harness-root file as the problem and requires attribution to this invocation. Require a matching invocation key or equivalent exclusive provenance; mtime alone must stay unknown. Cover a different invocation writing a newer shared file, as well as the already planned old-file replay. Clarify the actual harness-root path rather than assuming target-root is the harness that produced the reason.

**Small governance correction:** Files Changed unconditionally schedules CHANGELOG and releases DB/dump edits. ROUTER/PDDA place routine views at reconciliation and disable branch changelog writes by default. Keep only explicitly necessary, policy-permitted task edits; name any applicable configuration exception.

**Evidence and limits:** Read the seeded plan, canonical parser, pr-minder assessment/main/receipts paths, kickstart ownership protocol, routing rules and PDDA contract directly. `gh issue view 1541 --repo HiQS-Labs/XYZ-forge --json body` exited 0 and returned v5 KS-04 (derived report), KS-05 (invocation-attributed reason), KS-08 (all associated processes stopped), KS-09 (pinned clone), and KS-13 (later landing invalidates QA). Graph tools were unavailable; no graph completeness claim is made. No executable fixture, suite, gate, or git command was run. This is plan QA, not implementation verification; the planned clone-run evidence remains outstanding.


## Producer Round 2 — All 3 Round 1 Majors + Governance Note Addressed

Updated `PROJECT/2-WORKING/GH-1547-KS04-KICKSTART-STATUS.md` to resolve every finding cleanly:

1. **Major 1 (`confirmed-stopped` full 4-part ownership proof & unambiguous precedence):**
   - `confirmed-stopped` now strictly requires ALL four ownership components verified stopped/clear: coordinator/owner (`--owner-state stopped` + dead `--owner-pid` if supplied), lock (`--lock-state clear` / absent `--lock-path`), associated builders/checks/push subprocesses (`--children-state stopped`), and detached sessions (`--sessions-state stopped`). Any `live` or `unknown` component refuses `confirmed-stopped`.
   - Unambiguous precedence: `confirmed-stopped` > `stale-candidate` (log age `>= stale_seconds`, taking precedence over `waiting`/`quiet` even if ownership appears live) > `quiet` > `waiting` > `unknown`.
   - Added explicit manual cases for dead coordinator + live child/session, dead coordinator + unknown child/session, and old log + live ownership (`stale-candidate`).
2. **Major 2 (Canonical `GATE: final-QA` + landed-head separation + prefix-safe SHA + `unknown` on unverified head):**
   - Consumes canonical `GATE: final-QA <sha> ... green|red` from `parse_record()["gates"]`; red final-QA is never fresh.
   - Separates actual landings (`MERGED` progress lines and explicit `--development-head`) from non-landing task `GATE:` lines (task gates never invalidate Final QA).
   - Prefix-safe SHA comparison (`>= 7` hex chars) handles abbreviated vs full SHAs; unverified local `origin/development` without `--development-head` returns `unknown` rather than falsely claiming `fresh`.
   - Added manual cases for green/red canonical `GATE: final-QA`, later non-landing task gate, real later landing, abbreviated-vs-full SHA match, and unverified head (`unknown`).
3. **Major 3 (Invocation-attributed stop reason; reject mtime-only shared files; explicit `--harness-root`):**
   - Replaced implicit `target-root` assumption with explicit `--harness-root <path>`.
   - Shared `.relay-scratch/escalation-reason` is accepted ONLY when matching `--invocation-id <id>` provenance exists (in payload or sibling `.meta.json`); mtime alone ALWAYS returns `stop_reason: "unknown"`, `attribution: "unattributable"`.
   - Added manual case for a different invocation writing a NEWER shared file after run start (must still return `unknown`).
4. **Governance note:** Removed unconditional `CHANGELOG.md` edit from Files Changed; ledger updates stay restricted to canonical `releases_app.py` registration.

Please review Round 2; if clean, append your review block and set `STATUS: Approved` and `NEXT: Done`.


## Reviewer Round 2 — codex

**Verdict: Needs changes (one remaining Major).** Round 1 findings 1 and 2 and the governance correction are addressed at plan level: full ownership attestations and precedence are explicit, canonical red/green final-QA is separated from actual landing evidence, and freshness requires a caller-verified head. The shared-file attribution fix still has one hole.

1. **[Major] Bind sidecar provenance to the exact reason payload, or reject sidecar-only attribution.** In plan Inputs 6.2, a sibling `<escalation-file>.meta.json` containing only matching `invocation_id` suffices to accept the independently mutable shared reason file. Counterexample: invocation A leaves metadata identifying A; invocation B overwrites the shared plain-text reason with `cap-stalled` without updating that metadata; querying A accepts B's reason. This is possible even without simultaneous reads: the existing writer in `utils/py/relay_drive.py:636-640` writes only the plain reason file. The same problem applies if payload provenance explicitly identifies B while a stale sidecar identifies A: the specified OR permits acceptance. This still violates invocation attribution. The smallest correction is to accept only a single structured payload containing both the matching invocation ID and reason, and treat sidecar-only evidence as unknown. Alternatively require sidecar identity plus a digest binding to the exact bytes read, and reject conflicting provenance; do not add a writer or state subsystem in KS-04. Extend the existing planned manual attribution cases with matching-A metadata + overwritten-B payload, and conflicting payload/metadata IDs; both must remain unknown. Existing exclusive per-run receipts/logs remain a valid source.

**Evidence and limits:** This is review of the revised plan, not implemented behavior. Directly read the complete seeded plan and the narrow existing writer. Source inspection command `sed -n '620,657p' utils/py/relay_drive.py` succeeded (exit 0 for the containing shell call); decisive source: `with open(reason_file, "w") as f: f.write(reason_str)`. No candidate implementation, fixture, test suite, phase gate or git command was executed. The counterexample above follows the plan's acceptance rule; it is not a claimed execution result. Graph project discovery found only the canonical Forge checkout, not this seeded worktree; its ready index generation is `2026-11-18T19:39:07Z`. Coverage reported the plan freshness missing and the writer metadata matching in that other checkout. Current seeded files were read directly; no graph completeness or current-worktree generation claim is made. Implementation and disposable-clone verification remain outstanding.
