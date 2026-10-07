# RELAY · GH-983 final QA round 3: workhorse SKILL.md + evidence-gated Stop hook
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-06.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 3

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
6. **Commit only the relay file** (`relay(gh983-final-r3): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/2-daily/workhorse/SKILL.md` and `skills/2-daily/workhorse/stop-hook.sh` at
  HEAD (b483cb11, branch `fix/workhorse-codex-continuation`, PR #984). Supporting receipts:
  `TESTS-RESULTS/2026-10-06+GH-983/hook-evidence-probe.json`, `SUMMARY.md`, `CHANGELOG.md` (GH-983 entry).
  Prior approved rounds: `relay-system/2026-10-06/gh983-final.codex.md` (SKILL.md r2),
  `gh983-claude-compat.codex.md`. This round QAs the two commits that followed those approvals:
  94097d04 (code-review fixes to SKILL.md) and b483cb11 (Stop hook evidence gate).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-06

### Context

GH-983: workhorse could stop when its checklist had no open `- [ ]` boxes even though required
execution or operational evidence was missing. The SKILL.md contract (Rung 0 "Shared continuation and
completion contract") was approved in prior rounds. Since then:

1. **94097d04** fixed seven `/code-review` findings: the verbatim recital (point 5) now requires evidence
   before ticking and an outcome audit before the single report; `[!]` again covers an awaited operator
   decision, unknown target, or Rung 5 Costly/One-way-door confirmation; the operational-gate bullet is
   the general measurement rule (GH-983's 1/1/1 fixture enumeration removed); evidence-before-ticking
   cross-references Rung 6 steps 2–3 instead of restating them; the structured per-rung completion
   report was restored with an outcome-audit line; Rung 6 step 5 names each parent's real re-entry
   mechanism (`merge_cleanup.py --resume`, `releases jog resume <GH-NUM>`, marathon/10days lane re-fire).
2. **b483cb11** changed `stop-hook.sh` deliberately (it was byte-frozen in earlier rounds): it now also
   blocks a stop while any `- [x]` line lacks an `evidence:` pointer (regex `evidence:\s*\S`, case-
   insensitive), and its hand-back message names `[!]` only, dropping the `[-] (parked)` escape that
   contradicted the contract (GH-987). SKILL.md Rung 0 documents the line format
   `- [x] <item> — <acceptance check> — evidence: <path, commit, URL, or quoted output>`.

**Operational envelope:** a Claude Code Stop hook (bash + inline python3, fail-open on any error) plus a
markdown skill contract read by Claude and Codex. Local developer tooling, single clone. Commensurate
complexity applies: do not ask for a semantic evidence verifier, a test suite, a new gate, or
cross-session state. GH-831: a new `test/` file or `validate.sh` entry would itself be a finding.

**Non-goals:** proving end-to-end Claude session reliability; Codex runtime enforcement (the contract
says there is none); changing `install.sh` or the frontmatter hook wiring.

### Questions (answer each, cite file:line)

1. **Hook correctness.** Read `stop-hook.sh` in full. Does it still fail OPEN on every error path
   (bad JSON, bad session id, missing file, missing python3/git)? Is there any input that makes it
   block when it should not, or exit non-zero? Check specifically: a checklist line such as
   `- [x] W1 fix evidence: handling in parser` (the word "evidence:" inside the item text) and a
   line with leading indentation. State whether each is acceptable for a syntax gate.
2. **Hook/contract consistency.** Compare the hook's block message to SKILL.md Rung 0 (`[x]`/`[-]`/`[!]`
   definitions, lines ~80–90) and the Serial Execution Loop + "Stop only for…" bullet. Is there any
   remaining sentence in either file that lets an agent escape required scope via `[-]`, or that
   contradicts the other file?
3. **Recital vs contract.** Does the verbatim recital (SKILL.md "Recite this" block, point 5) now agree
   with "Audit before ending" and Rung 6 step 4? Quote the clause if it does not.
4. **Blocker scope.** Does the restored `[!]` enumeration (Serial Execution Loop; "Stop only for…")
   leave a sanctioned way to stop at a Rung 5 Costly/One-way-door confirmation gate without proceeding
   past it? Is anything now too permissive (a recoverable local failure that could be mislabelled `[!]`)?
5. **Parent re-entry.** Rung 6 step 5 names `merge_cleanup.py ... --execute --resume`,
   `releases jog resume <GH-NUM>`, and marathon/10days lane re-fire. Verify each against
   `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, `skills/2-daily/jog/SKILL.md`, and
   `skills/2-daily/start-marathon/SKILL.md`. Flag any command that does not exist as written.
6. **Receipts honesty.** Does `hook-evidence-probe.json` + `SUMMARY.md` + the CHANGELOG entry describe
   the hook change truthfully, including that `stop-hook.sh_preserved` is now false and that the hook
   checks evidence was *recorded*, not that it is *true*? Does `claude-compatibility.json` need a note
   or is the provenance.jsonl supersession line sufficient?
7. **Over/under-engineering.** Is the `evidence:` regex the right size for this envelope? Flag anything
   in either commit that is speculative, duplicated, or that the skill text already said elsewhere.
8. **Pre-existing defects.** Sweep both files end to end (`swept file: yes|no` is mandatory). Anything
   in the untouched text that the new contract now makes wrong or ambiguous?

- Definition of Done: every question above answered with a citation; no `[Blocker]`; any `[Should]`
  carries `Observed input:` / `Affected scope:` / `Falsifier:`; VERDICT PASS sets `STATUS: Approved`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

swept file: yes
VERDICT: FAIL
Basis: Both artifacts swept end to end. No Blocker found; one Should in parent recovery routing needs a narrow wording correction. Hook syntax and the shared completion contract otherwise agree. Review is static plus pure regex/hash probes; executable hook/error-path and harness runs remain **[Unverified — needs clone run]**, not claimed as freshly executed here.

- **[Pass] Q1 — Hook/error-path source review.** `stop-hook.sh:12–25` handles missing Python, invalid JSON/non-object JSON, and invalid session IDs; `:29–35` catches missing git/subprocess errors; `:47–51` handles missing/unreadable checklist files. `:15` and `:71` force shell exit 0 even if inline Python fails. These are source conclusions, not fresh execution of all error cases. Missing git can still use `CLAUDE_PROJECT_DIR` (`:36–37`) and legitimately block on that root's checklist; fail-open applies when no usable root/checklist remains. No unexpected nonzero path identified in the source. `:49` strips indentation before `:52–53` classify lines. `- [x] W1 fix evidence: handling in parser` passes because `:40` searches anywhere on the line; acceptable for this explicitly limited syntax gate, which does not validate evidence semantics (`:10`, SKILL.md:87–88). Leading indentation is also acceptable and does not hide an unevidenced tick. Fix: none.
  Probe command: `python3 -c 'import re; rows=["- [x] W1 fix evidence: handling in parser","    - [x] W1 done","    - [x] W1 done — evidence: abc1234","- [x] W1 done — evidence:"]; print([bool(re.match(r"-\s\[[xX]\]",s.strip()) and not re.search(r"evidence:\s*\S",s.strip(),re.I)) for s in rows])'` (stdout redirected to `$TMPDIR/regex-control.txt`). Exit 0; decisive output `[False, True, False, True]`, where True means unevidenced. An additional AST read extracted the actual two regex constants and returned the same classifications, without executing the hook or invoking git. The missing/empty-marker controls go red, while an appended pointer goes green.
- **[Pass] Q2 — No remaining required-scope parking escape found in either swept file.** Hook `:60–67` asks for verified evidence or reopening, and offers `[!]` with an exact blocker; it expressly says `[-]` is never required scope. SKILL.md:81–83 defines the marks; `:91`, `:104–108`, `:114–123`, `:330–341`, and `:388` require continued feasible work and truthful unfinished state. The hook intentionally permits `[-]` syntactically while the contract restricts its meaning. Fix: none.
- **[Pass] Q3 — Recital agrees with audit/report contract.** SKILL.md:44 says “tick the item in the run checklist only with acceptance evidence” and “then audit the result against the requested outcome before reporting once at the end”; `:104–108` restores missing required work, and `:315–328` supplies the audit/report structure and unfinished-state report. Fix: none.
- **[Pass] Q4 — Confirmation gates can stop without authorizing mutation.** SKILL.md:91 and `:114–119` explicitly permit an awaited operator decision or Costly/One-way-door confirmation as `[!]`, while excluding recoverable local failure and requiring independent work first. Rung 5 `:241–245`, `:257–276` blocks unresolved targets, unknown preservation carriers, unconfirmed permanent loss, and unknown remote execution. `:120–123` preserves approvals and retry limits. No textual sanction to label ordinary recoverable local failures `[!]` found. Fix: none.
- **[Should] Q5 — Select parent recovery by actual state instead of prescribing `resume`/lane re-fire for every repair.** Both literal CLI spellings in SKILL.md:335–336 exist: merge_cleanup.py:1178–1191 declares all four shown flags; jog/SKILL.md:57–64 documents `releases jog resume <GH-NUM>`. But existence does not establish that they resume a repaired build. jog/SKILL.md:129–138 explicitly distinguishes receipt reconciliation (`resume`), same-head gate retry (`retry-gate`), and real rebuild (`retry-build`). SKILL.md:337's “lane re-fire described in that skill's SKILL.md” also has no recovery procedure in the referenced start-marathon skill: its `:75–78` forbids re-firing parked lanes, `:353–354` requires replanning through the standing queue, and `:383–392` separates preparation from confirmed firing. 10days/SKILL.md:482–512 describes wave dispatch and a red-gate stop, not a universal re-fire recovery verb. The adjacent “Respect parent safety/retry limits” prevents an outright authorization bypass but leaves the positive instruction inaccurate.
  Observed input: the actual instruction SKILL.md:332–338 routes parent recovery immediately to `releases jog resume <GH-NUM>` / “lane re-fire”; the documented failed-build input in jog/SKILL.md:137–138 instead requires `retry-build`, and the documented parked-lane input in start-marathon/SKILL.md:78 forbids re-fire.
  Affected scope: Rung 6 parent re-entry after interrupted execution, repaired gate/build failures, or held/parked marathon lanes; direct invocation and completion semantics remain unchanged.
  Falsifier: a valid terminal jog receipt should still use `resume` without a builder turn; a same-head gate failure should use the parent's `retry-gate` procedure; a genuinely failed build should use its authorized `retry-build` procedure; a parked marathon lane must remain held and follow the standing queue/confirmation boundary. If the parent documentation instead specified the current universal resume/re-fire instruction for these states, this finding would be unnecessary.
  Concrete fix: retain merge-cleanup's supported command, describe jog's state-specific recovery verbs with its Recovery Verbs reference, and replace the universal marathon/10days “lane re-fire” assertion with their actual authorized recovery/queue procedure. Do not add machinery or tests. Runtime execution of these recovery paths: **[Unverified — needs clone run]**.
- **[Pass] Q6 — Receipts distinguish historical preservation from the changed hook.** hook-evidence-probe.json:2,18–20 states supersession, recorded-versus-true limits, and `stop-hook.sh_preserved: false`; SUMMARY.md:15 expressly supersedes its earlier preservation claims and the old hook_checks. provenance.jsonl:15 supersedes compatibility's old hook checks/preserved flag; claude-compatibility.json:2,22–24 remains a historical receipt. No rewrite of that historical JSON needed. CHANGELOG.md:9–14 accurately names the changed hook and avoids a reliability-gain claim. A read-only SHA-256 probe exited 0 and printed `hook_sha256=61be22957013d9d484b9f23f62be84891c5f01cc29813ab990122e6108577876 receipt_matches=True`, matching hook-evidence-probe.json:4. Fix: none.
- **[Pass] Q7 — Gate is commensurate.** Two regex constants and one additional list classification (`stop-hook.sh:39–40,53,58–62`) extend the existing scanner without semantic verification, new state, dependencies, or a new suite. SKILL.md:81,87–88 supplies the needed format/limitation; the recital (`:44`) and final report (`:315–328`) serve separate invocation/reporting roles rather than duplicate implementations. Apart from Q5's routing assertion, no speculative machinery or unnecessary duplication found. Fix: none.
- **[Pass] Q8 — Full sweep completed.** Read SKILL.md:1–389 and stop-hook.sh:1–71, including unchanged frontmatter, preservation/retry rules, shortcuts, and operating rules. No additional pre-existing defect that the new contract makes wrong identified. Source fallback was required: nearest available graph project `XYZ-forge` is a different checkout, generation `2026-09-01T15:54:30Z`; merge_cleanup graph lookup returned zero, and coverage marked the five requested paths `not_tracked`. All material conclusions use this worktree's exact source, not stale graph completeness. Fix: none beyond Q5.

Handing off to Producer (claude-a) — disposition Q5, make the narrow parent-routing correction, then return for review. Go to the Producer window and say 'take your turn'.

### Producer · Round 2 · claude-a

Dispositions for Round 1:

- **Q5 [Should] — Implemented.** `skills/2-daily/workhorse/SKILL.md` Rung 6 step 5 (parent re-entry) now
  routes by the item's actual state instead of a universal resume: merge-cleanup keeps its supported
  `--execute --resume` command; jog lists its three Recovery Verbs with the state each fits
  (`resume` = reconcile state and re-project a valid terminal receipt after crash/restart, `retry-gate` =
  same-head gate re-run when the fix landed outside the build, `retry-build` = real rebuild), citing
  `skills/2-daily/jog/SKILL.md`; marathon / 10days is stated to have no resume or re-fire verb, with the
  `start-marathon` recovery rule (re-run the affected check once within `LANE_MAX_ATTEMPTS`, parked lane
  stays held and returns through the standing queue and operator firing confirmation). The loop sentence
  reads `drive → repair → re-enter`. No machinery or tests added. Commit: see `git log -1 -- skills/2-daily/workhorse/SKILL.md`.
- Q1–Q4, Q6–Q8 **[Pass]** — acknowledged, no change.

Request for Round 2: confirm Q5 against `jog/SKILL.md:129–138` and `start-marathon/SKILL.md:75–78,
353–354, 383–392`; re-check that the new paragraph introduces no new contradiction with Rung 0 or the
"Stop only for…" bullet. If clean, set VERDICT PASS and `STATUS: Approved`.

Handing off to Reviewer (codex) — take your turn.

### Reviewer · Round 2 · codex

swept file: yes
VERDICT: PASS
Basis: Q5 is resolved by the state-specific parent routing. Both artifacts were swept in full again; no Blocker, Should, or additional pre-existing defect identified. This approval covers source review and narrow pure-data probes. Executable hook/error-path, recovery, and final harness verification remain **[Unverified — needs clone run]**; none were run in this worktree.

- **[Pass] Q1 — Fail-open source paths and syntax edge cases.** `skills/2-daily/workhorse/stop-hook.sh:12–25,29–37,47–51,69–71` handles missing Python, malformed/non-object JSON, invalid session IDs, unavailable git/root resolution and unreadable/missing checklist files, with shell exit 0 on Python failure. Missing git may still use a valid `CLAUDE_PROJECT_DIR` checklist; that is valid fallback behavior, not a requirement to ignore that checklist. `:39–40,49,53` strips indentation and searches for the evidence marker anywhere on a ticked line: `- [x] W1 fix evidence: handling in parser` passes, an indented unevidenced tick blocks. Both are acceptable for the stated syntax-only envelope (`:10`, SKILL.md:87–88). No unexpected nonzero source path found. Fix: none.
  Pure regex probe command: `python3 -c 'import re; rows=["- [x] W1 fix evidence: handling in parser","    - [x] W1 done","    - [x] W1 done — evidence: abc1234","- [x] W1 done — evidence:"]; print([bool(re.match(r"-\s\[[xX]\]",s.strip()) and not re.search(r"evidence:\s*\S",s.strip(),re.I)) for s in rows])' > "$TMPDIR/gh983-r2-regex.txt"`. Exit 0; decisive output `[False, True, False, True]` (True = unevidenced). Missing/empty markers are red controls; an appended pointer passes. A separate read-only AST extraction of the actual hook constants produced the same output without running the hook or git.
- **[Pass] Q2 — Contract and hook agree.** SKILL.md:80–91,100–123,330–347 reserves `[-]` for optional/out-of-scope or explicitly user-deferred work, preserves required unresolved findings, and requires independent authorized work before stopping. Hook:60–67 asks for verified evidence or reopening and names `[!]` with the precise blocker/decision. No required-scope parking escape found in either full sweep. Fix: none.
- **[Pass] Q3 — Recital and completion audit agree.** SKILL.md:44 says “tick the item in the run checklist only with acceptance evidence” and “then audit the result against the requested outcome before reporting once at the end”; :104–108 and :315–328 require that audit, continued feasible work, the per-item evidence report, and accurate unfinished-state reporting. Fix: none.
- **[Pass] Q4 — Confirmation boundary remains sanctioned.** SKILL.md:91,114–123 allows an awaited operator decision or Rung 5 confirmation as `[!]`, expressly excludes recoverable local failures, and preserves authorization/retry limits. :241–245,257–276 still holds mutation for unknown targets/carriers, unconfirmed permanent loss, or unknown remote execution. The new :344–347 parent loop retains those limits. No new permission to relabel a recoverable local failure as external found. Fix: none.
- **[Pass] Q5 — Round 1 Should resolved.** SKILL.md:336 retains merge-cleanup's supported `--primary`, `--prefix`, `--execute`, `--resume` flags (merge_cleanup.py:1178–1191). :337–340 now distinguishes receipt reconciliation, same-head gate retry and real rebuild exactly as jog/SKILL.md:57–64,129–138 documents. :341–343 replaces the universal lane re-fire instruction with bounded check retry and held-lane queue/confirmation recovery, consistent with start-marathon/SKILL.md:75–78,353–354,386–392. The statement about no resume/re-fire verb is read in this named parent-skill recovery context; it does not disable lower-level executor retry flags. The actual 10days source is `skills/3-weekly/10days/SKILL.md`:482–512, which describes wave dispatch and red-gate hold, not a universal recovery verb. No nonexistent command is prescribed. :344–347 keeps required unresolved parent findings active, so the correction adds no contradiction with Rung 0 or “Stop only for…”. Fix: none.
- **[Pass] Q6 — Receipts remain honest and explicitly historical.** hook-evidence-probe.json:2,18–20 records supersession, the recorded-versus-true limit, and `stop-hook.sh_preserved: false`; SUMMARY.md:15 supersedes its earlier preservation claims; provenance.jsonl:15 explicitly supersedes claude-compatibility.json's old hook checks/preservation flag. claude-compatibility.json:2,22–24 can remain unchanged as a historical receipt. CHANGELOG.md:9–14 describes the new hook and declines a measured reliability claim. Read-only hash probe invocation `python3 - <<'PY' > "$TMPDIR/gh983-r2-probe.txt"` (AST extraction, hashlib.sha256 and JSON comparison; no artifact execution) exited 0 and printed `hook_sha256=61be22957013d9d484b9f23f62be84891c5f01cc29813ab990122e6108577876 receipt_matches=True`, matching hook-evidence-probe.json:4. Fix: none.
- **[Pass] Q7 — Appropriate size.** Hook:39–40,53,58–62 adds a marker classification to the existing scanner. SKILL.md:81,87–88 states its format and semantic limitation; :44 and :315–328 serve recital and final-report roles. The corrected parent references (:336–344) reuse existing mechanisms rather than adding state, gates, dependencies or tests. No speculative machinery or unnecessary implementation duplication identified. Fix: none.
- **[Pass] Q8 — Full sweep, including unchanged text.** Read SKILL.md:1–395 and stop-hook.sh:1–71 in full, including frontmatter, preservation/retry rules, shortcuts, operating rules and the revised parent paragraph. No additional pre-existing defect made wrong or ambiguous by the new contract identified. Graph Verify discovery could not supply current-worktree evidence: paginated list_projects has no matching checkout; XYZ-forge points to another checkout, generation `2026-09-01T15:54:30Z`; merge_cleanup lookup has zero results. Coverage reports material paths as not_tracked/missing or excluded, so all conclusions use exact local source fallback. Fix: none.

Relay closed (Approved), no further review turn needed. Returning the terminal token with done; claude-a may continue the separately required harness/clone verification.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
