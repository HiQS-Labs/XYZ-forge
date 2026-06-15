Field report from driving relay-automation/codex-turn.sh cross-repo (relay thread in a
DIFFERENT git repo than the xyz clone). It worked end-to-end — exit 0, file-scoped commit,
no push, commit-bypass guard + allowlist held. But three portability gaps required manual
workarounds on the host repo. Each is a real-device/real-repo issue, not a fixture issue.
Please run these through your own relay + test/codex-turn.sh (keep the 16 green; add cases).

[1] PRE-EXISTING DIRTY-STATE SAFETY  (highest priority)
   codex-turn.sh step 3 enforces the allowlist against the FULL post-turn `git status`.
   Any file already dirty BEFORE the turn (unrelated WIP) that isn't allowlisted gets
   `git checkout -- ` / `rm -rf`'d AND fails the turn (exit 6) — it destroys ambient work.
   FIX: snapshot `git -C "$ROOT" status --porcelain -z` into a set BEFORE `codex exec`;
   after the turn, only enforce/revert paths whose status is NEW or CHANGED vs that
   snapshot. Leave pre-existing off-allowlist dirty paths untouched (and don't fail on them).
   (Known minor gap to note: a file already dirty that Codex edits further with the same
   status code won't be caught — acceptable for review turns; document it.)

[2] .tick/ PORTABILITY
   The shim deliberately doesn't clean .tick because it's gitignored IN THE XYZ REPO. In a
   host repo that hasn't gitignored .tick, tick's writes show as untracked and the allowlist
   walk `rm -rf`s .tick/ + fails. FIX: always exempt the tick state dir (paths under .tick/)
   from allowlist enforcement, independent of the host repo's .gitignore.

[3] CODEX AUTONOMY FLAGS
   The shim calls `"$CODEX_BIN" exec "$prompt"` with no sandbox/approval flags, so file-write
   depends entirely on the device's ~/.codex/config.toml. On a fresh device with default
   config, `codex exec` won't write the relay file → the turn produces no changes. The
   QUICKSTART prereq (`codex exec "say ok"`) doesn't catch this because it writes nothing.
   FIX: pass explicit autonomy to codex exec (e.g. `-s workspace-write` + a no-prompt
   approval mode), OR document a required CODEX_BIN wrapper. My workaround wrapper:
       #!/bin/bash
       sub="$1"; shift
       exec /path/to/codex "$sub" --dangerously-bypass-approvals-and-sandbox "$@"

[4] CROSS-REPO ERGONOMICS (nice-to-have)
   Driving a relay in another repo requires: CODEX_TURN_ROOT + TICK_REPO_ROOT = target repo,
   --relay-file as an ABSOLUTE path, and running from the xyz dir so ./bin/tick resolves.
   Consider a --repo-root convenience flag + a documented cross-repo invocation in README.
   Working invocation I used (single Reviewer turn, no supervisor):
       cd <xyz-clone>
       export TICK_REPO_ROOT=<target-repo>
       ./bin/tick log task.created RELAY-TURN --agent claude-a
       ./bin/tick claim   RELAY-TURN --agent claude-a --paths "<abs relay file>"
       ./bin/tick release RELAY-TURN --agent claude-a --to codex
       CODEX_TURN_ROOT=<target-repo> CODEX_AGENT=codex RELAY_AGENT=codex \
       RELAY_FILE="<abs relay file>" RELAY_TASK=RELAY-TURN ALLOW_PATHS= \
       CODEX_BIN=<wrapper> CODEX_LOG=/tmp/codex-turn.log \
       bash relay-automation/codex-turn.sh
