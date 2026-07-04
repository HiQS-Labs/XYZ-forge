#!/usr/bin/env bash
# GH-120: OpenRouter model-alias fuzzy lookup — placeholder until the lane lands.
# TODO(GH-120): assert the seeded aliases (glm-5.2, "nemotron ultra 3", "nemotron ultra 3 free")
# resolve to their canonical slugs via the lookup helper, including at least one fuzzy-variant
# case (e.g. "Nemotron 3 Ultra" or "nemotron-ultra3"). Wire into validate.sh once real.
set -euo pipefail
echo "test/model-alias.sh: GH-120 not yet implemented (placeholder — always passes)"
exit 0
