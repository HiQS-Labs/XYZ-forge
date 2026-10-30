---
name: idea
description: File an admission-ready GitHub issue from the repo you are standing in — recon-lite and the debug-mantra plan pivots run at filing time, so the issue body carries an Observed table, a plan that names the existing subsystem and writer, checkbox Acceptance with red controls, a PRS proposal, a Preflight Contract and a review footer, then lands through `hq park --create` (issue + 1-INBOX capture + ledger row) and `releases roadmap rate`. Trigger on /idea, "file an issue for this", "write this up as a GH issue", "capture this idea", "park this", or the legacy /file-issue. NOT for a bug in the xyz harness seen from another repo (that is /file-xyz-bug), and NOT for rewriting an existing issue (retrofit is a later phase: comment on that issue instead).
---

# /idea — admission-ready intake

An issue filed by hand enters the flywheel with no plan, no contract and no ledger row, and the
#1175 reconciler cannot admit it (Phase 0: 0 admissible of 281 open). This skill does the recon and
the plan while the context is fresh and files the result through the writers the repo already has.
It makes an issue **admission-ready**, never admitted: `ratings_provisional` stays set, no
`approved`/`reviewed` marker is ever written, and #522 keeps the admission decision.

Writers this skill calls, and nothing else: `hq park --create` (issue, capture doc, ledger row),
`releases roadmap rate` (the four axes), `gh issue comment` (the dispositions record). It writes no
code, no tests (AGENTS.md *No new tests*, GH-831), and never commits.

## Usage

```
/idea <one-line what and why>      # harvest → recon-lite → body → consult → preview → ONE confirm → file
/idea                              # ask for the one-liner first
```

## Steps

0. **Locate HQ** with the hq skill's own locator (never a second locator, never a cached path):

   ```bash
   for L in "${XYZ_HARNESS:+$XYZ_HARNESS/skills/2-daily/hq/find-hq.sh}" \
            "$HOME/.claude/skills/hq/find-hq.sh" \
            "$(git rev-parse --show-toplevel 2>/dev/null)/skills/2-daily/hq/find-hq.sh"; do
     [ -n "$L" ] && [ -x "$L" ] && break
   done
   [ -x "$L" ] || { echo "idea: hq locator not found — install the hq skill"; exit 1; }
   eval "$("$L" --env)" && "$L" --check
   ```

   Record `ROOT=$(git rev-parse --show-toplevel)` and `BASE=$(git rev-parse --short origin/development)`
   after `git fetch origin development`; the footer needs both. These exports do not survive to the next
   Bash call (see `file-xyz-bug` Step 0); re-resolve in each command that needs them.

1. **Harvest first, ask second.** Reconstruct from this session before asking anything: the
   `file-xyz-bug` Step 1 table (what broke / exact command / observed / where / version) applies
   unchanged, with "expected behaviour", "reproducibility" and "blocking?" as the only questions
   worth asking, capped at three. Redact per `file-xyz-bug` Step 2: the body is public.

2. **Tier, with the reason printed.** `trivial` = obvious, local, reversible, no design decision and
   no uncertain behaviour change; a short diff alone does not qualify (`start-task` Step 5). Trivial
   bodies keep Observed, Plan, Acceptance, PRS proposal and Preflight Contract and skip Step 6.
   Everything else is `standard`. `spike` (a question, not a change) omits the Preflight Contract.

3. **Prior art.** `python3 utils/py/prior_art_recon.py --query "<seam>"`. An `existing_fix_candidates`
   hit stops the skill: confirm with the operator whether the ask is already fixed. A matching open
   issue means no new issue: say which one and stop (retrofitting it is Phase 3 of #1258, not this skill).

4. **Recon-lite.** Run the recon skill's Steps 1–3 sized to the radius (one seam for a trivial fix,
   the full map for a feature): entry points, call paths, every write of the state involved, the
   contracts crossed, failure and rollback paths. Pin it to `Recon: <sha>` = `git rev-parse --short HEAD`.
   Then apply `/debug-mantra plan` to the acceptance items: each must fail on the current tree, reject
   an empty input, and name its red control.

5. **Render the body** to a local file, exactly these headings in this order (the reconciler and the
   preflight read them by name):

   ```
   ## Observed            measured table (claim · command · observed) with receipts
   ## Root cause          or "Diagnosis / existing gap" for a feature: origin, fix site, removes-the-class or one-instance
   ## Plan                ordered steps, each naming the existing subsystem and writer it extends
   ## Blast radius        seams table pinned to Recon <sha>; integration base development@<sha> stated separately;
                          truthful write-set incl. docs/helpers; builder/reviewer route
   ## Dependencies
   ## Acceptance          `- [ ]` items ONLY (jog_run.py:505-556 reads nothing else); each names its red control
   ## Verification        existing suite or manual check under TESTS-RESULTS/<date>+GH-<n>/ (no new tests)
   ## Non-goals
   ## Risk and rollback
   ## PRS proposal        pri/sev/appeal/effort 1–100, one issue-specific rationale line each; appeal 50 unless the
                          operator set it; effort scores CHEAPNESS
   ## Preflight Contract  JSON: target.repo, target.ref "development", gate, fix_probes (≥1, each UNFIXED at target.ref:
                          grep_absent/path_absent/grep_present/path_present/command), artifacts (≥1); every new file in
                          BOTH artifacts and artifacts_new with a path_absent probe (jog_run.py:1366-1373)
   Recon: <sha> · base: development@<sha> · tier: <trivial|standard|spike> · review: pending
   ```

   The footer is one line and is the last line of the body. The review hash (Step 6) covers every
   byte above it, so writing the hash into it changes nothing that was hashed.

