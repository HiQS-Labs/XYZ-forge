# RELEASES Ledger

This repository includes the RELEASES add-on.

## Enable the RELEASES ledger
To enable the ledger, simply initialize it:
```bash
releases init
```
*(Optional) Use `releases add` to plan forward releases.*

Nothing runs until the ledger is invoked.

## Shared in-progress issue label (GH-646)

Deliberately migrate to schema009 before using
`releases roadmap update --gid OWNED_ROW --accepted-start`. Admission requires an
independently owned full issue URL and a verified native open issue (never a PR).
It sets `In progress`/`🚧` plus the exact nullable `status_label = 'in-progress'`
through the existing locked writer and receipt. Repeated admission preserves the
original start; `--dry-run` writes nothing. Migration, old-dump restoration, rating,
metadata and backfill do not infer starts from legacy appearance. New dumps retain
the field; old dumps restore NULL. NULL means absent/unestablished, not completed.
Schema8 work evidence remains available, with `status_label_supported: false`.

Remote projection is separately opt-in in the existing device configuration:

```json
{"work_connectors":{"github_labels":{"enabled":true,"repos":["owner/repository"]}}}
```

The labels adapter checks current owned state and native identity before changing
only `in-progress`, preserves other labels, verifies readback and retains its old
cursor on outages/conflicts. It handles one distinct actionable issue per bounded
invocation; repeat `releases work reconcile --connector github_labels` to drain
large backlogs (each batch is at most 500 events). Unconfigured or disabled means
no network calls. Legacy board batches remain unchanged; new repair intents are
filtered out without losing cursor progress.
Independently qualified owned repositories omitted from `repos` are safely
acknowledged without network calls, so an opt-in subset can progress. Malformed,
foreign or ambiguous ownership still refuses before this allowlist check.

Direct native closes are discovered by an explicit preview-first
`releases roadmap reconcile-state`, then `--apply` (COMPLETED versus NOT_PLANNED
remain distinct). For already-terminal cleanup drift, reset label replay with
`releases work reconcile --connector github_labels --reset` when witnessed events
exist. With zero events, seed
`releases work emit --event label_repair --roadmap-gid OWNED_ROW`, then reconcile.
This qualified labels-only repair requires a NULL Completed/Deferred row and
does not synthesize lifecycle authority. Unestablished NULL/open issues are
preserved as unresolved conflicts; witnessed local stops can remove stale labels
on open/reopened native issues without claiming closure. Merged PR/open issue and
quiet/stale activity do not imply completion. Reopened terminal rows need a fresh
explicit start.

Disable this connector to roll back projection. Do not run older writer binaries
against migrated ledgers: their dump/digest excludes the new field. No automatic
configuration deployment, production migration or background watcher is added.

## Work-state diagnosis and board policy (GH-605)

`releases work status --json` is a read-only readiness check. It opens an existing database in
SQLite `mode=ro`, never migrates or creates one, and reports schema readiness, connector cursors,
current lifecycle, and the latest unsuperseded non-backfill start observation. The default
activity window is three days (`--stale-days N`); stale or malformed observations are
**unverified**, never evidence that work is idle. The board policy's Done window is a separate
seven-day setting. Diagnostics inspect the SQLite header before opening and refuse a WAL-format
database even when no `-wal`/`-shm` sidecars currently exist; checkpoint it deliberately first.
Informational backfills, metadata-only updates, and re-ratings remain visible as the latest event
but do not supersede a genuine lifecycle transition. Jog add/lease/status/drop/skip/retry writes retain
their existing `GH-N` receipt selector while resolving the unique queue row inside the transaction;
ambiguous same-number rows refuse instead of assigning an event to the first repository. Queue clear
and orphan recovery emit one owned transition per row through the same atomic receipt boundary, while
same-state metadata updates emit no lifecycle transition. Active queue positions compact only when a
row actually leaves `pending`/`running`; repeated or terminal-to-terminal commands cannot decrement
the remaining active rows again.

