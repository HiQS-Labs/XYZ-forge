# GH-1376 flywheel skill verification

## Scope

Documentation-only addition of `skills/2-daily/flywheel/SKILL.md`, its Skills Index row, the governed issue plan/ledger row, and independent review receipts. The operator-requested text extension adds the adaptive-work principle to `GUIDING-PRINCIPLES.md` and a pointer from `AGENTS.md`, while leaving the operational rubrics in the skill. No executable, new test suite, gate machinery, deployed-skill copy, app link, automatic merge or marathon dispatch.

- Implementation commit: `b35f931ce36f84cefdfdc1ccfd25d0baeffd8900`.
- Integrated commit after merging `origin/development`: `681809230bec851f4fa11748d9f5c6993f3804e4`.
- Final PRS row after supported base-merge replays: `rmi-01M6YBKN6MRJEYV3269DYE32ZP`, rated `80/45/50/80`, accepted start and In progress read back. The successive unpublished IDs `rmi-01M6Y72BPK27QN223B7MFV3DHK`, `rmi-01M6Y7RZVY3P9970XQQ13XGD8Q` and `rmi-01M6Y8AYYZR9S66FGD540Z0X3M` were reminted by replaying the same issue/rating/doc through `roadmap pickup` after ledger-base merges. No SQL or DB hand edit; the supported resolver reported `releases check` clean.

## Independent plan QA

Codex plan review through `relay-xyz` / `relay-drive.sh --review-once` returned **Approved** in `relay-system/2026-11-08/gh1376-flywheel-plan.codex.md`, reviewed head `627070dada97e1597a8ddfd0d82171b0a2e277c6`. It confirmed the composition gap, current #1358 policy match, owner boundaries, recovery order and proportionate verification. No plan correction was required.

The first dispatch stopped before a model turn because the fresh clone had no `.tick/events`; `tick init` repaired that local prerequisite. The successful review used one actual Codex turn. Token telemetry remains a partial floor, not total usage.

## Consumer smoke

Read `skills/2-daily/flywheel/SKILL.md` from its consumer source path, then ran nonempty content assertions for the frontmatter name, Rubrics 1A/1B/2/3, the exact autonomous-repair sentence, all four authorization-ladder rungs, ordered flow and completion contract. Also resolved all eight linked skill source paths and located the Skills Index row.

Result in `consumer-smoke.txt`:

```text
PASS consumer-smoke: 12/12 required segments; 8/8 owner links resolve; Skills Index link present
```

This was a manual documentation check, not a new test file, suite or gate.

## Classified documentation gate

`git diff --name-only origin/development...HEAD | utils/ci-route.sh pull_request` reported `route=docs`, `tier=1`, `docs_only=true`, `full_required=false`, `tier_reason=docs-only`.

Ran `utils/pdda/pdda.sh run` in the separate disposable full clone `XYZ-forge-gh1376-flywheel-skill-2026-11-08-gate`:

- Initial implementation `b35f931ce36f84cefdfdc1ccfd25d0baeffd8900`: exit 0, **zero errors**; `pdda-initial.log`.
- Integrated commit `681809230bec851f4fa11748d9f5c6993f3804e4`: exit 0, **zero errors**; `pdda-integrated.log`.
- Both logs are byte-identical (SHA-256 `01523a361a8a67ac265d1f78f6f9e724b2feac58378807b5a4029f00fb1d6475`) because the output contains no per-run timestamp.
- The 100 reported warnings are existing unrelated issue-sync/governance/marathon-plan hygiene warnings; none was edited or suppressed. LLM doc-ready self-skipped because `PDDA_LLM_BIN` was not set; independent review is supplied by the relay, not that optional hook.
- HEAD, canonical GitHub origin and `core.bare=false` matched before/after; the gate clone was clean after the run.

## Final independent QA

Codex final review through `relay-xyz` returned **Approved** in `relay-system/2026-11-08/gh1376-flywheel-final.codex.md`, reviewed head `9be787e6d99467b6950376d2664a2953bcaf5ee3`. It found no source correction, confirmed the seeded artifact equals the consumer source, resolved all eight owner paths, and independently matched the nonempty evidence hashes. The final publication gate and PR identity remain separate requirements; no merge, deployment or marathon dispatch is authorized by this review.

## Current state and next

Takeover merged published development at `a71a1d5a` into the task branch (`29f41026`), replayed only GH-1376 registration via supported writers, and passed the normal pre-push documentation gate. Final row: `rmi-01M6YGA74VK3VJ48AVECKS52R7`; older row IDs above are historical.

The operator replaced the requested additional delegate review with direct review. That review verified and corrected two existing CodeRabbit routing findings; see `takeover-review.md`. Earlier independent plan/final receipts do not claim coverage of this later correction. GP/AGENTS text is included; the original docs-only classification above predates that extension. The merge publication hook classified its incremental update as docs-only. Historical full-gate success on `abae1cc4` was reported in the transcript, but its raw log is not committed here and is not used as new proof.

PR #1378 remains open against development. No merge, deployment, promotion or factory qualification is claimed. Final correction push/check status must be inspected on its exact head.

## 10days and Daily compatibility extension

Resumed the existing GH-1376 clone/branch/PR, merged published development e695d3263, and replayed only the task registration using roadmap pickup/accepted-start plus the supported resolver. Current row: rmi-01M6Z440MV93RH8S65CGHTNMQ3; rating 80/45/50/80 retained. Prior IDs and merge heads above are historical.

Independent plan QA Approved in one round at b5d956a25; receipt gh1376-compat-plan.codex.md. Implemented its nit reconciling blanket no-firing language with 10days' pre-existing named exception. Source implementation f40a5f7b1; instruction-level consumer evidence compat-consumer-smoke.md at ea6c7b496. No actual sweep or automatic Daily integration is claimed. Daily is external/optional and no deployed skill was edited. Final extension QA and publication status are recorded separately.

Lessons: NO_ENTRY. Component edit verdicts: flywheel routing, 10days recovery/handoff and Daily observation support all have no observed runtime effect yet; static consumer checks cannot support a runtime outcome lesson.

Final compatibility QA Approved in round 2 at bc04fc63f. Round 1's concrete dirty-worktree fallback finding was corrected and verified by native Git refusal/clean-removal controls; see compat-cleanup-smoke.md. No further source findings. Normal final push gate and exact-head hosted inspection remain publication steps, not inferred from review.

Publication environment recovery: the base-merge push range selected the full hook gate even though the net PR classifier is docs. The first attempt used temporary Python 3.9; gh251 nested pytest exposed _marathon_plan.py's str|None import incompatibility. The agent stopped its own failed gate/push group, retaining the failure (push exit143; no publication). Prepared Python 3.13 passes the same focused suite, 6/6; both logs/provenance committed. No runtime source or gate was modified. Retry uses the prepared environment and normal hook.

Normal full pre-push gate passed in 547s on c4abd1db6 with prepared Python 3.13 and published that exact head. Retained log: compat-publication-full.log. Separate helper identity remained canonical origin, core.bare=false, exact head and clean tree. This is push verification, not promotion evidence. The following commit retains this receipt and handoff metadata only; source skills remain the final-QA-approved bytes.
