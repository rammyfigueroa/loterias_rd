import assert from 'node:assert/strict';
import test from 'node:test';

import { calculateNumberTransitions } from '../src/statistics/number-transitions.js';

const SERIES = Object.freeze({ operatorId: 'operator-a', drawId: 'draw-a' });

function event(id, date, number, overrides = {}) {
  return {
    eventId: id,
    operatorId: SERIES.operatorId,
    drawId: SERIES.drawId,
    position: 'first',
    drawDate: date,
    number,
    status: 'RESULT_FOUND',
    ...overrides,
  };
}

function coverage(startDay, endDay, overrides = {}) {
  const rows = [];
  for (let day = startDay; day <= endDay; day += 1) {
    const date = `2026-05-${String(day).padStart(2, '0')}`;
    rows.push({
      operatorId: SERIES.operatorId,
      drawId: SERIES.drawId,
      date,
      status: overrides[date] || 'RESULT_FOUND',
    });
  }
  return rows;
}

function calculate(events, options = {}) {
  return calculateNumberTransitions({
    events,
    coverageRows: options.coverageRows || coverage(1, 31),
    series: options.series || SERIES,
    originNumber: options.originNumber || '10',
    coverageMode: options.coverageMode || 'verified',
    from: options.from || null,
    to: options.to || null,
  });
}

test('calculates a simple sequence with multiple destinations and exact frequencies', () => {
  const result = calculate([
    event('a', '2026-05-01', '10'),
    event('b', '2026-05-02', '20'),
    event('c', '2026-05-03', '10'),
    event('d', '2026-05-04', '30'),
  ]);
  assert.equal(result.totalTransitions, 2);
  assert.deepEqual(result.results, [
    { nextNumber: '20', transitionCount: 1, lastTransitionDate: '2026-05-02', relativeFrequency: 0.5 },
    { nextNumber: '30', transitionCount: 1, lastTransitionDate: '2026-05-04', relativeFrequency: 0.5 },
  ]);
});

test('counts a repeated number as a self-transition', () => {
  const result = calculate([event('a', '2026-05-01', '10'), event('b', '2026-05-02', '10')]);
  assert.equal(result.results[0].nextNumber, '10');
  assert.equal(result.results[0].relativeFrequency, 1);
});

test('does not depend on input order and uses a stable tie order', () => {
  const rows = [
    event('d', '2026-05-04', '30'),
    event('b', '2026-05-02', '20'),
    event('a', '2026-05-01', '10'),
    event('c', '2026-05-03', '10'),
  ];
  assert.deepEqual(calculate(rows), calculate([...rows].reverse()));
  assert.deepEqual(calculate(rows).results.map((item) => item.nextNumber), ['20', '30']);
});

test('deduplicates equivalent stable events', () => {
  const duplicate = event('a', '2026-05-01', '10');
  const result = calculate([duplicate, { ...duplicate }, event('b', '2026-05-02', '20')]);
  assert.equal(result.totalTransitions, 1);
  assert.equal(result.warnings.some((item) => item.code === 'EQUIVALENT_EVENT_DUPLICATE'), true);
});

test('reports conflicting stable event versions and excludes affected transitions', () => {
  const result = calculate([
    event('a', '2026-05-01', '10'),
    event('conflict', '2026-05-02', '20'),
    event('conflict', '2026-05-02', '21'),
    event('c', '2026-05-03', '30'),
  ]);
  assert.equal(result.totalTransitions, 0);
  assert.equal(result.quality.excludedConflictTransitions, 1);
  assert.equal(result.warnings.some((item) => item.code === 'CONFLICTING_EVENT_ID'), true);
});

test('reports conflicting dates without choosing an event arbitrarily', () => {
  const result = calculate([
    event('a', '2026-05-01', '10'),
    event('b', '2026-05-02', '20'),
    event('c', '2026-05-02', '21'),
    event('d', '2026-05-03', '30'),
  ]);
  assert.equal(result.totalTransitions, 0);
  assert.equal(result.warnings.some((item) => item.code === 'CONFLICTING_EVENT_DATE'), true);
});

