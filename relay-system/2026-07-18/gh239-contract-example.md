# RELAY · GH-239 J2: ship CONTRACT.example.md + exit-3 skeleton
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-18.
-->

NEXT: Producer
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
6. **Commit only the relay file** (`relay(gh239-contract-example): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifacts (Producer may create/edit ONLY these):
  - `relay-automation/CONTRACT.example.md` — **new file**, the deliverable
  - `utils/swarm-preflight.sh` — exit-3 message only
  - `test/swarm-preflight.sh` — regression coverage for the new message
- Source of truth for the task: [`PROJECT/2-WORKING/GH-239-PREFLIGHT-CONTRACT-EXAMPLE.md`](../../PROJECT/2-WORKING/GH-239-PREFLIGHT-CONTRACT-EXAMPLE.md)
- Reviewer: agy   ·   Producer: codex
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
