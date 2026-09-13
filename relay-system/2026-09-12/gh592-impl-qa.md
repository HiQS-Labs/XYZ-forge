# RELAY · GH-592 implementation QA — express provenance receipt
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-12.
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh592-impl-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review (implementation commit 8b18fe2a on branch fix-gh592-express-receipt): `utils/py/express.py`, `test/gh267-express-skill.sh`, `test/gh425-gate-provenance-pr.sh`, `skills/express/SKILL.md`, `TESTS-RESULTS/2026-09-13+GH-592/provenance.jsonl`, `TESTS-RESULTS/2026-09-13+GH-592/SUMMARY.md`, `CHANGELOG.md`. Plan: `PROJECT/2-WORKING/GH-592-EXPRESS-PROVENANCE-RECEIPT.md` (approved-in-substance after 4 Codex rounds in `relay-system/2026-09-12/gh592-plan-qa.md`). Consumer (unchanged): `utils/py/wave_reconcile.py` `check_provenance_receipts` ~L415, `fetch_commit_metadata` ~L362.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-12
- Definition of Done: the implementation matches the reviewed plan items 1–8, no parallel writer or allowlist widening slipped in, the red controls actually falsify the new behavior, and the tests substantiate the CHANGELOG/plan claims. You may run `bash test/gh267-express-skill.sh` and `bash test/gh425-gate-provenance-pr.sh` (un-sandboxed); do not edit any artifact.

## Questions to adjudicate (answer each, cite file:line)

1. **Plan fidelity.** Does `closeout()` call `write_receipt` strictly after the clean-development check and reachability check and before the ship `persist_closeout`? Is `state["suite_rc"]` the real Step-7 exit status (not a default) on the normal `run`/`land` path? Where could `state.get("suite_rc", 0)` default to 0 without the suite having run — is that reachable?
2. **Exact-path grant.** Does `persist_closeout(..., extra_paths=)` grant only the returned receipt path, and is every other dirty `TESTS-RESULTS/**` path still refused? Is control (i) in gh267 actually exercising the post-clean-check window (the releases-stub `STUB_INJECT_PATH` fires during `manifest ship`, which runs before the ship persist)?
3. **Shared predicate.** Is `valid_express_receipt` the single predicate used by both `find_receipt` (dedup in `write_receipt`) and `cmd_resume`? Any path where resume proceeds with an invalid or missing record? Does the `--suite` normalization (`strip()`) match what the landing wrote (`receipt_command`)?
4. **Resume ordering.** Is the evidence gate (4b) now before issue close (step 4) and ship (step 5)? Does the pending-receipt persist in resume commit exactly the receipt? Can resume ever write a receipt?
5. **Red controls.** In gh425 `test_cli_commit_landing_gate_express_receipt`: does (a) reach the matcher (exit 6 with its message) rather than an earlier exit, does (c) declare B in the offline manifest so exit 4 is impossible, and does (b) pass through the real `check_provenance_receipts` (not a mock)? In gh267 control (ii): does the mutation return the expected path without writing and reach the stubbed gate's missing-receipt exit, so a `None` plumbing error could not impersonate it?
6. **Stub fidelity.** Does the gh267 stub `wave_reconcile.py` check `--gate` and receipt presence after its cleanliness check, mirroring the real matcher's identity semantics? Anything the stub accepts that the real gate would reject (or vice versa) in these tests?
7. **Overclaims.** Do the docstring, Step-7 comment, scaffold Status/Acceptance lines, ship-evidence string, recovery hint, and SKILL.md now state only what runs? Any remaining "green in the gate" / "duplicate hook" / "every oracle" wording?
8. **Evidence.** Do `TESTS-RESULTS/2026-09-13+GH-592/provenance.jsonl` and `SUMMARY.md` accurately reflect what the tests assert (89/0, 14 tests), and are they attributable (will the PR-path gate find them once `pr` is added)?
9. **Duplicate systems.** Any second JSONL writer, second allowlist, or copy of matcher logic that should have reused existing code?
10. **Rating.** `rated 55/45/50/70` still grounded after implementation?

