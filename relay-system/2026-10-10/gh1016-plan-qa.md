# RELAY · GH1016 plan QA: repo slug identity
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-10.
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
6. **Commit only the relay file** (`relay(gh1016-plan-qa-repo-slug-identity): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1016-REPO-SLUG-IDENTITY.md` (the plan; read it in full), checked against the source it cites: `utils/py/releases_app.py` (`cmd_init` ~2171-2205, `_github_slug_from_origin` ~2082, `tracking_token_to_url` ~2093, `_origin_repo_identity` ~5385, `resolve_roadmap_identity` ~5397, its callers ~3944/~4067/~5112/~5493, `load_dump` ~6059), `utils/py/wave_reconcile.py` `update_roadmap_entry` ~1467-1492, `utils/py/express.py` ~665-677, `utils/py/work_connectors/__init__.py` ~144-164, `relay-automation/xyz-releases-onboard.sh` ~95-116, `utils/pdda/pdda-install.sh` ~772-775, and the recorded manual check `TESTS-RESULTS/2026-10-10+GH-1016/identity_check.py` and `TESTS-RESULTS/2026-10-10+GH-1016/red-control-9a923f3c.jsonl`. Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1016
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-10
- Definition of Done: the plan is approved for implementation when (a) every recon claim matches the cited source at base `9a923f3c`, (b) the chosen fix makes an AEGIS-shaped ledger (bare `aegis-sleuth-slack-bot`, origin `HiQS-Labs/AEGIS-Sleuth-Slackbot`) resolve its own rows `identity_valid True` while foreign-repo rows stay invalid, (c) it extends the existing resolver and `cmd_init` writer without a second writer, new verb, schema change, or new test suite (AGENTS.md *No new tests*, GH-831), (d) acceptance checks are falsifiable with a red control, and (e) the rating 70/60/50/70 and its rationale are grounded.

## Operational envelope

Local, single-operator CLI ledger (`releases.db` + `releases.sql`), one `repos` row per ledger in practice, vendored into a few consumer repos. Grade against the stated requirements and commensurate complexity; do not demand enterprise multi-tenant threat models, new suites, new gate machinery, or a migration framework. Per AGENTS.md GH-831, a request for a new test file is itself out of scope; verification is existing suites plus the recorded manual check under `TESTS-RESULTS/2026-10-10+GH-1016/`.

## Questions

1. Are the recon claims grounded? In particular: is `cmd_init` the only place a slug value originates (`load_dump` only copies), are all ownership decisions routed through `resolve_roadmap_identity`, and is there really no existing verb that rewrites `repos.slug`?
2. Is the tolerant bare match safe? The plan's normalisation is `casefold()` with `-` and `_` removed, applied only when the slug has no `/` and `len(repo_rows) == 1`, with validity still requiring `url_repo == origin_repo` byte-exact. Can you construct a concrete foreign-repo row (paste it) that becomes valid under this rule? Is the one-row guard correct given every caller builds `repo_rows` from all `repos` rows?
3. Is `_github_slug_from_origin` (github-only) the right source for the new `cmd_init` default instead of `_origin_repo_identity` (any host; parses local-path origins into a bogus owner/name)? Does writing `owner/name` to `repos.slug` and `settings.repo_slug` for NEW ledgers break any reader you can find (dump, `tracking_token_to_url`, `releases_cycle.py`, tests under `test/` that call `init` without `--slug` in a fixture that has a github origin)?
4. Is the onboard-script change (move the existing `ORIGIN_URL`/`GH_BASE` parse above Step 1 and default the slug from it) necessary and minimal, or should it be dropped as scope creep?
5. Is choosing the resolver-side match over a receipted repair verb correct, given `repos.slug` is part of `business_digest` and `settings set` refuses `repo_slug`? Is the stated non-goal (legacy folder names that differ by more than case/separators) acceptable?
6. Are the acceptance checks falsifiable? The manual check scores 7/11 (exit 1) on the `9a923f3c` tree; do its cases actually exercise the reported failure path (`wave_reconcile.update_roadmap_entry` logging "No qualified owned roadmap row")? Is anything missing from the acceptance map?
7. Is the rating `rated 70/60/50/70` (pri/sev/appeal/effort) and its recurrence statement grounded in the evidence cited?

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) with `file:line` citations; any behaviour-change request carries `Observed input:` / `Affected scope:` / `Falsifier:`. End with `VERDICT: PASS|FAIL` and a `Basis:` line, and set `STATUS: Approved` only on PASS. Review only: do not run `validate.sh`, `test/*.sh`, pytest or fixtures in the relay worktree; read-only probes under `$TMPDIR` are fine. Only edit this relay file.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes

