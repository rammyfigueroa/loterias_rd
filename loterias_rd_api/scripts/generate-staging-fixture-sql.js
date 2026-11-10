#!/usr/bin/env node

import { writeFile } from 'node:fs/promises';

import { createBaseFixture } from './staging-fixtures.js';

function sqlValue(value) {
  if (value === null || value === undefined) return 'NULL';
  if (typeof value === 'number') return String(value);
  return `'${String(value).replaceAll("'", "''")}'`;
}

function resultStatement(item) {
  const values = [
    item.providerResultId, item.operatorId, item.drawId, item.drawDate,
    item.firstNumber, item.source, item.checksum, item.rawPayload,
    item.providerCreatedAt, item.providerUpdatedAt, item.collectedAt, item.updatedAt,
  ].map(sqlValue).join(',\n  ');
  return `INSERT INTO first_prize_results (
  provider_result_id, operator_id, draw_id, draw_date, first_number,
  source, checksum, raw_payload, provider_created_at, provider_updated_at,
  collected_at, updated_at
)
SELECT
  ${values}
WHERE NOT EXISTS (
  SELECT 1 FROM first_prize_results
  WHERE provider_result_id = ${sqlValue(item.providerResultId)}
     OR (draw_id = ${sqlValue(item.drawId)} AND draw_date = ${sqlValue(item.drawDate)})
);`;
}

function coverageStatement(item) {
  const values = [
    item.operatorId, item.drawId, item.coverageDate, item.status, item.source,
    item.verificationSource, item.detail, item.attemptCount, item.lastError,
    item.checkedAt, item.nextRetryAt,
  ].map(sqlValue).join(',\n  ');
  return `INSERT INTO coverage (
  operator_id, draw_id, coverage_date, status, source,
  verification_source, detail, attempt_count, last_error,
  checked_at, next_retry_at
)
SELECT
  ${values}
WHERE NOT EXISTS (
  SELECT 1 FROM coverage
  WHERE draw_id = ${sqlValue(item.drawId)}
    AND coverage_date = ${sqlValue(item.coverageDate)}
);`;
}

function revisionStatement(item, expectedResult) {
  const values = [
    item.providerResultId, item.oldFirstNumber, item.newFirstNumber,
    item.oldChecksum, item.newChecksum, item.oldRawPayload, item.newRawPayload,
    item.detectedAt,
  ].map(sqlValue).join(',\n  ');
  return `INSERT INTO result_revisions (
  result_id, provider_result_id, old_first_number, new_first_number,
  old_checksum, new_checksum, old_raw_payload, new_raw_payload, detected_at
)
SELECT
  r.id,
  ${values}
FROM first_prize_results r
WHERE r.provider_result_id = ${sqlValue(item.providerResultId)}
  AND r.draw_id = ${sqlValue(expectedResult.drawId)}
  AND r.draw_date = ${sqlValue(expectedResult.drawDate)}
  AND r.first_number = ${sqlValue(expectedResult.firstNumber)}
  AND r.source = ${sqlValue(expectedResult.source)}
  AND r.checksum = ${sqlValue(expectedResult.checksum)}
  AND r.raw_payload = ${sqlValue(expectedResult.rawPayload)}
  AND NOT EXISTS (
    SELECT 1 FROM result_revisions rr
    WHERE rr.provider_result_id = ${sqlValue(item.providerResultId)}
      AND rr.detected_at = ${sqlValue(item.detectedAt)}
  );`;
}

export function renderBaseFixtureSql(fixture = createBaseFixture()) {
  if (fixture.name !== 'base' || fixture.results.length !== 16 ||
      fixture.coverage.length !== 19 || fixture.revisions.length !== 1) {
    throw new Error('The SQL artifact only supports the validated base fixture.');
  }
  const statements = [
    ...fixture.results.map(resultStatement),
    ...fixture.coverage.map(coverageStatement),
    ...fixture.revisions.map((item) => {
      const expectedResult = fixture.results.find(
        (result) => result.providerResultId === item.providerResultId,
      );
      if (!expectedResult) throw new Error(`Missing canonical result for ${item.providerResultId}.`);
      return revisionStatement(item, expectedResult);
    }),
  ];
  return `-- Sorteos Dominicanos: synthetic staging fixture v1.
-- Generated deterministically from scripts/staging-fixtures.js.
-- Scope: 16 results, 19 coverage rows, 1 revision.
-- This artifact never updates, replaces or deletes existing rows.
-- A remote dry run and an independent authorization are required before use.

${statements.join('\n\n')}
`;
}

export async function generateArtifact(outputUrl = new URL('../fixtures/staging/base-fixture-v1.sql', import.meta.url)) {
  const sql = renderBaseFixtureSql();
  await writeFile(outputUrl, sql, { encoding: 'utf8', flag: 'w' });
  return outputUrl;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  generateArtifact().then((outputUrl) => {
    process.stdout.write(`Generated ${outputUrl.pathname}\n`);
  }).catch((error) => {
    process.stderr.write(`Fixture SQL generation failed: ${error.message}\n`);
    process.exitCode = 1;
  });
}
