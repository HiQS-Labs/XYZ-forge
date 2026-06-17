---
title: Marathon — chained multi-phase build→review across Claude Code ↔ Codex/Gemini
status: Draft (for relay-review — this plan can itself go through /relay)
created: 2026-06-16
builds-on: >-
  Relay Phases 1–4 + Option-A headless (codex-turn.sh shipped 2026-06-15),
  relay-turn-lib.sh containment core (3-model validated), relay-drive.sh supervisor,
  watchdog.sh liveness scanner
---

# Marathon: chain build→review phases, hands-free

## Goal
A `/marathon` that runs an **ordered list of phases**, where each phase is one relay:
**Claude Code builds (headless `claude -p`)**, then **Codex or Gemini reviews (headless)**,
revise/re-review until the reviewer sets `STATUS: Approved`, then advance to the next phase.
On a clean approval the chain advances; on no-progress / round-cap / close-mismatch it **halts
and escalates**. Closes item 196's cross-model sense at *workflow* scale, not just single-turn.

## The one decision that shapes everything: Marathon **wraps** `relay-drive.sh`
`relay-drive.sh` already is the loop — claim/ping/release lifecycle, round cap, no-progress
guard, close-mismatch detection, terminal-agreement (`STATUS:` terminal **AND** token not live).
**Marathon does not reimplement any of that.** `marathon-drive.sh` calls `relay-drive.sh` **once
per phase** and chains on its exit code. Likewise, every headless turn-taker **sources
`relay-turn-lib.sh`**, so the path-allowlist + commit-bypass + no-push containment is inherited,
not rewritten (reimplementation is exactly where a fourth bypass sneaks in).

---

## Architecture

```
marathon-drive.sh                         # NEW — outer phase-chain driver
  ├─ parse MARATHON.yaml (phases, reviewer, max_review_rounds, depends_on)
  ├─ for each phase in dependency order:
  │    ├─ render phases/p<N>/RELAY.md from template (phase prompt → role TAKE-YOUR-TURN slots)
  │    ├─ tick add  MARATHON-P<N>-TURN   (initial handoff → builder `claude`)
  │    └─ relay-drive.sh \
  │         --relay-file phases/p<N>/RELAY.md \
  │         --relay-task MARATHON-P<N>-TURN \
  │         --agent-cmd  relay-automation/marathon-agent.sh \
  │         --round-cap  <2*max_review_rounds + 1>
  │       ├─ exit 0  → emit marathon.phase.approved → advance
  │       ├─ exit 3  → emit marathon.phase.escalated (no-progress) → halt
  │       └─ exit 4  → emit marathon.phase.escalated (cap / close-mismatch) → halt
  └─ all phases approved → emit marathon.complete

relay-automation/
  marathon-agent.sh     # NEW — the single --agent-cmd; routes on RELAY_AGENT → the right shim
  claude-turn.sh        # NEW — builder; sources relay-turn-lib.sh; runs `claude -p`
  gemini-turn.sh        # CONFIRM/finish — referenced as gemini-drive.sh in relay-turn-lib.sh
  codex-turn.sh         # UNCHANGED — thin wrapper already sourcing relay-turn-lib.sh
  relay-turn-lib.sh     # UNCHANGED — sourced by ALL turn-takers (containment core)
  watchdog.sh           # UNCHANGED — optional liveness scan during long runs (M7)

phases/
  p1/RELAY.md           # generated per phase; STATUS: Approved is the terminal signal
  p2/RELAY.md
  ...
MARATHON.yaml           # you author
MARATHON-STATE.md       # projected from .tick/events/ (M7)
```

### Why `marathon-agent.sh` (the dispatcher)
`relay-drive.sh` takes **one** `--agent-cmd`, but a phase has **two** roles (builder + reviewer).
The dispatcher reads `RELAY_AGENT` (which relay-drive derives from the tick token's claimer /
handoff-to) and execs the matching shim:

```bash
case "$RELAY_AGENT" in
  claude)  exec "$(dirname "$0")/claude-turn.sh" ;;   # build / revise
  codex)   exec "$(dirname "$0")/codex-turn.sh"  ;;   # review
  gemini)  exec "$(dirname "$0")/gemini-turn.sh" ;;   # review
  *) printf 'marathon-agent: unknown agent %s\n' "$RELAY_AGENT" >&2; exit 2 ;;
esac
```

