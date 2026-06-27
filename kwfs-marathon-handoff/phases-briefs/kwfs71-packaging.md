# Phase kwfs71 — #71 Exclude process artifacts from the plugin distributable

**Issue:** kissplugins/KISS-woo-fast-search #71 (packaging, low). Branch off `development`.

**Goal:** `relay-system/` and `PROJECT/` (and now the marathon scaffolding) are committed for history
but must not land in the distributed plugin zip. Exclude from the build artifact only — **do not delete
from the repo**.

**Files you may edit:** `.distignore` (create it) only.

## Gate contract (publish-the-needle)

The gate asserts (no DB, pure file check) that a built/staged plugin contains no process dirs. It reads
`.distignore` for the required exclusions.

- [ ] Open `tests/gate.php`, find the `#71` check, and create `.distignore` so it satisfies exactly
      what the gate asserts (at minimum `relay-system/` and `PROJECT/`).
- [ ] Also exclude the marathon/swarm scaffolding so the swarm's own files never ship:
      `.tick/`, `tests/`, `MARATHON.yaml`, `phases-briefs/`, `phases/`.
      (Running the marathon with the plugin as ROOT creates `.tick/` in this repo — it must be excluded.)
- [ ] Confirm `.gitignore` already ignores `/relay-system/`; `.distignore` is still required for the
      tracked `PROJECT/` docs and the scaffolding above.

## Definition of done

- [ ] `bash tests/run.sh` shows the `#71` invariant **passed**.
- [ ] A staged/built zip would contain no `relay-system/`, `PROJECT/`, `.tick/`, `tests/`, or marathon
      files; repo history is untouched.

## Out of scope

- Do not change the build tooling itself or remove anything from version control.
