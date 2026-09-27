# RELAY · PR #867 review — GH-745 into staging/stabilize-2026-10 (#854 window)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-27.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(pr-867-review-gh-745-into-staging-stabilize-2026-10-854-window): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the diff from origin/staging/stabilize-2026-10 to HEAD on this branch (PR #867, GH-745). Key files: `utils/py/wave_reconcile.py`, `test/gh421-auto-wave-reconcile.sh`, `test/gh424-roadmap-status-marker.sh`, `test/gh425-gate-provenance-pr.sh`, `test/wave-reconcile.sh`, `CHANGELOG.md`, `TESTS-RESULTS/2026-09-27+GH-745/SUMMARY.md`. Read in place; do NOT edit.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-27
- Definition of Done: see *Review packet*. One round (operator: minimum ceremony). PASS means safe to squash-merge into the staging branch.

## Review packet

**The question:** is PR #867 (GH-745) correct, and safe to squash-merge into `staging/stabilize-2026-10`? Read issue GH-745's intent from `TESTS-RESULTS/*+GH-745/SUMMARY.md`. You cannot run git, so the PR's exact scope and code patch are embedded below; they were taken at the PR head before this thread was added.

**Scope** (`git diff --name-status origin/staging/stabilize-2026-10...HEAD`):
```
M	CHANGELOG.md
A	TESTS-RESULTS/2026-09-27+GH-745/SUMMARY.md
A	TESTS-RESULTS/2026-09-27+GH-745/base-collision.txt
A	TESTS-RESULTS/2026-09-27+GH-745/base-gh421-auto-wave-reconcile.log
A	TESTS-RESULTS/2026-09-27+GH-745/base-gh424-roadmap-status-marker.log
A	TESTS-RESULTS/2026-09-27+GH-745/base-gh425-gate-provenance-pr.log
A	TESTS-RESULTS/2026-09-27+GH-745/base-leak.txt
A	TESTS-RESULTS/2026-09-27+GH-745/collision-witness.py.txt
A	TESTS-RESULTS/2026-09-27+GH-745/head-collision.txt
A	TESTS-RESULTS/2026-09-27+GH-745/head1-gh421-auto-wave-reconcile.log
A	TESTS-RESULTS/2026-09-27+GH-745/head1-gh424-roadmap-status-marker.log
A	TESTS-RESULTS/2026-09-27+GH-745/head1-gh425-gate-provenance-pr.log
A	TESTS-RESULTS/2026-09-27+GH-745/head1-leak.txt
A	TESTS-RESULTS/2026-09-27+GH-745/head1-wave-reconcile.log
A	TESTS-RESULTS/2026-09-27+GH-745/head2-gh421-auto-wave-reconcile.log
A	TESTS-RESULTS/2026-09-27+GH-745/head2-gh424-roadmap-status-marker.log
A	TESTS-RESULTS/2026-09-27+GH-745/head2-gh425-gate-provenance-pr.log
A	TESTS-RESULTS/2026-09-27+GH-745/head2-leak.txt
A	TESTS-RESULTS/2026-09-27+GH-745/head2-wave-reconcile.log
A	TESTS-RESULTS/2026-09-27+GH-745/head3-gh421-auto-wave-reconcile.log
A	TESTS-RESULTS/2026-09-27+GH-745/head3-gh424-roadmap-status-marker.log
A	TESTS-RESULTS/2026-09-27+GH-745/head3-gh425-gate-provenance-pr.log
A	TESTS-RESULTS/2026-09-27+GH-745/head3-leak.txt
A	TESTS-RESULTS/2026-09-27+GH-745/head3-wave-reconcile.log
A	TESTS-RESULTS/2026-09-27+GH-745/head4-gh421-auto-wave-reconcile.log
A	TESTS-RESULTS/2026-09-27+GH-745/head4-gh424-roadmap-status-marker.log
A	TESTS-RESULTS/2026-09-27+GH-745/head4-gh425-gate-provenance-pr.log
A	TESTS-RESULTS/2026-09-27+GH-745/head4-leak.txt
A	TESTS-RESULTS/2026-09-27+GH-745/head4-wave-reconcile.log
A	TESTS-RESULTS/2026-09-27+GH-745/head5-gh421-auto-wave-reconcile.log
A	TESTS-RESULTS/2026-09-27+GH-745/head5-gh424-roadmap-status-marker.log
A	TESTS-RESULTS/2026-09-27+GH-745/head5-gh425-gate-provenance-pr.log
A	TESTS-RESULTS/2026-09-27+GH-745/head5-leak.txt
A	TESTS-RESULTS/2026-09-27+GH-745/head5-wave-reconcile.log
A	TESTS-RESULTS/2026-09-27+GH-745/leak-witness.sh.txt
A	TESTS-RESULTS/2026-09-27+GH-745/provenance.jsonl
A	TESTS-RESULTS/2026-09-27+GH-745/route.txt
M	test/gh421-auto-wave-reconcile.sh
M	test/gh424-roadmap-status-marker.sh
M	test/gh425-gate-provenance-pr.sh
M	utils/py/wave_reconcile.py
```

