# GH-1637 manual check receipts (2026-11-26)

Recorded manual checks for the consult tie-break at the factory round cap. These are evidence, not suites or
registry entries (AGENTS.md *No new tests*, GH-831).

- Provenance: run from a disposable full clone (`<task clone>-verify`) cut from the task branch, on macOS, with
  `$HOME/.cache/xyz-forge-test-venv/bin` first on `PATH`. Throwaway repos only; no network; stub codex/agy binaries
  answer the REAL `relay-automation/consult.sh` (`consult.py`), which runs them in its isolation worktree.
- `manual_check.sh` / `manual_check.log`: the REAL `utils/py/relay_drive.py` with stub builder/reviewer turn-takers,
  36 checks. Adjudicated terminal and its attestation record; the jog merge boundary refusing it; REAL at cap 3
  (reviewer next) and cap 2 (builder next) with the builder dispatched before any reviewer approval; a second cap
  escalating after one repair; SAFETY, one-advisor-failed, duplicate-verdict and quoted-token holds; a red focused
  driver gate, a refused token close and a receipt-write failure after `done`; a reviewer turn forging
  `Consult-Adjudicated`; a transcript-only candidate; the default-off run (`cap-stalled`, zero consults); a dirty
  target showing the advisors read the pinned candidate and not the working tree.
- `manual_check_marathon.sh` / `manual_check_marathon.log`: the REAL `marathon_drive.py` -> `relay_drive.py` ->
  `consult.sh`, 11 checks. Default cap 9 (driver and `marathon.sh`); full path to success through the attestation and
  pre-advance gate with the result receipt reading `relay_status: Consult-Adjudicated`; the lane PR notes text; the
  cap-1 Marathon fixture still `cap-stalled`; and the existing acceptance recheck stopping an unfixed adjudicated
  candidate (`acceptance-probes-unmet`, exit 5) while a fixed one advances.
- Added after final-QA round 1 (each is a named control in the logs): withdrawn / fenced / malformed advisor verdicts hold;
  the repair reviewer recording progress still ends the lane after exactly the two repair turns; REAL at cap 9; a refused
  handoff release rolls the driver's claim back; Approved/Closed/Consult-Adjudicated records through the jog merge
  boundary; a red pre-advance gate after an adjudicated terminal (`pre-advance-failed`, no approved outcome); and a mixed
  multi-phase `--closeout-pr` summary keeping the 2/2 count and labelling the adjudicated phase.
- Added after final-QA round 2: fence-aware verdict parsing (unclosed tilde fence, a four-backtick fence closed by three, both hold); the approval after a REAL repair attests a CHANGED head that descends from the head the consult judged; a refused reviewer claim with the builder holding the handoff (cap 2) restores the original handoff.
- Not exercised here: `marathon.sh --retry` recovery after a spent token (existing GH-116 behavior, unchanged).
- `provenance.jsonl`: revision-bound record of the runs (implementation commit, script and log digests).
