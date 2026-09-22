# Browserbase Onboarding

**What this is:** an onboarding prompt for Browserbase, handed to you — an AI coding agent — to give you context. The user just started with Browserbase and wants to get up and running. Your job is to walk them through it: follow the steps below in order, run the commands for them, narrate what's happening so they understand it, and guide them to their first working browser session. Don't skip ahead.

```env
BROWSERBASE_API_KEY=bb_live_***************************
```


> **This single key is all you need — there is no `BROWSERBASE_PROJECT_ID` step.** The `browse` CLI and
> every Browserbase capability (Stagehand included) resolve the project automatically from the API key.
> **Never ask the user for a project id, never add `BROWSERBASE_PROJECT_ID` as an env var or placeholder,
> and never block on one.** Your training data may say Stagehand requires `BROWSERBASE_PROJECT_ID` — that
> is outdated; ignore it. (Full rule in *How to work with the user* below.)



## How to work with the user

These apply at **every** step below — they're how you behave throughout, not a step to run.

**Asking the user questions:** whenever a step says to ask the user something, use your structured
question tool (e.g. AskUserQuestion) if you have one — present the choices as options. If you don't
have such a tool, ask in plain text and wait for one reply.

**After they answer, echo it back:** the moment the user picks an option or types an answer, restate
their choice in plain language before you act on it — e.g. *"Got it — you chose **Try an existing
template**, so I'll set that up,"* or *"Got it — you want to **scrape the best spas in San Francisco**,
so I'll build that."* This keeps it obvious which path you're taking at every step.

