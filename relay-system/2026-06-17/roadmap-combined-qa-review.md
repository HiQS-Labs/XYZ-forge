# RELAY · Planning-doc QA review — PROJECT/2-WORKING/ROADMAP-COMBINED.md (headless)
<!--
  Driven by relay-automation (tick RELAY-QA token + codex-turn.sh headless).
  Whose-turn is the RELAY-QA tick task, NOT the NEXT line (NEXT is a human mirror).
  STATUS is the terminal signal. Reviewer = Codex (headless CLI); Producer = claude-a (orchestrator).
-->

NEXT: — (closed; RELAY-QA done)
STATUS: Reviewed
ROUND: 0 / 1

## ▶ TAKE YOUR TURN — tick-native
1. **Read this whole file** carefully, then read the artifact and its sources (see Setup).
2. **Take the token:** `./bin/tick claim RELAY-QA --agent codex --paths relay-system/2026-06-17/roadmap-combined-qa-review.md`, then `./bin/tick ping RELAY-QA --agent codex`.
3. **Do your role's work** (Reviewer): produce a QA review of the planning doc against the THREE concerns in Setup. Give **graded findings** (`[Blocker]` / `[Should]` / `[Nit]` / `[Pass]`) each tied to a concern, plus a single **Verdict:** line, plus an explicit answer to Concern 3 (worthwhile/viable vs. burning time).
4. **Append ONE block** at the bottom (`### Round 1 · Reviewer · codex · <timestamp>`).
5. **Close:** set `STATUS: Reviewed` here **and** `./bin/tick done RELAY-QA --agent codex`. (No Producer round needed — the orchestrator disposes findings out-of-band.)
6. Do NOT git push and do NOT edit any file other than THIS one — the harness commits file-scoped for you.

## Setup
- **Artifact under review:** `PROJECT/2-WORKING/ROADMAP-COMBINED.md`
- **Source docs it claims to synthesize** (frontmatter `synthesizes:`):
  - `PROJECT/1-INBOX/LOOPS.md`
  - `PROJECT/2-WORKING/COST-OBSERVABILITY-PLAN.md`
  - `PROJECT/1-INBOX/MARATHON.md`
  - `ROADMAP.md`
- **Ground-truth for current state:** `git log --oneline -25`, `CHANGELOG.md`, the relay-automation scripts (`relay-automation/*.sh`), and `bin/tick`.

### The three concerns to review against
1. **Status accuracy.** Does the doc's status (the Status table + per-phase `Status:` lines + checkbox `[x]`/`[ ]` marks) accurately reflect the *actual* current state of the projects? Cross-check every "shipped/done ✅" claim against `git log`, `CHANGELOG.md`, and the actual files/tests on disk. Flag any phase marked done that isn't, or marked not-started that actually has work landed, and any checkbox that disagrees with reality.
2. **Synthesis fidelity.** Does the combined doc faithfully and completely combine the four standalone source docs? Read each source. Flag: content in a source that the combined doc dropped or misrepresented; claimed sources that are missing/empty; and any place the combined doc contradicts its source.
3. **Worth-it sanity check.** Step back: is this whole effort (cost-observed marathon loops + adversarial hardening) worthwhile and viable, or is it burning time? Consider scope vs. the value delivered, whether the remaining phases are realistically achievable, and whether anything is over-engineered or a dead end. Give a direct recommendation.

## Ground rules
1. Whose-turn = the tick `RELAY-QA` token.
2. One block appended per turn. Never edit earlier turns. Edit ONLY this file.
3. Be specific: cite file:line or commit hashes for every status/synthesis finding so the orchestrator can verify.

## Roles
- **Reviewer (codex)** — graded QA findings against the 3 concerns + verdict; cites evidence; does NOT edit the artifact or sources, only this relay file.
- **Producer (claude-a)** — orchestrator; disposes findings and reports to the operator out-of-band.

---
## Log

### Round 1 · Reviewer · codex · 2026-06-17 11:33:19 PDT

Per the explicit no-`git` constraint on this turn, I cross-checked against the working tree, `CHANGELOG.md`, the cited source docs, and a local `./validate.sh` run instead of `git log`.

**Findings:**

1. [Blocker] **Concern 1 + 2 — Part A Phase 5 overclaims a Marathon proof that does not exist yet.** The combined doc says Phase 5 dogfoods the "completed system (Cost + Marathon)" and claims a "relay/Marathon build with cost on" [PROJECT/2-WORKING/ROADMAP-COMBINED.md:187-196], but the source cost plan only proves a real relay run driven by `relay-drive.sh` + `gemini-turn.sh` [PROJECT/2-WORKING/COST-OBSERVABILITY-PLAN.md:141-149], while the Marathon source still leaves the dispatcher, `claude-turn.sh`, single-phase proof, and chaining work unchecked [PROJECT/1-INBOX/MARATHON.md:185-209]. The current runtime surface also lists `relay-drive.sh`, `codex-turn.sh`, and `gemini-turn.sh`, but no shipped `marathon-agent.sh` or `claude-turn.sh` [relay-automation/README.md:16-22]. This should be restated as a relay cost-comparison win, not a Marathon dogfood win.
2. [Should] **Concern 2 — the combined doc drops the cost plan's still-open measurement gaps.** The source plan explicitly keeps Codex token capture and Claude orchestrator token capture deferred [PROJECT/2-WORKING/COST-OBSERVABILITY-PLAN.md:174-180], but the combined Part A shipped sections retain only the success path and not those blind spots [PROJECT/2-WORKING/ROADMAP-COMBINED.md:58-80,185-206]. That omission matters because readers can reasonably infer "cost observability is complete" when the source doc says only Gemini headless turns are fully captured today.
3. [Pass] **Concern 1 — the Part B baseline is otherwise status-honest.** The repo's current full-suite manifest is 22 tests [validate.sh:7-30], and I ran `./validate.sh` green at 22/22. The combined doc's "mechanically proven" baseline and its unchecked adversarial phases match the on-disk state: the shared headless containment surface exists [relay-automation/README.md:16-22], while the Phase 1-4 hardening items remain unshipped in both the combined doc and source roadmap [PROJECT/2-WORKING/ROADMAP-COMBINED.md:219-323; ROADMAP.md:32-189].
4. [Pass] **Concern 2 — Part B is a faithful compression of `ROADMAP.md`.** The combined Phase 1-4 hardening track preserves the same threats, proof artifacts, and honest partial/missing statuses as the standalone roadmap [PROJECT/2-WORKING/ROADMAP-COMBINED.md:219-323; ROADMAP.md:32-189].

**Verdict:** Changes requested. The document is close, but it is not yet an execution-ready combined roadmap because Part A Phase 5 currently reads as if Marathon has already been proven and dogfooded.

**Concern 3 — worthwhile or burning time?** Worthwhile only if narrowed. The cost-observability work already delivered real value (`COST-COMPARISON.md`, deterministic analyzer, 22/22 suite), and the Part B adversarial-hardening track is a viable next investment because it targets real kernel risks. The Marathon track is not yet at that bar: Phase 2's `claude -p` feasibility spike is still the gating unknown [PROJECT/1-INBOX/MARATHON.md:190-198]. Recommendation: keep Part B, keep only the Marathon feasibility spike and honest cost-gap tracking, and do not treat Marathon Phases 3-5 as earned until the builder/dispatcher path exists on disk.
