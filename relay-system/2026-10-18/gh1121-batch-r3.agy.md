# RELAY · GH1121 cumulative QA round3 of4
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
-->

NEXT: —
STATUS: Approved
ROUND: 3 / 4

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
6. **Do not self-commit.** The harness owns the file-scoped commit and attestation. No push.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/QA-RESUME.md** — the read-only path that
  `relay-drive.sh --artifact-file TESTS-RESULTS/2026-10-17+GH-1121/QA-RESUME.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: codex-producer
- Started: 2026-10-17
- Definition of Done: QA-RESUME packet: actual different-family reviewer, source/grouping review, no Critical/High blockers, prefix-preserving append, truthful pending gate disclosure.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). Do not self-commit; harness owns attestation.

## Log

## Current review input
Read .relay-artifacts/QA-RESUME.md and canonical TESTS-RESULTS/2026-10-17+GH-1121/QA-RESUME.md. Requested actual model Claude Opus5.5 High through agy; author GPT family. Use existing append_before_marker for your report, preserve prior bytes, change only NEXT/STATUS headers, no self-commit. Source reviewed-head must be the actual setup HEAD the driver pins.

### Reviewer · Round 3 (agy)

- Reviewer identity: Claude Opus 5.5 (High), Anthropic Claude family, running through agy. Author is Codex (GPT family) per BATCH-PLAN.md:5, so the reviewer is from a different family.
- swept file: yes. I read all of `.relay-artifacts/QA-RESUME.md` (byte-identical to canonical: `cmp TESTS-RESULTS/2026-10-17+GH-1121/QA-RESUME.md .relay-artifacts/QA-RESUME.md` → cmp=0), all of BATCH-PLAN.md, qa-resume-input.json, heads.json, manual-preservation.txt, provenance.jsonl, base-refresh*, resolution-10{62,89}/1120.json, the whole of candidate-production.txt, and the whole of review-code-xyz/SKILL.md (437 lines), review-pr-xyz/SKILL.md (202 lines) and sync.py `repo_health` plus its new helpers.
- Scope is the whole files. Pre-existing defects found in touched files are listed below as Low, as the rule asks.
- Method: read-only. I hashed files with Python, used grep/find, and parsed with `ast.parse`. I did not run tests, git commands or pack parsing, and wrote no files outside .relay-scratch.

**Findings**
- [Pass] Production bytes match the frozen input. I hashed all 18 `production_sha256` entries in qa-resume-input.json:10-28 this turn. Python sha256 loop, exit 0: `mismatches 0 of 18`. For example, `OK  utils/py/xyz_mini_sync.py 2e3cb157663cb91e` and `OK  skills/3-weekly/worth-it/SKILL.md 01d5711d5de7529b`. The same 13 source-file hashes appear in manual-preservation.txt:5-17, so the current tree agrees with the author's preservation receipt. That source-head equality and the ancestry lines (manual-preservation.txt:1-4) remain author-measured. I could not verify them without git.
- [Pass] Merge policy is as stated. `.merge-cleanup.json` is exactly `{"preserve_commit_history": true}`, matching QA-RESUME.md:5. The r1 fabrication noted at BATCH-PLAN.md:44 is not repeated here.
- [Unverified — no citation] The grouping and order 1062→1089→1097→1120 have no hidden hard dependency. The diff map in candidate-production.txt shows each source owns a disjoint production surface:
  - 1062: review-code-xyz/review-pr-xyz/review-xyz, xyz_mini_sync.py, and tests gh589/gh778/gh798 (lines 65-847, 1619-1701).
  - 1089: start-task (lines 40-64).
  - 1097: sync.py and recovery.md (lines 848-1031).
  - 1120: worth-it (lines 1032-1618).
  - The only shared files are ARCHITECTURE.md, README.md and mini/README.md (lines 1-39), plus the ledger, which was replayed by the writer (resolution-1062.json `"replay=1 op(s)"`, and likewise for 1089/1120).
  - releases.sql carries 11 `rmi-01M563` hits and GH-1060/1088/960/1119 rows, matching base-refresh-classification.json `"added"` ×3 + `"updated"` ×1.
- [Pass] The review-code → review-code-xyz rename is complete.
  - `ls -d skills/2-daily/review-code` → `No such file or directory`.
  - The MANIFEST adds both skills (candidate-production.txt:1700-1701). An AST probe gives a skills set of `consult, daily-planner, …, review-code-xyz, review-pr-xyz, …` with no missing source path.
  - gh589 now expects twelve (candidate-production.txt:1625).
  - The only leftover `skills/2-daily/review-code` references are the absence check at test/gh778-review-code-skill.sh:18 and a historical note at PARKED/2026-09-29-xyz-mini-sync.md:19,22.
- [Pass] The 2-daily count is right. `find skills/2-daily -mindepth 2 -maxdepth 2 -name SKILL.md` gives 20, which equals ARCHITECTURE.md:72 `### \`2-daily\` — A few times a day (20)` and the 20 linked rows.
- [Pass] Relative links resolve in every changed skill or doc file. A regex link scan over the 9 changed md files found one broken link, at ARCHITECTURE.md:351 (`PROJECT/3-COMPLETED/GH-12-TICK-FOREIGN-CWD-SILENT-NOOP.md`). That line is outside the diff hunks (candidate-production.txt:5-16), so it is pre-existing; see the Lows.
- [Pass] The sync.py diagnostics (GH-960) are read-only.
  - Both files parse (`parse ok skills/3-weekly/skills-army-hq/scripts/sync.py`).
  - All git calls go through `shared.git_at`, which is `["git", "--no-optional-locks", "-C", …]` (intake.py:436-437).
  - config.sh is tokenized with `shlex.split(..., comments=True)` and never executed (candidate-production.txt:912-916).
  - The new code only adds warnings and report keys (candidate-production.txt:1028-1031). It does not write files, mutate config, or make network calls, which matches recovery.md (candidate-production.txt:855-857, 868).
  - The helpers it reuses (`regular_bytes`, `git_at`, `collection_repo`, `re`) already exist in intake.py:12,64,436,440, so no parallel subsystem was added.
