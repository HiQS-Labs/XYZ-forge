#!/usr/bin/env bash
# test/gh124-closeout.sh — GH-124: Closeout automation, gate receipts, workspace GC & drift alert.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec bash "$HERE/test/synthetic/gh124-closeout-suite.sh"
