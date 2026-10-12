---
name: weekly
description: >-
  Prepare held GitHub issue observations and explicit local branch accumulation for
  a weekly Jog or Marathon proposal. Shares 10days discovery and the existing
  weekly/daily planner core; canonical capture and RELEASES writers preserve owner
  state. Selection, freeze, exact approval and shared dispatch enforcement remain
  unavailable. Never auto-fire or schedule.
---

# Weekly — held canonical intake

Distinct from `/weekly-planner` (team outline) and `/daily-planner` (closure pivot).
Never invoke the entire `/10days` workflow for discovery: its unattended rating,
promotion and dispatch exception does not apply to weekly.

**Capability status:** staged implementation for [#1022](https://github.com/HiQS-Labs/XYZ-forge/issues/1022).
Shared discovery, local canonical accumulation and a held declared-work census are implemented. Executable
selection/artifacts, immutable freeze, exact approval, dependency expansion and
shared fire/phase/resume/landing enforcement remain unavailable. Keep dispatch held;
never claim umbrella completion, enable scheduling or run a real Marathon/Jog.

## Read-only observation

Resolve `/relay-xyz`'s shipped `find-harness.sh --root` for a separately copied
skill; require Python3 and the shared intake helper in that selected harness.
A complete repository/vendor bundle uses its own intake, canonical RELEASES
writer and HQ renderer as one runtime, even when an inherited valid harness hint
points elsewhere. Invalid explicit `XYZ_HARNESS`/`XYZ_REPO_ROOT` hints fail clearly;
they do not silently become profile fallback. A separately copied skill retains
central locator discovery, without a sibling-skill dependency. Set HARNESS to the
current runtime root and confirm the explicit repo/timestamp.

Preparation records actual planner/intake/writer/renderer/process-runner paths and
SHA256 hashes, separately from SOURCE_ROOT's target Git HEAD. It checks these
bytes and resolved paths before side effects, target/ledger reads and final commit
boundaries. Code drift preserves uncompleted state for explicit reconciliation or
retry with the exact original runtime; this observation is not an execution
approval or protection against an adversarial change/revert sequence.

Copied skills and older `.xyz` vendors need Python3 and a consistent current
harness with the shared helper and process runner. Copying only an adapter into an
old vendor is insufficient. Use the established vendor/copy workflow when
separately authorized; this task does not update any vendor or deployed skill
collection. Locator startup and legacy planner/10days command policies remain
unchanged except this scoped runtime ownership/invalid-hint correction.

```bash
XYZ_HARNESS="$HARNESS" PYTHONDONTWRITEBYTECODE=1   python3 "$HARNESS/skills/3-weekly/weekly-planner/scripts/planner_core.py"   --repo-root "$SOURCE_ROOT" --gh-repo "$TARGET_REPO" --mode weekly-intake   --since "$SINCE"
```

SINCE must include timezone. `--intake-file PATH` supplies a complete same-repo
prior observation, retaining/refetching every member/carryover/dependency named
there. All updated states, prior members and open PR pages/files are observed.
Duplicate conflicts, malformed/partial/offline data and changing PR snapshots
return UNKNOWN/nonzero. Pagination is complete transport, not an atomic snapshot.
This mode prints JSON and performs authenticated reads only; the bytecode flag
prevents import cache writes. Redirecting stdout explicitly writes a local file.
The outline sequencing/audit fields are advisory, never readiness or delivery proof.

## Declared work census

The opt-in existing-core `weekly-work` mode reads canonical Marathon/Jog/raw lifecycle
facts and explicitly named observer contexts without preparation or dispatch:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 "$HARNESS/skills/3-weekly/weekly-planner/scripts/planner_core.py" --repo-root "$SOURCE_ROOT" --mode weekly-work --authority-file "$AUTHORITIES"
```

AUTHORITIES is an explicit JSON `weekly/authorities@1` object with a nonempty
`roots` list. Every root declares unique `id`, absolute `root`, qualified
`repository` and `contexts` (even when empty). Each context declares absolute
`path`, `coordination_root`, `product_root` and optional absolute `metadata_roots`.
No registry, primary checkout or fleet scan is inferred. Metadata containment uses
physical roots; product ownership preserves the observer's logical path contract.

The canonical `work inventory` owner observes all queue, Marathon and raw lifecycle
rows under one guarded generation/head envelope, including NULL issue references
and unregistered/unknown held evidence. Driver-lock presence is observed through
the shared resolver without acquiring or reaping it. The existing observer's
`snapshot` action reads bounded context/heartbeat/receipt metadata once. Missing,
foreign, malformed or observed drift stays UNKNOWN/nonzero; available raw responses
and per-root provenance remain in accounting. Identical stable facts deduplicate
with all sources; conflicts hold. Runtime paths and bytes are measured separately
from target Git HEADs. Read completeness grants no readiness, authentic peer
attestation, stopped-descendant/global-idle proof or execution approval. Empty
context lists explicitly cannot prove absence of activity. No DB/context/capture,
Git/lease/audit writes, watchers or connectors occur. Redirecting stdout writes the
caller-chosen local output. Durable reconciliation and rollover remain unimplemented.

## Explicit local accumulation

Default weekly preparation commands use the existing `proc_group.run_bounded`
runner: 60-second per-command IO ceiling, one-second termination grace, with
owned-child group cleanup. This includes fresh remote checks and normal Git hooks
or signing while the canonical writer lock is held. Timeout returns held/unknown
and preserves partial state for retry; it does not disable hooks or replace fresh
target checks with cached refs. The ceiling is mechanical IO containment, not a
builder budget, recurring schedule or dispatch permission. Injected fixture
runners retain their existing contract; separately copied locator startup and
legacy modes do not acquire this new command policy.

Held accounting excludes only check URLs/start/completion times from durable
change detection. CI results, draft/review/mergeability state, heads, bodies,
files and unknown metadata remain material. Every returned observation includes
fresh full PR metadata, even when no commit is made; an unchanged input preserves
the committed cut/receipt/HEAD. The accounting artifact is not a frozen execution
receipt: future freeze/fire checks must bind fresh full check evidence separately.

Preparation uses the existing core's opt-in `weekly-prepare` mode. Specify every
policy input; no timezone/date/backfill/overlap defaults are invented. First inspect
its dry preview on a clean source at exact canonical target HEAD (or an owned
preparation clone). This enumerates preserve/register/capture intentions:

```bash
XYZ_HARNESS="$HARNESS" PYTHONDONTWRITEBYTECODE=1   python3 "$HARNESS/skills/3-weekly/weekly-planner/scripts/planner_core.py"   --repo-root "$SOURCE_ROOT" --gh-repo "$TARGET_REPO" --mode weekly-prepare   --prepare-root "$PREP_ROOT" --planning-date "$PLANNING_DATE"   --target-ref "$TARGET_REF" --since "$SINCE"   --initial-backfill all-open --overlap-hours "$OVERLAP_HOURS"
```

`updated-only` is an explicit alternative relevance/backfill policy, not a silent
fallback. `all-open` additionally paginates current open issues. Known carryovers
and dependencies must be included through `--intake-file`; expansion of unknown
or ambiguous dependency references remains unavailable. Every observed member is
accounted regardless of eventual selection; closed status never proves delivery.

Add `--apply` only when local preparation writes are authorized. It creates a new
independent full clone in PREP_ROOT, cuts `auto-yyyy-mm-dd` at freshly checked target
HEAD, or resumes its owned clone. SOURCE_ROOT and the harness must be separate from
PREP_ROOT, with no nesting. Unknown existing directories, linked worktrees, changed
origins/branches, existing remote planning branches and target-base drift hold for
explicit preserved-state reconciliation. It never resets, rebases or pushes.

Apply writes are real: full clone/fetch, branch, canonical captures through
`hq_render_capture`, missing RELEASES rows through `releases_app` CLI with
`XYZ_WORK_CONNECTORS=0`, local lock/receipts and a fixture/planning commit. Existing
rows, GIDs, ratings/overrides/status and owner-authored captures remain unchanged.
New rows stay unrated; captures carry provisional ratings from the sanctioned
renderer. Canonical reader JSON exposes axes, override, calc and effective rank.
The authoritative Python Marathon reader uses the same effective owner rank for
fully rated rows; its historical Bash fallback is unchanged. Selection remains
held until readiness and criterion evidence are reviewed; no weekly scorer is
substituted. The existing report formatter may show DB axes above five as dashes;
the canonical ledger reader retains the actual axes and effective rank.

Committed accounting is `PROJECT/4-MISC/weekly/<date>/intake.json`. Recovery intent
is in the clone Git-dir `weekly-<date>.json`; a nonblocking clone-local writer lock
prevents simultaneous preparation there. Canonical DB lock/journal/receipt/generation
ownership remains in releases_app. Foreign/ambiguous identities, missing/symlinked
captures, owner edits, malformed receipts, ledger generation changes and unknown
partial state hold rather than overwrite. A committed CLI addition whose return was
lost can be adopted only when the exact intended new row, old rows and one generation
increment match. Present canonical journals hold for stopped-owner inspection and
sanctioned recovery; never delete/reset them blindly.

Checkpoint cut is run-start UTC with inclusive caller-supplied overlap. Completion
is recorded after canonical accounting and commit succeed. Failed intake does not
advance; a refused commit retains partial evidence for retry. Unchanged input keeps
the old cut/commit and does not rewrite the completed receipt. This local lock is
not proof of global coordination across clones. Remote branch reconciliation,
rollover/concurrent integration and active-run accounting remain required work.

Every result remains HELD with `dispatch_allowed: false`. Local accounting and
commits are observations, not execution/approval artifacts. No executable YAML,
freeze packet or builder dispatch is generated by these modes.

## Canonical local merge prerequisite

The canonical RELEASES owner provides an opt-in local-parent preservation API:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 "$HARNESS/utils/py/releases_app.py" --root "$OWNED_ROOT" check --merge-base "$BASE_SHA" --merge-target "$TARGET_SHA" --expected-head "$HEAD_SHA" --expected-branch "$BRANCH"
```

The default is a pure preview: Git object reads and in-memory validation, no lock,
recovery, DB/dump/audit/index or connector writes. Supply exact full local commit
SHAs and the unique merge base in an explicit independent full clone. This proves
nothing about remote freshness. Only current identical canonical schema, disjoint
roadmap edits/additions and append-only receipt/event tails are supported. Every
source must roundtrip exactly; conflicting owner GIDs/natural identities, deletes,
unknown shape or invalid history remain UNKNOWN/nonzero. Owner ratings, overrides,
status labels, nullable issue references, captures and ordered history are retained.

Explicit `XYZ_WORK_CONNECTORS=0` plus `--apply` enables real local staged DB/dump,
intent, writer-lock audit, scoped merge receipt and adopted-view effects. Root/HEAD,
source bytes and owner files are guarded before publication. Existing intent,
SQLite sidecar/WAL, driver ownership, device cursors, live leases or unrelated
uncommitted owner edits hold. Backups remain untouched. Repeating the exact already
integrated selection adds no generation or receipt; arbitrary later owner changes
hold. Plain canonical `check` owns interrupted-operation recovery: exact before
means discard this owned staging, exact after means complete its dump, unknown
identity/state preserves evidence for reconciliation. Never replay or restore over
later owner writes. This API performs no Git merge, commit, push, capture, remote
check, approval, scheduling or dispatch. Every result remains HELD/dispatchfalse.
Weekly coordination/adoption/rollover is still a separate unimplemented caller.

## Required continuation

Continue the canonical [GH-1022 plan](../../../PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md)
and full current issue. Reuse canonical writers and authoritative Marathon/Jog owners;
never add a second backlog, scorer, orchestration framework or JOG.yaml contract.
Implement durable published-branch reconciliation, global active-run/PR handling,
authoritative bounded selection/artifacts, draft/required-CI/dependency readiness,
immutable freeze and exact operator approval before adding dispatch authority.

The shared safety protocol remains UNSHIPPED: independent criterion-by-criterion
current-code review; exact target HEAD/plan hash/planning commit receipts; delivered
no-op, partial-delta regeneration and overlap/unknown holds; fresh pre-fire/phase/
resume checks; and separate latest-target redundancy/regression review before landing.
Preserve #752/#1020 recovery holds and separate landing authority. Never treat a
closed issue, Completed bucket/row, linked PR or advisory PASS as criterion delivery.

Every individual new CI test, including cases/parametrizations in existing suites,
requires explicit operator approval identifying it. No test additions are authorized
by this skill, generated plans or review/fire/landing approval. Use existing checks
and recorded manual controls in disposable full clones. This implementation enables
no scheduler, deployed-skill installation, live Marathon/Jog, merge or deployment.
Recheck exact weekly names/aliases before any separately authorized deployment;
preserve weekly-planner/daily-planner routing.

New-issue titles containing canonical rating tokens hold before registration;
GitHub title text cannot assign owner ratings. Final accounting/staging/commit
holds the existing RELEASES writer lock and validates branch/HEAD and committed
object bytes. Lock acquisition writes the canonical local lock/audit sidecars.
Unknown or concurrent owner state is preserved and never completes a checkpoint.
