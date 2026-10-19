---
gh_issue: 1169
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1169
title: "express: vendored-host mode — docs lane uses the host's PDDA gate; host hook, harness tool resolution"
status: "In progress — implemented and verified; final QA next"
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
| Implemented (`a48f56cc`, `944c43c9`); suites, host scenarios S1–S8 and smoke in `TESTS-RESULTS/2026-10-19+GH-1169/` | Final Codex QA, full gate on the final commit, PR to `development` |

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
   validates against the same spelling. The exception is bound to the `--docs-only` flag, not the suite spelling:
   `--suite "utils/pdda/pdda.sh run"` without `--docs-only` gets no registry bypass (plan QA F1). Missing registry: today
   a host without `validate.sh` reaches `open(<root>/validate.sh)` and raises `FileNotFoundError` (plan QA F1 probe;
   `express.py:604-606`), and a missing suite file refuses `suite-missing` first (`:601-603`). New behaviour, any repo:
   a non-docs run where `validate.sh` is absent refuses `suite-unregistered` ("no validate.sh TESTS registry in this
   repo — code hotfixes need a registered suite") before reading it; the existing `suite-missing` check stays first.
3. Gate wiring in a vendored host: if `githooks/install.sh` exists, use it as today; else if the effective pre-push hook
   (`git rev-parse --git-path hooks/pre-push`, which honours `core.hooksPath` — plan QA nit) is an executable file, accept it and print `gate: host pre-push hook`; else print `gate: none — this host has no pre-push
   hook (the landing push bypasses pre-push by lane design)` and continue. Canonical repos keep `gate-unwired`.
4. Tools: `releases_app(root)` and `reconcile_gated` use `harness_paths.resolve_tool(root, rel, prefer_repo=False)`
   when vendored; canonical keeps the root paths (byte-identical behaviour).
5. Recovery in a vendored host (plan QA F2): `recovery_recipe` (`express.py:358-366`) names the driver it is running from
   (`.xyz/utils/py` when vendored, `utils/py` otherwise) and, for `HOST_DOCS_SUITE`, the command
   `PDDA_MODE=full PDDA_ACTIVITY_LOG=/dev/null bash utils/pdda/pdda.sh run`. `skills/2-daily/express/SKILL.md`: a short
   "Vendored hosts" paragraph (docs lane = host PDDA gate in full mode; host hook or none; pass `--release` if the host's
   next release is stale; code hotfixes need a `validate.sh` registry) and a vendored variant of the recovery recipe
   (`PY=.xyz/utils/py`; the suite run as `PDDA_MODE=full PDDA_ACTIVITY_LOG=/dev/null bash utils/pdda/pdda.sh run`, not
   `bash "$SUITE"`; same receipt spelling; `resume --docs-only --base "$BASE"`). Canonical recovery text unchanged.
6. Verification (no new suite, GH-831):
   - `test/gh267-express-skill.sh` and `test/gh358-wave-reconcile-vendored-paths.sh` green (disposable clone).
   - Manual host checks under `TESTS-RESULTS/2026-10-19+GH-1169/`: on a disposable copy of XYZ-layout-engine's shape
     (vendored `.xyz/` from this branch, `main`, host PDDA install, a doc-only change on a task branch, local bare
     origin, gh stub for issue/repo identity): `check`/`run --docs-only --dry-run` pass pre-flight and preview
     `origin/main`; a non-preview `run --docs-only` lands on `main`, the receipt says `bash utils/pdda/pdda.sh run`,
     closeout and reconcile complete; a code change refuses `suite-unregistered`.
   - Red controls (plan QA F3), all on the same host-shaped fixture, no new suite: (a) a non-preview
     `run --docs-only` with a doc in `PROJECT/2-WORKING/` lacking frontmatter refuses `suite-red`; the bare remote's
     `main` tip is unchanged, no receipt is written, the gh stub logs no `issue close` and the ledger records no ship;
     the same doc passes standalone under the host's `observe` mode (why full is forced). (b) A decoy
     `<host>/utils/py/wave_reconcile.py` that exits 99 and writes a marker file: the clean end-to-end landing must succeed
     with no marker (express ran the vendored reconciler). express's own `releases_app` choice is checked with a narrow
     resolution probe (`express.releases_app(<host>)` returns `<host>/.xyz/utils/py/releases_app.py` even when a
     `<host>/utils/py/releases_app.py` exists), not with an end-to-end decoy: `wave_reconcile` deliberately resolves
     `releases_app` repo-first (`wave_reconcile.py:1834-1850`, `harness_paths.py:111-113,129-130`) and stays unchanged
     (plan QA F4). (c) With the vendored branch disabled, the
     same host run refuses `gate-unwired`. (d) A non-docs run with `--suite "utils/pdda/pdda.sh run"` refuses `suite-missing`
     (not an existing suite file; no docs bypass), and a non-docs run with an existing `test/demo.sh` refuses
     `suite-unregistered`; both with no traceback and no landing (plan QA nit).
   - Clean landing assertions: the landed SHA is reachable from the bare remote's `main`; the receipt's `commit` equals
     that SHA, `command` is `bash utils/pdda/pdda.sh run`, `environment` names `main`; reconcile ran with `--base main`.
   - Recovery: follow the vendored SKILL.md recipe on the fixture after a landing with no receipt; with the injected
     PDDA error the recipe records rc≠0 (no passing receipt); clean, it commits a receipt that
     `resume --docs-only --base main` accepts.
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
| [#1169](https://github.com/HiQS-Labs/XYZ-forge/issues/1169) | Changes 1–6 | `XYZ-forge-gh1169-express-vendored-host-2026-10-19` / `feat/…` | Implementing |

## Rating rationale (2026-10-19)

`rated 35/25/50/50`. Severity 25: express unusable in vendored hosts; workaround is a manual landing, no data at risk.
Priority 35: operator asked for it now; one observed blocked use (XYZ-layout-engine, 2026-10-18/19). Appeal 50: neutral.
Effort 50: one file's host branch plus resolver reuse, with a host-shaped fixture to build for verification. Recurrence:
two related incidents in 14 days (GH-1144 branch, this layout gap) in the same host; trend unknown.

## Evidence

| Check | Result |
|---|---|
| Plan QA | Codex, 3 rounds, Approved (`relay-system/2026-10-19/gh1169-plan-qa.md`). R1: F1 refusal order and `--docs-only` binding, F2 vendored recovery, F3 express-level red controls, nit hook path. R2: F4 decoy scoped to express's own tool calls, nit refusal codes |
| Covering suites (disposable clone, `944c43c9`) | gh267 113/0, gh358 8/0, gh425 OK, gh429 15/0 |
| Host fixture S1–S8 (`944c43c9`) | clean landing on `main` with receipt `bash utils/pdda/pdda.sh run`; broken doc → `suite-red`, nothing published (host `observe` would have passed it); root reconciler decoy unused; registry-less code runs refuse (`suite-unregistered` / `suite-missing`, no traceback); canonical express on the host still `gate-unwired`; vendored `releases_app` resolution; vendored recovery recipe red/green judged correctly by resume |
| Smoke | real XYZ-layout-engine GitHub clone: `check --docs-only --dry-run` PASS on `origin/main`; Forge task clone: new vs old express byte-identical |
| Deviation found and fixed | first implementation mapped `--suite "utils/pdda/pdda.sh run"` to its script outside the docs lane (refused `suite-unregistered`, plan says `suite-missing`); `944c43c9` limits the mapping to `--docs-only` |
