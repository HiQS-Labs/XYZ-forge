---
title: "XYZ harness quick-wins marathon bundle — staging README"
status: "Bundle (authored in LTVera; executes against HiQS-Labs/XYZ-forge)"
created: 2026-09-01
updated: 2026-09-01
owner: Noel Saw
roadmap_exempt: true
quad_exempt: true
goal: >
  Everything needed to fire the 2026-09-01 xyz-harness-quickwins marathon: MARATHON.yaml,
  four phase briefs, and the seven capture docs the preflight requires.
---

# How to execute this bundle

## Status

| What was just completed | What's next |
|---|---|
| Staging bundle prepared and preflighted. | Marathon execution across four phases. |

Umbrella tracking issue: [XYZ-forge #376](https://github.com/HiQS-Labs/XYZ-forge/issues/376) —
the marathon PR into XYZ-forge closes it.

The BUILD targets **HiQS-Labs/XYZ-forge** (issues
[#368](https://github.com/HiQS-Labs/XYZ-forge/issues/368)–[#374](https://github.com/HiQS-Labs/XYZ-forge/issues/374)),
not this repo. The bundle travels here because LTVera is where the findings were made
and where the operator is working; at execution time:

1. **Fresh XYZ-forge task clone** cut from `origin/development` (branching SOP — never
   the `XYZ-forge-gh365*` clones if they are still in use by another session).
2. Copy `capture-docs/GH-36*.md` and `GH-37*.md` → `<xyz-clone>/PROJECT/2-WORKING/`
   (their internal paths already assume that home) and commit them.
3. Copy `MARATHON.yaml` + `phases-briefs/` →
   `<xyz-clone>/PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/` and commit.
4. Validate + dry-run from the clone root (always dry-run first):
   `bin/marathon-yaml PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/MARATHON.yaml`
   `relay-automation/marathon.sh --plan PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/MARATHON.yaml --dry-run`
5. Fire without `--dry-run`. The gate is XYZ-forge's default `bash validate.sh`
   (aggregate tick acceptance suite) — no `--pre-advance-cmd` needed.
6. Land as a PR into XYZ-forge `development`, one umbrella close-out; close the seven
   issues with the closing keyword in the PR body.

## Pre-verified 2026-09-01 (disposable clone `XYZ-forge-quickwins-2026-09-01`)

- `bin/marathon-yaml`: valid (after `depends_on` was made single-id / transitive).
- `swarm-preflight.sh --gh-issue 368 … 374 --dry-run`: **ready (exit 0)** with the
  capture docs staged — capture docs are REQUIRED (blocked without them), artifacts[]
  must list files that EXIST at `development` (frozen Bash twins are rejected — list the
  authoritative `.py` twin), and new test files belong in the briefs' artifact lists,
  not the contracts'.
- `marathon.sh --plan … --dry-run`: "4 phase(s) would run in order", exit 0.

## Lane contingency

Builder/reviewer are codex + agy (the intended cross-model pair). If the codex workspace
is still out of credits (the condition that produced #368), note that p1's own fix is
what makes an `agy`/`agy-qa` same-lane pair routable — the workaround dispatcher used on
2026-09-01 in LTVera (via `MARATHON_AGENT_CMD`) is documented in issue #368. The
`claude` builder is per-call API-billed and is not authorized by default.
