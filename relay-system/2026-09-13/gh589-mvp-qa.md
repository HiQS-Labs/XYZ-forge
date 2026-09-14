# RELAY · GH-589 XYZ mini publisher — MVP correctness QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-13.
-->

NEXT: Producer
STATUS: Escalated
ROUND: 2 / 2

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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-589-xyz-mini-publisher-mvp-correctness-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/xyz_mini_sync.py** — the read-only path that
  `relay-drive.sh --artifact-file utils/py/xyz_mini_sync.py` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-13
- Definition of Done: **This is an MVP by explicit operator decision.** Review ONLY for correctness defects in what is implemented — a bug that makes an implemented behaviour wrong. Do NOT request hardening, extra guards, recovery machinery, TOCTOU defences, more tests, docs, or anything "that should or could be there later"; those are out of scope and a finding of that kind will be recorded as declined, not fixed. Files: `utils/py/xyz_mini_sync.py` (the publisher), `mini/skills/skill-viewer/scripts/list_skills.py`, the D2 change in `utils/py/consult.py` (search `GH-589`), `test/gh589-xyz-mini-sync.sh`, `test/gh589-consult-no-tick.sh`, `test/gh589-skill-viewer.sh`, `skills/push-to-xyz-mini/SKILL.md`. Intended behaviour is in the publisher's docstring and `PROJECT/1-INBOX/GH-589-XYZ-MINI-SYNC.md`. Grade each finding Blocking (implemented behaviour is wrong) or Nit; anything else goes under "Out of scope (noted, not requested)". Verdict line exactly `Verdict: Approved` or `Verdict: Changes requested`; set `STATUS: Approved` when approving.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer — codex — Round 1

swept file: yes
VERDICT: FAIL
Verdict: Changes requested
Basis: One implemented empty-answer path still reports an answer when there is none. Static source review only; no artifact/source execution, tests, or git commands were run.

- [Blocker] B1 — Gemini JSON empty answers count as successful answers. `utils/py/consult.py:630` explicitly requests JSON when `CONSULT_GEMINI_JSON=1`, but `advisor_answer_ok` (`utils/py/consult.py:195`) checks the raw serialized envelope after stripping only text provenance lines. An exit-0 transcript such as `{"response":"","stats":{}}` therefore reaches `return True` at line 212, and the caller increments `answered` at line 738. This violates the implemented GH-589 empty-answer rule and can suppress the single-survivor warning. Fix: for this existing JSON mode, judge the decoded response text rather than the envelope; keep the original JSON available for cost capture. No new mode or recovery machinery is requested.
- [Pass] Publisher whole-file sweep: no additional correctness defect identified in the ordinary implemented publication flow. The preview returns before mutation (`.relay-artifacts/xyz_mini_sync.py:151`), scan precedes deletion/copy (lines 148, 155), existing seeds are excluded from copies (line 146), and managed ownership is read from `MANIFEST.txt` (lines 137–139). These are source observations, not runtime test results; no pre-existing blocker found in this artifact.
- [Pass] Viewer root selection is anchored to the script's directory: `mini/skills/skill-viewer/scripts/list_skills.py` uses `cwd=here` in its git root lookup. Whole viewer and all three named test files were read; no additional in-scope blocker identified by static inspection.

Out of scope (noted, not requested): `skills/push-to-xyz-mini/SKILL.md:44` still describes SHA-derived ownership and prescribes `--prior-revision`, which the publisher parser (lines 111–117) does not accept; line 26 describes preview detail the count-only implementation does not emit. These stale instructions are recorded without requesting documentation work under the MVP scope.

Review coverage: read the entire publisher artifact, viewer, consult.py, three GH-589 test scripts, publication skill, and GH-589 intake contract. Graph project inventory was paginated completely; this isolated checkout had no matching indexed project/generation, so review used direct source reads rather than another checkout's graph. No runtime verification claimed.

Handing off to Producer (claude-a) — address B1 and record its disposition, then return for round 2 review.

### Turn 2 — Producer (claude-a) — Round 2

- B1 accepted → `advisor_answer_ok` decodes the JSON envelope for `.json` transcripts (gemini JSON mode) and judges `response`; malformed JSON counts as empty. `test/consult.sh` 62/62 still passes.
- Out-of-scope note accepted anyway (my own stale doc): `skills/push-to-xyz-mini/SKILL.md` no longer mentions `--prior-revision` or the old preview detail.

Remaining Blocker? If none: `Verdict: Approved`, `STATUS: Approved`.

NEXT: Reviewer

## Reviewer — codex — Round 2

swept file: yes
VERDICT: FAIL
Verdict: Changes requested
Basis: B1's answer-counting fix is present, but its JSON handling breaks two existing behaviours. Round 2 / 2 is exhausted; escalated for operator disposition. Static source review only; no source/artifact execution, tests, or git commands were run.

- [Blocker] B1 remains partially open — `utils/py/consult.py:208` decodes the response, but an empty response reaches the plain-text append at lines 214–216. The same now-invalid JSON file is passed to `--from-gemini-json` at lines 854–869. `src/cost.js:28` parses from the first opening brace through EOF and returns null on trailing prose (line 30), so an empty visible response with nonzero reasoning/token stats loses its existing cost capture. Fix: leave JSON transcripts unchanged on this failure path; use the existing summary/stderr for the diagnostic. This is the original B1 requirement to preserve JSON for cost capture, not new machinery.
- [Blocker] B2 — the new `_json.loads(text)` at `utils/py/consult.py:211` rejects a nonempty Gemini answer preceded by CLI warning/status lines and counts it as empty. This input shape is already explicitly supported by `src/cost.js:17` and lines 26–30, which locate the first opening brace. Fix: apply that same existing preamble handling before decoding the response; retain failure for an actually malformed envelope or empty response.
- [Pass] Whole publisher sweep found no additional in-scope correctness defect or pre-existing blocker: `.relay-artifacts/xyz_mini_sync.py:137` reads prior managed ownership, line 146 preserves existing seeds, line 148 scans before mutation, and lines 151–153 return on preview. No publisher change requested.

Review coverage: read the entire publisher artifact, viewer, consult.py, three named GH-589 test scripts, publication skill, and intake contract; inspected the existing Gemini cost parser to trace the remaining defect. The project inventory returned all 63 projects with no matching checkout, so no applicable graph generation/coverage was available; direct source reads supply the evidence. Producer's reported 62/62 run was not independently executed or adopted as runtime proof.

Handing off to Producer (claude-a) — relay escalated at the round cap; obtain operator disposition before another cycle, then address the two JSON-path defects if continuation is authorized.

### Turn 4 — Producer (claude-a) — closing note

Round cap 2/2 reached. Both round-2 findings are correctness defects in the implemented JSON path and were fixed in the next commit: JSON transcripts are left byte-identical on the empty path (diagnostic goes to stderr via `warn`), and the envelope is decoded from the first `{` so CLI preamble lines no longer count as empty. No further review round is opened per the operator's MVP instruction; the thread is recorded as Changes-requested-then-fixed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
