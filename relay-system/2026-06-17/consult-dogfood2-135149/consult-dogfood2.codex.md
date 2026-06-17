Reading additional input from stdin...
OpenAI Codex v0.139.0
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626
model: gpt-5.4
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019ed75a-c191-74e2-86ee-9fc53009f3f0
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
Review a NEW Claude Code skill being added to this repo. Read both files:

- `skill/consult/SKILL.md` — the skill definition (what it does, when to use it, the workflow).
- `relay-automation/consult.sh` — its implementation (parallel read-only fan-out to Codex + Gemini,
  defensive no-write guard, graceful per-model degrade).

Context: this repo (`tick` + relay-automation: a cross-model coordination/relay stack) may become a
**commercial paid product**. The `consult` skill is meant to be a *one-shot parallel second opinion*
("ask Codex and Gemini the same question, then reconcile"), deliberately distinct from the existing
`relay` skill (iterative 1:1 Producer↔Reviewer build loop).

Assess and give graded findings ([Blocker]/[Should]/[Nit]/[Pass]):

1. **Concept soundness:** Is "consult" a genuinely useful primitive, and is it clearly distinct from
   `relay` — or does it overlap/confuse? Would a paying user understand when to reach for which?
2. **Spec quality:** Is `SKILL.md` well-specified, honest, and complete? Does the trigger/description
   correctly scope when it fires? Anything missing, over-claimed, or ambiguous?
3. **Implementation:** Is `consult.sh` correct and safe? Look hard at: the parallel fan-out + exit-code
   collection, the defensive "advisors must not mutate the tree" revert (does it correctly preserve
   pre-existing operator WIP while reverting only NEW advisor edits?), graceful degrade, and the
   read-only guarantees per model.
4. **Commercial readiness:** What is the single most important thing to fix or add before shipping
   this as a paid feature?

Be specific and cite file:line. End with a one-line recommendation: ship as-is / ship with changes /
needs rework.
codex
Verdict depends on whether the skill is actually distinct and whether the revert logic is surgically safe, so I’m reading the new skill plus the existing relay references before I make the call.
exec
/bin/zsh -lc "sed -n '1,220p' skill/consult/SKILL.md" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626
 succeeded in 0ms:
---
name: consult
description: One-shot cross-model CONSULT — fan the same question out to Codex and Gemini in parallel (read-only, advisory), then reconcile their answers into one. Use when the user wants a "second opinion", to "ask Codex and Gemini", a "panel" or "cross-model" check, or an independent gut-check on a decision/design/doc before committing — and does NOT need an iterative build/review loop. NOT a relay: a relay is an iterative 1:1 Producer↔Reviewer loop that converges an artifact; a consult is a parallel 1-shot 1:N second opinion, reconciled once. Repo-local — depends on the codex + gemini CLIs and the relay-automation shims, so it is not portable.
---

# Consult

**One question → N independent models in parallel → one reconciled answer.**

A consult asks Codex and Gemini the *same* question at the same time, read-only, and then a
coordinator (Claude) reconciles their answers — surfacing where they **agree**, where they
**disagree**, and giving a single reconciled **call**. It is the fast "ask the other brains before I
commit" move: no copy-paste, no window-shuttling, one step.

## Consult vs. relay — pick the right tool

| | **consult** (this skill) | **relay** |
|---|---|---|
| shape | parallel fan-out, 1 question → N models | iterative loop, 2 agents |
| rounds | exactly **one** | many, until `Approved` |
| writes | **none** — advisory only | Producer edits the artifact |
| output | reconciled answer + divergences | a converged artifact |
| use for | a decision, a design gut-check, "is this doc sound?" | building/fixing an artifact under review |

If after a consult you decide the work needs iteration, *start a relay* — the consult is the cheap
first look, the relay is the build loop.

## When to use

- "Get a second opinion." "Ask Codex and Gemini." "What do the other models think?"
- "Panel review" / "cross-model check" / "sanity-check this before I commit."
- An independent gut-check on a plan, design, schema, or doc — where you want *divergent* reads, not
  a single model's confident answer.

Do **not** use it to build or fix an artifact iteratively — that's `relay`.

## How it works

`relay-automation/consult.sh` fans the question out to both advisors **in parallel** and writes each
transcript to a per-run dir `relay-system/<today>/<label>-<HHMMSS>/`. The synthesis is **yours** — the
script only gathers the raw opinions.

**Provable no-mutation boundary (not best-effort).** Advisors run with their working directory set to a
**throwaway git worktree** checked out from your *current* state — tracked WIP (via `git stash create`)
plus untracked files copied in — so they see exactly what you see, including a brand-new file under
review. Anything an advisor writes lands in that disposable worktree and is destroyed with it; your
real working tree is **never** the advisors' surface, so there is nothing to revert and ambient WIP
cannot be clobbered. (Codex additionally runs `-s read-only`.) This replaced an earlier best-effort
post-hoc revert that the skill's own first dogfood flagged as unsafe.

```
consult.sh --prompt-file Q.md            # question is the file's contents (may reference repo paths)
consult.sh --prompt "Is X sound?"        # inline question
  [--models codex,gemini]                # which advisors (default both)
  [--out DIR]                            # parent dir (default relay-system/<today>/)
  [--label SLUG]                         # run-subdir + transcript stem (default "consult")
```

Each run gets its own `<label>-<HHMMSS>/` subdir, so two consults the same day never overwrite each
other. Behavior is covered by `test/consult.sh` in `validate.sh` (WIP preservation, no advisor leak,
graceful degrade, non-git refusal).

Exit `0` = at least one advisor answered; `5` = all failed; `3` = not a git repo (isolation needs
one); `2` = usage. Per-model failures are reported, not fatal — if Codex's backend is down, Gemini's
answer still comes back (**graceful degrade**, and the degrade is stated, never silent).

## Steps (the coordinator's job)

1. **Frame one sharp question.** Put it in a prompt file when it references repo paths (the advisors
   read the files themselves). Be explicit about what "good" looks like, just like a relay's
   Definition of Done.
2. **Fan out:** run `consult.sh` with the prompt + a `--label`. Both models run at once.
3. **Read both transcripts** in `relay-system/<today>/<label>-<HHMMSS>/<label>.codex.md` and `…gemini.*`.
4. **Reconcile — this is the load-bearing step.** Produce a synthesis with three parts, in this order:
   - **Disagree** (first — it's the whole point): every point the two models differ on, with your
     adjudication and *why*.
   - **Agree:** what both independently converged on (higher confidence because it's cross-model).
   - **Reconciled call:** your single recommendation, naming any open risk.
5. **Hand the synthesis back** to the operator. If it reveals the work needs iteration, offer to
   start a `relay`.

## The one rule that makes a consult worth running

**Surface disagreement; never average it away.** The entire value of asking two models is the *delta*
between them — the place one caught what the other missed. A synthesis that smooths two answers into
one confident paragraph throws that away and is worse than asking one model, because it launders two
guesses into false consensus. Lead with the disagreements, adjudicate them explicitly, and if you
can't adjudicate one, say so and flag it for the human. (Same failure mode as a review that only
hunts overclaims and misses silent drops: the easy direction satisfices.)

## Honest caveats

- **Two models, not ground truth.** Cross-model agreement raises confidence; it does not prove
  correctness — both can share a blind spot or a wrong prior. Treat a unanimous answer as *strong
  signal*, not proof, especially when correctness rides on runtime behavior neither model ran.
- **Isolated by design, not just prompted.** Advisors run in a throwaway worktree and cannot reach
  your real tree, so a consult never changes your code even if an advisor ignores the "advisory only"
  instruction. If a fix is needed, *you* (or a relay) apply it — the independent check stays independent.
- **Cost capture is opt-in.** Default Gemini output is human-readable text. Set `CONSULT_GEMINI_JSON=1`
  to capture `-o json` instead, which enables best-effort `tick cost` token logging (Codex token
  parsing is still deferred — its usage format isn't probed yet).
- **Repo-local, not portable.** Unlike `relay` (model-agnostic, file-only), consult hard-depends on
  the `codex` + `gemini` CLIs being installed and authed and on the `relay-automation` shims.

## What success looks like

The operator asks one question and gets back a single, honest, reconciled answer that **shows its
seams** — what the two models agreed on, where they split, and which way the coordinator called it and
why — in one step, with both raw transcripts on disk for audit.

exec
/bin/zsh -lc 'rg --files' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626
exec
/bin/zsh -lc "sed -n '1,260p' relay-automation/consult.sh" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626
 succeeded in 0ms:
#!/usr/bin/env bash
set -euo pipefail
#
# consult.sh — one-shot cross-model CONSULT (a panel of advisors), repo-local.
#
# Fans out the SAME question to Codex and Gemini IN PARALLEL, advisory-only, captures each transcript,
# and leaves the synthesis to the caller (Claude). This is NOT a relay: a relay is an iterative 1:1
# Producer↔Reviewer loop; a consult is a parallel 1-shot 1:N "second opinion," reconciled once.
#
# PROVABLE no-mutation boundary (reworked after the dogfood found the old best-effort revert unsafe):
# advisors run with CWD set to a THROWAWAY git worktree checked out from the operator's CURRENT state
# (tracked WIP via `git stash create` + untracked-not-ignored files copied in). Any file an advisor
# writes lands in that disposable worktree and is destroyed with it — the operator's real working tree
# is NEVER the advisors' surface, so there is nothing to revert and ambient WIP can't be clobbered.
# (Codex stays `-s read-only` on top of that; Gemini's writes, if any, are contained by the worktree.)
#
# Usage:
#   consult.sh --prompt-file Q.md  [--out DIR] [--models codex,gemini] [--label SLUG]
#   consult.sh --prompt "question" [--out DIR] [--models codex,gemini] [--label SLUG]
#
# Options:
#   --prompt-file F   File whose contents are the consult question (it may reference repo paths).
#   --prompt TEXT     Inline question (mutually exclusive with --prompt-file).
#   --out DIR         Parent dir for the run (default: relay-system/<today>/). Each run gets its own
#                     timestamped subdir <label>-<HHMMSS>/ so same-day consults never clobber.
#   --models CSV      Which advisors to run (default: codex,gemini).
#   --label SLUG      Run-subdir + transcript stem (default: consult).
#
# Env config:
#   CODEX_BIN / GEMINI_BIN     binaries (default: codex / gemini); tests inject stubs
#   CODEX_FLAGS                codex sandbox flags (default: -s read-only)
#   GOOGLE_GENAI_USE_GCA       gemini personal-login auth (default: true)
#   CONSULT_GEMINI_JSON=1      capture gemini as -o json (enables best-effort cost.tokens) instead of
#                              readable text (Codex token parsing is still deferred — format un-probed)
#   CONSULT_ROOT               git root to consult against (default: this repo)
#   TICK_BIN                   tick binary for cost capture (default: <root>/bin/tick)
#
# Exit: 0 = at least one advisor answered · 5 = ALL advisors failed · 2 = usage · 3 = not a git repo.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${CONSULT_ROOT:-"$(cd "$HERE/.." && pwd)"}"
CODEX_BIN="${CODEX_BIN:-codex}"
GEMINI_BIN="${GEMINI_BIN:-gemini}"
die()  { printf 'consult: %s\n' "$*" >&2; exit 2; }
warn() { printf 'consult: %s\n' "$*" >&2; }

PROMPT_FILE=""; PROMPT_TEXT=""; OUT=""; MODELS="codex,gemini"; LABEL="consult"
while (($# > 0)); do
  case "$1" in
    --prompt-file) PROMPT_FILE="${2:-}"; shift 2 ;;
    --prompt)      PROMPT_TEXT="${2:-}"; shift 2 ;;
    --out)         OUT="${2:-}"; shift 2 ;;
    --models)      MODELS="${2:-}"; shift 2 ;;
    --label)       LABEL="${2:-}"; shift 2 ;;
    --help) sed -n '2,40p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ -n "$PROMPT_FILE" || -n "$PROMPT_TEXT" ]] || die "one of --prompt-file or --prompt is required"
[[ -n "$PROMPT_FILE" && -n "$PROMPT_TEXT" ]] && die "--prompt-file and --prompt are mutually exclusive"
if [[ -n "$PROMPT_FILE" ]]; then
  [[ -f "$PROMPT_FILE" ]] || die "prompt file not found: $PROMPT_FILE"
  PROMPT_TEXT="$(cat "$PROMPT_FILE")"
fi

git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || { warn "consult requires a git repo (advisor isolation uses a throwaway worktree): $ROOT"; exit 3; }

OUT="${OUT:-$ROOT/relay-system/$(date +%F)}"
RUN_DIR="$OUT/${LABEL}-$(date +%H%M%S)"
mkdir -p "$RUN_DIR"

# Advisor preamble: independent, advisory, structured, cite evidence. Each is told a peer answers the
# SAME question separately and a coordinator reconciles — so it gives its OWN read, not a guessed consensus.
PREAMBLE="You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering \
the SAME question separately and a coordinator will reconcile both answers, so give your own honest, \
specific read — do not hedge toward a consensus you cannot see. Read any repo files the question \
references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — \
[Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY \
ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy)."
FULL_PROMPT="$PREAMBLE

=== CONSULT QUESTION ===
$PROMPT_TEXT"

# --- build the throwaway worktree = operator's CURRENT visible state, isolated --------------------
# tracked WIP (staged+unstaged) WITHOUT touching the real tree; falls back to HEAD when clean.
base="$(git -C "$ROOT" stash create 2>/dev/null || true)"; base="${base:-HEAD}"
WT="${TMPDIR:-/tmp}/consult-wt-$$-${RANDOM}"
cleanup() {
  git -C "$ROOT" worktree remove --force "$WT" >/dev/null 2>&1 || rm -rf "$WT"
  git -C "$ROOT" worktree prune >/dev/null 2>&1 || true
}
trap cleanup EXIT
git -C "$ROOT" worktree add --detach "$WT" "$base" >/dev/null 2>&1 \
  || die "could not create isolation worktree (base $base)"
# overlay untracked-not-ignored files so advisors see brand-new files (e.g. a skill being reviewed).
while IFS= read -r -d '' f; do
  mkdir -p "$WT/$(dirname "$f")"
  cp -p "$ROOT/$f" "$WT/$f" 2>/dev/null || true
done < <(git -C "$ROOT" ls-files --others --exclude-standard -z 2>/dev/null)

run_codex() {  # advisors run with CWD = the throwaway worktree
  local out="$1"; read -ra _f <<<"${CODEX_FLAGS:--s read-only}"
  # ${_f[@]+...} guards an EMPTY flags array under `set -u` on bash 3.2 (macOS default).
  ( cd "$WT" && "$CODEX_BIN" exec ${_f[@]+"${_f[@]}"} "$FULL_PROMPT" < /dev/null ) > "$out" 2>&1
}
run_gemini() {
  local out="$1"
  if [[ "${CONSULT_GEMINI_JSON:-0}" == "1" ]]; then
    ( cd "$WT" && GOOGLE_GENAI_USE_GCA="${GOOGLE_GENAI_USE_GCA:-true}" \
        "$GEMINI_BIN" --yolo --skip-trust -o json -p "$FULL_PROMPT" < /dev/null ) > "$out" 2>&1
  else
    ( cd "$WT" && GOOGLE_GENAI_USE_GCA="${GOOGLE_GENAI_USE_GCA:-true}" \
        "$GEMINI_BIN" --yolo --skip-trust -p "$FULL_PROMPT" < /dev/null ) > "$out" 2>&1
  fi
}

# --- fan out in parallel (indexed arrays — macOS bash 3.2 has no `declare -A`) --------------------
PIDS=(); PMODELS=(); POUTS=()
IFS=',' read -ra _models <<<"$MODELS"
for m in "${_models[@]}"; do
  m="${m// /}"; [[ -n "$m" ]] || continue
  case "$m" in
    codex)
      f="$RUN_DIR/${LABEL}.codex.md"
      run_codex "$f" & PIDS+=("$!"); PMODELS+=("codex"); POUTS+=("$f") ;;
    gemini)
      ext="md"; [[ "${CONSULT_GEMINI_JSON:-0}" == "1" ]] && ext="json"
      f="$RUN_DIR/${LABEL}.gemini.$ext"
      run_gemini "$f" & PIDS+=("$!"); PMODELS+=("gemini"); POUTS+=("$f") ;;
    *) warn "unknown model '$m' — skipping" ;;
  esac
