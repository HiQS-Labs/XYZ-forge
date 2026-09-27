# RELAY · GH-851/852 final QA — merge-cleanup landing resilience (implementation)
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
6. **Commit only the relay file** (`relay(gh-851-852-final-qa-merge-cleanup-landing-resilience-implementation): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the implementation diff from base 030ab5ba to HEAD on branch fix/gh851-852-merge-cleanup-network. Files: `skills/2-daily/merge-cleanup/SKILL.md`, `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, `skills/2-daily/merge-cleanup/scripts/scan_clones.py`, `test/gh436-merge-cleanup.py`, `test/gh534_phase_a_tests.py`, `test/gh534_phase_b_tests.py`, `CHANGELOG.md`, `TESTS-RESULTS/2026-09-27+GH-851/SUMMARY.md`, `PROJECT/2-WORKING/GH-851-MERGE-CLEANUP-LANDING-RESILIENCE.md`. Read in place; do NOT edit.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-27
- Definition of Done: see *Review packet* below (a)–(f). **One round only** (operator, 2026-09-27: minimum ceremony; #854 staging route). A FAIL is adjudicated by the Producer and the operator, not re-reviewed.

## Review packet

**What this is.** This is the final QA on the implementation of #851 and #852, one PR. It is #854's first
direct-path item, and it carries #854 decision D5, the 5400 s hosted-wait default. The plan is
`PROJECT/2-WORKING/GH-851-MERGE-CLEANUP-LANDING-RESILIENCE.md`. Its plan QA (`relay-system/2026-09-27/gh851-852-plan-review.md`)
ran two Codex rounds, then closed by operator-directed adjudication, with every finding accepted into the plan.
Branch `fix/gh851-852-merge-cleanup-network`, based on `030ab5ba`. Review the diff `030ab5ba..HEAD`. **Route:** the operator moved this PR to #854's `staging/stabilize-2026-10` branch. It gets no local full gate (a D2 bypass), and the staging landing gate re-runs it. This review is its D3 per-PR QA receipt.

**Definition of Done: Approved when all of these hold.**
- (a) Each of F1–F5 is implemented as the plan's *Plan* section states, at the lines it names. Nothing is missing, and nothing is added that the plan does not call for.
- (b) The existing subsystem is extended: GH-623 `_net_git` / `_retry_call` / `TRANSIENT_RE`, and GH-736's poll budget. There is no new module, helper family, writer, suite, test case or registry entry (AGENTS.md *No new tests*, GH-831). A new test file or registry entry in the diff is a finding.
- (c) The test edits are exactly the plan's C3 and D1 list: signature-only `**kw` on three `flaky` stubs; `gh436` `_run_main` injecting a MERGED PR, plus the `pr_head` / `merged_head` asserts in the ready-primary test; and `gh534_phase_b` PR 7 made MERGED. The Producer also added `reconcile.assert_called_once()` there, to prove that rc 2 comes from the reconcile and not the new refusal. Judge whether that is within "edit what the test injects" or is scope creep.
- (d) The evidence substantiates the claims. `TESTS-RESULTS/2026-09-27+GH-851/`: `witness.py.txt`, run unchanged at base and at head; `witness/*.jsonl` and logs; `SUMMARY.md`; `provenance.jsonl`; and `focused/`, holding gh436 (180 OK), gh674 (6 OK), gh645 (8 OK) and the Phase-B red control (FAIL `0 != 2`, then restored). Check that each witness would fail if its fix were reverted, and that no log is empty.
- (e) Safety holds. F2 returns True only on GitHub's `MERGED` with a merge-commit oid. F3 fails closed, with zero reconcile calls on OPEN or a read error, and never starts the local writer while the run on H is active. F4 cannot land a head other than the pushed one. The `GIT_HTTP_LOW_SPEED_*` defaults never override an operator's value.
- (f) The docs are truthful: the `SKILL.md` Phase 5 sentence and default, the `emit_pr_merged` docstring, and `CHANGELOG.md`. The ratings in the plan (#851 `55/35/50/85`, #852 `60/45/50/65`) still match the evidence.

**Read these yourself.** `git diff 030ab5ba..HEAD -- skills/ test/`; `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`
(`TRANSIENT_RE`, `execute_pr_merge`, `validate_head_in_second_clone`, `push_resolved_head`, `run_post_merge_reconcile`,
`commit_and_push_phase5_writes`, the post-B1 re-gate in `land_prs`, and `main`'s top and `--reconcile-pr`);
`scan_clones.py` (`classify_local_refs`, `main`); and the plan's *Plan* section.

**Specific questions.**
1. F4: when the refresh inside the head-wait loop returns an error, the code falls through to `_await_mergeable`, which returns the error, and the existing "after resolution the PR reads …" stop fires. Is that the right handling, or should a transient error there defer, as at the other pre-decision sites?
2. F3: `refresh_pr_with_retry` is read before `run_post_merge_reconcile`, and `dry_run` still short-circuits inside it. Is a dry-run `--reconcile-pr` now doing a network read it did not do before, and does that matter?
3. F1: `commit_and_push_phase5_writes` bounds its push at 3600 s. Is there any other caller of `run_git(... "push" ...)` or of `"fetch"` against a remote in these two scripts that is still unbounded? Cite it.

**Operating envelope.** A single-operator developer tool, run from one machine against one GitHub repo. Grade against the
stated requirements and commensurate complexity: surgical changes to one existing script pair. Do not grade against
multi-tenant or adversarial threat models, and do not ask for new infrastructure or new tests.

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
Basis: F1/F2/F3/F5 are present and the recorded focused evidence supports their stated cases, but F4 does not preserve its head invariant through the subsequent mergeability poll. The full runtime-file sweep also found an existing hosted-wait failure path inconsistent with DoD (e). One-round adjudication belongs to the Producer and operator.
swept file: yes

Sweep scope: both complete runtime scripts, all three listed test files, SKILL.md, the complete plan and evidence summary, witness source and base/head records; CHANGELOG's current task entry. Historical CHANGELOG entries were not exhaustively audited. No Git commands, test suites, executable fixtures, network calls, or writers were run. Source-only probes below compile individual function ASTs with inert dependencies.

- **[Blocker] R1 — the post-B1 mergeability poll can replace the head that F4 just checked.** At `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:1000` the head is checked against `b1["commit"]`; at `:1004` `_await_mergeable` may refresh it again. The `:1005` stop tests only error/mergeability, and `:1008` prepares whatever head that later read returned. The probe below observes the changed-head read passing that stop. This is a concrete violation of “F4 cannot land a head other than the pushed one,” not a request for new infrastructure.
  Observed input: pushed head `c*40`; first accepted observation `{headRefOid: c*40, mergeable: UNKNOWN, state: OPEN}`; next observation `{headRefOid: d*40, mergeable: MERGEABLE, state: OPEN}`.
  Affected scope: post-B1 polling where the head differs on a later mergeability read, including a stale response or an ordinary later branch update.
  Falsifier: the same sequence returning `c*40/MERGEABLE` must proceed; the `d*40/MERGEABLE` sequence must stop before preparing/merging that other head. Current probe accepts both.
  Root cause: head equality is treated as a fact that survives another remote read; Fix site: the post-B1 acceptance predicate after `_await_mergeable`; Why not upstream/downstream: the earlier equality check cannot certify the later response. Recheck equality there and retain the expected SHA through the merge request (the existing merge call at `:157` is by PR number only). Record a manual negative control in the existing evidence area; add no suite.

- **[Should] R2 — pre-existing hosted-wait fallback forgets observed activity after a read error.** `merge_cleanup.py:457` returns `fallback` on every lookup error, even after observing run 99 active on H; `:574` then invokes `run_local_wave_reconcile`. The narrow probe below observes `active_on_H then read_error -> fallback`. This contradicts SKILL.md:155's “Never invoke that local writer while the observed hosted run is queued or in progress” and prevents an unqualified DoD (e) attestation. The downstream writer's own guard may refuse (the plan cites exit 8); this finding does **not** claim concurrent writes or data loss were witnessed.
  Observed input: run list first returns run 99, `headSha=a*40`, `status=in_progress`; next lookup exits 1 with `connection reset`, with no completion observed.
  Affected scope: lookup failure after a matching active hosted run has already been observed during this wait.
  Falsifier: active → completed/success must return success; active → lookup error must not authorize the local fallback. Both branches are measured below.
  Root cause: a failed observation is treated as evidence that local reconciliation is safe; Fix site: `wait_for_hosted_reconcile`'s error exit after observed activity; Why not downstream: the downstream guard limits damage but does not satisfy this caller's promised no-invocation contract. Preserve that known-active state and stop on lost visibility, using the existing stop result; no new helper family is needed. Producer/operator may explicitly adjudicate this pre-existing defect, but should not attest the stronger safety claim unchanged.

- **[Pass] F1/F2/F5, within measured scope.** `merge_cleanup.py:325,352,567,618,622` use `_net_git`, with `:618` passing `PUSH_GATE_TIMEOUT_S=3600`; `scan_clones.py:437` passes 180. Both mains use `setdefault` (`merge_cleanup.py:1084`, `scan_clones.py:1260`), preserving operator values. Recovery at `merge_cleanup.py:166` requires both MERGED and a merge oid. The default is 5400 at `:442`. The corresponding base/head rows in `TESTS-RESULTS/2026-09-27+GH-851/witness/{base,head}.jsonl` change in the expected directions, with the OPEN and permanent-error controls unchanged. No additional unbounded remote clone/fetch/push call was found in the two scripts: the remaining plain fetch, `merge_cleanup.py:329`, reads a local `source_clone`, as the plan explicitly excludes.

- **[Pass] F3's intended refusal and SHA selection.** `merge_cleanup.py:1151` checks the PR read, MERGED state and merge oid before calling reconciliation with both SHAs. `witness/head.jsonl` records OPEN/read-error cases with zero reconciliation calls, and the stable active-run case with zero local-writer calls; the injected red control records one. These establish the listed scenarios, not R2's later-read-error scenario. `emit_pr_merged`'s revised docstring at `merge_cleanup.py:377` accurately distinguishes merge witnessing from recovery reconciliation.

- **[Pass] Existing test corrections and focused receipts.** `test/gh436-merge-cleanup.py:308,361,379` and `test/gh534_phase_a_tests.py:505,632` contain the specified stub/fixture corrections. `test/gh534_phase_b_tests.py:521` injects MERGED and checks `reconcile.assert_called_once()`: this is within keeping the existing test truthful, not a new test case. The retained focused logs report 180 OK (`focused/gh436-merge-cleanup.log:2050`), 6 OK (`focused/gh674-merge-cleanup-hosted-lookup.log:5`), 8 OK (`focused/gh645-merge-cleanup-xyz-tools.log:3`), and the red-control `AssertionError: 0 != 2` (`focused/red-control.log:9`) followed by restore OK. `provenance.jsonl` names the commits and commands. A read-only size enumeration reported `logs 31 empty []` (exit 0). The manual witnesses record outcomes, rather than exiting nonzero on every behavioral regression; their base/head differences supply the negative controls. The F4 witness stops deliberately at clone preparation and covers only a head that remains unchanged afterward, so it does not falsify R1.

- **[Pass] Specific questions 1–2.** Stopping on an exhausted post-push refresh error is consistent with Plan F4 and the existing post-resolution stop (`merge_cleanup.py:1004`); expanding deferral is not required by this plan. The diagnostic includes the error. Yes, dry-run `--reconcile-pr` now performs the PR read before the dry-run return in `run_post_merge_reconcile` (`:543`). This adds a bounded network dependency and possible exit 2, but no writer; it is consistent with the planned state check. Neither is a blocker.

- **[Nit] Current plan status is stale.** `PROJECT/2-WORKING/GH-851-MERGE-CLEANUP-LANDING-RESILIENCE.md:34` still says implementation and witnesses are next. Update that table at adjudication to reflect the existing implementation/evidence and this FAIL. The #851/#852 ratings remain proportionate to the incidents described under “Ratings”; the review does not establish a different incident severity.

- **[Unverified — needs clone run] Final-state gate and exact diff scope.** Per the operator's restriction, no suites were rerun and no `git diff 030ab5ba..HEAD` was obtained. The recorded focused runs name `9319ea9a`, and witnesses name `04fd21bf`; exact current-HEAD equivalence and the absence of other added files/registry entries require the harness's diff/gate attestation. No full local gate is claimed or requested beyond the agreed #854 staging route.

Probe command (exit **0**; no imports of the application or fixtures, all dependencies inert):

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
import ast, json
from pathlib import Path
from typing import Any, Dict, Optional
from types import SimpleNamespace as S
p = Path("skills/2-daily/merge-cleanup/scripts/merge_cleanup.py")
tree = ast.parse(p.read_text())
def load(name, ns):
    fn = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == name)
    exec(compile(ast.Module(body=[fn], type_ignores=[]), str(p), "exec"), ns)
    return ns[name]
for head in ("c"*40, "d"*40):
    ns = dict(Dict=Dict, Any=Any, Path=Path, MERGEABLE_POLL_ATTEMPTS=6,
              MERGEABLE_POLL_S=15, log=lambda _: None, _sleep=lambda _: None,
              refresh_pr_with_retry=lambda *_, h=head: dict(headRefOid=h, mergeable="MERGEABLE", state="OPEN"))
    info = load("_await_mergeable", ns)(5, dict(headRefOid="c"*40, mergeable="UNKNOWN", state="OPEN"), Path("."))
    print("pushed=cccc returned="+info["headRefOid"][:4]+" post_poll_stop="+str(bool(info.get("error") or info.get("mergeable") != "MERGEABLE")))
for next_state in ("success", "read_error"):
    def row(status, conclusion):
        return S(returncode=0, stdout=json.dumps([dict(databaseId=99, headSha="a"*40, status=status, conclusion=conclusion)]), stderr="")
    responses = iter([row("in_progress", None), row("completed", "success") if next_state == "success" else S(returncode=1, stdout="", stderr="connection reset")])
    ns = dict(Optional=Optional, Path=Path, json=json, HOSTED_WAIT_ENV="wait",
              HOSTED_POLL_ENV="poll", HOSTED_GRACE_ENV="grace", _seconds_from_env=lambda _, d: d,
              time=S(monotonic=lambda: 0, sleep=lambda _: None),
              _gh=lambda *a, **k: next(responses), log=lambda _: None,
              log_warn=lambda _: None, log_err=lambda _: None)
    result = load("wait_for_hosted_reconcile", ns)("b"*40, Path("."), "development", pr_head="a"*40)
    print("active_on_H then "+next_state+" -> "+result)
PY
```

Decisive output:

```text
pushed=cccc returned=cccc post_poll_stop=False
pushed=cccc returned=dddd post_poll_stop=False
active_on_H then success -> success
active_on_H then read_error -> fallback
```

Handing off to Producer (claude-a) for operator adjudication of R1/R2; STATUS is Escalated because this was the sole permitted round. No second review round is requested.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
