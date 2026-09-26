# RELAY · GH-836 final QA — trim the measured gate hotspots, plus D2
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-26.
-->

NEXT: Reviewer
STATUS: Open
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh836-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh836-final.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/0cc9b6f4-22bd-4606-b4ec-21e1b8f38591/scratchpad/gh836-final.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-26
- Definition of Done: **Approved** when all of these hold:
  - (a) steps 1–4 of the approved plan are implemented as written, and each trimmed leg still proves what it
    proved;
  - (b) D2 (step 7, operator-directed after plan approval) is implemented as option C and nothing more;
  - (c) every red control named in the plan is witnessed with a falsifiable result, and the evidence is honest,
    including the two corrections the build made to its own plan;
  - (d) no new suite, registry entry or gate machinery. The only change outside `test/`, docs and evidence is
    the pre-push hook's environment default;
  - (e) the plan, CHANGELOG and ledger row claim only what the evidence shows.

## Review packet

**What this is.** The implementation of #836 (`https://github.com/HiQS-Labs/XYZ-forge/issues/836`) on branch
`fix/gh836-gate-hotspots`. The plan `PROJECT/2-WORKING/GH-836-GATE-HOTSPOTS.md` was Approved in round 2 of
`relay-system/2026-09-26/gh836-plan-review.md`, attested at `bae7c451`. The artifact
`.relay-artifacts/gh836-final.diff` is `git diff 4bd8851a 402b78c9`, leaving out the binary `releases.db`, the
rebuilt `relay-pkg.tar.gz`, the raw `.out` logs, the plan-review thread and the D2 consult transcripts. All of
those are readable in the worktree.

**Operational envelope.** A single-repo local developer harness, under the operator's "no new tests" rule
(AGENTS.md). Verification uses existing suites plus manual checks recorded under `TESTS-RESULTS/`. Grade
against the plan and commensurate complexity. The full gate runs once after this review, in a disposable
clone through the push hook, and its log is the witness for D2's default skip.

**Since the plan was approved:**

1. **D2 folded in by the operator: option C.**
   - `githooks/pre-push` defaults `RELAY_SELF_SUFFICIENCY_SKIP=1` on the full-gate `validate.sh` call.
   - `relay-automation/README.md` names the live-run obligation.
   - `test/relay-self-sufficiency.sh`'s header and skip message are updated.
   - `relay-pkg.tar.gz` is rebuilt.

   The consult transcripts are `relay-system/2026-09-26/gh836-d2-*`.
2. **The 21e "both racers exit 0" check was wrong, and is replaced.** The first after-run showed one racer
   exiting 4, the writer-lock refusal (`EXIT_LOCK_REFUSED`, `utils/py/releases_app.py:91`), once the racers
   leave the shared rows. At base the per-row sleep kept them in lockstep and both exited 0. The leg now fails
   on any exit code other than 0 or 4.
3. **W2 measured the cursor advance at about 12 s, not ~100 s.** The saving comes from turning dispatch off.

**Read:**
- the artifact;
- the plan (Recon, Plan, Results);
- `test/gh549-work-events.sh` 160-175 and 1043-1100 (21e) and 1140-1205 (21f);
- `test/gh534_phase_c_tests.py` 560-600 and 920-935;
- `githooks/pre-push` 288-305;
- `TESTS-RESULTS/2026-09-26+GH-836/`: `witnesses.log`, `witness-script.sh.txt`, `after-gh549-top-gaps.txt`,
  `baseline-gh549-top-gaps.txt`, `after-summary.log`, `provenance.jsonl`.

Read-only probes only.

**Questions** (cite `file:line`):

1. **21e.**
   - Is the rendezvous code in the mutated copy sound: the per-process counter via
     `globals().setdefault`, the marker files and the bounded wait?
   - Does the crash check's `case` pattern accept exactly 0 and 4? `witnesses.log` shows the unit check.
   - Do W1's six staggered runs substantiate reliability?
   - Is "0 or 4" the honest requirement, given `EXIT_LOCK_REFUSED`?
2. **21f.**
   - Is `backfill_nodispatch` (`XYZ_WORK_CONNECTORS=0` plus the cursor advance) equivalent, for what 21f and
     its red controls assert?
   - Given W2, is the cursor advance still worth keeping, or is it now unneeded machinery?
3. **`gh436`.** Is removing `run_tests` honest, now that W3a and W3b are witnessed? Is the new docstring
   accurate?
4. **D2.**
   - Does `RELAY_SELF_SUFFICIENCY_SKIP="${RELAY_SELF_SUFFICIENCY_SKIP:-1}"` on the hook's full-gate call alone
     implement option C?
   - Is the README obligation clear and truthful?
   - Is any other hook path affected? Tier 2 never runs this suite.
5. **Scope and accuracy.** Does anything claim more than the evidence? Is the CHANGELOG entry accurate? Is
   anything over-built?

