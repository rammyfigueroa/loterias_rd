import { HISTORY_SOURCE, SERIES, SOURCE_SITE_ID } from './constants.js';
import { parseIsoDate, validateFirstNumber } from './validation.js';

export class ProviderError extends Error {
  constructor(message, options = {}) {
    super(message, options);
    this.name = 'ProviderError';
  }
}

export async function fetchJsonWithRetry(url, {
  fetchImpl = fetch, timeoutMs = 6000, retries = 2, retryDelayMs = 150,
} = {}) {
  let lastError;
  for (let attempt = 1; attempt <= retries + 1; attempt += 1) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const response = await fetchImpl(url, {
        headers: { Accept: 'application/json', 'User-Agent': 'SorteosDominicanosHistory/1.0' },
        signal: controller.signal,
      });
      if (!response.ok) throw new ProviderError(`Provider returned HTTP ${response.status}.`);
      return { data: await response.json(), attempts: attempt };
    } catch (error) {
      lastError = error;
      if (attempt > retries) break;
      await new Promise((resolve) => setTimeout(resolve, retryDelayMs * attempt));
    } finally {
      clearTimeout(timeout);
    }
  }
  throw new ProviderError('Provider request failed after retries.', { cause: lastError });
}

export function identifySeries(sitePayload, series) {
  const matches = [];
  for (const company of sitePayload?.siteCompanies || []) {
    if (company?.company_id !== series.operatorId || company?.company?._id !== series.operatorId) continue;
    for (const siteGame of company?.siteGames || []) {
      if (siteGame?.game_id !== series.drawId || siteGame?.game?._id !== series.drawId) continue;
      matches.push({ company, siteGame, game: siteGame.game });
    }
  }
  if (matches.length !== 1) {
    throw new ProviderError(`Expected one structured ${series.drawName} match, found ${matches.length}.`);
  }
  const match = matches[0];
  const labels = match.game?.score_layout?.flat?.().map((item) => item?.label) || [];
  if (match.company.title !== series.operatorName || match.siteGame.title !== series.drawName ||
      match.game?.is_quiniela !== true || match.game?.statistics?.positions !== 3 || labels.length < 3) {
    throw new ProviderError(`${series.drawName} metadata does not match the approved structure.`);
  }
  return {
    ...series,
    sourceSiteId: sitePayload?._id || SOURCE_SITE_ID,
    sourceCreatedAt: match.game.createdAt,
    lowerBoundDate: String(match.game.createdAt).slice(0, 10),
    scoreLabels: labels,
  };
}

export const identifyGanaMas = (payload) => identifySeries(payload, SERIES.ganaMas);
export const identifyNational = (payload) => identifySeries(payload, SERIES.national);

export async function fetchSeriesMetadata(series, options = {}) {
  const { data, attempts } = await fetchJsonWithRetry(`${HISTORY_SOURCE}/sites/env`, options);
  return { ...identifySeries(data, series), attempts };
}

export const fetchGanaMasMetadata = (options = {}) => fetchSeriesMetadata(SERIES.ganaMas, options);

export function extractSeriesSession(groups, requestedDate, series) {
  parseIsoDate(requestedDate, 'requestedDate');
  if (!Array.isArray(groups)) throw new ProviderError('Sessions payload must be an array.');
  const matchingGroups = groups.filter((group) => group?.game_id === series.drawId);
  if (matchingGroups.length !== 1) {
    throw new ProviderError(`Expected one ${series.drawName} session group, found ${matchingGroups.length}.`);
  }
  const exactSessions = (matchingGroups[0].sessions || []).filter(
    (session) => session?.game_id === series.drawId && String(session?.date).slice(0, 10) === requestedDate,
  );
  if (exactSessions.length === 0) return null;
  if (exactSessions.length > 1) throw new ProviderError(`Multiple ${series.drawName} sessions found for ${requestedDate}.`);
  const session = exactSessions[0];
  if (!session._id) throw new ProviderError(`${series.drawName} session is missing its provider ID.`);
  return {
    providerResultId: session._id,
    operatorId: series.operatorId,
    drawId: series.drawId,
    drawDate: requestedDate,
    firstNumber: validateFirstNumber(session?.score?.[0]?.[0]),
    source: HISTORY_SOURCE,
    providerCreatedAt: session.createdAt || null,
    providerUpdatedAt: session.updatedAt || null,
    rawPayload: session,
  };
}

export const extractGanaMasSession = (groups, date) => extractSeriesSession(groups, date, SERIES.ganaMas);

export async function fetchSeriesForDate(series, requestedDate, options = {}) {
  parseIsoDate(requestedDate, 'requestedDate');
  const url = new URL(`${HISTORY_SOURCE}/sessions`);
  url.searchParams.set('date', `${requestedDate}T04:00:00.000Z`);
  url.searchParams.set('limit', '3');
  const { data, attempts } = await fetchJsonWithRetry(url.toString(), options);
  return { result: extractSeriesSession(data, requestedDate, series), attempts };
}

export const fetchGanaMasForDate = (date, options = {}) => fetchSeriesForDate(SERIES.ganaMas, date, options);

export async function checksumForResult(result) {
  const canonical = JSON.stringify({
    providerResultId: result.providerResultId, operatorId: result.operatorId,
    drawId: result.drawId, drawDate: result.drawDate, firstNumber: result.firstNumber,
    score: result.rawPayload?.score || null,
  });
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(canonical));
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, '0')).join('');
}
