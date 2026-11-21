# RELAY · GH-1174 ATE documentation final review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-20.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(gh1174-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1174-ATE-FUZZ-DOCS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1174-ATE-FUZZ-DOCS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: producer
- Started: 2026-10-20
- Definition of Done: source-accurate documentation only, with all questions below answered.

## Review brief

Goal: independent final QA of GH-1174 manual docs hotfix, comparing origin/development..HEAD.
The user explicitly authorized correcting ATE/fuzzing docs, independent review, existing docs checks,
canonical ledger writers and normal-hook fast-forward publication to development WITHOUT a PR.
The express driver rejects SKILL.md; the manual exception is explicitly approved. No runtime,
packaging, tests, workflows, release-policy, skill deployment or production changes are in scope.

Read these changed files in FULL: skills/4-occasional/ate/SKILL.md,
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md, PROJECT/2-WORKING/GH-1174-ATE-FUZZ-DOCS.md,
CHANGELOG.md (new entry), and releases.sql (new GH-1174 rows only).
Verify claims against utils/ate/install.sh, utils/ate/scripts/{run_variations,checkin,compile_issue}.py,
all three variation templates using harness_root, utils/ate/tier1-calibration.json, and
utils/py/{adaptive_ate,fuzz_engine,domain_oracles,gen4_campaign,repro_builder,repro_synth,self_healer}.py.
Read the unchanged defect-campaign skill to ensure its safeguards remain intact.

Questions:
1. Are runner exit codes, no-model exit-only classification, expects_edits and usage-exit limits accurate?
2. Is full-checkout execution accurate, including the missing proc_group dependency and all copied harness_root templates?
3. Are nine targets, no-synth/default-on synthesis, unused campaign tier2-cmd, replay OR predicate,
   exit-only synthesis fallback and targetless clustering accurately distinguished from semantic proof?
4. Are seeded plans versus outcomes, corpus feedback timing, output feedback versus coverage and
   twin exit/stderr parity versus semantics explained accurately?
5. Are calibration 50/24/9, historical 2026-09-04 status/reports, observational oracles/lsof skips,
   recorded host violations, batch budgets, exit0 findings and destructive-reset supervision accurate?
6. Does the documentation clearly reject the atomic-write/full-validation repair promises, preserve
   qualification requirements and keep code follow-ups separate? Does it avoid inventing approval authority?
7. Is the consolidation concise and reviewable? The map explicitly supersedes old module-header
   promises/grid comments, keeping executable files byte-identical and the publication gate docs-only.
   Flag any material remaining contradiction or lost useful guidance; do not demand behavior/test changes.