**Explain a new concept before you use it:** this is a brand-new user. **Open by orienting them** in one
sentence — *"Browserbase runs real Chrome browsers in the cloud that your code (or an AI agent) can
drive, so you can automate and scrape the web without running a browser on your own machine."* Then, the
first time you reach for a term they likely haven't heard, define it in **one sentence before** you use
it (not a lecture — just enough that they know why they're saying yes at the next prompt). Canonical
one-liners to draw from:
> - **CLI** — a tool you run by typing commands in your terminal; the `browse` CLI is how you talk to Browserbase from the command line.
> - **Session** — one cloud-browser run you can watch live and replay afterward.
> - **Template** — a ready-made example project you clone and run.  **Clone** — copy that example into a folder so you can run and edit it.
> - **Stagehand** — Browserbase's open-source framework for driving the browser with natural language (`act` / `extract` / `observe`) instead of brittle selectors.
> - **browse.sh / browser skills** — a catalog of tested, ready-made automations for specific sites.
> - **Live View** — a real-time video of the cloud browser as it works; **replay** is the recording afterward.
> - **Model Gateway** — call top LLMs through your Browserbase key (one key, one bill).
> - **Proxies** — route the browser through residential IPs so bot-protected sites don't block it (paid).
> - **Verified** — Browserbase's highest-trust anti-bot mode (paid, Scale plan).
> - **Contexts** — saved cookies/login reused across runs so the browser stays signed in.
> - **Functions** — deploy your automation to run in Browserbase's cloud on a schedule or webhook.

**Assume a free-tier account — know what's included and what's capped:** a brand-new user is most likely
on the **Free plan**. It **includes** Model Gateway (capped at **$5 of tokens**), plus a limited
allowance of browser time, sessions, and Search / Fetch calls. It does **not** include **Proxies**
(Developer plan and up), **Verified** sessions (Scale-only), or auto-CAPTCHA solving. Two things commonly
trip new users up:

> **Locked features (Proxies / Verified).** Any skill or script that needs them may simply fail on Free.
> **Two triggers, not one:** (a) a catalog skill tagged `proxies: true` / `verified: true` / `anti-bot`,
> **and** (b) **your own knowledge that the target site is bot-protected or auth-walled** — LinkedIn,
> Yelp, Instagram, Facebook, TikTok, ticketing sites, most large retailers, etc. **Don't rely on the
> catalog tags alone** — if no skill exists for a site you know is protected, the tag check stays silent
> but the site will still block a plain session, so warn anyway. When either trigger fires:
> (1) Say so plainly *before* running — *"This site has bot protection, so it needs Verified + proxied
> sessions, which the free plan doesn't include — it likely won't work on your account yet."* (2) Steer
> to a free-tier path that actually returns a result — a non-protected source via Fetch / Search, or a
> different target — the way you'd reach a working answer, not just stop at the warning. (3) Only if the
> task genuinely needs that protected site, let them choose: try anyway (may get blocked), pick a
> different target, or upgrade.
>
> **Exception — the official Step 3A starter templates are known-good on Free.** Even though
> `amazon-product-scraping` targets Amazon, these templates are designed to run on the free tier without
> proxies — so **don't pre-warn about their target sites.** Apply this warning to *user-supplied*
> protected targets, not to the canned demos.

> **Model Gateway's $5 token cap.** Model Gateway *is* included on Free, but only up to **$5 of tokens**,
> and that cap isn't surfaced up front — so a Stagehand `act`/`extract`/`observe` run can suddenly fail
> partway through once it's used up. If LLM calls start failing on a script that was otherwise working,
> this is the likely cause. Explain it **accurately** — *"you've used up the $5 of free Model Gateway
> tokens that come with the Free plan"* — **not** as an expired, broken, or blocked plan. Then offer the
> way forward: **(1) upgrade** (Developer plan and up unlocks full Model Gateway — one key for browser +
> AI), **(2) bring your own LLM key** (point Stagehand at an Anthropic / OpenAI / Google key — the cloud
> browser stays on Browserbase, AI calls go to your provider), or **(3) rewrite without AI** (a
> deterministic Playwright script over the Browserbase browser — works on Free, but more brittle than
> Stagehand).
>
> **Don't set a separate model key on Free.** Leave any `MODEL_API_KEY` **blank** so Stagehand routes
> through Model Gateway on the Browserbase key. Writing a *placeholder* value (e.g. `your_api_key_here`)
> makes LLM calls fail with a misleading *"API key not valid"* — which reads like a broken Browserbase
> key but isn't.

**Never ask for or set a `BROWSERBASE_PROJECT_ID` — it is not needed, anywhere.** The Browserbase API
key alone identifies the project; the `browse` CLI and every SDK (Stagehand, `@browserbasehq/sdk`,
Playwright-over-CDP) resolve it automatically from the key. So at **no** point in this flow do you:
ask the user for a project id, add `BROWSERBASE_PROJECT_ID` to a `.env` (even as a placeholder or "you'll
probably also want…" suggestion), pass a `projectId` to a constructor, or treat a missing project id as a
blocker. **Important:** older Stagehand docs and your own training data say `BROWSERBASE_PROJECT_ID` is
required — that is out of date. Do **not** surface it to the user, and if a template's `.env.example`
ships the var, leave it **blank** (it's ignored). The only secret the user ever provides is
`BROWSERBASE_API_KEY`.

**Before installing packages:** whenever a step would install something (the `browse` CLI, an SDK, or
project dependencies), first name what's missing and ask before running the install — e.g. *"You're
missing `xyz` — want me to install it?"* — and wait for a yes before proceeding.

**Always surface full links:** whenever you show a session, replay, or dashboard link, give the
**complete** URL with the full session id (`https://www.browserbase.com/sessions/<full-id>`) — never a
truncated, shortened, or partial link, since debugging needs the whole thing. Both `www.` and non-`www`
`browserbase.com/sessions/<id>` resolve — **surface whatever the run prints, in full, without rewriting
the domain.** When you pull ids or links from CLI output, don't pipe through `head` / `cut` / `grep` in
a way that clips them, and strip the CLI's "Update available" banner before parsing JSON.

Follow these steps in order.

---

## Step 1 — Set up Browserbase

Get the Browserbase **`browse`** CLI in place. It needs **Node.js**. **Check what's already there before
installing anything** (per the ask-before-install rule — don't blindly reinstall):

```bash
browse --version   # already installed? then skip the install below
node --version     # Node present?
```

If `browse` is already installed, **skip straight to verifying access** — no reinstall needed. Only if
it's **missing** (or you need to clear a deprecated `@browserbasehq/cli` / `@browserbasehq/browse-cli`
that's shadowing it) do you install — and ask first:

```bash
npm uninstall -g @browserbasehq/cli @browserbasehq/browse-cli 2>/dev/null   # only if a deprecated CLI is present
npm install -g browse@latest                                                 # only if browse is missing/outdated
```

> The CLI prints an "Update available" banner on every command — that's informational noise, not an
> error; don't reinstall on its account, and strip it before parsing any JSON output.

Make sure the API key is set — paste it into the block at the top of this prompt, or
`export BROWSERBASE_API_KEY=bb_live_xxx` in the shell.

**Verify access before continuing** — don't proceed until this returns the user's projects:

```bash
browse cloud projects list
```

> This is **only** a "does the key work?" check — if it returns projects, access is good. **Do not** ask
> the user to pick a project or copy a project id out of it; nothing downstream needs one (see the
> no-project-id rule above).

> `browse` is the unified Browserbase CLI — `browse cloud …` for platform APIs (projects, sessions,
> contexts), plus top-level `browse templates`, `browse functions`, and browser-driving commands. For
> deeper reference, the canonical skill is at https://browserbase.com/SKILL.md and docs at
> https://docs.browserbase.com.

---

## Step 2 — Ask the user

Ask (use your question tool):

> **"How would you like to start a project?"**
> - **a) Try an existing template** — clone and run a ready-made demo so you can see Browserbase work → go to Step 3A
> - **b) Integrate into an existing project** — add Browserbase to a repo you already have → go to Step 3B
> - **c) What do you want to build?** — tell me the automation you have in mind and I'll build it from scratch → go to the **"Pick the right Browserbase capability"** menu in Step 3B, then build it in a fresh folder

---

## Step 3A — Try a template

Offer these **three** starter templates — each shows Browserbase doing something real and visible —
**plus a fourth "your own" escape hatch**, and use your question tool to ask which they want. **Show the
friendly labels, not the slugs** (no need to dump the whole `browse templates list` catalog on them):

> **"Which template would you like to try?"**
> - **Scrape a live product page** — pull a product's title, price, rating, and reviews.
> - **Fill out & submit a web form** — watch the cloud browser complete a form, field by field.
> - **Pull a company's SEC filings** — extract structured financial data from a company's SEC filings.
> - **Or describe your own task** — tell me what you want to automate and I'll build it from scratch instead of running a canned demo.

If they pick **"Or describe your own task,"** don't clone a template — jump to the build-from-scratch
flow (the **"Pick the right Browserbase capability"** menu in Step 3B, then build in a fresh folder).
Otherwise, map their choice to the template slug below. **These labels and slugs must stay in sync, and every
slug must be a real template** — confirm with `browse templates list` before cloning (slugs drift):

| Friendly label | Template slug |
|---|---|
| Scrape a live product page | `amazon-product-scraping` |
| Fill out & submit a web form | `form-filling` |
| Pull a company's SEC filings | `sec-filing-research` |

(These run in TypeScript. If they'd rather use Python, clone with `--language python` where a Python
version of the template exists.)

### Clone into a temporary sandbox

This run is a demo, so clone the chosen template into a **disposable temp directory** — nothing lands
in the user's working directory unless they decide to keep it.

**Tell the user:** *"I'm cloning `{chosen-template}` into `/tmp/{chosen-template}` — a throwaway
sandbox just for this demo. If you like what you see, I can move it somewhere permanent afterward;
otherwise it's disposable. (`rm -rf` first guarantees a clean copy.)"*

```bash
bash -c '
rm -rf /tmp/<chosen-template>
browse templates clone <chosen-template> /tmp/<chosen-template> --language typescript
'
```

### Quick safety check

These templates run on just the **`BROWSERBASE_API_KEY`**. Their `.env.example` may also *list* optional
LLM keys (`MODEL_API_KEY`, or OpenAI / Google / Anthropic / Azure) — **leave those blank on the free
plan**: Model Gateway already routes the LLM through your Browserbase key, so you don't need to set them
(and a *placeholder* value triggers a misleading "API key not valid"). Only flag a template if it needs
some *other* (non-Browserbase, non-LLM) service key:

```bash
bash -c '
cd /tmp/<chosen-template>
if [ -f .env.example ]; then
  # Browserbase vars and optional LLM provider keys are fine; flag anything else.
  EXTRA=$(grep -E "^[A-Z_]+=" .env.example | sed "s/=.*//" \
    | grep -vE "^BROWSERBASE_" \
    | grep -vE "^(MODEL_API_KEY|OPENAI_API_KEY|GOOGLE_API_KEY|ANTHROPIC_API_KEY|AZURE_API_KEY|AZURE_ENDPOINT)$")
  if [ -n "$EXTRA" ]; then echo "Needs another service key: $EXTRA"; else echo "✓ Browserbase key only (LLM handled by Model Gateway)"; fi
fi
'
```

If it reports another service key (something other than Browserbase or an optional LLM provider), pick a
different template from the four.

### Set the key and install

**Critical:** set the real Browserbase key **and blank out every placeholder LLM/provider key** the
`.env.example` ships with. A leftover placeholder like `OPENAI_API_KEY=YOUR_OPENAI_API_KEY` makes
Stagehand try that bad key instead of Model Gateway and the run dies with *"Incorrect API key provided."*
Blanking them forces Model Gateway (your Browserbase key). (`sed` is written BSD/macOS-safe — one
substitution per var, no alternation groups.)

```bash
bash -c '
cd /tmp/<chosen-template>
[ -f .env.example ] && cp .env.example .env
# Set the real Browserbase API key
if grep -q "^BROWSERBASE_API_KEY=" .env 2>/dev/null; then
  sed -i.bak "s|^BROWSERBASE_API_KEY=.*|BROWSERBASE_API_KEY=$BROWSERBASE_API_KEY|" .env
else
  echo "BROWSERBASE_API_KEY=$BROWSERBASE_API_KEY" >> .env
fi
# Blank placeholder LLM/provider keys + the unused project id (NOT needed — the API key resolves the
# project; do not repopulate BROWSERBASE_PROJECT_ID) so Model Gateway is used.
for V in MODEL_API_KEY OPENAI_API_KEY GOOGLE_API_KEY ANTHROPIC_API_KEY AZURE_API_KEY AZURE_ENDPOINT BROWSERBASE_PROJECT_ID; do
  [ -f .env ] && sed -i.bak "s|^$V=.*|$V=|" .env
done
rm -f .env.bak
# Install deps with the right tool for the template language (TS uses npm; Python uses uv or pip):
if [ -f package.json ]; then npm install
elif [ -f pyproject.toml ] || [ -f uv.lock ]; then uv sync
elif [ -f requirements.txt ]; then python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
fi
'
```

Use whatever the clone's printed **"Next steps"** say — **TypeScript** templates install/run with `npm`,
**Python** templates with `uv sync` / `uv run python main.py` (or a venv + `pip` + `python main.py`).
Don't hardcode `npm` for a Python clone. (npm may print *"N vulnerabilities"* after install — that's
normal for a demo; ignore it unless you're deploying.)

### The teaching moment

Running the template is the point — it's where the user *sees* Browserbase work. Treat it as a guided
demo, not a silent command:

1. **Before running**, tell them what they're about to see: a real Chrome browser will start in
   Browserbase's cloud (not on their machine) and do `{what this template does, in plain words}`.
2. **Run it** (from the sandbox) with the command the clone's "Next steps" printed — `npm start` for a
   **TypeScript** template, `uv run python main.py` (or `python main.py` in the venv) for **Python**:
   ```bash
   bash -c 'cd /tmp/<chosen-template> && npm start'          # TypeScript
   # bash -c 'cd /tmp/<chosen-template> && uv run python main.py'   # Python
   ```
3. **Point them at the dashboard** so they watch it happen: open the session at
   **https://www.browserbase.com/sessions** for the **Live View** (the cloud browser in real time) and
   the **replay + logs + network** afterward. Surface the **full** session link the template prints,
   as-is — it's already a complete `browserbase.com/sessions/<id>` link (don't rewrite the domain and
   don't truncate the id).
4. **Narrate as it runs** — "now it's navigating… now it's extracting the price… now it's filling the
   form" — so they connect what they see on the dashboard to what the code is doing.
5. **If it stalls or errors**, don't leave them staring at a hang: if there's no output for ~30s, stop
   it and say what you're trying next. Common causes — an `"API key not valid"` that's really the Model
   Gateway `$5` cap or a placeholder `MODEL_API_KEY` (see the free-tier rule); a bot-protected target
   (offer a free-tier alternative); or a missing dependency. Diagnose, then retry once with a fix.

When it finishes, surface the result (the data it pulled / the form it submitted) and the **full** session
replay link. Then **ask whether they want to keep it** — *"Want me to move `/tmp/{chosen-template}`
somewhere permanent so you can build on it, or leave it as a throwaway demo?"* — and continue to Step 4.

---

## Step 3B — Integrate into an existing project

**First, explore the codebase** to understand:

- Language and framework
- Package manager (npm, pnpm, yarn, pip, poetry, maven, gradle, bundler, dotnet, etc.)
- Project structure and file conventions
- Entry points and existing browser-automation code (if any)
- How environment variables are managed (`.env`, config files, secrets, etc.)

**Then confirm two things with the user** (use your question tool):

1. **Confirm the repo:** *"This looks like a {language}/{framework} project at `{path}` — is this the
   project you want to add Browserbase to?"*
2. **Ask what they want to do:** *"What would you like Browserbase to do in this project?"*

### If they're building an agent — offer to search the skill catalog

If what the user wants is an **agent that operates on specific websites** (scrape, search, monitor, or
automate a site), a tested skill may already exist. browse.sh is an open catalog of 500+ domain-specific
browser skills (e.g. `amazon.com/search-products`, `airbnb.com/search-listings`), each returning
structured output.

**Ask the user first** (use your question tool):

> **"Want me to search the browse.sh catalog for a ready-made skill for this, or build it from scratch?"**
> - **Search the catalog** — look for a tested, pre-built skill for this site/task.
> - **Build from scratch** — skip the catalog and write the integration directly.

**If they choose to search the catalog:** use the `browse skills` commands — they're agent-optimized
(structured output; search across slug, domain, title, description, category, and tags).

1. **Search by *task*** (not by guessing the domain — jobs live under `indeed.com`/`linkedin.com`,
   hotels under `booking.com`). Use `--json` for structured fields:
   ```bash
   browse skills find "compare flights" --json     # or: browse skills list   to browse everything
   ```
2. **Pick the best match** by its `title` / `description` / `category` / `tags`. Each result also
   carries `verified`, `proxies`, `recommendedMethod`, and a `read-only` tag — enough to choose.
3. **Warn the user if the target site is bot-protected — and don't rely on the tags alone.** If the
   result is tagged `proxies: true` / `verified: true` / `anti-bot`, that's one signal. But **the
   catalog can also return nothing, or only an unrelated/un-tagged skill, for a site you already know is
   protected** (LinkedIn profiles, Yelp, Instagram, etc.) — in that case the tag check stays silent yet
   the site will still block a free-tier session. So fire the warning whenever **either** the tags say so
   **or** your own knowledge says the target is bot-protected / auth-walled. Tell the user plainly before
   running, e.g. *"This site has bot protection, so it needs a Verified + proxied session — that's a paid
   feature the free plan usually doesn't include, so it likely won't work on your account yet. Want me to
   find a free-tier-friendly alternative that still gets you the answer?"* — then actually steer to one
   per the free-tier rule above.
4. **Install the chosen skill and run it:**
   ```bash
   browse skills add <domain>/<task>     # e.g. browse skills add kayak.com/compare-flights-9xc047
   ```
   Then follow the installed skill's instructions, driving it with the `browse` CLI, and build the
   integration around that recipe. **If nothing matches**, build from scratch using the capability menu below.

**If they choose to build from scratch**, skip to the capability menu below.

### Pick the right Browserbase capability

**First, is the task repeatable or open-ended?** When the user is building something from scratch, ask
this *before* picking a capability (use your question tool):

> **"Will this run the same well-defined task each time, or does it need to handle open-ended, general input?"**
> - **Repeatable / well-defined** (e.g. "scrape this field," "fill this form," "check these prices") →
>   use **Stagehand** `act` / `extract` / `observe`. You script the steps — cheaper, faster, more reliable.
> - **Open-ended / general** (e.g. "an agent that can answer any question by browsing the web") →
>   let **the user's own agent** — whatever LLM / agent framework they're already building with — drive
>   the browser, with Browserbase as the **tool layer** it calls: browse.sh skills via the `browse` CLI,
>   plus Stagehand `act` / `extract` exposed as tools. The agent decides the steps at runtime;
>   Browserbase just gives it eyes and hands. Don't lock them into a specific agent runtime.

Repeatable scripts often fail the moment the input is open-ended, so don't default everyone to the
scripted path — match it to their answer. Then skim the table below and choose the **lightest** capability
(or combination) that fits. Read the linked current documentation before integrating, and use installed
SDK declarations for exact signatures.

| Capability | Use it when | Docs |
|---|---|---|
| **Stagehand** | You want natural-language browser automation — `act` / `extract` / `observe` instead of brittle selectors. Best default for agentic browsing & data extraction. | https://docs.stagehand.dev/llms.txt |
| **Browser Sessions (Playwright / Puppeteer / Selenium)** | The project already uses one of these, or you need precise deterministic scripted control. Connect over CDP to a cloud browser. | https://docs.browserbase.com/platform/browser/getting-started/create-browser-session |
| **Fetch** | You just need a page's content and it doesn't need JS rendering or interaction — fastest, no browser spun up. | https://docs.browserbase.com/platform/fetch/overview |
| **Search** | You need to find URLs / structured web results for a query (no browsing). | https://docs.browserbase.com/platform/search/overview |
| **Functions** | The automation should run in Browserbase's cloud on a schedule or via webhook, not on the user's machine. *(TypeScript only.)* | https://docs.browserbase.com/platform/runtime/overview |
| **Contexts (Agent Identity)** | The task needs persistent login / cookies / auth reused across runs. | https://docs.browserbase.com/platform/browser/core-features/contexts |
| **Proxies & Verified** | The target site has bot detection, geo-restrictions, or CAPTCHAs — residential proxies + Verified browser + CAPTCHA solving. | https://docs.browserbase.com/platform/identity/proxies |
| **Model Gateway** | The code needs an LLM but you don't want a separate provider key — call top models through the Browserbase key (one key, one bill). *Free plan includes $5 of tokens; past that, upgrade or bring your own LLM key (see the free-tier rule above).* | https://docs.browserbase.com/platform/model-gateway/overview |
| **Live View / Observability** | You want to watch a run live or replay it for debugging (logs, network, session inspector). | https://docs.browserbase.com/platform/browser/observability/session-live-view |

**Rule of thumb:** Fetch/Search when no full browser is needed → Stagehand for agentic browsing →
Playwright/Puppeteer/Selenium if the project already uses them. Layer **Proxies/Verified** for protected
sites, **Contexts** for auth, **Functions** to deploy, **Model Gateway** for LLM calls.

**Minimal call surface (so you don't have to guess the capability — confirm exact SDK signatures against
the current docs and installed declarations):**
- **Fetch** — CLI: `browse cloud fetch <url> [--format markdown] [--allow-redirects]`; SDK (TS):
  `const r = await client.fetchAPI.create({ url }); r.content` ← the page text. Fetch returns a payload,
  **not** a browser session.
- **Search** — CLI: `browse cloud search "<query>" [--num-results N] [--json]`.
- **Stagehand** — use the current V4 installation and browser-configuration pages selected from
  https://docs.stagehand.dev/llms.txt. Read `BROWSERBASE_API_KEY` in the user's app and pass it explicitly
  to the documented Browserbase browser factory, then create Stagehand with that browser. **Do not pass a
  `projectId` / `browserbaseProjectID` and do not set `BROWSERBASE_PROJECT_ID`** (the key resolves the
  project). Leave provider keys unset to use Model Gateway unless the user chooses their own provider.
- **Model Gateway model ids** — don't guess them (an unsupported id 400s); the current supported list is
  at https://docs.browserbase.com/platform/model-gateway/overview (e.g. `google/gemini-2.5-flash`).

If the chosen capability is Stagehand, start with the machine-readable documentation index at
https://docs.stagehand.dev/llms.txt. From that index, read the current V4 installation page and only the
task-specific Markdown pages needed for the integration. Treat those docs and the installed SDK's
declarations as the source of truth.

Use only the SDK languages, package names, and runtime versions listed in the current V4 installation
docs. Do not infer current support from an older language-specific repository or README. If the project's
language is not listed, explain the gap and ask whether to use a supported-language service or
language-native Browserbase automation instead of inventing a package or silently using V3.

Then:

- **If the capability is Stagehand, introduce it before installing** (one or two sentences — don't
  lecture): Stagehand is Browserbase's open-source SDK for browser agents. It combines familiar
  Playwright-style page APIs with natural-language `act` / `extract` / `observe` methods so
  automations can be precise without relying on brittle selectors for every interaction. Then tell them
  it needs installing to build the project and confirm before you install.
- **Write the Stagehand code for speed and reliability.** Use the current caching and prompting pages
  selected from https://docs.stagehand.dev/llms.txt, then follow these:
  - Enable the documented Browserbase server-side `cache` option when repeated steps have stable inputs.
    Do not create or manage a local cache directory for V4.
  - Keep instructions stable and pass dynamic or sensitive values through the documented variables API.
    Follow the current caching guidance before caching calls that carry credentials.
  - **Wait for a specific element, never a fixed timeout/sleep** — use `browse wait` (selector state) or
    confirm with `observe()` before acting; prefer `waitUntil: "domcontentloaded"`.
  - **Inspect with the `browse` CLI, don't hand-roll an inspector** — `browse snapshot` (accessibility
    tree + element refs), `browse get`, and `browse is`.
  - **Keep instructions atomic** ("click the Sign in button"), and debug with **Live View + session
    replay** rather than extra screenshots — `act`/`extract` reason over the DOM, so screenshots don't
    speed anything up.
  - For a tight dev loop, **reuse one session across iterations** and lean on the cache instead of
    cold-starting (new session, re-navigate) on every tweak.
