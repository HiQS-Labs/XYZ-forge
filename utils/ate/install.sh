#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="ate"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SRC_DIR}/../.." && pwd)"
SKILL_SOURCE="${REPO_ROOT}/skills/${SKILL_NAME}/SKILL.md"
DEST_DIR="${HOME}/.claude/skills/${SKILL_NAME}"

mkdir -p "${HOME}/.claude/skills"

if [ "${SRC_DIR}" = "${DEST_DIR}" ]; then
  echo "Already running from ${DEST_DIR}, nothing to copy."
else
  echo "Installing ${SKILL_NAME} -> ${DEST_DIR}"
  rm -rf "${DEST_DIR}"
  cp -R "${SRC_DIR}" "${DEST_DIR}"
  cp "${SKILL_SOURCE}" "${DEST_DIR}/SKILL.md"
fi
chmod +x "${DEST_DIR}"/scripts/*.py

echo
echo "Checking dependencies..."
missing=0
for pkg in requests yaml; do
  if ! python3 -c "import ${pkg}" 2>/dev/null; then
    echo "  missing: python module '${pkg}'"
    missing=1
  fi
done
if [ "${missing}" -eq 1 ]; then
  echo "  -> pip3 install requests pyyaml"
fi

if ! command -v aider >/dev/null 2>&1; then
  echo "  missing: 'aider' CLI not found on PATH"
fi
if ! command -v gh >/dev/null 2>&1; then
  echo "  missing: 'gh' CLI not found on PATH (needed for compile_issue.py)"
else
  if ! gh auth status >/dev/null 2>&1; then
    echo "  note: 'gh' is installed but not authenticated (run: gh auth login)"
  fi
fi

echo
echo "Installed. Next steps:"
echo "  1. In LM Studio: load a Gemma 4 model, start the Local Server (Developer tab)."
echo "  2. export OPENROUTER_API_KEY=..."
echo "  3. Copy variations.example.yaml, edit the grid for what you're testing."
echo "  4. Read ${DEST_DIR}/SKILL.md for the full run/check-in/rollup workflow."
