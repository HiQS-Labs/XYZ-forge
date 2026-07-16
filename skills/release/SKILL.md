---
name: release
description: Turn a planned entry in RELEASES.md into a published GitHub Release. Finds the matching "Release: <version>" block, previews a `gh release create` body built from that block's own Description, then on confirmation publishes it and writes the returned URL back into GH_URL. Trigger on /release <version>, "publish this release", or "create GitHub release for <version>".
---

# /release — RELEASES.md entry → published GitHub Release

Give it a release version (e.g. `1.0.0`). It finds the matching `Release:` block in `RELEASES.md`,
previews a `gh release create` command built from that block's own fields, and — on one
confirmation — publishes the GitHub Release and writes the returned URL back into `GH_URL:`.

This is the **publish** front-door for a planned release. It does not add new entries to
`RELEASES.md` — for that, use `/release-plan` (already globally available on this machine via
`~/.claude/skills/release-plan`), the sibling **author** front-door — and it does not write
`CHANGELOG.md` — that's a separate, operator-owned step (see step 6).

## Usage

```
/release 1.0.0   # find and publish the "Release: 1.0.0" block in RELEASES.md
/release         # ask for the version, then proceed
```

## Steps

0. **Detect PDDA + tools (preflight).**
   - **PDDA repo?** Check for `utils/pdda/pdda.sh` at the repo root. If absent → say so and stop.
   - **Tools?** `gh` (auth'd) is required. If a `gh` call fails, retry **unsandboxed** first before
     concluding it is broken. Confirm `gh auth status` succeeds before proceeding.

1. **Locate the release block.** Find the `Release: <version>` block in `RELEASES.md`. Error if no
   block matches, or if `Status:` already reads `Shipped` (already published; nothing to do). If
   `GH_URL:` is populated but `Status` isn't `Shipped`, a Release object already exists (likely a
   draft, e.g. from a manual `gh release create --draft`) — say so and ask the operator how to
   proceed rather than assuming nothing to do; `gh release create` below will simply fail if the
   tag/release already exists, which step 5's guardrail already handles.

2. **Run `pdda.sh releases`** to surface any findings (a malformed block, an invalid `Target Date`)
   before attempting to publish. Report findings to the operator; this check is warn-only, so use
   judgment rather than a hard gate.

3. **Build the release body from the block's own fields.** Use `Description:` as the body. If
   `Codename:` is set and isn't `n/a`, mention it. If `Description:` is empty, ask the operator for
   a short summary rather than inventing one — never fabricate release notes.

4. **Preview, then get ONE confirmation.** Render together:
   - The `gh release create` command that would be run (version as tag, title, body)
   - The release body (full markdown preview)
   - The `GH_URL:` write-back that will happen on confirm
   Nothing is published before the operator confirms.

5. **On confirm, execute in order:**
   - `gh release create <version> --title "<title>" --notes "<body>"` → capture the returned URL.
     This publishes live (no `--draft`), so a successful call means the release is genuinely out.
   - Update `GH_URL:` in the matching `RELEASES.md` block with the returned URL, **and** set
     `Status: Shipped` — `GH_URL` alone only means "a Release object exists"; `Status: Shipped` is
     what the checks treat as authoritative.

6. **Report + nudge.** Run `utils/pdda/pdda.sh releases` to confirm it's clean. Report the release
   URL and remind the operator to add a `CHANGELOG.md` entry for this release (lessons learned live
   there, not in `RELEASES.md`). Do not write the CHANGELOG entry yourself.

## Guardrails

- **One preview, one confirmation.** Render the `gh release create` command + full body together and
  publish nothing until the operator confirms once.
- **Outward-facing steps confirm first.** A GitHub Release is public and durable.
- **Never invent release notes.** Use the block's own `Description:`; if it's empty, ask — don't
  fabricate.
- **Repo-relative paths only** in doc edits — no absolute local paths.
- **If `gh release create` fails**, report the error verbatim and stop. Do not write `GH_URL:` until
  the create succeeds.