- [Pass] worth-it attribution and license hold up.
  - The LICENSE header reads `GNU GENERAL PUBLIC LICENSE / Version 2, June 1991`.
  - NOTICE (candidate-production.txt:1394) says the bundle is separately licensed and is not relicensed. README.md adds a pointer (candidate-production.txt:22).
  - The SHA-256 values in NOTICE (candidate-production.txt:1395-1396) equal the hashes I computed for SKILL.md and LICENSE.
  - The PR15 pin is honestly labeled "PR open, not merged" (candidate-production.txt:1392).
- [Pass] The pending-gate disclosure is truthful.
  - QA-RESUME.md:7 says `No post-merge full qualification yet; mandatory hosted Wave reconciliation after actual landing will cover it`.
  - BATCH-PLAN.md:54 says `NOT ci-local sequential promotion evidence`.
  - provenance.jsonl's publication row has `"promotion_qualification": false`.
  - The skipped Ubuntu/macOS legs are disclosed (QA-RESUME.md:7).
- [Pass] Rollback and traceability are defined. Before landing there is nothing to undo; after landing, revert the first-parent batch merge with no force rewrite (BATCH-PLAN.md:29). The PR closes only 1060, 1088, 960 and 1119 (BATCH-PLAN.md:33). There is no individual merge, retarget or auto-merge of source PRs (QA-RESUME.md:5).
- [Should — traceability, not a behavior change; defer to GH1121] BATCH-PLAN.md:5 still says `Independent reviewer must be actual Gemini via agy`. This round's operator input in the relay file asked for Claude Opus 5.5 High through agy. The DoD (relay Setup) only requires "actual different-family reviewer", and that is met. Fix: when the batch PR or issue records the outcome, state that the operator's round-3 input picked Claude via agy, so line 5 is not read as an unmet condition.
- [Low — defer to GH1121] sync.py `pulse_sync_repo` returns None when config.sh is a symlink (`if not cfg.is_file() or cfg.is_symlink(): return None`, candidate-production.txt:902-903). `repo_health` then warns `duplicate-clone check skipped: no git-pulse config at …` (line 993), which misnames the cause.
  - Observed input: the code path above.
  - Affected scope: users whose `~/.config/git-pulse/config.sh` is a dotfile symlink.
  - Falsifier: if git-pulse itself refuses symlinked configs, or no such user exists, the current wording is acceptable.
  - The effect is warning text only. Nothing is written.
- [Low — defer to GH1121] sync.py `ahead_behind` falls back to `origin/HEAD`, `origin/main`, `origin/master`, then `FETCH_HEAD` when there is no `@{upstream}` (candidate-production.txt:932). On a branch with no upstream, this can compare against an unrelated branch and emit a spurious `STALE_PULSE_COLLECTION` warning.
  - Observed input: the fallback tuple at line 932.
  - Affected scope: collection checkouts on a branch with no upstream.
  - Falsifier: git-pulse always sets an upstream. The effect is advisory only.
- [Low — confirmed existing deferrals, BATCH-PLAN.md:46]
  - mini/README.md:8 `Mini carries eleven skills`, but there are 12 table rows (mini/README.md:19-30).
  - ARCHITECTURE.md:49 `(15)`, but there are 16 1-hourly rows and 16 on disk.
  - ARCHITECTURE.md:99 `(15)`, but there are 16 3-weekly skills on disk. The cause is that `weekly-planner` has no ARCHITECTURE.md row (`grep -n weekly-planner ARCHITECTURE.md` → empty). The diff does not remove such a row (candidate-production.txt:13-16), so this is pre-existing.
  - ARCHITECTURE.md:351 has a broken link (pre-existing).
  - None of these are fixed in this batch, as instructed.
- [Nit] review-code-xyz/SKILL.md:285-292: the workhorse rung list goes 0,1,2,3,5,6 and skips Rung 4.
- [Nit] review-code-xyz/SKILL.md:407: `If the PR closes issues` is leftover PR-review wording in the local-diff skill. It is harmless, because a branch may have a PR.
- [Unverified — needs clone run]
  - The full gate on the current head.
  - Member-head ancestry.
  - Reviewed-head parentage: the worktree HEAD reads `20b3d6d100ab3478758ac2bc30a220e02fed0553` (from the `.git/worktrees/rtl-wt.6jCAbn/HEAD` file), not `4b3eb334`. That fits the setup/packet commit QA-RESUME.md:5 expects the driver to attest, but I did not verify its parent without git.

VERDICT: PASS
Basis: There are no Critical/High findings. The production bytes independently match all 18 frozen hashes. Source grouping is disjoint, and shared docs and ledger were resolved through the writer. The rename and its consumers (MANIFEST, mini README, gh589/778/798, ARCHITECTURE 2-daily count) are consistent. The sync.py additions are read-only diagnostics on existing helpers. The worth-it license and attribution are intact and their hashes verify. The gate deferral is disclosed truthfully. The remaining findings are Medium/Low or Nit, deferred to GH1121 as the operator instructed.

This is review approval only. It is not landing qualification: the full gate on the reviewed head, the hosted batch smoke on the exact final head, and post-landing hosted wave-reconcile tier-3 qualification are all still pending (BATCH-PLAN.md:27).

Cumulative attempt 3 of 4.

Handing off: relay closed (Approved), no further turn needed. Return to the Producer/caller window for driver attestation and the landing steps.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
