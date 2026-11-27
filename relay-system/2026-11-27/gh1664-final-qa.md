# RELAY · GH-1664 final QA: stale-evidence admission refusal
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-27.
-->

NEXT: Producer
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
6. **Manual relay: commit only the relay file** (`relay(gh1664-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the committed implementation on this branch versus the development base commit 52813e56f: `utils/py/jog_run.py` (`_admission_captures`, `stale_evidence_refusal`, both pre-lease call sites), `test/gh280-jog-marathon-adapter.sh` (G9–G13), docs (`skills/1-hourly/conveyor/SKILL.md`, `skills/2-daily/jog/SKILL.md`, `relay-automation/CONTRACT.example.md`, `PROJECT/2-WORKING/GH-1476-RAW-TASK-PREPARATION.md`), plan `PROJECT/2-WORKING/GH-1664-STALE-EVIDENCE-ADMISSION.md`, evidence `TESTS-RESULTS/2026-11-27+GH-1664/provenance.jsonl` (and its sibling suite, replay, consult folders and icase-manual-check.txt), plan QA thread `relay-system/2026-11-27/gh1664-plan-qa.md`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-27
- Definition of Done: the plan's `## Acceptance` (verbatim from issue #1664) is satisfied by the code, and the evidence substantiates each box.

### Operational envelope
Local developer CLI (Jog over local SQLite), single repo. Grade against the Acceptance, the approved plan (including the R1–R4 and consult C1 amendments), commensurate complexity and AGENTS.md (No new tests, GH-831: a NEW test file or validate.sh entry is a finding; cases added to an existing suite are allowed). `git diff origin/development...HEAD` shows the change. Do not run suites in the relay worktree; the retained logs are the run evidence.

### Questions
1. Does each Acceptance box hold? Cite the code path and the retained receipt line: refusal names reason + paths, row parked, attempt unchanged (G9, replay snapshot); same row admits after refresh with no duplicate and budget intact (G10, replay `refresh:` line); unchanged cited files admit as before (G4+ green, G10 unrelated diff); red-then-green in an existing suite (suite/red-*.log vs suite/green-full.log).
2. What prevents an unchanged, unfixed candidate (base `jog_run.py`) from being reported delivered? Point at the observed red rejections (G9, G11, G13 red logs; replay red log).
3. Does the code match the plan: capture union via the extracted helper (hold behaviour unchanged), per-capture legacy skip, fetch-before-resolve with failed fetch refusing, execution-root-only, stripped artifacts plus literal probe paths, `icase` when `core.ignorecase=true`, fail-closed on malformed or unknown `prepared_commit`, no empty pathspec diff, `--simulate` exempt?
4. Any regression risk to existing hold refusals or to legacy captures (no `prepared_commit`): any new network call, output change or refusal for them?
5. Did a duplicate subsystem/writer, new schema, queue or suite slip in? Is the persisted rating (70/55/50/65) still consistent with the evidence?
6. Sweep `stale_evidence_refusal` and `_admission_captures` whole, plus their call sites, for pre-existing or new defects.

Output: graded findings with file:line, `swept file: yes|no`, a literal `VERDICT: PASS|FAIL|PARKED` line and a `Basis:` line; STATUS Approved only on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1 (codex)

swept file: yes

- **[Blocker] A malformed prepared ref aborts the queue instead of parking the item.** Observed input: the seeded contract with the plan's base SHA as `prepared_commit` and JSON `"ref": "development\u0000"`. The real contract parser accepts that string (`utils/py/swarm_preflight.py:65–70,132–153`). Jog's nonblank test accepts it and the rev-parse launch raises before it can return an unavailable reason (`utils/py/jog_run.py:1752–1753,1777–1787`). Both callers require that reason to take their park branch (`:1114–1120,3158–3171`). Affected scope: stamped packets with a ref or cited path that cannot be passed to Git as an argument. Falsifier: run the same probe and expect a named `stale-check-unavailable:` return, with normal ref inputs and the existing G11–G13 outcomes preserved. Validate the Git-bound fields or handle launch errors within the existing admission check so the row parks before any lease.

  Read-only probe below exited **1** with `jog_run.py:1785 → jog_run.py:1753 → ValueError: embedded null byte`. Fetch was stubbed as successful and the real Python subprocess argument check was exercised against the Python executable. No Git or network command ran.

```bash
python3 -B - <<'PY'
import io, json, subprocess, sys
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0, "utils/py")
import jog_run, swarm_preflight
doc = Path("PROJECT/2-WORKING/GH-1664-STALE-EVIDENCE-ADMISSION.md")
packet = swarm_preflight.extract_contract(str(doc))
packet.update(prepared_commit="52813e56f0abd76cd3ba277602cc3e7fdf1e6f90")
packet["target"]["ref"] = "development\0"
markdown = "## Swarm Preflight Contract\n```json\n" + json.dumps(packet) + "\n```\n"
run = subprocess.run
def local_run(argv, **kwargs):
    if argv[3:] == ["fetch", "--prune", "--quiet"]:
        return subprocess.CompletedProcess(argv, 0, "", "")
    assert argv[3:6] == ["rev-parse", "--verify", "--quiet"], argv
    return run([sys.executable, "-c", "pass", argv[-1]], **kwargs)
with patch.object(jog_run, "_admission_captures", return_value=[str(doc)]), \
     patch.object(swarm_preflight, "open", side_effect=lambda *a, **k: io.StringIO(markdown), create=True), \
     patch.object(jog_run.subprocess, "run", side_effect=local_run):
    assert swarm_preflight.extract_contract(str(doc))["target"]["ref"] == "development\0"
    reason = jog_run.stale_evidence_refusal(".", 1664)
    assert reason and reason.startswith("stale-check-unavailable:"), reason
PY
```

- **[Should] Bound the new admission fetch by the supervised dispatch deadline.** Observed input: `--supervise-until` establishes a monotonic deadline (`utils/py/jog_run.py:2953–2973`) → the queue checks it before selecting an item (`:3106–3128`) → supervised alignment returns (`:3135–3137`) → the stale check gets no deadline (`:3158–3159`) → the added fetch uses bare `subprocess.run` without a timeout (`:1752–1753,1781–1784`), while the later Preflight call already uses the bounded process path (`:644–647,2827–2842`). Affected scope: supervised admission of a stamped packet when the added fetch takes longer than the remaining dispatch time, after alignment has completed. Falsifier: a local child that delays the admission fetch for four seconds must be stopped by a one-second remaining deadline, before a lease. Use the existing bounded runner for the added Git calls when a deadline is set and put the supervised caller's deadline on that path. Pending clone probe verification.

  Clone probe: from the disposable full clone root, use this local fake Git child. It performs no fetch, accesses no credentials and uses a temporary directory inside that clone. The current helper takes no deadline argument, so the baseline branch below measures its current call. On a fix, test the deadline-aware call and confirm the supervised call site passes that same deadline.

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -B - <<'PY'
import inspect, io, json, os, sys, tempfile, time
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, "utils/py")
import jog_run, swarm_preflight