The shim never needs to know build-vs-review — the **relay file's per-role `▶ TAKE YOUR TURN`
steps** carry that. The shim only runs the right CLI headless and lets `relay-turn-lib.sh`
enforce the boundary. This also retires the "one `--agent-cmd` can't drive both sides" no-op
gating that `codex-turn.sh` carries for Option-B window co-existence (harmless if it still fires —
the dispatcher only calls it when `RELAY_AGENT=codex`).

---

## MARATHON.yaml (you author)

```yaml
name: trinity-sync-refactor
phases:
  - id: p1
    name: Event schema + projection contract
    reviewer: codex                # codex for code-level critique
    max_review_rounds: 2
  - id: p2
    name: sync.js single-writer lease
    reviewer: gemini               # gemini for architecture/cross-cutting
    depends_on: p1
    max_review_rounds: 3
  - id: p3
    name: tick CLI claim-cap wiring
    reviewer: codex
    depends_on: p2
    max_review_rounds: 2
```

Per-phase `reviewer` is worth the tiny complexity: Codex and Gemini have different review
strengths, and the field is what the dispatcher routes on. `depends_on` is cheap insurance even
without DAG branching — it lets you **re-run one failed phase** without re-running the whole chain.

---

## Phase relay file + lifecycle
Each phase reuses the **existing relay file shape** — one `RELAY.md` with `▶ TAKE YOUR TURN`
sections per role and a `STATUS:` line. No new protocol, no separate artifact/verdict files.

1. `marathon-drive.sh` writes `phases/p<N>/RELAY.md` with the phase brief baked into the builder
   and reviewer turn slots, and `NEXT:` naming the role to act.
2. `tick add MARATHON-P<N>-TURN` with initial handoff to `claude` → builder takes turn 1.
3. `claude` builds, then `tick release MARATHON-P<N>-TURN --to <reviewer>`.
4. Reviewer reviews. **Approve** → `tick done` + `STATUS: Approved` (relay-drive exit 0).
   **Changes** → `tick release --to claude` → builder revises → back to reviewer.
5. Loop until approve or `--round-cap` → relay-drive exits, `marathon-drive.sh` reads the code.

