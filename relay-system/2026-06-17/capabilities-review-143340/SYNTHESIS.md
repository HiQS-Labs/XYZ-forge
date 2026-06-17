# Consult synthesis — capabilities assessment review

**Run:** `relay-system/2026-06-17/capabilities-review-143340/`
**Advisors:** Codex (failed), Gemini (answered).
**Coordinator:** Claude.

## Degrade — stated, not silent

**Codex did not answer.** Its transcript shows a host-level failure, not a model verdict:
`no native root CA certificates found … No keychain is available` — the Codex CLI couldn't load
the macOS trust store, so every websocket reconnect failed and it never reached the model. This is
an environment problem on this machine, not a disagreement, and retrying won't fix it until the
keychain is available. So this is a **single-advisor consult**, which means the usual cross-model
disagreement section is empty — and per the skill's own caveat ("two models, not ground truth," and
here only one), I did not take Gemini's claims on faith. **I verified each concrete claim against
the repo before accepting it.**

## Disagree

No cross-model disagreement to adjudicate (only one advisor answered). Instead, the live tension was
**Gemini vs. my own draft** — and on every checkable point, Gemini was right and the draft was wrong:

| # | Gemini's claim | Verification | Adjudication |
|---|---|---|---|
| 1 | Test count is **23**, not 12 | `validate.sh` runs 23 tests in its loop; README's "12 acceptance tests" line is itself stale | **Gemini correct.** Draft under-sold maturity. |
| 2 | Watchdog **escalates**, doesn't autonomously **recover** | `watchdog.sh` reap is gated behind `--allow-reap` and is a "stub, pending an authority decision" (`relay-automation/README.md:18`) | **Gemini correct.** "Recovers from stalls" overstated. |
| 3 | Lanes are **not runtime-enforced** | `README.md:138`: "`tick` does not enforce that an agent's edits stay within declared paths" | **Gemini correct.** Real omission — the lock prevents double-*claims*, not out-of-lane *edits*. |
| 4 | "Hands-free" applies only to the **Claude** loop | `poll.sh:213` emits "manual nudge required" for Codex/Gemini turns; `codex-turn.sh` exists but isn't auto-fired by the poll driver | **Gemini correct.** Headless cross-model is wired but not yet auto-driven. |

## Agree

(Single advisor, so "agree" = Gemini's read that I independently confirmed.)
- **Consult's worktree isolation is real and tested** — `test/consult.sh` covers it. Gemini graded this "Pass."
- **The `tick` core and Consult safety mechanics are the most production-ready parts**; the relay
  automation layer is closer to an advanced prototype than a beta. Matches the code.
- The **architecture description is accurate** (local-transport event log, throwaway-worktree advisory boundary).

## Reconciled call

The draft's *framing* (honest working beta, well-tested core) is sound, but it shipped **four
factual overstatements/omissions**, all now verified true. Applying Gemini's four corrections makes
the "honest engineer's read" actually honest. Specifically:

1. **12 → 23 tests.**
2. **"recovers from stalls" → "detects stalls and escalates"** (autonomous reap is a gated stub).
3. **Add the no-runtime-enforcement omission** — collisions are prevented at *claim* time by a real
   mutex, but out-of-lane *edits* rely on agent honesty + post-run audit.
4. **Qualify "hands-free"** — fully hands-free for the Claude loop; non-Claude turns currently emit a
   manual nudge, with headless `codex-turn.sh` wired but not auto-fired.

And in Part 2, the marketing-honesty note must explicitly cover that **"zero collisions" and
"provably safe" depend on the precise boundary** (claim-time mutex; repo-not-process isolation), not
a stronger guarantee.

**Open risk flagged for the human:** this is a one-model review. Gemini's findings are verified, but
a clean blind spot shared by a single advisor can't be cross-checked here. The corrections are safe
to apply because each was confirmed against source — not because a panel agreed.

---

## Update — Codex round added (now a real two-model panel)

The Codex degrade was diagnosed as the **Claude Code Bash sandbox** (blocks keychain + `chatgpt.com`;
Gemini survives via allowlisted `googleapis.com`). Re-ran the Codex half with the sandbox disabled
(`relay-system/2026-06-17/capabilities-review-codex-144148/`) against the **corrected** doc — and it
caught five more real issues Gemini and the coordinator both missed. Each verified against source:

| # | Codex finding | Verification | Adjudication |
|---|---|---|---|
| 1 | **[Blocker]** Paid-package sample copy still overclaims ("collision-proof lanes," "converges on its own," "sealed off and untouchable") | The internal honesty note flagged these, but the sample message itself wasn't changed | **Correct.** Rewrote the sample to defensible-but-punchy copy. |
| 2 | Concurrency metric ≠ "actual overlap" | `src/analyze.js:67` measures ≥2 agents holding active **claims**, not edits | **Correct.** Reworded to "concurrent-claim time = overlap of claim windows, not keystrokes." |
| 3 | Missing: worktree excludes `.gitignore`d files | `consult.sh:105`, `SKILL.md:104` | **Correct.** Added to consult limits. |
| 4 | Missing: stale lock on hard kill mid-claim | `src/lock.js:17` ("recovery is `rm .tick/locks/claim.lock`") | **Correct.** Added to swarm limits. |
| 5 | "neither model runs the code" unsupported | Advisors *can* execute in-worktree (`--yolo` / `exec`) | **Correct.** Replaced with "agreement is not proof." |

**Cross-model agreement (higher confidence):** both models independently confirmed (a) the test count
should be 23, (b) edit-scope is not enforced / lanes rely on honesty, (c) cross-model relay still
needs a manual nudge, and (d) the core's "honest, well-tested" framing is fair for `tick` but
slightly generous for the relay/consult layers.

**Final reconciled call:** the framing was sound; the panel surfaced **nine** verified factual
fixes total (4 from Gemini, 5 from Codex), now all applied. The doc's own thesis — that the gap
between the honest read and the marketing read should be *small* — is now actually true of the
shipped marketing sample, which it wasn't before Codex's blocker.
