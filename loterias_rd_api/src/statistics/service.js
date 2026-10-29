import { SANTO_DOMINGO_TIMEZONE } from '../history/constants.js';
import { currentDateInZone } from '../history/validation.js';
import { buildStatistics } from './engine.js';

const cachedSnapshots = new Map();

async function historyFingerprint(db, series, asOfDate) {
  const [results, coverage, revisions] = await db.batch([
    db.prepare(`
      SELECT COUNT(*) AS count, MIN(draw_date) AS first_date,
             MAX(draw_date) AS last_date, MAX(updated_at) AS latest_update
      FROM first_prize_results WHERE operator_id = ? AND draw_id = ?
    `).bind(series.operatorId, series.drawId),
    db.prepare(`
      SELECT COUNT(*) AS count, MAX(checked_at) AS latest_check,
             SUM(CASE WHEN status = 'UNVERIFIED' THEN 1 ELSE 0 END) AS unverified_count,
             SUM(CASE WHEN status = 'FETCH_FAILED' THEN 1 ELSE 0 END) AS failed_count,
             SUM(CASE WHEN status = 'PENDING' THEN 1 ELSE 0 END) AS pending_count
      FROM coverage WHERE operator_id = ? AND draw_id = ?
    `).bind(series.operatorId, series.drawId),
    db.prepare(`
      SELECT COUNT(*) AS count, MAX(rr.detected_at) AS latest_revision
      FROM result_revisions rr
      JOIN first_prize_results r ON r.id = rr.result_id
      WHERE r.operator_id = ? AND r.draw_id = ?
    `).bind(series.operatorId, series.drawId),
  ]);
  return JSON.stringify({
    asOfDate,
    results: results.results?.[0] || null,
    coverage: coverage.results?.[0] || null,
    revisions: revisions.results?.[0] || null,
  });
}

export async function loadStatisticsSnapshot(db, series, { now = new Date(), from = null, to = null } = {}) {
  if (!db) throw new Error('HISTORY_DB binding is required.');
  if (!series) throw new Error('An authorized series is required.');
  const asOfDate = currentDateInZone(SANTO_DOMINGO_TIMEZONE, now);
  const key = `${series.operatorId}:${series.drawId}:${from || '*'}:${to || '*'}`;
  const fingerprint = await historyFingerprint(db, series, asOfDate);
  const cached = cachedSnapshots.get(key);
  if (cached?.fingerprint === fingerprint) return cached.statistics;

  const resultSql = `
      SELECT provider_result_id, operator_id, draw_id, draw_date, first_number
      FROM first_prize_results
      WHERE operator_id = ? AND draw_id = ?
      ${from ? 'AND draw_date >= ? AND draw_date <= ?' : ''}
      ORDER BY draw_date ASC, id ASC
    `;
  const coverageSql = `
      SELECT coverage_date, status FROM coverage
      WHERE operator_id = ? AND draw_id = ?
      ${from ? 'AND coverage_date >= ? AND coverage_date <= ?' : ''}
      ORDER BY coverage_date ASC
    `;
  const bindings = from
    ? [series.operatorId, series.drawId, from, to]
    : [series.operatorId, series.drawId];
  const [resultQuery, coverageQuery] = await db.batch([
    db.prepare(`
      ${resultSql}
    `).bind(...bindings),
    db.prepare(`${coverageSql}`).bind(...bindings),
  ]);
  const statistics = buildStatistics(
    resultQuery.results || [], coverageQuery.results || [], to || asOfDate, series,
  );
  statistics.range = { from, to, custom: Boolean(from) };
  cachedSnapshots.set(key, { fingerprint, statistics });
  return statistics;
}

export function clearStatisticsCache(series = null) {
  if (!series) cachedSnapshots.clear();
  else {
    const prefix = `${series.operatorId}:${series.drawId}:`;
    for (const key of cachedSnapshots.keys()) {
      if (key.startsWith(prefix)) cachedSnapshots.delete(key);
    }
  }
}
