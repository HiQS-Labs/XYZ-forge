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