doc = Path("PROJECT/2-WORKING/GH-1664-STALE-EVIDENCE-ADMISSION.md").resolve()
packet = swarm_preflight.extract_contract(str(doc))
packet["prepared_commit"] = "52813e56f0abd76cd3ba277602cc3e7fdf1e6f90"
markdown = "## Swarm Preflight Contract\n```json\n" + json.dumps(packet) + "\n```\n"
with tempfile.TemporaryDirectory(dir=Path.cwd()) as tmp:
    child = Path(tmp, "git")
    child.write_text(f"#!{sys.executable}\nimport sys, time\n"
                     "assert sys.argv[3:] == ['fetch', '--prune', '--quiet']\n"
                     "time.sleep(4)\nsys.exit(1)\n")
    child.chmod(0o700)
    check = jog_run.stale_evidence_refusal
    with patch.dict(os.environ, {"PATH": tmp + os.pathsep + os.environ["PATH"]}), \
         patch.object(jog_run, "_admission_captures", return_value=[str(doc)]), \
         patch.object(swarm_preflight, "open", lambda *a, **k: io.StringIO(markdown), create=True):
        started = time.monotonic()
        kwargs = {"deadline": started + 1} if "deadline" in inspect.signature(check).parameters else {}
        try:
            reason = check(str(Path.cwd()), 1664, **kwargs)
        except jog_run.ContractError as exc:
            reason = str(exc)
        elapsed = time.monotonic() - started
        print(f"elapsed={elapsed:.2f}s reason={reason!r}")
        assert elapsed < 3 and reason and ("deadline" in reason or "timed out" in reason), reason
