---
gh_issue: 272
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/272
title: "Driven relay turn's tick release resolves wrong TICK_REPO_ROOT in a vendored same-repo lane — review content never lands"
status: "Root-caused + fix landed 2026-07-23 via GH-296/PR #297 — different mechanism than originally scoped; this doc's own swarm-preflight contract is SUPERSEDED, do not fire. Pending #297 merge + close verification."
created: 2026-07-23
updated: 2026-07-23
owner: noel
doc_type: bug
complexity: 3
risk: 2
effort: 2
ratings_provisional: true
related:
  - "#261 — prior fix that reproduced this exact class of bug and explicitly deferred it: 'a separate, real bug worth its own future issue' (merge 312a2c3)"
non_goals:
  - Re-litigating GH-261's own fix (already merged and correct for what it addressed).
  - A general redesign of TICK_REPO_ROOT resolution — fix the specific vendored-same-repo-lane
    mismatch this issue reproduces, not the whole resolution model.
goal: >
  A driven relay turn's tick release/done call, when run inside a worktree-isolated vendored
  same-repo lane, resolves TICK_REPO_ROOT to the CALLER's actual repo root — not the vendored
  `.xyz/` subpath — so review content lands where the watcher expects it instead of silently
  vanishing into the wrong namespace.
---

# GH-272 · `tick`'s TICK_REPO_ROOT resolves wrong in a vendored same-repo lane

## Status
| What was just completed | What's next |
|---|---|
| **2026-07-23 (later, same day): root-caused and fixed — via [GH-296](../1-INBOX/GH-296-RELAY-DRIVE-TICK-EPERM.md)/[PR #297](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/297), NOT this doc's own contract below.** While reviewing GH-296 (a related tick-lock EPERM bug), traced this issue's exact symptom to a confirmed mechanism: `RelayTurnLib._run_rtl()` (`utils/py/rtl.py`) builds the bash subprocess env for every bridged `relay-turn-lib.sh` call — including `rtl_turn_prompt` (builds the turn prompt text) and the GH-67 backstop release — via `env["TICK_REPO_ROOT"] = os.environ.get("TICK_REPO_ROOT", self.root)`. `self.root` came from `codex-turn.py`/`agy-turn.py`/`claude-turn.py`'s own `root` default, which (pre-fix) fell back to `XYZ_ROOT` (the harness's own directory) instead of the CWD's git toplevel whenever the caller didn't independently export `TICK_REPO_ROOT` — exactly this issue's vendored-same-repo-lane shape. **Confirmed via a live A/B repro**, not just code reading: built a real vendored install with `relay-automation/xyz-vendor.sh` in a scratch repo, drove the shim with `CWD=.xyz` and no `TICK_REPO_ROOT` export (matching how `relay-drive.sh` actually invokes it). Pre-fix code baked `TICK_REPO_ROOT="<target>/.xyz"` into the Codex prompt AND the backstop release landed in that wrong namespace (`tick info` on the real target still showed `status: open, handoff-to: codex` afterward) — both match this issue's reported symptom exactly. Post-fix (PR #297) resolves both. **This doc's own "Where to look"/contract below targeted the wrong file** — `relay-turn-lib.sh`'s `rtl_tick_bin()`/backstop logic turned out to be correct all along; it just inherited a bad `TICK_REPO_ROOT` from its Python caller's env. **Do not fire the contract below** — it would spend effort editing code that isn't the defect. | Merge PR #297, then re-verify this issue's own original repro before closing #272 on GitHub — the live A/B above used the Python runtime (matching commit-ordering evidence that Python was already default at report time), not a literal replay of the original `sleuth-app`/`runtime:bash`-labeled report. |

Original reproduction (2/2, default timeout then `RELAY_TURN_TIMEOUT_S=900`): a worktree-isolated turn's own
`tick release`/`tick done` invocation logs `TICK_REPO_ROOT="<repo>/.xyz"`, but
`find-harness.sh --env` exports `TICK_REPO_ROOT=<repo>` (no `.xyz` suffix) for the same run. GH-261's
own fix commit (`312a2c3`) confirmed this exact behavior is real ("`.tick` claims do land in the
wrong repo when it leaks in") but deliberately deferred it as "a separate, real bug worth its own
future issue" rather than fixing it there — this issue was filed as that follow-on, and is now
resolved by a different fix than either doc originally anticipated.

## Where to look — SUPERSEDED, kept for history, do not act on this section

`relay-automation/relay-turn-lib.sh`'s `rtl_tick_bin()` (line ~173) and the `TICK_REPO_ROOT` resolution
used at token-claim/release/done time (lines ~648-650, ~1025-1049) — turned out NOT to be the defect;
both correctly fall back to the (by-then-correct) `RTL_ROOT`/caller env. The actual fix landed in
`utils/py/rtl.py` (`resolve_turn_root()`) and `utils/py/{codex,agy,claude}-turn.py` (`root`'s default).
See PR #297 and the GH-296 doc's "Update (2026-07-23...)" note for the full trace.

## Swarm Preflight Contract — SUPERSEDED, DO NOT FIRE

Kept verbatim for history/audit only. This contract targets `relay-automation/relay-turn-lib.sh`,
which the 2026-07-23 investigation above found is not the defect — firing this would edit the wrong
file and leave the actual (already-fixed, in PR #297) bug unremarked. If this doc is ever picked up
by an automated preflight/marathon sweep, treat the JSON below as historical, not fireable.

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_present", "path": "relay-automation/relay-turn-lib.sh", "pattern": "rtl_tick_bin" }
  ],
  "artifacts": [ "relay-automation/relay-turn-lib.sh" ],
  "remediation": {
    "source": "issue#272",
    "criteria": "SUPERSEDED — see the Status section above. The real fix is PR #297 (utils/py/rtl.py + utils/py/{codex,agy,claude}-turn.py), already landed."
  },
  "lanes": { "agy_safe": [], "orchestrator_only": [ "relay-automation/relay-turn-lib.sh" ] }
}
```
