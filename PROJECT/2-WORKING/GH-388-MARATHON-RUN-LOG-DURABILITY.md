---
gh_issue: 388
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/388
title: "GH-388 — marathon.sh persists no run log, and per-phase transcripts are written only on completion"
status: "Intake (2-WORKING) — captured 2026-08-06 for release 0.2.0 Litmus, preflight READY, awaiting operator go."
created: 2026-08-06
updated: 2026-08-06
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
| Captured 2026-08-06 as a lane of release 0.2.0 Litmus. Acceptance criteria authored on the issue (it had none) and revised after an adversarial codex+agy review, which found a **false premise** in one criterion and a loophole in another. | Operator go. Then Phase 1 (a chain run log the harness owns, and a partial transcript on failure) and Phase 2 (the durable-root rule and the kill-mid-run regression). |

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
