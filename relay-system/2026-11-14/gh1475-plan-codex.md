# RELAY · GH-1475 Phase 1 plan QA (Codex)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1475-plan-codex): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1475-MERGE-CLEANUP-REMEDIATION.md` (the Phase 1 plan; read it in full).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-14
- Definition of Done: the plan is approvable when its claims are grounded in the cited paths, every
  Phase 1 requirement (P1.1–P1.6 of https://github.com/HiQS-Labs/XYZ-forge/issues/1475) is covered with
  the smallest surface, it extends the existing writers (no duplicate subsystem or write path), each
  acceptance check observes the actual failure with a red control, and blast radius, rollback and the
  PRS rating are sound.

## Review packet (Producer: claude-a, 2026-11-14)

**Operational envelope.** `/merge-cleanup` is a local operator CLI run by one person or agent on one
laptop. Grade against commensurate complexity; do not ask for distributed locks, daemons or enterprise
fail-safes. XYZ-forge forbids new tests (AGENTS.md *No new tests*, GH-831): a new suite, a `validate.sh`
entry or gate machinery would itself be a finding; verification is existing suites plus manual checks
under `TESTS-RESULTS/`. Review-only turn: write only this relay file.

### Step 1 — paraphrase first
Read ONLY the plan doc above (no issue, no source yet). Write under your review heading:
**What this proposes** (2–5 sentences), **How the existing system works, per this document** (2–5
sentences), and a short **What it's not** (excluded vs deferred vs unresolved; label inference). State
the input boundary ("plan doc only").

### Step 2 — source-backed assessment
Then read: issue #1475 body (the approved three-phase plan; `gh issue view 1475 -R HiQS-Labs/XYZ-forge`
if reachable, else the Phase 1 list in the plan doc stands), and the sources the plan cites:
`utils/py/wave_reconcile.py`, `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`,
`skills/2-daily/merge-cleanup/scripts/batch_record.py`, `skills/2-daily/merge-cleanup/SKILL.md`,
`test/gh436-merge-cleanup.py`, `test/gh534_phase_c_tests.py`. Label this part **Source-backed assessment**.
Recorded decisions: `merge-check-*` stays retained (pinned tests); flock is out (P3.6); no new gh call.

### Questions
1. Are the plan's line/symbol claims accurate at this revision? Cite any that are wrong.
2. For each of P1.1–P1.6: what prevents an unchanged, unfixed tree from being reported as delivered —
   and where is the intended observed rejection (the red control)? Is any check only an admission probe
   (proves it runs, not that the defect is fixed)?
3. P1.3 uses `shutil.rmtree` on this run's own `mkdtemp` workdir with containment checks, not Trash.
   Is that safe and consistent with repo rules (AGENTS.md danger list, GH-567)? Any path where `clean`
   is true but the workdir holds something an operator needs?
4. P1.4: is the recovery write correct and minimal (dry-run guard, batch lookup by `[N]`, `_sync_batch`
   extraction), and is the `record_sweep` hint logic right without a gh query?
5. P1.6: do the probes risk breaking existing `main()`-level tests that mock `subprocess`/`_gh`? Any
   probe not worth its code?
6. Is anything missing, duplicated, or over-built? Is the rating 60/65/50/75 grounded?

Grade each finding `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`, then VERDICT.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

**What this proposes** (input boundary: plan doc only). Six local Phase 1 changes address fetch races, buffered output, temporary landing-clone retention, recovery records, exit-code documentation and environment warnings. It reuses the existing retry, logging and batch writers, with manual red controls and existing suites as acceptance evidence.

**How the existing system works, per this document.** Reconciliation currently pulls in the primary while cleanup fetches and fast-forwards separately. Landing scratch is always retained, recovery does not update the batch, and sweep hints cannot distinguish outstanding reconciliation from outstanding landing. Dry-run warnings already have an advisory logging path.

**What it's not.** Explicitly excluded: Phase 2/3, merge-check pruning, locks, new gh calls and new suites. Deferred: retention policy and concurrency serialization. Inference: advisory probes deliberately do not certify that execution is safe.

**Source-backed assessment** — **Block pending acceptance-plan corrections.**

swept file: yes

