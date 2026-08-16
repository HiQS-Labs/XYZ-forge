#!/usr/bin/env bash
# GH-311: run the deterministic PDDA contract against this repository's real docs.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

# pdda.sh normally appends runtime telemetry under PROJECT/. The validation must inspect the
# repository's actual docs without mutating them, while allowing a caller to capture telemetry.
export PDDA_ACTIVITY_LOG="${PDDA_ACTIVITY_LOG:-/dev/null}"

exec "$HERE/../utils/pdda/pdda.sh" run
