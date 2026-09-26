# RELAY · GH-836 plan review — trim the measured gate hotspots
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-26.
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
6. **Commit only the relay file** (`relay(gh836-plan-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh836-plan.md** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/0cc9b6f4-22bd-4606-b4ec-21e1b8f38591/scratchpad/gh836-plan.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-26
- Definition of Done: **Approved** when all of these hold:
  - (a) each recon claim R1–R5 matches the cited code and baseline evidence;
  - (b) each plan step removes measured cost without weakening what its leg or test proves, and names a red
    control that would catch the weakening;
  - (c) the plan adds no suite, registry entry or gate machinery, and touches only existing `test/` files and
    the plan;
  - (d) the red controls are falsifiable and not flaky, including step 1's smaller race window;
  - (e) the rating `70/45/50/70` and its rationale are grounded, and appeal is neutral (the operator set none).

## Review packet

**What this is.** The plan for #836 (`https://github.com/HiQS-Labs/XYZ-forge/issues/836`): trim three measured
test-side hotspots in `test/gh549-work-events.sh` and the `gh436` suite (`test/gh436-merge-cleanup.py`,
`test/gh534_phase_c_tests.py`), and fix `test/gh649-pdda-migration.sh`'s `/tmp` false red. The artifact is
`.relay-artifacts/gh836-plan.md`, a copy of `PROJECT/2-WORKING/GH-836-GATE-HOTSPOTS.md` at `5d463095`. The
branch is `fix/gh836-gate-hotspots` in this worktree.

**Operational envelope.** A single-repo local developer harness. The operator has ruled "no new tests"
(AGENTS.md): verification is by existing suites and recorded manual checks. The work is small edits to three
existing suites. Grade against the plan's stated requirements and commensurate complexity. Do not ask for new
suites, new helpers beyond the one extended helper, or runner changes.

**Read:**
- the artifact;
- `test/gh549-work-events.sh`: lines 160-165 (`seed_cursor_tail`), 935-1072 (section 21, especially the 21e red
  control at 1043-1072), and 1073-1190 (section 22, `rr`, 21f and its red controls);
- `utils/py/releases_app.py` 1610-1630 (`_dispatch_work_connectors`) and 5262-5275 (`_scan_review_ready`), for
  what `XYZ_WORK_CONNECTORS=0` switches off;
- `test/gh534_phase_c_tests.py` 522-600 and 920-966, and `test/gh436-merge-cleanup.py` 855-869;
- `test/gh649-pdda-migration.sh` 1-16 and `skills/4-occasional/vendor-stack/find-pdda.sh` 18-28;
- the baseline in `TESTS-RESULTS/2026-09-26+GH-836/` (`baseline-gh549-top-gaps.txt`,
  `baseline-gh436-durations.out`).

You may run read-only probes, but no suites: they belong in a disposable clone.

**Questions** (cite `file:line`):

1. **Step 1 (21e).**
   - Does bounding the mutated copy's sleep to the first 3 emits per process keep the red control reliable?
     Consider process start skew between the two `&`-launched racers, and whether both walk rows in the same
     order.
   - Is 3 enough, or should it be larger?
   - Is the process-global counter in the inserted text sound (Python `global` inside the mutated function)?
   - Does anything else in 21e depend on the per-row sleep?
2. **Step 2 (21f).**
   - Is it right that 21f's and red (iii)'s assertions never read board state, so `work backfill` can run with
     `XYZ_WORK_CONNECTORS=0`?
   - Does advancing the github_board cursor to the current tail before the next reconcile change what those
     reconciles do beyond skipping the replay? In particular, does review_ready emission depend on the cursor?
   - Is extending `seed_cursor_tail` with an optional id the least machinery?
   - Are the plan's listed backfill call sites (`:1127`, `:1132`, `:1141`, `:1178`) complete and correct?
3. **Step 3 (`gh436`).**
   - Is removing `run_tests` safe, given that all 17 named tests are in `gh436`'s collection (the recon's
     probe)?
   - Does GH-534's "exists and runs" requirement stay honest when "runs" means "runs in this same suite
     invocation"?
   - Is any named test excluded from collection in some mode, such as a skip decorator or an underscore name?
   - Are the two proposed red controls the right witnesses?
4. **Step 4 (`gh649`).** Is `pwd -P` the complete fix? Does anything else in the suite compare paths logically?
5. **Scope and machinery.** Anything over-built, under-built, or out of scope? Anything that should move to the
   operator decisions D1–D3 instead?
6. **Rating.** Is `70/45/50/70` grounded in the rationale?

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
