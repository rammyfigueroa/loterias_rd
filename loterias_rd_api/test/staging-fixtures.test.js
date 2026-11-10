import assert from 'node:assert/strict';
import test from 'node:test';

import wrangler from 'wrangler';

import { GANA_MAS_DRAW_ID, NATIONAL_DRAW_ID, OPERATOR_ID, SERIES } from '../src/history/constants.js';
import { loadNumberTransitions, clearNumberTransitionsCache } from '../src/statistics/number-transitions-service.js';
import {
  createBaseFixture,
  createPerformanceFixture,
  ensureLocalSchema,
  FIXTURE_PREFIX,
  loadFixture,
  PERFORMANCE_EVENT_COUNT,
} from '../scripts/staging-fixtures.js';
import { parseArguments, validateStagingConfig } from '../scripts/load-staging-fixtures-local.js';

const { getPlatformProxy } = wrangler;

async function localDatabase() {
  const platform = await getPlatformProxy({
    configPath: new URL('../wrangler.staging.toml', import.meta.url).pathname,
    persist: false,
    remoteBindings: false,
    envFiles: [],
  });
  await ensureLocalSchema(platform.env.HISTORY_DB);
  return { platform, db: platform.env.HISTORY_DB };
}

async function count(db, table) {
  const row = await db.prepare(`SELECT COUNT(*) AS count FROM ${table}`).first();
  return Number(row.count);
}

test('fixture base is deterministic, synthetic and has manually verified totals', () => {
  const first = createBaseFixture();
  const second = createBaseFixture();
  assert.deepEqual(first, second);
  assert.equal(first.results.length, 16);
  assert.equal(first.coverage.length, 19);
  assert.equal(first.revisions.length, 1);
  assert.equal(first.results.every((item) => item.providerResultId.startsWith(FIXTURE_PREFIX)), true);
  assert.equal(JSON.stringify(first).includes('api.loteriasdominicanas.com'), false);
});

test('loader requires explicit local mode and has no remote execution route', () => {
  assert.throws(() => parseArguments(['--remote', '--persist-to', '/tmp/test']), /not implemented or authorized/);
  assert.throws(() => parseArguments(['--persist-to', '/tmp/test']), /--local/);
  assert.throws(() => parseArguments(['--local']), /--persist-to/);
  assert.deepEqual(parseArguments(['--local', '--persist-to', '/tmp/fixture-test']), {
    persistTo: '/tmp/fixture-test',
    includePerformance: false,
  });
});

test('staging config validation rejects another database or exposed endpoint', () => {
  const valid = {
    name: 'sorteosdominicanos-api-staging',
    account_id: 'f171b568e3a3a203a09ef2fd6e337a2c',
    workers_dev: false,
    preview_urls: false,
    vars: { ENVIRONMENT: 'staging' },
    d1_databases: [{
      binding: 'HISTORY_DB',
      database_name: 'sorteosdominicanos-db-staging',
      database_id: 'f31aac48-f437-4fd7-9691-a7e976010dc6',
    }],
  };
  assert.doesNotThrow(() => validateStagingConfig(valid));
  assert.throws(() => validateStagingConfig({ ...valid, workers_dev: true }), /does not match/);
  assert.throws(() => validateStagingConfig({
    ...valid,
    d1_databases: [{ ...valid.d1_databases[0], database_name: 'production' }],
  }), /does not match/);
});

test('schema preparation rejects an unrelated local database', async (t) => {
  const platform = await getPlatformProxy({
    configPath: new URL('../wrangler.staging.toml', import.meta.url).pathname,
    persist: false,
    remoteBindings: false,
    envFiles: [],
  });
  t.after(() => platform.dispose());
  await platform.env.HISTORY_DB.prepare('CREATE TABLE foreign_data (id INTEGER PRIMARY KEY)').run();
  await assert.rejects(() => ensureLocalSchema(platform.env.HISTORY_DB), /unexpected tables: foreign_data/);
});

