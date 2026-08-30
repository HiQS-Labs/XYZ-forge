#!/usr/bin/env python3
"""Merge approved allowlist rules into a Claude Code settings file.

Usage:
    python3 write_rules.py <rules.json> [settings_path]

<rules.json>   Path to a file containing a JSON array of rule strings, e.g.
               ["Bash(git status:*)", "Read"]. Write this file with the editor
               (Write tool) — NOT via the shell — so rule strings that contain
               quotes, parens, or `$` never have to survive shell escaping.
[settings_path]  Defaults to `.claude/settings.local.json` (relative to CWD, i.e.
               the project you are working in). Never write the shared
               `.claude/settings.json` or the global file unless explicitly asked.

Rules are appended to `permissions.allow` (creating it if absent). A legacy
top-level `allowedTools` list is honored if that is the file's existing shape.
Existing rules are never removed and duplicates are skipped, so re-running is safe.
Exits non-zero on bad input so a caller can tell success from failure.
"""
import json
import os
import sys


def main():
    if len(sys.argv) < 2:
        print("usage: write_rules.py <rules.json> [settings_path]", file=sys.stderr)
        return 2

    rules_file = sys.argv[1]
    settings_path = sys.argv[2] if len(sys.argv) > 2 else '.claude/settings.local.json'

    try:
        with open(rules_file, 'r') as f:
            new_rules = json.load(f)
    except (OSError, ValueError) as e:
        print(f"error: could not read rules file {rules_file!r}: {e}", file=sys.stderr)
        return 1

    if not isinstance(new_rules, list) or not all(isinstance(r, str) for r in new_rules):
        print("error: rules file must contain a JSON array of strings", file=sys.stderr)
        return 1

    parent = os.path.dirname(settings_path)
    if parent:
        os.makedirs(parent, exist_ok=True)

    if os.path.exists(settings_path):
        try:
            with open(settings_path, 'r') as f:
                data = json.load(f)
        except (OSError, ValueError) as e:
            print(f"error: existing settings file {settings_path!r} is unreadable: {e}", file=sys.stderr)
            return 1
    else:
        data = {}

    # Honor an existing legacy `allowedTools` list; otherwise use the standard
    # `permissions.allow` shape (creating it when the file is new or partial).
    if 'permissions' not in data and 'allowedTools' in data:
        target = data['allowedTools']
    else:
        perms = data.setdefault('permissions', {})
        target = perms.setdefault('allow', [])

    added = []
    for rule in new_rules:
        if rule not in target:
            target.append(rule)
            added.append(rule)

    with open(settings_path, 'w') as f:
        json.dump(data, f, indent=2)
        f.write('\n')

    print(f"Wrote {len(added)} new rule(s) to {settings_path} "
          f"({len(new_rules) - len(added)} already present).")
    for rule in added:
        print(f"  + {rule}")
    return 0


if __name__ == '__main__':
    sys.exit(main())