Read the complete plan, including recon, verification, rating and rollback, then inspected the cited source paths and relevant existing suite contracts. No additional pre-existing defect in the plan beyond the findings below. GitHub issue retrieval (`gh issue view 1475 -R HiQS-Labs/XYZ-forge --json body`) exited 1: `error connecting to api.github.com`; the packet-authorized Phase 1 list in the plan is the fallback. Graph search was denied by the runtime approval policy; source reads were used. No suites, fixtures or git commands were run; execution evidence remains **[Unverified — needs clone run]**.

- [Should] **P1.4's check can pass without wiring the recovery entry point.** The verification table says “after the recovery write,” which permits manually calling `set_outcome` and then measuring existing `continuable`; that does not expose a missing recovery call. The smoke only drives `--reconcile-pr` in dry-run mode, where the proposed write is explicitly disabled. Require a scratch, execute-mode `main()` recovery with external reconciliation/push operations stubbed, then reload the actual persisted record and observe both its outcome and issue-update invocation. Also exercise dry run and failed reconciliation/push to show they leave the outcome unchanged. Keep this manual in a disposable clone, not a new suite.
  Observed input: plan Verification P1.4, “after the recovery write”; smoke, “`--reconcile-pr` dry run (no writes)”; current recovery branch `merge_cleanup.py:2348-2370` returns without a batch write.
  Affected scope: acceptance evidence for the new recovery-to-batch connection, including its success-only guard.
  Falsifier: run the same execute-mode entry-point check against the unchanged tree; the reloaded row must remain reconcile-failed and fail the success assertion. If it already changes to `ok`, this finding is unnecessary.

- [Should] **Make the buffering red control discriminate buffering from fast completion.** “Read the log within 5 s” is satisfied by an unchanged program that exits within five seconds and flushes at exit. Hold an existing downstream operation with a controlled delay, assert the process is still alive when reading, and require an early Phase 0 line before releasing the delay. Verify the same input on the base has no such line while alive.
  Observed input: plan Verification P1.2, `merge_cleanup.py --primary <scratch> > log &` followed only by “read the log within 5 s”; no blocking input or live-process assertion is specified.
  Affected scope: the manual P1.2 acceptance procedure, not the proposed line-buffering implementation.
  Falsifier: under an identical controlled delay the unchanged implementation emits the expected Phase 0 line while still running; that would show this input does not witness F12 and another input is needed.

- [Should] **P1.6 omits acceptance for the required-check warning.** The forced conditions cover TMPDIR, pmset, pgrep and disk, but never the separate `required_checks_state` branch. Add a manual dry-run input returning `("ok", "no required checks")`, require one F6 warning, and pair it with a named successful required check that emits none. Assert the existing gh-call count is unchanged. The unchanged tree must fail the warning assertion.
  Observed input: plan Phase 1 step 6 includes the F6 warning; its Verification row lists only environment probes. Existing `merge_cleanup.py:1893-1916` prints ordinary required-check detail and continues the dry run without a PRE-FLIGHT warning; `test/gh436-merge-cleanup.py:453` already supplies the concrete no-checks tuple.
  Affected scope: dry-run warning acceptance for positively absent required checks, distinct from unreadable/pending checks.
  Falsifier: the unchanged tree prints the specified F6 PRE-FLIGHT warning for that tuple; then the stated missing behavior would be disproven.

- [Pass] **P1.1/P1.3 have appropriate bounded surfaces, with implementation details to keep explicit.** `wave_reconcile.py:302-307` is the claimed one-shot pull; the plan replaces it with bounded fetch/merge retries rather than a new writer. Ensure the lock red control advances the remote ref, so fetching actually needs the held lock. The plan's resolved-parent/non-symlink checks constrain deletion to this run's scratch. `merge_cleanup.py:1802-1813,1820-1829,1857-1861` retains repair handoffs and draft-after-repair clones, while `:2059-2067` separates exit 3 from clean completion. Initialize `clean = False` before entering the protected body; setting it only before return 0 must not mask error paths with an unbound-local exception. Preserve the stated keep/deferred guards. A revert restores code, not deleted scratch: describe that limit rather than implying deletion itself is reversible.

- [Pass] **P1.4's proposed writer reuse and lookup match the existing contract.** `batch_record.py:250-271` defines closed rows as terminal and selects an unfinished batch overlapping `[N]`. The proposed “per continuable's rule” must retain closed-row exclusion in mixed batches. `_record_batch_outcomes` at `merge_cleanup.py:1607-1614` already finalizes inputs and refreshes the issue; extracting that tail avoids a second writer. The positive merged status supports a recovery hint without querying gh again.

