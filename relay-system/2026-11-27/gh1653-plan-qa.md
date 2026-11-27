# RELAY · GH-1653 plan QA - jog books receipt-publication attempt
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-27.
-->

NEXT: Producer
STATUS: Open
ROUND: 3 / 4

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

### Round 2 · Reviewer · codex

**What this proposes**

Jog would book and finish a manual gate attempt under a stable publication key for wake, resume, and gate-only retry. The plan adds recovery for a completed row awaiting archival and uses the existing supervisor lock to serialize resume publication. The focused fixture would check the remote ref and coordinator budget, and a disposable-clone smoke would exercise the installed hook.

**How the existing system works, per this document**

Marathon's reservation is bound to reviewed source and transcript-only changes. Jog creates a separate evidence commit whose paths fall outside that attestation. The reservation ledger retains failed and unfinished rows across processes and archives completed budgets.

**What it's not**

Excluded work includes hook policy changes, new accounting mechanisms, and changing the cap. Checkpoint booking is deferred. I infer the remote proof for interrupted finalization and the exact lock ownership boundary still need to be specified.

swept file: yes

**Source-backed**

**VERDICT: FAIL**

**Basis:** Reacquiring the coordinator lock inside resume would stop supervised recovery. The completed-row recovery still books a second attempt for an already-published commit and omits the previously requested remote proof. I read the full seeded plan and checked its current source seams, including supervised recovery. The maintained graph generation was 2026-11-26T04:31:47Z. Graph call tracing was unavailable under this session's approval policy, so I checked the calls in the relay worktree directly, including the reported partial fixture range at L729–730. No reviewer phase gate is specified. Proposed fixture and smoke outcomes are [Unverified — needs clone run].

- **[Blocker] Resume would reacquire a lock held by supervised recovery.**  
  Observed input: artifact L94–95 takes `JogSupervisorLock(root)` in the pending publication branch. `utils/py/jog_run.py:2977–2978,2992–3009` already holds the coordinator lock when supervision calls `_jog_supervise_recover(root, target)`. That function can reach `jog_resume(root, gh_num)` at L2826–2844 with an approved result and no `committed_receipt`. The added acquire would resolve to the same lock (`jog_run.py:1556–1558`, `utils/py/rtl.py:1235–1246`), see this process's live PID, and exit 4 (`jog_run.py:1578–1592,1606–1608`). Its `SystemExit` also bypasses the recovery handler's `except ContractError`.  
  Affected scope: supervised wake startup or checkpoint recovery, for an approved execution with a usable invocation and pending publication.  
  Falsifier: seed that pending state and exercise both entry points in the disposable fixture. Supervised recovery with the coordinator lock already held must publish once, save `committed_receipt`, and avoid exit 4. An independent concurrent CLI resume must consume zero extra rows. Use a small already-locked resume path called by supervision and a lock-acquiring CLI entry point. Read or reload publication state under the lock and keep it through the state save. Update supervision's `without a new builder or attempt` output (L2841) when publication actually books an attempt.

- **[Blocker] R1-B1 remains open. Recover the already-published attempt without booking again.**  
  Observed input: the Round 1 falsifier requires archiving the same completed row without a fresh reservation and checking the exact remote ref. Artifact L88–93 instead archives on a local HEAD match, then expressly books again; G4-archive at L111–113 accepts any exit 0 without counting new rows or reading the remote bundle. The completed/manual admission at `utils/py/gate_receipt.py:137–144,176–178,353–366` checks the candidate and origin identity, with no remote ref lookup. The related last-slot input is a failed publication row followed by an active row whose push updated the origin before Jog died. Artifact L92–93 expects the next booking to be followed by an up-to-date push, but `utils/py/rtl.py:88–97` returns no reservation for those two live rows at cap 2, before a push can be tried. `utils/py/jog_run.py:815–827` leaves the published receipt unprojected on either refusal.  
  Affected scope: the exact validated bundle is already at its intended origin lane ref, Jog has no committed-receipt marker, and the latest live manual publication row is active or completed with archival pending. A genuinely unpublished lane remains subject to the cap.  
  Falsifier: seed one failed row and a second row at cap with the exact remote candidate, first as completed awaiting archival and then as active after the push. Resume must reconcile the same row and save the marker with no new booking. In the active case with origin still at the prior SHA, resume must refuse at cap, with both live rows and the remote unchanged. Require the existing bundle/tail proof and matching reservation identity plus exact origin ref evidence before reconciling an already-published receipt. Jog already has an exact-ref check pattern at `jog_run.py:2423–2427`. Keep G4-archive's assertions on the bare remote and existing attempt identity/count.

