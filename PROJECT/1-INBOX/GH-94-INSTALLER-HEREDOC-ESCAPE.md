---
gh_issue: 94
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/94
title: "Installer: self-extracting heredoc mangles `!`→`\\!` when materialized programmatically; offer release tarball / npx"
status: Proposed (1-INBOX — not yet active)
created: 2026-07-05
updated: 2026-07-05
owner: noel
doc_type: enhancement
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Not changing the documented copy-paste install path — it works today and stays the default.
  - Not a full package-manager migration (no build pipeline, publishing workflow, or registry
    account setup) — scoped to removing the one failure class, not shipping a distribution system.
related:
  - skills/xyz/SKILL.md    # §4 "Install (self-extracting)" + §4b "Install — test suite" — the two
                            # embedded heredoc blocks this bug concerns
  - install.sh             # the materialized runtime installer itself (companion, not the bug site)
---

# GH-94 · Installer self-extracting heredoc mangles `!`→`\!` when materialized programmatically

**Severity: LOW** — the documented human copy-paste path is fine; this hardens a secondary,
increasingly common install path (an agent materializing the block, not a human pasting it).

**Why:** `skills/xyz/SKILL.md` embeds the `tick` runtime installer as two self-extracting heredoc
blocks (§4 runtime, §4b test suite — [SKILL.md:99](../../skills/xyz/SKILL.md#L99),
[SKILL.md:1345](../../skills/xyz/SKILL.md#L1345)), each using a quoted heredoc delimiter
(`<<'===XYZ_FILE==='`) that is itself correct, SIGPIPE-free Bash. The mangling isn't in that Bash —
it's upstream, in *how* an agent (rather than a human terminal paste) materializes the block: a
programmatic write path can apply its own shell/history-expansion escaping to `!` before the content
ever reaches the heredoc, corrupting every `!`/`!==` in the extracted runtime and test files. Found
while materializing the installer programmatically this session (per the original issue).

**Open question (verify before choosing a fix):** does this still reproduce today, or did an
unrelated later change (e.g. the full-mirror vendor rewrite, `5972ef4`) incidentally alter the
materialization path enough to close it? That commit touched `relay-automation/xyz-vendor.sh`, not
`skills/xyz/SKILL.md` — on inspection it does **not** appear to touch the self-extract blocks at all,
so the "re-verify" note on the ROADMAP status line looks like it refers to a different, unrelated
installer path (GH-104's full-mirror vendor install) rather than this one. Re-confirm this GH-94
heredoc bug against a fresh programmatic materialization before assuming it's fixed.

## Fix direction

1. **Cheap first step:** reproduce with a fresh programmatic materialization (not a human paste) to
   confirm the bug still exists as described, since the file it lives in hasn't been touched since
   filing.
2. **If still broken:** offer an install path that doesn't round-trip through a shell heredoc at all —
   a downloadable release tarball, and/or an `npx` entry point (this repo currently ships no
   `package.json`, so an `npx` path would be new surface, not a tweak).

## Swarm Preflight Contract

```json
{"target":{"repo":".","ref":"main"},"gate":"true","fix_probes":[{"type":"path_absent","path":"package.json"}],"artifacts":["skills/xyz/SKILL.md"],"remediation":{"source":"self#fix-direction","criteria":"Reproduced against a fresh programmatic materialization; if still broken, either the self-extract block's escaping is fixed/documented, or an alternative install path (release tarball / npx) is shipped."},"lanes":{"orchestrator_only":[]}}
```
