import { ValidationError } from '../history/validation.js';
import { calculateNumberTransitions } from './number-transitions.js';

const MAX_CACHE_ENTRIES = 100;
const cachedTransitions = new Map();

function row(result) {
  return result?.results?.[0] || null;
}

function count(value) {
  return Number(value || 0);
}

async function sha256(value) {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(value));
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

async function loadRevision(db, series, asOfDate) {
  const [drawQuery, resultsQuery, coverageQuery, revisionsQuery] = await db.batch([
    db.prepare(`
      SELECT id, operator_id, name, enabled, first_position_path
      FROM draws
      WHERE id = ? AND operator_id = ?
      LIMIT 1
    `).bind(series.drawId, series.operatorId),
    db.prepare(`
      SELECT COUNT(*) AS count, MIN(draw_date) AS first_date,
             MAX(draw_date) AS last_date, MAX(updated_at) AS latest_update
      FROM first_prize_results
      WHERE operator_id = ? AND draw_id = ?
    `).bind(series.operatorId, series.drawId),
    db.prepare(`
      SELECT COUNT(*) AS count, MIN(coverage_date) AS first_date,
             MAX(coverage_date) AS last_date, MAX(checked_at) AS latest_check,
             SUM(CASE WHEN status = 'RESULT_FOUND' THEN 1 ELSE 0 END) AS result_found_count,
             SUM(CASE WHEN status = 'NO_DRAW_SCHEDULED' AND verification_source IS NOT NULL THEN 1 ELSE 0 END) AS no_draw_count,
             SUM(CASE WHEN status IN ('NO_RESULTS_RETURNED', 'FETCH_FAILED') THEN 1 ELSE 0 END) AS incomplete_count,
             SUM(CASE WHEN status IN ('UNVERIFIED', 'PENDING') OR
               (status = 'NO_DRAW_SCHEDULED' AND verification_source IS NULL)
               THEN 1 ELSE 0 END) AS unknown_count
      FROM coverage
      WHERE operator_id = ? AND draw_id = ?
    `).bind(series.operatorId, series.drawId),
    db.prepare(`
      SELECT COUNT(*) AS count, MAX(rr.detected_at) AS latest_revision
      FROM result_revisions rr
      JOIN first_prize_results r ON r.id = rr.result_id
      WHERE r.operator_id = ? AND r.draw_id = ?
    `).bind(series.operatorId, series.drawId),
  ]);

  const draw = row(drawQuery);
  if (!draw || count(draw.enabled) !== 1 || draw.first_position_path !== 'score[0][0]') {
    throw new ValidationError('The requested series is not available in the historical database.');
  }

  const results = row(resultsQuery) || {};
  const coverage = row(coverageQuery) || {};
  const revisions = row(revisionsQuery) || {};
  const revisionData = {
    asOfDate,
    resultCount: count(results.count),
    firstResultDate: results.first_date || null,
    lastResultDate: results.last_date || null,
    latestResultUpdate: results.latest_update || null,
    coverageCount: count(coverage.count),
    firstCoverageDate: coverage.first_date || null,
    lastCoverageDate: coverage.last_date || null,
    latestCoverageCheck: coverage.latest_check || null,
    coverageResultFoundCount: count(coverage.result_found_count),
    coverageNoDrawCount: count(coverage.no_draw_count),
    coverageIncompleteCount: count(coverage.incomplete_count),
    coverageUnknownCount: count(coverage.unknown_count),
    revisionCount: count(revisions.count),
    latestRevision: revisions.latest_revision || null,
  };
  return {
    draw,
    results,
    coverage,
    revision: {
      ...revisionData,
      fingerprint: await sha256(JSON.stringify(revisionData)),
    },
  };
}

function resolveRange(from, to, revision) {
  const availableFrom = revision.firstCoverageDate;
  const availableTo = revision.lastCoverageDate;
  const requestedRange = {
    from,
    to,
    custom: Boolean(from),
    boundsInclusive: true,
  };

  if (from && (!availableFrom || !availableTo || from < availableFrom || to > availableTo)) {
    throw new ValidationError('The requested range is outside the available coverage.');
  }

  return {
    requestedRange,
    effectiveRange: {
      from: from || availableFrom || revision.firstResultDate,
      to: to || availableTo || revision.lastResultDate,
      custom: Boolean(from),
      boundsInclusive: true,
    },
  };
}

function cacheGet(key) {
  const value = cachedTransitions.get(key);
  if (!value) return null;
  cachedTransitions.delete(key);
  cachedTransitions.set(key, value);
  return structuredClone(value);
}

