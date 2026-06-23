# RELAY · Claude Code CRUD (Skill-first) plan — design review
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions, and don't look for the artifact on disk: **it is embedded inline in Setup below** (the plan lives in a different repo, so review the embedded copy).
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (see Roles) **and** the last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact embedded in Setup:
   - **Reviewer (codex):** review the embedded plan against the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete proposed fix and a `plan §<section>` pointer → set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit any file other than THIS relay file; you only append findings here.
   - **Producer (claude-a):** for every open finding log a disposition (Implemented / Modified / Declined + why); the real edits land on the plan file in the other repo, outside this relay.
4. **Append ONE block** at the very bottom, directly **above** the marker line (`<!-- ↓↓↓ NEXT TURN ... -->`). Never edit earlier turns. Header it `### Round N · <Role> · <your-label> · <date time>`; a Reviewer block carries `**Verdict:**` + `**Findings & proposals:**` (graded bullets) + `**Commit:**`.
5. **Update the header:** flip `NEXT` to the other role; set `STATUS` (`Approved` closes the relay — Reviewer only; else leave `Open`).
6. **Token + commit:** use `./bin/tick` for the `RELAY-MCP-CRUD` token (claim/ping, then `release --to claude-a`, or `done` + set `STATUS: Approved` when approving). The harness makes the one file-scoped commit for you — **never run git yourself.**
7. **Stop.** Tell the operator your one-line result.

## Setup
- **Artifact under review (embedded):** Noel's **"Claude Code CRUD for Text Replacement Studio (Skill-first)"** plan — a proposal-stage `PROJECT/1-INBOX` doc (not code) for letting Claude Code CRUD macOS text replacements. It was just rewritten (after a `/ponytail` laziness pass) so **Phase 0 is a Skill-only path over existing tooling**, with the MCP-server / HTTP-API / adapter stack demoted to deferred "future possibilities."
- **Context the plan relies on (assume true; flag if a claim looks unsupported):**
  - `trstudio` CLI already ships `list / add / import / export / apply / lint / backup`; `apply` previews by default and writes only with `--apply`/`--write`, taking a timestamped backup first.
  - `scripts/native_to_json.py` reads the live DB → canonical JSON; `scripts/json_to_apple_sqlite.py` writes JSON → live DB (`--strategy merge|replace`, `--apply`, backup-first); `scripts/lint_replacements.py` validates.
  - The live macOS DB at `~/Library/KeyboardServices/TextReplacements.db` is the system of record.
- **Definition of Done — judge the plan on:**
  - **(a) Right-sizing / YAGNI:** is Phase 0 genuinely the laziest path that still works, or is anything in it still over-built — or, conversely, under-specified so it wouldn't actually work? Is the deferral of MCP/API/adapter correctly gated (only when a non-shell MCP client needs it)?
  - **(b) Safety / trust boundary:** are the safety rules (lint → preview → backup, steer to `merge`) sufficient to protect the user's live database? What failure mode is unguarded? Is the `replace`-deletes-missing-shortcuts warning prominent and correct?
  - **(c) Correctness of the recipe:** does the read→edit-JSON→lint→preview→apply loop actually achieve full CRUD (esp. update & delete via JSON editing + strategy)? Any wrong flag, path, or step? Is `repl.json`'s location / lifecycle / the DB-path argument specified enough for an agent to run it deterministically?
  - **(d) PDDA-contract conformance for a `1-INBOX` proposal:** minimum frontmatter present; correctly carries **no** `## Status` table while in `1-INBOX`; repo-relative paths only (the `~/Library/...` runtime path is acceptable); promotion checklist sound.
  - **(e) Missing load-bearing detail:** anything the Skill needs to work that's absent — idempotency, how Claude resolves the DB path, concurrency with the open GUI app, what `repl.json` is seeded from, or a missing risk.
