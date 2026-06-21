# RELAY · PDDA design + implementation review
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (see Setup) **and** the last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup (READ the real files listed; cite `file:line`):
   - **Reviewer:** review vs the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete proposed fix → set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit the artifact; you only append findings to THIS relay file.
   - **Producer:** for every open finding log a disposition (Implemented / Modified / Declined + why), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line (`<!-- ↓↓↓ NEXT TURN ... -->`). Never edit earlier turns. Header it `### Round N · <Role> · <your-label> · <date time>`; a Reviewer block carries `**Verdict:**` + `**Findings & proposals:**` (graded bullets) + `**Commit:**`.
5. **Update the header:** flip `NEXT` to the other role; set `STATUS` (`Approved` closes the relay — Reviewer only; else leave `Open`).
6. **Commit only the files you touched** (this relay log): `git commit -m "relay(pdda-review): <your-label> r<N>"`, then put the short hash in your block's `Commit:` line. Do **not** push.
7. **Stop.** Tell the operator your one-line result.

## Setup
- Artifact under review — Noel's **PDDA (Project-Driven Doc Automation)** design + its first implementation. READ all of these:
  - **Design doc:** `PROJECT/PDDA.md` (the contract: lifecycle folders, required frontmatter, the exact two-column `## Status` table, QA-gate requirement, hardcoded-path ban, hourly schedule, output contract).
  - **Implementation (deterministic checks):** `utils/pdda-lib.sh` (shared helpers), `utils/pdda-run.sh` (aggregate runner), `utils/pdda-check-frontmatter.sh`, `utils/pdda-check-status-table.sh`, `utils/pdda-check-hardcoded-paths.sh`, `utils/pdda-stale-working-docs.sh`.
  - **Activity log sample:** `PROJECT/PDDA-ACTIVITY.jsonl` (the append-only artifact the scripts emit).
- Definition of Done: (a) **Design↔implementation fidelity** — each shipped script actually implements the "Minimum behavior" its section in `PDDA.md` specifies; (b) **script correctness/robustness** — bash hygiene (`set -euo pipefail`/quoting), and the tricky cases: exact `## Status` header matching incl. the alias compatibility window (ends `2026-07-31`), hardcoded-path detection without false-positives on quoted/transcript blocks, stale-doc move (4-day, dry-run/`pdda_hold` override), empty/edge inputs; (c) **gaps** — call out anything specified in `PDDA.md` but NOT implemented (e.g. the LLM `pdda-doc-ready.sh` layer, the activity-log fields, JSON-lines output contract, non-zero exit on blocking); (d) **design-doc quality** — internal contradictions, unresolved open questions that block automation, anything that would let plan rot through.
- Producer: Noel (human author of PDDA) — represented here by the orchestrator   ·   Reviewer: **agy (Antigravity CLI)**
- Handoff: cli-driven (agy)   <!-- driven by relay-automation/relay-drive.sh + agy-turn.sh -->
- Started: 2026-06-20

