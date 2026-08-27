# How to Use This System

An operator's guide to running XYZ day to day, organized by time horizon. Adapted from the
operating-rhythm writeup in [#259](https://github.com/HiQS-Labs/XYZ-forge/issues/259); that issue's
comment thread also tracks the skills roadmap that mechanizes these rituals.

One framing point before the rituals: the two core systems own different truths. The **releases DB
is the commitment ledger** — what's promised, to which release, with what evidence. The **marathon
system is the execution engine** — sequencing, concurrency lanes, readiness. The leverage is in
never duplicating either's state by hand, and letting each oracle catch the other's rot.

## Hour to hour — let the ledger answer "what now"

- **Start sessions with `releases next` + `releases show` on the active release.** The queue is
  already scored (`rating_pri/sev/appeal/effort/ovr`) — resist re-deriving priorities in your head
  or in chat. If the ranking is wrong, re-rate the row so the correction is durable.
- **Run the item's preflight before building it.** The `already-landed` check (`fix_probes`)
  exists because work sometimes already shipped — GH-197's history (closed on work that never
  landed, reopened, re-closed against verified code) is exactly that failure class. Two minutes of
  probing beats building something twice.
- **Record evidence at the moment of action.** `manifest ship --evidence` while the PR/test
  receipt is in front of you. GH-205 sat `dialed_in` for days while its issue was closed because
  shipping evidence was deferred — the op_receipts audit trail is only as good as its timeliness.
- **Never hand-edit `ROADMAP.md` ledger rows, `releases.sql`, or the DB.** Every hand edit breaks
  the DB↔dump↔generated triangle that `releases check` guards. Verbs only.
- **At merge time**, the rhythm is mechanized (`wave_reconcile.py --pr N`) — remember the two
  gates: capture docs need their Lessons Learned section *before* merge, and PR bodies citing a
  foreign tracker need an offline `issues[]` manifest.
- **For the immediate "run today" queue**, use jog once landed (GH-259 Phase 1): `jog GH-<n>`
  queues without wave-planning ceremony; full contracts are owed at fire time, not capture time.

## Day to day — a morning drift sweep and a generated plan

- **One command block each morning**: `releases check` + `marathon-plan.sh --dry-run` +
  `pdda.sh issue-doc-sync`. Deterministic output means any diff is real signal. The three drift
  classes it catches — `already-closed` (ledger stale vs GitHub), `already-landed`,
  `undocumented-partial` — are precisely the rot that accumulates silently. Five minutes daily
  keeps that list at zero-attributable. End the sweep by confirming the tree is clean
  (`git status --porcelain`) so the sweep itself can't become the day's first undetected drift.
- **Generate the day's `MARATHON-PLAN-<date>.md`, never author it** — it's collision-lane aware
  (`agy_safe` vs `orchestrator_only`), which is what keeps concurrent harness turns from stomping
  each other. Then link outcomes back: `releases manifest marathon` rolls marathon results up
  into the release manifest.
- **Same-day dial-in decisions on new intake.** When something lands in `1-INBOX`, either
  `manifest dial-in` it with a `dial_reason` or `cut --reason` it. Undispositioned intake is how
  backlogs of warnings form — the reason columns are your future self's context.
- **Close the loop before bed**: `releases gen` and treat a non-empty
  `RELEASES.generated.md.drift` as unfinished business.

## Day to week — release boundaries and disposition sessions

- **Weekly `releases list` review of the target-date ladder.** Drafts carrying `MIG-` placeholder
  tracking refs age into `mig-ref-stale` warnings (>7 days). A weekly disposition session
  (convert to real tracking issues or cut) keeps the strict flip reachable.
- **Per-release boundary ritual** — at a multi-day shipping cadence, "weekly" is really
  "per-release": `releases baseline` at kickoff (write-once — it's your mid-release scope-change
  detector), then at close require *zero* `dialed_in` stragglers, `releases check` clean,
  dashboards regenerated, then ship.
- **Weekly held-item disposition.** The planner never auto-places held items in waves — held is
  where work goes to be forgotten unless someone explicitly re-rates, parks, or cuts. A weekly
  pass over held buckets plus a `gh-refresh` of the issue-state cache closes that hole.
- **Feed what the drift oracles find back into core.** When the same manual workaround recurs
  across sessions, it's either a core fix or a skill — file it. The oracles detecting their own
  blind spots is the system working as designed; leaving the finding undispositioned is not.

## Where the deeper docs live

- [ROUTER.md](ROUTER.md) — canonical entry points and command rails (start here each session).
- [AGENTS.md](AGENTS.md) — repo behavior, decision quality, and proof rules.
- [PROJECT/PDDA.md](PROJECT/PDDA.md) — the doc lifecycle contract (1-INBOX → 2-WORKING → 3-COMPLETED).
- [RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md) — the app-managed ledger contract and merge procedure.
- [skills/relay-xyz/SKILL.md](skills/relay-xyz/SKILL.md) — driving automated relays and marathons.
