# RELAY · PR1327 preserved remediation source QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-09.
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
6. **Commit only the relay file** (`relay(pr1327-preserved-remediation-source-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/packet.md** — the read-only path that
  `relay-drive.sh --artifact-file temp/qa1327/packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: claude-opus   ·   Producer: codex-parent
- Started: 2026-11-09
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 (claude-opus)

swept file: yes — read in full `utils/py/marathon_plan.py` (214 lines); read the Bash twin's dispatch shim, flag parser and mode tail (`utils/marathon-plan.sh:24-46,113-160,1176-1204`); read `wave_reconcile.run_subprocesses` and `_plan_docs` (`utils/py/wave_reconcile.py:1986-2093`); read the `test/marathon-plan.sh` helpers plus Scenarios T and U (`:48-83,675-756`); read the `test/gh418-planner-ledger-source.sh` `plan()` harness (`:72-98`), the 10days step 5 and the start-marathon planner steps; read the commits `ebb24925`, `cf799f0d`, `44cb3aa3` and `eac96fb5`. Every probe was a read-only grep, sed or `git show`/`git log`. I ran no planner, test or validate.

**Basis for the definition of done:** the Setup DoD is still the `_<fill in>_` placeholder, so I graded against the four questions in `.relay-artifacts/packet.md:5-9`.

- **[Blocker] Q2: a second in-repo consumer that expects the generated file still runs the planner without `--write`. It is `skills/2-daily/start-marathon/SKILL.md:258`.**
  The skill says: "Write the canonical plan with the planner **without** `--dry-run` only when the file is absent, inspect its diff, and run `--check`." Under the candidate, "without `--dry-run`" is the bare run, and the bare run is now report-only. `marathon_plan.py:64` defaults `run_mode = "dry-run"`, and `:199-201` exits before the write at `:203-207`. The Bash twin does the same at `utils/marathon-plan.sh:139` and `:1196-1198`. When start-marathon then runs `--check`, it hits `marathon_plan.py:184-187`, prints `check: missing artifact`, and exits 1. That is the same defect class as the 10days caller fixed in `eac96fb5`. The skill text has not changed since `6f956294` (#765, 2026-09-25), and `git diff cf799f0d eac96fb5` leaves it unfixed. So the corrected claim at `TESTS-RESULTS/2026-11-03+GH-446/SUMMARY.md` ("earlier claim no in-repo skill callers was incomplete"), and its implication that 10days was the only gap, is still incomplete.
  Observed input: start-marathon's secondary route on a repo with no `PROJECT/2-WORKING/MARATHON-PLAN-<today>.md`. The agent follows `:258` literally (`python3 "$HARNESS/utils/py/marathon_plan.py" --deep`, no `--dry-run`), which writes nothing, and the next `--check` exits 1 with `missing artifact`.
  Affected scope: documentation only, in one skill. A command phrased as "the planner without `--dry-run`" should become "the planner with `--write`". Planner code does not change.
  Fix: in `skills/2-daily/start-marathon/SKILL.md:258`, replace "**without** `--dry-run`" with "with `--write`". Also amend the SUMMARY.md and takeover-relay correction lines to name start-marathon as the third caller. As with 10days, the deployed Skills Army copy has to be refreshed after landing.
  Falsifier: a grep of the candidate for `without\*\* \`--dry-run\`` in `skills/2-daily/start-marathon/SKILL.md` that returns nothing, or a start-marathon step that already passes `--write` before its `--check`. Expected result: neither exists at `eac96fb5`. The grep matched at line 258, exit 0.

- **[Pass] Q1: the mode semantics agree across both lanes.** Python parses `--write`/`--dry-run`/`--check` at `marathon_plan.py:72-80` and Bash at `utils/marathon-plan.sh:146-148`. Both are last-flag-wins, so their precedence is identical. The default is dry-run in both (`marathon_plan.py:64`, `marathon-plan.sh:139`). On return status, `--check` exits 1 when the file is missing or has drifted and 0 when it is in sync (`marathon_plan.py:183-197` ≡ `marathon-plan.sh:1181-1193`). Dry-run and write both exit with the engine's rc (`:199-210` ≡ `:1196-1204`). An unknown flag prints usage and exits 2 (`marathon_plan.py:102-107` ≡ `marathon-plan.sh:153`). The shim passes `--write` through untouched (`marathon-plan.sh:30-43`, where only `--zones-config` is translated).

- **[Pass] Q2, partial: reconcile and 10days are fixed.** `wave_reconcile.py:2009-2013` appends `--dry-run` or `--write`. `_plan_docs` (`:1986-1990`) snapshots before the replan and tracks new docs only on the non-dry path (`:2091-2092`), which is consistent with `--write`. 10days now reads `"$HARNESS/utils/marathon-plan.sh" --write --deep` (`skills/3-weekly/10days/SKILL.md:379`). start-marathon's primary route already uses `--dry-run --deep` deliberately (`:249`). `gen4_campaign.py:76` uses only a `--help` base.

- **[Pass] Q3: the mutation-control fix is correct.** `test/marathon-plan.sh:716` now runs the mutant with `--write`. Without it, the mutant's bare run (`:716`, pre-`44cb3aa3`) wrote nothing, and `:717` would have compared `shell.md` against the Python render left by `:687`. The `run_qp*` helpers prepend `--write` (`:53,61,82`), and a later `--dry-run`/`--check` still overrides it because the last flag wins, so the dry-run comparisons at `:680-681` remain dry. gh418 does the same (`gh418-planner-ledger-source.sh:90`, `[cli_path, '--write', *args]`). Commit `ebb24925` carries `Frozen-twin-exception: utils/marathon-plan.sh — …`, which names the file. `44cb3aa3` and `eac96fb5` do not touch the frozen twin, so they need no trailer. Both commits change one line in an existing suite and one line in a skill. Neither adds a suite or a `validate.sh` registry entry (diff stats above).

- **[Pass] Q4: the evidence claims are truthful.** SUMMARY.md says "Normal exact-composition push gate pending", and the takeover relay says "Normalfullgatepending … notclaimingreviewerinspectedlaterbytes". Neither claims publication. I found no regression or excess scope beyond the Blocker.

- **[Nit] `utils/py/marathon_plan.py:12`: the docstring is now false.** It still reads "CLI contract (unchanged): [--dry-run | --check] …". The contract did change, and the docstring omits `--write`. Fix: change it to `[--write | --dry-run | --check]`, matching `print_usage` at `:45`, and drop "(unchanged)". No behaviour change.

- **[Nit] The appended correction paragraphs have their spaces stripped.** Examples are "Independent Codex source review atcf799f0 …" in `TESTS-RESULTS/2026-11-03+GH-446/SUMMARY.md` and the line added to `relay-system/2026-11-09/gh446-takeover.codex.md`. Fix: restore word spacing when the start-marathon caller is added.

- **[Nit] The suite does not pin the core contract change.** No suite asserts that a bare run writes nothing; that is proven only by the manual table in `gh446-check-output.txt`. This is acceptable under the packet's "No new tests/gates" envelope. I am recording it, not requesting it.

**VERDICT: FAIL**
**Basis:** Q1, Q3 and Q4 pass, with citations. Q2 fails. A real in-repo consumer, `skills/2-daily/start-marathon/SKILL.md:258`, still tells the agent to write the plan by running the planner "without `--dry-run`". Under the new default (`marathon_plan.py:64,199-201`) that writes nothing, and the skill's next step, `--check`, then exits 1 with `missing artifact` (`:184-187`). The remediation's claim of caller completeness is therefore still incomplete. The fix is a one-line doc change plus corrected evidence text. The full classified gate is still pending and is not covered by this review.

handing off to Producer (codex-parent): go to the codex-parent window and say "take your turn".

### Producer disposition — parent Codex

- start-marathon caller finding: Accepted, deferred. The source instruction still assumes the old default. Existing SUMMARY explicitly records two prior ordinary readiness repairs, so no third repair is authorized. No production files changed in this review preparation.
- CLI docstring Nit and spacing Nit: Accepted as editorial findings, deferred with the held candidate; do not publish a partial fix as ready.
- No-suite-assertion Nit: No action; existing manual proof is the allowed verification path under GH831.
- Source review is FAIL (driver5), not Approved. Final full gate/publication not run. Original candidate and all prior review history remain preserved; this review confers no extra attempt budget.

### Operator-authorized continuation — parent Codex

The user explicitly instructed: "For the one that has a repair limit hold, review and take it over to finish it for approval." Scope is PR1327, one additional bounded readiness repair, not a reset or new allowance for other PRs. The original two repairs are preserved; the canonical attempt record reserves this exception as third/final, with authorization noted before mutation.

Implemented the accepted start-marathon caller correction: explicit --write on the secondary file-generation path. Corrected the Python CLI docstring Nit. Preserved old review/history text, adding a readable current SUMMARY correction rather than rewriting historical records. No new suite/registry entry/runtime behavior. Current development merged cleanly before this correction. R2 should check the whole composed source and all known file-expecting consumers; focus tests and final full publication gate remain pending and are not claimed by this review.

### Reviewer · Round 2 (claude-opus)

swept file: yes. I read the whole `0b597d7b7` diff (`git show`, 5 files). I re-read the `marathon_plan.py` docstring and mode parser (`:1-20,64-80,183-210`), the Bash twin's usage header and parser (`utils/marathon-plan.sh:60-80,136-150`), the `wave_reconcile.py` plan step (`:2005-2013,2057-2061`), the `hosted_lane_publish.py` recompute (`:169-181`), and start-marathon `:240-262`. I also swept every planner invocation in `skills/ utils/ relay-automation/ bin/ ROUTER.md HOW-TO-USE.md AGENTS.md docs/ PROJECT/2-WORKING` with `grep -rnE '(marathon-plan\.sh|marathon_plan\.py)"?[[:space:]]+(-|\$|")'` (exit 0) and checked the Python importers. Every probe was a read-only grep, sed or `git show`/`git log`. I ran no planner, test, fixture or validate.

- **[Pass] The R1 Blocker is fixed.** `skills/2-daily/start-marathon/SKILL.md:258` now says "Write the canonical plan with the planner **with** `--write` only when the file is absent, inspect its diff, and run `--check`". The falsifier grep for "without `--dry-run`" now returns no planner hits under `skills/ docs/ ROUTER.md HOW-TO-USE.md`. Its only match is `skills/3-weekly/end-of-week/SKILL.md:214`, which is about `work backfill`, not the planner.
- **[Pass] Every file-expecting consumer is now explicit, and none is left over.** Reconcile's live path appends `--write` (`wave_reconcile.py:2012-2013`) and its dry path appends `--dry-run` (`:2011`). 10days reads `"$HARNESS/utils/marathon-plan.sh" --write --deep` (`skills/3-weekly/10days/SKILL.md:398`). The start-marathon secondary route is fixed as above. Its primary route (`:249`), table (`:103`) and default note (`:54`) deliberately keep `--dry-run`. `hosted_lane_publish.py:171-174` regenerates the plan only through the reconciler, so it inherits `--write`. The Python importers (`harness.py:401-412`, `marathon_drive.py`) use `_marathon_plan.Engine` and not the CLI. `gen4_campaign.py:76` uses only `--help`. `HOW-TO-USE.md:36` uses `--dry-run`. I found no other invocation that expects a file.
- **[Pass] The metadata describes the new contract.** The Python docstring is now `CLI contract: [--write | --dry-run | --check] …` (`marathon_plan.py:12`), which fixes the R1 Nit. The Bash header says `# report on stdout; writes nothing (GH-446)` for a bare run and `--write # report + write today's marathon-plan doc` (`utils/marathon-plan.sh:70-71`). Both lanes default to dry-run (`marathon_plan.py:64`, `marathon-plan.sh:138`), so the R1 Q1 parity still holds. The frozen-twin exception is named in `ebb24925d` ("Frozen-twin-exception: utils/marathon-plan.sh — same contract change as the Python lane (GH-446)"). `0b597d7b7` does not touch the twin.
- **[Pass] The evidence is truthful and the scope is bounded.** The new SUMMARY section says "Final focused verification, independent recheck and normal full publication gate are still pending; no new suite or gate is added", and it names "reconcile, 10days and start-marathon". The provenance row records `"prior_repairs": 2, "authorized_additional_episodes": 1, "reserved_attempt_index": 2` and `"review": "R1 FAIL retained;R2 pending"`. The earlier findings are kept and not rewritten. The diff changes one line in a skill and one docstring line, and adds two evidence appends. It adds no suite and no registry entry, and changes no runtime behaviour.
- **[Nit] Some of R1's space-stripped paragraphs are still there.** Examples are "atcf799f0" in the older SUMMARY text and the line in `gh446-takeover.codex.md`. The Producer chose to preserve that history and append a readable correction instead. That is acceptable. No action needed.
- **[Nit] [Unverified — needs landing check] `CHANGELOG.md` has no `GH-446` entry** (`grep -n 'GH-446' CHANGELOG.md` returned no output). This turns a bare-run behaviour change into one that needs `--write`. If PDDA's landing rule requires a changelog line, add it at landing, not as another readiness repair.
- I found no pre-existing defects in the reviewed sections beyond these points.

**VERDICT: PASS**
**Basis:** The one R1 Blocker, the start-marathon secondary writer, now passes `--write` (`SKILL.md:258`). A repo-wide invocation sweep found no other consumer that expects a file but runs bare. The Python and Bash mode semantics and their docs agree, the frozen-twin exception is named, and the evidence makes no false gate claims. This approval covers source QA only. Focused tests, the normal full publication gate, the hosted check and the merge remain separate and pending. I did not verify them here.

relay closed (Approved), no further turn needed. Hand back to codex-parent for the pending focused verification and the full publication gate in a disposable clone.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
