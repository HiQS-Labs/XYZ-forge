# RELAY · GH-21 Phase 1 impl — bin/validate-relay-block + bin/tick exit 8

NEXT: none
STATUS: Approved
ROUND: 0 / 2

## ▶ TAKE YOUR TURN — read this first

You are **agy**, the **Producer**, taking an **implementation turn**. Your task is to ship
Phase 1 of GH-21: write `bin/validate-relay-block` and wire it into `bin/tick release`/`done`
so the relay has a structural quality gate independent of the turn-taker.

> ⏱️ **TIME-BUDGET — read first.** This is a code+doc write turn. Write the files, run
> `validate.sh` to confirm no regressions, then release. Do NOT push. Do NOT edit this
> relay file during the turn — append your block at the bottom above the `---` marker after
> you finish.

### Step 1 — Read the project doc for the full checklist and architecture

```
/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-21-RELAY-QUALITY-GATE.md
```

Sections to read: Phase 1 goal, Architecture paragraph, Checklist, Phase 1 QA Checklist.

### Step 2 — Read the files you will edit

- `bin/tick` — focus on the `release` case (~L220) and `done` case (~L236), and the `main()` try-block at the bottom (~L371-376). Note that `execFileSync` is already imported from `child_process`.
- `relay-automation/relay-turn-lib.sh` — search for the `ALLOW_PATHS` / allowlist section to understand the current format, so you can add `bin/validate-relay-block` if needed.
- `GUIDING-PRINCIPLES.md` — read the existing principles so you can append the new one in the right style.
- `relay-automation/README.md` — skim to see where operator-facing exit code tables live.

### Step 3 — Write `bin/validate-relay-block`

Create `bin/validate-relay-block` as a bash script. It takes ONE positional argument: the
relay file path. It exits `0` on a valid block and non-zero with a diagnostic to stderr on failure.

Four assertions (all must pass):
1. **`## Log` section exists and contains at least one log entry** — the file has a `## Log`
   header AND there is content under it (not just the header alone).
2. **Header `STATUS:` is set to a valid completed state** — the top-level `STATUS:` line is
   NOT `In Progress` (i.e., the turn-taker updated it to `Approved`, `Changes requested`,
   `Escalated`, or similar meaningful terminal/handoff value).
3. **`VERDICT:` line is present and valid** — a line matching `^VERDICT: (PASS|FAIL|PARKED)$`
   exists in the file's Log section (after `## Log`).
4. **`Basis:` line is present and non-empty** — a line matching `^Basis: .+` exists in the
   Log section.

Print a clear one-line diagnostic to stderr naming the missing field when any assertion fails.

Make the script executable (`chmod +x bin/validate-relay-block`).

### Step 4 — Wire into `bin/tick release` and `bin/tick done`

Add an optional `--relay-file <path>` flag to `bin/tick`. When provided:
- In the `release` case: AFTER the arg validation guard (`if (!task || !flags.agent) ...`),
  BEFORE the `release(root, ...)` call — invoke `bin/validate-relay-block <relay-file>`
  synchronously using `execFileSync`. If it exits non-zero, write a diagnostic to stderr
  and `return 8`.
- Same pattern for the `done` case.
- If `--relay-file` is absent, skip validation (backward compatible — non-relay `tick release`
  calls are unaffected).

For the invocation, find the validator script relative to `bin/tick`'s own location:
```javascript
const validateScript = path.resolve(__dirname, 'validate-relay-block');
```

### Step 5 — Add `exit 8` to `bin/tick`'s main() and error handling

The existing try/catch at the bottom of `bin/tick`:
```javascript
try {
  process.exit(main(process.argv.slice(2)) || 0);
} catch (err) {
  process.stderr.write(`tick: error: ${err.message}\n`);
  process.exit(1);
}
```

The `|| 0` idiom already propagates `8` correctly (8 is truthy). Confirm this is the case
and add `exit 8` to the help/usage text (`usage()` function) with the description:
`8 — relay block structural validation failed (bin/validate-relay-block returned non-zero)`.
Distinguish it clearly from exit 6 (containment violation).

### Step 6 — Update `relay-automation/relay-turn-lib.sh` allowlist (if needed)

If `relay-turn-lib.sh`'s allowlist check would block `bin/validate-relay-block` from being
called during a turn (e.g., if the allowlist only permits specific executables), add
`bin/validate-relay-block` to the allowed list. If the allowlist does not restrict internal
tool calls, skip this step and note it.

### Step 7 — Update `GUIDING-PRINCIPLES.md`

Append the following principle in the same style as existing entries:

**Independent Verification (Separated Grading)** — The agent that produces a turn must not
be the sole grader of its own quality. Verification must be performed by an independent
deterministic check or a separate reviewing agent before the lock releases. Applies to:
the relay's structural block validator (`bin/validate-relay-block` — Phase 1 of GH-21),
consult-verify diversity (Phase 3), and any other post-generation quality gate.

