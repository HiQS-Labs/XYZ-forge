#!/usr/bin/env bash
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=utils/pdda/pdda-lib.sh
. "$HERE/pdda-lib.sh"

CHECK_NAME="pdda-doc-ready"
EXIT_CODE=0

# LLM-assisted readiness review (PDDA.md "2. LLM-assisted doc readiness review"). This is the EXPENSIVE
# layer and is OPT-IN: set PDDA_LLM_BIN to a model CLI (+ PDDA_LLM_ARGS for its print flag). Unset or
# not on PATH => skip gracefully (advisory info, exit 0) so the deterministic hourly run never breaks
# when no model/network is available. Examples:
#   PDDA_LLM_BIN=agy   PDDA_LLM_ARGS="-p"  PDDA_LLM_MODEL="Gemini 3.1 Pro (High)"  (run sandbox-OFF — agy can hang)
#   PDDA_LLM_BIN=codex PDDA_LLM_ARGS="exec"
#   PDDA_LLM_BIN=claude PDDA_LLM_ARGS="-p"
# PDDA_LLM_ARGS is word-split (simple flags only); a model NAME with spaces goes via PDDA_LLM_MODEL so
# it survives as a single argument.
PDDA_LLM_BIN="${PDDA_LLM_BIN:-}"
PDDA_LLM_ARGS="${PDDA_LLM_ARGS:--p}"

if [ -z "$PDDA_LLM_BIN" ] || ! command -v "$PDDA_LLM_BIN" >/dev/null 2>&1; then
  pdda_record_finding info "$CHECK_NAME" "$PDDA_REPO_ROOT" 0 \
    "LLM readiness review skipped (set PDDA_LLM_BIN to a model CLI such as agy/codex/claude to enable)" "skip"
  pdda_emit_summary "$CHECK_NAME" 0
  exit 0
fi

# Word-split the flags; append a spaced-safe --model only if PDDA_LLM_MODEL is set.
read -ra _llm_args <<<"$PDDA_LLM_ARGS"
[ -n "${PDDA_LLM_MODEL:-}" ] && _llm_args+=(--model "$PDDA_LLM_MODEL")

# The rubric flags ONLY readiness gaps; it deliberately does NOT re-lint frontmatter / status-table /
# paths (those are the deterministic checks) and does NOT rewrite or invent claims (PDDA.md "It should not").
read -r -d '' RUBRIC <<'RUBRIC_EOF' || true
You are a documentation-readiness reviewer for a phased-plan repo. Review the project doc below and
flag ONLY readiness gaps. Do NOT rewrite it, do NOT invent technical claims, and do NOT report
frontmatter/status-table/hardcoded-path issues (separate deterministic checks own those). Flag:
- a phased plan with a phase that has no QA gate / acceptance criteria after it
- a phase that lists actions but no observable acceptance criteria
- a multi-phase plan with no table of contents listing its phases
- a discovery or spike phase (named "Discovery"/"Spike", or doc_type research) whose findings were NOT
  written back into this doc — i.e. it reverse-engineered or probed something but left no captured
  findings (what was investigated, what was found, what it changes for later phases)
- a medium-large plan or project (NOT a typo / path repoint / <=2-3 line fix) whose frontmatter is
  missing the triage ratings effort, complexity, risk, phases (used by automation to select work);
  do NOT flag genuinely small/trivial docs for this
- a status table that is present but stale versus the body
- the next action buried in prose instead of stated explicitly
- detail duplicated from another canonical doc
- contradictory status (e.g. frontmatter says Completed while the body is active)
Output ONE JSON object per finding, one per line, and NOTHING else. Schema:
{"severity":"warn|info","line":<integer or 0>,"message":"<one concise sentence>"}
This review is advisory and never blocks a build: use "warn" for a strong readiness concern and "info"
for advisory. Do NOT emit "error" — a non-deterministic review must not gain build-blocking power.
If the doc is ready, output nothing at all.
RUBRIC_EOF

