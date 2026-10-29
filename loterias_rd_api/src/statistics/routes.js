import { parseLimit, requireAuthorizedSeries, ValidationError } from '../history/validation.js';
import { aggregateIntervals } from './engine.js';
import { loadStatisticsSnapshot } from './service.js';

const BASE_PATH = '/statistics/first-prize';
const DISCLAIMER = 'This analysis describes observed historical coincidences and does not predict future results.';

function encodeOffset(offset) {
  return btoa(String(offset)).replaceAll('+', '-').replaceAll('/', '_').replace(/=+$/, '');
}

function decodeOffset(value) {
  if (!value) return 0;
  try {
    const normalized = value.replaceAll('-', '+').replaceAll('_', '/');
    const decoded = atob(normalized.padEnd(Math.ceil(normalized.length / 4) * 4, '='));
    if (!/^\d+$/.test(decoded)) throw new Error('invalid offset');
    return Number(decoded);
  } catch {
    throw new ValidationError('cursor is invalid.');
  }
}

export function paginate(items, searchParams, maximum = 100) {
  const limit = parseLimit(searchParams.get('limit'), 25, maximum);
  const offset = decodeOffset(searchParams.get('cursor'));
  const results = items.slice(offset, offset + limit);
  const nextOffset = offset + results.length;
  const hasMore = nextOffset < items.length;
  return {
    count: results.length,
    total: items.length,
    hasMore,
    nextCursor: hasMore ? encodeOffset(nextOffset) : null,
    results,
  };
}

function coverageFilter(searchParams) {
  const value = (searchParams.get('coverage') || 'verified').toLowerCase();
  if (!['verified', 'incomplete', 'all'].includes(value)) {
    throw new ValidationError('coverage must be verified, incomplete or all.');
  }
  return value;
}

function intervalDaysFromPath(pathname) {
  const match = pathname.match(/^\/statistics\/first-prize\/intervals\/(\d+)$/);
  if (!match) return null;
  const days = Number(match[1]);
  if (!Number.isSafeInteger(days) || days < 0 || days > 10000) {
    throw new ValidationError('Interval days are outside the supported range.');
  }
  return days;
}

async function intervalRanking(request, env) {
  const url = new URL(request.url);
  const series = requireAuthorizedSeries(url.searchParams);
  const coverage = coverageFilter(url.searchParams);
  const snapshot = await loadStatisticsSnapshot(env.HISTORY_DB, series);
  const ranking = coverage === 'verified'
    ? snapshot.verifiedRanking
    : coverage === 'incomplete'
      ? snapshot.incompleteCoverageRanking
      : aggregateIntervals(snapshot.intervals);
  return {
    operatorId: snapshot.operatorId,
    drawId: snapshot.drawId,
    coverage,
    quality: snapshot.quality,
    disclaimer: DISCLAIMER,
    ...paginate(ranking, url.searchParams),
  };
}

async function intervalDetail(request, env, days) {
  const url = new URL(request.url);
  const series = requireAuthorizedSeries(url.searchParams);
  const coverage = coverageFilter(url.searchParams);
  const snapshot = await loadStatisticsSnapshot(env.HISTORY_DB, series);
  const matching = snapshot.intervals
    .filter((interval) => interval.days === days)
    .filter((interval) =>
      coverage === 'all' ||
      (coverage === 'verified' && interval.coverageStatus === 'VERIFIED') ||
      (coverage === 'incomplete' && interval.coverageStatus === 'INCOMPLETE_COVERAGE'),
    )
    .sort((left, right) => left.number.localeCompare(right.number) || left.startDate.localeCompare(right.startDate));
  const numbers = [...new Set(matching.map((item) => item.number))].sort();
  return {
    operatorId: snapshot.operatorId,
    drawId: snapshot.drawId,
    days,
    coverage,
    distinctNumbers: numbers.length,
    totalRepetitions: matching.length,
    numbers,
    quality: snapshot.quality,
    disclaimer: DISCLAIMER,
    occurrences: paginate(matching, url.searchParams),
  };
}

async function numberStatistics(request, env) {
  const url = new URL(request.url);
  const series = requireAuthorizedSeries(url.searchParams);
  const snapshot = await loadStatisticsSnapshot(env.HISTORY_DB, series);
  return {
    operatorId: snapshot.operatorId,
    drawId: snapshot.drawId,
    asOfDate: snapshot.asOfDate,
    quality: snapshot.quality,
    disclaimer: DISCLAIMER,
    ...paginate(snapshot.numbers, url.searchParams),
  };
}

export async function handleStatisticsRequest(request, env) {
  if (!env.HISTORY_DB) return statisticsJson({ error: 'Historical database is not configured.' }, 503);
  const url = new URL(request.url);
  if (request.method !== 'GET') return statisticsJson({ error: 'Method not allowed.' }, 405);

  try {
    if (url.pathname === `${BASE_PATH}/intervals`) {
      return statisticsJson(await intervalRanking(request, env));
    }
    const days = intervalDaysFromPath(url.pathname);
    if (days != null) return statisticsJson(await intervalDetail(request, env, days));
    if (url.pathname === `${BASE_PATH}/numbers`) {
      return statisticsJson(await numberStatistics(request, env));
    }
    return statisticsJson({ error: 'Statistics route not found.' }, 404);
  } catch (error) {
    if (error instanceof ValidationError) return statisticsJson({ error: error.message }, 400);
    console.error('Statistics request failed', {
      path: url.pathname,
      error: error instanceof Error ? error.message : String(error),
    });
    return statisticsJson({ error: 'Statistics request failed.' }, 500);
  }
}

function statisticsJson(payload, status = 200) {
  return new Response(JSON.stringify(payload, null, 2), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Access-Control-Allow-Origin': '*',
    },
  });
}

export function isStatisticsPath(pathname) {
  return pathname === `${BASE_PATH}/intervals` ||
    pathname === `${BASE_PATH}/numbers` ||
    /^\/statistics\/first-prize\/intervals\/\d+$/.test(pathname);
}

export const __test = { decodeOffset, encodeOffset, intervalDaysFromPath };
