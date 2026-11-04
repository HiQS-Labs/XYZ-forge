# GH-1333 PR #1334 checks

## express red/green (commit 693e9d22)

`parse_rating(raw, "Example")` from `utils/py/releases_app.py`:

- old line (`🆕 rated 2/2/2/2 —`): `{rating_pri: 2, rating_sev: 2, rating_appeal: 2, rating_effort: 2, rating_ovr: None}` (red)
- new line (`🆕 —`): all five fields `None` (green)

## Existing suite

`bash test/gh267-express-skill.sh` at 693e9d22 (unsandboxed, gate PATH):

```

gh267-express-skill: pass=113 fail=0
```

## PDDA

`bash utils/pdda/pdda.sh run` before (origin/development) vs after: 0 errors both. The only differences: the CHANGELOG-freshness warning clears, and one new issue-doc-sync warning (#1263 closed but ledger row in Queue) appears from live state, since the #1298 batch landed #1263 between the runs.

## Pre-push gate

- 14e39087: documentation gate GREEN in 116s.
- 693e9d22: full gate GREEN in 6939s; first push failed on a network error (RPC failed; Broken pipe); the retry reused the receipt for 693e9d22.
