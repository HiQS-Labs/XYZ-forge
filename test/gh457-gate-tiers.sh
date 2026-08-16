#!/usr/bin/env bash
# gate-evidence: {"form":"deliberate-mutation","observed":true,"result":"reproducer: bash test/gh457-gate-tiers.sh. The registry entry for the default tier is mutated to wall_s=1 and the resolver is required to return 1, then restored and required to return the shipped value — so a cosmetically-tiered implementation with hardcoded caps fails while every other assertion in the file still passes. Observed in both directions in one run. The kill that a cap authorises is observed separately by the driven fast-tier overrun case (real subprocess, escalates gate-killed) and by the driven red-gate case (still pre-advance-failed); this control does NOT push a mutated registry through a subprocess marathon, and the pairing rather than a single end-to-end mutation is what is claimed."}
# GH-457: the gate's caps come from a TIER, and the default tier must not be smaller than the gate.
#
# The defect: one 900s wall cap served both "catch a runaway" and "allow the honest full suite".
# `bash validate.sh` measured 957s, so a fully GREEN gate returned gate-killed (108) at the shipped
# default — a resource kill dressed as a verdict, which is #407's failure mode arriving from the
# resource side. Both Litmus wave-2 runs needed a run-time override to avoid it.
#
# What is pinned here, in the order the criteria are written on the issue:
#   (1) the default tier's caps EXCEED the worst observed real gate runtime, with no override set
#   (2) tier membership is one declared registry, and an unknown tier falls back LOUDLY
#   (3) a tier overrun is attributed `gate-killed`, never `pre-advance-failed`
#   (4) a genuinely RED gate is still `pre-advance-failed` — the anti-overcorrection assertion
#   (5) a per-variable override still beats the tier, so a phase can retune one cap in place
#   (6) the RSS default is UNCHANGED and untiered (macOS refuses RLIMIT_AS/RLIMIT_DATA, so the
#       process-group poll is the only layer protecting the host)
#
# (4) is the one that matters most. The cheap way to satisfy everything else is to widen what counts
# as gate-killed, which would pass every other assertion here and reintroduce #407 from the opposite
# direction: a real gate failure reported as a resource kill. A false kill wastes a round; a false
# green hides a defect, so the asymmetry is deliberate.
set -euo pipefail

source "$(dirname "$0")/_setup.sh" gh457-gate-tiers
export TICK_BIN="$TICK"
ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"
DRIVER="$ROOT_REPO/relay-automation/marathon-drive.sh"
MD_PY="$ROOT_REPO/utils/py/marathon_drive.py"

# The worst REAL full-suite runtime observed while this issue was open. The default tier must clear
# it, or the defect is back. Recorded as a number here so a future cap change has to argue with it.
WORST_OBSERVED_WALL_S=957
WORST_OBSERVED_CPU_S=533

# ── (1)(2)(5)(6) the registry, driven directly ────────────────────────────────────────────
# A direct import rather than a driven phase: these are properties of the resolver, and driving a
# marathon to observe a dict would be slower and prove less.
out="$(python3 - "$MD_PY" "$WORST_OBSERVED_WALL_S" "$WORST_OBSERVED_CPU_S" <<'PY'
import importlib.util, os, sys

spec = importlib.util.spec_from_file_location("marathon_drive", sys.argv[1])
d = importlib.util.module_from_spec(spec); spec.loader.exec_module(d)
worst_wall, worst_cpu = int(sys.argv[2]), int(sys.argv[3])

for var in ("MARATHON_GATE_TIER", "MARATHON_GATE_WALL_S", "MARATHON_GATE_CPU_S",
            "MARATHON_GATE_RSS_MB"):
    os.environ.pop(var, None)

cfg = d._gate_guard_config()
assert cfg["tier"] == d.GATE_DEFAULT_TIER, cfg
assert cfg["wall_s"] > worst_wall, f"default wall {cfg['wall_s']}s must exceed observed {worst_wall}s"
assert cfg["cpu_s"] > worst_cpu, f"default cpu {cfg['cpu_s']}s must exceed observed {worst_cpu}s"
print("DEFAULT_CLEARS_OBSERVED")

