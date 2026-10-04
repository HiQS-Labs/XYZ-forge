# RELAY · GH-955 plan QA — centralized downstream publisher
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-03.
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
6. **Commit only the relay file** (`relay(gh955-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- **Artifact under review:** `PROJECT/1-INBOX/GH-955-CENTRAL-DOWNSTREAM-PUBLISHER.md` (the plan). This is a plan review; no code has been written yet.
- **Reviewer:** codex · **Producer:** claude-a · **Started:** 2026-10-03
- **Operational envelope:** a local developer CLI that the operator runs occasionally on one Mac to refresh three small downstream repos. Grade against the stated requirements and commensurate complexity, not enterprise multi-tenant threat models. XYZ-forge forbids new test suites (GH-831); new checks go into existing suites as assertions.
- **Requirements (operator, verbatim intent):**
  - XYZ-forge is upstream again for every standalone repo, reversing #882 / XYZ-skills-army-mini#2.
  - One centralized publisher, including Skills Army HQ and Agent Chorus.
  - It can target one repo or many in one run.
  - The HiQS org scan confirms the downstream set.
- **Source paths to read (ground truth):**
  - `utils/py/xyz_mini_sync.py` (the publisher being generalized; just reworked by #950)
  - `test/gh589-xyz-mini-sync.sh`, `test/gh620-skills-army-mini-sync.sh`
  - `skills/2-daily/agent-chorus/sync-to-standalone.sh`, `skills/2-daily/agent-chorus/publish-manifest.tsv`, `skills/2-daily/agent-chorus/standalone/ci.yml` (the second publisher and the child CI that calls it)
  - `skills/3-weekly/skills-army-hq/UPSTREAM.md`, `skills/3-weekly/push-to-skills-army-mini/SKILL.md`, `skills/3-weekly/push-to-xyz-mini/SKILL.md`, `skills/README.md`, `ROUTER.md`, `utils/ci-route.sh`, `mini/ADAPTATIONS.md`
- **Definition of Done (for the plan):** every requirement maps to an ordered step with inline verification. Claims match the actual paths. The plan extends the existing publisher instead of adding a parallel one. Migration risks (child CI, adoption of a child with no MANIFEST.txt, the #934 edits) are handled. Checks are falsifiable without new suites. The rating rationale is grounded.

### Questions for the Reviewer
1. **Grounding.** Are the plan's factual claims true at the cited paths? In particular: the comparison table of the two publishers; the child CI calling `sync-to-standalone.sh --check` and a smoke path that does not exist in the child; the forge sources' modes matching the TSV's 644/755.
2. **DRY.** Does generalizing `xyz_mini_sync.py` in place (`publish_one` + a multi-target loop + profiles) avoid a second subsystem? Is anything in steps 1–6 duplicative or speculative?
3. **`--adopt`.** Is it the smallest safe way to bring AgentChorus-Skill (no MANIFEST.txt, a `.xyz-canonical-revision` marker) under the ownership guard? Is there a simpler correct path, for example a one-time manual MANIFEST.txt commit in the child?
4. **`--check`.** Is a read-only check the right replacement for the bash `--check` the child CI calls? Is comparing managed paths and `source_sha` enough, given that adapted and seed paths are skipped?
5. **Multi-target semantics.** Continue on failure, worst exit code wins, `--dest` refused for more than one target, fixed order. Is anything missing that would cause a wrong publication?
6. **Missing requirements.** Is anything the operator asked for unmapped? Is any #882 reversal surface missing from step 7 (`grep` the repo for `UPSTREAM.md`, `push-to-skills-army-mini`, `#882`, `skills-army-mini is upstream`)?
7. **Over- or under-engineering.** Flag machinery not commensurate with an occasional-refresh local CLI.

Cite `file:line` for every finding. Behaviour-change requests carry `Observed input:`, `Affected scope:` and `Falsifier:` lines.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: Generalizing the existing publisher is the right scope, but the migration/retry contract and several acceptance criteria need correction before implementation.
swept file: yes

Reviewed the entire 177-line plan, the complete Python publisher and Bash publisher, both named publisher suites, the TSV/CI, and the cited policy surfaces. This is a static plan review, not implementation approval. The worktree has no matching graph project: `list_projects` returned 77 projects with no matching root; `check_index_coverage` for this root returned “project not found or not indexed.” Used exact-source fallback (Verify intent; no graph generation available). No git command, executable fixture, or suite was run. Runtime predictions below are **[Unverified — needs clone run]**. The whole-file sweep found the issues below; no additional plan defects are asserted.

- **[Should] F1 — Adoption must compose with retained-commit retry.** Plan `PROJECT/1-INBOX/GH-955-CENTRAL-DOWNSTREAM-PUBLISHER.md:98` preserves the single-target body, while lines 110–113 reject adoption once MANIFEST.txt exists and remove the old revision marker. The existing retry verifier at `utils/py/xyz_mini_sync.py:218` has an empty previous set when the remote lacks MANIFEST.txt; line 236 rejects each previously existing managed file, and line 220 does not allow deletion of `.xyz-canonical-revision`. Thus an adoption `--apply` followed by `--push`, or a failed first push, needs a deliberately specified recovery path. Cheapest option: compare a one-time reviewed MANIFEST.txt bootstrap committed/pushed in the child against keeping a permanent `--adopt` flag. If retaining the flag, explicitly extend only the proven adoption retry and preserve the unrelated-change refusal.
  Observed input: plan line 144 says “`--adopt` once for agent-chorus, then `--push`”; the existing retry code rejects remote-existing files absent from the remote manifest (line 236).
  Affected scope: the first adoption commit while origin still has the legacy marker and no MANIFEST.txt; ordinary retries must remain strict.
  Falsifier: in a disposable full clone, adopt with `--apply`, then retry with `--push`; expect the exact retained commit to push, while an amended unrelated file still refuses. Repeat with an induced first push failure. Runtime outcome not executed here.

- **[Should] F2 — Define a separate read-only check path suitable for child PR CI.** Plan lines 117–121 promise parity checking, but the existing shared path calls `destination_ready` (`utils/py/xyz_mini_sync.py:322`), which requires destination branch `main` and reads origin/main (lines 195–205). The child workflow runs on `pull_request` (`skills/2-daily/agent-chorus/standalone/ci.yml:6`) and uses checkout without a branch override (line 15). Specify that `--check` bypasses publication branch/history/write preconditions, supports detached child checkouts, and rejects combinations with `--apply`/`--push` rather than permitting ambiguous writes. Add exit 1 to the multi-target precedence, which currently omits it (plan line 98). Skipping seed/adapted byte comparisons is appropriate to their ownership contract; label the result managed parity, not whole-child identity.
  Observed input: child PR workflow at `standalone/ci.yml:6`, and `destination_ready`'s literal `destination must be on branch main` at `xyz_mini_sync.py:197`.
  Affected scope: `--check`, including multi-target check aggregation and conflicting write flags.
  Falsifier: a detached, byte-matching child passes without querying origin/main; a managed byte or mode change returns 1 naming the path; a mixed matching/drifting target run returns 1; conflicting write flags leave bytes/index/HEAD untouched. Run in a disposable clone.

- **[Should] F3 — Correct the Agent Chorus payload accounting and explicitly disposition the legacy TSV in the child.** Plan lines 106–108 and 137 say 15 TSV/payload paths, but `skills/2-daily/agent-chorus/publish-manifest.tsv:2` through line 15 contain **14** rows, leaving **13** payload rows after dropping the TSV. The old 15-file total includes the old revision marker. Adoption removes that marker but currently preserves the old TSV as destination-only content (plan lines 112–114); deleting the forge TSV alone does not retire the child's stale manifest. Name that exact legacy path for deliberate migration removal (or explicitly document its retention), and distinguish payload copies, metadata writes, and deletions in the expected preview.
  Observed input: TSV line 14 ships `skills/agent-chorus/publish-manifest.tsv`; this path is excluded from the new profile and the child has no old MANIFEST.txt to drive deletion.
  Affected scope: first Agent Chorus adoption and its literal expected file set, not unrelated child files.
  Falsifier: the adopted child contains the 13 intended payload files plus MANIFEST.txt and `.xyz-forge-revision`, with both legacy metadata paths absent if retirement is selected; an unrelated tracked note survives.
  Probe (exit 0): `python3 -` with `rows=[l.split("\t") for l in Path("skills/2-daily/agent-chorus/publish-manifest.tsv").read_text().splitlines() if l and not l.startswith("#")]; print(len(rows)); print(sum(not r[2].endswith("publish-manifest.tsv") for r in rows))` (after `from pathlib import Path`). Decisive output: `14`, `13`. A same-run filesystem mode comparison, `[(s,m,oct(Path(s).stat().st_mode & 0o777)) for m,s,d in rows if int(m,8)!=(Path(s).stat().st_mode & 0o777)]`, printed `[]`; this verifies checkout modes, not Git index modes.

- **[Should] F4 — Include the existing gh620 payload assertion in the un-retirement edit.** Plan lines 102–104 only drop the opt-in/default refusal; line 126 deletes UPSTREAM.md. `test/gh620-skills-army-mini-sync.sh:69` still requires UPSTREAM.md in the literal set, and line 75 calls the set ten managed payloads. Explicitly update this existing expectation to the nine-file payload, retaining the exact-set assertion.
  Observed input: literal `"UPSTREAM.md"` in the existing `expected` set (line 69).
  Affected scope: gh620's package set and its stale retirement comments; no new suite.
  Falsifier: after the planned deletion, the existing suite passes with nine payloads and fails if a required payload is omitted. **[Unverified — needs clone run]**; static mismatch established, no suite executed.

- **[Should] F5 — Give multi-target continuation a behavioral acceptance check.** Plan line 100 tests only argument refusal and manifest listing; neither exercises the loop/summary/worst-exit contract in line 98. Add a manual recorded check or an assertion in the existing suite with one refused target and a later successful target, checking both outcomes and the aggregate exit. Also state deduplication for repeated targets/`all` so one selection means one publication per target.
  Observed input: the two proposed checks at plan line 100 never publish to multiple destinations.
  Affected scope: target selection/iteration and failure aggregation only.
  Falsifier: deliberately short-circuit the loop after the first refused target; the acceptance check must turn red because the later target was not processed. Include a secret refusal if claiming exit-4 precedence is verified.

- **[Should] F6 — Disposition the transferred issue ownership when reversing #882.** Step 7 and closing actions omit the transferred backlog. `PROJECT/2-WORKING/GH-882-SKILLS-ARMY-UPSTREAM.md:35` names forge #506/#676/#837/#881 moved to mini #4/#5/#6/#7; `PROJECT/4-MISC/GH-506-SKILLS-ARMY-HQ-REPLICATE.md:5` remains superseded specifically because upstream moved. Add an explicit ownership decision/reconciliation step (or an explicit deferral with a canonical pointer), without implementing that backlog. Merely commenting on mini#2/#3 does not settle where future work should land.
  Observed input: the four issue transfers in GH-882 line 35 and #506's superseded reason.
  Affected scope: issue/doc/ledger routing for those transferred items, not their features.
  Falsifier: each transferred item retains a single explicit canonical work location consistent with the restored forge upstream; no duplicate active execution plans.

- **[Pass] Architecture and main CI diagnosis are grounded.** `xyz_mini_sync.py:99` already has per-target profiles, so extracting one target operation and looping is a proportional extension, with no need for another module. The old CI invokes the Bash checker at `standalone/ci.yml:24` and the wrong smoke path at line 26; the TSV maps that smoke script to `skills/agent-chorus/test-standalone.sh` at line 15. The comparison table broadly matches the publishers; “destination-only refused” should be qualified as **tracked** files (`sync-to-standalone.sh:83`).
- **[Unverified — no citation] Remote inventory/history and rating inputs.** Plan lines 37–48 and 177 assert all-21-repo coverage, downstream non-divergence, #934 history, and CI chronology without a durable query receipt. I did not query remote state this turn. Keep the rating provisional and cite the scan/history/run evidence (including the #934 source SHA/diff and preservation check) before treating these assertions as established. Q1's fourth-repo uncertainty is correctly exposed at line 164 and must be resolved before claiming every downstream is covered. Local severity/effort rationale is plausible; recurrence chronology is not independently verified.

Handing off to Producer (claude-a) — revise the plan, disposition F1–F6, and open Round 2. No approval; STATUS remains Open.

### Producer · Round 1 (claude-a)

Dispositions (full table in the plan's "Plan QA dispositions: round 1" section):
- **F1 Modified.** The `--adopt` flag is dropped. A one-time reviewed setup commit in AgentChorus-Skill (plan step 4) writes MANIFEST.txt with the 13 payload paths and removes both legacy paths. The publisher and retry logic need no special case.
- **F2 Implemented.** Step 5 makes `--check` a separate read-only path that skips `destination_ready`, is detached-safe, is refused with `--apply` / `--push`, and puts exit 1 in the precedence.
- **F3 Implemented.** The plan now says 13 payload rows; the setup commit removes the legacy TSV and the marker.
- **F4 Implemented.** Step 2 updates gh620's exact set to nine files.
- **F5 Implemented.** Step 1 adds a behavioural two-target continue-on-failure assertion with a red control, plus dedup.
- **F6 Implemented.** Operator decision Q5: transfer mini #4–#7 back to the forge after merge, then re-point through the writer.
- **Unverified remote claims:** receipts committed under `TESTS-RESULTS/2026-10-03+GH-955/recon/`.

Operator answers (2026-10-03): Q1 only the 3 active repos; Q2 one skill, `push-downstream`; Q3 the central "child files survive" rule; Q4 keep the filename; Q5 transfer the issues back.

Requesting Round 2 review of the revised plan.

### Reviewer · Round 2

VERDICT: FAIL
Basis: F1–F6 are addressed at plan level; one evidence/preservation gap remains before approval. The central publisher design is proportionate and needs no additional subsystem.
swept file: yes

Swept the entire revised plan (210 lines), both publisher implementations, both named publisher suites, the TSV/child CI, policy excerpts and all six new recon receipts. No additional plan defects beyond the findings below were identified in this sweep. Verify-tier intent: list_projects returned all 77 entries without this root; check_index_coverage returned “project not found or not indexed”, so exact-source fallback was used; no graph generation is claimed. No git command, suite or executable fixture was run. Implementation outcomes remain **[Unverified — needs clone run]**.

- **[Pass] F1–F6 dispositions accepted as specifications.** Plan lines 117–126 replace permanent adoption machinery with a pushed ownership bootstrap; this supplies the prior manifest used by the existing retry verifier at `utils/py/xyz_mini_sync.py:218` and ownership guard at line 328. Plan lines 128–137 define detached-safe, read-only checking; lines 100–107 define deduplication and a falsifiable continuation check; lines 111–114 correct the payload counts; lines 160 and 188 explicitly return backlog ownership. These are approval of the stated contracts, not claims that the unbuilt implementation passes.

- **[Should] F7 — Finish the evidence receipt and make #934 preservation measurable.** `PROJECT/1-INBOX/GH-955-CENTRAL-DOWNSTREAM-PUBLISHER.md:47` calls the new files receipts for the factual claims, but the seeded evidence directory has no `provenance.jsonl`. `TESTS-RESULTS/2026-10-03+GH-955/recon/gh934-diff.txt:1` names a source SHA, while lines 2–4 contain only a diffstat; neither edit is visible. Step 7 (plan line 147) promises both edits, but its verification at line 151 only names path-integrity, the skill suite and duplicate-plan checking. Cheapest correction: capture the actual two SKILL.md hunks against a named comparison revision, attach truthful command/exit/source provenance for the recon captures (re-run queries if original attribution is unavailable), and add an explicit acceptance check that those two hunks survive in forge and the first downstream publication. Do not invent retrospective provenance. The required provenance contract is AGENTS.md, “Verified beats plausible”.
  Observed input: the six nonempty receipt files include zero provenance files, and gh934-diff.txt is a 269-byte diffstat with no patch hunks.
  Affected scope: attribution of the plan's remote recon claims and preservation of the two already-identified #934 edits only; no new runtime feature or suite.
  Falsifier: a receipt with the actual two hunks, named source/base SHAs and successful query provenance, plus a planned exact comparison that fails when either edit is omitted, resolves this finding.
  Probe (exit 0): `python3 -` with `from pathlib import Path; root=Path("TESTS-RESULTS/2026-10-03+GH-955"); files=sorted(p for p in root.rglob("*") if p.is_file()); print("receipt_files:",len(files)); print("provenance_files:",len(list(root.rglob("provenance.jsonl")))); p=root/"recon/gh934-diff.txt"; s=p.read_text(); print("gh934_receipt_bytes:",p.stat().st_size); print("has_patch_hunk:",any(l.startswith("@@ ") for l in s.splitlines()))`. Decisive output: `receipt_files: 6; provenance_files: 0; gh934_receipt_bytes: 269; has_patch_hunk: False`. This is a static evidence check, not a remote re-query.

- **[Nit] Make the bootstrap one-liner's serialization explicit.** Plan line 121 mentions `--print-manifest`; the existing implementation emits JSON triples at `utils/py/xyz_mini_sync.py:265`, whereas the ownership reader consumes whitespace-separated destination paths at line 309. The documented one-liner should select agent-chorus, decode JSON and emit exactly its 13 destination paths, one per line; raw redirection is not the bootstrap format. The planned disposable-clone adoption check should catch a mistake here; no new CLI flag is needed.

- **[Nit] Name the short bootstrap CI gap.** Plan lines 118–121 push deletion of the old marker before the first publication installs the new workflow. The old workflow still reads that marker at `skills/2-daily/agent-chorus/standalone/ci.yml:19`. Explicitly label this intermediate commit's expected failing CI and require a successful child workflow at the first published SHA before calling migration complete. The final publication's workflow/payload atomicity at plan line 178 is sound; it does not cover the earlier setup commit.

Handing off to Producer (claude-a) — resolve F7 and clarify the two bootstrap notes, then open Round 3. STATUS remains Open; no approval or self-commit.

### Producer · Round 2 (claude-a)

- **F7 Implemented.**
  - The recon queries were re-run and their outputs rewritten. `TESTS-RESULTS/2026-10-03+GH-955/provenance.jsonl` records command, exit code, bytes and timestamp per receipt.
  - `recon/gh934-skill-hunks.patch` holds the actual hunk, with base `5c67ae05e9fa` and source `a2af20b16df5`.
  - Plan step 7 adds an exact preservation check: `git diff a2af20b16df5 HEAD -- skills/3-weekly/skills-army-hq/SKILL.md` must be empty. After the first publication, `--target skills-army-mini --check` must pass.
- **Nit (serialization) Implemented.** Step 4 decodes the `--print-manifest` JSON triples into the 13 destination paths, one per line.
- **Nit (CI gap) Implemented.** Step 4 labels the setup commit's expected CI failure. Migration is complete only when the child CI is green at the first published SHA.

Requesting Round 3 review.

### Reviewer · Round 3

VERDICT: PASS
Basis: F7 and the bootstrap clarifications are resolved at plan level. The ordered work covers the three agreed downstreams, extends the existing publisher, and defines falsifiable migration and preservation checks. The remaining nits are bookkeeping, not implementation blockers.
swept file: yes

Swept the entire 222-line plan, both publisher implementations, both named suites, TSV/child CI, routing/policy source excerpts and all current recon receipts. No additional substantive plan defects were identified, including in its pre-existing sections. Applied the SWE review rubric within the stated occasional-local-CLI envelope. Verify-tier intent: list_projects returned 77 projects (has_more=false), none matching this checkout; check_index_coverage returned “project not found or not indexed.” Exact-source fallback was used; no matching graph generation is claimed. No git command, suite, pytest or executable fixture was run, and no remote query was re-run by this reviewer.

- **[Pass] F7 closed as a plan/evidence correction.** `TESTS-RESULTS/2026-10-03+GH-955/provenance.jsonl:1` through line 6 now attribute the six query outputs with commands, exit codes and timestamps; line 6 names the patch base and source SHAs. `recon/gh934-skill-hunks.patch:6` contains a real hunk, including both local-working-tree freshness wording and the immediate symlink read-through boundary. Plan `PROJECT/1-INBOX/GH-955-CENTRAL-DOWNSTREAM-PUBLISHER.md:148` applies that patch; lines 154–155 require an empty source comparison and downstream managed parity. These are measurable acceptance criteria, not executed preservation results.
  Static probe (exit 0): `python3 -` with `import json; from pathlib import Path; r=Path("TESTS-RESULTS/2026-10-03+GH-955"); rows=[json.loads(l) for l in (r/"provenance.jsonl").read_text().splitlines()]`, then counted records, checked each output exists/nonempty, compared recorded byte sizes with `stat().st_size`, and counted patch lines by `@@ ` / `+` / `-` prefixes excluding headers. Decisive output: `provenance_rows 6 all_exit_zero True; missing_or_empty []; hunks 1 added 12 removed 2; org_rows 21 marker_rows 21`. Size discrepancies are disclosed below. This establishes receipt presence/content, not independent authentication of the producer's historical query execution.
- **[Pass] Bootstrap notes closed.** Plan line 121 explicitly decodes manifest JSON into 13 destination paths, matching the ownership reader at `utils/py/xyz_mini_sync.py:309`; plan line 122 labels the expected intermediate CI failure and requires green child CI at the first publication SHA. Lines 125–127 retain payload, unrelated-file-survival and missing-bootstrap refusal criteria.
- **[Pass] Earlier dispositions remain intact.** Plan lines 98–107 retain deterministic deduplication, continuation and its red control; lines 128–138 retain detached-safe read-only checking and conflict refusal; lines 144–168 cover upstream reversal, preservation and transferred backlog ownership. The existing implementation's per-target profiles (`utils/py/xyz_mini_sync.py:99`) remain the single publisher extension point. No new subsystem or permanent adoption flag is proposed.
- **[Nit] Correct two receipt byte counts.** `TESTS-RESULTS/2026-10-03+GH-955/provenance.jsonl:5` records 583 bytes but its CI output is 587 bytes; line 6 records 2213 but the patch is 2215 bytes. Command `wc -c TESTS-RESULTS/2026-10-03+GH-955/recon/agentchorus-ci-runs.txt TESTS-RESULTS/2026-10-03+GH-955/recon/gh934-skill-hunks.patch` exited 0 and printed `587`, `2215`, total `2802`. Fix the metadata from the actual byte lengths; the nonempty patch and its two edits are present, so this does not reopen F7.
- **[Nit] Refresh the status row when advancing to execution.** Plan line 23 still says “QA round 2, then execution”; update it to reflect this completed third-round plan review.
- **[Unverified — needs clone run] Implementation and publication outcomes.** Plan lines 124–138 and 153–160 remain future checks. Approval here is permission to implement the reviewed plan, not a claim that any runtime gate, publication, preservation comparison or child CI has passed. The harness/implementation phase must supply those receipts.

Relay closed (Approved), no further review turn needed. Producer (claude-a) receives the approved plan for implementation and the two bookkeeping nits; the harness owns the file-scoped commit.


### Attestation · relay-drive — 2026-10-03T19:41:14Z
task: RELAY-gh955-plan-qa
reviewer: codex
status: Approved
reviewed-head: ecd1aa96f2294e5225942703940289f60f3fd6e6
added-range: 25202+4482
added-sha256: c8fd26b11b1b64a34943cd0711189bd8d2179893455ebb119ad1d1e68c662168
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
