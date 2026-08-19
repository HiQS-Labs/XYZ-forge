# External audit — Windows/MSYS2, a third environment

**Contributed for review.** This directory is a report, not a code change. Nothing in it modifies the
harness. If you merge it, the only thing that lands is evidence.

**Harness audited:** `911878c` on `development`, in a pristine `git worktree add --detach` of
`origin/development` — deliberately not the auditor's working tree, so no finding depends on a local patch.
**Date:** 2026-08-18 · **Host:** MINGW64/MSYS2 Git-Bash on Windows 11 build 22631 — **not WSL, not macOS.**

---

## Why this is worth ten minutes

Your measurements are macOS. Your open canary is Linux. This is a **third environment**, and it turns out
to be the one that disagrees. Two of the five findings are things **neither a macOS nor a Linux canary can
ever catch**, because both honour shebangs and `/`-rooted paths:

- **the default execution lane cannot run a single turn here** (F7), and
- **the gate cannot produce a verdict at all** (F11).

Meanwhile the thing you'd most want an outsider to attack — the containment boundary — **held**. Eight of
nine invariants survived deliberately hostile agents. That result is in here too, at equal length, because
a passing negative control is evidence.

---

## Read in this order

| Order | File | What it is |
|---|---|---|
| 1 | [`FINDINGS-CONTAINMENT.md`](FINDINGS-CONTAINMENT.md) | **Start here.** F7–F11, each written to paste straight into an issue: exact command · what the docs promised · what happened · exit code · severity · `runtime:` label · suggested fix. |
| 2 | [`LOG-INDEX.md`](LOG-INDEX.md) | 48 command transcripts, each mapped to the probe that produced it and the finding it supports. |
| 3 | [`ENVIRONMENT.md`](ENVIRONMENT.md) | The stamp. Includes corrections to three values the first pass got wrong. |
| 4 | [`FIRST-RUN-FRICTION.md`](FIRST-RUN-FRICTION.md) | For the "does the repo survive a stranger's first run" milestone. Timestamped as it happened, including the guesses I made and the two I got wrong. |
| 5 | [`CONTAINMENT-FLOW.mmd`](CONTAINMENT-FLOW.mmd) / [`TURN-SEQUENCE.mmd`](TURN-SEQUENCE.mmd) | The turn's decision path with every exit code traced to its source line and to the probe that verified it; and one hostile turn end to end. |
| 6 | [`AUDIT-REPORT.md`](AUDIT-REPORT.md) | Long-form narrative covering both passes — the kernel probes (F1–F6) as well as this containment pass. |

Everything lives under `audit/`. The contribution adds **no root-level files** and touches nothing the
harness executes — `ROUTER.md` defines the canonical root doc set and PDDA enforces it, so this stays out
of that namespace entirely. It is text only: no binaries, no scripts.

---

## How the evidence was produced

**No agent credentials. No network. No token spend.** The trick is one you already built: every turn shim
resolves its agent from an env var (`codex-turn.sh:71`, `CODEX_BIN="${CODEX_BIN:-codex}"`) and your own
`test/codex-turn.sh` already injects a stub that way. So the containment claims can be attacked with
**fake agents that misbehave on purpose** — one commits mid-turn, one edits off-lane, one hangs past the
watchdog, one exits 0 having done nothing, one forks a child to outlive its own death.

Each fake agent's full source is in its own `-2-agent.log`, so the mechanism behind every verdict is
readable here without running anything.

**The probe scripts themselves are proposed separately, in #51 — not in this PR.** They are executable tooling with
their own review surface — scratch-directory handling, output paths, portability — and bundling them with
an evidence record would have made one PR out of two different asks. Reviewing the findings does not
require running them; reproducing the findings does, and that is what the follow-up is for.

---

## What is claimed, and what is not

**Claimed, with evidence:** everything in `FINDINGS-CONTAINMENT.md`. Every exit code in this report was
observed, not inferred. Every diagram node marked VERIFIED has a probe behind it.

**Explicitly not claimed:**

- **F11's root cause.** The gate recurses into itself via `githooks/pre-push`; *why* the test's stub was
  bypassed is not established, and it is not guessed at. It is also **not labelled Windows-only** — the
  mechanism has no obviously platform-dependent step and it deserves a Linux repro before triage.
- **The Python lane's containment behaviour.** It crashes before any turn starts here, so C1–C8 on that
  lane are reported as `BLOCKED`, not as failures. A control turn that never ran proves nothing.
- **Anything about macOS.** Not tested. Where a finding cannot reproduce on macOS/Linux, the report says so.

**A note on severity language:** "the default lane is broken" means *on Windows*. Your documented targets
are unaffected by F7, F8 and F10. They are filed as harness bugs rather than environment quirks because the
defects are POSIX-only assumptions in shared code — but the blast radius is one platform, and the report
never blurs that line.

---

## Two corrections to the earlier pass in this repo

Carried openly because the same directory contains the earlier findings:

1. The environment stamp recorded `python3` as a **Microsoft Store stub**, concluding the Python lane
   would harmlessly degrade to Bash. It is a real **Python 3.13.14**, the version guard passes, and Python
   is the lane this host actually takes — where it crashes. **That inverted the risk.** Corrected in
   `ENVIRONMENT.md`; it is the reason F7 exists.
2. `AUDIT-REPORT.md` cited `xyz-screens/*.png` as evidence. **That directory never existed.** Those
   citations are gone; the report now points only at `audit/logs/`, which is text that does exist and
   whose provenance is checkable line by line.

---

## If you want to act on this

Findings are issue-ready and carry the `runtime:` label your ROUTER.md taxonomy asks for
(`runtime:python` for F7/F10, `runtime:bash` for F8/F9; **omitted** for F11, since `validate.sh` is not one
of the dual-runtime twins and ROUTER.md says omit rather than guess). **No issues were filed** — five
unsolicited issues on someone else's tracker is the maintainer's call, not the auditor's. Open the ones you
agree with; the text is ready to paste.

The cheapest high-value fix is not in the findings list: an explicit re-entrancy guard in `validate.sh`
(`XYZ_VALIDATE_ACTIVE=1` on entry, refuse loudly if already set). That closes F11's whole class regardless
of root cause, and turns a silent 47-minute hang into an immediate, explained refusal.
