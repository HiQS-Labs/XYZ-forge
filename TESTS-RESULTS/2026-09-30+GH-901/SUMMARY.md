# GH-901 verification

28 recorded manual probes pass, including nonempty planner output, missing actual
activity, empty/stale/malformed snapshots, preserved long titles, stable replan,
custom/remote exclusions, and mixed-write preflight refusal. The deleted-rename
red control makes the nonempty-plan assertion fail. Run the retained
`manual_probe.py` from repo root; no suite/registry admission.

Native desktop smoke used supported list/read/title/pin tools: 5 renames and 6
new pins, all six targets readback verified. Current chat was separately renamed
and pinned. Private title/ID/undo details remain in local temp, not public git.

Independent Codex final relay: Round 1 PASS but supervisor close-mismatch; Round 2
PASS and driver-attested Approved against 0b18f924. Receipt:
`relay-system/2026-09-30/gh901-final.codex.md`.

The first, over-scoped full gate was stopped: inherited XYZ_HARNESS pointed at
primary rather than fixtures (observed gh448/gh401 output), and another full gate
was active on the host. Git identity remained intact. It is not passing evidence.
The canonical ci-route classification against origin/development is tier 1,
route docs, full_required=false; required verification uses Small in a separate
full clone with the ambient harness override removed. Result will be retained.

Native scheduler consolidation verified: legacy ZCode job disabled and idle;
Codex heartbeat ACTIVE every 15 minutes, using the retained pilot source clone.
Global skill publication awaits dependency landing; clone must remain available.
