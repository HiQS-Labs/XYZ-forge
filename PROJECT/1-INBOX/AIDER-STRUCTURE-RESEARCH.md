Here's the comprehensive breakdown:

## Root Cause: You're Using the Wrong Edit Format

The critical issue is that `--edit-format diff` is the worst possible choice for mid-weight local models. In Aider's terminology, `diff` doesn't mean unified diff — it means **SEARCH/REPLACE blocks**, a format that requires the model to exactly reproduce source code snippets for matching. This is the hardest format for local models to follow. [aider](https://aider.chat/docs/more/edit-formats.html)

Aider's own benchmark data and testing consistently show that **`whole` format beats `diff` for every local model variant**. Local models "frequently fail to negotiate diff and silently fall back, breaking search/replace edits". When the model produces conversational text instead of properly formatted SEARCH/REPLACE blocks, Aider interprets the output as a no-op — what you're seeing as "token-only moves." [modelfit](https://modelfit.io/tools/aider/)

## Immediate Fix: Switch to `--edit-format whole`

```bash
aider --edit-format whole --model lm_studio/bonsai-27b
```

The `whole` format simply asks the model to return the complete updated file inside a fenced code block with the filename as a header. This is the lowest-protocol-compliance-burden format and is what Aider already defaults to for unknown/lesser-known models (Aider editing format docs, Aider troubleshooting). [aider](https://aider.chat/docs/llms/editing-format.html)

One developer testing local models with Aider reported that switching to `--edit-format whole` caused parse errors to "almost completely disappear" — the model no longer needed to reproduce code character-for-character for matching. [zenn](https://zenn.dev/tkpurine/articles/local-llm-study-002-aider-model-screening)

## Complete Configuration Setup

You need three files for proper local model integration:

### `~/.aider.conf.yml`

```yaml
# Point to your custom model settings and metadata files
model-settings-file: .aider.model.settings.yml
model-metadata-file: .aider.model.metadata.json

# Use LM Studio as the provider (not openai/)
model: lm_studio/bonsai-27b

# Force the whole edit format
edit-format: whole

# Reduce context burden — critical for local models
map-tokens: 0

# Headless / autonomous loop settings
yes-always: true
no-auto-commits: true
no-stream: true

# Max context — must match what LM Studio is configured to serve
max-context-tokens: 32768
max-chat-history-tokens: 2048
```

Note: Use the `lm_studio/` prefix (not `openai/`) and set the LM Studio-specific environment variables, which handle the dummy API key requirement automatically: [aider](https://aider.chat/docs/llms/lm-studio.html)

```bash
export LM_STUDIO_API_KEY=dummy-api-key
export LM_STUDIO_API_BASE=http://127.0.0.1:1234/v1
```

### `.aider.model.settings.yml`

This file gives you per-model behavioral overrides that Aider's built-in settings don't cover for unknown models: [deepwiki](https://deepwiki.com/Aider-AI/aider/6.2-model-settings)

```yaml
- name: lm_studio/bonsai-27b
  edit_format: whole
  weak_model_name: null          # Don't spawn a second model for commit messages
  use_repo_map: false            # Disable repo map to save context tokens
  examples_as_sys_msg: true      # Put format examples in system message
  reminder: sys                  # Format reminders in system prompt
  system_prompt_prefix: |
    You are a code editing agent. Output ONLY the complete updated file
    inside a fenced code block with the filename as a header line.
    Do not explain what you are doing. Do not summarize changes.
    Return the full file content with no omissions or placeholders.

- name: lm_studio/gemma-4-31b
  edit_format: whole
  weak_model_name: null
  use_repo_map: false
  examples_as_sys_msg: true
  reminder: sys
  system_prompt_prefix: |
    You are a code editing agent. Output ONLY the complete updated file
    inside a fenced code block with the filename as a header line.
    Do not explain what you are doing. Do not summarize changes.
    Return the full file content with no omissions or placeholders.
```

The `system_prompt_prefix` field is the closest thing to a system prompt override — it prepends text to the coder's system prompt without replacing it entirely. There is no documented flag to fully replace Aider's system prompts; the FAQ notes that deeper prompt changes require modifying the coder source files in `aider/coders/`. [aider](https://aider.chat/docs/faq.html)

### `.aider.model.metadata.json`

```json
[
  {
    "name": "lm_studio/bonsai-27b",
    "max_tokens": 32768,
    "max_input_tokens": 30000,
    "max_output_tokens": 8192,
    "supports_system_messages": true,
    "supports_function_calling": false,
    "supports_vision": false,
    "mode": "chat"
  },
  {
    "name": "lm_studio/gemma-4-31b",
    "max_tokens": 32768,
    "max_input_tokens": 30000,
    "max_output_tokens": 8192,
    "supports_system_messages": true,
    "supports_function_calling": false,
    "supports_vision": false,
    "mode": "chat"
  }
]
```

Adjust `max_output_tokens` to match what your model/server supports. Too low and the model will truncate mid-file; too high and the server may reject the request.

## Context Window: The Silent Killer

Aider's troubleshooting page emphasizes that above ~25k tokens of context, most models "start to become distracted and become less likely to conform to their system prompt". Local model servers (LM Studio, Ollama) often default to very small context windows that silently truncate Aider's prompts. [aider](https://aider.chat/docs/troubleshooting/edit-errors.html)

In LM Studio, explicitly set the context length in the model load settings (e.g., 32768 or 65536 depending on your RAM). Then match it in `.aider.model.metadata.json` and `.aider.conf.yml` as shown above. Mismatches between the server's context window and what Aider thinks it has will cause silent truncation.

## Architect Mode: Separating Reasoning from Editing

If `whole` format still fails, architect mode splits the task into two LLM calls — first the model reasons about the solution in plain text, then a second call (potentially the same model) translates that into file edits:

```bash
aider --architect \
  --model lm_studio/bonsai-27b \
  --editor-model lm_studio/bonsai-27b \
  --editor-edit-format editor-whole \
  --yes-always
```

Architect mode "often produces more reliable edits, especially with models that have trouble following edit format instructions" because it "allowing the model two requests to solve the problem and edit the files" (Aider architect mode, Aider architect blog). Using `editor-whole` (the simplified whole format for editor mode) further reduces the protocol burden on the editing pass. [aider](https://aider.chat/docs/usage/modes.html)

You can also set this in `.aider.conf.yml`:

```yaml
architect: true
editor-model: lm_studio/bonsai-27b
editor-edit-format: editor-whole
auto-accept-architect: true
```

## Agent-Loop Guardrails

For your autonomous loop, implement this verification cycle to detect and recover from token-only moves:

```bash
#!/bin/bash
# Retry policy: if no git diff after a run, retry with smaller scope

run_aider_task() {
  local task="$1"
  local file="$2"

  aider \
    --message "$task" \
    --edit-format whole \
    --yes-always \
    --no-auto-commits \
    --no-stream \
    --map-tokens 0 \
    --model lm_studio/bonsai-27b \
    "$file"

  # Check if any changes were actually applied
  if git diff --exit-code --quiet -- "$file"; then
    echo "WARNING: No changes applied. Retrying with reduced scope..."
    aider \
      --message "Apply ONLY this change: $task. Output the complete file." \
      --edit-format whole \
      --yes-always \
      --no-auto-commits \
      --no-stream \
      --map-tokens 0 \
      --model lm_studio/bonsai-27b \
      "$file"

    if git diff --exit-code --quiet -- "$file"; then
      echo "FAILED: Model could not produce valid edits for $file"
      return 1
    fi
  fi
  return 0
}
```

Key principles for the loop:
- **One file per call** — pass a single file to each Aider invocation instead of multi-file tasks
- **Check `git diff --exit-code`** after each run to detect no-ops
- **Retry once** with a more explicit prompt and reduced scope
- **Escalate or skip** if the retry also fails — don't burn iteration caps on a stuck model

## Edit Format Hierarchy for Local Models

Based on Aider's own benchmark data and the edit format tradeoff table: [deepwiki](https://deepwiki.com/Aider-AI/aider/6.2-model-settings)

| Format | Difficulty | Token Efficiency | Local Model Suitability |
|--------|-----------|-------------------|------------------------|
| `whole` | Easy | Low | Best — lowest protocol burden |
| `diff` | Moderate | High | Bad — requires exact code reproduction for SEARCH/REPLACE |
| `diff-fenced` | Medium | Medium | Mainly for Gemini models, not Gemma |
| `udiff` | Hard | High | Worst for local models — requires strict unified diff syntax |
| `editor-whole` | Easy | Low | Good when paired with architect mode |

## Honest Assessment: Gemma Models on Aider

The Gemma family has historically performed very poorly on Aider's edit benchmark. Gemma 3 27B scored **4.9%** on Aider's polyglot coding leaderboard — near the bottom of all tested models, with "weak edit-following" (Aider leaderboards, ModelFit). [aider](https://aider.chat/docs/leaderboards/)

Gemma 4 shows improvement in general function-calling benchmarks (86.4% on tau2-bench, up from 6.6% for Gemma 3), and a multi-harness benchmark showed gemma-4-31b-it achieving 65/80 pass rate across multiple agent harnesses — but Aider-specific performance was notably weaker than other harnesses like `pi` or `opencode`. [neuralnoise](https://neuralnoise.com/2026/harness-bench-wip/)

For bonsai-27b, there's no published Aider benchmark data, so you'll need to test it directly.

## If Reliability Is Critical

If you need maximum reliability with local models on Aider, the strongest local picks are from the **Qwen2.5-Coder family** — the 14B variant tops the open-weight edit leaderboard in whole-file format and is the most reliable local pick for Aider specifically. If you can run the 32B variant, it's even better but requires more RAM. [modelfit](https://modelfit.io/tools/aider/)

## Summary

You can significantly improve reliability, but you cannot force a model that can't follow the protocol to do so reliably. The actionable path:

1. **Stop using `--edit-format diff`** — switch to `--edit-format whole` immediately
2. **Set up the three config files** with proper model settings, metadata, and `system_prompt_prefix`
3. **Ensure context windows match** between LM Studio and Aider's metadata config
4. **Use `--map-tokens 0`** to reduce context burden
5. **Try architect mode** with `editor-whole` if single-pass `whole` still fails
6. **Implement git diff verification** in your agent loop to detect and retry no-ops
7. **Use atomic single-file tasks** instead of multi-file refactoring requests