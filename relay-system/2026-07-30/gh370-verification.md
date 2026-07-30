# RELAY · GH-370 verification: are the five corrections true against the code?
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-30.
-->

NEXT: Producer
STATUS: Approved
ROUND: 3 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
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
6. **Commit only the relay file** (`relay(gh370-verification): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md`
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-30
- Issue: GH-370   ·   PR: #371   ·   Branch: `gh336-round4-retest`   ·   Base: `origin/development@9082328`

### Context — why you are being asked

That doc was reviewed across four rounds by three models (codex r1, agy r2–3, pi+qwen r4). **Every code
citation in all four rounds was verified against `utils/py/_marathon_plan_node.js`, a file that GH-340
has since deleted.** I re-tested the eight findings against the native Python engine that actually ships
and corrected five stale or false claims. **Your job is to check whether my corrections are true** — not
to re-review the GH-336 design, which four rounds already left standing.

Grade the five corrections against the code in this worktree. **Verify each one yourself**; do not take
my summary on trust. That is the entire point of this turn — the last review was wrong precisely because
it trusted citations nobody re-ran.

### Definition of Done — the five claims to check

1. **Call-site note.** The doc now says the seam is the gap between `engine.run(cfg, render_out)` and
   the check/write branch in `utils/py/marathon_plan.py`, and that `_inject_review_lanes` no longer
   exists. Confirm: the function is genuinely gone; `_marathon_plan.py` renders "Review lanes" natively;
   `marathon_plan.py` has no post-render mutation step; the cited line numbers are right; and — the part
   that matters — a sidecar writer really can attach between those two lines.
2. **The `gh` stub must be a file tripwire, not a loud failure.** The doc claims a stub that writes to
   stderr and exits non-zero is *undetectable*, because `_resolve_gh` uses `stderr=subprocess.DEVNULL`
   and folds a non-zero exit into `GH_MODE="off"`. **Reproduce this**, both directions: a stderr stub
   should yield no signal, a file tripwire should record `gh auth status`. If you can make a loud-fail
   stub detectable by some means I missed, that is a finding.
3. **`QP_GH_STATE_FILE` is not a usable env var.** The doc now says it is internal to the Bash twin,
   assigned from `QUEUE_PLAN_GH_STATE_FILE` at `utils/marathon-plan.sh:179`, so exporting it is a no-op
   on both lanes. Check both lanes. Also confirm `QUEUE_PLAN_GH=off` and `QUEUE_PLAN_GH_STATE_FILE` each
   really drive `gh` invocations to zero.
4. **Every line citation resolves.** Check each `#L<n>` reference in the doc points inside its file *and*
   at a line that says what the surrounding prose claims. I checked this by script; check it independently.
5. **The `/10days` narrowing.** The doc no longer says "no executable" (the skill ships `find-doc.sh`,
   `install.sh`, `scan-issues.sh`) and instead says there is no plan-rendering entry point. Confirm none
   of the three renders or fires a plan, so the criterion's logic survives the narrowing.

### Specifically try to break these

- Any **remaining** reference in the doc to deleted code or a pre-GH-340 fact that I missed. I fixed five;
  a sixth is exactly the kind of thing four rounds already proved is easy to leave behind.
- Anywhere my correction is **itself** overstated, or asserts something I did not actually verify.
- Whether the claim "the architecture is unchanged" still holds now that the seam it relied on is gone —
  if the sidecar design has a real problem against this engine, say so plainly.

### Out of scope

Re-litigating the GH-336 design, the churn ratio, or the sidecar decision. Unwired `--check` (#368) and
the relay path parser (#367) are filed separately. **Pre-existing defects in the files you read are in
scope** per the sweep rule above — report them as such.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer · r1

swept file: yes

- [Should] The call-site correction is substantively right, but its `#L181` citation does not support the stated three-way branch boundary: `--check` begins at `utils/py/marathon_plan.py:181`, while `--dry-run` and write begin at `:197` and `:201`. Fix the sentence/link to cite all three branch starts (or say only that the check branch starts at `:181`).
- [Should] The loud-stub correction is substantively right, but its `#L450` link alone does not show either `stderr=subprocess.DEVNULL` or the caught non-zero exit; those are at `utils/py/_marathon_plan.py:451-453`. Widen the citation to `#L450-L453` so the evidence actually matches the claim.
- [Should] Replace the absolute claims that `marathon_plan.py` has “no post-render step … at all” (artifact `:51`, `:420-421`) with “no post-render mutation shim.” The wrapper plainly performs post-render check, dry-run, and copy/write handling at `utils/py/marathon_plan.py:181-205`; the narrower mutation claim is the one the native renderer change proves.
- [Pass] `_inject_review_lanes` is folded into native rendering: `utils/py/_marathon_plan.py:1297-1302` builds the Review lanes section, while the wrapper calls `engine.run(cfg, render_out)` before its branch handling at `utils/py/marathon_plan.py:170-181`.
- [Pass] The hermetic-env correction holds on both lanes: Python reads only `QUEUE_PLAN_GH_STATE_FILE` / `QUEUE_PLAN_GH` at `utils/py/marathon_plan.py:161-164` and resolves forced-off/state-file modes before probing `gh` at `utils/py/_marathon_plan.py:432-453`; Bash assigns internal `QP_GH_STATE_FILE` only from `QUEUE_PLAN_GH_STATE_FILE` at `utils/marathon-plan.sh:179` and resolves those same modes at `:445-450`.
- [Pass] The narrowed helper-script claim holds: `find-doc.sh` is a capture-doc lookup (`skills/10days/find-doc.sh:3-15`), `install.sh` only registers the skill (`skills/10days/install.sh:3-14`), and `scan-issues.sh` only lists a GitHub issue window (`skills/10days/scan-issues.sh:3-11,52-54`); none renders or fires a plan.

Verdict: Changes requested

Handing off to Producer — go to the Producer window and say “take your turn”.

## Producer · claude-a · r1 disposition

**All three `[Should]`s implemented. Nothing declined.** I re-verified each against the code before
acting rather than taking the review on trust — the same discipline this whole issue exists to enforce —
and all three were right.

- [Should 1 — `:181` does not open all three branches] **Implemented.** Confirmed: `marathon_plan.py:181`
  is `if run_mode == "check":`, `:197` is `if run_mode == "dry-run":`, `:201` is the write path's
  `os.makedirs(...)`. My sentence cited one line as though it opened all three. Now cites all three
  separately and states the attach point as "after `:170`, before `:181`."
- [Should 2 — `#L450` does not span the evidence] **Implemented.** Confirmed: `:450` is only the
  `subprocess.run([...])` opening; `stderr=subprocess.DEVNULL` is on `:451` and the `except` that
  converts the failure into `GH_MODE = "off"` is `:452-453`. A reader following my link would not have
  seen the mechanism the claim depends on. Widened to `#L450-L453` with the two spans named inline.
- [Should 3 — "no post-render step at all" is overstated] **Implemented, and it is the best of the
  three.** The wrapper plainly does post-render work — check, dry-run, and copy/write at `:181-205`.
  What GH-340 removed is the post-render **mutation shim**, and that is the only claim the native-render
  change actually proves. Corrected in all three places it appeared (the revision note, the blockquote,
  and CHANGELOG.md). **This is precisely the failure mode I asked you to hunt** — a correction that
  overstates itself — landing inside the correction pass. Recorded in CHANGELOG rather than smoothed
  over.

- [Pass ×3] Noted, and the citations are why they are useful: the folded overlay at
  `_marathon_plan.py:1297-1302` against the wrapper's `engine.run(...)` at `marathon_plan.py:170-181`;
  the two-lane hermetic-env check (`marathon_plan.py:161-164`, `_marathon_plan.py:432-453`,
  `marathon-plan.sh:179` and `:445-450`) — that Bash-side `:445-450` span is evidence I did not gather
  myself; and the three `/10days` helpers read individually rather than assumed.

**Not found, and worth stating explicitly:** you did not turn up a sixth stale pre-GH-340 reference, and
did not challenge "the architecture is unchanged." Both were named as targets in the charge, so their
absence is a (weak) signal rather than silence.

Handing off to Reviewer — please confirm the three corrections landed, then close if clean.

## Reviewer · codex · r2

swept file: yes

- [Pass] The repaired call-site account is accurate: `engine.run(cfg, render_out)` is at `utils/py/marathon_plan.py:170`, with the check, dry-run, and write branches at `:181`, `:197`, and `:201`; native rendering owns Review lanes at `utils/py/_marathon_plan.py:1297-1302`. There is no `_inject_review_lanes` function, and the wrapper’s `:181-205` work does not mutate `render_out`, so a sidecar call can sit after `:170` and before `:181`.
- [Pass] The loud-stub correction is supported by the live code path: `utils/py/_marathon_plan.py:450-453` sends `gh auth status` stderr to `subprocess.DEVNULL` and catches a non-zero exit as `GH_MODE = "off"`; a PATH stub therefore has no stdout/stderr/exit signal propagated, while a file-writing stub is invoked with `gh auth status`. (Per the turn constraint, this was static inspection; I did not execute the source/artifact.)
- [Pass] `QP_GH_STATE_FILE` is internal-only on both lanes: Python accepts only `QUEUE_PLAN_GH_STATE_FILE` / `QUEUE_PLAN_GH` at `utils/py/marathon_plan.py:161-164`; the Bash twin overwrites `QP_GH_STATE_FILE` from the former at `utils/marathon-plan.sh:179`. Both engines select off/stub before either `gh` probe at `utils/py/_marathon_plan.py:432-453` and `utils/marathon-plan.sh:445-450`.
- [Pass] The document’s `#L` anchors resolve to in-range source lines and match their claims: check comparison at `utils/py/marathon_plan.py:187`, Bash state-file assignment at `utils/marathon-plan.sh:179`, gh suppression at `utils/py/_marathon_plan.py:450-453`, call/branch seam at `utils/py/marathon_plan.py:170,181,197,201`, and native Review lanes at `utils/py/_marathon_plan.py:1297`. The three `/10days` helpers do not render or fire a plan: `skills/10days/find-doc.sh:3-15`, `skills/10days/install.sh:3-14`, `skills/10days/scan-issues.sh:3-11,52-54`.
- [Should] One stale line citation remains in the swept document: its “Found during review” bullet says `marathon-plan.sh:54` claims `--check` is a drift guard in `validate.sh`, but `:54` is blank; the quoted claim is at `utils/marathon-plan.sh:67`. Fix the document’s `:54` to `:67`.

Pre-existing defects in the reviewed artifact beyond that stale citation: none found. No remaining reference treats deleted `_marathon_plan_node.js` or `_inject_review_lanes` as live code.

Verdict: Changes requested

Handing off to Producer — go to the Producer window and say “take your turn”.

## Producer · claude-a · r2 disposition

**The one `[Should]` is implemented.** You found the sixth stale citation I explicitly asked for and
could not find myself.

- [Should — `marathon-plan.sh:54` is blank; the claim is at `:67`] **Implemented.** Verified before
  acting: `:54` is a bare `#`, and the drift-guard comment is at `:67`. Corrected, and promoted from a
  bare reference to a real markdown link so it is machine-checkable.

  **Why my audit missed it, which matters more than the typo.** I verified citations by script and
  reported them clean — but the script walked only markdown `(../../path#Lnnn)` links, and this one was
  written as a bare `` `marathon-plan.sh:54` ``. **The audit's scope did not cover the shape the defect
  took**, so it returned "all citations OK" while a wrong one sat in the same file. That is the same
  family as everything this issue is about (#315/#319/#348/#368/#369): *a check that reads as coverage
  while missing the case that matters.* The audit now walks bare `file:line` references too — all nine
  resolve in-range and content-match — and both the script gap and the fix are recorded in CHANGELOG
  rather than quietly patched.

- [Pass ×4] Accepted with the reservation you yourself stated: your loud-stub `[Pass]` is **static
  inspection**, not execution, and you said so unprompted. The executable evidence for that claim is
  mine (a stderr stub producing zero observable output while a file tripwire in the same run recorded
  `gh auth status`), so the two passes are complementary rather than redundant — your reading confirms
  the mechanism at `_marathon_plan.py:450-453`, my run confirms the behaviour. Neither alone would be
  enough, and flagging the limit rather than letting the `[Pass]` read as a live reproduction is exactly
  the disclosure the relay rules are for.

- **"No remaining reference treats deleted `_marathon_plan_node.js` or `_inject_review_lanes` as live
  code"** — this is the sentence the whole issue was opened to be able to say, and it is now said by an
  independent reviewer that checked rather than by the author that wrote the corrections.

Handing off to Reviewer — one confirming pass on the `:67` fix, then close if clean.

## Reviewer · codex · r3

swept file: yes

- [Pass] The repaired out-of-scope citation now resolves and supports its claim: `utils/marathon-plan.sh:67` says `--check` works as a drift guard in `validate.sh`; `PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md:515` links to that exact line.
- [Pass] The five GH-370 corrections remain true against the shipping sources: the removable sidecar seam is after `engine.run` at `utils/py/marathon_plan.py:170` and before the mode branches at `:181`, `:197`, and `:201`; Review lanes render natively at `utils/py/_marathon_plan.py:1297-1302`; and the wrapper only does check/dry-run/write work at `utils/py/marathon_plan.py:181-205`, not a mutation shim.
- [Pass] The `gh`-fixture correction is source-supported: `_resolve_gh` discards `gh auth status` stderr at `utils/py/_marathon_plan.py:450-451` and converts a non-zero status to off mode at `:452-453`; `QUEUE_PLAN_GH_STATE_FILE` / `QUEUE_PLAN_GH` are the Python inputs at `utils/py/marathon_plan.py:161-164`, while the Bash twin derives internal `QP_GH_STATE_FILE` from the former at `utils/marathon-plan.sh:179`. Per the turn constraint I did not execute the source; the live reproduction remains the Producer's logged evidence.
- [Pass] All ten markdown `#L` anchors in the artifact resolve in-range and match their surrounding claims: `PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md:167,247,340,412-416,424,427,515`. The `/10days` narrowing is likewise accurate: `skills/10days/find-doc.sh:3-15`, `skills/10days/install.sh:3-14`, and `skills/10days/scan-issues.sh:3-11,52-54` respectively look up docs, install the skill, and list issue windows; none renders or fires a plan.
- [Pass] No remaining reference presents deleted `_marathon_plan_node.js` or `_inject_review_lanes` as live code: the remaining mentions explicitly mark them historical/deleted at `PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md:33,48-51,420-424`.

Pre-existing defects in the swept artifact: none found.

Verdict: Approved
VERDICT: PASS
Basis: Whole-artifact sweep plus static verification of the cited shipping-source seams, environment inputs, helper scripts, and repaired `marathon-plan.sh:67` anchor.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
