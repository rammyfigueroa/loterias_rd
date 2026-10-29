import {
  DRAW_ID,
  SANTO_DOMINGO_TIMEZONE,
  UNVERIFIED_DATES,
} from './constants.js';
import {
  checksumForResult,
  fetchGanaMasForDate,
  fetchGanaMasMetadata,
} from './provider.js';
import { HistoryRepository } from './repository.js';
import { currentDateInZone, previousIsoDate } from './validation.js';

export function coverageForMissingDate(date) {
  const detail = UNVERIFIED_DATES.get(date);
  if (detail) return { status: 'UNVERIFIED', detail };
  return { status: 'NO_RESULTS_RETURNED', detail: 'Provider returned no exact session for this date.' };
}

export async function runBackfillBatch(
  env,
  {
    maxRequests = 20,
    fetchOptions = {},
    now = new Date(),
    repository = new HistoryRepository(env.HISTORY_DB),
  } = {},
) {
  const boundedMax = Math.max(1, Math.min(Number(maxRequests) || 20, 50));
  const metadata = await fetchGanaMasMetadata(fetchOptions);
  await repository.ensureMetadata(metadata);

  let state = await repository.getBackfillState();
  if (!state) {
    state = await repository.initializeBackfill({
      nextDate: currentDateInZone(SANTO_DOMINGO_TIMEZONE, now),
      lowerBoundDate: metadata.lowerBoundDate,
    });
  }
  if (state.status === 'COMPLETE') return { state, processed: 0, inserted: 0, revisions: 0 };

  let cursor = state.next_date;
  let processed = 0;
  let inserted = 0;
  let revisions = 0;
  let unchanged = 0;

  while (processed < boundedMax && cursor >= state.lower_bound_date) {
    await repository.recordCoverage({ date: cursor, status: 'PENDING' });
    try {
      const response = await fetchGanaMasForDate(cursor, fetchOptions);
      if (response.result) {
        response.result.checksum = await checksumForResult(response.result);
        const saved = await repository.saveResult(response.result);
        if (saved.kind === 'INSERT') inserted += 1;
        if (saved.kind === 'REVISION') revisions += 1;
        if (saved.kind === 'UNCHANGED') unchanged += 1;
        await repository.recordCoverage({
          date: cursor,
          status: 'RESULT_FOUND',
          attempts: response.attempts,
          detail: `Stored provider result ${response.result.providerResultId}.`,
        });
      } else {
        const missing = coverageForMissingDate(cursor);
        await repository.recordCoverage({
          date: cursor,
          status: missing.status,
          attempts: response.attempts,
          detail: missing.detail,
        });
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      await repository.recordCoverage({
        date: cursor,
        status: 'FETCH_FAILED',
        attempts: 1,
        error: message,
      });
      await repository.updateBackfillState({
        nextDate: cursor,
        status: 'FAILED',
        requestDelta: processed,
        resultDelta: inserted,
        error: message,
      });
      return {
        state: await repository.getBackfillState(),
        processed,
        inserted,
        revisions,
        unchanged,
        error: message,
      };
    }

    processed += 1;
    cursor = previousIsoDate(cursor);
  }

  const complete = cursor < state.lower_bound_date;
  await repository.updateBackfillState({
    nextDate: cursor,
    status: complete ? 'COMPLETE' : 'RUNNING',
    requestDelta: processed,
    resultDelta: inserted,
  });

  return {
    state: await repository.getBackfillState(),
    processed,
    inserted,
    revisions,
    unchanged,
    hasMore: !complete,
  };
}

export async function runIncrementalUpdate(env, options = {}) {
  const repository = options.repository || new HistoryRepository(env.HISTORY_DB);
  const today = currentDateInZone(SANTO_DOMINGO_TIMEZONE, options.now || new Date());
  const dates = [today, previousIsoDate(today), previousIsoDate(previousIsoDate(today))];
  const metadata = await fetchGanaMasMetadata(options.fetchOptions || {});
  await repository.ensureMetadata(metadata);

  const summary = { drawId: DRAW_ID, checked: 0, inserted: 0, revisions: 0, unchanged: 0, failures: 0 };
  for (const date of dates) {
    try {
      const response = await fetchGanaMasForDate(date, options.fetchOptions || {});
      if (response.result) {
        response.result.checksum = await checksumForResult(response.result);
        const saved = await repository.saveResult(response.result);
        if (saved.kind === 'INSERT') summary.inserted += 1;
        if (saved.kind === 'REVISION') summary.revisions += 1;
        if (saved.kind === 'UNCHANGED') summary.unchanged += 1;
        await repository.recordCoverage({ date, status: 'RESULT_FOUND', attempts: response.attempts });
      } else {
        const missing = coverageForMissingDate(date);
        await repository.recordCoverage({ date, ...missing, attempts: response.attempts });
      }
    } catch (error) {
      summary.failures += 1;
      await repository.recordCoverage({
        date,
        status: 'FETCH_FAILED',
        attempts: 1,
        error: error instanceof Error ? error.message : String(error),
      });
    }
    summary.checked += 1;
  }
  return summary;
}
