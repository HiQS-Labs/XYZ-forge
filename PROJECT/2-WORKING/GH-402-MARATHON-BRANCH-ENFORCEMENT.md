---
gh_issue: 402
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/402
title: "A marathon commits to whatever branch the target has checked out — the suggested marathon/<slug> branch is advisory text nothing enforces"
status: "2-WORKING — captured 2026-08-10 for release 0.3.0 Nightwatch. Issue has no `## Acceptance` section; criteria authored in a separately-titled section below, not inside `## Acceptance`. Phase 1 (the driver refusal) cannot be a marathon lane — its write-set is `utils/py/marathon_drive.py`, the running driver — and must ship as a direct PR. Awaiting preflight for phase 2 only."
created: 2026-08-10
updated: 2026-08-10
owner: noel
doc_type: project
release: "0.3.0 Nightwatch"
complexity: 3
risk: 3
effort: 2
phases: 2
ratings_provisional: true
roadmap_exempt: false
related:
  - "#69 (GH-69, SHIPPED) — the origin of this exact mechanism. Its own design doc records the enforcement point as Stage 3, an *orchestrating agent* reading `branch_ready: false` from the packet and prompting a human before invoking `marathon-drive`. That is a human-in-the-loop UI convention, not code. #402's finding is what happens when the marathon runs with no orchestrating agent present to honor Stage 3 — e.g. headless/background execution."
  - "#378 — the green-suite precondition; cited by the issue itself as 'the other thing a marathon checks about its target before running'."
  - "skills/10days/SKILL.md:382 — the one caller in this repo that DOES cut a branch itself (`git checkout -b marathon/10days-<today>`) before firing marathon-drive, and has no step anywhere in the skill that restores the prior branch afterward — directly matching the observed incident of a background marathon leaving this repo's root parked on a `marathon/*` branch."
non_goals:
  - "Auto-cutting or auto-checking-out a branch on the operator's behalf. The issue's own 'Alternatives considered' rejects this (mutates the operator's checkout, sits badly with GUIDING-PRINCIPLES §8 and concurrent sessions) and the proposed fix is a refusal, not a checkout."
  - "Restoring the operator's prior branch after a marathon completes. The issue's proposed fix only prevents a NEW marathon from starting on the receiving repo's default branch; it does not touch what branch the repo is left on when the run ends. See 'Acceptance — deviations from the issue' below — this is a real gap, not covered by the issue as written."
  - "Cross-repo `--target-root` branch cutting. Out of scope per GH-69's own non_goals, carried forward here."
  - "Changing `relay-turn-lib.sh` worktree isolation (`rtl_worktree_begin`/`rtl_worktree_end`/`rtl_enforce`) itself. Isolation already commits nothing that reaches a push (`rtl_enforce` stages the allowlist and commits file-scoped, no push); the defect is in the OUTER driver commit path, not the turn-kernel isolation layer."
goal: >
  swarm-preflight computes a suggested marathon/<slug>-<date> branch and a branch_ready flag, and
  renders an operator-facing prompt string into the packet when the branch does not exist yet. No
  code on the path from a fired marathon to its first git commit reads branch_ready, checks the
  current branch, or refuses to proceed. Make the driver refuse to commit onto the receiving repo's
  default/trunk branch by default, so the packet's advisory text becomes an enforced precondition
  for at least the one case (headless/unattended execution) where GH-69's original enforcement point
  — an orchestrating agent prompting a human — cannot fire because no such agent is present.
---

# GH-402 · marathon branch enforcement is a packet string, not a code gate

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-10 for release 0.3.0 Nightwatch. Verified against `development` (`utils/py/swarm_preflight.py`, `utils/py/marathon_drive.py`, `relay-automation/relay-turn-lib.sh`, `relay-automation/marathon-closeout.sh`, `relay-automation/xyz-sync.sh`, `skills/10days/SKILL.md` are byte-identical between the checked-out `feature/agent-devtools-fuzzing` worktree and `development` for the files that matter here). The issue has no `## Acceptance` section — criteria authored below. Every file:line citation in the issue's own body is stale (the described code is real and unchanged in substance, but has drifted to different line numbers); corrected citations are given throughout this doc. | Preflight phase 2 (the `swarm_preflight.py` `ready=0` mirror) as a marathon lane. Phase 1 (the `marathon_drive.py` refusal) ships as a direct PR — see Reversibility & blast radius. |

