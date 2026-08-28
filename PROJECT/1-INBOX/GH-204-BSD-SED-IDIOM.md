---
title: "GH-204: BSD `sed -i ''` idiom silently no-ops on Linux at five call sites"
status: inbox
roadmap_exempt: true
created: 2026-08-24
updated: 2026-08-28
owner: arnoldadero
goal: make both in-place edits portable so a lost write can never be reported as a completed one
gh_issue: 204
source: https://github.com/HiQS-Labs/XYZ-forge/issues/204
doc_type: bugfix
effort: 1
complexity: 1
risk: 2
phases: 1
related:
  - "evidence/FINDINGS.md — round 1 Linux bring-up, where both sites were first observed"
  - "#29 / #51 — the Windows/MSYS2 audit; same class of POSIX-vs-BSD portability assumption"
---

# GH-204 — `sed -i ''` is a BSD idiom and silently loses the write on Linux

> **Superseded 2026-08-25**: PR #209 fixed the test-side call sites this doc names. The
> production-site remainder is now tracked at
> [PROJECT/2-WORKING/GH-204-BSD-SED-PORTABILITY.md](../2-WORKING/GH-204-BSD-SED-PORTABILITY.md)
> (release 0.7.4 "Linux-RC"). Kept here, `roadmap_exempt: true`, for the original findings.

## Status

| What was just completed | What's next |
|---|---|
| **Five** call sites, not two — the other three were found on 2026-08-28 while diagnosing why the gate refused on Linux: `test/gh69-roadmap-shadow.sh:102` and `:109` (which were *actively failing that suite*, 49/4) and `test/meter-release.sh:528`. The two test sites in gh69 are **fixed in PR #209** (53/0); the production pair and `meter-release.sh` remain. Original two re-verified present at `713ba6d1` (2026-08-24) and the failure mode reproduced directly on Linux (GNU sed 4.x). Severity established: at `relay-drive.sh:546` the lost write is **never surfaced** — the script prints an escalation message and exits 4 regardless. **Filed as [#204](https://github.com/HiQS-Labs/XYZ-forge/issues/204) on 2026-08-24**, so `marathon-plan.sh` can now see it. | Promote to `2-WORKING` with a preflight contract when it is scheduled. Fix is two lines; the only real decision is whether to fix the hardcoded-username residual check at `build-launch-artifact.sh:289` in the same change or separately. |

## Why this is in the ledger

The bug was found during the round-1 Linux bring-up and written up in `evidence/FINDINGS.md`.
That file is **not** a ledger `marathon-plan.sh` reads — it reads `ROADMAP.md` and `PROJECT/**`.
So as things stood, the harness's own planner could not see this bug and would never schedule it.
This document closes that gap.

## The defect

`sed -i ''` is the **BSD/macOS** spelling: BSD `-i` takes a mandatory backup-suffix argument, and `''`
means "no backup". **GNU sed takes the suffix attached** (`-i.bak`), so a separate `''` is parsed as
the *script*, and the real script is then read as a *filename*:

```console
$ printf 'STATUS: Open\nbody\n' > probe.md
$ sed -i '' 's/^STATUS:[[:space:]]*.*/STATUS: Escalated/' probe.md
sed: can't read s/^STATUS:[[:space:]]*.*/STATUS: Escalated/: No such file or directory
$ echo $?
2
$ cat probe.md
STATUS: Open      # unchanged — the write was lost
```

Verified on this host, `713ba6d1`, 2026-08-24. Exit is **2** and the target file is byte-identical.

## Call site 1 — `relay-automation/relay-drive.sh:546` (the serious one)

```bash
# Set STATUS: Escalated
sed -i '' 's/^STATUS:[[:space:]]*.*/STATUS: Escalated/' "$RELAY_FILE"
_cv_relay_repo="$(git -C "$(dirname "$RELAY_FILE")" rev-parse --show-toplevel 2>/dev/null || echo "$ROOT_DIR")"
git -C "$_cv_relay_repo" add "$RELAY_FILE" 2>/dev/null || true
git -C "$_cv_relay_repo" commit -m "relay-drive: consult-verify divergence escalation (round $round)" 2>/dev/null || true
printf 'relay-drive: relay escalated by consult-verify (STATUS: Escalated) after %d turn(s)\n' "$round" >&2
exit 4
```

