# Plan draft: #518 harness: wire Meta's native muse CLI (Muse Spark 1.3 Contributor) as an XYZ route — catalog aliases, muse-turn.sh shim, four-surface evidence

> draft; preflight and independent plan QA outstanding

- Request: `gh-518-3cfafd1bd016` (tick `slot_039`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 70/50/50/35
- Capture doc: PROJECT/1-INBOX/GH-518-MUSE-SPARK-HARNESS-ROUTE.md (sha256 a37818bae9259c39925be3cf796b0597b01675455dfedfbd4069bc19ab4d50f3)
- Issue sha256: 3cfafd1bd01607cdfa5abb4332ce4b2c8edac3f36dd156e30f4a82e0e3d8e1aa (updated 2026-09-09T03:50:17Z)
- Dependencies: none

## Scope

_Source: issue#518:L72 (Scope)_

**Model-catalog side** (companion issue, data + validator, cut as its own release):

- Add a `muse-spark-1.3-contributor` entity to `data/models.json` with `provider: "meta"`,
  `targets.native.id: "muse-spark-1.3-contributor"`, sourced to Meta's provider catalog and the
  live probe above.
- Add `meta` and `muse` alias rows to `data/aliases.json`, plus the natural spellings.
- Add `"meta"` and `"muse"` to `KNOWN_VENDOR_BRANDS` in `scripts/validate_catalog.py`. Today the
  bare-word GA gate catches `meta` only incidentally (via the `match == provider` branch) and
  does not recognise `muse` as a brand at all, so `muse` could silently be pointed at a preview
  model. Closing that is part of this change, not a drive-by.
- Regenerate `data/catalog.json` via `scripts/generate_catalog.py`; `scripts/validate_catalog.py`
  must pass.

**XYZ-forge side** (this issue):

- Re-vendor the catalog and rewrite `relay-automation/model-catalog/catalog.pin.json` using
  `python3 utils/py/model_catalog.py pin --tag ... --tag-commit ...`, never by hand, per the
  GH-450 contract. Note the vendored pin is currently **v1.0.0** while upstream is already at
  **v1.2.0**, so this repin also clears two minor versions of pre-existing drift — that drift
  should be called out in the PR rather than absorbed silently.
- `relay-automation/resolve-model-alias.sh` stays **byte-untouched** (GH-450 non-goal); the alias
  YAML is generated from the catalog, so the resolver inherits `meta`/`muse` for free.
- Ad

_Source: PROJECT/1-INBOX/GH-518-MUSE-SPARK-HARNESS-ROUTE.md:L7 (frontmatter goal)_

make "meta" and "muse" resolve through the Model-catalog pin to muse-spark-1.3-contributor, add a relay-turn-lib-based muse-turn.sh shim calling the absolute-path binary, and earn a registry grade from real relay/consult/builder/reviewer evidence rather than assigning one

_Source: codex-authored (codex-authored)_

Verify issue #518, Model-catalog #6, and the current harness and catalog state before identifying remaining work.

_Source: codex-authored (codex-authored)_

Plan the upstream catalog entity, aliases, and validator changes, followed by a tagged release and XYZ catalog repin.

_Source: codex-authored (codex-authored)_

Plan a native Muse turn shim using the existing relay turn library and collect real relay, consult, builder, and reviewer evidence for registry grading.

_Source: codex-authored (codex-authored)_

Assess the proposed default-lane change separately against data-use, metered-cost, and existing evidence requirements.

## Acceptance criteria

_Source: issue#518:L103 (Acceptance)_

- `muse-turn.sh` completes a real relay turn under the serialized `relay-drive.sh` protocol —
  the exact thing #41 could not do for 1.2 in the absence of an adapter.
- All four operator-named surfaces exercised against the route with honest per-surface pass/fail:
  **relay**, **consult**, **builder role**, **reviewer role**.
- `resolve-model-alias.sh "meta"` and `resolve-model-alias.sh "muse"` both resolve to
  `muse-spark-1.3-contributor` with the resolver file unmodified.
- `test/gh450-model-catalog-pin.sh` green against the new pin.
- `./validate.sh` green, run from a separate disposable full clone per the GH-45 worktree rule.
- The default-lane flip, if authorized, lands as its own commit after the above, amending the
  AGENTS.md/registry policy rows explicitly rather than leaving them contradicted.

_Source: PROJECT/1-INBOX/GH-518-MUSE-SPARK-HARNESS-ROUTE.md:L104 (Acceptance)_

- `muse-turn.sh` completes a real turn under the serialized `relay-drive.sh` protocol — the exact
  thing GH-41 could not do for 1.2 without an adapter.
- Four surfaces exercised with honest per-surface pass/fail: relay, consult, builder role,
  reviewer role.
- `resolve-model-alias.sh "meta"` and `"muse"` both resolve to `muse-spark-1.3-contributor`, with
  that file unmodified.
- `test/gh450-model-catalog-pin.sh` green against the new pin.
- `./validate.sh` green from a separate disposable full clone (GH-45 worktree rule).
- Registry row carries the grade the evidence earns, not a pre-assigned one.

_Source: codex-authored (codex-authored)_

The catalog resolves supported Meta and Muse aliases to the verified native model through generated catalog data without editing the alias resolver.

_Source: codex-authored (codex-authored)_

The harness invokes the native CLI through its absolute path and follows existing turn containment contracts.

_Source: codex-authored (codex-authored)_

Registry grading is supported by recorded end-to-end evidence under the existing rubric.

_Source: codex-authored (codex-authored)_

Any default-lane change requires an explicit operator decision on the data-use clause and addresses the existing cost and qualification policies.

_Source: codex-authored (codex-authored)_

The catalog release precedes the XYZ repin, and the repin's pre-existing version drift is disclosed.

## Open questions

_Source: codex-authored (codex-authored)_

What work has landed since the September capture, including Model-catalog #6 and the existing catalog pin?

_Source: codex-authored (codex-authored)_

Has the operator decided whether Contributor-tier data use and metered costs are acceptable for a default that can run on private repositories?

_Source: codex-authored (codex-authored)_

Which current tests and four-surface runs are required to establish the route's actual registry grade?

## Write set

- `AGENTS.md` (issue#518:L63)
- `HARNESS-MODELS-REGISTRY.md` (issue#518:L63)
- `relay-automation/model-catalog/catalog.pin.json` (issue#518:L89)
- `utils/py/model_catalog.py` (issue#518:L90)
- `relay-automation/resolve-model-alias.sh` (issue#518:L94)
- `relay-automation/muse-turn.sh` (issue#518:L96)
- `relay-automation/relay-turn-lib.sh` (issue#518:L98)
- `relay-automation/relay-drive.sh` (issue#518:L105)
- `test/gh450-model-catalog-pin.sh` (issue#518:L111)
- `validate.sh` (issue#518:L112)

## Unresolved file names

- `codex-turn.sh` (issue#518:L97; 2 tracked files share this name)
- `agy-turn.sh` (issue#518:L97; 2 tracked files share this name)
- `commandcode-turn.sh` (issue#518:L97; 2 tracked files share this name)

## Contract probes

- none
