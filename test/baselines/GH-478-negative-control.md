# GH-478 negative controls — witnessed mutation results

Every guard/sweep behavior this effort relies on has a bounded mutation that, when
applied, makes `test/gh478-runaway-guard.sh` go red. The suite re-witnesses each
mutation at run time by sed-mutating a COPY (never the tracked source) and asserting
the mutated copy fails its control case; this file records the witnessed results and
how to reproduce them.

| Date | Mutation (on a copy) | Expected red | Witnessed result |
|---|---|---|---|
| 2026-09-06 | `runaway-guard.sh`: delegated `--timeout "$cap_s"` → `--timeout 999999` (timeout disabled) | The 1s-cap case can no longer stop a hung child; the case hangs and is killed by the case's independent emergency cap (`sleep 8` + KILL) instead of passing | RED witnessed — mutant subshell killed at rc 137 ("went red or was emergency-capped — never silently green"); suite case 10 asserts this on every run |
| 2026-09-06 | `ate_runaway_sweep.py`: `MATCH_BASENAME_EXACT = True` → `False` (matcher broadened to substring) | `my_adaptive_ate.py` (near-match) becomes eligible | RED witnessed — dry run lists the near-match candidate; suite case 16 asserts this on every run |
| 2026-09-06 | `ate_runaway_sweep.py`: `REQUIRE_ARGV_AFTER_SCRIPT = False` → `True` (matcher narrowed) | The bare `adaptive_ate.py` invocation (no following args) drops out of the candidate set | RED witnessed — dry run stops listing the signature fixture; suite case 16 asserts this on every run |

Reproduce any row by running `bash test/gh478-runaway-guard.sh` — the mutation cases
are part of the suite (cases 10 and 16); a green suite with the mutation lines removed
from the source would itself be the failure signal.

Scope note (plan rev 3, round 2 finding 6): the `--kill` path's positive proof is a
suite case, not a mutation — cooperative target TERM-stopped, TERM-resistant target
escalated to SIGKILL after the configured grace, young targets excluded by the age
gate, dry run byte-for-byte signal-free, all under `--limit-pids` containment so the
suite can never signal anything beyond its own fixtures.
