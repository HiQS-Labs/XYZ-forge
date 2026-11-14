# Manual check receipt: GH-1468 baseline skill

Run on 2026-11-14 in a fresh full clone at base `e0586fc30`, macOS, system `python3` 3.9.6.
No new test suite was added (GH-831); this file is the recorded manual check.

## Observed results

| Check | Command | Observed | Verdict |
|---|---|---|---|
| CI route | `git diff --cached --name-only origin/development \| bash utils/ci-route.sh pull_request` | `route=docs`, `tier=1`, `tier_reason=docs-only` | PASS |
| PDDA gate | `bash utils/pdda/pdda.sh run` | `PDDA run complete: no errors, 105 warning(s) to review` (exit 0); no line names GH-1468 or baseline | PASS |
| Deploy tests | `python3 -m unittest test/test_deploy_skills.py` | `Ran 34 tests in 20.362s` `OK` | PASS |
| Ledger | `python3 utils/py/releases_app.py check` | `check: clean (0 failures, 10 warning(s))` | PASS |
| Frontmatter | YAML parse of `skills/3-weekly/baseline/SKILL.md` | `name=baseline`, description 947 characters | PASS |
| Builder, example spec | `build_deck.py assets/example-spec.json --out <scratch>` | `wrote ... (3 items, 10 slides)`, exit 0 | PASS |
| Not-ignored output | build to a path git does not ignore | prints `warning: ... is not git-ignored`; an ignored `temp/` path prints no warning | PASS |

## Red controls (each must be refused)

Each case is the example spec with one mutation, run with `build_deck.py --check`.

| Case | Mutation | Observed | Verdict |
|---|---|---|---|
| a | an item's question holds three questions | exit 2: `items[0].question: exactly one question, ending in '?'` | PASS |
| b | a `fix` ask whose only evidence is `unverified` | exit 2: `'fix' needs at least one confirmed or partly-confirmed claim` | PASS |
| c | a 400-character `event` | exit 2: `400 characters, the slide holds 320` | PASS |
| d | a `confirmed` claim with no `ref` | exit 2: `items[2].evidence[0].ref: required` | PASS |

Two controls that must be accepted:

| Case | Mutation | Observed | Verdict |
|---|---|---|---|
| e | summary set to `</script><script>alert(1)</script>` | exit 0; the raw string occurs 0 times in the output, `<` escapes as `\u003c`, and `json.loads` parses the exact original string | PASS |
| f | case b with the ask type changed to `decide` | exit 0: `spec ok` (a ruling request does not need a confirmed claim) | PASS |
| g | title and summary both contain the literal template markers `__DECK_DATA__` and `__DECK_TITLE__` | exit 0; the markers stay as text in `<title>` and in the data, the data block parses, and the page has 2 `<script` tags | PASS |
| h | `heard.summary` set to `<!-- quoted comment -->` | exit 0; raw `<!--` occurs 0 times inside `#deck-data`; `json.loads` and headless Chrome DOM round-trip `<!-- quoted comment -->` | PASS |
| i | headless Chrome DOM click probe on built `example.html` (all 6 item answers set, `heard` unset, then `heard` set) | `7 of 7 questions still open.` initially; `1 of 7 questions still open.` after item answers only; `Every question has an answer. This is the baseline.` after `heard` | PASS |
| j | mutate `items[0].ask.text` (same title/date/item list) vs identical rebuild | `spec.id` changes on mutated ask (`08de8fbbb20a` != `c474c38a84d4`); identical rebuild keeps `c474c38a84d4` | PASS |

## Rendering

Checked from headless Chrome screenshots at 1280x800, 1280x720 and 1440x900, light and dark, and
from headless Chrome `--dump-dom` probes of slide construction, completion counting, comment round-trip,
and `#next` navigation (`10` slides, `1` active, `7` question blocks, `3` summary rows).

## Not verified

- Clipboard copy button (`navigator.clipboard` / `execCommand`) and `localStorage` persistence across page reloads under an interactive browser session (`file://` headless probe exercised in-memory clicks).
- The skill run by a model other than the author's session.
- Independent Codex review: driven via `relay-xyz` in `relay-system/2026-11-14/gh1468-final.codex.md` on this branch.

Clone identity (`HEAD`, `core.bare`, `origin`) was the same before and after the runs.
