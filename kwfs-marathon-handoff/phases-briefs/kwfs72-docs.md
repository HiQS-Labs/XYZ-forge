# Phase kwfs72 — #72 Remove stale README/AUDIT.md security & performance warnings

**Issue:** kissplugins/KISS-woo-fast-search #72 (documentation, low). Branch off `development`.

**Goal:** README "Security & Performance Notes" and the four `AUDIT.md` findings still warn users
about issues that are already fixed (XSS via unescaped JS, unbounded `all_with_meta` customer loads,
`wc_get_orders limit => -1` counting, the `esc_attr` benchmark). All resolved in commits
`2a9398b`, `58ccc06`, `068a37e`. Make the docs tell the truth.

**Files you may edit:** `README.md`, `AUDIT.md` only.

## Gate contract (publish-the-needle)

The gate checks this invariant by **grepping for specific stale phrases** in `gate.php`. A green
fix means those phrases are **gone**, not merely annotated "Fixed".

- [ ] Open `tests/gate.php`, find the `#72` needle list, and ensure **none** of those exact phrases
      remain in `README.md` or `AUDIT.md`. The gate fails on *presence*, so removing the surrounding
      sentence is required — appending "(Fixed)" after the description will leave it RED.
- [ ] If you want to retain a historical note, phrase it as resolved with the commit refs above and
      confirm it does not re-trip a needle.

## Definition of done

- [ ] `bash tests/run.sh` shows the `#72` invariant **passed**.
- [ ] No remaining doc text implies any of the four findings is still open.
- [ ] Reviewer confirms the retained text (if any) is accurate and commit-referenced.

## Out of scope

- Do not touch code or other docs. This phase is docs-only.
