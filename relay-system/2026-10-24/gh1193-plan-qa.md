# RELAY · GH-1193 plan QA — published-retirement sibling safe root
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
6. **Commit only the relay file** (`relay(gh1193-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1193-RETIRE-SIBLING-ROOTS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/1-INBOX/GH-1193-RETIRE-SIBLING-ROOTS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-24
- This is a PLAN review; no fix code exists yet. The plan is the `## Plan` section of the artifact.
- Requirements source: https://github.com/HiQS-Labs/XYZ-forge/issues/1193 (body is transcribed in the
  artifact's Asks/Acceptance). Related, explicitly OUT of scope: #722 (default audit scan roots).
- Source paths to read (the plan cites line numbers against base `45eb73a7`):
  - `skills/2-daily/merge-cleanup/scripts/scan_clones.py` — `DEFAULT_SAFE_ROOTS` (:26),
    `DEFAULT_NEVER_DELETE`, `is_safe_deletable_path` (:64), `inspect_checkout` (:873, root check :935,
    `PRESERVE_UNSAFE_ROOT` :1106)
  - `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` — `teardown_checkout` (:872/:890),
    `retire_published_checkouts` (:1482/:1501), the published-mode CLI guard in `main` (:1583)
  - `WORKTREE-SAFETY.md` §16.1 (the `SAFE_ROOTS = [...]` block) and `test/gh534_phase_a_tests.py`
    `test_doc_and_code_root_lists_agree` (the parity pin)
  - `test/gh436-merge-cleanup.py` (orchestration asserts on `teardown_checkout(candidate, dry_run=...)`)
  - `skills/2-daily/merge-cleanup/SKILL.md` "Automatic retirement after ready PR publication";
    `skills/1-hourly/start-task/SKILL.md` Step 3 (GH-970 sibling location) and Step 9.
- Operational envelope: a local, single-operator developer CLI that removes the operator's own task
  clones (to Trash) after proving their content is published. Threat model is a *mistaken path*, not a
  hostile local attacker (WORKTREE-SAFETY §16.1 says so). Grade against the stated requirements and
  commensurate complexity; do not ask for enterprise machinery. XYZ-forge forbids new tests (GH-831):
  do not ask for a new suite or registry entry; verification is existing suites + manual smoke receipts.
- Definition of Done (questions to answer, cite `file:line`):
  1. Are the recon claims accurate — is the root check really applied at exactly those three places on
     the published-retirement path, all with the default list, and is there any fourth check the plan missed?
  2. Is accepting `--primary`'s parent (minus NEVER_DELETE parents) the leanest correct fix, and does it
     preserve every existing fail-closed check (absolute non-symlink checkout, not primary/ancestor/cwd,
     same origin, published-PR head proof, fresh re-inspection, NEVER_DELETE)? Any path where the
     widened root lets something be retired that should not be, given those other checks?
  3. Does the plan keep the normal sweep / default scan byte-for-byte unchanged (including the
     `teardown_checkout(candidate, dry_run=...)` call the gh436 suite pins and the module-global read
     that fixtures `mock.patch`)?
  4. Does the WORKTREE-SAFETY §16.1 parity pin stay green with the proposed doc sentence?
  5. Are the acceptance checks falsifiable (red control present) and sufficient without new tests?
  6. Is the rating (55/45/50/85) and its recurrence claim grounded? Appeal must stay neutral (50).
  7. Flag over- or under-engineering, a duplicate subsystem/writer, or a missing requirement.

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

- [Pass] The plan covers all three root-check sites: the up-front guard (`merge_cleanup.py:1501`), inspection (`scan_clones.py:935`), and teardown (`merge_cleanup.py:890`). Published retirement calls inspection again through `refresh_for_teardown` (`merge_cleanup.py:1515-1521`, `:862-864`), so the proposed `published_pr` condition also covers the fresh verdict. No fourth source site found.
- [Pass] The scoped parent root fits sibling placement (`start-task/SKILL.md:110-117`); strict containment and protected-root equality remain in `scan_clones.py:76-82`. The path, origin, live publication and fresh-inspection guards remain on the published path (`merge_cleanup.py:1491-1522`; `scan_clones.py:984-993`). The default sweep's `teardown_checkout(c, dry_run=dry_run)` call stays unchanged (`merge_cleanup.py:1937-1939`), including its module-global default (`scan_clones.py:66-69`). I found no missing safety check or duplicate writer in the reviewed plan.
- [Pass] The proposed sentence follows the example list (`WORKTREE-SAFETY.md:798-804`); the parity pin extracts only the first `SAFE_ROOTS = [...]` block (`test/gh534_phase_a_tests.py:123-129`). Existing focused suites plus a base-driver red control and final disposable-clone gate are falsifiable checks, as specified in the artifact's Acceptance checks.
- [Nit] The Recon phrase “runs the root check three times” should say “three source sites, four evaluations”: `inspect_checkout` runs at initial scan and fresh inspection (`merge_cleanup.py:1515-1518`). This does not change the implementation steps.
- [Unverified — no citation] The 55/45/50/85 rationale is proportionate to the reported recoverable cleanup blockage and small change; appeal remains neutral. The recurrence claim is limited to one reported #1190 incident and does not count the distinct default-scan #722 variant (artifact, “Rating rationale”).

VERDICT: PASS
Basis: The plan addresses the published-retirement root boundary at every source site while preserving the normal sweep and the existing fail-closed checks. The only correction is wording about repeated inspection.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
