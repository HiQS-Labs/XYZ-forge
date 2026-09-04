# RELAY · QA: debug-mantra plan-target ladder
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-03.
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
6. **Commit only the relay file** (`relay(debug-mantra-plan-ladder-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/debug-mantra/SKILL.md` (as committed at `a3185e38` on `development`; the full updated file is in your worktree at that path — read it in full)
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-03
- Definition of Done: the plan-target ladder addition is Approved if — (a) it contradicts none of the four core mantras or the Operating rules; (b) each of the four pivots is a faithful transposition of its step, not a new discipline; (c) the frontmatter description remains one valid YAML scalar and the added proactive trigger cannot fire on ordinary doc edits; (d) every cited reference resolves for a reader of THIS repo; (e) the whole-file sweep found no pre-existing defect the change worsens. Any [Blocker]/[Should] unaddressed = Changes requested.

## Context — what changed and what to adjudicate

The commit below adds a "plan mode" to the debug-mantra skill in one file (no new skill): a frontmatter trigger for `/debug-mantra plan` and proactive firing on acceptance-criteria work, a pivot table under "When the target is a plan, not a bug", and the plan-only rule (falsification at plan time is specified, not performed; every criterion must name where its red evidence lands). You cannot run git in this turn, so the diff is embedded verbatim:

````diff
commit a3185e38 skill(debug-mantra): plan-target ladder — same four mantras, per-step plan pivots

diff --git a/skills/debug-mantra/SKILL.md b/skills/debug-mantra/SKILL.md
index b8ca083d..69afa355 100644
--- a/skills/debug-mantra/SKILL.md
+++ b/skills/debug-mantra/SKILL.md
@@ -1,11 +1,11 @@
 ---
 name: debug-mantra
-description: Four-mantra debugging discipline — reproduce, trace the fail path, falsify the hypothesis, cross-reference every breadcrumb. Recite the mantra block verbatim at the start of any debugging session, then apply the four steps in order before proposing any fix. Trigger on /debug-mantra and proactively whenever debugging starts — user reports a bug, says something is broken/throwing/failing, asks to debug/diagnose/investigate an issue, pastes a stack trace or error log, or asks an attribution question ('where is this coming from?', 'what posts/triggers/generates this?', 'why is X appearing?') where the answer is an unknown source to find, not just a crash to fix. Adapted from: https://github.com/thananon/9arm-skills
+description: Four-mantra debugging discipline — reproduce, trace the fail path, falsify the hypothesis, cross-reference every breadcrumb. Recite the mantra block verbatim at the start of any debugging session, then apply the four steps in order before proposing any fix. Trigger on /debug-mantra and proactively whenever debugging starts — user reports a bug, says something is broken/throwing/failing, asks to debug/diagnose/investigate an issue, pastes a stack trace or error log, or asks an attribution question ('where is this coming from?', 'what posts/triggers/generates this?', 'why is X appearing?') where the answer is an unknown source to find, not just a crash to fix. Also trigger on /debug-mantra plan, and proactively when writing or reviewing the acceptance criteria of a plan, capture doc, or marathon plan — apply the same four mantras through the pivots in 'When the target is a plan, not a bug'. Adapted from: https://github.com/thananon/9arm-skills
 ---
 
 # Debug Mantra
 
-Four-step discipline for any debug session. Recite verbatim, then apply in order.
+Four-step discipline for any debug session. Recite verbatim, then apply in order. When the target is a plan rather than a bug, the same four steps apply read through the pivots in [When the target is a plan, not a bug](#when-the-target-is-a-plan-not-a-bug).
 
 ## Recite this — verbatim, as the first thing in your first response
 
@@ -63,6 +63,21 @@ Maintain a running **ledger** of every experiment in this session. Each entry: w
 
 ---
 
+## When the target is a plan, not a bug
+
+Invoked as `/debug-mantra plan`, or proactively when writing or reviewing the acceptance criteria of a plan, capture doc, or marathon plan. The four mantras apply unchanged and the recital stands verbatim — "the issue — or the artifact" includes the plan's own evidence. Each step is read through its pivot:
+
+| Step | Debug reading | Plan pivot |
+|---|---|---|
+| 1. Reproduce | Runnable repro of the failure. | **Measured ground truth at plan time.** Every count, `file:line`, and live-state claim in the plan is re-run now, not remembered — the "measured, not assumed" evidence table (#419) is the shape. A recalled repo state is hypothesis-zero. |
+| 2. Fail path | Trace the code that breaks. | **Trace the real path the plan changes**, before proposing: walk it and enumerate every caller and surface it touches. A criterion about a path nobody traced is a guess wearing a checkbox. |
+| 3. Falsify | Disprove the root-cause hypothesis. | **Falsify the acceptance criteria.** Each criterion must name how it fails — a criterion that cannot fail is decorative, and one an empty input satisfies passes vacuously. Specify the red control *and where its evidence will land* (`test/baselines/` negative-control pattern). Rank 3–5 alternatives for the load-bearing design choice and name the strongest counterargument (#419's open-question block is the pattern). |
+| 4. Breadcrumbs | Session experiment ledger. | **Recon ledger.** Record the greps, counts, and probes that grounded the plan, citable from the plan or its capture doc. Before finalizing, walk the ledger against what is already shipped — a plan resting on a stale claim (feature already exists, path already changed) inherits the stale claim. |
+
+**The plan-only rule, and why pivot 3 is the strictest:** at plan time falsification is *specified*, not *performed* — strictly weaker evidence than a red control you have watched fire. That gap is why each criterion must name a destination for its red evidence: a planned red control that is not witnessed when implemented is a promise, not a control. Plan reviews have caught criteria "satisfiable by an empty pre-created file" and "satisfiable by a print statement while the defect persisted" — both passed review as written.
+
+Scale rigor as ever: a one-line fix's plan needs a confirming observation, not the full table; a marathon or large-refactor plan needs every pivot. For large refactors this is the SOP "Arc planning" discipline applied debug-mantra-first.
+
 ## Operating rules
 
 - Recite the mantra block **once** per debug session, in your first response. Do not re-recite mid-session.
````

Adjudicate these, concretely, citing file:line from `skills/debug-mantra/SKILL.md`:

1. **Contradiction check** — does the new section (`:66-79` region) contradict "Recite verbatim" (`:10-20`) or any Operating rule (`:81-94`)? In particular: is reading the same recital through plan pivots coherent, or does it need its own recital?
2. **Pivot fidelity** — for each of the four pivot rows: is it a faithful transposition of its step (1 reproduce, 2 fail path, 3 falsify, 4 breadcrumbs), or does any row smuggle in a different discipline or drop a load-bearing element of the original?
3. **Frontmatter safety** — is the edited `description:` still a single valid YAML scalar (no new `: ` sequence that breaks naive frontmatter parsers), and is the proactive trigger narrow enough that it cannot reasonably fire on ordinary doc edits?
4. **The plan-only rule** — is "specified, not performed ... name a destination for its red evidence" actionable and consistent with this repo's red-control discipline (`test/baselines/` negative-control pattern, SOP §13 "a green gate without a witnessed red control is not evidence")? Or is it unenforceable prose?
5. **Reference hygiene** — do all cited targets resolve for a reader of THIS repo (#419, `test/baselines/`, SOP "Arc planning")? Was any bare upstream `GH-<n>` dead end introduced?
6. **Markdown mechanics** — does the intro's anchor link match the new heading text; does the pivot table render (no broken pipes/escapes)?

Sweep the WHOLE file (GH-268): pre-existing defects in the touched file are in scope. Output graded findings ([Blocker]/[Should]/[Nit]/[Pass]) with file:line, a literal `swept file: yes|no` line, and a Verdict.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · r1

swept file: yes

- [Blocker] `skills/debug-mantra/SKILL.md:3` is not valid YAML: a standard YAML parser rejects the unquoted plain scalar at `Adapted from: https://…` (`mapping values are not allowed`), so the Definition of Done's single-valid-scalar requirement fails. Fix: make `description` an actual single scalar (for example a folded `>` scalar, or quote the whole value), then parse the frontmatter with a YAML parser.
- [Should] `skills/debug-mantra/SKILL.md:72,74` cite `#419` and `#419's open-question block` without a repo-resolving link or path. This skill is read locally as well as rendered on GitHub, so the reader cannot follow those references reliably. Fix: link both to `../../PROJECT/1-INBOX/GH-419-MARATHON-RULE-ENFORCEMENT.md` (with a useful fragment for the cited table/block) or name that resolvable repo path inline.
- [Pass] The unchanged recital and operating-rule contract remain coherent with the plan reading: it explicitly retains the verbatim recital and applies the four steps in order through pivots, rather than introducing a second recital. `skills/debug-mantra/SKILL.md:8,10-18,68,83-90`.
- [Pass] The four pivots faithfully transpose the corresponding disciplines: observed ground truth, path tracing, disproof plus alternatives, and a citable ledger. `skills/debug-mantra/SKILL.md:22-62,72-75`.
- [Pass] The proactive trigger is limited to writing or reviewing *acceptance criteria*, not ordinary documentation edits; the heading link slug and three-column table are mechanically well-formed. `skills/debug-mantra/SKILL.md:3,8,66,70-75`.
- [Pass] The plan-only rule is actionable and aligned with the repo's red-control posture: it distinguishes specified from witnessed evidence and requires a red-evidence destination. `skills/debug-mantra/SKILL.md:74,77`.

Verdict: Changes requested

Handing off to Producer — go to the Producer window and say “take your turn”.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
