# RELAY · GH-281 items 1&2 QA — driver hooks + Tier-2 overlay
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-22.
-->

NEXT: —
STATUS: Approved
ROUND: 1 / 2

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
6. **Commit only the relay file** (`relay(gh-281-hooks-overlay-qa): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-22
- **Artifacts under review** (on branch `gh-281-driver-hooks`, read the files directly):
  - **Item 1 — Tier-1 driver hooks:** `relay-automation/marathon-drive.sh` (the six §1.3 Sentinel
    hooks: opt-in defaults, `_json_esc`/`xyz_debug_log_append`, escalation/lane-park/stale-lock hooks,
    Side Finding prompt in the `RELAY_EOF` heredoc, harvest on escalate/save_transcript) and its test
    `test/sentinel-driver-hooks.sh`.
  - **Item 2 — Tier-2 overlay:** everything under `sentinel-overlay/` (`lib/config.sh`,
    `lib/classify.sh`, `lib/gh.sh`, `lib/probe-lint.sh`, `sentinel-triage.sh`, `sentinel-nightly.sh`,
    `pr-emit.sh`, `adversarial-review.sh`, `morning-report.sh`, `README.md`,
    `config/runtime.env.example`, `config/.gitignore`) and its test `test/sentinel-overlay.sh`.
  - Design of record: `PROJECT/2-WORKING/GH-281-SENTINEL-TIER2-OVERLAY.md`.
- **Context (do NOT fault as gaps):** validate.sh full suite is already green; Tier-1 capture scripts
  shipped in #285; driver-hook self-edit was applied by hand (no live marathon runs it). Posture is
  deliberate: overlay code IS in the public repo for transparency; only `runtime.env` is gitignored.

- **Definition of Done — grade against these, in priority order:**
  1. **Inert-by-default / call-home-off (THE safety invariant).** With no `runtime.env`, can ANY
     overlay path reach the network, `ollama`, `gh`, a marathon fire, or a `git push`? Is
     `lib/config.sh::sentinel_active` truly the single gate, and does every egress route through
     `lib/classify.sh` / `lib/gh.sh`? Can the static guard or the inert test be evaded (e.g. an egress
     call built from a variable, an entrypoint that acts before the gate)?
  2. **Escaping consistency (GH-281 relay lesson).** `_json_esc` in `marathon-drive.sh` and the
     overlay must normalize the FULL C0/DEL control range + escape backslash/quote — same fix the
     Codex relay forced on `finding-new.sh`. Any field interpolated into JSON unescaped? Any emitter
     that can produce invalid JSONL?
  3. **Default-off byte-identity (item 1).** With `XYZ_DEBUG_LOG` unset, is `marathon-drive.sh`
     behavior unchanged? The lane-park hook rewrote the `lane_attempt_gate` call site — same exit
     semantics on every rc? Mirror block that `test/lane-attempt-cap.sh` diffs still untouched?
  4. **Portability.** macOS bash 3.2 (no `mapfile`, `${arr[@]}`-under-`set -u` traps). Any bash-4-ism?
  5. **Deterministic-before-LLM & verified-success-only.** Are the tests genuine (real fixtures, real  [Unverified — no citation]
     assertions), or do they pass vacuously? Does probe-lint enforce the correct GH-239 polarity?
  6. **Skill-first / measured-gap / DO-NOT-BUILD.** Reinvention where a shipped helper exists? Scope
     creep toward a generic platform beyond the measured gap?
  Cite `file:line` for every finding. Grade `[Blocker]/[Should]/[Nit]/[Pass]`, then a single
  **Verdict** (Approved | Changes requested | Blocked). Reviewer does NOT edit — findings only.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer (agy) — Round 1

All Definition of Done criteria are met. The Tier-1 driver hooks safely degrade to no-op when inactive and correctly normalize JSON strings. The Tier-2 overlay preserves the strict inert-by-default safety invariant.

- `[Pass]` **Inert-by-default / call-home-off**: `sentinel-overlay/lib/config.sh:16` serves as the single active gate. All egress routes strictly through the wrappers, verified by static regex in `test/sentinel-overlay.sh:17`. Wrappers safely return 1 (e.g. `sentinel-overlay/lib/gh.sh:11`), and un-gated scripts like `pr-emit.sh:22` safely exit when the wrapper fails.
- `[Pass]` **Escaping consistency**: `relay-automation/marathon-drive.sh:288` correctly scrubs controls (`tr '\000-\037\177' ' '`) and escapes backslash/quotes sequentially. Interpolated fields (`sev`, `chk`) bypass `_json_esc` but are hardcoded safe strings (e.g. `error`, `marathon.escalation`).
- `[Pass]` **Default-off byte-identity**: With `XYZ_DEBUG_LOG` unset, the logger short-circuits (`marathon-drive.sh:293`). The `lane_attempt_gate` RC capture matches previous exit semantics exactly (`marathon-drive.sh:885`), and the mirror block is untouched.
- `[Pass]` **Portability**: Safe Bash 3.2 array usage. `sentinel-overlay/sentinel-nightly.sh:27` guards the loop with `${#eligible[@]} -eq 0`, and `marathon-drive.sh:359` guards `read -ra` with a `-n` check, avoiding `set -u` unbound traps on empty arrays.
- `[Pass]` **Deterministic-before-LLM**: Real test fixtures. `test/sentinel-overlay.sh:30` employs fail-loud path stubs to prove the inert state. `sentinel-overlay/lib/probe-lint.sh:23` accurately maps `rc != 0` to "detects" for command probes (GH-239 polarity).
- `[Pass]` **Skill-first / measured-gap**: Clean separation. The logic is constrained to `sentinel-overlay/` rather than bloating the main marathon harness. 

**Verdict:** Approved

### Producer · claude-a · disposition

Agy Approved both items with all-[Pass], cited. Spot-verified the load-bearing claims against the code (Principle 12) — they match my build-time verification (full `validate.sh` green, `test/sentinel-overlay.sh` proves inert-by-default zero-egress, `test/sentinel-driver-hooks.sh` proves default-off + on-mode append). Agy's one observation (`sev`/`chk` bypass `_json_esc`) is correct and safe: both are internal literals (`error`/`warn`/`info`, `marathon.*`), never user/finding-derived — no change needed. No open findings. Relay closed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
