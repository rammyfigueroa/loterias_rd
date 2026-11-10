import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

import wrangler from 'wrangler';

import { SERIES } from '../src/history/constants.js';
import { clearNumberTransitionsCache, loadNumberTransitions } from '../src/statistics/number-transitions-service.js';
import { renderBaseFixtureSql } from '../scripts/generate-staging-fixture-sql.js';
import { ensureLocalSchema } from '../scripts/staging-fixtures.js';

const { getPlatformProxy } = wrangler;

async function executeSql(db, sql) {
  const statements = sql
    .split(/;\s*(?:\n|$)/)
    .map((statement) => statement.trim())
    .filter(Boolean);
  for (let index = 0; index < statements.length; index += 100) {
    await db.batch(statements.slice(index, index + 100).map((statement) => db.prepare(statement)));
  }
}

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

async function counts(db) {
  const [results, coverage, revisions] = await db.batch([
    db.prepare('SELECT COUNT(*) AS count FROM first_prize_results'),
    db.prepare('SELECT COUNT(*) AS count FROM coverage'),
    db.prepare('SELECT COUNT(*) AS count FROM result_revisions'),
  ]);
  return [results, coverage, revisions].map((item) => Number(item.results[0].count));
}

test('committed SQL artifact is deterministic and contains no destructive operations', async () => {
  const artifact = await readFile(new URL('../fixtures/staging/base-fixture-v1.sql', import.meta.url), 'utf8');
  assert.equal(artifact, renderBaseFixtureSql());
  assert.equal(/\b(REPLACE|DELETE|DROP|TRUNCATE|UPDATE|ALTER)\b/i.test(artifact), false);
  assert.equal(artifact.includes('performance-'), false);
  assert.equal((artifact.match(/INSERT INTO first_prize_results/g) || []).length, 16);
  assert.equal((artifact.match(/INSERT INTO coverage/g) || []).length, 19);
  assert.equal((artifact.match(/INSERT INTO result_revisions/g) || []).length, 1);
});

test('SQL artifact loads twice into ephemeral D1 without duplicates', async (t) => {
  const { platform, db } = await localDatabase();
  t.after(() => platform.dispose());
  const sql = await readFile(new URL('../fixtures/staging/base-fixture-v1.sql', import.meta.url), 'utf8');
  await executeSql(db, sql);
  assert.deepEqual(await counts(db), [16, 19, 1]);
  await executeSql(db, sql);
  assert.deepEqual(await counts(db), [16, 19, 1]);
  assert.deepEqual((await db.prepare('PRAGMA foreign_key_check').all()).results, []);

  clearNumberTransitionsCache();
  const analysis = await loadNumberTransitions(db, SERIES.ganaMas, {
    originNumber: '24',
    from: '2026-04-01',
    to: '2026-04-11',
    asOfDate: '2026-11-09',
  });
  assert.equal(analysis.totalTransitions, 5);
  assert.deepEqual(analysis.results.map(({ nextNumber, transitionCount, relativeFrequency }) => ({
    nextNumber, transitionCount, relativeFrequency,
  })), [
    { nextNumber: '67', transitionCount: 3, relativeFrequency: 0.6 },
    { nextNumber: '24', transitionCount: 1, relativeFrequency: 0.2 },
    { nextNumber: '32', transitionCount: 1, relativeFrequency: 0.2 },
  ]);
});

test('SQL artifact does not overwrite a colliding foreign result', async (t) => {
  const { platform, db } = await localDatabase();
  t.after(() => platform.dispose());
  await db.prepare(`
    INSERT INTO first_prize_results (
      provider_result_id, operator_id, draw_id, draw_date, first_number,
      source, checksum, raw_payload, collected_at, updated_at
    ) VALUES (
      'synthetic-staging-v1-gm-base-01',
      '6966a6d1ea7015c3b8a3d477',
      '6966a6d1ea7015c3b8a3d482',
      '2026-04-01', '99', 'foreign', 'foreign', '{}',
      '2026-04-01T21:00:00.000Z', '2026-04-01T21:00:00.000Z'
    )
  `).run();
  const sql = await readFile(new URL('../fixtures/staging/base-fixture-v1.sql', import.meta.url), 'utf8');
  await executeSql(db, sql);
  const stored = await db.prepare(`
    SELECT first_number, source FROM first_prize_results
    WHERE provider_result_id = 'synthetic-staging-v1-gm-base-01'
  `).first();
  assert.deepEqual(stored, { first_number: '99', source: 'foreign' });
  assert.deepEqual(await counts(db), [16, 19, 1]);
});