Reviewed the entire plan, including its existing claims and non-goals, and the cited resolver/writer/caller seams. Review tier: Verify with direct-source fallback. The exact relay worktree is not indexed; the nearest graph is `XYZ-forge`, generation `2026-09-01T15:54:30Z`, at another root. Symbol search is stale (e.g. `cmd_init` at 1792 rather than 2171); coverage reports changed/missing metadata. Consequently graph results are orientation only; local source reads and literal searches are the evidence. No git commands, executable fixtures, suites, or gates were run.

- [Should] **The proposed onboard default inherits a concrete parser gap.** Plan `PROJECT/2-WORKING/GH-1016-REPO-SLUG-IDENTITY.md:154` reuses `GH_BASE`, but the existing regex at `relay-automation/xyz-releases-onboard.sh:108` excludes dots from the repository name. A legitimate dotted repo therefore still gets a basename slug despite the stated new-ledger requirement. This is a pre-existing defect in the source seam the plan changes. Cheapest fix: permit dotted repository names in that existing parse while stripping only the terminal `.git`, and include a recorded manual acceptance for it; no second parser or new suite.
  Observed input: `ORIGIN_URL=https://github.com/test-org/foo.js.git`, no explicit `SLUG`, target folder `different-folder`; the current parse yields empty `GH_BASE`, so the planned fallback yields `different-folder` rather than `test-org/foo.js`.
  Affected scope: default onboarding slug selection for GitHub repository names containing dots; explicit slug precedence and non-GitHub fallback remain as specified.
  Falsifier: the same input must produce `test-org/foo.js`; the existing `https://github.com/test-org/happy-repo.git` input must still produce `test-org/happy-repo`, and a local-path origin must keep the basename.
  Probe: `bash` heredoc containing `url='https://github.com/test-org/foo.js.git'; if [[ "$url" =~ github\.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then printf 'matched=%s/%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"; else printf 'NO_MATCH: %s\n' "$url"; fi` → exit 0, decisive output `NO_MATCH: https://github.com/test-org/foo.js.git`. This is a builtin regex probe, not an executable fixture.

- [Should] **Give the measured evidence its required provenance and bound the rating claims.** The plan cites an executed red control at `:105-111` and prior search results at `:61-64`/`:122-125`, but the seeded evidence directory contains only `identity_check.py` and `red-control-9a923f3c.jsonl`. Probe `rg --files TESTS-RESULTS/2026-10-10+GH-1016` → exit 0, exactly those two files; `cat TESTS-RESULTS/2026-10-10+GH-1016/provenance.jsonl` → exit 1, `No such file or directory`. AGENTS.md:100-102 requires committed provenance for cited runs. Plan step 4 promises it later, which does not ground the present measured claim. Add the red-control receipt now (command, source SHA, exit status, output path), plus the retained AEGIS observations/search commands and decisive results supporting priority and recurrence; alternatively label unretained claims as author-reported/unverified. `releases.sql:842` and `:3306` support the stored 70/60/50/70 rating, and its sum is 250, but do not prove the historical search or the downstream exit-6 assertion. No runtime behavior change requested.

- [Should] **Add a falsifiable acceptance for step 3.** Plan `:158` names only gh197 staying green; it also explicitly says that suite does not pin the slug (`:117-118`). The current happy-path assertions at `test/gh197-vendor-tier-split.sh:131-151` check files, mapped URLs, consistency and no automatic commit, without asserting either stored slug. `identity_check.py:109-120` invokes direct `init`, never onboard. Omitting the entire onboard edit could therefore satisfy the stated checks. Add a recorded manual check, run only in a disposable full clone, that reads `repos.slug` and `settings.repo_slug` after onboarding the existing `onboard_happy` / `test-org/happy-repo` shape; require both to equal `test-org/happy-repo` and witness the old basename as the red control. Include explicit-slug and no-origin fallback checks. No new test file or gate machinery requested; this is a proof change, not a new runtime requirement.

- [Pass] **The core resolver fix is bounded and the one-row guard receives complete repo maps.** `releases_app.py:5397-5406` independently compares URL repo and number; the planned branch at plan `:141-147` only binds a bare slug to origin and retains those comparisons. Concrete foreign rows `repo_id=1, gh_number=300, issue_url=https://github.com/Other-Org/AEGIS-Sleuth-Slackbot/issues/300` and `repo_id=1, gh_number=301, issue_url=https://github.com/HiQS-Labs/XYZ-forge/issues/301` cannot become valid through that branch when origin is `HiQS-Labs/AEGIS-Sleuth-Slackbot`. All discovered production call sites build unfiltered maps: `releases_app.py:3944`, `:4067`, `:5112`, `:5493`; `express.py:673`; `work_connectors/__init__.py:149`; `wave_reconcile.py:1485`. Keep the exact-match branch outside the one-row restriction, as specified. This proof concerns newly accepted bare-slug rows; existing qualified `/` slugs retain existing semantics.

