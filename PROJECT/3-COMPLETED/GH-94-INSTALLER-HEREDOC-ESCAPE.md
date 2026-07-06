---
gh_issue: 94
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/94
title: "Installer: self-extracting heredoc mangles `!`→`\\!` when materialized programmatically; offer release tarball / npx"
status: SHIPPED 2026-07-06 — re-verify spike done; doc-guard fix landed; npx/tarball deferred (not needed at this severity)
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

## Spike findings (2026-07-06)

Re-verified against a fresh programmatic materialization of the §4 installer block, extracted **verbatim** from `skills/xyz/SKILL.md` (lines 98–1333) and executed.

- **Faithful path is clean.** `sed -n '98,1333p' SKILL.md > installer.sh && bash installer.sh out/` materialized all 11 runtime files, `!==` intact, **0 `\!`**, and `out/bin/tick --help` runs. The committed artifact is **correct** — the bug is *not* in `SKILL.md`.
- **The bug is a materialization-method defect, and it is real.** Reproduced by routing the block through a layer that escapes `!`→`\!` for a double-quote/`bash -c` context before it reaches the (single-quoted) heredoc: the `\!` is then written **literally**, corrupting `!==`→`\!==` in the extracted JS. This matches the original diagnosis exactly.
- **Not reproduced** via plain interactive history expansion (`bash -H -i script.sh`) — the quoted heredoc suppresses it; only an upstream escaping layer triggers the corruption.

**Disposition:** LOW-severity, method-specific. Shipped the proportionate fix — a materialization guard in **§4 and §4b** of `SKILL.md` telling agents to write the raw block to a file (never through a `!`-escaping `bash -c`/history-expansion wrapper), plus a `grep -rn '\!'` triage hint if `validate.sh` fails. The heavyweight **npx / release-tarball** alternative is **deferred, not shipped** — disproportionate for this severity and blast radius; file a separate enhancement if a non-heredoc distribution path is wanted for other reasons. `package.json` intentionally still absent.

## Swarm Preflight Contract

> Resolved via doc-guard (see Spike findings). Contract retained for provenance; `package.json` remains absent by design (npx path deferred), so this lane is no longer marathon-fireable — the fix already landed.

```json
{"target":{"repo":".","ref":"main"},"gate":"true","fix_probes":[{"type":"grep_present","path":"skills/xyz/SKILL.md","pattern":"history-expansion / double-quote escaping layer"}],"artifacts":["skills/xyz/SKILL.md"],"remediation":{"source":"self#spike-findings","criteria":"Re-verified: faithful materialization is clean; bug is materialization-method-specific. Shipped a materialization guard in SKILL.md §4/§4b. npx/tarball deferred."},"lanes":{"orchestrator_only":[]}}
```