assert len(d.GATE_TIERS) >= 2, d.GATE_TIERS
fast, full = d.GATE_TIERS["fast"], d.GATE_TIERS["full"]
assert fast["wall_s"] < full["wall_s"] and fast["cpu_s"] < full["cpu_s"], (fast, full)
print("TIERS_DECLARED")

os.environ["MARATHON_GATE_TIER"] = "fast"
assert d._gate_guard_config()["wall_s"] == fast["wall_s"]
os.environ["MARATHON_GATE_TIER"] = "no-such-tier"
assert d._gate_tier() == d.GATE_DEFAULT_TIER
print("UNKNOWN_FALLS_BACK")

os.environ["MARATHON_GATE_TIER"] = "fast"
os.environ["MARATHON_GATE_WALL_S"] = "41"
assert d._gate_guard_config()["wall_s"] == 41, "a per-variable override must beat the tier"
del os.environ["MARATHON_GATE_WALL_S"]
print("OVERRIDE_BEATS_TIER")

# RSS is not tiered and its default is pinned: a future tier edit must not quietly retune the one
# layer that actually protects this host.
assert d.GATE_RSS_MB_DEFAULT == 8192, d.GATE_RSS_MB_DEFAULT
assert all("rss_mb" not in t for t in d.GATE_TIERS.values()), d.GATE_TIERS
print("RSS_UNTIERED_AND_UNCHANGED")
PY
)"

for marker in DEFAULT_CLEARS_OBSERVED TIERS_DECLARED UNKNOWN_FALLS_BACK OVERRIDE_BEATS_TIER \
              RSS_UNTIERED_AND_UNCHANGED; do
  printf '%s' "$out" | /usr/bin/grep -Fq "$marker" \
    && pass "registry: $marker" \
    || fail "registry: $marker not observed — got: $out"
done

# ── fixture: a marathon root whose gate we swap per case ──────────────────────────────────
ROOT="$WORK/target"
mkdir -p "$ROOT"
git init -q "$ROOT"
git -C "$ROOT" config user.email gh457@t
git -C "$ROOT" config user.name gh457
printf '.tick/\n' > "$ROOT/.gitignore"
printf '#!/usr/bin/env bash\nexit 0\n' > "$ROOT/validate.sh"
git -C "$ROOT" add .gitignore validate.sh >/dev/null 2>&1
git -C "$ROOT" commit -q -m init