- [Pass] **Writer/reader choice and scope are appropriate.** `cmd_init` at `releases_app.py:2176-2196` supplies the same slug to both fields; `load_dump:6056-6064` copies stored values. The local literal search found no `UPDATE repos` in this module; `settings set:3821` excludes identity edits. `tracking_token_to_url:2102-2113` already accepts owner/name, `releases_cycle.py:207` displays it, and `business_digest:1303-1305` hashes the dump that includes slug at `:1128`. Resolver repair avoids changing stored digest state. Onboard passes explicit basename into an origin-less staging repo (`xyz-releases-onboard.sh:96-101`), so step 3 is necessary, subject to the findings above. Retain GitHub-origin helper reuse in init and the stated arbitrary-folder-name non-goal (`plan:195-197`); rollback compatibility follows from the existing `/` branch at `releases_app.py:5400`.

- [Pass] **The manual check reaches the reported skip path, with limits.** `identity_check.py:68-72` calls real `wave.update_roadmap_entry(..., dry_run=True)` and captures its skip message; `wave_reconcile.py:1481-1493` contains the corresponding qualification and refusal. Recorded output includes `"wave-reconcile-moves-own-row"` with `"logged_skip": true, "moved": false`. It is a falsifiable qualification/dry-run check, not proof of a persisted ledger move. Execution remains [Unverified — needs clone run] in this turn. The JSON contains seven passing controls and four failures; plan `:110` says six controls, a [Nit] counting typo. Call case 4 a qualified dry-run move, and retain the full-clone runtime gate and committed final receipts in step 4/5.

VERDICT: FAIL
Basis: The resolver and init strategy fit the task and add no second writer, verb, schema, or suite. Approval needs a concrete dotted-name onboard correction, a non-vacuous onboard acceptance, and provenance/qualification for the measured evidence and rating history. No additional pre-existing defects were found in the plan beyond the findings recorded above; this is plan QA, not final implementation sign-off.

Handing off to Producer (claude-a) — disposition these findings, revise the plan/evidence, then open round 2; go to the other window and say 'take your turn'.

### Producer · Round 1 · claude-a

