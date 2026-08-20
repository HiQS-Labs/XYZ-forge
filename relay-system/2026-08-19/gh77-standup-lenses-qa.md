# QA review — GH-77 collect.sh lenses 2, 3 and 7

STATUS: Open
NEXT: builder (Builder)

## What you are reviewing

Branch `gh77-standup-lenses-2-3-7`, one commit `1a8d07c` on top of `development`. It is the builder
output of Daybreak wave 1 (release 0.7.2, GH-77) and it has had **no adversarial pass at all** — the
marathon phase escalated at the builder turn on containment (issue #91) and the review round never
ran. You are that round.

Files:

- `skills/standup/collect.sh` — 173 lines, new. Lens 2 (working tree), lens 3 (branch divergence),
  lens 7 (ROADMAP ledger sync). Each honours `--fixture <dir>`.
- `skills/standup/fixtures/lens-2/`, `lens-2-fail/`, `lens-3/`, `lens-7/` — new.
- `test/gh77-standup-triage.sh` — +38 lines, 29 assertions to 35.

The consumer is `skills/standup/triage.py` (unchanged by this branch, and **out of scope to edit** —
if a lens appears to need a change there, that is a finding to report, not an edit to make).

The specification is `PROJECT/2-WORKING/GH-77-STANDUP-SESSION-TRIAGE.md`. Its lens table is
authoritative for each bounded read and for the six required candidate fields. **Where the doc and
`triage.py` disagree, the code and its tests win.**

## What the phase already claims

Verified before handing this to you, so do not spend the turn re-establishing it:

- all three fixtures emit valid JSON from `collect.sh --fixture …`
- `triage.py --lenses <output> --dry-run` exits 0 with no `D5` for each
- `bash test/gh77-standup-triage.sh` is 35/0

A green suite is the floor here, not the finding. The question is what the suite does not cover.

## What to look for, in priority order

1. **Assertions that cannot fail.** The six new assertions are two per lens: the candidate classifies
   to its expected tier, and the lens degrades loudly with its `D` id when the read is unavailable.
   For each one, ask what build would make it go red. An assertion no realistic defect can break is
   worse than no assertion, because it reads as coverage.
2. **Silence.** The brief's one unacceptable outcome is a lens that emits nothing: a lens that cannot
   supply all six required fields must set `status: degraded` with its `D` id rather than drop the
   candidate. Find any path — parse failure, empty read, unexpected exit code, missing fixture file —
   where a lens returns `status: ok` with an empty candidate list and no `D` id.
3. **The three settled decisions**, which the brief says are not open. Check the code actually
   implements them:
   - lens 2 excludes only **untracked** paths under `PARKED/`; a modified **tracked** park file must
     still surface;
   - lens 3 never claims "unpushed" without an upstream — with no upstream it carries
     `upstream-state: no-upstream`, takes **unknown** staleness, and its `close` is an `inspect:`
     action, never a bare `git push`;
   - `close` is never executed by collection.
4. **Fixture fidelity.** Do the fixtures represent the real command output, or a shape convenient for
   the assertions? A fixture that cannot occur in practice pins nothing.
5. **Shell correctness.** Unquoted expansions, paths with spaces (this repo lives under
   `GH Repos/`), `set -e` interactions, and exit codes that a caller reads.

## Definition of done for your turn

Append one review block with your findings, each graded **[Blocker] / [Should] / [Nit]** and each
citing a file:line or a quoted span. State plainly if you find nothing at a grade — an empty
[Blocker] list is a real result. Then set `STATUS:` to `Approved` if you would merge this as-is, or
leave it `Open` and hand back if you would not.

Do not edit any file other than this relay file.

## Rounds

### Reviewer — codex — 2026-08-19

- [Blocker] The six new lens checks never invoke `collect.sh` or its fixtures. `test/gh77-standup-triage.sh:175-210` writes hand-authored collector-shaped JSON via `mk`/inline Python, then calls only `triage.py`; therefore deleting or breaking every collector candidate, degradation, or fixture path still leaves all six assertions green. Replace these with collector end-to-end fixtures (including the failure fixtures) before treating the assertions as coverage.
- [Blocker] Lens 3 violates the settled no-upstream contract and masks real read failures. `skills/standup/collect.sh:80-92` treats *every* non-zero upstream query as “no upstream,” then compares `main...HEAD`; the authoritative requirement is fallback only on exit 128 and to `development` here, otherwise D5 (`PROJECT/2-WORKING/GH-77-STANDUP-SESSION-TRIAGE.md:129,142-146`). A missing repo, bad revision, or other `git` error is presently reported as a valid no-upstream observation instead of a degraded lens.
- [Blocker] Several unavailable/malformed-input paths report `status: ok` with no candidate and no D id — the explicitly prohibited silent outcome. `skills/standup/collect.sh:31-32` makes an omitted fixture read succeed empty; `:80-96` accepts an empty or non-count `rev-list` success without validating two integer counts; and `:103-105` converts a failed dirty-tree read into `clean_tree=true`. The latter can wrongly promote an ahead tracked branch to tier 4. Missing fixture files, parse failures, and failed dependent reads must degrade loudly rather than look clean.
- [Blocker] The final heredoc interpolates the branch name without JSON encoding (`skills/standup/collect.sh:165-173`). Git ref names may contain a double quote, so a legal branch can make the collector emit invalid JSON despite a successful exit. Build the document with `jq` (or otherwise JSON-encode `branch`) rather than hand-assembling it.
- [Should] The emitted candidate shapes do not implement the authoritative lens-table evidence/state contract: lens 2 uses `status:<path>` and no file-mtime staleness (`skills/standup/collect.sh:51-67`); lens 3 emits prose `branch:<behind> behind, <ahead> ahead` instead of `counts:<ahead>/<behind>@<upstream-state>` (`:106-130`); and lens 7 emits the constant `ledger:roadmap_diverged` instead of parsed `counts:+a~u-r` (`:141-157`). This also means their `live_state` values do not match the specified canonical forms (`PROJECT/2-WORKING/GH-77-STANDUP-SESSION-TRIAGE.md:128-133,245-275`). Parse the documented command output and emit those forms.
- [Should] The no-upstream close is textually an `inspect:` action but is labelled `close_kind: "command"` (`skills/standup/collect.sh:97-124`). That misdescribes an inspect-only action to the consumer and makes its effort bin S rather than L; emit `close_kind: "inspect"` for this case.
- [Should] `skills/standup/SKILL.md:19-22,52-56` still says `collect.sh` is not built and documents a required `--session` flag which this collector rejects at `collect.sh:5-9`. Update the skill when this partial collector has a supported invocation, or keep the command unavailable until its interface is implemented.
- [Nit] None.

Verdict: not approved. Static review only; no project test or gate was run per relay containment.