**Code patch** (everything except `TESTS-RESULTS/` and `relay-system/`):
```diff
diff --git a/CHANGELOG.md b/CHANGELOG.md
index dd63e8bb..762405c3 100644
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -1,5 +1,14 @@
 # Changelog
 
+## 2026-09-27 — rollback events no longer poison `.tick/events`, and tests keep them out of the real clone (GH-745)
+
+`wave_reconcile`'s rollback event was appended to a timestamp-named file. Two rollbacks in the same instant wrote two records into one file, and `tick claims` then failed `events-unreadable` for the whole clone, which made merge-cleanup preserve it forever. Each event is now its own file: the name carries the pid and 8 random hex characters, and the file is created exclusively. Three suites (`gh424`, `gh425`, `gh421`) built the journal with no root and wrote events into the real clone. They now use their fixture root.
+
+Evidence is in `TESTS-RESULTS/2026-09-27+GH-745/`:
+- **Leak witness:** 3 events leaked into the real clone at base, 0 at head (5 of 5 runs).
+- **Same-instant witness:** `tick claims` exits 3 at base and 0 at head.
+- **`wave-reconcile.sh`:** 23 of 23, 5 of 5 runs.
+
 ## 2026-09-27 — gh620 names a failed fixture git call instead of crashing later (GH-830)
 
 `test/gh620-skills-army-mini-sync.sh` ignored the exit code of about 30 fixture git calls and dropped their stderr. So a failed `seed-owner` clone on the hosted gate (run 36194249895) surfaced as an unrelated `FileNotFoundError`, and cost one full hosted qualification. `git()` now stops the suite with the failing command and git's stderr. There are no retries, and no assertion changed. The red control, with the fixture clone pointed at a missing repo, now names the clone. The normal run passes 5 of 5 (28/28). Evidence is in `TESTS-RESULTS/2026-09-27+GH-830/`.
diff --git a/test/gh421-auto-wave-reconcile.sh b/test/gh421-auto-wave-reconcile.sh
index 0d7fe01c..76b8898b 100755
--- a/test/gh421-auto-wave-reconcile.sh
+++ b/test/gh421-auto-wave-reconcile.sh
@@ -366,7 +366,7 @@ class ReconcileTests(unittest.TestCase):
         legacy.mkdir()
         (legacy / 'releases.db').touch()
         (legacy / 'ROADMAP.md').write_text('### In progress\n- **GH-421** — fixture\n### Completed\n')
-        journal = wave.RollbackJournal()
+        journal = wave.RollbackJournal(legacy)  # GH-745: never the real clone's .tick/events
         self.addCleanup(journal.cleanup)
         wave.update_roadmap_entry(str(legacy), 421, 42, '2026-09-08', journal=journal)
         self.assertIn('### Completed\n- **GH-421** ✅ **SHIPPED', (legacy / 'ROADMAP.md').read_text())
diff --git a/test/gh424-roadmap-status-marker.sh b/test/gh424-roadmap-status-marker.sh
index 0236b521..fed3d109 100644
--- a/test/gh424-roadmap-status-marker.sh
+++ b/test/gh424-roadmap-status-marker.sh
@@ -137,7 +137,7 @@ class MarkerTests(unittest.TestCase):
                 (self.root / name).unlink()
         before = self.snapshot() if not absent else {
             n: (self.root / n).read_bytes() if (self.root / n).exists() else None for n in artifacts}
-        journal = wave.RollbackJournal()
+        journal = wave.RollbackJournal(self.root)  # GH-745: never the real clone's .tick/events
         self.addCleanup(journal.cleanup)
         calls = []
 
diff --git a/test/gh425-gate-provenance-pr.sh b/test/gh425-gate-provenance-pr.sh
index e37fa1aa..d70ebe79 100644
--- a/test/gh425-gate-provenance-pr.sh
+++ b/test/gh425-gate-provenance-pr.sh
@@ -330,7 +330,7 @@ FIXTURE
         self.git('commit', '-m', 'qualification fixture')
         self.sha = self.git('rev-parse', 'HEAD').strip()
         self.meta = dict(META, mergeCommit={'oid': self.sha})
-        self.journal = wave.RollbackJournal()
+        self.journal = wave.RollbackJournal(self.root)  # GH-745: never the real clone's .tick/events
         self.addCleanup(self.journal.cleanup)
 
     def git(self, *args):
diff --git a/utils/py/wave_reconcile.py b/utils/py/wave_reconcile.py
index 300488c9..d360c16c 100755
--- a/utils/py/wave_reconcile.py
+++ b/utils/py/wave_reconcile.py
@@ -184,10 +184,14 @@ class RollbackJournal:
                 now = datetime.now(timezone.utc)
                 ts = now.isoformat(timespec="milliseconds").replace("+00:00", "Z")
                 filename_ts = ts.replace(":", "-")
+                # GH-745: tick parses each event file as ONE record. A timestamp-only
+                # name plus append mode put two rollbacks in one file and made the whole
+                # log unreadable. One record per file: a unique name, created exclusively.
                 evt = os.path.join(
-                    events_dir, f"{filename_ts}-wave-reconcile-rollback.jsonl"
+                    events_dir,
+                    f"{filename_ts}-{os.getpid()}-{os.urandom(4).hex()}-wave-reconcile-rollback.jsonl",
                 )
-                with open(evt, "a", encoding="utf-8") as fh:
+                with open(evt, "x", encoding="utf-8") as fh:
                     fh.write(json.dumps({
                         "schema_version": "0.2.0",
                         "ts": ts,
```