- **Producer:** Noel (owner), represented by the orchestrator (claude-a)  ·  **Reviewer:** codex
- **Handoff:** cli-driven (codex)  <!-- driven by relay-automation/relay-drive.sh + codex-turn.sh -->
- **Started:** 2026-06-23

## Ground rules
1. This file is the single source of truth. The agents are different tools (Claude and Codex) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`/`STATUS` at the top.
4. Stay tight. Findings are graded bullets, not essays.
5. **The Reviewer (codex) never edits the artifact** — it only appends graded findings with concrete fixes to THIS file (the artifact lives in another repo anyway).
6. Grade every finding: `[Blocker]` must fix · `[Should]` strong rec · `[Nit]` optional · `[Pass]` checked + sound.
7. The Reviewer posts a Verdict. Relay ends on **Approved**; else the orchestrator carries findings back to the Producer.
8. The token `RELAY-MCP-CRUD` is the lock. No push.
9. **Evidence:** this is a *planning* doc — prefer `textual` reasoning, citing the embedded plan by `§section`/line and the Context facts above.

## Roles
- **Producer** — Noel (owner), applied by the orchestrator (claude-a). Applies the Reviewer's findings to the plan file between rounds (in the other repo).
- **Reviewer** — codex. Reviews against the DoD, proposes graded findings, sets a verdict. Never edits the artifact.

---
## Log

### Round 1 · Producer · claude-a (on Noel's behalf) · 2026-06-23
**Did:** Scaffolded this relay to design-review the Skill-first CRUD plan (below). The plan was just lazified: Phase 0 ships a single Claude Skill that drives CRUD via the *existing* `trstudio` CLI + Python scripts (read with `native_to_json.py`, edit a JSON snapshot, `lint` → dry-run `preview` → `--apply`), with the MCP-server/HTTP-API/adapter stack explicitly deferred to "future possibilities" gated on non-shell MCP clients.
**Review this:** Apply the DoD in Setup. Most interested in: (a) is Phase 0 the right lazy size, or still over/under-built? (b) is the lint→preview→backup trust boundary to the live DB sufficient? (c) does the JSON-edit recipe actually deliver update + delete correctly and safely? (d) PDDA conformance for a `1-INBOX` doc; (e) any missing load-bearing detail (repl.json lifecycle, DB-path resolution, GUI concurrency).
**Verification:** N/A from the producer side — this is a review request.
**Embedded artifact (the plan, verbatim):**

`````markdown
---
title: Claude Code CRUD for Text Replacement Studio (Skill-first)
status: Proposed (1-INBOX — not yet active)
doc_type: project
created: 2026-06-23
updated: 2026-06-23
owner: noel
goal: >
  Let Claude Code Create/Read/Update/Delete macOS text replacements with zero new
  runtime code, by shipping a Skill that drives the existing trstudio CLI + Python
  scripts. The MCP server / adapter / HTTP API stack is deferred until a non-shell
  MCP client actually needs it.
related:
  - macOS/Sources/TextReplacementCLI
  - macOS/Sources/TextReplacementCore
  - scripts/native_to_json.py
  - scripts/json_to_apple_sqlite.py
  - scripts/lint_replacements.py
  - AGENTS.md
  - PROJECT/PDDA.md
non_goals:
  - New runtime services (HTTP server, MCP server) for the Claude Code use case
  - Re-porting the Apple Core Data write logic out of the Python scripts
  - Remote/networked access
---

# Claude Code CRUD for Text Replacement Studio (Skill-first)

> **Lifecycle note.** Proposal in `PROJECT/1-INBOX`, so per `PROJECT/PDDA.md` it carries
> **no `## Status` table** yet. On promotion to `PROJECT/2-WORKING/` add: the exact status
> table, the Phase 0 QA-gate sign-off, and a one-line `ROADMAP.md` pointer. See the
> **Promotion checklist** at the end.

## 1. Summary

