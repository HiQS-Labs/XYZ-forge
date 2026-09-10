---
title: roadmap_items.status_marker has no CLI writer — in releases-mode a row can never leave 🆕
status: 2-WORKING
marathon: gh-490
created: 2026-09-04
updated: 2026-09-09
owner: noelsaw1
gh_issue: 424
source: https://github.com/HiQS-Labs/XYZ-forge/issues/424
doc_type: feature
complexity: 2
risk: 3
effort: 2
phases: 3
non_goals:
  - Deriving the marker from raw_text. Rejected by agy in GH-421 review r2 and rejected here — it re-couples the schema to markdown parsing, which is what releases-mode exists to end.
  - A `releases check` rule for marker/raw_text divergence. Measured as tractable (2 of 117 rows) but a new check rule is a contract every vendored consumer ledger must then satisfy. Parked with the number so the call can be made later on evidence.
  - Repairing the 2 divergent rows (GH-259, GH-347). One CLI call each once the verb exists; not this issue's job.
  - Automating wave_reconcile — GH-421. This issue makes the reconciler WRITE correctly; GH-421 makes it RUN automatically.
  - Backfilling the 54 🆕 rows.
  - A schema migration. status_marker already exists; writing an existing column needs no version bump.
  - Touching ROADMAP.md or its transition code — GH-269.
related:
  - GH-421 (consumes this; blocked on it)
  - GH-269 (a DB that cannot express "done" is not a replacement for the file)
  - GH-271 (the prior incomplete-rollback incident this extends)
goal: >
  Give roadmap_items.status_marker a CLI writer, close the rollback-journal gap that leaves
  RELEASES.generated.md ahead of a rewound DB, and wire the write into wave_reconcile.py at the one
  point where `releases check` can validate it and the dashboard regen can satisfy the push gate.
---

# GH-424: the ledger cannot say "done"

## Status

| What was just completed | What's next |
|---|---|
| DeepSeek v4 Pro QA returned **Conditionally Approved** with four blockers; all four folded in, plus a correction to the reviewer's own fix (its proposed `🛑` is not in the enum it approved) | Re-review by DeepSeek per its own `NEXT: fix-blockers → return to deepseek`. **Implementation does not start until that passes.** No PR and no merge — another agent owns merges right now. |

> Recon map: [`recon-gh424-status-marker.md`](../1-INBOX/recon-gh424-status-marker.md). Every blast
> radius below is traced to `file:line` there. Breadcrumb ledger in the session scratchpad.

## What is actually broken

Not "the marker cannot be set" — three writers set it (`add:3169` hardcodes `🆕`, `sync:3522`
parses it, `load_dump:4533` restores it). **No writer can MUTATE an existing row's marker**, and in
releases-mode `sync` is a no-op, so a row is born `🆕` and dies `🆕`. 54 rows are there now.

And the failure is silent, not loud. **R1:** `roadmap update --raw-text '…✅…'` prints
`updated GH-425` and exits 0 with the column untouched. **R2:** that leaves `marker=🆕` beside a
`raw_text` saying `✅`, and `releases check` calls it clean — while `roadmap-dashboard.sh` renders
from `raw_text`, so the dashboard shows `✅` and the column says `🆕`. Two rows are already in that
state (GH-259, GH-347).

## Phase 1 — the writer

Add `--status-marker` to `roadmap update` (`releases_app.py:4984-4989` parser, `:3350-3366` mutate).

**Enum: reuse `_ROADMAP_STATUS_MARKERS` (`releases_app.py:2814`), do not declare a second list.**
Three vocabularies exist — the parser's 12, the viewers' 4, the data's 3 — and a fourth is how the
`⏸️`/`⏸` drift below happened. The parser's list is the declared vocabulary and is already the
parse-time contract; validate against it in Python, because the column is bare `TEXT` with no CHECK
(`:602`) and the schema will not help.

Three things the recon says this must not break:

1. **Extend the `no-update` refusal** (`:3321-3323`, "pass at least one of --raw-text or --section")
   or `--status-marker` alone is rejected. Pinned today by `test/gh257:74-95`.
2. **Keep the receipt op string `roadmap-update`** — asserted verbatim by `test/gh257:122`. No new
   op name.
3. **Go through `perform_write`** (`:3369`), never a bare `conn.execute`. It appends the receipt
   itself (`:1262-1267`); a direct write is only *detected* later by `check` rule `receipt-chain`,
   never prevented.

**B4 — `select_cols` must include `status_marker`.** `cmd_roadmap_update:3316` does not select it
today, so there is nothing to compare the new value against. Add it, or the divergence warning below
cannot be written at all.

