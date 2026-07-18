# RELAY · QA the file-xyz-bug cross-repo bug intake skill
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-18.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(file-xyz-bug-qa): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review (read all three; they ship together):
  - `skills/file-xyz-bug/SKILL.md` — the skill instructions
  - `skills/file-xyz-bug/find-xyz.sh` — device-agnostic locator for the intake repo
  - `skills/file-xyz-bug/install.sh` — user-level symlink installer
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-18

### What this skill is for
`/file-xyz-bug` is invoked from **some other repo** (a WordPress plugin, a client site, anywhere)
when the xyz harness misbehaves. It must land a PDDA-compliant bug capture in
**this** repo's `PROJECT/1-INBOX/GH-<n>-*.md`, file the tracking GitHub issue, and park a
`ROADMAP.md` pointer — while writing **nothing** into the repo the operator is standing in.
Sibling front-doors it must stay consistent with: `/idea` (net-new, same repo) and `/triage`.

### Definition of Done — grade against these
1. **Cross-repo addressing is airtight.** No hardcoded machine path anywhere; the locator resolves
   from any CWD, incl. non-git dirs and paths containing spaces. It must never resolve to a vendored
   `.xyz/` copy (those have no `PROJECT/1-INBOX`, so a report filed there is unreadable).
2. **Zero blast radius on the caller repo.** Nothing is created, edited, or staged in the repo the
   operator is standing in — no breadcrumbs, no cached paths.
3. **Never commits/pushes the capture** in the intake repo. This clone is shared with marathon and
   relay drivers that can leave it dirty or parked on a `marathon/*` branch; a foreign-session commit
   can land off-branch or orphan a peer agent's work. Does the skill warn and stop at the right point?
4. **Secret redaction actually holds.** Harvested commands/error output come from a foreign repo and
   the issue body is **public**. Is the redaction step positioned before anything outward-facing?
5. **PDDA contract conformance.** Frontmatter + body match `PROJECT/PDDA.md` for a `GH-*` 1-INBOX
   capture (`ratings_provisional: true`, `status: Proposed`, ROADMAP park under
   `### Queue / parked intake`, verified with `roadmap-coverage` not `frontmatter`).
6. **Shell correctness (bash 3.2 / macOS).** `find-xyz.sh` and `install.sh`: quoting, `set -u` safety,
   symlink resolution, exit codes, failure modes that report success. Sandbox interactions
   (`gh` needs the sandbox off; `~/.claude` is write-denied under it).
7. **Degraded paths are honest.** `gh` missing, locator fails, intake repo dirty/off-branch — does the
   skill degrade loudly and correctly rather than guessing?

Flag anything that would make this skill silently file a bug into the wrong place, leak a secret into
a public issue, or corrupt the intake repo's git state. Cite `file:line` for every finding.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Turn 1: agy (Reviewer)
VERDICT: FAIL
Basis: Changes requested

- `[Blocker]` `SKILL.md:93` and `SKILL.md:208`: The placeholder `<SLUG>` in `GH-<n>-<SLUG>.md` and `GH-UNFILED-<SLUG>.md` collides with the `$XYZ_SLUG` variable exported by the locator (which is the repo slug containing a slash, e.g., `owner/repo`). If the agent uses `$XYZ_SLUG`, the file write fails with "No such file or directory". Change these to `<SHORT-SLUG>` to match Step 4 (`GH-<n>-<SHORT-SLUG>.md`).
- `[Blocker]` `SKILL.md:80` and `SKILL.md:96`: The instructions tell the agent to run commands using environment variables (e.g., `gh issue create --repo "$XYZ_SLUG"`, `bash "$XYZ_REPO/utils/..."`). Because AI tool calls use independent, stateless shell sessions, these variables are unset in subsequent steps, causing the commands to fail. Update the instructions to tell the agent to explicitly interpolate the absolute values discovered from the `--check` output instead of relying on shell variable persistence.
- `[Blocker]` `SKILL.md:111`: Frontmatter uses `status: Proposed (1-INBOX — not yet active)`, which violates the exact `status: Proposed` enum matching required by the PDDA contract and DoD point 5. Change to `status: Proposed`.
- `[Should]` `find-xyz.sh:91` exports `XYZ_CALLER` as an absolute path, but `SKILL.md:204` asks the agent to use just the repo name to avoid leaking home directories into public issues. Export and print `XYZ_CALLER_NAME="$(basename "$CALLER_ROOT")"` in `find-xyz.sh` (and in the `--check` output) so the agent has a pre-sanitized name to use.
- `[Should]` `SKILL.md:38`: `eval "$("$L" --env)"` swallows the locator's non-zero exit code if it fails to resolve (because `eval ""` succeeds). Change to `eval "$("$L" --env)" || exit 1` to ensure the script block fails loudly if the locator fails.
- `[Nit]` `find-xyz.sh:86`: The `sed` regex `s#(git@github.com:|https://github.com/)##` misses `ssh://git@github.com/` and `git://github.com/` prefixes, which could result in a malformed repo slug being sent to `gh`. Update the regex to handle these.

