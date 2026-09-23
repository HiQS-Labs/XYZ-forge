# RELAY · PR 765 final QA: start marathon and root PARKED
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-23.
-->

NEXT: done
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
6. **Commit only the relay file** (`relay(gh765-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: skills/2-daily/start-marathon/SKILL.md
- Review target: draft PR #765, `origin/development...HEAD` at `fe2504b7`; inspect the full changed files, especially `PARKED/README.md`, `ROUTER.md`, `AGENTS.md`, `skills/2-daily/workhorse/SKILL.md`, `skills/1-hourly/unstuck/SKILL.md`, `skills/1-hourly/standup/{SKILL.md,collect.sh,triage.py}`, tests and `PROJECT/2-WORKING/GH-762-START-MARATHON-SKILL.md`.
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-09-23
- Operational envelope: local macOS skill routing and repo governance; no marathon dispatch or runtime rewrite. Read-only review; no `validate.sh`, `test/*.sh`, pytest, or executable fixtures in the relay worktree. Use narrow static inspection and the committed evidence. Keep any scratch under `.relay-scratch/` after setting `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR` there.
- Definition of Done: decide whether this PR is content-ready for review, with the existing full-gate baseline failures disclosed and tracked separately in #764. Explicitly answer:
  1. Does ambiguous “marathon” route to preparation while explicit fire still requires the operator gate, and do primary/secondary routes cover intake, contracts, plan QA, disjoint lanes, YAML, preflight and dry-run?
  2. Are recovery loops bounded and current-goal blockers kept in the active plan, without bypassing lane attempt caps?
  3. Is root `PARKED/` the coherent first home for incidental out-of-scope observations, with triage promotion into issue-first `1-INBOX` and RELEASES, without undermining formal PDDA intake? Trace writers and readers.
  4. Does standup still degrade on malformed *machine* records while ignoring ordinary general PARKED notes and checklists? Check `collect.sh`, `triage.py`, the changed fixture, and new test assertion.
  5. Are installed aliases, nudge routes, and direct callers compatible? Is the diff surgical and free of public PII? Identify any concrete blocker to marking the draft ready for review apart from the disclosed full gate.
  Give `VERDICT: PASS` or `FAIL` with `Basis:` and cited findings. `STATUS: Approved` only for PASS; otherwise hand back specific repairs.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer (agy) — r1
VERDICT: PASS
Basis: PR #765 is content-ready for review. Ambiguous "marathon" requests route cleanly to preparation without auto-dispatch; primary/secondary workflows cover intake, contracts, independent plan QA, disjoint lanes, YAML, preflight, and full-plan dry-run; recovery loops are bounded by workhorse/unstuck and lane attempt caps; root PARKED/ provides a coherent first home for incidental findings while preserving formal PDDA intake on promotion; standup lens 8 degradation is maintained for malformed machine records while ignoring general notes/checklists; compatibility across aliases, hooks, and callers is verified; and the full-gate baseline failures are properly disclosed and tracked in #764.

- [Pass] **Ambiguous marathon routing & explicit fire gate (Question 1):** `skills/2-daily/start-marathon/SKILL.md:3-8` ("Route an ambiguous bare 'marathon' here; ask which arc only if live evidence cannot identify one. Explicit fire/execute requests use the confirmed marathon command after this preparation") and `:30-33` ("A bare 'marathon' is never implicit authorization to dispatch") establish that bare requests prepare rather than fire. `relay-automation/hooks/skill-nudge.sh:56-58,64` correctly matches bare `marathon` and variants to nudge to `start-marathon`. `.claude/commands/pre-marathon.md:3-5, 18-20` retains the operator confirmation boundary before any execution.
- [Pass] **Primary and secondary preparation workflows (Question 1):** `skills/2-daily/start-marathon/SKILL.md:20-29` defines both paths. Primary follows Steps 0–6 covering missing capture generation with existing writers (`:187-216`), contract reconciliation and independent plan QA (`:217-233`), disjoint lane and wave formation (`:272-277`), umbrella tracking issue (`:336-366`), and direct candidate preflight plus `marathon.sh --plan <file> --dry-run` (`:253-297`). Secondary verifies existing docs, runs smoke checks, planner `--check`, and YAML dry-run without rewriting sound plans (`:25-29, 292-296`).
- [Pass] **Bounded recovery & blocker discipline (Question 2):** `skills/2-daily/start-marathon/SKILL.md:75-78` bounds recovery: "diagnose a concrete failure with `workhorse`, then use `unstuck` if a session stalls or repeats a step without new evidence. Re-run the affected check once after a material correction. If the same condition persists, report the blocker; do not bypass a deterministic verdict, exceed `LANE_MAX_ATTEMPTS`, re-fire a parked lane, or fabricate readiness." Current-goal blockers must stay in active plans (`skills/2-daily/start-marathon/SKILL.md:74`, `PARKED/README.md:6`, `AGENTS.md:242`).
- [Pass] **Root PARKED coherent intake & reader/writer tracing (Question 3):** `PARKED/README.md:3-6` establishes root `PARKED/` as the holding area for incidental agent findings outside the current task before triage, distinguishing it from the formal RELEASES queue (`:23-25`). Writers traced: `AGENTS.md:237-242`, `ROUTER.md:40-47`, `skills/2-daily/workhorse/SKILL.md:30, 45, 67`, `skills/1-hourly/unstuck/SKILL.md:123-124`, `skills/2-daily/start-marathon/SKILL.md:71-74`, and `/standup` machine records. Readers traced: human triage for notes, and standup `collect.sh`/`triage.py` for machine checks. Formal PDDA intake is strictly preserved upon promotion via issue-first `PROJECT/1-INBOX/GH-*.md` capture and `releases roadmap add` (`PARKED/README.md:14-18`). Follow-ups #763 and #764 in `PARKED/2026-09-23-gh762-followups.md` cite their promoted captures.
- [Pass] **Standup lens 8 machine degradation vs general notes (Question 4):** `skills/1-hourly/standup/collect.sh:1119-1120` (`if not line_str.startswith("- [") or " — check: " not in line_str: continue`) and `skills/1-hourly/standup/triage.py:225` (`PARK_RE = re.compile(r"^- \[([^\]]+)\].* — check: ")`) restrict parsing to machine records. `skills/1-hourly/standup/fixtures/all-degraded/PARKED/bad.md:1` retains `— check: {"kind": }` to prove malformed machine objects still degrade lens 8, while `test/gh77-standup-triage.sh:308-323` confirms that generic markdown checklists leave lens 8 healthy (`status: ok`, 0 candidates, 0 suppression entries).
- [Pass] **Installed aliases, callers, and compatibility (Question 5):** `skills/2-daily/start-marathon/install.sh:43-54` maintains backward compatibility for `marathon-triage` (replacing dangling symlinks while preserving live foreign links, verified in `test/gh678-installer-live-links.sh:39-61`). Direct callers updated: `.claude/commands/pre-marathon.md:6-7, 20`, `skills/3-weekly/10days/SKILL.md:273`, `skills/3-weekly/radar/SKILL.md:16, 512, 532`, `skills/2-daily/workhorse/SKILL.md:30, 45, 67`, `skills/1-hourly/unstuck/SKILL.md:123-124`, `skills/1-hourly/standup/SKILL.md:129-132`.
- [Pass] **Surgical diff, PII check, and baseline gate disclosure (Question 5):** Diff inspection confirmed changes are surgical across the 31 touched files with zero personal credentials, private keys, or foreign user paths. Baseline macOS gate failures (`gh142`, `gh605`, `gh549`) reproduced on `development` are openly disclosed and tracked in `PROJECT/1-INBOX/GH-764-BASELINE-GATE-FAILURES.md` and `PROJECT/2-WORKING/GH-762-START-MARATHON-SKILL.md:43, 115-117`. There are no content blockers to marking draft PR #765 ready for review.

swept file: yes. No pre-existing defects found across all touched files (`skills/2-daily/start-marathon/SKILL.md`, `skills/2-daily/start-marathon/install.sh`, `skills/2-daily/start-marathon/agents/openai.yaml`, `.claude/commands/pre-marathon.md`, `relay-automation/hooks/skill-nudge.sh`, `PARKED/README.md`, `PARKED/2026-09-23-gh762-followups.md`, `ROUTER.md`, `AGENTS.md`, `skills/1-hourly/standup/*`, `skills/2-daily/workhorse/SKILL.md`, `skills/1-hourly/unstuck/SKILL.md`, `skills/3-weekly/10days/SKILL.md`, `skills/3-weekly/radar/SKILL.md`, `PROJECT/2-WORKING/GH-762-START-MARATHON-SKILL.md`, `test/gh678-installer-live-links.sh`, `test/gh77-standup-triage.sh`, `test/xyz-harness-hooks.sh`).

relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
