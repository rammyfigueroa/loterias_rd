-- Sorteos Dominicanos: synthetic staging fixture v1.
-- Generated deterministically from scripts/staging-fixtures.js.
-- Scope: 16 results, 19 coverage rows, 1 revision.
-- This artifact never updates, replaces or deletes existing rows.
-- A remote dry run and an independent authorization are required before use.

INSERT INTO first_prize_results (
  provider_result_id, operator_id, draw_id, draw_date, first_number,
  source, checksum, raw_payload, provider_created_at, provider_updated_at,
  collected_at, updated_at
)
SELECT
  'synthetic-staging-v1-gm-base-01',
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d482',
  '2026-04-01',
  '24',
  'synthetic-staging-fixture-v1',
  'synthetic-staging-v1-gm-2026-04-01-24',
  '{"fixture":true,"fixtureVersion":1,"providerResultId":"synthetic-staging-v1-gm-base-01","drawId":"6966a6d1ea7015c3b8a3d482","drawDate":"2026-04-01","firstNumber":"24"}',
  '2026-04-01T20:00:00.000Z',
  '2026-04-01T20:00:00.000Z',
  '2026-04-01T21:00:00.000Z',
  '2026-04-01T21:00:00.000Z'
WHERE NOT EXISTS (
  SELECT 1 FROM first_prize_results
  WHERE provider_result_id = 'synthetic-staging-v1-gm-base-01'
     OR (draw_id = '6966a6d1ea7015c3b8a3d482' AND draw_date = '2026-04-01')
);

INSERT INTO first_prize_results (
  provider_result_id, operator_id, draw_id, draw_date, first_number,
  source, checksum, raw_payload, provider_created_at, provider_updated_at,
  collected_at, updated_at
)
SELECT
  'synthetic-staging-v1-gm-base-02',
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d482',
  '2026-04-02',
  '67',
  'synthetic-staging-fixture-v1',
  'synthetic-staging-v1-gm-2026-04-02-67',
  '{"fixture":true,"fixtureVersion":1,"providerResultId":"synthetic-staging-v1-gm-base-02","drawId":"6966a6d1ea7015c3b8a3d482","drawDate":"2026-04-02","firstNumber":"67"}',
  '2026-04-02T20:00:00.000Z',
  '2026-04-02T20:00:00.000Z',
  '2026-04-02T21:00:00.000Z',
  '2026-04-02T21:00:00.000Z'
WHERE NOT EXISTS (
  SELECT 1 FROM first_prize_results
  WHERE provider_result_id = 'synthetic-staging-v1-gm-base-02'
     OR (draw_id = '6966a6d1ea7015c3b8a3d482' AND draw_date = '2026-04-02')
);

INSERT INTO first_prize_results (
  provider_result_id, operator_id, draw_id, draw_date, first_number,
  source, checksum, raw_payload, provider_created_at, provider_updated_at,
  collected_at, updated_at
)
SELECT
  'synthetic-staging-v1-gm-base-03',
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d482',
  '2026-04-03',
  '24',
  'synthetic-staging-fixture-v1',
  'synthetic-staging-v1-gm-2026-04-03-24',
  '{"fixture":true,"fixtureVersion":1,"providerResultId":"synthetic-staging-v1-gm-base-03","drawId":"6966a6d1ea7015c3b8a3d482","drawDate":"2026-04-03","firstNumber":"24"}',
  '2026-04-03T20:00:00.000Z',
  '2026-04-03T20:00:00.000Z',
  '2026-04-03T21:00:00.000Z',
  '2026-04-03T21:00:00.000Z'
WHERE NOT EXISTS (
  SELECT 1 FROM first_prize_results
  WHERE provider_result_id = 'synthetic-staging-v1-gm-base-03'
     OR (draw_id = '6966a6d1ea7015c3b8a3d482' AND draw_date = '2026-04-03')
);

