# RELAY · GH-1468 final QA: baseline skill (PR #1469)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 2

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
6. **Commit only the relay file** (`relay(gh1468-final.codex): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review (all at this branch's HEAD; `git diff origin/development...HEAD` is the change):
  - `skills/3-weekly/baseline/SKILL.md`
  - `skills/3-weekly/baseline/scripts/build_deck.py`
  - `skills/3-weekly/baseline/assets/deck-template.html`
  - `skills/3-weekly/baseline/assets/example-spec.json`
  - `skills/3-weekly/honest/SKILL.md` (trigger and sibling-list label updated)
  - `ARCHITECTURE.md` (one Skills Index row)
  - `PROJECT/1-INBOX/GH-1468-BASELINE-SKILL.md`, `TESTS-RESULTS/2026-11-14+GH-1468/` (capture doc and manual check receipt)
- Reviewer: codex   ·   Producer: gemini-a
- Started: 2026-11-14
- Definition of Done: the acceptance list in `PROJECT/1-INBOX/GH-1468-BASELINE-SKILL.md` (issue #1468).
- Operational envelope: a local, single-user skill. A model writes a JSON spec; a ~220-line Python script
  (system `python3` 3.9, standard library only) validates it and fills one static HTML template that a
  presenter opens from disk. No server, no network, no multi-user state. Grade against that envelope: do
  not ask for enterprise fail-safes, and do not ask for a new test suite, gate or runner (GH-831) — a new
  suite in the diff would itself be a finding.

### Questions for the Reviewer (answer each, with `file:line`)
1. **Validator.** `build_deck.py` claims to refuse, with exit 2: a missing required field, an unknown grade
   or ask type, a question that is not exactly one question, a field over its cap, a checked claim with no
   `ref`, an unverified claim with no `settle`, and a `change`/`carve-out`/`fix` ask with no confirmed or
   partly-confirmed claim. Is each claim true in the code? Name any spec that passes `validate()` and then
   breaks or mis-renders in `deck-template.html` (wrong type, missing optional object, empty list).
2. **Injection & serialization.** Source text comes from issue threads and is untrusted. Can any spec field
   put markup, script or a non-http link into the built page, or break `JSON.parse` (including `</script>`,
   `<!--`, or literal `__DECK_DATA__`/`__DECK_TITLE__` markers)? Check the `\u003c` escaping, the one-pass
   marker substitution, the template's use of `textContent`, and the `link()` URL test.
3. **What rejects a bad deck & completion state.** The skill's rules are "one slide, one question" and
   "facts before asks", plus the last slide counting open questions across `heard` + `items` (`items.length * 2 + 1`).
   What in the delivered code enforces each, what is prose-only, and are the recorded controls in
   `TESTS-RESULTS/2026-11-14+GH-1468/smoke.md` (including `a`-`i`) truthful and complete?
4. **Skill text accuracy.** Are the commands in `SKILL.md` valid as written (the `gh` field lists, the
   Step 0 ignore snippet, the builder invocations)? Do the ask-type table, the grade table, the spec
   schema and the slide table match `build_deck.py` and the template (including `decide`)? Do the relative
   links resolve?
5. **Template behaviour.** Read the template script as code: slide construction, the item-aware storage id,
   answer state saved to `localStorage`, completion count (including `heard`), Markdown export, keyboard and
   hash navigation, print styles. Report concrete defects only (an input or key sequence that misbehaves).
6. **Scope and complexity.** Is anything over-built or under-built for the envelope? Is the `honest`
   trigger and sibling-list change sufficient, given that file's body still titles itself "Baseline"?
7. **Project-agnostic content.** This repository is public. Does any added line name a private project,
   person, repository or channel? The example spec is meant to be fictional.

Known and disclosed by the Producer, not findings by themselves: clipboard button and cross-reload `localStorage`
were not exercised interactively; the `honest` body still uses "Baseline" as its heading and output frontmatter key.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
