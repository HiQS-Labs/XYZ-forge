# RELAY · GH-1455 final QA: pdda_fn.sh shebang and documentation
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-13.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1455-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review (a small, committed change; base `37ca5e0d2`, HEAD `500872b42`; review the files at HEAD): `TESTS-RESULTS/2026-11-04+GH-1344/pdda_fn.sh` (one added shebang line), `TESTS-RESULTS/2026-11-13+GH-1452/qualifying-gate-summary.md` (a correction), `PARKED/2026-11-13-pre-push-shellcheck.md` (new, documents a paused decision), `CHANGELOG.md` (new top entry), and the evidence folder `TESTS-RESULTS/2026-11-13+GH-1455/` (README, provenance.jsonl, three shellcheck logs).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-13
- Issue: HiQS-Labs/XYZ-forge#1455 (`ci-local.sh` fails its shellcheck step on `pdda_fn.sh`, SC2148). Operator decisions this change implements: fix the file (not the check) with a shebang; correct the wrong "hosted CI is green" statement; pause adding shellcheck to pre-push but document it.
- Operational envelope: one added line plus documentation. Grade against the stated requirements and commensurate complexity. XYZ-forge forbids new tests (AGENTS.md *No new tests*, GH-831): a new test file, suite or registry entry in the diff is itself a finding, and you must not ask for one. The qualifying gate is not run for this change; the verification is the repo's own shellcheck scan before and after, retained under `TESTS-RESULTS/2026-11-13+GH-1455/`. Do not run `validate.sh`, `test/*.sh` or pytest.
- Definition of Done: the shebang is the only code change and the file's behavior is unchanged; the corrected statement in `qualifying-gate-summary.md` is true against `.github/workflows/ci.yml` and `ci-local.sh`; the PARKED note's claims are grounded; the CHANGELOG entry and the evidence README do not overclaim; nothing outside this scope is touched.

## Questions for the Reviewer (answer each with `file:line`)

1. Is the change in scope and minimal? List every file in the diff and say whether each is needed.
2. What prevents an unfixed tree from being reported as delivered, and where is the observed rejection? Check `TESTS-RESULTS/2026-11-13+GH-1455/shellcheck-before.log` and `shellcheck-base-blob.log` (exit 1, SC2148) against `shellcheck-after.log` (exit 0), and that `provenance.jsonl` hashes match the files.
3. Is the corrected sentence in `qualifying-gate-summary.md` grounded? Verify against `.github/workflows/ci.yml` (the two shellcheck steps are gated on `steps.route.outputs.docs_only != 'true'`; the scan is `git ls-files -- '*.sh'` with `shellcheck -S error`) and `ci-local.sh` `shellcheck_tracked`. The claim that the latest two `development` runs showed those steps as `skipped` came from the GitHub API and you cannot re-check it offline: grade it `[Unverified — needs network]` if you cannot confirm it, rather than failing it.
4. Are the PARKED note's claims grounded: 656 tracked `.sh` files, `pdda_fn.sh` the only one without a shebang, `githooks/pre-push` and `validate.sh` not executing shellcheck (`validate.sh:301` registers only a census suite), `fuzz-loop.sh` fixed in #121 per the `ci.yml` header, the file added 2026-11-05?
5. Does the CHANGELOG entry or the evidence README overclaim anything (for example about running the full `ci-local.sh`, the hosted job running on this PR, or how `pdda_fn.sh` is invoked)?
6. Is anything missing or wrong that a reader of #1455 would need?
7. Pre-existing defects in the touched files are in scope: report any real defect you can demonstrate in `pdda_fn.sh` itself (it extracts functions from `utils/pdda/pdda.sh` and `eval`s them).

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix. Every `[Blocker]` or `[Should]` asking for a behaviour change needs `Observed input:`, `Affected scope:` and `Falsifier:` lines. Include the literal line `swept file: yes` or `swept file: no`. Set a VERDICT (PASS, FAIL or PARKED) and Basis. Read-only probes only, output under `.relay-scratch/`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: The one-line code fix is sound and the red/green logs are internally consistent. Two small documentation corrections remain; no runtime change or new test is requested.

swept file: no
Scope disclosure: read all nine lines of `pdda_fn.sh`, the complete GH-1452 summary, PARKED note, GH-1455 README, provenance and all three logs. Reviewed the new CHANGELOG entry and established that the older content is unchanged; did not re-audit the entire 1,152,189-byte historical CHANGELOG. No demonstrated pre-existing runtime defect in the helper was found by this static review; execution of its eval/resolver was deliberately not attempted under the reviewer restrictions. The extraction itself is nonempty and passes `bash -n`; this is syntax evidence, not execution evidence. MCP's nearest XYZ-forge index is a different checkout with generation `2026-09-01T15:54:30Z`; coverage reports changed/missing paths, so findings use current source and read-only object inspection instead.

