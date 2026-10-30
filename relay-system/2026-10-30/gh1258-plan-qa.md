---
Goal: Plan QA — #1258 Phase 1 (idea skill: SKILL.md + ARCHITECTURE.md row)
Date: 2026-10-30
NEXT: codex
STATUS: Open
---

# Context

Independent plan QA for https://github.com/HiQS-Labs/XYZ-forge/issues/1258 before any build. Base `e305cbf3` (development). The plan of record is the issue body, embedded verbatim in `PROJECT/1-INBOX/GH-1258-IDEA-SKILL.md` (read that file; it is in this tree). Scope under review is **Phase 1 only**: create `skills/1-hourly/idea/SKILL.md` (markdown only) and its `ARCHITECTURE.md` Skills Index row. Phases 2 and 3 are later PRs and are not under review.

Three operator decisions are already settled (the doc's `## Decisions` section): D1 name `idea`; D2 a filing-time consult is draft review only (footer `review: consult <run-id> models=<list>[, degraded] hash <sha>`, no approval marker); D3 the ledger row for #1258 is added at pickup (done in this tree: row `rmi-01M66S1Y01WM5BWJS9XCKBXRWG`, rated 80/55/50/65). Do not reopen them.

A prior Codex consult (2026-10-29, 18 findings, 17 accepted) already corrected the plan: capture doc embeds the body verbatim; rating via `releases roadmap rate`; `## Acceptance` as `- [ ]` items only; `artifacts_new` for new files; refuse on any nonzero preflight exit; `target.ref = development`; unfiltered delta re-recon. Grade the plan as it stands now, not that history.

Operational envelope: a markdown skill that composes existing writers. **No code under `utils/`, no new flags, no new scripts, no new tests or suites (AGENTS.md *No new tests*, GH-831), no schema or gate changes.** Commensurate complexity: this is a SKILL.md and one index row. Do not ask for machinery the plan's non-goals exclude; if the plan cannot work without one, say so as a Blocker with the concrete failing input.

Read the plan doc in full, plus the code it cites:
- `utils/hq/hq.sh:214-369` (`cmd_park`: preview/create, dedupe `:306-312`, `gh issue create` `:314`, `roadmap add` `:339`, `HQ_PARK_*` env `:217-250`) and `utils/hq/hq-lib.sh:423-515` (`hq_render_capture`), `:555-560` (`hq_roadmap_line`).
- `utils/py/releases_app.py` `roadmap rate` (`--help`; refuses an already-rated row without `--force`).
- `utils/py/swarm_preflight.py:101-147` (required contract fields), `utils/py/jog_run.py:1382` (probe types), `:1398` (heading regex), `:505-556` (acceptance extractor), `:1299-1379` (`--dry-run` fetch + detached worktree), `:1366-1373,1471-1472` (artifacts missing at target.ref → NOT-READY unless in `artifacts_new`).
- `skills/2-daily/file-xyz-bug/SKILL.md:25-123` (Step 1 harvest table the plan reuses by reference), `skills/2-daily/hq/SKILL.md`, `skills/1-hourly/start-task/SKILL.md` (Step 5 tier rule, Step 6), `skills/README.md` (tier contract, Skills Index row), `ARCHITECTURE.md:55-62` (row format).

Questions:
1. Write-set: is `skills/1-hourly/idea/SKILL.md` + one `ARCHITECTURE.md` row complete and minimal for Phase 1? Name any file the plan's own acceptance or the repo's skill contract requires that is missing, or any it names that is unnecessary. Cite file:line.
2. Operational sequence (plan step 1: harvest → tier → prior art → recon-lite → body → consult → hash → footer → preview → `hq park --create` → `roadmap rate` → read-back → `swarm-preflight --dry-run` → report): is every step executable as written against the cited code? In particular: (a) `hq park`'s dedupe and title handling with a long rendered body; (b) whether `roadmap rate` after `hq park` can be refused (does `hq_roadmap_line` ever carry a `rated` token?); (c) whether `swarm-preflight --dry-run` on a just-filed issue can reach READY when the capture doc is only local and uncommitted, or whether the plan must say what state the tree is in at that step; (d) which file the acceptance extractor reads (issue body vs capture doc) and whether the verbatim embed under `## Idea` keeps `## Acceptance` extractable.
3. Body contract: does the Preflight Contract stub as specified (`target.ref = development`, `gate`, ≥1 `fix_probes` unfixed at target.ref, `artifacts` + `artifacts_new` with `path_absent`) parse and classify READY under `swarm_preflight.py`/`jog_run.py` for a brand-new skill whose only artifact is a file that does not yet exist? Give the concrete probe that would make it STALE or AMBIGUOUS by mistake.
4. Acceptance: are the `## Acceptance` items falsifiable with their named red controls, given no new tests may be added? Any item that cannot be witnessed on an existing suite or a recorded manual check?
5. Rating 80/55/50/65 (pri/sev/appeal/effort-as-cheapness): grounded in the plan's Observed table? Appeal is 50 (operator did not set it).
6. Is anything in Phase 1 in tension with D1–D3 as settled, or with the GH-831 rail?

Use `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`, citing file:line; every `[Blocker]`/`[Should]` that asks for a behaviour change carries `Observed input:`, `Affected scope:` and `Falsifier:`. End your final block with exactly `VERDICT: PASS` (or `FAIL`) on its own line, followed by a non-empty `Basis:` line (GH-533). Set STATUS to Approved on PASS.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log

