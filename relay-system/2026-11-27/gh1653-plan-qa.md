# RELAY · GH-1653 plan QA - jog books receipt-publication attempt
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-27.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

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
     change MUST carry `Observed input:`, `Affected scope:` (the input predicate the change would govern),
     and `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected
     result). `Observed input:` accepts two strict, non-speculative forms:
     (1) **Form 1 (observed failure or artifact contradiction):** a failing probe/gate output, or a concrete
     `fileA:line` vs `fileB:line` contradiction (e.g. IAM SA mismatch, inverted test, sibling guard omission);
     (2) **Form 2 (unrunnable runtime hazard trace):** permitted ONLY when reproduction requires an external
     service, multi-process concurrency, or a browser/container runtime forbidden in the relay worktree —
     must supply a hop-by-hop `file:line` trace plus an exact `Clone probe:` command/script for the Producer's
     disposable full clone. Default severity for an unexecuted Form 2 hazard is `[Should]`.
     A `[Blocker]` must cite an observed failure (Form 1); an unexecuted Form 2 hazard stays `[Should]`
     until a probe reproduces it, and remains pending probe verification until the Producer runs
     `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, read the probe before running it — refuse any probe that reaches
     the network, credentials, or paths outside the disposable clone and record the refusal as
     `[Unverified — clone probe failed/unavailable]` — then execute safe probes in a disposable full clone and
     record one of three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output;
     (b) Falsified → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored, refused, or
     environment unavailable → keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking
     `STATUS: Approved` until re-run cleanly or escalated/parked). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1653-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1653-JOG-RECEIPT-ATTEMPT.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1653-JOG-RECEIPT-ATTEMPT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-27
- Definition of Done: the plan's "Requirements" 1-4 (issue #1653 + ledger #1657) are each met by the plan, each with a falsifiable check that rejects the unchanged base.

### Review packet (plan QA, round 1)

**Paraphrase first (GH-1414).** Before reading anything except the plan, write 2-5 sentences each under **What this proposes** and **How the existing system works, per this document**, plus a short **What it's not**. Distinguish excluded work, deferred work and unresolved choices; label inference. Record this paraphrase as the first part of your review block, then continue with the source-backed assessment (label it "source-backed").

**Operational envelope.** Local developer/agent CLI (Jog queue supervisor, Python) in a single repo, publishing to the canonical GitHub remote through the repo's own pre-push gate. Grade against the stated requirements, commensurate complexity, and the repo's rules: AGENTS.md "No new tests" (GH-831: no new suites or `validate.sh` registry entries; a focused case added to an existing suite that already covers the path is allowed when nothing covers it), the #1399 attempt-accounting design (`utils/py/rtl.py`, `utils/py/gate_receipt.py`), never weakening the gate, never renaming a task to escape an exhausted budget. Do not ask for speculative machinery (new attempt kinds, locks, journals, schedulers).

**Read:** the plan (`.relay-artifacts/GH-1653-JOG-RECEIPT-ATTEMPT.md`), `utils/py/jog_run.py` (`publish_jog_receipt`, its three callers in the wake ≈L700-730, `jog_resume` ≈L775-830, gate-only retry ≈L1040-1070, `_git`), `utils/py/gate_receipt.py` (`attempt_admission`, `main()` attempt-start/attempt-finish), `utils/py/rtl.py` (`lane_attempt_reserve`, `lane_attempt_row`, `lane_attempt_finish`, `archive_lane_attempts`), `utils/py/relay_attest.py` (`candidate_ok`, `source_matches`), `githooks/install.sh` (`_attempt_guard`), `githooks/pre-push` L60-100, `utils/py/marathon_drive.py` `lane_attempt_gate`, `test/gh280-jog-marathon-adapter.sh` (fixture setup, `prepare_execution_target`, section G4, P2 near L1368).