**B3 — `--dry-run` must show the marker change.** `:3339-3348` prints only `raw_text`, rating and
`section`. A dry run that reports "nothing would change" and is then followed by a live run that
changes the marker is precisely the class of defect this arc exists to close. Print
`status_marker: <old> -> <new>`.

**Divergence: warn, do not refuse.** When `--status-marker` is given and `raw_text` carries a
different marker, print a warning naming both. Refusing would break the documented SOP promotion
procedure (`SOP.md:80-83`), which sets `--raw-text` to a bullet that contains a marker. The warning
is the honest middle: it makes R2's hazard visible at the moment it is created, without inventing a
gate that existing data would fail.

**Warn on markers no viewer renders.** Eight of the twelve (`🟡 ⚙️ 🔲 ⛔ 🔮 🟢 🔴 🐞`) have no
entry in either viewer map, so an operator can store a value that silently shows as unclassified.
Do **not** narrow the enum for it — that is the rejected fourth-vocabulary move. Warn at write time
naming the four that render (`✅ 🚧 ⏸️ ‖`). Note this bites the declined case directly: `⛔` is
in-enum and unrenderable, so the reconciler's own declined write will trip its own warning until a
viewer mapping exists. Flagged rather than silently fixed — widening the viewer maps is GH-269's
neighbourhood.

**One reachable-bug fix, in scope because this change reaches it.** The parser declares
`⏸️` (U+23F8 **U+FE0F**); both viewers key on `⏸` (U+23F8) — `export_timeline.py:39`,
`releases_cycle.py:35`. Today unreachable, because nothing can write it. The moment `--status-marker`
ships, an operator can store a marker no viewer will ever render. Add the U+FE0F form to both maps —
two lines. Not fixing it means knowingly shipping a reachable dead value.

## Phase 2 — the journal

`RollbackJournal`'s artifact tuple (`wave_reconcile.py:686-696`) is four files.
`express.py:71-77` already defines the correct five, `RELEASES.generated.md` first. The
reconciler's copy is that list with the first entry dropped.

**Define it once in `harness_paths.py`** — already imported by `wave_reconcile.py:23`, ships in the
core tier, no new module — and import it from both. Copying the list into a second place is exactly
the mistake being fixed. (`express.py` is import-safe: its only top-level statement is the
`__main__` guard at `:790`.)

Two constraints from the map:

- **`snapshot()` no-ops on a missing path** (`:83-89`) and `RELEASES.generated.md` is presence-gated
  adoption (`releases_app.py:1272`). A file absent pre-run must go through `track_created()`, not
  `snapshot()`, or rollback leaves it behind.
- **Tier 1 has no `releases_app.py`** (`xyz-vendor.sh:344`) and therefore can never produce the gen
  file. The fix must degrade silently there, not assume the artifact.

**Why this was invisible:** `verify_rollback_completeness()` (`:146-168`) diffs
`git status --porcelain`, and a **gitignored** file (`.gitignore:73`) can never appear in porcelain.
So an unrestored gen file passes the completeness check and surfaces later as `generation-mismatch`.
Scope honestly: this is an **operator-machine** failure. It cannot reach committed state or CI.

## Phase 3 — sequencing into the reconciler

This is the half that makes the verb worth shipping, and the only correct insertion point:

```
:928-931   validate_and_update_doc      2-WORKING -> 3-COMPLETED / 4-MISC
:932-942   update_roadmap_entry         ROADMAP.md badge + Completed move
   <<-- THE NEW DB WRITE
:985       fix_mangled_roadmap_entries
:988       run_subprocesses   1. roadmap sync (no-op here)
                              2. releases check          <- validates the new write
                              3. export_timeline --preview
                              4. roadmap-dashboard.sh    <- satisfies the GH-243 push guard
                              5. marathon-plan.sh
```

Before `run_subprocesses`, for two independent reasons: `releases check` (step 2) must validate the
post-write state, and `roadmap-dashboard.sh` (step 4) must run *after* the dump changes or
`githooks/pre-push` (`:83`) refuses the reconcile commit outright — pinned by `test/gh243`.

**Which marker to write — B1/B2, and where the reviewer contradicted itself.** The plan originally
said "the reconciler writes the marker" without saying which. Derive it from `is_merged`, the same
signal `update_roadmap_entry` already branches on (`:485`, `:499`), and thread `is_merged` down to
the new call site — today it reaches only `update_roadmap_entry` (`:936`).

DeepSeek specified `is_merged=False → 🛑`. **`🛑` (U+1F6D1) is not in `_ROADMAP_STATUS_MARKERS`**,
the enum the same review approved in Q1 — so that fix would be rejected by the validation it
endorsed. Verified: the 12 are `🆕 🚧 ✅ ⏸️ 🟡 ⚙️ 🔲 ⛔ 🔮 🟢 🔴 🐞`; the in-enum stop glyph is
`⛔` (U+26D4). The ROADMAP.md badge legitimately uses `🛑` because it is free text in a frozen
legacy file.