Repair in this order: run `releases check` and recover any interrupted write; deliberately run
`releases migrate` if status reports schema 7; rerun `releases work status`; review
`releases roadmap reconcile-state` and only then pass `--apply`; review/apply `releases work
backfill`; finally reconcile a connector only after its target is explicitly configured.
Historical replay is not a complete current-state repair: the stock event connector cannot enforce
top-N Ready selection, the Done window, reopen handling, or preservation of unknown evidence.

An explicit `github_board_selection_policy` uses `utils/py/board_sync.py policy-preview --out
<preview.json>`, followed within 15 minutes by `policy-apply --preview <preview.json> --result-out
<result.json>`. Both the preview creation time and its evidence `as_of` clock must be within that
window, ordered `as_of <= created_at <= now`. Preview is remotely read-only and apply re-reads the
ledger, GitHub and board under the existing connector exclusion lock, then keeps that same-ledger
lock through every change.
`policy-restore --result <result.json>` previews conditional status restoration; add `--write --out
<restore.json>` to perform it with durable per-request evidence. Newly added cards are retained
because this path never deletes; partial add/status failures are reported as residual cards. A
policy-managed board refuses raw event replay. GitHub Projects does not offer an atomic
compare-and-swap across devices, so the lock cannot exclude another device: every item ID and
status is re-read immediately before mutation. An unmatched intent or interrupted/indeterminate
request must be read back and freshly previewed, never blindly retried or overwritten.
Add/set/clear responses must acknowledge a nonempty expected Project item ID before the result is
recorded as successful; missing, null, or mismatched acknowledgements remain indeterminate.
Project lookup uses GitHub's `repositoryOwner` union for either user or organization boards, and
database events and policy evidence retain each roadmap row's repository identity. The legacy raw
event connector remains its existing configured single-repository replay path; policy preview/apply
is the complete repo-qualified projection for multi-repository board decisions.
Malformed, missing, or foreign issue URLs remain invalid evidence, but a qualified owning `repos.slug`
(or an origin-proven legacy basename) is retained so the planner preserves that known issue identity
instead of mistaking invalid evidence for an absent ledger row.

`roadmap rate --force` removes the complete prior canonical rating and optional override before
writing the replacement, so `raw_text` continues to parse back to the stored rating columns.
Number-only `roadmap repoint` refuses when more than one repository owns that issue number and, for
a unique match, updates only its resolved global row ID. Pass `--gid <rmi-id>` instead of
`--issue-num` to repoint an exact row. Wave reconciliation qualifies the root repository and
full issue URL before repointing/updating that GID; foreign same-number rows remain untouched.

## Re-pointing a release's tracking issue (GH-222)

When a tracking umbrella issue is superseded (e.g. closed and replaced by a re-scoped one),
re-point the release with `releases update --gid <rel> --tracking-issue <N|URL>` — a bare
number expands against the org/repo slug or the github origin remote, the URL is stored
canonically like the `add` path, and the old issue ref row keeps its identity.

## Roadmap Rating Vocabulary & Grammar (GH-108)

The canonical roadmap rating system scores candidates across four fixed axes:

- **Grammar**: `rated <pri>/<sev>/<appeal>/<effort>` with an optional ` ovr <score>`.
  - Example: `rated 85/70/90/60` or `rated 85/70/90/60 ovr 320`
- **Axes (each integer 1–100, higher is always better)**:
  - `pri` (**Priority**): urgency and strategic scheduling priority.
  - `sev` (**Severity**): pain / consequence if left unaddressed.
  - `appeal` (**Appeal**): stakeholder / developer desirability.
  - `effort` (**Effort / Cheapness**): scores **cheapness / ease of delivery** (higher = cheaper/easier; 100 = 15-minute quick win, 1 = multi-week architectural rewrite).
- **Override (`ovr`, optional integer 4–400)**:
  - Overrides the computed rank sum (`pri + sev + appeal + effort`) for sorting while preserving the underlying four axis scores.
- **Legacy Vocabulary**:
  - `cx/risk/eff` (`complexity/risk/effort`) is a legacy triple. The two vocabularies measure different things and cannot share a row or entry. Convert any legacy entry to `rated` syntax.
