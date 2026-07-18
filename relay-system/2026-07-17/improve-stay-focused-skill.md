# RELAY · Improve stay-focused skill
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-17.
-->

NEXT: done
STATUS: Approved
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(improve-stay-focused-skill): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: the **stay-focused** skill in the `giant-brains-claude-skills` repo (this relay runs with `--target-root` pointed at that repo, so all paths below are readable in your worktree):
  - `04-build/stay-focused/SKILL.md` — the skill definition + reply-format spec + examples (primary)
  - `04-build/stay-focused/HOOKS.md` — always-on hook docs (install/use/cost)
  - `04-build/stay-focused/hooks/focus-config.js` — flag-file helpers (sanitize/read/write, symlink-hardened)
  - `04-build/stay-focused/hooks/focus-tracker.js` — UserPromptSubmit hook: set/clear anchor, per-turn reminder
  - `04-build/stay-focused/hooks/focus-activate.js` — SessionStart hook: inject ruleset
  - `04-build/stay-focused/hooks/focus-ruleset.md` — the injected ruleset ({{ANCHOR}} placeholder)
  - `04-build/stay-focused/hooks/install.sh` — settings.json merge/uninstall
- What the skill does: locks a session to ONE anchor task; every reply leads with that task's live status over a `---` rule, then a tight rabbit-hole-style body (What's Shipped / What's Blocked / Recommended / Optional / Only Useful FYIs), minimum-viable text, empty buckets dropped. Set via "stay focused on <task>"; hooks re-inject the anchor every turn. It is a sibling of `04-build/rabbit-hole/` (same hook architecture) — compare against that for consistency.
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-17
- Definition of Done — grade the skill against these, propose concrete fixes:
  1. **Correctness** — the tracker's set/off/affirm regexes match the phrasings the SKILL/HOOKS advertise and don't misfire (e.g. does a bare "stop" ever clear the anchor? does a question set an anchor? does an off-phrase get captured as a task?). Flag any behavioral gap between docs and code with a `file:line` citation.
  2. **Robustness/safety** — flag-file sanitize/read/write path is symlink-safe, size-capped, and can't inject forged context lines; hooks silent-fail and exit 0 on every path; no way to leave the guard in an inconsistent state.
  3. **Prompt/format quality** — the injected ruleset + per-turn reminder actually produce the reply shape the user asked for (status-first, `---` rule, named buckets, minimum text) without being wasteful or ambiguous; the two sources (ruleset vs reminder) don't contradict each other.
  4. **Doc accuracy** — SKILL.md description triggers, HOOKS.md commands, and cost figures match the code's real behavior; examples are faithful.
  5. **Sibling consistency** — divergences from rabbit-hole's hook pattern are intentional and sound (the anchor-as-payload change), not accidental drift.
  Out of scope: renaming files, adding new features beyond the described behavior, or restructuring the repo.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### agy (Reviewer)

VERDICT: FAIL
Basis: Questions can hijack the anchor, punctuation breaks no-anchor prompt, and replacement patterns mangle anchor text.

- `[Blocker]` **Correctness:** Questions can unintentionally set the anchor. In `focus-tracker.js:112-113`, `extractTask` is called unconditionally on every prompt. If a user asks "why are we staying focused on the old PR?", `isQuestion` is true (bypassing the off-checks), but `extractTask` still runs, matches `SET_PATTERNS`, and sets the anchor to "the old PR". **Fix:** Guard the `extractTask` block with `if (!isQuestion)`.
- `[Should]` **Correctness:** The `bareAffirm` regex in `focus-tracker.js:133` tests against `norm` (which retains trailing punctuation) but anchors with `\s*$`. A user typing `"stay focused."` (with a period) will fail the match and won't trigger the no-anchor prompt. **Fix:** Add optional punctuation before the end anchor, e.g. `(focused|focussed|on\s+track)[.!?\s]*$`.
- `[Should]` **Robustness/safety:** In `focus-config.js:179`, `buildRuleset` uses `tmpl.replace(/\{\{ANCHOR\}\}/g, anchor)`. If the user's anchor text contains special replacement patterns like `$&` or `$1` (e.g. "fix the $100 bug"), `String.prototype.replace` will interpret them, mangling the injected anchor. **Fix:** Pass a replacer function instead: `tmpl.replace(/\{\{ANCHOR\}\}/g, () => anchor || '(none set — ask the user what to stay focused on)')`.
- `[Nit]` **Robustness/safety:** In `focus-config.js:60`, `collapsed.slice(0, MAX_FLAG_BYTES)` slices the anchor by UTF-16 code units, but `readRaw` (`focus-config.js:133`) checks the length in bytes (`st.size > MAX_FLAG_BYTES`). An anchor dense with multi-byte characters could be under 512 chars but over 512 bytes, causing `safeWriteFlag` to save it but `readRaw` to silently reject it. **Fix:** Cap the write length by bytes (e.g., using `Buffer.byteLength`) or increase the check in `readRaw` to `MAX_FLAG_BYTES * 4`.
- `[Nit]` **Prompt/format quality:** In `focus-tracker.js:26`, the reminder prompt includes an em-dash immediately after the colon: `**Status of ${anchor}:** — one honest line`. This contradicts the example in `SKILL.md:94` and `focus-ruleset.md:14`, and might cause the model to output `**Status of X:** — In progress`. **Fix:** Remove the em-dash after the colon in `focus-tracker.js`.
- `[Pass]` **Sibling consistency:** The symlink-hardened flag read/write logic in `focus-config.js:69` and `focus-config.js:121` perfectly matches the `caveman` pattern used in `rabbit-hole`, ensuring safe execution.
- `[Pass]` **Doc accuracy:** The cost estimation bounds in `HOOKS.md:106` (1,970 chars for SessionStart, 750 chars for reminder) accurately reflect the built payload sizes of `focus-ruleset.md` and `focus-tracker.js`.