INSERT INTO first_prize_results (
  provider_result_id, operator_id, draw_id, draw_date, first_number,
  source, checksum, raw_payload, provider_created_at, provider_updated_at,
  collected_at, updated_at
)
SELECT
  'synthetic-staging-v1-gm-base-04',
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d482',
  '2026-04-04',
  '32',
  'synthetic-staging-fixture-v1',
  'synthetic-staging-v1-corrected-32',
  '{"fixture":true,"fixtureVersion":1,"providerResultId":"synthetic-staging-v1-gm-base-04","drawId":"6966a6d1ea7015c3b8a3d482","drawDate":"2026-04-04","firstNumber":"32"}',
  '2026-04-04T20:00:00.000Z',
  '2026-04-04T20:00:00.000Z',
  '2026-04-04T21:00:00.000Z',
  '2026-04-04T21:00:00.000Z'
WHERE NOT EXISTS (
  SELECT 1 FROM first_prize_results
  WHERE provider_result_id = 'synthetic-staging-v1-gm-base-04'
     OR (draw_id = '6966a6d1ea7015c3b8a3d482' AND draw_date = '2026-04-04')
);

INSERT INTO first_prize_results (
  provider_result_id, operator_id, draw_id, draw_date, first_number,
  source, checksum, raw_payload, provider_created_at, provider_updated_at,
  collected_at, updated_at
)
SELECT
  'synthetic-staging-v1-gm-base-05',
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d482',
  '2026-04-06',
  '24',
  'synthetic-staging-fixture-v1',
  'synthetic-staging-v1-gm-2026-04-06-24',
  '{"fixture":true,"fixtureVersion":1,"providerResultId":"synthetic-staging-v1-gm-base-05","drawId":"6966a6d1ea7015c3b8a3d482","drawDate":"2026-04-06","firstNumber":"24"}',
  '2026-04-06T20:00:00.000Z',
  '2026-04-06T20:00:00.000Z',
  '2026-04-06T21:00:00.000Z',
  '2026-04-06T21:00:00.000Z'
WHERE NOT EXISTS (
  SELECT 1 FROM first_prize_results
  WHERE provider_result_id = 'synthetic-staging-v1-gm-base-05'
     OR (draw_id = '6966a6d1ea7015c3b8a3d482' AND draw_date = '2026-04-06')
);

INSERT INTO first_prize_results (
  provider_result_id, operator_id, draw_id, draw_date, first_number,
  source, checksum, raw_payload, provider_created_at, provider_updated_at,
  collected_at, updated_at
)
SELECT
  'synthetic-staging-v1-gm-base-06',
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d482',
  '2026-04-07',
  '67',
  'synthetic-staging-fixture-v1',
  'synthetic-staging-v1-gm-2026-04-07-67',
  '{"fixture":true,"fixtureVersion":1,"providerResultId":"synthetic-staging-v1-gm-base-06","drawId":"6966a6d1ea7015c3b8a3d482","drawDate":"2026-04-07","firstNumber":"67"}',
  '2026-04-07T20:00:00.000Z',
  '2026-04-07T20:00:00.000Z',
  '2026-04-07T21:00:00.000Z',
  '2026-04-07T21:00:00.000Z'
WHERE NOT EXISTS (
  SELECT 1 FROM first_prize_results
  WHERE provider_result_id = 'synthetic-staging-v1-gm-base-06'
     OR (draw_id = '6966a6d1ea7015c3b8a3d482' AND draw_date = '2026-04-07')
);

INSERT INTO first_prize_results (
  provider_result_id, operator_id, draw_id, draw_date, first_number,
  source, checksum, raw_payload, provider_created_at, provider_updated_at,
  collected_at, updated_at
)
SELECT
  'synthetic-staging-v1-gm-base-07',
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d482',
  '2026-04-08',
  '24',
  'synthetic-staging-fixture-v1',
  'synthetic-staging-v1-gm-2026-04-08-24',
  '{"fixture":true,"fixtureVersion":1,"providerResultId":"synthetic-staging-v1-gm-base-07","drawId":"6966a6d1ea7015c3b8a3d482","drawDate":"2026-04-08","firstNumber":"24"}',
  '2026-04-08T20:00:00.000Z',
  '2026-04-08T20:00:00.000Z',
  '2026-04-08T21:00:00.000Z',
  '2026-04-08T21:00:00.000Z'
