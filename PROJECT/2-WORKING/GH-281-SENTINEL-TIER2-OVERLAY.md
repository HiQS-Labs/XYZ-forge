---
gh_issue: 281
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/281
title: "Sentinel Tier-2 overlay — transparent in-repo code, gitignored activation, inert by default"
slug: sentinel-tier2-overlay
status: Active
created: 2026-07-22
updated: 2026-07-22
owner: Noel (operator) · Claude (builder)
branch: main
doc_type: project
goal: >
  Ship the full Sentinel Tier-2 triage overlay (reader → Gemma classify → draft PDDA doc → file
  issue → nightly batch → PR-emit → adversarial review → morning report) as visible reference code
  in the public repo, with ALL call-home paths gated behind a gitignored local runtime config so a
  downstream clone is completely inert (no network, no LLM, no GitHub) until the operator opts in.
effort: 4
complexity: 4
risk: 3
phases: 7
ratings_provisional: true
non_goals:
  - Not adding any egress to Tier-1 bundled capture (that stays provably zero-network)
  - Not auto-merging fixes; the human keeps the two irreversible edges (what to run, what to ship)
  - Not committing the runtime activation config (credentials / enable flag / target registry)
related:
  - PROJECT/2-WORKING/GH-281-SENTINEL-TIER1-STAGE0.md   # Tier-1 (shipped, Codex-approved, merged #285)
  - PROJECT/1-INBOX/GH-281-SENTINEL-DEBUG-FLYWHEEL.md   # umbrella capture + governance adjudication
---

# GH-281 · Sentinel Tier-2 overlay (transparent code, gitignored activation)

## Status

| What was just completed | What's next |
|---|---|
| Operator revised the Tier-2 posture: ship the whole overlay as transparent in-repo reference code, gate activation behind gitignored runtime config, inert by default. | Build the overlay against the inert-by-default invariant; prove call-home-off with a test + static guard. |

## Revised posture (supersedes finding #1's "gitignored dir / outside delivery scope")

The earlier plan hid Tier-2 in a gitignored `sentinel-overlay/` dir "outside this repo's delivery
scope." That undersold transparency: a public repo should show *exactly* what its private side does,
including the call-home paths. Revised model:

- **Code is public.** Every overlay script is committed — full transparency on the mechanism.
- **Activation is local.** The ONLY gitignored artifact is the runtime config
  (`sentinel-overlay/config/runtime.env`) holding the enable flag, model endpoint, GitHub usage, and
  target registry. A committed `runtime.env.example` documents it.
- **Inert by default (hard invariant).** With no `runtime.env` (or `SENTINEL_ENABLE` != 1), the whole
  overlay is a clean no-op: no network, no `ollama`, no `gh`, no marathon fire, no PR push. This is
  the "call home is definitely off" guarantee, and it is **tested**, not asserted.

This keeps every CONSTITUTION non-negotiable: local-first, no hidden cloud sync, reversibility, and
verified-success-only. The public ships the whole package; nothing calls home unless the operator
configures it on their own machine.

## Inert-by-default enforcement (the safety spine)

1. **Single gate** — `lib/config.sh::sentinel_active()` returns true only when `runtime.env` exists
   AND `SENTINEL_ENABLE=1`. It is the one place activation is decided.
2. **Gated wrappers** — the ONLY code allowed to touch network/LLM/GitHub lives in `lib/classify.sh`
   (ollama), `lib/gh.sh` (GitHub), and the fire/push steps. Each calls `sentinel_active` first and
   refuses (clean no-op, non-zero only if explicitly invoked in an enabled context) otherwise.
3. **Static guard** — `test/egress-static-guard.sh`: no overlay file outside those wrappers may
   contain `curl|wget|nc|/dev/tcp|http|ollama |gh `; all egress must route through the wrappers.
4. **Behavioural proof** — `test/inert-by-default.sh`: with no `runtime.env`, every entrypoint
   (`sentinel-triage.sh`, `sentinel-nightly.sh`, `pr-emit.sh`, `adversarial-review.sh`) runs as a
   no-op, attempts zero egress (verified by stubbing `ollama`/`gh`/`curl` on PATH to fail-loud), and
   exits 0 without writing outside its own log.
5. **Tier-1 guard unaffected** — `relay-automation/hooks/sentinel-network-guard.sh` already excludes
   `*/sentinel-overlay/*`, so overlay egress code does not trip the Tier-1 zero-network gate.

## Components (issue §2.1–§2.7 → files, all committed)

| File | Issue | Role |
|---|---|---|
| `sentinel-overlay/README.md` | §2 | what it is; activation; inert-by-default statement |
| `lib/config.sh` | §2 | the activation gate (`sentinel_active`) + config load |
| `lib/classify.sh` | §2.2 | Gemma classifier iface (ollama `gemma4:12b-mlx`); stubbable |
| `lib/probe-lint.sh` | §2.2/§2.3 | deterministic: run each `fix_probe`, must detect the bug pre-promotion |
| `lib/gh.sh` | §2.2/§2.5 | gated GitHub wrapper (issue file / PR create) |
| `sentinel-triage.sh` | §2.2 | debug.log → dedupe → classify → draft `PROJECT/1-INBOX` doc → (gated) file issue |
| `sentinel-nightly.sh` | §2.4 | PDDA selection rule → (gated) fire `marathon-drive.sh` serially, N≤2, `--require-clean --requires-test` |
| `pr-emit.sh` | §2.5 | (gated) branch/push/PR after approval + `3-COMPLETED` move |
| `adversarial-review.sh` | §2.6 | (gated) Gemma post-PR red-team |
| `morning-report.sh` | §2.7 | daily summary (local, no egress) |
| `config/runtime.env.example` | §0 | documents the gitignored activation settings |
| `config/.gitignore` | §0 | ignores `runtime.env` |

Selection rule (§2.3) is PDDA's verbatim: `eligible = risk<=2 AND not ratings_provisional`; route-to-human on `risk>=4 OR provisional OR foreign repo`. Gemma drafts land `ratings_provisional: true`.

## Acceptance

1. No `runtime.env` → `test/inert-by-default.sh` green: every entrypoint no-ops, zero egress reachable.
2. `test/egress-static-guard.sh` green: all network/LLM/gh confined to the gated wrappers.
3. Stubbed classify → `sentinel-triage.sh` drafts a valid `1-INBOX` capture doc that passes
   `pdda.sh frontmatter`/`status-table`, with a Swarm Preflight Contract whose probes pass probe-lint.
4. Tier-1 `sentinel-network-guard.sh` still green (overlay excluded).
5. Registered in `validate.sh`.
