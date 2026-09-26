# RELAY · GH-831 Phase 2 final QA — three tiers in the classifier and the reconcile
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-25.
-->

NEXT: Reviewer
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
6. **Commit only the relay file** (`relay(gh831-phase2-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh831-phase2.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/0cc9b6f4-22bd-4606-b4ec-21e1b8f38591/scratchpad/gh831-phase2.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-25
- Definition of Done: **Approved** when all of these hold:
  - (a) `utils/ci-route.sh` implements D2–D4 as the plan states: the Small list equals R2's 73 SMALL
    dispositions; the 7 Medium additions are R2's; the D4 docs surfaces follow the stated precedence; and
    no path changes tier except the ledger, data and view files and non-core skill files;
  - (b) `validate.sh`: `--subsystem small` adds the PDDA gate and the Python layer, the 8 off suites leave
    `TESTS`, and nothing else in the registry changes;
  - (c) `utils/py/wave_reconcile.py` implements D5: selection fails closed; the tier-2 rule holds every
    clause of D5.2; the receipt records tier and list; replay is against the tested commit; atomicity is
    unchanged; and every tier-3 behaviour and receipt is unchanged;
  - (d) the existing suites edited (`test/ci-route.sh`, `test/gh306`, `test/gh35`) changed only to stay
    truthful, and the diff adds no new suite, registry entry or gate machinery;
  - (e) the docs (ROUTER, AGENTS, `ci.yml` comments, the `validate.sh` usage text, the express wording, the
    five deferred lines, and the `relay-xyz` review item) are accurate and match the code;
  - (f) the recorded checks substantiate what the plan's Phase 2 steps 1–4 promise.

## Review packet

**What this is.** Phase 2 of GH-831, per `PROJECT/2-WORKING/GH-831-THREE-TIER-GATE.md`: Design D1–D7,
"Decisions for the operator" (O1–O4, O7 and O8 accepted), "Phase 2 — Tiers" and "Phase 2 — what the build
found". The diff under review is `.relay-artifacts/gh831-phase2.diff`: `git diff f832ef5a f7fff636`. It
excludes the binary `releases.db` and the two bulky run artifacts, which you can read in the worktree:
`TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071.log` and `small-run-9ecf2071-telemetry.jsonl`. The branch
is `feat/gh831-phase2-tiers`. Phase 1 (#832) is merged.

**Operational envelope.** A single-repo local developer harness, with its hosted reconcile on GitHub macOS.
The operator decided "no new tests; three tiers". Grade against the plan and commensurate complexity.
Verification is by existing suites plus manual checks recorded under `TESTS-RESULTS/`. Do not ask for new
suites or guard machinery, which would contradict the decision. The full gate runs once, after this review, on
the final commit.

**Read:**
- the diff;
- the plan sections named above;
- `utils/ci-route.sh` (whole file) and `utils/py/wave_reconcile.py` (`qualification_summary` through
  `qualify_landings`, and its `--only-receipted` caller in `main`);
- `TESTS-RESULTS/2026-09-25+GH-831/`: `suite-map.tsv`, `phase2-ci-route-red-controls.log`,
  `phase2-gh306-red-control.log`, `phase2-d4-skill-files-to-tier1.txt`, `phase2_reconcile_check.py`,
  `phase2-reconcile-check.log`, `phase2-reconcile-check-red-controls.log`, and the Small-run telemetry.

You may grep the worktree and run read-only probes such as
`printf '%s\n' <paths> | bash utils/ci-route.sh push` and `bash utils/ci-route.sh subsystems small`.

**Questions** (cite `file:line`):

1. **Small and Medium lists (D2, D3).** Does `SUBSYSTEM_TESTS_small` equal the 73 `SMALL` rows of
   `suite-map.tsv`? Are the 7 Medium additions exactly R2's `MEDIUM` rows not already listed? Is every listed
   suite still registered in `validate.sh`?
2. **Routing precedence (D4).** Does `is_docs_surface()` give the plan's precedence?
   - text, evidence and governance paths first;
   - the named ledger, data and view files as docs, despite `subsystem_of()` claiming `releases.db`/`.sql`;
   - the six core skills never docs;
   - other `skills/**` docs unless an area claims them.

   Is any path that was tier 2 or 3 now tier 1 beyond those? The file list is in
   `phase2-d4-skill-files-to-tier1.txt`. The plan records one consequence for GH-487's co-touch rule
   (a releases test plus only `releases.sql` now gives tier 3); is it correct and acceptable?
3. **The reconcile (D5).**
   - Does `select_qualification_gate` fail closed on every error path?
   - Is the union diff (`landing^..landing`) the right change set for squash merges and commit landings?
   - Does `qualification_summary`'s tier-2 branch enforce every D5.2 clause?
   - Can a tier-2 receipt satisfy the matcher for anything but a genuine complete Small run at the tested
     commit's list?
   - Is the tier-3 branch byte-for-byte the old logic?
   - `gh425` still passes unchanged. Is its fixture now exercising only the fail-closed selection path, and
     is that acceptable given `phase2_reconcile_check.py` covers the tier-1 path against real telemetry?
4. **`validate.sh`.** Does `--sequential --subsystem small` produce exactly the telemetry the rule expects?
   Compare the Small run: `total` 76, `run_set` 73, one `envelope-assert` stage. Is the reconcile's telemetry
   glob `validate-sequential-*-<pgid>.jsonl` satisfied by a tier-2 sequential run?
5. **Edited suites.** Are the `test/ci-route.sh`, `test/gh306` and `test/gh35` edits limited to keeping them
   truthful? Does the diff add any new suite, registry entry, hook, guard or telemetry?
6. **Docs.** Are ROUTER, AGENTS (the GH-544 and GH-509 rails), `ci.yml`, `validate.sh` usage, the
   `express.py` wording, the five deferred lines, and `relay-xyz` review-scope item 7 accurate? Do they
   conflict with other rails? Is the shared-skill wording scoped to repos that forbid new tests?
7. **Rollback and rating.** Is the plan's rollback (revert only D5's selection, keep the receipt reader) still
   correct for the code as written? Does the rating `85/70/75/40` still fit?
8. **Commensurate.** Anything over-built, under-built, or out of Phase 2 scope? Is there a pre-existing
   defect in `ci-route.sh` or the qualification functions that this change should not ship on top of?

Write findings in the Log per the turn rules. Set `STATUS: Approved` only if the Definition of Done is met.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
