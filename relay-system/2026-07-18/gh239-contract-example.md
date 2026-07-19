# RELAY · GH-239 J2: ship CONTRACT.example.md + exit-3 skeleton
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-18.
-->

NEXT: Producer
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
6. **Commit only the relay file** (`relay(gh239-contract-example): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifacts (Producer may create/edit ONLY these):
  - `relay-automation/CONTRACT.example.md` — **new file**, the deliverable
  - `utils/swarm-preflight.sh` — exit-3 message only
  - `test/swarm-preflight.sh` — regression coverage for the new message
- Source of truth for the task: [`PROJECT/2-WORKING/GH-239-PREFLIGHT-CONTRACT-EXAMPLE.md`](../../PROJECT/2-WORKING/GH-239-PREFLIGHT-CONTRACT-EXAMPLE.md)
- Reviewer: claude-a   ·   Producer: agy
  <!-- Roles swapped 2026-07-18 after round 1 aborted: codex-cli 0.139.0 is pinned to model
       gpt-5.6-terra and the API rejects it (400, "requires a newer version of Codex"), so the
       codex builder is unusable on this device until its CLI is upgraded. agy takes the build
       lane; Claude Code reviews, which is the documented default role split (GH-221). -->

- Started: 2026-07-18
- Lane: J2 of [MARATHON-PLAN-2026-07-18-J](../../PROJECT/2-WORKING/MARATHON-PLAN-2026-07-18-J-VENDORED-CONSUMER-DX.md). **Lane J1 (#238) is NOT part of this relay — do not touch `relay-automation/marathon-drive.sh`.**

### The problem being solved

`utils/swarm-preflight.sh` rejects any `--gh-issue` whose capture doc lacks a machine-readable
preflight contract (exit 3). The gate is correct, but **no example contract ships anywhere in the
install**, so a new consumer of a vendored `.xyz/` hits exit 3 as their first interaction with
nothing to copy. The schema exists only in `utils/swarm-preflight.sh:24-36`'s own header comment.

Real filled-in contracts exist in this repo's `PROJECT/**/GH-*.md` docs — but `PROJECT/**` is not
part of a vendored install, so they are invisible to the audience that needs them. Consumers
therefore skip preflight entirely and hand-author a `MARATHON.yaml` (which *does* ship an example),
bypassing the freshness / fix-required / collision gates.

### Definition of Done

1. `relay-automation/CONTRACT.example.md` exists: a complete, realistic capture doc with a filled-in
   `## Swarm Preflight Contract` JSON block, **annotated per field** — mirroring how
   `relay-automation/MARATHON.example.yaml` earns its keep. Read that file first and match its
   register (header comment block explaining each field, then a worked example).
2. It states **`fix_probes` polarity explicitly and unmistakably**: probes detect the **bug**, not the
   fix. `grep_present` = bug evidence still there; `grep_absent` = fix marker not yet landed.
   It must name the consequence of inverting them — preflight returns **STALE (exit 4)**, which reads
   as "already done": a *false completion signal*. This is the single most-mistaken field; give it
   the most annotation.
3. `utils/swarm-preflight.sh`'s exit-3 path prints a **minimal valid contract skeleton** and names the
   file it belongs in. The message must contain the literal phrase `minimal valid contract` (the
   preflight probe for this lane greps for it).
4. `test/swarm-preflight.sh` covers the new exit-3 message.
5. `bash validate.sh` no worse than baseline. **Baseline is NOT green** — see #170 / #232 for the
   ~9-12 known pre-existing failures. Do not "fix" unrelated reds; do not treat them as your bug.

### Constraints

- **Do not touch `relay-automation/marathon-drive.sh`** — that is lane J1, a separate fire.
- If your change lands anything under `relay-automation/`, the vendored `relay-pkg.tar.gz` goes stale.
  Note it in your turn block; the orchestrator re-runs `skills/relay-automation/make-pkg.sh`.
- No push. Commit locally, file-scoped, per the turn protocol above.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Turn 1: agy (Producer)
Implemented the requested changes for GH-239:
- Created `relay-automation/CONTRACT.example.md` with detailed per-field annotations and an explicit explanation of `fix_probes` polarity (detecting the bug, not the fix) and the consequence of returning STALE (exit 4).
- Modified `utils/swarm-preflight.sh` to print a minimal valid contract skeleton and name the file it belongs in when an exit-3 (contract missing) occurs. The message contains the literal phrase "minimal valid contract".
- Updated `test/swarm-preflight.sh` to cover the new exit-3 message (verifying the literal phrase and the file name).
- Note: This change lands a new file under `relay-automation/`, so the vendored `relay-pkg.tar.gz` will go stale and need a re-run of `skills/relay-automation/make-pkg.sh` by the orchestrator.

### Turn 2: claude-a (Reviewer)

**Verdict: Changes requested.** DoD 2 and 3 are met well; DoD 1 is not — the shipped example
teaches several things the repo's own real contracts don't do.

- `[Pass]` **DoD 2 — polarity is explicit and correct.** `CONTRACT.example.md:16-26` states
  "POLARITY: Probes detect the **bug**, NOT the fix", enumerates all five probe types with correct
  senses (`grep_present` = "bug evidence … still in the file", `grep_absent` = "fix marker has not
  yet landed"), and names the consequence: "will cause preflight to return **STALE (exit 4)**, which
  reads as 'already done' — a false completion signal". This was the highest-risk requirement and it
  landed cleanly.
- `[Pass]` **DoD 3 — exit-3 message.** `utils/swarm-preflight.sh:527-541` emits the literal phrase,
  names `$doc`, points at `relay-automation/CONTRACT.example.md`, and prints a real skeleton with
  `target`/`gate`/`fix_probes`/`artifacts`. Verified new: `git show 4b32bd3:utils/swarm-preflight.sh
  | grep -c "minimal valid contract"` → `0`.
- `[Pass]` **DoD 4 — test coverage.** `test/swarm-preflight.sh:160-161` asserts both the phrase and
  the doc name in T6's output.
- `[Blocker]` **The example's own contract is permanently STALE.** Its sole probe is
  `{"type": "path_absent", "path": "relay-automation/CONTRACT.example.md"}` — a file that now exists,
  by construction. Run this example and preflight returns exit 4 "already landed": precisely the
  false-completion failure the annotation above it warns against. A teaching artifact must not
  demonstrate the trap it documents. **Fix:** make the worked example a *fictional* lane (e.g. a
  `GH-900` bug in `src/widget.js`) whose probes are internally consistent and would actually fire.
- `[Should]` **No frontmatter — a consumer copying this produces a non-PDDA doc.** Every real capture
  doc here opens with `gh_issue`/`status`/`doc_type`/`complexity`/`risk`/`effort`/`non_goals`/`goal`
  (see `PROJECT/2-WORKING/GH-225-ISOLATION-WORKTREE-STALE-BASE-GUARDRAIL.md:1-26`). The example has
  none, so it under-teaches the format it exists to teach. **Fix:** add representative frontmatter.
- `[Should]` **`lanes` is annotated but absent from the worked JSON.** `CONTRACT.example.md:14`
  documents it; the block at `:34-50` omits it. Document-then-omit is the weakest teaching pattern.
  **Fix:** include `"lanes": { "agy_safe": [...], "orchestrator_only": [...] }` in the example.
- `[Should]` **`remediation.criteria` is vacuous.** "Implement the example contract file as per
  requirements." carries no verifiable acceptance signal; real ones state what must be true (compare
  GH-225's). A copied vacuous criteria field propagates. **Fix:** write a concrete, checkable string.
- `[Nit]` **`artifacts` annotation is factually wrong.** `:11` says "Comma-separated list", but the
  JSON at `:43-45` is a JSON array — and an array is what the parser wants. Fix the prose.

**Not blocking, orchestrator action:** this turn landed a new file under `relay-automation/`, so the
vendored `relay-pkg.tar.gz` is now stale (agy flagged this correctly in Turn 1). `make-pkg.sh` needs
re-running once the artifact is final — deferred until after the fixes above, not done now.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