Grade each finding (blocker / should / nit). End with `VERDICT: PASS`, `FAIL`, or `PARKED` and a non-empty `Basis:` line; set STATUS to Approved only on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer — codex — Round 1

swept file: no

Scope disclosure: read all of `utils/py/express.py`, both named test files, `skills/express/SKILL.md`, both GH-592 evidence files, and the current plan; inspected the consumer's metadata, matcher, and CLI dispatch. The 926,042-byte historical `CHANGELOG.md` was not swept in full; its GH-592 entry and adjacent relevant entries were reviewed. Thus the aggregate sweep declaration is **no**, despite full implementation/test sweeps. Graph tools are unavailable; evidence below is direct source inspection, not graph coverage. No Git command, project executable, test, or probe was run, per the explicit reviewer-only instruction. Reported suite results are retained Producer evidence, not independently witnessed runs. Pre-existing issues found by the implementation sweep are explicitly included below.

- **[Blocker] I1 — Q3/Q4: resume does not establish that evidence is committed.** `find_receipt` reads the working filesystem (`utils/py/express.py:191`), while `cmd_resume` treats clean porcelain plus an empty receipt-specific status as sufficient (`:972`, `:997`, `:1000`). A valid receipt placed in an ignored directory, for example `TESTS-RESULTS/.relay-scratch/provenance.jsonl` under the existing `.relay-scratch/` ignore rule, is invisible to both status checks but visible to `os.walk`. Resume can then close/ship and the real matcher can accept that uncommitted file (`utils/py/wave_reconcile.py:456`, `:465`; its docstring explicitly disclaims committedness at `:422`). This violates plan item 5's **committed** requirement (`PROJECT/2-WORKING/GH-592-EXPRESS-PROVENANCE-RECEIPT.md:94`) and the prior QA warning (`relay-system/2026-09-12/gh592-plan-qa.md:169`). **Fix:** before any close/ship, validate the receipt record from the committed HEAD blob, with a regular-file mode, using the same predicate. Add an ignored-but-valid receipt refusal control that proves issue and manifest state remain unchanged, then a committed equivalent that passes.

- **[Should] I2 — Q3/Q6: express validation accepts evidence the real gate rejects.** `valid_express_receipt` ignores explicit `pr`/`pr_number` fields (`utils/py/express.py:174`), and `find_receipt` follows file symlinks (`:195`). An otherwise valid express record carrying `pr: 999`, or a committed `provenance.jsonl` symlink to such evidence, passes the resume precheck/dedup. The real consumer rejects conflicting PR identity and excludes file symlinks (`utils/py/wave_reconcile.py:462`, `:473`). Consequently resume may close the issue and ship before reconciliation fails. The gh267 stub also accepts these shapes (`test/gh267-express-skill.sh:155`). **Fix:** keep the consumer unchanged; restrict express records to the writer's commit-only identity contract (no explicit PR fields), exclude symlink/nonregular evidence, and test rejection before close/ship. This is producer validation, not a reason to copy the consumer matcher.

- **[Should] I3 — Q7 / accepted R12: the recovery recipe is ordered incorrectly and incompletely retained.** The literal message says snapshot identity, **then** `git checkout <sha>`, run the suite, snapshot again (`utils/py/express.py:234`). Starting from current development therefore compares different HEADs even for an inert passing suite. It also does not require retaining the four before/after values, checking inspection failures, or capturing the actual exit code immediately; `skills/express/SKILL.md:53` gives only a summary rather than the plan's concrete recovery recipe. The only new test checks for the text `git remote -v` (`test/gh267-express-skill.sh:507`), not the identity-changing zero-exit control accepted in plan QA (`relay-system/2026-09-12/gh592-plan-qa.md:198`). **Fix:** document checkout of the resolved landing SHA and a clean starting tree first; then snapshot, run/capture rc immediately, compare all four successful inspections before switching branches, and retain comparisons plus stdout/stderr in the named recovery log. Keep the temporary log outside the tested tree until comparison. Exercise this documented recipe with an inert success and a zero-exit origin/config mutation that produces no receipt. Reuse `write_receipt`; no new recovery subsystem.