WHERE NOT EXISTS (
  SELECT 1 FROM first_prize_results
  WHERE provider_result_id = 'synthetic-staging-v1-gm-base-07'
     OR (draw_id = '6966a6d1ea7015c3b8a3d482' AND draw_date = '2026-04-08')
);

INSERT INTO first_prize_results (
  provider_result_id, operator_id, draw_id, draw_date, first_number,
  source, checksum, raw_payload, provider_created_at, provider_updated_at,
  collected_at, updated_at
)
SELECT
  'synthetic-staging-v1-gm-base-08',
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d482',
  '2026-04-09',
  '67',
  'synthetic-staging-fixture-v1',
  'synthetic-staging-v1-gm-2026-04-09-67',
  '{"fixture":true,"fixtureVersion":1,"providerResultId":"synthetic-staging-v1-gm-base-08","drawId":"6966a6d1ea7015c3b8a3d482","drawDate":"2026-04-09","firstNumber":"67"}',
  '2026-04-09T20:00:00.000Z',
  '2026-04-09T20:00:00.000Z',
  '2026-04-09T21:00:00.000Z',
  '2026-04-09T21:00:00.000Z'
WHERE NOT EXISTS (
  SELECT 1 FROM first_prize_results
  WHERE provider_result_id = 'synthetic-staging-v1-gm-base-08'
     OR (draw_id = '6966a6d1ea7015c3b8a3d482' AND draw_date = '2026-04-09')
);

INSERT INTO first_prize_results (
  provider_result_id, operator_id, draw_id, draw_date, first_number,
  source, checksum, raw_payload, provider_created_at, provider_updated_at,
  collected_at, updated_at
)
SELECT
  'synthetic-staging-v1-gm-base-09',
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d482',
  '2026-04-10',
  '24',
  'synthetic-staging-fixture-v1',
  'synthetic-staging-v1-gm-2026-04-10-24',
  '{"fixture":true,"fixtureVersion":1,"providerResultId":"synthetic-staging-v1-gm-base-09","drawId":"6966a6d1ea7015c3b8a3d482","drawDate":"2026-04-10","firstNumber":"24"}',
  '2026-04-10T20:00:00.000Z',
  '2026-04-10T20:00:00.000Z',
  '2026-04-10T21:00:00.000Z',
  '2026-04-10T21:00:00.000Z'
WHERE NOT EXISTS (
  SELECT 1 FROM first_prize_results
  WHERE provider_result_id = 'synthetic-staging-v1-gm-base-09'
     OR (draw_id = '6966a6d1ea7015c3b8a3d482' AND draw_date = '2026-04-10')
);

INSERT INTO first_prize_results (
  provider_result_id, operator_id, draw_id, draw_date, first_number,
  source, checksum, raw_payload, provider_created_at, provider_updated_at,
  collected_at, updated_at
)
SELECT
  'synthetic-staging-v1-gm-base-10',
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d482',
  '2026-04-11',
  '24',
  'synthetic-staging-fixture-v1',
  'synthetic-staging-v1-gm-2026-04-11-24',
  '{"fixture":true,"fixtureVersion":1,"providerResultId":"synthetic-staging-v1-gm-base-10","drawId":"6966a6d1ea7015c3b8a3d482","drawDate":"2026-04-11","firstNumber":"24"}',
  '2026-04-11T20:00:00.000Z',
  '2026-04-11T20:00:00.000Z',
  '2026-04-11T21:00:00.000Z',
  '2026-04-11T21:00:00.000Z'