- [Pass] **P1.5 identifies a real documentation contradiction.** SKILL.md says “Single-PR runs are unchanged: no issue, no exit 4.” The plan cites the broader QA-pending return at `merge_cleanup.py:2634-2663` and preserves the pinned “exit 4 is never Done” wording. A source-backed documentation correction plus the existing contract suite is proportionate; it needs no new runtime gate.

- [Nit] **Keep probes bounded and evidence durable.** Step 6's silent-error contract is appropriate, but explicitly give pmset/pgrep finite timeouts so an advisory probe cannot stall startup. Existing tests patch the shared subprocess module (`test/gh436-merge-cleanup.py:965,991`), so parse only successful textual output and leave `_gh` untouched. Record manual commands, final revision, exit statuses and nonempty outputs in the already-planned evidence directory with `provenance.jsonl` (AGENTS.md GH-430); no new infrastructure is needed.

- [Unverified — no citation] **Scope and rating are proportionate to the supplied evidence.** Plan “Rating” labels recurrence as one observed batch and explicitly says the trend for these failures is unknown; 60/65/50/75 is a reasonable provisional judgment rather than a measured recurrence claim. The “Smallest viable bet” excludes modules, flags, state files and new gh calls; retaining merge-check scratch and excluding flock respects the recorded decisions. Blast radius includes the vendored reconciliation consumer and wrapper interpretation, as the recon and P1.5 state. No distributed coordination is warranted.

**VERDICT: FAIL**
**Basis:** Implementation direction is sound, but the three acceptance gaps allow incomplete delivery to be reported green. Correct those procedures, clarify the small safety details above, then return for plan QA. Actual runs remain for the disposable-clone implementation phase.

Handing off to Producer (claude-a) — address the findings and take the next turn.

### Producer · Round 1 · claude-a

Paraphrase matches the plan; no explanation gap. GitHub was unreachable from the reviewer sandbox;
the plan's Phase 1 list is the approved issue text (issue body updated after Argon QA).

- **[Should] P1.4 check can pass without wiring the entry point.** **Implemented.** P1.4's check now
  drives `main()` with `--reconcile-pr N --execute` against a scratch record, stubbing only the
  external steps, reloads the persisted row and asserts the issue update; dry run and failed
  reconcile/push leave the row unchanged; red control is the base tree.
- **[Should] P1.2 red control does not discriminate fast exit.** **Implemented.** A `gh` stub sleeps
  on first call; assert the process is alive and Phase 0 is already logged; base shows no line while alive.
- **[Should] P1.6 F6 warning lacks acceptance.** **Implemented.** Added the no-required-checks tuple
  (one warning, `_gh` count unchanged) and a named passing check (none).
- **[Nit] bounded probes, durable evidence.** **Implemented** (5 s timeouts, parse only zero-exit
  text, `_gh` untouched; provenance per GH-430).
- **[Pass] details:** `clean = False` initialised before the `try`; P1.1 red control advances the
  remote ref so the fetch needs the lock; rollback text now says a revert does not restore deleted
  scratch; closed-row exclusion kept in the hint. **Implemented.**

Plan doc updated in place: `PROJECT/2-WORKING/GH-1475-MERGE-CLEANUP-REMEDIATION.md` (Verification
table, Phase 1 steps 3 and 6, Rollback). Please re-review.

handing off to Reviewer (codex) — take your turn.

### Reviewer · Round 2

**What this proposes** (input boundary: plan doc only). Six bounded Phase 1 changes improve fetch retries, live logging, successful-run scratch cleanup, recovery bookkeeping, exit documentation and advisory warnings. The revised acceptance procedures explicitly distinguish the unchanged tree from delivery.

**How the existing system works, per this document.** Reconciliation pulls once; landing scratch is always retained. Recovery reconciles and pushes without updating the batch, while the existing batch writer owns persistence and issue refresh. Required-check information already exists, so the warning needs no new gh query.

**What it's not.** Explicit exclusions: Phase 2/3, locks, merge-check retention changes, new suites and new gh calls. Deferred: broader retention and serialization. Inference: these advisory warnings do not certify the environment safe.

**Source-backed assessment**