**Questions (cite file:line):**
1. Is every claim in the plan's Recon table grounded in the actual paths? Is any entry wrong or missing — in particular, is it true that the Marathon lane's attested reservation cannot admit the receipt commit?
2. Will a reservation booked by `lane_attempt_reserve(kind="manual")` on the lane branch before the evidence commit be admitted by `attempt_admission` for the push of that commit (HEAD == sha, start_sha ancestor, branch match), from all three call sites including `jog resume` where the commit may already exist?
3. Retry/restart honesty: does the plan keep consumed attempts across a failed push, a crash between booking and finishing, and a new process (`jog resume`)? Can anything in it reset or rename the budget? Is the fixed key `GH-<n>-jog-publish` the right identity, and is drawing from `LANE_MAX_ATTEMPTS` (default 2) correct?
4. What prevents the unchanged base from being reported as fixed — is the G4 hook (real `gate_receipt.py admit` per pushed ref) a faithful stand-in for the installed gate's admission step, and does the red control on base `52813e56f` actually observe the Day 3 refusal? Is the negative control (plain unreserved push refused) meaningful?
5. Side effects: `rtl.lane_attempt_reserve` sets `os.environ[XYZ_ATTEMPT_CONTEXT]`; is the plan's restore sufficient so the next lane's Marathon dispatch or later Jog pushes do not inherit a stale context? Does Marathon's own push or `_require_gate_wired` interact badly?
6. Does extracting `manual_attempt_start/finish` out of `gate_receipt.main()` keep the CLI byte-for-byte compatible, and is that refactor justified versus Jog shelling out to the CLI?
7. Test honesty: does the G4 hook exercise the real seam (not mock it away)? Does the new booking conflict with gh280 P2 ("jog never ... writes executor attempt state")? Is any proposed assertion unnecessary?
8. Is anything over- or under-built? Flag missing requirements (e.g. should `run_record.py checkpoint --push` be in scope per #1653?) and justify.

Write your verdict below and change STATUS to Approved if it passes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Round 1 · Reviewer · codex

**What this proposes**

Jog would book a manual gate attempt under a stable per-issue publication key, push its receipt commit under that reservation, and finish the row using the existing accounting writer. Wake, resume, and a successful gate-only retry would share that behavior. The proposed fixture would exercise real admission on a local remote and witness both unreserved refusal and exhaustion across processes.

**How the existing system works, per this document**

Marathon books and attests a build reservation tied to reviewed source and permissible transcript changes. Jog then commits a separate receipt bundle, which changes content outside the attestation boundary, and pushes without a reservation of its own. The operator has been booking a manual reservation and resuming the existing commit to get it published.

**What it's not**

Excluded work includes altering the hook, adding a reservation store or kind, and changing the default cap. Checkpoint booking is deferred to its own caller. I infer that the exact recovery sequence for an interrupted finish and the point at which the fixture injects a failure are still open choices.

swept file: yes

**Source-backed**

**VERDICT: FAIL**

**Basis:** The admission design is sound on a normal call, but the plan leaves a completed-before-archive crash without a resume path and supplies no discriminating check for the gate-only caller. The fixture also needs to disambiguate the two pushes and prove that its transport rewrite preserves reservation identity. Full seeded plan and requested source seams reviewed. Graph discovery used the maintained XYZ-forge index (generation 2026-11-26T04:31:47Z), with current relay-worktree source as authority. Graph call tracing was unavailable and the partial gh280 range 729–730 was read locally. No phase gate was specified for this reviewer. Runtime results below remain [Unverified — needs clone run].

- **[Blocker] A completed row can strand resume before it reaches the existing recovery operation.**  
  Observed input: the plan books before the receipt commit and only finishes after the push (artifact L78–84). For a row whose completed write was installed at `utils/py/rtl.py:165–185` but whose archive rename at `utils/py/rtl.py:189–190,263–267` did not happen, the plan's next invocation goes straight to reserve. `rtl.py:89–95` explicitly refuses a new reservation and directs the caller back to attempt-finish. Yet `jog_run.py:815–827` only saves the published state after the helper returns and the proposed resume path never performs that finish. The current CLI already allows re-finishing the same completed candidate (`gate_receipt.py:353–366`, `rtl.py:160–164`).  
  Affected scope: an approved bundle already on the remote, a completed live publication row still awaiting archival, and an unset committed-receipt marker after a crash or archival error.  
  Falsifier: with exactly that state in the disposable fixture, a new `jog resume 901` archives the same row and projects the published receipt with no new reservation, even when the live count equals the cap. Spell out the same-candidate recovery using the existing finish operation and keep a post-push finish error distinct from a failed push. Also specify what happens if the push succeeded before any completed write and the live row is still active. Check the exact remote ref before treating publication as delivered.

- **[Blocker] Requirement 1 has no red control for the gate-only publication caller.**  
  Observed input: artifact L61 and L83 require all three call sites and explicitly passing the coordinator root. Its verification at L85–97 only gates G4 wake and the separate resume retry. Existing K2 (`test/gh280-jog-marathon-adapter.sh:874–887,931–945`) asserts the approved retry and no extra token, but installs no admission hook and never inspects the remote bundle or coordinator accounting. The gate-only caller at `utils/py/jog_run.py:1062–1066` could omit `accounting_root=root` and still meet every planned assertion.  
  Affected scope: a red contract gate that turns green on `jog retry-gate`, using the distinct coordinator/execution roots. A subsequent publication failure should continue through `jog resume` since `jog_run.py:958–964,1010–1016` intentionally rejects a Jog bundle as a gate-only relay tail.  
  Falsifier: extend the existing K2 check or record an equivalent manual control with real admission, the retry bundle on the bare remote, and the completed publication reservation under the coordinator. The fixture-only overlay on the unchanged base must refuse that push. Omitting the coordinator root on the candidate must fail the accounting assertion. Keep K2's no-builder/no-new-token checks.

- **[Should] Wire the G4 controls to the correct push and capture its refusal.**  
  Observed input: artifact L85–91 puts a per-ref admit hook and a fail sentinel on the whole G4 execution clone. G4 expects a redirected branch and PR 42 (`test/gh280-jog-marathon-adapter.sh:630–647`). The same clone first pushes via `utils/py/marathon_drive.py:2741–2756,2893` → `relay-automation/marathon-closeout.sh:189`; later Jog pushes via `utils/py/jog_run.py:1236–1238`. Marathon's closeout errors are best effort, while a Jog publication error parks the row (`marathon_drive.py:2760–2766`, `jog_run.py:719–727`). Thus a generic fail sentinel can also suppress the earlier push and invalidate the intended starting state for the retry. G4 captures output but its current row assertion prints only queue state, and an approved result alone doesn't witness the published bundle.  
  Affected scope: G4/G4-retry with a redirected branch and a failing receipt push; G4-neg after a successful publication, where pushing the same up-to-date ref may send no update lines.  
  Falsifier: use a receipt-specific sentinel after admission, observe the Marathon candidate already on the bare remote, and test a real new ref update with both attempt context variables unset for G4-neg. On an unchanged runtime at `52813e56f` with only the fixture overlay, retain the Jog-specific admission error, exit/status and unchanged bare remote ref. On the candidate, read the new ref and its bundle from the bare remote, and verify the row count remains two on the exhausted retry. Use a fresh fixture for the restart sequence or explicitly establish its starting ref and live count. The last cap-three case is optional as a fixture-only archive check. Mark Day 3 as field evidence at `3f2ffa353` per #1653 and the run on `52813e56f` as the planned replay.

- **[Should] Form 2 — check Git's inherited transport rewrite in the admission hook.**  
  Observed input: `test/gh280-jog-marathon-adapter.sh:83–102,159–164,550–553` preserves a synthetic GitHub origin during reservation but invokes the real push with a command-scoped `url.<bare>.insteadOf`. `rtl.py:35–56,100–105` hashes the effective URL at booking. The new hook calls `gate_receipt.py:140–144`, which hashes the origin again through a subprocess. If the push's command-scoped config reaches that subprocess, the fixture compares a GitHub-origin hash to a local-bare hash and refuses for a different reason.  
  Affected scope: only pushes using the gh280 transport shim and the proposed new hook.  
  Falsifier: the standalone observation prints identical configured URLs before and inside the hook; then run the G4 red control and check the exact admission error. If the URLs differ, isolate the test fixture's transport configuration from the hook's identity lookup or use a consistent local-remote identity. Leave production admission as written.  
  Clone probe: run this from a disposable full clone. It uses a local bare remote, makes no commits, and the hook intentionally refuses the update after printing its view of origin.

  ```bash
  mkdir -p "$PWD/temp"
  proof="$(mktemp -d "$PWD/temp/gh1653-origin.XXXXXX")" || exit 1
  git init -q --bare "$proof/remote.git" || exit 1
  git clone -q --no-local "$PWD" "$proof/source" || exit 1
  git -C "$proof/source" remote set-url origin https://github.com/example/example.git || exit 1
  mkdir -p "$proof/hooks"
  cat > "$proof/hooks/pre-push" <<'SH'
  #!/bin/sh
  printf 'hook origin: '
  git remote get-url origin
  exit 1
  SH
  chmod +x "$proof/hooks/pre-push"
  git -C "$proof/source" config core.hooksPath "$proof/hooks" || exit 1
  printf 'book origin: '
  git -C "$proof/source" remote get-url origin || exit 1
  git -C "$proof/source" -c "url.$proof/remote.git.insteadOf=https://github.com/example/example.git" \
      push origin HEAD:refs/heads/gh1653-local-probe
  printf 'push exit: %s\n' "$?"
  ```

- **[Should] Form 2 — two resumes can contend for the same publication attempt.**  
  Observed input: `utils/py/jog_run.py:787–819` reads old state and enters publication without the existing supervisor lock used by run/retry (`jog_run.py:868–876,1089–1095`). The proposed booking at artifact L78–84 appends a second active row under `rtl.py:82–111` while the first can still be in the pre-push hook. `rtl.py:133–135` then refuses the superseded first row, including when called by admission at `gate_receipt.py:137` or by finish at L357.  
  Affected scope: overlapping publishers for the same issue and coordinator while the unrecorded receipt is still pending.  
  Falsifier: while the first process holds a pending publication, the second consumes zero rows. Reuse the existing supervisor lock for the mutating resume path if reproduced, within the repo's one-owner rule.  
  Clone probe: in the disposable clone, temporarily insert the following fragment in the planned G4-retry fixture after its first failed push, before another retry, with that fixture's receipt-only fail sentinel still enabled. It parks process A immediately after the real reservation and launches B. The cap of three is local to this probe to leave two slots after the seeded failure. The expected signal is one additional row total (safe) versus two (race); report both exits and outputs. Remove this temporary fragment after the manual probe.

  ```bash
  attempt="$FR/.tick/attempts/GH-901-jog-publish"
  test "$(wc -l < "$attempt" | tr -d ' ')" = 1 || exit 1
  LANE_MAX_ATTEMPTS=3 PYTHONPATH="$FR/utils/py" python3 - "$FR" "$WORK/gh1653-reserved" \
      >"$WORK/gh1653-a.log" 2>&1 <<'PYPROBE' &
  import pathlib, runpy, sys, time
  import gate_receipt
  root, marker = sys.argv[1:]
  ready = pathlib.Path(marker)
  start = gate_receipt.manual_attempt_start
  def hold_after_reserve(*args, **kwargs):
      result = start(*args, **kwargs)
      if result[1] is not None:
          ready.touch()
          for _ in range(300):
              if ready.with_suffix(".continue").exists():
                  return result
              time.sleep(0.1)
          raise RuntimeError("publication probe timed out waiting for second resume")
      return result
  gate_receipt.manual_attempt_start = hold_after_reserve
  app = root + "/utils/py/releases_app.py"
  sys.argv = [app, "--root", root, "jog", "resume", "901"]
  runpy.run_path(app, run_name="__main__")
  PYPROBE
  first=$!
  for _ in $(seq 1 150); do
    test ! -f "$WORK/gh1653-reserved" || break
    sleep 0.1
  done
  if ! test -f "$WORK/gh1653-reserved"; then
    wait "$first"
    cat "$WORK/gh1653-a.log"
    exit 1
  fi
  b_rc=0
  LANE_MAX_ATTEMPTS=3 python3 "$FR/utils/py/releases_app.py" --root "$FR" jog resume 901 \
    >"$WORK/gh1653-b.log" 2>&1 || b_rc=$?
  touch "$WORK/gh1653-reserved.continue"
  a_rc=0
  wait "$first" || a_rc=$?
  printf 'resume A exit=%s B exit=%s, total consumed rows=' "$a_rc" "$b_rc"
  wc -l < "$attempt"
  cat "$WORK/gh1653-a.log" "$WORK/gh1653-b.log"
  ```

- **[Pass] Reusing the manual writer fits the admission contract.** The wake caller is actually `run_marathon_phase` (`utils/py/jog_run.py:603,719–727)); resume and gate-only source sites are L815–821 and L1062–1066. The same live HEAD, reserved branch and ancestry checks admit either a newly committed descendant or the same SHA when resuming (`gate_receipt.py:95–98,137–144,179–187`, `rtl.py:100–105`). Marathon binds its own reservation at `utils/py/relay_drive.py:1017–1022` and archives before closeout (`marathon_drive.py:2838–2843,2893`). Its attested candidate cannot cover Jog's four `TESTS-RESULTS` paths (`gate_receipt.py:145–165`, `relay_attest.py:474–497,505–526`, `jog_run.py:1197–1224`). The fixed distinct publication key and default cap 2 are consistent for new bookings (`rtl.py:69–111`, `gate_receipt.py:341–347)); failed or unfinished active rows remain counted across processes. Identify the key as the canonical publication identity going forward and avoid treating it as a recovery switch for an already exhausted budget under another key.

