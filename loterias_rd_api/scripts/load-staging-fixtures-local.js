#!/usr/bin/env node

import { resolve } from 'node:path';

import { getPlatformProxy, unstable_readConfig } from 'wrangler';

import {
  createBaseFixture,
  createPerformanceFixture,
  ensureLocalSchema,
  loadFixture,
} from './staging-fixtures.js';

const EXPECTED = Object.freeze({
  worker: 'sorteosdominicanos-api-staging',
  accountId: 'f171b568e3a3a203a09ef2fd6e337a2c',
  binding: 'HISTORY_DB',
  database: 'sorteosdominicanos-db-staging',
  databaseId: 'f31aac48-f437-4fd7-9691-a7e976010dc6',
});

export function parseArguments(argv) {
  if (argv.includes('--remote')) throw new Error('Remote fixture loading is not implemented or authorized.');
  if (!argv.includes('--local')) throw new Error('The explicit --local flag is required.');
  const persistIndex = argv.indexOf('--persist-to');
  if (persistIndex < 0 || !argv[persistIndex + 1] || argv[persistIndex + 1].startsWith('--')) {
    throw new Error('--persist-to requires an explicit local directory.');
  }
  const allowed = new Set(['--local', '--persist-to', '--include-performance']);
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === '--persist-to') {
      index += 1;
      continue;
    }
    if (!allowed.has(argument)) throw new Error(`Unsupported fixture argument: ${argument}.`);
  }
  return {
    persistTo: resolve(argv[persistIndex + 1]),
    includePerformance: argv.includes('--include-performance'),
  };
}

export function validateStagingConfig(config) {
  const database = config.d1_databases?.find((item) => item.binding === EXPECTED.binding);
  if (config.name !== EXPECTED.worker || config.account_id !== EXPECTED.accountId ||
      config.vars?.ENVIRONMENT !== 'staging' || config.workers_dev !== false ||
      config.preview_urls !== false || config.routes || config.route ||
      !database || database.database_name !== EXPECTED.database ||
      database.database_id !== EXPECTED.databaseId) {
    throw new Error('wrangler.staging.toml does not match the authorized isolated staging target.');
  }
}

export async function run(argv = process.argv.slice(2)) {
  const options = parseArguments(argv);
  const configPath = new URL('../wrangler.staging.toml', import.meta.url).pathname;
  const config = unstable_readConfig({ config: configPath });
  validateStagingConfig(config);

  process.stdout.write(
    `Target: LOCAL D1 only; binding=${EXPECTED.binding}; database=${EXPECTED.database}; persist=${options.persistTo}\n`,
  );
  const platform = await getPlatformProxy({
    configPath,
    persist: { path: options.persistTo },
    remoteBindings: false,
    envFiles: [],
  });
  try {
    const db = platform.env.HISTORY_DB;
    if (!db) throw new Error('The local HISTORY_DB binding is unavailable.');
    await ensureLocalSchema(db);
    const reports = [await loadFixture(db, createBaseFixture())];
    if (options.includePerformance) {
      reports.push(await loadFixture(db, createPerformanceFixture()));
    }
    process.stdout.write(`${JSON.stringify({ mode: 'local', reports }, null, 2)}\n`);
    return reports;
  } finally {
    await platform.dispose();
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  run().catch((error) => {
    process.stderr.write(`Fixture load refused: ${error.message}\n`);
    process.exitCode = 1;
  });
}
