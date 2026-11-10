import { readFile } from 'node:fs/promises';

import {
  GANA_MAS_DRAW_ID,
  NATIONAL_DRAW_ID,
  OPERATOR_ID,
} from '../src/history/constants.js';

export const FIXTURE_SOURCE = 'synthetic-staging-fixture-v1';
export const FIXTURE_PREFIX = 'synthetic-staging-v1';
export const PERFORMANCE_EVENT_COUNT = 5_000;

const EXPECTED_TABLES = [
  'backfill_state',
  'coverage',
  'draws',
  'first_prize_results',
  'operators',
  'result_revisions',
];

const EXPECTED_DRAWS = new Map([
  [GANA_MAS_DRAW_ID, 'Gana Más'],
  [NATIONAL_DRAW_ID, 'Lotería Nacional'],
]);

function isoDateFromOffset(startDate, offset) {
  const date = new Date(`${startDate}T12:00:00.000Z`);
  date.setUTCDate(date.getUTCDate() + offset);
  return date.toISOString().slice(0, 10);
}

function fixtureTimestamp(date, hour = '20') {
  return `${date}T${hour}:00:00.000Z`;
}

function result({ key, drawId, date, number, checksumSuffix = number }) {
  const providerResultId = `${FIXTURE_PREFIX}-${key}`;
  const payload = JSON.stringify({
    fixture: true,
    fixtureVersion: 1,
    providerResultId,
    drawId,
    drawDate: date,
    firstNumber: number,
  });
  return {
    providerResultId,
    operatorId: OPERATOR_ID,
    drawId,
    drawDate: date,
    firstNumber: number,
    source: FIXTURE_SOURCE,
    checksum: `${FIXTURE_PREFIX}-${checksumSuffix}`,
    rawPayload: payload,
    providerCreatedAt: fixtureTimestamp(date),
    providerUpdatedAt: fixtureTimestamp(date),
    collectedAt: fixtureTimestamp(date, '21'),
    updatedAt: fixtureTimestamp(date, '21'),
  };
}

function coverage({ drawId, date, status, verificationSource = null, detail = null }) {
  return {
    operatorId: OPERATOR_ID,
    drawId,
    coverageDate: date,
    status,
    source: FIXTURE_SOURCE,
    verificationSource,
    detail,
    attemptCount: 1,
    lastError: null,
    checkedAt: fixtureTimestamp(date, '22'),
    nextRetryAt: null,
  };
}

