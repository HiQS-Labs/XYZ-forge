# run-4-adjacent-no-match

Agent id: `afc617333c0f6dce5` · tool calls: 15

## Prompt given (verbatim, local paths replaced)

You are working in the repository at "<verify-clone>". Stay inside that directory for all repository reading; do not read any other checkout of this repository or any memory/notes files outside it. Read-only: do not create, edit or delete any file, do not run tests, do not run git commands that change state. Do not load or invoke any skills through a Skill tool.

The ONE exception to "stay inside": first read this single instruction file in full and follow it exactly as your procedure (read nothing else in its folder or its repository):
"<task-clone>/skills/3-weekly/connect-the-dots/SKILL.md"
Links inside it resolve to the same relative paths inside the repository you are working in.

Search scope for this run: only files tracked by git in the repository you are working in. Exclude from candidates: your own installed tools and skills outside the repository, and the paths relay-system/, PROJECT/, TESTS-RESULTS/, CHANGELOG.md, docs/, releases.db, releases.sql.

The operator asks:

"We need to render PDF invoices with embedded fonts."

Answer the operator by following that procedure. Your final message is the answer itself (max ~400 words), in the output shape the procedure specifies. After the answer, add a short section "Files I actually opened" listing each file path you read (not merely searched), and "Searches I ran" listing the search queries/tools you used.
<context_window_protection>
  <priority_instructions>
    Raw tool output floods context window. MUST use context-mode MCP tools. Keep raw data in sandbox.
  </priority_instructions>

  <tool_selection_hierarchy>
    0. MEMORY: mcp__plugin_context-mode_context-mode__ctx_search(sort: "timeline")
       - After resume, check prior context before asking user.
    1. GATHER: mcp__plugin_context-mode_context-mode__ctx_batch_execute(commands, queries)
       - Primary research tool. Runs commands, auto-indexes, searches. ONE call replaces many steps.
       - Each command: {label: "section header", command: "shell command"}
       - label becomes FTS5 chunk title — descriptive labels improve search.
    2. FOLLOW-UP: mcp__plugin_context-mode_context-mode__ctx_search(queries: ["q1", "q2", ...])
       - All follow-up questions. ONE call, many queries (default relevance mode).
    3. PROCESSING: mcp__plugin_context-mode_context-mode__ctx_execute(language, code) | mcp__plugin_context-mode_context-mode__ctx_execute_file(path, language, code)
       - API calls, log analysis, data processing.
  </tool_selection_hierarchy>

  <forbidden_actions>
    - NO Bash for commands producing >20 lines output.
    - NO Read for analysis — use mcp__plugin_context-mode_context-mode__ctx_execute_file. Read IS correct for files you intend to Edit.
    - NO WebFetch — use mcp__plugin_context-mode_context-mode__ctx_fetch_and_index.
    - Bash ONLY for git/mkdir/rm/mv/navigation.
    - NO mcp__plugin_context-mode_context-mode__ctx_execute or mcp__plugin_context-mode_context-mode__ctx_execute_file for file creation/modification.
      mcp__plugin_context-mode_context-mode__ctx_execute is for analysis, processing, computation only.
  </forbidden_actions>

  <file_writing_policy>
    ALWAYS use native Write/Edit tools for file creation/modification.
    NEVER use mcp__plugin_context-mode_context-mode__ctx_execute, mcp__plugin_context-mode_context-mode__ctx_execute_file, or Bash to write files.
    Applies to all file types: code, configs, plans, specs, YAML, JSON, markdown.
  </file_writing_policy>

  <output_constraints>
    <artifact_policy>
      Write artifacts (code, configs, PRDs) to FILES. NEVER inline.
      Return only: file path + 1-line description.
    </artifact_policy>
  </output_constraints>
  <session_continuity>
    Skills, roles, and decisions set during this session remain active until the user revokes them.
    Do not drop behavioral directives as context grows.
  </session_continuity>

</context_window_protection>

## Final answer (verbatim, local paths replaced)

