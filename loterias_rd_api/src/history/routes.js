import { runBackfillBatch } from './backfill.js';
import { DRAW_ID } from './constants.js';
import {
  parseIsoDate,
  parseLimit,
  parseOrder,
  requireAuthorizedSeries,
  ValidationError,
} from './validation.js';

export function encodeCursor(date, id) {
  return btoa(`${date}:${id}`).replaceAll('+', '-').replaceAll('/', '_').replace(/=+$/, '');
}

export function decodeCursor(value) {
  if (!value) return null;
  try {
    const normalized = value.replaceAll('-', '+').replaceAll('_', '/');
    const decoded = atob(normalized.padEnd(Math.ceil(normalized.length / 4) * 4, '='));
    const match = decoded.match(/^(\d{4}-\d{2}-\d{2}):(\d+)$/);
    if (!match) throw new Error('invalid cursor');
    return { date: parseIsoDate(match[1], 'cursor date'), id: Number(match[2]) };
  } catch {
    throw new ValidationError('cursor is invalid.');
  }
}

export function parseHistoryQuery(searchParams) {
  const series = requireAuthorizedSeries(searchParams);
  const startDate = parseIsoDate(searchParams.get('startDate'), 'startDate');
  const endDate = parseIsoDate(searchParams.get('endDate'), 'endDate');
  if (startDate && endDate && startDate > endDate) {
    throw new ValidationError('startDate must not be after endDate.');
  }
  return {
    ...series,
    startDate,
    endDate,
    limit: parseLimit(searchParams.get('limit')),
    order: parseOrder(searchParams.get('order')),
    cursor: decodeCursor(searchParams.get('cursor')),
  };
}

export function buildHistorySql(query) {
  const clauses = ['operator_id = ?', 'draw_id = ?'];
  const bindings = [query.operatorId, query.drawId];
  if (query.startDate) {
    clauses.push('draw_date >= ?');
    bindings.push(query.startDate);
  }
  if (query.endDate) {
    clauses.push('draw_date <= ?');
    bindings.push(query.endDate);
  }
  if (query.cursor) {
    const operator = query.order === 'asc' ? '>' : '<';
    clauses.push(`(draw_date ${operator} ? OR (draw_date = ? AND id ${operator} ?))`);
    bindings.push(query.cursor.date, query.cursor.date, query.cursor.id);
  }
  const direction = query.order.toUpperCase();
  bindings.push(query.limit + 1);
  return {
    sql: `
      SELECT id, provider_result_id, operator_id, draw_id, draw_date,
             first_number, source, checksum, provider_created_at,
             provider_updated_at, collected_at, updated_at
      FROM first_prize_results
      WHERE ${clauses.join(' AND ')}
      ORDER BY draw_date ${direction}, id ${direction}
      LIMIT ?
    `,
    bindings,
  };
}

async function listHistory(request, env) {
  const query = parseHistoryQuery(new URL(request.url).searchParams);
  const statement = buildHistorySql(query);
  const response = await env.HISTORY_DB.prepare(statement.sql).bind(...statement.bindings).all();
  const rows = response.results || [];
  const hasMore = rows.length > query.limit;
  const results = rows.slice(0, query.limit);
  const last = results.at(-1);
  return {
    operatorId: query.operatorId,
    drawId: query.drawId,
    order: query.order,
    count: results.length,
    hasMore,
    nextCursor: hasMore && last ? encodeCursor(last.draw_date, last.id) : null,
    results,
  };
}

async function listCoverage(request, env) {
  const query = parseHistoryQuery(new URL(request.url).searchParams);
  const clauses = ['operator_id = ?', 'draw_id = ?'];
  const bindings = [query.operatorId, query.drawId];
  if (query.startDate) { clauses.push('coverage_date >= ?'); bindings.push(query.startDate); }
  if (query.endDate) { clauses.push('coverage_date <= ?'); bindings.push(query.endDate); }
  if (query.cursor) {
    const operator = query.order === 'asc' ? '>' : '<';
    clauses.push(`(coverage_date ${operator} ? OR (coverage_date = ? AND id ${operator} ?))`);
    bindings.push(query.cursor.date, query.cursor.date, query.cursor.id);
  }
  const direction = query.order.toUpperCase();
  bindings.push(query.limit + 1);
  const response = await env.HISTORY_DB.prepare(`
    SELECT id, coverage_date, status, source, verification_source, detail,
           attempt_count, last_error, checked_at
    FROM coverage
    WHERE ${clauses.join(' AND ')}
    ORDER BY coverage_date ${direction}, id ${direction}
    LIMIT ?
  `).bind(...bindings).all();
  const rows = response.results || [];
  const hasMore = rows.length > query.limit;
  const results = rows.slice(0, query.limit);
  const last = results.at(-1);
  return {
    operatorId: query.operatorId,
    drawId: query.drawId,
    count: results.length,
    hasMore,
    nextCursor: hasMore && last ? encodeCursor(last.coverage_date, last.id) : null,
    results,
  };
}

function authorizeBackfill(request, env) {
  const expected = env.HISTORY_BACKFILL_TOKEN;
  const actual = request.headers.get('X-Backfill-Token');
  return Boolean(expected && actual && expected === actual);
}

export async function handleHistoryRequest(request, env) {
  if (!env.HISTORY_DB) return historyJson({ error: 'Historical database is not configured.' }, 503);
  const url = new URL(request.url);

  try {
    if (url.pathname === '/history' && request.method === 'GET') {
      return historyJson(await listHistory(request, env));
    }
    if (url.pathname === '/history/coverage' && request.method === 'GET') {
      return historyJson(await listCoverage(request, env));
    }
    if (url.pathname === '/internal/history/backfill' && request.method === 'POST') {
      if (!authorizeBackfill(request, env)) return historyJson({ error: 'Unauthorized.' }, 401);
      const maxRequests = parseLimit(url.searchParams.get('maxRequests'), 20, 50);
      return historyJson(await runBackfillBatch(env, { maxRequests }));
    }
    return historyJson({ error: 'Historical route not found.' }, 404);
  } catch (error) {
    if (error instanceof ValidationError) return historyJson({ error: error.message }, 400);
    console.error('Historical request failed', { path: url.pathname, error: error instanceof Error ? error.message : String(error) });
    return historyJson({ error: 'Historical request failed.' }, 500);
  }
}

function historyJson(payload, status = 200) {
  return new Response(JSON.stringify(payload, null, 2), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Access-Control-Allow-Origin': '*',
    },
  });
}

export function isHistoryPath(pathname) {
  return pathname === '/history' || pathname === '/history/coverage' || pathname === '/internal/history/backfill';
}

export const __test = { listHistory, listCoverage, DRAW_ID };
