---
gh_issue: 942
source: https://github.com/HiQS-Labs/XYZ-forge/issues/942
title: "9 skills exceed the 1024-char frontmatter description limit"
status: Active
created: 2026-10-02
fix_probes:
  - test -f skills/4-occasional/feynman/SKILL.md
  - bash test/skills-army-hq.sh --help
updated: 2026-10-16
owner: operator
goal: "The 13 committed SKILL.md files that exceed the 1024-char folded description limit (five, recon, workhorse, 10days, dry, radar, feynman, front-door, readme-audit, spike-360, timbre, better-options, vscode-color) are trimmed under it so skill loaders stop silently dropping them; any skill not in that list is out of this phase."
complexity: 1
risk: 1
effort: 2
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Issue #942 filed; all three deployed skills (radar, 10days, express) trimmed on PR #943 and re-vendored from its commits; independent relay QA Approved (`relay-system/2026-10-02/gh943-qa.md`). | Trim the remaining 6 (five, feynman, front-door, readme-audit, spike-360, timbre); re-vendor any that becomes deployed. |

## Problem

ZCode (and any spec-compliant Agent Skills consumer) silently drops a skill at load time when its
frontmatter `description` folds to more than 1024 characters. 9 committed skills are over the limit;
the 3 deployed to the operator's device (`radar`, `10days`, `express`) are therefore invisible to
ZCode sessions despite a healthy skills-army-hq deployment (payload + symlinks verified).

## Affected (canonical `skills/<tier>/<name>/SKILL.md`, folded desc chars)

- ~~1570~~ → 1015 — 3-weekly/10days (deployed; **fixed on PR #943**)
- ~~1336~~ → 1001 — 3-weekly/radar (deployed; **fixed on PR #943**)
- 1241 — 4-occasional/feynman
- 1193 — 4-occasional/front-door
- 1183 — 4-occasional/readme-audit
- 1151 — 4-occasional/spike-360
- 1136 — 4-occasional/timbre
- ~~1131~~ → 1015 — 2-daily/express (deployed; **fixed on PR #943**)
- 1061 — 1-hourly/five

## Fix recipe

1. Trim `description` to ≤1024 folded chars, front-loading trigger wording in the first ~250 chars;
   move cut detail into the body if absent there. Body pins (e.g. `test/gh779-radar-ci-health.sh`)
   are unaffected by frontmatter-only edits.
2. Deployed skills: re-vendor with `intake.py --apply update <name> --source <forge>/skills/<tier>/<name>`;
   symlinks read through, no re-link needed. Restart the consumer session to re-discover.
3. Optional guard rides an existing suite (GH-831 no-new-tests rail) — fail when a committed
   SKILL.md description folds over 1024.

## Merge evidence

- PR #943 merged 2026-10-03 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash ci-local.sh",
  "fix_probes": [
    {
      "type": "command",
      "cmd": "python3 -c 'import re,glob,sys,yaml\nbad=[]\nfor p in sorted(glob.glob(\"skills/*/*/SKILL.md\")):\n    t=open(p).read()\n    m=re.match(r\"^---\\n(.*?)\\n---\", t, re.S)\n    if not m: continue\n    try: fm=yaml.safe_load(m.group(1)) or {}\n    except Exception: continue\n    d=fm.get(\"description\")\n    if isinstance(d,str) and len(\" \".join(d.split()))>1024: bad.append(p)\nprint(bad)\nsys.exit(1 if bad else 0)'",
      "expect_nonzero": true,
      "note": "pre-fix: at least one committed SKILL.md description (full YAML value, folded on whitespace) exceeds 1024 chars (exit 1); landed when none do (exit 0)"
    }
  ],
  "artifacts": [
    "skills/1-hourly/five/SKILL.md",
    "skills/1-hourly/recon/SKILL.md",
    "skills/2-daily/workhorse/SKILL.md",
    "skills/3-weekly/10days/SKILL.md",
    "skills/3-weekly/dry/SKILL.md",
    "skills/3-weekly/radar/SKILL.md",
    "skills/4-occasional/feynman/SKILL.md",
    "skills/4-occasional/front-door/SKILL.md",
    "skills/4-occasional/readme-audit/SKILL.md",
    "skills/4-occasional/spike-360/SKILL.md",
    "skills/4-occasional/timbre/SKILL.md",
    "skills/1-hourly/better-options/SKILL.md",
    "skills/4-occasional/vscode-color/SKILL.md"
  ],
  "remediation": {
    "source": "issue#942",
    "criteria": "Trim the 13 listed SKILL.md frontmatter descriptions to <=1024 folded chars (full YAML value, literal blocks included), front-loading trigger wording; move cut detail into the body. Frontmatter-only edits; no new suite (GH-831). Skills outside the artifact list are not part of this phase."
  },
  "lanes": {
    "agy_safe": [
      "skills/1-hourly/five/SKILL.md",
      "skills/1-hourly/recon/SKILL.md",
      "skills/2-daily/workhorse/SKILL.md",
      "skills/3-weekly/10days/SKILL.md",
      "skills/3-weekly/dry/SKILL.md",
      "skills/3-weekly/radar/SKILL.md",
      "skills/4-occasional/feynman/SKILL.md",
      "skills/4-occasional/front-door/SKILL.md",
      "skills/4-occasional/readme-audit/SKILL.md",
      "skills/4-occasional/spike-360/SKILL.md",
      "skills/4-occasional/timbre/SKILL.md",
      "skills/1-hourly/better-options/SKILL.md",
      "skills/4-occasional/vscode-color/SKILL.md"
    ],
    "orchestrator_only": []
  }
}
```
