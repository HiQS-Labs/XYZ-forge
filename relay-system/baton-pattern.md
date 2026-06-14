# Baton pattern — paste once, orchestrator keeps it current

A **baton** removes the open-file → highlight → copy → paste dance from relays.
There is ONE baton file per relay. You paste the **same short line** into whichever
window the orchestrator (Claude-B) points you at, every turn. The orchestrator
overwrites the baton's contents before each handoff so it always describes the
*current* pending turn.

## How you use it (the operator)

Each turn, paste this one line into the window the orchestrator names:

```
read and do exactly what relay-system/<date>/<slug>.baton.md says, then stop
```

That's it. You never open or edit the baton yourself. The orchestrator tells you
which window to paste into ("paste the baton into the Codex window").

## Why it's safe (no stale-paste corruption)

The baton carries `TURN:` and `TARGET:` lines, and step 1 makes the agent verify
itself. If you paste into the wrong window, or before the orchestrator has updated
the baton, the agent sees the mismatch and **stops without writing** — the
wrong-window guard is baked into the file instead of living in your head.

## Lifecycle each turn

1. Orchestrator writes the baton for the upcoming TARGET, commits it.
2. Orchestrator tells you which window to paste the stable line into.
3. The agent reads the baton, verifies `TARGET` == itself and the relay's `NEXT`
   == `TARGET`; if not, it stops.
4. The agent does the steps (append its block to the relay thread, flip `NEXT`,
   commit), then stops.
5. You tell the orchestrator "done"; it rewrites the baton for the next TARGET.

---

## Fill-in template (orchestrator copies this into the live `<slug>.baton.md` each turn)

```markdown
# BATON · <relay title>

TURN: <n>
TARGET: <Codex | Gemini | Producer | Reviewer | ...>
RELAY FILE: relay-system/<date>/<slug>.md
PRECONDITION: that file's `NEXT:` must equal "<TARGET>". If it doesn't, STOP.

## If you are not <TARGET>, STOP — write nothing and tell the operator.

## DO (in order)
1. Read the whole relay file above.
2. Verify the PRECONDITION (NEXT == <TARGET>). On mismatch, STOP.
3. Append ONE block at the very bottom, directly ABOVE the marker line
   (<!-- ↓↓↓ NEXT TURN GOES ABOVE THIS LINE ... -->), in this exact format:

<paste the turn's block format here — e.g. the Reviewer/feedback block>

4. Do NOT edit any earlier block or any other file.
5. At the top of the relay file, change "NEXT: <TARGET>" to "NEXT: <next role>".
6. Commit just the relay file:
   git add relay-system/<date>/<slug>.md
   git commit -m "relay(<slug>): <TARGET> r<n>"
   then put the short hash in your block's Commit: line and `git commit --amend --no-edit`.
7. STOP. Tell the operator this turn is done and who goes next.
```

> Note: the baton is disposable scratch (the "do this now" pointer). The relay
> thread file remains the single source of truth and the committed log.
