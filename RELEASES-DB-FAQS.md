# RELEASES Ledger

This repository includes the RELEASES add-on.

## Enable the RELEASES ledger
To enable the ledger, simply initialize it:
```bash
releases init
```
*(Optional) You can then author `RELEASES.md` as needed.*

Nothing runs until the ledger is invoked.

## Re-pointing a release's tracking issue (GH-222)

When a tracking umbrella issue is superseded (e.g. closed and replaced by a re-scoped one),
re-point the release with `releases update --gid <rel> --tracking-issue <N|URL>` — a bare
number expands against the org/repo slug or the github origin remote, the URL is stored
canonically like the `add` path, and the old issue ref row keeps its identity.
