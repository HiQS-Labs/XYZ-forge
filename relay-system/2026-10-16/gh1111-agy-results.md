# RELAY · GH-1111 Agy methodology and reporting QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-16.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 3

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
6. **Commit only the relay file** (`relay(gh-1111-agy-methodology-and-reporting-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/ISSUE-REPORT.md** — the read-only path that
  `relay-drive.sh --artifact-file TESTS-RESULTS/2026-10-16+GH-1111/ISSUE-REPORT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: codex-author
- Started: 2026-10-16
- Definition of Done: truthful and reproducible experiment methodology/results reporting; explicit unresolved red gate; no runtime merge approval.

## Review packet — bounded reporting QA

Goal: independently QA GH-1111 methodology and the exact results posted at https://github.com/HiQS-Labs/XYZ-forge/issues/1111#issuecomment-6230834142. This is an evidence-only technical spike. The candidate is held after a red full gate. Approving report accuracy must not be described as approving production code or merge readiness.

Operational envelope: one local audit suite, a small exploratory benchmark on a heavily loaded shared Mac, no gate policy/routing changes and no new registered tests. Be commensurate; do not demand a CI rebuild or an unrelated process-group repair. Reviewer writes only this relay thread. No validate.sh, test/*.sh, pytest, executable fixtures or worker dispatches in the relay worktree. Narrow read-only arithmetic/data checks are allowed with scratch discipline.

Read the whole candidate file from its frozen revision, not just the current working tree: `git show c2d875fab7dd1bc3fb3648a2f7b94d60ed8fceb4:test/gh365-tier-fail-closed.sh`. Base is c9ecd0bf4c08e77765968a7bf797849658386a6e. The current branch tip deliberately restores baseline test bytes; candidate.patch and the immutable candidate commit retain the measured source. Do not misread the hold as missing implementation evidence.

Read all of TESTS-RESULTS/2026-10-16+GH-1111/SUMMARY.md, ISSUE-REPORT.md, issue-report-snapshot.json, measurements.jsonl, provenance.jsonl, ab-summary.json, controls.json, full-validation.jsonl, full-gate-context.json, aborted-publication-context.json and aborted-publication-validation.jsonl, plus measure.py and controls.py. Read the source diff and relevant router output/schema when needed. The complete frozen test-file lists are equal; the report branch adds evidence afterward. Existing graph generation is stale; use exact source/Git reads for material claims.

Answer these concrete questions:

1. Do raw timestamps, revisions, return codes and A/B/B/A order support 162.136 -> 79.101 seconds, 83.034 seconds / 51.213% reduction, N=2 each? Is the comparison explicitly limited by host load, cache/order variability, and bundled changes, with no unsupported hosted or whole-gate speedup?
2. Are all 7,412 path checks and five existing assertions retained, normalization restricted to the random fixture line, parser/membership checks accurately scoped, and expected red/mutation/restoration separated from passing measurements? Does the full candidate source introduce any material correctness regression within this bounded optimization?
3. Does the report preserve the full gate's RED 408/409, initial and retry failure, 406 executed shell suites, exact frozen candidate, explicit live-worker opt-out and clean identity/envelope? Are later isolated base/candidate greens correctly NOT used to establish root cause or erase the failure? Is the separate canceled publication attempt clearly incomplete and excluded from completed-run statistics?
4. Does ISSUE-REPORT.md match the posted snapshot exactly (allow only terminal newline normalization), and do its claims match retained evidence? Are candidate hold, restored branch-tip source, documentation-only publication and no bypass/merge claims honest? Flag unsupported claim strength or missing limitations.
5. Is the recommendation proportionate: retain an experiment with a useful focused signal, hold runtime adoption, avoid changing test selection/qualification based on this small sample? Do not turn report QA into runtime gate approval.

Output a Reviewer block with VERDICT: PASS/FAIL/PARKED, Basis (textual review of retained execution evidence vs your narrow arithmetic queries; no claimed test reruns), literal swept file: yes/no, numbered answers, graded findings with file:line or quoted evidence. Behavior-change requests require Observed input / Affected scope / Falsifier; no speculative machinery. Set STATUS: Approved only if methodology and reporting are accurate; otherwise Changes requested and hand back to codex-author. Commit only the relay thread; no push.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Producer · codex-author
**Did:** executed bounded suite optimization and retained raw A/B/control/full-gate evidence; restored baseline branch-tip test after red full gate; published exact findings to GH-1111.
**Verification:** A/B/B/A all exit 0; deliberate parser red exits 1 and saved bytes restored; three focused suites pass; full gate RED 408/409, later isolated base/candidate both pass with unresolved attribution; canceled publication excluded; evidence-only documentation gate green, no bypass. Independent review pending.
**Re-review this:** report accuracy and bounded methodology, not runtime merge approval; frozen candidate c2d875fa, all raw receipts and exact issue snapshot.
**Commit:** inputs committed before handoff.

### Round 1 · Reviewer · agy
**VERDICT:** PASS
**Basis:** Textual review of retained execution evidence (`TESTS-RESULTS/2026-10-16+GH-1111/*`, `candidate.patch`, `git show c2d875fab7dd1bc3fb3648a2f7b94d60ed8fceb4:test/gh365-tier-fail-closed.sh`, and `utils/ci-route.sh`) cross-checked with narrow read-only arithmetic/hash/inventory queries under `.relay-scratch/tmp` (exit 0); no test reruns claimed. Note: `.relay-artifacts/ISSUE-REPORT.md` was not materialized at that symlink path in this worktree, so the identical tracked artifact `TESTS-RESULTS/2026-10-16+GH-1111/ISSUE-REPORT.md` and `issue-report-snapshot.json` were reviewed directly.
swept file: yes

#### Numbered Answers
1. **A/B/B/A timings, arithmetic, and limitations:** Yes. `measurements.jsonl:1-4` and `provenance.jsonl:1-4` record serial A/B/B/A runs with `rc: 0` and `identity_equal: true` across base `c9ecd0bf4c08e77765968a7bf797849658386a6e` (`188.7676955420029` s, `135.5037056250003` s; mean `162.1357005835016` s -> `162.136` s / `162.14` s) and candidate `c2d875fab7dd1bc3fb3648a2f7b94d60ed8fceb4` (`81.144633625001` s, `77.05823966699973` s; mean `79.10143664600037` s -> `79.101` s / `79.10` s), yielding `83.03426393750124` s (`83.034` s / `83.03` s) and `51.21281965580289%` (`51.213%` / `51.2%`) reduction for N=2 each (`ab-summary.json:2-13`). `ISSUE-REPORT.md:20` and `SUMMARY.md:25` explicitly bound the result by N=2 sample size, baseline variability, high host load (`load_before`/`load_after` up to `91.91` in `ab-summary.json:21-74`), uncontrolled caches/sessions, and bundled edits, disclaiming any hosted, per-edit, or whole-gate speedup and noting `gh436-merge-cleanup.sh` as the parallel pool's final first-pass wait (`full-validation.jsonl:408`, `ended_ms: 1792219146738`).
2. **Coverage retention, normalization, controls, and full candidate sweep:** Yes. Both frozen revisions have identical 7,412-file inventories (`git ls-tree -r --name-only` == 7,412) and all four A/B/B/A runs pass all 5 assertions (`T1`, `T1b`, `T2`, `T3a RED`, `T3b RED`) with tier counts `5740 + 356 + 1316 = 7412` (`measurements.jsonl:1-4`, `ab-summary.json:15-19`). Normalization in `normalization-policy.txt:1` strips only the random `workdir:` line while preserving raw stdout and SHA-256 hashes in `measurements.jsonl:1-4`. `controls.py:12-73` and `controls.json:1-152` accurately scope the 16 classifier parser inputs (`SUMMARY.md:33` notes this is sampled equivalence, not a universal arbitrary-output proof), verify `registered_anywhere` equivalence across all 411 `test/*.sh` files (`sha256: e60e16b4641274069e9bd24a902739d4af99fb3a2f7fb31a312938f70f5e31fa`), verify failed (`rc=1`) and empty (`rc=1`) vs valid (`rc=0`) `SUBSYSTEM_REGISTRY` extraction, and isolate the expected `BROKEN` tier mutation red run (`measurements.jsonl:5`, `provenance.jsonl:5`, `expected_red: true`, `rc: 1`, `127.798` s) and its byte/identity restoration (`controls.json:140-151`, blob SHA-256 `81d451b5403068d1566030b4c5f28ab33cc16fc32e22f586710dadf79ffdd1ca`) from timing means. Sweeping the full candidate `c2d875fa:test/gh365-tier-fail-closed.sh` (lines 1-153) against `utils/ci-route.sh:79-99,499-508` confirms no material correctness regression.
3. **Full-gate RED preservation, attribution restraint, and aborted publication:** Yes. `ISSUE-REPORT.md:27-30`, `SUMMARY.md:43-49`, `full-gate-context.json:1-41`, and `full-validation.jsonl:1-414` accurately record the full parallel gate (`width: 4`, `registered: 406`, `run_set: 406`, `passed: 408`, `failed: 1`, `total: 409`, validator wall `1018.258` s, hook `1019` s, push attempt `1020.369` s in `measurements.jsonl:9`) on exact commit `c2d875fab7dd1bc3fb3648a2f7b94d60ed8fceb4` with `RELAY_SELF_SUFFICIENCY_SKIP=1`, `envelope_rc: "0"`, `envelope_drift: "none"`, and `identity_equal: true`. `gh648-l4-285-revalidate.sh` failed both pooled (`duration_ms: 9202`, `rc: 1`) and on isolated retry (`full-validation.jsonl:409-410`, `duration_ms: 7217`, `rc: 1`) with `PermissionError: [Errno 1] Operation not permitted` (`full-gate-context.json:38`). Subsequent isolated controls (`measurements.jsonl:10-11`, `11.244` s base / `11.225` s candidate, both `rc: 0`) and prior issue GH-1063 are explicitly NOT used to claim root cause or erase the red gate (`ISSUE-REPORT.md:28`, `SUMMARY.md:47`, `full-gate-context.json:36`). The canceled documentation-publication run (`aborted-publication-validation.jsonl:1`, `aborted-publication-context.json:1-15`, `run: 7fa7aa379-53471`, `terminal_summary: false`) is clearly disclosed and excluded from completed-run statistics (`ISSUE-REPORT.md:39`, `SUMMARY.md:63`).
4. **Snapshot fidelity and disposition honesty:** Yes. `TESTS-RESULTS/2026-10-16+GH-1111/ISSUE-REPORT.md:1-45` matches `issue-report-snapshot.json:3` (`https://github.com/HiQS-Labs/XYZ-forge/issues/1111#issuecomment-6230834142`, `body_sha256: 7576502ce20886c98de86bfcdd3a1e1e45d8941079f5896fb32c5a6a69e930ac`) byte-for-byte. `git diff c9ecd0bf4c08e77765968a7bf797849658386a6e HEAD -- test/gh365-tier-fail-closed.sh` is empty, confirming the branch tip restores baseline test bytes while preserving `c2d875fa` in history and `candidate.patch:1-59`. All claims regarding the held candidate, refused runtime push, no-bypass documentation publication, and non-merge-readiness (`ISSUE-REPORT.md:3,35-41`) are truthful and backed by the committed receipts.
5. **Proportionate recommendation:** Yes. `ISSUE-REPORT.md:35-41` and `SUMMARY.md:57-59` proportionately recommend preserving the candidate's focused process-avoidance win for later landing once the full-gate failure is resolved, holding production adoption now, and refraining from weakening CI selection/qualification or starting a broader CI rebuild from a small local sample. Approving this report QA attests strictly to methodology and reporting accuracy, not runtime merge readiness.

#### Graded Findings
- `[Pass]` **A/B/B/A timing arithmetic and output equivalence verified against raw receipts** — `TESTS-RESULTS/2026-10-16+GH-1111/ab-summary.json:2-20` and `TESTS-RESULTS/2026-10-16+GH-1111/measurements.jsonl:1-4` confirm base runs `188.7676955420029` s and `135.5037056250003` s (mean `162.1357005835016` s) vs candidate runs `81.144633625001` s and `77.05823966699973` s (mean `79.10143664600037` s), saving `83.03426393750124` s (`51.21281965580289%`), with all four normalized outputs identical (`tier1=5740 tier2=356 tier3=1316`, sum `7412`). Probe command (`exit 0`): `python3 -c 'import json; ab=json.load(open("TESTS-RESULTS/2026-10-16+GH-1111/ab-summary.json")); print(round(ab["base_mean_s"],3), round(ab["candidate_mean_s"],3), round(ab["saved_mean_s"],3), round(ab["reduction_pct"],3))'` -> `162.136 79.101 83.034 51.213`.
- `[Pass]` **Full candidate file sweep (`c2d875fa:test/gh365-tier-fail-closed.sh`) confirms semantics and fail-closed guards** — `TESTS-RESULTS/2026-10-16+GH-1111/candidate.patch:8-58` and `git show c2d875fab7dd1bc3fb3648a2f7b94d60ed8fceb4:test/gh365-tier-fail-closed.sh` (lines 28-40, 100-121, 141-146) replace only the 3 `grep|tail|cut` pipelines with `while IFS='=' read -r key value` over `utils/ci-route.sh:499-508`'s single-assignment `key=value` output, cache `bash "$ROUTER" subsystems` once with explicit non-zero and non-empty guards (`SUBSYSTEM_REGISTRY="$(bash "$ROUTER" subsystems 2>/dev/null)" || fail ...; [ -n "$SUBSYSTEM_REGISTRY" ] || fail ...`), and replace `$(basename "$f")` with `${f##*/}` over non-trailing-slash globs. Pre-existing file lines 1-153 were swept in full; no pre-existing defects or regressions found.
- `[Pass]` **Controls and mutation red-control isolation verified** — `TESTS-RESULTS/2026-10-16+GH-1111/controls.json:1-152` and `TESTS-RESULTS/2026-10-16+GH-1111/provenance.jsonl:5` confirm 16/16 classifier equivalence checks, 411/411 suite membership equivalence checks (`old_sha256 == new_sha256 == "e60e16b4641274069e9bd24a902739d4af99fb3a2f7fb31a312938f70f5e31fa"`), fail-closed registry checks (`rc=1` on exit 7 and empty output; `rc=0` on valid output), and `mutated-tier-red` (`rc=1`, `expected_red: true`, `original_blob_sha256 == restored_blob_sha256 == "81d451b5403068d1566030b4c5f28ab33cc16fc32e22f586710dadf79ffdd1ca"`).
- `[Pass]` **Full-gate RED receipt, unresolved attribution, and aborted publication accounting verified** — `TESTS-RESULTS/2026-10-16+GH-1111/full-gate-context.json:2-38`, `TESTS-RESULTS/2026-10-16+GH-1111/full-validation.jsonl:1,408-414`, and `TESTS-RESULTS/2026-10-16+GH-1111/aborted-publication-context.json:1-15` match every figure and caveat in `ISSUE-REPORT.md:27-39` and `SUMMARY.md:43-63`.
- `[Pass]` **Issue comment snapshot and branch-tip restoration verified** — `TESTS-RESULTS/2026-10-16+GH-1111/ISSUE-REPORT.md:1-45` and `TESTS-RESULTS/2026-10-16+GH-1111/issue-report-snapshot.json:2-4` match byte-for-byte (`sha256: 7576502ce20886c98de86bfcdd3a1e1e45d8941079f5896fb32c5a6a69e930ac`), and `git diff c9ecd0bf4c08e77765968a7bf797849658386a6e HEAD -- test/gh365-tier-fail-closed.sh` is empty (`exit 0`).

relay closed (Approved), no further turn needed


### Attestation · relay-drive — 2026-10-17T06:49:28Z
task: GH1111-AGY-RESULTS
reviewer: agy
status: Approved
reviewed-head: 21f3b7653edd14a8106d299e3f3058872a2ce9f8
added-range: 10247+9064
added-sha256: 384398ffcc7392f5a36fba1e69feafb7d66b41724554485c168f699db8792814
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
