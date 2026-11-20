# RELAY · GH-1498 delta2 fixes QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-16.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 1

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
6. **Commit only the relay file** (`relay(gh1498-coderabbit-delta3-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **skills/2-daily/pr-minder/scripts/pr_minder.py** (review `git diff 0522ef4b0..f6b432710`).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-16
- Definition of Done: the three FAIL findings in `relay-system/2026-11-16/gh1498-coderabbit-delta2-qa.md` (Round 1) are resolved by `git diff 0522ef4b0..f6b432710`, with no regression.

## Context and questions

**Envelope:** a manual local CLI, one operator, one repo. No new tests (GH-831).

Read your own delta2 Round 1 findings and the producer response in `gh1498-coderabbit-delta2-qa.md`, then the diff.

Answer, citing `file:line`:
1. Does `updates_since` now count `uncertain` attempts within the episode window, with the PR and time filter unchanged?
2. Is every PR- or CLI-controlled string that reaches a comment now rendered through `lit()`? That covers conflict files, own-commit headlines, check names and the update-branch error. Is a code span with backticks and newlines stripped inert on GitHub? Did any other untrusted interpolation path get missed?
3. Do A19a, A19c and A19f exercise your original inputs, with bad candidates that fail?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: PASS
Basis: Approve the three bounded delta2 corrections. The seeded source matches the candidate blob, the episode filters remain intact, and the comment interpolations are contained. No additional concrete defect found in the full-file sweep, including pre-existing code.
swept file: yes

Reviewed all of `skills/2-daily/pr-minder/scripts/pr_minder.py` (1–571), the delta2 findings/response, and the existing manual-check assertions and receipts. Graph tools were unavailable; direct source fallback used. No git command, executable fixture, gate, or live GitHub mutation was run.

- [Pass] **Candidate and delta:** reconstructed `0522ef4b0..f6b432710` directly from loose commit/tree/blob objects using Python `pathlib`, `zlib` and `difflib`; asserted the candidate blob equals the seeded file. Command: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 - <<'PY'` (inline read-only object traversal; exit 0). Decisive output: `seed equals f6b432710 blob`. The delta adds `lit()`, extends the outcome tuple, and changes the four requested rendering sites; see `pr_minder.py:52`, `:116`, `:299`, `:314`, `:318`, `:452` (all source citations in this block refer to the full artifact path above).

- [Pass] **Uncertain attempts count inside the same PR/episode window.** `pr_minder.py:119`–123 retains PR, phase, action and timestamp filtering and now includes `uncertain`; `:328` consumes that count. Narrow probe command: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 - <<'PY'` (exit 0). Parsed the artifact AST and compiled only `Receipts`, `md_safe`, and `lit`; constructed Receipts with `object.__new__`, assigned in-memory rows, and supplied an ISO timestamp parser. Two PR-1 uncertain results after `2026-11-10T00:00:00+00:00` produced `two uncertain: 2`. A mixed set of ok/failed/uncertain plus other-PR, pre-episode, intent and comment rows produced `PR/time/phase/action filters: 3`; both values were asserted.

- [Pass] **The four requested text paths use literal rendering.** Conflict files (`pr_minder.py:299`), own commits (`:314`), check names (`:318`) and fallback error (`:452`) call `lit()`. `:54` removes backticks/CR/LF before `:61` wraps the text. The same AST probe (exit 0) asserted exactly two delimiting backticks and no CR/LF for the three original check-name inputs, the original failure diagnostic, and a backtick/newline breakout input. Decisive outputs included `'<https://attacker.example>' -> '\`<https://attacker.example>\`'` and `'update rejected: @org/team <https://attacker.example>' -> '\`update rejected: @org/team <https://attacker.example>\`'` (backslashes here only escape Markdown delimiters). These are inert code contents under [GFM code-span rules](https://github.github.com/gfm/#code-spans), including literal backslashes and angle brackets. No live GitHub rendering/notification check was performed.

- [Pass] **No additional untrusted comment-text path found.** Strictly, not every external string calls `lit()`: the repair command already uses a code span, rejects backticks/CR/LF, and shell-quotes branch names (`pr_minder.py:302`–308); check URLs intentionally remain usable HTTPS links through `safe_url()` (`:64`–66, `:318`). Other interpolations are computed dates, rung constants and numeric counts (`:215`–216, `:284`–295). Neither exception exposes the raw-text failure found in delta2; no extra behavior change requested.

- [Pass] **A19a/A19c/A19f contain discriminating inputs and controls.** `TESTS-RESULTS/2026-11-16+GH-1498/manual_check.py.txt:719`–737 supplies all three original check names and a raw-text candidate; `:761`–776 supplies failed+uncertain results within the episode and an ok-only candidate (the immediate predecessor's ok+failed implementation also counts only one, so fails this assertion); `:806`–818 supplies the original stderr and raw-interpolation candidate. The recorder rejects crashes (`:182`–190). Committed `manual-check.log:23`, `:25`, `:28` report PASS and each bad candidate rejected; `provenance.jsonl:15` identifies `f6b432710`. This is source/receipt review, not an independent rerun of that executable driver.

- [Unverified — needs clone run] The full manual driver and harness gate were not executed in this worktree. Disposable-clone execution remains with the harness after this review; this approval is the scoped code-review verdict, not a gate-pass claim.

Relay closed (Approved), no further turn needed. Token handed off with `done`; the harness owns the file-scoped commit.


### Attestation · relay-drive — 2026-11-17T07:33:17Z
task: RELAY-gh1498-coderabbit-delta3
reviewer: codex
status: Approved
reviewed-head: 883bd87afb488020e8294ea2e6fd7bc4b6f260a6
added-range: 6551+4588
added-sha256: ad6d54a33677c77b07a221ecf7054f6a8845419c95b9d8b5cb09e1893983041d
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