export function createBaseFixture() {
  const ganaMasNumbers = [
    ['2026-04-01', '24'],
    ['2026-04-02', '67'],
    ['2026-04-03', '24'],
    ['2026-04-04', '32'],
    ['2026-04-06', '24'],
    ['2026-04-07', '67'],
    ['2026-04-08', '24'],
    ['2026-04-09', '67'],
    ['2026-04-10', '24'],
    ['2026-04-11', '24'],
  ];
  const nationalNumbers = [
    ['2026-05-01', '10'],
    ['2026-05-02', '20'],
    ['2026-05-04', '10'],
    ['2026-05-05', '30'],
    ['2026-05-07', '10'],
    ['2026-05-08', '20'],
  ];

  const results = [
    ...ganaMasNumbers.map(([date, number], index) => result({
      key: `gm-base-${String(index + 1).padStart(2, '0')}`,
      drawId: GANA_MAS_DRAW_ID,
      date,
      number,
      checksumSuffix: date === '2026-04-04' ? 'corrected-32' : `gm-${date}-${number}`,
    })),
    ...nationalNumbers.map(([date, number], index) => result({
      key: `national-base-${String(index + 1).padStart(2, '0')}`,
      drawId: NATIONAL_DRAW_ID,
      date,
      number,
      checksumSuffix: `national-${date}-${number}`,
    })),
  ];

  const ganaMasCoverage = Array.from({ length: 11 }, (_, index) => {
    const date = isoDateFromOffset('2026-04-01', index);
    if (date === '2026-04-05') {
      return coverage({
        drawId: GANA_MAS_DRAW_ID,
        date,
        status: 'NO_DRAW_SCHEDULED',
        verificationSource: 'synthetic-official-calendar-v1',
        detail: 'Synthetic verified no-draw date.',
      });
    }
    return coverage({ drawId: GANA_MAS_DRAW_ID, date, status: 'RESULT_FOUND' });
  });
  const nationalCoverage = Array.from({ length: 8 }, (_, index) => {
    const date = isoDateFromOffset('2026-05-01', index);
    if (date === '2026-05-03') {
      return coverage({
        drawId: NATIONAL_DRAW_ID,
        date,
        status: 'NO_RESULTS_RETURNED',
        detail: 'Synthetic incomplete provider response.',
      });
    }
    if (date === '2026-05-06') {
      return coverage({
        drawId: NATIONAL_DRAW_ID,
        date,
        status: 'UNVERIFIED',
        detail: 'Synthetic unknown coverage state.',
      });
    }
    return coverage({ drawId: NATIONAL_DRAW_ID, date, status: 'RESULT_FOUND' });
  });

  const corrected = results.find((item) =>
    item.drawId === GANA_MAS_DRAW_ID && item.drawDate === '2026-04-04');
  const revisions = [{
    providerResultId: corrected.providerResultId,
    oldFirstNumber: '31',
    newFirstNumber: '32',
    oldChecksum: `${FIXTURE_PREFIX}-pre-correction-31`,
    newChecksum: corrected.checksum,
    oldRawPayload: JSON.stringify({ fixture: true, firstNumber: '31', corrected: false }),
    newRawPayload: corrected.rawPayload,
    detectedAt: '2026-04-04T22:30:00.000Z',
  }];

  return {
    name: 'base',
    results,
    coverage: [...ganaMasCoverage, ...nationalCoverage],
    revisions,
    expected: {
      resultCount: 16,
      coverageCount: 19,
      revisionCount: 1,
      ganaMasOrigin24: {
        originAppearances: 6,
        originEventsWithoutSuccessor: 1,
        totalTransitions: 5,
        destinations: [
          { nextNumber: '67', transitionCount: 3, relativeFrequency: 0.6 },
          { nextNumber: '24', transitionCount: 1, relativeFrequency: 0.2 },
          { nextNumber: '32', transitionCount: 1, relativeFrequency: 0.2 },
        ],
      },
    },
  };
}

export function createPerformanceFixture(eventCount = PERFORMANCE_EVENT_COUNT) {
  if (!Number.isInteger(eventCount) || eventCount < 2) {
    throw new Error('eventCount must be an integer greater than one.');
  }
  const results = [];
  const coverageRows = [];
  for (let index = 0; index < eventCount; index += 1) {
    const date = isoDateFromOffset('2010-01-01', index);
    const number = String((11 + (index * 37)) % 100).padStart(2, '0');
    results.push(result({
      key: `performance-${String(index + 1).padStart(5, '0')}`,
      drawId: GANA_MAS_DRAW_ID,
      date,
      number,
      checksumSuffix: `performance-${String(index + 1).padStart(5, '0')}-${number}`,
    }));
    coverageRows.push(coverage({
      drawId: GANA_MAS_DRAW_ID,
      date,
      status: 'RESULT_FOUND',
    }));
  }
  return {
    name: 'performance',
    results,
    coverage: coverageRows,
    revisions: [],
    expected: {
      resultCount: eventCount,
      coverageCount: eventCount,
      revisionCount: 0,
      firstDate: results[0].drawDate,
      lastDate: results.at(-1).drawDate,
    },
  };
}

function rows(result) {
  return result?.results || [];
}

function first(result) {
  return rows(result)[0] || null;
}

async function executeSql(db, sql) {
  const statements = sql
    .split(/;\s*(?:\n|$)/)
    .map((statement) => statement.trim())
    .filter(Boolean);
  await db.batch(statements.map((statement) => db.prepare(statement)));
}

