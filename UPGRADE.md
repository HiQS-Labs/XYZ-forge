---
gh_issue: 255
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/255
title: "UPGRADE: flip the XYZ_PYTHON default from Bash to Python, reversibly and fleet-wide"
status: "Proposed (root doc — not yet active)"
created: 2026-07-20
updated: 2026-07-20
owner: noel
doc_type: runbook
complexity: 3
risk: 3
effort: 3
phases: 5
ratings_provisional: true
goal: >
  Turn the XYZ_PYTHON=1 opt-in into the default, as a reversible, fleet-aware upgrade that any repo
  shipping the harness (root clone or vendored .xyz/ copy) can run end-to-end without a follow-on
  stream of one-more-thing fixes. The reversibility guarantee — one runtime env var, one git revert —
  is the load-bearing requirement, not the flip itself.
roadmap_exempt: false
---

# UPGRADE — XYZ_PYTHON default flip (Bash → Python)

This is a **runbook**, not a feature spec. It is written to be executed top-to-bottom, once, by an
operator or an agent, on this repo first and then on any repo that vendors the harness. Every phase
has an explicit **entry gate**, **exact commands**, a **proof step**, and a **rollback**. If any
phase's proof fails, stop and roll back that phase — do not carry a red phase forward.

The design bias throughout is **reversibility over speed**. The switch is worth nothing if we cannot
get back to Bash in one move when it misbehaves.

---

## 0. What this changes, in one paragraph

Eleven Bash entry points each carry an identical 6-line header shim that `exec`s a Python twin when
`XYZ_PYTHON=1`, and otherwise falls through to the canonical Bash body **inlined in the same file**.
Today the shim reads `${XYZ_PYTHON:-0}` — default Bash. This upgrade changes that default to Python.
Because the Bash body is never renamed or deleted, "revert" is either an env var (`XYZ_PYTHON=0`, per
run) or a one-commit `git revert` (permanent). Nothing about the port's *code* changes here; only the
**default** changes, plus two hardening fixes that make the default safe to flip.

The 11 entry points:

```
relay-automation/agy-turn.sh      relay-automation/poll.sh
relay-automation/aider-turn.sh    relay-automation/relay-drive.sh
relay-automation/claude-turn.sh   relay-automation/relay-loop.sh
relay-automation/codex-turn.sh    utils/marathon-plan.sh
relay-automation/consult.sh       utils/swarm-preflight.sh
relay-automation/marathon-drive.sh
```

**Out of scope — stays Bash after this upgrade, by design:**
- `relay-automation/relay-turn-lib.sh` (permanent Bash boundary — `decisions/2026-07-04-python-port-boundary.md`; Python reaches it via `rtl.py`).
- `marathon.sh`, `runner.sh`, `watchdog.sh`, `xyz-sync.sh`, `xyz-vendor.sh`, `signal-triage.sh`, `roadmap-dashboard.sh`, and ~20 other Bash-only scripts that were never ported. A cutover is **permanently partial**; this doc does not pretend otherwise.

---

## 1. Reversibility model (read before executing anything)

There are three independent revert levers, fastest first. Know all three before you flip.

| Lever | Scope | Speed | How |
|---|---|---|---|
| **Runtime env** | one invocation / one shell | instant, no code change | `XYZ_PYTHON=0 <command>` (or `export XYZ_PYTHON=0` for a session) |
| **Git revert** | the whole repo, permanent | one commit | `git revert <flip-sha>` — the flip is a single isolated commit (Phase 3) |
| **Re-vendor** | one consumer `.xyz/` copy | one command | `relay-automation/xyz-sync.sh update <dir>` after the root is reverted |

**Fail-safe direction.** After the hardening in Phase 2, the shim condition is `== "1"`, so *every*
value that is not exactly `1` — `0`, `false`, a typo, empty, garbage — runs **Bash**. The system fails
back to the old, trusted path, never forward into Python. This is deliberate and must be preserved.

**The one non-obvious trap (fixed in Phase 2).** The current shim uses `${XYZ_PYTHON:-0}` — colon-dash
— which substitutes the default for *both unset and empty-string*. Today that is harmless (default is
`0`). After the flip the default is `1`, and colon-dash means anyone who "turns it off by clearing
the variable" (`export XYZ_PYTHON=`, `env XYZ_PYTHON= …`, a CI wrapper that sets it to `""`) silently
gets **Python** — the opposite of intent. Phase 2 changes `:-` to `-` (no colon) at all 11 sites so
that **only unset** takes the default; an explicit empty string then reads as "not 1" → Bash.

