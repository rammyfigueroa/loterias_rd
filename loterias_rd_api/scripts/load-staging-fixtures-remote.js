#!/usr/bin/env node

import { execFile } from 'node:child_process';
import { readdir } from 'node:fs/promises';
import { promisify } from 'node:util';

import { unstable_readConfig } from 'wrangler';

import { createBaseFixture, FIXTURE_PREFIX } from './staging-fixtures.js';

const execFileAsync = promisify(execFile);

export const REMOTE_FIXTURE_TARGET = Object.freeze({
  accountId: 'f171b568e3a3a203a09ef2fd6e337a2c',
  workerName: 'sorteosdominicanos-api-staging',
  databaseName: 'sorteosdominicanos-db-staging',
  databaseId: 'f31aac48-f437-4fd7-9691-a7e976010dc6',
  binding: 'HISTORY_DB',
  configName: 'wrangler.staging.toml',
});

const EXPECTED_MIGRATIONS = [
  '0001_gana_mas_history.sql',
  '0002_national_history.sql',
];

const EXPECTED_FUNCTIONAL_TABLES = [
  'backfill_state',
  'coverage',
  'draws',
  'first_prize_results',
  'operators',
  'result_revisions',
];

const EXPECTED_EXPLICIT_INDEXES = [
  'idx_coverage_draw_date',
  'idx_coverage_status',
  'idx_draws_operator',
  'idx_first_prize_draw_date',
  'idx_first_prize_number_date',
  'idx_revisions_result',
];

const READ_ONLY_SQL = Object.freeze({
  schema: `
    SELECT type, name, tbl_name
    FROM sqlite_master
    WHERE type IN ('table', 'index')
    ORDER BY type, name
  `,
  migrations: 'SELECT id, name, applied_at FROM d1_migrations ORDER BY id',
  identities: `
    SELECT 'operator' AS kind, id, name, NULL AS operator_id,
           NULL AS first_position_path, NULL AS enabled
    FROM operators
    UNION ALL
    SELECT 'draw' AS kind, id, name, operator_id, first_position_path, enabled
    FROM draws
    ORDER BY kind, id
  `,
  results: `
    SELECT provider_result_id, operator_id, draw_id, draw_date, first_number,
           source, checksum, raw_payload, provider_created_at,
           provider_updated_at, collected_at, updated_at
    FROM first_prize_results
    ORDER BY draw_id, draw_date, provider_result_id
  `,
  coverage: `
    SELECT operator_id, draw_id, coverage_date, status, source,
           verification_source, detail, attempt_count, last_error,
           checked_at, next_retry_at
    FROM coverage
    ORDER BY draw_id, coverage_date
  `,
  revisions: `
    SELECT rr.provider_result_id, rr.old_first_number, rr.new_first_number,
           rr.old_checksum, rr.new_checksum, rr.old_raw_payload,
           rr.new_raw_payload, rr.detected_at
    FROM result_revisions rr
    JOIN first_prize_results r ON r.id = rr.result_id
    ORDER BY rr.provider_result_id, rr.detected_at
  `,
  backfill: 'SELECT draw_id, status FROM backfill_state ORDER BY draw_id',
  foreignKeys: 'PRAGMA foreign_key_check',
});

export function parseRemoteArguments(argv) {
  if (argv.includes('--apply') || argv.includes('--write') || argv.includes('--yes')) {
    throw new Error('Remote fixture application is disabled in Phase 8.5B-7A.');
  }
  const allowed = new Set(['--dry-run']);
  for (const argument of argv) {
    if (!allowed.has(argument)) throw new Error(`Unsupported remote fixture argument: ${argument}.`);
  }
  return { mode: 'DRY_RUN' };
}

