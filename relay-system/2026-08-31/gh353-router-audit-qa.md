# RELAY · GH-353 router audit and prompt for target ROUTER.md ROADMAP.md frozen status during vendored updates
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-31.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-353-router-audit-and-prompt-for-target-router-md-roadmap-md-frozen-status-during-vendored-updates): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/router_audit.py** — the read-only path that
  `relay-drive.sh --artifact-file utils/py/router_audit.py` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-08-31
- Definition of Done:
  1. `utils/py/router_audit.py` accurately identifies releases mode (`releases.db` present or `ROADMAP_SOURCE=releases` in `.pdda-mode`) vs legacy mode.
  2. For releases mode repos, detects stale `ROUTER.md` files where `ROADMAP.md` is treated as active or `ROADMAP-DASHBOARD.md` is missing.
  3. For legacy mode repos, detects false frozen/dashboard references.
  4. `--fix` atomically and cleanly updates Role split and Startup sequence blocks in `ROUTER.md` while preserving custom repo sections.
  5. `relay-automation/xyz-sync.sh check` integrates router drift diagnosis.
  6. `skills/vendor-stack/SKILL.md` specifies the LLM check-and-prompt confirmation workflow.
  7. Automated tests in `test/gh353-vendored-router-audit.sh` pass cleanly and are registered in `validate.sh`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer — codex — Round 1

swept file: yes

Verdict: Changes requested

- [Blocker] Releases-mode validation is not scoped to the required blocks and can report a stale router as clean. A `ROADMAP-DASHBOARD.md` mention anywhere satisfies `has_dashboard`, while an omitted `ROADMAP.md = ...` role entry skips the frozen check entirely; startup detection only recognizes one exact numbered `Read ROADMAP.md` spelling (`.relay-artifacts/router_audit.py:71-103`). Fix: parse the bounded `## Role split` and `## Startup sequence` sections, require the dashboard and frozen/source-of-truth declarations in Role split, reject active roadmap reads in Startup, and add negative tests for mentions outside those sections, missing role entries, case/format variants, and absent Startup guidance.
- [Blocker] Legacy-mode validation does not detect the false frozen references required by DoD 3. It only reports a dashboard mention when the dashboard file is absent, never inspects a frozen/legacy `ROADMAP.md` declaration, and therefore treats a legacy repo with a leftover dashboard file—or a frozen declaration alone—as clean (`.relay-artifacts/router_audit.py:104-110`). Fix: reject releases-only dashboard/frozen/source-of-truth declarations based on mode regardless of filesystem leftovers, then test both false-clean cases.
- [Blocker] `--fix` can return success without producing a clean router and can rewrite custom sections. Releases remediation never creates a missing Role split, fails to append a dashboard at EOF when the section lacks matching entries, and rewrites every matching numbered roadmap-read line globally rather than only Startup (`.relay-artifacts/router_audit.py:132-195`). Legacy remediation likewise deletes/replaces matching lines globally and hard-codes step `3`, losing original numbering/text (`.relay-artifacts/router_audit.py:196-225`). Fix: locate or create bounded sections, mutate only their owned entries while preserving all other bytes, handle section-at-EOF, preserve file metadata during atomic replacement, and re-run `audit_router` before returning success; cover missing/last sections and custom lookalike prose in tests.
- [Should] An unreadable `ROUTER.md` accumulates a reason but leaves `drift=False`, so `--check` prints `ok` and `--fix` says already synchronized (`.relay-artifacts/router_audit.py:64-69`, `.relay-artifacts/router_audit.py:120-121`, `.relay-artifacts/router_audit.py:262-267`). Fix: distinguish audit failure from clean state, exit nonzero without offering remediation, and test the failure path.
- [Blocker] The documented confirmation prompt is releases-specific even when the audit reports legacy drift, telling the user that releases mode is enabled and proposing the opposite transformation (`skills/vendor-stack/SKILL.md:109-115`). Fix: consume `--json` (or otherwise branch on reported mode/reasons) and provide separate releases→frozen/dashboard and legacy→active/no-dashboard prompts before `--fix`.
- [Should] The registered test covers only canonical happy paths and broad substring outcomes (`test/gh353-vendored-router-audit.sh:43-146`; registration: `validate.sh:425`), so every false-clean/remediation case above can pass unnoticed. Extend that specific test with the regression matrix named in the findings. Test execution was intentionally not run in this reviewer-only turn.
- [Pass] Static integration exists: `xyz-sync.sh check` invokes the audit for each selected target and surfaces nonzero diagnostics (`relay-automation/xyz-sync.sh:454-461`), and the specific GH-353 test is registered (`validate.sh:425`).

Pre-existing defects: present across the swept artifact; no portion of `.relay-artifacts/router_audit.py:1-272` was excluded.

Handing off to Producer — go to the claude-a window and say "take your turn".

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
