From: Claude Opus 4.8 Max Web App
Status: Rough Research

I'll verify the current state of fine-tuning/custom-model options before answering, since this changes over time. Let me check Anthropic's product docs and search.Let me check the "build a custom agent" path (Agent SDK, subagents, skills), which is the more relevant lever here.Short version: you're conflating two very different things, and the one that would actually help you is the one you're already doing.

**"Build" vs "train" — they're not the same lever**

*Building* a custom agent means configuring the harness around a stock model: system prompts, a curated toolset, MCP connectors, hooks, restricted-permission subagents, skills. No weights change. This is fully supported, and your marathon/relay stack *is* exactly this — `marathon-agent.sh` routing to per-model shims with containment is a hand-rolled custom agent.

*Training* (fine-tuning) means updating model weights on your data. For Claude this is deliberately narrow: fine-tuning is available only for Claude 3 Haiku, only through Amazon Bedrock (US West / Oregon), and direct fine-tuning of other Claude models through Anthropic's native API remains unavailable to general users. Genuine custom-model training exists but only through enterprise contracts with committed spend, involving Anthropic's professional-services engineers — not a self-serve API. The gating is intentional: Anthropic has been explicit that unrestricted fine-tuning can degrade Constitutional AI properties and introduce safety regressions.

Other labs differ: OpenAI and Google both offer self-serve fine-tuning of *some* of their models, and open-weight models (Llama, DeepSeek) let you fine-tune fully on your own infra — the path to take if you require model weights for on-premise deployment, fine-tuning, or auditability.

**Would a trained agent beat Claude Code driving the process? Almost certainly not, for you**

Fine-tuning is the wrong tool for "more capable at specific tasks" in an agentic system. It does *not* make a model smarter at multi-step reasoning — agentic capability lives in the tools, context, and harness, not the weights. Worse, for you specifically: you'd be fine-tuning *Haiku 3*, which is weaker than the Sonnet/Opus you currently drive, and you'd freeze out every future model improvement.

Fine-tuning wins in a narrow band: high-volume, fixed, well-defined sub-tasks where you want style/format conformance or lower latency/cost — e.g. a classification task where fine-tuned Haiku went from 81.5% to 99.6% accuracy while cutting tokens per query by 85%. That's a classifier, not a builder/reviewer loop.

So the framing "custom trained agent vs Claude Code" is mostly a false choice — the effective agent *is* a stock model plus your tooling.

**The process, quick wins first → hardest last**

1. **Sharpen the harness you have (90% of the gains).** Better tool design, tighter subagent prompts and `description` fields, skills for repeatable procedures, and context engineering (what each turn actually sees). This is where capability comes from.
2. **Specialized subagents with restricted toolsets** — you're already half here with builder=`Bash,Read,Edit,Write` vs reviewer=`Bash,Read`. Push further: dedicated review/test/research subagents, each on the cheapest model that suffices. Watch the cost: subagent sprawl is the loudest production complaint — every extra agent multiplies memory, context, and cost.
3. **Consider the Claude Agent SDK** if you want hooks, session resume, and file checkpointing for free instead of hand-rolling them — it's the exact agent loop that powers Claude Code, driven from your own Python or TypeScript program. Weigh this against your existing bash containment, which already gives you tighter, more auditable control than the defaults. Don't migrate just to migrate. (Also note the rule of thumb: use an agent only for open-ended problems; if you can hardcode the workflow, a linear script is faster and cheaper — your relay loop is already mostly deterministic, which is correct.)
4. **Fine-tune only as a last resort, for a narrow leaf task.** A high-volume classifier/router → Haiku 3 on Bedrock. Org-level domain training → your Anthropic account team. Neither replaces your orchestrator.

One operational flag relevant to your headless `claude -p` turns: as of June 15, 2026, Agent SDK and `claude -p` usage on subscription plans draws from a separate monthly Agent SDK credit pool ($20 Pro / $100 Max 5x / $200 Max 20x) rather than your interactive limits — worth checking against your budget caps in `claude-turn.sh`.

Bottom line: don't train. Invest in tools, context, and subagent decomposition on top of the strongest stock model — which is what your marathon stack already does.