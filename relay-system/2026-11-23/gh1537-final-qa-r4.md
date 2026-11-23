# RELAY · GH-1537 Final QA round 4: side-branch merge before the ancestor exemption
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
-->

NEXT: Producer
STATUS: Approved
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
     A `[Blocker]` must cite an observed failure.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1537-final-qa-r4): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `githooks/pre-push` at head `7105c7785d464b9f96f069d6efa9fbe412725e43` (PR #1584). The change under
  review is the delta from the previously approved head `9c18e49f0`: `relay-system/2026-11-23/gh1537-r4-delta.diff` (37 lines);
  the full diff against base `5964566ef` is `relay-system/2026-11-23/gh1537-final-qa-code.diff`. Plan:
  `PROJECT/2-WORKING/GH-1537-PREPUSH-OWN-DIFF-ROUTING.md` (item 3). Evidence: `TESTS-RESULTS/2026-11-23+GH-1537/`
  (`README.md`, `red-green-table.log`, `previous-head-vs-repaired.log`, `provenance.jsonl`, `suites-provenance.jsonl`, `check.sh`).
  Prior history: `gh1537-plan-qa.md`, `gh1537-final-qa.md` (r3 PASS at `9c18e49f0`).
- Reviewer: codex (gpt-6-astra, reasoning effort high)   ·   Producer: claude-a
- Started: 2026-11-23
- Authorization: the operator approved exactly ONE extra round on PR #1584, limited to CodeRabbit's Major, recorded on #1537 as the
  comment "Operator decision 2026-11-23" (https://github.com/HiQS-Labs/XYZ-forge/issues/1537#issuecomment-7114076730; relayed by parent
  session a6590cb2). It also accepts the plan-QA cap deviation (plan QA ended FAIL at r3; final QA r3 PASS). This thread's cap is 1.
- Definition of Done: CodeRabbit's Major is fixed as stated, with no regression of the 20 earlier scenarios.

CodeRabbit Major (PR #1584, `own_diff_base`): "the early `return 1` for an ancestor merge base runs before the non-first-parent check. A new
merge of a side branch whose parent is not on the verified integration tip therefore keeps the update range. If that side commit changes
only the README, the update range can route to docs." Requested: move the ancestor check after the non-first-parent loop; keep rc 1 for
merges whose non-first parents are all on the tip; drop "or a merge of the branch's own sub-branch" from the plan's rc 1 bullet; add a
verification case: a README-only side-branch merge pushed after the integration tip is already in the remote branch must route full.

Operational envelope: grade against the stated requirements, commensurate complexity and this repo's own threat model. XYZ-forge forbids
new tests (AGENTS.md, GH-831): a new `test/` suite or `validate.sh` TESTS entry is a finding; verification is existing suites plus the
manual check with its red control. Gate/hook surface: do not suggest deferring a finding. Other CodeRabbit comments on the PR (the push-URL
argument, the plan-QA probe record, the replay `OUT` path) were NOT part of the operator's authorization and are not in this round; if
you find a defect in code this change touches, report it anyway.

Questions (cite `file:line`; behaviour-change requests carry `Observed input:`, `Affected scope:`, `Falsifier:`):
1. Is the reordering exactly what the Major asks, and is the resulting `own_diff_base` order correct and complete (dest, tracking tip,
   any merge, live probe, freshness, `^tip` exclusion, merge-base, non-first-parent rejection, ancestor exemption, narrow)? Is there
   any input that previously returned rc 0 or rc 1 correctly and now returns rc 2 unnecessarily or the reverse (octopus; a merge of
   a side commit already on the tip; `mbs` an ancestor of `remote_sha` with every own merge on the tip)?
2. Does the new scenario `side_merge_after_integration` reproduce CodeRabbit's case through a real `git push` (README-only side
   commit, integration tip already in the remote branch), red at `9c18e49f0` (docs) and green at the head (full)? See
   `previous-head-vs-repaired.log` (it must show this as the only scenario that changed) and `provenance.jsonl`.
3. Were all 20 earlier scenarios rerun on the new hook (`red-green-table.log`: 21 rows, 0 candidate mismatches, 10 red on base), and the
   six existing suites rerun at the new hook (`suites-provenance.jsonl`: tested commit `b48f00a0f`, hook sha256 `062ada684bedf828`,
   clone identity unchanged)? Is any claim in the README or plan unsupported?
4. Does the plan text match the code (item 3 bullets, the removed "sub-branch" wording, the verification list)?
5. Whole-file sweep: any defect in `githooks/pre-push` introduced or touched by this change? Scope: still one hook file, no new suite.

End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, a Basis; set STATUS to Approved only on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1 · codex

**Approve the bounded CodeRabbit Major repair.** The parent check now precedes the ancestor exemption, and the retained evidence shows the requested docs-to-full correction without changing the earlier 20 scenario results.

- **[Pass] The order and return-code boundary match the requested repair.** `githooks/pre-push:214-240` checks destination, local tracking tip, any merge, live probe/freshness, verified-tip exclusion and unique merge-base in that order. At `:246-251`, every non-first parent is checked before `:254` can return rc 1. An octopus merge with any non-first parent outside the tip is therefore rejected (rc 2); all parents on the tip retain the prior result: rc 1 when the merge-base is already in the remote branch, otherwise rc 0. A side commit already on the tip is accepted as integration content. An empty own-merge set still returns rc 1 at `:237`. Moving the ancestor check changes only the previously exempted case with an off-tip non-first parent; it cannot change a previous rc 0 or an already rejected candidate. These edge conclusions are source reasoning, not newly executed Git fixtures. No correction requested.

- **[Pass] The new fixture models the Major and the retained red control is discriminating.** `TESTS-RESULTS/2026-11-23+GH-1537/check.sh:121-125` first pushes the development merge, creates a README-only side commit outside development, then merges and pushes that side branch. The actual push helper is at `:90`; hook installation is at `:81`. `push-output.log:111-123` retains real push output and docs/full stub markers; `provenance.jsonl:17-18` records successful pushes with base docs versus repaired full. `previous-head-vs-repaired.log:10` records prior approved head `9c18e49f0=docs repaired=full`; its other 20 rows agree. The probe below checks that comparison against the candidate receipts. The prior-head result is retained comparison evidence, not a new reviewer execution; the per-run JSONL uses the original base hook. No correction requested.

- **[Pass] All 21 scenarios and six focused suites are attributed to the repaired hook.** `provenance.jsonl:1-42` contains 21 scenarios per variant, ten original-base mismatches and zero candidate mismatches, with matching actual gate markers. Only the deliberately broken-tree scenario has push exit 1 (`:35-36`), as disclosed in `README.md:45`. Candidate hook hash `062ada684bedf828` matches the seeded file. The scenario receipts' `repo_head=9c18e49f0...` identifies the checkout during the overlaid-hook run; it is not the repaired commit identity. `suites-provenance.jsonl:1-6` instead records tested commit `b48f00a0f936cdd1a147d8d41d2918e6d3c83c40`, the same repaired hook hash and six zero exits. The complete before/after identity bracket at `:7` is equal, including HEAD, both bare flags, fetch/push mappings and local email. The six retained log exit markers agree. `run-focused.sh:8-29` shows how those values were captured. These receipts support the focused hook claims, not a full gate at head `7105c7785...`. No correction requested.

- **[Pass] Plan and evidence explanations remain aligned.** `PROJECT/2-WORKING/GH-1537-PREPUSH-OWN-DIFF-ROUTING.md:87-96` places off-tip-parent rejection before the ancestor exemption and explicitly removes the branch's own sub-branch from that exemption; `:135-139` includes the new scenario. The status count at `:28` agrees with the receipts. `TESTS-RESULTS/2026-11-23+GH-1537/README.md:8-22` and `:49-57` distinguish stubbed routing checks, historical replay, focused suites and remaining limits. `replay.sh:22-44` overlays current support files and directly invokes the hook with historical input; `replay/replay.log:1-12` records two own-diff paths versus 33 update paths and full/docs stub markers. This is a local historical replay, not a new production push. No unsupported current behavioral claim requiring correction was found within this round's scope.

- **[Pass] Whole-hook sweep found no additional substantiated pre-existing or introduced defect.** Reviewed all of `githooks/pre-push:1-472` and both supplied implementation diffs. Admission at `:90-99`, first-push resolution at `:282-306`, development/main exclusion at `:214-217`, merge-free routing at `:230-231`, tier-2 handling at `:399-418` and exact-commit full-receipt reuse at `:421-440` retain their previous scope. Aligned per-ref pairs at `:319-320`, final-tree diff with `--no-renames` at `:333`, failed-classifier-output rejection at `:371` and whole-push veto/docs-only acceptance at `:376-385` preserve the earlier fixes. The delta changes one hook; no new suite, registry entry or production subsystem appears. No correction requested.

Read-only evidence audit command (exit **0**):

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PYPROBE'
from pathlib import Path
import hashlib,json,re
p=Path('TESTS-RESULTS/2026-11-23+GH-1537')
h=hashlib.sha256(Path('githooks/pre-push').read_bytes()).hexdigest()[:16]
r=[json.loads(x) for x in (p/'provenance.jsonl').read_text().splitlines()]
s=[json.loads(x) for x in (p/'suites-provenance.jsonl').read_text().splitlines()]
assert len(r)==44 and h=='062ada684bedf828'
assert all(x['hook_sha256']==h for x in r if x['variant']=='cand')
for v,n in [('base',10),('cand',0)]:
 a=[x for x in r if 'scenario' in x and x['variant']==v]
 assert len(a)==len({x['scenario'] for x in a})==21
 assert sum(x['want']!=x['route'] for x in a)==n
 assert all(x['gate_ran']=={'docs':'docs-gate','full':'full-gate'}[x['route']] for x in a)
 assert all(x['push_exit']==('1' if x['scenario']=='two_refs_partial_failure' else '0') for x in a)
 print(v,'scenarios',len(a),'mismatches',n,'gate_and_exit_match',True)
old=re.findall(r'^(\S+)\s+want=(\S+) 9c18e49f0=(\S+) repaired=(\S+)',(p/'previous-head-vs-repaired.log').read_text(),re.M)
assert len(old)==21 and {x[0]:x[3] for x in old}=={x['scenario']:x['route'] for x in r if 'scenario' in x and x['variant']=='cand'}
changed=[x[0] for x in old if x[2]!=x[3]]
assert changed==['side_merge_after_integration']
b=s[-1]['clone_identity_before']
assert len(s)==7 and b==s[-1]['clone_identity_after'] and s[-1]['unchanged']=='yes'
assert set(b)=={'head','core.bare','is_bare','remote_v','local_user_email'} and b['core.bare']==b['is_bare']=='false'
assert all(any(z.endswith('('+k+')') for z in b['remote_v']) for k in ('fetch','push'))
assert b['head']=='b48f00a0f936cdd1a147d8d41d2918e6d3c83c40'
assert all(x['exit']==0 and x['hook_sha256']==h and x['tested_commit']==b['head'] for x in s[:-1])
assert re.findall(r'^rc=(\d+) (.+)$',(p/'focused-suites.log').read_text(),re.M)==[('0',x['suite']) for x in s[:-1]]
print('hook',h,'changed',changed,'suite_exits',[x['exit'] for x in s[:-1]],'identity_unchanged',True)
PYPROBE
```

Decisive output:

```text
base scenarios 21 mismatches 10 gate_and_exit_match True
cand scenarios 21 mismatches 0 gate_and_exit_match True
hook 062ada684bedf828 changed ['side_merge_after_integration'] suite_exits [0, 0, 0, 0, 0, 0] identity_unchanged True
```

Additional syntax command: `/bin/bash -n githooks/pre-push` — exit **0**, no diagnostics. Graph tools were unavailable, so this review used direct source and retained artifacts. No Git command, executable fixture, test suite or full gate ran in this reviewer turn. Approval relies on the evidence inspected above, not on an assumed later gate.

swept file: yes
VERDICT: PASS
Basis: the requested ordering defect is fixed; the new retained real-push control distinguishes the previous approved hook from the repair, all earlier scenario results remain unchanged, and the focused-suite receipts match the repaired hook with an intact clone-identity bracket. No open finding from the prior approved QA is reopened by this change. Full-gate execution on the final commit is not established by this review.

Relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-11-23T21:51:19Z
task: RELAY-gh1537-final-qa-r4
reviewer: codex
status: Approved
reviewed-head: 9a85a2b28e0a3cb24e35bdfcb025157f4c4bdf4a
added-range: 10211+7944
added-sha256: c75242f3d20cb3577e4e8051d7f3e565302d546cb1895b8c437488b4f7a065e0
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
