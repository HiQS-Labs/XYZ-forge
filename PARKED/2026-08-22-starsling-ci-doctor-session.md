# Parked — StarSling / ci-doctor session, 2026-08-22

Items deliberately NOT continued in this session, filed here so they stop resurfacing in chat.
Each carries enough context to pick up cold; real homes are the linked issues/files.

- **stealth/ox-alpha off-lane edit on R3.** With `AIDER_FLAGS=--edit-format diff` applied (fixing
  the GH-118 quirk), the model's next attempt at the ci-doctor QA relay (round 3) tried to write
  outside its `ALLOW_PATHS=""` reviewer scope. `relay-turn-lib.sh` containment correctly discarded
  it and failed the turn (exit 6) — nothing was lost, no root-cause investigation was done beyond
  that. Relay: `relay-system/2026-08-22/ci-doctor-qa-gh-161-pr-162.md`. If this route gets picked
  up again, start by reading that turn's `AIDER_LOG` (`aider-turn-r3-*.log` under `$TMPDIR` at the
  time, likely rotated/gone by now) to see what it tried to write and why.

- **The ci-doctor QA relay itself is not closed (not Approved).** Two independent delivery
  failures (timeout, then containment violation) across three turns, against one genuinely strong
  review (R2, real content — see `HARNESS-MODELS-REGISTRY.md`'s 2026-08-22 stealth/ox-alpha entry).
  PR #162's actual code fixes were verified independently (`bash -n`, `shellcheck -S error`,
  targeted smoke tests matching the reviewer's exact repro cases) and do not depend on this relay
  closing. If a clean automated Approved verdict is wanted later, re-drive
  `relay-automation/relay-drive.sh --review-once` against the same relay file with a fresh
  `--artifact-file` seed.

- **`ci-doctor/benchmark-runners.sh` not yet tested against a real live `gh workflow run`
  dispatch end-to-end.** Verified by code inspection + targeted smoke tests only (per the R2
  Producer disposition in the relay file). A real dry-run against a disposable branch would close
  this gap.

- **StarSling side-by-side speed comparison used the default-tier and 8-vCPU tier only.** Larger
  tiers (`-16/-32/-64`) untested; `-8` showed negligible gain over the default (workload is
  sequential/I/O-bound, not CPU-bound — see GH-152), so this is low-priority.

- **StarSling's paid "AI optimization PR" tier remains unconfirmed/untested** on this account —
  only the free `ci-speedup`/`ci-score`/`ci-secure` skills were evaluated (GH-152). `ci-score` and
  `ci-secure` specifically were never run (only `ci-speedup`).
