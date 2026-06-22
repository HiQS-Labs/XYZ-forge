# RELAY · permission-inheritance-check SKILL review — AUTOMATED (headless, agy reviewer)
<!--
  Path A (headless single-session): Claude-A is the Producer presenting the artifact;
  agy (Antigravity CLI) is the Reviewer subprocess driven by relay-drive.sh + agy-turn.sh.
  Whose-turn is the tick PIC-TURN token, NOT the NEXT line (NEXT mirrors it for humans).
  STATUS is the terminal signal. CROSS-REPO: the artifact lives in a DIFFERENT repo than
  this harness, so it is referenced by ABSOLUTE path below (agy resolves relatives vs CWD).
-->

NEXT: Reviewer (agy) — review the skill and return graded findings + a verdict
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — tick-native (headless agy reviewer)
You are the **Reviewer**. The supervisor invokes you only when the PIC-TURN token is yours. Then:
1. **Read this whole file.**
2. **Take the token:** `./bin/tick claim PIC-TURN --agent agy` (it is handed to you), then `./bin/tick ping PIC-TURN --agent agy`.
3. **Review the artifact** (absolute path — read it directly; cite `file:line`):
   `/Users/noelsaw/Documents/GH Repos/WP-DB-Toolkit/experiments/inheritance-check/permission-inheritance-check-SKILL.md`
   - Produce **graded findings** (`[Blocker]` / `[Should]` / `[Nit]` / `[Pass]`) and a **Verdict** (APPROVED or REQUEST CHANGES).
   - Judge the skill on its own terms: are the INH-1…INH-7 invariants sound and falsifiable, is the allowlist/exception logic safe, is the effective-permission resolution well-defined, are there gaps or contradictions? **Do NOT edit the artifact** — reviewer appends findings only.
4. **Append ONE block** at the bottom, above the marker (`### Round N · Reviewer · agy · <ts>`).
5. **Hand off / close:**
   - REQUEST CHANGES → `./bin/tick release PIC-TURN --to claude-a` (routes the token back to the Producer).
   - APPROVED → set `STATUS: Approved` here **and** `./bin/tick done PIC-TURN --agent agy`.
6. Update the `NEXT:` mirror. **Do NOT run git — the harness commits for you (no push).**

## Setup
- Artifact under review: `/Users/noelsaw/Documents/GH Repos/WP-DB-Toolkit/experiments/inheritance-check/permission-inheritance-check-SKILL.md` (v0.1 skill spec — a modeled Tenant→User→Role permission-inheritance sanity check).
- Definition of Done: the skill's inheritance invariants + exception allowlist are sound, falsifiable, and free of contradictions — or the Reviewer names the gaps.
- Producer: **Claude-A** (this/main window)   ·   Reviewer: **agy** (Antigravity CLI, headless subprocess).
- Handoff: **Path A headless single-session** — relay-drive.sh supervises; agy-turn.sh takes the agy turn; turn-token = tick `RELAY-TURN`.
- Independence note: agy is a distinct model gateway from the authoring Claude, so this is a genuine cross-model review (not a same-model dogfood).
- Started: 2026-06-21

## Ground rules
1. Single source of truth. Whose-turn = the tick `RELAY-TURN` token; `STATUS` here is the terminal signal.
2. Reviewer never edits the artifact — appends findings to THIS file only.
3. One block appended at the bottom, above the marker. Never edit earlier turns.
4. Close requires `STATUS: Approved` **and** `tick done RELAY-TURN` (else the supervisor escalates).
5. The harness commits file-scoped at handoff; turn-takers do not run git.

## Roles
- **Producer (Claude-A)** — presents the artifact; disposes findings; edits the skill.
- **Reviewer (agy)** — graded findings + verdict; never edits the artifact.

---
## Log

### Round 1 · Producer · Claude-A · 2026-06-21 12:54 PDT
**Presenting** `/Users/noelsaw/Documents/GH Repos/WP-DB-Toolkit/experiments/inheritance-check/permission-inheritance-check-SKILL.md` for review — a v0.1 skill spec that sanity-checks **modeled** permission inheritance (the Tenant→User→Role matrix a user designs *inside* an app, not the app's own auth/RLS). It defines seven invariants (INH-1 owner-holds-ownership, INH-2 subset-not-superset, INH-3 inheritance-traces-to-an-edge, INH-4 no-cross-tenant-bleed, INH-5 masking-survives-inheritance, INH-6 revocation-cascades, INH-7 owner-reachability) plus an explicit `permissionExceptions[]` allowlist that downgrades matched findings to `exception` rather than dropping them.
**Review focus / open questions:**
1. Are INH-1…INH-7 each genuinely **falsifiable** and non-overlapping, or do any two collapse into the same check?
2. Is the **exception/allowlist** semantics safe — can a crafted exception entry silently suppress a real escalation (INH-2/INH-4)?
3. Is the **effective-permission resolution** (role grants + inherited/delegated edges + `parentTenantId` chain) well-defined enough to implement deterministically, or are there ambiguous/cyclic cases?
4. Any missing invariant a real modeled permission matrix would need?
**Handing the token to agy for review.**

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
