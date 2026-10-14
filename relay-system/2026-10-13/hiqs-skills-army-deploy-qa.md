# RELAY · QA: HiQS skills deployment via skills-army-hq SOP
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-13.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 2

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
6. **Commit only the relay file** (`relay(hiqs-skills-army-deploy-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/hiqs-skills-deploy-evidence.md** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-hiqs-ai-resolve/e1cc774f-3230-482b-8148-e7d7414b4fa4/scratchpad/hiqs-skills-deploy-evidence.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-13
- Definition of Done: the HiQS skills (`hiqs-resolve`, `hiqs-scrape` added; `ai-catalog-update` re-sourced)
  were deployed strictly per the skills-army-hq SOP — script-only mutation, no hand edits/copies — and
  are byte-identical to their owning repo and linked into every enabled target.

### Operational envelope & non-goals
Single-operator local macOS skill deployment. READ-ONLY QA: do not run `intake.py`/`sync.py` with
`--apply`, do not edit anything outside this relay file. Non-mutating probes are allowed
(`readlink`, `diff -rq`, `git -C ... log/show`, `sync.py --status`, `intake.py list`), with output in
`$TMPDIR`. Do not demand new machinery or tests.

### Read
- The artifact above (evidence bundle with commands run, commits, parity, links, status, changelog).
- SOP: `/Users/noelsaw/git-pulse-sync/Deployed Skills/skills-army-hq/SKILL.md` and
  `/Users/noelsaw/git-pulse-sync/Deployed Skills/skills-army-hq/references/recovery.md`.
- Live state (read-only): `/Users/noelsaw/git-pulse-sync` (commits 73e432087, 0320259c4, e225b0c8b),
  owning repo `/Users/noelsaw/Documents/GH Repos/hiqs-ai-resolve/skills/{hiqs-resolve,hiqs-scrape,ai-catalog-update}`.

### Questions
1. Was every mutation performed by `intake.py`/`sync.py` (preview → apply), with no hand edits or manual
   copies/symlinks? Cite the changelog/commit evidence.
2. Is each deployed copy byte-identical to its owning repo source at the recorded commit 3afdd0c, and is
   `ai-catalog-update`'s recorded source now the owning repo instead of the stale `/private/tmp/hiqs-main`?
3. Do all 3 skills resolve through a symlink into `Deployed Skills/<name>` in all 6 enabled targets
   (agents, claude, codex, codex-compat, antigravity, grok-bot, zcode — check `targets.json`)?
4. Was the interrupted sync (sandbox EPERM) recovered per `recovery.md` (preview `recover`, then
   `--apply recover`), and is there any residual staging/pending state or half-written link?
5. Are the vendor commits scoped to just each skill's folder (GH-993), with the Pulse tree clean and not
   pushed by us (pulse pushes)? Flag anything that will block the hourly pulse.
6. Anything else in the SOP violated or left incomplete (e.g. prerequisites to record, catalog regeneration)?

Cite file:line or quoted command output for every `[Pass]`. Set STATUS: Approved if all pass.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