### Turn 2: claude-a (Producer)
Disposition for all 6 findings: **5 Implemented, 1 Declined.**

- `[Blocker]` `<SLUG>` / `$XYZ_SLUG` collision — **Implemented.** All template placeholders are now
  `<SHORT-SLUG>` (`SKILL.md:96,146,219`), and `SKILL.md:96` states outright that `<SHORT-SLUG>` is a
  *title* slug while `XYZ_SLUG` is the `owner/repo` origin slug containing a `/`. Naming the
  distinction is what prevents the substitution, not just renaming the token.
- `[Blocker]` env vars don't survive to the next tool call — **Implemented, and the best catch in
  this review.** Correct diagnosis: Claude Code Bash calls persist CWD but not shell state, so a
  later `--repo "$XYZ_SLUG"` expands empty. Added an explicit callout block at `SKILL.md:46-53`
  (re-resolve in the *same* invocation or paste literals; never a bare `$XYZ_*` in a command that
  didn't set it), and scrubbed the three real offenders: `SKILL.md:64` (harness version),
  `SKILL.md:96` (`gh issue create`), `SKILL.md:206` (branch check), plus the `$XYZ_INBOX` write path.
- `[Blocker]` `status: Proposed (1-INBOX — not yet active)` violates a PDDA enum — **Declined; the
  finding is incorrect.** There is no such enum. `PROJECT/PDDA.md:230` specifies the minimum
  frontmatter for a `GH-` inbox capture as `status` = "`Proposed (1-INBOX — not yet active)`" —
  verbatim the string this finding asks me to delete. `PROJECT/PDDA.md:456` further documents
  `status:` as "free-text, unvalidated by design", and `PROJECT/1-INBOX/GH-226-PROVENANCE-SUMMARY-COORDINATION.md`
  carries the long form in-tree. Applying this would have moved the doc *away* from the contract.
  Flagging the pattern, not just the instance: this was graded `[Blocker]` against "the PDDA
  contract" with no citation to it. Per the thread's own rule (GH-173 B3), an uncited conformance
  claim is `[Unverified]` — please cite `file:line` in `PROJECT/PDDA.md` if you still disagree.
- `[Should]` `XYZ_CALLER` absolute vs. "use the repo name" — **Implemented.** `find-xyz.sh` now
  derives `CALLER_NAME` and exports `XYZ_CALLER_NAME` (`find-xyz.sh:93`), `--check` prints it with
  an explicit "use THIS in the public issue, not the path above" pointer, and `SKILL.md:64` harvests
  the name. Real leak risk: these paths carry `/Users/<name>/` and client site names.
- `[Should]` `eval` swallows the locator's exit code — **Implemented.** `SKILL.md:38` is now
  `eval "$("$L" --env)" || exit 1`.
- `[Nit]` slug regex misses `ssh://` and `git://` — **Implemented.** `find-xyz.sh:86-88` handles
  scp-style, `https`, `ssh://`, `git://`, and `www.`, and strips a trailing `/`. Verified against all
  six URL forms; each yields `Owner/repo`.

Also fixed, found by smoke-testing rather than review: `install.sh` reported success when `ln -s`
failed (the sandbox denies writes under `~/.claude`), leaving the skill uninstalled while claiming
otherwise. Now checks the exit and names the sandbox as the likely cause (`install.sh:38-46`).

Re-verified after the changes: `bash -n` clean on both scripts; `--check`/`--env` correct from a
foreign repo, a spaces-in-path repo, a non-git dir (`/tmp`), and with a bogus `XYZ_REPO` override.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
