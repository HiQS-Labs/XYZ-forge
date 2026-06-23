**Verdict:** The architecture is right, and it's the part most teams get wrong. You've correctly split "never needs judgment" into deterministic shell and reserved the LLM for fuzzy structure, with an adoption ramp so a fresh install can't nuke a repo on day one. The risk isn't the design — it's that the *one* destructive mechanic (stale auto-move) is the least specified, and your own activity log shows it has zero real miles. Lock that and the LLM severity contract before either goes live.

(The most useful lens on this is your own AGENTS.md — verdict-first, name the freight, reversibility reads. So that's the lens below.)

**What's load-bearing and correct — keep as-is:**

- **The deterministic/LLM split earns its keep, and the log proves it.** The deterministic half is catching real roadmap-checklist leaks and live `/Users/` paths in `RELAY-XYZ-DISCOVERY-SHAKEDOWN.md`. That's the cheap, repeatable win doing exactly its job.
- **observe → light → full with forced dry-run in observe.** This is the single thing that makes governance survive contact with a real doc backlog instead of getting ripped out in week one.
- **Two-column status table as the agent's front door.** Treating the header names as a contract rather than a style preference is correct, and it directly attacks your "agent restarts the same reasoning" failure mode.

**Where it'll bite (ordered by blast radius):**

**1. Stale auto-move is your only destructive mechanic and it's underspecified.** Three problems compound:

- *mtime is a bad staleness proxy.* git checkout, sync, backups, and editors all touch mtime; a doc you're heads-down building *from* (not editing) looks stale at day 4. And you require an `updated` frontmatter field that will routinely disagree with mtime — so which is truth? The best signal is git's last-commit-touching-the-file date: it survives clones and syncs and is an assertion, not a filesystem accident.
- *the move can break the contract it depends on.* The `git mv` is **Easy** to undo. But moving `2-WORKING → 4-MISC` silently invalidates the ROADMAP pointer and any cross-doc links aimed at the old path — so your stale-mover and your roadmap-pointer-checker can fight each other, and nothing reconciles them. That coupling is the real cost, and in `light` mode it happens with no block.
- *the safety valve is optional.* `pdda_hold: true` is filed under "recommended upgrade," but it's the brake on the only mechanic that can lose work. The log confirms the mover has *never actually moved anything* — you'd be shipping an unexercised destructive path with its brake marked optional. Backwards.

**2. Lock the LLM layer's max severity at `warn` — now, before `PDDA_LLM_BIN` is set.** Today `pdda-doc-ready` just skips (confirmed in the log: "LLM readiness review skipped"), which is the free moment to make this contractual. If LLM findings can ever emit `error` in `full`, a non-deterministic oracle gets to block your build — same doc passes at 2pm, fails at 3pm. Only deterministic checks should earn blocking power, or you trip your own AGENTS #8: a suite that flags flakily flags nothing.

**3. The `2026-07-31` cutover is a temporal time bomb.** A deterministic script whose behavior changes silently on a hardcoded date is precisely the fossilized assumption your hardcoded-path check exists to prevent — just in time instead of space. When it passes, CI starts failing docs nobody touched. Open Question #2 is blocking, not nice-to-have.

**Smaller and cheap:**

- **JSONL has no `schema_version`.** All 49 lines are uniform today (good) — but your own "proposed extensions" (`doc_type`, `priority`) will change the shape and break any whole-log reader. It's an append-only event log; those need versioning to stay replayable. Add `"v":1` now while it costs one line.
- **Test fixtures pollute the canonical ledger.** Six lines point at `/tmp/.../bad-roadmap.md` — test findings interleaved with real-repo findings, no field to tell them apart. A hygiene system shouldn't have a dirty log.
- **ROUTER and AGENTS restate the same rules** ("don't override deterministic findings," "don't report unverified wins"). Deliberate redundancy for an agent that reads only one — but it's double-maintenance the day a rule changes.

**Fixes, quick wins first:**

- [ ] Add `"v":1` to every `PDDA-ACTIVITY.jsonl` line — do this before adding `doc_type`/`priority`.
- [ ] Add a `run_kind` field (`real`/`test`) or route `/tmp/` fixture runs to a separate log.
- [ ] Pin `2026-07-31` to one constant, emit a `warn` countdown before it, mark Open Q#2 blocking.
- [ ] In the PDDA spec, make `pdda-doc-ready` findings **`warn`-max, never `error`** — before `PDDA_LLM_BIN` goes live.
- [ ] Switch staleness from mtime to git-last-commit-date; document which field is the single source of truth.
- [ ] Make `pdda_hold: true` a required v1 feature shipped *before* any non-dry-run move; add a `blocked` lifecycle state (borrow deferred/blocked/stalled from rebalance-OS — it's richer than active/stale).
- [ ] Reconcile the stale-mover with the pointer-checker: a move must update or flag inbound pointers, or stay flag-only until it can.
- [ ] State explicitly whether `PDDA_MODE` env or `.pdda-mode` wins when both are set.

The through-line: every weakness is in the *acting* layer, none in the *observing* layer. Your deterministic observers are solid and proven in the log. Everything that can do damage — the file move, the LLM gate, the date cutover — needs its reversibility and severity pinned down before it gets teeth.