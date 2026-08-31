HQ LaunchPad

Yes—**the core of VS Code is open source** (the “Code – OSS” repo on GitHub, MIT‑licensed), and you can absolutely fork it and build your own editor that hosts multiple VS Code extensions in custom panels. However, there are important practical and licensing caveats, and some extensions (including Claude Code and Codex) may have additional constraints beyond the editor itself.

## VS Code’s licensing and forking

- The **Code – OSS** repository (https://github.com/microsoft/vscode) is **MIT‑licensed** and explicitly intended to be forked and customized. [github](https://github.com/microsoft/vscode)
- The downloadable **“Visual Studio Code”** binaries from Microsoft are a **proprietary distribution** of that OSS code, with Microsoft-specific customizations, telemetry, and a different product license. [wiki.archlinux](https://wiki.archlinux.org/title/Visual_Studio_Code)
- Many forks (Cursor, Kiro, VSCodium, Devin Desktop, etc.) already do exactly what you’re describing: take Code – OSS, rebrand it, and ship a custom IDE. [vgtc](https://www.vgtc.io/insights/vs-code-forks-ide-landscape-2026-h1)

So legally, you can:

- Clone `microsoft/vscode` (Code – OSS).
- Modify the UI, add custom panels, change layout logic, bundle extensions, etc.
- Distribute your own build under your own branding, as long as you comply with the MIT license and any third‑party notices. [reddit](https://www.reddit.com/r/opensource/comments/1qys8mb/what_happens_if_the_license_changes_after_i_fork/)

You just can’t call it “Visual Studio Code” or use Microsoft’s trademarks, and you won’t automatically get access to Microsoft’s proprietary marketplace or some closed extensions. [wiki.archlinux](https://wiki.archlinux.org/title/Visual_Studio_Code)

## Custom panels and extension architecture

VS Code’s extension API is designed for exactly this kind of customization:

- Extensions can contribute **views**, **viewContainers**, **customEditors**, **webviews**, and **chatAgents** via `package.json` contribution points. [code.visualstudio](https://code.visualstudio.com/api/references/contribution-points)
- You can define new sidebar/activity bar containers and place extension views (including chat panels) wherever you want in your fork. [code.visualstudio](https://code.visualstudio.com/api/references/contribution-points)
- The “Copilot Chat” / “chatAgents” contribution point shows that Microsoft already expects AI agents to live as first-class panels inside the editor. [code.visualstudio](https://code.visualstudio.com/api/references/contribution-points)

If you control the host (your fork), you can:

- Add a custom “AI Agents” activity bar item.
- Create sub-panels for Claude Code, Codex, your Agy-style input, etc.
- Wire them up using existing view/webview APIs without breaking the extension model.

## Can Claude Code and Codex run in a clone?

### Claude Code

- The **Claude Code VS Code extension** is published by Anthropic and documented to work in:
  - Official VS Code (1.98.0+)
  - VS Code forks like **Cursor**, **Devin Desktop**, **Kiro**, etc., typically via the Open VSX registry or direct install. [eesel](https://www.eesel.ai/blog/claude-code-vs-code-extension)
- The extension itself is free; you need a **paid Claude plan** (Pro/Max/Team/Enterprise) to use it. [eesel](https://www.eesel.ai/blog/claude-code-vs-code-extension)
- There’s no public requirement that it only runs in Microsoft’s branded build; the docs explicitly mention “compatible forks.” [eesel](https://www.eesel.ai/blog/claude-code-vs-code-extension)

Practically:

- In your own fork, you’d:
  - Ensure your `product.json` and extension host behave like a standard VS Code 1.98+ environment.
  - Provide an extension marketplace (Open VSX or your own) or allow manual `.vsix` installs.
  - Install the Anthropic `anthropic.claude-code` extension.
- As long as your fork doesn’t break the extension APIs the Claude extension relies on (commands, webviews, chat contribution points, auth flows), it should run.

Anthropic could theoretically add checks that restrict certain builds, but as of now, their published guidance treats VS Code forks as valid hosts. [eesel](https://www.eesel.ai/blog/claude-code-vs-code-extension)

### Codex (OpenAI)

- OpenAI’s **Codex IDE extension** is also described as working with:
  - VS Code
  - VS Code Insiders
  - **Cursor** and **Windsurf** (both VS Code forks). [community.openai](https://community.openai.com/t/introducing-the-codex-ide-extension/1354930)
- It requires a **paid ChatGPT plan** (Plus/Pro/Team/Edu/Enterprise) or an API key setup. [community.openai](https://community.openai.com/t/introducing-the-codex-ide-extension/1354930)
- The extension is built on top of the open-source **Codex CLI**, and the docs explicitly say it works in “compatible forks.” [community.openai](https://community.openai.com/t/introducing-the-codex-ide-extension/1354930)

Same practical story as Claude:

- Your fork needs to:
  - Present a normal VS Code extension host.
  - Support the sidebar/chat panel APIs the Codex extension uses.
  - Allow installing the `openai.chatgpt` / Codex extension.
- No public requirement exists that it must be the Microsoft-branded editor.

## What could break in a custom fork?

Potential issues to watch for:

1. **Marketplace access**  
   - Microsoft’s official marketplace ToS restrict use to Microsoft-branded VS Code builds. [wiki.archlinux](https://wiki.archlinux.org/title/Visual_Studio_Code)
   - Forks typically use **Open VSX** or their own extension galleries.
   - You may need to:
     - Host your own extension registry.
     - Or let users install `.vsix` files manually.

2. **Product branding / telemetry hooks**  
   - Some extensions might check `product.json` fields (e.g., `extensionGallery`, `telemetryEndpoint`) and behave differently or refuse to run if they detect a non-standard host.
   - This is extension-specific; neither Anthropic nor OpenAI has publicly documented hard blocks, but it’s possible in the future.

3. **Chat / agent APIs**  
   - Both Claude Code and Codex lean on newer chat/agent contribution points (`chatAgents`, `languageModelTools`, etc.). [code.visualstudio](https://code.visualstudio.com/api/references/contribution-points)
   - Your fork must implement those APIs faithfully (or at least in a compatible way) if you want full functionality.

## Feasibility of your specific design

Your plan—“a custom VS Code-like shell that houses Claude Code, Codex, and Agy-style input boxes plus other extensions in custom panel locations”—is technically feasible:

- Use **Code – OSS** as the base.
- Add:
  - A custom activity bar entry (e.g., “Agents”).
  - Multiple view containers/panels:
    - One for Claude Code chat.
    - One for Codex chat.
    - One for your Agy-style multi-input orchestration UI.
- Install:
  - `anthropic.claude-code`
  - `openai.chatgpt` / Codex
  - Any other VS Code extensions you want.
- Optionally:
  - Add your own extension that provides the Agy-like UI and orchestrates calls to multiple agents.

Nothing in the current public docs for Claude Code or Codex says they require the “real” Microsoft VS Code; they target the **VS Code API surface**, which your fork can implement. [eesel](https://www.eesel.ai/blog/claude-code-vs-code-extension)

## Practical next steps if you want to build this

1. **Clone and build Code – OSS**  
   - Repo: https://github.com/microsoft/vscode  
   - Follow their “How to build from source” docs. [github](https://github.com/microsoft/vscode)

2. **Customize the layout**  
   - Add new `viewsContainers` and `views` in your own extension or in the core.
   - Define custom panels for each agent.

3. **Extension hosting**  
   - Decide on an extension marketplace strategy (Open VSX, private registry, or manual `.vsix` installs).
   - Ensure your `product.json` doesn’t break extension resolution.

4. **Test with Claude Code and Codex**  
   - Install their extensions in your fork.
   - Verify auth flows, chat panels, terminal access, and file operations work as expected.

If you’d like, I can sketch a minimal extension manifest and layout config showing how to register three agent panels (Claude, Codex, Agy) in a custom activity bar section.

===

Yes—you can absolutely compile VS Code on a Mac (including Apple Silicon M1/M2/M3). The Code – OSS repo builds natively on macOS with Xcode Command Line Tools, Node.js 20+, and Python. [github](https://github.com/microsoft/vscode/blob/main/README.md)

Below is a focused project plan to fork Code – OSS and ship a custom 3‑column editor with your exact layout.

***

## Project goal

Build a custom macOS desktop editor (“AgentCode”) based on Code – OSS that:

- Uses a fixed 3‑column workbench layout.
- Hosts standard VS Code extensions (file explorer, language features, Git, etc.).
- Integrates Claude Code, Codex, CommandCode, and DeepSeek as fixed panels in Column 3.

***

## High‑level architecture

- **Base**: `microsoft/vscode` (Code – OSS, MIT). [github](https://github.com/microsoft/vscode/blob/main/README.md)
- **Custom workbench**: Modified layout service + CSS + a small “layout extension” that enforces your 3‑column design.
- **Column 1**: Standard Explorer view (built‑in).
- **Column 2**:
  - Top: Project/Repo selector (custom view or extension).
  - Middle: PM Kanban dashboard (custom webview or integration with an existing task/issue extension).
  - Bottom: Single‑file editor (restricted to one file at a time).
- **Column 3**: Stacked AI panels:
  - Claude Code UI
  - Codex UI
  - CommandCode UI
  - DeepSeek UI  
  Each can be:
  - The official VS Code extension’s view (if available), or
  - A custom webview that wraps the CLI / API and mimics the official UI.

***

## Phase 0 – Environment & feasibility (1–2 days)

**Goals:** Confirm you can build and run Code – OSS on your Mac; validate extension model.

**Tasks:**

1. **Install prerequisites** (per VS Code’s “How to Contribute” docs): [github](https://github.com/microsoft/vscode/wiki/How-to-Contribute)
   - Git
   - Node.js ≥ 20.x (ARM64 build for Apple Silicon)
   - Python (for `node-gyp`)
   - Xcode Command Line Tools: `xcode-select --install`
2. **Clone and build Code – OSS:**
   ```bash
   git clone https://github.com/microsoft/vscode.git agentcode
   cd agentcode
   npm install
   npm run watch
   ```
   Then run:
   ```bash
   ./scripts/code.sh
   ```
   This launches “Code – OSS” locally. [github](https://github.com/microsoft/vscode/wiki/How-to-Contribute)
3. **Verify extension loading:**
   - Install a few marketplace extensions via `.vsix` or Open VSX.
   - Confirm chat/agent extensions (if any) load correctly.

**Deliverables:**

- Working local build of Code – OSS on your Mac.
- Notes on any build issues and resolutions.

***

## Phase 1 – Layout prototype (3–5 days)

**Goals:** Implement the 3‑column skeleton and enforce basic constraints.

**Tasks:**

1. **Create a custom “layout” extension** (e.g., `agentcode-layout`):
   - Contribute a new Activity Bar item (e.g., “AgentCode”).
   - Define a custom `viewContainer` with three sections (or use existing views and arrange via CSS).
   - Use `contributes.views` to register:
     - `agentcode.explorer` (wrapper around built‑in Explorer)
     - `agentcode.projectBar` (project selector + Kanban)
     - `agentcode.aiStack` (AI panels container)
2. **Enforce single editor tab:**
   - In `settings.json` of your build, set:
     ```jsonc
     "workbench.editor.limit.perEditorGroup": 1,
     "workbench.editor.limit.enabled": true,
     "workbench.editor.showTabs": false
     ```
   - Optionally, implement a small extension that intercepts editor open events and closes extra tabs automatically.
3. **Fix Kanban tabs:**
   - If using an existing Kanban extension, ensure its view is in Column 2 and mark it as non‑closeable by:
     - Customizing the view title menu to hide the close action.
     - Or, wrapping it in your own webview that embeds the Kanban UI and doesn’t expose a close button.
4. **Basic CSS tweaks:**
   - In your fork’s `workbench` CSS (or via a theme extension), define a 3‑column grid:
     - Column 1: ~250–300px (Explorer)
     - Column 2: ~50–60% width (Project + Kanban + Editor)
     - Column 3: ~350–450px (AI stack)

**Deliverables:**

- Running Code – OSS fork with:
  - Visible 3‑column layout.
  - Explorer in Column 1.
  - A placeholder Kanban + single‑file editor in Column 2.
  - A placeholder AI stack panel in Column 3.

***

## Phase 2 – Project/Repo selector & Kanban (4–7 days)

**Goals:** Make Column 2 functional for project switching and PM workflow.

**Tasks:**

1. **Project/Repo selector:**
   - Implement a small extension that:
     - Shows a dropdown or list of recent workspaces / Git repos.
     - On selection, calls `vscode.openFolder()` to switch projects.
   - Persist a curated list of “favorite” projects in extension state.
2. **Kanban dashboard:**
   Options:
   - **Option A:** Integrate an existing VS Code Kanban/issue extension (e.g., GitHub Issues, Jira, Linear) and embed its tree/webview in Column 2.
   - **Option B:** Build a custom Kanban webview:
     - Data source: GitHub Issues, GitLab, or a simple local JSON/SQLite store.
     - Columns: Backlog, TODO, In Progress, Review, Done.
     - Drag‑and‑drop using the webview’s HTML5 DnD API.
3. **Tie Kanban to editor:**
   - When a task/card is selected, open the associated file in the single editor pane (e.g., via file path stored in card metadata).

**Deliverables:**

- Working project switcher at the top of Column 2.
- Functional Kanban board integrated with your repo/issues.
- Clicking a card opens the related file in the single editor.

***

## Phase 3 – AI agent panels (7–14 days)

**Goals:** Integrate Claude Code, Codex, CommandCode, and DeepSeek into Column 3 as stacked panels.

**Tasks:**

1. **Decide integration strategy per agent:**
   - If an official VS Code extension exists and works in forks:
     - Bundle it in your build.
     - Contribute its view into your `agentcode.aiStack` container.
   - If not, wrap the CLI/API in a custom webview:
     - Run the agent CLI as a child process (e.g., `claude`, `codex`, `commandcode`, `deepseek`).
     - Stream stdin/stdout into a chat‑like UI.
2. **Implement a reusable “AgentPanel” webview component:**
   - Chat history view.
   - Input box with send button.
   - Context selectors (current file, selected text, entire project).
   - Status indicators (thinking, running commands, applying edits).
3. **Stack panels vertically:**
   - Use a single view container with multiple views:
     - `agentcode.ai.claude`
     - `agentcode.ai.codex`
     - `agentcode.ai.commandcode`
     - `agentcode.ai.deepseek`
   - Ensure each can be resized but not removed (hide close actions).
4. **Orchestration hooks (optional but powerful):**
   - Add commands like:
     - “Hand off to Claude”
     - “Run Codex review”
     - “Ask DeepSeek for design options”
   - These can transfer the current file + context to the chosen agent panel.

**Deliverables:**

- Four functional AI panels in Column 3.
- Each panel can:
  - Receive user input.
  - Show agent responses.
  - Apply edits to the open file (where supported).

***

## Phase 4 – Hardening, branding, and distribution (5–10 days)

**Goals:** Turn the prototype into a shippable product.

**Tasks:**

1. **Product branding:**
   - Update `product.json` in your fork:
     - `nameShort`, `nameLong`, `applicationName`, `win32AppName`, etc.
     - Custom icons, about dialog text, and help URLs.
   - Ensure you’re not using Microsoft’s “Visual Studio Code” trademarks. [github](https://github.com/microsoft/vscode/blob/main/README.md)
2. **Extension marketplace strategy:**
   - Decide:
     - Use Open VSX as the default gallery, or
     - Run your own extension gallery, or
     - Ship with a curated set of bundled extensions and no marketplace.
   - Configure `extensionsGallery` in `product.json` accordingly. [docs.jfrog](https://docs.jfrog.com/artifactory/docs/ai-editor-extension-repositories)
3. **Packaging for macOS:**
   - Use VS Code’s gulp tasks:
     ```bash
     npm run gulp vscode-darwin-arm64
     ```
   - This produces a `.app` bundle for Apple Silicon. [github](https://github.com/microsoft/vscode/wiki/How-to-Contribute)
4. **Testing:**
   - Validate:
     - Build/install on clean macOS machines.
     - Extension loading and updates.
     - AI panel stability under load.
   - Add basic smoke tests (launch, open folder, run an agent command).

**Deliverables:**

- Branded “AgentCode.app” for macOS.
- Installer or DMG for distribution.
- Documentation for users (install, configure API keys, add projects).

***

## Technical notes & constraints

- **Building on macOS:**
  - You must have Xcode Command Line Tools and a working `clang`/`make` toolchain. [github](https://github.com/microsoft/vscode/wiki/How-to-Contribute)
  - Node must match the architecture (ARM64 for M1/M2/M3). [github](https://github.com/microsoft/vscode/wiki/How-to-Contribute)
- **Extensions in forks:**
  - Official marketplace ToS limits use to Microsoft‑branded VS Code; forks typically use Open VSX or private galleries. [github](https://github.com/microsoft/vscode/wiki/How-to-Contribute)
  - Claude Code and Codex extensions currently document support for “compatible forks,” so they should work if your extension host APIs are standard. 
- **Layout enforcement:**
  - VS Code doesn’t officially support arbitrary multi‑column layouts out of the box; you’ll rely on:
    - Custom CSS (potentially fragile across upstream updates).
    - Careful use of view containers and editor group settings.
  - Expect some rebasing work when you sync with upstream `microsoft/vscode`. [github](https://github.com/microsoft/vscode/wiki/How-to-Contribute)

***

## Suggested repo structure

- `XYZHQ/` – fork of `microsoft/vscode`
- `extensions/agentcode-layout/` – layout + project selector + Kanban integration
- `extensions/agentcode-ai-panels/` – reusable agent webview + wrappers for Claude/Codex/CommandCode/DeepSeek
- `build/` – scripts for packaging macOS builds
- `docs/` – build instructions, architecture notes, and user guide

***

If you want, the next step can be a concrete scaffold: a minimal `package.json` for the layout extension, example `product.json` changes, and a starter webview template for an agent panel.