swept file: yes

Re-read the entire plan, including recon, all six changes, verification, rollback and rating; inspected the cited source seams and existing test contracts. No additional pre-existing defect in the plan requiring another cycle. Graph discovery returned `MCP tool call requires approval, but approval policy is never`; direct source reads were the fallback. `gh issue view 1475 -R HiQS-Labs/XYZ-forge --json body` exited 1, `error connecting to api.github.com`; used the packet-authorized Phase 1 list in the plan. No git commands, suites or executable fixtures were run. Runtime acceptance remains **[Unverified — needs clone run]**; this approves the plan, not delivery.

- [Pass] **Round 1 acceptance findings are addressed.** Verification P1.4 now says “call `main()` with `--reconcile-pr N --execute`” and “reload the persisted record,” including issue update, dry-run and failed reconcile/push controls. That measures the missing connection at `merge_cleanup.py:2348-2370`, rather than manually invoking the new writer. P1.2 now requires “process is still alive” with a sleeping downstream stub and an absent-line base control. P1.6 explicitly supplies `("ok", "no required checks")`, a named passing check and unchanged `_gh` count. These are discriminating planned checks; their execution is still outstanding.
- [Pass] **P1.1–P1.3 remain bounded.** `wave_reconcile.py:302-307` is the one-shot pull; Verification P1.1 now advances the remote branch before holding its tracking-ref lock, forcing a real update. The plan's “initialise `clean = False` before the `try`” and “clean and not keep_workdir and not deferred_sync_pending” preserve nonzero exits and retained repair handoffs (`merge_cleanup.py:1799-1829,1856-1868,2040-2067`). Resolved-parent, directory, prefix and symlink checks constrain removal to this invocation's temporary root. No clean-success path inspected retains a unique unpublished repair without the keep flag. Rollback now explicitly says deleted scratch is not restored; this is bounded deletion of owned scratch, not operator-checkout retirement.
- [Pass] **Recovery and hint changes reuse existing ownership.** `_record_batch_outcomes` already finalizes sweep inputs and calls `batch_record.update` (`merge_cleanup.py:1605-1614`); the `_sync_batch` extraction shares that tail. `find_unfinished(..., [N])` matches the overlap contract (`batch_record.py:260-270`). “per `continuable`'s rule” preserves terminal closed rows (`batch_record.py:250-257`); positive merged state justifies the recovery hint without another query. Verification P1.4 now includes closed-row silence and the old resume-hint red control.
- [Pass] **P1.5/P1.6 preserve existing contracts with proportionate surface.** The contradictory single-PR statement remains at `SKILL.md:475-476`; the plan corrects it while retaining drive-loop contracts exercised by `test/gh534_phase_c_tests.py:906-921`. Step 6 now bounds pmset/pgrep at 5 s and parses only successful textual output. That avoids interpreting failed shared subprocess mocks as warnings (`test/gh436-merge-cleanup.py:965-966,991-993`); full mock compatibility remains a focused-suite obligation. Disk, battery, unusual temp root and concurrent execution are reasonable advisory probes for the observed local batch hazards.
- [Nit] **Use the actual gh override in the buffering receipt.** Verification P1.2 calls it `GH_BIN`; the environment key is `MERGE_CLEANUP_GH_BIN` (`scan_clones.py:36`, read through `merge_cleanup.py:82-83`). Use that spelling in the eventual manual command so the sleeping stub is actually selected. This is a recipe correction, not a design blocker; require the specified live-process/line observations before counting the check as evidence.
- [Pass] **Scope, rating and evidence obligations are adequate.** “six local edits in two Python files and one doc” and “no new module, flag, config key, state file or gh call” keep the design local. Recon names the vendored reconciliation consumer; rollback states its deletion limit. Rating explicitly distinguishes one observed batch from an unknown recurrence trend and labels 60/65/50/75 with its rationale. Verification requires commands, revision, exit statuses, outputs and `provenance.jsonl`; QA gate still requires focused/full disposable-clone runs and final independent review. The bounded scratch deletion warrants care at implementation QA but no distributed machinery.

**VERDICT: PASS**
**Basis:** The revised plan covers P1.1–P1.6 through existing owners, and resolves the acceptance gaps with meaningful red controls. No blocking plan finding remains. Runtime proof and final implementation QA remain required before reporting delivery.

relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
