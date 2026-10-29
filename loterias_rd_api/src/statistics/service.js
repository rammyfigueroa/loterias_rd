import { DRAW_ID, OPERATOR_ID, SANTO_DOMINGO_TIMEZONE } from '../history/constants.js';
import { currentDateInZone } from '../history/validation.js';
import { buildStatistics } from './engine.js';

let cachedSnapshot = null;

async function historyFingerprint(db, asOfDate) {
  const [results, coverage, revisions] = await db.batch([
    db.prepare(`
      SELECT COUNT(*) AS count, MIN(draw_date) AS first_date,
             MAX(draw_date) AS last_date, MAX(updated_at) AS latest_update
      FROM first_prize_results
      WHERE operator_id = ? AND draw_id = ?
    `).bind(OPERATOR_ID, DRAW_ID),
    db.prepare(`
      SELECT COUNT(*) AS count, MAX(checked_at) AS latest_check,
             SUM(CASE WHEN status = 'UNVERIFIED' THEN 1 ELSE 0 END) AS unverified_count,
             SUM(CASE WHEN status = 'FETCH_FAILED' THEN 1 ELSE 0 END) AS failed_count,
             SUM(CASE WHEN status = 'PENDING' THEN 1 ELSE 0 END) AS pending_count
      FROM coverage
      WHERE operator_id = ? AND draw_id = ?
    `).bind(OPERATOR_ID, DRAW_ID),
    db.prepare(`
      SELECT COUNT(*) AS count, MAX(detected_at) AS latest_revision
      FROM result_revisions
    `),
  ]);
  return JSON.stringify({
    asOfDate,
    results: results.results?.[0] || null,
    coverage: coverage.results?.[0] || null,
    revisions: revisions.results?.[0] || null,
  });
}

export async function loadStatisticsSnapshot(db, { now = new Date() } = {}) {
  if (!db) throw new Error('HISTORY_DB binding is required.');
  const asOfDate = currentDateInZone(SANTO_DOMINGO_TIMEZONE, now);
  const fingerprint = await historyFingerprint(db, asOfDate);
  if (cachedSnapshot?.fingerprint === fingerprint) return cachedSnapshot.statistics;

  const [resultQuery, coverageQuery] = await db.batch([
    db.prepare(`
      SELECT provider_result_id, operator_id, draw_id, draw_date, first_number
      FROM first_prize_results
      WHERE operator_id = ? AND draw_id = ?
      ORDER BY draw_date ASC, id ASC
    `).bind(OPERATOR_ID, DRAW_ID),
    db.prepare(`
      SELECT coverage_date, status
      FROM coverage
      WHERE operator_id = ? AND draw_id = ?
      ORDER BY coverage_date ASC
    `).bind(OPERATOR_ID, DRAW_ID),
  ]);

  const statistics = buildStatistics(
    resultQuery.results || [],
    coverageQuery.results || [],
    asOfDate,
  );
  cachedSnapshot = { fingerprint, statistics };
  return statistics;
}

export function clearStatisticsCache() {
  cachedSnapshot = null;
}
