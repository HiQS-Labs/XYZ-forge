# RELAY · GH-1543 Final QA: kickstart KS-15 run-record contract
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-19.
-->

NEXT: Producer
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
6. **Manual relay: commit only the relay file** (`relay(gh1543-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/run_record.py** — the read-only path that
  `relay-drive.sh --artifact-file skills/1-hourly/kickstart/scripts/run_record.py` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: antigravity
- Started: 2026-11-19
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

- Candidate SHA: `4ae17986efbb9e541dcf52e30820486a12df129d`
- Plan doc: `PROJECT/2-WORKING/GH-1543-KS15-RECORD-CONTRACT.md` (Plan QA Approved in `relay-system/2026-11-20/gh1543-plan-qa.md` round 3)
- Implementation files: `skills/1-hourly/kickstart/scripts/run_record.py`, `skills/1-hourly/kickstart/SKILL.md`
- Verification evidence: `TESTS-RESULTS/2026-11-20+GH-1543/manual-check.md`, `pdda-run.log`, `provenance.jsonl`, `inputs/`, `outputs/`
- Operational envelope: local stdlib Python CLI/module + SKILL.md contract section; `utils/ci-route.sh pull_request` routes `docs` (tier 1 -> `utils/pdda/pdda.sh run` rc=0); no new test suite (`AGENTS.md`, GH-831).

Review the full implementation, plan compliance, SKILL.md contract alignment, and retained `TESTS-RESULTS/2026-11-20+GH-1543/` evidence:
1. Does `run_record.py` faithfully implement the approved plan (v1 grammar, reserved-word `APPLIED` precedence, `escalated` progression, sibling-locked in-lock validation + atomic replace, redaction + empty refusal, mandatory `--primary` + `LANDING_CLONE` + `git-common-dir` + pre/post-switch symlink confinement + failed-push retry)?
2. Does `skills/1-hourly/kickstart/SKILL.md` accurately reflect `run_record.py` without contradictions or missing flags?
3. Are there any new test files/registry entries (forbidden by GH-831), stray scratch files, or hardcoded machine paths in the diff?
4. Do `manual-check.md` and `provenance.jsonl` substantiate all 29 checks truthfully without overclaiming live run-2 acceptance?

Cite `file:line` for findings. End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, a Basis, set `STATUS: Approved` only on PASS, and flip `NEXT: Producer`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1
Block — full seeded module (lines 1–732), approved plan, full SKILL.md, and retained evidence reviewed. Findings apply to the seeded artifact; no source files changed.

- [Blocker] F1 — Authorization redaction exposes Basic credentials. At `.relay-artifacts/run_record.py:82`, the non-Bearer pattern consumes only the scheme, leaving its credential behind; `:393` applies this result to snapshots and `:529` to checkpoints.
  Observed input: `Authorization: Basic dXNlcjpwYXNzd29yZA==`.
  Affected scope: non-Bearer Authorization values containing a scheme and credential on the same line.
  Falsifier: Basic input must retain neither credential nor reversible encoded credential; Bearer input must still redact its token and preserve the following unrelated line.
  Probe command (stdlib, no files written): `PYTHONDONTWRITEBYTECODE=1 python3 -c 'import runpy; m=runpy.run_path(".relay-artifacts/run_record.py"); print(repr(m["redact_text"]("Authorization: Basic dXNlcjpwYXNzd29yZA=="))); print(repr(m["redact_text"]("Authorization: Bearer FakeCredential123456")))' `.
  Observed rc=0; decisive output: `'Authorization: [REDACTED] dXNlcjpwYXNzd29yZA==\n'`; Bearer control: `'Authorization: Bearer [REDACTED]\n'`.
  Root cause: matching one whitespace-delimited token after Authorization; Fix site: SECRET_PATTERNS; Why not downstream: both snapshot and checkpoint must share the corrected redactor. Fix by consuming the complete header value without crossing a newline; retain a manual red/green control.

- [Should] F2 — Refuse Git metadata destinations before any branch/write mutation. `.relay-artifacts/run_record.py:434` and `:467` permit `.git/config`; `:558` atomically replaces the accepted destination before `git add` can refuse it. In a full clone this can overwrite configuration and break subsequent Git commands.
  Observed input: `dest_rel=".git/config"`; the pure syntax/confinement helpers return the path without raising.
  Affected scope: destinations equal to or nested beneath the clone's Git administrative directory (including `.git` itself).
  Falsifier: `records/run.md` remains accepted; `.git/config` and `.git` refuse before changing bytes, index, branch or refs in a disposable full-clone run.
  Probe command: `PYTHONDONTWRITEBYTECODE=1 python3 -c 'import runpy; from pathlib import Path; m=runpy.run_path(".relay-artifacts/run_record.py"); d=m["_validate_dest_syntax"](".git/config"); print(m["_check_fs_confinement"](Path.cwd(),d))'`.
  Observed rc=0; output ends in `rtl-wt.K6r2Xg/.git/config`. This probes acceptance only; destructive checkpoint execution was deliberately not run. End-to-end corruption/refusal: [Unverified — needs clone run]. Fix at destination validation before mutation.

- [Should] F3 — Supersession accepts an older amendment, contrary to the approved plan's “declared newer amendment ID.” `.relay-artifacts/run_record.py:229` checks only existence and inequality; SKILL.md:100 likewise weakens this to “another.”
  Observed input:
  ```text
  RUN-RECORD-VERSION: 1
  OPERATOR_AMENDMENT: OA-1 2026-11-20T07:00Z operator turn old
  OPERATOR_AMENDMENT: OA-2 2026-11-20T07:01Z operator turn new
  APPLIED: OA-2 → superseded by OA-1
  ```
  Affected scope: superseded dispositions referencing amendments older than their target.
  Falsifier: reversing the last line to `APPLIED: OA-1 → superseded by OA-2` must remain valid.
  Probe command: load the seeded module with `runpy.run_path(".relay-artifacts/run_record.py")`, call `parse_record` on the exact text above and then the reversed control, and print `valid` and `errors`. Observed rc=0; both returned `valid=True errors=[]`. Fix by enforcing the approved newer-amendment relation and documenting its ordering definition consistently, or obtain an explicit scoped plan disposition.

- [Should] F4 — Retain reproducible commands and decisive outputs for the claimed 29 checks. `TESTS-RESULTS/2026-11-20+GH-1543/manual-check.md:21`–38 supplies assertions but no runnable setup/commands for the bad-input, concurrent append, confinement, or remote-blob/retry checks; `provenance.jsonl:1`–6 uses only `manual KS-15 contract checks (see manual-check.md)`. There are only two input fixtures, two parser JSON outputs, one redacted output, the summary, PDDA log and provenance. In particular no retained race stdout/exit statuses, pre/post identity/byte measurements, or remote-blob command/output substantiates the publication claim. Fix by retaining the exact manual commands/setup and nonempty results with provenance in the existing evidence directory, from disposable full clones where required; no new suite. These claims are [Unverified — needs clone run], not disproven. Do not replace missing evidence with an assertion that a later gate will run.

- [Pass] Saved parser outputs match fresh in-memory parses of both retained fixtures, and all seven provenance artifact byte counts/SHA-256 values match their files (`provenance.jsonl:1`–7; `outputs/run1-validate.json`, `outputs/run2-validate.json`). Probe: stdlib `json.loads` + `hashlib.sha256(Path(row["artifact"]).read_bytes())`, then compare saved JSON with seeded `parse_record` results (run2 uses `require_landing_clone=True`); rc=0, seven `size_match=True hash_match=True`, both `matches=True`. This establishes artifact integrity and parser reproducibility, not all 29 historical runs.
- [Pass] Sibling lock precedes the read and full candidate validation precedes replace (`.relay-artifacts/run_record.py:366`–378); unresolved escalation is computed from latest disposition (`:303`–312). These are source-inspection findings, not fresh concurrency qualification. The live acceptance limit is stated truthfully: “Live run-2 checkpoint publication remains uncredited until run 2” (`manual-check.md:44`).
- Review limits: no git, gates, fixtures, pytest, or checkpoint executed. Actual candidate diff/new-test/stray-file exclusion is unverified without a supplied diff (git is prohibited this turn). Nearest graph is another checkout, generation 2026-11-18T19:39:07Z, and coverage reports all three candidate paths freshness=missing; complete local source reads were used instead. No additional pre-existing defects found in the full seeded file beyond the findings above.

swept file: yes
VERDICT: FAIL
Basis: observed credential leakage blocks approval; destination confinement, supersession plan alignment and retained verification also need Producer disposition.
Handing off to Producer (antigravity) — address each finding and retain the requested evidence before opening round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
