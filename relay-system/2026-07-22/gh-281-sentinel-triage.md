# RELAY · GH-281 Sentinel/Debug Flywheel — triage adjudication review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-22.
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
6. **Commit only the relay file** (`relay(gh-281-sentinel-debug-flywheel-triage-adjudication-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **GH-281-SENTINEL-DEBUG-FLYWHEEL.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-22

### Review focus (Definition of Done for this turn)
This artifact is a PDDA intake capture that already carries a triage adjudication of GitHub issue
#281 against the repo's rails (GUIDING-PRINCIPLES.md, AGENTS.md, PROJECT/CONSTITUTION.md,
PROJECT/DO-NOT-BUILD.md). Do not re-review the underlying issue's patch detail — review whether the
**adjudication is sound and complete**. Weight your findings on these three, in order:
1. **DO-NOT-BUILD adjudication (finding #1).** Is "Tier-2 issue→PR loop is permitted as private
   unbundled operator tooling, never a public product surface" a defensible reading of the
   anti-scope list, or does it rationalize scope the list means to exclude? Name the strongest
   counter-argument and whether the capture answers it.
2. **Bounded-repair human-gate seam (finding #2).** Is the §2.3↔§2.4 gate ("Gemma-drafted docs are
   `ratings_provisional` and never auto-selectable until a human confirms ratings") actually
   airtight against CONSTITUTION's "bounded pre-approved menu, never open-ended rewrite," or is
   there a path where a provisional doc reaches the nightly marathon fire?
3. **Feedback-loop containment prerequisite (finding #3).** Is "pin the nightly runner to the last
   tagged harness release" a real control given the repo runs no tag cadence today, and is naming it
   a prerequisite sufficient, or does it need a stronger rollback path per AGENTS.md's Costly bar?
Also flag any missing rail the adjudication should have cited, and any finding that is overstated.

### Artifact — GH-281-SENTINEL-DEBUG-FLYWHEEL.md
```
---
gh_issue: 281
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/281
title: "Debug Flywheel a.k.a. Sentinel — opt-in debug capture (public) + private triage overlay"
status: "Proposed (1-INBOX — not yet active)"
created: 2026-07-22
doc_type: feedback
effort: 4
complexity: 4
risk: 4
phases: 7
ratings_provisional: true
---

# GH-281 · Sentinel Pipeline (Debug Flywheel)

Turn the harness's runtime failure/lesson signal into an always-on pipeline —
capture → triage → plan → execute → test → PR → adversarial review — split across a **public,
opt-in, capture-only tier** that never phones home and a **private, unbundled triage overlay**.
The live issue (v3 Draft) owns the full patch-level detail — Stage-0 hook anchors, the two new
Tier-1 scripts (`harvest-findings.sh`, `finding-new.sh`), the `debug.log` JSONL schema, and the
Tier-2 overlay scripts. This capture exists to satisfy the issue-first intake contract, record the
triage + governance adjudication, and fix the execution shape before any promotion to `2-WORKING`.

## Actionable substance (what the issue asks to build)

- **Tier 1 — public, bundled, capture-only.** Opt-in `XYZ_DEBUG_LOG=1` (default OFF). When on, the
  harness appends one PDDA-output-contract JSONL finding per signal it *already* produces
  (escalations 3/4/5/6/7, lane parks exit-8, stale-lock reclaims, builder/reviewer **Side
  Findings**, manual filings) to a single gitignored file `$ROOT/debug.log`. Zero network, no LLM,
  no `gh`, no telemetry. Ships: Stage-0 patch to `marathon-drive.sh` (§1.3), `harvest-findings.sh`,
  `finding-new.sh`, `.gitignore` entry, and a **CI network-guard** grep over bundled paths.
- **Tier 2 — private, NOT bundled.** A local overlay (gitignored dir or separate private repo) that
  reads `debug.log`, classifies with local Gemma, drafts PDDA `1-INBOX` capture docs + a GH-239-shape
  Swarm Preflight Contract (with `fix_probes` + probe-lint), files GitHub issues, fires
  `marathon-drive.sh` serially (N≤2/night, `--require-clean`, `--requires-test`), emits PRs after
  approval, and runs a Gemma post-PR red-team. All network egress lives here.
- **Build order.** Tier 1 Stage-0 patch first (ships dormant, safe alone), then the six Tier-2 steps,
  with auto-promotion (clearing `ratings_provisional` automatically) explicitly **last**.

## Triage & refinement (adjudicated vs GUIDING-PRINCIPLES / AGENTS.md / CONSTITUTION / DO-NOT-BUILD)

Verdict: **high-quality, self-aware v3 plan — accept the direction; gate the execution shape.**
It already grounds itself in PDDA's existing contracts and correctly identifies the no-phone-home
posture as load-bearing. The refinements below are ranked; the first two are governance gates that
must be resolved *in the doc* before promotion, the rest are concrete hardening.

1. **DO-NOT-BUILD adjudication (gate — must be explicit).** DO-NOT-BUILD names "a generic
   multi-agent platform … autonomous issue-to-PR loops" as anti-scope. Tier 2 *is* an
   issue→PR loop. It is **permitted** here because it is (a) private/unbundled operator tooling,
   not a product surface competing with an incumbent, and (b) built by *reusing* PDDA's lifecycle
   + selection rule, not a parallel platform. The anti-scope bar is about shipped product surfaces;
   this stays a local overlay. **Constraint of record: Tier 2 must never be promoted into the
   public package.** Record this adjudication so a future reviewer does not reopen it.

2. **Bounded-repair / human-gate seam (gate).** CONSTITUTION: self-repair "may choose only from a
   bounded, pre-approved menu — never an open-ended rewrite," and destructive actions need an
   explicit human gate. The nightly batch fires a marathon builder (open-ended edit within an
   allowlist). The gate that makes this legal is: **Gemma-drafted docs land `ratings_provisional:
   true` and are never auto-selectable until a human confirms the ratings.** §2.3↔§2.4 must be
   airtight on this — "select eligible `2-WORKING` docs" (§2.4 step 1) must exclude every
   provisional doc. Auto-promotion (build-order step 7) stays last, behind proven precision.

3. **Feedback-loop containment needs a real anchor (Costly surface).** A harness self-fix merged
   tonight changes tomorrow's overlay. The plan's fix — pin the nightly runner to the last *tagged*
   harness release, not HEAD — depends on a tag cadence the repo doesn't yet run (RELEASES.md is a
   planning ledger, not a tag stream). Surface "a tagged release to pin to" as a Tier-2
   **prerequisite**. Per AGENTS.md, anything touching relay containment / harness self-modification
   is **at least Costly**; it needs a rollback path.

