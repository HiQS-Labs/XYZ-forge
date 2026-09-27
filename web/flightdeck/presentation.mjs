// Read-side display expiry; producer completeness is never inferred from a GET.
export function snapshotFresh(snapshot, now = Date.now()) {
  const age = now - Date.parse(snapshot?.generated_at);
  return Number.isFinite(age) && age >= 0 && age <= 300000;
}
export function progressTone() {
  // Current producers supply observations, not a complete repo-scoped progress
  // window with owner-backed expiry. Preserve facts without inventing health.
  return 'unknown';
}
export const PROGRESS_HELP = 'Not an error. Flightdeck shows the activity its sources report, but no source measures progress for a lane yet, so it cannot say whether work is on track.';

// Where each connector is configured (see src/flightdeck/contract.py).
const SOURCE_SETUP = {
  xyz_work: 'set FLIGHTDECK_XYZ_ROOTS=/path/to/repo[:/other/repo] (or xyz_roots in FLIGHTDECK_CONFIG); if FLIGHTDECK_CONNECTORS or the connectors list in FLIGHTDECK_CONFIG is set, also add xyz_work to it; then restart',
  rebalance: 'check FLIGHTDECK_REBALANCE_DB points at the Rebalance database',
  clio: 'check FLIGHTDECK_CLIO_JSONL points at the prompt log',
  git_pulse: 'check FLIGHTDECK_GIT_PULSE_DIR points at the Git Pulse sync folder',
  topology: 'no producer writes this feed yet; once one does, set FLIGHTDECK_TOPOLOGY_JSON',
  continuity: 'no producer writes this feed yet; once one does, set FLIGHTDECK_CONTINUITY_JSON'
};
// Row/root caps the connectors report in their error fields (src/flightdeck/connectors.py).
const CAP_CODES = new Set(['issue-cap', 'root-cap']);
// Unknown or unconfigured is "off" (grey); any read failure, including one xyz_work root, is
// "failed" (red); a cap warning on an otherwise good read is "partial" (amber).
export function sourceStatus(source, fresh = true) {
  const setup = SOURCE_SETUP[source.id] || 'check the Flightdeck configuration';
  const roots = source.roots || [];
  const rootError = roots.map(root => root.error).find(error => error && !CAP_CODES.has(error));
  const cap = [source.error, ...roots.map(root => root.error)].find(error => CAP_CODES.has(error));
  const capOnly = cap && !rootError && roots.every(root => root.supported !== false);
  const failure = rootError || (source.availability !== 'ok' && !capOnly && source.error);
  if (!fresh) return {tone: 'stale', label: 'stale', help: 'Snapshot is older than 5 minutes; waiting for a fresh read.'};
  if (failure) return {tone: 'failed', label: 'read failed', help: `Read failed (${failure}): ${setup}.`};
  if (cap || (source.availability === 'ok' && source.error)) return {tone: 'partial', label: 'partial', help: `Partly shown (${cap || source.error}); the rest was read normally.`};
  if (source.availability === 'ok') return {tone: 'ok', label: 'ok', help: `Coverage: ${source.coverage}; observed ${source.observed_through || 'unknown'}`};
  if (source.availability === 'disabled') {
    return {tone: 'off', label: 'off', help: `Turned off. To enable: ${source.id === 'xyz_work' ? setup : `add ${source.id} to FLIGHTDECK_CONNECTORS`}.`};
  }
  return {tone: 'off', label: 'not set up', help: `Not configured: ${setup}.`};
}