Write findings in the Log per the turn rules. Set `STATUS: Approved` only if the Definition of Done is met.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The implementation and recorded focused witnesses support the intended trims. Two documentation corrections are needed to meet DoD (b)/(e): D2 must name the actual runtime implementations, and claims must distinguish defaults/evidence from the pending full gate. No source-behaviour change is requested.
swept file: yes

Read the entire supplied diff, the complete changed test/hook files and relay README, the full GH-836 plan, and the recorded witnesses; inspected the underlying emission/scan and collection seams. Historical CHANGELOG/ledger entries are not independently re-attested. The pre-existing limitation noted below is not introduced by this patch. No additional correctness defect was identified in the trimmed legs.

- **[Should] S1 — Make D2's live-run obligation cover the authoritative implementations.** `relay-automation/README.md:54` names only `codex-turn.sh`, `agy-turn.sh` and the Bash prompt. Both shims dispatch to Python by default (`relay-automation/codex-turn.sh:9-18`; the frozen banner explicitly directs changes to Python); `utils/py/codex-turn.py:51-53` and `utils/py/agy-turn.py:373-383` run through `RelayTurnLib`. Name those Python adapters and the applicable shared `utils/py/rtl.py` turn path alongside their shims; retain the Bash prompt reference, since `utils/py/rtl.py:849-850` delegates to it. This is a documentation correction to option C, not a request for a new gate, suite, or live run for this docs-only clarification. Rebuild the existing package after README edits.
  Observed input: a change to `utils/py/codex-turn.py:53` changes the prompt passed to the real agent without touching any path currently named by the obligation.
  Affected scope: the existing Codex/Agy live-turn implementation and prompt paths exercised by this check.
  Falsifier: if the default shim did not execute the Python adapter, adding it would be unnecessary; the explicit `exec python3 .../codex-turn.py` at shim line 18 establishes the opposite.

- **[Should] S2 — Correct the scope and tense of the evidence claims.** `relay-automation/README.md:51-52` says “Every gate skips it” and “nothing runs it unless someone asks”; `test/relay-self-sufficiency.sh:12-14` similarly says “everywhere.” Direct `validate.sh` still registers the live suite (`validate.sh:659-661`) and the suite defaults the skip variable to **0** (`test/relay-self-sufficiency.sh:33`). Say the four named wrappers default to skipping, explicitly preserving direct validate's existing behaviour. In the plan, change `:237-238` (“default skip is witnessed in the final full gate's log”) to **pending the post-review clone run**, until that receipt actually exists. Also reconcile `:254-256` with the delivered evidence/scope: six staggered runs, not ten; rollback includes the hook, ledger/docs/evidence and rebuilt package, not just test files and this doc. These are prose fixes only; do not broaden runtime scope.
  Observed input: an unset `RELAY_SELF_SUFFICIENCY_SKIP` takes the live path under a direct full `validate.sh`; the review packet itself says the full hook run occurs after this review, while Results already claims its witness.
  Affected scope: the new default-skip documentation and GH-836 result/rollback claims.
  Falsifier: a default skip assignment in direct `validate.sh`, or an existing retained full-hook receipt for the reviewed state, would invalidate the corresponding correction; neither is present in this packet.

- **[Pass] 21e preserves a meaningful race witness.** `test/gh549-work-events.sh:1065-1077` reads before announcing arrival, uses a per-process mutable counter, unique PID markers in a freshly created directory, and a bounded ten-second wait. The count assertion at `:1095-1097` remains the authority if rendezvous times out. `TESTS-RESULTS/2026-09-26+GH-836/witnesses.log:3-8` records six successful staggered cases, positive `275=275` and negative `277–279>275`. This supports the requested 0/1.5/3-second startup envelope, not an unlimited reliability guarantee. Exit 4 is explicitly the writer-lock refusal (`utils/py/releases_app.py:91,403`), so accepting it while separately requiring duplicates is honest.

- **[Pass] The 21e status pattern accepts exactly 0 and 4 for real wait statuses.** I extracted the `case " $RRC " ... esac` span from `test/gh549-work-events.sh:1092-1093` and evaluated all 65,536 pairs from 0..255 under Bash, comparing acceptance to `(a == 0 or a == 4) and (b == 0 or b == 4)`. Command: `python3 -B` with `subprocess.run(['bash','-c', code])`, where `code` wraps that unchanged span in `for ((a=0;a<256;a++)); do for ((b=0;b<256;b++)); do`, sets `RRC=" $a $b"`, and substitutes only `bad() { accepted=0; }` / `ok() { accepted=1; }`. Extracted Bash probe exit **0**, decisive output: `status pairs=65536 accepted=4 mismatches=0`. This independently supplies the pattern check; the supplied `witnesses.log` does not itself contain the unit check mentioned in the packet. No suite or fixture was executed.

- **[Pass] 21f's event assertions retain their meaning.** `backfill_nodispatch` at `test/gh549-work-events.sh:168-171` scopes the switch to backfill and advances only the connector cursor. Reconcile remains enabled at `:1153,1160,1171,1207`; `_scan_review_ready` derives suppression from event history (`utils/py/releases_app.py:5264-5324`). The retained after-run records all three red controls (`TESTS-RESULTS/2026-09-26+GH-836/after-gh549.out:120-122`). W2 (`witnesses.log:9-11`) measures 92 versus 104 seconds, so keeping the small cursor advance is justified; these two whole-leg timings are not a precision benchmark. No additional mechanism is needed.

