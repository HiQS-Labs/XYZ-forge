# RELAY · GH-898 final QA delta — ratchet marker
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-01.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh898-final-qa-delta): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: The delta since your approval (final QA round 3, reviewed-head 2a5cac92): `git diff 2a5cac92..HEAD`. Code change is ONE line: utils/py/board_sync.py:148 gains the comment `# SQLITE-GATEWAY-OK: read-only rebalanceOS DB, not harness state (GH-898)`. Also: the plan's "Ratchet exception record" (PROJECT/2-WORKING/GH-898-BOARD-SYNC-ACTIVE-REPOS.md), CHANGELOG.md entry, evidence under TESTS-RESULTS/2026-09-30+GH-898/marker/ (provenance.jsonl, logs, red gate log) and SUMMARY.md. Prior QA: relay-system/2026-09-30/gh898-final-qa.md. Scanner under discussion: utils/pdda/check_inventory_ratchet.py (line 79 exemption; shrink-only logic; --update-baseline refusal).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-01
- Definition of Done: The marker line is the smallest correct way to satisfy the repo's SQLite ratchet for one justified read-only read of a foreign DB; no gate/baseline edit, no new module; evidence substantiates the claim; nothing else changed.

**Operational envelope:** local single-operator developer CLI; one-line code delta. Grade against commensurate complexity; do not ask for new suites, gate machinery or alternative architectures already weighed (new module + CANONICAL_GATEWAYS edit, subprocess into rebalanceOS, HQ, Flightdeck, `gh` listing, git-pulse files were rejected in the plan's exception record with recon). Per the measure-read-only rule you may run narrow non-mutating probes under .relay-scratch/ or $TMPDIR; you may NOT run validate.sh/test/*.sh/pytest. Behavior-change requests need Observed input / Affected scope / Falsifier.

**Questions (cite file:line):**
1. Does the marker at board_sync.py:148 exempt exactly the intended connect and nothing else? Is the OTHER sqlite3.connect in board_sync.py (baselined, ~:511) still counted, and can the exemption shield any other line (e.g. via the substring match at check_inventory_ratchet.py:79)?
2. Is the exemption legitimate and durable enough: is the marker a deliberate scanner feature (code evidence), what happens if it is later removed, and is that risk disclosed accurately in the plan's record?
3. Is the plan record's account of the red gate accurate — the 12 harness-discovery suites failing on base due to inherited XYZ_HARNESS, and gh777 failing because of this change — as substantiated by marker/provenance.jsonl and marker/gate-red-before-marker.log?
4. Is the CHANGELOG wording accurate and not overclaiming (the full pre-push gate has NOT yet passed on this commit; it is re-run once on the final commit)?
5. Is anything in the delta over-built or unrelated scope?

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
VERDICT: FAIL
Basis: the one-line exemption is correct and proportionate; one evidence-attribution correction remains. No source, scanner, baseline, module, suite or gate change requested. This review does not attest the pending full gate.

- [Pass] **F1 — exact exemption scope.** `utils/py/board_sync.py:148` opens the foreign DB with `mode=ro`, runs only SELECT (:143-150), and closes it (:151-152). `utils/pdda/check_inventory_ratchet.py:78-82` skips only the physical line containing the substring. The other connect (:511) remains counted, matching the baseline's one board_sync occurrence (baseline line number 437; scanner :119-121 permits shifts). Probe below: marked -> [511], removed -> [148, 511], live/baseline totals 32/32. A second connect on the marked physical line is also shielded; an adjacent line is not. This is a deliberate existing line-scoped feature, not a semantic guarantee for future edits. Retain the single-connect line; no scanner redesign requested.
- [Pass] **F2 — removal fails closed.** Scanner :79 explicitly implements the marker; :128-134 refuses baseline growth, :155-156 rejects increased count. Removing this marker alone therefore makes 32 become 33 and fails the ratchet. The plan's exception record (`PROJECT/2-WORKING/GH-898-BOARD-SYNC-ACTIVE-REPOS.md:98`) acknowledges loss of the exemption on a scanner rewrite and names option A as recovery. Existing opt-in/read-only behavior is unaffected by the comment.
- [Should] **F3 — substantiate or qualify the 12-suite control claim.** `marker/gate-red-before-marker.log:1352-1367` records exactly 13 failures and the refused push; :428 specifically records the ratchet's 32 -> 33 regression. However, `TESTS-RESULTS/2026-09-30+GH-898/marker/provenance.jsonl:1` asserts those other 12 fail on base 57bd97af and pass with XYZ_HARNESS unset, while lines 2-7 record only the matrix and five focused suites on ea460d22. No control commands, exit statuses or raw base/unset results are supplied. The same first receipt labels the clone “XYZ_HARNESS unset for suites” despite attributing this gate's failures to inheritance. The override diagnostics in the red log (:483, :495, :678) support that hypothesis, but do not establish the claimed controls. **Fix:** add the already-run base/unset control logs and corresponding provenance (commit, commands, environment, exit statuses and clone identity), and distinguish the inherited environment on the failed push from the unset focused runs. If those receipts are unavailable, qualify the base/unset statements in the plan :98, SUMMARY.md:17 and provenance :1 as an unverified diagnosis, with clone verification pending. No new tests requested. [Unverified — needs clone run] for the claimed base/unset controls until receipts exist.
- [Pass] **F4 — focused evidence and CHANGELOG scope.** `marker/suite-gh777-inventory-ratchet.log:1-4` reports clean live inventory and growth rejection; `marker/matrix-pass.log:36` says “RESULT: ALL PASS”; `marker/suite-gh605.log:12` reports 52 passed. Provenance :2-7 attributes focused checks to ea460d22. `CHANGELOG.md:5` claims the matrix/red control/existing suites, not a full green gate; `SUMMARY.md:17` explicitly leaves the full gate for the final commit. Preserve that distinction.
- [Pass] **F5 — proportionality and sweep.** The marker uses existing scanner machinery (:79), needs no module or baseline expansion, and the exception record :98 weighs the alternatives. Read the complete 1,575-line board_sync.py and complete scanner, plus the complete 102-line plan and the seeded delta evidence. No additional observed pre-existing runtime defect found in this sweep. Scope comparison against 2a5cac92 is limited to the supplied delta description: git was forbidden and no git command was run. The nearest listed graph is the canonical XYZ-forge project (generation 2026-09-01T15:54:30Z), not this relay worktree; coverage returned both code paths “not_tracked”, so all material code conclusions use current direct source.

Probe command (non-mutating to artifacts; text variants only under scratch), exit 0:
```python
# Invoked as: export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY'
import importlib.util, pathlib, tempfile, json
p=pathlib.Path('utils/pdda/check_inventory_ratchet.py')
spec=importlib.util.spec_from_file_location('ratchet',p)
m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
src=pathlib.Path('utils/py/board_sync.py').read_text()
marker='  # SQLITE-GATEWAY-OK: read-only rebalanceOS DB, not harness state (GH-898)'
with tempfile.TemporaryDirectory() as d:
    root=pathlib.Path(d); f=root/'utils/py/board_sync.py'; f.parent.mkdir(parents=True)
    for name,s in [('marked',src),('removed',src.replace(marker,'')),('same_line',src.replace(marker,'; sqlite3.connect("another.db")'+marker)),('next_line',src.replace(marker,marker+'\n        sqlite3.connect("another.db")'))]:
        f.write_text(s)
        print(name, m.scan_sqlite_bypasses(root))
baseline=json.loads(pathlib.Path('utils/pdda/inventory_ratchet_baseline.json').read_text())
print('baseline board entries', [s for s in baseline['sqlite_bypasses'] if s.startswith('utils/py/board_sync.py:')])
print('live total',len(m.scan_sqlite_bypasses(pathlib.Path.cwd())), 'baseline total',len(baseline['sqlite_bypasses']))
# PY
```
Decisive output:
```text
marked ['utils/py/board_sync.py:511']
removed ['utils/py/board_sync.py:148', 'utils/py/board_sync.py:511']
same_line ['utils/py/board_sync.py:511']
next_line ['utils/py/board_sync.py:149', 'utils/py/board_sync.py:512']
baseline board entries ['utils/py/board_sync.py:437']
live total 32 baseline total 32
```

No validate.sh, test/*.sh, pytest, executable fixture, git or artifact mutation performed. Handing off to Producer (claude-a) — correct or qualify F3, then open round 2; go to the Producer window and say 'take your turn'.

### Producer · Round 1 (claude-a)
- F3 — Accepted. The raw control logs existed in my scratchpad but were not committed. They are now under `marker/base-controls/`: per-suite logs for the 13 red-gate suites run alone on base 57bd97af with `XYZ_HARNESS` set (`xyz-harness-set/`, rc summary `run-set.rc.txt`: gh777 rc=0, the other 12 rc=1) and with `env -u XYZ_HARNESS` (`xyz-harness-unset/`, `run-unset.rc.txt`: all 12 rc=0). My first attempt (`timeout 500 bash …`, rc=127 for every suite because macOS has no `timeout`) is kept as `run-INVALID-timeout-rc127.txt` and marked INVALID. `provenance.jsonl` is rewritten with a per-row `env` field and commit, so the failed push (XYZ_HARNESS inherited) is distinguished from the unset focused runs (the old single `clone` label said "unset" for all rows).
- F1, F2, F4, F5 — Pass; no change. Noted: the exemption is line-scoped (a second connect on the marked physical line would also be shielded); the plan's record already names removal as recovery via option A. Single-connect line retained.

Requesting round 2.

### Reviewer · Round 2 · codex

swept file: yes
VERDICT: PASS
Basis: F3 is resolved by the newly supplied base controls and environment-specific provenance. The marker remains the smallest justified exception. Approval covers this delta review; it does not attest a green full gate on the final commit.

- [Pass] **F3 closed — evidence attribution now supported.** `TESTS-RESULTS/2026-09-30+GH-898/marker/base-controls/run-set.rc.txt:1-15` records base 57bd97af, gh777 rc=0, the other twelve rc=1, and unchanged HEAD/clean tree after; `run-unset.rc.txt:3-16` records the same base and twelve rc=0. Raw logs support the summaries: `xyz-harness-set/gh396-find-harness-roots.log:39` reports the override selecting the primary clone instead of the verify clone, :43 reports 40 pass/1 fail; `xyz-harness-unset/gh396-find-harness-roots.log:43` reports 41 pass/0 fail. All 25 per-suite logs are nonempty; each set non-ratchet log contains a failure, and each unset log ends with zero failures. `marker/provenance.jsonl:1,3-10` now distinguishes inherited versus unset environments, attributes controls to base, and labels the rc127 attempt INVALID. The inherited values printed at the beginning of run-unset are context, not evidence that the per-suite env -u was absent; provenance :9 explicitly records its removal. No further fix requested.
- [Pass] **F1/F2 retained — line-scoped exemption and fail-closed removal.** `utils/py/board_sync.py:143-152` still has one read-only connect on the marked physical line and closes it after SELECT. The other connect at :511 is unmarked. `utils/pdda/check_inventory_ratchet.py:78-82` skips a physical line by substring; thus a hypothetical second connect on that same line would also be shielded, while an adjacent line would not. The round-1 quoted probe remains the evidence for marked [511] versus removed [148,511], 32 versus 33. Scanner :128-134 refuses growth updates and :155-156 rejects count growth. `PROJECT/2-WORKING/GH-898-BOARD-SYNC-ACTIVE-REPOS.md:98` discloses scanner-rewrite risk and recovery. No scanner/baseline/module change needed.
- [Pass] **F4/F5 retained — accurate scope and limits.** `CHANGELOG.md:5` claims focused checks rather than a green full gate; `TESTS-RESULTS/2026-09-30+GH-898/SUMMARY.md:17` leaves the final full gate pending. The new receipts resolve the evidence gap without runtime machinery. Swept the complete board_sync.py and scanner, plan, summary, provenance and supplied control evidence; no additional observed pre-existing defect found. Graph coverage is not current-worktree evidence: canonical XYZ-forge generation 2026-09-01T15:54:30Z returned not_tracked for both code paths, so source conclusions use direct reads. Exact diff completeness remains limited to the seeded delta description because git is prohibited.

Read-only evidence probe: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 - <<'PY'` with pathlib reading each base-controls/xyz-harness-{set,unset}/*.log and regex `FAIL|[0-9]+ pass.*[0-9]+ fail|clean \(matches` to report byte size and final decisive lines; exit 0. Decisive output: set gh777 216 bytes, "inventory_ratchet: clean (matches baseline, 0 new scripts/connects)"; twelve other set logs contain FAIL; unset summaries are respectively find-harness 23/0, gh280 223/0, gh292 7/0, gh358 8/0, gh362 9/0, gh372 3/0, gh396 41/0, gh429 15/0, gh448 18/0, hq-locator 8/0, marathon-drive 162/0, xyz-vendor 98/0. This checks committed receipts; no suite was executed here.

Only this relay file edited. No git, validate.sh, test/*.sh, pytest or executable fixture run. Relay closed (Approved), no further turn needed; Producer/harness owns the pending final-commit full gate.


### Attestation · relay-drive — 2026-10-01T16:48:49Z
task: RELAY-gh898-final-qa-delta
reviewer: codex
status: Approved
reviewed-head: 27688df2fa8a6afdfc5905a1b76f53c9b3432276
added-range: 14650+3736
added-sha256: 61189ceb45a219202e52b06f0aaf9cfd01b7311c5a58ee024f549f4b02e6c21e
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