WHERE NOT EXISTS (
  SELECT 1 FROM first_prize_results
  WHERE provider_result_id = 'synthetic-staging-v1-gm-base-10'
     OR (draw_id = '6966a6d1ea7015c3b8a3d482' AND draw_date = '2026-04-11')
);

INSERT INTO first_prize_results (
  provider_result_id, operator_id, draw_id, draw_date, first_number,
  source, checksum, raw_payload, provider_created_at, provider_updated_at,
  collected_at, updated_at
)
SELECT
  'synthetic-staging-v1-national-base-01',
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d47c',
  '2026-05-01',
  '10',
  'synthetic-staging-fixture-v1',
  'synthetic-staging-v1-national-2026-05-01-10',
  '{"fixture":true,"fixtureVersion":1,"providerResultId":"synthetic-staging-v1-national-base-01","drawId":"6966a6d1ea7015c3b8a3d47c","drawDate":"2026-05-01","firstNumber":"10"}',
  '2026-05-01T20:00:00.000Z',
  '2026-05-01T20:00:00.000Z',
  '2026-05-01T21:00:00.000Z',
  '2026-05-01T21:00:00.000Z'
WHERE NOT EXISTS (
  SELECT 1 FROM first_prize_results
  WHERE provider_result_id = 'synthetic-staging-v1-national-base-01'
     OR (draw_id = '6966a6d1ea7015c3b8a3d47c' AND draw_date = '2026-05-01')
);

INSERT INTO first_prize_results (
  provider_result_id, operator_id, draw_id, draw_date, first_number,
  source, checksum, raw_payload, provider_created_at, provider_updated_at,
  collected_at, updated_at
)
SELECT
  'synthetic-staging-v1-national-base-02',
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d47c',
  '2026-05-02',
  '20',
  'synthetic-staging-fixture-v1',
  'synthetic-staging-v1-national-2026-05-02-20',
  '{"fixture":true,"fixtureVersion":1,"providerResultId":"synthetic-staging-v1-national-base-02","drawId":"6966a6d1ea7015c3b8a3d47c","drawDate":"2026-05-02","firstNumber":"20"}',
  '2026-05-02T20:00:00.000Z',
  '2026-05-02T20:00:00.000Z',
  '2026-05-02T21:00:00.000Z',
  '2026-05-02T21:00:00.000Z'
WHERE NOT EXISTS (
  SELECT 1 FROM first_prize_results
  WHERE provider_result_id = 'synthetic-staging-v1-national-base-02'
     OR (draw_id = '6966a6d1ea7015c3b8a3d47c' AND draw_date = '2026-05-02')
);

INSERT INTO first_prize_results (
  provider_result_id, operator_id, draw_id, draw_date, first_number,
  source, checksum, raw_payload, provider_created_at, provider_updated_at,
  collected_at, updated_at
)
SELECT
  'synthetic-staging-v1-national-base-03',
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d47c',
  '2026-05-04',
  '10',
  'synthetic-staging-fixture-v1',
  'synthetic-staging-v1-national-2026-05-04-10',
  '{"fixture":true,"fixtureVersion":1,"providerResultId":"synthetic-staging-v1-national-base-03","drawId":"6966a6d1ea7015c3b8a3d47c","drawDate":"2026-05-04","firstNumber":"10"}',
  '2026-05-04T20:00:00.000Z',
  '2026-05-04T20:00:00.000Z',
  '2026-05-04T21:00:00.000Z',
  '2026-05-04T21:00:00.000Z'
WHERE NOT EXISTS (
  SELECT 1 FROM first_prize_results
  WHERE provider_result_id = 'synthetic-staging-v1-national-base-03'
     OR (draw_id = '6966a6d1ea7015c3b8a3d47c' AND draw_date = '2026-05-04')
);

