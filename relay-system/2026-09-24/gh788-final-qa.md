# RELAY · GH-788 final QA — Python path with a space
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-24.
-->

NEXT: Producer
STATUS: Approved
ROUND: 3 / 3

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
6. **Commit only the relay file** (`relay(gh788-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `test/lib/pystub.py` (moved from utils/py/pystub.py in round 3; plus the full diff below)
- Diff: git diff 337813e0..a061be40 (branch fix/gh788-python-path-space). Plan: `PROJECT/2-WORKING/GH-788-PYTHON-PATH-SPACE.md`, approved in `relay-system/2026-09-24/gh788-plan-qa.md` (round 2).
- Changed files: `utils/py/pystub.py` (new); `test/gh788-python-path-space.sh` (new, registered in `validate.sh`); 6 stub writers (`test/gh492-roadmap-state-sweep.sh`, `test/gh648-l2-token-aftermath.sh`, `test/gh648-l4-285-revalidate.sh`, `test/gh648-l5-gh237-repro.sh`, `test/gh648-l6-muse-attribution.sh`, `test/gh666_agy_model_probe.py`); 7 command strings (`utils/py/fuzz_engine.py`, `utils/py/repro_synth.py`, `utils/py/gen4_campaign.py`); gen4 bash suites (`test/gh-gen4-phase3-fuzz-engine.sh`, `test/gh-gen4-phase4-repro-synth.sh`).
- Scope change vs the approved plan: a third form found in verification. The gen4 bash suites passed `--target "$PY …"` with an unquoted `PY=$(command -v python3)`. It is fixed with a shell-quoted `PYQ` and guarded by a third pattern (see the capture doc's "Implementation notes").
- Evidence (producer-run, spaced venv active: `sys.executable=/Users/…/Documents/GH Repos/rebalanceOS/.venv/bin/python3`, commit `a061be40`): `gh492`, `gh648-l2/l4/l5/l6`, `agy-turn`, `gh-gen4-phase3/4/5`, `gh788-python-path-space`, `gh610` — all rc=0. Before the fix, the first 9 were rc=1 on this machine and on pristine `development` `39c2ae6a`. Negative control: with the 13 site edits stashed, `gh788-python-path-space.sh` rc=1 and lists the sites.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-24
- Operational envelope: test fixtures and a local fuzz self-test in a developer CLI repo. Grade proportionately; a new framework, a gate preflight, or migrating gh610's working launcher are out of scope (plan non-goals).
- Definition of Done (the plan's Acceptance):
  1. Every `'#!' + sys.executable` stub writer and every unquoted-interpreter command string (Python f-string or bash `--target "$PY …"`) in `test/ utils/ relay-automation/ skills/` is fixed. None remain, and none were missed.
  2. `pystub.launcher()` is correct: valid sh and Python for ordinary and spaced paths, exact interpreter, works with an empty `PATH`, refuses paths it can't embed. Each site's behaviour is otherwise unchanged (the stub bodies and what the tests assert).
  3. `test/gh788-python-path-space.sh` proves it: runtime cases, a bare-shebang red control, `build_argv` round-trip with its red control, and a ratchet with planted red controls for all three patterns. A scan error fails; safe forms don't match; the only excluded file is the suite itself.
  4. The edits are surgical and DRY: one helper, no second system, no unrelated changes. `validate.sh` registration is present.
  5. The capture doc truthfully records the scope change, the evidence and the rating; the ledger row is `In progress` and rated `75/70/50/70`.
- Questions (cite `file:line`; read-only probes under `.relay-scratch/` allowed, no test runs):
  1. Search for any remaining form of the defect the ratchet can't see, e.g. `sys.executable` interpolated into a shell string by `.format`/`%`, `subprocess(..., shell=True)` with an interpreter path, or other bash `$PYTHON`-style variables fed to `--target`. Name each with `file:line`, or say none found and how you searched.
  2. Is excluding the suite itself (`:(exclude)test/gh788-python-path-space.sh`) the right, minimal carve-out? Could a real site hide there?
  3. Do the six edited stubs keep their original body semantics? (Some previously had the body start on the same line as the shebang's `\n`.)
  4. Is `PYQ` (built with `python3 -c 'print(shlex.quote(sys.executable))'`) the same interpreter the suites used before (`command -v python3`)?
  5. Pre-existing defects in the touched functions/files: name any, or state none found.

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
Basis: the spaced-path repair is targeted, but the helper's refusal contract has a measured hole, and the whole-file sweep found an existing destructive ordering defect in the touched campaign module. S1/S2 need producer dispositions before approval.
swept file: yes

Scope: read the complete helper, three Python modules, six stub-writer files, both gen4 shell suites and new regression suite; inspected the validate runner code and registry (some unrelated registry commentary omitted). Read the capture and GH-788 SQL row. No Git command, suite, pytest or executable fixture was run. Historical diff/body byte-equivalence was not independently established because Git is forbidden this turn. MCP has no project for this worktree; nearest XYZ-forge coverage generation is 2026-09-01T15:54:30Z, with missing/not-tracked candidate paths and scope gaps. Findings use seeded source, not that stale graph.

- **[Should] S1 — reject carriage returns in interpreter paths.** utils/py/pystub.py:22 rejects LF but accepts CR, then line 24 embeds it in a single-line Python string. The probe below returned a header that fails compilation with SyntaxError: unterminated string literal. This contradicts the refusal promise at utils/py/pystub.py:18. Fix: include CR in the existing rejected-character set and refusal cases; no new quoting framework.
  Observed input: launcher("/tmp/py\rpath/python3"), where the Python escape denotes one carriage return.
  Affected scope: paths containing CR, legal in Unix filenames but treated as a newline by Python source parsing.
  Falsifier: this input must raise ValueError at the helper boundary; ordinary and spaced paths must still compile. A compilable current CR header would falsify the finding.

- **[Should] S2 — pre-existing: enforce the existing disjointness check before deletion/clone.** utils/py/gen4_campaign.py:90 creates directories, line 93 removes an existing clone, and line 94 clones, before lines 95–97 reject overlap. With repo=<base>/clone and sandbox_root=<base>, the deletion target is the source repository itself. The source-function probe intercepted every mutation and measured DELETE_SOURCE, CLONE_ATTEMPT, REFUSE, in that order; it deleted nothing and executed no Git. Fix: resolve/check the candidate paths before the first mutation, retaining ordinary disjoint-clone behavior. This is a pre-existing sweep finding, not caused by the quoting patch.
  Observed input: make_sandbox(repo=TMPDIR + "/example/clone", sandbox_root=TMPDIR + "/example"), with the existing-clone directory check true.
  Affected scope: candidate paths already rejected by the current equality/descendant predicate, especially an existing source checkout named clone.
  Falsifier: the intercepted overlapping call must refuse with zero mkdir/delete/subprocess calls; a disjoint candidate must still proceed. A current refusal before mutation would falsify the finding.

- **[Nit] N1 — separate temp directory leaks.** test/gh788-python-path-space.sh:22 uses tempfile.mkdtemp(dir="/tmp", ...) and never cleans it. The shared setup trap only removes WORK (test/_setup.sh:67); the Python block ignores its supplied WORK argument. Use TemporaryDirectory(dir="/tmp", ...) around the block to preserve the space-free ordinary-path control and clean up after every run.

- **[Pass] Syntax/quoting seam.** utils/py/pystub.py:24 emits shell exec plus adjacent Python string literals; the probe below compiles ordinary and spaced headers. All seven Python sites quote the interpreter: utils/py/fuzz_engine.py:375, :381, :382, :390, :392; utils/py/repro_synth.py:199; utils/py/gen4_campaign.py:329. build_argv at utils/py/fuzz_engine.py:224 shlex-splits head/tail. An in-memory AST-extracted call with a quoted "/tmp/py with space/python3" returned ['/tmp/py with space/python3', 'tool.py', 'x y']; the unquoted control returned ['/tmp/py', 'with', 'space/python3', 'tool.py', 'x y'] (python3 stdin probe, rc=0). Exact execution/empty-PATH behavior remains a clone-run item.

- **[Pass] Current stub construction keeps the body on a new line.** test/gh492-roadmap-state-sweep.sh:26, test/gh648-l2-token-aftermath.sh:66, test/gh648-l4-285-revalidate.sh:50, test/gh648-l5-gh237-repro.sh:36, test/gh648-l6-muse-attribution.sh:34 and test/gh666_agy_model_probe.py:33 prepend the helper, whose return at utils/py/pystub.py:24 ends with a newline. Immediate-import and leading-newline bodies both remain valid constructions. Each caller sets the utils/py import path. Historical byte-equivalence/runtime assertions are not claimed.

- **[Pass] Ratchet structure and registration.** test/gh788-python-path-space.sh:97 excludes only itself; its planted bad forms are at lines 105/108/111. Lines 98–102 distinguish no-match from scan-error, and lines 105–116 supply three red-form controls and safe forms. A real new site could hide in this excluded file, but its current bad forms are deliberate controls: the carve-out is reasonable. The guard covers three spellings, not every possible command construction. validate.sh:140 registers the suite.

- **[Pass] PYQ selects the running Python, not necessarily the lexical command-v path.** Both shell suites define PYQ at line 25 with shlex.quote(sys.executable). Commands "command -v python3" and "python3 -c 'import sys; print(sys.executable)'" returned /opt/homebrew/bin/python3 and /opt/homebrew/opt/python@3.14/bin/python3.14. Command "python3 -c 'import os,shutil,sys; print(os.path.samefile(shutil.which(\"python3\"),sys.executable))'" returned True (all rc=0). These paths identify the same binary here. With a wrapper/shim, sys.executable names the Python launched by it; that matches the suites' own python3 invocations.

- **[Pass] Scope/rating recorded.** The capture's Implementation notes documents the third Bash form and self-exclusion. releases.sql:726 places GH-788 in In progress with this capture and 75/70/50/70. Its Status/Acceptance leave full gate and final QA pending. The Setup's producer-run rc claims were not independently reproduced.

- **[Unverified — bounded search, not exhaustive proof] Alternate forms.** Command "rg -n 'sys\.executable' test utils relay-automation skills" returned 100 lines (rc=0); inspected every hit. Also searched "shell\s*=\s*True|--target.*\$|from sys import executable|sys[.]executable.*(format|%)" over the same roots (rc=0). No additional unquoted interpreter construction was found among these results: remaining hits are argv-list/execv uses, corrected quoting, or deliberate controls. The other variable fuzz target quotes its Bash script (test/gh460-fuzz-resolver-smoke.sh:57). This is not dataflow-complete proof of "none missed." Related pre-existing limitation: phase3 still leaves WORK/tool.py, noisy.py and twin.py unquoted inside target strings (test/gh-gen4-phase3-fuzz-engine.sh:55, :83, :99, :112, :115), so a spaced TMPDIR remains unsupported there; distinct from the interpreter repair.

- **[Unverified — needs clone run]** New-suite runtime/red controls, affected-suite regressions, tracked-file ratchet execution and final gate. No additional pre-existing defects were established beyond S2 and the phase3 TMPDIR limitation above. Run the authorized disposable-clone gate after dispositions/fixes; source inspection is not a green gate.

S1/S2 decisive probe (rc=0; every mutation/child-process boundary intercepted):

~~~bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
PYTHONPATH="$PWD/utils/py" python3 - <<'PROBE'
import ast, os, pathlib, shutil, subprocess
from typing import Optional, Tuple
from unittest.mock import patch
import pystub
for p in ("/tmp/plain/python3", "/tmp/py with space/python3", "/tmp/py\rpath/python3"):
    try:
        compile(pystub.launcher(p) + "pass\n", "<header>", "exec")
        print(repr(p), "compiles")
    except Exception as e:
        print(repr(p), type(e).__name__, str(e))
node = next(n for n in ast.parse(pathlib.Path("utils/py/gen4_campaign.py").read_text()).body
            if isinstance(n, ast.FunctionDef) and n.name == "make_sandbox")
exec(compile(ast.Module(body=[node], type_ignores=[]), "<source-function>", "exec"))
base = os.path.join(os.environ["TMPDIR"], "example")
repo = os.path.join(base, "clone")
events = []
with patch.object(os, "makedirs"), patch.object(os.path, "isdir", return_value=True), \
     patch.object(shutil, "rmtree", side_effect=lambda p: events.append("DELETE_SOURCE" if p == repo else p)), \
     patch.object(subprocess, "run", side_effect=lambda *a, **k: events.append("CLONE_ATTEMPT")):
    try:
        make_sandbox(repo, base)
    except RuntimeError:
        events.append("REFUSE")
print(events)
PROBE
~~~

Decisive output:
~~~text
'/tmp/plain/python3' compiles
'/tmp/py with space/python3' compiles
'/tmp/py\rpath/python3' SyntaxError unterminated string literal (detected at line 2) (<header>, line 2)
['DELETE_SOURCE', 'CLONE_ATTEMPT', 'REFUSE']
~~~

Handing off to Producer (claude-a) — disposition S1/S2 and N1, make the bounded corrections, and return for Round 2.

### Producer · Round 1 → 2 (claude-a)

**Dispositions**
- **[Should] S1 — CR accepted → Implemented.** `utils/py/pystub.py:22` now refuses `\r` along with `'`, `\\`, `\n` and the empty string. `test/gh788-python-path-space.sh` checks refusal for all four (quote, CR, backslash, empty) in one assertion: `PASS: launcher refuses paths it cannot embed (quote, CR, backslash, empty)`. Your input `"/tmp/py\rpath/python3"` now raises `ValueError`, and the ordinary and spaced cases still compile and run.
- **[Should] S2 — pre-existing delete-before-check in `gen4_campaign.make_sandbox` → Deferred, filed as https://github.com/HiQS-Labs/XYZ-forge/issues/792.** Confirmed from source (`utils/py/gen4_campaign.py:90–97`: `rmtree` and `clone` before the disjointness check). It is a real data-loss path, but unrelated to #788's interpreter quoting (the only #788 edit in this file is the quoted target at `:329`). It needs its own red control on mutation order. #792 carries your probe, the exact fix and the acceptance criteria.
- **[Nit] N1 — temp dir leak → Implemented.** `tempfile.TemporaryDirectory(dir="/tmp", …)` replaces `mkdtemp`. A re-run leaves the `/tmp/gh788.*` count unchanged (before=after), and earlier leftovers were removed.
- **Noted limitation (phase3 spaced `TMPDIR`) → recorded as a non-goal** in the capture doc: the input is different (the temp root, not the interpreter).
- **[Pass] items / bounded search** — no change.

**Verification:** `bash test/gh788-python-path-space.sh` → `11 pass, 0 fail` with the spaced venv active. Only `pystub.py` and the suite changed since the 11-suite run at `a061be40`. The full gate runs once, on the approved commit, in a disposable clone.

**Round 2 ask:** confirm S1/N1 and accept or contest the S2 deferral to #792.

### Reviewer · Round 2 · codex

VERDICT: PASS
Basis: S1 is corrected with a measured red control; N1 uses automatic cleanup; S2's separate tracking is accepted for this bounded interpreter-quoting repair. This approves the source review, not the outstanding disposable-clone gate.
swept file: yes

Scope: read the complete current `utils/py/pystub.py` and `test/gh788-python-path-space.sh`, the capture doc, and the S2 function. Round 1's broader whole-file sweep remains the baseline; attempted bulk re-reads of the other files were output-truncated, so no fresh exhaustive sweep of those files is claimed. No additional pre-existing defect was established. No Git command, suite, pytest or executable fixture was run. Graph project listing (both pages) contains no project for this worktree; nearest XYZ-forge coverage is generation 2026-09-01T15:54:30Z, with missing/not-tracked evidence paths. Current source is the evidence.

- **[Pass] S1 resolved.** `utils/py/pystub.py:22` rejects CR and LF alongside quote, backslash and empty input. The non-mutating probe below returned rc=0: ordinary/spaced headers compile, all five invalid inputs are refused, and removing CR rejection in memory restores the SyntaxError. The committed refusal case is at `test/gh788-python-path-space.sh:55`; runtime execution remains for the clone gate.
- **[Pass] N1 resolved by inspection.** `test/gh788-python-path-space.sh:22` retains a `TemporaryDirectory` object for the lifetime of the Python block (`work = _tmp.name` at :23), replacing the unowned allocation. Its normal interpreter-shutdown finalizer provides cleanup. The producer's before/after directory-count measurement was not independently repeated.
- **[Should — deferred, accepted] S2 remains real and unfixed.** `utils/py/gen4_campaign.py:93` still deletes before :95–97 validate disjointness. Accept separate remediation because this is pre-existing and independent of the quoting change, with the exact observed input and mutation-order acceptance now recorded in open [GH-792](https://github.com/HiQS-Labs/XYZ-forge/issues/792). Read-only command `gh issue view 792 --repo HiQS-Labs/XYZ-forge --json number,title,state,body` returned rc=0, `"number":792,"state":"OPEN"`, and acceptance: “The overlapping call refuses with zero `makedirs`/`rmtree`/`subprocess` calls”; the disjoint control is also present. This disposition does not certify overlapping sandbox inputs as safe or resolve #792.
- **[Unverified — needs clone run]** Final runtime/regression/ratchet gate remains outstanding, as the capture's Acceptance and this turn's restrictions require. Carry forward Round 1's bounded-search and historical-diff limitations; no new assertion that all possible alternate constructions were exhaustively ruled out. The source review has no remaining required #788 correction.

S1 probe command (rc=0; no subprocesses, fixture execution or source mutation):

~~~bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
PYTHONPATH="$PWD/utils/py" python3 - <<'PROBE'
import pathlib,pystub
for p in ('/tmp/plain/python3','/tmp/py with space/python3'):
    compile(pystub.launcher(p)+'pass\n','<header>','exec')
    print(repr(p),'compiles')
for p in ('/tmp/py\rpath/python3','/tmp/py\npath/python3',"/tmp/it's/python3",'/tmp/py\\path/python3',''):
    try: pystub.launcher(p)
    except ValueError: print(repr(p),'refused')
    else: raise AssertionError(p)
s=pathlib.Path('utils/py/pystub.py').read_text()
ns={}; exec(compile(s.replace('\\r',''),'<CR-guard-removed>','exec'),ns)
try: compile(ns['launcher']('/tmp/py\rpath/python3')+'pass\n','<mutant>','exec')
except SyntaxError: print('CR guard removed: SyntaxError (red control)')
else: raise AssertionError('mutation did not fail')
PROBE
~~~

Decisive output:
~~~text
'/tmp/plain/python3' compiles
'/tmp/py with space/python3' compiles
'/tmp/py\rpath/python3' refused
'/tmp/py\npath/python3' refused
"/tmp/it's/python3" refused
'/tmp/py\\path/python3' refused
'' refused
CR guard removed: SyntaxError (red control)
~~~

Relay closed (Approved), no further review turn needed. Handing completion to claude-a for the authorized disposable-clone gate; the harness owns the relay-file commit.


### Attestation · relay-drive — 2026-09-24T20:49:51Z
task: RELAY-gh788-final-qa
reviewer: codex
status: Approved
reviewed-head: b6158c9d8b3edd43e9ea4d38217b4fd16eb4539f
added-range: 19763+4221
added-sha256: 13fec94835cae70fa2c96e45267f9481085b80147ccf1a2d531ff9b7cdb7e052
### Producer · Round 2 → 3 (claude-a) — post-approval change, re-review required

Your round-2 approval was for `b6158c9d`. The one full gate on that commit (disposable clone, spaced venv active, 413/420 passed; identity unchanged before and after) found **5 failures caused by this branch**. They are fixed in `32492b8a`, so the approval is stale and this round reviews the delta `b6158c9d..32492b8a`:

1. **GH-777 inventory ratchet** (`utils/pdda/check_inventory_ratchet.py`) forbids any new script under `utils/`, `scripts/` or `bin/`, and baseline updates cannot approve growth. → `git mv utils/py/pystub.py test/lib/pystub.py` (`test` is in `PRUNED_DIRS`). The six sites now insert `test/lib` on `sys.path` before `import pystub`: gh648 ×4 via `os.environ["GH648_ROOT"]` (each already imports `os` earlier and receives `GH648_ROOT`), gh666 via `Path(__file__).resolve().parent / "lib"`, gh492 via `Path(sys.argv[1]) / 'test' / 'lib'`. The suite's `PYTHONPATH` gains `test/lib`.
2. **gh139-pipe-grep-guard / gh460-pipe-buffer-sigpipe** flagged `printf '%s\n' "$out" | grep -q …` in the suite. → `grep -q '^PASS: build_argv' <<<"$out"`.
3. **sentinel-overlay / pdda-repo-contract**: the capture doc lacked the `goal:` frontmatter that `2-WORKING` requires. → Added.

**Not this branch:** `gh777` (on `utils/py/work_connectors/github_labels.py`, from `e4d7c17d`/GH-646), `gh674` (`No module named merge_cleanup`) and `gh436` (`test_unknown_mergeable_settles_and_the_pr_lands`) fail identically on pristine `development` `337813e0`. Ratchet output on development: `inventory_ratchet: ERROR: NEW script added (utils/py/work_connectors/github_labels.py)`.

**Verification at `32492b8a`, spaced venv:** rc=0 for `gh788-python-path-space`, `gh139`, `gh460`, `pdda-repo-contract`, `sentinel-overlay`, and all nine originally affected suites. `gh777` now fails only on `github_labels.py`, the same as `development`.

**Round 3 (final) ask:** review only the delta. Confirm the move keeps the helper out of every ratchet scope; the new `sys.path` lines resolve correctly in each site (including gh648's env-var route); no stub behaviour changed; and the doc's claims are accurate. The full gate runs once more on your approved commit.


### Reviewer · Round 3 · codex

VERDICT: PASS
Basis: the helper relocation, six import routes, here-string correction and goal frontmatter are sound by source review. One stale plan-path nit is non-blocking. This approves review; the final disposable-clone gate remains outstanding.
swept file: yes

Scope: read the complete relocated helper, regression suite, six stub-writer files, capture doc and inventory ratchet. Round 1/2 remain the baseline for the unchanged broader patch. No additional pre-existing defect was established in this sweep; the accepted GH-792 deferral remains unresolved. No Git command, test suite, pytest or executable fixture was run. Historical byte-for-byte diff/body equivalence and producer runtime receipts were not independently established. Graph listing across both pages has no project for this worktree; nearest XYZ-forge coverage generation is 2026-09-01T15:54:30Z with missing/not-tracked evidence paths, so current source is the evidence.

- **[Pass] Move clears both GH-777 inventory categories.** `utils/pdda/check_inventory_ratchet.py:52` scans scripts only below utils/scripts/bin; `:26–40` includes test in PRUNED_DIRS, applied to SQLite scanning at `:72`. Thus `test/lib/pystub.py` is outside both categories. This does not mean outside every repository ratchet: GH-788 deliberately still scans test at `test/gh788-python-path-space.sh:101`. No inventory baseline relaxation is needed.
- **[Pass] All six import routes resolve to the relocated helper.** gh492 passes its absolute root as argv[1] at `test/gh492-roadmap-state-sweep.sh:4–6`, inserts test/lib at `:15`; gh648 l2 exports GH648_ROOT at `:7` before insertion at `:13`; l4/l5/l6 supply the variable on their Python invocation at `:6/:6/:5` and insert at `:17/:13/:13`, after importing os. `test/gh666_agy_model_probe.py:14` derives lib from its own file. The path-only probe below resolves all six and observes the old helper absent (rc=0). The regression suite includes both test/lib and utils/py in PYTHONPATH at `:18`.
- **[Pass] Body construction remains valid by inspection.** `test/lib/pystub.py:24` ends its header with a newline; the body concatenations remain at gh492 `:26`, gh648 l2/l4/l5/l6 `:67/:51/:37/:35`, gh666 `:34`. The relocation introduces no fixture import into generated stub bodies. Exact historical equivalence is not claimed without the forbidden Git comparison.
- **[Pass] Gate fixes are narrowly implemented.** `test/gh788-python-path-space.sh:87` now reads the captured output with a here-string, eliminating the producer-side pipe/SIGPIPE seam while retaining the missing-runtime-output failure. The capture's `goal: >` at `PROJECT/2-WORKING/GH-788-PYTHON-PATH-SPACE.md:10` is nonempty and describes the implemented behavior.
- **[Nit] Stale plan import path.** Capture `:92` still says gh492 inserts `argv[1]/utils/py`; its implementation notes at `:125–126` and source use test/lib. At doc closeout, change that plan parenthetical to `argv[1]/test/lib`. The implementation notes already explain the change, so this does not block source approval.
- **[Unverified — needs clone run]** Producer-reported 413/420, attribution to baseline failures, focused rerun rcs and the final full gate were not independently reproduced here. Capture Acceptance correctly leaves final gates unchecked; the implementation-note results remain producer attestations. Run the authorized disposable-clone gate on the final state. Carry forward earlier bounded alternate-form search limitations.

Path-only probe command (rc=0; evaluates only import-path expressions, never imports or executes a fixture):

~~~bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PROBE'
import ast, importlib.machinery, os, pathlib, sys
root=pathlib.Path.cwd()
files=['test/gh492-roadmap-state-sweep.sh','test/gh648-l2-token-aftermath.sh','test/gh648-l4-285-revalidate.sh','test/gh648-l5-gh237-repro.sh','test/gh648-l6-muse-attribution.sh','test/gh666_agy_model_probe.py']
for f in files:
    line=next(x for x in (root/f).read_text().splitlines() if x.startswith('sys.path.insert') and ('lib' in x or 'GH648_ROOT' in x))
    expr=ast.parse(line).body[0].value.args[1]
    class Context:
        argv=['-',str(root)]
    class Env:
        environ={'GH648_ROOT':str(root)}
        path=os.path
    path=eval(compile(ast.Expression(expr),'<path-only>','eval'),{'os':Env,'sys':Context,'Path':pathlib.Path,'__file__':str(root/f)})
    spec=importlib.machinery.PathFinder.find_spec('pystub',[path])
    assert spec and pathlib.Path(spec.origin)==root/'test/lib/pystub.py'
    print(f+': resolves test/lib/pystub.py')
assert not (root/'utils/py/pystub.py').exists()
print('old helper absent')
PROBE
~~~

Decisive output:
~~~text
test/gh492-roadmap-state-sweep.sh: resolves test/lib/pystub.py
test/gh648-l2-token-aftermath.sh: resolves test/lib/pystub.py
test/gh648-l4-285-revalidate.sh: resolves test/lib/pystub.py
test/gh648-l5-gh237-repro.sh: resolves test/lib/pystub.py
test/gh648-l6-muse-attribution.sh: resolves test/lib/pystub.py
test/gh666_agy_model_probe.py: resolves test/lib/pystub.py
old helper absent
~~~

Relay closed (Approved), no further review turn needed. Handing completion to claude-a for the disposable-clone gate and documentation closeout; the harness owns the relay-file commit.


### Attestation · relay-drive — 2026-09-24T21:30:48Z
task: RELAY-gh788-final-qa-r3
reviewer: codex
status: Approved
reviewed-head: 80dd318f3a7559970df6cc207c38d432cd66a7db
added-range: 26546+5359
added-sha256: 3de9fa24f78377fa60070c494525a2c0541e0ba4ccb885a029faed004c9c5240
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
