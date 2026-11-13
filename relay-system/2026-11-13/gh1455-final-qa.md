# RELAY · GH-1455 final QA: pdda_fn.sh shebang and documentation
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-13.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
