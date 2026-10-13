# RELAY · GH-1046 plan QA: skills-army-hq copy-not-link visibility
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-12.
-->

NEXT: Producer
STATUS: Approved
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
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1046-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1046-COPY-NOT-LINK.md` (the plan; sections Ask, Acceptance, Recon, Plan, Rating rationale). Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1046
- Source paths the plan changes (read them in full): `skills/3-weekly/skills-army-hq/SKILL.md`, `skills/3-weekly/skills-army-hq/scripts/intake.py` (`source_record`, `render_catalog`, `main` list/add/update branches), `skills/3-weekly/skills-army-hq/scripts/sync.py` (`main`). Also `skills/3-weekly/skills-army-hq/README.md:61-75`, `test/test_deploy_skills.py`, `test/skills-army-hq.sh`, `utils/ci-route.sh` (skills-army-hq subsystem), `AGENTS.md` *No new tests* (GH-831).
- Operational envelope: a local single-operator CLI (two ~800/~260-line Python scripts) plus a skill doc. This is a clarity change: one short SKILL.md block and a few human-readable stderr lines from receipt data that already exists. Grade against the stated requirements and commensurate complexity; do not ask for new state, JSON schema changes, flags, tests, or enterprise machinery. Read-only probes only (no validate.sh / test/*.sh / pytest in the relay worktree).
- Questions:
  1. Are the Recon claims grounded? Do receipts really carry `source`/`commit`/`dirty` (`intake.py` `source_record`), and does every stdout consumer (tests, other scripts, docs) parse JSON such that stderr-only additions are safe? Cite any consumer that reads stderr or expects empty stderr for `list`, `add`/`update` preview or `sync.py --status`.
  2. Is any requirement from the Ask missing (copy not link; source path + revision; which app roots link; consequences: any clean checkout of the merged revision, deletable after intake, update needs a newer source)?
  3. Does the plan extend the existing writer/helpers (reuse `render_catalog`'s link check via a shared `linked_targets`) rather than building a parallel path? Is putting `copy_line` in `intake.py` and importing it from `sync.py` (which already does `import intake as shared`) right?
  4. Are there receipts without `source`/`commit` (e.g. `catalog`-adopted or `init --adopt-existing` skills) and does the plan's fallback text handle them truthfully?
  5. Is the verification sound under GH-831 (existing `skills-army-hq.sh` suite + recorded manual check + red control on the existing suite)? Is the red control (temporarily print to stdout in `list`/`--status`) actually caught by an existing test — i.e. does any existing test parse `list` or `--status` stdout?
  6. Rating `55/40/50/85`: grounded?
- Flag anything wrong, missing, or over/under-engineered, citing file:line.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-12
- Definition of Done: the plan, if executed, satisfies the issue's Goal 1-4 with the smallest change, keeps stdout JSON byte-identical, adds no tests/state/deps, and its acceptance checks can fail. Approve (STATUS: Approved) when that holds.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The small stderr-only design is appropriate, but the plan leaves ordinary missing-provenance inputs unspecified, overstates the scope of its link summary, and does not yet establish byte-identical stdout. These need plan clarifications, not new machinery.
swept file: yes

Reviewed the entire plan, SKILL.md, intake.py, sync.py and test/test_deploy_skills.py, plus the named README, wrapper and routing surfaces. No additional pre-existing defect requiring expansion of this clarity change was identified. Verify-tier graph lookup was attempted: all 84 projects enumerated; this worktree has no index. Nearest `XYZ-forge` index is generation `2026-09-01T15:54:30Z`, a different checkout; symbol search returned zero and coverage marked the skill/test paths `not_tracked` and ci-route `metadata_changed`. Findings therefore use direct current source, not graph completeness claims.

- **[Should] R1 — Specify truthful provenance fallbacks (plan lines 37–39, 63–65).** `source_record` supplies source/commit/dirty for add/update (`intake.py:205`), but plain init creates a manager receipt without commit/dirty (`intake.py:717`), catalog adoption has neither source nor commit (`intake.py:815`), and inventory can include an unadopted skill (`intake.py:289`). Reuse the catalog's existing `manual/unadopted` and `unknown` conventions (`intake.py:398`); iterate actual inventory with an empty-receipt fallback. Describe these as recorded provenance, not a newly verified source revision. `init --adopt-existing` does call source_record (`intake.py:655`), but records the local Pulse collection/revision, not the original author's checkout. Add these cases to the existing manual verification; no new receipt fields.
  Observed input: the receipt literal at `intake.py:717` has `source` but no `commit`; the `setdefault` literal at `intake.py:817` has neither.
  Affected scope: per-skill human summaries for initialized, catalog-adopted and unadopted skills.
  Falsifier: a temp collection with those receipt shapes must list/status successfully with explicit unknown fields; an ordinary imported receipt must still display its recorded source, revision and dirty marker.

- **[Should] R2 — Qualify the link summary's scope (plan lines 63–65).** The proposed helper checks only enabled targets but labels its answer `linked from: ...|none`. Disabling a target changes config without removing its symlinks (`intake.py:797`); later sync withdraws them (`sync.py:117–147`). Thus a disabled-but-still-linked app can be reported as no links. Smallest fix: label the line `linked enabled targets` and state that disabled/removed targets may retain links until sync; preserve the existing catalog predicate and format. No new filesystem discovery is requested.
  Observed input: the existing sequence at `test/test_deploy_skills.py:374–377` removes/disables target configuration before separately applying sync to clear links.
  Affected scope: human summaries between target disable/removal and link reconciliation.
  Falsifier: with an existing matching symlink and its target disabled, the summary must not imply that no app can still read the copy; after sync the link should be absent under existing behavior.

- **[Should] R3 — Make stdout preservation measurable (plan lines 40–42, 73–77).** Existing JSON parsing establishes syntax and selected values, not byte identity. `list` calls at `test/test_deploy_skills.py:171,222,315` discard stdout; add/update previews likewise lack JSON assertions (`:240,322`). Amend the planned manual check to capture nonempty baseline/candidate stdout on the same unchanged temp collection for list, status, add and changed-update previews, compare bytes, and assert expected stderr text separately. Run all suite/red-control work in a disposable full clone, not just the final gate. No test edits required.
  Observed input: `test/test_deploy_skills.py:62–68` checks return code only; the list calls above do not inspect its returned output.
  Affected scope: the stated byte-identical stdout acceptance criterion across the four changed command paths.
  Falsifier: changing only JSON indentation must fail the manual byte comparison even though json.loads succeeds; a stdout human line must also fail it.

- **[Pass] Reuse, core requirements and rating scale are proportionate.** Plan lines 58–62 cover copy/link, disposable clean merged checkout, and explicit newer-source update. `sync.py:17` already imports intake as shared, and `intake.py:379–399` owns catalog link rendering, so the shared helper is the right seam. The qualitative `55/40/50/85` rationale (plan lines 81–86) fits the reported single confusion incident and small scope; recurrence and related-issue history were not independently queried.
- **[Pass] A status stdout red control has an existing consumer.** `test/test_deploy_skills.py:581,617,622` explicitly json.loads `--status` stdout. Use that named test/path for the existing-suite red control; do not claim a list-only mutation is covered. Existing stderr checks use substring assertions (`:586–587,610`), not empty-stderr equality; the wrapper runs this file (`test/skills-army-hq.sh:16`). The inspected standalone smoke reads exit codes/substrings (`test/gh620-skills-army-mini-sync.sh:192–215`), not exclusively JSON, which also narrows the Recon wording. No empty-stderr dependency was found in these inspected consumers.
- **[Unverified — needs clone run]** No suite, executable fixture, mutation probe or git command was run. Runtime green/red sensitivity and stdout comparisons remain implementation evidence to obtain; this is plan QA only.

Handing off to Producer (claude-a): clarify R1–R3 in the plan and log each disposition; go to the Producer window and say 'take your turn'.

### Producer · Round 2 · claude-a

- R1 — **Implemented.** Plan step 2 now reuses the catalog fallbacks (`manual/unadopted`, `unknown`), iterates actual inventory with an empty-receipt fallback, labels it "recorded source", and names the init / catalog / unadopted / adopt-existing receipt shapes; the manual check covers them.
- R2 — **Modified.** Rather than only relabelling, `linked from` checks every configured target (same `is_linked` predicate as the catalog) and marks disabled ones `(disabled)`; removed targets are out of config, so the explainer says sync withdraws their owned links. Catalog output unchanged.
- R3 — **Implemented.** Step 6 adds a base-vs-candidate `cmp` of nonempty stdout for list, status, add preview and changed update preview on one temp collection, separate stderr assertions, an indent-change red control, and runs everything in a disposable full clone.

Handing off to Reviewer (codex) for Round 2.

### Reviewer · Round 2 · codex

VERDICT: PASS
Basis: R1–R3 are resolved at plan level. The proposed change satisfies the four stated goals through existing receipt and link machinery, preserves the stdout contract, and specifies falsifiable verification without new tests, state or dependencies. Approval covers the plan, not implementation or runtime results.
swept file: yes

Re-read the entire plan, SKILL.md, intake.py, sync.py and test/test_deploy_skills.py, plus the named README span, wrapper, routing entries and standalone smoke consumers. No additional pre-existing defect requiring expansion of this clarity change was identified. Graph tools and tool-discovery tools are unavailable in this turn's tool inventory; current source reads were used instead. No graph generation or exhaustive consumer-coverage claim is made.

- **[Pass] R1 resolved — truthful recorded provenance.** Plan `PROJECT/1-INBOX/GH-1046-COPY-NOT-LINK.md:63–70` specifies actual inventory, empty-receipt handling, `manual/unadopted`, `unknown`, and the local-Pulse meaning of adoption receipts. These match `intake.py:213–216`, `:289–301`, `:392–393` and the init/catalog receipt constructors. The summary need not inspect or retain the original checkout.
- **[Pass] R2 modification accepted — bounded link observation.** Plan `:63–72` reuses the catalog's exact symlink-text predicate (`intake.py:386–390`), checks all configured targets and marks disabled ones. It explicitly excludes removed configuration and requires an explainer about withdrawal of owned links. That is a proportionate alternative to the enabled-only label; reconciliation already handles receipts for removed/disabled targets (`sync.py:117–150`). No new discovery or ownership state is needed.
- **[Pass] R3 resolved — measurable stdout preservation.** Plan `:79–90` requires nonempty base/candidate byte comparisons on the same collection for all four changed paths, separate stderr assertions, and controls for formatting drift and stdout contamination. `test/test_deploy_skills.py:581`, `:617` and `:622` parse status JSON, while `:62–68` enforces exit status for the list/status calls. The suite's stderr assertions at `:586–587` and `:610` are substring checks; the inspected smoke at `test/gh620-skills-army-mini-sync.sh:192–215` uses exit codes/substrings rather than empty-stderr equality. This supports the stderr-only design within the inspected consumers.
- **[Pass] Scope, reuse and core requirements remain sound.** Plan `:58–62` covers physical copies, clean merged source checkout, deletion after intake and explicit newer-source updates. `sync.py:17` already imports intake as shared; plan `:63–78` extends that seam and leaves catalog/JSON formats alone. The qualitative rating at `:95–100` is proportionate to the reported incident and small implementation; its recurrence and related-issue history remain reported inputs, not independently verified facts.
- **[Nit] Recon shorthand is broader than its evidence.** Plan `:40–42` says the test parses “that JSON”; it parses status output, while several list/preview calls check only exit status. The precise acceptance procedure at `:81–90` already closes the gap, so this does not block execution. Also preserve the existing unchanged-update early return (`intake.py:775–776`): no copy is planned there.
- **[Unverified — needs clone run]** No runtime suite, executable fixture, mutation probe or git command was run. The green suite, red controls, stderr content and byte comparisons must be obtained in the disposable full clone required by plan `:79`, with retained provenance. No runtime success is inferred from source inspection.

Relay closed (Approved), no further turn needed. Producer (claude-a) may proceed with the approved plan and its recorded verification requirements.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
