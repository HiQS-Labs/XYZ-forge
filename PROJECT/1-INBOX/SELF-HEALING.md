See GH issue 61

**Building a self-healing agent harness requires transitioning your engineering focus from manual bug-fixing to managing a highly structured pipeline that enforces codebase health, deterministic execution, and mandatory proof of work.** 

Based on the engineering practices of teams deploying production-level self-healing systems, here is a practical sketch of the core architectural principles and actionable steps you can apply to your own agent harness:

### Core Architectural Principles

*   **Enforce a "Flow State" Codebase**: An agent harness cannot reliably navigate a chaotic environment. Your codebase must remain in a clean, consistent "flow state" where documentation is up to date and active refactorings or major platform migrations are not actively tripping up the agent.
*   **Establish Deterministic, Decoupled Steps**: Instead of running a single unguided agent, divide your self-healing pipeline into discrete, specialized steps connected only by deterministic outputs. This structured workflow helps steer the agent step-by-step from triage to a verified outcome.
*   **Demand Proof of Work**: Never rely on an agent's word that a bug is resolved. Your system must require agents to explain how they will prove their fix works and then execute that validation (such as running automated browser tests or generating run videos) to verify success and self-correct if they fail.
*   **Leverage Multi-Layered Guardrails**: Build a defensive pipeline that combines third-party agent reviewers, automated security checkers, and custom validation tools before code changes reach a human. If there is a dispute or architectural mismatch, the system must immediately raise a flag for human review.
*   **Manage the "Multiplying Effect"**: Agents can multiply either your engineering foundations or your technical debt. Shift human engineering efforts "up the stack" to architectural audits, validation rules, and product decisions while managing the agents doing the bulk of the manual work.

---

### Concrete Action Items for Your Agent Harness

#### 1. Harden Codebase Health & Testing Rules
*   **Convert Warnings to Errors**: Configure your environment to treat all compile and runtime warnings as strict errors to eliminate ambiguity for the agent. Log unavoidable legacy issues separately to keep the agent's focus clean.
*   **Prioritize Failure-State Testing**: Pivot your testing strategy away from basic code coverage percentages toward validating failure states, bad data inputs, and 500 error handling.
*   **Establish Automated Housekeeping**: Run scheduled GitHub Actions to automatically update local wikis, conduct architectural audits, and identify gaps in test coverage.

#### 2. Structure the Self-Healing Pipeline
*   **Implement a 5-Stage Event Loop**: Design your pipeline to ingest incoming events (Sentry errors, Slack alerts, Linear bugs) and drive them through five deterministic stages: **Triage**, **Discovery**, **Root Cause Analysis (RCA)**, **Solution**, and **Proof**.
*   **Isolate Discovery and Execution**: Use the triage stage to classify issues, and allow the discovery phase to spin off specialized sub-agents to analyze the codebase without modifying files.
*   **Feed Custom Skills to Agents**: Equip your agents with explicit skills—such as using Model Context Protocol (MCP) servers to pull worker logs or cloud console telemetry—to help them resolve bugs autonomously.

#### 3. Harness the Pull Request and Merge Flow
*   **Chain Specialized Reviewers**: Route every agent-generated PR through third-party automated reviewers like Graphtile alongside security scanning tools.
*   **Deploy an Automated "Agent Merge Tool"**: Create a dedicated agent to ingest feedback from PR reviews and automatically write the code modifications required to address those comments.
*   **Create Architectural Validation Skills**: Build custom verification skills that enforce your specific backend patterns and raise a human review flag the moment there is an architectural disagreement or business-case conflict.

#### 4. Optimize Token Spend and Agent Behavior
*   **Shift from Real-Time to Scheduled Loops**: To avoid massive token bills from continuous triggers (such as running a deep scan on every single code commit), batch recurring tasks like dependency updates, doc generation, or security audits into scheduled periodic runs.
*   **Audit Agent Session Logs**: Routinely review session recordings to identify where agents are exploring stale directories, getting stuck, or operating with outdated instruction files (agent markdown documents) so you can adjust their guardrails and skills.

📊 Want me to generate an infographic of the 5-stage event loop so you can visualize how issues flow from triage to proof?