Dispositions (also recorded in the plan's "Plan QA dispositions"):
- [Should] onboard dotted names: **Modified.** Instead of widening the bash regex, step 3 now computes `ORIGIN_SLUG` once via the existing `releases_app._github_slug_from_origin` (`releases_app.py:2082-2090`, regex `[\w.\-]+/[\w.\-]+?` then optional `.git`) imported from the already-resolved `$RELEASES_APP`, and derives both `EFFECTIVE_SLUG` and `GH_BASE` from it; the script's own regex at `xyz-releases-onboard.sh:106-111` is removed. One parser for init and onboard; `foo.js` parses. Probe: `python3 -B -c "...from releases_app import _github_slug_from_origin..."` on this clone → `'HiQS-Labs/XYZ-forge'`, exit 0, no import side effects.
- [Should] provenance: **Implemented.** `TESTS-RESULTS/2026-10-10+GH-1016/provenance.jsonl` now records the red-control command, source SHA, exit 1, 9/15, failed cases and sha256 of check + output, the AEGIS read-only observations, and both recurrence searches (`[1016]`; `[1016,673]`, #673 being the identity feature, not an incident). Exit-6 / missing-row claims are labelled author-reported.
- [Should] onboard acceptance: **Implemented.** Four `onboard-*` cases added to the existing manual check (`identity_check.py`, not a suite/registry entry): default (`different-folder` + `test-org/happy-repo` → `test-org/happy-repo`), dotted (`test-org/foo.js`), explicit `--slug chosen`, no-origin basename. Each reads `repos.slug` and `settings.repo_slug`. On the `9a923f3c` tree the default and dotted cases fail (red), explicit/no-origin pass — see `red-control-9a923f3c.jsonl`. The check writes only temp dirs; the final receipt is re-run in the disposable gate clone.
- [Nit] control count: **Implemented** (nine controls of 15; wave case labelled a qualified dry-run).

Round 2 question for the Reviewer: do the revised plan step 3, acceptance map, and evidence resolve the three Should findings without adding a parser, writer, verb, schema change or suite?

### Reviewer · Round 2 · codex

swept file: yes

Reviewed the whole revised plan, the complete manual-check artifact and recorded output, and the cited writer/resolver/caller seams. SWE rubric applied. Codebase Memory tier: Verify, with direct-source fallback. The nearest graph is `XYZ-forge` at another root, generation `2026-09-01T15:54:30Z`; its search still places `cmd_init` at 1792. Coverage for the nine evidence paths reports changed, missing or untracked metadata, so local source is the evidence. No git commands, suites, gates or executable fixtures were run. No additional pre-existing defects were found in the plan beyond the earlier findings and the optional wording nit below.

- [Pass] **The shared parser resolves the dotted-name finding without another parser or writer.** Plan `PROJECT/2-WORKING/GH-1016-REPO-SLUG-IDENTITY.md:163-174` calls the already-resolved app's helper once, preserves explicit slug precedence and the explicit owner/name URL fallback, and removes the Bash regex. `utils/py/releases_app.py:2082-2090` already supports dots. Read-only probe: `python3 -B` heredoc using `ast.parse(Path('utils/py/releases_app.py').read_text())`, selecting the string constant containing `github\.com` from `_github_slug_from_origin`, then `re.search(pattern, url)` → exit 0; decisive output: `https://github.com/test-org/foo.js.git => test-org/foo.js`, `https://github.com/test-org/happy-repo.git => test-org/happy-repo`, `git@github.com:test-org/foo.js.git => test-org/foo.js`, `../GH Repos/XYZ-forge => None`. This measures the existing regex without importing or executing fixtures. Keep this proposal.

- [Pass] **The onboard acceptance now fails if the edit is omitted.** `TESTS-RESULTS/2026-10-10+GH-1016/identity_check.py:128-150` invokes the onboard entry point and compares both `repos.slug` and `settings.repo_slug` for default, dotted, explicit and absent-origin cases. The recorded red output at `red-control-9a923f3c.jsonl:12-16` shows default/dotted failing and explicit/no-origin passing. The acceptance map at plan `:249-254` covers that seam, and steps 4/5 require a fix-tree run and disposable full-clone gate. Keep these checks. Runtime execution in this reviewer turn remains **[Unverified — needs clone run]**; approval concerns the plan.

- [Pass] **The retained evidence closes the provenance finding, with honest runtime limits.** `TESTS-RESULTS/2026-10-10+GH-1016/provenance.jsonl:1-5` records the red-control command, full source SHA, exit 1, hashes, AEGIS observation, recurrence results and author-reported symptoms. Read-only probe: `python3 -B` heredoc reading the first receipt with `json.loads`, computing `hashlib.sha256((base/filename).read_bytes()).hexdigest()` for both named artifacts, and parsing/counting nonempty case rows → exit 0; decisive output: `identity_check.py hash_matches= True 0b3a34d2b35ab0b0b4144f1ec23d5699e7041d265b274d2b4ad62f9c4f2d2b1f`, `red-control-9a923f3c.jsonl hash_matches= True d738f4cb7eb6c5880997ef9a544aff2bad5f36770f41b7b814b8a079303c6bf2`, `nonempty_cases= 15 passed= 9`; the six failed case names agree with the receipt. `releases.sql:842` stores 70/60/50/70 (sum 250). The single observed AEGIS incident and unknown trend support the bounded rationale; these retained author observations/search results were not independently re-run here. Keep the distinction between recorded evidence and execution-time verification.

- [Pass] **The original core decision still satisfies the definition of done.** Plan `:149-160` retains exact matching, restricts the new normalized bare match to one repo row, and leaves URL-owner/name and issue-number equality intact (`releases_app.py:5397-5406`). The concrete foreign rows in `identity_check.py:80-85` cannot become valid through the proposed branch. All cited callers build unfiltered repo maps (`releases_app.py:3944/:4067/:5112/:5493`, `express.py:673`, `work_connectors/__init__.py:149`, `wave_reconcile.py:1485`). `cmd_init:2176-2196` remains the originating writer; `load_dump:6056-6064` copies values, and settings rejects identity edits (`:3821-3828`). Existing owner/name support (`:2102-2113/:5400`) makes rollback compatible; resolver repair leaves digest state untouched (`:1128/:1303-1305`). Keep the no-migration, no-new-verb, no-new-suite scope and arbitrary-folder-name non-goal.

- [Nit] **Name the execution debugging protocol.** The plan's existing log/reproduction path and full-clone proof are sufficient for this small fix, but SWE's Diagnosable rubric asks it to name debug-mantra explicitly. Cheapest follow-up: add “If execution fails, apply debug-mantra before changing the fix” to the execution instructions. This is optional plan wording, not a new runtime requirement or an approval blocker.

VERDICT: PASS
Basis: All three round-1 Should findings are resolved in the revised plan and retained evidence. The fix extends existing resolver/init behavior, shares the existing origin parser with onboard, preserves foreign-row refusal and stored-state compatibility, and defines falsifiable red/green acceptance without new suites or gate machinery. This is approval for implementation; the final green manual receipt and full-clone gate remain outstanding.

Relay closed (Approved), no further review turn needed. Token handed back to Producer (claude-a) with done for implementation under the approved plan.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
