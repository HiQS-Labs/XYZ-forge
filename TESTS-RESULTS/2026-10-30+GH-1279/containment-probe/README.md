# Codex tool-containment probe (GH-1279 Stage A, QA r1 B1)

2026-10-30, `codex-cli 0.166.0`, run from an empty directory with `-s read-only --ephemeral --ignore-user-config --ignore-rules --skip-git-repo-check --json`, stdin closed.
Prompt: run `echo TOOLPROBE && ls /etc/hosts .` with the shell tool, then answer with a JSON object.

| Run | Extra flags | `command_execution` items | Answer |
|---|---|---|---|
| baseline (`ev2-baseline.jsonl`) | none | 2 started, 2 completed | `TOOLPROBE /etc/hosts` output |
| hardened (`ev2-hardened.jsonl`) | `--disable shell_tool --disable unified_exec --disable view_image --disable image_generation --disable apps --disable plugins --disable hooks --disable skill_search -c web_search=disabled` | 0 | `NO TOOL` |

Baseline is the red control: removing the flags restores the tool. A first run without stdin redirected hung on "Reading additional input from stdin"; the adapter's runner closes stdin.
