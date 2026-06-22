# RELAY · shakedown SKILL.md review (single round trip)
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 1

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, Gemini)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions. You are the **Reviewer (Codex)**.
1. **Read this whole file** (header, Setup, Ground rules, the Producer's Round 1 block).
2. **Review the artifact** named in Setup against the Definition of Done. Read the real file at the repo-relative path `relay-system/2026-06-21/shakedown-SKILL.md` (your CWD is the harness repo root) and cite `SKILL.md:line`.
3. **Append ONE block** at the very bottom, directly above the marker line. Header it `### Round 1 · Reviewer · Codex · 2026-06-21`. Grade every finding `[Blocker]` / `[Should]` / `[Nit]` / `[Pass]`, each with a concrete proposed fix. Set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit the artifact — you only append findings here. Basis is `textual only` (non-executable doc).
4. **Update the header:** set `STATUS: Closed` (single round trip — no Producer reply turn) and leave `NEXT: —`.
5. This is the only writer of the relay file this turn; the harness commits it. Then stop.

## Setup
- Artifact under review: `relay-system/2026-06-21/shakedown-SKILL.md` (a verbatim copy of `utils/shakedown/SKILL.md` from the `giant-brains-claude-skills` repo — staged here so it is readable inside the harness workspace).
- True home of the artifact: `giant-brains-claude-skills/utils/shakedown/SKILL.md`.
- Definition of Done: the skill is correct, internally consistent, conforms to the giant-brains house style (frontmatter line 1, ASCII punctuation, observable triggers, a no-escalate counter-example, brevity), and — critically — its documented mechanics actually work: the bundled scripts it tells users to run must exist, and the path-discovery advice it preaches must hold up on the skill itself.
- Producer: Claude (Opus 4.8)   ·   Reviewer: Codex (codex exec, gpt-5)
- Handoff: cli-driven (codex), single round trip
- Started: 2026-06-21

## Ground rules
1. This file is the single source of truth. The two agents never share memory.
2. One turn = one block appended at the bottom, above the marker. Never edit earlier turns.
3. Stay tight — findings are bullets, not essays.
4. The Reviewer never edits the artifact; it proposes graded findings with concrete fixes and sets a verdict.
5. Grade every finding: `[Blocker]` must-fix to ship · `[Should]` strong rec · `[Nit]` optional · `[Pass]` checked and sound.
6. Evidence contract: this is a non-executable doc, so verdict `Basis:` is `textual only` — judged by reading the artifact text against the DoD and the Producer-verified facts below. Do not claim to have run anything.

## Roles
- **Producer** — Claude: staged the artifact and the review brief; will carry findings back to the operator.
- **Reviewer** — Codex: reviews against the DoD, proposes graded findings, sets a verdict.

---
## Log

### Round 1 · Producer · Claude · 2026-06-21
**Did:** Staged `utils/shakedown/SKILL.md` for an independent single-pass review. shakedown is a skill whose job is to *harden other script-calling skills* against path-discovery bugs — so it is fair to hold it to the standard it preaches.
**Producer-verified facts (you cannot see the giant-brains repo from here — trust these, they were checked with `ls` + `find` on 2026-06-21):**
- The real skill folder `utils/shakedown/` contains **only `SKILL.md`** — there is **no `scripts/` subdirectory**, and **no `audit.sh` or `harness.sh`** anywhere in the skill. Yet the doc's entire "The run" section instructs the user to call `bash "$SK/scripts/audit.sh"` and `bash "$SK/scripts/harness.sh"`. Weigh whether the skill is shippable in this state.
**Review this — focus areas:**
- **Missing bundled scripts.** Given the verified fact above, what is the correct severity? The skill's core mechanism (static audit + live harness) depends entirely on two scripts that don't exist in the folder.
- **Does it pass its own test? (dogfooding).** The skill preaches absolute-path self-location and warns against CWD-relative paths. Scrutinise its own discovery snippet — `SK=$(dirname "$(find "$HOME/.claude/skills" ".claude/skills" -path '*shakedown/SKILL.md' 2>/dev/null | head -n1)")` — and the `bash "$SK/scripts/<name>.sh"` calls. Any path bug, fragile `find` (e.g. a missing search root), or unset-`$SK` failure mode in the very skill that hunts path bugs?
- **House style & calibration.** Frontmatter on line 1, ASCII punctuation, observable triggers, a genuine no-escalate counter-example, brevity. Does it have the suite's calibration (it currently has no counter-example — is that a gap)?
- **Method soundness.** Is the "found vs ran-clean" distinction, the exit-code contract, and the "anchor the verdict to the worst finding" rule coherent? Any gap in the scenario matrix or the read-only contract?
- **Report defaults.** Per-repo `SHAKEDOWN/` vs central, propose-not-patch — sensible, or surprising?
**Verification:** N/A — non-executable artifact; facts above are from `ls`/`find` on the real skill folder.
**Open question:** Is the missing-scripts state a **Blocker** (doc references vaporware), or is it acceptable as a spec-ahead-of-implementation doc that should at least say so?
**Commit:** harness-managed.

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