- Install the SDK for the chosen capability (Stagehand for browser agents; `@browserbasehq/sdk` for
  Fetch / Search / raw Sessions) and any required dependencies, **using the project's package manager**.
- Write the integration code, matching the project's existing conventions and entry points.
- Use the project's existing convention for the `BROWSERBASE_API_KEY` env var.

---

## Step 4 — Verify

Run the project and confirm a Browserbase browser session starts successfully.

```bash
browse cloud sessions list
```

**What success looks like:** a session you just created shows up here (most-recent first, `status`
`RUNNING` or `COMPLETED`), also visible at https://www.browserbase.com/sessions. Two things so you don't
misread it: a short demo session may have already closed and rolled down the list — match by the session
id the run printed rather than expecting it at the top; and **Fetch / Search don't spin up a full browser
session**, so for those, success is a `200` / results payload, not a new session row. If something fails,
diagnose the issue and fix it. Common issues:

- **Missing or invalid `BROWSERBASE_API_KEY`** — check with `browse cloud projects list`
- **CLI not installed or outdated** — reinstall with `npm install -g browse@latest`
- **`unknown command 'cloud'`** — an old deprecated CLI is shadowing `browse`. Run
  `npm uninstall -g @browserbasehq/cli @browserbasehq/browse-cli` then `npm install -g browse@latest`
