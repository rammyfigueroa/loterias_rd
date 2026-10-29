import {
  DRAW_ID,
  DRAW_NAME,
  HISTORY_SOURCE,
  OPERATOR_ID,
  OPERATOR_NAME,
  SOURCE_SITE_ID,
} from './constants.js';
import { parseIsoDate, validateFirstNumber } from './validation.js';

export class ProviderError extends Error {
  constructor(message, options = {}) {
    super(message, options);
    this.name = 'ProviderError';
  }
}

export async function fetchJsonWithRetry(
  url,
  {
    fetchImpl = fetch,
    timeoutMs = 6000,
    retries = 2,
    retryDelayMs = 150,
  } = {},
) {
  let lastError;
  for (let attempt = 1; attempt <= retries + 1; attempt += 1) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const response = await fetchImpl(url, {
        headers: {
          Accept: 'application/json',
          'User-Agent': 'SorteosDominicanosHistory/1.0',
        },
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

export function identifyGanaMas(sitePayload) {
  const matches = [];
  for (const company of sitePayload?.siteCompanies || []) {
    if (company?.company_id !== OPERATOR_ID && company?.company?._id !== OPERATOR_ID) continue;
    for (const siteGame of company?.siteGames || []) {
      if (siteGame?.game_id !== DRAW_ID || siteGame?.game?._id !== DRAW_ID) continue;
      matches.push({ company, siteGame, game: siteGame.game });
    }
  }

  if (matches.length !== 1) {
    throw new ProviderError(`Expected one structured Gana Más match, found ${matches.length}.`);
  }

  const match = matches[0];
  const labels = match.game?.score_layout?.flat?.().map((item) => item?.label) || [];
  if (
    match.company.title !== OPERATOR_NAME ||
    match.siteGame.title !== DRAW_NAME ||
    match.game?.is_quiniela !== true ||
    match.game?.statistics?.positions !== 3 ||
    labels.length < 3
  ) {
    throw new ProviderError('Gana Más metadata does not match the approved structure.');
  }

  return {
    operatorId: OPERATOR_ID,
    operatorName: match.company.title,
    drawId: DRAW_ID,
    drawName: match.siteGame.title,
    sourceSiteId: sitePayload?._id || SOURCE_SITE_ID,
    sourceCreatedAt: match.game.createdAt,
    lowerBoundDate: String(match.game.createdAt).slice(0, 10),
    scoreLabels: labels,
  };
}

export async function fetchGanaMasMetadata(options = {}) {
  const { data, attempts } = await fetchJsonWithRetry(`${HISTORY_SOURCE}/sites/env`, options);
  return { ...identifyGanaMas(data), attempts };
}

export function extractGanaMasSession(groups, requestedDate) {
  parseIsoDate(requestedDate, 'requestedDate');
  if (!Array.isArray(groups)) throw new ProviderError('Sessions payload must be an array.');

  const matchingGroups = groups.filter((group) => group?.game_id === DRAW_ID);
  if (matchingGroups.length !== 1) {
    throw new ProviderError(`Expected one Gana Más session group, found ${matchingGroups.length}.`);
  }

  const exactSessions = (matchingGroups[0].sessions || []).filter(
    (session) => session?.game_id === DRAW_ID && String(session?.date).slice(0, 10) === requestedDate,
  );
  if (exactSessions.length === 0) return null;
  if (exactSessions.length > 1) {
    throw new ProviderError(`Multiple Gana Más sessions found for ${requestedDate}.`);
  }

  const session = exactSessions[0];
  if (!session._id) throw new ProviderError('Gana Más session is missing its provider ID.');
  const firstNumber = validateFirstNumber(session?.score?.[0]?.[0]);

  return {
    providerResultId: session._id,
    operatorId: OPERATOR_ID,
    drawId: DRAW_ID,
    drawDate: requestedDate,
    firstNumber,
    source: HISTORY_SOURCE,
    providerCreatedAt: session.createdAt || null,
    providerUpdatedAt: session.updatedAt || null,
    rawPayload: session,
  };
}

export async function fetchGanaMasForDate(requestedDate, options = {}) {
  parseIsoDate(requestedDate, 'requestedDate');
  const url = new URL(`${HISTORY_SOURCE}/sessions`);
  url.searchParams.set('date', `${requestedDate}T04:00:00.000Z`);
  url.searchParams.set('limit', '3');
  const { data, attempts } = await fetchJsonWithRetry(url.toString(), options);
  return { result: extractGanaMasSession(data, requestedDate), attempts };
}

export async function checksumForResult(result) {
  const canonical = JSON.stringify({
    providerResultId: result.providerResultId,
    operatorId: result.operatorId,
    drawId: result.drawId,
    drawDate: result.drawDate,
    firstNumber: result.firstNumber,
    score: result.rawPayload?.score || null,
  });
  const bytes = new TextEncoder().encode(canonical);
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, '0')).join('');
}
