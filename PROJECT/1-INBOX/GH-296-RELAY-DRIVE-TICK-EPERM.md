---
title: relay-drive.sh EPERM on tick lock in a same-repo vendored .xyz reviewing an artifact outside .xyz/
status: Proposed (1-INBOX — not yet active)
created: 2026-07-23
owner: Noel Saw
gh_issue: 296
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/296
doc_type: bugfix
complexity: 3
risk: 2
effort: 3
phases: 1
ratings_provisional: true
reported_from: pdda
harness_commit: c9f9c67
non_goals:
  - Redesigning the vendored-.xyz layout itself — this is a path-resolution bug in relay-drive.sh/codex-turn.sh, not a critique of xyz-vendor.sh's design
related:
  - "#263 — near-identical isolation=0 EPERM symptom (same TICK_REPO_ROOT-vs-HARNESS mismatch class),
     ROADMAP.md claims '✅ SHIPPED — closed 2026-07-22 (PR #271, merge 2a2da17)', but the doc's own
     Phase 0 + QA checklists are entirely unchecked and its Status table still describes it as newly
     promoted and awaiting an operator fire — see 'Related work' below, this may be an unverified-closed
     regression, not a coincidental duplicate"
  - "#272 — same root-cause family (TICK_REPO_ROOT resolves wrong in a vendored same-repo lane), but a
     distinct symptom: a successful worktree-isolated (isolation=1) turn whose tick release lands in the
     wrong namespace, vs. this issue's pre-claim EPERM block"
goal: >
  A same-repo vendored-.xyz relay can drive a Codex/agy review turn against an artifact that lives
  outside .xyz/ (the normal case) without the turn-taker's sandbox blocking tick's own lock file.
---

# GH-296 — relay-drive.sh EPERM on tick lock in a same-repo vendored `.xyz` reviewing an artifact outside `.xyz/`

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Symptom
Driving a Codex review turn via `relay-drive.sh` + `codex-turn.sh` from a **vendored, same-repo `.xyz`**
setup (`.xyz/` lives inside the target repo, sharing its git top-level — via `xyz-vendor.sh`) fails to
claim the `tick` token, 100% reproducible, when the artifact under review lives outside `.xyz/`.

## Environment
- **Observed from:** `pdda` (vendored `.xyz/`)
- **Harness commit:** `c9f9c67`
- **Worker/CLI:** Codex CLI (`OpenAI Codex v0.144.6`)
- **Runtime:** Bash — `relay-automation/relay-drive.sh` + `relay-automation/codex-turn.sh` invoked
  directly; no Python entry point (`utils/py/relay_drive.py` / `codex-turn.py`) involved in this repro