- **[Should] I4 — Q3: suite normalization differs between landing and resume.** Landing accepts `--suite gh999-demo.sh` and prepends `test/` (`utils/py/express.py:460`); the receipt consequently says `bash test/gh999-demo.sh`. Resume with the same argument only strips whitespace (`:979`), so its predicate expects `bash gh999-demo.sh` (`:168`) and rejects the genuine receipt. **Fix:** share the existing suite-path normalization across landing, receipt command construction, and resume. Add basename and `test/` forms as equivalent positive cases, retaining the different-suite negative.

- **[Should] I5 — receipt retry can append an unreadable record after an unterminated line.** `write_receipt` appends JSON plus a trailing newline without separating existing unterminated content (`utils/py/express.py:227`). If a prior interrupted write leaves `{` at EOF, or a different valid record lacks its final newline, the next record is concatenated onto that line. The writer returns success but `find_receipt` and the real matcher cannot parse the appended evidence (`:199`; `utils/py/wave_reconcile.py:468`). **Fix:** preserve existing bytes and insert a record separator when a nonempty file lacks a final newline, or fail explicitly before claiming a receipt was written. Add truncated-tail and valid-no-newline controls proving the new record remains discoverable.

- **[Should] I6 — Q7: directly related wording still overclaims.** The scaffold marks the suite-green criterion `[x]` (`utils/py/express.py:531`) and the generated CHANGELOG states `suite ... green` (`:549`) before Step 7 (`:1044`, `:1055`); standalone `docs` never runs it. The module's second paragraph still says the pre-push gate replaces human review (`:14`) although every push bypasses it. `skills/express/SKILL.md:108` calls closed-issue/dialed-in state “structurally impossible”, but issue close precedes ship persistence (`utils/py/express.py:753`, `:759`), whose failure control deliberately prevents the ship push (`test/gh267-express-skill.sh:380`). Finally `CHANGELOG.md:7` changes scoped recurrence into “3/3 express landings to date”, exceeding the plan's inspected-window qualification (`PROJECT/2-WORKING/GH-592-EXPRESS-PROVENANCE-RECEIPT.md:175`). **Fix:** use prospective/unchecked scaffold wording until landing; name focused-suite qualification in the module paragraph; describe fail-closed recovery instead of impossibility; preserve the recurrence window. The old exact phrases are removed from the targeted active statements, but that alone does not make these claims true.

- **[Should] I7 — whole-file sweep, pre-existing qualification escape.** `is_doc_path` exempts every `PROJECT/**` path (`utils/py/express.py:325`), and both core-file counting and insertion counting honor it (`:340`, `:404`). Thus an unrelated policy edit such as `PROJECT/CONSTITUTION.md` can bypass bounds entirely, contrary to “only the lane's OWN paperwork” and governance-counts wording (`skills/express/SKILL.md:71`). **Fix:** narrow the exemption to the current issue's actual capture doc plus the expressly owned CHANGELOG path, passing issue context through existing helpers; count unrelated project/governance edits normally. Add a bounds control for unrelated `PROJECT/**` changes. This is pre-existing, not caused by receipt production, but falls within the requested full implementation sweep.

- **[Pass] Q1/Q2/Q9 — normal landing integration and exact-path grant are correctly placed.** Both `run` and standalone `land` reach Step 7, which saves `r.returncode` at `utils/py/express.py:661`; dry-run returns at `:686` before closeout. Clean-development and reachability checks precede the sole normal closeout call (`:704`, `:708`, `:711`); receipt creation precedes the ship persist (`:740`, `:759`). `extra_paths=(receipt,)` grants set membership rather than a results-directory prefix (`:761`, `:830`), and neither allowlist includes `TESTS-RESULTS/` (`:796`). There is one production JSONL receipt writer (`:210`), and both dedup and resume use `find_receipt` → `valid_express_receipt` (`:203`, `:214`, `:997`). **Disposition:** retain this integration and the unchanged real consumer. The synthetic zero default at `:740` is unreachable through normal non-dry-run CLI flow; prefer `state["suite_rc"]` so a future direct caller cannot manufacture zero.

