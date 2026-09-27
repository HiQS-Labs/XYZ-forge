# RELAY · PR #869 review — GH-793 into staging/stabilize-2026-10 (#854 window)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-27.
-->

NEXT: Producer
STATUS: Escalated
ROUND: 1 / 1

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
6. **Commit only the relay file** (`relay(pr-869-review-gh-793-into-staging-stabilize-2026-10-854-window): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the diff from origin/staging/stabilize-2026-10 to HEAD on this branch (PR #869, GH-793). Key files: `test/gh492-idle-kill.sh`, `utils/py/turn_diagnostics.py`, `CHANGELOG.md`, `TESTS-RESULTS/2026-09-27+GH-793/SUMMARY.md`, `TESTS-RESULTS/2026-09-27+GH-793/slow-tools-repro.sh.txt`. Read in place; do NOT edit.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-27
- Definition of Done: see *Review packet*. One round (operator: minimum ceremony). PASS means safe to squash-merge into the staging branch.

## Review packet

**The question:** is PR #869 (GH-793) correct, and safe to squash-merge into `staging/stabilize-2026-10`? Read issue GH-793's intent from `TESTS-RESULTS/*+GH-793/SUMMARY.md`. You cannot run git, so the PR's exact scope and code patch are embedded below; they were taken at the PR head before this thread was added.

**Scope** (`git diff --name-status origin/staging/stabilize-2026-10...HEAD`):
```
M	CHANGELOG.md
A	TESTS-RESULTS/2026-09-27+GH-793/SUMMARY.md
A	TESTS-RESULTS/2026-09-27+GH-793/base-load-1.log
A	TESTS-RESULTS/2026-09-27+GH-793/base-load-2.log
A	TESTS-RESULTS/2026-09-27+GH-793/base-load-3.log
A	TESTS-RESULTS/2026-09-27+GH-793/base-load-4.log
A	TESTS-RESULTS/2026-09-27+GH-793/base-load-5.log
A	TESTS-RESULTS/2026-09-27+GH-793/base-slow-0.5-1.log
A	TESTS-RESULTS/2026-09-27+GH-793/base-slow-1-3.log
A	TESTS-RESULTS/2026-09-27+GH-793/base-slow-1.5-6.log
A	TESTS-RESULTS/2026-09-27+GH-793/cpu-load-attempt.sh.txt
A	TESTS-RESULTS/2026-09-27+GH-793/head-normal-1.log
A	TESTS-RESULTS/2026-09-27+GH-793/head-normal-2.log
A	TESTS-RESULTS/2026-09-27+GH-793/head-normal-3.log
A	TESTS-RESULTS/2026-09-27+GH-793/head-normal-4.log
A	TESTS-RESULTS/2026-09-27+GH-793/head-normal-5.log
A	TESTS-RESULTS/2026-09-27+GH-793/head-slow-0.5-1.log
A	TESTS-RESULTS/2026-09-27+GH-793/head-slow-1-3.log
A	TESTS-RESULTS/2026-09-27+GH-793/head-slow-1.5-6.log
A	TESTS-RESULTS/2026-09-27+GH-793/head-teeth-progress.log
A	TESTS-RESULTS/2026-09-27+GH-793/head-teeth-scope.log
A	TESTS-RESULTS/2026-09-27+GH-793/head-teeth.log
A	TESTS-RESULTS/2026-09-27+GH-793/provenance.jsonl
A	TESTS-RESULTS/2026-09-27+GH-793/route.txt
A	TESTS-RESULTS/2026-09-27+GH-793/slow-tools-repro.sh.txt
M	test/gh492-idle-kill.sh
```

**Code patch** (everything except `TESTS-RESULTS/` and `relay-system/`):
```diff
diff --git a/CHANGELOG.md b/CHANGELOG.md
index 762405c3..32c1049d 100644
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -1,5 +1,9 @@
 # Changelog
 
+## 2026-09-27 — gh492's idle checks no longer depend on how fast `ps` answers (GH-793)
+
+`test/gh492-idle-kill.sh` failed only under the parallel gate. Its sampler shells out to `ps`, `pgrep` and `lsof`, which slow down under gate load. The test's fixed 4 s window, a fixed 1.0 s bound, and an idle reading taken after the sampler threads were joined made that slowdown read as "a progressing turn looks idle" and "the blocked turn is unclassified". Delaying just those tools reproduces both at base. The windows now run until enough samples exist (capped at 30 s), idle is read when the window closes, and the two "not idle" bounds are `max(1.0 s, 2 × the largest observed sample gap)`. The product code is unchanged, and mutations that break file-progress or pid scoping still fail the suite. Evidence is in `TESTS-RESULTS/2026-09-27+GH-793/`.
+
 ## 2026-09-27 — rollback events no longer poison `.tick/events`, and tests keep them out of the real clone (GH-745)
 
 `wave_reconcile`'s rollback event was appended to a timestamp-named file. Two rollbacks in the same instant wrote two records into one file, and `tick claims` then failed `events-unreadable` for the whole clone, which made merge-cleanup preserve it forever. Each event is now its own file: the name carries the pid and 8 random hex characters, and the file is created exclusively. Three suites (`gh424`, `gh425`, `gh421`) built the journal with no root and wrote events into the real clone. They now use their fixture root.
diff --git a/test/gh492-idle-kill.sh b/test/gh492-idle-kill.sh
index 36ec37e1..19257764 100644
--- a/test/gh492-idle-kill.sh
+++ b/test/gh492-idle-kill.sh
@@ -61,29 +61,39 @@ open(os.path.join(wt_b, "seed.txt"), "w").write("seed\n")
 diag_b = TurnDiagnostics(worktree=wt_b, interval=INTERVAL)
 diag_b.start()
 
-deadline = time.monotonic() + 4.0
+# GH-793: the window is measured in SAMPLES as well as seconds. Each sample runs `ps`/`pgrep`
+# (and one `lsof` probe), which slow down under a loaded parallel gate. A fixed 4 s window then
+# held too few samples for a verdict. It still lasts at least 4 s, so a fast host runs as before.
+start = time.monotonic()
+deadline = start + 4.0
+need = IDLE_MIN_SAMPLES + 1
 n = 0
-while time.monotonic() < deadline:
+while (time.monotonic() < deadline
+       or len(diag_a.samples) < need or len(diag_b.samples) < need) and time.monotonic() < start + 30.0:
     n += 1
     # touch a NEW file so _newest_mtime advances
     with open(os.path.join(wt_b, f"progress-{n}.txt"), "w") as f:
         f.write(str(n))
     time.sleep(INTERVAL)
 
+# GH-793: read idle as the window closes. stop() joins each sampler for up to 2 s, and the kill
+# waits too; measured after them, that time counted as "idle" for a turn that was progressing.
+idle_a = diag_a.idle_seconds()
+idle_b = diag_b.idle_seconds()
+gaps_b = [b[0] - a[0] for a, b in zip(diag_b.samples, diag_b.samples[1:])]
 diag_a.stop(); diag_b.stop()
 try:
     proc_a.kill(); proc_a.wait(timeout=5)
 except Exception:
     pass
 
-idle_a = diag_a.idle_seconds()
-idle_b = diag_b.idle_seconds()
 reason_a, _ = diag_a.classify()
 reason_b, _ = diag_b.classify()
 print(f"SAMPLES_A={len(diag_a.samples)}")
 print(f"SAMPLES_B={len(diag_b.samples)}")
 print(f"IDLE_A={idle_a}")
 print(f"IDLE_B={idle_b}")
+print(f"GAP_B={max(gaps_b) if gaps_b else 0.0}")
 print(f"REASON_A={reason_a}")
 print(f"REASON_B={reason_b}")
 print(f"MIN_SAMPLES={IDLE_MIN_SAMPLES}")
@@ -111,9 +121,14 @@ awk -v v="$IDLE_A" 'BEGIN{exit !(v+0 >= 1.0)}' 2>/dev/null \
   && pass "a blocked turn accumulates idle time (idle=${IDLE_A}s) — killable before the wall cap" \
   || fail "a blocked turn reported idle=${IDLE_A} — the idle bound would never fire"
 
-# (3) THE CONTROL — a slow-but-progressing tree must stay near zero idle, so it is NOT killed
-awk -v v="$IDLE_B" 'BEGIN{exit !(v+0 <= 1.0)}' 2>/dev/null \
-  && pass "CONTROL: a slow-but-progressing turn stays un-idle (idle=${IDLE_B}s) — not killed" \
+# (3) THE CONTROL — a slow-but-progressing tree must stay near zero idle, so it is NOT killed.
+# GH-793: "near zero" is what the sampler can resolve. Progress is only seen at a sample, so a
+# progressing turn's idle can reach one sample gap. The bound is 1.0 s or twice the largest gap B
+# actually took, whichever is larger. On a fast host that is still 1.0 s.
+GAP_B="$(get GAP_B)"
+CTRL_MAX="$(awk -v g="$GAP_B" 'BEGIN{m=2*g; if (m < 1.0) m = 1.0; printf "%.3f", m}')"
+awk -v v="$IDLE_B" -v m="$CTRL_MAX" 'BEGIN{exit !(v+0 <= m+0)}' 2>/dev/null \
+  && pass "CONTROL: a slow-but-progressing turn stays un-idle (idle=${IDLE_B}s <= ${CTRL_MAX}s; largest sample gap ${GAP_B}s) — not killed" \
   || fail "CONTROL FAILED: a progressing turn reported idle=${IDLE_B}s — this bound is trigger-happy and would kill good reviews"
 
 # (4) the two must be SEPARATED, not merely both present. A bound cannot act on a difference it
@@ -165,7 +180,7 @@ grep -q "_idle is not None and _idle >= idle_cap" "$PY_DIR/agy-turn.py" \
 SCOPE_OUT="$WORK/scope.txt"
 PYTHONPATH="$PY_DIR" python3 - "$WORK" > "$SCOPE_OUT" 2>&1 <<'PYEOF'
 import os, sys, time, subprocess
-from turn_diagnostics import TurnDiagnostics
+from turn_diagnostics import TurnDiagnostics, IDLE_MIN_SAMPLES
 
 work = sys.argv[1]
 INTERVAL = 0.2
@@ -183,7 +198,15 @@ scoped = TurnDiagnostics(worktree=out_a, root_pid=proc_a.pid, interval=INTERVAL)
 # deliberately WRONG scoping: the shared parent, which is what the pre-GH-492 class could only do
 unscoped = TurnDiagnostics(worktree=out_a, interval=INTERVAL)
 scoped.start(); unscoped.start()
-time.sleep(3.0)
+# GH-793: at least 3 s AND enough samples for idle_seconds() to answer (capped at 30 s). Under a
+# loaded gate each sample's ps/pgrep can take a second or more, so a bare 3 s held too few.
+t0 = time.monotonic()
+while (time.monotonic() - t0 < 3.0
+       or min(len(scoped.samples), len(unscoped.samples)) < IDLE_MIN_SAMPLES + 1) \
+        and time.monotonic() - t0 < 30.0:
+    time.sleep(INTERVAL)
+scoped_idle, unscoped_idle = scoped.idle_seconds(), unscoped.idle_seconds()
+gaps_u = [b[0] - a[0] for a, b in zip(unscoped.samples, unscoped.samples[1:])]
 scoped.stop(); unscoped.stop()
 
 for p in (proc_a, proc_b):
@@ -192,8 +215,9 @@ for p in (proc_a, proc_b):
     except Exception:
         pass
 
-print(f"SCOPED_IDLE={scoped.idle_seconds()}")
-print(f"UNSCOPED_IDLE={unscoped.idle_seconds()}")
+print(f"SCOPED_IDLE={scoped_idle}")
+print(f"UNSCOPED_IDLE={unscoped_idle}")
+print(f"UNSCOPED_GAP={max(gaps_u) if gaps_u else 0.0}")
 PYEOF
 
 if grep -q "^SCOPED_IDLE=" "$SCOPE_OUT"; then
@@ -202,8 +226,11 @@ if grep -q "^SCOPED_IDLE=" "$SCOPE_OUT"; then
   awk -v v="$S_IDLE" 'BEGIN{exit !(v+0 >= 1.0)}' 2>/dev/null \
     && pass "CONSULT: a hung advisor is seen as idle when scoped to its own pid (idle=${S_IDLE}s)" \
     || fail "CONSULT: a hung advisor reported idle=${S_IDLE}s even when correctly scoped"
-  awk -v v="$U_IDLE" 'BEGIN{exit !(v+0 < 1.0)}' 2>/dev/null \
-    && pass "CONSULT: the SHARED-parent scope masks that same hang (idle=${U_IDLE}s) — which is why root_pid exists" \
+  # GH-793: the busy sibling is only seen at a sample, so "not idle" is resolved to one sample gap.
+  U_GAP="$(grep '^UNSCOPED_GAP=' "$SCOPE_OUT" | cut -d= -f2)"
+  U_MAX="$(awk -v g="$U_GAP" 'BEGIN{m=2*g; if (m < 1.0) m = 1.0; printf "%.3f", m}')"
+  awk -v v="$U_IDLE" -v m="$U_MAX" 'BEGIN{exit !(v+0 < m+0)}' 2>/dev/null \
+    && pass "CONSULT: the SHARED-parent scope masks that same hang (idle=${U_IDLE}s < ${U_MAX}s) — which is why root_pid exists" \
     || fail "CONSULT: the shared-parent scope reported idle=${U_IDLE}s, so this case proves nothing about scoping"
 else
   fail "consult scoping harness did not run: $(cat "$SCOPE_OUT")"
```

**Definition of Done (PASS when all hold):**
- (a) **The fix addresses the stated root cause** at the cited lines. It is minimal: no unrelated edits, and no weakened or deleted assertion that hides a failure.
- (b) **The evidence is real.** A red control at base fails for the stated reason, and the edited suite is green 5 of 5 at head. The logs in `TESTS-RESULTS/*+GH-793/` exist, are non-empty, and match `provenance.jsonl`.
- (c) **#854 per-PR rule.** No `releases.db`, `releases.sql` or `LEADERBOARD.md` change, no `PROJECT/` change, no new test file, and no new registry entry in `validate.sh` (AGENTS.md *No new tests*). Scope is CI or core-harness files only.
- (d) **The CHANGELOG entry is truthful.**

**Operating envelope.** A single-operator developer tool. Grade against these checks and commensurate complexity. Do not ask for new tests, new infrastructure or multi-tenant threat models.

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
Basis: The timing repair and recorded red/green evidence are sound, but the edited negative controls still accept an unmeasured reading as proof of progress. Resolve the narrow existing-suite assertion defect below before approval. One-round limit reached.

swept file: yes
Swept the entire `test/gh492-idle-kill.sh` and `utils/py/turn_diagnostics.py`, including pre-existing code, plus the evidence scripts and summary. Reviewed the GH-793 CHANGELOG entry; unrelated historical changelog entries were not re-audited. The pre-existing assertion defect found by this sweep is listed below; no other demonstrated runtime defect was established.

- [Should] Reject unmeasured values before the two numeric negative-control comparisons (`test/gh492-idle-kill.sh:130`, `test/gh492-idle-kill.sh:232`). AWK converts `None` to zero, so an absent measurement earns a PASS claiming that progress/scoping was observed. The 30-second cap still permits insufficient samples; the consult section has no separate minimum-sample assertion for its unscoped sampler. Fix within this existing suite: require a present numeric idle reading before either upper-bound comparison, retaining the new timing bounds and the fresh-sampler None check. No new suite or product change is needed.
  Observed input: `TESTS-RESULTS/2026-09-27+GH-793/base-slow-1-3.log:5` and `:13` explicitly print `PASS ... idle=Nones`; `base-slow-1.5-6.log:5` and `:13` repeat it. These base runs fail overall for other reasons; this finding concerns the false individual assertions, not a claim that those runs were green.
  Affected scope: `IDLE_B` and `U_IDLE` values passed through `v+0` in the two edited upper-bound checks; invalid or absent values must fail the measurement check rather than establish progress.
  Falsifier: replay the recorded `None` through the current comparison: it should exit nonzero. Read-only probe `awk -v v="None" -v m="1.000" 'BEGIN{print "UNSCOPED_IDLE=None -> numeric=" v+0 "; assertion passes=" (v+0 < m+0); exit !(v+0 < m+0)}'` exited **0**, output `UNSCOPED_IDLE=None -> numeric=0; assertion passes=1`. After correction, this input should fail while the recorded finite head readings still pass. Full-suite replay remains for a disposable clone.
- [Pass] The sample-count windows and earlier idle reads address the reproduced timing mechanism (`test/gh492-idle-kill.sh:69`, `:81`, `:204`, `:208`). Separation and attribution remain asserted (`:136`, `:141`, `:144`). Retain these changes. The supplied mutation logs show the file-progress mutation fails both the control and separation (`head-teeth-progress.log:5`, `:6`) and ignored PID scoping fails the hung-advisor check (`head-teeth-scope.log:12`), under `TESTS-RESULTS/2026-09-27+GH-793/`.
- [Pass] Recorded evidence agrees with the summary: `head-normal-1.log` through `head-normal-5.log` each end `gh492-idle-kill: 16 pass, 0 fail`; the moderate delayed-tool base/head pairs are red/green. A read-only Python JSON/log probe (parse each `provenance.jsonl` row, expand `base-load-1..5.log`, assert nonempty text and match the final fail count to `rc`) exited **0**: `14 receipts; 18 nonempty referenced logs; all rc/verdict pairs agree`. The extreme-delay head failure is retained and disclosed (`SUMMARY.md`, “Limit”; `head-slow-1.5-6.log:8`). Retain that disclosure.
- [Pass] The supplied scope contains the existing suite, CHANGELOG and evidence only; it lists no ledger, PROJECT, registry or new executable test addition (Review packet, “Scope”). The GH-793 entry at `CHANGELOG.md:3` accurately describes the implemented windows, bounds and recorded mutations. No expansion of scope requested.
- [Unverified — needs clone run] No suite, fixture, pytest, or Git command was executed in this turn. The retained receipts concern the pre-rebase fix described in `SUMMARY.md`; a final-state gate is still the harness/window landing obligation. This review does not independently attest the original parallel-gate failure mechanism beyond the supplied delayed-tool reproduction.

Handing off to Producer (claude-a) — address the single assertion finding in the producer window; this relay is Escalated at its one-round cap.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