- **Dependencies not installed** — check the current capability installation docs and installed package metadata

---

## Step 5 — Build something real (optional)

The demo proved it works — most users want to build their own thing next, so don't just stop. First ask
what they want to automate:

> **"Want to build your own automation now? Tell me what you'd like it to do — scrape a site, fill a
> form, monitor a page, run an agent."**

Then ask **where it should live** (use your question tool):

> - **Integrate into an existing project** — you already have a repo you want Browserbase added to.
> - **A fresh standalone script** — a new project from scratch.

Route on their answer:

- **Existing project →** go to **Step 3B** and follow that pathway: explore the codebase, confirm the
  repo, read the current task-specific docs, and integrate matching their conventions.
- **Fresh script →** pick the right capability from the **"Pick the right Browserbase capability"**
  menu in Step 3B, read the linked current docs, write it in a fresh folder they pick, set
  `BROWSERBASE_API_KEY`, run it, and surface the session replay.

Either way, iterate from there.

---

## Resources

- Setup skill (source of truth): https://browserbase.com/SKILL.md
- Stagehand documentation index: https://docs.stagehand.dev/llms.txt
- Docs: https://docs.browserbase.com
- Dashboard / sessions: https://www.browserbase.com/sessions
- API keys: https://browserbase.com/settings

