#!/usr/bin/env bash
set -euo pipefail
#
# sentinel-route.sh — PoC of the 3-tier local doc-governance chain:
#
#   changed doc ─▶ (0) deterministic checks ─▶ (1) Cactus/Needle router ─▶
#                  (2) Gemma-4-12B structured review ─▶ (3) Antigravity escalation
#                  ─▶ append one JSONL line to PDDA-ACTIVITY.jsonl
#
# All three tiers run locally (Needle + Gemma) / off the signed-in desktop app (agy).
# This is a WIRING proof — it exercises every hop for ONE doc. It reads the target
# doc read-only and writes only its own activity log; it mutates no repo.
#
# Deps: curl, python3, agy (Antigravity CLI). Endpoints must be up:
#   cactus serve Cactus-Compute/needle   # :8080
#   LM Studio with gemma-4-12b-it-mlx     # :1234
#
# Usage:  sentinel-route.sh <doc.md>
# Env (all optional, sane defaults):
#   CACTUS_URL   (http://127.0.0.1:8080/v1)   CACTUS_MODEL (needle-cq4)
#   GEMMA_URL    (http://localhost:1234/v1)   GEMMA_MODEL  (gemma-4-12b-it-mlx)
#   AGY_BIN      (agy)                        AGY_TIMEOUT  (60s)
#   ACTIVITY_LOG (<scriptdir>/PDDA-ACTIVITY.jsonl)
#   ALLOW_ESCALATE (1)  — set 0 to skip the agy hop (saves the real API turn)

DOC="${1:?usage: sentinel-route.sh <doc.md>}"
[[ -f "$DOC" ]] || { echo "sentinel-route: no such doc: $DOC" >&2; exit 2; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACTUS_URL="${CACTUS_URL:-http://127.0.0.1:8081/v1}"
CACTUS_MODEL="${CACTUS_MODEL:-needle-cq4}"
GEMMA_URL="${GEMMA_URL:-http://localhost:1234/v1}"
GEMMA_MODEL="${GEMMA_MODEL:-gemma-4-12b-it-mlx}"
AGY_BIN="${AGY_BIN:-agy}"
AGY_TIMEOUT="${AGY_TIMEOUT:-60s}"
ACTIVITY_LOG="${ACTIVITY_LOG:-$HERE/PDDA-ACTIVITY.jsonl}"
ALLOW_ESCALATE="${ALLOW_ESCALATE:-1}"

hr() { printf '\n\033[1;36m── %s ──\033[0m\n' "$*"; }

# ───────────────────────────────────────────────────────────────────────────
# (0) Deterministic checks — instant, blocking, no LLM. A tiny stand-in for
#     `pdda.sh frontmatter|roadmap-coverage|...`. Emits gaps as a compact string.
# ───────────────────────────────────────────────────────────────────────────
det_summary="$(python3 - "$DOC" <<'PY'
import sys, re
doc = open(sys.argv[1], encoding="utf-8", errors="replace").read()
gaps = []
if not doc.lstrip().startswith("---"):        gaps.append("no-frontmatter")
if not re.search(r'(?im)^\s*status\b', doc):  gaps.append("no-status-field")
if "ROADMAP" not in doc:                       gaps.append("no-roadmap-pointer")
if not re.search(r'(?im)^\s*related:', doc):   gaps.append("no-related-links")
print("clean" if not gaps else ",".join(gaps))
PY
)"
hr "0. deterministic checks"
printf 'doc:   %s\ngaps:  %s\n' "$DOC" "$det_summary"

# ───────────────────────────────────────────────────────────────────────────
# (1) Cactus / Needle router — 26M on-device tool-caller. We hand it ONE tool
#     (set_route) and let it emit the routing decision as a function call.
#     Stock Needle routes off tool-calling; a 100-example finetune (issue #38)
#     would sharpen the route/mode choice. We default to "readiness" if it
#     declines to call the tool.
# ───────────────────────────────────────────────────────────────────────────
hr "1. Needle router (Cactus :8080)"
needle_body="$(python3 - "$DOC" "$det_summary" "$CACTUS_MODEL" <<'PY'
import sys, json, os
path, det, model = sys.argv[1], sys.argv[2], sys.argv[3]
head = open(path, encoding="utf-8", errors="replace").read()[:1200]
body = {
  "model": model,
  "messages": [
    {"role": "system", "content":
     "You are a doc-governance routing sentinel. For a changed document, call set_route "
     "to decide: 'skip' if trivial, 'readiness' for a normal LLM review, 'escalate' if "
     "it has architectural/security risk. Pick mode from the repo posture."},
    {"role": "user", "content":
     f"Changed doc: {os.path.basename(path)}\nDeterministic gaps: {det}\n"
     f"First lines:\n{head}\n\nCall set_route now."},
  ],
  "tools": [{"type": "function", "function": {
    "name": "set_route",
    "description": "Route a changed governance document.",
    "parameters": {"type": "object", "properties": {
      "route": {"type": "string", "enum": ["skip", "readiness", "escalate"]},
      "mode":  {"type": "string", "enum": ["observe", "light", "full"]},
      "reason": {"type": "string"},
    }, "required": ["route", "mode", "reason"]},
  }}],
  "max_tokens": 96, "temperature": 0,
}
print(json.dumps(body))
PY
)"
needle_resp="$(curl -s --max-time 30 "$CACTUS_URL/chat/completions" \
  -H 'Content-Type: application/json' --data "$needle_body")"
route_json="$(python3 - <<PY
import json
r = json.loads(r'''$needle_resp''')
try:
    tc = r["choices"][0]["message"]["tool_calls"][0]["function"]["arguments"]
    d = json.loads(tc)
