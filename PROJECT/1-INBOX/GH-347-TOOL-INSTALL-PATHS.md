---
gh_issue: 347
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/347
title: "pi CLI installed inside another app's folder (~/.hermes/node) — invisible to PATH, and no guidance existed to prevent it"
status: "Proposed (1-INBOX — not yet active)"
created: 2026-07-29
doc_type: feedback
related: GH-295, GH-303, GH-336
effort: 1
complexity: 1
risk: 1
phases: 3
goal: >
  Relocate the pi CLI out of a foreign application's private Node runtime onto a path this repo's
  tooling owns, and add the missing GUIDING-PRINCIPLES convention that would have prevented it.
---

# GH-347 · tool install paths

## Why now

Driving round 4 of the [GH-336](GH-336-PLANNING-CONTEXT.md) review with `pi + qwen3.8-max-preview`,
`find-harness.sh --check` reported `pi` absent. It was installed and working — just inside **another
application's private directory**, invisible to every shell. The turn ran only after manually prepending
a foreign app's bin directory to PATH.

The relay itself succeeded. This issue is about the install being fragile and undetectable, not about Pi
or the shim misbehaving.

## Root cause

`~/.hermes` is a separate agent application (own `SOUL.md`, `sessions/`, `memories/`, `state.db`, `.env`,
`skills/`, `cron/`, `hooks/`) shipping a **bundled private Node runtime** at `~/.hermes/node`. It
symlinked that runtime onto PATH on 2026-06-03:

```
~/.local/bin/node -> ~/.hermes/node/bin/node
~/.local/bin/npm  -> ~/.hermes/node/bin/npm
```

npm derives its global prefix from its own node install, so `npm config get prefix` returns
`/Users/noelsaw/.hermes/node` — **with no `~/.npmrc` and no explicit prefix setting anywhere.** A plain
`npm install -g @earendil-works/pi-coding-agent` therefore landed our tool in Hermes's folder, silently,
exit 0. The break completes because only `node`/`npm` were symlinked out — nothing symlinks `pi`, and
`~/.hermes/node/bin` is not itself on PATH.

The two lanes that never had this problem show the correct shape: `~/.local/bin/agy` (real binary) and
`~/.local/bin/codex -> ~/.codex/packages/standalone/current/bin/codex` (own app dir, own symlink).

## Bet, tradeoff, and blast radius

**Bet:** a one-line convention plus a relocation removes a whole class of silent-dependency-loss without
adding any enforcement machinery.

**Blast radius — small, and that scopes the work.** `~/.hermes/node/lib/node_modules` contains only
`@earendil-works/` (pi), `corepack/`, and `npm/`. Pi is the **sole** misplaced third-party package. This
is one isolated instance, not a systemic cleanup.

**Real risk if left alone:** `~/.hermes/.install_method` reads `git`, and the folder carries a 10.8 MB
`hermes-setup` and an `.update_check`. A Hermes update that rebuilds `node/` deletes `pi`, and the only
signal is `find-harness.sh --check` saying `pi` is not on PATH — exactly what it says *today*, so the
failure is indistinguishable from the current state. Same disease as GH-315/GH-319: a broken observation
layer where every available signal agrees with the wrong conclusion.

**Reversibility:** trivial. Phases 1–2 are a reinstall and a doc paragraph.

## Guidance audit — none existed

Checked before writing anything new:

- `relay-automation/README.md:29` names the package but not its install location.
- `PROJECT/2-WORKING/GH-295-PI-BUILDER-INTEGRATION.md` covers config surface and containment posture,
  never where the binary should live.
- `skills/relay-xyz/SKILL.md` requires workers *on PATH* and ships `find-harness.sh --check` for it —
  the right check for a different question.
- `GUIDING-PRINCIPLES.md` had no tool-install-path convention at all.

**No guidance was wrong; guidance was absent.** Hence Phase 2 adds a convention rather than correcting
a doc.

## Phase 1 — relocate `pi` (DONE 2026-07-30)

- [x] Reinstalled with **Homebrew's** npm (independent Node 26.3.0 at `/opt/homebrew`) into a prefix we
      own: `npm install -g --prefix ~/.local @earendil-works/pi-coding-agent@0.81.1`. Launcher is now
      `~/.local/bin/pi -> ../lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js` — the same
      shape as `codex`, in the same directory as `codex` and `agy`.
