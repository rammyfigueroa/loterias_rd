import { seriesByIds } from './constants.js';

const ISO_DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

export class ValidationError extends Error {
  constructor(message) {
    super(message);
    this.name = 'ValidationError';
  }
}

export function requireAuthorizedSeries(searchParams) {
  const operatorId = searchParams.get('operatorId');
  const drawId = searchParams.get('drawId');

  if (!operatorId || !drawId) {
    throw new ValidationError('operatorId and drawId are required.');
  }
  const series = seriesByIds(operatorId, drawId);
  if (!series) throw new ValidationError('The requested operator and draw series is not enabled.');
  return series;
}

export function parseIsoDate(value, fieldName) {
  if (value == null || value === '') return null;
  if (!ISO_DATE_PATTERN.test(value)) {
    throw new ValidationError(`${fieldName} must use YYYY-MM-DD.`);
  }
  const date = new Date(`${value}T12:00:00.000Z`);
  if (Number.isNaN(date.getTime()) || date.toISOString().slice(0, 10) !== value) {
    throw new ValidationError(`${fieldName} is not a valid calendar date.`);
  }
  return value;
}

export function parseDateRange(searchParams, maximumDate = null) {
  const from = parseIsoDate(searchParams.get('from'), 'from');
  const to = parseIsoDate(searchParams.get('to'), 'to');
  if ((from && !to) || (!from && to)) {
    throw new ValidationError('from and to must be provided together.');
  }
  if (from && from > to) {
    throw new ValidationError('from must not be after to.');
  }
  if (to && maximumDate && to > maximumDate) {
    throw new ValidationError('to must not be in the future.');
  }
  return { from, to };
}

export function parseLimit(value, fallback = 50, maximum = 100) {
  if (value == null || value === '') return fallback;
  if (!/^\d+$/.test(value)) throw new ValidationError('limit must be an integer.');
  const parsed = Number(value);
  if (parsed < 1 || parsed > maximum) {
    throw new ValidationError(`limit must be between 1 and ${maximum}.`);
  }
  return parsed;
}

export function parseOrder(value) {
  const normalized = (value || 'asc').toLowerCase();
  if (normalized !== 'asc' && normalized !== 'desc') {
    throw new ValidationError('order must be asc or desc.');
  }
  return normalized;
}

export function validateFirstNumber(value) {
  const text = String(value ?? '').trim();
  if (!/^\d{1,2}$/.test(text)) {
    throw new ValidationError('First position must be a number from 00 to 99.');
  }
  return text.padStart(2, '0');
}

export function previousIsoDate(value) {
  const valid = parseIsoDate(value, 'date');
  const date = new Date(`${valid}T12:00:00.000Z`);
  date.setUTCDate(date.getUTCDate() - 1);
  return date.toISOString().slice(0, 10);
}

export function currentDateInZone(timeZone, now = new Date()) {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(now);
  const values = Object.fromEntries(
    parts.filter((part) => part.type !== 'literal').map((part) => [part.type, part.value]),
  );
  return `${values.year}-${values.month}-${values.day}`;
}