export function validateRemoteStagingConfig(config) {
  const databases = config.d1_databases || [];
  const database = databases.find((item) => item.binding === REMOTE_FIXTURE_TARGET.binding);
  if (config.name !== REMOTE_FIXTURE_TARGET.workerName ||
      config.account_id !== REMOTE_FIXTURE_TARGET.accountId ||
      config.vars?.ENVIRONMENT !== 'staging' ||
      config.workers_dev !== false || config.preview_urls !== false ||
      config.routes || config.route || databases.length !== 1 ||
      !database || database.database_name !== REMOTE_FIXTURE_TARGET.databaseName ||
      database.database_id !== REMOTE_FIXTURE_TARGET.databaseId ||
      database.migrations_dir !== 'migrations') {
    throw new Error('The explicit staging configuration does not match the authorized remote target.');
  }
  return database;
}

export function buildReadOnlyInspectionCommands(configPath) {
  const base = ['--config', configPath];
  const commands = [
    {
      id: 'identity',
      args: ['whoami', '--json', ...base],
      readOnly: true,
    },
    {
      id: 'databases',
      args: ['d1', 'list', '--json', ...base],
      readOnly: true,
    },
  ];
  for (const [id, sql] of Object.entries(READ_ONLY_SQL)) {
    if (!/^\s*(SELECT|PRAGMA)\b/i.test(sql)) {
      throw new Error(`Non-read-only SQL detected in inspection ${id}.`);
    }
    commands.push({
      id,
      args: [
        'd1', 'execute', REMOTE_FIXTURE_TARGET.databaseName,
        '--remote', '--json', '--command', sql, ...base,
      ],
      sql,
      readOnly: true,
    });
  }
  return commands;
}

function parseJsonOutput(output, commandId) {
  try {
    return JSON.parse(output);
  } catch {
    throw new Error(`Wrangler returned non-JSON output for ${commandId}.`);
  }
}

function resultRows(value) {
  if (Array.isArray(value)) {
    if (value.every((item) => item && Array.isArray(item.results))) {
      return value.flatMap((item) => item.results);
    }
    return value;
  }
  if (value && Array.isArray(value.results)) return value.results;
  if (value && Array.isArray(value.result)) return value.result.flatMap(resultRows);
  return [];
}

function recursiveAccountIds(value, output = new Set()) {
  if (Array.isArray(value)) {
    value.forEach((item) => recursiveAccountIds(item, output));
  } else if (value && typeof value === 'object') {
    for (const [key, item] of Object.entries(value)) {
      if ((key === 'id' || key === 'account_id') && typeof item === 'string') output.add(item);
      recursiveAccountIds(item, output);
    }
  }
  return output;
}

function normalizeResult(item) {
  return {
    provider_result_id: item.providerResultId,
    operator_id: item.operatorId,
    draw_id: item.drawId,
    draw_date: item.drawDate,
    first_number: item.firstNumber,
    source: item.source,
    checksum: item.checksum,
    raw_payload: item.rawPayload,
    provider_created_at: item.providerCreatedAt,
    provider_updated_at: item.providerUpdatedAt,
    collected_at: item.collectedAt,
    updated_at: item.updatedAt,
  };
}

function normalizeCoverage(item) {
  return {
    operator_id: item.operatorId,
    draw_id: item.drawId,
    coverage_date: item.coverageDate,
    status: item.status,
    source: item.source,
    verification_source: item.verificationSource,
    detail: item.detail,
    attempt_count: item.attemptCount,
    last_error: item.lastError,
    checked_at: item.checkedAt,
    next_retry_at: item.nextRetryAt,
  };
}

function normalizeRevision(item) {
  return {
    provider_result_id: item.providerResultId,
    old_first_number: item.oldFirstNumber,
    new_first_number: item.newFirstNumber,
    old_checksum: item.oldChecksum,
    new_checksum: item.newChecksum,
    old_raw_payload: item.oldRawPayload,
    new_raw_payload: item.newRawPayload,
    detected_at: item.detectedAt,
  };
}

