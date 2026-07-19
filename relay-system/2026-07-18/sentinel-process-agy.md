# RELAY · Collector sentinel process review — agy desktop tail, service-reset authority, diagnostic sufficiency
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-18.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(sentinel-process-agy): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: `PROJECT/2-WORKING/AGY-SENTINEL.md` (the **process**, not the prose)
- Target repo (`--target-root`): a `rebalance-OS` worktree on branch `work/sentinel-process-review`
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-18
- Definition of Done: each of Q1/Q2/Q3 below answered with a graded finding carrying a
  `file:line` or quoted-span citation.

## Review brief — what this review is for

`AGY-SENTINEL.md` proposes a timed loop that runs `rebalance doctor`, classifies findings,
files/captures/parks real defects on the PDDA rails, repairs one at a time on a `sentinel/*`
branch off `development`, and **stops at a PR**. It is intended to run as a recurring
**Antigravity (agy desktop)** scheduled task. Review it *as the system that would execute
the tail end of it*.

**Q1 — Service-reset authority.** The loop has no authority to restart anything today. The
operator's standing practice is that `launchctl kickstart -k` on `com.rebalance-os.pulse-server`
(and affected `com.rebalance-os.*` jobs) is an accepted remedy after code/env changes. Should
the sentinel be empowered to reset the rebalance web server / launchd jobs as a *remedy*? If
so, where does that authority sit relative to the §6 brakes and the "stops at a PR, operator
decides" boundary (GUIDING-PRINCIPLES Principle 7)? Note the asymmetry: a service restart is
**reversible and non-code**, unlike a merge. Is "restart allowed, merge not" a coherent line
or does it leak? Address specifically whether restarting a service the sentinel also
*monitors* creates a feedback loop that masks the defect it should report — a restart that
clears a symptom also destroys the evidence and resets the "two consecutive failures" counter
§2 depends on.

**Q2 — Diagnostic sufficiency for a flywheel.** For this to run unattended rather than
operator-supervised, what diagnostics are missing? Ground truth verified this session:
- `rebalance doctor` returns a structured `DoctorReport` (`src/rebalance/doctor.py:9`); the CLI
  renders it. Whether a machine-readable emission path is exposed to an external scheduler is
  **unverified — check it.**
- Structured diagnostics that do exist: `temp/logs/auth_activity.jsonl` (`doctor.py:807`),
  `temp/health-reporter.log.jsonl` (`doctor.py:931`), per-device pulse health YAML
  (`doctor.py:852`).
- There appears to be **no health-history table** in the store — `rg "CREATE TABLE"` over
  `src/rebalance/` surfaces no health/check/doctor-run table. If true, the §2 rule "require two
  consecutive failures before treating it as real" has **no persistent substrate to answer
  from**, and the whole classification step is running on whatever a single invocation can see.
  **Confirm or refute — this is the most important claim in this brief.**

**Q3 — Are diagnostics siloed enough for easy retrieval?** Observed fragmentation: most
launchd jobs log to `temp/logs/*.log` under the repo, but `obsidian-daily-sync` and
`obsidian-rollover` log to `~/Library/Logs/rebalance-os/*.log` — two roots, no index, mixed
formats (free-text `.log` vs structured `.jsonl`). Could an unattended agent retrieve "what
happened to collector X in the last 48h" without a human pointing it at a path? State the
minimum viable diagnostic contract.

Ground every answer in the repo and cite files. **If a claim above is wrong, say so** — that is
the most useful thing you can do here.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Review (agy) — 2026-07-18

**Q1 — Service-reset authority**
- **[Blocker]** Empowering the sentinel to reset `com.rebalance-os.pulse-server` violates Principle 7 ("stops at a PR, operator decides") because it modifies live runtime state without operator consent. Furthermore, restarting a service clears the symptom, destroying the evidence and resetting the "two consecutive failures" state the §2 rule depends on.
- **Fix:** The sentinel must strictly act as an observer and must not reset launchd services. Leave service kicks to the operator after merging.

**Q2 — Diagnostic sufficiency for a flywheel**
- **[Blocker]** `rebalance doctor` lacks a machine-readable emission path. `src/rebalance/cli/__init__.py:114-164` (`doctor_cmd`) prints directly to stdout via `rich.console.Console` and has no `--json` flag.
- **Fix:** Add a `--json` flag to `rebalance doctor` that dumps the `DoctorReport` structure.
- **[Blocker]** Confirmed: there is no health-history table. `src/rebalance/ingest/db/schema.py` contains no table for doctor runs or health checks. The "two consecutive failures" rule in `AGY-SENTINEL.md` §2 cannot be tracked via the store.
- **Fix:** Ensure the `.sentinel-state.json` file (mentioned in Phase 1) robustly tracks finding occurrences across runs to answer §2, or introduce a `health_history` table to the DB.

**Q3 — Are diagnostics siloed enough for easy retrieval?**
- **[Blocker]** Diagnostics are too fragmented (split across `temp/logs/` and `~/Library/Logs/rebalance-os/` with mixed formats). An unattended agent cannot reliably pull "what happened to collector X" without hardcoded paths.
- **Fix:** The minimum viable diagnostic contract requires a `rebalance logs <collector>` CLI command that abstracts the file locations and format, returning the last 48h of history. Alternatively, unify all logs into a single directory and format (e.g., JSONL).

**Verdict:** Changes requested.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
