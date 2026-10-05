# RELAY · GH-964 second-opinion QA (Fable): xyz-mod /xyz-status, PR #966
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-04.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh-964-second-opinion-qa-fable-xyz-mod-xyz-status-pr-966): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review (branch `feat/gh964-xyz-mod` vs `origin/development` `8853cd6a`):
  `skills/2-daily/xyz-mod/mod/hooks/register.ts`, `skills/2-daily/xyz-mod/mod/hooks/hooks.json`,
  `skills/2-daily/xyz-mod/mod/.claude-plugin/plugin.json`, `skills/2-daily/xyz-mod/mod/tsconfig.json`
  (written by Claude Code when it loaded the mod), `skills/2-daily/xyz-mod/SKILL.md`, the
  `ARCHITECTURE.md` and `CHANGELOG.md` entries, `PARKED/2026-10-04-gh964-skills-index.md`, and the
  evidence in `TESTS-RESULTS/2026-10-04+GH-964/`.
- Approved plan: `PROJECT/2-WORKING/GH-964-CLAUDE-CODE-MODS.md` (plan QA:
  `relay-system/2026-10-04/gh964-plan-qa.md`, Approved round 2).
- Reviewer: fable (Claude subagent, light effort; second opinion after Codex approved round 1 in `relay-system/2026-10-04/gh964-final-qa.md`)   ·   Producer: claude-a
- Started: 2026-10-04
- Definition of Done: the code does what plan step 1 says and nothing more; the evidence substantiates
  the plan's D1–D3, D6 and R1; the skill and docs are accurate; no new test suite, registry entry or
  gate machinery (GH-831); the rating 35/15/50/70 still matches the evidence.

**Operational envelope.** Optional, read-only, single-operator local mod, ~45 lines of TypeScript.
Grade against the approved plan. Do not ask for retries, caching, telemetry, installers or tests.

