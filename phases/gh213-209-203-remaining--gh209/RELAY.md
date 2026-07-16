# Marathon Phase gh209
STATUS: Approved
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH209-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

## Phase: GH-209 — static audit that every test/marathon*.sh invocation scopes MARATHON_ROOT

Full context: [GH-209-MARATHON-ROOT-LEAK-AUDIT.md](../GH-209-MARATHON-ROOT-LEAK-AUDIT.md).
GitHub issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/209

### Important scope boundary — read this first

The GitHub issue asks for two things. You are building ONLY the second, mechanical one. Do **not**
attempt the first:

1. ~~Make `marathon.sh`'s PWD-based `MARATHON_ROOT` fallback refuse to resolve to "the wrong
   repo"~~ — **OUT OF SCOPE.** This conflicts with GH-206's own explicit goal (a vendored install
   must resolve `ROOT` from `$PWD` with ZERO required env vars), and there is no reliable code-level
   signal today that distinguishes a legitimate bare run from a stray background invocation. Do not
   edit `relay-automation/marathon.sh` or `relay-automation/marathon-drive.sh` for this phase.
2. **IN SCOPE:** add a static audit (a new test/check) proving every invocation of the real
   `marathon.sh`/`marathon-drive.sh` inside this repo's own test suite (`test/marathon.sh`,
   `test/marathon-drive.sh`) either sets `MARATHON_ROOT` explicitly, or runs with its CWD inside an
   isolated fixture directory (never the real repo checkout with an unset/ambient root) — and that
   this stays true going forward (a future test edit that reintroduces the gap must fail the check
   loudly, not silently).

### What to build

A new test case (either a new small test file, e.g. `test/marathon-root-audit.sh`, or a new case
appended to `test/marathon.sh` — your call, whichever fits the existing test-file conventions in this
repo better) that:

1. Greps `test/marathon.sh` and `test/marathon-drive.sh` for every line that invokes
   `relay-automation/marathon.sh` or `relay-automation/marathon-drive.sh` directly (e.g. `bash
   "$MSH"`, `bash "$DRIVER"`, `./.xyz/relay-automation/marathon.sh`-style calls) — NOT the stubbed
   `MARATHON_DRIVE`/`STUB` plumbing those tests use to avoid invoking the real driver.
2. For each such invocation, confirms its surrounding shell context sets `MARATHON_ROOT` explicitly
   (grep the same line or the enclosing function/block for `MARATHON_ROOT=`), OR confirms the
   invocation's CWD is inside an isolated fixture dir created by `_setup.sh` (the `$A`/`$B`/`$V`-style
   variables this repo's test harness already uses — never the real repo root).
3. Fails loudly, naming the offending file:line, if any invocation has neither signal.

You will find that, as of today, every existing invocation in both files already satisfies this
(verified before this brief was written) — this phase is about making that a CHECKED, enforced
invariant, not about fixing a currently-broken test. If your audit finds a genuine gap, fix that one
specific invocation to set `MARATHON_ROOT` explicitly rather than expanding scope elsewhere.

### Acceptance / done means

- The new audit test exists, runs, and passes against the current (already-compliant) test suite.
- `bash test/marathon.sh` and `bash test/marathon-drive.sh` still both green (unchanged behavior).
- Full `validate.sh` green (or unchanged from before your change — the pre-existing `#208`
  environment red is expected and not yours to fix).
- Do NOT touch `relay-automation/marathon.sh` or `relay-automation/marathon-drive.sh` at all.

---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): test/marathon.sh,test/marathon-drive.sh,test/marathon-root-audit.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH209-TURN --agent codex --paths "phases/gh213-209-203-remaining--gh209/RELAY.md,test/marathon.sh,test/marathon-drive.sh,test/marathon-root-audit.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH209-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH209-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gh213-209-203-remaining--gh209/RELAY.md and test/marathon.sh,test/marathon-drive.sh,test/marathon-root-audit.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: test/marathon.sh,test/marathon-drive.sh,test/marathon-root-audit.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH209-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH209-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh213-209-203-remaining--gh209/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · codex

Implemented the static audit as a standalone test in `test/marathon-root-audit.sh`. It scans `test/marathon.sh` and `test/marathon-drive.sh` for direct invocations of the real `marathon.sh` / `marathon-drive.sh`, resolves local aliases like `MSH` / `DRIVER`, and fails with `file:line` if an invocation lacks either an explicit `MARATHON_ROOT=` or a fixture-local `cd "$A"` / `$B` / `$V`-style cwd signal in the enclosing helper/subshell or continued command prelude.

Touched `test/marathon.sh` and `test/marathon-drive.sh` only to `unset MARATHON_LANE_NS` at startup. The ambient lane namespace from this relay turn was leaking into those suites and redirecting rendered relay paths under `phases/gh213-209-203-remaining--gh209/`, which broke pre-existing path assertions unrelated to GH-209. Explicit GH-207 namespaced cases still set `MARATHON_LANE_NS` per invocation and remain covered.

Verification:
- `bash test/marathon-root-audit.sh`
- `bash test/marathon.sh`
- `bash test/marathon-drive.sh`

### Round 1 · Reviewer · agy

**Verdict:** Approved

The implementation in `test/marathon-root-audit.sh` successfully audits that all invocations of the real `marathon.sh` and `marathon-drive.sh` in the test suite have either `MARATHON_ROOT` set or execute within an isolated fixture directory (which ensures the real repo root is never contaminated).
The pre-existing tests inside `test/marathon.sh` and `test/marathon-drive.sh` pass successfully, and unsetting `MARATHON_LANE_NS` at the top of these scripts prevents the namespace leakage.
The code is clean, robust, and correctly scoped. Approved!
