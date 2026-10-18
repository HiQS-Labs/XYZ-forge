# RELAY · GH1121 final unseeded target-tree QA4of4
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
-->

NEXT: —
STATUS: Approved
ROUND: 4 / 4

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
6. **Do not self-commit.** Harness owns the commit/attestation; no push.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Target under review: the actual isolated repository tree at the driver-pinned HEAD; full production files listed in TESTS-RESULTS/2026-10-17+GH-1121/qa-resume-input.json. No seeded artifact.
- Reviewer: agy   ·   Producer: codex-producer
- Started: 2026-10-17
- Definition of Done: Unseeded pinned-target whole-source and sequence review. Actual independent Claude-family reviewer; no Critical/High blockers; strict append-only helper; current exact-head input; all applicable gates preserved.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). No self-commit; harness owns attestation.

## Log

## Final round4of4 — target tree, no seeded artifact

Noel explicitly approved up to FOUR cumulative QA attempts; three consumed, this is the last. No cap reset or extension. This review is of the ACTUAL isolated repository tree at the HEAD the driver pins, not a copied .relay-artifacts input. There is NO --artifact-file on this invocation. Read canonical TESTS-RESULTS/2026-10-17+GH-1121/QA-RESUME.md, BATCH-PLAN.md and qa-resume-input.json as context only; their old attempt3 instructions are historical. Target: the full combined production files listed in production_sha256, current source/code/metadata at pinned HEAD, original source heads1062/1089/1097/1120 and base7f19d57d. R3's full report may inform you but cannot replace your own target-tree review. Reviewer Claude Opus5.5 High through configured Agy, Anthropic family; author GPT family.

Review whole changed production files and the grouping/order, semantic interactions, current-base resolution, exact source preservation, license, rollback and required gates. Read-only local file/hash/SQLite inspection allowed. No tests, Git commands, Git pack parsing, installs, source edits, network posting or self-commit. Only this relay is writable; scratch under .relay-scratch allowed. Caller leaves source tree untouched during your run. Record findings with real file:line/quotes and actual commands/results; don't invent evidence. No Critical/High finding may remain; defer Medium/Low/Nit to GH1121 with clear severity, as instructed. Existing full publication409/409 at a2a13890 covers unchanged production/runtime/test hashes; later normal docs gates cover review/base metadata. Fresh exact-head hosted smoke and actual post-merge hosted full qualification remain mandatory, no promotion.

Process causes fixed: R1 caller concurrent file edit rejected containment; source now clean and caller makes NO tree writes. R2 rewrote earlier blank lines; use EXISTING utils/py/relay_attest.py::append_before_marker(path,text) for your report, then modify ONLY first NEXT/STATUS header lines without normalizing other bytes. Do NOT self-commit; ignore any generic template self-commit rule. Close the handed-off token normally after writing. R3 passed append-only but used --artifact-file, which creates artifact_sha256 and is never target-tree merge-eligible. This invocation is unseeded. After your attestation, caller will store any receipts ONLY in relay-system/ and use relay_attest.load plus candidate_ok before landing; no non-transcript change is allowed without another valid review, and no attempts remain after this one.

Write a Reviewer Round4 block, actual model identity, swept file yes/no, bounded whole-file coverage, graded findings, literal VERDICT: PASS|FAIL|PARKED and cited Basis. If reviewed target is sound with zero Critical/High, set STATUS Approved and NEXT —. Approval is source/strategy review, not unrun gate qualification. Do not dispatch/retry yourself.

### Reviewer — Round 4 (agy)

**Identity:** Claude Opus 5.5 (High), Anthropic family, run through the configured Agy CLI (seat `agy`). The author is from the GPT family, so this review is cross-family.
**Target:** the isolated target tree at the driver-pinned HEAD (`rtl-wt.MztXAb`). This run is unseeded: no `--artifact-file` and no `.relay-artifacts` copy.
swept file: yes

**Coverage (bounded whole-file):** I read every production path in `qa-resume-input.json` in full:
- the three new skill bodies: `review-code-xyz/SKILL.md` (436 lines), `review-pr-xyz/SKILL.md` (201) and `worth-it/SKILL.md` (192)
- both `install.sh` files (58 lines each) and the worth-it `NOTICE` (38)
- `sync.py`, all 394 lines, plus the `intake.py` helpers it calls: `git_at`, `collection_repo`, `regular_bytes`, `dirty_paths`
- `recovery.md`, from the GH-960 section through to the end of the file
- the review-xyz frontmatter and the first 40 lines of its body
- the `xyz_mini_sync.py` MANIFEST block (lines 55–80)
- the three changed suites, as zero-context hunks
- the `ARCHITECTURE.md`, `README.md`, `mini/README.md` and start-task hunks, each with its step/section context

