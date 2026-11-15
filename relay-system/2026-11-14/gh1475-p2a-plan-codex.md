# RELAY · GH-1475 Phase 2A plan QA (Codex)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1475-p2a-plan-codex): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1475-MERGE-CLEANUP-REMEDIATION.md`, section **## Phase 2A** only (read it in full; the Phase 1 sections are background, already merged as PR #1478).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-14
- Definition of Done: the plan is approvable when its claims are grounded in the cited paths, every
  Phase 2A requirement (P2.1, P2.2, P2.3, P2.8 of https://github.com/HiQS-Labs/XYZ-forge/issues/1475) is
  covered with the smallest surface, it extends the existing writers and helpers (no duplicate subsystem
  or write path), each acceptance check observes the actual failure with a red control, and blast radius,
  rollback and the PRS rating are sound.

## Review packet (Producer: claude-a, 2026-11-14)

**Operational envelope.** `/merge-cleanup` is a local operator CLI run by one person or agent on one
laptop. Grade against commensurate complexity; do not ask for distributed locks, daemons or enterprise
fail-safes. XYZ-forge forbids new tests (AGENTS.md *No new tests*, GH-831): a new suite, a `validate.sh`
entry or gate machinery would itself be a finding; updating existing tests that pin changed behaviour is
allowed; other verification is manual checks under `TESTS-RESULTS/`. Review-only turn: write only this relay file.

### Step 1 — paraphrase first
Read ONLY the `## Phase 2A` section of the plan doc (no issue, no source yet). Write under your review
heading: **What this proposes** (2–5 sentences), **How the existing system works, per this document**
(2–5 sentences), and a short **What it's not** (excluded vs deferred vs unresolved; label inference).
State the input boundary ("Phase 2A section only").

### Step 2 — source-backed assessment
Then read issue #1475's Phase 2A items (`gh issue view 1475 -R HiQS-Labs/XYZ-forge` if reachable; else
the items are quoted in the plan) and the sources the plan cites:
`skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (`_land_prs_loop`, `resolve_merge_policy`,
`required_checks_state`, `pin_selection`, `_remove_own_scratch`, `_probe_text`),
`skills/2-daily/merge-cleanup/scripts/ledger_merge.py` (`resolve_ledger_conflict`, forecast assumptions),
`skills/2-daily/merge-cleanup/scripts/scan_clones.py` (`inspect_open_handles`),
`skills/2-daily/merge-cleanup/scripts/batch_record.py` (`set_allowlist`),
`skills/2-daily/merge-cleanup/SKILL.md`, `test/gh534_phase_b_tests.py`, `test/gh534_phase_c_tests.py`,
`test/gh436-merge-cleanup.py`. Label this part **Source-backed assessment**.
Recorded decisions: reuse Phase 1's `_remove_own_scratch`, `keep_workdir`, `preflight_warnings`/`_probe_text`,
`batch_record.row_done`/`set_outcome`; P2A.measure is out of this PR; no new tests.

### Questions
1. Are the plan's line/symbol claims accurate at this revision? Cite any that are wrong.
2. For each of P2.1, P2.2, P2.3, P2.8: what prevents an unchanged tree from being reported as delivered,
   and where is the intended observed rejection (red control)? Is any check only an admission probe?
3. P2.1: is re-pinning safe? Specifically: (a) is "GitHub reports exactly `b1["commit"]`, checks ok on it,
   head unchanged on one more refresh" enough to prove nothing else moved the head; (b) is the
   `had_required` + registration-grace design right for gh's "no required checks reported" right after a
   push, and does it avoid sleeping in the existing fixture tests (which have no checks); (c) is calling
   `pin_selection` with the stored forecast the right way to keep GH-1452's single writer; (d) are the
   test edits truthful (keep-pinned-behaviour edits, not new tests)?
4. P2.2: is `checks_state` (required part unchanged + one extra read only when names are declared) the
   minimal shape? Is the combine rule and the "absent = pending" rule right? Should `wait_for_checks`
   be allowed without `full_suite`, or is requiring it (as today for any `qualification`) acceptable?
5. P2.3: are the prune guards enough and not excessive (prefix, direct temp-root child, uid, newest N,
   one-hour age floor, `inspect_open_handles` verified-idle, skip if another `merge_cleanup.py` runs)?
   Note suites run under the real `$TMPDIR`. Is the exit-3 landed-clone release correct (which clones
   belong to a landed PR; `_remove_own_scratch` gaining `root`)?
6. P2.8: is "dry run and not handoff ⇒ preview" exactly true for `resolve_ledger_conflict(execute=False)`?
   Should the previewed PR affect hard dependents in the dry run?
7. Is anything missing, duplicated, or over-built? Is the retained rating 60/65/50/75 grounded?

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

Input boundary for paraphrase: Phase 2A section only, read before sources.

**What this proposes:** Make B1 repairs land in the same execution after new-head checks pass, allow explicitly named CI checks, prune retained scratch, and continue B1 dry-run previews through the batch. It extends existing policy, pin and cleanup writers, with existing-suite updates and manual red controls.

**How the existing system works, per this document:** The loop repairs and pushes ledger conflicts, but rejects the new head because it differs from the dry-run pin. Required-check discovery permits repositories without required checks. Clean runs remove their landing workdir; deferred runs and check clones retain scratch. B1 previews currently return early.

**What it's not:** Excluded: new modules, flags, suites or daemons. Deferred: P2A.measure/decision and Phase 2B. Unresolved (inference): how re-pin publication failures and second validation-clone ownership are handled.

**Source-backed assessment**

swept file: yes

Swept the full Phase 2A section, the artifact boundary specified in Setup. Source review covered the cited implementation paths and pinned test cases; this is plan QA, not an assertion that every source module was audited. No additional pre-existing defect established beyond the behavior the plan already identifies.

- [Should] Keep the registration guard effective throughout repaired-head polling, not only at entry. Step 3 says to run a registration grace before applying the existing pending loop. That loop accepts a later `ok, "no required checks"` immediately (`merge_cleanup.py:1962-1970`), so the plan still permits delivery without any green result on a required check.
  Observed input: the existing helper maps stderr `no required checks reported` to `("ok", "no required checks")` at `merge_cleanup.py:763-765`; the existing pending loop exits on any non-pending result. A repaired-head sequence `pending(ci)` followed by that helper result takes the green path under the proposed one-time grace arrangement.
  Affected scope: own B1 repairs for which `had_required` is true, on every poll before re-pinning.
  Falsifier: manual controlled responses `old: pass(ci); repaired: pending(ci), no-required-checks` must defer or continue bounded registration waiting, never re-pin/merge; `pending(ci), pass(ci)` must land. Apply the same guard on every read rather than adding another subsystem. Retain this red control in the planned manual receipts.

- [Should] Account for the second validation clone in exit-3 cleanup. Step 4 deletes only `pr-<n>-*`, but `validate_head_in_second_clone` allocates `workdir / f"verify-{sha[:8]}"` (`merge_cleanup.py:834-840`). A successfully repaired and merged PR leaves this full clone behind whenever another PR defers; the promised check that “only the deferred PR's clone” remains cannot pass for that input.
  Observed input: one B1-repaired PR lands, another PR defers; the first creates both `pr-<n>-*` and `verify-<repair-sha8>`, while Step 4 only selects the former.
  Affected scope: validation scratch belonging to PRs merged in this run on exit 3, with no kept result or unfinished sync.
  Falsifier: the manual mixed landed/deferred scenario must include a B1 repair, assert its second clone is removed, and retain the deferred PR's evidence. Track the already-created validation path alongside the landed PR, or explicitly narrow the requirement and acceptance claim if retaining it is intentional.

- [Should] Add negative controls for the irreversible prune predicates. Step 4's control only shows base retaining everything; its held-open/young cases do not cover foreign uid, failed process discovery, or incomplete lsof. `_probe_text` specifically collapses error/timeout and a negative process search into the same empty string (`merge_cleanup.py:1112-1119`), so it cannot establish the advertised “skip if another process runs” when discovery fails.
  Observed input: `_probe_text` returns `""` for `OSError`, timeout and nonzero exit, and Step 4 proposes treating that output as the concurrency guard for deletion.
  Affected scope: old retained scratch considered for pruning when process enumeration is unavailable or incomplete.
  Falsifier: controlled process-probe failure must preserve candidates; a successful no-match probe plus verified-idle lsof must prune eligible candidates. Keep separate status for pgrep's normal no-match versus failure; no new gate or suite needed. Also record incomplete-lsof and foreign-owner preservation controls, with all other predicates eligible.

- [Pass] P2.8's preview predicate matches the resolver: `ledger_merge.py:536-583` starts unresolved/non-handoff, marks each rejection as handoff, and returns the preview only after classification. Continuing without `failed` is consistent with the existing clean-preview `continue` (`merge_cleanup.py:1983-1985`); hard dependents may be previewed, not represented as landed. The two-hub base/candidate control measures delivery rather than admission.
- [Pass] P2.2 extends the existing policy owner (`merge_cleanup.py:270-311`); required-plus-declared worst-state combination and absent-name pending are conservative. Requiring `full_suite` preserves the existing contract. Its pending-to-pass, timeout and absent-name checks exercise runtime behavior; policy acceptance alone would be insufficient. Existing required-check behavior remains at `:750-772`.
- [Pass] Re-pin through `pin_selection` preserves GH-1452's atomic writer and stored-forecast argument (`merge_cleanup.py:509-547`); `batch_record.py:329-337` supports latest-pin replacement. Implementation must check the writer's boolean result before proceeding and construct the supplied rows from the authorized pins, not fresh unreviewed heads. The proposed exact repair SHA plus final refresh is proportionate for the local CLI; it proves the head observed at those points, not absence of every intervening move. Registration controls above remain necessary.
- [Pass] The test edits revise existing contracts: `gh534_phase_b_tests.py:241-245,423-424` explicitly require a second run today; Phase C's cited cases use that helper. Preserve their downstream merge, row, dependent and durability assertions while removing the obsolete second execution. Fixtures with no required checks need no grace sleep when `had_required` is false.
- [Nit] Name the reversibility class explicitly. Code rollback is Easy, while scratch deletion is irreversible and needs the stated bounded retention policy and negative controls. Retained 60/65/50/75 is plausible from the stated incidents, but not independently read back from PRS here; the future-ending incident window “2026-11-14..15” should be explained or corrected.
- [Unverified — needs clone run] No suites, fixtures or runtime red controls executed in this worktree. Commands and decisive failure: `gh issue view 1475 -R HiQS-Labs/XYZ-forge --json body` exited 1, `error connecting to api.github.com`; assessment uses the four locally identified Phase 2A requirements, so exact remote issue completeness remains unverified. Graph search was denied with `MCP tool call requires approval, but approval policy is never`; direct cited-source reads supplied the fallback. Full gate and manual receipts remain implementation requirements, not delivered evidence.

VERDICT: FAIL
Basis: The small-surface direction is sound, but the required-check polling transition and cleanup ownership/negative controls need explicit plan corrections before approval.

Handing off to Producer (claude-a) — address the findings, then return for Round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
