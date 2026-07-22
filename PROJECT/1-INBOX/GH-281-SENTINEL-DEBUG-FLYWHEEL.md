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
   issue→PR loop. **Adjudicated (relay Blocker, accepted):** "private/unbundled" is *not* a stated
   DO-NOT-BUILD exception, and an in-doc "do not reopen this" note conflicts with the list's canonical
   reconsideration process (a *measured incumbent gap* + a coordinated DO-NOT-BUILD **and** synthesis
   amendment — DO-NOT-BUILD.md:54-59). Resolution: Tier 2 is **operator-owned experimentation that
   lives outside this repo's public delivery scope** (a gitignored dir or a separate private repo) —
   DO-NOT-BUILD governs what *this repo builds and ships*, so it does not reach a private overlay that
   is never packaged. The moment Tier 2 is proposed *for this repo* (bundled, a product surface, or a
   shipped `sentinel-*` script), it re-enters scope and must go through the canonical reconsideration
   process — recording the measured gap and amending DO-NOT-BUILD + the synthesis together — not a
   unilateral capture note. So the constraint is not "never reopen"; it is "reopening requires the
   documented amendment path."

2. **Bounded-repair / human-gate seam (gate).** CONSTITUTION: self-repair "may choose only from a
   bounded, pre-approved menu — never an open-ended rewrite," and destructive actions need an
   explicit human gate (CONSTITUTION.md:24-26,33-37). The nightly batch fires a marathon builder
   (open-ended edit within an allowlist). **Adjudicated (relay Blocker, accepted — this corrects my
   first draft):** the `ratings_provisional` guard as I first stated it is *not* airtight, two ways.
   (a) **The canonical PDDA predicate gates only on `risk`** (`eligible = risk <= 2`, PDDA.md:125-131)
   — it does **not** mention `ratings_provisional`, so a plan that "reuses PDDA's rule verbatim" does
   *not* inherit the provisional guard; it must be added as a **separate deterministic check**.
   (b) **Build-order step 7 auto-clears the provisional flag**, which reopens the exact unattended-fire
   path this finding claims to close. Hardened requirement: (1) **no automatic clearing of
   `ratings_provisional` — ever;** (2) promotion requires an **explicit human attestation bound to the
   doc revision, the approved allowlist, and the specific run** (rating-confirmation alone is not the
   authorization CONSTITUTION requires for an open-ended builder edit); (3) a **deterministic reject of
   any provisional/unattested doc at BOTH selection time and immediately before fire**; (4) any future
   auto-promotion is a **separate constitutional/policy decision**, not something earned by "proven
   precision." Build-order step 7 is struck as written.

3. **Feedback-loop containment needs a rollback path, not just a dependency (Costly surface).** A
   harness self-fix merged tonight changes tomorrow's overlay. The plan's fix — pin the nightly runner
   to the last *tagged* harness release, not HEAD — depends on a tag cadence the repo doesn't yet run
   (RELEASES.md is a planning ledger, not a tag stream). **Adjudicated (relay Should, accepted):**
   naming a tag as a prerequisite is a *dependency*, not the rollback path AGENTS.md's Costly bar
   requires. A tag alone is not the control. Required: (1) an **immutable release commit/artifact**;
   (2) a **recorded last-known-good pin**; (3) a **tested operator procedure to disable the nightly job
   and restore that pin**; (4) **no newly merged self-fix enters the runner until an explicit release
   promotion** bumps the pin. This is the rollback path; the tag is just its handle.

3b. **Measured-gap bar for new Bash/policy (relay Should, accepted).** DO-NOT-BUILD.md:21,54-59 sets
   the bar: new Bash/policy complexity is justified only by a *measured gap*, not a nice-to-have. My
   first draft cited this rail for the *shape* but not for the *new scripts*. State the observed gap
   explicitly: the harness **already produces** these signals (escalations, lane parks, stale-lock
   reclaims, side findings) but they are **ephemeral — emitted to a transcript/exit code and lost at
   turn end, never systematically captured or triaged**; that loss is the measured gap the two Tier-1
   scripts + the overlay address. Each new script must still show it is the **least-code** response
   (e.g. why the append helper can't just reuse an existing PDDA writer).

4. **Probe-lint is the load-bearing deterministic gate (Principle 12 + deterministic-before-LLM).**
   The worst Tier-2 failure is an inverted `fix_probe` → STALE exit-4 *false completion* (the named
   GH-239 trap). Probe-lint (run each probe; require it to currently *detect* the bug before the doc
   leaves `1-INBOX`) must be specified as a **required deterministic gate**, not advisory prose —
   it is the independent verification separating "capture" from "unattended fixing."

5. **Execution shape — umbrella, not one lane.** This is a 7-step, two-tier program. Per the GH-275
   precedent, **capture as an umbrella; do not fire as one marathon lane.** The **Tier-1 Stage-0
   patch** is the **proposed first shippable slice** (opt-in, default-off, additive, one gitignored
   file, six §1.7 acceptance checks). **Adjudicated (relay Should, accepted):** it is *proposed*, not
   verified "marathon-ready today" — its ~risk-2 rating, its acceptance checks, and its principle
   coverage are **design claims, unrun in this capture**. It becomes ready only after (a) its own
   human-confirmed ratings on the promoted `2-WORKING` slice and (b) a green run of the §1.7 checks.
   Tier 2 stays an operator-run private overlay, never a public marathon lane.

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
   output-contract JSONL rather than inventing a schema. These are **designed to** satisfy Principles
   3/6/7/8/10 and the four pillars; treat that as a design claim to confirm at the promoted-slice
   gate, not verified here (relay Should, accepted).

## Relay adjudication (Codex reviewer, Round 1 — 2026-07-22)

A headless `/relay-xyz` review turn (Codex builder, `--review-once`, review-only) stress-tested this
adjudication against the rails. Verdict: **Changes requested** — 2 Blockers + 3 Shoulds, all cited to
`file:line`, all **accepted** (none overstated). The full block is in
[relay-system/2026-07-22/gh-281-sentinel-triage.md](../../relay-system/2026-07-22/gh-281-sentinel-triage.md).
Two caught real holes in my *first* draft, now fixed above: (1) I asserted a "private/unbundled"
DO-NOT-BUILD exception that isn't canonical and told reviewers not to reopen it (finding #1); (2) my
build-order concession auto-cleared the `ratings_provisional` flag, reopening the unattended-fire
path finding #2 claimed to close — and the canonical PDDA predicate gates only on `risk`, so the
provisional guard was never inherited "for free" (finding #2). Findings #4/#6/#7 passed as
appropriately bounded. Verified independently before accepting: PDDA.md:125-131 confirms
`eligible = risk <= 2` with no provisional term.

## Recommended next step

Promote **only** the Tier-1 Stage-0 slice to `2-WORKING` with a Swarm Preflight Contract once a human
records an explicit attestation (per finding #2) — not merely clearing provisional ratings. Hold
Tier 2 as a separate, operator-run private-overlay effort **outside this repo's delivery scope**
(finding #1), gated on findings #2/#3/#3b. Ratings (`4/4/4/7`) are for the whole program and
provisional; `risk >= 4` ⇒ **route-to-human**, so nothing here auto-selects. The Tier-1 slice's own
lower rating is a design claim to confirm on promotion, not a verified fact of this capture.
