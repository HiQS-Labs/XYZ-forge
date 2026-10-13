# RELAY · GH-898 plan QA (Agy) — revised plan after Codex cap
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-30.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 3

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
6. **Commit only the relay file** (`relay(gh898-plan-qa-agy): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/1-INBOX/GH-898-BOARD-SYNC-ACTIVE-REPOS.md (revised plan). Prior history: relay-system/2026-09-30/gh898-plan-qa.md (Codex rounds 1-3 FAIL→cap; read it for the findings and dispositions). Source to read: utils/py/board_sync.py (resolve_selection_policy :119, plan_selection_policy :221, build_policy_preview :1113, policy-apply :1165, restore_policy_result :1237, the `config` branch of main()), utils/py/device_config.py (resolve_device_block :73), utils/py/work_connectors/github_board.py. Out-of-repo evidence (read-only): /Users/noelsaw/Documents/GH Repos/rebalanceOS/src/rebalance/ingest/db/github.py (top_active_repos), src/rebalance/paths.py.
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-09-30
- Definition of Done: Issue #898 satisfied by the plan's requirements; extends resolve_selection_policy (no new writer/module); no new test files (AGENTS.md GH-831); falsifiable manual checks.

**Operational envelope:** local single-operator developer CLI, ~60-line change in one file. Grade against stated requirements and commensurate complexity; no multi-tenant threat models, locks, journals, or new test suites. Reject speculative abstraction.

**What changed since Codex's last round (grade these):**
(a) F3 resolved by the operator-directed decision recorded in the plan's "F3 decision record": reject `repos_source` + non-empty singular `repo` instead of normalizing identity. Options A/B/C were weighed there.
(b) Review-found gaps fixed: per-key env names (XYZ_GITHUB_BOARD_POLICY_<KEY>), env-delivered string for repos_source, label plumbing via private `_resolve_policy_and_label()`, collection-failure wording, stale status line, blast-radius precondition.

**Questions (cite file:line; every behavior-change request needs Observed input / Affected scope / Falsifier):**
1. Is the F3 decision sound? Under `repos_source` + `repos` only, does the saved policy dict recover to exact equality (board_sync.py:1244-1246) with the documented recovery? Any identity field still not reproducible (check POLICY_DEFAULTS :82-89 and resolve_device_block defaults/env tiers)?
2. Is `repos_source` actually visible to resolve_device_block (declared in POLICY_DEFAULTS) and is popping it from the returned dict compatible with every consumer, incl. github_board.py:126-134 and the `required=False` path?
3. Does `_resolve_policy_and_label()` + unchanged public signature leave all callers (:1114, :1166, :1244, connector) untouched?
4. Is the collection-failure disclosure accurate (board_sync.py:1005-1006) and is "loud failure, remove repos_source" an acceptable remedy for the stated envelope?
5. Is the verification plan falsifiable without new tests, and does the red control detect the real failure?
6. Is anything over-built? Flag unneeded machinery.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer (agy) — Round 1

swept file: yes. No pre-existing defects found in the touched `board_sync.py` config branch or `resolve_selection_policy` footprint.

- `[Pass]` **Question 1 (F3 decision & recovery):** The F3 decision is sound. Because `repos_source` is popped from the dictionary before it is returned, the resolved policy dictionary contains exactly the 14 original keys from `POLICY_DEFAULTS` (`board_sync.py:82-89`). Furthermore, `resolve_device_block` isolates the environment/file merge to only declared keys. Consequently, a policy saved with an active source will have `repo: ""` and `repos: [pinned, active1...]`. The documented recovery (setting `repos` to exactly the saved list and leaving `repo` unset) will perfectly recreate this dictionary, satisfying the exact equality check at `board_sync.py:1244-1246`.
- `[Pass]` **Question 2 (`repos_source` visibility & `github_board.py` compatibility):** `repos_source` is correctly visible to `resolve_device_block` when added to `POLICY_DEFAULTS`. The connector at `work_connectors/github_board.py:126-134` inspects only `project_owner` and `project_number`, so popping `repos_source` before returning the dictionary is completely safe.
- `[Pass]` **Question 3 (`_resolve_policy_and_label` signature):** Splitting the logic into a private `_resolve_policy_and_label()` that returns `(cfg, label)` while `resolve_selection_policy(required=False)` returns only `cfg` flawlessly isolates the change. All existing callers (`board_sync.py:1114`, `:1166`, `:1244`, and `work_connectors/github_board.py:126`) remain untouched and oblivious to the label.
- `[Pass]` **Question 4 (Collection failure disclosure):** The collection failure disclosure at `board_sync.py:1005-1006` (`raise RuntimeError("GitHub returned no %s collection for %s" % (field, repo_name))`) is accurate and correctly names the unreachable repository. For a local single-operator CLI, failing fast and loud is exactly the right remedy.
- `[Pass]` **Question 5 (Falsifiable verification):** The verification plan is fully falsifiable without introducing new tests. Step 6's red control instructs the operator to temporarily mutate the fallback merge logic so that it drops the pinned repos upon source failure. Testing this mutation against the fallback assertion guarantees that the check verifies the real behavior rather than passing vacuously.
- `[Pass]` **Question 6 (Over-building):** The implementation is surgical and direct. It correctly anticipates that `resolve_device_block` (`device_config.py:112-117`) cannot coerce an environment variable into a dictionary when the default is `None`, and elegantly turns this into a structured `ValueError`. No speculative machinery is introduced.

**VERDICT:** PASS
**Basis:** The plan meets all requirements, strictly follows the codebase's existing patterns (including the `resolve_device_block` coercion mechanics), ensures backward compatibility with zero artifacts migration, and defines a highly rigorous, falsifiable manual test matrix without adding prohibited test suites.

relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
