# Marathon Phase p1
STATUS: Approved
NEXT: codex

<!-- marathon-drive: task=MARATHON-P1-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon phase brief — gh-281-sentinel-tier1-stage0 (Sentinel Tier-1 Stage-0)

- Source: PROJECT/2-WORKING/GH-281-SENTINEL-TIER1-STAGE0.md · issue #281 (Draft v3)
- Verdict: preflight ready · Gate: `bash validate.sh`
- Suggested branch: `marathon/gh-281-sentinel-tier1-stage0-2026-07-22`

Build the three standalone, **zero-network** Tier-1 debug-capture scripts, their two covering
tests, the `.gitignore` line, and register the two tests in `validate.sh`. Reference implementations
for the two scripts are given **verbatim** below — reproduce them faithfully. The network-guard and
the two tests you design to the acceptance checks, following the cited precedents.

## Scope lock — edit ONLY these 7 paths (plus the relay file)

```
relay-automation/harvest-findings.sh
relay-automation/finding-new.sh
relay-automation/hooks/sentinel-network-guard.sh
test/sentinel-tier1.sh
test/sentinel-network-guard.sh
.gitignore
validate.sh
```

Any edit outside this set is reverted and FAILS the turn. Do **NOT** run `bash validate.sh` or any
`test/*.sh` yourself — those create temporary git fixtures inside your isolated worktree, which
containment treats as off-lane edits and can discard your whole turn. The harness runs the real gate
AFTER your turn, outside the worktree. Do not analyze the roadmap, file issues, or refactor adjacent
code. Nothing bundled here may make a network call — no `curl`/`wget`/`nc`/`gh`/`/dev/tcp`/`http`.

## Acceptance criteria — DONE when all hold

- [ ] `relay-automation/harvest-findings.sh` exists, `chmod +x`, matches the reference body below.
- [ ] `relay-automation/finding-new.sh` exists, `chmod +x`, matches the reference body below.
- [ ] `relay-automation/hooks/sentinel-network-guard.sh` exists, `chmod +x`: greps the bundled path
      set for `curl`, `wget`, `nc `, `gh `, `/dev/tcp`, `http`; exits nonzero + prints findings to
      stderr on any hit; exits 0 clean. Shape mirrors `relay-automation/hooks/security-scan.sh`.
- [ ] `test/sentinel-tier1.sh` exists, `chmod +x`: feeds a relay fixture with 2 `### Side Finding`
      blocks to `harvest-findings.sh` → asserts 2 `marathon.side-finding` JSONL lines with `scope`
      and `probe` intact; runs `finding-new.sh` → asserts 1 valid line; asserts every emitted line
      parses via `python3 -c 'import json,sys;[json.loads(l) for l in sys.stdin]'`. (§1.7 #3, #5)
- [ ] `test/sentinel-network-guard.sh` exists, `chmod +x`: a BAD fixture (a `curl` line in a bundled
      path) trips the guard (nonzero); a clean fixture passes (0). Shape mirrors
      `test/security-scan.sh`. (§1.7 #6)
- [ ] `.gitignore` gains a `debug.log` entry under a `# Sentinel Tier 1 debug capture` comment.
- [ ] `validate.sh` `TESTS=(…)` array registers `sentinel-tier1.sh` and `sentinel-network-guard.sh`.

## Reference implementation — `relay-automation/harvest-findings.sh` (verbatim, issue §1.4)

```bash
#!/usr/bin/env bash
# harvest-findings.sh — extract `### Side Finding` blocks from a relay file and append them to
# debug.log as PDDA-output-contract JSONL findings. Read-only on the relay; append-only on
# debug.log; NO network. Best-effort — a broken harvest must never fail a phase.
# Usage: harvest-findings.sh --relay FILE [--scope S] [--repo R] [--out debug.log]
set -u
RELAY="" SCOPE="harness" REPO="" OUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --relay) RELAY="${2:-}"; shift 2 ;;
    --scope) SCOPE="${2:-harness}"; shift 2 ;;
    --repo)  REPO="${2:-}"; shift 2 ;;
    --out)   OUT="${2:-}"; shift 2 ;;
    -h|--help) echo "usage: harvest-findings.sh --relay FILE [--scope S] [--repo R] [--out FILE]"; exit 0 ;;
    *) echo "harvest-findings.sh: unexpected arg: $1" >&2; exit 2 ;;
  esac
