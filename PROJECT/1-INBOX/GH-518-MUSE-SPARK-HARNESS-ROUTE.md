---
title: "GH-518: Wire Meta's native muse CLI (Muse Spark 1.3 Contributor) as an XYZ harness route"
status: Parked
created: 2026-09-08
updated: 2026-09-08
owner: unassigned
goal: make "meta" and "muse" resolve through the Model-catalog pin to muse-spark-1.3-contributor, add a relay-turn-lib-based muse-turn.sh shim calling the absolute-path binary, and earn a registry grade from real relay/consult/builder/reviewer evidence rather than assigning one
gh_issue: 518
source: https://github.com/HiQS-Labs/XYZ-forge/issues/518
doc_type: feature
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/41
  - https://github.com/HiQS-Labs/XYZ-forge/issues/346
  - https://github.com/HiQS-Labs/XYZ-forge/issues/450
  - https://github.com/HiQS-Labs/Model-catalog/issues/6
context_tags: [harness, model-catalog, model-alias, relay-harness, muse, meta]
non_goals:
  - Editing relay-automation/resolve-model-alias.sh (GH-450 non-goal; the alias YAML is generated from the catalog)
  - Vendoring a .xyz/ copy into Model-catalog (tests run here, where relay-automation/ lives)
  - Retiring or re-grading the Commandcode route recorded in GH-41
  - Modifying shell rc files to put muse on PATH (installed with MUSE_NO_MODIFY_PATH=1 by operator decision)
effort: 5
complexity: 3
risk: 4
---

# GH-518 — Muse Spark 1.3 as a first-class XYZ harness route

## Status

| What was just completed | What's next |
|---|---|
| Installed and verified the CLI, confirmed the model id by live run, filed GH-518 + Model-catalog#6, parked this row | Operator decision on the default-lane flip (data clause, below), then Model-catalog PR before the XYZ-forge repin |

## Why

XYZ has no supported route to Meta's native `muse` CLI. The last Muse Spark evaluation here
([GH-41](https://github.com/HiQS-Labs/XYZ-forge/issues/41), 2026-08-19) ran version **1.2**
indirectly through Commandcode, because no native CLI existed at the time. Meta has since shipped
`Muse Code 1.0.3` with a headless `muse exec` mode and a current model,
`muse-spark-1.3-contributor`.

## Key concepts

- **The catalog is the resolver.** Under the GH-450 contract, `resolve-model-alias.sh` is
  byte-untouched and the alias YAML is *generated* from the vendored Model-catalog copy. So
  "set up the resolver" means adding rows upstream in Model-catalog and re-pinning here — not
  editing the Bash resolver. Hand edits to either side are CI-red by design.
- **Two-repo, two-PR flow.** Model-catalog#6 lands and cuts a tag; only then does this repo repin
  with `utils/py/model_catalog.py pin`, never by hand.
- **Pre-existing pin drift.** `relay-automation/model-catalog/catalog.pin.json` is at **v1.0.0**
  while Model-catalog is already at **v1.2.0**. The repin therefore crosses two minor versions
  this repo never took, and the vendored diff will look larger than this change's true blast
  radius. Call that out in the PR rather than absorbing it silently.
- **The bare-word gate is why `status` matters.** `validate_catalog.py` refuses a bare vendor
  alias pointing at a `preview` model. Meta reports `is_current: true` / `visibility: visible`
  for this model, which supports `status: "ga"`.

## Verified ground truth (2026-09-08)

- Installer is HTTPS-pinned (`--proto '=https'`, `--proto-redir '=https'`, `--tlsv1.2`) and
  checksum-verifies the launcher against an `x-content-sha256` header when advertised.
- Installed with `MUSE_NO_MODIFY_PATH=1` to `~/.local/bin/muse`; confirmed no PATH line was
  appended to `.zshrc`, `.bashrc`, `.profile`, or `.bash_profile`. **Shims must use the absolute
  path.**
- `muse --version` → `Muse Code 1.0.3 (1.0.3-R2198.1)`.
- The launcher's `auth.meta.com` OAuth device flow authenticates *release downloads only*.
  Provider credentials are separate and stdin-only:
  `muse auth set --provider meta --api-key-stdin`. Key stored from the operator's secrets path;
  value never printed, logged, or committed.
- Headless surface: `muse exec [--json] --model <ID> --prompt-file <PATH>`, with
  `--reasoning-effort`, `--permission-profile`, `--workspace`, `-w/--worktree` — close to the
  containment contract the existing shims already implement.
- **Model id confirmed by live run:** `muse exec --model muse-spark-1.3-contributor` returned
  `MUSE_OK`; an invalid-id probe is rejected server-side, so the slug is validated, not inferred.

## Open decision — blocks the default-lane flip only

Meta's catalog row for the Contributor tier reads verbatim:

> Discounted tokens: your content, including inter-session messages, may be used for product
> improvement.

Contributor is $0.10/$0.20/$0.002 per M (input/output/cached); the clause-free sibling
`muse-spark-1.3` is $1.25/$4.25/$0.15 — 12.5× input, 21× output. The discount is the
consideration for the data grant.

Fine for this repo, which is public. Different as a **default**, because XYZ drives private
repositories and a default applies everywhere unless scoped, and sent content cannot be recalled.

Two standing-policy collisions the flip must amend rather than contradict:

1. `AGENTS.md` / `HARNESS-MODELS-REGISTRY.md` §1 designate Codex CLI the cost-blind default
   builder/reviewer (GH-212) and agy a cost-blind cross-model lane (GH-178). Both are
   subscription-authenticated; Muse bills per token, so the flip converts every relay turn and
   marathon wave from fixed-cost to metered.
2. The registry rubric requires **three verified end-to-end runs** for an A grade. Muse Spark 1.3
   has **zero** recorded runs here. GH-41's 1.2 history is a turn-cap stall, one no-code run, and
   two review blockers contradicted by live evidence. Defaulting before the qualifying runs
   inverts the evidence rule the registry exists to enforce.

Route work proceeds regardless; only the flip waits.

## Acceptance

- `muse-turn.sh` completes a real turn under the serialized `relay-drive.sh` protocol — the exact
  thing GH-41 could not do for 1.2 without an adapter.
- Four surfaces exercised with honest per-surface pass/fail: relay, consult, builder role,
  reviewer role.
- `resolve-model-alias.sh "meta"` and `"muse"` both resolve to `muse-spark-1.3-contributor`, with
  that file unmodified.
- `test/gh450-model-catalog-pin.sh` green against the new pin.
- `./validate.sh` green from a separate disposable full clone (GH-45 worktree rule).
- Registry row carries the grade the evidence earns, not a pre-assigned one.