Operational envelope: repository documentation. No installs, campaigns, model benchmarks, runtime suites,
new tests, production/credential access or external writes. Read-only source inspection and narrow static
checks only; no test/*.sh/validate.sh/pytest in your worktree. Existing docs verification is performed by
producer in a separate disposable full clone. Do not claim those checks ran during your review.
Report file:line findings, swept file: yes/no, source revision and PASS/FAIL. Approve only if source
claims and scope pass; pre-existing code defects are known limitations, not a request to fix code.
Commensurate complexity: no new machinery or speculative requirements.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PASS
Basis: Ship the documentation correction. The source contracts and supervision boundaries are accurately described; no material remaining contradiction or lost operational safeguard found in the complete changed-document sweep. No pre-existing documentation defect requiring correction found. This is source review approval, not a campaign, docs-gate, publication or repair qualification receipt.
swept file: yes

Source revision: isolated review HEAD `84ff0d4040eaa371d34672dec978cd6d796dd484` (read directly from worktree HEAD metadata; no git command). The map identifies its runtime audit baseline as `7eeae804`. Read the complete ATE skill, GH-299 document, GH-1174 task document and seeded artifact, new CHANGELOG entry, and GH-1174 ledger rows; also read the unchanged defect-campaign safeguards and the relevant implementation bodies/templates/calibration. Graph project `XYZ-forge` is another checkout with generation `2026-09-01T15:54:30Z`; graph search returned no campaign nodes, and coverage reported excluded/untracked/changed paths. Local source inspection supplies the review evidence instead.

- [Pass] Q1 — Runner status is separated from child findings, and no-model classification ignores edit expectations: `skills/4-occasional/ate/SKILL.md:55`, `:73`; `utils/ate/scripts/run_variations.py:486`, `:508`, `:570`, `:581`, `:588`, `:601`. The diagnostic prompt treats nonzero exit as error evidence (`run_variations.py:63`); it does not implement the turn-grid comment's exit-2 pass contract. Filing outcomes and bounded gh failure handling match `utils/ate/scripts/compile_issue.py:32`, `:130`, `:164`. No fix requested.
- [Pass] Q2 — Full-checkout guidance correctly identifies the missing sibling dependency and all three copied-root templates: `utils/ate/scripts/run_variations.py:50`, `:427`; `utils/ate/install.sh:21`; `utils/ate/variations.tool-density.yaml:10`, `utils/ate/variations.tool-calling.yaml:10`, `utils/ate/variations.turn-shims.yaml:26`. The variation example makes disposable scratch ownership and separate check-ins explicit (`skills/4-occasional/ate/SKILL.md:43`, `:63`); reset, clean and startup control behavior match `run_variations.py:213`, `:254`, `:451`. No fix requested.
- [Pass] Q3 — Nine targets, default-on synthesis, only `--no-synth`, unwired campaign Tier-2, OR replay and targetless clustering match `utils/py/gen4_campaign.py:66`, `:113`, `:216`, `:376`, `:398`; `utils/py/repro_synth.py:67`, `:145`. Adaptive ATE's anomaly-command hook is distinct (`utils/py/adaptive_ate.py:402`). The documentation explicitly withholds semantic/root-cause proof (`skills/4-occasional/ate/SKILL.md:102`). No fix requested.
- [Pass] Q4 — Planning precedes feedback updates; parity is exit/stderr only: `utils/py/fuzz_engine.py:284`, `:297`, `:306`. The documentation distinguishes corpus feedback, pairwise coverage and semantic execution outcomes (`skills/4-occasional/ate/SKILL.md:90`; `PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:63`). No fix requested.
- [Pass] Q5 — Calibration 50/24/9 matches `utils/ate/tier1-calibration.json` (quoted fields: `"fail": 24`, `"pass": 50`, `"anomalies": 9`). The historical 400-mutation report matches `TESTS-RESULTS/2026-09-04+GH-299/campaign/campaign-summary.md:4`; September 4's pending soak is explicitly time-qualified (`PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:40`, `:50`), not a claim that the later retained soak never happened. Observational/skippable lsof, batch checks, recorded host violations and exit-0 findings match `utils/py/domain_oracles.py:154`, `:169`; `utils/py/gen4_campaign.py:152`, `:188`, `:405`. No fix requested.
- [Pass] Q6 — Atomic-write and full-attestation promises are explicitly rejected while qualification remains required (`skills/4-occasional/ate/SKILL.md:112`; `PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:75`). Source uses ordinary writes (`utils/py/self_healer.py:48`, `:253`) and hands off `validate.sh --print-mode` (`utils/py/gen4_campaign.py:231`). The unchanged defect-campaign sections “Specify before requesting execution approval”, “Verify current CLI safety” and “Replay, classify and hand off” still require bounded approval, synthesis/healing/filing disablement, semantic predicates and separately approved remediation. No new authority is supplied by the map (`skills/4-occasional/ate/SKILL.md:11`). No fix requested.
- [Pass] Q7 — The consolidated map explicitly supersedes module/grid promises (`skills/4-occasional/ate/SKILL.md:8`), and GH-299 preserves historical results while linking current operating guidance (`PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:32`, `:42`). The task's scope remains documentation with publication pending (`.relay-artifacts/GH-1174-ATE-FUZZ-DOCS.md:24`, `:43`); GH-1174's ledger pointer is in progress (`releases.sql:888`) and the new CHANGELOG entry describes the same correction (`CHANGELOG.md:3`). No runtime repair, new test, policy or deployment is requested by this review. No fix requested.

Read-only supplemental probe (exit 0):

```bash
python3 -c 'from pathlib import Path; print("seeded_artifact_matches_task_doc:", Path(".relay-artifacts/GH-1174-ATE-FUZZ-DOCS.md").read_bytes() == Path("PROJECT/2-WORKING/GH-1174-ATE-FUZZ-DOCS.md").read_bytes())'
```

Decisive output: `seeded_artifact_matches_task_doc: True`. This is byte comparison of two nonempty reviewed documents, not a behavioral test. An additional read-only AST/JSON inspection (`python3 -` parsing `DEFAULT_TARGETS` with `ast.literal_eval` and loading calibration JSON) exited 0 and printed `default_targets: 9`, benchmark `fail: 24, pass: 50, rows: 74`, and score `anomalies: 9, false_negatives: 0, false_positives: 0`; the source citations above are the durable basis for those findings.

Verification limits: no validate.sh, test script, pytest, executable fixture, install, campaign, model call, external write or git command was run. Existing deterministic docs checks, final diff/byte-identity enforcement and exact-head publication evidence remain for the producer/harness in the authorized disposable full clone; this approval does not claim those checks passed here. Live GitHub merge/issue state was not re-queried. Only the relay file was edited.

Relay closed (Approved), no further review turn needed. Producer/harness owns the remaining docs gate and authorized publication.


### Attestation · relay-drive — 2026-10-21T04:11:33Z
task: RELAY-gh1174-final
reviewer: codex
status: Approved
reviewed-head: 84ff0d4040eaa371d34672dec978cd6d796dd484
added-range: 8511+6403
added-sha256: 418a3e229bb8b3bf5cf6ab323b9f974d61291e7f03ad6e69c67196f3a70af166
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