PY
```

- **[Should] Retain the planned red evidence for G12.** Observed input: the plan requires a base rejection at G12 (`PROJECT/2-WORKING/GH-1664-STALE-EVIDENCE-ADMISSION.md:196–201,209–216`), but the cut run stops at the G13 failure and exits 1 before reaching G12 (`TESTS-RESULTS/2026-11-27+GH-1664/suite/red-base-g12-g13-cut.log:122–129`, `test/gh280-jog-marathon-adapter.sh:831–846`). Affected scope: the remote-only change witness, specifically the regression where successful admission compares cached A. Falsifier: retain a disposable-clone base run of G12 alone with its remote left reachable. Expect the G12 refusal oracle to fail after a lease and dispatch. The existing green G12 receipt must still show a named refusal at B with zero attempts and no execution. Record the exact cut, revision, command and exit in provenance.

- **[Pass] Acceptance 1–3 on the retained fixture.** Run and retry-build share the refusal before the lease (`utils/py/jog_run.py:1114–1125,3155–3171`). G9 names `src/feature.js`, parks at 1 and records no execution (`TESTS-RESULTS/2026-11-27+GH-1664/suite/green-full.log:122–125`). The inbox replay independently shows the unchanged capture, attempts 1→1 and executions 0→0 (`replay/green-stale-evidence-run.log:4–10`, relative to the evidence directory). Its refresh reaches the worker once, with the same global ID, one row and attempts 1→1→2 (`:35–45`). The replay uses a stub exit 9 after dispatch. G10 supplies the approving receipt and the artifact write after an unrelated commit above the refreshed stamp (`test/gh280-jog-marathon-adapter.sh:780–801`, `suite/green-full.log:126–129`). G4 covers unstamped dispatch (`:105–110`). The recovery handoff directs inbox packets to `jog retry` plus `jog run` with the clone current (`skills/1-hourly/conveyor/SKILL.md:69–71,105–109`, `skills/2-daily/jog/SKILL.md:168–176`).
- **[Pass] Acceptance 4 has a discriminating red and green in the existing suite.** Base spends attempt 2 at G9, attempt 1 at G11, and attempt 1 plus a Preflight execution at G13 (`suite/red-base-jog_run.log:122–123`, `suite/red-base-g11-cut.log:122,167`, `suite/red-base-g12-g13-cut.log:122–129`). The base replay reaches the worker once, increments the attempt and fails its refusal assertion (`replay/red-stale-evidence-run.log:34–37`). The candidate suite logs G9–G13 and 244 pass, 0 fail (`suite/green-full.log:122–137,248`). The GH-1664 packet's own `grep_absent` probe seeks the implementation marker with the existing Preflight polarity (`PROJECT/2-WORKING/GH-1664-STALE-EVIDENCE-ADMISSION.md:289–305`, `utils/py/swarm_preflight.py:278–282,302–305`).
- **[Pass] Capture selection, compatibility and scope.** The shared union covers the working glob, lifecycle candidates and canonical selection (`utils/py/jog_run.py:1664–1678`, `utils/py/swarm_preflight.py:1439–1446`). Holds short-circuit staleness, and simulation skips both. An unstamped capture emits the planned notice and continues without a new fetch for that capture (`jog_run.py:1699–1732,1771–1784,3155–3159`). The stamped path uses the execution root, fetches once before resolution, refuses nonzero fetch and invalid or unknown stamps, strips artifacts, preserves probe spelling, and skips an empty path list (`:1752–1805`). C1's retained manual check records detection with `core.ignorecase=true` and the miss with it forced false (`icase-manual-check.txt:1–10`). The parking and retry writes remain in the existing queue owner (`utils/py/releases_app.py:4963–4974,5124–5138`). Coverage lives in G9–G13 of the existing adapter suite and the retained replay witness (`test/gh280-jog-marathon-adapter.sh:727–847`, `provenance.jsonl:1–11`). The stored 70/55/50/65 matches the plan's rationale and bounded implementation (`releases.sql:1072`, `PROJECT/2-WORKING/GH-1664-STALE-EVIDENCE-ADMISSION.md:280–287`).
- **[Pass] Retained receipt bytes.** From the repo root, the following read-only probe exited 0 with `11 nonempty evidence files match provenance SHA-256` (`provenance.jsonl:1–10`, including the source archive hash on line 1).
  ```bash
  python3 -B -c 'import hashlib,json,pathlib; p=pathlib.Path("TESTS-RESULTS/2026-11-27+GH-1664/provenance.jsonl"); rows=[json.loads(s) for s in p.read_text().splitlines()]; checks=[(pathlib.Path(r[k]).read_bytes(),r[h]) for r in rows for k,h in (("artifact","sha256"),("source","source_sha256")) if h in r]; assert checks and all(b and hashlib.sha256(b).hexdigest()==h for b,h in checks); print(len(checks),"nonempty evidence files match provenance SHA-256")'
  ```

VERDICT: FAIL
Basis: The whole admission-helper and call-site sweep found the malformed-ref failure and the new unbounded supervised fetch. The existing retry-build inbox limitation is documented in the operator handoff (`skills/2-daily/jog/SKILL.md:168–176`). The core behavior has retained proof, with the specific G12 red control still missing. The nearest graph predates this lane and its trace calls were denied, so citations use worktree source. Suites and the full gate were not run in this relay worktree. Producer claude-a should address the findings, run the deadline probe and return the evidence for review.

### Producer · Round 1 (claude-a)

Dispositions (fix commit `fc02e445d`):
- **[Blocker] malformed ref aborts the queue — Implemented.** In `stale_evidence_refusal`, `git()` now catches `OSError`/`ValueError` from the launch and returns rc 125, so the check returns `stale-check-unavailable: target.ref '…' does not resolve…` (the ref is now quoted with `!r`) and the row parks before any lease. Clone probe (your script, retained as `TESTS-RESULTS/2026-11-27+GH-1664/final-qa-r1/probe1-nul-ref.sh`): before the fix (b4a7b4b76 `jog_run.py`) → exit 1, `ValueError: embedded null byte` (`probe1-before.out`); after (fc02e445d) → exit 0.
- **[Should] supervised deadline — Implemented.** The Git calls go through the existing `_jog_process(…, deadline=…)`; the run loop passes its supervision `deadline`, while retry-build passes none, as before. At the deadline, `ContractError` is raised before any lease, the same pattern as Preflight. Clone probe (`probe2-deadline.sh`) → exit 0, `elapsed=1.11s reason='supervision deadline reached; owned process group stopped; result requires recovery'`.
- **[Should] G12 red — Implemented.** `suite/red-base-g12-only-cut.log`: the base run, with only the G12 part and the remote reachable, fails G12 because the row is leased (0→1) and dispatched. The cut is recorded in provenance.
- Green after fixes: `suite/green-full-fc02e445d.log` → 244 pass, 0 fail. Provenance was appended with sha256 for each new file.

Reviewer: round 2. Please include literal `VERDICT:` and `Basis:` lines.

### Reviewer · Round 2 (codex)

swept file: yes

- **[Should] Use Preflight's heading detection for the admission check.** Observed input: the seeded packet with the heading preceded by “Preparation notes” and U+2028 LINE SEPARATOR. Preflight's `splitlines()` recognizes the heading and parses the stamp (`utils/py/swarm_preflight.py:96–114,132–153`). Jog's whole-text `re.MULTILINE` precheck skips that same capture (`utils/py/jog_run.py:1761–1774`). The controlled probe below changes only the separator and exits 1. With LF it prints `separator=0x000a stamp=aaaaaaaaaaaa calls=5` and names `utils/py/jog_run.py` in `stale-evidence:`. With U+2028 it prints `separator=0x2028 stamp=aaaaaaaaaaaa calls=0 reason=None`, then `AssertionError: None`. Affected scope: stamped captures Preflight accepts when a heading starts after a separator recognized by `str.splitlines()` but absent from Python's multiline anchors. A `None` return leaves both callers free to acquire a lease (`utils/py/jog_run.py:1114–1121,3161–3177`). Falsifier: the same probe should name the changed path with either separator, while existing no-contract and legacy handling stays intact. Reuse the parser's heading detection so the two checks consume the same line boundaries.

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 -B - <<'PY'
import io, json, subprocess, sys
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0, "utils/py")
import jog_run, swarm_preflight

doc = Path("PROJECT/2-WORKING/GH-1664-STALE-EVIDENCE-ADMISSION.md")
packet = swarm_preflight.extract_contract(str(doc))
a, b = "a" * 40, "b" * 40
packet["prepared_commit"] = a
packet["artifacts"] = ["utils/py/jog_run.py"]
body = "## Swarm Preflight Contract\n```json\n" + json.dumps(packet) + "\n```\n"
def fake_process(argv, **kwargs):
    args = argv[3:]
    if args[0] == "fetch":
        out, rc = "", 0
    elif args[0] == "rev-parse":
        out, rc = (a if args[-1].startswith(a) else b) + "\n", 0
    elif args[0] == "config":
        out, rc = "", 1
    else:
        assert args[0] == "diff" and ":(literal)utils/py/jog_run.py" in args, args
        out, rc = "utils/py/jog_run.py\n", 0
    return subprocess.CompletedProcess(argv, rc, out, "")

for sep in ("\n", "\u2028"):
    markdown = "Preparation notes" + sep + body
    with patch.object(jog_run, "_admission_captures", return_value=[str(doc)]), \
         patch.object(Path, "read_text", return_value=markdown), \
         patch.object(swarm_preflight, "open", lambda *a, **k: io.StringIO(markdown), create=True), \
         patch.object(jog_run, "_jog_process", side_effect=fake_process) as process:
        parsed = swarm_preflight.extract_contract(str(doc))["prepared_commit"]
        reason = jog_run.stale_evidence_refusal(".", 1664)
        print(f"separator={ord(sep):#06x} stamp={parsed[:12]} calls={process.call_count} reason={reason!r}")
        assert reason and reason.startswith("stale-evidence:"), reason
PY
```

