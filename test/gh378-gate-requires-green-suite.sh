#!/usr/bin/env bash
# PLACEHOLDER for GH-378 — this file exists so the swarm-preflight contract can name it as an
# artifact (preflight requires every artifacts[] path to exist at target.ref) and so a builder
# lane can edit it inside its ALLOW_PATHS without tripping containment as an off-lane create.
#
# It is deliberately NOT registered in validate.sh's TESTS. An unregistered gate is invisible —
# that is #461's defect — so registration is part of the lane's work, not part of this stub.
set -uo pipefail
echo "GH-378: placeholder — not implemented. See PROJECT/2-WORKING/ for the capture doc."
exit 0