### Exit code → phase action (no new logic, just mapping)
| relay-drive exit | meaning | marathon action |
|---|---|---|
| 0 | `STATUS: Approved` + token done (agreement) | emit `phase.approved`, advance |
| 3 | no-progress (token actor didn't move) | emit `phase.escalated`, write ESCALATION.md, **halt** |
| 4 | round-cap / closed-not-approved / close-mismatch | emit `phase.escalated`, write ESCALATION.md, **halt** |
| 2 | usage error | abort with the usage message |

---

## Two wiring details the code makes mandatory

**1. Round-cap arithmetic (off-by-one trap).** `relay-drive.sh --round-cap` counts **turns**, not
review rounds. One review round = build/revise turn + review turn = **2 turns**. So
`--round-cap = 2 * max_review_rounds + 1` (the `+1` for the initial build). `max_review_rounds: 2`
→ `--round-cap 5`. Get this wrong and phases either die early or burn extra Codex/Gemini turns.

**2. `RELAY_PEER` on every turn.** `relay-turn-lib.sh:rtl_turn_prompt` takes an optional peer; when
it's absent a turn can `release --to` a *literal role string* — a live Gemini turn on 2026-06-15
released to the literal "Producer" because the peer was unnamed. `marathon-drive.sh` must pass the
peer per turn: builder's peer = the phase's reviewer; reviewer's peer = `claude`. Thread it
through `marathon-agent.sh` → the shim → `rtl_turn_prompt`.

---

## `claude-turn.sh` shape (the only genuinely new turn-taker)
Mirror `codex-turn.sh`: source `relay-turn-lib.sh`, `rtl_init` → `rtl_before` → run model →
`rtl_enforce`. The model invocation (current Claude Code headless flags):

```bash
prompt="$(rtl_turn_prompt "claude" "$RELAY_FILE" "$RELAY_TASK" "$ALLOW_CSV" "$RELAY_PEER")"
claude -p "$prompt" \
  --allowedTools "Bash,Read,Edit,Write" \   # Bash needed for ./bin/tick; lib still guards git
  --permission-mode acceptEdits \           # codex `approval:never`-equivalent
  --max-turns 40 \                          # cost ceiling per build turn
  --output-format json \                    # parseable; extract VERDICT/result for supervisor
  > "$TURN_LOG" 2>&1
```

- **Do NOT pass `--bare`** — you *want* CLAUDE.md + skills loaded so build turns match interactive
  quality. (`--bare` skips CLAUDE.md/skills/MCP/hooks.)
- **Allowlist = only `phases/p<N>/RELAY.md`** (plus `.tick/*`, which the lib exempts intrinsically).
  `claude -p` with Edit/Write is a wider surface than codex's `workspace-write` — the
  `rtl_enforce` allowlist+commit-guard is the real control, not the permission flag. Do not skip it.
- **No push, no commit by the agent** — the lib commits file-scoped; if `claude` commits mid-turn,
  `rtl_enforce`'s commit-bypass guard resets `--hard` and fails the turn (exit 6).
- Docs: https://code.claude.com/docs/en/headless · https://docs.anthropic.com/en/docs/claude-code/sdk/sdk-headless

---

## Implementation plan (quick wins → harder)

> Ordered for fastest signal with least risk. The `claude -p` spike (M2) gates the headless-builder
> bet — do it before committing to M3, exactly like the Option-A spike preceded `codex-turn.sh`.

### M0 — Confirm the Gemini shim already exists  ·  ~15 min  ·  trivial
- [ ] Grep the relay-automation dir for `gemini-drive.sh` / `gemini-turn.sh` — `relay-turn-lib.sh` already names `gemini-drive.sh` as a sourcer and a **live Gemini turn ran 2026-06-15**, so this may be done.
- [ ] If it exists: rename/symlink to the `gemini-turn.sh` convention the dispatcher expects, run its test suite. *Accept:* a stub-`gemini` turn drives one relay turn (claim/ping/release + relay-file mutation) and the off-allowlist negative test reverts + fails.
- [ ] If it does not exist: copy `codex-turn.sh`, swap `codex exec "<prompt>" < /dev/null` → `gemini -p "$prompt"` (confirm Gemini CLI flag), keep the `rtl_*` calls identical.

### M1 — `marathon-agent.sh` dispatcher  ·  ~15 min  ·  trivial
- [ ] Write the `case "$RELAY_AGENT"` router above. Pure routing, no logic.
- [ ] Pass `RELAY_PEER` through to the exec'd shim.
- [ ] *Accept:* set `RELAY_AGENT` to `claude` / `codex` / `gemini` and confirm the correct shim is exec'd; unknown agent → exit 2.

### M2 — `claude -p` headless spike (the gating unknown)  ·  ~30 min  ·  medium
- [ ] Run a trivial `claude -p "<prompt>" --allowedTools "Bash,Read,Edit,Write" --permission-mode acceptEdits --output-format json` in an isolated repo. Confirm it: runs non-interactively + exits 0, **edits a file**, **runs `./bin/tick`** (Bash), and **loads project CLAUDE.md + skills** (no `--bare`).
- [ ] Capture **tokens + $ per turn** (Codex defaults high reasoning at tens-of-k; size Claude's similarly) → sets realistic `--max-turns` / `--max-budget-usd`.
- [ ] *Accept:* a one-shot `claude -p` turn produces a graded relay block + a parseable `VERDICT:`/result, with file-write and `tick` both working. *If context-loading or tool access is wrong, stop and fix flags before M3.*

### M3 — `claude-turn.sh` shim  ·  ~30 min  ·  medium
- [ ] Build per the shape above: `rtl_init` → `rtl_before` → `claude -p ...` → `rtl_enforce`. Allowlist = `phases/p<N>/RELAY.md` only.
- [ ] *Accept (positive):* a stub `claude` doing the real turn-taker contract (`tick claim/ping/release|done` **and** mutating the relay file) drives one turn through `relay-drive.sh`.
- [ ] *Accept (negative):* the stub touches an off-allowlist file → `rtl_enforce` reverts it, stages nothing extra, fails (exit 6). No push occurs.

### M4 — Single-phase marathon (the proof)  ·  ~1 h  ·  medium
- [ ] `marathon-drive.sh` hardcoded to one phase: render `phases/p1/RELAY.md` from a template, `tick add MARATHON-P1-TURN` (handoff → `claude`), call `relay-drive.sh --agent-cmd marathon-agent.sh --round-cap 5` **unmodified**.
- [ ] *Accept:* builder turn → reviewer turn → `STATUS: Approved` → relay-drive **exit 0**; reviewer block present; only `phases/p1/RELAY.md` changed; no push. **This proves chaining works with relay-drive untouched and all containment inherited.**

### M5 — `MARATHON.yaml` + phase chaining + events  ·  ~2–3 h  ·  harder
- [ ] Parse `MARATHON.yaml` (use `yq`, or a zero-dep key=value reader if you'd rather not add a dep). Resolve `depends_on` into execution order.
- [ ] Loop phases; compute `--round-cap = 2*max_review_rounds + 1` per phase; route reviewer via the agent name placed in the token.
- [ ] Emit `.tick/events/` JSONL at boundaries: `marathon.phase.start` / `phase.approved` / `phase.revision` / `phase.escalated` / `marathon.complete`.
- [ ] On halt (exit 3/4) write `ESCALATION.md` with phase id, round count, last verdict, and stop.
- [ ] *Accept:* a 3-phase YAML runs end-to-end; a deliberately-unsatisfiable middle phase halts the chain at that phase with an escalation record and does **not** start the next phase.

### M6 — Cross-phase context injection  ·  later  ·  low urgency
- [ ] When `depends_on` is set, prepend the **approved** prior-phase `RELAY.md` artifact block into the next phase's builder prompt template (concatenate → context block). Start *without* this; add only once a phase genuinely needs the prior phase's output.
- [ ] *Accept:* a p2 build turn visibly references a decision made in the approved p1.

### M7 — Liveness + state projection  ·  later  ·  low urgency
- [ ] Run `watchdog.sh --channel file --escalation-log marathon.escalations.jsonl` alongside long runs — its structured `parked_suspects[]` scan catches a stalled turn that a single `relay-drive.sh` invocation's per-call no-progress guard can't see across the whole chain. Keep `--allow-reap` **off** until reap policy is approved.
- [ ] Project `MARATHON-STATE.md` from `.tick/events/` (current phase, per-phase round counts, statuses) — same pattern as `STATE.md`. Do after M5 is stable.

---

## Risks
- **Headless `claude -p` cost** — each build turn is real spend; cap with `--max-turns` + `--max-budget-usd` and the phase `--round-cap`. A bare `claude -p` will happily burn the budget on one stubborn typo.
- **Wider write surface than Codex** — `claude -p` with Edit/Write can touch the whole tree; the `rtl_enforce` allowlist + commit-bypass guard is the boundary, *not* the permission mode. Never run a phase without the shim.
- **Round-cap miscount** — turns ≠ rounds; the `2*rounds + 1` conversion is load-bearing (see above).
- **Unnamed peer on handoff** — without `RELAY_PEER`, a turn can release to a literal role string (the 2026-06-15 Gemini "Producer" failure). Thread the peer through every turn.
- **Prompt-injection on unattended agents** — general Option-A caveat; the relay file is the only writable input, but treat its contents as untrusted by the model.
- **`.tick/` state between phases** — `marathon-drive.sh` adds a fresh `MARATHON-P<N>-TURN` per phase; the `.tick/*` exemption in `rtl_check` should cover any residue, but verify the next phase's `rtl_before` snapshot is clean on the **first real multi-phase run**.

## Open decisions
- [ ] **Builder bootstrap order** — ship M4 with a **manual** Claude window for the first phase build (lowest risk, proves the chaining harness), then flip to `claude-turn.sh`? Or trust the M2 spike and go headless from M4? (Recommendation: trust the spike; manual builds aren't a "marathon.")
- [ ] **YAML parser dependency** — add `yq`, or keep zero-dep with a simple reader? (Recommendation: `yq` if it's already in the toolchain; otherwise the relay ethos favors zero new deps.)
- [ ] **Per-phase reviewer override at runtime** — flag to force all reviews to one model for a cost-constrained run, ignoring the YAML `reviewer` field?
- [ ] **Should this plan go through `/relay` first** — dogfood: have Codex + Gemini review this doc before building, the way the containment contract was 3-model validated.