**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/402

## The defect

**The mechanism exists and computes correctly; nothing consumes it.** `utils/py/swarm_preflight.py`
(all line numbers verified against `development`, not the issue's citations, which are stale — see
below):

- Current branch: `symbolic-ref --short HEAD` at `:1069`.
- `suggested_branch = f"marathon/{slug}-{today}"` at `:1075`, existence-checked against local and
  remote refs at `:1076-1084` to set `branch_ready`.
- `skip_branch_prompt = 1 if fm_risk == "1" and zone == "independent" else 0` at `:1231` — the
  GH-69 carve-out.
- The two prompt strings are built at `:1518-1521` and interpolated into the packet's
  `Suggested branch:` line at `:1529`. Confirmed verbatim:
  ```python
  if branch_ready == 0 and skip_branch_prompt == 0: br_prompt_str = " — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8"
  elif skip_branch_prompt == 1: br_prompt_str = " — carve-out: risk=1/independent zone, proceed on the current branch without asking"
  ```
- The `ready`/verdict computation (`ready = 1` initialized at `:1178`, every `ready, ready_next = 0, …`
  assignment at `:1245-1345`, verdict resolved at `:1398`) never references `branch`, `dirty`, or
  `skip_branch_prompt`. Confirmed by grep across that exact span: the only hit is the
  `skip_branch_prompt` assignment itself, never a read of it in a `ready = 0` branch. `dirty` (computed
  at `:1101-1105` from `git status --porcelain`) is written into the packet's `SP_DIRTY` field
  (`:1373`) and nowhere else. **Confirms the issue's central claim: none of this reaches the verdict.**
  The only git-state refusal in preflight is a failed `git fetch --prune` (`fetch_ok`, `:1088-1089`,
  folded into `fresh_blocked` at `:1121`) — connectivity, not branch.

`utils/py/marathon_drive.py`:

- The three `symbolic-ref` calls the issue cites are real, but at `:879`, `:882` (inside a nested
  `trunk_ref()` helper, `:878-882`) and `:930` — not `:703/:706/:735`. All three are confirmed
  reachable only from `marathon_run_github_log()` (`:884` onward), gated on `--log-github`
  (`:886-887`): reporting only, exactly as the issue says, just at different lines. `trunk_ref()` is
  `root`-scoped (uses the bare `root` variable, not `args.target_root or root`), matching the issue's
  note that it "would need to take a repo argument" to point at the receiving repo instead of the
  harness's own.
- `--require-clean` dies at `:1735-1736`, inside a block that otherwise only **warns**
  (`log("WARNING: workspace is not clean …")`, `:1733`) — confirmed opt-in as the issue states, at
  `:1735` not `:1307`.
- The `args.target_root or root` idiom the issue proposes reusing is real and used repeatedly
  (e.g. `:1020`, `:1144`, `:1217`, `:1322`, `:1450`, `:1533` — not the exact `:825/:1209/:1486` the
  issue cites, but the pattern and its intent are correct).

`relay-automation/relay-turn-lib.sh`: `rtl_worktree_begin()` (`:580`) runs
`git worktree add --detach "$wt" HEAD` (confirmed, unquoted branch — detached, not a new branch), and
`rtl_enforce()` (comment at `:1092`, commit logic through `:1106-1114`) stages only the allowlist and
commits file-scoped with no push, confirmed by the header comment `"(3) stage ONLY the allowlist;
commit file-scoped; NO push."` — this is why the observed incident is recoverable pre-push, exactly as
the issue states.