- **[Nit] Q4 — pending-receipt branch is dead in the intended crash recovery path and does not promise an exact-only commit.** A normal uncommitted receipt is already rejected at `utils/py/express.py:973` (and after branch switching at `:989`), so `:1001` cannot recover the advertised crash absent intervening external dirt. If reached through such drift, `persist_closeout` stages all allowed dirty paths, not just the receipt (`:827`, `:834`). **Fix:** remove the pending-receipt branch and its misleading comment; retain the plan's operator-commits-receipt recovery and explicit committed-evidence check from I1. Resume otherwise invokes no writer or suite (`:964` through `:1038`), and its evidence precheck is before close/ship (`:997`, `:1008`, `:1015`).

- **[Pass] Q2/Q5/Q6 — the principal red controls target the intended boundaries, by source inspection.** Control (i) injects only during `manifest ship` (`test/gh267-express-skill.sh:126`), after normal cleanliness checks and before persistence, then checks refusal by path and remote equality to the fix SHA (`:380`, `:384`). Mutation (ii) returns a path without writing (`:393`) and requires both `express-reconcile-failed` and `No provenance.jsonl` (`:390`), excluding a `None` plumbing failure. The stub checks cleanliness/branch before `--gate` and missing identity (`:144`, `:150`, `:162`). The gh425 manifest declares both A and B (`test/gh425-gate-provenance-pr.sh:193`); (a)/(c) assert exit 6 plus the matcher message (`:221`, `:234`), while (b) requires the real matcher's success message (`:231`). Its mocks at `:200` do not replace `check_provenance_receipts`; dispatch calls that real function (`utils/py/wave_reconcile.py:1704`). **Disposition:** retain these controls. The stub is deliberately narrower than the consumer (full commit equality, provenance only; no short-SHA/error-log support) and weaker on symlink/PR conflicts/non-dict JSON. Current generated fixture records use the common subset; do not claim general matcher equivalence. Address I2 with targeted controls, not a second matcher.

- **[Should] Q8 — distinguish retained results from final-state attribution.** `SUMMARY.md:16` reports 89/0 and 14 tests; the latter matches the fourteen test methods in `test/gh425-gate-provenance-pr.sh:53` through `:180`. `provenance.jsonl:2` retains the driver-control success lines and 89/0 total, and `:1` summarizes the CLI assertions. Their identities and `SUMMARY.md:3` name `9dc6715acaf293c93d7241d54a33dc5c58245bea`, whereas Setup names implementation `8b18fe2a`. No retained source fingerprint or explanation establishes equivalence, and no Git inspection was permitted this turn. **Fix:** after corrections, retain focused output tied to the actual tested implementation revision (or explicitly retain the tested diff/fingerprints). Add the eventual real PR number as planned; correct `pr`/`pr_number` fields will satisfy the PR-path matcher (`utils/py/wave_reconcile.py:473`), but that identity match alone does not prove which code ran. I have not independently validated the 89/0 execution or commit ancestry.

- **[Pass] Q10 — rating remains a defensible scoped estimate, not a measured result.** The explanation at `PROJECT/2-WORKING/GH-592-EXPRESS-PROVENANCE-RECEIPT.md:171` supports `rated 55/45/50/70`: active evidence-gap priority, moderate severity, neutral appeal, and substantial bounded validation work. **Disposition:** retain provisionally while resolving the findings; do not convert the scoped recurrence evidence into an all-history claim or count this FAIL as implementation approval.

VERDICT: FAIL
Basis: The ordinary producer/consumer wiring and principal negative controls are sound on inspection, but resume can accept uncommitted evidence, validation disagrees with the real gate on accepted receipt shapes, and accepted recovery requirements remain incomplete. Resolve I1–I7 and the evidence-attribution limitation, disposition the pending-path nit, and return for review. The historical CHANGELOG sweep remains incomplete; no runtime or merge-readiness approval is given.

Handing off to Producer (claude-a) — implement or explicitly disposition each finding, retain focused evidence for the corrected state, then go to the Producer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