STUB_RD="$WORK/relay-drive.sh"
cat > "$STUB_RD" << 'STUB_EOF'
#!/usr/bin/env bash
set -u
rf=""
while (($#)); do case "$1" in --relay-file) rf="${2:-}"; shift 2 ;; *) shift ;; esac; done
[ -n "$rf" ] && printf 'STATUS: Approved\n' >> "$rf"
exit 0
STUB_EOF
chmod +x "$STUB_RD"
STUB_BIN="$WORK/stub-bin"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_BIN"; chmod +x "$STUB_BIN"
BRIEF="$WORK/brief.md"; printf '## Do a thing\nBody.\n' > "$BRIEF"

run_driver() {  # <extra-args…>
  MARATHON_ROOT="$ROOT" \
  MARATHON_RELAY_DRIVE="$STUB_RD" \
  MARATHON_AGENT_CMD="$WORK/noop-agent" \
  TICK_REPO_ROOT="$ROOT" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB_BIN" AGY_BIN="$STUB_BIN" CODEX_BIN="$STUB_BIN" \
  bash "$DRIVER" \
    --phases-dir "$ROOT/phases" \
    --phase-brief "$BRIEF" \
    --reviewer agy \
    --builder claude \
    "$@"
}
esc_reason() { sed -n 's/^reason: //p' "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null; }

# ── (1) a green gate passes under DEFAULT caps with NO override ───────────────────────────
# This is the defect, driven: before tiering, a gate slower than 900s was killed while green.
# A 900s gate cannot be run in a test, so the assertion is that no override is present AND the
# resolved cap exceeds the worst real measurement (proved above) AND a green gate completes.
printf '#!/usr/bin/env bash\nsleep 2\nexit 0\n' > "$ROOT/validate.sh"
( unset MARATHON_GATE_TIER MARATHON_GATE_WALL_S MARATHON_GATE_CPU_S MARATHON_GATE_RSS_MB
  run_driver --phase-id tier-green ) > "$WORK/green.log" 2>&1 && rc=0 || rc=$?
[ "$rc" -eq 0 ] \
  && pass "a green gate completes under default tier caps with no override set (exit 0)" \
  || fail "green gate did not complete under defaults: exit $rc — $(tail -3 "$WORK/green.log")"
/usr/bin/grep -q 'tier full' "$WORK/green.log" \
  && pass "the guard records WHICH tier it applied, so the caps are readable after the fact" \
  || fail "no tier recorded in the gate-guard line: $(/usr/bin/grep gate-guard "$WORK/green.log" | head -2)"

# ── (3) a tier overrun is gate-killed, not pre-advance-failed ────────────────────────────
# Driven through the fast tier with its wall cap squeezed, so the overrun is real rather than mocked.
printf '#!/usr/bin/env bash\nsleep 30\nexit 0\n' > "$ROOT/validate.sh"
MARATHON_GATE_TIER=fast MARATHON_GATE_WALL_S=3 MARATHON_GATE_POLL_S=1 \
  run_driver --phase-id tier-overrun > "$WORK/overrun.log" 2>&1 && rc=0 || rc=$?
reason="$(esc_reason tier-overrun)"
[ "$reason" = "gate-killed" ] \
  && pass "a tier wall-cap overrun escalates as gate-killed, not as the gate finding a defect" \
  || fail "tier overrun reason was '$reason', expected gate-killed"

# ── (4) anti-overcorrection: a genuinely red gate keeps pre-advance-failed ────────────────
printf '#!/usr/bin/env bash\nexit 1\n' > "$ROOT/validate.sh"
MARATHON_GATE_TIER=fast run_driver --phase-id tier-red > "$WORK/red.log" 2>&1 && rc=0 || rc=$?
reason="$(esc_reason tier-red)"
[ "$reason" = "pre-advance-failed" ] \
  && pass "a genuinely red gate is still pre-advance-failed — tiering does not relabel real failures" \
  || fail "red gate reason was '$reason', expected pre-advance-failed"

# ── the negative control (#419): mutate the tier registry and observe the caps follow ─────
# The failure mode this fix could have shipped is caps that LOOK tiered but are really hardcoded —
# every assertion above would still pass while MARATHON_GATE_TIER did nothing. So the control edits
# the registry itself and requires the resolved caps to change with it, in both directions.
#
# Scope of this control, stated rather than implied: the mutation is observed at the RESOLVER, and
# the kill it authorises is observed separately by the driven overrun case above. It does not run a
# mutated registry through a subprocess marathon. That pairing is what makes the chain
# tier -> cap -> kill observed end to end; claiming a single end-to-end mutation would overstate it.
out="$(python3 - "$MD_PY" <<'PY'
import importlib.util, os, sys

spec = importlib.util.spec_from_file_location("marathon_drive", sys.argv[1])
d = importlib.util.module_from_spec(spec); spec.loader.exec_module(d)
for var in ("MARATHON_GATE_TIER", "MARATHON_GATE_WALL_S", "MARATHON_GATE_CPU_S"):
    os.environ.pop(var, None)

real = d._gate_guard_config()["wall_s"]

# MUTATION: the default tier now permits 1 second, below the runtime of any real gate.
# (No apostrophes in this heredoc: bash tokenises quotes inside a heredoc that sits within $( ),
#  so one contraction here is an unterminated-string parse error 12 lines later. Observed.)
d.GATE_TIERS[d.GATE_DEFAULT_TIER]["wall_s"] = 1
mutated = d._gate_guard_config()["wall_s"]
assert mutated == 1, f"registry mutation did not reach the resolver (got {mutated}) — the caps are hardcoded"

# RESTORED: the same call returns the shipped value again, so the difference is the registry and
# nothing ambient.
d.GATE_TIERS[d.GATE_DEFAULT_TIER]["wall_s"] = real
assert d._gate_guard_config()["wall_s"] == real, "restore did not take"
print(f"CONTROL_OBSERVED real={real} mutated=1")
PY
)"
printf '%s' "$out" | /usr/bin/grep -Fq "CONTROL_OBSERVED" \
  && pass "control: mutating the tier registry moves the resolved cap, and restoring it moves back ($out)" \
  || fail "control: a registry mutation did NOT change the resolved cap — the tiering is cosmetic: $out"

echo "gh457-gate-tiers: $PASS pass, $FAIL fail"
