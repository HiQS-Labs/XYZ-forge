# Plan draft: #453 Audit governance document ownership and correct XYZ principles drift

> draft; preflight and independent plan QA outstanding

- Request: `gh-453-3dd9322a7f45` (tick `slot_019`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 70/65/50/55
- Capture doc: PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md (sha256 7a68ad611901aa322edd2bb9b4c02075e4d5e031009ab595f2dd2ab5db0376ca)
- Issue sha256: 3dd9322a7f45ba5225bc2f53a93275d2211745311a24d183385ea85187929efd (updated 2026-09-25T01:18:51Z)
- Dependencies: none

## Scope

_Source: issue#453:L155 (Explicitly out of scope)_

- Rewriting PDDA's actual policy content. If a vendored doc is wrong *about PDDA*, that is an upstream
  issue — file it there, do not patch it here.
- Renaming the project or changing `package.json`'s `name` field. Related, but a separate decision
  with its own blast radius; note it and move on.
- Any change to `utils/pdda/**` behavior. You are auditing document ownership, not the checker.
- The 12 frozen Bash twins.

_Source: PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L32 (Scope)_

Execute Stage 1 of [the revised audit prompt](../1-INBOX/CODEX-GOVERNANCE-DOC-AUDIT-PROMPT.md).
Produce one report with the ownership/applicability inventory, exact proposed corrections,
strategy trade-offs, confirmed/refuted nearby drift, evidence limits and non-goals.
Stage 2 governance edits require explicit approval of that report.

_Source: PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L191 (Does the anti-scope parenthetical bind XYZ?)_

The parenthetical is evidence of intended governance-layer reach, not authority to ban XYZ's
existing execution system. ROUTER registers it as PDDA anti-scope, while Constitution explicitly
extends verified-success to all agents. These are different adoption signals.

| Entry (DO-NOT-BUILD line) | Assessment for XYZ |
|---|---|
| Generic spec framework / PRD-to-tasks product (16–17) | Consistent with current README:174–177, but capability overlap does not prove an adopted prohibition on every planning feature. Propose retaining that product boundary in XYZ's charter. |
| Generic multi-agent platform / marketplace (18) | Marketplace exclusion matches README. A blanket orchestration ban conflicts with XYZ's stated coordination/relay purpose. Do not apply that ban to its core product. |
| Full Kanban before stable CLI/MCP (19) | Conditional sequencing advice, not evidence that all dashboards are forbidden. Adoption unresolved. |
| Replacing commodity Markdown linting (20) | Consistent with the canonical reuse principle. Apply as a preference to extend/reuse existing checks, not permission to remove local contract checks. |
| New Bash or policy complexity (21) | XYZ independently has stronger Python/frozen-twin rails in AGENTS. Those already govern; do not weaken them to this older measured-gap wording. |
| Replacement for agent instruction formats (26–28) | Consistent with existing ROUTER/AGENTS role split. Preserve it without creating another policy system. |
| Large AI agile m

_Source: PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L8 (frontmatter goal)_

Establish document ownership and propose corrections without changing governance authority.

## Acceptance criteria

_Source: PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L297 (Stage 2 acceptance and remaining decisions)_

Approve the path-preserving strategy, the exact proposed XYZ principles corrections, and the
specific adoption boundary for Constitution/anti-scope before execution. Also decide whether the
PDDA.md first-line marker is a prerequisite or a separate upstream follow-up; without that decision
this report does not promise a durable all-five first-line outcome.

After approval, sweep current references in ROUTER, ARCHITECTURE, README, HOW-TO-USE, SOP, AGENTS,
skills and PDDA consumers; retain historical CHANGELOG entries. A bounded resolver should cover
changed governance docs and their current top-level inbound references, report unrelated baseline
defects separately, and test both missing files and headings with non-empty input controls. The
four provenance links should point to the verified predecessor snapshot. Required Stage 2 gates
remain PDDA run, tier 1, full validate for changes outside PROJECT, and targeted governance. Run
mutation-heavy suites in a separate disposable full clone and compare Git identity before/after.
Finally inspect all ROUTER startup targets and every PROJECT document's first line. These checks
have **not** been claimed as completed for unimplemented Stage 2 edits.

## Open questions

_missing_

## Write set

- `PROJECT/CONSTITUTION.md` (issue#453:L7)
- `PROJECT/DO-NOT-BUILD.md` (issue#453:L7)
- `PROJECT/PDDA-MODE-GUIDE.md` (issue#453:L26)
- `PROJECT/PDDA-SYNC-POLICY.md` (issue#453:L26)
- `PROJECT/PDDA.md` (issue#453:L26)
- `GUIDING-PRINCIPLES.md` (issue#453:L40)
- `AGENTS.md` (issue#453:L42)
- `src/acorn-extract.js` (issue#453:L48)
- `utils/pdda/pdda-lib.sh` (issue#453:L60)
- `ROUTER.md` (issue#453:L66)
- `.github/workflows/ci.yml` (issue#453:L67)
- `ARCHITECTURE.md` (issue#453:L69)
- `utils/py/releases_app.py` (issue#453:L85)
- `releases.sql` (issue#453:L87)
- `HOW-TO-USE.md` (issue#453:L129)
- `SOP.md` (issue#453:L130)
- `CHANGELOG.md` (issue#453:L132)
- `utils/pdda/pdda.sh` (issue#453:L141)
- `validate.sh` (issue#453:L142)
- `utils/pdda/PDDA-SOURCE.md` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L117)
- `src/claim.js` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L219)
- `src/events.js` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L219)
- `src/identity.js` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L219)
- `bin/tick` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L219)
- `src/project.js` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L220)
- `utils/py/rtl.py` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L221)
- `relay-automation/hooks/relay-xyz-guard.sh` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L222)
- `utils/py/codex-turn.py` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L230)
- `relay-automation/relay-turn-lib.sh` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L230)
- `utils/marathon-plan.sh` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L265)
- `utils/swarm-preflight.sh` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L265)
- `utils/py/marathon_drive.py` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L273)
- `relay-automation/marathon.sh` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L275)
- `utils/pdda/pdda-sync-manifest.conf` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L396)
- `relay-system/2026-09-05/gh453-plan-qa.md` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L405)
- `relay-system/2026-09-05/gh453-report-qa.md` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L411)
- `relay-system/2026-09-05/gh453-stage2-plan-qa.md` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L439)
- `utils/py/swarm_preflight.py` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L459)
- `test/gh370-progress-telemetry.sh` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L473)
- `test/gh365-validate-telemetry.sh` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L473)
- `relay-system/2026-09-05/gh453-stage2-final-qa.md` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L492)

## Unresolved file names

- `package.json` (issue#453:L47; 3 tracked files share this name)
- `package-lock.json` (issue#453:L47; 2 tracked files share this name)
- `README.md` (issue#453:L53; 56 tracked files share this name)
- `ROADMAP.md` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L227; 72 tracked files share this name)
- `marathon.sh` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L273; 2 tracked files share this name)
- `ci.yml` (PROJECT/2-WORKING/GH-453-GOVERNANCE-IDENTITY-AUDIT.md:L290; 2 tracked files share this name)

## Contract probes

- none
