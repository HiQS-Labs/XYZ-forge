# ARCHITECTURE/ — generated diagrams

**Nothing in this folder is hand-written. Do not hand-edit the `.json` or the `.html`.**

Every pair here is produced by the **`swe-diagram`** skill
([`skills/swe-diagram/SKILL.md`](../skills/swe-diagram/SKILL.md), implementation under
[`utils/swe-diagram/`](../utils/swe-diagram/)). The `.json` is the spec you edit; the `.html` is a
self-contained, dependency-free interactive render of it — pan, zoom, drag, search, filter, and it
follows the OS light/dark theme. Editing the HTML directly means your change is gone the next time
anyone rebuilds.

## What is here

| Diagram | Layout | What it is for |
| --- | --- | --- |
| `system-diagram` | `layered` | The default left→right map of the multi-agent coordination system |
| `system-diagram-top-down` | `top-down` | The same system, stacked vertically — fits a narrower page |
| `system-diagram-hub` | `hub-ring` | `relay-lib` at the centre, everything else on a ring — reads as event-driven rather than as a pipeline |
| `system-diagram-trust-clustered` | `trust-clustered` | Bands by **trust tier** rather than call direction, so the containment core reads as the hub it is |
| `git-history-diagram` | `git-lanes` | Commits, branch cuts and merges as stacked branch lanes, generated from local refs |
| `ledger-diagram` | `layered` | `releases.db`, the four views derived from it, the adoption gate, and the push guard that reads the renderer's stderr |

The four `system-diagram*` files are deliberately **the same graph under different layouts** — pick
the one that makes the point you are making. `git-history-diagram` and `ledger-diagram` are
different graphs entirely: the first is Git ancestry, the second is the releases ledger subsystem.

## Rebuilding one

Edit the `.json`, then rebuild its HTML:

```bash
bash utils/swe-diagram/assets/build-diagram.sh ARCHITECTURE/<name>.json
```

That inlines `utils/swe-diagram/assets/renderer.js` and the spec into the template. Regenerate the
Git-history diagram from refs instead of editing it by hand:

```bash
node utils/swe-diagram/scripts/git-history-to-json.js --repo . --limit 20 \
  --output ARCHITECTURE/git-history-diagram.json
bash utils/swe-diagram/assets/build-diagram.sh ARCHITECTURE/git-history-diagram.json
```

## Adding a new one

Invoke the skill (`/swe-diagram`, or ask for "a diagram of X") rather than copying an existing JSON.
It works down a ladder of already-rendered knowledge — graphify output, the codebase-memory graph,
ask-self RAG, then the written docs — before it reads any source, and records what it used in the
spec's `sources` field so the diagram is auditable. A hand-copied spec skips that and silently
inherits the wrong `sources`.

## Checking a spec

The builder fails on invalid JSON but not on graph semantics — an edge whose `source` or `target`
names no node is dropped by the renderer *silently*, so a spec can ship a picture quietly missing a
relationship. Run the validator before you commit:

```bash
node utils/swe-diagram/scripts/validate-spec.js ARCHITECTURE/*.json
```

It reports **errors** (dangling edge endpoints, duplicate node ids, nodes in an undeclared group,
unknown layout, an unresolvable `hub` or `lane`) and exits non-zero on any of them. **Warnings** —
an unknown node `type` or edge `kind` that will fall back to a default, an empty group, a node with
no edges, and the node-count band below — never fail the run.

`test/swe-diagram.sh` runs it over every committed spec here, with red controls proving each error
class actually fails. So a dangling edge cannot reach `development`; the manual check is now the
belt, not the braces.

- **Node count.** Aim for 8–25. Past that the layout stops being readable and the diagram stops
  being a map. The four `system-diagram*` files sit at 31 deliberately — hence a warning, not an
  error.

## The prose counterpart

Narrative architecture lives in [`../ARCHITECTURE.md`](../ARCHITECTURE.md), including mermaid
diagrams for flows small enough to read inline (the relay turn lifecycle, the ledger's derived views
and the push guard). Use a mermaid block there when the picture is a handful of nodes explaining one
mechanism in context; use this folder when it is a system map worth panning around.