This runs on the **consult-verify divergence** path — the branch that fires precisely when the
advisors disagree with the turn-taker's verdict, i.e. when a review has gone wrong and a human needs
to look.

The `sed` exit code is not checked. The two `git` calls are `|| true`. So on Linux:

- the relay file's `STATUS:` line is **not** rewritten and still reads whatever it read before,
  typically `Open` or `In Review`
- the commit is empty or absent, and both failures are swallowed
- stderr nevertheless says `relay escalated by consult-verify (STATUS: Escalated)`
- the process exits **4**, the code `relay-drive.sh` documents as *escalated by design*

Every downstream reader of terminality reads `STATUS:` from the file. `poll.sh` exits 10 only on
`STATUS: Approved|Closed`; the escalation state it is meant to see never got written.

**Net effect: a genuinely failed review can silently read as still open, while the driver reports it
as escalated.** The operator-facing message and the exit code both assert something the filesystem
does not agree with. That is the whole severity — not the portability wart itself.

## Call site 2 — `utils/build-launch-artifact.sh:283`

```bash
while IFS= read -r f; do
  if LC_ALL=C grep -qF "$REDACT_HOME" "$f" 2>/dev/null; then
    LC_ALL=C sed -i '' "s|${REDACT_HOME}|${REDACT_WITH}|g" "$f" 2>/dev/null && redacted=$((redacted+1))
  fi
done < <(find "$DEST_NORM" -type f ! -path "*/.git/*" 2>/dev/null)
printf '  redacted home path in %s file(s)\n' "$redacted"
```

This is the **author-home-path redaction that runs before a launch artifact is shared**. On Linux:

- `2>/dev/null` hides sed's error
- the `&&` means `redacted` never increments, so it prints `redacted home path in 0 file(s)`
- the home path stays in every file it was supposed to leave

The `0 file(s)` line is a real signal, but a weak one: it is indistinguishable from the legitimate
"there was nothing to redact" case.

**Second-order problem in the safety net at line 289.** The residual check that is supposed to catch
exactly this is:

```bash
residual="$(LC_ALL=C grep -rlF "noelsaw" "$DEST_NORM" --exclude-dir=.git 2>/dev/null | wc -l | tr -d ' ')"
```

It greps for the hardcoded literal `noelsaw`. For any other author it reports `0` — a false all-clear
on top of a redaction that already silently did nothing. It should grep for the actual `$REDACT_HOME`
/ the current user, not a name baked in at authoring time.

## A live instance, deliberately left alone

`evidence/marathons/run-3/artefacts/plan/home/arnoldadero/…` still carries the unredacted home path —
an instance of this bug sitting inside the evidence tree for a run that hit it. It is **left as-is on
purpose**: editing it would be editing the record. Noted here so it reads as known, not missed.

## Acceptance criteria

1. Neither call site uses the BSD-only `sed -i ''` form; both work on GNU sed and BSD sed.
2. `relay-drive.sh`'s escalation path **fails loudly** if the `STATUS:` rewrite does not land —
   it must not print "escalated" or exit 4 when the file was not changed.
3. `build-launch-artifact.sh` reports a redaction failure distinguishably from "nothing to redact".
4. The residual check no longer depends on a hardcoded username.
5. A regression test covers the escalation path asserting on **file content**, not on exit code alone.

## Suggested fix

Portable in-place edit without the suffix argument, e.g. write to a temp file and move it back, or
use `perl -i -pe`. If `sed -i` is kept, GNU and BSD need different invocations, so the temp-file form
is the simpler contract. Then, at the escalation site:

```bash
if ! _portable_sed_i 's/^STATUS:[[:space:]]*.*/STATUS: Escalated/' "$RELAY_FILE"; then
  printf 'relay-drive: FAILED to write STATUS: Escalated to %s\n' "$RELAY_FILE" >&2
  exit 1
fi
```

## Evidence

- `evidence/FINDINGS.md` — round-1 index where both sites were first recorded
- Reproduction transcript in this document's "The defect" section, re-run at `713ba6d1`
