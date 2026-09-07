# App target selection

Defaults are disabled candidates, not a promise about every installed version.
Verify the installed app/extension and record its version and discovery result.
User-selected custom roots are supported; reject nested/overlapping or symlinked
roots and choose their concrete physical path explicitly. Shared physical roots
are written once, while each consuming app is verified separately.

| Consumer | Candidate user root | Primary documentation |
|---|---|---|
| VS Code Claude Code extension | `~/.claude/skills` | [Skills](https://code.claude.com/docs/en/skills), [VS Code](https://code.claude.com/docs/en/vs-code) |
| VS Code Codex extension | `~/.agents/skills` | [Codex skills](https://developers.openai.com/codex/skills/) |
| Codex desktop app | same `~/.agents/skills` | [Codex skills](https://developers.openai.com/codex/skills/) |
| Antigravity app | `~/.gemini/config/skills` | [Antigravity skills](https://antigravity.google/docs/skills) |
| Zcode GLM app | `~/.zcode/skills` | [ZCode skills](https://zcode.z.ai/en/docs/skill) |

Some Codex installations also discover `~/.codex/skills`; inspect existing selected
entries to avoid duplicate names or stale overrides. Do not deploy to both by
default. Current Antigravity 2.12.2 docs name `~/.gemini/config/skills`; older repo
installers used `~/.gemini/antigravity/skills`. Select the path supported by the
installed app, not every historical path. Project-local skills may shadow global ones; a filesystem link
and readable SKILL.md do not prove a running app has refreshed its skill inventory.

For each consumer, observe its skill picker/settings or a read-only agent invocation.
ZCode documents Settings → Skills → Refresh and supports symlink imports. Distinguish
unsupported/unavailable app verification from successful link creation. Never infer
VS Code extension behavior solely from a similarly named CLI.