Truth table after Phase 2 hardening (`${XYZ_PYTHON-1}`, flipped default):

| `XYZ_PYTHON` | Runs |
|---|---|
| unset | Python (new default) |
| `1` | Python |
| `0` | Bash |
| `` (empty) | Bash ✅ (was the trap) |
| `false` / anything else | Bash |

**What is NOT safely reversible mid-flight.** The two implementations do not emit byte-identical
artifacts (e.g. GH-207: Python does not yet write the namespaced relay/attempt paths Bash writes). So
you revert *between* runs, never during one. A marathon or relay interrupted in one mode and resumed
in the other is unsupported. Rollback granularity is "the next invocation," which is fine because
every entry point is a short-lived process.

---

## 2. Preconditions (hard gates — do not start if any fail)

Run every check. All must pass on the target repo before Phase 1.

```bash
# (a) python3 present AND >= 3.8 — the shims exec `python3` with no fallback and no presence guard.
#     `--version` alone is NOT a gate: it exits 0 on 3.7 too. Enforce the floor with a predicate.
python3 --version                                             # readable output
python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)' \
  || { echo "python3 >= 3.8 required — do not flip"; }        # hard gate; must exit 0

# (a2) node present — NOT optional. utils/py/marathon_plan.py runs `node --version` and hard-exits
#      ("node is required ... but not found in PATH", marathon_plan.py:105-107) before delegating the
#      real work to utils/py/_marathon_plan_node.js. So the marathon-plan entry point is Python+Node,
#      not pure Python: a box with python3 but no node passes (a) and still bricks marathon-plan.
node --version               # must succeed, or exclude marathon-plan from the flip (keep its default 0)

# (b) clean, CURRENT branch — a clean status is NOT proof the branch is up to date.
#     Use bare `git fetch origin` (NOT `git fetch origin <branch>`): the bare form refreshes ALL
#     remote-tracking refs via the configured refspec, so the origin/<branch> the compare reads is
#     guaranteed fresh. An explicit-branch fetch can, depending on refspec config, update only
#     FETCH_HEAD and leave origin/<branch> stale — silently defeating this very check.
git fetch -q origin
git rev-list --left-right --count "origin/$(git branch --show-current)...HEAD"   # want: 0<TAB>0 (or ahead-only if you know why)
git status --porcelain       # want: empty

# (c) the port's own baseline is green in BOTH modes before you touch defaults.
#     Bash baseline first, then Python — same commit, soft-fail so you see every gap at once.
TEST_SOFT_FAIL=1 RELAY_SELF_SUFFICIENCY_SKIP=1 bash validate.sh            ; echo "bash exit=$?"
TEST_SOFT_FAIL=1 RELAY_SELF_SUFFICIENCY_SKIP=1 XYZ_PYTHON=1 bash validate.sh; echo "py   exit=$?"
```

**Gate:** the diff between those two runs must contain **zero Python-attributable failures** — a test
that fails under `XYZ_PYTHON=1` but passes in the same-commit Bash baseline. Pre-existing failures
that fail in *both* modes (e.g. a stale `relay-pkg.tar.gz`, an environment-specific test) do not block
the flip — they are not caused by it — but they must be *known and named*, not discovered later.

> Use `utils/py`-mode attribution, not a raw count: subtract the Bash baseline. See GH-255 for the
> method and the reference attribution script. If you cannot produce a clean same-commit baseline,
> **you are not ready to flip** — that is the whole lesson of the GH-172 → GH-215 → GH-223 → #235
> "one gap unmasks the next" sequence.

`python3` version floor: the twins use f-strings and `subprocess.run(..., timeout=)`; 3.8+ is safe.
If a target box is older, stop — the flip would brick every entry point with no fallback.

**Interpreter matrix** (which *additional language runtime* each entry point needs — beyond the POSIX
baseline). NB: "python3 only" below means no second *language* runtime; every twin still shells out to
ordinary system tools — `git`, `/bin/bash`, `date`, `sed` (e.g. `marathon_drive.py:139,424,444`,
`relay_drive.py:106` + the Bash `consult.sh` it calls, `aider-turn.py:80`). Those (coreutils + git +
bash) are assumed present on any box that already ran the Bash harness, so they are not a new gate —
but the twins are **not** pure-Python, and a truly minimal container must carry them.

