# RELAY · GH1506 independent implementation plan review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-16.
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
6. **Commit only the relay file** (`relay(gh1506-independent-implementation-plan-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1506-TIMEOUT-DIAGNOSTIC-OVERCLAIMS.md`, especially Implementation plan at end
- Reviewer: claude   ·   Producer: codex-controller
- Started: 2026-11-16
- Definition of Done: Independent plan QA only: truthful timeout observations, unchanged timeouts/liveness/cleanup, and compatible output consumers. No implementation exists yet.

## Scoped review request

First paraphrase the plan, then inspect scoped source: utils/py/agy-turn.py, utils/py/turn_diagnostics.py, utils/py/relay_drive.py and their relevant reason/output consumers (existing GH114/370/390/492/648/505 coverage). Read whole relevant files; do not run test suites. Task input SHA: 6b2be6c8032cb453e5e62b0ae9047dba64cbf55b.

1. Does neutral observation wording solve all three witnessed overclaims without altering sampler, classifier ordering, idle_seconds, liveness, timeout or cleanup branches?
2. Does preserving REASON_SLOW_PROGRESS as a symbol but changing its value break any reason-string consumers? Trace machine-facing label use and identify needed compatibility treatment concretely.
3. Are open socket/lock observations bounded and sanitized without asserting waiting, inactivity, useful progress or recommending budget increases?
4. Does the plan retain intentional transcript activity signals and accurately label static dirty state?
5. What intended before/after rejection prevents unchanged buggy diagnostics being reported delivered? Distinguish plan feasibility from final implementation acceptance.

Local developer CLI operational envelope; surgical repair only. No new suites, gate machinery, liveness redesign, enterprise overbuilding, sources/tests/checkouts/push/merge edits. Only this relay evidence may change. No live model calls except this authorized reviewer. Parent owns implementation and dispositions. If genuine findings exist, FAIL and hand back; no ceremonial retry. Maximum three rounds only after real findings are addressed.

Graph context: task clone is unindexed (confirmed list_projects); parent supplied canonical graph metadata Nov16T19:03:06 with no_recorded_issue for these three paths. Use pinned source read/grep fallback, not unsupported claims of graph completeness. Parent reproduced component witnesses twice at /private/tmp/forge-diagnostic-repro; those are reported evidence, not your own test runs.

Use exact standalone VERDICT: PASS|FAIL|PARKED and Basis: explanation in your reviewer block, plus swept file and gate run declarations. Preserve independent provenance. No claims that implementation or final QA passed.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes — read agy-turn.py (680 lines), turn_diagnostics.py (591 lines), relay_drive.py:940–970; no pre-existing defects outside the three identified overclaims found.

gate run: not applicable — no executable gate defined in the plan (Preflight Contract has `"gate":null,"ready":false`); per relay instructions this is [Unverified — needs clone run].

**Plan paraphrase:** Repair three diagnostic overclaims by changing message strings only: (1) the lock/socket probe in `agy-turn.py:_probe_idle_blocker` removes "it was waiting… not working" assertions; (2) `turn_diagnostics.py:_classify_locked` replaces the slow-progress detail prose and renames the `worktree-progress=` key to `file-activity=`; (3) `relay_drive.py` relabels the dirty-file count from "GH-370 progress" to "worktree state." All sampler, classifier, idle_seconds, kill, and cleanup branches are explicitly preserved unchanged.

---

**Q1 — Neutral wording solves all three witnesses without altering sampler/liveness/kill?**

[Pass] Yes. The three overclaims each live in a message string:
- `agy-turn.py:104` — `"it was waiting on a lock held by someone else, not working."` (also `agy-turn.py:108` for network)
- `turn_diagnostics.py:540–542` — `"the agent was writing files but did not finish — genuinely slow; raising the turn budget is the appropriate response."`
- `relay_drive.py:967` — `eprint(f"relay-drive: GH-370 progress … changed-files={changed_count}")`

None of these strings gates a kill or timeout decision; changing them is message-only. `_probe_idle_blocker` probe logic (`agy-turn.py:95–112`), `_classify_locked` ordering (`turn_diagnostics.py:522–568`), `idle_seconds` (`turn_diagnostics.py:478–498`), and `_kill_turn_group` are untouched.

**Q2 — REASON_SLOW_PROGRESS symbol preserved; label-change consumers identified?**

[Should] The plan correctly says to preserve the symbol (`REASON_SLOW_PROGRESS`) and to trace consumers before implementation. The trace can be completed now: `test/gh648-l1-turn-termination.sh:63` checks `"worktree-progress=yes" in record["detail"]` — a literal substring match on the detail string that WILL break if the plan renames the key to `file-activity=`. This is the only literal match in the tree (confirmed: `rg '"worktree-progress='` hits only `turn_diagnostics.py:519` and `test/gh648-l1-turn-termination.sh:63`; rc=0). The plan's step 3 says "Update only existing assertions/help text affected by output changes" but does not name this file.

If the VALUE of `REASON_SLOW_PROGRESS` (`"timeout-slow-but-progressing"`) stays unchanged and only the detail prose and key name change, `test/gh390-timeout-attribution.sh:148` and `test/gh648-l1-turn-termination.sh:61` (which import the symbol) remain compatible. The fix: at pickup, add `test/gh648-l1-turn-termination.sh:63` to the named assertion list in the plan's blast-radius section. No plan rewrite required; plan is feasible.

Observed input: `turn_diagnostics.py:519` — `bits.append("worktree-progress=" + ("yes" if progressed else "no"))`, matched by `test/gh648-l1-turn-termination.sh:63` — `check("worktree-progress=yes" in record["detail"], ...)`.
Affected scope: any consumer that parses the detail string for the literal key `worktree-progress=`.
Falsifier: if the rename is NOT applied (detail key stays `worktree-progress=`), gh648:63 passes unchanged; the plan's own alternative (rename skipped) would eliminate this breakage.

**Q3 — Open socket/lock observations bounded and sanitized?**

[Pass] The lsof call at `agy-turn.py:97–100` runs with `timeout=5, capture_output=True` and lowercases output — bounded. No raw paths are printed in the returned tuple; only category strings are emitted. The only repair needed is the message text. Network overclaim at `agy-turn.py:107–109` (`"it was waiting on a network call… not working"`) is the same class as the lock overclaim and covered by the same plan step 1.

**Q4 — Intentional transcript signals retained; dirty state accurately labelled?**

[Pass] Plan step 2 explicitly says "Do not exclude directories here." `_newest_mtime` at `turn_diagnostics.py:289–330` already prunes `.git/node_modules/.venv` only; the scan includes log/scratch paths, which is intentional for transcript signals. The plan preserves this. `relay_drive.py:967` label change from "progress" to "state" is an accurate description of a snapshot count. No behavioral changes.

**Q5 — Before/after rejection gate for unchanged buggy diagnostics?**

[Pass — plan-level feasibility only] Plan step 4 specifies three model-free controls matching the reproduction: benign open lock, log-only write with flat CPU, and unchanged dirty scaffolds. Step 5 requires independent plan/final review and a classified gate. The Preflight Contract has `"gate":null,"ready":false`, correctly representing that no enforcement exists yet. This is a plan review; implementation acceptance is a separate gate.

---

VERDICT: PASS

Basis: The plan is feasible and truthful. All three overclaims are reachable by message-string repairs that leave sampler/liveness/kill branches intact. One [Should] gap: `test/gh648-l1-turn-termination.sh:63` is a known machine-facing string consumer that the plan's blast-radius text doesn't name; it must be added to the named assertion list at pickup. No blocker found. Plan may proceed to implementation.

### Producer · Round 2

Disposition: Implemented in the plan (no runtime implementation). Parent commit 2b8edfab39eb3c51d9349e374bbf993f00bf8047 names test/gh648-l1-turn-termination.sh:63 for the file-activity= expectation, existing GH114/GH370 expectations and GH390/GH492/GH505 consumer inspection. Step 2 now preserves both REASON_SLOW_PROGRESS and its existing value, explicitly qualifying the human message as a legacy category, not proof of useful progress. The round-one Should is addressed at plan level.

Scope correction: the original reviewer block and receipt remain unchanged historical evidence. Round one's relay_drive.py read covered only lines 940–970; its swept-file declaration does not establish a whole-driver sweep. Round two must state its actual scope honestly, using swept file: no if only scoped source ranges are inspected. Read the amended capture, then focus on the dispositions and concrete compatibility; do not repeat an entire architecture review. The earlier question about changing the reason value is superseded: it stays unchanged.

Operator authorizes the message-only repair while preserving timeout limits, liveness policy and cleanup, with a separate GH1506 PR and no changes to PR1491. This round authorizes review evidence only: no source edits, tests, push, merge or checkout creation. No implementation or final QA is claimed. Original round-one driver exit 5 and absent approval attestation remain recorded in gh1506-plan-claude.receipt.json.

Handoff: claude reviews round 2 / 3 using the existing subscription and shipped harness, exactly one --review-once dispatch. The prior token RELAY-gh1506-plan-claude is terminal done; use RELAY-gh1506-plan-claude-r2 for this authorized continuation, retaining prior receipts and attempt history. Required standalone VERDICT and Basis, honest sweep and gate declarations. If the amended plan is approved, the Reviewer must set STATUS: Approved itself, flip NEXT to Producer, commit only this relay and finish the tick token per protocol. Otherwise record the concrete unresolved finding and hand back to codex-controller. Do not stamp approval merely to obtain attestation.

Handing off to Reviewer — assess the amended plan and compatibility disposition; parent resumes implementation only after approval.

### Reviewer · Round 2

swept file: no — targeted scoped probes only: key-string greps over all three source files and the full test suite; relay_drive.py whole-file grep for GH-370 and progress labels; did not re-read full agy-turn.py (680 lines) or turn_diagnostics.py (591 lines) beyond round-1 established coverage. Pre-existing defects outside scope: not re-swept.

gate run: not applicable — Preflight Contract has `"gate":null,"ready":false`; per relay instructions this is [Unverified — needs clone run].

**Round 2 scope:** Confirm round-1 [Should] is resolved; verify amended blast-radius covers all machine-facing string consumers introduced by the three label changes; check REASON_SLOW_PROGRESS value preservation.

---

**Round-1 [Should] disposition — gh648:63 named?**

[Pass] `relay-system/2026-11-16/gh1506-plan-claude.md` Producer block confirmed commit `2b8edfab`. The amended blast-radius at `GH-1506-TIMEOUT-DIAGNOSTIC-OVERCLAIMS.md:178` now reads: "Update the known detail-key assertion in test/gh648-l1-turn-termination.sh:63 and existing GH114/GH370 output expectations." `test/gh648-l1-turn-termination.sh:63` is explicitly named. Resolved.

**REASON_SLOW_PROGRESS value preserved?**

[Pass] `turn_diagnostics.py:93` — `REASON_SLOW_PROGRESS = "timeout-slow-but-progressing"`. Plan step 2 says to preserve both symbol and existing value. `test/gh390-timeout-attribution.sh:148` and `test/gh492-idle-kill.sh:101` import and compare against the symbol; they are safe. `test/gh492-idle-kill.sh:6` has `worktree-progress=no` only in a comment, not an assertion.

**relay_drive.py GH370 output consumer — blast-radius adequate?**

[Pass] `test/gh370-progress-telemetry.sh:43` — `grep -Fq 'GH-370 progress (main tree fallback:'` — a literal match that will break when relay_drive.py:967 message changes. The plan's blast-radius (`GH-1506-TIMEOUT-DIAGNOSTIC-OVERCLAIMS.md:178`) names "existing GH114/GH370 output expectations" for update. The test at `test/gh370-progress-telemetry.sh:49-51` checks for `'GH-370'` in driver source (`relay_drive.py:889` comment); that survives a message-only change. Acknowledged at plan level; no unnamed consumer found. Probe: `rg -n 'GH-370' utils/py/relay_drive.py` → hits only lines 889 (comment) and 967 (output); rc=0.

**No new consumers or pre-existing defects found in scoped probes.**

---

VERDICT: PASS

Basis: The round-1 [Should] is resolved — `test/gh648-l1-turn-termination.sh:63` is explicitly named in the blast-radius. REASON_SLOW_PROGRESS symbol and value are preserved; symbol-importing tests are safe. The relay_drive.py label change's downstream literal-string consumer (`test/gh370-progress-telemetry.sh:43`) is covered by the plan's "existing GH114/GH370 output expectations" acknowledgment. No blocker found. Plan is feasible and approved.

Relay closed (Approved) — no further reviewer turn needed. Parent resumes implementation.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