**Mode:** maps first (`ROUTER.md`, `ARCHITECTURE.md`, `README.md`), then grep over git-tracked files at `5967bde25`. No index was used: codebase-memory has no project rooted at this checkout, and no graphify or `ask_self` output is tracked here.

**Bottom line:** this repo has nothing that produces PDFs or embeds fonts. It is an agent-orchestration harness. The only transferable piece is a pattern for baking records into a single self-contained HTML file.

**Outcome:** a billing record becomes a paginated, print-ready file whose typefaces travel inside it.
**Constraints:** none stated by the operator.

| Capability | Existing module | `file:line` | Owner of the state or lock | Fit | Limiting constraint | Cost or risk to adapt |
|---|---|---|---|---|---|---|
| Fill a fixed layout from structured records | `bake_static()` in the timeline exporter | `utils/timeline/export_timeline.py:506-513` (context 1-50, 516-559) | `releases.db`, opened read-only | pattern only | Injects a JSON blob at one `<!--LEDGER_DATA-->` marker; layout happens in browser JS; payload is ledger-shaped | Copy the approach, not the code |
| Carry typeface data inside the output file | swe-diagram template | `utils/swe-diagram/assets/template.html:12-24, 160-163` | none | not found in these searches | Deliberately the opposite: "No @font-face / network fetch here on purpose", system font stacks only | n/a |
| Convert laid-out pages to a paginated print file | browserbase skill (raw Playwright/CDP session) | `skills/4-occasional/browserbase/SKILL.md:77-101` | external cloud service | not found in these searches | A web-research routing guide; no print or PDF path; sends data to a third party | n/a |
| Compute line totals, tax, currency | — | — | — | not found in these searches | Only hits are test strings in archived marathon output (`evidence/marathons/run-3/.../fuzzy-match.test.js`), not opened | n/a |
| Store and number issued documents | — | — | — | not found in these searches | — | n/a |

**Composition:** none. No existing owner carries any capability; the one `pattern only` row is a ten-line idea.

**New remainder:** all of it — the invoice data model, the layout, the PDF engine, font subsetting and embedding, numbering and storage.

**Unknowns:**
- Whether this feature belongs in this repo at all. Nothing in the maps suggests a billing surface; the operator naming the target product would settle it.
- `evidence/marathons/run-*/artefacts/built/src/report.js` was seen by filename only and not opened. It is archived output from a marathon target, not a module of this repo.

**One next action:** `sanity-check` — confirm which repo this feature is for before anything is designed.

## Files I actually opened
All under `<verify-clone>/` except the first:
- `<task-clone>/skills/3-weekly/connect-the-dots/SKILL.md` (full)
- `utils/timeline/export_timeline.py` (lines 1-50, 500-559)
- `utils/swe-diagram/assets/template.html` (lines 1-30, 154-169)
- `skills/4-occasional/browserbase/SKILL.md` (lines 76-105)

`ROUTER.md`, `ARCHITECTURE.md` and `README.md` were searched, not read.

## Searches I ran
- `git ls-files` piped to `rg -i 'pdf|font|invoice|render|template|typeset|latex|html|report|export|billing|receipt'`, and `rg -i '\.(woff2?|ttf|otf|pdf)$'` (no font or PDF files tracked).
- `rg -n -i` on the three maps for `pdf|font|invoice|render|typeset|glyph|pandoc|weasyprint|reportlab|wkhtml|latex|html|billing|document generat|export` (17 hits, all in `ARCHITECTURE.md`).
- `git grep -i` over in-scope tracked files for:
  - `pdf`: 0 files, confirmed with `git ls-files | xargs rg -l -i pdf`.
  - `weasyprint|reportlab|wkhtmltopdf|pdfkit|puppeteer|playwright|page\.pdf|printToPDF|pandoc|xelatex|pdflatex|fpdf|typst|pdf-lib|jspdf`
  - `@font-face|woff|\.ttf|\.otf|fonts\.googleapis|font-family`
  - `invoice|line items?|billing|subtotal|amount due`
  - `chromium|headless|puppeteer|playwright`
- `mcp__codebase-memory-mcp__list_projects` (both pages, 86 projects).
