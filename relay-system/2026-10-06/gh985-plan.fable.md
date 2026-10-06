# RELAY · GH-985 Claude optimization plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-06.
-->

NEXT: Producer
STATUS: Approved
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-985-claude-optimization-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **PROJECT/2-WORKING/GH-985-CLAUDE-WORKHORSE.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-985-CLAUDE-WORKHORSE.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: Fable   ·   Producer: Producer
- Started: 2026-10-06
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

Operational envelope: user-selected Fable low-effort independent plan review of a two-file text/comment change in existing workhorse; no new gate/test/mod/loop detector. Read full canonical plan, runtime-recon.md, workhorse SKILL.md and stop-hook.sh. Plan author was a separate Fable turn; review independently. Verify narrow scope, concrete mismatch, official runtime claims, preserved predicate/fail-open/session/authorization boundaries, ratings and honest acceptance/CI routing. Grade current revised canonical plan; fable-plan.md is original authorship evidence with adjudicated factual gaps, not the build plan. Grounded official sources are links in runtime-recon.md. Do not use git, execute tests, modify source, or expand scope; write only this relay. Require cited whole-file sweep, VERDICT PASS/FAIL/PARKED and Approved only if no unresolved Blocker/Should. Harness owns commit/token cleanup; report final handoff.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 (Fable)

Scope reviewed: current canonical `PROJECT/2-WORKING/GH-985-CLAUDE-WORKHORSE.md` (130 lines), graded against the operational envelope; `fable-plan.md` read only as authorship evidence. Probes were read-only (`sqlite3` select, `rg`, `sed`, `python3 json.load`); no git, no validate/test runs.

swept file: yes — whole-file reads of `skills/2-daily/workhorse/stop-hook.sh` (51 lines) and `skills/2-daily/workhorse/SKILL.md` (377 lines). No pre-existing defect found in either beyond the wording mismatch the plan targets; `SKILL.md:24-25` hook command paths are the installed-link paths, not repo paths, and are out of this plan's scope by its own Non-goals.

- `[Pass]` Mismatch is concrete, not generalized. `stop-hook.sh:47-48` emits "mark it [!] (with the exact blocker) or [-] (parked, with its pointer)"; `SKILL.md:90` "Parking must not silently reduce authorized scope", `:106-107` "only explicit user deferral can remove required work", `:113` "Stop only for verified completion, explicit user pause/cancellation, or a concrete external blocker", `:322` "`[-]` is not an escape from required scope". All four citations land on the quoted lines.
- `[Pass]` Predicate and fail-open boundaries cited correctly and preserved by the Bet. Predicate `stop-hook.sh:40-43` (`startswith("- [ ]")` → block); fail-open `:9` (no python3), `:12` (`|| exit 0`), `:16-22` (bad JSON / bad session id), `:41-42` (unreadable checklist → `continue`), `:49-51`. Step 2's "lines 9-44 and 49-51 unchanged" check covers every one of them.
- `[Pass]` SKILL.md anchors verified: frontmatter Stop wiring `:17-26`; Claude-only/syntax-only disclosure `:86-88`; "Instructions versus runtime enforcement" paragraph `:123-132` (line 133 is blank, 134 is `---`, so "after line 133" is a valid insertion point).
- `[Pass]` Ratings match the ledger. Probe: `sqlite3 releases.db "select gh_number,doc_path,rating_pri,rating_sev,rating_appeal,rating_effort from roadmap_items where gh_number=985"` → `985|PROJECT/2-WORKING/GH-985-CLAUDE-WORKHORSE.md|65|45|50|85`, matching plan `:117-119`. Rating prose is honest ("no measured incident rate").
- `[Pass]` Prior-evidence claim holds. `TESTS-RESULTS/2026-10-06+GH-983/claude-compatibility.json` `hook_checks[]` records `case: open` → `decision: block` with the current reason bytes (including "(parked, with its pointer)") and `case: checked` → empty output, as plan `:44-45` states.
- `[Pass]` Cap claim repo-grounding is as stated. `rg -n '8-consecutive|consecutive-continuation'` excluding PROJECT/TESTS-RESULTS/relay-system → exactly one hit, `stop-hook.sh:7`. The plan correctly relies on the official Stop doc via `runtime-recon.md:5` (eight-continuation cap, tool-call reset, StopFailure ignores decision output, Stop not run on user interrupt, `/goal` optional/explicit). Plan `:29`, `:52`, `:54` match that recon text word-for-word in substance. Not independently refetched this turn; grounded source is the link in runtime-recon.md per envelope.
- `[Pass]` CI routing claim is honest. `utils/ci-route.sh:65-69` classifies `*.md`, `PROJECT/*`, `TESTS-RESULTS/*` as docs and any `skills/*` path with no `subsystem_of()` match as docs; `workhorse` is not in `subsystem_of()` (`:40-53`), so `stop-hook.sh` and `SKILL.md` route tier 1 as plan step 4 says. `.github/workflows/ci.yml:11-16` triggers `pull_request` only on `[main, development]`, so plan step 6's "dispatch if automatic base filters omit it" is correct for a PR targeting PR #984's branch.
- `[Pass]` Scope and boundaries: Non-goals `:70-74` exclude predicate, fail-open, session scoping, config, mods, loop detectors, trust; Bet `:49-54` is text-only; Mod rejection `:63-64` cites GH-831; reversibility Easy with `git revert` rollback `:66-68`. Roles `:76-80` keep reviewer write-scope to the relay receipt.
- `[Nit]` Acceptance row "Skill names the Claude hook's limit in one place" (`:111`) is literally unmeetable: `SKILL.md:86-88` already discloses the limit, and the new sentences after `:133` make a second place. Fix: reword to "Skill's runtime-enforcement paragraph names the Claude hook's behavior, limit and reason-text alignment; `:86-88` disclosure unchanged."
- `[Nit]` Step 6 / Validation limits should state that a `workflow_dispatch` run is routed `route=full tier=3` unconditionally (`utils/ci-route.sh:101-116`, "operator-initiated full run"), so the hosted run for the stacked head will be a full gate by design, not the tier-1 documentation route from step 4. Without that line the executor may read the tier mismatch as a routing defect.
- `[Nit]` Step 3a/3d wording assertion: name the literal string the red control must flip on (e.g. absence of `(parked, with its pointer)` and presence of a fixed contract phrase) so 3d is mechanical rather than a judgment call.
- `[Unverified — needs clone run]` Step 2 syntax checks (`bash -n`, heredoc compile) and step 3 hook probes against the *new* bytes; GH-983 evidence covers only the current bytes. Correctly deferred to the build and final-QA stages by the plan itself.
- Unverified by design, as the plan flags: PR #984 branch name and development base `8ec99b60…` (`:22-23`, "re-verify before publication"). Stack base `3c9bfa8c…` matches the visible HEAD~3 commit in this worktree's log snapshot.

**VERDICT: PASS**
**Basis:** The plan names a concrete, cited mismatch, confines the change to two text spans plus two-to-three doc sentences, preserves the block predicate and every fail-open path by explicit line-range diff, states official runtime limits consistent with the grounded recon, keeps ratings equal to the ledger row, and routes CI honestly. The three Nits are plan-wording clarifications the Producer may apply or disposition at accepted-start; none changes behavior, so none blocks Approved.

Handing off: relay closed (Approved). Producer: disposition the three Nits in the canonical doc if desired, then proceed to exact-row accepted-start and Agy build per plan step 2. No further Reviewer turn needed on this relay.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
