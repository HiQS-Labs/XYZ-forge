# RELAY · GH-1508 Final QA: governance doc list extension
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
6. **Manual relay: commit only the relay file** (`relay(gh1508-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/pdda/pdda.sh`, `PROJECT/PDDA.md`, `TESTS-RESULTS/2026-11-20+GH-1508/smoke.md`
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-19
- Definition of Done: issue #1508 with the operator decision (extend, never replace); no new suite (GH-831).

Small change; design decided by the operator (issue #1508 comment / run record 01:50Z: a committed per-repo
file that EXTENDS the default list, never replaces it). Plan QA skipped: the operator settled the only design
question and the diff is one variable resolution. Diff: `git diff origin/development..HEAD`.

Questions (cite file:line):
1. In `utils/pdda/pdda.sh` `check_governance`, does a `.pdda-mode` line `PDDA_GOVERNANCE_DOCS_EXTRA=...` extend the
   default set, while an exported `PDDA_GOVERNANCE_DOCS` still replaces it? Any parsing hole (comments, quotes,
   CRLF, several lines, empty value) that could drop the default docs or scan something unintended?
2. Is `.pdda-mode` really preserved by install and sync (`utils/pdda/pdda-install.sh` seed handling, `pdda-sync.sh`)?
3. Does `TESTS-RESULTS/2026-11-20+GH-1508/smoke.md` show the pre-fix script ignoring the line (red control) and the
   fixed script flagging the extra doc? Do `PROJECT/PDDA.md` and the CHANGELOG describe the behaviour accurately?

End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, a Basis; set STATUS Approved only on PASS (approval = `tick done`).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1
- [Should] Normalize the extra-list value before tokenization (`utils/pdda/pdda.sh:1435–1436`, consumed at `:1454–1455`). CRLF leaves a literal carriage return on the last path, so an existing extra doc is silently skipped. Strip trailing CR/whitespace (the existing `pdda_trim` helper suffices for this case); retain defaults and replacement precedence.
  Observed input: `PDDA_GOVERNANCE_DOCS_EXTRA=README.md\r\n`; the existing `README.md` becomes the non-existent filename `README.md\r`.
  Affected scope: extra-list assignments with CRLF endings, specifically the last whitespace-delimited path.
  Falsifier: the same existing doc selected from LF and CRLF assignments must produce the same path and findings; an empty last assignment must still retain defaults.
  Probe (exit 0), using the exact parser expression and file-existence predicate:
  ```bash
  /bin/bash -c 'extra="$(printf "PDDA_GOVERNANCE_DOCS_EXTRA=README.md\r\n" | sed -nE "s/^[[:space:]]*PDDA_GOVERNANCE_DOCS_EXTRA[[:space:]]*=[[:space:]]*([^#]*).*/\1/p" | tail -n1)"; for doc in $extra; do printf "token=%q\n" "$doc"; if [ -f "$PWD/$doc" ]; then echo present=yes; else echo present=no; fi; done; [ -f README.md ] && echo control-present=yes'
  ```
  Decisive output: `token=$'README.md\r'`, `present=no`, `control-present=yes`.
- [Nit] State the configuration grammar in `PROJECT/PDDA.md:644–647`: quoted values currently retain literal quotes, comments begin at the first `#`, and the last assignment wins (`pdda.sh:1435–1436`). Document unquoted values and last-assignment behavior, or support balanced outer quotes without sourcing/eval.
- [Pass] Core extension/replacement order is correct by inspection: `docs="$PDDA_GOVERNANCE_DOCS_DEFAULT"` is reached only when the environment replacement is empty, and extras are appended (`utils/pdda/pdda.sh:1432–1437`). Empty extra values cannot remove defaults.
- [Pass] Preservation is correct for ordinary installs/sync: `utils/pdda/pdda-install.sh:450–459` keeps existing seed files unless `--force`; `.pdda-mode` is seeded at `:762/:767`. `utils/pdda/pdda-sync-manifest.conf:16–29` includes only `utils/pdda`, `PROJECT/PDDA.md`, and two Python scanners, so mode is outside normal sync. Qualify the new docs/CHANGELOG preservation statement with the explicit install `--force` exception.
- [Pass] The recorded smoke table includes the requested red control and candidate warning (`TESTS-RESULTS/2026-11-20+GH-1508/smoke.md:9–13`), and the sibling `provenance.jsonl` identifies its candidate SHA. This is retained producer evidence, not an independently rerun suite. No gate or executable fixture was run here.
- [Nit] Whole-file sweep found pre-existing documentation drift: `PROJECT/PDDA.md` under "Automation layers" says warnings never leave the clean state, while `utils/pdda/pdda.sh:1852–1857` explicitly reports warnings separately. Correct that prose to four outcomes when convenient; it does not invalidate this extension.

swept file: yes
VERDICT: FAIL
Basis: Reviewed the complete three named artifacts and supporting installer/sync paths directly. The nearest graph is a different checkout, generation 2026-11-18T19:39:07Z, and lacks this smoke artifact; graph coverage cannot attest this seeded worktree, so source evidence governs. One concrete parsing defect silently drops CRLF-configured extra docs. No other pre-existing source defect established in the sweep; the documentation drift above is pre-existing. Return to Producer for the bounded parser correction and retained manual evidence; no new suite requested.

Handing off to Producer (claude-a) — address the parsing finding and record dispositions.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