function canonical(value) {
  return JSON.stringify(Object.fromEntries(Object.entries(value).sort(([a], [b]) => a.localeCompare(b))));
}

function compareOwnedRows(actual, expected, key, label) {
  const expectedByKey = new Map(expected.map((item) => [key(item), item]));
  const actualByKey = new Map();
  for (const item of actual) {
    const identity = key(item);
    if (actualByKey.has(identity)) throw new Error(`Duplicate ${label} identity: ${identity}.`);
    actualByKey.set(identity, item);
  }
  for (const [identity, item] of actualByKey) {
    const expectedItem = expectedByKey.get(identity);
    if (!expectedItem || canonical(item) !== canonical(expectedItem)) {
      throw new Error(`Unexpected or conflicting ${label}: ${identity}.`);
    }
  }
  return {
    existing: actual.length,
    expected: expected.length,
    missing: expected.length - actual.length,
  };
}

function assertIdentityRows(rows) {
  const expected = [
    {
      kind: 'draw', id: '6966a6d1ea7015c3b8a3d47c', name: 'Lotería Nacional',
      operator_id: '6966a6d1ea7015c3b8a3d477', first_position_path: 'score[0][0]', enabled: 1,
    },
    {
      kind: 'draw', id: '6966a6d1ea7015c3b8a3d482', name: 'Gana Más',
      operator_id: '6966a6d1ea7015c3b8a3d477', first_position_path: 'score[0][0]', enabled: 1,
    },
    {
      kind: 'operator', id: '6966a6d1ea7015c3b8a3d477', name: 'Nacional',
      operator_id: null, first_position_path: null, enabled: null,
    },
  ];
  if (canonical(rows) !== canonical(expected)) {
    throw new Error('Remote operator/draw identities do not match the audited staging schema.');
  }
}

