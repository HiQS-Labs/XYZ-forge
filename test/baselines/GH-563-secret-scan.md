# GH-563 secret scan — the public launch artifact

Recorded 2026-08-15. Evidence for #563's *Secret and privacy review* section. Sanitized: no secret
values, raw matches, or credential fragments appear in this file, per that issue's evidence rule.

## Tool

```
trufflehog 3.97.0
```

Version pinned as reported by the scanning binary itself, not by `--version` on the installed path —
the two disagreed (`3.96.0` installed, `3.97.0` reported at scan time), and the scanner's own
self-report is what covers the result.

## Scope — and why it is the artifact, not the source history

**Scanned: the published artifact**, at the exact commit below. With fresh history that is one
commit and one tree, and it is the entire public exposure.

**Not scanned here: the private source repository's 2,147-commit history.** That is tracked
separately as credential-rotation hygiene. The reasoning, recorded because it is a deliberate
narrowing of the issue's original wording: a credential ever committed to the private repository may
still need rotating, but publishing an artifact that does not contain it cannot expose it. Letting a
dead credential in unpublished history block a clean release would conflate repository hygiene with
release safety. See the *Acceptance — deviations from the issue* section of
`PROJECT/2-WORKING/GH-563-PUBLIC-LAUNCH.md`.

## Commit

```
306a09dea7325bc6634a6f35022dfd0ec610b73f
```

## Result

Two scans, both clean:

```
trufflehog git file://<artifact>
  chunks: 1056   bytes: 7296915   verified_secrets: 0   unverified_secrets: 0

trufflehog filesystem <artifact>
  chunks: 2249   bytes: 16966225  verified_secrets: 0   unverified_secrets: 0
```

The `git` scan covers the committed history; the `filesystem` scan covers the working tree,
including anything present but untracked. Both are recorded because a clean result from one is not a
clean result from the other.

## The finding that mattered, and it was not a secret

The **first** scan of the artifact was not clean: it returned two unverified `ZendeskApi` hits, both
in `.consult-gh79-out/consult-114136/consult.codex.md`.

The hits themselves were false positives — an article-slug-shaped string in transcript prose, not a
credential. **The directory was the real finding.** `.consult-gh79-out/` is tracked internal consult
transcript output, and it survived sanitization because the sweep for internal working material
enumerated top-level directories by name and a **dot-prefixed directory is not visible to that
sweep**. It was dropped and the artifact rebuilt.

Recorded prominently because the lesson generalises past this one directory: the secret scanner
earned its place here not by finding a secret but by reading files a name-based sweep never looked
at. A tracked hidden directory is exactly the shape of thing a keep/drop list misses.

## What this does not prove

TruffleHog finds credential-shaped strings. It does not find private paths, internal hostnames,
personal data, or proprietary prose — those are covered separately by the launch gate's
private-marker sweep (`test/meter-release.sh`, Half A) and by the manual review #563 requires. A
clean scan here is one of several conditions, not the whole review.