test('base fixture loads twice without duplicates and preserves foreign keys', async (t) => {
  const { platform, db } = await localDatabase();
  t.after(() => platform.dispose());
  const fixture = createBaseFixture();
  const first = await loadFixture(db, fixture);
  const second = await loadFixture(db, fixture);
  assert.deepEqual(first.inserted, { results: 16, coverage: 19, revisions: 1 });
  assert.deepEqual(second.inserted, { results: 0, coverage: 0, revisions: 0 });
  assert.equal(await count(db, 'first_prize_results'), 16);
  assert.equal(await count(db, 'coverage'), 19);
  assert.equal(await count(db, 'result_revisions'), 1);
  assert.deepEqual((await db.prepare('PRAGMA foreign_key_check').all()).results, []);
});

test('loader stops on a foreign result collision without overwriting it', async (t) => {
  const { platform, db } = await localDatabase();
  t.after(() => platform.dispose());
  const fixture = createBaseFixture();
  const expected = fixture.results[0];
  await db.prepare(`
    INSERT INTO first_prize_results (
      provider_result_id, operator_id, draw_id, draw_date, first_number,
      source, checksum, raw_payload, collected_at, updated_at
    ) VALUES (?, ?, ?, ?, '99', 'foreign', 'foreign', '{}', ?, ?)
  `).bind(
    expected.providerResultId, OPERATOR_ID, GANA_MAS_DRAW_ID, expected.drawDate,
    expected.collectedAt, expected.updatedAt,
  ).run();
  await assert.rejects(() => loadFixture(db, fixture), /Fixture collision/);
  const stored = await db.prepare(
    'SELECT first_number, source FROM first_prize_results WHERE provider_result_id = ?',
  ).bind(expected.providerResultId).first();
  assert.deepEqual(stored, { first_number: '99', source: 'foreign' });
  assert.equal(await count(db, 'coverage'), 0);
});

test('base fixture produces known transitions, ties, no-draw handling and cache data', async (t) => {
  const { platform, db } = await localDatabase();
  t.after(() => platform.dispose());
  const fixture = createBaseFixture();
  await loadFixture(db, fixture);
  clearNumberTransitionsCache();
  const options = {
    originNumber: '24',
    asOfDate: '2026-11-09',
    from: '2026-04-01',
    to: '2026-04-11',
  };
  const first = await loadNumberTransitions(db, SERIES.ganaMas, options);
  const second = await loadNumberTransitions(db, SERIES.ganaMas, options);
  assert.equal(first.cacheStatus, 'MISS');
  assert.equal(second.cacheStatus, 'HIT');
  assert.equal(first.totalTransitions, fixture.expected.ganaMasOrigin24.totalTransitions);
  assert.equal(first.originAppearances, fixture.expected.ganaMasOrigin24.originAppearances);
  assert.equal(first.originEventsWithoutSuccessor, 1);
  assert.deepEqual(first.results.map(({ nextNumber, transitionCount, relativeFrequency }) => ({
    nextNumber, transitionCount, relativeFrequency,
  })), fixture.expected.ganaMasOrigin24.destinations);
  assert.equal(first.availableCoverage.noDrawScheduled, 1);
  assert.equal(first.quality.verifiedTransitions, 9);
});

test('correction is canonical and its synthetic revision remains traceable', async (t) => {
  const { platform, db } = await localDatabase();
  t.after(() => platform.dispose());
  await loadFixture(db, createBaseFixture());
  const row = await db.prepare(`
    SELECT r.first_number, rr.old_first_number, rr.new_first_number
    FROM first_prize_results r
    JOIN result_revisions rr ON rr.result_id = r.id
    WHERE r.draw_id = ? AND r.draw_date = '2026-04-04'
  `).bind(GANA_MAS_DRAW_ID).first();
  assert.deepEqual(row, { first_number: '32', old_first_number: '31', new_first_number: '32' });
});

