# RELAY · GH1401 PR1404 Opus medium QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-09.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 3

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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1401-pr1404-opus-medium-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh1401-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file temp/opus-qa/gh1401-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: claude-opus   ·   Producer: codex-parent
- Started: 2026-11-09
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 (claude-opus)

swept file: yes. I read all of `skills/1-hourly/conveyor/SKILL.md` (71 lines), `PROJECT/2-WORKING/GH-1401-CONVEYOR.md` (81 lines), the ARCHITECTURE row (`ARCHITECTURE.md:57`) and the TESTS-RESULTS SUMMARY. I checked every CLI and parser claim in the skill against its consumer: `utils/py/swarm_preflight.py`, `utils/py/jog_run.py:1577`, `utils/py/releases_app.py` pickup/rate, the HQ skill, the idea skill and `prior_art_recon.py`. All probes were read-only; no tests, validate or fixtures were run.

- **[Should] Step 4 has no instructed path to rate an existing unrated row: `pickup --rated` silently drops the rating there.** `cmd_roadmap_pickup` returns early on any existing row: `if row is not None: ... print("roadmap-pickup: GH-%d already parked (%s); preserved" ...); return` (`releases_app.py:3841-3862`). `--rated` is never read on that path. The skill (`SKILL.md:36`) passes `--rated P/S/A/E` and then only offers `roadmap rate` for "A justified rescore ... with retained `--ovr`" (`SKILL.md:42`). For an issue that is parked but has never been rated, the agent gets "preserved", and the read-back then shows no rating. The skill gives no next step: the rescore wording does not fit, and the agent cannot tell whether to hold or improvise.
  - Observed input: `sqlite3 -readonly releases.db "SELECT COUNT(*) FROM roadmap_items WHERE gh_number IS NOT NULL AND rating_pri IS NULL"` exited 0 and returned `40`. Open-section examples: `1314|Queue / parked intake|🆕` and `1293|Queue / parked intake|🆕`. `/conveyor 1314` would hit the early return at `releases_app.py:3841`.
  - Affected scope: only issues whose roadmap row exists with `rating_pri IS NULL`. Absent rows (the create path) and rated rows (correctly preserved) are unchanged.
  - Fix (instruction only, no code): in Step 4, add one sentence: "If pickup reports an existing row that is unrated, apply the first rating with `roadmap rate --issue-num N --rated P/S/A/E --dry-run`, then without `--dry-run`. This needs no `--force`." `rate` refuses to overwrite an existing rating without `--force` (`releases_app.py:7020-7021`), so the sentence cannot clobber operator values.
  - Falsifier: if pickup's existing-row path did apply `--rated` to a NULL-rated row, the gap would not exist. Expected result under current code: in a disposable clone, `pickup --issue-num 1314 --rated 50/50/50/50` followed by `roadmap list --json` still shows GH-1314 with null rating fields. Grade: [Unverified — needs clone run]. The early return is statically certain from `releases_app.py:3841-3862`.
- **[Nit] On an existing row, the pickup `--dry-run` "preview" shows nothing about a repoint.** When `--doc-path` differs, the dry-run skips the write but prints the same "already parked ... preserved" line (`releases_app.py:3857-3861`). It never says that a doc repoint would happen, so "After inspecting the preview" (`SKILL.md:37`) shows nothing useful. This is optional: the Step 4 read-back (`roadmap list --json`, `SKILL.md:38,42`) already catches the doc path. No change required.
- **[Pass] Probe polarity matches the evaluator.** `path_absent` lands when the path exists. `grep_present` lands when the pattern is gone and is blocked when the file is missing. `grep_absent` lands when the pattern is present. `command` lands on rc≠0, inverted by `expect_nonzero` (`swarm_preflight.py:207-232`). All of this agrees with `SKILL.md:31`.
- **[Pass] Contract fields and the `artifacts_new` rule are the parser's rules, not a second schema.** Each `artifacts_new` entry must also appear in `artifacts` (`swarm_preflight.py:119-126`) and needs a matching `path_absent` probe (`swarm_preflight.py:1332-1336`), as `SKILL.md:29` says.
- **[Pass] Preflight flags, input scope and exit codes are accurate.** `--project-doc/--target-root/--format/--dry-run` exist (`swarm_preflight.py:1158-1163`). `--gh-issue` globs only `PROJECT/2-WORKING` (`swarm_preflight.py:1232-1235`). Exit codes match: 3 contract error, 4 STALE, 5 NOT-READY, 6 BLOCKED, 7 AMBIGUOUS (`:66`, `:1644-1645`, `:1210`, `:182`).
- **[Pass] The validation snippet fits the real signatures.** `extract_contract(doc_path)` is at `swarm_preflight.py:54`, and `contract_probes_from_doc(root, doc_path)` returns `(labels, reason)` (`jog_run.py:1577-1582`). If the doc has no contract heading, `extract_contract` exits 3 before the assert runs, so the snippet fails closed rather than passing an empty result.
- **[Pass] Pickup cannot grant accepted start or an in-progress label.** `pickup` has no `--accepted-start` flag (`releases_app.py:7025-7032`). The `in-progress` label is set only on `roadmap-update` with `accepted_start` (`releases_app.py:1655-1657`). Existing scores and override are preserved (`releases_app.py:3826`).
- **[Pass] The readiness label is a publication signal only.** `grep -rn ready-for-pickup utils/py/*.py skills/1-hourly/jog/SKILL.md` returned nothing, so no consumer admits work from the label, matching "today Jog does not select or admit work from it" (`SKILL.md:67`). The label is held until the packet is on the integration ref and a fresh exit-0 run passes (`SKILL.md:63-65`). A stale label is removed only within invocation scope (`SKILL.md:67`). This composes with PR1403's flow of explicit owner selection, revalidation, then execution, and no shared runtime is touched (the PR's changes are the skill, the index row, docs and evidence).
- **[Pass] The skill's cross-references resolve.** `hq park --gh-issue N` exists (`skills/2-daily/hq/SKILL.md:68`). The idea skill excludes retrofit (`skills/1-hourly/idea/SKILL.md:3,72`). `prior_art_recon.py` supports `--query/--json` (`:171,176`). `relay-automation/CONTRACT.example.md` exists.
- **[Pass] The evidence supports the claims and the change is proportionate.** SUMMARY records main READY exit 0, adjacent STALE exit 4 and the empty-probe red control at exit 3 (`TESTS-RESULTS/2026-11-09+GH-1401/SUMMARY.md:5-7`). No new tests, gates or runtime were added, consistent with GH831. Gap: the evidence never exercised the existing-unrated-row path, which is why the Should finding above went undetected.
- Pre-existing defects in the swept files: none beyond the writer behaviour behind the Should and the Nit. That writer is not changed by this PR, and the fix belongs in the skill text.

VERDICT: FAIL
Basis: The three invocation modes are bounded and use existing contracts. Polarity, parser, preflight, publication, holds, the accepted-start exclusion and the no-execution boundary are all correct and cited above. One instruction cannot be completed as written: for the 40 existing unrated rows (for example, open GH-1314 and GH-1293), the canonical `pickup --rated` drops the rating without error, and the skill only names `roadmap rate` for rescoring. The fix is one sentence of skill text. I would approve once it is added and nothing else in the skill changes.

handing off to Producer (codex-parent): go to the codex-parent window and say "take your turn".

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
