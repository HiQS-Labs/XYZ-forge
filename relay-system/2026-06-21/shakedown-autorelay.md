# RELAY · shakedown autonomous review
NEXT: Reviewer
STATUS: Open
ROUND: 1 / 6

## ▶ TAKE YOUR TURN (any model: Claude / Codex / agy)
Read the WHOLE file. Your role is the one named by `NEXT:`. Act only on your turn; append ONE block above the marker; never edit earlier turns; the harness commits.
- **Reviewer:** review the artifact (Setup path) against the Definition of Done. Append `### Round N · Reviewer · <you> · 2026-06-21` with graded findings ([Blocker]/[Should]/[Nit]/[Pass]), each with a concrete fix, and a **Verdict**. If anything should change -> Verdict `Changes requested`, set `NEXT: Producer`, hand the token to the producer. If genuinely clean -> Verdict `Approved`, set `STATUS: Approved` + `NEXT: —` and close the token. Do NOT edit the artifact.
- **Producer:** read the latest Reviewer findings. For each, EITHER edit the artifact at the Setup path to implement the fix, OR write a one-line decline reason. Append `### Round N · Producer · <you> · 2026-06-21` listing every disposition. Set `NEXT: Reviewer` and hand the token back.

## Setup
- Artifact under review (edit THIS path; it is a staged copy inside the harness): `relay-system/2026-06-21/shakedown-SKILL.md`
- Definition of Done: Review the artifact for correctness, internal consistency, conformance to its repo's house style (valid frontmatter, ASCII punctuation, observable triggers, at least one no-escalate counter-example, brevity), and whether its documented mechanics actually work. Iterate to Approved.
- Producer: agy   ·   Reviewer: codex   ·   Autonomous: 1
- Started: 2026-06-21

## Ground rules
1. The file is the single source of truth; the agents never share memory.
2. One block per turn, appended at the bottom; flip NEXT; the Reviewer alone may set STATUS: Approved.
3. Findings are tight bullets. The Reviewer never edits the artifact; the Producer does.
4. Evidence: judge by reading the artifact text; this is a non-executable doc (Basis: textual only).

---
## Log

### Round 1 · Producer · auto-relay · 2026-06-21
**Did:** Staged `SKILL.md` for autonomous review. Reviewer goes first.
**Subject note (Producer-verified, you cannot see the source repo):** The real skill folder utils/shakedown/ ships SKILL.md and scripts/lib.sh, but the two entrypoint scripts the doc tells users to RUN -- scripts/audit.sh and scripts/harness.sh -- do not exist yet, so the 'The run' section is not yet executable.
**Review this:** the artifact against the Definition of Done; lead with the worst load-bearing finding.
**NEXT:** Reviewer.

### Round 1 · Reviewer · codex · 2026-06-21
- [Blocker] The core workflow is not executable as written: `The run` instructs users to execute `bash "$SK/scripts/audit.sh"` and `bash "$SK/scripts/harness.sh"`, but the staged review context says those entrypoints do not exist in the real skill folder. That fails the "documented mechanics actually work" bar. Concrete fix: either add those two scripts at the documented paths, or rewrite the runbook so every command maps to files that actually ship.
- [Should] The write contract is internally inconsistent. `Read-only contract` says "The only thing written to the user's repo is the report file under `SHAKEDOWN/`", but step 4 also requires prepending an entry to `SHAKEDOWN/INDEX.md`, which is a second repo write. Concrete fix: update the contract to say the skill writes the dated report plus `SHAKEDOWN/INDEX.md`, or drop the index requirement.
- [Should] House-style conformance is loose in the report template. The required output uses emoji verdict markers (`🔧`, `🚧`, `⚠️`, `✅`) even though this repo's reviewable artifacts bias toward plain ASCII presentation. Concrete fix: switch those markers to ASCII labels like `[path bug]`, `[warnings]`, and `[clean]`.
- [Nit] The frontmatter `description` is carrying too much operational detail for a trigger surface, which hurts brevity and makes the actual observable triggers harder to scan. Concrete fix: compress the description to the trigger cases and move the execution detail into the body.

**Verdict:** Changes requested.
**NEXT:** Producer.

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
