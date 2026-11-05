# RELAY · GH-1340 Task 1 final QA: decisions 4-6 in PDDA.md, policy only
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-04.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1340-task1-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **task1-qa.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-04

### Artifact — task1-qa.md
````
## Diff (229e1be9..HEAD, excluding the rules relay thread)

```diff
diff --git a/CHANGELOG.md b/CHANGELOG.md
index a147daca..e38ec409 100644
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -1,5 +1,12 @@
 # Changelog
 
+## 2026-11-04 — GH-1340 Task 1: GH-1333 decisions 4-6 written into the rules (policy only)
+
+- `PROJECT/PDDA.md` now records that the merge step closes an issue only under two conditions (a reviewed whole-issue assertion, or a non-empty Acceptance checklist fully checked), and otherwise leaves it open with one reason comment.
+- It records that a ledger row is created when work starts, not at filing: selection into an actual batch counts as starting (D-b), and the existing "Queue / parked intake" rows stay as proposals (D-a). Until the #1340 cutover lands, row-writing intake is not used for new unstarted work.
+- Corrects the Lifecycle sentence that sent a closed, never-actioned capture to `4-MISC` and removed its pointer; closed captures follow the `stateReason` sweep. Section H's "who closes" now points at decision 4, and the coverage rule mentions #1339's in-flight promotion case.
+- Policy only; no code changed. Decision record: `decisions/2026-11-04-gh1333-closure-appeal-row-at-start.md`. Rule set with stable IDs: top of #1328. Rule-set review: Codex (GPT-6 Astra, medium), one round, nine findings accepted (`relay-system/2026-11-04/rules-sharpening-qa.md`).
+
 ## 2026-11-04 — GH-1341 todo-list and start-task close the loop on GitHub issues
 
 - `todo-list` has a new section 4, "Close the loop on GitHub". When a run ends, including on a halt or the 100-minute / 10-wake cap, it posts one comment to each issue the run touched. The comment covers what was done, the evidence, the decisions and why, what stays open, and the next step. A marker line (`<!-- todo-list closeout: <note-path> -->`) makes a rerun edit that comment instead of adding another. Tier A and B post with `gh` and record the URLs in the note; Tier C renders the text in chat to paste. A failed lookup or write is reported `unposted` or `unknown`, with no URL claimed. The step never closes or relabels an issue. Both run ends call it: section 3 step 4 and the watchdog wake prompt.
diff --git a/PROJECT/PDDA.md b/PROJECT/PDDA.md
index fd14f875..9c6f1ae1 100644
--- a/PROJECT/PDDA.md
+++ b/PROJECT/PDDA.md
@@ -256,7 +256,8 @@ stream lives in GitHub (machine-queryable state, labels, commit↔issue linkage)
 surface of record stays in `PROJECT/**`. This is the **issue-first SOP**; the bug-fix stance above
 states the principle, and this section owns the *format*. To prevent duplicate intake and forgotten
 work, every captured `GH-*.md` doc is also **parked immediately in `ROADMAP.md`** as a one-line queue
-entry until it is promoted, deferred, or closed.
+entry until it is promoted, deferred, or closed. **This is changing** (GH-1333 decision 6, 2026-11-04,
+policy only): the ledger row will be created when work starts, not at capture. See Lifecycle.
 
 **Floor (what needs an issue).** The operational test is **lines of code touched**: any change
 beyond a **2–3 line** fix opens a GitHub issue first, and its local plan doc is named after that
@@ -285,18 +286,34 @@ Lifecycle:
 
 - The `GH-` inbox doc is the **capture**, not the active-work doc. It carries no `## Status` table while
   it sits in `1-INBOX` (the inbox is the rough/untriaged bucket).
-- Capture time also adds a **one-line `ROADMAP.md` queue pointer** linking that inbox doc. This is a
+- **Today**, capture time also adds a **one-line `ROADMAP.md` queue pointer** linking that inbox doc. This is a
   temporary parking slot: it makes fresh intake visible to humans and automation before promotion,
   which is the duplicate-prevention guard.
+- **Decided, not yet implemented: the ledger row is created when work starts** (GH-1333 decision 6,
+  2026-11-04). Filing an issue no longer means a row. The row, and the PRS rating stored on it, appear
+  at pickup: `jog add`, `start-task`, or promotion to `2-WORKING`. Until then the rating proposal lives
+  in the issue body.
+  - **Selection counts as starting** (decision D-b): committing an issue to an actual execution batch or
+    marathon creates its row, on the primary checkout and before dispatch, or reuses an existing
+    proposal row and its rating. Ranking or shortlisting does not.
+  - **Existing rows stay** (decision D-a): the rows already in "Queue / parked intake" are proposals, not
+    a sign that work started. They are not migrated; revisit about a month after the cutover. This
+    exception covers only those rows.
+  - **Until the cutover lands** (#1340 Tasks 2, 3, 4, 6 and the Task 11 rating contract, as one change),
+    today's intake tools and the coverage check still write and require a row at capture. In that gap,
+    do not run row-writing intake (`hq park --create` / `--gh-issue`, `/file-xyz-bug`, `express`) for new
+    unstarted work: file the GitHub issue with its rating proposal in the body, and leave the capture
+    doc and row to pickup. Something else must take over the duplicate-prevention guard (#1340 Task 6).
 - When execution starts, **promote** it to `PROJECT/2-WORKING/` — keep the `GH-` prefix for provenance —
   and it must then satisfy the full active-doc contract (frontmatter, exact status table, QA gates if
-  phased), **carrying `gh_issue` forward**. The `ROADMAP.md` pointer is therefore required twice:
-  first as a queued parking entry at capture, then as an active-work ledger entry after promotion.
+  phased), **carrying `gh_issue` forward**. The `ROADMAP.md` pointer is therefore required twice today:
+  first as a queued parking entry at capture, then as an active-work ledger entry after promotion
+  (after the decision-6 cutover it is created once, at pickup).
   This is the concrete mechanism behind "GitHub issues are not a substitute for the local active-work
   doc once execution starts" (bug-fix stance above).
-- If a captured issue is never actioned it ages out of `1-INBOX` like any other untriaged note; if it is
-  closed without work, the completion sweep (next item) moves the doc to `PROJECT/4-MISC` and removes its
-  queue pointer from `ROADMAP.md`.
+- If a captured issue is never actioned it ages out of `1-INBOX` like any other untriaged note. If it is
+  closed, the completion sweep (next item) places the doc by the issue's `stateReason`, whether or not work
+  started; an existing ledger pointer is repointed, not removed.
 - **Completion moves come from one sweep, keyed on current issue state** (GH-1333). The sweep reads the
   issue state of every `GH-<n>-` doc in `1-INBOX` and `2-WORKING`. The destination comes from the
   closed issue's GitHub `stateReason`:
@@ -311,6 +328,13 @@ Lifecycle:
   `wave_reconcile.py --pr N`. It runs from the steps that already run: the merge-cleanup batch and
   `start-marathon` Step 2. It never closes an issue. **Until it lands**, `wave_reconcile.py --pr N`
   still moves docs on a closing-keyword merge, and `issue-doc-sync` (H) flags what that misses.
+- **Closing an issue at merge** (GH-1333 decision 4, 2026-11-04; decided, not yet implemented, #1340
+  Task 7). The merge step closes an issue only when **either** a recorded independent review assertion
+  says the delivered lane covers the whole issue, **or** the issue has a non-empty `## Acceptance`
+  checklist with every item checked. Otherwise it leaves the issue open with one comment, "delivered, left
+  open because <reason>". A mention is never authority to close. Closing text never uses a negated keyword:
+  "does not close #N" still closes #N, so write `Refs #N` and "leaves #N open". **Until Task 7 lands**, a PR
+  writes a closing keyword only when one of the two conditions holds.
 
 A foreign-repo issue (not `origin`) is the rare exception: the `source:` URL disambiguates it, since the
 bare `GH-<number>` only guarantees uniqueness within the canonical repo.
@@ -502,7 +526,8 @@ Minimum behavior:
     to avoid.
   - **(c)** doc is in `3-COMPLETED` but the issue is **OPEN** -> `warn`. Since GH-1333 the issue's state,
     not the folder, says whether work is done. So (c) means either the doc moved early or the issue was
-    never closed after delivery. It is a prompt to whoever owns closing (still to be decided in #1333),
+    never closed after delivery. It is a prompt to whoever owns closing (the merge step, under the two
+    conditions of GH-1333 decision 4; see Lifecycle),
     not evidence that the work is done; neither this check nor the sweep closes the issue.
     A doc in `3-COMPLETED` with a **CLOSED** issue is the fully reconciled end state: no finding.
 - `warn` (never `error` — does not block, even in `full`, mirroring `pdda.sh changelog`); **flag-only**,
@@ -1006,10 +1031,14 @@ Coverage rule:
 - every active doc in `PROJECT/2-WORKING` must be reflected here by a pointer (a one-line ledger entry
   that links it), so the ledger never falls behind the working set. A working doc that legitimately
   should not appear opts out with `roadmap_exempt: true` in its frontmatter. This is the inverse of the
-  "no detail leaks in" rule above: nothing active goes *missing from* the roadmap either.
+  "no detail leaks in" rule above: nothing active goes *missing from* the roadmap either. A doc that Jog
+  promoted on an execution branch counts as covered while the ledger still points at the same file name in
+  `PROJECT/1-INBOX/` and that inbox file is gone (GH-1332, #1339): Jog writes no ledger on a lane branch, and
+  the pointer is corrected when the issue is reconciled closed.
 - every captured GitHub issue doc in `PROJECT/1-INBOX/GH-*.md` must also be reflected here as a
   one-line **queued / parked** pointer until it is promoted, deferred out, or closed, so intake cannot
-  quietly disappear and later be duplicated.
+  quietly disappear and later be duplicated. GH-1333 decision 6 makes a capture without a row the normal
+  state of unstarted work; until the #1340 cutover changes this check, it still applies.
 
 How this is enforced (so it cannot quietly rot in either direction):
 - **deterministic (no leak in)** — `pdda.sh roadmap` errors on task checklists / `### Checklist` /
diff --git a/decisions/2026-11-04-gh1333-closure-appeal-row-at-start.md b/decisions/2026-11-04-gh1333-closure-appeal-row-at-start.md
new file mode 100644
index 00000000..d81df02f
--- /dev/null
+++ b/decisions/2026-11-04-gh1333-closure-appeal-row-at-start.md
@@ -0,0 +1,17 @@
+# Closing at merge, the appeal axis, and rows at work start — GH-1333 decisions 4-6
+
+Recorded 2026-11-04. The operator decided the three questions the 2026-11-03 record left open, plus two follow-ups raised by QA of #1340. The canonical rule text is in [PROJECT/PDDA.md](../PROJECT/PDDA.md), under "GitHub issue intake" (Lifecycle) and section H. The full operator-approved rule set, with stable IDs, is at the top of [#1328](https://github.com/HiQS-Labs/XYZ-forge/issues/1328) (G4, G5, G6, G6a, G6b and interim rules C1-C3).
+
+4. **The merge step closes an issue under two conditions** (rule G4): a recorded independent review assertion that the delivered lane covers the whole issue, or a non-empty `## Acceptance` checklist with every item checked. Otherwise it leaves the issue open with one "delivered, left open because <reason>" comment. A mention is never authority; never use a negated close keyword.
+5. **The appeal axis stays as it is** (rule G5): neutral 50 unless the operator supplies a value. 91 of 112 recent ratings are 50, so appeal adds a near-constant to the sum; that is accepted.
+6. **A ledger row is created when work starts, not at filing** (rule G6). Filing no longer means a row; the row and its stored rating appear at pickup (`jog add`, `start-task`, promotion to `2-WORKING`). Until then the rating proposal lives in the issue body.
+   - **D-b** (rule G6b): selection means committing an issue to an actual execution batch or marathon; its row is created on the primary before dispatch, or an existing proposal row is reused with its rating.
+   - **D-a** (rule G6a): the 69 existing "Queue / parked intake" rows stay as proposals; no migration now; revisit about a month after the cutover.
+
+Why: "a row exists" was standing in for "someone is working on this", and it was created at filing. 208 of 300 open issues had no row, so the backlog looked unregistered when it was simply unstarted, and admission rejected issues for a missing row instead of a missing plan. Ratings stored at filing were mostly placeholders.
+
+Status: **policy decided, not yet implemented.** Today's intake tools and the coverage check still write and require a row at capture. The change lands as one cutover (#1340 Tasks 2, 3, 4, 6 and the Task 11 rating contract, with Task 5 as the #1298 rollout instruction). Closing at merge is #1340 Task 7. Until they land, interim rules C1 (closing keywords) and C2 (no row-writing intake for new unstarted work) apply.
+
+Expected signal: after the cutover, new issues filed through intake have no row until pickup, the inbox coverage check stays green for them, and the admission census stops reporting "no ledger row" as a rejection reason. After Task 7, every merged lane either closes its issue under one of the two conditions or leaves exactly one reason comment. Revisit if issues go missing between filing and pickup, or duplicates appear.
+
+Rollback: the policy is text. Revert this record and the PDDA.md edits. Nothing in the code changed with this record.
```
````
- Definition of Done (from #1340 Task 1): decisions 4-6, D-a and D-b are in `PROJECT/PDDA.md` (Lifecycle, the intake and ledger contract, section H), with a decision record under `decisions/` and a CHANGELOG entry, all marked policy-only; **no text claims behaviour the code does not yet have.**

**Operational envelope.** Docs-only change in a local single-operator repo. Read the checkout (`origin/development` 229e1be9 plus this diff). The operator-approved rule set it implements is at the top of issue #1328 (G4, G5, G6, G6a, G6b, C1, C2); its text is also in `relay-system/2026-11-04/rules-sharpening-qa.md` (artifact plus the Producer turn). Run no git, no suites. Edit only this relay file.

**Questions.**
1. **Overclaims.** Does any added sentence state as current behaviour something the code does not do? Check against `utils/pdda/pdda.sh` (`check_roadmap_coverage`), `utils/hq/hq.sh` (park), `utils/py/wave_reconcile.py` (closing behaviour), `utils/py/jog_run.py` (promotion).
2. **Fidelity.** Does the text match G4, G6, G6a, G6b, C1 and C2 as approved, without widening or narrowing them?
3. **Contradictions inside PDDA.md.** Does any untouched sentence elsewhere in `PROJECT/PDDA.md` now contradict the new text (search for "parked", "queue pointer", "closes", "4-MISC")? Cite line numbers.
4. **Anything missing** from Task 1's done condition.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
