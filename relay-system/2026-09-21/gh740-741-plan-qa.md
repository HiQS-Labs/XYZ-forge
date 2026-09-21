# RELAY · GH-740/741 plan QA — hosted lane receipts-first publish + outcome-aware report
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-21.
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
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh740-741-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-740-HOSTED-LANE-PUSH-RACE.md (group plan for #740 + #741; PROJECT/2-WORKING/GH-741-HOSTED-LANE-REPORT-ATTRIBUTION.md points at it)
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-21
- Definition of Done: the plan is **grounded, complete for both issues, surgical, and falsifiable** — graded against the requirements in the issues (#740, #741) and the plan's own Requirements table, at **commensurate complexity** (a ~150-line change to one CI job's last two steps; no merge queue, no second job, no enterprise failure taxonomy). Reviewer reads the source paths, not just the plan: `.github/workflows/wave-reconcile.yml:12-17,53-112`, `utils/py/hosted_lane_report.py` (whole file, 112 lines), `utils/py/wave_reconcile.py:475-528` (receipt contract) and `:530-560` (qualify_landings pending filter), `test/gh421-auto-wave-reconcile.sh:525-640`, `test/gh684-hosted-lane-report.sh`. Evidence the plan cites: run 35623940059 (push step red, reconcile step green; the reported `invalid merged_at timestamp` is gh421 test output), runs 35372725722 / 35375197135 (09-18 rejected pushes).
- Questions to answer explicitly (each with a grade): (1) Is the receipt-contract claim right — does `committed_qualifications()` + `qualification_receipt_matches()` really accept a receipt pushed by a *separate earlier commit* once `tested` is an ancestor of the new HEAD, so Phase B's recompute skips the suite for this run's landings? Name any condition the plan missed. (2) Phase B re-runs the exact reconcile argv (incl. `--catch-up --qualify`) after `reset --hard`; is there a state the reconcile step leaves that makes a second invocation unsafe (journal/rollback markers, `.tick/`, porcelain check), or a cheaper correct argv? (3) Does moving the inline publish step into `utils/py/hosted_lane_publish.py` keep every gh421 pin (allowlist regexes byte-identical, explicit-path `git add`, bot identity, no push before allowlist), and are the gh421 test edits the plan lists the *minimum*? (4) #741: is outcome-based attribution (`steps.<id>.outcome`) sufficient, or is there a case where the reconcile step is green yet its log's last ERROR line is the real cause? (5) Are the fixture suite's five cases enough and is its red control genuinely red (a plain push from the raced clone rejected)? (6) Ratings: are `85/75/50/55` and `70/55/50/80` grounded in the cited recurrence (3 rejected pushes in 5 days; 27 red runs classified), appeal neutral? (7) Anything the plan lists as a non-goal that is actually required for the acceptance to hold? Grade findings [Must]/[Should]/[Nit]; **Approved** only when no [Must] remains. Do not request scope beyond the two issues.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer — codex — round 1

VERDICT: FAIL
Basis: The receipt contract supports the design, but the written Phase A/B ordering does not implement its own raced-publish acceptance; the retry budget also conflicts with the existing job timeout. These are plan/source findings, not claims of executed Git fixtures.
swept file: yes

Read the entire GH-740 plan, GH-741 companion, workflow, report module and gh684 suite; inspected the specified gh421 pins, receipt consumer/producer and reconciliation cleanup/re-entry paths. No additional pre-existing defect found in the report module beyond the already-scoped attribution problem. No Git commands or executable fixtures were run. Runtime race/receipt proof: [Unverified — needs clone run].

- **[Must] F1 — Phase A has no clean-tree transition, and an A-side race never mandates recomputation.** The plan at `PROJECT/2-WORKING/GH-740-HOSTED-LANE-PUSH-RACE.md:88-96` commits receipts alone, rebases, then commits the old `rest`; only a subsequent B push rejection triggers recomputation. This contradicts its own case at `:131-132` (A-side race must recompute once). The dirty transition files prevent ordinary rebase; merely parking/restoring those files would then allow stale generated ledger bytes to push successfully atop the racer. Specify how the old transitions are kept outside the receipt-only rebase and discarded/regenerated whenever A adopts a newer remote base. Never rebase a transition commit or restore stale ledger bytes onto that base. Keep the one recompute budget explicit across both phases.
  Observed input: The plan's own fixture at `:129-132` has a receipt plus modified `releases.sql` and a project doc when Phase A commits only the receipt; the current producer writes these together (`wave_reconcile.py:2011`, `:2180-2190`).
  Affected scope: A remote advance before the receipt push while reconciliation has non-receipt output.
  Falsifier: In a disposable clone, race a remote edit to the same ledger while local receipt + tracked ledger/doc edits exist; expect receipt publication, exactly one recompute, preservation of the racer's ledger contribution, and no transition bytes passed through rebase. An implementation satisfying that without an explicit clean/recompute transition would disprove this finding.

- **[Must] F2 — The “cheap” retry can exceed the unchanged job budget.** `:100-103` explicitly permits another full qualification for an unqualified racer, while `.github/workflows/wave-reconcile.yml:28` caps the whole job at 120 minutes. The plan itself measures the initial qualification at roughly 70 minutes: two such runs need roughly 140 minutes before other work. A one-attempt cap is not a sufficient wall-time bound. State a bounded retry policy that fits the job, or explicitly budget the additional qualification and adjust the workflow timeout/pin. Align the goal's “at most one cheap recompute” wording with the chosen policy; this is required for #740, not an unrelated hosted-suite repair.
  Observed input: Plan `:100-103` and `:143-145` admit a full retry qualification; workflow `:28` is `timeout-minutes: 120`; the plan's Observed problem says the lane is approximately 70 minutes.
  Affected scope: A newly merged, unqualified PR discovered by the retry's `--catch-up --qualify` after the original qualification consumed most of the job budget.
  Falsifier: A budget calculation or bounded timing fixture showing both permitted qualifications and publication fit the configured job deadline; merely counting one retry does not falsify it.

- **[Should] F3 — Make the real fixture prove receipt reuse and retained remote content, not just stub call count.** The stub described at `:129-135` writes a receipt-shaped directory and counts invocations; it does not exercise `committed_qualifications()` or `qualification_receipt_matches()`. Include valid retained telemetry/receipt data and assert that the production pending filter excludes the original landing after a separate earlier receipt commit. Assert the remote racer's content survives, not just commit ordering. The red control must run on the stale pre-recovery clone/head before successful publication updates its ancestry.
  Observed input: The specified stub at `:129-130` writes “a receipt folder” and a `releases.sql` line, without a valid receipt/telemetry contract or a production consumer assertion.
  Affected scope: The five planned gh740 cases used to establish the “never qualify this run's landings again” acceptance.
  Falsifier: A clone-run test whose valid receipt passes the real consumer after publication and whose missing/corrupt receipt control makes that assertion fail; the stale plain push must actually return nonzero. Record decisive output in committed evidence.

**Answers to the seven requested questions:**

1. **[Pass — source contract; runtime unverified]** A receipt need not be introduced by HEAD itself: `committed_qualifications()` reads paths and blobs from HEAD's complete tree (`utils/py/wave_reconcile.py:511-528`). A separate earlier receipt commit therefore works. Ancestor status alone is insufficient: matching schema, artifact kind, PR identity, landing SHA, pass/rc/gate, permitted non-symlink telemetry path, matching hash and valid telemetry summary are also required, plus **landing → tested → HEAD** ancestry (`:475-508`). Both evidence files must survive publication intact. `:535-539` excludes matching landings; it does not exclude a newly arrived unqualified racer.
2. **[Must — F1/F2; otherwise source-supported re-entry]** The journal is in memory and cleanup clears its backups (`:154-218`, `:2190`); the lock's file may persist, but `flock` is released on context exit (`:56-80`). There is no successful-run rollback marker that by itself prohibits a repeat. The actual entry condition is clean porcelain and branch `development` (`:232-245`, `:272-284`, `:1961-1962`). `.tick/marathon-plan.fingerprint` survives a tracked reset and affects regeneration (`:1617-1647`): include preservation/regeneration of plan output in clone verification if the retry discards it. Keeping the same argv is semantically defensible, but neither guaranteed cheap nor needed just to fetch again: it already calls `pull --ff-only` (`:286-292`, `:1970-1971`); `--skip-pull` after an explicit fetch/reset is a possible small optimization, not a required scope addition.
3. **[Pass — proposed surface, with necessary pin corrections]** The move is appropriately surgical; preserve the four allowlist definitions and bot identity from `.github/workflows/wave-reconcile.yml:79-98`, and validate the entire changed-path set before **either** phase pushes. gh421's extraction helper/test and ordering assertion depend on `PUBLISH_HEAD`, so they must change when inline Python disappears (`test/gh421-auto-wave-reconcile.sh:551-610`). Its single combined `add` assertion must become explicit receipt/rest staging assertions (`:621-623`). Keep the refusal cases, empty case and no-push-before-refusal proof; do not retain YAML-extraction machinery for an external module. These are the minimum structural adaptations beyond the plan's abbreviated list.
4. **[Pass — initial attribution]** For the current workflow, green initial reconcile means its last fixture ERROR cannot be the fatal error: `set -euo pipefail` preserves process failure, and actual `die()` raises (`wave_reconcile.py:51-53`). Outcomes suffice for #741's reported case (`hosted_lane_report.py:52-56` currently ignores them). With the new design, a **second** reconcile runs inside publish: its real error belongs to publish.log, even while the original reconcile outcome is success. The promised publish error wrapper (`plan:98-99`) must retain that subprocess's decisive diagnostic, not reduce it to an exit-code-only message. Keep skip parsing and job-status attention logic (`hosted_lane_report.py:88-90`); retry-only skips should also be considered when wiring the new log consumer so a green retry cannot silently close the attention issue.
5. **[Should — F3]** Five named cases are a reasonable size, but the specified assertions do not yet prove receipt reuse or protect the racer's data. Also include a B-only race (A succeeds, then the remote advances) as a timing variant of the existing race case. A plain push is a valid red control only before recovery makes that clone current. No red control was executed this turn: [Unverified — needs clone run].
6. **[Unverified — remote evidence unavailable]** Ratings are proportionate **if** the cited classification is accurate; appeal 50 is neutral and the two effort scores are consistent with the plan treating higher effort-score as easier work. The recurrence counts do not mechanically determine the exact priority/severity numbers. Queries `gh issue view 740 --repo HiQS-Labs/XYZ-forge --json body` and the same for 741 both exited 1 with `error connecting to api.github.com`; the 27-run classification and the three run identities were not independently verified here. Preserve them as author-reported evidence pending accessible run records, rather than reviewer-confirmed counts.
7. **[Must — F2 only]** No merge queue, second job, force-push, allowlist widening, or unrelated suite-failure repair is needed. The retry's own time budget and F1's safe state transition are necessary acceptance work within these two issues. Reversibility is Easy for the relay edit; publication/ledger integrity is consequential and must be covered by the plan's rollback and clone proof before shipping.

Handing off to Producer (claude-a): disposition F1–F3 and revise the canonical plan, then open round 2 for review.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