| Entry point | Extra language runtime |
|---|---|
| the 10 relay/turn/consult/preflight twins | none beyond `python3` (POSIX tools + git + bash still required) |
| `utils/marathon-plan.sh` | `python3` **and** `node` (the twin shells out to `_marathon_plan_node.js`) |

If a target has `python3` but no `node`, you may still flip the other 10 and leave
`utils/marathon-plan.sh` on its Bash default (`${XYZ_PYTHON-0}` at that one site) — the flip is
per-file, so a partial flip is legitimate. Say so in the flip commit if you do it.

---

## 3. Phase 1 — Close all Python-attributable parity gaps (the real work)

**Entry gate:** Preconditions §2 pass except possibly (c)'s zero-gap requirement.
**Goal:** make §2(c) hold — no test fails only under Python.

This is the bulk of the effort and it is **not** mechanical. As of 2026-07-20 the open gaps on this
repo (from GH-255, at HEAD where `agy-turn.py` fail-open is already fixed) are:

| Test | Assertions | Nature |
|---|---:|---|
| `swarm-preflight.sh` | 8 | port: stale-lock warning, contract-heading detection, effective artifacts/helpers |
| `consult.sh` | 7 | port: the #235 provenance surface (`FIRSTHAND_COUNT`/`ECHOED_COUNT`, `PROMPT.txt` snapshot) |
| `marathon-drive.sh` | 23 | **reconcile, not port** — Bash and Python fail in *disjoint* sets (see below) |
| `debug-mantra.sh` | 6 | port (fails via the driver it calls) |
| `marathon.sh` | 5 | port (fails via the driver it calls) |
| `marathon-plan.sh` | 5 | port: review-lanes/overlay-doc handling |
| `relay-artifact-file.sh` | 3 | port |
| `relay-turn-trace.sh` | 2 | port: persistent transcript path |
| `aider-turn.sh` | 1 | port: legacy `--add-gitignore-files` flag |
| `relay-review-once.sh` | 1 | port |

**Ordering (safety first, entanglement last):**
1. Any **fail-open / containment** gap first — a Python path that accepts what Bash rejects is a
   safety regression, not a parity nit. (The `agy-turn.py` GH-178 B1 grounding scan was exactly this
   and is already fixed; treat any future one the same way.)
