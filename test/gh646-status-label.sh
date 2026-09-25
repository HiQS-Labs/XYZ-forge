#!/usr/bin/env bash
# Registered wrapper only; the stdlib suite owns bounded isolated TemporaryDirectory fixtures.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/gh646_status_label.py" "$@"