## Ground rules
1. This file is the single source of truth. The agents are different tools (Claude and agy) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`/`STATUS` at the top.
4. Stay tight. Findings are graded bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings with concrete suggested fixes; it appends them to THIS file only.
6. Grade every finding: `[Blocker]` must fix · `[Should]` strong rec · `[Nit]` optional · `[Pass]` checked + sound.
7. The Reviewer posts a Verdict. Relay ends on **Approved**; else the orchestrator carries the findings back to Noel.
8. End your turn by committing it: `relay(pdda-review): <role> r<N>`. No push.
9. **One actor at a time.** The `PDDA-TURN` tick token is the lock.
10. **Evidence:** the scripts ARE runnable — prefer `behaviorally proven` (you ran a script against a fixture) over `textual only` where you can; otherwise say `textual only`.

## Roles
- **Producer** — Noel (author of the PDDA design + scripts).
- **Reviewer** — agy. Reviews against the DoD, proposes graded findings, sets a verdict. Never edits the artifact.

---
## Log

### Round 1 · Producer · noel (via orchestrator) · 2026-06-20 21:40 PDT
**Did:** Drafted the PDDA design doc (`PROJECT/PDDA.md`) and a first cut of the deterministic hygiene layer under `utils/`: `pdda-lib.sh` (shared helpers), `pdda-run.sh` (aggregate runner), and the four checks — `pdda-check-frontmatter.sh`, `pdda-check-status-table.sh`, `pdda-check-hardcoded-paths.sh`, `pdda-stale-working-docs.sh`. Activity is logged to `PROJECT/PDDA-ACTIVITY.jsonl`.
**Review this:** Does the implementation faithfully deliver what `PDDA.md` promises, and is each script correct and robust? Specifically: (1) does the status-table check enforce the EXACT headers + the alias window correctly? (2) is the hardcoded-path check resistant to false-positives on quoted/transcript blocks? (3) does the stale-doc mover honor a dry-run + `pdda_hold` override, and is the 4-day cutoff right? (4) is the JSON-lines/output + non-zero-exit contract from `PDDA.md` actually implemented? (5) what's specified but NOT yet built (e.g. the LLM `pdda-doc-ready.sh` layer)? (6) any design-doc contradictions or open questions that block reliable automation?
**Verification:** N/A from the producer side this round — this is a review request; the reviewer should run the scripts where feasible.
**Open questions:** The 4 "Open questions" at the bottom of `PDDA.md` (gh_issue requiredness, compat-window length, activity-log rotation, project-local roadmap) — flag which ones actually block a stable v1.
**Commit:** (artifact files are Noel's working tree, uncommitted by design — review them on disk)

### Round 1 · Reviewer · agy · 2026-06-20 21:45 PDT

**Verdict:** Changes requested

**Findings & proposals:**
- `[Blocker]` **Missing `pdda-doc-ready.sh` (LLM readiness check):** `PROJECT/PDDA.md` specifies the LLM-assisted readiness review script `pdda-doc-ready.sh` under "2. LLM-assisted doc readiness review" and in the hourly schedule, but no such script has been implemented in the codebase.
- `[Should]` **Quoted date values break frontmatter check:** In [pdda-check-frontmatter.sh](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/pdda-check-frontmatter.sh#L36), strict regex `^[0-9]{4}-[0-9]{2}-[0-9]{2}$` fails if dates are wrapped in quotes in the frontmatter (e.g., `created: "2026-06-15"`), causing false positive validation errors. Strip quotes before performing the regex check.
- `[Should]` **Loose header regex:** In [pdda-check-status-table.sh](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/pdda-check-status-table.sh#L18), the status heading matcher `^##[[:space:]]+Status([[:space:]].*)?$` is too loose and permits headings like `## Status At A Glance` instead of enforcing the exact `## Status` specified in `PDDA.md`.
- `[Should]` **Output format contract implementation gap:** `PDDA.md` specifies that each check script should emit a machine-readable JSON lines format for composability. The current scripts print human-readable text to stdout and append JSON lines to the activity log, but do not directly output JSON lines to stdout.
- `[Nit]` **Unused local variable `cells`:** In [pdda-lib.sh](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/pdda-lib.sh#L167), `local cells` is declared inside `pdda_normalize_header` but never used.
- `[Nit]` **Dry-run action naming discrepancy:** In [pdda-stale-working-docs.sh](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/pdda-stale-working-docs.sh#L54), the dry-run action is logged as `would-move` instead of the recommended `flagged` name suggested in `PDDA.md`.
- `[Nit]` **Frontmatter leading whitespace parsing risk:** [pdda-lib.sh](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/pdda-lib.sh#L117) and [pdda-lib.sh](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/pdda-lib.sh#L125) enforce `NR == 1 && $0 == "---"`, which fails if files contain leading blank lines or a BOM.
- `[Pass]` **Good platform compatibility:** [pdda-lib.sh](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/pdda-lib.sh#L173) correctly handles BSD (`stat -f`) versus GNU (`stat -c`) parameters for extracting file mtimes, ensuring compatibility on both macOS and Linux.

**Open Questions Recommendations:**
1. *gh_issue:* Keep optional to minimize intake friction for local/non-GitHub tasks.
2. *compat deadline:* Keep 2026-07-31 to provide a reasonable manual cleanup window.
3. *log rotation:* Implement rotation by size or date (e.g. keeping only the last 10,000 entries) to prevent `PDDA-ACTIVITY.jsonl` from growing indefinitely.
4. *roadmap:* Keep `ROADMAP.md` at root-level only to prevent duplication and plan rot.

**Commit:** pending (harness-managed)

### Round 2 · Producer · claude-a (applying on Noel's behalf) · 2026-06-20 22:16 PDT
**Decisions on proposals:** (each verified against the source first; fixes applied to the `utils/pdda-*.sh` files on disk — Noel's working tree, uncommitted by design — so re-review them ON DISK)
- [Blocker] Missing `pdda-doc-ready.sh` — **Implemented.** Created `utils/pdda-doc-ready.sh`: the LLM readiness layer from `PDDA.md`. OPT-IN via `PDDA_LLM_BIN` (+`PDDA_LLM_ARGS`); unset/not-on-PATH → graceful skip (advisory info, exit 0) so the deterministic hourly run never breaks. Rubric flags only readiness gaps (QA-gate-after-phase, actions-without-criteria, stale-vs-body, buried-next-action, duplication, contradictory-status), does NOT re-lint frontmatter/status/paths, does NOT rewrite. Parses model JSON-line output via node; advisory findings (warn/info). Wired into `pdda-run.sh` as step 5 (after deterministic hygiene). · Proof: `bash utils/pdda-doc-ready.sh` with no `PDDA_LLM_BIN` → `skip`, exit 0; runner runs it as step 5.
- [Should] Quoted dates break the frontmatter check — **Implemented** @ `utils/pdda-check-frontmatter.sh`: trim + strip surrounding `"`/`'` before the `YYYY-MM-DD` regex. · Proof: fixture `created: "2026-06-15"` → errors=0 (was a false error before).
- [Should] Loose `## Status` header — **Implemented** @ `utils/pdda-check-status-table.sh`: `^##[[:space:]]+Status([[:space:]].*)?$` → `^##[[:space:]]+Status[[:space:]]*$`. · Proof: `## Status At A Glance` → now `missing usable '## Status' table` (error); exact `## Status` still passes.
- [Should] No JSON-lines on stdout — **Implemented** @ `utils/pdda-lib.sh`: new `PDDA_FORMAT` (`text` default | `json`). `json` emits one JSON object per finding/summary on stdout (same shape as the activity log) via the new `pdda_json_line` helper; the log append is unchanged. · Proof: `PDDA_FORMAT=json` → JSON lines on stdout.
- [Nit] Unused `cells` in `pdda_normalize_header` (pdda-lib.sh:167) — **Declined (false finding).** Verified: `pdda_normalize_header` has NO `cells` var; the `local cells` at `pdda-lib.sh:153` is in `pdda_table_cells` and IS used (lines 155-159). Nothing to remove.
- [Nit] dry-run logs `would-move` — **Implemented** @ `utils/pdda-stale-working-docs.sh`: action → `flagged` (matches the doc's moved/flagged/skipped vocabulary). · Proof: dry-run activity log shows `"action":"flagged"`, doc not moved.
- [Nit] frontmatter `NR==1 && $0=="---"` breaks on BOM/leading blank — **Implemented** @ `utils/pdda-lib.sh` (`pdda_frontmatter_lines` + `pdda_has_frontmatter`): strip a UTF-8 BOM (octal `\357\273\277`) and skip leading blank lines before `---`. · Proof: BOM+leading-blank fixture parses, errors=0.
- [Open-Q rec] activity-log rotation — **Implemented**: `pdda_rotate_activity` + `PDDA_ACTIVITY_MAX_LINES` (default 10000), called once at the end of `pdda-run.sh`. The other three open-Qs (gh_issue requiredness, compat-window length, project-local roadmap) are policy calls left to Noel.
**Did:** All 6 actioned findings + log rotation, applied to the 6 scripts + 1 new script. Did NOT touch `PROJECT/PDDA.md` (Noel's doc, the spec — the scripts now conform to it).
**Verification:** behaviorally proven against TEMP fixtures only (never the real `PROJECT/2-WORKING`, so no docs were moved): `bash -n` clean on all 7 scripts; quoted-date / tight-header / BOM / JSON-mode / flagged-action / doc-ready-skip all asserted; full `pdda-run.sh` (dry-run) → "all checks passed", exit 0.
**Re-review this:** (1) `utils/pdda-doc-ready.sh` — is the opt-in/graceful-skip + JSON-line parsing sound, and does it honor the design's "do not rewrite / do not re-lint" constraints? (2) the tightened header + quoted-date + BOM fixes — any new false-positive/negative? (3) the `PDDA_FORMAT=json` shape. (4) Was declining the `cells` nit correct?
**Commit:** none for the artifact (Noel's uncommitted scripts — review on disk); this relay turn commits only the log.

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
