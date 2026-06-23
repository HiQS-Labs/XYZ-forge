Yes. **Similar systems exist, but I did not find a single obvious drop-in clone of your whole stack.** The closest matches cover pieces of it: agent instruction files, spec/task workflows, autonomous coding agents, multi-agent orchestration, and docs-as-code linting. Your distinctive bit is the combination of **repo-local doc lifecycle governance + deterministic checks + advisory LLM review + pointer-only roadmap + agent safety/cost rails.**

Your system appears to be three things glued together:

1. **Agent entry/routing contract** — `ROUTER.md` tells agents what to read, what is canonical, and what validation must run before claiming success. 
2. **PDDA doc-governance layer** — active docs live in lifecycle buckets, require frontmatter, a strict “what changed / what next” status table, QA gates, repo-relative paths, deterministic hygiene checks, and an advisory LLM review.  
3. **Agent execution / hardening layer** — cost-observed marathon loops, headless build→review chaining, worktree isolation, epoch fencing, chaos/recovery, cross-repo targeting, and relay containment hardening.   

## Closest existing systems

| Your subsystem                                   | Already-existing analogs                                                                                                                                                                                                                                                                                                                                                                                                               | My take                                                                                                                                                                        |
| ------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Agent startup instructions / repo onboarding** | **AGENTS.md** is now a common/open format for coding-agent repo instructions and says it is used by over 60k open-source projects; OpenAI Codex explicitly reads `AGENTS.md`; Claude Code uses `CLAUDE.md` project memory files. ([Agents][1]) ([OpenAI Developers][2]) ([Claude Code][3])                                                                                                                                             | Do not overbuild this. Keep `ROUTER.md` only if it adds stronger routing than `AGENTS.md`; otherwise fold most of it into `AGENTS.md` and keep `ROUTER.md` as a local index.   |
| **Spec/task/project workflow for AI coding**     | **Agent OS** captures and deploys coding standards across agentic development; **Task Master** uses PRDs as the start of an AI task flow; **GitHub Spec Kit** is an open toolkit for spec-driven development with AI agents; **BMad Method** provides specialized AI agents, guided workflows, and planning from ideation to implementation. ([Builder Methods][4]) ([docs.task-master.dev][5]) ([GitHub Pages][6]) ([BMAD Method][7]) | This is the most direct threat to refining PDDA as a “method.” Borrow or interop. Your value is not “AI project docs exist”; it is the strict lifecycle/ledger/checking layer. |
| **Autonomous coding runner / issue-to-PR loop**  | **GitHub Copilot coding agent** can be assigned issues and produce PRs; GitHub Agent HQ has Claude and Codex agents in public preview; **OpenHands** provides a self-hosted coding-agent control center and SDK; **SWE-agent** autonomously uses tools to fix real GitHub repo issues. ([The GitHub Blog][8]) ([The GitHub Blog][9]) ([GitHub][10]) ([GitHub][11])                                                                     | Do not spend lots of time building a general coding-agent runner unless your safety rails materially outperform these. This area is crowded.                                   |
| **Multi-agent orchestration runtime**            | **LangGraph** is a low-level runtime for long-running, stateful agents with durable execution; **AutoGen** is Microsoft’s event-driven framework for scalable multi-agent AI systems. ([LangChain Docs][12]) ([Microsoft GitHub][13])                                                                                                                                                                                                  | If your relay/marathon layer grows into a platform, you may be recreating these. Use them as substrate if you need durability/state graphs.                                    |
| **Docs-as-code / docs linting**                  | **Backstage TechDocs** is a docs-like-code system for Markdown living with code; **GitHub Docs** uses markdownlint plus custom rules; **Vale** is a markup-aware prose linter; **lychee** checks Markdown/HTML links. ([Backstage][14]) ([GitHub Docs][15]) ([GitHub][16]) ([GitHub][17])                                                                                                                                              | Generic doc hygiene is solved. Keep only custom checks that encode your repo’s agent-operating contract.                                                                       |

## The decision

**Do not keep refining it as a broad platform.** Too many pieces already exist.

**Do keep the parts that are genuinely opinionated and hard to buy:**

* `ROADMAP.md` as a **pointer ledger**, not a second plan body. That distinction is explicit in your roadmap and PDDA contract.  
* The exact active-doc contract: frontmatter, near-top status table, QA gates, repo-relative paths, and no stale/hidden next actions. 
* Deterministic checks first, advisory LLM checks second, with the LLM layer unable to block the build. 
* “Do not claim success unless validation ran” as a repo rule. 
* Safety rails around autonomous turns: worktree isolation, epoch fencing, commit containment, cost tracking, and recovery.  

