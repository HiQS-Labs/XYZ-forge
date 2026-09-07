**SINGLE-MODEL — NOT RECONCILED** (only codex answered; 1 of 2 requested advisor(s) failed — this is one model's read, not a cross-model consult. Do not treat any claim below as cross-verified.)

**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-5.6-terra
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
OpenAI Codex v0.153.4
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej
model: gpt-5.6-terra
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 01a07d3b-2f81-7ad0-ae81-4a7e0931e401
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Adjudicate PR #483: delete LEADERBOARD.html and RELEASES-PREVIEW.html from this repo

You are reviewing a proposed deletion in THIS repository, at the working tree you are running in.
**Read the real files.** Do not answer from memory, from a cached copy of this repo, or from any
scratch directory outside this worktree. If a file you expect is absent here, say so and treat this
worktree as authoritative — it is. Cite `file:line` for every load-bearing claim, and name the
command you ran.

## The change

PR #483 deletes exactly two files from the repo root and nothing else — 1,618 deletions, zero
insertions:

- `LEADERBOARD.html`
- `RELEASES-PREVIEW.html`

No generator is removed. No consumer is edited. No test is changed. The generators
(`utils/timeline/export_timeline.py --leaderboard` and `--preview`) stay.

Note: those two files still exist in this worktree — you are checking whether deleting them is safe,
not observing an already-applied change.

## The claim I want attacked

**"Both files are pure adoption-by-presence: every consumer regenerates them only when the file
already exists at the repo root, so deleting the file simply makes every consumer stop refreshing
it."**

The evidence I am relying on:

- `utils/py/express.py:202-207` — `paths.update(p for p in RELEASES_PROJECTIONS if os.path.lexists(...))`
- `utils/py/releases_app.py:1170-1201` — the post-write refresh
- `utils/releases-merge-resolve.sh:196-214` — the merge-resolution refresh

## Questions — answer each

1. **Is the presence-gating claim actually true for BOTH files, on EVERY write path?** Enumerate
   every place either filename appears (`git grep -n 'LEADERBOARD.html\|RELEASES-PREVIEW.html'`) and
   say, for each, whether it is presence-gated, unconditional, or something else. Name any path that
   would ERROR rather than no-op when the file is absent. I care most about a path I have not
   listed above.

2. **Do any tests break?** Four suites mention these filenames: `test/gh103-timeline-exporter.sh`,
   `test/gh153-releases-sidebar-rollup.sh`, `test/gh267-express-skill.sh`,
   `test/gh57-live-merge-resolve.sh`. Read them. Does any of them assert that either committed
   artifact EXISTS at the repo root, as opposed to exercising the exporter or the presence gate?

3. **Is there a route to these files I missed?** Check governance docs (`ROUTER.md`, `AGENTS.md`,
   `GUIDING-PRINCIPLES.md`, `README.md`), skills (`skills/**/SKILL.md`), CI workflows
   (`.github/workflows/`), the vendoring path (`relay-automation/xyz-vendor.sh`,
   `relay-automation/xyz-sync.sh`), and `utils/py/router_audit.py`. Does anything require these two
   HTML files to be present or tracked? Does anything PUBLISH or SERVE them?

4. **Is the asymmetry justified?** The same #474 work is deliberately NOT removing the two rendered
   MARKDOWN views (`ROADMAP-DASHBOARD.md`, `LEADERBOARD.md`) — those stay tracked, because
   `AGENTS.md:139-143` and `GUIDING-PRINCIPLES.md:77` route to the dashboard with no CLI
   alternative, and `utils/py/router_audit.py` is a hard gate (run by
   `test/gh353-vendored-router-audit.sh`) requiring `ROUTER.md` to declare the dashboard as the
   generated view. Verify those three citations. Is "the HTML has no guard, no governance route and
   no router_audit clause" a real distinction in this tree, or am I drawing a line that is not
   there?

5. **Rollback.** The PR claims rollback is "run the generator, commit the file, and every consumer
   resumes refreshing it." Is that complete and testable, or is something harder than stated?

6. **Should this ship at all?** Pick one: SHIP, SHIP WITH CHANGES (name them), or DO NOT SHIP (say
   what would change your mind). A balanced survey is a failed answer.

Grade findings [Blocker] / [Should] / [Nit]. End with a one-line verdict.

codex
I’ll inspect the specified tree directly and trace every filename occurrence, including the write paths and tests. I’ll treat this worktree as authoritative and cite exact lines.
exec
/bin/zsh -lc "pwd && rg --files -g 'ROUTER.md' -g 'GUIDING-PRINCIPLES.md' -g 'README.md' -g 'AGENTS.md' -g 'LEADERBOARD.html' -g 'RELEASES-PREVIEW.html' -g 'router_audit.py' -g 'express.py' -g 'releases_app.py' -g 'releases-merge-resolve.sh' -g 'xyz-vendor.sh' -g 'xyz-sync.sh' -g 'gh103-timeline-exporter.sh' -g 'gh153-releases-sidebar-rollup.sh' -g 'gh267-express-skill.sh' -g 'gh57-live-merge-resolve.sh' -g 'gh353-vendored-router-audit.sh'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej
 succeeded in 0ms:
/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej
GUIDING-PRINCIPLES.md
PARKED/README.md
AGENTS.md
skills/skills-sync-trinity/README.md
sentinel-overlay/README.md
LEADERBOARD.html
docs/ingestion/README.md
utils/timeline/README.md
utils/vndr/README.md
utils/README.md
relay-automation/xyz-vendor.sh
relay-automation/README.md
utils/releases-merge-resolve.sh
relay-automation/xyz-sync.sh
utils/py/express.py
utils/py/releases_app.py
utils/py/router_audit.py
ROUTER.md
RELEASES-PREVIEW.html
TESTS-RESULTS/2026-08-23+GH-174/README.md
test/gh267-express-skill.sh
test/xyz-vendor.sh
test/gh153-releases-sidebar-rollup.sh
evidence/marathons/run-3/3a-agy-quota-halt/README.md
test/fixtures/canary-token-reuse/README.md
test/fixtures/gamma-poison/README.md
tools/vscode-cockpit/README.md
TESTS-RESULTS/2026-09-06+GH-460/README.md
test/fixtures/canary-reviewer-overstep/README.md
PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/README.md
test/fixtures/canary-peer-orphan/README.md
test/fixtures/contracts/README.md
README.md
TESTS-RESULTS/README.md
test/gh57-live-merge-resolve.sh
test/gh353-vendored-router-audit.sh
test/gh103-timeline-exporter.sh
relay-system/2026-08-29/gh280-phase5-vendored-default/README.md
relay-system/2026-08-29/gh222-vendored-dogfood/README.md
skills/agent-chorus/README.md
skills/agent-chorus/standalone/README.md

exec
/bin/zsh -lc "git grep -n -E 'LEADERBOARD\\.html|RELEASES-PREVIEW\\.html' && nl -ba utils/py/express.py | sed -n '175,225p' && nl -ba utils/py/releases_app.py | sed -n '1130,1225p' && nl -ba utils/releases-merge-resolve.sh | sed -n '175,230p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej
 succeeded in 11294ms:
2026-09-07 11:57:23.939 xcodebuild[82626:40799698]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 11:57:25.202 xcodebuild[82626:40799678] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-GczFaJI0' (errno=Operation not permitted)
2026-09-07 11:57:27.586 xcodebuild[83787:40804192]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 11:57:28.609 xcodebuild[83787:40804088] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
CHANGELOG.md:83:- **GH-271/GH-272/GH-273: the #260 assessment's revised quick wins — reconciler linkage, merge-resolve views, audit spellings.** Three fixes from the top-3 re-prioritization on issue #260 (each issue links the revised comment). **GH-271:** `wave_reconcile.py`'s linked-issue extraction was mention-greedy — every prose `GH-N`/`#N` in a PR body acted as a link (PR #185's body yielded ten "linked" issues, two of them live lanes). Extraction now splits *closers* (GitHub closing-keyword semantics, extended to the `GH-N` spelling, mandatory prefix so "closes 5 issues" extracts nothing, comma lists, title trailers, code fences ignored) from *mentions*, which only ever record merge evidence on an OPEN issue's doc — never a promotion or ROADMAP move — unless `--force-promote` explicitly widens the action set. The bet: evidence-recording for "Advances GH-N (phase k of n)" phase PRs is load-bearing (GH-202/GH-232 pin it), and a keyword-only rule would have gutted it, so the harmful direction (mention → closed/unknown state → relocation) is what's blocked. Rollback completeness made verifiable: regenerated views snapshotted, dated plan docs tracked even when a step dies mid-loop, a pre-existing promotion destination snapshotted instead of unlinked-blind, and a porcelain-vs-baseline tripwire names leftovers loudly. `gh202` extended to 29 assertions; `gh232`/`gh168`/`wave-reconcile` green (31 total). **GH-272:** `releases-merge-resolve.sh` now regenerates and stages every adopted derived view (`ROADMAP-DASHBOARD.md`, `RELEASES-PREVIEW.html`, `LEADERBOARD.html`, `LEADERBOARD.md`) after the DB rebuild — take-`--ours`-then-regen-then-stage, hard-fail-and-leave-the-merge-open on generator failure — ending the hand-regen tax on every concurrent ledger merge; `roadmap-dashboard.sh` gained `ROADMAP_DASHBOARD_ROOT` so a resolver can drive it against a `--root` target. `gh57-live-merge-resolve` extended to 53 assertions including a both-sides-conflicted-views merge. **GH-273:** `marathon-root-audit.sh` recognizes python3-spelled driver invocations in program position (the GH-195 blind spot), with group-span safety (scoping envs above, anchor args below, fixture-resident copies by construction) and the `python3 - "<path>" <<'PY'` reader shape deliberately unmatched; four parse-probe call sites in `gh322-*` scoped per those files' own GH-401 convention. Audit coverage 139 invocations, zero failures; new `gh273-marathon-root-audit-python-shape.sh` (9 assertions) pins the shapes.
CHANGELOG.md:131:  exists — so both baked artifacts (`RELEASES-PREVIEW.html`, `LEADERBOARD.html`) inherit it with
CHANGELOG.md:248:  `export_timeline.py --leaderboard` bakes `LEADERBOARD.html` from the SAME template as the timeline
LEADERBOARD.html:288:    <a class="sn-item" id="sn-view-a" href="./LEADERBOARD.html"><span class="sn-ico">◫</span><span class="sn-label">leaderboard</span></a>
LEADERBOARD.html:324:      <a id="view-link" class="mono" href="./LEADERBOARD.html"
LEADERBOARD.html:427:    document.getElementById('sn-view-a').href=lb?'#':'./LEADERBOARD.html';
LEADERBOARD.html:428:    document.getElementById('sn-view-b').href=lb?'./RELEASES-PREVIEW.html':'#';
LEADERBOARD.html:687:      link.href=view==='leaderboard'?'./RELEASES-PREVIEW.html':'./LEADERBOARD.html';
PARKED/2026-08-20-gh103-timeline-spike.md:12:- **RELEASES-PREVIEW.html staleness guard.** The committed snapshot (operator decision) has no
PROJECT/1-INBOX/GH-254-PREVIEW-DRAFT-SORT.md:32:Draft release cards render before active cards in RELEASES-PREVIEW.html; drafts should move to the back of the line.
PROJECT/1-INBOX/GH-254-PREVIEW-DRAFT-SORT.md:43:2. Run `utils/timeline/export_timeline.py --preview RELEASES-PREVIEW.html`.
PROJECT/1-INBOX/GH-424-ROADMAP-STATUS-MARKER-WRITER.md:58:`ROADMAP-DASHBOARD.md`, `RELEASES-PREVIEW.html`, `LEADERBOARD.html`, `LEADERBOARD.md`
PROJECT/1-INBOX/RADAR-REPORT-2026-08-28.md:182:**Class-shaped.** #163, #168, #202, #232, #228, #250, #253, #257, #272, #69. Seams: `utils/py/wave_reconcile.py`, `utils/py/releases_app.py`, and derived artifacts `RELEASES-PREVIEW.html` / `LEADERBOARD.html` / `releases.sql`. 8–9 issues across 5 distinct days, 2026-08-20 → 08-26 — **passes the recurrence discriminator.**
PROJECT/1-INBOX/RADAR-REPORT-2026-09-01.md:396:| `LEADERBOARD.md`, `RELEASES-PREVIEW.html`, `releases.db/.sql`, `CHANGELOG.md`, `ROADMAP-DASHBOARD.md` | **Generated artifacts.** Regenerated on every release commit; co-change noise. |
PROJECT/1-INBOX/recon-leaderboard-removal.md:5:Subject: `LEADERBOARD.md`, `LEADERBOARD.html`, and their rendering machinery (`utils/leaderboard.sh`, `utils/timeline/export_timeline.py --leaderboard`).
PROJECT/1-INBOX/recon-leaderboard-removal.md:17:- CLI / Agent writes -> `utils/py/releases_app.py` -> `refresh_preview()` -> calls `utils/leaderboard.sh` to regenerate `LEADERBOARD.md` and `export_timeline.py --leaderboard` to regenerate `LEADERBOARD.html`.
PROJECT/1-INBOX/recon-leaderboard-removal.md:37:| Do any downstream external tools rely on `LEADERBOARD.html`? | If it's served statically to a team dashboard, removing it will cause a 404. | Search for org/repo deployments of `LEADERBOARD.html` |
PROJECT/2-WORKING/GH-75-RELEASES-ROADMAP-DASHBOARD.md:17:  - Replacing RELEASES-PREVIEW.html — extend, do not fork.
PROJECT/2-WORKING/GH-75-RELEASES-ROADMAP-DASHBOARD.md:25:  trust header — by extending the existing RELEASES-PREVIEW.html generator
PROJECT/2-WORKING/GH-75-RELEASES-ROADMAP-DASHBOARD.md:37:pipeline. `RELEASES-PREVIEW.html` (644 lines) already exists and is refreshed by
PROJECT/3-COMPLETED/GH-108-GH-111-EXECUTION-TODO.md:95:      `LEADERBOARD.html`
PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md:33:| **SHIPPED 2026-08-21 — merged to `development` via PR #116** (`c271be3`), issue #108 closed. All four phases built on `feat/gh111-phase-a-dialed-in`. A: migration 003 (five nullable `rating_*` columns, transaction-safe, registry-driven), the one canonical `rated N/N/N/N` + ` ovr N` grammar in `roadmap sync` with a named refusal for every malformed shape, and the dump grammar both directions. B: exporter emits `metrics` + `effectiveScore` under the public axis names, joins detour cards to the roadmap index, flags `sev >= 80` hot, and gained `--json`; the viewer renames `app` -> `appeal`, adds `effort` to both metric loops, and flips the footer legend in the same commit. C: the intake scaffold takes the rating line and the 15 active-window ROADMAP entries are rated. D: `utils/leaderboard.sh` -> `LEADERBOARD.md`, `--leaderboard` -> `LEADERBOARD.html` from the SAME template via a `view` field, cross-linked from `.top`, all three refreshed by the GH-106 hook. Final suite counts after the aider/qwen3.8-max QA round: gh32 140/0, gh69 53/0, gh103 38/0. | Nothing — this plan is closed. The backfilled scores remain a defensible FIRST PASS read off what the ledger already says (operator front-of-line calls, built-vs-unstarted, blast radius); revising one is a `rated` edit plus a sync, not a reopen. Deferred as named, and still deferred: GH label mirroring, re-weighting, and machine-parsed doc frontmatter. |
PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md:109:   ranking an agent or a GitHub reader can consume without a browser; `LEADERBOARD.html` is the
PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md:128:| 7 | `utils/leaderboard.sh` + `LEADERBOARD.md` + `LEADERBOARD.html` | the ranked-report pipeline — see "The leaderboard pipeline" below | M |
PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md:142:                        export_timeline.py --leaderboard ──▶ LEADERBOARD.html
PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md:158:**3. One template, two baked artifacts.** `LEADERBOARD.html` is produced by the SAME
PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md:159:`bake_static(template, payload)` path that produces `RELEASES-PREVIEW.html`, from the SAME
PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md:168:when the operator collapses the chrome. Each page links to the other: `RELEASES-PREVIEW.html` gets
PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md:169:"leaderboard →", `LEADERBOARD.html` gets "← timeline".
PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md:219:   template; `--leaderboard` baking `LEADERBOARD.html`; the two-way navbar cross-link in `.top`;
PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md:251:top five exactly — the one-scorer property, proven rather than asserted — `LEADERBOARD.html` bakes
PROJECT/3-COMPLETED/GH-153-RELEASES-SIDEBAR-ROLLUP.md:30:The dashboard (`RELEASES-PREVIEW.html` / `LEADERBOARD.html`, both baked from the single
PROJECT/3-COMPLETED/GH-153-RELEASES-SIDEBAR-ROLLUP.md:92:4. Committed `RELEASES-PREVIEW.html` / `LEADERBOARD.html` match a fresh bake of the
PROJECT/3-COMPLETED/GH-153-RELEASES-SIDEBAR-ROLLUP.md:105:baked views (`LEADERBOARD.*`, `ROADMAP-DASHBOARD.md`, `RELEASES-PREVIEW.html`) against `development`,
PROJECT/3-COMPLETED/GH-197-VENDOR-TIER-SPLIT.md:116:`RELEASES-PREVIEW.html`) lives at the target ROOT, not under `.xyz/` — so
PROJECT/3-COMPLETED/GH-269-RELEASES-DB-SWITCHOVER.md:25:  again, verified by ATE/fuzzing, with RELEASES-PREVIEW.html as the surviving
PROJECT/3-COMPLETED/GH-269-RELEASES-DB-SWITCHOVER.md:37:gate/canary repointing, dashboard/preview coverage (RELEASES-PREVIEW.html is
PROJECT/3-COMPLETED/GH-269-RELEASES-DB-SWITCHOVER.md:87:    "criteria": "Every reader/writer/gate/canary that consumed ROADMAP.md reads releases.db instead; ROADMAP.md is deleted; a regression test proves no tool recreates or requires it; RELEASES-PREVIEW.html remains the human-readable view."
PROJECT/3-COMPLETED/GH-272-MERGE-RESOLVE-VIEWS.md:34:`LEADERBOARD.html`, `RELEASES-PREVIEW.html`, and `LEADERBOARD.md` are untouched, and
PROJECT/3-COMPLETED/GH-272-MERGE-RESOLVE-VIEWS.md:46:  `RELEASES-PREVIEW.html`/`LEADERBOARD.html` → `python3 utils/timeline/export_timeline.py
PROJECT/3-COMPLETED/GH-450-MODEL-CATALOG-CONSUME.md:123:   (`releases.db`/`.sql`, `harnesses.db`/`.sql`, `ROADMAP-DASHBOARD.md`, `LEADERBOARD.html`,
PROJECT/3-COMPLETED/GH-450-MODEL-CATALOG-CONSUME.md:124:   `RELEASES-PREVIEW.html`). The resolution is never a hand-merge of a binary: take
RELEASES-PREVIEW.html:288:    <a class="sn-item" id="sn-view-a" href="./LEADERBOARD.html"><span class="sn-ico">◫</span><span class="sn-label">leaderboard</span></a>
RELEASES-PREVIEW.html:324:      <a id="view-link" class="mono" href="./LEADERBOARD.html"
RELEASES-PREVIEW.html:427:    document.getElementById('sn-view-a').href=lb?'#':'./LEADERBOARD.html';
RELEASES-PREVIEW.html:428:    document.getElementById('sn-view-b').href=lb?'./RELEASES-PREVIEW.html':'#';
RELEASES-PREVIEW.html:687:      link.href=view==='leaderboard'?'./RELEASES-PREVIEW.html':'./LEADERBOARD.html';
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:4981:wrote /var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/gh57-live.wdTcTl/c8/RELEASES-PREVIEW.html (0 releases, self-contained, read-only snapshot of /var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/gh57-live.wdTcTl/c8/releases.db)
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:4982:wrote /var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/gh57-live.wdTcTl/c8/LEADERBOARD.html (0 rated task(s), self-contained)
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:4985:  PASS: fixture adopted RELEASES-PREVIEW.html before the merge
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:4986:  PASS: fixture adopted LEADERBOARD.html before the merge
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:4995:  PASS:   RELEASES-PREVIEW.html is staged resolved
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:4996:  PASS:   RELEASES-PREVIEW.html carries no conflict markers
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:4997:  PASS:   RELEASES-PREVIEW.html carries neither side's stale touch
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:4998:  PASS:   LEADERBOARD.html is staged resolved
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:4999:  PASS:   LEADERBOARD.html carries no conflict markers
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:5000:  PASS:   LEADERBOARD.html carries neither side's stale touch
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:5008:  PASS: staged RELEASES-PREVIEW.html reflects the MERGED ledger (both sides' releases present)
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:7909:  PASS: RELEASES-PREVIEW.html: id="sidenav-toggle"
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:7910:  PASS: RELEASES-PREVIEW.html: id="sidenav"
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:7911:  PASS: RELEASES-PREVIEW.html: id="sn-project"
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:7912:  PASS: RELEASES-PREVIEW.html: id="sn-min"
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:7913:  PASS: RELEASES-PREVIEW.html: data-snfocus="rel"
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:7914:  PASS: RELEASES-PREVIEW.html: class="sn-item sn-ph"
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:7915:  PASS: RELEASES-PREVIEW.html: __snCycle
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:7916:  PASS: RELEASES-PREVIEW.html: data-sn="expanded"
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:7917:  PASS: RELEASES-PREVIEW.html: id="ledger-data"
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:7918:  PASS: LEADERBOARD.html: id="sidenav-toggle"
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:7919:  PASS: LEADERBOARD.html: id="sidenav"
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:7920:  PASS: LEADERBOARD.html: id="sn-project"
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:7921:  PASS: LEADERBOARD.html: id="sn-min"
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:7922:  PASS: LEADERBOARD.html: data-snfocus="rel"
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:7923:  PASS: LEADERBOARD.html: class="sn-item sn-ph"
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:7924:  PASS: LEADERBOARD.html: __snCycle
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:7925:  PASS: LEADERBOARD.html: data-sn="expanded"
TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:7926:  PASS: LEADERBOARD.html: id="ledger-data"
relay-system/2026-08-20/gh103-branch-qa.md:72:- **[Blocker] Staleness hazard from committed generated artifact (DoD #5).** The snapshot `RELEASES-PREVIEW.html` is committed to the repository, but unlike `ROADMAP-DASHBOARD.md`, there is no check wiring (e.g., in `validate.sh` or `ci-local.sh`) to ensure it gets regenerated and hasn't drifted from the DB.
relay-system/2026-08-20/gh103-branch-qa.md:73:  - `RELEASES-PREVIEW.html` addition in diff.
relay-system/2026-08-20/gh103-branch-qa.md:74:  *Fix: Either add `RELEASES-PREVIEW.html` to `.gitignore` so it's strictly a local artifact, or wire a staleness check in the gate suite that regenerates it and fails on `git diff --exit-code`, identical to the dashboard pattern.*
relay-system/2026-08-21/gh124-merge-seq-173029/gh124-merge-seq.codex.md:3746: LEADERBOARD.html                                   |    4 +
relay-system/2026-08-21/gh124-merge-seq-173029/gh124-merge-seq.codex.md:3749: RELEASES-PREVIEW.html                              |    4 +
relay-system/2026-08-21/gh124-merge-seq-173029/gh124-merge-seq.codex.md:3783:M	LEADERBOARD.html
relay-system/2026-08-21/gh124-merge-seq-173029/gh124-merge-seq.codex.md:3786:M	RELEASES-PREVIEW.html
relay-system/2026-08-22/gh165-post-merge-reconcile-plan-qa.md:79:   - Run: python3 utils/timeline/export_timeline.py      (rebakes RELEASES-PREVIEW.html).
relay-system/2026-08-22/gh165-post-merge-reconcile-plan-qa.md:80:   - Run: bash utils/leaderboard.sh                     (rebakes LEADERBOARD.html & ROADMAP-DASHBOARD.md).
relay-system/2026-08-22/gh165-post-merge-reconcile-plan-qa.md:168:   command does not rebake `RELEASES-PREVIEW.html`; it needs `--preview` (`utils/timeline/export_timeline.py:583-588,626-640`).
relay-system/2026-08-22/gh165-post-merge-reconcile-plan-qa.md:169:   `leaderboard.sh` writes `LEADERBOARD.md`, not `LEADERBOARD.html` or `ROADMAP-DASHBOARD.md`
relay-system/2026-08-23/salvage-location-214521/salvage-location.codex.md:1214:./LEADERBOARD.html:375:<script id="ledger-data" type="application/json">{"meta": {"title": "Planning ledgers", "subtitle": "XYZ-forge · releases.db · read-only", "generatedAtDisplay": "2026-08-24 03:30:06Z", "sourceLabel": "releases.db · schema v5", "repoUrl": "https://github.com/HiQS-Suite/XYZ-forge"}, "sync": null, "telemetry": {"dbGeneration": 114, "receipts": 128, "lastSyncDisplay": "2026-08-24T03:30", "lastSyncAgoDisplay": "in 1 day", "releasesOpen": 6, "releasesTotal": 12, "releasesOverdue": 0}, "ratedTasks": [{"id": "GH-67", "title": "Commandcode builder default widened to `--yolo` — closer evaluation → possible build", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 88, "sev": 80, "appeal": 45, "effort": 70, "calc": 283, "effectiveScore": 340}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/67"}, "override": {"value": 340, "hot": true}}, {"id": "GH-181", "title": "repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command, rc 127 vs expected 2)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 90, "sev": 75, "appeal": 90, "effort": 60, "calc": 315, "effectiveScore": 315}, "links": null}, {"id": "GH-174", "title": "Harness & Models Registry SQLite Migration: Per-Device Config, Reasoning Effort Tracking, AI Grading Hooks & Blog Generator", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 85, "sev": 75, "appeal": 95, "effort": 45, "calc": 300, "effectiveScore": 300}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/174"}}, {"id": "GH-155", "title": "3rd Gen ATE & Fuzzing", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 70, "appeal": 90, "effort": 50, "calc": 295, "effectiveScore": 295}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/155"}}, {"id": "GH-165", "title": "Post-Merge Wave & Marathon Lifecycle Reconciler (Docs, ROADMAP, DB, Views, and Planning)", "release": null, "lane": "Completed", "metrics": {"pri": 90, "sev": 80, "appeal": 90, "effort": 35, "calc": 295, "effectiveScore": 295}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/165"}}, {"id": "GH-113", "title": "headless agy builder writes root scratch files, tripping containment (exit 6)", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 85, "sev": 60, "appeal": 85, "effort": 60, "calc": 290, "effectiveScore": 290}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/113"}}, {"id": "GH-148", "title": "DeepSeek Harness (dsh) integration & deepseek-turn shim for OpenRouter DeepSeek V4 Pro", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 75, "appeal": 90, "effort": 40, "calc": 290, "effectiveScore": 290}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/148"}}, {"id": "GH-168", "title": "wave_reconcile.py hard-fails and rolls back on pre-existing drift unrelated to the reconciled PR", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 70, "calc": 290, "effectiveScore": 290}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/168"}}, {"id": "GH-141", "title": "make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison", "release": "Bulkhead", "lane": "ad-hoc detour", "metrics": {"pri": 80, "sev": 65, "appeal": 85, "effort": 55, "calc": 285, "effectiveScore": 285}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/141"}}, {"id": "GH-114", "title": "headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7)", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 80, "sev": 60, "appeal": 80, "effort": 60, "calc": 280, "effectiveScore": 280}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/114"}}, {"id": "GH-115", "title": "marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 75, "sev": 50, "appeal": 85, "effort": 70, "calc": 280, "effectiveScore": 280}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/115"}}, {"id": "GH-180", "title": "repro_builder crashes on timeout telemetry records (exit_code: null → TypeError)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 70, "sev": 45, "appeal": 85, "effort": 80, "calc": 280, "effectiveScore": 280}, "links": null}, {"id": "GH-77", "title": "`/standup` — session-scoped triage: what did I leave open, what is rotting, is the plan still right?", "release": null, "lane": "Completed", "metrics": {"pri": 95, "sev": 70, "appeal": 85, "effort": 30, "calc": 280, "effectiveScore": 280}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/77"}}, {"id": "GH-124", "title": "eliminate end-of-day closeout friction — automated phase QA receipts, auto-PR creation, and clone lifecycle hygiene", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 60, "appeal": 90, "effort": 40, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/124"}}, {"id": "GH-132", "title": "feat(skills): formal /review-xyz code review skill & multi-model harness", "release": null, "lane": "Completed", "metrics": {"pri": 80, "sev": 70, "appeal": 85, "effort": 40, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/132"}}, {"id": "GH-170", "title": "Agent2Agent: close transcript glitches and harden publishing", "release": null, "lane": "Completed", "metrics": {"pri": 75, "sev": 60, "appeal": 85, "effort": 55, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/170"}}, {"id": "GH-2", "title": "test-suite run relocated an untracked file into .tick/orphan-backups/", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 55, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/2"}}, {"id": "GH-8", "title": "kernel boundary hardening — CLI numeric validation, task/agent format contract", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 65, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/8"}}, {"id": "GH-184", "title": "committed scratch artifact `.relay-scratch/probe_telemetry.json` makes every real turn a tracked-file mutation", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 60, "sev": 40, "appeal": 80, "effort": 90, "calc": 270, "effectiveScore": 270}, "links": null}, {"id": "GH-75", "title": "single-page HTML dashboard: releases (mid/long term) + roadmap (immediate) in one read-only view", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 90, "sev": 40, "appeal": 85, "effort": 55, "calc": 270, "effectiveScore": 270}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/75"}}, {"id": "GH-111", "title": "retire manifest FREEZE; tasks and marathons are DIALED IN to exactly one release, as a database state", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 75, "appeal": 70, "effort": 35, "calc": 265, "effectiveScore": 265}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/111"}}, {"id": "GH-182", "title": "self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 55, "calc": 265, "effectiveScore": 265}, "links": null}, {"id": "GH-50", "title": "sandboxed git --track / branch -D half-applies and loses uncommitted work", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 65, "sev": 35, "appeal": 85, "effort": 80, "calc": 265, "effectiveScore": 265}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/50"}}, {"id": "GH-183", "title": "active_explorer env-family fuzzing unsound (base_env={} hardcoded, one always-deferring vector, ambient-env leakage)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 65, "sev": 50, "appeal": 75, "effort": 70, "calc": 260, "effectiveScore": 260}, "links": null}, {"id": "GH-10", "title": "prevent-half of containment: require_fixture adoption across the fixture-creating suites + adoption guard + ci-local identity bracket", "release": null, "lane": "Completed", "metrics": {"pri": 55, "sev": 70, "appeal": 50, "effort": 80, "calc": 255, "effectiveScore": 255}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/10"}}, {"id": "GH-144", "title": "Agent2Agent 3+ participant onboarding + read-only status quick wins", "release": null, "lane": "Completed", "metrics": {"pri": 55, "sev": 30, "appeal": 80, "effort": 90, "calc": 255, "effectiveScore": 255}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/144"}}, {"id": "GH-91", "title": "a build turn has nowhere to write verification output — containment kills a complete, green turn", "release": null, "lane": "Completed", "metrics": {"pri": 60, "sev": 65, "appeal": 55, "effort": 75, "calc": 255, "effectiveScore": 255}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/91"}}, {"id": "GH-153", "title": "RELEASES dashboard sidebar + full-cycle rollup (technical spike)", "release": null, "lane": "Completed", "metrics": {"pri": 70, "sev": 55, "appeal": 80, "effort": 45, "calc": 250, "effectiveScore": 250}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/153"}}, {"id": "GH-197", "title": "two-tier xyz-vendor.sh: Tier 1 core-harness default, Tier 2 opt-in RELEASES overlay + onboarding SOP (GH-105 follow-up)", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 80, "sev": 55, "appeal": 65, "effort": 50, "calc": 250, "effectiveScore": 250}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/197"}}, {"id": "GH-108", "title": "pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override)", "release": "Daybreak", "lane": "cut", "metrics": {"pri": 80, "sev": 50, "appeal": 75, "effort": 40, "calc": 245, "effectiveScore": 245}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/108"}}, {"id": "GH-105", "title": "vendor the RELEASES DB system + HTML timeline generator into the `.xyz` payload (optional add-on)", "release": "Cargo", "lane": "queue", "metrics": {"pri": 75, "sev": 50, "appeal": 60, "effort": 45, "calc": 230, "effectiveScore": 230}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/105"}}, {"id": "GH-32", "title": "RELEASES app: SQLite-backed release ledger, CLI-only writes, generated RELEASES.md, cross-repo UI", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 70, "sev": 50, "appeal": 65, "effort": 35, "calc": 220, "effectiveScore": 220}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/32"}}, {"id": "GH-5", "title": "kernel robustness: node:test unit runner", "release": "Bulkhead", "lane": "ad-hoc detour", "metrics": {"pri": 45, "sev": 40, "appeal": 45, "effort": 80, "calc": 210, "effectiveScore": 210}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/5"}}, {"id": "GH-35", "title": "3-tier test suite selection (docs / utility subsystems / core) + CPU governance", "release": null, "lane": "Completed", "metrics": {"pri": 55, "sev": 45, "appeal": 50, "effort": 45, "calc": 195, "effectiveScore": 195}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/35"}}, {"id": "GH-61", "title": "RELEASES ledger durability hardening (GH-57 follow-up)", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 45, "sev": 55, "appeal": 40, "effort": 50, "calc": 190, "effectiveScore": 190}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/62"}}, {"id": "GH-17", "title": "SOP for evaluating new agent harnesses and frontier models", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 45, "sev": 30, "appeal": 50, "effort": 60, "calc": 185, "effectiveScore": 185}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/17"}}, {"id": "GH-42", "title": "relay automation: supported Commandcode turn-taker", "release": null, "lane": "Completed", "metrics": {"pri": 50, "sev": 35, "appeal": 55, "effort": 45, "calc": 185, "effectiveScore": 185}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/42"}}, {"id": "GH-195", "title": "marathon-root-audit's blind spot: a direct `python3 marathon_drive.py` call", "release": null, "lane": "Completed", "metrics": {"pri": 60, "sev": 40, "appeal": 50, "effort": 20, "calc": 170, "effectiveScore": 170}, "links": null}, {"id": "GH-28", "title": "RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 40, "sev": 35, "appeal": 40, "effort": 55, "calc": 170, "effectiveScore": 170}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/28"}}, {"id": "GH-18", "title": "Harness evaluation: Command Code (cmd) and model matrix", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 35, "sev": 25, "appeal": 45, "effort": 55, "calc": 160, "effectiveScore": 160}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/18"}}], "justFinished": {"issue": "v0.7.2", "title": "Daybreak shipped", "closedDateDisplay": "2026-08-23", "closedAgoDisplay": "today", "issueUrl": "https://github.com/HiQS-Suite/XYZ-forge/issues/77"}, "whatsNext": {"issue": "v0.7.3", "title": "Bulkhead", "note": "target 2026-09-05 · in 13 days", "issueUrl": "https://github.com/HiQS-Suite/XYZ-forge/issues/179"}, "releases": [{"id": "c-0-1-0", "slug": "quicksilver", "name": "Quicksilver", "version": "0.1.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-01", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Quicksilver", "blurb": "Python-authoritative Tier-A twins.", "exit": "Python-authoritative Tier-A twins. Licensed AGPL-3.0-only (`LICENSE`) with a commercial option (`LICENSE-COMMERCIAL.md`), adopted 2026-07-29 post-ship; the pre-existing conflicting `LICENSE.md` was removed 2026-07-30 (#372).", "detours": [], "roadmap": []}, {"id": "c-0-2-0", "slug": "litmus", "name": "Litmus", "version": "0.2.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-14", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Litmus", "blurb": "Make the checks capable of failing.", "exit": "Exit: `bash test/litmus-release.sh --release-gate` exits 0. Red today by design; turning it green is what \"done\" means. Its own negative control is `--mutate-evidence`, which must detect a stripped declaration and an unregistered gate. NOTE the honest limit, stated in that file: the audit proves registration, declaration shape and the absence of false completion claims. It does NOT prove a control was truly observed, because `gate_inventory.py` reads a declaration authored by the same person who wrote the gate. Recorded execution of each control is deliberately out of scope for this release.", "detours": [], "roadmap": []}, {"id": "c-0-3-0", "slug": "nightwatch", "name": "Nightwatch", "version": "0.3.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-14", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Nightwatch", "blurb": "An unattended marathon against a real target repo survives, records, and recovers.", "exit": "Exit: `bash test/nightwatch-release.sh --release-gate` exits 0. BUILT 2026-08-11 and red by design, exactly as Litmus's was; turning it green is what \"done\" means. It has two halves because a metadata audit cannot answer this release's question. Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), and has a RECORDED control under `test/baselines/`; it also cross-checks that this list and the `Manifest:` line below agree, since a boundary that disagrees with itself is not frozen. Half B executes the lifecycle cases rather than auditing them, delegating to the suites that already drive real children and kill them rather than growing a second driver fixture here. Status on 2026-08-11: manifest 8/8 complete; lifecycle 5 passing, 0 NOT COVERED — GOALPOST MET. The last gap was the hostile-target write-set case, closed by #514, which was filed while executing this release and deliberately NOT admitted to the manifest (discovery is not admission); it belongs to the lifecycle list because the exit criterion always named that case — what was missing was a suite driving it. That lane also corrected its own premise: the pre-fix tree does not dispatch a turn first, it dies at the render's `git add` with an unhandled `CalledProcessError` traceback, so the discriminating assertion is the absence of that traceback rather than the absence of a dispatch. Its own negative control is `--mutate-evidence` (34/0), which unregisters a gate and deletes a recorded control in a fixture copy, requires both to be detected, and re-checks the unmutated inputs green in the same run so an always-red detector cannot pass for one. Honest limit, inherited from Litmus: Half A reads a declaration and a filename and cannot know a recorded control was honestly recorded; Half B is what narrows that, and is why this criterion is a command that kills children rather than a checklist.", "detours": [], "roadmap": []}, {"id": "c-0-7-0", "slug": "ballast", "name": "Ballast", "version": "0.7.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-18", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Ballast", "blurb": "Post-launch hardening: the launched repository holds up under a stranger's first run and an outside contributor's first push.", "exit": "Exit: `bash test/ballast-release.sh --release-gate` exits 0. NOT BUILT — writing it is Ballast's first task, before any member is fixed (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. Half A audits the frozen manifest: each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. Half B EXECUTES the stranger's path rather than auditing it: (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15's contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4's fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. SHIPPED 2026-08-18. `XYZ_BALLAST_STRANGER_RUNS=10 test/ballast-release.sh --release-gate` executed for real against a fresh disposable clone (`~/xyz-disposable/xyz-stranger-clone`): exit 0. Half A: 4 of 4 manifest members complete (#14, #15, #4, #3 — gate/registration/control/CLOSED-issue all confirmed). Half B: 4 of 4 passing (B1: 10/10 consecutive parallel runs with zero failures; B2a: ungated clone warning in-band; B2b: forced-red push refusal; B3: atomic-append cross-process stress case clean) — GOALPOST MET.", "detours": [], "roadmap": []}, {"id": "c-0-7-1", "slug": "bulwark", "name": "Bulwark", "version": "0.7.1", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-19", "extra": null, "itemsTotal": 3, "itemsOpen": 3, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Bulwark", "blurb": "Patch release on Ballast: the RELEASES ledger survives a git merge.", "exit": "Exit: test/gh32-releases-artifacts.sh, test/gh53-releases-merge-resolve.sh, test/gh54-merged-dump-refusals.sh and releases_app.py check all exit 0, AND this release's own merge into development resolves releases.sql without a hand-edit.", "detours": [], "roadmap": [{"id": "GH-52", "title": "issue GH-52", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/52"}}, {"id": "GH-53", "title": "issue GH-53", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/53"}}, {"id": "GH-54", "title": "issue GH-54", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/54"}}]}, {"id": "c-0-7-2", "slug": "daybreak", "name": "Daybreak", "version": "0.7.2", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-23", "extra": null, "itemsTotal": 9, "itemsOpen": 0, "baseline": {"count": 9, "at": "2026-08-21T04:21:29Z", "source": "backfilled", "growth": 0}, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Daybreak", "blurb": "The /standup skill completes: collect.sh implements the eight bounded lens reads that feed triage.py, and the skill runs end-to-end.", "exit": "Exit: collect.sh --fixture emits all eight lenses; triage.py consumes each without a D5; test/gh77-standup-triage.sh green with per-lens assertions AND a per-lens degradation assertion; the skill runs end-to-end on this repo and its output fits the 15-line cap; validate.sh full gate green.", "detours": [], "roadmap": [{"type": "marathon", "id": "GH-77", "url": "https://github.com/HiQS-Suite/XYZ-forge/issues/77", "title": "Daybreak marathon", "meta": "planned", "state": "run", "cards": [{"id": "GH-79", "title": "issue GH-79", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/79"}}, {"id": "GH-80", "title": "issue GH-80", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/80"}}, {"id": "GH-81", "title": "issue GH-81", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/81"}}, {"id": "GH-82", "title": "issue GH-82", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/82"}}, {"id": "GH-83", "title": "issue GH-83", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/83"}}, {"id": "GH-84", "title": "issue GH-84", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/84"}}, {"id": "GH-85", "title": "issue GH-85", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/85"}}, {"id": "GH-86", "title": "issue GH-86", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/86"}}, {"id": "GH-87", "title": "issue GH-87", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/87"}}]}, {"id": "GH-108", "title": "pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override)", "marker": "paused", "section": "deferred", "sectionLabel": "cut", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/108", "doc": "PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md"}, "metrics": {"pri": 80, "sev": 50, "appeal": 75, "effort": 40, "calc": 245, "effectiveScore": 245}}]}, {"id": "c-0-7-3", "slug": "bulkhead", "name": "Bulkhead", "version": "0.7.3", "status": "active", "flags": {"now": true}, "badge": {"type": "active", "label": "active"}, "dateLabel": "target", "date": "2026-09-05", "extra": "in 13 days", "itemsTotal": 13, "itemsOpen": 13, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Bulkhead", "blurb": "An unattended marathon survives its own harness.", "exit": "Exit: Each member suite (gh8, gh2, gh50, gh113, gh114, gh115, gh168) green and registered in validate.sh; full local gate green; manifest 7/7 shipped or explicitly cut.", "detours": [{"id": "GH-141", "title": "make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison", "marker": "wip", "section": "adhoc", "sectionLabel": "ad-hoc detour", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/141"}, "metrics": {"pri": 80, "sev": 65, "appeal": 85, "effort": 55, "calc": 285, "effectiveScore": 285}}, {"id": "GH-5", "title": "kernel robustness: node:test unit runner", "marker": "wip", "section": "adhoc", "sectionLabel": "ad-hoc detour", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/5"}, "metrics": {"pri": 45, "sev": 40, "appeal": 45, "effort": 80, "calc": 210, "effectiveScore": 210}}], "roadmap": [{"id": "GH-113", "title": "headless agy builder writes root scratch files, tripping containment (exit 6)", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/113", "doc": "PROJECT/2-WORKING/GH-113-HEADLESS-SCRATCH-CONTAINMENT.md"}, "metrics": {"pri": 85, "sev": 60, "appeal": 85, "effort": 60, "calc": 290, "effectiveScore": 290}}, {"id": "GH-114", "title": "headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7)", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/114", "doc": "PROJECT/2-WORKING/GH-114-HEADLESS-TTY-IDLE-HANG.md"}, "metrics": {"pri": 80, "sev": 60, "appeal": 80, "effort": 60, "calc": 280, "effectiveScore": 280}}, {"id": "GH-115", "title": "marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/115", "doc": "PROJECT/3-COMPLETED/GH-115-ROUND-CAP-ESCALATION.md"}, "metrics": {"pri": 75, "sev": 50, "appeal": 85, "effort": 70, "calc": 280, "effectiveScore": 280}}, {"id": "GH-168", "title": "wave_reconcile.py hard-fails and rolls back on pre-existing drift unrelated to the reconciled PR", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/168", "doc": "PROJECT/2-WORKING/GH-168-WAVE-RECONCILE-SCOPE.md"}, "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 70, "calc": 290, "effectiveScore": 290}}, {"id": "GH-8", "title": "kernel boundary hardening — CLI numeric validation, task/agent format contract", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/8", "doc": "PROJECT/3-COMPLETED/GH-8-KERNEL-BOUNDARY-HARDENING.md"}, "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 65, "calc": 275, "effectiveScore": 275}}, {"id": "GH-2", "title": "test-suite run relocated an untracked file into .tick/orphan-backups/", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/2", "doc": "PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md"}, "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 55, "calc": 275, "effectiveScore": 275}}, {"id": "GH-50", "title": "sandboxed git --track / branch -D half-applies and loses uncommitted work", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/50", "doc": "PROJECT/2-WORKING/GH-50-SANDBOXED-GIT-HALF-APPLY.md"}, "metrics": {"pri": 65, "sev": 35, "appeal": 85, "effort": 80, "calc": 265, "effectiveScore": 265}}, {"id": "GH-180", "title": "repro_builder crashes on timeout telemetry records (exit_code: null → TypeError)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/180", "doc": "PROJECT/3-COMPLETED/GH-180-REPRO-TIMEOUT-CRASH.md"}, "metrics": {"pri": 70, "sev": 45, "appeal": 85, "effort": 80, "calc": 280, "effectiveScore": 280}}, {"id": "GH-181", "title": "repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command, rc 127 vs expected 2)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/181", "doc": "PROJECT/3-COMPLETED/GH-181-REPRO-ADAPTER-FIDELITY.md"}, "metrics": {"pri": 90, "sev": 75, "appeal": 90, "effort": 60, "calc": 315, "effectiveScore": 315}}, {"id": "GH-182", "title": "self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/182", "doc": "PROJECT/2-WORKING/GH-182-HEALER-FACADE-SAFETY.md"}, "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 55, "calc": 265, "effectiveScore": 265}}, {"id": "GH-183", "title": "active_explorer env-family fuzzing unsound (base_env={} hardcoded, one always-deferring vector, ambient-env leakage)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/183", "doc": "PROJECT/3-COMPLETED/GH-183-EXPLORER-ENV-SOUNDNESS.md"}, "metrics": {"pri": 65, "sev": 50, "appeal": 75, "effort": 70, "calc": 260, "effectiveScore": 260}}, {"id": "GH-184", "title": "committed scratch artifact `.relay-scratch/probe_telemetry.json` makes every real turn a tracked-file mutation", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/184", "doc": "PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md"}, "metrics": {"pri": 60, "sev": 40, "appeal": 80, "effort": 90, "calc": 270, "effectiveScore": 270}}, {"id": "GH-174", "title": "Harness & Models Registry SQLite Migration: Per-Device Config, Reasoning Effort Tracking, AI Grading Hooks & Blog Generator", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/174", "doc": "PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md"}, "metrics": {"pri": 85, "sev": 75, "appeal": 95, "effort": 45, "calc": 300, "effectiveScore": 300}}]}, {"id": "c-0-9-0", "slug": "cargo", "name": "Cargo", "version": "0.9.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-09-19", "extra": "in 27 days", "itemsTotal": 2, "itemsOpen": 2, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Cargo", "blurb": "The harness travels with its ledger: the RELEASES DB system (releases_app.py CLI + merge resolver + FAQs) and the GH-103 HTML timeline generator (utils/timeline/) ship inside every vendored .xyz/ payload as an optional, never-wired-by-default add-on — a 'when you're ready' module a target repo enables by running releases init itself, matching RELEASES.md's own OPTIONAL philosophy (GH-381).", "exit": "Exit: A repo vendored with xyz-vendor.sh can, with zero extra downloads, run releases init/add and export_timeline.py --preview from .xyz/ against its own root, and xyz-sync.sh update preserves the target's ledger state (GH-312 preserve list). Nothing runs until the user invokes it.", "detours": [], "roadmap": [{"id": "GH-105", "title": "vendor the RELEASES DB system + HTML timeline generator into the `.xyz` payload (optional add-on)", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/105", "doc": "PROJECT/1-INBOX/GH-105-VENDOR-RELEASES-ADDON.md"}, "metrics": {"pri": 75, "sev": 50, "appeal": 60, "effort": 45, "calc": 230, "effectiveScore": 230}}, {"id": "GH-107", "title": "issue GH-107", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/107"}}]}, {"id": "c-0-6-0", "slug": "meter", "name": "Meter", "version": "0.6.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-09-26", "extra": "in 34 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Meter", "blurb": "XYZ can be handed to a stranger: an unauthenticated clone reaches a documented entry path and exercises a supported happy path with no private context, from a sanitized, secret-scanned tree.", "exit": "Exit: bash test/meter-release.sh --release-gate exits 0. NOT BUILT — written first, before any sanitization (the Litmus/Nightwatch ordering). Half A AUDITS the launch artifact: single-commit sanitized clone at the declared path; CHANGELOG.md byte-identical; .tick/, relay-system/, temp/ absent; PROJECT/ = PDDA scaffold + retained Meter example only; both LICENSE files present and consistent; secret-scan result names tool version and exact commit. Half B EXECUTES the stranger's path: a credential-less clone of the published commit completes one supported happy path with nothing author-machine-local. Negative control --mutate-evidence: plant a private path, remove CHANGELOG.md, leave a relay-system/ behind — detect all three, re-check unmutated inputs green in the same run. RED on arrival.", "detours": [], "roadmap": []}, {"id": "c-0-8-0", "slug": "sundown", "name": "Sundown", "version": "0.8.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-10-17", "extra": "in 55 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Sundown", "blurb": "Retire the twelve frozen Bash twins.", "exit": "Exit: NOT WRITTEN. Required before this release starts, per the ordering Litmus and Nightwatch both used and Meter is repeating — the gate is built first and arrives RED, because a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one.", "detours": [], "roadmap": []}, {"id": "c-0-4-0", "slug": "plumbline", "name": "Plumbline", "version": "0.4.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-11-14", "extra": "in 83 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Plumbline", "blurb": "Assisted reflection and a bounded self-improvement loop, measured before either is trusted.", "exit": "Assisted reflection and a bounded self-improvement loop, measured before either is trusted. The reflection pipeline turns durable Nightwatch records into proposals (`proposals-sink.sh` gains its first production caller) and is graded against external ground truth — the 49 human-f…", "detours": [], "roadmap": []}, {"id": "c-0-5-0", "slug": "lantern", "name": "Lantern", "version": "0.5.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-12-12", "extra": "in 111 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "milestones", "blurb": "When the harness fails, the information needed to act already exists inside it — make it say so.", "exit": "Exit: `bash test/lantern-release.sh --release-gate` exits 0. NOT BUILT. Writing it precedes fixing any member, which is the Litmus and Nightwatch ordering and the reason both releases could tell a finished entry from a claimed one. Two halves, the established shape: Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below. Half B executes #499's four phases rather than auditing them, since every one of them is a message an operator either receives or does not: a `relay-drive` launch preflight that refuses before spending, a gate refusal that states its real reason, a launcher exit code that survives its wrapper, and a change-impact report. #358 Phase 2 is the one member with no executable half, and the criterion is written around that rather than pretending otherwise: it is satisfied by a RECORDED transcript of a real CI failure under `test/baselines/`, and it must NOT be satisfiable by a disposition written in advance — that issue's own capture doc forbids pre-committing one, and an exit criterion that accepted a pre-written verdict would launder exactly the thing #419 exists to prevent. Its own negative control is `--mutate-evidence`, which must unregister a gate, delete a recorded control, and substitute a pre-dated disposition for a real transcript — detecting all three, and re-checking the unmutated inputs green in the same run so an always-red detector cannot pass for one.", "detours": [], "roadmap": []}], "projects": [{"slug": "XYZ-forge", "active": true}], "cycle": {"repo": "XYZ-forge", "generatedAt": "2026-08-24T03:30:06Z", "db": {"generation": 114, "receipts": 128, "lastOp": "2026-08-24T03:30:06Z", "schemaVersion": 5}, "releases": {"total": 12, "open": 6, "overdue": 0, "byStatus": {"active": 1, "draft": 5, "shipped": 6}, "openList": [{"version": "0.7.3", "codename": "Bulkhead", "status": "active", "target": "2026-09-05", "daysToTarget": 13}, {"version": "0.9.0", "codename": "Cargo", "status": "draft", "target": "2026-09-19", "daysToTarget": 27}, {"version": "0.6.0", "codename": "Meter", "status": "draft", "target": "2026-09-26", "daysToTarget": 34}, {"version": "0.8.0", "codename": "Sundown", "status": "draft", "target": "2026-10-17", "daysToTarget": 55}, {"version": "0.4.0", "codename": "Plumbline", "status": "draft", "target": "2026-11-14", "daysToTarget": 83}], "recentShipped": [{"version": "0.7.2", "shipped": "2026-08-23"}, {"version": "0.7.1", "shipped": "2026-08-19"}, {"version": "0.7.0", "shipped": "2026-08-18"}]}, "roadmap": {"total": 56, "unmarked": 9, "wip": 9, "queued": 0, "done": 38, "paused": 0}, "marathons": {"total": 1, "byStatus": {"planned": 1}, "runningRefs": ["GH-77"]}, "items": {"open": 0, "dialedIn": 18, "shipped": 9, "cut": 1}, "recentEvents": [{"at": "2026-08-23T04:30:03Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-87"}, {"at": "2026-08-23T04:30:02Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-85"}, {"at": "2026-08-23T04:30:02Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-86"}, {"at": "2026-08-23T04:30:01Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-82"}, {"at": "2026-08-23T04:30:01Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-83"}]}, "view": "leaderboard"}</script>
relay-system/2026-08-23/salvage-location-214521/salvage-location.codex.md:1312:./RELEASES-PREVIEW.html:375:<script id="ledger-data" type="application/json">{"meta": {"title": "Planning ledgers", "subtitle": "XYZ-forge · releases.db · read-only", "generatedAtDisplay": "2026-08-24 03:30:06Z", "sourceLabel": "releases.db · schema v5", "repoUrl": "https://github.com/HiQS-Suite/XYZ-forge"}, "sync": null, "telemetry": {"dbGeneration": 114, "receipts": 128, "lastSyncDisplay": "2026-08-24T03:30", "lastSyncAgoDisplay": "in 1 day", "releasesOpen": 6, "releasesTotal": 12, "releasesOverdue": 0}, "ratedTasks": [{"id": "GH-67", "title": "Commandcode builder default widened to `--yolo` — closer evaluation → possible build", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 88, "sev": 80, "appeal": 45, "effort": 70, "calc": 283, "effectiveScore": 340}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/67"}, "override": {"value": 340, "hot": true}}, {"id": "GH-181", "title": "repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command, rc 127 vs expected 2)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 90, "sev": 75, "appeal": 90, "effort": 60, "calc": 315, "effectiveScore": 315}, "links": null}, {"id": "GH-174", "title": "Harness & Models Registry SQLite Migration: Per-Device Config, Reasoning Effort Tracking, AI Grading Hooks & Blog Generator", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 85, "sev": 75, "appeal": 95, "effort": 45, "calc": 300, "effectiveScore": 300}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/174"}}, {"id": "GH-155", "title": "3rd Gen ATE & Fuzzing", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 70, "appeal": 90, "effort": 50, "calc": 295, "effectiveScore": 295}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/155"}}, {"id": "GH-165", "title": "Post-Merge Wave & Marathon Lifecycle Reconciler (Docs, ROADMAP, DB, Views, and Planning)", "release": null, "lane": "Completed", "metrics": {"pri": 90, "sev": 80, "appeal": 90, "effort": 35, "calc": 295, "effectiveScore": 295}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/165"}}, {"id": "GH-113", "title": "headless agy builder writes root scratch files, tripping containment (exit 6)", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 85, "sev": 60, "appeal": 85, "effort": 60, "calc": 290, "effectiveScore": 290}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/113"}}, {"id": "GH-148", "title": "DeepSeek Harness (dsh) integration & deepseek-turn shim for OpenRouter DeepSeek V4 Pro", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 75, "appeal": 90, "effort": 40, "calc": 290, "effectiveScore": 290}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/148"}}, {"id": "GH-168", "title": "wave_reconcile.py hard-fails and rolls back on pre-existing drift unrelated to the reconciled PR", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 70, "calc": 290, "effectiveScore": 290}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/168"}}, {"id": "GH-141", "title": "make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison", "release": "Bulkhead", "lane": "ad-hoc detour", "metrics": {"pri": 80, "sev": 65, "appeal": 85, "effort": 55, "calc": 285, "effectiveScore": 285}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/141"}}, {"id": "GH-114", "title": "headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7)", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 80, "sev": 60, "appeal": 80, "effort": 60, "calc": 280, "effectiveScore": 280}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/114"}}, {"id": "GH-115", "title": "marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 75, "sev": 50, "appeal": 85, "effort": 70, "calc": 280, "effectiveScore": 280}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/115"}}, {"id": "GH-180", "title": "repro_builder crashes on timeout telemetry records (exit_code: null → TypeError)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 70, "sev": 45, "appeal": 85, "effort": 80, "calc": 280, "effectiveScore": 280}, "links": null}, {"id": "GH-77", "title": "`/standup` — session-scoped triage: what did I leave open, what is rotting, is the plan still right?", "release": null, "lane": "Completed", "metrics": {"pri": 95, "sev": 70, "appeal": 85, "effort": 30, "calc": 280, "effectiveScore": 280}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/77"}}, {"id": "GH-124", "title": "eliminate end-of-day closeout friction — automated phase QA receipts, auto-PR creation, and clone lifecycle hygiene", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 60, "appeal": 90, "effort": 40, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/124"}}, {"id": "GH-132", "title": "feat(skills): formal /review-xyz code review skill & multi-model harness", "release": null, "lane": "Completed", "metrics": {"pri": 80, "sev": 70, "appeal": 85, "effort": 40, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/132"}}, {"id": "GH-170", "title": "Agent2Agent: close transcript glitches and harden publishing", "release": null, "lane": "Completed", "metrics": {"pri": 75, "sev": 60, "appeal": 85, "effort": 55, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/170"}}, {"id": "GH-2", "title": "test-suite run relocated an untracked file into .tick/orphan-backups/", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 55, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/2"}}, {"id": "GH-8", "title": "kernel boundary hardening — CLI numeric validation, task/agent format contract", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 65, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/8"}}, {"id": "GH-184", "title": "committed scratch artifact `.relay-scratch/probe_telemetry.json` makes every real turn a tracked-file mutation", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 60, "sev": 40, "appeal": 80, "effort": 90, "calc": 270, "effectiveScore": 270}, "links": null}, {"id": "GH-75", "title": "single-page HTML dashboard: releases (mid/long term) + roadmap (immediate) in one read-only view", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 90, "sev": 40, "appeal": 85, "effort": 55, "calc": 270, "effectiveScore": 270}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/75"}}, {"id": "GH-111", "title": "retire manifest FREEZE; tasks and marathons are DIALED IN to exactly one release, as a database state", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 75, "appeal": 70, "effort": 35, "calc": 265, "effectiveScore": 265}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/111"}}, {"id": "GH-182", "title": "self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 55, "calc": 265, "effectiveScore": 265}, "links": null}, {"id": "GH-50", "title": "sandboxed git --track / branch -D half-applies and loses uncommitted work", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 65, "sev": 35, "appeal": 85, "effort": 80, "calc": 265, "effectiveScore": 265}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/50"}}, {"id": "GH-183", "title": "active_explorer env-family fuzzing unsound (base_env={} hardcoded, one always-deferring vector, ambient-env leakage)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 65, "sev": 50, "appeal": 75, "effort": 70, "calc": 260, "effectiveScore": 260}, "links": null}, {"id": "GH-10", "title": "prevent-half of containment: require_fixture adoption across the fixture-creating suites + adoption guard + ci-local identity bracket", "release": null, "lane": "Completed", "metrics": {"pri": 55, "sev": 70, "appeal": 50, "effort": 80, "calc": 255, "effectiveScore": 255}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/10"}}, {"id": "GH-144", "title": "Agent2Agent 3+ participant onboarding + read-only status quick wins", "release": null, "lane": "Completed", "metrics": {"pri": 55, "sev": 30, "appeal": 80, "effort": 90, "calc": 255, "effectiveScore": 255}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/144"}}, {"id": "GH-91", "title": "a build turn has nowhere to write verification output — containment kills a complete, green turn", "release": null, "lane": "Completed", "metrics": {"pri": 60, "sev": 65, "appeal": 55, "effort": 75, "calc": 255, "effectiveScore": 255}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/91"}}, {"id": "GH-153", "title": "RELEASES dashboard sidebar + full-cycle rollup (technical spike)", "release": null, "lane": "Completed", "metrics": {"pri": 70, "sev": 55, "appeal": 80, "effort": 45, "calc": 250, "effectiveScore": 250}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/153"}}, {"id": "GH-197", "title": "two-tier xyz-vendor.sh: Tier 1 core-harness default, Tier 2 opt-in RELEASES overlay + onboarding SOP (GH-105 follow-up)", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 80, "sev": 55, "appeal": 65, "effort": 50, "calc": 250, "effectiveScore": 250}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/197"}}, {"id": "GH-108", "title": "pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override)", "release": "Daybreak", "lane": "cut", "metrics": {"pri": 80, "sev": 50, "appeal": 75, "effort": 40, "calc": 245, "effectiveScore": 245}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/108"}}, {"id": "GH-105", "title": "vendor the RELEASES DB system + HTML timeline generator into the `.xyz` payload (optional add-on)", "release": "Cargo", "lane": "queue", "metrics": {"pri": 75, "sev": 50, "appeal": 60, "effort": 45, "calc": 230, "effectiveScore": 230}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/105"}}, {"id": "GH-32", "title": "RELEASES app: SQLite-backed release ledger, CLI-only writes, generated RELEASES.md, cross-repo UI", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 70, "sev": 50, "appeal": 65, "effort": 35, "calc": 220, "effectiveScore": 220}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/32"}}, {"id": "GH-5", "title": "kernel robustness: node:test unit runner", "release": "Bulkhead", "lane": "ad-hoc detour", "metrics": {"pri": 45, "sev": 40, "appeal": 45, "effort": 80, "calc": 210, "effectiveScore": 210}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/5"}}, {"id": "GH-35", "title": "3-tier test suite selection (docs / utility subsystems / core) + CPU governance", "release": null, "lane": "Completed", "metrics": {"pri": 55, "sev": 45, "appeal": 50, "effort": 45, "calc": 195, "effectiveScore": 195}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/35"}}, {"id": "GH-61", "title": "RELEASES ledger durability hardening (GH-57 follow-up)", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 45, "sev": 55, "appeal": 40, "effort": 50, "calc": 190, "effectiveScore": 190}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/62"}}, {"id": "GH-17", "title": "SOP for evaluating new agent harnesses and frontier models", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 45, "sev": 30, "appeal": 50, "effort": 60, "calc": 185, "effectiveScore": 185}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/17"}}, {"id": "GH-42", "title": "relay automation: supported Commandcode turn-taker", "release": null, "lane": "Completed", "metrics": {"pri": 50, "sev": 35, "appeal": 55, "effort": 45, "calc": 185, "effectiveScore": 185}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/42"}}, {"id": "GH-195", "title": "marathon-root-audit's blind spot: a direct `python3 marathon_drive.py` call", "release": null, "lane": "Completed", "metrics": {"pri": 60, "sev": 40, "appeal": 50, "effort": 20, "calc": 170, "effectiveScore": 170}, "links": null}, {"id": "GH-28", "title": "RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 40, "sev": 35, "appeal": 40, "effort": 55, "calc": 170, "effectiveScore": 170}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/28"}}, {"id": "GH-18", "title": "Harness evaluation: Command Code (cmd) and model matrix", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 35, "sev": 25, "appeal": 45, "effort": 55, "calc": 160, "effectiveScore": 160}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/18"}}], "justFinished": {"issue": "v0.7.2", "title": "Daybreak shipped", "closedDateDisplay": "2026-08-23", "closedAgoDisplay": "today", "issueUrl": "https://github.com/HiQS-Suite/XYZ-forge/issues/77"}, "whatsNext": {"issue": "v0.7.3", "title": "Bulkhead", "note": "target 2026-09-05 · in 13 days", "issueUrl": "https://github.com/HiQS-Suite/XYZ-forge/issues/179"}, "releases": [{"id": "c-0-1-0", "slug": "quicksilver", "name": "Quicksilver", "version": "0.1.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-01", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Quicksilver", "blurb": "Python-authoritative Tier-A twins.", "exit": "Python-authoritative Tier-A twins. Licensed AGPL-3.0-only (`LICENSE`) with a commercial option (`LICENSE-COMMERCIAL.md`), adopted 2026-07-29 post-ship; the pre-existing conflicting `LICENSE.md` was removed 2026-07-30 (#372).", "detours": [], "roadmap": []}, {"id": "c-0-2-0", "slug": "litmus", "name": "Litmus", "version": "0.2.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-14", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Litmus", "blurb": "Make the checks capable of failing.", "exit": "Exit: `bash test/litmus-release.sh --release-gate` exits 0. Red today by design; turning it green is what \"done\" means. Its own negative control is `--mutate-evidence`, which must detect a stripped declaration and an unregistered gate. NOTE the honest limit, stated in that file: the audit proves registration, declaration shape and the absence of false completion claims. It does NOT prove a control was truly observed, because `gate_inventory.py` reads a declaration authored by the same person who wrote the gate. Recorded execution of each control is deliberately out of scope for this release.", "detours": [], "roadmap": []}, {"id": "c-0-3-0", "slug": "nightwatch", "name": "Nightwatch", "version": "0.3.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-14", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Nightwatch", "blurb": "An unattended marathon against a real target repo survives, records, and recovers.", "exit": "Exit: `bash test/nightwatch-release.sh --release-gate` exits 0. BUILT 2026-08-11 and red by design, exactly as Litmus's was; turning it green is what \"done\" means. It has two halves because a metadata audit cannot answer this release's question. Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), and has a RECORDED control under `test/baselines/`; it also cross-checks that this list and the `Manifest:` line below agree, since a boundary that disagrees with itself is not frozen. Half B executes the lifecycle cases rather than auditing them, delegating to the suites that already drive real children and kill them rather than growing a second driver fixture here. Status on 2026-08-11: manifest 8/8 complete; lifecycle 5 passing, 0 NOT COVERED — GOALPOST MET. The last gap was the hostile-target write-set case, closed by #514, which was filed while executing this release and deliberately NOT admitted to the manifest (discovery is not admission); it belongs to the lifecycle list because the exit criterion always named that case — what was missing was a suite driving it. That lane also corrected its own premise: the pre-fix tree does not dispatch a turn first, it dies at the render's `git add` with an unhandled `CalledProcessError` traceback, so the discriminating assertion is the absence of that traceback rather than the absence of a dispatch. Its own negative control is `--mutate-evidence` (34/0), which unregisters a gate and deletes a recorded control in a fixture copy, requires both to be detected, and re-checks the unmutated inputs green in the same run so an always-red detector cannot pass for one. Honest limit, inherited from Litmus: Half A reads a declaration and a filename and cannot know a recorded control was honestly recorded; Half B is what narrows that, and is why this criterion is a command that kills children rather than a checklist.", "detours": [], "roadmap": []}, {"id": "c-0-7-0", "slug": "ballast", "name": "Ballast", "version": "0.7.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-18", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Ballast", "blurb": "Post-launch hardening: the launched repository holds up under a stranger's first run and an outside contributor's first push.", "exit": "Exit: `bash test/ballast-release.sh --release-gate` exits 0. NOT BUILT — writing it is Ballast's first task, before any member is fixed (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. Half A audits the frozen manifest: each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. Half B EXECUTES the stranger's path rather than auditing it: (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15's contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4's fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. SHIPPED 2026-08-18. `XYZ_BALLAST_STRANGER_RUNS=10 test/ballast-release.sh --release-gate` executed for real against a fresh disposable clone (`~/xyz-disposable/xyz-stranger-clone`): exit 0. Half A: 4 of 4 manifest members complete (#14, #15, #4, #3 — gate/registration/control/CLOSED-issue all confirmed). Half B: 4 of 4 passing (B1: 10/10 consecutive parallel runs with zero failures; B2a: ungated clone warning in-band; B2b: forced-red push refusal; B3: atomic-append cross-process stress case clean) — GOALPOST MET.", "detours": [], "roadmap": []}, {"id": "c-0-7-1", "slug": "bulwark", "name": "Bulwark", "version": "0.7.1", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-19", "extra": null, "itemsTotal": 3, "itemsOpen": 3, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Bulwark", "blurb": "Patch release on Ballast: the RELEASES ledger survives a git merge.", "exit": "Exit: test/gh32-releases-artifacts.sh, test/gh53-releases-merge-resolve.sh, test/gh54-merged-dump-refusals.sh and releases_app.py check all exit 0, AND this release's own merge into development resolves releases.sql without a hand-edit.", "detours": [], "roadmap": [{"id": "GH-52", "title": "issue GH-52", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/52"}}, {"id": "GH-53", "title": "issue GH-53", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/53"}}, {"id": "GH-54", "title": "issue GH-54", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/54"}}]}, {"id": "c-0-7-2", "slug": "daybreak", "name": "Daybreak", "version": "0.7.2", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-23", "extra": null, "itemsTotal": 9, "itemsOpen": 0, "baseline": {"count": 9, "at": "2026-08-21T04:21:29Z", "source": "backfilled", "growth": 0}, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Daybreak", "blurb": "The /standup skill completes: collect.sh implements the eight bounded lens reads that feed triage.py, and the skill runs end-to-end.", "exit": "Exit: collect.sh --fixture emits all eight lenses; triage.py consumes each without a D5; test/gh77-standup-triage.sh green with per-lens assertions AND a per-lens degradation assertion; the skill runs end-to-end on this repo and its output fits the 15-line cap; validate.sh full gate green.", "detours": [], "roadmap": [{"type": "marathon", "id": "GH-77", "url": "https://github.com/HiQS-Suite/XYZ-forge/issues/77", "title": "Daybreak marathon", "meta": "planned", "state": "run", "cards": [{"id": "GH-79", "title": "issue GH-79", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/79"}}, {"id": "GH-80", "title": "issue GH-80", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/80"}}, {"id": "GH-81", "title": "issue GH-81", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/81"}}, {"id": "GH-82", "title": "issue GH-82", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/82"}}, {"id": "GH-83", "title": "issue GH-83", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/83"}}, {"id": "GH-84", "title": "issue GH-84", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/84"}}, {"id": "GH-85", "title": "issue GH-85", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/85"}}, {"id": "GH-86", "title": "issue GH-86", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/86"}}, {"id": "GH-87", "title": "issue GH-87", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/87"}}]}, {"id": "GH-108", "title": "pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override)", "marker": "paused", "section": "deferred", "sectionLabel": "cut", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/108", "doc": "PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md"}, "metrics": {"pri": 80, "sev": 50, "appeal": 75, "effort": 40, "calc": 245, "effectiveScore": 245}}]}, {"id": "c-0-7-3", "slug": "bulkhead", "name": "Bulkhead", "version": "0.7.3", "status": "active", "flags": {"now": true}, "badge": {"type": "active", "label": "active"}, "dateLabel": "target", "date": "2026-09-05", "extra": "in 13 days", "itemsTotal": 13, "itemsOpen": 13, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Bulkhead", "blurb": "An unattended marathon survives its own harness.", "exit": "Exit: Each member suite (gh8, gh2, gh50, gh113, gh114, gh115, gh168) green and registered in validate.sh; full local gate green; manifest 7/7 shipped or explicitly cut.", "detours": [{"id": "GH-141", "title": "make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison", "marker": "wip", "section": "adhoc", "sectionLabel": "ad-hoc detour", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/141"}, "metrics": {"pri": 80, "sev": 65, "appeal": 85, "effort": 55, "calc": 285, "effectiveScore": 285}}, {"id": "GH-5", "title": "kernel robustness: node:test unit runner", "marker": "wip", "section": "adhoc", "sectionLabel": "ad-hoc detour", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/5"}, "metrics": {"pri": 45, "sev": 40, "appeal": 45, "effort": 80, "calc": 210, "effectiveScore": 210}}], "roadmap": [{"id": "GH-113", "title": "headless agy builder writes root scratch files, tripping containment (exit 6)", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/113", "doc": "PROJECT/2-WORKING/GH-113-HEADLESS-SCRATCH-CONTAINMENT.md"}, "metrics": {"pri": 85, "sev": 60, "appeal": 85, "effort": 60, "calc": 290, "effectiveScore": 290}}, {"id": "GH-114", "title": "headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7)", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/114", "doc": "PROJECT/2-WORKING/GH-114-HEADLESS-TTY-IDLE-HANG.md"}, "metrics": {"pri": 80, "sev": 60, "appeal": 80, "effort": 60, "calc": 280, "effectiveScore": 280}}, {"id": "GH-115", "title": "marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/115", "doc": "PROJECT/3-COMPLETED/GH-115-ROUND-CAP-ESCALATION.md"}, "metrics": {"pri": 75, "sev": 50, "appeal": 85, "effort": 70, "calc": 280, "effectiveScore": 280}}, {"id": "GH-168", "title": "wave_reconcile.py hard-fails and rolls back on pre-existing drift unrelated to the reconciled PR", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/168", "doc": "PROJECT/2-WORKING/GH-168-WAVE-RECONCILE-SCOPE.md"}, "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 70, "calc": 290, "effectiveScore": 290}}, {"id": "GH-8", "title": "kernel boundary hardening — CLI numeric validation, task/agent format contract", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/8", "doc": "PROJECT/3-COMPLETED/GH-8-KERNEL-BOUNDARY-HARDENING.md"}, "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 65, "calc": 275, "effectiveScore": 275}}, {"id": "GH-2", "title": "test-suite run relocated an untracked file into .tick/orphan-backups/", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/2", "doc": "PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md"}, "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 55, "calc": 275, "effectiveScore": 275}}, {"id": "GH-50", "title": "sandboxed git --track / branch -D half-applies and loses uncommitted work", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/50", "doc": "PROJECT/2-WORKING/GH-50-SANDBOXED-GIT-HALF-APPLY.md"}, "metrics": {"pri": 65, "sev": 35, "appeal": 85, "effort": 80, "calc": 265, "effectiveScore": 265}}, {"id": "GH-180", "title": "repro_builder crashes on timeout telemetry records (exit_code: null → TypeError)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/180", "doc": "PROJECT/3-COMPLETED/GH-180-REPRO-TIMEOUT-CRASH.md"}, "metrics": {"pri": 70, "sev": 45, "appeal": 85, "effort": 80, "calc": 280, "effectiveScore": 280}}, {"id": "GH-181", "title": "repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command, rc 127 vs expected 2)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/181", "doc": "PROJECT/3-COMPLETED/GH-181-REPRO-ADAPTER-FIDELITY.md"}, "metrics": {"pri": 90, "sev": 75, "appeal": 90, "effort": 60, "calc": 315, "effectiveScore": 315}}, {"id": "GH-182", "title": "self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/182", "doc": "PROJECT/2-WORKING/GH-182-HEALER-FACADE-SAFETY.md"}, "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 55, "calc": 265, "effectiveScore": 265}}, {"id": "GH-183", "title": "active_explorer env-family fuzzing unsound (base_env={} hardcoded, one always-deferring vector, ambient-env leakage)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/183", "doc": "PROJECT/3-COMPLETED/GH-183-EXPLORER-ENV-SOUNDNESS.md"}, "metrics": {"pri": 65, "sev": 50, "appeal": 75, "effort": 70, "calc": 260, "effectiveScore": 260}}, {"id": "GH-184", "title": "committed scratch artifact `.relay-scratch/probe_telemetry.json` makes every real turn a tracked-file mutation", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/184", "doc": "PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md"}, "metrics": {"pri": 60, "sev": 40, "appeal": 80, "effort": 90, "calc": 270, "effectiveScore": 270}}, {"id": "GH-174", "title": "Harness & Models Registry SQLite Migration: Per-Device Config, Reasoning Effort Tracking, AI Grading Hooks & Blog Generator", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/174", "doc": "PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md"}, "metrics": {"pri": 85, "sev": 75, "appeal": 95, "effort": 45, "calc": 300, "effectiveScore": 300}}]}, {"id": "c-0-9-0", "slug": "cargo", "name": "Cargo", "version": "0.9.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-09-19", "extra": "in 27 days", "itemsTotal": 2, "itemsOpen": 2, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Cargo", "blurb": "The harness travels with its ledger: the RELEASES DB system (releases_app.py CLI + merge resolver + FAQs) and the GH-103 HTML timeline generator (utils/timeline/) ship inside every vendored .xyz/ payload as an optional, never-wired-by-default add-on — a 'when you're ready' module a target repo enables by running releases init itself, matching RELEASES.md's own OPTIONAL philosophy (GH-381).", "exit": "Exit: A repo vendored with xyz-vendor.sh can, with zero extra downloads, run releases init/add and export_timeline.py --preview from .xyz/ against its own root, and xyz-sync.sh update preserves the target's ledger state (GH-312 preserve list). Nothing runs until the user invokes it.", "detours": [], "roadmap": [{"id": "GH-105", "title": "vendor the RELEASES DB system + HTML timeline generator into the `.xyz` payload (optional add-on)", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/105", "doc": "PROJECT/1-INBOX/GH-105-VENDOR-RELEASES-ADDON.md"}, "metrics": {"pri": 75, "sev": 50, "appeal": 60, "effort": 45, "calc": 230, "effectiveScore": 230}}, {"id": "GH-107", "title": "issue GH-107", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/107"}}]}, {"id": "c-0-6-0", "slug": "meter", "name": "Meter", "version": "0.6.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-09-26", "extra": "in 34 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Meter", "blurb": "XYZ can be handed to a stranger: an unauthenticated clone reaches a documented entry path and exercises a supported happy path with no private context, from a sanitized, secret-scanned tree.", "exit": "Exit: bash test/meter-release.sh --release-gate exits 0. NOT BUILT — written first, before any sanitization (the Litmus/Nightwatch ordering). Half A AUDITS the launch artifact: single-commit sanitized clone at the declared path; CHANGELOG.md byte-identical; .tick/, relay-system/, temp/ absent; PROJECT/ = PDDA scaffold + retained Meter example only; both LICENSE files present and consistent; secret-scan result names tool version and exact commit. Half B EXECUTES the stranger's path: a credential-less clone of the published commit completes one supported happy path with nothing author-machine-local. Negative control --mutate-evidence: plant a private path, remove CHANGELOG.md, leave a relay-system/ behind — detect all three, re-check unmutated inputs green in the same run. RED on arrival.", "detours": [], "roadmap": []}, {"id": "c-0-8-0", "slug": "sundown", "name": "Sundown", "version": "0.8.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-10-17", "extra": "in 55 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Sundown", "blurb": "Retire the twelve frozen Bash twins.", "exit": "Exit: NOT WRITTEN. Required before this release starts, per the ordering Litmus and Nightwatch both used and Meter is repeating — the gate is built first and arrives RED, because a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one.", "detours": [], "roadmap": []}, {"id": "c-0-4-0", "slug": "plumbline", "name": "Plumbline", "version": "0.4.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-11-14", "extra": "in 83 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Plumbline", "blurb": "Assisted reflection and a bounded self-improvement loop, measured before either is trusted.", "exit": "Assisted reflection and a bounded self-improvement loop, measured before either is trusted. The reflection pipeline turns durable Nightwatch records into proposals (`proposals-sink.sh` gains its first production caller) and is graded against external ground truth — the 49 human-f…", "detours": [], "roadmap": []}, {"id": "c-0-5-0", "slug": "lantern", "name": "Lantern", "version": "0.5.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-12-12", "extra": "in 111 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "milestones", "blurb": "When the harness fails, the information needed to act already exists inside it — make it say so.", "exit": "Exit: `bash test/lantern-release.sh --release-gate` exits 0. NOT BUILT. Writing it precedes fixing any member, which is the Litmus and Nightwatch ordering and the reason both releases could tell a finished entry from a claimed one. Two halves, the established shape: Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below. Half B executes #499's four phases rather than auditing them, since every one of them is a message an operator either receives or does not: a `relay-drive` launch preflight that refuses before spending, a gate refusal that states its real reason, a launcher exit code that survives its wrapper, and a change-impact report. #358 Phase 2 is the one member with no executable half, and the criterion is written around that rather than pretending otherwise: it is satisfied by a RECORDED transcript of a real CI failure under `test/baselines/`, and it must NOT be satisfiable by a disposition written in advance — that issue's own capture doc forbids pre-committing one, and an exit criterion that accepted a pre-written verdict would launder exactly the thing #419 exists to prevent. Its own negative control is `--mutate-evidence`, which must unregister a gate, delete a recorded control, and substitute a pre-dated disposition for a real transcript — detecting all three, and re-checking the unmutated inputs green in the same run so an always-red detector cannot pass for one.", "detours": [], "roadmap": []}], "projects": [{"slug": "XYZ-forge", "active": true}], "cycle": {"repo": "XYZ-forge", "generatedAt": "2026-08-24T03:30:06Z", "db": {"generation": 114, "receipts": 128, "lastOp": "2026-08-24T03:30:06Z", "schemaVersion": 5}, "releases": {"total": 12, "open": 6, "overdue": 0, "byStatus": {"active": 1, "draft": 5, "shipped": 6}, "openList": [{"version": "0.7.3", "codename": "Bulkhead", "status": "active", "target": "2026-09-05", "daysToTarget": 13}, {"version": "0.9.0", "codename": "Cargo", "status": "draft", "target": "2026-09-19", "daysToTarget": 27}, {"version": "0.6.0", "codename": "Meter", "status": "draft", "target": "2026-09-26", "daysToTarget": 34}, {"version": "0.8.0", "codename": "Sundown", "status": "draft", "target": "2026-10-17", "daysToTarget": 55}, {"version": "0.4.0", "codename": "Plumbline", "status": "draft", "target": "2026-11-14", "daysToTarget": 83}], "recentShipped": [{"version": "0.7.2", "shipped": "2026-08-23"}, {"version": "0.7.1", "shipped": "2026-08-19"}, {"version": "0.7.0", "shipped": "2026-08-18"}]}, "roadmap": {"total": 56, "unmarked": 9, "wip": 9, "queued": 0, "done": 38, "paused": 0}, "marathons": {"total": 1, "byStatus": {"planned": 1}, "runningRefs": ["GH-77"]}, "items": {"open": 0, "dialedIn": 18, "shipped": 9, "cut": 1}, "recentEvents": [{"at": "2026-08-23T04:30:03Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-87"}, {"at": "2026-08-23T04:30:02Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-85"}, {"at": "2026-08-23T04:30:02Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-86"}, {"at": "2026-08-23T04:30:01Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-82"}, {"at": "2026-08-23T04:30:01Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-83"}]}}</script>
relay-system/2026-08-25/canary-root-euid-203501/canary-root-euid.codex.md:1186:utils/timeline/README.md-20-  self-contained `RELEASES-PREVIEW.html` (default: repo root). Generated artifact —
relay-system/2026-08-25/canary-root-euid-203501/canary-root-euid.codex.md:1564:utils/timeline/export_timeline.py-12-self-contained RELEASES-PREVIEW.html (default: repo root), and --serve PORT
relay-system/2026-08-28/gh280-phase4-dogfood/gh105/gh280-dogfood-run2.log:2:marathon-drive:   • LEADERBOARD.html
relay-system/2026-08-28/gh280-phase4-dogfood/gh105/gh280-dogfood-run2.log:6:marathon-drive:   • RELEASES-PREVIEW.html
relay-system/2026-08-28/gh280-phase4-dogfood/gh107-orphan-backup/20260828T022003Z-80043/scratch/test_export/RELEASES.html:288:    <a class="sn-item" id="sn-view-a" href="./LEADERBOARD.html"><span class="sn-ico">◫</span><span class="sn-label">leaderboard</span></a>
relay-system/2026-08-28/gh280-phase4-dogfood/gh107-orphan-backup/20260828T022003Z-80043/scratch/test_export/RELEASES.html:324:      <a id="view-link" class="mono" href="./LEADERBOARD.html"
relay-system/2026-08-28/gh280-phase4-dogfood/gh107-orphan-backup/20260828T022003Z-80043/scratch/test_export/RELEASES.html:427:    document.getElementById('sn-view-a').href=lb?'#':'./LEADERBOARD.html';
relay-system/2026-08-28/gh280-phase4-dogfood/gh107-orphan-backup/20260828T022003Z-80043/scratch/test_export/RELEASES.html:428:    document.getElementById('sn-view-b').href=lb?'./RELEASES-PREVIEW.html':'#';
relay-system/2026-08-28/gh280-phase4-dogfood/gh107-orphan-backup/20260828T022003Z-80043/scratch/test_export/RELEASES.html:687:      link.href=view==='leaderboard'?'./RELEASES-PREVIEW.html':'./LEADERBOARD.html';
relay-system/2026-08-28/gh280-phase4-dogfood/gh107-orphan-backup/20260828T022003Z-80043/scratch/test_export/index.html:288:    <a class="sn-item" id="sn-view-a" href="./LEADERBOARD.html"><span class="sn-ico">◫</span><span class="sn-label">leaderboard</span></a>
relay-system/2026-08-28/gh280-phase4-dogfood/gh107-orphan-backup/20260828T022003Z-80043/scratch/test_export/index.html:324:      <a id="view-link" class="mono" href="./LEADERBOARD.html"
relay-system/2026-08-28/gh280-phase4-dogfood/gh107-orphan-backup/20260828T022003Z-80043/scratch/test_export/index.html:427:    document.getElementById('sn-view-a').href=lb?'#':'./LEADERBOARD.html';
relay-system/2026-08-28/gh280-phase4-dogfood/gh107-orphan-backup/20260828T022003Z-80043/scratch/test_export/index.html:428:    document.getElementById('sn-view-b').href=lb?'./RELEASES-PREVIEW.html':'#';
relay-system/2026-08-28/gh280-phase4-dogfood/gh107-orphan-backup/20260828T022003Z-80043/scratch/test_export/index.html:687:      link.href=view==='leaderboard'?'./RELEASES-PREVIEW.html':'./LEADERBOARD.html';
relay-system/2026-08-28/gh280-phase4-dogfood/gh107/gh280-dogfood-retry1.log:2:marathon-drive:   • LEADERBOARD.html
relay-system/2026-08-28/gh280-phase4-dogfood/gh107/gh280-dogfood-retry1.log:4:marathon-drive:   • RELEASES-PREVIEW.html
relay-system/2026-08-28/gh280-phase4-dogfood/gh107/gh280-dogfood-run1.log:3:marathon-drive:   • LEADERBOARD.html
relay-system/2026-08-28/gh280-phase4-dogfood/gh107/gh280-dogfood-run1.log:6:marathon-drive:   • RELEASES-PREVIEW.html
relay-system/2026-08-29/gh222-executor-dogfood/gh222-retry-build2.log:4:marathon-drive:   • LEADERBOARD.html
relay-system/2026-08-29/gh222-executor-dogfood/gh222-retry-build2.log:5:marathon-drive:   • RELEASES-PREVIEW.html
relay-system/2026-08-29/gh222-executor-dogfood/gh222-retry-build3.log:2:marathon-drive:   • LEADERBOARD.html
relay-system/2026-08-29/gh222-executor-dogfood/gh222-retry-build3.log:3:marathon-drive:   • RELEASES-PREVIEW.html
relay-system/2026-09-02/gh123-cancel-linux-rc-qa.md:15:Diff: `LEADERBOARD.html`, `LEADERBOARD.md`, `RELEASES-PREVIEW.html`, `releases.db`, `releases.sql`.
releases.sql:414:INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr) VALUES('rmi-01M0GKR98K9X9FYJVH6CPSQ2BP', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '103', 'GH-103 · technical spike: RELEASES SQLite → timeline-ui ledger viewer (RELEASES dashboard view)', 'Completed', '39', '✅', NULL, NULL, NULL, 'PROJECT/1-INBOX/GH-103-TIMELINE-LEDGER-SPIKE.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/103', '- **GH-103 · technical spike: RELEASES SQLite → timeline-ui ledger viewer (RELEASES dashboard view)** ✅ **SHIPPED 2026-08-20 (PR #104; issue closed)** — read-only exporter `utils/timeline/export_timeline.py` projects `releases.db` into timeline-ui''s `data.json` contract; viewer `utils/timeline/RELEASES.html` (header collapse caret, full-viewport liquid layout, scrollable detour lanes); `--preview` bakes the committed `RELEASES-PREVIEW.html` snapshot, auto-refreshed after every CLI write by the GH-106 hook; `--serve` answers `/data.json` live from the DB; band-aware RELEASES.md-vs-DB drift banner. Zero DB writes (SQLite `mode=ro`). Prototype for the queued #75 `releases dashboard` verb; follow-on integration tracked in #107 (Cargo). → [GH-103-TIMELINE-LEDGER-SPIKE.md](PROJECT/1-INBOX/GH-103-TIMELINE-LEDGER-SPIKE.md) · [#103](https://github.com/HiQS-Labs/XYZ-forge/issues/103) (rated 62/35/75/50)', '2026-08-20T22:13:04Z', '2026-08-26T05:32:06Z', '62', '35', '75', '50', NULL);
releases.sql:416:INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr) VALUES('rmi-01M0H9CC0AAF9JWBSHR3679NQQ', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '108', 'GH-108 · pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override)', 'Completed', '36', '✅', NULL, NULL, NULL, 'PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/108', '- **GH-108 · pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override)** ✅ **SHIPPED 2026-08-21 (PR #116; issue closed)** — one scoring vocabulary for every task in the ledger, oriented so a single glance answers what should go to the front of the line: four axes 1-100 where higher is always better (effort scores cheapness), a combined 4-400 `calc` derived and never stored, and an `ovr` override that pins anything visible. Authored as `rated N/N/N/N` on a ROADMAP entry; read via `bash utils/leaderboard.sh` or LEADERBOARD.html. rated 80/50/75/40. → [GH-108-RATING-SYSTEM.md](PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md) · [#108](https://github.com/HiQS-Labs/XYZ-forge/issues/108)', '2026-08-21T04:31:03Z', '2026-08-25T02:10:14Z', '80', '50', '75', '40', NULL);
releases.sql:470:INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr) VALUES('rmi-01M122CV0YB16Q87H28ASDAFFG', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '269', 'Full switchover to Releases DB — retire ROADMAP.md', 'Completed', '20', '🆕', NULL, NULL, NULL, 'PROJECT/2-WORKING/GH-269-RELEASES-DB-SWITCHOVER.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/269', '- **GH-269 · full switchover to Releases DB — retire ROADMAP.md** ✅ **SHIPPED 2026-09-04 (PR #432)** — retire ROADMAP.md** 🆕 **captured 2026-08-27** (rated 75/65/65/50) — [GH-269-RELEASES-DB-SWITCHOVER.md](PROJECT/3-COMPLETED/GH-269-RELEASES-DB-SWITCHOVER.md) — migrate readers/writers/gates/canary off the frozen file; ATE-verified; RELEASES-PREVIEW.html survives', '2026-08-27T16:56:03Z', '2026-09-04T06:20:12Z', '75', '65', '65', '50', NULL);
skills/relay-xyz/SKILL.md:182:`RELEASES-PREVIEW.html`) lives at the target repository root, outside `.xyz/`, while `.xyz/`-resident
test/gh103-timeline-exporter.sh:228:LB_HTML="$WORK/LEADERBOARD.html"
test/gh153-releases-sidebar-rollup.sh:112:PREVIEW="$WORK/RELEASES-PREVIEW.html"
test/gh153-releases-sidebar-rollup.sh:113:LEADER="$WORK/LEADERBOARD.html"
test/gh267-express-skill.sh:126:    for name in ("releases.sql", "RELEASES.generated.md", "RELEASES-PREVIEW.html",
test/gh267-express-skill.sh:127:                 "LEADERBOARD.html", "LEADERBOARD.md"):
test/gh267-express-skill.sh:154:for projection in RELEASES.generated.md RELEASES-PREVIEW.html LEADERBOARD.html LEADERBOARD.md ROADMAP-DASHBOARD.md; do
test/gh267-express-skill.sh:232:new_task_branch; printf 'x\n' >> "$FX/utils/py/foo.py"; printf 'hand edit\n' > "$FX/RELEASES-PREVIEW.html"
test/gh57-live-merge-resolve.sh:239:# RELEASES-PREVIEW.html, LEADERBOARD.html and LEADERBOARD.md are all rendered from ledger
test/gh57-live-merge-resolve.sh:255:  python3 "$ROOT_DIR/utils/timeline/export_timeline.py" --db "$r/releases.db" --preview "$r/RELEASES-PREVIEW.html"
test/gh57-live-merge-resolve.sh:256:  python3 "$ROOT_DIR/utils/timeline/export_timeline.py" --db "$r/releases.db" --leaderboard "$r/LEADERBOARD.html"
test/gh57-live-merge-resolve.sh:260:V8="ROADMAP-DASHBOARD.md RELEASES-PREVIEW.html LEADERBOARD.html LEADERBOARD.md"
test/gh57-live-merge-resolve.sh:297:ok "staged RELEASES-PREVIEW.html reflects the MERGED ledger (both sides' releases present)" \
test/gh57-live-merge-resolve.sh:298:   "grep -q '\"releasesTotal\": 2' '$R8/RELEASES-PREVIEW.html'"
utils/README.md:120:| [`utils/timeline/`](timeline/) | **Interactive Ledger Viewer:** Exporter (`export_timeline.py`) projecting SQLite `releases.db` into liquid HTML timeline views (`RELEASES.html`, `RELEASES-PREVIEW.html`). |
utils/py/express.py:73:    "RELEASES-PREVIEW.html",
utils/py/express.py:74:    "LEADERBOARD.html",
utils/py/jog_run.py:285:                         "ROADMAP-DASHBOARD.md", "LEADERBOARD.html", "RELEASES-PREVIEW.html")
utils/py/releases_app.py:1170:    GH-108 adds LEADERBOARD.html on the same terms — one template, two baked artifacts, both
utils/py/releases_app.py:1175:    for name, flag in (("RELEASES-PREVIEW.html", "--preview"),
utils/py/releases_app.py:1176:                       ("LEADERBOARD.html", "--leaderboard")):
utils/py/wave_reconcile.py:729:            "RELEASES-PREVIEW.html",
utils/py/wave_reconcile.py:730:            "LEADERBOARD.html",
utils/py/wave_reconcile.py:799:                "RELEASES-PREVIEW.html",
utils/py/wave_reconcile.py:800:                "LEADERBOARD.html",
utils/releases-merge-resolve.sh:16:#   5. regenerate adopted views   — ROADMAP-DASHBOARD.md / RELEASES-PREVIEW.html /
utils/releases-merge-resolve.sh:17:#                                  LEADERBOARD.html / LEADERBOARD.md are all rendered from
utils/releases-merge-resolve.sh:160:VIEWS="ROADMAP-DASHBOARD.md RELEASES-PREVIEW.html LEADERBOARD.html LEADERBOARD.md"
utils/releases-merge-resolve.sh:188:    *" RELEASES-PREVIEW.html "*)
utils/releases-merge-resolve.sh:190:      if ! python3 "$HERE/timeline/export_timeline.py" --db "$ROOT/releases.db" --preview "$ROOT/RELEASES-PREVIEW.html"; then
utils/releases-merge-resolve.sh:192:  RELEASES-PREVIEW.html has not been staged."
utils/releases-merge-resolve.sh:197:    *" LEADERBOARD.html "*)
utils/releases-merge-resolve.sh:199:      if ! python3 "$HERE/timeline/export_timeline.py" --db "$ROOT/releases.db" --leaderboard "$ROOT/LEADERBOARD.html"; then
utils/releases-merge-resolve.sh:201:  LEADERBOARD.html has not been staged."
utils/timeline/README.md:13:python3 utils/timeline/export_timeline.py --preview     # bake ./RELEASES-PREVIEW.html (one file, opens from disk)
utils/timeline/README.md:20:  self-contained `RELEASES-PREVIEW.html` (default: repo root). Generated artifact —
utils/timeline/RELEASES.html:288:    <a class="sn-item" id="sn-view-a" href="./LEADERBOARD.html"><span class="sn-ico">◫</span><span class="sn-label">leaderboard</span></a>
utils/timeline/RELEASES.html:324:      <a id="view-link" class="mono" href="./LEADERBOARD.html"
utils/timeline/RELEASES.html:427:    document.getElementById('sn-view-a').href=lb?'#':'./LEADERBOARD.html';
utils/timeline/RELEASES.html:428:    document.getElementById('sn-view-b').href=lb?'./RELEASES-PREVIEW.html':'#';
utils/timeline/RELEASES.html:687:      link.href=view==='leaderboard'?'./RELEASES-PREVIEW.html':'./LEADERBOARD.html';
utils/timeline/export_timeline.py:12:self-contained RELEASES-PREVIEW.html (default: repo root), and --serve PORT
utils/timeline/export_timeline.py:603:    ap.add_argument("--preview", nargs="?", const=Path("RELEASES-PREVIEW.html"), default=None,
utils/timeline/export_timeline.py:605:                    help="bake current DB state into one self-contained HTML (default: ./RELEASES-PREVIEW.html)")
utils/timeline/export_timeline.py:606:    ap.add_argument("--leaderboard", nargs="?", const=Path("LEADERBOARD.html"), default=None,
utils/timeline/export_timeline.py:608:                    help="bake the ranked view from the SAME template (default: ./LEADERBOARD.html)")
   175	    if not os.path.lexists(path):
   176	        return "missing"
   177	    if os.path.islink(path):
   178	        return "link:" + os.readlink(path)
   179	    if os.path.isfile(path):
   180	        digest = hashlib.sha256()
   181	        with open(path, "rb") as f:
   182	            for chunk in iter(lambda: f.read(1024 * 1024), b""):
   183	                digest.update(chunk)
   184	        return "file:" + digest.hexdigest()
   185	    if os.path.isdir(path):
   186	        digest = hashlib.sha256()
   187	        for name in sorted(os.listdir(path)):
   188	            child = os.path.join(path, name)
   189	            digest.update(name.encode("utf-8", "surrogateescape"))
   190	            digest.update(b"\0")
   191	            digest.update(path_fingerprint(child).encode("utf-8", "surrogateescape"))
   192	            digest.update(b"\0")
   193	        return "dir:" + digest.hexdigest()
   194	    st = os.lstat(path)
   195	    return "other:%d:%d" % (st.st_mode, st.st_size)
   196	
   197	
   198	def snapshot_paths(root, paths):
   199	    return {p: path_fingerprint(os.path.join(root, p)) for p in paths}
   200	
   201	
   202	def driver_projection_paths(root):
   203	    paths = set(DRIVER_LEDGER)
   204	    paths.update(p for p in RELEASES_PROJECTIONS if os.path.lexists(os.path.join(root, p)))
   205	    if os.path.isfile(os.path.join(root, "utils", "roadmap-dashboard.sh")):
   206	        paths.add("ROADMAP-DASHBOARD.md")
   207	    return paths
   208	
   209	
   210	def core_paths(paths):
   211	    return [p for p in paths if not is_doc_path(p)]
   212	
   213	
   214	def is_doc_path(p):
   215	    """The lane's own paperwork never counts against the size bounds; every
   216	    other path — including operator-supplied .md — counts (finding 5)."""
   217	    return p == "CHANGELOG.md" or p.startswith("PROJECT/")
   218	
   219	
   220	def insertions(root, paths, expect_driver=frozenset()):
   221	    total = 0
   222	    numstat = git(root, "diff", "origin/development", "--numstat", check=False).stdout
   223	    tracked = {}
   224	    for line in numstat.splitlines():
   225	        parts = line.split("\t")
  1130	GEN_MARKER_RE = re.compile(r"^<!-- releases-app generation: (\d+) -->$")
  1131	
  1132	
  1133	def gen_marker(generation):
  1134	    return "<!-- releases-app generation: %d -->" % generation
  1135	
  1136	
  1137	# ── staged writes + crash injection ─────────────────────────────────────────────────────────────
  1138	
  1139	def _crash(boundary):
  1140	    if os.environ.get("RELEASES_APP_CRASH_AT", "") == boundary:
  1141	        sys.stdout.flush()
  1142	        sys.stderr.flush()
  1143	        os._exit(EXIT_CRASH_INJECTED)
  1144	
  1145	
  1146	def _stage_write(final_path, content):
  1147	    """Staged temp-name write; the caller renames (atomic) only once the DB commit is durable."""
  1148	    tmp = "%s.tmp-%s" % (final_path, new_txn_id()[:12])
  1149	    with open(tmp, "w", encoding="utf-8", newline="\n") as fh:
  1150	        fh.write(content)
  1151	        fh.flush()
  1152	        os.fsync(fh.fileno())
  1153	    return tmp
  1154	
  1155	
  1156	def _atomic_write(final_path, content):
  1157	    tmp = _stage_write(final_path, content)
  1158	    os.replace(tmp, final_path)
  1159	
  1160	
  1161	# ── the writer protocol (PRD Git story 2-3): journal -> txn -> stage -> rename -> clear ─────────
  1162	
  1163	def refresh_preview(root):
  1164	    """GH-106: after a successful write, refresh the baked viewer artifacts — but only the ones
  1165	    the repo has ADOPTED (the file already exists at root; presence is the opt-in signal, so
  1166	    fixtures and non-adopting repos are silent no-ops). Best-effort by design: the write is
  1167	    already durable with its receipt when this runs, so a refresh failure WARNS on stderr and
  1168	    never fails the operation. Success is silent (the exporter's stdout is captured).
  1169	
  1170	    GH-108 adds LEADERBOARD.html on the same terms — one template, two baked artifacts, both
  1171	    regenerated by the same hook so a ranking can never lag the ledger it ranks."""
  1172	    exporter = os.path.join(root, "utils", "timeline", "export_timeline.py")
  1173	    if not os.path.exists(exporter):
  1174	        return
  1175	    for name, flag in (("RELEASES-PREVIEW.html", "--preview"),
  1176	                       ("LEADERBOARD.html", "--leaderboard")):
  1177	        target = os.path.join(root, name)
  1178	        if not os.path.exists(target):
  1179	            continue
  1180	        try:
  1181	            r = subprocess.run([sys.executable, exporter, flag, target],
  1182	                               cwd=root, capture_output=True, text=True, timeout=60)
  1183	            if r.returncode != 0:
  1184	                print("warning: %s refresh failed (the write itself is committed): %s"
  1185	                      % (name, r.stderr.strip() or r.stdout.strip() or
  1186	                         "exit %d" % r.returncode), file=sys.stderr)
  1187	        except Exception as exc:  # never let a rendered artifact break a committed write
  1188	            print("warning: %s refresh failed (the write itself is committed): %s"
  1189	                  % (name, exc), file=sys.stderr)
  1190	    # LEADERBOARD.md rides the same adoption signal — generated, never hand-edited.
  1191	    board = os.path.join(root, "LEADERBOARD.md")
  1192	    script = os.path.join(root, "utils", "leaderboard.sh")
  1193	    if os.path.exists(board) and os.path.exists(script):
  1194	        try:
  1195	            r = subprocess.run(["bash", script], cwd=root, capture_output=True, text=True,
  1196	                               timeout=60)
  1197	            if r.returncode != 0:
  1198	                print("warning: LEADERBOARD.md refresh failed (the write itself is committed): %s"
  1199	                      % (r.stderr.strip() or "exit %d" % r.returncode), file=sys.stderr)
  1200	        except Exception as exc:
  1201	            print("warning: LEADERBOARD.md refresh failed (the write itself is committed): %s"
  1202	                  % exc, file=sys.stderr)
  1203	
  1204	
  1205	def perform_write(root, conn, op, target_gid, mutate):
  1206	    """Run one CLI transaction under the full multi-artifact protocol:
  1207	
  1208	      write intent journal (txn_id, NEXT generation, planned outputs)   [BEFORE the DB commit]
  1209	      -> BEGIN IMMEDIATE -> mutate -> stamp generation into settings -> COMMIT
  1210	      -> stage dump (+ generated view when one exists), each carrying that generation
  1211	      -> atomic renames -> clear journal.
  1212	
  1213	    `mutate(conn)` does the business writes; the op_receipt (before/after business-state digests)
  1214	    is appended HERE so no writer can forget it. Recovery per boundary is `check`'s job
  1215	    (recover_from_journal); RELEASES_APP_CRASH_AT lands on the five named boundaries. The caller
  1216	    must NOT hold the writer lock (this function takes it)."""
  1217	    paths = artifact_paths(root)
  1218	    lock = WriterLock(root)
  1219	    lock.acquire()
  1220	    try:
  1221	        if os.path.exists(lock.journal_path):
  1222	            refuse("journal-live",
  1223	                   "an intent journal from an interrupted write exists (%s); run `releases check` "
  1224	                   "to recover before writing again" % lock.journal_path)
  1225	
   175	if [ -n "$REGEN" ]; then
   176	  say "regenerating adopted views: $REGEN"
   177	  case " $REGEN " in
   178	    *" ROADMAP-DASHBOARD.md "*)
   179	      say "  -> roadmap-dashboard.sh"
   180	      if ! ROADMAP_DASHBOARD_ROOT="$ROOT" bash "$HERE/roadmap-dashboard.sh"; then
   181	        die "roadmap-dashboard.sh failed. The merge is left open on purpose — staging the
   182	  stale dashboard against a rebuilt ledger would commit exactly the divergence this
   183	  resolver exists to prevent."
   184	      fi
   185	      ;;
   186	  esac
   187	  case " $REGEN " in
   188	    *" RELEASES-PREVIEW.html "*)
   189	      say "  -> export_timeline.py --preview"
   190	      if ! python3 "$HERE/timeline/export_timeline.py" --db "$ROOT/releases.db" --preview "$ROOT/RELEASES-PREVIEW.html"; then
   191	        die "export_timeline.py --preview failed. The merge is left open on purpose; the stale
   192	  RELEASES-PREVIEW.html has not been staged."
   193	      fi
   194	      ;;
   195	  esac
   196	  case " $REGEN " in
   197	    *" LEADERBOARD.html "*)
   198	      say "  -> export_timeline.py --leaderboard"
   199	      if ! python3 "$HERE/timeline/export_timeline.py" --db "$ROOT/releases.db" --leaderboard "$ROOT/LEADERBOARD.html"; then
   200	        die "export_timeline.py --leaderboard failed. The merge is left open on purpose; the stale
   201	  LEADERBOARD.html has not been staged."
   202	      fi
   203	      ;;
   204	  esac
   205	  case " $REGEN " in
   206	    *" LEADERBOARD.md "*)
   207	      say "  -> leaderboard.sh"
   208	      if ! LEADERBOARD_DB="$ROOT/releases.db" LEADERBOARD_OUTPUT="$ROOT/LEADERBOARD.md" bash "$HERE/leaderboard.sh"; then
   209	        die "leaderboard.sh failed. The merge is left open on purpose; the stale LEADERBOARD.md
   210	  has not been staged."
   211	      fi
   212	      ;;
   213	  esac
   214	fi
   215	
   216	# ── 6. stage what the rebuild regenerated — the FIRST point at which anything is resolved ───────
   217	for f in $TOOK_SIDE; do
   218	  say "resolving $f in the index now that the rebuild verified clean"
   219	done
   220	# One `git add` for the whole handled set (codex consult: per-path adds could stage a subset
   221	# when a later add fails), gated on existence, then a postcondition: nothing we handled may
   222	# still be unmerged.
   223	ADD_PATHS=""
   224	for f in $DERIVED releases.sql $REGEN; do
   225	  [ -f "$ROOT/$f" ] && ADD_PATHS="${ADD_PATHS:+$ADD_PATHS }$f"
   226	done
   227	[ -n "$ADD_PATHS" ] && git -C "$ROOT" add -- $ADD_PATHS
   228	LEFT_UNMERGED="$(git -C "$ROOT" diff --name-only --diff-filter=U 2>/dev/null || true)"
   229	for f in $ADD_PATHS; do
   230	  if printf '%s\n' "$LEFT_UNMERGED" | grep -qx "$f"; then

exec
/bin/zsh -lc "rg -n --hidden --glob '"'!.git'"' 'LEADERBOARD\\.html|RELEASES-PREVIEW\\.html' .; nl -ba utils/py/express.py | sed -n '175,225p'; nl -ba utils/py/releases_app.py | sed -n '1130,1225p'; nl -ba utils/releases-merge-resolve.sh | sed -n '175,230p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej
 succeeded in 18ms:
   175	    if not os.path.lexists(path):
   176	        return "missing"
   177	    if os.path.islink(path):
   178	        return "link:" + os.readlink(path)
   179	    if os.path.isfile(path):
   180	        digest = hashlib.sha256()
   181	        with open(path, "rb") as f:
   182	            for chunk in iter(lambda: f.read(1024 * 1024), b""):
   183	                digest.update(chunk)
   184	        return "file:" + digest.hexdigest()
   185	    if os.path.isdir(path):
   186	        digest = hashlib.sha256()
   187	        for name in sorted(os.listdir(path)):
   188	            child = os.path.join(path, name)
   189	            digest.update(name.encode("utf-8", "surrogateescape"))
   190	            digest.update(b"\0")
   191	            digest.update(path_fingerprint(child).encode("utf-8", "surrogateescape"))
   192	            digest.update(b"\0")
   193	        return "dir:" + digest.hexdigest()
   194	    st = os.lstat(path)
   195	    return "other:%d:%d" % (st.st_mode, st.st_size)
   196	
   197	
   198	def snapshot_paths(root, paths):
   199	    return {p: path_fingerprint(os.path.join(root, p)) for p in paths}
   200	
   201	
   202	def driver_projection_paths(root):
   203	    paths = set(DRIVER_LEDGER)
   204	    paths.update(p for p in RELEASES_PROJECTIONS if os.path.lexists(os.path.join(root, p)))
   205	    if os.path.isfile(os.path.join(root, "utils", "roadmap-dashboard.sh")):
   206	        paths.add("ROADMAP-DASHBOARD.md")
   207	    return paths
   208	
   209	
   210	def core_paths(paths):
   211	    return [p for p in paths if not is_doc_path(p)]
   212	
   213	
   214	def is_doc_path(p):
   215	    """The lane's own paperwork never counts against the size bounds; every
   216	    other path — including operator-supplied .md — counts (finding 5)."""
   217	    return p == "CHANGELOG.md" or p.startswith("PROJECT/")
   218	
   219	
   220	def insertions(root, paths, expect_driver=frozenset()):
   221	    total = 0
   222	    numstat = git(root, "diff", "origin/development", "--numstat", check=False).stdout
   223	    tracked = {}
   224	    for line in numstat.splitlines():
   225	        parts = line.split("\t")
  1130	GEN_MARKER_RE = re.compile(r"^<!-- releases-app generation: (\d+) -->$")
  1131	
  1132	
  1133	def gen_marker(generation):
  1134	    return "<!-- releases-app generation: %d -->" % generation
  1135	
  1136	
  1137	# ── staged writes + crash injection ─────────────────────────────────────────────────────────────
  1138	
  1139	def _crash(boundary):
  1140	    if os.environ.get("RELEASES_APP_CRASH_AT", "") == boundary:
  1141	        sys.stdout.flush()
  1142	        sys.stderr.flush()
  1143	        os._exit(EXIT_CRASH_INJECTED)
  1144	
  1145	
  1146	def _stage_write(final_path, content):
  1147	    """Staged temp-name write; the caller renames (atomic) only once the DB commit is durable."""
  1148	    tmp = "%s.tmp-%s" % (final_path, new_txn_id()[:12])
  1149	    with open(tmp, "w", encoding="utf-8", newline="\n") as fh:
  1150	        fh.write(content)
  1151	        fh.flush()
  1152	        os.fsync(fh.fileno())
  1153	    return tmp
  1154	
  1155	
  1156	def _atomic_write(final_path, content):
  1157	    tmp = _stage_write(final_path, content)
  1158	    os.replace(tmp, final_path)
  1159	
  1160	
  1161	# ── the writer protocol (PRD Git story 2-3): journal -> txn -> stage -> rename -> clear ─────────
  1162	
  1163	def refresh_preview(root):
  1164	    """GH-106: after a successful write, refresh the baked viewer artifacts — but only the ones
  1165	    the repo has ADOPTED (the file already exists at root; presence is the opt-in signal, so
  1166	    fixtures and non-adopting repos are silent no-ops). Best-effort by design: the write is
  1167	    already durable with its receipt when this runs, so a refresh failure WARNS on stderr and
  1168	    never fails the operation. Success is silent (the exporter's stdout is captured).
  1169	
  1170	    GH-108 adds LEADERBOARD.html on the same terms — one template, two baked artifacts, both
  1171	    regenerated by the same hook so a ranking can never lag the ledger it ranks."""
  1172	    exporter = os.path.join(root, "utils", "timeline", "export_timeline.py")
  1173	    if not os.path.exists(exporter):
  1174	        return
  1175	    for name, flag in (("RELEASES-PREVIEW.html", "--preview"),
  1176	                       ("LEADERBOARD.html", "--leaderboard")):
  1177	        target = os.path.join(root, name)
  1178	        if not os.path.exists(target):
  1179	            continue
  1180	        try:
  1181	            r = subprocess.run([sys.executable, exporter, flag, target],
  1182	                               cwd=root, capture_output=True, text=True, timeout=60)
  1183	            if r.returncode != 0:
  1184	                print("warning: %s refresh failed (the write itself is committed): %s"
  1185	                      % (name, r.stderr.strip() or r.stdout.strip() or
  1186	                         "exit %d" % r.returncode), file=sys.stderr)
  1187	        except Exception as exc:  # never let a rendered artifact break a committed write
  1188	            print("warning: %s refresh failed (the write itself is committed): %s"
  1189	                  % (name, exc), file=sys.stderr)
  1190	    # LEADERBOARD.md rides the same adoption signal — generated, never hand-edited.
  1191	    board = os.path.join(root, "LEADERBOARD.md")
  1192	    script = os.path.join(root, "utils", "leaderboard.sh")
  1193	    if os.path.exists(board) and os.path.exists(script):
  1194	        try:
  1195	            r = subprocess.run(["bash", script], cwd=root, capture_output=True, text=True,
  1196	                               timeout=60)
  1197	            if r.returncode != 0:
  1198	                print("warning: LEADERBOARD.md refresh failed (the write itself is committed): %s"
  1199	                      % (r.stderr.strip() or "exit %d" % r.returncode), file=sys.stderr)
  1200	        except Exception as exc:
  1201	            print("warning: LEADERBOARD.md refresh failed (the write itself is committed): %s"
  1202	                  % exc, file=sys.stderr)
  1203	
  1204	
  1205	def perform_write(root, conn, op, target_gid, mutate):
  1206	    """Run one CLI transaction under the full multi-artifact protocol:
  1207	
  1208	      write intent journal (txn_id, NEXT generation, planned outputs)   [BEFORE the DB commit]
  1209	      -> BEGIN IMMEDIATE -> mutate -> stamp generation into settings -> COMMIT
  1210	      -> stage dump (+ generated view when one exists), each carrying that generation
  1211	      -> atomic renames -> clear journal.
  1212	
  1213	    `mutate(conn)` does the business writes; the op_receipt (before/after business-state digests)
  1214	    is appended HERE so no writer can forget it. Recovery per boundary is `check`'s job
  1215	    (recover_from_journal); RELEASES_APP_CRASH_AT lands on the five named boundaries. The caller
  1216	    must NOT hold the writer lock (this function takes it)."""
  1217	    paths = artifact_paths(root)
  1218	    lock = WriterLock(root)
  1219	    lock.acquire()
  1220	    try:
  1221	        if os.path.exists(lock.journal_path):
  1222	            refuse("journal-live",
  1223	                   "an intent journal from an interrupted write exists (%s); run `releases check` "
  1224	                   "to recover before writing again" % lock.journal_path)
  1225	
   175	if [ -n "$REGEN" ]; then
   176	  say "regenerating adopted views: $REGEN"
   177	  case " $REGEN " in
   178	    *" ROADMAP-DASHBOARD.md "*)
   179	      say "  -> roadmap-dashboard.sh"
   180	      if ! ROADMAP_DASHBOARD_ROOT="$ROOT" bash "$HERE/roadmap-dashboard.sh"; then
   181	        die "roadmap-dashboard.sh failed. The merge is left open on purpose — staging the
   182	  stale dashboard against a rebuilt ledger would commit exactly the divergence this
   183	  resolver exists to prevent."
   184	      fi
   185	      ;;
   186	  esac
   187	  case " $REGEN " in
   188	    *" RELEASES-PREVIEW.html "*)
   189	      say "  -> export_timeline.py --preview"
   190	      if ! python3 "$HERE/timeline/export_timeline.py" --db "$ROOT/releases.db" --preview "$ROOT/RELEASES-PREVIEW.html"; then
   191	        die "export_timeline.py --preview failed. The merge is left open on purpose; the stale
   192	  RELEASES-PREVIEW.html has not been staged."
   193	      fi
   194	      ;;
   195	  esac
   196	  case " $REGEN " in
   197	    *" LEADERBOARD.html "*)
   198	      say "  -> export_timeline.py --leaderboard"
   199	      if ! python3 "$HERE/timeline/export_timeline.py" --db "$ROOT/releases.db" --leaderboard "$ROOT/LEADERBOARD.html"; then
   200	        die "export_timeline.py --leaderboard failed. The merge is left open on purpose; the stale
   201	  LEADERBOARD.html has not been staged."
   202	      fi
   203	      ;;
   204	  esac
   205	  case " $REGEN " in
   206	    *" LEADERBOARD.md "*)
   207	      say "  -> leaderboard.sh"
   208	      if ! LEADERBOARD_DB="$ROOT/releases.db" LEADERBOARD_OUTPUT="$ROOT/LEADERBOARD.md" bash "$HERE/leaderboard.sh"; then
   209	        die "leaderboard.sh failed. The merge is left open on purpose; the stale LEADERBOARD.md
   210	  has not been staged."
   211	      fi
   212	      ;;
   213	  esac
   214	fi
   215	
   216	# ── 6. stage what the rebuild regenerated — the FIRST point at which anything is resolved ───────
   217	for f in $TOOK_SIDE; do
   218	  say "resolving $f in the index now that the rebuild verified clean"
   219	done
   220	# One `git add` for the whole handled set (codex consult: per-path adds could stage a subset
   221	# when a later add fails), gated on existence, then a postcondition: nothing we handled may
   222	# still be unmerged.
   223	ADD_PATHS=""
   224	for f in $DERIVED releases.sql $REGEN; do
   225	  [ -f "$ROOT/$f" ] && ADD_PATHS="${ADD_PATHS:+$ADD_PATHS }$f"
   226	done
   227	[ -n "$ADD_PATHS" ] && git -C "$ROOT" add -- $ADD_PATHS
   228	LEFT_UNMERGED="$(git -C "$ROOT" diff --name-only --diff-filter=U 2>/dev/null || true)"
   229	for f in $ADD_PATHS; do
   230	  if printf '%s\n' "$LEFT_UNMERGED" | grep -qx "$f"; then

exec
/bin/zsh -lc "rg -l --hidden --glob '"'!.git'"' 'LEADERBOARD\\.html|RELEASES-PREVIEW\\.html' . | sort; nl -ba utils/releases-merge-resolve.sh | sed -n '135,177p'; nl -ba utils/py/wave_reconcile.py | sed -n '700,815p'; nl -ba utils/py/jog_run.py | sed -n '260,300p'; nl -ba utils/timeline/export_timeline.py | sed -n '570,635p'; nl -ba utils/timeline/README.md | sed -n '1,42p'; nl -ba utils/README.md | sed -n '108,127p'; nl -ba skills/relay-xyz/SKILL.md | sed -n '165,195p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej
 succeeded in 70ms:
./CHANGELOG.md
./LEADERBOARD.html
./PARKED/2026-08-20-gh103-timeline-spike.md
./PROJECT/1-INBOX/GH-254-PREVIEW-DRAFT-SORT.md
./PROJECT/1-INBOX/GH-424-ROADMAP-STATUS-MARKER-WRITER.md
./PROJECT/1-INBOX/RADAR-REPORT-2026-08-28.md
./PROJECT/1-INBOX/RADAR-REPORT-2026-09-01.md
./PROJECT/1-INBOX/recon-leaderboard-removal.md
./PROJECT/2-WORKING/GH-75-RELEASES-ROADMAP-DASHBOARD.md
./PROJECT/3-COMPLETED/GH-108-GH-111-EXECUTION-TODO.md
./PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md
./PROJECT/3-COMPLETED/GH-153-RELEASES-SIDEBAR-ROLLUP.md
./PROJECT/3-COMPLETED/GH-197-VENDOR-TIER-SPLIT.md
./PROJECT/3-COMPLETED/GH-269-RELEASES-DB-SWITCHOVER.md
./PROJECT/3-COMPLETED/GH-272-MERGE-RESOLVE-VIEWS.md
./PROJECT/3-COMPLETED/GH-450-MODEL-CATALOG-CONSUME.md
./RELEASES-PREVIEW.html
./TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log
./relay-system/2026-08-20/gh103-branch-qa.md
./relay-system/2026-08-21/gh124-merge-seq-173029/gh124-merge-seq.codex.md
./relay-system/2026-08-22/gh165-post-merge-reconcile-plan-qa.md
./relay-system/2026-08-23/salvage-location-214521/salvage-location.codex.md
./relay-system/2026-08-25/canary-root-euid-203501/canary-root-euid.codex.md
./relay-system/2026-08-28/gh280-phase4-dogfood/gh105/gh280-dogfood-run2.log
./relay-system/2026-08-28/gh280-phase4-dogfood/gh107-orphan-backup/20260828T022003Z-80043/scratch/test_export/RELEASES.html
./relay-system/2026-08-28/gh280-phase4-dogfood/gh107-orphan-backup/20260828T022003Z-80043/scratch/test_export/index.html
./relay-system/2026-08-28/gh280-phase4-dogfood/gh107/gh280-dogfood-retry1.log
./relay-system/2026-08-28/gh280-phase4-dogfood/gh107/gh280-dogfood-run1.log
./relay-system/2026-08-29/gh222-executor-dogfood/gh222-retry-build2.log
./relay-system/2026-08-29/gh222-executor-dogfood/gh222-retry-build3.log
./relay-system/2026-09-02/gh123-cancel-linux-rc-qa.md
./relay-system/2026-09-07/gh483-html-removal-115703/gh483-html-removal.PROMPT.txt
./releases.sql
./skills/relay-xyz/SKILL.md
./test/gh103-timeline-exporter.sh
./test/gh153-releases-sidebar-rollup.sh
./test/gh267-express-skill.sh
./test/gh57-live-merge-resolve.sh
./utils/README.md
./utils/py/express.py
./utils/py/jog_run.py
./utils/py/releases_app.py
./utils/py/wave_reconcile.py
./utils/releases-merge-resolve.sh
./utils/timeline/README.md
./utils/timeline/RELEASES.html
./utils/timeline/export_timeline.py
   135	  fi
   136	done
   137	
   138	# ── 3. rebuild the DB from the merged dump ──────────────────────────────────────────────────────
   139	say "rebuilding releases.db from the merged releases.sql"
   140	if ! python3 "$APP" --root "$ROOT" check --rebuild; then
   141	  die "check --rebuild failed. The merge is left open on purpose — nothing was staged over it.
   142	  Read the error above: a UNIQUE constraint failure usually means the merged dump contains the same
   143	  row twice (both sides edited one release), which is a real content conflict a union cannot settle."
   144	fi
   145	
   146	# ── 4. the rebuilt state must actually be clean ─────────────────────────────────────────────────
   147	say "verifying"
   148	if ! python3 "$APP" --root "$ROOT" check; then
   149	  die "the rebuilt artifacts still do not check clean. Not staging them. The displaced DB is at
   150	  releases.db.bak if you need to compare."
   151	fi
   152	
   153	# ── 5. regenerate the adopted derived views (GH-272) ───────────────────────────────────────────
   154	# Adoption is opt-in by presence, mirroring refresh_preview in releases_app.py: a repo that
   155	# never baked a view (a fixture, a fresh install) is a silent no-op. A view that exists is
   156	# stale the moment the dump merged — regenerate it from the rebuilt ledger, and if the
   157	# generator fails, refuse and leave the merge open rather than warn-and-continue: the
   158	# write path can afford best-effort refreshes, a merge resolver cannot (a stale view is
   159	# exactly the hand-regen tax this step exists to end).
   160	VIEWS="ROADMAP-DASHBOARD.md RELEASES-PREVIEW.html LEADERBOARD.html LEADERBOARD.md"
   161	REGEN=""
   162	for f in $VIEWS; do
   163	  if printf '%s\n' "$UNMERGED" | grep -qx "$f"; then
   164	    # --ours is arbitrary and that is the point: both sides are stale the moment the dump
   165	    # merged. The working-tree copy is replaced because the generators write in place; the
   166	    # index stays unmerged until the regen below has succeeded, same discipline as releases.db.
   167	    git -C "$ROOT" checkout --ours -- "$f" 2>/dev/null || true
   168	    say "took either side of $f in the working tree (it is regenerated below, so the choice cannot matter)"
   169	    REGEN="${REGEN:+$REGEN }$f"
   170	  elif [ -f "$ROOT/$f" ]; then
   171	    REGEN="${REGEN:+$REGEN }$f"
   172	  fi
   173	done
   174	
   175	if [ -n "$REGEN" ]; then
   176	  say "regenerating adopted views: $REGEN"
   177	  case " $REGEN " in
   700	            "marathon-plan found drift/held state attributable to the reconciled "
   701	            f"PR item(s): {labels}",
   702	            code=6,
   703	        )
   704	
   705	    log("  WARNING — marathon-plan found pre-existing unrelated drift/held items; keeping reconciliation:")
   706	    for finding in unrelated:
   707	        log(f"    - {describe_finding(finding)}")
   708	
   709	
   710	def run_subprocesses(repo_root, dry_run=False, journal=None, reconciled_issues=None):
   711	    """Orchestrate releases sync, view exports, and marathon replanning with DB rollback protection."""
   712	    log("Running downstream database sync and dashboard regeneration...")
   713	
   714	    # Snapshot DB files in journal for transactional integrity
   715	    db_file = os.path.join(repo_root, "releases.db")
   716	    sql_file = os.path.join(repo_root, "releases.sql")
   717	    pre_views = set()
   718	    if not dry_run and journal:
   719	        journal.snapshot(db_file)
   720	        journal.snapshot(sql_file)
   721	        # GH-271: the regen steps below also rewrite the baked views and marathon-plan drops
   722	        # a dated plan doc — none of which the journal previously knew about, which is how a
   723	        # failed run's rollback left regenerated dashboards and a stray MARATHON-PLAN behind
   724	        # while reporting success (2026-08-23). Snapshot existing views (new ones are tracked
   725	        # as created post-run); plan docs are always new files, so a before/after glob covers
   726	        # them.
   727	        for view in (
   728	            "ROADMAP-DASHBOARD.md",
   729	            "RELEASES-PREVIEW.html",
   730	            "LEADERBOARD.html",
   731	            "LEADERBOARD.md",
   732	        ):
   733	            view_path = os.path.join(repo_root, view)
   734	            if os.path.exists(view_path):
   735	                journal.snapshot(view_path)
   736	                pre_views.add(view_path)
   737	
   738	    def _plan_docs():
   739	        found = set()
   740	        for pattern in ("MARATHON-PLAN-*.md", os.path.join("PROJECT", "2-WORKING", "MARATHON-PLAN-*.md")):
   741	            found.update(glob.glob(os.path.join(repo_root, pattern)))
   742	        return found
   743	
   744	    pre_plan_docs = _plan_docs() if not dry_run else set()
   745	    if journal and not dry_run:
   746	        # Codex consult: a same-dated plan doc that already exists gets OVERWRITTEN by the
   747	        # replan, and tracking-only-created would leave rollback no bytes to restore.
   748	        for existing_doc in pre_plan_docs:
   749	            journal.snapshot(existing_doc)
   750	
   751	    # GH-358: resolve each harness tool against the repo first, then the harness home. On a
   752	    # vendored install these five live only under <repo>/.xyz/ and every one was unreachable,
   753	    # so the reconciler died on its first downstream step.
   754	    releases_app = harness_tool(repo_root, "utils/py/releases_app.py")
   755	    sync_cmd = ["python3", releases_app, "roadmap", "sync"]
   756	    check_cmd = ["python3", releases_app, "check"]
   757	    timeline_cmd = ["python3", harness_tool(repo_root, "utils/timeline/export_timeline.py"), "--preview"]
   758	    dash_cmd = ["bash", harness_tool(repo_root, "utils/roadmap-dashboard.sh")]
   759	    plan_cmd = ["bash", harness_tool(repo_root, "utils/marathon-plan.sh"), "--format", "json"]
   760	
   761	    if dry_run:
   762	        sync_cmd.append("--dry-run")
   763	        plan_cmd.append("--dry-run")
   764	
   765	    steps = [
   766	        ("releases roadmap sync", sync_cmd),
   767	        ("releases check", check_cmd),
   768	    ]
   769	    if not dry_run:
   770	        steps.extend(
   771	            [
   772	                ("export_timeline.py --preview", timeline_cmd),
   773	                ("roadmap-dashboard.sh", dash_cmd),
   774	                ("marathon-plan.sh", plan_cmd),
   775	            ]
   776	        )
   777	    else:
   778	        steps.append(("marathon-plan.sh --dry-run", plan_cmd))
   779	
   780	    # GH-271: registration of created views/plan docs must happen even when a step DIES —
   781	    # the marathon-plan failure path raises from inside the loop, and a post-loop pass
   782	    # would never run, which is exactly how the stray MARATHON-PLAN escaped rollback.
   783	    try:
   784	        for name, cmd in steps:
   785	            log(f"  -> {name}")
   786	            # GH-429: roadmap-dashboard.sh derives ROOT from its own location and lands on <repo>/.xyz
   787	            # when vendored (#215 item 2); it honours this override, and the reconciler already knows
   788	            # the repo root. Harmless for the other steps, which ignore the variable.
   789	            step_env = dict(os.environ, ROADMAP_DASHBOARD_ROOT=str(repo_root))
   790	            r = subprocess.run(cmd, cwd=repo_root, capture_output=True, text=True, check=False, env=step_env)
   791	            if name.startswith("marathon-plan"):
   792	                handle_marathon_plan_result(r, reconciled_issues or set())
   793	            elif r.returncode != 0:
   794	                die(f"Subprocess '{name}' failed with exit {r.returncode}:\n{r.stderr}\n{r.stdout}", code=6)
   795	    finally:
   796	        if journal and not dry_run:
   797	            for view in (
   798	                "ROADMAP-DASHBOARD.md",
   799	                "RELEASES-PREVIEW.html",
   800	                "LEADERBOARD.html",
   801	                "LEADERBOARD.md",
   802	            ):
   803	                view_path = os.path.join(repo_root, view)
   804	                if os.path.exists(view_path) and view_path not in pre_views:
   805	                    journal.track_created(view_path)
   806	            for plan_doc in _plan_docs() - pre_plan_docs:
   807	                journal.track_created(plan_doc)
   808	
   809	
   810	def run_validation_gate(repo_root):
   811	    """Run pdda doc-health verification gate."""
   812	    log("Running PDDA doc-hygiene gate...")
   813	    gate_cmd = ["bash", "utils/pdda-local-checks.sh"] if os.path.exists(os.path.join(repo_root, "utils", "pdda-local-checks.sh")) else ["bash", "utils/pdda/pdda.sh"]
   814	    r = subprocess.run(
   815	        gate_cmd,
   260	
   261	
   262	def jog_commit_supervisor_state(root, gh_num, exec_id):
   263	    """GH-292 F1: commit the supervisor's own ledger/doc writes before dispatch.
   264	
   265	    The turn-containment pass restores tracked working-tree modifications to HEAD, and jog's
   266	    uncommitted writes (releases.db/sql, regenerated views, the promoted doc pair) are
   267	    indistinguishable from an agent's off-lane edits — the Phase-4 dogfood lost queue rows to
   268	    exactly this, twice. Committing supervisor-owned paths BEFORE any turn dispatches makes
   269	    containment have nothing of the supervisor's to revert.
   270	
   271	    Stages an explicit path list only — never `git add -A` (the GH-124 sweep lesson). The
   272	    promotion's own `git rm`/`git add` of the doc pair is already staged by promotion.
   273	    Commits only on the integration branch: a retry-build dispatches from a lane branch,
   274	    and a ledger commit there would ride into the lane PR and block later branch switches.
   275	    Returns True when a commit was made."""
   276	    integration = os.environ.get("MARATHON_INTEGRATION_BRANCH", "development")
   277	    current = subprocess.run(["git", "-C", root, "symbolic-ref", "--quiet", "--short", "HEAD"],
   278	                             capture_output=True, text=True)
   279	    if current.returncode == 0 and current.stdout.strip() != integration:
   280	        print(f"jog: supervisor-state commit skipped — on branch '{current.stdout.strip()}' "
   281	              f"(not the integration branch '{integration}'); uncommitted ledger writes on a "
   282	              f"lane are the containment-revert tradeoff (GH-292 F1)")
   283	        return False
   284	    paths = [p for p in ("releases.db", "releases.sql", "releases.gen",
   285	                         "ROADMAP-DASHBOARD.md", "LEADERBOARD.html", "RELEASES-PREVIEW.html")
   286	             if os.path.exists(os.path.join(root, p))]
   287	    if paths:
   288	        subprocess.run(["git", "-C", root, "add", "--"] + paths, capture_output=True)
   289	    staged = subprocess.run(["git", "-C", root, "diff", "--cached", "--quiet"],
   290	                            capture_output=True)
   291	    if staged.returncode == 0:
   292	        return False
   293	    res = subprocess.run(
   294	        ["git", "-C", root, "commit", "-q", "-m",
   295	         f"jog-state: intake + lease for GH-{gh_num} (execution {exec_id}) — supervisor-owned "
   296	         f"ledger, doc, and view writes committed before dispatch (GH-292 F1)"],
   297	        capture_output=True, text=True)
   298	    if res.returncode != 0:
   299	        print(f"jog: warning: supervisor-state commit failed: {(res.stderr or '').strip()}",
   300	              file=sys.stderr)
   570	            self.send_header("Cache-Control", "no-store")
   571	            self.send_header("Content-Length", str(len(body)))
   572	            self.end_headers()
   573	            self.wfile.write(body)
   574	
   575	    with http.server.ThreadingHTTPServer(("127.0.0.1", port), Handler) as srv:
   576	        print(f"live on http://127.0.0.1:{port}/RELEASES.html — every refresh re-queries {db_path}")
   577	        srv.serve_forever()
   578	
   579	
   580	def bake_static(template_html, payload):
   581	    marker = "<!--LEDGER_DATA-->"
   582	    if marker not in template_html:
   583	        sys.exit("template is missing the <!--LEDGER_DATA--> placeholder")
   584	    blob = json.dumps(payload, ensure_ascii=False).replace("</", "<\\/")
   585	    return template_html.replace(
   586	        marker, f'<script id="ledger-data" type="application/json">{blob}</script>'
   587	    )
   588	
   589	
   590	def main(argv=None):
   591	    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
   592	    ap.add_argument("--db", default="releases.db", type=Path)
   593	    ap.add_argument("--md", type=Path, help="RELEASES.md for drift check (default: next to --db)")
   594	    ap.add_argument("--template", default=HERE / "RELEASES.html", type=Path)
   595	    ap.add_argument("--out", default=Path("temp/timeline"), type=Path)
   596	    ap.add_argument("--json", action="store_true",
   597	                    help="print the payload (same single-object shape as data.json) to stdout; "
   598	                         "no files written — the input the leaderboard and /radar consume")
   599	    ap.add_argument("--check-drift", action="store_true",
   600	                    help="no files written: exit 1 listing RELEASES.md-vs-DB drift, exit 0 when aligned")
   601	    ap.add_argument("--serve", type=int, metavar="PORT", default=None,
   602	                    help="serve live: /data.json re-queries the DB on every request (no files written)")
   603	    ap.add_argument("--preview", nargs="?", const=Path("RELEASES-PREVIEW.html"), default=None,
   604	                    type=Path, metavar="PATH",
   605	                    help="bake current DB state into one self-contained HTML (default: ./RELEASES-PREVIEW.html)")
   606	    ap.add_argument("--leaderboard", nargs="?", const=Path("LEADERBOARD.html"), default=None,
   607	                    type=Path, metavar="PATH",
   608	                    help="bake the ranked view from the SAME template (default: ./LEADERBOARD.html)")
   609	    args = ap.parse_args(argv)
   610	
   611	    if not args.db.is_file():
   612	        sys.exit(f"releases DB not found: {args.db}")
   613	    md_path = args.md if args.md else args.db.resolve().parent / "RELEASES.md"
   614	
   615	    if args.serve:
   616	        serve(args.db.resolve(), md_path, args.template.resolve().parent, args.serve)
   617	        return
   618	    cx = sqlite3.connect(f"{args.db.resolve().as_uri()}?mode=ro", uri=True)
   619	    try:
   620	        payload = build_payload(cx, date.today(), md_path)
   621	    finally:
   622	        cx.close()
   623	
   624	    if args.json:
   625	        print(json.dumps(payload, ensure_ascii=False))
   626	        return
   627	
   628	    if args.check_drift:
   629	        sync = payload.get("sync")
   630	        if sync:
   631	            print(f"DRIFT ({sync['rowsDiffer']}): {sync['message']}")
   632	            sys.exit(1)
   633	        print("releases.db and RELEASES.md agree (releases present on both sides, shipped-status aligned)")
   634	        return
   635	
     1	# utils/timeline — RELEASES ledger → timeline viewer (GH-103 spike)
     2	
     3	Read-only projection of `releases.db` onto the timeline-ui rail (release nodes on a
     4	horizontal trunk, manifest cards in lanes). See
     5	`PROJECT/1-INBOX/GH-103-TIMELINE-LEDGER-SPIKE.md`; overlaps queued #75
     6	(`releases dashboard` verb).
     7	
     8	## Usage
     9	
    10	From the repo root:
    11	
    12	```bash
    13	python3 utils/timeline/export_timeline.py --preview     # bake ./RELEASES-PREVIEW.html (one file, opens from disk)
    14	python3 utils/timeline/export_timeline.py --serve 8103  # live: http://127.0.0.1:8103/RELEASES.html
    15	python3 utils/timeline/export_timeline.py               # full export → temp/timeline/
    16	python3 utils/timeline/export_timeline.py --check-drift # exit 1 if RELEASES.md and the DB disagree
    17	```
    18	
    19	- `--preview [PATH]` — the on-demand snapshot: current DB state baked into one
    20	  self-contained `RELEASES-PREVIEW.html` (default: repo root). Generated artifact —
    21	  regenerate rather than edit.
    22	- `--serve PORT` — live mode: `/data.json` re-queries the DB (read-only) on every
    23	  request; no stale file in the path. The browser cannot read SQLite directly; this
    24	  is the one-source equivalent.
    25	- Full export writes `temp/timeline/`: `data.json` (the viewer's data contract),
    26	  `index.html` (baked, opens from `file://`), and `RELEASES.html` (the fetch-mode
    27	  template copy).
    28	- `--db`, `--md`, `--template`, `--out` override the defaults.
    29	
    30	## Navigation sidebar (GH-153 spike)
    31	
    32	The template ships a left sidebar in both baked views: default ON, hamburger
    33	(`#sidenav-toggle`) slides it out, the chevron (`#sn-min`) collapses it to an icon rail,
    34	state persists via `localStorage('ledger-sidenav')`. The project switcher and the
    35	"releases cycle" panel are filled from the payload's additive `projects`/`cycle` keys —
    36	the cycle numbers come from `utils/py/releases_cycle.py`, the same module
    37	`utils/hq/rollup.sh` embeds, so the dashboard and the Obsidian daily rollup cannot
    38	disagree. Items with no destination yet are deliberate non-link placeholders (`.sn-ph`).
    39	
    40	## Guarantees & limits
    41	
    42	- Opens the DB with SQLite's read-only URI (`mode=ro`): no writer lock, no generation
   108	}
   109	```
   110	
   111	---
   112	
   113	## 2. Subsystem Directory Index
   114	
   115	| Subdirectory | Description |
   116	|---|---|
   117	| [`utils/py/`](py/) | **Authoritative Python Twin Runtimes:** Authoritative implementations for Tier-A entry points (`marathon_drive.py`, `relay_drive.py`, `agy-turn.py`, `consult.py`, `releases_app.py`, `review_xyz.py`, `workspace_manager.py`, `script_runner.py`, `gate_receipt.py`). |
   118	| [`utils/hq/`](hq/) | **Multi-Repo Command Center:** CLI (`hq.sh`) driving multi-repo resolution, PDDA cross-repo task landing, and `/hq` skill execution. |
   119	| [`utils/pdda/`](pdda/) | **PDDA Governance & Hygiene:** Doc lifecycle validation (`pdda.sh`), link checks, roadmap-to-working sync, and doc invariant enforcement (`pdda-local-checks.sh`). |
   120	| [`utils/timeline/`](timeline/) | **Interactive Ledger Viewer:** Exporter (`export_timeline.py`) projecting SQLite `releases.db` into liquid HTML timeline views (`RELEASES.html`, `RELEASES-PREVIEW.html`). |
   121	| [`utils/telemetry/`](telemetry/) | **Telemetry & Receipts:** Telemetry collector adapters, cost summary collectors, and test evidence recorders. |
   122	| [`utils/swe-diagram/`](swe-diagram/) | **SWE Architecture Diagrams:** Automated diagram generator mapping repository workflows and kernel states. |
   123	| [`utils/vndr/`](vndr/) | **Vendored Assets & Tools:** Vendoring tools and third-party scripts. |
   124	
   125	---
   126	
   127	## 3. Core Script Index
   165	keeps the event stream readable even across clones: distinct `--phase-id` / `--relay-task`, plus
   166	`MARATHON_LANE_NS` for the lane namespace and an explicit `XYZ_SESSION_ID` (its fallback to `PHASE_ID`
   167	cannot tell one run from another).
   168	
   169	To run relays in **different repos at the same time on one machine**, give each repo its **own harness**
   170	so each gets its own lock, `.tick/`, and worktrees:
   171	
   172	| Install path / Tier | Ships | Relay capability | Releases ledger? | Lock |
   173	|---|---|---|---|---|
   174	| `install.sh` (tick-only) | `bin/tick` + `src/*.js` | ❌ falls back to the centralized harness | ❌ no | shared (serializes) |
   175	| **Tier 1 (default)**: `xyz-vendor.sh <target-repo> [--no-register]` | full core harness (`relay-automation/` minus `xyz-releases-onboard.sh`, `bin/`, `src/`, `test/`, `skills/`, `utils/` minus overlay) into gitignored `.xyz/` | ✅ per-repo | ❌ no overlay | **own** `.xyz/.relay-driver.lock` |
   176	| **Tier 2 (opt-in)**: `xyz-vendor.sh <target-repo> --with-releases` (or auto-detected via `releases.db` at root) | full core harness + RELEASES overlay (`releases_app.py`, `releases_cycle.py`, `releases-merge-resolve.sh`, `release-lanes.sh`, `utils/timeline/`, `xyz-releases-onboard.sh`, `RELEASES-DB-FAQS.md`) | ✅ per-repo | ✅ opt-in overlay | **own** `.xyz/.relay-driver.lock` |
   177	
   178	Updating a vendored copy (`xyz-sync.sh update`, or re-running `xyz-vendor.sh` over an existing
   179	`.xyz/`) replaces the harness **code** and preserves the per-repo state above — `relay-system/`,
   180	`.tick/`, `.relay-driver.lock`, and the `XYZ.json*` telemetry ride across the rebuild (GH-312).
   181	Note that RELEASES ledger runtime state (`releases.db`, `releases.sql`, `RELEASES.md`,
   182	`RELEASES-PREVIEW.html`) lives at the target repository root, outside `.xyz/`, while `.xyz/`-resident
   183	runtime state is preserved across swaps. This matters because `.xyz/` is gitignored: state lost there
   184	is unrecoverable, with no reflog or stash behind it. A new runtime artifact under `.xyz/` must be added
   185	to the preserve list in `xyz-vendor.sh`'s `materialize_vendor()`, or the next update will delete it.
   186	
   187	So: **`xyz-vendor.sh` (not `install.sh`) is the path to concurrent per-repo relays.** Once a repo has
   188	`.xyz/`, `find-harness.sh` prefers it automatically (env → `.xyz/` → current repo → script-relative), and
   189	`find-harness.sh --check` **warns** when you're in a foreign repo with no `.xyz/` (using the shared
   190	harness) and points you at the vendor command. Two vendored repos each run `relay-drive.sh` from their
   191	own `.xyz/relay-automation/`, holding independent locks — no contention. (Editing the central harness
   192	clone also can't disturb a vendored run, since it uses its own pinned `.xyz/` copy.)
   193	
   194	## Per-repo persistence (don't cache a path)
   195	

exec
/bin/zsh -lc "nl -ba utils/timeline/export_timeline.py | sed -n '635,690p'; nl -ba test/gh103-timeline-exporter.sh | sed -n '1,260p'; nl -ba test/gh153-releases-sidebar-rollup.sh | sed -n '1,240p'; nl -ba test/gh267-express-skill.sh | sed -n '1,280p'; nl -ba test/gh57-live-merge-resolve.sh | sed -n '1,320p'; nl -ba PROJECT/1-INBOX/recon-leaderboard-removal.md | sed -n '1,260p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej
 succeeded in 0ms:
   635	
   636	    if args.leaderboard:
   637	        # ONE template, TWO baked artifacts. The only difference is the payload's `view` field —
   638	        # no second copy of the design system, no second baker, one data contract, and both
   639	        # files stay standalone and openable from a plain git checkout with no server.
   640	        args.leaderboard.write_text(
   641	            bake_static(args.template.read_text(), dict(payload, view="leaderboard")))
   642	        print(f"wrote {args.leaderboard} "
   643	              f"({len(payload['ratedTasks'])} rated task(s), self-contained)")
   644	        return
   645	
   646	    if args.preview:
   647	        args.preview.write_text(bake_static(args.template.read_text(), payload))
   648	        print(f"wrote {args.preview} ({payload['telemetry']['releasesTotal']} releases, "
   649	              f"self-contained, read-only snapshot of {args.db})")
   650	        return
   651	
   652	    args.out.mkdir(parents=True, exist_ok=True)
   653	    (args.out / "data.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
   654	    template = args.template.read_text()
   655	    (args.out / "index.html").write_text(bake_static(template, payload))
   656	    shutil.copyfile(args.template, args.out / "RELEASES.html")
   657	    print(
   658	        f"wrote {args.out}/data.json + index.html "
   659	        f"({payload['telemetry']['releasesTotal']} releases, "
   660	        f"{sum(r['itemsTotal'] for r in payload['releases'])} manifest cards, read-only)"
   661	    )
   662	
   663	
   664	if __name__ == "__main__":
   665	    main()
     1	#!/usr/bin/env bash
     2	# gh103-timeline-exporter.sh — utils/timeline/export_timeline.py, the READ-ONLY projection of
     3	# releases.db onto the timeline viewer.
     4	#
     5	# The exporter had no suite before this one, which is how #109 survived: it asserted a marathon
     6	# membership the data never claimed ("release has a marathon => every manifest item is one of its
     7	# work units"), and that stayed latent until a non-marathon item joined a marathon release.
     8	#
     9	# What is pinned here:
    10	#   * GH-109 — marathon grouping follows manifest_items.marathon_id and NOTHING else; a
    11	#     non-member on a marathon release renders as a sibling, outside the box.
    12	#   * GH-110 — a shipped member renders the done marker (the branch that existed for years and
    13	#     never received a row, because no code path wrote that state).
    14	#   * GH-111 — itemsTotal counts COMMITTED work (dialed_in + shipped); cut rows still render but
    15	#     stop inflating the total. Baseline and growth are emitted, and a baseline-less release
    16	#     emits null rather than a zero.
    17	#   * GH-108 — rated tasks carry metrics + effectiveScore, the override wins over calc, an
    18	#     unrated card carries no metrics key at all, sev >= 80 flags hot, and a rated DETOUR is
    19	#     scored too (detours reparse the markdown, so they need the index handed to them).
    20	#   * The page is a PURE CONSUMER: the exporter opens the DB read-only and writes no DB bytes.
    21	set -uo pipefail
    22	
    23	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    24	APP="$HERE/../utils/py/releases_app.py"
    25	EXPORTER="$HERE/../utils/timeline/export_timeline.py"
    26	TEMPLATE="$HERE/../utils/timeline/RELEASES.html"
    27	
    28	pass=0; fail=0
    29	ok(){ if [ "$2" = "0" ]; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
    30	is(){ [ "$1" = "$2" ]; }
    31	# Fixed-string containment, done in-process.
    32	#
    33	# This was `printf '%s' "$1" | grep -Fq -- "$2"`, which is unsound under the `set -o pipefail` above:
    34	# `grep -q` exits the moment it matches, closing the pipe while `printf` is still writing, so printf
    35	# dies of SIGPIPE and pipefail reports the pipeline as 141 — i.e. "not found" — even though the
    36	# string IS present. Whether it fires depends on how early the match sits in the input and on
    37	# scheduling, so it read as a flaky, template-size-dependent false negative rather than a bug.
    38	# Bash pattern matching needs no pipe and cannot race.
    39	has(){ case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac; }
    40	file_hash() { # portable: sha256sum -> shasum -a 256 -> md5 (GH-65)
    41	  local f="$1"
    42	  if command -v sha256sum >/dev/null 2>&1; then
    43	    sha256sum "$f" | awk '{print $1}'
    44	  elif command -v shasum >/dev/null 2>&1; then
    45	    shasum -a 256 "$f" | awk '{print $1}'
    46	  else
    47	    md5 -q "$f"
    48	  fi
    49	}
    50	
    51	echo "== test: gh103-timeline-exporter =="
    52	command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
    53	command -v sqlite3 >/dev/null 2>&1 || { echo "sqlite3 required" >&2; exit 1; }
    54	
    55	WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh103-timeline.XXXXXX")"
    56	[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "mktemp failed" >&2; exit 1; }
    57	. "$HERE/lib/fixture-guard.sh"
    58	fixture_guard_init "$WORK"
    59	cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
    60	trap cleanup EXIT
    61	
    62	R="$WORK/repo"
    63	case "$R" in "$WORK"/*) ;; *) echo "REFUSING: $R outside WORK" >&2; exit 2 ;; esac
    64	mkdir -p "$R"
    65	git -C "$R" init -q -b main
    66	git -C "$R" config user.email t@t
    67	git -C "$R" config user.name t
    68	ra(){ require_fixture "$R" "timeline fixture"; python3 "$APP" --root "$R" "$@"; }
    69	rq(){ ra "$@" >/dev/null 2>&1; }
    70	GH="https://github.com/HiQS-Labs/XYZ-forge/issues"
    71	
    72	rq init --slug gh103
    73	
    74	# ── the fixture ledger ──────────────────────────────────────────────────────────────────────────
    75	# One ACTIVE release with a marathon, carrying: two marathon members, one NON-member, one cut
    76	# item, and one shipped member. Plus a second release with no marathon at all.
    77	rq marathon add --tracking-issue "$GH/700"
    78	MAR="$(sqlite3 "$R/releases.db" "SELECT global_id FROM marathons LIMIT 1")"
    79	rq add --version 1.0.0 --codename Fixture --status draft --description "The marathon release." \
    80	   --marathon "$MAR" --tracking-issue "$GH/1"
    81	REL="$(sqlite3 "$R/releases.db" "SELECT global_id FROM releases WHERE version='1.0.0'")"
    82	for N in 801 802 803 804 805; do
    83	  rq manifest dial-in --gid "$REL" "$GH/$N" --reason "fixture"
    84	done
    85	rq manifest marathon --gid "$REL" "$GH/801" --marathon "$MAR"
    86	rq manifest marathon --gid "$REL" "$GH/802" --marathon "$MAR"
    87	rq update --gid "$REL" --status active           # baseline auto-captures here: 5 committed
    88	rq manifest ship --gid "$REL" "$GH/803" --evidence "landed in abc1234"
    89	rq manifest cut --gid "$REL" "$GH/804" --reason "descoped"
    90	
    91	cat > "$R/ROADMAP.md" <<'MD'
    92	# Fixture roadmap
    93	## Ledger
    94	### In progress
    95	- **GH-801 · marathon phase one** 🚧 — body. rated 90/85/70/60 → [#801](https://github.com/HiQS-Labs/XYZ-forge/issues/801)
    96	- **GH-805 · a non-member with an override** 🚧 — body. rated 10/10/10/10 ovr 399 → [#805](https://github.com/HiQS-Labs/XYZ-forge/issues/805)
    97	- **GH-900 · a rated detour, on no manifest** 🚧 — body. rated 50/50/50/50 → [#900](https://github.com/HiQS-Labs/XYZ-forge/issues/900)
    98	### Queue / parked intake
    99	- **GH-802 · marathon phase two, unrated** — body.
   100	MD
   101	printf 'Release: 1.0.0\nStatus: Active\nCodename: Fixture\n' > "$R/RELEASES.md"
   102	rq roadmap sync
   103	
   104	JSON="$WORK/payload.json"
   105	python3 "$EXPORTER" --db "$R/releases.db" --json > "$JSON" 2>"$WORK/err.txt"
   106	ok "--json emits the payload to stdout and writes no files" "$([ -s "$JSON" ] && [ ! -d "$R/temp" ]; echo $?)"
   107	
   108	q(){ python3 - "$JSON" "$1" <<'PY'
   109	import json, sys
   110	payload = json.load(open(sys.argv[1]))
   111	rel = next(r for r in payload["releases"] if r["version"] == "1.0.0")
   112	groups = [i for i in rel["roadmap"] if i.get("type") == "marathon"]
   113	sibs = [i for i in rel["roadmap"] if i.get("type") != "marathon"]
   114	members = groups[0]["cards"] if groups else []
   115	cards = {c["id"]: c for c in members + sibs + rel["detours"]}
   116	env = {"rel": rel, "groups": groups, "sibs": sibs, "members": members, "cards": cards,
   117	       "payload": payload}
   118	print(eval(sys.argv[2], {"__builtins__": {"len": len, "sorted": sorted, "sum": sum,
   119	                                          "str": str, "any": any, "all": all}}, env))
   120	PY
   121	}
   122	
   123	# ── GH-109: marathon membership is a fact the row carries ───────────────────────────────────────
   124	echo "-- GH-109: the marathon box contains members, and only members"
   125	ok "the release renders exactly ONE marathon group" "$(is "$(q 'len(groups)')" "1"; echo $?)"
   126	ok "the group holds only the two LINKED items — not every card on the release" \
   127	   "$(is "$(q '[c["id"] for c in members]')" "['GH-801', 'GH-802']"; echo $?)"
   128	ok "the non-member renders as a SIBLING beside the box (the #109 defect, inverted)" \
   129	   "$(is "$(q 'any(c["id"] == "GH-805" for c in sibs)')" "True"; echo $?)"
   130	ok "the cut item is a sibling too, and still rendered rather than dropped" \
   131	   "$(is "$(q 'any(c["id"] == "GH-804" and c["sectionLabel"] == "cut" for c in sibs)')" "True"; echo $?)"
   132	
   133	# ── GH-110: shipped members finally have a row to render ────────────────────────────────────────
   134	echo "-- GH-110: a shipped member renders the done marker"
   135	ok "the shipped item carries marker=done and section=done" \
   136	   "$(is "$(q 'cards["GH-803"]["marker"] + "/" + cards["GH-803"]["section"]')" "done/done"; echo $?)"
   137	
   138	# ── GH-111: the denominator means COMMITTED work ────────────────────────────────────────────────
   139	echo "-- GH-111: denominator, baseline, growth"
   140	ok "itemsTotal counts dialed_in + shipped and EXCLUDES the cut row (4, not 5)" \
   141	   "$(is "$(q 'rel["itemsTotal"]')" "4"; echo $?)"
   142	ok "the baseline captured at activation is emitted with its provenance" \
   143	   "$(is "$(q 'str(rel["baseline"]["count"]) + "/" + rel["baseline"]["source"]')" "5/observed"; echo $?)"
   144	ok "growth is NEGATIVE when more was cut than added — a real, meaningful number, not an error" \
   145	   "$(is "$(q 'rel["baseline"]["growth"]')" "-1"; echo $?)"
   146	ok "a release with no baseline emits null, never a placeholder zero" \
   147	   "$(is "$(q 'any(r["baseline"] is None for r in payload["releases"] if r["version"] != "1.0.0") or len(payload["releases"]) == 1')" "True"; echo $?)"
   148	
   149	# ── GH-108: ratings reach the cards ─────────────────────────────────────────────────────────────
   150	echo "-- GH-108: metrics, effectiveScore, override precedence, hot flag"
   151	ok "a rated card carries all four axes under their PUBLIC names (no rating_ prefix leaks)" \
   152	   "$(is "$(q 'sorted(k for k in cards["GH-801"]["metrics"] if k not in ("calc", "effectiveScore"))')" "['appeal', 'effort', 'pri', 'sev']"; echo $?)"
   153	ok "calc is the equal-weighted SUM of the four axes (90+85+70+60 = 305)" \
   154	   "$(is "$(q 'cards["GH-801"]["metrics"]["calc"]')" "305"; echo $?)"
   155	ok "effectiveScore falls back to calc when there is no override" \
   156	   "$(is "$(q 'cards["GH-801"]["metrics"]["effectiveScore"]')" "305"; echo $?)"
   157	ok "sev >= 80 flags the card hot (one constant, not a threshold system)" \
   158	   "$(is "$(q 'cards["GH-801"]["metricFlags"]["sev"]')" "hot"; echo $?)"
   159	ok "an override REPLACES calc for ranking while the honest axes stay underneath" \
   160	   "$(is "$(q 'str(cards["GH-805"]["metrics"]["effectiveScore"]) + "/" + str(cards["GH-805"]["metrics"]["calc"])')" "399/40"; echo $?)"
   161	ok "an UNRATED card carries no metrics key at all — no placeholder, no 0/400 noise" \
   162	   "$(is "$(q 'cards["GH-802"].get("metrics") is None')" "True"; echo $?)"
   163	ok "a rated DETOUR is scored too (detours reparse the markdown; the index is handed to them)" \
   164	   "$(is "$(q 'cards["GH-900"]["metrics"]["effectiveScore"]')" "200"; echo $?)"
   165	
   166	# the pinned exit-criterion command, run verbatim against this payload
   167	echo "-- the pinned ranking command"
   168	TOP="$(python3 - "$JSON" <<'PY'
   169	import json, sys
   170	payload = json.load(open(sys.argv[1]))
   171	rows = []
   172	for rel in payload["releases"]:
   173	    for item in rel["detours"] + rel["roadmap"]:
   174	        for card in (item["cards"] if item.get("type") == "marathon" else [item]):
   175	            m = card.get("metrics")
   176	            if m:
   177	                rows.append((m["effectiveScore"], card["id"]))
   178	rows.sort(reverse=True)
   179	print(" ".join("%s:%d" % (i, s) for s, i in rows))
   180	PY
   181	)"
   182	ok "the ranking is ordered by effectiveScore, override first, with no ties" \
   183	   "$(is "$TOP" "GH-805:399 GH-801:305 GH-900:200"; echo $?)"
   184	
   185	# ── the viewer template agrees with the data it is handed ───────────────────────────────────────
   186	echo "-- the template renders what the exporter emits"
   187	TPL="$(cat "$TEMPLATE")"
   188	N="$(printf '%s' "$TPL" | grep -c "\['pri','sev','appeal','effort','calc'\]")"
   189	ok "BOTH metric loops (card renderer and what's-next strip) carry appeal and effort" "$(is "$N" "2"; echo $?)"
   190	if has "$TPL" "100 = strongest" && ! has "$TPL" "1 = strongest"; then ok "the footer legend reads 100 = strongest — legend and data never disagree in a committed artifact" 0; else ok "legend flipped" 1; fi
   191	if has "$TPL" "rel.baseline"; then ok "the release node renders the baseline/growth pair" 0; else ok "baseline rendered" 1; fi
   192	
   193	# ── read-only: the page is a pure consumer ──────────────────────────────────────────────────────
   194	echo "-- read-only contract"
   195	DB_HASH="$(file_hash "$R/releases.db")"; DUMP_HASH="$(file_hash "$R/releases.sql")"
   196	python3 "$EXPORTER" --db "$R/releases.db" --preview "$WORK/preview.html" >/dev/null 2>&1
   197	if [ -s "$WORK/preview.html" ] && grep -q 'id="ledger-data"' "$WORK/preview.html"; then ok "--preview bakes a self-contained page with the payload inline" 0; else ok "preview bakes" 1; fi
   198	if [ -n "$DB_HASH" ] && [ "$(file_hash "$R/releases.db")" = "$DB_HASH" ] && [ "$(file_hash "$R/releases.sql")" = "$DUMP_HASH" ]; then ok "the exporter wrote no DB bytes (opened read-only; the page never writes back)" 0; else ok "exporter read-only" 1; fi
   199	if ra check >/dev/null 2>&1; then ok "the ledger still checks clean after every projection" 0; else ok "check clean" 1; fi
   200	
   201	# ── the leaderboard pipeline (GH-108 Phase D) ───────────────────────────────────────────────────
   202	# ONE SCORER, proven rather than asserted: the shell script's ranking must match the exporter's
   203	# `--json` ordering exactly. A script that re-derived calc or reapplied the override rule would be
   204	# the same drift class the "calc is never stored" rule prevents, one layer up.
   205	echo "-- the leaderboard pipeline"
   206	LB_MD="$WORK/LEADERBOARD.md"
   207	LEADERBOARD_DB="$R/releases.db" LEADERBOARD_OUTPUT="$LB_MD" bash "$HERE/../utils/leaderboard.sh" >/dev/null 2>&1
   208	ok "leaderboard.sh renders LEADERBOARD.md from the exporter's JSON" "$([ -s "$LB_MD" ]; echo $?)"
   209	if grep -q 'GENERATED' <<<"$(head -1 "$LB_MD")"; then ok "the file announces itself as generated (never hand-edited)" 0; else ok "generated header" 1; fi
   210	# POSIX sed rather than `rg`: ripgrep is not a documented prerequisite (README lists Codex CLI, agy
   211	# CLI, Node 18+, git, Python 3.8+) and this suite was the only thing in test/ or utils/ that needed
   212	# it, so the whole suite failed on any host without it. Handles both the linked `[GH-n](url)` and
   213	# bare `GH-n` row forms, same as the regex it replaces.
   214	SCRIPT_ORDER="$(sed -n 's/^| [0-9][0-9]* | \*\*[0-9][0-9]*\*\* | \[\{0,1\}\(GH-[0-9][0-9]*\).*/\1/p' "$LB_MD" | tr '\n' ' ' | sed 's/ $//')"
   215	ok "the script's ranking matches the pinned --json ordering EXACTLY (one scorer, proven)" \
   216	   "$(is "$SCRIPT_ORDER" "$(printf '%s' "$TOP" | sed 's/:[0-9]*//g')"; echo $?)"
   217	if grep -q 'Top of the line:\*\* GH-805' "$LB_MD"; then ok "the highest-scoring task is called out by name, override included" 0; else ok "top of the line" 1; fi
   218	if grep -q 'GH-900' "$LB_MD"; then ok "a rated DETOUR ranks too — not just manifest cards" 0; else ok "detour ranks" 1; fi
   219	CP="$WORK/lb-first.md"; cp "$LB_MD" "$CP"
   220	LEADERBOARD_DB="$R/releases.db" LEADERBOARD_OUTPUT="$LB_MD" bash "$HERE/../utils/leaderboard.sh" >/dev/null 2>&1
   221	ok "regeneration is idempotent — a second run is byte-identical" "$(cmp -s "$CP" "$LB_MD"; echo $?)"
   222	LEADERBOARD_DB="$R/releases.db" LEADERBOARD_OUTPUT="$LB_MD" bash "$HERE/../utils/leaderboard.sh" --check >/dev/null 2>&1
   223	ok "--check passes when the committed copy is in sync" "$?"
   224	printf '\nstale hand edit\n' >> "$LB_MD"
   225	LEADERBOARD_DB="$R/releases.db" LEADERBOARD_OUTPUT="$LB_MD" bash "$HERE/../utils/leaderboard.sh" --check >/dev/null 2>&1
   226	ok "--check FAILS on drift (a stale checked-in copy is a review signal)" "$([ $? -ne 0 ]; echo $?)"
   227	
   228	LB_HTML="$WORK/LEADERBOARD.html"
   229	python3 "$EXPORTER" --db "$R/releases.db" --leaderboard "$LB_HTML" >/dev/null 2>&1
   230	ok "--leaderboard bakes a self-contained page from the SAME template" "$([ -s "$LB_HTML" ]; echo $?)"
   231	if grep -q '"view": *"leaderboard"\|"view":"leaderboard"' "$LB_HTML"; then ok "the payload carries view=leaderboard — one template, two baked artifacts" 0; else ok "view field" 1; fi
   232	if grep -q 'leaderboardHTML' "$WORK/preview.html" && grep -q 'columnHTML' "$LB_HTML"; then ok "both artifacts share ONE renderer bundle (no second copy of the design system)" 0; else ok "shared bundle" 1; fi
   233	if grep -q 'id="view-link"' "$TEMPLATE"; then ok "the cross-link lives in .top, which never collapses" 0; else ok "cross-link placement" 1; fi
   234	# grep -E rather than `rg` (see the SCRIPT_ORDER note above). This assertion is negated, so with
   235	# ripgrep absent `rg -q` returned 127 and the test passed without checking anything.
   236	if ! grep -qE 'id="fbar"[^>]*>[^<]*<a id="view-link"' "$TEMPLATE"; then ok "and NOT in #fbar, which disappears with the header caret" 0; else ok "cross-link not in fbar" 1; fi
   237	# The leaderboard view never calls initInteractions(), so #fbar's search + focus + prev/next are
   238	# all inert there — a search box that looks broken (aider/qwen3.8-max QA r1).
   239	if grep -q 'body\[data-view="leaderboard"\] #fbar' "$TEMPLATE"; then ok "the leaderboard view hides #fbar rather than shipping an inert search box" 0; else ok "leaderboard hides fbar" 1; fi
   240	
   241	# ── GH-250: codename-only releases (version NULL) must not crash the bake ───────────────────────
   242	# `releases add` accepts a codename with no version, and release_columns() already fell back to
   243	# the codename for slug/name — but not for id, and _ver() only caught ValueError. So ONE
   244	# NULL-version row killed --preview and --leaderboard outright, and refresh_preview()'s warn-only
   245	# path turned that into artifacts that silently stop tracking the ledger. The versioned-no-target
   246	# row below is deliberate: it ties with the codename-only rows on the sort's primary key, pinning
   247	# the None-vs-str tiebreaker compare too.
   248	echo "-- GH-250: codename-only releases (version NULL)"
   249	rq add --version 9.9.9 --codename Tiebreak --status draft --description "Versioned, no target." --tracking-issue "$GH/910"
   250	rq add --codename "Night Owl" --status draft --description "Codename-only one." --tracking-issue "$GH/911"
   251	rq add --codename Falcon --status draft --description "Codename-only two." --tracking-issue "$GH/912"
   252	NO_VER="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM releases WHERE version IS NULL")"
   253	ok "fixture holds codename-only rows (version IS NULL in the ledger)" "$([ "$NO_VER" -ge 2 ]; echo $?)"
   254	J250="$WORK/gh250.json"
   255	if python3 "$EXPORTER" --db "$R/releases.db" --json > "$J250" 2>/dev/null; then ok "--json succeeds on a ledger with NULL-version releases" 0; else ok "--json on NULL-version ledger" 1; fi
   256	python3 "$EXPORTER" --db "$R/releases.db" --preview "$WORK/gh250-preview.html" >/dev/null 2>&1
   257	ok "--preview bakes (the crash refresh_preview's warn-only path used to hide)" "$([ -s "$WORK/gh250-preview.html" ]; echo $?)"
   258	python3 "$EXPORTER" --db "$R/releases.db" --leaderboard "$WORK/gh250-lb.html" >/dev/null 2>&1
   259	ok "--leaderboard bakes on the same ledger" "$([ -s "$WORK/gh250-lb.html" ]; echo $?)"
   260	IDS="$(python3 - "$J250" 2>/dev/null <<'PY'
     1	#!/usr/bin/env bash
     2	# GH-153: regression lock for the RELEASES dashboard sidebar + full-cycle rollup spike.
     3	#
     4	# Pins three surfaces, all additive by design:
     5	#   (1) utils/py/releases_cycle.py — the shared module: JSON contract, markdown sections,
     6	#       exit 2 on missing/corrupt DB (rollup.sh degrades per repo on that code);
     7	#   (2) utils/timeline/export_timeline.py — ships the additive payload keys (projects, cycle,
     8	#       meta.repoUrl) and bakes the sidebar chrome into BOTH artifacts from the one template;
     9	#   (3) utils/timeline/RELEASES.html — the three nav states (expanded/rail/hidden), the
    10	#       non-link placeholders, and the boot()-side __snCycle hook that fills the panel.
    11	# The rollup.sh embed path (verbatim + demoted + failure-visible) is pinned by
    12	# test/hq-rollup.sh Cases A/F/G — deliberately not duplicated here.
    13	#
    14	# Negative controls: pre-GH-153 the exporter payload had no cycle/projects keys, the template
    15	# had no #sidenav, and releases_cycle.py did not exist — every "MISS" below was the old state.
    16	
    17	set -uo pipefail
    18	# strict-mode: -e exempt — assertion-style test with expected-nonzero probes handled explicitly.
    19	
    20	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    21	ROOT="$(cd "$HERE/.." && pwd)"
    22	CYCLE="$ROOT/utils/py/releases_cycle.py"
    23	EXPORTER="$ROOT/utils/timeline/export_timeline.py"
    24	TEMPLATE="$ROOT/utils/timeline/RELEASES.html"
    25	
    26	# shellcheck source=test/lib/fixture-guard.sh
    27	. "$ROOT/test/lib/fixture-guard.sh"
    28	
    29	WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh153.XXXXXX")"
    30	fixture_guard_init "$WORK"
    31	trap 'rm -rf "$WORK"' EXIT
    32	
    33	PASS=0
    34	FAIL=0
    35	pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
    36	fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
    37	
    38	echo "== test: gh153-releases-sidebar-rollup =="
    39	echo "  workdir: $WORK"
    40	
    41	# The repo's own committed ledger is the fixture — copied into the sandbox, never touched in place.
    42	DB="$WORK/releases.db"
    43	cp "$ROOT/releases.db" "$DB"
    44	require_fixture_file "$DB" "ledger fixture"
    45	
    46	echo "-- module: JSON contract against a real ledger copy --"
    47	JSON_OUT="$("$CYCLE" --db "$DB" --json)"
    48	rc=$?
    49	[ "$rc" -eq 0 ] && pass "cycle module exits 0 on a real ledger (invoked via exec bit, as rollup.sh does)" \
    50	  || fail "cycle module rc=$rc on a real ledger"
    51	if python3 - "$JSON_OUT" <<'PY'
    52	import json, sys
    53	s = json.loads(sys.argv[1])
    54	assert {"repo", "generatedAt", "db", "releases", "roadmap", "marathons", "items",
    55	        "recentEvents"} <= set(s), sorted(s)
    56	assert {"total", "open", "overdue", "byStatus", "openList", "recentShipped"} <= set(s["releases"])
    57	assert {"wip", "queued", "done", "paused", "total"} <= set(s["roadmap"])
    58	assert {"dialedIn", "shipped", "cut", "open"} <= set(s["items"])
    59	assert isinstance(s["db"]["generation"], int) and s["db"]["receipts"] >= 0
    60	assert s["releases"]["total"] == sum(s["releases"]["byStatus"].values()), "total != sum(byStatus)"
    61	assert s["marathons"]["total"] == sum(s["marathons"]["byStatus"].values())
    62	PY
    63	then pass "JSON shape: all sections present, counts internally consistent"
    64	else fail "JSON shape mismatch (see python traceback above)"
    65	fi
    66	
    67	echo "-- module: markdown render + repo-label override --"
    68	MD_OUT="$("$CYCLE" --db "$DB" --repo-label SPIKE-REPO)"
    69	rc=$?
    70	[ "$rc" -eq 0 ] && pass "markdown render exits 0" || fail "markdown render rc=$rc"
    71	for heading in "# RELEASES cycle — SPIKE-REPO" \
    72	               "## Releases — " "## Roadmap shadow — " "## Marathons — " \
    73	               "## Manifest outcomes" "## Latest state events"; do
    74	  grep -q "$heading" <<<"$MD_OUT" \
    75	    && pass "markdown section present: $heading" \
    76	    || fail "markdown section missing: $heading"
    77	done
    78	
    79	echo "-- module: exit 2 on missing / corrupt DB (rollup.sh degrades on this code) --"
    80	"$CYCLE" --db "$WORK/no-such.db" >/dev/null 2>"$WORK/missing.err"
    81	rc=$?
    82	[ "$rc" -eq 2 ] && pass "missing DB -> exit 2" || fail "missing DB -> rc=$rc (want 2)"
    83	grep -q "no releases DB" "$WORK/missing.err" \
    84	  && pass "missing DB names the path on stderr" || fail "missing DB stderr silent"
    85	
    86	printf 'definitely not a sqlite database\n' > "$WORK/corrupt.db"
    87	"$CYCLE" --db "$WORK/corrupt.db" >/dev/null 2>"$WORK/corrupt.err"
    88	rc=$?
    89	[ "$rc" -eq 2 ] && pass "corrupt DB -> exit 2" || fail "corrupt DB -> rc=$rc (want 2)"
    90	grep -q "releases_cycle:" "$WORK/corrupt.err" \
    91	  && pass "corrupt DB explains itself on stderr" || fail "corrupt DB stderr silent"
    92	rm -f "$WORK/corrupt.db"
    93	
    94	echo "-- exporter: additive payload keys --"
    95	EXPORT_JSON="$(python3 "$EXPORTER" --db "$DB" --json)"
    96	rc=$?
    97	[ "$rc" -eq 0 ] && pass "exporter --json exits 0 with the cycle import in place" \
    98	  || fail "exporter --json rc=$rc"
    99	if python3 - "$EXPORT_JSON" <<'PY'
   100	import json, sys
   101	d = json.loads(sys.argv[1])
   102	assert "cycle" in d and "projects" in d, sorted(d)
   103	assert d["meta"]["repoUrl"] and d["meta"]["repoUrl"].startswith("https://github.com/")
   104	assert any(p["slug"] == "XYZ-forge" and p["active"] for p in d["projects"]), d["projects"]
   105	assert d["cycle"]["releases"]["total"] >= 1
   106	PY
   107	then pass "payload carries projects + cycle + meta.repoUrl, values sane"
   108	else fail "payload keys missing/wrong (see python traceback above)"
   109	fi
   110	
   111	echo "-- exporter: sidebar chrome baked into BOTH artifacts from the one template --"
   112	PREVIEW="$WORK/RELEASES-PREVIEW.html"
   113	LEADER="$WORK/LEADERBOARD.html"
   114	python3 "$EXPORTER" --db "$DB" --preview "$PREVIEW" >/dev/null \
   115	  && pass "preview bake exits 0" || fail "preview bake failed"
   116	python3 "$EXPORTER" --db "$DB" --leaderboard "$LEADER" >/dev/null \
   117	  && pass "leaderboard bake exits 0" || fail "leaderboard bake failed"
   118	require_fixture_file "$PREVIEW" "baked preview"
   119	require_fixture_file "$LEADER" "baked leaderboard"
   120	
   121	MARKERS=('id="sidenav-toggle"'      # hamburger — the slideout control
   122	         'id="sidenav"'             # the nav itself
   123	         'id="sn-project"'          # project switcher
   124	         'id="sn-min"'              # minimize-to-rail chevron
   125	         'data-snfocus="rel"'       # focus items wired to the #fbar buttons
   126	         'class="sn-item sn-ph"'    # NON-LINK placeholders (no fake hrefs)
   127	         '__snCycle'                # boot()-side hook filling the panel
   128	         'data-sn="expanded"'       # default ON
   129	         'id="ledger-data"')        # the pre-existing inline payload survives the injection
   130	for f in "$PREVIEW" "$LEADER"; do
   131	  fname="$(basename "$f")"
   132	  for m in "${MARKERS[@]}"; do
   133	    grep -q "$m" "$f" \
   134	      && pass "$fname: $m" \
   135	      || fail "$fname: MISSING $m"
   136	  done
   137	done
   138	
   139	echo "-- template: states + placeholders are source-level facts --"
   140	for pat in 'body\[data-sn="rail"\]' 'body\[data-sn="hidden"\]' 'placeholder — no destination yet' \
   141	           'localStorage.setItem(KEY,state)' 'window.__snCycle=function(data)'; do
   142	  grep -q "$pat" "$TEMPLATE" \
   143	    && pass "template carries: $pat" \
   144	    || fail "template missing: $pat"
   145	done
   146	
   147	echo "== gh153-releases-sidebar-rollup: $PASS passed, $FAIL failed =="
   148	[ "$FAIL" -eq 0 ]
     1	#!/usr/bin/env bash
     2	# test/gh267-express-skill.sh — GH-267 regression guard for the /express driver.
     3	#
     4	# WHY THIS EXISTS: /express is the only sanctioned no-human-gate landing path in
     5	# this repo (it mechanizes SOP §4's express-to-development carve-out). Its value
     6	# IS its refusal surface: a lane that can be talked past any guardrail is just a
     7	# direct push with extra steps. This suite pins the guardrails shut.
     8	#
     9	# WHAT IS CHECKED (all hermetic — a fake `gh` on PATH serves issue state, a
    10	# local bare remote serves origin/development; no network, no real GitHub):
    11	#   refusals: task-branch, task-clone, frozen-twin, shared-runtime, no-new-bash,
    12	#             kernel-surface, scratch (.orig editor artifact), too-many-files,
    13	#             suite-unregistered, issue-closed
    14	#   happy path: check PASS on a legal single-subsystem fix with a registered suite;
    15	#               docs (.md) never count against the file bound
    16	#   docs: capture doc born complete (Lessons Learned present from birth) +
    17	#         CHANGELOG entry inserted under a fresh dated Unreleased section +
    18	#         CHANGELOG entry NOT silently dropped when today's section lacks a
    19	#         ### Fixed heading (deepseek QA finding 3)
    20	#   telemetry: every refusal writes a .tick express-refused event carrying the rule
    21	#   production projections: every adopted releases view + the roadmap dashboard
    22	#   TOCTOU: both new paths and mutations of already-qualified bytes refuse
    23	#   closeout: ship is persisted before clean-tree reconciliation; every failure ticks
    24	#   source audit: cmd_land/build_offline_manifest never call args_repo() — the
    25	#             --repo flag must thread through every landing gh call (QA finding 1)
    26	#
    27	# CONTAINMENT (GH-567): every path derived from $WORK is asserted non-empty and
    28	# lexically under $WORK at the point of use, not just at mktemp time. The suite
    29	# never writes outside $WORK and never touches the real clone it runs from.
    30	
    31	set -u
    32	HERE="$(cd "$(dirname "$0")" && pwd)"
    33	DRIVER="$HERE/../utils/py/express.py"
    34	WORK="$(mktemp -d /tmp/gh267-express.XXXXXX)" || { echo "FAIL: mktemp"; exit 1; }
    35	BIN="$WORK/bin"; GH_STATE="$WORK/gh-state"
    36	mkdir -p "$BIN" "$GH_STATE"
    37	
    38	# GH-1 adoption: the central fixture guard (GH-564 kill conditions + GH-567
    39	# use-boundary resolution), armed at source time — no private copies.
    40	. "$HERE/lib/fixture-guard.sh"
    41	fixture_guard_init "$WORK"
    42	
    43	case "$WORK" in /tmp/gh267-express.*) ;; *) echo "FAIL: unsafe WORK=$WORK"; exit 1;; esac
    44	
    45	PASS=0; FAIL=0
    46	ok()   { PASS=$((PASS+1)); echo "  pass: $1"; }
    47	bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
    48	check_rule() { # check_rule <expected-rule> <stderr-file>
    49	  if grep -q "express-refused: rule=$1" "$2"; then
    50	    return 0
    51	  fi
    52	  echo "    [stderr was: $(tail -1 "$2" 2>/dev/null)]"
    53	  return 1
    54	}
    55	
    56	# ── fake gh ──────────────────────────────────────────────────────────────────
    57	cat > "$BIN/gh" <<'GH'
    58	#!/usr/bin/env bash
    59	# gh267 suite stub: issue view from $GH_STATE; pr create/merge simulated (PR #777).
    60	set -u
    61	if [ "$1 $2" = "issue view" ]; then
    62	  n=""; prev=""
    63	  for a in "$@"; do
    64	    [ "$prev" = "view" ] && n="$a"
    65	    prev="$a"
    66	  done
    67	  cat "$GH_STATE/issue-$n.json" && exit 0
    68	fi
    69	if [ "$1 $2" = "pr create" ]; then echo "https://github.com/H/H/pull/777"; exit 0; fi
    70	if [ "$1 $2" = "pr merge" ]; then
    71	  # Simulate GitHub's merge into the remote development branch.
    72	  git -C "$EXPRESS_FX" checkout -q development || exit 1
    73	  git -C "$EXPRESS_FX" merge -q --no-ff task/gh-999 -m "merge express fixture" || exit 1
    74	  git -C "$EXPRESS_FX" push -q origin development || exit 1
    75	  printf '{"state":"CLOSED","title":"Demo hotfix","url":"https://github.com/H/H/issues/999","createdAt":"2026-08-27T00:00:00Z"}\n' > "$GH_STATE/issue-999.json"
    76	  exit 0
    77	fi
    78	echo "gh-stub: unsupported invocation: $*" >&2; exit 1
    79	GH
    80	chmod +x "$BIN/gh"
    81	export PATH="$BIN:$PATH"
    82	export GH_STATE
    83	issue_json() { printf '{"state":"%s","title":"%s","url":"https://github.com/H/H/issues/%s","createdAt":"2026-08-27T00:00:00Z"}\n' "$1" "$2" "$3" > "$GH_STATE/issue-$3.json"; }
    84	issue_json OPEN "Demo hotfix" 999
    85	issue_json CLOSED "Already done" 888
    86	
    87	# ── fixture repo ─────────────────────────────────────────────────────────────
    88	FX="$WORK/repo"; REMOTE="$WORK/remote.git"
    89	export EXPRESS_FX="$FX"
    90	git init -q --bare "$REMOTE"
    91	git init -q "$FX"
    92	git -C "$FX" remote add origin "$REMOTE"
    93	git -C "$FX" config user.email t@t; git -C "$FX" config user.name t
    94	mkdir -p "$FX/utils/py" "$FX/utils" "$FX/test" "$FX/relay-automation" "$FX/src" "$FX/PROJECT/2-WORKING" "$FX/CHANGELOG.d" "$FX/githooks"
    95	printf '#!/usr/bin/env bash\nTESTS=(\n  "gh999-demo.sh"\n  "gh999-drift.sh"\n  "gh999-content-drift.sh"\n  "gh999-hook-drift.sh"\n  "other.sh"\n)\n' > "$FX/validate.sh"
    96	printf 'old\n' > "$FX/utils/py/foo.py"
    97	printf 'twin body\n' > "$FX/relay-automation/consult.sh"
    98	printf 'shared runtime\n' > "$FX/relay-automation/relay-turn-lib.sh"
    99	printf 'kernel\n' > "$FX/src/project.js"
   100	printf 'readme\n' > "$FX/README.md"
   101	printf '.tick/\n' > "$FX/.gitignore"
   102	printf '# demo suite\n' > "$FX/test/gh999-demo.sh"
   103	printf '# suite that writes a stray file at run time (TOCTOU probe)\nprintf stray > stray-suite-artifact.txt\n' > "$FX/test/gh999-drift.sh"
   104	printf '# suite that rewrites a qualified path (content TOCTOU probe)\nprintf suite-mutated > utils/py/foo.py\n' > "$FX/test/gh999-content-drift.sh"
   105	printf '# suite that replaces the untracked git-metadata hook\nprintf "#!/bin/sh\\nexit 0\\n" > .git/hooks/pre-push\nchmod +x .git/hooks/pre-push\n' > "$FX/test/gh999-hook-drift.sh"
   106	printf '# unregistered suite\n' > "$FX/test/gh999b-unreg.sh"
   107	# Use the real installer contract with a tiny fixture gate. A foreign executable
   108	# hook must not satisfy `install.sh --check`.
   109	cp "$HERE/../githooks/install.sh" "$FX/githooks/install.sh"
   110	printf '#!/usr/bin/env bash\nexit 0\n' > "$FX/githooks/pre-push"
   111	chmod +x "$FX/githooks/install.sh" "$FX/githooks/pre-push"
   112	
   113	# Faithful write-surface stub: every mutating releases verb changes the DB/dump
   114	# and every adopted projection that production refresh_preview owns.
   115	cat > "$FX/utils/py/releases_app.py" <<'RA'
   116	#!/usr/bin/env python3
   117	import os, sqlite3, sys
   118	a = sys.argv[1:]
   119	if a[:1] == ["next"]:
   120	    print("NEXT: stub gid=rel-STUB000000000000000000000008")
   121	if a[:2] in (["roadmap", "add"], ["manifest", "dial-in"], ["manifest", "ship"]):
   122	    c = sqlite3.connect("releases.db")
   123	    c.execute("CREATE TABLE IF NOT EXISTS fixture_writes (id INTEGER PRIMARY KEY, verb TEXT)")
   124	    c.execute("INSERT INTO fixture_writes(verb) VALUES (?)", (" ".join(a[:2]),))
   125	    c.commit(); c.close()
   126	    for name in ("releases.sql", "RELEASES.generated.md", "RELEASES-PREVIEW.html",
   127	                 "LEADERBOARD.html", "LEADERBOARD.md"):
   128	        with open(name, "a", encoding="utf-8") as f:
   129	            f.write("stub-release-write: %s\n" % " ".join(a[:2]))
   130	print("stub-releases:", " ".join(a[:2]))
   131	RA
   132	cat > "$FX/utils/py/wave_reconcile.py" <<'WR'
   133	#!/usr/bin/env python3
   134	import os, subprocess, sys
   135	if os.environ.get("WR_FAIL") == "1":
   136	    print("forced reconcile failure", file=sys.stderr); sys.exit(9)
   137	if subprocess.run(["git", "status", "--porcelain"], capture_output=True, text=True).stdout.strip():
   138	    print("reconcile requires a clean tree", file=sys.stderr); sys.exit(8)
   139	if subprocess.run(["git", "branch", "--show-current"], capture_output=True, text=True).stdout.strip() != "development":
   140	    print("reconcile requires development", file=sys.stderr); sys.exit(7)
   141	src = "PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md"
   142	dst = "PROJECT/3-COMPLETED/GH-999-DEMO-HOTFIX.md"
   143	if os.path.exists(src):
   144	    os.makedirs(os.path.dirname(dst), exist_ok=True)
   145	    os.replace(src, dst)
   146	WR
   147	cat > "$FX/utils/roadmap-dashboard.sh" <<'RD'
   148	#!/usr/bin/env bash
   149	printf 'stub-dashboard-refresh\n' >> ROADMAP-DASHBOARD.md
   150	RD
   151	chmod +x "$FX/utils/roadmap-dashboard.sh"
   152	python3 -c "import sqlite3; c=sqlite3.connect('$FX/releases.db'); c.execute('CREATE TABLE IF NOT EXISTS roadmap_items (global_id TEXT, gh_number INTEGER)'); c.commit(); c.close()"
   153	printf 'base dump\n' > "$FX/releases.sql"
   154	for projection in RELEASES.generated.md RELEASES-PREVIEW.html LEADERBOARD.html LEADERBOARD.md ROADMAP-DASHBOARD.md; do
   155	  printf 'base projection\n' > "$FX/$projection"
   156	done
   157	printf '# Changelog\n\nAll notable changes.\n\n## [Unreleased] - 2026-01-01\n\n### Fixed\n- old entry\n' > "$FX/CHANGELOG.md"
   158	git -C "$FX" add -A && git -C "$FX" commit -qm base
   159	git -C "$FX" branch -m development
   160	git -C "$FX" push -q origin development
   161	git -C "$FX" fetch -q origin
   162	(cd "$FX" && bash githooks/install.sh) >/dev/null
   163	require_fixture "$FX"
   164	require_fixture "$REMOTE"
   165	echo "fixture ready"
   166	
   167	new_task_branch() {
   168	  # reset to a pristine task branch: discard tracked mods, untracked files, and
   169	  # any stray commits, so each case starts from the exact base state
   170	  require_fixture "$FX"
   171	  git -C "$FX" checkout -q development
   172	  git -C "$FX" reset -q --hard origin/development
   173	  git -C "$FX" clean -fdq
   174	  git -C "$FX" checkout -q -B task/gh-999 origin/development
   175	  # The production prerequisite is per clone; restore the canonical fixture
   176	  # stub after every destructive sandbox reset so cases cannot contaminate it.
   177	  rm -f "$FX/.git/hooks/pre-push"
   178	  (cd "$FX" && bash githooks/install.sh) >/dev/null || exit 1
   179	}
   180	run_check() {
   181	  require_fixture "$FX"
   182	  python3 "$DRIVER" --root "$FX" check --issue "${1:-999}" --suite "${2:-test/gh999-demo.sh}" ;
   183	}
   184	
   185	echo "== refusals =="
   186	ERR="$WORK/err"; : > "$ERR"
   187	
   188	new_task_branch; git -C "$FX" checkout -q development
   189	run_check > /dev/null 2> "$ERR" && bad "on-development must refuse" || { check_rule task-branch "$ERR" && ok "task-branch refusal" || bad "task-branch rule"; }
   190	EV="$(ls "$FX/.tick/events/"*express-refused*.jsonl 2>/dev/null | head -1)"
   191	[ -n "$EV" ] && grep -q '"verb": "express-refused"' "$EV" && ok "express-refused tick event written" || bad "tick telemetry missing"
   192	
   193	new_task_branch; printf 'x\n' >> "$FX/utils/py/foo.py"; git -C "$FX" add -A; git -C "$FX" commit -qm extra
   194	run_check > /dev/null 2> "$ERR" && bad "HEAD-ahead must refuse" || { check_rule task-clone "$ERR" && ok "task-clone refusal (GH-527)" || bad "task-clone rule"; }
   195	
   196	new_task_branch; printf 'x\n' >> "$FX/relay-automation/consult.sh"
   197	run_check > /dev/null 2> "$ERR" && bad "twin edit must refuse" || { check_rule frozen-twin "$ERR" && ok "frozen-twin refusal (GH-308)" || bad "frozen-twin rule"; }
   198	
   199	new_task_branch; printf 'x\n' >> "$FX/relay-automation/relay-turn-lib.sh"
   200	run_check > /dev/null 2> "$ERR" && bad "shared runtime edit must refuse" || { check_rule shared-runtime "$ERR" && ok "shared-runtime refusal (QA F4: not mislabeled frozen-twin)" || bad "shared-runtime rule"; }
   201	
   202	new_task_branch; printf 'x\n' > "$FX/utils/py/leftover.py.orig"
   203	run_check > /dev/null 2> "$ERR" && bad ".orig artifact must refuse" || { check_rule scratch "$ERR" && ok "scratch refusal for .orig (QA F2)" || bad ".orig scratch rule"; }
   204	
   205	new_task_branch; printf 'x\n' >> "$FX/relay-automation/new-thing.sh"
   206	run_check > /dev/null 2> "$ERR" && bad "new bash must refuse" || { check_rule no-new-bash "$ERR" && ok "no-new-bash refusal (GH-551)" || bad "no-new-bash rule"; }
   207	
   208	new_task_branch; printf 'x\n' >> "$FX/src/project.js"
   209	run_check > /dev/null 2> "$ERR" && bad "kernel surface must refuse" || { check_rule kernel-surface "$ERR" && ok "kernel-surface refusal" || bad "kernel-surface rule"; }
   210	
   211	new_task_branch; printf 'x\n' >> "$FX/githooks/pre-push"
   212	run_check > /dev/null 2> "$ERR" && bad "gate source edit must refuse" || { check_rule kernel-surface "$ERR" && ok "gate source is a refused safety surface" || bad "gate-source kernel rule"; }
   213	
   214	new_task_branch; for i in 1 2 3 4 5; do printf 'x\n' > "$FX/utils/py/f$i.py"; done
   215	run_check > /dev/null 2> "$ERR" && bad "5 files must refuse" || { check_rule too-many-files "$ERR" && ok "too-many-files refusal" || bad "too-many-files rule"; }
   216	
   217	new_task_branch; printf 'x\n' >> "$FX/utils/py/foo.py"
   218	run_check 999 test/gh999b-unreg.sh > /dev/null 2> "$ERR" && bad "unregistered suite must refuse" || { check_rule suite-unregistered "$ERR" && ok "suite-unregistered refusal" || bad "suite-unregistered rule"; }
   219	
   220	new_task_branch; printf 'x\n' >> "$FX/utils/py/foo.py"
   221	run_check 888 > /dev/null 2> "$ERR" && bad "closed issue must refuse" || { check_rule issue-closed "$ERR" && ok "issue-closed refusal (already-landed guard)" || bad "issue-closed rule"; }
   222	
   223	new_task_branch; printf 'x\n' >> "$FX/utils/py/foo.py"; rm -f "$FX/.git/hooks/pre-push"
   224	run_check > /dev/null 2> "$ERR" && bad "unwired gate must refuse" || { check_rule gate-unwired "$ERR" && ok "gate-unwired refusal (finding 3: hooks do not travel)" || bad "gate-unwired rule"; }
   225	printf '#!/bin/sh\nexit 0\n' > "$FX/.git/hooks/pre-push" && chmod +x "$FX/.git/hooks/pre-push"
   226	run_check > /dev/null 2> "$ERR" && bad "foreign no-op hook must not prove the gate" || { check_rule gate-unwired "$ERR" && ok "gate-unwired rejects an executable no-op impostor" || bad "gate identity rule"; }
   227	rm -f "$FX/.git/hooks/pre-push" && (cd "$FX" && bash githooks/install.sh) >/dev/null
   228	
   229	new_task_branch; printf 'x\n' >> "$FX/utils/py/foo.py"; printf 'hand edit\n' > "$FX/releases.sql"
   230	run_check > /dev/null 2> "$ERR" && bad "hand-edited ledger must refuse" || { check_rule ledger-hand-edit "$ERR" && ok "ledger-hand-edit refusal (verbs only)" || bad "ledger-hand-edit rule"; }
   231	
   232	new_task_branch; printf 'x\n' >> "$FX/utils/py/foo.py"; printf 'hand edit\n' > "$FX/RELEASES-PREVIEW.html"
   233	run_check > /dev/null 2> "$ERR" && bad "hand-edited generated view must refuse" || { check_rule driver-output-hand-edit "$ERR" && ok "driver-output-hand-edit refusal (generated views are verb-owned)" || bad "driver-output-hand-edit rule"; }
   234	
   235	echo "== happy path =="
   236	new_task_branch; printf 'fixed\n' > "$FX/utils/py/foo.py"; printf '# demo suite v2\n' > "$FX/test/gh999-demo.sh"
   237	OUT="$(run_check 999)"
   238	grep -q "express-check: PASS" <<<"$OUT" && ok "legal fix passes" || bad "legal fix refused: $OUT"
   239	
   240	new_task_branch; printf 'fixed\n' > "$FX/utils/py/foo.py"; for i in 1 2 3; do printf 'x\n' > "$FX/utils/py/g$i.py"; done; printf 'doc edit\n' > "$FX/README.md"
   241	run_check > /dev/null 2> "$ERR" && bad "README must count against the file bound (finding 5)" || { check_rule too-many-files "$ERR" && ok "operator .md edits COUNT against the bound (finding 5)" || bad "README exempted: $(tail -1 "$ERR")"; }
   242	
   243	new_task_branch; printf 'fixed\n' > "$FX/utils/py/foo.py"; printf 'entry\n' >> "$FX/CHANGELOG.md"
   244	run_check > /dev/null 2> "$ERR" && ok "the lane's own paperwork (CHANGELOG) stays exempt" || bad "CHANGELOG counted against bounds: $(tail -1 "$ERR")"
   245	
   246	echo "== docs born complete =="
   247	python3 "$DRIVER" --root "$FX" docs --issue 999 --suite test/gh999-demo.sh --summary "demo" >/dev/null 2>"$ERR" || bad "docs scaffold failed: $(cat "$ERR")"
   248	DOC="$FX/PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md"
   249	[ -f "$DOC" ] && ok "capture doc created" || bad "capture doc missing"
   250	grep -q "## Lessons Learned (For Future Agents)" "$DOC" 2>/dev/null && ok "Lessons Learned present from birth (GH-232 gate)" || bad "doc not born complete"
   251	grep -q "^## Status$" "$DOC" && grep -q "^## Acceptance Criteria$" "$DOC" && ok "Status + Acceptance present" || bad "doc sections incomplete"
   252	TODAY="$(date +%F)"
   253	grep -q "## \[Unreleased\] - $TODAY" "$FX/CHANGELOG.md" && ok "CHANGELOG dated section inserted" || bad "CHANGELOG section missing"
   254	CH_TODAY="$(awk "/## \[Unreleased\] - $TODAY/,0" "$FX/CHANGELOG.md")"
   255	grep -q "GH-999" <<<"$CH_TODAY" && ok "CHANGELOG entry present" || bad "CHANGELOG entry missing"
   256	
   257	# QA F3: a today-section WITHOUT a ### Fixed heading must not silently drop the entry
   258	new_task_branch
   259	printf '# Changelog\n\nAll notable changes.\n\n## [Unreleased] - %s\n\n### Added\n- someone added something\n\n## [Unreleased] - 2026-01-01\n\n### Fixed\n- old entry\n' "$TODAY" > "$FX/CHANGELOG.md"
   260	rm -f "$FX/PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md"
   261	python3 "$DRIVER" --root "$FX" docs --issue 999 --suite test/gh999-demo.sh --summary "demo" >/dev/null 2>"$ERR" || bad "docs scaffold (no-Fixed-heading) failed: $(cat "$ERR")"
   262	CH_F3="$(awk "/## \[Unreleased\] - $TODAY/,/## \[Unreleased\] - 2026-01-01/" "$FX/CHANGELOG.md")"
   263	grep -q "GH-999" <<<"$CH_F3" && ok "CHANGELOG entry survives a Fixed-less today-section (QA F3)" || bad "CHANGELOG entry silently dropped (QA F3 regression)"
   264	
   265	echo "== run: end-to-end happy path (hermetic — stubbed gh/releases/reconcile) =="
   266	new_task_branch; rm -f "$FX/PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md"; printf 'fixed\n' > "$FX/utils/py/foo.py"; printf '# demo suite v2\n' > "$FX/test/gh999-demo.sh"
   267	issue_json OPEN "Demo hotfix" 999
   268	RUNOUT="$(python3 "$DRIVER" --root "$FX" run --issue 999 --suite test/gh999-demo.sh --summary demo 2>"$ERR")"
   269	if grep -q "express-land: PR #777 merged" <<<"$RUNOUT"; then
   270	  ok "run accepts the full production projection set"
   271	else
   272	  bad "run failed: $(tail -2 "$ERR")"
   273	fi
   274	[ "$(git -C "$FX" branch --show-current)" = development ] && ok "closeout left the clone on development" || bad "clone not on development after run"
   275	RECENT_LOG="$(git -C "$FX" log --format=%s -3)"
   276	grep -q "express ship GH-999" <<<"$RECENT_LOG" && ok "ship transaction persisted before reconciliation" || bad "ship commit missing"
   277	grep -q "express reconcile GH-999" <<<"$RECENT_LOG" && ok "reconcile persisted as a separate clean-tree transaction" || bad "reconcile commit missing"
   278	[ -z "$(git -C "$FX" status --porcelain)" ] && ok "successful closeout leaves development clean" || bad "successful closeout left drift: $(git -C "$FX" status --short | tr '\n' ';')"
   279	FIRED="$(ls "$FX/.tick/events/"*express-fired*.jsonl 2>/dev/null | head -1)"
   280	[ -n "$FIRED" ] && ok "express-fired tick written on full success" || bad "express-fired tick missing"
     1	#!/usr/bin/env bash
     2	# GH-57 — the RELEASES merge contract, driven by an ACTUAL `git merge`.
     3	#
     4	# WHY THIS EXISTS, when gh53/gh54/gh57-releases-fuzz already cover merges.
     5	#
     6	# Every one of those suites builds its merged dump by hand — `awk '!seen[$0]++'` over two
     7	# `git show` outputs — and then calls the app. That proves what the app does with a mangled dump.
     8	# It does NOT prove what git actually leaves on disk, and it never puts the resolver in front of a
     9	# real conflicted index. Concretely, until this suite the following were all unexercised:
    10	#
    11	#   * that a real merge conflicts BOTH releases.sql and releases.db (the resolver branches on that)
    12	#   * the resolver's two refusals, against a genuinely unmerged tree rather than a simulated one
    13	#   * the full operator path: conflict -> hand-resolve the dump -> resolver -> `git merge --continue`
    14	#   * what the index looks like after the resolver FAILS
    15	#
    16	# The gap was noted on 2026-08-19 as "no PR has touched releases.sql concurrently with development",
    17	# which is true and is exactly why the live path had no coverage: the repo's own traffic never
    18	# produced one. A suite is the only way this path gets exercised before an operator meets it.
    19	#
    20	# Three of the scenarios below found real defects on first run; all three were fixed in the same
    21	# change and are pinned here. See RELEASES-DB-FAQS.md ("What a real merge actually looks like").
    22	set -uo pipefail
    23	
    24	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    25	ROOT_DIR="$(cd "$HERE/.." && pwd)"
    26	APP="$ROOT_DIR/utils/py/releases_app.py"
    27	RESOLVER="$ROOT_DIR/utils/releases-merge-resolve.sh"
    28	
    29	pass=0; fail=0
    30	ok()   { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1" >&2; fail=$((fail+1)); fi }
    31	has()  { printf '%s' "$1" | grep -Fq -- "$2"; }
    32	
    33	echo "== test: gh57-live-merge-resolve =="
    34	command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
    35	command -v sqlite3 >/dev/null 2>&1 || { echo "sqlite3 required" >&2; exit 1; }
    36	[ -f "$APP" ]     || { echo "missing app: $APP" >&2; exit 1; }
    37	[ -x "$RESOLVER" ] || { echo "missing resolver: $RESOLVER" >&2; exit 1; }
    38	
    39	WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh57-live.XXXXXX")"
    40	. "$HERE/lib/fixture-guard.sh"
    41	fixture_guard_init "$WORK"
    42	cleanup() {
    43	  case "${WORK:-}" in
    44	    "${TMPDIR:-/tmp}"/gh57-live.*) [ -d "$WORK" ] && rm -rf "$WORK" ;;
    45	    *) echo "gh57-live: REFUSING cleanup outside the workspace: ${WORK:-<empty>}" >&2 ;;
    46	  esac
    47	}
    48	trap cleanup EXIT
    49	
    50	ra() { local r="$1"; shift; require_fixture "$r" "releases fixture"; python3 "$APP" --root "$r" "$@"; }
    51	
    52	# Every path below that reaches a real tool goes through this first. Writing this suite escaped its
    53	# fixture exactly once — `conflicted()` aborted mid-build (see the `local` note there), returned an
    54	# empty string, and `--root ""` sent utils/releases-merge-resolve.sh at THIS repo, which rebuilt the
    55	# production ledger. The resolver now refuses an empty --root, and this guard makes the suite refuse
    56	# to get that far. Two independent stops, because one was already shown to be zero.
    57	fx() {  # <candidate-root> — die unless it is a real fixture under $WORK
    58	  local r="${1:-}"
    59	  [ -n "$r" ] || { echo "gh57-live: ABORT — empty fixture root; a fixture failed to build" >&2; exit 2; }
    60	  require_fixture "$r" "fixture root"
    61	  printf '%s\n' "$r"
    62	}
    63	resolver() { local r; r="$(fx "${1:-}")"; bash "$RESOLVER" --root "$r" 2>&1; }
    64	
    65	# Leave a repo sitting in a REAL, unresolved merge conflict on the ledger.
    66	# <name> <extra writes on the side branch> -> repo path
    67	conflicted() {
    68	  # NOTE: one name per `local`. macOS ships bash 3.2, where `local a=$1 b=$WORK/$a` does NOT see
    69	  # `a` — every name in the statement is localized (unset) before any assignment runs, so `$a`
    70	  # tripped `set -u`, aborted this function, and returned an empty path. That is what escaped the
    71	  # fixture and rebuilt the production ledger while this suite was being written.
    72	  local name="$1"
    73	  local extra="${2:-0}"
    74	  local r="$WORK/$name"
    75	  local i=0
    76	  mkdir -p "$r"; require_fixture "$r" "merge fixture"
    77	  git -C "$r" init -q -b main
    78	  git -C "$r" config user.email gh57live@test.invalid
    79	  git -C "$r" config user.name gh57live
    80	  ra "$r" init --slug "$name" >/dev/null
    81	  git -C "$r" add -A; git -C "$r" commit -qm base
    82	  git -C "$r" branch side
    83	  git -C "$r" checkout -q side
    84	  ra "$r" add --version 1.0.0 --status draft --description 'side one.' --tracking-issue TMP-SIDE01 >/dev/null
    85	  while [ "$i" -lt "$extra" ]; do
    86	    ra "$r" add --version "1.$((i+1)).0" --status draft --description 'side extra.' \
    87	      --tracking-issue "TMP-SIDE1$i" >/dev/null
    88	    i=$((i+1))
    89	  done
    90	  git -C "$r" commit -qam side
    91	  git -C "$r" checkout -q main
    92	  ra "$r" add --version 2.0.0 --status draft --description 'main one.' --tracking-issue TMP-MAIN01 >/dev/null
    93	  git -C "$r" commit -qam main
    94	  git -C "$r" merge side -m merge >"$r.merge.log" 2>&1 || true
    95	  printf '%s\n' "$r"
    96	}
    97	
    98	# Hand-resolve the dump the way RELEASES-DB-FAQS.md tells an operator to: union both sides' rows,
    99	# keep exactly ONE settings block, and keep the HIGHEST generation header.
   100	resolve_dump() {  # <repo> [override-header-number]
   101	  local r; r="$(fx "${1:-}")"          # same bash 3.2 rule: one name per `local`
   102	  local override="${2:-}"
   103	  local hi lo keep
   104	  hi="$(git -C "$r" show MERGE_HEAD:releases.sql | sed -n 's/^-- generation: \([0-9]*\)$/\1/p' | head -1)"
   105	  lo="$(git -C "$r" show HEAD:releases.sql       | sed -n 's/^-- generation: \([0-9]*\)$/\1/p' | head -1)"
   106	  [ "${lo:-0}" -gt "${hi:-0}" ] && hi="$lo"
   107	  keep="${override:-$hi}"
   108	  { printf -- '-- generation: %s\n' "$keep"
   109	    { git -C "$r" show HEAD:releases.sql; git -C "$r" show MERGE_HEAD:releases.sql; } \
   110	      | grep -v -E '^-- generation: |^INSERT INTO settings\(' | awk '!seen[$0]++'
   111	    git -C "$r" show MERGE_HEAD:releases.sql | grep '^INSERT INTO settings('
   112	  } > "$r/releases.sql"
   113	  git -C "$r" add releases.sql
   114	}
   115	
   116	# ── 1. what a real merge actually leaves behind ─────────────────────────────────────────────────
   117	echo "-- 1: the shape of a real conflict"
   118	R1="$(conflicted c1 1)"
   119	U="$(git -C "$R1" diff --name-only --diff-filter=U)"
   120	ok "a concurrent ledger write conflicts BOTH artifacts, not just the dump" \
   121	   "has \"\$U\" 'releases.sql' && has \"\$U\" 'releases.db'"
   122	ok "  and git wrote conflict markers into releases.sql" \
   123	   "[ \"\$(grep -c '^<<<<<<< ' '$R1/releases.sql')\" -ge 1 ]"
   124	ok "  and the conflicted dump carries both sides' generation headers" \
   125	   "[ \"\$(grep -c '^-- generation: ' '$R1/releases.sql')\" -eq 2 ]"
   126	
   127	# ── 2. the resolver refuses an unresolved dump, and refuses markers ─────────────────────────────
   128	echo "-- 2: refusals against a genuinely conflicted index"
   129	out="$(resolver "$R1")"; rc=$?
   130	ok "resolver refuses while releases.sql is unmerged (rc=$rc)" "[ $rc -ne 0 ]"
   131	ok "  and says which file needs judgment" "has \"\$out\" 'releases.sql is still unresolved'"
   132	# NOTE: `git diff --cached --name-only` lists BOTH conflicted paths during any in-progress merge —
   133	# that is how git reports unmerged index entries, not evidence of a write. Measure the file instead.
   134	R1_DB_HASH="$(shasum -a 256 "$R1/releases.db" | awk '{print $1}')"
   135	ok "  and did NOT touch the live DB (byte-identical after the refusal)" \
   136	   "[ \"\$(shasum -a 256 '$R1/releases.db' | awk '{print \$1}')\" = \"$R1_DB_HASH\" ]"
   137	
   138	# Marker check: stage the file WITH its markers still in it. The unmerged test above no longer
   139	# fires, so this is the only thing standing between markers and a rebuild.
   140	git -C "$R1" add releases.sql
   141	out="$(resolver "$R1")"; rc=$?
   142	ok "resolver refuses a staged dump that still contains conflict markers (rc=$rc)" "[ $rc -ne 0 ]"
   143	ok "  and names the markers as the reason" "has \"\$out\" 'still contains conflict markers'"
   144	
   145	# ── 3. the full operator path, end to end, through `git merge --continue` ───────────────────────
   146	echo "-- 3: conflict -> resolve dump -> resolver -> commit"
   147	R3="$(conflicted c3 1)"
   148	resolve_dump "$R3"
   149	out="$(resolver "$R3")"; rc=$?
   150	ok "resolver completes a real hand-resolved merge (rc=$rc)" "[ $rc -eq 0 ]"
   151	ok "  and says it deliberately did not commit" "has \"\$out\" 'does not commit'"
   152	ok "  and left no unmerged paths" "[ -z \"\$(git -C '$R3' diff --name-only --diff-filter=U)\" ]"
   153	out2="$(ra "$R3" check 2>&1)"; rc2=$?
   154	ok "  and the ledger checks clean afterwards" "[ $rc2 -eq 0 ] && has \"\$out2\" 'check: clean'"
   155	ok "  and BOTH sides' releases survived the merge" \
   156	   "[ \"\$(sqlite3 '$R3/releases.db' 'SELECT COUNT(*) FROM releases')\" -eq 3 ]"
   157	git -C "$R3" commit -q --no-edit >/dev/null 2>&1
   158	ok "  and \`git commit\` closes the merge" \
   159	   "[ -z \"\$(git -C '$R3' rev-parse --verify -q MERGE_HEAD 2>/dev/null)\" ]"
   160	ok "  and the committed tree carries both artifacts" \
   161	   "git -C '$R3' show --stat HEAD | grep -q releases.sql && git -C '$R3' show --stat HEAD | grep -q releases.db"
   162	
   163	# ── 4. EDGE CASE: a failed resolver must leave the merge genuinely open ─────────────────────────
   164	# Found broken 2026-08-19: the resolver staged releases.db BEFORE attempting the rebuild, so a
   165	# failing run had already marked half the merge resolved while its own error text said "nothing was
   166	# staged over it". An operator who trusted that line and ran `git commit` would have committed the
   167	# stale --ours DB against a dump it does not match — the silent divergence #52/#53 exist to stop.
   168	echo "-- 4: the failure path leaves the merge open (regression: it did not)"
   169	R4="$(conflicted c4 0)"
   170	resolve_dump "$R4"
   171	# Append a second, DIFFERING row for a GID the resolved dump already contains: a content conflict
   172	# no union can settle. Derive it from the merged dump itself — reading the GID out of the worktree
   173	# releases.db gives you the OURS side's release, which by construction is absent from MERGE_HEAD's
   174	# dump, so the duplicate never got appended and this scenario silently tested nothing.
   175	R4_ROW="$(grep -m1 '^INSERT INTO releases(' "$R4/releases.sql")"
   176	ok "fixture has a release row to duplicate" "[ -n \"\$R4_ROW\" ]"
   177	printf '%s\n' "$R4_ROW" | sed "s/one\./one EDITED ON THE OTHER BRANCH./" >> "$R4/releases.sql"
   178	R4_GID="$(printf '%s' "$R4_ROW" | grep -o 'rel-[A-Z0-9]*' | head -1)"
   179	ok "  and that GID now appears twice in the dump" \
   180	   "[ \"\$(grep -c \"\$R4_GID\" '$R4/releases.sql')\" -gt 1 ]"
   181	git -C "$R4" add releases.sql
   182	out="$(resolver "$R4")"; rc=$?
   183	ok "resolver fails on an unsettleable content conflict (rc=$rc)" "[ $rc -ne 0 ]"
   184	ok "  and releases.db is STILL unmerged — the merge is open, as the message claims" \
   185	   "git -C '$R4' diff --name-only --diff-filter=U | grep -qx releases.db"
   186	
   187	# ── 5. EDGE CASE: keeping the LOWER generation header must be refused ───────────────────────────
   188	# Found broken 2026-08-19: this returned rc=0 and then `check: clean`, with the ledger's generation
   189	# counter rewound below a merge parent's. The advice to keep the highest header existed only inside
   190	# another refusal's prose; nothing enforced it, so the one resolution that loses information was
   191	# also the one nothing complained about.
   192	echo "-- 5: a rewound generation header is refused (regression: it was accepted)"
   193	R5="$(conflicted c5 2)"
   194	LOW="$(git -C "$R5" show HEAD:releases.sql | sed -n 's/^-- generation: \([0-9]*\)$/\1/p' | head -1)"
   195	HIGH="$(git -C "$R5" show MERGE_HEAD:releases.sql | sed -n 's/^-- generation: \([0-9]*\)$/\1/p' | head -1)"
   196	ok "fixture really has unequal parent generations (HEAD=$LOW MERGE_HEAD=$HIGH)" "[ \"$LOW\" -lt \"$HIGH\" ]"
   197	resolve_dump "$R5" "$LOW"
   198	out="$(resolver "$R5")"; rc=$?
   199	ok "resolver refuses a header below the highest parent (rc=$rc)" "[ $rc -ne 0 ]"
   200	ok "  and names both parents' generations" "has \"\$out\" \"$LOW (HEAD)\" && has \"\$out\" \"$HIGH (MERGE_HEAD)\""
   201	ok "  and says what to set it to" "has \"\$out\" 'Set the header to $HIGH'"
   202	# POSITIVE CONTROL: the same fixture with the correct header must succeed, or the check above is
   203	# just refusing everything.
   204	resolve_dump "$R5"
   205	out="$(resolver "$R5")"; rc=$?
   206	ok "POSITIVE CONTROL: the SAME merge with the highest header resolves cleanly (rc=$rc)" "[ $rc -eq 0 ]"
   207	ok "  and the ledger's generation did not go backwards" \
   208	   "[ \"\$(sqlite3 '$R5/releases.db' \"SELECT value FROM settings WHERE key='generation'\")\" -gt \"$HIGH\" ]"
   209	
   210	# ── 6. EDGE CASE: the displaced DB backup must never be committable ─────────────────────────────
   211	# The resolver tells the operator releases.db.bak is "untracked and safe to delete". It was not
   212	# ignored, so a `git add -A` before `git merge --continue` would have committed a stale binary copy
   213	# of the ledger — the one artifact guaranteed to disagree with the dump.
   214	echo "-- 6: releases.db.bak is ignored, not merely unmentioned"
   215	ok "the rebuild really produced a .bak to worry about" "[ -f '$R3/releases.db.bak' ]"
   216	ok "this repo's .gitignore covers releases.db.bak" \
   217	   "git -C '$ROOT_DIR' check-ignore -q releases.db.bak"
   218	
   219	# ── 7. EDGE CASE: an explicitly empty --root must be refused, not silently retargeted ──────────
   220	# This is here because it actually happened. While writing this suite, `conflicted()` aborted on a
   221	# bash 3.2 `local` quirk and returned "", the call became `--root ""`, the resolver fell back to
   222	# `git rev-parse --show-toplevel`, and it REBUILT THIS REPO'S PRODUCTION LEDGER (generation 6 -> 12;
   223	# recovered from HEAD). "No --root" and "--root with an empty value" are different statements and
   224	# must not share a code path.
   225	echo "-- 7: --root '' is a caller bug, not a request for the current repo"
   226	# Hash-compare, NOT `git status`: a clean-tree assertion also fails whenever the operator simply
   227	# has uncommitted ledger work (found 2026-08-19 with a live roadmap-sync pending), which is a
   228	# false alarm about the resolver. What this scenario owns is only that the CALL changed nothing.
   229	LEDGER_BEFORE="$(shasum -a 256 "$ROOT_DIR/releases.db" "$ROOT_DIR/releases.sql" | awk '{print $1}' | tr '\n' ' ')"
   230	out="$(bash "$RESOLVER" --root "" 2>&1)"; rc=$?
   231	ok "resolver refuses an explicitly empty --root (rc=$rc)" "[ $rc -ne 0 ]"
   232	ok "  and says it will not fall back to the current repository" \
   233	   "has \"\$out\" 'Refusing to fall back'"
   234	ok "  and this repo's ledger is byte-identical after that call" \
   235	   "[ \"\$(shasum -a 256 \"$ROOT_DIR/releases.db\" \"$ROOT_DIR/releases.sql\" | awk '{print \$1}' | tr '\n' ' ')\" = \"$LEDGER_BEFORE\" ]"
   236	
   237	# ── 8. GH-272: adopted derived views are regenerated and staged, not left for hand-regen ────────
   238	# releases.db is not the only artifact a ledger merge stales: ROADMAP-DASHBOARD.md,
   239	# RELEASES-PREVIEW.html, LEADERBOARD.html and LEADERBOARD.md are all rendered from ledger
   240	# state. Until GH-272 the resolver finished with those views still conflicted or stale, and
   241	# the operator regenerated each by hand before `git merge --continue`. A repo that never
   242	# adopted a view must remain a silent no-op (scenario 3's bare fixture already pins that).
   243	echo "-- 8: adopted views are regenerated + staged (GH-272)"
   244	R8="$WORK/c8"
   245	mkdir -p "$R8"
   246	require_fixture "$R8" "views merge fixture"
   247	git -C "$R8" init -q -b main
   248	git -C "$R8" config user.email gh57live@test.invalid
   249	git -C "$R8" config user.name gh57live
   250	ra "$R8" init --slug c8 >/dev/null
   251	printf 'ROADMAP_SOURCE=releases\n' > "$R8/.pdda-mode"
   252	bake_views() {  # <repo> — render every adopted view from that repo's CURRENT ledger
   253	  local r="$1"
   254	  ROADMAP_DASHBOARD_ROOT="$r" bash "$ROOT_DIR/utils/roadmap-dashboard.sh"
   255	  python3 "$ROOT_DIR/utils/timeline/export_timeline.py" --db "$r/releases.db" --preview "$r/RELEASES-PREVIEW.html"
   256	  python3 "$ROOT_DIR/utils/timeline/export_timeline.py" --db "$r/releases.db" --leaderboard "$r/LEADERBOARD.html"
   257	  LEADERBOARD_DB="$r/releases.db" LEADERBOARD_OUTPUT="$r/LEADERBOARD.md" bash "$ROOT_DIR/utils/leaderboard.sh"
   258	}
   259	bake_views "$R8"
   260	V8="ROADMAP-DASHBOARD.md RELEASES-PREVIEW.html LEADERBOARD.html LEADERBOARD.md"
   261	for f in $V8; do ok "fixture adopted $f before the merge" "[ -f '$R8/$f' ]"; done
   262	git -C "$R8" add -A; git -C "$R8" commit -qm base
   263	git -C "$R8" branch side
   264	git -C "$R8" checkout -q side
   265	ra "$R8" add --version 1.0.0 --status draft --description 'side one.' --tracking-issue TMP-SIDE01 >/dev/null
   266	for f in $V8; do printf 'side touched %s\n' "$f" >> "$R8/$f"; done
   267	git -C "$R8" commit -qam side
   268	git -C "$R8" checkout -q main
   269	ra "$R8" add --version 2.0.0 --status draft --description 'main one.' --tracking-issue TMP-MAIN01 >/dev/null
   270	for f in $V8; do printf 'main touched %s\n' "$f" >> "$R8/$f"; done
   271	git -C "$R8" commit -qam main
   272	git -C "$R8" merge side -m merge >/dev/null 2>&1 || true
   273	ok "the adopted views really conflicted (both sides wrote them)" \
   274	   "has \"\$(git -C '$R8' diff --name-only --diff-filter=U)\" 'ROADMAP-DASHBOARD.md'"
   275	resolve_dump "$R8"
   276	out="$(resolver "$R8")"; rc=$?
   277	ok "resolver completes with adopted views in play (rc=$rc)" "[ $rc -eq 0 ]"
   278	ok "  and says it regenerated them" "has \"\$out\" 'regenerating adopted views'"
   279	ok "  and left no unmerged paths (views included)" \
   280	   "[ -z \"\$(git -C '$R8' diff --name-only --diff-filter=U)\" ]"
   281	STAGED="$(git -C "$R8" diff --cached --name-only)"
   282	for f in $V8; do
   283	  ok "  $f is staged resolved" "has \"\$STAGED\" '$f'"
   284	  ok "  $f carries no conflict markers" "[ \"\$(grep -c '^<<<<<<< ' '$R8/$f')\" -eq 0 ]"
   285	  ok "  $f carries neither side's stale touch" "! grep -q 'touched $f' '$R8/$f'"
   286	done
   287	# Idempotence: re-rendering from the resolved ledger reproduces the staged bytes, and the
   288	# dashboard/leaderboard --check modes agree the staged copies are in sync.
   289	ok "staged dashboard matches a fresh render (--check in sync)" \
   290	   "ROADMAP_DASHBOARD_ROOT='$R8' bash '$ROOT_DIR/utils/roadmap-dashboard.sh' --check"
   291	ok "staged LEADERBOARD.md matches a fresh render (--check in sync)" \
   292	   "LEADERBOARD_DB='$R8/releases.db' LEADERBOARD_OUTPUT='$R8/LEADERBOARD.md' bash '$ROOT_DIR/utils/leaderboard.sh' --check"
   293	# The staged preview was rendered from the MERGED ledger, not the stale ours-side: the bake
   294	# embeds the ledger's telemetry, and byte-comparing two bakes is wrong by design (each embeds
   295	# its own generatedAtDisplay timestamp). Ours-side-only would say releasesTotal 1; the merge
   296	# carried both sides' releases, so the regenerated bake must say 2.
   297	ok "staged RELEASES-PREVIEW.html reflects the MERGED ledger (both sides' releases present)" \
   298	   "grep -q '\"releasesTotal\": 2' '$R8/RELEASES-PREVIEW.html'"
   299	
   300	echo
   301	echo "  gh57-live-merge-resolve: $pass pass, $fail fail"
   302	[ "$fail" -eq 0 ]
     1	# Recon Map — LEADERBOARD.md Removal
     2	Commit: current-head · Mode: grep-only · Lanes: A, B, C, D (serial)
     3	
     4	## Subject and change class
     5	Subject: `LEADERBOARD.md`, `LEADERBOARD.html`, and their rendering machinery (`utils/leaderboard.sh`, `utils/timeline/export_timeline.py --leaderboard`).
     6	Change class: Subsystem removal
     7	
     8	## The seams — where a change here escapes this file
     9	| Seam | Location | Crosses | Breaks if |
    10	| --- | --- | --- | --- |
    11	| Merge resolve | `utils/releases-merge-resolve.sh:196-214` | Git conflict resolution | Resolving a merge still tries to invoke the deleted `leaderboard.sh` or `export_timeline.py --leaderboard` |
    12	| Python App Auto-refresh | `utils/py/releases_app.py:1170-1201` | Releases CLI | `releases_app.py` tries to refresh the deleted LEADERBOARD files |
    13	| Automation Pipelines | `utils/py/wave_reconcile.py`, `utils/py/express.py`, `utils/py/jog_run.py` | Automated lane commits | Automation tries to stage a deleted LEADERBOARD file during git commits |
    14	| Tests | `test/gh57-live-merge-resolve.sh` and others | CI/CD | Tests expect `LEADERBOARD.md` to be present and updated |
    15	
    16	## Call paths in
    17	- CLI / Agent writes -> `utils/py/releases_app.py` -> `refresh_preview()` -> calls `utils/leaderboard.sh` to regenerate `LEADERBOARD.md` and `export_timeline.py --leaderboard` to regenerate `LEADERBOARD.html`.
    18	- Git merge conflicts -> `utils/releases-merge-resolve.sh` -> calls `utils/leaderboard.sh` and `export_timeline.py --leaderboard`.
    19	- Automated loops (`wave_reconcile.py`, `express.py`, `jog_run.py`) -> automatically add `LEADERBOARD.md` to commits if it exists.
    20	
    21	## State
    22	- Read sites: Humans and agents reviewing task rankings (e.g., via `LEADERBOARD.md`).
    23	- Write sites: Generated automatically by `utils/leaderboard.sh` and `utils/timeline/export_timeline.py`.
    24	- Source of truth: The score data (pri/sev/appeal/effort) is sourced directly from `releases.db` (`roadmap_items` table). `LEADERBOARD.md` is strictly a derived view.
    25	
    26	## Contracts
    27	- As with `ROADMAP-DASHBOARD.md`, `LEADERBOARD.md` is an "adopted view." `releases_app.py` only refreshes it if the file exists (opt-in by presence). Removing the file means it stops refreshing automatically.
    28	
    29	## Build, failure and rollback today
    30	- Build: Automatically generated via `releases_app.py` after a DB write or during merge resolution.
    31	- Failure: If `utils/leaderboard.sh` is missing, `releases-merge-resolve.sh` will fail and block merge resolution if the file was tracked.
    32	- Rollback: `git revert`
    33	
    34	## Unknowns
    35	| Unknown | Why it matters | What would settle it |
    36	| --- | --- | --- |
    37	| Do any downstream external tools rely on `LEADERBOARD.html`? | If it's served statically to a team dashboard, removing it will cause a 404. | Search for org/repo deployments of `LEADERBOARD.html` |
    38	
    39	## Current-state radius, one line
    40	Releases CLI auto-refresh (`releases_app.py`), merge resolution (`releases-merge-resolve.sh`), Python automation staging loops (`wave_reconcile.py`, `express.py`, `jog_run.py`), and downstream docs.

exec
/bin/zsh -lc "nl -ba test/gh153-releases-sidebar-rollup.sh | sed -n '85,190p'; nl -ba test/gh267-express-skill.sh | sed -n '105,175p'; nl -ba test/gh267-express-skill.sh | sed -n '215,250p'; nl -ba test/gh57-live-merge-resolve.sh | sed -n '230,305p'; nl -ba test/gh103-timeline-exporter.sh | sed -n '185,245p'; rg -n -C 3 'run_subprocesses\\(' utils/py/wave_reconcile.py; rg -n -C 3 'refresh_preview\\(' utils/py/releases_app.py; rg -n -C 3 'driver_projection_paths' utils/py/express.py" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej
 succeeded in 0ms:
    85	
    86	printf 'definitely not a sqlite database\n' > "$WORK/corrupt.db"
    87	"$CYCLE" --db "$WORK/corrupt.db" >/dev/null 2>"$WORK/corrupt.err"
    88	rc=$?
    89	[ "$rc" -eq 2 ] && pass "corrupt DB -> exit 2" || fail "corrupt DB -> rc=$rc (want 2)"
    90	grep -q "releases_cycle:" "$WORK/corrupt.err" \
    91	  && pass "corrupt DB explains itself on stderr" || fail "corrupt DB stderr silent"
    92	rm -f "$WORK/corrupt.db"
    93	
    94	echo "-- exporter: additive payload keys --"
    95	EXPORT_JSON="$(python3 "$EXPORTER" --db "$DB" --json)"
    96	rc=$?
    97	[ "$rc" -eq 0 ] && pass "exporter --json exits 0 with the cycle import in place" \
    98	  || fail "exporter --json rc=$rc"
    99	if python3 - "$EXPORT_JSON" <<'PY'
   100	import json, sys
   101	d = json.loads(sys.argv[1])
   102	assert "cycle" in d and "projects" in d, sorted(d)
   103	assert d["meta"]["repoUrl"] and d["meta"]["repoUrl"].startswith("https://github.com/")
   104	assert any(p["slug"] == "XYZ-forge" and p["active"] for p in d["projects"]), d["projects"]
   105	assert d["cycle"]["releases"]["total"] >= 1
   106	PY
   107	then pass "payload carries projects + cycle + meta.repoUrl, values sane"
   108	else fail "payload keys missing/wrong (see python traceback above)"
   109	fi
   110	
   111	echo "-- exporter: sidebar chrome baked into BOTH artifacts from the one template --"
   112	PREVIEW="$WORK/RELEASES-PREVIEW.html"
   113	LEADER="$WORK/LEADERBOARD.html"
   114	python3 "$EXPORTER" --db "$DB" --preview "$PREVIEW" >/dev/null \
   115	  && pass "preview bake exits 0" || fail "preview bake failed"
   116	python3 "$EXPORTER" --db "$DB" --leaderboard "$LEADER" >/dev/null \
   117	  && pass "leaderboard bake exits 0" || fail "leaderboard bake failed"
   118	require_fixture_file "$PREVIEW" "baked preview"
   119	require_fixture_file "$LEADER" "baked leaderboard"
   120	
   121	MARKERS=('id="sidenav-toggle"'      # hamburger — the slideout control
   122	         'id="sidenav"'             # the nav itself
   123	         'id="sn-project"'          # project switcher
   124	         'id="sn-min"'              # minimize-to-rail chevron
   125	         'data-snfocus="rel"'       # focus items wired to the #fbar buttons
   126	         'class="sn-item sn-ph"'    # NON-LINK placeholders (no fake hrefs)
   127	         '__snCycle'                # boot()-side hook filling the panel
   128	         'data-sn="expanded"'       # default ON
   129	         'id="ledger-data"')        # the pre-existing inline payload survives the injection
   130	for f in "$PREVIEW" "$LEADER"; do
   131	  fname="$(basename "$f")"
   132	  for m in "${MARKERS[@]}"; do
   133	    grep -q "$m" "$f" \
   134	      && pass "$fname: $m" \
   135	      || fail "$fname: MISSING $m"
   136	  done
   137	done
   138	
   139	echo "-- template: states + placeholders are source-level facts --"
   140	for pat in 'body\[data-sn="rail"\]' 'body\[data-sn="hidden"\]' 'placeholder — no destination yet' \
   141	           'localStorage.setItem(KEY,state)' 'window.__snCycle=function(data)'; do
   142	  grep -q "$pat" "$TEMPLATE" \
   143	    && pass "template carries: $pat" \
   144	    || fail "template missing: $pat"
   145	done
   146	
   147	echo "== gh153-releases-sidebar-rollup: $PASS passed, $FAIL failed =="
   148	[ "$FAIL" -eq 0 ]
   105	printf '# suite that replaces the untracked git-metadata hook\nprintf "#!/bin/sh\\nexit 0\\n" > .git/hooks/pre-push\nchmod +x .git/hooks/pre-push\n' > "$FX/test/gh999-hook-drift.sh"
   106	printf '# unregistered suite\n' > "$FX/test/gh999b-unreg.sh"
   107	# Use the real installer contract with a tiny fixture gate. A foreign executable
   108	# hook must not satisfy `install.sh --check`.
   109	cp "$HERE/../githooks/install.sh" "$FX/githooks/install.sh"
   110	printf '#!/usr/bin/env bash\nexit 0\n' > "$FX/githooks/pre-push"
   111	chmod +x "$FX/githooks/install.sh" "$FX/githooks/pre-push"
   112	
   113	# Faithful write-surface stub: every mutating releases verb changes the DB/dump
   114	# and every adopted projection that production refresh_preview owns.
   115	cat > "$FX/utils/py/releases_app.py" <<'RA'
   116	#!/usr/bin/env python3
   117	import os, sqlite3, sys
   118	a = sys.argv[1:]
   119	if a[:1] == ["next"]:
   120	    print("NEXT: stub gid=rel-STUB000000000000000000000008")
   121	if a[:2] in (["roadmap", "add"], ["manifest", "dial-in"], ["manifest", "ship"]):
   122	    c = sqlite3.connect("releases.db")
   123	    c.execute("CREATE TABLE IF NOT EXISTS fixture_writes (id INTEGER PRIMARY KEY, verb TEXT)")
   124	    c.execute("INSERT INTO fixture_writes(verb) VALUES (?)", (" ".join(a[:2]),))
   125	    c.commit(); c.close()
   126	    for name in ("releases.sql", "RELEASES.generated.md", "RELEASES-PREVIEW.html",
   127	                 "LEADERBOARD.html", "LEADERBOARD.md"):
   128	        with open(name, "a", encoding="utf-8") as f:
   129	            f.write("stub-release-write: %s\n" % " ".join(a[:2]))
   130	print("stub-releases:", " ".join(a[:2]))
   131	RA
   132	cat > "$FX/utils/py/wave_reconcile.py" <<'WR'
   133	#!/usr/bin/env python3
   134	import os, subprocess, sys
   135	if os.environ.get("WR_FAIL") == "1":
   136	    print("forced reconcile failure", file=sys.stderr); sys.exit(9)
   137	if subprocess.run(["git", "status", "--porcelain"], capture_output=True, text=True).stdout.strip():
   138	    print("reconcile requires a clean tree", file=sys.stderr); sys.exit(8)
   139	if subprocess.run(["git", "branch", "--show-current"], capture_output=True, text=True).stdout.strip() != "development":
   140	    print("reconcile requires development", file=sys.stderr); sys.exit(7)
   141	src = "PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md"
   142	dst = "PROJECT/3-COMPLETED/GH-999-DEMO-HOTFIX.md"
   143	if os.path.exists(src):
   144	    os.makedirs(os.path.dirname(dst), exist_ok=True)
   145	    os.replace(src, dst)
   146	WR
   147	cat > "$FX/utils/roadmap-dashboard.sh" <<'RD'
   148	#!/usr/bin/env bash
   149	printf 'stub-dashboard-refresh\n' >> ROADMAP-DASHBOARD.md
   150	RD
   151	chmod +x "$FX/utils/roadmap-dashboard.sh"
   152	python3 -c "import sqlite3; c=sqlite3.connect('$FX/releases.db'); c.execute('CREATE TABLE IF NOT EXISTS roadmap_items (global_id TEXT, gh_number INTEGER)'); c.commit(); c.close()"
   153	printf 'base dump\n' > "$FX/releases.sql"
   154	for projection in RELEASES.generated.md RELEASES-PREVIEW.html LEADERBOARD.html LEADERBOARD.md ROADMAP-DASHBOARD.md; do
   155	  printf 'base projection\n' > "$FX/$projection"
   156	done
   157	printf '# Changelog\n\nAll notable changes.\n\n## [Unreleased] - 2026-01-01\n\n### Fixed\n- old entry\n' > "$FX/CHANGELOG.md"
   158	git -C "$FX" add -A && git -C "$FX" commit -qm base
   159	git -C "$FX" branch -m development
   160	git -C "$FX" push -q origin development
   161	git -C "$FX" fetch -q origin
   162	(cd "$FX" && bash githooks/install.sh) >/dev/null
   163	require_fixture "$FX"
   164	require_fixture "$REMOTE"
   165	echo "fixture ready"
   166	
   167	new_task_branch() {
   168	  # reset to a pristine task branch: discard tracked mods, untracked files, and
   169	  # any stray commits, so each case starts from the exact base state
   170	  require_fixture "$FX"
   171	  git -C "$FX" checkout -q development
   172	  git -C "$FX" reset -q --hard origin/development
   173	  git -C "$FX" clean -fdq
   174	  git -C "$FX" checkout -q -B task/gh-999 origin/development
   175	  # The production prerequisite is per clone; restore the canonical fixture
   215	run_check > /dev/null 2> "$ERR" && bad "5 files must refuse" || { check_rule too-many-files "$ERR" && ok "too-many-files refusal" || bad "too-many-files rule"; }
   216	
   217	new_task_branch; printf 'x\n' >> "$FX/utils/py/foo.py"
   218	run_check 999 test/gh999b-unreg.sh > /dev/null 2> "$ERR" && bad "unregistered suite must refuse" || { check_rule suite-unregistered "$ERR" && ok "suite-unregistered refusal" || bad "suite-unregistered rule"; }
   219	
   220	new_task_branch; printf 'x\n' >> "$FX/utils/py/foo.py"
   221	run_check 888 > /dev/null 2> "$ERR" && bad "closed issue must refuse" || { check_rule issue-closed "$ERR" && ok "issue-closed refusal (already-landed guard)" || bad "issue-closed rule"; }
   222	
   223	new_task_branch; printf 'x\n' >> "$FX/utils/py/foo.py"; rm -f "$FX/.git/hooks/pre-push"
   224	run_check > /dev/null 2> "$ERR" && bad "unwired gate must refuse" || { check_rule gate-unwired "$ERR" && ok "gate-unwired refusal (finding 3: hooks do not travel)" || bad "gate-unwired rule"; }
   225	printf '#!/bin/sh\nexit 0\n' > "$FX/.git/hooks/pre-push" && chmod +x "$FX/.git/hooks/pre-push"
   226	run_check > /dev/null 2> "$ERR" && bad "foreign no-op hook must not prove the gate" || { check_rule gate-unwired "$ERR" && ok "gate-unwired rejects an executable no-op impostor" || bad "gate identity rule"; }
   227	rm -f "$FX/.git/hooks/pre-push" && (cd "$FX" && bash githooks/install.sh) >/dev/null
   228	
   229	new_task_branch; printf 'x\n' >> "$FX/utils/py/foo.py"; printf 'hand edit\n' > "$FX/releases.sql"
   230	run_check > /dev/null 2> "$ERR" && bad "hand-edited ledger must refuse" || { check_rule ledger-hand-edit "$ERR" && ok "ledger-hand-edit refusal (verbs only)" || bad "ledger-hand-edit rule"; }
   231	
   232	new_task_branch; printf 'x\n' >> "$FX/utils/py/foo.py"; printf 'hand edit\n' > "$FX/RELEASES-PREVIEW.html"
   233	run_check > /dev/null 2> "$ERR" && bad "hand-edited generated view must refuse" || { check_rule driver-output-hand-edit "$ERR" && ok "driver-output-hand-edit refusal (generated views are verb-owned)" || bad "driver-output-hand-edit rule"; }
   234	
   235	echo "== happy path =="
   236	new_task_branch; printf 'fixed\n' > "$FX/utils/py/foo.py"; printf '# demo suite v2\n' > "$FX/test/gh999-demo.sh"
   237	OUT="$(run_check 999)"
   238	grep -q "express-check: PASS" <<<"$OUT" && ok "legal fix passes" || bad "legal fix refused: $OUT"
   239	
   240	new_task_branch; printf 'fixed\n' > "$FX/utils/py/foo.py"; for i in 1 2 3; do printf 'x\n' > "$FX/utils/py/g$i.py"; done; printf 'doc edit\n' > "$FX/README.md"
   241	run_check > /dev/null 2> "$ERR" && bad "README must count against the file bound (finding 5)" || { check_rule too-many-files "$ERR" && ok "operator .md edits COUNT against the bound (finding 5)" || bad "README exempted: $(tail -1 "$ERR")"; }
   242	
   243	new_task_branch; printf 'fixed\n' > "$FX/utils/py/foo.py"; printf 'entry\n' >> "$FX/CHANGELOG.md"
   244	run_check > /dev/null 2> "$ERR" && ok "the lane's own paperwork (CHANGELOG) stays exempt" || bad "CHANGELOG counted against bounds: $(tail -1 "$ERR")"
   245	
   246	echo "== docs born complete =="
   247	python3 "$DRIVER" --root "$FX" docs --issue 999 --suite test/gh999-demo.sh --summary "demo" >/dev/null 2>"$ERR" || bad "docs scaffold failed: $(cat "$ERR")"
   248	DOC="$FX/PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md"
   249	[ -f "$DOC" ] && ok "capture doc created" || bad "capture doc missing"
   250	grep -q "## Lessons Learned (For Future Agents)" "$DOC" 2>/dev/null && ok "Lessons Learned present from birth (GH-232 gate)" || bad "doc not born complete"
   230	out="$(bash "$RESOLVER" --root "" 2>&1)"; rc=$?
   231	ok "resolver refuses an explicitly empty --root (rc=$rc)" "[ $rc -ne 0 ]"
   232	ok "  and says it will not fall back to the current repository" \
   233	   "has \"\$out\" 'Refusing to fall back'"
   234	ok "  and this repo's ledger is byte-identical after that call" \
   235	   "[ \"\$(shasum -a 256 \"$ROOT_DIR/releases.db\" \"$ROOT_DIR/releases.sql\" | awk '{print \$1}' | tr '\n' ' ')\" = \"$LEDGER_BEFORE\" ]"
   236	
   237	# ── 8. GH-272: adopted derived views are regenerated and staged, not left for hand-regen ────────
   238	# releases.db is not the only artifact a ledger merge stales: ROADMAP-DASHBOARD.md,
   239	# RELEASES-PREVIEW.html, LEADERBOARD.html and LEADERBOARD.md are all rendered from ledger
   240	# state. Until GH-272 the resolver finished with those views still conflicted or stale, and
   241	# the operator regenerated each by hand before `git merge --continue`. A repo that never
   242	# adopted a view must remain a silent no-op (scenario 3's bare fixture already pins that).
   243	echo "-- 8: adopted views are regenerated + staged (GH-272)"
   244	R8="$WORK/c8"
   245	mkdir -p "$R8"
   246	require_fixture "$R8" "views merge fixture"
   247	git -C "$R8" init -q -b main
   248	git -C "$R8" config user.email gh57live@test.invalid
   249	git -C "$R8" config user.name gh57live
   250	ra "$R8" init --slug c8 >/dev/null
   251	printf 'ROADMAP_SOURCE=releases\n' > "$R8/.pdda-mode"
   252	bake_views() {  # <repo> — render every adopted view from that repo's CURRENT ledger
   253	  local r="$1"
   254	  ROADMAP_DASHBOARD_ROOT="$r" bash "$ROOT_DIR/utils/roadmap-dashboard.sh"
   255	  python3 "$ROOT_DIR/utils/timeline/export_timeline.py" --db "$r/releases.db" --preview "$r/RELEASES-PREVIEW.html"
   256	  python3 "$ROOT_DIR/utils/timeline/export_timeline.py" --db "$r/releases.db" --leaderboard "$r/LEADERBOARD.html"
   257	  LEADERBOARD_DB="$r/releases.db" LEADERBOARD_OUTPUT="$r/LEADERBOARD.md" bash "$ROOT_DIR/utils/leaderboard.sh"
   258	}
   259	bake_views "$R8"
   260	V8="ROADMAP-DASHBOARD.md RELEASES-PREVIEW.html LEADERBOARD.html LEADERBOARD.md"
   261	for f in $V8; do ok "fixture adopted $f before the merge" "[ -f '$R8/$f' ]"; done
   262	git -C "$R8" add -A; git -C "$R8" commit -qm base
   263	git -C "$R8" branch side
   264	git -C "$R8" checkout -q side
   265	ra "$R8" add --version 1.0.0 --status draft --description 'side one.' --tracking-issue TMP-SIDE01 >/dev/null
   266	for f in $V8; do printf 'side touched %s\n' "$f" >> "$R8/$f"; done
   267	git -C "$R8" commit -qam side
   268	git -C "$R8" checkout -q main
   269	ra "$R8" add --version 2.0.0 --status draft --description 'main one.' --tracking-issue TMP-MAIN01 >/dev/null
   270	for f in $V8; do printf 'main touched %s\n' "$f" >> "$R8/$f"; done
   271	git -C "$R8" commit -qam main
   272	git -C "$R8" merge side -m merge >/dev/null 2>&1 || true
   273	ok "the adopted views really conflicted (both sides wrote them)" \
   274	   "has \"\$(git -C '$R8' diff --name-only --diff-filter=U)\" 'ROADMAP-DASHBOARD.md'"
   275	resolve_dump "$R8"
   276	out="$(resolver "$R8")"; rc=$?
   277	ok "resolver completes with adopted views in play (rc=$rc)" "[ $rc -eq 0 ]"
   278	ok "  and says it regenerated them" "has \"\$out\" 'regenerating adopted views'"
   279	ok "  and left no unmerged paths (views included)" \
   280	   "[ -z \"\$(git -C '$R8' diff --name-only --diff-filter=U)\" ]"
   281	STAGED="$(git -C "$R8" diff --cached --name-only)"
   282	for f in $V8; do
   283	  ok "  $f is staged resolved" "has \"\$STAGED\" '$f'"
   284	  ok "  $f carries no conflict markers" "[ \"\$(grep -c '^<<<<<<< ' '$R8/$f')\" -eq 0 ]"
   285	  ok "  $f carries neither side's stale touch" "! grep -q 'touched $f' '$R8/$f'"
   286	done
   287	# Idempotence: re-rendering from the resolved ledger reproduces the staged bytes, and the
   288	# dashboard/leaderboard --check modes agree the staged copies are in sync.
   289	ok "staged dashboard matches a fresh render (--check in sync)" \
   290	   "ROADMAP_DASHBOARD_ROOT='$R8' bash '$ROOT_DIR/utils/roadmap-dashboard.sh' --check"
   291	ok "staged LEADERBOARD.md matches a fresh render (--check in sync)" \
   292	   "LEADERBOARD_DB='$R8/releases.db' LEADERBOARD_OUTPUT='$R8/LEADERBOARD.md' bash '$ROOT_DIR/utils/leaderboard.sh' --check"
   293	# The staged preview was rendered from the MERGED ledger, not the stale ours-side: the bake
   294	# embeds the ledger's telemetry, and byte-comparing two bakes is wrong by design (each embeds
   295	# its own generatedAtDisplay timestamp). Ours-side-only would say releasesTotal 1; the merge
   296	# carried both sides' releases, so the regenerated bake must say 2.
   297	ok "staged RELEASES-PREVIEW.html reflects the MERGED ledger (both sides' releases present)" \
   298	   "grep -q '\"releasesTotal\": 2' '$R8/RELEASES-PREVIEW.html'"
   299	
   300	echo
   301	echo "  gh57-live-merge-resolve: $pass pass, $fail fail"
   302	[ "$fail" -eq 0 ]
   185	# ── the viewer template agrees with the data it is handed ───────────────────────────────────────
   186	echo "-- the template renders what the exporter emits"
   187	TPL="$(cat "$TEMPLATE")"
   188	N="$(printf '%s' "$TPL" | grep -c "\['pri','sev','appeal','effort','calc'\]")"
   189	ok "BOTH metric loops (card renderer and what's-next strip) carry appeal and effort" "$(is "$N" "2"; echo $?)"
   190	if has "$TPL" "100 = strongest" && ! has "$TPL" "1 = strongest"; then ok "the footer legend reads 100 = strongest — legend and data never disagree in a committed artifact" 0; else ok "legend flipped" 1; fi
   191	if has "$TPL" "rel.baseline"; then ok "the release node renders the baseline/growth pair" 0; else ok "baseline rendered" 1; fi
   192	
   193	# ── read-only: the page is a pure consumer ──────────────────────────────────────────────────────
   194	echo "-- read-only contract"
   195	DB_HASH="$(file_hash "$R/releases.db")"; DUMP_HASH="$(file_hash "$R/releases.sql")"
   196	python3 "$EXPORTER" --db "$R/releases.db" --preview "$WORK/preview.html" >/dev/null 2>&1
   197	if [ -s "$WORK/preview.html" ] && grep -q 'id="ledger-data"' "$WORK/preview.html"; then ok "--preview bakes a self-contained page with the payload inline" 0; else ok "preview bakes" 1; fi
   198	if [ -n "$DB_HASH" ] && [ "$(file_hash "$R/releases.db")" = "$DB_HASH" ] && [ "$(file_hash "$R/releases.sql")" = "$DUMP_HASH" ]; then ok "the exporter wrote no DB bytes (opened read-only; the page never writes back)" 0; else ok "exporter read-only" 1; fi
   199	if ra check >/dev/null 2>&1; then ok "the ledger still checks clean after every projection" 0; else ok "check clean" 1; fi
   200	
   201	# ── the leaderboard pipeline (GH-108 Phase D) ───────────────────────────────────────────────────
   202	# ONE SCORER, proven rather than asserted: the shell script's ranking must match the exporter's
   203	# `--json` ordering exactly. A script that re-derived calc or reapplied the override rule would be
   204	# the same drift class the "calc is never stored" rule prevents, one layer up.
   205	echo "-- the leaderboard pipeline"
   206	LB_MD="$WORK/LEADERBOARD.md"
   207	LEADERBOARD_DB="$R/releases.db" LEADERBOARD_OUTPUT="$LB_MD" bash "$HERE/../utils/leaderboard.sh" >/dev/null 2>&1
   208	ok "leaderboard.sh renders LEADERBOARD.md from the exporter's JSON" "$([ -s "$LB_MD" ]; echo $?)"
   209	if grep -q 'GENERATED' <<<"$(head -1 "$LB_MD")"; then ok "the file announces itself as generated (never hand-edited)" 0; else ok "generated header" 1; fi
   210	# POSIX sed rather than `rg`: ripgrep is not a documented prerequisite (README lists Codex CLI, agy
   211	# CLI, Node 18+, git, Python 3.8+) and this suite was the only thing in test/ or utils/ that needed
   212	# it, so the whole suite failed on any host without it. Handles both the linked `[GH-n](url)` and
   213	# bare `GH-n` row forms, same as the regex it replaces.
   214	SCRIPT_ORDER="$(sed -n 's/^| [0-9][0-9]* | \*\*[0-9][0-9]*\*\* | \[\{0,1\}\(GH-[0-9][0-9]*\).*/\1/p' "$LB_MD" | tr '\n' ' ' | sed 's/ $//')"
   215	ok "the script's ranking matches the pinned --json ordering EXACTLY (one scorer, proven)" \
   216	   "$(is "$SCRIPT_ORDER" "$(printf '%s' "$TOP" | sed 's/:[0-9]*//g')"; echo $?)"
   217	if grep -q 'Top of the line:\*\* GH-805' "$LB_MD"; then ok "the highest-scoring task is called out by name, override included" 0; else ok "top of the line" 1; fi
   218	if grep -q 'GH-900' "$LB_MD"; then ok "a rated DETOUR ranks too — not just manifest cards" 0; else ok "detour ranks" 1; fi
   219	CP="$WORK/lb-first.md"; cp "$LB_MD" "$CP"
   220	LEADERBOARD_DB="$R/releases.db" LEADERBOARD_OUTPUT="$LB_MD" bash "$HERE/../utils/leaderboard.sh" >/dev/null 2>&1
   221	ok "regeneration is idempotent — a second run is byte-identical" "$(cmp -s "$CP" "$LB_MD"; echo $?)"
   222	LEADERBOARD_DB="$R/releases.db" LEADERBOARD_OUTPUT="$LB_MD" bash "$HERE/../utils/leaderboard.sh" --check >/dev/null 2>&1
   223	ok "--check passes when the committed copy is in sync" "$?"
   224	printf '\nstale hand edit\n' >> "$LB_MD"
   225	LEADERBOARD_DB="$R/releases.db" LEADERBOARD_OUTPUT="$LB_MD" bash "$HERE/../utils/leaderboard.sh" --check >/dev/null 2>&1
   226	ok "--check FAILS on drift (a stale checked-in copy is a review signal)" "$([ $? -ne 0 ]; echo $?)"
   227	
   228	LB_HTML="$WORK/LEADERBOARD.html"
   229	python3 "$EXPORTER" --db "$R/releases.db" --leaderboard "$LB_HTML" >/dev/null 2>&1
   230	ok "--leaderboard bakes a self-contained page from the SAME template" "$([ -s "$LB_HTML" ]; echo $?)"
   231	if grep -q '"view": *"leaderboard"\|"view":"leaderboard"' "$LB_HTML"; then ok "the payload carries view=leaderboard — one template, two baked artifacts" 0; else ok "view field" 1; fi
   232	if grep -q 'leaderboardHTML' "$WORK/preview.html" && grep -q 'columnHTML' "$LB_HTML"; then ok "both artifacts share ONE renderer bundle (no second copy of the design system)" 0; else ok "shared bundle" 1; fi
   233	if grep -q 'id="view-link"' "$TEMPLATE"; then ok "the cross-link lives in .top, which never collapses" 0; else ok "cross-link placement" 1; fi
   234	# grep -E rather than `rg` (see the SCRIPT_ORDER note above). This assertion is negated, so with
   235	# ripgrep absent `rg -q` returned 127 and the test passed without checking anything.
   236	if ! grep -qE 'id="fbar"[^>]*>[^<]*<a id="view-link"' "$TEMPLATE"; then ok "and NOT in #fbar, which disappears with the header caret" 0; else ok "cross-link not in fbar" 1; fi
   237	# The leaderboard view never calls initInteractions(), so #fbar's search + focus + prev/next are
   238	# all inert there — a search box that looks broken (aider/qwen3.8-max QA r1).
   239	if grep -q 'body\[data-view="leaderboard"\] #fbar' "$TEMPLATE"; then ok "the leaderboard view hides #fbar rather than shipping an inert search box" 0; else ok "leaderboard hides fbar" 1; fi
   240	
   241	# ── GH-250: codename-only releases (version NULL) must not crash the bake ───────────────────────
   242	# `releases add` accepts a codename with no version, and release_columns() already fell back to
   243	# the codename for slug/name — but not for id, and _ver() only caught ValueError. So ONE
   244	# NULL-version row killed --preview and --leaderboard outright, and refresh_preview()'s warn-only
   245	# path turned that into artifacts that silently stop tracking the ledger. The versioned-no-target
707-        log(f"    - {describe_finding(finding)}")
708-
709-
710:def run_subprocesses(repo_root, dry_run=False, journal=None, reconciled_issues=None):
711-    """Orchestrate releases sync, view exports, and marathon replanning with DB rollback protection."""
712-    log("Running downstream database sync and dashboard regeneration...")
713-
--
1037-            fix_mangled_roadmap_entries(repo_root, dry_run=args.dry_run, journal=journal)
1038-
1039-            # Subprocess orchestration
1040:            run_subprocesses(
1041-                repo_root,
1042-                dry_run=args.dry_run,
1043-                journal=journal,
1160-
1161-# ── the writer protocol (PRD Git story 2-3): journal -> txn -> stage -> rename -> clear ─────────
1162-
1163:def refresh_preview(root):
1164-    """GH-106: after a successful write, refresh the baked viewer artifacts — but only the ones
1165-    the repo has ADOPTED (the file already exists at root; presence is the opt-in signal, so
1166-    fixtures and non-adopting repos are silent no-ops). Best-effort by design: the write is
--
1282-        _crash("post-rename")
1283-
1284-        os.unlink(lock.journal_path)
1285:        refresh_preview(root)  # GH-106: adoption-gated, best-effort — after full durability
1286-        return txn_id
1287-    finally:
1288-        lock.release()
--
1394-                _crash("mid-rename")
1395-        _crash("post-rename")
1396-        os.unlink(lock.journal_path)
1397:        refresh_preview(root)
1398-        print("migrated %s to schema version %d (applied %s; generation %d)"
1399-              % (DB_NAME, max(pending), ", ".join(str(v) for v in pending), generation))
1400-        return txn_id
199-    return {p: path_fingerprint(os.path.join(root, p)) for p in paths}
200-
201-
202:def driver_projection_paths(root):
203-    paths = set(DRIVER_LEDGER)
204-    paths.update(p for p in RELEASES_PROJECTIONS if os.path.lexists(os.path.join(root, p)))
205-    if os.path.isfile(os.path.join(root, "utils", "roadmap-dashboard.sh")):
--
719-    form: check / docs / ledger / land, each its own process) has no other way
720-    to learn what an earlier standalone `docs`/`ledger` step wrote, so `cmd_land`
721-    falls back to recomputing the same set itself (GH-278 review finding)."""
722:    paths = {"CHANGELOG.md"} | driver_projection_paths(root)
723-    doc = capture_doc_path(root, issue)
724-    if doc:
725-        paths.add(doc)

codex
I found a material exception to the proposed premise: the post-merge reconciler invokes `export_timeline.py --preview` without checking for an existing root artifact, so it will recreate `RELEASES-PREVIEW.html`. I’m checking the governance/CI/vendor surface now to distinguish that operational issue from any publication or routing requirement.
exec
/bin/zsh -lc "rg -n -i -C 2 'LEADERBOARD\\.html|RELEASES-PREVIEW\\.html|LEADERBOARD|RELEASES-PREVIEW' ROUTER.md AGENTS.md GUIDING-PRINCIPLES.md README.md .github/workflows relay-automation/xyz-vendor.sh relay-automation/xyz-sync.sh utils/py/router_audit.py skills || true; nl -ba ROUTER.md | sed -n '1,240p'; nl -ba GUIDING-PRINCIPLES.md | sed -n '60,90p'; nl -ba AGENTS.md | sed -n '130,150p'; nl -ba utils/py/router_audit.py | sed -n '1,280p'; nl -ba test/gh353-vendored-router-audit.sh | sed -n '1,240p'; rg -n -i 'pages|publish|serve|http.server|LEADERBOARD\\.html|RELEASES-PREVIEW\\.html' .github/workflows relay-automation/xyz-vendor.sh relay-automation/xyz-sync.sh utils/py/router_audit.py ROUTER.md AGENTS.md GUIDING-PRINCIPLES.md README.md skills || true" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej
 succeeded in 24ms:
skills/agent-chorus/README.md:13:> first and are published one way into the standalone repository. Project website:
skills/agent-chorus/README.md:69:clause is what makes every harness load the skill; a bare "Join…" line was observed to be answered as
skills/agent-chorus/README.md:84:or delete them automatically. A future migration tool must preserve each raw conversation rather
skills/agent-chorus/README.md:108:## Publish the standalone distribution
skills/agent-chorus/README.md:110:XYZ Forge is canonical. `publish-manifest.tsv` declares every file shipped to the standalone
skills/agent-chorus/README.md:112:then publish only from a clean committed canonical revision:
skills/agent-chorus/README.md:120:Set `AGENT2AGENT_STANDALONE_REPO` to select another checkout. The publisher refuses undeclared
skills/agent-chorus/README.md:121:tracked destination files, preserves declared executable modes, verifies byte parity, and records
skills/agent-chorus/SKILL.md:107:observed results. Do not put secrets, credentials, or unrelated conversation into the packet. Write
skills/agent-chorus/SKILL.md:161:doorbell marker. `not observed/manual` means only that no watch sidecar exists; it is not evidence
skills/agent-chorus/SKILL.md:475:  operator answers. Observed incident: the operator's keyboard macro accidentally pasted an
skills/agent-chorus/test-standalone.sh:94:Does the package preserve its documented contract?
skills/agent-chorus/test-standalone.sh:397:Every helper-owned state transition was observed.
skills/agent-chorus/test-standalone.sh:449:[ "$?" -ne 0 ] && pass "discussion IDs are reserved across the whole store" \
skills/agent-chorus/standalone/README.md:54:- [`publish-manifest.tsv`](skills/agent-chorus/publish-manifest.tsv) — declared canonical publishing surface
skills/agent-chorus/standalone/README.md:61:then be published one way into this repository.
skills/rpr/SKILL.md:65:Use the bundled `write_rules.py` rather than hand-editing JSON — it preserves existing
skills/agent-chorus/scripts/agent_chorus_client.py:219:    parser.add_argument("--url", default="http://127.0.0.1:8080", help="Bridge server URL (default: http://127.0.0.1:8080)")
skills/agent-chorus/scripts/agent_chorus_bridge.py:16:import http.server
skills/agent-chorus/scripts/agent_chorus_bridge.py:23:import socketserver
skills/agent-chorus/scripts/agent_chorus_bridge.py:267:class ThreadingHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
skills/agent-chorus/scripts/agent_chorus_bridge.py:272:class BridgeRequestHandler(http.server.BaseHTTPRequestHandler):
skills/agent-chorus/scripts/agent_chorus_bridge.py:275:    server: ThreadingHTTPServer
skills/agent-chorus/scripts/agent_chorus_bridge.py:279:        return getattr(self.server, "bridge_manager")
skills/agent-chorus/scripts/agent_chorus_bridge.py:307:            self.log_message("Internal server error: %s", exc)
skills/agent-chorus/scripts/agent_chorus_bridge.py:308:            self._send_json(500, {"error": "internal server error", "code": "internal_error"})
skills/agent-chorus/scripts/agent_chorus_bridge.py:720:def start_bridge_server(
skills/agent-chorus/scripts/agent_chorus_bridge.py:729:) -> Tuple[ThreadingHTTPServer, int]:
skills/agent-chorus/scripts/agent_chorus_bridge.py:730:    """Start the bridge server in a background thread or return the server instance."""
skills/agent-chorus/scripts/agent_chorus_bridge.py:744:    server = ThreadingHTTPServer((host, port), BridgeRequestHandler)
skills/agent-chorus/scripts/agent_chorus_bridge.py:745:    # GH-384 review (Qwen Q6): ThreadingHTTPServer with no socket timeout means a slow header
skills/agent-chorus/scripts/agent_chorus_bridge.py:750:    server.timeout = REQUEST_SOCKET_TIMEOUT
skills/agent-chorus/scripts/agent_chorus_bridge.py:751:    setattr(server, "bridge_manager", manager)
skills/agent-chorus/scripts/agent_chorus_bridge.py:752:    actual_port = server.server_address[1]
skills/agent-chorus/scripts/agent_chorus_bridge.py:753:    return server, actual_port
skills/agent-chorus/scripts/agent_chorus_bridge.py:805:        help="Publish the tunnel with NO authentication. Every endpoint becomes world-readable "
skills/agent-chorus/scripts/agent_chorus_bridge.py:813:    server, actual_port = start_bridge_server(
skills/agent-chorus/scripts/agent_chorus_bridge.py:828:    manager = getattr(server, "bridge_manager", None)
skills/agent-chorus/scripts/agent_chorus_bridge.py:852:        server.server_close()
skills/agent-chorus/scripts/agent_chorus_bridge.py:884:        server.serve_forever()
skills/agent-chorus/scripts/agent_chorus_bridge.py:886:        server.server_close()
skills/agent-chorus/scripts/agent_chorus.py:932:            """Materialize the reserved ID into a readable discussion. Extracted so the supersede
skills/agent-chorus/scripts/agent_chorus.py:996:                    # leaves nothing behind but the reserved directory it always did.
skills/agent-chorus/scripts/agent_chorus.py:1343:    """Describe a seat's observed doorbell state, or None when it may be participating manually."""
skills/agent-chorus/scripts/agent_chorus.py:1350:            return f"ACTIVE — owns NEXT{duration}; heartbeat not observed/manual"
skills/agent-chorus/scripts/agent_chorus.py:1367:    """One advisory peer line, or None when no doorbell has been observed for that seat."""
skills/agent-chorus/scripts/agent_chorus.py:1425:        print(f"DOORBELL {member}: {state or 'not observed/manual'}")
skills/agent-chorus/scripts/agent_chorus.py:2526:            server, actual_port = agent_chorus_bridge.start_bridge_server(
skills/agent-chorus/scripts/agent_chorus.py:2560:                server.serve_forever()
skills/agent-chorus/scripts/agent_chorus.py:2562:                server.server_close()
skills/rpr/tests/run_tests.py:212:    check("write: special chars (quotes/parens) preserved verbatim",
skills/browserbase/reference/onboarding-guide.md:40:> - **Stagehand** — Browserbase's open-source framework for driving the browser with natural language (`act` / `extract` / `observe`) instead of brittle selectors.
skills/browserbase/reference/onboarding-guide.md:74:> and that cap isn't surfaced up front — so a Stagehand `act`/`extract`/`observe` run can suddenly fail
skills/browserbase/reference/onboarding-guide.md:366:>   use **Stagehand** `act` / `extract` / `observe`. You script the steps — cheaper, faster, more reliable.
skills/browserbase/reference/onboarding-guide.md:380:| **Stagehand** | You want natural-language browser automation — `act` / `extract` / `observe` instead of brittle selectors. Best default for agentic browsing & data extraction. | https://docs.stagehand.dev/llms.txt |
skills/browserbase/reference/onboarding-guide.md:400:- **Stagehand** — use the current V4 installation and browser-configuration pages selected from
skills/browserbase/reference/onboarding-guide.md:410:task-specific Markdown pages needed for the integration. Treat those docs and the installed SDK's
skills/browserbase/reference/onboarding-guide.md:422:  Playwright-style page APIs with natural-language `act` / `extract` / `observe` methods so
skills/browserbase/reference/onboarding-guide.md:425:- **Write the Stagehand code for speed and reliability.** Use the current caching and prompting pages
skills/browserbase/reference/onboarding-guide.md:427:  - Enable the documented Browserbase server-side `cache` option when repeated steps have stable inputs.
skills/browserbase/reference/onboarding-guide.md:432:    confirm with `observe()` before acting; prefer `waitUntil: "domcontentloaded"`.
skills/browserbase/SKILL.md:8:  catalog -> Stagehand act/extract/observe -> raw Playwright session) and returns
skills/browserbase/SKILL.md:87:| Repeatable task on a JS page: extract fields, click, fill, paginate | **Stagehand** `act` / `extract` / `observe` | TS or Python SDK, see §4 |
skills/browserbase/SKILL.md:105:Goal: a sourced answer, not a pile of pages.
skills/browserbase/SKILL.md:137:   install page plus the task pages you need. Use installed SDK declarations for
skills/browserbase/SKILL.md:146:   - Wait on a specific element or `observe()` result, **never** a fixed sleep.
skills/browserbase/SKILL.md:148:   - Enable the server-side `cache` option when inputs are stable; pass dynamic or
skills/releases/install.sh:36:    echo "  Preserve or move it yourself, then re-run this installer." >&2

exec
/bin/zsh -lc "rg -n -C 4 'ROADMAP-DASHBOARD|generated view|ROUTER' utils/py/router_audit.py test/gh353-vendored-router-audit.sh AGENTS.md GUIDING-PRINCIPLES.md; rg -n -i 'LEADERBOARD\\.html|RELEASES-PREVIEW\\.html' .github/workflows relay-automation/xyz-vendor.sh relay-automation/xyz-sync.sh || true; nl -ba utils/py/router_audit.py | sed -n '1,240p'; nl -ba test/gh353-vendored-router-audit.sh | sed -n '1,220p'; nl -ba GUIDING-PRINCIPLES.md | sed -n '68,84p'; nl -ba AGENTS.md | sed -n '135,146p'; nl -ba skills/express/SKILL.md | sed -n '60,80p'; nl -ba skills/releases/SKILL.md | sed -n '45,68p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej
 succeeded in 0ms:
GUIDING-PRINCIPLES.md-1-# Guiding Principles
GUIDING-PRINCIPLES.md-2-
GUIDING-PRINCIPLES.md:3:North star for **XYZ Forge**, the multi-agent coordination harness behind the `tick` event-log kernel and `relay-automation/` relay stack. When a choice is unclear, the option that keeps agents synchronized, contained, and verifiable — without leaking or destroying work — wins. AGENTS.md is the behavioral playbook; ROUTER.md is the entry-point map; this is the *why*.
GUIDING-PRINCIPLES.md-4-
GUIDING-PRINCIPLES.md-5-## The North Star
GUIDING-PRINCIPLES.md-6-
GUIDING-PRINCIPLES.md-7-There is no perfect architecture and no finished codebase. The bar is not perfection — it is that
--
GUIDING-PRINCIPLES.md-73-7. **Least code that clears the bar.** The `tick` coordination kernel uses Node's standard library. The repository also ships `package.json` and `package-lock.json` for Acorn-based source analysis. Prefer reusing or extending what exists; the smallest change that stays correct, contained, and durable wins. Net-new code is a cost to justify. Deleting code counts as progress.
GUIDING-PRINCIPLES.md-74-
GUIDING-PRINCIPLES.md-75-8. **Honest; the operator decides.** Surface what failed and why — never mask a stall as success or an escalation as a stall. A headless turn self-repairs within a bounded exit-code menu (`exit 3` stall, `exit 4` escalated-by-design, `exit 6` containment revert), then stops; it never loops forever or silently swallows an error. Destructive actions require explicit authorization.
GUIDING-PRINCIPLES.md-76-
GUIDING-PRINCIPLES.md:77:9. **Docs support resumable work (PDDA).** ROUTER points to the governing contracts; the RELEASES DB owns this repository's roadmap ledger, and ROADMAP-DASHBOARD.md is its generated view. Linked PROJECT documents hold plans, decisions and handoff detail; CHANGELOG records dated outcomes. Resume execution using those documents together with the relevant runtime state and evidence. If current documentation contradicts the implementation, correct it or explicitly record the unresolved discrepancy.
GUIDING-PRINCIPLES.md-78-
GUIDING-PRINCIPLES.md-79-10. **Done means verified.** "Done" is `validate.sh` green, the relevant PDDA checks passing, and any relay review returning `Approved` — not work that looks finished. An unverified success claim is itself a low-quality signal.
GUIDING-PRINCIPLES.md-80-
GUIDING-PRINCIPLES.md-81-11. **Issue-first; every non-trivial change has a signal stream.** Any change beyond a 2–3 line fix opens a GitHub issue first, then gets a `GH-<number>` in-repo pointer doc, then lands. The issue is the machine-queryable signal stream; the `PROJECT/**` doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt.
--
AGENTS.md-21-> license. Coding models may choose commands through their own runtimes and safety controls, outside
AGENTS.md-22-> the intended harness workflow. XYZ Forge cannot guarantee model behavior or data integrity; maintain
AGENTS.md-23-> tested, independent backups and follow industry-standard backup and recovery practices.
AGENTS.md-24-
AGENTS.md:25:Read `ROUTER.md` first for startup order and canonical files.
AGENTS.md-26-
AGENTS.md-27-Read `GUIDING-PRINCIPLES.md` for the product north stars — its "The North Star" section (durable,
AGENTS.md-28-reversible, DRY; extend what exists rather than forking a parallel system) is canonical and governs
AGENTS.md-29-everything below.
AGENTS.md-30-
AGENTS.md-31-Read `PROJECT/PDDA.md` when the task touches project docs or `CHANGELOG.md`.
AGENTS.md:32:Its document contract is adopted here; [ROUTER’s role split](ROUTER.md#role-split) distinguishes
AGENTS.md-33-XYZ-owned policy from PDDA-layer scope.
AGENTS.md-34-
AGENTS.md-35-Read `HARNESS-MODELS-REGISTRY.md` for evaluated agent harnesses, model compatibility grades, and CLI flags.
AGENTS.md-36-
--
AGENTS.md-48-This file is the behavioral playbook for work in this repo: decision quality, reversibility, blast
AGENTS.md-49-radius, planning shape, and proof.
AGENTS.md-50-
AGENTS.md-51-Do not restate routing, roadmap, changelog, or active-doc contracts here. Those live in
AGENTS.md:52:`ROUTER.md` and `PROJECT/PDDA.md`.
AGENTS.md-53-
AGENTS.md-54-After merging any PR into `development`, run `python3 utils/py/wave_reconcile.py --pr <N>` before
AGENTS.md-55-ending the task — the reconciler is single-command but nothing triggers it for you; `pdda.sh
AGENTS.md-56-issue-doc-sync` is the deterministic drift detector when in doubt.
--
AGENTS.md-137-  Four rules follow, and they are load-bearing:
AGENTS.md-138-
AGENTS.md-139-  1. **Exactly one long-horizon marathon is in flight at a time.** When one lands, choosing the next
AGENTS.md-140-     is a real decision, not a default. It is named in the roadmap ledger's **Immediate next-up**
AGENTS.md:141:     (read `ROADMAP-DASHBOARD.md`; the RELEASES DB is the source of truth since the
AGENTS.md-142-     `ROADMAP_SOURCE=releases` flip) as the marathon, so an agent arriving cold can tell which item
AGENTS.md-143-     is the load and which items are riding alongside it.
AGENTS.md-144-  2. **Prefer the marathon-shaped candidate.** *Marathon-shaped* means: decomposable into many items
AGENTS.md-145-     with an identical transform, a per-item pass condition a machine can check, and a plausible way
--
AGENTS.md-156-
AGENTS.md-157-- **The RELEASES DB is two subsystems behind one CLI** (`utils/py/releases_app.py`): the GH-32
AGENTS.md-158-  release ledger and the roadmap ledger (`roadmap_items`). Since the `ROADMAP_SOURCE=releases`
AGENTS.md-159-  flip (GH-169/GH-238/GH-243) and ROADMAP.md retirement (GH-269), the DB is the roadmap's source of truth in THIS repo: park intake
AGENTS.md:160:  with `releases roadmap add` (or `hq park`), and read with `roadmap list` / `ROADMAP-DASHBOARD.md`.
AGENTS.md-161-  `roadmap sync` is for legacy-mode repos only and no-ops here — it mirrors markdown and would delete
AGENTS.md-162-  `add`-parked rows. Never hand-edit `releases.sql` or `releases.db`. Merge conflicts on the dump have
AGENTS.md-163-  a one-command resolver (`utils/releases-merge-resolve.sh`). The whole contract, including what a real
AGENTS.md-164-  merge conflict looks like: [RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md).
--
AGENTS.md-202-  wrap the complete command with `utils/git-sandbox-guard.sh --repo <root> -- <git command>` so it
AGENTS.md-203-  refuses before mutation when the config cannot be written. Never truncate git stderr for branch
AGENTS.md-204-  operations: the decisive `could not lock config file` line can otherwise disappear behind an
AGENTS.md-205-  unrelated upstream hint.
AGENTS.md:206:- `ROUTER.md` owns startup order, canonical files, command rails, and the issue-first SOP.
AGENTS.md-207-- `GUIDING-PRINCIPLES.md` owns the product/runtime priorities: local event-log coordination,
AGENTS.md-208-  containment, skill-first relay work, durable fixes, and verified done.
AGENTS.md-209-- `PROJECT/PDDA.md` owns doc lifecycle, roadmap pointer-ledger rules, and `CHANGELOG.md`
AGENTS.md-210-  governance.
--
AGENTS.md-397-  2026-07-10 renaming a branch backing PR #193; recovered by opening a new PR from the renamed
AGENTS.md-398-  branch and pointer-commenting the closed one). If a branch needs a new name and has an open PR:
AGENTS.md-399-  either rename it *before* opening the PR, or accept that renaming after will require re-opening a
AGENTS.md-400-  fresh PR — don't assume the PR follows the rename.
AGENTS.md:401:- **Aider Configuration (AIDER.md / GH-77)**: When using Aider as a headless runner against OpenRouter, do not hardcode the API key or attempt to use a secrets manager. The `OPENROUTER_API_KEY` is securely stored at `~/secrets/openrouter/openrouter.txt` and is exported dynamically by `~/.zshrc`.
AGENTS.md-402-- **Aider edit-format compat for OpenRouter models (GH-118)**: many OpenRouter-proxied models
AGENTS.md-403-  (confirmed: GLM-5.2, Nemotron Ultra 3) default to Aider's `whole` edit format and fail to emit
AGENTS.md-404-  parseable edits, stalling the turn. Fix is `AIDER_FLAGS=--edit-format diff` (existing passthrough
AGENTS.md-405-  in `aider-turn.sh`) — see `relay-automation/README.md`'s "Known OpenRouter edit-format quirks"
--
AGENTS.md-416-
AGENTS.md-417-## Conflict order
AGENTS.md-418-
AGENTS.md-419-1. The current user request
AGENTS.md:420:2. The canonical doc that owns the surface you are touching (`ROUTER.md`, `GUIDING-PRINCIPLES.md`,
AGENTS.md-421-   `PROJECT/PDDA.md`, or the active `PROJECT/**` doc)
AGENTS.md-422-3. This file
AGENTS.md-423-4. Skill defaults
--
utils/py/router_audit.py-1-#!/usr/bin/env python3
utils/py/router_audit.py:2:"""router_audit.py — Audit and remediate ROUTER.md roadmap declarations across repos.
utils/py/router_audit.py-3-
utils/py/router_audit.py-4-Contract:
utils/py/router_audit.py-5-- Checks if a target repository is in releases mode (releases.db present or anchored ROADMAP_SOURCE=releases in .pdda-mode).
utils/py/router_audit.py-6-- If in releases mode:
utils/py/router_audit.py-7-  - Asserts exactly one exact ## Role split and ## Startup sequence section exists (ignoring headings inside fenced code blocks and prefixed custom sections like '## Role split rationale').
utils/py/router_audit.py:8:  - Asserts ## Role split affirmatively declares ROADMAP-DASHBOARD.md as generated view of the roadmap ledger (rejecting 'generated deployment manifest', 'not a generated view', 'lives elsewhere', 'historical archive', 'do not read', 'obsolete').
utils/py/router_audit.py-9-  - Asserts ## Role split declares ROADMAP.md frozen/legacy AND affirmatively declares the releases DB (releases.db / releases.sql) as the source of truth (rejecting 'releases.db is present for compatibility', 'ROADMAP_SOURCE=releases' without DB source of truth, unrelated frozen subjects like 'OLD-API.md is frozen', active/current/priority claims or negated frozen/legacy in owned ROADMAP.md entries, while preserving non-owned entries like PROJECT/PDDA.md and examples inside code fences).
utils/py/router_audit.py:10:  - Asserts ## Startup sequence directs to ROADMAP-DASHBOARD.md for current work/state/active effort in the directive clause itself (rejecting purpose-free reads like 'Read ROADMAP-DASHBOARD.md for deployment instructions; TEAM.md tracks current work', 'not current state', 'historical reference only', 'do not read') and forbids active ROADMAP.md directives in all clauses (supporting valid negations like 'do not use ROADMAP.md', while preserving custom steps and historical reads like 'Read ROADMAP.md only for historical reference').
utils/py/router_audit.py-11-- If in legacy mode:
utils/py/router_audit.py-12-  - Asserts exactly one exact ## Role split and ## Startup sequence section exists (ignoring code fences).
utils/py/router_audit.py-13-  - Asserts ## Role split affirmatively declares active ROADMAP.md pointer ledger of current/active work in its own clause (rejecting 'pointer ledger for deployment policy', 'archived', 'frozen', 'legacy', 'releases.db', while preserving unrelated legacy entries like OLD-API.md and historical CHANGELOG entries like '- `CHANGELOG.md` = records when `ROADMAP.md` was frozen during the 2025 migration').
utils/py/router_audit.py-14-  - Asserts ## Startup sequence directs to active ROADMAP.md for active effort/current work/tasks/intake in the candidate directive clause itself (rejecting 'for deployment instructions; do not use ROADMAP.md for current work', 'historical reference only', ignoring unrelated legacy entries).
--
utils/py/router_audit.py-28-import sys
utils/py/router_audit.py-29-import tempfile
utils/py/router_audit.py-30-
utils/py/router_audit.py-31-
utils/py/router_audit.py:32:RELEASES_TOKENS = r"\b(ROADMAP-DASHBOARD\.md|releases\.db|releases\.sql|ROADMAP_SOURCE=releases|ROADMAP_SOURCE\s*=\s*releases)\b"
utils/py/router_audit.py-33-ROADMAP_MENTION_RE = r"(?:`?ROADMAP\.md`?|\[[^\]]*\]\([^)]*ROADMAP\.md[^)]*\))"
utils/py/router_audit.py:34:DASHBOARD_MENTION_RE = r"(?:`?ROADMAP-DASHBOARD\.md`?|\[[^\]]*\]\([^)]*ROADMAP-DASHBOARD\.md[^)]*\))"
utils/py/router_audit.py-35-
utils/py/router_audit.py:36:# Matches lines where ROADMAP.md or ROADMAP-DASHBOARD.md is the declared subject
utils/py/router_audit.py-37-OWNED_ROADMAP_DECL_RE = r"^\s*(?:[-*+]|\d+\.)?\s*`?ROADMAP\.md`?\s*(?:=|:|—|-)\s*(.*)$"
utils/py/router_audit.py:38:OWNED_DASHBOARD_DECL_RE = r"^\s*(?:[-*+]|\d+\.)?\s*`?ROADMAP-DASHBOARD\.md`?\s*(?:=|:|—|-)\s*(.*)$"
utils/py/router_audit.py-39-
utils/py/router_audit.py-40-
utils/py/router_audit.py-41-def parse_pdda_mode(root):
utils/py/router_audit.py-42-    """Checks .pdda-mode for anchored ROADMAP_SOURCE=releases.
--
utils/py/router_audit.py-231-    return ""
utils/py/router_audit.py-232-
utils/py/router_audit.py-233-
utils/py/router_audit.py-234-def is_owned_startup_roadmap_directive(line):
utils/py/router_audit.py:235:    """Returns True if a Startup line is the primary directive to read ROADMAP.md or ROADMAP-DASHBOARD.md for current work."""
utils/py/router_audit.py-236-    if is_active_roadmap_startup_directive(line):
utils/py/router_audit.py-237-        return True
utils/py/router_audit.py-238-    if re.search(r"\b(?:only\s+for\s+historical|for\s+historical\s+reference|historical\s+reference\s+only)\b", line, re.IGNORECASE):
utils/py/router_audit.py-239-        return False
--
utils/py/router_audit.py-276-    return False
utils/py/router_audit.py-277-
utils/py/router_audit.py-278-
utils/py/router_audit.py-279-def is_affirmative_dashboard_role_line(line):
utils/py/router_audit.py:280:    """Returns True if a Role split line affirmatively declares ROADMAP-DASHBOARD.md as the generated view of the roadmap ledger."""
utils/py/router_audit.py-281-    m = re.search(OWNED_DASHBOARD_DECL_RE, line, re.IGNORECASE)
utils/py/router_audit.py-282-    if not m:
utils/py/router_audit.py-283-        return False
utils/py/router_audit.py-284-    desc = m.group(1)
--
utils/py/router_audit.py-297-        return False
utils/py/router_audit.py-298-    for clause in split_clauses(line):
utils/py/router_audit.py-299-        if not re.search(DASHBOARD_MENTION_RE, clause, re.IGNORECASE):
utils/py/router_audit.py-300-            continue
utils/py/router_audit.py:301:        if not re.search(r"\b(?:Read|Consult|Open|Check|See|Inspect|Use)\s+(?:`?ROADMAP-DASHBOARD\.md`?|\[[^\]]*\]\([^)]*ROADMAP-DASHBOARD\.md[^)]*\))", clause, re.IGNORECASE):
utils/py/router_audit.py-302-            continue
utils/py/router_audit.py-303-        if re.search(r"\b(?:do\s+not|never)\s+(?:read|consult|open|check|use)\b", clause, re.IGNORECASE):
utils/py/router_audit.py-304-            continue
utils/py/router_audit.py-305-        if re.search(r"\b(?:historical\s+(?:reference|archive|context)|only\s+for\s+historical|obsolete|not\s+current|not\s+for\s+current)\b", clause, re.IGNORECASE):
--
utils/py/router_audit.py-327-    return False
utils/py/router_audit.py-328-
utils/py/router_audit.py-329-
utils/py/router_audit.py-330-def audit_router(root, content_override=None):
utils/py/router_audit.py:331:    """Audit ROUTER.md in root (or content_override if provided). Returns a dict."""
utils/py/router_audit.py:332:    router_path = os.path.join(root, "ROUTER.md")
utils/py/router_audit.py-333-    releases_mode, mode_err = get_repo_mode(root)
utils/py/router_audit.py-334-
utils/py/router_audit.py-335-    result = {
utils/py/router_audit.py-336-        "root": root,
--
utils/py/router_audit.py-350-        return result
utils/py/router_audit.py-351-
utils/py/router_audit.py-352-    if not result["exists"]:
utils/py/router_audit.py-353-        result["error"] = True
utils/py/router_audit.py:354:        result["reasons"].append("ROUTER.md does not exist")
utils/py/router_audit.py-355-        return result
utils/py/router_audit.py-356-
utils/py/router_audit.py-357-    if content_override is not None:
utils/py/router_audit.py-358-        content = content_override
--
utils/py/router_audit.py-362-                content = f.read()
utils/py/router_audit.py-363-        except Exception as e:
utils/py/router_audit.py-364-            result["readable"] = False
utils/py/router_audit.py-365-            result["error"] = True
utils/py/router_audit.py:366:            result["reasons"].append(f"could not read ROUTER.md: {e}")
utils/py/router_audit.py-367-            return result
utils/py/router_audit.py-368-
utils/py/router_audit.py-369-    sections = find_sections(content)
utils/py/router_audit.py-370-    role_sections = [s for s in sections if re.match(r"^Role\s+split$", s["heading"], re.IGNORECASE)]
--
utils/py/router_audit.py-391-    if releases_mode:
utils/py/router_audit.py-392-        # Releases Mode Validation
utils/py/router_audit.py-393-        if role_section is None:
utils/py/router_audit.py-394-            result["drift"] = True
utils/py/router_audit.py:395:            result["reasons"].append("ROUTER.md missing '## Role split' section")
utils/py/router_audit.py-396-        else:
utils/py/router_audit.py-397-            has_affirmative_dashboard = any(
utils/py/router_audit.py-398-                is_affirmative_dashboard_role_line(l) for l in all_role_lines
utils/py/router_audit.py-399-            )
--
utils/py/router_audit.py-403-            ]
utils/py/router_audit.py-404-
utils/py/router_audit.py-405-            if not has_affirmative_dashboard:
utils/py/router_audit.py-406-                result["drift"] = True
utils/py/router_audit.py:407:                result["reasons"].append("Role split does not affirmatively declare ROADMAP-DASHBOARD.md as the generated roadmap view")
utils/py/router_audit.py-408-            if not owned_roadmap_lines:
utils/py/router_audit.py-409-                result["drift"] = True
utils/py/router_audit.py-410-                result["reasons"].append("Role split does not contain a ROADMAP.md declaration")
utils/py/router_audit.py-411-            else:
--
utils/py/router_audit.py-448-                    result["reasons"].append("Role split contains stray active ROADMAP.md clause")
utils/py/router_audit.py-449-
utils/py/router_audit.py-450-        if startup_section is None:
utils/py/router_audit.py-451-            result["drift"] = True
utils/py/router_audit.py:452:            result["reasons"].append("ROUTER.md missing '## Startup sequence' section")
utils/py/router_audit.py-453-        else:
utils/py/router_audit.py-454-            has_affirmative_dashboard_startup = any(
utils/py/router_audit.py-455-                is_affirmative_dashboard_startup_directive(l) for l in all_startup_lines
utils/py/router_audit.py-456-            )
--
utils/py/router_audit.py-459-            )
utils/py/router_audit.py-460-
utils/py/router_audit.py-461-            if not has_affirmative_dashboard_startup:
utils/py/router_audit.py-462-                result["drift"] = True
utils/py/router_audit.py:463:                result["reasons"].append("Startup sequence does not contain an affirmative directive to read ROADMAP-DASHBOARD.md for current work")
utils/py/router_audit.py-464-            if has_active_roadmap_read:
utils/py/router_audit.py-465-                result["drift"] = True
utils/py/router_audit.py-466-                result["reasons"].append("Startup sequence contains active ROADMAP.md directive without frozen/legacy note")
utils/py/router_audit.py-467-
--
utils/py/router_audit.py-471-    else:
utils/py/router_audit.py-472-        # Legacy Mode Validation
utils/py/router_audit.py-473-        if role_section is None:
utils/py/router_audit.py-474-            result["drift"] = True
utils/py/router_audit.py:475:            result["reasons"].append("Legacy ROUTER.md missing '## Role split' section")
utils/py/router_audit.py-476-        else:
utils/py/router_audit.py-477-            has_rel_tokens = any(
utils/py/router_audit.py-478-                re.search(RELEASES_TOKENS, l, re.IGNORECASE) for l in all_role_lines
utils/py/router_audit.py-479-            )
--
utils/py/router_audit.py-492-            )
utils/py/router_audit.py-493-
utils/py/router_audit.py-494-            if has_rel_tokens:
utils/py/router_audit.py-495-                result["drift"] = True
utils/py/router_audit.py:496:                result["reasons"].append("Role split references releases-mode tokens (ROADMAP-DASHBOARD.md/releases.db) in a legacy-mode repo")
utils/py/router_audit.py-497-            if has_affirmative_frozen_in_role:
utils/py/router_audit.py-498-                result["drift"] = True
utils/py/router_audit.py-499-                result["reasons"].append("Role split declares ROADMAP.md as frozen/legacy in a legacy-mode repo")
utils/py/router_audit.py-500-            if not has_positive_active_role:
--
utils/py/router_audit.py-502-                result["reasons"].append("Role split missing affirmative active ROADMAP.md pointer ledger declaration in a legacy-mode repo")
utils/py/router_audit.py-503-
utils/py/router_audit.py-504-        if startup_section is None:
utils/py/router_audit.py-505-            result["drift"] = True
utils/py/router_audit.py:506:            result["reasons"].append("Legacy ROUTER.md missing '## Startup sequence' section")
utils/py/router_audit.py-507-        else:
utils/py/router_audit.py-508-            has_rel_tokens_startup = any(
utils/py/router_audit.py-509-                re.search(RELEASES_TOKENS, l, re.IGNORECASE) for l in all_startup_lines
utils/py/router_audit.py-510-            )
--
utils/py/router_audit.py-541-    return result
utils/py/router_audit.py-542-
utils/py/router_audit.py-543-
utils/py/router_audit.py-544-def fix_router(root, dry_run=False):
utils/py/router_audit.py:545:    """Applies targeted updates to ROUTER.md by splicing exact sections in-place, deduplicating sections, and preserving custom bytes."""
utils/py/router_audit.py-546-    audit = audit_router(root)
utils/py/router_audit.py-547-    if not audit["exists"]:
utils/py/router_audit.py:548:        return False, "ROUTER.md does not exist"
utils/py/router_audit.py-549-    if not audit["readable"] or audit["error"]:
utils/py/router_audit.py:550:        return False, f"ROUTER.md cannot be audited: {'; '.join(audit['reasons'])}"
utils/py/router_audit.py-551-    if not audit["drift"]:
utils/py/router_audit.py:552:        return True, "ROUTER.md already in sync with repo mode"
utils/py/router_audit.py-553-
utils/py/router_audit.py-554-    router_path = audit["router_path"]
utils/py/router_audit.py-555-    with open(router_path, "r", newline="", encoding="utf-8") as f:
utils/py/router_audit.py-556-        content = f.read()
--
utils/py/router_audit.py-586-                    new_r_pieces.append(f"{line_text}{term}")
utils/py/router_audit.py-587-                    continue
utils/py/router_audit.py-588-                if re.search(OWNED_DASHBOARD_DECL_RE, line_text, re.IGNORECASE):
utils/py/router_audit.py-589-                    if not dashboard_seen:
utils/py/router_audit.py:590:                        new_r_pieces.append(f"- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`){eff_term}")
utils/py/router_audit.py-591-                        dashboard_seen = True
utils/py/router_audit.py-592-                elif re.search(OWNED_ROADMAP_DECL_RE, line_text, re.IGNORECASE):
utils/py/router_audit.py-593-                    if not dashboard_seen:
utils/py/router_audit.py:594:                        new_r_pieces.append(f"- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`){eff_term}")
utils/py/router_audit.py-595-                        dashboard_seen = True
utils/py/router_audit.py-596-                    if not roadmap_seen:
utils/py/router_audit.py-597-                        new_r_pieces.append(f"- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file{eff_term}")
utils/py/router_audit.py-598-                        roadmap_seen = True
--
utils/py/router_audit.py-604-                else:
utils/py/router_audit.py-605-                    new_r_pieces.append(f"{line_text}{term}")
utils/py/router_audit.py-606-
utils/py/router_audit.py-607-            if not dashboard_seen and not roadmap_seen:
utils/py/router_audit.py:608:                new_r_pieces.append(f"- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`){crlf}")
utils/py/router_audit.py-609-                new_r_pieces.append(f"- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file{crlf}")
utils/py/router_audit.py-610-            elif not dashboard_seen:
utils/py/router_audit.py:611:                new_r_pieces.append(f"- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`){crlf}")
utils/py/router_audit.py-612-            elif not roadmap_seen:
utils/py/router_audit.py-613-                new_r_pieces.append(f"- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file{crlf}")
utils/py/router_audit.py-614-
utils/py/router_audit.py-615-            new_role_body = "".join(new_r_pieces)
--
utils/py/router_audit.py-617-                new_role_body += crlf
utils/py/router_audit.py-618-        else:
utils/py/router_audit.py-619-            new_role_body = crlf.join([
utils/py/router_audit.py-620-                "",
utils/py/router_audit.py:621:                "- `ROUTER.md` = startup order and canonical entry points",
utils/py/router_audit.py-622-                "- `AGENTS.md` = behavioral rules, decision quality, reversibility, blast radius, proof",
utils/py/router_audit.py:623:                "- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)",
utils/py/router_audit.py-624-                "- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file",
utils/py/router_audit.py-625-                "- `CHANGELOG.md` = the end-of-iteration running log",
utils/py/router_audit.py-626-                "- `RELEASES.md` = forward-looking release-planning ledger (optional milestone planning aid)",
utils/py/router_audit.py-627-                "",
--
utils/py/router_audit.py-640-                if is_owned_startup_roadmap_directive(line_text):
utils/py/router_audit.py-641-                    if not dashboard_step_seen:
utils/py/router_audit.py-642-                        m = re.match(r"^(\s*(?:\d+\.|\-|\*)\s+)(.*)$", line_text)
utils/py/router_audit.py-643-                        num_prefix = m.group(1) if m else "3. "
utils/py/router_audit.py:644:                        new_st_pieces.append(f"{num_prefix}Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list` / `.xyz/utils/py/releases_app.py roadmap list`) to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.){eff_term}")
utils/py/router_audit.py-645-                        dashboard_step_seen = True
utils/py/router_audit.py-646-                    continue
utils/py/router_audit.py-647-                new_st_pieces.append(f"{line_text}{term}")
utils/py/router_audit.py-648-
utils/py/router_audit.py-649-            if not dashboard_step_seen:
utils/py/router_audit.py:650:                new_st_pieces.append(f"3. Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list` / `.xyz/utils/py/releases_app.py roadmap list`) to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.){crlf}")
utils/py/router_audit.py-651-
utils/py/router_audit.py-652-            new_startup_body = "".join(new_st_pieces)
utils/py/router_audit.py-653-            if not new_startup_body.endswith("\n") and not new_startup_body.endswith("\r\n"):
utils/py/router_audit.py-654-                new_startup_body += crlf
utils/py/router_audit.py-655-        else:
utils/py/router_audit.py-656-            new_startup_body = crlf.join([
utils/py/router_audit.py-657-                "",
utils/py/router_audit.py:658:                "1. Read `ROUTER.md` to understand the repo's operating order and canonical files.",
utils/py/router_audit.py-659-                "2. Read `AGENTS.md` before making recommendations or edits.",
utils/py/router_audit.py:660:                "3. Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list` / `.xyz/utils/py/releases_app.py roadmap list`) to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.)",
utils/py/router_audit.py-661-                "4. Read the linked `PROJECT/**` document that owns the work you are touching.",
utils/py/router_audit.py-662-                "",
utils/py/router_audit.py-663-            ]) + crlf
utils/py/router_audit.py-664-
--
utils/py/router_audit.py-692-                new_role_body += crlf
utils/py/router_audit.py-693-        else:
utils/py/router_audit.py-694-            new_role_body = crlf.join([
utils/py/router_audit.py-695-                "",
utils/py/router_audit.py:696:                "- `ROUTER.md` = startup order and canonical entry points",
utils/py/router_audit.py-697-                "- `AGENTS.md` = behavioral rules, decision quality, reversibility, blast radius, proof",
utils/py/router_audit.py-698-                "- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work",
utils/py/router_audit.py-699-                "- `CHANGELOG.md` = the end-of-iteration running log",
utils/py/router_audit.py-700-                "",
--
utils/py/router_audit.py-726-                new_startup_body += crlf
utils/py/router_audit.py-727-        else:
utils/py/router_audit.py-728-            new_startup_body = crlf.join([
utils/py/router_audit.py-729-                "",
utils/py/router_audit.py:730:                "1. Read `ROUTER.md` to understand the repo's operating order and canonical files.",
utils/py/router_audit.py-731-                "2. Read `AGENTS.md` before making recommendations or edits.",
utils/py/router_audit.py-732-                "3. Read `ROADMAP.md` to find the active effort or parked intake. -> expect links outward to canonical `PROJECT/**` docs.",
utils/py/router_audit.py-733-                "4. Read the linked `PROJECT/**` document that owns the work you are touching.",
utils/py/router_audit.py-734-                "",
--
utils/py/router_audit.py-769-    if candidate_audit["drift"] or candidate_audit["error"]:
utils/py/router_audit.py-770-        return False, f"pre-write validation failed: {'; '.join(candidate_audit['reasons'])}"
utils/py/router_audit.py-771-
utils/py/router_audit.py-772-    if dry_run:
utils/py/router_audit.py:773:        return True, "dry-run: planned updates to ROUTER.md"
utils/py/router_audit.py-774-
utils/py/router_audit.py-775-    stat = os.stat(router_path)
utils/py/router_audit.py-776-    dir_name = os.path.dirname(os.path.abspath(router_path))
utils/py/router_audit.py-777-    fd, tmp_path = tempfile.mkstemp(prefix="router_audit_", dir=dir_name)
--
utils/py/router_audit.py-787-            try:
utils/py/router_audit.py-788-                os.remove(tmp_path)
utils/py/router_audit.py-789-            except OSError:
utils/py/router_audit.py-790-                pass
utils/py/router_audit.py:791:        return False, f"failed to write updated ROUTER.md: {e}"
utils/py/router_audit.py-792-
utils/py/router_audit.py:793:    return True, "updated ROUTER.md to reflect repository roadmap mode"
utils/py/router_audit.py-794-
utils/py/router_audit.py-795-
utils/py/router_audit.py-796-def main(argv=None):
utils/py/router_audit.py:797:    parser = argparse.ArgumentParser(description="Audit and remediate ROUTER.md roadmap declarations.")
utils/py/router_audit.py-798-    parser.add_argument("root", nargs="?", default=".", help="Target repository directory (default: current directory)")
utils/py/router_audit.py-799-    parser.add_argument("--check", action="store_true", help="Exit 1 if drift, missing, or error detected, 0 if clean")
utils/py/router_audit.py:800:    parser.add_argument("--fix", action="store_true", help="Remediate detected ROUTER.md drift")
utils/py/router_audit.py-801-    parser.add_argument("--dry-run", action="store_true", help="Report planned remediation without writing")
utils/py/router_audit.py-802-    parser.add_argument("--json", action="store_true", help="Output audit result as JSON")
utils/py/router_audit.py-803-
utils/py/router_audit.py-804-    args = parser.parse_args(argv)
--
utils/py/router_audit.py-819-        import json
utils/py/router_audit.py-820-        print(json.dumps(audit))
utils/py/router_audit.py-821-    else:
utils/py/router_audit.py-822-        if not audit["exists"]:
utils/py/router_audit.py:823:            print(f"ROUTER.md not found in {root}")
utils/py/router_audit.py-824-        elif not audit["readable"] or audit["error"]:
utils/py/router_audit.py:825:            print(f"ERROR reading ROUTER.md in {root}:")
utils/py/router_audit.py-826-            for r in audit["reasons"]:
utils/py/router_audit.py-827-                print(f"  • {r}")
utils/py/router_audit.py-828-        elif audit["drift"]:
utils/py/router_audit.py-829-            mode_str = "releases" if audit["releases_mode"] else "legacy"
utils/py/router_audit.py:830:            print(f"ROUTER DRIFT in {audit['router_path']} (mode: {mode_str}):")
utils/py/router_audit.py-831-            for r in audit["reasons"]:
utils/py/router_audit.py-832-                print(f"  • {r}")
utils/py/router_audit.py-833-            print(f"Remediation available: run `python3 utils/py/router_audit.py --fix {root}`")
utils/py/router_audit.py-834-        else:
--
test/gh353-vendored-router-audit.sh-1-#!/usr/bin/env bash
test/gh353-vendored-router-audit.sh:2:# gh353-vendored-router-audit.sh — GH-353: audit and remediate target ROUTER.md ROADMAP.md frozen status.
test/gh353-vendored-router-audit.sh-3-#
test/gh353-vendored-router-audit.sh-4-# Comprehensive regression test matrix:
test/gh353-vendored-router-audit.sh-5-#   1. Clean releases-mode repo reports `ok` (rc=0).
test/gh353-vendored-router-audit.sh:6:#   2. Drifted releases-mode repo (legacy ROUTER.md with active ROADMAP.md) reports `ROUTER DRIFT` (rc=1 on --check).
test/gh353-vendored-router-audit.sh-7-#   3. Releases negative: mention dashboard only in unrelated prose outside Role split / Startup -> fails audit.
test/gh353-vendored-router-audit.sh-8-#   4. Releases negative: missing ROADMAP.md declaration in Role split -> fails audit.
test/gh353-vendored-router-audit.sh:9:#   5. Releases negative: obsolete dashboard in Role split `ROADMAP-DASHBOARD.md = obsolete; do not read` -> fails audit.
test/gh353-vendored-router-audit.sh-10-#   6. Releases negative: historical archive only dashboard in Role split -> fails audit.
test/gh353-vendored-router-audit.sh:11:#   7. Releases negative: negated generated dashboard `ROADMAP-DASHBOARD.md = not generated; current view lives elsewhere` -> fails audit.
test/gh353-vendored-router-audit.sh:12:#   8. Releases negative: not a generated view `ROADMAP-DASHBOARD.md = not a generated view` -> fails audit.
test/gh353-vendored-router-audit.sh:13:#   9. Releases negative: generated deployment manifest `ROADMAP-DASHBOARD.md = generated deployment manifest` -> fails audit.
test/gh353-vendored-router-audit.sh-14-#  10. Releases negative: negated DB source of truth `ROADMAP.md = frozen legacy; releases.db is not the source of truth` -> fails audit.
test/gh353-vendored-router-audit.sh-15-#  11. Releases negative: compatibility DB note `ROADMAP.md = frozen legacy; releases.db is present for compatibility` -> fails audit.
test/gh353-vendored-router-audit.sh-16-#  12. Releases negative: mode token without DB source of truth `ROADMAP.md = frozen legacy; ROADMAP_SOURCE=releases` -> fails audit.
test/gh353-vendored-router-audit.sh-17-#  13. Releases negative: unrelated frozen subject on same line `ROADMAP.md = deployment notes; OLD-API.md is frozen; releases.db is the source of truth` -> fails audit.
test/gh353-vendored-router-audit.sh:18:#  14. Releases negative: negated dashboard in Startup `Do not read ROADMAP-DASHBOARD.md` -> fails audit.
test/gh353-vendored-router-audit.sh-19-#  15. Releases negative: historical context dashboard in Startup -> fails audit.
test/gh353-vendored-router-audit.sh:20:#  16. Releases negative: purpose-free dashboard in Startup `Read ROADMAP-DASHBOARD.md for deployment instructions` -> fails audit.
test/gh353-vendored-router-audit.sh:21:#  17. Releases negative: purpose-free dashboard + unrelated current work `Read ROADMAP-DASHBOARD.md for deployment instructions; TEAM.md tracks current work` -> fails audit.
test/gh353-vendored-router-audit.sh:22:#  18. Releases negative: not current state dashboard in Startup `Read ROADMAP-DASHBOARD.md for not current state` -> fails audit.
test/gh353-vendored-router-audit.sh-23-#  19. Releases negative: multi-clause active directive `ROADMAP.md is frozen for historical reference; nevertheless use ROADMAP.md for current work` -> fails audit.
test/gh353-vendored-router-audit.sh-24-#  20. Releases negative: historical first clause + active second clause `Read ROADMAP.md only for historical reference; nevertheless use ROADMAP.md for current work` -> fails audit.
test/gh353-vendored-router-audit.sh-25-#  21. Releases negative: conjunction active directive `ROADMAP.md is frozen and use ROADMAP.md for current work` -> fails audit.
test/gh353-vendored-router-audit.sh-26-#  22. Releases negative: while-connector active directive `ROADMAP.md is frozen while operators use ROADMAP.md for current work` -> fails audit.
--
test/gh353-vendored-router-audit.sh-76-#  72. Legacy negative: Startup sequence with `Read ROADMAP.md; but note ROADMAP.md remains legacy` -> fails audit.
test/gh353-vendored-router-audit.sh-77-#  73. Legacy negative: Startup sequence with releases.sql mention -> fails audit.
test/gh353-vendored-router-audit.sh-78-#  74. Legacy negative: Missing Role split section -> fails audit.
test/gh353-vendored-router-audit.sh-79-#  75. Legacy negative: Missing Startup sequence section -> fails audit.
test/gh353-vendored-router-audit.sh:80:#  76. Legacy negative: leftover ROADMAP-DASHBOARD.md file on disk + clean router reports ok (not fooled by file).
test/gh353-vendored-router-audit.sh-81-#  77. Legacy --fix: removes two-line contradictory frozen role lines, standalone releases tokens, creates/repairs missing sections, restores active ROADMAP.md, strips dashboard, passes post-fix audit.
test/gh353-vendored-router-audit.sh:82:#  78. Missing ROUTER.md reports error and exits non-zero on --check.
test/gh353-vendored-router-audit.sh:83:#  79. Unreadable ROUTER.md reports error and exits non-zero on --check.
test/gh353-vendored-router-audit.sh-84-#  80. `xyz-sync.sh check` surfaces router drift for registered vendored repositories.
test/gh353-vendored-router-audit.sh-85-set -uo pipefail
test/gh353-vendored-router-audit.sh-86-
test/gh353-vendored-router-audit.sh-87-HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
--
test/gh353-vendored-router-audit.sh-117-# ── 1. Clean releases-mode repo ───────────────────────────────────────────────────
test/gh353-vendored-router-audit.sh-118-R_REL_CLEAN="$(mkrepo rel_clean)"
test/gh353-vendored-router-audit.sh-119-require_fixture "$R_REL_CLEAN" "clean releases repo"
test/gh353-vendored-router-audit.sh-120-touch "$R_REL_CLEAN/releases.db"
test/gh353-vendored-router-audit.sh:121:cat > "$R_REL_CLEAN/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:122:# ROUTER.md
test/gh353-vendored-router-audit.sh-123-## Role split
test/gh353-vendored-router-audit.sh:124:- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)
test/gh353-vendored-router-audit.sh-125-- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file
test/gh353-vendored-router-audit.sh-126-- `CHANGELOG.md` = running log of completed work
test/gh353-vendored-router-audit.sh-127-## Startup sequence
test/gh353-vendored-router-audit.sh:128:1. Read ROUTER.md
test/gh353-vendored-router-audit.sh-129-2. Read AGENTS.md
test/gh353-vendored-router-audit.sh:130:3. Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list`) to find the active effort. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.)
test/gh353-vendored-router-audit.sh-131-MD
test/gh353-vendored-router-audit.sh-132-
test/gh353-vendored-router-audit.sh-133-out="$(python3 "$AUDIT_PY" --check "$R_REL_CLEAN" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-134-ok "clean releases-mode repo reports ok (rc=0)" "$(is "$rc" "0"; echo $?)"
--
test/gh353-vendored-router-audit.sh-137-# ── 2. Drifted releases-mode repo (legacy active ROADMAP.md text) ───────────────────
test/gh353-vendored-router-audit.sh-138-R_REL_STALE="$(mkrepo rel_stale)"
test/gh353-vendored-router-audit.sh-139-require_fixture "$R_REL_STALE" "stale releases repo"
test/gh353-vendored-router-audit.sh-140-touch "$R_REL_STALE/releases.db"
test/gh353-vendored-router-audit.sh:141:cat > "$R_REL_STALE/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:142:# ROUTER.md
test/gh353-vendored-router-audit.sh-143-## Role split
test/gh353-vendored-router-audit.sh:144:- `ROUTER.md` = startup order
test/gh353-vendored-router-audit.sh-145-- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
test/gh353-vendored-router-audit.sh-146-- `CHANGELOG.md` = running log of completed work
test/gh353-vendored-router-audit.sh-147-## Startup sequence
test/gh353-vendored-router-audit.sh:148:1. Read ROUTER.md
test/gh353-vendored-router-audit.sh-149-2. Read AGENTS.md
test/gh353-vendored-router-audit.sh-150-3. Read `ROADMAP.md` to find the active effort.
test/gh353-vendored-router-audit.sh-151-MD
test/gh353-vendored-router-audit.sh-152-
test/gh353-vendored-router-audit.sh-153-out="$(python3 "$AUDIT_PY" --check "$R_REL_STALE" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-154-ok "drifted releases-mode repo reports non-zero exit with --check" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
test/gh353-vendored-router-audit.sh:155:ok "drifted releases-mode repo output reports ROUTER DRIFT" "$(has "$out" "ROUTER DRIFT"; echo $?)"
test/gh353-vendored-router-audit.sh-156-
test/gh353-vendored-router-audit.sh-157-# ── 3. Releases negative: dashboard mentioned outside Role split / Startup ─────────
test/gh353-vendored-router-audit.sh-158-R_REL_UNSCOPED="$(mkrepo rel_unscoped)"
test/gh353-vendored-router-audit.sh-159-require_fixture "$R_REL_UNSCOPED" "unscoped releases repo"
test/gh353-vendored-router-audit.sh-160-touch "$R_REL_UNSCOPED/releases.db"
test/gh353-vendored-router-audit.sh:161:cat > "$R_REL_UNSCOPED/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:162:# ROUTER.md
test/gh353-vendored-router-audit.sh:163:See ROADMAP-DASHBOARD.md in our notes somewhere.
test/gh353-vendored-router-audit.sh-164-## Role split
test/gh353-vendored-router-audit.sh-165-- `ROADMAP.md` = active roadmap ledger
test/gh353-vendored-router-audit.sh-166-## Startup sequence
test/gh353-vendored-router-audit.sh-167-1. Read `ROADMAP.md` to find work.
--
test/gh353-vendored-router-audit.sh-173-# ── 4. Releases negative: missing ROADMAP.md declaration in Role split ──────────────
test/gh353-vendored-router-audit.sh-174-R_REL_NO_RMI="$(mkrepo rel_no_rmi)"
test/gh353-vendored-router-audit.sh-175-require_fixture "$R_REL_NO_RMI" "no rmi releases repo"
test/gh353-vendored-router-audit.sh-176-touch "$R_REL_NO_RMI/releases.db"
test/gh353-vendored-router-audit.sh:177:cat > "$R_REL_NO_RMI/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:178:# ROUTER.md
test/gh353-vendored-router-audit.sh-179-## Role split
test/gh353-vendored-router-audit.sh:180:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-181-## Startup sequence
test/gh353-vendored-router-audit.sh:182:1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
test/gh353-vendored-router-audit.sh-183-MD
test/gh353-vendored-router-audit.sh-184-
test/gh353-vendored-router-audit.sh-185-out="$(python3 "$AUDIT_PY" --check "$R_REL_NO_RMI" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-186-ok "omitted ROADMAP.md role entry reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-188-# ── 5. Releases negative: obsolete dashboard in Role split ─────────────────────────
test/gh353-vendored-router-audit.sh-189-R_REL_OBSOLETE_DASH="$(mkrepo rel_obsolete_dash)"
test/gh353-vendored-router-audit.sh-190-require_fixture "$R_REL_OBSOLETE_DASH" "obsolete dash releases repo"
test/gh353-vendored-router-audit.sh-191-touch "$R_REL_OBSOLETE_DASH/releases.db"
test/gh353-vendored-router-audit.sh:192:cat > "$R_REL_OBSOLETE_DASH/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:193:# ROUTER.md
test/gh353-vendored-router-audit.sh-194-## Role split
test/gh353-vendored-router-audit.sh:195:- `ROADMAP-DASHBOARD.md` = obsolete; do not read
test/gh353-vendored-router-audit.sh-196-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (releases.db) is the source of truth
test/gh353-vendored-router-audit.sh-197-## Startup sequence
test/gh353-vendored-router-audit.sh:198:1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
test/gh353-vendored-router-audit.sh-199-MD
test/gh353-vendored-router-audit.sh-200-
test/gh353-vendored-router-audit.sh-201-out="$(python3 "$AUDIT_PY" --check "$R_REL_OBSOLETE_DASH" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-202-ok "obsolete dashboard declaration in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-204-# ── 6. Releases negative: historical archive dashboard in Role split ───────────────
test/gh353-vendored-router-audit.sh-205-R_REL_HIST_DASH="$(mkrepo rel_hist_dash)"
test/gh353-vendored-router-audit.sh-206-require_fixture "$R_REL_HIST_DASH" "hist dash releases repo"
test/gh353-vendored-router-audit.sh-207-touch "$R_REL_HIST_DASH/releases.db"
test/gh353-vendored-router-audit.sh:208:cat > "$R_REL_HIST_DASH/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:209:# ROUTER.md
test/gh353-vendored-router-audit.sh-210-## Role split
test/gh353-vendored-router-audit.sh:211:- `ROADMAP-DASHBOARD.md` = historical archive
test/gh353-vendored-router-audit.sh-212-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (releases.db) is the source of truth
test/gh353-vendored-router-audit.sh-213-## Startup sequence
test/gh353-vendored-router-audit.sh:214:1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
test/gh353-vendored-router-audit.sh-215-MD
test/gh353-vendored-router-audit.sh-216-
test/gh353-vendored-router-audit.sh-217-out="$(python3 "$AUDIT_PY" --check "$R_REL_HIST_DASH" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-218-ok "historical archive dashboard declaration in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-220-# ── 7. Releases negative: negated generated dashboard in Role split ────────────────
test/gh353-vendored-router-audit.sh-221-R_REL_NEG_GEN_DASH="$(mkrepo rel_neg_gen_dash)"
test/gh353-vendored-router-audit.sh-222-require_fixture "$R_REL_NEG_GEN_DASH" "neg gen dash releases repo"
test/gh353-vendored-router-audit.sh-223-touch "$R_REL_NEG_GEN_DASH/releases.db"
test/gh353-vendored-router-audit.sh:224:cat > "$R_REL_NEG_GEN_DASH/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:225:# ROUTER.md
test/gh353-vendored-router-audit.sh-226-## Role split
test/gh353-vendored-router-audit.sh:227:- `ROADMAP-DASHBOARD.md` = not generated; current view lives elsewhere
test/gh353-vendored-router-audit.sh-228-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (releases.db) is the source of truth
test/gh353-vendored-router-audit.sh-229-## Startup sequence
test/gh353-vendored-router-audit.sh:230:1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
test/gh353-vendored-router-audit.sh-231-MD
test/gh353-vendored-router-audit.sh-232-
test/gh353-vendored-router-audit.sh-233-out="$(python3 "$AUDIT_PY" --check "$R_REL_NEG_GEN_DASH" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-234-ok "negated generated dashboard declaration in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
test/gh353-vendored-router-audit.sh-235-
test/gh353-vendored-router-audit.sh:236:# ── 8. Releases negative: not a generated view in Role split ───────────────────────
test/gh353-vendored-router-audit.sh-237-R_REL_NOT_A_GEN="$(mkrepo rel_not_a_gen)"
test/gh353-vendored-router-audit.sh-238-require_fixture "$R_REL_NOT_A_GEN" "not a gen dash releases repo"
test/gh353-vendored-router-audit.sh-239-touch "$R_REL_NOT_A_GEN/releases.db"
test/gh353-vendored-router-audit.sh:240:cat > "$R_REL_NOT_A_GEN/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:241:# ROUTER.md
test/gh353-vendored-router-audit.sh-242-## Role split
test/gh353-vendored-router-audit.sh:243:- `ROADMAP-DASHBOARD.md` = not a generated view
test/gh353-vendored-router-audit.sh-244-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (releases.db) is the source of truth
test/gh353-vendored-router-audit.sh-245-## Startup sequence
test/gh353-vendored-router-audit.sh:246:1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
test/gh353-vendored-router-audit.sh-247-MD
test/gh353-vendored-router-audit.sh-248-
test/gh353-vendored-router-audit.sh-249-out="$(python3 "$AUDIT_PY" --check "$R_REL_NOT_A_GEN" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh:250:ok "not a generated view dashboard declaration in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
test/gh353-vendored-router-audit.sh-251-
test/gh353-vendored-router-audit.sh-252-# ── 9. Releases negative: generated deployment manifest in Role split ──────────────
test/gh353-vendored-router-audit.sh-253-R_REL_GEN_MANIFEST="$(mkrepo rel_gen_manifest)"
test/gh353-vendored-router-audit.sh-254-require_fixture "$R_REL_GEN_MANIFEST" "gen manifest releases repo"
test/gh353-vendored-router-audit.sh-255-touch "$R_REL_GEN_MANIFEST/releases.db"
test/gh353-vendored-router-audit.sh:256:cat > "$R_REL_GEN_MANIFEST/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:257:# ROUTER.md
test/gh353-vendored-router-audit.sh-258-## Role split
test/gh353-vendored-router-audit.sh:259:- `ROADMAP-DASHBOARD.md` = generated deployment manifest
test/gh353-vendored-router-audit.sh-260-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (releases.db) is the source of truth
test/gh353-vendored-router-audit.sh-261-## Startup sequence
test/gh353-vendored-router-audit.sh:262:1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
test/gh353-vendored-router-audit.sh-263-MD
test/gh353-vendored-router-audit.sh-264-
test/gh353-vendored-router-audit.sh-265-out="$(python3 "$AUDIT_PY" --check "$R_REL_GEN_MANIFEST" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-266-ok "generated deployment manifest in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-268-# ── 10. Releases negative: negated DB source of truth ──────────────────────────────
test/gh353-vendored-router-audit.sh-269-R_REL_NEG_DB_SOURCE="$(mkrepo rel_neg_db_source)"
test/gh353-vendored-router-audit.sh-270-require_fixture "$R_REL_NEG_DB_SOURCE" "neg db source releases repo"
test/gh353-vendored-router-audit.sh-271-touch "$R_REL_NEG_DB_SOURCE/releases.db"
test/gh353-vendored-router-audit.sh:272:cat > "$R_REL_NEG_DB_SOURCE/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:273:# ROUTER.md
test/gh353-vendored-router-audit.sh-274-## Role split
test/gh353-vendored-router-audit.sh:275:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-276-- `ROADMAP.md` = frozen legacy; releases.db is not the source of truth
test/gh353-vendored-router-audit.sh-277-## Startup sequence
test/gh353-vendored-router-audit.sh:278:1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
test/gh353-vendored-router-audit.sh-279-MD
test/gh353-vendored-router-audit.sh-280-
test/gh353-vendored-router-audit.sh-281-out="$(python3 "$AUDIT_PY" --check "$R_REL_NEG_DB_SOURCE" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-282-ok "negated DB source of truth in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-284-# ── 11. Releases negative: compatibility DB note ──────────────────────────────────
test/gh353-vendored-router-audit.sh-285-R_REL_COMPAT_DB="$(mkrepo rel_compat_db)"
test/gh353-vendored-router-audit.sh-286-require_fixture "$R_REL_COMPAT_DB" "compat db releases repo"
test/gh353-vendored-router-audit.sh-287-touch "$R_REL_COMPAT_DB/releases.db"
test/gh353-vendored-router-audit.sh:288:cat > "$R_REL_COMPAT_DB/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:289:# ROUTER.md
test/gh353-vendored-router-audit.sh-290-## Role split
test/gh353-vendored-router-audit.sh:291:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-292-- `ROADMAP.md` = frozen legacy; releases.db is present for compatibility
test/gh353-vendored-router-audit.sh-293-## Startup sequence
test/gh353-vendored-router-audit.sh:294:1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
test/gh353-vendored-router-audit.sh-295-MD
test/gh353-vendored-router-audit.sh-296-
test/gh353-vendored-router-audit.sh-297-out="$(python3 "$AUDIT_PY" --check "$R_REL_COMPAT_DB" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-298-ok "compatibility DB note without source of truth in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-300-# ── 12. Releases negative: mode token without DB source of truth ───────────────────
test/gh353-vendored-router-audit.sh-301-R_REL_MODE_TOKEN_ONLY="$(mkrepo rel_mode_token_only)"
test/gh353-vendored-router-audit.sh-302-require_fixture "$R_REL_MODE_TOKEN_ONLY" "mode token only repo"
test/gh353-vendored-router-audit.sh-303-touch "$R_REL_MODE_TOKEN_ONLY/releases.db"
test/gh353-vendored-router-audit.sh:304:cat > "$R_REL_MODE_TOKEN_ONLY/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:305:# ROUTER.md
test/gh353-vendored-router-audit.sh-306-## Role split
test/gh353-vendored-router-audit.sh:307:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-308-- `ROADMAP.md` = frozen legacy; ROADMAP_SOURCE=releases
test/gh353-vendored-router-audit.sh-309-## Startup sequence
test/gh353-vendored-router-audit.sh:310:1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
test/gh353-vendored-router-audit.sh-311-MD
test/gh353-vendored-router-audit.sh-312-
test/gh353-vendored-router-audit.sh-313-out="$(python3 "$AUDIT_PY" --check "$R_REL_MODE_TOKEN_ONLY" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-314-ok "mode token without DB source of truth in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-316-# ── 13. Releases negative: unrelated frozen subject on same line ──────────────────
test/gh353-vendored-router-audit.sh-317-R_REL_UNRELATED_FROZEN="$(mkrepo rel_unrelated_frozen)"
test/gh353-vendored-router-audit.sh-318-require_fixture "$R_REL_UNRELATED_FROZEN" "unrelated frozen repo"
test/gh353-vendored-router-audit.sh-319-touch "$R_REL_UNRELATED_FROZEN/releases.db"
test/gh353-vendored-router-audit.sh:320:cat > "$R_REL_UNRELATED_FROZEN/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:321:# ROUTER.md
test/gh353-vendored-router-audit.sh-322-## Role split
test/gh353-vendored-router-audit.sh:323:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-324-- `ROADMAP.md` = deployment notes; OLD-API.md is frozen; releases.db is the source of truth
test/gh353-vendored-router-audit.sh-325-## Startup sequence
test/gh353-vendored-router-audit.sh:326:1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
test/gh353-vendored-router-audit.sh-327-MD
test/gh353-vendored-router-audit.sh-328-
test/gh353-vendored-router-audit.sh-329-out="$(python3 "$AUDIT_PY" --check "$R_REL_UNRELATED_FROZEN" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-330-ok "unrelated frozen subject on same line in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-332-# ── 14. Releases negative: negated dashboard in Startup ────────────────────────────
test/gh353-vendored-router-audit.sh-333-R_REL_NEG_DASH="$(mkrepo rel_neg_dash)"
test/gh353-vendored-router-audit.sh-334-require_fixture "$R_REL_NEG_DASH" "neg dash releases repo"
test/gh353-vendored-router-audit.sh-335-touch "$R_REL_NEG_DASH/releases.db"
test/gh353-vendored-router-audit.sh:336:cat > "$R_REL_NEG_DASH/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:337:# ROUTER.md
test/gh353-vendored-router-audit.sh-338-## Role split
test/gh353-vendored-router-audit.sh:339:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-340-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
test/gh353-vendored-router-audit.sh-341-## Startup sequence
test/gh353-vendored-router-audit.sh:342:1. Do not read ROADMAP-DASHBOARD.md
test/gh353-vendored-router-audit.sh-343-MD
test/gh353-vendored-router-audit.sh-344-
test/gh353-vendored-router-audit.sh-345-out="$(python3 "$AUDIT_PY" --check "$R_REL_NEG_DASH" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-346-ok "negated dashboard read in Startup sequence reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-348-# ── 15. Releases negative: historical context dashboard in Startup ─────────────────
test/gh353-vendored-router-audit.sh-349-R_REL_HIST_STARTUP="$(mkrepo rel_hist_startup)"
test/gh353-vendored-router-audit.sh-350-require_fixture "$R_REL_HIST_STARTUP" "hist startup releases repo"
test/gh353-vendored-router-audit.sh-351-touch "$R_REL_HIST_STARTUP/releases.db"
test/gh353-vendored-router-audit.sh:352:cat > "$R_REL_HIST_STARTUP/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:353:# ROUTER.md
test/gh353-vendored-router-audit.sh-354-## Role split
test/gh353-vendored-router-audit.sh:355:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-356-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
test/gh353-vendored-router-audit.sh-357-## Startup sequence
test/gh353-vendored-router-audit.sh:358:1. Read ROADMAP-DASHBOARD.md for historical context
test/gh353-vendored-router-audit.sh-359-MD
test/gh353-vendored-router-audit.sh-360-
test/gh353-vendored-router-audit.sh-361-out="$(python3 "$AUDIT_PY" --check "$R_REL_HIST_STARTUP" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-362-ok "historical context dashboard directive in Startup reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-364-# ── 16. Releases negative: purpose-free dashboard in Startup ──────────────────────
test/gh353-vendored-router-audit.sh-365-R_REL_PURPOSE_FREE="$(mkrepo rel_purpose_free)"
test/gh353-vendored-router-audit.sh-366-require_fixture "$R_REL_PURPOSE_FREE" "purpose free releases repo"
test/gh353-vendored-router-audit.sh-367-touch "$R_REL_PURPOSE_FREE/releases.db"
test/gh353-vendored-router-audit.sh:368:cat > "$R_REL_PURPOSE_FREE/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:369:# ROUTER.md
test/gh353-vendored-router-audit.sh-370-## Role split
test/gh353-vendored-router-audit.sh:371:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-372-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
test/gh353-vendored-router-audit.sh-373-## Startup sequence
test/gh353-vendored-router-audit.sh:374:1. Read ROADMAP-DASHBOARD.md for deployment instructions
test/gh353-vendored-router-audit.sh-375-MD
test/gh353-vendored-router-audit.sh-376-
test/gh353-vendored-router-audit.sh-377-out="$(python3 "$AUDIT_PY" --check "$R_REL_PURPOSE_FREE" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-378-ok "purpose-free dashboard directive in Startup reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-380-# ── 17. Releases negative: purpose-free dashboard + unrelated current work ────────
test/gh353-vendored-router-audit.sh-381-R_REL_PF_UNRELATED="$(mkrepo rel_pf_unrelated)"
test/gh353-vendored-router-audit.sh-382-require_fixture "$R_REL_PF_UNRELATED" "pf unrelated releases repo"
test/gh353-vendored-router-audit.sh-383-touch "$R_REL_PF_UNRELATED/releases.db"
test/gh353-vendored-router-audit.sh:384:cat > "$R_REL_PF_UNRELATED/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:385:# ROUTER.md
test/gh353-vendored-router-audit.sh-386-## Role split
test/gh353-vendored-router-audit.sh:387:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-388-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
test/gh353-vendored-router-audit.sh-389-## Startup sequence
test/gh353-vendored-router-audit.sh:390:1. Read ROADMAP-DASHBOARD.md for deployment instructions; TEAM.md tracks current work
test/gh353-vendored-router-audit.sh-391-MD
test/gh353-vendored-router-audit.sh-392-
test/gh353-vendored-router-audit.sh-393-out="$(python3 "$AUDIT_PY" --check "$R_REL_PF_UNRELATED" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-394-ok "purpose-free dashboard + unrelated current work in Startup reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-396-# ── 18. Releases negative: not current state dashboard in Startup ──────────────────
test/gh353-vendored-router-audit.sh-397-R_REL_NOT_CURRENT_DASH="$(mkrepo rel_not_current_dash)"
test/gh353-vendored-router-audit.sh-398-require_fixture "$R_REL_NOT_CURRENT_DASH" "not current dash releases repo"
test/gh353-vendored-router-audit.sh-399-touch "$R_REL_NOT_CURRENT_DASH/releases.db"
test/gh353-vendored-router-audit.sh:400:cat > "$R_REL_NOT_CURRENT_DASH/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:401:# ROUTER.md
test/gh353-vendored-router-audit.sh-402-## Role split
test/gh353-vendored-router-audit.sh:403:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-404-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
test/gh353-vendored-router-audit.sh-405-## Startup sequence
test/gh353-vendored-router-audit.sh:406:1. Read ROADMAP-DASHBOARD.md for not current state
test/gh353-vendored-router-audit.sh-407-MD
test/gh353-vendored-router-audit.sh-408-
test/gh353-vendored-router-audit.sh-409-out="$(python3 "$AUDIT_PY" --check "$R_REL_NOT_CURRENT_DASH" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-410-ok "not current state dashboard directive in Startup reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-412-# ── 19. Releases negative: multi-clause active directive in Startup ────────────────
test/gh353-vendored-router-audit.sh-413-R_REL_MULTI_CLAUSE="$(mkrepo rel_multi_clause)"
test/gh353-vendored-router-audit.sh-414-require_fixture "$R_REL_MULTI_CLAUSE" "multi clause releases repo"
test/gh353-vendored-router-audit.sh-415-touch "$R_REL_MULTI_CLAUSE/releases.db"
test/gh353-vendored-router-audit.sh:416:cat > "$R_REL_MULTI_CLAUSE/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:417:# ROUTER.md
test/gh353-vendored-router-audit.sh-418-## Role split
test/gh353-vendored-router-audit.sh:419:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-420-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
test/gh353-vendored-router-audit.sh-421-## Startup sequence
test/gh353-vendored-router-audit.sh:422:1. Read `ROADMAP-DASHBOARD.md`.
test/gh353-vendored-router-audit.sh-423-2. ROADMAP.md is frozen for historical reference; nevertheless use ROADMAP.md for current work.
test/gh353-vendored-router-audit.sh-424-MD
test/gh353-vendored-router-audit.sh-425-
test/gh353-vendored-router-audit.sh-426-out="$(python3 "$AUDIT_PY" --check "$R_REL_MULTI_CLAUSE" 2>&1)"; rc=$?
--
test/gh353-vendored-router-audit.sh-429-# ── 20. Releases negative: historical first clause + active second clause ──────────
test/gh353-vendored-router-audit.sh-430-R_REL_HIST_ACTIVE_STARTUP="$(mkrepo rel_hist_active_startup)"
test/gh353-vendored-router-audit.sh-431-require_fixture "$R_REL_HIST_ACTIVE_STARTUP" "hist active startup releases repo"
test/gh353-vendored-router-audit.sh-432-touch "$R_REL_HIST_ACTIVE_STARTUP/releases.db"
test/gh353-vendored-router-audit.sh:433:cat > "$R_REL_HIST_ACTIVE_STARTUP/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:434:# ROUTER.md
test/gh353-vendored-router-audit.sh-435-## Role split
test/gh353-vendored-router-audit.sh:436:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-437-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
test/gh353-vendored-router-audit.sh-438-## Startup sequence
test/gh353-vendored-router-audit.sh:439:1. Read `ROADMAP-DASHBOARD.md`.
test/gh353-vendored-router-audit.sh-440-2. Read ROADMAP.md only for historical reference; nevertheless use ROADMAP.md for current work.
test/gh353-vendored-router-audit.sh-441-MD
test/gh353-vendored-router-audit.sh-442-
test/gh353-vendored-router-audit.sh-443-out="$(python3 "$AUDIT_PY" --check "$R_REL_HIST_ACTIVE_STARTUP" 2>&1)"; rc=$?
--
test/gh353-vendored-router-audit.sh-450-# ── 21. Releases negative: conjunction active directive in Startup ────────────────
test/gh353-vendored-router-audit.sh-451-R_REL_CONJ_STARTUP="$(mkrepo rel_conj_startup)"
test/gh353-vendored-router-audit.sh-452-require_fixture "$R_REL_CONJ_STARTUP" "conj startup releases repo"
test/gh353-vendored-router-audit.sh-453-touch "$R_REL_CONJ_STARTUP/releases.db"
test/gh353-vendored-router-audit.sh:454:cat > "$R_REL_CONJ_STARTUP/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:455:# ROUTER.md
test/gh353-vendored-router-audit.sh-456-## Role split
test/gh353-vendored-router-audit.sh:457:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-458-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
test/gh353-vendored-router-audit.sh-459-## Startup sequence
test/gh353-vendored-router-audit.sh:460:1. Read `ROADMAP-DASHBOARD.md`.
test/gh353-vendored-router-audit.sh-461-2. ROADMAP.md is frozen and use ROADMAP.md for current work.
test/gh353-vendored-router-audit.sh-462-MD
test/gh353-vendored-router-audit.sh-463-
test/gh353-vendored-router-audit.sh-464-out="$(python3 "$AUDIT_PY" --check "$R_REL_CONJ_STARTUP" 2>&1)"; rc=$?
--
test/gh353-vendored-router-audit.sh-467-# ── 22. Releases negative: while-connector active directive in Startup ─────────────
test/gh353-vendored-router-audit.sh-468-R_REL_WHILE_STARTUP="$(mkrepo rel_while_startup)"
test/gh353-vendored-router-audit.sh-469-require_fixture "$R_REL_WHILE_STARTUP" "while startup releases repo"
test/gh353-vendored-router-audit.sh-470-touch "$R_REL_WHILE_STARTUP/releases.db"
test/gh353-vendored-router-audit.sh:471:cat > "$R_REL_WHILE_STARTUP/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:472:# ROUTER.md
test/gh353-vendored-router-audit.sh-473-## Role split
test/gh353-vendored-router-audit.sh:474:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-475-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
test/gh353-vendored-router-audit.sh-476-## Startup sequence
test/gh353-vendored-router-audit.sh:477:1. Read `ROADMAP-DASHBOARD.md`.
test/gh353-vendored-router-audit.sh-478-2. ROADMAP.md is frozen while operators use ROADMAP.md for current work.
test/gh353-vendored-router-audit.sh-479-MD
test/gh353-vendored-router-audit.sh-480-
test/gh353-vendored-router-audit.sh-481-out="$(python3 "$AUDIT_PY" --check "$R_REL_WHILE_STARTUP" 2>&1)"; rc=$?
--
test/gh353-vendored-router-audit.sh-484-# ── 23. Releases negative: colon-form active keywords in Role split ────────────────
test/gh353-vendored-router-audit.sh-485-R_REL_COLON_ACTIVE="$(mkrepo rel_colon_active)"
test/gh353-vendored-router-audit.sh-486-require_fixture "$R_REL_COLON_ACTIVE" "colon active releases repo"
test/gh353-vendored-router-audit.sh-487-touch "$R_REL_COLON_ACTIVE/releases.db"
test/gh353-vendored-router-audit.sh:488:cat > "$R_REL_COLON_ACTIVE/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:489:# ROUTER.md
test/gh353-vendored-router-audit.sh-490-## Role split
test/gh353-vendored-router-audit.sh:491:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-492-ROADMAP.md: active; frozen legacy; releases.db is the source of truth
test/gh353-vendored-router-audit.sh-493-## Startup sequence
test/gh353-vendored-router-audit.sh:494:1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
test/gh353-vendored-router-audit.sh-495-MD
test/gh353-vendored-router-audit.sh-496-
test/gh353-vendored-router-audit.sh-497-out="$(python3 "$AUDIT_PY" --check "$R_REL_COLON_ACTIVE" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-498-ok "colon-form active keywords in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-500-# ── 24. Releases negative: negated legacy in Role split ───────────────────────────
test/gh353-vendored-router-audit.sh-501-R_REL_NOT_LEGACY="$(mkrepo rel_not_legacy)"
test/gh353-vendored-router-audit.sh-502-require_fixture "$R_REL_NOT_LEGACY" "not legacy releases repo"
test/gh353-vendored-router-audit.sh-503-touch "$R_REL_NOT_LEGACY/releases.db"
test/gh353-vendored-router-audit.sh:504:cat > "$R_REL_NOT_LEGACY/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:505:# ROUTER.md
test/gh353-vendored-router-audit.sh-506-## Role split
test/gh353-vendored-router-audit.sh:507:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-508-- `ROADMAP.md` = not legacy; releases.db is source of truth
test/gh353-vendored-router-audit.sh-509-## Startup sequence
test/gh353-vendored-router-audit.sh:510:1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
test/gh353-vendored-router-audit.sh-511-MD
test/gh353-vendored-router-audit.sh-512-
test/gh353-vendored-router-audit.sh-513-out="$(python3 "$AUDIT_PY" --check "$R_REL_NOT_LEGACY" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-514-ok "negated legacy in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-516-# ── 25. Releases negative: prose active ROADMAP in Role split ──────────────────────
test/gh353-vendored-router-audit.sh-517-R_REL_PROSE_ROLE="$(mkrepo rel_prose_role)"
test/gh353-vendored-router-audit.sh-518-require_fixture "$R_REL_PROSE_ROLE" "prose role releases repo"
test/gh353-vendored-router-audit.sh-519-touch "$R_REL_PROSE_ROLE/releases.db"
test/gh353-vendored-router-audit.sh:520:cat > "$R_REL_PROSE_ROLE/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:521:# ROUTER.md
test/gh353-vendored-router-audit.sh-522-## Role split
test/gh353-vendored-router-audit.sh:523:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-524-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
test/gh353-vendored-router-audit.sh-525-ROADMAP.md is used for current priorities
test/gh353-vendored-router-audit.sh-526-## Startup sequence
test/gh353-vendored-router-audit.sh:527:1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
test/gh353-vendored-router-audit.sh-528-MD
test/gh353-vendored-router-audit.sh-529-
test/gh353-vendored-router-audit.sh-530-out="$(python3 "$AUDIT_PY" --check "$R_REL_PROSE_ROLE" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-531-ok "prose active ROADMAP in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-533-# ── 26. Releases negative: prefixed prose active ROADMAP in Role split ────────────
test/gh353-vendored-router-audit.sh-534-R_REL_PREFIX_PROSE="$(mkrepo rel_prefix_prose)"
test/gh353-vendored-router-audit.sh-535-require_fixture "$R_REL_PREFIX_PROSE" "prefix prose releases repo"
test/gh353-vendored-router-audit.sh-536-touch "$R_REL_PREFIX_PROSE/releases.db"
test/gh353-vendored-router-audit.sh:537:cat > "$R_REL_PREFIX_PROSE/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:538:# ROUTER.md
test/gh353-vendored-router-audit.sh-539-## Role split
test/gh353-vendored-router-audit.sh:540:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-541-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
test/gh353-vendored-router-audit.sh-542-Note: ROADMAP.md is used for current priorities
test/gh353-vendored-router-audit.sh-543-## Startup sequence
test/gh353-vendored-router-audit.sh:544:1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
test/gh353-vendored-router-audit.sh-545-MD
test/gh353-vendored-router-audit.sh-546-
test/gh353-vendored-router-audit.sh-547-out="$(python3 "$AUDIT_PY" --check "$R_REL_PREFIX_PROSE" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-548-ok "prefixed prose active ROADMAP in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-554-# ── 27. Releases negative: compound custom entry + active prose in Role split ─────
test/gh353-vendored-router-audit.sh-555-R_REL_COMPOUND_ROLE="$(mkrepo rel_compound_role)"
test/gh353-vendored-router-audit.sh-556-require_fixture "$R_REL_COMPOUND_ROLE" "compound role releases repo"
test/gh353-vendored-router-audit.sh-557-touch "$R_REL_COMPOUND_ROLE/releases.db"
test/gh353-vendored-router-audit.sh:558:cat > "$R_REL_COMPOUND_ROLE/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:559:# ROUTER.md
test/gh353-vendored-router-audit.sh-560-## Role split
test/gh353-vendored-router-audit.sh:561:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-562-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (releases.db) is the source of truth
test/gh353-vendored-router-audit.sh-563-- `PROJECT/PDDA.md` = governs the `ROADMAP.md` contract; `ROADMAP.md` is used for current work
test/gh353-vendored-router-audit.sh-564-## Startup sequence
test/gh353-vendored-router-audit.sh:565:1. Read `ROADMAP-DASHBOARD.md` to find active effort. (ROADMAP.md is frozen legacy.)
test/gh353-vendored-router-audit.sh-566-MD
test/gh353-vendored-router-audit.sh-567-
test/gh353-vendored-router-audit.sh-568-out="$(python3 "$AUDIT_PY" --check "$R_REL_COMPOUND_ROLE" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-569-ok "compound custom entry + active prose in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
test/gh353-vendored-router-audit.sh-570-
test/gh353-vendored-router-audit.sh-571-python3 "$AUDIT_PY" --fix "$R_REL_COMPOUND_ROLE" >/dev/null
test/gh353-vendored-router-audit.sh-572-out_comp_fix="$(python3 "$AUDIT_PY" --check "$R_REL_COMPOUND_ROLE" 2>&1)"; rc_cf=$?
test/gh353-vendored-router-audit.sh-573-ok "compound custom entry fixed and passes audit (rc=0)" "$(is "$rc_cf" "0"; echo $?)"
test/gh353-vendored-router-audit.sh:574:comp_content="$(cat "$R_REL_COMPOUND_ROLE/ROUTER.md")"
test/gh353-vendored-router-audit.sh-575-ok "compound fix preserved governance clause" "$(has "$comp_content" "governs the \`ROADMAP.md\` contract"; echo $?)"
test/gh353-vendored-router-audit.sh-576-ok "compound fix removed stray active clause" "$(! has "$comp_content" "is used for current work"; echo $?)"
test/gh353-vendored-router-audit.sh-577-
test/gh353-vendored-router-audit.sh-578-# ── 28. Releases negative: asterisk list marker in Role split ──────────────────────
test/gh353-vendored-router-audit.sh-579-R_REL_ASTERISK="$(mkrepo rel_asterisk)"
test/gh353-vendored-router-audit.sh-580-require_fixture "$R_REL_ASTERISK" "asterisk releases repo"
test/gh353-vendored-router-audit.sh-581-touch "$R_REL_ASTERISK/releases.db"
test/gh353-vendored-router-audit.sh:582:cat > "$R_REL_ASTERISK/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:583:# ROUTER.md
test/gh353-vendored-router-audit.sh-584-## Role split
test/gh353-vendored-router-audit.sh:585:* `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-586-* `ROADMAP.md` = active pointer ledger
test/gh353-vendored-router-audit.sh-587-## Startup sequence
test/gh353-vendored-router-audit.sh:588:1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
test/gh353-vendored-router-audit.sh-589-MD
test/gh353-vendored-router-audit.sh-590-
test/gh353-vendored-router-audit.sh-591-out="$(python3 "$AUDIT_PY" --check "$R_REL_ASTERISK" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-592-ok "asterisk-marker active ROADMAP.md declaration in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-594-# ── 29. Releases negative: Startup sequence with Open verb ─────────────────────────
test/gh353-vendored-router-audit.sh-595-R_REL_OPEN_STARTUP="$(mkrepo rel_open_startup)"
test/gh353-vendored-router-audit.sh-596-require_fixture "$R_REL_OPEN_STARTUP" "open startup releases repo"
test/gh353-vendored-router-audit.sh-597-touch "$R_REL_OPEN_STARTUP/releases.db"
test/gh353-vendored-router-audit.sh:598:cat > "$R_REL_OPEN_STARTUP/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:599:# ROUTER.md
test/gh353-vendored-router-audit.sh-600-## Role split
test/gh353-vendored-router-audit.sh:601:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-602-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
test/gh353-vendored-router-audit.sh-603-## Startup sequence
test/gh353-vendored-router-audit.sh-604-1. Open ROADMAP.md to find current work.
test/gh353-vendored-router-audit.sh:605:2. Read ROADMAP-DASHBOARD.md
test/gh353-vendored-router-audit.sh-606-MD
test/gh353-vendored-router-audit.sh-607-
test/gh353-vendored-router-audit.sh-608-out="$(python3 "$AUDIT_PY" --check "$R_REL_OPEN_STARTUP" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-609-ok "Startup sequence with Open ROADMAP.md reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-611-# ── 30. Releases negative: Startup sequence with Consult verb ──────────────────────
test/gh353-vendored-router-audit.sh-612-R_REL_CONSULT_STARTUP="$(mkrepo rel_consult_startup)"
test/gh353-vendored-router-audit.sh-613-require_fixture "$R_REL_CONSULT_STARTUP" "consult startup releases repo"
test/gh353-vendored-router-audit.sh-614-touch "$R_REL_CONSULT_STARTUP/releases.db"
test/gh353-vendored-router-audit.sh:615:cat > "$R_REL_CONSULT_STARTUP/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:616:# ROUTER.md
test/gh353-vendored-router-audit.sh-617-## Role split
test/gh353-vendored-router-audit.sh:618:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-619-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
test/gh353-vendored-router-audit.sh-620-## Startup sequence
test/gh353-vendored-router-audit.sh-621-- Consult ROADMAP.md first
test/gh353-vendored-router-audit.sh:622:- Check ROADMAP-DASHBOARD.md
test/gh353-vendored-router-audit.sh-623-MD
test/gh353-vendored-router-audit.sh-624-
test/gh353-vendored-router-audit.sh-625-out="$(python3 "$AUDIT_PY" --check "$R_REL_CONSULT_STARTUP" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-626-ok "Startup sequence with Consult ROADMAP.md reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-628-# ── 31. Releases negative: Startup sequence with Use verb ──────────────────────────
test/gh353-vendored-router-audit.sh-629-R_REL_USE_STARTUP="$(mkrepo rel_use_startup)"
test/gh353-vendored-router-audit.sh-630-require_fixture "$R_REL_USE_STARTUP" "use startup releases repo"
test/gh353-vendored-router-audit.sh-631-touch "$R_REL_USE_STARTUP/releases.db"
test/gh353-vendored-router-audit.sh:632:cat > "$R_REL_USE_STARTUP/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:633:# ROUTER.md
test/gh353-vendored-router-audit.sh-634-## Role split
test/gh353-vendored-router-audit.sh:635:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-636-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
test/gh353-vendored-router-audit.sh-637-## Startup sequence
test/gh353-vendored-router-audit.sh-638-1. Use ROADMAP.md for current work.
test/gh353-vendored-router-audit.sh:639:2. Read ROADMAP-DASHBOARD.md
test/gh353-vendored-router-audit.sh-640-MD
test/gh353-vendored-router-audit.sh-641-
test/gh353-vendored-router-audit.sh-642-out="$(python3 "$AUDIT_PY" --check "$R_REL_USE_STARTUP" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-643-ok "Startup sequence with Use ROADMAP.md for current work reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-645-# ── 32. Releases negative: Startup sequence with negated frozen phrase ─────────────
test/gh353-vendored-router-audit.sh-646-R_REL_NOT_FROZEN_STARTUP="$(mkrepo rel_not_frozen_startup)"
test/gh353-vendored-router-audit.sh-647-require_fixture "$R_REL_NOT_FROZEN_STARTUP" "not frozen startup releases repo"
test/gh353-vendored-router-audit.sh-648-touch "$R_REL_NOT_FROZEN_STARTUP/releases.db"
test/gh353-vendored-router-audit.sh:649:cat > "$R_REL_NOT_FROZEN_STARTUP/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:650:# ROUTER.md
test/gh353-vendored-router-audit.sh-651-## Role split
test/gh353-vendored-router-audit.sh:652:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-653-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
test/gh353-vendored-router-audit.sh-654-## Startup sequence
test/gh353-vendored-router-audit.sh-655-1. ROADMAP.md is not frozen; use it for current work.
test/gh353-vendored-router-audit.sh:656:2. Read ROADMAP-DASHBOARD.md
test/gh353-vendored-router-audit.sh-657-MD
test/gh353-vendored-router-audit.sh-658-
test/gh353-vendored-router-audit.sh-659-out="$(python3 "$AUDIT_PY" --check "$R_REL_NOT_FROZEN_STARTUP" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-660-ok "Startup sequence saying ROADMAP.md is not frozen reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-662-# ── 33. Releases negative: Startup sequence with markdown link ────────────────────
test/gh353-vendored-router-audit.sh-663-R_REL_LINK_STARTUP="$(mkrepo rel_link_startup)"
test/gh353-vendored-router-audit.sh-664-require_fixture "$R_REL_LINK_STARTUP" "link startup releases repo"
test/gh353-vendored-router-audit.sh-665-touch "$R_REL_LINK_STARTUP/releases.db"
test/gh353-vendored-router-audit.sh:666:cat > "$R_REL_LINK_STARTUP/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:667:# ROUTER.md
test/gh353-vendored-router-audit.sh-668-## Role split
test/gh353-vendored-router-audit.sh:669:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-670-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
test/gh353-vendored-router-audit.sh-671-## Startup sequence
test/gh353-vendored-router-audit.sh-672-1. See [ROADMAP.md](PROJECT/ROADMAP.md) for active items.
test/gh353-vendored-router-audit.sh:673:2. Read ROADMAP-DASHBOARD.md
test/gh353-vendored-router-audit.sh-674-MD
test/gh353-vendored-router-audit.sh-675-
test/gh353-vendored-router-audit.sh-676-out="$(python3 "$AUDIT_PY" --check "$R_REL_LINK_STARTUP" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-677-ok "Startup sequence with markdown link to ROADMAP.md reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
--
test/gh353-vendored-router-audit.sh-679-# ── 34. Releases negative: missing Startup sequence section ─────────────────────────
test/gh353-vendored-router-audit.sh-680-R_REL_NO_START="$(mkrepo rel_no_start)"
test/gh353-vendored-router-audit.sh-681-require_fixture "$R_REL_NO_START" "no start releases repo"
test/gh353-vendored-router-audit.sh-682-touch "$R_REL_NO_START/releases.db"
test/gh353-vendored-router-audit.sh:683:cat > "$R_REL_NO_START/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:684:# ROUTER.md
test/gh353-vendored-router-audit.sh-685-## Role split
test/gh353-vendored-router-audit.sh:686:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-687-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
test/gh353-vendored-router-audit.sh-688-MD
test/gh353-vendored-router-audit.sh-689-
test/gh353-vendored-router-audit.sh-690-out="$(python3 "$AUDIT_PY" --check "$R_REL_NO_START" 2>&1)"; rc=$?
--
test/gh353-vendored-router-audit.sh-693-# ── 35. Releases negative: duplicate sections ─────────────────────────────────────
test/gh353-vendored-router-audit.sh-694-R_REL_DUP_SECT="$(mkrepo rel_dup_sect)"
test/gh353-vendored-router-audit.sh-695-require_fixture "$R_REL_DUP_SECT" "dup sect releases repo"
test/gh353-vendored-router-audit.sh-696-touch "$R_REL_DUP_SECT/releases.db"
test/gh353-vendored-router-audit.sh:697:cat > "$R_REL_DUP_SECT/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:698:# ROUTER.md
test/gh353-vendored-router-audit.sh-699-## Role split
test/gh353-vendored-router-audit.sh:700:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-701-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
test/gh353-vendored-router-audit.sh-702-## Startup sequence
test/gh353-vendored-router-audit.sh:703:1. Read ROADMAP-DASHBOARD.md
test/gh353-vendored-router-audit.sh-704-## Role split
test/gh353-vendored-router-audit.sh-705-- `ROADMAP.md` = active work
test/gh353-vendored-router-audit.sh-706-## Startup sequence
test/gh353-vendored-router-audit.sh-707-1. Read ROADMAP.md
--
test/gh353-vendored-router-audit.sh-713-# ── 36. Releases clean valid custom mention passes audit and is preserved ──────────
test/gh353-vendored-router-audit.sh-714-R_REL_PDDA_CUSTOM="$(mkrepo rel_pdda_custom)"
test/gh353-vendored-router-audit.sh-715-require_fixture "$R_REL_PDDA_CUSTOM" "pdda custom releases repo"
test/gh353-vendored-router-audit.sh-716-touch "$R_REL_PDDA_CUSTOM/releases.db"
test/gh353-vendored-router-audit.sh:717:cat > "$R_REL_PDDA_CUSTOM/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:718:# ROUTER.md
test/gh353-vendored-router-audit.sh-719-## Role split
test/gh353-vendored-router-audit.sh:720:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-721-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (`releases.db`) is the source of truth
test/gh353-vendored-router-audit.sh-722-- `PROJECT/PDDA.md` = governs the `ROADMAP.md` contract
test/gh353-vendored-router-audit.sh-723-## Startup sequence
test/gh353-vendored-router-audit.sh:724:1. Read `ROADMAP-DASHBOARD.md` to find active effort. (`ROADMAP.md` is frozen legacy.)
test/gh353-vendored-router-audit.sh-725-MD
test/gh353-vendored-router-audit.sh-726-
test/gh353-vendored-router-audit.sh-727-out="$(python3 "$AUDIT_PY" --check "$R_REL_PDDA_CUSTOM" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-728-ok "valid custom PDDA entry mentioning ROADMAP.md passes releases audit (rc=0)" "$(is "$rc" "0"; echo $?)"
test/gh353-vendored-router-audit.sh-729-
test/gh353-vendored-router-audit.sh-730-python3 "$AUDIT_PY" --fix "$R_REL_PDDA_CUSTOM" >/dev/null
test/gh353-vendored-router-audit.sh:731:pdda_content="$(cat "$R_REL_PDDA_CUSTOM/ROUTER.md")"
test/gh353-vendored-router-audit.sh-732-ok "releases --fix preserved custom PROJECT/PDDA.md entry" "$(has "$pdda_content" "PROJECT/PDDA.md"; echo $?)"
test/gh353-vendored-router-audit.sh-733-
test/gh353-vendored-router-audit.sh-734-# ── 37. Releases clean valid custom startup step preserved byte-for-byte ──────────
test/gh353-vendored-router-audit.sh-735-R_REL_CUSTOM_STEP="$(mkrepo rel_custom_step)"
test/gh353-vendored-router-audit.sh-736-require_fixture "$R_REL_CUSTOM_STEP" "custom step releases repo"
test/gh353-vendored-router-audit.sh-737-touch "$R_REL_CUSTOM_STEP/releases.db"
test/gh353-vendored-router-audit.sh:738:cat > "$R_REL_CUSTOM_STEP/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:739:# ROUTER.md
test/gh353-vendored-router-audit.sh-740-## Role split
test/gh353-vendored-router-audit.sh-741-- `ROADMAP.md` = active pointer ledger
test/gh353-vendored-router-audit.sh-742-## Startup sequence
test/gh353-vendored-router-audit.sh:743:1. Read ROUTER.md
test/gh353-vendored-router-audit.sh-744-2. Read AGENTS.md
test/gh353-vendored-router-audit.sh-745-3. Read ROADMAP.md
test/gh353-vendored-router-audit.sh-746-4. Read `PROJECT/PDDA.md` for the `ROADMAP.md` governance contract.
test/gh353-vendored-router-audit.sh-747-MD
test/gh353-vendored-router-audit.sh-748-
test/gh353-vendored-router-audit.sh-749-# Save custom step 4
test/gh353-vendored-router-audit.sh-750-python3 -c "
test/gh353-vendored-router-audit.sh:751:with open('$R_REL_CUSTOM_STEP/ROUTER.md', 'rb') as f:
test/gh353-vendored-router-audit.sh-752-    data = f.read()
test/gh353-vendored-router-audit.sh-753-start = data.find(b'4. Read ' + b'\x60PROJECT/PDDA.md\x60')
test/gh353-vendored-router-audit.sh-754-with open('$WORK/custom_step_exp.bin', 'wb') as out:
test/gh353-vendored-router-audit.sh-755-    out.write(data[start:])
--
test/gh353-vendored-router-audit.sh-759-out_cs="$(python3 "$AUDIT_PY" --check "$R_REL_CUSTOM_STEP" 2>&1)"; rc_cs=$?
test/gh353-vendored-router-audit.sh-760-ok "releases repo with custom startup step fixed and passes audit (rc=0)" "$(is "$rc_cs" "0"; echo $?)"
test/gh353-vendored-router-audit.sh-761-
test/gh353-vendored-router-audit.sh-762-python3 -c "
test/gh353-vendored-router-audit.sh:763:with open('$R_REL_CUSTOM_STEP/ROUTER.md', 'rb') as f:
test/gh353-vendored-router-audit.sh-764-    data = f.read()
test/gh353-vendored-router-audit.sh-765-start = data.find(b'4. Read ' + b'\x60PROJECT/PDDA.md\x60')
test/gh353-vendored-router-audit.sh-766-with open('$WORK/custom_step_act.bin', 'wb') as out:
test/gh353-vendored-router-audit.sh-767-    out.write(data[start:])
--
test/gh353-vendored-router-audit.sh-772-# ── 38. Releases clean valid historical read preserved byte-for-byte ──────────────
test/gh353-vendored-router-audit.sh-773-R_REL_HIST_READ="$(mkrepo rel_hist_read)"
test/gh353-vendored-router-audit.sh-774-require_fixture "$R_REL_HIST_READ" "hist read releases repo"
test/gh353-vendored-router-audit.sh-775-touch "$R_REL_HIST_READ/releases.db"
test/gh353-vendored-router-audit.sh:776:cat > "$R_REL_HIST_READ/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:777:# ROUTER.md
test/gh353-vendored-router-audit.sh-778-## Role split
test/gh353-vendored-router-audit.sh:779:- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger
test/gh353-vendored-router-audit.sh-780-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (releases.db) is the source of truth
test/gh353-vendored-router-audit.sh-781-## Startup sequence
test/gh353-vendored-router-audit.sh:782:1. Read ROUTER.md
test/gh353-vendored-router-audit.sh:783:2. Read `ROADMAP-DASHBOARD.md` to find active effort.
test/gh353-vendored-router-audit.sh-784-3. Read ROADMAP.md only for historical reference.
test/gh353-vendored-router-audit.sh-785-MD
test/gh353-vendored-router-audit.sh-786-
test/gh353-vendored-router-audit.sh-787-out="$(python3 "$AUDIT_PY" --check "$R_REL_HIST_READ" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-788-ok "valid historical read 'Read ROADMAP.md only for historical reference' passes releases audit (rc=0)" "$(is "$rc" "0"; echo $?)"
test/gh353-vendored-router-audit.sh-789-
test/gh353-vendored-router-audit.sh-790-python3 "$AUDIT_PY" --fix "$R_REL_HIST_READ" >/dev/null
test/gh353-vendored-router-audit.sh:791:hist_content="$(cat "$R_REL_HIST_READ/ROUTER.md")"
test/gh353-vendored-router-audit.sh-792-ok "releases --fix preserved historical read line" "$(has "$hist_content" "only for historical reference"; echo $?)"
test/gh353-vendored-router-audit.sh-793-
test/gh353-vendored-router-audit.sh-794-# ── 39. Releases clean valid negations pass audit ──────────────────────────────────
test/gh353-vendored-router-audit.sh-795-R_REL_VALID_NEG="$(mkrepo rel_valid_neg)"
test/gh353-vendored-router-audit.sh-796-require_fixture "$R_REL_VALID_NEG" "valid neg releases repo"
test/gh353-vendored-router-audit.sh-797-touch "$R_REL_VALID_NEG/releases.db"
test/gh353-vendored-router-audit.sh:798:cat > "$R_REL_VALID_NEG/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:799:# ROUTER.md
test/gh353-vendored-router-audit.sh-800-## Role split
test/gh353-vendored-router-audit.sh:801:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-802-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (releases.db) is the source of truth
test/gh353-vendored-router-audit.sh-803-## Startup sequence
test/gh353-vendored-router-audit.sh:804:1. Read `ROADMAP-DASHBOARD.md` to find active effort.
test/gh353-vendored-router-audit.sh-805-2. ROADMAP.md is frozen; do not use it for current work.
test/gh353-vendored-router-audit.sh-806-MD
test/gh353-vendored-router-audit.sh-807-
test/gh353-vendored-router-audit.sh-808-out="$(python3 "$AUDIT_PY" --check "$R_REL_VALID_NEG" 2>&1)"; rc=$?
--
test/gh353-vendored-router-audit.sh-811-# ── 40. Releases clean valid fenced code blocks ────────────────────────────────────
test/gh353-vendored-router-audit.sh-812-R_REL_FENCED="$(mkrepo rel_fenced)"
test/gh353-vendored-router-audit.sh-813-require_fixture "$R_REL_FENCED" "fenced code releases repo"
test/gh353-vendored-router-audit.sh-814-touch "$R_REL_FENCED/releases.db"
test/gh353-vendored-router-audit.sh:815:cat > "$R_REL_FENCED/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:816:# ROUTER.md
test/gh353-vendored-router-audit.sh-817-## Role split
test/gh353-vendored-router-audit.sh:818:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-819-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (releases.db) is the source of truth
test/gh353-vendored-router-audit.sh-820-
test/gh353-vendored-router-audit.sh-821-```markdown
test/gh353-vendored-router-audit.sh-822-## Role split
--
test/gh353-vendored-router-audit.sh-825-1. Read `ROADMAP.md` inside fence
test/gh353-vendored-router-audit.sh-826-```
test/gh353-vendored-router-audit.sh-827-
test/gh353-vendored-router-audit.sh-828-## Startup sequence
test/gh353-vendored-router-audit.sh:829:1. Read `ROADMAP-DASHBOARD.md` to find active effort. (ROADMAP.md is frozen legacy.)
test/gh353-vendored-router-audit.sh-830-MD
test/gh353-vendored-router-audit.sh-831-
test/gh353-vendored-router-audit.sh-832-out="$(python3 "$AUDIT_PY" --check "$R_REL_FENCED" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-833-ok "clean repo with ## headings inside code fences passes audit (rc=0)" "$(is "$rc" "0"; echo $?)"
--
test/gh353-vendored-router-audit.sh-835-# ── 41. Releases --fix: collapses duplicate roadmap steps in Startup ───────────────
test/gh353-vendored-router-audit.sh-836-R_REL_DUP="$(mkrepo rel_dup)"
test/gh353-vendored-router-audit.sh-837-require_fixture "$R_REL_DUP" "dup releases repo"
test/gh353-vendored-router-audit.sh-838-touch "$R_REL_DUP/releases.db"
test/gh353-vendored-router-audit.sh:839:cat > "$R_REL_DUP/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:840:# ROUTER.md
test/gh353-vendored-router-audit.sh-841-## Role split
test/gh353-vendored-router-audit.sh-842-- `ROADMAP.md` = active work
test/gh353-vendored-router-audit.sh-843-## Startup sequence
test/gh353-vendored-router-audit.sh:844:1. Read ROUTER.md
test/gh353-vendored-router-audit.sh-845-2. Open ROADMAP.md to find current work.
test/gh353-vendored-router-audit.sh-846-3. Consult [ROADMAP.md](ROADMAP.md) for items.
test/gh353-vendored-router-audit.sh:847:4. Read ROADMAP-DASHBOARD.md
test/gh353-vendored-router-audit.sh-848-MD
test/gh353-vendored-router-audit.sh-849-
test/gh353-vendored-router-audit.sh-850-python3 "$AUDIT_PY" --fix "$R_REL_DUP" >/dev/null
test/gh353-vendored-router-audit.sh-851-out_dup_check="$(python3 "$AUDIT_PY" --check "$R_REL_DUP" 2>&1)"; rc_dup=$?
test/gh353-vendored-router-audit.sh-852-ok "dup roadmap steps fixed and passes audit (rc=0)" "$(is "$rc_dup" "0"; echo $?)"
test/gh353-vendored-router-audit.sh:853:dup_count="$(grep -c "ROADMAP-DASHBOARD.md" "$R_REL_DUP/ROUTER.md")"
test/gh353-vendored-router-audit.sh-854-ok "Startup sequence collapsed duplicate directives to 1 canonical step" "$(is "$dup_count" "2"; echo $?)"
test/gh353-vendored-router-audit.sh-855-
test/gh353-vendored-router-audit.sh-856-# ── 42. Releases --fix: removes duplicate sections down to exactly 1 each ──────────
test/gh353-vendored-router-audit.sh-857-python3 "$AUDIT_PY" --fix "$R_REL_DUP_SECT" >/dev/null
test/gh353-vendored-router-audit.sh-858-out_dup_sect_check="$(python3 "$AUDIT_PY" --check "$R_REL_DUP_SECT" 2>&1)"; rc_dup_sect=$?
test/gh353-vendored-router-audit.sh-859-ok "duplicate sections fixed and passes audit (rc=0)" "$(is "$rc_dup_sect" "0"; echo $?)"
test/gh353-vendored-router-audit.sh:860:role_sect_count="$(grep -c "## Role split" "$R_REL_DUP_SECT/ROUTER.md")"
test/gh353-vendored-router-audit.sh:861:start_sect_count="$(grep -c "## Startup sequence" "$R_REL_DUP_SECT/ROUTER.md")"
test/gh353-vendored-router-audit.sh:862:ok "fixed ROUTER.md has exactly 1 ## Role split" "$(is "$role_sect_count" "1"; echo $?)"
test/gh353-vendored-router-audit.sh:863:ok "fixed ROUTER.md has exactly 1 ## Startup sequence" "$(is "$start_sect_count" "1"; echo $?)"
test/gh353-vendored-router-audit.sh-864-
test/gh353-vendored-router-audit.sh-865-# ── 43. Releases --fix: preserves prefixed custom sections byte-for-byte ───────────
test/gh353-vendored-router-audit.sh-866-R_REL_PREFIXED_CUSTOM="$(mkrepo rel_prefixed_custom)"
test/gh353-vendored-router-audit.sh-867-require_fixture "$R_REL_PREFIXED_CUSTOM" "prefixed custom repo"
test/gh353-vendored-router-audit.sh-868-touch "$R_REL_PREFIXED_CUSTOM/releases.db"
test/gh353-vendored-router-audit.sh:869:cat > "$R_REL_PREFIXED_CUSTOM/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:870:# ROUTER.md
test/gh353-vendored-router-audit.sh-871-## Role split rationale
test/gh353-vendored-router-audit.sh-872-Rationale notes here: $CUSTOM_PARAM = 100!
test/gh353-vendored-router-audit.sh-873-## Role split
test/gh353-vendored-router-audit.sh-874-- `ROADMAP.md` = active work
--
test/gh353-vendored-router-audit.sh-879-MD
test/gh353-vendored-router-audit.sh-880-
test/gh353-vendored-router-audit.sh-881-# Save custom section slices before fix
test/gh353-vendored-router-audit.sh-882-python3 -c "
test/gh353-vendored-router-audit.sh:883:with open('$R_REL_PREFIXED_CUSTOM/ROUTER.md', 'rb') as f:
test/gh353-vendored-router-audit.sh-884-    data = f.read()
test/gh353-vendored-router-audit.sh-885-s1_start = data.find(b'## Role split rationale')
test/gh353-vendored-router-audit.sh-886-s1_end = data.find(b'## Role split\n')
test/gh353-vendored-router-audit.sh-887-s2_start = data.find(b'## Startup sequence notes')
--
test/gh353-vendored-router-audit.sh-896-out_pref_check="$(python3 "$AUDIT_PY" --check "$R_REL_PREFIXED_CUSTOM" 2>&1)"; rc_pref=$?
test/gh353-vendored-router-audit.sh-897-ok "prefixed custom sections repo fixed and passes audit (rc=0)" "$(is "$rc_pref" "0"; echo $?)"
test/gh353-vendored-router-audit.sh-898-
test/gh353-vendored-router-audit.sh-899-python3 -c "
test/gh353-vendored-router-audit.sh:900:with open('$R_REL_PREFIXED_CUSTOM/ROUTER.md', 'rb') as f:
test/gh353-vendored-router-audit.sh-901-    data = f.read()
test/gh353-vendored-router-audit.sh-902-s1_start = data.find(b'## Role split rationale')
test/gh353-vendored-router-audit.sh-903-s1_end = data.find(b'## Role split\n')
test/gh353-vendored-router-audit.sh-904-s2_start = data.find(b'## Startup sequence notes')
--
test/gh353-vendored-router-audit.sh-920-touch "$R_REL_CRLF/releases.db"
test/gh353-vendored-router-audit.sh-921-
test/gh353-vendored-router-audit.sh-922-CUSTOM_CRLF_TEXT="## Custom Section\r\nExact custom text with CRLF line endings: \$SPECIAL \`code\`!\r\n"
test/gh353-vendored-router-audit.sh-923-
test/gh353-vendored-router-audit.sh:924:printf "# ROUTER.md\r\n\r\n## Role split\r\n- \`ROADMAP.md\` = active pointer ledger\r\n\r\n%b\r\n## Startup sequence\r\n1. Consult ROADMAP.md to find current tasks.\r\n" "$CUSTOM_CRLF_TEXT" > "$R_REL_CRLF/ROUTER.md"
test/gh353-vendored-router-audit.sh-925-
test/gh353-vendored-router-audit.sh-926-# Save custom section slice before fix
test/gh353-vendored-router-audit.sh-927-python3 -c "
test/gh353-vendored-router-audit.sh:928:with open('$R_REL_CRLF/ROUTER.md', 'rb') as f:
test/gh353-vendored-router-audit.sh-929-    data = f.read()
test/gh353-vendored-router-audit.sh-930-start = data.find(b'## Custom Section')
test/gh353-vendored-router-audit.sh-931-end = data.find(b'## Startup sequence')
test/gh353-vendored-router-audit.sh-932-with open('$WORK/custom_expected.bin', 'wb') as out:
--
test/gh353-vendored-router-audit.sh-940-ok "after --fix, CRLF repo passes audit with rc=0" "$(is "$rc_after" "0"; echo $?)"
test/gh353-vendored-router-audit.sh-941-
test/gh353-vendored-router-audit.sh-942-# Extract custom section slice after fix
test/gh353-vendored-router-audit.sh-943-python3 -c "
test/gh353-vendored-router-audit.sh:944:with open('$R_REL_CRLF/ROUTER.md', 'rb') as f:
test/gh353-vendored-router-audit.sh-945-    data = f.read()
test/gh353-vendored-router-audit.sh-946-start = data.find(b'## Custom Section')
test/gh353-vendored-router-audit.sh-947-end = data.find(b'## Startup sequence')
test/gh353-vendored-router-audit.sh-948-with open('$WORK/custom_actual.bin', 'wb') as out:
--
test/gh353-vendored-router-audit.sh-951-cmp "$WORK/custom_expected.bin" "$WORK/custom_actual.bin" >/dev/null 2>&1; rc_cmp=$?
test/gh353-vendored-router-audit.sh-952-ok "custom section bytes match exactly with cmp (CRLF intact)" "$(is "$rc_cmp" "0"; echo $?)"
test/gh353-vendored-router-audit.sh-953-
test/gh353-vendored-router-audit.sh-954-# Idempotence
test/gh353-vendored-router-audit.sh:955:cp "$R_REL_CRLF/ROUTER.md" "$WORK/router_pass1.bin"
test/gh353-vendored-router-audit.sh-956-python3 "$AUDIT_PY" --fix "$R_REL_CRLF" >/dev/null
test/gh353-vendored-router-audit.sh:957:cmp "$WORK/router_pass1.bin" "$R_REL_CRLF/ROUTER.md" >/dev/null 2>&1; rc_idemp=$?
test/gh353-vendored-router-audit.sh-958-ok "--fix is byte-level idempotent on second run" "$(is "$rc_idemp" "0"; echo $?)"
test/gh353-vendored-router-audit.sh-959-
test/gh353-vendored-router-audit.sh-960-# ── 45. Releases --fix: repairs empty ## Role split followed by another section ───
test/gh353-vendored-router-audit.sh-961-R_REL_EMPTY_ROLE="$(mkrepo rel_empty_role)"
test/gh353-vendored-router-audit.sh-962-require_fixture "$R_REL_EMPTY_ROLE" "empty role releases repo"
test/gh353-vendored-router-audit.sh-963-touch "$R_REL_EMPTY_ROLE/releases.db"
test/gh353-vendored-router-audit.sh:964:printf '# ROUTER.md\n## Role split\n## Startup sequence\n1. Read ROADMAP.md\n' > "$R_REL_EMPTY_ROLE/ROUTER.md"
test/gh353-vendored-router-audit.sh-965-
test/gh353-vendored-router-audit.sh-966-python3 "$AUDIT_PY" --fix "$R_REL_EMPTY_ROLE" >/dev/null
test/gh353-vendored-router-audit.sh-967-out_er="$(python3 "$AUDIT_PY" --check "$R_REL_EMPTY_ROLE" 2>&1)"; rc_er=$?
test/gh353-vendored-router-audit.sh-968-ok "releases repo with empty ## Role split fixed and passes audit (rc=0)" "$(is "$rc_er" "0"; echo $?)"
--
test/gh353-vendored-router-audit.sh-970-# ── 46. Releases --fix: preserves repeated custom lines inside owned sections ─────
test/gh353-vendored-router-audit.sh-971-R_REL_REPEAT_CUSTOM="$(mkrepo rel_repeat_custom)"
test/gh353-vendored-router-audit.sh-972-require_fixture "$R_REL_REPEAT_CUSTOM" "repeat custom releases repo"
test/gh353-vendored-router-audit.sh-973-touch "$R_REL_REPEAT_CUSTOM/releases.db"
test/gh353-vendored-router-audit.sh:974:cat > "$R_REL_REPEAT_CUSTOM/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:975:# ROUTER.md
test/gh353-vendored-router-audit.sh-976-## Role split
test/gh353-vendored-router-audit.sh-977-- `ROADMAP.md` = active work
test/gh353-vendored-router-audit.sh-978-- `CUSTOM.md` = custom entry
test/gh353-vendored-router-audit.sh-979-- `CUSTOM.md` = custom entry
--
test/gh353-vendored-router-audit.sh-981-1. Read ROADMAP.md
test/gh353-vendored-router-audit.sh-982-MD
test/gh353-vendored-router-audit.sh-983-
test/gh353-vendored-router-audit.sh-984-python3 "$AUDIT_PY" --fix "$R_REL_REPEAT_CUSTOM" >/dev/null
test/gh353-vendored-router-audit.sh:985:repeat_content="$(cat "$R_REL_REPEAT_CUSTOM/ROUTER.md")"
test/gh353-vendored-router-audit.sh:986:repeat_count="$(grep -c "CUSTOM.md" "$R_REL_REPEAT_CUSTOM/ROUTER.md")"
test/gh353-vendored-router-audit.sh-987-ok "releases --fix preserved repeated custom entries" "$(is "$repeat_count" "2"; echo $?)"
test/gh353-vendored-router-audit.sh-988-
test/gh353-vendored-router-audit.sh-989-# ── 47. Releases --fix: preserves mixed LF/CRLF lines in owned sections verbatim ───
test/gh353-vendored-router-audit.sh-990-R_REL_MIXED_TERM="$(mkrepo rel_mixed_term)"
test/gh353-vendored-router-audit.sh-991-require_fixture "$R_REL_MIXED_TERM" "mixed term releases repo"
test/gh353-vendored-router-audit.sh-992-touch "$R_REL_MIXED_TERM/releases.db"
test/gh353-vendored-router-audit.sh:993:printf '# ROUTER.md\n## Role split\n- `ROADMAP.md` = active work\n- `LF_LINE.md` = line with LF\n- `CRLF_LINE.md` = line with CRLF\r\n## Startup sequence\n1. Read ROADMAP.md\n' > "$R_REL_MIXED_TERM/ROUTER.md"
test/gh353-vendored-router-audit.sh-994-
test/gh353-vendored-router-audit.sh-995-python3 "$AUDIT_PY" --fix "$R_REL_MIXED_TERM" >/dev/null
test/gh353-vendored-router-audit.sh-996-python3 -c "
test/gh353-vendored-router-audit.sh:997:with open('$R_REL_MIXED_TERM/ROUTER.md', 'rb') as f:
test/gh353-vendored-router-audit.sh-998-    data = f.read()
test/gh353-vendored-router-audit.sh-999-assert b'- \x60CRLF_LINE.md\x60 = line with CRLF\r\n' in data
test/gh353-vendored-router-audit.sh-1000-assert b'- \x60LF_LINE.md\x60 = line with LF\n' in data
test/gh353-vendored-router-audit.sh-1001-"
--
test/gh353-vendored-router-audit.sh-1006-require_fixture "$R_PDDA_COMMENT" "pdda comment repo"
test/gh353-vendored-router-audit.sh-1007-cat > "$R_PDDA_COMMENT/.pdda-mode" <<'MODE'
test/gh353-vendored-router-audit.sh-1008-# ROADMAP_SOURCE=releases
test/gh353-vendored-router-audit.sh-1009-MODE
test/gh353-vendored-router-audit.sh:1010:cat > "$R_PDDA_COMMENT/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1011:# ROUTER.md
test/gh353-vendored-router-audit.sh-1012-## Role split
test/gh353-vendored-router-audit.sh-1013-- `ROADMAP.md` = the pointer ledger of current work
test/gh353-vendored-router-audit.sh-1014-## Startup sequence
test/gh353-vendored-router-audit.sh-1015-1. Read `ROADMAP.md` to find active effort.
--
test/gh353-vendored-router-audit.sh-1023-require_fixture "$R_PDDA_PREFIX" "pdda prefix repo"
test/gh353-vendored-router-audit.sh-1024-cat > "$R_PDDA_PREFIX/.pdda-mode" <<'MODE'
test/gh353-vendored-router-audit.sh-1025-NOT_ROADMAP_SOURCE=releases
test/gh353-vendored-router-audit.sh-1026-MODE
test/gh353-vendored-router-audit.sh:1027:cat > "$R_PDDA_PREFIX/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1028:# ROUTER.md
test/gh353-vendored-router-audit.sh-1029-## Role split
test/gh353-vendored-router-audit.sh-1030-- `ROADMAP.md` = the pointer ledger of current work
test/gh353-vendored-router-audit.sh-1031-## Startup sequence
test/gh353-vendored-router-audit.sh-1032-1. Read `ROADMAP.md` to find active effort.
--
test/gh353-vendored-router-audit.sh-1040-require_fixture "$R_PDDA_WS" "pdda ws repo"
test/gh353-vendored-router-audit.sh-1041-cat > "$R_PDDA_WS/.pdda-mode" <<'MODE'
test/gh353-vendored-router-audit.sh-1042-   ROADMAP_SOURCE   =   releases  # comment
test/gh353-vendored-router-audit.sh-1043-MODE
test/gh353-vendored-router-audit.sh:1044:cat > "$R_PDDA_WS/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1045:# ROUTER.md
test/gh353-vendored-router-audit.sh-1046-## Role split
test/gh353-vendored-router-audit.sh:1047:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-1048-- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db`) is the source of truth
test/gh353-vendored-router-audit.sh-1049-## Startup sequence
test/gh353-vendored-router-audit.sh:1050:1. Read `ROADMAP-DASHBOARD.md` to find active effort. (`ROADMAP.md` is frozen legacy.)
test/gh353-vendored-router-audit.sh-1051-MD
test/gh353-vendored-router-audit.sh-1052-
test/gh353-vendored-router-audit.sh-1053-out="$(python3 "$AUDIT_PY" --check "$R_PDDA_WS" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-1054-ok "whitespace-padded ROADMAP_SOURCE=releases is recognized as releases mode (rc=0)" "$(is "$rc" "0"; echo $?)"
--
test/gh353-vendored-router-audit.sh-1069-
test/gh353-vendored-router-audit.sh-1070-# ── 52. Clean legacy-mode repo ─────────────────────────────────────────────────────
test/gh353-vendored-router-audit.sh-1071-R_LEG_CLEAN="$(mkrepo leg_clean)"
test/gh353-vendored-router-audit.sh-1072-require_fixture "$R_LEG_CLEAN" "clean legacy repo"
test/gh353-vendored-router-audit.sh:1073:cat > "$R_LEG_CLEAN/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1074:# ROUTER.md
test/gh353-vendored-router-audit.sh-1075-## Role split
test/gh353-vendored-router-audit.sh:1076:- `ROUTER.md` = startup order
test/gh353-vendored-router-audit.sh-1077-- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
test/gh353-vendored-router-audit.sh-1078-- `CHANGELOG.md` = running log of completed work
test/gh353-vendored-router-audit.sh-1079-## Startup sequence
test/gh353-vendored-router-audit.sh:1080:1. Read ROUTER.md
test/gh353-vendored-router-audit.sh-1081-2. Read `ROADMAP.md` to find active effort.
test/gh353-vendored-router-audit.sh-1082-MD
test/gh353-vendored-router-audit.sh-1083-
test/gh353-vendored-router-audit.sh-1084-out="$(python3 "$AUDIT_PY" --check "$R_LEG_CLEAN" 2>&1)"; rc=$?
--
test/gh353-vendored-router-audit.sh-1086-
test/gh353-vendored-router-audit.sh-1087-# ── 53. Clean legacy-mode repo with Markdown link in Startup ───────────────────────
test/gh353-vendored-router-audit.sh-1088-R_LEG_MD_LINK="$(mkrepo leg_md_link)"
test/gh353-vendored-router-audit.sh-1089-require_fixture "$R_LEG_MD_LINK" "clean legacy md link repo"
test/gh353-vendored-router-audit.sh:1090:cat > "$R_LEG_MD_LINK/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1091:# ROUTER.md
test/gh353-vendored-router-audit.sh-1092-## Role split
test/gh353-vendored-router-audit.sh-1093-- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
test/gh353-vendored-router-audit.sh-1094-## Startup sequence
test/gh353-vendored-router-audit.sh-1095-1. Read [the roadmap](ROADMAP.md) to find active effort.
--
test/gh353-vendored-router-audit.sh-1100-
test/gh353-vendored-router-audit.sh-1101-# ── 54. Clean legacy-mode repo with not frozen in Startup ──────────────────────────
test/gh353-vendored-router-audit.sh-1102-R_LEG_NOT_FROZEN="$(mkrepo leg_not_frozen)"
test/gh353-vendored-router-audit.sh-1103-require_fixture "$R_LEG_NOT_FROZEN" "clean legacy not frozen repo"
test/gh353-vendored-router-audit.sh:1104:cat > "$R_LEG_NOT_FROZEN/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1105:# ROUTER.md
test/gh353-vendored-router-audit.sh-1106-## Role split
test/gh353-vendored-router-audit.sh-1107-- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
test/gh353-vendored-router-audit.sh-1108-## Startup sequence
test/gh353-vendored-router-audit.sh-1109-1. Read `ROADMAP.md` to find active effort (ROADMAP.md is not frozen).
--
test/gh353-vendored-router-audit.sh-1114-
test/gh353-vendored-router-audit.sh-1115-# ── 55. Clean legacy-mode repo with unrelated legacy entry ─────────────────────────
test/gh353-vendored-router-audit.sh-1116-R_LEG_OLD_API="$(mkrepo leg_old_api)"
test/gh353-vendored-router-audit.sh-1117-require_fixture "$R_LEG_OLD_API" "clean legacy old api repo"
test/gh353-vendored-router-audit.sh:1118:cat > "$R_LEG_OLD_API/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1119:# ROUTER.md
test/gh353-vendored-router-audit.sh-1120-## Role split
test/gh353-vendored-router-audit.sh-1121-- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
test/gh353-vendored-router-audit.sh-1122-- `OLD-API.md` = remains legacy
test/gh353-vendored-router-audit.sh-1123-## Startup sequence
--
test/gh353-vendored-router-audit.sh-1127-out="$(python3 "$AUDIT_PY" --check "$R_LEG_OLD_API" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-1128-ok "clean legacy-mode repo with unrelated 'OLD-API.md remains legacy' reports ok (rc=0)" "$(is "$rc" "0"; echo $?)"
test/gh353-vendored-router-audit.sh-1129-
test/gh353-vendored-router-audit.sh-1130-python3 "$AUDIT_PY" --fix "$R_LEG_OLD_API" >/dev/null
test/gh353-vendored-router-audit.sh:1131:old_api_content="$(cat "$R_LEG_OLD_API/ROUTER.md")"
test/gh353-vendored-router-audit.sh-1132-ok "legacy --fix preserved unrelated OLD-API.md entry" "$(has "$old_api_content" "OLD-API.md"; echo $?)"
test/gh353-vendored-router-audit.sh-1133-
test/gh353-vendored-router-audit.sh-1134-# ── 56. Clean legacy-mode repo with non-owned historical frozen mention ───────────
test/gh353-vendored-router-audit.sh-1135-R_LEG_HIST_CHANGELOG="$(mkrepo leg_hist_changelog)"
test/gh353-vendored-router-audit.sh-1136-require_fixture "$R_LEG_HIST_CHANGELOG" "hist changelog repo"
test/gh353-vendored-router-audit.sh:1137:cat > "$R_LEG_HIST_CHANGELOG/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1138:# ROUTER.md
test/gh353-vendored-router-audit.sh-1139-## Role split
test/gh353-vendored-router-audit.sh-1140-- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
test/gh353-vendored-router-audit.sh-1141-- `CHANGELOG.md` = records when `ROADMAP.md` was frozen during the 2025 migration
test/gh353-vendored-router-audit.sh-1142-## Startup sequence
--
test/gh353-vendored-router-audit.sh-1146-out="$(python3 "$AUDIT_PY" --check "$R_LEG_HIST_CHANGELOG" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-1147-ok "clean legacy repo with historical frozen mention in CHANGELOG entry reports ok (rc=0)" "$(is "$rc" "0"; echo $?)"
test/gh353-vendored-router-audit.sh-1148-
test/gh353-vendored-router-audit.sh-1149-python3 "$AUDIT_PY" --fix "$R_LEG_HIST_CHANGELOG" >/dev/null
test/gh353-vendored-router-audit.sh:1150:cl_content="$(cat "$R_LEG_HIST_CHANGELOG/ROUTER.md")"
test/gh353-vendored-router-audit.sh-1151-ok "legacy --fix preserved non-owned CHANGELOG entry" "$(has "$cl_content" "records when \`ROADMAP.md\` was frozen"; echo $?)"
test/gh353-vendored-router-audit.sh-1152-
test/gh353-vendored-router-audit.sh-1153-# ── 57. Legacy clean valid custom startup step preserved byte-for-byte ────────────
test/gh353-vendored-router-audit.sh-1154-R_LEG_CUSTOM_STEP="$(mkrepo leg_custom_step)"
test/gh353-vendored-router-audit.sh-1155-require_fixture "$R_LEG_CUSTOM_STEP" "custom step legacy repo"
test/gh353-vendored-router-audit.sh:1156:cat > "$R_LEG_CUSTOM_STEP/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1157:# ROUTER.md
test/gh353-vendored-router-audit.sh-1158-## Role split
test/gh353-vendored-router-audit.sh-1159-- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
test/gh353-vendored-router-audit.sh:1160:- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-1161-## Startup sequence
test/gh353-vendored-router-audit.sh:1162:1. Read ROUTER.md
test/gh353-vendored-router-audit.sh-1163-2. Read AGENTS.md
test/gh353-vendored-router-audit.sh:1164:3. Read `ROADMAP-DASHBOARD.md` to find work.
test/gh353-vendored-router-audit.sh-1165-4. Read `PROJECT/PDDA.md` for the `ROADMAP.md` governance contract.
test/gh353-vendored-router-audit.sh-1166-MD
test/gh353-vendored-router-audit.sh-1167-
test/gh353-vendored-router-audit.sh-1168-# Save custom step 4
test/gh353-vendored-router-audit.sh-1169-python3 -c "
test/gh353-vendored-router-audit.sh:1170:with open('$R_LEG_CUSTOM_STEP/ROUTER.md', 'rb') as f:
test/gh353-vendored-router-audit.sh-1171-    data = f.read()
test/gh353-vendored-router-audit.sh-1172-start = data.find(b'4. Read ' + b'\x60PROJECT/PDDA.md\x60')
test/gh353-vendored-router-audit.sh-1173-with open('$WORK/leg_custom_step_exp.bin', 'wb') as out:
test/gh353-vendored-router-audit.sh-1174-    out.write(data[start:])
--
test/gh353-vendored-router-audit.sh-1178-out_lcs="$(python3 "$AUDIT_PY" --check "$R_LEG_CUSTOM_STEP" 2>&1)"; rc_lcs=$?
test/gh353-vendored-router-audit.sh-1179-ok "legacy repo with custom startup step fixed and passes audit (rc=0)" "$(is "$rc_lcs" "0"; echo $?)"
test/gh353-vendored-router-audit.sh-1180-
test/gh353-vendored-router-audit.sh-1181-python3 -c "
test/gh353-vendored-router-audit.sh:1182:with open('$R_LEG_CUSTOM_STEP/ROUTER.md', 'rb') as f:
test/gh353-vendored-router-audit.sh-1183-    data = f.read()
test/gh353-vendored-router-audit.sh-1184-start = data.find(b'4. Read ' + b'\x60PROJECT/PDDA.md\x60')
test/gh353-vendored-router-audit.sh-1185-with open('$WORK/leg_custom_step_act.bin', 'wb') as out:
test/gh353-vendored-router-audit.sh-1186-    out.write(data[start:])
--
test/gh353-vendored-router-audit.sh-1190-
test/gh353-vendored-router-audit.sh-1191-# ── 58. Legacy negative: Role split with deployment policy pointer ledger ─────────
test/gh353-vendored-router-audit.sh-1192-R_LEG_DEPLOY_POLICY="$(mkrepo leg_deploy_policy)"
test/gh353-vendored-router-audit.sh-1193-require_fixture "$R_LEG_DEPLOY_POLICY" "deploy policy legacy repo"
test/gh353-vendored-router-audit.sh:1194:cat > "$R_LEG_DEPLOY_POLICY/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1195:# ROUTER.md
test/gh353-vendored-router-audit.sh-1196-## Role split
test/gh353-vendored-router-audit.sh-1197-- `ROADMAP.md` = pointer ledger for deployment policy
test/gh353-vendored-router-audit.sh-1198-## Startup sequence
test/gh353-vendored-router-audit.sh-1199-1. Read `ROADMAP.md` to find active effort.
--
test/gh353-vendored-router-audit.sh-1204-
test/gh353-vendored-router-audit.sh-1205-# ── 59. Legacy negative: Role split with archived pointer ledger ──────────────────
test/gh353-vendored-router-audit.sh-1206-R_LEG_ARCHIVED="$(mkrepo leg_archived)"
test/gh353-vendored-router-audit.sh-1207-require_fixture "$R_LEG_ARCHIVED" "archived legacy repo"
test/gh353-vendored-router-audit.sh:1208:cat > "$R_LEG_ARCHIVED/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1209:# ROUTER.md
test/gh353-vendored-router-audit.sh-1210-## Role split
test/gh353-vendored-router-audit.sh-1211-- `ROADMAP.md` = archived pointer ledger
test/gh353-vendored-router-audit.sh-1212-## Startup sequence
test/gh353-vendored-router-audit.sh-1213-1. Read `ROADMAP.md` to find active effort.
--
test/gh353-vendored-router-audit.sh-1218-
test/gh353-vendored-router-audit.sh-1219-# ── 60. Legacy negative: Role split with false-frozen ROADMAP.md ───────────────────
test/gh353-vendored-router-audit.sh-1220-R_LEG_FALSE_FROZEN="$(mkrepo leg_false_frozen)"
test/gh353-vendored-router-audit.sh-1221-require_fixture "$R_LEG_FALSE_FROZEN" "false frozen legacy repo"
test/gh353-vendored-router-audit.sh:1222:cat > "$R_LEG_FALSE_FROZEN/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1223:# ROUTER.md
test/gh353-vendored-router-audit.sh-1224-## Role split
test/gh353-vendored-router-audit.sh-1225-- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases flip
test/gh353-vendored-router-audit.sh-1226-## Startup sequence
test/gh353-vendored-router-audit.sh:1227:1. Read ROUTER.md
test/gh353-vendored-router-audit.sh-1228-2. Read `ROADMAP.md` to find active effort.
test/gh353-vendored-router-audit.sh-1229-MD
test/gh353-vendored-router-audit.sh-1230-
test/gh353-vendored-router-audit.sh-1231-out="$(python3 "$AUDIT_PY" --check "$R_LEG_FALSE_FROZEN" 2>&1)"; rc=$?
--
test/gh353-vendored-router-audit.sh-1233-
test/gh353-vendored-router-audit.sh-1234-# ── 61. Legacy negative: Role split with two contradictory lines (active + frozen) ─
test/gh353-vendored-router-audit.sh-1235-R_LEG_TWO_LINE="$(mkrepo leg_two_line)"
test/gh353-vendored-router-audit.sh-1236-require_fixture "$R_LEG_TWO_LINE" "two line contradictory legacy repo"
test/gh353-vendored-router-audit.sh:1237:cat > "$R_LEG_TWO_LINE/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1238:# ROUTER.md
test/gh353-vendored-router-audit.sh-1239-## Role split
test/gh353-vendored-router-audit.sh-1240-- `ROADMAP.md` = the pointer ledger of current work
test/gh353-vendored-router-audit.sh-1241-ROADMAP.md is frozen legacy
test/gh353-vendored-router-audit.sh-1242-
--
test/gh353-vendored-router-audit.sh-1249-
test/gh353-vendored-router-audit.sh-1250-# ── 62. Legacy negative: Role split with mixed not frozen + affirmative legacy ─────
test/gh353-vendored-router-audit.sh-1251-R_LEG_MIXED_ROLE="$(mkrepo leg_mixed_role)"
test/gh353-vendored-router-audit.sh-1252-require_fixture "$R_LEG_MIXED_ROLE" "mixed role legacy repo"
test/gh353-vendored-router-audit.sh:1253:cat > "$R_LEG_MIXED_ROLE/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1254:# ROUTER.md
test/gh353-vendored-router-audit.sh-1255-## Role split
test/gh353-vendored-router-audit.sh-1256-- `ROADMAP.md` = the pointer ledger of current work
test/gh353-vendored-router-audit.sh-1257-ROADMAP.md is not frozen, but ROADMAP.md remains legacy
test/gh353-vendored-router-audit.sh-1258-
--
test/gh353-vendored-router-audit.sh-1265-
test/gh353-vendored-router-audit.sh-1266-# ── 63. Legacy negative: Role split with asterisk marker ───────────────────────────
test/gh353-vendored-router-audit.sh-1267-R_LEG_ASTERISK="$(mkrepo leg_asterisk)"
test/gh353-vendored-router-audit.sh-1268-require_fixture "$R_LEG_ASTERISK" "asterisk legacy repo"
test/gh353-vendored-router-audit.sh:1269:cat > "$R_LEG_ASTERISK/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1270:# ROUTER.md
test/gh353-vendored-router-audit.sh-1271-## Role split
test/gh353-vendored-router-audit.sh-1272-* `ROADMAP.md` = LEGACY pointer ledger, frozen
test/gh353-vendored-router-audit.sh-1273-## Startup sequence
test/gh353-vendored-router-audit.sh-1274-1. Read `ROADMAP.md` to find active effort.
--
test/gh353-vendored-router-audit.sh-1279-
test/gh353-vendored-router-audit.sh-1280-# ── 64. Legacy negative: Role split with inactive declaration ──────────────────────
test/gh353-vendored-router-audit.sh-1281-R_LEG_INACTIVE_ROLE="$(mkrepo leg_inactive_role)"
test/gh353-vendored-router-audit.sh-1282-require_fixture "$R_LEG_INACTIVE_ROLE" "inactive role legacy repo"
test/gh353-vendored-router-audit.sh:1283:cat > "$R_LEG_INACTIVE_ROLE/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1284:# ROUTER.md
test/gh353-vendored-router-audit.sh-1285-## Role split
test/gh353-vendored-router-audit.sh-1286-- `ROADMAP.md` = not active; obsolete record of deferred work
test/gh353-vendored-router-audit.sh-1287-## Startup sequence
test/gh353-vendored-router-audit.sh:1288:1. Read ROUTER.md
test/gh353-vendored-router-audit.sh-1289-2. Read `ROADMAP.md` to find active effort.
test/gh353-vendored-router-audit.sh-1290-MD
test/gh353-vendored-router-audit.sh-1291-
test/gh353-vendored-router-audit.sh-1292-out="$(python3 "$AUDIT_PY" --check "$R_LEG_INACTIVE_ROLE" 2>&1)"; rc=$?
--
test/gh353-vendored-router-audit.sh-1294-
test/gh353-vendored-router-audit.sh-1295-# ── 65. Legacy negative: Role split with releases.db mention ──────────────────────
test/gh353-vendored-router-audit.sh-1296-R_LEG_DB_ROLE="$(mkrepo leg_db_role)"
test/gh353-vendored-router-audit.sh-1297-require_fixture "$R_LEG_DB_ROLE" "db role legacy repo"
test/gh353-vendored-router-audit.sh:1298:cat > "$R_LEG_DB_ROLE/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1299:# ROUTER.md
test/gh353-vendored-router-audit.sh-1300-## Role split
test/gh353-vendored-router-audit.sh-1301-- `ROADMAP.md` = the pointer ledger of current work (releases.db is source)
test/gh353-vendored-router-audit.sh-1302-## Startup sequence
test/gh353-vendored-router-audit.sh-1303-1. Read `ROADMAP.md` to find active effort.
--
test/gh353-vendored-router-audit.sh-1308-
test/gh353-vendored-router-audit.sh-1309-# ── 66. Legacy negative: Startup sequence with deployment instructions ────────────
test/gh353-vendored-router-audit.sh-1310-R_LEG_DEPLOY_START="$(mkrepo leg_deploy_start)"
test/gh353-vendored-router-audit.sh-1311-require_fixture "$R_LEG_DEPLOY_START" "deploy start legacy repo"
test/gh353-vendored-router-audit.sh:1312:cat > "$R_LEG_DEPLOY_START/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1313:# ROUTER.md
test/gh353-vendored-router-audit.sh-1314-## Role split
test/gh353-vendored-router-audit.sh-1315-- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
test/gh353-vendored-router-audit.sh-1316-## Startup sequence
test/gh353-vendored-router-audit.sh-1317-1. Read `ROADMAP.md` for deployment instructions.
--
test/gh353-vendored-router-audit.sh-1322-
test/gh353-vendored-router-audit.sh-1323-# ── 67. Legacy negative: Startup sequence with deployment + negated current work ──
test/gh353-vendored-router-audit.sh-1324-R_LEG_DEPLOY_NEG_START="$(mkrepo leg_deploy_neg_start)"
test/gh353-vendored-router-audit.sh-1325-require_fixture "$R_LEG_DEPLOY_NEG_START" "deploy neg start legacy repo"
test/gh353-vendored-router-audit.sh:1326:cat > "$R_LEG_DEPLOY_NEG_START/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1327:# ROUTER.md
test/gh353-vendored-router-audit.sh-1328-## Role split
test/gh353-vendored-router-audit.sh-1329-- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
test/gh353-vendored-router-audit.sh-1330-## Startup sequence
test/gh353-vendored-router-audit.sh-1331-1. Read `ROADMAP.md` for deployment instructions; do not use ROADMAP.md for current work.
--
test/gh353-vendored-router-audit.sh-1336-
test/gh353-vendored-router-audit.sh-1337-# ── 68. Legacy negative: Startup sequence with false-frozen ROADMAP.md ────────────
test/gh353-vendored-router-audit.sh-1338-R_LEG_START_FROZEN="$(mkrepo leg_start_frozen)"
test/gh353-vendored-router-audit.sh-1339-require_fixture "$R_LEG_START_FROZEN" "start frozen legacy repo"
test/gh353-vendored-router-audit.sh:1340:cat > "$R_LEG_START_FROZEN/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1341:# ROUTER.md
test/gh353-vendored-router-audit.sh-1342-## Role split
test/gh353-vendored-router-audit.sh-1343-- `ROADMAP.md` = the pointer ledger of current work
test/gh353-vendored-router-audit.sh-1344-## Startup sequence
test/gh353-vendored-router-audit.sh:1345:1. Read ROUTER.md
test/gh353-vendored-router-audit.sh-1346-2. Read `ROADMAP.md` (note: ROADMAP.md is frozen legacy).
test/gh353-vendored-router-audit.sh-1347-MD
test/gh353-vendored-router-audit.sh-1348-
test/gh353-vendored-router-audit.sh-1349-out="$(python3 "$AUDIT_PY" --check "$R_LEG_START_FROZEN" 2>&1)"; rc=$?
--
test/gh353-vendored-router-audit.sh-1351-
test/gh353-vendored-router-audit.sh-1352-# ── 69. Legacy negative: Startup sequence with historical reference only ──────────
test/gh353-vendored-router-audit.sh-1353-R_LEG_HIST_REF="$(mkrepo leg_hist_ref)"
test/gh353-vendored-router-audit.sh-1354-require_fixture "$R_LEG_HIST_REF" "hist ref legacy repo"
test/gh353-vendored-router-audit.sh:1355:touch "$R_LEG_HIST_REF/ROUTER.md"
test/gh353-vendored-router-audit.sh:1356:cat > "$R_LEG_HIST_REF/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1357:# ROUTER.md
test/gh353-vendored-router-audit.sh-1358-## Role split
test/gh353-vendored-router-audit.sh-1359-- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
test/gh353-vendored-router-audit.sh-1360-## Startup sequence
test/gh353-vendored-router-audit.sh-1361-1. Read `ROADMAP.md` only for historical reference.
--
test/gh353-vendored-router-audit.sh-1366-
test/gh353-vendored-router-audit.sh-1367-# ── 70. Legacy negative: Startup sequence with negated Do not read ─────────────────
test/gh353-vendored-router-audit.sh-1368-R_LEG_NEG_READ="$(mkrepo leg_neg_read)"
test/gh353-vendored-router-audit.sh-1369-require_fixture "$R_LEG_NEG_READ" "neg read legacy repo"
test/gh353-vendored-router-audit.sh:1370:cat > "$R_LEG_NEG_READ/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1371:# ROUTER.md
test/gh353-vendored-router-audit.sh-1372-## Role split
test/gh353-vendored-router-audit.sh-1373-- `ROADMAP.md` = the pointer ledger of current work
test/gh353-vendored-router-audit.sh-1374-## Startup sequence
test/gh353-vendored-router-audit.sh:1375:1. Read ROUTER.md
test/gh353-vendored-router-audit.sh-1376-2. Do not read ROADMAP.md.
test/gh353-vendored-router-audit.sh-1377-MD
test/gh353-vendored-router-audit.sh-1378-
test/gh353-vendored-router-audit.sh-1379-out="$(python3 "$AUDIT_PY" --check "$R_LEG_NEG_READ" 2>&1)"; rc=$?
--
test/gh353-vendored-router-audit.sh-1381-
test/gh353-vendored-router-audit.sh-1382-# ── 71. Legacy negative: Startup sequence with not frozen + do not read contradiction
test/gh353-vendored-router-audit.sh-1383-R_LEG_START_CONTRADICT="$(mkrepo leg_start_contradict)"
test/gh353-vendored-router-audit.sh-1384-require_fixture "$R_LEG_START_CONTRADICT" "start contradict legacy repo"
test/gh353-vendored-router-audit.sh:1385:cat > "$R_LEG_START_CONTRADICT/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1386:# ROUTER.md
test/gh353-vendored-router-audit.sh-1387-## Role split
test/gh353-vendored-router-audit.sh-1388-- `ROADMAP.md` = the pointer ledger of current work
test/gh353-vendored-router-audit.sh-1389-## Startup sequence
test/gh353-vendored-router-audit.sh-1390-1. ROADMAP.md is not frozen; do not read ROADMAP.md.
--
test/gh353-vendored-router-audit.sh-1395-
test/gh353-vendored-router-audit.sh-1396-# ── 72. Legacy negative: Startup sequence with mixed not frozen + affirmative legacy
test/gh353-vendored-router-audit.sh-1397-R_LEG_START_MIXED="$(mkrepo leg_start_mixed)"
test/gh353-vendored-router-audit.sh-1398-require_fixture "$R_LEG_START_MIXED" "start mixed legacy repo"
test/gh353-vendored-router-audit.sh:1399:cat > "$R_LEG_START_MIXED/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1400:# ROUTER.md
test/gh353-vendored-router-audit.sh-1401-## Role split
test/gh353-vendored-router-audit.sh-1402-- `ROADMAP.md` = the pointer ledger of current work
test/gh353-vendored-router-audit.sh-1403-## Startup sequence
test/gh353-vendored-router-audit.sh-1404-1. Read `ROADMAP.md`; but note ROADMAP.md remains legacy.
--
test/gh353-vendored-router-audit.sh-1409-
test/gh353-vendored-router-audit.sh-1410-# ── 73. Legacy negative: Startup sequence with releases.sql mention ───────────────
test/gh353-vendored-router-audit.sh-1411-R_LEG_SQL_START="$(mkrepo leg_sql_start)"
test/gh353-vendored-router-audit.sh-1412-require_fixture "$R_LEG_SQL_START" "sql start legacy repo"
test/gh353-vendored-router-audit.sh:1413:cat > "$R_LEG_SQL_START/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1414:# ROUTER.md
test/gh353-vendored-router-audit.sh-1415-## Role split
test/gh353-vendored-router-audit.sh-1416-- `ROADMAP.md` = the pointer ledger of current work
test/gh353-vendored-router-audit.sh-1417-## Startup sequence
test/gh353-vendored-router-audit.sh-1418-1. Read `ROADMAP.md` via releases.sql.
--
test/gh353-vendored-router-audit.sh-1423-
test/gh353-vendored-router-audit.sh-1424-# ── 74. Legacy negative: missing Role split section ───────────────────────────────
test/gh353-vendored-router-audit.sh-1425-R_LEG_NO_ROLE="$(mkrepo leg_no_role)"
test/gh353-vendored-router-audit.sh-1426-require_fixture "$R_LEG_NO_ROLE" "no role legacy repo"
test/gh353-vendored-router-audit.sh:1427:cat > "$R_LEG_NO_ROLE/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1428:# ROUTER.md
test/gh353-vendored-router-audit.sh-1429-## Startup sequence
test/gh353-vendored-router-audit.sh-1430-1. Read `ROADMAP.md` to find active effort.
test/gh353-vendored-router-audit.sh-1431-MD
test/gh353-vendored-router-audit.sh-1432-
--
test/gh353-vendored-router-audit.sh-1435-
test/gh353-vendored-router-audit.sh-1436-# ── 75. Legacy negative: missing Startup sequence section ─────────────────────────
test/gh353-vendored-router-audit.sh-1437-R_LEG_NO_START="$(mkrepo leg_no_start)"
test/gh353-vendored-router-audit.sh-1438-require_fixture "$R_LEG_NO_START" "no start legacy repo"
test/gh353-vendored-router-audit.sh:1439:cat > "$R_LEG_NO_START/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1440:# ROUTER.md
test/gh353-vendored-router-audit.sh-1441-## Role split
test/gh353-vendored-router-audit.sh-1442-- `ROADMAP.md` = the pointer ledger of current work
test/gh353-vendored-router-audit.sh-1443-MD
test/gh353-vendored-router-audit.sh-1444-
test/gh353-vendored-router-audit.sh-1445-out="$(python3 "$AUDIT_PY" --check "$R_LEG_NO_START" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh-1446-ok "legacy repo missing Startup sequence reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
test/gh353-vendored-router-audit.sh-1447-
test/gh353-vendored-router-audit.sh:1448:# ── 76. Legacy negative: leftover ROADMAP-DASHBOARD.md file on disk ───────────────
test/gh353-vendored-router-audit.sh-1449-R_LEG_LEFTOVER="$(mkrepo leg_leftover)"
test/gh353-vendored-router-audit.sh-1450-require_fixture "$R_LEG_LEFTOVER" "leftover dashboard file legacy repo"
test/gh353-vendored-router-audit.sh:1451:touch "$R_LEG_LEFTOVER/ROADMAP-DASHBOARD.md"
test/gh353-vendored-router-audit.sh:1452:cat > "$R_LEG_LEFTOVER/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1453:# ROUTER.md
test/gh353-vendored-router-audit.sh-1454-## Role split
test/gh353-vendored-router-audit.sh-1455-- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
test/gh353-vendored-router-audit.sh-1456-## Startup sequence
test/gh353-vendored-router-audit.sh:1457:1. Read ROUTER.md
test/gh353-vendored-router-audit.sh-1458-2. Read `ROADMAP.md` to find active effort.
test/gh353-vendored-router-audit.sh-1459-MD
test/gh353-vendored-router-audit.sh-1460-
test/gh353-vendored-router-audit.sh-1461-out="$(python3 "$AUDIT_PY" --check "$R_LEG_LEFTOVER" 2>&1)"; rc=$?
--
test/gh353-vendored-router-audit.sh-1463-
test/gh353-vendored-router-audit.sh-1464-# ── 77. Remediate legacy repo with --fix ──────────────────────────────────────────
test/gh353-vendored-router-audit.sh-1465-R_LEG_DRIFT="$(mkrepo leg_drift)"
test/gh353-vendored-router-audit.sh-1466-require_fixture "$R_LEG_DRIFT" "drifted legacy repo"
test/gh353-vendored-router-audit.sh:1467:cat > "$R_LEG_DRIFT/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1468:# ROUTER.md
test/gh353-vendored-router-audit.sh-1469-## Role split
test/gh353-vendored-router-audit.sh:1470:* `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
test/gh353-vendored-router-audit.sh-1471-* `ROADMAP.md` = LEGACY pointer ledger, frozen
test/gh353-vendored-router-audit.sh-1472-releases.db is the source of truth
test/gh353-vendored-router-audit.sh-1473-ROADMAP.md is frozen legacy
test/gh353-vendored-router-audit.sh-1474-
test/gh353-vendored-router-audit.sh-1475-## Startup sequence
test/gh353-vendored-router-audit.sh:1476:1. Read ROUTER.md
test/gh353-vendored-router-audit.sh:1477:2. Read `ROADMAP-DASHBOARD.md` to find work.
test/gh353-vendored-router-audit.sh-1478-MD
test/gh353-vendored-router-audit.sh-1479-
test/gh353-vendored-router-audit.sh-1480-python3 "$AUDIT_PY" --fix "$R_LEG_DRIFT" >/dev/null
test/gh353-vendored-router-audit.sh-1481-out_remed="$(python3 "$AUDIT_PY" --check "$R_LEG_DRIFT" 2>&1)"; rc_remed=$?
test/gh353-vendored-router-audit.sh-1482-ok "drifted legacy repo remediated with --fix (rc=0)" "$(is "$rc_remed" "0"; echo $?)"
test/gh353-vendored-router-audit.sh:1483:content_leg="$(cat "$R_LEG_DRIFT/ROUTER.md")"
test/gh353-vendored-router-audit.sh:1484:ok "legacy --fix removed ROADMAP-DASHBOARD.md declaration" "$(! has "$content_leg" "ROADMAP-DASHBOARD.md"; echo $?)"
test/gh353-vendored-router-audit.sh-1485-ok "legacy --fix stripped standalone releases.db line" "$(! has "$content_leg" "releases.db is the source"; echo $?)"
test/gh353-vendored-router-audit.sh-1486-ok "legacy --fix stripped contradictory frozen line" "$(! has "$content_leg" "ROADMAP.md is frozen legacy"; echo $?)"
test/gh353-vendored-router-audit.sh-1487-ok "legacy --fix restored active pointer ledger text" "$(has "$content_leg" "pointer ledger of current"; echo $?)"
test/gh353-vendored-router-audit.sh-1488-ok "legacy --fix restored active ROADMAP.md read step" "$(has "$content_leg" "Read \`ROADMAP.md\`"; echo $?)"
test/gh353-vendored-router-audit.sh-1489-
test/gh353-vendored-router-audit.sh:1490:# ── 78. Missing ROUTER.md handling ────────────────────────────────────────────────
test/gh353-vendored-router-audit.sh-1491-R_MISSING="$(mkrepo missing_router)"
test/gh353-vendored-router-audit.sh-1492-require_fixture "$R_MISSING" "missing router repo"
test/gh353-vendored-router-audit.sh-1493-out="$(python3 "$AUDIT_PY" --check "$R_MISSING" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh:1494:ok "missing ROUTER.md reports non-zero exit on --check" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
test/gh353-vendored-router-audit.sh:1495:ok "missing ROUTER.md output indicates not found" "$(has "$out" "ROUTER.md not found"; echo $?)"
test/gh353-vendored-router-audit.sh-1496-
test/gh353-vendored-router-audit.sh:1497:# ── 79. Unreadable ROUTER.md handling ─────────────────────────────────────────────
test/gh353-vendored-router-audit.sh-1498-R_UNREADABLE="$(mkrepo unreadable)"
test/gh353-vendored-router-audit.sh-1499-require_fixture "$R_UNREADABLE" "unreadable repo"
test/gh353-vendored-router-audit.sh:1500:touch "$R_UNREADABLE/ROUTER.md"
test/gh353-vendored-router-audit.sh:1501:chmod 000 "$R_UNREADABLE/ROUTER.md" 2>/dev/null || true
test/gh353-vendored-router-audit.sh-1502-
test/gh353-vendored-router-audit.sh:1503:if [ ! -r "$R_UNREADABLE/ROUTER.md" ]; then
test/gh353-vendored-router-audit.sh-1504-  out="$(python3 "$AUDIT_PY" --check "$R_UNREADABLE" 2>&1)"; rc=$?
test/gh353-vendored-router-audit.sh:1505:  ok "unreadable ROUTER.md reports non-zero exit on --check" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
test/gh353-vendored-router-audit.sh:1506:  ok "unreadable output indicates error" "$(has "$out" "ERROR reading ROUTER.md"; echo $?)"
test/gh353-vendored-router-audit.sh:1507:  chmod 644 "$R_UNREADABLE/ROUTER.md"
test/gh353-vendored-router-audit.sh-1508-else
test/gh353-vendored-router-audit.sh-1509-  echo "  SKIP: unreadable test (running as root or chmod 000 not enforced)"
test/gh353-vendored-router-audit.sh-1510-  pass=$((pass+2))
test/gh353-vendored-router-audit.sh-1511-fi
--
test/gh353-vendored-router-audit.sh-1516-printf '%s\t%s\t%s\t%s\t%s\n' "$R_REL_STALE/.xyz" "2026-08-31T00:00:00Z" "0.2.0" "deadbeef" "$R_REL_STALE" >> "$REG_FILE"
test/gh353-vendored-router-audit.sh-1517-mkdir -p "$R_REL_STALE/.xyz"
test/gh353-vendored-router-audit.sh-1518-
test/gh353-vendored-router-audit.sh-1519-# Re-introduce drift in R_REL_STALE to test xyz-sync check
test/gh353-vendored-router-audit.sh:1520:cat > "$R_REL_STALE/ROUTER.md" <<'MD'
test/gh353-vendored-router-audit.sh:1521:# ROUTER.md
test/gh353-vendored-router-audit.sh-1522-## Role split
test/gh353-vendored-router-audit.sh-1523-- `ROADMAP.md` = the pointer ledger
test/gh353-vendored-router-audit.sh-1524-## Startup sequence
test/gh353-vendored-router-audit.sh-1525-1. Read ROADMAP.md
test/gh353-vendored-router-audit.sh-1526-MD
test/gh353-vendored-router-audit.sh-1527-
test/gh353-vendored-router-audit.sh-1528-sync_out="$(XYZ_REGISTRY="$REG_FILE" bash "$XYZ_SYNC" check --all 2>&1 || true)"
test/gh353-vendored-router-audit.sh:1529:ok "xyz-sync.sh check surfaces ROUTER DRIFT" "$(has "$sync_out" "ROUTER DRIFT"; echo $?)"
test/gh353-vendored-router-audit.sh-1530-
test/gh353-vendored-router-audit.sh-1531-echo "gh353: $pass passed, $fail failed"
test/gh353-vendored-router-audit.sh-1532-[ "$fail" -eq 0 ]
     1	#!/usr/bin/env python3
     2	"""router_audit.py — Audit and remediate ROUTER.md roadmap declarations across repos.
     3	
     4	Contract:
     5	- Checks if a target repository is in releases mode (releases.db present or anchored ROADMAP_SOURCE=releases in .pdda-mode).
     6	- If in releases mode:
     7	  - Asserts exactly one exact ## Role split and ## Startup sequence section exists (ignoring headings inside fenced code blocks and prefixed custom sections like '## Role split rationale').
     8	  - Asserts ## Role split affirmatively declares ROADMAP-DASHBOARD.md as generated view of the roadmap ledger (rejecting 'generated deployment manifest', 'not a generated view', 'lives elsewhere', 'historical archive', 'do not read', 'obsolete').
     9	  - Asserts ## Role split declares ROADMAP.md frozen/legacy AND affirmatively declares the releases DB (releases.db / releases.sql) as the source of truth (rejecting 'releases.db is present for compatibility', 'ROADMAP_SOURCE=releases' without DB source of truth, unrelated frozen subjects like 'OLD-API.md is frozen', active/current/priority claims or negated frozen/legacy in owned ROADMAP.md entries, while preserving non-owned entries like PROJECT/PDDA.md and examples inside code fences).
    10	  - Asserts ## Startup sequence directs to ROADMAP-DASHBOARD.md for current work/state/active effort in the directive clause itself (rejecting purpose-free reads like 'Read ROADMAP-DASHBOARD.md for deployment instructions; TEAM.md tracks current work', 'not current state', 'historical reference only', 'do not read') and forbids active ROADMAP.md directives in all clauses (supporting valid negations like 'do not use ROADMAP.md', while preserving custom steps and historical reads like 'Read ROADMAP.md only for historical reference').
    11	- If in legacy mode:
    12	  - Asserts exactly one exact ## Role split and ## Startup sequence section exists (ignoring code fences).
    13	  - Asserts ## Role split affirmatively declares active ROADMAP.md pointer ledger of current/active work in its own clause (rejecting 'pointer ledger for deployment policy', 'archived', 'frozen', 'legacy', 'releases.db', while preserving unrelated legacy entries like OLD-API.md and historical CHANGELOG entries like '- `CHANGELOG.md` = records when `ROADMAP.md` was frozen during the 2025 migration').
    14	  - Asserts ## Startup sequence directs to active ROADMAP.md for active effort/current work/tasks/intake in the candidate directive clause itself (rejecting 'for deployment instructions; do not use ROADMAP.md for current work', 'historical reference only', ignoring unrelated legacy entries).
    15	- In --fix mode:
    16	  - Deduplicates and safely splices exact bounded ## Role split and ## Startup sequence sections while preserving custom entries (like PROJECT/PDDA.md, OLD-API.md), custom startup steps, historical reads, custom sections, duplicate lines, code fences, and verbatim line endings (mixed LF/CRLF).
    17	  - Cleans active stray clauses from compound lines while preserving the valid governance/custom clauses.
    18	  - Ensures clean structural newlines between sections even if the previous section was empty.
    19	  - Collapses duplicate roadmap directives in Startup to exactly one canonical step.
    20	  - Validates candidate file BEFORE replacing live target; rolls back on failure so original is never corrupted.
    21	  - Uses safe atomic temporary files with fsync, chmod, and cleanup.
    22	- Report-only by default (exit 0 if clean, exit 1 if drift, missing, or error on --check).
    23	"""
    24	
    25	import argparse
    26	import os
    27	import re
    28	import sys
    29	import tempfile
    30	
    31	
    32	RELEASES_TOKENS = r"\b(ROADMAP-DASHBOARD\.md|releases\.db|releases\.sql|ROADMAP_SOURCE=releases|ROADMAP_SOURCE\s*=\s*releases)\b"
    33	ROADMAP_MENTION_RE = r"(?:`?ROADMAP\.md`?|\[[^\]]*\]\([^)]*ROADMAP\.md[^)]*\))"
    34	DASHBOARD_MENTION_RE = r"(?:`?ROADMAP-DASHBOARD\.md`?|\[[^\]]*\]\([^)]*ROADMAP-DASHBOARD\.md[^)]*\))"
    35	
    36	# Matches lines where ROADMAP.md or ROADMAP-DASHBOARD.md is the declared subject
    37	OWNED_ROADMAP_DECL_RE = r"^\s*(?:[-*+]|\d+\.)?\s*`?ROADMAP\.md`?\s*(?:=|:|—|-)\s*(.*)$"
    38	OWNED_DASHBOARD_DECL_RE = r"^\s*(?:[-*+]|\d+\.)?\s*`?ROADMAP-DASHBOARD\.md`?\s*(?:=|:|—|-)\s*(.*)$"
    39	
    40	
    41	def parse_pdda_mode(root):
    42	    """Checks .pdda-mode for anchored ROADMAP_SOURCE=releases.
    43	    Returns (is_releases_mode: bool, error_msg: str or None)
    44	    """
    45	    pdda_mode_path = os.path.join(root, ".pdda-mode")
    46	    if not os.path.exists(pdda_mode_path):
    47	        return False, None
    48	    try:
    49	        with open(pdda_mode_path, "r", newline="", encoding="utf-8") as f:
    50	            lines = f.readlines()
    51	        for line in lines:
    52	            line_clean = line.strip()
    53	            if not line_clean or line_clean.startswith("#"):
    54	                continue
    55	            m = re.match(r"^\s*ROADMAP_SOURCE\s*=\s*releases\s*(?:#.*)?$", line_clean)
    56	            if m:
    57	                return True, None
    58	        return False, None
    59	    except Exception as e:
    60	        return False, f"could not read .pdda-mode: {e}"
    61	
    62	
    63	def get_repo_mode(root):
    64	    """Returns (is_releases_mode: bool, error_msg: str or None)"""
    65	    if os.path.exists(os.path.join(root, "releases.db")):
    66	        return True, None
    67	    return parse_pdda_mode(root)
    68	
    69	
    70	def find_sections(content):
    71	    """Finds all '## <heading>' sections outside fenced code blocks and their byte/character spans in content."""
    72	    lines_with_pos = []
    73	    pos = 0
    74	    for line in content.splitlines(True):
    75	        lines_with_pos.append((line, pos))
    76	        pos += len(line)
    77	
    78	    in_fence = False
    79	    fence_char = None
    80	    fence_len = 0
    81	
    82	    section_headings = []
    83	    for line_text, start_pos in lines_with_pos:
    84	        clean_l = line_text.strip()
    85	        m_fence = re.match(r"^(`{3,}|~{3,})", clean_l)
    86	        if m_fence:
    87	            marker = m_fence.group(1)
    88	            char = marker[0]
    89	            length = len(marker)
    90	            if not in_fence:
    91	                in_fence = True
    92	                fence_char = char
    93	                fence_len = length
    94	            elif char == fence_char and length >= fence_len:
    95	                in_fence = False
    96	            continue
    97	
    98	        if not in_fence and line_text.startswith("## "):
    99	            m_h = re.match(r"^(##\s+[^\r\n]+)", line_text)
   100	            if m_h:
   101	                h_raw = m_h.group(1)
   102	                h_clean = re.sub(r"^##\s+", "", h_raw).strip()
   103	                nl_pos = content.find("\n", start_pos)
   104	                body_start = nl_pos + 1 if nl_pos != -1 else len(content)
   105	                section_headings.append({
   106	                    "heading": h_clean,
   107	                    "heading_raw": h_raw,
   108	                    "start": start_pos,
   109	                    "body_start": body_start,
   110	                })
   111	
   112	    sections = []
   113	    n = len(content)
   114	    for i, s in enumerate(section_headings):
   115	        end = section_headings[i + 1]["start"] if i + 1 < len(section_headings) else n
   116	        body = content[s["body_start"]:end]
   117	        sections.append({
   118	            "heading": s["heading"],
   119	            "heading_raw": s["heading_raw"],
   120	            "start": s["start"],
   121	            "body_start": s["body_start"],
   122	            "end": end,
   123	            "body": body,
   124	        })
   125	
   126	    return sections
   127	
   128	
   129	def split_clauses(line):
   130	    """Splits a line into clauses by punctuation, conjunctions, or sentence boundaries."""
   131	    return [c.strip() for c in re.split(r";|,|\s+(?:and|or|nevertheless|however|but|although|yet|while|whereas)\s+|\.\s+(?=[A-Z0-9\(])", line, flags=re.IGNORECASE) if c.strip()]
   132	
   133	
   134	def get_unfenced_lines(text):
   135	    """Returns lines from text that are outside fenced code blocks."""
   136	    result = []
   137	    in_fence = False
   138	    fence_char = None
   139	    fence_len = 0
   140	    for line in text.splitlines():
   141	        clean_l = line.strip()
   142	        m_fence = re.match(r"^(`{3,}|~{3,})", clean_l)
   143	        if m_fence:
   144	            marker = m_fence.group(1)
   145	            char = marker[0]
   146	            length = len(marker)
   147	            if not in_fence:
   148	                in_fence = True
   149	                fence_char = char
   150	                fence_len = length
   151	            elif char == fence_char and length >= fence_len:
   152	                in_fence = False
   153	            continue
   154	        if not in_fence:
   155	            result.append(line)
   156	    return result
   157	
   158	
   159	def split_lines_preserving_endings_with_fence(text):
   160	    """Splits text into (line_text, terminator, is_in_fence) tuples."""
   161	    result = []
   162	    lines = text.splitlines(True)
   163	    in_fence = False
   164	    fence_char = None
   165	    fence_len = 0
   166	    for l in lines:
   167	        if l.endswith("\r\n"):
   168	            line_text = l[:-2]
   169	            term = "\r\n"
   170	        elif l.endswith("\n"):
   171	            line_text = l[:-1]
   172	            term = "\n"
   173	        else:
   174	            line_text = l
   175	            term = ""
   176	
   177	        clean_l = line_text.strip()
   178	        m_fence = re.match(r"^(`{3,}|~{3,})", clean_l)
   179	        if m_fence:
   180	            marker = m_fence.group(1)
   181	            char = marker[0]
   182	            length = len(marker)
   183	            if not in_fence:
   184	                in_fence = True
   185	                fence_char = char
   186	                fence_len = length
   187	                result.append((line_text, term, True))
   188	            elif char == fence_char and length >= fence_len:
   189	                in_fence = False
   190	                result.append((line_text, term, True))
   191	            else:
   192	                result.append((line_text, term, True))
   193	            continue
   194	
   195	        result.append((line_text, term, in_fence))
   196	    return result
   197	
   198	
   199	def is_role_stray_active_roadmap_line(line):
   200	    """Returns True if any clause on a Role split line (not an owned declaration) claims ROADMAP.md is active."""
   201	    if re.search(OWNED_ROADMAP_DECL_RE, line, re.IGNORECASE):
   202	        return False
   203	    if not re.search(ROADMAP_MENTION_RE, line, re.IGNORECASE):
   204	        return False
   205	
   206	    for clause in split_clauses(line):
   207	        if not re.search(ROADMAP_MENTION_RE, clause, re.IGNORECASE):
   208	            continue
   209	        if re.search(r"\b(?:governs\s+the|contract|frozen\s+since|historical\s+archive)\b", clause, re.IGNORECASE):
   210	            continue
   211	        if re.search(r"\b(used\s+for\s+current|active\s+effort|active\s+tasks|current\s+priorities|active\s+pointer|current\s+work|active\s+items)\b", clause, re.IGNORECASE):
   212	            if not re.search(r"\b(?:is\s+(?:the\s+)?(?:frozen|legacy))\b", clause, re.IGNORECASE):
   213	                return True
   214	    return False
   215	
   216	
   217	def clean_stray_active_clauses(line):
   218	    """Removes stray active ROADMAP clauses from a compound line, returning cleaned line or empty string."""
   219	    if ";" in line:
   220	        parts = [p.strip() for p in line.split(";") if p.strip()]
   221	        kept = []
   222	        for p in parts:
   223	            if is_role_stray_active_roadmap_line(p):
   224	                continue
   225	            kept.append(p)
   226	        if kept:
   227	            m = re.match(r"^(\s*(?:[-*+]|\d+\.)\s+)", line)
   228	            prefix = m.group(1) if m and not kept[0].startswith(m.group(1).strip()) else ""
   229	            return prefix + "; ".join(kept)
   230	        return ""
   231	    return ""
   232	
   233	
   234	def is_owned_startup_roadmap_directive(line):
   235	    """Returns True if a Startup line is the primary directive to read ROADMAP.md or ROADMAP-DASHBOARD.md for current work."""
   236	    if is_active_roadmap_startup_directive(line):
   237	        return True
   238	    if re.search(r"\b(?:only\s+for\s+historical|for\s+historical\s+reference|historical\s+reference\s+only)\b", line, re.IGNORECASE):
   239	        return False
   240	
     1	#!/usr/bin/env bash
     2	# gh353-vendored-router-audit.sh — GH-353: audit and remediate target ROUTER.md ROADMAP.md frozen status.
     3	#
     4	# Comprehensive regression test matrix:
     5	#   1. Clean releases-mode repo reports `ok` (rc=0).
     6	#   2. Drifted releases-mode repo (legacy ROUTER.md with active ROADMAP.md) reports `ROUTER DRIFT` (rc=1 on --check).
     7	#   3. Releases negative: mention dashboard only in unrelated prose outside Role split / Startup -> fails audit.
     8	#   4. Releases negative: missing ROADMAP.md declaration in Role split -> fails audit.
     9	#   5. Releases negative: obsolete dashboard in Role split `ROADMAP-DASHBOARD.md = obsolete; do not read` -> fails audit.
    10	#   6. Releases negative: historical archive only dashboard in Role split -> fails audit.
    11	#   7. Releases negative: negated generated dashboard `ROADMAP-DASHBOARD.md = not generated; current view lives elsewhere` -> fails audit.
    12	#   8. Releases negative: not a generated view `ROADMAP-DASHBOARD.md = not a generated view` -> fails audit.
    13	#   9. Releases negative: generated deployment manifest `ROADMAP-DASHBOARD.md = generated deployment manifest` -> fails audit.
    14	#  10. Releases negative: negated DB source of truth `ROADMAP.md = frozen legacy; releases.db is not the source of truth` -> fails audit.
    15	#  11. Releases negative: compatibility DB note `ROADMAP.md = frozen legacy; releases.db is present for compatibility` -> fails audit.
    16	#  12. Releases negative: mode token without DB source of truth `ROADMAP.md = frozen legacy; ROADMAP_SOURCE=releases` -> fails audit.
    17	#  13. Releases negative: unrelated frozen subject on same line `ROADMAP.md = deployment notes; OLD-API.md is frozen; releases.db is the source of truth` -> fails audit.
    18	#  14. Releases negative: negated dashboard in Startup `Do not read ROADMAP-DASHBOARD.md` -> fails audit.
    19	#  15. Releases negative: historical context dashboard in Startup -> fails audit.
    20	#  16. Releases negative: purpose-free dashboard in Startup `Read ROADMAP-DASHBOARD.md for deployment instructions` -> fails audit.
    21	#  17. Releases negative: purpose-free dashboard + unrelated current work `Read ROADMAP-DASHBOARD.md for deployment instructions; TEAM.md tracks current work` -> fails audit.
    22	#  18. Releases negative: not current state dashboard in Startup `Read ROADMAP-DASHBOARD.md for not current state` -> fails audit.
    23	#  19. Releases negative: multi-clause active directive `ROADMAP.md is frozen for historical reference; nevertheless use ROADMAP.md for current work` -> fails audit.
    24	#  20. Releases negative: historical first clause + active second clause `Read ROADMAP.md only for historical reference; nevertheless use ROADMAP.md for current work` -> fails audit.
    25	#  21. Releases negative: conjunction active directive `ROADMAP.md is frozen and use ROADMAP.md for current work` -> fails audit.
    26	#  22. Releases negative: while-connector active directive `ROADMAP.md is frozen while operators use ROADMAP.md for current work` -> fails audit.
    27	#  23. Releases negative: colon-form active keywords `ROADMAP.md: active; frozen legacy; releases.db is source of truth` -> fails audit.
    28	#  24. Releases negative: negated legacy `ROADMAP.md is not legacy; releases.db is source of truth` -> fails audit.
    29	#  25. Releases negative: prose active ROADMAP in Role split `ROADMAP.md is used for current priorities` -> fails audit.
    30	#  26. Releases negative: prefixed prose active ROADMAP in Role split `Note: ROADMAP.md is used for current priorities` -> fails audit and --fix repairs it.
    31	#  27. Releases negative: compound custom entry + active prose in Role split `- \`PROJECT/PDDA.md\` = governs the \`ROADMAP.md\` contract; \`ROADMAP.md\` is used for current work` -> fails audit and --fix preserves the governance clause while removing the active clause.
    32	#  28. Releases negative: asterisk list marker in Role split `* ROADMAP.md = active pointer ledger` -> fails audit.
    33	#  29. Releases negative: Startup sequence with Open verb `Open ROADMAP.md to find current work` -> fails audit.
    34	#  30. Releases negative: Startup sequence with Consult verb `Consult ROADMAP.md first` -> fails audit.
    35	#  31. Releases negative: Startup sequence with Use verb `Use ROADMAP.md for current work` -> fails audit.
    36	#  32. Releases negative: Startup sequence with negated frozen `ROADMAP.md is not frozen; use it for current work` -> fails audit.
    37	#  33. Releases negative: Startup sequence with markdown link `[ROADMAP.md](path)` -> fails audit.
    38	#  34. Releases negative: Missing Startup sequence section -> fails audit.
    39	#  35. Releases negative: Duplicate Role split and Startup sections -> fails audit.
    40	#  36. Releases clean valid custom mention `- \`PROJECT/PDDA.md\` = governs the \`ROADMAP.md\` contract` passes audit and --fix preserves it.
    41	#  37. Releases clean valid custom startup step `4. Read \`PROJECT/PDDA.md\` for the \`ROADMAP.md\` governance contract.` passes audit and --fix preserves it byte-for-byte.
    42	#  38. Releases clean valid historical read `Read ROADMAP.md only for historical reference` passes audit and --fix preserves it.
    43	#  39. Releases clean valid negations: `do not use it` and `do not use ROADMAP.md for current work` pass audit.
    44	#  40. Releases clean valid fenced code blocks containing `## Role split` and `## Startup sequence` are ignored by section finder.
    45	#  41. Releases --fix: collapses duplicate roadmap steps in Startup to exactly 1 step, passes post-fix audit.
    46	#  42. Releases --fix: removes duplicate sections down to exactly 1 Role split and 1 Startup sequence.
    47	#  43. Releases --fix: preserves prefixed custom sections `## Role split rationale` and `## Startup sequence notes` with byte-for-byte cmp.
    48	#  44. Releases --fix: exact byte-level cmp on custom section with CRLF and idempotent re-run cmp.
    49	#  45. Releases --fix: repairs empty ## Role split followed by another section.
    50	#  46. Releases --fix: preserves repeated custom lines inside owned sections.
    51	#  47. Releases --fix: preserves mixed LF/CRLF lines in owned sections verbatim.
    52	#  48. Mode parser: commented `# ROADMAP_SOURCE=releases` in .pdda-mode is legacy mode.
    53	#  49. Mode parser: prefix `NOT_ROADMAP_SOURCE=releases` in .pdda-mode is legacy mode.
    54	#  50. Mode parser: whitespace `  ROADMAP_SOURCE  =  releases  # comment` in .pdda-mode is releases mode.
    55	#  51. Mode parser: unreadable .pdda-mode reports error and exits non-zero on --check.
    56	#  52. Clean legacy-mode repo reports `ok` (rc=0).
    57	#  53. Clean legacy-mode repo with Markdown link in Startup reports `ok` (rc=0).
    58	#  54. Clean legacy-mode repo with `ROADMAP.md is not frozen` in Startup reports `ok` (rc=0).
    59	#  55. Clean legacy-mode repo with unrelated legacy entry `- \`OLD-API.md\` = remains legacy` reports `ok` (rc=0) and --fix preserves it.
    60	#  56. Clean legacy-mode repo with non-owned historical frozen mention `- \`CHANGELOG.md\` = records when \`ROADMAP.md\` was frozen during the 2025 migration` reports `ok` (rc=0) and --fix preserves it.
    61	#  57. Legacy clean valid custom startup step `4. Read \`PROJECT/PDDA.md\` for the \`ROADMAP.md\` governance contract.` passes audit and --fix preserves it byte-for-byte.
    62	#  58. Legacy negative: Role split with deployment policy pointer ledger `ROADMAP.md = pointer ledger for deployment policy` -> fails audit.
    63	#  59. Legacy negative: Role split with archived pointer ledger `ROADMAP.md = archived pointer ledger` -> fails audit.
    64	#  60. Legacy negative: Role split with false-frozen ROADMAP.md -> fails audit.
    65	#  61. Legacy negative: Role split with two contradictory lines (active + frozen) -> fails audit.
    66	#  62. Legacy negative: Role split with mixed not frozen + affirmative legacy `ROADMAP.md is not frozen, but ROADMAP.md remains legacy` -> fails audit.
    67	#  63. Legacy negative: Role split with asterisk marker `* ROADMAP.md = frozen` -> fails audit.
    68	#  64. Legacy negative: Role split with inactive `not active; obsolete record of deferred work` -> fails audit.
    69	#  65. Legacy negative: Role split with releases.db mention -> fails audit.
    70	#  66. Legacy negative: Startup sequence with deployment instructions `Read ROADMAP.md for deployment instructions` -> fails audit.
    71	#  67. Legacy negative: Startup sequence with deployment instructions + negated current work `Read ROADMAP.md for deployment instructions; do not use ROADMAP.md for current work` -> fails audit.
    72	#  68. Legacy negative: Startup sequence with false-frozen ROADMAP.md -> fails audit.
    73	#  69. Legacy negative: Startup sequence with historical reference only `Read ROADMAP.md only for historical reference` -> fails audit.
    74	#  70. Legacy negative: Startup sequence with negated `Do not read ROADMAP.md` -> fails audit.
    75	#  71. Legacy negative: Startup sequence with `ROADMAP.md is not frozen; do not read ROADMAP.md` -> fails audit.
    76	#  72. Legacy negative: Startup sequence with `Read ROADMAP.md; but note ROADMAP.md remains legacy` -> fails audit.
    77	#  73. Legacy negative: Startup sequence with releases.sql mention -> fails audit.
    78	#  74. Legacy negative: Missing Role split section -> fails audit.
    79	#  75. Legacy negative: Missing Startup sequence section -> fails audit.
    80	#  76. Legacy negative: leftover ROADMAP-DASHBOARD.md file on disk + clean router reports ok (not fooled by file).
    81	#  77. Legacy --fix: removes two-line contradictory frozen role lines, standalone releases tokens, creates/repairs missing sections, restores active ROADMAP.md, strips dashboard, passes post-fix audit.
    82	#  78. Missing ROUTER.md reports error and exits non-zero on --check.
    83	#  79. Unreadable ROUTER.md reports error and exits non-zero on --check.
    84	#  80. `xyz-sync.sh check` surfaces router drift for registered vendored repositories.
    85	set -uo pipefail
    86	
    87	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    88	ROOT_DIR="$(cd "$HERE/.." && pwd)"
    89	AUDIT_PY="$ROOT_DIR/utils/py/router_audit.py"
    90	XYZ_SYNC="$ROOT_DIR/relay-automation/xyz-sync.sh"
    91	
    92	pass=0; fail=0
    93	ok(){ if [ "$2" = "0" ]; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
    94	is(){ [ "$1" = "$2" ]; }
    95	has(){ printf '%s' "$1" | grep -Fq "$2"; }
    96	
    97	echo "== test: gh353-vendored-router-audit =="
    98	
    99	command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
   100	
   101	WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh353-audit.XXXXXX")"
   102	[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "mktemp failed" >&2; exit 1; }
   103	. "$HERE/lib/fixture-guard.sh"
   104	fixture_guard_init "$WORK"
   105	cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
   106	trap cleanup EXIT
   107	
   108	mkrepo(){
   109	  local r="$WORK/$1"
   110	  mkdir -p "$r"
   111	  git -C "$r" init -q -b main
   112	  git -C "$r" config user.email test@invalid
   113	  git -C "$r" config user.name test
   114	  printf '%s\n' "$r"
   115	}
   116	
   117	# ── 1. Clean releases-mode repo ───────────────────────────────────────────────────
   118	R_REL_CLEAN="$(mkrepo rel_clean)"
   119	require_fixture "$R_REL_CLEAN" "clean releases repo"
   120	touch "$R_REL_CLEAN/releases.db"
   121	cat > "$R_REL_CLEAN/ROUTER.md" <<'MD'
   122	# ROUTER.md
   123	## Role split
   124	- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)
   125	- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file
   126	- `CHANGELOG.md` = running log of completed work
   127	## Startup sequence
   128	1. Read ROUTER.md
   129	2. Read AGENTS.md
   130	3. Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list`) to find the active effort. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.)
   131	MD
   132	
   133	out="$(python3 "$AUDIT_PY" --check "$R_REL_CLEAN" 2>&1)"; rc=$?
   134	ok "clean releases-mode repo reports ok (rc=0)" "$(is "$rc" "0"; echo $?)"
   135	ok "clean releases-mode repo output contains ok" "$(has "$out" "ok"; echo $?)"
   136	
   137	# ── 2. Drifted releases-mode repo (legacy active ROADMAP.md text) ───────────────────
   138	R_REL_STALE="$(mkrepo rel_stale)"
   139	require_fixture "$R_REL_STALE" "stale releases repo"
   140	touch "$R_REL_STALE/releases.db"
   141	cat > "$R_REL_STALE/ROUTER.md" <<'MD'
   142	# ROUTER.md
   143	## Role split
   144	- `ROUTER.md` = startup order
   145	- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
   146	- `CHANGELOG.md` = running log of completed work
   147	## Startup sequence
   148	1. Read ROUTER.md
   149	2. Read AGENTS.md
   150	3. Read `ROADMAP.md` to find the active effort.
   151	MD
   152	
   153	out="$(python3 "$AUDIT_PY" --check "$R_REL_STALE" 2>&1)"; rc=$?
   154	ok "drifted releases-mode repo reports non-zero exit with --check" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
   155	ok "drifted releases-mode repo output reports ROUTER DRIFT" "$(has "$out" "ROUTER DRIFT"; echo $?)"
   156	
   157	# ── 3. Releases negative: dashboard mentioned outside Role split / Startup ─────────
   158	R_REL_UNSCOPED="$(mkrepo rel_unscoped)"
   159	require_fixture "$R_REL_UNSCOPED" "unscoped releases repo"
   160	touch "$R_REL_UNSCOPED/releases.db"
   161	cat > "$R_REL_UNSCOPED/ROUTER.md" <<'MD'
   162	# ROUTER.md
   163	See ROADMAP-DASHBOARD.md in our notes somewhere.
   164	## Role split
   165	- `ROADMAP.md` = active roadmap ledger
   166	## Startup sequence
   167	1. Read `ROADMAP.md` to find work.
   168	MD
   169	
   170	out="$(python3 "$AUDIT_PY" --check "$R_REL_UNSCOPED" 2>&1)"; rc=$?
   171	ok "mentioning dashboard outside bounded sections fails audit" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
   172	
   173	# ── 4. Releases negative: missing ROADMAP.md declaration in Role split ──────────────
   174	R_REL_NO_RMI="$(mkrepo rel_no_rmi)"
   175	require_fixture "$R_REL_NO_RMI" "no rmi releases repo"
   176	touch "$R_REL_NO_RMI/releases.db"
   177	cat > "$R_REL_NO_RMI/ROUTER.md" <<'MD'
   178	# ROUTER.md
   179	## Role split
   180	- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
   181	## Startup sequence
   182	1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
   183	MD
   184	
   185	out="$(python3 "$AUDIT_PY" --check "$R_REL_NO_RMI" 2>&1)"; rc=$?
   186	ok "omitted ROADMAP.md role entry reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
   187	
   188	# ── 5. Releases negative: obsolete dashboard in Role split ─────────────────────────
   189	R_REL_OBSOLETE_DASH="$(mkrepo rel_obsolete_dash)"
   190	require_fixture "$R_REL_OBSOLETE_DASH" "obsolete dash releases repo"
   191	touch "$R_REL_OBSOLETE_DASH/releases.db"
   192	cat > "$R_REL_OBSOLETE_DASH/ROUTER.md" <<'MD'
   193	# ROUTER.md
   194	## Role split
   195	- `ROADMAP-DASHBOARD.md` = obsolete; do not read
   196	- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (releases.db) is the source of truth
   197	## Startup sequence
   198	1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
   199	MD
   200	
   201	out="$(python3 "$AUDIT_PY" --check "$R_REL_OBSOLETE_DASH" 2>&1)"; rc=$?
   202	ok "obsolete dashboard declaration in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
   203	
   204	# ── 6. Releases negative: historical archive dashboard in Role split ───────────────
   205	R_REL_HIST_DASH="$(mkrepo rel_hist_dash)"
   206	require_fixture "$R_REL_HIST_DASH" "hist dash releases repo"
   207	touch "$R_REL_HIST_DASH/releases.db"
   208	cat > "$R_REL_HIST_DASH/ROUTER.md" <<'MD'
   209	# ROUTER.md
   210	## Role split
   211	- `ROADMAP-DASHBOARD.md` = historical archive
   212	- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (releases.db) is the source of truth
   213	## Startup sequence
   214	1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
   215	MD
   216	
   217	out="$(python3 "$AUDIT_PY" --check "$R_REL_HIST_DASH" 2>&1)"; rc=$?
   218	ok "historical archive dashboard declaration in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
   219	
   220	# ── 7. Releases negative: negated generated dashboard in Role split ────────────────
    68	
    69	5. **Adversarially proven before commercially viable.** The harness exists to run against real codebases. Features in the adversarial-hardening track (epoch fencing, chaos suite, cross-repo E2E) must be verified to survive deliberate abuse — stale writers, zombie claims, macOS case-sensitivity, concurrent peer commits — not just the happy path. A feature that clears the happy path and skips chaos is half-done.
    70	
    71	6. **Build durable, not band-aid.** Durable means it removes the root cause and the next planned change builds on it — not a patch torn out when the obvious next feature lands. A band-aid is wasted work unless a demo strictly needs one, and a demo band-aid is tagged for removal so it isn't silently inherited.
    72	
    73	7. **Least code that clears the bar.** The `tick` coordination kernel uses Node's standard library. The repository also ships `package.json` and `package-lock.json` for Acorn-based source analysis. Prefer reusing or extending what exists; the smallest change that stays correct, contained, and durable wins. Net-new code is a cost to justify. Deleting code counts as progress.
    74	
    75	8. **Honest; the operator decides.** Surface what failed and why — never mask a stall as success or an escalation as a stall. A headless turn self-repairs within a bounded exit-code menu (`exit 3` stall, `exit 4` escalated-by-design, `exit 6` containment revert), then stops; it never loops forever or silently swallows an error. Destructive actions require explicit authorization.
    76	
    77	9. **Docs support resumable work (PDDA).** ROUTER points to the governing contracts; the RELEASES DB owns this repository's roadmap ledger, and ROADMAP-DASHBOARD.md is its generated view. Linked PROJECT documents hold plans, decisions and handoff detail; CHANGELOG records dated outcomes. Resume execution using those documents together with the relevant runtime state and evidence. If current documentation contradicts the implementation, correct it or explicitly record the unresolved discrepancy.
    78	
    79	10. **Done means verified.** "Done" is `validate.sh` green, the relevant PDDA checks passing, and any relay review returning `Approved` — not work that looks finished. An unverified success claim is itself a low-quality signal.
    80	
    81	11. **Issue-first; every non-trivial change has a signal stream.** Any change beyond a 2–3 line fix opens a GitHub issue first, then gets a `GH-<number>` in-repo pointer doc, then lands. The issue is the machine-queryable signal stream; the `PROJECT/**` doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt.
    82	
    83	12. **Independent Verification (Separated Grading)** — The agent that produces a turn must not be the sole grader of its own quality. Verification must be performed by an independent deterministic check or a separate reviewing agent before the lock releases. Applies to: the relay's structural block validator (`bin/validate-relay-block` — Phase 1 of GH-21), consult-verify diversity (Phase 3), and any other post-generation quality gate.
    84	
   135	  failure-prone enough to tax the whole system: worktree isolation, path claims, the driver lock,
   136	  multi-round handoff, escalation, and resume. Short, single-shot tasks land fine but prove nothing.
   137	  Four rules follow, and they are load-bearing:
   138	
   139	  1. **Exactly one long-horizon marathon is in flight at a time.** When one lands, choosing the next
   140	     is a real decision, not a default. It is named in the roadmap ledger's **Immediate next-up**
   141	     (read `ROADMAP-DASHBOARD.md`; the RELEASES DB is the source of truth since the
   142	     `ROADMAP_SOURCE=releases` flip) as the marathon, so an agent arriving cold can tell which item
   143	     is the load and which items are riding alongside it.
   144	  2. **Prefer the marathon-shaped candidate.** *Marathon-shaped* means: decomposable into many items
   145	     with an identical transform, a per-item pass condition a machine can check, and a plausible way
   146	     to break the harness. GH-10 (73 unaudited suites, one mechanical adoption each) is the
    60	   new/edited `.sh` under `utils/` or `relay-automation/` (GH-551),
    61	   coordination-kernel and containment surfaces (AGENTS: at least Costly).
    62	3. **Issue first** — the tracking issue exists and is OPEN. Closed => the work
    63	   may already be landed; run the preflight probes instead of re-doing it.
    64	4. **Suite** — the fix's regression suite exists AND is registered in
    65	   `validate.sh` TESTS. A hotfix without its suite is a claim, not a fix.
    66	5. **Docs born complete** — capture doc scaffolded in `2-WORKING` with Status,
    67	   Acceptance, Merge evidence, and `## Lessons Learned (For Future Agents)`
    68	   present from birth (the 08-26 reconcile gate refuses promotion otherwise),
    69	   plus the CHANGELOG entry appended in the same motion.
    70	6. **Ledger** — `roadmap add` if the issue is unparked, then `manifest dial-in`
    71	   against the active release (`releases next`) with an express reason. The
    72	   adopted release/leaderboard projections and `ROADMAP-DASHBOARD.md` refresh
    73	   in the same phase and are the only accepted driver outputs.
    74	7. **Gate** — the fix's suite runs green, the tree is RE-SNAPSHOTTED afterwards
    75	   by path and content (`tree-drift`: new paths and changed qualified bytes both
    76	   refuse). Gate identity is re-proven after the suite, staging uses explicit
    77	   pathspecs, and the push never sets `XYZ_SKIP_PREPUSH`.
    78	8. **Land** — one commit of exactly the qualified paths; push; ghost PR into
    79	   `development`; immediate merge. The closeout then switches to clean,
    80	   current `development` (ship/reconcile state never rides the task branch).
    45	   `CHANGELOG.md`. A missing, empty, sparse, or apparently old ledger is valid. In an app-managed
    46	   repo, also run `releases check` and surface any findings before proceeding.
    47	
    48	   **In an app-managed repo, read the ledger through the CLI's readers, not raw SQL.** All three
    49	   are read-only, take no lock, and mutate nothing:
    50	
    51	   ```text
    52	   releases next [--verbose]        the next unshipped release, by target date
    53	   releases show --version 0.6.0    one full record (or --gid; --full disables elision)
    54	   releases list [--status ...]     one line per release (--all-repos aggregates siblings)
    55	   ```
    56	
    57	   There is no generated Markdown mirror of the database to read: `RELEASES-PREVIEW.md` was removed
    58	   2026-08-19. For a whole-ledger view, use `releases list`, open `releases.db` in a SQLite viewer,
    59	   or read the release cards `releases project sync` (GH-39) pushes to GitHub Projects.
    60	
    61	   **After any merge that touched the ledger, run `releases check` before anything else.** The
    62	   merge procedure resolves `releases.sql` as text and then requires `releases check --rebuild` to
    63	   regenerate the DB from it; skipping that leaves a DB that disagrees with the dump, and the DB is
    64	   what every reader above trusts. `test/gh32-releases-artifacts.sh` gates this on every full-suite
    65	   run, but it catches the mistake after the fact — checking first is cheaper. Never run
    66	   `--rebuild` to make a red check go away without reading what diverged: it is for merge
    67	   resolution only, never crash recovery. See [RELEASES-DB-FAQS.md](../../RELEASES-DB-FAQS.md).
    68	3. Treat GitHub as optional for checks and required for publication. If `gh` is unavailable, run

exec
/bin/zsh -lc "nl -ba utils/timeline/export_timeline.py | sed -n '510,580p'; rg -n -C 2 'RELEASES-PREVIEW\\.html|LEADERBOARD\\.html' utils/timeline/RELEASES.html LEADERBOARD.html RELEASES-PREVIEW.html; rg -n -i 'pages|deploy|publish|serve|http.server|RELEASES\\.html|timeline' .github/workflows README.md ROUTER.md skills relay-automation/xyz-vendor.sh relay-automation/xyz-sync.sh utils/py/router_audit.py; rg -n 'router_audit|gh353-vendored-router-audit' validate.sh .github/workflows test || true; nl -ba utils/py/router_audit.py | sed -n '270,475p'; nl -ba utils/py/wave_reconcile.py | sed -n '1010,1055p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej
 succeeded in 0ms:
   510	    # ties break on id, so the ranking is deterministic rather than dict-iteration order
   511	    rated_tasks.sort(key=lambda r: (-r["metrics"]["effectiveScore"], r["id"]))
   512	
   513	    for c in columns:
   514	        del c["_raw"]
   515	
   516	    return {
   517	        "meta": {
   518	            "title": "Planning ledgers",
   519	            "subtitle": f"{settings.get('repo_slug', 'repo')} · releases.db · read-only",
   520	            "generatedAtDisplay": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%SZ"),
   521	            "sourceLabel": f"releases.db · schema v{schema_v}",
   522	            "repoUrl": repo_url,  # GH-153: sidebar repo links (None -> links stay unwired)
   523	        },
   524	        "sync": sync,  # RELEASES.md-vs-DB drift banner; None (no banner) when they agree
   525	        # ROADMAP.md row parity: still out of spike scope
   526	        "telemetry": {
   527	            "dbGeneration": int(settings.get("generation", 0)),
   528	            "receipts": receipts,
   529	            "lastSyncDisplay": (last_op or "—")[:16],
   530	            "lastSyncAgoDisplay": humanize_days(last_ago) if last_ago is not None else "",
   531	            "releasesOpen": n_open,
   532	            "releasesTotal": len(columns),
   533	            "releasesOverdue": n_overdue,
   534	        },
   535	        # every rated task in the ledger, ranked — the leaderboard's single input
   536	        "ratedTasks": rated_tasks,
   537	        "justFinished": jf,
   538	        "whatsNext": wn,
   539	        "releases": columns,
   540	        # GH-153: sidebar payload — switcher list + the shared full-cycle summary
   541	        "projects": projects,
   542	        "cycle": cycle,
   543	    }
   544	
   545	
   546	def serve(db_path, md_path, template_dir, port):
   547	    """Live mode: /data.json re-queries releases.db on every request — no stale file."""
   548	    import http.server
   549	
   550	    class Handler(http.server.SimpleHTTPRequestHandler):
   551	        def __init__(self, *a, **kw):
   552	            super().__init__(*a, directory=str(template_dir), **kw)
   553	
   554	        def do_GET(self):
   555	            path = self.path.split("?")[0]
   556	            if path == "/":
   557	                self.send_response(302)
   558	                self.send_header("Location", "/RELEASES.html")
   559	                self.end_headers()
   560	                return
   561	            if path != "/data.json":
   562	                return super().do_GET()
   563	            cx = sqlite3.connect(f"{db_path.as_uri()}?mode=ro", uri=True)
   564	            try:
   565	                body = json.dumps(build_payload(cx, date.today(), md_path)).encode()
   566	            finally:
   567	                cx.close()
   568	            self.send_response(200)
   569	            self.send_header("Content-Type", "application/json")
   570	            self.send_header("Cache-Control", "no-store")
   571	            self.send_header("Content-Length", str(len(body)))
   572	            self.end_headers()
   573	            self.wfile.write(body)
   574	
   575	    with http.server.ThreadingHTTPServer(("127.0.0.1", port), Handler) as srv:
   576	        print(f"live on http://127.0.0.1:{port}/RELEASES.html — every refresh re-queries {db_path}")
   577	        srv.serve_forever()
   578	
   579	
   580	def bake_static(template_html, payload):
utils/timeline/RELEASES.html-286-  <div class="sn-sec">
utils/timeline/RELEASES.html-287-    <div class="tiny">views</div>
utils/timeline/RELEASES.html:288:    <a class="sn-item" id="sn-view-a" href="./LEADERBOARD.html"><span class="sn-ico">◫</span><span class="sn-label">leaderboard</span></a>
utils/timeline/RELEASES.html-289-    <a class="sn-item" id="sn-view-b" href="#track"><span class="sn-ico">▤</span><span class="sn-label">timeline</span></a>
utils/timeline/RELEASES.html-290-  </div>
--
utils/timeline/RELEASES.html-322-      <!-- The cross-link lives in .top, not #fbar: #fbar is inside the collapsible header, so a
utils/timeline/RELEASES.html-323-           link there vanishes the moment the operator collapses the chrome. -->
utils/timeline/RELEASES.html:324:      <a id="view-link" class="mono" href="./LEADERBOARD.html"
utils/timeline/RELEASES.html-325-         style="font-size:10px;letter-spacing:0.06em;text-transform:uppercase">leaderboard →</a>
utils/timeline/RELEASES.html-326-      <span class="mono" id="pg-generated" style="font-size:10px;color:var(--ink3)"></span>
--
utils/timeline/RELEASES.html-425-  function viewLinks(){
utils/timeline/RELEASES.html-426-    var lb=document.body.dataset.view==='leaderboard';
utils/timeline/RELEASES.html:427:    document.getElementById('sn-view-a').href=lb?'#':'./LEADERBOARD.html';
utils/timeline/RELEASES.html:428:    document.getElementById('sn-view-b').href=lb?'./RELEASES-PREVIEW.html':'#';
utils/timeline/RELEASES.html-429-  }
utils/timeline/RELEASES.html-430-  viewLinks();   /* pre-boot paint (template default is the timeline view) */
--
utils/timeline/RELEASES.html-685-    var link=document.getElementById('view-link');
utils/timeline/RELEASES.html-686-    if(link){
utils/timeline/RELEASES.html:687:      link.href=view==='leaderboard'?'./RELEASES-PREVIEW.html':'./LEADERBOARD.html';
utils/timeline/RELEASES.html-688-      link.textContent=view==='leaderboard'?'← timeline':'leaderboard →';
utils/timeline/RELEASES.html-689-    }
--
LEADERBOARD.html-286-  <div class="sn-sec">
LEADERBOARD.html-287-    <div class="tiny">views</div>
LEADERBOARD.html:288:    <a class="sn-item" id="sn-view-a" href="./LEADERBOARD.html"><span class="sn-ico">◫</span><span class="sn-label">leaderboard</span></a>
LEADERBOARD.html-289-    <a class="sn-item" id="sn-view-b" href="#track"><span class="sn-ico">▤</span><span class="sn-label">timeline</span></a>
LEADERBOARD.html-290-  </div>
--
LEADERBOARD.html-322-      <!-- The cross-link lives in .top, not #fbar: #fbar is inside the collapsible header, so a
LEADERBOARD.html-323-           link there vanishes the moment the operator collapses the chrome. -->
LEADERBOARD.html:324:      <a id="view-link" class="mono" href="./LEADERBOARD.html"
LEADERBOARD.html-325-         style="font-size:10px;letter-spacing:0.06em;text-transform:uppercase">leaderboard →</a>
LEADERBOARD.html-326-      <span class="mono" id="pg-generated" style="font-size:10px;color:var(--ink3)"></span>
--
LEADERBOARD.html-425-  function viewLinks(){
LEADERBOARD.html-426-    var lb=document.body.dataset.view==='leaderboard';
LEADERBOARD.html:427:    document.getElementById('sn-view-a').href=lb?'#':'./LEADERBOARD.html';
LEADERBOARD.html:428:    document.getElementById('sn-view-b').href=lb?'./RELEASES-PREVIEW.html':'#';
LEADERBOARD.html-429-  }
LEADERBOARD.html-430-  viewLinks();   /* pre-boot paint (template default is the timeline view) */
--
LEADERBOARD.html-685-    var link=document.getElementById('view-link');
LEADERBOARD.html-686-    if(link){
LEADERBOARD.html:687:      link.href=view==='leaderboard'?'./RELEASES-PREVIEW.html':'./LEADERBOARD.html';
LEADERBOARD.html-688-      link.textContent=view==='leaderboard'?'← timeline':'leaderboard →';
LEADERBOARD.html-689-    }
--
RELEASES-PREVIEW.html-286-  <div class="sn-sec">
RELEASES-PREVIEW.html-287-    <div class="tiny">views</div>
RELEASES-PREVIEW.html:288:    <a class="sn-item" id="sn-view-a" href="./LEADERBOARD.html"><span class="sn-ico">◫</span><span class="sn-label">leaderboard</span></a>
RELEASES-PREVIEW.html-289-    <a class="sn-item" id="sn-view-b" href="#track"><span class="sn-ico">▤</span><span class="sn-label">timeline</span></a>
RELEASES-PREVIEW.html-290-  </div>
--
RELEASES-PREVIEW.html-322-      <!-- The cross-link lives in .top, not #fbar: #fbar is inside the collapsible header, so a
RELEASES-PREVIEW.html-323-           link there vanishes the moment the operator collapses the chrome. -->
RELEASES-PREVIEW.html:324:      <a id="view-link" class="mono" href="./LEADERBOARD.html"
RELEASES-PREVIEW.html-325-         style="font-size:10px;letter-spacing:0.06em;text-transform:uppercase">leaderboard →</a>
RELEASES-PREVIEW.html-326-      <span class="mono" id="pg-generated" style="font-size:10px;color:var(--ink3)"></span>
--
RELEASES-PREVIEW.html-425-  function viewLinks(){
RELEASES-PREVIEW.html-426-    var lb=document.body.dataset.view==='leaderboard';
RELEASES-PREVIEW.html:427:    document.getElementById('sn-view-a').href=lb?'#':'./LEADERBOARD.html';
RELEASES-PREVIEW.html:428:    document.getElementById('sn-view-b').href=lb?'./RELEASES-PREVIEW.html':'#';
RELEASES-PREVIEW.html-429-  }
RELEASES-PREVIEW.html-430-  viewLinks();   /* pre-boot paint (template default is the timeline view) */
--
RELEASES-PREVIEW.html-685-    var link=document.getElementById('view-link');
RELEASES-PREVIEW.html-686-    if(link){
RELEASES-PREVIEW.html:687:      link.href=view==='leaderboard'?'./RELEASES-PREVIEW.html':'./LEADERBOARD.html';
RELEASES-PREVIEW.html-688-      link.textContent=view==='leaderboard'?'← timeline':'leaderboard →';
RELEASES-PREVIEW.html-689-    }
utils/py/router_audit.py:8:  - Asserts ## Role split affirmatively declares ROADMAP-DASHBOARD.md as generated view of the roadmap ledger (rejecting 'generated deployment manifest', 'not a generated view', 'lives elsewhere', 'historical archive', 'do not read', 'obsolete').
utils/py/router_audit.py:10:  - Asserts ## Startup sequence directs to ROADMAP-DASHBOARD.md for current work/state/active effort in the directive clause itself (rejecting purpose-free reads like 'Read ROADMAP-DASHBOARD.md for deployment instructions; TEAM.md tracks current work', 'not current state', 'historical reference only', 'do not read') and forbids active ROADMAP.md directives in all clauses (supporting valid negations like 'do not use ROADMAP.md', while preserving custom steps and historical reads like 'Read ROADMAP.md only for historical reference').
utils/py/router_audit.py:13:  - Asserts ## Role split affirmatively declares active ROADMAP.md pointer ledger of current/active work in its own clause (rejecting 'pointer ledger for deployment policy', 'archived', 'frozen', 'legacy', 'releases.db', while preserving unrelated legacy entries like OLD-API.md and historical CHANGELOG entries like '- `CHANGELOG.md` = records when `ROADMAP.md` was frozen during the 2025 migration').
utils/py/router_audit.py:14:  - Asserts ## Startup sequence directs to active ROADMAP.md for active effort/current work/tasks/intake in the candidate directive clause itself (rejecting 'for deployment instructions; do not use ROADMAP.md for current work', 'historical reference only', ignoring unrelated legacy entries).
relay-automation/xyz-sync.sh:25:# preserves state the target owns. `xyz-vendor.sh` rebuilds the tree by staging a fresh mirror of
relay-automation/xyz-sync.sh:30:# Adding a new runtime artifact under `.xyz/` means adding it to that preserve list, or `update`
relay-automation/xyz-sync.sh:31:# will silently delete it. Regression coverage: test/gh312-vendor-preserves-state.sh.
ROUTER.md:42:- **`GH-<n>` numbering spans two repos.** This repo succeeded [`Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm`](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm) and the migration did **not** renumber references, so a `GH-<n>` in a source comment, test name, or CHANGELOG entry may belong to either repo. Upstream ledger entries are preserved verbatim in [`docs/ROADMAP-UPSTREAM-ARCHIVE.md`](docs/ROADMAP-UPSTREAM-ARCHIVE.md), which states its own numbering caveat and is not parsed by anything. Where an upstream number is cited from code that ships here, mirror it as a closed `[upstream archive]` issue so the citation resolves locally (#407, #408 are the pattern) rather than editing the comment. Raised externally as GH-406 §3.1.
ROUTER.md:64:the parent clone's `.git`, and an observed suite escape corrupted the parent (core.bare, origin,
ROUTER.md:164:- If the task is about release planning, ledger health, cleanup, authoring, or publishing, invoke `/releases`. It reads and synthesizes `RELEASES.md` first, then routes explicit requests into confirmation-gated cleanup, planning, or publication; governance is in `PROJECT/PDDA.md` (the "RELEASES.md — release ledger" contract). It conditionally points strategic drift to `/radar` and a frozen path-to-ship to `/finish-line` without duplicating either workflow.
relay-automation/xyz-vendor.sh:14:  --with-releases  Include the Tier 2 RELEASES overlay (releases_app.py, timeline, etc.).
relay-automation/xyz-vendor.sh:244:# Auto-un-ignoring would publish builder/reviewer transcripts a repo had explicitly decided to
relay-automation/xyz-vendor.sh:246:# script. `git add -f` is the same mistake one layer down. Refusing is recoverable; publishing is
relay-automation/xyz-vendor.sh:288:    printf '\n  NOT editing your .gitignore for you. Un-ignoring these would publish builder and\n'
relay-automation/xyz-vendor.sh:338:#                     (releases_app.py, releases_cycle.py, releases-merge-resolve.sh, release-lanes.sh, timeline/,
relay-automation/xyz-vendor.sh:344:RELEASES_OVERLAY="utils/py/releases_app.py utils/py/releases_cycle.py utils/releases-merge-resolve.sh utils/release-lanes.sh utils/timeline relay-automation/xyz-releases-onboard.sh"
relay-automation/xyz-vendor.sh:408:      || die "failed to preserve target runtime state: $_keep (aborting before the destructive swap)"
README.md:17:server, an account, or an API key for the coordination layer itself.
README.md:34:| Release tags | No release tags — two archival tags only; versions are tracked in an internal ledger, not published ([#452](https://github.com/HiQS-Labs/XYZ-forge/issues/452) tracks adopting them) |
README.md:86:serialize instead of racing. Projection folds events into `.tick/STATE.md`. No server, no remote, no
README.md:173:matrix for regulatory submission. Those require multi-user, server-backed, permissioned state, and
README.md:251:and its gate running serially with normal host reserve; it does **not** support per-lane parallel
README.md:264:unbounded term you must supply — plus host reserve.
.github/workflows/ci.yml:95:# EVERYTHING BELOW IS DELIBERATELY PRESERVED — jobs, routing, and especially the GH-509 Phase 4 cost
.github/workflows/pages.yml:1:name: Pages
.github/workflows/pages.yml:3:# Deploys the project site at https://hiqs-labs.github.io/XYZ-forge/ from PAGES/.
.github/workflows/pages.yml:4:# The two data-driven pages (roadmap.html, models-harnesses.html) are REGENERATED at
.github/workflows/pages.yml:5:# deploy time by utils/py/site_build.py from the committed releases.db / harnesses.db,
.github/workflows/pages.yml:6:# so a push that changes the ledgers republishes the site without anyone rebuilding
.github/workflows/pages.yml:7:# by hand. Static pages are served as committed. Pages is enabled on the repo with
.github/workflows/pages.yml:8:# build_type=workflow (Settings -> Pages -> Source: GitHub Actions).
.github/workflows/pages.yml:14:      - "PAGES/**"
.github/workflows/pages.yml:21:      - ".github/workflows/pages.yml"
.github/workflows/pages.yml:26:  pages: write
.github/workflows/pages.yml:30:  group: pages
.github/workflows/pages.yml:42:      - name: Regenerate data-driven pages from the committed ledgers
.github/workflows/pages.yml:44:      - uses: actions/upload-pages-artifact@v3
.github/workflows/pages.yml:46:          path: PAGES
.github/workflows/pages.yml:48:  deploy:
.github/workflows/pages.yml:53:      name: github-pages
.github/workflows/pages.yml:54:      url: ${{ steps.deployment.outputs.page_url }}
.github/workflows/pages.yml:56:      - id: deployment
.github/workflows/pages.yml:57:        uses: actions/deploy-pages@v4
skills/file-xyz-bug/SKILL.md:62:   | Observed | the real error text + exit code |
skills/file-xyz-bug/SKILL.md:73:   Never invent a repro you did not actually observe. If a step is inferred rather than seen, mark
skills/file-xyz-bug/SKILL.md:81:   published by a convenience skill.
skills/file-xyz-bug/SKILL.md:165:- **Observed from:** `<caller repo name>` (<vendored `.xyz/` | centralized harness>)
skills/file-xyz-bug/SKILL.md:176:**Observed:** <what actually happened, incl. exit code>
skills/file-xyz-bug/find-xyz.sh:98:# Where the bug was observed — the repo the caller is standing in, which is the single
skills/releases/SKILL.md:3:description: Read, synthesize, diagnose, clean, author, and publish the optional RELEASES.md planning ledger through one routed workflow. Use for /releases; release status or health checks; stale-plan review against merged PRs, commits, and CHANGELOG entries; disciplined release creation or updates; ledger cleanup; historical anchors or backfill; publishing a planned GitHub Release; or deciding whether Radar or Finish Line is the better follow-up. Default invocation is read-only and every write or publication requires a preview and confirmation.
skills/releases/SKILL.md:21:/releases publish <version>       publish one planned entry to GitHub
skills/releases/SKILL.md:78:1. Run `utils/pdda/pdda.sh releases` and `utils/pdda/pdda.sh releases-current`. Preserve their
skills/releases/SKILL.md:107:  actual publish state.
skills/releases/SKILL.md:117:- A target date no longer fits explicit dependencies or the observed delivery rate.
skills/releases/SKILL.md:140:2. Propose the smallest cleanup that restores the documented shape: compact descriptions, preserve
skills/releases/SKILL.md:141:   theme and dependencies, reduce manifests to a fixed list or milestone pointer, preserve dated
skills/releases/SKILL.md:211:## Publish subroutine
skills/releases/SKILL.md:223:5. Get one explicit confirmation, publish live, and capture the returned URL. If creation fails,
skills/better-options/SKILL.md:22:2. **Favor the smallest survivor** (from [ponytail](../ponytail/SKILL.md)) — once options survive falsification, don't default to the most architecturally satisfying one. Actively check whether a config flag, an existing feature, a one-line change, or deleting code resolves the actual observed problem — not the theorized one.
skills/better-options/SKILL.md:24:An option **survives** falsification when its justification — the claim that *this option is necessary* to resolve the observed problem, not merely that it's *a valid way* to resolve it — holds up against a real attempt to disprove it; plausibility alone doesn't count. That distinction guards point 2 against becoming reflexive minimalism: the bias is toward the smallest *survivor*, not the smallest option outright. A small option that doesn't actually resolve the observed problem isn't a survivor, it's just small, and the bigger option that does survive should win instead.
skills/better-options/SKILL.md:47:- **Simplest surviving option:** [Among what survives, the smallest fix that resolves the *actual observed* problem — config, flag, existing feature, one-liner, deletion — named explicitly, even if it wasn't on the original menu.]
skills/better-options/SKILL.md:70:**One clean disproof beats a survey of every option's pros and cons.** Resist restating each option's tradeoffs symmetrically — that's bottom-line's job on an honest menu. Here, the job is deciding whether the menu itself deserves to stand.
skills/releases/install.sh:36:    echo "  Preserve or move it yourself, then re-run this installer." >&2
skills/phase-qa/SKILL.md:7:  per phase whether the work needs deploying to a remote environment. Invoke before work
skills/phase-qa/SKILL.md:151:## Step 3d — Surface deployment need per phase (optional)
skills/phase-qa/SKILL.md:154:runnable: does this phase need to be deployed to a remote environment (staging,
skills/phase-qa/SKILL.md:155:production, a client server) before it counts as done?
skills/phase-qa/SKILL.md:157:**This skill's only job here is to catch and surface *whether* a deploy step is needed —
skills/phase-qa/SKILL.md:158:full stop.** It does not plan the deployment. Target, owner, rollback, sequencing, and
skills/phase-qa/SKILL.md:163:> all complete locally? I'm only flagging *whether* a deploy is needed — not how it's
skills/phase-qa/SKILL.md:171:| Deploy needed, confirmed | Add the deployment item, unchecked — to be confirmed done before the phase closes |
skills/phase-qa/SKILL.md:173:| No deploy needed | Add a one-line N/A note (checked), so the answer is on record rather than forgotten |
skills/phase-qa/SKILL.md:175:The deployment line is conditional: a phase that completes locally gets the N/A note if
skills/phase-qa/SKILL.md:180:- [ ] Deployment: this phase requires a remote deploy — confirm it's done before closing the phase
skills/phase-qa/SKILL.md:181:- [ ] Deployment: confirm whether this phase needs a remote deploy before closing (check with the plan author)
skills/phase-qa/SKILL.md:182:- [x] Deployment: N/A — phase completes locally, ships no remote artifact (asked, confirmed)
skills/phase-qa/SKILL.md:198:  Deployment item (Step 3d)
skills/phase-qa/SKILL.md:304:this order: the Scope item (Step 3c, when anti-goals are defined), then the Deployment
skills/phase-qa/SKILL.md:305:item (Step 3d, when the phase needs a remote deploy). Both are operator-attested — the
skills/phase-qa/SKILL.md:319:preserve any item the user has already checked (`- [x]`) unless the diff review
skills/skills-sync-trinity/SKILL.md:30:- Do not use it for publishing, installing, or syncing skills into external registries.
skills/relay-xyz/find-harness.sh:162:# 4. current git repo (preserves "operate on the clone I'm standing in")
skills/marathon-cleanup/SKILL.md:25:- Preserve unrelated dirty-worktree changes. Stop if a candidate or lifecycle ledger has overlapping
skills/marathon-cleanup/SKILL.md:57:| GitHub issue | Open/closed state, close reason, linked PRs, comments that narrow or preserve remaining scope | Corroboration; closed alone is insufficient |
skills/marathon-cleanup/SKILL.md:139:2. Update eligible task docs to terminal frontmatter and an evidence-backed Status row; preserve
skills/relay-xyz/SKILL.md:176:| **Tier 2 (opt-in)**: `xyz-vendor.sh <target-repo> --with-releases` (or auto-detected via `releases.db` at root) | full core harness + RELEASES overlay (`releases_app.py`, `releases_cycle.py`, `releases-merge-resolve.sh`, `release-lanes.sh`, `utils/timeline/`, `xyz-releases-onboard.sh`, `RELEASES-DB-FAQS.md`) | ✅ per-repo | ✅ opt-in overlay | **own** `.xyz/.relay-driver.lock` |
skills/relay-xyz/SKILL.md:179:`.xyz/`) replaces the harness **code** and preserves the per-repo state above — `relay-system/`,
skills/relay-xyz/SKILL.md:183:runtime state is preserved across swaps. This matters because `.xyz/` is gitignored: state lost there
skills/relay-xyz/SKILL.md:185:to the preserve list in `xyz-vendor.sh`'s `materialize_vendor()`, or the next update will delete it.
skills/relay-xyz/SKILL.md:300:| DeepSeek | `DEEPSEEK_MODEL` | `deepseek/deepseek-v4-pro` | accepts a colloquial alias (`"deepseek v4 pro"`); also `DEEPSEEK_PROVIDER` (`openrouter`\|`deepseek`\|`alibaba`) selecting the endpoint and its key variable. An unrecognised value REFUSES the turn (it used to fall through to DeepSeek silently). `alibaba` is the Alibaba Token Plan, which serves Qwen under bare ids (`qwen3.8-max`, not `qwen/...`) and reads its key from `ALIBABA_TOKEN_PLAN_API_KEY` or, failing that, the file named by `ALIBABA_TOKEN_PLAN_API_KEY_FILE`. |
skills/relay-xyz/SKILL.md:387:the same repo/worktree state (observed: a stray `git worktree` plus a `tick` token stuck in
skills/relay-xyz/SKILL.md:512:| extra writable paths | `ALLOW_PATHS` | `ALLOW_PATHS` | comma-sep git paths the turn may change (the relay file is always allowed). **For a review turn, set `ALLOW_PATHS=""` — relay file only.** If the artifact is writable, the reviewer tends to start *editing and building* it instead of reviewing (it can read any path regardless), which over-runs the turn cap (exit 7) — observed 2026-06-26. A build/fix turn is the only case that needs the artifact in `ALLOW_PATHS`. **A whole DIRECTORY is a valid lane entry** (GH-90): an entry that names an existing directory, or any entry written with a **trailing slash** (`skills/standup/fixtures/` — the only form that works when the turn is about to *create* the directory), makes that directory and everything beneath it writable. Without either signal the entry is a FILE path, and a file entry is never a bare prefix — GH-59: `green` must not reach `greenfield/output.txt`. Before GH-90 a bare directory entry was unmatchable by construction and the turn failed as a *containment violation*, which reads as a misbehaving builder rather than a malformed lane spec; the off-lane report now names that mistake explicitly. |
skills/relay-xyz/SKILL.md:547:self-escape backstop. Observed live twice (2026-07-05, 2026-07-18); the second incident silently
skills/browserbase/reference/onboarding-guide.md:40:> - **Stagehand** — Browserbase's open-source framework for driving the browser with natural language (`act` / `extract` / `observe`) instead of brittle selectors.
skills/browserbase/reference/onboarding-guide.md:47:> - **Functions** — deploy your automation to run in Browserbase's cloud on a schedule or webhook.
skills/browserbase/reference/onboarding-guide.md:74:> and that cap isn't surfaced up front — so a Stagehand `act`/`extract`/`observe` run can suddenly fail
skills/browserbase/reference/onboarding-guide.md:268:normal for a demo; ignore it unless you're deploying.)
skills/browserbase/reference/onboarding-guide.md:366:>   use **Stagehand** `act` / `extract` / `observe`. You script the steps — cheaper, faster, more reliable.
skills/browserbase/reference/onboarding-guide.md:380:| **Stagehand** | You want natural-language browser automation — `act` / `extract` / `observe` instead of brittle selectors. Best default for agentic browsing & data extraction. | https://docs.stagehand.dev/llms.txt |
skills/browserbase/reference/onboarding-guide.md:392:sites, **Contexts** for auth, **Functions** to deploy, **Model Gateway** for LLM calls.
skills/browserbase/reference/onboarding-guide.md:400:- **Stagehand** — use the current V4 installation and browser-configuration pages selected from
skills/browserbase/reference/onboarding-guide.md:410:task-specific Markdown pages needed for the integration. Treat those docs and the installed SDK's
skills/browserbase/reference/onboarding-guide.md:422:  Playwright-style page APIs with natural-language `act` / `extract` / `observe` methods so
skills/browserbase/reference/onboarding-guide.md:425:- **Write the Stagehand code for speed and reliability.** Use the current caching and prompting pages
skills/browserbase/reference/onboarding-guide.md:427:  - Enable the documented Browserbase server-side `cache` option when repeated steps have stable inputs.
skills/browserbase/reference/onboarding-guide.md:432:    confirm with `observe()` before acting; prefer `waitUntil: "domcontentloaded"`.
skills/browserbase/SKILL.md:8:  catalog -> Stagehand act/extract/observe -> raw Playwright session) and returns
skills/browserbase/SKILL.md:87:| Repeatable task on a JS page: extract fields, click, fill, paginate | **Stagehand** `act` / `extract` / `observe` | TS or Python SDK, see §4 |
skills/browserbase/SKILL.md:105:Goal: a sourced answer, not a pile of pages.
skills/browserbase/SKILL.md:137:   install page plus the task pages you need. Use installed SDK declarations for
skills/browserbase/SKILL.md:146:   - Wait on a specific element or `observe()` result, **never** a fixed sleep.
skills/browserbase/SKILL.md:148:   - Enable the server-side `cache` option when inputs are stable; pass dynamic or
skills/merge-cleanup/SKILL.md:110:1. **Zero Data Loss:** Any dirty working tree, unpopped stash, or unpushed commit automatically stops deletion and marks the checkout `PRESERVE_*`.
skills/merge-cleanup/SKILL.md:111:2. **Zero Process Interference:** Clones with active driver locks or running subagents are detected and preserved.
skills/swe-diagram/SKILL.md:108:    same deterministic longest-path ranks as `layered`. Use for deployment
skills/marathon-triage/SKILL.md:200:   holds — never from a blank menu. Reserve a bare options list only for genuinely balanced
skills/front-door/SKILL.md:112:3. **Health at a glance** — one row per inspection dimension (`One front door`, `🔑 Leaked secrets`, `First success works`, `Doc ↔ code drift`, `Agent front door`, `Recent features documented`, …), each scored ✅ / ⚠️ / 🚧 with a one-liner. These are the seven *What to inspect* points, graded. (Here 🚧 marks a dimension that has open findings; reserve the *verdict's* 🚧 for a true wall.)
skills/front-door/SKILL.md:143:**The error message is a symptom, not the diagnosis.** A first-run failure often names the wrong cause — a blocked host or a sandbox can surface as "no keychain available" or "restart your computer." Trace what actually failed (which host, resource, or boundary) where you can observe it; where you can't, mark the cause **inferred** rather than restating the misleading message as fact. Either way, don't route the newcomer toward the fix the error literally names when the real wall is elsewhere.
skills/jog/SKILL.md:64:    Fresh Marathon attempt on a fresh execution id (history preserved).
skills/jog/SKILL.md:137:  when the build itself must be redone; all prior Tick history and execution records are preserved.
skills/merge-cleanup/scripts/scan_clones.py:274:                res["disposition"] = "PRESERVED_USER_EXCLUDE"
skills/merge-cleanup/scripts/scan_clones.py:286:        res["disposition"] = "PRESERVE_WIKI"
skills/merge-cleanup/scripts/scan_clones.py:304:        res["disposition"] = "PRESERVE_DIRTY"
skills/merge-cleanup/scripts/scan_clones.py:309:        res["disposition"] = "PRESERVE_STASH"
skills/merge-cleanup/scripts/scan_clones.py:314:        res["disposition"] = "PRESERVE_UNPUSHED"
skills/merge-cleanup/scripts/scan_clones.py:319:        res["disposition"] = "PRESERVE_PARENT_CLONE"
skills/merge-cleanup/scripts/scan_clones.py:324:        res["disposition"] = "PRESERVE_UNSAFE_ROOT"
skills/recon/SKILL.md:50:If the `codebase-memory` MCP server is available, use it first — it answers "who touches this" in one call instead of twenty greps:
skills/recon/SKILL.md:58:**The graph is a lead, not a citation.** Every edge a plan step will depend on gets confirmed by reading the file; an edge that exists only in the graph is marked `graph-only`. Depending on the indexer, it **may miss** config, SQL strings, templates, shell and CI scripts, cron, IaC and deploy manifests, generated code and its generator, database triggers/views/procedures, macros, runtime registries, reflection and dynamic dispatch, and consumers in other repositories. Anything in that list you did not verify by hand is an Unknown — in graph mode and grep mode alike.
skills/recon/SKILL.md:73:| **D. Build, failure & operations** | How is this built, how does it fail, who notices? | Build/CI config and package metadata, generated code and its generator, IaC and deploy manifests, error paths, retries, timeouts, existing tests covering the subject, logs/metrics/traces, and the rollback path |
skills/merge-cleanup/scripts/merge_cleanup.py:314:        log("No candidate checkouts qualify for safe removal (all are preserved or active).")
skills/relay-to-issue/SKILL.md:119:- Preserve grades and cite the source round so each task is traceable.
skills/readme-audit/SKILL.md:58:   - **External URLs** — obviously broken or wrong-target; flag, but mark unreachable-vs-just-unchecked honestly (don't claim a 404 you didn't observe).
skills/radar/SKILL.md:47:Two reasons, both observed, and the second one independently in two repos: shell wrappers/hooks may
skills/radar/SKILL.md:123:   events need per-issue `gh api` timeline calls — expensive; sample them only for cluster
skills/radar/SKILL.md:142:at all. Observed: one sweep relocated 39 docs and repointed 51 roadmap entries in a single commit.
skills/radar/SKILL.md:210:Read the DB using `releases check`, `releases roadmap sync --dry-run`, and the `python3 utils/timeline/export_timeline.py --json` payload instead of hand-parsing `RELEASES.md`. Cite the DB generation numbers in the report.
skills/radar/SKILL.md:223:Then compare the planned theme against the observed flow distribution and the top targets, and
skills/radar/SKILL.md:275:to preserve that state explicit: "Recommended next step: keep the current plan; rerun Radar after
skills/radar/SKILL.md:373:| `marathon-triage` | Ranking marathon candidates | Radar asks what deserves to be a candidate; feeds it, never requires it |
skills/feynman/SKILL.md:14:## The one rule everything else serves
skills/feynman/SKILL.md:28:- **Read-only on the source. Additive output.** Observe the doc; never edit it. Never overwrite an existing output file — if the chosen path already exists, disambiguate rather than clobber.
skills/relay/SKILL.md:79:**Basis:** behaviorally proven (<what I ran / observed>) | textual only (read, not run) | N/A — non-executable artifact
skills/relay/SKILL.md:273:10. **Evidence contract — state your proof every turn.** The Producer logs a one-line `Verification:` (what it ran / skipped / couldn't run); the Reviewer logs a verdict `Basis:` — `behaviorally proven` (ran/observed) or `textual only` (read, not run) — and classes any prior fix `textually fixed` vs `behaviorally proven`. An `Approved` can't silently mean "looked fine on read": if correctness rides on runtime behavior and nothing ran, `textual only` is the strongest honest verdict. Scales to the artifact — a pure doc answers `N/A — non-executable artifact`.
skills/relay/RELAY-sample.md:28:10. **Evidence contract — state your proof every turn.** The Producer logs a one-line `Verification:` (what it ran / skipped / couldn't run); the Reviewer logs a verdict `Basis:` — `behaviorally proven` (ran/observed) or `textual only` (read, not run) — and classes any prior fix `textually fixed` vs `behaviorally proven`. An `Approved` can't silently mean "looked fine on read": if correctness rides on runtime behavior and nothing ran, `textual only` is the strongest honest verdict. Scales to the artifact — a pure doc answers `N/A — non-executable artifact`.
skills/relay/RELAY-sample.md:59:- [Blocker] fuzzy-match → FACT — **Modified** → kept FACT but gated it: line 96 now requires exact match after hash-normalization; ≤2 on raw IDs falls through to PATTERN. The ≤2 window only ever fired on casing/encoding artifacts of the *same* device, so exact-after-normalize preserves intent without over-claiming. · Proof: `pytest -q` → 12 passed (added `test_fuzzy_id_is_pattern_not_fact`).
skills/spike-360/SKILL.md:44:- **Audit-only** — it observes; nothing reads it back as truth.
skills/honest/SKILL.md:22:The output serves a human and a machine simultaneously, so its shape is deliberate:
skills/honest/SKILL.md:47:- **Confirmed (FACT)** — directly observed. The test passed, the code path exists and is exercised, the CHANGELOG entry has a matching commit.
skills/honest/SKILL.md:96:- **Preserve history, keep the live file clean.** If `HONEST.md` already exists, rename the old one to `HONEST-<YYYY-MM-DD>.md` first, then write the fresh one. This lets the operator see maturity drift over time without bloating the file the downstream LLM reads.
skills/debug-mantra/SKILL.md:13:> 1. **First is reproducibility.** Can the issue — or the artifact — be reproduced or observed reliably?
skills/debug-mantra/SKILL.md:26:**Reproduce = observe the primitive ground truth, not your impression of it.** For a crash that's a failing test; for an *attribution* question ("what posts this?", "where does X come from?") it's inspecting the actual artifact — the real message, record, or raw bytes — **before** theorising about its origin. A screenshot, a rendered view, or a remembered detail is an **observation to verify, not an axiom to build on**: name it as assumption-zero and check it first. The cheapest disproof is usually looking straight at the thing — one query against the real object beats a sweep of the code that *might* have produced it. Beware visual grouping and other rendering artifacts: what looks like "one consolidated thing" may be many separate ones (or vice versa) — confirm against the raw object before any hypothesis inherits the shape.
skills/swe/SKILL.md:70:- [ ] **Observed vs. predicted is kept separate** — the doc never launders a projection ("this will reduce load 40%") as evidence. Predictions are labeled as such.
skills/swe/SKILL.md:188:**Separate what you saw from what you expect.** Observed evidence and predicted behavior are different epistemic objects; a plan that blends them is lying to its future reader.
skills/swe/SKILL.md:207:> | §3 | Blast | Block | Bulk overwrite of `wp_orders` is costly-to-one-way with no shield/tripwire | Run in observe mode first; add a row-count + mismatch-rate tripwire before any write mode |
skills/triangulate/SKILL.md:78:  **Irreversible** — migration, published contract, stored data shape, an API others call, or
skills/workhorse/SKILL.md:136:   published artifact and classify the action `Easy`, `Costly`, or `One-way door`. If the target is
skills/workhorse/SKILL.md:196:  - Execute Rungs 1, 2, 5, and 6 directly (observe ground truth → shortest diff → classify → verify).
skills/workhorse/SKILL.md:198:  - Destructive, externally published, Costly, or One-way-door actions never fast-track, however
skills/workhorse/SKILL.md:205:    proven, run a bounded `/recon` before deciding whether to preserve, merge, archive, or remove it.
skills/ate/SKILL.md:48:#    Local Server (Developer tab -> Start Server). Default: http://localhost:1234/v1
skills/ate/SKILL.md:49:#    Note the exact model identifier shown in LM Studio's server log/model list.
skills/ate/SKILL.md:108:| `1` | `gh issue create` failed. `issue_body.md` is preserved in the working directory for manual filing. |
skills/ate/SKILL.md:115:exit `1` with `issue_body.md` preserved — no traceback, no indefinite hold on the run's completion.
skills/ate/SKILL.md:145:  has hung (check the LM Studio server and the `aider` subprocess). `checkin.py`
skills/start-task/SKILL.md:19:issue creation, task branches, commits, pushes, Codex QA, and opening PRs. Preserve
skills/start-task/SKILL.md:23:do not repeat permission questions already answered. Merge, deployment, and clone
skills/start-task/SKILL.md:59:   hooks installed and checked. Preserve the primary checkout and other sessions.
skills/start-task/SKILL.md:73:4. **Ground the plan in initial recon.** Observe the current artifact or behavior
skills/start-task/SKILL.md:97:   observed problem, per-issue requirements, smallest affected surface, explicit
skills/start-task/SKILL.md:117:   set it, and user overrides preserved? Give the
skills/start-task/SKILL.md:129:   do not require a new marathon, queue, daemon, or parallel executor. Preserve
skills/start-task/SKILL.md:153:   as a failed review, even if a transcript sounds positive. Preserve a resumable
skills/start-task/SKILL.md:169:   when requested; preserve the clone and its evidence until then.
skills/start-task/SKILL.md:181:| Severity (`sev`) | Judge observed or credibly supported potential consequences, including data/work lost, affected users and recovery difficulty. Crashes, data corruption/loss, and work-blocking defects belong in the high band (80–100); do not average away a serious consequence because reports are rare. Within that band, distinguish a recoverable crash from irreversible corruption. Raise the assessment for a recurring same-class defect or rising incident rate; do not infer a shared root cause merely from similar labels. |
skills/start-task/SKILL.md:182:| Priority (`pri`) | Weight urgency strongly toward severity, consequence/reach, recurrence and blocked work, then incorporate the user's stated urgency, deadlines and ordering. Explain departures from severity-led ordering. Keep observed severity honest even when the user schedules something else first. This is LLM assessment of the existing priority axis, not a new ranking formula. |
skills/start-task/SKILL.md:183:| Appeal (`appeal`) | Use **50 (neutral)** unless the user explicitly supplies a score or desirability preference. Preserve a prior explicit user value on resume; if translating a qualitative preference into a number, label that interpretation. Do not infer appeal from bug severity, frequency, developer enthusiasm or apparent popularity. |
skills/start-task/SKILL.md:207:reason, never as an automatic response to an "already rated" refusal. Preserve
skills/start-task/SKILL.md:238:Verify the current app installation supports its path. Preserve any existing
skills/start-task/SKILL.md:241:and content against the maintained source. Report filesystem deployment separately
skills/start-task/SKILL.md:243:using start-task for ordinary work does not deploy skills or change app settings.
skills/10days/SKILL.md:265:- **High calculated scores (`calc >= 250`, or `sev >= 75` / `pri >= 75`)**: serve as a strong signal to prioritize the candidate into earlier waves.
skills/10days/SKILL.md:336:  remains context rather than a new linted schema: it preserves the cross-repo provenance while
skills/timbre/SKILL.md:30:## The one rule everything else serves
skills/timbre/SKILL.md:68:| Anti-samples | Optional, valuable | Writing the author would never publish — the negative space is diagnostic |
skills/timbre/SKILL.md:243:## Draft                (final, with any [GAP: …] preserved)
skills/vendor-stack/SKILL.md:91:"$PDDA/install.sh" /abs/path/to/target-repo          # observe mode, idempotent, self-registers
skills/vendor-stack/SKILL.md:94:Prefer the **no-flag** form on first install: it installs in `observe` mode
skills/vendor-stack/SKILL.md:158:- **Non-destructive PDDA default.** First PDDA install is `observe` mode; it will
skills/hq/find-hq.sh:54:# 2. the current git repo (preserves "operate on the clone I'm standing in")
skills/hq/SKILL.md:109:order — all deterministic, local file/process reads, no server or daemon involved:
skills/standup/collect.sh:9:    # bash error and exit 1 rather than the interface SKILL.md publishes ("2 usage or a contract
skills/standup/collect.sh:395:      # matters (rebase onto upstream, then publish).
skills/standup/collect.sh:428:        # been sitting unpublished longest, which is what staleness means here; the newest one would
skills/standup/collect.sh:1186:# `skills/standup/SKILL.md` publishes "Exit 0 clean · 2 usage or a contract violation · 3 one or more
skills/xyz/SKILL.md:28:repo at once without colliding. A coordinator (you) seeds tasks, observes, and
skills/xyz/SKILL.md:29:scores the run. There is **no server and no git transport** — just a shared
skills/xyz/SKILL.md:2095:1. `tick init` in the target repo (creates `.tick/events/`). Add **`.tick/`** to `.gitignore` — locks are ephemeral, and events/`STATE.md` coordinate via the shared working tree on disk (not git), so agents never need to commit them. (If you specifically want the coordination log preserved in history — as the Trinity experiment did — track `.tick/events/` instead, but never the lock dir.)
skills/rpr/SKILL.md:65:Use the bundled `write_rules.py` rather than hand-editing JSON — it preserves existing
skills/rpr/tests/run_tests.py:212:    check("write: special chars (quotes/parens) preserved verbatim",
skills/agent-chorus/sync-to-standalone.sh:2:# Publish the canonical XYZ Forge package into the standalone distribution.
skills/agent-chorus/sync-to-standalone.sh:8:MANIFEST="$SKILL_DIR/publish-manifest.tsv"
skills/agent-chorus/sync-to-standalone.sh:18:  --apply    Copy declared files, preserve modes, and record the canonical revision.
skills/agent-chorus/sync-to-standalone.sh:34:[ -f "$MANIFEST" ] || { echo "Missing publish manifest: $MANIFEST" >&2; exit 1; }
skills/agent-chorus/sync-to-standalone.sh:42:  echo "Source and destination repositories are identical; refusing to publish." >&2
skills/agent-chorus/sync-to-standalone.sh:48:  echo "Canonical source is dirty; commit it before publishing so the recorded revision is truthful." >&2
skills/agent-chorus/sync-to-standalone.sh:52:allowed_file="$(mktemp "${TMPDIR:-/tmp}/agent-chorus-publish-allowed.XXXXXX")"
skills/agent-chorus/sync-to-standalone.sh:65:  echo "Publish manifest has a malformed row or duplicate destination." >&2
skills/agent-chorus/sync-to-standalone.sh:87:  echo "Remove them deliberately or add them to publish-manifest.tsv in the canonical repository." >&2
skills/agent-chorus/sync-to-standalone.sh:138:    echo "Published canonical revision $SOURCE_REVISION to $DEST_REPO"
skills/agent-chorus/TELEMETRY.md:15:  sidecars: observability must not bloat the artifact it observes).
skills/agent-chorus/SKILL.md:107:observed results. Do not put secrets, credentials, or unrelated conversation into the packet. Write
skills/agent-chorus/SKILL.md:161:doorbell marker. `not observed/manual` means only that no watch sidecar exists; it is not evidence
skills/agent-chorus/SKILL.md:475:  operator answers. Observed incident: the operator's keyboard macro accidentally pasted an
skills/read-only/SKILL.md:94:2. Add rules to the allowlist array the file *already uses*. The current schema is `permissions.allow`; if the file instead has a legacy or root-level allow key (e.g. `allowedTools`), append to that existing array rather than introducing a second list the harness may ignore. Only create `permissions.allow` fresh when no allowlist exists at all. Preserve every other key untouched, including `deny` and `ask`.
skills/agent-chorus/scripts/agent_chorus.py:932:            """Materialize the reserved ID into a readable discussion. Extracted so the supersede
skills/agent-chorus/scripts/agent_chorus.py:996:                    # leaves nothing behind but the reserved directory it always did.
skills/agent-chorus/scripts/agent_chorus.py:1343:    """Describe a seat's observed doorbell state, or None when it may be participating manually."""
skills/agent-chorus/scripts/agent_chorus.py:1350:            return f"ACTIVE — owns NEXT{duration}; heartbeat not observed/manual"
skills/agent-chorus/scripts/agent_chorus.py:1367:    """One advisory peer line, or None when no doorbell has been observed for that seat."""
skills/agent-chorus/scripts/agent_chorus.py:1425:        print(f"DOORBELL {member}: {state or 'not observed/manual'}")
skills/agent-chorus/scripts/agent_chorus.py:2526:            server, actual_port = agent_chorus_bridge.start_bridge_server(
skills/agent-chorus/scripts/agent_chorus.py:2560:                server.serve_forever()
skills/agent-chorus/scripts/agent_chorus.py:2562:                server.server_close()
skills/agent-chorus/scripts/agent_chorus_bridge.py:16:import http.server
skills/agent-chorus/scripts/agent_chorus_bridge.py:23:import socketserver
skills/agent-chorus/scripts/agent_chorus_bridge.py:267:class ThreadingHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
skills/agent-chorus/scripts/agent_chorus_bridge.py:272:class BridgeRequestHandler(http.server.BaseHTTPRequestHandler):
skills/agent-chorus/scripts/agent_chorus_bridge.py:275:    server: ThreadingHTTPServer
skills/agent-chorus/scripts/agent_chorus_bridge.py:279:        return getattr(self.server, "bridge_manager")
skills/agent-chorus/scripts/agent_chorus_bridge.py:307:            self.log_message("Internal server error: %s", exc)
skills/agent-chorus/scripts/agent_chorus_bridge.py:308:            self._send_json(500, {"error": "internal server error", "code": "internal_error"})
skills/agent-chorus/scripts/agent_chorus_bridge.py:720:def start_bridge_server(
skills/agent-chorus/scripts/agent_chorus_bridge.py:729:) -> Tuple[ThreadingHTTPServer, int]:
skills/agent-chorus/scripts/agent_chorus_bridge.py:730:    """Start the bridge server in a background thread or return the server instance."""
skills/agent-chorus/scripts/agent_chorus_bridge.py:744:    server = ThreadingHTTPServer((host, port), BridgeRequestHandler)
skills/agent-chorus/scripts/agent_chorus_bridge.py:745:    # GH-384 review (Qwen Q6): ThreadingHTTPServer with no socket timeout means a slow header
skills/agent-chorus/scripts/agent_chorus_bridge.py:750:    server.timeout = REQUEST_SOCKET_TIMEOUT
skills/agent-chorus/scripts/agent_chorus_bridge.py:751:    setattr(server, "bridge_manager", manager)
skills/agent-chorus/scripts/agent_chorus_bridge.py:752:    actual_port = server.server_address[1]
skills/agent-chorus/scripts/agent_chorus_bridge.py:753:    return server, actual_port
skills/agent-chorus/scripts/agent_chorus_bridge.py:805:        help="Publish the tunnel with NO authentication. Every endpoint becomes world-readable "
skills/agent-chorus/scripts/agent_chorus_bridge.py:813:    server, actual_port = start_bridge_server(
skills/agent-chorus/scripts/agent_chorus_bridge.py:828:    manager = getattr(server, "bridge_manager", None)
skills/agent-chorus/scripts/agent_chorus_bridge.py:852:        server.server_close()
skills/agent-chorus/scripts/agent_chorus_bridge.py:884:        server.serve_forever()
skills/agent-chorus/scripts/agent_chorus_bridge.py:886:        server.server_close()
skills/agent-chorus/scripts/agent_chorus_client.py:219:    parser.add_argument("--url", default="http://127.0.0.1:8080", help="Bridge server URL (default: http://127.0.0.1:8080)")
skills/agent-chorus/README.md:13:> first and are published one way into the standalone repository. Project website:
skills/agent-chorus/README.md:69:clause is what makes every harness load the skill; a bare "Join…" line was observed to be answered as
skills/agent-chorus/README.md:84:or delete them automatically. A future migration tool must preserve each raw conversation rather
skills/agent-chorus/README.md:108:## Publish the standalone distribution
skills/agent-chorus/README.md:110:XYZ Forge is canonical. `publish-manifest.tsv` declares every file shipped to the standalone
skills/agent-chorus/README.md:112:then publish only from a clean committed canonical revision:
skills/agent-chorus/README.md:120:Set `AGENT2AGENT_STANDALONE_REPO` to select another checkout. The publisher refuses undeclared
skills/agent-chorus/README.md:121:tracked destination files, preserves declared executable modes, verifies byte parity, and records
skills/agent-chorus/test-standalone.sh:94:Does the package preserve its documented contract?
skills/agent-chorus/test-standalone.sh:397:Every helper-owned state transition was observed.
skills/agent-chorus/test-standalone.sh:449:[ "$?" -ne 0 ] && pass "discussion IDs are reserved across the whole store" \
skills/agent-chorus/publish-manifest.tsv:14:644	skills/agent-chorus/publish-manifest.tsv	skills/agent-chorus/publish-manifest.tsv
skills/agent-chorus/standalone/README.md:54:- [`publish-manifest.tsv`](skills/agent-chorus/publish-manifest.tsv) — declared canonical publishing surface
skills/agent-chorus/standalone/README.md:61:then be published one way into this repository.
skills/standup/triage.py:89:    # Tier 2 — a crash the session actually observed, never inferred reachability.
skills/standup/triage.py:187:def render(items, notices, verdict_code, clause, degraded_ids, page, pages):
skills/standup/triage.py:198:    out.append("Do this now" + (" (page %d/%d)" % (page, pages) if pages > 1 else ""))
skills/standup/triage.py:316:    pages = max(1, (len(kept) + CAP - 1) // CAP)
skills/standup/triage.py:317:    page = min(max(1, args.page), pages)
skills/standup/triage.py:339:                   [d for d in degraded if d != "D3"], page, pages)
validate.sh:523:  "gh353-vendored-router-audit.sh"    # GH-353 (audit and prompt for target ROUTER.md ROADMAP.md frozen status during vendored updates)
test/gh353-vendored-router-audit.sh:2:# gh353-vendored-router-audit.sh — GH-353: audit and remediate target ROUTER.md ROADMAP.md frozen status.
test/gh353-vendored-router-audit.sh:89:AUDIT_PY="$ROOT_DIR/utils/py/router_audit.py"
test/gh353-vendored-router-audit.sh:97:echo "== test: gh353-vendored-router-audit =="
test/gh353-vendored-router-audit.sh:937:ok "router_audit.py --fix returns rc=0 on CRLF fixture" "$(is "$rc_fix" "0"; echo $?)"
   270	                    return True
   271	
   272	        if re.search(r"\b(current\s+work|active\s+effort|active\s+tasks|current\s+tasks|current\s+priorities|active\s+items)\b", clause, re.IGNORECASE):
   273	            if not re.search(r"\b(?:is\s+(?:the\s+)?(?:frozen|legacy)|obsolete|frozen\s+since)\b", clause, re.IGNORECASE):
   274	                return True
   275	
   276	    return False
   277	
   278	
   279	def is_affirmative_dashboard_role_line(line):
   280	    """Returns True if a Role split line affirmatively declares ROADMAP-DASHBOARD.md as the generated view of the roadmap ledger."""
   281	    m = re.search(OWNED_DASHBOARD_DECL_RE, line, re.IGNORECASE)
   282	    if not m:
   283	        return False
   284	    desc = m.group(1)
   285	
   286	    if re.search(r"\b(do\s+not\s+read|do\s+not\s+use|obsolete|deprecated|not\s+active|not\s+used|historical\s+archive|historical\s+context|not\s+the\s+source|not\s+(?:a\s+)?generated|not\s+current|lives\s+elsewhere)\b", desc, re.IGNORECASE):
   287	        return False
   288	    if (re.search(r"\b(?:generated|human-readable)\b.*?\b(?:view\s+of\s+(?:the\s+)?roadmap|roadmap\s+ledger|view\s+of\s+the\s+ledger)\b", desc, re.IGNORECASE)
   289	            or re.search(r"\b(?:view\s+of\s+(?:the\s+)?roadmap|roadmap\s+ledger)\b.*?\b(?:generated|human-readable)\b", desc, re.IGNORECASE)):
   290	        return True
   291	    return False
   292	
   293	
   294	def is_affirmative_dashboard_startup_directive(line):
   295	    """Returns True if a Startup line affirmatively directs reading the dashboard for current work/state in the dashboard clause itself."""
   296	    if not re.search(DASHBOARD_MENTION_RE, line, re.IGNORECASE):
   297	        return False
   298	    for clause in split_clauses(line):
   299	        if not re.search(DASHBOARD_MENTION_RE, clause, re.IGNORECASE):
   300	            continue
   301	        if not re.search(r"\b(?:Read|Consult|Open|Check|See|Inspect|Use)\s+(?:`?ROADMAP-DASHBOARD\.md`?|\[[^\]]*\]\([^)]*ROADMAP-DASHBOARD\.md[^)]*\))", clause, re.IGNORECASE):
   302	            continue
   303	        if re.search(r"\b(?:do\s+not|never)\s+(?:read|consult|open|check|use)\b", clause, re.IGNORECASE):
   304	            continue
   305	        if re.search(r"\b(?:historical\s+(?:reference|archive|context)|only\s+for\s+historical|obsolete|not\s+current|not\s+for\s+current)\b", clause, re.IGNORECASE):
   306	            continue
   307	        if re.search(r"\b(active\s+effort|parked\s+intake|current\s+state|active\s+tasks|current\s+work|find\s+(?:the\s+)?active|active\s+work|roadmap\s+ledger)\b", clause, re.IGNORECASE) or re.search(r"\b(?:find\s+(?:the\s+)?active|to\s+find)\b", clause, re.IGNORECASE):
   308	            if not re.search(r"\bnot\s+current\b", clause, re.IGNORECASE):
   309	                return True
   310	    return False
   311	
   312	
   313	def is_legacy_active_role_line(line):
   314	    """Returns True if a Role split line affirmatively declares ROADMAP.md as the active pointer ledger of current work."""
   315	    m = re.search(OWNED_ROADMAP_DECL_RE, line, re.IGNORECASE)
   316	    if not m:
   317	        return False
   318	    desc = m.group(1)
   319	
   320	    if re.search(r"\b(not\s+active|obsolete|frozen|legacy|historical|archived|releases\.db|releases\.sql|ROADMAP_SOURCE)\b", desc, re.IGNORECASE):
   321	        return False
   322	    for clause in split_clauses(desc):
   323	        if re.search(r"\b(?:the\s+pointer\s+ledger\s+of\s+current|pointer\s+ledger\s+of\s+current|active\s+pointer|ledger\s+of\s+current|current,\s+completed|pointer\s+ledger\s+of\s+active)\b", clause, re.IGNORECASE):
   324	            return True
   325	        if re.search(r"\b(?:the\s+pointer\s+ledger|pointer\s+ledger)\b", clause, re.IGNORECASE) and re.search(r"\b(?:current\s+work|active\s+effort|completed,\s+attempted|current\s+tasks)\b", clause, re.IGNORECASE):
   326	            return True
   327	    return False
   328	
   329	
   330	def audit_router(root, content_override=None):
   331	    """Audit ROUTER.md in root (or content_override if provided). Returns a dict."""
   332	    router_path = os.path.join(root, "ROUTER.md")
   333	    releases_mode, mode_err = get_repo_mode(root)
   334	
   335	    result = {
   336	        "root": root,
   337	        "router_path": router_path,
   338	        "exists": os.path.exists(router_path) if content_override is None else True,
   339	        "readable": True,
   340	        "releases_mode": releases_mode,
   341	        "drift": False,
   342	        "error": False,
   343	        "reasons": [],
   344	        "fixes_available": False,
   345	    }
   346	
   347	    if mode_err:
   348	        result["error"] = True
   349	        result["reasons"].append(mode_err)
   350	        return result
   351	
   352	    if not result["exists"]:
   353	        result["error"] = True
   354	        result["reasons"].append("ROUTER.md does not exist")
   355	        return result
   356	
   357	    if content_override is not None:
   358	        content = content_override
   359	    else:
   360	        try:
   361	            with open(router_path, "r", newline="", encoding="utf-8") as f:
   362	                content = f.read()
   363	        except Exception as e:
   364	            result["readable"] = False
   365	            result["error"] = True
   366	            result["reasons"].append(f"could not read ROUTER.md: {e}")
   367	            return result
   368	
   369	    sections = find_sections(content)
   370	    role_sections = [s for s in sections if re.match(r"^Role\s+split$", s["heading"], re.IGNORECASE)]
   371	    startup_sections = [s for s in sections if re.match(r"^Startup\s+sequence$", s["heading"], re.IGNORECASE)]
   372	
   373	    if len(role_sections) > 1:
   374	        result["drift"] = True
   375	        result["reasons"].append(f"Duplicate '## Role split' sections detected ({len(role_sections)})")
   376	    if len(startup_sections) > 1:
   377	        result["drift"] = True
   378	        result["reasons"].append(f"Duplicate '## Startup sequence' sections detected ({len(startup_sections)})")
   379	
   380	    role_section = role_sections[0] if role_sections else None
   381	    startup_section = startup_sections[0] if startup_sections else None
   382	
   383	    all_role_lines = []
   384	    for s in role_sections:
   385	        all_role_lines.extend(get_unfenced_lines(s["body"]))
   386	
   387	    all_startup_lines = []
   388	    for s in startup_sections:
   389	        all_startup_lines.extend(get_unfenced_lines(s["body"]))
   390	
   391	    if releases_mode:
   392	        # Releases Mode Validation
   393	        if role_section is None:
   394	            result["drift"] = True
   395	            result["reasons"].append("ROUTER.md missing '## Role split' section")
   396	        else:
   397	            has_affirmative_dashboard = any(
   398	                is_affirmative_dashboard_role_line(l) for l in all_role_lines
   399	            )
   400	            owned_roadmap_lines = [
   401	                l for l in all_role_lines
   402	                if re.search(OWNED_ROADMAP_DECL_RE, l, re.IGNORECASE)
   403	            ]
   404	
   405	            if not has_affirmative_dashboard:
   406	                result["drift"] = True
   407	                result["reasons"].append("Role split does not affirmatively declare ROADMAP-DASHBOARD.md as the generated roadmap view")
   408	            if not owned_roadmap_lines:
   409	                result["drift"] = True
   410	                result["reasons"].append("Role split does not contain a ROADMAP.md declaration")
   411	            else:
   412	                for r_line in owned_roadmap_lines:
   413	                    clauses = split_clauses(r_line)
   414	                    is_frozen_clause = any(
   415	                        (re.search(ROADMAP_MENTION_RE, c, re.IGNORECASE) or idx == 0)
   416	                        and re.search(r"\b(frozen|legacy)\b", c, re.IGNORECASE)
   417	                        and not re.search(r"\b(?:not|isn't|never)\s+(?:frozen|legacy)\b", c, re.IGNORECASE)
   418	                        for idx, c in enumerate(clauses)
   419	                    )
   420	                    has_affirmative_db_clause = any(
   421	                        (re.search(r"\b(?:releases\.db|releases\.sql)\b", c, re.IGNORECASE) and re.search(r"\b(?:is\s+(?:the\s+)?source|source\s+of\s+truth)\b", c, re.IGNORECASE) and not re.search(r"\b(?:not|never)\s+(?:the\s+)?source\b", c, re.IGNORECASE))
   422	                        or (re.search(r"\b(?:the\s+)?(?:releases\s+db|source\s+of\s+truth)\b", c, re.IGNORECASE) and re.search(r"\b(?:releases\.db|releases\.sql)\b", c, re.IGNORECASE) and not re.search(r"\b(?:not|never)\s+(?:the\s+)?source\b", c, re.IGNORECASE))
   423	                        for c in clauses
   424	                    )
   425	                    has_negated_db_clause = any(
   426	                        re.search(r"\b(?:releases\.db|releases\.sql)\b.*?\b(?:not\s+(?:the\s+)?source)\b", c, re.IGNORECASE)
   427	                        or re.search(r"\b(?:not\s+(?:the\s+)?source)\b.*?\b(?:releases\.db|releases\.sql)\b", c, re.IGNORECASE)
   428	                        for c in clauses
   429	                    )
   430	                    has_active_clause = any(
   431	                        (re.search(r"\b(active\s+pointer|active\s+ledger|current\s+work|current\s+priorities|the\s+pointer\s+ledger\s+of\s+current|active\s+effort|used\s+for\s+current)\b", c, re.IGNORECASE)
   432	                         or re.search(r"(?:=|\b)\s*active\b", c, re.IGNORECASE))
   433	                        and not re.search(r"\b(not\s+active|former\s+active)\b", c, re.IGNORECASE)
   434	                        for c in clauses
   435	                    )
   436	                    has_negated_frozen_clause = any(
   437	                        re.search(r"\b(?:not|isn't|never)\s+(?:frozen|legacy)\b", c, re.IGNORECASE)
   438	                        for c in clauses
   439	                    )
   440	
   441	                    if has_active_clause or has_negated_frozen_clause or has_negated_db_clause or not (is_frozen_clause and has_affirmative_db_clause):
   442	                        result["drift"] = True
   443	                        result["reasons"].append("Role split describes ROADMAP.md with active terms or lacks explicit frozen/legacy + releases DB source-of-truth declaration")
   444	
   445	            for l in all_role_lines:
   446	                if is_role_stray_active_roadmap_line(l):
   447	                    result["drift"] = True
   448	                    result["reasons"].append("Role split contains stray active ROADMAP.md clause")
   449	
   450	        if startup_section is None:
   451	            result["drift"] = True
   452	            result["reasons"].append("ROUTER.md missing '## Startup sequence' section")
   453	        else:
   454	            has_affirmative_dashboard_startup = any(
   455	                is_affirmative_dashboard_startup_directive(l) for l in all_startup_lines
   456	            )
   457	            has_active_roadmap_read = any(
   458	                is_active_roadmap_startup_directive(l) for l in all_startup_lines
   459	            )
   460	
   461	            if not has_affirmative_dashboard_startup:
   462	                result["drift"] = True
   463	                result["reasons"].append("Startup sequence does not contain an affirmative directive to read ROADMAP-DASHBOARD.md for current work")
   464	            if has_active_roadmap_read:
   465	                result["drift"] = True
   466	                result["reasons"].append("Startup sequence contains active ROADMAP.md directive without frozen/legacy note")
   467	
   468	        if result["drift"]:
   469	            result["fixes_available"] = True
   470	
   471	    else:
   472	        # Legacy Mode Validation
   473	        if role_section is None:
   474	            result["drift"] = True
   475	            result["reasons"].append("Legacy ROUTER.md missing '## Role split' section")
  1010	                        else:
  1011	                            log(f"  Issue #{issue_num} is OPEN — preserving active ROADMAP.md entry (skipping move to Completed)")
  1012	
  1013	                # GH-271: reference-only mentions never promote or move anything. When the
  1014	                # mentioned issue is OPEN (or an unknowable-state umbrella), record merge
  1015	                # evidence on its active doc — the "Advances GH-N (phase k of n)" convention
  1016	                # GH-202/GH-232 pin — and nothing else. Issues already handled above (the
  1017	                # force-promote widening) are skipped.
  1018	                for issue_num in mentioned_issues:
  1019	                    if issue_num in action_issues:
  1020	                        continue
  1021	                    doc_path = find_active_doc_for_issue(repo_root, issue_num)
  1022	                    if not doc_path:
  1023	                        continue
  1024	                    issue_state = fetch_issue_state(repo_root, issue_num, offline_manifest)
  1025	                    fm = parse_doc_frontmatter(doc_path)
  1026	                    is_multiphase = (
  1027	                        fm.get("umbrella") in ("true", "1", "yes")
  1028	                        or fm.get("multiphase") in ("true", "1", "yes")
  1029	                        or fm.get("multi_phase") in ("true", "1", "yes")
  1030	                    )
  1031	                    is_open = (issue_state == "OPEN") or (issue_state is None and is_multiphase)
  1032	                    if is_open and is_merged:
  1033	                        log(f"  Issue #{issue_num} referenced without a closing keyword and OPEN — recording merge evidence only")
  1034	                        record_merge_evidence(doc_path, pr_meta, dry_run=args.dry_run, journal=journal)
  1035	
  1036	            # Global roadmap cleanups
  1037	            fix_mangled_roadmap_entries(repo_root, dry_run=args.dry_run, journal=journal)
  1038	
  1039	            # Subprocess orchestration
  1040	            run_subprocesses(
  1041	                repo_root,
  1042	                dry_run=args.dry_run,
  1043	                journal=journal,
  1044	                reconciled_issues=reconciled_issues,
  1045	            )
  1046	
  1047	            # Final validation gate
  1048	            if not args.dry_run:
  1049	                run_validation_gate(repo_root)
  1050	
  1051	            log("Wave reconciliation completed successfully! ✅")
  1052	            journal.cleanup()
  1053	
  1054	    except ReconcileError as re_err:
  1055	        journal.rollback()

exec
/bin/zsh -lc "nl -ba .github/workflows/pages.yml | sed -n '1,65p'; nl -ba validate.sh | sed -n '515,528p'; nl -ba relay-automation/xyz-vendor.sh | sed -n '330,355p'; nl -ba relay-automation/xyz-sync.sh | sed -n '20,40p'; nl -ba README.md | sed -n '1,50p'; rg -n 'LEADERBOARD\\.html|RELEASES-PREVIEW\\.html' ROUTER.md AGENTS.md GUIDING-PRINCIPLES.md README.md .github/workflows relay-automation/xyz-vendor.sh relay-automation/xyz-sync.sh utils/py/router_audit.py || true" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej
 succeeded in 0ms:
     1	name: Pages
     2	
     3	# Deploys the project site at https://hiqs-labs.github.io/XYZ-forge/ from PAGES/.
     4	# The two data-driven pages (roadmap.html, models-harnesses.html) are REGENERATED at
     5	# deploy time by utils/py/site_build.py from the committed releases.db / harnesses.db,
     6	# so a push that changes the ledgers republishes the site without anyone rebuilding
     7	# by hand. Static pages are served as committed. Pages is enabled on the repo with
     8	# build_type=workflow (Settings -> Pages -> Source: GitHub Actions).
     9	
    10	on:
    11	  push:
    12	    branches: [development, main]
    13	    paths:
    14	      - "PAGES/**"
    15	      - "utils/py/site_build.py"
    16	      - "utils/py/releases_app.py"
    17	      - "releases.db"
    18	      - "releases.sql"
    19	      - "harnesses.db"
    20	      - "harnesses.sql"
    21	      - ".github/workflows/pages.yml"
    22	  workflow_dispatch:
    23	
    24	permissions:
    25	  contents: read
    26	  pages: write
    27	  id-token: write
    28	
    29	concurrency:
    30	  group: pages
    31	  cancel-in-progress: true
    32	
    33	jobs:
    34	  build:
    35	    runs-on: ubuntu-latest
    36	    timeout-minutes: 10
    37	    steps:
    38	      - uses: actions/checkout@v4
    39	      - uses: actions/setup-python@v5
    40	        with:
    41	          python-version: "3.x"
    42	      - name: Regenerate data-driven pages from the committed ledgers
    43	        run: python3 utils/py/site_build.py
    44	      - uses: actions/upload-pages-artifact@v3
    45	        with:
    46	          path: PAGES
    47	
    48	  deploy:
    49	    needs: build
    50	    runs-on: ubuntu-latest
    51	    timeout-minutes: 10
    52	    environment:
    53	      name: github-pages
    54	      url: ${{ steps.deployment.outputs.page_url }}
    55	    steps:
    56	      - id: deployment
    57	        uses: actions/deploy-pages@v4
   515	  "mktemp-trap-guard.sh"         # GH-177 (static audit: no unguarded mktemp-into-destructive-rm-rf/cd-recapture pattern anywhere in the repo)
   516	  "hq-marathon-scan.sh"          # GH-158 (cross-repo marathon aggregation + preflight — written, never registered until GH-192)
   517	  "hq-rollup.sh"                 # GH-192 (marathon-scan.sh bridged verbatim into the Obsidian daily rollup)
   518	  "gh238-hq-releases-mode.sh"    # GH-238 (releases-mode park: roadmap add verb + hq park DB sink + sync no-op)
   519	  "gh239-hq-status-releases-mode.sh"  # GH-239 (releases-mode status + rollup read from the releases DB)
   520	  "gh243-dashboard-staleness-guard.sh" # GH-243 (push guard: ledger write without dashboard regen is refused)
   521	  "gh257-roadmap-ledger-fixes.sh"     # GH-257 (roadmap ledger validation, dropped-row warnings, update subcommand, staleness diagnosis)
   522	  "gh269-roadmap-retired.sh"          # GH-269 (verify ROADMAP.md is retired, tools operate on releases.db, move/update CLI verbs)
   523	  "gh353-vendored-router-audit.sh"    # GH-353 (audit and prompt for target ROUTER.md ROADMAP.md frozen status during vendored updates)
   524	  "jog-queue.sh"                      # GH-259 (Jog serial queue schema, CRUD operations, lease recovery, and execution runner)
   525	  "gh290-ate-variation-grid.sh"       # GH-290 (ATE variation grid: contract loaders, land verification,
   526	                                     #   receipt-writer robustness — deterministic hostile-input matrix)
   527	  "gh291-contract-goldens.sh"         # GH-291 Scope 2 (golden @1 conformance: producer fidelity vs
   528	                                     #   committed fixtures, loader accept/refuse matrix, future-schema
   330	#   bin/               tick, validate-relay-block, marathon-yaml
   331	#   src/               the tick/marathon JS core
   332	#   utils/             helper scripts, preflights, and planning utilities (in Tier 1, minus the RELEASES overlay)
   333	#   test/              the shim + feature tests, so a vendored repo can self-verify
   334	#   skills/            the consult / relay-xyz / xyz skill definitions travel with the harness
   335	#
   336	# Vendoring tiers (GH-197):
   337	#   Tier 1 (default): core harness only. Full mirror minus the RELEASES_OVERLAY manifest
   338	#                     (releases_app.py, releases_cycle.py, releases-merge-resolve.sh, release-lanes.sh, timeline/,
   339	#                      relay-automation/xyz-releases-onboard.sh).
   340	#                     Uses a deny-list mechanism to prevent the GH-77 curated-manifest drop failure.
   341	#   Tier 2 (opt-in):  --with-releases (or auto-detected when releases.db is present at target root).
   342	#                     Retains the full overlay and stages RELEASES-DB-FAQS.md into .xyz/.
   343	VENDOR_DIRS="relay-automation bin src utils test skills"
   344	RELEASES_OVERLAY="utils/py/releases_app.py utils/py/releases_cycle.py utils/releases-merge-resolve.sh utils/release-lanes.sh utils/timeline relay-automation/xyz-releases-onboard.sh"
   345	
   346	materialize_vendor() {
   347	  local d
   348	
   349	  rm -rf "$STAGE_DIR"
   350	  mkdir -p "$STAGE_DIR"
   351	
   352	  for d in $VENDOR_DIRS; do
   353	    [ -d "$HARNESS_ROOT/$d" ] || die "missing $d/ under $HARNESS_ROOT (cannot build a complete vendor)"
   354	    mkdir -p "$STAGE_DIR/$d"
   355	    # Trailing '/.' copies the directory *contents* (incl. nested hooks/, fixtures/) into the stage.
    20	# source_commit=unknown. Keep a small manifest of behaviorally meaningful, static guard patterns
    21	# and inspect the installed copy itself. This keeps `check` report-only while making a missing
    22	# guard distinguishable from ordinary provenance drift.
    23	#
    24	# GH-312 -- what `update` does to the target's RUNTIME STATE: it updates harness CODE only and
    25	# preserves state the target owns. `xyz-vendor.sh` rebuilds the tree by staging a fresh mirror of
    26	# the harness and swapping it in over `rm -rf`, so anything the target accumulated that is not
    27	# harness source would be destroyed unread -- and `.xyz/` is gitignored, so that loss has no git
    28	# recovery path. materialize_vendor() therefore carries these across the swap:
    29	#   relay-system/  .tick/  .relay-driver.lock  XYZ.json  XYZ.json.lock/  XYZ.heartbeat.json
    30	# Adding a new runtime artifact under `.xyz/` means adding it to that preserve list, or `update`
    31	# will silently delete it. Regression coverage: test/gh312-vendor-preserves-state.sh.
    32	
    33	usage() {
    34	  cat <<'USAGE'
    35	Usage:
    36	  xyz-sync.sh list
    37	  xyz-sync.sh update <dir> | --all
    38	  xyz-sync.sh delete <dir> | --all [--yes]
    39	  xyz-sync.sh check <dir> | --all
    40	  xyz-sync.sh --list
     1	# XYZ Forge
     2	
     3	**A local-first engineering operations system for running AI coding agents as a workforce.**
     4	
     5	XYZ Forge coordinates several AI coding agents — Claude Code, Codex, `agy` (Google's Antigravity
     6	CLI), and others — working on the same repositories, and it carries the surrounding machinery an
     7	unattended agent run actually needs: specified work, collision-free lanes, verification gates, and a
     8	receipted record of what happened.
     9	
    10	It started as a coordination kernel. It has become the loop around it:
    11	
    12	```
    13	capture → rate → plan → preflight → execute → gate → land → record
    14	```
    15	
    16	Every stage is a CLI verb or a skill, every artifact is on your disk, and no stage requires a
    17	server, an account, or an API key for the coordination layer itself.
    18	
    19	> **Safety and warranty:** XYZ Forge is provided **"AS IS," without warranty**, under the applicable
    20	> license. Coding-agent automation is inherently risky: models may choose commands through their own
    21	> runtimes and safety controls, outside the intended harness workflow. XYZ Forge cannot guarantee
    22	> model behavior or data integrity; maintain tested, independent backups and follow industry-standard
    23	> backup and recovery practices.
    24	
    25	---
    26	
    27	## Status: alpha, single-operator, moving fast
    28	
    29	Be clear-eyed about what you are adopting.
    30	
    31	| | |
    32	|---|---|
    33	| Age | Current history rooted 2026-08-15 after a 2026-09-02 reset; the project predates it (archival tag `bash-final-2026-07-28`) |
    34	| Release tags | No release tags — two archival tags only; versions are tracked in an internal ledger, not published ([#452](https://github.com/HiQS-Labs/XYZ-forge/issues/452) tracks adopting them) |
    35	| Primary operator | One, with a small collaborator set; most commits are agent-authored |
    36	| Test suite | ~350 registered suites (count drifts weekly); `npm run test:unit` is a 14-case, sub-second kernel check |
    37	| Gates | Local pre-push gate plus hosted CI on `main` and `development` |
    38	| Runtime | Python by default since the `XYZ_PYTHON` flip; frozen Bash twins remain as a fallback |
    39	| Known-weakest area | The frozen Bash fallback paths, and Python static analysis (there is none) |
    40	
    41	This is software that has been used hard by its author against real repositories and has the scar
    42	tissue to show it — several guards in this repo exist because an earlier version destroyed work.
    43	That is a point in its favor and a warning at once. **Run it on a branch. Keep independent backups.**
    44	
    45	---
    46	
    47	## Prove the kernel works — 60 seconds, no accounts
    48	
    49	Tested on **Node 18+**; requires **git**.
    50	

codex
ANSWER: SHIP WITH CHANGES, not as the proposed two-file-only deletion. The adoption-by-presence claim is false for `RELEASES-PREVIEW.html`: post-merge reconciliation recreates it unconditionally. A delete/modify merge conflict can also recreate either HTML view.

FINDINGS

- [Blocker] `wave_reconcile.py` always runs `export_timeline.py --preview` after a non-dry reconciliation, with no existence check, so a missing root `RELEASES-PREVIEW.html` is recreated. The exporter writes its requested output unconditionally. [utils/py/wave_reconcile.py:757](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/py/wave_reconcile.py:757) [utils/py/wave_reconcile.py:769](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/py/wave_reconcile.py:769) [utils/timeline/export_timeline.py:646](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/timeline/export_timeline.py:646)

- [Blocker] The merge resolver is presence-gated only for clean, non-conflicted files. If either HTML filename is unmerged (such as a delete/modify conflict), it adds that filename to `REGEN` regardless of working-tree presence, suppresses a failed `checkout --ours`, and invokes the generator—which recreates the deleted file. Generator failure is a hard error that deliberately leaves the merge open. [utils/releases-merge-resolve.sh:160](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/releases-merge-resolve.sh:160) [utils/releases-merge-resolve.sh:163](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/releases-merge-resolve.sh:163) [utils/releases-merge-resolve.sh:188](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/releases-merge-resolve.sh:188)

- [Pass] The cited `releases_app.refresh_preview()` path is genuinely presence-gated for both files; missing files silently skip refresh. `express.py` snapshots projections only when `lexists`, and `jog_run.py` stages them only when present. [utils/py/releases_app.py:1172](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/py/releases_app.py:1172) [utils/py/releases_app.py:1175](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/py/releases_app.py:1175) [utils/py/express.py:202](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/py/express.py:202) [utils/py/jog_run.py:284](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/py/jog_run.py:284)

- [Pass] Explicit exporter invocation is intentionally unconditional for both artifacts (`--preview` and `--leaderboard`); it creates the supplied/default output path rather than treating absence as an error. That is a generator API, not adoption refresh. [utils/timeline/export_timeline.py:603](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/timeline/export_timeline.py:603) [utils/timeline/export_timeline.py:636](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/timeline/export_timeline.py:636)

- [Pass] The four named tests do not assert that this repository’s root HTML artifacts exist. `gh103` and `gh153` generate into `$WORK`; `gh267` creates fixture projections; `gh57` deliberately adopts views in a fixture to test resolver behavior. The deletion alone should not break them. [test/gh103-timeline-exporter.sh:196](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/test/gh103-timeline-exporter.sh:196) [test/gh153-releases-sidebar-rollup.sh:112](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/test/gh153-releases-sidebar-rollup.sh:112) [test/gh267-express-skill.sh:154](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/test/gh267-express-skill.sh:154) [test/gh57-live-merge-resolve.sh:252](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/test/gh57-live-merge-resolve.sh:252)

- [Pass] I found no formal governance, CI, vendoring, or Pages requirement for either root HTML file. Pages deploys only `PAGES/`; vendor Tier 2 ships the timeline tooling, not root artifacts. [pages.yml:3](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/.github/workflows/pages.yml:3) [pages.yml:42](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/.github/workflows/pages.yml:42) [xyz-vendor.sh:341](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/relay-automation/xyz-vendor.sh:341)

- [Nit] `--serve` does not serve either root artifact: it serves `utils/timeline/` and redirects to `RELEASES.html`. That template still contains links to both root HTML names, so they are a stale navigation route, though not a publication dependency. [utils/timeline/export_timeline.py:546](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/timeline/export_timeline.py:546) [utils/timeline/RELEASES.html:288](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/timeline/RELEASES.html:288)

- [Pass] The Markdown dashboard distinction is real: ROUTER calls it the generated human-readable roadmap view, and `router_audit.py` hard-requires that declaration and a startup directive; its suite is registered in the full gate. [ROUTER.md:11](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/ROUTER.md:11) [GUIDING-PRINCIPLES.md:77](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/GUIDING-PRINCIPLES.md:77) [utils/py/router_audit.py:405](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/py/router_audit.py:405) [validate.sh:523](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/validate.sh:523) The “no CLI alternative” rationale is overstated: ROUTER explicitly offers `releases_app.py roadmap list` as an alternative. [ROUTER.md:27](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/ROUTER.md:27)

- [Should] Rollback is mechanically easy—run both exporter commands and commit the files—but “every consumer resumes refreshing” is too broad. It restores adoption-gated CLI and ordinary merge refreshes; reconciliation never gated preview in the first place, and the resolver’s conflict behavior remains exceptional.

I ran `git grep -n -E 'LEADERBOARD\\.html|RELEASES-PREVIEW\\.html'`; sandboxed macOS tooling prevented usable output, so I corroborated the authoritative tree with `rg -n --hidden --glob '!.git'` and inspected every operational hit.

RECOMMENDATION: Gate `wave_reconcile`’s preview export by pre-existing adoption and define delete/modify resolver behavior (plus regression tests); then delete the HTML files.
tokens used
121,986
ANSWER: SHIP WITH CHANGES, not as the proposed two-file-only deletion. The adoption-by-presence claim is false for `RELEASES-PREVIEW.html`: post-merge reconciliation recreates it unconditionally. A delete/modify merge conflict can also recreate either HTML view.

FINDINGS

- [Blocker] `wave_reconcile.py` always runs `export_timeline.py --preview` after a non-dry reconciliation, with no existence check, so a missing root `RELEASES-PREVIEW.html` is recreated. The exporter writes its requested output unconditionally. [utils/py/wave_reconcile.py:757](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/py/wave_reconcile.py:757) [utils/py/wave_reconcile.py:769](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/py/wave_reconcile.py:769) [utils/timeline/export_timeline.py:646](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/timeline/export_timeline.py:646)

- [Blocker] The merge resolver is presence-gated only for clean, non-conflicted files. If either HTML filename is unmerged (such as a delete/modify conflict), it adds that filename to `REGEN` regardless of working-tree presence, suppresses a failed `checkout --ours`, and invokes the generator—which recreates the deleted file. Generator failure is a hard error that deliberately leaves the merge open. [utils/releases-merge-resolve.sh:160](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/releases-merge-resolve.sh:160) [utils/releases-merge-resolve.sh:163](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/releases-merge-resolve.sh:163) [utils/releases-merge-resolve.sh:188](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/releases-merge-resolve.sh:188)

- [Pass] The cited `releases_app.refresh_preview()` path is genuinely presence-gated for both files; missing files silently skip refresh. `express.py` snapshots projections only when `lexists`, and `jog_run.py` stages them only when present. [utils/py/releases_app.py:1172](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/py/releases_app.py:1172) [utils/py/releases_app.py:1175](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/py/releases_app.py:1175) [utils/py/express.py:202](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/py/express.py:202) [utils/py/jog_run.py:284](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/py/jog_run.py:284)

- [Pass] Explicit exporter invocation is intentionally unconditional for both artifacts (`--preview` and `--leaderboard`); it creates the supplied/default output path rather than treating absence as an error. That is a generator API, not adoption refresh. [utils/timeline/export_timeline.py:603](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/timeline/export_timeline.py:603) [utils/timeline/export_timeline.py:636](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/timeline/export_timeline.py:636)

- [Pass] The four named tests do not assert that this repository’s root HTML artifacts exist. `gh103` and `gh153` generate into `$WORK`; `gh267` creates fixture projections; `gh57` deliberately adopts views in a fixture to test resolver behavior. The deletion alone should not break them. [test/gh103-timeline-exporter.sh:196](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/test/gh103-timeline-exporter.sh:196) [test/gh153-releases-sidebar-rollup.sh:112](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/test/gh153-releases-sidebar-rollup.sh:112) [test/gh267-express-skill.sh:154](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/test/gh267-express-skill.sh:154) [test/gh57-live-merge-resolve.sh:252](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/test/gh57-live-merge-resolve.sh:252)

- [Pass] I found no formal governance, CI, vendoring, or Pages requirement for either root HTML file. Pages deploys only `PAGES/`; vendor Tier 2 ships the timeline tooling, not root artifacts. [pages.yml:3](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/.github/workflows/pages.yml:3) [pages.yml:42](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/.github/workflows/pages.yml:42) [xyz-vendor.sh:341](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/relay-automation/xyz-vendor.sh:341)

- [Nit] `--serve` does not serve either root artifact: it serves `utils/timeline/` and redirects to `RELEASES.html`. That template still contains links to both root HTML names, so they are a stale navigation route, though not a publication dependency. [utils/timeline/export_timeline.py:546](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/timeline/export_timeline.py:546) [utils/timeline/RELEASES.html:288](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/timeline/RELEASES.html:288)

- [Pass] The Markdown dashboard distinction is real: ROUTER calls it the generated human-readable roadmap view, and `router_audit.py` hard-requires that declaration and a startup directive; its suite is registered in the full gate. [ROUTER.md:11](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/ROUTER.md:11) [GUIDING-PRINCIPLES.md:77](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/GUIDING-PRINCIPLES.md:77) [utils/py/router_audit.py:405](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/utils/py/router_audit.py:405) [validate.sh:523](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/validate.sh:523) The “no CLI alternative” rationale is overstated: ROUTER explicitly offers `releases_app.py roadmap list` as an alternative. [ROUTER.md:27](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-77630-hv8gteej/ROUTER.md:27)

- [Should] Rollback is mechanically easy—run both exporter commands and commit the files—but “every consumer resumes refreshing” is too broad. It restores adoption-gated CLI and ordinary merge refreshes; reconciliation never gated preview in the first place, and the resolver’s conflict behavior remains exceptional.

I ran `git grep -n -E 'LEADERBOARD\\.html|RELEASES-PREVIEW\\.html'`; sandboxed macOS tooling prevented usable output, so I corroborated the authoritative tree with `rg -n --hidden --glob '!.git'` and inspected every operational hit.

RECOMMENDATION: Gate `wave_reconcile`’s preview export by pre-existing adoption and define delete/modify resolver behavior (plus regression tests); then delete the HTML files.
