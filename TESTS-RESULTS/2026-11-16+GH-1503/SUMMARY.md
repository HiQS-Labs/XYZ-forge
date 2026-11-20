# GH-1503 verification receipts (2026-11-16)

Checks for the branch `fix/XYZ-forge-approved-over-fail-2026-11-16`. No issue number exists yet, so the
folder uses a slug. No suite or registry entry was added (GH-831); three cases were added to the existing
`test/gh505-relay-attest.sh`. Base: `14329f38b` (`origin/development`). Paths in logs are redacted to
`<clones>`, `<scratch>` and `<home>`. Run by Claude Code in a disposable full clone.

| Check | Command | Result |
|---|---|---|
| **Red before, D4** (reviewer block ends `VERDICT: FAIL`, sets `STATUS: Approved`, closes the token) | the edited `test/gh505-relay-attest.sh` with the six source files at base | **rc 1**: `FAIL: D4: rc=0 reason=` (the base driver attests the approval). `red-before-D4-gh505-relay-attest.log` |
| **Red before, D6** (reviewer writes `**STATUS:** Approved` with `VERDICT: PASS`) | same suite at base with the D4/D5 cases removed from a temporary copy, because the suite stops at its first failure | **rc 1**: `FAIL: D6: rc=4 reason=token-state` (the base driver reads no status; the wrapper had closed the token). `red-before-D6-gh505-relay-attest.log` |
| Green after | `bash test/gh505-relay-attest.sh` | rc 0; D4 refused `approved-over-fail` with no record, D5 (`VERDICT: PASS`) attested, D6 attested and the Python and Bash readers both read `Approved` |
| Existing focused suites, Python 3.11.13 first on PATH, one at a time | `for s in gh505-relay-attest gh308-frozen-twin-guard gh306-registry-bidirectional relay-pkg-freshness relay-review-once relay-escalation-not-stall gh115-round-cap gh204-sed-portability gh372-escalation-log-tail gh371-interrupt-snapshot gh384-crash-recovery gh438-removal-is-progress lane-attempt-cap gh509-gate-evidence archive-telemetry gh280-jog-marathon-adapter jog-queue gh681-reviewer-probe-rules marathon-drive; do bash test/$s.sh; done` | all 19 rc 0 (`focused-results.txt`, `focused-*.log`) |
| Test merge with PR 1467 (`fd5475446`) in a throwaway detached worktree | `git merge --no-commit --no-ff fd5475446` | `relay_drive.py`, `relay_attest.py`, `marathon_drive.py` merge automatically and `relay_drive.py` parses; only `CHANGELOG.md` conflicts |

Notes:
- An earlier run of 17 of these suites used the host default Python 3.9.12 (`py39-first-run-results.txt`).
  Two failed there for reasons outside the change under test: `gh280-jog-marathon-adapter` stops in
  `utils/py/swarm_preflight.py:29` (`str | None` needs Python 3.10; that file is not touched here), and
  `gh204-sed-portability` required the literal `re.subn(` in `relay_drive.py`, which an intermediate
  version of this change had replaced. The final change keeps `re.subn(`.
- `gh204` pins the escalation write's form, so that write keeps `re.subn` with the tolerant pattern inline.

Not run: the full `validate.sh`; the 87 other suites that mention a changed file; a live model turn;
a marathon or jog run against a real target. The consult-verify path was not exercised.
