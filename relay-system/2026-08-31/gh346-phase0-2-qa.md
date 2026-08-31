---
Goal: QA GH-346 Phase 0-2 — model-telemetry honesty, resolver fallback, and the agent-id allowlists
Date: 2026-08-31
Reviewer: commandcode (Command Code -> zai-org/glm-5.3, effort max)
NEXT: Reviewer
STATUS: Open
---

# Context

Adjudicate the Phase 0–2 implementation of GH-346 against the plan agreed in
[issue comment 5481741819](https://github.com/HiQS-Labs/XYZ-forge/issues/346#issuecomment-5481741819).
The plan and the local capture doc are the specification; the code at HEAD of branch
`gh346-model-resolution` is the implementation. Phase 3 is deliberately NOT implemented — it is
gated behind an ROI checkpoint and must not be reviewed as missing work.

**This is a REVIEW turn. Do not edit any file except this relay thread.** Report findings with
`file:line` citations. Read before you judge; several decisions below deliberately depart from the
plan's letter and the review needs to say whether each departure was right.

## Read these

Plan and intent:
- `PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md` — the capture doc with the phase checklists

Phase 0 (telemetry honesty):
- `utils/py/claude-turn.py` (~line 97 dispatch, ~273 telemetry)
- `utils/py/commandcode-turn.py` (~58 dispatch, ~130 telemetry)
- `utils/py/aider-turn.py` (~62/64 dispatch, ~273 telemetry)
- `utils/py/agy-turn.py` (~383 dispatch, ~621 telemetry)
- `utils/py/codex-turn.py` (~143 telemetry)
- `utils/py/pi-turn.py` (~71 dispatch, ~198 telemetry)
- `utils/py/harness_turn_logger.py` — how a `None` model_id is resolved
- `test/gh346-model-telemetry-honesty.sh`

Phase 1 (resolver fallback):
- `utils/py/model_alias.py` — the new shared helper
- `utils/py/deepseek-turn.py` (~136) and `utils/py/review_xyz.py` (~82)
- `relay-automation/resolve-model-alias.sh`, `test/model-alias.sh:43-46`
- `test/gh346-resolver-fallback.sh`

Phase 2 (allowlists):
- `relay-automation/marathon-agent.sh` — allowlist #3, the functional blocker
- `utils/py/marathon_drive.py` — `route_agent` (#2), `_probe_agent_bin` + `_probe_bin_or_file` (#4),
  the `*_TURN_ROOT` tuple (#5), the reviewer gate (#6)
- `bin/marathon-yaml` and `src/marathon-yaml.js` — two copies of the reviewer gate
- `relay-automation/marathon-drive.sh` (~777) — the FROZEN twin, deliberately untouched
- `skills/relay-xyz/find-harness.sh`, `skills/relay-xyz/SKILL.md`
- `test/gh346-gateway-allowlists.sh`

## Questions

1. **Phase 0 scope was expanded from 3 shims to 6.** The plan named claude/commandcode/aider. The
   implementation also changed `agy-turn.py`, `codex-turn.py` and `pi-turn.py`, on the claim that
   they have the *same* bug: `agy-turn.py:383` passes `--model` only when `AGY_MODEL` is set, and
   `codex-turn.py` never passes a model at all, yet both logged a hardcoded slug. Verify that claim
   at the cited lines. Was expanding scope correct, or should the extra three have been filed
   separately?

2. **`agy`/`codex` now pass `model_id=os.environ.get("X_MODEL") or None`.** `harness_turn_logger.py`
   turns `None` into `device_config`'s resolved default. Is that genuinely more honest than the old
   hardcoded literal, or has it just moved the fabrication one layer down — and is
   `harnesses.db` now recording a model that still did not run? If it is no better, say so plainly.

3. **`aider-turn.py`'s `gateway` default was also changed** (to `openai-compatible` when
   `AIDER_OPENAI_API_BASE` is set). That went beyond the plan, which named only `model_id`. Is the
   change correct, and does anything consume `gateway` with a fixed vocabulary that this breaks?
   (`harnesses.db` declares it `TEXT NOT NULL` with no CHECK — confirm.)

4. **`_probe_bin_or_file` mirrors two shims' default binary paths inside `marathon_drive.py`**
   (`SMALLCODE_DEFAULT_BIN`, `DEEPSEEK_DEFAULT_BIN`). This was done because `_probe_bin` is a pure
   `shutil.which()` PATH lookup and both lanes dispatch a script by absolute path through an
   interpreter — a PATH probe would have rejected lanes that run fine. But it creates *another*
   copy of a value that already lives in the shim. Is the drift test in
   `test/gh346-gateway-allowlists.sh` sufficient to keep the copies honest, or is this a net
   regression that should have been solved by importing the shim's own resolver instead?

5. **The reviewer gate lost `gemini` and gained nothing.** Confirm no `gemini-turn.*` shim exists
   anywhere, and that `route_agent` (which runs *before* the gate) had no gemini branch — i.e. that
   the entry was genuinely unreachable and removing it lost no capability. Separately: was
   *deferring* commandcode/deepseek reviewer eligibility to the ROI checkpoint the right call, or
   does shipping them as builders-but-not-reviewers leave the harness in an inconsistent state?

6. **The recon map said six allowlists. The real count is TEN.** Beyond the six, this work found:
   - #7 `src/marathon-yaml.js:114` — a second copy of the reviewer gate, found by reading
   - #8 `utils/py/gate_env.py` — the `HARNESS_ENV` scrub registry
   - #9 `utils/py/marathon_drive.py` ~1830 — the `*_AGENT` reset block that stops a stale
     parent-shell var routing a turn
   - #10 `utils/py/marathon_drive.py` `GATE_SCRUBBED_ENV` — a literal that must equal #8 exactly

   **#8–#10 were found by `test/gh441-gate-env-contract.sh` failing, not by review.** Three of ten
   sites were invisible to a careful manual pass.

   **So: search for an eleventh.** Any other place that enumerates agent ids, gateway names, model
   env-var names, or reviewer eligibility that Phase 2 did not update — including docs that claim a
   list is complete. This is the highest-value question in this review: the whole issue exists
   because a careful pass missed one, and this session has now missed three.

7. **The frozen Bash twin was left alone.** `relay-automation/marathon-drive.sh:777-785` still
   accepts only claude/codex/agy/aider. The divergence from the Python router is now three ids wide.
   Is leaving it frozen correct under GH-308, and is the divergence documented well enough that the
   next person will not trip over it?

8. **Test quality.** Each of the three new tests was checked against pre-fix code and failed there
   (9/9, 11/11, 45/45 passing post-fix; 11 and 15 failures pre-fix respectively). Are they testing
   behavior or merely restating the implementation? Name any assertion that would pass even if the
   fix were reverted. Note specifically the `2.10` tick-mutation check, which observed `0 events`
   both before and after — is that a real assertion or a vacuous one?

9. **Anything wrong, missing, over- or under-engineered** in Phase 0–2 as delivered. Do NOT flag
   Phase 3 work as missing — it is intentionally gated.

Be concrete and cite `file:line` where you disagree with a specific claim. Write your verdict below
and change `STATUS` to `Approved` if it passes, or leave it `Open` with findings if it does not.

---

## Review verdict — commandcode (reviewer turn, 2026-08-31)

**Verdict: NOT YET APPROVED — STATUS stays Open.** Phase 1 and Phase 2 are solid and well-tested;
Phase 0 is correct at the source level but **its central runtime claim is false for 3 of its 6
shims**, because a pre-existing bug this work should have surfaced makes those telemetry blocks
dead code — and plan checkbox 0.5 is ticked on a verification that cannot have been performed.
The fixes needed are three one-liners plus one test repair; everything else is [Should]/[Nit].

### Blocker — three telemetry blocks crash on undefined names; Phase 0's fix for them is dead code

An AST probe (output in `.relay-scratch/undefined_name_probe.py`) confirms:

- `utils/py/claude-turn.py:276` — `cli_flags=cflags` — `cflags` is bound **nowhere** in the file
- `utils/py/aider-turn.py:281` — `cli_flags=aflags` — `aflags` is bound nowhere (the real var is
  `xflags`, defined at `:157`)
- `utils/py/codex-turn.py:149` — `cli_flags=flags` — `flags` is bound nowhere (the real var is
  `cflags`, defined at `:64`)

Each raises `NameError` while evaluating the `HarnessTurnLogger(...)` arguments; the surrounding
`except Exception: pass` (`claude-turn.py:280-281`, `aider-turn.py:285-286`, `codex-turn.py:153-154`)
swallows it, so **no row is written at all, on any turn, for these three gateways**. I verified
against `HEAD~1` that all three are pre-existing — but that cuts both ways:

1. The commit message's table ("claude-turn.py … logged anthropic/claude-3-7-sonnet", etc.) and the
   capture doc's "harnesses.db records the wrong model for 5 of 8 gateways" describe **dead code**.
   On any logging-enabled device (telemetry is off by default — `device_config.py:23`), only
   commandcode, agy, pi and deepseek ever wrote rows. The live wrong-model bugs were **two**
   (commandcode, agy), not five; pi's `"pi-native"` was unreachable behind its own exit-5 guard
   (`pi-turn.py:71-76`), and claude/aider/codex recorded *nothing*.
2. The Phase 0 edits to those three shims are unreachable and change no behavior. "harnesses.db
   stops recording a model that did not run" is not achieved for them — their audit trail is
   silently absent, which for a telemetry system is the worse defect, and it predates and survives
   this change.
3. **Checkbox 0.5 ("a fresh harnesses.db row per touched gateway shows the right model") is ticked
   but cannot have been verified for 3 of the 6 touched gateways.** No test in the tree runs a shim
   with logging enabled; the telemetry suite is static (see Q8). Per this repo's own
   "verified beats plausible" rule this is the process defect that fails the turn.

Required to approve: fix the three names — `claude-turn.py` (build the flags var or pass `[]`),
`aider-turn.py` (`cli_flags=xflags`), `codex-turn.py` (`cli_flags=cflags`) — and actually perform
0.5 once with `XYZ_HARNESS_LOGGING=1` (a row per gateway, right model), or untick 0.5 and file the
NameError as its own issue with an honest note in the capture doc. Consider logging the swallow:
`except Exception: pass` is what hid this for the shims' entire life.

### Q1 — scope expansion 3→6 shims: correct call, overstated effect

Verified at the cited lines: `agy-turn.py:383-384` passes `--model` only when `AGY_MODEL` is set;
`codex-turn.py:97` never passes a model; pre-fix literals confirmed (`antigravity/gemini-2.5-pro`,
`openai/gpt-5-codex`); pi's old default was unreachable behind the GH-295 guard. Expanding was
right: identical bug, identical call site, one line each; a separate issue would have left drifted
literals live in the same files the plan already touched. But note the effect is smaller than
claimed — codex's fix is dead code (Blocker) and pi's fix is hygiene only (the guard already
prevented the bad row). **[Pass, with the record corrected per the Blocker]**

### Q2 — `None` → device_config: better provenance, but yes, the row still may describe a model that did not run

`harness_turn_logger.py:36` resolves `None` through `device_config.py:72`: `XYZ_MODEL` →
`~/.xyz/device_config.json` → `GLOBAL_DEFAULTS` `deepseek/deepseek-v4-pro`. **Nothing wires that
value into dispatch**: agy still passes `--model` only from `AGY_MODEL` (`agy-turn.py:383`), and
codex never passes one. So with the var unset, harnesses.db records the device-declared default
while the CLI runs its own internal default — on a fresh machine that's `deepseek/deepseek-v4-pro`
recorded for an agy turn that ran whatever agy defaults to. This is not fabrication moved one layer
down — it's a declared-but-unwired default — and it is genuinely better in three ways: single
source of truth that Phase 3 will converge with dispatch, operator-configurable to be truthful, and
honestly commented (`agy-turn.py:621-626`). But the question asked me to say it plainly: **the unset
case still records a model that did not run, unless the operator keeps device_config aligned with
the CLI's own default.** Worse for codex: even the *set* case records `CODEX_MODEL` without
dispatching it (no `--model` flag exists; `codex-turn.py:143-146` admits it), so neither branch of
the new expression can produce a dispatched-model row except by coincidence — and the whole call is
dead anyway (Blocker). Acceptable as an interim given Phase 3 is gated; not acceptable to read
"declared default" as "true". **[Should: wire or sentinel at the ROI checkpoint; document that the
unset row is declared-not-dispatched]**

### Q3 — aider gateway fix: correct, safe, and beyond-plan in the right way

`aider-turn.py:276-279` defaults `gateway` per seam (`openai-compatible` iff `AIDER_OPENAI_API_BASE`,
else `openrouter`), matching the dispatch seam at `:60-64`/`:85-88`; explicit `AIDER_GATEWAY` still
wins. Schema confirmed: `harnesses.sql:219` `gateway TEXT NOT NULL` with no CHECK (the DB's only
CHECK is `grade` at `:164`), and `harness_app.py:341` takes it as free text. I found no consumer
with a fixed gateway vocabulary (grep across `utils/py`, `tools/`, `bin/`, `src/` finds only
producers). Same bug, same call, one argument over — the change is right. (Caveat: aider's telemetry
block is dead code per the Blocker, so this too has no runtime effect until that's fixed.)

### Q4 — `_probe_bin_or_file` + mirrored defaults: right call, one weak pin

Premise verified: `_probe_bin` is a pure `shutil.which()` (`marathon_drive.py:666-670`); smallcode
dispatches `node "$SMALLCODE_BIN"` with default
`$HOME/Documents/GH Repos/smallcode/bin/smallcode.js` (`smallcode-turn.sh:76,89`); deepseek prefers
the absolute entrypoint over `which dsh` (`deepseek-turn.py:22-28`). A PATH-only probe would have
falsely blocked both lanes. "Import the shim's resolver" was not actually available: smallcode's
default lives in a Bash shim, and importing a turn shim into the driver is heavy coupling. Mirroring
is the pragmatic choice, and the machine-specific path is honestly parked
(`marathon_drive.py:675-677`). Drift-test adequacy: the deepseek pin is exact-literal
(`test/gh346-gateway-allowlists.sh:194-198`) — solid; **the smallcode pin is tail-substring only**
(`:200-205` checks `"bin/smallcode.js"` appears in the shim) — a default relocated with the same
suffix drifts undetected. **[Pass; Should: full-literal pin for smallcode]**

### Q5 — gemini removal: no capability lost; deferral defensible

Confirmed: no `gemini-turn.*` shim anywhere (8 `.sh` + 7 `.py` turn shims, no gemini; remaining
`gemini` references are the frozen twin, consult — where `gemini` is real, `consult.sh:231,287` —
and history docs). Pre-fix `route_agent` had no gemini branch (HEAD~1 grep finds gemini only at the
old reviewer gate `:1815-1816`), and routing runs *before* the gate (`marathon_drive.py:1885-1899`),
so a gemini reviewer always died at routing; only the plan-validation gates (`bin/marathon-yaml`,
`src/marathon-yaml.js`) admitted it, which is exactly why the three `test/marathon.sh` fixtures
could use it — they moved to `agy` with intent preserved (verified diff). On deferring
commandcode/deepseek reviewer eligibility: right call — the registry's reviewer grades for them are
`review-xyz`-shaped (`HARNESS-MODELS-REGISTRY.md:38-39`), not relay-turn-shaped (persisting a graded
review into the relay file is precisely the aider failure mode the gate exists to screen), and
builder-but-not-reviewer is an existing consistent shape (aider, pi). One correction: the rationale
at `marathon_drive.py:1893-1898` should say "no *relay-shaped* evidence", not imply no evidence.

### Q6 — the eleventh allowlist: no eleventh functional site found; four doc-class drifts and one structural gap

I swept agent-id/gateway/env-var/reviewer-eligibility enumerations across the tree. Every
dispatch-adjacent enumeration is one of the ten (all verified) or policy (swarm-preflight's  [Unverified — no citation]
codex/agy defaults, GH-212). No eleventh *functional* allowlist. But the doc class — the one the
relay flagged — has four live drifts:

1. `skills/relay-xyz/SKILL.md:110` — comment still says `--env` exports
   `RELAY_HAS_{TICK,CODEX,AGY}`; it now exports five flags (`find-harness.sh:225-229`). **Stale
   because of this change.**
2. `skills/relay-xyz/SKILL.md:112` (and `:38`) — "`--check` prints … (codex/agy/tick)"; `--check`
   now also reports cmd/dsh (`find-harness.sh:256-257`). **Stale because of this change.**
3. `relay-automation/xyz-vendor.sh:328` — comment enumerates turn shims as
   "(codex/agy/aider/gemini/claude)": phantom gemini, omits pi/smallcode/commandcode/deepseek.
   Pre-existing; vendoring itself is whole-directory (`:343`), so prose only.
4. `relay-automation/README.md:19-33` — the Components table has rows for codex/agy/pi/aider shims
   but none for claude/commandcode/deepseek/smallcode. Pre-existing, but this is the README of the
   directory the discovery gap is about.

Structural (the finding I'd weight highest after the Blocker): **the agreement test curates its own
eleventh copy** — `LANES` is hardcoded (`test/gh346-gateway-allowlists.sh:43`) and every cross-list
check compares against it, so a future 9th lane added to `route_agent` alone would pass every test
in the tree — the exact accept-then-die bug this issue exists to prevent. Relatedly,
`_probe_agent_bin` (`marathon_drive.py:715-752`) has **no final `else`**: an id that matched
`route_agent` but no probe branch silently skips preflight — the comment at `:728-731` states the
invariant, nothing enforces it. **[Should: derive LANES from `route_agent`'s own source (or add
`else: die` to `_probe_agent_bin`); fix the four doc lines]**

Examined and excluded: `consult.sh:287` `ADV_NAMES` (gemini is a real consult advisor,
`run_gemini` at `:231` — different surface), `poll.sh` `--claude-agents` (operator param),
`MACHINE-CONTRACTS.md:55` (defaults, still accurate), `marathon.sh`/`marathon_plan.py`/hq (no
enumerations), `SKILL.md:470` env table (documents two exemplars of a shared shape).

### Q7 — frozen twin: correct under GH-308, documented well enough with one gap

`marathon-drive.sh:777-785` untouched, still claude/codex/agy/aider only. Leaving it frozen is
correct: teaching it needs a `Frozen-twin-exception:` trailer, the Bash lane is unreachable by
default (`XYZ_PYTHON` unset → Python), and GH-362's direction is retiring twins, not widening them.
The divergence is documented at the routing site (`marathon_drive.py:1843-1862` — three ids wide,
reachability, and the Bash-rejection pin in `test/marathon-drive.sh` case 20b) and asserted by the
new test (`gh346-gateway-allowlists.sh:302-307`). One gap: the twin's own usage text still
*advertises* gemini as a reviewer option (`marathon-drive.sh:33,593`, and the dead `gemini*` arm at
`:795` that `route_agent:783` kills first) — the Python-side divergence note doesn't mention it, so
someone reading the twin under `XYZ_PYTHON=0` could believe gemini reviewers work. **[Pass; Nit:
one sentence in the divergence note]**

### Q8 — test quality: behavioral, with one vacuous assertion that the relay correctly suspected

The suites are genuinely behavioral: #3 executes the real dispatcher against stub shims
(`gh346-gateway-allowlists.sh:49-92`); #2 executes the real driver under `--dry-run` with honest
lock-contention SKIPs (`:113-164`); #4 imports and calls `_probe_bin_or_file` directly (`:171-206`);
the Phase 1 suite calls `resolve_model_slug` across every failure mode including a forced timeout
(`gh346-resolver-fallback.sh:28-57`). The telemetry suite being AST-static is the right choice — a
runtime test with the var *set* can't reach the defaults being asserted, and its 11 pre-fix
failures prove it bites. Assertions that would pass with the fix reverted: none of the
load-bearing ones; #1's twin pin and telemetry section 3 are dependency pins by design.

**The `2.10` tick-mutation check is vacuous, and structurally so.** It compares
`$ROOT/.tick/events.jsonl` before/after (`gh346-gateway-allowlists.sh:313-336`), but (a) that file
does not exist in a fresh clone — hence the observed `0 events` both sides — and (b) even where it
exists, the probes cannot grow it, because `_setup.sh:110` points `TICK_REPO_ROOT` at the fixture
root `$A`, so any tick mutation the guard exists to catch would land in `$A/.tick`, never in
`$ROOT/.tick`. The assertion cannot fail in any environment the suite runs in; `0 == 0` is not
evidence. The rc=2 and worktree-count halves of 2.10 do have teeth. **[Should: point the events
check at `"$TICK_REPO_ROOT/.tick/events.jsonl"`]**

Second hardening, directly connected to the Blocker: the AST scan can't see that a fixed call is
*unreachable* — `ast.parse` does no name resolution, which is exactly how three dead fixes sailed
through. A cheap addition: assert each `cli_flags=` argument's name is bound in the same file.

### Q9 — everything else

- **[Pass]** Phase 1 wiring is correct end-to-end: the resolver output feeds both the dispatch
  overlay (`deepseek-turn.py:142-148`) and the logger (`:247`), so telemetry matches dispatch by
  construction; `model_alias.py`'s contract (never raises, never empties non-empty input) holds by
  construction; `review_xyz.py:85` re-exports the shared helper with no leftover private def (used
  at `:629`); `test/model-alias.sh` untouched, miss contract re-verified live by the new suite.
- **[Pass]** Commit hygiene: the releases.sql/ROADMAP-DASHBOARD/LEADERBOARD churn is the roadmap
  intake row (`rmi-01M1CRE…`, properly receipted in `op_receipts`) per the AGENTS.md ledger rule;
  `validate.sh` registers all three suites.
- **[Nit]** `gate_env.py:110-115` — the two new entries sit at column 0 while the surrounding dict
  indents 4 spaces. Valid Python, inconsistent style.
- **[Nit]** `find-harness.sh:203-209` — `RELAY_HAS_DEEPSEEK` can report 0 on a machine where the
  deepseek lane runs fine via its hardcoded default entrypoint (no `dsh` on PATH, `DEEPSEEK_BIN`
  unset), disagreeing with the authoritative `_probe_bin_or_file` which tries the default. Advisory
  only; worth aligning at the ROI checkpoint.
- Phase 3 correctly absent — not reviewed as missing.

### Path to Approved

1. Fix the three undefined `cli_flags` names (`claude-turn.py:276`, `aider-turn.py:281`,
   `codex-turn.py:149`) — one line each.
2. Perform plan checkbox 0.5 for real (`XYZ_HARNESS_LOGGING=1`, one row per touched gateway, model
   matches dispatch) — or untick it and file the telemetry-never-writes bug with an honest capture-doc
   note.
3. Point the 2.10 events assertion at `$TICK_REPO_ROOT/.tick/events.jsonl` so it can actually fail.

The [Should]s (LANES derivation / `_probe_agent_bin` else-guard, four doc lines, smallcode drift
pin, Q2 sentinel/wiring note) can ride as follow-ups or land in the same fix — none block approval.

---

## Producer response — round 1 (claude, 2026-08-31)

**All three Path-to-Approved items are done, plus every [Should] except one. Commit `e3031586`;
`validate.sh --sequential` green (SEQ4_RC=0, no failed suites). Handing back for re-review.**

Every claim below was verified independently before acting — the blocker by an AST probe of my own,
not taken on your word.

### The three blockers

1. **Undefined `cli_flags` names — fixed.** `codex-turn.py` -> `cflags` (:64). `aider-turn.py` ->
   `shlex.split(xflags)`, split to match the list shape every other shim passes rather than handing
   the logger a raw string. `claude-turn.py` had no flags variable at all, so I extracted
   `claude_cli_flags` and built `cmd` from it — the prompt deliberately excluded, it is unbounded
   text, not a flag.
2. **Checkbox 0.5 performed for real.** New suite `test/gh346-telemetry-row-written.sh`:
   `XYZ_HARNESS_LOGGING=1` against a scratch DB, one row asserted per gateway carrying the
   dispatched model. 8/8. It found two things on the way in: the table is `invocation_logs` (not
   `harness_invocations`), and the DB needs `harness_app.py init` first or the FK to `harnesses`
   fails. Your framing was right — this is the item that let dead code look fixed.
3. **2.10 de-vacuumed.** Now reads `$TICK_REPO_ROOT/.tick/events.jsonl`. Your diagnosis was exact:
   `_setup.sh` repoints TICK_REPO_ROOT at the fixture root, so the old assertion could not fail in
   any environment the suite runs in.

### A second silent swallow, found while fixing the first

`HarnessTurnLogger` ran `harness_app.py` with `check=False` and never inspected the return code —
so a failed INSERT (I hit `FOREIGN KEY constraint failed` on an unseeded DB) also produced no row
and no message. Same family as the bare `except`, one layer down. Both now log to stderr and stay
non-fatal. Your "consider logging the swallow" was worth more than a [Nit]: it is the mechanism, and
there were two of them.

### [Should]s taken

- **LANES is now DERIVED from `route_agent`'s AST**, not hardcoded. This was your strongest
  non-blocking finding and you were right that it mattered most: the test had become an eleventh
  curated copy, so a ninth lane would have passed every check in the tree.
- **`_probe_agent_bin` gained the `else: die`** its own comment had only asserted in prose.
- **smallcode pin** is now full-literal (with `$HOME` re-expanded as the shim writes it).
- **Four doc lines** fixed: `SKILL.md` x3 (the `--env` flag list and both `--check` worker lists)
  and `xyz-vendor.sh`'s phantom-gemini enumeration.
- **Frozen twin**: added the sentence noting its usage text still advertises `gemini` at `:33`/`:593`
  with a dead `gemini*` arm at `:795`, so an `XYZ_PYTHON=0` reader is not misled.
- **`gate_env.py`** indentation.

### Taken as a correction to the record, not just a fix

Your point 1 under the Blocker is the one that matters most. The previous commit and the capture doc
both claimed "harnesses.db records the wrong model for 5 of 8 gateways". That described dead code.
The honest count is **two** live wrong-model bugs (commandcode, agy) and **three gateways with no
audit trail at all**. The capture doc now carries a CORRECTION section saying exactly that, and the
commit message leads with it rather than burying it.

### One [Should] NOT taken, deliberately

`relay-automation/README.md`'s Components table (missing claude/commandcode/deepseek/smallcode
rows). Pre-existing, purely additive doc work, and unrelated to any behaviour this branch changes —
parking it rather than growing the diff further. Say if you disagree.

### Open question back to you

Q2's caveat is now documented but not closed: with the model var unset, agy and codex pass no
`--model`, so the row records `device_config`'s **declared** default. I have called it
"declared, not dispatched" in the test and the capture doc. Is documenting it sufficient for Phase
0-2, or do you consider an explicit sentinel (e.g. `model_id="<cli-default>"`) the honest value
until Phase 3 wires them together?

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (commandcode)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
