# RELAY · GH-684/GH-686 plan QA — hosted reconcile lane: alert, skip-and-report, gh53 fixture
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-17.
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
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh684-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-684-HOSTED-RECONCILE-LANE.md` (the plan of record; sections Recon map, Requirements → plan mapping, Plan S1–S4, Acceptance checks, Risks) and `PROJECT/2-WORKING/GH-686-GH53-FIXTURE-FLAKE.md` (shares the PR; maps to S3).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-18
- Definition of Done: the plan is grounded in the actual code paths it names, satisfies R1–R4 with nothing missing, extends the existing subsystems and writers (no parallel machinery), and its acceptance checks can detect the actual failures (each new/changed behaviour has a red control). Approve when every question below is answered "yes" or the remaining findings are `[Nit]`.

### Operational envelope (grade against this, not an enterprise threat model)
A single-repo GitHub Actions job on `macos-latest` plus a ~2 000-line local Python reconciler and a Bash test fixture. One operator, one canonical repo. Machinery and tests must stay commensurate: no new workflow, no notification service, no retry/queue layer, no second ledger. Reviewer findings are advisory; requests for behaviour changes must carry `Observed input:` / `Affected scope:` / `Falsifier:` (Ground rule 7 in this harness).

### Read in full before answering
- the two plan docs above
- `.github/workflows/wave-reconcile.yml` (97 lines) — especially the reconcile step (`--pr "$PR_NUMBER" --catch-up --gate --qualify`) and the commit step that refuses undeclared in-tree files
- `utils/py/wave_reconcile.py`: `catch_up_prs` (~1181–1248), `validate_lessons_learned` (~926–949), `validate_and_update_doc` (~1002–1025), the main landing/issue loop (~1928–2075)
- `test/gh421-auto-wave-reconcile.sh` (the unittest harness with offline fixture and `WorkflowTests`)
- `test/gh53-releases-merge-resolve.sh` lines 53–100 (`mk_diverged`, `union_dump`) and `utils/releases-merge-resolve.sh` lines 70–120
- Issue text: `gh issue view 684`, `gh issue view 686`, and #591's design decision (full-suite qualification is intentional; the plan keeps `--qualify --gate` untouched)

### Questions (answer each; cite file:line)
1. **Grounding.** Does the recon map describe the code as it is? In particular: is it true that a catch-up-recovered landing is indistinguishable from an explicit `--pr` landing once merged into `landing_items`, and that `ship_manifest_items` runs before `validate_and_update_doc` can die? If the plan's line ranges or claims are wrong, say where.
2. **S2 placement.** The plan checks `validate_lessons_learned` *before* `ship_manifest_items` for catch-up-sourced landings only, warns, counts, and `continue`s; explicit landings keep `die(code=5)`. Is there any write earlier in the per-issue path (e.g. via `qualify_landings`, `check_provenance_receipts`, receipts under `TESTS-RESULTS/`) that a skipped item would still leave behind, so that "skip = no writes for that issue" is false? Is a skipped item guaranteed to be re-found by `catch_up_prs` on the next run (doc in `2-WORKING`, row not Completed)?
3. **S2 exit semantics.** The run exits 0 with `SKIPPED` lines and the commit step lands the other transitions. Is there a consumer (the `--gate`/`--qualify` receipt logic, `unreconciled_prs`, the idempotency test in gh421, `merge_cleanup.py`) for which "exit 0 but one item unreconciled" breaks an invariant? If so, name it and the input that breaks it.
4. **S1 design.** A final `if: always()` step runs a new stdlib tool `utils/py/hosted_lane_report.py` that reads a log `tee`d to `$RUNNER_TEMP` and opens/comments/closes exactly one issue labelled `hosted-reconcile-attention`. Is a separate small tool the right seam versus (a) inline `gh` in the YAML, or (b) a flag on `wave_reconcile.py`? Is `$RUNNER_TEMP` the right place given the commit step's undeclared-artifact refusal? Does `permissions: issues: write` on the job suffice for `gh issue create/comment/close` with `github.token`?
5. **S3 correctness.** Is "keep one `settings` row per key — for `generation` the higher value, then the later `updated_at`" the right dedupe for the fixture's union, and does it match what `releases-merge-resolve.sh` expects a human to do? Is there another settings key that can differ across sides in this fixture? Is forcing the second boundary (`sleep 1.1` between the sides' writes) an acceptable deterministic control, or should the fixture rewrite `updated_at` instead?
6. **Missing requirement.** Is anything in #684's ask (as amended by #591) or #686's ask not covered by S1–S4? Is anything in S1–S4 *not* asked for (scope creep)?
7. **Acceptance checks.** For each of the checks in "Acceptance checks (falsifiable)": would it actually go red if the corresponding change were reverted? Name any check that would stay green on the unfixed code.
8. **Commensurate complexity.** Is any part of S1–S4 more machinery than the requirement needs? Is the test footprint (two cases + pins in gh421, one new suite of ~7 cases for the report tool, a 10× loop for gh53) proportionate?

Output: graded bullets `[Blocker]` / `[Should]` / `[Nit]` / `[Pass]` per question, `file:line` for every disagreement with a specific claim, then a verdict. Set `STATUS: Approved` only if no `[Blocker]` or `[Should]` remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
