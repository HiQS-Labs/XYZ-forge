# RELAY · GH-1108 delivery1 QA — Claude Code Opus 5.5 high
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 3 / 3

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
6. **Commit only the relay file** (`relay(gh1108-opus55-high): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: Complete delivery1 diff from b26c9edb73f61587a71287f68cb4338409188042 to 7d4ed1c5; whole touched runtime source `utils/py/jog_run.py`, `utils/py/releases_app.py`, `utils/py/harness_paths.py`, `utils/py/gate_receipt.py`, merge-cleanup scripts `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` and `skills/2-daily/merge-cleanup/scripts/ledger_merge.py`; material existing callers; canonical `PROJECT/2-WORKING/GH-1108-JOG-LAND-RECEIPTS.md`; retained `TESTS-RESULTS/2026-10-17+GH-1108` evidence plus historical portable bundles.
- Reviewer: claude-opus-reviewer · Producer: codex-producer
- Definition of Done: Independent final QA using Claude Code Opus 5.5 high. Local operator CLI scope, commensurate complexity, surgical DRY. User requires two PRs: delivery1 one-writer guard/disposable execution/committed receipts/mechanical landing proof/mapped merge-cleanup hook; delivery2 exclusively direct transition publication and non-FF fresh-intent retry. Delivery1 manual primary commit/push checkpoint and common real auto-merge refusal are intentional interim policy, not missing delivery2. No merge authorized. No new suites/gates. Only this relay is writable; no production edits, Git commands, builders, pytest, validate.sh or test/*.sh in review worktree. Narrow read-only scratch probes allowed. Full gate is running separately; no result claimed. Historical re-land currently proved with disposable primary plus live GH data; actual machine primary recovery pending.

### Questions
1. Do all Jog write paths refuse outside pinned primary before DB writes, while real execution uses separate full clone and existing #1104/#1099 root helpers without writing lane releases files?
2. Are green result/gate bytes preserved and committed as portable evidence, with cache-independent land identity/hash/gate/reconcile checks and safe receipt publication/resume?
3. Does the approval tail proof reject changed/reverted source commits, allow six-path-only commits, and mechanically prove upstream merges using reachable second parent plus conflict-free identical stripped trees (ledger exclusions recorded)?
4. Does merge-cleanup call land only for mapped rows after hosted reconcile and reuse its final post-merge publication; does existing plain/old/vendored consumer behavior survive? Both real executor auto-merge paths now refuse interim unpublished state before lease, simulation/dry-run stay compatible.
5. Does retained red/green/manual and focused 223/34/180/8 evidence support claims within stated limits? Any concrete blocker/should, unnecessary layers or unexamined touched-file defects? Cite exact file:line, observed input, affected scope and falsifier. Do not ask for new suites.

Terminal token protocol: claim as instructed. On Approved, call tick done RELAY-gh1108-opus55-high --agent claude-opus-reviewer (with this checkout's TICK_REPO_ROOT), not release. On findings release to codex-producer. Never run Git: shim commits relay only.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 (claude-opus-reviewer)

swept file: yes
Scope: I read in full `utils/py/harness_paths.py`, `utils/py/gate_receipt.py` and `skills/2-daily/merge-cleanup/scripts/ledger_merge.py`. I read `utils/py/jog_run.py` 183–302, 379–1239, 1361–1468 and 1765–2002. In `merge_cleanup.py` I read the Jog hook, post-merge, `--reconcile-pr` and primary-pin sections (421–445, 600–760, 1270–1295, 1410–1505). In `releases_app.py` I read only the Jog entries (4490–5016) and the `perform_write` `jog-*` guard. Two read-only sub-reviews also covered `releases_app` and merge-cleanup, and I re-read every cited span myself. Probes were read-only: `sqlite3 mode=ro` on `releases.db`, rg/sed, and log tails. No git, tests or fixtures were run. The pre-existing defects I found are listed under Nits; none rises to Blocker.

VERDICT: FAIL
Basis: Q1–Q3 and Q5 hold with citations. Q4 does not fully hold, for three reasons. The `--reconcile-pr` recovery mode now lands without the shared final publication step. The new mapping stops merge-cleanup after merge for PRs that have nothing to do with Jog. The old-harness refusal checks the wrong copy of `harness_paths`. Each one contradicts a Q4 claim in the Definition of Done. All three are Should-level with narrow fixes. No Blocker was observed.

**[Should] S1: `--reconcile-pr` lands Jog rows and exits 0, but leaves the landing writes unpublished.**
- Path: `merge_cleanup.py:1499` runs `return 0 if run_post_merge_reconcile(...) else 2`, and `run_post_merge_reconcile` now ends with `return ok and run_jog_post_merge_land(pr_num, repo_path)` (`merge_cleanup.py:724`). `jog_land` then writes queue completion and `<bundle>/landing.json` (`jog_run.py:1216`, `jog_run.py:1224-1226`).
- Only the main loop calls `commit_and_push_phase5_writes` (`merge_cleanup.py:1291`). The DoD says merge-cleanup "reuse[s] its final post-merge publication", which is true only in the main loop.
- Observed input: `merge_cleanup.py --primary P --reconcile-pr N --execute`, where N is a merged PR mapped to a Jog row and its hosted run is green. By code trace, this exits 0 with `releases.db`/`releases.sql` and `landing.json` left dirty in the primary. I have not run it [Unverified — needs clone run].
- Affected scope: only `--reconcile-pr` runs where `run_jog_post_merge_land` actually lands at least one issue.
- Fix: after a successful reconcile in that branch, call the existing `commit_and_push_phase5_writes(args.reconcile_pr, primary_repo, args.integration_branch)`. Alternatively, refuse mapped landing in `--reconcile-pr` mode. Either way, do not add a new publisher.
- Falsifier: the existing one-writer fixture, run with `--reconcile-pr 4242 --execute`. If it already ends with the primary clean and equal to `origin/development`, this finding is wrong.

**[Should] S2: the mapping is too wide, so non-Jog PRs stop merge-cleanup after they merge.**
- Path: `merge_cleanup.py:630` reads `SELECT gh_number FROM jog_queue WHERE status!='archived'`. Lines 643–644 then map by the title/body `Closes #N` match or the branch token `gh[-_]?N`.
- Any mapped issue goes to `jog land`, and that refuses when no bundle in HEAD names this PR (`jog_run.py:1054-1055`, then `:1085`). The refusal returns False at `:655`, which hard-stops the run at `:1285` after the merge has already happened.
- Observed input: `releases.db` in this checkout (read-only) contains `(904,'dropped')`, `(275,'completed')`, `(533,'failed')` and `(1075,'pending')`. A plain PR whose body says "Fixes #904" (an issue the operator removed from Jog), or a later follow-up "Closes #275", maps and then refuses.
- The only queue escape is `jog clear` (`releases_app.py:4810-4815`). It also archives every `parked` row that is awaiting landing, so the workaround does collateral damage.
- Affected scope: PRs whose linked issue or branch token matches a non-archived Jog row, but which carry no committed Jog bundle for that PR.
- Fix: map positively only when merged HEAD contains a committed `TESTS-RESULTS/*+GH-N/jog/*/receipt.json` whose `pr_number == PR` or whose `head_branch == headRefName`. Reuse `_committed_jog_receipt`'s path regex rather than adding a second predicate. Every other PR stays unchanged, as the plan's "unrelated PRs remain unchanged" requires.
- Falsifier: a fixture where a `dropped` row's issue is closed by a plain PR. Expected after the fix: merge-cleanup publishes without invoking land. The current code refuses.

**[Should] S3: the old-harness refusal probes merge-cleanup's own copy of `harness_paths`, not the copy the land subprocess will run.**
- Path: `ledger_merge.py:479-480` resolves `bundled = Path(__file__).resolve().parents[4] / "utils" / "py" / "harness_paths.py"` and prefers it over `tool_path(root, …)`. When the skill runs from a harness checkout (a symlinked user skill resolves to it), the check at `merge_cleanup.py:646` (`hasattr(paths_policy, "require_primary")`) inspects the upgraded harness.
- Meanwhile `merge_cleanup.py:650` runs `tool_path(repo_path, "releases_app.py")`, which resolves to the consumer's own `utils/py` or `.xyz/utils/py` first (`ledger_merge.py:266-271`).
- Observed input: a vendored consumer whose `.xyz/utils/py/releases_app.py` predates this change, that has a Jog row, and whose PR branch contains `gh-N`. merge-cleanup then invokes the old `jog land` instead of refusing "before writes".
- The retained control (`compat-and-root-manual.log.txt`, "deployed skill with older-harness") covers only the deployed-copy layout, where `parents[4]` is not a harness.
- Affected scope: merge-cleanup run from a harness checkout against a consumer whose vendored PRS predates delivery 1.
- Fix: for the capability check, load the `harness_paths.py` that sits beside the resolved `releases_app.py`, using `tool_path(repo_path, "harness_paths.py")`. Keep B1's own policy lookup unchanged.
- Falsifier: the same compat fixture, but invoked through a harness-resident script path. It should print "Mapped Jog landing requires the updated…" and leave no ledger write.

**[Nit]**
- `jog_run.py:630-631`: the comment says "exporting it keeps marathon-drive from contending", but the next line pops `RELAY_DRIVER_LOCKED`. Lines 639–642 contain a garbled sentence ("so the supervisor's to revert."). Both are comment fixes only.
- `jog_run.py:655-656`: on a clone ledger change the function returns `"failed"` without `jog_save_state`, so the record stays `dispatched`. A later `jog resume` is still refused safely by `_execution_root`'s ledger-diff check (`jog_run.py:529-533`). The fix is to set `record["status"]` and save before returning.
- `harness_paths.py:167`: `git config --get` honours repo-local and env-injected config, so a clone can deliberately pin itself as primary. Multiple global values resolve to the last one, and the error text says `--global`. This needs a deliberate act, which is not the accidental-writer threat. Optional fix: `--global --get-all`, requiring exactly one value.
- `harness_paths.py:179` (path case, compared with realpath) and `:146` (a trailing `/` on the origin URL) both fail closed. `:181` gives a raw `CalledProcessError` on detached HEAD.
- Several non-`ContractError` failures surface as tracebacks without writing anything: `releases_app.py:4992` catches only `ContractError`, so `primary_config_key` on a target with no origin traces back (`jog_run.py:909`, `:830`). `merge_cleanup.py:642` calls `json.loads` unguarded. The land subprocess at `:650` has no timeout.
- `merge_cleanup.py:635-637`: when the slug cannot be resolved (for example an ssh host alias), `--repo` is omitted and ambient `GH_REPO` applies. Land's branch, merge-reachability and hosted checks mostly fail closed, but mapping can silently miss.
- Pre-existing:
  - `jog_run.py:1887-1890`: `_ensure_jog_schema` runs DDL outside `perform_write`. This only matters for DBs from before migration 006.
  - `releases_app.py:4727-4745`: `jog retry` resets `completed` rows without `--force`.
  - `releases_app.py:4928-4932`: an EPERM from `os.kill(pid,0)` is read as a dead lease.

**[Pass]**
- Q1:
  - Every mutating Jog entry runs its guard before `connect()`, `_ensure_jog_schema` or `perform_write`: add, bump, drop, retry, skip and clear (`releases_app.py:4501-4503`, `4632-4634`, `4669-4671`, `4713-4715`, `4755-4757`, `4797-4799`).
  - Lease, status and orphan writers are also guarded (`:4849`, `:4878`, `:4915`), and `perform_write` guards every `jog-*` op (`:1670-1671`).
  - Run, resume, land and promote are guarded in `jog_run.py` (`:1848`, `:720`, `:1144`, `:1363`).
  - Dry-run opens read-only (`jog_run.py:1825` uses `?mode=ro`).
  - The target must be a separate full clone with the same origin and no ledger delta (`jog_run.py:524-533`). Clone ledger bytes are compared before and after (`:554`, `:655`).
  - The #1104 argv/env helpers are reused (`:483-517`), and the lock bypass is not exported (`:632` `env.pop("RELAY_DRIVER_LOCKED", None)`). Clone promotion skips the repoint (`:1443-1445`).
- Q2:
  - Publication writes the original result bytes, the gate bytes, digest-bound provenance and a manifest. It refuses to overwrite differing evidence (`jog_run.py:1017-1020`) and refuses unrelated staged paths (`:1033-1035`). Resume re-pushes without another builder (`:739-745`, and `one-writer-manual.log.txt` "PASS injected receipt push failure resumes publication without another builder").
  - Landing reads only `HEAD:` blobs, with sha256, provenance and gate checks (`:1043-1082`), and never uses `.tick`.
- Q3: `_landing_tail_proof` (`jog_run.py:1099-1134`) works as follows:
  - Ancestor check first.
  - Single-parent tail commits may touch only `LEDGER_REPAIR_PATHS` (the six paths, `harness_paths.py:152-153`, shared with `ledger_merge.py:510`). One receipt-publication commit is allowed if it is exactly-added and exactly-bundle.
  - For two-parent commits, the second parent must be reachable from the freshly fetched `origin/<base>` (`:1117`, fetch at `:1171`). Both stripped inputs are re-parented onto the real parents, so the merge-base history is preserved, and the result is compared tree-for-tree against the recorded tree with the ledger paths stripped (`:1118-1127`).
  - Octopus merges refuse (`:1132`).
  - `tail-proof-manual.log.txt` retains all seven controls. GH-942 recomputes to `121a33348db69fdd2bb30ff164c83c007c6206dc` and keeps approval `6f521bc5`, separate from the landed head `974d98db` (`historical-942-landing.json`).
- Q4 ordering on the main loop is correct apart from S1–S3:
  - merge → ff → wait for hosted → fetch/ff (`merge_cleanup.py:688-700`) → check/pdda → land (`:724`) → `emit_pr_merged` → `commit_and_push_phase5_writes` (`:1290-1291`).
  - Land re-verifies hosted green by PR head with `--repo`. That is consistent with the workflow trigger `pull_request: [closed]` (`.github/workflows/wave-reconcile.yml:4-5`).
  - Auto-merge refuses before any lease: `jog_run.py:1795-1797` in run, and `validate_marathon_executor` at `:208`, which retry-build and retry-gate reach before the lease (`:910-913`, `:788-791`). `auto-merge-entry-manual.log.txt` "PASS HEAD relay simulate=False dry_run=False refused-2".
- Q5: the retained logs match the claims.
  - gh280: "223 pass, 0 fail".
  - jog-queue: "34 passed, 0 failed".
  - gh436: log line 1931 "Ran 180 tests in 267.691s", line 1933 "OK". The earlier "fast-forward … FAILED: boom" is a negative fixture.
  - gh645: "Ran 8 tests … OK".
  - No new suite or unnecessary layer was found.

Handing off to Producer (codex-producer). Disposition S1–S3 (and the Nits as you choose). Fix narrowly, with no new suites or gates, then hand back for Round 2.

### Producer · Round 1 adjudication

S1 Implemented: `03fb2fd9` calls the existing final post-merge publisher after successful executed recovery; dry-run publishes nothing. Manual actual prior-main control exits0 with dirty landing writes; fixed main performs actual committed landing and final commit/push, ending clean at origin. Local bare remote and fixture GH, plus stubbed issue-doc-sync network probe only. Releases check/landing/Git/publisher are real.

S2 Modified: actionable row statuses pending/running/failed/parked are mapped; terminal dropped/completed/archived rows no longer pull a follow-up into Jog. Manual red controls show old behavior dispatching/refusing land for existing dropped904 and completed275, then fixed mapping skips both. We decline the broader suggested rule to silently skip an actionable mapped row with a missing bundle: operator requirement5 explicitly calls land for mapped queue PRs, and missing approval evidence must refuse. This preserves the operator's fail-closed boundary instead of concealing an incomplete lane.

S3 Implemented: capability is loaded beside the exact tool_path-resolved releases CLI, independently of B1's policy copy. The manual control runs this harness-resident helper against an old vendored consumer: prior check invokes an intentionally marked old writer; fixed check refuses before invocation. No ledger writes in either capability probe.

Minor comment fixes and saving clone-ledger-changed cache status were also applied. Other optional/pre-existing nits are outside this delivery and are not silently fixed. The newer source also fixes the legacy interactive supervisor merge route and its inherited lock bypass, with recorded red/green controls. Source reviewed now through03fb2fd9; all evidence in TESTS-RESULTS/2026-10-17+GH-1108. Full final-source gate and actual machine-primary historical recovery remain pending.

Handing off to claude-opus-reviewer for Round2, final source and complete sweep; only this relay writable. Tick done on approval as specified, not release.

### Reviewer · Round 2 (claude-opus-reviewer)

swept file: yes
Scope: I re-read the current working tree. In `merge_cleanup.py` I read the Jog hook, the reconcile and publisher functions, and the `--reconcile-pr` branch (621–770, 1270–1300, 1440–1520). I read `ledger_merge.py:476-488`. In `jog_run.py` I read the legacy supervisor, the lock and the checkpoint (196–212, 1255–1295, 1540–1595, 1960–2010). I read the existing `--reconcile-pr` callers in `test/gh436-merge-cleanup.py:330-380` and `test/gh534_phase_b_tests.py:535-543`, the SUMMARY, and the round-1 manual logs. Probes were `sqlite3 "file:releases.db?mode=ro"` and rg/sed only. I ran no git, no tests and no fixtures. Beyond round 1's Nits, I found no new pre-existing defect in the touched spans.

VERDICT: FAIL
Basis: The S1–S3 dispositions hold in the source. S2 Modified is accepted. One new Should remains: by code trace, the S1 fix breaks an existing merge-cleanup unit test. Its focused suite last ran at `7551ca55`, before `03fb2fd9` (SUMMARY.md), so no retained run covers it. The fix is one test-only edit with no new suite. Everything else passes.

**[Should] S4: the S1 publisher makes the existing `test_reconcile_pr_proceeds_on_a_ready_primary` return 2, but it asserts 0.**
- Path: `test/gh436-merge-cleanup.py:347-363` (`_run_main`) mocks only `inspect_primary_landing`, `run_post_merge_reconcile` (a truthy MagicMock), `refresh_pr_with_retry`, `scan_directories` and `fetch_open_prs`. The primary is a bare `git init -b development` with no origin and no commit (`:342`).
- With `--execute`, `main` now reaches `commit_and_push_phase5_writes` (`merge_cleanup.py:1512-1514`). Its `git status` is empty, but `_net_git(["push","origin","HEAD:development"])` (`:750`) fails because there is no `origin` remote. The function returns False and `main` returns 2. Line `:378` asserts `rc == 0`.
- `test/gh534_phase_b_tests.py:535-543` is unaffected, because its reconcile mock returns False and stops before the publisher.
- Observed input: `merge_cleanup.py --primary <empty git-init repo> --reconcile-pr 42 --execute` with the reconcile step mocked truthy, which is that test's exact setup. I traced this through the code and did not run it [Unverified — needs clone run].
- Affected scope: this one existing test, and any full-gate run that includes `gh436`. No runtime behaviour changes.
- Fix: in that test only, also patch `merge_cleanup.commit_and_push_phase5_writes` (return True). Assert it is called once with `(42, self.primary, "development")`, which turns the existing test into the S1 pin. Do not touch the runtime code, and do not add a new test file.
- Falsifier: run `python3 test/gh436-merge-cleanup.py TestMergeCleanupOrchestration.test_reconcile_pr_proceeds_on_a_ready_primary` at `03fb2fd9` in the gate clone. If it passes unchanged, this finding is wrong.

**[Nit]**
- `jog_run.py:1995-1996`: a real legacy run without `--auto-merge` is parked with `JOG_AUTO_MERGE_CHECKPOINT`, whose text begins "--auto-merge requires…" (`:200-203`). That misleads the operator about why the row parked. Optionally use a neutral reason, such as "primary publication checkpoint required before merge-cleanup (delivery 1)". This is wording only.

**[Pass]**
- S1:
  - Recovery now publishes only when it is not a dry run and reconcile succeeds (`merge_cleanup.py:1506-1515`).
  - It reuses the existing `commit_and_push_phase5_writes` (`:734-767`), so no new publisher was added.
  - `merge-hook-review-manual.log.txt` shows "PASS red prior recovery exits0 with unpublished landing writes" and then "PASS actual recovery mode completes actionable row and publishes owned writes; clean at origin/development".
- S2 Modified, accepted:
  - The mapping now covers only `{"pending","running","failed","parked"}` (`merge_cleanup.py:632-633`).
  - That matches the schema's `CHECK (status IN ('pending','running','completed','parked','failed','dropped','archived'))` (read-only `sqlite_master`). Only the terminal statuses are excluded.
  - Refusing an actionable mapped row that has no evidence is the fail-closed reading of operator requirement 5. I withdraw the broader skip suggestion.
  - Log: "PASS prior terminal follow-up invokes/refuses land; fixed terminal mapping skips issue 904" (and 275).
  - Every `jog_queue` row in this DB has `repo_id=1` (one repo), so the dump's lack of a repo filter has no observed effect.
- S3:
  - `runtime_policy` now loads from `tool_path(repo_path,"releases_app.py").with_name("harness_paths.py")` (`merge_cleanup.py:648-652`), through the new `source=` parameter (`ledger_merge.py:476-488`).
  - The B1 slug lookup is unchanged (`:637`).
  - Log: "PASS prior skill-resident check invokes old runtime; fixed exact-runtime check refuses before old writer".
- Hook DB access: the hook parses the qualified dump with `ledger_merge.parse_dump` (`:631`) and opens no new SQLite connection, which is consistent with the inventory ratchet note in SUMMARY.
- Legacy route:
  - A real (non-simulate) legacy run parks at the checkpoint before `handle_landing_boundary` (`jog_run.py:1993-2000`).
  - The clone driver drops the inherited `RELAY_DRIVER_LOCKED` (`:1562`).
  - The clone ledger bytes are compared around the drive (`:1974`, `:1983-1986`).
  - Log: "PASS legacy supervisor bea9d480 ['parked']" and "PASS real existing target driver refuses live holder despite inherited bypass; no clone ledger change".
- Round-1 Nits: comment fixes and the clone-ledger cache status are dispositioned. The rest are declared out of delivery scope, which I accept.

Handing off to Producer (codex-producer). Disposition S4 with the one test-only edit, then hand back for Round 3. Go to the Producer window and say "take your turn".

### Producer · Round 2 disposition

S4 Implemented. The existing ready-primary recovery test now mocks the final publisher and asserts exactly one call with the resolved primary and development. Red control executes the old test against the new runtime and fails2!=0; the fixed same existing test passes, with the realpath normalization accounted for. Evidence round4-publisher-fixture-{red,green}.log.txt plus before/fixed source text and provenance. No new test file or registered case.

Codex round3 observed a concrete additional defect in B1's line classifier used as a complete queue reader: multiline failure_reason silently drops a valid actionable row. Operator authorized one exceptional Codex Round4 scoped to this defect; no fifth. e088456e replaces the hook reader with existing root-bound releases CLI jog list --all --json, keeping terminal skipping and missing approval refusal. Failed or malformed reader output refuses. No new parser/SQLite site.

At7dc1ed0a the canonical-reader red/green control witnesses actual writer-generated single-line and newline failed rows: prior hook skips newline, fixed hook calls landing for both and refuses invalid/missing evidence; neither read changes the DB. Terminal/unrelated cases skip; malformed/failed extraction refuses. round4-merge-hook-manual repeats actual committed landing/recovery/final publication using the new reader in a disposable primary. gh60528, gh29037 and gh29120 focused checks pass with existing primary/receipt fixtures truthfully adapted. gh436 broad run is still completing; its corrected ready-primary case passes at007a14ad, runtime identical to7dc. Full final-source qualification still pending, not claimed.

Review current source through007a14ad and the bounded final changes/evidence. This is your last configured Opus round3; only this relay writable. User wants the second PR as an unreviewed dependent draft, rebase after first lands; no merge. Please report concrete remaining findings or Approved, with truthful coverage limits. On approval tick done, not release. The Codex exception will run after this turn so any concrete feedback can be included before its unique fourth round.

Handing off to claude-opus-reviewer for Round3.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
