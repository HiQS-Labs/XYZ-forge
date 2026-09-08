---
title: "GH-491: roadmap move/update --section advertises names the renderer drops, and validates nothing"
status: active
created: 2026-09-07
updated: 2026-09-07
owner: orchestrator (Claude Code)
goal: the CLI cannot write a section the renderer will not render, and its help names the section vocabulary that actually exists
gh_issue: 491
source: https://github.com/HiQS-Labs/XYZ-forge/issues/491
branch: fix/gh491-roadmap-section-validation
doc_type: bugfix
marathon: 497
lane: A
related: [GH-492, GH-355, GH-474, GH-269]
context_tags: [releases, roadmap, cli, validation]
effort: 2
complexity: 2
risk: 2
---

## Status

| What was just completed | What's next |
|---|---|
| Filed with a reproduction; the markdown-vs-database naming split identified in a follow-up comment | Lane A of marathon #497 — wave 2, after #355 lands |

## The problem, in one run

```bash
$ python3 utils/py/releases_app.py roadmap move --issue-num 123 --section 'Deferred / cancelled'
updated GH-123

$ bash utils/roadmap-dashboard.sh
roadmap-dashboard: warning: dropped 1 row(s) under unrecognised section heading(s) "Deferred / cancelled": #123
```

The row is still in the ledger. It is simply absent from the view — and invisible to drift
detection, because a row that renders to nothing leaves the committed file byte-identical to a
fresh render, so `--check` exits 0. Only GH-474's stderr signal catches it.

## Why the wrong name looks right

`utils/py/wave_reconcile.py:472-473` keeps two vocabularies on purpose:

```python
target_section_md = "### Completed" if is_merged else "### Deferred / cancelled"
target_section_db = "Completed"     if is_merged else "Deferred · vision"
```

`Deferred / cancelled` is the **ROADMAP.md heading**; `Deferred · vision` is the **roadmap_items
section**. The `--help` at `utils/py/releases_app.py:4999` quotes the markdown name at a flag that
writes the database one, and `:4993` quotes a bare `Deferred` that is neither. So this is not a
typo a user invents — it is one the tooling supplies.

## The renderer's actual vocabulary

`utils/roadmap-dashboard.sh:97`:

```js
const ledgerSections = [
  "Queue / parked intake",
  "Queue",              // GH-243: early `releases roadmap add` rows parked under the short name
  "In progress",
  "Completed",
  "Deferred · vision",
];
```

## Plan

1. Correct all three strings (`releases_app.py:3375`, `:4993`, `:4999`) to real database sections.
2. Move `ledgerSections` to one source both the CLI and the renderer read, so the two cannot drift
   apart again. This is the seam lane B depends on — a sweep validating against a second copy of
   the list reintroduces exactly the drift this lane closes.
3. Refuse an unknown `--section`. When the value is a known **markdown-side** name, say so and name
   the database equivalent, rather than emitting a bare "unknown section" that leaves the user
   guessing between two plausible names.

## Acceptance

- [ ] `roadmap move --section 'Deferred / cancelled'` is refused, and the message names `Deferred · vision` specifically.
- [ ] `roadmap move --section 'Completed'` still succeeds unchanged.
- [ ] A test asserts the CLI's accepted set matches `ledgerSections` in `utils/roadmap-dashboard.sh`, so a future edit to either side fails loudly.
- [ ] Red control: the pre-fix behaviour (verbatim write of an unknown section) is pinned as failing.

## Acceptance — deviations from the issue

- [changed] `roadmap move --section 'Deferred / cancelled'` is refused, naming the valid sections. -> `roadmap move --section 'Deferred / cancelled'` is refused, and the message names `Deferred · vision` specifically. — reason: the follow-up comment on #491 established that a bare "unknown section" message leaves the user guessing between two plausible names; the refusal must name the database equivalent, not just reject.
- [added] `roadmap move --section 'Completed'` still succeeds unchanged. — reason: a validator that only proves the bad case is refused, without a regression check that the good case still works, can pass while silently breaking normal use.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "path_absent", "path": "test/gh491-roadmap-section-validation.sh" },
                     { "type": "grep_present", "path": "utils/py/releases_app.py", "pattern": "Deferred / cancelled" } ],
  "artifacts":     [ "utils/py/releases_app.py", "utils/roadmap-dashboard.sh", "test/gh491-roadmap-section-validation.sh" ],
  "artifacts_new": [ "test/gh491-roadmap-section-validation.sh" ],
  "remediation":   { "source": "self#plan", "criteria": "an unrecognised --section is refused naming the database equivalent; the CLI's accepted set and the renderer's ledgerSections are asserted equal by a test" },
  "lanes":         { "agy_safe": [ "utils/py/releases_app.py", "utils/roadmap-dashboard.sh", "test/gh491-roadmap-section-validation.sh" ], "orchestrator_only": [ "validate.sh" ] }
}
```

The `grep_present` probe is bug-evidence, and it is directional: `Deferred / cancelled` is in
`releases_app.py` today, so the probe reads `unfixed` now and flips to `landed` the moment the
string is corrected. Verified against the live tree before this doc was committed.
