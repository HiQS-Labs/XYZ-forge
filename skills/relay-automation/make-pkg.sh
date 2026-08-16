#!/usr/bin/env bash
# Regenerate skills/relay-automation/relay-pkg.tar.gz from the live relay-automation
# sources. Run after changing any packaged script. (Phase 5 packaging.)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."   # repo root
# GH-261: on macOS, bsdtar silently packs AppleDouble ._* sidecar entries for any source file
# carrying an xattr (e.g. com.apple.provenance) — no corresponding "live source" file exists for
# those, so relay-pkg-freshness.sh correctly flags them as stale junk when regenerated on Linux CI
# (or extracted there). COPYFILE_DISABLE=1 is the standard opt-out; harmless on Linux (unused there).
export COPYFILE_DISABLE=1
tar czf skills/relay-automation/relay-pkg.tar.gz \
  relay-automation/poll.sh \
  relay-automation/relay-loop.sh \
  relay-automation/runner.sh \
  relay-automation/watchdog.sh \
  relay-automation/relay-drive.sh \
  relay-automation/relay-turn-lib.sh \
  relay-automation/durable-log-lib.sh \
  relay-automation/non-durable-log-roots.conf \
  relay-automation/new-relay.sh \
  relay-automation/codex-turn.sh \
  relay-automation/agy-turn.sh \
  relay-automation/README.md \
  test/poll-driver.sh \
  test/relay-loop.sh \
  test/poll-relay.sh \
  test/watchdog-relay.sh \
  test/codex-turn.sh \
  test/agy-turn.sh
echo "wrote skills/relay-automation/relay-pkg.tar.gz ($(wc -c < skills/relay-automation/relay-pkg.tar.gz) bytes)"