Claude Code can already run shells and edit files, and `trstudio` already ships
`list / add / import / export / apply / lint / backup` (apply does preview + a timestamped
backup via the reviewed `scripts/json_to_apple_sqlite.py`). So the shippable deliverable is
**one Skill file** that teaches Claude the safe CRUD recipe over those existing tools —
**no new runtime code**.

The MCP server, adapter, and HTTP API from the earlier draft are kept, but **demoted to
future possibilities** (Section 4): they only earn their place if an MCP client that *can't
run a local shell* (Claude Desktop, the web app, ChatGPT) needs CRUD access.

## 2. Why / use cases

- "Add a `/sig` snippet with my signature." → create, preview, apply.
- "Update every replacement pointing at the old Zoom link." → read, edit, apply.
- "Disable my casual `brb`/`omw` snippets." → update `enabled`.
- "What duplicate shortcuts do I have?" → read + lint.

## 3. Phase 0 — Claude Code Skill (ship this)

The whole feature is: operate on a **throwaway JSON snapshot** and promote it with the
existing apply script. The live macOS DB stays the only store; there is no second store and
therefore no concurrency/authority problem to manage.

### 3.1 What already exists (reuse, write nothing)

- `trstudio` subcommands: `list`, `add`, `import`, `export`, `apply`, `lint`, `backup`
  (`macOS/Sources/TextReplacementCLI/main.swift`).
- `scripts/native_to_json.py` — live DB → canonical JSON (read-only).
- `scripts/json_to_apple_sqlite.py` — canonical JSON → live DB; dry-run by default,
  `--apply` writes after a timestamped backup; `--strategy merge|replace`.
- `scripts/lint_replacements.py` / `trstudio lint` — validation.

### 3.2 The recipe the Skill documents

```text
Read     python3 scripts/native_to_json.py --db ~/Library/KeyboardServices/TextReplacements.db -o repl.json
Create   edit repl.json (add an item)            # or: trstudio add ...
Update   edit repl.json (change shortcut/phrase/enabled/group/notes)
Delete   edit repl.json (drop the item)          # removed on apply with --strategy replace
Lint     python3 scripts/lint_replacements.py repl.json
Preview  python3 scripts/json_to_apple_sqlite.py repl.json --db <db> --strategy merge
Apply    python3 scripts/json_to_apple_sqlite.py repl.json --db <db> --strategy merge --apply
```

CRUD is just editing the JSON snapshot; `merge` adds/updates, `replace` also deletes
shortcuts missing from the JSON. The canonical `keyboard-replacements.v1` shape and field
names come from `macOS/Sources/TextReplacementCore/Codecs/CanonicalReplacementCodec.swift`.

### 3.3 The deliverable

`.claude/skills/text-replacements/SKILL.md`, with:

- **Frontmatter:** name + description with trigger hints ("manage my mac text
  replacements / snippets / autocorrect", "add a text expansion", "fix my signature
  snippet").
- **Workflow:** read → edit JSON → **lint → preview → apply**, explaining `merge` vs
  `replace` and the "quit & reopen apps to see changes" caveat.
- **Safety rules (non-negotiable, this is the trust boundary to the live DB):**
  - always `lint` before apply; never apply data with `error`-severity issues (blank
    shortcut/phrase, duplicate shortcut);
  - always run the dry-run **preview** and show the diff before `--apply`;
  - apply writes a backup first (the script does this) — never bypass it;
  - never apply without the user's explicit intent.

### 3.4 QA gate (Phase 0)

- A scripted read → edit (add/update/delete one shortcut each) → lint → preview → apply
  cycle runs against a **temporary copy** of the DB (reuse the gated-e2e pattern already in
  `macOS/Tests/`), asserting the change shows up on re-read and a backup exists.
- The Skill triggers on a representative prompt and, in a dry-run transcript, previews
  before applying and refuses linter-flagged data.

## 4. Future possibilities (deferred — do not build yet)

**Trigger to revisit:** a non-shell MCP client (Claude Desktop, web app, ChatGPT) needs to
CRUD replacements, or multiple clients need a shared, concurrent store. Until then these are
speculative and intentionally unbuilt.

- **A. API endpoint** — `trstudio serve`: a loopback HTTP service over `TextReplacementCore`
  (CRUD + `validate`/`import`/`preview`/`apply`), `127.0.0.1` + bearer-token. Introduces a
  persistent working store and, with it, the authority/concurrency question below.
- **B. Adapter** — a transport-agnostic typed client between the MCP server and the API (a
  seam worth nothing until there is a second transport).
- **C. MCP server** — stdio tools over the adapter for non-shell clients.
- **D. GUI ↔ store reconciliation** — point `StudioModel` at the shared store so the app and
  the bridge stay in sync.

**Authority note (only relevant to A–D).** A persistent API store becomes a *dual-written
peer* against the live DB (the system of record), reintroducing a concurrency problem that
Phase 0 avoids entirely by working on a throwaway snapshot. Classify and design for it
*before* building A.

## 5. Risks & open questions

- **Phase 0:** `trstudio` has `add` but not dedicated `update`/`delete` subcommands — the
  recipe leans on JSON editing for those. Optional ergonomic add-on: 2–3 small subcommands
  (`update`, `delete`, `disable`) reusing `TextReplacementCore`. Not required to ship.
- **`replace` strategy is destructive** (deletes shortcuts missing from the JSON) — the
  Skill must steer to `merge` unless deletion is explicitly intended.
- **Future A–D:** server lifecycle, HTTP dependency, MCP language, auth sufficiency,
  store-vs-GUI concurrency — all deferred with the stack.

## 6. Verification

- `swift test` (incl. the gated Python e2e) stays green.
- From Claude Code: "add a `/sig` snippet … then apply it" yields a previewed diff, a
  backup on disk, and the shortcut present on re-read.

## 7. Promotion checklist (1-INBOX → 2-WORKING)

- [ ] Move to `PROJECT/2-WORKING/MCP-CRUD-BRIDGE.md`.
- [ ] Add the exact `## Status` table (`What was just completed | What's next`).
- [ ] Create `ROADMAP.md` (pointer ledger) and add a one-line pointer.
- [ ] Keep the Phase 0 QA gate; check it off when the Skill ships.
- [ ] Add a `CHANGELOG.md` entry.
- [ ] Run `utils/pdda-run.sh` and clear deterministic findings.
`````

**Open questions:** flag any `[Blocker]` that should stop this from promoting to `2-WORKING` as-is.
**Commit:** (this relay scaffold; the plan is reviewed inline)

### Round 1 · Reviewer · codex · 2026-06-23 13:49 PDT
**Verdict:** Changes requested
**Findings & proposals:**
- [Blocker] The delete path is not actually correct as written: `§3.2` says "Delete = drop the item" but the only concrete preview/apply commands shown use `--strategy merge`, which will not remove missing entries; deletion only happens under `replace`, and `replace` is only safe if the JSON snapshot is a fresh full export of the whole DB. Proposed fix: split the recipe into two explicit flows in `plan §3.2`: create/update use `merge`; delete requires `export fresh full snapshot -> remove target item -> lint -> preview/apply with --strategy replace`, with a bold note that `replace` deletes every shortcut absent from that snapshot.
- [Should] The Phase 0 safety story underprices stale-snapshot clobbering against the live DB, especially for `replace`: `§3` says there is "no concurrency/authority problem," but there is still a window where edits made in System Settings or another app after `native_to_json.py` runs can be overwritten on apply. Proposed fix: add a Phase 0 rule in `§3.3` or `§5` to re-read from the live DB immediately before apply when the editing window was long or when using `replace`, and tell the user to avoid concurrent GUI edits during the run.
- [Should] The recipe is not deterministic enough about the working file and DB path lifecycle for an agent to execute repeatably: `§3.2` mixes a literal `~/Library/...` read command with `<db>` placeholders for preview/apply and leaves `repl.json` as an unspecified cwd artifact. Proposed fix: in `§3.2` define one canonical variable pair, e.g. `DB=~/Library/KeyboardServices/TextReplacements.db` and a repo-local temp snapshot path such as `.tmp/repl.json`, and reuse them in every command; say the snapshot is always seeded from a fresh export, overwritten per run, and disposable after apply.
- [Pass] The plan is otherwise correctly right-sized for `1-INBOX`: `§1`, `§3`, and `§4` keep Phase 0 to a single Skill over existing tooling and defer the MCP/API/adapter stack behind a falsifiable non-shell-client trigger; the frontmatter and lifecycle note also satisfy the stated PDDA constraint of no `## Status` table while still in `PROJECT/1-INBOX`.
**Commit:** Reviewer findings appended to relay only; no artifact/source edits.

### Round 2 · Producer · claude-a (on Noel's behalf) · 2026-06-23
**Dispositions** (all applied to the plan in the other repo, `PROJECT/1-INBOX/MCP-CRUD-BRIDGE.md`):
- `[Blocker]` delete-path correctness → **Implemented.** §3.2 rewritten into two explicit flows. Create/Update use `merge`. Delete now requires a fresh **full** export → remove item(s) → lint → preview/apply with `--strategy replace`, under a bold "⚠️ `replace` deletes every shortcut absent from `$SNAP`" callout. Added "`merge` never deletes."
- `[Should]` stale-snapshot clobbering → **Implemented.** §3 no-longer claims "no concurrency problem" — it now names the stale-snapshot window explicitly. Added a §3.3 safety rule (re-export + re-lint immediately before apply if stale or using `replace`; no concurrent edits) and a §5 risk bullet ("reduced, not eliminated").
- `[Should]` deterministic file/DB lifecycle → **Implemented.** §3.2 now opens with a canonical pair `DB=~/Library/KeyboardServices/TextReplacements.db` and `SNAP=.tmp/repl.json`, reused in every command (no `<db>` placeholders); `$SNAP` declared disposable + overwritten by a fresh export each run.
- `[Pass]` right-sizing / PDDA → acknowledged, no change.

**Verify (revised text, quoted for inline re-review):**
- §3.2 setup: `DB=~/Library/KeyboardServices/TextReplacements.db` · `SNAP=.tmp/repl.json` (disposable; fresh export each run).
- §3.2 Delete: gated on `--strategy replace` over a fresh **full** snapshot + ⚠️ callout; Create/Update stay on `merge`.
- §3.3: "re-export + re-lint `$SNAP` immediately before apply if it is stale or you are using `replace`; don't edit in System Settings or start a second apply mid-run."
- §5: new stale-snapshot risk bullet (reduced, not eliminated).

**Open:** if these resolve the Blocker + both Shoulds, set **Verdict: Approved** + `STATUS: Approved`.
**Commit:** (plan edits live in the fast-key repo; this relay carries the dispositions)

### Round 2 · Reviewer · codex · 2026-06-23 13:55 PDT
**Verdict:** Approved
**Findings & proposals:**
- [Pass] `plan §3.2` now makes the delete contract correct instead of implicit: create/update stay on `merge`, while delete is explicitly routed through a fresh full snapshot plus `--strategy replace`, with the destructive-missing-entries warning called out where the operator will see it.
- [Pass] `plan §3.3` now sizes the real Phase 0 safety boundary correctly: the stale-snapshot window is named, `replace` gets a mandatory re-export/re-lint path, and concurrent GUI edits are explicitly prohibited during the run.
- [Pass] `plan §3.2` is now deterministic enough for a Skill to execute repeatably: one canonical `DB` path, one disposable `SNAP` path, fresh seeding each run, and no lingering `<db>` placeholder ambiguity.
**Commit:** Approval recorded in relay only; no artifact/source edits.

<!-- ↓↓↓ NEXT TURN APPENDS BELOW THIS LINE ↓↓↓ -->
