# RELAY · GH-1126 plan QA: idle-kill label race between sampler and classify()
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
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
6. **Commit only the relay file** (`relay(gh1126-idle-race-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1126-IDLE-LABEL-PROBE-RACE.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1126-IDLE-LABEL-PROBE-RACE.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 — Producer (claude-a) → Reviewer (codex)

**Plan QA request.** Read the canonical `PROJECT/2-WORKING/GH-1126-IDLE-LABEL-PROBE-RACE.md` (it is also seeded under `.relay-artifacts/`). Then read `utils/py/turn_diagnostics.py` (whole file), `utils/py/consult.py:270-330,780-810`, `test/gh610-claude-subscription.sh:119-149`, and issue #1126's acceptance criteria as summarized in the plan.

**Operational envelope:**
- Single-maintainer repo.
- #1126 constraints: do not weaken the classifier; do not delete, skip or quarantine the suite; no new test case without operator approval (GH-831).

**Questions (cite file:line):**
1. **Root cause.** Does the failing transcript (`samples=3, cpu=0.00s/s, worktree-progress=no`, network observation None) *require* that the sample-3 probe had not completed when `classify()` ran? Is there another path to that exact detail string, such as `_loop` swallowing an exception, or `cpu_ratio()` differing between the probe check and `classify()`? Separate confirmed from hypothesis.
2. **Lock design.** `_sample()` holds `_sample_lock` for its whole body, and `classify()` acquires it. Check three things:
   - Any deadlock: does `classify()` call anything that re-enters `_sample`?
   - Readers other than `classify()` that would need it: `idle_seconds()`, `cpu_ratio()`, `termination_record()`, or a direct `samples` read in consult or the shims.
   - Test seams that call `_sample()` directly from a test thread, e.g. `test/gh648-l1-turn-termination.sh:150-175`.
3. **Turn shims.** `stop()` joins with `timeout=2.0` (`:437-441`), but `lsof` can take up to 5 s. Can a shim's post-`stop()` `classify()` currently race a still-running probe too? Does the lock fix that as well?
4. **Verification.** Is the planned manual race control (a slow stubbed `_network_state`, `classify()` mid-sample; red on base, green on fix) sufficient and non-vacuous? Are the listed existing suites the right covering set?
5. Anything in the plan that is an unproven generalization or a missing requirement from #1126.

End with VERDICT and a `swept file: yes|no` line.

### Reviewer · Round 1

**Block — plan corrections required; the proposed two-site lock remains a reasonable implementation.**

swept file: yes

Reviewed the entire seeded plan and all of `utils/py/turn_diagnostics.py`, plus the requested consult/test ranges and relevant caller sites. Setup's Definition of Done is still a placeholder; this review uses the plan's Acceptance section and the Producer's stated #1126 constraints. Graph tools (including project/generation and coverage queries) are unavailable in this turn; evidence is direct source reading and bounded string searches, not a graph-completeness claim. No artifact/source edits or git commands; no suites executed.

- **[Should] R1 — separate reproduced race from hosted-cause hypothesis.** Plan :39-43 treats the signature as proof of timing and says runner load explains why only hosted failed. The same signature occurs after a sampling exception, with no probe in flight. Source: `turn_diagnostics.py:393-395,425-428,536-541`. Correct the plan to say the race is reproduced, hosted attribution is plausible but unproven, and exceptions can leave the observation absent even after this lock change. Do not broaden the fix to mask missing evidence. CPU ratio is a pure computation over samples (:443-467); with three fixed samples it does not independently change between probe eligibility and classification.
  - Observed input: idle CPU/mtime seams, two completed samples, then a third sample whose dialog seam sets the stop event and raises; `_loop()` catches it. Output is the exact reported signature with `attempted=False`. Compare the held network seam's identical signature with `attempted=True`.
  - Affected scope: causal explanation and acceptance claims for missing cached observations, not classifier behavior.
  - Falsifier: demonstrate that the completed exceptional third sample cannot produce that detail on the reviewed module; expected result of the supplied probe is that it can.
  - Probe command (exit **0**, real imported module; all probes stubbed, no external processes):
    ```bash
    export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
    mkdir -p "$TMPDIR"
    python3 - <<'PY'
    import sys, threading
    sys.path.insert(0, 'utils/py')
    import turn_diagnostics as td
    td._descendant_cpu_seconds = lambda pid: (0.0, 1)
    td._security_dialog_present = lambda: False
    td._newest_mtime = lambda root: 0.0
    entered, release = threading.Event(), threading.Event()
    def network(pid):
        entered.set()
        assert release.wait(3), 'probe release timeout'
        return 'none'
    td._network_state = network
    d = td.TurnDiagnostics(worktree='unused')
    d._sample(); d._sample()
    t = threading.Thread(target=d._sample)
    t.start()
    assert entered.wait(3), 'probe never entered'
    try:
        print('inflight:', d.classify(), 'attempted=', d._network_probe_attempted, 'alive=', t.is_alive())
    finally:
        release.set(); t.join(3)
    assert not t.is_alive()
    print('completed:', d.classify()[0])
    d = td.TurnDiagnostics(worktree='unused')
    d._sample(); d._sample()
    def fail_dialog():
        d._stop.set()
        raise RuntimeError('controlled pre-probe exception')
    td._security_dialog_present = fail_dialog
    d._loop()
    print('exception:', d.classify(), 'attempted=', d._network_probe_attempted, 'stop=', d._stop.is_set())
    PY
    ```
    Decisive output:
    ```text
    inflight: ('timeout-unclassified', 'live sampling never established a safe idle window for the network probe [cpu=0.00s/s, samples=3, worktree-progress=no]') attempted= True alive= True
    completed: timeout-idle-unknown
    exception: ('timeout-unclassified', 'live sampling never established a safe idle window for the network probe [cpu=0.00s/s, samples=3, worktree-progress=no]') attempted= False stop= True
    ```

- **[Should] R2 — correct caller scope and delay contract before implementation.** Plan :44 is factually wrong for `review_xyz.py:429,441`: it classifies **before** stop, and before killing the process group (:433). Other listed shims do classify after stop (e.g. `codex-turn.py:118,128`), but `turn_diagnostics.py:440-441` joins for only 2 seconds; a still-running sample can race them too. The same lock addresses their classification reads without shim edits. Include `muse-turn.py:300,312`, whose emitted termination record also reaches classify. Plan :88's “up to about 5 s” worst case is not a bound for a whole-sample lock: `_network_state` includes a separate ps probe (:148; :122), dialog checks include pgrep/osascript for two names (:69,270-280), and directory mtime traversal has an entry bound rather than a wall-time bound (:288-327). In consult and review_xyz, classification occurs **before** termination, so this delays killing the live advisor, not merely reporting an already-ended turn. State that tradeoff explicitly and remove the false five-second ceiling; no probe redesign requested.
  - Observed input: `review_xyz.py:429` invokes classify inside the TimeoutExpired handler while the sampler and advisor can still be live; `stop()` uses `join(timeout=2.0)`.
  - Affected scope: the plan's reader inventory, affected-callers explanation, and accepted latency risk.
  - Falsifier: source showing review_xyz stops before classifying, or stop waits until sampling actually ends; current cited source shows neither.

- **[Should] R3 — make the planned race control deterministic and attributable.** Plan :62-67 uses fixed 0.2/1.5-second sleeps to establish overlap. A delayed sampler can miss that window; elapsed wait is then a scheduling assertion rather than proof of atomic classification. Use events to assert probe entry, call classify on a separate thread while the probe is held, and assert classify cannot finish until release on the candidate; bound all event waits/joins and assert thread completion. On base, assert classify finishes while the probe is still held with the quoted unclassified detail; on candidate, assert the returned idle label after release. Keep the no-sample-in-flight case. This stays a recorded manual control, not a new suite/case. Include the existing required committed `provenance.jsonl` alongside the script/log evidence (plan :61 currently lists only script/log), and explicitly place all suite/gate execution in a separate disposable **full clone**.
  - Observed input: the literal “Call classify() 0.2 s into the third sample” in plan :65 provides no probe-entry/completion synchronization; the R1 event-held probe establishes actual overlap.
  - Affected scope: the manual evidence procedure, preserving the exact current race and no-new-tests constraint.
  - Falsifier: a scheduler delaying the sampler beyond 0.2 s must still produce a valid overlap measurement rather than a false result; event entry/hold assertions satisfy that requirement.

- **[Pass] Lock call graph and seams.** `classify()` (:490-551) calls `cpu_ratio()`, not `_sample()`; termination wrappers (:553-578) call classify before packaging/emitting, with no outer acquisition. A plain Lock around only _sample/classify has no shown recursive acquisition. Keep `cpu_ratio()` unlocked internally because _sample already calls it (:416-417); blindly locking that helper with the same non-reentrant lock would deadlock. The direct sequential seam in `test/gh648-l1-turn-termination.sh:151,162` remains callable. No additional lock is necessary merely to make termination_record use the protected classifier.

- **[Pass] Scope restraint and covering intent.** The plan explicitly preserves classifier labels/thresholds, gh610's assertion and all test files (:51-52,73-77); `test/gh610-claude-subscription.sh:143-144` requires idle-unknown. The listed label/idle suites cover relevant behavior by source inspection. `gh648-l4-285-revalidate.sh:40,109` substitutes diagnostics, so it checks adapter reporting, not real sampler synchronization; the manual control supplies that gap.

- **[Nit] Atomicity wording.** Plan :49's “atomic with respect to readers” should say “with respect to classify.” `idle_seconds()` (:486-488) and direct samples/cpu_ratio reads remain unlocked. The pre-existing interval after sample append but before _last_progress_t update (:393-412) remains visible to idle_seconds; this change does not establish an atomic idle-kill decision. Keep this as an explicit limitation, without expanding #1126 into an idle-policy redesign.

- **[Unverified — needs clone run]** Candidate locking behavior, all listed suite results, final-commit gate, and hosted-run cause are not established here. No further pre-existing defect requiring expansion of this classifier-label fix was found in the full-file sweep; the existing partial idle-read limitation is recorded above.

**VERDICT: FAIL**

**Basis:** The race itself is reproduced and the proposed lock has a viable call graph, but the current plan overstates causal certainty and the delay bound, misstates a live caller, and needs a synchronized manual verification contract. Correct R1–R3, retain classifier semantics and the narrow source scope, then return for plan approval.

Handing off to Producer (claude-a) — disposition R1–R3, revise the plan, and return for Round 2.

### Round 2 — Producer (claude-a) → Reviewer (codex)

Dispositions (canonical plan revised; re-seeded):
- **R1 — Implemented.** Root cause is split into *reproduced* (the in-flight race, using your probe's exact signature) and *plausible but unproven* (hosted attribution). The exception-before-probe path is named as yielding the same signature. The fix does not cover it, and its `timeout-unclassified` label is honest.
- **R2 — Implemented.** The caller inventory is corrected:
  - consult and `review_xyz.py:429` classify before `stop()`.
  - The shims, including `muse-turn.py:312`, classify after a `stop()` that joins for only 2 s, so they can race too.
  - The lock covers all of them with no caller edits.
  - The "5 s" bound is replaced by "one sample's duration", with every component named. `_newest_mtime` is bounded by entry count, not wall time.
- **R3 — Implemented.** The manual control is event-synchronized: probe `entered`/`release`, `classify()` on its own thread, and bounded joins with no sleeps. It runs against base (red: finishes during the held probe with the quoted detail) and candidate (blocked until release, then `idle-unknown`). It also covers the no-in-flight case and records the exception-path limitation. `provenance.jsonl` is added.
- **Nit — Implemented.** Atomicity is now stated "with respect to `classify()`". `cpu_ratio()` stays lock-free (reentrancy). The append/`_last_progress_t` gap is named as a limitation.

Request: confirm R1–R3 closed, or name the gap with Observed input / Affected scope / Falsifier. VERDICT + `swept file:` line.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
