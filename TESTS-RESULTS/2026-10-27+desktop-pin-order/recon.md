# Claude Desktop pinned-section order: can a tool set it? (recon, 2026-10-27)

Question (cross-project tasks tracker, issue 58, "Claude Desktop pinned-section order"): can the
task-sync Desktop sweep move recently active sessions to the top of the sidebar's Pinned section?
Method: `/debug-mantra` + `/recon`, read only. Nothing under `~/Library/Application Support/Claude`
was edited; the only writes were three `set_pinned` calls on the investigating session itself
(pin, unpin, pin, then unpin to restore), never on a pin the operator made.
Sanitized: pinned sessions are `P0`…`P8` in stored order, the investigating session is `<self>`;
no titles, session ids, account or org ids appear here. App: Claude Desktop 4.29.0, macOS 24.6,
bundled Claude Code 2.1.309. Telemetry: `provenance.jsonl` beside this file.

## Verdict

**Not settable through any supported tool, and not sorted by activity.** The Pinned section's
order is an explicit, app-wide list that only the sidebar's own UI writes (drag and drop, the
row menu's *Move up* / *Move down*, and undo). `set_pinned` only adds to or removes from the
pin *set*; it never touches the order list. Unpinning and re-pinning through the tool does not
move a session to the top: a pin that is not in the order list sorts **below** every listed
one. The only non-UI way to change the order is hand-editing an app config file, which is
unsupported and out of bounds for the sweeper. No "recent pins to top" step can be added to
task-sync until the app exposes an order argument.

