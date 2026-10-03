# RELAY · 2026-10-02 seven-PR fold QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-02.
-->

NEXT: Producer
STATUS: Escalated
ROUND: 1 / 1

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
6. **Commit only the relay file** (`relay(pr-fold-2026-10-02): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: committed seven-PR fold branch in this clone (diff against origin/development); focus on the files and source PRs named in Definition of Done.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-02
- Definition of Done: independent, read-only QA of the seven-PR consolidation before publication. This is a local macOS developer toolkit; keep findings proportional. No new tests or gate machinery (AGENTS.md GH-831). Do not run `validate.sh`, `ci-local.sh`, `test/*.sh`, or mutating checks in the relay worktree. Review the committed source and ledger dump; cite file:line or exact rows. Specifically answer:
  1. Does the fold contain all seven PR heads and preserve every CHANGELOG entry? Flag unintended code loss or collision.
  2. Does the merged RELEASES dump preserve #913 jog queue items GH-904/907/906/905 at positions 1-4 and shifted pending rows, plus its four roadmap rows? Are GH-506 and GH-882 semantically equivalent to PR #915, including GH-506 cleared ratings/Deferred doc path and GH-882 `in-progress` status? Distinguish fresh GIDs/timestamps from data loss.
  3. Does the #891 GH-549 fixture resolution keep a single pending event for lock/red-control assertions while avoiding duplicate cursor seeding? Is a concrete failing case visible?
  4. Does `test/test_deploy_skills.py` carry the GH-914 second-of-month collision fix from #915? Any code conflict left unresolved?
  5. Is any newly introduced behavior unsafe or any required source PR behavior dropped? Separate blockers from optional polish. Return PASS/FAIL/PARKED and an explicit `swept file: yes/no` declaration with citations.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL

Basis: all seven pinned PR heads and CHANGELOG content survive, and the specifically requested queue/roadmap resolutions hold. However, the fold loses development's established GH-896 label state and part of its event history. Repair that ledger regression before publication. This is a source/data review, not a passing runtime gate.

swept file: no

Scope: complete source reads of `test/gh549-work-events.sh` and `test/test_deploy_skills.py`; whole-dump parsing/comparison; whole-blob comparisons for the seven PR change sets; targeted reads of differing runtime seams and label consumers. This is not an exhaustive whole-file audit of every pre-existing implementation in the consolidated branch. No additional concrete pre-existing defect was established in the two fully read test files. Graph tools were unavailable; no graph coverage claim is made. No Git commands, suites, executable fixtures, or application writers were run. Scratch probes only read object files/source/immutable SQLite or evaluated pure filename predicates.

- **[Blocker] B1 — GH-896 loses accepted work state during ledger reconstruction.** At development `75b75181299d605b5458dbf4fd367680a05cbb53:releases.sql:773`, GH-896 has `status_label='in-progress'`; the fold's `releases.sql:777` has NULL despite retaining `In progress` / 🚧. Development's event `wev-01M3SDW9K2KKMCRCBAS3TMY2F7` (`releases.sql:2799` at that SHA) records `"accepted_start": true` at `2026-09-30T15:10:40Z`; the replacement at fold `releases.sql:2864` lacks that field and records a new October 2 start. GH-896's five historical events become three; across GH-896/GH-901, seven original event GIDs disappear. This is more than fresh GIDs/timestamps: an actual state field and historical updates are lost. The committed DB agrees with the dump. The label consumer distinguishes active authority using `status_label` (`utils/py/work_connectors/github_labels.py:50`) and refuses unresolved NULL/open state (`:57`); accepted-start idempotence also requires the label (`utils/py/releases_app.py:4001`). Those consumer consequences are source traces, not a live GitHub projection claim.
  Observed input: GH-896 row `rmi-01M3SBWHWGSWAFVKTW7ZAE1MMX` and accepted-start event above from the pinned development base; replacement row `rmi-01M3YKW2WR79PXFKG2AEN1T2GP` in the fold.
  Affected scope: development's existing GH-896 accepted state and the GH-896/GH-901 history reconstructed while folding; no proposed blanket label inference for legacy NULL rows.
  Falsifier: compare the repaired dump and DB against those exact base rows/events; GH-896 must retain established `in-progress` authority and its original start/history, while an unrelated legacy NULL-label row stays NULL. A documented intentional stop would disprove preservation being required, but none appears in the reviewed data.
  Fix: redo the affected ledger resolution through the existing supported merge/writer workflow, preserving the base state/history while retaining the nine intended added roadmap issues. Do not repair this by inferring labels for every 🚧 row or minting a fictitious new historical start.
  Probe: `PYTHONDONTWRITEBYTECODE=1 python3 -` loaded base/fold dump rows through the scratch read-only object/SQL parser and asserted `label == 'in-progress'` for GH-896. **Exit 1**; decisive output: `development GH896 accepted label preserved: True`, `fold GH896 accepted label preserved: False`, `AssertionError: GH-896 status_label lost: None`. Companion `python3 .relay-scratch/final-probes.py`, **exit 0**, reported `DB_dump_focused_rows_match True` and `GH896_event_counts_base_fold 5 3`.

- **[Pass] Seven-head inclusion and CHANGELOG preservation.** Reviewed fold `a546fbe0abb9d09558067a87c6771441a678d4ca`, with substantive merge tip `0bf9954a0fdbe528feb8db1aa9d3bd3fe6515637`. SHA-1-validated, read-only commit-object inspection found these PR head prefixes as second parents along its first-parent chain: #890 `d9b4811c`, #924 `1f9007cb`, #919 `6c6946b3`, #827 `b725c234`, #913 `f6e5b877`, #891 `3a3f6aab`, #915 `698cb143`. For example, the final merge header literally contains `parent 698cb14342286473b774679cd24dc91a12059249`. `python3 .relay-scratch/compare.py` and `python3 .relay-scratch/final-probes.py` both exited **0**: `missing_multiset 0` for all seven complete source CHANGELOGs and development (2,707 nonempty base lines); `conflict_marker_candidates []`. Fold entries include `CHANGELOG.md:3`, `:29`, `:74`, `:80`, and `:89`. These are locally pinned PR heads, not a claim that remote refs were refreshed during review. No fix requested.

- **[Pass] #913 queue and four roadmap rows survive.** `releases.sql:798`–`:801` retain GH-904/907/906/905 at queue positions 1/2/3/4, all pending. The read-only whole-dump probe `python3 .relay-scratch/ledger.py` exited **0**, reporting `semantic_diff {}` for all eight compared pending queue rows and `PENDING [('904', '1'), ('907', '2'), ('906', '3'), ('905', '4'), ('554', '5'), ('555', '5'), ('307', '6'), ('313', '7')]`. The duplicate position 5 is inherited from #913, not introduced here. The four roadmap rows at `releases.sql:781`–`:784` retain titles, paths, ratings, text, markers and sections; their positions shift together from 111–114 to 112–115 to coexist with other intake. New GIDs and write timestamps alone are not data loss. No fix requested.

- **[Pass] #915's GH-506/GH-882 business state is preserved.** `releases.sql:685` has GH-506 under `Deferred · vision`, the `PROJECT/4-MISC/GH-506-SKILLS-ARMY-HQ-REPLICATE.md` path and five NULL rating fields. `releases.sql:786` has GH-882 under `In progress`, 🚧, `status_label='in-progress'`, and its working-doc path. `python3 .relay-scratch/ledger.py`, **exit 0**, reported `semantic_diff {}` for each against #915 after excluding identity/time metadata and the relocated GH-882 roadmap position. GH-506's only changed field is `updated_at`; GH-882's fresh GID/timestamps/position are the other differences. No fix requested.

- **[Pass] The #891 fixture conflict resolution preserves the intended source logic.** The single helper uses `ON CONFLICT(connector) DO UPDATE` (`test/gh549-work-events.sh:163`); leg 15 seeds at the pristine tail (`:475`), the overshoot red control seeds at `MAXID - 1` (`:589`), and both lock legs use the same `LOCK_BATCH_TAIL = max(id)-1` (`:822`, `:859`). Thus the latter assertions have exactly the newest event pending, rather than a second legitimate 500-event batch. The merge does not leave an additional default-tail seed overriding those explicit seeds. No concrete failing case was established for this resolution. **[Unverified — needs clone run]** Actual lock timing, connector invocation counts and mutation-control outcomes still require the existing suite in the disposable full clone; nothing here claims it passed. No source fix requested.

- **[Pass] GH-914's second-of-month fix is present byte-for-byte from #915.** The entire `test/test_deploy_skills.py` blob matches #915. Its collision predicate distinguishes `sample-YYYY-MM-DD` from `sample-YYYY-MM-DD-02` (`:270`–`:274`). `python3 .relay-scratch/final-probes.py`, **exit 0**, extracted that literal lambda via AST without importing/running the suite: `deploy_file_byte_identical_to_PR915 True`, `collision_calendar_days 365`, and `negative_control_old_endswith_on_2026_10_02 False`. The old suffix-only classifier misclassifies the ordinary October 2 archive; the retained predicate does not. No fix requested.

- **[Pass] The overlapping Releases runtime edits compose at the inspected seam.** `utils/py/releases_app.py:1344` retains #913's `projections_enabled` switch and `:3827` validates on/off. The removed automatic `LEADERBOARD.md` refresh is the explicit #827 change, not accidental #913 code loss; the final source differs from #827 by #913's projection additions and differs from #913 by that #827 deletion. Other changed executable/skill files were compared as whole blobs to the relevant source heads; unresolved differences were confined to the documented combined seams and generated/ledger/catalog surfaces. This preservation comparison does not replace the unswept whole-file audit or clone gate. No further concrete code-loss finding established.

Round cap reached: STATUS is Escalated, not Approved. Handing off to **Producer / claude-a** to resolve B1, then obtain another review and the disposable-clone gate. No commit or publication was performed by this reviewer.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
