# RELAY · GH-839 final QA — standardize clone backup layout & integrity verification
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-26.
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
6. **Commit only the relay file** (`relay(gh-839-final-qa-standardize-clone-backup-layout-integrity-verification): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh839-final.diff** — the read-only path that
  `relay-drive.sh --artifact-file .relay-artifacts/gh839-final.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: antigravity
- Started: 2026-09-26
- Definition of Done: **Approved** when all of these hold:
  - (a) `backup_clones.py` is implemented cleanly in `skills/2-daily/merge-cleanup/scripts/` with standardized hierarchy under `<root>/_backups/<repo>/<timestamp>/` containing `zips/`, `metadata/`, `reports/`, and `SUMMARY.md`.
  - (b) Cache exclusion correctly excludes heavy disposable directories (`node_modules`, `.venv`, `.pytest_cache`, `__pycache__`) while keeping `.git` and source code.
  - (c) Zip integrity verification is performed via `testzip()` CRC check and SHA256 generation before marking safe.
  - (d) `--backup-first` option is wired cleanly into `merge_cleanup.py` and documented in both `merge-cleanup` and `merge-cleanup-deep` skills.
  - (e) Zero new CI/CD tests added (compliance with moratorium and GH-831). Verified by existing suites and manual check in `TESTS-RESULTS/2026-09-26+GH-839/` with committed `provenance.jsonl`.

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
Basis: The layout and CRC/SHA sequence exist, but byte integrity is being treated as preservation completeness. Concrete source paths below can lose backup content while remaining eligible for teardown. DoD (b)/(c) and the verification evidence need corrections before approval.
swept file: yes

Scope: read both Python files in full, both affected skill documents, the GH-839 capture and evidence, and the seeded change sections. The sweep includes pre-existing teardown handling (R1-6); this is not a diff-only review. No git commands, suites, executable fixtures, or source edits were performed. Archive creation/restoration and teardown behavior are **[Unverified — needs clone run]**; findings distinguish static traces from execution.

- **[Should] R1-1 — Exclusions also remove Git refs and source directories.** `skills/2-daily/merge-cleanup/scripts/backup_clones.py:39`, `:201`, and `:215` apply a basename blacklist everywhere, including `.git`. `build`, `dist`, `env`, and `target` are not intrinsically disposable. CRC cannot detect files never included.
  Observed input: the read-only AST probe below evaluates `clone/.git/refs/heads/build/topic` and `clone/src/env/config.py` as excluded; `clone/src/main.py` is retained. These are concrete path values, not an archive execution claim.
  Affected scope: default cache exclusion in both archivers; Git namespaces and working-tree paths sharing excluded names.
  Falsifier: a disposable-clone backup containing a loose `build/topic` ref and source `src/env/config.py` restores both unchanged, while `node_modules/pkg/index.js` is absent.
  Fix: exempt Git metadata entirely and constrain exclusions to established disposable content; preserve source even when its directory shares a cache/build name. Record omitted paths/policy in metadata.

- **[Should] R1-2 — Backup destinations collide and overwrite prior verified archives.** `backup_clones.py:246`, `:265`, `:277`, `:280`, and `:190` reuse a timestamp directory and name archives only by basename; existing zip files are unlinked. Two inputs can produce two verified records pointing to the final archive of only one clone. Reusing `--timestamp` also destroys an earlier backup before the replacement is verified.
  Observed input: `/roots/a/repo` and `/roots/b/repo` both map to `zips/repo.zip` (read-only path probe: `True`). The CLI accepts arbitrary clone paths and the cleanup scanner accepts multiple roots.
  Affected scope: same-basename candidates, repeated timestamps, or concurrent runs selecting the same second.
  Falsifier: back up two distinct `repo` directories and repeat a run timestamp; both original archives and their correct hashes must remain intact, or the run must refuse before overwriting anything.
  Fix: reject collisions before writing or allocate unique run/archive names exclusively; never replace a previously verified backup implicitly.

- **[Should] R1-3 — Python fallback silently drops directory symlinks.** `backup_clones.py:213` uses `os.walk` without following links, but only archives entries from `files` at `:216`; symlinks to directories appear in `dirs` and are never written. The symlink branch at `:221` therefore does not cover them.
  Observed input: fallback selected (`shutil.which("zip")` returns `None`), with `clone/current -> src/` and an existing `clone/src/` directory; the `current` entry has no write path.
  Affected scope: Python fallback backups containing directory symlinks, including source layout links.
  Falsifier: force fallback in a disposable clone, archive and inspect `current`; it must have a Unix symlink entry with target `src/`, without traversing the target twice.
  Fix: write symlink entries from `dirs` explicitly, or fail closed when the fallback cannot preserve them.

- **[Should] R1-4 — Linked-worktree archives are not self-contained Git backups.** `merge_cleanup.py:1243` includes `SAFE_REMOVE_WORKTREE` in the backup list. `backup_clones.py:99` accepts a `.git` file, and both archivers preserve only that pointer rather than the referenced gitdir. `merge_cleanup.py:690` then removes the worktree through Git, which removes its administrative state. A valid CRC on the pointer does not preserve `.git` as promised.
  Observed input: a candidate with `checkout_type=linked_worktree`, disposition `SAFE_REMOVE_WORKTREE`, and `.git` containing `gitdir: /parent/.git/worktrees/task` enters this path unchanged.
  Affected scope: `--backup-first` linked-worktree candidates and standalone backup CLI inputs with external Git storage.
  Falsifier: after normal worktree removal, extract the backup elsewhere and recover its Git HEAD/index/refs without the original administrative directory.
  Fix: either produce a genuinely restorable Git backup for this shape or explicitly refuse it as unsupported under verified-backup mode. Do not label a pointer-only archive a complete clone backup.

- **[Should] R1-5 — Evidence does not establish the new failure gate.** `TESTS-RESULTS/2026-09-26+GH-839/backup-clones-verification.log` ends with help-text matching for `--backup-first`; it never demonstrates a corrupt archive preventing teardown. Its provenance command is only `manual verification script: ...`, with no reproducible script/commands. The capture claims `gh436-merge-cleanup.py (180/180 pass)` but the three provenance rows contain no receipt for that run. `gh589` is explicitly attributed to the task clone, contrary to the separate disposable-clone rail.
  Fix: provide reproducible manual commands and positive/negative receipts in a disposable full clone for backup completeness and failed verification withholding teardown; attach the claimed gh436 evidence or remove that claim. Keep the no-new-suite rule. The existing log SHA256 values do match their receipts (579, 904, and 6938 bytes respectively), so this is a coverage/attribution issue, not a hash mismatch.

- **[Should] R1-6 — Pre-existing teardown failure is reported as success; new backup failures inherit that outcome.** `merge_cleanup.py:690` checks failed worktree removal but then returns `True` after prune/repair without retrying removal or checking disappearance. `:1265` ignores every teardown return; `:1271` returns zero. The new backup failure branch at `:1258` likewise logs an error and ultimately exits zero.
  Observed input: `worktree remove` returning nonzero at `:691`, or `backup_res["all_verified"] == False` at `:1258`; both control paths reach successful completion.
  Affected scope: failed Phase 6 operations and partial/all failed requested backups.
  Falsifier: a disposable-clone run with a refused removal or failed backup returns nonzero and names preserved candidates, while an all-success run returns zero.
  Fix: preserve per-candidate progress but aggregate failures into an honest nonzero result; only report removal success when observed. This defect predates the backup addition in the removal path.

- **[Pass] Structural pieces are present.** `backup_clones.py:246` constructs the requested run hierarchy, `:73` calls `testzip()`, and `:314` through `:330` order CRC verification and SHA generation before `verified=True`. This is source-level evidence only. The seeded diff's file headers contain no new `test/` suite or `validate.sh` edit.
- **[Nit] Drop routine generated-view churn.** `.relay-artifacts/gh839-final.diff:22` includes `LEADERBOARD.md`; AGENTS.md assigns routine view reconciliation to the hosted workflow. Also bind `DEST` to the generated run directory in deep-skill Phase 1 before Phase 3 uses `<DEST>/reports/`, and remove the contradictory permission to start Phase 2 before backup completion.

Read-only probe receipt (exit **0**; no backup or fixture execution):
```python
import ast, hashlib, json
from pathlib import Path
p=Path('skills/2-daily/merge-cleanup/scripts/backup_clones.py')
t=ast.parse(p.read_text())
ex=next(ast.literal_eval(n.value) for n in t.body if isinstance(n,ast.AnnAssign) and getattr(n.target,'id','')=='DEFAULT_CACHE_EXCLUDES')
for name in ['clone/.git/refs/heads/build/topic','clone/src/env/config.py','clone/src/main.py','clone/node_modules/pkg/index.js']:
    print(f'{name}: excluded directory component={any(x in ex for x in Path(name).parts[:-1])}')
a,b=Path('/roots/a/repo'),Path('/roots/b/repo')
print(f'destination collision: {a.name}.zip == {b.name}.zip: {a.name==b.name}')
base=Path('TESTS-RESULTS/2026-09-26+GH-839')
for line in (base/'provenance.jsonl').read_text().splitlines():
    r=json.loads(line); data=(base/r['log']).read_bytes()
    print(f"{r['log']}: bytes={len(data)} sha_matches={hashlib.sha256(data).hexdigest()==r['log_sha256']}")
```
Command: `PYTHONDONTWRITEBYTECODE=1 python3 -` with the above stdin. Decisive output: exclusion booleans `True, True, False, True`; `destination collision: repo.zip == repo.zip: True`; all three `sha_matches=True`. These measure predicates and receipt bytes, not restore fidelity.

Root cause: backup verification checks the bytes selected by the archiver but not preservation of the requested clone state; fix sites are input selection, archive naming, supported checkout shapes, and failure propagation, before CRC/SHA can authorize teardown.

Handing off to Producer (antigravity) — address each finding, record dispositions and disposable-clone evidence, then return for Round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
