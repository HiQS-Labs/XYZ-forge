# RELAY · QA: Model-catalog coordination surface — docs, GH issues, next steps coherence
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-05.
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
6. **Commit only the relay file** (`relay(model-catalog-coordination-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/COORDINATION.md** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/Model-catalog/COORDINATION.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: deepseek   ·   Producer: claude-a
- Started: 2026-09-05
- Definition of Done: a cold agent in ANY of the three repos can orient from COORDINATION.md +
  the linked issues and execute their part without asking a question; every link resolves; no
  claim contradicts the artifact it points at.

Adjudicate the coordination surface for the Model-catalog project (this is a DOCS/COORDINATION
review — the artifact is COORDINATION.md in Model-catalog, seeded read-only at
.relay-artifacts/COORDINATION.md). You are running inside the XYZ-forge clone, so you CAN verify
XYZ-side claims locally (gh is available; issues #346/#448/#449/#450, relay files, PROJECT.md
sources). Questions:

1. Link integrity: every GH issue/PR link in COORDINATION.md resolves and its state matches the
   table's claim (e.g. PR #449 open + CI green; #448 open; Model-catalog#1 phase checkboxes).
2. Cold-start test: pick ONE phase (#450 for XYZ-forge OR AEGIS-Sleuth#173) and walk it as an
   executor — is any step ambiguous, missing an acceptance criterion, or dependent on an
   undocumented decision?
3. Consistency: do COORDINATION.md, Model-catalog PROJECT.md/README, and the umbrella issue agree
   on the consumer contract, the versioning taxonomy (MAJOR/MINOR/PATCH), the two-PR flow, and the
   license split? Quote any contradiction.
4. Loose ends: is the "Known loose ends" section complete and accurate (local-commit caveat, dsh
   telemetry caveat, VERDICT vocabulary drift)? What would bite next?
5. Sequencing: is the "Next steps" order correct given dependencies (e.g. PR #449 vs Phase 1;
   Sleuth sync needing a tagged catalog version)?

FORMAT REQUIREMENT (the harness validator enforces this literally):
- Include a line starting `Basis:` summarizing your evidence base (what you verified vs trusted).
- End with a verdict line EXACTLY one of: `VERDICT: PASS` / `VERDICT: FAIL` / `VERDICT: PARKED`
  (plain text, own line, after the ## Log section header).
- Grade findings [Blocker]/[Should]/[Nit]/[Unverified — no citation]. Do not edit the artifact.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

---

### [R1] Reviewer — deepseek — 2026-09-05 (ROUND 1)

swept file: yes — reviewed the ENTIRE COORDINATION.md (all 72 lines; seeded copy verified byte-identical via `diff` to `/Users/noelsaw/Documents/GH Repos/Model-catalog/COORDINATION.md`), plus every artifact it points at: Model-catalog#1 body, PROJECT.md (all 299 lines), README.md, data/catalog.json, both LICENSEs, XYZ-forge #346/#448/#450 + PR #449 + `bin/validate-relay-block` + both relay-QA files, AEGIS-Sleuth #168/#171/#173. Pre-existing defects in the pointed-at docs are graded below per the GH-268 whole-file rule.

Basis: verified via read-only `gh api` — states of all seven linked issues (Model-catalog#1 open; XYZ #346/#448/#450 open; Sleuth #171/#173 open; #168 closed state_reason=completed), PR #449 OPEN/MERGEABLE with the blocking `vendored smoke gate` check = pass, both comment anchors resolve (5553629381 on XYZ#346, created 2026-09-05T17:44:01Z; 5553627378 on MC#1), XYZ-forge remote returns HTTP 422 for `a90c4df5` (local-only ✓), Model-catalog remote has 0 tags / 0 releases / 0 workflows / 0 runs, commits 4e0ae5a + 4f412a1 + 0baadb0 exist on remote, and catalog.json blob sha 7733be94… (17909 B) is identical at main (239f3c2) and 4f412a1; verified via local file reads — catalog counts (60 rows; 53 native / 7 openrouter; exactly 2 flagged rows; 31 rows dated 2026-09-04 / 29 null; 6 distinct dated replaces ↔ 6 distinct URLs), LICENSE=MIT + data/LICENSE=CC0, README/PROJECT.md full text, `validate-relay-block:76,82` regexes, XYZ seams (`resolve-model-alias.sh:32` MODEL_ALIASES_FILE, `test/model-alias.sh:81-90` miss assertions, `utils/py/profile_resolve.py` exists, yml has exactly 7 alias rows). Trusted-not-verified: local commit-hash `a90c4df5` attribution (needs git, banned this turn — its remote ABSENCE is verified); `validate_catalog.py` exit-0 behavior (reviewer runs no artifact); whether the 31 dated rows reflect genuine out-of-band verification.

**Cold-start walk (Q2): XYZ-forge #450.** Steps 3–5 + Accept are executable as written (every seam verified, cited above). Steps 1–2 are NOT executable as written — B1, B3.

- [Blocker] B1 — **The `v1.0.0` tag does not exist anywhere, yet both consumers' pin steps hard-depend on it.** `gh api repos/HiQS-Labs/Model-catalog/tags` → `[]`, `git/matching-refs/tags/` → empty, `releases` → `[]`; local `.git/refs/tags/` is an empty dir with no packed-refs. But #450 step 1: "Vendor `catalog.json` byte-identical to the `v1.0.0` tag … **pin record (tag + sha256)**"; #173 Accept: "reconcile 1:1 with Model-catalog `v1.0.0`"; PROJECT.md:227-228 + README → Versioning: "every release is **git-tagged**" — and v1.0.0 shipped (Phase 0 ✅) untagged. A cold executor hits an undocumented decision immediately: who tags, and which commit is v1.0.0? **Fix:** in COORDINATION.md "Next steps", insert a maintainer step before current step 2: "Tag `v1.0.0` and push the tag — data-safe at current main: catalog.json blob 7733be94… is byte-identical at 4f412a1 (Phase 0 close) and 239f3c2 (main)"; add a matching "Known loose ends" bullet covering the window until the tag exists.
- [Blocker] B2 — **"CI validates" contradicts the repo: Model-catalog has no CI at all.** COORDINATION.md:70 (contribution flow step 2): "CI validates (uniqueness under both normalizations, tier-4 capture, vocabulary, dates)"; same claim at PROJECT.md:106 ("enforced by this repo's CI"), PROJECT.md:228-229 ("catalog CI rejects a `data/catalog.json` change that does not bump `version` + `updated`"), README → Changing the catalog step 2. Reality: no `.github/workflows/` directory exists; `actions/workflows` total_count = 0; zero workflow runs ever. A cold contributor PRing a row gets no validation, and the promised version-bump enforcement does not exist — the contribution flow is the artifact's "standing answer", so this is a DoD contradiction ("no claim contradicts the artifact it points at"). **Fix:** rewrite COORDINATION.md:70 honestly ("`scripts/validate_catalog.py` exists and must be run manually on every catalog PR — CI wiring is an open loose end"), add the loose-end bullet, and add "wire CI (validator + version-bump check)" to Next steps; flag the identical stale claims in PROJECT.md/README to the maintainer.
- [Blocker] B3 — **The renderer "Catalog repo ships … at the pinned tag" does not exist, and no issue anywhere tracks building it.** PROJECT.md:168-169 ("Catalog repo ships the renderer at the pinned tag") and #450 step 2 ("Catalog repo ships the renderer") assign the openrouter-YAML renderer to Model-catalog; `scripts/` contains only `validate_catalog.py` (verified by ls); umbrella #1 has no renderer checkbox in Phase 0 (all [x], none is the renderer) or Phase 1 (all XYZ-side). Sequencing trap: if `v1.0.0` is tagged first (B1 fix), a renderer added later is NOT "at the pinned tag" — it forces a re-tag or a v1.0.1 pin. The XYZ executor must choose cold: wait for an untracked deliverable, or build it across the repo boundary the plan assigned elsewhere. **Fix:** in COORDINATION.md Next steps, name the renderer as an owned, ordered deliverable — either "Model-catalog: build renderer (spec already deterministic: PROJECT.md:112-115 squash-length desc, then lexicographic) and tag it (v1.0.1 if v1.0.0 is tagged first), consumers pin that tag" or an explicit reassignment into the XYZ #450 PR — the decision must be recorded, not made cold.
- [Should] S1 — **PROJECT.md:103's provenance arithmetic contradicts the shipped data.** PROJECT.md:103 (the r2-F1 fold): "Backfilled `2026-09-04` **only for the seven** Sleuth-native pins re-verified in GH-168 Rev 4, each with a per-pin source URL recorded; the other **46** bulk-seeded Sleuth pins and all seven XYZ OpenRouter rows **stay `null`**." Data: **31** rows dated 2026-09-04 and 29 null (= 20 pre-GH-168 + 7 XYZ + 2 flagged — the flagged-rows-carry-no-date rule holds); the 31 dated rows map to **6** distinct `replace` pins ↔ 6 distinct first-party URLs (e.g. 8 rows share `platform.openai.com/docs/models/gpt-5.6-terra`) — plausibly satisfying the per-pin-evidence bar under a pin = replace-target reading, but "seven dated / 46 stay null" is false under either reading (rows 31/29; pins 6 dated, 7 native-null). **Fix:** reconcile PROJECT.md:103 to the data — restate the rule as per-replace-target evidence with the actual counts (31 rows / 6 pins) — or strip the unearned dates; until reconciled, add a COORDINATION loose-end so #173's `VerifiedOn`-age diagnostics don't read the mismatch as corruption.
- [Should] S2 — **Phase 0 is ✅ but one of its own accept items is unmet: the README note for the `gpt` → `gpt-5.6-terra` deviation.** PROJECT.md:153-154 (Phase 0): "carry the documented `gpt` → `gpt-5.6-terra` vendor-default-not-flagship deviation as data **(a note in README)**, not silently." The data row exists (catalog.json:330-335, `"match": "gpt"` → `"replace": "gpt-5.6-terra"`); the README contains no such note (grep: no `gpt-5.6-terra`, no vendor-default text — only unrelated "chatgpt"/"gpt 5.5" mentions at README:3,28). So COORDINATION.md:16 "Phase 0 ✅" and the umbrella's all-[x] overstate completion. **Fix:** add the README note (producer-side), or record the gap in COORDINATION's loose ends until it lands.
- [Should] S3 — **README's consumer-contract list omits the binding flags clause.** README → Consumer contract has 5 items ending "Exact model IDs are never declared keys, so they always pass through untouched"; PROJECT.md:142-145 item 6, umbrella item 6, and COORDINATION decision 4 all carry "**Flagged rows resolve normally** … flags advisory, never terminal" — and #173 calls its version "binding". A cold agent reading only the README loses clause 6. Not a contradiction, a divergence — but Q3 asks exactly this. **Fix:** add the clause to the README contract list (or note the divergence in COORDINATION loose ends).
- [Nit] N1 — PROJECT.md is internally stale on GH-168: PROJECT.md:31 "Its GH-168 resolver **(status: Proposed)**" and PROJECT.md:258 "GH-168 is **not yet implemented**, so nothing live changes" contradict its own PROJECT.md:193 "GH-168 **shipped** (closed completed)" and the verified remote state (#168 closed, state_reason=completed). **Fix:** refresh both stale lines.
- [Nit] N2 — #450 Accept "Refusal contract negative control still fails when mutated" names no control; the closest existing artifact is the resolver-level miss assertion at `test/model-alias.sh:81-86` ("piped table: miss -> exit 1, no output"), and no XYZ doc names a terminal-refusal negative control. **Fix:** name the file/assertion (or state that Phase 1 adds it) in #450 / PROJECT.md Phase 1 Accept.
- [Pass] P1 — **Link integrity (Q1): every COORDINATION.md link resolves and every State cell matches the target.** MC#1 open with body "Phase 0 … ✅ COMPLETE" all `[x]`, "Phase 1 … ⬜ pending", "Phase 2 … ⬜ pending", "Phase 3 … 🅿️ PARKED" ≡ row 16; XYZ#450 open ≡ row 21 "Pending — not started"; XYZ#346 open ≡ row 22 and the r2-comment anchor `#issuecomment-5553629381` exists on #346; Sleuth#173 open ≡ row 23; #171 open ≡ row 24; "#168 resolver, closed completed" ≡ remote state_reason `completed`; #448 open and PR #449 OPEN/non-draft/MERGEABLE with blocking `vendored smoke gate` = pass ≡ row 25 "PR open, CI green, awaiting review/merge" (the skipped ubuntu/macOS jobs are push-to-main-only by design); relative links PROJECT.md, data/catalog.json, scripts/validate_catalog.py, LICENSE (MIT), data/LICENSE (CC0-1.0) all exist ≡ rows 17–20; both relay-QA files exist in-tree ≡ row 26, and `a90c4df5` is absent from the remote (422) ≡ "local until next development push".
- [Pass] P2 — **Numeric claims exact.** Row 18 "60 rows (53 native / 7 openrouter)": catalog.json:3 `"version": "1.0.0"`; grep counts = 60 `"match"` rows, 53 `"target": "native"`, 7 `"target": "openrouter"`; XYZ `openrouter-model-aliases.yml` holds exactly 7 alias rows; exactly 2 flagged rows (`gemini 2.5 pro`, `gemini pro` → `gemini-2.5-pro`), both `unverified-generation` with `verified_on: null` ≡ umbrella:21.
- [Pass] P3 — **Consistency (Q3): contract, taxonomy, two-PR flow, and license split agree across COORDINATION / PROJECT.md / README / umbrella** (README's omitted clause = S3; PROJECT.md:103's count = S1 — neither is a contract contradiction). Decision 4's six clauses ≡ PROJECT.md:127-145 items 1–6 ≡ umbrella "Consumer contract" items 1–6; row 71's pointer "PROJECT.md → Versioning" resolves to PROJECT.md:216 "## Versioning & cadence" and its MAJOR/MINOR/PATCH definitions ≡ README "## Versioning" in substance; decision 2 "Two-PR change flow … deliberate" ≡ PROJECT.md:241-242 "Contribution flow costs two PRs … deliberate price" ≡ README "Two PRs of friction is the deliberate price"; decision 5 ≡ PROJECT.md:243-245 ≡ README License ≡ the two files on disk; row 17 "Reviewed — 2 relay rounds folded" ≡ PROJECT.md:5 frontmatter + Review record (r1 agy, r2 qwen).
- [Pass] P4 — **Loose ends (Q4): all three existing entries verified accurate.** (a) `a90c4df5` local-only ✓ (remote 422); (b) dsh telemetry ✓ ≡ #448 title "…telemetry records a model that never ran"; (c) VERDICT drift ✓ — `bin/validate-relay-block:76` accepts only `VERDICT:` + `(PASS|FAIL|PARKED)` and `:82` requires a `Basis:` line, while the relay playbook says "Approved | Changes requested | Blocked"; PROJECT.md:280-282 and :297-299 record the two exit-8 rejections, and `model-catalog-plan-qa-agy.md:109` still literally ends `**Verdict:** Changes requested.` — the exact failure described. What's MISSING from the section (what bites next): B1 no tag, B2 no CI, S1 doc↔data provenance mismatch, S2 unmet Phase 0 accept item.
- [Pass] P5 — **Sequencing (Q5): the order of Next steps 1→5 is correct as far as it goes.** Step 1 first with "Independent of Phase 1" ✓ — PR #449 touches only the dsh overlay, is open/mergeable/green, and the stated rationale ≡ #448's title; steps 2 and 3 are mutually independent (parallelizable across repos — the numbering doesn't forbid that); step 4 ≡ contract item 4; step 5 ≡ Phase 3 parked. The only sequencing defects are the missing predecessors — tag (B1) and renderer (B3) — graded above, not re-graded here.

Verdict: **Changes requested** — B1/B2/B3 each independently break the DoD ("execute their part without asking a question; no claim contradicts the artifact it points at") for the #450/#173 executors and the contribution flow; all three are fixable in COORDINATION.md this round (honest wording + the two missing predecessor steps + loose-end entries), with the repo-side actions they name (cut the tag, wire CI, assign the renderer) flagged for the maintainer. S1–S3 and N1–N2 should ride the same pass.

Handing off to Producer (claude-a) — go to the Producer window and say "take your turn": log a disposition for every finding above (Implemented / Modified / Declined + why), edit COORDINATION.md, bump ROUND, and flip NEXT back to Reviewer.

VERDICT: FAIL

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
