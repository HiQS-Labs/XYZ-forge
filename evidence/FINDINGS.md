# FINDINGS — XYZ-forge Linux bring-up

Each entry is written so it can be pasted into a GitHub issue as-is. `evidence/findings-log.md` is
the raw chronological record with fuller reasoning; this is the cleaned index.

**Environment.** Ubuntu 24.04.1 LTS under WSL2 (kernel 5.15.146.1-microsoft-standard-WSL2), 4 cores,
19 GB RAM, Node 22.23.2 (nvm), Python 3.12.3, git 2.43.0, bash 5.2.21, agy 1.1.16, codex-cli 0.148.0.
Branch `linux-bringup` from `development` @ `cd0f5bd`. Captured 2026-08-20.

**Tags.** `LINUX` a real defect any Linux user hits · `WSL` an artefact of this environment only, not
a repo bug · `DOC` docs wrong, missing, or macOS-assuming · `UNKNOWN` needs a native Linux box to
disambiguate.

**Reproduce any of these:** `bash repro.sh <probe>` (un-sandboxed, from the repo root).
`bash repro.sh --list` for names. Every probe prints expected, actual, and PASS/FAIL, where PASS means
"the finding still reproduces".

---

## Summary

| # | Tag | Sev | Finding | Repro probe |
|---|---|---|---|---|
| F-001 | LINUX | low | relay-xyz guard blocks reads inside a compound command | `probe-guard-read` |
| F-002 | DOC | info | "compute" is not a marathon verb anywhere in the repo — **closed 2026-08-24**, see [Round 2](#round-2--2026-08-24) | `probe-compute-verb` |
| F-003 | DOC | low | `marathon-plan.sh --help` advertises its inner Python path | `probe-plan-help-path` |
| F-004 | DOC | info | exit 8 is "lane parked", not "relay block invalid" | `probe-exit8-meaning` |
| F-005 | WSL+DOC | med | no builder on PATH; `claude` resolves to the Windows binary | `probe-builders` |
| F-006 | WSL | high | nvm's node is invisible to non-interactive login shells | `probe-node-path` |
| F-007 | WSL | high | `relay-xyz` skill unreachable from a Windows-host / WSL-repo session | — |
| F-008 | LINUX | high | a builder installed via nvm's `npm -g` is invisible to the harness | `probe-builders` |
| F-009 | LINUX | low | `issue-doc-sync` reports "gh absent/offline" when gh works | — |
| F-010 | DOC | med | the releases suite needs `sqlite3`, undocumented — **resolved** | — |
| F-011 | DOC | med | `standup/collect.sh` hard-requires `jq`, undocumented — **resolved** | — |
| F-012 | LINUX | med | the suite requires a GLOBAL git identity and nothing says so | — |
| F-013 | LINUX | med | `gh35-test-tiers` asserts `nice` 20, unreachable on Linux — **downgraded to latent 2026-08-24**, see [Round 2](#round-2--2026-08-24) | — |
| F-014 | — | — | methodology: baseline contaminated by a mid-run install | — |
| **F-015** | **LINUX** | **critical** | **agy 1.1.16 removed `whoami`; the auth preflight hard-blocks the lane — FIXED** | `probe-agy-auth` |
| F-016 | LINUX | low | `swarm-preflight` decides lane readiness with a bare `command -v` | `probe-lane-cli-probe` |
| F-017 | LINUX | med | `--plan` is checked against CWD, not `--target-root`, contradicting its help | `probe-plan-resolution` |
| **F-018** | **DOC** | **high** | **`--target-root` is recommended for exactly the case `relay-drive` refuses** | `probe-target-root-contradiction` |
| F-019 | DOC | med | `artifacts_new` is mandatory for greenfield lanes and undocumented | `probe-artifacts-new-doc` |
| F-020 | WSL | high | the agent Bash tool is sandboxed; GH-177 guard blocks every suite run | — |
| F-021 | WSL | med | a background notification reported exit 0 for a run that exited 2 | — |
| F-022 | LINUX | med | the compute/ranking step cannot run in a vendored repo | — |
| **F-023** | **LINUX** | **med** | **GH-68 drift watcher fires on every path absent at both revs** | `probe-drift-false-positive` |
| F-024 | LINUX | med | the gate mutates 4 tracked files on every run; benchmark rows accumulate | — |
| F-025 | LINUX | med | upstream `development` is RED on this host (9 suites) while hosted CI is green | — |
| F-026 | WSL | low | background-task notification reported exit 0 for a push that exited 1 (F-021 recurrence) | — |
| F-027 | LINUX | low | F-001 unchanged — guard still blocks read-only compound commands | `probe-guard-read` |
| **F-028** | **LINUX** | **high** | **`claude-turn.sh`'s PATH filter strips `node` too — suite cannot pass on an nvm install** | — |
| F-029 | LINUX | med | `gh103` uses BSD `md5`; the read-only safety assertion passes vacuously | — |
| F-030 | LINUX | low-med | `gh382` asserts a `darwin`-only feature on every platform | — |
| **F-031** | **LINUX** | **high** | **the fixture remote's HEAD names a branch never created — clones land with no commits** | — |
| F-032 | DOC | med | `--tool-mode programmatic` requires bubblewrap; listed in no prerequisites table | — |

Three are worth an issue each on their own: **F-015**, **F-018**, **F-023**.

**Round 2 (2026-08-24)** adds F-024 … F-027 and re-verifies PR #29's Windows findings — see
[Round 2](#round-2--2026-08-24) and `evidence/PR29-MSYS2-FOLLOWUP.md`. F-002 is **closed**; F-013 is
**downgraded to latent** and routed to GH-35 Phase 3.

---

## F-015 — `agy whoami` no longer exists; the auth preflight hard-blocks the whole agy lane

**Tag:** LINUX · **Severity:** critical — `--builder agy` is unusable on an unpatched tree · **Fixed** in `a4706d1`

### Command

```bash
python3 -c "import sys; sys.path.insert(0,'utils/py'); \
  import importlib.util; s=importlib.util.spec_from_file_location('t','utils/py/agy-turn.py'); \
  m=importlib.util.module_from_spec(s); s.loader.exec_module(m); \
  print(m.agy_auth_preflight('$HOME/.local/bin/agy'))"
```

### Expected per the docs

`relay-automation/README.md:249` and `agy-turn.sh:94` treat `agy whoami` as the auth pre-flight, with
`agy login` as the remedy on failure. `utils/py/rtl.py:119-124` states the intended behaviour: a
timeout carrying positive evidence of a TTY failure reclassifies to `unverifiable` and the lane
proceeds.

### Actual

`agy_auth_preflight` returns **`False`** — lane blocked, shim exits **5** — at every timeout tried:

| `AGY_AUTH_TIMEOUT_S` | result |
|---|---|
| 5 | `False` — BLOCKED |
| 15 | `False` — BLOCKED |
| 30 | `False` — BLOCKED |

Raising the timeout cannot help, because the probe never completes.

**Root cause, in three measured parts.**

1. `whoami` is not a subcommand of agy 1.1.16. `agy --help` lists
   `agent agents changelog help install mcp models plugin plugins update`. Neither `whoami` nor
   `login` — the remedy every failure path prints — exists.
2. The argument therefore falls through to agy's **interactive TUI**, which writes a terminal-takeover
   escape sequence and blocks. It also **ignores SIGTERM**: `timeout 30 agy whoami` was observed in
   the process table still alive at **6m43s**; `timeout 8 agy whoami` at **2m26s**. Only SIGKILL ends
   it. (`rtl_run_bounded` uses `kill -9`, so the harness does not hang — but any naive `timeout`
   caller does.)
3. The capture at timeout is therefore escape codes and **no prose**:
   `\e[?2026$p\e[?1049h\e[?25l\e[?2004h\e[H\e[2J`. `AGY_AUTH_TTY_MARKERS` matched prose only
   (`"could not open tty"`, `"error opening tty"`), so the classifier read this as "timed out with no
   TTY diagnostic" → `failed`.

Meanwhile the lane demonstrably works: `agy -p "Reply with exactly: MARATHON-PROBE-OK"` → rc **0** in
14s, correct answer; `agy models` → rc **0** in 7.6–8.5s, real model list from the backend.

This is the third arrival of the false-block direction GH-375 and its follow-up were both written to
prevent — through a new spelling rather than a new branch.

### Fix applied

Branch `fix/agy-tui-takeover-auth-verdict`, commit `a4706d1`. Treat a **mute** terminal takeover as
positive evidence of the TTY cause. The follow-up's rule is preserved verbatim — reclassify only on
positive evidence — because a terminal takeover *is* that evidence, in control codes rather than
English. The second half of the predicate keeps the fatal cases fatal: nothing readable may survive
escape-stripping, so a device-code login prompt still blocks and silence still blocks. Also adds
`"error entering raw mode"` to `AGY_AUTH_TTY_MARKERS` (1.1.16's wording).

| Verification | Result |
|---|---|
| `test/agy-tui-takeover-verdict.sh` (new, includes a pre-fix replay) | 8 pass / 0 fail |
| `test/gh375-auth-timeout-verdict.sh` | 14 pass / 0 fail — no regression |
| `test/gh375-agy-auth-preflight.sh` | pass — no regression |
| live `agy_auth_preflight()` at 5s / 15s / 30s | `False` → **`True`** |
| live marathon (run 1, 4 phases, builder agy) | exit 0, all phases Approved |

### Not fixed, deliberately

The preflight still burns its full timeout (default 20s) on every agy turn, because `agy whoami` can
never complete. That is a cost question, not a correctness one. Choosing a replacement probe is a
maintainer's call — `agy models` is a real candidate at rc=0 in ~8s — and GH-492 criterion 4 explicitly
prefers recording the finding over shipping a weaker probe.

**Repro:** `bash repro.sh probe-agy-auth`

---

## F-018 — `--target-root` is recommended for exactly the case `relay-drive` refuses

**Tag:** DOC · **Severity:** high — the documented remedy for a gitignoring target cannot run a build turn

### Command

```bash
relay-automation/marathon.sh --plan "$TARGET/PROJECT/2-WORKING/RUN1/MARATHON.yaml" \
  --target-root "$TARGET" --builder agy --pre-advance-cmd "npm test"
```

### Expected per the docs

`relay-automation/marathon.sh` `--target-root` help, verbatim:

> Use this when the target repo cannot track harness output (e.g. a public repo that gitignores
> `marathon-system/` and `relay-system/` on purpose): without it, marathon-drive's `git add` of
> RELAY.md / ESCALATION.md / the transcript fails and the phase HALTs.

That described the target repo exactly — its `.gitignore` carried both paths.

### Actual

Exit **2**, halted on phase 1, in 2s, with no builder turn spent:

```
relay-drive: --target-root build turn cannot report: relay file
  '<harness>/marathon-system/run1-ledger-exports--r1p1/RELAY.md' resolves outside the target root
  '<target>', so a build turn (ALLOW_PATHS="") has no writable path for its findings and the turn
  would be discarded after full cost. Vendor the harness into the target repo
  (relay-automation/xyz-vendor.sh '<target>') and drop --target-root, or move the relay thread
  under the target root.
marathon: HALT: phase r1p1 failed (marathon-drive exit 2) — chain stops; later phases NOT started
```

Both statements are individually correct and mutually exclusive. `--target-root` keeps the relay
thread in the harness repo **by design** — its own help says so in the next sentence — and that is
precisely what leaves a build turn with nowhere to report.

The refusal is pinned by `test/gh289-target-root-build-turn.sh`, so it is intended behaviour, not a
regression. The defect is the help text.

### Credit where due

This is the best failure in the bring-up. It fired **before** any builder turn was spent, stated the
cause in one sentence, and named two concrete remedies, the first of which worked immediately. The
halt behaved exactly as `marathon.sh:4-8` documents.

### Second-order cost the help does not mention

Taking the named remedy means the target repo must now **track** `marathon-system/` and
`relay-system/` — the exact thing `--target-root` was offered to avoid. For a genuinely public repo
that gitignores harness output on purpose, **neither branch of the advice is available**.

### Suggested resolution

Either narrow the `--target-root` help to review-only lanes (where `ALLOW_PATHS` is non-empty and the
turn can report), or state plainly that build turns require a vendored install and that the target
must track harness output.

**Repro:** `bash repro.sh probe-target-root-contradiction`

---

## F-023 — the GH-68 drift watcher fires on every path that exists at neither revision

**Tag:** LINUX · **Severity:** medium — warn-only, but it pollutes every agent turn brief and buries the real signal

### Command

```bash
git rev-parse "$(git rev-parse HEAD~1):src/project.js"   # a path in neither revision
```

### Expected per the code's own comment

`relay-automation/relay-turn-lib.sh:1353`:

```bash
[[ "$_psha" == "$_csha" ]] && continue   # unchanged (or absent at both revs) — no drift
```

### Actual

Exit **128**, and `rev-parse` **echoes its argument back on stdout** — the standard fallback for an
unresolvable argument. So the two sides are non-empty and differ by SHA prefix:

```
_psha=[3daa280311ae05710b24daf2d65af5b907c981b6:src/project.js]
_csha=[a7222a5de42d20a6aa177691c17e2912de6418ac:src/project.js]
=> DIFFERENT -> drift emitted
```

The `continue` guard never fires. A control path that *does* exist behaves correctly
(`src/parse.js` → identical SHAs → no drift), which is what isolates the cause.

The `(0 lines)` in the operator output is the tell — a genuine drift always has a non-zero diff:

```
agy-turn: dependency.drift — agy changed relay-automation/relay-turn-lib.sh (0 lines); signalled for the next turn
agy-turn: dependency.drift — agy changed src/project.js (0 lines); signalled for the next turn
agy-turn: dependency.drift — agy changed src/events.js (0 lines); signalled for the next turn
```

### Blast radius

The watch list is hardcoded to xyz's own filenames
(`relay-automation/relay-turn-lib.sh`, `src/project.js`, `src/events.js`). In a **vendored** install
the harness lives at `.xyz/relay-automation/...` and the other two are xyz's own files, so **all three
are absent by construction and all three fire on every commit**. Measured: **42 `dependency.drift`
events in a single four-phase run**, every one false.

This is not just log noise. GH-68's purpose is to inject the notice into the **next agent's turn
brief**, and it does — captured live from the process table:

```
agy --dangerously-skip-permissions --print-timeout 900s -p [cross-agent dependency drift —
informational, warn-only; re-...
```

So every builder and reviewer turn after the first opens with a heads-up about three files that do not
exist in the repository it is working on. In the deployment shape that actually works (per F-018), the
signal is 100% false positives — which makes a real drift event indistinguishable from its noise.

### Suggested fix

```diff
-  _psha="$(git -C "$RTL_ROOT" rev-parse "$RTL_BEFORE_HEAD:$_surf" 2>/dev/null || true)"
-  _csha="$(git -C "$RTL_ROOT" rev-parse "$_newhead:$_surf"        2>/dev/null || true)"
+  _psha="$(git -C "$RTL_ROOT" rev-parse --verify --quiet "$RTL_BEFORE_HEAD:$_surf" 2>/dev/null || true)"
+  _csha="$(git -C "$RTL_ROOT" rev-parse --verify --quiet "$_newhead:$_surf"        2>/dev/null || true)"
```

`--verify --quiet` suppresses the echo-back, so an absent path yields `""` at both revs and the
existing guard works as its comment already promises. One flag pair, no logic change. Verified not to
suppress genuine drift.

Separately: `utils/marathon-plan.sh` already solved the "don't match foreign repos against xyz's
filenames" problem with `--zones-config` / `QUEUE_PLAN_ZONES_FILE`. The drift watcher has the same
need and no such lever.

**Repro:** `bash repro.sh probe-drift-false-positive`

---

## F-017 — `--plan` is existence-checked against the process CWD, not `--target-root`

**Tag:** LINUX · **Severity:** medium

### Command

```bash
relay-automation/marathon.sh --plan PROJECT/2-WORKING/RUN1/MARATHON.yaml \
  --target-root "$TARGET" --builder agy --dry-run
```

### Expected per the docs

`relay-automation/marathon.sh:96`: *"Plan and brief paths resolve against DIR when set."*

### Actual

Exit **2** · `marathon: plan not found: PROJECT/2-WORKING/RUN1/MARATHON.yaml` — for a file that exists
at exactly that path inside `--target-root`.

Ordering bug, visible in the source:

```
relay-automation/marathon.sh:136   [[ -f "$PLAN" ]] || die "plan not found: $PLAN"
relay-automation/marathon.sh:155   _plan_base="${TARGET_ROOT:-$ROOT}"
```

The existence check runs **19 lines before** the base it is documented to resolve against is computed.
`brief_base` at `:271` is later still. The error message gives no hint that a different root was used.

**Workaround:** pass `--plan` as an absolute path. Verified — the same invocation then reached
`marathon: dry-run complete: 4 phase(s) would run in order`, exit **0**.

**Repro:** `bash repro.sh probe-plan-resolution`

---

## F-019 — `artifacts_new` is mandatory for greenfield lanes and appears in no operator-facing doc

**Tag:** DOC · **Severity:** medium

### Commands and exit codes — three attempts to get one valid contract

| Attempt | Exit | Message |
|---|---|---|
| new files listed in `artifacts[]` | **5** | `artifact path not found at target.ref: src/export-csv.js` |
| `artifacts_new` as a parallel list | **3** | `artifacts_new entry not present in artifacts[]: src/export-csv.js` |
| `artifacts_new` as a subset of `artifacts[]`, each with a `path_absent` probe | **0** | `verdict: ready` |

### Expected per the docs

The exit-3 message says:

> To fix, add a minimal valid contract in `<doc>` (copy `relay-automation/CONTRACT.example.md` for a
> detailed example)

### Actual

```bash
grep -q 'artifacts_new' relay-automation/CONTRACT.example.md
```
Exit **1** — the field appears nowhere in the file the error names. Nor in `README.md`, `ROUTER.md`,
`AGENTS.md`, or anywhere under `relay-automation/`. Outside PROJECT capture docs and the CHANGELOG,
the only prose mention repo-wide is `skills/marathon-triage/SKILL.md:93`, which references the field
without defining it.

The semantics are recoverable only from `utils/swarm-preflight.sh:181-190` and `:228-243`:
`artifacts_new` is a **subset marker over `artifacts[]`**, not a parallel list, and every entry needs a
matching `fix_probes` `path_absent` on the same path.

Greenfield work is the normal case for a marathon, so this sits on the main path.

**Suggested resolution:** add the three-line `artifacts_new` block to `CONTRACT.example.md`, and have
the exit-5 message mention `artifacts_new` when the missing path is absent at `target.ref`.

**Repro:** `bash repro.sh probe-artifacts-new-doc`

---

## F-022 — the compute/ranking step cannot run in a vendored repo

**Tag:** LINUX · **Severity:** medium

### Command

```bash
cd "$TARGET" && bash .xyz/utils/marathon-plan.sh --check
```

### Expected

The planner/ranker is the nearest thing the repo has to the lifecycle's first step (see F-002).
`README.md`'s "`marathon.sh` roots" documents the vendored invocation shape as normal usage.

### Actual

Exit **3** · `ROADMAP not found: <target>/ROADMAP.md`

It reads the harness's own PDDA `ROADMAP.md` ledger, which no consuming repo has. The same command in
the harness repo works: exit **4** (drift present),
`SUMMARY [marathon-plan] items=22 active=0 waves=0 drift=true held=11`.

So ranking is unavailable in exactly the deployment shape `xyz-vendor.sh` creates — and which F-018
forces you into. Not a blocker for a hand-written plan, but an operator following the lifecycle in
order hits exit 3 on step one with nothing saying "this step is harness-only".

---

## F-016 — `swarm-preflight` decides lane readiness with a bare `command -v`

**Tag:** LINUX · **Severity:** low

`utils/swarm-preflight.sh:780`:

```bash
GH39_LANE_NOTE="codex=$(command -v codex >/dev/null 2>&1 && echo present || echo absent) agy=$(command -v agy >/dev/null 2>&1 && echo present || echo absent)"
```

A bare `command -v` proves only that a file is on `PATH`. It printed
`lane-cli : codex=present agy=present` in the same minute that `agy-turn.py`'s own preflight returned
`False` at every timeout tried (F-015). `skills/relay-xyz/find-harness.sh` is the better-behaved
sibling — it honours `AGY_BIN` and the well-known install location (`:192-196`) — and the two
disagreed about the same machine within one run.

Advisory-only, but it is the line an operator scans to decide whether a lane is safe to fire.

**Repro:** `bash repro.sh probe-lane-cli-probe`

---

## F-020 / F-021 — environment truths worth stating

**F-020 (WSL, high friction).** The agent's Bash tool **is sandboxed**.
`relay-automation/hooks/gh177-sandbox-test-guard.sh` refuses every suite invocation until it is
disabled. This is the guard doing its job: it converts the failure mode "prints nothing for minutes
and then fails, and it looks exactly like a hang" into an instant, explanatory refusal naming the
remedy. Note the sandbox is imposed by the **agent harness**, not by WSL — `mktemp -d` works fine
inside WSL (exit 0). Every test and marathon in this bring-up ran with the sandbox explicitly
disabled, which is the second option the guard itself offers.

**F-021 (WSL, medium).** A background-task notification reported `completed (exit code 0)` for a
marathon that halted with `EXIT_CODE: 2`. The same class already appears in F-014, where
`./validate.sh --sequential | tail -80` reported `tail`'s status for a suite that exited 1. It fired
twice in one bring-up on two different mechanisms.

**The only defensible rule:** a run counts only if a `PIPESTATUS[0]`-derived `EXIT_CODE:` was written
to a log. Not the notification, not the terminal's last line. `evidence/_env/run.sh` enforces this.

---

## F-001 … F-014

Unchanged from the Phase 0–3 record. Full text with commands, exit codes and reasoning is in
`evidence/findings-log.md`. Two status updates:

- **F-010 / F-011 — resolved.** `sqlite3` 3.53.4 and `jq` 1.7.1 installed to `~/.local/bin` from
  official upstream binaries (sqlite.org, jqlang releases), no root required, and verified visible
  from a **non-interactive login shell** — the shape that matters per F-006. Deliberately not shimmed
  over Python's `sqlite3` module: a fake CLI would make the suite assert things that are not true.
- **F-009 — partially resolved.** `gh repo set-default HiQS-Suite/XYZ-forge` (exit 0) fixed the
  resolution target, but `gh issue view 544` still exits 1 — that issue does not exist upstream
  either. Warn-only; `errors=0`.

---

# Round 2 — 2026-08-24

Resync to `713ba6d1` (upstream org renamed `HiQS-Suite` → `HiQS-Labs`). Everything below was
re-verified against that commit, not carried over from round 1.

## F-002 — CLOSED: "compute" maps to `utils/marathon-plan.sh`

Round 1 reported that "compute" is not a literal verb anywhere in the repo. That is still true, and
`probe-compute-verb` still passes. But leaving it as a bare terminology complaint was the wrong
disposition — the step exists, it is just named differently in the operator-facing docs than in the
source.

`utils/marathon-plan.sh:170` calls its own ranking logic exactly that:

```
# One embedded Node program does the compute (parse ledger → resolve items → signals → score →
# wave-pack → render).
```

So the lifecycle's first stage — "compute" — **is** `utils/marathon-plan.sh`: it reads `ROADMAP.md`,
validates each item is still real, ranks by PDDA cx/risk/effort, and batches collision-safe waves.

**Closed with that mapping.** The residual, if anyone wants it, is a one-line docs change naming the
script where the lifecycle is described. Not worth an issue on its own.

## F-013 — DOWNGRADED: the `nice` assertion is latent, not currently failing

Round 1 recorded a hard failure: `caller nice=10, worker nice=19, wanted 20`. That specific failure
**no longer reproduces**, for two independent reasons, both already upstream:

1. `githooks/pre-push` no longer wraps the runner in `nice` (see its comments at lines 128-131 and
   176) — so the caller is no longer at nice 10 and the stacking that produced the failure is gone
   at source.
2. `test/gh35-test-tiers.sh:242-245` now asserts a **delta** (`worker == caller + 10`) rather than an
   absolute 20.

In today's full-gate run `gh35-test-tiers.sh` failed in parallel but **passed when re-run alone**, and
the failing assertion was not the `nice` pin.

**But the ceiling is still real and still unsatisfiable.** Re-probed on this host, `713ba6d1`:

```console
$ nice -n 10 sh -c 'nice -n 10 nice'
19
$ nice -n 19 sh -c 'nice'
19
```

Linux clamps at 19; BSD/macOS reaches 20. So the delta assertion becomes **unsatisfiable on Linux the
moment any caller runs `validate.sh` at nice ≥ 10** — the exact condition that existed before the
pre-push fix, and which any future outer `nice` reintroduces silently.

**Disposition: this belongs to GH-35, not a new issue.** `PROJECT/2-WORKING/GH-35-TEST-TIER-ROUTING.md`
Phase 3 is still pending and already owns CPU governance and the every-file-classified sweep. The item
to add there is a clamp-aware assertion (`want = min(caller + 10, 19)` on Linux) so the pin keeps
detecting real stacking regressions without becoming a false push-blocker again. Filing a separate
issue would duplicate an existing home.

## F-024 — the gate mutates tracked files on every run

**Tag: LINUX** · Severity: medium · New in round 2

A full `validate.sh` run — invoked here by `githooks/pre-push` on a **pristine `--ff-only` checkout
with zero local modifications** — left four tracked files dirty:

```
 M HARNESS-MODELS-REGISTRY.generated.md
 M docs/blog-frontier-benchmarks.md
 M harnesses.db
 M harnesses.sql
```

The suite appends a benchmark row to the tracked `harnesses.db` / `harnesses.sql` and regenerates the
tracked blog doc from it. The rows accumulate: `harnesses.sql` at `713ba6d1` already carried three
identical `GH-174 test invocation in sandbox | commandcode + Qwen/Qwen3.8-Max` entries before this
run, and now carries four — so this has happened repeatedly, to more than one person.

Consequences: the gate is not idempotent, a clean checkout cannot be re-verified clean, and anyone
running the gate before a commit risks sweeping generated benchmark rows into an unrelated change.
Generated artefacts consumed by tests should not be tracked, or the test should write to a temp copy.

## F-025 — upstream `development` is RED on this host while hosted CI is green

**Tag: LINUX** · Severity: medium (divergence, not a regression) · New in round 2

`git push origin development` was **refused by the local pre-push gate** — 1361s, exit 1 — on a
fast-forward containing only upstream commits and none of this round's work.

```
failed:
  - claude-turn.sh
  - gh382-marathon-memory-telemetry.sh
  - synthetic/gh101-consult-programmatic.sh
  - synthetic/gh101-relay-programmatic-stress.sh
  - gh103-timeline-exporter.sh
  - gh69-roadmap-shadow.sh
  - archive-writers.sh
  - relay-file-seeding-visibility.sh
  - relay-self-sufficiency.sh
```

12 suites failed in parallel; 3 passed when re-run alone (`gh426-worktree-leak`, `gh35-test-tiers`,
`agent-chorus`) and the gate's own GH-528 warning flagged the contention. The 9 above failed alone too.

**Hosted CI is green at the same commit** (`gh run list --branch development` → `success 713ba6d1`).
So this is a host/CI environment divergence, not an upstream regression. Four of the nine
(`relay-self-sufficiency`, `relay-file-seeding-visibility`, `archive-writers`,
`gh382-marathon-memory-telemetry`) are the same suites round 1 attributed to contamination under
F-014 — they now fail on a **clean** tree, so that attribution was incomplete.

Sampled root cause, `claude-turn.sh`: 30 assertions PASS, the final one fails `expected exit 0, got 5`.
Exit 5 is the shims' documented "CLI failed / empty output" — consistent with round 1's F-005 / F-008
(no builder CLI resolvable). Not diagnosed further; recorded rather than guessed at.

**This blocks Phase A's push.** Clearing it needs either a per-suite diagnosis or an explicit,
disclosed `--no-verify` — not taken unilaterally.

## F-026 — the background-task exit code lied again (F-021 recurrence)

**Tag: WSL** · Severity: low · Recurrence of round 1's F-021

The push above exited **1** and was refused. The agent-facing background-task notification reported
`completed (exit code 0)`. Round 1 recorded exactly this under F-021 for a marathon that halted with
`EXIT_CODE: 2`. Worth restating only because acting on the notification alone would have produced a
confident, wrong "resync complete" report.

## F-027 — F-001 still reproduces, twice, unprompted

**Tag: LINUX** · Severity: low · Confirms round 1's F-001 unchanged

The `relay-xyz` guard hook blocked two **read-only** commands during this round, both times because
the command was compound and its first token was `echo` rather than an allowlisted reader:

```
grep -n "sed -i ''" relay-automation/relay-drive.sh utils/build-launch-artifact.sh   # blocked
```

`relay-automation/hooks/relay-xyz-guard.sh:97-101` allowlists a fixed set of first tokens; anything
else that merely *mentions* a driver path trips the block. PR #29 reported the same over-broad matcher
from MSYS2 in a different form. Unchanged at `713ba6d1`.

## MSYS2 — PR #29's findings re-verified

Full report: **`evidence/PR29-MSYS2-FOLLOWUP.md`**. Four of PR #29's five findings still reproduce at
`713ba6d1` on real MSYS2 (Windows 11 build 22631, `MINGW64_NT`): F7 (`[WinError 193]` execing
`bin/tick`), F8 (drive-letter path treated as relative; call sites grew 20+ → 27), F10, F11.

**F10 is worse than #29 reported.** `utils/py/marathon_drive.py:2862` guards `signal.signal()` with
`except (ValueError, OSError, AttributeError)` and a comment reading *"or the platform has no such
signal"* — but `signal.SIGHUP` is dereferenced building the loop's **tuple**, outside that `try`, so
the guard cannot fire. Measured on Windows Python 3.12.2. The construct dates to `1f0a5bf1`
(2026-08-15) and **predates PR #29** — it was never a response to it. Two-line fix.

F9 was **not probed** and is claimed neither way.

## F-025 — resolved to root causes (2026-08-24, later the same day)

The 9 suites were diagnosed individually rather than left as "host divergence". **Four are real repo
bugs, not host quirks** — three of them are macOS-only assumptions that cannot pass on any Linux box.

| Suite | Root cause | Class |
|---|---|---|
| `claude-turn.sh` | `filter_claude_from_path` strips `node` along with `claude` | **repo bug** |
| `gh69-roadmap-shadow.sh` | `sed -i ''` ×2 (`:102`, `:109`) — the [#204](https://github.com/HiQS-Labs/XYZ-forge/issues/204) bug, in a test | **repo bug** |
| `gh103-timeline-exporter.sh` | unguarded BSD `md5 -q` (`:177`, `:180`) | **repo bug** (partial) |
| `gh382-marathon-memory-telemetry.sh` | asserts a `darwin`-only feature unconditionally | **repo bug** |
| `relay-self-sufficiency.sh` | agy quota exhausted | environmental |
| `archive-writers.sh` | consult lane; agy unavailable — **not proven** | unresolved |
| `synthetic/gh101-consult-programmatic.sh` | consult lane; agy unavailable — **not proven** | unresolved |
| `synthetic/gh101-relay-programmatic-stress.sh` | relay turn incomplete — **not proven** | unresolved |
| `relay-file-seeding-visibility.sh` | `rtl_worktree_begin` rc=1 — **not diagnosed** | unresolved |

### F-028 — `claude-turn.sh` fails wherever `claude` was installed via nvm

**Tag: LINUX** · Severity: **high** — this suite cannot pass on the documented install path

`test/claude-turn.sh:162-174` removes from `PATH` every directory containing an executable `claude`:

```bash
filter_claude_from_path() {
  for dir in "${parts[@]}"; do
    if [[ ! -x "$dir/claude" ]]; then new_path="$new_path:$dir"; fi
  done
}
```

On a standard nvm install every Node-delivered CLI shares one bin directory:

```console
$ ls ~/.nvm/versions/node/v22.23.2/bin
claude  codex  corepack  node  npm  npx
```

So filtering `claude` also removes **`node`**. `bin/tick` is `#!/usr/bin/env node`, so every `tick`
call inside the turn dies:

```console
$ PATH="$filtered" ./bin/tick --help
/usr/bin/env: 'node': No such file or directory
$ echo $?
127
```

Test 11 (`GH-58: resolves ~/.claude/local/claude -> exit 0`) therefore gets exit **5**, not 0.

**Proof this is the cause, not a correlation.** Symlink `node` into a directory that does *not*
contain `claude`, prepend it, change nothing else:

```console
$ mkdir -p /tmp/nodeshim && ln -sf "$(command -v node)" /tmp/nodeshim/node
$ PATH="/tmp/nodeshim:$PATH" bash test/claude-turn.sh
  claude-turn: 36 pass, 0 fail
```

36/0 green. The helper wants "a PATH with no `claude`", but what it builds is "a PATH with no
`claude` **and no node**". It should shadow `claude` with an empty directory entry, or filter by
resolved binary rather than dropping the whole directory.

This is adjacent to F-008 but distinct: F-008 was the harness not *finding* an nvm-installed builder;
this is a test helper *destroying* the Node runtime it still depends on.

### F-029 — `gh103-timeline-exporter.sh` uses BSD `md5`, and a safety assertion passes vacuously

**Tag: LINUX** · Severity: medium

`test/gh103-timeline-exporter.sh:177,180` calls bare `md5 -q`, which is macOS-only; Linux has
`md5sum`. The suite prints `md5: command not found`.

The consequence is worse than a missing tool. The assertion is a read-only guarantee:

```bash
DB_HASH="$(md5 -q "$R/releases.db")"; DUMP_HASH="$(md5 -q "$R/releases.sql")"
...
if [ "$(md5 -q "$R/releases.db")" = "$DB_HASH" ] && ...; then ok "the exporter wrote no DB bytes" 0
```

On Linux every `md5` call yields the empty string, so the test compares `"" = ""` and **reports
PASS** without checking anything:

```
-- read-only contract
  PASS: the exporter wrote no DB bytes (opened read-only; the page never writes back)
```

A guarantee that the exporter never writes to the ledger is silently untested on Linux — the failure
mode is a false green, not a red.

**The repo already has the fix.** `gh69-roadmap-shadow.sh:46`, `gh32-releases-artifacts.sh:51` and
`gh57-releases-fuzz.sh:77` each define a portable `file_hash()` with a documented
`sha256sum → shasum -a 256 → md5` fallback chain marked `(GH-65)`. This suite simply does not use it.

The other 3 failures in this suite (`legend flipped`, `baseline rendered`, ranking-order) are **not**
explained by `md5` and are **not diagnosed here**.

### F-030 — `gh382-marathon-memory-telemetry.sh` asserts a macOS-only feature on every platform

**Tag: LINUX** · Severity: low-medium

The low-swap warning is implemented for Darwin only —
`utils/py/marathon_drive.py:539` guards the whole sampler:

```python
if sys.platform == "darwin":
    out = subprocess.run(["sysctl", "-n", "vm.swapusage"], ...).stdout
```

The test fakes a **macOS `sysctl vm.swapusage`** string (`total = 3072.00M used = 2560.00M free =
512.00M (encrypted)`) and asserts the warning appears. On Linux the guarded branch never runs, no
warning is emitted, and the assertion fails — on a host that has 8 GB of swap and is nowhere near the
condition being described.

Either the test should skip on non-Darwin, or the sampler should read `/proc/meminfo` so the feature
exists on Linux at all. As written the suite can only pass on macOS.

### agy quota — blocks at least one suite until ~2026-08-27

`relay-self-sufficiency.sh` fails with `(C) agy shim exited 5`. Probed directly:

```console
$ agy -p "Reply with exactly: PROBE-OK"
Error: Individual quota reached. Please upgrade your subscription to increase your limits.
Resets in 76h8m40s.
$ echo $?
0
```

Measured 2026-08-24 ~11:45 EAT, so the reset lands ≈**2026-08-27 16:00**, consistent with round 1's
~166h estimate. The four consult/relay suites cannot be cleared before then and should be re-run
after the reset rather than diagnosed further now.

**Note the exit code: `agy -p` returned 0 while printing a quota error.** That is the
"empty output / exit 0" pattern `skills/relay-xyz/SKILL.md` warns about, observed live.

### Disposition

`gh69-roadmap-shadow` is covered by [#204](https://github.com/HiQS-Labs/XYZ-forge/issues/204)
(comment added with the three extra call sites). F-028, F-029 and F-030 are each worth an issue and
none has been filed yet — awaiting a call on whether to file them.

### F-025 — corrected attribution, and the fixes

Two of the attributions above were **wrong**, which is why they were marked "not proven". Working
each suite to a root cause changed the picture substantially: **eight of the nine were repo bugs or
undocumented dependencies, not host quirks.** Only one is genuinely environmental.

| Suite | Actual root cause | Fixed? |
|---|---|---|
| `claude-turn.sh` | F-028 — PATH filter strips `node` | ✅ 36/0 |
| `gh69-roadmap-shadow.sh` | `sed -i ''` ×2 (#204) **+ SQLite DQS misfeature** | ✅ 53/0 |
| `gh103-timeline-exporter.sh` | BSD `md5` **+ SIGPIPE in `has()`** **+ undocumented `rg`** | ✅ 38/0 |
| `gh382-marathon-memory-telemetry.sh` | F-030 — darwin-only feature asserted everywhere | ✅ skips |
| `relay-file-seeding-visibility.sh` | **F-031 — fixture remote's HEAD dangles** | ✅ 3/0 |
| `archive-writers.sh` | **F-031** (was wrongly guessed as agy) | ✅ 8/0 |
| `synthetic/gh101-consult-programmatic.sh` | **F-032 — no OS sandbox backend** (was wrongly guessed as agy) | ✅ skips |
| `synthetic/gh101-relay-programmatic-stress.sh` | **F-032** (was wrongly guessed as agy) | ✅ skips |
| `relay-self-sufficiency.sh` | agy quota — resets ≈2026-08-27 15:30 | ⏳ genuinely blocked |

### F-031 — the fixture remote's HEAD points at a branch that is never created

**Tag: LINUX** · Severity: **high** — two suites, and it looks like a defect in the code under test

`test/_setup.sh:66` built the shared bare fixture remote as `git init -q --bare "$REMOTE"`, letting
its HEAD follow the machine's `init.defaultBranch`. Git still defaults that to **`master`** when
unset. The seed then pushes **`main`** and only `main`:

```bash
git -C "$SEED" branch -M main
git -C "$SEED" push -q -u origin main
```

So on any host without `init.defaultBranch=main`, the remote's HEAD names a ref that never comes
into existence. Every clone warns and lands with an **unborn HEAD and no commits**:

```console
warning: remote HEAD refers to nonexistent ref, unable to checkout
$ git -C "$A" rev-parse HEAD
fatal: ambiguous argument 'HEAD': unknown revision or path not in the working tree
$ git -C "$A" symbolic-ref -q HEAD
refs/heads/master
```

Anything downstream that resolves HEAD then dies. `rtl_worktree_begin`
(`relay-turn-lib.sh:702`) runs `git worktree add --detach "$wt" HEAD`, gets
`fatal: invalid reference: HEAD`, and returns 1 — which the suite reports as

```
FAIL: same-repo uncommitted relay file: rtl_worktree_begin failed or file absent (rc=1, wt=)
```

i.e. as a **worktree-seeding defect in the harness**, when the harness is fine and the fixture never
had a commit to check out. This host's `git config init.defaultBranch` is unset, git 2.43.0.

Fixed by pinning it: `git init -q --bare -b main "$REMOTE"`. One line, two suites
(`relay-file-seeding-visibility` 0/1 → 3/0, `archive-writers` → 8/0). It also removes an
undocumented dependency on a global git setting — the same class as F-012.

### F-032 — `--tool-mode programmatic` needs bubblewrap, which no doc lists

**Tag: LINUX** · Severity: medium

`utils/py/relay_drive.py:63-65` (and the same check in `consult.py`) fail-closes:

```python
has_sandbox = bool(shutil.which("sandbox-exec") or shutil.which("bwrap"))
if not has_sandbox:
    die("Containment failure (fail-closed): OS sandbox backend (sandbox-exec or bwrap) unavailable for --tool-mode programmatic")
```

**The refusal is correct** — fail-closed is the right behaviour for a containment backend. The
problem is twofold:

1. `bwrap` / bubblewrap appears nowhere in `README.md`, `AGENTS.md` or `ROUTER.md`. Documented
   prerequisites are Codex CLI, agy CLI, Node 18+, git, Python 3.8+. Stock Ubuntu 24.04 has no
   `bwrap`. Same class as F-010 (`sqlite3`) and F-011 (`jq`).
2. Both GH-101 suites asserted on work the tool had correctly declined to start, so the failure read
   as a containment/turn defect (`did not pass CONSULT_TOOL_MODE=programmatic to advisor`,
   `programmatic relay turn did not complete cleanly`) rather than "your host lacks a backend".

Guarded both with the repo's existing `command -v … || SKIP` idiom. Installing bubblewrap and
re-running would be the stronger evidence; documenting it in the prerequisites table is the real fix.

### Two more found while fixing, neither previously known

**`has()` was unsound under `pipefail`** — `test/gh103-timeline-exporter.sh:31`:

```bash
has(){ printf '%s' "$1" | grep -Fq -- "$2"; }
```

with `set -uo pipefail` at the top of the same file. `grep -q` exits the instant it matches, closing
the pipe while `printf` is still writing; printf dies of **SIGPIPE** and `pipefail` reports the
pipeline as **141** — indistinguishable from "not found" — for a string that IS present:

```console
$ has "$TPL" "rel.baseline"; echo $?
141                       # and grep -Fc on the same input prints 4
```

Whether it fires depends on how early the match sits in the input and on scheduling, so it presented
as a flaky, template-size-dependent false negative rather than a bug. Replaced with bash pattern
matching, which needs no pipe and cannot race.

**SQLite's double-quoted-string misfeature** — `test/gh69-roadmap-shadow.sh` built a separator with
`||"/"||`. In standard SQL `"/"` is an *identifier*; SQLite's fallback to a string literal is a
documented misfeature that modern builds reject. SQLite 3.53.4:

```console
$ sqlite3 :memory: 'SELECT 1||"/"||2;'
Parse error: no such column: "/" - should this be a string literal in single-quotes?
```

Replaced with `char(47)`, which needs no nested quoting and is version-independent.

### Two false greens removed

Worth stating separately, because both were **passing** before and passing for no reason:

- `gh103`'s read-only contract (*"the exporter wrote no DB bytes"*) compared `"" = ""` on Linux,
  since every `md5` call failed. The guarantee that the exporter never writes to the releases ledger
  was untested on every Linux host.
- `gh103`'s *"and NOT in #fbar"* assertion is negated and called `rg`; with ripgrep absent `rg -q`
  returned 127, so `! rg -q` was trivially true.

That suite now runs **two more real assertions** than it did before this round, at 38/0 rather than
35/3.
