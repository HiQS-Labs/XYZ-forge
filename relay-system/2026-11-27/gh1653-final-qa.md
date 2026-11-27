# RELAY · GH-1653 final QA - jog books receipt-publication attempt
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-27.
-->

NEXT: Producer
STATUS: Escalated
ROUND: 4 / 4

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
6. **Manual relay: commit only the relay file** (`relay(gh1653-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the committed diff `git diff 52813e56f..HEAD -- utils/py/jog_run.py utils/py/gate_receipt.py test/gh280-jog-marathon-adapter.sh` plus `PROJECT/2-WORKING/GH-1653-JOG-RECEIPT-ATTEMPT.md` and `TESTS-RESULTS/2026-11-27+GH-1653/` (read them in the worktree; do NOT edit).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-27
- Definition of Done: plan Requirements 1-4 (issue #1653, ledger #1657) are met by the built code with observed evidence: (1) approved lane publishes in the same wake/resume/gate-only retry with no manual attempt-start; (2) an unreserved task push is still refused by the unchanged gate; (3) consumed attempts survive retry and restart, an exhausted budget refuses, nothing renames/resets; (4) reuse of gate_receipt/rtl accounting, no new scheduler/suite/bypass.

### Review packet (final QA, round 1)

**Operational envelope.** Local agent CLI (Jog), single repo, canonical remote behind the repo's pre-push gate. Commensurate complexity; AGENTS.md "No new tests" (GH-831): a new `test/` file or `validate.sh` registry entry is a finding; focused cases in the existing gh280 suite are allowed (the plan named them). Never weaken the gate. Grade against the stated requirements, not speculative hardening.

**Plan QA history.** `relay-system/2026-11-27/gh1653-plan-qa.md`: 4 Codex rounds, all FAIL, cap reached; every finding dispositioned in the plan; consult tie-break single-model (Codex PROCEED, agy timed out) — not a cross-model approval. Re-check that the R1-R4 findings are actually implemented in code, including the R1-S5 probe now run.

**Evidence.** `TESTS-RESULTS/2026-11-27+GH-1653/README.md` and logs: gh280 242/0 at the fix; base-runtime red control 17 fails (wake G4, gate-only K2, retry-build K4 hit the Day 3 refusal); two-resume probe (B exit 4, one added row); installed-hook smoke (`smoke.sh`) green through the real `githooks/install.sh` stub and full pre-push gate; full `./validate.sh` at `8164e2ec1` red only on two pipe-grep guards caused by new test lines, fixed in `e9127b18` (guards green, smoke at `e9127b18` passed the full gate).

**Questions (cite file:line):**
1. Does `_jog_publish_under_attempt` / `jog_settle_publication_attempt` (jog_run.py) implement the plan exactly: book before commit, push with the context, finish completed/failed, post-push finish error reported as accounting pending (not a failed publication), exact env restore, ValueError→ContractError?
2. Already-published shortcut: only when the bundle was committed before the call AND the exact live ref equals HEAD; absent ref (empty ls-remote) and transport failure (nonzero) distinguished? Any path where a genuinely unpublished lane skips the push or the cap?
3. Settlement: completed live row archived via `rtl.archive_lane_attempts`; active row finished only with the exact-ref proof. Could it archive/finish a row belonging to a different publication or reset an exhausted budget?
4. Lock: `jog_resume` acquires `JogSupervisorLock`; `_jog_supervise_recover` calls `_jog_resume_locked`. Any other caller of `jog_resume` that already holds the lock?
5. `gate_receipt.py` extraction: CLI output/exit codes byte-compatible for attempt-start/attempt-finish?
6. Test honesty: does the gh280 hook exercise the real admission seam; do the new cases fail on the base runtime (see red log) for the right reason; any assertion that passes vacuously?
7. Is anything over-built, or is a requirement unmet? Is `run_record.py checkpoint --push` correctly left out of scope (#1653 Observed vs Next owner)?

Write your verdict below and set STATUS to Approved if it passes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Round 1 · Reviewer · codex

swept file: no

VERDICT: FAIL

Basis: The retained wake and gate-only controls show the intended booking path, but the candidate can report publication without its destination branch and can stop a saved receipt from being re-projected. The concurrency probes below are pending. I reviewed the publication, admission, resume, recovery, lock and fixture paths, including pre-existing code on those paths. The full outlying legacy code and fixture sections were outside this turn's sweep. The nearest graph generation (2026-11-26T04:31:47Z) indexes a separate development checkout, so citations use the seeded worktree source. The candidate/base CLI byte comparison and exact-commit qualification remain unverified. No suites or executable fixtures were run in this turn.

- **[Blocker] The already-published shortcut can accept a tag in place of the destination branch.**
  Observed input: The installed `git-ls-remote(1)` manual describes glob matching after any slash. `utils/py/jog_run.py:1274–1280` accepts the first OID without reading the returned refname. The allowed wire row `aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa<TAB>refs/tags/refs/heads/marathon/gh1653` produced that OID with the actual parser, expected `None`. Command under the relay scratch environment was `PYTHONPATH=utils/py python3 -` with:

  ```python
  from subprocess import CompletedProcess
  from unittest.mock import patch
  import jog_run as j
  head = "a" * 40
  ref = "refs/heads/marathon/gh1653"
  wire = f"{head}\trefs/tags/{ref}\n".encode()
  with patch.object(j.subprocess, "run", return_value=CompletedProcess([], 0, wire, b"")):
      result = j._jog_remote_ref("/unused", "marathon/gh1653")
      print(f"wire={wire.decode().strip()!r}; lookup returned {result!r}; expected None")
      assert result is None
  ```

  Exit 1, `lookup returned 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'; expected None`. At `jog_run.py:1308,1334–1336` that answer can skip both the reservation cap and the push, and at `:1314–1316` it can complete an active row using the wrong ref.
  Affected scope: A committed bundle at HEAD with an absent or different destination branch and a matching-suffix ref in the remote advertisement.
  Falsifier: Advertise the suffix tag at HEAD and either no exact branch or an exact branch at a different SHA. The former must return absent, the latter must return the exact branch's SHA regardless of row order. Select by the full returned refname, with transport errors still distinct.

- **[Blocker] Resume now requires a live execution clone even when the saved publication has no accounting left to settle.**
  Observed input: A saved `committed_receipt` and `published_head`, retained invocation file, retired execution clone and no live publication row. `utils/py/jog_run.py:835–843` now loads and validates the invocation/target before the durable projection at `:844–852`. An actual invocation loader can reject the missing target at `:120–125` or the missing drive at `:104–107`; with invocation data supplied directly, the real target validator rejects it at `:537–549`. Command under the relay scratch environment was `PYTHONPATH=utils/py python3 -` with:

  ```python
  from pathlib import Path
  from unittest.mock import patch
  import jog_run as j
  root = Path(".").resolve()
  packet = root / "relay-system/2026-11-27/gh1653-final-qa.md"
  retired = packet / "retired-clone"
  state = {"executions": [{"execution_id": "e1", "packet_dir": ".", "result_path": "result.json",
                           "committed_receipt": "TESTS-RESULTS/e1", "published_head": "a" * 40}]}
  receipt = {"outcome": "approved", "issue": "1653", "execution_id": "e1",
             "head_branch": "marathon/gh1653"}
  with patch.multiple(j, _require_jog_primary=lambda *_: None, jog_resolve_ledger_gid=lambda *_: "g",
                      jog_load_state=lambda *_: state,
                      _jog_latest_receipt=lambda *_: (state["executions"][0], receipt),
                      _ledger_abs_path=lambda *_: str(packet.parent),
                      load_marathon_invocation=lambda *_: {"target_root": str(retired)},
                      jog_save_state=lambda *_: None, jog_set_status=lambda *_, **kw: None):
      with patch.object(j.os.path, "isfile", return_value=True):
          with patch.object(j, "jog_project_marathon_outcome", return_value=("parked", "awaiting-landing")) as project:
              try:
                  result = j._jog_resume_locked(str(root), 1653)
              except j.ContractError as exc:
                  print(f"saved receipt, retired clone: {exc}; projected={project.called}")
                  raise SystemExit(2)
              print(f"resume={result}; projected={project.called}")
  ```

  Exit 2, `saved receipt, retired clone: execution target must be a separate full clone, not the primary or a worktree; projected=False`.
  Affected scope: Approved saved publications with retained coordinator evidence and either a retired clone or an unavailable origin. The saved case currently calls the remote before reading the live row (`jog_run.py:1307–1314`), even for an already archived budget.
  Falsifier: The saved-receipt case with neither a pending row nor an execution clone exits 0 and re-projects without consulting Git. With an active row and unavailable exact-ref proof, preserve the row and report the accounting problem without derailing the known publication. Read potential pending accounting before loading the disposable clone or querying origin.

- **[Should] Form 2 — a second resume can reclaim the first resume's initializing supervisor lock.**
  Observed input: `utils/py/jog_run.py:785–789` uses the nonconservative lock default at `:1682`. A creates the lock directory at `:1690`, then has a window before writing its PID at `:1733`. In that window B sees an empty owner at `:1693–1702`, removes the directory at `:1724–1727` and enters the locked body at `:789`. A then writes its PID and also enters. The recorded two-resume probe holds A after booking (`TESTS-RESULTS/2026-11-27+GH-1653/two-resume-probe-fragment.sh:12–21`), so it only covers a published lock owner.
  Affected scope: Two resume processes (or a resume and another Jog driver) sharing the coordinator during lock initialization.
  Falsifier: With A paused at the PID write, B refuses before entering the body, and A enters exactly once after being unpaused. Reuse the conservative acquisition behavior for this boundary and verify it refuses initialization without misreporting another publication.
  Clone probe: From a disposable full clone only. Uses no Git, network, credentials or queue writes.

  ```bash
  PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=utils/py python3 - <<'PY'
  import builtins, multiprocessing as mp, tempfile
  from pathlib import Path
  from unittest.mock import patch
  import jog_run as j
  ctx = mp.get_context("fork")
  a_ready, release_a, a_inside, b_inside = [ctx.Event() for _ in range(4)]
  real_open = builtins.open
  with tempfile.TemporaryDirectory(dir=Path.cwd()) as root:
      lock = Path(root) / "relay-driver.lock"
      def run(role):
          def gated_open(file, *args, **kwargs):
              if role == "A" and str(file) == str(lock / "pid") and args == ("w",):
                  a_ready.set()
                  if not release_a.wait(10):
                      raise RuntimeError("probe timed out")
              return real_open(file, *args, **kwargs)
          def enter(*_):
              (a_inside if role == "A" else b_inside).set()
              if role == "B" and not a_inside.wait(10):
                  raise RuntimeError("A did not enter")
          with patch.multiple(j, driver_lock_path=lambda *_: (str(lock), str(lock)),
                              _require_jog_primary=lambda *_: None, _jog_resume_locked=enter):
              with patch("builtins.open", gated_open):
                  try:
                      j.jog_resume(root, 1653)
                  except j.ContractError as exc:
                      print(f"{role} refused: {exc}")
                      raise SystemExit(2)
      a = ctx.Process(target=run, args=("A",))
      b = ctx.Process(target=run, args=("B",))
      a.start()
      assert a_ready.wait(5), "A did not reach lock initialization"
      b.start()
      b_inside.wait(3)
      release_a.set()
      a.join(12)
      b.join(12)
      print(f"A entered={a_inside.is_set()} exit={a.exitcode}; B entered={b_inside.is_set()} exit={b.exitcode}")
      assert a_inside.is_set() and a.exitcode == 0
      assert not b_inside.is_set() and b.exitcode in (2, 4)
  PY
  ```

- **[Should] Form 2 — completed-row settlement can archive a replacement active budget.**
  Observed input: Jog reads completed row A at `utils/py/jog_run.py:1311–1312` before taking the attempt lock. A concurrent manual writer can finish and archive A through `utils/py/gate_receipt.py:196–206` and `utils/py/rtl.py:153–190`, then reserve row B at the same key through `rtl.py:82–114`. Jog calls `archive_lane_attempts(record)` at `jog_run.py:1313`; `rtl.py:194–200,254–267` then locks and renames the current file with no binding to the observed row. The Jog supervisor lock does not cover the manual CLI entry at `gate_receipt.py:360–373`.
  Affected scope: A completed live manual publication budget only when the same key is retired and restarted between Jog's read and rename. The newly consumed active attempt belongs to the replacement budget.
  Falsifier: At that interleaving the replacement active row remains at the live path with the same id and counts against the cap. Read and validate the last row under the same canonical lock as the rename.
  Clone probe: From a disposable full clone only. Use temporary state inside that clone, with Git metadata stubbed and real attempt locking and archival.

  ```bash
  PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=utils/py python3 - <<'PY'
  import json, multiprocessing as mp, tempfile
  from pathlib import Path
  from unittest.mock import patch
  import jog_run as j, rtl
  ctx = mp.get_context("fork")
  read, proceed = ctx.Event(), ctx.Event()
  key, sha = "GH-1653-jog-publish", "a" * 40
  with tempfile.TemporaryDirectory(dir=Path.cwd()) as coord:
      record = Path(coord) / ".tick" / "attempts" / key
      def reserve():
          with patch.multiple(rtl, attempt_origin=lambda *_: "b" * 64,
                              attempt_git=lambda _r, cmd, *_: "marathon/one" if cmd == "branch" else sha):
              return rtl.lane_attempt_reserve(coord, key, coord, kind="manual")[1]
      first = reserve()
      rtl.lane_attempt_finish(first, "completed", sha, archive=False)
      def settle():
          original = j._jog_live_publication_row
          def pause(path, issue_key):
              row = original(path, issue_key)
              if row and row["id"] == first["id"]:
                  read.set()
                  assert proceed.wait(10)
              return row
          with patch.multiple(j, _jog_live_publication_row=pause, _git=lambda *_: sha.encode()):
              j.jog_settle_publication_attempt(coord, coord, 1653, "marathon/one", False)
      p = ctx.Process(target=settle)
      p.start()
      assert read.wait(5), "settlement did not observe A"
      def rotate():
          rtl.lane_attempt_finish(first, "completed", sha, archive=True)
          reserve()
      other = ctx.Process(target=rotate)
      other.start()
      other.join(2)
      rotated_while_paused = other.exitcode == 0
      proceed.set()
      p.join(12)
      other.join(12)
      live = json.loads(record.read_text().splitlines()[-1]) if record.exists() else None
      print(f"rotation finished while A paused={rotated_while_paused}; settlement={p.exitcode} rotation={other.exitcode}; live={live}")
      assert p.exitcode == 0
      assert (rotated_while_paused and live and live["state"] == "active" and live["id"] != first["id"]) or (
          not rotated_while_paused and other.exitcode in (0, 1) and (live is None or live["state"] == "active"))
  PY
  ```

- **[Should] Complete the missing resume witnesses and compare the actual failed-push ref.** `PROJECT/2-WORKING/GH-1653-JOG-RECEIPT-ATTEMPT.md:140–143,150–152` calls for supervised recovery with the lock held and an installed-hook resume after failure. `TESTS-RESULTS/2026-11-27+GH-1653/smoke.sh:35–44,49–56` calls the publication helper directly twice, with the first push already successful. `test/gh280-jog-marathon-adapter.sh:722–732,756–777` demonstrates failed/refused resumes and accounting recovery after an out-of-band publish. At `:718–731` the check labelled remote unchanged rejects one commit subject, so a missing ref or a move to a different commit still passes. Record an exact baseline OID and assert equality after each failure/exhaustion. Also retain an actual resume that publishes a still-unpublished bundle with room in the cap, and a supervised recovery of an approved pending publication. These can use the existing fixture/manual receipt. Until then those end-to-end claims are [Unverified — needs clone run].

- **[Pass] Core booking and admission.** Wake, CLI resume and gate-only retry pass the coordinator root at `utils/py/jog_run.py:719–724,828–834,1084–1089`. The write path calls the existing manual writer before commit and push, supplies its context, best-effort finishes failures, and reports the common post-push finish errors as accounting pending (`:1338–1365`, `utils/py/gate_receipt.py:190–206`). The CLI retains its JSON/export output and exit 3 for exhaustion and 2 for refusal at `gate_receipt.py:360–376` on source inspection. The successful push, negative admission, and cap controls have retained results at `TESTS-RESULTS/2026-11-27+GH-1653/gh280-green.log:111–122,174–180` and the missing-attempt red control at `gh280-red-base-runtime.log:105,168,222,311,324` in that directory. The hook reproduces the established per-ref seam (`test/gh280-jog-marathon-adapter.sh:616–634`, `githooks/install.sh:156–181`). The scoped `jog_resume` caller search found the CLI dispatch at `utils/py/releases_app.py:5245–5246` and supervised recovery calls the already-locked body at `utils/py/jog_run.py:2920–2923,2966`. The separate checkpoint push remains outside scope as specified in the plan at line 16 (`skills/1-hourly/kickstart/scripts/run_record.py:602–609`).

- **[Pass] Post-push error and environment restoration at the helper boundary.** Read-only command `PYTHONPATH=utils/py python3 -` under the relay scratch environment imported `jog_run` and patched the start and push calls to append to an in-memory sequence, patched finish to raise `ValueError("finish red control")`, and ran the real helper with an absent, empty, then nonempty caller context. Exit 0, `receipt pushed; attempt accounting pending: finish red control` and `book → commit → push → finish, successful return with pending accounting, caller env restored (absent/empty/nonempty)`, consistent with `utils/py/jog_run.py:1338–1365`. The same command compared SHA-256 against the retained `TESTS-RESULTS/2026-11-27+GH-1653/provenance.jsonl:1–9` and printed `provenance: 9 hashes match`. The syntax-only check `bash -n test/gh280-jog-marathon-adapter.sh` produced no diagnostics.

### Round 1 · Producer · claude-a

Fixes in `4f83f0b45`; evidence refreshed in `TESTS-RESULTS/2026-11-27+GH-1653/` (gh280 **245/0**). Dispositions:

- **[Blocker] tag accepted for the destination branch — Implemented.** `_jog_remote_ref` now returns only the row whose refname is exactly `refs/heads/<lane>` (any order, suffix tags ignored); nonzero `ls-remote` still refuses as a transport failure.
- **[Blocker] resume required a live clone with nothing pending — Implemented.** The saved-receipt branch reads the coordinator's live `GH-<n>-jog-publish` row first and reaches the invocation/clone/origin only when a row is pending; settlement then queries origin only for an active row (`need_published=False`). Any failure there prints `receipt published; attempt accounting pending` and projection continues. New gh280 case: saved receipt + no pending row re-projects with the execution clone moved away (rc 0, "re-projected").
- **[Should] Form 2 lock initialization race — Reproduced → fixed.** Your clone probe at `e9127b18`: AssertionError (B entered). `jog resume` now acquires `JogSupervisorLock(root, conservative=True)`; at `4f83f0b45`: `A entered=True exit=0; B entered=False exit=2`, B refused `driver lock owner is unknown or initializing` (`final-qa-r1-probe1.log`).
- **[Should] Form 2 completed-row archive vs replacement budget — Reproduced → fixed.** Your clone probe at `e9127b18`: AssertionError. Settlement now re-reads the live row under `rtl.lane_attempt_lock(record)` and archives with `_locked=True` only if the same completed id is still last; the active-row finish keeps `lane_attempt_finish`'s own lock and superseded-row refusal. At `4f83f0b45` the replacement active row survives at the live path (`final-qa-r1-probe2.log`).
- **[Should] missing resume witnesses / exact ref — Implemented.** G4-retry records the exact remote OID (`BASE_OID`) and asserts equality after each failed/refused/exhausted step; a CLI `jog resume` with room in the cap (`LANE_MAX_ATTEMPTS=3`) publishes the still-unpublished bundle (archive `failed,active,completed`); a supervised wake (`jog run --supervise-until`, row left running by a dead lease) recovers and publishes under the held lock with no self-refusal; interrupted-finish cases saved-completed / saved-active / unsaved-active each settle the same row ids with the ref unchanged. The installed-hook smoke (`smoke.sh`, at `e9127b18`) remains the installed-stub witness; the end-to-end wake/resume/supervision witnesses are the gh280 fixture with real admission.

Handing off to Reviewer for round 2.

### Round 2 · Reviewer · codex

swept file: no

VERDICT: FAIL

Basis: The retained clone results cover the initial resume, archive-race and admission cases. The saved-receipt recovery can still reset a live budget for a different branch. The shared lock's mixed-entry initialization interleaving and the planned installed-hook resume after failure remain open. I reviewed the full gate receipt module and the relevant Jog, accounting and fixture paths, including the pre-existing lock behavior there. I did not complete a line-by-line sweep of the outlying Jog and gh280 sections. The available graph generation (2026-11-26T04:31:47Z) covers a separate development checkout, so line citations use the seeded source. No suite or executable fixture was run in this turn.

- **[Blocker] Saved receipt recovery can complete and archive another branch's active reservation.**
  Observed input: A saved publication for `marathon/old` has `published_head = "a" * 40`. The execution clone is now on `marathon/new` at that same commit, having reserved a new active manual attempt for the same issue key while the new remote ref is absent. `utils/py/jog_run.py:843–847` checks the saved SHA but passes the old branch for the remote proof. At `:1327–1345` that proof admits the last active row by key. The canonical row stores its branch at `utils/py/rtl.py:100–105`, but `utils/py/gate_receipt.py:95–96,179–184,196–205` checks the **current** branch, so the actual admission path accepts the new row and requests its archival. Verified with the read-only command `PYTHONPATH=utils/py python3 -` under the relay scratch environment, with metadata and the terminal write stubbed and the actual settlement, receipt admission and row parsing exercised:

  ```python
  import json
  from unittest.mock import mock_open, patch
  import gate_receipt as g, jog_run as j, rtl

  sha, key = "a" * 40, "GH-1653-jog-publish"
  old, new = "marathon/old", "marathon/new"
  row = {"schema": rtl.ATTEMPT_SCHEMA, "task": key, "kind": "manual",
         "state": "active", "id": "c" * 32, "target_root": "/exec",
         "origin": "d" * 64, "branch": new, "start_sha": sha,
         "started": "2026-11-27T00:00:00+00:00"}
  def metadata(_root, verb, *_):
      return {"branch": new, "rev-parse": sha, "merge-base": ""}[verb]

  with patch("builtins.open", mock_open(read_data=json.dumps(row) + "\n")), \
       patch.object(g.os.path, "isfile", return_value=True), \
       patch.multiple(g, attempt_git=metadata, attempt_origin=lambda _: row["origin"]), \
       patch.multiple(j, _git=lambda *_: sha.encode(),
                      _jog_remote_ref=lambda _, branch: sha if branch == old else None), \
       patch.object(g, "lane_attempt_finish", return_value=dict(row, state="completed")) as finish:
      j.jog_settle_publication_attempt("/exec", "/coord", 1653, old, True,
                                       need_published=False)
      print(f"proved={old}; checked out/reserved={new}; finish called={finish.called}; "
            f"archive={finish.call_args.kwargs.get('archive') if finish.called else False}")
      assert not finish.called
  ```

  Exit 1, `proved=marathon/old; checked out/reserved=marathon/new; finish called=True; archive=True`. The real writer would rename the live budget via `utils/py/rtl.py:189–190,263–267`.
  Affected scope: Active publication rows for the same issue key whose reserved branch differs from the receipt branch proved at origin. This can consume a reservation the new branch still needs and reset its live attempt count.
  Falsifier: Re-run the same case and require no finish or archive request, with the active row id and live count unchanged. The matched-branch case must still settle the same row. Bind active settlement to the reserved branch and the exact ref used as proof.

- **[Should] Form 2 — the initialization race is still reachable from retry-gate beside resume.**
  Observed input: Resume passes `conservative=True` at `utils/py/jog_run.py:785–789`. A creates the lock directory at `:1719` and pauses before publishing its PID at `:1762`. Retry-gate B calls the default lock at `:899–902`, reads no owner at `:1722–1731`, and removes and recreates the directory at `:1753–1756`. Resume then writes into the replacement directory and enters its own locked body. Retry-build and an unsupervised wake also take the nonconservative path at `:1119–1122,3132–3133`. The retained Round 1 clone probe has both processes enter through resume, so it proves refusal for that pair only.
  Affected scope: A resume initializing the coordinator lock while another Jog publication entry acquires that same lock.
  Falsifier: With resume A paused at the PID write, B refuses before the retry body, and A enters once after release. Apply the initialization-safe rule consistently across the competing Jog publication entries and retain the mixed-entry result.
  Clone probe: From a disposable full clone. The probe uses local lock files and exercises both entry points before any Git, network or queue activity.

  ```bash
  PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=utils/py python3 - <<'PY'
  import builtins, multiprocessing as mp, tempfile
  from pathlib import Path
  from unittest.mock import patch
  import jog_run as j

  ctx = mp.get_context("fork")
  ready, release, a_inside, b_inside = [ctx.Event() for _ in range(4)]
  real_open = builtins.open
  with tempfile.TemporaryDirectory(dir=Path.cwd()) as root:
      lock = Path(root) / "relay-driver.lock"

      def run(role):
          def gated_open(file, *args, **kwargs):
              if role == "A" and str(file) == str(lock / "pid") and args == ("w",):
                  ready.set()
                  assert release.wait(10), "A timed out"
              return real_open(file, *args, **kwargs)

          def retry_body(*_):
              b_inside.set()
              assert a_inside.wait(10), "A never entered"

          with patch.multiple(j, driver_lock_path=lambda *_: (str(lock), str(lock)),
                              _require_jog_primary=lambda *_: None,
                              validate_marathon_executor=lambda *_: None,
                              _jog_resume_locked=lambda *_: a_inside.set(),
                              _jog_retry_gate_locked=retry_body):
              with patch("builtins.open", gated_open):
                  try:
                      if role == "A":
                          j.jog_resume(root, 1653)
                      else:
                          j.jog_retry_gate(root, 1653, None)
                  except j.ContractError as exc:
                      print(f"{role} refused: {exc}")
                      raise SystemExit(2)

      a = ctx.Process(target=run, args=("A",))
      b = ctx.Process(target=run, args=("B",))
      a.start()
      try:
          assert ready.wait(5), "resume did not reach PID write"
          b.start()
          b_inside.wait(3)
      finally:
          release.set()
      a.join(12)
      b.join(12)
      print(f"resume entered={a_inside.is_set()} exit={a.exitcode}; "
            f"retry-gate entered={b_inside.is_set()} exit={b.exitcode}")
      assert a_inside.is_set() and a.exitcode == 0
      assert not b_inside.is_set() and b.exitcode in (2, 4)
  PY
  ```

- **[Should] The installed-hook resume after failure is still [Unverified — needs clone run].** The plan requires this adjacent case at `PROJECT/2-WORKING/GH-1653-JOG-RECEIPT-ATTEMPT.md:150–152`. `TESTS-RESULTS/2026-11-27+GH-1653/smoke.sh:35–44,49–56` calls the helper twice, after the first push already succeeded. The new CLI and supervised resume cases use the admission-only fixture hook at `test/gh280-jog-marathon-adapter.sh:621–634,763–795`. Retain one deliberately refused publication and a successful CLI resume from the same state through the actual installed hook, with the failed row still counted and the remote OID observed before and after each step. The current candidate's final classified gate is also undocumented. The plan requires it at line 157 and the evidence README lines 12–18 identify only the focused run at `4f83f0b45` and the prior installed full-gate smoke at `e9127b18`. Retain the actual final gate result and align the per-run provenance revisions with the log descriptions (for example, `provenance.jsonl:9,13` currently label the older installed-smoke and validate logs with `4f83f0b45`).

- **[Pass] Exact ref parsing and saved state without a live row.** Read-only `PYTHONPATH=utils/py python3 -` with `subprocess.run` stubbed returned the expected cases at `utils/py/jog_run.py:1278–1290`: `suffix-only absent, exact wins both orders, empty absent, transport refused`. The parser assertions and all 13 evidence hashes passed before the separate failing settlement assertion in the same command (overall exit 1). Saved receipts with no pending row skip the invocation and re-project at `:835–857`; see `TESTS-RESULTS/2026-11-27+GH-1653/gh280-green.log:125`. The saved branch still projects when settlement raises a caught accounting error at `:848–857`.

- **[Pass] Round 1 same-entry lock and completed-row replacement races.** At `4f83f0b45`, `TESTS-RESULTS/2026-11-27+GH-1653/final-qa-r1-probe1.log:1–8` shows resume B entered before the fix and refused after it (A exit 0, B exit 2), and `final-qa-r1-probe2.log:1–7` shows the replacement active row lost before and still live after. The code rechecks row id and state under the canonical lock at `utils/py/jog_run.py:1336–1341`. The already-owned recovery path invokes `_jog_resume_locked` at `:2991–3001`, and the plan QA's two-resume probe reports B exit 4 and one additional row at `two-resume-probe.log:7–14`.

- **[Pass] Retained booking, failed-budget, and fixture recovery evidence.** `utils/py/jog_run.py:721–724,831–834,1091–1095,1369–1394` supplies the coordinator root, books before commit/push, reuses the manual finish path and restores the caller environment. `TESTS-RESULTS/2026-11-27+GH-1653/gh280-green.log:110–125,177–183,248` records 245 passes, including admission refusal for an unreserved push, two failed rows surviving restart, exact OID equality after retry/exhaustion, CLI recovery with room and supervised recovery. The first refusal establishes that the remote is not at the bundle, with the prior OID captured immediately afterward at `test/gh280-jog-marathon-adapter.sh:720–735`. The base-runtime refusal is retained at `gh280-red-base-runtime.log:105,168,222` in the same evidence directory. The fixture calls the real admission CLI per ref as the installed hook does (`test/gh280-jog-marathon-adapter.sh:621–634`, `githooks/install.sh:156–181`). Both shell files parsed under `bash -n test/gh280-jog-marathon-adapter.sh && bash -n TESTS-RESULTS/2026-11-27+GH-1653/smoke.sh`, exit 0 with no diagnostics.

- **[Pass] Scoped reuse and CLI surface.** `utils/py/gate_receipt.py:190–206,360–376` retains the manual writer, JSON/export shape, exhausted exit 3 and refusal exit 2 on source comparison to the available pre-extraction development source. Byte-for-byte execution against exact base `52813e56f` remains unverified. The plan leaves checkpoint push out of scope at `PROJECT/2-WORKING/GH-1653-JOG-RECEIPT-ATTEMPT.md:12–17`. The publication implementation uses the existing writer and attempt lock.

Handing off to Producer to fix the reservation proof mismatch and close the open clone-evidence findings.

### Round 2 · Producer · claude-a

Fixes in `cc6c73d9e`; gh280 **245/0** there. Dispositions:

- **[Blocker] saved-receipt settlement could finish another branch's active row — Reproduced → fixed.** Your probe at `4f83f0b45`: AssertionError (`finish called=True; archive=True`). Active settlement now also requires `row["branch"] == branch` (the lane whose exact ref is the proof). At `cc6c73d9e`: `finish called=False; archive=False` (`final-qa-r2-probe-branch.log`). Matched-branch settlement is still exercised by gh280's saved-active / unsaved-active cases (pass).
- **[Should] Form 2 mixed-entry initialization race — Reproduced → fixed for the publication entries.** Your probe at `4f83f0b45`: AssertionError. `jog_retry_gate` and `jog_retry_build` now take `JogSupervisorLock(root, conservative=True)`, like resume. At `cc6c73d9e`: `resume entered=True exit=0; retry-gate entered=False exit=2` (`final-qa-r2-probe-mixed.log`). **Declined (scoped):** the unattended wake keeps `conservative=supervised` unchanged — a supervised wake is already conservative, and making the unsupervised wake conservative would stop it reclaiming an empty lock left by a crash between `mkdir` and the PID write (a pre-existing recovery behaviour outside #1653).
- **[Should] installed-hook resume after failure + final gate + provenance — Implemented / scheduled.** `smoke.sh` now runs: a booked publication whose push cannot reach the remote (1 failed row, remote OID observed before/after), then the resume of that same approved receipt through the real installed stub (admission + full gate), then the rerun and the unreserved control. It and the final classified gate run once on the qualification head, which per the parent's landing order must first merge `origin/development` after PR #1669 lands; both results will be retained before push. `provenance.jsonl` now labels each file with the revision it was produced at.

Handing off to Reviewer for round 3.

### Round 3 · Reviewer · codex

swept file: no

VERDICT: FAIL

Basis: The reservation-branch mismatch and the resume versus retry-gate initialization case have passing evidence. The installed-hook CLI resume and final classified gate still lack results. An ordinary unsupervised wake can still reclaim an initializing resume lock. This round reviewed the affected publication and recovery paths, accounting, smoke and retained records. It did not sweep the full legacy Jog and gh280 files. The graph generation (2026-11-26T04:31:47Z) indexes a separate development checkout, so citations below use the seeded worktree. I ran no suites, executable fixtures or Git commands.

- **[Should] The installed-hook CLI resume and final classified gate remain [Unverified — needs clone run].**
  Observed input: The plan requires `jog resume` after failed publication through the installed hook at `PROJECT/2-WORKING/GH-1653-JOG-RECEIPT-ATTEMPT.md:150–152`. The new smoke calls `publish()` at `TESTS-RESULTS/2026-11-27+GH-1653/smoke.sh:57,62,68`, whose body directly invokes `publish_jog_receipt` at lines 37–46. This skips CLI dispatch and loading, locking and projecting saved state (`utils/py/releases_app.py:5236–5246`, `utils/py/jog_run.py:785–857`). The retained installed-hook log at lines 1–15 shows a first successful helper push followed by a helper rerun, and its provenance is `e9127b18` (`provenance.jsonl:13`). The inherited gh280 CLI and supervised resume witness uses the admission-only fixture hook (`test/gh280-jog-marathon-adapter.sh:621–634,763–795`). The final classified gate required by the plan at line 157 is still scheduled in the Round 2 disposition.
  Affected scope: Qualification of the public resume command against the actual installed hook after a booked publication fails, and qualification of the eventual delivery revision.
  Falsifier: Retain a disposable-clone smoke that invokes `python3 "$coordinator/utils/py/releases_app.py" --root "$coordinator" jog resume "$issue"` from the failed execution's saved state with the real installed hook. Require the failed publication to leave one failed row and the remote lane OID unchanged. Require CLI resume to exit 0, save/project the publication, update the remote ref to the bundle SHA and archive the same failed row plus the completed retry. Keep the unreserved refusal. Check the printed statuses and OIDs explicitly, since the diagnostic `echo` calls at smoke lines 57–74 can leave the script with exit 0 after a failed expectation. Record that result and the actual final classified gate result with their revisions and provenance. The current smoke is a useful helper retry check.

- **[Should] Form 2 — an unsupervised wake can still take the coordinator lock during resume initialization.**
  Observed input: Resume A takes the conservative lock at `utils/py/jog_run.py:785–789`, creates the directory at `:1721–1722` and pauses before opening the PID file at `:1763–1765`. With no `--supervise-until`, wake B sets `supervised=False` at `:3035–3036` and acquires the same lock at `:3134–3135`. B sees no PID at `:1724–1731`, skips the conservative refusal at `:1733–1734`, and removes and recreates the directory at `:1751–1758`. It proceeds into orphan reconciliation at `:3167–3168` and can reach the publication driver at `:3267–3275`. When A resumes, it writes into B's directory and also enters its protected body. The Round 2 probe covers retry-gate as B, and the Producer explicitly left the ordinary wake path unchanged.
  Affected scope: Ordinary unsupervised `jog run` sharing a coordinator with `jog resume` while resume is publishing the lock owner.
  Falsifier: Pause A immediately before its PID write. B refuses before entering the wake body, then A enters exactly once. If preserving stale empty-lock recovery, distinguish an initializing owner from an abandoned directory and retain a separate stale-lock control.
  Clone probe: From a disposable full clone. This stops B at the first post-lock queue operation and substitutes A's protected body. It makes no Git, network or queue calls.

  ```bash
  PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=utils/py python3 - <<'PROBE'
  import builtins, multiprocessing as mp, tempfile
  from pathlib import Path
  from types import SimpleNamespace
  from unittest.mock import patch
  import jog_run as j

  ctx = mp.get_context("fork")
  ready, release, a_inside, b_inside = [ctx.Event() for _ in range(4)]
  real_open = builtins.open
  with tempfile.TemporaryDirectory(dir=Path.cwd()) as root:
      lock = Path(root) / "relay-driver.lock"
      (Path(root) / "releases.db").touch()

      def run(role):
          def gated_open(file, *args, **kwargs):
              if role == "A" and str(file) == str(lock / "pid") and args == ("w",):
                  ready.set()
                  assert release.wait(10), "resume timed out"
              return real_open(file, *args, **kwargs)

          def stop_wake(_):
              b_inside.set()
              assert a_inside.wait(10), "resume never entered"
              raise SystemExit(0)

          with patch.multiple(j, driver_lock_path=lambda *_: (str(lock), str(lock)),
                              _require_jog_primary=lambda *_: None,
                              validate_marathon_executor=lambda *_: None,
                              _execution_root=lambda *_: root,
                              validate_checkpoint_options=lambda *_: None,
                              _jog_resume_locked=lambda *_: a_inside.set(),
                              jog_reconcile_orphan_leases=stop_wake), patch("builtins.open", gated_open):
              try:
                  if role == "A":
                      j.jog_resume(root, 1653)
                  else:
                      j.jog_run_main(SimpleNamespace(root=root))
              except j.ContractError as exc:
                  print(f"{role} refused: {exc}", flush=True)
                  raise SystemExit(2)

      a = ctx.Process(target=run, args=("A",))
      b = ctx.Process(target=run, args=("B",))
      a.start()
      try:
          assert ready.wait(5), "resume did not reach PID write"
          b.start()
          b_inside.wait(3)
      finally:
          release.set()
      a.join(12)
      b.join(12)
      print(f"resume entered={a_inside.is_set()} exit={a.exitcode}; "
            f"wake entered={b_inside.is_set()} exit={b.exitcode}")
      assert a_inside.is_set() and a.exitcode == 0
      assert not b_inside.is_set() and b.exitcode in (2, 4)
  PROBE
  ```

- **[Pass] Active reservation branch binding and evidence hashes.** The exact-ref proof now also requires the row's branch to match (`utils/py/jog_run.py:1337–1347`). Under the relay scratch environment, `PYTHONPATH=utils/py python3 -` stubbed `_jog_live_publication_row` to return an active `marathon/new` row, stubbed local and remote SHA to the same value, and recorded calls to `manual_attempt_finish` across proofs for `marathon/old` and `marathon/new`. Exit 0, `marathon/old: settled=False; finish calls=0`, `marathon/new: settled=True; finish calls=1`, and `provenance: all 17 artifact hashes match` (`TESTS-RESULTS/2026-11-27+GH-1653/provenance.jsonl:1–17`). The retained before/after probe at `final-qa-r2-probe-branch.log:1–6` includes real admission and the prior failing assertion. `bash -n TESTS-RESULTS/2026-11-27+GH-1653/smoke.sh && bash -n test/gh280-jog-marathon-adapter.sh` exited 0 with no diagnostics.

- **[Pass] Conservative resume/retry acquisition and focused publication cases.** The retained `TESTS-RESULTS/2026-11-27+GH-1653/final-qa-r2-probe-mixed.log:1–8` shows resume entered and retry-gate refused at `cc6c73d9e`. Retry-build also passes the conservative flag (`utils/py/jog_run.py:900–905,1119–1125`). The completed-row replacement check remains under the attempt lock (`:1337–1342`), with the retained before/after result at `final-qa-r1-probe2.log:1–7`. The focused log at `gh280-green.log:110–125,177–183,248` records 245/0, including wake, unreserved refusal, persistent failures and cap, gate-only creation, saved-state settlement, CLI resume and supervised recovery. CLI output and exit paths remain as inspected at `utils/py/gate_receipt.py:360–376`. Byte-for-byte CLI comparison against the exact base remains unverified.

Handing off to Producer to exercise the remaining lock interleaving and retain the installed-hook CLI resume and qualification results.

### Round 3 · Producer · claude-a

Fixes in `8f47703f5`; gh280 **245/0**, `jog-queue.sh`, `gh139`, `gh460` exit 0 there. Dispositions:

- **[Should] installed-hook CLI resume — Implemented.** New `TESTS-RESULTS/2026-11-27+GH-1653/smoke-cli.sh` runs the public `releases_app.py --root <coordinator> jog resume 1653` from a coordinator clone (queue row via `jog add`, hand-built approved execution state + invocation) against an execution clone with the **real installed stub**, with explicit checks that make the script exit nonzero on any failed expectation. Result at `8f47703f5`: 12/12 OK — refused resume rc=2, one `failed` row, remote OID absent→absent; `jog resume` rc 0, remote lane = bundle commit, archive `failed,completed`, receipt saved; rerun re-projected with nothing booked and the ref unchanged; unreserved push refused (`smoke-cli-installed-hook.log`). **Final classified gate:** per the parent's landing order the qualification head must first merge `origin/development` after PR #1669; the gate runs once on that merged head from a disposable clone before push, and its result is recorded in the PR and closeout (it cannot exist on this pre-merge revision).
- **[Should] Form 2 unsupervised wake reclaims an initializing lock — Reproduced → fixed.** Your probe at `cc6c73d9e`: AssertionError. `JogSupervisorLock.acquire` now refuses an owner-less lock younger than `LOCK_INIT_GRACE_S` (10 s) for every entry ("driver lock owner is initializing"); older owner-less locks are still reclaimed as stale, preserving crash recovery. At `8f47703f5`: `resume entered=True exit=0; wake entered=False exit=2`; stale control: fresh empty lock refused, 60 s-old empty lock reclaimed (`final-qa-r3-probe-wake.log`).

Handing off to Reviewer for round 4 (cap).

### Round 4 · Reviewer · codex

swept file: no

VERDICT: FAIL

Basis: The installed-hook CLI resume evidence closes that part of Round 3. The lock fix prevents the short interleaving in the retained probe, but an unsupervised wake can still reclaim the lock while a live resume is paused before writing its PID. The extended interleaving is pending clone verification at the round cap. I reviewed the publication, attempt accounting, resume, lock and test evidence paths, including the pre-existing stale-lock behavior. The rest of the legacy Jog and gh280 files were outside this sweep. The graph generation at 2026-11-26T04:31:47Z covers a separate checkout and traces were unavailable under the session approval policy, so citations use the seeded source. The classified gate on the approved delivery commit is [Unverified — needs clone run] under plan lines 30–34 and 154–157. Exact-base byte-for-byte CLI comparison remains unverified. No Git commands, suites or executable fixtures ran in this turn.

- **[Should] Form 2 — an unsupervised wake can still replace a live resume's lock after the 10-second grace period.**
  Observed input: Resume A acquires before entering its body at `utils/py/jog_run.py:785–791`. It creates the directory at `:1723–1725` and can be paused before the PID write at `:1775–1777`. Wake B without `--supervise-until` is nonconservative at `:3047–3048,3146–3147`. If A stays paused for 11 seconds, B sees no PID at `:1727–1734`. Directory age alone makes the initialization check false at `:1710,1738–1746`. B then replaces the directory at `:1763–1770` and reaches its protected body at `:3180`. A resumes, writes into B's directory and enters its own protected body at `:789`. B can reach publication through `:3279–3287`; either release can also remove the other's lock at `:1783–1789`. The retained probe at `TESTS-RESULTS/2026-11-27+GH-1653/final-qa-r3-probe-wake.sh:16–20,43–57` starts B immediately after A pauses, and its stale control has no initializing process (`final-qa-r3-probe-wake.log:5–10`).
  Affected scope: An unsupervised wake sharing a coordinator with resume when suspend, scheduling delay or a stalled PID write leaves the live owner unpublished beyond the grace period.
  Falsifier: With A alive and paused immediately before its PID write for 11 seconds, B refuses before the wake body, then A enters once. Make reclamation distinguish an initializing live owner from an abandoned lock and retain an abandoned-lock recovery control.
  A local single-process decision probe used `PYTHONPATH=utils/py python3 -` with `os.mkdir` stubbed to raise `FileExistsError` and then succeed, `isfile` false, `st_mtime=100.0`, `time.time=100+age`, and `rmtree` and PID writes mocked. Exit 0, `age=9s acquired=False removed=False` and `age=11s acquired=True removed=True`. This measures the decision, with the two-process overlap still pending.
  Clone probe: Run from a disposable full clone. Reuse the retained two-process probe with A's wait extended and B started only after the grace period. It uses local temporary files inside the clone and stops before Git, network or queue operations.

  ```bash
  PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=utils/py python3 - <<'PROBE'
  from pathlib import Path

  path = Path("TESTS-RESULTS/2026-11-27+GH-1653/final-qa-r3-probe-wake.sh")
  first, *body, last = path.read_text().splitlines()
  assert first.endswith("<<'PROBE'") and last == "PROBE"
  source = "\n".join(body)
  before = "assert release.wait(10)"
  start = "        b.start()"
  assert source.count(before) == 1 and source.count(start) == 1
  source = "import time\n" + source.replace(before, "assert release.wait(30)")
  source = source.replace(start, "        time.sleep(11)\n" + start)
  exec(compile(source, str(path), "exec"))
  PROBE
  ```

- **[Pass] Installed-hook CLI resume after failure.** `TESTS-RESULTS/2026-11-27+GH-1653/smoke-cli.sh:24,63–99` installs and checks the real hook, invokes the public resume verb and fails if any expectation fails. The retained result at `8f47703f5` shows first refusal exit 2 with one failed row and an unchanged absent remote ref, then resume exit 0 with the bare remote ref at the bundle commit and `failed,completed` archived. A further resume re-projects with the same OID and budget history, and an unreserved push is refused. See `smoke-cli-installed-hook.log:1–28` and `provenance.jsonl:14–15` in the same directory.

- **[Pass] Focused publication evidence and artifact integrity.** The retained `gh280-green.log:110–125,177–183,248` records 245 pass and 0 fail, covering wake, gate-only creation, refusal, retry and exhausted-cap accounting, saved-state settlement and supervised recovery. In this turn, `bash -n` on `test/gh280-jog-marathon-adapter.sh`, `smoke.sh`, `smoke-cli.sh` and `final-qa-r3-probe-wake.sh`, followed by `python3 -` comparing the full directory membership and SHA-256 of every nonempty artifact with the unique entries in `TESTS-RESULTS/2026-11-27+GH-1653/provenance.jsonl:1–21`, exited 0 with `bash syntax: 4 files passed` and `provenance: 21 unique nonempty artifacts match SHA-256`.

Handing off to Producer at escalation for the extended lock probe and its disposition.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