- **Sandbox:** on (Codex's own internal `workspace-write` sandbox), driven from an un-sandboxed shell

## Reproduction
1. `pdda` has `.xyz/` vendored at its root (`xyz-vendor.sh vendor`). `find-harness.sh --env` resolves
   `HARNESS=/…/pdda/.xyz`, `TICK_REPO_ROOT=/…/pdda` — the true git top-level, a *different* directory
   than `HARNESS`, though the same git repo (`git rev-parse --show-toplevel` is identical from both).
2. Scaffolded a relay thread at `$HARNESS/relay-system/2026-07-23/pdda-status-qa.md`
   (`relay-automation/new-relay.sh`) reviewing `SKILLS/PDDA-STATUS/SKILL.md`, which lives at the outer
   repo root, outside `.xyz/`.
3. Drove it:
   ```
   CODEX_AGENT=codex ALLOW_PATHS="" CODEX_LOG=<path> \
   relay-automation/relay-drive.sh \
     --relay-file relay-system/2026-07-23/pdda-status-qa.md \
     --relay-task RELAY-pdda-status-qa \
     --agent-cmd relay-automation/codex-turn.sh \
     --review-once
   ```
   (Codex on PATH, `tick`/`claim`/`release` set up beforehand via the documented recipe.)

**Expected:** Codex claims the token, reads the relay file, appends graded findings, hands off.
**Observed:** two attempts, both fail claiming the tick token — exit 3 (genuine stall), no findings
appended.
**Frequency:** every time (2/2 attempts, both isolation settings below).

### Attempt 1 — `RELAY_WORKTREE_ISOLATION=1` (default)
Codex's sandbox allowlist is `[workdir=<ephemeral worktree>, /tmp, $TMPDIR,
/…/pdda/.xyz/.tick]` — but `tick` actually writes its lock at `/…/pdda/.tick/locks/claim.lock` (the
real git top-level's `.tick/`, where `TICK_REPO_ROOT` points it — `/…/pdda/.xyz/.tick` doesn't exist on
disk at all). Separately, the relay file itself never appeared inside the isolated worktree, because
`.xyz/` is entirely gitignored in the outer repo and `git worktree add` only materializes
tracked+committed content — Codex's own transcript shows it searching for the relay file and failing
to find it, independent of the lock issue.

```text
sed: relay-system/2026-07-23/pdda-status-qa.md: No such file or directory
...
Blocked: `relay-system/2026-07-23/pdda-status-qa.md` is not present in the workspace or allowed relay
locations. The mandated pinned claim also failed:
`EPERM: operation not permitted, open .../.tick/locks/claim.lock`
```

### Attempt 2 — `RELAY_WORKTREE_ISOLATION=0` (workdir = real `$HARNESS` = `.xyz`)
Codex's own sandbox is `workspace-write [workdir, /tmp, $TMPDIR]` — writes outside `.xyz` are blocked,
and `tick`'s lock is still outside it (`/…/pdda/.tick/`, not `/…/pdda/.xyz/.tick/`). Same failure:

```text
tick: error: EPERM: operation not permitted, open '/…/pdda/.tick/locks/claim.lock'
```

## Related work — possible unverified-closed regression, not a fresh coincidence

Two existing issues share this bug's root-cause family (`TICK_REPO_ROOT` resolution confusion in a
vendored same-repo `.xyz` lane):

- **[#263](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/263)** —
  `codex-turn.sh isolation=0 path can't reach the parent-root .tick lock in vendored installs`. Symptom
  is **identical** to this issue's Attempt 2 (`EPERM: open <repo>/.tick/locks/claim.lock`, `isolation=0`,
  driven from `cd $HARNESS`). `ROADMAP.md` marks it `✅ SHIPPED — closed 2026-07-22 (PR #271, merge
  2a2da17)`, and its doc lives in `PROJECT/3-COMPLETED/`. **But** the doc's own body still reads: Status
  table says "Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet
  operator-verified" / "What's next: Operator review of the contract, then fire," and every box in its
  Phase 0 checklist and QA checklist is unchecked (`- [ ]`, none `- [x]`). That is internally
  inconsistent with a "SHIPPED" claim, and this issue's own fresh repro (harness commit `c9f9c67`, which
  per `ROADMAP.md` postdates the claimed merge `2a2da17`) hits the exact symptom #263 describes. Read
  together, this suggests #263 may have been swept into a "closed" ROADMAP line by association with
  PR #271 (which also shipped #261/#266, sharing `relay-turn-lib.sh`) without independently landing its
  own fix or verification — **not confirmed**, just the evidence as found; a human should check whether
  `codex-turn.sh`'s `isolation=0` branch actually got the `--add-dir "$TICK_REPO_ROOT/.tick"` fix #263
  describes before trusting the "closed" status.