test('separate series retains incomplete and unknown coverage without mixing results', async (t) => {
  const { platform, db } = await localDatabase();
  t.after(() => platform.dispose());
  await loadFixture(db, createBaseFixture());
  clearNumberTransitionsCache();
  const verified = await loadNumberTransitions(db, SERIES.national, {
    originNumber: '10',
    asOfDate: '2026-11-09',
    from: '2026-05-01',
    to: '2026-05-08',
    coverageMode: 'verified',
  });
  assert.equal(verified.totalTransitions, 3);
  assert.deepEqual(verified.results.map((item) => item.nextNumber), ['20', '30']);
  assert.equal(verified.availableCoverage.incomplete, 1);
  assert.equal(verified.availableCoverage.unknown, 1);
  assert.equal(verified.series.drawId, NATIONAL_DRAW_ID);
  assert.equal(verified.results.some((item) => item.nextNumber === '67'), false);

  const incomplete = await loadNumberTransitions(db, SERIES.national, {
    originNumber: '20',
    asOfDate: '2026-11-09',
    from: '2026-05-01',
    to: '2026-05-08',
    coverageMode: 'incomplete',
  });
  assert.equal(incomplete.totalTransitions, 1);
  assert.equal(incomplete.coverageStatus, 'INCOMPLETE_COVERAGE');
});

test('inclusive short range excludes outside events and absent origin has no transitions', async (t) => {
  const { platform, db } = await localDatabase();
  t.after(() => platform.dispose());
  await loadFixture(db, createBaseFixture());
  clearNumberTransitionsCache();
  const short = await loadNumberTransitions(db, SERIES.ganaMas, {
    originNumber: '24',
    asOfDate: '2026-11-09',
    from: '2026-04-03',
    to: '2026-04-04',
  });
  assert.equal(short.totalTransitions, 1);
  assert.equal(short.results[0].nextNumber, '32');
  const absent = await loadNumberTransitions(db, SERIES.ganaMas, {
    originNumber: '99',
    asOfDate: '2026-11-09',
    from: '2026-04-01',
    to: '2026-04-11',
  });
  assert.equal(absent.totalTransitions, 0);
});

test('performance generator creates 5,000 deterministic events and loads idempotently', async (t) => {
  const fixture = createPerformanceFixture();
  assert.equal(fixture.results.length, PERFORMANCE_EVENT_COUNT);
  assert.equal(fixture.coverage.length, PERFORMANCE_EVENT_COUNT);
  assert.deepEqual(fixture, createPerformanceFixture());

  const { platform, db } = await localDatabase();
  t.after(() => platform.dispose());
  const started = performance.now();
  const first = await loadFixture(db, fixture);
  const elapsedMs = performance.now() - started;
  const second = await loadFixture(db, fixture);
  assert.deepEqual(first.inserted, { results: 5_000, coverage: 5_000, revisions: 0 });
  assert.deepEqual(second.inserted, { results: 0, coverage: 0, revisions: 0 });
  assert.equal(await count(db, 'first_prize_results'), 5_000);
  assert.equal(await count(db, 'coverage'), 5_000);
  assert.ok(elapsedMs < 30_000, `fixture load took ${elapsedMs.toFixed(0)}ms`);

  clearNumberTransitionsCache();
  const analysis = await loadNumberTransitions(db, SERIES.ganaMas, {
    originNumber: '11',
    asOfDate: '2026-11-09',
    from: fixture.expected.firstDate,
    to: fixture.expected.lastDate,
  });
  assert.equal(analysis.totalTransitions, 50);
  assert.deepEqual(analysis.results.map(({ nextNumber, transitionCount, relativeFrequency }) => ({
    nextNumber, transitionCount, relativeFrequency,
  })), [{ nextNumber: '48', transitionCount: 50, relativeFrequency: 1 }]);
});