So: **merged → `✅`, declined → `⛔`**, with an in-code comment recording that the badge glyph and
the DB marker differ *by design* — the alternative is widening a parse-time enum or editing frozen
legacy text, and neither is worth glyph symmetry. B2 asked for the two representations to "agree";
semantic agreement is achievable, glyph identity is not.

**Check the subprocess return code.** B2's other half: wrap the call in an explicit
`if r.returncode != 0: die(...)`, never a bare `subprocess.run`. A refused marker write must fail the
reconcile, not pass silently.

**As a subprocess, not SQL.** `wave_reconcile.py` has no `sqlite3` import and must not gain one;
`AGENTS.md:155-164` forbids hand-editing the ledger.

**Gate at BOTH OPEN-issue sites** — `:920-925` (active-doc branch) and `:946`/`:958-959` (no-doc
branch). A merged PR behind a still-OPEN issue is not a completion, and the guard is duplicated.

**Every fixture mock must learn the verb.** Five suites mock `releases_app.py`
(`test/wave-reconcile.sh:145-185`, `gh168:79`, `gh202:226-295`, `gh232:76`, `gh358:47`). A new
subprocess call breaks all five unless each mock handles it.

## Blast radius this plan introduces, beyond the map's current state

**A live GitHub Projects board starts receiving cards.** `board_sync.py:184` selects
`WHERE status_marker = '🚧'` and treats every hit as a strong candidate to add. That query is inert
today *only because nothing can write `🚧`*. Phase 1 makes it live. Neither review round raised
this.

Mitigation, and it must be a green: **assert that a `🚧` write is visible to `board_sync scan` but
that `board_sync` still performs no write without `--write`.** The board projection changing
behavior is acceptable and arguably the point; a silent unattended card creation is not.

