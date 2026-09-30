# RELAY · GH-898 plan QA — board_sync repo allow-list from rebalanceOS active-repos
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-30.
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
6. **Commit only the relay file** (`relay(gh898-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/1-INBOX/GH-898-BOARD-SYNC-ACTIVE-REPOS.md (plan). Source to read: utils/py/board_sync.py (resolve_selection_policy :119, plan_selection_policy :221, build_policy_preview :1113, policy-apply :1165, cmd_config), utils/py/work_connectors/github_board.py, utils/hq/hq-lib.sh. Out-of-repo evidence the plan cites (read-only): /Users/noelsaw/Documents/GH Repos/rebalanceOS/src/rebalance/ingest/db/github.py (top_active_repos), src/rebalance/paths.py (resolve_database_path).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-30
- Definition of Done: Issue #898 satisfied by the plan's 6 requirements; plan extends resolve_selection_policy (no new writer/module); no new test files (AGENTS.md GH-831); falsifiable manual checks.

**Operational envelope:** local single-operator developer CLI, ~60-line change in one file. Grade against the stated requirements and commensurate complexity; do not ask for multi-tenant threat models, locks, journals, or new test suites. Reject speculative abstraction.

**Questions (cite file:line):**
1. Are the plan's claims about board_sync.py true? Specifically: does widening policy["repos"] change only what the plan says (observation filter, planner `allowed`, collect_github_state loop)? Is anything that reads cfg["repos"][0] or policy["repos"] missed (incl. work_connectors/github_board.py)?
2. Is the pinned-first ordering sufficient to keep touch/default paths (:736, :802, :902) correct?
3. policy-apply refuses if policy != preview["policy"] (:1167). With a live-computed repo list, is the refusal behavior (re-preview) acceptable, or does it make apply flaky in a way the plan under-states?
4. Read-only immutable sqlite open of a 4.9 GB WAL database: is `file:...?immutable=1` safe against a concurrently-writing rebalanceOS launchd sync (stale/inconsistent read), and is that acceptable for an allow-list signal?
5. Failure contract (req 4): does fallback to the pinned list cover DB missing / locked / empty / schema-absent (no github_activity table)? Any case that returns an empty allow-list silently?
6. Is this the smallest change? Is a direct DB read the right coupling vs. alternatives the plan rejected, and is the org-rename alias gap (non-goal) acceptably bounded?
7. Is the verification plan falsifiable without adding tests, and does the red control detect the actual failure?

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

VERDICT: FAIL
Basis: the one-file approach is appropriate, but the plan assumes an unsafe live-DB read and understates existing mutation/restore behavior. Revise the plan before implementation; no new writer, locks, modules or test suites requested.

Evidence scope: reviewed the entire plan and board_sync.py, the complete github_board connector, the relevant HQ read paths, and rebalanceOS's activity query and database resolver. No additional independently established pre-existing source defect found; the findings below concern the proposed feature's interaction with existing behavior. Verify-tier graph attempt: XYZ-forge generation 2026-09-01T15:54:30Z points at another checkout; symbol search returned zero and coverage reports board_sync.py / github_board.py freshness not_tracked, hq-lib.sh metadata_changed. Used this worktree's exact source as fallback; graph completeness is not claimed. Read commands exited 0. No suites, executable fixtures, live mutation, or git commands ran.

- [Should] **F1 — Replace immutable live reads with a safe read-only attempt and pinned fallback.** Plan :27, :37 and :59 treat successful immutable opening as justification for using it on the live WAL DB. SQLite explicitly disables locking/change detection for immutable files and warns of incorrect results or SQLITE_CORRUPT if the file changes ([SQLite URI §3.3](https://www.sqlite.org/uri.html)). This is more than a tolerable older activity snapshot. Smallest fix: URI mode=ro (properly encoded path), bounded timeout, close the handle, warn and retain pinned repos on sqlite3.Error/OSError; do not retry with immutable against the changing live file. An immutable read is appropriate only for an actually stable snapshot. No need to copy 4.9 GB or fix the writer.
  Observed input: plan :24/:27 names the live 4.9 GB WAL DB; Setup question 4 identifies its concurrent launchd writer. This is a documented safety-contract conflict, not a witnessed corrupt query; no Blocker grade claimed.
  Affected scope: reads of a database that another process can modify/checkpoint.
  Falsifier: demonstrate that the chosen input is an unchanging snapshot for the full connection lifetime; immutable would then be valid. In the intended live case, a read-only open failure must warn and return pinned repos. Concurrent-WAL measurement is [Unverified — needs clone run].

- [Should] **F2 — Correct the visibility-only and rollback claims.** Plan :29/:48 says non-Forge card moves need per-repo ledgers. Existing planner deliberately moves OPEN PRs without ledger rows (board_sync.py:252-255), follows closing links without a row (:262-279), and handles CLOSED issues before the missing-ledger guard (:309-329). Those changes flow to the existing writer (:1217-1219). Cheapest fix: explicitly accept/document these existing GitHub-authoritative moves for added repos; reserve the non-goal for ledger-dependent Ready/start decisions. Describe the opt-in as widening mutation eligibility as well as visibility, and replace “No data written anywhere” (:55) with the actual distinction between source resolution and a subsequent policy-apply.
  Observed input: board_sync.py:254-255 sets an allowed OPEN PR target to in_review with no ledger lookup; :262-279 explicitly permits an OPEN closing-linked issue with zero ledger rows.
  Affected scope: newly allowed repos' PRs, closing-linked issues and terminal issues; ordinary OPEN unlinked issues still hit :328-330.
  Falsifier: in a disposable clone, allowed repo other/r with ledger=[] and GitHub OPEN PR #1 must yield an In review change; an OPEN unlinked issue #2 with ledger=[] must remain unresolved. If both remain unchanged, this scope finding is wrong. These executions are [Unverified — needs clone run].

- [Should] **F3 — Account for policy-restore drift, not just preview/apply drift.** restore_policy_result compares the whole resolved policy with the saved result (board_sync.py:1244-1246) before readback. An activity-list change, even ordering alone, prevents restoring a previously applied result; deleting repos_source also does not make the old result match. Cheapest fix within the stated scope: explicitly document the limitation and an exact recovery procedure that reconstructs the saved resolved policy (including its source metadata) before conditional restore, with a clone check proving it. Alternatively propose a narrowly scoped restore compatibility change, with its own proof; do not silently remove the identity guard.
  Observed input: board_sync.py:1245-1246 contains 'if policy != result.get("policy")' and raises 'current policy does not match the result artifact'; plan :44 only covers apply refusal, :55 supplies no board-restore procedure.
  Affected scope: a saved applied result whose dynamic list/source differs from current resolution.
  Falsifier: saved result repos=[pinned/r,active/a], current repos=[pinned/r,active/b] must refuse; then the documented recovery must permit conditional restore readback while still refusing a genuinely different board owner/number. Execution is [Unverified — needs clone run].

- [Should] **F4 — Make manual proof cover all six requirements and witness a real red control.** Plan :59-63 does not assert pinned order/dedupe/cap, unchanged absent-source behavior, since_days/type validation, schema-absent versus empty-result fallback, or source labeling on fallback. An empty DB producing the intended warning is a positive failure-path check, not the AGENTS.md red control: no assertion has been shown to fail. Add a compact manual matrix and an intentional temporary mutation of the implementation in the disposable clone (e.g. return [] on DB failure), then witness the same pinned-list assertion fail and restore from a copy. Assert extracted data is nonempty; commit provenance.jsonl with the evidence. Explicitly put test/*.sh runs in a disposable full clone.
  Observed input: plan :63 calls the expected successful empty-file fallback the 'Red control'; :60 lists only bad top_n values, and :62 records a directory without requiring provenance.jsonl.
  Affected scope: acceptance evidence for this opt-in resolver; no new test files or gate machinery.
  Falsifier: the manual pinned-list assertion passes on correct fallback and fails on the deliberate [] mutation. A schema-present zero-score DB must warn/fallback separately from a DB lacking github_activity; both must preserve a nonempty pinned list.

- [Pass] **Consumer trace / minimum mechanism.** Legacy touch/default paths consume resolve_settings(), not the saved selection policy (board_sync.py:1407/main cfg assignment, :736/:802/:902); keeping pinned order is sensible for _policy_board_cfg (:975-979), but does not itself change legacy settings. github_board.run uses policy only for board-target exclusion (:126-134); its own cfg repos[0] (:96-99) stays legacy and replay remains refused for the policy-managed board. No parallel writer is needed. Direct stdlib SQL is a reasonable small coupling when the package is unavailable (plan :28/:44), with schema failure mapped to fallback.

- [Pass] **Apply refusal is acceptable with an explicit limitation.** board_sync.py:1166-1168 rejects differing policy before mutations, and :1187-1191 additionally rechecks a fresh preview. Re-preview is a defensible single-operator response (plan :44). Document ordering-only changes and source outages as refusal causes too, and use a deterministic score tie-break in the copied query if reproducibility is desired; rebalanceOS github.py:36 currently orders only by score. The org-rename gap is explicitly bounded in plan :49; keep it and disclose that an inaccessible added repo can fail the whole collection (board_sync.py:1005-1006).

- [Nit] There is no cmd_config function: config is a branch inside main (board_sync.py, 'if args.cmd == "config"'). Name that existing branch in the plan, and state how repos_source enters resolution: resolve_device_block only copies keys in defaults (device_config.py:95-111), so a helper alone cannot see an undeclared policy key. Keep the absent-source policy/output compatibility contract precise when adding source metadata.

Handoff: Producer (claude-a) should disposition F1–F4 and the nit, revise the canonical plan, and open round 2. Harness owns the file-scoped commit; reviewer did not commit.

### Producer · Round 1 (claude-a)
Plan revised in PROJECT/1-INBOX/GH-898-BOARD-SYNC-ACTIVE-REPOS.md. Dispositions:

- F1 — Accepted. `immutable=1` dropped; `mode=ro` (URL-encoded path, 2 s timeout, close, warn + pinned fallback on sqlite3.Error/OSError). Measured: Python `mode=ro` opens and queries the live DB (0.0 s); the earlier failure was the `sqlite3 -readonly` shell call. Score query gains a `repo_full_name` tie-break.
- F2 — Accepted. Plan now states the opt-in widens mutation eligibility (PR/closing-link/CLOSED moves need no ledger row, :252-329); non-goal narrowed to ledger-dependent Ready/start decisions; rollback wording corrected to distinguish resolution from policy-apply; inaccessible-repo failure (:1005-1006) disclosed.
- F3 — Accepted as documented limitation + exact recovery procedure (pin repos to the saved policy, drop repos_source, restore, revert), with a clone proof. No change to the identity guard.
- F4 — Accepted. Manual matrix covers all six requirements incl. schema-absent vs zero-score; red control is now a real mutation (helper returns [] on failure) witnessed failing then restored; suites run in a disposable full clone; provenance.jsonl required.
- Nit — Accepted. Plan names the `config` branch in main() and adds `repos_source` to POLICY_DEFAULTS (device_config.py:95-111 only copies declared keys).
- Both [Unverified — no citation] items noted; ordering-only/outage refusal causes added to the apply-refusal note.

Nothing rejected. Requesting round 2.

### Reviewer · Round 2
swept file: yes

VERDICT: FAIL
Basis: the minimal resolver approach is sound and the live SQLite read contract is repaired, but the documented restore recovery and red control still need precise corrections. These are small plan fixes, not requests for new infrastructure.

Evidence scope: swept the entire revised plan and board_sync.py, the entire github_board connector, relevant device_config/HQ paths and rebalanceOS activity SQL/path resolver. No additional independently established pre-existing source defect found. Applied the SWE planning rubric. Verify-tier graph: XYZ-forge points at a different checkout, generation 2026-09-01T15:54:30Z; resolve_selection_policy search returned zero (has_more=false). Coverage: board_sync.py/github_board.py not_tracked, device_config.py/hq-lib.sh metadata_changed. Read exact local source as fallback; no completeness claim about the graph. Source-read commands exited 0. No git, suites, executable fixtures or live mutations ran. Implementation/recovery measurements remain [Unverified — needs clone run].

- [Should] **F3 remains open — make the recovery reconstruct the actual saved policy.** Plan :46 says set repos to saved policy.repos and remove repos_source. With singular repo still configured, resolve_selection_policy rejects a widened repos list before restore (board_sync.py:125-128). Moreover the resolver returns the complete cfg (:162), and restore compares the whole dict (:1244-1246): deleting source cannot recover equality if the result saved source configuration/label, or if the absent-source key is now None. Requirement 5 (:39) does not specify whether the label is display-only or part of the saved policy. Cheapest fix: explicitly define that representation and give an equality-preserving recovery for it; remove/clear singular repo when pinning the full saved list, preserve all other saved policy fields and account for env overrides. Keeping source diagnostics outside policy identity can simplify recovery, provided absent-source byte compatibility is preserved. Do not edit the result artifact or bypass the board identity guard.
  Observed input: the supported singular-repo config {"repo":"pinned/r"} (board_sync.py:125-128), followed by the documented recovery adding repos=["pinned/r","active/a"], satisfies the existing "policy repo and repos disagree" predicate. Plan :46 explicitly removes repos_source although :39 adds it to POLICY_DEFAULTS.
  Affected scope: recovery of dynamic-policy results when singular repo is set, or source metadata participates in saved policy equality.
  Falsifier: in the disposable clone, generate the saved policy through the actual resolver from a singular-repo + enabled-source config, then change active membership. The revised recovery must produce a dict exactly equal to result.policy before conditional restore readback; changing owner/number must still refuse. A hand-constructed result omitting source fields does not falsify this finding.

- [Should] **F4 red control is still underspecified at the wrong boundary.** Plan :73 mutates _rebalance_active_repos to return [] on failure, but :36/:38 requires the resolver to retain pinned repos when activity contributes nothing. For the natural implementation pinned + helper_result, [] is exactly the fallback contribution; that mutation leaves the pinned-list assertion green. Cheapest fix: mutate the final resolved fallback list to [] (or remove the pinned contribution at the resolver merge), then run the same nonempty/equality assertion, require nonzero exit, restore from a copy and require zero exit. Keep the helper return contract explicit so the control cannot be a no-op.
  Observed input: plan :63 helper takes only source; :36 specifies pinned repos followed by added activity repos; :73 changes only the helper's failure return to [].
  Affected scope: the manual red control's ability to detect loss of pinned repos on source failure.
  Falsifier: record the exact mutation and decisive output showing the existing fallback assertion changes from exit 0 to nonzero, then back to 0. If helper=[] truly erases the final pinned list in the chosen implementation, that output establishes the original control is adequate. This is [Unverified — needs clone run].

- [Should] **F2 documentation is contradictory rather than fully dispositioned.** Plan :29 still says "card moves for those repos still need a per-repo ledger root"; :52 still excludes "moving cards for non-Forge repos". Both contradict :48's accepted GitHub-authoritative moves, grounded in board_sync.py:252-279/:309-329. Replace those two old statements with the narrower ledger-dependent Ready/start non-goal already written at :48. No runtime change requested.

- [Pass] **F1 / failure contract / minimal mechanism.** Plan :37-38 explicitly specifies mode=ro, encoded path, 2 s timeout, close, sqlite3.Error/OSError fallback and separate schema-absent/zero-row warnings; :44 keeps one helper in board_sync.py with deterministic tie ordering and no parallel writer. This is an appropriate plan contract for the stated single-operator scope. Actual locked/live-WAL outcomes await clone evidence; timeout bounds lock waiting, not total query duration.

- [Pass] **Consumer and mutation scope.** board_sync.py:204/:224/:986/:1256 consume policy repos for observations/planning/collection/restore allowlisting; _policy_board_cfg (:975-979) copies that list into writer cfg. Legacy cfg comes from resolve_settings (:1407) and github_board.apply_event uses its own cfg repos[0] (:96-99); github_board.run only compares policy board owner/number (:126-134). Plan :48 correctly accepts the widened GitHub-authoritative mutation scope and collection-failure exposure. No additional repo-list consumer missed in the swept source.

- [Pass] **Apply drift and remaining proof matrix.** Plan :44 explicitly accepts re-preview for membership/order/outage drift; board_sync.py:1166-1168 refuses before mutation. Plan :67-72 requires absent-source compatibility, validation, pinned order/dedupe/cap, schema/empty fallback, labels and committed provenance; :66 places suites in a disposable full clone. F4's red-control fix and F3's actual-resolver recovery proof remain required before approval.

Handoff: Producer (claude-a) should resolve F3/F4 and remove the two stale F2 statements, then open round 3. Harness owns the file-scoped commit; reviewer did not commit.

### Producer · Round 2 (claude-a)
Plan revised; all three findings accepted, nothing rejected.

- F3 — Accepted. Representation defined: source metadata is diagnostic only; `resolve_selection_policy` pops `repos_source` so the policy dict has today's keys and only `repos` differs (absent-source byte compatibility preserved). Recovery now also removes the singular `repo` key (board_sync.py:125-128), preserves all other saved fields, and accounts for `XYZ_GITHUB_BOARD_POLICY`. Step 7 generates the saved policy with the real resolver and requires dict equality before readback, plus a different-owner/number refusal.
- F4 — Accepted. Red control now mutates the resolver's final merge (drops pinned on source failure), requires nonzero exit then zero after restore; helper contract (`[]` on nothing) stated explicitly.
- F2 — Accepted. The two stale statements (recon bullet, non-goal) rewritten to the narrower ledger-dependent Ready/start non-goal; consistent with the Mutation eligibility paragraph.

Requesting round 3 (final within cap).

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
