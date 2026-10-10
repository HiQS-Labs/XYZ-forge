# RELAY · GH1016 final QA: repo slug identity
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-10.
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
6. **Commit only the relay file** (`relay(gh1016-final-qa-repo-slug-identity): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the committed implementation diff 9a923f3c to 1cb42805 on branch fix/XYZ-forge-gh1016-repo-slug-identity-2026-10-10 (the pushed task branch), covering `utils/py/releases_app.py` (`resolve_roadmap_identity` and `cmd_init` plus `--slug` help) and `relay-automation/xyz-releases-onboard.sh`. Grade it against the approved plan `PROJECT/2-WORKING/GH-1016-REPO-SLUG-IDENTITY.md` (Plan, Acceptance map, Implementation evidence), the plan-QA thread `relay-system/2026-10-10/gh1016-plan-qa.md`, `CHANGELOG.md` (top entry), and evidence `TESTS-RESULTS/2026-10-10+GH-1016/provenance.jsonl`, `TESTS-RESULTS/2026-10-10+GH-1016/identity_check.py`, `TESTS-RESULTS/2026-10-10+GH-1016/red-control-9a923f3c.jsonl`, `TESTS-RESULTS/2026-10-10+GH-1016/green-gate-1cb42805.jsonl` and `TESTS-RESULTS/2026-10-10+GH-1016/prepush-gate-1cb42805.log`. Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1016
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-10
- Definition of Done: the implementation matches the Approved plan and satisfies issue #1016's acceptance. An AEGIS-shaped ledger (bare `aegis-sleuth-slack-bot`, origin `HiQS-Labs/AEGIS-Sleuth-Slackbot`) resolves its own rows `identity_valid True`, foreign-repo rows stay invalid, and new ledgers from init and onboard record the GitHub owner/name, falling back to the basename otherwise. A red control fails on the pre-fix tree. There is no duplicate writer, parser, verb, schema change, or new test suite or registry entry (AGENTS.md GH-831). The persisted rating 70/60/50/70 still fits the evidence, and the gate evidence substantiates the claims.

## Operational envelope

Local, single-operator CLI ledger, vendored into a few consumer repos. Grade against the stated requirements and commensurate complexity; no enterprise threat models, no new suites or gate machinery (a new test file in the diff would itself be a finding).

## Acceptance map → evidence

| Requirement | Evidence |
|---|---|
| AEGIS-shaped own row valid; wave dry-run moves it | `legacy-bare-own-row-valid`, `wave-reconcile-moves-own-row`: red at `9a923f3c`, green at `1cb42805` |
| Foreign rows invalid (same name/other owner; other repo; wave skip) | three legacy foreign cases pass at base and fix |
| Multi-repo ledger keeps exact match | `multi-repo-ledger-keeps-exact-match` |
| init records owner/name; local-path/no-origin keep basename; explicit wins | five `init-*` cases |
| onboard records owner/name incl. dotted; explicit/no-origin unchanged | four `onboard-*` cases (default/dotted red at base) |
| No regression | focused gh646/gh605×2/gh32/gh197/relay-pkg-freshness/gh238 rc=0; full pre-push gate GREEN 406/406 in 871s in a disposable full clone at `1cb42805` (`provenance.jsonl` full_gate line) |

## Questions

1. Does the resolver change in `utils/py/releases_app.py` (`resolve_roadmap_identity`) implement exactly the approved rule? That is: exact match retained; casefold and `-`/`_` removal only for a bare slug with `len(repo_rows) == 1`; validity still `url_repo == source` and number equality. Can any concrete foreign row become valid (paste it if so)?
2. Does `cmd_init` use `_github_slug_from_origin` with the basename fallback and explicit `--slug` precedence, writing the same value to `repos.slug` and `settings.repo_slug`?
3. Does the onboard change use the shared parser for both `EFFECTIVE_SLUG` and `GH_BASE`, keep the `--slug owner/name` fallback, and fail closed if the lookup errors? Is the `python3 -c` import of `releases_app` from `$RELEASES_APP`'s directory sound in a vendored `.xyz/` install (Tier 2)?
4. Did any duplicate subsystem, writer, verb, schema change, new suite or registry entry slip into `9a923f3c..1cb42805`?
5. Do the receipts substantiate the claims? Check the hashes in `provenance.jsonl`, red 9/15 versus green 15/15, and the gate log's GREEN line plus the absence of non-zero rc. Is the CHANGELOG entry accurate?
6. Does the rating 70/60/50/70 still match the evidence?

Output: graded findings with `file:line` citations; behaviour-change requests carry `Observed input:` / `Affected scope:` / `Falsifier:`. End with `VERDICT: PASS|FAIL` and a `Basis:` line; set `STATUS: Approved` only on PASS. Review only: no `validate.sh`, `test/*.sh`, pytest or fixtures in the relay worktree; read-only probes under `$TMPDIR` are fine. Only edit this relay file.

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

Reviewed both complete implementation files, the approved plan and plan-QA dispositions, CHANGELOG entry, manual check, and retained receipts. Review-code skill applied within the operator's review-only envelope. Codebase Memory tier: Verify with direct-source fallback: no project matches this worktree; nearest `XYZ-forge` is another root, generation `2026-09-01T15:54:30Z`. Symbol search is stale and coverage reports changed/missing metadata or exclusion for the evidence paths, so local source is authoritative here. Read-only decoding of local commit/tree objects established the exact `9a923f3c..1cb42805` path set and that both executable files equal the committed head; GitHub comparison query failed (`gh api repos/HiQS-Labs/XYZ-forge/compare/9a923f3cc131f432f2682e7a11f57d03597fb5df...1cb42805b01a6aba8d5aec841e7a9394d8b084bd`, exit 1, `error connecting to api.github.com`). No git commands, suites, gates, pytest, or executable fixtures were run. One concrete pre-existing defect was found in the whole-file sweep, below; no additional confirmed defects were found.

- [Should] **An unnumbered row accepted by `roadmap repoint --gid` crashes while reporting the already-completed write.** `utils/py/releases_app.py:3782` deliberately selects by GID, but `:3808` always formats `row["gh_number"]` with `%d`, after `perform_write` at `:3807`. The current ledger contains a real supported unnumbered row (`releases.sql:525`). Cheapest fix: print the existing `label` with `%s`, preserving the numbered selector's `GH-N` label and using the GID for an unnumbered selector. Record a manual full-clone check of the actual command, including a numbered control; no new suite or gate machinery. Reversibility: Easy, a status-message correction without a writer/schema change.
  Observed input: `global_id=rmi-01M0H9CC0A81K3083ASEGK37HK`, `gh_number=NULL`, `doc_path=PROJECT/3-COMPLETED/GH-108-GH-111-EXECUTION-TODO.md` in `releases.sql:525`; that document exists. The source's final status expression raises `TypeError` for this row. A non-dry-run `roadmap repoint --gid rmi-01M0H9CC0A81K3083ASEGK37HK --doc-path PROJECT/3-COMPLETED/GH-108-GH-111-EXECUTION-TODO.md` reaches that expression after its writer call; end-to-end execution is **[Unverified — needs clone run]** in this turn.
  Affected scope: the success message for `roadmap repoint` selections whose `gh_number` is NULL; preserve the write protocol, selectors and numbered-row behavior.
  Falsifier: in a disposable full clone, that exact GID command must exit 0 and print the GID, and a numbered `--issue-num` control must exit 0 and retain `GH-N`; a current-code run already doing both would falsify the request.
  Probe: `PYTHONDONTWRITEBYTECODE=1 python3 -B -c 'import sys; from pathlib import Path; sys.path.insert(0,"utils/py"); import releases_app as a; r=next(r for r in a.parse_dump(Path("releases.sql").read_text())["roadmap_items"] if r["global_id"]=="rmi-01M0H9CC0A81K3083ASEGK37HK"); print("repointed GH-%d -> %s" % (r["gh_number"],r["doc_path"]))'` → exit 1, decisive output `TypeError: %d format: a real number is required, not NoneType`. This evaluates only the read-only dump parser and failing formatting expression, without invoking the writer.

- [Pass] **The GH-1016 resolver implements the approved boundary.** `utils/py/releases_app.py:5403` retains qualified slugs; `:5408` normalizes only case and `-`/`_`; `:5409` retains exact bare matching outside the one-row restriction; `:5412` still requires exact URL repository and number equality. A pure AST-selected function probe (`python3 -B` heredoc compiling only `_repo_from_issue_url` and `resolve_roadmap_identity`, with dictionaries and no repository/DB operations) exited 0: own AEGIS row `identity_valid=true`; same-name other owner and other repo `false`; two-repo tolerant match `false`; two-repo exact match `true`; mismatched number `false`; qualified slug `true`. Concrete same-number foreign URL `https://github.com/Other-Org/AEGIS-Sleuth-Slackbot/issues/221` remains invalid for origin `HiQS-Labs/AEGIS-Sleuth-Slackbot`. Keep this implementation.

- [Pass] **Init and onboard share the established parser and preserve precedence.** `utils/py/releases_app.py:2178` uses explicit slug, GitHub origin, then basename, and `:2187`/`:2194` write the same selected value to both identity fields. `relay-automation/xyz-releases-onboard.sh:99` imports from the resolved app directory, `:101` refuses an import/lookup process error, `:104` preserves explicit/default/fallback precedence, and `:110`/`:113` share the origin value while retaining explicit owner/name tracking fallback. The resolved Tier-2 candidate at `:79` is absolute after target-root canonicalization. The module uses standard-library imports and its CLI is protected by the `__main__` guard (`releases_app.py:6884`), so importing it does not run init. Probe `python3 -B -c 'import sys; sys.path.insert(0,"utils/py"); import releases_app; print("import_ok",releases_app.__file__)'` → exit 0, `import_ok .../rtl-wt.IfwF3T/utils/py/releases_app.py`. An AST-extracted helper-regex probe exited 0: HTTPS/SSH `test-org/foo.js.git` → `test-org/foo.js`, ordinary `happy-repo.git` → `test-org/happy-repo`, local path → `None`. Keep the shared-helper choice. Actual vendored onboarding was not executed in this turn.

- [Pass] **The committed implementation is surgical and the proof is falsifiable.** The local object comparison showed only the planned init/resolver/help hunks in `releases_app.py` and shared-parser/default/URL-base hunks in onboard; neither `test/` nor `validate.sh` changed. The added `TESTS-RESULTS/.../identity_check.py` is the permitted recorded manual check, not a registered suite: `:80`/`:85` cover foreign identity, `:68` calls the real wave qualification path with `dry_run=True`, and `:128`/`:150` exercise onboarding and read both slug fields. No duplicate writer, new parser, verb, schema, suite or registry entry was added. Keep this scope; the wave receipt proves qualified dry-run behavior, not a persisted ledger move.

- [Pass] **Receipts substantiate recorded red/green and gate claims, with their stated limits.** `TESTS-RESULTS/2026-10-10+GH-1016/provenance.jsonl:1` records red exit 1 at base, `:6`/`:9` record green exit 0, and `:8` attributes the disposable macOS full-clone gate to `1cb42805`. A read-only `python3 -B` JSON/hash/count audit exited 0: all six named hash comparisons matched (check, red, two green outputs, gate log); red `cases=15 passed=9` with the six specified failures; final green `cases=15 passed=15 failed=[]`; gate `nonempty_bytes=34183`, `gate_rc_counts={'0': 406}`. Decisive hash examples: check `0b3a34d2b35ab0b0b4144f1ec23d5699e7041d265b274d2b4ad62f9c4f2d2b1f`; gate log `7568d03031f7dcd55138c6ba3673d0442aa5c3c35c652494b9ad1035b01f4ce1`. `prepush-gate-1cb42805.log:891` says `pre-push: full gate GREEN in 871s — pushing.` This is retained execution evidence, not an independent rerun here; `log:6` explicitly distinguishes it from promotion evidence. Preserve that qualification and rerun the appropriate clone gate after any fix.

- [Pass] **CHANGELOG and rating are commensurate with the measured defect.** `CHANGELOG.md:3` describes the bounded resolver repair, shared origin parser, fallback and rollback compatibility accurately. `releases.sql:842` persists `70/60/50/70` with no override (sum 250). Plan's Rating and Measured sections distinguish one observed silent-reconcile incident from author-reported exit-6 symptoms; provenance `:2` retains the AEGIS observation and `:3`/`:4` retain recurrence searches. Priority 70/severity 60 fit a blocked downstream ledger without observed data loss; appeal 50 and cheapness 70 remain reasonable for these small existing-seam changes. Keep the rating and unknown-trend qualification; historical observations were not re-measured here.

VERDICT: FAIL
Basis: The GH-1016 changes match the approved plan and retained acceptance/gate evidence. The relay's explicit whole-file rule additionally brings the concrete pre-existing post-write `repoint --gid` crash into scope. Resolve that one small status-message defect and retain clone-only runtime proof before final approval; no broader identity redesign is requested.

Handing off to Producer (claude-a) — disposition the Should finding, make the smallest correction with recorded clone verification, then open round 2; go to the other window and say 'take your turn'.

### Producer · Round 1 · claude-a

- [Should] `roadmap repoint --gid` post-write crash: **Implemented** (`48013cbc`, `utils/py/releases_app.py` `cmd_roadmap_repoint` success message): `GH-%d` only when `gh_number is not None`, else the row's GID; write protocol/selectors untouched. In scope per the thread's whole-file rule; Reversibility Easy.
  Proof (recorded manual check, temp ledger copy, not a suite): `identity_check.py` section 5 runs your exact falsifier `roadmap repoint --gid rmi-01M0H9CC0A81K3083ASEGK37HK --doc-path PROJECT/3-COMPLETED/GH-108-GH-111-EXECUTION-TODO.md` plus the numbered control `--issue-num 1016`. Red at `9a923f3c`: 10/17, exit 1, `repoint-gid` rc=1 `TypeError: %d format: a real number is required, not NoneType` (`TESTS-RESULTS/2026-10-10+GH-1016/red-control-9a923f3c-r2.jsonl`). Green at `48013cbc`: 17/17, exit 0, stdout `repointed rmi-01M0H9CC0A81K3083ASEGK37HK -> ...` and `repointed GH-1016 -> ...` (`TESTS-RESULTS/2026-10-10+GH-1016/green-48013cbc.jsonl`). Hashes in `provenance.jsonl`.
- Focused suites at `48013cbc`: gh69 85/0, gh424, gh605-work-state, gh421, gh32 145/0, gh646 rc=0; gh280 223/0 in the gate clone with ambient `XYZ_HARNESS` unset (with the shell's `XYZ_HARNESS`=primary checkout it parks on the primary's `.tick/attempts/p1` and exits 8 at both `1cb42805` and `48013cbc` — environmental; the scrubbed pre-push gate passed it).
- Gates on the new code head `b76a693e` in the disposable gate clone: pre-push tier 2 (range classified releases) GREEN in 319s, then the full `RELAY_SELF_SUFFICIENCY_SKIP=1 ./validate.sh` exit 0, 406/406 suites rc=0, 980s, identity intact (`TESTS-RESULTS/2026-10-10+GH-1016/validate-full-b76a693e.log`, `provenance.jsonl` last line). Commits after `b76a693e` are docs/evidence only.

Round 2 question: is the Should resolved, and do the GH-1016 Pass findings still hold at the new head?

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
