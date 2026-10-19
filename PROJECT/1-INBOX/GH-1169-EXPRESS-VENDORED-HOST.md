---
gh_issue: 1169
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1169
title: "express: vendored-host mode — docs lane uses the host's PDDA gate; host hook, harness tool resolution"
status: "Captured — plan drafted, awaiting plan QA"
created: 2026-10-19
updated: 2026-10-19
owner: claude
goal: "Let /express --docs-only land in a vendored host (a repo using the harness from .xyz/) using the host's own PDDA gate, with XYZ Forge's behaviour unchanged"
doc_type: feature
effort: 2
complexity: 2
risk: 2
phases: 1
related:
  - PROJECT/3-COMPLETED/GH-1144-EXPRESS-DEFAULT-BRANCH.md
  - utils/py/express.py
  - utils/py/harness_paths.py
fix_probes:
  - "grep -q 'is_vendored' utils/py/express.py"
  - "grep -q 'HOST_DOCS_SUITE' utils/py/express.py"
---

# GH-1169 — express vendored-host mode

Issue #1169 is the brief. Follows #1144 (PR #1162, merged `7fb309eb`), which made express resolve the host's
integration branch. Operator choice (2026-10-19): Forge vendored-host mode, not copying Forge's gate files into hosts.
Branch `feat/XYZ-forge-gh1169-express-vendored-host-2026-10-19` off `development@7eeae804`.

## Status

| What was just completed | What's next |
|---|---|
| Issue filed, clone provisioned off `origin/development` (`7eeae804`, hooks installed), recon, plan drafted | Codex plan QA, then promote to 2-WORKING |

## Observed today (7eeae804)

- Host probe: HiQS-Labs/XYZ-layout-engine with `.xyz/` re-vendored at `7eeae804`, on a throwaway task branch:
  `python3 .xyz/utils/py/express.py --root . check --issue 65 --docs-only --repo HiQS-Labs/XYZ-layout-engine --dry-run`
  resolves `main`, then refuses `gate-unwired — … githooks/install.sh is missing`.
- Host layout: no `validate.sh`, no `githooks/`, no `test/pdda-repo-contract.sh` at the root; `.xyz/test/pdda-repo-contract.sh`
  exists; the host's own PDDA install is `utils/pdda/pdda.sh` (+ `.pdda-mode`: `observe`, `ROADMAP_SOURCE=releases`).
- `utils/py/express.py` root-layout assumptions:
  - `gate_check` (`:374-379`) runs `<root>/githooks/install.sh --check`; called by `cmd_check` (`:511`) and `cmd_land` (`:848`).
  - Step 4 (`:599-610`) requires `<root>/<suite>` to exist and be named in `<root>/validate.sh` TESTS.
  - `DOCS_SUITE = "test/pdda-repo-contract.sh"` (`:86`); `normalize_suite` (`:248-254`) prefixes `test/`;
    `receipt_command` (`:257-258`) is `bash <suite>`; the suite runs as `subprocess.run(["bash", <root>/<suite>])` (`:842`);
    `main()` forces `--docs-only` to `DOCS_SUITE` (`:1337-1340`).
  - `releases_app(root)` dies unless `<root>/utils/py/releases_app.py` exists ("requires a canonical-repo layout");
    `reconcile_gated` (`:964-978`) requires `<root>/utils/py/wave_reconcile.py`.
- `test/pdda-repo-contract.sh` is `PDDA_ACTIVITY_LOG=${…:-/dev/null} exec utils/pdda/pdda.sh run` — the Forge docs
  lane is the repo's own PDDA gate. Forge's `.pdda-mode` is `full`; the host's is `observe` ("report only, never
  blocks"). Host today: `PDDA_MODE=full utils/pdda/pdda.sh run` → rc 0, no errors, 21 warnings (same as observe).
- `utils/py/harness_paths.py` provides `is_vendored(path)` and `resolve_tool(repo_root, rel, prefer_repo=True)`; its
  docstring tells new consumers to pass `prefer_repo=False` so a host's same-named file cannot shadow the harness copy.
