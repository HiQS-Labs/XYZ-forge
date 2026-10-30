# RELAY · T3 fork GH1 Kimi terminal auth final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(t3-fork-gh1-kimi-terminal-auth-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/final-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/.codex/task-artifacts/t3code-fork-gh1-kimi-auth/final-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: author
- Started: 2026-10-30
- Definition of Done: Evaluate final-packet.md against its stated requirements, source diff and verification receipt; code revision cf236c223c2945e8b7a741266b69af8851c642af. Review the full supplied source and focused compatibility scope; no artifact edits.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 1
Implementation and verification are complete for independent review. No full browser/account session is claimed.
VERDICT: PASS
Basis: Required check:changed gate and runtime login-command smoke pass; final approval belongs to reviewer.

### Reviewer · Round 1
Ship within the packet's stated compatibility and verification scope.

VERDICT: PASS
Basis: The complete supplied diff and all five full source files implement the bounded plan without a concrete blocking finding. Source review supports legacy terminal routing, modern precedence, environment ordering, PTY filtering and session verification before success. Execution results below remain producer-reported evidence, not a reviewer rerun.
swept file: yes

- [Pass] Legacy resolution is bounded and shared: `probe.ts:102` decodes a nonempty command, optional string-array argv and optional string-record env; `probe.ts:125`–`127` returns the legacy command and replacement argv. `auth.ts:121` and `auth.ts:280` use that same resolver for discovery and execution. No provider-specific branch or new transport is introduced. No fix requested.
- [Pass] Modern precedence is preserved: `probe.ts:114`–`121` selects modern terminal spawn plus appended method args first, then rejects legacy fallback for any explicit type. Malformed legacy metadata returns no terminal recipe (`probe.ts:122`–`123`); explicit agent and malformed examples are present in `apps/server/src/provider/AcpRegistryProbe.test.ts:159`–`175`. The source also preserves explicit env_var precedence through the same early return. No fix requested.
- [Pass] Runtime behavior preserves the existing boundary: `auth.ts:177` merges base -> resolved spawn -> login env; `auth.ts:123` filters terminal discovery without a PTY and `auth.ts:162`–`166` rejects terminal execution without one. `auth.ts:282` closes the original ACP scope before PTY login; `auth.ts:286`–`301` reconnects and awaits session start before `auth.ts:327` calls `onChanged(true)`. Existing cancellation and failed-verification cases remain in `auth.test.ts:348`–`384`. No fix requested.
- [Pass] The Vite prerequisite is minimal: `apps/web/vite.config.ts:328` uses `NodeURL.fileURLToPath(new URL(...))` for the existing alias, correctly decoding a spaced file path without changing its destination. No fix requested.
- [Pass] Packet consistency probe: command `PYTHONDONTWRITEBYTECODE=1 python3 .relay-scratch/check-packet.py`, exit 0. Decisive output: `PASS: 20 new-side hunks match 5 nonempty full files`; sensitivity output: `RED CONTROL: in-memory resolver mutation rejected at ('packages/provider-acp-registry/src/server/probe.ts', 99)`. The stdlib parser compares each new-side diff hunk with its full-file line range; changing only the in-memory legacy command schema to `Schema.String` makes the comparison fail. The seeded artifact was untouched. Evidence location: `.relay-artifacts/final-packet.md`, “Committed diff” and all five “Full file” sections. This checks packet consistency, not runtime behavior. No fix requested.
- [Unverified — needs clone run] The packet's “Verification receipt” reports a pre-fix red regression, 8 auth / 12 probe passes, and `vp run check:changed` passing on revision `cf236c223c2945e8b7a741266b69af8851c642af`. Its runtime transcript reports device-login prompts for 1.52.0 and 2.3.1, explicitly says “account completion not attempted,” and leaves independent current-home credential verification pending. These claims were assessed against the supplied assertions and transcript; no suite, fixture, browser/account login, or paid turn was executed here. Harness verification remains separate; this approval does not attest a completed integrated account login.

Full sweep included pre-existing normalization, probe/management, browser/env-var authentication, PTY cleanup, tests and Vite configuration. No additional concrete pre-existing defect was found in the supplied files. Reversibility: Easy for the bounded resolver/caller and alias changes; the packet's rollback requires no schema migration.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
