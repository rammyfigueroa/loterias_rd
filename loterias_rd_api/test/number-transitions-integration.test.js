import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

import wrangler from 'wrangler';

import { GANA_MAS_DRAW_ID, NATIONAL_DRAW_ID, OPERATOR_ID } from '../src/history/constants.js';
import { clearNumberTransitionsCache } from '../src/statistics/number-transitions-service.js';
import { handleStatisticsRequest, isStatisticsPath, __test as routeTest } from '../src/statistics/routes.js';

const { getPlatformProxy } = wrangler;

let platform;
let db;

function endpoint(params = {}) {
  const query = new URLSearchParams({
    operatorId: OPERATOR_ID,
    drawId: GANA_MAS_DRAW_ID,
    position: 'first',
    number: '10',
    ...params,
  });
  return new Request(`https://local.test/statistics/number-transitions?${query}`);
}

async function response(params = {}, options = {}) {
  const result = await handleStatisticsRequest(endpoint(params), { HISTORY_DB: db }, {
    now: new Date('2026-05-05T23:00:00.000Z'),
    ...options,
  });
  return { status: result.status, body: await result.json() };
}

async function executeMigration(name) {
  const sql = await readFile(new URL(`../migrations/${name}`, import.meta.url), 'utf8');
  await executeSql(sql);
}

async function executeSql(sql) {
  const statements = sql.split(/;\s*(?:\n|$)/).map((statement) => statement.trim()).filter(Boolean);
  await db.batch(statements.map((statement) => db.prepare(statement)));
}

test.before(async () => {
  platform = await getPlatformProxy({
    configPath: new URL('../wrangler.toml', import.meta.url).pathname,
    persist: false,
    remoteBindings: false,
  });
  db = platform.env.HISTORY_DB;
  await executeMigration('0001_gana_mas_history.sql');
  await executeMigration('0002_national_history.sql');
  await executeSql(`
    INSERT INTO first_prize_results (
      provider_result_id, operator_id, draw_id, draw_date, first_number,
      source, checksum, raw_payload, collected_at, updated_at
    ) VALUES
      ('gm-1', '${OPERATOR_ID}', '${GANA_MAS_DRAW_ID}', '2026-05-01', '10', 'fixture', 'a', '{}', '2026-05-01T20:00:00Z', '2026-05-01T20:00:00Z'),
      ('gm-2', '${OPERATOR_ID}', '${GANA_MAS_DRAW_ID}', '2026-05-03', '20', 'fixture', 'b', '{}', '2026-05-03T20:00:00Z', '2026-05-03T20:00:00Z'),
      ('gm-3', '${OPERATOR_ID}', '${GANA_MAS_DRAW_ID}', '2026-05-04', '10', 'fixture', 'c', '{}', '2026-05-04T20:00:00Z', '2026-05-04T20:00:00Z'),
      ('gm-4', '${OPERATOR_ID}', '${GANA_MAS_DRAW_ID}', '2026-05-05', '30', 'fixture', 'd', '{}', '2026-05-05T20:00:00Z', '2026-05-05T20:00:00Z'),
      ('nat-1', '${OPERATOR_ID}', '${NATIONAL_DRAW_ID}', '2026-05-01', '10', 'fixture', 'n1', '{}', '2026-05-01T21:00:00Z', '2026-05-01T21:00:00Z'),
      ('nat-2', '${OPERATOR_ID}', '${NATIONAL_DRAW_ID}', '2026-05-02', '99', 'fixture', 'n2', '{}', '2026-05-02T21:00:00Z', '2026-05-02T21:00:00Z');

    INSERT INTO coverage (
      operator_id, draw_id, coverage_date, status, source, verification_source, checked_at
    ) VALUES
      ('${OPERATOR_ID}', '${GANA_MAS_DRAW_ID}', '2026-05-01', 'RESULT_FOUND', 'fixture', NULL, '2026-05-01T21:00:00Z'),
      ('${OPERATOR_ID}', '${GANA_MAS_DRAW_ID}', '2026-05-02', 'NO_DRAW_SCHEDULED', 'fixture', 'official-calendar-fixture', '2026-05-02T21:00:00Z'),
      ('${OPERATOR_ID}', '${GANA_MAS_DRAW_ID}', '2026-05-03', 'RESULT_FOUND', 'fixture', NULL, '2026-05-03T21:00:00Z'),
      ('${OPERATOR_ID}', '${GANA_MAS_DRAW_ID}', '2026-05-04', 'RESULT_FOUND', 'fixture', NULL, '2026-05-04T21:00:00Z'),
      ('${OPERATOR_ID}', '${GANA_MAS_DRAW_ID}', '2026-05-05', 'RESULT_FOUND', 'fixture', NULL, '2026-05-05T21:00:00Z'),
      ('${OPERATOR_ID}', '${NATIONAL_DRAW_ID}', '2026-05-01', 'RESULT_FOUND', 'fixture', NULL, '2026-05-01T22:00:00Z'),
      ('${OPERATOR_ID}', '${NATIONAL_DRAW_ID}', '2026-05-02', 'RESULT_FOUND', 'fixture', NULL, '2026-05-02T22:00:00Z');
  `);
});

