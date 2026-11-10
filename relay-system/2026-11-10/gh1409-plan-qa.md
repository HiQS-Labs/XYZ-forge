---
Goal: Plan QA for GH-1409 (vendored-smoke base-pinning of judge files)
Date: 2026-11-10
NEXT: codex
STATUS: Open
---

# Context

Review the implementation plan in `PROJECT/2-WORKING/GH-1409-VENDORED-SMOKE-BASE-PIN.md` before any
code is written. The issue text is https://github.com/HiQS-Labs/XYZ-forge/issues/1409, and the
recon comment that narrowed it is linked from the plan.

**Operational envelope.** This is a public single-maintainer repo. Every PR is authored by one
account, and agents run under it. The goal is to stop a PR from weakening vendored-smoke's own
judge files in the same change. It is not a defence against a determined insider; the operator
explicitly accepted the `ci.yml` self-edit loophole and dropped CODEOWNERS. The repo forbids new
tests, new suites and new gate machinery (`AGENTS.md` "No new tests", GH-831). A new loose script
under `utils/` would also trip the inventory ratchet. Grade against the plan's requirements
R1–R5 and commensurate complexity. Do not ask for enterprise controls.

Read the following:
- `PROJECT/2-WORKING/GH-1409-VENDORED-SMOKE-BASE-PIN.md` (the plan)
- `.github/workflows/ci.yml`: the `vendored-smoke` job, about lines 524-583
- `utils/pdda/check_inventory_ratchet.py` and `utils/pdda/inventory_ratchet_baseline.json`
- `test/gh308-frozen-twin-guard.sh` (lines 1-80), `test/gh421-auto-wave-reconcile.sh` (head)
- The heads of `test/gh396-find-harness-roots.sh`, `test/gh393-deepseek-readiness.sh`,
  `test/gh358-wave-reconcile-vendored-paths.sh`, `test/gh292-worktree-vendored-discovery.sh`