# ROADMAP.md pointer-only contract (PDDA.md "ROADMAP.md contract"). Honors the deliberate carve-out
# ("a short exception note is allowed when omitting would hide an operationally critical fact"), which
# is exactly why this is judged by the LLM layer rather than a brittle deterministic lint.
read -r -d '' ROADMAP_RUBRIC <<'ROADMAP_EOF' || true
You are reviewing a repo's ROADMAP.md against its "pointer file, not a plan body" contract. It SHOULD
contain only: projects in progress, completed, attempted, deferred, and links to the canonical project
docs. It SHOULD NOT contain detailed phase checklists, step-by-step build instructions, or deep
execution notes that belong in an individual project doc. IMPORTANT carve-out: a SHORT exception note
is allowed when omitting it would hide an operationally critical fact — do NOT flag those.
Flag ONLY genuine contract violations (execution detail that should live in a project doc). Do NOT
rewrite. Output ONE JSON object per finding, one per line, NOTHING else. Schema:
{"severity":"warn|info","line":<integer or 0>,"message":"<one concise sentence>"}
This review is advisory and never blocks: use "warn" for a clear violation and "info" for borderline.
Do NOT emit "error". If ROADMAP.md honors the contract, output nothing.
ROADMAP_EOF

# Parse the model's output: keep only lines that look like a JSON object, extract fields via node
# (already a dependency, see pdda_json_escape). Malformed/prose lines are skipped, not fatal.
parse_finding() {  # reads one JSON line on stdin -> "severity\tline\tmessage" or empty
  node -e '
    let s = "";
    process.stdin.on("data", d => s += d).on("end", () => {
      try {
        const o = JSON.parse(s);
        const sev = (o.severity === "warn" || o.severity === "info" || o.severity === "error") ? o.severity : "info";
        const line = Number.isInteger(o.line) ? o.line : 0;
        const msg = typeof o.message === "string" ? o.message.replace(/[\t\r\n]+/g, " ").trim() : "";
        if (msg) process.stdout.write(sev + "\t" + line + "\t" + msg);
      } catch (e) { /* not JSON — skip */ }
    });
  ' 2>/dev/null
}

# Review ONE doc against <rubric>; record any findings. Used for both the working docs and ROADMAP.
review_one() {  # <file> <rubric>
  local file="$1" rubric="$2" rel response parsed sev ln msg jline
  rel="$(pdda_relpath "$file")"
  response="$("$PDDA_LLM_BIN" ${_llm_args[@]+"${_llm_args[@]}"} "$rubric

=== DOC: $rel ===
$(cat "$file")" 2>/dev/null || true)"
  [ -n "$response" ] || return 0
  while IFS= read -r jline; do
    case "$jline" in
      '{'*'}') ;;          # only attempt lines that look like a single JSON object
      *) continue ;;
    esac
    parsed="$(printf '%s' "$jline" | parse_finding)"
    [ -n "$parsed" ] || continue
    IFS=$'\t' read -r sev ln msg <<PARSED
$parsed
PARSED
    # PDDA contract: the LLM layer is advisory and never blocks (warn-max). A non-deterministic oracle
    # must not gain blocking power — the same doc could pass at 2pm and fail at 3pm. Clamp any "error".
    [ "$sev" = "error" ] && sev="warn"
    pdda_record_finding "$sev" "$CHECK_NAME" "$file" "${ln:-0}" "$msg" "llm-readiness"
  done <<RESPONSE
$response
RESPONSE
}

# 1) active working docs — generic readiness rubric.
while IFS= read -r file; do
  review_one "$file" "$RUBRIC"
done < <(pdda_list_working_docs)

# 2) ROADMAP.md — pointer-only contract (separate rubric; skipped if absent).
PDDA_ROADMAP="${PDDA_ROADMAP:-$PDDA_REPO_ROOT/ROADMAP.md}"
[ -f "$PDDA_ROADMAP" ] && review_one "$PDDA_ROADMAP" "$ROADMAP_RUBRIC"

pdda_emit_summary "$CHECK_NAME" "$EXIT_CODE"
exit "$(pdda_gated_exit "$EXIT_CODE")"
