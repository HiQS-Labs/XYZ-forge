# RELAY · gh1159 PR #1163 final QA (agy)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
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
6. **Commit only the relay file** (`relay(gh1159-pr1163-agy-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **gh1159-agy-brief.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-10-18

### Artifact — gh1159-agy-brief.md
```
# QA brief: PR #1163 / GH-1159 — per-repo qualification setting in .merge-cleanup.json

Goal: independent final QA of PR #1163 (head 894cb809) before an operator takeover. The PR was built in a cloud Claude session with Claude-only review. You are the first non-Claude reviewer.

Requirement (issue #1159):
- One optional `qualification` key in the existing `.merge-cleanup.json`, read by the existing resolver `resolve_merge_policy`. It fails closed.
- Forge commits `full_suite: promotion` and today's behavior stays byte-identical.
- A repo without the key never gets a Forge-only workflow, gate or branch in its batch issue.
- Non-goals: no ci.yml, wave-reconcile.yml or AGENTS.md change, and no writes into vendored repos.

Operational envelope: a local developer CLI (merge-cleanup) run by agents against one repo at a time. Grade at commensurate complexity. **This repo forbids new tests without per-case operator approval (GH-831).** A new test is a finding, never a request. Manual checks under `TESTS-RESULTS/` are the allowed form.

Read:
- `git diff origin/development...HEAD` restricted to `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, `skills/2-daily/merge-cleanup/scripts/batch_record.py`, `.merge-cleanup.json`, `test/gh436-merge-cleanup.py`, `relay-automation/xyz-vendor.sh` and `skills/2-daily/merge-cleanup/SKILL.md`
- `PROJECT/2-WORKING/GH-1159-QUALIFICATION-SETTING.md`
- `TESTS-RESULTS/2026-10-18+GH-1159/` (README, qualification-checks.py and .log)

Questions:
1. **Forge parity.** With Forge's committed key, is `finalize_sweep_inputs` output byte-identical to development for both the Small-gate case and the deferred full-gate case? Name any field that changed (for example the new `full_suite` key in `sweep_inputs`, or the `--ref` that now ignores `rec["integration"]`) and whether it matters.
2. **Foreign repo.** With no key, can any path still print `wave-reconcile.yml`, `validate.sh`, `--ref development` or a Forge gate? Check `script_block` rendering, the exit-4 hint in `main()`, and old batch records written before this change.
3. **Fail-closed scope.** `resolve_merge_policy` runs at startup for every mode. Does an invalid `qualification` now stop runs that never sweep (`--scan-only`, `--retire-published-pr`, `--record-sweep`, teardown-only)? Is that the intended fail-closed behavior or over-reach? Separately, `_record_batch_outcomes` catches `ValueError` mid-run. Is that consistent?
4. **Rollout hazard.** merge-cleanup is also deployed globally (Skills Army HQ) and vendored. Once Forge's `.merge-cleanup.json` carries the new key, does an older deployed `merge_cleanup.py` refuse Forge's file, breaking `/merge-cleanup` in Forge until re-vendored? Does the PR document this, and what is the smallest mitigation (ordering or a doc line)?
5. **per_batch injection and grouping.** `command = f"{clone} && ( {declared} )"`. Is the grouping correct? Is `declared` repo-committed config, so trusted at the same level as the repo's own scripts?
6. **Scope.** Is there any machinery, abstraction or test beyond the requirement? Is the test change only an adapted existing call?

For every finding give a severity (Blocker, Should, Nit or Pass) and a `file:line` citation. Every Blocker or Should that requests a behavior change must carry `Observed input:`, `Affected scope:` and `Falsifier:` lines.
```
- Definition of Done: the #1159 acceptance criteria hold, there is no Blocker, and every Should has a falsifier.

### Reviewer block template (copy exactly; `VERDICT:` and `Basis:` must each start at the beginning of a line, with no bold)

```
### Round 1 — Reviewer (agy)
Findings:
- [Severity] file:line — finding
  Observed input: ...
  Affected scope: ...
  Falsifier: ...
Answers: 1) ... 2) ... 3) ... 4) ... 5) ... 6) ...
VERDICT: PASS
Basis: <one line>
```
Use `VERDICT: CHANGES` if there is any Blocker or Should. On PASS set `STATUS: Approved`; otherwise hand back to claude-a.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