test('deduplicates equivalent events with different provider identities on one date', () => {
  const result = calculate([
    event('a', '2026-05-01', '10'),
    event('b', '2026-05-01', '10'),
    event('c', '2026-05-02', '20'),
  ]);
  assert.equal(result.totalTransitions, 1);
  assert.equal(result.warnings.some((item) => item.code === 'EQUIVALENT_DATE_DUPLICATE'), true);
});

test('a corrected canonical event changes both adjacent transitions reproducibly', () => {
  const before = [
    event('a', '2026-05-01', '10'),
    event('b', '2026-05-02', '20'),
    event('c', '2026-05-03', '10'),
  ];
  const after = before.map((item) => item.eventId === 'b' ? { ...item, number: '30' } : item);
  assert.equal(calculate(before).results[0].nextNumber, '20');
  assert.equal(calculate(after).results[0].nextNumber, '30');
  assert.deepEqual(calculate(after), calculate([...after].reverse()));
});

test('ignores explicit non-result rows and never invents their numbers', () => {
  const result = calculate([
    event('a', '2026-05-01', '10'),
    event('missing', '2026-05-02', null, { status: 'NO_RESULTS_RETURNED' }),
    event('c', '2026-05-03', '20'),
  ], {
    coverageRows: coverage(1, 3, { '2026-05-02': 'NO_RESULTS_RETURNED' }),
  });
  assert.equal(result.totalTransitions, 0);
  assert.equal(result.quality.incompleteCoverageTransitions, 1);
  assert.equal(result.warnings.some((item) => item.code === 'IGNORED_NON_RESULT_EVENT'), true);
});

test('accepts a verified NO_DRAW_SCHEDULED date between events', () => {
  const result = calculate([
    event('a', '2026-05-01', '10'),
    event('b', '2026-05-03', '20'),
  ], {
    coverageRows: coverage(1, 3, { '2026-05-02': 'NO_DRAW_SCHEDULED' }),
  });
  assert.equal(result.totalTransitions, 1);
  assert.equal(result.coverageStatus, 'VERIFIED');
});

test('classifies missing dates as unknown and excludes them by default', () => {
  const result = calculate([
    event('a', '2026-05-01', '10'),
    event('b', '2026-05-03', '20'),
  ], { coverageRows: coverage(1, 1) });
  assert.equal(result.totalTransitions, 0);
  assert.equal(result.quality.unknownCoverageTransitions, 1);
  assert.equal(result.quality.excludedByCoverage, 1);
});

for (const status of ['UNVERIFIED', 'PENDING', 'FETCH_FAILED', 'NO_RESULTS_RETURNED']) {
  test(`treats ${status} as non-verified coverage`, () => {
    const result = calculate([
      event('a', '2026-05-01', '10'),
      event('b', '2026-05-03', '20'),
    ], { coverageRows: coverage(1, 3, { '2026-05-02': status }) });
    assert.equal(result.totalTransitions, 0);
    assert.equal(result.quality.excludedByCoverage, 1);
  });
}

test('incomplete mode includes incomplete and unknown transitions but labels them', () => {
  const result = calculate([
    event('a', '2026-05-01', '10'),
    event('b', '2026-05-03', '20'),
  ], { coverageRows: coverage(1, 1), coverageMode: 'incomplete' });
  assert.equal(result.totalTransitions, 1);
  assert.equal(result.coverageStatus, 'UNKNOWN_COVERAGE');
});

test('all mode keeps verified and non-verified transitions in separate quality totals', () => {
  const result = calculate([
    event('a', '2026-05-01', '10'),
    event('b', '2026-05-02', '20'),
    event('c', '2026-05-03', '10'),
    event('d', '2026-05-05', '30'),
  ], {
    coverageRows: coverage(1, 5, { '2026-05-04': 'UNVERIFIED' }),
    coverageMode: 'all',
  });
  assert.equal(result.totalTransitions, 2);
  assert.equal(result.quality.verifiedTransitions, 2);
  assert.equal(result.quality.unknownCoverageTransitions, 1);
  assert.equal(result.coverageStatus, 'MIXED');
});

test('the last origin event has no successor and never enters the denominator', () => {
  const result = calculate([event('a', '2026-05-01', '20'), event('b', '2026-05-02', '10')]);
  assert.equal(result.originAppearances, 1);
  assert.equal(result.originEventsWithoutSuccessor, 1);
  assert.equal(result.totalTransitions, 0);
  assert.equal(result.sampleStatus, 'NO_TRANSITIONS_OBSERVED');
});

