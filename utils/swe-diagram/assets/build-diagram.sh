#!/usr/bin/env bash
# build-diagram.sh <diagram.json> [output.html]
# Inlines renderer.js + the diagram JSON into template.html to produce a
# single self-contained HTML file. No dependencies beyond python3.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JSON="${1:?usage: build-diagram.sh <diagram.json> [output.html]}"
OUT="${2:-${JSON%.json}.html}"

python3 - "$SCRIPT_DIR/template.html" "$SCRIPT_DIR/renderer.js" "$JSON" "$OUT" <<'PY'
import json, sys, html as H
template, renderer, spec_path, out = sys.argv[1:5]
spec = json.load(open(spec_path))  # validates JSON before embedding
doc = open(template).read()
doc = doc.replace("__TITLE__", H.escape(spec.get("title", "System Diagram")))
doc = doc.replace("__RENDERER_JS__", open(renderer).read())
# ensure_ascii escapes non-ASCII; also escape "<" so a "</script>" inside any
# string can't close the embedding <script> tag early (parses back to "<").
diagram_json = json.dumps(spec, indent=2).replace("<", "\\u003c")
doc = doc.replace("__DIAGRAM_JSON__", diagram_json)
open(out, "w").write(doc)
print(f"wrote {out} ({len(spec.get('nodes', []))} nodes, {len(spec.get('edges', []))} edges)")
PY