**Definition of Done (PASS when all hold):**
- (a) **The fix addresses the stated root cause** at the cited lines. It is minimal: no unrelated edits, and no weakened or deleted assertion that hides a failure.
- (b) **The evidence is real.** A red control at base fails for the stated reason, and the edited suite is green 5 of 5 at head. The logs in `TESTS-RESULTS/*+GH-745/` exist, are non-empty, and match `provenance.jsonl`.
- (c) **#854 per-PR rule.** No `releases.db`, `releases.sql` or `LEADERBOARD.md` change, no `PROJECT/` change, no new test file, and no new registry entry in `validate.sh` (AGENTS.md *No new tests*). Scope is CI or core-harness files only.
- (d) **The CHANGELOG entry is truthful.**

**Operating envelope.** A single-operator developer tool. Grade against these checks and commensurate complexity. Do not ask for new tests, new infrastructure or multi-tenant threat models.

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

VERDICT: PASS
Basis: The supplied PR scope meets (a)–(d); approve the squash into `staging/stabilize-2026-10` under the stated #854 window contract. This is a source/evidence review, not a new suite run or development/promotion qualification.

- [Pass] Root cause: `utils/py/wave_reconcile.py:187–204` adds pid/random uniqueness and exclusive creation while retaining the envelope and best-effort exception boundary. `src/events.js:209–210` parses the entire file with `JSON.parse(raw)`, so preventing a second appended object addresses the recorded failure directly. `base-collision.txt` says `records per file: [2]` and `tick claims rc: 3`; `head-collision.txt` says `[1, 1]` and `tick claims rc: 0` (both under `TESTS-RESULTS/2026-09-27+GH-745/`). No fix requested.
- [Pass] Fixture containment: the three changed constructors explicitly receive the private fixture at `test/gh421-auto-wave-reconcile.sh:369`, `test/gh424-roadmap-status-marker.sh:140`, and `test/gh425-gate-provenance-pr.sh:333`; production already supplies its target at `utils/py/wave_reconcile.py:2067`. The supplied patch removes or weakens no assertion. Swept the complete reconciler and all three edited suites, plus `test/wave-reconcile.sh`; no additional pre-existing defect established in that sweep. No fix requested.
- [Pass] Retained evidence matches the claims: `base-leak.txt` records `rollback events written into the real clone: 3`; head leak logs 1–5 record zero. All three suite logs end in `OK` on every head run (36/6/23 unittest cases), and every head wave log records `23 passed, 0 failed`. The 13 rows in `provenance.jsonl` identify their logs and disclose the rebased-code attribution. The read-only audit below exited **0**, output: `36 non-empty artifacts; 13 resolved receipts; 5/5 runs: three suites OK, leak=0, wave=23/23`. No fix requested.
- [Pass] Scope and reporting: the packet's complete name-status list contains only the four implementation/suite edits, CHANGELOG, and retained GH-745 evidence; no ledger, PROJECT, new suite, or registry change. `CHANGELOG.md:3–11` matches the recorded collision, leak counts, and five wave results. `SUMMARY.md` explicitly places the tier-3 obligation at the #854 window landing; `route.txt` reports `tier=3`. No fix requested.
- [Unverified — needs clone run] No tests, executable witnesses, or gate were run in this worktree. The post-turn harness gate remains required. Exact Git ancestry/rebase identity was not independently queried because this turn prohibits Git; scope and rebase attribution are those supplied in the packet and provenance.

