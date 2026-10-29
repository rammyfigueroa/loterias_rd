import { SERIES } from '../history/constants.js';
import { parseIsoDate } from '../history/validation.js';

export const COVERAGE_POLICY = {
  name: 'STRICT_CALENDAR_CONTINUITY',
  verifiedStatuses: ['RESULT_FOUND', 'NO_DRAW_SCHEDULED'],
  description: 'Every calendar date from the first appearance through the next appearance must be covered by RESULT_FOUND or NO_DRAW_SCHEDULED.',
};

const DAY_MS = 86_400_000;
const VERIFIED_STATUSES = new Set(COVERAGE_POLICY.verifiedStatuses);

export function calendarDaysBetween(startDate, endDate) {
  parseIsoDate(startDate, 'startDate');
  parseIsoDate(endDate, 'endDate');
  const start = Date.parse(`${startDate}T12:00:00.000Z`);
  const end = Date.parse(`${endDate}T12:00:00.000Z`);
  if (end < start) throw new Error('endDate must not be before startDate.');
  return Math.round((end - start) / DAY_MS);
}

function eachCalendarDate(startDate, endDate) {
  const dates = [];
  const cursor = new Date(`${startDate}T12:00:00.000Z`);
  const end = new Date(`${endDate}T12:00:00.000Z`);
  while (cursor <= end) {
    dates.push(cursor.toISOString().slice(0, 10));
    cursor.setUTCDate(cursor.getUTCDate() + 1);
  }
  return dates;
}

export function normalizeResults(results, series = SERIES.ganaMas) {
  const byDate = new Map();
  for (const row of results) {
    if (row.operator_id !== series.operatorId || row.draw_id !== series.drawId) {
      throw new Error('Statistics input contains an unauthorized series.');
    }
    const date = parseIsoDate(row.draw_date, 'draw_date');
    const number = String(row.first_number ?? '');
    if (!/^\d{2}$/.test(number)) throw new Error(`Invalid first number for ${date}.`);
    const existing = byDate.get(date);
    if (existing && existing.first_number !== number) {
      throw new Error(`Conflicting results found for ${date}.`);
    }
    if (!existing) byDate.set(date, { ...row, draw_date: date, first_number: number });
  }
  return [...byDate.values()].sort((left, right) => left.draw_date.localeCompare(right.draw_date));
}

export function classifyIntervalCoverage(startDate, endDate, coverageByDate) {
  const blockingDates = [];
  for (const date of eachCalendarDate(startDate, endDate)) {
    const status = coverageByDate.get(date);
    if (!status || !VERIFIED_STATUSES.has(status)) {
      blockingDates.push({ date, status: status || 'MISSING_COVERAGE' });
    }
  }
  return {
    status: blockingDates.length === 0 ? 'VERIFIED' : 'INCOMPLETE_COVERAGE',
    blockingDates,
  };
}

export function calculateConsecutiveIntervals(results, coverageRows, series = SERIES.ganaMas) {
  const normalized = normalizeResults(results, series);
  const coverageByDate = new Map(
    coverageRows.map((row) => [row.coverage_date, row.status]),
  );
  const appearances = new Map();
  for (const result of normalized) {
    if (!appearances.has(result.first_number)) appearances.set(result.first_number, []);
    appearances.get(result.first_number).push(result.draw_date);
  }

  const intervals = [];
  for (const [number, dates] of appearances) {
    for (let index = 1; index < dates.length; index += 1) {
      const startDate = dates[index - 1];
      const endDate = dates[index];
      const coverage = classifyIntervalCoverage(startDate, endDate, coverageByDate);
      intervals.push({
        number,
        startDate,
        endDate,
        days: calendarDaysBetween(startDate, endDate),
        coverageStatus: coverage.status,
        blockingDates: coverage.blockingDates,
      });
    }
  }
  return { normalizedResults: normalized, appearances, intervals };
}

export function aggregateIntervals(intervals, coverageStatus) {
  const groups = new Map();
  for (const interval of intervals) {
    if (coverageStatus && interval.coverageStatus !== coverageStatus) continue;
    if (!groups.has(interval.days)) {
      groups.set(interval.days, { days: interval.days, numbers: new Set(), occurrences: [] });
    }
    const group = groups.get(interval.days);
    group.numbers.add(interval.number);
    group.occurrences.push(interval);
  }

  return [...groups.values()]
    .map((group) => ({
      days: group.days,
      distinctNumbers: group.numbers.size,
      totalRepetitions: group.occurrences.length,
      numbers: [...group.numbers].sort(),
    }))
    .sort((left, right) =>
      right.distinctNumbers - left.distinctNumbers ||
      right.totalRepetitions - left.totalRepetitions ||
      left.days - right.days,
    );
}