### Step 8 — Update relay protocol docs

In `relay-automation/README.md`, add a note in the exit codes section (or create one if
absent) listing `exit 8` and mentioning `bin/validate-relay-block`. One or two sentences
only — operators need to know it exists and what triggers it.

### Step 9 — Run `validate.sh` and confirm green

```bash
TICK_REPO_ROOT="/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm" \
  bash "/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm/validate.sh"
```

All tests must pass. If any fail, fix them before releasing.

### Step 10 — Append your block to this relay file and release

Append ONE block at the bottom of THIS relay file (above the `---` marker) with:
- `VERDICT: PASS` (impl complete, validate.sh green) or `FAIL` (something broke)
- `Basis:` — `behaviorally proven` (ran validate.sh and confirmed) or note what was skipped
- A brief bullet list: what was written, what was wired, what was skipped and why

Set the header at the top of this file:
- `STATUS: Changes requested` (releasing back to claude-a for QA review)

Then hand off the lock (use absolute paths):
```bash
TICK_REPO_ROOT="/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm" \
  "/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm/bin/tick" \
  release RELAY-gh21-phase1-impl --agent agy --to claude-a
```

**Stop.** One-line result to the operator.

---

## Setup

- Artifact: `bin/validate-relay-block` (new), `bin/tick` (modify), `relay-automation/relay-turn-lib.sh` (allowlist if needed), `GUIDING-PRINCIPLES.md`, `relay-automation/README.md`
- Phase 1 checklist: `PROJECT/2-WORKING/GH-21-RELAY-QUALITY-GATE.md` → Phase 1 Checklist
- Definition of Done: validator written, wired into `bin/tick release`/`done`, `validate.sh` green, docs updated.
- Producer: **agy** (this turn). Reviewer: claude-a (next turn — Phase 1 QA checklist).
- Lock: tick task **RELAY-gh21-phase1-impl**
- Started: 2026-06-25
- Note: this relay runs WITHOUT the validator it is building (bootstrapping). The QA review turn is the manual equivalent of what Phase 1 will automate.

## Ground rules

1. This file is the single source of truth. Append one block at the bottom (above `---`); never edit earlier turns.
2. Do NOT edit the project doc — impl turn only.
3. Do NOT push. Commit locally with `git commit` if needed; `rtl_enforce` will handle file-scoped commit.
4. Evidence contract: log `Basis:` — `behaviorally proven` (ran validate.sh and confirmed) or `textual only` (read but not run).
5. RELAY_WORKTREE_ISOLATION=0 for this run (GH-22 workaround — agy writes via absolute RELAY_FILE path, worktree isolation silently discards it).

---
## Log

### agy impl turn — 2026-06-25

VERDICT: PASS

- `bin/validate-relay-block` written (61 lines, bash, executable): 4 assertions — STATUS not In Progress, ## Log non-empty, VERDICT: valid, Basis: non-empty. Exits 8 with named diagnostic on any failure.
- `bin/tick release` + `done` wired: `--relay-file <path>` flag added; validator invoked via `execFileSync` before token release; returns 8 on non-zero validator exit. Backward compatible — no `--relay-file` = no validation.
- `bin/tick` help text updated: `exit 8` added to usage legend, clearly distinct from `exit 6` (containment).
- `GUIDING-PRINCIPLES.md`: Principle 12 "Independent Verification (Separated Grading)" appended.
- `relay-automation/README.md`: `exit 8` note added to exit codes section.
- `relay-automation/relay-turn-lib.sh` allowlist: no change needed — `bin/validate-relay-block` is an internal subprocess call from `bin/tick`, not an agent file write. Correctly skipped.
- validate.sh: not confirmed by agy (token not released — agy stopped after writing but before Step 10). Reap issued by operator; QA review took over.
- Token not released by agy (relay-drive detected no-progress, exit 3). Implementation committed via rtl_enforce in round 1.

Basis: textual only (agy's turn); behaviorally proven for QA items below (claude-a QA review turn).

---

### claude-a QA review — 2026-06-25

VERDICT: PASS

**QA 1** `bin/tick release` vs missing `VERDICT:` → exit 8, token NOT released. PASS (diagnostic: "VERDICT: line is missing or invalid")
**QA 2** `bin/tick release` vs missing `Basis:` → exit 8, token NOT released. PASS (diagnostic: "Basis: line is missing or empty")
**QA 3** `bin/tick release` vs `VERDICT: INVALID` → exit 8, token NOT released. PASS (diagnostic: "VERDICT: line is missing or invalid")
**QA 4** `bin/tick release` vs well-formed relay file → exit 0, "released: QA-VALIDATOR-TEST". PASS
**QA 5** exit 8 distinct from exit 6: confirmed in `tick --help` Exit codes section. PASS
**QA 6** Part A regression: validate.sh 0 failures across all 25 suites post-implementation. PASS

Basis: behaviorally proven (QA 1-5 run against synthetic fixtures; QA 6 via validate.sh)