4. **Probe-lint is the load-bearing deterministic gate (Principle 12 + deterministic-before-LLM).**
   The worst Tier-2 failure is an inverted `fix_probe` → STALE exit-4 *false completion* (the named
   GH-239 trap). Probe-lint (run each probe; require it to currently *detect* the bug before the doc
   leaves `1-INBOX`) must be specified as a **required deterministic gate**, not advisory prose —
   it is the independent verification separating "capture" from "unattended fixing."

5. **Execution shape — umbrella, not one lane.** This is a 7-step, two-tier program. Per the GH-275
   precedent, **capture as an umbrella; do not fire as one marathon lane.** Only the **Tier-1
   Stage-0 patch** is marathon-ready today (opt-in, default-off, additive, one gitignored file,
   crisp §1.7 acceptance checks — risk 2 on its own). Tier 2 stays an operator-run private overlay,
   never a public marathon lane.

6. **CI network-guard: pin the bundled-path set (concrete).** §1.7#6 greps `relay-automation/` for
   `curl`/`wget`/`nc`/`gh `/`/dev/tcp`/`http`. Tier 1 adds `harvest-findings.sh` +
   `finding-new.sh` — the guard must cover wherever those land, and must explicitly carve out the
   one legitimate network step (`pdda.sh gh-refresh`) so the guard doesn't false-positive on it.

7. **Namespace `debug.log` (concrete, cheap).** A root-level `debug.log` is generic enough to
   collide with a consumer repo's own debug output in a vendored `.xyz/` install. Prefer a
   namespaced default (`XYZ.debug.log` / `.xyz-debug.log`) mirroring the existing `XYZ.json`
   telemetry convention. Keeps the opt-in artifact unambiguous.

8. **Where Tier 1 is already strong (keep).** Default-off byte-identical behavior (acceptance #1),
   six runnable acceptance checks incl. the network grep and JSONL round-trip, Side Findings as
   record-only (off-lane edits reverted → containment preserved), and reuse of PDDA's
   output-contract JSONL rather than inventing a schema. These satisfy Principles 3/6/7/8/10 and the
   four pillars — no change needed.

## Recommended next step

Promote **only** the Tier-1 Stage-0 slice to `2-WORKING` with a Swarm Preflight Contract once a
human clears the provisional ratings; hold Tier 2 as a separate, operator-run private-overlay effort
gated on findings #1–#4. Ratings above (`4/4/4/7`) are for the whole program and provisional; the
Tier-1 slice alone is ~risk 2. `risk >= 4` ⇒ **route-to-human**, so nothing here auto-selects.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