test.after(async () => {
  await platform?.dispose();
});

test.beforeEach(() => clearNumberTransitionsCache());

test('registers the number-transitions route', () => {
  assert.equal(isStatisticsPath('/statistics/number-transitions'), true);
});

test('returns 503 when the historical binding is absent', async () => {
  const result = await handleStatisticsRequest(endpoint(), {});
  assert.equal(result.status, 503);
});

test('requires exact operator and draw identifiers', async () => {
  const result = await handleStatisticsRequest(new Request(
    'https://local.test/statistics/number-transitions?position=first&number=10',
  ), { HISTORY_DB: db });
  assert.equal(result.status, 400);
  assert.match((await result.json()).error, /operatorId and drawId/);
});

test('rejects an unauthorized series before querying data', async () => {
  const result = await response({ drawId: 'unknown' });
  assert.equal(result.status, 400);
  assert.match(result.body.error, /not enabled/);
});

test('requires the first position explicitly', async () => {
  assert.equal((await response({ position: '' })).status, 400);
  assert.equal((await response({ position: 'second' })).status, 400);
});

test('requires a canonical two-digit origin number', async () => {
  assert.equal((await response({ number: '0' })).status, 400);
  assert.equal((await response({ number: '100' })).status, 400);
  assert.equal((await response({ number: '-1' })).status, 400);
});

test('rejects incomplete, inverted and invalid calendar ranges', async () => {
  assert.equal((await response({ from: '2026-05-01' })).status, 400);
  assert.equal((await response({ from: '2026-05-05', to: '2026-05-01' })).status, 400);
  assert.equal((await response({ from: '2026-02-30', to: '2026-05-01' })).status, 400);
});

test('rejects future dates using the Dominican date', async () => {
  const result = await handleStatisticsRequest(
    endpoint({ from: '2026-05-01', to: '2026-05-02' }),
    { HISTORY_DB: db },
    { now: new Date('2026-05-02T02:30:00.000Z') },
  );
  assert.equal(result.status, 400);
  assert.match((await result.json()).error, /future/);
});

test('rejects a range outside available coverage', async () => {
  const result = await response({ from: '2026-04-30', to: '2026-05-05' });
  assert.equal(result.status, 400);
  assert.match(result.body.error, /outside the available coverage/);
});

test('returns a deterministic response from local D1', async () => {
  const first = await response();
  clearNumberTransitionsCache();
  const second = await response();
  assert.equal(first.status, 200);
  assert.deepEqual(first.body.results, second.body.results);
  assert.equal(first.body.totalTransitions, 2);
  assert.deepEqual(first.body.results.map((item) => item.nextNumber), ['20', '30']);
});

test('preserves a verified NO_DRAW_SCHEDULED gap', async () => {
  const result = await response({ from: '2026-05-01', to: '2026-05-03' });
  assert.equal(result.status, 200);
  assert.equal(result.body.totalTransitions, 1);
  assert.equal(result.body.results[0].nextNumber, '20');
  assert.equal(result.body.quality.verifiedTransitions, 1);
});

test('returns an empty valid sample for an absent origin number', async () => {
  const result = await response({ number: '88' });
  assert.equal(result.status, 200);
  assert.equal(result.body.totalTransitions, 0);
  assert.deepEqual(result.body.results, []);
});

test('keeps National and Gana Más isolated', async () => {
  const result = await response({ drawId: NATIONAL_DRAW_ID });
  assert.equal(result.status, 200);
  assert.equal(result.body.totalTransitions, 1);
  assert.deepEqual(result.body.results.map((item) => item.nextNumber), ['99']);
});

test('reports requested, effective and available coverage ranges', async () => {
  const result = await response({ from: '2026-05-01', to: '2026-05-04' });
  assert.deepEqual(result.body.requestedRange, {
    from: '2026-05-01', to: '2026-05-04', custom: true, boundsInclusive: true,
  });
  assert.equal(result.body.effectiveRange.to, '2026-05-04');
  assert.equal(result.body.availableCoverage.noDrawScheduled, 1);
});

