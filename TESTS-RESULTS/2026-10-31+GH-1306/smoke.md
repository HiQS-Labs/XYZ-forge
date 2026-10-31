# GH-1306 smoke and verification (manual check; no new suite — GH-831)

| Check | Revision | Result | Log |
|---|---|---|---|
| Red control: `smoke.py` on the pre-fix bundle | 19fe0e6b | 4 FAIL: `update --source` prints `Unchanged` for a `catalog` receipt (no source) and an `adopt-existing` receipt (source = the collection's own folder); nothing recorded | `red-control-prefix.log` |
| Smoke main path + adjacent paths | 6426356f | 19/19 PASS | `smoke-candidate.log` |
| Existing suite `bash test/skills-army-hq.sh` | 6426356f | 33 passed, 4 subtests passed | `skills-army-hq-suite.log` |

**Fixture:** a disposable Pulse-shaped collection in its own temp git repo, adopted with
`init --adopt-existing`; a second skill registered with `catalog`, which leaves no `source` key (the
shape of the 8 skills seen on 2026-10-30). HOME is sandboxed; no real collection is touched.

**Main path (`other`, catalog receipt):** preview prints `will RECORD source …` and leaves the receipt
untouched; `--apply` records source and commit, payload bytes are unchanged, no backup archive, no
blocked-pulse WARN, no Pulse commit.

**Adjacent paths:** (a) an `adopt-existing` receipt re-points to the owning repo; (b) rerunning the same
command prints `Unchanged` (idempotent); (c) a real content change still copies the payload.