function cacheSet(key, value) {
  cachedTransitions.set(key, structuredClone(value));
  while (cachedTransitions.size > MAX_CACHE_ENTRIES) {
    cachedTransitions.delete(cachedTransitions.keys().next().value);
  }
}

export async function loadNumberTransitions(db, series, {
  originNumber,
  position = 'first',
  from = null,
  to = null,
  coverageMode = 'verified',
  asOfDate,
} = {}) {
  if (!db) throw new Error('HISTORY_DB binding is required.');
  if (!series) throw new Error('An authorized series is required.');
  const metadata = await loadRevision(db, series, asOfDate);
  const ranges = resolveRange(from, to, metadata.revision);
  const cacheKey = [
    series.operatorId,
    series.drawId,
    position,
    originNumber,
    ranges.effectiveRange.from || '*',
    ranges.effectiveRange.to || '*',
    coverageMode,
    metadata.revision.fingerprint,
  ].join(':');
  const cached = cacheGet(cacheKey);
  if (cached) return { ...cached, cacheStatus: 'HIT' };

  const hasRange = Boolean(ranges.effectiveRange.from && ranges.effectiveRange.to);
  const bindings = hasRange
    ? [series.operatorId, series.drawId, ranges.effectiveRange.from, ranges.effectiveRange.to]
    : [series.operatorId, series.drawId];
  const rangeSql = hasRange ? 'AND draw_date >= ? AND draw_date <= ?' : '';
  const coverageRangeSql = hasRange ? 'AND coverage_date >= ? AND coverage_date <= ?' : '';
  const [resultsQuery, coverageQuery] = await db.batch([
    db.prepare(`
      SELECT id, provider_result_id, operator_id, draw_id, draw_date,
             first_number, checksum, updated_at
      FROM first_prize_results
      WHERE operator_id = ? AND draw_id = ? ${rangeSql}
      ORDER BY draw_date ASC, id ASC
    `).bind(...bindings),
    db.prepare(`
      SELECT operator_id, draw_id, coverage_date, status, checked_at,
             verification_source
      FROM coverage
      WHERE operator_id = ? AND draw_id = ? ${coverageRangeSql}
      ORDER BY coverage_date ASC, id ASC
    `).bind(...bindings),
  ]);

  const calculated = calculateNumberTransitions({
    events: (resultsQuery.results || []).map((item) => ({
      eventId: String(item.id),
      providerResultId: item.provider_result_id,
      operatorId: item.operator_id,
      drawId: item.draw_id,
      position: 'first',
      drawDate: item.draw_date,
      number: item.first_number,
      status: 'RESULT_FOUND',
      checksum: item.checksum,
      updatedAt: item.updated_at,
    })),
    coverageRows: (coverageQuery.results || []).map((item) => ({
      operatorId: item.operator_id,
      drawId: item.draw_id,
      date: item.coverage_date,
      status: item.status === 'NO_DRAW_SCHEDULED' && !item.verification_source
        ? 'UNVERIFIED'
        : item.status,
    })),
    series,
    position,
    originNumber,
    from: ranges.effectiveRange.from,
    to: ranges.effectiveRange.to,
    coverageMode,
  });

  const response = {
    series: {
      operatorId: series.operatorId,
      operatorName: series.operatorName,
      drawId: series.drawId,
      drawName: metadata.draw.name,
      position,
    },
    originNumber,
    requestedRange: ranges.requestedRange,
    effectiveRange: ranges.effectiveRange,
    availableCoverage: {
      from: metadata.revision.firstCoverageDate,
      to: metadata.revision.lastCoverageDate,
      totalDates: count(metadata.coverage.count),
      resultFound: count(metadata.coverage.result_found_count),
      noDrawScheduled: count(metadata.coverage.no_draw_count),
      incomplete: count(metadata.coverage.incomplete_count),
      unknown: count(metadata.coverage.unknown_count),
    },
    coverageMode,
    coverageStatus: calculated.coverageStatus,
    sampleStatus: calculated.sampleStatus,
    originAppearances: calculated.originAppearances,
    originEventsWithoutSuccessor: calculated.originEventsWithoutSuccessor,
    totalTransitions: calculated.totalTransitions,
    quality: calculated.quality,
    results: calculated.results,
    warnings: calculated.warnings,
    dataRevision: metadata.revision,
    disclaimer: calculated.disclaimer,
    cacheStatus: 'MISS',
  };
  cacheSet(cacheKey, response);
  return response;
}

export function clearNumberTransitionsCache() {
  cachedTransitions.clear();
}

export const __test = { loadRevision, resolveRange };