INSERT INTO first_prize_results (
  provider_result_id, operator_id, draw_id, draw_date, first_number,
  source, checksum, raw_payload, provider_created_at, provider_updated_at,
  collected_at, updated_at
)
SELECT
  'synthetic-staging-v1-national-base-04',
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d47c',
  '2026-05-05',
  '30',
  'synthetic-staging-fixture-v1',
  'synthetic-staging-v1-national-2026-05-05-30',
  '{"fixture":true,"fixtureVersion":1,"providerResultId":"synthetic-staging-v1-national-base-04","drawId":"6966a6d1ea7015c3b8a3d47c","drawDate":"2026-05-05","firstNumber":"30"}',
  '2026-05-05T20:00:00.000Z',
  '2026-05-05T20:00:00.000Z',
  '2026-05-05T21:00:00.000Z',
  '2026-05-05T21:00:00.000Z'
WHERE NOT EXISTS (
  SELECT 1 FROM first_prize_results
  WHERE provider_result_id = 'synthetic-staging-v1-national-base-04'
     OR (draw_id = '6966a6d1ea7015c3b8a3d47c' AND draw_date = '2026-05-05')
);

INSERT INTO first_prize_results (
  provider_result_id, operator_id, draw_id, draw_date, first_number,
  source, checksum, raw_payload, provider_created_at, provider_updated_at,
  collected_at, updated_at
)
SELECT
  'synthetic-staging-v1-national-base-05',
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d47c',
  '2026-05-07',
  '10',
  'synthetic-staging-fixture-v1',
  'synthetic-staging-v1-national-2026-05-07-10',
  '{"fixture":true,"fixtureVersion":1,"providerResultId":"synthetic-staging-v1-national-base-05","drawId":"6966a6d1ea7015c3b8a3d47c","drawDate":"2026-05-07","firstNumber":"10"}',
  '2026-05-07T20:00:00.000Z',
  '2026-05-07T20:00:00.000Z',
  '2026-05-07T21:00:00.000Z',
  '2026-05-07T21:00:00.000Z'
WHERE NOT EXISTS (
  SELECT 1 FROM first_prize_results
  WHERE provider_result_id = 'synthetic-staging-v1-national-base-05'
     OR (draw_id = '6966a6d1ea7015c3b8a3d47c' AND draw_date = '2026-05-07')
);

INSERT INTO first_prize_results (
  provider_result_id, operator_id, draw_id, draw_date, first_number,
  source, checksum, raw_payload, provider_created_at, provider_updated_at,
  collected_at, updated_at
)
SELECT
  'synthetic-staging-v1-national-base-06',
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d47c',
  '2026-05-08',
  '20',
  'synthetic-staging-fixture-v1',
  'synthetic-staging-v1-national-2026-05-08-20',
  '{"fixture":true,"fixtureVersion":1,"providerResultId":"synthetic-staging-v1-national-base-06","drawId":"6966a6d1ea7015c3b8a3d47c","drawDate":"2026-05-08","firstNumber":"20"}',
  '2026-05-08T20:00:00.000Z',
  '2026-05-08T20:00:00.000Z',
  '2026-05-08T21:00:00.000Z',
  '2026-05-08T21:00:00.000Z'
WHERE NOT EXISTS (
  SELECT 1 FROM first_prize_results
  WHERE provider_result_id = 'synthetic-staging-v1-national-base-06'
     OR (draw_id = '6966a6d1ea7015c3b8a3d47c' AND draw_date = '2026-05-08')
);

INSERT INTO coverage (
  operator_id, draw_id, coverage_date, status, source,
  verification_source, detail, attempt_count, last_error,
  checked_at, next_retry_at
)
SELECT
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d482',
  '2026-04-01',
  'RESULT_FOUND',
  'synthetic-staging-fixture-v1',
  NULL,
  NULL,
  1,
  NULL,
  '2026-04-01T22:00:00.000Z',
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM coverage
  WHERE draw_id = '6966a6d1ea7015c3b8a3d482'
    AND coverage_date = '2026-04-01'
);

