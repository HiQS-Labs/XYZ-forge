#!/usr/bin/env bash
# GH-346 Phase 0: model-telemetry honesty.
#
# The bug this pins: every turn shim resolves a dispatch model near the top of main(), then builds
# a HarnessTurnLogger near the bottom. Five of the eight shims re-read the SAME env var at the
# logger with a SECOND, DIFFERENT hardcoded default -- so whenever the operator left the model var
# unset, harnesses.db recorded a model that never ran:
#
#   claude-turn.py       dispatched claude-sonnet-4-6            logged anthropic/claude-3-7-sonnet
#   commandcode-turn.py  dispatched meta/muse-spark-1.2-...      logged Qwen/Qwen3.8-Max
#   aider-turn.py        dispatched 1 of 2 seam-dependent values logged a 3rd, unrelated value
#   agy-turn.py          passed NO --model (agy's own default)   logged antigravity/gemini-2.5-pro
#   codex-turn.py        passed NO --model (codex's own default) logged openai/gpt-5-codex
#
# The invariant: a shim may log a variable it actually dispatched, or log nothing and let
# HarnessTurnLogger fall back to device_config's resolver. It may NEVER invent a model id with a
# second hardcoded literal that no dispatch path can produce.
#
# This is a STATIC test (ast-based). It cannot be defeated by an unreachable env default the way a
# runtime test with the var set would be, and it needs no agent CLI, network, or relay scaffolding.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: gh346-model-telemetry-honesty =="

# --- 1. no shim may pass a hardcoded literal fallback as model_id ------------------------------
report="$(python3 - "$ROOT" <<'PY'
import ast, os, sys

root = sys.argv[1]
pydir = os.path.join(root, "utils", "py")

def env_get_default(node):
    """If node is os.environ.get(X, <str literal>), return that literal, else None."""
    if not isinstance(node, ast.Call):
        return None
    fn = node.func
    if not (isinstance(fn, ast.Attribute) and fn.attr == "get"):
        return None
    # match os.environ.get(...)
    tgt = fn.value
    if not (isinstance(tgt, ast.Attribute) and tgt.attr == "environ"):
        return None
    if len(node.args) < 2:
        return None
    d = node.args[1]
    if isinstance(d, ast.Constant) and isinstance(d.value, str) and d.value.strip():
        return d.value
    return None

def model_id_arg(path):
    """Return (found, kind, detail) for the model_id kwarg of a HarnessTurnLogger call."""
    with open(path) as fh:
        tree = ast.parse(fh.read(), filename=path)
    for node in ast.walk(tree):
        if not isinstance(node, ast.Call):
            continue
        fn = node.func
        name = fn.id if isinstance(fn, ast.Name) else getattr(fn, "attr", None)
        if name != "HarnessTurnLogger":
            continue
        for kw in node.keywords:
            if kw.arg != "model_id":
                continue
            v = kw.value
            lit = env_get_default(v)
            if lit is not None:
                return (True, "hardcoded", lit)
            # `os.environ.get(X) or None` / `... or <name>`
            if isinstance(v, ast.BoolOp):
                for operand in v.values:
                    lit = env_get_default(operand)
                    if lit is not None:
                        return (True, "hardcoded", lit)
                    if isinstance(operand, ast.Constant) and isinstance(operand.value, str) and operand.value.strip():
                        return (True, "hardcoded", operand.value)
                return (True, "ok-or", ast.dump(v)[:40])
            if isinstance(v, ast.Name):
                return (True, "ok-var", v.id)
            return (True, "ok-other", type(v).__name__)
        return (True, "missing-kwarg", "")
    return (False, "no-logger", "")

shims = sorted(f for f in os.listdir(pydir) if f.endswith("-turn.py"))
bad = []
seen = 0
for s in shims:
    found, kind, detail = model_id_arg(os.path.join(pydir, s))
    if not found:
        continue
    seen += 1
    if kind == "hardcoded":
        bad.append(f"{s}: model_id falls back to hardcoded {detail!r}")
    elif kind == "missing-kwarg":
        bad.append(f"{s}: HarnessTurnLogger called with no model_id")

print(f"SHIMS={seen}")
for b in bad:
    print(f"BAD={b}")
PY
)"
rc=$?
if [ "$rc" != 0 ]; then
  fail "ast scan failed to run (rc=$rc)"
else
  shims="$(printf '%s\n' "$report" | sed -n 's/^SHIMS=//p')"
  bad="$(printf '%s\n' "$report" | sed -n 's/^BAD=//p')"
  if [ "${shims:-0}" -lt 7 ]; then
    fail "expected >=7 turn shims with a HarnessTurnLogger call, scanned ${shims:-0} — did the scan silently match nothing?"
  else
    pass "scanned $shims turn shims for model_id honesty"
  fi
  if [ -n "$bad" ]; then
    while IFS= read -r line; do
      [ -n "$line" ] && fail "$line"
    done <<EOF
$bad
EOF
  else
    pass "no shim invents a model id with a hardcoded telemetry fallback"
  fi
fi

