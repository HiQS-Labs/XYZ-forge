# RELAY · GH-1193 final QA — published-retirement sibling safe root
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-24.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh1193-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1193-RETIRE-SIBLING-ROOTS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1193-RETIRE-SIBLING-ROOTS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-24
- This is the FINAL review of the implemented change. The plan (Approved in
  `relay-system/2026-10-24/gh1193-plan-qa.md`) is the `## Plan` section of the artifact.
- Requirements: https://github.com/HiQS-Labs/XYZ-forge/issues/1193 (transcribed in the artifact's Asks/Acceptance).
  Out of scope: #722 (default audit scan roots).
- The change under review: `git diff 45eb73a7..f7d148ec -- skills WORKTREE-SAFETY.md` (commit `f7d148ec`):
  - `skills/2-daily/merge-cleanup/scripts/scan_clones.py` — new `published_retirement_roots()` after
    `DEFAULT_NEVER_DELETE`; `inspect_checkout` root check now passes it only when `published_pr` and
    `primary_repo_path` are set.
  - `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` — import; `teardown_checkout(..., safe_roots=None)`;
    `retire_published_checkouts` computes the roots once and passes them to its guard and to `teardown_checkout`.
  - `WORKTREE-SAFETY.md` §16.1 — one paragraph after the code block; `skills/2-daily/merge-cleanup/SKILL.md` — one
    sentence in "Automatic retirement after ready PR publication".
- Evidence: `TESTS-RESULTS/2026-10-24+GH-1193/` (`SUMMARY.md`, red control on base `45eb73a7`, main and adjacent
  smoke on `f7d148ec`, focused suites in a disposable full clone, `provenance.jsonl`). The full route gate runs once
  on the final approved commit after this review.
- Operational envelope: local single-operator developer CLI removing the operator's own task clones (to Trash)
  after proving their content is published; threat model is a mistaken path, not a hostile local attacker
  (WORKTREE-SAFETY §16.1). Grade against stated requirements and commensurate complexity. XYZ-forge forbids new
  tests (GH-831): a new suite or registry entry in the diff would be a finding; do not ask for one.
- Definition of Done (answer each, cite `file:line`):
  1. Does the code match the approved plan at all three source sites, and does the normal sweep stay
     byte-identical (the `teardown_checkout(c, dry_run=dry_run)` call, `inspect_checkout` with `published_pr=0`,
     the module-global `DEFAULT_SAFE_ROOTS` read that fixtures `mock.patch`)?
  2. Is every pre-existing fail-closed check on the published path still in force and in the same order?
  3. Is `published_retirement_roots` correct for a primary whose parent resolves to a NEVER_DELETE member, and for a
     symlinked primary/parent (both sides resolved, as §16.1 requires)?
  4. Does the §16.1 parity pin still read only the unchanged list? Are both doc sentences accurate?
  5. Do the receipts substantiate the acceptance criteria (red control present; main path no longer refuses on
     SAFE_ROOTS; NEVER_DELETE parent not added; outside path still refused)?
  6. Does the persisted rating 55/45/50/85 still match the evidence (appeal neutral)?
  7. Any duplicate subsystem/writer, new test, unrelated change, or over-/under-engineering in the diff?

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

- [Pass] The approved three-site change is present: `scan_clones.py:53-60,945-946` derives the resolved parent only for published inspection; `merge_cleanup.py:1492,1505,1525` supplies it to the up-front and teardown guards. The normal sweep remains `teardown_checkout(c, dry_run=dry_run)` at `merge_cleanup.py:1942`, and `is_safe_deletable_path` still reads module-global `DEFAULT_SAFE_ROOTS` when passed `None` (`scan_clones.py:74-77`).
- [Pass] Published retirement still checks origin, absolute non-symlink checkout, protected primary/ancestor/CWD, Git checkout, root, distinct paths, and matching origin before inspection (`merge_cleanup.py:1488-1517`); fresh inspection and teardown remain in that order (`:1519-1525`). The existing inspection checks for publication/ref proof, active claims/handles, dirty state, failed queries, ignored worktree files, stashes, unpublished refs, dependents, and unsafe roots remain in `scan_clones.py:976-1121`. No pre-existing defect found in the touched paths.
- [Pass] `primary.resolve().parent` and resolved existing `DEFAULT_NEVER_DELETE` members are compared on both sides (`scan_clones.py:57-60`), including symlinked primary/parent cases. The unchanged §16.1 `SAFE_ROOTS` list is at `WORKTREE-SAFETY.md:798-803`; the derived-root prose follows the code block at `:827-831`, and the skill describes the same boundary at `skills/2-daily/merge-cleanup/SKILL.md:568-569`.
- [Pass] Receipts substantiate the acceptance checks: `red-control-base-45eb73a7.txt` exits 2 on SAFE_ROOTS; `smoke-main-f7d148ec.txt` reaches `ACTIVE_PROCESS` for the task clone and `SAFE_REMOVE_CLONE` dry run for its gate helper; `smoke-adjacent-f7d148ec.txt` shows NEVER_DELETE parents retain defaults and an outside checkout still exits 2 on SAFE_ROOTS. `focused-suites-f7d148ec.txt` records the parity and focused suites exiting 0 in a disposable full clone; `provenance.jsonl` records the commit and artifact hashes. Preview only; the full route gate remains the post-review harness step.
- [Pass] The persisted 55/45/50/85 rating remains supported by the blocker and bounded fix described in `.relay-artifacts/GH-1193-RETIRE-SIBLING-ROOTS.md` under “Rating rationale”; appeal remains neutral. The scoped code and two doc edits introduce no duplicate writer, new test, or unrelated behavior (`scan_clones.py:53-60,945-946`; `merge_cleanup.py:873-893,1492-1525`).

VERDICT: PASS
Basis: All seven Definition of Done checks are supported by source and committed receipts; no blocker or should finding.

relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
