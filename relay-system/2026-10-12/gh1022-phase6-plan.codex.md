# RELAY · GH1022 Phase6 qualified Jog observation plan
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-11.
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
6. **Commit only the relay file** (`relay(gh1022-phase6-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md Phase6; utils/py/releases_app.py connect/cmd_jog_list/schema/settings/journal/repository identities/parser and consumers; phase6-jog-read-before.json
- Reviewer: codex · Producer: author
- Started: 2026-10-12
- Definition of Done: Review the smallest proposed qualified Jog seam, legacy compatibility and read-only UNKNOWN contract; no implementation attestation. Own normal new-scope cap3 authorized earlier; accumulation R6 remains FAIL6/6 and cannot be reopened/reset.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 1

Review genuinely new Phase6 W7 prerequisite plan only. Current task3b5fb32e includes developmentff895c83 by preserving merge4dd28049; #1017/#1026 merged, no open Jog inventory overlap. Production reader unchanged. Observed collision: queue RepoA GH777 joins BOTH RepoA/RepoB roadmap titles/URLs under number-only join (committed before JSON/log). Qualify in owner; no second reader/framework/backlog.

Read Phase6 and owning contracts. Determine exact repo/GID/generation/journal semantics before approving. Inventory is one caller-declared root with --all explicit; it cannot attest global authority/quiescence/readiness/delivery. Preserve legacy fields/filter/order and missing-table behavior; unsupported legacy schema stays advisory in default view. Inventory UNKNOWN/nonzero on missing required schema/identity, journal or drift, no creation/migration/recovery/writes. Existing connect must-exist already owns missing DB refusal. Optional read-only SQLite URI leaves writers unchanged. Use canonical helpers, no invented repository slug. Existing/manual verification only, no new CI cases.

Operator prohibits further corrective R6 review; do not reopen its corrections or down-rank Medium GH1028. This new plan turn has no source edits or attestation of finished W7–W11. No suites, pytest, executable fixtures, external/Git writes except relay, extra agents, live execution or connectors. Harmless in-memory read probes permitted. Full owner-file final sweep required later. State actionable severity, observed input, affected scope and falsifier. Normal new-scope cap3, no reset. Handing off to Reviewer(codex)—take the plan turn.

### Reviewer · Round 1

VERDICT: PASS
Basis: Approve only the new Phase6 owner-read plan. The collision is measured at its existing owner, compatibility is explicit, and inventory grants no execution authority. This is not implementation/final-source or W7–W11 approval. Accumulation R6 remains FAIL6/6; GH1028 remains Medium and GH1027 remains unapproved.

swept file: no
Read the whole canonical plan and seeded JSON/log; directly inspected the owner connection, schema, settings, journal/write path, identity, list/parser and diagnostic contracts. The full 6930-line owner-source sweep remains required at final QA, as the Producer explicitly states. No additional pre-existing defect established in the inspected seam; no exhaustive owner-source clearance claimed.

- [Pass] Current `utils/py/releases_app.py:4617` still joins only gh_number. The fresh actual-handler in-memory probe reproduced the seeded duplicate queue GID; the qualified query control returned one owner row and retained an unregistered queue row. Canonical roadmap/queue uniqueness includes repo_id (`:654`, `:959`). Fresh source SHA256 is `74d2f2ed943373af71aec9b8c17e4e5e8aefdca4b76e342ea625ad8cf373491c`, different from the historical seed; the failure persists. Root cause: number-only enrichment loses ownership; fix site: shared owner row query; why not upstream/downstream: tables already encode repository ownership and weekly must not duplicate the reader.
- [Pass] Legacy boundaries are concrete: absent table returns `[]` (`utils/py/releases_app.py:4602`), active filter at `:4608`, projection/order at `:4613`/`:4619`, parser flags at `:6814`. Phase6 preserves these defaults and requires explicit `--all` for weekly terminal/carryover observations (`PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md:592`). The seam does not attest global authority or readiness (`:601`).
- [Pass] Read-only UNKNOWN is consistent with existing owners: connect already refuses missing DB (`utils/py/releases_app.py:433`); `_ensure_jog_schema` writes (`:966`) and cannot be a read probe. Initialization records repo GID/slug and generation1 (`:2187`, `:2195`); `get_generation` defaults missing/invalid values to zero (`:467`), explicitly disallowed as inventory stability proof by Phase6 (`PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md:631`). Existing identity resolution distinguishes owner/name slugs from bare legacy slugs plus validated origin (`utils/py/releases_app.py:5444`). Preserve unregistered queue rows; unresolved required ownership remains UNKNOWN, without guessed slugs or migration.
- [Pass] Canonical journal resolution uses Git common-dir (`utils/py/releases_app.py:345`), not a linked-worktree-local `.git` path. Existing diagnostics reject WAL header/SQLite sidecars and unresolved common-dir before opening a quoted read-only URI (`:5503` through `:5525`). These are relevant existing contracts for the planned no-creation/no-write implementation. Do not acquire WriterLock or recover during inventory: lock attempts append audit state (`:363`). Phase6 already requires journal/drift, mutation-refusal and unchanged-bytes controls (`PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md:605`); those remain implementation obligations, not witnessed successes.
- [Nit] Phase6 says PR1017 actively owns observer repairs (`PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md:617`, `:651`), while resumption at `:815` says #1017/#1026 merged and the old ownership blocker is superseded. Update those two present-tense clauses to refer to the landed owner and avoiding duplicate repairs. No provider acceptance or corrective R6 re-review requested.
- [Unverified — needs clone run] No implementation to attest schema/identity/generation rejection, common-dir journal/drift boundaries, sidecar/byte preservation, missing-DB behavior or default-output parity. No suites, pytest, executable fixtures, Git, providers or connectors ran. Existing/manual disposable-clone checks and the whole owner-file final sweep remain required by Phase6 acceptance (`PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md:637`).

Graph limitation: neither list_projects page contained this worktree. Nearest Forge index generation `2026-10-12T01:54:46Z` supplied discovery/snippets; coverage referred to another checkout and reported missing plan/evidence freshness. Direct current source grounds the citations. Graph trace was rejected with “MCP tool call requires approval, but approval policy is never”; no complete caller-graph claim follows.

Quoted narrow query probe command (in-memory measurement, no filesystem DB/module import/executable fixture):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
import ast, sqlite3
from pathlib import Path
s=ast.parse(Path('utils/py/releases_app.py').read_text())
f=next(n for n in s.body if isinstance(n,ast.FunctionDef) and n.name=='cmd_jog_list')
q=next(n.value for n in ast.walk(f) if isinstance(n,ast.Constant) and isinstance(n.value,str) and 'LEFT JOIN roadmap_items' in n.value)%''
c=sqlite3.connect(':memory:')
c.executescript("CREATE TABLE jog_queue(id,global_id,repo_id,gh_number,position,status,attempt_count,lease_pid,failure_reason,created_at,updated_at); CREATE TABLE roadmap_items(repo_id,gh_number,title,doc_path,issue_url); INSERT INTO jog_queue VALUES(1,'jog-11111111111111111111111111',1,777,1,'pending',0,NULL,NULL,'2026-10-11','2026-10-11'); INSERT INTO roadmap_items VALUES(1,777,'Repo A','A.md','https://github.com/acme/a/issues/777'),(2,777,'Repo B','B.md','https://github.com/acme/b/issues/777');")
print('current:',[(r[1],r[-1]) for r in c.execute(q)])
q=q.replace('ON ri.gh_number = jq.gh_number','ON ri.repo_id = jq.repo_id AND ri.gh_number = jq.gh_number')
print('qualified:',[(r[1],r[-1]) for r in c.execute(q)])
c.execute('DELETE FROM roadmap_items WHERE repo_id=1')
print('unregistered:',[(r[1],r[-1]) for r in c.execute(q)])
PY
```

Exit status: 0. Decisive output:

```text
current: [('jog-11111111111111111111111111', 'https://github.com/acme/a/issues/777'), ('jog-11111111111111111111111111', 'https://github.com/acme/b/issues/777')]
qualified: [('jog-11111111111111111111111111', 'https://github.com/acme/a/issues/777')]
unregistered: [('jog-11111111111111111111111111', None)]
```

Relay closed (Approved), no further plan-review turn needed. Producer may implement the authorized seam, address the documentation Nit, and return for separately required final QA. Broader work remains held.


### Attestation · relay-drive — 2026-10-12T03:44:39Z
task: GH1022-PHASE6-PLAN-R1
reviewer: codex
status: Approved
reviewed-head: bf6f389a6424afcba63953beef8e92c1659fe2f3
added-range: 7208+6451
added-sha256: 23d0d255a36b8c130dbcb6cd625dd7d7ef9c646e35776c34e696622488b14d95
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
