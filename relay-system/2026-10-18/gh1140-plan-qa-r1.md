# RELAY · GH-1140 plan QA round 1 — verify the merge-batch stale-state pattern at HEAD
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 3

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
6. **Commit only the relay file** (`relay(gh1140-plan-qa-r1): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1140-BATCH-STALE-STATE.md` (the plan + Phase A verification verdict table, committed on this branch)
- Code under verification (same worktree, at this branch's HEAD): `skills/2-daily/merge-cleanup/scripts/batch_record.py`, `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- **Round 1 scope (operator directive): verify the bug PATTERN is actually valid before any fix is designed.** Do not grade the fix design beyond "does it follow from the verified shapes"; the design gets its own pass in a later round if the pattern survives.
- Definition of Done (round 1): every row of the plan's Phase A verdict table is independently confirmed or overturned with `file:line` citations at this HEAD; the three-mechanism decomposition is confirmed or corrected; any claimed shape that is already fixed at HEAD is named with its fixing line; any ADDITIONAL stale-captured-state shape the sweep finds is reported with a citation. VERDICT PASS requires the table to be accurate as written or amended by findings that the Producer accepts.

## Context and questions (round 1 — pattern validity only)

Operational envelope: a local developer CLI skill (`/merge-cleanup`) that lands multi-PR batches. Commensurate complexity applies: no enterprise fail-safes are being requested or should be demanded. The repo forbids new test suites (AGENTS.md GH-831) — do not ask for any.

Base: this branch's HEAD (cut from `origin/development` @ `4fd5dca8`). The plan's Phase A table claims, at these lines:

1. `batch_record.extend()` (batch_record.py:79-87) appends only unknown PRs and never refreshes `files`/`soft` for known ones, while `finalize_sweep_inputs()` (:282-295) computes `shared_files` from the stored rows — so a resume after a branch change misses new shared files (#1075, #1073). **Confirm or overturn.**
2. `batch_record.save()` (:89-93) locks the write only; callers mutate retained in-memory dicts, so a stale snapshot wins last-writer-wins and can drop another writer's whole outcome row (#1072), with GH-1074's guards (:144 merge-never-downgrade, :95-102 `landed()` backstop) protecting only two specific consequences. **Confirm or overturn; state precisely which consequences remain unprotected.**
3. `select_batch()` (merge_cleanup.py:1739-1763) performs the `need_qa=True` lookup only inside the `args.resume` branch (:1745-1748); a plain `--execute` rerun with an empty queue returns None and main() exits 0 at :1729-1736 while a QA-pending batch exists (#1084 Major). **Confirm or overturn.**
4. batch_record.py:312 emits a sweep command containing literal `<tmp>`, which the shell parses as a redirection (#1084 minor). **Confirm or overturn.**
5. `execute_pr_merge()` (merge_cleanup.py:200-239) returns bool and discards the merge OID it already verified; the caller (:1313-1316) re-fetches and records `""` when that refresh fails (#1084 minor). **Confirm or overturn.**
6. `hold_label()` (merge_cleanup.py:315-321) scans labels only — never the title — while the original #441 near-miss carried its "do not merge" marker in the TITLE (#444 partially fixed: labels+draft landed at :59/:1113-1122/:1301-1304). **Confirm or overturn.**
7. #944's batch-issue protocol is delivered by #1069 with threshold 2+ (merge_cleanup.py:1754) vs the asked ≥3. **Confirm; note anything material from #944 that is genuinely missing.**
8. **Sweep question:** reading the two scripts whole, is there any OTHER shape of captured-once state trusted across resume/rerun, or any additional path that bypasses the exit-4 QA gate, that the plan missed? Report with `file:line` or state "no additional shape found" explicitly (`swept file: yes` covers this).
9. Decomposition check: the plan reads the class as three mechanisms (captured-once state never refreshed; QA-pending invisible outside --resume + non-transactional saves; title veto gap). **Is that the right decomposition, or is there a simpler/more accurate one?**

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: The bug family survives source review, but Phase A needs the corrections and additional recovery/eligibility shapes below before it is an accurate verification contract. This is pattern QA only; Phase B's save algorithm has not been approved.
swept file: yes

Read the entire plan and both scripts (batch_record.py:1-334; merge_cleanup.py:1-1792). Below, **B** means `skills/2-daily/merge-cleanup/scripts/batch_record.py`; **M** means `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`. All citations refer to this seeded checkout. Static traces establish mechanisms; no runtime reproduction, suite, executable fixture, or git command was run.

- [Pass] **#1075:** confirmed in source. B:81-85 ignores every known PR; B:292-295/310 calculates overlap from retained files. M:1751 passes fresh discovery to that function. Thus a known row with files `["a"]` stays `["a"]` when discovery now says `["a","b"]`, hiding overlap with another landed PR touching `b`.
- [Pass] **#1073:** same persisted metadata seam, with a qualification: B:62-64 captures **title and hard dependencies too**, not just files/soft reasons. B:298-306 does re-read per-PR conflict files; that part is already refreshed at HEAD. Also, within a single invocation, discovery precedes repair (M:1593/1675 versus M:1209-1275); B:292-295 still consumes the original planned files after repair. Refresh-on-resume alone does not establish that repaired-head file metadata is current. Amend the row to distinguish discovery refresh on resume from post-repair refresh within the run.
- [Pass] **#1072 mechanism:** B:89-92 locks only whole-snapshot replacement; the delegated writer serializes the supplied dict and atomically replaces the file (`skills/2-daily/merge-cleanup/scripts/attempt_record.py:117-122`). B:143-152 mutates memory before that lock. Two readers of `outcomes={"1":{"status":"unattempted"},"2":{"status":"unattempted"}}` can save a merge for #1 and then overwrite it with the second reader's old #1 row while updating #2. Normally it loses the **new outcome fields**, replacing them with `unattempted`; a whole PR row disappears only if absent from the stale snapshot (e.g. another writer extended the batch). Correct that wording. B:144 protects a merged status only when already present in **that dict**; B:95-102 recovers a missing landing-order entry only when merge evidence survives in outcomes. Neither protects erased outcomes, stale verdict/covers, planned rows, issue metadata, sweep inputs, OID or reconcile fields (B:146-149 can overwrite the latter even on a merged row). QA can clear if the overwrite erases the only landing evidence. Concurrent runtime reproduction: [Unverified — needs clone run].
- [Pass] **#1084 Major:** confirmed source path: empty queue + execute + no resume returns None at M:1754-1755, never performs M:1746-1748, and skips M:1729 to return 0 at M:1736. This also applies to a one-PR queue that does not adopt an old batch; a new 2+ batch can mask an older pending batch when the new batch has no landings. GH-1074's fallback **is present** at M:1748-1749 but only within resume. M:1681-1683 preserves exit 2/3 precedence; those hard-stop/partial outcomes are not success bypasses.
- [Pass] **#1084 command:** B:312 emits literal `<tmp>`; this is a syntax error here, not merely a usable redirection. Non-executing probe: `bash -n <<'SH'
git clone --no-local /example/primary <tmp> && cd <tmp> && bash validate.sh --parallel 4
SH` → exit **2**, decisive output `syntax error near unexpected token '&&'`. No clone or gate was executed.
- [Pass] **#1084 OID:** M:224-228 and M:233-236 verify an OID then return only True; M:1314-1316 queries again and stores empty on error. B:288-307 selects unknown range/full gate when OIDs are missing, so that degradation is already guarded. Describe this as **discarded verified evidence followed by a fallible re-query**, rather than captured-once state retained across resume.
- [Should] **#444 needs a more complete verdict:** the title veto is absent, but adding a title scan only to hold_label cannot work for live eligibility: M:244-245 does not fetch `title`. Moreover, the table's “re-check :1301-1304” rechecks **draft only**; it does not recheck labels. Labels are checked once at M:1117, before polling/repair/gating. Correct the table and carry these concrete inputs into later design QA.
  Observed input: M:245's JSON field list omits title; M:1297-1311 accepts a final response with unchanged head, isDraft=false, and labels=[{"name":"do not merge"}] after the earlier label check passed.
  Affected scope: title-marked PRs, and hold labels added between the first eligibility check and final merge eligibility.
  Falsifier: later clone verification should supply a title-only “DO NOT MERGE” PR and a PR acquiring that label during gating; neither should reach execute_pr_merge. An unmarked, non-draft control should remain eligible.
  Static probe (exit **0**): `python3` AST query counting title literals in hold_label, printing refresh_pr's JSON string, and counting find_unfinished references in main → `hold_label title literals: 0`; `refresh_pr JSON: number,state,isDraft,mergeable,headRefOid,headRefName,baseRefName,labels,mergeCommit,url`; `main find_unfinished calls: 0`. These measurements corroborate M:244-245/315-321/1729. Exact probe command (environment above; standard input only):

  ```sh
  python3 - <<'PYPROBE'
  import ast
  from pathlib import Path
  p=Path("skills/2-daily/merge-cleanup/scripts/merge_cleanup.py")
  t=ast.parse(p.read_text())
  f={n.name:n for n in t.body if isinstance(n,ast.FunctionDef)}
  print("hold_label title literals:",sum(isinstance(n,ast.Constant) and n.value=="title" for n in ast.walk(f["hold_label"])))
  print("refresh_pr JSON:",next(n.value for n in ast.walk(f["refresh_pr"]) if isinstance(n,ast.Constant) and isinstance(n.value,str) and n.value.startswith("number,state,")))
  print("main find_unfinished calls:",sum(isinstance(n,ast.Attribute) and n.attr=="find_unfinished" for n in ast.walk(f["main"])))
  PYPROBE
  ```

  Historical #441 title incident: [Unverified — no accessible issue evidence]; `gh issue view 441 --repo HiQS-Labs/XYZ-forge --json number,title,body,state` exited **1**, `error connecting to api.github.com`. Keep the current-code finding separate from that historical assertion.
- [Pass] **#944:** the requested protocol is represented: issue before loop (M:1675/1680,1756-1757); marked sequence/sweep/verdict block (B:161-200), caller sections (B:32-39), verdict entry point (M:1766-1788). Threshold is 2+ (M:1754); this is an explicit subsequent operator decision, not an unexplained deviation (`PROJECT/3-COMPLETED/GH-1064-MERGE-BATCH-ISSUE-QA.md:23-31`). Carry-over dual sink remains caller-owned and present in `skills/2-daily/merge-cleanup/SKILL.md:435-442`; absence of script automation for it is not missing delivery. No additional material implementation omission found for #944's stated protocol. Historical delivery by PR #1069 is supported by the local #1075 capture's merge note (`PROJECT/2-WORKING/GH-1075-BATCH-RESUME-STALE-FILES.md:35-37`); remote issue state/dogfood completion was not independently checked.

- [Should] **Additional stale outcome recovery shape:** resume trusts a persisted unattempted row even when its PR merged after the last save. Discovery is OPEN-only (`skills/2-daily/merge-cleanup/scripts/toposort_prs.py:33-35`), and resume only extends that discovery (M:1746-1752); no live recovery of absent planned PRs occurs. If a queued PR turns MERGED during this invocation, M:1123-1127 records `closed: merged outside this run` without the returned merge OID. B:100 excludes that status; B:114 treats it as terminal. Add this shape to Phase A and explicitly disposition recovery of known planned PRs against live merged evidence.
  Observed input: a batch's only landed PR has persisted `{"status":"unattempted"}` because execution stopped after remote merge at M:1311 and before save at M:1315; on resume discovery excludes it. Alternatively, a queued PR's live refresh returns `state="MERGED", mergeCommit={"oid":"abc"}` at M:1123.
  Affected scope: planned batch PRs whose remote merge is absent from persisted landing evidence; not arbitrary historical PRs.
  Falsifier: in a disposable clone, resume that persisted batch with the planned PR positively reported MERGED; expected landing/OID recovery and QA pending rather than a successful no-QA result. CLOSED without a merge must not invent a landing. Runtime recovery proof: [Unverified — needs clone run].
- [Should] **Additional gate bypass under an existing mode:** M:1742-1743 returns None unconditionally for `--execute --teardown-only`, so M:1729 cannot surface an existing batch's QA debt even with `--resume`. Record this as another instance of the pending-batch selection gap and state the intended mode boundary. Scan-only/prs-only/policy display and verdict recording have explicit narrower purposes; I am not requesting that every successful diagnostic command exit 4.
  Observed input: args.execute=true, args.teardown_only=true, args.resume=true, with a persisted QA-pending batch.
  Affected scope: executing teardown through the ordinary Phase 6 completion path.
  Falsifier: clone run of that input should surface pending QA at final status if the plan's “every executing run” contract applies; absent QA debt should still exit 0.

- [Should] **Correct the decomposition:** use separate mechanisms: (1) stale planned metadata (#1075/#1073, including in-run repair), (2) lost durable updates (#1072), (3) incomplete QA-debt discovery (#1084 Major/teardown mode), (4) discarded verified OID (#1084 minor), (5) incomplete/live-stale veto inputs (#444). The shell placeholder is a separate command-generation defect. Three broad work families are fine, but combining (2) and (3) does not make them one mechanism, and (4) is evidence loss rather than never-refreshed state. Add the observed unrecorded-merge recovery seam above; do not claim a single save merge or resume refresh resolves it. This requests a plan classification correction, not a new subsystem.  [Unverified — no citation]

Pre-existing defects were found and are explicitly reported above (title field omission, late hold-label gap, unrecorded/external merge recovery, teardown-only QA visibility). No additional captured-state/exit-4 shape found beyond these and the Phase A rows. No new suites, guards, or runners requested. Design review and runtime falsifiers remain for later authorized turns.

Handing off to Producer (claude-a) — accept or disposition these Phase A corrections and update the artifact; then request the next review turn.

### Producer · Round 1 · claude-a — adjudication of all r1 findings

All graded items adjudicated; **all accepted** (confirmations folded as corrections, all four [Should]s implemented as plan changes). No declines.

- #1073 qualification -> Phase A row amended: title/hard also stale; conflict-files-refresh noted; in-run post-repair window added.
- #1072 wording -> corrected: typical loss reverts fields to unattempted; whole-row loss only when absent from the stale snapshot; unprotected-field list (verdict/covers/planned/issue/sweep/OID/reconcile) recorded.
- #1084 Major extensions -> Phase A amended (one-PR queue, new-batch masking, teardown-only invisibility); Phase B item 3 redesigned as a batch-adoption-independent final-status step covering all four paths.
- tmp command -> recharacterized as a syntax error (bash -n exit 2 probe adopted).
- OID -> recharacterized as discarded-verified-evidence + fallible re-query (Phase A); Phase B item 4 keeps the verified OID.
- #444 widening -> accepted with your falsifiers adopted verbatim as acceptance controls (title-only DNM PR; label-acquired-during-gating PR; clean control stays eligible). Phase B item 5 now covers all three gaps (fetch title, scan title, re-check labels at final eligibility).
- NEW recovery shape -> accepted; Phase A row added; Phase B item 6 (positive MERGED+OID only; CLOSED-without-merge stays terminal; refresh failure defers).
- NEW teardown-only shape -> accepted into Phase A and Phase B item 3.
- Decomposition -> corrected to your five mechanisms + command defect + recovery seam (plan "Pattern verdict" paragraph rewritten).
- #944 -> closed-as-delivered wording now cites the recorded operator decision (GH-1064 doc) per your citation.

Artifact updated in commit "plan(GH-1140): fold r1 plan-QA corrections". Runtime falsifiers remain deliberately deferred to the implementation verification phase (clone runs + manual checks under TESTS-RESULTS) — this round is pattern QA only, per the operator directive.

**Requesting round 2:** confirm the amended Phase A table is now an accurate verification contract and the Phase B mechanism mapping follows from it (design-grade review of the fix implementations themselves comes at final QA, after code exists).

handing off to Reviewer (codex) — take your turn.
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->

