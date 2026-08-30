# 🚪 FRONTDOOR.md — onboarding health dashboard (worked example)

> **Worked example.** This board was generated against the source repo on 2026-06-22. It is kept as a sample of the skill's output, not as this repo's own health board.

Continuous, structured, **deterministic** dashboard of the repo's clone-to-working front door. Every
finding carries a check in the [Deterministic checks](#deterministic-checks--re-run-to-refresh) block
below, so each status is *verified by re-running a command*, not asserted. Refresh this board whenever
an onboarding-facing doc (`README.md`, `ROUTER.md`, `AGENTS.md`, `CLAUDE.md`, `skills/**/SKILL.md`,
`relay-automation/QUICKSTART.md`) or the repo structure changes.

| | |
|---|---|
| **Last audited** | 2026-06-22 (HEAD — what a cold clone gets) |
| **Method** | front-door walk, read-only |
| **Verdict** | ⚠️ **Bumpy** — a newcomer reaches working, but stale numbers, 2 dead links, and a phantom-path `CLAUDE.md` trip the path |
| **Remediation plan** | [PROJECT/1-INBOX/FRONT-DOOR/2026-06-22.md](PROJECT/1-INBOX/FRONT-DOOR/2026-06-22.md) |

## Health at a glance

| Dimension | Status | One-liner |
|---|---|---|
| One front door | ✅ | `ROUTER.md` is the single canonical entry (README points to it) |
| 🔑 Leaked secrets | ✅ | 0 provider-format keys (tree + history spot-check) |
| First success works | ✅ | `./validate.sh` → 36/36, no accounts or keys |
| Doc ↔ code drift | 🚧 | stale test counts in 3 docs + 2 dead README links |
| Agent front door | 🚧 | `CLAUDE.md` sends a fresh agent to 5 phantom paths |
| Recent features documented | ⚠️ | `--target-root`, `install.sh` not in any prose doc |

## Findings

Severity 🔴 high · 🟠 med · 🟡 low — Status ⬜ OPEN · ✅ FIXED

| ID | Area | Sev | Status | Fix (doc-only) |
|---|---|---|---|---|
| FD-01 | Agent door — `CLAUDE.md` cats 5 phantom paths + a phantom branch | 🔴 | ⬜ | point it at `ROUTER.md`, or gate it if it's a different-repo file |
| FD-02 | Drift — `README.md` claims `28/28` (lines 8, 14) | 🟠 | ⬜ | 28 → 36 |
| FD-03 | Drift — `AGENTS.md` claims `12/12` (line 53) | 🟠 | ⬜ | 12 → 36 |
| FD-04 | Drift — `ROADMAP.md` status table claims `33/33` (line 40) | 🟡 | ⬜ | 33 → 36 |
| FD-05 | Dead link — `README.md:28` → `2-WORKING/EXP-AUTOMATION/…` (file is in `1-INBOX`) | 🟠 | ⬜ | repoint to `1-INBOX`, or move the file |
| FD-06 | Wrong path — `README.md:33` `skill/relay-automation/` (no such dir) | 🟠 | ⬜ | `skill` → `skills` (plural) |
| FD-07 | Undocumented — `--target-root` absent from prose docs (only `--help`) | 🟠 | ⬜ | add a recipe (GH-11 Asks 2–5) |
| FD-08 | Undocumented — `skills/relay-xyz/install.sh` only in SKILL.md (chicken-and-egg) | 🟠 | ⬜ | surface in `README.md`/`ROUTER.md` |
| FD-09 | Stale — `AGENTS.md` "One skill ships here / `skill/xyz`" (several skills now) | 🟡 | ⬜ | update to the real `skills/` inventory |
| FD-10 | Missing — no "run un-sandboxed" note for agent users in `README.md` | 🟡 | ⬜ | add a callout |

## Verified baselines (keep green)

- ✅ **Secrets clean** — no provider-format key in the tracked tree or the history spot-check.
- ✅ **One front door** — `README.md`'s first pointer is `ROUTER.md`; `ROUTER.md` owns startup order.
- ✅ **First success** — `./validate.sh` prints `passed: 36 / 36`, no accounts or keys required.
- ✅ **No human-gated wall on the kernel path** — auth is only for the *live* relay (codex / agy each need their own install + login).

## Deterministic checks — re-run to refresh

Empty output = all green. Any line printed names an OPEN finding. This block never executes the
repo's own scripts or tests — that's execution wearing a read-only disguise. `EXPECTED` below is a
literal the operator updates by hand after running `./validate.sh` themselves; it is never
auto-derived by this block.

```bash
# Run from the repo root.
EXPECTED=36  # updated by hand after a manual ./validate.sh run — never auto-derived

# FD-01 — CLAUDE.md required-reading paths must exist
for f in PROJECT/2-WORKING/P1-TRINITY.md \
         experiments/coordination-layer/README.md \
         experiments/coordination-layer/RECAP.md \
         experiments/coordination-layer/REAL-AGENT-OBSERVATIONS.md \
         experiments/coordination-layer/BACKLOG.md; do
  [ -e "$f" ] || echo "FD-01 OPEN: CLAUDE.md sends agents to a missing path: $f"
done
# FD-02 — README test count must match the recorded baseline
grep -qE "$EXPECTED ?/ ?$EXPECTED" README.md || echo "FD-02 OPEN: README test count != recorded baseline ($EXPECTED)"
# FD-03 — AGENTS.md must not carry the stale 12/12
grep -q '12/12' AGENTS.md && echo "FD-03 OPEN: AGENTS.md still says 12/12 (recorded baseline $EXPECTED)"
# FD-04 — ROADMAP status table must not carry the stale 33/33
grep -q '33/33' ROADMAP.md && echo "FD-04 OPEN: ROADMAP status table still says 33/33 (recorded baseline $EXPECTED)"
# FD-05 — every relative link in README must resolve
grep -oE '\]\(([^)]+)\)' README.md | sed -E 's/^\]\(//; s/\)$//' | grep -vE '^https?:|^#' | while read -r p; do
  [ -e "${p%%#*}" ] || echo "FD-05 OPEN: dead README link -> $p"
done
# FD-06 — README must not reference the non-existent skill/ (singular) dir
grep -q 'skill/relay-automation' README.md && echo "FD-06 OPEN: README references skill/relay-automation (dir is skills/ plural)"
# FD-07 — --target-root in at least one prose doc
grep -rlq 'target-root' skills/relay-xyz/SKILL.md relay-automation/QUICKSTART.md 2>/dev/null \
  || echo "FD-07 OPEN: --target-root not in SKILL.md/QUICKSTART (only --help)"
# FD-08 — install.sh reachable from the front door
grep -rlq 'install.sh' README.md ROUTER.md 2>/dev/null \
  || echo "FD-08 OPEN: skills/relay-xyz/install.sh not surfaced in README/ROUTER"
# FD-09 — AGENTS.md skill inventory current
grep -q 'One skill ships here' AGENTS.md && echo "FD-09 OPEN: AGENTS.md says 'One skill ships here' (several exist)"
# FD-10 — README mentions the sandbox-off requirement for agents
grep -qi 'sandbox' README.md || echo "FD-10 OPEN: README has no 'run un-sandboxed' note for agent users"
# Baseline — secrets must stay clean
git grep -IE '(sk-[A-Za-z0-9]{20}|ghp_[A-Za-z0-9]{30}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----)' >/dev/null 2>&1 \
  && echo "BASELINE BROKEN: provider-format secret in the tracked tree — rotate then purge"
```
