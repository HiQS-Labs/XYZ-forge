1. Loop Architecture & Goal Definition

- [ ] **Identify the Loop Type:** Determine if the task is **deterministic** (e.g., code must pass specific functional tests or compile) or **non-deterministic** (e.g., qualitative document review or "AI slop" detection).
- [ ] **Define the "End Goal" Clearly:** Instead of step-by-step instructions, define exactly what "done" looks like for the kernel (e.g., "Zero critical vulnerabilities from Codex and a 'Pass' on style from Gemini").
- [ ] **Set Explicit Termination Conditions:** Establish a rule for when the loop must stop to prevent the agents from running indefinitely or quitting too early without progress.

### 2. The Five-Step Execution Cycle

Your kernel should automate these five steps for every iteration between Claude, Codex, and Gemini:

- [ ] **State Check:** The kernel assesses the current status of the code/document.
- [ ] **Decision:** Claude decides the next action based on the state.
- [ ] **Action:** Claude calls tools, writes files, or runs the Codex/Gemini CLIs.
- [ ] **Feedback Gathering:** The kernel captures the raw output from the Codex and Gemini reviews.
- [ ] **Verdict:** A model or script determines if the feedback warrants another loop or if the task is finished.

### 3. Verification & Adversarial Mechanics

- [ ] **Establish Verification Gates:** Implement checkpoints that prevent Claude from marking a task as "done" until the reviewers (Codex/Gemini) provide a specific positive signal.
- [ ] **Cross-Model Verification:** Leverage the fact that different models are reviewing the work. Use the specific strengths of Gemini or Codex to catch "slop" or errors Claude might overlook.
- [ ] **Implement "Hooks":** Use scripts that trigger automatically after Claude writes code to run the CLI reviews immediately, ensuring the agent cannot drift from the goal.

### 4. Operational Robustness (The "Missing Pieces")

- [ ] **Context Management:** Do not rely solely on the chat history. As tool outputs from the CLIs grow, ensure the system prompt and core goals do not get "buried" or lost.
- [ ] **State Management Across Turns:** Use **external files** to track the history of reviews and fixes. This allows Claude to keep the "thread" of the project even if the context window becomes crowded.
- [ ] **Feedback Quality Control:** Ensure the kernel parses CLI outputs into a high-quality signal that the building agent can actually use to iterate.
- [ ] **Explicit Error Handling:** Define exactly what the kernel should do if a CLI tool fails (e.g., a timeout or crash) so the loop doesn't leave the project in a "broken state".

### 5. Efficiency & Optimization

- [ ] **Token Budgeting:** Since autonomous loops can be expensive, set a "deliberate" policy for when to trigger the full multi-agent review loop versus a simple self-correction.
- [ ] **Non-Interactive Mode:** Configure the kernel to run Claude Code in non-interactive mode so it can iterate through feedback from Codex and Gemini without requiring human intervention.