// Read-side display expiry; producer completeness is never inferred from a GET.
export function snapshotFresh(snapshot, now = Date.now()) {
  const age = now - Date.parse(snapshot?.generated_at);
  return Number.isFinite(age) && age >= 0 && age <= 300000;
}
export function progressTone(repo, snapshot, failed = false, now = Date.now()) {
  if (failed || !snapshotFresh(snapshot, now)) return 'unknown';
  const progress = Date.parse(repo.last_progress_at);
  const age = now - progress;
  const source = (snapshot.sources || []).find(s =>
    (repo.events || []).some(e => e.source_ref === s.id && e.occurred_at === repo.last_progress_at));
  const watermark = Date.parse(source?.observed_through);
  if (!source || source.availability !== 'ok' || !Number.isFinite(watermark) || watermark > now || now - watermark > 300000) return 'unknown';
  if (age >= 0 && age < 3600000 && watermark >= progress) return 'green';
  // Absence requires an explicitly covered interval, not a heartbeat or old event.
  const start = Date.parse(source.coverage_start);
  if (source.coverage !== 'complete' || !Number.isFinite(start) || start > now - 7200000) return 'unknown';
  if (age >= 7200000) return 'red';
  if (age >= 3600000) return 'amber';
  return 'unknown';
}
