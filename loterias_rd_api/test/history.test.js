import assert from 'node:assert/strict';
import test from 'node:test';

import { coverageForMissingDate, runBackfillBatch } from '../src/history/backfill.js';
import {
  DRAW_ID,
  NATIONAL_DRAW_ID,
  OPERATOR_ID,
  SERIES,
} from '../src/history/constants.js';
import {
  checksumForResult,
  extractGanaMasSession,
  extractSeriesSession,
  fetchJsonWithRetry,
  identifyGanaMas,
  identifyNational,
  ProviderError,
} from '../src/history/provider.js';
import { classifyResultChange } from '../src/history/repository.js';
import {
  buildHistorySql,
  decodeCursor,
  encodeCursor,
  parseHistoryQuery,
} from '../src/history/routes.js';
import {
  parseIsoDate,
  previousIsoDate,
  requireAuthorizedSeries,
  validateFirstNumber,
  ValidationError,
} from '../src/history/validation.js';

function siteFixture() {
  return {
    _id: '6966a6d1ea7015c3b8a3d446',
    siteCompanies: [{
      title: 'Nacional',
      company_id: OPERATOR_ID,
      company: { _id: OPERATOR_ID },
      siteGames: [{
        title: 'Lotería Nacional',
        game_id: NATIONAL_DRAW_ID,
        game: {
          _id: NATIONAL_DRAW_ID,
          createdAt: '2026-01-13T20:10:57.975Z',
          is_quiniela: true,
          statistics: { positions: 3 },
          score_layout: [[{ label: 'Bola 1' }, { label: 'Bola 2' }, { label: 'Bola 3' }]],
        },
      }, {
        title: 'Gana Más',
        game_id: DRAW_ID,
        game: {
          _id: DRAW_ID,
          createdAt: '2026-01-13T20:10:57.992Z',
          is_quiniela: true,
          statistics: { positions: 3 },
          score_layout: [[{ label: 'Bola 1' }, { label: 'Bola 2' }, { label: 'Bola 3' }]],
        },
      }],
    }],
  };
}

test('identifies Lotería Nacional only through its independent structured ID', () => {
  const identified = identifyNational(siteFixture());
  assert.equal(identified.drawId, NATIONAL_DRAW_ID);
  assert.equal(identified.drawName, 'Lotería Nacional');
  assert.equal(identified.lowerBoundDate, '2026-01-13');
});

test('extracts National first prize without reading Gana Más sessions', () => {
  const groups = [
    ...sessionGroups('2026-10-28', '05'),
    {
      game_id: NATIONAL_DRAW_ID,
      sessions: [{
        _id: 'national-2026-10-28',
        game_id: NATIONAL_DRAW_ID,
        date: '2026-10-28T04:00:00.000Z',
        score: [['87', '22', '10']],
      }],
    },
  ];
  const result = extractSeriesSession(groups, '2026-10-28', SERIES.national);
  assert.equal(result.firstNumber, '87');
  assert.equal(result.drawId, NATIONAL_DRAW_ID);
});

function sessionGroups(date = '2026-10-28', first = '05') {
  return [{
    game_id: DRAW_ID,
    sessions: [{
      _id: `result-${date}`,
      game_id: DRAW_ID,
      date: `${date}T04:00:00.000Z`,
      score: [[first, '18', '54']],
      createdAt: `${date}T18:00:00.000Z`,
      updatedAt: `${date}T18:01:00.000Z`,
    }],
  }];
}

test('identifies Gana Más only through approved structured IDs', () => {
  const identified = identifyGanaMas(siteFixture());
  assert.equal(identified.operatorId, OPERATOR_ID);
  assert.equal(identified.drawId, DRAW_ID);
  assert.equal(identified.drawName, 'Gana Más');
  assert.equal(identified.lowerBoundDate, '2026-01-13');
});

test('rejects ambiguous or text-only Gana Más metadata', () => {
  const payload = siteFixture();
  payload.siteCompanies[0].company_id = 'wrong-id';
  payload.siteCompanies[0].company._id = 'wrong-id';
  assert.throws(() => identifyGanaMas(payload), ProviderError);
});

test('extracts first position and preserves a leading zero', () => {
  const result = extractGanaMasSession(sessionGroups(), '2026-10-28');
  assert.equal(result.firstNumber, '05');
  assert.equal(result.providerResultId, 'result-2026-10-28');
});

test('returns null when the provider has no exact session for the requested date', () => {
  assert.equal(extractGanaMasSession(sessionGroups('2026-10-27'), '2026-10-28'), null);
});

test('rejects invalid first-position values', () => {
  assert.throws(() => validateFirstNumber('100'), ValidationError);
  assert.throws(() => validateFirstNumber('A5'), ValidationError);
  assert.equal(validateFirstNumber('5'), '05');
});

test('rejects invalid calendar dates', () => {
  assert.throws(() => parseIsoDate('2026-02-30', 'date'), ValidationError);
  assert.throws(() => parseIsoDate('30/02/2026', 'date'), ValidationError);
});

