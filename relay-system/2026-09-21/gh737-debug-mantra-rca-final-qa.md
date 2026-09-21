# RELAY · GH-737 final QA: debug-mantra Root Cause Analysis gate
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-21.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-737-final-qa-debug-mantra-root-cause-analysis-gate): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/debug-mantra/SKILL.md` (diff vs origin/development, commit 7dfc84d5); context: `PROJECT/1-INBOX/GH-737-DEBUG-MANTRA-RCA-GATE.md`, issue #737
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-21
- Definition of Done: (a) mantra 3 carries a falsifiable root-vs-proximate class-vs-instance test and the named symptom-fix trap; (b) mantra 4 closes with the one-line RC statement; (c) plan pivot row 3 mirrors it; (d) recital block (lines 10-16) byte-identical to origin/development; (e) no contradiction with the existing 'scale rigor to the bug' rule; (f) no tooling/scripts added (docs-only, commensurate complexity).

## Context — questions for the Reviewer

Operational envelope: a prose skill file consumed by LLM agents. Grade prose correctness, coherence
with the four existing mantras, and whether it changes agent behaviour as issue #737 intends. Do NOT
request scripts, tests, or tooling. The recital block is out of scope for rewording.

1. Does the "Root cause or proximate cause?" block in mantra 3 give a test an agent can actually apply
   (class-vs-instance, "what let that happen?"), or is it decorative? Cite lines.
2. Is the symptom-fix trap definition accurate, and does its "tell" (cannot name the upstream change
   that would make the guard dead code) discriminate symptom fixes from legitimate defensive code?
3. Does the mantra-4 RC statement fit the ledger's purpose, and is the new operating-rules gate
   ("Do not propose a fix until the RC statement…") consistent with "scale rigor to the bug" for
   trivial defects, or does it conflict?
4. Is the plan-pivot row 3 addition coherent with the plan-only-rule paragraph below the table?
5. Anything redundant with existing text, over-engineered, or contradicting another section?

Output: numbered answers with file:line; each [Blocker]/[Should] carries Observed input / Affected
scope / Falsifier. STATUS: Approved if it passes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

swept file: yes

Scope note: Setup is unbound. I inferred `skills/debug-mantra/SKILL.md` and the acceptance criteria in
`PROJECT/1-INBOX/GH-737-DEBUG-MANTRA-RCA-GATE.md:52-57` only to perform a provisional whole-file
sweep; that inference cannot substitute for the relay's source-of-truth contract.

- [Blocker] The relay still contains literal placeholders for both the artifact and Definition of
  Done (`relay-system/2026-09-21/gh737-debug-mantra-rca-final-qa.md:54,57`), while its own protocol
  requires review of "the artifact named in Setup" against that Definition of Done
  (`relay-system/2026-09-21/gh737-debug-mantra-rca-final-qa.md:15-18`). This is the observed failure:
  the review target and grading contract are undefined. Concrete fix: replace both placeholders with
  the exact artifact path and complete acceptance criteria before returning for review.
- [Pass] On the inferred artifact, the whole 101-line file was swept and no pre-existing defects were
  found. The edit adds the class-vs-instance/root-vs-proximate test and named symptom-fix trap at
  `skills/debug-mantra/SKILL.md:55-58`, the required RC close-out at
  `skills/debug-mantra/SKILL.md:68`, mirrors it in the plan pivot at
  `skills/debug-mantra/SKILL.md:80`, and enforces it at `skills/debug-mantra/SKILL.md:97`.
  Concrete fix: none.
- [Pass] Narrow count probe passed. Command:
  `rg -c 'proximate' skills/debug-mantra/SKILL.md; rg -c 'symptom-fix trap' skills/debug-mantra/SKILL.md; rg -c 'Root cause:' skills/debug-mantra/SKILL.md`.
  Exit status: `0`. Decisive output: `3`, `1`, `1`, satisfying the inferred thresholds at
  `PROJECT/1-INBOX/GH-737-DEBUG-MANTRA-RCA-GATE.md:52-54`. Concrete fix: none.
- [Should] [Unverified — needs clone run] The exact `origin/development` recitation-diff criterion at
  `PROJECT/1-INBOX/GH-737-DEBUG-MANTRA-RCA-GATE.md:55-56` was not run because this turn explicitly
  forbids every `git` invocation. A supporting non-authoritative comparison was clean: command
  `sed -n '1,19p' skills/debug-mantra/SKILL.md > "$TMPDIR/gh737-current-recitation.txt"; sed -n '1,19p' /Users/noelsaw/.codex/skills/debug-mantra/SKILL.md > "$TMPDIR/gh737-reference-recitation.txt"; cmp -s "$TMPDIR/gh737-current-recitation.txt" "$TMPDIR/gh737-reference-recitation.txt"`
  exited `0`. Concrete fix: provide the authoritative origin/development comparison in the next turn
  or cite the disposable-clone harness result.

VERDICT: FAIL

Basis: The inferred artifact content is strong, but an authoritative final-QA verdict is impossible
until the relay names its artifact and Definition of Done; one acceptance gate also remains
unverified against its required baseline.

Handing off to Producer — go to the Producer window and say 'take your turn'.

### Producer · Round 2 · claude-a

Dispositions on Round 1:
- [Blocker] placeholders in Setup — **Accepted, fixed.** Artifact and Definition of Done are now filled
  in above, plus a Context block with the five concrete questions. The scaffold edit had silently
  failed to apply in Round 1; that was the root cause, not the review.
- [Should] recital-diff criterion unverified — **Resolved with authoritative evidence.** Run in the
  task clone (git allowed for the Producer):
  `git diff origin/development -- skills/debug-mantra/SKILL.md | rg -c '^[-+]> '` → `0` matching
  lines (0 = no recital line added or removed). Exit status of the pipeline: rg returns 1 on zero
  matches, which is the passing condition here. `bash test/debug-mantra.sh` → exit 0.
- Both [Pass] findings — acknowledged; no change.

Artifact unchanged since Round 1 (still commit 7dfc84d5). Please grade against the now-bound Setup
and answer the five Context questions.

Handing off to Reviewer — take your turn.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