| Hypothesis | Result | Evidence |
|---|---|---|
| H1 no supported tool sets pin order | **Holds** | Every `ccd_sidebar` and `ccd_session_mgmt` schema read: `set_pinned(session_id, pinned)` only; `move_sessions` files into groups and unpins on the way; `set_view(section_id, sort_by)` exists but the renderer's handler for a section only records the setting (`setSectionView`), and the Pinned list sorts by the order list first (see H4). No tool has an order, position or index argument. |
| H2 Pinned already sorts by last activity | **Falsified (code, stored state, and operator's eye)** | Stored order `P0…P8` vs activity order `P8,P0,P1,P2,P5,P4,P3,P6,P7` vs creation order `P8,P0,P5,P4,P7,P3,P1,P6,P2`: no match. The renderer sorts pinned rows by index in the order list; activity is at most a tie-break for rows absent from it. Operator read the sidebar on 2026-10-27: `P0` at the top and `P8` at the bottom, as stored; activity order would have put `P7` and `P8` on top. |
| H3 order is pin time | **Falsified** | No pin timestamp anywhere: the 120 session records carry no pin field at all (0 of 120 contain `pinned`). Live test on `<self>`: pin → appended to the pin set, order list unchanged (9 → 9); unpin → removed from the set; pin again → appended again, order list still unchanged. Re-pinning cannot move a row to the top. |
| H4 order lives in an app-wide list | **Holds** | `claude_desktop_config.json` → `preferences.epitaxyPrefs["dframe-local-slice"].pinnedOrder` (9 strings `code:<session id>`) is the order; `preferences.epitaxyPrefs["starred-local-code-sessions"]` (9 ids, same set) is the pin set. The app rewrites the file within a second of each `set_pinned` (mtime moved on every call). Session records, `Local Storage`, `IndexedDB` hold only mirrors or hints (`seenDragPinHint`). |

## Where the order lives (Lane B: state)

| Store | Key | Role | Written by |
|---|---|---|---|
| `~/Library/Application Support/Claude/claude_desktop_config.json` | `preferences.epitaxyPrefs["starred-local-code-sessions"]` (list) | the pin set | `set_pinned` (MCP), row menu Pin/Unpin, drag |
| same file | `preferences.epitaxyPrefs["dframe-local-slice"].pinnedOrder` (list of `code:<id>`) | the pin order | drag, Move up/down, undo, and family-pin bookkeeping only |
| same file | `preferences.epitaxyPrefs["dframe-code-sections"].<acct/org>.sections[].sortBy` | per-section sort setting | `set_view`; recorded for Pinned, consumed for Sessions |
| `claude-code-sessions/<acct>/<org>/local_<id>.json` | (none) | no pin field at all | — |
| `Local Storage/leveldb` | `pinnedOrder`, `code.pinned`, `seenDragPinHint` | mirrors / row counts / drag-hint flag | renderer |

The `homeProjectsPinnedOrder` sibling is the Cowork home-projects list, not sessions.

## How the sidebar orders the section (Lane A: call path, from the cached claude.ai renderer bundle)

Minified, read from the Electron HTTP cache (`Cache/Cache_Data`, bundles served from
`assets-proxy.anthropic.com/claude-ai/v2/assets/v1/shared-*.js`). The app.asar holds only the
main-process MCP shim; the sidebar is a web bundle.

1. Sort: `AH(rows, pinnedOrder, comparator, filter)` builds `Map(key → index)` from `pinnedOrder`
   and sorts with `oh`: equal indices fall to `comparator`, otherwise `(i ?? Infinity) - (a ?? Infinity)`.
   A row missing from `pinnedOrder` gets `Infinity`, so it sinks below every listed row.
2. Write: `du(action, orderedKeys, pinnedOrder)` is the single writer. It first appends any
   displayed-but-unlisted key at the end (in displayed order), then applies the action:
   `pin` with an explicit `at` (only from a drop slot or undo), `unpin` (filter out),
   `reorder {from,to}` (drag or the row menu's Move up / Move down, `source:"menu"`), `pinBlock`
   (multi-select drop). This is why all nine operator pins are listed: the first drag froze the
   displayed order into the file.
3. MCP: the renderer's sidebar op handler maps `SetPinned` to `x6(ctx, sessionId, pinned)`, which
   compares the current star and toggles it (`source:"mcp"`). No order write. `SetView` with a
   `section_id` goes to `Fo`, which calls `setSectionView(id, {groupBy, sortBy})` and returns;
   the Pinned section records the value, the comparator for the pinned list is a separate import.
4. Rows: Code session rows receive a `pinReorder` prop, so Move up / Move down is offered on
   pinned Code sessions, not only routines.

## Step N+1 downstream checks

- Consumer hop: `set_pinned` writes the star set; the Pinned list consumer selects by star and
  orders by `pinnedOrder`. A tool-pinned row is displayed, at the bottom. No stranded state.
- Retry hop: n/a (no scheduled consumer; the config write is synchronous, mtime moved each call).
- Parameter role: `set_view(sort_by)` on the Pinned section is a recorded setting, not an order generator.
- Rollout/rollback: the three `set_pinned` calls on `<self>` were reversed; final state equals the
  initial state (pin set 9, order list 9, `<self>` in neither).

## Unknowns

| Unknown | Why it matters | What would settle it |
|---|---|---|
| The comparator used for ties among rows absent from `pinnedOrder` (import `nJ` of a shared chunk; export not resolved in the cached copy) | Decides how several tool-pinned rows order among themselves at the bottom (recency is the likely default) | Pin two sessions through the tool and read the sidebar, or resolve the export in an un-minified build |
| Whether the app ever rewrites `pinnedOrder` without a UI action (e.g. a later version materializing tool pins) | Would change where tool pins land after a restart | Re-run `probe` after an app update |

## Breadcrumb ledger (mantra 4)

| # | Run | Observed | Ruled in / out |
|---|---|---|---|
| 1 | Read all 18 sidebar/session tool schemas | no order/position argument anywhere; `set_view` has `section_id`+`sort_by`, "Pinned only records them" | H1 holds, one lead to check |
| 2 | `list_sections` | Pinned: `sort_by recency`, `order 0` | sort setting exists, applied? (see 10) |
| 3 | Read-only probe (operator's script) | session records: no pin key; config: `pinnedOrder` list + `sortBy` per section; leveldb: `pinnedOrder`, `seenDragPinHint` | H3 timestamp theory out; H4 candidate found |
| 4 | Compare `pinnedOrder` to `starred-local-code-sessions` | identical 9-member sets; sequence matches neither activity nor creation order | explicit order; H2 out on stored state |
| 5 | `set_pinned(<self>, true)` then read config | star set 9 → 10 (`<self>` last); `pinnedOrder` 9, unchanged; mtime moved | tool writes the set only |
| 6 | Re-read after 20 s | unchanged | not a lazy write |
| 7 | app.asar scan | 0 hits for `pinnedOrder`; MCP tool names present | renderer is the web bundle |
| 8 | Cache bundle scan | `AH`/`oh`/`du`/`yV` found; sort by list index, Infinity for unlisted | mechanism fixed |
| 9 | `set_pinned(<self>, false)` then read | star set back to 9; `pinnedOrder` unchanged | unpin removes from set only |
| 10 | `x6`, `Fo` handlers read | SetPinned toggles star; SetView records `sortBy` per section | H1 lead closed |
| 11 | `set_pinned(<self>, true)`, read, `set_pinned(<self>, false)`, read | appended last again; order list never changed; final state equals initial | re-pin cannot move to top; restored |
| 12 | `pinReorder` prop trace | passed to Code session rows; Move up/down menu | UI reorder exists, menu + drag only |
| 13 | Operator reads the Pinned section top to bottom | top row is `P0`, bottom row is `P8`, matching `pinnedOrder` | H2 closed by eye; stored list is the sidebar's source |

Root cause statement: the pin order is a renderer-owned, drag-maintained list persisted in the app
config; the MCP sidebar surface exposes the pin set but not the list. Fix site, if any: the
app's `set_pinned` schema (an `at`/`position` argument) or a new `move_pin` op. Not in XYZ-forge.

## Implication for task-sync (deliverable 4)

No supported path exists, so no "recent pins to top" step is proposed. The Desktop procedure stays
add-only. If Anthropic later adds a position argument to `set_pinned` (or a reorder op), the step
would be: after step 6's `set_pinned`, re-read `list_sessions`, and for rows pinned by the sweep
with activity inside `--pin-hours`, move them to index 0 in activity order; never move a pin the
sweep did not make. Until then the only levers are the operator's own drag or Move up / Move down.