- [Pass] **Q1 — scope/minimality.** Read the base/head Git objects directly with Python (no git invocation): `37ca5e0d272c04fd2a9cd02ef4b0cfd1bbf5d2c8` → `500872b424bf6a0d740355da531e9e45c87403d6` has exactly these nine files: `CHANGELOG.md:3` (required change record); `PARKED/2026-11-13-pre-push-shellcheck.md:3` (required paused decision); `TESTS-RESULTS/2026-11-04+GH-1344/pdda_fn.sh:1` (fix); `TESTS-RESULTS/2026-11-13+GH-1452/qualifying-gate-summary.md:39` (required correction); `TESTS-RESULTS/2026-11-13+GH-1455/README.md:1` (evidence interpretation); `TESTS-RESULTS/2026-11-13+GH-1455/provenance.jsonl:1` (required receipts); and that folder's `shellcheck-before.log:1`, `shellcheck-base-blob.log:2`, `shellcheck-after.log:1` (red/green evidence). Each is needed. Object comparison returned `ONLY_SHEBANG True MODE 100644`; no test or registry change. Fix: retain this scope.

- [Pass] **Q2 — observed rejection and hashes.** `shellcheck-before.log:6` and `shellcheck-base-blob.log:4` retain SC2148; their final lines say `scan exit=1` and `shellcheck exit=1`; `shellcheck-after.log:6` says `scan exit=0`. Recomputed SHA-256 for each nonempty log against `provenance.jsonl:1-3`: all three match. Narrow local commands `shellcheck -S error TESTS-RESULTS/2026-11-04+GH-1344/pdda_fn.sh` and `bash -n TESTS-RESULTS/2026-11-04+GH-1344/pdda_fn.sh` each exited 0 with empty output. A controlled copy made with Python `Path('.relay-scratch/tmp/unfixed-pdda.sh').write_bytes(Path('TESTS-RESULTS/2026-11-04+GH-1344/pdda_fn.sh').read_bytes().split(b'\n',1)[1])`, then `shellcheck -S error .relay-scratch/tmp/unfixed-pdda.sh`, exited 1 and printed `SC2148 (error): Tips depend on target shell and yours is unknown`. That rejects the unfixed content; it does not assert a new full qualifying run. Fix: retain receipts and the explicit full-gate limitation.

- [Pass] **Q3 — correction's source basis.** `.github/workflows/ci.yml:306-324` gates both installation and scan on `steps.route.outputs.docs_only != 'true'`, enumerates `git ls-files -- '*.sh'`, and invokes `shellcheck -S error`. `ci-local.sh:193-195` uses the same selection and severity with NUL-safe parallel enumeration. `utils/ci-route.sh:65` includes `TESTS-RESULTS/*` as docs. Thus the correction at `qualifying-gate-summary.md:39-43` correctly distinguishes a skipped scan from a passing scan. Fix: retain that distinction.

- [Unverified — needs network] **Q3/Q5 — particular hosted executions.** The latest two development runs being skipped (`qualifying-gate-summary.md:42`) and this PR's actual hosted steps (`GH-1455/README.md:25-26`) were not checked against the GitHub API. The workflow supports the conditional statement but does not establish those particular run outcomes. Fix: cite run IDs/step outcomes when available, or describe the configured docs-only behavior rather than asserting this PR's observed result. This limitation alone is not a failure under Setup.

- [Should] **Q4/Q5/Q6 — state the shebang census in the past tense.** `PARKED/2026-11-13-pre-push-shellcheck.md:16-17` says “It is currently the only tracked `.sh` without a shebang”; `GH-1455/README.md:22` likewise says “it is the only tracked `.sh` without a shebang.” Those statements are false in the reviewed tree. Read-only base/head object census exited 0 and printed `TRACKED_SH 656`, `BASE_NO_SHEBANG ['TESTS-RESULTS/2026-11-04+GH-1344/pdda_fn.sh']`, `HEAD_NO_SHEBANG []`; the new shebang is at `pdda_fn.sh:1`. Fix both to “Before this fix, it was the only tracked .sh without a shebang; afterward none remain.” This requests only a prose correction.

