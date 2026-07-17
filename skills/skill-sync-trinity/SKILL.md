---
name: skill-sync-trinity
description: >-
  Build or update a repo-local Codex skill by keeping three artifacts aligned:
  the canonical PDDA working doc, the skill's `SKILL.md`, and deterministic
  Python helper scripts. Use when a skill folder is empty, partial, or has
  drifted so the plan, instructions, and scripts no longer match.
---

# skill-sync-trinity

Use this skill when a repo-local skill needs to be scaffolded or repaired as one coherent bundle.
The "trinity" is:

1. `PROJECT/2-WORKING/<DOC>.md` - the canonical PDDA working doc
2. `skills/<skill-name>/SKILL.md` - the runtime instructions
3. `skills/<skill-name>/scripts/*.py` - deterministic helpers

## When to use it

- A skill folder has only an empty `PROJECT.md` or a partial scaffold.
- A repo needs a PDDA-compliant working doc for skill work, but the skill folder should stay lean.
- `SKILL.md` and helper scripts have drifted and need a single pass to re-align them.

## When not to use it

- Do not use it for publishing, installing, or syncing skills into external registries.
- Do not use it when the task is only a one-line tweak to an existing `SKILL.md`.
- Do not use it as a generic docs generator outside repo-local skill work.

## Workflow

1. Make the `PROJECT/2-WORKING` doc canonical.
   Use `scripts/render_working_doc.py` when the skill folder lacks a proper working doc or needs a
   fresh PDDA-compliant project file.
2. Keep `skills/<skill>/PROJECT.md` as a pointer.
   Do not maintain a second full plan inside the skill folder. Point back to the canonical working doc.
3. Keep `SKILL.md` short.
   Put only trigger text, scope, workflow, and routing guidance in `SKILL.md`. Move deterministic
   generation and validation into scripts.
4. Validate before claiming the scaffold is done.
   Run `scripts/validate_trinity.py` and `python3 -m py_compile` on the helper scripts. If the working
   doc changed, also run the relevant PDDA checks.

## Bundled scripts

- `scripts/render_working_doc.py`
  Renders a PDDA-compliant working doc with the exact status table and a phase skeleton tuned for skill work.
- `scripts/sync_trinity.py`
  Scaffolds the pointer `PROJECT.md`, optionally creates the working doc, and seeds a starter `SKILL.md`
  plus starter Python helpers for a target repo-local skill.
- `scripts/validate_trinity.py`
  Checks that the working doc, pointer file, `SKILL.md`, and Python helpers are present and structurally aligned.

## Suggested commands

```bash
python3 skills/skill-sync-trinity/scripts/render_working_doc.py \
  --skill-dir skills/my-skill \
  --output PROJECT/2-WORKING/MY-SKILL.md \
  --title "My Skill" \
  --owner noel \
  --goal "Describe the skill bundle this working doc owns"
```

```bash
python3 skills/skill-sync-trinity/scripts/sync_trinity.py \
  --skill-dir skills/my-skill \
  --working-doc PROJECT/2-WORKING/MY-SKILL.md \
  --title "My Skill" \
  --owner noel \
  --goal "Describe the skill bundle this working doc owns"
```

```bash
python3 skills/skill-sync-trinity/scripts/validate_trinity.py \
  --skill-dir skills/my-skill \
  --working-doc PROJECT/2-WORKING/MY-SKILL.md
```

## Output contract

- One canonical working doc in `PROJECT/2-WORKING/`
- One pointer `PROJECT.md` inside the skill folder
- One concise `SKILL.md`
- One or more Python helpers under `scripts/`

If any of those four surfaces disagree, fix the canonical working doc first, then reconcile the
skill and scripts to match it.
