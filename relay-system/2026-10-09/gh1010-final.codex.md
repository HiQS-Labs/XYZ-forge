# RELAY · GH-1010 final implementation QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-09.
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
6. **Commit only the relay file** (`relay(gh-1010-final-implementation-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-1010-MERGE-HISTORY-POLICY.md; git diff ecec5561..HEAD; TESTS-RESULTS/2026-10-09+GH-1010/
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-09
- Definition of Done: GH-1010 implemented with shared opt-in policy, no unsafe fallback, accurate consumer docs and attributable evidence.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Final review packet

Read the canonical plan, diff from base ecec5561, both cleanup skills and deep agent template,
vendor-stack instructions, root policy and the retained TESTS-RESULTS summary/provenance/manual
probe. Existing cleanup suite: 180 tests pass; policy probes green; enforcement-removal red control
fails for the right reason; restored green; clone identity intact. Plan QA Approved in sibling relay.

Operational envelope: maintainer-controlled local developer CLI. No new test suites/gates allowed
by AGENTS. Keep machinery commensurate; do not request unrelated repairs or speculative frameworks.
Reviewer may read/probe without mutation but must not run suites/fixtures in this worktree. Only
this relay file may change; shim commits. Full final gate follows approval at the push boundary.

1. Does omitted/explicit strategy handling preserve compatibility and refuse forbidden methods at
   real writer boundaries, including direct calls and per-PR policy refresh?
2. Are malformed/unreadable policy and unavailable merge commits refused without fallback or
   hosting mutation? Is the reporter shared with deep audit and rooted at the target primary?
3. Do deep/vendor instructions preserve maintainer choice and distinguish ancestry/content without
   weakening historic provenance or teardown gates?
4. Do committed checks substantiate acceptance, and do neutral appeal/rating/no-new-tests hold?

Append findings with concrete falsifiers and citations; set STATUS Approved on PASS. Otherwise
return bounded actionable findings. Keep pre-existing unrelated changes outside this feature.

### Reviewer · Round 1

VERDICT: FAIL
Basis: The shared implementation and retained evidence support the policy, but two consumer instructions still prescribe unconditional squash. Correct those bounded documentation inconsistencies before approval.
swept file: yes

- [Should] **F1 — Remove unconditional squash from the consumer instructions.** skills/2-daily/merge-cleanup/SKILL.md:228 still gives “gh pr merge <PR_NUM> --squash --delete-branch”, and line 283 says “merges are squash commits on a remote branch.” These contradict the new Project merge policy section and Forge's enabled root policy. The literal direct-gh command bypasses the Python resolver. Replace the Phase 5 example with the policy-selected method (explicitly refer to the resolver), and make the continuation description method-neutral. No runtime change or new test is requested.
  Observed input: .merge-cleanup.json contains {"preserve_commit_history": true} while SKILL.md:228 specifies --squash; the read-only reporter returns "strategy": "merge" for this primary.
  Affected scope: Those two instruction spans in the cleanup skill, for opted-in projects and explicit non-squash strategies.
  Falsifier: If line 228 already selected the resolver's method and line 283 did not universally describe squash, this finding would be unnecessary. After correction, following Phase 5 with the seeded true policy must select merge; absent/false policy must retain the legacy squash default.
  Probe: rg -n "squash commits|Executes remote merges" skills/2-daily/merge-cleanup/SKILL.md returned both cited spans. python3 skills/2-daily/merge-cleanup/scripts/merge_cleanup.py --primary "$PWD" --show-merge-policy emitted {"preserve_commit_history": true, "strategy": "merge", "source": "/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/rtl-wt.KzhRow/.merge-cleanup.json"}. The combined read/probe command exited 0; Python startup also printed Xcode cache/event-stream warnings to stderr.
- [Pass] **Policy enforcement is shared and refreshed.** merge_cleanup.py:150 strictly resolves missing/boolean/invalid policy and explicit strategy; :194 guards the direct merge writer; :908 guards landing entry; :931 re-reads before each PR's repair/retarget; :1269 resolves before Phase 0 and exposes the JSON-only report. The writer receives the original args.strategy, preserving omission rather than freezing an earlier effective method. check_merge_capability (:176) requires positive hosting capability without settings mutation or fallback. No additional in-scope pre-existing runtime defect found in the whole-file sweep.
- [Pass] **Deep/vendor consumers preserve the intended boundaries.** Deep Phase 0 says “Do not parse another config or infer policy from a stale clone or the vendored harness”; Phase 3 says “Missing ancestry is not proof of missing content or a retroactive policy violation”; its agent template includes MERGE_POLICY and separate ancestry/content evidence. Vendor-stack's Project merge-history choice says “If they decline or have not chosen, leave the file absent” and “Do not copy Forge's own policy into a target.” The whole cleanup/deep/template/vendor files were read; no further in-scope consumer issue beyond F1 was found.
- [Pass] **Retained focused evidence is internally attributable.** TESTS-RESULTS/2026-10-09+GH-1010/cleanup-focused.log:3474 records “Ran 180 tests in 257.522s”, followed by “OK”; policy-red.log records “AssertionError: forbidden squash reached the merge writer after enforcement removal”; green/restored logs end “ALL POLICY PROBES PASSED”. Read-only Python check: parse each provenance row, assert its artifact is nonempty and hashlib.sha256(bytes).hexdigest() equals the recorded sha256, then compare identity-before/after bytes; exit 0, decisive output “10 nonempty artifact digests match; clone identity snapshots match”. Canonical plan's Rating rationale explicitly records neutral appeal 50 and an unknown trend; its verification plan uses existing suites and retained manual probes.
- [Unverified — needs clone run] No suites, fixtures, git commands, live merges or hosting mutations were run in this reviewer worktree. The full final harness gate remains outstanding as the packet states. The base-to-HEAD git diff and revision attribution were not independently queried because this turn expressly forbids git; review used complete named implementation/consumer artifacts and retained evidence instead. Graph indexing was refused by tool approval policy, so source reads were used.

Handing off to Producer (codex-producer) — correct F1, record its disposition, then return for Round 2. Only this relay file was edited.

### Producer · Round 2

F1 disposition: Implemented. Phase 5 uses the resolver-owned execute_pr_merge path; continuation
wording is method-neutral. Read the corrected complete skill spans. No runtime change.
Integrated current development 9a923f3c (the session crossed an overnight pause). Only changelog
and ledger conflicts: preserved both entries and used existing resolve_ledger_conflict writer to
replay GH-1010 onto the newer ledger; logs retained. Rating 65/55/50/75 remains.
Re-review F1 and integration against the same requirements; prior runtime checks remain on the
same implementation bytes. Full gate will run once at final push. Do not rerun tests here.

### Reviewer · Round 2

VERDICT: PASS
Basis: F1 is resolved; the integrated policy implementation, consumer instructions and retained evidence meet the implementation-review requirements. Final execution gates remain the harness's responsibility.
swept file: yes

- [Pass] **F1 closed.** skills/2-daily/merge-cleanup/SKILL.md:228 now says “through `execute_pr_merge`, using the method selected by the project policy resolver”; its continuation contract says “merges land on a remote branch using the policy-selected method.” Read the complete cleanup skill, not only these replacements.
- [Pass] **Shared enforcement and consumers remain coherent.** Whole-file sweep of merge_cleanup.py and the cleanup/deep/vendor skills plus deep agent template found no additional in-scope pre-existing defect. merge_cleanup.py:150 owns strict resolution, :194 guards the merge writer, :908 and :931 resolve at landing entry and per PR, and the final writer receives `strategy=args.strategy` rather than freezing the effective default. Deep Phase 3 explicitly says “Missing ancestry is not proof of missing content or a retroactive policy violation”; vendor instructions retain “If they decline or have not chosen, leave the file absent.” No policy-based relaxation of teardown evidence was found.
- [Pass] **Seeded reporter selects merge.** Command: `PYTHONDONTWRITEBYTECODE=1 python3 skills/2-daily/merge-cleanup/scripts/merge_cleanup.py --primary "$PWD" --show-merge-policy`, with TMPDIR pinned to .relay-scratch/tmp; exit 0. Decisive output: `{"preserve_commit_history": true, "strategy": "merge", "source": "/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/rtl-wt.ET6qT7/.merge-cleanup.json"}`.
- [Pass] **Retained evidence and integration record remain internally consistent.** Read-only `python3 -` probe parsed every nonempty provenance.jsonl row, required nonempty artifact bytes and asserted `hashlib.sha256(b).hexdigest()==row['sha256']`, then compared identity-before/after bytes; exit 0, output “12 nonempty artifact digests match; clone identity snapshots match”. The same probe opened `sqlite3.connect('file:releases.db?mode=ro',uri=True)`, executed `select * from roadmap_items where gh_number=1010`, and asserted exactly one row; output retains the working-plan doc_path and ratings 65/55/50/75, override null. integration.log quotes “keep=theirs generation ours/theirs=(1533, 1564) replay=1 op(s)” and successful writer add/rate/update/rebuild. SUMMARY.md attributes the 180-test run and witnessed enforcement-removal red control to aa479b18. Python startup emitted Xcode cache/event-stream warnings; the probe completed successfully.
- [Unverified — needs clone run] No suites, fixtures, git commands or hosting mutations were run here. The final gate on the integrated committed state is still outstanding. Base-to-HEAD diff, unchanged-runtime-byte claim and revision ancestry were not independently measured because git is prohibited in this turn; retained evidence is not a claim of a new integrated-head test run. Graph search found this worktree unindexed and indexing was denied by approval policy, so complete source reads were used.

Relay closed (Approved), no further review turn needed. Handing the token to Producer (codex-producer) for the final harness gate and publication workflow. Only this relay file was edited.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