- `relay-automation/xyz-vendor.sh` (`VENDOR_DIRS`, about line 432)
- `test/ci-workflow.sh` (around lines 355-362, which pin the twin guard's placement)

# Questions

1. **R1.** On a `pull_request` run, `actions/checkout` checks out `refs/pull/N/merge` with
   `fetch-depth: 0`. Is `HEAD^1` the right trusted base, and is failing closed when `HEAD^2` is
   absent correct? Does removing the gh308 step's step-level `BASE_SHA` env change its behaviour
   on PR merge refs?
2. **R4 (pin in place).** The plan claims that restoring each judge script in place with
   `git checkout "$BASE_SHA" -- <paths>` keeps it scanning the candidate tree, because each one
   resolves paths from its own location. It also claims `xyz-vendor.sh` then copies the base
   copies of the four suites into `.xyz/test`. Verify both against the cited lines. Is any judge
   script missed, or does any of them read a sibling file that would then mismatch?
3. **R2 (baseline monotonicity).** Does the planned comparison (scripts subset, bypass-file subset,
   count not larger) accept every legitimate `--update-baseline` shrink and reject every growth
   that `check_inventory_ratchet.py --check` would otherwise accept with an inflated baseline?
   Remember that the pinned ratchet then runs against the PR's own baseline.
4. **R3 (marker diff).** Is `git diff -U0 "$BASE_SHA" HEAD -- '*.py' '*.sh' ':!test/**'`, grepped
   for added `SQLITE-(BYPASS|GATEWAY)-OK:` lines, correctly scoped against what
   `scan_sqlite_bypasses` actually honours (`PRUNED_DIRS`, `SCRIPT_EXTS`)? Would it false-positive
   on a plain line move inside a file? If so, is that acceptable friction?
5. **R5 (label).** Is a live `gh pr view --json labels` lookup with `GH_TOKEN: github.token` under
   the workflow's `contents: read` permission workable on this public repo? Is "re-run after
   labelling" a sound operator flow?
6. **Scope.** Is the design surgical: one inline step, no new file, no new suite? Flag any
   over-engineering, and any requirement from the issue's Phase 1/2 that was dropped without a
   recorded reason.
7. **Verification.** Do the five manual controls (three red, one green, one label-adjacent) plus
   this PR's own hosted run actually falsify R2–R5? Is extracting the step's `run:` block and
   running it against a constructed `--no-ff` merge in a disposable clone a faithful reproduction?

Every `[Blocker]` or `[Should]` that asks for a behaviour change must carry `Observed input:`,
`Affected scope:` and `Falsifier:` lines. Cite `file:line`. Write your verdict below. Set
`STATUS: Approved` if the plan can proceed as written (or with only `[Nit]`s); otherwise hand back
with your findings.

## Log

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex plan QA — 2026-11-10

**Block — revise R2 before implementation.** The single inline step is proportionate to the stated operational envelope; no enterprise controls or new suites are requested.

### [Blocker] Compare effective bypass cardinality, not only its descriptive count

`PROJECT/2-WORKING/GH-1409-VENDORED-SMOKE-BASE-PIN.md:63-65,82-83` compares `sqlite_bypasses_count`. But the pinned checker never reads that field: it constructs a set of `sqlite_bypasses` at `utils/pdda/check_inventory_ratchet.py:116` and compares its length at `:155-159`. A PR can append a second location in an existing bypass file, leave the declared count unchanged, and add the corresponding unmarked connect site. The planned subset/count comparison accepts this and the pinned checker sees matching effective debt. This is the exact baseline-inflation class R2 is meant to stop.

Observed input: the seeded baseline has declared count 32 and 32 distinct locations. An in-memory candidate appending `<existing-file>:999999` retains declared count 32 but has 33 distinct locations. Scripts and bypass-file sets remain unchanged.

Affected scope: R2 and the verification controls at plan `:113-119`; the dummy-script red control does not exercise this independent inflation route.

Falsifier: compare `len(set(candidate['sqlite_bypasses'])) <= len(set(base['sqlite_bypasses']))`, in addition to the script/file subsets (retain the declared-count check if desired). Record a manual red input with an extra distinct location in an existing file and unchanged declared count; it must fail. Legitimate `--update-baseline` reductions and line shifts must still pass. No new suite is needed.

Probe: `PYTHONDONTWRITEBYTECODE=1 python3 -` with the following read-only body; exit 0:

```python
import json
p=json.load(open('utils/pdda/inventory_ratchet_baseline.json'))
b=set(p['sqlite_bypasses']); f={x.split(':')[0] for x in b}
candidate=dict(p)
candidate['sqlite_bypasses']=list(b)+[next(iter(f))+':999999']
cf={x.split(':')[0] for x in candidate['sqlite_bypasses']}
print('base declared/list:',p['sqlite_bypasses_count'],len(b))
print('candidate declared/list:',candidate['sqlite_bypasses_count'],len(set(candidate['sqlite_bypasses'])))
print('planned R2 accepts:',set(candidate['scripts'])<=set(p['scripts']) and cf<=f and candidate['sqlite_bypasses_count']<=p['sqlite_bypasses_count'])
print('pinned checker count-growth predicate for one extra live site:',len(b)+1>len(set(candidate['sqlite_bypasses'])))
```

Decisive output:

```text
base declared/list: 32 32
candidate declared/list: 32 33
planned R2 accepts: True
pinned checker count-growth predicate for one extra live site: False
```

This is a predicate-level reproduction, not a claim that a constructed merge or suite was executed.

### Remaining questions

- **R1:** For the default PR merge checkout with full history (`ci.yml:530-533`), first parent is the tested base and second parent is the PR head. Requiring the second parent is appropriate fail-closed behavior. Exporting the first parent via GITHUB_ENV supplies the subsequent gh308 step once its overriding env is removed. This also aligns its range with the tested merge if the event's base SHA is stale on a rerun; the plan's claim that the two are always identical (`:93-94`) is stronger than necessary.
- **R4:** The seven scripts cover the direct judge invocations at `ci.yml:546-582`. Their location-derived roots point at the candidate tree. `xyz-vendor.sh:432,442-448` copies the working `test/` directory, including the restored suites. Helpers remain candidate-owned as explicitly accepted. Include `_setup.sh` (sourced by gh358 at `test/gh358-wave-reconcile-vendored-paths.sh:17`) in that residual description; it is outside `test/lib/*`. No additional pin is requested.
- **R3 [Nit]:** The proposed diff is broader than the ratchet's honored scan: the ratchet prunes every directory component in `PRUNED_DIRS` (`check_inventory_ratchet.py:25-39,68-80`), while the diff excludes only root `test/`. Added markers in fixtures, temp, results, relay records, or nested test directories can therefore require the label unnecessarily. A plain line move can also appear as an added marker line. This is conservative friction consistent with literal R3, not an evasion; document the accepted friction or reuse the scanner's exclusions if desired.
- **R5:** A live lookup is the right shape for rerun-after-label behavior. Actual GitHub token permissions and label propagation remain **[Unverified — needs hosted run]** here. `gh issue view 1409 --repo HiQS-Labs/XYZ-forge --json body` could not connect to api.github.com, so original Phase 1/2 scope and the linked recon comment could not be independently checked. Local plan records reasons for the stated omissions. Do not describe the stubbed label control as proof of live permissions.
- **Verification:** The listed controls discriminate script-baseline growth, marker replacement, suite pinning, a normal shrink and the label branch. Add the effective-cardinality case above to the same manual evidence. A constructed no-ff merge faithfully models parent ordering, provided the extracted run block also receives the declared step env, a writable GITHUB_ENV, and subsequent steps load its exports. A green unlabeled hosted run can establish live lookup success; the stubbed label control alone cannot establish real label/re-run behavior. All suite execution and merge-fixture verification remain **[Unverified — needs clone run]**, as required by this review turn's restrictions.

Only this relay file was edited. No git commands, test suites, executable fixtures, or source mutations were run. Graph discovery was attempted but the MCP tool required unavailable approval; source inspection supplied the evidence above.

## Producer response — round 1 dispositions (claude-a)

- **[Blocker] R2 effective cardinality — Accepted.** R2 now also compares `len(set(sqlite_bypasses))` (the
  cardinality the ratchet compares at `check_inventory_ratchet.py:116,155-159`) and keeps the declared count.
  Red control 1b (extra distinct location in an existing bypass file, declared count unchanged) is added.
- **R1 wording — Accepted.** "Identical" is replaced with "aligned with the tested merge, including stale re-run base".
- **R4 residual — Accepted.** `test/_setup.sh` is added to the accepted residual list.
- **R3 [Nit] — Accepted as documented friction** (Ponytail): broader scope and moved marker lines can need the label;
  no marker gets through. No exclusion list added.
- **R5 / label control — Accepted.** The stubbed label control is described as branch-only; live permissions are
  evidenced by this PR's hosted run.

Plan revised in `PROJECT/2-WORKING/GH-1409-VENDORED-SMOKE-BASE-PIN.md` (Requirements R2, Design note, Risks, Verification).

**Round 2 ask (codex):** confirm the R2 revision closes the blocker and nothing new is introduced. End your block
with exactly one line `VERDICT: Approved` or `VERDICT: Changes requested` (the shim's structural check requires a
`VERDICT:` line; round 1 failed it with exit 8), and set `STATUS: Approved` when approving.


## Codex plan QA — round 2, 2026-11-10

**Approved for implementation.** The R2 revision closes the round 1 blocker; no new blocking finding is introduced by the recorded revisions.

The revised requirement at `PROJECT/2-WORKING/GH-1409-VENDORED-SMOKE-BASE-PIN.md:63-68` now bounds the distinct bypass locations as well as the script set, bypass-file set and declared count. This matches the effective cardinality used by `utils/pdda/check_inventory_ratchet.py:116,155-159`. Red 1b at plan `:119-120` now directly challenges the missed inflation route. The R1 clarification (`:96-97`), helper residual (`:104`), accepted marker friction (`:105-106`) and branch-only qualification of the label stub (`:126-128`) accurately address the remaining dispositions.

Read-only predicate probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 -` with this body (exit **0**):

```python
import json
from pathlib import Path
p=json.loads(Path('utils/pdda/inventory_ratchet_baseline.json').read_text())
def accepts(c):
 b=set(p['sqlite_bypasses']); v=set(c['sqlite_bypasses'])
 return (set(c['scripts'])<=set(p['scripts']) and {x.split(':')[0] for x in v}<={x.split(':')[0] for x in b} and len(v)<=len(b) and c['sqlite_bypasses_count']<=p['sqlite_bypasses_count'])
grown=dict(p,sqlite_bypasses=p['sqlite_bypasses']+[p['sqlite_bypasses'][0].split(':')[0]+':999999'])
shrunk=dict(p,scripts=p['scripts'][1:],sqlite_bypasses=p['sqlite_bypasses'][1:],sqlite_bypasses_count=p['sqlite_bypasses_count']-1)
shifted=dict(p,sqlite_bypasses=[x.split(':')[0]+':'+str(int(x.split(':')[1])+10000) for x in p['sqlite_bypasses']])
for name,c in [('unchanged',p),('extra location unchanged declared count',grown),('shrink',shrunk),('line shift',shifted)]:
 print(name, 'ACCEPT' if accepts(c) else 'REJECT')
assert not accepts(grown) and all(accepts(x) for x in (p,shrunk,shifted))
```

Decisive output:

```text
unchanged ACCEPT
extra location unchanged declared count REJECT
shrink ACCEPT
line shift ACCEPT
```

This measures the revised predicate, not a completed implementation. Constructed-merge controls and suites remain **[Unverified — needs clone run]**; live GitHub token/label behavior remains **[Unverified — needs hosted run]**. Approval is of the plan and its verification obligations, not an implementation or merge-readiness attestation.

[Nit] Implementation order `:134` still says “five manual controls”; the expanded list now contains six including Red 1b. Execute all six listed controls.

Only this relay file was edited. No git commands, suite execution, executable fixtures or source mutations were performed this turn.

VERDICT: Approved

### System · relay-drive — 2026-11-10T22:09:06Z
terminal STATUS Approved written by FAILED reviewer turn (codex; shim returned non-zero) — reverted

## Producer response — round 2 (claude-a)

- Round 2 content approved the plan; the driver reverted it because my round-2 instruction asked for
  `VERDICT: Approved`, while the shim accepts only `PASS`, `FAIL` or `PARKED`. That was a Producer error, not a reviewer one.
- **[Nit] "five manual controls" — Accepted;** the implementation order now says six.

**Round 3 ask (codex):** confirm the plan as revised (no change since round 2 beyond the nit). End your block with
exactly `VERDICT: PASS` (or `VERDICT: FAIL` with findings), and set `STATUS: Approved` when passing.


## Codex plan QA — round 3, 2026-11-10

**Approved for implementation.** The current plan retains the effective-cardinality comparison in R2 (`PROJECT/2-WORKING/GH-1409-VENDORED-SMOKE-BASE-PIN.md:63-68`) and its matching Red 1b control (`:119-120`). Those still match the pinned checker's set-based cardinality comparison (`utils/pdda/check_inventory_ratchet.py:116,155-159`). The round 2 nit is resolved: implementation order `:134` now explicitly requires all six listed manual controls. No new blocking finding arises from this revision.

This is plan approval only. The prior round's predicate-level evidence remains applicable; no fresh runtime probe was needed for the control-count wording correction. Constructed-merge controls and suites remain **[Unverified — needs clone run]**, and live token/label behavior remains **[Unverified — needs hosted run]**. Execute the controls with the step's declared environment and a writable GITHUB_ENV, and load its exports for subsequent steps, as specified in the earlier review.

Only this relay file was edited this turn. No git commands, suite execution, executable fixtures, source mutations, or new verification artifacts were performed or created.

VERDICT: PASS

### System · relay-drive — 2026-11-10T22:10:32Z
terminal STATUS Approved written by FAILED reviewer turn (codex; shim returned non-zero) — reverted
