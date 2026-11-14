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
| e | summary set to `</script><script>alert(1)</script>` | exit 0; the raw string occurs 0 times in the output and the escaped form `<\/script>` once | PASS |
| f | case b with the ask type changed to `decide` | exit 0: `spec ok` (a ruling request does not need a confirmed claim) | PASS |

## Rendering

Checked from headless Chrome screenshots at 1280x800, 1280x720 and 1440x900, light and dark, and
from a DOM dump of the last slide (10 slides, 1 active, 7 question blocks, 3 summary rows).

## Not verified

- Clicking the answer buttons, the saved notes and the Markdown copy button in a live browser.
- The skill run by a model other than the author's session.
- No independent review has run on this change.

Clone identity (`HEAD`, `core.bare`, `origin`) was the same before and after the runs.
