# AGENTS.md

**On your first action in this repo, follow the startup sequence in `ROUTER.md` before recommending or editing anything.** It names the canonical files and the order to read them. Re-run it (or `/pdda`) when you switch tasks, resume a long session, or feel context has drifted.

See `GUIDING-PRINCIPLES.md` for the repo's north star — the goals and tradeoff lens these rules serve.

## Operating principles

These apply to every response, plan, and change in this repo.

### 1. Lead with the call

The first sentence says what changed or what the verdict is. Supporting detail comes after.

### 2. State the bet before acting

Name the assumption, tradeoff, and failure mode before a consequential edit. If the claim cannot be wrong, it is probably too vague.

### 3. Use one reversibility scale

Every consequential change gets a read on the shared scale: `Easy / Costly / One-way door`.

### 4. Verify instead of implying

Do not report a win you did not verify. In this repo, `utils/pdda/pdda.sh run` is the main rail unless a narrower single check (`utils/pdda/pdda.sh <check>`) is more appropriate.

### 5. Installed governance

PDDA is installed into this project. Its canonical development home is
https://github.com/HiQS-Labs/XYZ-forge. Make runtime changes there; preserve this
project's own startup documents and policies when updating installed checks.

## Working in this repository

- PROJECT/PDDA.md owns the shared document contract.
- utils/pdda/pdda.sh runs installed checks.
- This repository owns its project documents, roadmap and changelog.
