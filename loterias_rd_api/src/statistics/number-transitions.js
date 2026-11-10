import { parseIsoDate } from '../history/validation.js';

const VERIFIED_COVERAGE = new Set(['RESULT_FOUND', 'NO_DRAW_SCHEDULED']);
const INCOMPLETE_COVERAGE = new Set(['NO_RESULTS_RETURNED', 'FETCH_FAILED']);
const UNKNOWN_COVERAGE = new Set(['UNVERIFIED', 'PENDING']);
const COVERAGE_STATUSES = new Set([
  ...VERIFIED_COVERAGE,
  ...INCOMPLETE_COVERAGE,
  ...UNKNOWN_COVERAGE,
]);
const EVENT_STATUSES = new Set(['RESULT_FOUND', ...INCOMPLETE_COVERAGE, ...UNKNOWN_COVERAGE, 'NO_DRAW_SCHEDULED']);
const COVERAGE_MODES = new Set(['verified', 'incomplete', 'all']);
const DISCLAIMER = 'This analysis describes observed historical transitions and does not predict future results.';

function requiredText(value, field) {
  const text = String(value ?? '').trim();
  if (!text) throw new Error(`${field} is required.`);
  return text;
}

function requiredDate(value, field) {
  const date = parseIsoDate(value, field);
  if (!date) throw new Error(`${field} is required.`);
  return date;
}

function requiredNumber(value, field = 'originNumber') {
  const number = String(value ?? '');
  if (!/^\d{2}$/.test(number)) throw new Error(`${field} must be a number from 00 to 99.`);
  return number;
}

function compareText(left, right) {
  return left < right ? -1 : left > right ? 1 : 0;
}

function eachDate(startDate, endDate) {
  const dates = [];
  const cursor = new Date(`${startDate}T12:00:00.000Z`);
  const end = new Date(`${endDate}T12:00:00.000Z`);
  while (cursor <= end) {
    dates.push(cursor.toISOString().slice(0, 10));
    cursor.setUTCDate(cursor.getUTCDate() + 1);
  }
  return dates;
}

function normalizeSeries(series, position) {
  if (!series || typeof series !== 'object') throw new Error('series is required.');
  const normalized = {
    operatorId: requiredText(series.operatorId, 'series.operatorId'),
    drawId: requiredText(series.drawId, 'series.drawId'),
    position: requiredText(position, 'position'),
  };
  if (normalized.position !== 'first') throw new Error('position must be first.');
  return normalized;
}

function normalizeRange(from, to) {
  if ((from && !to) || (!from && to)) throw new Error('from and to must be provided together.');
  if (!from) return { from: null, to: null, custom: false, boundsInclusive: true };
  const normalizedFrom = requiredDate(from, 'from');
  const normalizedTo = requiredDate(to, 'to');
  if (normalizedFrom > normalizedTo) throw new Error('from must not be after to.');
  return { from: normalizedFrom, to: normalizedTo, custom: true, boundsInclusive: true };
}

function assertSeries(item, series, prefix) {
  const operatorId = requiredText(item.operatorId, `${prefix}.operatorId`);
  const drawId = requiredText(item.drawId, `${prefix}.drawId`);
  if (operatorId !== series.operatorId || drawId !== series.drawId) {
    throw new Error(`${prefix} belongs to a different series.`);
  }
  return { operatorId, drawId };
}

function eventSignature(event) {
  return [event.operatorId, event.drawId, event.position, event.drawDate, event.number, event.status].join('|');
}

function warning(code, message, detail = {}) {
  return { code, message, ...detail };
}

