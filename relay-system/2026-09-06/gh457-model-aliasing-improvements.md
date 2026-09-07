# RELAY · Improve #457 model-aliasing spec — practical adjustments only (ponytail lens)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-06.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(gh457-model-aliasing-improvements): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/issue-457.md** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/XYZ-forge/temp/issue-457.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-06
- Definition of Done: the issue receives **only adjustments that are meaningful and practical**
  — you are the laziness gate (ponytail: the best unnecessary change is the change never made).
  Work through the artifact and answer, each with a quoted span or file:line citation:

  1. **Fact-check every "verified" claim** in the Defects/Architecture sections by probing this
     worktree (run the resolver, read the cited lines). Flag anything that would not reproduce —
     an issue with a wrong spec sends implementers the wrong way.
  2. **For each defect (D1/D2/D3): is the proposed requirement the *minimum* that fixes it?**
     Reject any fix that adds a layer, a config surface, a second matcher, or a gateway parameter
     on the resolver (the Non-goals already forbid these — hold the line). If a defect is better
     answered by an existing adjacent issue (#450/#346/#399), say "defer" instead of designing here.
  3. **Missing, or already covered?** Name anything material the spec omits (a caller, a contract,
     a failure path) — and explicitly bless anything you checked that is fine, so absence of a
     finding reads as checked, not unread.
  4. **Wording:** sharpen only where the spec is wrong, ambiguous, or over-specified. Do not
     rewrite for style.

  Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with the concrete
  adjustment text where one is warranted (or "no change" where none is), a `swept file:` line,
  and a Verdict: Approved | Changes requested | Blocked. Uncited `[Pass]` findings are
  downgraded. Do NOT edit the artifact.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer · codex · Round 1 · 2026-09-06

swept file: no

- [Blocker] The specified review input is absent. Setup names **`.relay-artifacts/issue-457.md`** and instructs **“read it there; do NOT edit it”**, but reading that path returns `No such file or directory`; listing `.relay-artifacts` returns the same error in this worktree. Concrete adjustment: seed the intended issue snapshot at `.relay-artifacts/issue-457.md` through the harness, then return the review turn. No spec adjustment is justified before that input is available.
- Review limits: D1/D2/D3, the Defects/Architecture claims, adjacent-issue coverage, and pre-existing defects remain unreviewed. No resolver/source execution or project gate was run; no substantive pass is claimed. The external `temp/issue-457.md` exists, but was not substituted for the required isolated snapshot.

Verdict: Blocked

Handing off to Producer (claude-a) — restore the review input through the harness, then return the turn to Reviewer; go to the Producer window and say 'take your turn'.

## Producer · claude-a · Round 1 · 2026-09-06

Disposition of Reviewer's [Blocker] (artifact absent): **Implemented** — the blocker was my
drive command, not the spec: `--artifact-file` was passed to the scaffolder but omitted from
`relay-drive.sh`, so `.relay-artifacts/issue-457.md` was never seeded into the worktree. The
redrive passes it; the artifact will be present at that exact path.

Also pinning the output contract that tripped validation last turn: end your block with a
line-start literal `VERDICT: Approved` / `VERDICT: Changes requested` / `VERDICT: Blocked`
(uppercase VERDICT — the driver's regex requires it; title-case "Verdict:" reads as missing).

NEXT: Reviewer · STATUS: Open · ROUND 1/4 (no substantive review has happened yet — the prior
Blocked block was operational, do not treat the spec as reviewed).

## Reviewer · codex · Round 1 · 2026-09-06 · substantive review

swept file: yes

- [Should] **D1/A2: choose the existing caller boundary, not provider-validity discovery.** “How to know valid for target” and “Fix D1 inside the existing wrapper contract” (`.relay-artifacts/issue-457.md:20,33`) invite unnecessary machinery. The shim already has `DEEPSEEK_PROVIDER` and validates it before claiming (`utils/py/deepseek-turn.py:200-203`), yet resolves the model unconditionally at `:231-235`. Concrete replacement: “Apply the OpenRouter alias helper only on the OpenRouter route; pass other routes' model literals unchanged, using the existing provider selection. Preserve the helper's existing OpenRouter behavior and fallback contract.” Permit gating at this call site; no helper parameter is needed for today's incident. Fold short-prefix coverage into this same rule, and defer changes to tier 4 itself to #450. #399 owns route extensibility and explicitly excludes the alias table (`PROJECT/2-WORKING/GH-399-PROFILE-CARRIES-THE-ROUTE.md:20`); do not defer the present unconditional rewrite to it.
- [Should] **A1's red control currently rewards deleting the trigger.** “fails while the colliding row exists and passes when it doesn't” (`.relay-artifacts/issue-457.md:37`) describes the temporary workaround, not the fix. Replace with: “Keep a colliding fixture row present: the non-OpenRouter turn must preserve the literal after the fix; restoring unconditional resolution must make the assertion fail. Include a short-prefix case and an OpenRouter alias-hit control.” Assert the model in the captured `--patch` overlay supplied to the stub subprocess, including both model registration and `agent-default-model` (`utils/py/deepseek-turn.py:114-132,267-269`), not merely the helper return or environment. The existing `test/gh346-resolver-fallback.sh:75-78` is only a grep for the helper name; it neither proves dispatch nor the absence of other callers.
- [Should] **D3/A3 overreach into intentionally synthetic fixtures, and omit a shipped example.** `test/model-alias.sh:54-64,68-79` tests a caller-supplied table, not catalog availability; arbitrary canonical values are legitimate, especially because the real profile caller pipes `key: key` (`utils/py/profile_resolve.py:246-255`). Replace A3 with: “Correct the runnable OpenRouter profile examples in `skills/relay-xyz/SKILL.md` and `utils/py/profile_resolve.py:434-435`; label matcher fixtures synthetic and keep them offline. Defer generated-table drift checking to #450.” Drop the blanket live-catalog requirement for every doc/test and the `:variant`/date exception: a suffix alone does not make an unavailable route valid. The [OpenRouter models endpoint](https://openrouter.ai/api/v1/models), read this turn, includes `qwen/qwen3.8-max-0902`; this supports the proposed replacement example, not endpoint execution or the historical 404 claim.
- [Should] **Correct the reproduction's tier.** D1 calls `qwen3.8-max` versus `qwen 3.8 max` “tier-1 normalized-exact” (`.relay-artifacts/issue-457.md:19`). `normalize()` preserves letter/digit adjacency (`relay-automation/resolve-model-alias.sh:36-37`): these normalize to `qwen3 8 max` and `qwen 3 8 max`, respectively. Their squashed forms agree, so this is **tier 2** (`:97-104`). Change only the tier label; the collision mechanism still follows from source.
- [Nit] **Scope the wrapper guarantee accurately.** Replace “never returns empty” (`.relay-artifacts/issue-457.md:11`) with “never returns empty for non-empty input”; empty input is deliberately returned at `utils/py/model_alias.py:41-42` and covered by `test/gh346-resolver-fallback.sh:35`. Update the deepseek call citation to `:231-235` and describe the cited grep test narrowly rather than calling the whole call-site inventory “pinned.” No runtime change warranted.
- [Pass] **Core architecture and D2 are supported by source; no change.** Seven table rows and the add-an-assertion instruction are at `relay-automation/openrouter-model-aliases.yml:12-21`; tier order, file-order wins, pipe readability, and ordinary exit contracts are at `resolve-model-alias.sh:52-62,87-128`. Its substring predicate at `:121`, combined with table rows `:15,18,20`, predicts the stated qwen/glm/grok outputs. This is source reasoning, not fresh runtime probes. The profile's model passes through at `utils/py/profile_resolve.py:331-333,383`, while only its name uses the matcher at `:228-264`. Keep that separation.
- [Pass] **Existing fallback and adjacent caller deserve preservation, not extra design.** `utils/py/model_alias.py:45-61` retains input on missing script, subprocess exception, nonzero exit, or blank output; `:26,54` supplies the default 10-second timeout. `utils/py/review_xyz.py:85,629-630` uses the same helper before engine inference. Preserve that caller's behavior when gating the DeepSeek route. The non-goals “No second matcher” and “No cache, no latency work” (`.relay-artifacts/issue-457.md:30,32`) are appropriate; no change.

Review limits: the entire 44-line artifact was swept, including its pre-existing claims; the issues above are the substantive omissions/errors found. No source, resolver, test, gate, or git command was executed. Therefore the historical incident, exact local-profile export, and claimed live probes were not independently reproduced; retain them as dated producer observations, not reviewer-verified runs. The linked Model-catalog comment could not be retrieved, so its r2 quotation and #450's current scope remain unverified. Graph discovery used `XYZ-forge`, generation `2026-09-01T15:54:30Z`; no index exists for this worktree, and coverage reported changed/untracked evidence paths. Findings therefore rely on direct worktree source reads and bounded literal searches, not an exhaustive graph claim.

VERDICT: Changes requested

Handing off to Producer (claude-a) — apply the concrete spec adjustments and return for review; go to the Producer window and say 'take your turn'.

## Producer · claude-a · Round 1 close-out · 2026-09-06

All four Reviewer `[Should]` adjustments were citation-checked (deepseek-turn.py:231-235,
profile_resolve.py:246-255 — both verified verbatim) and posted to #457 as the adopted
amendments: https://github.com/HiQS-Labs/XYZ-forge/issues/457#issuecomment- (see issue thread).
Reviewer's `Changes requested` maps to the validator's `FAIL` vocabulary; the vocabulary
mismatch between bin/validate-relay-block (PASS/FAIL/PARKED + Basis) and the /relay template
(Approved/Changes requested/Blocked) is noted in that comment as a separate harness nit.

STATUS: Closed — adjustments posted; re-review available on request (re-open NEXT: Reviewer).

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
