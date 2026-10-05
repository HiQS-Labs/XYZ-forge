# RELAY · GH-964 final QA: xyz-mod /xyz-status implementation
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
6. **Commit only the relay file** (`relay(gh-964-final-qa-xyz-mod-xyz-status-implementation): <role> r<N>`); no push. **Stop** and report one line.
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
- Reviewer: codex   ·   Producer: claude-a
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
6. Anything over- or under-built for the envelope? Cite `file:line` for every disagreement.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: PASS
Basis: The implementation meets the approved step-1 contract in the stated optional, read-only envelope. Retained manual receipts support D1–D3, D6 and R1; the raw headless result supports zero model turns without pretending to establish interactive terminal/VS Code acceptance. No Blocker or Should finding. Approval closes this implementation review, not the outstanding operator acceptance or post-turn gate.
swept file: yes

Swept the entire 46-line `register.ts`, all three JSON configuration files, the entire skill and parked note, all eight provenance records and both logs, the approved plan, and the entire `ARCHITECTURE.md`. For CHANGELOG the artifact named in Setup is the GH-964 entry (`CHANGELOG.md:3`–17); reviewed that complete entry, not the unrelated historical archive. No additional pre-existing defects found in the scoped implementation. The existing missing daily-planner index row is already captured in the seeded parked note; no unrelated repair requested.

Verify-tier graph limitation: both `list_projects` pages covered all 77 projects (`has_more=false`), with none for this checkout. Nearest `XYZ-forge` graph belongs to another checkout. `search_graph` for register symbols under the new mod returned zero rows; coverage across all artifact paths plus `bin/tick` and `marathon-ls.sh` reports generation `2026-09-01T15:54:30Z`, missing new files, changed architecture metadata, and excluded CHANGELOG/bin. Used current full source reads for those paths; no negative claim rests on the old graph. Supplied Claude Code process semantics and engine origin of tsconfig are accepted inputs, not independently re-measured here.

- **[Pass] Step 1 and the read-only boundary match.** `skills/2-daily/xyz-mod/mod/hooks/register.ts:9`–15 registers the command at session start with `immediate: true`; :18 scopes the only other hook to `xyz-status`. Lines 19–22 resolve the session's git root with a 15 s bound and stop with an explicit message when resolution fails. Lines 27–29 use exactly the planned argv: bounded recent hosted runs with `gh` from PATH, absolute repo-local tick and marathon readers. Line 34 sets cwd=root, overrides `TICK_REPO_ROOT`, and applies the 15 s timeout; :44 emits root first. No tool, prompt or transcript hook is registered. This reuses the existing readers rather than recreating their state logic; `bin/tick:403`–455 is the read-only claims branch and `relay-automation/marathon-ls.sh:178`–199 enumerates its hub plus registry.

- **[Pass] Failed sections cannot become healthy through these checks.** `register.ts:32`–42 isolates each process in its own try/catch before joining results. At :35–38, concrete inputs `{exitCode:0, stdout:'   ', stderr:''}` and `{exitCode:1, stdout:'(no claimed tasks)', stderr:'failure'}` both take the ERROR branch: success requires exit 0 **and** trimmed non-empty stdout. A rejected process takes :39–40 while the other promises keep their sections. Those are source-traced cases, not executed fixtures. The observed missing-path case in `TESTS-RESULTS/2026-10-04+GH-964/provenance.jsonl:6` records `ERROR (... ENOENT ... bin/tick-missing)`, healthy other sections, then restored health. No concrete failed-reader input was found that this mod would relabel healthy under the supplied process contract; upstream reader semantic correctness is not established by an exit-code check.

- **[Pass] Receipts support the requested diagnostic subset without over-claiming D5.** `provenance.jsonl:1` records Claude 2.1.289; :2 is corroborated by `d2-validate.txt:9`–12 (only the two intended hooks and two calls, validation passed with an author warning). Lines 3, 5 and 6 retain D3's individual rc=0/non-empty byte counts, D6's subdirectory-root result and R1's mutant/restored outcome. D6 and R1 are retained manual summaries, not independently reproduced runs or separate raw logs. `d5-headless.json:4`–7 contains `is_error:false`, `num_turns:0`, the root and all three healthy sections. The nonzero `total_cost_usd` is preserved; zero model turns is not a claim of zero recorded cost. `provenance.jsonl:4` explicitly limits this to headless, and plan :20 leaves D4/D5 plus go/no-go with the operator.

  Non-mutating evidence probe (no source executed):
  ```bash
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  python3 -c 'import json,pathlib; p=pathlib.Path("TESTS-RESULTS/2026-10-04+GH-964"); rows=[json.loads(s) for s in (p/"provenance.jsonl").read_text().splitlines()]; d=json.loads((p/"d5-headless.json").read_text()); sections=d["result"].split("\n\n## ")[1:]; print("receipts",len(rows),"ids",[r["id"] for r in rows if "id" in r]); print("num_turns",d["num_turns"],"is_error",d["is_error"],"sections",len(sections),"nonempty",all("\n" in s and s.split("\n",1)[1].strip() for s in sections),"ERROR","ERROR" in d["result"]); print("logs_exist",all((p/r["log"]).is_file() for r in rows if "log" in r))'
  ```
  Exit 0; decisive output: `receipts 8 ids ['D1', 'D2', 'D3', 'D5-headless', 'D6', 'R1']`; `num_turns 0 is_error False sections 3 nonempty True ERROR False`; `logs_exist True`. This validates the retained evidence structure, not a fresh runtime execution.

- **[Pass] Packaging, scope and ratings remain proportionate.** `mod/hooks/hooks.json:1` names the single module; `mod/.claude-plugin/plugin.json:2`–4 matches the skill name/version. `mod/tsconfig.json:2` is only the engine-written `extends` pointer; retaining it is acceptable for this host-loaded experiment and adds no custom build or gate machinery. A standalone fresh-checkout type-check is not established by that pointer; the scratch type-check is recorded separately at `provenance.jsonl:8`, with an exitCod red control. `SKILL.md:17`–23 accurately bounds recent hosted runs and defers undriven threads; :45–68 matches hooks, error behavior and diagnostic ownership. `ARCHITECTURE.md:89` links the correct skill. `PARKED/2026-10-04-gh964-skills-index.md:3`–7 accurately captures the pre-existing index omission (source has 17 listed rows and 18 daily folders). The scoped artifacts add no suite, registry entry, runner or installer. Plan :135–138's 35/15/50/70 remains appropriate: optional time-saver, no blocked workflow, small implementation, API/interactive acceptance still experimental. Keep the rating; no expansion requested.

- **[Nit] “Answers instantly” overstates latency.** `SKILL.md:14` and `CHANGELOG.md:7` say “instantly”, but `register.ts:19` awaits root resolution and :32–44 waits for the slowest reader, each bounded by 15 s. Optional wording fix: “runs immediately, even mid-turn, without a model turn; replies when the readers finish.” This is a documentation precision nit, not a requested behavioral change. The changelog's verification bullet at :16 could also link the retained receipts and name the pending interactive checks when next recording an iteration.

- **[Unverified — needs clone run]** No `validate.sh`, `test/*.sh`, pytest, executable fixture, live plugin invocation, or git command was run in this turn. D4/D5 on both interactive surfaces and the keep/extend/drop decision remain operator work; post-turn harness/doc gates and exact committed-state qualification remain outside this review. The only tracked edit is this relay file; the harness owns its commit.

Relay closed (Approved), no further turn needed. Producer (claude-a) may proceed with the post-turn gate and PR preparation while keeping operator acceptance explicitly pending.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