done
[ -n "$RELAY" ] && [ -f "$RELAY" ] || exit 0
[ -n "$SCOPE" ] || SCOPE="harness"
OUT="${OUT:-debug.log}"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"

awk -v ts="$TS" -v scope="$SCOPE" -v repo="$REPO" -v relay="$RELAY" '
  function esc(s){ gsub(/\\/,"\\\\",s); gsub(/"/,"\\\"",s); gsub(/\t/," ",s); return s }
  function flush(){
    if (!inblk) return
    printf("{\"timestamp\":\"%s\",\"severity\":\"warn\",\"check\":\"marathon.side-finding\",\"scope\":\"%s\",\"repo\":\"%s\",\"file\":\"%s\",\"line\":\"\",\"message\":\"%s%s\",\"action\":\"triage\",\"probe\":\"%s\"}\n",
      ts, esc(scope), esc(repo), esc(p), esc(sy), (sc!=""?"; suspected: " esc(sc):""), esc(pr))
    inblk=0; p=""; sy=""; sc=""; pr=""
  }
  /^###[ \t]+Side Finding/ { flush(); inblk=1; next }
  inblk && (/^#/ || /^---/) { flush() }
  inblk {
    if (match($0,/^-[ \t]*path:[ \t]*/))                 p =substr($0,RLENGTH+1)
    else if (match($0,/^-[ \t]*symptom:[ \t]*/))         sy=substr($0,RLENGTH+1)
    else if (match($0,/^-[ \t]*suspected_cause:[ \t]*/)) sc=substr($0,RLENGTH+1)
    else if (match($0,/^-[ \t]*probe:[ \t]*/))           pr=substr($0,RLENGTH+1)
  }
  END { flush() }
' "$RELAY" >> "$OUT" 2>/dev/null || true
exit 0
```

## Reference implementation — `relay-automation/finding-new.sh` (verbatim, issue §1.5)

```bash
#!/usr/bin/env bash
# finding-new.sh — manually append one PDDA-output-contract JSONL finding to debug.log. NO network.
# Usage: finding-new.sh [--scope S] [--severity error|warn|info] "one-line message"
set -u
SCOPE="harness" SEV="warn" TEXT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --scope) SCOPE="${2:-harness}"; shift 2 ;;
    --severity) SEV="${2:-warn}"; shift 2 ;;
    -h|--help) echo 'usage: finding-new.sh [--scope S] [--severity error|warn|info] "message"'; exit 0 ;;
    *) TEXT="$1"; shift ;;
  esac