**Facts you cannot check here** (stated input, from Claude Code 2.1.289's bundled typings and runs):
`$.process.run(argv, { cwd, env, timeoutMs })` resolves `{ exitCode, stdout, stderr }` for any exit
code and rejects when the command cannot start or times out; `env` is set *over* the host
environment (PATH survives). `claude plugin validate` output is in `TESTS-RESULTS/.../d2-validate.txt`.
A scratch type-check with TypeScript 5.6 against those typings was clean.

**Owed by the operator, not claimed here:** D4 (`/plugin` lists the mod active) and D5 interactive in
the terminal and VS Code. Only a headless `claude -p` run is recorded for D5.

**Questions.**
1. Does `register.ts` match plan step 1 exactly: root via `git rev-parse --show-toplevel`, root line
   first, repo-local readers by absolute path, `gh` from PATH, `cwd` = root, `TICK_REPO_ROOT` pinned,
   15 s timeouts, independent sections, nonzero / thrown / empty → `ERROR`, and no other hooks?
2. Any input where a failed reader would still print as healthy, or one section's failure hides
   another's? Cite `register.ts:line` and the concrete input.
3. Do the recorded results in `TESTS-RESULTS/2026-10-04+GH-964/provenance.jsonl` and the two logs
   support the D1–D3, D6, R1 verdicts? Is anything over-claimed (for example D5)?
4. Are `SKILL.md`, the ARCHITECTURE row and the CHANGELOG entry accurate against the code?
5. Is the committed engine-written `tsconfig.json` acceptable, or an accidental file to drop?
   Also: is anything in the Codex final-QA thread wrong, or did it miss something?
6. Anything over- or under-built for the envelope? Cite `file:line` for every disagreement.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · fable

VERDICT: PASS
Basis: `register.ts` implements plan step 1 line for line inside the stated envelope (46 lines, two hooks, two calls); no input was found under the stated `$.process.run` contract where a failed reader prints as healthy or hides a sibling; the retained receipts support D1–D3, D6 and R1 and explicitly scope D5 to headless; skill, ARCHITECTURE row and CHANGELOG entry match the code; the Codex round-1 approval holds. No Blocker or Should. Approval closes this second-opinion implementation review, not the operator-owed D4/D5 or the go/no-go.
swept file: yes

Swept all 46 lines of `register.ts`, the three JSON files, all of `SKILL.md`, the parked note, all 8 `provenance.jsonl` rows, both logs, the plan, the Codex thread, `bin/tick:403`–455 and `relay-automation/marathon-ls.sh:21`. No pre-existing defects found in scope (every mod file is new on this branch; `bin/tick` / `marathon-ls.sh` are read, not touched). Read-only probes only; no `validate.sh`, `test/*`, `claude` or the mod run. Branch base confirmed: `git merge-base HEAD origin/development` → `8853cd6a…`; `git diff --stat 8853cd6a..HEAD` → 17 files, +749/−3, all GH-964.

- **[Pass] Q1 — step 1 matched exactly.** Root: `register.ts:19`–22 (`git rev-parse --show-toplevel`, 15 s, `.catch(() => undefined)`, non-zero/empty → explicit "not inside a git repository" stop). Root line first: `:44` (`root: ${root}` is element 0 of the join). Repo-local readers by absolute path: `:28` (`${root}/bin/tick`), `:29` (`bash ${root}/relay-automation/marathon-ls.sh`); `gh` from PATH: `:27`. `cwd: root`, `env: { TICK_REPO_ROOT: root }`, `timeoutMs: TIMEOUT_MS` (= 15_000, `:6`): `:34`. Independent sections: `:32`–42. Nonzero / thrown / empty → `ERROR`: `:36`–40. Hooks: only `session.start` (`:9`) and `command.run{command:'xyz-status'}` (`:18`); confirmed by `d2-validate.txt:9`–10. Nothing beyond the plan.

- **[Pass] Q2 — no healthy-looking failure, no cross-section masking.** Healthy requires `exitCode === 0 && out` (trimmed) at `:36`; concrete inputs `{exitCode:0, stdout:'\n'}` → `ERROR (exit 0): empty output` (`:37` fallback), `{exitCode:3, stdout:'', stderr:'tick claims: tick-dir-missing: …'}` (the real `bin/tick:412`–413 path) → `ERROR (exit 3): tick claims: tick-dir-missing: …`. Each reader's `await` sits inside its own `try` (`:33`–41), so a rejection (ENOENT, timeout) becomes that section's text and `Promise.all` at `:32` never rejects — a sibling cannot be lost. Observed: `provenance.jsonl:6` (R1 mutant: tick section `ERROR (... ENOENT ...)`, other two healthy). Note for the operator, not a change request: `bin/tick:427`–431 returns 0 with `(no claimed tasks — uninitialized coordination root: no .tick/events)` on a clone where the kernel never ran; it prints as healthy but the text self-labels, which is tick's own GH-561 contract.

- **[Nit] Q2 edge — a legitimately empty `gh run list` reads as ERROR.** `gh` prints "no runs found" to stderr with exit 0 on an empty result → `:36` fails the `&& out` test → `ERROR (exit 0): no runs found` (`:37`). That is exactly what plan step 1 asks ("empty stdout → ERROR … never an empty 'nothing in flight'"), so this is conservative by design. No change requested; mention only so the operator does not read it as a mod bug on a quiet branch.

- **[Pass] Q3 — receipts support D1–D3, D6, R1; D5 is not over-claimed.** `provenance.jsonl:1` D1 `2.1.289 (>= 2.1.287)`; `:2` D2 with log `d2-validate.txt:9`–12 (two hooks, two calls, "Validation passed with warnings" — the warning is the missing `author`); `:3` D3 all three rc=0 with byte counts 1107/18/3416; `:5` D6 run from `src/`, root names the clone root; `:6` R1 mutant red / restored green with `qualification: "mutation applied to a scratch copy, not the committed file"` (consistent with `SKILL.md:68` "do not commit"); `:8` type-check clean with a `exitCod` mutant caught (TS2551). D5: `provenance.jsonl:4` is labelled `D5-headless` with `qualification: "headless only; … D4, D5 … still owed"`, and `d5-headless.json:5`–6 shows `num_turns: 0`, `is_error: false`, `result` with the root line and three non-empty sections (verified: "Hosted runs" 8 rows, "tick claims" `(no claimed tasks)`, "Marathon / relay drivers" table). Plan `GH-964-CLAUDE-CODE-MODS.md:20` keeps D4/D5 and go/no-go with the operator. Minor: D3, D6 and R1 are summary rows without raw logs (Codex noted the same); acceptable for a manual checklist under GH-831.

- **[Pass] Q4 — docs accurate against the code.** `SKILL.md:14` "replies when its readers finish (15 s cap each)" ↔ `register.ts:6`,`:34`; `:17`–20 reader list ↔ `:27`–29 argv verbatim (`--branch development --limit 8`, `TICK_REPO_ROOT` pinned, `marathon-ls.sh`); `:36`–38 "any subfolder works … says so if that folder is not a git repo" ↔ `:19`–22; `:45`–48 hook/call boundary ↔ `:9`,`:18`,`:10`,`:34`; `:50`–52 error shape ↔ `:36`–41. `ARCHITECTURE.md:89` row text matches `plugin.json:4`. `CHANGELOG.md:3`–17 matches (root line, three readers, read-only, failures visible, no suite). The Codex "instantly" nit is already applied: commit `34532495`, and `rg instantly skills/2-daily/xyz-mod CHANGELOG.md` → 0 matches.

- **[Pass] Q5 — tsconfig.json is acceptable; Codex thread stands.** `mod/tsconfig.json:2` is a 1-line `extends` pointer to `./.claude-plugin/types/tsconfig.json`. Probe: `git check-ignore -v …/types/tsconfig.json` → `types/.gitignore:1:*` (rc=0), and `git ls-files skills/2-daily/xyz-mod` lists only the 5 intended files — so `types/` is engine-written and self-ignored, and the committed pointer dangles in a fresh clone until Claude Code loads the mod and regenerates `types/`. That is harmless (editor-only; no build or gate reads it) and keeping it avoids a dirty-tree diff after every load, so keep. Codex's thread (`gh964-final-qa.md:103`–132): every cited line re-checked and correct; its one Nit is applied; the only thing it did not mention is the dangling-pointer detail above, which changes nothing.

- **[Pass] Q6 — proportionate to the envelope.** 46 lines (`register.ts:1`–46), no retries, caching, telemetry, installer, suite or registry entry anywhere in the 17 changed files (diff stat above). Nothing under-built: every plan-step-1 clause has a line. Rating 35/15/50/70 (`plan:135`–138) still matches: optional time-saver, nothing blocked, small change.

Relay closed (Approved), no further turn needed. Producer (claude-a): proceed with the post-turn gate and PR #966; D4/D5 interactive and the go/no-go remain operator work.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
