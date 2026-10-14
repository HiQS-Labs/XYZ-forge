# RELAY · Plan QA: hiqs-ai-resolve GH-49 skill rename + network doc
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-14.
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
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(hiqs-gh49-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/plan.md** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/hiqs-ai-resolve-gh49-hiqs-skill-rename-2026-10-14/docs/issue-49/plan.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-14
- Definition of Done: the plan fully and surgically covers issue #49's requirements, grounded in the
  actual repo paths, with falsifiable checks, and is ready to implement.

### Operational envelope & non-goals
Documentation + skill-folder rename in a private single-maintainer repo (Lovable-synced `main`). No runtime
code change (that is #50). Grade against the stated requirements and commensurate complexity; do not ask for
new tests, aliases, or enterprise machinery. READ-ONLY: write only this relay file.

### Read (absolute paths, read-only)
- Plan (artifact above) and the task clone it describes:
  `/Users/noelsaw/Documents/GH Repos/hiqs-ai-resolve-gh49-hiqs-skill-rename-2026-10-14` (branch HEAD f2ee642).
- Requirements: `gh issue view 49 --repo NeochromeTeam/hiqs-ai-resolve` (and #48, #50 for context), or the
  clone's `skills/resolve-research/SKILL.md`, `skills/resolve-image/SKILL.md`, `skills/hiqs-chain/SKILL.md`,
  `CHANGELOG.md`, `consumer/chain.ts:290-320`.
- Deployment SOP the post-merge step must follow:
  `/Users/noelsaw/git-pulse-sync/Deployed Skills/skills-army-hq/SKILL.md`.

### Questions
1. Is the recon table complete? Run `git -C <clone> grep -n -E 'resolve-research|resolve-image|research-chain'`
   and confirm every live (non-historical) reference is covered or deliberately excluded with a valid reason.
2. Is leaving `image-manifest.json` `recordedBy` and `scripts/build-image-manifest.ts` `BY` unchanged correct
   (digested evidence), or would that break anything?
3. Is the network-requirement wording accurate to `consumer/chain.ts` behaviour (symptom: `contract_rejected`,
   `dispatched: true`, no `httpStatus`), and placed DRY (canonical in hiqs-chain, pointers in wrappers)?
4. Is the post-merge skills-army-hq sequence (remove old ×2, add new ×2, update hiqs-chain, sync) correct per
   the SOP, and does `remove` withdraw the old app links?
5. Is the durability probe a reasonable, bounded check of whether the doc fix works for a sandboxed agent?
6. Anything missing, wrong, or over-engineered?

Cite file:line for every finding. Set STATUS: Approved if the plan is ready.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

Ship with conditions.

VERDICT: FAIL

Basis: The surgical rename and canonical network paragraph fit the task. Fix S1's contradictory acceptance check and S2's overconfident diagnostic instruction before implementation. Both are small plan edits; no runtime changes or new tests requested.

swept file: yes

Read all of `.relay-artifacts/plan.md`, all three affected skill Markdown files and CHANGELOG, plus the relevant dispatch, evidence-sealing and deployment source. No additional pre-existing defect found in those skill files beyond the missing network guidance already addressed by this task. Paths below are relative to `/Users/noelsaw/Documents/GH Repos/hiqs-ai-resolve-gh49-hiqs-skill-rename-2026-10-14` unless qualified. Graph lookup used Verify scope, but the available `hiqs-ai-resolve` graph is for another checkout, generation `2026-09-12T03:16:16Z`; chain lookup returned zero and coverage was untracked/excluded or changed, so conclusions use direct source reads and literal searches instead.

- **[Should] S1 — Make the rename check compatible with preserved evidence.** `.relay-artifacts/plan.md:36` requires the skills-wide old-name grep to return only two formerly notes, while `:22` expressly preserves `skills/hiqs-chain/assets/image-manifest.json:1`. That manifest contains five old-name occurrences, including two `recordedBy` values and three evidence URLs. Cheapest fix: scope the live-name assertion to skill Markdown, then separately assert the historical manifest remains unchanged; do not rewrite evidence to satisfy the grep.
  Observed input: The preserved manifest. Probe, with `task_repo='/Users/noelsaw/Documents/GH Repos/hiqs-ai-resolve-gh49-hiqs-skill-rename-2026-10-14'`: `python3 -c 'from pathlib import Path; import re,sys; s=Path(sys.argv[1]).read_text(); print("preserved manifest old-name matches:",len(re.findall("resolve-research|resolve-image",s)))' "$task_repo/skills/hiqs-chain/assets/image-manifest.json"`. Exit **0**; decisive output: `preserved manifest old-name matches: 5`.
  Affected scope: The skills-wide rename acceptance check at plan lines 36/42, not historical provenance.
  Falsifier: After the proposed rename, a Markdown-only search must show exactly the intended formerly notes; restoring one live old-name link must fail that check, while retaining the unchanged manifest must pass.

- **[Should] S2 — Treat the signature as a clue, not proof of blocked egress.** `.relay-artifacts/plan.md:37` says to rerun with network and “do not report it as a recipe/contract defect.” Source supports the reported transport-failure mapping (`consumer/chain.ts:306`, `:318`), but successful HTTP responses rejected by `boundedJSON`/`content` also become `contract_rejected` without `httpStatus` (`:224`, `:229`, `:243`, `:321`). Cheapest fix: include `dispatched: true`, say the pattern *can indicate* blocked network, establish whether network was denied, and preserve contract investigation if it recurs with network available. No classifier change belongs here.
  Observed input: Existing `tests/acceptance/chain-caller.test.ts:118` supplies HTTP-200 JSON with `status: "completed"` and an empty `google_search_result.result`; `consumer/chain.ts:243` rejects that actual response contract. The source trace reaches the same failed/empty-output/no-httpStatus signature without blocked egress. **[Unverified — needs clone run]** for runtime measurement; the existing suite was read, not executed.
  Affected scope: The new canonical diagnostic paragraph and wrapper pointers, specifically interpretation of dispatched `contract_rejected` attempts without HTTP status.
  Falsifier: In a disposable clone, compare a fetch rejection with that existing HTTP-200 ungrounded-response case. The documentation must allow a network diagnosis for the former and a response-contract diagnosis for the latter, rather than prohibiting the latter report.

- **[Pass] Recon and evidence preservation otherwise fit.** Literal search covered 20 matching files; the live skill references are accounted for by plan lines 16–19. `docs/catalog-ops/ledger.md:624` is an additional historical mention and can remain unchanged. No old-name hits were found across the inspected consumer/src/packages/tests files (7/100/11/25 files respectively). Keeping the manifest and builder identity is correct: `scripts/build-image-manifest.ts:39`, `:43`, `:51`, `:64` seal provenance; `packages/core/src/recipes.ts:35` hashes claim content and `packages/core/src/client.ts:145` hashes the snapshot. These strings are provenance rather than executable folder references.

- **[Pass] Deployment sequence and probe purpose are reasonable.** The deployed `/Users/noelsaw/git-pulse-sync/Deployed Skills/skills-army-hq/SKILL.md:66` requires publishing from merged source; `:88` explicitly prescribes remove then sync for withdrawal. Its `scripts/intake.py:816` says `run sync apply to withdraw owned links`; remove alone removes the payload/receipt and can leave temporarily dangling links. Plan `:49` includes the necessary sync. The probe at plan `:44` has an observable outcome and a durable transcript destination; actual agent behavior remains **[Unverified — needs clone run]**.

- **[Nit] Pin the runtime refresh source explicitly.** At plan `:49`, spell out `update hiqs-chain --source <merged main>/skills/hiqs-chain` and preview/apply sync. The SOP `:22` documents explicit refresh, and `scripts/intake.py:788` otherwise reuses the recorded source; selecting the same merged checkout as the new wrappers avoids stale-source ambiguity.

Limitations: `gh issue view 49 --repo NeochromeTeam/hiqs-ai-resolve --json title,body,comments` exited **1**, `error connecting to api.github.com`; review used the relay-authorized local requirements/context fallback. No tests, executable fixtures, paid calls, deployment operations or agent durability run were performed. Artifact/source files were not edited.

Handing off to Producer (claude-a) — address S1/S2, disposition the remaining observations, then return for round 2.

### Producer · Round 2
- S1 → **Implemented** (plan d05af87, step 1 check): old-name assertion scoped to `skills/*.md`; separate `git diff --quiet origin/main -- skills/hiqs-chain/assets/image-manifest.json` asserts the preserved evidence is unchanged.
- S2 → **Implemented** (step 2): the diagnostic now reads as a clue (`dispatched: true`, no `httpStatus`, `contract_rejected` *can indicate* blocked egress), first establish whether network was denied and rerun with network, and keep contract investigation if it recurs with network available.
- Nit → **Implemented** (post-merge): `update hiqs-chain --source <merged main>/skills/hiqs-chain`, then preview/apply sync.
- Recon/manifest/deployment [Pass] items: no change. The artifact path above now resolves to plan r2 (re-seeded).

Handing off to Reviewer (codex) — round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
