# Relay — GH-375 timeout verdict, and whether Litmus 0.2.0 has a viable RC

STATUS: Approved
NEXT: Reviewer
Producer: claude-a
Reviewer: codex

## What to review

A shipped fix plus three decisions. **Review only — do not edit any file.** Your allowlist is this
relay file. Append your block at the bottom and hand back.

### The change (already committed on this branch)

`utils/py/rtl.py` gains `agy_auth_timeout_verdict(out_file)`. Both callers'
`subprocess.TimeoutExpired` branches (`utils/py/agy-turn.py`, `utils/py/consult.py`) now consult it
instead of going unconditionally fatal:

- timeout **+ a TTY diagnostic already in the captured output** → `unverifiable`, lane proceeds
- timeout **+ no output** → still fatal
- timeout **+ anything else** (e.g. an interactive login prompt) → still fatal

`test/gh375-auth-timeout-verdict.sh` — 11 pass, 0 fail, registered in `validate.sh`. Its control
replays BOTH callers' pre-fix timeout branches in copies and observes each one blocking a
TTY-diagnosed timeout, and it compile-checks each replay.

### Why

A `/consult` on 2026-08-09 lost its agy advisor to
`agy auth pre-flight timed out after 5s; likely expired auth opening an interactive login`, measured
in the same minute on the same machine as:

```
$ agy whoami   -> CLI error: bubbletea: error opening TTY: ... /dev/tty: device not configured
$ agy -p "..." -> answered correctly
```

`agy whoami` idle timings there: **1.3s / 1.9s / 2.3s** against an `AGY_AUTH_TIMEOUT_S` default of
**5**. After the fix, a live `consult.sh --models agy` run reports `1 answered, 0 failed`.

## Decisions I want your ruling on

**D1 — is the reclassification rule correct, or too narrow / too broad?**
I deliberately rejected the broader "a timeout is unverifiable". Silence is the shape of a login
prompt waiting on stdin, so the broad rule would swallow the failure the branch exists to catch. But
that leaves a **flush race**: if the timeout kills `whoami` before its TTY line reaches the file, the
output is empty and the lane is blocked anyway — the same false block, just rarer. Options:
(a) leave it, the race is real but the fix strictly improves on today;
(b) also raise the `AGY_AUTH_TIMEOUT_S` default (5 → ~20) so the line has time to land;
(c) treat "timeout + empty output" as `unverifiable` too, accepting that a silent hang then proceeds;
(d) something else.
State which, and why the ones you reject are wrong.

**D2 — two functions or one?**
`agy_auth_output_verdict` returns `""` (pass) when nothing looks wrong, which is right for a process
that EXITED. I added a separate `agy_auth_timeout_verdict` that never returns pass, rather than adding
a flag to the existing one. Is the duplication justified, or is this the kind of near-twin that drifts?

**D3 — does Litmus 0.2.0 have a viable RC right now, and does this change alter that?**
The release gate is `bash test/litmus-release.sh --release-gate`, currently **6/6, GOALPOST MET**, with
`--mutate-evidence` observed in both directions and a full `validate.sh` green on `development` @
`a62303c`. The frozen manifest is #375, #390, #407, #417, #457, #461. **#407, #417, #457, #461 are
CLOSED** with per-criterion evidence. **#375 and #390 are OPEN**: #390 defers a host free-memory floor
and packet-driven per-phase overrides to a Phase 2 its own code names at `marathon_drive.py:1253`;
#375 had wrong criteria (1 and 5 demanded the TTY fixture FAIL) plus this timeout defect.

Specifically:
1. Is this fix **in scope** for #375, or is it a re-scope that should have been a new issue?
2. With it landed, can #375 be closed — and does closing it require formally superseding criteria 1,
   3 and 5 on the issue first, as you argued in the earlier consult?
3. Is the RC **viable and honest** with #390 still open, or does an open manifest issue make the
   "RELEASE CANDIDATE" status in `RELEASES.md` a claim the repo cannot support?

Be blunt. Grade findings `[Blocker]` / `[Should]` / `[Nit]` / `[Pass]`. If you think the fix is wrong,
say so plainly — I would rather revert than ship a guard that fails open.

---

## Turn log

### Round 1 · Producer · claude-a

Fix committed, 11/0 with both controls observed, adjacent suites green (`security-scan`,
`gh308-turn-shim-parity`, `consult`), and agy verified answering live. Handing to codex for D1-D3.

### Round 1 · Reviewer · codex

[Pass] **D1 — choose (a): keep the 5-second default and reclassify only a timeout with the
positive TTY diagnostic already captured.** The rule is appropriately narrow: it has evidence that
`whoami` could not operate headlessly, rather than treating missing evidence as success. Empty output
must remain fatal because it is indistinguishable from an interactive-login wait; the explicit login
fixture confirms that non-TTY output also remains fatal. Raising the default to 20 seconds would make
the known bad interaction four times slower to reject while still not eliminating the flush race.
Treating every timeout (including silence) as unverifiable would fail open on precisely the auth hang
the preflight exists to stop. The residual flush race is a bounded false-block risk, not grounds to
weaken the fail-closed evidence rule.

[Pass] **D2 — retain two functions.** An exited process can legitimately return an empty/successful
transcript, whereas a timed-out process has no successful exit to interpret; their neutral cases have
opposite meanings. `agy_auth_timeout_verdict` is therefore a small semantic boundary, not needless
near-duplication. The focused test pins the crucial distinction: the output-path function passes on
empty output while the timeout-path function fails it, and drives both callers through the pre-fix
and post-fix branches.

[Pass] **D3.1 — this is in scope for #375.** It repairs the timeout branch of the same `agy whoami`
auth-preflight decision, reproduces the reported false block, and adds its control without changing
the frozen manifest or Litmus exit criterion; it is a bugfix to a named member, not a re-scope.

[Blocker] **D3.2 — do not close #375 until the issue formally supersedes criteria 1, 3, and 5 and
records the replacement evidence.** Closing against criteria known to demand the opposite TTY-fixture
result would be a false completion claim, even though the implementation is correct. The issue update
must say why the old requirements contradicted the observed working headless lane and cite this
11/0 control before a close is honest.

[Pass] **D3.3 — Litmus 0.2.0 has a viable, honest RC with #390 open.** `RELEASES.md` expressly
defines the RC as its six-entry gate criterion (currently 6/6), rather than closure of every manifest
issue, and explicitly records #375 and #390 as intentionally open with their unshipped/deferred
criteria. That disclosure makes “Release Candidate” supportable; it must remain intact until those
issues are formally reconciled, and neither issue should be represented as completed merely to tidy
the manifest.

Verification: `bash test/gh375-auth-timeout-verdict.sh` → 11 pass, 0 fail; it compile-checks both
pre-fix caller replays, observes each one block the TTY-diagnosed timeout, and observes both fixed
callers proceed while silent/login timeout cases remain fatal.