2. Self-contained ports next: `swarm-preflight`, `consult` (#235), `aider-turn`, `relay-*`, `marathon-plan`.
3. **`marathon-drive` last, and split into its own tracked issue.** It is not a port: Bash fails
   GH-171/GH-172 (vendored chain) while Python fails GH-207/GH-238/worktree `--require-clean`. Neither
   side is a superset of the other, so fixing the Python twin alone will not make the file green in
   either mode. Someone must reconcile the *union*. That is a `marathon-drive` correctness project the
   cutover happens to surface, not cutover work — do not let it ride inside this runbook's critical path.

**Per-gap discipline:** each fix is one commit, refs its own issue, and must leave the same-commit
Bash baseline unchanged (verify by re-running §2(c)). Porting one gap frequently *unmasks* the next
(the `TEST_SOFT_FAIL=1` soft-fail harness from GH-255 exists precisely so you see the whole set in one
run instead of dribbling them out) — re-run the full soft-fail sweep after every fix, not just the
one test.

**Proof:** §2(c) diff is empty of Python-attributable failures.
**Rollback:** each gap fix is independently `git revert`-able; none touches defaults, so none can
break Bash mode.

---

## 4. Phase 2 — Harden the toggle (do this even if you never flip)

**Entry gate:** none — these two changes are safe under the *current* Bash default and should land
regardless of flip timing.

**(2a) Kill the empty-string trap.** At all 11 sites, change the shim condition from colon-dash to
dash:

```bash
# before
if [[ "${XYZ_PYTHON:-0}" == "1" ]]; then
# after  (only UNSET takes the default; explicit "" reads as not-1 → Bash)
if [[ "${XYZ_PYTHON-0}" == "1" ]]; then
```

Note: while the default is still `0` this is a no-op for every value *except* empty-string, so it is
provably safe to land now. It is a prerequisite for the flip, not part of it.

**(2b) Add a `python3`-presence guard** so a missing interpreter fails loudly to Bash instead of
`exec`-ing into a "command not found". Insert inside the shim, before the `exec`:

```bash
if [[ "${XYZ_PYTHON-0}" == "1" ]]; then
  if ! command -v python3 >/dev/null 2>&1; then
    echo "xyz: XYZ_PYTHON=1 but python3 not found — falling back to Bash" >&2
  else
    _xyz_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    export XYZ_ROOT="$_xyz_root"
    export PYTHONPATH="$_xyz_root/utils/py${PYTHONPATH:+:$PYTHONPATH}"
    exec python3 "$_xyz_root/utils/py/<twin>.py" "$@"
  fi
fi
```

This makes the fail-safe direction hold even on a box with no Python — the single scariest flip
failure mode (every entry point bricked) becomes a graceful degrade with a warning.

**Consistency note:** the 11 shims share one identical *condition line*, but they are **not** wholly
byte-identical — `utils/marathon-plan.sh` carries an extra `--zones-config → QUEUE_PLAN_ZONES_FILE`
translation block (GH-154, `marathon-plan.sh:11-20`) that the other 10 lack. So the invariant is
scoped to the **condition line only**, which the filter below isolates (the zones-config lines don't
match `grep '\[\['`):

```bash
# every shim's CONDITION line should be identical (body may differ — marathon-plan.sh has extra flag xlat)
grep -h 'XYZ_PYTHON' relay-automation/*.sh utils/marathon-plan.sh utils/swarm-preflight.sh \
  | grep '\[\[' | sort -u    # want: exactly ONE distinct line
```

**Proof:** the one-distinct-line check above; plus `TEST_SOFT_FAIL=1 XYZ_PYTHON= bash validate.sh`
(empty string) now runs **Bash** and is green; plus a spot-check that `XYZ_PYTHON=1` on a box with
`python3` still routes to Python.
**Rollback:** `git revert` — these are ordinary code commits, default unchanged, so Bash mode is
untouched either way.

---

## 5. Phase 3 — The flip (one isolated commit)

**Entry gate:** §2(c) clean (Phase 1 done) AND Phase 2 hardening landed.

Change the default at all 11 sites, and **nothing else in the same commit**:

```bash
# after Phase 2 the line is:  ${XYZ_PYTHON-0}
# the flip makes it:          ${XYZ_PYTHON-1}
```

The commit must touch only those 11 default characters. A surgical, single-purpose flip commit is what
makes `git revert <flip-sha>` a guaranteed-safe rollback with zero collateral. Do not fold anything
else in.

**Proof:**
```bash
# default now routes to Python with the var UNSET:
unset XYZ_PYTHON; TEST_SOFT_FAIL=1 RELAY_SELF_SUFFICIENCY_SKIP=1 bash validate.sh; echo "default exit=$?"
# explicit opt-OUT still works:
XYZ_PYTHON=0     TEST_SOFT_FAIL=1 RELAY_SELF_SUFFICIENCY_SKIP=1 bash validate.sh; echo "opt-out exit=$?"
```
Both must match their pre-flip counterparts (default-unset == old Python run; `XYZ_PYTHON=0` == old
Bash run).

**Rollback:** `git revert <flip-sha>` (permanent), or `export XYZ_PYTHON=0` (this shell / CI job,
instant). Document BOTH in the commit message body so the rollback is discoverable from `git log`.

---

## 6. Phase 4 — Documentation & discoverability (so rollback isn't tribal knowledge)

**Entry gate:** Phase 3 landed.

Right now `XYZ_PYTHON` appears in **no** canonical doc — only in shim comments and relay transcripts.
An un-discoverable rollback lever is a broken rollback lever. Land these in the same PR as the flip:

- **README** (or the repo's front-door doc): a short "Runtime: Python default, opt out with
  `XYZ_PYTHON=0`" note, plus the `git revert` line for a permanent rollback.
- **AGENTS.md**: one line so agents know the default is Python and how to force Bash for a single run.
- **CHANGELOG**: the flip entry, naming the flip SHA and both rollback levers verbatim.
- This `UPGRADE.md`: mark the flip done, record the date and SHA.

**Proof:** `grep -rl 'XYZ_PYTHON=0' README* AGENTS.md CHANGELOG.md` returns all four surfaces.
**Rollback:** docs-only; revert with the flip if the flip is reverted.

---

## 7. Phase 5 — Fleet propagation (the genuinely non-atomic part)

**Entry gate:** Phases 1–4 held on the root repo through a **soak period** (see §8). Do NOT start this
until you are confident you will not need to roll the root back — because rolling back the fleet is a
per-copy operation, not a git revert.

The harness is vendored into N `.xyz/` copies across other repos. Each copy carries its **own** shim
files, so flipping the root does not flip them and reverting the root does not revert them. Treat the
fleet as a separate, staged rollout.

```bash
# 1. Inventory every vendored copy the registry knows about:
relay-automation/xyz-sync.sh list

# 2. Drift check before touching anything (report-only, never mutates):
relay-automation/xyz-sync.sh check --all

# 3. Upgrade ONE low-stakes consumer first, prove it, then widen:
relay-automation/xyz-sync.sh update <dir>      # re-vendors that copy from the current (flipped) root
#    → run that repo's own validate.sh (or its smoke path) with the var UNSET to confirm Python-default
#    → run it with XYZ_PYTHON=0 to confirm the opt-out lever survives the vendor

# 4. Only after the pilot copy holds, widen:
relay-automation/xyz-sync.sh update --all
```

**Per-copy rollback** (the fleet has no single revert):
- Runtime, any single consumer, instant: `XYZ_PYTHON=0` in that repo's environment.
- Permanent, one consumer: re-vendor it from a root that is on the pre-flip commit
  (`git -C <root> revert <flip-sha>` then `xyz-sync.sh update <dir>`), OR pin that copy and skip it.

**Proof:** `xyz-sync.sh check --all` shows every copy at the expected `source_commit`; each upgraded
consumer's own test/smoke path is green with the var unset.

**Honest cost statement:** this phase is why the upgrade's reversibility is "good but not one-click."
Root repo rollback is a git revert. **Fleet rollback is O(N) copies.** Keep the soak long and the pilot
small so you never have to exercise fleet rollback under pressure.

---

## 8. Soak & abort criteria

- **Soak the root repo** (Phases 1–4) for at least one real marathon/relay cycle plus a few days of
  normal use before Phase 5. The two implementations diverge on artifacts (GH-207); real runs surface
  what tests do not.
- **Abort signal:** any Python-default run that produces a *worse* outcome than the same run under
  `XYZ_PYTHON=0` — a lost artifact, a wrong exit code that changes a driver's decision, a containment
  breach accepted. On any such signal: `export XYZ_PYTHON=0` immediately (stops the bleeding for every
  consumer in that environment), then decide between a full `git revert` and a targeted parity fix.
- **Do not** flip the fleet to "prove" the root flip. The root soak is the proof.

---

## 9. Portability — running this on a repo that is NOT this one

This runbook is repo-agnostic, but **there are two kinds of target and they do NOT run the same
phases.** Decide which one you are on before doing anything — conflating them is the single easiest way
to get stuck.

**Type A — a full harness clone** (this repo, cloned elsewhere): ships `validate.sh`, `test/`, `PROJECT/`,
the whole suite. It **owns** parity — it runs Phases 1–8 as written.

**Type B — a vendored `.xyz/` leaf** (a consumer repo that ran `xyz-vendor.sh`): ships
`relay-automation/`, `utils/py/`, `test/_setup.sh`, and the shims, but **no `validate.sh` aggregator and
no `PROJECT/`** (confirmed on real copies). A leaf **does not derive or close parity gaps** — Phase 1
and Phase 3's whole "close the gaps" effort are **not run on a leaf**. It inherits an
already-parity-clean harness from the root it was vendored from. Trying to run the §2(c) two-mode sweep
on a leaf fails because there is no `validate.sh` to run — that is expected, not a blocker: it is the
signal that you are on a Type-B target and Phase 1 is upstream's job, already done.

When executing elsewhere:

1. **Locate the harness root** the device-agnostic way — do not hardcode a path. The locator is **not**
   at the repo root; it ships under the relay-xyz skill. Use the path that exists for your type:
   ```bash
   # Type A (full clone):   skills/relay-xyz/find-harness.sh
   # Type B (vendored leaf): .xyz/skills/relay-xyz/find-harness.sh   (at the consumer repo root)
   L="skills/relay-xyz/find-harness.sh"; [ -x "$L" ] || L=".xyz/skills/relay-xyz/find-harness.sh"
   "$L" --check     # prints the resolved harness root + which type; every command in this doc is relative to it
   ```
   **Caveat (GH-234, still open):** do **not** drive a vendored (Type-B) flow through `"$L" --env` yet —
   its `TICK_REPO_ROOT` export is known to resolve one directory too deep for a `.xyz/` install. Use
   `--check` to locate + confirm, and `cd` to the printed root manually, until GH-234 lands.
2. **Type A only — re-run §2 preconditions incl. the two-mode baseline.** `python3`/`node` presence, a
   clean/current branch, and a same-commit sweep are repo-local facts, not inherited from here. §3's
   gap *numbers* are this repo's snapshot; regenerate them on a Type-A target — the *method* ports, the
   *findings* do not.
3. **Type B (vendored leaf) — skip Phases 1 & 3 entirely.** Do NOT try to run `validate.sh`; it isn't
   there. The leaf's parity is whatever its source root shipped, so the correct sequence for a leaf is:
   (a) confirm `python3` (+ `node` if it uses marathon-plan) on the box; (b) `xyz-sync.sh check <dir>`
   from the **owning** repo to confirm the leaf is at the expected, already-flipped `source_commit`;
   (c) prove via the **consuming repo's own** smoke/test path plus a real relay/marathon run with the
   var unset, and again with `XYZ_PYTHON=0`. That is the leaf's Phase-1-equivalent — inherit-and-verify,
   not derive.
4. **The flip itself reaches a leaf only by re-vendor, never by editing `.xyz/`.** You do not hand-edit
   a vendored copy's shims (`xyz-sync.sh` would report it as drift and a future `update` would clobber
   it). A leaf becomes Python-default by `xyz-sync.sh update <dir>` from a root that is already flipped
   (Phase 5), full stop.
5. **Phase 5 is only driven from the repo that owns the registry** (the one whose `xyz-sync.sh list`
   knows the fleet). A leaf consumer receives its flip via re-vendor and opts out at runtime with its
   own `XYZ_PYTHON=0`; it never drives the fleet.

---

## 10. End-to-end checklist (copy into the tracking issue)

```
[ ] §9  determined target TYPE first (A = full clone runs Phases 1-8 · B = vendored leaf skips 1 & 3)
[ ] §2  python3 >= 3.8 on target
[ ] §2  node present (or marathon-plan excluded from the flip)
[ ] §2  branch clean AND current (fetched, 0 behind)
[ ] §2  two-mode same-commit baseline captured; Python-attributable gaps enumerated   (Type A only)
[ ] §3  all Python-attributable gaps closed (marathon-drive split to its own issue)
[ ] §3  re-run soft-fail sweep after EACH fix (unmasking)
[ ] §4  (2a) :- → - at all 11 sites; one-distinct-line invariant holds
[ ] §4  (2b) python3-presence guard added at all 11 sites
[ ] §4  empty-string run (XYZ_PYTHON=) proven to route to Bash and pass
[ ] §5  flip commit: only the 11 default chars, nothing else
[ ] §5  proof: unset==old-python-run, XYZ_PYTHON=0==old-bash-run
[ ] §6  README + AGENTS.md + CHANGELOG + this doc carry the rollback levers
[ ] §8  root soak: ≥1 marathon/relay cycle + a few days, abort criteria understood
[ ] §7  fleet: list → check --all → pilot ONE → prove → update --all
[ ] §7  every upgraded copy proven with var unset AND XYZ_PYTHON=0
```

---

## Appendix A — Rollback quick reference (pin this)

| Situation | Action |
|---|---|
| One command misbehaves under Python | prefix it: `XYZ_PYTHON=0 <command>` |
| A whole session / CI job | `export XYZ_PYTHON=0` at the top |
| Root repo, permanent | `git revert <flip-sha>` (the isolated Phase-3 commit) |
| One vendored consumer, now | `XYZ_PYTHON=0` in that repo's env |
| One vendored consumer, permanent | re-vendor from a reverted root, or pin/skip it |
| Whole fleet | there is no single lever — `XYZ_PYTHON=0` env-wide stops the bleeding; permanent is O(N) re-vendors |

## Appendix B — Why the Bash body must never be deleted

The entire reversibility guarantee rests on the Bash implementation staying **inline and callable** in
each entry point. The rejected PR #121 shape (renaming bodies to `*-legacy.sh`) would have made
rollback a rename-restore instead of an env var, and left copies with no escape hatch. Do not, in any
future cleanup, "tidy up" by extracting or deleting the Bash bodies until the Python default has held
across the whole fleet for a long, boring time — and even then, keep one tagged commit that still has
them.
