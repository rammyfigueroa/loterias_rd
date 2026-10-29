import assert from 'node:assert/strict';
import test from 'node:test';

import { DRAW_ID, NATIONAL_DRAW_ID, OPERATOR_ID, SERIES, SANTO_DOMINGO_TIMEZONE } from '../src/history/constants.js';
import { currentDateInZone, parseDateRange, ValidationError } from '../src/history/validation.js';
import {
  aggregateIntervals,
  buildStatistics,
  calendarDaysBetween,
  calculateConsecutiveIntervals,
  classifyIntervalCoverage,
  normalizeResults,
} from '../src/statistics/engine.js';
import { paginate, __test as routeTest } from '../src/statistics/routes.js';

function result(date, number, id = `result-${date}`) {
  return {
    provider_result_id: id,
    operator_id: OPERATOR_ID,
    draw_id: DRAW_ID,
    draw_date: date,
    first_number: number,
  };
}

function coverage(startDay, endDay, overrides = {}) {
  const rows = [];
  for (let day = startDay; day <= endDay; day += 1) {
    const date = `2026-05-${String(day).padStart(2, '0')}`;
    rows.push({ coverage_date: date, status: overrides[date] || 'RESULT_FOUND' });
  }
  return rows;
}

test('calculates calendar days independently of elapsed hours', () => {
  assert.equal(calendarDaysBetween('2026-05-01', '2026-05-18'), 17);
  assert.equal(calendarDaysBetween('2026-02-28', '2026-03-01'), 1);
});

test('uses only consecutive appearances for each number', () => {
  const rows = [
    result('2026-05-01', '05'),
    result('2026-05-03', '05'),
    result('2026-05-05', '05'),
  ];
  const calculated = calculateConsecutiveIntervals(rows, coverage(1, 5));
  assert.deepEqual(calculated.intervals.map((item) => item.days), [2, 2]);
  assert.equal(calculated.intervals.some((item) => item.days === 4), false);
});

test('recalculates intervals only from appearances inside a selected range', () => {
  const rows = [
    result('2026-05-01', '27'),
    result('2026-05-15', '27'),
    result('2026-05-30', '27'),
  ].filter((item) => item.draw_date >= '2026-05-10' && item.draw_date <= '2026-05-31');
  const statistics = buildStatistics(rows, coverage(10, 31), '2026-05-31');
  assert.deepEqual(statistics.intervals.map((item) => item.days), [15]);
  assert.equal(statistics.numbers.find((item) => item.number === '27').appearancesObserved, 2);
});

test('validates complete, ordered and non-future date ranges', () => {
  assert.deepEqual(
    parseDateRange(new URLSearchParams({ from: '2026-05-10', to: '2026-05-31' }), '2026-06-01'),
    { from: '2026-05-10', to: '2026-05-31' },
  );
  assert.throws(() => parseDateRange(new URLSearchParams({ from: '2026-05-10' })), /provided together/);
  assert.throws(() => parseDateRange(new URLSearchParams({ from: '2026-05-31', to: '2026-05-10' })), /must not be after/);
  assert.throws(() => parseDateRange(new URLSearchParams({ from: '2026-05-10', to: '2026-06-02' }), '2026-06-01'), /future/);
});

test('preserves numbers with a leading zero', () => {
  const calculated = calculateConsecutiveIntervals([
    result('2026-05-01', '05'),
    result('2026-05-04', '05'),
  ], coverage(1, 4));
  assert.equal(calculated.intervals[0].number, '05');
});

test('groups exact intervals by distinct numbers and total repetitions', () => {
  const intervals = [
    { days: 17, number: '05', coverageStatus: 'VERIFIED' },
    { days: 17, number: '05', coverageStatus: 'VERIFIED' },
    { days: 17, number: '27', coverageStatus: 'VERIFIED' },
  ];
  const ranking = aggregateIntervals(intervals, 'VERIFIED');
  assert.deepEqual(ranking[0], {
    days: 17,
    distinctNumbers: 2,
    totalRepetitions: 3,
    numbers: ['05', '27'],
  });
});

test('orders ranking by distinct numbers, repetitions and then days', () => {
  const intervals = [
    { days: 20, number: '01', coverageStatus: 'VERIFIED' },
    { days: 20, number: '02', coverageStatus: 'VERIFIED' },
    { days: 10, number: '01', coverageStatus: 'VERIFIED' },
    { days: 10, number: '02', coverageStatus: 'VERIFIED' },
    { days: 10, number: '02', coverageStatus: 'VERIFIED' },
    { days: 5, number: '03', coverageStatus: 'VERIFIED' },
  ];
  assert.deepEqual(aggregateIntervals(intervals, 'VERIFIED').map((item) => item.days), [10, 20, 5]);
});

test('marks an interval incomplete when it crosses an unverified date', () => {
  const byDate = new Map([
    ['2026-05-01', 'RESULT_FOUND'],
    ['2026-05-02', 'UNVERIFIED'],
    ['2026-05-03', 'RESULT_FOUND'],
  ]);
  const classified = classifyIntervalCoverage('2026-05-01', '2026-05-03', byDate);
  assert.equal(classified.status, 'INCOMPLETE_COVERAGE');
  assert.deepEqual(classified.blockingDates, [{ date: '2026-05-02', status: 'UNVERIFIED' }]);
});

