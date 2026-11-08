# Plan draft: #1168 scheduler: shared local scheduler (launchd) for XYZ jobs — first job #1184, then daily weekly-prepare + Friday start-marathon hookup (child of #1022)

> draft; preflight and independent plan QA outstanding

- Request: `gh-1168-2cba856d87cc` (tick `slot_077`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: 2cba856d87cc647ab75e25825da3be24aef4aa2c84ad951f96adba092bd45ea2 (updated 2026-10-23T05:35:20Z)
- Dependencies: none

## Scope

_Source: issue#1168:L8 (Scope)_

- A daily trigger (launchd or the repo's scheduled-task mechanism) that runs `weekly-prepare --apply` against a fresh full clone, HELD / dispatch false, and records its receipt.
- A `start-marathon` entry point that accepts an `auto-<date>` predecessor root as its intake source, so Friday's computation starts from the accumulated ledger rather than re-discovering.
- Explicit operator approval remains the gate for any fire; this issue adds no dispatch authority.

_Source: codex-authored (codex-authored)_

Verify PR #1024 and the current scheduler and weekly intake mechanisms, then plan one shared local scheduler with the #1184 read-only report as its first job.

_Source: codex-authored (codex-authored)_

Plan daily held weekly preparation and a start-marathon entry point that consumes the accumulated auto-date predecessor root, without granting dispatch authority.

_Source: codex-authored (codex-authored)_

Keep existing launchd jobs and remote or hosted wake outside scope, and add no new tests.

## Acceptance criteria

_Source: codex-authored (codex-authored)_

Each Mac has one launchd user agent running a named job list with per-job scheduling, checkout, held or dry-run setting, kill switch, and single-instance lock.

_Source: codex-authored (codex-authored)_

Each run records device, start and end times, and exit code under .tick/scheduler/, with the last successful run visible to doctor.

_Source: codex-authored (codex-authored)_

Missed runs are recorded as skipped, with no duplicate catch-up or automatic retry; waking from sleep is treated like a crash.

_Source: codex-authored (codex-authored)_

Installing the scheduler enables no jobs; each job requires explicit operator approval before being switched on.

_Source: codex-authored (codex-authored)_

Daily weekly-prepare runs against a fresh full clone with HELD and dispatch false, and Friday planning can use the accumulated ledger without rediscovery.

_Source: codex-authored (codex-authored)_

Any fire remains subject to explicit operator approval.

## Open questions

_Source: codex-authored (codex-authored)_

Has PR #1024 landed, and what current interfaces and receipts does it provide?

_Source: codex-authored (codex-authored)_

How should skipped runs and interrupted runs be detected and recorded across sleep, logout, and login?

_Source: codex-authored (codex-authored)_

What existing verification covers the scheduler and its jobs without adding tests?

## Write set

- `utils/hq/hourly-global-scan.sh` (issue#1168:L37)

## Unresolved file names

- none

## Contract probes

- none