export async function ensureLocalSchema(db) {
  const allTables = rows(await db.prepare(`
    SELECT name FROM sqlite_master
    WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
    ORDER BY name
  `).all()).map((item) => item.name);
  const allowedInternalTables = new Set(['_cf_KV', '_cf_METADATA', 'd1_migrations']);
  const unexpectedTables = allTables.filter((name) =>
    !EXPECTED_TABLES.includes(name) && !allowedInternalTables.has(name));
  if (unexpectedTables.length > 0) {
    throw new Error(`Refusing a local database with unexpected tables: ${unexpectedTables.join(', ')}.`);
  }
  const found = await db.prepare(`
    SELECT name FROM sqlite_master
    WHERE type = 'table' AND name IN (${EXPECTED_TABLES.map(() => '?').join(', ')})
    ORDER BY name
  `).bind(...EXPECTED_TABLES).all();
  const existing = rows(found).map((item) => item.name);
  if (existing.length === 0) {
    for (const name of ['0001_gana_mas_history.sql', '0002_national_history.sql']) {
      const sql = await readFile(new URL(`../migrations/${name}`, import.meta.url), 'utf8');
      await executeSql(db, sql);
    }
  } else if (JSON.stringify(existing) !== JSON.stringify(EXPECTED_TABLES)) {
    throw new Error(`Refusing a partial or unexpected schema: ${existing.join(', ') || 'none'}.`);
  }
  await assertFixtureTarget(db);
}

export async function assertFixtureTarget(db) {
  const schema = await db.prepare(`
    SELECT name FROM sqlite_master
    WHERE type = 'table' AND name IN (${EXPECTED_TABLES.map(() => '?').join(', ')})
    ORDER BY name
  `).bind(...EXPECTED_TABLES).all();
  const tables = rows(schema).map((item) => item.name);
  if (JSON.stringify(tables) !== JSON.stringify(EXPECTED_TABLES)) {
    throw new Error(`Fixture target does not have the expected historical schema: ${tables.join(', ')}.`);
  }

  const operator = first(await db.prepare(
    'SELECT id, name FROM operators WHERE id = ?',
  ).bind(OPERATOR_ID).all());
  if (!operator || operator.name !== 'Nacional') {
    throw new Error('Fixture target does not contain the expected Nacional operator identity.');
  }

  const draws = rows(await db.prepare(`
    SELECT id, operator_id, name, first_position_path, enabled
    FROM draws WHERE operator_id = ? ORDER BY id
  `).bind(OPERATOR_ID).all());
  for (const [drawId, drawName] of EXPECTED_DRAWS) {
    const draw = draws.find((item) => item.id === drawId);
    if (!draw || draw.name !== drawName || draw.operator_id !== OPERATOR_ID ||
        draw.first_position_path !== 'score[0][0]' || Number(draw.enabled) !== 1) {
      throw new Error(`Fixture target has an invalid identity for ${drawName}.`);
    }
  }
}

function equalResult(existing, expected) {
  return existing.provider_result_id === expected.providerResultId &&
    existing.operator_id === expected.operatorId &&
    existing.draw_id === expected.drawId &&
    existing.draw_date === expected.drawDate &&
    existing.first_number === expected.firstNumber &&
    existing.source === expected.source &&
    existing.checksum === expected.checksum &&
    existing.raw_payload === expected.rawPayload &&
    existing.provider_created_at === expected.providerCreatedAt &&
    existing.provider_updated_at === expected.providerUpdatedAt &&
    existing.collected_at === expected.collectedAt &&
    existing.updated_at === expected.updatedAt;
}

function equalCoverage(existing, expected) {
  return existing.operator_id === expected.operatorId &&
    existing.draw_id === expected.drawId &&
    existing.coverage_date === expected.coverageDate &&
    existing.status === expected.status &&
    existing.source === expected.source &&
    existing.verification_source === expected.verificationSource &&
    existing.detail === expected.detail &&
    Number(existing.attempt_count) === expected.attemptCount &&
    existing.last_error === expected.lastError &&
    existing.checked_at === expected.checkedAt &&
    existing.next_retry_at === expected.nextRetryAt;
}

function fixtureRanges(items, dateField) {
  const byDraw = new Map();
  for (const item of items) {
    const date = item[dateField];
    const current = byDraw.get(item.drawId) || { from: date, to: date };
    if (date < current.from) current.from = date;
    if (date > current.to) current.to = date;
    byDraw.set(item.drawId, current);
  }
  return byDraw;
}