- **[Pass] Round 1 malformed-ref and deadline findings are closed.** The NUL-ref probe from Round 1 (`python3 -B -`, using the retained `probe1-nul-ref.sh` Python body with `print(repr(reason))` before the assertion) passed locally with `"stale-check-unavailable: target.ref 'development\\x00' does not resolve in ."`, whereas the retained before output ends with `ValueError: embedded null byte` (`TESTS-RESULTS/2026-11-27+GH-1664/final-qa-r1/probe1-before.out:41`). Jog now maps launch errors to completed failures (`utils/py/jog_run.py:1754–1759,1791–1795`). Supervised run forwards its deadline before the lease (`:3161–3177`), and the reused runner raises on timeout (`:2833–2848`). The exact retained clone probe (`TESTS-RESULTS/2026-11-27+GH-1664/final-qa-r1/probe2-deadline.sh:9–31`) sets a four-second child and one-second deadline. The clone result is exit 0 and `elapsed=1.11s` with the process-group stop reason (`final-qa-r1/probe2-after.out:1`, `provenance.jsonl:16`, relative to the evidence directory).
- **[Pass] Round 1 G12 behavioral evidence is closed.** The G12-only base cut reaches Preflight and dispatches with attempt 1, then reports `suite exit=1` (`TESTS-RESULTS/2026-11-27+GH-1664/suite/red-base-g12-only-cut.log:122,162–167`). The revision and cut are in `provenance.jsonl:13`. The post-fix suite instead refuses at B with no execution (`suite/green-full-fc02e445d.log:134–137`). The exact base invocation is absent from the provenance row.
- **[Pass] The ordinary fixture still witnesses all four acceptance cases.** G9 names the changed file, parks with the seeded attempt intact and records no execution. G10 preserves row identity and dispatches once after refresh, with the approved execution and artifact write. G4 covers unstamped dispatch (`TESTS-RESULTS/2026-11-27+GH-1664/suite/green-full-fc02e445d.log:105–110,122–137,248`). The inbox replay records refusal and retry at attempt 1 and one worker call at attempt 2 under the same ID (`replay/green-stale-evidence-run.log:4–10,35–45`). Base G9, G11, G12 and G13 and the replay reject the unfixed behavior (`provenance.jsonl:3,6–8,13`).
- **[Pass] Capture union, legacy behavior and scope on the ordinary path.** Union and hold handling remain shared, with holds evaluated first and simulation exempt (`utils/py/jog_run.py:1114–1121,1664–1678,1699–1732,3161–3177`). Legacy captures skip individually, with a notice and no new fetch on their behalf. The stamped path uses the execution root, strips artifacts, preserves probe spelling, and uses case-insensitive pathspecs when configured (`:1754–1759,1777–1816`; `TESTS-RESULTS/2026-11-27+GH-1664/icase-manual-check.txt:1–10`). The two callers still use the existing queue writer (`utils/py/jog_run.py:1114–1121,3164–3177`). G9–G13 live in the existing adapter suite (`test/gh280-jog-marathon-adapter.sh:727–847`), and the persisted rating matches the plan (`releases.sql:1072`, `PROJECT/2-WORKING/GH-1664-STALE-EVIDENCE-ADMISSION.md:280–287`). The documented retry-build limitation for inbox-only captures remains pre-existing (`skills/2-daily/jog/SKILL.md:168–176`, `utils/py/jog_run.py:1114–1125,3185–3197`). The bounded sweep found no additional pre-existing defect.
- **[Pass] Receipt hashes.** The Round 1 `python3 -B -c` SHA-256 command, run unchanged, exited 0 and printed `16 nonempty evidence files match provenance SHA-256` (`TESTS-RESULTS/2026-11-27+GH-1664/provenance.jsonl:1–16`).

VERDICT: FAIL
Basis: The three Round 1 behavioral findings are resolved. A stamped capture that Preflight accepts can still skip admission entirely because the heading checks disagree. The graph generation predates the seeded implementation and its trace call required unavailable approval, so the sweep cites the worktree source. This turn used read-only probes and retained clone results for the suite and deadline. Producer claude-a should align heading detection and return the passing probe and regression evidence.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
