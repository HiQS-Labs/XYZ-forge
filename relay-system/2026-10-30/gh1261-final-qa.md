# RELAY · GH-1261 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
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
6. **Commit only the relay file** (`relay(gh1261-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/harness.py`
- Also read: the diff `git diff b1dd41a8..HEAD -- utils/py/harness.py`; the approved plan `PROJECT/2-WORKING/GH-1261-PLAN-DRAFT-PHASE-2B.md` and its plan QA thread `relay-system/2026-10-30/gh1261-plan-qa.md`; evidence `TESTS-RESULTS/2026-10-30+GH-1261/SUMMARY.md`, `controls.txt`, `gh1261-controls.py`, `gh1261-controls.sh`, `pilot-3/`; `utils/py/_marathon_plan.py` (_pack_waves, _zone_of, _deps_of).
- Operational envelope: a local, single-operator, read-only experiment on an unmerged spike branch (stacked on feat/gh1248-outer-loop-primitive). Grade against the approved plan and commensurate complexity; no multi-tenant or enterprise machinery. XYZ-forge forbids new test suites (AGENTS.md, GH-831): a new test file or registry entry is a finding; verification is manual controls under `TESTS-RESULTS/`. The full gate is running in the verify clone; its result will be added in the next Producer block.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-30
- Definition of Done: each acceptance item in the plan is met by the code and shown by the evidence; the code matches the approved plan (R1 no tie-break, R2 lookup for every seeded unregistered request, R3 no cap, N=0 makes no list call, `unresolved_names` in BRIEF_KEYS); no second planner, writer or suite; read-only/offline claims hold; ledger issues are never handled less conservatively than in Phase 2A; the rating 55/40/50/60 still fits.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 1 · claude-a

Implementation `f0bb7db9`, evidence `7bc1742d`. Pilot on 20 real issues and 13 manual controls pass, including red controls for the #216 under-count and the R2 dependency case. Please check especially: BARE_RE false matches or misses; the `.xyz/` strip path; `_unregistered_record` keys versus everything that reads a planner record in plan_draft/_build_proposal/render; dependency view overlay; init failure leaves no admitted state.

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: source review supports the approved design; acceptance evidence is incomplete. Return for retained provenance and measured ledger preservation, plus the already-pending disposable-clone gate. No source change requested.
swept file: yes

Swept all of `utils/py/harness.py`, the approved plan and plan-QA log, the named planner methods, controls/scripts, and pilot manifest/proposal/#216 brief. No additional source defect found, including in the pre-existing portions of the touched file. Verify-tier graph search returned zero harness symbols; `XYZ-forge` is another checkout, generation `2026-09-01T15:54:30Z`, with unavailable/stale candidate coverage. Material conclusions use this worktree's source, not graph completeness. No git command, suite, executable fixture, artifact/source edit, or self-commit performed. The requested base diff could not be obtained under the explicit no-git instruction: a read-only loose-object lookup reported `Diff unavailable without git: base loose object unavailable` (exit 0). Please retain the diff with the next evidence update so it can be reviewed without running git here.

- **[Should] E1 — Retain the required run provenance and ledger preservation measurements.** `AGENTS.md:114–116,162` requires `provenance.jsonl` with retained run evidence. `TESTS-RESULTS/2026-10-30+GH-1261/SUMMARY.md:6,17,41` claims ledger byte identity and unchanged replay files, but the supplied 28-file evidence directory has no provenance receipt and no before/after ledger digest lines. `pilot-3/manifest.json` contains a frozen-copy hash, which cannot establish the source ledger's before/after identity. Add the genuine retained receipt(s), exact commands/exit statuses, and measured before/after hashes for both `releases.db` and `releases.sql`; retain replay hashes if keeping that claim. If the original measurements were not retained, rerun only the necessary manual experiment in the disposable full clone rather than reconstructing a historical result. Include these with the pending gate receipt in the same PR. This is an evidence correction, not a request for a new test, gate, or runtime behavior.

  Probe command (exit **0**):
  ```sh
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  python3 - <<'PROBE'
  from pathlib import Path
  import re
  root=Path('TESTS-RESULTS/2026-10-30+GH-1261')
  files=[p for p in root.rglob('*') if p.is_file()]
  print('files:',len(files))
  print('provenance.jsonl:',[str(p) for p in files if p.name=='provenance.jsonl'])
  print('ledger before/after digest lines:',[(str(p),i,line) for p in files for i,line in enumerate(p.read_text().splitlines(),1) if 'releases.' in line and re.search(r'\b[0-9a-f]{64}\b',line)])
  PROBE
  ```
  Decisive output: `files: 28`; `provenance.jsonl: []`; `ledger before/after digest lines: []`.

- **[Pass] R1/R3 implementation matches the plan.** `_cited_paths` uses containment and existing-file checks, requires listing membership before stripping `.xyz/`, and leaves duplicate basenames unresolved (`harness.py:338–365`). `plan_draft` retains all extracted paths without a cap (`harness.py:533–543`). `pilot-3/slot_004.md` lists both Python paths and unresolved `marathon-plan.sh` (2). The retained `controls.txt` records `26 paths; PDDA kept=True` and distinct collision waves. No tie-break is present.
- **[Pass] R2 and synthesized record wiring match.** `harness.py:369–376,437–466,509–513` supplies reader keys, extracts body/title dependencies for briefs, inserts every seeded unregistered request into dependency lookup, and overlays admitted lanes. The existing planner holds unresolved dependencies (`_marathon_plan.py:830–835`). `controls.txt` records held/pending dependent `wave=None` and admitted prerequisite wave 2 before dependent wave 7, with the admitted-only red control packing the dependent.
- **[Pass] Bounded integration.** `harness.py:637–661` puts the list call behind `if unregistered`, filters registered numbers, orders and freezes candidates; list failure precedes `connect(instance / "state.db")`. `BRIEF_KEYS` includes `unresolved_names` (`harness.py:35–38`) alongside its producer and renderer/verifier. `pilot-3/manifest.json` has 10 ledger and 10 unregistered requests; `wave-proposal.json` reports 20 accepted briefs and 18 provisional lanes. A read-only JSON inspection found no intersecting write sets within either recorded wave view. The local advisory envelope still fits `55/40/50/60` (plan Rating).
- **[Unverified — needs clone run]** Final full gate, runtime containment/offline behavior, and ledger byte identity are not independently established by this turn. The gate is explicitly pending in Setup; return its final-state receipt with E1. Recorded control results above are inspected evidence, not rerun suites.

Handing off to Producer (claude-a) — retain E1 evidence, the base diff and final clone-gate result, then go to the Producer window and say 'take your turn'.

### Producer · Round 2 · claude-a

- **E1 — Implemented** (`31fad5d9`). Added `TESTS-RESULTS/2026-10-30+GH-1261/provenance.jsonl` (5 receipts). `ledger-identity.txt` is a genuine rerun in the disposable clone at `7bc1742d` (init 3 ledger + 3 unregistered, 6 ticks, all rc=0) with `releases.db`/`releases.sql` sha256 before and after: identical. The pilot-3 digests were measured but not retained, so per your instruction I reran rather than reconstruct. `smoke.txt` retains the replay tree digests (79f59842… before = after).
- **Base diff** retained: `harness-b1dd41a8..f0bb7db9.diff`. No source change since `f0bb7db9`.
- **Gate:** `./validate.sh` (route=full) on `7bc1742d` in the verify clone, rc=0 in 894s, passed 409/409, identity unchanged (`gate.txt`, `gate-7bc1742d.log`). `7bc1742d` and `31fad5d9` differ from `f0bb7db9` only in evidence/docs.

### Reviewer · Round 2 · codex

VERDICT: PASS
Basis: approve the implementation within the approved local advisory experiment. E1 is addressed by retained provenance, a genuine ledger-identity rerun, replay measurements and the disposable-clone gate receipt. No source change requested.
swept file: yes

Swept all 1,255 lines of `utils/py/harness.py`, including pre-existing code; reviewed the retained base diff, approved plan and plan-QA thread, planner dependency/zone/packing methods, manual control scripts/results, pilot manifest/proposal and #216 brief. No additional source defects found. Verify-tier graph lookup for `_cited_paths|_build_proposal|init_from_prs` returned zero symbols. Project listing (both pages) has no matching worktree; nearest `XYZ-forge` points at another checkout, generation `2026-09-01T15:54:30Z`; coverage reports planner `metadata_changed`. Used this worktree's source as fallback, without graph completeness claims. Only this relay file was edited; no git command, suite, executable fixture or module entry point ran.

- **[Pass] E1 closed.** `TESTS-RESULTS/2026-10-30+GH-1261/provenance.jsonl:1–5` retains five receipts. `ledger-identity.txt:1–17` identifies the disposable-clone rerun at `7bc1742d`, init rc=0 and six completed ticks, with identical full before/after hashes for both ledger files. This supports the rerun, not a reconstructed historical pilot digest. `smoke.txt:2–6` retains identical replay digests, both completed slot responses and the free lock. No further evidence correction required.
- **[Pass] Gate and source attribution.** `gate.txt:1–4` records `rc=0 in 894s, passed: 409 / 409` at `7bc1742d`, with matching HEAD/origin/clean-status identity; the nonempty raw `gate-7bc1742d.log:479` also contains `passed: 409 / 409`. The current source's Git blob hash, computed without git, is `fa1e1bfc2b037cc5ac483f2395917ccc7d11c778`, matching the candidate blob in the retained diff's `index a8f83e11..fa1e1bfc` header. A read-only comparison also matched all 14 candidate hunk spans. Accept the recorded clone run for this unchanged implementation; no rerun requested here.
- **[Pass] Approved behavior remains intact.** `harness.py:338–365,527–543` preserves containment, listing-gated `.xyz/` stripping, no ambiguity tie-break and all sourced paths. `harness.py:369–376,437–466,509–513` supplies synthesized reader keys, body/title dependency extraction and every seeded unregistered lookup record, with admitted lanes overlaid. `harness.py:35–38,551–554,573–595` produces and checks the new key together. `controls.txt:6–20` retains ambiguity, prefix, cap/collision, held/pending/admitted dependency and verifier measurements, including both red controls. No further implementation change required.
- **[Pass] Pilot, conservatism and integration.** `pilot-3/wave-proposal.json` records 20 accepted briefs, unchanged planner 6 lanes/2 waves, provisional 18 lanes/7 waves and held 5. Read-only JSON inspection found disjoint write sets in every wave of both views; #216 is in provisional wave 2 with both Python paths, the doc-sourced shell path and PDDA (`pilot-3/slot_004.md`, “Write set” and “Unresolved file names”). `harness.py:645–663` gates the one new read on N > 0 before admission; `controls.txt:1–5` records list failure without state.db, zero-mode without a list call, and candidate-order parity. `_run_tool` retains a sandbox profile without network permission and with constrained tool writes (`harness.py`, `profile = ("(version 1)(deny default)...`); source adds no planner, ledger writer or suite. `55/40/50/60` remains appropriate to the plan's advisory scope.

Evidence-inspection probe (exit **0**; this reads retained results, it does not rerun their experiments):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
from pathlib import Path
import hashlib,json,re
r=Path('TESTS-RESULTS/2026-10-30+GH-1261')
b=Path('utils/py/harness.py').read_bytes()
h=hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()
assert h.startswith('fa1e1bfc')
print('source blob:',h,'matches retained diff candidate fa1e1bfc')
print('provenance receipts:',len([json.loads(x) for x in (r/'provenance.jsonl').read_text().splitlines()]))
s=(r/'ledger-identity.txt').read_text()
for name in ('releases.db','releases.sql'):
 v=re.findall(r'([0-9a-f]{64})  '+re.escape(name),s)
 assert len(v)==2 and v[0]==v[1]
 print(name,'before=after:',v[0])
s=(r/'smoke.txt').read_text(); v=re.findall(r'(?:before: |after:  )([0-9a-f]{64})',s)
assert len(v)==2 and v[0]==v[1]
print('replay before=after:',v[0])
s=(r/'gate-7bc1742d.log').read_text(); assert 'passed: 409 / 409' in s
print('gate log: passed: 409 / 409')
PY
```

Decisive output: `source blob: fa1e1bfc2b037cc5ac483f2395917ccc7d11c778 matches retained diff candidate fa1e1bfc`; `provenance receipts: 5`; `releases.db before=after: a0c9a6d1b30a396448a03d6476514ae1dd8d890e6d8407e43e1a41254cc74588`; `releases.sql before=after: b6922bba94c3a1c609d2fbe44b3ebd0c37a083e5ed0f7e48a289c5f8b9a2c84b`; `replay before=after: 79f59842949cc78c08e1bfcca4c7d7e6f53d99e84cea2e53386aada49f92145b`; `gate log: passed: 409 / 409`.

Limits: runtime experiments and the full gate are Producer-recorded disposable-clone evidence inspected here, not independently rerun in this reviewer worktree. Approval covers this experiment and source; it does not authorize dispatch or promotion. The first relay-write command failed shell parsing (exit 1) before making a change; this file-scoped patch completed the update.

Relay closed (Approved), no further turn needed. The harness owns the file-scoped commit.


### Attestation · relay-drive — 2026-10-30T14:52:52Z
task: RELAY-gh1261-final-qa
reviewer: codex
status: Approved
reviewed-head: 6b211165f40f034e83172dc96657afc045610bc4
added-range: 12794+5677
added-sha256: 13d6a6ff986350c6bc7ade99b414e32baf099c84e7e70615f978a180a931c09d
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
