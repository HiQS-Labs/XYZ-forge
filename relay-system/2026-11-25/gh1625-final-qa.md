# RELAY · GH-1625 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
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
6. **Manual relay: commit only the relay file** (`relay(gh-1625-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the branch diff `git diff 7f2f1cce5..HEAD` — implementation
  `test/gh436-merge-cleanup.py` (commit `ada4644db`, +17 lines at the top), plan
  `PROJECT/2-WORKING/GH-1625-SUITE-TEMP-ISOLATION.md` (Approved in `relay-system/2026-11-25/gh1625-plan-qa.md`),
  evidence `TESTS-RESULTS/2026-11-25+GH-1625/` (README, provenance.jsonl, two summaries), ledger
  `releases.db`/`releases.sql` (pickup + accepted-start for GH-1625).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-25
- Definition of Done: issue https://github.com/HiQS-Labs/XYZ-forge/issues/1625 is satisfied as the
  Approved plan scopes it: the merge-cleanup unit suite (gate entry `test/gh436-merge-cleanup.sh` →
  `test/gh436-merge-cleanup.py`, which imports `gh534_phase_a/b/c_tests`) no longer leaves
  `merge-cleanup-*`/`merge-check-*` folders in the inherited temp dir and no longer runs
  `prune_retained_scratch` over it; the per-run dir is removed at exit; no new tests (GH-831).
- Operational envelope: local developer test suite, single repo. Commensurate complexity: a 17-line
  change to one existing test module. The plan's non-goals stand (no production `merge_cleanup.py`
  changes — that is #1626 / #1578; no isolation for standalone phase-module runs; no shared fixture lib).
- Not yet run, by design: the classified gate (A2, `bash test/gh436-merge-cleanup.sh` via the push-time
  hook in a disposable full clone) runs after this review on the approved commit. A smoke of the wrapper
  entry is part of that gate.

Questions:
1. Does `test/gh436-merge-cleanup.py:18-36` (new block) match the Approved plan: created before
   `scan_clones`/`merge_cleanup` and the phase modules import; `TMPDIR` and `tempfile.tempdir = None` set;
   atexit removal guarded to the exact captured path, prefix and parent? Any path where `gettempdir()` was
   already cached before line 18 (e.g. by a stdlib import) so the reset is needed — and is it sufficient?
2. Is anything in the suite or the phase modules computed from the temp dir at import time *before* the
   block (it is placed after only stdlib imports)?
3. Does the evidence in `TESTS-RESULTS/2026-11-25+GH-1625/` substantiate each A1 check (a)-(d), and does
   the before run (`7f2f1cce5`) show the defect so that an unchanged, unfixed suite could not be reported
   delivered? Is the README's caveat about the forced pruning pass accurate?
4. Is the PRS rating still grounded given the before run removed 5/5 planted tool-shaped folders
   (forced passes)? Plan rationale: `PROJECT/2-WORKING/GH-1625-SUITE-TEMP-ISOLATION.md` "Rating".
5. Any accidental files, a new test file or registry entry, or a duplicate mechanism in the diff?

Cite `file:line` for every claim. Set STATUS to Approved if it passes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

swept file: yes

VERDICT: FAIL

Basis: A1 substantiates the merge landing/check scratch fix. The whole-file sweep found two pre-existing fixture writes that still bypass the suite temp root. The A2 wrapper result is also outstanding.

- [Should] Move the two hard-coded fixture roots inside the suite temp directory. **Observed input:** `test/gh436-merge-cleanup.py:21-35` promises a private temp directory for the whole suite and cleans only that directory. The existing boundary test at `test/gh436-merge-cleanup.py:79-105` creates `/tmp/test_safe_root/repo_clone` and `/tmp/outside_repo` with `mkdir` and never removes either root. These absolute paths bypass both the suite root and A1's sealed parent, so A1 would pass while the test still leaves shared entries. Read-only AST probe, exit 1:
  ```sh
  python3 - <<'PY'
  import ast
  from pathlib import Path
  path = Path("test/gh436-merge-cleanup.py")
  tree = ast.parse(path.read_text())
  case = next(n for n in tree.body if isinstance(n, ast.ClassDef) and n.name == "TestMergeCleanupSafety")
  case = next(n for n in case.body if n.name == "test_safe_deletable_path_boundaries")
  roots = []
  for node in case.body:
      if isinstance(node, ast.Assign) and isinstance(node.value, ast.Call) and isinstance(node.value.func, ast.Name) and node.value.func.id == "Path":
          root = Path(ast.literal_eval(node.value.args[0]))
          if root.is_absolute():
              roots.append(root)
              print(f"{path}:{node.lineno} {root}")
  assert not roots, "fixture roots bypass the suite temp directory"
  PY
  ```
  Decisive output: `test/gh436-merge-cleanup.py:80 /tmp/test_safe_root`, `test/gh436-merge-cleanup.py:101 /tmp/outside_repo`, and `AssertionError: fixture roots bypass the suite temp directory`. **Affected scope:** the existing boundary case on both direct and registered wrapper runs. **Falsifier:** all mkdir targets in that case resolve under one suite-owned temporary parent, with the allowed child inside the safe root and the rejected candidate its sibling outside the safe root. Use the existing case with a `TemporaryDirectory` parent and reference its `safe_root` in `never_delete`. No new case is needed.
- [Pass] The bootstrap is before `scan_clones`, `merge_cleanup`, and the phase modules (`test/gh436-merge-cleanup.py:10-41,56,1397-1401`). The atexit registration takes no arguments, so removal uses the captured child and parent defaults and tests the parent, prefix and directory type (`:24-35`). The reset is needed because the bootstrap's own `gettempdir()` populates the cache before the environment change. The isolated stdlib probe below exited 0 and printed `None`, `True`, `True`, `True` in order.
  ```sh
  python3 -c 'import json, os, sys, tempfile, subprocess, shutil, unittest, unittest.mock, atexit; from pathlib import Path; print("after stdlib imports:", repr(tempfile.tempdir)); inherited = tempfile.gettempdir(); print("after gettempdir:", tempfile.tempdir == inherited); os.environ["TMPDIR"] = str(Path(inherited).parent); print("without reset still inherited:", tempfile.gettempdir() == inherited); tempfile.tempdir = None; print("after reset:", tempfile.gettempdir() == os.environ["TMPDIR"])'
  ```
  The wrapper execs the same Python file (`test/gh436-merge-cleanup.sh:8-11`). Default temp lookup reaches the production allocations and listing (`skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:396-406,432-445,2025,2531-2545`). The phase modules load after setup and their relevant child paths inherit or copy the environment (`test/gh534_phase_a_tests.py:25-36,303-306`, `test/gh534_phase_b_tests.py:23-32,40-42,145,397`, `test/gh534_phase_c_tests.py:20-36,95-99,190-193,405-406,884-887`).
- [Pass] A1 meets checks (a)-(d) in `PROJECT/2-WORKING/GH-1625-SUITE-TEMP-ISOLATION.md:93-118`. The receipts show 36→0 new merge scratch entries, zero suite roots left after exit, a nonempty trace changing from 138 inherited-root listings to 138 suite-root listings, all five planted folders intact in the patched run, and 227 tests `OK` on both revisions. The base fails the patched acceptance predicates despite its suite exit 0. See `TESTS-RESULTS/2026-11-25+GH-1625/a1-before-summary.txt:1-10`, `a1-after-summary.txt:1-10`, and `provenance.jsonl:1-2` in the same directory.
- [Nit] Tighten the frequency claim in `TESTS-RESULTS/2026-11-25+GH-1625/README.md:18-21`. The forced probe shows deletion of five synthetic plants. The unforced recon shows one listing pass and five surviving plants (`PROJECT/2-WORKING/GH-1625-SUITE-TEMP-ISOLATION.md:44-56`). The 66 skips establish fewer listing passes in that recon. Replace the deletion-frequency statement with those observations. The rating remains grounded at 45/45/50/85 because the forced run establishes a deletion path for tool-shaped directories while loss of real unpushed work remains unobserved. The scope and cost remain one existing suite (`PROJECT/2-WORKING/GH-1625-SUITE-TEMP-ISOLATION.md:132-138`, `releases.sql:1062,6114-6115`).
- [Pass] Read-only commit-tree and suite-blob comparison of `7f2f1cce57a065d801905e97aeb28b8a9c49a800..4b32c20e5ad5fd31caf8ef619c6f5137a67b886c` exited 0. The only code delta was the 17-line setup in `test/gh436-merge-cleanup.py:18-36`. The ten changed paths were that suite, the working plan, the two relay transcripts, the four A1 evidence files, and both ledger files. The existing registry entry remains at `validate.sh:96`. No additional suite, registry entry, or parallel fixture mechanism appeared in the comparison.

[Unverified — needs clone run] A2 is the uninstrumented `bash test/gh436-merge-cleanup.sh` check in a disposable full clone (`PROJECT/2-WORKING/GH-1625-SUITE-TEMP-ISOLATION.md:115`). The setup records it as pending (`relay-system/2026-11-25/gh1625-final-qa.md:90-92`). Return the actual command, exit status and test count for the revised changes. The scoped graph was from a separate checkout, so file citations use the seeded worktree.

Handing off to Producer (claude-a) to isolate the existing boundary fixture, correct the evidence wording, and supply the A2 result.

### Producer · Round 2 (claude-a)

- [Should] Hard-coded `/tmp` fixture roots — **Implemented** in `bbd6ba299`: `test_safe_deletable_path_boundaries`
  now builds `safe_root` and `outside` under `tempfile.mkdtemp(prefix="gh436-bounds-")` (inside the suite dir),
  references that `safe_root` in `never_delete`, and removes the base with `addCleanup` (`test/gh436-merge-cleanup.py:80-84,103`).
  Re-grep of the four modules for `"/tmp/` and `Path("/tmp`: only `test/gh436-merge-cleanup.py:1578`
  remains — `Path("/tmp")` passed as the `primary` argument to `finalize_sweep_inputs`, a value embedded in a
  command string that is only syntax-checked with `bash -n`; nothing is created there. Left as is.
  Both stale folders exist on the operator's Mac from an earlier run (`ls -ld` → mtime Nov 25 09:32).
- [Nit] Frequency wording — **Implemented**: README now states the forced run removed 5/5 synthetic plants,
  the unforced recon skipped 66/67 passes with one listing and all plants surviving, and real work loss was
  not observed.
- A2 — **Run** on `bbd6ba299` in disposable full clone `…-gate` (origin GitHub, no probe):
  `TMPDIR=<S> bash test/gh436-merge-cleanup.sh` → rc=0, `Ran 227 tests in 301.613s OK`, S empty after,
  `/tmp/test_safe_root` + `/tmp/outside_repo` mtimes unchanged, HEAD unchanged, bare=false, 0 dirty.
  Recorded in `TESTS-RESULTS/2026-11-25+GH-1625/provenance.jsonl` (row 3) and README "A2".

NEXT: Reviewer. Handing off to Reviewer (codex) for round 2.

### Reviewer · Round 2

swept file: yes

VERDICT: PASS

Basis: Both Round 1 findings are closed. The A1 red control and patched results meet the plan, and the recorded A2 wrapper run passed on the same suite source seeded here. The whole-file sweep found no other pre-existing defect affecting the reviewed isolation requirement.

- [Pass] Closed the shared boundary-fixture finding. Both candidates now descend from the private `gh436-bounds-` fixture and the test registers cleanup for that fixture. The allowed candidate stays inside `safe_root`, the rejected candidate is its sibling outside `safe_root`, and the original `NEVER_DELETE` and `SAFE_ROOTS` assertions remain (`test/gh436-merge-cleanup.py:79-107`). The remaining `/tmp` path literals in the suite are inputs to command generation and a Bash syntax check (`test/gh436-merge-cleanup.py:1572-1583`).
- [Pass] The direct and wrapper runs share one bootstrap before local imports and phase collection (`test/gh436-merge-cleanup.sh:8-11`, `test/gh436-merge-cleanup.py:10-41,56,1398-1403`). The bootstrap's own `gettempdir()` populates the cache before `TMPDIR` changes. Resetting it redirects the next default lookup, and the no-argument atexit callback operates on the captured child with the parent, name and directory checks (`test/gh436-merge-cleanup.py:24-35`, Round 1 stdlib probe at `relay-system/2026-11-25/gh1625-final-qa.md:148-152`). The production allocation and listing sites use those defaults (`skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:396-406,432-445,2025,2545`).
- [Pass] A1 meets (a)–(d) on the bootstrap revision. The before run left 36 matching entries and made 138/138 listings in S. The after run left zero matching entries and zero suite temp roots, made 138/138 listings in the private child, preserved all five planted trees by checksum, and matched the 227-test count with OK (`PROJECT/2-WORKING/GH-1625-SUITE-TEMP-ISOLATION.md:93-118`, `TESTS-RESULTS/2026-11-25+GH-1625/a1-before-summary.txt:1-10`, `TESTS-RESULTS/2026-11-25+GH-1625/a1-after-summary.txt:1-10`). The README now reports five synthetic deletions under the forced probe and five survivors under the unforced recon, with one listing and 66 skips. That evidence supports the existing 45/45/50/85 rating and its distinction between reachable deletion and observed harm (`TESTS-RESULTS/2026-11-25+GH-1625/README.md:18-22`, `PROJECT/2-WORKING/GH-1625-SUITE-TEMP-ISOLATION.md:44-57,132-138`, `releases.sql:1062,6114-6115`).
- [Pass] A2 is recorded as `TMPDIR=<S> bash test/gh436-merge-cleanup.sh` in the disposable full clone on `bbd6ba299`, exit 0, 227 tests OK, S empty and both old fixture directory mtimes unchanged (`TESTS-RESULTS/2026-11-25+GH-1625/provenance.jsonl:3`, `TESTS-RESULTS/2026-11-25+GH-1625/README.md:30-34`). The read-only comparison below exited 0. It printed four changed paths since Round 1, the existing suite, the relay, and the receipt README and provenance. The three paths changed after A2 were the relay and those two receipt files. It printed `seeded suite == A2 == HEAD: 6325d3df4c89e861d44f779a4535442e850e86d1`. Together with the Round 1 scope comparison (`relay-system/2026-11-25/gh1625-final-qa.md:155`), this shows a single modified suite, with the existing registry entry at `validate.sh:96`.
  ```sh
  python3 - <<'PY'
  from pathlib import Path
  from hashlib import sha1
  import zlib
  g = Path(Path(".git").read_text().strip().split(": ", 1)[1])
  def read(oid):
      return zlib.decompress((g.parent.parent/"objects"/oid[:2]/oid[2:]).read_bytes()).split(b"\0", 1)[1]
  def tree(commit):
      return read(commit).splitlines()[0].split()[1].decode()
  def entries(oid):
      result, data = {}, read(oid)
      while data:
          name, data = data.split(b"\0", 1)
          mode, name = name.decode().split(" ", 1)
          result[name] = (mode, data[:20].hex())
          data = data[20:]
      return result
  def changed(a, b, path=""):
      if a == b:
          return []
      left, right = entries(a), entries(b)
      result = []
      for name in sorted(left.keys() | right.keys()):
          x, y = left.get(name), right.get(name)
          if x != y:
              result += changed(x[1], y[1], path+name+"/") if x and y and x[0] == y[0] == "40000" else [path+name]
      return result
  head = (g/"HEAD").read_text().strip()
  gate = "bbd6ba2995f75d63d754e839811d8eb5a80387a6"
  prior = "4b32c20e5ad5fd31caf8ef619c6f5137a67b886c"
  suite = Path("test/gh436-merge-cleanup.py")
  for rev in (prior, gate):
      print(rev[:9], "to HEAD:", ", ".join(changed(tree(rev), tree(head))))
  data = suite.read_bytes()
  blob = sha1(f"blob {len(data)}\0".encode()+data).hexdigest()
  for rev in (head, gate):
      assert blob == entries(entries(tree(rev))["test"][1])[suite.name][1]
  print("seeded suite == A2 == HEAD:", blob)
  PY
  ```

The graph available for this turn covered a separate checkout. The call trace was unavailable under the approval policy, so the file citations use the seeded worktree. Runtime results are from the Producer's recorded runs.

Relay closed (Approved), no further relay turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
