---
gh_issue: 92
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/92
title: "poll.sh: relay-pointer parser rejects whole-line bold (`**NEXT: x**`) → silent turn-1 deadlock"
status: Ready — promoted for Marathon Plan B Wave 1 (2026-07-04)
created: 2026-07-04
updated: 2026-07-04
owner: noel
doc_type: bugfix
goal: >
  Make relay_field/relay_next_agent in relay-automation/poll.sh tolerant of trailing markdown
  (whole-line-bold **NEXT: x**, backtick-wrapped `NEXT: x`) so a naturally-authored relay pointer
  never silently misclassifies a Claude agent as non-Claude and deadlocks the poll loop.
complexity: 1
risk: 1
effort: 1
phases: 1
roadmap_exempt: false
non_goals:
  - Not changing the relay thread template or scaffolding tool that emits the pointer line.
  - Not adding a general markdown parser — trailing-markdown stripping only, matching the existing
    leading-markdown stripping already in relay_field.
related:
  - relay-automation/poll.sh
  - test/poll-driver.sh
---

## Status

| What was just completed | What's next |
|---|---|
| Promoted from GitHub issue capture, root cause confirmed against the live code (`relay-automation/poll.sh:152`). Not yet built. | Fix `relay_field`, add regression coverage to `test/poll-driver.sh`, `validate.sh` green, file-scoped commit, close #92. |

## Problem (grounded in the current code)

`relay_field()` (`relay-automation/poll.sh:152`):

```bash
relay_field() { sed -n "s/^[*]*$1[*]*:[*]*[[:space:]]*//p" "$RELAY_FILE" | head -n 1 | sed 's/[[:space:]]*$//'; }
```

The extraction regex strips **leading** asterisks around the key and after the colon, then the
trailing pipe only trims trailing whitespace. A thread authored as `**NEXT: claude-reb**`
(bold wrapping the *whole* line — a natural, common style, and what the scaffolding tool that
authored the live-incident thread emits) parses to the literal string `claude-reb**` — the trailing
`**` survives untouched.

`relay_next_agent()` (line 156) takes the first whitespace-delimited token of that value —
`claude-reb**` — which then fails the `--claude-agents` membership check in the poll driver's
dispatch logic, since the configured Claude agent id is `claude-reb`, not `claude-reb**`. The poller
concludes the next agent is a non-Claude worker and emits `nudge-cross-model` on *every* tick,
forever — a silent deadlock, not a failure any exit code surfaces (confirmed live: a real duel
session stalled ~90 minutes until the pointer was hand-edited mid-run).

## Fix

Extend `relay_field`'s pipeline with one more `sed` stage that strips trailing markdown
(`*`, `` ` ``) before the existing whitespace trim, so any reasonable bold/emphasis/code-span style
around the *value* parses to the bare token:

```bash
relay_field() { sed -n "s/^[*]*$1[*]*:[*]*[[:space:]]*//p" "$RELAY_FILE" | head -n 1 | sed -E 's/[`*]+[[:space:]]*$//; s/[[:space:]]*$//'; }
```

This is a pure extension of the existing pattern (the function already strips leading `*`/`` ` ``
markdown; this closes the trailing side) — no change to the thread template, the scaffolding tool,
or any other caller of `relay_field`/`relay_next_agent`.

**Diagnostic (per the issue's suggestion):** when `relay_next_agent`'s value isn't found in
`--claude-agents` and isn't a recognized non-Claude id either, `poll.sh` should log the raw parsed
value at the `nudge-cross-model` decision point, so a *future* format the stripping doesn't cover
fails loud (visible in output) instead of silently repeating forever.

## Definition of done

- [ ] `relay_field`/`relay_next_agent` correctly parse `**NEXT: claude-reb**` (whole-line bold),
  `` `NEXT: claude-reb` `` (backtick-wrapped), and the already-working `**NEXT:** claude-reb`
  (bold-on-key) to the bare agent id `claude-reb` in all three cases.
- [ ] `test/poll-driver.sh` gets new cases for whole-line-bold and backtick-wrapped pointers,
  asserting `run-runner`/`idle`/`nudge-cross-model` classify identically to the existing bold-on-key
  case for the same agent-id scenarios.
- [ ] The `nudge-cross-model` decision path logs the parsed value when it's not a recognized
  Claude/non-Claude id.
- [ ] `bash validate.sh` green.

## Reversibility & blast radius

**Trivial, leaf-level.** One-line regex extension inside a single existing function; no schema,
no kernel, no relay-turn-lib.sh surface. Every existing caller of `relay_field`/`relay_next_agent`
keeps working identically for inputs that already parsed correctly — the change only widens what
additionally parses correctly.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/poll-driver.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/poll.sh", "pattern": "GH-92" }
  ],
  "artifacts": [
    "relay-automation/poll.sh",
    "test/poll-driver.sh"
  ],
  "remediation": "In relay-automation/poll.sh's relay_field() (line 152), extend the sed pipeline with a stage that strips trailing markdown ([`*]+ followed by optional whitespace) before the existing trailing-whitespace trim, so a whole-line-bold pointer (**NEXT: claude-reb**) or backtick-wrapped pointer parses to the bare agent id instead of leaving trailing **/` characters that fail the --claude-agents membership check and cause a silent nudge-cross-model deadlock. Add a diagnostic log of the parsed value at the nudge-cross-model decision point when the value matches neither a configured Claude agent nor a recognized non-Claude id. Add test/poll-driver.sh cases for whole-line-bold and backtick-wrapped NEXT pointers, asserting identical classification to the existing bold-on-key case. GH-92 marker comment near the fix.",
  "lanes": {
    "agy_safe": ["relay-automation/poll.sh", "test/poll-driver.sh"],
    "orchestrator_only": [],
    "note": "Independent leaf lane, no kernel/relay-turn-lib.sh touch. Parallel-safe with any other Wave 1 lane in Marathon Plan B."
  }
}
```

## Provenance

Filed 2026-07-03 after a live cross-repo relay duel silently deadlocked ~90 minutes on a
whole-line-bold `**NEXT: x**` pointer emitted by the scaffolding tool. Promoted to `2-WORKING`
2026-07-04 as part of Marathon Plan B Wave 1 (the 5 lanes cleared for firing after #23/#61 removal
and Plan A confirmation — see
[MARATHON-PLAN-2026-07-03-B-PARALLEL.md](MARATHON-PLAN-2026-07-03-B-PARALLEL.md)).