except Exception:
    d = {"route": "readiness", "mode": "full", "reason": "default (no tool_call)"}
d.setdefault("route", "readiness"); d.setdefault("mode", "full"); d.setdefault("reason", "")
print(json.dumps(d))
PY
)"
# v0 REALITY CHECK: stock Needle (26M, no finetune) emits syntactically-valid but
# semantically-wrong tool args (it echoes enum literals / the filename). So its route is
# ADVISORY ONLY here — issue #38's "100-example finetune" is what makes this slot trustworthy.
# Until then v0 always runs the (cheap, local) Gemma pass and escalates on Gemma's verdict.
printf 'needle raw (advisory): %s\n' "$route_json"
ROUTE="readiness"; MODE="full"
printf '\033[0;33mroute (v0 rule): %s | mode: %s  — Needle advisory, finetune pending\033[0m\n' "$ROUTE" "$MODE"

# ───────────────────────────────────────────────────────────────────────────
# (2) Gemma-4-12B structured review — only if Needle didn't say 'skip'.
#     3 passes folded into one JSON-mode call (completeness / quality / critique).
# ───────────────────────────────────────────────────────────────────────────
review_json='{"skipped":true}'
if [[ "$ROUTE" != "skip" ]]; then
  hr "2. Gemma structured review (LM Studio :1234)"
  gemma_body="$(python3 - "$DOC" "$GEMMA_MODEL" <<'PY'
import sys, json
path, model = sys.argv[1], sys.argv[2]
doc = open(path, encoding="utf-8", errors="replace").read()[:8000]
# LM Studio (MLX) requires response_format.type == "json_schema" (NOT "json_object").
schema = {"type": "json_schema", "json_schema": {"name": "pdda_review", "strict": True,
  "schema": {"type": "object", "properties": {
    "score": {"type": "number"},
    "gaps": {"type": "array", "items": {"type": "string"}},
    "quality_notes": {"type": "array", "items": {"type": "string"}},
    "critiques": {"type": "array", "items": {"type": "string"}},
    "residual_risk": {"type": "array", "items": {"type": "string"}},
    "recommendation": {"type": "string", "enum": ["pass", "revise", "block"]},
  }, "required": ["score", "gaps", "critiques", "residual_risk", "recommendation"]}}}
body = {
  "model": model,
  "messages": [
    {"role": "system", "content":
     "You are a strict PDDA readiness reviewer. Evaluate the doc in three passes: "
     "(1) completeness & contract, (2) quality of each point, (3) adversarial critique "
     "(a skeptical maintainer finds drift)."},
    {"role": "user", "content": f"Document:\n\n{doc}"},
  ],
  "response_format": schema,
  "max_tokens": 700, "temperature": 0.2,
}
print(json.dumps(body))
PY
)"
  gemma_resp="$(curl -s --max-time 120 "$GEMMA_URL/chat/completions" \
    -H 'Content-Type: application/json' --data "$gemma_body")"
  review_json="$(python3 - <<PY
import json
r = json.loads(r'''$gemma_resp''')
try:
    content = r["choices"][0]["message"]["content"]
    d = json.loads(content)
except Exception as e:
    d = {"error": f"parse: {e}", "raw": r}
print(json.dumps(d))
PY
)"
  python3 -c "import json,sys;d=json.loads(sys.argv[1]);print('score:      ',d.get('score'));print('recommend:  ',d.get('recommendation'));print('gaps:       ',d.get('gaps'));print('residual:   ',d.get('residual_risk'))" "$review_json" 2>/dev/null \
    || echo "$review_json"
fi

# ───────────────────────────────────────────────────────────────────────────
# (3) Antigravity escalation — only when Needle OR Gemma asks for it. Real turn.
# ───────────────────────────────────────────────────────────────────────────
escalated="false"; agy_out=""
NEED_ESC="$(python3 -c "
import json,sys
route=sys.argv[1]; rev=json.loads(sys.argv[2])
print('1' if route=='escalate' or rev.get('recommendation')=='block' or rev.get('residual_risk') else '0')
" "$ROUTE" "$review_json")"
if [[ "$ALLOW_ESCALATE" == "1" && "$NEED_ESC" == "1" ]]; then
  hr "3. Antigravity escalation (agy -p)"
  esc_prompt="You are a senior reviewer. A doc-governance sentinel escalated $(basename "$DOC").
Gemma's structured review was: $review_json
In 4 bullet points: the single highest-risk gap, whether it should BLOCK, and the one concrete edit to make. Be terse."
  agy_out="$("$AGY_BIN" -p "$esc_prompt" --print-timeout "$AGY_TIMEOUT" < /dev/null 2>&1 || true)"
  escalated="true"
  printf '%s\n' "$agy_out"
else
  hr "3. Antigravity escalation — skipped ($([[ "$ALLOW_ESCALATE" == 1 ]] && echo 'not needed' || echo 'ALLOW_ESCALATE=0'))"
fi

# ───────────────────────────────────────────────────────────────────────────
# emit one activity line (the existing PROJECT/PDDA-ACTIVITY.jsonl contract)
# ───────────────────────────────────────────────────────────────────────────
python3 - "$DOC" "$det_summary" "$route_json" "$review_json" "$escalated" "$ACTIVITY_LOG" <<'PY'
import sys, json
doc, det, route_json, review_json, escalated, log = sys.argv[1:7]
rec = {
  "ts": None,  # PoC: harness would stamp; scripts here can't call time
  "doc": doc,
  "deterministic": det,
  "route": json.loads(route_json),
  "review": json.loads(review_json),
  "escalated": escalated == "true",
}
with open(log, "a", encoding="utf-8") as f:
    f.write(json.dumps(rec) + "\n")
print(f"\n\033[1;32m✓ logged →\033[0m {log}")
PY