- **[Should] Preserve the post-push outcome through the wake's error reporting.**  
  Observed input: artifact L83–85 says `receipt pushed; attempt finish failed` is distinct, while the wake's handler at `utils/py/jog_run.py:721–727` labels every covered error `receipt-publication-failed` and prefixes it with `approved receipt not published:`. Adding only the helper's error text would produce both claims for the same successful push.  
  Affected scope: a successfully updated lane ref followed by a failed accounting finish or archive.  
  Falsifier: inject the finish failure after an admitted push. The remote ref must retain the expected bundle and the wake must report publication succeeded with accounting recovery pending. A rejected push still uses the existing unpublished message. Carry the distinction through the wake handler using the existing error/result path.

- **[Should] R1-S5 remains pending clone verification.** The Producer recorded that the two-process probe was skipped. The Form 2 input, scope, falsifier and exact **Clone probe** are in the Round 1 two-resume finding above. Run that same script with the revised lock ownership in the disposable G4-retry fixture. If the helper is imported by name, patch the binding that the publication helper actually calls so the first process stops after booking. Preserve the exit 4 and one-additional-row assertions. A plan-only checkout without the proposed helper cannot produce a valid result for that probe.

- **[Pass] R1-B2, R1-S3 and R1-S4 are addressed at plan level.** Artifact L97–119 now sends a real update through admission, singles out the receipt commit for simulated push failure, and checks K2's remote commit and coordinator archive. These discriminate the gate-only call at `utils/py/jog_run.py:1062–1066` and the wake call at L719–727. The Producer's reported transport probe (Round 1 disposition) supports clearing command-scoped config in the fixture before admission. The transport rewrite at `test/gh280-jog-marathon-adapter.sh:83–102`, the identity lookup at `utils/py/rtl.py:34–56`, and the installed stub's per-ref admission at `githooks/install.sh:153–185` support that seam. The focused hook and the separately planned installed-hook smoke test different amounts of the push path.

- **[Pass] The normal-path accounting design covers requirements 1–4 at plan level, subject to the recovery findings above.** A fresh manual reservation covers a descendant and a retry on the same HEAD (`utils/py/rtl.py:100–114`, `utils/py/gate_receipt.py:137–144,179–187`). Marathon's attested receipt cannot cover the four Jog evidence paths (`utils/py/jog_run.py:1197–1224`, `utils/py/relay_attest.py:474–526`). The fixed key, default cap and failed-row retention use the same writer (`rtl.py:75–111`, `gate_receipt.py:341–366`). Keep the exact environment restore, CLI outputs/exits, source-text P2 check and checkpoint scope in the proposed plan (artifact L75–87, L117, L13–17). The negative control in artifact L105–106 checks gate preservation. The fixture overlay in L118–119 supplies the planned failing base replay for actual Jog publication.

Handing off to Producer for round 2 to revise recovery and lock ownership and resolve the pending probe.

### Round 2 · Producer · claude-a

Plan step 2/3 revised. Dispositions:

- **[Blocker] resume reacquires the supervision lock — Implemented as suggested.** `jog_resume` becomes a lock-acquiring CLI entry over `_jog_resume_locked` (today's body, state loaded/saved inside the lock); `_jog_supervise_recover` (already holding the lock, `jog_run.py:2977–3009`) calls `_jog_resume_locked`, so no self-refusal and no `SystemExit` past its `except ContractError`. Supervision's line becomes `without a new builder turn`.
- **[Blocker] R1-B1 recover without a second booking — Implemented.** Before booking, Jog reads the exact live lane ref with `git ls-remote --exit-code origin refs/heads/<lane>` (same pattern as `jog_run.py:2423–2427`). Equal to the local bundle HEAD (after the existing bundle verification and landing-tail proof) ⇒ already published: no booking, no push; the live `GH-<n>-jog-publish` row, if `manual` and `active` or `completed` with `candidate` == HEAD, is finished `completed` through `manual_attempt_finish` (admission re-checks identity/origin/branch/candidate) and archived. Remote differs ⇒ normal booking; failed + active at cap with remote at prior SHA refuses with rows and remote unchanged. G4-archive asserts both on the bare remote and on row ids/counts.
- **[Should] post-push outcome through the wake handler — Implemented.** A finish/archive error after a successful push no longer raises: the helper prints `receipt pushed; attempt accounting pending: <err>` and returns, so callers record publication as succeeded; a rejected push keeps the existing unpublished message.
- **[Should] R1-S5 probe pending — Accepted, scheduled.** The two-resume probe needs the implementation; it runs in the disposable clone after build (patching the binding the helper calls) with expected B exit 4 and one additional row, recorded under `TESTS-RESULTS/` and shown at final QA.

Handing off to Reviewer for round 3.

### Round 3 · Reviewer · codex

**What this proposes**

Jog would use the existing manual attempt writer for receipt pushes from wake, resume, and gate-only retry. It would use the exact remote lane ref to recover an already-published bundle without booking again. CLI resume would take the coordinator lock, and supervised recovery would use the body that assumes the lock is already held.

**How the existing system works, per this document**

Marathon attests its own reservation for reviewed source and transcript-only changes. The later Jog evidence commit changes paths outside that attestation, and today's push has no independent attempt context. The accounting writer keeps failed and active rows on disk and archives a completed budget.

**What it's not**

The excluded work includes changes to hook policy, the default cap, and the reservation model. Checkpoint booking is deferred to its own caller. I infer that the precise ordering of the remote lookup and first commit, and how callers retry finalization after recording publication, still need to be pinned down.

swept file: yes

**Source-backed**

**VERDICT: FAIL**

**Basis:** The revised plan fixes the lock ownership and describes a no-rebooking recovery path for an unrecorded receipt. Two cases are still underspecified: the first publication can target a missing remote ref, and the post-push warning can leave a completed row without a reachable Jog recovery path. The two-process probe remains open. I swept the seeded artifact and reviewed the requested source seams. Discovery used the maintained XYZ-forge graph (generation 2026-11-26T04:31:47Z). Graph tracing was unavailable under the session approval policy, so I read the worktree call sites and the flagged fixture range at L729–730 directly. No reviewer phase gate was specified. Build, fixture, and smoke outcomes are [Unverified — needs clone run].

- **[Blocker] Define the first-publish path when the lane ref does not yet exist.**  
  Observed input: artifact L78–82 books before the new receipt commit, while L90–98 places the remote proof after verifying or committing the bundle, before deciding whether to book. Its cited pattern invokes `ls-remote --exit-code` through `_git`, which raises on every nonzero exit (`utils/py/jog_run.py:1148–1153,2423–2428`). A missing ref returns 2 and never reaches the “remote differs” branch through that wrapper. K2 gives a concrete first-publish case: K1 is red (`test/gh280-jog-marathon-adapter.sh:883–895`) and K2 uses the already-satisfied path (L931–937), for which Marathon explicitly leaves `lane_branch_cut` empty and closeout does nothing (`utils/py/marathon_drive.py:2722–2742,2884–2894`). The base Jog push at `jog_run.py:1237–1238` can create the ref. Also, today's tail proof can accept an approved or ledger-only HEAD without a committed bundle (`jog_run.py:1226–1230,1300–1316,1334–1335`), so equality with the Marathon head alone would be insufficient.  
  Affected scope: an approved publication on a branch never pushed by Marathon, including a fresh K2 fixture, and first publications where the current remote tip is still the approved code with no Jog bundle.  
  Falsifier: show the bare remote lacks the exact K2 lane ref before retry; the candidate must book once, create that ref with the receipt bundle, and archive the coordinator row. In G4, equality at a pre-bundle HEAD must still result in one admitted publication. Limit the equality shortcut to a proven committed bundle, then keep the normal booking path for absent or different refs. Specify how the lookup distinguishes absence from a transport failure. The separate checkpoint caller already uses a successful empty lookup to represent absence (`skills/1-hourly/kickstart/scripts/run_record.py:602–609`).

- **[Blocker] Make accounting recovery reachable after Jog records a successful push.**  
  Observed input: artifact L83–85 makes the helper return success after a finish error and tells callers to record the publication as succeeded. For an archive failure after the completed write (`utils/py/rtl.py:165–190,263–267`), wake saves `committed_receipt` (`utils/py/jog_run.py:719–731`). Resume invokes the publication helper only when that field is absent (L812–827), and the new locked body is otherwise today's body (artifact L99–104). The completed row remains live, so a later publication for the same issue reaches the refusal at `rtl.py:89–95`, contradicting the fresh-budget outcome in artifact L146. G4-archive at L119–124 seeds a crash before projection and does not exercise the now-recorded success case.  
  Affected scope: the exact approved bundle was pushed and recorded, while its latest manual row is still active or completed awaiting archival after a finish error.  
  Falsifier: inject a one-time archive error after the completed write on an admitted push. The first invocation reports the remote publication succeeded and persists its receipt. After removing the fault, a fresh resume must finish or archive the same row without another reservation or push; assert the same id, the archived row count, and the unchanged bare ref. Make the existing exact-ref recovery reachable for a saved receipt with accounting pending, or provide an explicit supported recovery using the existing writer and matching row. Preserve the successful delivery outcome.

- **[Should] R1-S5 / R2-S4 remains open pending probe verification.** The exact **Clone probe** and its Observed input, Affected scope, and Falsifier are in Round 1's “two resumes contend” finding. Artifact L125–128 now schedules it, but Round 2's Producer disposition supplies no runtime output. Run it against the implementation in a disposable clone with the reservation binding patched as specified, then record both exits and one additional row. Exercise the supervised entry with its lock already held as planned.

- **[Pass] R2-B1 is addressed at plan level.** The wrapper and already-locked body in artifact L99–104 match the CLI dispatch (`utils/py/releases_app.py:5230–5246`) and the supervised path that holds the coordinator and target locks (`utils/py/jog_run.py:2794–2797,2836–2846,2977–3009`). State load and save stay inside the lock. Update the wake-caller name in the Recon table (artifact L49) to `run_marathon_phase` (`jog_run.py:603,719–727`).

- **[Pass] The shared writer and gate controls fit the normal path.** Wake, resume, and gate retry call the helper at `utils/py/jog_run.py:719–723,815–821,1062–1066`. A fresh manual row binds the source checkout, origin, branch and starting SHA, and permits a descendant or the same SHA (`utils/py/rtl.py:100–114`, `utils/py/gate_receipt.py:137–144,179–187`). Marathon binds and archives its own reservation (`utils/py/relay_drive.py:1011–1022`, `utils/py/marathon_drive.py:2838–2843`), whose attestation excludes the four Jog evidence paths (`jog_run.py:1197–1224`, `utils/py/relay_attest.py:474–526`). The plan preserves the stable key, existing cap, exact context restoration, and CLI output and exit behavior (artifact L75–89, L146; `gate_receipt.py:341–369`, `rtl.py:88–111,268–272`). The focused G4/K2 hook exercises the same per-ref admission as the installed hook and uses a real new ref update for the unchanged negative control (artifact L105–134; `githooks/install.sh:153–185`, `githooks/pre-push:90–99`). Keep the P2 executor-state tripwire and the separate installed-hook smoke (artifact L132–137; `test/gh280-jog-marathon-adapter.sh:1366–1378`). Checkpoint stays with its existing caller (artifact L13–17; `run_record.py:599–611`). Beyond the recovery and Recon findings above, I found no pre-existing defect in the swept plan that needs a separate change.

Handing off to Producer for round 3 to resolve the two recovery cases and the pending clone probe.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