test('supports incomplete coverage without relabeling it verified', async () => {
  await db.prepare(`
    UPDATE coverage SET status = 'NO_RESULTS_RETURNED', checked_at = ?
    WHERE draw_id = ? AND coverage_date = '2026-05-02'
  `).bind('2026-05-06T00:00:00Z', GANA_MAS_DRAW_ID).run();
  const result = await response({ coverage: 'incomplete', from: '2026-05-01', to: '2026-05-03' });
  assert.equal(result.status, 200);
  assert.equal(result.body.totalTransitions, 1);
  assert.equal(result.body.coverageStatus, 'INCOMPLETE_COVERAGE');
  await db.prepare(`
    UPDATE coverage SET status = 'NO_DRAW_SCHEDULED', verification_source = 'official-calendar-fixture', checked_at = ?
    WHERE draw_id = ? AND coverage_date = '2026-05-02'
  `).bind('2026-05-06T00:01:00Z', GANA_MAS_DRAW_ID).run();
});

test('does not trust NO_DRAW_SCHEDULED without a verification source', async () => {
  await db.prepare(`
    UPDATE coverage SET verification_source = NULL, checked_at = ?
    WHERE draw_id = ? AND coverage_date = '2026-05-02'
  `).bind('2026-05-06T00:02:00Z', GANA_MAS_DRAW_ID).run();
  const result = await response({ coverage: 'verified', from: '2026-05-01', to: '2026-05-03' });
  assert.equal(result.status, 200);
  assert.equal(result.body.totalTransitions, 0);
  assert.equal(result.body.availableCoverage.noDrawScheduled, 0);
  assert.equal(result.body.availableCoverage.unknown, 1);
  await db.prepare(`
    UPDATE coverage SET verification_source = 'official-calendar-fixture', checked_at = ?
    WHERE draw_id = ? AND coverage_date = '2026-05-02'
  `).bind('2026-05-06T00:03:00Z', GANA_MAS_DRAW_ID).run();
});

test('uses the cache only for the same data fingerprint', async () => {
  const first = await response();
  const second = await response();
  assert.equal(first.body.cacheStatus, 'MISS');
  assert.equal(second.body.cacheStatus, 'HIT');
  assert.equal(first.body.dataRevision.fingerprint, second.body.dataRevision.fingerprint);
});

test('invalidates cache after a canonical correction and revision', async () => {
  const before = await response();
  const stored = await db.prepare(
    'SELECT id, provider_result_id, first_number, checksum, raw_payload FROM first_prize_results WHERE provider_result_id = ?',
  ).bind('gm-2').first();
  await db.batch([
    db.prepare(`
      INSERT INTO result_revisions (
        result_id, provider_result_id, old_first_number, new_first_number,
        old_checksum, new_checksum, old_raw_payload, new_raw_payload, detected_at
      ) VALUES (?, ?, ?, '40', ?, 'corrected', ?, '{}', ?)
    `).bind(stored.id, stored.provider_result_id, stored.first_number, stored.checksum,
      stored.raw_payload, '2026-05-06T01:00:00Z'),
    db.prepare(`
      UPDATE first_prize_results
      SET first_number = '40', checksum = 'corrected', updated_at = ?
      WHERE id = ?
    `).bind('2026-05-06T01:00:00Z', stored.id),
  ]);
  const after = await response();
  assert.equal(after.body.cacheStatus, 'MISS');
  assert.notEqual(after.body.dataRevision.fingerprint, before.body.dataRevision.fingerprint);
  assert.equal(after.body.results[0].nextNumber, '30');
  assert.equal(after.body.results[1].nextNumber, '40');
});

test('paginates with a cursor bound to the data revision', async () => {
  const first = await response({ limit: '1' });
  assert.equal(first.body.count, 1);
  assert.equal(first.body.hasMore, true);
  const second = await response({ limit: '1', cursor: first.body.nextCursor });
  assert.equal(second.status, 200);
  assert.equal(second.body.count, 1);
  assert.notEqual(second.body.results[0].nextNumber, first.body.results[0].nextNumber);
  assert.throws(
    () => routeTest.decodeTransitionCursor(first.body.nextCursor, 'different-revision'),
    /another data revision/,
  );
});

test('rejects unsupported coverage and invalid cursors', async () => {
  assert.equal((await response({ coverage: 'maybe' })).status, 400);
  assert.equal((await response({ cursor: 'bad' })).status, 400);
});

test('does not use predictive or guaranteed language', async () => {
  const result = await response();
  const serialized = JSON.stringify(result.body).toLowerCase();
  for (const phrase of ['número ganador', 'número seguro', 'próximo número garantizado']) {
    assert.equal(serialized.includes(phrase), false);
  }
  assert.match(result.body.disclaimer, /does not predict future results/);
});