- `wave_reconcile.py` already runs in vendored hosts (GH-358/GH-429 suites) and takes `--base` (#1144).
- Host ledger: `releases next` → `0.0.1 RendererSpike (draft) … gid=rel-01M3XFJBJBF1B4ARDV7M6WSVC9`, an old draft;
  express's ledger phase would dial into it unless `--release` is passed (existing behaviour, not changed here).
- Prior art: `prior_art_recon.py --query "express vendored host"` lists #1162 (the predecessor) and keyword matches;
  no open PR or issue covers vendored-host express.

## Preflight bet

- Outcome sought: `/express --docs-only` works in a vendored host such as XYZ-layout-engine, with a docs gate that can
  fail, and XYZ Forge unchanged.
- Smallest viable bet: in `express.py`, detect a vendored host once (`harness_paths.is_vendored` on the running
  script) and, only then: (1) the docs lane runs the host's PDDA gate `utils/pdda/pdda.sh run` under `PDDA_MODE=full`
  (Forge's mode) with `PDDA_ACTIVITY_LOG=/dev/null`, recorded as its own suite spelling; (2) gate wiring accepts the
  host's installed `pre-push` hook, or proceeds with an explicit "no pre-push gate in this host" line; (3) harness tools
  resolve through `resolve_tool(root, rel, prefer_repo=False)`.
- Not built: code hotfixes in hosts without `validate.sh` (still `suite-unregistered`); copying Forge gate files into
  hosts (operator rejected); fixing host ledgers' active release; new suites (GH-831).
- Alternatives rejected: (a) running `.xyz/test/pdda-repo-contract.sh` — it executes `.xyz/utils/pdda/pdda.sh`, the
  harness's copy, not the host's installed PDDA, and would inspect whatever root that copy resolves; (b) honouring the
  host's `observe` mode — a docs gate that never fails is decorative (AGENTS: "a check that cannot fail is not a check");
  (c) requiring hosts to install Forge's `githooks/` — the operator rejected adding Forge gate machinery to hosts.
- Rollback: revert the commit; canonical (non-vendored) behaviour is untouched.
- Reversibility: **Easy** to revert the code; a misdirected landing cannot be undone by a revert. Stop signal: any
  host run whose suite, receipt or destination differs from the plan. Last safe checkpoint: before the first push.

## Changes (ordered, verification inline)

1. `express.py`: `VENDORED = harness_paths.is_vendored(<this file>)` computed once in `main()` (module default `False`
   so imports and Forge behave as today). `HOST_DOCS_SUITE = "utils/pdda/pdda.sh run"`.
2. Docs lane in a vendored host: `main()` sets `args.suite = HOST_DOCS_SUITE` instead of `DOCS_SUITE`;
   `normalize_suite` returns `HOST_DOCS_SUITE` unchanged (no `test/` prefix); Step 4 checks `utils/pdda/pdda.sh` exists
   and skips the `validate.sh` registry only for this suite; Step 7 runs `["bash", "utils/pdda/pdda.sh", "run"]` with
   `PDDA_MODE=full` and `PDDA_ACTIVITY_LOG=/dev/null`; the receipt `command` is `bash utils/pdda/pdda.sh run` and resume
   validates against the same spelling. A non-docs run in a vendored host without `validate.sh` refuses
   `suite-unregistered` as today.
3. Gate wiring in a vendored host: if `githooks/install.sh` exists, use it as today; else if `.git/hooks/pre-push` is an
   executable file, accept it and print `gate: host pre-push hook`; else print `gate: none — this host has no pre-push
   hook (the landing push bypasses pre-push by lane design)` and continue. Canonical repos keep `gate-unwired`.
4. Tools: `releases_app(root)` and `reconcile_gated` use `harness_paths.resolve_tool(root, rel, prefer_repo=False)`
   when vendored; canonical keeps the root paths (byte-identical behaviour).
5. `skills/2-daily/express/SKILL.md`: a short "Vendored hosts" paragraph (docs lane = host PDDA gate in full mode;
   host hook or none; pass `--release` if the host's next release is stale; code hotfixes need a `validate.sh`
   registry).
6. Verification (no new suite, GH-831):
   - `test/gh267-express-skill.sh` and `test/gh358-wave-reconcile-vendored-paths.sh` green (disposable clone).
   - Manual host checks under `TESTS-RESULTS/2026-10-19+GH-1169/`: on a disposable copy of XYZ-layout-engine's shape
     (vendored `.xyz/` from this branch, `main`, host PDDA install, a doc-only change on a task branch, local bare
     origin, gh stub for issue/repo identity): `check`/`run --docs-only --dry-run` pass pre-flight and preview
     `origin/main`; a non-preview `run --docs-only` lands on `main`, the receipt says `bash utils/pdda/pdda.sh run`,
     closeout and reconcile complete; a code change refuses `suite-unregistered`.
   - Red controls: (a) a doc in `PROJECT/2-WORKING/` without frontmatter makes the host docs gate fail under
     `PDDA_MODE=full` (and the same file passes under the host's `observe` mode, showing why full is forced);
     (b) with the vendored branch disabled, the same host run refuses `gate-unwired` as today.
   - Smoke (GH-1088): main path — the real XYZ-layout-engine `check --docs-only --dry-run` on a throwaway doc-only branch
     passes pre-flight; adjacent — the same in XYZ Forge prints output identical to `origin/development`'s express.
   - Final gate per `utils/ci-route.sh` on the changed paths, once, on the final commit.

## Non-goals

No code-hotfix lane for hosts without a registry; no Forge gate files in hosts; no change to host ledgers or to
`wave_reconcile`; no new suite or gate.

## Risks

- A host's PDDA install drifts from Forge's (older `pdda.sh`): the gate is still the host's own canonical check, which is
  the point; recorded in the receipt command.
- A stale "next" release in a host ledger: express dials into it unless `--release` is passed; documented, not changed.
- Shadowing: a host carrying its own `utils/py/releases_app.py` could win under repo-first resolution; `prefer_repo=False`
  avoids it.

## Acceptance

- Vendored host fixture: `run --docs-only` lands on `main` with receipt `bash utils/pdda/pdda.sh run`, reconciles; dry-run
  previews `origin/main`; code change refuses `suite-unregistered`; host gate fails on an injected PDDA error in full mode.
- Real XYZ-layout-engine: `check --docs-only --dry-run` passes pre-flight.
- XYZ Forge: `test/gh267-express-skill.sh` unchanged and green; dry-run output identical to before.

## Per-issue map

| Issue | Requirement | Clone / branch | State |
|---|---|---|---|
| [#1169](https://github.com/HiQS-Labs/XYZ-forge/issues/1169) | Changes 1–6 | `XYZ-forge-gh1169-express-vendored-host-2026-10-19` / `feat/…` | Plan drafted |

## Rating rationale (2026-10-19)

`rated 35/25/50/50`. Severity 25: express unusable in vendored hosts; workaround is a manual landing, no data at risk.
Priority 35: operator asked for it now; one observed blocked use (XYZ-layout-engine, 2026-10-18/19). Appeal 50: neutral.
Effort 50: one file's host branch plus resolver reuse, with a host-shaped fixture to build for verification. Recurrence:
two related incidents in 14 days (GH-1144 branch, this layout gap) in the same host; trend unknown.

## Evidence

| Check | Result |
|---|---|
| Plan QA | pending |
