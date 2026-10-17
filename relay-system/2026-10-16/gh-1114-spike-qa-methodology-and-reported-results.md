# RELAY · GH-1114 spike QA — methodology and reported results
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-16.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh-1114-spike-qa-methodology-and-reported-results): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh1114-qa-pack.md** — the read-only path that
  `relay-drive.sh --artifact-file temp/gh1114-qa-pack.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-10-16
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer · agy

swept file: yes

Full sweep of `.relay-artifacts/gh1114-qa-pack.md` (lines 1–152) and the referenced spike commit `/tmp/xyz-forge-spike-gh1114` `be487693` (`utils/py/wave_reconcile.py` lines 1338–1421, `temp/gh1114_manual_check.py`, `temp/gh1114_measure.py`) found no pre-existing defects in the touched surfaces. No `[Blocker]` or `[Should]` behaviour changes are requested.

#### Answers to the 6 Review Questions & Graded Findings

1. **`[Pass]` Correctness of the predicate (Q1):** The conjunction of `BOOKKEEPING_SUBJECT = re.compile(r"^chore: (reconcile|retain)\b")` and `is_bookkeeping_commit(repo_root, sha)` is implemented as described in `.relay-artifacts/gh1114-qa-pack.md:20-24` and `/tmp/xyz-forge-spike-gh1114/utils/py/wave_reconcile.py:1340-1352,1404-1410`.
   - *Subject parsing:* `sha, _, rest = line.partition(" ")` followed by `author, _, subject = rest.partition(" ")` (`wave_reconcile.py:1404-1405`) on `--format=%H %ae %s` is exact as long as `%ae` contains no spaces (standard email format; verified across all 317 non-merge first-parent commits).
   - *First-parent / merge nuance:* `unreconciled_commits` runs `git log --first-parent` (`wave_reconcile.py:1394`) without `--no-merges`; for a merge commit not already in `merged_shas`, `git diff-tree --no-commit-id --name-only -r <sha>` returns empty stdout (`""`) unless `-m`/`-c`/`--cc` is passed, which triggers `not changed.stdout.strip()` (`wave_reconcile.py:1349`) and fails closed (`False`). Probe `git -C /tmp/xyz-forge-spike-gh1114 log --first-parent --merges --since=2026-09-16 --format='%H %ae %s' development | grep -E 'chore: (reconcile|retain)'` exited 0 with `no matching merge commits`.
   - *Prefix matching (`path.startswith(root)`):* In `BOOKKEEPING_PATHS = ("TESTS-RESULTS/", "PROJECT/", "CHANGELOG.md", "LEADERBOARD.md", "releases.sql", "releases.db")` (`wave_reconcile.py:1341-1342`), directory roots carry trailing slashes and file roots are exact filenames. Because `startswith("CHANGELOG.md")` would theoretically match a hypothetical root file like `CHANGELOG.md.bak` or `releases.db-wal`, that is a negligible theoretical edge case (see `[Nit]` below), not a practical failure on repo history.

2. **`[Pass]` Fail-closed claims (Q2):** Confirmed in `/tmp/xyz-forge-spike-gh1114/utils/py/wave_reconcile.py:1345-1352,1408-1410` and verified by live probe (`python3 /tmp/xyz-forge-spike-gh1114/temp/gh1114_manual_check.py green`, `rc=0`):
   - *Empty diff / git error:* `if changed.returncode or not changed.stdout.strip(): return False` (`wave_reconcile.py:1349-1350`) — exercised by fixture `F` (`--allow-empty -m "chore: reconcile empty diff"`, `gh1114_manual_check.py:60-62`), which remained in `pending=['237ce8de', '6fbb8a28', 'acb7991b']`.
   - *Mixed diff:* `all(any(path.startswith(root) ...))` (`wave_reconcile.py:1351-1352`) returns `False` when any path is outside `BOOKKEEPING_PATHS` — exercised by fixture `C` (`PROJECT/2-ACTIVE/note.md` + `utils/py/evil.py`, `gh1114_manual_check.py:54-55`), which remained pending.
   - *Non-matching subject:* `BOOKKEEPING_SUBJECT.match(subject)` (`wave_reconcile.py:1408`) short-circuits `False` before calling `is_bookkeeping_commit` — exercised by fixture `D` (`feat: real docs work by a human` touching `PROJECT/1-INBOX/capture.md`, `gh1114_manual_check.py:56-57`), which remained pending.

3. **`[Pass]` Verification sufficiency (Q3):** Under repo rail GH-831 (no new test files), verification is sufficient.
   - The 5 existing suites covering `wave_reconcile.py` and commit boundaries are cited in `.relay-artifacts/gh1114-qa-pack.md:80-88` (`[Unverified — needs clone run]` from this reviewer worktree per prompt restriction against running `test/*.sh` or `pytest`, while the manual check and red controls were directly re-executed here).
   - Live probe `python3 /tmp/xyz-forge-spike-gh1114/temp/gh1114_manual_check.py green` (`rc=0`): `GREEN: pending=['237ce8de', '6fbb8a28', 'acb7991b'] expected=['237ce8de', '6fbb8a28', 'acb7991b'] PASS`.
   - Live probe `python3 /tmp/xyz-forge-spike-gh1114/temp/gh1114_manual_check.py red-subject` (`rc=0`): `RED-CONTROL(subject arm off): pending=['6fbb8a28', 'f5415081'] expected=['237ce8de', '6fbb8a28', 'f5415081'] RED CONTROL WENT RED AS REQUIRED (assertion can fail)`.
   - Live probe `python3 /tmp/xyz-forge-spike-gh1114/temp/gh1114_manual_check.py red-paths` (`rc=0`): `RED-CONTROL(path arm off): pending=['2ddfec22', '3983970a', '3b703d4d', '6e38adf0', 'c559ff0a'] expected=['2ddfec22', '3983970a', '3b703d4d'] RED CONTROL WENT RED AS REQUIRED (assertion can fail)`.

4. **`[Pass]` Measurement integrity (Q4):** Re-ran `python3 /tmp/xyz-forge-spike-gh1114/temp/gh1114_measure.py` (`rc=0`).
   - *Empty-extraction guards:* Verified at `/tmp/xyz-forge-spike-gh1114/temp/gh1114_measure.py:34` (`assert commits, "no direct commits extracted — refusing to compute"`), `gh1114_measure.py:50` (`assert runs, "no wave provenance receipts found — refusing to compute"`), and `gh1114_measure.py:61` (`assert any(v for v in runs.values()), "no parsed landings — refusing to compute"`).
   - *Attribution & 59.0 min reading:* `shas <= skip` (`gh1114_measure.py:72`) isolates runs where every qualified landing was a skippable bookkeeping commit (`b86dcaace6` = 14.6m, `63e4956bbc` = 15.9m, `d0dc3268af` = 14.6m, `e271416c52` = 14.0m; exact sum = `59.0 min` across 101 receipt dirs). The 8 `swept-in` runs (`shas & skip` with non-skip PR landings also present, `gh1114_measure.py:76-77`) had to run for the PR landings regardless, so attributing marginal ~0 hosted waste to them and correcting #1110's 98.5 min figure downward is methodologically sound.

5. **`[Pass]` Reporting accuracy (Q5):** Every number and claim in `.relay-artifacts/gh1114-qa-pack.md:18-39,78-108` matches the commit diff (`be487693`) and probe outputs (`317 non-merge first-parent; 37 newly skippable`, `4 solo bookkeeping runs = 59.0 min`, `8 swept-in runs`, `101 runs analysed`), with receipt-backed durations cleanly labelled `FACT`.

6. **`[Pass]` Residual risk (Q6):** Could this predicate suppress a qualification run that was actually needed?
   - In `wave_reconcile.py:1408-1410`, skipping `continue`s before `metadata[("commit", sha)] = meta` (`wave_reconcile.py:1415`), so a skipped commit is also excluded from `catch_up_prs` direct-commit issue-closer ownership (`wave_reconcile.py:1474-1475`).
   - Probe against all 37 historical skipped commits using `wr.extract_linked_issues({"title": subj, "body": body}, "HiQS-Labs/XYZ-forge")` (`rc=0`) confirmed `closed=[]` on every single one (0 of 37 carry closing keywords).
   - Remaining residual risk is strictly bounded to a human authoring a commit titled `chore: reconcile...` or `chore: retain...` whose diff touches *only* `BOOKKEEPING_PATHS` while intending to close an issue via commit message or test a schema migration in `releases.sql`—which contradicts the `chore: reconcile|retain` convention and is guarded at push time by `pre-push`.
   - `[Nit]` In `BOOKKEEPING_PATHS` (`wave_reconcile.py:1341-1342`), using `path.startswith(root)` (`wave_reconcile.py:1351`) on non-directory entries (`CHANGELOG.md`, `LEADERBOARD.md`, `releases.sql`, `releases.db`) would also match a root file with that prefix (e.g. `releases.db-shm` or `CHANGELOG.md.bak`) if ever committed; splitting directory prefixes (`path.startswith(...)`) from exact file matches (`path in ...`) when landing the real fix is a trivial hardening, not a flaw in the spike's conclusions.

**VERDICT:** PASS
**Basis:** The spike's two-arm conjunction (`BOOKKEEPING_SUBJECT` + `is_bookkeeping_commit` whole-diff path allowlist) in `be487693` is fail-closed on git errors, empty diffs, mixed diffs, and non-matching subjects; both red controls fail as required when their respective arm is disabled; empty-input assertions guard every extraction stage in `gh1114_measure.py`; and the 59.0 min solo-run vs. swept-in marginal-cost attribution across 101 receipts is accurate and verified by read-only replay.

relay closed (Approved), no further turn needed

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
