Yes — there's real shared DNA, but they're solving adjacent problems from opposite ends. Here's the honest comparison.

Where they overlap
Concept	Eve	This repo (tick / relay-automation)
Filesystem-as-interface	"A file's location says what it does; its path gives it a name." No registry.	.tick/events/ + STATE.md projection; relay threads in dated folders; skills-as-files. State is the filesystem.
Durable / resumable sessions	Workflow SDK makes sessions crash-safe & resumable.	Append-only event log → replayable projection; watchdogs + poll-driven turn-takers survive restarts.
Skills	"Longer procedures loaded contextually."	Literal skill/ surface + Claude Code skills loaded on trigger.
Hooks / lifecycle	Hooks for event reactivity.	Watchdogs, poll loops, + Claude Code hooks (you can see them firing in this session).
Schedules	Recurring work automation.	loop / schedule / cron + Marathon phase chaining.
Sandbox	Controlled workspace for file/command ops.	Command sandbox + path-scoped claims (lanes).
Connections	External MCP server tools.	MCP servers (context-mode, connectors).
So if you squint, both are filesystem-first, durable, skill/hook/schedule-shaped agent substrates. That convergence is striking and worth noting — it's the same design vocabulary.

Where they fundamentally diverge
The two "multi-agent" stories are not the same thing:

Eve = a framework/SDK to build one durable agent product, where a root agent delegates to its own subagents and talks to Slack/Discord/HTTP channels. The agents are cooperative and framework-coordinated. Hosted, vendor stack.
This repo = a coordination spike to make separately-owned, heterogeneous vendor CLIs (Claude Code, Codex, Gemini) work concurrently on one shared git repo without colliding. Local-transport only, no accounts, no remote dependency.
The load-bearing piece of this project — tick claim with O_EXCL locks, drift detection, file-collision analysis, the honest-concurrency metric — has no analog in Eve, because Eve never has two independently-owned agents racing for the same file. Its subagents are conducted; yours are negotiated.

Bottom line
They share a design philosophy (filesystem-first, durable, hook/skill/schedule primitives) but live at different layers: Eve is "how to build a durable agent"; this repo is "how to keep N agents you didn't build from stepping on each other." Eve is the closest mainstream framework to your aesthetic — but it assumes away the exact problem (tick's collision-free claims across heterogeneous agents) that this spike exists to solve.

Want me to pull the actual Eve subagent/sandbox API pages and do a deeper primitive-by-primitive map (e.g. could tick sit under an Eve-style framework, or is it a competitor)?