I skimmed the GPL-2 `LICENSE` body; I did not compare it to the FSF text word for word. Context only: BATCH-PLAN.md, QA-RESUME.md, manual-preservation.txt and candidate-production.txt. R3 was not used as evidence.

**Probes run.** I did not run git or tests. Every command exited 0.
1. Production hashes: Python sha256 over all 18 `production_sha256` paths printed `OK` for 18/18. This is the current tree, computed by me.
2. Stale-rename sweep: `grep -rn -E 'review-code([^-]|$)|2-daily/review-code/'`, excluding history, TESTS-RESULTS and relay-system. There are no live links or skill references to the old path. The only hits are prose in PROJECT/PARKED/LEADERBOARD, plus `test/gh778…:18`, which asserts the old folder is absent. `ls -d skills/*/review-code` → no match.
3. Link scan: every relative markdown link in the 9 changed docs resolves. The one exception is pre-existing and outside this diff: `ARCHITECTURE.md:351 → PROJECT/3-COMPLETED/GH-12-TICK-FOREIGN-CWD-SILENT-NOOP.md` is missing.
4. Index against disk: 2-daily has 20 table rows, 20 on disk, and the heading says `(20)`. That matches the gh778/gh798 disk-derived assertion. 1-hourly has 16 rows, 16 on disk, heading `(15)`. 3-weekly has 15 rows, 16 on disk, heading `(15)`, and `weekly-planner` is absent from ARCHITECTURE entirely.
5. Pure-function probe of `sync.py` (imported only; no git or network), output in `.relay-scratch/tmp/probe-sync.txt`:
   - `sync_repo_dir="$HOME/x" # c` → `/home/u/x`
   - `${CONFIG_DIR}/repo2` → `<cfg>/repo2`
   - an empty value → `<cfg>/repo`
   - a commented-out line → default
   - `git@GitHub.com:Org/Repo.git`, `https://github.com/Org/Repo` and `ssh://git@github.com/Org/Repo.git/` all → `github.com/Org/Repo`
   - **`config.sh` at mode 000 → `PermissionError [Errno 13]`**
6. Ledger, read-only SQLite (`mode=ro`), `roadmap_items`: there is exactly one row each for gh 1060, 1088, 960 and 1119. All four `doc_path` values exist under `PROJECT/2-WORKING/`, and no GH-960 duplicate is left in `PROJECT/1-INBOX`. `jog_queue` rows matching 960: `(0,)`. That matches BATCH-PLAN:33.
7. Installers: comparing `install.sh` with the skill name masked out gives `installers-identical-modulo-name`. Both files are `-rwxr-xr-x`.

**Findings**
- [Pass] **Exact source preservation.** The hashes at the current HEAD equal `manual-preservation.txt` for all 13 member-source files. The worth-it `NOTICE:13-14` self-declared SHA-256s (`01d5711d…`, `8177f975…`) equal the computed hashes of `SKILL.md` and `LICENSE`, so the claim "byte-identical import" (`NOTICE:15`) holds for the bytes on disk. The ancestry of the four exact heads is author-measured (manual-preservation.txt:1-4). I could not independently verify it without git, so it is graded [Unverified — needs clone run].
- [Pass] **Rename consistency (1062).** The MANIFEST ships both new skills as `managed` (`utils/py/xyz_mini_sync.py` MANIFEST rows `skills/2-daily/review-code-xyz` and `skills/2-daily/review-pr-xyz`). gh589 expects the sorted twelve (`…"relay", "review-code-xyz", "review-pr-xyz", "skill-viewer"…`), which is in correct lexical order. The gh778 handoff regex matches `review-code-xyz/SKILL.md:98` "Stop and hand off to [`review-pr-xyz`]". Probe 2 found no dangling live reference.
- [Pass] **Semantic interactions across members.** The members touch disjoint surfaces: review skills, a start-task prose step, Skills Army `repo_health`, and a standalone worth-it bundle. No member references another member's renamed path (probe 2). `sync.py` adds only `warn()` calls and additive result keys (`sync.py:186-215`). `main` still returns non-zero only on `errors` (`sync.py:386`), and `repo_health` runs before `transact` (`sync.py:377` vs `:385`). The diagnostics cannot change a deploy outcome except through the Low finding below. All git calls go through `git_at`, which uses `--no-optional-locks` (`intake.py:436-437`). Every subcommand is read-only: `symbolic-ref`, `rev-list`, `remote get-url`, `config --get`, `rev-parse`.
- [Pass] **License and attribution (1120).** The bundle carries the full GPL-2 text and states non-relicensing (`NOTICE:12` "Forge's root license does not relicense it"). It is a standalone markdown skill, which is mere aggregation under GPL-2 §2 (`LICENSE:129`). `README.md:321` points to the NOTICE. `LICENSE-COMMERCIAL.md:60-61` already says it "does not change the licensing of the third-party dependencies XYZ incorporates", so the commercial grant does not overreach.
- [Pass] **Rollback, gates and test policy.** The rollback is a revert of the batch merge's first-parent diff (BATCH-PLAN:29), rated Easy, with no schema, workflow or CI change. No new suite was added. The three suite edits keep existing assertions truthful after the rename (gh589:62, gh778, gh798), which the GH-831 rail permits. gh778 is already turned off under the GH-831 exemption (`test/gh306-registry-bidirectional.sh:59`). The plan keeps the mandatory exact-head hosted smoke and the post-merge hosted tier-3 qualification (BATCH-PLAN:27), with no main promotion.
- [Low → defer GH-1121] **New abort path in sync.py.** `sync.py:85` reads `config.sh` through `shared.regular_bytes`. An unreadable config raises `OSError`, which `main` turns into exit 2 (`sync.py:387-389`). A read-only diagnostic can therefore abort preview, `--status` and `--apply`.
  - Observed input: probe 5, `config.sh` mode 000 → `PermissionError [Errno 13]`.
  - Affected scope: an unreadable or non-regular-at-open `config.sh` only.
  - Falsifier: a mode-600 config, which parses fine (probe 5).
  - The failure is fail-closed and happens before `transact`, so nothing is lost. Suggested fix: catch `OSError` in `pulse_sync_repo` and warn "duplicate-clone check skipped: unreadable config".