**Existing branch refusals confirmed elsewhere, and confirmed NOT to cover this path:**
`relay-automation/marathon-closeout.sh:123` — `[[ -n "$HEAD_BRANCH" ]] || die_usage "detached HEAD is
not supported; pass --head"` — refuses only a detached HEAD, only at closeout (after the run), and only
when no `--head` override is given. `relay-automation/xyz-sync.sh:322` — `die "refusing update: harness
source branch '${branch:-detached}' is not canonical …"` — refuses distributing the harness itself from
a non-canonical branch; unrelated to a marathon's target repo.

**Root cause, found in this repo's own history and not stated in the issue:** this was never a gap
left by oversight. `PROJECT/3-COMPLETED/GH-69-MARATHON-BRANCH-PROMPT.md` — the doc that shipped
exactly this mechanism — designs the enforcement point as **Stage 3: "Orchestrating agent prompt. When
agent reads `branch_ready: false` from packet, ask operator before proceeding to `marathon-drive`"**
(`GH-69-MARATHON-BRANCH-PROMPT.md:40-41`), i.e. a human-in-the-loop convention carried out by whichever
Claude Code session is driving, not a code gate. That convention holds for an interactively-driven
marathon. It cannot hold for a marathon fired with no orchestrating agent reading packets — the
documented case is exactly `skills/10days/SKILL.md`, whose own procedure (`:382`) does
`git checkout -b marathon/10days-<today>` *before* firing (so headless 10days runs already self-satisfy
the "not on trunk" half by cutting their own branch) but has **no step anywhere in the skill file that
restores the prior branch after the run**. That is precisely the shape of the incident this repo's
own CHANGELOG.md acknowledges in passing at `CHANGELOG.md:239`: *"this clone is shared with
marathon/relay drivers that can leave it dirty or parked on a `marathon/*` branch"* — and it matches
this drafting session's own operator memory of a background marathon leaving this repo's root checked
out on a `marathon/*` branch, so a later, unrelated commit landed there silently instead of on
`development`.

## Acceptance

Issue #402 contains **no `## Acceptance` section** — TL;DR, three narrative sections, "Proposed fix"
(three numbered pieces plus an optional second layer), "Alternatives considered", and "Related" only.
There is no checklist to copy verbatim. Authored criteria are in the separate section immediately
below, per the drafting brief's instruction to never place authored criteria inside `## Acceptance`.

## Authored acceptance criteria (the issue defines none)

Scoped to **Phase 1 only** — the driver refusal, the one piece the issue's "Proposed fix" describes as
required (item 1-3 of three). Phase 2 (the `swarm_preflight.py ready=0` mirror) is explicitly
"optional" in the issue's own text and is deferred to its own criteria if picked up.

- [ ] `utils/py/marathon_drive.py` refuses, before its first commit, when the repo that will receive
      the commit (`args.target_root or root`, the existing idiom) is checked out on its default/trunk
      branch — defined as `origin/HEAD` if resolvable, else the branch current at driver start.
- [ ] `trunk_ref()` (currently `:878-882`, `root`-scoped) is generalized to take a repo path argument
      so it can be evaluated against the receiving repo, not only the harness's own `root`.
- [ ] The refusal is skippable by an explicit override flag, and by the existing `skip_branch_prompt`
      carve-out (`risk == 1` and zone `independent`) without requiring the flag.
- [ ] The refusal message names the `marathon/<slug>-<date>` branch preflight already suggests (the
      existing `SP_SUGGESTED_BRANCH` value) so the operator has the exact branch name to cut.
- [ ] No change to `relay-automation/marathon.sh`, `relay-automation/relay-turn-lib.sh`, or
      `utils/py/rtl.py` — this is a `marathon_drive.py`-only change per the issue's own "Proposed fix"
      reasoning (the driver is the last common point on every commit path).

### Acceptance — deviations from the issue

Not deviations from a verbatim checklist (there is none) — this section instead records where the
issue's own proposed fix, as written, does not close the gap it opens with:

1. **The issue names only one of two failure directions.** Its title and every section describe
   direction A — a marathon commits to whatever branch was already checked out when it started,
   defaulting badly to trunk. It never states direction B — **a marathon (or a skill that cuts its own
   branch, like `/10days`) leaves the repo checked out on a non-trunk branch when it ENDS, so a later,
   unrelated commit in a separate session silently lands there instead of on trunk.** This is the
   direction the drafting brief's real-world context names explicitly, and it is not a hypothetical:
   `skills/10days/SKILL.md:382` cuts `marathon/10days-<today>` and never restores the prior branch, and
   `CHANGELOG.md:239` independently acknowledges the clone "can [be] left … parked on a `marathon/*`
   branch." **The issue's proposed fix does not address direction B and could make it more common**:
   under the proposed refusal, the documented remediation is to cut and check out a `marathon/*`
   branch before firing (exactly what `/10days` already does) — which is precisely the state that
   causes direction B once the run ends and nothing checks the operator back out. Authored acceptance
   criteria above are scoped to direction A only, matching the issue; direction B is left as a
   non-goal (see frontmatter) and should be filed as a follow-on if the operator wants it fixed.

   **Direction B reproduced live during this doc's own drafting session, 2026-08-10.** It is no
   longer an inference from `/10days` plus a CHANGELOG line. While these capture docs were being
   written, a concurrent process cut and checked out `feature/agent-devtools-fuzzing` in the shared
   root clone and left it there. The root moved off `development` (last commit `d121cac`) to
   `68ade4d` mid-session, with no signal to the session already working in that tree. The next
   `git commit` would have landed this entire batch of capture docs on the fuzzing branch — silently,
   with every gate still green, because nothing anywhere checks which branch a commit is landing on.
   That is exactly the failure this deviation describes, and it happened **inside the repo that
   contains the issue**, to the session writing the issue's own capture doc. Batch 2 was landed from
   an isolated `git worktree` pinned to `development` instead, which is a workaround an operator has
   to know to perform — not a fix.

   Two details sharpen the case. First, the damage would have been invisible rather than loud: the
   commit succeeds, the tests pass, and the work is simply on the wrong branch. Second, the shared
   clone is the *normal* arrangement here — marathon drivers, relay turns and skills all operate on
   this one working tree, so any of them can move it under any other. Direction B is therefore not a
   `/10days` quirk; it is a property of the shared-root design that direction A's fix leaves intact.
2. **The issue's file:line citations for `utils/py/swarm_preflight.py` and `utils/py/marathon_drive.py`
   are stale** — every one checked in "The defect" above lands on unrelated code at the cited line
   number. The described logic is real and substantively unchanged; only the citations have drifted.
   `relay-automation/marathon-closeout.sh:123` and `relay-automation/xyz-sync.sh:322` are the two
   citations that check out exactly as written.

## Litmus tests

- **Direction A, default case:** on a repo whose current branch equals its resolvable `origin/HEAD`
  (or, with no upstream, whatever branch the driver started on), invoke `marathon-drive` with no
  override. A real fix refuses before any `git commit` runs against that repo and names the suggested
  branch. A plausible-but-wrong fix warns (matching the current `--require-clean` pattern) but still
  commits — that is not enforcement, it's the same advisory text moved one layer down.
- **Carve-out still works:** a `risk=1`/`independent`-zone lane proceeds on the current branch with no
  flag and no refusal — regressing this reopens GH-69's original intent.
- **Override still works:** the explicit override flag, passed on a trunk checkout, proceeds and
  commits — confirming the refusal is a default, not a hard block, per the issue's own "Proposed fix."
- **A fix that adds an automatic `git checkout -b` fails this lane's own non-goals** — the issue's
  "Alternatives considered" rejects this explicitly, and a reviewer should treat an auto-checkout as
  scope creep even if it "solves" the acceptance criteria above.
- **Not proof of anything:** a green `validate.sh` run. No existing test in this repo currently
  exercises this path (`test/` has no branch-refusal fixture at time of capture), so the gate protects
  against collateral damage only; the reviewer must actually invoke the changed code against a
  synthetic trunk checkout to confirm the refusal fires.

## Reversibility & blast radius

