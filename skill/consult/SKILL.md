---
name: consult
description: One-shot cross-model CONSULT — fan the same question out to Codex and Gemini in parallel (repo-isolated, advisory), then reconcile their answers into one. Use when the user wants a "second opinion", to "ask Codex and Gemini", a "panel" or "cross-model" check, or an independent gut-check on a decision/design/doc before committing — and does NOT need an iterative build/review loop. NOT a relay: a relay is an iterative 1:1 Producer↔Reviewer loop that converges an artifact; a consult is a parallel 1-shot 1:N second opinion, reconciled once. Repo-local — depends on the codex + gemini CLIs and the relay-automation shims, so it is not portable.
---

# Consult

**One question → N independent models in parallel → one reconciled answer.**

A consult asks Codex and Gemini the *same* question at the same time, isolated from your real tree, and then a
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

`relay-automation/consult.sh` (path is relative to **this repo's root**, not your cwd) fans the question
out to both advisors **in parallel** and writes each transcript to a per-run dir
`relay-system/<today>/<label>-<HHMMSS>/`. The synthesis is **yours** — the script only gathers the raw
opinions.

**Locating the script — resolve it cwd-independently; never assume your cwd is the repo root.** A bare
`consult.sh` or `relay-automation/consult.sh` only resolves when you happen to be sitting at the root,
so invoke it through its repo-root anchor instead:

```
SCRIPT="$(git rev-parse --show-toplevel)/relay-automation/consult.sh"
"$SCRIPT" --prompt "…" --label …
```

`git rev-parse --show-toplevel` works from any subdirectory of the repo. If you are not inside the
`xyz-3-agents-swarm` worktree at all, `cd` there first — consult is repo-local and its shims live only
here. (Do **not** go hunting the disk for `consult.sh`; the anchor above always finds it.)

**Provable no-mutation boundary (not best-effort).** Advisors run with their working directory set to a
**throwaway git worktree** checked out from your *current* state — tracked WIP (via `git stash create`)
plus untracked-non-ignored files copied in — so they see your working state (minus `.gitignore`d
files), including a brand-new file under
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
2. **Fan out:** run the script through its repo-root anchor —
   `"$(git rev-parse --show-toplevel)/relay-automation/consult.sh"` (see "Locating the script" above) —
   with the prompt + a `--label`. Both models run at once. Don't invoke a bare `consult.sh`; it only
   resolves at the repo root.
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
- **Repo-isolated, not process-sandboxed.** Advisors run in a throwaway worktree and cannot reach
  your real tree, so a consult never changes your code even if an advisor ignores the "advisory only"
  instruction. Be precise about the boundary: this protects your *repository*, not the *host process*.
  Codex additionally runs `-s read-only`; Gemini runs `--yolo` and is repo-isolated but not a
  sandboxed process (it can still reach the network / the host outside the worktree). For a hard
  process boundary, run consult inside your own sandbox. If a fix is needed, *you* (or a relay) apply
  it — the independent check stays independent.
- **The worktree shows tracked + untracked state, not ignored files.** `.gitignore`d local context is
  excluded from what advisors see; reference it inline in the question if it matters.
- **Cost capture is opt-in.** Default Gemini output is human-readable text. Set `CONSULT_GEMINI_JSON=1`
  to capture `-o json` instead, which enables best-effort `tick cost` token logging (Codex token
  parsing is still deferred — its usage format isn't probed yet).
- **Repo-local, not portable.** Unlike `relay` (model-agnostic, file-only), consult hard-depends on
  the `codex` + `gemini` CLIs being installed and authed and on the `relay-automation` shims.

## Gotcha: run consult OUTSIDE Claude Code's Bash sandbox

If you launch `consult.sh` from a Claude Code session, **disable the Bash sandbox for that call**
(`dangerouslyDisableSandbox: true`). The sandbox blocks the macOS keychain (so the **Codex** CLI
can't load root CA certs — `no native root CA certificates found` / `No keychain is available`) and
does not allowlist `chatgpt.com`, so Codex fails every time while **Gemini still answers** (it talks
to `googleapis.com`, which is allowlisted). The symptom is a one-sided `1 answered, 1 failed` degrade
with a keychain error in the Codex transcript — it is **not** a Codex auth problem and **not** a
"restart your computer" problem. Disabling the sandbox here is safe: consult's isolation comes from
its **throwaway worktree** (and Codex's own `-s read-only`), not from the Bash sandbox, so nothing is
weakened.

## What success looks like

The operator asks one question and gets back a single, honest, reconciled answer that **shows its
seams** — what the two models agreed on, where they split, and which way the coordinator called it and
why — in one step, with both raw transcripts on disk for audit.
