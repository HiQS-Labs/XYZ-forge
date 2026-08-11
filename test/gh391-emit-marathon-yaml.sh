#!/usr/bin/env bash
# GH-391: join ranked plan lanes with preflight packets into runnable MARATHON.yaml.
source "$(dirname "$0")/_setup.sh" gh391-emit-marathon-yaml
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EMITTER="$ROOT/utils/py/marathon_yaml_emit.py"
FIXTURE="$WORK/fixture"
PACKETS="$FIXTURE/packets"
OUT_DIR="$FIXTURE/output"
OUT="$OUT_DIR/MARATHON.yaml"
mkdir -p "$PACKETS/gh-10-alpha" "$PACKETS/gh-20-beta" "$OUT_DIR"

cat > "$FIXTURE/plan.md" <<'PLAN'
# Fixture plan

## Per-item scoring

| Item | cx | risk | eff | zone | deps | score | wave |
|---|---|---|---|---|---|---|---|
| [#10] GH-10 · alpha lane | 1 | 1 | 1 | independent | — | 4 | 1 |
| [#20] GH-20 · beta lane | 1 | 1 | 1 | independent | #10 | 5 | 2 |

## Recommended waves
PLAN

cat > "$PACKETS/gh-10-alpha/packet.md" <<'PACKET'
# Marathon preflight packet — gh-10-alpha

- Sources: PROJECT/2-WORKING/GH-10-ALPHA.md
- Verdict: ready
- Artifacts: README.md
PACKET
cat > "$PACKETS/gh-20-beta/packet.md" <<'PACKET'
# Marathon preflight packet — gh-20-beta

- Sources: PROJECT/2-WORKING/GH-20-BETA.md
- Verdict: ready
- Artifacts: validate.sh,test/gh391-emit-marathon-yaml.sh
PACKET

plan_before="$(cksum "$FIXTURE/plan.md")"
packets_before="$(find "$PACKETS" -type f -exec cksum {} \; | LC_ALL=C sort)"
files_before="$(find "$FIXTURE" -type f | LC_ALL=C sort)"
if python3 "$EMITTER" --plan "$FIXTURE/plan.md" --packets "$PACKETS" \
    --reviewer agy --output "$OUT" >"$WORK/emit.out" 2>"$WORK/emit.err"; then
  pass "documented command emits MARATHON.yaml without hand editing"
else
  fail "emitter failed: $(cat "$WORK/emit.err")"
fi

[ "$plan_before" = "$(cksum "$FIXTURE/plan.md")" ] \
  && [ "$packets_before" = "$(find "$PACKETS" -type f -exec cksum {} \; | LC_ALL=C sort)" ] \
  && pass "plan and packets remain byte-identical" \
  || fail "emitter mutated a plan or packet"
files_after_without_output="$(find "$FIXTURE" -type f ! -path "$OUT" | LC_ALL=C sort)"
[ "$files_before" = "$files_after_without_output" ] \
  && pass "emitter writes only the supplied output path" \
  || fail "emitter wrote a path other than $OUT"

if node "$ROOT/bin/marathon-yaml" "$OUT" >"$WORK/phases.tsv" 2>"$WORK/yaml.err"; then
  pass "existing bin/marathon-yaml oracle accepts emitted output"
else
  fail "bin/marathon-yaml rejected output: $(cat "$WORK/yaml.err")"
fi
[ "$(cut -f1 "$WORK/phases.tsv" | paste -sd, -)" = "gh10,gh20" ] \
  && pass "phase ids and order follow the plan ranking" \
  || fail "emitted phase order is wrong: $(cat "$WORK/phases.tsv")"
[ "$(cut -f2 "$WORK/phases.tsv" | paste -sd, -)" = "agy,agy" ] \
  && pass "explicit reviewer is copied to every phase" \
  || fail "reviewer flag was not preserved"
[ "$(awk -F '\t' '$1=="gh10" {print $4}' "$WORK/phases.tsv")" = "" ] \
  && [ "$(awk -F '\t' '$1=="gh20" {print $4}' "$WORK/phases.tsv")" = "gh10" ] \
  && [ "$(grep -c '^    depends_on:' "$OUT")" -eq 1 ] \
  && pass "only the recorded dependency is emitted, in scalar id form" \
  || fail "depends_on was fabricated, omitted, or emitted in the wrong form"
[ "$(awk -F '\t' '$1=="gh10" {print $6}' "$WORK/phases.tsv")" = "README.md" ] \
  && [ "$(awk -F '\t' '$1=="gh20" {print $6}' "$WORK/phases.tsv")" = "validate.sh,test/gh391-emit-marathon-yaml.sh" ] \
  && pass "artifact fields come from their packets" \
  || fail "packet artifacts were not preserved"

if MARATHON_ROOT="$ROOT" MARATHON_HOME="$ROOT" MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 \
    CODEX_BIN=true AGY_BIN=true \
    bash "$ROOT/relay-automation/marathon.sh" --plan "$OUT" --dry-run \
      --phases-dir "$WORK/phases" >"$WORK/dry-run.out" 2>"$WORK/dry-run.err"; then
  pass "existing marathon.sh --dry-run oracle accepts emitted output"
else
  fail "marathon.sh --dry-run rejected output: $(cat "$WORK/dry-run.err")"
fi

EMPTY="$FIXTURE/empty-packets"
mkdir -p "$EMPTY"
if python3 "$EMITTER" --plan "$FIXTURE/plan.md" --packets "$EMPTY" \
    --reviewer agy --output "$OUT_DIR/missing.yaml" >"$WORK/missing.out" 2>"$WORK/missing.err"; then
  fail "emitter accepted an absent packet fixture"
elif grep -q "packet for lane #10" "$WORK/missing.err" \
    && [ ! -e "$OUT_DIR/missing.yaml" ]; then
  pass "negative control observes missing packets rejected before output"
else
  fail "missing-packet refusal did not name the lane: $(cat "$WORK/missing.err")"
fi

MALFORMED="$FIXTURE/malformed-packets"
mkdir -p "$MALFORMED/gh-10-alpha"
cat > "$MALFORMED/gh-10-alpha/packet.md" <<'PACKET'
# Marathon preflight packet — gh-10-alpha
- Sources: PROJECT/2-WORKING/GH-10-ALPHA.md
- Verdict: ready
PACKET
if python3 "$EMITTER" --plan "$FIXTURE/plan.md" --packets "$MALFORMED" \
    --reviewer agy --output "$OUT_DIR/malformed.yaml" 2>"$WORK/malformed.err"; then
  fail "emitter accepted a malformed packet"
elif grep -q "$MALFORMED/gh-10-alpha/packet.md" "$WORK/malformed.err"; then
  pass "malformed packet is rejected and named"
else
  fail "malformed-packet error did not name its packet: $(cat "$WORK/malformed.err")"
fi

DUPLICATE="$FIXTURE/duplicate-packets"
mkdir -p "$DUPLICATE/one" "$DUPLICATE/two"
cp "$PACKETS/gh-10-alpha/packet.md" "$DUPLICATE/one/packet.md"
cp "$PACKETS/gh-10-alpha/packet.md" "$DUPLICATE/two/packet.md"
if python3 "$EMITTER" --plan "$FIXTURE/plan.md" --packets "$DUPLICATE" \
    --reviewer agy --output "$OUT_DIR/duplicate.yaml" 2>"$WORK/duplicate.err"; then
  fail "emitter accepted duplicate packets"
elif grep -q "duplicate packet for lane #10" "$WORK/duplicate.err"; then
  pass "duplicate packets are rejected and named"
else
  fail "duplicate-packet error was not actionable: $(cat "$WORK/duplicate.err")"
fi

UNMATCHED="$FIXTURE/unmatched-packets"
mkdir -p "$UNMATCHED/gh-10-alpha" "$UNMATCHED/gh-20-beta" "$UNMATCHED/gh-30-extra"
cp "$PACKETS/gh-10-alpha/packet.md" "$UNMATCHED/gh-10-alpha/packet.md"
cp "$PACKETS/gh-20-beta/packet.md" "$UNMATCHED/gh-20-beta/packet.md"
cat > "$UNMATCHED/gh-30-extra/packet.md" <<'PACKET'
# Marathon preflight packet — gh-30-extra
- Sources: PROJECT/2-WORKING/GH-30-EXTRA.md
- Verdict: ready
- Artifacts: README.md
PACKET
if python3 "$EMITTER" --plan "$FIXTURE/plan.md" --packets "$UNMATCHED" \
    --reviewer agy --output "$OUT_DIR/unmatched.yaml" 2>"$WORK/unmatched.err"; then
  fail "emitter accepted a packet with no plan lane"
elif grep -q "$UNMATCHED/gh-30-extra/packet.md" "$WORK/unmatched.err"; then
  pass "unmatched packet is rejected and named"
else
  fail "unmatched-packet error did not name its packet: $(cat "$WORK/unmatched.err")"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