test('treats missing and NO_RESULTS_RETURNED coverage conservatively', () => {
  const byDate = new Map([
    ['2026-05-01', 'RESULT_FOUND'],
    ['2026-05-02', 'NO_RESULTS_RETURNED'],
  ]);
  const classified = classifyIntervalCoverage('2026-05-01', '2026-05-03', byDate);
  assert.equal(classified.status, 'INCOMPLETE_COVERAGE');
  assert.deepEqual(classified.blockingDates.map((item) => item.status), ['NO_RESULTS_RETURNED', 'MISSING_COVERAGE']);
});

test('calculates average, median, latest appearance and current days', () => {
  const rows = [
    result('2026-05-01', '12'),
    result('2026-05-03', '12'),
    result('2026-05-07', '12'),
  ];
  const statistics = buildStatistics(rows, coverage(1, 10), '2026-05-10');
  const number = statistics.numbers.find((item) => item.number === '12');
  assert.equal(number.averageIntervalDays, 3);
  assert.equal(number.medianIntervalDays, 3);
  assert.equal(number.minimumIntervalDays, 2);
  assert.equal(number.maximumIntervalDays, 4);
  assert.equal(number.latestIntervalDays, 4);
  assert.equal(number.lastAppearanceDate, '2026-05-07');
  assert.equal(number.daysSinceLastAppearance, 3);
});

test('distinguishes one appearance and no observed appearances', () => {
  const statistics = buildStatistics([result('2026-05-01', '44')], coverage(1, 1), '2026-05-03');
  const single = statistics.numbers.find((item) => item.number === '44');
  const absent = statistics.numbers.find((item) => item.number === '45');
  assert.equal(single.sampleStatus, 'SINGLE_APPEARANCE');
  assert.equal(single.averageIntervalDays, null);
  assert.equal(absent.sampleStatus, 'NO_APPEARANCES_OBSERVED');
  assert.equal(absent.lastAppearanceDate, null);
});

test('reports sample quality and separates verified intervals', () => {
  const rows = [
    result('2026-05-01', '10'),
    result('2026-05-03', '10'),
    result('2026-05-04', '20'),
    result('2026-05-06', '20'),
  ];
  const coverageRows = coverage(1, 6, { '2026-05-05': 'UNVERIFIED' });
  const statistics = buildStatistics(rows, coverageRows, '2026-05-07');
  assert.equal(statistics.quality.resultsAnalyzed, 4);
  assert.equal(statistics.quality.intervalsCalculated, 2);
  assert.equal(statistics.quality.verifiedIntervals, 1);
  assert.equal(statistics.quality.incompleteCoverageIntervals, 1);
  assert.equal(statistics.quality.unverifiedDateCount, 1);
});

test('deduplicates identical stored dates and rejects conflicting duplicates', () => {
  assert.equal(normalizeResults([
    result('2026-05-01', '10', 'one'),
    result('2026-05-01', '10', 'duplicate'),
  ]).length, 1);
  assert.throws(() => normalizeResults([
    result('2026-05-01', '10', 'one'),
    result('2026-05-01', '11', 'conflict'),
  ]), /Conflicting results/);
});

test('rejects results from any other series', () => {
  const unauthorized = { ...result('2026-05-01', '10'), draw_id: 'other' };
  assert.throws(() => normalizeResults([unauthorized]), /unauthorized series/);
});

test('calculates National independently and rejects a mixed Gana Más row', () => {
  const nationalRows = [
    { ...result('2026-05-01', '10'), draw_id: NATIONAL_DRAW_ID },
    { ...result('2026-05-05', '10'), draw_id: NATIONAL_DRAW_ID },
  ];
  const statistics = buildStatistics(nationalRows, coverage(1, 5), '2026-05-06', SERIES.national);
  assert.equal(statistics.drawId, NATIONAL_DRAW_ID);
  assert.equal(statistics.intervals[0].days, 4);
  assert.throws(
    () => buildStatistics([...nationalRows, result('2026-05-06', '10')], coverage(1, 6), '2026-05-06', SERIES.national),
    /unauthorized series/,
  );
});

test('uses the Dominican calendar when the UTC date already changed', () => {
  const now = new Date('2026-10-29T02:30:00.000Z');
  assert.equal(currentDateInZone(SANTO_DOMINGO_TIMEZONE, now), '2026-10-28');
});

test('paginates statistics with an opaque cursor', () => {
  const first = paginate([1, 2, 3, 4, 5], new URLSearchParams({ limit: '2' }));
  assert.deepEqual(first.results, [1, 2]);
  assert.equal(first.hasMore, true);
  const second = paginate([1, 2, 3, 4, 5], new URLSearchParams({ limit: '2', cursor: first.nextCursor }));
  assert.deepEqual(second.results, [3, 4]);
});

test('validates interval detail paths and pagination cursors', () => {
  assert.equal(routeTest.intervalDaysFromPath('/statistics/first-prize/intervals/17'), 17);
  assert.equal(routeTest.intervalDaysFromPath('/statistics/first-prize/intervals'), null);
  assert.throws(() => paginate([1], new URLSearchParams({ cursor: 'bad' })), ValidationError);
});