Also introduced: every marker write rewrites `releases.sql`, so it trips the push gate unless the
dashboard is regenerated (handled by Phase 3's ordering); and `site_build.py:95-100` **hard-fails**
on a row missing the key, so the list JSON contract must not change shape.

## Proof — §13: a green gate with no witnessed red is not evidence

Reds. **R1, R2 and R4 are already witnessed in this clone** and their transcripts go in
`test/baselines/GH-424-negative-control.md` as the pre-fix record — not a sentence claiming a
control happened.

- **R1** — no CLI invocation moves a row off its marker; the attempt *succeeds* and reports success
- **R2** — `marker` and `raw_text` disagree and `releases check` returns clean
- **R4** — restore db+sql only, leave the gen file ahead →
  `FAIL: rule=generation-mismatch: … carries generation 404 but the DB is at 403`
- **new** — a `wave_reconcile` run over a merged PR leaves the marker untouched (pre-Phase-3)

Greens, and the over-strictness ones matter most here:

- `--status-marker` rejects a value outside `_ROADMAP_STATUS_MARKERS` rather than storing it
- `--status-marker` **alone** is accepted (the `no-update` extension) — the case a careless fix breaks
- the receipt op is still `roadmap-update`, and `releases check` stays clean after the write
- setting the marker leaves `doc_path`, `section`, `raw_text` untouched unless separately given
- divergence **warns** and still writes — it does not refuse, or SOP §1b regresses
- after Phase 2, an injected failure restores DB, dump **and** the gen file byte-for-byte
- on a fixture with no `releases_app.py` (Tier 1), the journal fix is a silent no-op
- a still-OPEN issue behind a merged PR gets **no** marker write, at both guard sites
- `⏸️` written through the flag renders as `paused` in both viewers
- a `🚧` row appears in `board_sync scan` output, and `board_sync` without `--write` still writes nothing

Registration: `test/gh424-roadmap-status-marker.sh` must be added to `validate.sh`'s `TESTS` near
`:506`, or `test/gh306-registry-bidirectional.sh` goes red. No `Frozen-twin-exception:` or
`New-bash-exception:` trailer is required — neither `.py` file is in the `TWINS` array
(`test/gh308-frozen-twin-guard.sh:14-31`) and `test/` is exempt from the new-Bash rule
(`AGENTS.md:260`).

## Review history

### DeepSeek v4 Pro, 2026-09-04 — Conditionally Approved

Transcript: `relay-system/2026-09-04/gh424-status-marker-plan-qa.md`.

**First turn produced nothing.** It read everything, wrote *"Now I have all the context I need. Let
me compose my thorough review"*, and was killed at 15m10s against the 900s default
`RELAY_TURN_TIMEOUT_S`. Zero tokens, empty relay file. Re-driven at 2700s. Recorded because a
silent empty turn is indistinguishable from an approval unless someone checks — and nothing in the
drive's exit code said otherwise.

**Four blockers, all adopted:**

| | gap | fix |
|---|---|---|
| B1 | Phase 3 never said *which* marker the reconciler writes | derive from `is_merged`, threaded to the new call site |
| B2 | that marker must agree with `update_roadmap_entry`'s badge; and the subprocess return code was unchecked | semantic agreement + explicit `returncode` check |
| B3 | `--dry-run` (`:3339-3348`) would not show the marker change | print `status_marker: <old> -> <new>` |
| B4 | `cmd_roadmap_update:3316` `select_cols` omits `status_marker` | select it, or nothing can be compared |

**Where the review contradicted itself, and I broke it against the reviewer.** B1/B2 specify writing
`🛑` for a declined PR. `🛑` (U+1F6D1) **is not in `_ROADMAP_STATUS_MARKERS`** — the enum this same
review approved in Q1 — so the fix as written would be refused by the validation it endorsed.
Verified against the constant. Resolved as **merged → `✅`, declined → `⛔`** (U+26D4, in-enum), with
the badge/marker glyph asymmetry documented in code rather than papered over: making them identical
would mean either widening a parse-time enum or editing frozen legacy text.

**Adopted from its Q1 caveat:** eight of the twelve markers have no viewer mapping, so a write-time
warning names the four that do. This bites the declined path immediately — `⛔` is itself
unrenderable — which is worth knowing before shipping rather than after.

**Confirmed, and it retires one of my own worries:** `board_sync.py:74-75` classifies `stale_marker`
as **WEAK**, and `reconcile` only writes for STRONG sources. So a `🚧` row can never create a board
card on its own. My "the blast radius reaches the live GitHub board" finding was real about
visibility but wrong about writes — the strength classification already protects it. The green
stands as a pin on that protection.

**Not adopted, deliberately:** its closing note that ROADMAP.md and the DB marker will evolve
independently in releases-mode. Correct, and it is the current design, not a defect of this change —
GH-269's territory.

## Parked

- A `releases check` rule for marker/`raw_text` divergence — **measured: 2 of 117 rows** (GH-259
  `🆕` vs `🚧`; GH-347 `🆕` vs `✅`). Tractable, but a new check rule is a contract every vendored
  consumer ledger must satisfy, and their data is unseen. Deferred with the number.
- Repairing those two rows — one CLI call each, once the verb exists.
- `skills/releases/SKILL.md:28-31` still describes `ROADMAP.md` as the human file and `roadmap sync`
  as the finisher, contradicting `AGENTS.md:155-160`. Doc drift, GH-269's neighborhood.
- `RollbackJournal.deleted_files` is initialized and never used (`:80`). Dead field.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "utils/py/releases_app.py", "pattern": "status-marker" } ],
  "artifacts":   [
    "utils/py/releases_app.py",
    "utils/py/wave_reconcile.py",
    "utils/py/harness_paths.py",
    "utils/py/express.py",
    "utils/timeline/export_timeline.py",
    "utils/py/releases_cycle.py",
    "validate.sh",
    "test/gh424-roadmap-status-marker.sh",
    "test/baselines/GH-424-negative-control.md"
  ],
  "remediation": { "source": "issue#424", "criteria": "`roadmap update --status-marker` sets the column through a receipted roadmap-update write, is accepted alone, rejects any value outside _ROADMAP_STATUS_MARKERS, and warns without refusing when raw_text disagrees; the rollback journal shares one constant with express.py and restores RELEASES.generated.md byte-for-byte under injected failure while no-opping on a Tier-1 install; wave_reconcile writes the marker via subprocess before run_subprocesses, gated at both OPEN-issue sites; validate.sh is green with the new suite registered" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```

## Merge evidence

- PR #504 merged 2026-09-09 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Integration status — PR #495

The design and review history above are retained from development. The gh-490 lane has implemented the writer and reconciliation changes; the historical pre-implementation instructions above describe that earlier review checkpoint. Integration validation is pending. The implementation reuses the existing twelve-marker enum; declined PRs write `⛔` while retaining the legacy `🛑` prose badge.

## Acceptance

- A CLI verb transitions `status_marker` on a named row and refuses without one.
- The dashboard regenerates to reflect the marker change.
- Bulk transition of stale 🆕 rows works without hand-editing SQL; pinned by a new suite.

## Acceptance — reviewer-tightened criteria (CodeRabbit round 1)

- [ ] The verb rejects marker values outside the known enum.
- [ ] Marker writes are receipted (updated_at + issuing verb recorded).
- [ ] Unrelated fields on the row are preserved byte-for-byte.
- [ ] A failed write rolls back the generated dashboard artifacts.
- [ ] `releases check` is clean after the write.