function median(values) {
  if (values.length === 0) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const middle = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 1
    ? sorted[middle]
    : (sorted[middle - 1] + sorted[middle]) / 2;
}

function numberStatistics(number, dates, intervals, asOfDate) {
  const values = intervals.map((interval) => interval.days);
  const lastAppearanceDate = dates.at(-1) || null;
  const appearancesObserved = dates.length;
  return {
    number,
    sampleStatus: appearancesObserved === 0
      ? 'NO_APPEARANCES_OBSERVED'
      : appearancesObserved === 1
        ? 'SINGLE_APPEARANCE'
        : 'MULTIPLE_APPEARANCES',
    appearancesObserved,
    intervalsObserved: intervals.length,
    verifiedIntervals: intervals.filter((item) => item.coverageStatus === 'VERIFIED').length,
    incompleteCoverageIntervals: intervals.filter((item) => item.coverageStatus === 'INCOMPLETE_COVERAGE').length,
    minimumIntervalDays: values.length ? Math.min(...values) : null,
    maximumIntervalDays: values.length ? Math.max(...values) : null,
    averageIntervalDays: values.length
      ? Number((values.reduce((sum, value) => sum + value, 0) / values.length).toFixed(2))
      : null,
    medianIntervalDays: median(values),
    latestIntervalDays: values.at(-1) ?? null,
    lastAppearanceDate,
    daysSinceLastAppearance: lastAppearanceDate
      ? calendarDaysBetween(lastAppearanceDate, asOfDate)
      : null,
  };
}

export function buildStatistics(results, coverageRows, asOfDate, series = SERIES.ganaMas) {
  parseIsoDate(asOfDate, 'asOfDate');
  const calculated = calculateConsecutiveIntervals(results, coverageRows, series);
  const firstDate = calculated.normalizedResults[0]?.draw_date || null;
  const lastDate = calculated.normalizedResults.at(-1)?.draw_date || null;
  if (lastDate && asOfDate < lastDate) throw new Error('asOfDate must not precede the latest stored result.');

  const intervalsByNumber = new Map();
  for (const interval of calculated.intervals) {
    if (!intervalsByNumber.has(interval.number)) intervalsByNumber.set(interval.number, []);
    intervalsByNumber.get(interval.number).push(interval);
  }
  const numberRows = Array.from({ length: 100 }, (_, value) => String(value).padStart(2, '0'))
    .map((number) => numberStatistics(
      number,
      calculated.appearances.get(number) || [],
      intervalsByNumber.get(number) || [],
      asOfDate,
    ));

  const verifiedIntervals = calculated.intervals.filter((item) => item.coverageStatus === 'VERIFIED');
  const incompleteIntervals = calculated.intervals.filter((item) => item.coverageStatus === 'INCOMPLETE_COVERAGE');
  const unverifiedDates = firstDate && lastDate
    ? coverageRows
      .filter((row) => !VERIFIED_STATUSES.has(row.status) && row.coverage_date >= firstDate && row.coverage_date <= lastDate)
      .map((row) => ({ date: row.coverage_date, status: row.status }))
    : [];

  return {
    operatorId: series.operatorId,
    drawId: series.drawId,
    asOfDate,
    quality: {
      firstAvailableDate: firstDate,
      lastAvailableDate: lastDate,
      resultsAnalyzed: calculated.normalizedResults.length,
      intervalsCalculated: calculated.intervals.length,
      verifiedIntervals: verifiedIntervals.length,
      incompleteCoverageIntervals: incompleteIntervals.length,
      observedNumbers: calculated.appearances.size,
      unverifiedDateCount: unverifiedDates.length,
      unverifiedDates,
      coveragePolicy: COVERAGE_POLICY,
    },
    intervals: calculated.intervals,
    verifiedRanking: aggregateIntervals(calculated.intervals, 'VERIFIED'),
    incompleteCoverageRanking: aggregateIntervals(calculated.intervals, 'INCOMPLETE_COVERAGE'),
    numbers: numberRows,
  };
}
