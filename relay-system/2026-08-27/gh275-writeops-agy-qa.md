---
Goal: Second-opinion QA of the GH-275 write-ops logging plan v2 (agy lane, 1 pass)
Date: 2026-08-27
NEXT: done
STATUS: Changes requested
---

# Context

GitHub issue #275 plans medium-level durable logging of agent disk-write commands (worktree teardowns, clone deletions, destructive git) across Claude Code + all harness turn-takers. A cross-model consult already ran; codex answered, the agy lane failed auth that day. This relay is the deferred agy second opinion — one review pass, no edits to repo files.

The full issue body (including the consult-sharpened v2 plan you are reviewing) is embedded below between the ISSUE-BODY markers. Verify its code claims against the actual repo files where cited:
- `relay-automation/relay-turn-lib.sh` (rtl_worktree_end, ~:756-762 and ~:873-875)
- `relay-automation/hooks/gh527-destructive-git-guard.sh` (existing pattern family)
- `relay-automation/xyz-sync.sh` (delete_rows rm -rf, ~:356-360)
- `utils/py/consult.py` (~:747), `utils/py/review_xyz.py` (~:684)
- `utils/py/marathon_drive.py:97-160` (XYZ_DEBUG_LOG Sentinel contract)

Questions:
1. Are the two v2 blocker fixes correct — is `rtl_worktree_end()` really the shared teardown chokepoint, and is the central default-on `~/.local/state/xyz/write-ops.jsonl` (no env inheritance) the right arming mechanism?
2. Is the v2 pattern family (superset of gh527's) right-sized — anything destructive it still misses, or anything that will false-positive noisily?
3. Is the 4-checkbox scope sound for a "medium" logging goal — anything over-built or under-built?
4. Any security/robustness flaw in the hook design (JSON decode/encode, O_APPEND, 0600, size cap, swallow-errors)?

Write your verdict below the TAKE YOUR TURN block. `**Verdict:** Approved` if sound as written, or `**Verdict:** Changes requested` with concrete file:line-cited changes. This is a single-pass review: do not modify any repo file; write only into this relay file.

<!-- ISSUE-BODY-BEGIN -->
## Goal

Medium-level durable logging of the **disk-write commands agents execute** — worktree teardowns, clone deletions, `rm -rf`, destructive git — across Claude Code and the harnesses, so "what deleted that?" has an answer with a timestamp. Not full exec auditing; a receipts trail for destructive writes.

## Recon (grounded, each point directly observed 2026-08-27 — not inferred)

**Where agent disk-writes actually originate, and what already sees them:**

| Chokepoint | Coverage today |
|---|---|
| Claude Code Bash tool (the dominant agent surface) | PreToolUse hooks demonstrably intercept every command — `gh177-sandbox-test-guard.sh` and `gh527-destructive-git-guard.sh` fired on this session's own calls. GH-527's guard **already parses the command JSON and regex-matches destructive git patterns** (`reset --hard`, `checkout --`, `stash`, `clean`) — it snapshots, but does not log non-git teardowns. |
| Harness drivers (`relay_drive.py` / `marathon_drive.py`) | `git worktree remove` sites exist; the Sentinel JSONL journal (`XYZ_DEBUG_LOG=1`, `marathon_drive.py:97-160`) defines the exact timestamped record shape and swallow-errors contract, but is opt-in and not armed at teardown sites. |
| `xyz-sync.sh:359` | The one `rm -rf` that deletes vendored installs. Unlogged. |
| codex/agy CLI internals | Shims already bound their writes (containment reverts off-lane edits; `CODEX_LOG`/`AGY_LOG` per-PID). Internal execs invisible — accepted gap. |
| Interactive terminal | `.zsh_history` now timestamped (`EXTENDED_HISTORY`, verified live) — but captures **only human typing**; every agent shell is non-interactive and writes nothing there. This gap is what motivates this issue. |
| macOS system level | True every-exec capture requires Endpoint Security (`eslogger exec`) — heavyweight, noisy, out of scope for "medium". |

## Plan (ponytail pass — extend existing seams, build nothing new)

- [ ] **1. One new PreToolUse hook, user-level (`~/.claude/`): `write-ops-log.sh` (~25 lines).** Reads the same tool-call JSON GH-527's guard already parses; regex-matches the teardown family (`rm -rf`, `git worktree remove|prune`, `git clean`, `git branch -D`, `git reset --hard`, `xyz-sync.sh delete`); appends one Sentinel-shape JSONL line (`timestamp`, cwd, matched pattern, full command) to `~/.claude/write-ops.jsonl`. Never blocks, never fails the call (mirror the XYZ_DEBUG_LOG swallow-errors contract). User-level placement covers **every repo and session on the Mac**, not just XYZ-forge.
- [ ] **2. Harness teardown sites: arm the journal that already exists.** `export XYZ_DEBUG_LOG=1` in `~/.zshenv` (inherits into all non-interactive shells), plus `xyz_debug_log_append(...)` calls at the driver worktree-remove sites and an echo-append at `xyz-sync.sh:359` (~10 lines total). Both machines.
- [ ] **3. One registered test**: hook emits a line for `git worktree remove`, stays silent for `ls`; harness append fires at a fixture teardown.

Skipped, with re-entry triggers: **eslogger/Endpoint Security daemon** (add only when a forensic question the two logs can't answer actually occurs); **codex/agy internal-exec capture** (containment + shim logs bound the blast radius; revisit if an unattributed deletion appears with no hook/journal line); **log rotation** (single JSONL; revisit past ~10MB).

Est: under an hour of work, zero new dependencies, two files touched + one hook file added.

-Reviewed by Fable 5 (ponytail pass; recon grounded in-session)

## Turn-taker coverage clarification (all harness CLIs: aider, DeepSeek, CommandCode, codex, agy)

Layer 2 covers **all turn-takers identically**: worktree creation/teardown, clone hygiene, and `xyz-sync` deletes are performed by the *drivers* (`relay-drive`/`marathon-drive`/jog), never by the CLIs themselves — so the journal lines fire the same whether the turn is aider, DeepSeek (gh148 shim), CommandCode, codex, or agy. The `~/.zshenv` export inherits into every non-interactive shell, so any XYZ-system invocation is armed.

What is NOT logged: commands those CLIs run *internally* during turns. That gap is structurally **bounded rather than watched** — turns execute in isolated worktrees under the `ALLOW_PATHS` containment contract, and off-lane writes are reverted and fail the turn (GH-441 mechanism). The one true residual blind spot: a CLI writing *outside* the repo with an absolute path (e.g. in `$HOME`) — only the Endpoint Security tier sees that, which is exactly the skipped item's re-entry trigger below.

Layer 1 additionally logs the *launch* of every drive from a Claude Code session, giving each harness run a timestamped start record that ties journal lines back to a session.

## Overhead note

Negligible on SSD/NVMe. The hook appends one ~200-byte line only on matched destructive patterns (a handful per day); the journal appends small JSONL lines per harness event, not per I/O operation. The measurable cost is the hook's process spawn per Bash tool call (single-digit ms against commands that run seconds-to-minutes), not disk. No fsync in the append path; best-effort writes that swallow their own errors, per the existing Sentinel contract.

---

## Consult-sharpened plan v2 (2026-08-27 — supersedes the 3 checkboxes above)

Cross-model consult run: codex answered with a line-cited review (`relay-system/2026-08-27/gh275-writeops-081831/`); **agy lane failed auth pre-flight (needs interactive `agy login`) — this is a single-model consult, stated per the degrade contract.** Coordinator verified codex's blockers directly before accepting.

**Two confirmed blockers in v1, both fixed below:**
1. **v1 named the wrong teardown seam.** The Python drivers contain zero `worktree remove` calls (verified: 0 matches). The real shared teardown is `rtl_worktree_end()` at `relay-automation/relay-turn-lib.sh:873-875` — `git worktree remove --force || rm -rf` plus `prune` — and that `rm -rf` fallback is exactly the operation v1 would have missed. Independent removal sites also exist in `utils/py/consult.py:~747` and `utils/py/review_xyz.py:~684`.
2. **`~/.zshenv` is zsh-only** — bash scripts, launchd jobs, and GUI-launched processes never read it, and the teardown lib is bash. Env-inheritance-based arming was the wrong mechanism entirely.

### v2 checkboxes

- [ ] **1. User-level PreToolUse hook `write-ops-log.sh`** (separate from gh527 — codex concurs it's the right ownership seam; gh527 stays a repo-local recovery guard). Hardened per review: parse the tool JSON with a real JSON decoder and emit with a real encoder (no hand-built JSON), validate shapes, swallow malformed input; single `O_APPEND` write, `0600` perms; command-size cap with hash+truncation marker (one heredoc must not blow the log); records labeled `stage:"pre"` (intent, not success). Fields: `timestamp, host, session, cwd, pattern, command`.
- [ ] **2. Harness seam: instrument `rtl_worktree_end()` + the confirmed `rm -rf` inside `xyz-sync.sh` `delete_rows` (~:356-360, after `--yes`, not at launch) + `consult.py`/`review_xyz.py` removal sites.** No env-arming: the append helper defaults **on** to a central `~/.local/state/xyz/write-ops.jsonl` (`XYZ_WRITE_OPS_LOG` overrides path, `=0` opts out) — no `~/.zshenv`, no `XYZ_DEBUG_LOG` coupling (which would also scatter `$ROOT/debug.log` into target repos and enable unrelated Sentinel findings). Same swallow-errors contract.
- [ ] **3. Pattern family (superset of gh527's, tested as such to prevent matcher drift):** `rm` recursive+force in all spellings (`-rf`, `-fr`, `-r -f`, `--recursive --force`, absolute `/bin/rm`); `git worktree remove|prune` tolerating `-C` and intervening flags; `git branch -d|-D|-df|--delete [--force]`; gh527's working-tree family (`reset --hard`, `checkout --`, `restore`, forced `switch`, `stash`, `clean`); `git stash clear|drop`; `git update-ref -d`. Known accepted limit (as gh527 itself documents): regex over raw shell text matches quoted/commented text — fine for labeled pre-execution intent.
- [ ] **4. One registered test file, wider assertions:** every pattern family fires; `ls` stays silent; malformed/non-dict JSON swallowed; newline/quote-laden commands encode cleanly; size-cap truncation; central destination + `0600`; `xyz-sync` preview (no log) vs confirmed delete (log); `rtl_worktree_end` fallback `rm -rf` path; small concurrent-append integrity check.

### Adjudicated & retained from v1
- Local per-machine logs, no sync (full commands can contain secrets — mode `0600`); forensic lookup queries both machines.
- Skip list unchanged and codex-endorsed: Endpoint Security, CLI internal execs (blind spot stays explicit: absolute-path writes outside containment), rotation (now safe to defer because records are size-capped).

Est. rises to ~2-3 hours (from 1) — the extra hour is the difference between logging the operation that actually runs and logging the one v1 imagined.

-Reviewed by Fable 5 · consult: codex (agy degraded)
<!-- ISSUE-BODY-END -->

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (agy)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

**Verdict:** Changes requested

1. **Are the two v2 blocker fixes correct?**
Yes. `rtl_worktree_end()` is indeed the shared teardown chokepoint (verified at `relay-automation/relay-turn-lib.sh:874`, handling both `worktree remove` and the `rm -rf` fallback). The removal of `~/.zshenv` in favor of a central default-on `~/.local/state/xyz/write-ops.jsonl` correctly arms bash scripts and Python drivers (`consult.py:748`, `review_xyz.py:689`) that bypass zsh profiles.

2. **Is the v2 pattern family right-sized?**
It has a structural blind spot and a tension inherited from gh527:
- **Misses non-recursive `rm -f`**: The spec strictly calls out "recursive+force" (`-rf`). An agent running `rm -f src/main.py` performs a destructive disk write that completely evades this log. The pattern should include `rm -f` even without `-r`.
- **The `checkout` tension (False Positive vs. False Negative)**: v2 cites "gh527's working-tree family" but lists `checkout --`. If you enforce `--`, you miss `git checkout <path>` (which `gh527` explicitly notes is the single most common agent revert spelling). But if you use `gh527`'s exact broad regex (`\bgit\b.*\bcheckout\b`), an intent log (unlike a guard) won't check `git status` first, meaning it will noisily log *every* safe branch switch (`git checkout main`).

3. **Is the 4-checkbox scope sound for a "medium" logging goal?**
Yes, but Checkbox 1 and Checkbox 2 have a slight drift in destination: Checkbox 2 explicitly names `~/.local/state/xyz/write-ops.jsonl` as the central destination, while Checkbox 1 just says "user-level hook `write-ops-log.sh`" without naming the file. They must both target the *same* `~/.local/state/xyz/write-ops.jsonl` central log (as Checkbox 4 implies), otherwise the logs are split across directories.

4. **Any security/robustness flaw in the hook design?**
- **0600 Race Condition**: The file must be *created* with 0600 permissions atomically (e.g., Python's `os.open` with `O_CREAT | O_WRONLY | O_APPEND` and mode `0o600`), not chmod'd after creation, to avoid a race condition that could briefly expose secrets.
- **Size Cap Placement**: If the hook blindly reads the entire JSON payload via `json.load(sys.stdin)` *before* checking the size, a massive tool call (e.g., a 100MB heredoc file write) will bloat the hook's memory or cause severe latency. The size cap must be applied defensively during the read stream, not just before emitting the log line.
