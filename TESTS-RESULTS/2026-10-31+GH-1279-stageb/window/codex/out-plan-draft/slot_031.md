# Plan draft: #460 ATE/Fuzz campaign vs the model-alias resolver — counterexamples must land as fixes (start-task ready)

> draft; preflight and independent plan QA outstanding

- Request: `gh-460-e63ba9e2f9ed` (tick `slot_031`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 60/40/50/70
- Capture doc: PROJECT/2-WORKING/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md (sha256 b1a2f9a5c745fbaf7889730d39dc77961b5dfdce042e3b64f7e1a448f0616f9b)
- Issue sha256: e63ba9e2f9edf71ef14926408e74c44472f30aa2f365d5035c6d0a1b0e9633ae (updated 2026-09-06T18:38:05Z)
- Dependencies: none

## Scope

_Source: PROJECT/2-WORKING/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md:L29 (frontmatter goal)_

Make the Gen4 fuzz engine a standing oracle over resolve-model-alias.sh and model_alias.resolve_model_slug: a committed smoke test with a witnessed red control, seeded 500+-iteration campaigns with every counterexample dispositioned on #460 (fix + pinned replayable regression test, or documented non-defect with the oracle narrowed), and zero untriaged counterexamples at close.

_Source: codex-authored (codex-authored)_

Verify the current issue and branch status, including the capture document's reported completed implementation, campaign evidence, and outstanding final QA.

_Source: codex-authored (codex-authored)_

Review the standing resolver smoke test and wrapper-floor fuzz campaign against the issue's loop contract; identify and complete only remaining work.

_Source: codex-authored (codex-authored)_

Triage every counterexample as a defect with a replayable regression test and fix, or as a documented non-defect with a narrowed oracle.

## Acceptance criteria

_Source: codex-authored (codex-authored)_

The standing seeded smoke runs in validate.sh, and a witnessed resolver return-code mutation makes it fail.

_Source: codex-authored (codex-authored)_

Resolver and wrapper-floor campaigns cover at least 500 iterations across at least three seeds, with results including any null outcome recorded on the issue.

_Source: codex-authored (codex-authored)_

No counterexamples remain untriaged; each defect has a fix and corpus-derived replayable regression test, and each non-defect has a rationale and narrowed oracle.

_Source: codex-authored (codex-authored)_

The fuzz engine is used as-is, and alias-table semantics and cache or latency work remain out of scope.

## Open questions

_Source: codex-authored (codex-authored)_

What has landed since the capture document reported completed campaigns and pending final QA?

_Source: codex-authored (codex-authored)_

The issue calls for an inline Python oracle with no new Bash, while the capture describes a committed Bash oracle; which current contract applies, and does the implementation comply?

_Source: codex-authored (codex-authored)_

Do the reported 1500+300 campaign results satisfy the iteration and seed requirements for both resolver and wrapper-floor fuzzing?

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
