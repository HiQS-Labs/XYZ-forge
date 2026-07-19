---
gh_issue: 206
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/206
title: "Marathon: vendored .xyz/ install conflates harness-home with repo-root — won't run without MARATHON_ROOT + bin overrides"
status: Closed — built 2026-07-15 on marathon branch (agy-reviewed, Approved, gate green); follow-up #209 closed
created: 2026-07-15
updated: 2026-07-15
owner: noel
doc_type: bug
complexity: 3
risk: 3
effort: 3
phases: 1
ratings_provisional: true
non_goals:
  - Not changing the vendoring mechanism (xyz-vendor.sh) itself — only how marathon.sh resolves its two roots.
  - Not sweeping every script in this pass; swarm-preflight.sh / marathon-drive.sh get the same split only if the marathon lane's review confirms they share the defect.
related:
  - relay-automation/marathon.sh
  - relay-automation/marathon-drive.sh
  - relay-automation/xyz-vendor.sh
  - relay-automation/consult.sh
goal: >
  Split marathon.sh's single ROOT into MARATHON_HOME (harness: bin/, utils/, phases defaults, from
  the script's own location) and MARATHON_ROOT (target repo: briefs, TICK_REPO_ROOT, commits, from
  git rev-parse), so a vendored .xyz/ install runs from the repo root with zero env overrides.
---

## Status

| What was just completed | What's next |
|---|---|
| Lane `gh206-root-split` BUILT 2026-07-15 on `marathon/gh-205-turn-timeout-false-halt-2026-07-15` (codex build `4d60689`, agy Approved `a07ef5e`, gate green): `MARATHON_HOME`/`MARATHON_ROOT` split landed in `marathon.sh` + README + vendored-layout test. | Merge via the marathon branch PR. Follow-up [#209](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/209): the new PWD-based `MARATHON_ROOT` fallback leaked a fixture render/commit + tick token into the real repo mid-run — needs a foreign-CWD guard + regression test. |

## Problem (confirmed in code, not assumed)

`relay-automation/marathon.sh:37-40` derives one `ROOT` from the script location
(`HERE="$(dirname BASH_SOURCE)"; ROOT="${MARATHON_ROOT:-$HERE/..}"`) and uses it as **both** the
harness home (`TICK_BIN="$ROOT/bin/tick"`, `MARATHON_YAML_BIN="$ROOT/bin/marathon-yaml"`) **and**
the repo root (brief paths `"$ROOT/$brief"`, `TICK_REPO_ROOT`). In the dev checkout those coincide;
in a vendored `.xyz/` they are `repo/.xyz/` vs `repo/`, so **no single ROOT value is correct**:

- Default: briefs resolve to `.xyz/marathon-plans/...` → `brief file not found`.
- `MARATHON_ROOT=<repo>`: bins resolve to `<repo>/bin/*` → `No such file or directory`.
- Only a 4-variable override set (`MARATHON_ROOT` + `MARATHON_YAML_BIN` + `TICK_BIN` +
  `XYZ_APPEND_BIN`) runs at all. Reproduced live in sleuth-app 2026-07-15 (vendored `.xyz/` at
  source_commit `4e12133`).

## Ask / Definition of done

- [ ] `marathon.sh` derives `MARATHON_HOME` from the script location (bin/, utils/, phase-render
      defaults) and `MARATHON_ROOT` from `git -C "$PWD" rev-parse --show-toplevel` (briefs,
      `TICK_REPO_ROOT`, commits), each independently overridable — mirroring consult.sh's
      `CONSULT_ROOT` handling.
- [ ] A vendored install "just runs": `.xyz/relay-automation/marathon.sh --plan <repo-relative>`
      from the target repo root works with **no** env overrides.
- [ ] Dev-checkout invocation (home == root) keeps working unchanged.
- [ ] Audit `marathon-drive.sh` (and note `swarm-preflight.sh`) for the same conflation; fix or file
      follow-up per review verdict.
- [ ] `test/marathon.sh` gains a vendored-layout case (harness dir ≠ git toplevel).

## Reversibility & blast radius

Medium. Path-resolution change in the marathon entry script; wrong split breaks dev-checkout runs,
which is why the DoD pins both layouts under test. Revertible in one commit; no data or protocol
change.

## Provenance

Filed from a live sleuth-app marathon run (2026-07-15) alongside #205 (300s cap) and #207
(retry/resume brittleness); bundled with both for one marathon.

## Swarm Preflight Contract

```json
{"target":{"repo":".","ref":"main"},"gate":"bash validate.sh","fix_probes":[{"type":"grep_present","path":"relay-automation/marathon.sh","pattern":"ROOT/bin/tick"},{"type":"grep_absent","path":"relay-automation/marathon.sh","pattern":"MARATHON_HOME"}],"artifacts":["relay-automation/marathon.sh","relay-automation/marathon-drive.sh","test/marathon.sh","test/marathon-drive.sh","relay-automation/README.md"],"remediation":{"source":"self#ask--definition-of-done","criteria":"MARATHON_HOME/MARATHON_ROOT split landed; vendored .xyz/ runs with zero overrides; dev-checkout unchanged; bash validate.sh green."},"lanes":{"orchestrator_only":["relay-automation/relay-turn-lib.sh","bin/",".tick/"]}}
```