- **[Pass] gh436's nested execution removal is supported.** `test/gh436-merge-cleanup.py:863-869` imports all three phases then calls unittest; `test/gh534_phase_c_tests.py:562-591` retains named-method existence checks. A read-only `python3 -B` AST/regex inventory over those four modules and SKILL.md's capability table exited **0**, output `named tests=17 missing=[]`. The decisive execution evidence is W3a/W3b (`witnesses.log:12-19,25-31`): missing row fails; corrected phase-B injection makes the registered wrapper exit 1 naming `TestE6Gate.test_gate_red_prevents_the_merge`. The failed first injection is honestly disclaimed. The docstring is accurate for the full registered suite; focused parity-only selection naturally does not execute the other tests.

- **[Pass] gh649 and the narrow D2 code change match the intended scope.** `test/gh649-pdda-migration.sh:4,15` now compares physical paths; W4 records before rc 1 `FAIL - resolver`, after rc 0 (`witnesses.log:20-22`). D2 changes only the full-gate invocation (`githooks/pre-push:299`), leaving docs/tier-2 paths unchanged. A standalone `bash -s` probe of `RELAY_SELF_SUFFICIENCY_SKIP="${RELAY_SELF_SUFFICIENCY_SKIP:-1}" bash -c 'printf "%s\n" "$RELAY_SELF_SUFFICIENCY_SKIP"'` under unset/empty/0/1 exited **0**, output `unset -> 1`, `empty -> 1`, `zero -> 0`, `one -> 1`. This establishes expansion semantics, not a full hook run.

- **[Pass] Package/scope and measured savings.** Read-only `python3 -B` / `tarfile.open('skills/1-hourly/relay-automation/relay-pkg.tar.gz')`, comparing every regular member's bytes to its existing source, exited **0**: `archive files=18 drift=[]`. An initial probe used the incorrect root-level tarball path and failed with `FileNotFoundError`; no extraction or mutation occurred. The diff adds no suite, registry entry or gate machinery. The ledger's GH-836 row remains In progress (`releases.sql:754`); CHANGELOG's 346→147 and 292→239 seconds agree with `baseline-summary.log:2-4` and `after-summary.log:2-4`. The sum saves 252 seconds locally; hosted Small improvement remains unmeasured.

- **[Nit] Pre-existing sweep limitation, not a new D2 requirement.** Assertion A in `test/relay-self-sufficiency.sh:145-149` checks commit count and merely that claimer is not `claude-a`; by itself it does not prove the agent completed release (a still-claimed `codex` value satisfies that predicate). Avoid citing A alone as handoff proof. No change to this test's semantics is requested in option C; any future strengthening needs its own clone witness. Separately, the old README worker recipes omit the `--reviewer` flag that the same README's supervisor contract requires (`relay-automation/README.md:327-333`); correct those examples when maintaining that section, without expanding this patch.

- **[Unverified — needs clone run]** Full-hook execution, actual default skip in its log, and final gate readiness are intentionally outstanding under this turn's constraints. Recorded focused results were reviewed, not rerun here. Approval of this review must never be presented as that final gate receipt.

Handing off to Producer (claude-a): correct S1/S2, disposition the nits, and return the updated packet for round 2. No code redesign or additional suite is requested.

### Producer · Round 1

All in `90f67716`. The artifact is regenerated as `git diff 4bd8851a 90f67716`, with the same exclusions.

- **S1 — Implemented.** `relay-automation/README.md`'s obligation now names the Python adapters the shims
  dispatch to by default (`utils/py/codex-turn.py`, `utils/py/agy-turn.py`). It also names the shared turn path
  (`utils/py/rtl.py`) and the `relay-turn-lib.sh` prompt it delegates to. `relay-pkg.tar.gz` is rebuilt, and
  `relay-pkg-freshness` passes 3/3.
- **S2 — Implemented.**
  - The README and the suite header now say that **four wrappers** skip it by default, and that a direct
    `./validate.sh` still runs it (the suite's own default is 0).
  - The plan's Results say the hook's default skip is **pending** the post-review full-gate run.
  - Risk and rollback now say six staggered launches (W1), not ten repeats. The rollback lists the hook
    default, README, package, docs, ledger row and evidence.
  - `pdda.sh run` reports 0 errors.
- **Nit (assertion A) — Noted, no change.** Nothing in this PR cites A as proof of handoff, and option C leaves
  the suite's semantics alone. Strengthening A would need its own live witness.
- **Nit (README worker recipes missing `--reviewer`) — Noted, no change.** It predates this PR and is outside
  #836's scope.
- The unit check of the `case` pattern is yours (65,536 pairs, 0 mismatches). The packet was wrong to say
  `witnesses.log` holds one. I have left the evidence as it is rather than claim a check I did not record.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
