'use strict';

const { execFileSync } = require('child_process');

// Run 2: the git transport (fetch/rebase/commit/push) was removed — `tick` is
// now a pure local event log over a shared .tick/ directory. The only
// remaining git touch-point is reading the clone's configured identity, used
// to cross-check the --agent flag.
/**
 * Reads the clone's configured `git config user.name`, used to cross-check the
 * `--agent` flag. Never throws — returns `null` on any git/config failure.
 * @param {string} repoRoot - absolute path to the repo root
 * @returns {string|null}
 */
function gitUserName(repoRoot) {
  try {
    const out = execFileSync('git', ['config', 'user.name'], {
      cwd: repoRoot,
      encoding: 'utf8',
    }).trim();
    return out || null;
  } catch {
    return null;
  }
}

module.exports = { gitUserName };
