# RELAY · gh1108-hook-takeover-final
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1108-hook-takeover-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: skills/2-daily/merge-cleanup/scripts/merge_cleanup.py (`run_jog_post_merge_land`), TESTS-RESULTS/2026-10-17+GH-1108/hook-no-bundle-skip-manual.{py,log}.txt, PROJECT/2-WORKING/GH-1108-JOG-LAND-RECEIPTS.md (Takeover section)
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-17
- Definition of Done: the merge-cleanup post-merge Jog hook never fails a landing for a mapped row that has no committed receipt bundle in the merged tree; it still fails when a bundle exists and `jog land` refuses; bad `gh pr view` output is a named failure; nothing else in PR #1116 changed; no new suites (GH-831).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 — Producer (claude-a) → Reviewer (codex)

**Context.** PR #1116 (GH-1108 delivery 1) was independently reviewed at 323602cd. One Blocker: `run_jog_post_merge_land` mapped every `pending|running|failed|parked` Jog row reachable from a PR's closing issues or any `gh<N>` token in its branch name and returned False when `jog land` refused — so a hand-built PR that closes an issue with a stale Jog row (GH-269, 310, 529, 533, 1075 exist today) stopped merge-cleanup after the remote merge, before `commit_and_push_phase5_writes`, and `--reconcile-pr` re-entered the same refusal. Operator decision: fix only this, land, stop delivery 2 (#1117), freeze Jog.

**Change under review (commit aa3ae393, one function):** after mapping, the hook runs `git ls-tree -r --name-only -z HEAD -- TESTS-RESULTS` in the primary and keeps only mapped issues that have a committed `TESTS-RESULTS/<date>+GH-<n>/jog/<exec>/receipt.json`; the others are logged `warn: … not a Jog delivery — row left as-is` and skipped. Rows with a bundle still go through `jog land`, and a refusal still returns False. `json.loads(gh pr view)` is wrapped: non-JSON/non-object → `log_err` + False (CodeRabbit item). Nothing else in the PR changed.

**Operational envelope.** Local merge-cleanup CLI run by one operator in the primary checkout after a PR merged on GitHub. Commensurate complexity: no new suites, no new config, no new subsystem. Evidence: `hook-no-bundle-skip-manual.py.txt` (6/6 green on aa3ae393; red at 323602cd: A1/A2 fail, D crashes) and the focused gh436/gh280 suites re-run in this clone (`takeover-focused-suites.log.txt`).

**Questions (answer each with file:line):**
1. Does the bundle regex over `ls-tree -z` output match exactly the layout `publish_jog_receipt` writes (`TESTS-RESULTS/<YYYY-MM-DD>+GH-<n>/jog/<execution-id>/receipt.json`) and nothing else? Any path shape that would be wrongly included or excluded (e.g. multiple executions, foreign `+GH-` dirs)?
2. Is the skip safe: can a row that *is* a Jog delivery ever lack a bundle in the merged tree at hook time (publication failed/parked, or the lane commit was squashed away by policy), and if so is "row left as-is + warn" the correct outcome versus failing?
3. Does the `mapped &= bundled` intersection preserve the original refusal path (bundle present + `jog land` rc≠0 → False) unchanged? Confirm against `jog_land` in `utils/py/jog_run.py`.
4. Is the `run_git(repo_path, [...])` argument order and return shape correct for `scan_clones.run_git`, and is a non-zero `ls-tree` handled as a named failure?
5. The `gh pr view` JSON guard: any remaining path in this function where malformed subprocess output raises instead of returning False?
6. Does the manual control actually exercise the real function (not a copy), and does its red run at 323602cd falsify the claim? Note it stubs `subprocess.run` and `_gh` by module attribute.
7. Anything in this one-function change that is over-built for the envelope, or a simpler equivalent?

Grade each finding [Blocker]/[Should]/[Nit]/[Pass]; a [Blocker]/[Should] requesting a behaviour change must carry Observed input / Affected scope / Falsifier. Do not ask for new tests. End with STATUS: Approved if the Definition of Done holds.


<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
