# RELAY · QA: release-tags backfill plan for #452 (plan comment by claude-a)
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
6. **Commit only the relay file** (`relay(gh452-release-tags-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/xyz-452-plan-comment.md** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/XYZ-forge/temp/xyz-452-plan-comment.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: commandcode   ·   Producer: claude-a
- Started: 2026-09-05
- Definition of Done: the plan comment is **executable as written** — every repo-fact claim it
  rests on is true of this repo, its decisions are internally consistent, and its execution order
  is safe. Answer these numbered questions explicitly, each with a citation (file:line, command
  output, or a quoted span of the artifact):

  1. **Ground-truth check (verify in this worktree, don't trust the plan):** (a) does
     `utils/py/releases_app.py` `update` really expose `--gh-release-url`, and is there any
     existing tag/SHA column in `releases.sql`? (b) does `githooks/pre-push` really have NO
     `refs/tags` handling today? (c) `git tag --list` — exactly the two archival tags named?
     (d) do the four candidate SHAs (136eafbc, cd0f5bdb, 713ba6d1, 17b18b84) exist with the
     commit dates the plan claims?
  2. **Decision soundness:** decision 3 reuses `gh_release_url` instead of a tag-SHA column,
     while the vendor-stamping follow-up arc consumes the tag convention. Is that consistent, or
     does the vendor arc silently depend on a schema change the plan deferred?
  3. **Reachability:** is the "0.1.0–0.3.0 have no identifiable landing commit" claim correctly
     derived (check `git log` dates on the two archival refs), and is skipping them consistent
     with the issue body's "otherwise start from the next release"?
  4. **Hook carve-out safety (Phase A step 2):** all-annotated-`v*`-tags + targets already on the
     remote ⇒ skip the suite. Is this genuinely fail-closed, or is there a bypass (lightweight
     tag, non-`v` name, tag pointing at a commit pushed to a side branch without ever being
     gated)?
  5. **Execution order:** are the 8 steps correctly ordered and complete — e.g. is anything
     missing around the `PAGES/` status copy, `provenance.jsonl` evidence for the gate-claim
     runs, or post-merge reconcile duties in AGENTS.md?
  6. **Acceptance criteria:** can each criterion actually fail when it should ("a check that
     cannot fail is not a check")? Name any that are decorative as written.

  Verdict: **Approved** | **Changes requested** | **Blocked**, plus the mandatory `swept file:`
  line. Cite; uncited `[Pass]` findings get downgraded.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### R1 · Reviewer (agent deepseek, bound to Reviewer this turn) · 2026-09-06

**Verdict: Changes requested** — the plan's shape, decisions, and ordering are sound and most repo-fact claims verified true in this worktree, but one ledger claim is false as written, the candidate-locator command is not reproducible as written, the hook carve-out's reachability clause is undefined for the exact push it targets, two repo-specific duties are missing from the step list, and two acceptance checks cannot fail against the property they name. No Blockers: every fix is plan-text-local, and Phase B is unaffected by the false claim (the 0.7.x rows really are NULL).

Provenance note: `.relay-artifacts/` was not seeded in this worktree; the artifact was read at the Setup-named source `/Users/noelsaw/Documents/GH Repos/XYZ-forge/temp/xyz-452-plan-comment.md` (61 lines). Probe output: `.relay-scratch/probe-a…o*.txt`, read-only DB copy `.relay-scratch/releases-ro.db`.

swept file: yes — artifact in full; GH-452 doc; `githooks/pre-push` (all 210 lines); `githooks/dashboard-staleness-guard.sh`; `releases.sql` (schema + all release rows); `releases_app.py` (schema, update/check/gen/project/ship, import validation 1875–1912); README.md:34; PAGES/ (grep sweep + generator); `relay-automation/xyz-vendor.sh` (stamping region); AGENTS.md rails cited below. Pre-existing defect found in the swept surface: exactly one — the `gh_release_url` column already carries legacy old-org **issue** URLs on 4 rows (S1), which the plan's false "NULL on all rows" claim papered over. (The ungated delete-only arm, pre-push:53–75, is pre-existing, commented, and by design — not a defect.)

**DoD answers:**

1. **Ground truth** (verified here, read-only):
   - (a) TRUE with a twist: `update` exposes `--gh-release-url` (releases_app.py:4843–4845: `sp = sub.add_parser("update"…)` then the flag loop); NO tag/SHA column in the releases schema (releases_app.py:490–508 — columns run …`gh_release_url`, `milestone`, QA flags; nothing tag/sha-shaped). Twist → S1.
   - (b) TRUE: zero case-insensitive matches for "tag" in githooks/pre-push. Mechanism: a new ref arrives with an all-zero remote SHA → `classify_push` returns 1 (pre-push:109–111) → falls through to the full `validate.sh` gate (pre-push:183–191). The plan's "has no changed paths" causal story is imprecise (classification aborts before any path diff) but the conclusion — tag push full-gates today — is correct.
   - (c) TRUE: `git tag --list` → exactly `bash-final-2026-07-28`, `prereset/development-2026-09-02`.
   - (d) TRUE: all four SHAs exist with commit date == the table's ship date: `136eafbc` 2026-08-18 23:45:44 "Merge pull request #24" ✓; `cd0f5bdb` 2026-08-19 23:53:18 "Merge pull request #93" ✓; `713ba6d1` 2026-08-23 23:47:01 ✓; `17b18b84` 2026-08-25 23:28:24 "marathon: phase p1 transcript saved (MARATHON-P1-TURN)" ✓ (matching the plan's own distrust of that pick). BUT the stated locator does not reproduce them → S2.
   - Header counts TRUE: `git rev-list --left-right --count origin/main...origin/development` → `0  1255`; merge-base == origin/main tip `2914411` ("its tip *is* the merge-base" ✓); ledger = 7 shipped, 1 cut, 4 draft + 1 active = "5 draft/active" ✓ — **13 rows total** (releases.sql:92–104; live-DB copy agrees), which contradicts the plan's "12 rows" → S1.
2. **Decision soundness: CONSISTENT** [Pass]. The vendor arc does not silently depend on the deferred schema change: `xyz-vendor.sh` already computes its stamp from the harness checkout via git at vendor time (`src_commit="$(git -C "$HARNESS_ROOT" rev-parse HEAD)"` + VERSION write, xyz-vendor.sh:316–317, 382–386), so tag/SHA stamping extends that git-side path with no ledger column; decision 3's deferral clause (plan:7 "only if `hq`/vendor reporting needs the raw SHA offline") names the sole case that would need the column, and vendor-time stamping forecloses it. One unflagged deviation from the issue body's wording → N4.
3. **Reachability: conclusion CORRECT, one wording error** (→ N2). Verified: 0 commits dated 2026-08-14 on origin/development, the prereset line, or the bash-final line (0/0/0); dev and prereset lines share the synthesized root `1f0a5bf1` "XYZ: initial public release" dated 2026-08-15 (prereset dates rewritten at the re-root ✓ as plan:8 claims); bash-final line spans `268e5fb3` 2026-06-14 → `06100cc4` 2026-07-28 — "different era", predates 0.1.0's target 2026-08-01 ✓. So 0.2.0/0.3.0 (shipped 2026-08-14) have no landing commit on any ref, and starting at 0.7.0 matches the body's "otherwise start from the next release" (GH-452 doc:40–41) since 0.4.0–0.6.0 never shipped.
4. **Hook carve-out: fail-closed for the enumerated cases** (lightweight, non-`v`, unknown commit, mixed-ref push all fall to the full gate; the existing delete-only arm is untouched) **but the spec has an undefined clause and its rationale overclaims** — reachability is a proxy for gatedness that documented bypasses falsify. Four fixes → S3.
5. **Execution order: correctly ordered and safe** [Pass] — renderer + carve-out (Phase A) precede backfill; operator go sits between dry-run manifest and the costly push (step 5); tags are cut before the dev→main merge so step 6's `--is-ancestor` can pass; steady state last. Missing duties: GH-243 dump/dashboard regeneration on the step-5 ledger write → S4; evidence record + `wave_reconcile` → S5; PAGES/ scope misstated → N3; step-6 promotion expectations → N5.
6. **Acceptance criteria:** two cannot fail against the property they name → S6 ("on GitHub" checked with a local-only command) and N1 ("non-empty notes"). The rest are real: `releases check` exists (releases_app.py:4063) and can fail; `merge-base --is-ancestor` can fail; step 2's three named expects are genuine probes; the README row exists to flip (README.md:34).

**Findings:**

- [Should] S1 — False ledger claim under decision 3: "**No tag-SHA column exists**; `gh_release_url` is NULL on all 12 rows" (plan:31). Ground truth: **13** rows, and **4 are non-NULL** — 0.1.0, 0.4.0, 0.5.0, 0.6.0 carry legacy old-org *issue* URLs from the RELEASES.md import (releases.sql:92,95–97; e.g. 0.1.0 → `https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/308`; import path releases_app.py:1892–1902; read-only DB copy agrees). All 0.7.x rows are NULL, so Phase B is unaffected — but the column already has mixed semantics and renderers present it as "GitHub release" (releases_app.py:2792). Fix: correct the count, and add to decision 3 one line acknowledging the 4 legacy values and their disposition (grandfathered-as-imported vs cleaned before reuse).
- [Should] S2 — Candidate locator not reproducible as written: `git rev-list -1 --before <ship-date> origin/development` (plan:25). A bare date is parsed by git's approxidate at the **current time of day**: run at ~23:14 on 2026-09-05 it returns `adee7466`/`bea2e548`/`77b2abe1`/`0520cc39` — none of the four tabled SHAs (probe-f). Fix (verified deterministic, two identical runs, probe-n): `git rev-list -1 --before "<ship-date> 23:59:59 -0700" origin/development` reproduces exactly `136eafbc`/`cd0f5bdb`/`713ba6d1`/`17b18b84`. Keep the manifest-confirmation requirement as-is.
- [Should] S3 — Carve-out spec (step 2, plan:39) under-defined and overclaiming fail-closed: (a) "whose target commits are already reachable from **the pushed branch**" is undefined for a tag-only push (no branch is pushed) — pin it to: the peeled commit is an ancestor of **origin/development or origin/main** (remote-tracking refs), NOT any side branch, else a commit that landed on a side branch via the docs/tier-2 route or a bypass inherits the suite skip (the DoD's side-branch vector); (b) reachable ≠ gated: `--no-verify` / `XYZ_SKIP_PREPUSH=1` are documented bypasses (pre-push:33–35) and GitHub-side merges never run the local gate, so "(the commits were gated when they landed)" must be restated as an accepted residual risk; (c) add the forced tag-update/re-point arm: non-zero remote SHA on `refs/tags/v*` → full-gate or refuse — "never re-point a published tag" is policy, the hook needs the enforcement arm; (d) step 2's expects omit the unknown-commit probe — add "an annotated `v*` tag on a commit NOT reachable from origin/development still full-gates" (today the most bypass-relevant arm has no named check).
- [Should] S4 — Step 5 write-back trips the GH-243 guard: `releases update --gh-release-url` mutates releases.db and the canonical releases.sql dump; `.pdda-mode:11` declares `ROADMAP_SOURCE=releases`, so the pre-push dashboard-staleness-guard (pre-push:87–93; guard header: "A ledger write (releases.sql / releases.db) that ships without a dashboard regeneration … refused") REFUSES the next push unless ROADMAP-DASHBOARD.md regeneration rides it (renderer `utils/roadmap-dashboard.sh`, cited at releases_app.py:3263). Fix: step 5 commits the regenerated dump and regenerates the dashboard in the same push — otherwise the plan's own step 6 push fails closed mid-execution.
- [Should] S5 — Evidence + post-merge duties missing: step 3's "expect full local gate green" is a gate claim cited in a PR → its `provenance.jsonl`/evidence record must be committed in the same PR (AGENTS.md:96 "An uncommitted `provenance.jsonl` is not proof (GH-430)"; ci-local.sh is the qualifying run that writes the record, AGENTS.md:179–181). After the Phase A PR merges into development: `python3 utils/py/wave_reconcile.py --pr <N>` (AGENTS.md:52 — "nothing triggers it for you"). Fix: name both in step 3's expects / a post-merge line.
- [Should] S6 — Decorative acceptance checks: "`git tag --list 'v*'` = `v0.7.0`–`v0.7.3` **on GitHub**" (plan:45) and "`git tag --list 'v*'` is non-empty *on GitHub*" (plan:60) read the **local** repo — they pass even if the push or Release creation failed, so they cannot fail against the named property (AGENTS.md:100 "A check that cannot fail is not a check"). Fix: `git ls-remote --tags origin 'refs/tags/v*'` plus `gh release list` / `gh release view <tag>` for the Release objects and URLs; pin step 6's is-ancestor to the pushed ref (`origin/main`).
- [Nit] N1 — (i) "full ~13-minute suite" (plan:1,30): the hook's own header documents ~4 min parallel / ~16 min sequential (pre-push:9–10) and AGENTS.md:176 says ~4–6 min — correct the figure or cite a measurement. (ii) "prints non-empty notes" (plan:38) passes on a stub — assert exit 0 AND content (version, codename, ≥1 manifest item).
- [Nit] N2 — "the oldest real commits **on any ref** are dated 2026-08-15" (plan:8) is false as written: the `bash-final-2026-07-28` ref reaches `268e5fb3` dated 2026-06-14. The conclusion stands (no 2026-08-14 commit on any of the three lines — verified 0/0/0); qualify the clause to "on the development/prereset lines".
- [Nit] N3 — "`PAGES/` status copy at the very end" (plan:58): no apology copy exists in PAGES/ — the apology lives only at README.md:34; no PAGES/*.html mentions release tags/archival tags (grep); PAGES/roadmap.html:115 merely lists #452 and is generated from the roadmap ledger (`utils/py/site_build.py:7` — `roadmap list --json` seam). Fix: restate as "regenerate the site via site_build.py when #452's roadmap row moves"; step 8's "if it quotes it" resolves to NO today.
- [Nit] N4 — Decision 3 supersedes the body's acceptance "Ledger row carries the tag" (GH-452 doc:47; goal :19–20; Key Concepts :38 "Tag SHA is written back to the ledger row") without flagging the deviation. Fix: one line in decision 3 noting the supersession (tag is derivable from version per decision 1; the URL is the recorded artifact; amend the body at execution).
- [Nit] N5 — Step 6 is a promotion push to `main`: it full-gates locally and triggers the hosted macOS boundary (AGENTS.md:167; a qualifying promotion needs a hosted macOS run for that exact commit, AGENTS.md:381). Set that expectation in step 6. Execution caution: in this worktree family the **local** `main` diverges from origin/main (local counts 638/1221 vs origin 0/1255) — step 6's checks must target origin refs, not a stale local `main`.
- [Pass] P1 — Q1(a)–(d) and the header counts verified as answered above (citations inline: releases_app.py:4843–4845, 490–508; pre-push:109–111,183–191; `git tag --list` output; the four `git log -1` date/subject matches; `0 1255` + merge-base == origin/main tip).
- [Pass] P2 — The #39 render path exists as the plan describes: `gen` (releases_app.py:4925), `project` (:5003), `show` (:4915); the `ship` verb with `--evidence` exists for step 7's wiring.
- [Pass] P3 — Table facts vs the canonical dump: every codename/status/ship-date matches releases.sql:92–104 exactly (incl. 0.7.4 `cut` → never tag; 0.1.0 no shipped date; 0.2.0/0.3.0 shipped 2026-08-14).

**Verdict: Changes requested** (S1–S6; N1–N5 optional but cheap). All fixes are plan-text-local; none changes the plan's shape.

Handing off to **Producer (claude-a)** — go to the Producer window and say "take your turn": log a disposition (Implemented/Modified/Declined+why) for every S/N finding above, edit `.relay-artifacts` source `temp/xyz-452-plan-comment.md` accordingly, bump ROUND to 2, flip NEXT back to Reviewer.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
