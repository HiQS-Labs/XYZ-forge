# GH-1314 — attempt 02 corrected manual calibration protocol (review candidate)

Tracking: https://github.com/HiQS-Labs/XYZ-forge/issues/1314.
Historical behavioral requirement: https://github.com/HiQS-Labs/XYZ-forge/issues/1284.
Execution is held until the parent approves this protocol and the exact helper digest.
Attempt 01 remains immutable and inconclusive (0/8 candidate invocations).
Attempt 02 is a distinct new run; no candidate invocation is authorized before parent review.

## Identities and scope

- Bad: `b78df4b93049498b19dd47fe6a90d006f9c42700`.
- Good: `47deab48b8c749d699c6b6c77c38dfdaa5682025` (bad's direct child).
- Bad/good harness blobs: `38d183aa4ae12bb28f527b2c4f6e3cbf0b47989a` /
  `6db76a3b6bbd876755e8f719a97e2231868687a9`.
- Scenario blob: `77bb7f7ba7fea8603f41a510c3212ea4063dbd2c`.
- Manifest blob: `f7e3ca47ab66d1d7fcfde4b31728742b3153e95f`.
- Prompt blob: `8f2d9f6073cefdbdc8317c7d4635ca2b53e444d9`.

Only eight candidate invocations: each candidate gets status then init on fresh r1,
then the same sequence on fresh r2, reversing candidate order for r2. No tick,
packet, actor repair, model, campaign, production action, test or workflow.

## Setup and deadline

The supervisor records setup-start epoch and sets deadline to that value plus 600
seconds **before creating either candidate clone**. Allocate one exclusively owned
candidate directory using tempfile.mkdtemp under the task workspace, with basename
`gh1284-calibration.<random>`, and a separate sibling setup scratch directory named
`gh1314-attempt02-setup.<random>`. Resolve physical absolute paths; no existing paths
are reused. Setup HOME/TMPDIR live in setup scratch only. Create candidate home/, tmp/
and evidence/ only AFTER both clones/checkouts complete; do not erase or allowlist files.

For each candidate, use explicit argv arrays:

1. `/Library/Developer/CommandLineTools/usr/bin/git -c core.hooksPath=/dev/null clone --no-hardlinks --no-checkout
   <READ_ONLY_SOURCE> <root>/<candidate>`.
2. `/Library/Developer/CommandLineTools/usr/bin/git -c core.hooksPath=/dev/null -C <root>/<candidate> checkout
   --detach <pinned-sha>`.

The frozen attempt-02 launcher is invoked using the approved resolved Python directly,
not /usr/bin/python3. It verifies its own, helper and protocol SHA-256 identities from
parent-approved config before setup, records explicit approval metadata in that config,
and retains all setup output plus direct Git/Python binary hashes. The helper uses
/Library/Developer/CommandLineTools/usr/bin/git for identity checks too, avoiding the
/usr/bin/git xcrun shim inside candidate TMPDIR. Its receipt records Git identity and
Python/SQLite versions. Setup and helper failure stop this attempt, with no retry.

Each setup command has a supervisor-enforced 120-second timeout, subject to the
same absolute deadline. Stop on any failure; no retry, source substitution or
network fetch. Existing source checkout is read only. Use standalone full clones,
not linked worktrees. No shared gate is launched. No host-wide idleness claim.

The launcher copies this approved protocol and exact approved helper to
evidence/PROTOCOL.md and evidence/helper.txt after setup. Its helper-config.json
is kept in setup scratch outside root. The helper configuration fields are:

```json
{
  "root": "<absolute uniquely owned calibration root>",
  "python": "<absolute resolved Python 3 executable>",
  "deadline_epoch": "<numeric setup-start + 600, not a string in actual JSON>",
  "helper_sha256": "<approved helper digest>",
  "protocol_sha256": "<approved protocol digest>"
}
```

Invoke exactly `<direct-python> -B <approved-launcher-file> <launcher-config.json>`.
Launcher config contains absolute workspace/source/helper/protocol/Python paths, all
three approved artifact hashes and parent approval metadata. The launcher creates
the helper configuration and invokes `<direct-python> -B <helper> <helper-config>`.
The helper
requires its interpreter to match configured Python, records Python/SQLite
versions, validates identities and requires a clean candidate. No installation.

## Candidate commands

For candidate C and N=1/2, from C:

```text
<python> -B utils/py/harness.py factory-primitive
  --run-root <C>/temp/factory-primitive/calibration-rN status --instance C

<python> -B utils/py/harness.py factory-primitive
  --run-root <C>/temp/factory-primitive/calibration-rN init --instance C
  --scenario <C>/utils/py/factory_primitive/scenarios/soak-v1.jsonl
  --manifest <C>/utils/py/factory_primitive/scenarios/soak-v1.manifest.json
  --daily-cap 1 --max-call-cost 0
```

Use argv arrays and the helper's minimal environment; no inherited credentials.
Each command is capped at 30 seconds and remaining total budget. No candidate
command is a retry. r2 starts only with more than 240 seconds remaining; otherwise
retain an inconclusive run. Zero provider/model spending follows from no model
invocation, not reliance on the max-call-cost configuration.

## Frozen expected matrix

| Step | Exit/output | Filesystem |
|---|---|---|
| Bad status | 0; nonempty JSON, pending=0, ticks={}, last_receipt=null; stderr empty | state.db exists |
| Bad init | 2; stdout empty; exact stderr `factory-primitive: instance already initialized; use a new run root` plus newline | candidate unchanged by refusal; no init success files |
| Good status | 2; stdout empty; exact stderr `factory-primitive: instance not initialized; run init first` plus newline | candidate unchanged; run root absent |
| Good init | 0; nonempty JSON, status=initialized, exact instance path; stderr empty | database, canary, config and nonempty init/ok telemetry |

Canary bytes are `do-not-modify\n`. Config must contain scenario/prompt SHA-256,
explicit scenario/manifest paths and caps 1/0. Manifest SHA-256 is verified externally
from the frozen baseline, not claimed as a config field.

## Evidence, stop conditions and ownership

The helper inventories complete candidate trees (including .git), owned HOME/TMPDIR
and evidence paths with lstat, types, permissions, symlink targets, lengths and
hashes. Allowed candidate changes are only declared runtime directories and regular
state.db/SQLite sidecars/canary/config/events files. Telemetry must be a real
directory; runtime symlinks, special files and type changes fail. HOME/TMPDIR changes
are unexpected. Only the supervisor creates evidence files; prior evidence may not
change. Raw stdout/stderr (including valid empty streams), command metadata and
before/after snapshots are retained outside candidates.

Stop on timeout, identity/fixture drift, unexpected changes, missing/empty required
observations, malformed JSON, mismatched controls or uncertain termination. Capture
an inconclusive outcome, do not retry or weaken expectations. Track only directly
launched children and their groups; terminate only those groups. No process inventory
retry/bypass. A child creating a new session is not proven contained by process groups.

Use observed epoch and monotonic deadlines, subprocess timeouts and an alarm reserving
three seconds for shutdown. Check time after inventory reads, classification and
immediately before/after success publication. Blocking filesystem I/O can delay
observation of deadlines; these are supervised execution controls, not a hard OS
sandbox. An inconclusive record takes precedence over any partial outcome record.
Same-user separation/hashes detect observed tampering but cannot prevent it. Inventory
claims cover declared candidate/environment/evidence paths, not absence of writes
elsewhere on the host. Separate setup scratch is retained as setup provenance, not
subject to the candidate empty-directory contract. A launcher inconclusive result
also invalidates helper success, even if a partial outcome file exists.

Keep clones and runtime artifacts for parent review. No recursive deletion. Parent
checks raw captures, eight command identities, reversed fresh-root replay, source and
fixture hashes, inventories and actual duration. Missing evidence is inconclusive.
Only that independent review accepts the calibration; candidate output cannot award
itself a passing receipt. Retain helper text as evidence, not a reusable executable.

## Publication

Use existing isolated docs branch into development with normal installed/checked
hooks. Payload: issue pointer, canonical queue bookkeeping, this protocol/helper text,
sanitized raw evidence, provenance, hash manifest and medium-level proposal/summary.
No new CI cases, assertions, parametrizations, suites or gate machinery. Existing
focused documentation checks only, selected against the final diff. No routine full
development suite. If a push would require one, hold unless the parent explicitly
releases the documented WIP draft exception with focused evidence and skipped-gate
disclosure; merge readiness remains outstanding. No merge or deployment.
