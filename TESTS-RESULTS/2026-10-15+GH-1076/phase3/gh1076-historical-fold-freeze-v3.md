# GH1076 historical fold freeze: PR936

## Finding

**PR936 is a concrete precedent for a human-prepared, operator-approved fold through the normal local and hosted gates.** It does not depend on PR1069 batch bookkeeping, and GH1072/GH1073 do not block creating an unrelated immutable manual freeze artifact or preparing a separately approved single-landing pilot. They only matter if mutable PR1069 state is used as authoritative membership/sweep coverage/evidence-reuse input.

This report directly read [PR936](https://github.com/HiQS-Labs/XYZ-forge/pull/936), its GitHub commit metadata/compare/run records, committed fold review files and local/hosted receipts. No new suite, workflow, merge, source edit or remote write ran. PR880 was unnecessary because PR936 supplies the needed concrete example. This is historical reconstruction, not a claim a current group is ready or standing permission to reduce checks.

## Reconstructed freeze identities

The PR body retains the following **operator-approved revised order**. Current historical source PR GraphQL records retain full head OIDs matching those body prefixes; all seven source PRs are CLOSED with mergedAt=null, so they must not be counted as seven separate GitHub merges/qualifications.

| Order | Source PR | Frozen source head recovered |
|---|---|---|
| 1 | #890 planners | `d9b4811ccc9511931b0a94775e499932e1511e8f` |
| 2 | #924 Codex eligibility | `1f9007cb1203fd088df31c58cfb024fe2c1cc6a2` |
| 3 | #919 direct workhorse | `6c6946b3c7f31fe05698ca95ef8f467ee4e52763` |
| 4 | #827 handsfree | `b725c234613669dc40cfcc95b9d73865d59456d5` |
| 5 | #913 PDDA reliability | `f6e5b877b4c9155f6dd6cbba2eec9ce69a61d97d` |
| 6 | #891 relay locator | `3a3f6aab5505e8f373d3a4ad7f42dd34ea45b053` |
| 7 | #915 upstream pointer/retirement | `698cb14342286473b774679cd24dc91a12059249` |

- **Pinned integration base:** `75b75181299d605b5458dbf4fd367680a05cbb53`. Retained local gate provenance names source_base_sha; it is also the sole parent of actual squash landing ae305.
- **Final reviewed implementation plus attestation snapshot tested locally:** `4ec641ba933479881a7a62e2d84b6f2b7bdddce0`.
- **Published final candidate:** `1dc5c8fe24d94f9aed4609ed89e368e760f2447c`; GitHub commit API says its parent is 4ec641ba. Compare 4ec→1dc is exactly one commit adding five evidence files under `TESTS-RESULTS/2026-10-02+PR-fold/`; no source changes in that final delta.
- **Actual landing:** `ae30510af564356dd155e309ea99ad81c24472d5`, merged into development on October 2, 2026. It has one parent, the pinned base75b75181, so the actual landing is a squash.
- **Candidate and landed trees:** both `6f3dc9661b3ea612700c1dc40c41c69a31e27e1c`, reconstructed independently from GitHub candidate metadata and local landed Git object. Tree identity is established, but it was not substituted for actual-landed hosted qualification.
- **Downstream order explicitly kept outside fold:** fold → #925 → #903. The body requires green hosted reconciliation on the fold merge SHA and closure checks before925, superseding an earlier prerequisite. Those later PRs are not members of the seven-source fold.

This is useful freeze data; it is distributed across PR prose, Git objects, reviews and receipts rather than a single machine-validated batch manifest.

## Retained review and failure history

At landed commit ae305, `relay-system/2026-10-02/pr-fold-qa.codex.md:8–9` retains Escalated, round1/1; `:77` retains FAIL and `:85` names actual lost GH896 accepted-start state and seven GH896/GH901 work-event IDs in the first ledger rebuild. This was a real combined-state defect missed by simply considering independently ready PRs.

The subsequent bounded ledger review is Approved with PASS (`pr-fold-ledger-qa.codex.md:8–9,72`), and attestation `:99` binds reviewed-head **77ec0d5e6c95d2be4f93c475d4b898091bc95fe0**. Its scope `:78` compares complete DB/dump content against base75b75181 and pre-repair fold612ba69c639bae5719e920c25e8b45d7c2e20558; it explicitly says this is not a second whole-source audit of all seven PRs. The final receipt commit is f72e183488268b29b76e90104f2cfb13a7742db5, as retained PR prose/planner review parent metadata indicate. Keep reviewed head and containing attestation commit distinct.

Planner deployment review is Approved with PASS (`pr-fold-planner-deploy-qa.codex.md:8–9,72`); attestation `:99` binds **8b5e42fdf8cc0f404712b7fa1bb5fb81894cb578**, not final1dc. Its candidate-bebdde27 versus parentf72 comparison (`:80`) proves exactly four changes: removing both direct planner installers and correcting planner layout/deployment guidance. The containing attestation becomes4ec641ba, which the local full gate tested.

The PR body retains an initial local-full FAIL atf72: GH678 exposed installers replacing a live managed link, and inherited XYZ_HARNESS caused twelve fixture failures also reproduced on development. Both are disclosed, followed by a new clean-clone full run after removing installers and unsetting that override. Do not flatten initial FAIL → later PASS into an unqualified first-try pass or imply the focused delta reviews attested every final file.

## Qualification evidence and its limits

`TESTS-RESULTS/2026-10-02+PR-fold/provenance.jsonl:1` retains command `env -u XYZ_HARNESS bash ci-local.sh --base origin/development`, head4ec641ba, base75b75181, exit_code0, start/end and before/after clone identity. SUMMARY.md:3–5 explicitly distinguishes local evidence from hosted promotion. The retained gzip log ends with all steps passed and the local/non-promotion caveat. Its provenance digest cb42ea03eca16ce9a72af37ca9325221a0dc5be0260c5e2373508dde7fec8ce3 matches **decompressed log bytes**; compressed artifact bytes hash e0710005a177a2bafc36da2e30fafa91d9bd8505b525ab32bfb4e8ad0f892dca. This hashing convention should be made explicit in a future freeze record; it is not an observed payload mismatch.

PR936 body separately reports full pre-push success at1dc in a fresh clone,858seconds, no bypass, after an initial refused push with inherited XYZ_HARNESS. This report read the body; it did not locate a separately committed complete pre-push log in the five-file fold receipt directory. Treat858s/no-bypass as retained author disclosure rather than an independently replayed qualification.

The actual landed snapshot has committed `wave-qualification@1` evidence under `TESTS-RESULTS/2026-10-02+GH-591/wave-ae30510af564356dd155e309ea99ad81c24472d5/`:

- `provenance.jsonl:1`: PR936, landing_commit=tested_commit=ae305, sequential full gate, result pass, rc0,413/413, run URL [37069893468](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/37069893468), telemetry SHA256674a511927fb1259992509234029d2dfe7ec5c7135bd6bf8dc871866c5024973.
- The retained validation bytes match that digest. run.start says exact commit ae305, sequential,width1,tier3,410registered. run.summary says413passed/0failed, run_set410/registered410, matching suite events, envelope0/no drift. No nonzero event RC or suite skip_lines appeared in the source-read JSONL inspection.
- The same telemetry also has separate historical PR900 and PR902 receipt rows (`provenance.jsonl:2–3`), proving one integrated snapshot covered those already landed items too. This is not seven individual source PR landing receipts.
- GitHub run API currently reports completed/success, reconcile job succeeded. Its event/head metadata names PR source head1dc, whereas strict retained telemetry pins **actual tested landing ae305**. Use the receipt to identify tested code; do not infer test identity from eventhead alone.
- Reconciliation evidence was subsequently committed in `be535e438a4e04b550e8f65b5e64b1a647f144ca` (Git history of receipt path). This is development qualification, with no main promotion/stability claim.

## Concrete fields a new manual freeze should add

The example already retains order, full recoverable member heads, base, final candidate, actual landed SHA/tree, scoped review identities, exact local-tested snapshot, actual-landed hosted result and known integration decisions. It is inaccurate to label all batching unsupported. The gaps found in the inspected artifacts are narrower:

1. One immutable freeze ID/document with source and retrieval provenance, rather than relying on editable PR prose and reconstructing full heads later. Include per-member head and reviewed head **as separate fields**, source bases/merge-bases if required for replay, and the approved ordering/dependency rationale.
2. The exact composite preparation recipe and intermediate result mapping: member heads were transformed (installer removal, supported ledger replay, cursor repair), so final candidate must bind all conflict/manual delta commits and their scoped review receipts. Record candidate changes invalidating freeze; do not treat original source head approvals as approval of altered combined behavior.
3. Runtime/dependency compatibility identity: the local pack records override removal and required programs, but lacks a normalized OS/runtime/version/environment policy fingerprint. Tracked lockfiles/policy can be read from the pinned tree, yet runtime installation/host environment remains distinct. Avoid cross-candidate reuse in the smallest pilot.
4. Explicit rollback baseline/target/group/owner. Actual single-squash landingae305 and parent75b75181 provide concrete reversible anchors, but no named rollback decision/command or owner was located in the PR body and inspected fold artifacts. This is a gap for a new approved fold plan, not authorization to revert historical work.
5. Checked result links and hash encoding semantics for every claimed phase; preserve original failed attempts and distinguish local full, pre-push, PR checks and actual-landed hosted qualification. Add one current exact-head combined review before landing if changes exceed the retained scoped review coverage.

These can be a manually maintained, reviewed freeze artifact using existing gate/receipt mechanisms. A new batch database, runner, policy framework or PR1069 runtime change is unnecessary for that bounded pilot. Any proposal to reduce required checks still needs separately reviewed policy/protection/workflow compatibility; historical approval for936 is not standing approval for a new group.

## Current queue and next boundary

The supplied open-pr-freeze-inventory contains1079draft,1069current4691,1068current52c39,1062currentfad5,1053draft,1024draft/held-history,930draft/titleHOLD. Prior user instructions skip1062, defer1068, and preserve1024hold/caps. The inventory supplies no current exact-head reviews, completed required checks, owner handoffs or compatible approved dependency group. **No current fold is selected or declared ready.** A single-landing shadow pilot or manual freeze template can be prepared independently, then grounded in a later explicitly approved eligible group. The present investigation grants no merge, test admission or gate reduction.