- **[Pass] A small extraction can preserve the CLI and caller boundary.** Leave CLI parsing, JSON field order/serialization, shell quoting, exit 3 for exhaustion and exit 2 refusal in `gate_receipt.py:323–369`; have helpers return data or raise. For `_git`'s subprocess env (`jog_run.py:1148–1153`), serialize the context dict with `json.dumps`. Save/restore the exact prior env in a `finally` covering reserve and finish, because reserve, finish and archive can all assign it (`rtl.py:112–114,268–272`, `gate_receipt.py:362–366`). The installer check only checks wiring (`jog_run.py:1156–1173`); Marathon inherits a new child env per dispatch (`jog_run.py:526–534,691–704`). Specify mapping accounting errors to the existing Jog error surface (`jog_run.py:724–727`, `releases_app.py:5236–5241`). Check CLI bytes and exits in the disposable clone. Update the existing P2 description to say Marathon retains executor attempts and Tick tokens, while Jog owns only the newly authorized publication rows through the shared writer (`test/gh280-jog-marathon-adapter.sh:1366–1378`). Refresh resume's “spend nothing” wording at `jog_run.py:775–781` accordingly.

- **[Pass] Checkpoint remains a separate scope.** [#1653](https://github.com/HiQS-Labs/XYZ-forge/issues/1653) names checkpoint in Observed and explicitly assigns the wake fix to Jog publication. [#1657](https://github.com/HiQS-Labs/XYZ-forge/issues/1657) likewise names native Jog booking. The other push is independently implemented at `skills/1-hourly/kickstart/scripts/run_record.py:599–611`. Neither that caller nor admission policy needs a change here. Keep the real installed-hook smoke distinct from the focused admission fixture, which covers the matching per-ref check (`githooks/install.sh:156–185`, `githooks/pre-push:90–99`) and only that check. A classified gate on the implementation commit alone cannot witness publication of the generated receipt commit. The same-wake disposable smoke should show the actual receipt push under the installed hook, and the separate integrated Day 4 run still owns live OL-13 credit.

### Round 1 · Producer · claude-a

Plan revised in `PROJECT/2-WORKING/GH-1653-JOG-RECEIPT-ATTEMPT.md` (Plan steps 2–4). Dispositions:

- **[Blocker] completed-before-archive strands resume — Implemented.** On rtl's `completed reservation awaits archival` refusal, Jog re-finishes the live row with the existing `manual_attempt_finish(..., "completed")` only when it is a `manual` row for this key whose `candidate` equals the target's live HEAD (same-candidate re-finish, `rtl.py:160–164`), which archives it, then books normally; any other completed row stays a refusal. A finish error after a successful push is reported distinctly (`receipt pushed; attempt finish failed`). A row left `active` by a crash after a successful push counts as consumed; the next booking's push is a no-op. New fixture case G4-archive witnesses resume recovery.
- **[Blocker] no red control for the gate-only caller — Implemented.** K2 gets the same admission hook and asserts the retry's `jog: publish` commit on the bare remote plus a completed publication row under the coordinator `$FR/.tick/attempt-history/` (would land under `$FT` without `accounting_root=root`). K2's no-builder/no-new-token checks retained.
- **[Should] wire G4 controls to the right push — Implemented.** Sentinel is receipt-only (fires after admission, only for a pushed commit whose subject starts `jog: publish`), so Marathon's closeout push is untouched. G4-neg pushes a new commit on a new task ref with both context variables unset. G4-retry uses a fresh fixture with the starting lane ref recorded; remote ref checked unchanged on failures and the exhausted retry keeps 2 rows. Cap-3 is optional. Day 3 at `3f2ffa353` is field evidence; base `52813e56f` is the replay.
- **[Should] Form 2 transport rewrite — Reproduced → fixture fix.** Clone probe (local bare remote, scratch dir): `book origin: https://github.com/example/example.git`, `hook origin: <scratch>/remote.git`, and `git config --get-regexp ^url.` inside the hook shows the command-scoped `insteadof`, push exit 1 by design. The fixture hook unsets `GIT_CONFIG_PARAMETERS`/`GIT_CONFIG_COUNT` before `admit`; production admission unchanged.
- **[Should] Form 2 two resumes contend — Implemented without probe (fix taken as suggested).** `jog resume`'s publication branch takes the existing `JogSupervisorLock(root)`, as retry-gate/retry-build already do (`jog_run.py:868–876,1089–1095`); a held lock refuses with exit 4 before any booking, so a second publisher consumes zero rows.
- **[Pass] items:** CLI bytes/exits preserved (helpers return data or raise; parsing/printing/exit codes stay in `main()`), `json.dumps` for the env, exact save/restore in `finally`, accounting errors mapped to `ContractError`, P2 reworded, resume docstring refreshed. Checkpoint stays out of scope. Smoke uses the real installed hook for the actual receipt push; live OL-13 credit stays with Day 4.

Handing off to Reviewer for round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