async function loadExistingResults(db, expected) {
  const found = [];
  for (const [drawId, range] of fixtureRanges(expected, 'drawDate')) {
    const query = await db.prepare(`
      SELECT provider_result_id, operator_id, draw_id, draw_date, first_number,
             source, checksum, raw_payload, provider_created_at,
             provider_updated_at, collected_at, updated_at
      FROM first_prize_results
      WHERE (draw_id = ? AND draw_date BETWEEN ? AND ?)
         OR provider_result_id LIKE ?
    `).bind(drawId, range.from, range.to, `${FIXTURE_PREFIX}-%`).all();
    found.push(...rows(query));
  }
  return [...new Map(found.map((item) => [item.provider_result_id, item])).values()];
}

async function loadExistingCoverage(db, expected) {
  const found = [];
  for (const [drawId, range] of fixtureRanges(expected, 'coverageDate')) {
    const query = await db.prepare(`
      SELECT operator_id, draw_id, coverage_date, status, source,
             verification_source, detail, attempt_count, last_error,
             checked_at, next_retry_at
      FROM coverage
      WHERE draw_id = ? AND coverage_date BETWEEN ? AND ?
    `).bind(drawId, range.from, range.to).all();
    found.push(...rows(query));
  }
  return found;
}

async function preflight(db, fixture) {
  const existingResults = await loadExistingResults(db, fixture.results);
  const resultsByProvider = new Map(existingResults.map((item) => [item.provider_result_id, item]));
  const resultsByDate = new Map(existingResults.map((item) => [`${item.draw_id}|${item.draw_date}`, item]));
  const missingResults = [];
  for (const expected of fixture.results) {
    const byProvider = resultsByProvider.get(expected.providerResultId);
    const byDate = resultsByDate.get(`${expected.drawId}|${expected.drawDate}`);
    const existing = byProvider || byDate;
    if (!existing) missingResults.push(expected);
    else if (byProvider !== byDate || !equalResult(existing, expected)) {
      throw new Error(`Fixture collision in first_prize_results for ${expected.providerResultId}.`);
    }
  }

  const existingCoverage = await loadExistingCoverage(db, fixture.coverage);
  const coverageByDate = new Map(existingCoverage.map((item) => [`${item.draw_id}|${item.coverage_date}`, item]));
  const missingCoverage = [];
  for (const expected of fixture.coverage) {
    const existing = coverageByDate.get(`${expected.drawId}|${expected.coverageDate}`);
    if (!existing) missingCoverage.push(expected);
    else if (!equalCoverage(existing, expected)) {
      throw new Error(`Fixture collision in coverage for ${expected.drawId} on ${expected.coverageDate}.`);
    }
  }

  const missingRevisions = [];
  for (const expected of fixture.revisions) {
    const existing = rows(await db.prepare(`
      SELECT rr.old_first_number, rr.new_first_number, rr.old_checksum,
             rr.new_checksum, rr.old_raw_payload, rr.new_raw_payload, rr.detected_at
      FROM result_revisions rr
      JOIN first_prize_results r ON r.id = rr.result_id
      WHERE rr.provider_result_id = ? AND rr.detected_at = ?
    `).bind(expected.providerResultId, expected.detectedAt).all());
    if (existing.length === 0) missingRevisions.push(expected);
    else if (existing.length !== 1 ||
      existing[0].old_first_number !== expected.oldFirstNumber ||
      existing[0].new_first_number !== expected.newFirstNumber ||
      existing[0].old_checksum !== expected.oldChecksum ||
      existing[0].new_checksum !== expected.newChecksum ||
      existing[0].old_raw_payload !== expected.oldRawPayload ||
      existing[0].new_raw_payload !== expected.newRawPayload) {
      throw new Error(`Fixture collision in result_revisions for ${expected.providerResultId}.`);
    }
  }
  return { missingResults, missingCoverage, missingRevisions };
}

async function executeInChunks(db, statements, chunkSize = 100) {
  for (let index = 0; index < statements.length; index += chunkSize) {
    await db.batch(statements.slice(index, index + chunkSize));
  }
}

