# RELAY · GH-831 Phase 2 final QA — three tiers in the classifier and the reconcile
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-25.
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

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: The implementation and retained Small-run evidence support D2–D5, but the new routing documentation contradicts the actual text-first precedence. One bounded documentation correction is required for DoD (e); no runtime change or new test is requested.
swept file: yes

Swept all of `utils/ci-route.sh`, the qualification functions through `qualify_landings`, and the `--only-receipted` caller; reviewed the supplied diff, plan and retained evidence. No additional pre-existing shipping defect identified in those swept runtime surfaces. This is review approval work, not a full-gate attestation.

- [Should] F1 — Correct the core-skill routing claim. `ROUTER.md:125-126` says all six core skills “are never docs”, but `utils/ci-route.sh:62-64` deliberately checks `*.md`/`*.txt` before the core exclusions. The separate full-surface rule at `utils/ci-route.sh:334` catches relay-xyz and relay-automation; it does not catch every core skill. Keep the implementation's existing text-first behavior and document that the exclusions apply to the newly widened non-text skill surfaces, with the existing full-surface overrides still winning. Align the equivalent unqualified wording in the new CHANGELOG bullet and the plan's D4 precedence explanation. This is an Easy, text-only correction; changing runtime precedence instead would violate the requested preservation of existing path tiers.
  Observed input: `skills/1-hourly/relay/SKILL.md`, `skills/2-daily/merge-cleanup/SKILL.md`, and `skills/1-hourly/express/SKILL.md` each produce `route=docs`, `tier=1`; `skills/1-hourly/relay-xyz/SKILL.md` produces `route=full`, `tier=3`.
  Affected scope: documentation describing core-skill and claimed-area precedence; no classifier behavior change.
  Falsifier: the same paths returning tier 3 uniformly would support “never docs”; they do not. Probe command: `printf '%s\n' skills/1-hourly/relay/SKILL.md | bash utils/ci-route.sh push` (and the other three paths separately). Exit status 0 for each; decisive outputs quoted above. These probes used the supplied classifier without invoking git or a suite.

- [Pass] D2/D3 and scope: `utils/ci-route.sh:24-36` contains the 73 Small names and the seven Medium additions (two ATE, two agent-chorus, three skills-army-hq). A read-only Python comparison using `csv.DictReader(..., delimiter='\t')` on `suite-map.tsv`, the literal `SUBSYSTEM_TESTS_*` assignments, and `validate.sh`'s `TESTS` block exited 0: `SMALL 73 73 equal True unregistered []`. The diff removes exactly eight TESTS entries, mirrored in `test/gh306-registry-bidirectional.sh:53-60`; it adds no suite, runner, hook or telemetry stage. Existing suite edits correspond to changed routing, membership and nested suite paths.

- [Pass] D4 implementation: `utils/ci-route.sh:61-69,373-405` reuses one docs predicate, preserves text/evidence precedence, admits the six named ledger/data/view paths, and excludes core non-text and subsystem-owned non-text skill paths. The concrete `releases.sql` probe returned `route=docs tier=1`, and `utils/py/releases_app.py` returned `route=fast tier=2` (same command form as F1, exit 0). The documented releases-test plus ledger-only co-touch escalation follows `code_touched_subs` and the post-loop co-touch resolution; accepting that fail-closed consequence is consistent with the build packet.

- [Pass] D5: `utils/py/wave_reconcile.py:477-524` enforces the listed Small completeness clauses while retaining the old full-registry branch. `:550-565` binds Small receipts to the tested commit's literal list; `:589-614` unions first-parent landing diffs and selects full on classifier/diff failures. First-parent differences cover squash landings and individual commit landings. `:675-714` retains identity checks, exact process-bound telemetry, and journaled publication; `:2122-2140` still uses the same matcher for bounded replay. Keeping this reader while forcing selection back to full remains the correct rollback. No scope growth warrants changing the recorded 85/70/75/40 rating.

- [Pass] Actual telemetry shape: `validate.sh:933-939,1132-1145,1444-1484,1513-1520` selects the two required non-suite checks and counts identity separately; `test/lib/runner-telemetry.sh:55-63` produces the filename matched at `wave_reconcile.py:678`. Read-only probe command: `python3 - <<'PY'` with `ast.parse` of `wave_reconcile.py`, compilation of only its `qualification_summary` function, and `qualification_summary(raw, rows[0]['commit'], small_names)` against `small-run-9ecf2071-telemetry.jsonl`; then repeat after filtering out the `tier2:pdda` row. Exit 0; decisive output: `real telemetry 76 76 73` and `red control missing PDDA rejected: Small-run telemetry is failed, incomplete or not the expected list`. No module startup, fixture or suite was executed.

- [Pass] Retained checks: `phase2-reconcile-check.log` records “19 pass, 0 fail”; its paired red-control log records rc 1 for both disabled rules. The inspected manual-check source exercises receipt replay after list drift and selection failure, complementing gh425's retained fail-closed fixture. `phase2-ci-route-red-controls.log` and `phase2-gh306-red-control.log` retain failing controls and restored green results, with provenance entries in the same evidence directory. The Small-run log ends `validate rc=0 wall=1233s` and unchanged HEAD/porcelain. These are retained producer results, not fresh suite runs by this reviewer.

- [Pass] Remaining edited wording: `skills/1-hourly/relay-xyz/SKILL.md:612-615` scopes the no-new-tests review item to forbidding repos; the relay-automation installation wording preserves other repos' policy. Express changes are wording only, and the CI promotion command remains the full sequential registry. The changed examples and PR template name existing coverage rather than a new suite.

- [Unverified — needs clone run] The final full gate remains pending as explicitly scheduled by the packet. No `validate.sh`, `test/*.sh`, pytest, executable fixture, or git command was run in this review worktree.

Handing off to Producer (claude-a): correct F1's documentation, preserve routing behavior, and return for the next review round.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