- [Low → defer GH-1121] **`normalize_remote` is case-sensitive.** It lowercases the host but not the owner/repo path (`sync.py:148`), so `github.com/Org/Repo` and `github.com/org/repo` compare unequal (probe 5). On a case-insensitive host this is a false negative for `DUPLICATE_PULSE_CLONE`. It is advisory only.
- [Low → defer GH-1121] **Stale index and counts, all pre-existing or already retained.**
  - `ARCHITECTURE.md:49` says `(15)` against 16 on disk; `:99` says `(15)` against 16 on disk, because `weekly-planner` is missing from the index.
  - `mini/README.md:8` says "eleven" while 12 rows are listed.
  - The `ARCHITECTURE.md:351` link is dead.
  - The `LICENSE-COMMERCIAL.md:62-64` dependency list does not mention the worth-it bundle, although the general carve-out at :60-61 covers it.
- [Nit → defer] `review-code-xyz/SKILL.md:285-292`: the Workhorse rungs jump from 3 to 5.
- [Nit → defer] `start-task/SKILL.md:262`: "independent review (step 6)" should point to step 8, the final QA. This is the retained 1089 CodeRabbit nit.
- [Nit → defer] In mini's flat layout, the `../../1-hourly/...` and `../review-xyz/` links in the published review skills will not resolve; `xyz_mini_sync.py` does not rewrite links.
- [Nit → defer] `README.md:321`: the third-party sentence comes before the "AGPL-3.0-only" line in the License section. Putting the root license first reads better.
- [Nit → defer] `sync.py:82`: a symlinked `config.sh` returns `None`, so the warning says "no git-pulse config". The skip is intentional, but the wording is wrong (R3 nit).
- [Info] Operator carry-over: links created by the old `review-code` installer (`~/.claude/skills/review-code → …/2-daily/review-code`) will dangle after the landing. This is covered by carry-over BATCH-PLAN:37 and is not a code defect.

There are no Critical or High findings. No finding asks for a behaviour change before merge; the Low items carry observed input, scope and a falsifier only so they can be dispositioned in GH-1121.

VERDICT: PASS
**Basis:**
- All 18 production hashes at the pinned HEAD match `qa-resume-input.json` (probe 1).
- The member-source bytes equal the declared exact-source hashes (manual-preservation.txt:5-17).
- There are no hidden cross-member dependencies or dangling references to the renamed skill (probes 2-3).
- The `sync.py` change is read-only and advisory and comes before `transact` (`sync.py:166-215`, `:377-386`).
- The ledger state matches the plan (probe 6).
- The GPL-2 bundle is correctly isolated and attributed (`NOTICE:12`, `LICENSE:129`, `LICENSE-COMMERCIAL.md:60-61`).
- The remaining items are Low or Nit and deferred to GH-1121, as the operator instructed.

This approval covers source and strategy review only. It is **not** gate qualification. Still pending:
- the exact-head hosted smoke
- the post-merge hosted wave-reconcile tier-3 full run
- issue-doc-sync and PRS reconciliation
- clone-verified ancestry of the four member heads

Relay closed (Approved), no further reviewer turn needed. Hand control back to the caller: go to the codex-producer/caller window and continue the landing checks (`candidate_ok`, exact-head smoke).

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
