# RELAY · GH1016 plan QA: repo slug identity
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
6. **Commit only the relay file** (`relay(gh1016-plan-qa-repo-slug-identity): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1016-REPO-SLUG-IDENTITY.md` (the plan; read it in full), checked against the source it cites: `utils/py/releases_app.py` (`cmd_init` ~2171-2205, `_github_slug_from_origin` ~2082, `tracking_token_to_url` ~2093, `_origin_repo_identity` ~5385, `resolve_roadmap_identity` ~5397, its callers ~3944/~4067/~5112/~5493, `load_dump` ~6059), `utils/py/wave_reconcile.py` `update_roadmap_entry` ~1467-1492, `utils/py/express.py` ~665-677, `utils/py/work_connectors/__init__.py` ~144-164, `relay-automation/xyz-releases-onboard.sh` ~95-116, `utils/pdda/pdda-install.sh` ~772-775, and the recorded manual check `TESTS-RESULTS/2026-10-10+GH-1016/identity_check.py` + `red-control-9a923f3c.jsonl`. Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1016
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-10
- Definition of Done: the plan is approved for implementation when (a) every recon claim matches the cited source at base `9a923f3c`, (b) the chosen fix makes an AEGIS-shaped ledger (bare `aegis-sleuth-slack-bot`, origin `HiQS-Labs/AEGIS-Sleuth-Slackbot`) resolve its own rows `identity_valid True` while foreign-repo rows stay invalid, (c) it extends the existing resolver and `cmd_init` writer without a second writer, new verb, schema change, or new test suite (AGENTS.md *No new tests*, GH-831), (d) acceptance checks are falsifiable with a red control, and (e) the rating 70/60/50/70 and its rationale are grounded.

## Operational envelope

Local, single-operator CLI ledger (`releases.db` + `releases.sql`), one `repos` row per ledger in practice, vendored into a few consumer repos. Grade against the stated requirements and commensurate complexity; do not demand enterprise multi-tenant threat models, new suites, new gate machinery, or a migration framework. Per AGENTS.md GH-831, a request for a new test file is itself out of scope; verification is existing suites plus the recorded manual check under `TESTS-RESULTS/2026-10-10+GH-1016/`.

## Questions

1. Are the recon claims grounded? In particular: is `cmd_init` the only place a slug value originates (`load_dump` only copies), are all ownership decisions routed through `resolve_roadmap_identity`, and is there really no existing verb that rewrites `repos.slug`?
2. Is the tolerant bare match safe? The plan's normalisation is `casefold()` with `-` and `_` removed, applied only when the slug has no `/` and `len(repo_rows) == 1`, with validity still requiring `url_repo == origin_repo` byte-exact. Can you construct a concrete foreign-repo row (paste it) that becomes valid under this rule? Is the one-row guard correct given every caller builds `repo_rows` from all `repos` rows?
3. Is `_github_slug_from_origin` (github-only) the right source for the new `cmd_init` default instead of `_origin_repo_identity` (any host; parses local-path origins into a bogus owner/name)? Does writing `owner/name` to `repos.slug` and `settings.repo_slug` for NEW ledgers break any reader you can find (dump, `tracking_token_to_url`, `releases_cycle.py`, tests under `test/` that call `init` without `--slug` in a fixture that has a github origin)?
4. Is the onboard-script change (move the existing `ORIGIN_URL`/`GH_BASE` parse above Step 1 and default the slug from it) necessary and minimal, or should it be dropped as scope creep?
5. Is choosing the resolver-side match over a receipted repair verb correct, given `repos.slug` is part of `business_digest` and `settings set` refuses `repo_slug`? Is the stated non-goal (legacy folder names that differ by more than case/separators) acceptable?
6. Are the acceptance checks falsifiable? The manual check scores 7/11 (exit 1) on the `9a923f3c` tree; do its cases actually exercise the reported failure path (`wave_reconcile.update_roadmap_entry` logging "No qualified owned roadmap row")? Is anything missing from the acceptance map?
7. Is the rating `rated 70/60/50/70` (pri/sev/appeal/effort) and its recurrence statement grounded in the evidence cited?

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) with `file:line` citations; any behaviour-change request carries `Observed input:` / `Affected scope:` / `Falsifier:`. End with `VERDICT: PASS|FAIL` and a `Basis:` line, and set `STATUS: Approved` only on PASS. Review only: do not run `validate.sh`, `test/*.sh`, pytest or fixtures in the relay worktree; read-only probes under `$TMPDIR` are fine. Only edit this relay file.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