- [Should] **Q4 — distinguish repository scanning from the registered suite's fixture scans.** The premise that `validate.sh` does not execute shellcheck is too broad: `validate.sh:301` registers `test/gh365-shellcheck-parallel.sh`; that suite's `scan()` runs `shellcheck -S error` on its scratch corpus, including the shebang-less mutant. Its own comment explicitly says “this census suite itself must run shellcheck to test the shapes — self is the one exemption.” Consequently `PARKED/2026-11-13-pre-push-shellcheck.md:20` (“the pre-push hook runs the test pool, not shellcheck”) should say that pre-push/validate do not scan the actual tracked repository scripts. Fix: retain the timing-gap argument, but name the real missing coverage and acknowledge the fixture scan. No suite execution or new machinery is needed; this is a source-demonstrated prose correction.

- [Nit] **Q5 — invocation claim is stronger than the evidence.** `GH-1455/README.md:19-21` infers “can only be run as bash” from mode 644. That mode rules out ordinary direct execution; it does not exclude sourcing or another explicitly selected interpreter. There is also an existing recorded invocation beyond the witness comment: `TESTS-RESULTS/2026-11-04+GH-1344/provenance.jsonl:1` records `bash pdda_fn.sh <tree> <fixture> 1292`. Fix: say “The recorded invocation uses bash; the file is non-executable and its body is unchanged.” This directly supports the intended behavior claim.

- [Unverified — needs history evidence] **Q4 — introduction date.** The 2026-11-05 addition date in `PARKED/2026-11-13-pre-push-shellcheck.md:9` was not independently checked against commit history. The directory name is 2026-11-04 and the old provenance date is 2026-11-06, neither establishes the addition date. Fix: cite the introduction commit if retaining the precise eight-day claim. The #121 precedent is grounded in `.github/workflows/ci.yml:50-53` (“Fixed in #121 (e9b9b07)”).

- [Pass] **Q5/Q7 — bounded claims and helper sweep.** `CHANGELOG.md:5` claims a shellcheck scan pass, not a fresh full `ci-local.sh` pass; `GH-1455/README.md:26` explicitly says the full runner was not rerun. `pdda_fn.sh:3-9` still sets fixture paths, extracts function definitions, evals them and prints the resolver return code. The shebang is the only body-independent addition. It remains a trusted-tree manual witness, not a new gate; no demonstrated defect justifies expanding this one-line fix. Fix: retain that boundary and correct the prose above.

Handing off to Producer (claude-a) — address the two Should prose corrections, disposition the remaining notes, then return for review. No source or artifact was edited by Reviewer; only this relay file changed. The harness owns the commit.

### Producer · Round 1 (claude-a)

All items checked against the tree; each is a prose correction, no code or scope change.

- **[Should] shebang census tense — Implemented.** `PARKED/2026-11-13-pre-push-shellcheck.md` and `TESTS-RESULTS/2026-11-13+GH-1455/README.md` now say "before this fix it was the only tracked `.sh` without a shebang; none remain".
- **[Should] pre-push / validate coverage — Implemented, and the finding is right.** I had written that the hook "runs the test pool, not shellcheck". `validate.sh:301` registers `test/gh365-shellcheck-parallel.sh`, which does run shellcheck on its own scratch corpus. The PARKED note now says neither `githooks/pre-push` nor `validate.sh` scans the repository's tracked scripts, names that census suite, and acknowledges its fixture scan. While checking this I also found the root cause of why the file slipped through: `utils/ci-route.sh:65` counts `TESTS-RESULTS/*` as a docs surface, so a script committed there never triggers the hosted scan, and only `ci-local.sh` scans every tracked `.sh`. That is now stated in the PARKED note and in the corrected gate summary.
- **[Nit] invocation claim — Implemented.** The README now cites the recorded invocation (`provenance.jsonl:1`, `bash pdda_fn.sh <tree> <fixture> 1292`), the 644 mode and the unchanged body, and drops the "can only be run as bash" inference.
- **[Unverified] introduction date — Implemented.** The PARKED note now cites the introducing commit `0dc1d25fb` (2026-11-05); `git log --diff-filter=A` on the file returns it.
- **[Unverified] hosted run outcomes — Modified.** The gate summary now cites the two run IDs (43504181832 and 43505530482) whose shellcheck steps read `skipped` (from the GitHub API during the session). The README no longer asserts this PR's hosted result: it says that by `ci-route.sh:65` every file here is a docs surface, so the steps are configured to be skipped, and the actual outcome was not checked.
- **[Pass] items — Noted.**

swept file: n/a (Producer)

Handing off to Reviewer (codex) for round 2. Re-check only the corrected statements and anything these edits newly broke.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
