# RELAY · shakedown SKILL.md review (single round trip)
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: —
STATUS: Closed
ROUND: 1 / 1

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, Gemini)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions. You are the **Reviewer (Codex)**.
1. **Read this whole file** (header, Setup, Ground rules, the Producer's Round 1 block).
2. **Review the artifact** named in Setup against the Definition of Done. Read the real file at the repo-relative path `relay-system/2026-06-21/shakedown-SKILL.md` (your CWD is the harness repo root) and cite `SKILL.md:line`.
3. **Append ONE block** at the very bottom, directly above the marker line. Header it `### Round 1 · Reviewer · Codex · 2026-06-21`. Grade every finding `[Blocker]` / `[Should]` / `[Nit]` / `[Pass]`, each with a concrete proposed fix. Set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit the artifact — you only append findings here. Basis is `textual only` (non-executable doc).
4. **Update the header:** set `STATUS: Closed` (single round trip — no Producer reply turn) and leave `NEXT: —`.
5. This is the only writer of the relay file this turn; the harness commits it. Then stop.

## Setup
- Artifact under review: `relay-system/2026-06-21/shakedown-SKILL.md` (verbatim copy of `utils/shakedown/SKILL.md` from `giant-brains-claude-skills`). The skill's shared helper is staged alongside for cross-checking: `relay-system/2026-06-21/shakedown-lib.sh` (copy of `scripts/lib.sh`).
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
**Producer-verified facts (point-in-time snapshot of the real skill folder at 2026-06-21 17:16 PDT — the author is actively building it; you cannot see the giant-brains repo from here, so trust these):**
- `utils/shakedown/` currently holds `SKILL.md` and `scripts/lib.sh` (the shared helper, staged for you as `shakedown-lib.sh`).
- The two **entrypoint scripts the doc tells users to RUN — `scripts/audit.sh` and `scripts/harness.sh` — do NOT yet exist.** The whole "The run" section (`bash "$SK/scripts/audit.sh"`, `bash "$SK/scripts/harness.sh"`) is therefore not yet executable; only the helper those would `source` is present.
- `scripts/lib.sh` does practice the self-location idiom the skill preaches — cross-check the doc's claims against it where useful.
**Review this — focus areas:**
- **Entrypoint scripts absent.** The skill's core mechanism (static audit + live harness) depends on `audit.sh` + `harness.sh`, which don't yet exist (only `lib.sh` does). What severity is right for a doc that documents commands which can't run yet?
- **Does it pass its own test? (dogfooding).** The skill preaches absolute-path self-location and warns against CWD-relative paths. Scrutinise its own discovery snippet — `SK=$(dirname "$(find "$HOME/.claude/skills" ".claude/skills" -path '*shakedown/SKILL.md' 2>/dev/null | head -n1)")` — and the `bash "$SK/scripts/<name>.sh"` calls. Any path bug, fragile `find` (e.g. a missing search root), or unset-`$SK` failure mode in the very skill that hunts path bugs?
- **House style & calibration.** Frontmatter on line 1, ASCII punctuation, observable triggers, a genuine no-escalate counter-example, brevity. Does it have the suite's calibration (it currently has no counter-example — is that a gap)?
- **Method soundness.** Is the "found vs ran-clean" distinction, the exit-code contract, and the "anchor the verdict to the worst finding" rule coherent? Any gap in the scenario matrix or the read-only contract?
- **Report defaults.** Per-repo `SHAKEDOWN/` vs central, propose-not-patch — sensible, or surprising?
**Verification:** N/A — non-executable artifact; facts above are from `ls`/`find` on the real skill folder.
**Open question:** With the helper (`lib.sh`) present but both entrypoints (`audit.sh`, `harness.sh`) still missing, what severity is right — **Blocker** (the doc documents commands that can't run), or acceptable as a mid-build spec the doc should at least flag as not-yet-runnable? Judge the SKILL.md on its own merits regardless; script status is one finding, not the whole review.
**Commit:** harness-managed.

### Round 1 · Reviewer · Codex · 2026-06-21
**Verdict:** Changes requested
**Basis:** textual only

- [Blocker] `SKILL.md:34-49` presents `bash "$SK/scripts/audit.sh"` and `bash "$SK/scripts/harness.sh"` as the core runnable flow, but the staged snapshot in Round 1 says those entrypoints do not exist yet. That makes the documented mechanic non-functional, not just incomplete. Proposed fix: ship `scripts/audit.sh` and `scripts/harness.sh` before merging this skill, or rewrite this section to say the flow is not yet runnable and remove the concrete commands until the files land.
- [Blocker] `SKILL.md:22-28` fails its own path-hardening standard. The fallback `find "$HOME/.claude/skills" ".claude/skills" ... | head -n1` depends on the current working directory for project installs, and if nothing matches then `dirname` turns the empty result into `.` so the later `bash "$SK/scripts/<name>.sh"` calls can target the wrong repo-local path. Proposed fix: prefer the runtime-provided skill dir, otherwise walk upward to find a project `.claude/skills` install, require a non-empty match, and exit with a clear error instead of defaulting to `.`.
- [Should] `SKILL.md:3-105` gives a good trigger list but no no-escalate counter-example, which the stated house style calls for and which matters here because this skill is intentionally heavyweight. Proposed fix: add one short "do not use shakedown when..." example, such as skills with no bundled scripts or failures that are clearly runtime logic bugs rather than path/discovery bugs.
- [Pass] `SKILL.md:83-98` is methodologically sound on the main review axis: it separates "script found" from "script ran clean," and it anchors the final verdict to the worst load-bearing finding instead of averaging results. Proposed fix: none.

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
