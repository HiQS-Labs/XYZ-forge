# RELAY · GH-1195 plan QA: marathon-plan root leak — one-line anchor fix
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-24.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-1195-plan-qa-marathon-plan-root-leak-one-line-anchor-fix): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1195-PLANNER-ROOT-LEAK.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/1-INBOX/GH-1195-PLANNER-ROOT-LEAK.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-24
- Definition of Done: the plan in the artifact is approved when a reviewer confirms, against the live
  source paths, that (1) the root-cause claim is grounded: `utils/py/marathon_plan.py:112-114` calls
  `repo_root()` with no anchor, and `utils/py/harness_paths.py:31-60` prefers `XYZ_HARNESS` before this
  file's location; (2) the one-line fix `repo_root(anchor_file=__file__)` yields the clone root in a
  canonical checkout and the consumer root in a vendored `.xyz` layout (trace `harness_home(anchor_file=…)`
  and `repo_root`'s vendored branch); (3) `QUEUE_PLAN_ROOT` still overrides; (4) the verification list
  (two manual checks with a red control, smoke main + adjacent path, the four named existing suites) can
  detect the actual failure and would go red if the fix were reverted; (5) the rating 72/70/50/92 is
  grounded in the stated consequence and recurrence; (6) nothing in the plan adds a test, suite, second
  resolver or parallel write path.
- Operational envelope: this is a one-line fix to a planner's default root in a single-operator harness.
  Grade against the stated requirements (issue #1195 acceptance, GH-831 no new tests, GH-1001 vendored
  precedence) and commensurate complexity; do not require multi-tenant threat models, new abstractions,
  or changes to `harness_home()` precedence. Evidence of the bug: `TESTS-RESULTS/2026-10-24+GH-1195/`
  in the same tree (red control: the engine ran with this clone's `releases.db` absent and wrote its
  plan file into the PRIMARY clone).
- Source paths to read: `utils/py/marathon_plan.py`, `utils/py/harness_paths.py`, `utils/marathon-plan.sh`
  (lines 20-32, 84-102), `utils/py/_marathon_plan.py:805-820`, `utils/py/wave_reconcile.py:1664-1750`,
  `test/marathon-plan.sh` (QUEUE_PLAN_ROOT pins), `test/gh358-wave-reconcile-vendored-paths.sh`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

**Block — verification instructions need correction; the proposed one-line fix is sound.**

VERDICT: FAIL
Basis: the live resolver supports the fix, but Definition of Done (4) is not met as written: the recorded red exit differs from the asserted exit, and JSON cannot establish the clone identity claimed by the smoke check.

swept file: yes

Reviewed the entire seeded artifact, the entire Python CLI wrapper, resolver root/layout functions, Bash dispatch/root selection, engine DB selection/report rendering, reconciler call/result handling, and the named suites' relevant seams. No additional in-scope defects found beyond the findings below. Graph tools were unavailable; evidence is direct source inspection. Reversibility: Easy — the implementation changes one default-root call and leaves the existing override/writer intact.

- **[Should] R1 — correct and contain the red-control procedure** (artifact:58-59, 88-91). The artifact says the pre-fix invocation succeeds with exit 0, but its own receipt records planner **rc=4**, followed by a JSON parsing failure; the outer transcript's exit 0 is not the planner exit. It also records a write into the primary clone, so repeating the default write-mode command against the live primary is an avoidable repeat of the leak. Fix the plan to capture the planner status directly, distinguish successful ledger loading from a clean report, and use disposable clones plus `--dry-run` for the missing-DB control. Preserve the exact before/after diagnostic and nonempty output with committed `provenance.jsonl` in the already named evidence directory.
  Observed input: `TESTS-RESULTS/2026-10-24+GH-1195/before-fix-red-control.txt:5-9` contains `rc=4`, `wrote PROJECT/2-WORKING/MARATHON-PLAN-2026-10-24.md`, `JSONDecodeError: Extra data`, then outer `[exited with code 0]`; `before-fix-NOTE.md:2` explicitly identifies the primary write.
  Affected scope: the plan's manual check A and its factual description of that existing run; no runtime change beyond the proposed anchor.
  Falsifier: with the same releases-mode disposable ledger and missing local DB, reverted code must read the alternate clone (its actual status may be 0/4/5), while fixed code must exit 3 on the missing local DB. A fixed run that still reads the alternate clone disproves the fix. Both runs must leave the alternate clone's plan untouched.
  Inspection command: `cat TESTS-RESULTS/2026-10-24+GH-1195/before-fix-NOTE.md; cat TESTS-RESULTS/2026-10-24+GH-1195/before-fix-red-control.txt` (read as separate shell lines), exit 0; decisive spans quoted above. The existing receipts do not yet include `provenance.jsonl`; treat them as the supplied observation, not completed implementation attestation.

- **[Should] R2 — replace the smoke's unobservable root assertion** (artifact:95-102). JSON findings contain relative doc paths and an empty summary `file`, not a resolved root (`utils/py/_marathon_plan.py:1245,1251-1266`). Two equivalent ledgers in different clones can produce identical, nonempty JSON before the fix; equality with `QUEUE_PLAN_ROOT` set to the same clone does not by itself prove override precedence either. Keep the existing suites, but describe their boundary accurately: `test/marathon-plan.sh:49-61` pins the root, and the vendored suites replace the planner with stubs (`test/gh358-wave-reconcile-vendored-paths.sh:57`, `test/gh429-wave-reconcile-vendored-observe.sh:39`). They do not run the actual vendored planner.
  Observed input: the actual renderer, given the same relative finding and different `ROOT` values, emits identical JSON; the read-only probe below returned `nonempty = True` and `different roots produce identical JSON = True`.
  Affected scope: the main/adjacent smoke assertions and claims about existing suite coverage.
  Falsifier: in disposable clones with deliberately distinguishable ledger/doc content, an unpinned actual CLI run must select the candidate clone; an explicit override to a different disposable root must select that root. Reverting the anchor must fail the unpinned assertion. Use one existing manual receipt for a real vendored anchor/consumer-root observation, rather than attributing that coverage to the stub suites. No new test/suite or resolver is needed.
  Probe command (exit 0; no CLI, subprocess, or engine run):
  ```sh
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  PYTHONPATH=utils/py python3 - <<'PY'
  from _marathon_plan import Engine
  e = Engine.__new__(Engine)
  e.FORMAT, e.NOW, e.GH_MODE = "json", "2026-10-24T00:00:00Z", "off"
  e.findings = [{"severity":"info","type":"drift","file":"PROJECT/2-WORKING/GH-1.md","message":"sample","action":"sample"}]
  outputs = []
  for e.ROOT in ("/clone-A", "/clone-B"):
      outputs.append(e._render_report([], [], [], [], False, 0, {}, ""))
  print(outputs[0], end="")
  print("nonempty =", bool(outputs[0].strip()))
  print("different roots produce identical JSON =", outputs[0] == outputs[1])
  assert outputs[0].strip() and outputs[0] == outputs[1]
  PY
  ```

- **[Nit] R3 — narrow the rating rationale's universal rollback claim** (artifact:23,106-108). `utils/py/wave_reconcile.py:1735-1752` rolls back for findings attributable to reconciled issues; unrelated stale issues produce a warning and keep reconciliation. Say “when the stale primary produces findings attributable to this PR's reconciled issues,” rather than “every” close whenever that ledger lags. The stated 72/70/50/92 remains a reasonable operator judgment for a recurring landing-path defect and a one-line repair; the extra historical incidents are reported context, not independently replayed evidence in this turn.

- **[Pass] Root cause, fix site, and override contract:** `utils/py/marathon_plan.py:114-115` calls unanchored `repo_root()`, then applies `QUEUE_PLAN_ROOT`; `harness_paths.py:43-46,57-59` checks an explicit anchor before `XYZ_HARNESS`; `harness_paths.py:80-89` strips the vendored `.xyz` component for an anchored consumer root. Bash already derives its root from its own location (`utils/marathon-plan.sh:93-105`). Root cause: the planner asks the shared resolver an unanchored install question; Fix site: its default-root call; Why not upstream/downstream: the resolver already provides the required contract, and a reconciler-only override would miss direct CLI invocations.
  Resolver probe command (exit 0; actual canonical path, vendored file existence simulated only):
  ```sh
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  PYTHONPATH=utils/py python3 - <<'PY'
  import os
  from unittest.mock import patch
  import harness_paths as hp
  anchor = os.path.abspath("utils/py/marathon_plan.py")
  assert hp.repo_root(anchor_file=anchor) == os.getcwd()
  print("unanchored_is_primary =", hp.repo_root() == os.environ["XYZ_HARNESS"])
  print("anchored_is_worktree =", hp.repo_root(anchor_file=anchor) == os.getcwd())
  vendored = os.path.join(os.environ["TMPDIR"], "consumer/.xyz/utils/py/marathon_plan.py")
  original_isfile = os.path.isfile
  with patch("harness_paths.os.path.isfile", side_effect=lambda p: p == vendored or original_isfile(p)):
      actual = hp.repo_root(anchor_file=vendored)
      expected = os.path.join(os.environ["TMPDIR"], "consumer")
      print("vendored_consumer =", actual)
      assert actual == expected
  print("all resolver assertions passed (vendored file existence simulated only)")
  PY
  ```
  Decisive output: `unanchored_is_primary = True`, `anchored_is_worktree = True`, `vendored_consumer = <worktree>/.relay-scratch/tmp/consumer`, `all resolver assertions passed (vendored file existence simulated only)`. An earlier probe exited 1 because its blanket `isfile=True` mock also classified the harness directory as a file; that invalid simulation is discarded, not evidence against the resolver.

- **[Pass] Scope stays surgical:** artifact:17-21 excludes shared-resolver, downstream-engine, Bash and new-test changes; artifact:70 proposes only `repo_root(anchor_file=__file__)`, and artifact:84 supplies the one-line rollback. No added writer, resolver, suite, or gate is proposed.

**[Unverified — needs clone run]** The four suites, actual CLI missing-DB red/green control, write destination, actual vendored CLI and final gate were not executed here, as required by this review turn's containment instructions. This is plan QA, not implementation approval.

Handing off to Producer (claude-a) — correct R1/R2, disposition R3, then return the revised artifact for review; go to the Producer window and say 'take your turn'.

### Producer · Round 1 — claude-a

Dispositions (all three accepted; artifact revised in the same commit):

- **R1 — Accepted.** Observed section now states the recorded planner rc=4 (not 0), the JSON-parse failure, and the write into the primary, and says the plan repeats the control only against disposable clones. Verification check A rewritten: two disposable clones A (candidate) and B (alternate, `XYZ_HARNESS=<B>`), `--dry-run` on every planner run, planner exit captured directly, reverted = ledger loads from B (rc 0/4/5), fixed = rc 3 cannot-read on A, B's tree byte-identical before/after, receipts listed in `provenance.jsonl`.
- **R2 — Accepted.** Smoke rewritten around a distinguishable ledger: a sentinel roadmap row added only in disposable B; unpinned run in A must not mention it (reverted code does); `QUEUE_PLAN_ROOT=<B>` must mention it (override precedence). Suite boundary stated accurately: `test/marathon-plan.sh` pins the override not the default root; gh358/gh429 stub the planner. Vendored root witnessed by check 2's anchored resolver probe (your isfile-patched shape), not attributed to the stub suites.
- **R3 — Accepted.** Rating rationale and the #1127 related line now say "whenever the primary's stale ledger yields a finding attributable to the PR's reconciled issues" (`wave_reconcile.py:1735-1752`); rating unchanged at 72/70/50/92.

No runtime change proposed beyond `repo_root(anchor_file=__file__)`; no new tests, suites, resolvers or writers.

VERDICT: PASS
Basis: all round-1 findings folded into the artifact at this commit; requesting round 2 review of the revised plan.

Handing off to Reviewer (codex) — review the revised artifact; go to the Reviewer window and say 'take your turn'.

### Reviewer · Round 2

**Ship the plan.** No remaining Blocker or Should findings.

VERDICT: PASS
Basis: the revised verification distinguishes the selected ledger, contains the red control, and preserves the surgical implementation. Approval is for the plan; implementation receipts and the final gate remain pending.

swept file: yes

Read the entire revised artifact and entire Python CLI wrapper; rechecked resolver precedence/vendored handling, Bash dispatch/root selection, engine ledger loading/classification/JSON rendering, reconciler attribution, the recorded red control, and the named suites. No additional material in-scope defects found. Graph tools were unavailable; direct source inspection supplied the evidence. Reversibility: Easy — one default-root call, with the override and existing writer retained.

- **[Pass] R1 resolved:** artifact:58-64 now reports planner rc=4 and the primary write accurately. Artifact:93-104 requires disposable A/B clones, `--dry-run`, direct planner status, missing local DB versus alternate ledger, and retained provenance. The expected fixed rc=3 follows `_marathon_plan.py:765-809,815-835`; `marathon_plan.py:192-197` exits dry-run before the plan-copy path. The earlier JSON parse error remains documented in the supplied receipt and Round 1; the plan no longer uses it as evidence of successful parsing.
- **[Pass] R2 resolved at plan scope:** artifact:111-117 replaces ambiguous relative paths with distinguishable ledger content and an override to a different root. A queued issue with no doc yields the concrete `issue #N has no PROJECT capture doc` finding (`_marathon_plan.py:986-989`), so presence/absence of its issue number can distinguish B from A and fail on reversion. Artifact:118-123 correctly limits suite claims to pinned-root engine behavior and stubbed reconciler tool resolution; the simulated vendored resolver observation is explicitly identified at artifact:107-110. These are planned checks, not executed CLI evidence.
- **[Pass] Root cause, proposed fix and override:** `marathon_plan.py:114-115` still resolves an unanchored default, then applies `QUEUE_PLAN_ROOT`. `harness_paths.py:43-46,57-59,80-89` makes an existing explicit anchor win and strips `.xyz` for the consumer. The pure probe below independently observed canonical and simulated vendored results. Root cause: an unanchored install-resolution request selects the global alternate; Fix site: the planner default-root call; Why not upstream/downstream: the resolver already supplies the right contract, while a reconciler-only override misses direct calls.
- **[Pass] R3 and scope:** artifact:128-136 scopes rollback to findings attributable to reconciled issues, matching `wave_reconcile.py:1735-1752`. The 72/70/50/92 rating is a reasonable judgment for the supplied recurring landing-path consequence and bounded repair; historical incidents beyond the supplied receipt were not independently replayed. Artifact:17-20,75,84-89 proposes no new suite, resolver, gate or parallel writer.
- **[Nit] Make the sentinel assertion literal during execution:** artifact:112-117 says a sentinel issue URL, but JSON emits the issue number in a finding, not that URL or its title (`_marathon_plan.py:987-989,1254-1258`). Use a unique issue number absent from A and a queued row with no doc; assert the corresponding `#N` finding in nonempty parsed JSONL. Do not grep for the whole URL. This clarifies the planned observable without changing runtime behavior or expanding scope.

Probe command (exit **0**; imports and pure resolver/renderer calls only, no CLI, `engine.run`, suites, subprocesses, or executable fixtures):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
PYTHONPATH=utils/py python3 - <<'PY'
import os
from unittest.mock import patch
import harness_paths as hp
from _marathon_plan import Engine
anchor = os.path.abspath("utils/py/marathon_plan.py")
alternate = os.path.abspath(os.environ["TMPDIR"])
with patch.dict(os.environ, {"XYZ_HARNESS": alternate}):
    print("unanchored_is_alternate =", hp.repo_root() == alternate)
    print("anchored_is_candidate =", hp.repo_root(anchor_file=anchor) == os.getcwd())
    assert hp.repo_root() == alternate
    assert hp.repo_root(anchor_file=anchor) == os.getcwd()
    vendored = os.path.join(alternate, "consumer/.xyz/utils/py/marathon_plan.py")
    original_isfile = os.path.isfile
    with patch("harness_paths.os.path.isfile", side_effect=lambda p: p == vendored or original_isfile(p)):
        consumer = hp.repo_root(anchor_file=vendored)
        print("vendored_is_consumer =", consumer == os.path.join(alternate, "consumer"))
        assert consumer == os.path.join(alternate, "consumer")
e = Engine.__new__(Engine)
e.FORMAT, e.NOW, e.GH_MODE, e.findings = "json", "2026-10-24T00:00:00Z", "off", []
e._flag("info", "needs-doc", {"title": "sentinel", "docRel": None},
        "issue #987654 has no PROJECT capture doc linked in the ledger",
        "promote to a 2-WORKING capture doc with a preflight contract")
report = e._render_report([{}], [], [], [], False, 5, {}, "")
assert report.strip()
assert "#987654" in report
print("nonempty_sentinel_finding =", "#987654" in report)
print("literal_issue_url_in_json =", "https://github.com/" in report)
print("pure resolver/renderer assertions passed; no CLI or engine.run executed")
PY
```

Decisive output: `unanchored_is_alternate = True`, `anchored_is_candidate = True`, `vendored_is_consumer = True`, `nonempty_sentinel_finding = True`, `literal_issue_url_in_json = False`, `pure resolver/renderer assertions passed; no CLI or engine.run executed`. Vendored file existence was simulated; this does not attest an installed vendored CLI.

**[Unverified — needs clone run]** Actual missing-DB red/green control, distinguishable-ledger/override smoke, four suites and final gate were not run here. Execute the approved plan in disposable full clones and retain the specified evidence before implementation sign-off. No artifact/source edits or Git commands were performed; the harness owns the relay-only commit. The first relay-edit command failed shell parsing (exit 1, `unmatched` backtick); a subsequent read showed the header still Open. The corrected edit uses a distinct outer heredoc delimiter.

Relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-10-24T22:17:46Z
task: RELAY-gh1195-plan-qa-r1
reviewer: codex
status: Approved
reviewed-head: 4f83fa9df77a52fc18fdc00e96faf4d09b3b5813
added-range: 17556+6351
added-sha256: de219347ea973c5b65984fc5d9f9376d304986f49f49ba0705f788fc97ad5836
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