Evidence-audit command (read-only; exit 0; output quoted above):
```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY_AUDIT'
from pathlib import Path
import json,re
p=Path('TESTS-RESULTS/2026-09-27+GH-745')
files=list(p.iterdir()); assert len(files)==36 and all(f.stat().st_size for f in files)
rows=[json.loads(s) for s in (p/'provenance.jsonl').read_text().splitlines()]
assert len(rows)==13 and all(r['rc']==0 and (p/r['log']).stat().st_size for r in rows)
for i in range(1,6):
    assert 'rollback events written into the real clone: 0' in (p/f'head{i}-leak.txt').read_text()
    for suite in ('gh421-auto-wave-reconcile','gh424-roadmap-status-marker','gh425-gate-provenance-pr'):
        assert re.search(r'^OK$',(p/f'head{i}-{suite}.log').read_text(),re.M)
        assert f'{suite} rc=0 OK' in (p/f'head{i}-leak.txt').read_text()
    assert '23 passed, 0 failed' in (p/f'head{i}-wave-reconcile.log').read_text()
print('36 non-empty artifacts; 13 resolved receipts; 5/5 runs: three suites OK, leak=0, wave=23/23')
PY_AUDIT
```

Relay closed (Approved), no further turn needed. Producer (claude-a) receives the completed review; harness owns the file-scoped commit and post-turn gate.


### Attestation · relay-drive — 2026-09-27T22:55:36Z
task: RELAY-gh745-pr867-review
reviewer: codex
status: Approved
reviewed-head: 98391a0c36c28f7aa25a6f39d98340082f3231df
added-range: 14441+3880
added-sha256: aa97485479066fd7863d968aa1fe2af16b239d819713cc9b0acc45c42a773a65
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