### claude-a (Producer) — r1

DISPOSITION: all 7 findings addressed. 4 implemented as proposed, 1 blocker implemented with a modified (more surgical) fix, 2 `[Pass]` acknowledged. All changes verified with targeted regression tests.

- `[Blocker]` Correctness (questions hijack anchor) — **Modified.** Agy's proposed `if (!isQuestion)` guard would have broken an *advertised & tested* phrasing: "can we stay focused on X?" starts with "can", so `isQuestion` is true, and the anchor would never set. Instead I closed the actual hijack vector two ways: (1) dropped the `(?:ing)?` from the `stay`/`stay on track` SET_PATTERNS (`focus-tracker.js:38-39`) — the gerund "staying" only appears in descriptive/interrogative sentences, never an imperative; and (2) added a **wh-question guard** (`focus-tracker.js:117-121`): `why|what|when|where|who|whose|how|which` prefixes skip the set, while polite requests (`can/could/let's/please …`) still set. Verified: "why are we staying focused on the old PR?" now **preserves** the existing anchor; "can we stay focused on fixing login?" / "please stay focused on the migration" still set correctly.
- `[Should]` Correctness (bareAffirm punctuation) — **Implemented.** Both bareAffirm alternatives now end `[.!?\s]*$` instead of `\s*$` (`focus-tracker.js:136-137`). Verified: "stay focused." (trailing period) now fires the no-anchor prompt.
- `[Should]` Robustness (`buildRuleset` `$&`/`$1` mangling) — **Implemented.** `buildRuleset` now replaces with a function `() => fill` rather than a literal string (`focus-config.js:184-188`). Verified: anchor "fix the $100 bug and $& handler" injects **verbatim** into the ruleset.
- `[Nit]` Robustness (byte vs char cap) — **Implemented.** `sanitizeAnchor` now trims whole chars until `Buffer.byteLength(out) <= MAX_FLAG_BYTES` (`focus-config.js:57-62`), so a multi-byte-dense anchor can't be written-then-rejected-on-read. Verified: a 300× multibyte anchor writes 510 bytes and reads back non-empty (was silently dropped before).
- `[Nit]` Prompt/format (em-dash after colon) — **Implemented.** Removed the `— ` after the colon in the reminder (`focus-tracker.js:22`) so it matches `SKILL.md` and `focus-ruleset.md`. Verified: reminder no longer contains `:** —`.
- `[Pass]` Sibling consistency — acknowledged, no change.
- `[Pass]` Doc accuracy (cost figures) — acknowledged, no change.

Handing back for a confirmation pass. Same Definition of Done; the 5 fixes above are the only diff since your review.

### agy (Reviewer)

VERDICT: Approved
Basis: All findings have been verified. The modified wh-question guard correctly resolves the anchor-hijack bug without breaking legitimate interrogative set commands, and the remaining implementation details match the proposed fixes exactly.

- `[Pass]` **Correctness:** Verified modified wh-question guard (`focus-tracker.js:121-122`). It correctly prevents descriptive sentences from resetting the anchor while still allowing polite requests.
- `[Pass]` **Correctness:** Verified `bareAffirm` punctuation logic (`focus-tracker.js:141-142`).
- `[Pass]` **Robustness/safety:** Verified `buildRuleset` replacement function (`focus-config.js:189`) which correctly avoids `$1` regex mangling.
- `[Pass]` **Robustness/safety:** Verified `Buffer.byteLength` cap (`focus-config.js:64`) safely aligns writes with reads.
- `[Pass]` **Prompt/format quality:** Verified em-dash removal (`focus-tracker.js:26`) matches example shapes.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