INSERT INTO coverage (
  operator_id, draw_id, coverage_date, status, source,
  verification_source, detail, attempt_count, last_error,
  checked_at, next_retry_at
)
SELECT
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d482',
  '2026-04-02',
  'RESULT_FOUND',
  'synthetic-staging-fixture-v1',
  NULL,
  NULL,
  1,
  NULL,
  '2026-04-02T22:00:00.000Z',
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM coverage
  WHERE draw_id = '6966a6d1ea7015c3b8a3d482'
    AND coverage_date = '2026-04-02'
);

INSERT INTO coverage (
  operator_id, draw_id, coverage_date, status, source,
  verification_source, detail, attempt_count, last_error,
  checked_at, next_retry_at
)
SELECT
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d482',
  '2026-04-03',
  'RESULT_FOUND',
  'synthetic-staging-fixture-v1',
  NULL,
  NULL,
  1,
  NULL,
  '2026-04-03T22:00:00.000Z',
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM coverage
  WHERE draw_id = '6966a6d1ea7015c3b8a3d482'
    AND coverage_date = '2026-04-03'
);

INSERT INTO coverage (
  operator_id, draw_id, coverage_date, status, source,
  verification_source, detail, attempt_count, last_error,
  checked_at, next_retry_at
)
SELECT
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d482',
  '2026-04-04',
  'RESULT_FOUND',
  'synthetic-staging-fixture-v1',
  NULL,
  NULL,
  1,
  NULL,
  '2026-04-04T22:00:00.000Z',
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM coverage
  WHERE draw_id = '6966a6d1ea7015c3b8a3d482'
    AND coverage_date = '2026-04-04'
);

INSERT INTO coverage (
  operator_id, draw_id, coverage_date, status, source,
  verification_source, detail, attempt_count, last_error,
  checked_at, next_retry_at
)
SELECT
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d482',
  '2026-04-05',
  'NO_DRAW_SCHEDULED',
  'synthetic-staging-fixture-v1',
  'synthetic-official-calendar-v1',
  'Synthetic verified no-draw date.',
  1,
  NULL,
  '2026-04-05T22:00:00.000Z',
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM coverage
  WHERE draw_id = '6966a6d1ea7015c3b8a3d482'
    AND coverage_date = '2026-04-05'
);

INSERT INTO coverage (
  operator_id, draw_id, coverage_date, status, source,
  verification_source, detail, attempt_count, last_error,
  checked_at, next_retry_at
)
SELECT
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d482',
  '2026-04-06',
  'RESULT_FOUND',
  'synthetic-staging-fixture-v1',
  NULL,
  NULL,
  1,
  NULL,
  '2026-04-06T22:00:00.000Z',
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM coverage
  WHERE draw_id = '6966a6d1ea7015c3b8a3d482'
    AND coverage_date = '2026-04-06'
);

INSERT INTO coverage (
  operator_id, draw_id, coverage_date, status, source,
  verification_source, detail, attempt_count, last_error,
  checked_at, next_retry_at
)
SELECT
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d482',
  '2026-04-07',
  'RESULT_FOUND',
  'synthetic-staging-fixture-v1',
  NULL,
  NULL,
  1,
  NULL,
  '2026-04-07T22:00:00.000Z',
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM coverage
  WHERE draw_id = '6966a6d1ea7015c3b8a3d482'
    AND coverage_date = '2026-04-07'
);

INSERT INTO coverage (
  operator_id, draw_id, coverage_date, status, source,
  verification_source, detail, attempt_count, last_error,
  checked_at, next_retry_at
)
SELECT
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d482',
  '2026-04-08',
  'RESULT_FOUND',
  'synthetic-staging-fixture-v1',
  NULL,
  NULL,
  1,
  NULL,
  '2026-04-08T22:00:00.000Z',
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM coverage
  WHERE draw_id = '6966a6d1ea7015c3b8a3d482'
    AND coverage_date = '2026-04-08'
);

