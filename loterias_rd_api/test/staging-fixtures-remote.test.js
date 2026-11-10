import assert from 'node:assert/strict';
import test from 'node:test';

import { createBaseFixture, createPerformanceFixture } from '../scripts/staging-fixtures.js';
import {
  buildReadOnlyInspectionCommands,
  evaluateRemoteInspection,
  parseRemoteArguments,
  REMOTE_FIXTURE_TARGET,
  runRemoteDryRun,
  validateRemoteStagingConfig,
} from '../scripts/load-staging-fixtures-remote.js';

function schemaRows() {
  const tables = [
    '_cf_KV', '_cf_METADATA', 'backfill_state', 'coverage', 'd1_migrations',
    'draws', 'first_prize_results', 'operators', 'result_revisions', 'sqlite_sequence',
  ];
  const indexes = [
    'idx_coverage_draw_date', 'idx_coverage_status', 'idx_draws_operator',
    'idx_first_prize_draw_date', 'idx_first_prize_number_date', 'idx_revisions_result',
  ];
  return [
    ...indexes.map((name) => ({ type: 'index', name, tbl_name: null })),
    ...tables.map((name) => ({ type: 'table', name, tbl_name: name })),
  ];
}

function identities() {
  return [
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
}

function emptyInspection(overrides = {}) {
  return {
    identity: { accounts: [{ id: REMOTE_FIXTURE_TARGET.accountId }] },
    databases: [{ uuid: REMOTE_FIXTURE_TARGET.databaseId, name: REMOTE_FIXTURE_TARGET.databaseName }],
    migrations: [{ name: '0001_gana_mas_history.sql' }, { name: '0002_national_history.sql' }],
    schema: schemaRows(),
    identities: identities(),
    results: [],
    coverage: [],
    revisions: [],
    backfill: [],
    foreignKeys: [],
    ...overrides,
  };
}

function config(overrides = {}) {
  return {
    name: REMOTE_FIXTURE_TARGET.workerName,
    account_id: REMOTE_FIXTURE_TARGET.accountId,
    workers_dev: false,
    preview_urls: false,
    vars: { ENVIRONMENT: 'staging' },
    d1_databases: [{
      binding: REMOTE_FIXTURE_TARGET.binding,
      database_name: REMOTE_FIXTURE_TARGET.databaseName,
      database_id: REMOTE_FIXTURE_TARGET.databaseId,
      migrations_dir: 'migrations',
    }],
    ...overrides,
  };
}

test('default and explicit dry run are read-only while apply is disabled', () => {
  assert.deepEqual(parseRemoteArguments([]), { mode: 'DRY_RUN' });
  assert.deepEqual(parseRemoteArguments(['--dry-run']), { mode: 'DRY_RUN' });
  assert.throws(() => parseRemoteArguments(['--apply']), /disabled/);
  assert.throws(() => parseRemoteArguments(['--database', 'api']), /Unsupported/);

  const commands = buildReadOnlyInspectionCommands('/absolute/wrangler.staging.toml');
  assert.equal(commands.every((item) => item.readOnly), true);
  assert.equal(commands.some((item) => item.args.includes('deploy')), false);
  assert.equal(commands.some((item) => item.sql && !/^\s*(SELECT|PRAGMA)\b/i.test(item.sql)), false);
  assert.equal(commands.some((item) => /\b(INSERT|UPDATE|DELETE|REPLACE|DROP|TRUNCATE)\b/i.test(item.sql || '')), false);
});

test('default executable path performs only mocked read inspections and no writes', async () => {
  const inspection = emptyInspection();
  const invoked = [];
  const report = await runRemoteDryRun({
    argv: [],
    runner: async (command) => {
      invoked.push(command);
      return inspection[command.id];
    },
  });
  assert.equal(report.state, 'EMPTY');
  assert.equal(report.writesExecuted, false);
  assert.equal(invoked.length, 10);
  assert.equal(invoked.every((command) => command.readOnly), true);
});

test('validates exact staging configuration and rejects production-like targets', () => {
  assert.doesNotThrow(() => validateRemoteStagingConfig(config()));
  assert.throws(() => validateRemoteStagingConfig(config({ account_id: 'wrong' })), /does not match/);
  assert.throws(() => validateRemoteStagingConfig(config({ name: 'api' })), /does not match/);
  assert.throws(() => validateRemoteStagingConfig(config({
    d1_databases: [{ ...config().d1_databases[0], database_id: 'wrong' }],
  })), /does not match/);
  assert.throws(() => validateRemoteStagingConfig(config({
    d1_databases: [{ ...config().d1_databases[0], database_name: 'production' }],
  })), /does not match/);
});

test('empty staging produces a base-only dry-run insertion plan without writes', () => {
  const report = evaluateRemoteInspection(emptyInspection());
  assert.equal(report.mode, 'DRY_RUN');
  assert.equal(report.state, 'EMPTY');
  assert.equal(report.writesExecuted, false);
  assert.equal(report.applyEnabled, false);
  assert.equal(report.fixture.results.missing, 16);
  assert.equal(report.fixture.coverage.missing, 19);
  assert.equal(report.fixture.revisions.missing, 1);
  assert.equal(report.fixture.performanceFixtureIncluded, false);
  assert.equal(report.expectedAnalysis.totalTransitions, 5);
});

test('rejects wrong account, D1 UUID and D1 name', () => {
  assert.throws(() => evaluateRemoteInspection(emptyInspection({
    identity: { accounts: [{ id: 'wrong' }] },
  })), /account/);
  assert.throws(() => evaluateRemoteInspection(emptyInspection({
    databases: [{ uuid: 'wrong', name: REMOTE_FIXTURE_TARGET.databaseName }],
  })), /name or UUID/);
  assert.throws(() => evaluateRemoteInspection(emptyInspection({
    databases: [{ uuid: REMOTE_FIXTURE_TARGET.databaseId, name: 'wrong' }],
  })), /name or UUID/);
});

test('pending or unexpected migration blocks the plan', () => {
  assert.throws(() => evaluateRemoteInspection(emptyInspection({
    migrations: [{ name: '0001_gana_mas_history.sql' }],
  })), /migrations are pending/);
  assert.throws(() => evaluateRemoteInspection(emptyInspection({
    migrations: [
      { name: '0001_gana_mas_history.sql' },
      { name: '0002_national_history.sql' },
      { name: '0003_unreviewed.sql' },
    ],
  })), /migrations are pending/);
});

test('unexpected schema, identities, backfill or integrity errors block', () => {
  assert.throws(() => evaluateRemoteInspection(emptyInspection({
    schema: [...schemaRows(), { type: 'table', name: 'foreign_data', tbl_name: 'foreign_data' }],
  })), /schema/);
  assert.throws(() => evaluateRemoteInspection(emptyInspection({
    schema: [...schemaRows(), { type: 'index', name: 'foreign_index', tbl_name: 'draws' }],
  })), /schema/);
  assert.throws(() => evaluateRemoteInspection(emptyInspection({ identities: [] })), /identities/);
  assert.throws(() => evaluateRemoteInspection(emptyInspection({ backfill: [{ draw_id: 'x' }] })), /backfill/);
  assert.throws(() => evaluateRemoteInspection(emptyInspection({ foreignKeys: [{ table: 'x' }] })), /foreign-key/);
});

test('foreign fixture collision blocks without treating it as an idempotent row', () => {
  const fixture = createBaseFixture();
  const row = fixture.results[0];
  assert.throws(() => evaluateRemoteInspection(emptyInspection({
    results: [{
      provider_result_id: row.providerResultId,
      operator_id: row.operatorId,
      draw_id: row.drawId,
      draw_date: row.drawDate,
      first_number: '99',
      source: 'foreign',
      checksum: 'foreign',
      raw_payload: '{}',
      provider_created_at: null,
      provider_updated_at: null,
      collected_at: row.collectedAt,
      updated_at: row.updatedAt,
    }],
  })), /conflicting fixture result/);
});

test('partial fixture state is blocked and not reported as success', () => {
  const row = createBaseFixture().results[0];
  assert.throws(() => evaluateRemoteInspection(emptyInspection({
    results: [{
      provider_result_id: row.providerResultId,
      operator_id: row.operatorId,
      draw_id: row.drawId,
      draw_date: row.drawDate,
      first_number: row.firstNumber,
      source: row.source,
      checksum: row.checksum,
      raw_payload: row.rawPayload,
      provider_created_at: row.providerCreatedAt,
      provider_updated_at: row.providerUpdatedAt,
      collected_at: row.collectedAt,
      updated_at: row.updatedAt,
    }],
  })), /partial fixture load/);
});

test('complete matching fixture is recognized as idempotently applied', () => {
  const fixture = createBaseFixture();
  const report = evaluateRemoteInspection(emptyInspection({
    results: fixture.results.map((item) => ({
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
    })),
    coverage: fixture.coverage.map((item) => ({
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
    })),
    revisions: fixture.revisions.map((item) => ({
      provider_result_id: item.providerResultId,
      old_first_number: item.oldFirstNumber,
      new_first_number: item.newFirstNumber,
      old_checksum: item.oldChecksum,
      new_checksum: item.newChecksum,
      old_raw_payload: item.oldRawPayload,
      new_raw_payload: item.newRawPayload,
      detected_at: item.detectedAt,
    })),
  }));
  assert.equal(report.state, 'ALREADY_APPLIED');
  assert.equal(report.fixture.results.missing, 0);
  assert.equal(report.writesExecuted, false);
});

test('performance fixture is never accepted by the remote planner', () => {
  assert.throws(() => evaluateRemoteInspection(emptyInspection(), createPerformanceFixture()), /base fixture/);
});
