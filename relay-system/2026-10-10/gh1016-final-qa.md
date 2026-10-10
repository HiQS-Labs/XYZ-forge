# RELAY · GH1016 final QA: repo slug identity
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-10.
-->

NEXT: Reviewer
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
- Artifact under review: the committed implementation diff `9a923f3c..1cb42805` on branch `fix/XYZ-forge-gh1016-repo-slug-identity-2026-10-10`, covering `utils/py/releases_app.py` (`resolve_roadmap_identity` and `cmd_init` plus `--slug` help) and `relay-automation/xyz-releases-onboard.sh`. Grade it against the approved plan `PROJECT/2-WORKING/GH-1016-REPO-SLUG-IDENTITY.md` (Plan, Acceptance map, Implementation evidence), the plan-QA thread `relay-system/2026-10-10/gh1016-plan-qa.md`, `CHANGELOG.md` (top entry), and evidence `TESTS-RESULTS/2026-10-10+GH-1016/provenance.jsonl`, `TESTS-RESULTS/2026-10-10+GH-1016/identity_check.py`, `TESTS-RESULTS/2026-10-10+GH-1016/red-control-9a923f3c.jsonl`, `TESTS-RESULTS/2026-10-10+GH-1016/green-gate-1cb42805.jsonl` and `TESTS-RESULTS/2026-10-10+GH-1016/prepush-gate-1cb42805.log`. Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1016
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