done
((${#PIDS[@]} > 0)) || die "no valid models to consult (got: $MODELS)"

# --- collect results -----------------------------------------------------------------------------
answered=0; failed=0; summary=""; i=0
while ((i < ${#PIDS[@]})); do
  pid="${PIDS[$i]}"; model="${PMODELS[$i]}"; out="${POUTS[$i]}"
  if wait "$pid"; then
    answered=$((answered + 1)); summary+=$'\n'"  [ok]   $model -> $out"
  else
    failed=$((failed + 1));   summary+=$'\n'"  [FAIL] $model -> $out (see transcript for error)"
  fi
  i=$((i + 1))
done

# --- best-effort cost capture (gemini json mode only; never fails the consult) --------------------
if [[ "${CONSULT_GEMINI_JSON:-0}" == "1" ]]; then
  gj="$RUN_DIR/${LABEL}.gemini.json"
  if [[ -s "$gj" ]]; then
    "${TICK_BIN:-$ROOT/bin/tick}" cost "CONSULT-$LABEL" --agent gemini --from-gemini-json "$gj" --tool gemini \
      2>/dev/null || warn "gemini tokens not captured (no parseable stats)"
  fi
fi

printf 'consult: %d answered, %d failed -> %s%s\n' "$answered" "$failed" "$RUN_DIR" "$summary"
((answered > 0)) || { warn "all advisors failed"; exit 5; }
exit 0

 succeeded in 0ms:
src/take.js
src/lock.js
src/claim.js
src/identity.js
src/scope.js
src/project.js
src/analyze.js
src/next.js
src/cost.js
src/paths.js
src/events.js
CLAUDE.md
BACKLOG.md
AGENTS.md
GEMINI.md
ROADMAP.md
CODEX.md
TODO_DEFER.md
PROJECT/AGENTS-DOCS.md
PROJECT/3-COMPLETED/blank.md
PROJECT/4-MISC/blank.md
PROJECT/2-WORKING/AUTOMATED-RELAY.md
PROJECT/2-WORKING/COST-COMPARISON.md
PROJECT/2-WORKING/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md
PROJECT/2-WORKING/EXP-AUTOMATION/RUN-4-AGENT-PROMPTS.md
PROJECT/2-WORKING/EXP-AUTOMATION/RUN-4-FEEDBACK-PROMPTS.md
PROJECT/2-WORKING/EXP-AUTOMATION/run4-prompts/ChatGPT-Codex-Instructions.md
PROJECT/2-WORKING/EXP-AUTOMATION/run4-prompts/Gemini-Instructions.md
PROJECT/2-WORKING/EXP-AUTOMATION/FEEDBACK-MBP16.md
PROJECT/2-WORKING/EXP-AUTOMATION/RUN-4-META-BRIEF.md
PROJECT/2-WORKING/blank.md
PROJECT/2-WORKING/COST-OBSERVABILITY-PLAN.md
PROJECT/1-INBOX/FEEDBACK/FEEDBACK-2026-06-15.md
PROJECT/1-INBOX/FEEDBACK/FEEDBACK-KWFS.md
PROJECT/1-INBOX/MARATHON.md
PROJECT/1-INBOX/blank.md
PROJECT/1-INBOX/LOOPS.md
README.md
decisions/2026-06-15-unattended-agent-containment.md
decisions/2026-06-14-graduate-relay-automation-phase-2.md
decisions/2026-06-15-relay-turns-tick-native.md
4X4.md
REAL-AGENT-OBSERVATIONS.md
docs/relay-history/relay-run3-plan.md
docs/relay-history/relay-xyz-skill-review.md
docs/relay-history/relay-run3-results.md
docs/P1-TRINITY.md
docs/P1-TRINITY-ROUND2.md
RECAP.md
snapshot.md
SKILL-BUILD-PLAN.md
relay-automation/consult.sh
relay-automation/PHASE-2-PLAN.md
relay-automation/relay-drive.sh
relay-automation/watchdog.sh
relay-automation/PHASE-2-BUILD-BRIEF.md
relay-automation/runner.sh
relay-automation/README.md
relay-automation/relay-turn-lib.sh
relay-automation/CROSSMODEL-OPTIONA-PLAN.md
relay-automation/QUICKSTART.md
relay-automation/poll.sh
relay-automation/gemini-turn.sh
relay-automation/PHASE-4A-SCOPE.md
relay-automation/codex-turn.sh
relay-automation/PHASE-5-PLAN.md
relay-automation/PHASE-4-PLAN.md
CHANGELOG.md
bin/tick
run3-prompts/gemini.md
run3-prompts/codex.md
run3-prompts/START-HERE.md
LICENSE.md
validate.sh
run2-prompts/gemini.md
run2-prompts/codex.md
run2-prompts/START-HERE.md
skill/consult/SKILL.md
test/claim-cap.sh
test/poll-driver.sh
test/concurrent-claim.sh
test/reap.sh
test/poll-relay.sh
test/circuit-break.sh
test/handoff.sh
test/runner-loop.sh
test/consult.sh
test/watchdog-liveness.sh
test/handoff-exclusive.sh
test/projection-idempotent.sh
test/watchdog-relay.sh
test/_setup.sh
test/analyze.sh
test/path-overlap.sh
test/cost.sh
test/gemini-turn.sh
test/heartbeat.sh
test/codex-turn.sh
test/scope-change.sh
test/take.sh
test/skill-extract.sh
test/auto-sync.sh
sandbox-app/STORE-CONTRACT.md
relay-system/2026-06-17/consult-dogfood.gemini.md
relay-system/2026-06-17/roadmap-combined-qa-review.md
relay-system/2026-06-17/consult-dogfood-question.md
relay-system/2026-06-17/consult-dogfood.codex.md
skill/xyz/SKILL.md
sandbox-app/src/store/validate.js
sandbox-app/src/store/query.js
sandbox-app/src/store/store.js
ingestion/examples/todo-api.project.md
ingestion/README.md
ingestion/PROJECT-SPEC.template.md
ingestion/ingest.js
sandbox-app/package.json
relay-system/2026-06-16/p3-dogfood-relay.gemini-transcript.md
relay-system/2026-06-16/p3-dogfood-relay.md
relay-system/baton-pattern.md
skill/relay-automation/SKILL.md
sandbox-app/src/http/router.js
sandbox-app/src/http/server.js
skill/relay-automation/relay-pkg.tar.gz
skill/relay-automation/make-pkg.sh
sandbox-app/src/http/handlers.js
sandbox-app/test/store/validate.test.js
sandbox-app/test/store/query.test.js
relay-system/2026-06-14/phase4-plan-review.md
sandbox-app/test/store/store.test.js
relay-system/2026-06-14/run4-brief.md
relay-system/2026-06-14/run4-feedback.md
relay-system/2026-06-14/automation-proposal.md
relay-system/2026-06-14/agents-md.md
relay-system/2026-06-14/readme-transport.md
relay-system/2026-06-14/phase2-readiness.md
relay-system/2026-06-15/portability-roadmap-gemini-review.md
relay-system/2026-06-15/cost-observability-plan-review.gemini-transcript.md
relay-system/2026-06-15/phase4a-code-review.md
relay-system/2026-06-15/codex-turn-review-gemini.md
relay-system/2026-06-15/phase4-qa-gate.md
relay-system/2026-06-15/phase4a-scope-check.md
relay-system/2026-06-15/phase5-plan-autorelay.md
relay-system/2026-06-15/cost-observability-plan-review.md
sandbox-app/test/http/router.test.js
sandbox-app/test/http/handlers.test.js
sandbox-app/test/http/server.test.js

codex
I’ve got the new spec and implementation; next I’m checking the existing relay skill and the consult tests to see whether the distinction is crisp and whether the safety claims are actually exercised.
exec
/bin/zsh -lc "nl -ba skill/consult/SKILL.md | sed -n '1,220p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626
 succeeded in 0ms:
     1	---
     2	name: consult
     3	description: One-shot cross-model CONSULT — fan the same question out to Codex and Gemini in parallel (read-only, advisory), then reconcile their answers into one. Use when the user wants a "second opinion", to "ask Codex and Gemini", a "panel" or "cross-model" check, or an independent gut-check on a decision/design/doc before committing — and does NOT need an iterative build/review loop. NOT a relay: a relay is an iterative 1:1 Producer↔Reviewer loop that converges an artifact; a consult is a parallel 1-shot 1:N second opinion, reconciled once. Repo-local — depends on the codex + gemini CLIs and the relay-automation shims, so it is not portable.
     4	---
     5	
     6	# Consult
     7	
     8	**One question → N independent models in parallel → one reconciled answer.**
     9	
    10	A consult asks Codex and Gemini the *same* question at the same time, read-only, and then a
    11	coordinator (Claude) reconciles their answers — surfacing where they **agree**, where they
    12	**disagree**, and giving a single reconciled **call**. It is the fast "ask the other brains before I
    13	commit" move: no copy-paste, no window-shuttling, one step.
    14	
    15	## Consult vs. relay — pick the right tool
    16	
    17	| | **consult** (this skill) | **relay** |
    18	|---|---|---|
    19	| shape | parallel fan-out, 1 question → N models | iterative loop, 2 agents |
    20	| rounds | exactly **one** | many, until `Approved` |
    21	| writes | **none** — advisory only | Producer edits the artifact |
    22	| output | reconciled answer + divergences | a converged artifact |
    23	| use for | a decision, a design gut-check, "is this doc sound?" | building/fixing an artifact under review |
    24	
    25	If after a consult you decide the work needs iteration, *start a relay* — the consult is the cheap
    26	first look, the relay is the build loop.
    27	
    28	## When to use
    29	
    30	- "Get a second opinion." "Ask Codex and Gemini." "What do the other models think?"
    31	- "Panel review" / "cross-model check" / "sanity-check this before I commit."
    32	- An independent gut-check on a plan, design, schema, or doc — where you want *divergent* reads, not
    33	  a single model's confident answer.
    34	
    35	Do **not** use it to build or fix an artifact iteratively — that's `relay`.
    36	
    37	## How it works
    38	
    39	`relay-automation/consult.sh` fans the question out to both advisors **in parallel** and writes each
    40	transcript to a per-run dir `relay-system/<today>/<label>-<HHMMSS>/`. The synthesis is **yours** — the
    41	script only gathers the raw opinions.
    42	
    43	**Provable no-mutation boundary (not best-effort).** Advisors run with their working directory set to a
    44	**throwaway git worktree** checked out from your *current* state — tracked WIP (via `git stash create`)
    45	plus untracked files copied in — so they see exactly what you see, including a brand-new file under
    46	review. Anything an advisor writes lands in that disposable worktree and is destroyed with it; your
    47	real working tree is **never** the advisors' surface, so there is nothing to revert and ambient WIP
    48	cannot be clobbered. (Codex additionally runs `-s read-only`.) This replaced an earlier best-effort
    49	post-hoc revert that the skill's own first dogfood flagged as unsafe.
    50	
    51	```
    52	consult.sh --prompt-file Q.md            # question is the file's contents (may reference repo paths)
    53	consult.sh --prompt "Is X sound?"        # inline question
    54	  [--models codex,gemini]                # which advisors (default both)
    55	  [--out DIR]                            # parent dir (default relay-system/<today>/)
    56	  [--label SLUG]                         # run-subdir + transcript stem (default "consult")
    57	```
    58	
    59	Each run gets its own `<label>-<HHMMSS>/` subdir, so two consults the same day never overwrite each
    60	other. Behavior is covered by `test/consult.sh` in `validate.sh` (WIP preservation, no advisor leak,
    61	graceful degrade, non-git refusal).
    62	
    63	Exit `0` = at least one advisor answered; `5` = all failed; `3` = not a git repo (isolation needs
    64	one); `2` = usage. Per-model failures are reported, not fatal — if Codex's backend is down, Gemini's
    65	answer still comes back (**graceful degrade**, and the degrade is stated, never silent).
    66	
    67	## Steps (the coordinator's job)
    68	
    69	1. **Frame one sharp question.** Put it in a prompt file when it references repo paths (the advisors
    70	   read the files themselves). Be explicit about what "good" looks like, just like a relay's
    71	   Definition of Done.
    72	2. **Fan out:** run `consult.sh` with the prompt + a `--label`. Both models run at once.
    73	3. **Read both transcripts** in `relay-system/<today>/<label>-<HHMMSS>/<label>.codex.md` and `…gemini.*`.
    74	4. **Reconcile — this is the load-bearing step.** Produce a synthesis with three parts, in this order:
    75	   - **Disagree** (first — it's the whole point): every point the two models differ on, with your
    76	     adjudication and *why*.
    77	   - **Agree:** what both independently converged on (higher confidence because it's cross-model).
    78	   - **Reconciled call:** your single recommendation, naming any open risk.
    79	5. **Hand the synthesis back** to the operator. If it reveals the work needs iteration, offer to
    80	   start a `relay`.
    81	
    82	## The one rule that makes a consult worth running
    83	
    84	**Surface disagreement; never average it away.** The entire value of asking two models is the *delta*
    85	between them — the place one caught what the other missed. A synthesis that smooths two answers into
    86	one confident paragraph throws that away and is worse than asking one model, because it launders two
    87	guesses into false consensus. Lead with the disagreements, adjudicate them explicitly, and if you
    88	can't adjudicate one, say so and flag it for the human. (Same failure mode as a review that only
    89	hunts overclaims and misses silent drops: the easy direction satisfices.)
    90	
    91	## Honest caveats
    92	
    93	- **Two models, not ground truth.** Cross-model agreement raises confidence; it does not prove
    94	  correctness — both can share a blind spot or a wrong prior. Treat a unanimous answer as *strong
    95	  signal*, not proof, especially when correctness rides on runtime behavior neither model ran.
    96	- **Isolated by design, not just prompted.** Advisors run in a throwaway worktree and cannot reach
    97	  your real tree, so a consult never changes your code even if an advisor ignores the "advisory only"
    98	  instruction. If a fix is needed, *you* (or a relay) apply it — the independent check stays independent.
    99	- **Cost capture is opt-in.** Default Gemini output is human-readable text. Set `CONSULT_GEMINI_JSON=1`
   100	  to capture `-o json` instead, which enables best-effort `tick cost` token logging (Codex token
   101	  parsing is still deferred — its usage format isn't probed yet).
   102	- **Repo-local, not portable.** Unlike `relay` (model-agnostic, file-only), consult hard-depends on
   103	  the `codex` + `gemini` CLIs being installed and authed and on the `relay-automation` shims.
   104	
   105	## What success looks like
   106	
   107	The operator asks one question and gets back a single, honest, reconciled answer that **shows its
   108	seams** — what the two models agreed on, where they split, and which way the coordinator called it and
   109	why — in one step, with both raw transcripts on disk for audit.

exec
/bin/zsh -lc "nl -ba skill/relay-automation/SKILL.md | sed -n '1,220p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626
 succeeded in 0ms:
     1	---
     2	name: relay-automation
     3	description: Tick-backed, self-healing automation for the file-based /relay review loop — a hands-free poll driver (poll.sh), a relay-turn supervisor (relay-drive.sh), a liveness watchdog (watchdog.sh), a verdict-gated runner (runner.sh), and a headless cross-model turn-taker (codex-turn.sh). Sibling to the xyz/tick skill; depends on a tick runtime with handoff-exclusive claims. Use to run a Producer↔Reviewer relay with auto turn-taking, stall recovery, and (Option A) headless Codex turns.
     4	---
     5	
     6	# relay-automation — sibling skill (bundled package)
     7	
     8	Automates the portable `/relay` review loop on top of `tick`: turns pass hands-free
     9	(all-Claude `/loop` poll), a watchdog recovers stalls, and — with the Codex CLI — a
    10	Codex participant can take its turn **headlessly** (`codex exec`). The portable
    11	`/relay` skill stays dependency-free; **this** tick-dependent automation is its sibling.
    12	
    13	## Components (in `relay-pkg.tar.gz` beside this file)
    14	| Script | Role |
    15	|---|---|
    16	| `relay-automation/poll.sh` | per-tick poll driver (run under `/loop`): claimability guard + dispatch; `--deadline` self-expiry |
    17	| `relay-automation/relay-drive.sh` | relay-turn supervisor: loop a `RELAY-TURN` token to termination; round-cap + no-progress + close-mismatch escalation |
    18	| `relay-automation/watchdog.sh` | liveness: `tick analyze --format json` → parked `RELAY-TURN` → structured escalation; gated reap stub |
    19	| `relay-automation/runner.sh` | single verdict-gated turn (`VERDICT: PASS\|FAIL\|PARKED`) + artifact-scoped clean-tree gate |
    20	| `relay-automation/codex-turn.sh` | **Option A** headless turn-taker: drives a Codex turn via `codex exec` behind a path-allowlist (no push) |
    21	| `relay-automation/README.md` | operator usage (`/loop` invocations, self-closing loops, all-Claude boundary) |
    22	| `test/{poll-driver,poll-relay,watchdog-relay,codex-turn}.sh` | the relay-automation suite |
    23	
    24	## Dependency — E3 detect-or-extract (capability gate, NOT just presence)
    25	The relay rides the **Phase-1 handoff-exclusive `tick` rule** (a `claim`/`take` of a task
    26	whose `handoff_to` is set and ≠ caller is rejected with **zero events**). A host that has
    27	`tick` but predates that change silently breaks the relay. **Before using, run the gate;**
    28	if it fails, install/patch tick (e.g. via the `xyz` skill, which self-extracts the full
    29	runtime) — then re-run the gate.
    30	
    31	```bash
    32	# capability gate — run at repo root after extracting; needs ./bin/tick
    33	gate() {
    34	  local t=./bin/tick d; d="$(mktemp -d)"; TICK_REPO_ROOT="$d" $t init >/dev/null
    35	  TICK_REPO_ROOT="$d" $t log task.created _CAP --agent a >/dev/null
    36	  TICK_REPO_ROOT="$d" $t claim _CAP --agent a --paths "x/**" >/dev/null
    37	  TICK_REPO_ROOT="$d" $t release _CAP --agent a --to b >/dev/null
    38	  local n m; n=$(ls "$d/.tick/events" | wc -l)
    39	  TICK_REPO_ROOT="$d" $t claim _CAP --agent c --paths "x/**" >/dev/null 2>&1   # wrong-handoff: must be rejected, zero events
    40	  m=$(ls "$d/.tick/events" | wc -l); rm -rf "$d"
    41	  [ "$n" = "$m" ] && echo "tick capability OK (handoff-exclusive)" || { echo "FAIL: host tick lacks handoff-exclusive — install/patch tick (xyz skill) first"; return 1; }
    42	}
    43	gate
    44	```
    45	
    46	## Install
    47	The relay scripts + tests ship as `relay-pkg.tar.gz` beside this SKILL.md (regenerable
    48	from sources via `make-pkg.sh`). Extract into a repo that already has a capable `tick`
    49	(run the gate first):
    50	
    51	```bash
    52	DIR="${1:-.}"                        # target repo root (must contain ./bin/tick)
    53	tar xzf skill/relay-automation/relay-pkg.tar.gz -C "$DIR"
    54	# wire the 4 tests into validate.sh's TESTS=( ... ), then:
    55	cd "$DIR" && bash validate.sh        # the relay-automation tests pass alongside tick's
    56	```
    57	
    58	## Usage
    59	See the extracted `relay-automation/README.md` — `/loop` invocations (hands-free relay
    60	turn, designated watchdog poller, single-process supervision), **self-closing loops**
    61	(`--deadline` + self-delete; cron jobs are per-session — always set a deadline), the
    62	**all-Claude boundary** (cross-model stays manual nudge unless driven via `codex-turn.sh`),
    63	and the **Option A** headless Codex path (`codex-turn.sh`: dispatch-gated, path-allowlisted,
    64	no push).

exec
/bin/zsh -lc "nl -ba relay-automation/consult.sh | sed -n '1,260p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	#
     4	# consult.sh — one-shot cross-model CONSULT (a panel of advisors), repo-local.
     5	#
     6	# Fans out the SAME question to Codex and Gemini IN PARALLEL, advisory-only, captures each transcript,
     7	# and leaves the synthesis to the caller (Claude). This is NOT a relay: a relay is an iterative 1:1
     8	# Producer↔Reviewer loop; a consult is a parallel 1-shot 1:N "second opinion," reconciled once.
     9	#
    10	# PROVABLE no-mutation boundary (reworked after the dogfood found the old best-effort revert unsafe):
    11	# advisors run with CWD set to a THROWAWAY git worktree checked out from the operator's CURRENT state
    12	# (tracked WIP via `git stash create` + untracked-not-ignored files copied in). Any file an advisor
    13	# writes lands in that disposable worktree and is destroyed with it — the operator's real working tree
    14	# is NEVER the advisors' surface, so there is nothing to revert and ambient WIP can't be clobbered.
    15	# (Codex stays `-s read-only` on top of that; Gemini's writes, if any, are contained by the worktree.)
    16	#
    17	# Usage:
    18	#   consult.sh --prompt-file Q.md  [--out DIR] [--models codex,gemini] [--label SLUG]
    19	#   consult.sh --prompt "question" [--out DIR] [--models codex,gemini] [--label SLUG]
    20	#
    21	# Options:
    22	#   --prompt-file F   File whose contents are the consult question (it may reference repo paths).
    23	#   --prompt TEXT     Inline question (mutually exclusive with --prompt-file).
    24	#   --out DIR         Parent dir for the run (default: relay-system/<today>/). Each run gets its own
    25	#                     timestamped subdir <label>-<HHMMSS>/ so same-day consults never clobber.
    26	#   --models CSV      Which advisors to run (default: codex,gemini).
    27	#   --label SLUG      Run-subdir + transcript stem (default: consult).
    28	#
    29	# Env config:
    30	#   CODEX_BIN / GEMINI_BIN     binaries (default: codex / gemini); tests inject stubs
    31	#   CODEX_FLAGS                codex sandbox flags (default: -s read-only)
    32	#   GOOGLE_GENAI_USE_GCA       gemini personal-login auth (default: true)
    33	#   CONSULT_GEMINI_JSON=1      capture gemini as -o json (enables best-effort cost.tokens) instead of
    34	#                              readable text (Codex token parsing is still deferred — format un-probed)
    35	#   CONSULT_ROOT               git root to consult against (default: this repo)
    36	#   TICK_BIN                   tick binary for cost capture (default: <root>/bin/tick)
    37	#
    38	# Exit: 0 = at least one advisor answered · 5 = ALL advisors failed · 2 = usage · 3 = not a git repo.
    39	
    40	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    41	ROOT="${CONSULT_ROOT:-"$(cd "$HERE/.." && pwd)"}"
    42	CODEX_BIN="${CODEX_BIN:-codex}"
    43	GEMINI_BIN="${GEMINI_BIN:-gemini}"
    44	die()  { printf 'consult: %s\n' "$*" >&2; exit 2; }
    45	warn() { printf 'consult: %s\n' "$*" >&2; }
    46	
    47	PROMPT_FILE=""; PROMPT_TEXT=""; OUT=""; MODELS="codex,gemini"; LABEL="consult"
    48	while (($# > 0)); do
    49	  case "$1" in
    50	    --prompt-file) PROMPT_FILE="${2:-}"; shift 2 ;;
    51	    --prompt)      PROMPT_TEXT="${2:-}"; shift 2 ;;
    52	    --out)         OUT="${2:-}"; shift 2 ;;
    53	    --models)      MODELS="${2:-}"; shift 2 ;;
    54	    --label)       LABEL="${2:-}"; shift 2 ;;
    55	    --help) sed -n '2,40p' "${BASH_SOURCE[0]}"; exit 0 ;;
    56	    *) die "unknown argument: $1" ;;
    57	  esac
    58	done
    59	
    60	[[ -n "$PROMPT_FILE" || -n "$PROMPT_TEXT" ]] || die "one of --prompt-file or --prompt is required"
    61	[[ -n "$PROMPT_FILE" && -n "$PROMPT_TEXT" ]] && die "--prompt-file and --prompt are mutually exclusive"
    62	if [[ -n "$PROMPT_FILE" ]]; then
    63	  [[ -f "$PROMPT_FILE" ]] || die "prompt file not found: $PROMPT_FILE"
    64	  PROMPT_TEXT="$(cat "$PROMPT_FILE")"
    65	fi
    66	
    67	git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    68	  || { warn "consult requires a git repo (advisor isolation uses a throwaway worktree): $ROOT"; exit 3; }
    69	
    70	OUT="${OUT:-$ROOT/relay-system/$(date +%F)}"
    71	RUN_DIR="$OUT/${LABEL}-$(date +%H%M%S)"
    72	mkdir -p "$RUN_DIR"
    73	
    74	# Advisor preamble: independent, advisory, structured, cite evidence. Each is told a peer answers the
    75	# SAME question separately and a coordinator reconciles — so it gives its OWN read, not a guessed consensus.
    76	PREAMBLE="You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering \
    77	the SAME question separately and a coordinator will reconcile both answers, so give your own honest, \
    78	specific read — do not hedge toward a consensus you cannot see. Read any repo files the question \
    79	references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — \
    80	[Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY \
    81	ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy)."
    82	FULL_PROMPT="$PREAMBLE
    83	
    84	=== CONSULT QUESTION ===
    85	$PROMPT_TEXT"
    86	
    87	# --- build the throwaway worktree = operator's CURRENT visible state, isolated --------------------
    88	# tracked WIP (staged+unstaged) WITHOUT touching the real tree; falls back to HEAD when clean.
    89	base="$(git -C "$ROOT" stash create 2>/dev/null || true)"; base="${base:-HEAD}"
    90	WT="${TMPDIR:-/tmp}/consult-wt-$$-${RANDOM}"
    91	cleanup() {
    92	  git -C "$ROOT" worktree remove --force "$WT" >/dev/null 2>&1 || rm -rf "$WT"
    93	  git -C "$ROOT" worktree prune >/dev/null 2>&1 || true
    94	}
    95	trap cleanup EXIT
    96	git -C "$ROOT" worktree add --detach "$WT" "$base" >/dev/null 2>&1 \
    97	  || die "could not create isolation worktree (base $base)"
    98	# overlay untracked-not-ignored files so advisors see brand-new files (e.g. a skill being reviewed).
    99	while IFS= read -r -d '' f; do
   100	  mkdir -p "$WT/$(dirname "$f")"
   101	  cp -p "$ROOT/$f" "$WT/$f" 2>/dev/null || true
   102	done < <(git -C "$ROOT" ls-files --others --exclude-standard -z 2>/dev/null)
   103	
   104	run_codex() {  # advisors run with CWD = the throwaway worktree
   105	  local out="$1"; read -ra _f <<<"${CODEX_FLAGS:--s read-only}"
   106	  # ${_f[@]+...} guards an EMPTY flags array under `set -u` on bash 3.2 (macOS default).
   107	  ( cd "$WT" && "$CODEX_BIN" exec ${_f[@]+"${_f[@]}"} "$FULL_PROMPT" < /dev/null ) > "$out" 2>&1
   108	}
   109	run_gemini() {
   110	  local out="$1"
   111	  if [[ "${CONSULT_GEMINI_JSON:-0}" == "1" ]]; then
   112	    ( cd "$WT" && GOOGLE_GENAI_USE_GCA="${GOOGLE_GENAI_USE_GCA:-true}" \
   113	        "$GEMINI_BIN" --yolo --skip-trust -o json -p "$FULL_PROMPT" < /dev/null ) > "$out" 2>&1
   114	  else
   115	    ( cd "$WT" && GOOGLE_GENAI_USE_GCA="${GOOGLE_GENAI_USE_GCA:-true}" \
   116	        "$GEMINI_BIN" --yolo --skip-trust -p "$FULL_PROMPT" < /dev/null ) > "$out" 2>&1
   117	  fi
   118	}
   119	
   120	# --- fan out in parallel (indexed arrays — macOS bash 3.2 has no `declare -A`) --------------------
   121	PIDS=(); PMODELS=(); POUTS=()
   122	IFS=',' read -ra _models <<<"$MODELS"
   123	for m in "${_models[@]}"; do
   124	  m="${m// /}"; [[ -n "$m" ]] || continue
   125	  case "$m" in
   126	    codex)
   127	      f="$RUN_DIR/${LABEL}.codex.md"
   128	      run_codex "$f" & PIDS+=("$!"); PMODELS+=("codex"); POUTS+=("$f") ;;
   129	    gemini)
   130	      ext="md"; [[ "${CONSULT_GEMINI_JSON:-0}" == "1" ]] && ext="json"
   131	      f="$RUN_DIR/${LABEL}.gemini.$ext"
   132	      run_gemini "$f" & PIDS+=("$!"); PMODELS+=("gemini"); POUTS+=("$f") ;;
   133	    *) warn "unknown model '$m' — skipping" ;;
   134	  esac
   135	done
   136	((${#PIDS[@]} > 0)) || die "no valid models to consult (got: $MODELS)"
   137	
   138	# --- collect results -----------------------------------------------------------------------------
   139	answered=0; failed=0; summary=""; i=0
   140	while ((i < ${#PIDS[@]})); do
   141	  pid="${PIDS[$i]}"; model="${PMODELS[$i]}"; out="${POUTS[$i]}"
   142	  if wait "$pid"; then
   143	    answered=$((answered + 1)); summary+=$'\n'"  [ok]   $model -> $out"
   144	  else
   145	    failed=$((failed + 1));   summary+=$'\n'"  [FAIL] $model -> $out (see transcript for error)"
   146	  fi
   147	  i=$((i + 1))
   148	done
   149	
   150	# --- best-effort cost capture (gemini json mode only; never fails the consult) --------------------
   151	if [[ "${CONSULT_GEMINI_JSON:-0}" == "1" ]]; then
   152	  gj="$RUN_DIR/${LABEL}.gemini.json"
   153	  if [[ -s "$gj" ]]; then
   154	    "${TICK_BIN:-$ROOT/bin/tick}" cost "CONSULT-$LABEL" --agent gemini --from-gemini-json "$gj" --tool gemini \
   155	      2>/dev/null || warn "gemini tokens not captured (no parseable stats)"
   156	  fi
   157	fi
   158	
   159	printf 'consult: %d answered, %d failed -> %s%s\n' "$answered" "$failed" "$RUN_DIR" "$summary"
   160	((answered > 0)) || { warn "all advisors failed"; exit 5; }
   161	exit 0

exec
/bin/zsh -lc "nl -ba test/consult.sh | sed -n '1,260p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# consult.sh test — the cross-model CONSULT fan-out (relay-automation/consult.sh).
     3	# Uses a STUB that impersonates both codex (`exec` first arg) and gemini (`--yolo` first arg), so no
     4	# network/real CLI is needed. Focuses on the safety properties the dogfood flagged as Blockers:
     5	#   - operator WIP is preserved (advisors run in a throwaway worktree, never the real tree)
     6	#   - an advisor that WRITES cannot leak into the operator's tree
     7	#   - graceful per-model degrade (one fails -> still exit 0); all-fail -> exit 5
     8	#   - non-git root is refused (exit 3) rather than running unisolated
     9	source "$(dirname "$0")/_setup.sh" consult
    10	CONSULT="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/consult.sh"
    11	
    12	# Fixture: a tracked file, committed, then left DIRTY (uncommitted operator WIP).
    13	printf 'original\n' >"$A/tracked.txt"
    14	git -C "$A" add tracked.txt >/dev/null 2>&1; git -C "$A" commit -q -m "seed tracked" >/dev/null 2>&1
    15	printf 'WIP\n' >"$A/tracked.txt"   # operator's uncommitted work — must survive a consult
    16	
    17	# One stub for both advisors: detects which it is by argv, picks its RC, optionally writes (in CWD,
    18	# which consult sets to the throwaway worktree — so any write must NOT reach $A).
    19	STUB="$WORK/advisor-stub"
    20	cat >"$STUB" <<'STUB_EOF'
    21	#!/usr/bin/env bash
    22	set -u
    23	if [ "${1:-}" = "exec" ]; then who=codex; rc="${CODEX_RC:-0}"; else who=gemini; rc="${GEMINI_RC:-0}"; fi
    24	printf 'ANSWER from %s stub\n[Pass] looks fine\nRECOMMENDATION: ship\n' "$who"
    25	if [ "${STUB_WRITE:-0}" = 1 ]; then
    26	  printf 'pwned by %s\n' "$who" > "pwned-by-$who.txt" 2>/dev/null || true   # CWD = worktree
    27	  [ -f tracked.txt ] && printf 'advisor was here\n' >> tracked.txt 2>/dev/null || true
    28	fi
    29	exit "$rc"
    30	STUB_EOF
    31	chmod +x "$STUB"
    32	
    33	OUT="$WORK/cout"   # transcripts OUTSIDE $A, so $A stays clean for the safety assertion
    34	run() { # env passthrough: CODEX_RC, GEMINI_RC, STUB_WRITE set by caller
    35	  CONSULT_ROOT="$A" CODEX_BIN="$STUB" GEMINI_BIN="$STUB" CODEX_FLAGS=" " \
    36	  bash "$CONSULT" --prompt "review please" --out "$OUT" --label t --models codex,gemini "$@"
    37	}
    38	
    39	# --- (1) happy path: both answer, transcripts captured ------------------------------------------
    40	out="$(STUB_WRITE=0 run 2>&1)"; rc=$?
    41	[ "$rc" -eq 0 ] && pass "happy path exits 0" || fail "happy path exit=$rc ($out)"
    42	cfile="$(ls "$OUT"/t-*/t.codex.md 2>/dev/null | head -1)"
    43	gfile="$(ls "$OUT"/t-*/t.gemini.md 2>/dev/null | head -1)"
    44	{ [ -s "$cfile" ] && grep -q "ANSWER from codex" "$cfile"; } && pass "codex transcript captured" || fail "no codex transcript"
    45	{ [ -s "$gfile" ] && grep -q "ANSWER from gemini" "$gfile"; } && pass "gemini transcript captured" || fail "no gemini transcript"
    46	
    47	# --- (2) SAFETY: advisor writes cannot leak; operator WIP preserved -----------------------------
    48	rm -rf "$OUT"
    49	STUB_WRITE=1 run >/dev/null 2>&1 || true
    50	[ "$(cat "$A/tracked.txt")" = "WIP" ] && pass "operator WIP preserved (tracked.txt still WIP)" \
    51	  || fail "operator WIP clobbered: $(cat "$A/tracked.txt")"
    52	if find "$A" -name 'pwned-by-*.txt' 2>/dev/null | grep -q .; then
    53	  fail "advisor write leaked into operator tree"
    54	else
    55	  pass "advisor writes did NOT leak into operator tree"
    56	fi
    57	porc="$(git -C "$A" status --porcelain)"
    58	[ "$porc" = " M tracked.txt" ] && pass "tree shows ONLY the operator's WIP, no advisor churn" \
    59	  || fail "unexpected tree state: [$porc]"
    60	# no leftover worktrees
    61	[ "$(git -C "$A" worktree list | wc -l | tr -d ' ')" = "1" ] && pass "isolation worktree cleaned up" \
    62	  || fail "worktree left behind: $(git -C "$A" worktree list)"
    63	
    64	# --- (3) graceful degrade: gemini fails, codex still answers ------------------------------------
    65	rm -rf "$OUT"
    66	out="$(CODEX_RC=0 GEMINI_RC=1 STUB_WRITE=0 run 2>&1)"; rc=$?
    67	[ "$rc" -eq 0 ] && pass "one-model failure still exits 0 (graceful degrade)" || fail "degrade exit=$rc"
    68	printf '%s' "$out" | grep -q "1 answered, 1 failed" && pass "degrade reported honestly (1 answered, 1 failed)" \
    69	  || fail "degrade not reported: $out"
    70	
    71	# --- (4) all advisors fail -> exit 5 -----------------------------------------------------------
    72	rm -rf "$OUT"
    73	CODEX_RC=1 GEMINI_RC=1 STUB_WRITE=0 run >/dev/null 2>&1; rc=$?
    74	[ "$rc" -eq 5 ] && pass "all-fail exits 5" || fail "all-fail exit=$rc (expected 5)"
    75	
    76	# --- (5) non-git root refused (exit 3), not silently run unisolated -----------------------------
    77	mkdir -p "$WORK/plain"
    78	CONSULT_ROOT="$WORK/plain" CODEX_BIN="$STUB" GEMINI_BIN="$STUB" \
    79	  bash "$CONSULT" --prompt "x" --out "$WORK/pout" --label t --models codex >/dev/null 2>&1; rc=$?
    80	[ "$rc" -eq 3 ] && pass "non-git root refused (exit 3)" || fail "non-git root exit=$rc (expected 3)"
    81	
    82	echo "  consult: $PASS passed, $FAIL failed"
    83	exit 0

codex
The main implementation question is no longer “can advisor edits leak into the repo?”; that part looks materially better. The remaining risk is broader than git state: Gemini is being launched unsandboxed, so I’m checking whether the repo documents that boundary accurately or overstates “read-only.”
exec
/bin/zsh -lc "nl -ba relay-automation/gemini-turn.sh | sed -n '1,220p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626
exec
/bin/zsh -lc "rg -n \"--yolo|skip-trust|read-only|consult\" relay-automation skill README.md docs decisions test -g '"'!relay-system/**'"'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	#
     4	# gemini-turn.sh — headless turn-taker for the GEMINI agent. Thin dispatch wrapper over the
     5	# shared safety core (relay-turn-lib.sh) — the SAME containment contract as codex-turn.sh,
     6	# proving the boundary is model-agnostic (decisions/2026-06-15-unattended-agent-containment.md).
     7	#
     8	# History: first drafted standalone by Gemini (fe0bd61), an exact parallel to codex-turn.sh.
     9	# Reconciled here onto the shared core (boundary in ONE place, not duplicated) AND corrected the
    10	# headless invocation: the Gemini CLI has NO `exec` subcommand — headless is `gemini -p`, and an
    11	# unattended turn needs GCA auth + `--yolo` + `--skip-trust` (caught by live-running the CLI 0.46.0).
    12	#
    13	# Invoked by relay-drive.sh as --agent-cmd, with env:
    14	#   RELAY_FILE  — relay thread file (always allowlisted)
    15	#   RELAY_TASK  — tick turn-token (default RELAY-TURN)
    16	#   RELAY_AGENT — current actor (the token's claimer/handoff_to)
    17	# Shim config:
    18	#   GEMINI_AGENT     — the agent id this shim drives; NO-OPS unless RELAY_AGENT==GEMINI_AGENT
    19	#   ALLOW_PATHS      — comma-separated extra git paths the turn may change (e.g. the artifact)
    20	#   RELAY_PEER       — optional: the other agent's id, so the turn hands off "--to <peer>" (else the
    21	#                      prompt says "the other agent", which a live model may resolve to a role name)
    22	#   GEMINI_BIN       — gemini binary (default: gemini); tests inject a stub
    23	#   GEMINI_TURN_ROOT — git root to guard (default: this repo); tests point at a fixture
    24	#   GEMINI_LOG       — where to write the gemini transcript (default: stderr)
    25	#
    26	# Auth/headless contract (validated 2026-06-15, gemini-cli 0.46.0):
    27	#   GOOGLE_GENAI_USE_GCA=true  — personal Google login (free tier), reuses ~/.gemini/oauth_creds.json
    28	#   -p "<prompt>"              — non-interactive (headless) mode
    29	#   --yolo                     — auto-approve tool calls (shell for tick, edit for the relay file)
    30	#   --skip-trust               — bypass the trusted-folder prompt in an automated environment
    31	#
    32	# Exit: 0 acted/deferred · 5 gemini failed · 6 off-allowlist edit (reverted) · 2 usage.
    33	
    34	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    35	# shellcheck source=relay-turn-lib.sh
    36	source "$HERE/relay-turn-lib.sh"
    37	
    38	ROOT="${GEMINI_TURN_ROOT:-"$(cd "$HERE/.." && pwd)"}"
    39	GEMINI_BIN="${GEMINI_BIN:-gemini}"
    40	die() { printf 'gemini-turn: %s\n' "$*" >&2; exit 2; }
    41	
    42	me="${RELAY_AGENT:-}"; f="${RELAY_FILE:-}"; t="${RELAY_TASK:-RELAY-TURN}"
    43	gemini_agent="${GEMINI_AGENT:-}"
    44	[[ -n "$me" ]] || die "RELAY_AGENT required"
    45	[[ -n "$f" ]] || die "RELAY_FILE required"
    46	[[ -n "$gemini_agent" ]] || die "GEMINI_AGENT required"
    47	
    48	# Dispatch only for the Gemini agent; defer otherwise (that window drives its own turn).
    49	if [[ "$me" != "$gemini_agent" ]]; then
    50	  printf 'gemini-turn: actor %s is not the Gemini agent (%s) — deferring (window-driven)\n' "$me" "$gemini_agent" >&2
    51	  exit 0
    52	fi
    53	
    54	rtl_init "$ROOT" "$f" "${ALLOW_PATHS:-}"
    55	prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"
    56	
    57	# Transcript/log: default to a $TMPDIR file (NOT the repo tree — the safety guard in
    58	# relay-turn-lib.sh deletes any in-tree log). A persisted transcript is both the debug record AND
    59	# the token source: `-o json` makes the CLI emit a stats block we parse for cost.tokens (Phase 1).
    60	GEMINI_LOG="${GEMINI_LOG:-${TMPDIR:-/tmp}/gemini-turn-$$.json}"
    61	GEMINI_OUTPUT_FORMAT="${GEMINI_OUTPUT_FORMAT:-json}"
    62	
    63	# Run the Gemini turn headless (token ops + edit the relay file; NO git), then enforce the boundary.
    64	rtl_before
    65	GOOGLE_GENAI_USE_GCA="${GOOGLE_GENAI_USE_GCA:-true}" \
    66	  "$GEMINI_BIN" --yolo --skip-trust -o "$GEMINI_OUTPUT_FORMAT" -p "$prompt" < /dev/null > "$GEMINI_LOG" 2>&1 \
    67	  || { printf 'gemini-turn: gemini -p failed\n' >&2; exit 5; }
    68	rtl_enforce "$t" "$me" "$GEMINI_LOG" "gemini"
    69	
    70	# Best-effort cost capture (Phase 1, COST-OBSERVABILITY-PLAN): parse the CLI's own token stats and
    71	# log a cost.tokens event. NEVER fails the turn — the turn already committed; a missing/unparseable
    72	# stats block just means "tokens not captured" (the loud-partial signal), not a failed turn.
    73	if [[ -s "$GEMINI_LOG" ]]; then
    74	  "${TICK_BIN:-$ROOT/bin/tick}" cost "$t" --agent "$me" --from-gemini-json "$GEMINI_LOG" --tool gemini \
    75	    || printf 'gemini-turn: tokens not captured for %s (no parseable stats in transcript)\n' "$t" >&2
    76	fi

 exited 2 in 0ms:
rg: unrecognized flag --yolo|skip-trust|read-only|consult

exec
/bin/zsh -lc "nl -ba relay-automation/README.md | sed -n '1,240p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626
 succeeded in 0ms:
     1	# relay-automation
     2	
     3	A tick-backed, self-healing automation layer for the manual `/relay` review loop
     4	and `xyz` build swarms. Built in phases on top of `tick` (see
     5	[PROPOSAL-AUTOMATION.md](../PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md)).
     6	
     7	**Execution contract: Option B (baton + poll)** — the turn itself is taken by a
     8	live Claude window (driven by `/loop`) or by a human one-line nudge for non-Claude
     9	windows. There is **no headless agent CLI** in this environment (spike, 2026-06-14);
    10	fully-unattended Option A is a documented future upgrade (see
    11	[PHASE-2-PLAN.md](PHASE-2-PLAN.md) → "Future upgrade — Option A").
    12	
    13	## Components
    14	| Script | Role |
    15	|---|---|
    16	| `poll.sh` | **Phase 4** per-tick poll driver. Reads state, applies the guard, dispatches `runner.sh`/`watchdog.sh` or idles. Run under `/loop`. |
    17	| `runner.sh` | **Phase 3** single agent/turn: claim → run (`--agent-cmd`) → verdict gate (`VERDICT: PASS\|FAIL\|PARKED`) → done/retry; artifact-scoped clean-tree gate. |
    18	| `watchdog.sh` | **Phase 2** liveness: `tick analyze --format json` → parked `parked_suspects[]` → structured escalation record; reap gated behind `--allow-reap` (stub, pending an authority decision). |
    19	| `relay-drive.sh` | **Phase 4b** relay supervisor: loops a `/relay` Producer↔Reviewer thread to termination via a turn-taker; round cap + no-progress escalation. |
    20	| `relay-turn-lib.sh` | **Shared safety core** (sourced, not run): the model-agnostic containment contract — path-allowlist + commit-bypass guard + no-push. Both headless turn-takers source this so the boundary lives in ONE place. See [decisions/2026-06-15-unattended-agent-containment.md](../decisions/2026-06-15-unattended-agent-containment.md). |
    21	| `codex-turn.sh` | **Option-A** headless turn-taker for the **Codex** agent (`codex exec`); thin dispatch wrapper over `relay-turn-lib.sh`. |
    22	| `gemini-turn.sh` | **Option-A** headless turn-taker for the **Gemini** agent (`gemini --yolo --skip-trust -p`, GCA auth); thin dispatch wrapper over the same `relay-turn-lib.sh`. First drafted standalone by Gemini, reconciled onto the shared core + corrected invocation; live-validated 2026-06-15. |
    23	
    24	## Operator usage (Option B)
    25	
    26	### Hands-free relay turn (all-Claude only)
    27	In each Claude window, run a guarded `/loop` that uses `poll.sh` as the gate, then
    28	takes the turn from the relay file's embedded `▶ TAKE YOUR TURN` instructions:
    29	```
    30	# Producer window (agent id = the agent the RELAY-TURN token is handed to)
    31	/loop 60s run relay-automation/poll.sh --mode relay --agent claude-a \
    32	  --relay-file relay-system/<date>/<slug>.md --artifact <path-under-review> --dry-run ;\
    33	  if it prints "DECISION: run-runner", take your turn on that relay file per its embedded \
    34	  instructions (review/produce, append your block, `tick release RELAY-TURN --to <other>` or
    35	  `done` on approve, commit, push); otherwise do nothing.
    36	# Reviewer window: same, with that window's --agent id
    37	```
    38	**Whose-turn is the `RELAY-TURN` tick task** (handed off via `tick release --to`), so the
    39	Phase-1 handoff-exclusive rule + the Phase-2 watchdog both apply. The guard *is* the lock:
    40	a window acts only when the token is claimable by **its** agent **and** the artifact scope is
    41	clean. `poll.sh` exits `10` on a closed relay (file `STATUS: Approved`) so the loop can stop.
    42	*(Default `--relay-task RELAY-TURN`; seed it at relay setup, handed to the first actor.)*
    43	
    44	**Poll interval — cache-warmth tradeoff.** `60s` keeps Claude Code's prompt cache warm
    45	(≈5-min TTL); the **lock/heartbeat is the real correctness guard, not the timer**, so a longer
    46	interval only adds latency, never a race. Use ~`60s` for active relays, longer (e.g. `120s`)
    47	for the lower-frequency watchdog poller.
    48	
    49	**Self-closing loops (no stray cron housekeeping).** Launch each loop with a deadline so it
    50	ends on the first of: relay `Approved`/`Closed`, **or** the deadline:
    51	`--deadline "$(date -v+30M +%s)"` (macOS) / `--deadline "$(date -d '+30 min' +%s)"` (GNU).
    52	Past the deadline `poll.sh` prints `DECISION: stop`; the loop prompt then `CronList`s and
    53	`CronDelete`s its own job. Cron jobs are per-session — you can't stop another window's loop
    54	from yours, so always set a deadline. See the `/relay` skill → "Self-closing loops".
    55	
    56	### Designated watchdog (exactly ONE window)
    57	Only one poller holds watchdog authority, so a stalled turn is recovered without
    58	double-escalation:
    59	```
    60	/loop 120s run relay-automation/poll.sh --mode relay --agent coordinator \
    61	  --relay-file relay-system/<date>/<slug>.md --watchdog-authority ;\
    62	  if it prints "DECISION: run-watchdog", it has escalated the parked turn — surface it to me.
    63	```
    64	
    65	### Single-process relay supervision (one window drives the whole thread)
    66	```
    67	relay-automation/relay-drive.sh --relay-file relay-system/<date>/<slug>.md \
    68	  --agent-cmd "<turn-taker>" --round-cap 6
    69	```
    70	`--agent-cmd` is the turn-taker seam (a CLI in a future Option A; in Option B the
    71	turn is taken by the live window / baton). Exits: `0` closed Approved/Closed,
    72	`3` no-progress, `4` round cap without Approved.
    73	
    74	### Cross-model windows (Codex / Gemini) — manual nudge
    75	Non-Claude windows can't self-wake. The operator's whole job is **one line**:
    76	```
    77	take your turn on relay-system/<date>/<slug>.md
    78	```
    79	The relay file embeds the `▶ TAKE YOUR TURN` instructions, so any agent acts from
    80	the file alone. `poll.sh` detects a cross-model turn and emits this nudge text
    81	rather than silently idling.
    82	
    83	## Boundary (load-bearing)
    84	- **Hands-free poll is all-Claude only** — it relies on Claude Code's in-session `/loop`. Cross-model stays on the manual nudge.
    85	- **Not a durable scheduler / not unattended-without-a-window.** A Claude window must be open and looping. Truly unattended runs need Option A (future).
    86	- The portable `/relay` skill stays dependency-free; this tick-driven automation lives here.

exec
/bin/zsh -lc 'rg -n -e "--yolo" -e "skip-trust" -e "read-only" -e "consult" relay-automation skill README.md docs decisions test' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626
 succeeded in 0ms:
skill/consult/SKILL.md:2:name: consult
skill/consult/SKILL.md:3:description: One-shot cross-model CONSULT — fan the same question out to Codex and Gemini in parallel (read-only, advisory), then reconcile their answers into one. Use when the user wants a "second opinion", to "ask Codex and Gemini", a "panel" or "cross-model" check, or an independent gut-check on a decision/design/doc before committing — and does NOT need an iterative build/review loop. NOT a relay: a relay is an iterative 1:1 Producer↔Reviewer loop that converges an artifact; a consult is a parallel 1-shot 1:N second opinion, reconciled once. Repo-local — depends on the codex + gemini CLIs and the relay-automation shims, so it is not portable.
skill/consult/SKILL.md:10:A consult asks Codex and Gemini the *same* question at the same time, read-only, and then a
skill/consult/SKILL.md:17:| | **consult** (this skill) | **relay** |
skill/consult/SKILL.md:25:If after a consult you decide the work needs iteration, *start a relay* — the consult is the cheap
skill/consult/SKILL.md:39:`relay-automation/consult.sh` fans the question out to both advisors **in parallel** and writes each
skill/consult/SKILL.md:48:cannot be clobbered. (Codex additionally runs `-s read-only`.) This replaced an earlier best-effort
skill/consult/SKILL.md:52:consult.sh --prompt-file Q.md            # question is the file's contents (may reference repo paths)
skill/consult/SKILL.md:53:consult.sh --prompt "Is X sound?"        # inline question
skill/consult/SKILL.md:56:  [--label SLUG]                         # run-subdir + transcript stem (default "consult")
skill/consult/SKILL.md:59:Each run gets its own `<label>-<HHMMSS>/` subdir, so two consults the same day never overwrite each
skill/consult/SKILL.md:60:other. Behavior is covered by `test/consult.sh` in `validate.sh` (WIP preservation, no advisor leak,
skill/consult/SKILL.md:72:2. **Fan out:** run `consult.sh` with the prompt + a `--label`. Both models run at once.
skill/consult/SKILL.md:82:## The one rule that makes a consult worth running
skill/consult/SKILL.md:97:  your real tree, so a consult never changes your code even if an advisor ignores the "advisory only"
skill/consult/SKILL.md:102:- **Repo-local, not portable.** Unlike `relay` (model-agnostic, file-only), consult hard-depends on
relay-automation/consult.sh:4:# consult.sh — one-shot cross-model CONSULT (a panel of advisors), repo-local.
relay-automation/consult.sh:8:# Producer↔Reviewer loop; a consult is a parallel 1-shot 1:N "second opinion," reconciled once.
relay-automation/consult.sh:15:# (Codex stays `-s read-only` on top of that; Gemini's writes, if any, are contained by the worktree.)
relay-automation/consult.sh:18:#   consult.sh --prompt-file Q.md  [--out DIR] [--models codex,gemini] [--label SLUG]
relay-automation/consult.sh:19:#   consult.sh --prompt "question" [--out DIR] [--models codex,gemini] [--label SLUG]
relay-automation/consult.sh:22:#   --prompt-file F   File whose contents are the consult question (it may reference repo paths).
relay-automation/consult.sh:25:#                     timestamped subdir <label>-<HHMMSS>/ so same-day consults never clobber.
relay-automation/consult.sh:27:#   --label SLUG      Run-subdir + transcript stem (default: consult).
relay-automation/consult.sh:31:#   CODEX_FLAGS                codex sandbox flags (default: -s read-only)
relay-automation/consult.sh:35:#   CONSULT_ROOT               git root to consult against (default: this repo)
relay-automation/consult.sh:44:die()  { printf 'consult: %s\n' "$*" >&2; exit 2; }
relay-automation/consult.sh:45:warn() { printf 'consult: %s\n' "$*" >&2; }
relay-automation/consult.sh:47:PROMPT_FILE=""; PROMPT_TEXT=""; OUT=""; MODELS="codex,gemini"; LABEL="consult"
relay-automation/consult.sh:68:  || { warn "consult requires a git repo (advisor isolation uses a throwaway worktree): $ROOT"; exit 3; }
relay-automation/consult.sh:76:PREAMBLE="You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering \
relay-automation/consult.sh:90:WT="${TMPDIR:-/tmp}/consult-wt-$$-${RANDOM}"
relay-automation/consult.sh:105:  local out="$1"; read -ra _f <<<"${CODEX_FLAGS:--s read-only}"
relay-automation/consult.sh:113:        "$GEMINI_BIN" --yolo --skip-trust -o json -p "$FULL_PROMPT" < /dev/null ) > "$out" 2>&1
relay-automation/consult.sh:116:        "$GEMINI_BIN" --yolo --skip-trust -p "$FULL_PROMPT" < /dev/null ) > "$out" 2>&1
relay-automation/consult.sh:136:((${#PIDS[@]} > 0)) || die "no valid models to consult (got: $MODELS)"
relay-automation/consult.sh:150:# --- best-effort cost capture (gemini json mode only; never fails the consult) --------------------
relay-automation/consult.sh:159:printf 'consult: %d answered, %d failed -> %s%s\n' "$answered" "$failed" "$RUN_DIR" "$summary"
decisions/2026-06-15-unattended-agent-containment.md:68:  subcommand; headless is `-p`) and lacked GCA/`--yolo`/`--skip-trust`, so it could not take a live
README.md:37:| `tick next --agent <id>` | Return the next compatible task (read-only). Reports the claim limit instead of a task if the agent is at the cap. |
test/consult.sh:2:# consult.sh test — the cross-model CONSULT fan-out (relay-automation/consult.sh).
test/consult.sh:3:# Uses a STUB that impersonates both codex (`exec` first arg) and gemini (`--yolo` first arg), so no
test/consult.sh:9:source "$(dirname "$0")/_setup.sh" consult
test/consult.sh:10:CONSULT="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/consult.sh"
test/consult.sh:15:printf 'WIP\n' >"$A/tracked.txt"   # operator's uncommitted work — must survive a consult
test/consult.sh:18:# which consult sets to the throwaway worktree — so any write must NOT reach $A).
test/consult.sh:82:echo "  consult: $PASS passed, $FAIL failed"
docs/P1-TRINITY-ROUND2.md:63:`tick next` called `project()` internally, which rewrote `STATE.md` even on a read-only operation. Every `tick next` made `git status` show unstaged changes.
docs/P1-TRINITY-ROUND2.md:85:| `tick next` read-only | `src/next.js` | Folds events in memory; never writes `STATE.md` |
relay-automation/gemini-turn.sh:11:# unattended turn needs GCA auth + `--yolo` + `--skip-trust` (caught by live-running the CLI 0.46.0).
relay-automation/gemini-turn.sh:29:#   --yolo                     — auto-approve tool calls (shell for tick, edit for the relay file)
relay-automation/gemini-turn.sh:30:#   --skip-trust               — bypass the trusted-folder prompt in an automated environment
relay-automation/gemini-turn.sh:66:  "$GEMINI_BIN" --yolo --skip-trust -o "$GEMINI_OUTPUT_FORMAT" -p "$prompt" < /dev/null > "$GEMINI_LOG" 2>&1 \
skill/xyz/SKILL.md:165:  tick next --agent <id>                           (read-only, no STATE.md write)
skill/xyz/SKILL.md:2079:**read-only**, and writes a structured profile **into its own lane**. Naturally
relay-automation/codex-turn.sh:51:# read-only); operator-overridable for tighter/looser policies.
relay-automation/README.md:22:| `gemini-turn.sh` | **Option-A** headless turn-taker for the **Gemini** agent (`gemini --yolo --skip-trust -p`, GCA auth); thin dispatch wrapper over the same `relay-turn-lib.sh`. First drafted standalone by Gemini, reconciled onto the shared core + corrected invocation; live-validated 2026-06-15. |
test/gemini-turn.sh:15:# Stub `gemini`: ignores its flags (--yolo --skip-trust -p <prompt>); performs a real turn as

exec
/bin/zsh -lc "nl -ba decisions/2026-06-15-unattended-agent-containment.md | sed -n '1,260p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626
 succeeded in 0ms:
     1	---
     2	status: Decided
     3	date: 2026-06-15
     4	reversibility: Costly
     5	revisit: "first real unattended Option-A run (no live window) — if any off-lane change reaches a commit or a push, reopen"
     6	related:
     7	  - decisions/2026-06-15-relay-turns-tick-native.md
     8	decider: "@noelsaw1"
     9	---
    10	
    11	# Containment for an unattended committing agent = path-allowlist + commit-bypass guard + no-push
    12	
    13	**Decision:** The safety boundary for a headless agent that takes relay turns and commits
    14	(`relay-automation/codex-turn.sh`) is three enforced invariants, owned by the shim (not the
    15	supervisor): (1) a **path allowlist** — revert + fail on any change outside {relay file,
    16	artifact allowlist}; (2) a **commit-bypass guard** — snapshot `before_head`, `reset --hard` +
    17	fail if the agent committed during its turn; (3) **no push** — commit file-scoped, leave
    18	pushing to a separate human step. This is accepted as *sufficient* containment to let an
    19	unattended agent commit to the working branch.
    20	
    21	**The bet:** These three invariants close every path by which an off-lane or unreviewed change
    22	could reach shared history without a human in the loop. If a real unattended run finds a fourth
    23	escape (e.g. ignored-file damage, a `.git` edit, an `--no-verify` trick, a symlink), the bet is
    24	wrong and the boundary needs another guard.
    25	
    26	**Rejected:**
    27	- *Raw `--agent-cmd` string as the turn-taker* — no place to enforce safety; Codex's own review
    28	  flagged it as too brittle. The shim exists precisely to be that place.
    29	- *Supervisor (`relay-drive.sh`) owns the clean-tree gate* — rejected; the shim owns it, so the
    30	  boundary lives with the thing that runs the agent.
    31	- *`git clean -Xdf` to also wipe ignored files* — rejected; it would destroy `.tick/` (the
    32	  gitignored coordination state the turn legitimately writes). Ignored-file safety is deferred
    33	  to the codex sandbox (`-c sandbox_permissions`) instead.
    34	
    35	**Expected signal:** A real unattended Option-A run (a runner/service, no live window) completes
    36	a multi-turn relay with **zero** off-allowlist changes reaching a commit or push — on the event
    37	that run first happens, not a fixed date.
    38	
    39	**Reversibility:** Costly — the contract is wired into `codex-turn.sh` + `test/codex-turn.sh`
    40	(16 assertions) + the packaged skill tarball; changing it touches all three plus any agent-drive
    41	shim that adopts it (e.g. a future `gemini-turn.sh`).
    42	
    43	**Revisit trigger:** The first real unattended run (above). Also reopen immediately if any
    44	adopting shim (Codex or Gemini) is observed letting an off-lane change through in a live turn.
    45	
    46	## Updates
    47	<!-- append-only, newest last -->
    48	- 2026-06-15 — Recorded. Boundary is **3-model validated**: Claude authored the shim, Codex
    49	  (headless review) added the allowlist + no-push contract, Gemini (manual `/relay`, 3rd model)
    50	  found + cleared two bypasses *through* it — git-commit-bypass and quoted-path — and Approved
    51	  the fixes (r3). `test/codex-turn.sh` 10→16, `validate.sh` 20/20. Strong early signal, but the
    52	  "sufficient for unattended" bet stays **Decided** (not Validated) until a real no-window run.
    53	- 2026-06-15 — Generalization in progress: **Gemini is building its own `gemini-turn.sh`** (a
    54	  sibling turn-taker for itself, same role as `codex-turn.sh`). It should adopt these three
    55	  invariants; if it does and behaves, that's corroborating evidence — if it lets an off-lane
    56	  change through, that fires the revisit trigger.
    57	- 2026-06-15 — **Corroborating evidence (2nd model adopted the boundary, live).** Refactored the
    58	  three invariants into a shared sourced core (`relay-automation/relay-turn-lib.sh`); `codex-turn.sh`
    59	  + a new `gemini-turn.sh` are thin wrappers over it. A **real `gemini -p` turn** (gemini-cli 0.46.0,
    60	  GCA auth) took a relay review turn through `gemini-turn.sh`: edited only the relay file, committed
    61	  file-scoped, no push, and **left the reviewed artifact untouched** — containment held for a second
    62	  independent model. `test/gemini-turn.sh` 13/13, `validate.sh` 21/21. Bet still **Decided** (this
    63	  was a single *supervised* turn, not a real multi-turn *unattended* run). Live run also surfaced a
    64	  prompt-clarity gap (peer agent unnamed → released to a role name) — fixed with optional `RELAY_PEER`.
    65	- 2026-06-15 — **Reconciliation + a reimplementation-bug datapoint (supports the "share, don't copy"
    66	  rationale).** Gemini independently committed a *standalone* `gemini-turn.sh` (`fe0bd61`) that copied
    67	  `codex-turn.sh`'s boundary verbatim — but it invoked **`gemini exec`** (the Gemini CLI has no such
    68	  subcommand; headless is `-p`) and lacked GCA/`--yolo`/`--skip-trust`, so it could not take a live
    69	  turn. Converged on one `gemini-turn.sh` = its name + the shared sourced core + the corrected
    70	  invocation. This is concrete evidence for the Rejected-alternative reasoning: a *copied* boundary is
    71	  exactly where divergence/breakage enters; the shared `relay-turn-lib.sh` is the durable surface.

exec
/bin/zsh -lc "nl -ba README.md | sed -n '1,260p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626
 succeeded in 0ms:
     1	# XYZ - A 3 Agent Coordination System (Beta)
     2	
     3	An early skill to let Claude Code, Codex, and Gemini work the same codebase concurrently without colliding. 
     4	
     5	## Status
     6	
     7	- All 12 acceptance tests pass — run `./validate.sh`.
     8	- Real-agent hand-test results: see [`REAL-AGENT-OBSERVATIONS.md`](REAL-AGENT-OBSERVATIONS.md).
     9	- Spike recap: see [`RECAP.md`](RECAP.md).
    10	
    11	## What it is
    12	
    13	`tick` is a tiny CLI backed by an event log under `.tick/events/`. Each event is a separate JSONL file (one event per file = disjoint files = zero merge conflicts). `tick project` folds events into `.tick/STATE.md`. Coordination is **local-transport** (since Run 2): every verb is a pure append to a shared local `.tick/events/` — no git push or fetch per event. Peer agents see each other's events by reading the same shared directory, and a per-repo `O_EXCL` lock (`withClaimLock`, under `.tick/locks/`) serialises concurrent claims into a real mutex. `git` is used only incidentally — `tick` locates the repo root via `git rev-parse`, and `tick reap` defaults its actor name from `git config user.name`. Coordination state and `tick analyze` read only `.tick/`.
    14	
    15	## Quickstart (single repo)
    16	
    17	```bash
    18	# from the repo root:
    19	./bin/tick init
    20	./bin/tick log task.created TASK-001 \
    21	  --agent dispatcher --priority 10 --paths "src/auth/**"
    22	./bin/tick project
    23	cat .tick/STATE.md
    24	```
    25	
    26	## CLI verbs
    27	
    28	No verb touches the network — every verb appends locally to `.tick/events/`.
    29	
    30	| Verb | Purpose |
    31	|---|---|
    32	| `tick init` | `mkdir -p .tick/events` |
    33	| `tick log <type> <task> ...` | Append a raw event |
    34	| `tick project` | Rebuild `.tick/STATE.md` from events |
    35	| `tick claim <task> --agent <id> --paths <globs>` | Claim a task. Serialised by an `O_EXCL` lock so concurrent claims resolve to exactly one winner — a real mutex, no tie-breaker. Refused if the agent already holds 2 active claims (the cap). |
    36	| `tick take --agent <id>` | Atomic `next` + `claim` under one lock — the recommended way to grab work, since it closes the `next`→`claim` race. Claims the task with the paths it was seeded with. |
    37	| `tick next --agent <id>` | Return the next compatible task (read-only). Reports the claim limit instead of a task if the agent is at the cap. |
    38	| `tick scope <task> --agent <id> --paths <globs>` | Replace the claim's path scope |
    39	| `tick release <task> --agent <id> [--to <agent>]` | Release claim, optionally hand off |
    40	| `tick break <task> --agent <id> --reason "..."` | Mark task circuit-broken; excluded from `tick next` for everyone |
    41	| `tick done <task> --agent <id> [--note "..."]` | Mark complete |
    42	| `tick ping <task> --agent <id> [--note "..."]` | Heartbeat on an active claim so `tick analyze` can tell a live claim from a parked/stalled one |
    43	| `tick info <task>` | Print a task's current state — status, priority, owner, declared paths |
    44	| `tick reap <agent> [--by <id>]` | Coordinator lever: release every active claim held by a presumed-crashed agent so peers can pick the work back up. Manual and logged — not auto-recovery. |
    45	| `tick analyze [--format human\|md\|json] [--write <file>]` | Audit a run from the event log alone: run window, **concurrent-claim time** (the primary metric), parked-claim suspects, and per-agent event counts (claims, dones, heartbeats, releases, scope changes, breaks). Drift / file-collision attribution is **not** automated — see [Auditing a real-agent run](#auditing-a-real-agent-run). |
    46	
    47	`--paths` accepts comma-separated globs: `--paths "src/auth/**,tests/auth/**"`.
    48	
    49	## Multi-agent setup: one shared event log
    50	
    51	Coordination state lives in a single `.tick/events/` directory that every agent reads and writes, so the simplest (and tested) setup is **one shared `TICK_REPO_ROOT`**. There is no per-event push: an agent's `tick claim` is visible to peers the instant the event file lands, and the `O_EXCL` lock serialises concurrent claims. Point every agent's `tick` at the same root:
    52	
    53	```bash
    54	export TICK_REPO_ROOT=/path/to/shared/repo   # same value in every agent's session
    55	./bin/tick init
    56	```
    57	
    58	Each agent passes its own ID with `--agent` on every verb. That flag — not git identity — is authoritative for claims; the old `--agent`-vs-`git config user.name` cross-check was removed in Run 2.
    59	
    60	> **Caveat — per-agent attribution is coarse in the shared-tree PoC.** Coordination itself doesn't need git identity (every claim carries `--agent`), so the shared tree is fine for running the protocol. Commit-level attribution is the soft spot: a single working tree has only one `git config user.name` at a time, and that identity was observed flipping between agents in Run 2. Treat the `--agent` field in the event log as the source of truth for who did what; richer multi-checkout attribution is future work — see [`RECAP.md`](RECAP.md).
    61	
    62	**Historical note.** Pre-Run-2 builds used a distributed transport: each critical event auto-`fetch`+`rebase`+`commit`+`push` so separate clones on a shared branch could see each other. That model — and its worktree friction (same-branch checkouts refused; per-child-branch pushes invisible to peers) — is what motivated the move to local transport. `bin/tick` no longer pushes.
    63	
    64	## Agent integration prompt snippet
    65	
    66	Paste this verbatim into each agent's system prompt or project instructions:
    67	
    68	```
    69	You are coordinating with other AI agents on this codebase via the `tick` CLI
    70	at bin/tick. Your agent ID is <YOUR-ID>.
    71	
    72	ONE-TIME SETUP (run once at session start):
    73	  git config user.name <YOUR-ID>
    74	  git config user.email <YOUR-ID>@trinity.local
    75	This lets `tick analyze` attribute your work commits by git author name. (Your
    76	`--agent <YOUR-ID>` flag is what's authoritative for claims; identity is only
    77	for post-run attribution.)
    78	
    79	BEFORE EDITING ANY FILES — grab a task first:
    80	  Preferred: `tick take --agent <YOUR-ID>` — atomically runs `next` + `claim`
    81	  under one lock, so you never lose a task to the next->claim race. It prints
    82	  `won: <TASK-ID> ...`, or `(no available task)`.
    83	
    84	  Manual equivalent (use if you need to declare extra paths up front):
    85	    1. `tick next --agent <YOUR-ID>` to see what task is yours.
    86	    2. `tick claim <TASK-ID> --agent <YOUR-ID> --paths "<glob1>,<glob2>"`
    87	       declaring every file glob you intend to touch.
    88	    3. If it prints `lost: ...`, someone else holds it — run `tick next` again.
    89	
    90	CLAIM LIMIT: You may hold AT MOST 2 active claims at once. Finish (`tick done`)
    91	or release (`tick release`) a task before claiming a third. `tick next` and
    92	`tick claim` will refuse to give you a third — that is expected, not an error.
    93	
    94	DEPENDENCIES: Use only the Node standard library — `node:http`, `node:test`,
    95	`node:assert`. Do NOT install dependencies, do NOT edit `package.json`, do NOT
    96	create a lockfile. `package.json` is shared and outside every task's scope;
    97	touching it collides with the other agent and fails the run.
    98	
    99	WHILE WORKING:
   100	  - If you discover you need to edit files outside your declared paths, run
   101	    `tick scope <TASK-ID> --agent <YOUR-ID> --paths "<expanded globs>"` BEFORE
   102	    editing. This warns peer agents off the new scope.
   103	  - If you get stuck or detect a poisoned task (failing tests after multiple
   104	    attempts), run `tick break <TASK-ID> --agent <YOUR-ID> --reason "..."` so
   105	    no other agent burns budget on it.
   106	
   107	WHEN DONE:
   108	  - Run `tick done <TASK-ID> --agent <YOUR-ID>` (after your final commit).
   109	  - To pass the task to another agent instead, run
   110	    `tick release <TASK-ID> --agent <YOUR-ID> --to <other-agent-id>`.
   111	
   112	After the session, `tick analyze` will be run against the event log + git
   113	history to measure: did you claim before editing? did your declared paths
   114	match your actual edits? did you use scope/done/break correctly? Behave
   115	accordingly.
   116	
   117	Note: `tick` verbs are local-only — they append an event file under
   118	`.tick/events/` and never touch the network. Commit your code changes with
   119	normal git; `tick` does not push for you.
   120	```
   121	
   122	## Multi-agent flow
   123	
   124	Seed the event log with non-overlapping tasks before starting agents:
   125	
   126	```bash
   127	tick log task.created TASK-A --agent dispatcher --priority 10 --paths "src/auth/**"
   128	tick log task.created TASK-B --agent dispatcher --priority 10 --paths "src/billing/**"
   129	tick log task.created TASK-C --agent dispatcher --priority 5  --paths "tests/**"
   130	# events are local — no push needed; peers read the same shared .tick/events/
   131	```
   132	
   133	Then start each agent (all pointed at the same `TICK_REPO_ROOT`) with the integration prompt loaded.
   134	
   135	## Constraints
   136	
   137	- **Shared event log.** All coordinating agents read and write one `.tick/events/` (the same `TICK_REPO_ROOT`). Cross-clone / cross-branch sync is Phase 2.
   138	- **Honest declaration required.** `tick` does not enforce that an agent's edits stay within declared paths. A pre-commit hook is one Phase 2 enforcement option.
   139	- **Lock-serialised claims.** Concurrent `tick claim` / `tick take` calls are serialised by an `O_EXCL` lock under `.tick/locks/` — exactly one wins, the other is told to retry. No network, no push.
   140	
   141	## Tests
   142	
   143	```bash
   144	./validate.sh        # run all acceptance tests
   145	./test/handoff.sh    # run one
   146	```
   147	
   148	Each test runs in an isolated `$TMPDIR` working tree and exercises the protocol end-to-end against a shared local `.tick/events/`. (A bare remote is still scaffolded for the few assertions that touch git-level operations like author identity, but coordination no longer depends on push/pull.) Cleanup is automatic.
   149	
   150	## Auditing a real-agent run
   151	
   152	After any multi-agent session — Day 5 hand-test, future Phase 2 runs, anything — run:
   153	
   154	```bash
   155	./bin/tick analyze                                          # human-readable to stdout
   156	./bin/tick analyze --format json                            # for downstream tooling
   157	./bin/tick analyze --write REAL-AGENT-OBSERVATIONS.md       # append/replace the auto-analyzed section in-place
   158	```
   159	
   160	The analyzer reads `.tick/events/` only — the git transport was removed in Run 2, so there are no work commits to attribute. It reports:
   161	
   162	- **Run window** — earliest to latest event, plus a total event count broken down by type.
   163	- **Concurrent-claim time (primary metric)** — how much of the run window had two agents holding active claims at once, as both a duration and a percentage.
   164	- **Parked-claim suspects** — claims that ran too long without a `tick ping` heartbeat; any suspect disqualifies the run.
   165	- **Per-agent counts** — claims, dones (`tick done`), heartbeats (`tick ping`), releases (and how many were handoffs), breaks, scope changes, comments.
   166	
   167	**Not automated:** per-commit path drift and file-collision attribution. Those depended on the git-author-per-agent signal the old transport provided; in the current PoC the coordinator inspects `git diff` by hand. There is no `--since` flag.
   168	
   169	Subjective questions in REAL-AGENT-OBSERVATIONS.md (what the prompt needed, what felt like friction) still require each agent to self-report.

exec
/bin/zsh -lc "nl -ba validate.sh | sed -n '1,220p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# Aggregate runner for all tick acceptance tests.
     3	# Exit 0 = all pass; Exit 1 = at least one failed.
     4	set -u
     5	
     6	HERE="$(cd "$(dirname "$0")" && pwd)"
     7	TESTS=(
     8	  "projection-idempotent.sh"
     9	  "concurrent-claim.sh"
    10	  "path-overlap.sh"
    11	  "scope-change.sh"
    12	  "handoff.sh"
    13	  "handoff-exclusive.sh"
    14	  "circuit-break.sh"
    15	  "auto-sync.sh"
    16	  "analyze.sh"
    17	  "claim-cap.sh"
    18	  "reap.sh"
    19	  "heartbeat.sh"
    20	  "cost.sh"
    21	  "take.sh"
    22	  "watchdog-liveness.sh"
    23	  "runner-loop.sh"
    24	  "poll-driver.sh"
    25	  "poll-relay.sh"
    26	  "watchdog-relay.sh"
    27	  "codex-turn.sh"
    28	  "gemini-turn.sh"
    29	  "consult.sh"
    30	  "skill-extract.sh"
    31	)
    32	
    33	PASSED=()
    34	FAILED=()
    35	
    36	for t in "${TESTS[@]}"; do
    37	  echo
    38	  echo "==============================="
    39	  echo "Running $t"
    40	  echo "==============================="
    41	  if bash "$HERE/test/$t"; then
    42	    PASSED+=("$t")
    43	  else
    44	    FAILED+=("$t")
    45	  fi
    46	done
    47	
    48	echo
    49	echo "==============================="
    50	echo "Summary"
    51	echo "==============================="
    52	echo "passed: ${#PASSED[@]} / ${#TESTS[@]}"
    53	for t in "${PASSED[@]}"; do echo "  + $t"; done
    54	if [ "${#FAILED[@]}" -gt 0 ]; then
    55	  echo "failed:"
    56	  for t in "${FAILED[@]}"; do echo "  - $t"; done
    57	  exit 1
    58	fi
    59	exit 0

exec
/bin/zsh -lc 'rg -n "consult" RECAP.md REAL-AGENT-OBSERVATIONS.md docs relay-system decisions' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626
 succeeded in 0ms:
relay-system/2026-06-17/consult-dogfood.gemini.md:4:The `consult` skill is a conceptually strong and architecturally sound addition to the `tick` ecosystem. It correctly identifies the value of **divergent thinking** over simple consensus. However, there are significant technical risks in the "read-only" guarantee and history management that should be addressed before it is considered "commercial grade."
relay-system/2026-06-17/consult-dogfood.gemini.md:7:The distinction between `consult` (parallel, 1-shot, advisory) and `relay` (iterative, multi-turn, stateful) is clear and well-articulated. The comparison table in `SKILL.md:14-23` is excellent and provides a clear heuristic for a paying user. The primitive fills a specific gap: "I don't want an agent to fix this yet; I want to know if my plan is flawed."
relay-system/2026-06-17/consult-dogfood.gemini.md:14:*   **[Blocker] Broken Revert Guard (`consult.sh:173-189`):** The guard uses `comm -13` on `git status --porcelain` to identify files to revert. This **fails to detect edits to files that were already modified (WIP)** before the consult started. If an advisor edits an existing dirty file, the status line (e.g., ` M src/main.js`) remains identical, `comm` skips it, and the advisor's "advisory" edit pollutes the user's workspace permanently.
relay-system/2026-06-17/consult-dogfood.gemini.md:15:*   **[Should] Unsafe Gemini Execution (`consult.sh:110`):** Running Gemini with `--yolo` and no sandbox is dangerous. While the preamble asks for read-only behavior, `--yolo` gives the model permission to execute any tool (including `write_file`). Given the broken revert guard above, a "hallucinating" or malicious advisor could damage the repo. Codex is better protected with `-s read-only` (line 104).
relay-system/2026-06-17/consult-dogfood.gemini.md:16:*   **[Should] History Clobbering:** The script defaults to `LABEL="consult"` (line 46) and writes to a directory based on the date. Running the skill twice in one day without an explicit `--label` will **overwrite the first consult's transcripts**. A commercial product should use unique session IDs or timestamps (e.g., `consult-$(date +%H%M%S)`).
relay-system/2026-06-17/consult-dogfood.gemini.md:17:*   **[Nit] Cost Capture vs. Readability (`consult.sh:150`):** Enabling `CONSULT_GEMINI_JSON=1` for cost tracking changes the transcript extension to `.json`. This breaks the "Read both transcripts" workflow for the coordinator (Claude) if it expects consistent Markdown formatting across advisors. Transcripts should ideally be `.md`, with metadata/costing captured separately.
relay-system/2026-06-17/consult-dogfood.gemini.md:26:- `SKILL.md:14-23`: Comparison table between consult and relay.
relay-system/2026-06-17/consult-dogfood.gemini.md:27:- `consult.sh:110`: Use of `--yolo` for Gemini.
relay-system/2026-06-17/consult-dogfood.gemini.md:28:- `consult.sh:189`: Faulty `comm -13` logic for tree reverts.
relay-system/2026-06-17/consult-dogfood.gemini.md:29:- `consult.sh:46`: Default label risk.
relay-system/2026-06-17/consult-dogfood-question.md:3:- `skill/consult/SKILL.md` — the skill definition (what it does, when to use it, the workflow).
relay-system/2026-06-17/consult-dogfood-question.md:4:- `relay-automation/consult.sh` — its implementation (parallel read-only fan-out to Codex + Gemini,
relay-system/2026-06-17/consult-dogfood-question.md:8:**commercial paid product**. The `consult` skill is meant to be a *one-shot parallel second opinion*
relay-system/2026-06-17/consult-dogfood-question.md:14:1. **Concept soundness:** Is "consult" a genuinely useful primitive, and is it clearly distinct from
relay-system/2026-06-17/consult-dogfood-question.md:18:3. **Implementation:** Is `consult.sh` correct and safe? Look hard at: the parallel fan-out + exit-code
relay-system/2026-06-17/consult-dogfood.codex.md:14:You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: do NOT edit, create, move, or commit any file — output your analysis as text and nothing else.
relay-system/2026-06-17/consult-dogfood.codex.md:19:- `skill/consult/SKILL.md` — the skill definition (what it does, when to use it, the workflow).
relay-system/2026-06-17/consult-dogfood.codex.md:20:- `relay-automation/consult.sh` — its implementation (parallel read-only fan-out to Codex + Gemini,
relay-system/2026-06-17/consult-dogfood.codex.md:24:**commercial paid product**. The `consult` skill is meant to be a *one-shot parallel second opinion*
relay-system/2026-06-17/consult-dogfood.codex.md:30:1. **Concept soundness:** Is "consult" a genuinely useful primitive, and is it clearly distinct from
relay-system/2026-06-17/consult-dogfood.codex.md:34:3. **Implementation:** Is `consult.sh` correct and safe? Look hard at: the parallel fan-out + exit-code
relay-system/2026-06-17/consult-dogfood.codex.md:44:Reviewing `skill/consult/SKILL.md` and `relay-automation/consult.sh` first, then I’ll cross-check the existing `relay` skill so the distinction claim is grounded in the repo rather than inferred.
relay-system/2026-06-17/consult-dogfood.codex.md:46:/bin/zsh -lc 'nl -ba skill/consult/SKILL.md' in /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm
relay-system/2026-06-17/consult-dogfood.codex.md:48:/bin/zsh -lc 'nl -ba relay-automation/consult.sh' in /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm
relay-system/2026-06-17/consult-dogfood.codex.md:53:     4	# consult.sh — one-shot cross-model CONSULT (a panel of advisors), repo-local.
relay-system/2026-06-17/consult-dogfood.codex.md:57:     8	# This is NOT a relay: a relay is an iterative 1:1 Producer↔Reviewer loop; a consult is a parallel
relay-system/2026-06-17/consult-dogfood.codex.md:65:    16	#   consult.sh --prompt-file Q.md  [--out DIR] [--models codex,gemini] [--label SLUG]
relay-system/2026-06-17/consult-dogfood.codex.md:66:    17	#   consult.sh --prompt "question" [--out DIR] [--models codex,gemini] [--label SLUG]
relay-system/2026-06-17/consult-dogfood.codex.md:69:    20	#   --prompt-file F   File whose contents are the consult question (it may reference repo paths).
relay-system/2026-06-17/consult-dogfood.codex.md:73:    24	#   --label SLUG      Filename stem for transcripts (default: consult).
relay-system/2026-06-17/consult-dogfood.codex.md:90:    41	die() { printf 'consult: %s\n' "$*" >&2; exit 2; }
relay-system/2026-06-17/consult-dogfood.codex.md:91:    42	warn() { printf 'consult: %s\n' "$*" >&2; }
relay-system/2026-06-17/consult-dogfood.codex.md:93:    44	PROMPT_FILE=""; PROMPT_TEXT=""; OUT=""; MODELS="codex,gemini"; LABEL="consult"
relay-system/2026-06-17/consult-dogfood.codex.md:119:    70	PREAMBLE="You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering \
relay-system/2026-06-17/consult-dogfood.codex.md:171:   122	((${#PIDS[@]} > 0)) || die "no valid models to consult (got: $MODELS)"
relay-system/2026-06-17/consult-dogfood.codex.md:185:   136	# --- best-effort cost capture (gemini json mode only; never fails the consult) -------------------
relay-system/2026-06-17/consult-dogfood.codex.md:198:   149	  warn "an advisor committed during the consult (forbidden) — reset to ${before_head:0:8}"
relay-system/2026-06-17/consult-dogfood.codex.md:218:   169	printf 'consult: %d answered, %d failed%s\n' "$answered" "$failed" "$summary"
relay-system/2026-06-17/consult-dogfood.codex.md:224:     2	name: consult
relay-system/2026-06-17/consult-dogfood.codex.md:225:     3	description: One-shot cross-model CONSULT — fan the same question out to Codex and Gemini in parallel (read-only, advisory), then reconcile their answers into one. Use when the user wants a "second opinion", to "ask Codex and Gemini", a "panel" or "cross-model" check, or an independent gut-check on a decision/design/doc before committing — and does NOT need an iterative build/review loop. NOT a relay: a relay is an iterative 1:1 Producer↔Reviewer loop that converges an artifact; a consult is a parallel 1-shot 1:N second opinion, reconciled once. Repo-local — depends on the codex + gemini CLIs and the relay-automation shims, so it is not portable.
relay-system/2026-06-17/consult-dogfood.codex.md:232:    10	A consult asks Codex and Gemini the *same* question at the same time, read-only, and then a
relay-system/2026-06-17/consult-dogfood.codex.md:239:    17	| | **consult** (this skill) | **relay** |
relay-system/2026-06-17/consult-dogfood.codex.md:247:    25	If after a consult you decide the work needs iteration, *start a relay* — the consult is the cheap
relay-system/2026-06-17/consult-dogfood.codex.md:261:    39	`relay-automation/consult.sh` fans the question out to both advisors **in parallel**, captures each
relay-system/2026-06-17/consult-dogfood.codex.md:264:    42	sneaks in — a consult never changes your code. The script does the fan-out; **the synthesis is yours.**
relay-system/2026-06-17/consult-dogfood.codex.md:267:    45	consult.sh --prompt-file Q.md            # question is the file's contents (may reference repo paths)
relay-system/2026-06-17/consult-dogfood.codex.md:268:    46	consult.sh --prompt "Is X sound?"        # inline question
relay-system/2026-06-17/consult-dogfood.codex.md:271:    49	  [--label SLUG]                         # transcript filename stem (default "consult")
relay-system/2026-06-17/consult-dogfood.codex.md:283:    61	2. **Fan out:** run `consult.sh` with the prompt + a `--label`. Both models run at once.
relay-system/2026-06-17/consult-dogfood.codex.md:293:    71	## The one rule that makes a consult worth running
relay-system/2026-06-17/consult-dogfood.codex.md:312:    90	- **Repo-local, not portable.** Unlike `relay` (model-agnostic, file-only), consult hard-depends on
relay-system/2026-06-17/consult-dogfood.codex.md:322:/bin/zsh -lc "rg --files . | rg '("'^|/)(SKILL'"\\.md|consult\\.sh|relay\\.sh|README\\.md)"'$'"'" in /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm
relay-system/2026-06-17/consult-dogfood.codex.md:325:./relay-automation/consult.sh
relay-system/2026-06-17/consult-dogfood.codex.md:327:./skill/consult/SKILL.md
relay-system/2026-06-17/consult-dogfood.codex.md:493:/bin/zsh -lc "rg -n \"consult|relay\" README.md relay-automation/README.md skill -g '"'!skill/consult/SKILL.md'"'" in /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm
relay-system/2026-06-17/consult-dogfood.codex.md:699:/bin/zsh -lc "rg -n \"consult\\.sh|CONSULT_|consult\" relay-automation test skill README.md" in /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm
relay-system/2026-06-17/consult-dogfood.codex.md:701:skill/consult/SKILL.md:2:name: consult
relay-system/2026-06-17/consult-dogfood.codex.md:702:skill/consult/SKILL.md:3:description: One-shot cross-model CONSULT — fan the same question out to Codex and Gemini in parallel (read-only, advisory), then reconcile their answers into one. Use when the user wants a "second opinion", to "ask Codex and Gemini", a "panel" or "cross-model" check, or an independent gut-check on a decision/design/doc before committing — and does NOT need an iterative build/review loop. NOT a relay: a relay is an iterative 1:1 Producer↔Reviewer loop that converges an artifact; a consult is a parallel 1-shot 1:N second opinion, reconciled once. Repo-local — depends on the codex + gemini CLIs and the relay-automation shims, so it is not portable.
relay-system/2026-06-17/consult-dogfood.codex.md:703:skill/consult/SKILL.md:10:A consult asks Codex and Gemini the *same* question at the same time, read-only, and then a
relay-system/2026-06-17/consult-dogfood.codex.md:704:skill/consult/SKILL.md:17:| | **consult** (this skill) | **relay** |
relay-system/2026-06-17/consult-dogfood.codex.md:705:skill/consult/SKILL.md:25:If after a consult you decide the work needs iteration, *start a relay* — the consult is the cheap
relay-system/2026-06-17/consult-dogfood.codex.md:706:skill/consult/SKILL.md:39:`relay-automation/consult.sh` fans the question out to both advisors **in parallel**, captures each
relay-system/2026-06-17/consult-dogfood.codex.md:707:skill/consult/SKILL.md:42:sneaks in — a consult never changes your code. The script does the fan-out; **the synthesis is yours.**
relay-system/2026-06-17/consult-dogfood.codex.md:708:skill/consult/SKILL.md:45:consult.sh --prompt-file Q.md            # question is the file's contents (may reference repo paths)
relay-system/2026-06-17/consult-dogfood.codex.md:709:skill/consult/SKILL.md:46:consult.sh --prompt "Is X sound?"        # inline question
relay-system/2026-06-17/consult-dogfood.codex.md:710:skill/consult/SKILL.md:49:  [--label SLUG]                         # transcript filename stem (default "consult")
relay-system/2026-06-17/consult-dogfood.codex.md:711:skill/consult/SKILL.md:61:2. **Fan out:** run `consult.sh` with the prompt + a `--label`. Both models run at once.
relay-system/2026-06-17/consult-dogfood.codex.md:712:skill/consult/SKILL.md:71:## The one rule that makes a consult worth running
relay-system/2026-06-17/consult-dogfood.codex.md:713:skill/consult/SKILL.md:87:- **Cost capture is opt-in.** Default Gemini output is human-readable text. Set `CONSULT_GEMINI_JSON=1`
relay-system/2026-06-17/consult-dogfood.codex.md:714:skill/consult/SKILL.md:90:- **Repo-local, not portable.** Unlike `relay` (model-agnostic, file-only), consult hard-depends on
relay-system/2026-06-17/consult-dogfood.codex.md:715:relay-automation/consult.sh:4:# consult.sh — one-shot cross-model CONSULT (a panel of advisors), repo-local.
relay-system/2026-06-17/consult-dogfood.codex.md:716:relay-automation/consult.sh:8:# This is NOT a relay: a relay is an iterative 1:1 Producer↔Reviewer loop; a consult is a parallel
relay-system/2026-06-17/consult-dogfood.codex.md:717:relay-automation/consult.sh:16:#   consult.sh --prompt-file Q.md  [--out DIR] [--models codex,gemini] [--label SLUG]
relay-system/2026-06-17/consult-dogfood.codex.md:718:relay-automation/consult.sh:17:#   consult.sh --prompt "question" [--out DIR] [--models codex,gemini] [--label SLUG]
relay-system/2026-06-17/consult-dogfood.codex.md:719:relay-automation/consult.sh:20:#   --prompt-file F   File whose contents are the consult question (it may reference repo paths).
relay-system/2026-06-17/consult-dogfood.codex.md:720:relay-automation/consult.sh:24:#   --label SLUG      Filename stem for transcripts (default: consult).
relay-system/2026-06-17/consult-dogfood.codex.md:721:relay-automation/consult.sh:30:#   CONSULT_GEMINI_JSON=1         capture gemini as -o json (enables best-effort cost.tokens) instead
relay-system/2026-06-17/consult-dogfood.codex.md:722:relay-automation/consult.sh:32:#   CONSULT_ROOT                  git root to guard (default: this repo)
relay-system/2026-06-17/consult-dogfood.codex.md:723:relay-automation/consult.sh:38:ROOT="${CONSULT_ROOT:-"$(cd "$HERE/.." && pwd)"}"
relay-system/2026-06-17/consult-dogfood.codex.md:724:relay-automation/consult.sh:41:die() { printf 'consult: %s\n' "$*" >&2; exit 2; }
relay-system/2026-06-17/consult-dogfood.codex.md:725:relay-automation/consult.sh:42:warn() { printf 'consult: %s\n' "$*" >&2; }
relay-system/2026-06-17/consult-dogfood.codex.md:726:relay-automation/consult.sh:44:PROMPT_FILE=""; PROMPT_TEXT=""; OUT=""; MODELS="codex,gemini"; LABEL="consult"
relay-system/2026-06-17/consult-dogfood.codex.md:727:relay-automation/consult.sh:70:PREAMBLE="You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering \
relay-system/2026-06-17/consult-dogfood.codex.md:728:relay-automation/consult.sh:93:  if [[ "${CONSULT_GEMINI_JSON:-0}" == "1" ]]; then
relay-system/2026-06-17/consult-dogfood.codex.md:729:relay-automation/consult.sh:114:      ext="md"; [[ "${CONSULT_GEMINI_JSON:-0}" == "1" ]] && ext="json"
relay-system/2026-06-17/consult-dogfood.codex.md:730:relay-automation/consult.sh:122:((${#PIDS[@]} > 0)) || die "no valid models to consult (got: $MODELS)"
relay-system/2026-06-17/consult-dogfood.codex.md:731:relay-automation/consult.sh:136:# --- best-effort cost capture (gemini json mode only; never fails the consult) -------------------
relay-system/2026-06-17/consult-dogfood.codex.md:732:relay-automation/consult.sh:137:if [[ "${CONSULT_GEMINI_JSON:-0}" == "1" ]]; then
relay-system/2026-06-17/consult-dogfood.codex.md:733:relay-automation/consult.sh:149:  warn "an advisor committed during the consult (forbidden) — reset to ${before_head:0:8}"
relay-system/2026-06-17/consult-dogfood.codex.md:734:relay-automation/consult.sh:169:printf 'consult: %d answered, %d failed%s\n' "$answered" "$failed" "$summary"
relay-system/2026-06-17/consult-dogfood.codex.md:737:/bin/zsh -lc 'rg -n "rename|R |status --porcelain|checkout --|reset --hard|rm -rf|CONSULT_ROOT|TICK_BIN" relay-automation/consult.sh relay-automation/*.sh test/*.sh' in /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm
relay-system/2026-06-17/consult-dogfood.codex.md:739:relay-automation/consult.sh:22:#   --out DIR         Where to write transcripts (default: relay-system/<today>/).
relay-system/2026-06-17/consult-dogfood.codex.md:740:relay-automation/consult.sh:32:#   CONSULT_ROOT                  git root to guard (default: this repo)
relay-system/2026-06-17/consult-dogfood.codex.md:741:relay-automation/consult.sh:33:#   TICK_BIN                      tick binary for cost capture (default: <root>/bin/tick)
relay-system/2026-06-17/consult-dogfood.codex.md:742:relay-automation/consult.sh:38:ROOT="${CONSULT_ROOT:-"$(cd "$HERE/.." && pwd)"}"
relay-system/2026-06-17/consult-dogfood.codex.md:743:relay-automation/consult.sh:83:before_status="$(git -C "$ROOT" status --porcelain 2>/dev/null || true)"
relay-system/2026-06-17/consult-dogfood.codex.md:744:relay-automation/consult.sh:140:    "${TICK_BIN:-$ROOT/bin/tick}" cost "CONSULT-$LABEL" --agent gemini --from-gemini-json "$gj" --tool gemini \
relay-system/2026-06-17/consult-dogfood.codex.md:745:relay-automation/consult.sh:148:  git -C "$ROOT" reset --hard "$before_head" >/dev/null 2>&1 || true
relay-system/2026-06-17/consult-dogfood.codex.md:746:relay-automation/consult.sh:156:after_status="$(git -C "$ROOT" status --porcelain 2>/dev/null || true)"
relay-system/2026-06-17/consult-dogfood.codex.md:747:relay-automation/consult.sh:163:    git -C "$ROOT" checkout -- "$p" 2>/dev/null || rm -rf "${ROOT:?}/${p%/}" 2>/dev/null || true
relay-system/2026-06-17/consult-dogfood.codex.md:796:relay-automation/consult.sh:22:#   --out DIR         Where to write transcripts (default: relay-system/<today>/).
relay-system/2026-06-17/consult-dogfood.codex.md:797:relay-automation/consult.sh:32:#   CONSULT_ROOT                  git root to guard (default: this repo)
relay-system/2026-06-17/consult-dogfood.codex.md:798:relay-automation/consult.sh:33:#   TICK_BIN                      tick binary for cost capture (default: <root>/bin/tick)
relay-system/2026-06-17/consult-dogfood.codex.md:799:relay-automation/consult.sh:38:ROOT="${CONSULT_ROOT:-"$(cd "$HERE/.." && pwd)"}"
relay-system/2026-06-17/consult-dogfood.codex.md:800:relay-automation/consult.sh:83:before_status="$(git -C "$ROOT" status --porcelain 2>/dev/null || true)"
relay-system/2026-06-17/consult-dogfood.codex.md:801:relay-automation/consult.sh:140:    "${TICK_BIN:-$ROOT/bin/tick}" cost "CONSULT-$LABEL" --agent gemini --from-gemini-json "$gj" --tool gemini \
relay-system/2026-06-17/consult-dogfood.codex.md:802:relay-automation/consult.sh:148:  git -C "$ROOT" reset --hard "$before_head" >/dev/null 2>&1 || true
relay-system/2026-06-17/consult-dogfood.codex.md:803:relay-automation/consult.sh:156:after_status="$(git -C "$ROOT" status --porcelain 2>/dev/null || true)"
relay-system/2026-06-17/consult-dogfood.codex.md:804:relay-automation/consult.sh:163:    git -C "$ROOT" checkout -- "$p" 2>/dev/null || rm -rf "${ROOT:?}/${p%/}" 2>/dev/null || true
relay-system/2026-06-17/consult-dogfood.codex.md:809:There’s an immediate implementation smell: the repo already has a more careful rename-aware enforcement core for `relay`, while `consult.sh` uses a much simpler `git status --porcelain` diff-and-checkout path. I’m reading that core now to see exactly which edge cases `consult` is currently missing.
relay-system/2026-06-17/consult-dogfood.codex.md:934:The biggest risk is no longer conceptual; it’s the safety boundary. `consult.sh` claims “never changes your code,” but its rollback logic is materially weaker than the repo’s existing containment core and appears capable of both missing advisor edits and destroying operator WIP on the commit path.
relay-system/2026-06-17/consult-dogfood.codex.md:998:/bin/zsh -lc 'rg -n "consult" validate.sh test skill/consult relay-automation/README.md README.md' in /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm
relay-system/2026-06-17/consult-dogfood.codex.md:1000:skill/consult/SKILL.md:2:name: consult
relay-system/2026-06-17/consult-dogfood.codex.md:1001:skill/consult/SKILL.md:3:description: One-shot cross-model CONSULT — fan the same question out to Codex and Gemini in parallel (read-only, advisory), then reconcile their answers into one. Use when the user wants a "second opinion", to "ask Codex and Gemini", a "panel" or "cross-model" check, or an independent gut-check on a decision/design/doc before committing — and does NOT need an iterative build/review loop. NOT a relay: a relay is an iterative 1:1 Producer↔Reviewer loop that converges an artifact; a consult is a parallel 1-shot 1:N second opinion, reconciled once. Repo-local — depends on the codex + gemini CLIs and the relay-automation shims, so it is not portable.
relay-system/2026-06-17/consult-dogfood.codex.md:1002:skill/consult/SKILL.md:10:A consult asks Codex and Gemini the *same* question at the same time, read-only, and then a
relay-system/2026-06-17/consult-dogfood.codex.md:1003:skill/consult/SKILL.md:17:| | **consult** (this skill) | **relay** |
relay-system/2026-06-17/consult-dogfood.codex.md:1004:skill/consult/SKILL.md:25:If after a consult you decide the work needs iteration, *start a relay* — the consult is the cheap
relay-system/2026-06-17/consult-dogfood.codex.md:1005:skill/consult/SKILL.md:39:`relay-automation/consult.sh` fans the question out to both advisors **in parallel**, captures each
relay-system/2026-06-17/consult-dogfood.codex.md:1006:skill/consult/SKILL.md:42:sneaks in — a consult never changes your code. The script does the fan-out; **the synthesis is yours.**
relay-system/2026-06-17/consult-dogfood.codex.md:1007:skill/consult/SKILL.md:45:consult.sh --prompt-file Q.md            # question is the file's contents (may reference repo paths)
relay-system/2026-06-17/consult-dogfood.codex.md:1008:skill/consult/SKILL.md:46:consult.sh --prompt "Is X sound?"        # inline question
relay-system/2026-06-17/consult-dogfood.codex.md:1009:skill/consult/SKILL.md:49:  [--label SLUG]                         # transcript filename stem (default "consult")
relay-system/2026-06-17/consult-dogfood.codex.md:1010:skill/consult/SKILL.md:61:2. **Fan out:** run `consult.sh` with the prompt + a `--label`. Both models run at once.
relay-system/2026-06-17/consult-dogfood.codex.md:1011:skill/consult/SKILL.md:71:## The one rule that makes a consult worth running
relay-system/2026-06-17/consult-dogfood.codex.md:1012:skill/consult/SKILL.md:90:- **Repo-local, not portable.** Unlike `relay` (model-agnostic, file-only), consult hard-depends on
relay-system/2026-06-17/consult-dogfood.codex.md:1017:`consult` is a useful and clearly different primitive from `relay`, but this implementation is not safe enough to ship as a paid feature yet. The distinction is understandable for users because the skill says `consult` is a one-shot parallel second opinion while `relay` is an iterative artifact-building loop ([skill/consult/SKILL.md](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/skill/consult/SKILL.md:15>), [skill/relay-automation/SKILL.md](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/skill/relay-automation/SKILL.md:8>)); the single most important pre-ship fix is the safety model in `consult.sh`, which can both lose operator WIP and miss advisor edits ([relay-automation/consult.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/consult.sh:146>), [relay-automation/consult.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/consult.sh:156>)).
relay-system/2026-06-17/consult-dogfood.codex.md:1021:- [Blocker] The commit-bypass path can destroy pre-existing operator WIP. `consult.sh` snapshots `before_status`, but if an advisor moves `HEAD`, it does `git reset --hard "$before_head"` and never restores the prior dirty tree, so any tracked local edits are lost ([relay-automation/consult.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/consult.sh:82>), [relay-automation/consult.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/consult.sh:148>)). That directly contradicts the intended “revert only NEW advisor edits, preserve operator WIP” behavior.
relay-system/2026-06-17/consult-dogfood.codex.md:1023:- [Blocker] The post-hoc revert logic is not robust enough to support the “consult never changes your code” claim. It diffs plain `git status --porcelain` text and reverts `p="${line:3}"`; that mishandles rename/copy records and cannot detect advisor edits to files that were already dirty if the status code stays the same ([relay-automation/consult.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/consult.sh:159>), [relay-automation/consult.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/consult.sh:163>)). The repo’s own containment core already documents rename-aware `-z` handling and also calls out the same-status dirty-file gap explicitly, which `consult.sh` does not ([relay-automation/relay-turn-lib.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/relay-turn-lib.sh:82>), [relay-automation/relay-turn-lib.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/relay-turn-lib.sh:89>), [relay-automation/relay-turn-lib.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/relay-turn-lib.sh:96>)).
relay-system/2026-06-17/consult-dogfood.codex.md:1025:- [Should] `SKILL.md` overclaims the read-only guarantee for Gemini. Codex is launched with `-s read-only`, but Gemini is launched with `--yolo --skip-trust -p` and no actual sandbox/read-only flag, so for Gemini this is “prompted not to write, then best-effort reverted afterward,” not true read-only execution ([relay-automation/consult.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/consult.sh:87>), [relay-automation/consult.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/consult.sh:95>), [skill/consult/SKILL.md](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/skill/consult/SKILL.md:39>), [skill/consult/SKILL.md](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/skill/consult/SKILL.md:85>)).
relay-system/2026-06-17/consult-dogfood.codex.md:1027:- [Should] There is no validation coverage for `consult`. `validate.sh` runs the relay and turn-taker suites, including rename-hijack cases for the containment core, but no `consult` test exists in the gate ([validate.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/validate.sh:7>), [validate.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/validate.sh:27>), [validate.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/validate.sh:29>)). For a paid feature, the missing cases are exactly the ones most likely to regress silently: dirty-tree preservation, advisor commit attempts, rename/copy edits, and single-model degrade.
relay-system/2026-06-17/consult-dogfood.codex.md:1029:- [Pass] The product concept is sound and distinct from `relay`. The new skill’s table is crisp, and it matches the existing relay docs: `consult` is for one-shot decision support; `relay` is for iterative producer/reviewer convergence on an artifact ([skill/consult/SKILL.md](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/skill/consult/SKILL.md:17>), [skill/consult/SKILL.md](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/skill/consult/SKILL.md:25>), [relay-automation/README.md](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/README.md:83>)).
relay-system/2026-06-17/consult-dogfood.codex.md:1031:- [Pass] The spec is otherwise unusually honest and well-scoped: it says the synthesis remains with the coordinator, documents graceful degrade and exit codes, and clearly marks the feature repo-local/non-portable ([skill/consult/SKILL.md](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/skill/consult/SKILL.md:42>), [skill/consult/SKILL.md](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/skill/consult/SKILL.md:52>), [skill/consult/SKILL.md](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/skill/consult/SKILL.md:90>), [relay-automation/consult.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/consult.sh:169>)).
relay-system/2026-06-17/consult-dogfood.codex.md:1035:Needs rework: keep the concept and spec framing, but replace the in-place best-effort rollback with a provable no-mutation boundary that preserves ambient WIP, then add consult-specific safety tests before shipping.
relay-system/2026-06-17/consult-dogfood.codex.md:1040:`consult` is a useful and clearly different primitive from `relay`, but this implementation is not safe enough to ship as a paid feature yet. The distinction is understandable for users because the skill says `consult` is a one-shot parallel second opinion while `relay` is an iterative artifact-building loop ([skill/consult/SKILL.md](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/skill/consult/SKILL.md:15>), [skill/relay-automation/SKILL.md](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/skill/relay-automation/SKILL.md:8>)); the single most important pre-ship fix is the safety model in `consult.sh`, which can both lose operator WIP and miss advisor edits ([relay-automation/consult.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/consult.sh:146>), [relay-automation/consult.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/consult.sh:156>)).
relay-system/2026-06-17/consult-dogfood.codex.md:1044:- [Blocker] The commit-bypass path can destroy pre-existing operator WIP. `consult.sh` snapshots `before_status`, but if an advisor moves `HEAD`, it does `git reset --hard "$before_head"` and never restores the prior dirty tree, so any tracked local edits are lost ([relay-automation/consult.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/consult.sh:82>), [relay-automation/consult.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/consult.sh:148>)). That directly contradicts the intended “revert only NEW advisor edits, preserve operator WIP” behavior.
relay-system/2026-06-17/consult-dogfood.codex.md:1046:- [Blocker] The post-hoc revert logic is not robust enough to support the “consult never changes your code” claim. It diffs plain `git status --porcelain` text and reverts `p="${line:3}"`; that mishandles rename/copy records and cannot detect advisor edits to files that were already dirty if the status code stays the same ([relay-automation/consult.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/consult.sh:159>), [relay-automation/consult.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/consult.sh:163>)). The repo’s own containment core already documents rename-aware `-z` handling and also calls out the same-status dirty-file gap explicitly, which `consult.sh` does not ([relay-automation/relay-turn-lib.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/relay-turn-lib.sh:82>), [relay-automation/relay-turn-lib.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/relay-turn-lib.sh:89>), [relay-automation/relay-turn-lib.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/relay-turn-lib.sh:96>)).
relay-system/2026-06-17/consult-dogfood.codex.md:1048:- [Should] `SKILL.md` overclaims the read-only guarantee for Gemini. Codex is launched with `-s read-only`, but Gemini is launched with `--yolo --skip-trust -p` and no actual sandbox/read-only flag, so for Gemini this is “prompted not to write, then best-effort reverted afterward,” not true read-only execution ([relay-automation/consult.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/consult.sh:87>), [relay-automation/consult.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/consult.sh:95>), [skill/consult/SKILL.md](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/skill/consult/SKILL.md:39>), [skill/consult/SKILL.md](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/skill/consult/SKILL.md:85>)).
relay-system/2026-06-17/consult-dogfood.codex.md:1050:- [Should] There is no validation coverage for `consult`. `validate.sh` runs the relay and turn-taker suites, including rename-hijack cases for the containment core, but no `consult` test exists in the gate ([validate.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/validate.sh:7>), [validate.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/validate.sh:27>), [validate.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/validate.sh:29>)). For a paid feature, the missing cases are exactly the ones most likely to regress silently: dirty-tree preservation, advisor commit attempts, rename/copy edits, and single-model degrade.
relay-system/2026-06-17/consult-dogfood.codex.md:1052:- [Pass] The product concept is sound and distinct from `relay`. The new skill’s table is crisp, and it matches the existing relay docs: `consult` is for one-shot decision support; `relay` is for iterative producer/reviewer convergence on an artifact ([skill/consult/SKILL.md](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/skill/consult/SKILL.md:17>), [skill/consult/SKILL.md](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/skill/consult/SKILL.md:25>), [relay-automation/README.md](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/README.md:83>)).
relay-system/2026-06-17/consult-dogfood.codex.md:1054:- [Pass] The spec is otherwise unusually honest and well-scoped: it says the synthesis remains with the coordinator, documents graceful degrade and exit codes, and clearly marks the feature repo-local/non-portable ([skill/consult/SKILL.md](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/skill/consult/SKILL.md:42>), [skill/consult/SKILL.md](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/skill/consult/SKILL.md:52>), [skill/consult/SKILL.md](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/skill/consult/SKILL.md:90>), [relay-automation/consult.sh](</Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/consult.sh:169>)).
relay-system/2026-06-17/consult-dogfood.codex.md:1058:Needs rework: keep the concept and spec framing, but replace the in-place best-effort rollback with a provable no-mutation boundary that preserves ambient WIP, then add consult-specific safety tests before shipping.

exec
/bin/zsh -lc 'git status --short' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626
 succeeded in 2963ms:
2026-06-17 13:52:53.770 xcodebuild[27008:102151339]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-06-17 13:52:54.211 xcodebuild[27008:102151338] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-9SeOa3AR' (errno=Operation not permitted)
2026-06-17 13:52:54.962 xcodebuild[27012:102151385]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-06-17 13:52:55.189 xcodebuild[27012:102151384] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
?? relay-automation/consult.sh
?? relay-system/2026-06-17/consult-dogfood-question.md
?? relay-system/2026-06-17/consult-dogfood.codex.md
?? relay-system/2026-06-17/consult-dogfood.gemini.md
?? skill/consult/
?? test/consult.sh

codex
The current safety story around source files is stronger than the old revert-based design, but there’s another boundary question now: whether “advisory only” still holds once optional cost logging writes into `.tick/events/`. I’m checking that before I grade commercial readiness.
exec
/bin/zsh -lc "nl -ba src/cost.js | sed -n '1,240p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626
 succeeded in 0ms:
     1	'use strict';
     2	
     3	// cost.js — pure, deterministic extractors for the Phase-1 cost signals
     4	// (COST-OBSERVABILITY-PLAN). No I/O, no clock, no network — just parse a CLI's
     5	// structured output into {tokens_in, tokens_out, tokens_total}. Pure so it's
     6	// trivially testable and the analyzer can trust it the same way it trusts the
     7	// event-log math.
     8	
     9	// Parse the token stats from `gemini -o json` output (validated against gemini-cli 0.46.0).
    10	// Shape: { stats: { models: { "<model>": { tokens: { input, prompt, candidates, total, ... } } } } }
    11	// Sums across ALL models used in the turn (a single turn may route across a flash + a main model).
    12	//
    13	//   tokens_in    = Σ tokens.input         (prompt/context fed in)
    14	//   tokens_total = Σ tokens.total         (input + candidates + thoughts, per the CLI's own sum)
    15	//   tokens_out   = tokens_total - tokens_in   (generated: candidates + reasoning "thoughts")
    16	//
    17	// Accepts a JSON string or an already-parsed object. Returns null when the input has no parseable
    18	// model-token stats (e.g. a non-json transcript or a stub) — the caller treats null as "not
    19	// captured" and emits the loud-partial signal rather than a fake zero.
    20	function parseGeminiStats(input) {
    21	  let obj = input;
    22	  if (typeof input === 'string') {
    23	    // gemini -o json may prefix the JSON with warning/status lines (e.g. color warnings, YOLO notices).
    24	    // Locate the first '{' and parse from there so those preamble lines don't break the parse.
    25	    const start = input.indexOf('{');
    26	    const jsonStr = start >= 0 ? input.slice(start) : input;
    27	    try { obj = JSON.parse(jsonStr); } catch { return null; }
    28	  }
    29	  const models = obj && obj.stats && obj.stats.models;
    30	  if (!models || typeof models !== 'object') return null;
    31	
    32	  let tokensIn = 0;
    33	  let tokensTotal = 0;
    34	  let sawTokens = false;
    35	  for (const name of Object.keys(models)) {
    36	    const t = models[name] && models[name].tokens;
    37	    if (!t || typeof t !== 'object') continue;
    38	    const input_ = Number(t.input) || 0;
    39	    const total = Number(t.total) || 0;
    40	    tokensIn += input_;
    41	    tokensTotal += total;
    42	    sawTokens = true;
    43	  }
    44	  if (!sawTokens) return null;
    45	
    46	  return {
    47	    tokens_in: tokensIn,
    48	    tokens_total: tokensTotal,
    49	    tokens_out: Math.max(0, tokensTotal - tokensIn),
    50	  };
    51	}
    52	
    53	module.exports = { parseGeminiStats };

exec
/bin/zsh -lc "rg -n \"cost \" src README.md skill relay-automation test -g '"'!relay-system/**'"'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626
 succeeded in 0ms:
relay-automation/consult.sh:36:#   TICK_BIN                   tick binary for cost capture (default: <root>/bin/tick)
relay-automation/consult.sh:150:# --- best-effort cost capture (gemini json mode only; never fails the consult) --------------------
relay-automation/consult.sh:154:    "${TICK_BIN:-$ROOT/bin/tick}" cost "CONSULT-$LABEL" --agent gemini --from-gemini-json "$gj" --tool gemini \
relay-automation/PHASE-2-PLAN.md:123:4. **Per-turn cost + rate-limit budgeting** — every automated turn is a billed API call; add a spend cap / backoff.
src/cost.js:3:// cost.js — pure, deterministic extractors for the Phase-1 cost signals
src/events.js:81:  // Cost fields — only stamped when present, so non-cost events stay byte-identical to before.
relay-automation/gemini-turn.sh:70:# Best-effort cost capture (Phase 1, COST-OBSERVABILITY-PLAN): parse the CLI's own token stats and
relay-automation/gemini-turn.sh:74:  "${TICK_BIN:-$ROOT/bin/tick}" cost "$t" --agent "$me" --from-gemini-json "$GEMINI_LOG" --tool gemini \
test/cost.sh:2:# cost.sh — Phase-1 cost signals (COST-OBSERVABILITY-PLAN): the `tick cost` verb writes
test/cost.sh:11:# read a single field out of the one matching cost event file (jsonl, one obj per file)
test/cost.sh:25:"$TICK" cost TASK-A --agent noel --human-minutes 12 >/dev/null
test/cost.sh:27:  && pass "cost --human-minutes writes human_minutes=12" || fail "human_minutes not 12 (got '$(field human-TASK-A human_minutes)')"
test/cost.sh:32:"$TICK" cost TASK-B --agent gemini --tokens-in 100 --tokens-out 40 --tool gemini >/dev/null
test/cost.sh:39:"$TICK" cost TASK-C --agent gemini --tokens-in 100 --tokens-out 40 --tokens-total 999 >/dev/null
test/cost.sh:50:"$TICK" cost TASK-D --agent gemini --from-gemini-json "$GJ" --tool gemini >/dev/null
test/cost.sh:72:"$TICK" cost TASK-E --agent gemini >/dev/null 2>&1; rc=$?
test/cost.sh:73:[ "$rc" -eq 2 ] && pass "cost with no signal -> usage error (exit 2)" || fail "expected exit 2, got $rc"
test/cost.sh:89:p2 cost REG-1 --agent gemini --tokens-in 5 --tokens-out 5 >/dev/null
test/cost.sh:90:p2 cost REG-1 --agent noel  --human-minutes 3 >/dev/null
test/cost.sh:93:  || fail "cost events leaked into coordination metrics"
test/cost.sh:97:# --- (8) PHASE 2: analyzer computes the cost section ----------------------
src/analyze.js:235:  // run window, parked-claims) byte-identical to pre-cost runs. (COST-OBSERVABILITY-PLAN, Phase 1 QA.)
src/analyze.js:283:  const cost = computeCost(allEvents, windows, doneTaskIds, parallelism.run_window_ms, process.env.TICK_RUN_TYPE);
src/analyze.js:337:    out.push('--- cost ---');

exec
/bin/zsh -lc "nl -ba test/cost.sh | sed -n '1,220p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# cost.sh — Phase-1 cost signals (COST-OBSERVABILITY-PLAN): the `tick cost` verb writes
     3	# deterministic cost.tokens / cost.human events, parseGeminiStats reads `gemini -o json`
     4	# token stats verbatim, and the coordination analyzer IGNORES cost.* events (no regression).
     5	source "$(dirname "$0")/_setup.sh" cost
     6	export TICK_REPO_ROOT="$A"
     7	tick_a init >/dev/null
     8	
     9	ROOT="$(cd "$(dirname "$0")/.." && pwd)"
    10	
    11	# read a single field out of the one matching cost event file (jsonl, one obj per file)
    12	field() { # <glob-substring> <key>
    13	  node -e '
    14	    const fs=require("fs"),path=require("path");
    15	    const dir=path.join(process.argv[1],".tick","events");
    16	    if(!fs.existsSync(dir)){process.stdout.write("");process.exit(0);}
    17	    const f=fs.readdirSync(dir).filter(x=>x.includes(process.argv[2])).sort().pop();
    18	    if(!f){process.stdout.write("");process.exit(0);}
    19	    const ev=JSON.parse(fs.readFileSync(path.join(dir,f),"utf8"));
    20	    process.stdout.write(String(ev[process.argv[3]] ?? ""));
    21	  ' "$A" "$1" "$2"
    22	}
    23	
    24	# --- (1) human-minutes -> cost.human event -------------------------------
    25	"$TICK" cost TASK-A --agent noel --human-minutes 12 >/dev/null
    26	[ "$(field human-TASK-A human_minutes)" = "12" ] \
    27	  && pass "cost --human-minutes writes human_minutes=12" || fail "human_minutes not 12 (got '$(field human-TASK-A human_minutes)')"
    28	[ "$(field human-TASK-A type)" = "cost.human" ] \
    29	  && pass "human event typed cost.human" || fail "wrong type"
    30	
    31	# --- (2) explicit tokens -> cost.tokens, total auto-summed ----------------
    32	"$TICK" cost TASK-B --agent gemini --tokens-in 100 --tokens-out 40 --tool gemini >/dev/null
    33	[ "$(field tokens-TASK-B tokens_in)" = "100" ]  && pass "tokens_in=100" || fail "tokens_in wrong"
    34	[ "$(field tokens-TASK-B tokens_out)" = "40" ]  && pass "tokens_out=40" || fail "tokens_out wrong"
    35	[ "$(field tokens-TASK-B tokens_total)" = "140" ] && pass "tokens_total auto-summed to 140" || fail "total not summed"
    36	[ "$(field tokens-TASK-B tool)" = "gemini" ]    && pass "tool=gemini recorded" || fail "tool not recorded"
    37	
    38	# --- (3) explicit --tokens-total overrides the sum -----------------------
    39	"$TICK" cost TASK-C --agent gemini --tokens-in 100 --tokens-out 40 --tokens-total 999 >/dev/null
    40	[ "$(field tokens-TASK-C tokens_total)" = "999" ] && pass "explicit --tokens-total honored" || fail "total override ignored"
    41	
    42	# --- (4) parse gemini -o json verbatim (the real CLI shape) --------------
    43	GJ="$WORK/gem.json"
    44	cat >"$GJ" <<'JSON'
    45	{"session_id":"x","response":"ok","stats":{"models":{
    46	  "flash":{"tokens":{"input":3761,"candidates":26,"total":4738,"thoughts":951}},
    47	  "main":{"tokens":{"input":11546,"candidates":1,"total":11547,"thoughts":0}}
    48	}}}
    49	JSON
    50	"$TICK" cost TASK-D --agent gemini --from-gemini-json "$GJ" --tool gemini >/dev/null
    51	# in = 3761+11546 = 15307 ; total = 4738+11547 = 16285 ; out = total-in = 978
    52	[ "$(field tokens-TASK-D tokens_in)" = "15307" ]    && pass "gemini-json tokens_in summed across models" || fail "in=$(field tokens-TASK-D tokens_in)"
    53	[ "$(field tokens-TASK-D tokens_total)" = "16285" ] && pass "gemini-json tokens_total summed" || fail "total wrong"
    54	[ "$(field tokens-TASK-D tokens_out)" = "978" ]     && pass "gemini-json tokens_out = total-in" || fail "out wrong"
    55	
    56	# --- (5) parseGeminiStats returns null on non-json / no stats ------------
    57	nullres="$(node -e 'const {parseGeminiStats}=require(process.argv[1]); console.log(parseGeminiStats("not json")===null && parseGeminiStats(JSON.stringify({a:1}))===null ? "OK":"BAD")' "$ROOT/src/cost.js")"
    58	[ "$nullres" = "OK" ] && pass "parseGeminiStats -> null on garbage/no-stats" || fail "parser should return null"
    59	
    60	# --- (5b) parseGeminiStats handles warning-prefix preamble (the real gemini-cli format) -------
    61	# gemini -o json emits color/YOLO warnings before the JSON object; the parser must skip them.
    62	PREAMBLE_JSON="$(cat <<'PEOF'
    63	Warning: 256-color support not detected.
    64	YOLO mode is enabled. All tool calls will be automatically approved.
    65	{"session_id":"x","response":"ok","stats":{"models":{"flash":{"tokens":{"input":100,"candidates":10,"total":200,"thoughts":90}}}}}
    66	PEOF
    67	)"
    68	preamble_res="$(node -e 'const {parseGeminiStats}=require(process.argv[1]); const r=parseGeminiStats(process.argv[2]); console.log(r && r.tokens_in===100 && r.tokens_total===200 ? "OK" : "BAD:"+JSON.stringify(r))' "$ROOT/src/cost.js" "$PREAMBLE_JSON")"
    69	[ "$preamble_res" = "OK" ] && pass "parseGeminiStats handles warning-prefix preamble" || fail "preamble parse failed: $preamble_res"
    70	
    71	# --- (6) bad input -> usage error, no event ------------------------------
    72	"$TICK" cost TASK-E --agent gemini >/dev/null 2>&1; rc=$?
    73	[ "$rc" -eq 2 ] && pass "cost with no signal -> usage error (exit 2)" || fail "expected exit 2, got $rc"
    74	
    75	# Phase 2 tests run on a FRESH events root so totals/coverage are isolated from tests 1-6.
    76	P2="$WORK/p2"; mkdir -p "$P2"
    77	p2() { TICK_REPO_ROOT="$P2" "$TICK" "$@"; }
    78	p2j() { TICK_REPO_ROOT="$P2" "$TICK" analyze --format json | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const r=JSON.parse(s);let v=r;for(const k of process.argv[1].split("."))v=v[k];process.stdout.write(typeof v==="object"?JSON.stringify(v):String(v))})' "$1"; }
    79	p2 init >/dev/null
    80	# Two done coordination tasks (REG-1 by alpha, REG-2 by beta).
    81	p2 log task.created REG-1 --agent dispatcher >/dev/null; p2 claim REG-1 --agent alpha --paths "x/**" >/dev/null; p2 done REG-1 --agent alpha >/dev/null
    82	p2 log task.created REG-2 --agent dispatcher >/dev/null; p2 claim REG-2 --agent beta  --paths "y/**" >/dev/null; p2 done REG-2 --agent beta  >/dev/null
    83	
    84	# --- (7) NO REGRESSION: cost.* events don't change the COORDINATION metrics ---
    85	# Phase 2 intentionally REPORTS cost, so the whole json changes; the invariant is narrower —
    86	# the coordination subset (everything except .cost) must be byte-identical.
    87	strip_cost() { node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const r=JSON.parse(s);delete r.cost;process.stdout.write(JSON.stringify(r))})'; }
    88	before="$(TICK_REPO_ROOT="$P2" "$TICK" analyze --format json | strip_cost)"
    89	p2 cost REG-1 --agent gemini --tokens-in 5 --tokens-out 5 >/dev/null
    90	p2 cost REG-1 --agent noel  --human-minutes 3 >/dev/null
    91	after="$(TICK_REPO_ROOT="$P2" "$TICK" analyze --format json | strip_cost)"
    92	[ "$before" = "$after" ] && pass "coordination metrics unchanged by cost.* events (no regression)" \
    93	  || fail "cost events leaked into coordination metrics"
    94	TICK_REPO_ROOT="$P2" "$TICK" analyze --format json | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const r=JSON.parse(s);const names=(r.agents||[]).map(a=>a.agent);process.exit(names.includes("gemini")||names.includes("noel")?1:0)})' \
    95	  && pass "cost-only agents absent from per-agent coordination table" || fail "cost-only agent leaked into agents[]"
    96	
    97	# --- (8) PHASE 2: analyzer computes the cost section ----------------------
    98	# REG-1 instrumented (5/5), REG-2 not -> 1 of 2 done-tasks instrumented => PARTIAL floor.
    99	[ "$(p2j cost.tokens.tokens_total)" = "10" ]     && pass "cost.tokens_total summed (10)" || fail "tokens_total=$(p2j cost.tokens.tokens_total)"
   100	[ "$(p2j cost.human_minutes_total)" = "3" ]      && pass "cost.human_minutes_total summed (3)" || fail "human total wrong"
   101	[ "$(p2j cost.tokens.partial)" = "true" ]        && pass "partial flag true (1/2 done-tasks instrumented)" || fail "partial should be true"
   102	[ "$(p2j cost.tokens.coverage)" = "1/2" ]        && pass "coverage reads 1/2 (done-tasks)" || fail "coverage=$(p2j cost.tokens.coverage)"
   103	[ "$(p2j cost.per_unit.tokens_per_done)" = "5" ] && pass "tokens_per_done = 10/2 = 5 (floor)" || fail "per-done=$(p2j cost.per_unit.tokens_per_done)"
   104	[ "$(p2j cost.run_type)" = "unspecified" ]       && pass "run_type defaults to unspecified" || fail "run_type=$(p2j cost.run_type)"
   105	TICK_REPO_ROOT="$P2" "$TICK" analyze --format md | grep -q "PARTIAL (floor only)" && pass "md renders the loud-partial floor marker" || fail "md missing partial marker"
   106	
   107	# --- (9) run_type honors TICK_RUN_TYPE; invalid -> unspecified -----------
   108	[ "$(TICK_RUN_TYPE=symmetric p2j cost.run_type)" = "symmetric" ] && pass "TICK_RUN_TYPE=symmetric honored" || fail "run_type env not honored"
   109	[ "$(TICK_RUN_TYPE=garbage   p2j cost.run_type)" = "unspecified" ] && pass "invalid TICK_RUN_TYPE -> unspecified (no auto-guess)" || fail "bad run_type not rejected"
   110	
   111	echo "  $TEST_NAME: $PASS pass, $FAIL fail"
   112	[ "$FAIL" -eq 0 ] || exit 1
   113	exit 0

codex
`consult` is a useful and clearly distinct primitive, and the current worktree-based implementation fixes the old “advisor edits can clobber my repo” class of bug, but I would not ship it as a paid `read-only` feature yet because Gemini is only repo-isolated, not actually sandboxed/read-only ([skill/consult/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/consult/SKILL.md:3), [relay-automation/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/relay-automation/consult.sh:105), [relay-automation/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/relay-automation/consult.sh:112)).

- [Blocker] The commercial claim/boundary is too loose around Gemini. The skill description repeatedly says `read-only, advisory`, but only Codex gets an explicit read-only sandbox; Gemini is launched with `--yolo --skip-trust` and no comparable containment in this wrapper. The throwaway worktree is a strong repo-protection boundary, but it is not the same thing as a read-only execution boundary for the host process ([skill/consult/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/consult/SKILL.md:3), [skill/consult/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/consult/SKILL.md:43), [relay-automation/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/relay-automation/consult.sh:104), [relay-automation/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/relay-automation/consult.sh:112)).

- [Should] “Graceful degrade” is true only for advisors that exit. The fan-out/collection logic is otherwise correct, but there is no timeout or watchdog around either child process, so one hung CLI stalls the entire consult instead of degrading to the other model’s answer ([relay-automation/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/relay-automation/consult.sh:121), [relay-automation/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/relay-automation/consult.sh:140), [skill/consult/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/consult/SKILL.md:64)).

- [Should] The spec slightly overclaims advisor visibility. It says the throwaway worktree shows advisors “exactly what you see,” but the overlay copies only untracked, non-ignored files; ignored local context is excluded silently ([skill/consult/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/consult/SKILL.md:44), [relay-automation/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/relay-automation/consult.sh:98), [relay-automation/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/relay-automation/consult.sh:102)).

- [Pass] The product concept is sound and distinct from `relay`. The new skill frames `consult` as one-shot parallel opinion gathering with a reconciled call, while the existing relay automation is explicitly a multi-round Producer/Reviewer convergence loop on an artifact; that distinction is clear enough for a paying user ([skill/consult/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/consult/SKILL.md:15), [skill/consult/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/consult/SKILL.md:25), [skill/relay-automation/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/relay-automation/SKILL.md:8)).

- [Pass] The no-write guard for the repo tree is materially good now. Building a throwaway worktree from `git stash create` plus an untracked-file overlay is a defensible design, and the acceptance test covers the important cases: operator WIP preserved, advisor writes don’t leak, partial failure degrades, non-git roots are refused ([relay-automation/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/relay-automation/consult.sh:89), [relay-automation/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/relay-automation/consult.sh:96), [test/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/test/consult.sh:47), [validate.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/validate.sh:29)).

- [Pass] `SKILL.md` is otherwise well-specified and unusually honest: it says the script only gathers raw opinions, makes reconciliation the coordinator’s job, documents exit codes, and explicitly marks the feature repo-local/non-portable ([skill/consult/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/consult/SKILL.md:39), [skill/consult/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/consult/SKILL.md:67), [skill/consult/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/consult/SKILL.md:102)).

Recommendation: `needs rework` — keep the concept, but before selling it, either give Gemini a real sandbox or narrow the promise from “read-only” to “real-repo isolated,” then add per-advisor timeouts.
tokens used
71,359
`consult` is a useful and clearly distinct primitive, and the current worktree-based implementation fixes the old “advisor edits can clobber my repo” class of bug, but I would not ship it as a paid `read-only` feature yet because Gemini is only repo-isolated, not actually sandboxed/read-only ([skill/consult/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/consult/SKILL.md:3), [relay-automation/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/relay-automation/consult.sh:105), [relay-automation/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/relay-automation/consult.sh:112)).

- [Blocker] The commercial claim/boundary is too loose around Gemini. The skill description repeatedly says `read-only, advisory`, but only Codex gets an explicit read-only sandbox; Gemini is launched with `--yolo --skip-trust` and no comparable containment in this wrapper. The throwaway worktree is a strong repo-protection boundary, but it is not the same thing as a read-only execution boundary for the host process ([skill/consult/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/consult/SKILL.md:3), [skill/consult/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/consult/SKILL.md:43), [relay-automation/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/relay-automation/consult.sh:104), [relay-automation/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/relay-automation/consult.sh:112)).

- [Should] “Graceful degrade” is true only for advisors that exit. The fan-out/collection logic is otherwise correct, but there is no timeout or watchdog around either child process, so one hung CLI stalls the entire consult instead of degrading to the other model’s answer ([relay-automation/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/relay-automation/consult.sh:121), [relay-automation/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/relay-automation/consult.sh:140), [skill/consult/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/consult/SKILL.md:64)).

- [Should] The spec slightly overclaims advisor visibility. It says the throwaway worktree shows advisors “exactly what you see,” but the overlay copies only untracked, non-ignored files; ignored local context is excluded silently ([skill/consult/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/consult/SKILL.md:44), [relay-automation/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/relay-automation/consult.sh:98), [relay-automation/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/relay-automation/consult.sh:102)).

- [Pass] The product concept is sound and distinct from `relay`. The new skill frames `consult` as one-shot parallel opinion gathering with a reconciled call, while the existing relay automation is explicitly a multi-round Producer/Reviewer convergence loop on an artifact; that distinction is clear enough for a paying user ([skill/consult/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/consult/SKILL.md:15), [skill/consult/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/consult/SKILL.md:25), [skill/relay-automation/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/relay-automation/SKILL.md:8)).

- [Pass] The no-write guard for the repo tree is materially good now. Building a throwaway worktree from `git stash create` plus an untracked-file overlay is a defensible design, and the acceptance test covers the important cases: operator WIP preserved, advisor writes don’t leak, partial failure degrades, non-git roots are refused ([relay-automation/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/relay-automation/consult.sh:89), [relay-automation/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/relay-automation/consult.sh:96), [test/consult.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/test/consult.sh:47), [validate.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/validate.sh:29)).

- [Pass] `SKILL.md` is otherwise well-specified and unusually honest: it says the script only gathers raw opinions, makes reconciliation the coordinator’s job, documents exit codes, and explicitly marks the feature repo-local/non-portable ([skill/consult/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/consult/SKILL.md:39), [skill/consult/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/consult/SKILL.md:67), [skill/consult/SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-23743-8626/skill/consult/SKILL.md:102)).

Recommendation: `needs rework` — keep the concept, but before selling it, either give Gemini a real sandbox or narrow the promise from “read-only” to “real-repo isolated,” then add per-advisor timeouts.