- [x] Uninstalled from Hermes (`npm uninstall -g --prefix ~/.hermes/node …`, 132 packages removed) and
      removed the empty `@earendil-works/` directory it left behind. `~/.hermes/node/lib/node_modules`
      now contains only `corepack/` and `npm/`.
- [x] **Hermes's `node`/`npm` symlinks left untouched**, as scoped.

### Acceptance criteria

- [x] `command -v pi` → `/Users/noelsaw/.local/bin/pi`, outside `~/.hermes/`; `pi --version` → `0.81.1`.
- [x] `pi --list-models` still lists `qwen-token-plan / qwen3.8-max-preview` (1M context, tools +
      reasoning).
- [x] `bash test/pi-turn.sh` → **39 pass / 0 fail**.
- [x] `~/.hermes/node/lib/node_modules` no longer contains `@earendil-works/`.
- [x] `~/.local/bin/node` and `~/.local/bin/npm` still point at `~/.hermes/node/bin/…`, unchanged.
- [ ] ~~`find-harness.sh --check` reports `pi` present.~~ **Criterion was wrong — see below.**

### Correction: `find-harness.sh --check` never probed for `pi`

This criterion could not be met as written, because the readiness check has **no `pi` probe at all**. It
exports `RELAY_HAS_TICK`, `RELAY_HAS_CODEX`, and `RELAY_HAS_AGY`
([find-harness.sh:206-208](../../skills/relay-xyz/find-harness.sh#L206)) and nothing for `pi`.

The original framing of this issue said `--check` "reported `pi` absent." **It did not** — it stayed
silent about `pi`, and silence was misread as a negative report. The practical consequence is worse than
the version first written up: a missing `pi` produces **no signal whatsoever**, rather than a line saying
it is missing. GH-295 added `pi` as a third builder lane and the readiness check was never extended to
match.

This does not change Phase 1's outcome — `pi` is correctly relocated — but it moves work into Phase 3 and
sharpens it.

## Phase 2 — add the missing convention (DONE 2026-07-29)

- [x] `GUIDING-PRINCIPLES.md` → Conventions → **"Tool install paths — never inside another app's folder
      (GH-347)"**: the rule, the invisible-failure mode, the `npm config get prefix` trap with GH-347 as
      the worked example, the positive pattern, and an explicit note that this is a convention and not a
      gate.

### Acceptance criteria

- [x] The convention names the `npm install -g` trap specifically and says to check
      `npm config get prefix` before installing.
- [x] It states the observation-layer failure (readiness check cannot distinguish wiped from
      never-installed).
- [x] `utils/pdda/pdda.sh run` green.

## Phase 3 — make it detectable

**Promoted from "optional" to "worth doing," and its first item is no longer optional at all** — the
correction above shows `pi` is invisible to the readiness check in *both* directions.

- [ ] **Add a `pi` probe** (`RELAY_HAS_PI`) alongside the existing tick/codex/agy exports at
      `find-harness.sh:206-208`, so a missing third builder lane produces a line instead of silence.
      GH-295 shipped the lane; the checker was never extended to match.
- [ ] Consider extending `--check` to **warn** when a resolved worker binary sits under a known foreign
      app root.

### Acceptance criteria

- [ ] `find-harness.sh --check` prints a `pi` line — present *or* missing — so its absence is a signal
      rather than silence. Asserted with `pi` off PATH.
- [ ] The foreign-root check is a **warning, never a gate** — a false positive that blocks a relay is
      worse than the papercut it prevents.
- [ ] Test coverage for both the `pi` probe and the warning path; `./validate.sh` green.
- [ ] The `pi` probe is **not** droppable — it closes a real observability hole. The foreign-root warning
      still is, if it cannot be done cleanly.

## Non-goals

- Repointing or repairing Hermes's `node`/`npm` symlinks, or changing the machine's global npm prefix.
- Auditing other machines or vendored `.xyz/` copies for the same pattern — no evidence it occurs
  elsewhere.
- Making install location a blocking gate anywhere in the harness.
