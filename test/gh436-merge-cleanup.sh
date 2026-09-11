#!/usr/bin/env bash
# gh436-merge-cleanup.sh — gate entry for the /merge-cleanup unit suite (GH-436, GH-534 A.6).
#
# WHY: test/gh436-merge-cleanup.py existed for four days without being in validate.sh TESTS, so
# every guarantee it pinned was unproven at push time. This wrapper is the registered entry; the
# Python file (and the GH-534 Phase A module it collects) is the suite.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/gh436-merge-cleanup.py"
