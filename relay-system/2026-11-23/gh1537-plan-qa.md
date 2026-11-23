# RELAY · GH-1537 Plan QA: pre-push own-diff routing for development merges
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
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
     A `[Blocker]` must cite an observed failure.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1537-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1537-PREPUSH-OWN-DIFF-ROUTING.md` (the plan; no code yet)
- Reviewer: codex (gpt-6-astra, reasoning effort high)   ·   Producer: claude-a
- Started: 2026-11-23
- Definition of Done: the plan satisfies issue #1537 plus the KS-12 entry of arc #1541 with the smallest
  change that works, grounded in the real hook code.

Issue #1537 (operator-approved policy 2026-11-19): a push whose only new integration content is
`development` merged into the branch is classified by the branch's own diff (merge-base to head)
through the existing `utils/ci-route.sh`, and the final landing still gets a full gate. Correction
comment on #1537: `githooks/pre-push:91` is only a comment; the mechanism is the update-range diff
`git diff --no-renames --name-only "$remote_sha" "$local_sha"`, so a development merge drags
development's code paths into the range. KS-12 (#1541) adds: classify the FINAL TREE against the
verified integration parent so conflict-resolution and evil-merge edits count; use it only for
`route=docs`; refuse it for pushes to `development` or `main`; keep live `ls-remote` freshness,
per-ref checks, rename/deletion handling and the ambiguous-history fallback. Red controls: a docs
branch with a merge whose code conflict resolution routes `full`; a merge from another branch routes
`full`; a stale base routes `full`. Green: a pure docs branch with a merge routes `docs`.

Operational envelope: grade against the stated requirements, commensurate complexity, and this repo's
own threat model. XYZ-forge forbids new tests (AGENTS.md, GH-831); verification is existing suites plus
a manual check with a red control under `TESTS-RESULTS/`. This is a gate/hook surface: do not suggest
deferring a finding; do not ask for a new suite or machinery beyond the plan's non-goals.

**Step A — paraphrase first (GH-1414).** Before opening any other file, read ONLY the plan doc and
write 2-5 sentences each under **What this proposes** and **How the existing system works, per this
document**, plus a short **What it's not**. Label inference as inference.

**Step B — source-backed check.** Then read `githooks/pre-push` in full, `utils/ci-route.sh`
(the `push` mode and the docs/full classification), `test/gh544-pre-push-gate.sh` (how the hook is
driven against a stub `validate.sh`) and `AGENTS.md` (No new tests). Answer:
1. Is the soundness argument right? For which inputs does classifying `merge-base(tip, local)..local`
   (final tree) while accepting only `route=docs` still let code reach a push ungated, or wrongly
   force `full` where it should not? Try: octopus merges, a merge whose first parent is development,
   a rebased branch, a branch that already merged an older development, a submodule or mode change,
   renames/deletions (`--no-renames` is load-bearing), multiple refs in one push.
2. Is the merge-parent check (`git rev-list --merges --parents remote..local ^tip`, every non-first
   parent an ancestor of the tip) correct and sufficient for "a merge from another branch routes full"?
   Is the `mbs` not-already-an-ancestor-of-`remote_sha` gate right, and does it skip the network probe
   on ordinary pushes?
3. Freshness: does using the local tracking ref as a hint and then proving equality with the live
   `ls-remote` tip (shared `probe_integration_tips`) keep GH-487's guarantee? Does extracting the probe
   into a cached function change first-push behaviour (the `_base_note`, the `return 1` paths)?
4. Is carrying `rref` as a third field in `_real_ref_pairs` safe for every reader in the hook
   (`:68-78`, `:131`, `:180`, `:306`)? Name any reader missed.
5. What prevents an unchanged, unfixed candidate from being reported delivered? Is the red/green manual
   check (base `5964566ef` routes `full`, candidate routes `docs`, plus the controls) a real rejection,
   and are the controls sufficient and each discriminating?
6. Is anything over-built or missing for the envelope? Is the CHANGELOG entry warranted?

Cite `file:line` for disagreements. End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, a Basis, and
set STATUS to Approved only on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
