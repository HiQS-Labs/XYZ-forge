# RELAY · PR1406 outer review and minor-fix eligibility
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-09.
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
6. **Commit only the relay file** (`relay(pr1406-outer-review-and-minor-fix-eligibility): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/packet.md** — the read-only path that
  `relay-drive.sh --artifact-file temp/pr1406-qa/packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: claude-opus   ·   Producer: codex-parent
- Started: 2026-11-09
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

Reviewed: `.relay-artifacts/packet.md` (candidate a8186569) against the worktree source at HEAD ee7d917d (a8186569 + seed doc). Read-only probes only: grep, sed, python3 -I json reads. No git, tests or fixtures were run.

swept file: no. I read partial ranges, not whole files: `utils/py/consult.py` 128–264, 365–525 and 795–1114 (the whole Codex launch, wait, validate, stamp, neutralize and exit path); `utils/py/jog_run.py` 1142–1189 and 1300–1448; `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` 905–960 and 1015–1035; `relay-automation/consult.sh` 1–22 and 195–230. I found no pre-existing defect in those ranges beyond N1. I did not read the rest of consult.py or jog_run.py.

**[Blocker] B1 — The published head describes itself as defective, and the corrections are not available to review.**
- Observed input: packet.md:13 PR body: "**Not merge-ready:** review found three confirmed defects. Corrections are committed locally at `4d9915835317952983c1c1fb6f4ea6f733174411`, not pushed or fully qualified. Two belong to dependency #1402. Published head remains a8186569b."
- I searched the tree for `4d99158`. The only hit is packet.md itself, so neither the three defects nor the correction diff is in this packet or the tree. a8186569 cannot be approved for merge while its own PR says it is not merge-ready. The correction cannot be reviewed because it is not here.
- Affected scope: merge eligibility of PR1406 at any head other than a pushed, qualified 4d991583 (or its successor). This is an evidence gap, not a request to change consult behaviour.
- Falsifier: a disposition comment naming the three defects, plus a pushed 4d991583 whose full gate passes on that exact SHA. If all three defects sit only in #1402 files and #1402 lands with them, B1 becomes a rebase/re-qualify step and no longer blocks.
- Fix (parent, minor): push 4d991583 and run the normal full gate on that exact SHA. Then re-seed this relay with the three-defect disposition and the `a8186569..4d991583` diff, so the next round reviews the code that will actually merge.

**[Pass] Q1a — The Codex answer is kept separate from diagnostics on every success path.**
- consult.py:810 `["--output-last-message", f_out, full_prompt]`; :812 stdout/stderr go to `f_out + ".transcript"`; :919 the idle bound watches `.transcript` (where progress happens), not the final file.
- :925–926 attestation is written to `out + ".transcript"` only. Answer validation (:952 `advisor_answer_ok(out, m)`), uncited stamping (:992 `rtl_has_uncited_claim(out)`), provenance classification (:1020) and neutral payloads (:327 `answered_items = [... if ok and os.path.isfile(out)]`) all read the final file.
- Neither file is used as a fallback for the other, so a missing final answer can never be backfilled from the raw transcript.

**[Pass] Q1b — Missing and empty final answers fail closed, and so do launch failures and timeouts.**
- Missing file: :215–216 `except OSError: return False`, which goes to :958–962 FAIL.
- Empty file: :232–238 appends a "no visible content" note and returns False.
- Launch failure: :422–425 writes the error to `.transcript` and returns None, which goes to :902–905 FAIL.
- Wall-clock or idle timeout: :978 `surface_partial(out + ".transcript" ...)` marks the transcript PARTIAL and records the advisor as failed (:980).
- Committed evidence agrees: `public-boundary.json` shows candidate modes `missing` rc 5 and `empty` rc 5; `cited` with `uncited_stamp: false, sentinel_in_answer: false, raw_transcript_preserved: true`; `uncited` with `uncited_stamp: true`. The baseline row shows `sentinel_in_answer: true`, i.e. the leak reproduced.
- Caveat: that probe's `candidate` is `09027b1d…`, not c06fcf34 or a8186569. The claim that the runtime is unchanged from 09027b1d to c06fcf34 rests on the Codex receipt (`gh1243-final-fixtures.codex.md`: "Runtime remains unchanged from independently reviewed `09027b1d`"). I could not diff it myself: [Unverified — needs `git diff 09027b1d c06fcf34 -- utils/py/consult.py` empty].

**[Pass] Q1c — The uncited-warning change is a fix, not a regression.** On the old code, a stdout transcript carried prompt and tool echoes, so citation detection ran over prompt text. Now `rtl_classify_cited_claims` (:130–183) and `rtl_has_uncited_claim` judge only the model's own final text. The FIRSTHAND/ECHOED split now separates the answer from the prompt snapshot as designed.

**[Nit] N1 — Failed-Codex summary lines point at the wrong file.**
- Observed input:
  - A Codex run that exits 0 without writing a final file (public-boundary `missing` mode, `answer_exists: false`) prints `[FAIL] codex -> …/t.codex.md (see transcript for error)` (:961). That path does not exist, and :215–216 writes no reason anywhere.
  - On a non-zero exit, :966–967 writes `consult: advisor failed with exit N` into `t.codex.md`, so a file that should hold only the final answer now holds a diagnostic stub. The real diagnostics are in `t.codex.md.transcript`.
- Affected scope: Codex rows with `ok=False` only. Neutral payloads are unaffected because :327 filters on `ok`.
- Falsifier: a missing-final fixture in which the operator-visible summary names `t.codex.md.transcript`, or in which a reason line exists in some file. Today neither holds. Expected after the fix: the summary path is `out + ".transcript"` when `m == "codex"`, mirroring :978.
- Optional, diagnostic text only, not merge-blocking. It fits in one line inside the existing suites.

**[Nit] N2 — Known residual: the frozen Bash fallback still treats stdout as the answer.** `relay-automation/consult.sh:206` runs `_guarded "$out" ... "$CODEX_BIN" exec ... "$FULL_PROMPT"` with no `--output-last-message`. That code is reached only when `XYZ_PYTHON` is explicitly not 1, or python3 is missing or older than 3.8 (:9–20), and the header says it is FROZEN (GH-308). No change requested. It is worth one sentence in SKILL.md so nobody assumes the fallback has the same contract. Today SKILL.md:126 states the contract without that caveat.

**[Pass] Q2 — The fixtures are truthful and no new test machinery was added.**
- The stubs honour the new flag and still print to stdout when the flag is absent: test/consult.sh:25–26 and test/gh589-consult-no-tick.sh:29–31.
- In the packet's file list, every test file is `MODIFIED`. The only `ADDED` .py file is `TESTS-RESULTS/2026-11-10+GH-1243/public-boundary-probe.py`, an evidence probe that is not registered as a suite.
- Caveat: the happy-path stub at test/consult.sh:26–27 writes the same text to the answer file and to stdout, so that case cannot tell separation from leakage. Discrimination depends on the later cases (:201–262), which I did not read: [Unverified].

**[Pass] Q3 — The receipts substantiate c06fcf34 and state the limits honestly.**
- `qualification.json`: `"source": "c06fcf34…"`, `"rc": 0`, `"elapsed": 542.39…`, `"command": "git push -u origin HEAD"`, `"parent_takeover": true`.
- `takeover-focused.json`: `total_passed: 80` (62+4+6+8), `new_builder: false, new_review: false`.
- The Codex receipt explicitly says "Focused-suite/full-gate and hosted qualification are **not attested by this review**".
- TAKEOVER-RESULT.md states plainly: "The original automatic pair failed", "No counters were reset", "#1243 remains open for live Codex + agy acceptance". The PR uses "Refs #1243", not a closing keyword.
- Gap: the a8186569 evidence-only push (66.911s) is claimed only in the PR body. No receipt file for it exists under `TESTS-RESULTS/2026-11-10+GH-1243/`: [Unverified — hosted check/push log].

**[Unverified — needs clone/git] Q4a — Whether the inherited #1402 runtime is byte-identical.**
- I cannot run git here. Settling path: `git diff <1402-head> a8186569 -- utils/py/{jog_run,marathon_drive,relay_drive,releases_app,swarm_preflight}.py` must be empty.
- B1 matters here too: two of the three declared defects are in #1402, so the comparison must be against the *corrected* #1402 head.
- **[Should] (procedural, not a behaviour change):** after #1402 lands, merge or rebase 1406 onto `development` and confirm those five files have an empty diff against `development` before merging.
  - Why: if #1402 is squash-merged, 1406 still carries the old pre-correction #1402 commits. A 3-way merge base can then produce conflicts, or a silent mix wherever the corrected and old hunks differ.
  - Falsifier: that diff is empty on the final 1406 head.

**[Pass] Q4b — A manual rescue PR cannot fake Jog approval or reset the cap.**
- `ls TESTS-RESULTS/2026-11-10+GH-1243/` lists no `jog/` directory.
- merge_cleanup.py:919–933: a mapped Jog row with no committed `…/jog/*/receipt.json` gets only "warn: … not a Jog delivery — row left as-is". `jog land` is never invoked for it, so there is no completion, no `landing.json`, and no cap or counter change.
- If `jog land` is called directly, jog_run.py:1185–1186 refuses with "has no committed approved Jog receipt bundle". :1175–1177 additionally requires `outcome == "approved"`, a green gate and a valid pass receipt.
- So the failed/cap-stalled 1243 queue row stays as it is. That is truthful.
- Open contract: how that stale row is later retired, since it stays failed/cap-stalled after a non-Jog merge. That needs an explicit operator `jog` status action or the GH-1108 delivery-2 path. I made no live queue writes.

VERDICT: FAIL
Basis: The consult change is sound: separation holds, missing, empty, timeout and launch failures all fail closed, citation handling and attestation are correct, and the fixtures are truthful with no new machinery (Q1–Q3 Pass, two Nits). But the PR's own body declares the published head a8186569 not merge-ready, with three confirmed defects. The corrections (4d991583) are unpushed, unqualified and absent from this packet, and two of them are in dependency #1402. I cannot approve a head its author has disowned. Minor-fix path for the parent: push 4d991583, run the full gate on that exact SHA, re-seed with the defect disposition and the diff, and settle Q4a after #1402 lands. Approval is not a merge gate; fresh live pins and required checks remain mandatory.  [Unverified — no citation]

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