- **[#272](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/272)** — open,
  same root-cause family, but the *isolation=1* side: a worktree-isolated turn completes its review but
  its own `tick release`/`done` call resolves `TICK_REPO_ROOT` to a `.xyz`-suffixed path instead of the
  real root, so the result lands in the wrong namespace instead of failing loudly like this issue's
  Attempt 1 EPERM did.

  **Update (2026-07-23, later same session): CONFIRMED via a live A/B repro — PR #297 fixes this.**
  Built a real vendored install with this repo's own `relay-automation/xyz-vendor.sh` (not a hand-rolled
  approximation) into a fresh scratch git repo, so `.xyz/` genuinely shares the target's git toplevel —
  the exact shape both #296 and #272 describe. Drove the vendored `codex-turn.sh` (default `XYZ_PYTHON`
  dispatch → `codex-turn.py`) with CWD=`.xyz` and NO `TICK_REPO_ROOT` export (matching how
  `relay-drive.sh` actually invokes the shim — confirmed neither the Bash nor Python driver propagates
  it), capturing the STUB Codex's full invocation to inspect the prompt's pinned
  `TICK_REPO_ROOT="..."` string. **Pre-fix** (overlaid `development`'s `utils/py/{rtl,codex-turn,
  agy-turn,claude-turn}.py` into the same vendored install): the prompt baked in
  `TICK_REPO_ROOT="<target>/.xyz"` — the exact bogus namespace from #272's report — AND, worse than
  the doc originally theorized, `tick info <task>` queried against the REAL target root afterward
  still showed `status: open, handoff-to: codex`, meaning the harness's own GH-67 backstop release
  ALSO silently landed in the wrong namespace (it bridges through the same corrupted env). **Post-fix**
  (this branch, unmodified): the same repro bakes in the correct `TICK_REPO_ROOT="<target>"` and the
  backstop release lands where `tick info` on the real target actually sees it. Root mechanism traced
  precisely: `RelayTurnLib._run_rtl()` (`utils/py/rtl.py`) builds the bash subprocess env for every bridged
  `relay-turn-lib.sh` call — including `rtl_turn_prompt`, which is what LITERALLY BUILDS the prompt
  text handed to Codex/agy/claude — via `env["TICK_REPO_ROOT"] = os.environ.get("TICK_REPO_ROOT",
  self.root)`. Pre-#296-fix, `self.root` was `codex-turn.py`'s buggy `root` (defaulted to `xyz_root`,
  no git-toplevel fallback) whenever the caller didn't independently export a correct `TICK_REPO_ROOT`.
  Inside `rtl_turn_prompt`, `tickroot="${TICK_REPO_ROOT:-${RTL_ROOT:-}}"` — the (wrong) env var wins
  over the already-GH-160-corrected `RTL_ROOT` — and that wrong value gets baked LITERALLY into the
  turn prompt's pinned `TICK_REPO_ROOT="%s"` instruction. So a Python-runtime turn wouldn't just risk
  an EPERM (#296's symptom) — it would faithfully hand Codex a WRONG-but-confidently-pinned
  `TICK_REPO_ROOT` string, and Codex following it exactly explains #272's exact observed symptom
  (`TICK_REPO_ROOT="<repo>/.xyz"` in Codex's own invocation) without needing to invoke any LLM
  non-adherence theory. **Caveat:** #272 is labeled `runtime:bash`, and Bash's own `codex-turn.sh` does
  NOT have this bug (its `ROOT` was always git-toplevel-correct, so its exported `TICK_REPO_ROOT` was
  always correct too) — but `git merge-base --is-ancestor af7bb4d 70640ca` confirms the GH-264
  Python-default flip (`af7bb4d`) predates #272's own reported harness commit (`70640ca`), so Python
  was already the default runtime at the time of that report; the `runtime:bash` label may be a triage
  mislabel rather than a confirmed Bash repro (not fully resolved either way — the live A/B repro
  above used the Python runtime, matching the commit-ordering evidence, not a literal re-run of the
  original `sleuth-app` report). **Recommendation:** #272's own existing swarm-preflight contract
  (`PROJECT/2-WORKING/GH-272-TICK-REPO-ROOT-VENDORED-MISMATCH.md`) targets `rtl_tick_bin()`/the
  harness's own GH-67 backstop release at `relay-turn-lib.sh:1025-1049` — the WRONG function; the
  actual defect was in the Python shims' `root` default (now fixed here) and, transitively, in
  `RelayTurnLib._run_rtl()`'s env-building. That contract should be closed or redirected once #297
  merges, not fired as scoped — it would spend effort editing the correct-all-along
  `relay-turn-lib.sh` backstop logic while leaving the real (already-fixed) defect unremarked.

## Impact
Any same-repo vendored-`.xyz` relay reviewing an artifact outside `.xyz/` (the normal case — the
artifact is almost always in the actual target repo, not inside the vendored harness copy) cannot be
driven via `relay-drive.sh` right now. **Workaround exists and works on the first try:**
`relay-automation/consult.sh` with `CONSULT_ROOT=<outer repo>` — no `tick`/worktree dependency, so it
sidesteps the whole path-resolution problem. Not currently blocking (workaround available), but the
primary Path A recipe this repo's own `relay-xyz` skill documents is broken for this common layout.

**Self-recovery poisons the task id.** Confirmed from a second repro (below): when a turn-taker hits
this failure and tries to self-recover by running `tick break <task> --agent <a> --reason "..."`
(rather than leaving the token safely `claimed`), the token becomes `circuit_broken` —
**permanent and unrecoverable**. A later `claim`/`reap` on the same `--relay-task` id fails
(`is circuit_broken — only the claiming agent can mutate it`), and `tick` itself confirms the id is
spent (`use a fresh per-relay id`). So the blast radius isn't just "the turn stalls" — it's "the turn
stalls *and* burns its own relay-task id if the agent tries to self-recover," forcing a fresh id +
re-scaffold to retry at all.

## Confirmed independently — second repo, same harness commit
- **Observed from:** `sleuth-app` (vendored `.xyz/`), 2026-07-23, same harness commit `c9f9c67`.
- Same setup shape as this doc's Reproduction (§ above): `HARNESS=.../sleuth-app/.xyz`,
  `TICK_REPO_ROOT=.../sleuth-app`, relay file scaffolded under `$HARNESS/relay-system/...`, artifact
  under review living outside `.xyz/`.
- Hit the exact **Attempt 1** failure mode (isolation=1, relay file absent from the isolated
  worktree because `.xyz/` is gitignored) — did not additionally hit the pre-claim `.tick` EPERM this
  session's Attempt 1 log shows, since `relay-drive.sh` itself claims the token *before* handing off
  to Codex's own subprocess in this run's sequencing; Codex's *own* internal attempt to re-claim
  inside its sandboxed subprocess is what failed with the lock EPERM, matching this doc's diagnosis.
- Additionally surfaced the token-poisoning behavior above (`tick break` → `circuit_broken`) — not
  previously documented here.
- Full detail: [issue comment](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/296#issuecomment-5061043547).
- Workaround used: fresh `--relay-task` id + `RELAY_WORKTREE_ISOLATION=0` — succeeded on first retry,
  matching this doc's own workaround direction.

## Phase 0 — Diagnose & scope
> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Findings (2026-07-23, this session)

**Not an `HARNESS`-anchored sandbox-path bug in `relay-drive.sh` as originally guessed — the real
root cause is that `utils/py/codex-turn.py` (the Python turn shim, the actually-executing default
runtime since GH-264 flipped `XYZ_PYTHON` unset → Python) never received the GH-263/GH-36 fixes at
all, and independently mis-resolves its own `root`.**

- **`codex-turn.sh`'s Bash body is already correct.** `ROOT="${CODEX_TURN_ROOT:-"$(git rev-parse
  --show-toplevel 2>/dev/null || (cd "$HERE/.." && pwd))"}"` (relay-automation/codex-turn.sh:68)
  resolves `ROOT` via the CWD's git toplevel by design — so a vendored `.xyz/` (same git repo,
  different directory) still resolves `ROOT` to the true outer repo. `codex_extra_flags=(--add-dir
  "$TICK_REPO_ROOT/.tick")` is applied **unconditionally in both branches** (isolation=1 at line 157,
  isolation=0 at line 171 — the GH-263 fix, commit `8c361a0`). `test/codex-turn.sh`'s own (7b)/(7c)
  cases pin `XYZ_PYTHON=0` specifically to test this Bash path, with a comment explicitly flagging
  the gap: *"XYZ_PYTHON now defaults to 1 (GH-264), which would otherwise silently exercise the
  Python port."* That gap is exactly what happened.
- **`utils/py/codex-turn.py` (git history: last touched `fc59f9b`, well before the GH-263 fix
  `8c361a0`) never got the port.** Two independent defects, both confirmed by reverting the fix and
  re-running the new regression test (see below — reproduces the exact bogus `--add-dir` path from
  the bug report):
  1. `root = os.environ.get("CODEX_TURN_ROOT", xyz_root)` (old code) — no git-toplevel fallback like
     Bash's `ROOT`. Defaults straight to `xyz_root` (the harness's own `__file__`-derived directory)
     when `CODEX_TURN_ROOT` is unset, which is exactly what a vendored `.xyz/` run leaves unset.
  2. `codex_extra_flags = ["--add-dir", f"{root}/.tick"]` was built from `root`, not `tick_repo_root`
     — so even when `TICK_REPO_ROOT` is independently resolved correctly (e.g. by `find-harness.sh
     --env`, as this issue's repro did), the sandbox allowlist still pointed at the wrong `.tick`.
     **And only inside the `isolation=1` branch** — the `isolation=0` (default) branch built no
     `codex_extra_flags` at all, i.e. the GH-263 fix was never ported to this branch either.
  Confirmed via a stash-and-rerun: pre-fix, the new regression test observed `--add-dir
  /Users/.../xyz-3-agents-swarm/.tick` (this repo's own real `.tick`, standing in for the harness's
  vendored location) instead of the fixture's `TICK_REPO_ROOT/.tick` — the same class of bogus path
  the original report's Attempt 1 transcript showed (`/…/pdda/.xyz/.tick` instead of `/…/pdda/.tick`).
- **`agy-turn.py`/`claude-turn.py` share the same un-ported `root` default — follow-up, fixed in this
  same session/branch, not filed as a separate issue** (operator call: fold into GH-296 rather than
  spawn a new tracked issue, since it's the identical root cause found while reviewing this one).
  `agy-turn.py` has its own "CROSS-REPO mode" warning for `root != CWD git root`, but re-reading it:
  the warning is advisory-only (prints a heads-up, does not correct `root`), so it does not actually
  prevent the bug — it just narrates the symptom. `claude-turn.py` has no such warning at all.

### Follow-up finding: worktree-seeding is NOT where this bites agy/claude — a different native bug is
`RelayTurnLib`'s worktree/containment calls (`rtl_init`, `rtl_worktree_begin`) all bridge into the
*real* `relay-turn-lib.sh` via a subprocess shell-out, and that Bash function **already** self-corrects
a `root` that's a subdirectory of its own git repo (the GH-160 fix, `rtl_init` lines ~212–236) —
so a first end-to-end test of "does the turn still succeed" passed even with the pre-fix `root`, which
initially looked like a false reassurance that agy/claude had no bug at all. The REAL, still-native
(not bridged) bug is `rtl.claim_paths_for_turn(root, relay_file, allow_paths)` — every turn shim's
pre-launch `tick claim --paths` call, computed via a raw `os.path.relpath(relay_file, root)` in Python
with no equivalent self-correction. Confirmed directly:
```
root (wrong, = xyz_root)   -> claim --paths ../../../../../tmp/some-fixture-A/relay.md
root (correct, via CWD git toplevel) -> claim --paths relay.md
```
This resolves the earlier open checklist item below about why the relay file was missing from the
isolated worktree in Attempt 1 — it's this same escaping-path defect, just landing on the pre-launch
`tick claim` call, not the worktree seed itself (which the GH-160 bridge protects).

**A second native bug found while building the regression test for this:** `git rev-parse
--show-toplevel` (used by the new `resolve_turn_root` fallback) returns the *physical* path — on
macOS, `/var`/`/tmp` are symlinks to `/private/var`/`/private/tmp` — while a caller-supplied
`relay_file` can still be in the unresolved logical form. That symlink-form mismatch alone made
`claim_paths_for_turn`'s relpath climb out to an unrelated `../../..`-prefixed path even with the
*correct* root. This is the same GH-51 physical/logical-path class of bug `relay-turn-lib.sh`'s
`rtl_init` already guards against on the bridged side (`pwd -P` comparisons) — this native Python
computation had no equivalent, so `claim_paths_for_turn` now resolves both sides through
`os.path.realpath()` before computing the relative path.

### Fix landed this session
- `utils/py/rtl.py`:
  - new `resolve_turn_root(explicit_root, xyz_root)` — mirrors Bash's ROOT default (explicit override
    → CWD git toplevel → `xyz_root` fallback).
  - `claim_paths_for_turn` now resolves both `root` and `relay_file` through `os.path.realpath()`
    before computing the relative path (the GH-51-class symlink-form fix above).
- `utils/py/codex-turn.py`: `root = resolve_turn_root(os.environ.get("CODEX_TURN_ROOT"), xyz_root)`;
  `codex_extra_flags = ["--add-dir", f"{tick_repo_root}/.tick"]` built once, unconditionally, off
  `tick_repo_root` (not `root`) — parity with the Bash isolation=0 branch, GH-263's actual intent.
- `utils/py/agy-turn.py` / `utils/py/claude-turn.py`: same `resolve_turn_root` fix for `root`'s
  default (follow-up, same session).
- `test/codex-turn.sh`: new case (7d) — forces `XYZ_PYTHON=1`, leaves `CODEX_TURN_ROOT` unset, pins
  `TICK_REPO_ROOT` to the fixture root, asserts `--add-dir <fixture>/.tick` for both isolation states.
- `test/agy-turn.sh` / `test/claude-turn.sh`: new cases asserting the shim's own pre-launch `tick
  claim`'s recorded `--paths` (read directly from the `.tick/events/*.jsonl` claim event, not
  `tick info` — which shows `(none)` once the token is released later in the same turn) stays a
  clean repo-relative path with no `..` escaping.
  All five new/extended cases verified to **fail against the pre-fix code and pass post-fix** via a
  `git stash`/rerun/`stash pop` cycle — not just written and trusted.
- Rebuilt `skills/relay-automation/relay-pkg.tar.gz` (`make-pkg.sh`) twice — editing `test/*.sh` drifted
  the bundled tarball, caught by `relay-pkg-freshness.sh`.
- Full `validate.sh` run (unsandboxed per GH-177 guard) — see status table / CHANGELOG for the result.

### Checklist
- [x] Reproduce in the intake repo itself (or a scratch repo with the same vendored-`.xyz` +
      artifact-outside-`.xyz` layout) — confirm this isn't `pdda`-specific — reproduced generically via
      `test/codex-turn.sh` (no `pdda`-specific state needed; the bug is in the shared Python shim)
- [x] Read `relay-drive.sh`'s Codex-sandbox-path computation — **revised finding:** `relay-drive.sh`
      itself does not build the `--add-dir`/sandbox path at all; that logic lives entirely in
      `codex-turn.sh`/`codex-turn.py`, and the bug is in the latter (see Findings)
- [x] Read `codex-turn.sh`'s worktree-seeding step and confirm why the relay file was still missing
      from the isolated worktree in Attempt 1 — **resolved:** the worktree-seeding step itself
      (`rtl_worktree_begin`, bridged into the real `relay-turn-lib.sh`) is NOT the culprit — it
      already self-corrects a subdirectory `root` via the existing GH-160 fix. The actual defect is
      `rtl.claim_paths_for_turn`'s native (unbridged) `os.path.relpath(relay_file, root)` call, which
      has no such self-correction — confirmed directly (see Follow-up finding above) and fixed.
- [x] Decide the fix: allowlist `TICK_REPO_ROOT/.tick` explicitly (not a guess) — done, see above
- [x] Add a regression test exercising this exact layout — `test/codex-turn.sh` case (7d)
- [ ] Set/correct the triage ratings; clear `ratings_provisional` once real — left to the operator;
      actual fix effort was smaller than the provisional 3/2/3 (isolated 2-file + 1-test-file change)

### QA checklist — Phase 0
- [x] The repro is confirmed in the intake repo, not assumed from the reporting repo alone — confirmed
      via a stash/rerun of the actual production code path, not inference
- [x] A regression test covers the failure path before the fix lands — `test/codex-turn.sh` (7d),
      verified red pre-fix / green post-fix
- [x] The fix composes with the existing sandbox/worktree-isolation design rather than adding a
      parallel path — reuses the same `codex_extra_flags`/`--add-dir` mechanism GH-36/GH-263 already
      established, just fixes the Python port's variable and default