That is the part I would preserve.

## What I’d stop refining

I would stop investing in:

* A general replacement for AGENTS.md / CLAUDE.md / repo instruction files.
* A general PRD-to-task system.
* A generic multi-agent runner.
* Generic Markdown/prose/link linting.
* A large “AI agile methodology” surface area.

Those markets already have strong incumbents or fast-moving open-source projects.

## What I’d turn this into

The strongest positioning is:

> **A thin repo-governance and safety layer for autonomous coding agents.**

Not “an AI project-management framework.” Not “a coding-agent platform.” More like:

* `pdda-run.sh` = deterministic repo-doc contract checker
* `pdda-doc-ready.sh` = advisory planning-quality reviewer
* `ROADMAP.md` = pointer ledger
* `ROUTER.md` / `AGENTS.md` = agent entry contract
* relay/marathon = optional execution harness
* safety rails = the defensible kernel

## Practical recommendation

Freeze the design. Then compare against these candidates:

* **OpenHands** or **GitHub Agent HQ/Copilot coding agent** for replacing the headless execution loop.
* **Agent OS**, **Task Master**, **Spec Kit**, or **BMad** for replacing broad planning/task workflow.
* **markdownlint + Vale + lychee** for commodity documentation checks.
* Keep PDDA only where it encodes rules those tools do not: lifecycle buckets, pointer-ledger coverage, exact active-doc readiness, non-blocking LLM review, and “verified success only.”

My read: **you built something real, but the broad platform category is already crowded. The durable value is your guardrail layer, not the whole harness.**

[1]: https://agents.md/?utm_source=chatgpt.com "AGENTS.md"
[2]: https://developers.openai.com/codex/guides/agents-md?utm_source=chatgpt.com "Custom instructions with AGENTS.md – Codex | OpenAI Developers"
[3]: https://code.claude.com/docs/en/memory?utm_source=chatgpt.com "How Claude remembers your project - Claude Code Docs"
[4]: https://buildermethods.com/agent-os?utm_source=chatgpt.com "Agent OS | Coding standards for AI-powered development"
[5]: https://docs.task-master.dev/getting-started/quick-start/prd-quick?utm_source=chatgpt.com "PRD Creation and Parsing - Task Master"
[6]: https://github.github.com/spec-kit/?utm_source=chatgpt.com "GitHub Spec Kit | Spec Kit Documentation"
[7]: https://docs.bmad-method.org/?utm_source=chatgpt.com "Welcome to the BMad Method | BMAD Method"
[8]: https://github.blog/ai-and-ml/github-copilot/assigning-and-completing-issues-with-coding-agent-in-github-copilot/?utm_source=chatgpt.com "Assigning and completing issues with coding agent in GitHub Copilot"
[9]: https://github.blog/changelog/2026-02-04-claude-and-codex-are-now-available-in-public-preview-on-github/?utm_source=chatgpt.com "Claude and Codex are now available in public preview on GitHub"
[10]: https://github.com/OpenHands/OpenHands?utm_source=chatgpt.com "GitHub - OpenHands/OpenHands: OpenHands: AI-Driven Development"
[11]: https://github.com/SWE-agent/SWE-agent?utm_source=chatgpt.com "GitHub - SWE-agent/SWE-agent: SWE-agent takes a GitHub issue and tries ..."
[12]: https://docs.langchain.com/oss/python/langgraph/overview?utm_source=chatgpt.com "LangGraph overview - Docs by LangChain"
[13]: https://microsoft.github.io/autogen/stable/index.html?utm_source=chatgpt.com "AutoGen — AutoGen - microsoft.github.io"
[14]: https://backstage.io/docs/features/techdocs/?utm_source=chatgpt.com "TechDocs Documentation | Backstage Software Catalog and Developer Platform"
[15]: https://docs.github.com/en/contributing/collaborating-on-github-docs/using-the-content-linter?utm_source=chatgpt.com "Using the content linter - GitHub Docs"
[16]: https://github.com/vale-cli/vale?utm_source=chatgpt.com "GitHub - vale-cli/vale: :pencil: A markup-aware linter for prose built ..."
[17]: https://github.com/lycheeverse/lychee?utm_source=chatgpt.com "GitHub - lycheeverse/lychee: ⚡ Fast, async, stream-based link checker ..."