INSERT INTO coverage (
  operator_id, draw_id, coverage_date, status, source,
  verification_source, detail, attempt_count, last_error,
  checked_at, next_retry_at
)
SELECT
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d482',
  '2026-04-09',
  'RESULT_FOUND',
  'synthetic-staging-fixture-v1',
  NULL,
  NULL,
  1,
  NULL,
  '2026-04-09T22:00:00.000Z',
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM coverage
  WHERE draw_id = '6966a6d1ea7015c3b8a3d482'
    AND coverage_date = '2026-04-09'
);

INSERT INTO coverage (
  operator_id, draw_id, coverage_date, status, source,
  verification_source, detail, attempt_count, last_error,
  checked_at, next_retry_at
)
SELECT
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d482',
  '2026-04-10',
  'RESULT_FOUND',
  'synthetic-staging-fixture-v1',
  NULL,
  NULL,
  1,
  NULL,
  '2026-04-10T22:00:00.000Z',
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM coverage
  WHERE draw_id = '6966a6d1ea7015c3b8a3d482'
    AND coverage_date = '2026-04-10'
);

INSERT INTO coverage (
  operator_id, draw_id, coverage_date, status, source,
  verification_source, detail, attempt_count, last_error,
  checked_at, next_retry_at
)
SELECT
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d482',
  '2026-04-11',
  'RESULT_FOUND',
  'synthetic-staging-fixture-v1',
  NULL,
  NULL,
  1,
  NULL,
  '2026-04-11T22:00:00.000Z',
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM coverage
  WHERE draw_id = '6966a6d1ea7015c3b8a3d482'
    AND coverage_date = '2026-04-11'
);

INSERT INTO coverage (
  operator_id, draw_id, coverage_date, status, source,
  verification_source, detail, attempt_count, last_error,
  checked_at, next_retry_at
)
SELECT
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d47c',
  '2026-05-01',
  'RESULT_FOUND',
  'synthetic-staging-fixture-v1',
  NULL,
  NULL,
  1,
  NULL,
  '2026-05-01T22:00:00.000Z',
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM coverage
  WHERE draw_id = '6966a6d1ea7015c3b8a3d47c'
    AND coverage_date = '2026-05-01'
);

INSERT INTO coverage (
  operator_id, draw_id, coverage_date, status, source,
  verification_source, detail, attempt_count, last_error,
  checked_at, next_retry_at
)
SELECT
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d47c',
  '2026-05-02',
  'RESULT_FOUND',
  'synthetic-staging-fixture-v1',
  NULL,
  NULL,
  1,
  NULL,
  '2026-05-02T22:00:00.000Z',
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM coverage
  WHERE draw_id = '6966a6d1ea7015c3b8a3d47c'
    AND coverage_date = '2026-05-02'
);

INSERT INTO coverage (
  operator_id, draw_id, coverage_date, status, source,
  verification_source, detail, attempt_count, last_error,
  checked_at, next_retry_at
)
SELECT
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d47c',
  '2026-05-03',
  'NO_RESULTS_RETURNED',
  'synthetic-staging-fixture-v1',
  NULL,
  'Synthetic incomplete provider response.',
  1,
  NULL,
  '2026-05-03T22:00:00.000Z',
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM coverage
  WHERE draw_id = '6966a6d1ea7015c3b8a3d47c'
    AND coverage_date = '2026-05-03'
);

INSERT INTO coverage (
  operator_id, draw_id, coverage_date, status, source,
  verification_source, detail, attempt_count, last_error,
  checked_at, next_retry_at
)
SELECT
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d47c',
  '2026-05-04',
  'RESULT_FOUND',
  'synthetic-staging-fixture-v1',
  NULL,
  NULL,
  1,
  NULL,
  '2026-05-04T22:00:00.000Z',
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM coverage
  WHERE draw_id = '6966a6d1ea7015c3b8a3d47c'
    AND coverage_date = '2026-05-04'
);

