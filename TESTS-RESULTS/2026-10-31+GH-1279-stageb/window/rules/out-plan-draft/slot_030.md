# Plan draft: #460 ATE/Fuzz campaign vs the model-alias resolver — counterexamples must land as fixes (start-task ready)

> draft; preflight and independent plan QA outstanding

- Request: `gh-460-e63ba9e2f9ed` (tick `slot_030`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 60/40/50/70
- Capture doc: PROJECT/2-WORKING/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md (sha256 b1a2f9a5c745fbaf7889730d39dc77961b5dfdce042e3b64f7e1a448f0616f9b)
- Issue sha256: e63ba9e2f9edf71ef14926408e74c44472f30aa2f365d5035c6d0a1b0e9633ae (updated 2026-09-06T18:38:05Z)
- Dependencies: none

## Scope

_Source: PROJECT/2-WORKING/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md:L29 (frontmatter goal)_

Make the Gen4 fuzz engine a standing oracle over resolve-model-alias.sh and model_alias.resolve_model_slug: a committed smoke test with a witnessed red control, seeded 500+-iteration campaigns with every counterexample dispositioned on #460 (fix + pinned replayable regression test, or documented non-defect with the oracle narrowed), and zero untriaged counterexamples at close.

## Acceptance criteria

_missing_

## Open questions

_missing_

## Write set

- `utils/py/fuzz_engine.py` (issue#460:L3)
- `relay-automation/resolve-model-alias.sh` (issue#460:L3)
- `validate.sh` (issue#460:L17)
- `test/gh346-resolver-fallback.sh` (issue#460:L20)
- `PROJECT/1-INBOX/recon-model-aliasing.md` (PROJECT/2-WORKING/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md:L17)
- `test/gh460-oracle.sh` (PROJECT/2-WORKING/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md:L25)
- `utils/py/model_alias.py` (PROJECT/2-WORKING/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md:L62)
- `utils/py/deepseek-turn.py` (PROJECT/2-WORKING/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md:L64)
- `utils/py/review_xyz.py` (PROJECT/2-WORKING/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md:L65)
- `test/gh460-fuzz-resolver-smoke.sh` (PROJECT/2-WORKING/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md:L109)
- `test/model-alias.sh` (PROJECT/2-WORKING/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md:L110)
- `ci-local.sh` (PROJECT/2-WORKING/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md:L110)
- `AGENTS.md` (PROJECT/2-WORKING/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md:L150)

## Unresolved file names

- none

## Contract probes

- none
