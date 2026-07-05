# Decision — opt-in tool-cache exemption in containment's off-lane loop (GH-107)

**Date:** 2026-07-04 · **Issue:** [#107](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/107) · **Zone:** kernel (`relay-automation/relay-turn-lib.sh`) · **Track:** Opus-serial (Marathon Plan C kernel lane)

## The call

`rtl_worktree_end`'s off-lane loop gains one additional exemption check, placed after `rtl_in_allow`
and before the `RTL_WT_OFFLANE=1` fallthrough: `rtl_is_containment_ignored "$path"`. It matches the
changed path against a small **built-in list of known tool-cache directories**
(`.codebase-memory`, `.aider*`, `node_modules/.cache`) union an operator-supplied
**`CONTAINMENT_IGNORE`** env var (comma-separated glob patterns, empty by default). A match means
"this is a builder tool's own side-effect write, not an off-lane edit" — the path is skipped by
detection, discarded with the throwaway worktree, and never copied back to ROOT.

## The bet / assumption

Untracked writes to well-known tool-cache directories are **never the payload of a runaway turn** —
they are side effects of the builder's own tooling (MCP indexers, Aider caches). Exempting them from
off-lane detection therefore discards no real signal, while un-exempting them (the status quo) has
already destroyed a complete, correct, 67/67-tested build in a live dogfood run (the #107 field
report; sibling mechanism to #54's fs-touching-test discards).

The risk we accept: a malicious/off-task model could theoretically stash content inside
`.codebase-memory/` knowing it's exempt. Mitigations: the dir is **never copied back to ROOT**
(exemption ≠ propagation — the worktree is destroyed with the cache inside it), tracked-file
detection is untouched, and the built-in list is deliberately tiny and root-anchored (a nested
`sub/.codebase-memory` is NOT exempt by default).

## Why not the alternatives

- **Honor `.gitignore` wholesale** (issue suggestion #1): only works after a target repo has
  pre-anticipated the specific tool's cache dir — which is exactly the failure mode reported. Rejected
  in the capture doc's non-goals.
- **Only revert tracked off-lane edits** (issue suggestion #3): a philosophical change to the
  containment model (untracked creations were deliberately brought into detection by the
  worktree-isolation design — see `decisions/2026-07-02-offlane-untracked-dir.md`). Explicitly
  deferred, not built.

## Expected signal & revisit trigger

- **Signal it worked:** no more discarded-but-green turns whose only off-lane path is a cache dir;
  `CONTAINMENT_IGNORE` shows up in target-repo lane configs instead of post-hoc `.gitignore` patches.
- **Revisit if:** any turn is found using an exempted directory to smuggle actual work product, or
  the built-in list starts growing past a handful of entries (that would signal the suggestion-#3
  tracked-only model deserves the real debate instead of list maintenance).

## Reversibility

**Easy.** Additive, default-off (built-ins only fire on exact cache-dir names). Reverting is deleting
`rtl_is_containment_ignored()` and its one call site; behavior returns byte-for-byte. Coverage:
`test/worktree-isolation.sh` cases 7–9 (built-in exempt, env exempt, default-off control) plus the
untouched off-lane baselines in cases 2/4.
