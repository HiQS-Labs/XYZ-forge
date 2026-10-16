# GH1076 reverse coverage audit of consumer map v3

Audited immutable PR1079 head `8bf95a1ebb2a915f4cad4c127b69bccf68fcf4a8` using `git show`, not the parent's modified working tree. Static extraction found **406 existing shell registry entries**. Every entry's source was scanned for specific package/publisher/drift dependencies and broader global skills/glob/inventory access; relevant bodies and called helpers were read. No project imports, classifiers, suites or checks were executed. This lane changed no source, remote, branch or test case; its only writes are this report and accompanying JSON.

**The proposed78 is not a complete general package-content closure.** Two more existing registered checks read package content: `path-integrity.sh` and `gh788-python-path-space.sh`. Neither is in proposed78. An audit union including both would have80 shell suites, plus mandatory existing non-shell stages; this is a static count, not qualification authority, sufficient recall or runtime PASS.

## Included semantic consumers

- `skills-army-hq.sh:8–15` runs `test_deploy_skills.py` via pytest. Named skip without pytest is explicit and must not become qualification. `test_deploy_skills.py:21–24` importlib-loads real intake; `:39–67` copies actual package, executes real intake/sync into fixtures; `:562–623` exercises drift integration.
- `gh620-skills-army-mini-sync.sh:43–80,167–215` calls actual publisher with skills-army-mini target, pins full projected payload/README/provenance, then exercises generated package root intake and sync. This is the previously observed payload-pin consumer, already included.
- `gh589-xyz-mini-sync.sh:34,61–80,95–147` calls shared publisher, checks default target payload, ownership and target manifest listing. `gh589-consult-no-tick.sh:22` builds default published mini then checks consult without kernel. Both already retained in area five; neither by itself proves all three publisher targets safe for arbitrary shared implementation edits.
- `gh589-skill-viewer.sh:17–25` enumerates `skills/*/*/SKILL.md` and compares actual viewer count/name set against disk. It therefore reads skills-army frontmatter as part of a global inventory; `:36–56` tests parser/error controls. Included already.
- Proposed addition `gh660-skill-drift.sh:10–74` drives actual checker with canonical/collection fixtures, tiered names, mutation and JSON output. This is a semantic dependency of package sync, not a filename association.
- Mandatory non-shell Python stage `test/test_python_layer.py:13–19` independently runs unittest discovery for `test_deploy_skills.py`, asserts success and nonempty discovery. Retain this despite overlap with area wrapper; do not silently erase duplicate work while claiming equivalent evidence.

## Genuinely omitted package-content consumers

**`path-integrity.sh`**, registered at `validate.sh:516`:

- `:165–198` builds `list((root / "skills").rglob("*.md"))`; asserts nonempty scan, then validates `../...` cross-folder links and canonical development blob links against actual paths. Every package Markdown file is included. A text-only package link edit can change this check's result.
- `:45–163` additionally scans every tracked shell script and curated operational docs for referenced relay/script/doc paths. Those curated docs are relay-specific; the global Markdown section is the direct skills-army edge.
- Its final `exit0` does not make failures decorative: `test/_setup.sh:172` fail exits1 by default and `:62–66` preserves nonzero failure under soft-fail mode. Source reviewed; no new red control run.

**`gh788-python-path-space.sh`**, registered at `validate.sh:141`:

- `:89–105` scans with `git grep` against `test utils relay-automation skills`, excluding only its own test file. There is **no file-extension restriction**.
- Patterns reject bare `sys.executable` shebang construction, unquoted `f"{sys.executable} ..."`, and the unquoted Bash `$PY` fuzz-target spelling. Consequently both package scripts **and package Markdown code examples** can affect this assertion. This is a global semantic content guard, not mere route/registry infrastructure.
- Existing planted unsafe/safe controls are `:108–125`; no changes or reruns made here.

For a first pilot that allows general package text, include both existing checks or explicitly exclude their affecting changes. Merely saying “no script edits” does **not** exclude gh788, since its scan includes Markdown examples. With proposed78 + path-integrity alone (79), interpreter-example effects remain outside the selected set.

## Infrastructure references and false positives

- `gh251-validate-pytest-skip.sh:13–22,41–58` names package sync.py only as nested runner routing input, validating pytest pass/skip reporting. It is not a manager behavioral test. Adding selected area members affects its nested runtime cost, which is a separate measurement concern.
- `ci-route.sh:187–205,235–238,283–291` checks synthetic package paths, dedicated co-touch routing and existing area count. It does not call intake/sync/publisher. Count adaptation5→7 for existing suite additions changes an existing expectation; it is not a new assertion/case.
- `gh365-tier-fail-closed.sh:39–62,72,103–116` checks classifier/registry family coverage, not manager behavior.
- `find-harness.sh:11–12,116–143` copies **relay-xyz/find-harness.sh** directly and tests deployed locator discovery. Its Skills Army comment names a deployment context. It does not consume the manager package; not an additional missing package test.
- `gh678-installer-live-links.sh:12–22` discovers actual `skills/*/*/install.sh`. The immutable package has seven files and **no install.sh**. Adding an installer would make it a new consumer edge, excluded from the narrow existing-content pilot.
- `gh245-agy-probe-verb-invariant.sh:58–78` has a broad rglob helper, but invokes it at `utils/py` only and tests specific agy calls; not a package consumer.
- Already-in-Small global checks remain included: `mktemp-trap-guard.sh:42–62` scans executable Bash/shell scripts beneath skills; `gh777-inventory-ratchet.sh:7` invokes inventory checking whose helper scans script inventory and sqlite bypasses. These are not substitutes for missing Markdown link/interpreter guards.
- Other scans/skill references in the406 test sources name relay/agent-chorus/HQ/standup/review-xyz or temporary fixtures. No additional direct package caller was identified by the bounded source/body audit. This is not a proof against dynamic/external consumers.

## Scope and concrete recommendation

1. **Current no-reduction improvement:** append existing gh660 and path-integrity to the existing skills-army area, adapt existing count5→7 and label, retain Small72, hosted Medium full, full registry406 and exact-main full. Both are demonstrably registered; no new suite or case needed. This preserves current gate authority and adds local coverage. It does not claim a complete reduced-pilot closure.
2. **Content-only study:** restrict to existing tracked package content with no schemas/scripts/modes/manifest/ownership/security/activation changes. Include global link consumer. Include gh788 too if code-example/interpreter-pattern edits are allowed; otherwise make that exclusion explicit and review actual changed text for the restriction. Proposed general-content union would be80 shell suites. Preserve mandatory stages, history and current full qualification until separate policy/receipt/required-check approval.
3. **Package scripts:** manager lock/state/recovery/deployment changes expand beyond narrow first pilot. Keep full while reviewing actual runtime consumers. Existing manager fixtures and gh660 are useful but do not establish complete consumer closure.
4. **Shared publisher or drift checker:** retain full for `utils/py/xyz_mini_sync.py`, shared manifest/secret/ownership/remote logic, global LICENSE inputs and `utils/py/skill_drift_check.py`. The publisher has xyz-mini, skills-army-mini and agent-chorus profiles (`:62–120`); a package-only source edit enters the skills-army payload whereas a shared implementation change can affect all three. Do not generalize a package-only selected set to shared changes.

The JSON retains scan patterns, per-suite source hits and explicit classifications as audit evidence. It is not a machine policy or competing registry. No new CI assertions, parameter cases, guard stages, installs, deployments or qualification reductions are authorized by this report.