export async function loadFixture(db, fixture) {
  await assertFixtureTarget(db);
  const missing = await preflight(db, fixture);
  await executeInChunks(db, missing.missingResults.map((item) => db.prepare(`
    INSERT INTO first_prize_results (
      provider_result_id, operator_id, draw_id, draw_date, first_number,
      source, checksum, raw_payload, provider_created_at, provider_updated_at,
      collected_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).bind(
    item.providerResultId, item.operatorId, item.drawId, item.drawDate,
    item.firstNumber, item.source, item.checksum, item.rawPayload,
    item.providerCreatedAt, item.providerUpdatedAt, item.collectedAt, item.updatedAt,
  )));
  await executeInChunks(db, missing.missingCoverage.map((item) => db.prepare(`
    INSERT INTO coverage (
      operator_id, draw_id, coverage_date, status, source,
      verification_source, detail, attempt_count, last_error,
      checked_at, next_retry_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).bind(
    item.operatorId, item.drawId, item.coverageDate, item.status, item.source,
    item.verificationSource, item.detail, item.attemptCount, item.lastError,
    item.checkedAt, item.nextRetryAt,
  )));
  await executeInChunks(db, missing.missingRevisions.map((item) => db.prepare(`
    INSERT INTO result_revisions (
      result_id, provider_result_id, old_first_number, new_first_number,
      old_checksum, new_checksum, old_raw_payload, new_raw_payload, detected_at
    )
    SELECT id, ?, ?, ?, ?, ?, ?, ?, ?
    FROM first_prize_results WHERE provider_result_id = ?
  `).bind(
    item.providerResultId, item.oldFirstNumber, item.newFirstNumber,
    item.oldChecksum, item.newChecksum, item.oldRawPayload, item.newRawPayload,
    item.detectedAt, item.providerResultId,
  )));

  const verified = await verifyFixture(db, fixture);
  return {
    fixture: fixture.name,
    inserted: {
      results: missing.missingResults.length,
      coverage: missing.missingCoverage.length,
      revisions: missing.missingRevisions.length,
    },
    totals: verified,
  };
}

export async function verifyFixture(db, fixture) {
  const providerIds = fixture.results.map((item) => item.providerResultId);
  let resultCount = 0;
  for (let index = 0; index < providerIds.length; index += 100) {
    const chunk = providerIds.slice(index, index + 100);
    const query = await db.prepare(`
      SELECT COUNT(*) AS count FROM first_prize_results
      WHERE provider_result_id IN (${chunk.map(() => '?').join(', ')})
    `).bind(...chunk).first();
    resultCount += Number(query?.count || 0);
  }

  let coverageCount = 0;
  for (const [drawId, range] of fixtureRanges(fixture.coverage, 'coverageDate')) {
    const expectedDates = new Set(fixture.coverage
      .filter((item) => item.drawId === drawId)
      .map((item) => item.coverageDate));
    const query = await db.prepare(`
      SELECT coverage_date, source FROM coverage
      WHERE draw_id = ? AND coverage_date BETWEEN ? AND ?
    `).bind(drawId, range.from, range.to).all();
    coverageCount += rows(query).filter((item) =>
      expectedDates.has(item.coverage_date) && item.source === FIXTURE_SOURCE).length;
  }

  let revisionCount = 0;
  for (const item of fixture.revisions) {
    const query = await db.prepare(`
      SELECT COUNT(*) AS count FROM result_revisions
      WHERE provider_result_id = ? AND detected_at = ?
    `).bind(item.providerResultId, item.detectedAt).first();
    revisionCount += Number(query?.count || 0);
  }
  const foreignKeyCheck = rows(await db.prepare('PRAGMA foreign_key_check').all());
  if (foreignKeyCheck.length > 0) throw new Error('Fixture violates foreign-key integrity.');

  const expected = fixture.expected;
  if (resultCount !== expected.resultCount || coverageCount !== expected.coverageCount ||
      revisionCount !== expected.revisionCount) {
    throw new Error(
      `Fixture verification failed: results=${resultCount}, coverage=${coverageCount}, revisions=${revisionCount}.`,
    );
  }
  return { results: resultCount, coverage: coverageCount, revisions: revisionCount };
}
