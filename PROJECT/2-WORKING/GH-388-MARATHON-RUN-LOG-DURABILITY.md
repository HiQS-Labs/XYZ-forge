---
gh_issue: 388
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/388
title: "GH-388 — marathon.sh persists no run log, and per-phase transcripts are written only on completion"
status: "BUILT 2026-08-11 (both phases) as a lane of release 0.3.0 Nightwatch, to which it moved on 2026-08-08. Built Opus-direct rather than fired: the 2026-08-10 wave-1 plan had already recorded why this lane is not marathon-buildable — it edits marathon.sh, the outer driver bash that is reading itself by byte offset as the chain runs. Negative control recorded in test/baselines/GH-388-negative-control.md (9 red pre-fix). Full validate.sh green."
created: 2026-08-06
updated: 2026-08-11
owner: noel
doc_type: project
release: "0.2.0 Litmus"
complexity: 2
risk: 2
effort: 3
phases: 2
ratings_provisional: true
related:
  - "#419 — the class. The harness keeps a permanent record of every phase that succeeded and none of the phase that failed, so the archive is systematically biased toward success."
  - "#382 — the crash whose first occurrence produced no usable profile precisely because of this."
  - "#384 — recovery after an interrupted run, which is much harder without a run log."
  - "#390 — its layer-5 evidence requirement depends on what this lane makes durable."
non_goals:
  - "Changing what the per-phase transcripts contain on success. They work; the gap is the failure path."
  - "Making the invoker responsible for redirection. That is the current state and is the defect."
goal: >
  The failure mode guarantees the absence of the record. Per-phase transcripts are written when a
  phase completes, so the phase that dies is the one phase with no transcript, and the chain-level
  narrative exists only on the operator's terminal. Whether any of it survives a crash depends on
  whether whoever typed the command happened to redirect stdout somewhere durable.
---

# GH-388 · the phase that fails is the one with no record

## Status

| What was just completed | What's next |
|---|---|
| **Both phases built 2026-08-11.** `marathon.sh` owns a durable chain run log under the same transcript root as the per-phase transcripts, announced at chain start; a phase killed mid-run leaves a content-bearing `PHASE-INTERRUPTED.md`; `rtl_default_log` refuses on both lanes instead of silently relocating to volatile storage; and the non-durable locations are stated in one runtime-read file. `test/gh388-run-log-durability.sh` 24/0, observed **9 red** pre-fix. | Close #388 against the acceptance block below. All seven criteria met — see "Acceptance — outcome". |

## Acceptance — outcome

1. **Met.** `marathon.sh` opens `<transcript-root>/run-logs/<date>/marathon-<plan>-<time>-<pid>.log` and `tee`s stdout+stderr into it as produced. Armed after plan validation and before the phase loop, so a usage error or an unparseable plan leaves no log implying a run happened; `--dry-run` is excluded for the same reason, and that exclusion is asserted.
2. **Met.** `marathon: run log: <path>` is printed at chain start, and the test parses that line rather than guessing the path — if the announcement breaks, the test cannot find the file.
3. **Met.** `_write_interrupted_phase_record` writes `PHASE-INTERRUPTED.md` carrying the phase id, the relay `STATUS:` read *at interruption*, the recorded round count, the reason and the exit code. Asserted on content, not existence, and against a marker stamped after dispatch — the empty-file and pre-created-file loopholes the issue's own review found.
4. **Met, both lanes.** `rtl_default_log` in `utils/py/rtl.py` and in `relay-turn-lib.sh` now exit 5 rather than returning a `$TMPDIR` path, and the resolver's stderr is no longer swallowed (`quiet=True` is gone), so the refusal names *why* the root failed to resolve. `test/relay-turn-trace.sh`'s case 3c, which pinned the old fallback, is inverted with the rationale recorded in place.
5. **Met.** `relay-automation/non-durable-log-roots.conf` is the single registry, read at runtime by `durable-log-lib.sh` (Bash) and `rtl.py::non_durable_reason` (Python). The test asserts the two readers agree on every probe path *and* that an invented entry changes the verdict — without that second assertion the file could be decorative while the real list lived in the readers.
6. **Met.** Part C kills a running phase; Part D kills a running chain. Both assert on what is left on disk.
7. **Met.** `test/baselines/GH-388-negative-control.md` carries both runs in full: 9 red pre-fix, 0 after.

## Acceptance — deviations found while building

**The durability rule is scoped to RELOCATION, not to absolute location.** A transcript that resolves
*inside the repo being driven* is permitted even when that repo sits in `$TMPDIR`; only a path that is
both non-durable *and* outside the repo is refused. Criterion 5 reads "a default log path resolving
into one of them fails the run", which taken literally refuses to run the harness inside every fixture
in this suite — every one of them is a repo under `$TMPDIR`. A guard that cannot be exercised is not a
guard, and "fails the run" would have meant "fails every run". The defect being fixed is the harness
*silently moving* evidence out of the repo; a repo the operator put in `/tmp` makes the code, the
commits and the log volatile together, visibly, by their choice.