test('returns an explicit empty sample for an absent origin and an empty series', () => {
  const absent = calculate([event('a', '2026-05-01', '20')]);
  const empty = calculate([], { coverageRows: [] });
  assert.equal(absent.originAppearances, 0);
  assert.equal(absent.totalTransitions, 0);
  assert.equal(empty.quality.eventsAnalyzed, 0);
  assert.deepEqual(empty.range, { from: null, to: null, custom: false, boundsInclusive: true });
});

test('uses inclusive range bounds and excludes outside boundary transitions', () => {
  const result = calculate([
    event('a', '2026-05-01', '10'),
    event('b', '2026-05-02', '10'),
    event('c', '2026-05-03', '20'),
    event('d', '2026-05-04', '30'),
  ], { from: '2026-05-02', to: '2026-05-03' });
  assert.equal(result.totalTransitions, 1);
  assert.equal(result.results[0].nextNumber, '20');
  assert.equal(result.quality.eventsAnalyzed, 2);
});

test('validates incomplete and inverted ranges', () => {
  assert.throws(() => calculate([], { coverageRows: [], from: '2026-05-01' }), /provided together/);
  assert.throws(
    () => calculate([], { coverageRows: [], from: '2026-05-03', to: '2026-05-01' }),
    /must not be after/,
  );
});

test('validates canonical numbers, dates, identifiers, positions and statuses', () => {
  assert.throws(() => calculate([], { coverageRows: [], originNumber: '1' }), /00 to 99/);
  assert.throws(() => calculate([event('', '2026-05-01', '10')]), /eventId is required/);
  assert.throws(() => calculate([event('a', 'bad-date', '10')]), /YYYY-MM-DD/);
  assert.throws(() => calculate([event('a', '2026-05-01', '100')]), /00 to 99/);
  assert.throws(() => calculate([event('a', '2026-05-01', '10', { position: 'second' })]), /different position/);
  assert.throws(() => calculate([event('a', '2026-05-01', '10', { status: 'OTHER' })]), /unsupported/);
  assert.throws(() => calculate([], { coverageRows: [], coverageMode: 'other' }), /coverageMode/);
});

test('rejects mixed operators and draws in events and coverage', () => {
  assert.throws(
    () => calculate([event('a', '2026-05-01', '10', { drawId: 'draw-b' })]),
    /different series/,
  );
  assert.throws(
    () => calculate([], { coverageRows: coverage(1, 1).map((row) => ({ ...row, operatorId: 'operator-b' })) }),
    /different series/,
  );
});

test('reports conflicting coverage as unknown deterministically', () => {
  const rows = [
    ...coverage(1, 2),
    { operatorId: SERIES.operatorId, drawId: SERIES.drawId, date: '2026-05-02', status: 'PENDING' },
  ];
  const events = [event('a', '2026-05-01', '10'), event('b', '2026-05-02', '20')];
  const forward = calculate(events, { coverageRows: rows });
  const reversed = calculate([...events].reverse(), { coverageRows: [...rows].reverse() });
  assert.deepEqual(forward, reversed);
  assert.equal(forward.quality.unknownCoverageTransitions, 1);
});

test('rounds relative frequencies to six decimal places', () => {
  const result = calculate([
    event('a', '2026-05-01', '10'), event('b', '2026-05-02', '20'),
    event('c', '2026-05-03', '10'), event('d', '2026-05-04', '20'),
    event('e', '2026-05-05', '10'), event('f', '2026-05-06', '30'),
  ]);
  assert.deepEqual(result.results.map((item) => item.relativeFrequency), [0.666667, 0.333333]);
  assert.equal(result.results.reduce((sum, item) => sum + item.transitionCount, 0), result.totalTransitions);
});

test('exposes descriptive language without recommendations or guarantees', () => {
  const serialized = JSON.stringify(calculate([],{ coverageRows: [] })).toLowerCase();
  for (const forbidden of ['recommended number', 'guaranteed winner', 'will come out']) {
    assert.equal(serialized.includes(forbidden), false);
  }
  assert.match(serialized, /does not predict future results/);
});
