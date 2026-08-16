# Sentinel Tier-2 overlay

The private triage half of the Sentinel Debug Flywheel (GH-281). It reads the Tier-1 `debug.log`,
classifies findings with a local Gemma model, drafts PDDA capture docs, files GitHub issues, fires
marathon lanes, emits PRs after approval, and runs an adversarial post-PR review.

## Transparent code, gitignored activation, inert by default

This overlay ships as **visible reference code in the public repo** — full transparency on exactly
what the private side does, including every call-home path. What is **not** committed is the runtime
activation config.

- **Inert by default.** With no `config/runtime.env` (or `SENTINEL_ENABLE` != 1), the overlay is a
  clean no-op: **no network, no LLM (`ollama`), no GitHub (`gh`), no marathon fire, no PR push.**
- **Activation is local.** Copy `config/runtime.env.example` → `config/runtime.env` (gitignored),
  set `SENTINEL_ENABLE=1`, and fill in the model / GitHub / target settings. Only then does egress
  happen — on your machine, by your choice.

This is enforced, not just documented:
- `lib/config.sh::sentinel_active` is the single activation gate.
- All network/LLM/GitHub egress is confined to the gated wrappers `lib/classify.sh` (ollama),
  `lib/gh.sh` (`gh` / `git push`).
- `test/egress-static-guard.sh` proves no other overlay file contains a call-home primitive.
- `test/inert-by-default.sh` proves that with no `runtime.env`, every entrypoint no-ops and reaches
  zero egress (verified by stubbing `ollama`/`gh`/`curl` to fail-loud on PATH).

The Tier-1 zero-network guard (`relay-automation/hooks/sentinel-network-guard.sh`) excludes this
directory, so the overlay legitimately containing egress code does not weaken the Tier-1 guarantee.

## Components

| File | Role |
|---|---|
| `lib/config.sh` | the activation gate (`sentinel_active`) + runtime.env loader |
| `lib/classify.sh` | Gemma classifier (ollama) — gated; stubbable via `SENTINEL_CLASSIFY_STUB` |
| `lib/probe-lint.sh` | deterministic: each `fix_probe` must currently detect the bug (no egress) |
| `lib/gh.sh` | gated GitHub / `git push` wrapper |
| `sentinel-triage.sh` | `debug.log` → dedupe → classify → draft `PROJECT/1-INBOX` doc → (gated) file issue |
| `sentinel-nightly.sh` | PDDA selection → (gated) fire `marathon-drive.sh` serially, N≤2, `--require-clean --requires-test` |
| `pr-emit.sh` | (gated) branch/push/PR after approval + move doc to `3-COMPLETED` |
| `adversarial-review.sh` | (gated) Gemma post-PR red-team |
| `morning-report.sh` | daily local summary (no egress) |

## Selection rule (PDDA, verbatim)

```
eligible = risk <= 2 AND not ratings_provisional
route-to-human: risk >= 4 OR ratings_provisional OR a target repo you don't own
```

Gemma-drafted docs always land `ratings_provisional: true`, so nothing it rated auto-selects until a
human confirms the ratings.