6. **Consult (standard tier).** Load the consult skill and fan the rendered body out with the
   start-task Step 6 questions (claims grounded in the cited paths? requirement missing? extends
   the existing subsystem and writer? blast radius, ordering, rollback and falsifiable checks
   sufficient? ratings grounded, appeal neutral?). Adjudicate every finding against the tree, revise
   the body, keep the dispositions for Step 9. Then compute the hash and finish the footer:

   ```bash
   HASH=$(sed '$d' body.md | shasum -a 256 | cut -c1-64)   # everything above the footer line
   # footer: review: consult <run-id> models=<codex,agy | codex, degraded | agy, degraded> hash $HASH
   ```

   `models=` names the seats that answered; `consult.sh` exits 0 on a single answer, so a degraded
   run must be legible from the issue alone. This is a **draft review** for #522's reviewer, not the
   review: it never writes `approved`, and `start-task` Step 6 still runs when the work is picked up.

7. **Preview, one confirmation.** Export the judgment fields from the recon and preview (hq previews
   by default):

   ```bash
   HQ_PARK_WHY="<one paragraph>" HQ_PARK_KEY_CONCEPTS="a|b|c" HQ_PARK_NON_GOALS="x|y" \
   HQ_PARK_RELATED="#n|#m" HQ_PARK_COMPLEXITY=<1-5> HQ_PARK_RISK=<1-5> HQ_PARK_EFFORT=<1-5> HQ_PARK_PHASES=<n> \
   bash "$HQ_SH" park --title "<one line, no rated a/b/c/d token>" <project> "$(cat body.md)"
   ```

   The title must not contain a `rated N/N/N/N` token: `hq_roadmap_line` interpolates it into the ledger
   line and `parse_rating` reads the whole line (`releases_app.py:3639`), which would pre-rate the row and
   make Step 8's `roadmap rate` refuse. Score examples belong in the body. Show the operator the title,
   the body, the capture-doc path and the ledger line together, and get **one** confirmation. `hq park` refuses a title that matches an open issue (`hq.sh:306`); that is
   the dedupe, do not work around it.

8. **File, rate, read back.** Run un-sandboxed (`gh` needs the keychain):

   ```bash
   … bash "$HQ_SH" park --create --title "<title>" <project> "$(cat body.md)"     # prints "✓ issue: <url>"; N is its trailing number
   python3 utils/py/releases_app.py roadmap rate --issue-num N --rated P/S/A/E --dry-run
   python3 utils/py/releases_app.py roadmap rate --issue-num N --rated P/S/A/E
   python3 utils/py/releases_app.py roadmap list --json | python3 -c 'import json,sys;print([r for r in json.load(sys.stdin) if r.get("gh_number")==N])'
   ```

   `hq park` drops the rating (`hq_roadmap_line` carries no `rated` token), so `roadmap rate` is the
   writer. Never pass `--force`; never clear `ratings_provisional` in the doc. The capture doc embeds
   the body verbatim under `## Idea`, so the Acceptance checkboxes and the Preflight Contract reach
   the doc with no HQ change.

9. **Post the dispositions** (standard tier): `gh issue comment N --body-file dispositions.md` with
   the consult run dir, each finding and its disposition, and the hash from Step 6.

10. **Preflight the capture, refuse on any nonzero.**

    ```bash
    bash utils/swarm-preflight.sh --project-doc "$ROOT/PROJECT/1-INBOX/GH-N-<SLUG>.md" --target-root "$ROOT" --dry-run; echo "exit=$?"
    ```

    `--project-doc` reads the fresh local capture directly (`--gh-issue` searches only `2-WORKING`);
    the uncommitted capture and ledger are fine: dirty state is recorded, not a verdict condition
    (`swarm_preflight.py:1312-1316,1640-1645`). `--dry-run` publishes nothing but **does** fetch and
    create/remove a detached worktree. Exit 0 is READY. Anything else is reported by name, never as success: 3 contract missing/invalid, 4 STALE
    (a probe already satisfied at `target.ref`: either a wrong probe or already-delivered work; say
    which you found), 5 NOT-READY (an artifact missing at `target.ref` and absent from
    `artifacts_new`), 6 BLOCKED, 7 AMBIGUOUS. By now the issue, the capture doc and the ledger row
    already exist (Step 8 ran first), so the report says **filed, not admission-ready**, names those
    three outputs and the verdict, and stops; nothing is rolled back and nothing is admitted. Fix the
    body and the doc together, or leave it for the operator. The skill never invents a replacement
    probe to turn a verdict green.

11. **Report** in five lines: the issue URL; the capture-doc path and ledger row id; the rating as
    read back; the preflight exit and verdict; and that the capture, `releases.db` and `releases.sql`
    are **uncommitted** on the current branch, so the operator knows the one action left is theirs.

## Guardrails

- The only writers are `hq park --create`, `releases roadmap rate` and `gh issue comment`. No file
  under `utils/`, no new flag, no new script, no test, no commit, no push.
- Never write `approved`, `reviewed` or any admission marker. Never clear `ratings_provisional`.
- Never retrofit an existing issue's body. Never file when prior art names an open match.
- A rating is four 1–100 integers with one rationale line each; never 1–5 values, never a template default.
- A `swarm-preflight` verdict other than READY is reported as what it is. Success is exit 0 only.