test('classifies inserts, duplicates and corrections', () => {
  const incoming = { checksum: 'new' };
  assert.equal(classifyResultChange(null, null, incoming).kind, 'INSERT');
  assert.equal(classifyResultChange({ checksum: 'new' }, null, incoming).kind, 'UNCHANGED');
  assert.equal(classifyResultChange({ checksum: 'old' }, null, incoming).kind, 'REVISION');
  assert.equal(classifyResultChange(null, { checksum: 'old' }, incoming).kind, 'REVISION');
});

test('checksum ignores provider timestamps but detects score corrections', async () => {
  const base = extractGanaMasSession(sessionGroups(), '2026-10-28');
  const timestampOnly = {
    ...base,
    rawPayload: { ...base.rawPayload, updatedAt: '2026-10-29T00:00:00.000Z' },
  };
  assert.equal(await checksumForResult(base), await checksumForResult(timestampOnly));

  const corrected = {
    ...base,
    firstNumber: '06',
    rawPayload: { ...base.rawPayload, score: [['06', '18', '54']] },
  };
  assert.notEqual(await checksumForResult(base), await checksumForResult(corrected));
});

test('keeps reported holidays unverified without official evidence', () => {
  assert.equal(coverageForMissingDate('2026-08-16').status, 'UNVERIFIED');
  assert.equal(coverageForMissingDate('2026-09-24').status, 'UNVERIFIED');
  assert.equal(coverageForMissingDate('2026-08-18').status, 'NO_RESULTS_RETURNED');
});

test('requires exact operator and draw filters', () => {
  assert.throws(() => requireAuthorizedSeries(new URLSearchParams()), ValidationError);
  assert.throws(() => requireAuthorizedSeries(new URLSearchParams({ operatorId: OPERATOR_ID, drawId: 'other' })), ValidationError);
  assert.equal(
    requireAuthorizedSeries(new URLSearchParams({ operatorId: OPERATOR_ID, drawId: DRAW_ID })).drawId,
    DRAW_ID,
  );
  assert.equal(
    requireAuthorizedSeries(new URLSearchParams({ operatorId: OPERATOR_ID, drawId: NATIONAL_DRAW_ID })).drawId,
    NATIONAL_DRAW_ID,
  );
});

test('builds bounded, parameterized chronological history queries', () => {
  const query = parseHistoryQuery(new URLSearchParams({
    operatorId: OPERATOR_ID,
    drawId: DRAW_ID,
    startDate: '2026-05-01',
    endDate: '2026-05-31',
    limit: '25',
    order: 'desc',
  }));
  const statement = buildHistorySql(query);
  assert.match(statement.sql, /ORDER BY draw_date DESC/);
  assert.match(statement.sql, /LIMIT \?/);
  assert.deepEqual(statement.bindings.slice(0, 4), [OPERATOR_ID, DRAW_ID, '2026-05-01', '2026-05-31']);
  assert.equal(statement.bindings.at(-1), 26);
});

test('round-trips opaque pagination cursors', () => {
  const cursor = encodeCursor('2026-10-28', 181);
  assert.deepEqual(decodeCursor(cursor), { date: '2026-10-28', id: 181 });
  assert.throws(() => decodeCursor('bad'), ValidationError);
});

test('retries transient provider failures', async () => {
  let calls = 0;
  const fetchImpl = async () => {
    calls += 1;
    if (calls < 3) throw new Error('temporary');
    return new Response(JSON.stringify({ ok: true }), { status: 200 });
  };
  const response = await fetchJsonWithRetry('https://example.test', {
    fetchImpl,
    retries: 2,
    retryDelayMs: 0,
  });
  assert.equal(calls, 3);
  assert.equal(response.attempts, 3);
});

test('reports provider failure after bounded retries', async () => {
  const fetchImpl = async () => new Response('failed', { status: 503 });
  await assert.rejects(
    fetchJsonWithRetry('https://example.test', { fetchImpl, retries: 1, retryDelayMs: 0 }),
    ProviderError,
  );
});

test('moves back one calendar day without local-time drift', () => {
  assert.equal(previousIsoDate('2026-03-01'), '2026-02-28');
});

test('backfill persists its next date so another batch can resume', async () => {
  const coverage = [];
  let state = null;
  const repository = {
    async ensureMetadata() {},
    async getBackfillState() { return state; },
    async initializeBackfill({ nextDate, lowerBoundDate }) {
      state = { next_date: nextDate, lower_bound_date: lowerBoundDate, status: 'READY' };
      return state;
    },
    async recordCoverage(item) { coverage.push(item); },
    async saveResult() { return { kind: 'INSERT' }; },
    async updateBackfillState({ nextDate, status }) {
      state = { ...state, next_date: nextDate, status };
    },
  };
  const fetchImpl = async (url) => {
    if (String(url).includes('/sites/env')) {
      return new Response(JSON.stringify(siteFixture()), { status: 200 });
    }
    return new Response(JSON.stringify(sessionGroups('2026-10-28')), { status: 200 });
  };

  const summary = await runBackfillBatch(
    { HISTORY_DB: {} },
    {
      maxRequests: 1,
      now: new Date('2026-10-28T20:00:00Z'),
      repository,
      fetchOptions: { fetchImpl, retries: 0 },
    },
  );
  assert.equal(summary.inserted, 1);
  assert.equal(summary.state.next_date, '2026-10-27');
  assert.equal(summary.hasMore, true);
  assert.ok(coverage.some((item) => item.status === 'RESULT_FOUND'));
});