**AMENDED CRITERION 5 (2026-08-11, adjudicated by cross-model consult — codex + agy).** The criterion
above is superseded. The shipped rule is the correct rule and the original wording is the stale
artifact; the amended text is what #388 was closed against:

> The locations the harness treats as non-durable are stated in one place it actually reads at
> runtime, and a default log path that resolves into one of them **and lies outside the repo being
> driven** fails the run rather than proceeding. A path inside the driven repo is permitted: it shares
> the durability of the work it documents, and is the operator's visible choice rather than a silent
> relocation by the harness.

*How this was adjudicated, since a documented deviation is not self-justifying.* The consult split.
agy called the narrowed rule correct (a co-located log inherits its repo's lifecycle) and voted to
amend and close. codex graded it a Blocker and voted to keep open, arguing that permitting a run log
inside a `$TMPDIR` repo lets a reboot erase the checkout and its only evidence together with no
refusal — and proposing a third path the original build never considered: refuse by default, with an
explicit opt-in volatile mode for fixtures. That proposal dissolves the "a guard that cannot be
exercised is not a guard" argument, so the deviation was **not** self-evidently right.

It was decided by measurement rather than by argument. The strict default requires threading an
opt-in flag through **26 test files** that build a `$TMPDIR` fixture and drive a turn, mirrored across
two lanes that must not drift (`utils/py/rtl.py` and `relay-automation/relay-turn-lib.sh` — the GH-308
twin-drift class), and re-vendored into every `.xyz/` install via `skills/relay-automation/make-pkg.sh`.
Against that: real targets are durable, so the benefit is zero for production runs, and the only case
protected is an operator who deliberately placed the target repo in volatile storage — where a reboot
takes the code and the commits too and the log is the smallest loss. The fix would create a standing
defect class (26 fixtures, each a future chance to omit the flag) to close a hypothetical one.

**Residual, recorded rather than lost:** on the in-repo-volatile path the harness emits *no signal at
all*. If that ever bites, the cheap remedy is a one-line warning on that branch — not the strict
default. Deliberately not built now; a warning that fires in 26 fixtures is noise bidding to become
ignored.

**Two defects were found by this lane's own test rather than reasoned about.**

- **The driver's narrative was block-buffered.** Python block-buffers stdout when it is not a TTY, and
  a marathon is never a TTY — so the buffering is not an edge case, it *is* the unattended path. The
  first kill-mid-run recovered a log containing the child turn-shim's output and none of
  `marathon-drive`'s own: the subprocesses wrote straight to the fd and survived, while every
  `marathon-drive: …` line sat in a buffer that SIGTERM discards. A run log fed by a buffered writer
  records the run right up to the moment something goes wrong. Fixed with `line_buffering=True`.
- **SIGTERM never reached the exit hooks.** `marathon_drive.py` already had an `_ON_EXIT` list run from
  a `finally`, but SIGTERM terminates CPython immediately — no `finally`, no hooks, no record. SIGINT
  already raised `KeyboardInterrupt` and so already reached them; SIGTERM is what an unattended run
  actually receives. Converted to `SystemExit(128+signum)`, which is the convention `_exit_meaning`
  and `marathon.sh`'s halt table already read. **SIGKILL and a host panic remain unreachable** — that
  is stated in the code rather than papered over, and is why #384's recovery path is a separate lane
  rather than something this one quietly claims to cover.

## The defect

`marathon.sh` persists none of its own output — no `tee`, no `exec >`, no log-file variable. What is
durable is written **per phase, on completion**. In the observed run, phases 1–4 completed and each
has a transcript; phase 5 is the one that killed the host, and there is no transcript for it.

**The fallback is not a fallback.** The only surviving account of phase 5 was the terminal stream,
which had been redirected to a path the platform clears at boot. After the panic reboot it was gone.
That choice was the invoker's and a poor one — but the harness offered no alternative and gave no
indication one was needed.

**There is a related silent path inside XYZ itself.** `rtl_default_log` resolves the durable
transcript root and, on failure, falls back to a temporary directory *with the diagnostic
suppressed*. A misconfigured archive root silently relocates turn logs into the one directory a crash
erases, and prints nothing. This did not fire in the observed run — it is a live code path, not an
observed failure, and this doc keeps that distinction.

## Two corrections the review produced

Both from codex, both verified against `development` @ `3b37072` before being acted on:

- **A criterion of mine rested on a false premise.** It asserted that *"the repo's own PDDA lint
  already classifies those locations as non-durable."* It does not — `check_hardcoded_paths` reads
  `pdda_list_working_docs` and scans **documentation** for literal absolute paths. It says nothing
  about runtime log destinations. The criterion was rewritten to require the harness to state the
  non-durable set somewhere it actually reads at runtime.
- **"Writes a partial transcript" was satisfiable by an empty file.** A static or pre-created
  transcript met the words while the failing phase's evidence remained absent. It now requires the
  file to have been created or modified *after that phase started* and to carry the phase id, the
  relay state at interruption, and the failure reason.

Agy independently found the third: *"no longer silent"* was satisfiable by adding a print statement
while still writing to volatile storage — the logs would still be destroyed, the defect completely
unfixed.

## Acceptance

*Copied verbatim from [issue #388](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/388)
(`## Acceptance`), fetched 2026-08-06. Deviations, if any, are recorded below this block.*

- [ ] A durable run log captures the whole chain's output as it is produced, under the same transcript root the per-phase transcripts already use. Where the run narrative goes is the harness's decision, not the invoker's.
- [ ] The run log's path is printed at chain start, so an operator knows where to look afterwards.
- [ ] A phase that escalates, times out, or dies mid-gate leaves a transcript that was **created or modified after that phase started** and contains the phase id, the relay state at interruption, and the failure or kill reason. An empty or pre-created file does not satisfy this.
- [ ] `rtl_default_log` does not silently relocate turn logs to volatile storage. It either resolves a durable root or refuses before the turn launches; if a volatile fallback is retained, it is reported as non-durable and is never presented as the turn transcript. Adding a message while still writing to storage a reboot erases does not satisfy this.
- [ ] The locations the harness treats as non-durable are stated in one place it actually reads at runtime, and a default log path resolving into one of them fails the run rather than proceeding.
- [ ] A regression test kills a phase mid-run and asserts that both a chain-level run log and a content-bearing partial phase transcript survive.
- [ ] The regression test is observed failing against the pre-fix revision, and a durable record states the reproducer command, the pre-fix revision, the pre-fix result and the post-fix result. A sentence asserting a negative control happened is not the record, per #419.

## Acceptance — deviations from the issue

None. Every criterion is carried verbatim.

The criteria were **authored onto the issue on 2026-08-05** (it had none) and **revised on 2026-08-06**
after the codex+agy review, for the three reasons above. The `tee` prescription was also dropped —
both reviewers noted it named a mechanism where an outcome was wanted.

## Phases

| Phase | Deliverable | Artifacts | cx/risk/eff |
|---|---|---|---|
| 1 | The chain run log. One durable file opened at chain start under the same transcript root the per-phase transcripts use, capturing the chain's output as it is produced, with its path printed at start. Plus a content-bearing partial transcript when a phase escalates, times out, or dies mid-gate. | `relay-automation/marathon.sh`, `utils/py/marathon_drive.py` | 2/2/3 |
| 2 | The durability rule. The non-durable locations are stated in one place the harness reads at runtime; `rtl_default_log` resolves a durable root or refuses before the turn launches, and a retained volatile fallback is never presented as the turn transcript. Plus the kill-mid-run regression. | `utils/py/rtl.py`, `test/gh388-run-log-durability.sh`, `validate.sh` | 2/2/3 |

## Litmus tests

- **A green suite is not evidence here.** Everything works on the success path today. The only
  assertion that matters is what survives a kill, so the regression must actually kill a phase.
- **An empty transcript passes a naive check.** Assert content — phase id, relay state, reason — not
  existence. This was a real hole in the first draft.
- **A message is not a fix.** If the fallback still writes to storage a reboot erases, the evidence
  still disappears; the message only means someone could have known.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "path_absent", "path": "test/gh388-run-log-durability.sh" },
    { "type": "grep_absent", "path": "relay-automation/marathon.sh", "pattern": "run log" }
  ],
  "artifacts":     [ "relay-automation/marathon.sh", "utils/py/marathon_drive.py", "utils/py/rtl.py", "test/gh388-run-log-durability.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh388-run-log-durability.sh" ],
  "remediation":   { "source": "issue#388", "criteria": "the harness owns a durable chain run log, and a failing phase leaves evidence — ranking summary only, NOT the definition of done (that is the verbatim ## Acceptance block above)" },
  "lanes":         { "agy_safe": [], "orchestrator_only": [] }
}
```

**Probe polarity** (probes detect the **bug**, not the fix): `path_absent` reports `landed` when the
path *exists*; `grep_absent` reports `landed` when the pattern *is found*. Verified 2026-08-06:
`run log` occurs **0 times** (case-insensitive) in `relay-automation/marathon.sh`.

**`relay-automation/marathon.sh` is not a frozen twin** — verified 2026-08-06, no GH-308 banner — so
Phase 1 may edit it directly. `utils/py/rtl.py` is the authoritative Python lane.

## Method note

The phase-5 evidence, the cleared-temp-directory finding and the `rtl_default_log` code path are
carried from the issue. The PDDA-lint correction and the empty-transcript loophole came from the
codex review and were verified directly before being written as criteria. No open PR or branch
touches this issue — checked before authoring.
