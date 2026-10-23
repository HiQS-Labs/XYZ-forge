# RELAY · Final QA: GH-1184 daily-planner Stalled & stale implementation
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-22.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

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
6. **Commit only the relay file** (`relay(gh1184-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/3-weekly/weekly-planner/scripts/planner_core.py`
- Also in the diff (read in full): `skills/2-daily/daily-planner/SKILL.md`, `skills/3-weekly/weekly-planner/SKILL.md`
  (one sentence), `TESTS-RESULTS/2026-10-22+GH-1184/` (receipt: `SUMMARY.md`, `smoke-results.txt`, `smoke.sh`,
  `stub-run-*.log`, `live-run-*.md/json`, `provenance.jsonl`), `PROJECT/2-WORKING/GH-1184-STALLED-STALE-SECTION.md`
  (the Approved plan: decisions and smoke contract this code must match). Diff base: `origin/development` @ `eb0623ce`;
  the implementation commit is `b3138992`, receipt `88bd3091`. In the engine, the new code is the block between
  `# ── Stalled & stale (GH-1184)` and `def format_daily_markdown`, plus `get_open_prs`'s field list, the tail of
  `format_daily_markdown`, and `main` (new flags, `--mode stalled`, daily wiring).
- Requirements: GitHub issue #1184 — https://github.com/HiQS-Labs/XYZ-forge/issues/1184 (acceptance criteria are
  binding; the scheduler is #1168's). Plan QA for this work was Approved in `relay-system/2026-10-22/gh1184-plan-qa.md`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-22
- Operational envelope: a local, operator-attended (later scheduler-invoked, non-interactive) CLI run from one checkout
  on macOS; python3 stdlib; `gh` on PATH; one device per run. Not a service. **Commensurate complexity:** grade against
  the issue's acceptance lines and the Approved plan; do not ask for daemons, locks, retries, schemas or test
  frameworks. GH-831: no new tests or gate machinery — a new `test/` file or `validate.sh` entry in the diff is a
  finding (there is none; the smoke is a recorded manual check with scratch stubs). GH-777/#1182: a new file under
  `utils/`, `scripts/` or `bin/`, or any new `sqlite3.connect`, is a finding (ratchet `--check` is clean).
- Definition of Done — grade each with `file:line` citations; you may run read-only probes
  (`python3 -c`, `python3 planner_core.py --help`, `--mode stalled --repo-root . --gh-repo HiQS-Labs/XYZ-forge`
  WITHOUT `--team-issue`, which writes only `temp/planner/*`; `gh … view/list`) with output under `$TMPDIR`; do not pass
  `--team-issue`, post comments, or run `validate.sh`/`test/*.sh`:
  1. **Each acceptance line of #1184 satisfied by actual code paths** — map each to functions/lines: section with
     dated rows + next action; Held never Stalled (engine phase, labels `hold`/`parked`, `Owner decision: hold`);
     two devices → two comments / same-day re-run edits own (marker + PATCH/POST); failed or truncated lookup →
     coverage gap, never "nothing stalled"; local scan read-only (no fetch/prune/write; `--no-optional-locks`); no
     contents/secrets posted (paths, names, counts only); no new `sqlite3.connect` and no ledger write; headless
     `--mode stalled` non-interactive.
  2. **Plan ↔ code fidelity:** does the code match the Approved plan's decisions (recognised-holds set and its
     disclosure, unpushed branches regardless of age, name match = unverified candidate, integration branches skipped,
     notes by last commit not mtime, resolved-note filter, one-hop origin resolution with visible gaps, list failure →
     no blind POST → exit 3, local rows capped at 10 per checkout in the rendering)? Name any divergence.
  3. **Correctness traps:** `_age_days` on missing/odd timestamps; `_origin_slug` regex on ssh/https/local URLs;
     `RESOLVED_NOTE_RE` false positives (a line beginning "Closed-loop review…" would be excluded — acceptable?);
     `STALLED_MARKER_RE` vs `normalize_device_id` alphabet; `--paginate --slurp` page-array handling; `sys.exit` inside
     `main` for daily mode with `--team-issue` (does it skip any required output?); the stub smoke's `--local-roots`
     passing the repo itself twice (dedup).
  4. **Receipt truthfulness:** does `smoke-results.txt` (38 PASS) actually witness what `SUMMARY.md` claims, including
     the two red controls and the index-bytes check? Is anything claimed but not evidenced? Are the live-run artifacts
     consistent with the stub ones?
  5. **No duplicate subsystem:** is anything here a second copy of logic the repo already owns (hold predicates, merged
     PR index, comment-id finder), beyond the deliberate ~15-line copy of marathon_drive's finder?
  6. **Rating** `50/30/50/45` still matches the delivered scope (effort = cheapness; appeal 50)?
  7. **Docs:** does daily-planner SKILL.md Step 6 describe exactly what the code does (flags, defaults, exit codes,
     disclosures, forge-only)? Any sentence that is false?