function normalizeEvents(events, series, range) {
  if (!Array.isArray(events)) throw new Error('events must be an array.');
  const warnings = [];
  const candidates = [];

  for (let index = 0; index < events.length; index += 1) {
    const input = events[index];
    if (!input || typeof input !== 'object') throw new Error(`events[${index}] must be an object.`);
    assertSeries(input, series, `events[${index}]`);
    const eventId = requiredText(input.eventId, `events[${index}].eventId`);
    const position = requiredText(input.position, `events[${index}].position`);
    if (position !== series.position) throw new Error(`events[${index}] belongs to a different position.`);
    const drawDate = requiredDate(input.drawDate, `events[${index}].drawDate`);
    const status = requiredText(input.status, `events[${index}].status`);
    if (!EVENT_STATUSES.has(status)) throw new Error(`events[${index}].status is unsupported: ${status}.`);

    if (status !== 'RESULT_FOUND') {
      if (input.number != null && input.number !== '') {
        throw new Error(`events[${index}] must not contain a number when status is ${status}.`);
      }
      warnings.push(warning(
        'IGNORED_NON_RESULT_EVENT',
        'A row without a valid result was not treated as a historical event.',
        { eventId, date: drawDate, status },
      ));
      continue;
    }

    candidates.push({
      eventId,
      operatorId: series.operatorId,
      drawId: series.drawId,
      position,
      drawDate,
      number: requiredNumber(input.number, `events[${index}].number`),
      status,
    });
  }

  candidates.sort((left, right) =>
    compareText(left.eventId, right.eventId) ||
    compareText(left.drawDate, right.drawDate) ||
    compareText(left.number, right.number));

  const byId = new Map();
  for (const event of candidates) {
    if (!byId.has(event.eventId)) byId.set(event.eventId, []);
    byId.get(event.eventId).push(event);
  }

  const uniqueById = [];
  const conflictDates = new Set();
  for (const [eventId, rows] of byId) {
    const signatures = new Set(rows.map(eventSignature));
    if (signatures.size > 1) {
      rows.forEach((row) => conflictDates.add(row.drawDate));
      warnings.push(warning(
        'CONFLICTING_EVENT_ID',
        'Conflicting versions of one stable event were excluded.',
        { eventId, dates: [...new Set(rows.map((row) => row.drawDate))].sort() },
      ));
      continue;
    }
    uniqueById.push(rows[0]);
    if (rows.length > 1) {
      warnings.push(warning(
        'EQUIVALENT_EVENT_DUPLICATE',
        'Equivalent copies of one event were counted once.',
        { eventId, date: rows[0].drawDate, duplicateCount: rows.length },
      ));
    }
  }

  uniqueById.sort((left, right) =>
    compareText(left.drawDate, right.drawDate) || compareText(left.eventId, right.eventId));
  const byDate = new Map();
  for (const event of uniqueById) {
    if (!byDate.has(event.drawDate)) byDate.set(event.drawDate, []);
    byDate.get(event.drawDate).push(event);
  }

  const canonical = [];
  for (const [date, rows] of byDate) {
    const numbers = new Set(rows.map((row) => row.number));
    if (numbers.size > 1) {
      conflictDates.add(date);
      warnings.push(warning(
        'CONFLICTING_EVENT_DATE',
        'Conflicting results for one series date were excluded.',
        { date, eventIds: rows.map((row) => row.eventId).sort() },
      ));
      continue;
    }
    canonical.push(rows[0]);
    if (rows.length > 1) {
      warnings.push(warning(
        'EQUIVALENT_DATE_DUPLICATE',
        'Equivalent events on one series date were counted once.',
        { date, eventIds: rows.map((row) => row.eventId).sort() },
      ));
    }
  }

  const inRange = canonical.filter((event) =>
    (!range.from || event.drawDate >= range.from) && (!range.to || event.drawDate <= range.to));
  return { events: inRange, conflictDates, warnings };
}

