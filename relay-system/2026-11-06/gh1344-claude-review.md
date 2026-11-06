# RELAY · GH-1344 review: finishing work, readers, sweep, close (Codex attempt 3)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-05.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1344-claude-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifacts under review (in-tree repo paths; read each file in full, do NOT edit them):
  1. `utils/pdda/pdda.sh`
  2. `utils/py/wave_reconcile.py`
  3. `utils/py/jog_run.py`
  4. `utils/py/releases_app.py`
- Change under review: `git diff 3a563a9f..HEAD -- utils/` (Codex builder rounds 1 and 2, about +335/−65).
- Plan: `PROJECT/2-WORKING/GH-1344-FINISHING-WORK-READERS-SWEEP-CLOSE.md`. Issue: #1344.
- Prior review: Agy round 1 (4 Blockers + 1 Should) and Codex's round 2 dispositions are in
  `marathon-system/gh-1344-finishing-work-readers-sweep-close/RELAY.md`. Agy never reviewed round 2.
  Verify each of those five findings is actually fixed, with a citation, not just claimed.
- Out of scope for this review: `TESTS-RESULTS/` witnesses and `_marathon_plan.py` (outside the
  builder's allowlist; the orchestrator adds witnesses before the PR). Note any gap they leave.
- Reviewer: claude   ·   Producer: codex
- Started: 2026-11-06
- Definition of Done (issue #1344 Acceptance, verbatim):

- [ ] A doc moved between `PROJECT/` folders breaks no reader that #1340 Task 10 lists (red on the base, green on the PR), recorded under `TESTS-RESULTS/`.
- [ ] One sweep run on a disposable clone clears stranded docs and stale `doc_path` values (before/after recorded), and a closed, never-started capture moves without gaining a row.
- [ ] A local Jog landing still finds its `SHIPPED … (PR #N)` badge after the sweep.
- [ ] The sweep lists delivered-but-open candidates and closes nothing.
- [ ] A one-phase partial delivery with neither proof stays open with one reason comment; either proof closes it (red/green).
- [ ] Existing suites covering pdda, wave-reconcile and jog pass on the final commit. No new test (GH-831).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer · claude

swept file: no

Coverage, stated exactly. Read end to end: `utils/py/wave_reconcile.py` (1–2679). Read in part: `utils/py/jog_run.py` 262–283 and 1184–1408 plus every diff hunk; `utils/pdda/pdda.sh` 30–62 and 1836–1870 plus every diff hunk; `utils/py/releases_app.py` diff hunks only (4061–4073, 4110–4116). A read-only subagent read `releases_app.py` 1–6934 and its report is summarised under "Delegated sweep" below; I did not re-open the lines it quotes. A second read-only subagent read `jog_run.py` 1–2158; its report is summarised under "Delegated sweep of `jog_run.py`". The unread ranges of `pdda.sh` are not cleared for pre-existing defects: its delegated sweep had not reported when this block was written, which is why the line above says no. Probes ran under `.relay-scratch/` only; no `validate.sh`, `test/*.sh` or pytest was run.

VERDICT: FAIL
Basis: Two blocking regressions were reproduced on this repo's own data. The new identity rule makes 12 real docs unresolvable in both languages (two of them active captures with ledger rows), and the new stale-pointer check costs about 3 s per ledger row inside the default PDDA check set. Five further should-fix items carry observed inputs. The five agy round 1 findings are fixed as far as they went, except that 4(c)'s "clean after `--fix`" cannot hold on real data (findings 1 and 3).

**Findings**

1. `[Blocker]` A non-numeric `gh_issue` value now hides the doc from every reader. `utils/py/wave_reconcile.py:1079-1084`, `:1134-1139`; `utils/pdda/pdda.sh:589`, `:611`.
   - Observed input: `PROJECT/1-INBOX/GH-1292-HARNESS-RECAP-HOOKS.md:6` is `gh_issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1292`. `python3 -B .relay-scratch/probe_data.py` (exit 0) compared the pre-change lookups with HEAD over all 583 PROJECT docs: `wave find_active_doc_for_issue old!=new: … (1292, 'PROJECT/1-INBOX/GH-1292-HARNESS-RECAP-HOOKS.md', None)`, `(1293, 'PROJECT/1-INBOX/GH-1293-HQ-NATIVE-HOOK-REGISTRATION.md', None)`. `bash .relay-scratch/p1.sh` (exit 0, real functions extracted from `pdda.sh`): `doc_issue_number(GH-1292 doc)=[]`, `find 1292 rc=1 out=[]`. Twelve docs carry such a value: the two captures above and ten in 3-COMPLETED (606, 791, 793, 912, 949, 1010, 1037, 1051, 1119 as URLs; `GH-661-662-682-RELAY-CONTAINMENT.md` as `661, 662, 682`). Both captures have ledger rows (`1292|Queue / parked intake|PROJECT/1-INBOX/GH-1292-HARNESS-RECAP-HOOKS.md`). On HEAD a PR closing #1292 reaches "No active doc" (`wave_reconcile.py:2583`) and strands the capture; the sweep never considers it (mock probe, a closed issue whose doc has a URL identity: `gh queried: ['801']`, `find_issue_doc(802) = None`); Jog cannot find its contract doc.
   - Affected scope: docs whose `gh_issue` is anything but digits with an optional `#`.
   - Falsifier: with those 12 docs untouched, `find_issue_doc(root, n)` and `_pdda_find_doc_for_issue n` return the doc the pre-change filename lookup returned for each of the 12 numbers, while a doc `GH-602-X.md` with `gh_issue: none` still resolves to nothing (agy r1 4b). Fix: parse the identity instead of comparing strings. Accept `N`, `#N`, `GH-N` and this repo's issue URL; let only an explicit none-style value opt out; fall back to the filename otherwise.

2. `[Blocker]` The stale-pointer block re-scans every doc for every ledger row. `utils/pdda/pdda.sh:750-762`, resolver at `:598-616`, default check registry at `:1656`.
   - Observed input: `bash .relay-scratch/p1.sh`: `miss lookup rc=1 seconds=3`. `sqlite3 -readonly releases.db "SELECT count(*), sum(gh_number IS NOT NULL) … FROM roadmap_items"` returned `456|454`. The block calls `_pdda_find_doc_for_issue` once per gh-numbered row, and each call forks `pdda_frontmatter_value` per doc per pass with no cache (583 docs). The upper bound is 454 × 3 s, about 23 minutes; hits return earlier. Total run time is `[Unverified — needs clone run]`; the per-lookup cost and the row count are measured.
   - Affected scope: every `check_issue_doc_sync` run on a repo with a ledger, and `check_roadmap_coverage` once per doc that the three earlier `return 0` lines do not cover (`pdda.sh:365`).
   - Falsifier: time `bash utils/pdda/pdda.sh issue-doc-sync` on this repo at `3a563a9f` and at HEAD. If the difference is under about 10 s, drop this. Fix: build one issue-to-doc map per run in a single pass over the four folders and look rows up in it.

3. `[Should]` Frontmatter-first resolution picks recon docs, and the checker recommends a fix the sweep refuses to make. `wave_reconcile.py:1078-1080`, `:1150-1152`; `pdda.sh:755-758`.
   - Observed input: `find 494 rc=0 out=[PROJECT/2-WORKING/recon-flightdeck-consumer.md]`, while the ledger row is `494|Completed|PROJECT/3-COMPLETED/GH-494-SESSION-CONTEXT-PLAN.md`. The checker therefore warns "cached doc_path … differs … run: issue-doc-sync --fix", but the sweep skips #494 as ambiguous (14 issues have more than one identity doc, per `probe_data.py`), so the warning never clears. In Python `find_active_doc_for_issue` changed from `None` to a `recon-*.md` for 494, 496 and 981; a closer for one of them would file the recon doc and repoint the row to it (`:2562-2578`).
   - Affected scope: issues with more than one doc declaring the same `gh_issue` (recon docs, phase specs).
   - Falsifier: on this repo `find_active_doc_for_issue(root, 494)` is `None`, and `issue-doc-sync` reports no `repoint-doc-path` for 494, 496, 981 or 111 that `--fix` cannot clear. Fix: one tie-break shared by both languages (prefer the `GH-<n>-` named doc; never pick `recon-*` or `MARATHON-PLAN-*`, which `run_pre_merge` already excludes at `:2168`), and have the checker say "ambiguous" instead of recommending `--fix`.

4. `[Should]` The sweep moves a row to `Completed` without a shipping badge, which removes the issue from catch-up discovery. `wave_reconcile.py:1191-1194`.
   - Observed input: mock probe (exit 0; row `rm-801` in `In progress`, doc in 2-WORKING, issue CLOSED/COMPLETED) printed `TRANSITION ["roadmap", "move", "--gid", "rm-801", "--section", "Completed"]` and no badge write. `catch_up_prs` finds drift only through `dialed_in` manifest members (`:1566`), rows with `section NOT IN ('Completed', 'Deferred · vision')` (`:1569-1574`) and docs in `RECONCILE_FOLDERS` (`:1575-1579`). After the sweep the issue matches none of them.
   - Affected scope: a closed issue with a merged, not yet reconciled closer that is not a manifest member, when `--fix` runs before `--catch-up`. An explicit `--pr N` still writes the badge (`:2582-2599`), and Jog repairs itself (`jog_run.py:1281-1298`).
   - Falsifier: a fixture in that state, `--issue-doc-sweep --fix` then `--catch-up`: `SHIPPED … (PR #N)` must still be written. If it is, keep the move. The plan says "Repoint existing rows only" and `releases roadmap reconcile-state` already owns section state, so the simplest fix is to drop the section move. This reverses part of agy r1 4(c).

5. `[Should]` Both new modes die with a traceback and exit 1. `wave_reconcile.py:2366-2369`, `:2381-2384`.
   - Observed input: `python3 -B utils/py/wave_reconcile.py --root .relay-scratch/tmp/empty --issue-doc-sweep` gave `rc=1` and a traceback ending `ReconcileError: Could not acquire reconciler lock …` (that `die` carries code 8). Both calls sit outside the `except ReconcileError` at `:2668`.
   - Affected scope: every `die()` reachable from the sweep or `--delivered-issue` (no origin slug `:1126`, a `gh` failure `:1163`, the closeout refusal `:2245`), plus the uncaught `KeyError` and `ValueError` from `data["delivered"]` and `int(n)` (`:1145`, `:1148`).
   - Falsifier: the same command exits 8 with one `wave-reconcile: ERROR —` line and no traceback. Fix: wrap both as `run_pre_merge` is wrapped (`:2386-2391`).

6. `[Should]` `--pre-merge` now applies the doc contract to captures and declined docs. `wave_reconcile.py:2176-2179`, `:2204-2207`.
   - Observed input: `probe_data.py`: `1-INBOX: 55/85 docs fail validate_frontmatter_schema`, for example `Doc GH-1052-RECON-VENDOR-CONTRACTS.md frontmatter missing required field(s): updated`; `4-MISC: 1/5`. The old code looked in 2-WORKING, then 3-COMPLETED. The old `Ambiguous active doc match` error is also gone (no test pins it).
   - Affected scope: `--pre-merge` for a change with a closing keyword for an issue whose doc is in 1-INBOX or 4-MISC.
   - Falsifier: `--pre-merge` on a branch whose message says `Closes #1052` exits as it did at `3a563a9f`. Fix: resolve by identity, apply the contract to 2-WORKING and 3-COMPLETED docs only, or record the tightening as intended in the PR.

7. `[Should]` The independence check passes when the receipt names no builder. `jog_run.py:1163-1167`.
   - Observed input: mock probe, receipt `{"whole_issue_coverage": {"issue": 1344, "head_sha": "deadbeef", "covers_whole_issue": true, "reviewer": "codex", "evidence_path": "x"}}` and an issue body with no Acceptance: `returned=True gh=['view', 'close']`. `reviewer != receipt.get("builder")` is true when `builder` is absent.
   - Affected scope: receipts without a `builder` value.
   - Falsifier: the same call returns `False` and posts the reason comment. Fix: require a non-empty `receipt["builder"]`.

8. `[Nit]` `jog_run.py:1179` ignores unchecked boxes in blockquotes and table cells. `## Acceptance\n- [x] a\n> - [ ] quoted b\n` returned `True` with `gh=['view', 'close']`.
9. `[Nit]` The sweep's filename fallback (`wave_reconcile.py:1136`, `^GH-(\d+)`) is narrower than the resolver's (`:1085`, `^(?:GH-)?N`).
10. `[Nit]` `reconcile_delivered_issue` locks `<root>/.git/wave-reconcile.lock` (`:2238`), which fails in a worktree; `sweep_issue_docs` resolves the common git dir (`:1099-1105`).
11. `[Nit]` `--issue-doc-sweep` returns before the other flags are read (`:2366`), so `--dry-run` and `--pr` are silently ignored.
12. `[Nit]` Pre-existing, `wave_reconcile.py`: `validate_and_update_doc` rewrites every line starting `status:` or `updated:` in the whole doc, not only the frontmatter (`:1338-1343`), and the sweep now sends captures through it (`:1183`). `ReconcilerLock` truncates the holder's lock file before it tries the lock (`:65`). `catch_up_prs` still finds docs by filename only (`:1575-1579`). The `repoint_moved_doc_rows` docstring still says docs are found by filename (`:1630`).

**agy round 1 findings, re-checked**

- 1a `[Pass]` Mixed checklists no longer close. `jog_run.py:1179-1180`; probe with agy's input `- [x] … / - [~] … / 1. [ ] …`: `returned=False gh=['view', 'comment']`. All checked closes; an existing marker comment posts nothing (`marker already present: False ['view']`).
- 1b `[Pass]` by reading. Merge evidence is accepted before disposition (`jog_run.py:1267-1272`), and a proven close without a badge runs the single-issue closeout and then requires the badge (`:1280-1298`). The end-to-end landing is `[Unverified — needs clone run]`.
- 2 `[Pass]` by reading. `jog_run.py:266-270`: `allowed = {f"PROJECT/{bucket}/{os.path.basename(resolved)}" for bucket in ("1-INBOX", "2-WORKING")}`. Not executed against git.
- 3 `[Pass]` `find_active_doc_for_issue` searches `RECONCILE_FOLDERS` only (`wave_reconcile.py:1091-1093`) and the lifecycle writers use it (`:2246`, `:2533`, `:2614`). On real data none of its five changed results is an archived doc.
- 4a `[Pass]` by reading. `pdda.sh:1838-1839` shifts only the command, `:1854-1858` forwards the rest, `--census` is `nargs="?", const=True` (`wave_reconcile.py:2360`) and the bare form logs at `:1141-1142`.
- 4b `[Pass]` Archived docs are queried only for a census candidate or a non-terminal row (`:1154-1159`); the `gh_issue: none` opt-out holds (`:1134-1139`), which is also the cause of finding 1.
- 4c Partly. `[Pass]` Moved docs get status and date through `validate_and_update_doc` (`:1183`; probe `TRANSITION ["doc", "move", "GH-801-X.md", "3-COMPLETED", …]`). Not met: a clean `issue-doc-sync` after `--fix` (findings 1 and 3); the section move is finding 4.
- 5 `[Pass]` `_pdda_find_doc_for_issue` iterates `"$PDDA_WORKING_DIR" "$PDDA_INBOX_DIR" "$PDDA_COMPLETED_DIR" "$PDDA_MISC_DIR"` (`pdda.sh:600`, `:608`).

**Other checks**

- `[Pass]` The sweep closes nothing and creates no row. Its only GitHub call is `read_issue_closure_state` (`wave_reconcile.py:1161`); its only ledger writes are `roadmap repoint` and `roadmap move` on an existing `--gid` (`:1186-1194`).
- `[Pass]` The `releases_app.py` extraction keeps refusals as refusals: the helper raises `ValueError` (`:4067-4071`) and the caller catches `(ValueError, OSError, subprocess.TimeoutExpired)` (`:4114`). The refusal text changed; no test pins the old strings (grep of `test/`, no hits).

**Delegated sweep of `releases_app.py` (subagent report, not re-verified by me; no behaviour change is requested on these)**

- Bearing on finding 4: `roadmap move --section Completed` is accepted with no badge, date or closed-issue check, and besides `section` it clears `status_label` (`:1651-1652`), writes a `completed`/`deferred` `work_events` transition (`:1488-1505`) and leaves an in-progress `status_marker` in place. So the sweep records a completion event for a row that carries no shipping badge.
- `[Nit]` `roadmap repoint` rewrites every occurrence of the old path inside `raw_text` (`:3805`), so the comment at `wave_reconcile.py:1188` ("repoint preserves raw_text") overstates it; badges are untouched. It refuses a destination that does not exist (`:3800`), which the sweep satisfies by moving the doc first.
- `[Nit]` `read_issue_closure_state` does not tell an issue from a pull request; the reconcile-state caller relies on `read_native_issue` for that (`:5479`), the sweep calls the helper alone (`wave_reconcile.py:1161-1163`). A doc number that is really a PR would abort the whole sweep. Inferred, not run.
- `[Nit]` Pre-existing: `releases update`, `roadmap repoint` and `roadmap rate` read the row before taking the writer lock and write values computed from that read (`:2451`/`:2480`, `:3792`/`:3812`, `:3725`/`:3763`); `roadmap move`/`update`/`rate` raise `no such column` on a schema-2 ledger instead of refusing (`:1701`, `:3725-3734`); `repoint --doc-path` accepts absolute and `..` paths (`:3800`); `releases update --status shipped` skips the ship evidence rule (`:2133`, `:2480`). No High-severity defect was reported.

**Delegated sweep of `jog_run.py` (subagent report; items 13–15 are by reading, not executed, so the Producer may decline any whose falsifier passes)**

13. `[Should]` Only the first `## Acceptance` section is read. `jog_run.py:1178` uses `re.search`.
   - Observed input (by reading, not executed): issue body `## Acceptance (Phase 1)\n- [x] a\n\n## Acceptance (Phase 2)\n- [ ] b\n`. The first section ends at the next `## `, every counted box is checked, so the issue closes.
   - Affected scope: issue bodies with more than one heading that starts `## Acceptance`.
   - Falsifier: `_close_delivered_issue` on that body returns `False` and comments. Fix: collect the checkboxes of every matching section.
14. `[Should]` The coverage proof is bound to a SHA the receipt cannot contain. `jog_run.py:1165` requires `coverage["head_sha"] == head`, the PR's final `headRefOid` (`:1206`), which includes the commit that publishes the receipt; `:1224` already treats `receipt["head_sha"] != head` as normal.
   - Observed input (by reading): any receipt committed on the PR branch.
   - Affected scope: every use of proof (a).
   - Falsifier: a receipt committed on a PR branch whose `whole_issue_coverage.head_sha` equals that PR's `headRefOid`. If one can exist, drop this. Fix: bind to `receipt["head_sha"]`.
15. `[Should]` The issue is closed before the closeout is known to be able to run. `jog_run.py:1280` closes; `:1282-1288` then runs `--delivered-issue`, which dies unless the PR text references the issue and its base is `development` (`wave_reconcile.py:2242-2245`; `--base` is not passed).
   - Observed input (by reading): a hand-opened PR whose title and body carry no `#N`, issue Acceptance fully checked.
   - Affected scope: proven closes where the PR does not reference the issue, or the manifest base is not `development`.
   - Falsifier: that landing either refuses before `gh issue close` or completes. Fix: check the reference and base before closing, and pass `--base`.
- `[Nit]` Any CLOSED issue returns `True` (`:1152-1153`) without reading `stateReason`, so one closed as not planned still drives the SHIPPED closeout. Plain bullets without a box are ignored, so `- must …` items beside one `- [x]` count as complete; `- [docs](url) …` is read as an unchecked box (`:1179`).
- `[Nit]` Gap outside the allowlist: preflight still globs `PROJECT/2-WORKING/GH-{n}-*.md` (`utils/py/swarm_preflight.py:1232`), so a doc Jog resolves by frontmatter can be promoted and then refused by preflight.
- `[Nit]` Pre-existing: the supervisor lock can be reclaimed between `os.mkdir` and the pid write (`:1333`, `:1374`); `lint_probe` treats the second token as a path, so `python3 -m pytest …` is rejected (`:1401-1408`); `jog_set_status` and the `landing.json` write sit outside the `try` (`:1306`, `:1316`). No SQL built from strings and no `shell=True` were reported.

**Definition of Done, and gaps outside the four files**

- Criterion 1: not met (finding 1). The planner (`_marathon_plan.py`) and the path-integrity reader are not routed through the resolver; they are outside the builder's allowlist.
- Criteria 2, 3 and 6: `[Unverified — needs clone run]`.
- Criterion 4: by reading, `wave_reconcile.py:1164-1165` logs `delivered-but-open … report only`.
- Criterion 5: shown with mocks only (1a above).
- No `TESTS-RESULTS/2026-11-04+GH-1344/` witness exists. `whole_issue_coverage` has no producer in `utils/`, `relay-automation/`, `skills/` or `test/`, so proof (a) can be exercised only with a hand-written receipt. `utils/py/marathon_drive.py:1148` still accepts `--lane-closes-issue`.

handing off to Producer (codex) — go to the codex window and say 'take your turn'.

### Round 2 · Producer · codex

Dispositions for Claude round 1:

1. **Implemented.** `doc_issue_number` accepts N, #N, GH-N and issue URLs; only explicit none/null/false/n/a/no/~ values opt out. Unrecognized declarations fall back to the filename. The sweep and Python readers use the same identity index. The standalone PDDA resolver implements the same policy without depending on Forge's Python modules being installed beside PDDA.
2. **Implemented.** `_pdda_doc_map` reads each configured lifecycle directory once. The cached-pointer checker builds the map once before iterating ledger rows; individual resolutions use that map rather than spawning frontmatter readers for every doc. The real checkout's Python index contains 464 issues and took 0.02–0.04 s in focused runs. This is index latency, not a measured full `issue-doc-sync` duration; no claim about the full check's base/candidate delta.
3. **Modified.** Both indexes omit recon/MARATHON-PLAN supporting docs, prefer primary issue filenames, and use lifecycle priority between primary docs in different folders. Multiple primary docs in the same preferred folder, or multiple unnamed identity docs without a primary, remain ambiguous. The checker reports ambiguity without recommending `--fix`; the sweep skips it. This checkout has two GH-494 primary docs in 3-COMPLETED, so choosing either would still have been unsafe. Active lookup for 494 now returns None.
4. **Implemented.** Removed sweep `roadmap move`. It files docs and repoints existing rows only, preserving section and shipping eligibility for catch-up. Archived pointer repair consequently needs no live closure query unless the issue appears in the census. Section drift remains the responsibility of `roadmap reconcile-state` / normal shipping reconciliation; a warning from that separate check is not a promise that sweep `--fix` will clear it. This deliberately supersedes agy round 1's section-move request.
5. **Implemented.** Both early CLI modes handle `ReconcileError` with its original exit code; malformed census objects/keys and ordinary input I/O/value errors produce the existing ERROR format. Census `delivered` must be a numeric-keyed object. The missing-root lock probe changed from exit 1 plus traceback to exit 8 without traceback.
6. **Implemented.** Identity resolution remains all-folder, but pre-merge adds closer docs to the contract set only in 2-WORKING/3-COMPLETED. Inbox and declined captures no longer acquire the working-doc schema contract through this lookup.
7. **Implemented.** Independent coverage additionally requires a nonempty receipt builder.
8. **Implemented.** Checklist parsing includes quoted bullet checkboxes and table-cell checkboxes. Focused controls show unchecked quoted/table entries keep the issue open.
9. **Implemented.** Sweep uses the same index as the Python reader, including optional GH- filename prefixes.
10. **Implemented.** Exact-issue closeout and sweep share `reconciler_git_dir`, including linked-worktree `commondir` resolution.
11. **Modified.** `--dry-run` takes precedence over `--fix`; conflicting reconciliation modes (including `--pr`) are rejected for sweep mode instead of silently ignored. Qualifying/promotion options remain governed by the ordinary CLI and are not a supported sweep workflow.
12. **Partly implemented; remainder deferred.** The mover now rewrites status/updated only inside the YAML frontmatter. Lock files open in append/read mode and are truncated only after lock acquisition. `repoint` comment now accurately says path references change while badges/ratings/section remain. The pre-existing filename-only catch-up scan and stale explanatory docstring are not a substitute for resolving all Task 10 consumers; the planner/path-integrity/preflight and final witness gaps remain explicitly outstanding for the orchestrator. No claim of whole-file sweep clearance is made by this Producer turn.
13. **Implemented.** Gather checklist entries across every matching Acceptance section; the observed two-phase input now remains open.
14. **Implemented.** Coverage binds to `receipt.head_sha`, whose preservation through the final PR head is already checked by `_landing_tail_proof` in `jog_land`. A receipt committed after its approved candidate can now provide proof without asserting its own containing commit's hash. Nonempty approved SHA remains mandatory.
15. **Implemented.** Before calling the issue disposition helper, landing checks that a PR needing exact-issue closeout references the issue using the reconciler's own extractor. The PR base is already verified against the manifest and is now passed explicitly to `--delivered-issue`. These checks prevent the reported missing-reference/default-development failures from first closing the issue. Later filesystem/network/write failures can still occur after a legitimate remote closure; the existing refusal/retry behavior remains necessary, not an atomic GitHub/local transaction claim.

Other delegated observations: **Modified** the CLOSED fast path to require `stateReason=COMPLETED`, so a declined issue cannot be shipped by that path. **Deferred** the pre-existing lock-reclaim window, command lint limitations, post-try Jog writes, releases ledger concurrency/schema/path-validation observations, and plain non-checkbox Acceptance prose interpretation; no corresponding new reproductions or broad behavior requests are established here. No edit to `releases_app.py` was needed. The no-producer coverage assertion and out-of-allowlist preflight/planner/path-integrity gaps remain with the orchestrator. This is not Definition-of-Done approval.

Verification: focused manual probes only; no git command, project suite, remote mutation, or ledger write ran. `.relay-scratch/probe.py`, `extra-probe.py`, their logs, and `shell-probe.sh`/log contain the ephemeral commands/results. Pre-edit file snapshots provide red controls for URL identity, recon selection, missing builder, multiple Acceptance sections, coverage candidate SHA, premature roadmap section transition, and CLI traceback/exit code. Candidate results passed. Additional controls cover real scratch-file movement/status updates, body preservation, no-row/archive behavior, ambiguous identities, all-checked closure, quoted/table incompleteness, dry-run precedence, and exact full-map Bash/Python parity (464 nonempty entries). Python AST parsing for all three Python artifacts and `bash -n utils/pdda/pdda.sh` passed. GitHub/ledger calls were mocked; the full landing and pre-merge flows were not exercised end to end. No new suite or gate was added. Codebase graph tools were not exposed in this turn, so targeted source reads were the fallback.

Reversibility: **Costly**, because lifecycle writes and a valid remote closure span different stores. The sweep retains the rollback journal; stop on a failing final gate or peer finding. Durable TESTS-RESULTS provenance, final-commit existing suites, disposable-clone sweep and local Jog landing witnesses remain required from the harness/orchestrator. Scratch results are not committed acceptance evidence.

handing off to Reviewer (claude) — go to the claude window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
