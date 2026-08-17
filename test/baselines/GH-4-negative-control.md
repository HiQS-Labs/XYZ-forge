# GH-4 negative control — ungated-clone warning in `validate.sh`

Recorded 2026-08-17. Per the standing rule: a check never observed failing is not evidence.

## What had to be falsifiable

`validate.sh` now surfaces an ungated clone in-band, on the documented first-run path, without
blocking local validation (a prior attempt at this fix — a driven marathon, escalated without
landing — put a hard `exit` before argument parsing, which broke the documented "an evaluator can
skip installation, it only affects pushing" promise and failed local runs like `--print-mode` in
an otherwise-valid ungated clone; codex's review of that attempt caught it). This control
demonstrates the check DOES fire when ungated, and DOES NOT fire (silent) when gated — both
directions, both non-fatal.

## UNGATED — the warning is OBSERVED firing, non-fatally

```
$ bash githooks/install.sh --uninstall
githooks: uninstalled — removed .../.git/hooks/pre-push.
githooks: this clone no longer gates pushes.

$ bash validate.sh --print-mode
githooks: NOT INSTALLED in this clone.
  .../.git/hooks/pre-push does not exist.
  This clone will push WITHOUT running the gate. Fix: bash githooks/install.sh
validate.sh: continuing WITHOUT the push gate installed — this run is unaffected, but a future push from this clone will not be verified.
validate.sh: PARALLEL mode 8-wide — auto-detected 10 cores
  NOT promotion evidence: the qualifying gate is ci-local.sh's sequential run (GH-509).
```

**Exit status: 0.** Local validation (`--print-mode`, and every other mode) runs to completion
exactly as it would gated — the warning is informational, never a refusal, honoring the documented
"only pushing is affected" contract while making the ungated state loud instead of invisible.

## GATED — no warning, silent

```
$ bash githooks/install.sh
githooks: installed — .../.git/hooks/pre-push
  ...

$ bash validate.sh --print-mode
validate.sh: PARALLEL mode 8-wide — auto-detected 10 cores
  NOT promotion evidence: the qualifying gate is ci-local.sh's sequential run (GH-509).
```

No ungated-clone warning line — the check is silent when the clone is properly wired.

## Design note — the deviation from the phase brief's artifact boundary

The Ballast wave-1 brief scoped lane #4 to `README.md` + `githooks/install.sh` only, explicitly
excluding `validate.sh` to avoid a merge conflict with lane #10 (both would have touched
`validate.sh` if driven concurrently through the harness). #10 was cut from Ballast the same day
this fix landed (see `RELEASES.md`, `PROJECT/2-WORKING/GH-10-REQUIRE-FIXTURE-ADOPTION.md`), so
that conflict no longer exists — this fix was authored directly by the orchestrator with full
context, not by an automated builder crossing an unapproved boundary, and is recorded here rather
than silently implemented.