done
[ -n "$TEXT" ] || { echo 'finding-new.sh: a one-line message is required' >&2; exit 2; }
case "$SEV" in error|warn|info) ;; *) echo "finding-new.sh: --severity must be error|warn|info" >&2; exit 2 ;; esac
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUT="${DEBUG_LOG_FILE:-$ROOT/debug.log}"
esc(){ local s="$1"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; printf '%s' "$s"; }
printf '{"timestamp":"%s","severity":"%s","check":"manual","scope":"%s","repo":"%s","message":"%s","action":"triage"}\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$SEV" "$SCOPE" "$ROOT" "$(esc "$TEXT")" >> "$OUT"
echo "appended: $OUT"
```

## `.gitignore` addition (verbatim, issue §1.6)

Append (do not remove existing entries):

```gitignore
# Sentinel Tier 1 debug capture — local only, never committed.
debug.log
```

## Design guidance — `sentinel-network-guard.sh` + tests

- **Guard** (`relay-automation/hooks/sentinel-network-guard.sh`): read the precedent
  `relay-automation/hooks/security-scan.sh` for the fail-loud-to-stderr / nonzero-on-hit contract.
  Scan the **bundled** relay-automation paths (exclude any marked non-bundled overlay dir such as
  `sentinel-overlay/`) for `curl`, `wget`, `nc `, `gh `, `/dev/tcp`, `http`. Exit nonzero listing
  each hit; exit 0 when clean. Keep it dependency-free (grep + bash).
- **Tests**: read `test/security-scan.sh` for the bad-fixture/clean-fixture + `mktemp -d` hermetic
  harness style. Put all fixtures under `${TMPDIR:-/tmp}` — never write into the repo tree. Cover the
  acceptance bullets above exactly.

## Provenance
Generated from swarm-preflight packet (readiness=1, greenfield via artifacts_new); scope tightened
by the orchestrator from the auto-expanded covering-test set to the 7 real write paths. Full contract
in `run-candidate.json` / `readiness.json` in this dir. Producer's output; the orchestrator launches.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): relay-automation/harvest-findings.sh,relay-automation/finding-new.sh,relay-automation/hooks/sentinel-network-guard.sh,test/sentinel-tier1.sh,test/sentinel-network-guard.sh,.gitignore,validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/wt/gh-281-sentinel/bin/tick
   - /Users/noelsaw/wt/gh-281-sentinel/bin/tick claim MARATHON-P1-TURN --agent codex --paths "phases/p1/RELAY.md,relay-automation/harvest-findings.sh,relay-automation/finding-new.sh,relay-automation/hooks/sentinel-network-guard.sh,test/sentinel-tier1.sh,test/sentinel-network-guard.sh,.gitignore,validate.sh"
   - /Users/noelsaw/wt/gh-281-sentinel/bin/tick ping MARATHON-P1-TURN --agent codex
   - /Users/noelsaw/wt/gh-281-sentinel/bin/tick release MARATHON-P1-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/p1/RELAY.md and relay-automation/harvest-findings.sh,relay-automation/finding-new.sh,relay-automation/hooks/sentinel-network-guard.sh,test/sentinel-tier1.sh,test/sentinel-network-guard.sh,.gitignore,validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/harvest-findings.sh,relay-automation/finding-new.sh,relay-automation/hooks/sentinel-network-guard.sh,test/sentinel-tier1.sh,test/sentinel-network-guard.sh,.gitignore,validate.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/wt/gh-281-sentinel/bin/tick release MARATHON-P1-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/wt/gh-281-sentinel/bin/tick done MARATHON-P1-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/wt/gh-281-sentinel/bin/tick
   Edit ONLY phases/p1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · codex

- Added executable `harvest-findings.sh` and `finding-new.sh` from the supplied reference bodies.
- Added executable `sentinel-network-guard.sh`: it fails loud to stderr for network-pattern hits,
  accepts explicit hermetic fixture paths, defaults to the two bundled capture scripts, and excludes
  its own pattern-bearing source plus `sentinel-overlay/` subtrees.
- Added executable Tier-1 JSONL and network-guard tests. The JSONL test checks two harvested side
  findings (including intact `scope` and `probe`), one manual finding, and parses every emitted line;
  the guard test checks both a bad and a clean bundle fixture under `${TMPDIR:-/tmp}`.
- Added the local-only `debug.log` ignore entry and registered both tests in `validate.sh`.
- Verification performed within the containment rail: `bash -n` passed for all five new scripts,
  executable bits are set, and the guard's default scan exited 0. Per the phase brief, neither
  `test/*.sh` nor `validate.sh` was executed in this isolated worktree; the harness owns that gate.

### Round 1 · Reviewer · agy

The implementation precisely matches the phase brief. The two reference scripts were included verbatim. `sentinel-network-guard.sh` is well implemented, avoiding external network patterns and excluding `sentinel-overlay` paths. The test fixtures are hermetic and cover the acceptance criteria thoroughly. Both `.gitignore` and `validate.sh` were updated as required.

**Verdict:** Approved
