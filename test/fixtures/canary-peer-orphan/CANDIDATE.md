# Incident audit — a peer commit "vanished" after a relay turn (review candidate)

> This is the **blind** artifact handed to the Reviewer. It states the incident and the captured git
> state, and deliberately contains **no verdict**. The answer lives in `EXPECTED.md`, which the
> Reviewer must not see.

## Context

A file-based relay turn ran **in-ROOT** (attended / non-worktree-isolated mode — the agent operated
directly in the repo, not a throwaway worktree). The containment shim (`relay-automation/relay-turn-lib.sh`,
`rtl_enforce`) reported the turn **failed** (exit 6). Afterward, an operator noticed that a *second*
(peer) agent, which had committed concurrently, can no longer find its commit on the branch.

Below is the captured git state of the repo right after the turn (a representative run; SHAs vary
per run, the shape does not).

```text
### shim exit code: 6

### git log --oneline (current branch):
3e82ed1 seed relay

### git status --short:
(clean)

### git reflog:
3e82ed1 HEAD@{0}: reset: moving to 3e82ed136424a5196036317ae53bc3184c753057
b225306 HEAD@{1}: commit: PEER concurrent commit (different agent)
3e82ed1 HEAD@{2}: commit (initial): seed relay

### git for-each-ref (all refs):
refs/heads/main 3e82ed1
refs/relay-orphan/b225306 b225306

### shim stderr:
relay-turn: agent committed during its turn (forbidden) — reset to 3e82ed13 (prior HEAD saved to refs/relay-orphan/), failing
```

## Reviewer task

Audit this incident for a **systemic** coordination fault — a problem with the containment protocol,
not a one-off. Specifically:

1. Was any committed work **removed from the branch**? If so, whose, and is it recoverable — how?
2. Is the shim's reaction **correct** here, or is it a false positive? Read what the shim *believed*
   happened versus what the reflog shows actually happened.
3. Propose a **systemic** fix (a containment-mode or kernel change), not a one-off recovery step.

Ground your analysis in the captured state (reflog, refs, shim message) and the containment logic in
`relay-automation/relay-turn-lib.sh` — not in narrative plausibility.