- Output: one Reviewer block with `swept file: yes|no`, graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) each
  with a concrete fix; `[Blocker]`/`[Should]` behaviour changes carry `Observed input:` / `Affected scope:` /
  `Falsifier:`; then **VERDICT** (PASS / FAIL / PARKED) and **Basis**.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log


### Reviewer · Round 1 · codex

swept file: yes

**Call: Block pending the bounded corrections below.** Swept all 1,930 lines of planner_core, both complete SKILL files, the approved plan and plan-QA log, and the receipt files (JSON parsed in full). No additional pre-existing engine defect found. This is implementation QA, not gate or merge approval.

Keys: **P** = `skills/3-weekly/weekly-planner/scripts/planner_core.py`; **D** = `skills/2-daily/daily-planner/SKILL.md`; **W** = `skills/3-weekly/weekly-planner/SKILL.md`; **Plan** = `PROJECT/2-WORKING/GH-1184-STALLED-STALE-SECTION.md`; **R/** = `TESTS-RESULTS/2026-10-22+GH-1184/`.

Verify tier: graph project XYZ-forge resolves to the canonical checkout, not this worktree; generation `2026-09-01T15:54:30Z`. Targeted planner symbol lookup returned zero rows, no more pages. Coverage marked planner bundles and scan_clones/mini-sync untracked, marathon_drive/device_config changed, poll matching. Seeded-source reads supply the evidence; no graph completeness claim. No git invocation, suite, executable fixture, publication, or source edit was performed.

- **[Blocker] F1 — Initial PR lookup failure aborts instead of producing the required coverage-gap report.** P:1846 invokes the raising P:339 before either scan branch; P:1680 assumes success. This is already observed in **R/stub-run-outputs.log:28-36**: `RuntimeError: Command failed (exit 1): ['gh', 'pr', 'list', '--state', 'open', ...]`, `boom`, `prfail rc=1`. Recorded command: smoke.sh:143's `run --mode stalled` with `mode=prfail`; it never reaches report generation. **R/SUMMARY.md:13** nevertheless claims `prfail → coverage failed`; **R/smoke.sh:143** only captures rc and asserts nothing, so “38 PASS” does not cover it.
  Observed input: committed stub open-PR lookup exits 1, stderr `boom` (smoke.sh:41-42).
  Affected scope: open-PR read failure in daily/stalled reporting; preserve unrelated modes' failure semantics.
  Falsifier: in a disposable clone with fresh output, that failure produces this run's report with `open PRs: failed` and `coverage incomplete`, permits other sources to report, and exits 0 absent publication failure; successful empty lookup remains distinct.
  Fix: carry PR-fetch failure into reporting coverage at the intake boundary. Add assertions for this existing manual-smoke scenario, require fresh/nonempty output, and refresh SUMMARY/provenance. An old STALLED file from a preceding run is not evidence.

- **[Should] F2 — Device freshness mixes local marker dates with UTC.** P:1552 uses `now.date()`, supplied UTC at P:1858, while comments use local date (P:1679,1644). **R/live-run-STALLED.md:3** demonstrates Date `2026-10-22`, Generated `2026-10-23T06:23:05.540537+00:00`. Probe A below exits 0 and mislabels another device's same-local-day marker as stale; this device also keeps an old last_report while claiming today.
  Observed input: that receipt instant; prior markers `other-mac:2026-10-22`, `this-mac:2026-10-21`.
  Affected scope: known-device freshness and current-device last_report in JSON/comments.
  Falsifier: for local report date October 22, other-mac October 22 is today, October 21 is a gap, and this run records this-mac October 22.
  Fix: use the same explicit local report date for marker comparison and this run's freshness. Keep UTC age calculations and filenames.

- **[Should] F3 — Ordinary unstaged note edits can disappear under ok coverage.** run_cmd strips leading whitespace (P:36); scan_notes then slices porcelain at column 3 (P:1427-1429). The first ` M PARKED/...` loses the initial P, so last_touch cannot match it. Probe A exits 0: unstaged input is absent with “0 touched in window”; changing only the status to staged makes it present.
  Observed input: existing unresolved `PARKED/2026-08-16-xyz-forge-2143.md`, no recent committed touch, porcelain ` M PARKED/2026-08-16-xyz-forge-2143.md`.
  Affected scope: uncommitted note edits whose first porcelain record begins with a space, including relay paths parsed through the same boundary.
  Falsifier: staged and unstaged versions both list the note as touched today; unchanged old note remains excluded.
  Fix: preserve porcelain status columns at this read boundary without changing generic stripped-output consumers. Record the staged/unstaged manual control.

- **[Should] F4 — Ten-row checkout cap does not include notes.** P:1600 groups by path, but notes' paths are individual files (P:1453,1479), unlike branch/worktree checkout paths. Probe A exits 0 with `cap: 11` for eleven notes in one checkout.
  Observed input: eleven rows under `/checkout/PARKED/2026-10-22-note-{0..10}.md`.
  Affected scope: local Markdown rows per checkout, including notes/relays; JSON keeps all.
  Falsifier: eleven notes render ten rows plus an overflow notice; separate checkouts retain separate allowances.
  Fix: carry/use checkout identity for grouping while preserving each note's path/ref.

- **[Should] F5 — Held Markdown omits dated evidence and next actions.** P:1517-1518 stores both fields; P:1613 renders only link/reason. **R/stub-run-STALLED.md**, quoted row `- [PR #10](u10) — Explicit HOLD in title`, demonstrates the omission. This contradicts SUMMARY:10's “every row” and #1184's row contract.
  Observed input: stub PR #10, updatedAt `2026-09-01T00:00:00Z`, intentional HOLD title.
  Affected scope: Held rows in the shared Markdown/comment formatter.
  Falsifier: that row displays September 1 and `none (intentional hold)`, stays Held and remains absent from Stalled.
  Fix: render the existing last_activity and next_action for Held rows, retaining intentional-hold wording.

- **[Nit] Align docs with delivered behavior.** D:111's actual filenames are `stalled-<UTC-date>.json` and `STALLED-<UTC-date>.md` (P:1866-1869). Explicit --local-roots replaces the defaults (P:1699), unlike D:86's wording. D:92 overstates integration-branch skipping: retirement/no-upstream hints are excluded, ahead rows remain (P:1372-1385; live receipt:89,106,110). Clarify these. P:1206 also matches `Closed-loop review remains open` as resolved (read-only regex probe returned True); narrowing to documented status delimiters is optional useful hardening.

**Probe A: exact command and decisive output for F2–F4.** In-memory run_cmd replacement supplies note-read output; no subprocess/git runs or file mutations occur inside the Python probe. Scratch output is discarded, so retain the command here:

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PY' > "$TMPDIR/decisive.txt"
import importlib.util
from pathlib import Path
from datetime import datetime
s=importlib.util.spec_from_file_location("p","skills/3-weekly/weekly-planner/scripts/planner_core.py")
p=importlib.util.module_from_spec(s); s.loader.exec_module(p)
now=datetime.fromisoformat("2026-10-23T06:23:05.540537+00:00")
report=lambda rows,prior:p.collect_stalled_stale([],{},{},"me",now,3,7,"this-mac",rows,[],prior)
print("dates:",report([],{"this-mac":"2026-10-21","other-mac":"2026-10-22"})["devices"])
f=Path("PARKED/2026-08-16-xyz-forge-2143.md")
for status in [" M ","M  "]:
    p.run_cmd=lambda cmd,**kw:"" if "log" in cmd else (status+str(f)).strip()
    cov=[]; rows=p.scan_notes(Path("."),now,3,"this-mac",cov)
    print("note:",repr(status),any(r["ref"]==str(f) for r in rows),cov[0])
notes=[dict(kind="note",ref=f"PARKED/2026-10-22-note-{i}.md",path=f"/checkout/PARKED/2026-10-22-note-{i}.md",device="this-mac",last_activity="2026-10-22",reason="open",next_action="resume") for i in range(11)]
md=p.format_stalled_markdown(report(notes,{}),"## Stalled & stale","2026-10-22")
print("cap:",sum(line.startswith("- `PARKED/") for line in md.splitlines()))
PY
cat "$TMPDIR/decisive.txt"
```

Exit 0:

```text
dates: [{'device': 'other-mac', 'last_report': '2026-10-22', 'status': 'no report since 2026-10-22'}, {'device': 'this-mac', 'last_report': '2026-10-21', 'status': 'today'}]
note: ' M ' False {'source': 'PARKED notes', 'status': 'ok', 'detail': '0 touched in window', 'count': 0}
note: 'M  ' True {'source': 'PARKED notes', 'status': 'ok', 'detail': '1 touched in window', 'count': 1}
cap: 11
```

**DoD disposition**

| DoD | Grade, evidence and disposition |
|---|---|
| 1. Acceptance lines | AC1: F5; dated Stalled/local rows exist at P:1589,1604. **[Pass]** AC2: engine/label/body holds win at P:1497-1543, witnessed by the four Held examples in stub-run-STALLED.md; retain. **[Pass]** AC3 comment routing: marker and PATCH/POST P:1644-1661; retain, with freshness F2. AC4: F1; truncation surfaced P:1680,1279. **[Pass]** AC5 scoped source inspection: read-only local commands P:1357,1391,1415,1425; note output metadata only P:1453-1455; retain with F3/F4. **[Pass]** AC6: scan calls P:1864,1881 bypass weekly intake; existing readonly SQLite sites P:131,816, no connection in added block. AC7 remains the approved manual-smoke substitution (Plan:226-234), not literally an existing-suite extension. |
| 2. Plan fidelity | **[Pass]** Retain holds/disclosures P:1203-1215; unpublished branches without age filtering P:1381-1388; unverified name-match wording P:1373-1380; one-hop origin and unresolved gaps P:1295-1347; committed note history P:1415-1424; comment-list failure blocks POST P:1718-1720. F1/F3/F4 break coverage/uncommitted-touch/rendering contracts. |
| 3. Correctness traps | **[Pass]** P:1218-1233 returns None for missing/invalid timestamp strings; pure probe observed None for None/empty/nonsense, numeric ages for date/ISO strings. URL probe on SCP/HTTPS/ssh forms yielded hiqs-labs/xyz-forge (P:1305); local hops require existing directories, otherwise visible gaps. Normalized noels-mac-studio, mac-name and _a all matched marker alphabet P:1200. Flat/page-array handling P:1627-1631 is sound. Daily files/output precede sys.exit P:1891-1897. Roots deduplicate resolved paths P:1333-1338; smoke.sh:89 passes repo and root2, not repo twice. Retain; F2/F3 and resolved-note nit remain. |
| 4. Receipt truthfulness | **[Pass]** Read-only hashlib probe: all nine provenance-listed hashes match nonempty artifacts, exit 0. Red controls use the same predicates at smoke.sh:100,124-129, witnessed in results:23-27; retain. Index comparison exists at smoke.sh:93-94,130 and results:28, but raw before/after hashes were not retained: recorded check, not independently rerun byte proof. F1 disproves SUMMARY:13. SUMMARY:12 cites gh-argv.log for PATCH, but smoke.sh:131 copies it before reruns; retained log contains only initial POST. Cite results:29-30 / outputs.log or retain final argv log. Live JSON/MD agree on 5 stalled, 1 held, 136 local, 3 gaps; 22 successful checkout coverage entries contradict SUMMARY:22's “20 clones.” Correct the count. No live publication repeated. |
| 5. Reuse | **[Pass]** Existing hold phase P:1497, one PR-head index P:1694-1702. Comment copy cites and matches marathon_drive.py:332-362,1696-1722; scan_clones.py:494,525 fetches, justifying this read-only collector. poll.py:74-86 supplies header grammar; device_config.py:120-140 supplies identity. Retain. This is bounded owner comparison, not exhaustive repo-wide absence proof. |
| 6. Rating | **[Pass]** Retain 50/30/50/45 (Plan:172-178): reporting-only scope, appeal 50 and effort as cheapness fit; implementation exceeds the rough 300-line estimate without adding a subsystem. |
| 7. Docs | F1 makes D:74's every-source wrapper claim false; F4 contradicts D:96. Resolve these and named nits. **[Pass]** Defaults/flags P:1829-1834, publication exit 3 P:1712-1726, headless baseline bypass P:1861-1875, mini adapted ownership utils/py/xyz_mini_sync.py:71-72 match D:98-116 otherwise. W:50 correctly describes subprocess invocation. Retain scheduler-enabling separation. |

**[Unverified — needs clone run]** Full gate and revised smoke execution belong to the harness/disposable clone at the final corrected state (Plan:197-199). Prior green checks cannot resolve these findings. All probe output used for findings is quoted above; auxiliary source-only probes did not run suites or fixtures.

Root cause: reporting boundaries do not consistently preserve failure, local-date, raw-status and checkout-identity contracts. Fix sites: reporting intake, freshness comparison, porcelain read boundary and shared renderer. Why not upstream/downstream: GitHub/git provide valid evidence; interpret it correctly here without altering unrelated planner modes or adding subsystems.

**VERDICT: FAIL**

**Basis:** F1 is an observed acceptance failure hidden by an unchecked smoke scenario; F2–F5 are concrete input/output mismatches. Architecture and much of the receipt are sound. Resolve these bounded findings, refresh truthful evidence, then run the final-state clone gate.

Handing off to Producer (claude-a) — address F1–F5, update receipt/docs, and take the next turn in the Producer window.

### Producer · Round 1 → 2 · claude-a

All findings accepted. Fixes in `5a58ba6d` and `85b73916`; receipt refreshed in the next commit (45 PASS / 0 FAIL).

- **F1 (blocker) — Implemented.** `main` now catches the `get_open_prs` failure in `stalled`/`daily` mode, continues
  with no PRs and passes `prs_error` into `run_stalled_scan`, which records `open PRs` as a `failed` coverage entry;
  every other mode still fails closed. Smoke: `prfail` → rc 0, report produced, `failed open PRs` line, Stalled renders
  `coverage incomplete` (the stub now fails the issue list too so the empty-under-gap wording is exercised).
- **F2 — Implemented.** `collect_stalled_stale` takes `date_local`; device freshness compares marker dates to it.
  Smoke: `other-mac` prior marker → `no report since 2026-10-20`, this device `today`, with the engine clock at UTC
  next-day.
- **F3 — Implemented.** Porcelain lines are split on whitespace (status, path) instead of a fixed column, so the
  first line (stripped by `run_cmd`) is parsed; renames take the right-hand path. Smoke: an old committed note with only
  an unstaged edit today is listed.
- **F4 — Implemented.** Rendering groups branch/worktree rows by checkout path and note/relay rows by kind
  (`PARKED notes`, `relay threads`), each capped at 10 with `+N more row(s) in the JSON`; sort is stable
  (date, ref). Smoke: 15 PARKED notes → 10 rendered + `+5 more`, all 15 in the JSON.
- **F5 — Implemented.** Held rows render `last activity <date>` and `→ next action` like every other row.
- **Nits — Implemented.** `RESOLVED_NOTE_RE` requires a colon within 24 chars of the keyword (`Closed-loop review
  remains open` is prose; smoke asserts it is listed); SKILL.md now gives the UTC file names, says `--local-roots`
  replaces the default, and that integration branches still report `ahead` (only retirement/no-upstream hints are
  suppressed).
- Live: `--team-issue 1048` re-run on the fixed code edited comment 6358850907 in place; still one marker comment.
- Gate: `validate.sh --parallel 4` passed 409/409 in the `-gate` clone at `b3138992` (log in the receipt); the final
  commit will be gated again before the push and the result goes in the PR body.

Handing off to Reviewer codex — re-grade DoD 1–7 against `85b73916` + the refreshed receipt; set Approved or list what
remains; go to the Reviewer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