function normalizeCoverage(coverageRows, series, range) {
  if (!Array.isArray(coverageRows)) throw new Error('coverageRows must be an array.');
  const rows = coverageRows.map((input, index) => {
    if (!input || typeof input !== 'object') throw new Error(`coverageRows[${index}] must be an object.`);
    assertSeries(input, series, `coverageRows[${index}]`);
    const date = requiredDate(input.date, `coverageRows[${index}].date`);
    const status = requiredText(input.status, `coverageRows[${index}].status`);
    if (!COVERAGE_STATUSES.has(status)) {
      throw new Error(`coverageRows[${index}].status is unsupported: ${status}.`);
    }
    return { date, status };
  }).filter((row) => (!range.from || row.date >= range.from) && (!range.to || row.date <= range.to));

  rows.sort((left, right) => compareText(left.date, right.date) || compareText(left.status, right.status));
  const byDate = new Map();
  const warnings = [];
  for (const row of rows) {
    if (!byDate.has(row.date)) {
      byDate.set(row.date, row.status);
    } else if (byDate.get(row.date) !== row.status) {
      byDate.set(row.date, 'COVERAGE_CONFLICT');
      warnings.push(warning(
        'CONFLICTING_COVERAGE_DATE',
        'Conflicting coverage states were treated as unknown.',
        { date: row.date },
      ));
    }
  }
  return { byDate, warnings };
}

function classifyCoverage(startDate, endDate, coverageByDate) {
  const blockingDates = [];
  let hasIncomplete = false;
  let hasUnknown = false;
  for (const date of eachDate(startDate, endDate)) {
    const status = coverageByDate.get(date) || 'MISSING_COVERAGE';
    if (VERIFIED_COVERAGE.has(status)) continue;
    if (INCOMPLETE_COVERAGE.has(status)) hasIncomplete = true;
    else hasUnknown = true;
    blockingDates.push({ date, status });
  }
  return {
    status: hasUnknown
      ? 'UNKNOWN_COVERAGE'
      : hasIncomplete
        ? 'INCOMPLETE_COVERAGE'
        : 'VERIFIED',
    blockingDates,
  };
}

function includesConflict(startDate, endDate, conflictDates) {
  let low = 0;
  let high = conflictDates.length;
  while (low < high) {
    const middle = Math.floor((low + high) / 2);
    if (conflictDates[middle] < startDate) low = middle + 1;
    else high = middle;
  }
  return low < conflictDates.length && conflictDates[low] <= endDate;
}

function includeForMode(status, mode) {
  if (mode === 'verified') return status === 'VERIFIED';
  if (mode === 'incomplete') return status !== 'VERIFIED';
  return true;
}

function sortWarnings(warnings) {
  return warnings.sort((left, right) =>
    compareText(left.code, right.code) ||
    compareText(left.date || '', right.date || '') ||
    compareText(left.eventId || '', right.eventId || '') ||
    compareText(left.message, right.message));
}