export function evaluateRemoteInspection(inspection, fixture = createBaseFixture()) {
  if (fixture.name !== 'base' || fixture.results.length !== 16 ||
      fixture.coverage.length !== 19 || fixture.revisions.length !== 1 ||
      fixture.results.some((item) => item.providerResultId.includes('performance'))) {
    throw new Error('Only the validated base fixture is allowed in the remote plan.');
  }

  const accountIds = recursiveAccountIds(inspection.identity);
  if (!accountIds.has(REMOTE_FIXTURE_TARGET.accountId)) {
    throw new Error('The authenticated Cloudflare account does not include the authorized account ID.');
  }
  const databases = resultRows(inspection.databases);
  const database = databases.find((item) =>
    (item.uuid || item.id) === REMOTE_FIXTURE_TARGET.databaseId);
  if (!database || database.name !== REMOTE_FIXTURE_TARGET.databaseName) {
    throw new Error('The remote D1 name or UUID does not match the authorized target.');
  }

  const migrations = resultRows(inspection.migrations).map((item) => item.name);
  if (canonical(migrations) !== canonical(EXPECTED_MIGRATIONS)) {
    throw new Error('Remote migrations are pending, missing or unexpected.');
  }
  const schema = resultRows(inspection.schema);
  const functionalTables = schema
    .filter((item) => item.type === 'table' && EXPECTED_FUNCTIONAL_TABLES.includes(item.name))
    .map((item) => item.name).sort();
  const unexpectedTables = schema
    .filter((item) => item.type === 'table' &&
      !EXPECTED_FUNCTIONAL_TABLES.includes(item.name) &&
      !['_cf_KV', '_cf_METADATA', 'd1_migrations', 'sqlite_sequence'].includes(item.name))
    .map((item) => item.name);
  const explicitIndexes = schema
    .filter((item) => item.type === 'index' && EXPECTED_EXPLICIT_INDEXES.includes(item.name))
    .map((item) => item.name).sort();
  const unexpectedIndexes = schema
    .filter((item) => item.type === 'index' &&
      !EXPECTED_EXPLICIT_INDEXES.includes(item.name) &&
      !item.name.startsWith('sqlite_autoindex_'))
    .map((item) => item.name);
  if (canonical(functionalTables) !== canonical(EXPECTED_FUNCTIONAL_TABLES) ||
      canonical(explicitIndexes) !== canonical(EXPECTED_EXPLICIT_INDEXES) ||
      unexpectedTables.length > 0 || unexpectedIndexes.length > 0) {
    throw new Error('Remote staging schema contains missing or unexpected objects.');
  }

  assertIdentityRows(resultRows(inspection.identities));
  if (resultRows(inspection.backfill).length !== 0) {
    throw new Error('Remote staging contains unexpected backfill state.');
  }
  if (resultRows(inspection.foreignKeys).length !== 0) {
    throw new Error('Remote staging has foreign-key violations.');
  }

  const results = compareOwnedRows(
    resultRows(inspection.results), fixture.results.map(normalizeResult),
    (item) => item.provider_result_id, 'fixture result',
  );
  const coverage = compareOwnedRows(
    resultRows(inspection.coverage), fixture.coverage.map(normalizeCoverage),
    (item) => `${item.draw_id}|${item.coverage_date}`, 'fixture coverage',
  );
  const revisions = compareOwnedRows(
    resultRows(inspection.revisions), fixture.revisions.map(normalizeRevision),
    (item) => `${item.provider_result_id}|${item.detected_at}`, 'fixture revision',
  );
  const existing = results.existing + coverage.existing + revisions.existing;
  const total = results.expected + coverage.expected + revisions.expected;
  const state = existing === 0 ? 'EMPTY' : existing === total ? 'ALREADY_APPLIED' : 'PARTIAL_BLOCKED';
  if (state === 'PARTIAL_BLOCKED') {
    throw new Error('A partial fixture load was detected and is not considered a successful dry run.');
  }
  return {
    mode: 'DRY_RUN',
    target: REMOTE_FIXTURE_TARGET,
    fixture: {
      name: fixture.name,
      prefix: FIXTURE_PREFIX,
      results,
      coverage,
      revisions,
      performanceFixtureIncluded: false,
    },
    state,
    writesExecuted: false,
    applyEnabled: false,
    expectedAnalysis: fixture.expected.ganaMasOrigin24,
  };
}

export async function collectRemoteInspection({ configPath, runner }) {
  const output = {};
  for (const command of buildReadOnlyInspectionCommands(configPath)) {
    if (!command.readOnly) throw new Error(`Inspection command ${command.id} is not read-only.`);
    output[command.id] = await runner(command);
  }
  return output;
}

export async function runRemoteDryRun({ argv = process.argv.slice(2), runner } = {}) {
  parseRemoteArguments(argv);
  const configPath = new URL('../wrangler.staging.toml', import.meta.url).pathname;
  const config = unstable_readConfig({ config: configPath });
  validateRemoteStagingConfig(config);

  const migrationNames = (await readdir(new URL('../migrations/', import.meta.url)))
    .filter((name) => name.endsWith('.sql')).sort();
  if (canonical(migrationNames) !== canonical(EXPECTED_MIGRATIONS)) {
    throw new Error('Local migrations do not match the two audited staging migrations.');
  }

  const commandRunner = runner || (async (command) => {
    const { stdout } = await execFileAsync('npx', ['--no-install', 'wrangler', ...command.args], {
      cwd: new URL('..', import.meta.url).pathname,
      env: { ...process.env, WRANGLER_SEND_METRICS: 'false' },
      maxBuffer: 10 * 1024 * 1024,
    });
    return parseJsonOutput(stdout, command.id);
  });
  const inspection = await collectRemoteInspection({ configPath, runner: commandRunner });
  return evaluateRemoteInspection(inspection);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  runRemoteDryRun().then((report) => {
    process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
  }).catch((error) => {
    process.stderr.write(`Remote fixture dry run refused: ${error.message}\n`);
    process.exitCode = 1;
  });
}
