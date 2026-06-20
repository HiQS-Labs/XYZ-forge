#!/usr/bin/env bash
# Regenerate skills/relay-automation/relay-pkg.tar.gz from the live relay-automation
# sources. Run after changing any packaged script. (Phase 5 packaging.)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."   # repo root
tar czf skills/relay-automation/relay-pkg.tar.gz \
  relay-automation/poll.sh \
  relay-automation/runner.sh \
  relay-automation/watchdog.sh \
  relay-automation/relay-drive.sh \
  relay-automation/relay-turn-lib.sh \
  relay-automation/codex-turn.sh \
  relay-automation/agy-turn.sh \
  relay-automation/README.md \
  test/poll-driver.sh \
  test/poll-relay.sh \
  test/watchdog-relay.sh \
  test/codex-turn.sh \
  test/agy-turn.sh
echo "wrote skills/relay-automation/relay-pkg.tar.gz ($(wc -c < skills/relay-automation/relay-pkg.tar.gz) bytes)"