**Medium — write-set includes the running marathon driver, which disqualifies Phase 1 from marathon
execution.** `utils/py/marathon_drive.py` is named explicitly in this repo's self-modification
constraint (a lane whose write-set includes the running driver cannot be a marathon lane — it would
edit the code gating its own run). **Phase 1 must ship as a direct PR, not a fired marathon.** Note
also: `relay-automation/marathon-drive.sh:utils/py/marathon_drive.py` is one of the 12 frozen twin
pairs in `test/gh308-frozen-twin-guard.sh:23` — but only the Bash half (`marathon-drive.sh`) is frozen
(`frozen_paths()` only collects the left side of each pair); `marathon_drive.py` is the Python
authoritative side and is editable with no `Frozen-twin-exception:` trailer required.

Phase 2 (`utils/py/swarm_preflight.py`, mirroring `ready=0` under the same condition it already prints
the prompt for) touches `utils/swarm-preflight.sh:utils/py/swarm_preflight.py`, also a frozen-twin
pair (`test/gh308-frozen-twin-guard.sh:24`) — same rule: only `utils/swarm-preflight.sh` is frozen, the
Python side is editable freely. Phase 2 does **not** touch the running driver or the turn kernel and
**can** be a marathon lane, but only makes sense chained after Phase 1 ships (there is nothing for it
to mirror otherwise).

**Blast radius if wrong:** a refusal that fires too aggressively blocks every marathon on every target
until the operator learns the override flag — annoying, loud, and safe (fails closed). A refusal that
fires too rarely reproduces the status quo (silent commits onto trunk) — the failure mode already
observed live. Neither is destructive; `git commit` is always revertible pre-push, and `rtl_enforce`'s
"NO push" behavior (confirmed above) means nothing in this repo's own git history is at risk from a
bad first cut. Fully revertible by reverting the PR.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "grep_absent", "path": "utils/py/marathon_drive.py", "pattern": "def trunk_ref(repo" }
  ],
  "artifacts":     ["utils/py/marathon_drive.py"],
  "artifacts_new": [],
  "remediation":   { "source": "issue #402", "criteria": "refuse in the driver, before the first commit, when the repo receiving the commit is on its default/trunk branch, unless overridden — ranking summary only, NOT the definition of done (that is the Authored acceptance criteria block above, since the issue itself has no ## Acceptance)" },
  "lanes": { "agy_safe": [], "orchestrator_only": ["utils/py/marathon_drive.py"] }
}
```

**This contract describes Phase 1's shape for documentation purposes only — it is NOT fireable as a
marathon lane.** Phase 1's write-set is the running driver (see Reversibility & blast radius above);
per this repo's self-modification constraint it must ship as a direct PR reviewed by a human, not
through `swarm-preflight` → `marathon-drive`. `lanes.orchestrator_only` reflects that no agy/aider
lane should touch this file at all, driver or not.

**Probe polarity** (probes detect the **bug**, not the fix): `grep_absent` on the pattern
`def trunk_ref(repo` reports the fix as still required while `trunk_ref()` keeps its current
zero-argument, `root`-scoped signature (`def trunk_ref():`, confirmed at `:878`). Once `trunk_ref` is
generalized to accept a repo argument — the acceptance criterion above — the marker string appears and
the probe stops reporting. This is a proxy for "was the function actually generalized," not for "does
the refusal fire correctly"; the litmus tests above are what a reviewer should run to confirm the
latter, since a docs-only or comment-only edit could satisfy this probe without implementing the
refusal at all.

## Provenance

Filed as issue #402. This capture doc traces the mechanism back to `PROJECT/3-COMPLETED/GH-69-MARATHON-BRANCH-PROMPT.md`
(SHIPPED 2026-07-01), which designed the branch-suggestion/prompt machinery this issue finds unwired,
and forward to `skills/10days/SKILL.md` and `CHANGELOG.md:239`, both independent corroboration of the
"left on a marathon/* branch" failure direction the issue itself does not name. Captured 2026-08-10 for
release 0.3.0 Nightwatch; no wave assignment yet (Phase 1 cannot run as a marathon lane; Phase 2 would
need its own preflight).