INSERT INTO coverage (
  operator_id, draw_id, coverage_date, status, source,
  verification_source, detail, attempt_count, last_error,
  checked_at, next_retry_at
)
SELECT
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d47c',
  '2026-05-05',
  'RESULT_FOUND',
  'synthetic-staging-fixture-v1',
  NULL,
  NULL,
  1,
  NULL,
  '2026-05-05T22:00:00.000Z',
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM coverage
  WHERE draw_id = '6966a6d1ea7015c3b8a3d47c'
    AND coverage_date = '2026-05-05'
);

INSERT INTO coverage (
  operator_id, draw_id, coverage_date, status, source,
  verification_source, detail, attempt_count, last_error,
  checked_at, next_retry_at
)
SELECT
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d47c',
  '2026-05-06',
  'UNVERIFIED',
  'synthetic-staging-fixture-v1',
  NULL,
  'Synthetic unknown coverage state.',
  1,
  NULL,
  '2026-05-06T22:00:00.000Z',
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM coverage
  WHERE draw_id = '6966a6d1ea7015c3b8a3d47c'
    AND coverage_date = '2026-05-06'
);

INSERT INTO coverage (
  operator_id, draw_id, coverage_date, status, source,
  verification_source, detail, attempt_count, last_error,
  checked_at, next_retry_at
)
SELECT
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d47c',
  '2026-05-07',
  'RESULT_FOUND',
  'synthetic-staging-fixture-v1',
  NULL,
  NULL,
  1,
  NULL,
  '2026-05-07T22:00:00.000Z',
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM coverage
  WHERE draw_id = '6966a6d1ea7015c3b8a3d47c'
    AND coverage_date = '2026-05-07'
);

INSERT INTO coverage (
  operator_id, draw_id, coverage_date, status, source,
  verification_source, detail, attempt_count, last_error,
  checked_at, next_retry_at
)
SELECT
  '6966a6d1ea7015c3b8a3d477',
  '6966a6d1ea7015c3b8a3d47c',
  '2026-05-08',
  'RESULT_FOUND',
  'synthetic-staging-fixture-v1',
  NULL,
  NULL,
  1,
  NULL,
  '2026-05-08T22:00:00.000Z',
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM coverage
  WHERE draw_id = '6966a6d1ea7015c3b8a3d47c'
    AND coverage_date = '2026-05-08'
);

INSERT INTO result_revisions (
  result_id, provider_result_id, old_first_number, new_first_number,
  old_checksum, new_checksum, old_raw_payload, new_raw_payload, detected_at
)
SELECT
  r.id,
  'synthetic-staging-v1-gm-base-04',
  '31',
  '32',
  'synthetic-staging-v1-pre-correction-31',
  'synthetic-staging-v1-corrected-32',
  '{"fixture":true,"firstNumber":"31","corrected":false}',
  '{"fixture":true,"fixtureVersion":1,"providerResultId":"synthetic-staging-v1-gm-base-04","drawId":"6966a6d1ea7015c3b8a3d482","drawDate":"2026-04-04","firstNumber":"32"}',
  '2026-04-04T22:30:00.000Z'
FROM first_prize_results r
WHERE r.provider_result_id = 'synthetic-staging-v1-gm-base-04'
  AND r.draw_id = '6966a6d1ea7015c3b8a3d482'
  AND r.draw_date = '2026-04-04'
  AND r.first_number = '32'
  AND r.source = 'synthetic-staging-fixture-v1'
  AND r.checksum = 'synthetic-staging-v1-corrected-32'
  AND r.raw_payload = '{"fixture":true,"fixtureVersion":1,"providerResultId":"synthetic-staging-v1-gm-base-04","drawId":"6966a6d1ea7015c3b8a3d482","drawDate":"2026-04-04","firstNumber":"32"}'
  AND NOT EXISTS (
    SELECT 1 FROM result_revisions rr
    WHERE rr.provider_result_id = 'synthetic-staging-v1-gm-base-04'
      AND rr.detected_at = '2026-04-04T22:30:00.000Z'
  );
