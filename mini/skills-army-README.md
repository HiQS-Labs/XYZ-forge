# XYZ Skills Army mini

This repository distributes the standalone Skills Army HQ manager package from
[XYZ Forge](https://github.com/HiQS-Labs/XYZ-forge). It manages a durable local collection of AI
coding-agent skills and deploys directory links to configured applications.

XYZ Forge is authoritative; this repository is a generated projection. Managed files are changed
and reviewed in Forge, then republished. Do not maintain equivalent patches in both repositories.
Local collections, imported skills, receipts, targets, catalogs, history, backups, and machine-local
configuration are user-owned state and are never generated into this repository.

Requires Python 3.9+; macOS is the supported alpha. Preview and initialize a separate empty
collection from a fresh clone:

```bash
python3 ./skills-army-hq/scripts/intake.py --root "/path/to/Deployed Skills" init
python3 ./skills-army-hq/scripts/intake.py --root "/path/to/Deployed Skills" --apply init
```

Read `skills-army-hq/README.md` and `skills-army-hq/SKILL.md` for the complete workflow.