# --- 2. the five named regressions stay fixed, by exact literal ---------------------------------
# Belt-and-braces: even if the ast walk above is ever weakened, these grep for the exact drifted
# literals that were live at the time this issue was filed.
check_absent() {
  # check_absent <file> <literal>
  file="$ROOT/utils/py/$1"; lit="$2"
  if [ ! -f "$file" ]; then
    fail "$1 not found"
    return
  fi
  if grep -q -- "$lit" "$file"; then
    # tolerate the literal appearing in an explanatory comment, not in code
    if grep -qv '^[0-9]*: *#' <<<"$(grep -n -- "$lit" "$file")"; then
      fail "$1 still references drifted telemetry literal '$lit' outside a comment"
      return
    fi
  fi
  pass "$1: drifted literal '$lit' no longer live"
}
check_absent claude-turn.py      "anthropic/claude-3-7-sonnet"
check_absent commandcode-turn.py "Qwen/Qwen3.8-Max"
check_absent aider-turn.py       "openrouter/deepseek/deepseek-v4-pro"
check_absent agy-turn.py         "antigravity/gemini-2.5-pro"
check_absent codex-turn.py       "openai/gpt-5-codex"

# --- 3. passing None must still resolve, or "log nothing" would mean "log nothing" --------------
# agy/codex now pass None when the operator picked no model. That is only honest if
# HarnessTurnLogger substitutes device_config's resolved default rather than writing a null.
if grep -q 'self.model_id = model_id or self.cfg\["model"\]' "$ROOT/utils/py/harness_turn_logger.py"; then
  pass "HarnessTurnLogger falls back to device_config's resolved model when model_id is None"
else
  fail "harness_turn_logger.py no longer falls back to cfg['model'] — agy/codex would log a null model"
fi

# --- 3b. the logger call must be EVALUABLE, not merely well-shaped ------------------------------
# The gap this closes, found by GLM 5.3 in QA and confirmed: three shims passed an undefined name as
# cli_flags (claude `cflags`, aider `aflags`, codex `flags`). Evaluating the argument raised
# NameError, the block's own `except Exception` swallowed it, and those gateways wrote NO telemetry
# row at all -- for the life of the shim. The original version of this test asserted only that
# model_id was honest, so it passed with flying colours over three gateways that logged nothing.
# A correct model id in a call that never runs is worth nothing.
undef="$(python3 - "$ROOT" <<'PY'
import ast, os, sys
root = sys.argv[1]
pydir = os.path.join(root, "utils", "py")
for f in sorted(x for x in os.listdir(pydir) if x.endswith("-turn.py")):
    src = open(os.path.join(pydir, f)).read()
    tree = ast.parse(src)
    bound = set(dir(__builtins__)) | {"__name__", "__file__"}
    for n in ast.walk(tree):
        if isinstance(n, ast.Name) and isinstance(n.ctx, ast.Store): bound.add(n.id)
        if isinstance(n, ast.arg): bound.add(n.arg)
        if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)): bound.add(n.name)
        if isinstance(n, (ast.Import, ast.ImportFrom)):
            for a in n.names: bound.add((a.asname or a.name).split(".")[0])
        if isinstance(n, ast.ExceptHandler) and n.name: bound.add(n.name)
    for n in ast.walk(tree):
        if not isinstance(n, ast.Call): continue
        fn = n.func
        nm = fn.id if isinstance(fn, ast.Name) else getattr(fn, "attr", None)
        if nm != "HarnessTurnLogger": continue
        for kw in n.keywords:
            for sub in ast.walk(kw.value):
                if isinstance(sub, ast.Name) and isinstance(sub.ctx, ast.Load) and sub.id not in bound:
                    print(f"{f}: {kw.arg}={sub.id} is bound nowhere — NameError, swallowed, no row written")
PY
)"
if [ -z "$undef" ]; then
  pass "every HarnessTurnLogger argument resolves — no shim's telemetry is dead code"
else
  while IFS= read -r u; do
    [ -n "$u" ] && fail "$u"
  done <<< "$undef"
fi

# --- 3c. the swallow must be visible ------------------------------------------------------------
# `except Exception: pass` is the mechanism that hid the above for the shims' entire life. Logging
# must stay non-fatal, but never silent again.
silent=0
for s in "$ROOT"/utils/py/*-turn.py; do
  if grep -q 'from harness_turn_logger import HarnessTurnLogger' "$s"; then
    if grep -q 'telemetry not recorded' "$s"; then :; else
      fail "$(basename "$s"): telemetry failure is still swallowed silently"
      silent=1
    fi
  fi
done
[ "$silent" = 0 ] && pass "a swallowed telemetry failure is reported on stderr in every shim"

# --- 4. every shim still parses ----------------------------------------------------------------
for s in "$ROOT"/utils/py/*-turn.py; do
  if python3 -c "import ast,sys; ast.parse(open(sys.argv[1]).read())" "$s" 2>/dev/null; then
    :
  else
    fail "$(basename "$s") does not parse"
  fi
done
pass "all turn shims parse"

echo "  gh346-model-telemetry-honesty: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
