# RELAY · QA the file-xyz-bug cross-repo bug intake skill
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-18.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