export function calculateNumberTransitions({
  events,
  coverageRows,
  series,
  position = 'first',
  originNumber,
  from = null,
  to = null,
  coverageMode = 'verified',
}) {
  const normalizedSeries = normalizeSeries(series, position);
  const normalizedOrigin = requiredNumber(originNumber);
  const range = normalizeRange(from, to);
  if (!COVERAGE_MODES.has(coverageMode)) {
    throw new Error('coverageMode must be verified, incomplete or all.');
  }

  const normalized = normalizeEvents(events, normalizedSeries, range);
  const coverage = normalizeCoverage(coverageRows, normalizedSeries, range);
  const warnings = [...normalized.warnings, ...coverage.warnings];
  const transitions = [];
  const conflictDates = [...normalized.conflictDates].sort();
  let excludedConflictTransitions = 0;

  for (let index = 0; index + 1 < normalized.events.length; index += 1) {
    const source = normalized.events[index];
    const target = normalized.events[index + 1];
    if (includesConflict(source.drawDate, target.drawDate, conflictDates)) {
      excludedConflictTransitions += 1;
      continue;
    }
    const classified = classifyCoverage(source.drawDate, target.drawDate, coverage.byDate);
    transitions.push({
      sourceEventId: source.eventId,
      sourceDate: source.drawDate,
      originNumber: source.number,
      targetEventId: target.eventId,
      targetDate: target.drawDate,
      nextNumber: target.number,
      coverageStatus: classified.status,
      blockingDates: classified.blockingDates,
    });
  }

  const originTransitions = transitions.filter((item) => item.originNumber === normalizedOrigin);
  const selected = originTransitions.filter((item) => includeForMode(item.coverageStatus, coverageMode));
  const totals = new Map();
  for (const item of selected) {
    const current = totals.get(item.nextNumber) || {
      nextNumber: item.nextNumber,
      transitionCount: 0,
      lastTransitionDate: item.targetDate,
    };
    current.transitionCount += 1;
    if (item.targetDate > current.lastTransitionDate) current.lastTransitionDate = item.targetDate;
    totals.set(item.nextNumber, current);
  }

  const totalTransitions = selected.length;
  const results = [...totals.values()]
    .map((item) => ({
      ...item,
      relativeFrequency: Number((item.transitionCount / totalTransitions).toFixed(6)),
    }))
    .sort((left, right) =>
      right.transitionCount - left.transitionCount || compareText(left.nextNumber, right.nextNumber));
  const originAppearances = normalized.events.filter((event) => event.number === normalizedOrigin).length;
  const lastEvent = normalized.events.at(-1);
  const excludedByCoverage = originTransitions.length - selected.length;

  if (excludedConflictTransitions > 0) {
    warnings.push(warning(
      'EXCLUDED_CONFLICT_TRANSITIONS',
      'Transitions crossing unresolved event conflicts were excluded.',
      { count: excludedConflictTransitions },
    ));
  }
  if (excludedByCoverage > 0) {
    warnings.push(warning(
      'EXCLUDED_BY_COVERAGE',
      'Origin transitions outside the selected coverage mode were excluded.',
      { count: excludedByCoverage, coverageMode },
    ));
  }
  if (totalTransitions === 0) {
    warnings.push(warning(
      'NO_TRANSITIONS_OBSERVED',
      'No transitions satisfy the selected series, range and coverage mode.',
    ));
  }

  const statusCounts = {
    verified: transitions.filter((item) => item.coverageStatus === 'VERIFIED').length,
    incomplete: transitions.filter((item) => item.coverageStatus === 'INCOMPLETE_COVERAGE').length,
    unknown: transitions.filter((item) => item.coverageStatus === 'UNKNOWN_COVERAGE').length,
  };
  const originStatusCounts = {
    verified: originTransitions.filter((item) => item.coverageStatus === 'VERIFIED').length,
    incomplete: originTransitions.filter((item) => item.coverageStatus === 'INCOMPLETE_COVERAGE').length,
    unknown: originTransitions.filter((item) => item.coverageStatus === 'UNKNOWN_COVERAGE').length,
  };
  const observedStatuses = Object.values(originStatusCounts).filter((count) => count > 0).length;
  const effectiveRange = range.custom
    ? range
    : {
        from: normalized.events[0]?.drawDate || null,
        to: normalized.events.at(-1)?.drawDate || null,
        custom: false,
        boundsInclusive: true,
      };

  return {
    operatorId: normalizedSeries.operatorId,
    drawId: normalizedSeries.drawId,
    position: normalizedSeries.position,
    originNumber: normalizedOrigin,
    range: effectiveRange,
    coverageMode,
    coverageStatus: observedStatuses === 0
      ? 'NO_OBSERVATIONS'
      : observedStatuses === 1
        ? originStatusCounts.verified > 0
          ? 'VERIFIED'
          : originStatusCounts.incomplete > 0
            ? 'INCOMPLETE_COVERAGE'
            : 'UNKNOWN_COVERAGE'
        : 'MIXED',
    sampleStatus: totalTransitions === 0 ? 'NO_TRANSITIONS_OBSERVED' : 'TRANSITIONS_OBSERVED',
    originAppearances,
    originEventsWithoutSuccessor: lastEvent?.number === normalizedOrigin ? 1 : 0,
    totalTransitions,
    quality: {
      eventsAnalyzed: normalized.events.length,
      transitionsAnalyzed: transitions.length,
      verifiedTransitions: statusCounts.verified,
      incompleteCoverageTransitions: statusCounts.incomplete,
      unknownCoverageTransitions: statusCounts.unknown,
      excludedConflictTransitions,
      excludedByCoverage,
    },
    results,
    warnings: sortWarnings(warnings),
    disclaimer: DISCLAIMER,
  };
}

export const __test = {
  classifyCoverage,
  normalizeEvents,
  normalizeCoverage,
};
