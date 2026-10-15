# RELAY · GH1076 end-to-end implementation plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-15.
-->

NEXT: Producer
STATUS: Escalated
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
6. **Commit only the relay file** (`relay(gh1076-end-to-end-implementation-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup

Operational envelope: one XYZ Forge developer-tooling policy change in an operator-owned isolated full clone. Full issue1076 is requested end-to-end; no coverage weakening without sufficient evidence, no new individual CI assertion/case/parametrization without Noel approval, no merge/protection/deployment/install/activation. Actual Agy+Claude advisory consult runs separately; this is the required independent Codex plan review, normal3-round cap. Source basef974fcee, plan source3ccbb4e1. Read the complete plan plus existing router/selector/receipt contracts and relevant existing tests. Do not run suites in a linked review worktree. The earlier spike is issue1076 comment6186021918; the plan incorporates its source findings.

Questions:
1. Does the plan meet authorized whole-issue scope without falsely claiming unproved Medium coverage or unsafe batch readiness? Identify exact prerequisite ownership/decision boundaries.
2. Is additive versioned hosted decision output plus existing wave consumer full fallback the smallest safe consolidation? Preserve historical receipt replay, fixed commands, non-shell stages and exact-main full.
3. Is widening known markdown package input to its existing publication consumer area grounded and minimally sufficient? No new framework or CI cases.
4. Are matched before/after full-suite measurements, identity bracketing, host serialization, failure/skips/retries attribution and natural-hosted-only comparisons sufficient and honest?
5. Are intake/ratings, dependency/rollback plan and existing-check/red-control verification commensurate? Do not demand speculative framework or tests. Any behavior-change finding needs concrete observed input, affected scope and falsifier; blockers need observed failure.

- Artifact under review: **.relay-artifacts/GH-1076-CI-POLICY.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/1-INBOX/GH-1076-CI-POLICY.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-15
- Definition of Done: the complete scoped plan satisfies the five concrete Setup questions and preserves stated safety/coverage/test-admission limits; source-linked findings and unknowns are explicit.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PARKED
Basis: Required seeded review input is absent. This is an input-delivery finding, not a rejection or approval of the implementation plan.
swept file: no

- [Blocker] Setup names `.relay-artifacts/GH-1076-CI-POLICY.md` and explicitly directs the reviewer to read the seeded artifact there. That file does not exist in this review worktree. The complete canonical `PROJECT/1-INBOX/GH-1076-CI-POLICY.md` was readable, but its presence does not establish that it is the intended immutable seed at plan source `3ccbb4e1`. Concrete fix: have the Producer/harness seed the named artifact from the intended plan revision, then return for whole-file review; do not substitute an unverified artifact identity.
  Observed input: `.relay-artifacts/GH-1076-CI-POLICY.md` is absent; `.relay-artifacts/` contains only `gh182-claim-guards.md`.
  Affected scope: this relay's required plan input and the resulting approval, not router/selector behavior.
  Falsifier: the named seeded file exists, is nonempty, and is attributable to the intended plan revision; expected result is a readable complete plan suitable for the requested source-contract review.
  Probe: `python3 -B -c 'from pathlib import Path; p=Path(".relay-artifacts/GH-1076-CI-POLICY.md"); print("seeded_artifact_exists=" + str(p.is_file())); q=Path("PROJECT/1-INBOX/GH-1076-CI-POLICY.md"); print("canonical_plan_exists=" + str(q.is_file())); raise SystemExit(0 if p.is_file() else 2)'` → exit **2**, decisive output: `seeded_artifact_exists=False`, `canonical_plan_exists=True`. Initial `cat .relay-artifacts/GH-1076-CI-POLICY.md` also returned `No such file or directory`.
- [Unverified — needs clone run] No suites, executable fixtures, or mutation probes ran. No conclusion about Medium coverage, batch readiness, receipt compatibility, performance, or pre-existing source defects is established by this turn. The requested whole-file/source-contract sweep remains outstanding.

Handing off to Producer (codex-producer) — restore the intended seeded review input, then return the relay to Reviewer. No artifact/source edits or git commands were performed by this reviewer.

### Producer · Round 1

Disposition: Implemented — the first drive omitted `--artifact-file`, so the required seed was absent. Production code is unchanged. Next drive explicitly supplies the committed plan at `PROJECT/1-INBOX/GH-1076-CI-POLICY.md`; source3ccbb4e1, SHA256 `e35904609790f9f7886ea6e5b56d9d276780d78dd5d67757820806fe4ec84f3d`. Normal3-round cap and original PARKED review remain; this is round2, not a new/reset review. Filled the scaffolder's Definition of Done with the existing Setup questions.

Handing off to Reviewer — read the complete seeded plan and source contracts.

### Reviewer · Round 2

VERDICT: PASS
Basis: The complete seeded plan meets the five Setup questions as a coverage-preserving implementation plan with explicit readiness prerequisites. Approval does not attest implementation, live dependency state, Medium coverage, batch readiness or performance results.
swept file: yes

- [Pass] Required seed restored: the complete 152-line artifact is nonempty (10,918 bytes), and its SHA256 matches the Producer's recorded `e35904609790f9f7886ea6e5b56d9d276780d78dd5d67757820806fe4ec84f3d`. Read the whole artifact, including existing scope, phase gates and rollback; no additional pre-existing plan defect found. Probe: `python3 -B -c 'from pathlib import Path; import hashlib; p=Path(".relay-artifacts/GH-1076-CI-POLICY.md"); b=p.read_bytes(); print("bytes=",len(b)); print("sha256="+hashlib.sha256(b).hexdigest())'` → exit **0**, decisive output: `bytes= 10918`, matching digest above.
- [Pass] Scope and ownership are honest: artifact lines 100–118 require an assessment of batch identities/dependencies/rollback and Medium evidence, preserve per-PR gates and bounded recovery, name GH1064/PR1069 and GH1072/GH1073, and explicitly prohibit calling unsupported umbrella capabilities complete. Lines 66–76 require registration/rating readback, prior-art/writer checks and independent review before code; lines 149–152 retain new-case approval and evidence dependencies. Live PR/owner state must be refreshed during execution; this turn does not certify it.
- [Pass] Smallest consolidation fits the actual contracts. Artifact lines 80–88 extend the existing router and wave consumer, retain fixed dispatch and fail full on absent/unknown/duplicate/malformed decisions. Current `utils/py/wave_reconcile.py:593–619` owns the duplicated tier-to-gate translation; `:461–477` defines the two fixed gates and historical Small lookup, and `:531–571` checks schema, hash, tested-commit list and ancestry. Preserving @1 replay avoids an unnecessary receipt migration. Artifact lines 94–96 preserve registries and main/full; `.github/workflows/ci.yml:151–203` pins exact-main push and full sequential promotion. `validate.sh:922–924` enables PDDA/Python for Small; these stages remain required.
- [Pass] Package widening is grounded in current input, without implying representative Medium catch-rate evidence. Probe commands: `printf '%s\n' skills/3-weekly/skills-army-hq/BOT-DAILY-HEALTH-CHECK.md | bash utils/ci-route.sh push` and `printf '%s\n' skills/3-weekly/skills-army-hq/scripts/sync.py | bash utils/ci-route.sh push` → both exit **0**. Decisive output: markdown `route=docs`, `tier=1`, empty `tier2_subsystems`; script `route=fast`, `tier=2`, `tier2_subsystems=skills-army-hq`, with `gh620-skills-army-mini-sync.sh` in `tier2_tests`. The literal Small registry omits that suite (`utils/ci-route.sh:38`); the existing publication area includes it (`:33`), the publisher projects the package (`utils/py/xyz_mini_sync.py:98–100`), and the existing payload pin checks its literal file set (`test/gh620-skills-army-mini-sync.sh:63–75`). Artifact lines 89–96 address that precedence miss and retain hosted Medium/full. No extra framework or CI case is needed to specify the fix.
- [Pass] Verification and measurement criteria are proportionate: artifact lines 68–71 and 122–138 require matched width4 full runs in disposable full clones, host serialization, identity brackets, retained first failures/skips/retries, final review, typed attribution, normal push gates and exact-head hosted outcomes. They label one pair descriptive and restrict hosted comparison to naturally occurring equivalent jobs. Existing receipt checks include red/partial/drift/empty/wrong-run refusal (`test/gh425-gate-provenance-pr.sh:360–367`) and malformed telemetry rejection (`:395–406`); planned manual red controls complement existing checks without new assertions. Execution must commit provenance/raw evidence under the repository's existing TESTS-RESULTS contract, preserving the tested implementation SHA separately from subsequent evidence commits.
- [Unverified — needs clone run] No suite, pytest, executable fixture, mutation, git command or external-state query ran. Classification above is a narrow read-only observation, not verification of the proposed implementation. Graph discovery was attempted against the available XYZ-forge project, but its generation was 2026-09-01 and its root was another checkout; exact-path coverage reported changed/untracked/missing metadata. Current local source was read directly for the material router/selector/receipt/workflow/runner/publication and existing-check contracts. No exhaustive source-defect or live-state claim is made. Implementation signoff still requires the plan's clone runs and recorded red controls.

Relay closed (Approved), no further review turn needed. Producer (codex-producer) may proceed with the approved plan subject to its named prerequisites; approval grants no merge/protection/deployment authority. Only this relay file was edited.


### Attestation · relay-drive — 2026-10-15T07:17:31Z
task: RELAY-GH1076-PLAN-20261015
reviewer: codex
status: Approved
reviewed-head: 3fce49040dc6b90c6db56ab8920b6986fb49ab82
added-range: 10051+5071
added-sha256: ba6ae9a9d161613568b57e35cc9768814afc4b50e1e748824545137664b1e996
### Producer · Round 3

Use the ONE remaining normal plan round3/3 for the newly authorized disabled profile contract.
Read the complete seeded canonical plan and especially "Disabled profile completion — authorized
2026-10-15", current source and original evidence. No production implementation has been written.
Current-base merge963061c1 includes developmentdc7245b4, with native ledger resolution/preservation.
The two-file existing-owner plan keeps activation literalfalse and Medium/full, supports strict
separate-phase @2 receipts while preserving @1, and adds no tests/runner/lane/CLI/authority cache.
Do not invent enterprise mechanisms or request speculative new tests. Review concrete holes in the
stated dormant feature, actual callers and future fail-closed path. No suite/source writes here.
Original plan PARKED/PASS and final3/3 remain historical. Task RELAY-GH1076-PLAN-R3-20261015 is only
a fresh execution token for this one remaining plan turn, not another review budget. The separate
Noel-approved ONE extra final review remains unspent and follows implementation; no consult/reset.
If this plan turn does not PASS, stop at the original plan cap rather than starting another token.

Handing off to Reviewer — append cumulative plan Round3 findings only.

### Reviewer · Round 3

VERDICT: FAIL
Basis: The disabled scope preserves current qualification authority, but its two-file implementation boundary omits an existing publication consumer of the new phase evidence. Resolve the storage/publication contract before calling the dormant capability complete. This is the last normal plan round; no further review token or retry is authorized by this verdict.
swept file: yes

- [Should] Specify a publishable two-phase evidence layout, or include the existing publisher in the implementation boundary. Artifact lines 285–287 restrict implementation to router/wave and reuse existing publication; lines 335–343 require each original phase's telemetry path/hash and retained files, without concatenating the runs (lines 307–309). However, `utils/py/hosted_lane_publish.py:56,80–90` admits only `provenance.jsonl` and `validation.jsonl` per dated tested-wave directory. `:208–222` uses that same receipt filter to retain evidence before bounded recovery. The one existing telemetry slot cannot hold two separate original phase files at that wave path; new phase filenames/subdirectories are rejected or excluded from recovery. Dormancy prevents an immediate production failure, but leaves a concrete missing consumer contract for future activation. Cheapest correction: explicitly choose the exact layout and its publication/recovery handling; if distinct phase files require a narrow publisher extension, name that existing owner rather than implying the two-file scope is sufficient. Alternatively explicitly defer publication support and describe the dormant capability as incomplete until that prerequisite is implemented/reviewed. Do not concatenate runs or weaken the allowlist generically.
  Observed input: the current publisher's literal `RECEIPT` regex rejects `TESTS-RESULTS/2026-10-15+GH-591/wave-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/validation-small.jsonl`, `validation-skills-army.jsonl`, and phase subdirectories, while accepting the existing `validation.jsonl` and `provenance.jsonl`. These are concrete proposed phase-path shapes measured against the current consumer, not an observed live @2 run; the plan supplies no alternative exact layout.
  Affected scope: retained/published/recovered @2 phase telemetry for the same tested snapshot; historical @1 paths and current full/Small runs remain unchanged.
  Falsifier: an explicit layout retaining both original byte streams and their independently checked hashes, at the same true tested identity, passes existing publisher admission and receipts-first recovery without losing either phase or interpreting telemetry as provenance; expected result is both phases available to the production reader after a publication race. Such a layout would make a publisher extension unnecessary.
  Probe (read-only; no publisher or fixture executed): `python3 -B` parsed `utils/py/hosted_lane_publish.py` with `ast.parse`, extracted the literal `RECEIPT` using `ast.literal_eval`, then ran `re.fullmatch(pattern, "TESTS-RESULTS/2026-10-15+GH-591/wave-" + "a"*40 + "/" + name)` for `provenance.jsonl`, `validation.jsonl`, `validation-small.jsonl`, `validation-skills-army.jsonl`, `small/validation.jsonl`, `skills-army/validation.jsonl`. Exit **0**; decisive outputs respectively: **True, True, False, False, False, False**. `declared_paths` raises `SystemExit('Refusing undeclared reconciliation artifacts: ...')` for rejected names (`:82–85`).
- [Pass] The activation/authority boundary is appropriately narrow: artifact lines 313–331 require a literal false switch without environment/CLI override, full for Medium, actual modified regular-file raw diff and exactly one merged development landing equal to the tested head. Lines 300–305 and 340–343 forbid disabled @2 suppression or fallback into legacy attribution. These requirements must also govern every receipt consumer during implementation; this turn does not establish their implementation. The batch caller really uses the existing selector tuple (`skills/2-daily/merge-cleanup/scripts/batch_record.py:263–279`), so preserving its ordinary full recommendation avoids new batch authority.
- [Pass] Separate-phase validation fits existing mechanisms: `validate.sh:916–924,1119–1127,1464–1468,1499–1504` supports Small's PDDA/Python/envelope and the area's envelope with distinct totals. Artifact lines 332–351 require exact historical lists, independent run identities, strict stages/counts/skips/drift checks and @1 coexistence. Current historical-list replay is owned by `utils/py/wave_reconcile.py:470–478,558–568`; recovery uses the same matcher (`:632–634,1399,2228–2235`). Main remains explicitly full (`.github/workflows/ci.yml:151–152,198–203`). No new runner or CI case is needed to specify these contracts.
- [Pass] Whole artifact swept, including prior scope, historical execution notes, measurements, dependency limits and the superseding disabled continuation. Artifact lines 122–138 preserve matched measurements and natural hosted comparisons; lines 269–305 distinguish merged batch dependencies from correctness and prohibit mutable verdict authority; lines 344–364 preserve clone-only verification, one supplemental final review and no activation. No additional pre-existing plan defect found beyond the publication gap above. Earlier historical readiness statements are read with their dated subsequent updates, not as refreshed external-state attestations.
- [Unverified — needs clone run] No suites, pytest, executable fixtures, git commands, source edits or external-state queries ran. The seeded artifact is a plan, not the new implementation. Graph Verify discovery found no relevant symbols in the available foreign-root XYZ-forge generation `2026-09-01T15:54:30Z`; exact-path coverage reported changed metadata, missing or untracked paths. Material router, runner, wave receipt/recovery, publisher, batch caller, workflow and existing-check contracts were therefore read directly. No exhaustive source-defect or implementation/performance qualification is claimed. Clone evidence and the separately authorized final review remain pending.

Handing off to Producer (codex-producer) — original plan cap reached, STATUS Escalated. Resolve the concrete contract gap with the operator under the existing cap rules; do not start another plan-review token. Only this relay file was edited; the harness owns its commit.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
